# Portable Pi 5 Cluster - Makefile
# Standardizes common operational tasks
# Usage: make <target>

.PHONY: help status validate diagnose backup restore clean

SHELL := /bin/bash
SCRIPTS_DIR := scripts
CONFIG_DIR := config
BACKUP_DIR := backups
TIMESTAMP := $(shell date +%Y%m%d-%H%M%S)

help:
	@echo "Portable Pi 5 Cluster - Operations"
	@echo ""
	@echo "Diagnostic Commands:"
	@echo "  make status              - Check cluster status and health"
	@echo "  make validate            - Validate all configuration files"
	@echo "  make diagnose            - Full system diagnostics"
	@echo ""
	@echo "Configuration Commands:"
	@echo "  make backup              - Backup current configuration"
	@echo "  make restore-config      - Restore from latest backup"
	@echo "  make list-backups        - Show available backups"
	@echo ""
	@echo "Setup Commands (When Ready):"
	@echo "  make setup-boot-node     - Configure boot node (future)"
	@echo "  make setup-isr-node      - Configure ISR node (future)"
	@echo ""
	@echo "Utility Commands:"
	@echo "  make clean               - Remove temporary files"
	@echo "  make git-check           - Check git status"
	@echo ""

# Diagnostic Operations
status:
	@echo "Checking cluster status..."
	@sudo $(SCRIPTS_DIR)/cluster-status.sh

diagnose: validate status
	@echo "Full diagnostics complete"

validate:
	@echo "Validating configuration files..."
	@$(SCRIPTS_DIR)/validate-config.sh

# Configuration Backup/Restore
backup:
	@echo "Backing up configuration files..."
	@mkdir -p $(BACKUP_DIR)
	@tar -czf $(BACKUP_DIR)/cluster-config-$(TIMESTAMP).tar.gz \
		$(CONFIG_DIR)/ \
		--exclude='*.swp' \
		--exclude='*~'
	@echo "✓ Backup created: $(BACKUP_DIR)/cluster-config-$(TIMESTAMP).tar.gz"

restore-config:
	@echo "Finding latest backup..."
	@latest=$$(ls -t $(BACKUP_DIR)/cluster-config-*.tar.gz 2>/dev/null | head -1); \
	if [ -z "$$latest" ]; then \
		echo "✗ No backups found"; \
		exit 1; \
	fi; \
	echo "Restoring from: $$latest"; \
	tar -xzf $$latest; \
	echo "✓ Restore complete"

list-backups:
	@echo "Available backups:"
	@ls -lh $(BACKUP_DIR)/cluster-config-*.tar.gz 2>/dev/null || echo "  No backups found"

# Utility Commands
clean:
	@echo "Removing temporary files..."
	@rm -f $(SCRIPTS_DIR)/*.pyc
	@rm -f /tmp/cluster-status-*.txt
	@echo "✓ Cleanup complete"

git-check:
	@echo "Git status:"
	@git status

# Future Setup Commands (stubs)
setup-boot-node:
	@echo "setup-boot-node: Not yet implemented"
	@echo "Run 'make status' first to understand current state"

setup-isr-node:
	@echo "setup-isr-node: Not yet implemented"

setup-mesh-node:
	@echo "setup-mesh-node: Not yet implemented"

setup-vhf-node:
	@echo "setup-vhf-node: Not yet implemented"

# Development helpers
watch-logs:
	@echo "Watching cluster logs (Ctrl+C to stop)..."
	@tail -f /var/log/cluster-diagnostics.log /var/log/syslog 2>/dev/null

check-services:
	@echo "Boot Node Services:"
	@systemctl status dnsmasq --no-pager || echo "  dnsmasq: not running"
	@systemctl status nfs-server --no-pager || echo "  nfs-server: not running"
	@systemctl status ssh --no-pager || echo "  ssh: not running"
	@systemctl status chronyd --no-pager || echo "  chronyd: not running"
