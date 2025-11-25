#!/bin/sh
# ============================================================================
# rclone sync script for Yandex.Disk
# ============================================================================
#
# This script runs in a loop inside the rclone Docker container.
# It syncs backup files from /data to yandex:xtunnel-backups every 24 hours.
#
# Environment variables:
#   RETENTION_DAYS - Delete files older than N days (default: 30)
#   SYNC_INTERVAL  - Seconds between syncs (default: 86400 = 24h)
# ============================================================================

RETENTION_DAYS=${RETENTION_DAYS:-30}
SYNC_INTERVAL=${SYNC_INTERVAL:-86400}

while true; do
  echo "[$(date)] rclone: Starting upload to Yandex.Disk"

  # Sync local backups to Yandex.Disk
  rclone sync /data yandex:xtunnel-backups \
    --config=/config/rclone/rclone.conf \
    --create-empty-src-dirs \
    --log-level=INFO \
    --stats=10s \
    && echo "[$(date)] rclone: Upload SUCCESS" \
    || echo "[$(date)] rclone: Upload FAILED!"

  echo "[$(date)] rclone: Cleaning up old backups (>$RETENTION_DAYS days)"

  # Delete files older than RETENTION_DAYS
  rclone delete yandex:xtunnel-backups \
    --config=/config/rclone/rclone.conf \
    --min-age=${RETENTION_DAYS}d \
    && echo "[$(date)] rclone: Cleanup SUCCESS" \
    || echo "[$(date)] rclone: Cleanup FAILED!"

  echo "[$(date)] rclone: Next run in $SYNC_INTERVAL seconds ($(($SYNC_INTERVAL / 3600))h)"
  sleep $SYNC_INTERVAL
done
