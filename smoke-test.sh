#!/bin/bash

# Simple Smoke Test - Quick verification that deployment is working
# Usage: ./smoke-test.sh [API_URL]
# Example: ./smoke-test.sh https://YOUR_API_ID.execute-api.us-west-2.amazonaws.com/Prod

API_URL="${1:-}"
if [ -z "$API_URL" ]; then
    echo "❌ Error: API URL required"
    echo "Usage: ./smoke-test.sh <API_URL>"
    echo "Example: ./smoke-test.sh https://abc123.execute-api.us-west-2.amazonaws.com/Prod"
    exit 1
fi

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔥 Smoke Test: $API_URL"
echo ""

# Generate unique test user
TEST_USER="smoketest-$(date +%s)"
TEST_PASS="testpass123"

PASSED=0
FAILED=0

# Test 1: Signup
echo -e "${YELLOW}Test 1: User Signup${NC}"
SIGNUP_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/auth/signup" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$TEST_USER\",\"password\":\"$TEST_PASS\"}")
HTTP_CODE=$(echo "$SIGNUP_RESPONSE" | tail -n1)
BODY=$(echo "$SIGNUP_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 201 ]; then
    TOKEN=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin).get('token', ''))" 2>/dev/null)
    if [ -n "$TOKEN" ]; then
        echo -e "${GREEN}✓ Passed (HTTP $HTTP_CODE) - Token received${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ Failed - No token in response${NC}"
        ((FAILED++))
    fi
else
    echo -e "${RED}✗ Failed (HTTP $HTTP_CODE)${NC}"
    echo "$BODY"
    ((FAILED++))
fi
echo ""

# Test 2: Login
echo -e "${YELLOW}Test 2: User Login${NC}"
LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$TEST_USER\",\"password\":\"$TEST_PASS\"}")
HTTP_CODE=$(echo "$LOGIN_RESPONSE" | tail -n1)
BODY=$(echo "$LOGIN_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    TOKEN=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin).get('token', ''))" 2>/dev/null)
    if [ -n "$TOKEN" ]; then
        echo -e "${GREEN}✓ Passed (HTTP $HTTP_CODE) - Token received${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ Failed - No token in response${NC}"
        ((FAILED++))
    fi
else
    echo -e "${RED}✗ Failed (HTTP $HTTP_CODE)${NC}"
    echo "$BODY"
    ((FAILED++))
fi
echo ""

# Test 3: Get Inventory (empty)
echo -e "${YELLOW}Test 3: Get Inventory (should be empty)${NC}"
INV_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$API_URL/inventory" \
    -H "Authorization: Bearer $TOKEN")
HTTP_CODE=$(echo "$INV_RESPONSE" | tail -n1)
BODY=$(echo "$INV_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✓ Passed (HTTP $HTTP_CODE)${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ Failed (HTTP $HTTP_CODE)${NC}"
    echo "$BODY"
    ((FAILED++))
fi
echo ""

# Test 4: Add Item
echo -e "${YELLOW}Test 4: Add Item${NC}"
ADD_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/inventory" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Smoke Test Item","quantity":1}')
HTTP_CODE=$(echo "$ADD_RESPONSE" | tail -n1)
BODY=$(echo "$ADD_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    ITEM_ID=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin).get('item', {}).get('id', ''))" 2>/dev/null)
    if [ -n "$ITEM_ID" ]; then
        echo -e "${GREEN}✓ Passed (HTTP $HTTP_CODE) - Item ID: $ITEM_ID${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ Failed - No item ID in response${NC}"
        ((FAILED++))
    fi
else
    echo -e "${RED}✗ Failed (HTTP $HTTP_CODE)${NC}"
    echo "$BODY"
    ((FAILED++))
fi
echo ""

# Test 5: Get Inventory (with item)
echo -e "${YELLOW}Test 5: Get Inventory (should have 1 item)${NC}"
INV_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$API_URL/inventory" \
    -H "Authorization: Bearer $TOKEN")
HTTP_CODE=$(echo "$INV_RESPONSE" | tail -n1)
BODY=$(echo "$INV_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    COUNT=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin).get('count', 0))" 2>/dev/null)
    if [ "$COUNT" -eq 1 ]; then
        echo -e "${GREEN}✓ Passed (HTTP $HTTP_CODE) - Found $COUNT item(s)${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ Failed - Expected 1 item, found $COUNT${NC}"
        ((FAILED++))
    fi
else
    echo -e "${RED}✗ Failed (HTTP $HTTP_CODE)${NC}"
    echo "$BODY"
    ((FAILED++))
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed! ($PASSED/$((PASSED + FAILED)))${NC}"
    echo "🚀 Deployment looks good!"
    exit 0
else
    echo -e "${RED}❌ Some tests failed ($FAILED/$((PASSED + FAILED)))${NC}"
    echo "⚠️  Check the errors above"
    exit 1
fi

