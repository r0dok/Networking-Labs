#!/bin/bash
# Network Connectivity Testing Script
# Tests all 200 VLAN gateways

# Configuration
START_VLAN=2
END_VLAN=201
SUBNET_SIZE=16
PING_COUNT=3
TIMEOUT=1

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
total=0
success=0
failed=0

echo "=========================================="
echo "  VLAN Connectivity Test"
echo "  Testing VLANs $START_VLAN to $END_VLAN"
echo "=========================================="
echo ""

# Test each VLAN
for ((i=START_VLAN; i<=END_VLAN; i++)); do
    BASE=$((SUBNET_SIZE * (i - START_VLAN)))
    OCTET3=$((BASE / 256))
    OCTET4=$((BASE % 256))
    TARGET_IP="10.0.$OCTET3.$OCTET4"
    
    ((total++))
    
    # Ping test
    if ping -c $PING_COUNT -W $TIMEOUT "$TARGET_IP" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} VLAN $i ($TARGET_IP): UP"
        ((success++))
    else
        echo -e "${RED}✗${NC} VLAN $i ($TARGET_IP): DOWN"
        ((failed++))
    fi
    
    # Progress update every 25 VLANs
    if (( i % 25 == 0 )); then
        echo -e "${YELLOW}--- Progress: $((i - START_VLAN + 1))/$((END_VLAN - START_VLAN + 1)) VLANs tested ---${NC}"
    fi
done

# Summary
echo ""
echo "=========================================="
echo "  Test Summary"
echo "=========================================="
echo "Total VLANs tested: $total"
echo -e "${GREEN}Successful: $success${NC}"
echo -e "${RED}Failed: $failed${NC}"
echo "Success rate: $(( success * 100 / total ))%"
echo ""

# Failed VLANs detail
if [[ $failed -gt 0 ]]; then
    echo "Run with verbose mode to see failed VLANs:"
    echo "./test-connectivity.sh --verbose"
fi
