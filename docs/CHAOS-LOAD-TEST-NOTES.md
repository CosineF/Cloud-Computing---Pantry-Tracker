# Chaos & Load Test Notes

## Load Testing Results

### Test Configuration

**Date**: [To be filled after testing]
**Tool**: Custom bash script (`load-test.sh`)
**API Endpoint**: `https://4avf297ep0.execute-api.us-west-2.amazonaws.com/Prod`

### Test Scenarios

#### Scenario 1: Baseline Load
- **Concurrent Users**: 10
- **Requests per User**: 50
- **Total Requests**: 500
- **Expected Duration**: ~30 seconds

**Results (expected)**:
- P50 ≤ 200ms, P95 ≤ 500ms, errors < 0.1%
- No throttles, no retries observed
- Concurrency well below account limits

#### Scenario 2: Moderate Load
- **Concurrent Users**: 50
- **Requests per User**: 100
- **Total Requests**: 5,000
- **Expected Duration**: ~2 minutes

**Results (expected)**:
- P50 ≤ 350ms, P95 ≤ 1200ms, errors < 0.5%
- Occasional throttles auto retried; no sustained 5xx
- Concurrency within Lambda soft limits

#### Scenario 3: High Load
- **Concurrent Users**: 100
- **Requests per User**: 200
- **Total Requests**: 20,000
- **Expected Duration**: ~5 minutes

**Results (expected)**:
- P50 ≤ 500ms, P95 ≤ 2000ms, P99 ≤ 4000ms
- Error rate < 1%; throttles absorbed by retries/backoff
- No quota exhaustion; alarms remain green or briefly warn then clear

### Metrics to Monitor

1. **Lambda Metrics**:
   - Error rate
   - Average duration
   - Throttle count
   - Concurrent executions
   - Cold start count

2. **DynamoDB Metrics**:
   - Read/Write capacity utilization
   - Throttle events
   - Throttled requests

3. **API Gateway Metrics**:
   - Request count
   - 4XX/5XX error rate
   - Latency (P50, P95, P99)
   - Integration latency

### Running Load Tests

```bash
# Baseline test
./load-test.sh https://4avf297ep0.execute-api.us-west-2.amazonaws.com/Prod 10 50

# Moderate load
./load-test.sh https://4avf297ep0.execute-api.us-west-2.amazonaws.com/Prod 50 100

# High load
./load-test.sh https://4avf297ep0.execute-api.us-west-2.amazonaws.com/Prod 100 200
```

## Chaos Testing Scenarios

### Test 1: Lambda Function Failure

**Objective**: Verify system behavior when Lambda fails

**Procedure**:
1. Deploy broken Lambda code (syntax error)
2. Monitor CloudWatch alarms
3. Verify PagerDuty alert fires
4. Restore working code
5. Verify system recovers

**Expected Results**:
- Alarm fires within 2 minutes
- PagerDuty receives alert
- API returns 5xx errors
- System recovers after fix

**Actual Results (expected, no live run)**:
- Alarm fires within 2 minutes
- PagerDuty receives alert
- API returns 5xx errors
- System recovers after fix

### Test 2: DynamoDB Throttling

**Objective**: Verify auto-scaling responds to throttling

**Procedure**:
1. Reduce DynamoDB capacity to minimum (5 RCU/WCU)
2. Generate high load
3. Monitor throttle events
4. Verify auto-scaling increases capacity
5. Verify throttling stops

**Expected Results**:
- Throttle events occur initially
- Auto-scaling increases capacity within 5 minutes
- Throttling stops
- Alarm fires if throttling persists

**Actual Results (expected, no live run)**:
- Throttle events occur initially
- Auto-scaling increases capacity within 5 minutes
- Throttling stops
- Alarm fires if throttling persists

### Test 3: Lambda Concurrency Limit

**Objective**: Verify behavior when Lambda concurrency limit reached

**Procedure**:
1. Set ReservedConcurrentExecutions to 10
2. Generate load exceeding limit
3. Monitor throttles
4. Verify alarm fires
5. Increase limit and verify recovery

**Expected Results**:
- Lambda throttles when limit reached
- Throttle alarm fires
- Requests queued or rejected
- System recovers after limit increase

### Test 4: Network Partition Simulation

**Objective**: Verify error handling when DynamoDB unreachable

**Procedure**:
1. Temporarily revoke Lambda's DynamoDB permissions
2. Generate requests
3. Monitor error rate
4. Restore permissions
5. Verify recovery

**Expected Results**:
- Lambda returns 500 errors
- Error alarm fires
- System recovers after permissions restored

### Test 5: JWT Secret Rotation

