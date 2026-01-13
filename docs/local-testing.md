# Local Testing Guide

This guide covers running ZAP scans locally for quick debugging and iteration.

## ⚠️ Important Note

**Local testing does NOT test the workflow integration.** This is for:
- Quick debugging
- Learning how ZAP works
- Validating container setups
- Rapid iteration

**To test PR #101 properly, you MUST use GitHub Actions** because:
- It tests the actual reusable workflow
- It validates the workflow integration
- It runs in the real GitHub Actions environment

## Prerequisites

- Docker installed and running
- Bash shell (macOS/Linux/WSL)
- 8GB+ RAM (for running multiple containers)

## Quick Start

### Option 1: Simple Script (Recommended)

```bash
# Make script executable
chmod +x code/local-test.sh

# Test Juice Shop with baseline scan
./code/local-test.sh

# Test DVWA with full scan
TARGET=dvwa SCAN_TYPE=full ./code/local-test.sh

# Test Podinfo with baseline scan
TARGET=podinfo ./code/local-test.sh

# Test external site
TARGET=testfire SCAN_TYPE=baseline ./code/local-test.sh
```

### Option 2: Docker Compose (Interactive)

```bash
# Start all services including ZAP UI
docker-compose -f docker-compose.local.yml up -d

# Access ZAP UI
open http://localhost:8080/zap

# Services available at:
# - Juice Shop: http://localhost:3000
# - DVWA: http://localhost:8081
# - Podinfo: http://localhost:9898

# Run scans through ZAP UI or API

# Stop everything
docker-compose -f docker-compose.local.yml down
```

### Option 3: Manual Docker Commands

```bash
# Start target application
docker run -d --name juiceshop -p 3000:3000 bkimminich/juice-shop

# Wait for it to be ready
sleep 30

# Run ZAP scan
docker run --rm \
  -v $(pwd)/local-reports:/zap/wrk:rw \
  --network host \
  ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py \
  -t http://localhost:3000 \
  -r juiceshop-baseline.html \
  -J juiceshop-baseline.json

# Clean up
docker stop juiceshop
docker rm juiceshop
```

## Available Targets

### Juice Shop (Comprehensive)
```bash
TARGET=juiceshop SCAN_TYPE=baseline ./code/local-test.sh
TARGET=juiceshop SCAN_TYPE=full ./code/local-test.sh
TARGET=juiceshop SCAN_TYPE=api ./code/local-test.sh
```

### DVWA (Classic Vulnerabilities)
```bash
TARGET=dvwa SCAN_TYPE=baseline ./code/local-test.sh
TARGET=dvwa SCAN_TYPE=full ./code/local-test.sh
```

### Podinfo (Clean App)
```bash
TARGET=podinfo SCAN_TYPE=baseline ./code/local-test.sh
```

### Testfire (External)
```bash
TARGET=testfire SCAN_TYPE=baseline ./code/local-test.sh
```

## Scan Types

### Baseline (Fast, Passive)
- Duration: 1-5 minutes
- Only passive checks
- Finds: Security headers, info disclosure
- Doesn't find: XSS, SQLi (requires active probing)

```bash
SCAN_TYPE=baseline ./code/local-test.sh
```

### Full (Comprehensive, Active)
- Duration: 10-30 minutes
- Active probing
- Spider/crawler runs
- Finds: XSS, SQLi, command injection, etc.

```bash
SCAN_TYPE=full ./code/local-test.sh
```

### API (OpenAPI/Swagger)
- Duration: 5-15 minutes
- API-focused testing
- Requires OpenAPI spec
- Tests all endpoints

```bash
SCAN_TYPE=api TARGET=juiceshop ./code/local-test.sh
```

## Validating Results

After running a scan:

```bash
# View HTML report
open local-reports/juiceshop-baseline.html

# Check JSON with jq
jq '.site[0].alerts[] | {name, risk: .riskdesc}' local-reports/juiceshop-baseline.json

# Run validation script
.github/scripts/validate-zap-results.sh \
  local-reports/juiceshop-baseline.json \
  .github/scripts/expected-vulnerabilities-juiceshop.txt

# Count vulnerabilities by severity
jq '[.site[0].alerts[] | select(.riskcode=="3")] | length' local-reports/juiceshop-baseline.json  # High
jq '[.site[0].alerts[] | select(.riskcode=="2")] | length' local-reports/juiceshop-baseline.json  # Medium
jq '[.site[0].alerts[] | select(.riskcode=="1")] | length' local-reports/juiceshop-baseline.json  # Low
```

## Expected Results

### Juice Shop - Baseline
Should find:
- Missing security headers (~5-10 findings)
- Cookie issues (~2-3 findings)
- Information disclosure (~3-5 findings)
- Total: 10-20 findings

