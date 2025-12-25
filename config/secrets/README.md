# Secrets Management Guide

**Version:** 1.0  
**Date:** December 25, 2025  
**Purpose:** Secure credential and key management

## Overview

Secrets (passwords, API keys, private certificates) must never be committed to Git. This guide establishes how to manage sensitive information safely.

## Quick Start

1. **Store secrets in `config/secrets/`** (git-ignored)
2. **Document HOW to create them** in `config/secrets/README.md`
3. **Load from environment variables** in scripts
4. **Never hardcode credentials**

## Secrets Directory Structure

```bash
config/secrets/
├── README.md                    # How to create secrets
├── .gitignore                   # Ignore all files here
├── ssh/
│   ├── id_rsa                   # Private SSH key (never commit)
│   ├── id_rsa.pub              # Public SSH key (safe to commit if needed)
│   └── authorized_keys         # Allowed public keys
├── tls/
│   ├── server.key              # Private certificate
│   ├── server.crt              # Public certificate
│   └── ca.crt                  # Certificate authority
├── api/
│   ├── credentials.conf        # API credentials file
│   └── tokens.env              # API tokens
├── database/
│   ├── db_password.conf        # Database password
│   └── db_user.conf            # Database username
└── wireless/
    ├── wpa_passphrase.conf     # WiFi password
    └── frequency.conf          # Frequency data (if sensitive)
```

## Git Ignore Configuration

### config/secrets/.gitignore

```bash
# Ignore EVERYTHING in this directory
*
*.*

# Except documentation
!README.md
!.gitignore
!.gitkeep

# Patterns for common files
*.key
*.pem
*.csr
*.conf
*.env
*.pass
*.pwd
*.secret
```

### Root .gitignore (Already Set)

Ensure root `.gitignore` includes:

```bash
# Secrets
config/secrets/**
!config/secrets/README.md
!config/secrets/.gitkeep

# Environment files
.env
.env.local
.env.*.local
```

## Creating Secrets

### 1. SSH Keys

```bash
# Generate keypair (on secure machine first)
ssh-keygen -t ed25519 -f config/secrets/ssh/id_rsa -N ""

# Store public key in git (can be public)
cp config/secrets/ssh/id_rsa.pub docs/ssh-keys/boot-node.pub

# NEVER commit the private key
chmod 600 config/secrets/ssh/id_rsa
```

### 2. TLS Certificates

```bash
# Self-signed certificate (development)
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout config/secrets/tls/server.key \
  -out config/secrets/tls/server.crt

# Set permissions
chmod 600 config/secrets/tls/server.key
chmod 644 config/secrets/tls/server.crt
```

### 3. API Credentials

Create `config/secrets/api/credentials.conf`:

```bash
# API Credentials File
# Store as: config/secrets/api/credentials.conf
# Permissions: 600 (owner only)
# NEVER commit to git

# Radio API
RADIO_API_KEY="your-api-key-here"
RADIO_API_SECRET="your-secret-here"

# GPS Service
GPS_API_KEY="your-gps-key"
GPS_API_TOKEN="your-token"

# Mesh Network
MESH_NETWORK_KEY="network-secret-key"
```

Permissions:
```bash
chmod 600 config/secrets/api/credentials.conf
```

### 4. Database Passwords

Create `config/secrets/database/db_password.conf`:

```bash
# Database Password File
# Store as: config/secrets/database/db_password.conf
# Permissions: 600 (owner only)
# NEVER commit to git

DB_USER="cluster_admin"
DB_PASSWORD="very-secure-password-here"
DB_HOST="localhost"
DB_PORT="5432"
```

## Loading Secrets in Scripts

### Method 1: Source from File

```bash
#!/bin/bash

# Load secrets
source config/secrets/api/credentials.conf

# Use variables
echo "API Key: $RADIO_API_KEY"
```

### Method 2: Use Environment Variables

```bash
# Load secrets to environment
export $(cat config/secrets/api/credentials.conf | grep -v '#' | xargs)

# Now available as $VARIABLE
```

### Method 3: Pass to Container

```bash
# Docker example
docker run \
  --env-file config/secrets/api/credentials.conf \
  my-app:latest
```

### Method 4: Python Scripts

```python
import os
from dotenv import load_dotenv

# Load from file
load_dotenv('config/secrets/api/credentials.conf')

# Access variables
api_key = os.getenv('RADIO_API_KEY')
```

## Keeping Secrets Secure

### File Permissions

```bash
# Secrets files should be readable only by owner
chmod 600 config/secrets/**/*.conf
chmod 600 config/secrets/**/*.key
chmod 600 config/secrets/**/*.env

# Keys should never be world-readable
ls -la config/secrets/ssh/
# -rw------- (600)
```

### Access Control

**Only authorized personnel should access:**
- SSH keys
- API credentials
- Database passwords
- TLS private keys

```bash
# Restrict to specific user
sudo chown nobody:nogroup config/secrets/
sudo chmod 700 config/secrets/

# Or group-based access
sudo chown nobody:cluster-admin config/secrets/
sudo chmod 750 config/secrets/
```

### Audit Trail

Track who accessed secrets:

```bash
# Enable audit logging
sudo apt install auditd

# Monitor secrets directory
sudo auditctl -w config/secrets/ -p wa -k cluster_secrets

# View logs
sudo ausearch -k cluster_secrets
```

## Rotating Secrets

### SSH Key Rotation

