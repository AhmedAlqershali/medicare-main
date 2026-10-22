const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { initializeApp } = require('firebase-admin/app');
const { logger } = require('firebase-functions');
const { HttpsError, onCall } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const {
  classifyPatientIdentity,
  isActiveClinic,
  normalizePatientEmail,
  patientEmailIndexPath,
} = require('./patient_identity');

initializeApp();
const db = getFirestore();
const pageSize = 250;
const workBatchSize = 25;
const dayMilliseconds = 24 * 60 * 60 * 1000;
const validDatingMethods = new Set([
  'lastMenstrualPeriod',
  'estimatedStartDate',
  'gestationalAgeAtReference',
]);

function callableValue(value) {
  if (value != null && typeof value.toDate === 'function') {
    return value.toDate().toISOString();
  }
  if (Array.isArray(value)) return value.map(callableValue);
  if (value != null && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value).map(([key, item]) => [key, callableValue(item)]),
    );
  }
  return value;
}

function authenticatedIdentity(request) {
  const uid = request.auth?.uid;
  const email = normalizePatientEmail(request.auth?.token?.email);
  if (uid == null || request.auth.token.email_verified !== true || email === '') {
    throw new HttpsError('unauthenticated', 'يلزم حساب موثق ببريد إلكتروني مؤكد.');
  }
  return { uid, email };
}

async function authenticatedProfile(request) {
  const { uid, email } = authenticatedIdentity(request);
  const profileSnapshot = await db.doc(`users/${uid}`).get();
  const profile = profileSnapshot.data();
  if (profile == null || profile.uid !== uid ||
      normalizePatientEmail(profile.email) !== email) {
    throw new HttpsError('permission-denied', 'ملف المستخدم غير مطابق لحساب Firebase.');
  }
  return { uid, email, profile };
}

async function activeDoctorContext(request) {
  const { uid, profile } = await authenticatedProfile(request);
  const organizationId = profile.organizationId;
  const doctorId = profile.doctorId;
  if (profile.role !== 'doctor' || typeof organizationId !== 'string' ||
      typeof doctorId !== 'string') {
    throw new HttpsError('permission-denied', 'يلزم ملف طبيب مرتبط بمؤسسة.');
  }

  const organizationRef = db.collection('organizations').doc(organizationId);
  const doctorRef = organizationRef.collection('doctors').doc(doctorId);
  const [organizationSnapshot, doctorSnapshot] = await Promise.all([
    organizationRef.get(),
    doctorRef.get(),
  ]);
  const organization = organizationSnapshot.data();
  const doctor = doctorSnapshot.data();
  if (organization?.status !== 'active' || doctor == null ||
      doctor.status !== 'active' || doctor.firebaseUid !== uid ||
      doctor.organizationId !== organizationId ||
      typeof doctor.clinicId !== 'string' || doctor.clinicId.trim() === '') {
    throw new HttpsError('permission-denied', 'الطبيب أو المؤسسة أو العيادة غير نشطة.');
  }

  const clinicRef = organizationRef.collection('clinics').doc(doctor.clinicId);
  const clinicSnapshot = await clinicRef.get();
  const clinic = clinicSnapshot.data();
    if (clinic == null || clinic.organizationId !== organizationId ||
      !isActiveClinic(clinic.status)) {
    throw new HttpsError('permission-denied', 'عيادة الطبيب غير صالحة ضمن المؤسسة.');
  }

  return {
    uid,
    organizationId,
    doctorId,
    doctor,
    clinicId: doctor.clinicId,
    clinic,
    organizationRef,
  };
}

async function activeOrganizationClinicContext(request, clinicId) {
  const { uid, profile } = await authenticatedProfile(request);
  const organizationId = profile.organizationId;
  if (profile.role !== 'organization' ||
      typeof organizationId !== 'string') {
    throw new HttpsError('permission-denied', 'لا تملك المؤسسة صلاحية هذه العيادة.');
  }

  const organizationRef = db.collection('organizations').doc(organizationId);
  const [organizationSnapshot, clinicSnapshot] = await Promise.all([
    organizationRef.get(),
    organizationRef.collection('clinics').doc(clinicId).get(),
  ]);
  const organization = organizationSnapshot.data();
  const clinic = clinicSnapshot.data();
  const isOwner = organization?.firebaseUid === uid || organization?.ownerUid === uid;
  const hasClinicScope = typeof profile.clinicId === 'string' &&
    profile.clinicId.trim() !== '';
    if (organization?.status !== 'active' || clinic == null ||
      clinic.organizationId !== organizationId || !isActiveClinic(clinic.status)) {
    throw new HttpsError('permission-denied', 'المؤسسة أو العيادة غير نشطة.');
  }
  if (hasClinicScope && !isOwner && profile.clinicId !== clinicId) {
    throw new HttpsError('permission-denied', 'لا تملك المؤسسة صلاحية هذه العيادة.');
  }
  return { organizationId, organizationRef };
}

