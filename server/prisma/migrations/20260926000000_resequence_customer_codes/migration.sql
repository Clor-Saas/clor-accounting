-- Customer identifiers are six-digit numbers in the 2–5 series. Earlier
-- browser-only masters created values such as CUST-1/CUST-001. Re-allot every
-- existing customer deterministically inside its organisation so old and new
-- records follow one sequence. Party relations use Party.id, so changing this
-- display/business identifier does not break invoices, receipts or ledgers.
UPDATE Party AS target
SET code = (
  SELECT printf('%06d', 199999 + COUNT(*))
  FROM Party AS ranked
  WHERE ranked.accountId = target.accountId
    AND ranked.orgId = target.orgId
    AND ranked.partyType IN ('CUSTOMER', 'BOTH')
    AND (
      ranked.createdAt < target.createdAt
      OR (ranked.createdAt = target.createdAt AND ranked.id <= target.id)
    )
)
WHERE target.partyType IN ('CUSTOMER', 'BOTH');
