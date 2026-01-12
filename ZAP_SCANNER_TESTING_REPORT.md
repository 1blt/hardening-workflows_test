# ZAP Scanner Testing Report
**Branch Tested:** huntridge-labs/hardening-workflows@feat/zap-scanner
**PR:** huntridge-labs/hardening-workflows#101
**Test Repository:** [1blt/hardening-workflows_test_zap](https://github.com/1blt/hardening-workflows_test_zap/)
**Demonstration Fork:** [1blt/hardening-workflows@feat/zap-scanner-fixes-250112](https://github.com/1blt/hardening-workflows/tree/feat/zap-scanner-fixes-250112)
**Date:** 2026-01-12

---

## Summary

Testing revealed **3 critical issues** that must be fixed before merging PR #101. A working demonstration is available in the fork above.

**Status:** BLOCKED - Critical chmod bug prevents execution
**Test Coverage:** URL scanning, Docker scanning, severity thresholds

---

## Issue 1: Script Path chmod Failure (CRITICAL)

**Severity:** CRITICAL - Blocks all ZAP scanner execution
**File:** `.github/workflows/scanner-zap.yml`

### Problem
The workflow attempts to chmod scripts without checking if they exist, causing immediate failure when running from forks.

### Error
```
chmod: cannot access './.hardening-workflows/.github/scripts/parse-zap-results.sh': No such file or directory
Error: Process completed with exit code 1
```

### Root Cause
- Line 768: chmod runs unconditionally
- Lines 775, 781: Repository checks only match `huntridge-labs/hardening-workflows`, not forks like `1blt/hardening-workflows`

### Fix Required

**Location:** `.github/workflows/scanner-zap.yml` line ~768

**Current code:**
```bash
chmod +x "$ZAP_PARSER" "$SUMMARY_SCRIPT"
```

**Replace with:**
```bash
# Only chmod if files exist
if [[ -f "$ZAP_PARSER" ]] && [[ -f "$SUMMARY_SCRIPT" ]]; then
  chmod +x "$ZAP_PARSER" "$SUMMARY_SCRIPT"
else
  echo "Error: Required scripts not found:"
  echo "  ZAP_PARSER: $ZAP_PARSER (exists: $(test -f "$ZAP_PARSER" && echo yes || echo no))"
  echo "  SUMMARY_SCRIPT: $SUMMARY_SCRIPT (exists: $(test -f "$SUMMARY_SCRIPT" && echo yes || echo no))"
  ls -la .github/scripts/ 2>/dev/null || echo ".github/scripts/ not found"
  ls -la .hardening-workflows/.github/scripts/ 2>/dev/null || echo ".hardening-workflows/.github/scripts/ not found"
  exit 1
fi
```

**Also update repository checks:**

Line ~775:
```yaml
# Current
ZAP_PARSER: ${{ github.repository == 'huntridge-labs/hardening-workflows' && './.github/scripts/parse-zap-results.sh' || './.hardening-workflows/.github/scripts/parse-zap-results.sh' }}

# Fixed - match any hardening-workflows repository
ZAP_PARSER: ${{ endsWith(github.repository, '/hardening-workflows') && './.github/scripts/parse-zap-results.sh' || './.hardening-workflows/.github/scripts/parse-zap-results.sh' }}
```

Line ~781:
```bash
# Current
if [[ "${{ github.repository }}" == "huntridge-labs/hardening-workflows" ]]; then

# Fixed - match any hardening-workflows repository
if [[ "${{ github.repository }}" == *"/hardening-workflows" ]]; then
```

**Demonstration:** [Commit 194d0dd](https://github.com/1blt/hardening-workflows/commit/194d0dd)

---

## Issue 2: Missing Permissions Documentation (HIGH)

**Severity:** HIGH - Causes immediate workflow failure
**Impact:** Poor user experience, unclear error messages

### Problem
The reusable workflow requires specific permissions that are not documented in:
- PR description
- README.md
- Example workflows

### Error Users See
```
The workflow is requesting 'actions: read, checks: write, pull-requests: write,
security-events: write, id-token: write', but is only allowed 'actions: none,
checks: none, pull-requests: none, security-events: none, id-token: none'
```

### Fix Required

Add this permissions block to **all documentation and examples**:

```yaml
permissions:
  actions: read          # Read workflow artifacts
  checks: write          # Create check runs for findings
  pull-requests: write   # Comment on PRs with results
  security-events: write # Upload to GitHub Security tab
  id-token: write        # OIDC token for authentication
  contents: read         # Read repository contents
```

**Action Items:**
1. Add permissions section to PR #101 description
2. Update README.md with "Required Permissions" section
3. Include in all example workflows
4. Add troubleshooting note for this error

---

## Issue 3: Summary Output Improvements (MEDIUM)

**Severity:** MEDIUM - Usability and tracking enhancements
**Files:** `.github/scripts/generate-zap-summary.sh`

### Problem A: Emojis in Output
Summary uses emojis throughout, which:
- Look unprofessional in screenshots/reports
- May not render correctly in all tools
- Make output harder to parse programmatically

**Examples:** Headers use spider/chart emojis, severity uses colored circles, status uses checkmarks

**Fix:** Remove all emojis - use clean text labels instead

### Problem B: No Regression Tracking
Tables only show current findings, making it impossible to:
- Track changes between scans
- Identify new vulnerabilities
- Validate expected baselines

**Current format:**
```markdown
| Critical | High | Medium | Low | Total |
|----------|------|--------|-----|-------|
| 0 | 3 | 8 | 5 | 16 |
```

**Recommended format:**
```markdown
|             | Critical | High | Medium | Low | Total |
|-------------|----------|------|--------|-----|-------|
| Found       | 0 | 3 | 8 | 5 | 16 |
| Expected    | 0 | 0 | 0 | 0 | 0 |
| Difference  | 0 | +3 | +8 | +5 | +16 |
```

### Fix Required

**Location:** `.github/scripts/generate-zap-summary.sh` lines 159-182

Add baseline tracking variables:
```bash
# Expected values (baseline - set to 0 for now, can be customized per target)
EXP_CRIT=0; EXP_HIGH=0; EXP_MED=0; EXP_LOW=0
EXP_TOTAL=0

# Calculate differences
DIFF_CRIT=$((TOTAL_CRIT - EXP_CRIT))
DIFF_HIGH=$((TOTAL_HIGH - EXP_HIGH))
DIFF_MED=$((TOTAL_MED - EXP_MED))
DIFF_LOW=$((TOTAL_LOW - EXP_LOW))
DIFF_TOTAL=$((TOTAL - EXP_TOTAL))
```

Update table generation:
```bash
cat >> "$output" << EOF
### Overall Findings Summary

|             | Critical | High | Medium | Low | Total |
|-------------|----------|------|--------|-----|-------|
| **Found**   | $TOTAL_CRIT | $TOTAL_HIGH | $TOTAL_MED | $TOTAL_LOW | $TOTAL |
| **Expected** | $EXP_CRIT | $EXP_HIGH | $EXP_MED | $EXP_LOW | $EXP_TOTAL |
| **Difference** | $DIFF_CRIT | $DIFF_HIGH | $DIFF_MED | $DIFF_LOW | $DIFF_TOTAL |
EOF
```

Also remove all emoji variables and replace in output (search for emoji unicode characters and replace with text).

**Demonstration:** [Commit 4be01a8](https://github.com/1blt/hardening-workflows/commit/4be01a8)
**Visual Comparison:** [Format comparison doc](https://github.com/1blt/hardening-workflows_test_zap/blob/main/SUMMARY_FORMAT_COMPARISON.md)

---

## Recommended Actions

### Must Fix (Critical Path)
1. Apply Issue #1 fix to `scanner-zap.yml` - **BLOCKS ALL TESTING**
2. Document permissions (Issue #2) in PR description and README

### Should Fix (Quality)
3. Apply Issue #3 fixes to `generate-zap-summary.sh` for better UX

### How to Apply

**Option 1 - Cherry-pick from demonstration:**
```bash
git remote add demo https://github.com/1blt/hardening-workflows.git
git fetch demo
git cherry-pick 194d0dd  # chmod fix
git cherry-pick 4be01a8  # summary improvements
```

**Option 2 - Reference fixed fork for testing:**
```yaml
uses: 1blt/hardening-workflows/.github/workflows/reusable-security-hardening.yml@feat/zap-scanner-fixes-250112
```

---

## What Works Well

Once the chmod bug is fixed:
- ZAP scanning successfully detects vulnerabilities
- Multiple scan modes work (url, docker-run, compose)
- Multiple scan types work (baseline, full, api)
- Severity thresholds function correctly
- Parallel scan orchestration works
- JSON report parsing is accurate

---

## Test Evidence

**Test repository:** https://github.com/1blt/hardening-workflows_test_zap
**Successful runs:** Using demonstration fork with all fixes applied
**Test targets:** OWASP Juice Shop, demo.testfire.net, testphp.vulnweb.com
