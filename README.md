# Hardening Workflows Test Suite

This repository provides comprehensive testing for [huntridge-labs/hardening-workflows](https://github.com/huntridge-labs/hardening-workflows), specifically for validating PR #101 (ZAP DAST Scanner Integration).

## Purpose

Test the ZAP scanner integration to ensure:
- All scan modes work correctly (URL, Docker, Compose)
- All scan types function properly (Baseline, Full, API)
- Failure thresholds trigger correctly
- Integration with existing scanners is seamless
- Reporting and artifacts work as expected

## Test Strategy

This repository uses **existing, well-maintained vulnerable containers** instead of custom code:

- **OWASP Juice Shop** (`bkimminich/juice-shop`) - Comprehensive vulnerable web application
- **DVWA** (`vulnerables/web-dvwa`) - Damn Vulnerable Web Application
- **Podinfo** (`ghcr.io/stefanprodan/podinfo`) - Clean application for baseline testing
- **Altoro Mutual** (`demo.testfire.net`) - OWASP's public test site

## Test Workflows

### Scan Mode Tests
- `test-zap-url-mode.yml` - Tests URL mode against external target
- `test-zap-docker-juiceshop.yml` - Tests Docker mode with Juice Shop
- `test-zap-docker-dvwa.yml` - Tests Docker mode with DVWA
- `test-zap-docker-podinfo.yml` - Tests Docker mode with clean app
- `test-zap-compose-mode.yml` - Tests Compose mode with multiple containers

### Functional Tests
- `test-zap-thresholds.yml` - Validates failure threshold logic
- `test-zap-integration.yml` - Tests ZAP with other scanners

## Running Tests

### Quick Start with Makefile

```bash
# Setup (first time only)
make setup

# View all available commands
make help

# Local testing (quick debugging)
make test-juiceshop
make test-dvwa
make test-podinfo

# GitHub Actions (validates PR #101)
make github-all
make github-watch
```

### Option 1: Local Testing (Fast, Debugging)

**⚠️ Local testing does NOT test the workflow integration. Use GitHub Actions to validate PR #101.**

Local testing is useful for:
- Quick debugging
- Learning how ZAP works
- Rapid iteration

```bash
# Quick test
./code/local-test.sh

# Test specific target
TARGET=juiceshop SCAN_TYPE=baseline ./code/local-test.sh
TARGET=dvwa SCAN_TYPE=full ./code/local-test.sh
TARGET=podinfo ./code/local-test.sh

# Interactive testing with ZAP UI
docker-compose -f docker-compose.local.yml up -d
open http://localhost:8080/zap
```

See [Local Testing Guide](docs/local-testing.md) for details.

### Option 2: GitHub Actions (Official, Validates PR #101)

**✅ This is the official way to test PR #101 integration.**

```bash
# Run all workflows
gh workflow run test-zap-docker-juiceshop.yml
gh workflow run test-zap-docker-dvwa.yml
gh workflow run test-zap-url-mode.yml
gh workflow run test-zap-compose-mode.yml
gh workflow run test-zap-thresholds.yml
gh workflow run test-zap-integration.yml

# Or use the master workflow
gh workflow run run-all-tests.yml --field test_suite=all

# Monitor results
gh run watch
gh run list
```

## Validation

### Automated Validation
Use the validation script to check scan results:

```bash
# Download the ZAP report artifact from workflow
gh run download <run-id>

# Validate results
chmod +x .github/scripts/validate-zap-results.sh
.github/scripts/validate-zap-results.sh \
  zap-report.json \
  .github/scripts/expected-vulnerabilities-juiceshop.txt
```

### Manual Validation Checklist

See `data/test-checklist.csv` for the comprehensive test checklist with 70+ validation points covering:

1. **Scan Mode Verification** (5 tests)
2. **Scan Type Verification** (7 tests)
3. **Threshold Testing** (6 tests)
4. **Integration Testing** (4 tests)
5. **Configuration Options** (4 tests)
6. **Reporting & Artifacts** (6 tests)
7. **Error Handling** (6 tests)
8. **Performance** (4 tests)
9. **Functional Tests** (5 tests)
10. **Detection Validation** (9 tests)
11. **Documentation** (5 tests)
12. **Validation** (4 tests)
13. **Security** (4 tests)
14. **Regression** (3 tests)

## Test Checklist CSV

The `data/test-checklist.csv` file contains:
- **Category**: Test grouping
- **Test ID**: Unique identifier
- **Test Name**: Short description
- **Description**: Detailed test description
- **Expected Result**: What should happen
- **Test File**: Which workflow tests this
- **Validation Method**: How to verify
- **Status**: Track completion (empty by default)

Import this into your spreadsheet tool to track testing progress.

## Key Validation Points

### Must Pass
- ✅ All three scan modes work (url, docker-run, compose)
- ✅ All three scan types work (baseline, full, api)
- ✅ ZAP is opt-in (not included in 'all' scanners)
- ✅ Failure thresholds trigger correctly
- ✅ Reports are generated and parseable
- ✅ Known vulnerabilities are detected

### Must Not Happen
- ❌ ZAP runs when scanners='all'
- ❌ Breaks existing scanners
- ❌ Orphaned containers after scan
- ❌ False positives on clean applications
- ❌ Workflow passes when it should fail

## PR #101 Review

Testing PR commit: `79dbc2998a0c6f83e77d44176ea38fc67bd15fe0`

All workflows reference this specific commit:
```yaml
uses: huntridge-labs/hardening-workflows/.github/workflows/reusable-security-hardening.yml@79dbc2998a0c6f83e77d44176ea38fc67bd15fe0
```

## Expected Vulnerabilities

### OWASP Juice Shop
- Cross-Site Scripting (XSS)
- SQL Injection
- Missing Security Headers (CSP, X-Frame-Options, etc.)
- Insecure Cookie Settings
- CSRF vulnerabilities

### DVWA
- SQL Injection
- Cross-Site Scripting
- Command Injection
- File Inclusion

### Altoro Mutual (testfire.net)
- Various SQL injection points
- XSS vulnerabilities
- Session management issues

### Podinfo (Clean App)
- Should have minimal findings
- Only informational/low severity issues expected

## Troubleshooting

### Workflow Fails Immediately
- Check if the PR branch/commit is accessible
- Verify repository secrets are configured
- Check workflow permissions

### ZAP Reports No Vulnerabilities
- Verify target application started correctly
- Check port mappings
- Ensure scan duration was reasonable (>30 seconds)
- Review ZAP logs for connection issues

### Container Issues
- Verify Docker images are accessible
- Check port conflicts
- Ensure healthchecks pass

### Threshold Tests
- Use `continue-on-error: true` for tests expected to fail
- Check workflow conclusion vs outcome
- Validate error messages are clear

## Contributing

When adding new tests:
1. Use existing containers when possible
2. Add entry to `data/test-checklist.csv`
3. Include expected vulnerabilities file if needed
4. Document validation criteria
5. Update this README

## Resources

- [PR #101](https://github.com/huntridge-labs/hardening-workflows/pull/101)
- [OWASP ZAP Documentation](https://www.zaproxy.org/docs/)
- [Juice Shop Vulnerabilities](https://pwning.owasp-juice.shop/)
- [DVWA Documentation](https://github.com/digininja/DVWA)
