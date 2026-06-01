# =============================================================================
# Makefile — terraform-aws-security automation
# github.com/Protector080322/terraform-aws-security
# =============================================================================

.PHONY: help install validate fmt lint security opa plan apply destroy report clean

ENV     ?= dev
REGION  ?= eu-central-1
TF_DIR  := envs/$(ENV)
OPA_DIR := policies-as-code/opa

# Colors
GREEN  := \033[0;32m
BLUE   := \033[0;34m
YELLOW := \033[1;33m
RED    := \033[0;31m
NC     := \033[0m

## ─── HELP ────────────────────────────────────────────────────────────────────

help: ## Show this help
	@echo ""
	@echo "$(BLUE)terraform-aws-security — NIS2/DORA Compliance Framework$(NC)"
	@echo "$(BLUE)=========================================================$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Usage: make <target> [ENV=dev|prod] [REGION=eu-central-1]"
	@echo ""

## ─── INSTALL ─────────────────────────────────────────────────────────────────

install: ## Install all required tools for your OS
	@echo "$(BLUE)Detecting OS...$(NC)"
	@if [ "$$(uname)" = "Darwin" ]; then \
		bash install/macos.sh; \
	elif [ "$$(uname)" = "Linux" ]; then \
		bash install/linux.sh; \
	else \
		echo "$(YELLOW)Windows detected. Run: .\\install\\windows.ps1 in PowerShell$(NC)"; \
	fi

## ─── CODE QUALITY ────────────────────────────────────────────────────────────

fmt: ## Format all Terraform files
	@echo "$(BLUE)Formatting Terraform...$(NC)"
	terraform fmt -recursive
	@echo "$(GREEN)✅ Formatting done$(NC)"

fmt-check: ## Check formatting (no changes)
	@echo "$(BLUE)Checking Terraform format...$(NC)"
	terraform fmt -recursive -check -diff

validate-tf: ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform...$(NC)"
	cd $(TF_DIR) && terraform init -backend=false -input=false -no-color && terraform validate
	@echo "$(GREEN)✅ Terraform valid$(NC)"

## ─── SECURITY SCANNING ───────────────────────────────────────────────────────

tfsec: ## Run tfsec security scanner (HIGH+ severity)
	@echo "$(BLUE)Running tfsec...$(NC)"
	tfsec $(TF_DIR) --minimum-severity HIGH --no-module-downloads
	@echo "$(GREEN)✅ tfsec passed$(NC)"

checkov: ## Run checkov compliance scanner
	@echo "$(BLUE)Running checkov...$(NC)"
	checkov -d $(TF_DIR) --framework terraform --compact --quiet
	@echo "$(GREEN)✅ checkov passed$(NC)"

gitleaks: ## Scan for secrets in git history (NIS2 Art.25)
	@echo "$(BLUE)Scanning for secrets with gitleaks...$(NC)"
	gitleaks detect --source . --verbose
	@echo "$(GREEN)✅ No secrets found$(NC)"

secrets: gitleaks ## Alias for gitleaks

## ─── OPA COMPLIANCE ──────────────────────────────────────────────────────────

opa-test: ## Run OPA policy unit tests
	@echo "$(BLUE)Running OPA tests...$(NC)"
	opa test $(OPA_DIR) -v
	@echo "$(GREEN)✅ All OPA tests passed$(NC)"

opa-eval: ## Validate current plan against NIS2/DORA policies
	@if [ ! -f "$(TF_DIR)/plan.json" ]; then \
		echo "$(YELLOW)No plan.json found. Run: make plan first$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Validating plan against NIS2/DORA policies...$(NC)"
	@RESULT=$$(opa eval \
		--data $(OPA_DIR)/policies.rego \
		--input $(TF_DIR)/plan.json \
		--format raw \
		"data.terraform.security.result"); \
	echo "$$RESULT" | python3 -c "\
import sys, json; \
d = json.load(sys.stdin); \
print('Violations:', d.get('count', 0)); \
[print(' ❌', m) for m in d.get('messages', [])]; \
exit(0 if d.get('passed') else 1)"; \
	echo "$(GREEN)✅ Plan passes NIS2/DORA compliance$(NC)"

## ─── FULL VALIDATION ─────────────────────────────────────────────────────────

validate: fmt-check validate-tf opa-test gitleaks ## Run ALL compliance checks
	@echo ""
	@echo "$(GREEN)╔══════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║  ✅ ALL COMPLIANCE CHECKS PASSED    ║$(NC)"
	@echo "$(GREEN)╚══════════════════════════════════════╝$(NC)"
	@echo ""
	@bash scripts/validate-compliance.sh

security: tfsec checkov gitleaks ## Run security scanners only

lint: fmt-check validate-tf ## Run linting only

## ─── TERRAFORM ───────────────────────────────────────────────────────────────

init: ## Initialize Terraform (ENV=dev|prod)
	@echo "$(BLUE)Initializing Terraform ($(ENV))...$(NC)"
	cd $(TF_DIR) && terraform init
	@echo "$(GREEN)✅ Initialized$(NC)"

plan: init ## Create Terraform plan + convert to JSON for OPA
	@echo "$(BLUE)Creating Terraform plan ($(ENV))...$(NC)"
	cd $(TF_DIR) && terraform plan -out=tfplan -var="env=$(ENV)"
	cd $(TF_DIR) && terraform show -json tfplan > plan.json
	@echo "$(GREEN)✅ Plan created: $(TF_DIR)/plan.json$(NC)"
	@$(MAKE) opa-eval

apply: plan ## Apply Terraform (requires plan first)
	@echo "$(YELLOW)⚠️  About to apply to $(ENV) in $(REGION)$(NC)"
	@read -p "Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ]
	cd $(TF_DIR) && terraform apply tfplan
	@echo "$(GREEN)✅ Applied successfully$(NC)"

destroy: ## Destroy Terraform resources (DANGEROUS!)
	@echo "$(RED)⚠️  DANGER: This will DESTROY all resources in $(ENV)!$(NC)"
	@read -p "Type 'DESTROY-$(ENV)' to confirm: " confirm && [ "$$confirm" = "DESTROY-$(ENV)" ]
	cd $(TF_DIR) && terraform destroy -var="env=$(ENV)"

output: ## Show Terraform outputs
	cd $(TF_DIR) && terraform output -json | jq .

## ─── REPORTS ─────────────────────────────────────────────────────────────────

report: ## Generate NIS2/DORA compliance report
	@echo "$(BLUE)Generating compliance report...$(NC)"
	bash scripts/generate-report.sh
	@echo "$(GREEN)✅ Report saved to reports/$(NC)"

## ─── KUBERNETES ──────────────────────────────────────────────────────────────

k8s-validate: ## Validate Kubernetes configs
	@echo "$(BLUE)Validating Kubernetes configs...$(NC)"
	cd kubernetes/k3s-hardened && terraform validate
	@echo "$(GREEN)✅ K8s configs valid$(NC)"

## ─── UTILS ───────────────────────────────────────────────────────────────────

clean: ## Clean Terraform cache files
	@echo "$(BLUE)Cleaning Terraform cache...$(NC)"
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.tfplan" -delete 2>/dev/null || true
	find . -name "plan.json" -delete 2>/dev/null || true
	@echo "$(GREEN)✅ Cleaned$(NC)"

pre-commit-run: ## Run pre-commit hooks on all files
	pre-commit run --all-files

update-hooks: ## Update pre-commit hooks
	pre-commit autoupdate

aws-check: ## Check AWS credentials and region
	@echo "$(BLUE)Checking AWS...$(NC)"
	@aws sts get-caller-identity | jq .
	@echo "Region: $$(aws configure get region)"
	@REGION=$$(aws configure get region); \
	if [[ "$$REGION" != eu-* ]]; then \
		echo "$(YELLOW)⚠️  Region $$REGION is not EU! Set eu-central-1 for NIS2$(NC)"; \
	else \
		echo "$(GREEN)✅ EU region confirmed$(NC)"; \
	fi

version: ## Show versions of all tools
	@echo "Terraform: $$(terraform version -json | python3 -c 'import sys,json; print(json.load(sys.stdin)[\"terraform_version\"])' 2>/dev/null)"
	@echo "AWS CLI:   $$(aws --version 2>/dev/null)"
	@echo "OPA:       $$(opa version 2>/dev/null | head -1)"
	@echo "tfsec:     $$(tfsec --version 2>/dev/null | head -1)"
	@echo "checkov:   $$(checkov --version 2>/dev/null)"
	@echo "gitleaks:  $$(gitleaks version 2>/dev/null)"
	@echo "kubectl:   $$(kubectl version --client --short 2>/dev/null | head -1)"
