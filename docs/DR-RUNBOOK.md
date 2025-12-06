# Disaster Recovery & Runbook

## Overview

This runbook provides procedures for disaster recovery, incident response, and operational maintenance for Cloud Pantry Tracker.

## System Architecture

```
Frontend (Static) → API Gateway → Lambda → DynamoDB
                              ↓
                         CloudWatch Alarms → SNS → PagerDuty/Email
```

## Disaster Recovery Scenarios

### Scenario 1: Lambda Function Failure

**Symptoms**:
- CloudWatch alarm: `PantryInventory-LambdaErrors`
- API Gateway returns 5xx errors
- Users cannot access inventory

**Recovery Steps**:

1. **Immediate Response** (0-5 minutes):
   ```bash
   # Check Lambda logs
   aws logs tail /aws/lambda/PantryInventoryFunction --follow
   
   # Check recent errors
   aws cloudwatch get-metric-statistics \
     --namespace AWS/Lambda \
     --metric-name Errors \
     --dimensions Name=FunctionName,Value=PantryInventoryFunction \
     --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
     --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
     --period 300 \
     --statistics Sum
   ```

2. **Investigation** (5-15 minutes):
   - Review CloudWatch Logs Insights for error patterns
   - Check if recent deployment caused issue
   - Verify environment variables are correct

3. **Resolution**:
   - **If code issue**: Rollback to previous version
     ```bash
     # List recent deployments
     aws cloudformation list-stack-events \
       --stack-name CloudPantryTracker \
       --max-items 20
     
     # Rollback by redeploying previous template version
     sam deploy --parameter-overrides ...
     ```
   
   - **If configuration issue**: Update environment variables
     ```bash
     aws lambda update-function-configuration \
       --function-name PantryInventoryFunction \
       --environment Variables={TABLE_NAME=...,USERS_TABLE_NAME=...,JWT_SECRET=...}
     ```
   
   - **If resource limit**: Increase Lambda concurrency
     ```bash
     # Update template.yaml: ReservedConcurrentExecutions: 200
     sam deploy
     ```

### Scenario 2: DynamoDB Throttling

**Symptoms**:
- CloudWatch alarm: `PantryInventory-DynamoDBReadThrottles` or `WriteThrottles`
- API requests timing out
- High latency

**Recovery Steps**:

1. **Immediate Response**:
   ```bash
   # Check current capacity
   aws dynamodb describe-table --table-name PantryInventory
   
   # Check throttle events
   aws cloudwatch get-metric-statistics \
     --namespace AWS/DynamoDB \
     --metric-name ReadThrottleEvents \
     --dimensions Name=TableName,Value=PantryInventory \
     --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
     --period 300 \
     --statistics Sum
   ```

2. **Resolution**:
   - **Auto-scaling should handle this**, but if needed:
     ```bash
     # Manually increase capacity (if auto-scaling not working)
     aws application-autoscaling register-scalable-target \
       --service-namespace dynamodb \
       --resource-id table/PantryInventory \
       --scalable-dimension dynamodb:table:ReadCapacityUnits \
       --min-capacity 10 \
       --max-capacity 200
     ```
   
   - **Check for hot partitions**:
     - Review access patterns
     - Consider adding Global Secondary Index if needed
     - Optimize query patterns

### Scenario 3: API Gateway Failure

**Symptoms**:
- CloudWatch alarm: `PantryInventory-API5xxErrors`
- All API requests failing
- Frontend cannot connect

**Recovery Steps**:

1. **Check API Gateway status**:
   ```bash
   # Get API Gateway ID
   API_ID=$(aws apigateway get-rest-apis --query 'items[?name==`CloudPantryTracker`].id' --output text)
   
   # Check deployment status
   aws apigateway get-deployments --rest-api-id $API_ID
   ```

2. **Resolution**:
   - **Redeploy API**:
     ```bash
     sam deploy
     ```
   
   - **Check Lambda permissions**:
     ```bash
     aws lambda get-policy --function-name PantryInventoryFunction
     ```

### Scenario 4: Data Corruption or Loss

**Symptoms**:
- Users report missing data
- DynamoDB table shows unexpected state

**Recovery Steps**:

1. **Check Point-in-Time Recovery** (if enabled):
   ```bash
   # List available restore times
   aws dynamodb list-continuous-backups --table-name PantryInventory
   
   # Restore to point in time
   aws dynamodb restore-table-to-point-in-time \
     --source-table-name PantryInventory \
     --target-table-name PantryInventory-restored \
     --restore-date-time 2024-01-01T00:00:00Z
   ```

