'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  addCalendarMonths,
  isRepeatBlocked,
  serviceEligibilityDate,
} = require('../service_restrictions');

test('supports twelve-month service intervals with end-of-month clamping', () => {
  const serviceAt = new Date('2026-01-31T10:30:00.000Z');

  assert.equal(
    serviceEligibilityDate(serviceAt, 12).toISOString(),
    '2027-01-31T10:30:00.000Z',
  );
  assert.equal(
    addCalendarMonths(serviceAt, 1).toISOString(),
    '2026-02-28T10:30:00.000Z',
  );
});

test('supports no restriction and different intervals', () => {
  const serviceAt = new Date('2026-05-05T00:00:00.000Z');

  assert.equal(serviceEligibilityDate(serviceAt, 0), null);
  assert.equal(
    serviceEligibilityDate(serviceAt, 3).toISOString(),
    '2026-08-05T00:00:00.000Z',
  );
});

test('blocks strictly before the due instant but allows at due time', () => {
  const dueAt = new Date('2027-01-31T10:30:00.000Z');

  assert.equal(isRepeatBlocked(dueAt, dueAt.getTime() - 1), true);
  assert.equal(isRepeatBlocked(dueAt, dueAt.getTime()), false);
  assert.equal(isRepeatBlocked(null, Date.now()), false);
});