function patientForCallable(snapshot) {
  return {
    ...callableValue(snapshot.data()),
    id: snapshot.id,
  };
}

exports.registerPatientVisit = onCall({ region: 'us-central1' }, async (request) => {
  const context = await activeDoctorContext(request);
  const name = typeof request.data?.name === 'string' ? request.data.name.trim() : '';
  const email = normalizePatientEmail(request.data?.email);
  const problemLocation = typeof request.data?.problemLocation === 'string'
    ? request.data.problemLocation.trim()
    : '';
  const medicalNotes = typeof request.data?.medicalNotes === 'string'
    ? request.data.medicalNotes.trim()
    : '';
  const appointmentAtMillis = request.data?.appointmentAtMillis;
  const appointmentTime = typeof request.data?.appointmentTime === 'string'
    ? request.data.appointmentTime.trim()
    : '';
  if (name === '' || !/^[^@\s/]+@[^@\s/]+\.[^@\s/]+$/.test(email)) {
    throw new HttpsError('invalid-argument', 'اسم المريض أو بريده الإلكتروني غير صالح.');
  }
  if (!Number.isSafeInteger(appointmentAtMillis) ||
      appointmentAtMillis <= Date.now() || appointmentTime === '') {
    throw new HttpsError('invalid-argument', 'يجب تحديد موعد قادم صالح.');
  }

  const patientsRef = context.organizationRef.collection('patients');
  const emailIndexRef = db.doc(
    patientEmailIndexPath(context.organizationId, email),
  );
  const indexHint = await emailIndexRef.get();
  const identity = indexHint.exists
    ? { kind: 'indexed' }
    : classifyPatientIdentity(
      (await patientsRef.get()).docs.map((document) => ({
        id: document.id,
        email: document.data().email,
        name: document.data().name,
        reference: document.ref,
      })),
      email,
      name,
    );
  const emailMatches = identity.kind === 'reuse'
    ? [identity.patient]
    : identity.kind === 'duplicate' ? identity.candidates : [];
  if (emailMatches.length > 1) {
    throw new HttpsError(
      'failed-precondition',
      'توجد سجلات متعددة بهذا البريد داخل المؤسسة؛ يلزم تدقيقها يدويًا قبل المتابعة.',
      {
        reason: 'duplicate_email',
        candidates: emailMatches.map((patient) => ({
          id: patient.id,
          name: patient.name ?? '',
          email: patient.email ?? '',
        })),
      },
    );
  }
  if (identity.kind === 'review') {
    throw new HttpsError(
      'failed-precondition',
      'يوجد سجل باسم مطابق دون هوية مؤكدة؛ راجعه يدويًا ولا تربطه تلقائيًا.',
      {
        reason: 'name_review',
        candidates: identity.candidates.slice(0, 5).map((patient) => ({
          id: patient.id,
          name: patient.name ?? '',
          email: patient.email ?? '',
        })),
      },
    );
  }

  const patientId = await db.runTransaction(async (transaction) => {
    const indexSnapshot = await transaction.get(emailIndexRef);
    const querySnapshot = await transaction.get(
      patientsRef.where('email', '==', email).limit(3),
    );
    const transactionMatches = querySnapshot.docs;
    if (transactionMatches.length > 1) {
      throw new HttpsError(
        'failed-precondition',
        'توجد سجلات متعددة بهذا البريد داخل المؤسسة؛ يلزم تدقيقها يدويًا.',
        {
          reason: 'duplicate_email',
          candidates: transactionMatches.map((document) => ({
            id: document.id,
            name: document.data().name ?? '',
            email: document.data().email ?? '',
          })),
        },
      );
    }

    let patientRef;
    let patientSnapshot;
    if (indexSnapshot.exists) {
      const index = indexSnapshot.data();
      if (index.organizationId !== context.organizationId ||
          index.email !== email || typeof index.patientId !== 'string') {
        throw new HttpsError('data-loss', 'فهرس المريض غير متطابق مع المؤسسة.');
      }
      patientRef = patientsRef.doc(index.patientId);
      patientSnapshot = await transaction.get(patientRef);
      if (!patientSnapshot.exists ||
          normalizePatientEmail(patientSnapshot.data().email) !== email ||
          (transactionMatches.length === 1 &&
            transactionMatches[0].id !== patientRef.id)) {
        throw new HttpsError('data-loss', 'تعذر التحقق من سجل المريض في المؤسسة.');
      }
    } else if (transactionMatches.length === 1) {
      patientSnapshot = transactionMatches[0];
      patientRef = patientSnapshot.ref;
    } else if (emailMatches.length === 1) {
      patientRef = patientsRef.doc(emailMatches[0].id);
      patientSnapshot = await transaction.get(patientRef);
      if (!patientSnapshot.exists ||
          normalizePatientEmail(patientSnapshot.data().email) !== email) {
        throw new HttpsError('aborted', 'تغير سجل المريض أثناء التحقق؛ أعد المحاولة.');
      }
    } else {
      patientRef = patientsRef.doc();
    }

    const now = FieldValue.serverTimestamp();
    let patientData;
    if (patientSnapshot?.exists) {
      patientData = patientSnapshot.data();
      if ((patientData.organizationId != null &&
          patientData.organizationId !== context.organizationId) ||
          (patientData.id != null && patientData.id !== patientRef.id) ||
          patientData.status === 'inactive' ||
          (patientData.status === 'pending' &&
            patientData.firebaseUid != null && patientData.firebaseUid !== '')) {
        throw new HttpsError('failed-precondition', 'سجل المريض غير صالح أو غير نشط.');
      }
      transaction.update(patientRef, {
        id: patientRef.id,
        organizationId: context.organizationId,
        email,
        updatedAt: now,
      });
    } else {
      patientData = {
        id: patientRef.id,
        name,
        email,
        doctorId: context.doctorId,
        organizationId: context.organizationId,
        clinicId: context.clinicId,
        status: 'pending',
        accountActivated: false,
        initials: name.split(/\s+/).slice(0, 2).map((part) => part[0]).join('').toUpperCase(),
        firebaseUid: null,
        problemLocation: problemLocation || null,
        medicalNotesHistory: [],
        createdAt: now,
        updatedAt: now,
      };
      transaction.create(patientRef, patientData);
    }

    transaction.set(emailIndexRef, {
      email,
      organizationId: context.organizationId,
      patientId: patientRef.id,
      updatedAt: now,
      createdAt: indexSnapshot.data()?.createdAt ?? now,
    }, { merge: true });

    transaction.set(patientRef.collection('clinic_access').doc(context.doctorId), {
      patientId: patientRef.id,
      organizationId: context.organizationId,
      doctorId: context.doctorId,
      clinicId: context.clinicId,
      updatedAt: now,
    }, { merge: true });
    transaction.set(
      patientRef.collection('clinic_access_by_clinic').doc(context.clinicId),
      {
        patientId: patientRef.id,
        organizationId: context.organizationId,
        clinicId: context.clinicId,
        updatedAt: now,
      },
      { merge: true },
    );

    const appointmentRef = context.organizationRef.collection('appointments').doc();
    const appointmentDate = Timestamp.fromMillis(appointmentAtMillis);
    const patientName = patientSnapshot?.data()?.name ?? name;
    const patientUid = patientSnapshot?.data()?.firebaseUid ?? null;
    const birthDate = patientSnapshot?.data()?.birthDate;
    let age = '';
    if (typeof birthDate === 'string') {
      const parsedBirthDate = new Date(birthDate);
      if (!Number.isNaN(parsedBirthDate.getTime())) {
        const appointmentDay = new Date(appointmentAtMillis);
        let years = appointmentDay.getFullYear() - parsedBirthDate.getFullYear();
        if (appointmentDay.getMonth() < parsedBirthDate.getMonth() ||
            (appointmentDay.getMonth() === parsedBirthDate.getMonth() &&
              appointmentDay.getDate() < parsedBirthDate.getDate())) years--;
        if (years >= 0) age = `${years} سنة`;
      }
    }
    transaction.create(appointmentRef, {
      id: appointmentRef.id,
      organizationId: context.organizationId,
      clinicId: context.clinicId,
      doctorId: context.doctorId,
      patientId: patientRef.id,
      patientUid,
      patientName,
      patientInitials: patientSnapshot?.data()?.initials ?? patientData.initials ?? '',
      age,
      gender: patientSnapshot?.data()?.gender ?? '',
      doctorName: context.doctor.name ?? '',
      doctorInitials: context.doctor.initials ?? '',
      specialty: context.doctor.specialty ?? '',
      clinicName: context.clinic.name ?? '',
      location: context.clinic.location ?? '',
      date: appointmentDate,
      time: appointmentTime,
      type: 'زيارة في العيادة',
      status: 'upcoming',
      notes: '',
      createdAt: now,
      updatedAt: now,
      createdBy: context.uid,
    });

    if (medicalNotes !== '') {
      const noteRef = patientRef.collection('medical_notes').doc();
      transaction.create(noteRef, {
        text: medicalNotes,
        createdAt: now,
        doctorUid: context.uid,
        doctorName: context.doctor.name ?? '',
      });
    }

    const responsePatient = patientSnapshot?.data() ?? patientData;
    return {
      patientId: patientRef.id,
      reused: patientSnapshot?.exists === true,
      patient: callableValue({
        id: patientRef.id,
        name: responsePatient.name ?? name,
        email: responsePatient.email ?? email,
        doctorId: responsePatient.doctorId ?? context.doctorId,
        organizationId: context.organizationId,
        clinicId: responsePatient.clinicId ?? context.clinicId,
        status: responsePatient.status ?? 'pending',
        accountActivated: responsePatient.accountActivated ?? false,
        initials: responsePatient.initials ?? '',
        firebaseUid: responsePatient.firebaseUid ?? null,
        phone: responsePatient.phone ?? null,
        birthDate: responsePatient.birthDate ?? null,
        gender: responsePatient.gender ?? null,
        notes: responsePatient.notes ?? null,
        problemLocation: responsePatient.problemLocation ?? problemLocation ?? null,
        medicalNotes: responsePatient.medicalNotes ?? null,
        medicalNotesHistory: responsePatient.medicalNotesHistory ?? [],
        createdAt: patientSnapshot?.data()?.createdAt ?? null,
        updatedAt: patientSnapshot?.data()?.updatedAt ?? null,
      }),
    };
  });

  return patientId;
});

