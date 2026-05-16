# ============================================================================
# Makefile for AWS Infrastructure Platform
# ============================================================================
# This Makefile provides convenient commands for common infrastructure tasks.
#
# Usage:
#   make <target>
#
# Examples:
#   make init ENV=dev SERVICE=ec2
#   make plan ENV=dev SERVICE=ec2
#   make apply ENV=dev SERVICE=ec2
#   make destroy ENV=dev SERVICE=ec2
# ============================================================================

.PHONY: help init plan apply destroy validate fmt clean setup-backend test-modules

# Default target
.DEFAULT_GOAL := help

# Variables
ENV ?= dev
SERVICE ?= ec2
REGION ?= us-east-1
BACKEND_BUCKET ?= ramiz-takildar-infra
DYNAMODB_TABLE ?= terraform-locks
TERRAFORM_DIR = terraform/environments/$(ENV)/$(SERVICE)

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# ============================================================================
# Help Target
# ============================================================================

help: ## Show this help message
	@echo "$(BLUE)AWS Infrastructure Platform - Makefile$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Variables:$(NC)"
	@echo "  $(YELLOW)ENV$(NC)              Environment (dev, staging, prod) [default: dev]"
	@echo "  $(YELLOW)SERVICE$(NC)          Service name (ec2, s3, vpc, etc.) [default: ec2]"
	@echo "  $(YELLOW)REGION$(NC)           AWS region [default: us-east-1]"
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make init ENV=dev SERVICE=ec2"
	@echo "  make plan ENV=prod SERVICE=vpc"
	@echo "  make apply ENV=staging SERVICE=s3"
	@echo "  make destroy ENV=dev SERVICE=ec2"

# ============================================================================
# Setup Targets
# ============================================================================

setup-backend: ## Setup Terraform backend (DynamoDB table)
	@echo "$(BLUE)Setting up Terraform backend...$(NC)"
	@cd terraform/backend && chmod +x setup-dynamodb.sh
	@cd terraform/backend && ./setup-dynamodb.sh $(DYNAMODB_TABLE) $(REGION)
	@echo "$(GREEN)✓ Backend setup complete$(NC)"

check-aws: ## Check AWS credentials
	@echo "$(BLUE)Checking AWS credentials...$(NC)"
	@aws sts get-caller-identity > /dev/null 2>&1 || (echo "$(RED)✗ AWS credentials not configured$(NC)" && exit 1)
	@echo "$(GREEN)✓ AWS credentials configured$(NC)"
	@aws sts get-caller-identity

check-terraform: ## Check Terraform installation
	@echo "$(BLUE)Checking Terraform installation...$(NC)"
	@terraform version > /dev/null 2>&1 || (echo "$(RED)✗ Terraform not installed$(NC)" && exit 1)
	@echo "$(GREEN)✓ Terraform installed$(NC)"
	@terraform version

check-env: ## Validate environment and service variables
	@echo "$(BLUE)Validating environment variables...$(NC)"
	@if [ "$(ENV)" != "dev" ] && [ "$(ENV)" != "staging" ] && [ "$(ENV)" != "prod" ]; then \
		echo "$(RED)✗ Invalid ENV: $(ENV). Must be dev, staging, or prod$(NC)"; \
		exit 1; \
	fi
	@if [ ! -d "$(TERRAFORM_DIR)" ]; then \
		echo "$(RED)✗ Directory not found: $(TERRAFORM_DIR)$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ Environment: $(ENV)$(NC)"
	@echo "$(GREEN)✓ Service: $(SERVICE)$(NC)"
	@echo "$(GREEN)✓ Directory: $(TERRAFORM_DIR)$(NC)"

# ============================================================================
# Terraform Targets
# ============================================================================

init: check-aws check-terraform check-env ## Initialize Terraform
	@echo "$(BLUE)Initializing Terraform for $(ENV)/$(SERVICE)...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform init \
		-backend-config="bucket=$(BACKEND_BUCKET)" \
		-backend-config="key=$(ENV)/$(SERVICE)/terraform.tfstate" \
		-backend-config="region=$(REGION)" \
		-backend-config="dynamodb_table=$(DYNAMODB_TABLE)" \
		-backend-config="encrypt=true"
	@echo "$(GREEN)✓ Terraform initialized$(NC)"

validate: init ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform configuration...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform validate
	@echo "$(GREEN)✓ Configuration is valid$(NC)"

fmt: ## Format Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(NC)"
	@terraform fmt -recursive terraform/
	@echo "$(GREEN)✓ Files formatted$(NC)"

fmt-check: ## Check Terraform formatting
	@echo "$(BLUE)Checking Terraform formatting...$(NC)"
	@terraform fmt -check -recursive terraform/
	@echo "$(GREEN)✓ Formatting is correct$(NC)"

