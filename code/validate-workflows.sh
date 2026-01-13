#!/bin/bash
# Validate GitHub Actions workflows locally before committing

echo "Validating GitHub Actions workflows..."
echo ""

# Check if actionlint is installed
if ! command -v actionlint &> /dev/null; then
    echo "Error: actionlint is not installed"
    echo "Install with: brew install actionlint"
    exit 1
fi

# Parse options
SHOW_SHELLCHECK=false
if [ "$1" = "--all" ] || [ "$1" = "-a" ]; then
    SHOW_SHELLCHECK=true
    shift
fi

# Validate all workflows
if [ -n "$1" ]; then
    # Validate specific workflow
    echo "Validating: $1"
    if [ "$SHOW_SHELLCHECK" = true ]; then
        actionlint "$1"
    else
        actionlint -ignore 'SC[0-9]+:' "$1" && echo "No critical errors"
    fi
else
    # Validate all workflows
    has_errors=false
    for workflow in .github/workflows/*.yml; do
        echo "Validating: $workflow"
        if [ "$SHOW_SHELLCHECK" = true ]; then
            actionlint "$workflow" || has_errors=true
        else
            actionlint -ignore 'SC[0-9]+:' "$workflow" || has_errors=true
        fi
        echo ""
    done

    if [ "$has_errors" = false ]; then
        echo "All workflows valid!"
    else
        echo "Error: Some workflows have errors"
        exit 1
    fi
fi
