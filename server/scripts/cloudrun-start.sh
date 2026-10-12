#!/bin/sh
# Cloud Run entrypoint for the API.
#
# Builds the four datasource URLs from ONE secret (DB_PASSWORD) plus non-secret
# settings, so Secret Manager holds a single database credential instead of four
# full URLs. Connects over the Cloud SQL unix socket that Cloud Run mounts at
# /cloudsql/<instance> when the service has the Cloud SQL connection attached.
#
# Each Prisma client opens up to DB_POOL connections (default 2). Four clients x 2
# = 8 per instance; with max 2 instances that stays well under the ~25
# connections a db-f1-micro allows.
#
# If DATABASE_URL is already set (local/dev), nothing is composed.
set -e

if [ -z "$DATABASE_URL" ]; then
  : "${DB_USER:?DB_USER is not set}"
  : "${DB_PASSWORD:?DB_PASSWORD is not set}"
  : "${CLOUDSQL_INSTANCE:?CLOUDSQL_INSTANCE is not set}"
  base="postgresql://${DB_USER}:${DB_PASSWORD}@localhost"
  q="host=/cloudsql/${CLOUDSQL_INSTANCE}&connection_limit=${DB_POOL:-2}"
  export DATABASE_URL="${base}/clor_main?${q}"
  export PAYROLL_DATABASE_URL="${base}/clor_payroll?${q}"
  export PEOPLE_DATABASE_URL="${base}/clor_people?${q}"
  export PLATFORM_DATABASE_URL="${base}/clor_platform?${q}"
fi

npm run prisma:deploy
exec node dist/index.js
