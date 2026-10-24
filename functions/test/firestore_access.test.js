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
const {
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} = require('firebase/firestore');

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
  admin: { uid: 'admin-a-uid', email: 'admin@example.com', role: 'organization', organizationId: 'org-a' },
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
      'organizations/org-unlinked': {
        id: 'org-unlinked', email: 'unlinked@example.com', status: 'active',
      },
      'organizations/org-a/clinics/clinic-a': {
        id: 'clinic-a', organizationId: 'org-a', status: 'active',
      },
      'organizations/org-a/clinics/clinic-b': {
        id: 'clinic-b', organizationId: 'org-a', status: 'active',
      },
      'organizations/org-a/invitations/invited-member': {
        id: 'invited-member', email: 'new-organization@example.com',
        recipientEmail: 'new-organization@example.com', role: 'organization',
        invitedBy: identities.owner.uid, organizationId: 'org-a',
        status: 'pending', clinicId: 'clinic-a',
      },
      'organizations/org-b/clinics/clinic-c': {
        id: 'clinic-c', organizationId: 'org-b', status: 'active',
      },
      'organizations/org-a/doctors/doctor-a': {
        id: 'doctor-a', organizationId: 'org-a', status: 'active',
        firebaseUid: identities.doctor.uid, clinicId: 'clinic-a',
        serviceIds: ['service-glasses'],
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
      'admins/admin-a-uid': { role: 'admin', active: true },
      'medical_catalog/service-glasses': {
        id: 'service-glasses', kind: 'service', nameAr: 'خدمة النظارات',
        nameEn: '', specialtyIds: [], repeatIntervalMonths: 12,
        active: true, archived: false,
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

test('clinic-scoped members cannot read another clinic document', async () => {
  const db = context(identities.clinicMember);
  await assertSucceeds(getDoc(doc(db, 'organizations/org-a/clinics/clinic-a')));
  await assertFails(getDoc(doc(db, 'organizations/org-a/clinics/clinic-b')));
  await assertFails(getDoc(doc(db, 'organizations/org-b/clinics/clinic-c')));
});

test('only an organization owner or admin can create a clinic', async () => {
  const ownerDb = context(identities.owner);
  const clinicMemberDb = context(identities.clinicMember);
  const adminDb = context(identities.admin);
  const clinic = {
    id: 'new-clinic',
    organizationId: 'org-a',
    name: 'New clinic',
    status: 'active',
  };

  await assertSucceeds(setDoc(doc(ownerDb, 'organizations/org-a/clinics/new-clinic'), clinic));
  await assertFails(setDoc(doc(clinicMemberDb, 'organizations/org-a/clinics/other-new-clinic'), {
    ...clinic,
    id: 'other-new-clinic',
  }));
  await assertSucceeds(setDoc(doc(adminDb, 'organizations/org-a/clinics/admin-clinic'), {
    ...clinic,
    id: 'admin-clinic',
  }));
});

test('doctor can read a directly assigned patient', async () => {
  const db = context(identities.doctor);
  await assertSucceeds(getDoc(doc(db, 'organizations/org-a/patients/patient-a')));
});

test('doctor can read a legacy patient assigned to its clinic', async () => {
  const db = context(identities.doctor);
  await assertSucceeds(getDoc(doc(db, 'organizations/org-a/patients/patient-legacy')));
});

test('doctor can read a patient explicitly assigned to its clinic', async () => {
  const db = context(identities.doctor);
  await assertSucceeds(getDoc(doc(db, 'organizations/org-a/patients/patient-shared')));
});

test('doctor cannot read another clinic or organization patient', async () => {
  const db = context(identities.doctor);
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

test('patient records cannot be deleted by organization owners or admins', async () => {
  const ownerDb = context(identities.owner);
  const adminDb = context(identities.admin);
  const patientPath = 'organizations/org-a/patients/patient-a';

  await assertFails(deleteDoc(doc(ownerDb, patientPath)));
  await assertFails(deleteDoc(doc(adminDb, patientPath)));
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

test('medical catalog is readable by signed-in users and writable only by admins without deletion', async () => {
  const doctorDb = context(identities.doctor);
  const adminDb = context(identities.admin);
  const entry = doc(adminDb, 'medical_catalog/specialty-test');
  const data = {
    id: 'specialty-test',
    kind: 'specialty',
    nameAr: 'تخصص اختباري',
    nameEn: '',
    specialtyIds: [],
    active: true,
    archived: false,
    updatedAt: serverTimestamp(),
  };

  await assertSucceeds(getDoc(doc(doctorDb, 'medical_catalog/specialty-test')));
  await assertFails(setDoc(doc(doctorDb, 'medical_catalog/specialty-test'), data));
  await assertSucceeds(setDoc(entry, data));
  await assertFails(deleteDoc(entry));
  await assertFails(updateDoc(doc(doctorDb, 'medical_catalog/specialty-test'), {
    active: false,
  }));
});

test('users can access only their own profile and cannot grant themselves admin', async () => {
  const patientDb = context(identities.patient);
  const adminDb = context(identities.admin);
  const forgedAdminDb = testEnvironment.authenticatedContext('forged-admin', {
    email: 'forged-admin@example.com',
    email_verified: true,
    role: 'admin',
  }).firestore();
  const orphanDb = testEnvironment.authenticatedContext('orphan-user', {
    email: 'orphan@example.com',
    email_verified: true,
  }).firestore();
  const ownProfile = doc(patientDb, 'users/patient-a-uid');

  await assertSucceeds(getDoc(ownProfile));
  await assertFails(getDoc(doc(patientDb, 'users/patient-b-uid')));
  await assertFails(updateDoc(ownProfile, { role: 'admin' }));
  await assertFails(updateDoc(ownProfile, { organizationId: 'org-b' }));
  await assertFails(updateDoc(ownProfile, { doctorId: 'doctor-b' }));
  await assertFails(updateDoc(ownProfile, { patientId: 'patient-b' }));
  await assertFails(updateDoc(ownProfile, { clinicId: 'clinic-b' }));
  await assertFails(setDoc(doc(patientDb, 'admins/patient-a-uid'), {
    role: 'admin',
    active: true,
  }));
  await assertSucceeds(getDoc(doc(adminDb, 'organizations/org-a/patients/patient-a')));
  await assertFails(getDoc(doc(forgedAdminDb, 'organizations/org-a/patients/patient-a')));
  await assertFails(getDoc(doc(orphanDb, 'organizations/org-a/patients/patient-a')));
  await assertFails(getDoc(doc(testEnvironment.unauthenticatedContext().firestore(), 'organizations/org-a/patients/patient-a')));
});

test('organization email matching only permits linking an unclaimed organization', async () => {
  const unlinkedOwnerDb = testEnvironment.authenticatedContext('unlinked-owner', {
    email: 'unlinked@example.com',
    email_verified: true,
  }).firestore();
  const emailImpostorDb = testEnvironment.authenticatedContext('email-impostor', {
    email: identities.owner.email,
    email_verified: true,
  }).firestore();

  await assertSucceeds(getDoc(doc(unlinkedOwnerDb, 'organizations/org-unlinked')));
  await assertSucceeds(updateDoc(doc(unlinkedOwnerDb, 'organizations/org-unlinked'), {
    firebaseUid: 'unlinked-owner',
    updatedAt: serverTimestamp(),
  }));
  await assertFails(getDoc(doc(emailImpostorDb, 'organizations/org-a')));
  await assertFails(updateDoc(doc(emailImpostorDb, 'organizations/org-a'), {
    firebaseUid: 'email-impostor',
    updatedAt: serverTimestamp(),
  }));
});

test('organization invitation profile creation must match its clinic and invitation', async () => {
  const db = testEnvironment.authenticatedContext('invited-member-uid', {
    email: 'new-organization@example.com',
    email_verified: true,
  }).firestore();
  const profile = {
    uid: 'invited-member-uid',
    email: 'new-organization@example.com',
    role: 'organization',
    organizationId: 'org-a',
    clinicId: 'clinic-b',
    invitationId: 'invited-member',
  };

  await assertFails(setDoc(doc(db, 'users/invited-member-uid'), profile));
  await assertSucceeds(setDoc(doc(db, 'users/invited-member-uid'), {
    ...profile,
    clinicId: 'clinic-a',
  }));
});

test('patients cannot change ownership or activation fields', async () => {
  const db = context(identities.patient);
  const patient = doc(db, 'organizations/org-a/patients/patient-a');

  await assertFails(updateDoc(patient, { organizationId: 'org-b' }));
  await assertFails(updateDoc(patient, { doctorId: 'doctor-b' }));
  await assertFails(updateDoc(patient, { patientId: 'patient-b' }));
  await assertFails(updateDoc(patient, { clinicId: 'clinic-b' }));
  await assertFails(updateDoc(patient, { firebaseUid: identities.otherPatient.uid }));
  await assertFails(updateDoc(patient, { accountActivated: false }));
});

test('medical notes can only be created by the assigned doctor and are permanent', async () => {
  const doctorDb = context(identities.doctor);
  const otherDoctorDb = context(identities.otherDoctor);
  const patientDb = context(identities.patient);
  const notePath = 'organizations/org-a/patients/patient-a/medical_notes/note-a';

  await assertSucceeds(setDoc(doc(doctorDb, notePath), {
    text: 'Clinical note',
    createdAt: serverTimestamp(),
    doctorUid: identities.doctor.uid,
    doctorName: 'Assigned Doctor',
  }));
  await assertFails(updateDoc(doc(doctorDb, notePath), { text: 'Changed' }));
  await assertFails(deleteDoc(doc(doctorDb, notePath)));
  await assertFails(setDoc(doc(otherDoctorDb, 'organizations/org-a/patients/patient-a/medical_notes/note-b'), {
    text: 'Unauthorized note',
    createdAt: serverTimestamp(),
    doctorUid: identities.otherDoctor.uid,
    doctorName: 'Other Doctor',
  }));
  await assertFails(setDoc(doc(patientDb, 'organizations/org-a/patients/patient-a/medical_notes/note-c'), {
    text: 'Patient-authored note',
    createdAt: serverTimestamp(),
    doctorUid: identities.patient.uid,
    doctorName: 'Patient',
  }));
  await assertFails(setDoc(doc(doctorDb, 'organizations/org-a/patients/patient-a/medical_notes/note-malformed'), {
    text: 42,
    createdAt: serverTimestamp(),
    doctorUid: identities.doctor.uid,
    doctorName: 'Assigned Doctor',
  }));
  await assertFails(setDoc(doc(doctorDb, 'organizations/org-a/patients/patient-a/medical_notes/note-empty'), {
    text: '  ',
    createdAt: serverTimestamp(),
    doctorUid: identities.doctor.uid,
    doctorName: 'Assigned Doctor',
  }));
  await assertFails(setDoc(doc(doctorDb, 'organizations/org-a/patients/patient-a/medical_notes/note-forged-time'), {
    text: 'Clinical note',
    createdAt: Timestamp.fromDate(new Date('2020-01-01T00:00:00.000Z')),
    doctorUid: identities.doctor.uid,
    doctorName: 'Assigned Doctor',
  }));
});

async function seedPregnancyCase() {
  const casePath = 'organizations/org-a/patients/patient-a/medical_cases/case-a';
  await testEnvironment.withSecurityRulesDisabled(async (adminContext) => {
    const db = adminContext.firestore();
    await setDoc(doc(db, casePath), {
      id: 'case-a',
      patientId: 'patient-a',
      organizationId: 'org-a',
      doctorId: 'doctor-a',
      clinicId: 'clinic-a',
      title: 'Pregnancy',
      type: 'pregnancy',
      startedAt: Timestamp.fromDate(new Date('2026-01-01T00:00:00.000Z')),
      diagnosis: '',
      assessment: '',
      notes: '',
      treatmentPlan: '',
      status: 'active',
      createdAt: Timestamp.fromDate(new Date('2026-01-01T00:00:00.000Z')),
      pregnancy: {
        datingMethod: 'lastMenstrualPeriod',
        referenceDate: Timestamp.fromDate(new Date('2026-01-01T00:00:00.000Z')),
        gestationalWeeksAtReference: 0,
        gestationalDaysAtReference: 0,
        expectedDueDate: Timestamp.fromDate(new Date('2026-10-08T00:00:00.000Z')),
        archiveAt: Timestamp.fromDate(new Date('2026-10-22T00:00:00.000Z')),
      },
    });
    await setDoc(doc(db, `${casePath}/follow_ups/follow-up-a`), {
      id: 'follow-up-a',
      caseId: 'case-a',
      patientId: 'patient-a',
      organizationId: 'org-a',
      doctorId: 'doctor-a',
      clinicId: 'clinic-a',
    });
    await setDoc(doc(db, 'organizations/org-a/appointments/appointment-a'), {
      id: 'appointment-a',
      organizationId: 'org-a',
      patientId: 'patient-a',
      doctorId: 'doctor-a',
      clinicId: 'clinic-a',
      status: 'completed',
      date: Timestamp.fromDate(new Date('2026-10-20T00:00:00.000Z')),
      time: '10:00',
    });
    await setDoc(doc(db, 'organizations/org-a/appointments/service-appointment-a'), {
      id: 'service-appointment-a',
      organizationId: 'org-a',
      patientId: 'patient-a',
      doctorId: 'doctor-a',
      clinicId: 'clinic-a',
      serviceId: 'service-glasses',
      serviceName: 'خدمة النظارات',
      status: 'upcoming',
      date: Timestamp.fromDate(new Date('2026-10-20T00:00:00.000Z')),
      time: '10:00',
    });
  });
  return casePath;
}

test('only the assigned doctor can record a pregnancy outcome once', async () => {
  const casePath = await seedPregnancyCase();
  const doctorDb = context(identities.doctor);
  const otherDoctorDb = context(identities.otherDoctor);
  const pregnancy = {
    datingMethod: 'lastMenstrualPeriod',
    referenceDate: Timestamp.fromDate(new Date('2026-01-01T00:00:00.000Z')),
    gestationalWeeksAtReference: 0,
    gestationalDaysAtReference: 0,
    expectedDueDate: Timestamp.fromDate(new Date('2026-10-08T00:00:00.000Z')),
    archiveAt: Timestamp.fromDate(new Date('2026-10-22T00:00:00.000Z')),
    outcome: 'liveBirth',
    endedAt: Timestamp.fromDate(new Date('2026-10-10T00:00:00.000Z')),
  };

  await assertFails(updateDoc(doc(doctorDb, casePath), {
    status: 'completed',
    completedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(doctorDb, casePath), {
    status: 'archived',
    archivedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(otherDoctorDb, casePath), {
    status: 'completed',
    completedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    pregnancy,
  }));
  await assertSucceeds(updateDoc(doc(doctorDb, casePath), {
    status: 'completed',
    completedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    pregnancy,
  }));
  await assertFails(updateDoc(doc(doctorDb, casePath), {
    status: 'completed',
    completedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    pregnancy: { ...pregnancy, outcome: 'stillbirth' },
  }));
});

test('medical cases and clinical follow-ups cannot be deleted', async () => {
  const casePath = await seedPregnancyCase();
  const doctorDb = context(identities.doctor);

  await assertFails(deleteDoc(doc(doctorDb, casePath)));
  await assertFails(deleteDoc(doc(doctorDb, `${casePath}/follow_ups/follow-up-a`)));
});

test('follow-ups are append-only and restricted to the assigned doctor and patient', async () => {
  const casePath = await seedPregnancyCase();
  const doctorDb = context(identities.doctor);
  const otherDoctorDb = context(identities.otherDoctor);
  const patientDb = context(identities.patient);
  const followUpPath = `${casePath}/follow_ups/follow-up-new`;
  const data = {
    id: 'follow-up-new',
    caseId: 'case-a',
    patientId: 'patient-a',
    organizationId: 'org-a',
    doctorId: 'doctor-a',
    clinicId: 'clinic-a',
    visitAt: Timestamp.fromDate(new Date('2026-10-20T00:00:00.000Z')),
    assessment: 'Follow-up assessment',
    notes: 'Medical notes',
    recommendations: '',
    nextPlan: 'Continue follow-up',
    caseData: { gestationalAge: '40 weeks', bloodPressure: '120/80' },
    nextAppointmentAt: Timestamp.fromDate(new Date('2026-10-27T00:00:00.000Z')),
    createdAt: serverTimestamp(),
  };

  await assertFails(setDoc(doc(otherDoctorDb, followUpPath), data));
  await assertFails(setDoc(doc(patientDb, followUpPath), data));
  await assertSucceeds(setDoc(doc(doctorDb, followUpPath), data));
  await assertSucceeds(setDoc(doc(doctorDb, `${casePath}/follow_ups/follow-up-same-time`), {
    ...data,
    id: 'follow-up-same-time',
    nextAppointmentAt: data.visitAt,
  }));
  await assertSucceeds(setDoc(doc(doctorDb, `${casePath}/follow_ups/follow-up-linked`), {
    ...data,
    id: 'follow-up-linked',
    appointmentId: 'appointment-a',
  }));
  await assertFails(setDoc(doc(doctorDb, `${casePath}/follow_ups/follow-up-mismatch`), {
    ...data,
    id: 'follow-up-mismatch',
    appointmentId: 'appointment-a',
    visitAt: Timestamp.fromDate(new Date('2026-10-21T00:00:00.000Z')),
  }));
  await assertFails(updateDoc(doc(doctorDb, followUpPath), { notes: 'Changed' }));
  await assertFails(deleteDoc(doc(doctorDb, followUpPath)));
});

test('appointment access is scoped and clients cannot change its ownership', async () => {
  await seedPregnancyCase();
  const doctorDb = context(identities.doctor);
  const otherDoctorDb = context(identities.otherDoctor);
  const patientDb = context(identities.patient);
  const otherPatientDb = context(identities.otherPatient);
  const appointmentPath = 'organizations/org-a/appointments/appointment-a';
  const appointment = doc(doctorDb, appointmentPath);

  await assertSucceeds(getDoc(appointment));
  await assertFails(getDoc(doc(otherDoctorDb, appointmentPath)));
  await assertSucceeds(getDoc(doc(patientDb, appointmentPath)));
  await assertFails(getDoc(doc(otherPatientDb, appointmentPath)));
  await assertFails(updateDoc(doc(otherDoctorDb, appointmentPath), {
    status: 'cancelled',
  }));
  await assertFails(updateDoc(doc(patientDb, appointmentPath), {
    status: 'cancelled',
  }));
  await assertFails(updateDoc(appointment, { patientId: 'patient-b' }));
  await assertFails(updateDoc(appointment, { doctorId: 'doctor-b' }));
  await assertFails(updateDoc(appointment, { clinicId: 'clinic-b' }));
  await assertFails(updateDoc(appointment, { organizationId: 'org-b' }));

  const futureAppointment = doc(doctorDb, 'organizations/org-a/appointments/future-appointment');
  await testEnvironment.withSecurityRulesDisabled(async (adminContext) => {
    await setDoc(doc(adminContext.firestore(), 'organizations/org-a/appointments/future-appointment'), {
      id: 'future-appointment',
      organizationId: 'org-a',
      patientId: 'patient-a',
      doctorId: 'doctor-a',
      clinicId: 'clinic-a',
      status: 'upcoming',
      date: Timestamp.fromDate(new Date(Date.now() + 86400000)),
      time: '10:00',
    });
  });
  await assertFails(updateDoc(futureAppointment, { status: 'completed' }));
  await assertFails(setDoc(doc(doctorDb, 'organizations/org-a/appointments/invalid-date'), {
    id: 'invalid-date',
    organizationId: 'org-a',
    patientId: 'patient-a',
    doctorId: 'doctor-a',
    clinicId: 'clinic-a',
    status: 'upcoming',
    date: '2026-10-25T10:00:00.000Z',
  }));
});

test('medical service usage and history are append-only and cannot be written by clients', async () => {
  const doctorDb = context(identities.doctor);
  const patientDb = context(identities.patient);
  const usagePath = 'organizations/org-a/patients/patient-a/medical_service_usage/service-glasses';
  const historyPath = 'organizations/org-a/patients/patient-a/medical_service_history/record-a';

  await assertFails(setDoc(doc(doctorDb, usagePath), { lastServiceAt: serverTimestamp() }));
  await assertFails(setDoc(doc(doctorDb, historyPath), { serviceId: 'service-glasses' }));
  await assertFails(deleteDoc(doc(doctorDb, historyPath)));
  await assertFails(setDoc(doc(patientDb, historyPath), { serviceId: 'service-glasses' }));
});

test('service-linked appointments cannot be completed directly by clients', async () => {
  await seedPregnancyCase();
  const doctorDb = context(identities.doctor);

  await assertFails(updateDoc(
    doc(doctorDb, 'organizations/org-a/appointments/service-appointment-a'),
    { status: 'completed', updatedAt: serverTimestamp() },
  ));
});

test('service-linked appointments require an active service assigned to their doctor', async () => {
  const doctorDb = context(identities.doctor);
  const appointmentPath = 'organizations/org-a/appointments/new-service-appointment';
  await testEnvironment.withSecurityRulesDisabled(async (adminContext) => {
    await setDoc(doc(adminContext.firestore(), 'medical_catalog/service-unassigned'), {
      id: 'service-unassigned',
      kind: 'service',
      nameAr: 'خدمة غير معينة',
      nameEn: '',
      specialtyIds: [],
      active: true,
      archived: false,
    });
  });
  const validAppointment = {
    id: 'new-service-appointment',
    organizationId: 'org-a',
    patientId: 'patient-a',
    doctorId: 'doctor-a',
    clinicId: 'clinic-a',
    date: Timestamp.fromDate(new Date(Date.now() + 24 * 60 * 60 * 1000)),
    time: '10:00',
    type: 'زيارة في العيادة',
    status: 'upcoming',
    notes: '',
    serviceId: 'service-glasses',
    serviceName: 'خدمة النظارات',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };

  await assertSucceeds(setDoc(doc(doctorDb, appointmentPath), validAppointment));
  await assertFails(setDoc(doc(doctorDb, 'organizations/org-a/appointments/unassigned-service'), {
    ...validAppointment,
    id: 'unassigned-service',
    serviceId: 'unknown-service',
  }));
  await assertFails(setDoc(doc(doctorDb, 'organizations/org-a/appointments/not-offered-service'), {
    ...validAppointment,
    id: 'not-offered-service',
    serviceId: 'service-unassigned',
    serviceName: 'خدمة غير معينة',
  }));
});

test('service usage visibility remains limited to the patient access scope', async () => {
  const doctorDb = context(identities.doctor);
  const otherDoctorDb = context(identities.otherDoctor);
  const usagePath = 'organizations/org-a/patients/patient-a/medical_service_usage/service-glasses';

  await testEnvironment.withSecurityRulesDisabled(async (adminContext) => {
    await setDoc(doc(adminContext.firestore(), usagePath), {
      organizationId: 'org-a',
      patientId: 'patient-a',
      serviceId: 'service-glasses',
      lastServiceAt: Timestamp.fromDate(new Date('2026-01-01T00:00:00.000Z')),
    });
  });
  await assertSucceeds(getDoc(doc(doctorDb, usagePath)));
  await assertFails(getDoc(doc(otherDoctorDb, usagePath)));
});

test('only organization owners and admins can grant a repeat override permission', async () => {
  const ownerDb = context(identities.owner);
  const doctorDb = context(identities.doctor);
  const permissionPath = 'organizations/org-a/medical_service_override_permissions/doctor-a';
  const permission = {
    doctorId: 'doctor-a',
    permission: 'service_repeat_override',
    active: true,
    changedBy: identities.owner.uid,
    updatedAt: serverTimestamp(),
  };

  await assertSucceeds(setDoc(doc(ownerDb, permissionPath), permission));
  await assertFails(setDoc(doc(doctorDb, permissionPath), {
    ...permission,
    changedBy: identities.doctor.uid,
  }));
  await assertFails(deleteDoc(doc(ownerDb, permissionPath)));
});