exports.listPatientsForDoctor = onCall({ region: 'us-central1' }, async (request) => {
  const context = await activeDoctorContext(request);
  const patientCollection = context.organizationRef.collection('patients');
  const [primaryPatients, assignedPatients] = await Promise.all([
    patientCollection.where('doctorId', '==', context.doctorId).get(),
    db.collectionGroup('clinic_access')
      .where('organizationId', '==', context.organizationId)
      .where('doctorId', '==', context.doctorId)
      .where('clinicId', '==', context.clinicId)
      .get(),
  ]);

  const patientReferences = new Map();
  for (const document of primaryPatients.docs) {
    const patient = document.data();
    if (patient.organizationId === context.organizationId &&
        (patient.clinicId == null || patient.clinicId === context.clinicId)) {
      patientReferences.set(document.id, document.ref);
    }
  }
  for (const access of assignedPatients.docs) {
    const segments = access.ref.path.split('/');
    const data = access.data();
    if (segments.length === 6 && segments[0] === 'organizations' &&
        segments[1] === context.organizationId && segments[2] === 'patients' &&
        segments[4] === 'clinic_access' && segments[5] === context.doctorId &&
        data.patientId === segments[3] && data.clinicId === context.clinicId) {
      patientReferences.set(segments[3], patientCollection.doc(segments[3]));
    }
  }

  const patients = await Promise.all([...patientReferences.entries()].map(
    async ([patientId, reference]) => {
      const snapshot = await reference.get();
      if (!snapshot.exists || snapshot.data().organizationId !== context.organizationId) {
        return null;
      }
      return patientForCallable(snapshot);
    },
  ));
  return { patients: patients.filter((patient) => patient != null) };
});

