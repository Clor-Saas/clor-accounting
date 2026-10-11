import { describe, it, expect, afterAll } from 'vitest';
import { platformPrisma } from '../utils/platformPrisma.js';
import { setSubscription, subscribedAppCodes, isAppEntitled, inGoodStanding } from '../services/subscriptions.js';

/**
 * The generic business-model layer: subscriptions grant app-level access and
 * feed the entitlement ceiling, with NO payment gateway wired (manual path).
 */
describe('business model — subscriptions (gateway-agnostic)', () => {
  const acct = 'test_acct_bizmodel_1';
  afterAll(async () => {
    await platformPrisma.subscription.deleteMany({ where: { accountId: acct } });
  });

  it('inGoodStanding is correct across states (pure)', () => {
    const future = new Date(Date.now() + 86400000);
    const past = new Date(Date.now() - 86400000);
    expect(inGoodStanding({ status: 'trialing', trialEndsAt: future, currentPeriodEnd: null })).toBe(true);
    expect(inGoodStanding({ status: 'trialing', trialEndsAt: past, currentPeriodEnd: null })).toBe(false);
    expect(inGoodStanding({ status: 'active', trialEndsAt: null, currentPeriodEnd: past })).toBe(false);
    expect(inGoodStanding({ status: 'active', trialEndsAt: null, currentPeriodEnd: null })).toBe(true);
    expect(inGoodStanding({ status: 'cancelled', trialEndsAt: null, currentPeriodEnd: null })).toBe(false);
  });

  it('a manual subscription grants app access with no gateway', async () => {
    await setSubscription(acct, { apps: [{ appCode: 'payroll', seats: 5 }], trialDays: 14 });
    const apps = await subscribedAppCodes(acct);
    expect(apps).toContain('payroll');
    expect(await isAppEntitled(acct, 'payroll')).toBe(true);
    expect(await isAppEntitled(acct, 'accounting')).toBe(false);
  });

  it('non-sellable apps (on-prem attendance) are rejected', async () => {
    await setSubscription(acct, { apps: [{ appCode: 'payroll' }, { appCode: 'attendance' }], trialDays: 14 });
    const apps = await subscribedAppCodes(acct);
    expect(apps).toContain('payroll');
    expect(apps).not.toContain('attendance');
  });
});
