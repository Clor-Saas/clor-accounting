ALTER TABLE "Warehouse" ADD COLUMN "code" TEXT NOT NULL DEFAULT '';
ALTER TABLE "Warehouse" ADD COLUMN "isActive" BOOLEAN NOT NULL DEFAULT true;

UPDATE "Warehouse"
SET "code" = 'WH-' || substr("id", -6)
WHERE "code" = '';

CREATE UNIQUE INDEX "Warehouse_orgId_code_key" ON "Warehouse"("orgId", "code");
