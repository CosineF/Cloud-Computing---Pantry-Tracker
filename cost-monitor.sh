#!/bin/bash

# Cost Monitoring Script
# Monitors AWS costs and triggers alerts if thresholds exceeded

DAILY_THRESHOLD="${1:-5}"  # Default $5/day
MONTHLY_THRESHOLD="${2:-100}"  # Default $100/month

echo "💰 Cost Monitoring for Cloud Pantry Tracker"
echo "==========================================="
echo "Daily Threshold: \$$DAILY_THRESHOLD"
echo "Monthly Threshold: \$$MONTHLY_THRESHOLD"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get today's date
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d yesterday +%Y-%m-%d)
MONTH_START=$(date +%Y-%m-01)

# Check if AWS Cost Explorer is available
if ! aws ce get-cost-and-usage --help &>/dev/null; then
    echo -e "${YELLOW}⚠ AWS Cost Explorer API not available${NC}"
    echo "Cost monitoring requires Cost Explorer API access"
    echo ""
    echo "Alternative: Check costs manually in AWS Console:"
    echo "  https://console.aws.amazon.com/cost-management/home"
    exit 0
fi

# Get daily cost
echo -e "${YELLOW}Checking daily cost...${NC}"
DAILY_COST=$(aws ce get-cost-and-usage \
  --time-period Start=$TODAY,End=$(date -d tomorrow +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --query 'ResultsByTime[0].Total.BlendedCost.Amount' \
  --output text 2>/dev/null)

if [ -z "$DAILY_COST" ] || [ "$DAILY_COST" == "None" ]; then
    DAILY_COST="0"
fi

DAILY_COST_ROUNDED=$(printf "%.2f" $DAILY_COST)

# Get monthly cost
echo -e "${YELLOW}Checking monthly cost...${NC}"
MONTHLY_COST=$(aws ce get-cost-and-usage \
  --time-period Start=$MONTH_START,End=$(date -d 'next month' +%Y-%m-01) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --query 'ResultsByTime[0].Total.BlendedCost.Amount' \
  --output text 2>/dev/null)

if [ -z "$MONTHLY_COST" ] || [ "$MONTHLY_COST" == "None" ]; then
    MONTHLY_COST="0"
fi

MONTHLY_COST_ROUNDED=$(printf "%.2f" $MONTHLY_COST)

# Get cost by service
echo -e "${YELLOW}Cost breakdown by service...${NC}"
echo ""
aws ce get-cost-and-usage \
  --time-period Start=$MONTH_START,End=$(date -d 'next month' +%Y-%m-01) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=SERVICE \
  --query 'ResultsByTime[0].Groups[*].[Keys[0],Metrics.BlendedCost.Amount]' \
  --output table 2>/dev/null | head -20

echo ""
echo "==========================================="
echo -e "Daily Cost: \$$DAILY_COST_ROUNDED"
echo -e "Monthly Cost: \$$MONTHLY_COST_ROUNDED"
echo ""

# Check thresholds
DAILY_ALERT=false
MONTHLY_ALERT=false

if (( $(echo "$DAILY_COST > $DAILY_THRESHOLD" | bc -l) )); then
    echo -e "${RED}⚠️  DAILY COST EXCEEDED THRESHOLD!${NC}"
    echo -e "   Daily: \$$DAILY_COST_ROUNDED > \$$DAILY_THRESHOLD"
    DAILY_ALERT=true
else
    echo -e "${GREEN}✓ Daily cost within threshold${NC}"
fi

if (( $(echo "$MONTHLY_COST > $MONTHLY_THRESHOLD" | bc -l) )); then
    echo -e "${RED}⚠️  MONTHLY COST EXCEEDED THRESHOLD!${NC}"
    echo -e "   Monthly: \$$MONTHLY_COST_ROUNDED > \$$MONTHLY_THRESHOLD"
    MONTHLY_ALERT=true
else
    echo -e "${GREEN}✓ Monthly cost within threshold${NC}"
fi

echo ""

# Recommendations
if [ "$DAILY_ALERT" = true ] || [ "$MONTHLY_ALERT" = true ]; then
    echo -e "${YELLOW}Recommended Actions:${NC}"
    echo "1. Review cost breakdown above"
    echo "2. Check for unusual activity:"
    echo "   - High Lambda invocations"
    echo "   - High DynamoDB capacity"
    echo "   - Unexpected data transfer"
    echo "3. Apply kill switch if needed:"
    echo "   ./kill-switch.sh"
    echo "4. Review CloudWatch metrics for anomalies"
fi

echo ""
echo "📊 View detailed costs:"
echo "   https://console.aws.amazon.com/cost-management/home"