exports.findPendingPatientActivation = onCall({ region: 'us-central1' }, async (request) => {
  const { uid, email } = authenticatedIdentity(request);
  const userSnapshot = await db.doc(`users/${uid}`).get();
  const userProfile = userSnapshot.data();
  if (userProfile != null &&
      (userProfile.role !== 'patient' ||
        normalizePatientEmail(userProfile.email) !== email)) {
    throw new HttpsError(
      'permission-denied',
      'حساب Firebase مرتبط بدور أو بريد مختلف ولا يمكن ربطه بسجل المريض.',
    );
  }

  const [matches, doctorLinks, organizationLinks, ownerLinks, adminSnapshot] =
    await Promise.all([
      db.collectionGroup('patients').get(),
      db.collectionGroup('doctors').where('firebaseUid', '==', uid).get(),
      db.collection('organizations').where('firebaseUid', '==', uid).get(),
      db.collection('organizations').where('ownerUid', '==', uid).get(),
      db.collection('admins').doc(uid).get(),
    ]);
  if (!doctorLinks.empty || !organizationLinks.empty || !ownerLinks.empty ||
      adminSnapshot.exists) {
    throw new HttpsError(
      'permission-denied',
      'حساب Firebase مرتبط بدور آخر ولا يمكن ربطه كسجل مريض.',
    );
  }
  const patientRecords = matches.docs.filter((document) => {
    const segments = document.ref.path.split('/');
    const data = document.data();
    return segments.length === 4 && segments[0] === 'organizations' &&
      segments[2] === 'patients' && data.organizationId === segments[1] &&
      data.id === document.id && normalizePatientEmail(data.email) === email &&
      data.status === 'pending' && data.accountActivated === false &&
      (data.firebaseUid == null || data.firebaseUid === '');
  });

  if (patientRecords.length !== 1) {
    throw new HttpsError(
      'failed-precondition',
      patientRecords.length === 0
        ? 'لا يوجد سجل مريض معلّق بهذا البريد الإلكتروني.'
        : 'يوجد أكثر من سجل بهذا البريد في مؤسسات مختلفة أو في المؤسسة نفسها؛ يلزم التحقق اليدوي.',
      { reason: patientRecords.length === 0 ? 'not_found' : 'ambiguous_activation' },
    );
  }

  const snapshot = patientRecords[0];
  const patient = patientForCallable(snapshot);
  const linkedPatientRecords = matches.docs.filter((document) =>
    document.data().firebaseUid === uid);
  if (linkedPatientRecords.some((document) =>
    document.id !== patient.id ||
    document.ref.path !== snapshot.ref.path)) {
    throw new HttpsError(
      'permission-denied',
      'حساب Firebase مرتبط بسجل مريض آخر ولا يمكن نقله.',
    );
  }
  if (userProfile != null &&
      (userProfile.patientId !== patient.id ||
        userProfile.organizationId !== patient.organizationId ||
        userProfile.doctorId !== patient.doctorId)) {
    throw new HttpsError(
      'permission-denied',
      'حساب Firebase مرتبط بسجل مريض أو مؤسسة أخرى.',
    );
  }
  return { patient };
});

