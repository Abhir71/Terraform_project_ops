#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

DB_USER="devops_user"
DB_PASSWORD="devops_password"
DB_NAME="devops_db"
DB_HOST="localhost"
DB_PORT="5432"
BACKUP_DIR="./backups"
BACKUP_FILE="${1:-${BACKUP_DIR}/latest_backup.sql}"

echo -e "${YELLOW}Starting database restore...${NC}"

# Check if backup file exists
if [ ! -f "${BACKUP_FILE}" ]; then
    echo -e "${RED}Error: Backup file not found: ${BACKUP_FILE}${NC}"
    echo -e "${YELLOW}Usage: ./scripts/restore.sh [path-to-backup-file]${NC}"
    echo -e "${YELLOW}Or ensure latest_backup.sql exists in ./backups/${NC}"
    exit 1
fi

# Check if database is running
if ! docker ps | grep -q "devops-db"; then
    echo -e "${RED}Error: Database container is not running.${NC}"
    echo -e "${YELLOW}Please run: docker compose up -d${NC}"
    exit 1
fi

# Confirm restore action
echo -e "${RED}⚠️  WARNING: This will completely replace the current database!${NC}"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "${confirm}" != "yes" ]; then
    echo -e "${YELLOW}Restore cancelled.${NC}"
    exit 0
fi

echo -e "${GREEN}Restoring from: ${BACKUP_FILE}${NC}"

# Perform restore
cat "${BACKUP_FILE}" | docker exec -i devops-db psql \
    -U "${DB_USER}" \
    -d "${DB_NAME}"

# Check if restore was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Restore completed successfully!${NC}"
    
    # Verify the restore
    echo -e "${YELLOW}Verifying restore...${NC}"
    
    # Check count of bookings
    BOOKING_COUNT=$(docker exec devops-db psql -U "${DB_USER}" -d "${DB_NAME}" -t -c "SELECT COUNT(*) FROM hotel_bookings;" | tr -d ' ')
    EVENT_COUNT=$(docker exec devops-db psql -U "${DB_USER}" -d "${DB_NAME}" -t -c "SELECT COUNT(*) FROM booking_events;" | tr -d ' ')
    
    echo -e "${GREEN}   Hotel bookings: ${BOOKING_COUNT}${NC}"
    echo -e "${GREEN}   Booking events: ${EVENT_COUNT}${NC}"
    
    # Show sample data
    echo -e "${YELLOW}Sample data (first 3 bookings):${NC}"
    docker exec devops-db psql -U "${DB_USER}" -d "${DB_NAME}" -c "SELECT id, org_id, city, status, amount FROM hotel_bookings LIMIT 3;"
    
    echo -e "${GREEN}✅ Restore verification completed!${NC}"
else
    echo -e "${RED}❌ Restore failed!${NC}"
    exit 1
fi