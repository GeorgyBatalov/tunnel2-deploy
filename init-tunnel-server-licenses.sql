-- Initialize test licenses for tunnel_server (licenses table)
-- These licenses are NOT bound to hardware thumbprint - will be auto-bound on first connection

-- License 1: Update existing PROFESSIONAL_KEY → PROFESSIONAL_KEY_1_TEST
UPDATE licenses SET
    "SecretKey" = 'PROFESSIONAL_KEY_1_TEST',
    "Tier" = 'Professional',
    "IsActive" = true,
    "ValidUntil" = NOW() + INTERVAL '5 years',
    "LegacyPublicEndpoint" = 'myapp1.tunnel.local',
    "LegacyPublicTcpPort" = 40001,
    "MaxDevices" = 10
WHERE "Id" = '10000000-0000-0000-0000-000000000001'::uuid;

-- License 2: Update existing PERSONAL_KEY → PROFESSIONAL_KEY_2_TEST
UPDATE licenses SET
    "SecretKey" = 'PROFESSIONAL_KEY_2_TEST',
    "Tier" = 'Professional',
    "IsActive" = true,
    "ValidUntil" = NOW() + INTERVAL '5 years',
    "LegacyPublicEndpoint" = 'myapp2.tunnel.local',
    "LegacyPublicTcpPort" = 40002,
    "MaxDevices" = 10
WHERE "Id" = '10000000-0000-0000-0000-000000000002'::uuid;

-- License 3: Update existing FREE_KEY → PROFESSIONAL_KEY_3_TEST
UPDATE licenses SET
    "SecretKey" = 'PROFESSIONAL_KEY_3_TEST',
    "Tier" = 'Professional',
    "IsActive" = true,
    "ValidUntil" = NOW() + INTERVAL '5 years',
    "LegacyPublicEndpoint" = 'myapp3.tunnel.local',
    "LegacyPublicTcpPort" = 40003,
    "MaxDevices" = 10
WHERE "Id" = '10000000-0000-0000-0000-000000000003'::uuid;

-- License 4: Update existing BUSINESS_KEY → PROFESSIONAL_KEY_4_TEST
UPDATE licenses SET
    "SecretKey" = 'PROFESSIONAL_KEY_4_TEST',
    "Tier" = 'Professional',
    "IsActive" = true,
    "ValidUntil" = NOW() + INTERVAL '5 years',
    "LegacyPublicEndpoint" = 'myapp4.tunnel.local',
    "LegacyPublicTcpPort" = 40004,
    "MaxDevices" = 10
WHERE "Id" = '10000000-0000-0000-0000-000000000004'::uuid;

-- License 5: Already updated above (PROFESSIONAL_KEY_5_TEST exists)
-- Just ensure it has correct fields
UPDATE licenses SET
    "Tier" = 'Professional',
    "IsActive" = true,
    "ValidUntil" = NOW() + INTERVAL '5 years',
    "LegacyPublicEndpoint" = '17ce8c85-56a7-4abd-abf7-01e0c1f0b429.tunnel.local',
    "LegacyPublicTcpPort" = 40005,
    "MaxDevices" = 10
WHERE "Id" = '10000000-0000-0000-0000-000000000005'::uuid;

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
WHERE "SecretKey" IN (
    'PROFESSIONAL_KEY_1_TEST',
    'PROFESSIONAL_KEY_2_TEST',
    'PROFESSIONAL_KEY_3_TEST',
    'PROFESSIONAL_KEY_4_TEST',
    'PROFESSIONAL_KEY_5_TEST'
)
ORDER BY "SecretKey";
