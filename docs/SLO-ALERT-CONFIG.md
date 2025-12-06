# SLO/Alert Configuration

## Service Level Objectives (SLOs)

### Availability SLO

**Target**: 99.5% uptime (monthly)

**Measurement**:
- API Gateway 5xx errors < 0.5% of total requests
- Lambda function errors < 1% of invocations
- DynamoDB throttling events = 0

**Calculation**:
```
Availability = (Total Requests - 5xx Errors) / Total Requests
```

### Latency SLO

**Target**: 
- P50 latency < 200ms
- P95 latency < 500ms
- P99 latency < 1000ms

**Measurement**:
- API Gateway latency metrics
- Lambda duration metrics

### Error Rate SLO

**Target**: Error rate < 1%

**Measurement**:
- Lambda errors / total invocations
- API Gateway 4xx + 5xx / total requests

## CloudWatch Alarms Configuration

### Critical Alarms (PagerDuty)

#### 1. Lambda Function Errors
- **Alarm Name**: `PantryInventory-LambdaErrors`
- **Metric**: `AWS/Lambda Errors`
- **Threshold**: > 5 errors in 2 minutes
- **Action**: SNS → PagerDuty + Email
- **Severity**: Critical

#### 2. Lambda Throttles
- **Alarm Name**: `PantryInventory-LambdaThrottles`
- **Metric**: `AWS/Lambda Throttles`
- **Threshold**: > 0 throttles in 1 minute
- **Action**: SNS → PagerDuty + Email
- **Severity**: Critical

#### 3. DynamoDB Read Throttles
- **Alarm Name**: `PantryInventory-DynamoDBReadThrottles`
- **Metric**: `AWS/DynamoDB ReadThrottleEvents`
- **Threshold**: > 0 events in 1 minute
- **Action**: SNS → PagerDuty + Email
- **Severity**: Critical

#### 4. DynamoDB Write Throttles
- **Alarm Name**: `PantryInventory-DynamoDBWriteThrottles`
- **Metric**: `AWS/DynamoDB WriteThrottleEvents`
- **Threshold**: > 0 events in 1 minute
- **Action**: SNS → PagerDuty + Email
- **Severity**: Critical

#### 5. API Gateway 5xx Errors
- **Alarm Name**: `PantryInventory-API5xxErrors`
- **Metric**: `AWS/ApiGateway 5XXError`
- **Threshold**: > 5 errors in 2 minutes
- **Action**: SNS → PagerDuty + Email
- **Severity**: Critical

### Warning Alarms (Email Only)

#### 1. Lambda High Duration
- **Alarm Name**: `PantryInventory-LambdaDuration`
- **Metric**: `AWS/Lambda Duration`
- **Threshold**: Average > 8 seconds in 2 minutes
- **Action**: Email only
- **Severity**: Warning

## Alert Response Procedures

### Critical Alert Response

1. **Immediate Actions** (within 5 minutes):
   - Check CloudWatch Logs for error details
   - Verify DynamoDB table status
   - Check Lambda function metrics
   - Review recent deployments

2. **Investigation** (within 15 minutes):
   - Identify root cause
   - Check if issue is affecting users
   - Determine if rollback is needed

3. **Resolution** (within 1 hour):
   - Apply fix or rollback
   - Verify resolution in CloudWatch
   - Document incident

### Warning Alert Response

1. **Monitor** (within 30 minutes):
   - Check if trend is increasing
   - Review performance metrics
   - Check for capacity issues

2. **Action** (if needed):
   - Scale resources if needed
   - Optimize code if performance issue
   - Update capacity planning

## Monitoring Dashboard

### Key Metrics to Monitor

1. **Lambda Metrics**:
   - Invocations
   - Errors
   - Duration
   - Throttles
   - Concurrent Executions

2. **DynamoDB Metrics**:
   - Read/Write Capacity Units
   - Throttle Events
   - Consumed Read/Write Capacity

3. **API Gateway Metrics**:
   - Request Count
   - 4XX/5XX Errors
   - Latency (P50, P95, P99)
   - Cache Hit Rate

4. **Custom Metrics** (via Lambda Insights):
   - Function cold starts
   - Memory utilization
   - Custom business metrics

## Alert Channels

### Primary: PagerDuty
- **Integration**: AWS SNS → PagerDuty Events API
- **Escalation**: On-call engineer → Team lead → Manager
- **Response Time**: 5 minutes for critical alerts

### Secondary: Email
- **Recipients**: Team email list
- **Purpose**: Non-critical alerts and notifications
- **Response Time**: Business hours

## SLO Tracking

### Monthly Review

1. Calculate actual availability
2. Compare against 99.5% target
3. Review error budget consumption
4. Document any SLO violations
5. Plan improvements if needed

### Error Budget

**Monthly Error Budget**: 0.5% of requests (based on 99.5% SLO)

**Example** (1M requests/month):
- Allowed errors: 5,000 requests
- Track consumption throughout month
- If budget consumed early, prioritize reliability improvements

## Continuous Improvement

### Weekly Reviews
- Review alarm frequency
- Tune thresholds if needed
- Update runbooks based on incidents

### Monthly Reviews
- SLO performance analysis
- Capacity planning updates
- Alert optimization

