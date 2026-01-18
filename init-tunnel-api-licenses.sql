-- Initialize test licenses in cabinet-api database (OLD LEGACY SCHEMA)
--
-- IMPORTANT: This is for tunnel_legacy database (cabinet-api)
-- Old schema uses:
--   - Table: "Licenses" (capital L)
--   - Field: "Secret" (not "SecretKey")
--   - Field: "Endpoint" (not "LegacyPublicEndpoint")
--   - Field: "LicenseType" (integer: 0=Free, 1=Personal, 2=Professional, 3=Business)
--   - Field: "PaidUntil" (not "ValidUntil")
--   - Requires "Users" table with foreign key

-- Ensure test user exists
INSERT INTO "Users" ("Id", "Email", "ExternalId", "CreatedDate")
VALUES (
    '10000000-0000-0000-0000-000000000001'::uuid,
    'test@tunnel.local',
    'test-user-1',
    NOW()
) ON CONFLICT ("Email") DO NOTHING;

-- CLEANUP: Delete all existing test licenses from legacy DB
DELETE FROM "Licenses" WHERE "Secret" LIKE '%_TEST';

-- License 1: PROFESSIONAL_KEY_1_TEST (old schema)
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "TcpPort", "PaidUntil", "LicenseType", "CreatedDate")
VALUES (
    '7e3b9f8a-4c21-4d5e-9b1a-2f8e6d3c1a4b'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'PROFESSIONAL_KEY_1_TEST',
    'myapp1.tunnel.local',
    40001, -- Fixed TCP port
    NOW() + INTERVAL '5 years',
    2, -- Professional
    NOW()
);

-- License 2: PROFESSIONAL_KEY_2_TEST (old schema)
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "TcpPort", "PaidUntil", "LicenseType", "CreatedDate")
VALUES (
    'a5d8c2f1-6b4e-4a8c-9d2e-3f7b8c5a1d6e'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'PROFESSIONAL_KEY_2_TEST',
    'myapp2.tunnel.local',
    40002, -- Fixed TCP port
    NOW() + INTERVAL '5 years',
    2, -- Professional
    NOW()
);

-- License 3: PROFESSIONAL_KEY_3_TEST (old schema)
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "TcpPort", "PaidUntil", "LicenseType", "CreatedDate")
VALUES (
    '3c7f2a9b-8d4e-4b6c-a1e5-9f8d2c6b4a7e'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'PROFESSIONAL_KEY_3_TEST',
    'myapp3.tunnel.local',
    40003, -- Fixed TCP port
    NOW() + INTERVAL '5 years',
    2, -- Professional
    NOW()
);

-- License 4: PROFESSIONAL_KEY_4_TEST (old schema)
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "TcpPort", "PaidUntil", "LicenseType", "CreatedDate")
VALUES (
    '9f1e4d6c-2b8a-4c5e-8d9f-6a3b7c1e4d8f'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'PROFESSIONAL_KEY_4_TEST',
    'myapp4.tunnel.local',
    40004, -- Fixed TCP port
    NOW() + INTERVAL '5 years',
    2, -- Professional
    NOW()
);

-- License 5: PROFESSIONAL_KEY_5_TEST (GUID-based endpoint, old schema)
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "TcpPort", "PaidUntil", "LicenseType", "CreatedDate")
VALUES (
    '5a8c3f7b-9d1e-4c6a-b8f2-4e7d9c1a5b8e'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'PROFESSIONAL_KEY_5_TEST',
    '17ce8c85-56a7-4abd-abf7-01e0c1f0b429.tunnel.local',
    40005, -- Fixed TCP port
    NOW() + INTERVAL '5 years',
    2, -- Professional
    NOW()
);

-- License 6: BUSINESS_KEY_1_TEST (old schema)
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "TcpPort", "PaidUntil", "LicenseType", "CreatedDate")
VALUES (
    'b1000000-0000-0000-0000-000000000001'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'BUSINESS_KEY_1_TEST',
    'mybiz1.tunnel.local',
    40006, -- Fixed TCP port
    NOW() + INTERVAL '2 years',
    3, -- Business
    NOW()
);

-- Verification query (old schema)
SELECT
    "Id",
    "Secret",
    "LicenseType",
    "Endpoint",
    "TcpPort",
    "PaidUntil"
FROM "Licenses"
WHERE "Secret" LIKE '%_TEST'
ORDER BY "TcpPort";
