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
const {
  isPregnancyArchiveDue,
  pregnancyArchiveDates,
} = require('./pregnancy_archive');
const {
  normalizeRepeatIntervalMonths,
  serviceEligibilityDate,
  isRepeatBlocked,
} = require('./service_restrictions');

initializeApp();
const db = getFirestore();
const pageSize = 250;
const workBatchSize = 25;

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

exports.completeAppointmentWithService = onCall({ region: 'us-central1' }, async (request) => {
  const context = await activeDoctorContext(request);
  const appointmentId = typeof request.data?.appointmentId === 'string'
    ? request.data.appointmentId.trim()
    : '';
  const overrideReason = typeof request.data?.overrideReason === 'string'
    ? request.data.overrideReason.trim()
    : '';
  if (appointmentId === '' || overrideReason.length > 1000) {
    throw new HttpsError('invalid-argument', 'معرّف الموعد أو سبب الاستثناء غير صالح.');
  }

  const organizationRef = context.organizationRef;
  const appointmentRef = organizationRef.collection('appointments').doc(appointmentId);
  const result = await db.runTransaction(async (transaction) => {
    const appointmentSnapshot = await transaction.get(appointmentRef);
    const appointment = appointmentSnapshot.data();
    if (!appointmentSnapshot.exists || appointment == null ||
        appointment.organizationId !== context.organizationId ||
        appointment.doctorId !== context.doctorId ||
      appointment.clinicId !== context.clinicId ||
        typeof appointment.patientId !== 'string' ||
        typeof appointment.clinicId !== 'string') {
      throw new HttpsError('permission-denied', 'الموعد لا يتبع الطبيب أو المؤسسة الحالية.');
    }

    if (appointment.status === 'completed') {
      return { alreadyCompleted: true };
    }
    if (appointment.status !== 'upcoming' ||
        typeof appointment.date?.toMillis !== 'function' ||
        appointment.date.toMillis() > Date.now()) {
      throw new HttpsError('failed-precondition', 'لا يمكن إكمال موعد غير مستحق أو ملغى.');
    }

    const serviceId = appointment.serviceId;
    if (serviceId == null) {
      transaction.update(appointmentRef, {
        status: 'completed',
        updatedAt: FieldValue.serverTimestamp(),
      });
      return { alreadyCompleted: false, nextEligibleAt: null };
    }
    if (typeof serviceId !== 'string' || serviceId.trim() === '') {
      throw new HttpsError('failed-precondition', 'معرّف الخدمة المرتبطة بالموعد غير صالح.');
    }

    const patientRef = organizationRef.collection('patients').doc(appointment.patientId);
    const clinicRef = organizationRef.collection('clinics').doc(appointment.clinicId);
    const clinicAccessRef = patientRef.collection('clinic_access').doc(context.doctorId);

    const serviceRef = db.collection('medical_catalog').doc(serviceId);
    const usageRef = patientRef.collection('medical_service_usage').doc(serviceId);
    const historyRef = patientRef.collection('medical_service_history').doc(appointmentId);
    const permissionRef = organizationRef
      .collection('medical_service_override_permissions')
      .doc(context.doctorId);
    const [patientSnapshot, clinicSnapshot, clinicAccessSnapshot,
      serviceSnapshot, usageSnapshot, historySnapshot, permissionSnapshot] =
      await Promise.all([
        transaction.get(patientRef),
        transaction.get(clinicRef),
        transaction.get(clinicAccessRef),
        transaction.get(serviceRef),
        transaction.get(usageRef),
        transaction.get(historyRef),
        transaction.get(permissionRef),
      ]);

    if (historySnapshot.exists) {
      if (appointment.status === 'completed') {
        return { alreadyCompleted: true };
      }
      throw new HttpsError('failed-precondition', 'سجل تقديم هذه الخدمة موجود مسبقًا.');
    }
    if (appointment.status !== 'upcoming') {
      throw new HttpsError('failed-precondition', 'الموعد غير قابل للإكمال مرة أخرى.');
    }

    const patient = patientSnapshot.data();
    const clinic = clinicSnapshot.data();
    const service = serviceSnapshot.data();
    const directClinicAccess = patient?.doctorId === context.doctorId &&
      patient?.clinicId === appointment.clinicId;
    const explicitClinicAccess = clinicAccessSnapshot.exists &&
      clinicAccessSnapshot.data()?.organizationId === context.organizationId &&
      clinicAccessSnapshot.data()?.patientId === appointment.patientId &&
      clinicAccessSnapshot.data()?.doctorId === context.doctorId &&
      clinicAccessSnapshot.data()?.clinicId === appointment.clinicId;
    if (patient?.organizationId !== context.organizationId ||
        clinic == null || clinic.organizationId !== context.organizationId ||
        !isActiveClinic(clinic.status) ||
        (!directClinicAccess && !explicitClinicAccess)) {
      throw new HttpsError('permission-denied', 'المريض أو العيادة غير مرتبطين بالموعد الحالي.');
    }
    if (service?.kind !== 'service') {
      throw new HttpsError('failed-precondition', 'الخدمة المرتبطة بالموعد غير موجودة في الدليل.');
    }

    const serviceAt = Date.now();
    const repeatIntervalMonths =
      normalizeRepeatIntervalMonths(service.repeatIntervalMonths);
    if (repeatIntervalMonths == null) {
      throw new HttpsError('failed-precondition', 'مدة تكرار الخدمة غير صالحة.');
    }
    let lastServiceAt = usageSnapshot.data()?.lastServiceAt?.toDate?.() ?? null;
    const priorAppointments = await transaction.get(
      organizationRef.collection('appointments')
        .where('patientId', '==', appointment.patientId),
    );
    const priorHistory = await transaction.get(
      patientRef.collection('medical_service_history')
        .where('serviceId', '==', serviceId),
    );
    for (const priorDocument of priorAppointments.docs) {
      const priorAppointment = priorDocument.data();
      if (priorDocument.id === appointmentId ||
          priorAppointment.serviceId !== serviceId ||
          priorAppointment.status !== 'completed') continue;
      const priorServiceAt = priorAppointment.serviceCompletedAt?.toDate?.() ??
        priorAppointment.date?.toDate?.() ?? null;
      if (priorServiceAt != null &&
          (lastServiceAt == null || priorServiceAt > lastServiceAt)) {
        lastServiceAt = priorServiceAt;
      }
    }
    for (const historyDocument of priorHistory.docs) {
      const priorServiceAt = historyDocument.data().serviceAt?.toDate?.() ?? null;
      if (priorServiceAt != null &&
          (lastServiceAt == null || priorServiceAt > lastServiceAt)) {
        lastServiceAt = priorServiceAt;
      }
    }
    const previousNextEligibleAt = lastServiceAt == null
      ? null
      : serviceEligibilityDate(lastServiceAt, repeatIntervalMonths);
    const blocked = repeatIntervalMonths > 0 &&
      isRepeatBlocked(previousNextEligibleAt, serviceAt);
    const permission = permissionSnapshot.data();
    const hasOverridePermission = permission?.active === true &&
      permission.permission === 'service_repeat_override';
    if (blocked && !hasOverridePermission) {
      throw new HttpsError(
        'failed-precondition',
        `الخدمة متاحة مجددًا في ${previousNextEligibleAt.toISOString().slice(0, 10)}.`,
      );
    }
    if (blocked && overrideReason === '') {
      throw new HttpsError('invalid-argument', 'أدخل سبب الاستثناء الطبي.');
    }

    const serviceAtDate = new Date(serviceAt);
    const nextEligibleAt = serviceEligibilityDate(serviceAtDate, repeatIntervalMonths);
    const serviceTimestamp = Timestamp.fromDate(serviceAtDate);
    const nextEligibleTimestamp = nextEligibleAt == null
      ? null
      : Timestamp.fromDate(nextEligibleAt);
    transaction.update(appointmentRef, {
      status: 'completed',
      serviceCompletedAt: serviceTimestamp,
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.set(usageRef, {
      organizationId: context.organizationId,
      patientId: appointment.patientId,
      serviceId,
      lastServiceAt: serviceTimestamp,
      nextEligibleAt: nextEligibleTimestamp,
      lastAppointmentId: appointmentId,
      doctorId: context.doctorId,
      clinicId: appointment.clinicId,
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.create(historyRef, {
      id: appointmentId,
      appointmentId,
      organizationId: context.organizationId,
      patientId: appointment.patientId,
      serviceId,
      serviceName: service.nameAr || service.nameEn || serviceId,
      doctorId: context.doctorId,
      clinicId: appointment.clinicId,
      serviceAt: serviceTimestamp,
      repeatIntervalMonths,
      nextEligibleAt: nextEligibleTimestamp,
      overrideApplied: blocked,
      ...(blocked ? { overrideReason, overrideDoctorId: context.doctorId,
        overrideClinicId: appointment.clinicId } : {}),
      recordedByUid: context.uid,
      createdAt: FieldValue.serverTimestamp(),
    });
    return { alreadyCompleted: false, nextEligibleAt: nextEligibleAt?.toISOString() ?? null };
  });

  return result;
});

exports.getMedicalServiceUsage = onCall({ region: 'us-central1' }, async (request) => {
  const context = await activeDoctorContext(request);
  const patientId = typeof request.data?.patientId === 'string'
    ? request.data.patientId.trim()
    : '';
  const serviceId = typeof request.data?.serviceId === 'string'
    ? request.data.serviceId.trim()
    : '';
  if (patientId === '' || serviceId === '') {
    throw new HttpsError('invalid-argument', 'المريض والخدمة مطلوبان.');
  }

  const patientRef = context.organizationRef.collection('patients').doc(patientId);
  const clinicAccessRef = patientRef.collection('clinic_access').doc(context.doctorId);
  const serviceRef = db.collection('medical_catalog').doc(serviceId);
  const usageRef = patientRef.collection('medical_service_usage').doc(serviceId);
  const [patientSnapshot, clinicAccessSnapshot, serviceSnapshot, usageSnapshot] =
    await Promise.all([
      patientRef.get(),
      clinicAccessRef.get(),
      serviceRef.get(),
      usageRef.get(),
    ]);
  const patient = patientSnapshot.data();
  const clinicAccess = clinicAccessSnapshot.data();
  const directClinicAccess = patient?.doctorId === context.doctorId &&
    patient?.clinicId === context.clinicId;
  const explicitDoctorAccess = clinicAccess?.organizationId === context.organizationId &&
    clinicAccess.patientId === patientId &&
    clinicAccess.doctorId === context.doctorId &&
    clinicAccess.clinicId === context.clinicId;
  if (patient?.organizationId !== context.organizationId ||
      (!directClinicAccess && !explicitDoctorAccess)) {
    throw new HttpsError('permission-denied', 'لا يملك الطبيب صلاحية سجل هذا المريض.');
  }
  const service = serviceSnapshot.data();
  if (service?.kind !== 'service' ||
      !Array.isArray(context.doctor.serviceIds) ||
      !context.doctor.serviceIds.includes(serviceId)) {
    throw new HttpsError('not-found', 'الخدمة غير موجودة في الدليل.');
  }

  let lastServiceAt = usageSnapshot.data()?.lastServiceAt?.toDate?.() ?? null;
  const historySnapshot = await patientRef.collection('medical_service_history')
    .where('serviceId', '==', serviceId)
    .get();
  for (const historyDocument of historySnapshot.docs) {
    const historyAt = historyDocument.data().serviceAt?.toDate?.() ?? null;
    if (historyAt != null && (lastServiceAt == null || historyAt > lastServiceAt)) {
      lastServiceAt = historyAt;
    }
  }
  const appointmentSnapshot = await context.organizationRef
    .collection('appointments')
    .where('patientId', '==', patientId)
    .get();
  for (const appointmentDocument of appointmentSnapshot.docs) {
    const appointment = appointmentDocument.data();
    if (appointment.serviceId !== serviceId || appointment.status !== 'completed') continue;
    const appointmentServiceAt = appointment.serviceCompletedAt?.toDate?.() ??
      appointment.date?.toDate?.() ?? null;
    if (appointmentServiceAt != null &&
        (lastServiceAt == null || appointmentServiceAt > lastServiceAt)) {
      lastServiceAt = appointmentServiceAt;
    }
  }

  const interval = normalizeRepeatIntervalMonths(service.repeatIntervalMonths);
  if (interval == null) {
    throw new HttpsError('failed-precondition', 'مدة تكرار الخدمة غير صالحة.');
  }
  const nextEligibleAt = lastServiceAt == null
    ? null
    : serviceEligibilityDate(lastServiceAt, interval);
  return {
    lastServiceAt: lastServiceAt?.toISOString() ?? null,
    nextEligibleAt: nextEligibleAt?.toISOString() ?? null,
  };
});

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
  const [
    primaryPatients,
    assignedPatients,
    assignedClinicPatients,
    clinicDoctors,
  ] = await Promise.all([
    patientCollection.where('clinicId', '==', clinicId).get(),
    db.collectionGroup('clinic_access')
      .where('organizationId', '==', context.organizationId)
      .where('clinicId', '==', clinicId)
      .get(),
    db.collectionGroup('clinic_access_by_clinic')
      .where('organizationId', '==', context.organizationId)
      .where('clinicId', '==', clinicId)
      .get(),
    context.organizationRef.collection('doctors').where('clinicId', '==', clinicId).get(),
  ]);
  const references = new Map();
  for (const document of primaryPatients.docs) {
    references.set(document.id, document.ref);
  }
  for (const access of [
    ...assignedPatients.docs,
    ...assignedClinicPatients.docs,
  ]) {
    const segments = access.ref.path.split('/');
    const data = access.data();
    if (segments.length === 6 && segments[0] === 'organizations' &&
        segments[1] === context.organizationId && segments[2] === 'patients' &&
        ['clinic_access', 'clinic_access_by_clinic'].includes(segments[4]) &&
        data.organizationId === context.organizationId &&
        data.patientId === segments[3] &&
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

async function archiveIfDue(reference, now) {
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    if (!snapshot.exists) return false;

    const data = snapshot.data();
    if (!isPregnancyArchiveDue(data, now.toMillis())) return false;
    const dates = pregnancyArchiveDates(data.pregnancy);

    transaction.update(reference, {
      status: 'archived',
      completedAt: data.completedAt,
      archivedAt: FieldValue.serverTimestamp(),
      archiveReason: 'pregnancy_ended_and_period_elapsed',
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