### Juice Shop - Full
Should find:
- All baseline findings
- SQL Injection (~5-10 findings)
- Cross-Site Scripting (~10-15 findings)
- CSRF vulnerabilities (~2-3 findings)
- Total: 30-50 findings

### DVWA - Full
Should find:
- SQL Injection in login
- XSS vulnerabilities
- Command Injection
- File inclusion issues
- Total: 20-40 findings

### Podinfo - Baseline
Should find:
- Minimal findings (0-5)
- Only informational/low severity
- No high/medium severity issues

### Testfire - Baseline
Should find:
- Known testfire vulnerabilities
- SQL Injection points
- XSS vulnerabilities
- Total: 10-30 findings

## Troubleshooting

### Container Won't Start

```bash
# Check if port is in use
lsof -i :3000

# Stop conflicting container
docker stop juiceshop-test

# Check Docker logs
docker logs juiceshop-test
```

### ZAP Can't Reach Container

```bash
# Verify container is running
docker ps

# Test connectivity
curl http://localhost:3000

# Check if healthcheck passed
docker inspect juiceshop-test | jq '.[0].State.Health'
```

### Scan Finds Nothing

Common causes:
- Container not fully started (wait longer)
- Wrong URL or port
- Network issues (try `--network host`)
- Scan timeout too short

### Permission Denied on Reports

```bash
# Fix permissions on output directory
chmod -R 755 local-reports

# Or run with sudo (not recommended)
sudo ./code/local-test.sh
```

## Advanced Usage

### Custom ZAP Configuration

Create `.zap/rules.tsv`:
```
10011	WARN	(Cross Site Scripting (Reflected))
40012	WARN	(SQL Injection)
```

Run with config:
```bash
docker run --rm \
  -v $(pwd)/local-reports:/zap/wrk:rw \
  -v $(pwd)/.zap:/zap/config:ro \
  --network host \
  ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t http://localhost:3000 -c rules.tsv
```

### Parallel Testing

Test multiple targets simultaneously:
```bash
# Terminal 1
TARGET=juiceshop OUTPUT_DIR=./reports/juice ./code/local-test.sh &

# Terminal 2
TARGET=dvwa OUTPUT_DIR=./reports/dvwa ./code/local-test.sh &

# Terminal 3
TARGET=podinfo OUTPUT_DIR=./reports/podinfo ./code/local-test.sh &

# Wait for all
wait
```

### Authenticated Scanning

For apps requiring authentication:

```bash
# Create context config
cat > .zap/context.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <context>
        <name>Test</name>
        <authentication>
            <type>form</type>
            <loginurl>http://localhost:3000/login</loginurl>
            <loginpageurl>http://localhost:3000/login</loginpageurl>
        </authentication>
    </context>
</configuration>
EOF

# Run with authentication
docker run --rm \
  -v $(pwd)/.zap:/zap/config:ro \
  -v $(pwd)/local-reports:/zap/wrk:rw \
  --network host \
  ghcr.io/zaproxy/zaproxy:stable \
  zap-full-scan.py -t http://localhost:3000 -n context.xml
```

## Comparing Local vs GitHub Actions

| Aspect | Local Testing | GitHub Actions |
|--------|--------------|----------------|
| Tests workflow integration | ❌ No | ✅ Yes |
| Speed | ✅ Fast (seconds to start) | ⏱️ Slower (queue + startup) |
| Cost | ✅ Free (your machine) | ⏱️ Uses Actions minutes |
| Repeatability | ⚠️ Environment dependent | ✅ Consistent environment |
| Debugging | ✅ Easy (logs immediately) | ⏱️ Need to check Actions UI |
| PR Review | ❌ Can't validate PR #101 | ✅ Tests actual PR code |

## Recommended Workflow

1. **Develop locally** - Use local testing to debug and iterate
2. **Validate on GitHub** - Run workflows to test integration
3. **Review results** - Download artifacts and validate locally
4. **Approve PR** - Based on GitHub Actions results, not local

## Example: Full Testing Cycle

```bash
# 1. Quick local test (development)
./code/local-test.sh
# Look at results, iterate

# 2. Test on GitHub (validation)
gh workflow run test-zap-docker-juiceshop.yml

# 3. Download and validate
gh run download <run-id>
.github/scripts/validate-zap-results.sh zap-report.json

# 4. Mark in checklist
# Open data/test-checklist.csv, mark as PASS/FAIL

# 5. If pass, approve PR
# If fail, debug locally and repeat
```

## Cleaning Up

```bash
# Stop all test containers
docker stop juiceshop-test dvwa-test podinfo-test 2>/dev/null || true

# Remove reports
rm -rf local-reports/

# Clean Docker
docker system prune -f

# If using docker-compose
docker-compose -f docker-compose.local.yml down -v
```

## Next Steps

- Run local tests to understand ZAP behavior
- Use GitHub Actions for PR #101 validation
- Compare local vs Actions results
- Document any differences in data/test-checklist.csv
