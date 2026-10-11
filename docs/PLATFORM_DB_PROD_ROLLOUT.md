# Platform DB split — production rollout (Render + Neon)

**Do these in order. Do NOT push `feat/clor-platform` until step 4.**
Render auto-deploys on push; the new code needs `PLATFORM_DATABASE_URL` and a
populated `clor_platform`, or api.clor.in fails to boot / logins break.

Detailed SQL + table list: `server/prisma/platform/README_MIGRATION.md`.

## 0. Before you start
- Take a Neon backup/branch of `clor_main` (Neon → Branches → create branch from production). This is your rollback.
- Pick a quiet window: signups/logins during steps 2–4 could be lost.

## 1. Lay down platform tables in `clor_platform` (from your machine)
In a terminal, set the env vars from your Neon strings (never paste them into files):
```
export DATABASE_URL='<clor_main string>'
export PLATFORM_DATABASE_URL='<clor_main string with db name clor_platform>'
npm --prefix server run platform:deploy
psql "$PLATFORM_DATABASE_URL" -f server/prisma/platform/migrations/20260924120000_row_level_security/migration.sql
```

## 2. Copy the 27 tables' data clor_main -> clor_platform
Follow README_MIGRATION.md step 2–3 (pg_dump data-only, FK-safe order, restore).
Verify row counts match for Account, User, Session, Role, UserOrgMembership.

## 3. Set the env on Render
Render → clor-api → Environment → add `PLATFORM_DATABASE_URL` = the clor_platform string. Save (no deploy yet if possible).

## 4. Push + deploy
`git push origin feat/clor-platform` → Render builds, `prisma:deploy` no-ops (already applied), app boots.

## 5. Verify
- Log in on app.clor.in with an existing account.
- GET /api/billing/catalog returns apps.
- Render logs: no "Environment variable not found".

## 6. Later (after a week of clean running)
Drop the 27 moved tables from clor_main (README_MIGRATION.md final step). Not before.

## Rollback
Remove `PLATFORM_DATABASE_URL`, redeploy the previous commit (`66ca808`) from Render's dashboard; data in clor_main is untouched by steps 1–4.
