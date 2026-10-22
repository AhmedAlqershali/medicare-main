'use strict';

const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const assert = require('node:assert/strict');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc } = require('firebase/firestore');

const projectId = 'demo-medicare-access-tests';
const rules = fs.readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8');
let testEnvironment;

const identities = {
  owner: { uid: 'owner-a', email: 'owner@example.com', role: 'organization', organizationId: 'org-a', clinicId: 'clinic-a' },
  organization: { uid: 'organization-a', email: 'organization@example.com', role: 'organization', organizationId: 'org-a' },
  clinicMember: { uid: 'clinic-member-a', email: 'clinic@example.com', role: 'organization', organizationId: 'org-a', clinicId: 'clinic-a' },
  otherClinicMember: { uid: 'clinic-member-b', email: 'clinic-b@example.com', role: 'organization', organizationId: 'org-a', clinicId: 'clinic-b' },
  doctor: { uid: 'doctor-a-uid', email: 'doctor-a@example.com', role: 'doctor', organizationId: 'org-a', doctorId: 'doctor-a' },
  otherDoctor: { uid: 'doctor-b-uid', email: 'doctor-b@example.com', role: 'doctor', organizationId: 'org-a', doctorId: 'doctor-b' },
  patient: { uid: 'patient-a-uid', email: 'patient-a@example.com', role: 'patient', organizationId: 'org-a', doctorId: 'doctor-a', patientId: 'patient-a' },
  otherPatient: { uid: 'patient-b-uid', email: 'patient-b@example.com', role: 'patient', organizationId: 'org-a', doctorId: 'doctor-b', patientId: 'patient-b' },
};

function userDocument(identity) {
  return {
    uid: identity.uid,
    email: identity.email,
    role: identity.role,
    organizationId: identity.organizationId,
    ...(identity.doctorId ? { doctorId: identity.doctorId } : {}),
    ...(identity.patientId ? { patientId: identity.patientId } : {}),
    ...(identity.clinicId ? { clinicId: identity.clinicId } : {}),
  };
}

function context(identity) {
  return testEnvironment.authenticatedContext(identity.uid, {
    email: identity.email,
    email_verified: true,
  }).firestore();
}

async function seedFixtures() {
  await testEnvironment.withSecurityRulesDisabled(async (adminContext) => {
    const db = adminContext.firestore();
    const documents = {
      'organizations/org-a': {
        id: 'org-a', status: 'active', firebaseUid: identities.owner.uid,
        ownerUid: identities.owner.uid,
      },
      'organizations/org-b': { id: 'org-b', status: 'active' },
      'organizations/org-a/clinics/clinic-a': {
        id: 'clinic-a', organizationId: 'org-a', status: 'active',
      },
      'organizations/org-a/clinics/clinic-b': {
        id: 'clinic-b', organizationId: 'org-a', status: 'active',
      },
      'organizations/org-b/clinics/clinic-c': {
        id: 'clinic-c', organizationId: 'org-b', status: 'active',
      },
      'organizations/org-a/doctors/doctor-a': {
        id: 'doctor-a', organizationId: 'org-a', status: 'active',
        firebaseUid: identities.doctor.uid, clinicId: 'clinic-a',
      },
      'organizations/org-a/doctors/doctor-b': {
        id: 'doctor-b', organizationId: 'org-a', status: 'active',
        firebaseUid: identities.otherDoctor.uid, clinicId: 'clinic-b',
      },
      'organizations/org-b/doctors/doctor-c': {
        id: 'doctor-c', organizationId: 'org-b', status: 'active',
        firebaseUid: 'doctor-c-uid', clinicId: 'clinic-c',
      },
      'organizations/org-a/patients/patient-a': {
        id: 'patient-a', organizationId: 'org-a', doctorId: 'doctor-a',
        clinicId: 'clinic-a', email: identities.patient.email,
        firebaseUid: identities.patient.uid, accountActivated: true, status: 'active',
      },
      'organizations/org-a/patients/patient-legacy': {
        id: 'patient-legacy', organizationId: 'org-a', doctorId: 'doctor-a',
        email: 'legacy@example.com', firebaseUid: null,
        accountActivated: false, status: 'pending',
      },
      'organizations/org-a/patients/patient-b': {
        id: 'patient-b', organizationId: 'org-a', doctorId: 'doctor-b',
        clinicId: 'clinic-b', email: identities.otherPatient.email,
        firebaseUid: identities.otherPatient.uid, accountActivated: true, status: 'active',
      },
      'organizations/org-a/patients/patient-shared': {
        id: 'patient-shared', organizationId: 'org-a', doctorId: 'doctor-b',
        clinicId: 'clinic-b', email: 'shared@example.com',
        firebaseUid: null, accountActivated: false, status: 'pending',
      },
      'organizations/org-b/patients/patient-other-org': {
        id: 'patient-other-org', organizationId: 'org-b', doctorId: 'doctor-c',
        clinicId: 'clinic-c', email: 'other-org@example.com',
        firebaseUid: null, accountActivated: false, status: 'pending',
      },
      'organizations/org-a/patients/patient-legacy/clinic_access_by_clinic/clinic-a': {
        patientId: 'patient-legacy', organizationId: 'org-a', clinicId: 'clinic-a',
      },
      'organizations/org-a/patients/patient-shared/clinic_access_by_clinic/clinic-a': {
        patientId: 'patient-shared', organizationId: 'org-a', clinicId: 'clinic-a',
      },
      'organizations/org-a/patients/patient-shared/clinic_access/doctor-a': {
        patientId: 'patient-shared', organizationId: 'org-a',
        doctorId: 'doctor-a', clinicId: 'clinic-a',
      },
      'organizations/org-a/patient_email_index/patient-a@example.com': {
        email: 'patient-a@example.com', organizationId: 'org-a', patientId: 'patient-a',
      },
      'patient_email_index/patient-a@example.com': {
        email: 'patient-a@example.com', organizationId: 'org-a',
        patientId: 'patient-a', doctorId: 'doctor-a',
      },
    };

    for (const identity of Object.values(identities)) {
      documents[`users/${identity.uid}`] = userDocument(identity);
    }
    for (const [documentPath, data] of Object.entries(documents)) {
      await setDoc(doc(db, documentPath), data);
    }
  });
}

 test.before(async () => {
  testEnvironment = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules,
    },
  });
});