exports.listPatientsForClinic = onCall({ region: 'us-central1' }, async (request) => {
  const clinicId = typeof request.data?.clinicId === 'string'
    ? request.data.clinicId.trim()
    : '';
  if (clinicId === '') {
    throw new HttpsError('invalid-argument', 'معرّف العيادة مطلوب.');
  }
  const context = await activeOrganizationClinicContext(request, clinicId);
  const patientCollection = context.organizationRef.collection('patients');
  const [primaryPatients, assignedPatients, clinicDoctors] = await Promise.all([
    patientCollection.where('clinicId', '==', clinicId).get(),
    db.collectionGroup('clinic_access')
      .where('organizationId', '==', context.organizationId)
      .where('clinicId', '==', clinicId)
      .get(),
    context.organizationRef.collection('doctors').where('clinicId', '==', clinicId).get(),
  ]);
  const references = new Map();
  for (const document of primaryPatients.docs) {
    references.set(document.id, document.ref);
  }
  for (const access of assignedPatients.docs) {
    const segments = access.ref.path.split('/');
    const data = access.data();
    if (segments.length === 6 && segments[0] === 'organizations' &&
        segments[1] === context.organizationId && segments[2] === 'patients' &&
        segments[4] === 'clinic_access' && data.patientId === segments[3] &&
        data.clinicId === clinicId) {
      references.set(segments[3], patientCollection.doc(segments[3]));
    }
  }

  const legacyDoctorIds = clinicDoctors.docs
    .filter((document) => document.data().status === 'active')
    .map((document) => document.id);
  for (let index = 0; index < legacyDoctorIds.length; index += 30) {
    const doctorIds = legacyDoctorIds.slice(index, index + 30);
    if (doctorIds.length === 0) continue;
    const legacyPatients = await patientCollection
      .where('doctorId', 'in', doctorIds)
      .get();
    for (const document of legacyPatients.docs) {
      const patient = document.data();
      if (patient.clinicId == null && patient.organizationId === context.organizationId) {
        references.set(document.id, document.ref);
      }
    }
  }

  const patients = await Promise.all([...references.values()].map(async (reference) => {
    const snapshot = await reference.get();
    if (!snapshot.exists || snapshot.data().organizationId !== context.organizationId) {
      return null;
    }
    return patientForCallable(snapshot);
  }));
  return { patients: patients.filter((patient) => patient != null) };
});