```bash
# 1. Generate new key
ssh-keygen -t ed25519 -f config/secrets/ssh/id_rsa_new -N ""

# 2. Add new public key to authorized_keys
cat config/secrets/ssh/id_rsa_new.pub >> config/secrets/ssh/authorized_keys

# 3. Test with new key
ssh -i config/secrets/ssh/id_rsa_new user@host

# 4. Remove old key from authorized_keys
nano config/secrets/ssh/authorized_keys

# 5. Replace old with new
mv config/secrets/ssh/id_rsa_new config/secrets/ssh/id_rsa
mv config/secrets/ssh/id_rsa_new.pub config/secrets/ssh/id_rsa.pub

# 6. Verify all nodes updated
for node in boot isr mesh vhf; do
  ssh -i config/secrets/ssh/id_rsa $node "echo OK"
done
```

### API Key Rotation

```bash
# 1. Generate new key with service provider
# (process varies by provider)

# 2. Update credentials file
nano config/secrets/api/credentials.conf
# Change RADIO_API_KEY to new value

# 3. Test new key
./scripts/test-api-key.sh

# 4. Verify all services working
make test

# 5. Revoke old key with provider
```

### Certificate Rotation

```bash
# 1. Generate new certificate
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout config/secrets/tls/server.key.new \
  -out config/secrets/tls/server.crt.new

# 2. Update service configuration
# Point to new certificate files

# 3. Test service
systemctl restart my-service

# 4. Remove old certificate
rm config/secrets/tls/server.key
rm config/secrets/tls/server.crt

# 5. Rename new to current
mv config/secrets/tls/server.key.new config/secrets/tls/server.key
mv config/secrets/tls/server.crt.new config/secrets/tls/server.crt
```

## Secure Secret Distribution

### Setup on New Node

Never email or copy passwords:

```bash
# 1. SSH to new node
ssh pi@new-node

# 2. Generate SSH key on node
ssh-keygen -t ed25519 -f ~/.ssh/id_rsa -N ""

# 3. Return public key securely
cat ~/.ssh/id_rsa.pub
# Email or share only the public key

# 4. Add to authorized_keys on boot node
cat new-node-key.pub >> config/secrets/ssh/authorized_keys

# 5. Test connection
ssh pi@new-node "echo OK"
```

### Using Secrets in Deployment

```bash
#!/bin/bash
# deployment/boot-node/04-apply-secrets.sh

# Only run on secure network
if [ "$SECURE_NETWORK" != "true" ]; then
  echo "ERROR: Only deploy secrets on secure network"
  exit 1
fi

# Copy secrets securely
scp -r -i config/secrets/ssh/id_rsa \
    config/secrets/ssh/id_rsa \
    pi@boot-node:/home/pi/.ssh/

# Fix permissions
ssh pi@boot-node "chmod 600 /home/pi/.ssh/id_rsa"

# Verify no world-readable secrets
ssh pi@boot-node "find /home/pi -type f -perm /077 | grep -E '(key|secret|password)' || echo 'OK'"
```

## Emergency Access Recovery

### If SSH Key Lost

```bash
# 1. Physical access required
# Connect monitor and keyboard to node

# 2. Boot into single-user mode
# Edit /boot/cmdline.txt to add: init=/bin/sh

# 3. Generate new SSH key
ssh-keygen -t ed25519 -f ~/.ssh/id_rsa -N ""

# 4. Export public key
cat ~/.ssh/id_rsa.pub

# 5. Update boot node
ssh-copy-id -i ~/.ssh/id_rsa.pub user@boot-node
```

### If Root Password Lost

```bash
# 1. Physical access required
# Boot into recovery mode

# 2. Reset root password
sudo passwd root

# 3. Update sudoers
sudo visudo  # Add back admin users

# 4. Restore SSH keys
# Copy from backup or recreate as above
```

## Backup Secrets Securely

### Encrypted Backup

```bash
#!/bin/bash
# operations/backups/backup-secrets.sh

# Backup secrets with encryption
tar czf - config/secrets/ | \
  gpg --encrypt --recipient your-gpg-key \
  > backups/secrets-$(date +%Y%m%d).tar.gz.gpg

# Verify backup
gpg --decrypt backups/secrets-*.gpg | tar tzf - | head
```

### Restore from Backup

```bash
#!/bin/bash
# operations/recovery/restore-secrets.sh

# Decrypt and restore
gpg --decrypt backups/secrets-20250101.tar.gz.gpg | \
  tar xz -C /

# Fix permissions
chmod 600 config/secrets/**
```

## Secrets Checklist

**Before Production Deployment:**

- ✅ No plaintext secrets in code
- ✅ No plaintext secrets in config files (except git-ignored)
- ✅ SSH keys generated and stored
- ✅ Database passwords set
- ✅ API keys obtained
- ✅ TLS certificates created
- ✅ All secrets in `config/secrets/`
- ✅ `config/secrets/.gitignore` configured
- ✅ Permissions set to 600
- ✅ Backup encrypted
- ✅ Recovery procedure tested

## FAQ

**Q: Can I commit passwords?**
A: No. Never commit credentials. Use `config/secrets/` (git-ignored).

**Q: How do I document secrets without leaking them?**
A: Document HOW to create them, not the actual values. See `config/secrets/README.md`.

**Q: What if someone commits a secret?**
A: Immediately rotate that secret. See "Rotating Secrets" section.

**Q: How do I test without real secrets?**
A: Use dummy/test credentials in test environment.

**Q: Can I share secrets via email?**
A: No. Only share public keys or use secure channels (Signal, etc).

---

See also: [SECURITY-BASELINE.md](SECURITY-BASELINE.md), [GIT-WORKFLOW.md](GIT-WORKFLOW.md)
