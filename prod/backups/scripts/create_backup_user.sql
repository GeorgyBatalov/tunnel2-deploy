-- ============================================================================
-- Create PostgreSQL Read-Only Backup User
-- ============================================================================
--
-- This script creates a read-only user for backup purposes.
-- The user has ONLY SELECT privileges and cannot modify data.
--
-- Usage:
--   source .env
--   BACKUP_PASSWORD="$POSTGRES_BACKUP_PASSWORD" docker exec -i postgres \
--     psql -U tunnel -d tunnel2 \
--     -v BACKUP_PASSWORD="$POSTGRES_BACKUP_PASSWORD" \
--     < scripts/create_backup_user.sql
--
-- Security:
--   - backup_user can ONLY read data (SELECT)
--   - Cannot INSERT, UPDATE, DELETE, or DROP
--   - Cannot create tables or modify schema
--   - Safe to use for automated backups
-- ============================================================================

-- Create backup user
CREATE USER backup_user WITH PASSWORD :'BACKUP_PASSWORD';

-- Grant connection to tunnel2 database
GRANT CONNECT ON DATABASE tunnel2 TO backup_user;

-- Grant usage on public schema
GRANT USAGE ON SCHEMA public TO backup_user;

-- Grant SELECT on all existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup_user;

-- Grant SELECT on all future tables (important for Phase 7!)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO backup_user;

-- Grant SELECT on all existing sequences (needed for proper restore)
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO backup_user;

-- Grant SELECT on all future sequences
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON SEQUENCES TO backup_user;

-- Show granted privileges
\dp

-- Success message
\echo 'backup_user created successfully with read-only access'
