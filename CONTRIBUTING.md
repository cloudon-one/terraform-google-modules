# Contributing to GCP Terraform Modules

Thank you for your interest in contributing to our GCP Terraform modules! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Contributing Process](#contributing-process)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)
- [Release Process](#release-process)
- [Community and Support](#community-and-support)

## Code of Conduct

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, sex characteristics, gender identity and expression, level of experience, education, socio-economic status, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our Standards

**Positive behaviors include:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

**Unacceptable behaviors include:**
- The use of sexualized language or imagery
- Trolling, insulting/derogatory comments, and personal or political attacks
- Public or private harassment
- Publishing others' private information without explicit permission
- Other conduct which could reasonably be considered inappropriate

### Enforcement

Project maintainers are responsible for clarifying standards and may take appropriate and fair corrective action in response to any instances of unacceptable behavior.

Report violations to: `conduct@yourcompany.com`

## Getting Started

### Prerequisites

Before contributing, ensure you have:

1. **Google Cloud Account** with appropriate permissions
2. **Development Tools**:
   ```bash
   # Required tools
   gcloud --version    # Google Cloud SDK
   terraform --version # Terraform >= 1.5.0
   git --version      # Git version control
   
   # Recommended tools
   tflint --version   # Terraform linter
   tfsec --version    # Terraform security scanner
   pre-commit --version # Git hooks framework
   ```

3. **Knowledge Requirements**:
   - Terraform fundamentals
   - Google Cloud Platform services
   - Infrastructure as Code principles
   - Git workflow basics

### First-Time Setup

1. **Fork and Clone**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/gcp-terraform-modules.git
   cd gcp-terraform-modules
   git remote add upstream https://github.com/ORIGINAL_OWNER/gcp-terraform-modules.git
   ```

2. **Install Development Dependencies**:
   ```bash
   # Install pre-commit hooks
   pre-commit install
   
   # Install additional tools
   go install github.com/terraform-linters/tflint@latest
   brew install tfsec checkov
   ```

3. **Set Up Google Cloud**:
   ```bash
   gcloud auth application-default login
   gcloud config set project YOUR_DEV_PROJECT_ID
   ```

## Development Environment

### Project Structure

```
gcp-terraform-modules/
├── terraform-google-svc-projects/    # Multi-project management
├── terraform-google-svpc/            # Shared VPC networking
├── terraform-google-gke/             # GKE cluster
├── terraform-google-bastion/         # Bastion host
├── terraform-google-cloudsql/        # Cloud SQL database
├── terraform-google-memorystore/     # Redis cache
├── terraform-google-iam/             # IAM management
├── terraform-google-vpc-sc/          # VPC Service Controls
├── examples/                         # Usage examples
├── test/                            # Integration tests
├── docs/                            # Additional documentation
├── .github/                         # GitHub workflows
├── scripts/                         # Utility scripts
├── README.md
├── CONTRIBUTING.md
├── SECURITY.md
└── LICENSE
```

### Module Structure Standards

Each module should follow this structure:

```
terraform-google-[service]/
├── README.md              # Module documentation
├── main.tf               # Primary resources
├── variables.tf          # Input variables
├── outputs.tf            # Output values
├── versions.tf           # Provider requirements
├── examples/             # Usage examples
│   ├── basic/
│   ├── advanced/
│   └── complete/
└── test/                # Module-specific tests
    └── [service]_test.go
```

### Environment Setup

1. **Create Development Project**:
   ```bash
   gcloud projects create dev-terraform-modules-$(date +%s)
   gcloud config set project dev-terraform-modules-$(date +%s)
   gcloud billing projects link PROJECT_ID --billing-account=BILLING_ACCOUNT_ID
   ```

2. **Enable Required APIs**:
   ```bash
   ./scripts/enable-apis.sh
   ```

3. **Set Up Testing Environment**:
   ```bash
   export TF_VAR_project_id="your-dev-project"
   export TF_VAR_region="us-central1"
   export TF_VAR_billing_account_id="your-billing-account"
   ```

## Contributing Process

### Types of Contributions

We welcome various types of contributions:

- 🐛 **Bug fixes**: Fix issues in existing modules
- ✨ **Features**: Add new functionality to modules  
- 📚 **Documentation**: Improve or add documentation
- 🧪 **Tests**: Add or improve test coverage
- 🔧 **Infrastructure**: Improve CI/CD, tooling, or processes
- 🎨 **Examples**: Add usage examples and tutorials

### Contribution Workflow

1. **Check Existing Issues**:
   - Browse [GitHub Issues](https://github.com/your-org/gcp-terraform-modules/issues)
   - Look for `good first issue` or `help wanted` labels
   - Comment on issues you'd like to work on

2. **Create or Update Issue**:
   - For bugs: Use the bug report template
   - For features: Use the feature request template
   - For questions: Use GitHub Discussions

3. **Development Process**:
   ```bash
   # Create feature branch
   git checkout -b feature/your-feature-name
   
   # Make your changes
   # ... code, test, document
   
   # Run validation
   make validate
   make test
   
   # Commit and push
   git add .
   git commit -m "feat: add new feature"
   git push origin feature/your-feature-name
   ```

4. **Submit Pull Request**:
   - Use the pull request template
   - Include tests and documentation
   - Reference related issues

## Coding Standards

### Terraform Style Guide

Follow the [official Terraform style guide](https://www.terraform.io/docs/language/style.html):

1. **File Organization**:
   ```hcl
   # Order within files
   terraform {           # Terraform settings
     required_version = ">= 1.5"
     required_providers {
       google = {
         source  = "hashicorp/google"
         version = ">= 5.0"
       }
     }
   }
   
   locals {              # Local values
     common_labels = {
       managed_by = "terraform"
     }
   }
   
   data "google_client_config" "default" {}  # Data sources
   
   resource "google_compute_network" "vpc" {  # Resources
     # Configuration
   }
   ```

2. **Naming Conventions**:
   ```hcl
   # Use snake_case for all identifiers
   variable "vpc_name" {}
   resource "google_compute_network" "main_vpc" {}
   
   # Use descriptive names
   # ❌ Bad
   variable "n" {}
   resource "google_compute_network" "net" {}
   
   # ✅ Good  
   variable "network_name" {}
   resource "google_compute_network" "main_network" {}
   ```

3. **Variable Standards**:
   ```hcl
   variable "project_id" {
     description = "The ID of the project where resources will be created"
     type        = string
     validation {
       condition     = length(var.project_id) > 0
       error_message = "Project ID must not be empty."
     }
   }
   
   variable "labels" {
     description = "A map of labels to assign to resources"
     type        = map(string)
     default     = {}
   }
   ```

4. **Resource Configuration**:
   ```hcl
   resource "google_compute_network" "vpc" {
     name                    = var.network_name
     auto_create_subnetworks = false
     project                 = var.project_id
     
     labels = merge(
       var.labels,
       {
         component = "networking"
       }
     )
     
     lifecycle {
       prevent_destroy = true
     }
   }
   ```

### Code Quality Tools

Use these tools to maintain code quality:

```bash
# Format Terraform files
terraform fmt -recursive

# Validate syntax
terraform validate

# Lint with tflint
tflint --init
tflint

# Security scan
tfsec .
checkov -f main.tf

# Pre-commit hooks (runs automatically)
pre-commit run --all-files
```

### Pre-commit Configuration

We use pre-commit hooks (`.pre-commit-config.yaml`):

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.81.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_tfsec
      - id: terraform_checkov
      - id: terraform_docs
```

## Testing Guidelines

### Test Types

1. **Unit Tests**: Test individual resources and modules
2. **Integration Tests**: Test module interactions
3. **End-to-End Tests**: Test complete infrastructure deployment
4. **Security Tests**: Test security configurations

### Testing Framework

We use [Terratest](https://terratest.gruntwork.io/) for testing:

```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestBasicGKE(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/basic",
        Vars: map[string]interface{}{
            "project_id": "test-project",
            "region":     "us-central1",
        },
    }
    
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
    
    // Test outputs
    clusterName := terraform.Output(t, terraformOptions, "cluster_name")
    assert.NotEmpty(t, clusterName)
}
```

### Running Tests

```bash
# Run all tests
make test

# Run specific module tests
cd terraform-google-gke/test
go test -v -timeout 30m

# Run security tests
make security-test

# Run integration tests
make integration-test
```

### Test Environment

Use dedicated test projects:

```bash
# Create test project
export TF_VAR_project_id="test-terraform-modules-$(date +%s)"
gcloud projects create $TF_VAR_project_id
gcloud billing projects link $TF_VAR_project_id --billing-account=$BILLING_ACCOUNT_ID

# Run tests
make test

# Clean up
gcloud projects delete $TF_VAR_project_id
```

## Documentation

### README Standards

Each module must have comprehensive documentation:

1. **Module Description**: Purpose and features
2. **Usage Examples**: Basic and advanced examples
3. **Requirements**: Terraform and provider versions
4. **Inputs**: All variables with descriptions
5. **Outputs**: All outputs with descriptions
6. **Resources**: Resources created by module

### Documentation Generation

Use `terraform-docs` to generate documentation:

```bash
# Generate README for module
terraform-docs markdown table --output-file README.md .

# Update all module documentation
make docs
```

### Example Standards

Provide multiple example configurations:

```
examples/
├── basic/              # Minimal working example
├── complete/           # Full-featured example
└── real-world/         # Production-like example
```

Each example should:
- Be self-contained and runnable
- Include clear variable definitions
- Show expected outputs
- Include cleanup instructions

## Pull Request Process

### Before Submitting

Ensure your contribution meets these requirements:

- [ ] Code follows style guidelines
- [ ] Tests pass locally
- [ ] Documentation is updated
- [ ] Security scan passes
- [ ] Examples are provided
- [ ] Commit messages follow convention

### Pull Request Template

Use this template for PRs:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Breaking change

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass  
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
```

### Review Process

1. **Automated Checks**: CI/CD pipeline runs automatically
2. **Code Review**: Maintainers review code and provide feedback
3. **Testing**: Reviewers may run additional tests
4. **Approval**: Requires approval from at least one maintainer
5. **Merge**: Maintainer merges after all checks pass

### Commit Message Convention

Use [Conventional Commits](https://conventionalcommits.org/):

```bash
# Format
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]

# Examples
feat(gke): add support for confidential nodes
fix(cloudsql): resolve backup configuration issue
docs(README): update usage examples
test(bastion): add integration tests
```

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `style`, `chore`

## Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Steps

1. **Version Bump**: Update version in relevant files
2. **Changelog**: Update CHANGELOG.md with changes
3. **Tag**: Create and push git tag
4. **Release**: Create GitHub release with notes
5. **Announcement**: Notify community of release

### Changelog Format

```markdown
## [1.2.0] - 2024-01-15

### Added
- New feature X for module Y
- Support for Z in module A

### Changed  
- Improved performance of module B
- Updated default values for module C

### Fixed
- Bug fix for issue #123
- Security vulnerability in module D

### Breaking Changes
- Removed deprecated variable X
- Changed default behavior of Y
```

## Community and Support

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and general discussion
- **Slack**: `#terraform-modules` channel (invite required)
- **Email**: `maintainers@yourcompany.com`

### Getting Help

1. **Check Documentation**: README, examples, and docs/
2. **Search Issues**: Existing issues and discussions
3. **Ask Questions**: GitHub Discussions or Slack
4. **Report Bugs**: Use issue templates

### Recognition

We recognize contributors through:

- **Contributors list** in README
- **Release notes** mentions
- **Annual contributor awards**
- **Speaker opportunities** at conferences

### Mentorship

New contributors can get help through:

- **Good First Issues**: Labeled issues for beginners
- **Mentorship Program**: Pairing with experienced contributors
- **Office Hours**: Regular Q&A sessions
- **Documentation**: Comprehensive guides and examples

## Tools and Resources

### Recommended IDE Setup

**Visual Studio Code Extensions**:
- HashiCorp Terraform
- Google Cloud Code
- GitLens
- YAML
- Markdown All in One

**Settings**:
```json
{
  "[terraform]": {
    "editor.formatOnSave": true,
    "editor.formatOnSaveMode": "file"
  }
}
```

### Useful Scripts

Check the `scripts/` directory:
- `validate.sh`: Run all validation checks  
- `test.sh`: Run all tests
- `docs.sh`: Generate documentation
- `setup.sh`: Initial development setup

### External Resources

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Google Cloud Architecture Center](https://cloud.google.com/architecture)
- [Terratest Documentation](https://terratest.gruntwork.io/)
- [Google Cloud Terraform Provider](https://registry.terraform.io/providers/hashicorp/google/latest)

---

Thank you for contributing to GCP Terraform Modules! Your contributions help make infrastructure as code more accessible and reliable for everyone.

**Questions?** Reach out to us at `maintainers@yourcompany.com` or create a discussion on GitHub.

---

**Last Updated**: September 2025  
**Version**: 1.0