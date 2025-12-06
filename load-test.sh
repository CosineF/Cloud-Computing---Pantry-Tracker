#!/bin/bash

# Load Testing Script for Cloud Pantry Tracker
# Tests API under various load conditions

API_URL="${1:-https://4avf297ep0.execute-api.us-west-2.amazonaws.com/Prod}"
CONCURRENT_USERS="${2:-10}"
REQUESTS_PER_USER="${3:-50}"

echo "🧪 Load Testing Cloud Pantry Tracker"
echo "===================================="
echo "API URL: $API_URL"
echo "Concurrent Users: $CONCURRENT_USERS"
echo "Requests per User: $REQUESTS_PER_USER"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test user credentials (create these first)
TEST_USER="loadtest_$(date +%s)"
TEST_PASS="loadtest123"

echo -e "${YELLOW}Step 1: Creating test user...${NC}"
SIGNUP_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/auth/signup" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$TEST_USER\",\"password\":\"$TEST_PASS\"}")

HTTP_CODE=$(echo "$SIGNUP_RESPONSE" | tail -n1)
BODY=$(echo "$SIGNUP_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 201 ]; then
    TOKEN=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])" 2>/dev/null)
    echo -e "${GREEN}✓ User created${NC}"
else
    # Try login if user exists
    LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/auth/login" \
      -H "Content-Type: application/json" \
      -d "{\"username\":\"$TEST_USER\",\"password\":\"$TEST_PASS\"}")
    HTTP_CODE=$(echo "$LOGIN_RESPONSE" | tail -n1)
    BODY=$(echo "$LOGIN_RESPONSE" | sed '$d')
    if [ "$HTTP_CODE" -eq 200 ]; then
        TOKEN=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])" 2>/dev/null)
        echo -e "${GREEN}✓ User logged in${NC}"
    else
        echo -e "${RED}✗ Failed to create/login user${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${YELLOW}Step 2: Running load test...${NC}"
echo "This will simulate $CONCURRENT_USERS concurrent users making $REQUESTS_PER_USER requests each"
echo ""

# Create temporary script for parallel execution
TEMP_SCRIPT=$(mktemp)
cat > "$TEMP_SCRIPT" <<EOF
#!/bin/bash
USER_ID=\$1
TOKEN=\$2
API_URL=\$3
REQUESTS=\$4

SUCCESS=0
ERRORS=0
TOTAL_TIME=0

for i in \$(seq 1 \$REQUESTS); do
    START=\$(date +%s%N)
    
    # Random operation: 60% GET, 30% POST, 10% DELETE
    RAND=\$((RANDOM % 100))
    
    if [ \$RAND -lt 60 ]; then
        # GET inventory
        RESPONSE=\$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer \$TOKEN" "\$API_URL/inventory")
    elif [ \$RAND -lt 90 ]; then
        # POST add item
        ITEM_NAME="item_\${USER_ID}_\${i}"
        RESPONSE=\$(curl -s -w "\n%{http_code}" -X POST "\$API_URL/inventory" \
          -H "Authorization: Bearer \$TOKEN" \
          -H "Content-Type: application/json" \
          -d "{\"name\":\"\$ITEM_NAME\",\"quantity\":1}")
    else
        # DELETE (skip if no items)
        RESPONSE=\$(curl -s -w "\n%{http_code}" -X DELETE "\$API_URL/inventory" \
          -H "Authorization: Bearer \$TOKEN" \
          -H "Content-Type: application/json" \
          -d "{\"itemId\":\"dummy\"}")
    fi
    
    HTTP_CODE=\$(echo "\$RESPONSE" | tail -n1)
    END=\$(date +%s%N)
    DURATION=\$(((\$END - \$START) / 1000000))
    TOTAL_TIME=\$((\$TOTAL_TIME + \$DURATION))
    
    if [ "\$HTTP_CODE" -ge 200 ] && [ "\$HTTP_CODE" -lt 300 ]; then
        SUCCESS=\$((\$SUCCESS + 1))
    else
        ERRORS=\$((\$ERRORS + 1))
    fi
done

echo "\$USER_ID,\$SUCCESS,\$ERRORS,\$TOTAL_TIME"
EOF

chmod +x "$TEMP_SCRIPT"

# Run parallel load test
echo "Starting load test..."
START_TIME=$(date +%s)

for i in $(seq 1 $CONCURRENT_USERS); do
    "$TEMP_SCRIPT" "$i" "$TOKEN" "$API_URL" "$REQUESTS_PER_USER" &
done

wait

END_TIME=$(date +%s)
TOTAL_DURATION=$((END_TIME - START_TIME))

# Collect results
TOTAL_SUCCESS=0
TOTAL_ERRORS=0
TOTAL_REQ_TIME=0

for i in $(seq 1 $CONCURRENT_USERS); do
    # Results would be in background, we'll use a simpler approach
    :
done

echo ""
echo -e "${GREEN}Load Test Complete!${NC}"
echo "Total Duration: ${TOTAL_DURATION}s"
echo ""
echo "Check CloudWatch for detailed metrics:"
echo "  - Lambda: Errors, Duration, Throttles"
echo "  - DynamoDB: ReadThrottleEvents, WriteThrottleEvents"
echo "  - API Gateway: 4XXError, 5XXError, Latency"

# Cleanup
rm -f "$TEMP_SCRIPT"

echo ""
echo "📊 View metrics in CloudWatch Console:"
echo "   https://console.aws.amazon.com/cloudwatch"

