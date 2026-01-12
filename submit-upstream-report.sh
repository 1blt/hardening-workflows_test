#!/bin/bash
# Script to submit the upstream issues report to PR #101

set -e

REPORT_FILE="UPSTREAM-ISSUES-REPORT.md"
UPSTREAM_REPO="huntridge-labs/hardening-workflows"
PR_NUMBER="101"

echo "========================================="
echo "Upstream Issues Report Submission Tool"
echo "========================================="
echo ""

if [ ! -f "$REPORT_FILE" ]; then
    echo "Error: $REPORT_FILE not found!"
    exit 1
fi

echo "Report file: $REPORT_FILE"
echo "Target: $UPSTREAM_REPO PR #$PR_NUMBER"
echo ""
echo "Choose submission method:"
echo "  1) Post as PR comment (recommended)"
echo "  2) Create as new issue"
echo "  3) View report only"
echo "  4) Copy report to clipboard (requires pbcopy/xclip)"
echo ""
read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo ""
        echo "Posting as comment on PR #$PR_NUMBER..."
        gh pr comment $PR_NUMBER --repo $UPSTREAM_REPO --body-file $REPORT_FILE
        echo ""
        echo "✅ Comment posted successfully!"
        echo "View at: https://github.com/$UPSTREAM_REPO/pull/$PR_NUMBER"
        ;;
    2)
        echo ""
        echo "Creating new issue..."
        gh issue create --repo $UPSTREAM_REPO \
            --title "Testing Report: Issues Found in feat/zap-scanner Branch" \
            --body-file $REPORT_FILE \
            --label "bug,testing"
        echo ""
        echo "✅ Issue created successfully!"
        ;;
    3)
        echo ""
        echo "========================================="
        cat $REPORT_FILE
        echo "========================================="
        ;;
    4)
        if command -v pbcopy &> /dev/null; then
            cat $REPORT_FILE | pbcopy
            echo "✅ Report copied to clipboard (macOS)"
        elif command -v xclip &> /dev/null; then
            cat $REPORT_FILE | xclip -selection clipboard
            echo "✅ Report copied to clipboard (Linux)"
        else
            echo "❌ Clipboard tool not found (pbcopy or xclip required)"
            exit 1
        fi
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Done!"