plan: init ## Run Terraform plan
	@echo "$(BLUE)Running Terraform plan for $(ENV)/$(SERVICE)...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform plan -out=tfplan
	@echo "$(GREEN)✓ Plan complete$(NC)"

apply: init ## Apply Terraform changes
	@echo "$(YELLOW)⚠ This will apply changes to $(ENV)/$(SERVICE)$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(BLUE)Applying Terraform changes...$(NC)"; \
		cd $(TERRAFORM_DIR) && terraform apply -auto-approve; \
		echo "$(GREEN)✓ Apply complete$(NC)"; \
	else \
		echo "$(YELLOW)Apply cancelled$(NC)"; \
	fi

apply-plan: init ## Apply from saved plan
	@echo "$(BLUE)Applying saved plan for $(ENV)/$(SERVICE)...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform apply tfplan
	@echo "$(GREEN)✓ Apply complete$(NC)"

destroy: init ## Destroy Terraform resources
	@echo "$(RED)⚠ WARNING: This will destroy all resources in $(ENV)/$(SERVICE)$(NC)"
	@read -p "Are you absolutely sure? Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		echo "$(BLUE)Destroying resources...$(NC)"; \
		cd $(TERRAFORM_DIR) && terraform destroy -auto-approve; \
		echo "$(GREEN)✓ Destroy complete$(NC)"; \
	else \
		echo "$(YELLOW)Destroy cancelled$(NC)"; \
	fi

output: init ## Show Terraform outputs
	@echo "$(BLUE)Terraform outputs for $(ENV)/$(SERVICE):$(NC)"
	@cd $(TERRAFORM_DIR) && terraform output

state-list: init ## List resources in state
	@echo "$(BLUE)Resources in $(ENV)/$(SERVICE) state:$(NC)"
	@cd $(TERRAFORM_DIR) && terraform state list

state-show: init ## Show specific resource
	@echo "$(BLUE)Enter resource name:$(NC)"
	@read resource; \
	cd $(TERRAFORM_DIR) && terraform state show $$resource

# ============================================================================
# Module Testing
# ============================================================================

