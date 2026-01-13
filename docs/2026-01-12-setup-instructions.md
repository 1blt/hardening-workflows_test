# Setup Instructions - Get Tests Running

## Current Status

✅ All test files are created locally
❌ Not yet pushed to GitHub (workflows can't run yet)

## Steps to Get Tests Running

### Step 1: Initialize Git Repository

```bash
cd /Users/loremipsum/Documents/HuntHub/hardening_workflows_tester

# Initialize git
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: ZAP scanner test suite for PR #101"
```

### Step 2: Create GitHub Repository

**Option A: Using GitHub CLI (Recommended)**
```bash
# Create and push in one command
gh repo create hardening_workflows_tester \
  --public \
  --source=. \
  --push \
  --description="Test suite for huntridge-labs/hardening-workflows PR #101"
```

**Option B: Using GitHub Web UI**
1. Go to https://github.com/new
2. Repository name: `hardening_workflows_tester`
3. Make it public
4. Don't initialize with README (we already have files)
5. Click "Create repository"

Then push:
```bash
git remote add origin https://github.com/YOUR-USERNAME/hardening_workflows_tester.git
git branch -M main
git push -u origin main
```

### Step 3: Verify Workflows Are Detected

```bash
# List workflows (should show 8 workflows)
gh workflow list
```

Expected output:
```
Test ZAP - Compose Mode (Multi-Container)        active  12345
Test ZAP - Docker Mode (DVWA)                   active  12346
Test ZAP - Docker Mode (Juice Shop)             active  12347
Test ZAP - Docker Mode (Podinfo - Clean App)    active  12348
Test ZAP - Failure Thresholds                   active  12349
Test ZAP - Integration with Other Scanners      active  12350
Test ZAP - URL Mode (External Target)           active  12351
Run All ZAP Tests                               active  12352
```

### Step 4: Run Your First Test

```bash
# Test with Juice Shop (comprehensive test)
gh workflow run test-zap-docker-juiceshop.yml

# Watch it run
gh run watch
```

Or use the Makefile:
```bash
make github-juiceshop
make github-watch
```

### Step 5: Verify It's Actually Running

```bash
# Check recent runs
gh run list

# View a specific run
gh run view <run-id>

# See live logs
gh run view <run-id> --log
```

## What Gets Tested

When you run a workflow, it will:

1. ✅ Call the reusable workflow from PR #101 commit `79dbc29`
2. ✅ Start the target container (Juice Shop, DVWA, etc.)
3. ✅ Run ZAP scanner against it
4. ✅ Generate reports (HTML, JSON, MD)
5. ✅ Upload artifacts
6. ✅ Create GitHub summary

## Troubleshooting

### "workflow not found"

The repository doesn't exist yet or workflows aren't pushed.

**Solution:**
```bash
git push origin main
gh workflow list  # Verify they appear
```

### "requires authorization"

The hardening-workflows repository might be private or the workflow reference is incorrect.

**Solution:** The workflow uses a specific commit hash that's publicly accessible. This should work. If not, you may need to:
- Fork huntridge-labs/hardening-workflows
- Update workflow files to point to your fork

### "No workflows found"

Workflows aren't in the right location.

**Solution:**
```bash
# Verify workflow files exist
ls -la .github/workflows/

# They should all be .yml files in .github/workflows/
```

### Workflows aren't triggering

Check if workflows are enabled.

**Solution:**
```bash
# Enable all workflows
gh workflow enable test-zap-docker-juiceshop.yml
gh workflow enable test-zap-docker-dvwa.yml
# ... etc
```

## Quick Test Sequence

```bash
# 1. Initialize and push
git init
git add .
git commit -m "Initial commit"
gh repo create hardening_workflows_tester --public --source=. --push

# 2. Verify workflows
gh workflow list

# 3. Run a quick test
gh workflow run test-zap-docker-podinfo.yml

# 4. Watch it
gh run watch

# 5. After completion, download results
gh run list
gh run download <run-id>

# 6. Validate
.github/scripts/validate-zap-results.sh zap-report.json
```

## Expected Timeline

- **Setup**: 2-3 minutes (git init, push)
- **First workflow start**: 30 seconds - 2 minutes (queue time)
- **Podinfo test**: 5-10 minutes (fastest)
- **Juice Shop baseline**: 10-15 minutes
- **Juice Shop full scan**: 20-30 minutes

## What You'll See

In GitHub Actions UI, you'll see:
- Workflow starts
- Sets up ZAP scanner
- Starts target container
- Runs scan
- Generates reports
- Uploads artifacts
- Shows summary with vulnerability counts

## Next Steps After Tests Run

1. Download artifacts: `gh run download <run-id>`
2. Validate results: `.github/scripts/validate-zap-results.sh zap-report.json`
3. Open checklist: `open test-checklist.csv`
4. Mark test as PASS/FAIL
5. Run more tests
6. Complete the full test suite

## Need Help?

Check if you're in the right directory:
```bash
pwd
# Should be: /Users/loremipsum/Documents/HuntHub/hardening_workflows_tester

ls -la .github/workflows/
# Should show 8 .yml files
```

Verify GitHub CLI is working:
```bash
gh auth status
# Should show you're logged in
```
