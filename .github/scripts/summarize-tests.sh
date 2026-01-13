#!/bin/bash
# Generate a summary of test results for PR review

set -e

echo "======================================"
echo "ZAP Scanner Test Suite Summary"
echo "======================================"
echo ""

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo "ERROR: GitHub CLI (gh) is not installed"
    exit 1
fi

# Get recent workflow runs
echo "Recent Test Runs:"
echo ""
gh run list --limit 10 --json name,status,conclusion,createdAt --jq '.[] | "\(.createdAt | split("T")[0]) - \(.name): \(.conclusion // .status)"'

echo ""
echo "======================================"
echo "Test Coverage by Category"
echo "======================================"
echo ""

# Count tests by category if CSV exists
if [ -f "data/test-checklist.csv" ]; then
    echo "Scan Mode Tests: $(grep -c '^Scan Mode,' data/test-checklist.csv || echo 0)"
    echo "Scan Type Tests: $(grep -c '^Scan Type,' data/test-checklist.csv || echo 0)"
    echo "Threshold Tests: $(grep -c '^Threshold,' data/test-checklist.csv || echo 0)"
    echo "Integration Tests: $(grep -c '^Integration,' data/test-checklist.csv || echo 0)"
    echo "Configuration Tests: $(grep -c '^Configuration,' data/test-checklist.csv || echo 0)"
    echo "Reporting Tests: $(grep -c '^Reporting,' data/test-checklist.csv || echo 0)"
    echo "Error Handling Tests: $(grep -c '^Error Handling,' data/test-checklist.csv || echo 0)"
    echo "Performance Tests: $(grep -c '^Performance,' data/test-checklist.csv || echo 0)"
    echo "Functional Tests: $(grep -c '^Functional,' data/test-checklist.csv || echo 0)"
    echo "Detection Tests: $(grep -c '^Detection,' data/test-checklist.csv || echo 0)"
    echo "Documentation Tests: $(grep -c '^Documentation,' data/test-checklist.csv || echo 0)"
    echo "Validation Tests: $(grep -c '^Validation,' data/test-checklist.csv || echo 0)"
    echo "Security Tests: $(grep -c '^Security,' data/test-checklist.csv || echo 0)"
    echo "Regression Tests: $(grep -c '^Regression,' data/test-checklist.csv || echo 0)"
    echo ""
    echo "Total Tests: $(tail -n +2 data/test-checklist.csv | wc -l | tr -d ' ')"
fi

echo ""
echo "======================================"
echo "Workflow Files Created"
echo "======================================"
echo ""

ls -1 .github/workflows/*.yml | while read -r file; do
    echo "$(basename "$file")"
done

echo ""
echo "======================================"
echo "Available Test Applications"
echo "======================================"
echo ""
echo "OWASP Juice Shop (bkimminich/juice-shop)"
echo "   - Comprehensive vulnerable web app"
echo "   - Tests: XSS, SQLi, CSRF, security headers"
echo ""
echo "DVWA (vulnerables/web-dvwa)"
echo "   - Damn Vulnerable Web Application"
echo "   - Tests: SQLi, XSS, command injection"
echo ""
echo "Podinfo (ghcr.io/stefanprodan/podinfo)"
echo "   - Clean reference application"
echo "   - Tests: Baseline security, minimal findings"
echo ""
echo "Altoro Mutual (demo.testfire.net)"
echo "   - OWASP public test site"
echo "   - Tests: URL mode, external scanning"
echo ""

echo "======================================"
echo "Next Steps"
echo "======================================"
echo ""
echo "1. Run test workflows:"
echo "   gh workflow run test-zap-docker-juiceshop.yml"
echo ""
echo "2. Monitor results:"
echo "   gh run watch"
echo ""
echo "3. Validate findings:"
echo "   .github/scripts/validate-zap-results.sh zap-report.json"
echo ""
echo "4. Track progress:"
echo "   Open data/test-checklist.csv and mark status"
echo ""
echo "5. Review documentation:"
echo "   docs/pr-review-guide.md"
echo ""
