#!/bin/bash

# Restore Capacity Script
# Restores system capacity after kill switch

echo "🔄 Restoring System Capacity"
echo "============================"
echo ""

# Restore Lambda concurrency
echo "1. Restoring Lambda concurrency to 100..."
aws lambda put-function-concurrency \
  --function-name PantryInventoryFunction \
  --reserved-concurrent-executions 100 \
  2>&1 | grep -q "ConcurrentExecutions" && echo "   ✓ Lambda concurrency restored" || echo "   ⚠ Failed to update Lambda"

# Restore DynamoDB auto-scaling
echo "2. Restoring DynamoDB auto-scaling (5-100 RCU/WCU)..."
aws application-autoscaling register-scalable-target \
  --service-namespace dynamodb \
  --resource-id table/PantryInventory \
  --scalable-dimension dynamodb:table:ReadCapacityUnits \
  --min-capacity 5 \
  --max-capacity 100 \
  2>&1 | grep -q "ScalableTarget" && echo "   ✓ DynamoDB read capacity restored" || echo "   ⚠ Failed to update DynamoDB read"

aws application-autoscaling register-scalable-target \
  --service-namespace dynamodb \
  --resource-id table/PantryInventory \
  --scalable-dimension dynamodb:table:WriteCapacityUnits \
  --min-capacity 5 \
  --max-capacity 100 \
  2>&1 | grep -q "ScalableTarget" && echo "   ✓ DynamoDB write capacity restored" || echo "   ⚠ Failed to update DynamoDB write"

echo ""
echo -e "\033[0;32m✓ Capacity restored\033[0m"
echo ""
echo "System is back to normal operation."
echo "Monitor metrics to ensure stability."
echo ""

