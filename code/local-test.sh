#!/bin/bash
# Local ZAP testing script for quick debugging
# This does NOT test the workflow integration - use GitHub Actions for that
# This is useful for rapid iteration and debugging

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCAN_TYPE="${SCAN_TYPE:-baseline}"
TARGET="${TARGET:-juiceshop}"
OUTPUT_DIR="${OUTPUT_DIR:-./local-reports}"
ZAP_IMAGE="ghcr.io/zaproxy/zaproxy:stable"

echo "======================================"
echo "Local ZAP Scanner Test"
echo "======================================"
echo ""
echo "NOTE: This tests ZAP locally, NOT the workflow integration"
echo "      Use GitHub Actions to test PR #101 properly"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to run ZAP scan
run_zap_scan() {
    local target_url=$1
    local scan_type=$2
    local report_name=$3

    echo -e "${YELLOW}Starting $scan_type scan against $target_url${NC}"

    case $scan_type in
        baseline)
            docker run --rm \
                -v "$PWD/$OUTPUT_DIR:/zap/wrk:rw" \
                --network host \
                $ZAP_IMAGE \
                zap-baseline.py \
                -t "$target_url" \
                -r "$report_name.html" \
                -J "$report_name.json" \
                -w "$report_name.md" \
                -I
            ;;
        full)
            docker run --rm \
                -v "$PWD/$OUTPUT_DIR:/zap/wrk:rw" \
                --network host \
                $ZAP_IMAGE \
                zap-full-scan.py \
                -t "$target_url" \
                -r "$report_name.html" \
                -J "$report_name.json" \
                -w "$report_name.md" \
                -I
            ;;
        api)
            docker run --rm \
                -v "$PWD/$OUTPUT_DIR:/zap/wrk:rw" \
                --network host \
                $ZAP_IMAGE \
                zap-api-scan.py \
                -t "$target_url" \
                -f openapi \
                -r "$report_name.html" \
                -J "$report_name.json" \
                -w "$report_name.md" \
                -I
            ;;
        *)
            echo -e "${RED}Unknown scan type: $scan_type${NC}"
            exit 1
            ;;
    esac
}

# Function to start and wait for container
start_container() {
    local container_name=$1
    local image=$2
    local port=$3
    local health_url=$4

    echo -e "${YELLOW}Starting $container_name...${NC}"
    docker run -d --rm \
        --name "$container_name" \
        -p "$port" \
        "$image"

    echo "Waiting for container to be ready..."
    for i in {1..30}; do
        if curl -sf "$health_url" > /dev/null 2>&1; then
            echo -e "${GREEN}Container ready!${NC}"
            return 0
        fi
        echo -n "."
        sleep 2
    done

    echo -e "${RED}Error: Container failed to start${NC}"
    docker logs "$container_name"
    docker stop "$container_name"
    exit 1
}

# Function to stop container
stop_container() {
    local container_name=$1
    echo -e "${YELLOW}Stopping $container_name...${NC}"
    docker stop "$container_name" 2>/dev/null || true
}

# Main test logic
case $TARGET in
    juiceshop)
        CONTAINER_NAME="juiceshop-test"
        TARGET_URL="http://localhost:3000"

        start_container "$CONTAINER_NAME" "bkimminich/juice-shop:latest" "3000:3000" "$TARGET_URL"
        run_zap_scan "$TARGET_URL" "$SCAN_TYPE" "juiceshop-$SCAN_TYPE"
        stop_container "$CONTAINER_NAME"
        ;;

    dvwa)
        CONTAINER_NAME="dvwa-test"
        TARGET_URL="http://localhost:8080"

        start_container "$CONTAINER_NAME" "vulnerables/web-dvwa:latest" "8080:80" "$TARGET_URL"
        run_zap_scan "$TARGET_URL" "$SCAN_TYPE" "dvwa-$SCAN_TYPE"
        stop_container "$CONTAINER_NAME"
        ;;

    podinfo)
        CONTAINER_NAME="podinfo-test"
        TARGET_URL="http://localhost:9898"

        start_container "$CONTAINER_NAME" "ghcr.io/stefanprodan/podinfo:latest" "9898:9898" "$TARGET_URL"
        run_zap_scan "$TARGET_URL" "$SCAN_TYPE" "podinfo-$SCAN_TYPE"
        stop_container "$CONTAINER_NAME"
        ;;

    testfire)
        TARGET_URL="http://demo.testfire.net"
        echo -e "${YELLOW}Testing external target: $TARGET_URL${NC}"
        run_zap_scan "$TARGET_URL" "$SCAN_TYPE" "testfire-$SCAN_TYPE"
        ;;

    *)
        echo -e "${RED}Unknown target: $TARGET${NC}"
        echo "Available targets: juiceshop, dvwa, podinfo, testfire"
        exit 1
        ;;
esac

echo ""
echo "======================================"
echo -e "${GREEN}Scan Complete!${NC}"
echo "======================================"
echo ""
echo "Reports generated in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"
echo ""
echo "View results:"
echo "  HTML: open $OUTPUT_DIR/*-$SCAN_TYPE.html"
echo "  JSON: cat $OUTPUT_DIR/*-$SCAN_TYPE.json"
echo "  Markdown: cat $OUTPUT_DIR/*-$SCAN_TYPE.md"
echo ""
echo "Validate results:"
echo "  .github/scripts/validate-zap-results.sh $OUTPUT_DIR/*-$SCAN_TYPE.json"
echo ""