2. **Manual Recovery**:
   - Export data from backup
   - Restore to new table
   - Update Lambda environment variables
   - Verify data integrity

### Scenario 5: Security Breach

**Symptoms**:
- Unusual access patterns
- Unauthorized API calls
- JWT tokens compromised

**Recovery Steps**:

1. **Immediate Actions**:
   - Rotate JWT secret:
     ```bash
     # Generate new secret
     openssl rand -hex 32
     
     # Update stack
     sam deploy --parameter-overrides JwtSecret=NEW_SECRET
     ```
   
   - Review CloudTrail logs:
     ```bash
     aws cloudtrail lookup-events \
       --lookup-attributes AttributeKey=EventName,AttributeValue=InvokeFunction \
       --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S)
     ```

2. **Investigation**:
   - Identify compromised accounts
   - Review access logs
   - Check for data exfiltration

3. **Remediation**:
   - Revoke compromised tokens (force re-login)
   - Update security policies
   - Notify affected users

## Operational Procedures

### Daily Checks

1. **Review CloudWatch Alarms**:
   - Check for any active alarms
   - Review alarm history

2. **Monitor Metrics**:
   - Lambda error rate
   - DynamoDB throttle events
   - API Gateway latency

### Weekly Tasks

1. **Review Logs**:
   - Check for error patterns
   - Review performance trends
   - Identify optimization opportunities

2. **Capacity Planning**:
   - Review usage trends
   - Adjust auto-scaling limits if needed
   - Plan for growth

### Monthly Tasks

1. **SLO Review**:
   - Calculate actual availability
   - Review error budget consumption
   - Document any violations

2. **Security Audit**:
   - Review IAM policies
   - Check for unused resources
   - Rotate secrets if needed

## Backup and Recovery

### Current Backup Strategy

**DynamoDB**:
- Point-in-Time Recovery: **Not enabled** (MVP)
- On-Demand Backups: **Not configured** (MVP)

**Recommendation for Production**:
```bash
# Enable Point-in-Time Recovery
aws dynamodb update-continuous-backups \
  --table-name PantryInventory \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true
```

### Backup Procedures

1. **Manual Backup**:
   ```bash
   # Export table data
   aws dynamodb scan --table-name PantryInventory > backup.json
   
   # Export users table
   aws dynamodb scan --table-name PantryUsers > users-backup.json
   ```

2. **Restore from Backup**:
   ```bash
   # Import data (requires table to exist)
   # Use AWS Data Pipeline or custom script
   ```

## Incident Response Checklist

### When Alert Fires

- [ ] Acknowledge alert in PagerDuty
- [ ] Check CloudWatch dashboard
- [ ] Review recent changes/deployments
- [ ] Check system health metrics
- [ ] Identify root cause
- [ ] Apply fix or rollback
- [ ] Verify resolution
- [ ] Document incident
- [ ] Update runbook if needed

### Communication

- **Internal**: Update team Slack/email
- **Users**: If extended outage, post status update
- **Stakeholders**: Escalate if SLO violated

## Testing Procedures

### Chaos Testing

1. **Lambda Failure Injection**:
   - Temporarily break Lambda code
   - Verify alarms fire
   - Test recovery procedures

2. **DynamoDB Throttle Simulation**:
   - Reduce capacity to minimum
   - Generate load
   - Verify auto-scaling response

3. **Network Partition**:
   - Simulate Lambda-DynamoDB connectivity issues
   - Test retry logic
   - Verify error handling

### Load Testing

Run load tests regularly:
```bash
./load-test.sh $API_URL 50 100
```

Monitor:
- Lambda concurrency
- DynamoDB capacity utilization
- Error rates
- Latency percentiles

## Contact Information

- **On-Call Engineer**: Cosine Feng  
- **Team Lead**: Jacob Wu   

## Appendix

### Useful Commands

```bash
# View Lambda logs
aws logs tail /aws/lambda/PantryInventoryFunction --follow

# Check DynamoDB metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedReadCapacityUnits \
  --dimensions Name=TableName,Value=PantryInventory \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum

# List CloudWatch alarms
aws cloudwatch describe-alarms --alarm-name-prefix PantryInventory

# Check stack status
aws cloudformation describe-stacks --stack-name CloudPantryTracker
```

### CloudWatch Dashboard Queries

Create dashboard with:
- Lambda: Errors, Duration, Throttles, ConcurrentExecutions
- DynamoDB: ReadThrottleEvents, WriteThrottleEvents, ConsumedReadCapacityUnits
- API Gateway: 4XXError, 5XXError, Latency, Count

