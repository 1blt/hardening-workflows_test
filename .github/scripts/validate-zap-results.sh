#!/bin/bash
set -e

# Validate ZAP scan results
# Usage: ./validate-zap-results.sh <report.json> <expected_vulnerabilities_file>

REPORT_FILE="${1:-zap-report.json}"
EXPECTED_FILE="${2:-expected-vulnerabilities.txt}"

echo "==================================="
echo "ZAP Scan Results Validation"
echo "==================================="
echo ""

# Check if report exists
if [ ! -f "$REPORT_FILE" ]; then
    echo "ERROR: Report file not found: $REPORT_FILE"
    exit 1
fi

# Parse vulnerability counts
HIGH_COUNT=$(jq '[.site[0].alerts[] | select(.riskcode=="3")] | length' "$REPORT_FILE")
MEDIUM_COUNT=$(jq '[.site[0].alerts[] | select(.riskcode=="2")] | length' "$REPORT_FILE")
LOW_COUNT=$(jq '[.site[0].alerts[] | select(.riskcode=="1")] | length' "$REPORT_FILE")
INFO_COUNT=$(jq '[.site[0].alerts[] | select(.riskcode=="0")] | length' "$REPORT_FILE")
TOTAL_COUNT=$((HIGH_COUNT + MEDIUM_COUNT + LOW_COUNT + INFO_COUNT))

echo "Vulnerability Counts:"
echo "   High: $HIGH_COUNT"
echo "   Medium: $MEDIUM_COUNT"
echo "   Low: $LOW_COUNT"
echo "   Informational: $INFO_COUNT"
echo "   Total: $TOTAL_COUNT"
echo ""

# Check if any vulnerabilities were found
if [ "$TOTAL_COUNT" -eq 0 ]; then
    echo "WARNING: No vulnerabilities found. This may indicate scan didn't run properly."
    exit 1
fi

# List all found vulnerabilities
echo "Vulnerabilities Found:"
jq -r '.site[0].alerts[] | "   - \(.name) (Risk: \(.riskdesc | split(" ")[0]))"' "$REPORT_FILE"
echo ""

# Check for expected vulnerabilities if file provided
if [ -f "$EXPECTED_FILE" ]; then
    echo "Checking for expected vulnerabilities..."

    MISSING_VULNS=0
    while IFS= read -r expected_vuln; do
        # Skip empty lines and comments
        [[ -z "$expected_vuln" || "$expected_vuln" =~ ^# ]] && continue

        if jq -e ".site[0].alerts[] | select(.name | test(\"$expected_vuln\"; \"i\"))" "$REPORT_FILE" > /dev/null; then
            echo "   Found: $expected_vuln"
        else
            echo "   Missing: $expected_vuln"
            MISSING_VULNS=$((MISSING_VULNS + 1))
        fi
    done < "$EXPECTED_FILE"

    if [ "$MISSING_VULNS" -gt 0 ]; then
        echo ""
        echo "VALIDATION FAILED: $MISSING_VULNS expected vulnerabilities not found"
        exit 1
    fi
fi

echo ""
echo "Validation passed!"
echo "==================================="
exit 0
