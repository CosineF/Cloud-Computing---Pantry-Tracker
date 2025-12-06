#!/bin/bash

# Simple API testing script
# Usage: ./test-api.sh [API_URL] [API_KEY]
# Example: ./test-api.sh http://127.0.0.1:3000
# Example: ./test-api.sh https://YOUR_API_ID.execute-api.ca-central-1.amazonaws.com/Prod your-api-key

API_URL="${1:-http://127.0.0.1:3000}"
API_KEY="${2:-}"
HOUSEHOLD_ID="test-household-$(date +%s)"

echo "🧪 Testing API at: $API_URL"
echo "📝 Using household ID: $HOUSEHOLD_ID"
if [ -n "$API_KEY" ]; then
    echo "🔑 Using API key authentication"
else
    echo "⚠️  No API key provided (will fail if auth is enabled)"
fi
echo ""

# Build curl headers
CURL_HEADERS=""
if [ -n "$API_KEY" ]; then
    CURL_HEADERS="-H \"X-API-Key: $API_KEY\""
fi

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Get empty inventory
echo -e "${YELLOW}Test 1: Get empty inventory${NC}"
if [ -n "$API_KEY" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -H "X-API-Key: $API_KEY" "$API_URL/inventory?householdId=$HOUSEHOLD_ID")
else
    RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/inventory?householdId=$HOUSEHOLD_ID")
fi
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✓ Passed (HTTP $HTTP_CODE)${NC}"
    echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
else
    echo -e "${RED}✗ Failed (HTTP $HTTP_CODE)${NC}"
    echo "$BODY"
fi
echo ""

# Test 2: Add item
echo -e "${YELLOW}Test 2: Add item${NC}"
if [ -n "$API_KEY" ]; then
    ADD_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/inventory" \
      -H "X-API-Key: $API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"householdId\":\"$HOUSEHOLD_ID\",\"name\":\"Milk\",\"quantity\":2}")
else
    ADD_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/inventory" \
      -H "Content-Type: application/json" \
      -d "{\"householdId\":\"$HOUSEHOLD_ID\",\"name\":\"Milk\",\"quantity\":2}")
fi
HTTP_CODE=$(echo "$ADD_RESPONSE" | tail -n1)
BODY=$(echo "$ADD_RESPONSE" | sed '$d')
if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✓ Passed (HTTP $HTTP_CODE)${NC}"
    echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
    ITEM_ID=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['item']['id'])" 2>/dev/null)
else
    echo -e "${RED}✗ Failed (HTTP $HTTP_CODE)${NC}"
    echo "$BODY"
    ITEM_ID=""
fi
echo ""

# Test 3: Get inventory (should have item)
echo -e "${YELLOW}Test 3: Get inventory (should have item)${NC}"
if [ -n "$API_KEY" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -H "X-API-Key: $API_KEY" "$API_URL/inventory?householdId=$HOUSEHOLD_ID")
else
    RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/inventory?householdId=$HOUSEHOLD_ID")
fi
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
if [ "$HTTP_CODE" -eq 200 ]; then
    ITEM_COUNT=$(echo "$BODY" | python3 -c "import sys, json; print(len(json.load(sys.stdin)['items']))" 2>/dev/null)
    if [ "$ITEM_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Passed (HTTP $HTTP_CODE, $ITEM_COUNT items)${NC}"
        echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
    else
        echo -e "${RED}✗ Failed: Expected items but found none${NC}"
        echo "$BODY"
    fi
else
    echo -e "${RED}✗ Failed (HTTP $HTTP_CODE)${NC}"
    echo "$BODY"
fi
echo ""

# Test 4: Remove item (if we have an item ID)
if [ -n "$ITEM_ID" ]; then
    echo -e "${YELLOW}Test 4: Remove item${NC}"
    if [ -n "$API_KEY" ]; then
        REMOVE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$API_URL/inventory" \
          -H "X-API-Key: $API_KEY" \
          -H "Content-Type: application/json" \
          -d "{\"householdId\":\"$HOUSEHOLD_ID\",\"itemId\":\"$ITEM_ID\"}")
    else
        REMOVE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$API_URL/inventory" \
          -H "Content-Type: application/json" \
          -d "{\"householdId\":\"$HOUSEHOLD_ID\",\"itemId\":\"$ITEM_ID\"}")
    fi
    HTTP_CODE=$(echo "$REMOVE_RESPONSE" | tail -n1)
    BODY=$(echo "$REMOVE_RESPONSE" | sed '$d')
    if [ "$HTTP_CODE" -eq 200 ]; then
        echo -e "${GREEN}✓ Passed (HTTP $HTTP_CODE)${NC}"
        echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
    else
        echo -e "${RED}✗ Failed (HTTP $HTTP_CODE)${NC}"
        echo "$BODY"
    fi
    echo ""
    
    # Test 5: Get inventory (should be empty again)
    echo -e "${YELLOW}Test 5: Get inventory (should be empty again)${NC}"
    if [ -n "$API_KEY" ]; then
        RESPONSE=$(curl -s -w "\n%{http_code}" -H "X-API-Key: $API_KEY" "$API_URL/inventory?householdId=$HOUSEHOLD_ID")
    else
        RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/inventory?householdId=$HOUSEHOLD_ID")
    fi
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    if [ "$HTTP_CODE" -eq 200 ]; then
        ITEM_COUNT=$(echo "$BODY" | python3 -c "import sys, json; print(len(json.load(sys.stdin)['items']))" 2>/dev/null)
        if [ "$ITEM_COUNT" -eq 0 ]; then
            echo -e "${GREEN}✓ Passed (HTTP $HTTP_CODE, inventory is empty)${NC}"
            echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
        else
            echo -e "${RED}✗ Failed: Expected empty inventory but found $ITEM_COUNT items${NC}"
            echo "$BODY"
        fi
    else
        echo -e "${RED}✗ Failed (HTTP $HTTP_CODE)${NC}"
        echo "$BODY"
    fi
    echo ""
fi

# Test 6: Error case - missing householdId
echo -e "${YELLOW}Test 6: Error case - missing householdId${NC}"
if [ -n "$API_KEY" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -H "X-API-Key: $API_KEY" "$API_URL/inventory")
else
    RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/inventory")
fi
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
if [ "$HTTP_CODE" -eq 400 ] || [ "$HTTP_CODE" -eq 404 ]; then
    echo -e "${GREEN}✓ Passed (HTTP $HTTP_CODE - expected error)${NC}"
    echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
else
    echo -e "${YELLOW}⚠ Unexpected status (HTTP $HTTP_CODE)${NC}"
    echo "$BODY"
fi
echo ""

echo -e "${GREEN}✅ All tests completed!${NC}"