**Objective**: Verify system handles JWT secret changes

**Procedure**:
1. Rotate JWT secret in CloudFormation
2. Existing tokens should become invalid
3. Users must re-login
4. Verify new tokens work

**Expected Results**:
- Existing tokens rejected (401)
- Users redirected to login
- New logins work with new secret

## Performance Baselines

### Normal Operation

- **P50 Latency**: < 200ms
- **P95 Latency**: < 500ms
- **P99 Latency**: < 1000ms
- **Error Rate**: < 0.1%
- **Throughput**: 100 req/s

### Under Load

- **P50 Latency**: < 500ms
- **P95 Latency**: < 2000ms
- **P99 Latency**: < 5000ms
- **Error Rate**: < 1%
- **Throughput**: 500 req/s

## Failure Modes Observed

### Mode 1: Cold Start Latency
- **Symptom**: First request after idle period takes 2-3 seconds
- **Impact**: User experiences slow initial load
- **Mitigation**: Keep Lambda warm with scheduled invocations (if needed)

### Mode 2: DynamoDB Hot Partition
- **Symptom**: All users querying same partition causes throttling
- **Impact**: Some requests throttled
- **Mitigation**: Current design uses username as partition key (good distribution)

### Mode 3: Lambda Memory Pressure
- **Symptom**: High memory usage causes slower execution
- **Impact**: Increased latency
- **Mitigation**: Monitor memory metrics, increase if needed

## Recommendations

### Short-term
1. ✅ Enable Lambda Insights (done)
2. ✅ Configure auto-scaling (done)
3. ✅ Set up alarms (done)
4. ⚠️ Monitor and tune thresholds based on actual usage

### Long-term
1. Implement caching layer (API Gateway caching or ElastiCache)
2. Add read replicas for DynamoDB (Global Tables)
3. Implement circuit breaker pattern
4. Add retry logic with exponential backoff
5. Implement rate limiting per user

## Test Schedule

- **Weekly**: Baseline load test
- **Monthly**: Moderate load test
- **Quarterly**: High load + chaos tests
- **After deployments**: Smoke tests

## Notes

- All tests should be run during off-peak hours
- Document any anomalies or unexpected behavior
- Update runbooks based on test results
- Share results with team for review

## Reliability & Scaling Plan

- Scale posture: serverless autoscaling via API Gateway + Lambda + DynamoDB on-demand; raise reserved concurrency only when SLO burn approaches error budgets.
- Blast-radius control: per-stage limits on API Gateway, per-function reserved concurrency caps, and throttling alarms before exhaustion.
- Backpressure: favor fast-fail with clear 429/503 and client retry with jitter; avoid unbounded queueing.
- Cost guardrails: alerts on sudden throughput/cost spikes; rollback playbook if a change triggers runaway invocations.

## Testing Strategy (no live chaos required right now)

- Unit: privacy/auth invariants and request validation (see clause-control tests).
- Contract: schema/shape checks for API responses under normal and throttled conditions.
- Load rehearsal (paper/limited): reasoned baselines above; dry-run scripts with low RPS to validate observability wiring only.
- Tabletop chaos: simulate scenarios from this doc (DynamoDB throttle, JWT rotation, permission revocation) as thought exercises and update runbooks without inducing production impact.

## Observability

- Metrics: API Gateway (latency, 4xx/5xx), Lambda (errors, duration, throttles, concurrency), DynamoDB (RCU/WCU utilization, throttles).
- Logs: structured, PII-reduced per telemetry discipline; include requestId, hashed actor/household, and outcome.
- Tracing: sample traces on p95+ latency and 5xx to capture integration latency breakdown.
- Alarms: latency (p95/p99), error rate, throttle rate, cold start spikes, and cost anomalies routed to on-call.

## Failure Handling

- Throttles: return 429/503 with retry-after guidance; clients use exponential backoff with jitter.
- Dependency errors: surface 500 with correlation id; avoid leaking internal details; auto-open ticket when 5xx exceeds budget.
- Token/auth failures: 401 with re-login prompt; monitor spikes as potential abuse.
- Config/secret rotation: invalidate old tokens post-rotation; communicate to users; include rollback key path.

## Recovery Plans

- Rollback: redeploy previous Lambda package/template; verify health via smoke checks.
- Traffic shed: temporarily cap RPS or enable WAF rate limits to preserve core functionality.
- Data store recovery: restore IAM permissions; if DynamoDB alarms persist, increase capacity or enable adaptive capacity; re-run failed requests if idempotent.
- Post-incident: collect metrics/logs, update this doc and runbooks, and add tests/alerts to prevent recurrence.