test-modules: ## Test all Terraform modules
	@echo "$(BLUE)Testing Terraform modules...$(NC)"
	@for module in terraform/modules/*; do \
		if [ -d "$$module" ]; then \
			echo "$(YELLOW)Testing $$module...$(NC)"; \
			cd $$module && terraform init -backend=false && terraform validate; \
			if [ $$? -eq 0 ]; then \
				echo "$(GREEN)✓ $$module is valid$(NC)"; \
			else \
				echo "$(RED)✗ $$module validation failed$(NC)"; \
				exit 1; \
			fi; \
		fi; \
	done
	@echo "$(GREEN)✓ All modules validated$(NC)"

# ============================================================================
# Security Scanning
# ============================================================================

security-scan: ## Run security scans (tfsec)
	@echo "$(BLUE)Running security scan...$(NC)"
	@if command -v tfsec > /dev/null; then \
		tfsec $(TERRAFORM_DIR); \
	else \
		echo "$(YELLOW)⚠ tfsec not installed. Install with: brew install tfsec$(NC)"; \
	fi

checkov-scan: ## Run Checkov security scan
	@echo "$(BLUE)Running Checkov scan...$(NC)"
	@if command -v checkov > /dev/null; then \
		checkov -d $(TERRAFORM_DIR); \
	else \
		echo "$(YELLOW)⚠ checkov not installed. Install with: pip install checkov$(NC)"; \
	fi

# ============================================================================
# Utility Targets
# ============================================================================

clean: ## Clean Terraform files
	@echo "$(BLUE)Cleaning Terraform files...$(NC)"
	@find terraform -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find terraform -type f -name "tfplan" -delete 2>/dev/null || true
	@find terraform -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

list-envs: ## List all environments
	@echo "$(BLUE)Available environments:$(NC)"
	@ls -1 terraform/environments/

list-services: ## List services for environment
	@echo "$(BLUE)Services in $(ENV):$(NC)"
	@ls -1 terraform/environments/$(ENV)/ 2>/dev/null || echo "$(RED)Environment not found$(NC)"

cost-estimate: init ## Estimate infrastructure costs (requires infracost)
	@echo "$(BLUE)Estimating costs for $(ENV)/$(SERVICE)...$(NC)"
	@if command -v infracost > /dev/null; then \
		cd $(TERRAFORM_DIR) && infracost breakdown --path .; \
	else \
		echo "$(YELLOW)⚠ infracost not installed. Install from: https://www.infracost.io/docs/$(NC)"; \
	fi

graph: init ## Generate Terraform dependency graph
	@echo "$(BLUE)Generating dependency graph...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform graph | dot -Tpng > graph.png
	@echo "$(GREEN)✓ Graph saved to $(TERRAFORM_DIR)/graph.png$(NC)"

# ============================================================================
# State Management
# ============================================================================

state-pull: init ## Pull remote state
	@echo "$(BLUE)Pulling remote state...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform state pull > terraform.tfstate.backup
	@echo "$(GREEN)✓ State saved to terraform.tfstate.backup$(NC)"

state-push: init ## Push local state (use with caution)
	@echo "$(RED)⚠ WARNING: This will overwrite remote state$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd $(TERRAFORM_DIR) && terraform state push terraform.tfstate; \
		echo "$(GREEN)✓ State pushed$(NC)"; \
	else \
		echo "$(YELLOW)Push cancelled$(NC)"; \
	fi

unlock: ## Force unlock state (requires LOCK_ID)
	@echo "$(BLUE)Enter lock ID:$(NC)"
	@read lock_id; \
	cd $(TERRAFORM_DIR) && terraform force-unlock -force $$lock_id

# ============================================================================
# Documentation
# ============================================================================

docs: ## Generate module documentation
	@echo "$(BLUE)Generating module documentation...$(NC)"
	@if command -v terraform-docs > /dev/null; then \
		for module in terraform/modules/*; do \
			if [ -d "$$module" ]; then \
				echo "Generating docs for $$module..."; \
				terraform-docs markdown table $$module > $$module/README.md; \
			fi; \
		done; \
		echo "$(GREEN)✓ Documentation generated$(NC)"; \
	else \
		echo "$(YELLOW)⚠ terraform-docs not installed. Install from: https://terraform-docs.io/$(NC)"; \
	fi

# ============================================================================
# Quick Commands
# ============================================================================

dev-ec2-plan: ## Quick: Plan dev EC2
	@$(MAKE) plan ENV=dev SERVICE=ec2

dev-ec2-apply: ## Quick: Apply dev EC2
	@$(MAKE) apply ENV=dev SERVICE=ec2

dev-vpc-plan: ## Quick: Plan dev VPC
	@$(MAKE) plan ENV=dev SERVICE=vpc

dev-vpc-apply: ## Quick: Apply dev VPC
	@$(MAKE) apply ENV=dev SERVICE=vpc

prod-plan: ## Quick: Plan production (requires SERVICE)
	@$(MAKE) plan ENV=prod SERVICE=$(SERVICE)

# ============================================================================
# CI/CD Helpers
# ============================================================================

ci-validate: check-terraform fmt-check ## CI: Validate configuration
	@echo "$(BLUE)Running CI validation...$(NC)"
	@$(MAKE) test-modules
	@echo "$(GREEN)✓ CI validation passed$(NC)"

ci-plan: init ## CI: Run plan for CI/CD
	@cd $(TERRAFORM_DIR) && terraform plan -detailed-exitcode -out=tfplan

ci-apply: init ## CI: Apply for CI/CD
	@cd $(TERRAFORM_DIR) && terraform apply -auto-approve tfplan

# ============================================================================
# Installation
# ============================================================================

install-tools: ## Install required tools (macOS)
	@echo "$(BLUE)Installing required tools...$(NC)"
	@if command -v brew > /dev/null; then \
		brew install terraform awscli tfsec terraform-docs; \
		pip3 install checkov; \
		echo "$(GREEN)✓ Tools installed$(NC)"; \
	else \
		echo "$(RED)✗ Homebrew not found. Please install from: https://brew.sh/$(NC)"; \
	fi

# ============================================================================
# Version Information
# ============================================================================

version: ## Show version information
	@echo "$(BLUE)Version Information:$(NC)"
	@echo "Terraform: $$(terraform version -json | jq -r '.terraform_version')"
	@echo "AWS CLI: $$(aws --version | cut -d' ' -f1)"
	@echo "Platform: AWS Infrastructure Platform v1.0.0"

# ============================================================================
# Notes
# ============================================================================
#
# Common Workflows:
# -----------------
#
# 1. First-time setup:
#    make setup-backend
#    make check-aws
#    make check-terraform
#
# 2. Deploy new infrastructure:
#    make plan ENV=dev SERVICE=ec2
#    make apply ENV=dev SERVICE=ec2
#
# 3. Update existing infrastructure:
#    make plan ENV=prod SERVICE=vpc
#    make apply ENV=prod SERVICE=vpc
#
# 4. Destroy infrastructure:
#    make destroy ENV=dev SERVICE=ec2
#
# 5. Validate and format:
#    make fmt
#    make validate ENV=dev SERVICE=ec2
#
# 6. Security scanning:
#    make security-scan ENV=prod SERVICE=vpc
#
# ============================================================================
