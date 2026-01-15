-- Initialize test licenses in tunnel_server database (new system)
--
-- IMPORTANT: Normally these licenses should come from cabinet-api via LegacyFallback
-- This script is for cases when:
-- 1. Fallback is disabled or not working
-- 2. Quick initialization without cabinet-api dependency
-- 3. Testing tunnel_server in isolation
--
-- For production use, licenses should be created in cabinet-api and synced via fallback

-- CLEANUP: Delete all existing test licenses
DELETE FROM licenses WHERE "SecretKey" LIKE '%_TEST';

-- License 1: PROFESSIONAL_KEY_1_TEST
-- TCP port 40001 from range 40000-40009 (docker-compose.yml line 51)
INSERT INTO licenses ("Id", "SecretKey", "Tier", "IsActive", "ValidUntil", "LegacyPublicEndpoint", "LegacyPublicTcpPort", "MaxDevices", "CreatedAt")
VALUES (
    '7e3b9f8a-4c21-4d5e-9b1a-2f8e6d3c1a4b'::uuid,
    'PROFESSIONAL_KEY_1_TEST',
    'Professional',
    true,
    NOW() + INTERVAL '5 years',
    'myapp1.tunnel.local',
    40001,
    10,
    NOW()
);

-- License 2: PROFESSIONAL_KEY_2_TEST
-- TCP port 40002 from range 40000-40009 (docker-compose.yml line 51)
INSERT INTO licenses ("Id", "SecretKey", "Tier", "IsActive", "ValidUntil", "LegacyPublicEndpoint", "LegacyPublicTcpPort", "MaxDevices", "CreatedAt")
VALUES (
    'a5d8c2f1-6b4e-4a8c-9d2e-3f7b8c5a1d6e'::uuid,
    'PROFESSIONAL_KEY_2_TEST',
    'Professional',
    true,
    NOW() + INTERVAL '5 years',
    'myapp2.tunnel.local',
    40002,
    10,
    NOW()
);

-- License 3: PROFESSIONAL_KEY_3_TEST
-- TCP port 40003 from range 40000-40009 (docker-compose.yml line 51)
INSERT INTO licenses ("Id", "SecretKey", "Tier", "IsActive", "ValidUntil", "LegacyPublicEndpoint", "LegacyPublicTcpPort", "MaxDevices", "CreatedAt")
VALUES (
    '3c7f2a9b-8d4e-4b6c-a1e5-9f8d2c6b4a7e'::uuid,
    'PROFESSIONAL_KEY_3_TEST',
    'Professional',
    true,
    NOW() + INTERVAL '5 years',
    'myapp3.tunnel.local',
    40003,
    10,
    NOW()
);

-- License 4: PROFESSIONAL_KEY_4_TEST
-- TCP port 40004 from range 40000-40009 (docker-compose.yml line 51)
INSERT INTO licenses ("Id", "SecretKey", "Tier", "IsActive", "ValidUntil", "LegacyPublicEndpoint", "LegacyPublicTcpPort", "MaxDevices", "CreatedAt")
VALUES (
    '9f1e4d6c-2b8a-4c5e-8d9f-6a3b7c1e4d8f'::uuid,
    'PROFESSIONAL_KEY_4_TEST',
    'Professional',
    true,
    NOW() + INTERVAL '5 years',
    'myapp4.tunnel.local',
    40004,
    10,
    NOW()
);

-- License 5: PROFESSIONAL_KEY_5_TEST (GUID-based endpoint)
-- TCP port 40005 from range 40000-40009 (docker-compose.yml line 51)
INSERT INTO licenses ("Id", "SecretKey", "Tier", "IsActive", "ValidUntil", "LegacyPublicEndpoint", "LegacyPublicTcpPort", "MaxDevices", "CreatedAt")
VALUES (
    '5a8c3f7b-9d1e-4c6a-b8f2-4e7d9c1a5b8e'::uuid,
    'PROFESSIONAL_KEY_5_TEST',
    'Professional',
    true,
    NOW() + INTERVAL '5 years',
    '17ce8c85-56a7-4abd-abf7-01e0c1f0b429.tunnel.local',
    40005,
    10,
    NOW()
);

-- Verification query
SELECT
    "Id",
    "SecretKey",
    "Tier",
    "LegacyPublicEndpoint",
    "LegacyPublicTcpPort",
    "IsActive",
    "BoundHardwareThumbprint",
    "ValidUntil"
FROM licenses
WHERE "SecretKey" LIKE '%_TEST'
ORDER BY "SecretKey";