test.beforeEach(async () => {
  await testEnvironment.clearFirestore();
  await seedFixtures();
});

test.after(async () => {
  await testEnvironment?.cleanup();
});

test('organization owner can read across clinics in the active organization only', async () => {
  const db = context(identities.owner);
  await assertSucceeds(getDoc(doc(db, 'organizations/org-a/patients/patient-b')));
  await assertFails(getDoc(doc(db, 'organizations/org-b/patients/patient-other-org')));
});

test('unscoped organization member can read organization patients, not other organizations', async () => {
  const db = context(identities.organization);
  await assertSucceeds(getDoc(doc(db, 'organizations/org-a/patients/patient-a')));
  await assertSucceeds(getDoc(doc(db, 'organizations/org-a/patients/patient-b')));
  await assertSucceeds(getDoc(doc(db, 'organizations/org-a/patients/patient-legacy')));
  await assertFails(getDoc(doc(db, 'organizations/org-b/patients/patient-other-org')));
});

test('clinic-scoped member can read its direct and explicitly assigned legacy patients only', async () => {
  const db = context(identities.clinicMember);
  await assertSucceeds(getDoc(doc(db, 'organizations/org-a/patients/patient-a')));
  await assertSucceeds(getDoc(doc(db, 'organizations/org-a/patients/patient-legacy')));
  await assertSucceeds(getDoc(doc(db, 'organizations/org-a/patients/patient-shared')));
  await assertFails(getDoc(doc(db, 'organizations/org-a/patients/patient-b')));
  await assertFails(getDoc(doc(db, 'organizations/org-b/patients/patient-other-org')));
});

test('doctor can read owned and explicitly assigned patients in the active clinic only', async () => {
  const db = context(identities.doctor);
  await assertSucceeds(getDoc(doc(db, 'organizations/org-a/patients/patient-a')));
  await assertSucceeds(getDoc(doc(db, 'organizations/org-a/patients/patient-legacy')));
  await assertSucceeds(getDoc(doc(db, 'organizations/org-a/patients/patient-shared')));
  await assertFails(getDoc(doc(db, 'organizations/org-a/patients/patient-b')));
  await assertFails(getDoc(doc(db, 'organizations/org-b/patients/patient-other-org')));
});

test('patient can read only their own linked record', async () => {
  const db = context(identities.patient);
  await assertSucceeds(getDoc(doc(db, 'organizations/org-a/patients/patient-a')));
  await assertFails(getDoc(doc(db, 'organizations/org-a/patients/patient-b')));
  await assertFails(getDoc(doc(db, 'organizations/org-a/patients/patient-legacy')));
});

test('patient records cannot be created directly by a client', async () => {
  const db = context(identities.doctor);
  await assertFails(setDoc(doc(db, 'organizations/org-a/patients/direct-write'), {
    id: 'direct-write', organizationId: 'org-a', doctorId: 'doctor-a',
    clinicId: 'clinic-a', email: 'direct@example.com', status: 'pending',
    accountActivated: false,
  }));
});

test('email indexes are not enumerable and are readable only through their authorized identity', async () => {
  const doctorDb = context(identities.doctor);
  const otherDoctorDb = context(identities.otherDoctor);
  const patientDb = context(identities.patient);
  await assertSucceeds(getDoc(doc(doctorDb, 'patient_email_index/patient-a@example.com')));
  await assertFails(getDoc(doc(otherDoctorDb, 'patient_email_index/patient-a@example.com')));
  await assertSucceeds(getDoc(doc(patientDb, 'organizations/org-a/patient_email_index/patient-a@example.com')));
  await assertFails(getDoc(doc(otherDoctorDb, 'organizations/org-a/patient_email_index/patient-a@example.com')));
});

test('clinic member cannot read another clinic email index or write an index directly', async () => {
  const db = context(identities.clinicMember);
  await assertFails(getDoc(doc(db, 'organizations/org-a/patient_email_index/patient-b@example.com')));
  await assertFails(setDoc(doc(db, 'organizations/org-a/patient_email_index/fake@example.com'), {
    email: 'fake@example.com', organizationId: 'org-a', patientId: 'patient-b',
  }));
});
