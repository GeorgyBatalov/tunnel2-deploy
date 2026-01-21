-- ===================================================================
-- INITIALIZE TEST LICENSES FOR CABINET-API (OLD SYSTEM)
-- ===================================================================
--
-- IMPORTANT: This script creates licenses ONLY in cabinet-api database!
-- Database: tunnel_legacy
-- Table: "Licenses" (Pascal case) - это таблица cabinet-api (СТАРАЯ БД)
--
-- Apply script:
--   cat init-test-licenses.sql | docker exec -i tunnel2_postgres psql -U admin -d tunnel_legacy
--
-- tunnel_server will automatically fetch these licenses via LegacyFallback
-- DO NOT apply this script to tunnel_server's "licenses" table!
-- ===================================================================

-- CLEANUP: Delete all existing test licenses
-- Note: Using existing user ID 10000000-0000-0000-0000-000000000001
DELETE FROM "Licenses" WHERE "UserId" = '10000000-0000-0000-0000-000000000001'::uuid;

-- License 0: FREE_KEY_TEST (Free tier)
-- LicenseType = 0 (Free)
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "PaidUntil", "TcpPort", "LicenseType", "CreatedDate", "ModifiedDate")
VALUES (
    '1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'FREE_KEY_TEST',
    'free-app',
    NOW() + INTERVAL '1 year',  -- Free tier valid for 1 year
    NULL,  -- No TCP port for free tier
    0,  -- LicenseType = 0 (Free)
    NOW(),
    NOW()
);

-- License 1: PROFESSIONAL_KEY_1_TEST
-- LicenseType = 2 (PaidProfessional)
-- TCP port 40001 from range 40000-40009 (docker-compose.yml line 51)
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "PaidUntil", "TcpPort", "LicenseType", "CreatedDate", "ModifiedDate")
VALUES (
    '7e3b9f8a-4c21-4d5e-9b1a-2f8e6d3c1a4b'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'PROFESSIONAL_KEY_1_TEST',
    'myapp1',
    NOW() + INTERVAL '5 years',  -- Paid for 5 years
    40001,  -- Fixed TCP port from range 40000-40009
    2,  -- LicenseType = 2 (PaidProfessional)
    NOW(),
    NOW()
);

-- License 2: PROFESSIONAL_KEY_2_TEST
-- LicenseType = 2 (PaidProfessional)
-- TCP port 40002 from range 40000-40009 (docker-compose.yml line 51)
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "PaidUntil", "TcpPort", "LicenseType", "CreatedDate", "ModifiedDate")
VALUES (
    'a5d8c2f1-6b4e-4a8c-9d2e-3f7b8c5a1d6e'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'PROFESSIONAL_KEY_2_TEST',
    'myapp2',
    NOW() + INTERVAL '5 years',  -- Paid for 5 years
    40002,  -- Fixed TCP port from range 40000-40009
    2,  -- LicenseType = 2 (PaidProfessional)
    NOW(),
    NOW()
);

-- License 3: PROFESSIONAL_KEY_3_TEST
-- LicenseType = 2 (PaidProfessional)
-- TCP port 40003 from range 40000-40009 (docker-compose.yml line 51)
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "PaidUntil", "TcpPort", "LicenseType", "CreatedDate", "ModifiedDate")
VALUES (
    '3c7f2a9b-8d4e-4b6c-a1e5-9f8d2c6b4a7e'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'PROFESSIONAL_KEY_3_TEST',
    'myapp3',
    NOW() + INTERVAL '5 years',  -- Paid for 5 years
    40003,  -- Fixed TCP port from range 40000-40009
    2,  -- LicenseType = 2 (PaidProfessional)
    NOW(),
    NOW()
);

-- License 4: PROFESSIONAL_KEY_4_TEST
-- LicenseType = 2 (PaidProfessional)
-- TCP port 40004 from range 40000-40009 (docker-compose.yml line 51)
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "PaidUntil", "TcpPort", "LicenseType", "CreatedDate", "ModifiedDate")
VALUES (
    '9f1e4d6c-2b8a-4c5e-8d9f-6a3b7c1e4d8f'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'PROFESSIONAL_KEY_4_TEST',
    'myapp4',
    NOW() + INTERVAL '5 years',  -- Paid for 5 years
    40004,  -- Fixed TCP port from range 40000-40009
    2,  -- LicenseType = 2 (PaidProfessional)
    NOW(),
    NOW()
);

-- License 5: PROFESSIONAL_KEY_5_TEST (GUID-based endpoint)
-- LicenseType = 2 (PaidProfessional)
-- TCP port 40005 from range 40000-40009 (docker-compose.yml line 51)
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "PaidUntil", "TcpPort", "LicenseType", "CreatedDate", "ModifiedDate")
VALUES (
    '5a8c3f7b-9d1e-4c6a-b8f2-4e7d9c1a5b8e'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'PROFESSIONAL_KEY_5_TEST',
    '17ce8c85-56a7-4abd-abf7-01e0c1f0b429.tunnel.local',
    NOW() + INTERVAL '5 years',  -- Paid for 5 years
    40005,  -- Fixed TCP port from range 40000-40009
    2,  -- LicenseType = 2 (PaidProfessional)
    NOW(),
    NOW()
);

