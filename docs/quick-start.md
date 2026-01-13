# Quick Start Guide

Get started testing the ZAP scanner PR in under 5 minutes.

## Prerequisites

- GitHub CLI installed (`gh`)
- Access to this repository
- GitHub Actions enabled

## Step 1: Initialize Repository

```bash
# Initialize git repository
git init
git add .
git commit -m "Initial commit: ZAP scanner test suite"

# Create GitHub repository (replace with your org/repo)
gh repo create hardening_workflows_tester --public --source=. --push
```

## Step 2: Run Your First Test

```bash
# Test ZAP with Juice Shop (comprehensive test)
gh workflow run test-zap-docker-juiceshop.yml

# Monitor the workflow
gh run list

# Watch it live
gh run watch
```

## Step 3: Validate Results

```bash
# Get the latest run ID
RUN_ID=$(gh run list --workflow=test-zap-docker-juiceshop.yml --limit 1 --json databaseId --jq '.[0].databaseId')

# Download artifacts
gh run download $RUN_ID

# Validate results
chmod +x .github/scripts/validate-zap-results.sh
.github/scripts/validate-zap-results.sh \
  zap-report.json \
  .github/scripts/expected-vulnerabilities-juiceshop.txt
```

## Step 4: Run Full Test Suite

```bash
# Run all tests
gh workflow run run-all-tests.yml --field test_suite=all

# Or run specific test groups
gh workflow run run-all-tests.yml --field test_suite=scan-modes
gh workflow run run-all-tests.yml --field test_suite=thresholds
gh workflow run run-all-tests.yml --field test_suite=integration
```

## Step 5: Track Progress

1. Open `data/test-checklist.csv` in Excel/Google Sheets
2. Filter by test category
3. Mark tests as PASS/FAIL/SKIP as you validate
4. Use the Status column to track progress

## Quick Test Matrix

### Fast Tests (< 5 minutes)
- `test-zap-url-mode.yml` - Tests external URL scanning
- `test-zap-docker-podinfo.yml` - Tests with clean app

### Medium Tests (5-15 minutes)
- `test-zap-docker-juiceshop.yml` - Baseline and full scans
- `test-zap-docker-dvwa.yml` - DVWA vulnerability detection

### Comprehensive Tests (15-30 minutes)
- `test-zap-thresholds.yml` - All threshold combinations
- `run-all-tests.yml` - Complete test suite

## Common Commands

```bash
# List all workflows
gh workflow list

# Run a workflow
gh workflow run <workflow-name>

# Check status
gh run list

# View workflow details
gh run view <run-id>

# Download artifacts
gh run download <run-id>

# Watch a running workflow
gh run watch

# View workflow logs
gh run view <run-id> --log
```

## Validation Commands

```bash
# Validate JSON report exists
test -f zap-report.json && echo "✅ Report found" || echo "❌ Report missing"

# Check vulnerability count
jq '.site[0].alerts | length' zap-report.json

# List all vulnerabilities
jq -r '.site[0].alerts[].name' zap-report.json

# Count by severity
jq '[.site[0].alerts[] | select(.riskcode=="3")] | length' zap-report.json  # High
jq '[.site[0].alerts[] | select(.riskcode=="2")] | length' zap-report.json  # Medium
jq '[.site[0].alerts[] | select(.riskcode=="1")] | length' zap-report.json  # Low
```

## What to Look For

### ✅ Good Signs
- Workflow completes successfully
- ZAP report contains vulnerabilities
- Scan duration > 30 seconds (proves it ran)
- Known vulnerabilities are detected
- Severity levels are reasonable

### ❌ Bad Signs
- Workflow fails immediately
- Zero vulnerabilities found
- Scan completes in < 10 seconds
- Container cleanup fails
- Reports are missing or corrupted

## Troubleshooting

### Workflow Won't Start
```bash
# Check if workflow file is valid
gh workflow view test-zap-docker-juiceshop.yml

# Enable workflow if disabled
gh workflow enable test-zap-docker-juiceshop.yml
```

### Can't Download Artifacts
```bash
# Check if run completed
gh run view <run-id>

# List artifacts
gh run view <run-id> --json artifacts

# Wait for completion
gh run watch <run-id>
```

### Validation Script Fails
```bash
# Make script executable
chmod +x .github/scripts/validate-zap-results.sh

# Check if jq is installed
which jq || brew install jq  # macOS
which jq || sudo apt install jq  # Linux

# Run with bash explicitly
bash .github/scripts/validate-zap-results.sh zap-report.json
```

## Next Steps

1. **Review Results**: Check that expected vulnerabilities were found
2. **Test Thresholds**: Verify failure logic works correctly
3. **Test Integration**: Ensure ZAP is opt-in and works with other scanners
4. **Complete Checklist**: Work through data/test-checklist.csv
5. **Document Issues**: Note any problems in the CSV or create GitHub issues

## Need Help?

- Review full documentation: [README.md](../README.md)
- PR Review Guide: [pr-review-guide.md](pr-review-guide.md)
- Test Checklist: [data/test-checklist.csv](../data/test-checklist.csv)
- Original PR: [PR #101](https://github.com/huntridge-labs/hardening-workflows/pull/101)
