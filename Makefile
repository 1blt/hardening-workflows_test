.PHONY: help setup test-local test-github validate clean

help:
	@echo "ZAP Scanner Test Suite"
	@echo "======================"
	@echo ""
	@echo "Available commands:"
	@echo "  make setup          - Make scripts executable and create directories"
	@echo "  make test-local     - Run local ZAP tests (quick debugging)"
	@echo "  make test-github    - Trigger GitHub Actions tests"
	@echo "  make validate       - Validate latest test results"
	@echo "  make clean          - Clean up local reports and containers"
	@echo "  make summary        - Show test suite summary"
	@echo ""
	@echo "Local testing (quick):"
	@echo "  make test-juiceshop       - Test Juice Shop locally"
	@echo "  make test-dvwa            - Test DVWA locally"
	@echo "  make test-podinfo         - Test Podinfo locally"
	@echo "  make test-testfire        - Test external target"
	@echo ""
	@echo "GitHub Actions (validates PR #101):"
	@echo "  make github-juiceshop     - Run Juice Shop workflow"
	@echo "  make github-all           - Run all workflows"
	@echo "  make github-watch         - Watch latest workflow run"
	@echo ""

setup:
	@echo "Setting up test environment..."
	chmod +x code/*.sh
	chmod +x .github/scripts/*.sh
	mkdir -p local-reports
	@echo "Setup complete!"

# Local testing targets
test-local:
	./code/local-test.sh

test-juiceshop:
	@echo "Testing Juice Shop locally..."
	TARGET=juiceshop SCAN_TYPE=baseline ./code/local-test.sh

test-juiceshop-full:
	@echo "Full scan of Juice Shop (this takes ~15 min)..."
	TARGET=juiceshop SCAN_TYPE=full ./code/local-test.sh

test-dvwa:
	@echo "Testing DVWA locally..."
	TARGET=dvwa SCAN_TYPE=baseline ./code/local-test.sh

test-podinfo:
	@echo "Testing Podinfo locally..."
	TARGET=podinfo SCAN_TYPE=baseline ./code/local-test.sh

test-testfire:
	@echo "Testing external target (testfire.net)..."
	TARGET=testfire SCAN_TYPE=baseline ./code/local-test.sh

# GitHub Actions targets
test-github:
	@echo "Triggering GitHub Actions tests..."
	gh workflow run test-zap-docker-juiceshop.yml
	gh workflow run test-zap-docker-dvwa.yml
	gh workflow run test-zap-url-mode.yml
	@echo "✅ Workflows triggered. Use 'make github-watch' to monitor"

github-juiceshop:
	gh workflow run test-zap-docker-juiceshop.yml
	@echo "✅ Workflow triggered. Use 'make github-watch' to monitor"

github-dvwa:
	gh workflow run test-zap-docker-dvwa.yml
	@echo "✅ Workflow triggered"

github-url:
	gh workflow run test-zap-url-mode.yml
	@echo "✅ Workflow triggered"

github-thresholds:
	gh workflow run test-zap-thresholds.yml
	@echo "✅ Workflow triggered"

github-integration:
	gh workflow run test-zap-integration.yml
	@echo "✅ Workflow triggered"

github-all:
	gh workflow run run-all-tests.yml --field test_suite=all
	@echo "✅ Full test suite triggered"

github-watch:
	gh run watch

github-list:
	gh run list --limit 20

# Validation targets
validate:
	@echo "Validating latest test results..."
	@if [ -f local-reports/*.json ]; then \
		.github/scripts/validate-zap-results.sh local-reports/*.json; \
	else \
		echo "❌ No reports found. Run 'make test-local' first"; \
	fi

validate-github:
	@echo "Download artifacts first with: gh run download <run-id>"
	@echo "Then run: make validate"

summary:
	@chmod +x .github/scripts/summarize-tests.sh
	@.github/scripts/summarize-tests.sh

# Docker Compose targets
compose-up:
	docker-compose -f docker-compose.local.yml up -d
	@echo "✅ Services started:"
	@echo "   ZAP UI: http://localhost:8080/zap"
	@echo "   Juice Shop: http://localhost:3000"
	@echo "   DVWA: http://localhost:8081"
	@echo "   Podinfo: http://localhost:9898"

compose-down:
	docker-compose -f docker-compose.local.yml down

compose-logs:
	docker-compose -f docker-compose.local.yml logs -f

# Cleanup targets
clean:
	@echo "Cleaning up..."
	rm -rf local-reports/*.html local-reports/*.json local-reports/*.md local-reports/*.xml
	docker stop juiceshop-test dvwa-test podinfo-test 2>/dev/null || true
	@echo "✅ Cleanup complete"

clean-all:
	@echo "Deep cleaning..."
	rm -rf local-reports/
	docker-compose -f docker-compose.local.yml down -v
	docker system prune -f
	@echo "✅ Deep cleanup complete"

# View reports
view-reports:
	@echo "HTML Reports:"
	@ls -lh local-reports/*.html 2>/dev/null || echo "No HTML reports found"

open-report:
	@LATEST=$$(ls -t local-reports/*.html 2>/dev/null | head -1); \
	if [ -n "$$LATEST" ]; then \
		echo "Opening $$LATEST"; \
		open "$$LATEST" || xdg-open "$$LATEST"; \
	else \
		echo "❌ No reports found"; \
	fi

# Checklist management
checklist:
	@if command -v open >/dev/null 2>&1; then \
		open data/test-checklist.csv; \
	elif command -v xdg-open >/dev/null 2>&1; then \
		xdg-open data/test-checklist.csv; \
	else \
		echo "Open data/test-checklist.csv in your spreadsheet application"; \
	fi

# Documentation
docs:
	@echo "Available documentation:"
	@echo "  - README.md"
	@echo "  - docs/quick-start.md"
	@echo "  - docs/local-testing.md"
	@echo "  - docs/pr-review-guide.md"

docs-local:
	@cat docs/local-testing.md | less

docs-review:
	@cat docs/pr-review-guide.md | less