function pregnancyArchiveAt(pregnancy) {
  if (pregnancy == null || typeof pregnancy !== 'object') return null;
  const { datingMethod, referenceDate } = pregnancy;
  const weeks = pregnancy.gestationalWeeksAtReference;
  const days = pregnancy.gestationalDaysAtReference;
  if (!validDatingMethods.has(datingMethod) ||
      referenceDate == null || typeof referenceDate.toDate !== 'function' ||
      !Number.isInteger(weeks) || !Number.isInteger(days) ||
      weeks < 0 || weeks > 42 || days < 0 || days > 6 ||
      weeks * 7 + days > 294) {
    return null;
  }
  if (datingMethod === 'gestationalAgeAtReference') {
    if (weeks * 7 + days === 0) return null;
  } else if (weeks !== 0 || days !== 0) {
    return null;
  }

  const reference = referenceDate.toDate();
  const referenceDay = Date.UTC(
    reference.getUTCFullYear(),
    reference.getUTCMonth(),
    reference.getUTCDate(),
  );
  const baselineDays = weeks * 7 + days;
  return {
    archiveAt: referenceDay + (294 - baselineDays) * dayMilliseconds,
    expectedDueDate: referenceDay + (280 - baselineDays) * dayMilliseconds,
  };
}

async function archiveIfDue(reference, now) {
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    if (!snapshot.exists) return false;

    const data = snapshot.data();
    if (data.type !== 'pregnancy' ||
        !['active', 'monitoring', 'completed'].includes(data.status)) {
      return false;
    }

    const dates = pregnancyArchiveAt(data.pregnancy);
    if (dates == null || dates.archiveAt > now.toMillis()) return false;

    transaction.update(reference, {
      status: 'archived',
      completedAt: data.completedAt ?? FieldValue.serverTimestamp(),
      archivedAt: FieldValue.serverTimestamp(),
      archiveReason: 'pregnancy_period_elapsed',
      updatedAt: FieldValue.serverTimestamp(),
      'pregnancy.expectedDueDate': Timestamp.fromMillis(dates.expectedDueDate),
      'pregnancy.archiveAt': Timestamp.fromMillis(dates.archiveAt),
    });
    return true;
  });
}

exports.archiveEndedPregnancies = onSchedule({
  schedule: 'every day 01:15',
  timeZone: 'UTC',
  region: 'us-central1',
  timeoutSeconds: 540,
  memory: '512MiB',
  maxInstances: 1,
}, async () => {
  const now = Timestamp.now();
  const baseQuery = db.collectionGroup('medical_cases')
    .where('type', '==', 'pregnancy');
  let cursor = null;
  let scanned = 0;
  let archived = 0;

  while (true) {
    let query = baseQuery.limit(pageSize);
    if (cursor != null) query = baseQuery.startAfter(cursor).limit(pageSize);
    const page = await query.get();
    if (page.empty) break;

    for (let index = 0; index < page.docs.length; index += workBatchSize) {
      const work = page.docs.slice(index, index + workBatchSize);
      const results = await Promise.all(work.map(async (document) => {
        const path = document.ref.path.split('/');
        if (path.length !== 6 ||
            path[0] !== 'organizations' ||
            path[2] !== 'patients' ||
            path[4] !== 'medical_cases') {
          return false;
        }
        return archiveIfDue(document.ref, now);
      }));
      scanned += work.length;
      archived += results.filter(Boolean).length;
    }

    cursor = page.docs[page.docs.length - 1];
    if (page.size < pageSize) break;
  }

  logger.info('Pregnancy archive run completed', { scanned, archived });
});
