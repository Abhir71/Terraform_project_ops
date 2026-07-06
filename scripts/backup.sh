#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DB_USER="devops_user"
DB_PASSWORD="devops_password"
DB_NAME="devops_db"
DB_HOST="localhost"
DB_PORT="5432"
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.sql"

echo -e "${YELLOW}Starting database backup...${NC}"

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Check if database is running
if ! docker ps | grep -q "devops-db"; then
    echo -e "${RED}Error: Database container is not running.${NC}"
    echo -e "${YELLOW}Please run: docker compose up -d${NC}"
    exit 1
fi

# Perform backup using pg_dump
echo -e "${GREEN}Creating backup: ${BACKUP_FILE}${NC}"

docker exec devops-db pg_dump \
    -U "${DB_USER}" \
    -d "${DB_NAME}" \
    --clean \
    --if-exists \
    --no-owner \
    --no-privileges \
    > "${BACKUP_FILE}"

# Check if backup was successful
if [ $? -eq 0 ] && [ -f "${BACKUP_FILE}" ]; then
    FILE_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
    echo -e "${GREEN}✅ Backup created successfully!${NC}"
    echo -e "${GREEN}   File: ${BACKUP_FILE}${NC}"
    echo -e "${GREEN}   Size: ${FILE_SIZE}${NC}"
    
    # Create a symlink to the latest backup
    ln -sf "$(basename "${BACKUP_FILE}")" "${BACKUP_DIR}/latest_backup.sql"
    echo -e "${GREEN}   Latest backup symlink created${NC}"
else
    echo -e "${RED}❌ Backup failed!${NC}"
    exit 1
fi

# Optional: Clean up old backups (keep last 5)
echo -e "${YELLOW}Cleaning up old backups...${NC}"
cd "${BACKUP_DIR}" && ls -tp | grep -v '/$' | tail -n +6 | xargs -I {} rm -- {}
echo -e "${GREEN}   Kept last 5 backups${NC}"

echo -e "${GREEN}✅ Backup process completed!${NC}"