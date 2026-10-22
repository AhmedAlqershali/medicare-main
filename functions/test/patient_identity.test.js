'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  classifyPatientIdentity,
  isActiveClinic,
  normalizePatientEmail,
  patientEmailIndexPath,
} = require('../patient_identity');

test('normalizes email before matching within an organization', () => {
  const patient = { id: 'patient-1', email: ' Ahmad@Example.com ', name: 'Ahmad' };
  const match = classifyPatientIdentity([patient], 'ahmad@example.com', 'Ahmad');

  assert.equal(normalizePatientEmail(' Ahmad@Example.com '), 'ahmad@example.com');
  assert.equal(match.kind, 'reuse');
  assert.equal(match.patient.id, 'patient-1');
});

test('uses organization-scoped index paths for identical emails', () => {
  const email = 'person@example.com';

  assert.notEqual(
    patientEmailIndexPath('organization-a', email),
    patientEmailIndexPath('organization-b', email),
  );
});

test('does not merge a name-only match', () => {
  const match = classifyPatientIdentity(
    [{ id: 'patient-1', email: 'old@example.com', name: 'Ahmad Ali' }],
    'new@example.com',
    '  AHMAD   Ali ',
  );

  assert.equal(match.kind, 'review');
  assert.deepEqual(match.candidates.map((patient) => patient.id), ['patient-1']);
});

test('flags close name spellings for manual review', () => {
  const match = classifyPatientIdentity(
    [{ id: 'patient-1', email: 'old@example.com', name: 'Ahmad Hassan' }],
    'new@example.com',
    'Ahmad Hassa',
  );

  assert.equal(match.kind, 'review');
  assert.equal(match.candidates[0].id, 'patient-1');
});

test('reports duplicate email records for manual reconciliation', () => {
  const match = classifyPatientIdentity(
    [
      { id: 'patient-1', email: 'same@example.com', name: 'A' },
      { id: 'patient-2', email: ' SAME@example.com ', name: 'B' },
    ],
    'same@example.com',
    'A',
  );

  assert.equal(match.kind, 'duplicate');
  assert.equal(match.candidates.length, 2);
});

test('recognizes inactive clinic statuses used by the application', () => {
  assert.equal(isActiveClinic('نشطة'), true);
  assert.equal(isActiveClinic('active'), true);
  assert.equal(isActiveClinic('غير متاحة'), false);
  assert.equal(isActiveClinic('inactive'), false);
  assert.equal(isActiveClinic(undefined), true);
});