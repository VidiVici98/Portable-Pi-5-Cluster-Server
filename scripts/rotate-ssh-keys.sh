#!/bin/bash

################################################################################
# SSH Key Rotation Procedure
# Purpose: Safely rotate SSH keys with minimal downtime
# Usage: sudo bash scripts/rotate-ssh-keys.sh
# Safety: Creates new keys, tests them, then transitions
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_FILE="/var/log/ssh-key-rotation.log"

# Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

################################################################################
# PRE-FLIGHT CHECKS
################################################################################

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}ERROR: This script must be run as root${NC}"
   exit 1
fi

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}SSH Key Rotation Procedure${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

log "=== SSH Key Rotation Started ==="

# Verify SSH key exists
if [ ! -f "config/secrets/ssh/id_rsa" ]; then
    echo -e "${YELLOW}INFO: No existing key in config/secrets/ssh/id_rsa${NC}"
    log "No existing key found. This will be initial key generation."
fi

################################################################################
# BACKUP EXISTING KEYS
################################################################################

echo -e "${YELLOW}[Step 1] Backing up existing keys...${NC}"
log "Backing up existing SSH keys"

BACKUP_DATE=$(date +%Y%m%d-%H%M%S)

if [ -f "config/secrets/ssh/id_rsa" ]; then
    mkdir -p "config/secrets/ssh/.backup"
    cp "config/secrets/ssh/id_rsa" "config/secrets/ssh/.backup/id_rsa.${BACKUP_DATE}.bak"
    cp "config/secrets/ssh/id_rsa.pub" "config/secrets/ssh/.backup/id_rsa.pub.${BACKUP_DATE}.bak"
    echo -e "${GREEN}✓ Keys backed up${NC}"
    log "Keys backed up to config/secrets/ssh/.backup/"
else
    echo -e "${YELLOW}⚠ No existing keys to backup${NC}"
    log "No existing keys found"
fi

################################################################################
# GENERATE NEW KEYS
################################################################################

echo -e "${YELLOW}[Step 2] Generating new SSH keys...${NC}"
log "Generating new SSH keys"

mkdir -p config/secrets/ssh

# Generate ED25519 key (more secure than RSA)
if ssh-keygen -t ed25519 \
    -f "config/secrets/ssh/id_rsa" \
    -N "" \
    -C "cluster-$(hostname)-$(date +%Y%m%d)" \
    -q; then
    
    echo -e "${GREEN}✓ New ED25519 key generated${NC}"
    log "New ED25519 key generated"
    
    # Fix permissions immediately
    chmod 600 "config/secrets/ssh/id_rsa"
    chmod 644 "config/secrets/ssh/id_rsa.pub"
    
    log "Key permissions set: id_rsa (600), id_rsa.pub (644)"
else
    echo -e "${RED}ERROR: Failed to generate SSH key${NC}"
    log "ERROR: SSH key generation failed"
    exit 1
fi

################################################################################
# DISPLAY NEW PUBLIC KEY
################################################################################

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}New Public Key Generated${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

echo "Public key (config/secrets/ssh/id_rsa.pub):"
echo "────────────────────────────────────────────────"
cat "config/secrets/ssh/id_rsa.pub"
echo "────────────────────────────────────────────────"
echo ""

################################################################################
# UPDATE AUTHORIZED_KEYS
################################################################################

echo -e "${YELLOW}[Step 3] Updating authorized_keys...${NC}"
log "Updating authorized_keys"

# Ensure .ssh directory exists with proper permissions
if [ ! -d ~/.ssh ]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    log "Created ~/.ssh directory"
fi

# Add new public key to authorized_keys
if cat "config/secrets/ssh/id_rsa.pub" >> ~/.ssh/authorized_keys; then
    chmod 600 ~/.ssh/authorized_keys
    echo -e "${GREEN}✓ New key added to authorized_keys${NC}"
    log "New key added to authorized_keys"
else
    echo -e "${RED}ERROR: Failed to add key to authorized_keys${NC}"
    log "ERROR: Failed to update authorized_keys"
    exit 1
fi

################################################################################
# TEST NEW KEY
################################################################################

echo -e "${YELLOW}[Step 4] Testing new key...${NC}"
log "Testing new SSH key"

# Test SSH connection with new key
if ssh -i "config/secrets/ssh/id_rsa" -o StrictHostKeyChecking=no localhost "echo SSH_TEST_OK" &>/dev/null; then
    echo -e "${GREEN}✓ New key works${NC}"
    log "SSH key test successful"
else
    echo -e "${RED}ERROR: New key doesn't work${NC}"
    log "ERROR: SSH key test failed"
    exit 1
fi

################################################################################
# REMOVE OLD KEYS FROM AUTHORIZED_KEYS (OPTIONAL)
################################################################################

echo -e "${YELLOW}[Step 5] Handling old keys...${NC}"
log "Processing old SSH keys"

OLD_KEY_COUNT=$(($(grep -c "^" ~/.ssh/authorized_keys 2>/dev/null || echo 0) - 1))

if [ "$OLD_KEY_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}Found $OLD_KEY_COUNT previous key(s) in authorized_keys${NC}"
    echo ""
    echo "Do you want to remove old keys? (y/n) - They will remain in backup."
    read -p "Remove old keys? [n]: " -t 10 REMOVE_OLD || REMOVE_OLD="n"
    
    if [ "$REMOVE_OLD" = "y" ] || [ "$REMOVE_OLD" = "Y" ]; then
        echo -e "${YELLOW}Removing old keys...${NC}"
        log "User requested removal of old keys"
        
        # Backup authorized_keys
        cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.${BACKUP_DATE}.bak
        log "Backed up authorized_keys"
        
        # Keep only the latest key
        LATEST_KEY=$(tail -1 ~/.ssh/authorized_keys)
        echo "$LATEST_KEY" > ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
        
        echo -e "${GREEN}✓ Old keys removed${NC}"
        log "Old keys removed from authorized_keys"
    else
        echo -e "${YELLOW}Keeping all keys in authorized_keys${NC}"
        log "User chose to keep all keys"
    fi
else
    echo -e "${GREEN}✓ No old keys to handle${NC}"
    log "No previous keys found"
fi

################################################################################
# VERIFY SYSTEM SSH CONFIGURATION
################################################################################

echo -e "${YELLOW}[Step 6] Verifying system SSH configuration...${NC}"
log "Verifying SSH system configuration"

# Verify sshd_config has correct permissions
if [ -f "/etc/ssh/sshd_config" ]; then
    PERMS=$(stat -c '%a' /etc/ssh/sshd_config 2>/dev/null)
    if [ "$PERMS" = "600" ] || [ "$PERMS" = "644" ]; then
        echo -e "${GREEN}✓ SSH server config permissions: OK${NC}"
        log "SSH server config verified"
    else
        echo -e "${YELLOW}⚠ SSH config permissions: $PERMS (check manually)${NC}"
        log "WARNING: SSH config has unusual permissions: $PERMS"
    fi
fi

################################################################################
# DOCUMENT ROTATION
################################################################################

echo -e "${YELLOW}[Step 7] Documenting key rotation...${NC}"
log "Recording key rotation event"

# Create rotation record
ROTATION_LOG="config/secrets/ssh/.rotation-history"
mkdir -p "config/secrets/ssh"

cat >> "$ROTATION_LOG" << EOF
=== SSH Key Rotation ===
Date: $(date '+%Y-%m-%d %H:%M:%S')
Key Type: ED25519
Key Comment: cluster-$(hostname)-$(date +%Y%m%d)
Status: Successful
Backup: id_rsa.${BACKUP_DATE}.bak
EOF

echo -e "${GREEN}✓ Rotation documented${NC}"
log "Key rotation documented in config/secrets/ssh/.rotation-history"

################################################################################
# SUMMARY
################################################################################

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}SSH Key Rotation Complete${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
echo "Summary:"
echo "  ✓ New ED25519 key generated"
echo "  ✓ Key added to authorized_keys"
echo "  ✓ New key tested and verified"
echo "  ✓ Old keys backed up"
echo ""
echo "Key Locations:"
echo "  Private: config/secrets/ssh/id_rsa (KEEP SECURE)"
echo "  Public: config/secrets/ssh/id_rsa.pub"
echo "  Backups: config/secrets/ssh/.backup/"
echo ""
echo "Next Steps:"
echo "  1. Distribute new public key to other systems (if needed)"
echo "  2. Update any key references in deployment scripts"
echo "  3. Document any external systems using this key"
echo "  4. Verify no authentication issues on next login"
echo ""
echo "To test the new key manually:"
echo "  ssh -i config/secrets/ssh/id_rsa pi@boot-node"
echo ""

log "=== SSH Key Rotation Completed Successfully ==="
echo -e "${GREEN}Log: $LOG_FILE${NC}"
