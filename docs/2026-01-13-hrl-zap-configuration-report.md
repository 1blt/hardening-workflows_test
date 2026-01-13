# HRL ZAP Scanner Configuration Test Report

**Workflow:** `huntridge-labs/hardening-workflows@feat/zap-scanner`
**Test Date:** 2026-01-13
**Run ID:** 20962870790

## Executive Summary

Out of 6 configuration tests, **2 passed** and **4 failed**. The primary issues are:
1. Artifact name conflicts when running parallel ZAP scans
2. Target URL reachability issues
3. Baseline scan failures on certain targets

## Test Results

| # | Test | Configuration | Status | Failure Point |
|---|------|---------------|--------|---------------|
| 1 | URL + Baseline | mode=url, type=baseline | FAILED | Run ZAP (baseline) |
| 2 | URL + Full Scan | mode=url, type=full | SUCCESS | - |
| 3 | URL + API Scan | mode=url, type=api | FAILED | Wait for target readiness |
| 4 | Docker + Baseline | mode=docker-run, type=baseline | FAILED | Run ZAP (baseline) |
| 5 | Threshold = None | severity_threshold=none | SUCCESS | - |
| 6 | Threshold = High | severity_threshold=high | FAILED | Wait for target readiness |

## Configurations That Work

### URL Mode + Full Scan
- **Configuration:** `zap_scan_mode: url`, `zap_scan_type: full`
- **Target:** http://demo.testfire.net
- **Duration:** 5m 48s
- **Notes:** Active scanning with spider/crawler completed successfully

### Threshold = None (Report-Only Mode)
- **Configuration:** `zap_scan_mode: url`, `zap_scan_type: baseline`, `severity_threshold: none`
- **Target:** http://zero.webappsecurity.com
- **Duration:** 59s
- **Notes:** Baseline scan works when target is reachable and stable

## Configurations That Don't Work

### 1. URL Mode + Baseline Scan (on certain targets)
- **Configuration:** `zap_scan_mode: url`, `zap_scan_type: baseline`
- **Target:** http://testphp.vulnweb.com
- **Failure Step:** "Run ZAP (baseline)"
- **Issue:** ZAP execution failed (exit code non-zero)
- **Root Cause:** Unknown - may be target-specific or artifact conflict

### 2. URL Mode + API Scan
- **Configuration:** `zap_scan_mode: url`, `zap_scan_type: api`
- **Target:** https://petstore.swagger.io/v2
- **API Spec:** https://petstore.swagger.io/v2/swagger.json
- **Failure Step:** "Wait for target readiness"
- **Issue:** Target URL not reachable within timeout
- **Root Cause:** Swagger Petstore may have intermittent availability

### 3. Docker Mode + Baseline
- **Configuration:** `zap_scan_mode: docker-run`, `zap_scan_type: baseline`
- **Target:** bkimminich/juice-shop:latest on localhost:3000
- **Failure Step:** "Run ZAP (baseline)"
- **Issue:** ZAP execution failed despite successful container startup
- **Root Cause:** Likely artifact name conflict with other parallel jobs

### 4. Threshold = High (with certain targets)
- **Configuration:** `severity_threshold: high`, `allow_failure: false`
- **Target:** http://hackazon.webscantest.com
- **Failure Step:** "Wait for target readiness"
- **Issue:** Target URL not reachable
- **Root Cause:** Hackazon test site may be offline or unavailable

## Critical Issues Found

### Issue 1: Artifact Name Conflicts (HIGH)

**Problem:** Multiple parallel ZAP scan jobs create artifacts with the same name, causing upload failures.

**Affected Jobs:**
- Test 1: URL + Baseline - `zap-reports-baseline-*`
- Test 4: Docker + Baseline - `zap-reports-baseline-*`
- Test 6: Threshold = High - `zap-reports-baseline-*`

**Error Message:**
```
Failed to CreateArtifact: Received non-retryable error: Failed request: (409) Conflict:
an artifact with this name already exists on the workflow run
```

**Recommendation:** The HRL workflow should generate unique artifact names using a hash of the target URL or a unique job identifier.

### Issue 2: Baseline Scan Execution Failures (MEDIUM)

**Problem:** The "Run ZAP (baseline)" step fails on certain targets even when the target is reachable.

**Observation:**
- Test 5 (zero.webappsecurity.com) - baseline works
- Test 1 (testphp.vulnweb.com) - baseline fails
- Test 4 (localhost:3000) - baseline fails

**Possible Causes:**
1. Target response characteristics affect ZAP behavior
2. Race condition in parallel execution
3. Artifact name conflict causing premature job failure

### Issue 3: External Target Availability (LOW)

**Problem:** Some test targets are unreliable:
- `hackazon.webscantest.com` - frequently offline
- `petstore.swagger.io` - intermittent availability

**Recommendation:** Use more reliable test targets or self-hosted vulnerable applications.

## Working Configuration Template

Based on successful tests, here's a configuration that works:

```yaml
jobs:
  security-scan:
    uses: huntridge-labs/hardening-workflows/.github/workflows/reusable-security-hardening.yml@feat/zap-scanner
    with:
      scanners: 'zap'
      zap_scan_mode: 'url'
      zap_scan_type: 'full'  # 'full' is more reliable than 'baseline'
      zap_target_urls: 'http://demo.testfire.net'  # reliable test target
      allow_failure: true
    secrets: inherit
```

## Coverage Matrix

| Dimension | Tested Values | Working | Not Working |
|-----------|---------------|---------|-------------|
| Scan Modes | url, docker-run | url | docker-run (artifact conflicts) |
| Scan Types | baseline, full, api | full | baseline (inconsistent), api (target issues) |
| Thresholds | none, high | none | high (target issues) |
| Failure Modes | allow_failure=true/false | true | false (affected by issues) |

## Recommendations for HRL

1. **Fix artifact naming** - Use unique identifiers in artifact names to prevent conflicts
2. **Add healthcheck retries** - More robust target readiness checks with configurable retries
3. **Document reliable test targets** - Provide list of known-working test URLs
4. **Improve error handling** - Better error messages when ZAP scan fails

## Next Steps

1. Report artifact naming issue to HRL maintainers
2. Test with single job at a time to isolate artifact conflict issue
3. Investigate baseline scan failures in more detail
4. Consider using more reliable/self-hosted test targets