-- License 6: PROFESSIONAL_KEY_CLI_E2E_TEST (for CLI E2E integration tests)
-- LicenseType = 2 (PaidProfessional)
-- TCP port 40006 from range 40000-40009 (docker-compose.yml line 51)
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "PaidUntil", "TcpPort", "LicenseType", "CreatedDate", "ModifiedDate")
VALUES (
    '5a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'PROFESSIONAL_KEY_CLI_E2E_TEST',
    'cli-e2e',
    NOW() + INTERVAL '5 years',  -- Paid for 5 years
    40006,  -- Fixed TCP port from range 40000-40009
    2,  -- LicenseType = 2 (PaidProfessional)
    NOW(),
    NOW()
);

-- License 7: PERSONAL_KEY_1_TEST
-- LicenseType = 1 (PaidPersonal)
-- TCP port 40007 from range 40000-40009 (docker-compose.yml line 51)
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "PaidUntil", "TcpPort", "LicenseType", "CreatedDate", "ModifiedDate")
VALUES (
    '8b2c3d4e-5f6a-7b8c-9d0e-1f2a3b4c5d6e'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'PERSONAL_KEY_1_TEST',
    'personal-app1',
    NOW() + INTERVAL '5 years',  -- Paid for 5 years
    40007,  -- Fixed TCP port from range 40000-40009
    1,  -- LicenseType = 1 (PaidPersonal)
    NOW(),
    NOW()
);

-- License 8: PERSONAL_KEY_2_TEST
-- LicenseType = 1 (PaidPersonal)
-- TCP port 40008 from range 40000-40099
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "PaidUntil", "TcpPort", "LicenseType", "CreatedDate", "ModifiedDate")
VALUES (
    '9c3d4e5f-6a7b-8c9d-0e1f-2a3b4c5d6e7f'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'PERSONAL_KEY_2_TEST',
    'personal-app2',
    NOW() + INTERVAL '5 years',  -- Paid for 5 years
    40008,  -- Fixed TCP port from range 40000-40099
    1,  -- LicenseType = 1 (PaidPersonal)
    NOW(),
    NOW()
);

-- License 9: PROFESSIONAL_KEY_6_TEST (human-readable subdomain)
-- LicenseType = 2 (PaidProfessional)
-- TCP port 40009 from range 40000-40099
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "PaidUntil", "TcpPort", "LicenseType", "CreatedDate", "ModifiedDate")
VALUES (
    '0d4e5f6a-7b8c-9d0e-1f2a-3b4c5d6e7f8a'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'PROFESSIONAL_KEY_6_TEST',
    'my-awesome-api',
    NOW() + INTERVAL '5 years',  -- Paid for 5 years
    40009,  -- Fixed TCP port from range 40000-40099
    2,  -- LicenseType = 2 (PaidProfessional)
    NOW(),
    NOW()
);

-- License 10: PROFESSIONAL_KEY_7_TEST (another human-readable subdomain)
-- LicenseType = 2 (PaidProfessional)
-- TCP port 40010 from range 40000-40099
INSERT INTO "Licenses" ("Id", "UserId", "Secret", "Endpoint", "PaidUntil", "TcpPort", "LicenseType", "CreatedDate", "ModifiedDate")
VALUES (
    '1e5f6a7b-8c9d-0e1f-2a3b-4c5d6e7f8a9b'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'PROFESSIONAL_KEY_7_TEST',
    'prod-service',
    NOW() + INTERVAL '5 years',  -- Paid for 5 years
    40010,  -- Fixed TCP port from range 40000-40099
    2,  -- LicenseType = 2 (PaidProfessional)
    NOW(),
    NOW()
);

-- Verification query (optional - comment out if not needed)
SELECT
    l."Secret" as "License Key",
    l."LicenseType" as "Type",
    l."Endpoint" as "Public Domain",
    l."TcpPort" as "TCP Port",
    l."PaidUntil" as "Paid Until",
    u."Email" as "User Email"
FROM "Licenses" l
JOIN "Users" u ON l."UserId" = u."Id"
WHERE l."Secret" IN (
    'FREE_KEY_TEST',
    'PERSONAL_KEY_1_TEST',
    'PERSONAL_KEY_2_TEST',
    'PROFESSIONAL_KEY_1_TEST',
    'PROFESSIONAL_KEY_2_TEST',
    'PROFESSIONAL_KEY_3_TEST',
    'PROFESSIONAL_KEY_4_TEST',
    'PROFESSIONAL_KEY_5_TEST',
    'PROFESSIONAL_KEY_6_TEST',
    'PROFESSIONAL_KEY_7_TEST',
    'PROFESSIONAL_KEY_CLI_E2E_TEST'
)
ORDER BY l."LicenseType", l."Secret";
