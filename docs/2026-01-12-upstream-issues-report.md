# Issues Report: feat/zap-scanner Branch Testing

**Reporter:** Testing Repository (hardening-workflows_test_zap)
**Date:** 2026-01-12
**PR Being Tested:** huntridge-labs/hardening-workflows#101
**Branch:** feat/zap-scanner

## Executive Summary

While testing the `feat/zap-scanner` branch, we encountered several issues that prevent successful workflow execution. This report consolidates findings from multiple test runs across different scan modes and configurations.

## Issues Identified

### 1. Missing Required Permissions Documentation

**Severity:** High
**Status:** Workaround Applied

**Issue:**
The reusable workflow requires specific permissions but this was not documented:
```yaml
permissions:
  actions: read
  checks: write
  pull-requests: write
  security-events: write
  id-token: write
  contents: read
```

**Error Message:**
```
The workflow is requesting 'actions: read, checks: write, pull-requests: write,
security-events: write, id-token: write', but is only allowed 'actions: none,
checks: none, pull-requests: none, security-events: none, id-token: none'
```

**Evidence:**
- [Run #20924327947](https://github.com/1blt/hardening-workflows_test_zap/actions/runs/20924327947) - startup_failure due to missing permissions
- [Run #20923992700](https://github.com/1blt/hardening-workflows_test_zap/actions/runs/20923992700) - Another permissions failure
- [Fix applied in commit 57b9075](https://github.com/1blt/hardening-workflows_test_zap/commit/57b9075) - Added permissions blocks
- [Example fix in workflow file](https://github.com/1blt/hardening-workflows_test_zap/blob/main/.github/workflows/test-zap-docker-juiceshop.yml#L9-L15)

**Recommendation:**
- Add permissions requirements to the PR description and documentation
- Consider adding example workflows that show the required permissions

---

### 2. Script Path/Checkout Configuration Issue

**Severity:** High
**Status:** Unresolved

**Issue:**
The workflow checkout step succeeds, but subsequent steps cannot find the scripts at the expected path. The scripts [exist in the repository](https://github.com/huntridge-labs/hardening-workflows/tree/feat/zap-scanner/.github/scripts) but the path reference is incorrect.

**Error Messages:**
```
chmod: cannot access './.hardening-workflows/.github/scripts/parse-zap-results.sh':
  No such file or directory
chmod: cannot access './.hardening-workflows/.github/scripts/generate-zap-summary.sh':
  No such file or directory
```

**Root Cause Analysis:**
1. "Checkout hardening-workflows scripts" step **succeeds** ✅
2. Scripts [exist in feat/zap-scanner branch](https://github.com/huntridge-labs/hardening-workflows/blob/feat/zap-scanner/.github/scripts/parse-zap-results.sh) ✅
3. But "Generate ZAP summary" step immediately fails looking for them ❌
4. Likely issue: Checkout `path:` parameter doesn't match script path references

**Affected Workflows:**
- All ZAP scan modes (docker-run, compose, url)
- All scan types (baseline, full, api)

**Evidence:**
- [Run #20924879735 job details](https://github.com/1blt/hardening-workflows_test_zap/actions/runs/20924879735) - Shows "Checkout hardening-workflows scripts" succeeds but "Generate ZAP summary" fails
- Scripts confirmed to exist: [parse-zap-results.sh](https://github.com/huntridge-labs/hardening-workflows/blob/feat/zap-scanner/.github/scripts/parse-zap-results.sh), [generate-zap-summary.sh](https://github.com/huntridge-labs/hardening-workflows/blob/feat/zap-scanner/.github/scripts/generate-zap-summary.sh)
- [Workflow file example](https://github.com/1blt/hardening-workflows_test_zap/blob/main/.github/workflows/test-zap-docker-juiceshop.yml#L20) - Calls reusable workflow

**Recommendation:**
- Review checkout action configuration in reusable workflow (verify `path:` parameter)
- Ensure script path references match checkout path (e.g., if checkout uses `path: .hardening-workflows`, scripts should reference `.hardening-workflows/.github/scripts/`)
- Consider using `$GITHUB_ACTION_PATH` or similar to make paths relative to action location
- Add debugging to show where files are actually checked out vs where they're being referenced

---

### 3. ZAP Summary Generation Failure

**Severity:** High
**Status:** Unresolved

**Issue:**
The "Generate ZAP summary" step consistently fails across all test scenarios.

**Error Pattern:**
```
X Generate ZAP summary
  Process completed with exit code 1
```

**Artifact Error:**
```
! No files were found with the provided path: scanner-summaries/zap.md.
  No artifacts will be uploaded.
```

**Affected Runs:**
- [Run #20924879735](https://github.com/1blt/hardening-workflows_test_zap/actions/runs/20924879735) - ZAP Compose Mode
- [Run #20924879669](https://github.com/1blt/hardening-workflows_test_zap/actions/runs/20924879669) - ZAP Docker Mode (Podinfo)
- [Run #20924879693](https://github.com/1blt/hardening-workflows_test_zap/actions/runs/20924879693) - ZAP Docker Mode (DVWA)
- [Run #20924879664](https://github.com/1blt/hardening-workflows_test_zap/actions/runs/20924879664) - ZAP URL Mode
- [Run #20924627094](https://github.com/1blt/hardening-workflows_test_zap/actions/runs/20924627094) - ZAP Docker Mode (Juice Shop)

**Failed Job Step:**
`ZAP (DAST) Scanner / ZAP Summary` → `Generate ZAP summary`

**Observations:**
- ZAP scans complete successfully (vulnerabilities detected)
- JSON reports appear to be generated
- Summary markdown file is not created
- Likely related to missing `generate-zap-summary.sh` script

**Evidence:**
- Failed job step visible in all runs above (expand "ZAP (DAST) Scanner" → "ZAP Summary" → "Generate ZAP summary")
- [All workflow runs](https://github.com/1blt/hardening-workflows_test_zap/actions) show same failure pattern
- Artifact upload warnings confirm missing `scanner-summaries/zap.md`

**Recommendation:**
- Debug the summary generation script
- Check if the script is reading from the correct path
- Verify the script has proper error handling
- Consider making summary generation non-blocking

---

### 4. Artifact Naming Conflicts (Resolved in Testing Repo)

**Severity:** Medium
**Status:** Workaround Applied

**Issue:**
When multiple jobs in the same workflow call the reusable workflow, they attempt to upload artifacts with identical names, causing conflicts.

**Error Message:**
```
Error: Failed to CreateArtifact: Received non-retryable error: Failed request:
(409) Conflict: an artifact with this name already exists on the workflow run
```

**Workaround Applied:**
Made jobs sequential using `needs:` dependencies to prevent parallel artifact uploads.

**Evidence:**
- [Background task output](https://github.com/1blt/hardening-workflows_test_zap/actions/runs/20924627094) showing artifact conflict
- Affected workflows with multiple jobs:
  - [test-zap-docker-juiceshop.yml](https://github.com/1blt/hardening-workflows_test_zap/blob/main/.github/workflows/test-zap-docker-juiceshop.yml#L18-L56) - 3 jobs (baseline, full, api)
  - [test-zap-docker-dvwa.yml](https://github.com/1blt/hardening-workflows_test_zap/blob/main/.github/workflows/test-zap-docker-dvwa.yml#L18-L42) - 2 jobs (baseline, full)
  - [test-zap-thresholds.yml](https://github.com/1blt/hardening-workflows_test_zap/blob/main/.github/workflows/test-zap-thresholds.yml#L18-L90) - 5 jobs (thresholds)
  - [test-zap-url-mode.yml](https://github.com/1blt/hardening-workflows_test_zap/blob/main/.github/workflows/test-zap-url-mode.yml#L18-L38) - 2 jobs (baseline, full)
- [Fix applied: Sequential dependencies](https://github.com/1blt/hardening-workflows_test_zap/blob/main/.github/workflows/test-zap-docker-juiceshop.yml#L32) - Using `needs:`

**Better Solution:**
Consider adding an optional input parameter (e.g., `artifact_suffix` or `job_id`) to differentiate artifacts when multiple scans run in the same workflow.

---

## Suggestions for Improvement

### Documentation Enhancement: ZAP Input Parameters

While testing, we found that some ZAP-specific parameters weren't immediately discoverable without reading the workflow source code. This led to initial test configurations that didn't fully utilize available features.

**Example:**
The `zap_failure_threshold` parameter wasn't clearly documented in the PR or workflow documentation, leading to our initial threshold tests not actually testing threshold behavior. We had to read the workflow source code to discover it.

**Evidence from Upstream Repository:**
- [PR #101 description](https://github.com/huntridge-labs/hardening-workflows/pull/101) - Does not document ZAP-specific parameters like `zap_failure_threshold`
- [Reusable workflow file](https://github.com/huntridge-labs/hardening-workflows/blob/feat/zap-scanner/.github/workflows/reusable-security-hardening.yml) - Parameter exists in workflow but lacks user-facing documentation
- Testing impact: [Our initial commit](https://github.com/1blt/hardening-workflows_test_zap/commit/1aea429) created threshold tests without the parameter because it wasn't discoverable
- [Corrected implementation](https://github.com/1blt/hardening-workflows_test_zap/blob/main/.github/workflows/test-zap-thresholds.yml#L28) shows proper usage once we found it in the source

**Suggestion:**
- Add comprehensive documentation for all ZAP-specific input parameters in the PR description or README
- Include examples showing different configurations (scan modes, scan types, thresholds)
- Consider adding a table of all ZAP parameters with descriptions and default values
- Provide example workflow snippets for common use cases

---

## Test Configuration Used

### Test Workflows Created
1. [test-zap-docker-juiceshop.yml](https://github.com/1blt/hardening-workflows_test_zap/blob/main/.github/workflows/test-zap-docker-juiceshop.yml) - 3 scan types (baseline, full, api)
2. [test-zap-docker-dvwa.yml](https://github.com/1blt/hardening-workflows_test_zap/blob/main/.github/workflows/test-zap-docker-dvwa.yml) - 2 scan types (baseline, full)
3. [test-zap-docker-podinfo.yml](https://github.com/1blt/hardening-workflows_test_zap/blob/main/.github/workflows/test-zap-docker-podinfo.yml) - baseline scan (clean app)
4. [test-zap-url-mode.yml](https://github.com/1blt/hardening-workflows_test_zap/blob/main/.github/workflows/test-zap-url-mode.yml) - external URL scanning
5. [test-zap-compose-mode.yml](https://github.com/1blt/hardening-workflows_test_zap/blob/main/.github/workflows/test-zap-compose-mode.yml) - multi-container testing
6. [test-zap-thresholds.yml](https://github.com/1blt/hardening-workflows_test_zap/blob/main/.github/workflows/test-zap-thresholds.yml) - threshold testing (5 levels)
7. [test-zap-integration.yml](https://github.com/1blt/hardening-workflows_test_zap/blob/main/.github/workflows/test-zap-integration.yml) - integration with other scanners

### Test Targets
- **OWASP Juice Shop** - Comprehensive vulnerable app
- **DVWA** - Classic vulnerability testbed
- **Podinfo** - Clean reference app
- **Altoro Mutual (testfire.net)** - Public test site

### Scan Modes Tested
- ✅ `docker-run` - Single container scan
- ✅ `compose` - Multi-container scan
- ✅ `url` - External URL scan

### Scan Types Tested
- ✅ `baseline` - Quick passive scan
- ✅ `full` - Active scan with spidering
- ✅ `api` - API specification scan

---

## Successful Aspects

Despite the issues above, several components work correctly:

✅ **ZAP Scanning:** Scans execute and detect vulnerabilities
✅ **Scan Coordinator:** Properly orchestrates ZAP jobs
✅ **Vulnerability Detection:** Finds expected vulnerabilities in test apps
✅ **Multiple Scan Modes:** docker-run, compose, and url modes all initiate properly

**Example Success Output:**
```
FAIL-NEW: 0  FAIL-INPROG: 0  WARN-NEW: 16  WARN-INPROG: 0  INFO: 0
IGNORE: 0  PASS: 51
Scanning process completed, starting to analyze the results!
```

---

## Reproduction Steps

1. Fork or clone hardening-workflows_test_zaper repository
2. Reference `feat/zap-scanner` branch in workflow files:
   ```yaml
   uses: huntridge-labs/hardening-workflows/.github/workflows/reusable-security-hardening.yml@feat/zap-scanner
   ```
3. Add required permissions block
4. Run any ZAP test workflow
5. Observe failure at "Generate ZAP summary" step

---

## Recommendations for PR #101

### Critical (Must Fix)
1. ✅ Ensure `parse-zap-results.sh` and `generate-zap-summary.sh` exist and are accessible
2. ✅ Fix ZAP summary generation to create `scanner-summaries/zap.md`
3. ✅ Document required permissions in PR description and README

### Important (Should Fix)
4. ✅ Add artifact naming differentiation for multiple parallel jobs
5. ✅ Improve error handling in summary generation (fail gracefully)
6. ✅ Add comprehensive input parameter documentation

### Nice to Have
7. ✅ Add example workflows showing different configurations
8. ✅ Add troubleshooting section to documentation
9. ✅ Consider making summary generation optional/non-blocking

---

## Additional Context

**Testing Repository:** https://github.com/1blt/hardening-workflows_test_zap
**Example Failed Run:** https://github.com/1blt/hardening-workflows_test_zap/actions/runs/20924879735

**Configuration Applied:**
- [Added all required permissions](https://github.com/1blt/hardening-workflows_test_zap/blob/main/.github/workflows/test-zap-docker-juiceshop.yml#L9-L15)
- [Added threshold parameters](https://github.com/1blt/hardening-workflows_test_zap/blob/main/.github/workflows/test-zap-thresholds.yml#L28)
- [Made multi-job workflows sequential](https://github.com/1blt/hardening-workflows_test_zap/blob/main/.github/workflows/test-zap-docker-juiceshop.yml#L32) to avoid artifact conflicts
- [Updated to use feat/zap-scanner branch](https://github.com/1blt/hardening-workflows_test_zap/blob/main/.github/workflows/test-zap-docker-juiceshop.yml#L20)
- Tested across [7 different workflow configurations](https://github.com/1blt/hardening-workflows_test_zap/tree/main/.github/workflows)

---

## Contact

For questions about this report or to request additional test scenarios, please comment on PR #101 or create an issue in the testing repository.
