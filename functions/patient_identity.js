'use strict';

function normalizePatientEmail(value) {
  return typeof value === 'string' ? value.trim().toLowerCase() : '';
}

function normalizePatientName(value) {
  return typeof value === 'string'
    ? value.normalize('NFKC').trim().replace(/\s+/g, ' ').toLowerCase()
    : '';
}

function isActiveClinic(status) {
  return status == null || ['active', 'نشطة', 'نشط'].includes(status);
}

function similarPatientName(first, second) {
  const left = normalizePatientName(first);
  const right = normalizePatientName(second);
  if (left === '' || right === '') return false;
  if (left === right || left.includes(right) || right.includes(left)) return true;

  const leftTokens = new Set(left.split(' '));
  const rightTokens = new Set(right.split(' '));
  const sharedTokens = [...leftTokens].filter((token) => rightTokens.has(token)).length;
  if (sharedTokens > 0 && sharedTokens / Math.max(leftTokens.size, rightTokens.size) >= 0.75) {
    return true;
  }

  if (Math.min(left.length, right.length) < 5) return false;
  let previous = Array.from({ length: right.length + 1 }, (_, index) => index);
  for (let row = 1; row <= left.length; row++) {
    const current = [row];
    for (let column = 1; column <= right.length; column++) {
      const substitution = previous[column - 1] +
        (left[row - 1] === right[column - 1] ? 0 : 1);
      current[column] = Math.min(
        previous[column] + 1,
        current[column - 1] + 1,
        substitution,
      );
    }
    previous = current;
  }
  return 1 - previous[right.length] / Math.max(left.length, right.length) >= 0.82;
}

function patientEmailIndexPath(organizationId, email) {
  const normalizedEmail = normalizePatientEmail(email);
  if (typeof organizationId !== 'string' || organizationId.trim() === '' ||
      normalizedEmail === '') {
    throw new TypeError('Organization and patient email are required.');
  }
  return `organizations/${organizationId.trim()}/patient_email_index/${normalizedEmail}`;
}

function classifyPatientIdentity(records, email, name) {
  const normalizedEmail = normalizePatientEmail(email);
  const normalizedName = normalizePatientName(name);
  const emailMatches = records.filter((record) =>
    normalizePatientEmail(record.email) === normalizedEmail);
  if (emailMatches.length > 1) {
    return { kind: 'duplicate', candidates: emailMatches };
  }
  if (emailMatches.length === 1) {
    return { kind: 'reuse', patient: emailMatches[0] };
  }

  const nameMatches = records.filter((record) =>
    similarPatientName(record.name, normalizedName));
  if (nameMatches.length > 0) {
    return { kind: 'review', candidates: nameMatches };
  }
  return { kind: 'create', candidates: [] };
}

module.exports = {
  classifyPatientIdentity,
  normalizePatientEmail,
  normalizePatientName,
  patientEmailIndexPath,
  similarPatientName,
  isActiveClinic,
};