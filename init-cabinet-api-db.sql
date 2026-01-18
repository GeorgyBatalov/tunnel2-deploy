-- Initialize cabinet-api database (legacy schema)
-- This script creates the old database schema with "Licenses" table (capital L)
-- for testing legacy fallback migration

-- Create Users table
CREATE TABLE IF NOT EXISTS "Users" (
    "Id" uuid PRIMARY KEY,
    "Email" character varying(300) NOT NULL,
    "ExternalId" character varying(450) NOT NULL,
    "CreatedDate" timestamp with time zone NOT NULL,
    "ModifiedDate" timestamp with time zone
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_Users_Email" ON "Users" ("Email");
CREATE UNIQUE INDEX IF NOT EXISTS "IX_Users_ExternalId" ON "Users" ("ExternalId");

-- Create Licenses table (old schema with capital L)
CREATE TABLE IF NOT EXISTS "Licenses" (
    "Id" uuid PRIMARY KEY,
    "UserId" uuid NOT NULL,
    "Secret" character varying(300) NOT NULL,
    "Endpoint" character varying(800),
    "PaidUntil" timestamp with time zone,
    "LicenseType" integer NOT NULL DEFAULT 0,  -- Added in later migration
    "CreatedDate" timestamp with time zone NOT NULL,
    "ModifiedDate" timestamp with time zone,
    CONSTRAINT "FK_Licenses_Users_UserId" FOREIGN KEY ("UserId") REFERENCES "Users" ("Id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_Licenses_Endpoint" ON "Licenses" ("Endpoint");
CREATE UNIQUE INDEX IF NOT EXISTS "IX_Licenses_Secret" ON "Licenses" ("Secret");
CREATE INDEX IF NOT EXISTS "IX_Licenses_UserId" ON "Licenses" ("UserId");

-- Insert test user for licenses
INSERT INTO "Users" ("Id", "Email", "ExternalId", "CreatedDate")
VALUES (
    '10000000-0000-0000-0000-000000000001'::uuid,
    'test@tunnel.local',
    'test-user-1',
    NOW()
) ON CONFLICT DO NOTHING;

-- Insert legacy licenses for migration testing
-- LicenseType: 0=Free, 1=Personal, 2=Professional, 3=Business

-- OLD_PROFESSIONAL_1 - should migrate to tunnel2.licenses
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "PaidUntil", "LicenseType", "CreatedDate")
VALUES (
    '80000000-0000-0000-0000-000000000001'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'OLD_PROFESSIONAL_1',
    'oldapp1.tunnel.local',
    NOW() + INTERVAL '1 year',
    2, -- Professional
    NOW()
) ON CONFLICT DO NOTHING;

-- OLD_PROFESSIONAL_2 - should migrate to tunnel2.licenses
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "PaidUntil", "LicenseType", "CreatedDate")
VALUES (
    '80000000-0000-0000-0000-000000000002'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'OLD_PROFESSIONAL_2',
    'oldapp2.tunnel.local',
    NOW() + INTERVAL '1 year',
    2, -- Professional
    NOW()
) ON CONFLICT DO NOTHING;

-- OLD_BUSINESS_1 - should migrate to tunnel2.licenses
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "PaidUntil", "LicenseType", "CreatedDate")
VALUES (
    '80000000-0000-0000-0000-000000000003'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'OLD_BUSINESS_1',
    'oldbiz1.tunnel.local',
    NOW() + INTERVAL '2 years',
    3, -- Business
    NOW()
) ON CONFLICT DO NOTHING;

-- Verification query
SELECT
    "Id",
    "Secret",
    "LicenseType",
    "Endpoint",
    "PaidUntil"
FROM "Licenses"
ORDER BY "Secret";
