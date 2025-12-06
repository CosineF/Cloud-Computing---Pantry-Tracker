#!/bin/bash

# Emergency Kill Switch Script
# Reduces system capacity to minimum to control costs

echo "🛑 Emergency Kill Switch"
echo "======================="
echo ""
echo -e "\033[1;31mWARNING: This will significantly reduce system capacity!\033[0m"
echo "This should only be used in emergencies (cost spike, abuse, etc.)"
echo ""
read -p "Are you sure you want to activate kill switch? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Kill switch cancelled."
    exit 0
fi

echo ""
echo "Activating kill switch..."

# Reduce Lambda concurrency to minimum
echo "1. Reducing Lambda concurrency to 10..."
aws lambda put-function-concurrency \
  --function-name PantryInventoryFunction \
  --reserved-concurrent-executions 10 \
  2>&1 | grep -q "ConcurrentExecutions" && echo "   ✓ Lambda concurrency reduced" || echo "   ⚠ Failed to update Lambda"

# Reduce DynamoDB capacity to minimum
echo "2. Reducing DynamoDB capacity to minimum (5 RCU/WCU)..."
aws application-autoscaling register-scalable-target \
  --service-namespace dynamodb \
  --resource-id table/PantryInventory \
  --scalable-dimension dynamodb:table:ReadCapacityUnits \
  --min-capacity 5 \
  --max-capacity 5 \
  2>&1 | grep -q "ScalableTarget" && echo "   ✓ DynamoDB read capacity reduced" || echo "   ⚠ Failed to update DynamoDB read"

aws application-autoscaling register-scalable-target \
  --service-namespace dynamodb \
  --resource-id table/PantryInventory \
  --scalable-dimension dynamodb:table:WriteCapacityUnits \
  --min-capacity 5 \
  --max-capacity 5 \
  2>&1 | grep -q "ScalableTarget" && echo "   ✓ DynamoDB write capacity reduced" || echo "   ⚠ Failed to update DynamoDB write"

echo ""
echo -e "\033[0;32m✓ Kill switch activated\033[0m"
echo ""
echo "System capacity has been reduced to minimum."
echo "Monitor costs and restore capacity when safe:"
echo "  ./restore-capacity.sh"
echo ""

