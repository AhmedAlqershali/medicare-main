'use strict';

const dayMilliseconds = 24 * 60 * 60 * 1000;

function addCalendarMonths(date, months) {
  if (!(date instanceof Date) || !Number.isFinite(date.getTime()) ||
      !Number.isInteger(months) || months < 0 || months > 1200) {
    throw new TypeError('A valid date and month interval are required.');
  }
  if (months === 0) return null;

  const targetMonth = date.getUTCMonth() + months;
  const targetYear = date.getUTCFullYear() + Math.floor(targetMonth / 12);
  const normalizedMonth = targetMonth % 12;
  const lastDay = new Date(Date.UTC(targetYear, normalizedMonth + 1, 0)).getUTCDate();
  return new Date(Date.UTC(
    targetYear,
    normalizedMonth,
    Math.min(date.getUTCDate(), lastDay),
    date.getUTCHours(),
    date.getUTCMinutes(),
    date.getUTCSeconds(),
    date.getUTCMilliseconds(),
  ));
}

function isRepeatBlocked(nextEligibleAt, nowMillis) {
  return nextEligibleAt instanceof Date &&
    Number.isFinite(nextEligibleAt.getTime()) &&
    nextEligibleAt.getTime() > nowMillis;
}

function serviceEligibilityDate(serviceAt, repeatIntervalMonths) {
  return addCalendarMonths(serviceAt, repeatIntervalMonths);
}

module.exports = { addCalendarMonths, isRepeatBlocked, serviceEligibilityDate };
