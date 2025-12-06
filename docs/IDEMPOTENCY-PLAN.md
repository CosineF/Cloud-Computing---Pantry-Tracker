# Idempotency Plan

## Overview

Idempotency ensures that operations can be safely retried without causing unintended side effects. This document outlines the idempotency strategy for Cloud Pantry Tracker.

## Current Implementation

### 1. Inventory Operations

#### Add Item (POST /inventory)
**Status**: ✅ Partially Idempotent

**Current Behavior:**
- Each request generates a unique `itemId` using: `householdId#hash(itemName + timestamp)`
- Multiple identical requests create multiple items with different IDs

**Idempotency Issue:**
- If a request is retried (e.g., network timeout), it may create duplicate items

**Recommendation:**
- Add idempotency key in request header: `Idempotency-Key: <uuid>`
- Store idempotency key in DynamoDB with TTL (24 hours)
- If key exists, return the original response without creating duplicate

#### Remove Item (DELETE /inventory)
**Status**: ✅ Idempotent

**Current Behavior:**
- DELETE operation is naturally idempotent
- Deleting a non-existent item returns 404 (safe to retry)

#### Get Inventory (GET /inventory)
**Status**: ✅ Idempotent

**Current Behavior:**
- Read operations are naturally idempotent
- No side effects, safe to retry

### 2. Authentication Operations

#### Signup (POST /auth/signup)
**Status**: ⚠️ Not Idempotent

**Current Behavior:**
- First request creates user
- Subsequent requests with same username return 409 Conflict

**Idempotency:**
- Already handled: Returns 409 if user exists
- Safe to retry (won't create duplicates)

#### Login (POST /auth/login)
**Status**: ✅ Idempotent

**Current Behavior:**
- Read operation (validates credentials)
- No side effects, safe to retry

## Idempotency Strategy

### Short-term (Current MVP)

1. **DELETE operations**: Already idempotent ✅
2. **GET operations**: Already idempotent ✅
3. **POST /auth/signup**: Handled with conflict detection ✅
4. **POST /inventory**: Accept duplicate items as acceptable for MVP

### Long-term Improvements

#### 1. Add Idempotency Keys for Write Operations

```python
# In Lambda function
def add_item(event, headers, username):
    # Extract idempotency key
    idempotency_key = event.get('headers', {}).get('Idempotency-Key')
    
    if idempotency_key:
        # Check if request was already processed
        idempotency_table = dynamodb.Table('IdempotencyKeys')
        try:
            response = idempotency_table.get_item(Key={'key': idempotency_key})
            if 'Item' in response:
                # Return cached response
                return json.loads(response['Item']['response'])
        except ClientError:
            pass
    
    # Process request...
    result = {...}
    
    # Store idempotency key with TTL
    if idempotency_key:
        idempotency_table.put_item(Item={
            'key': idempotency_key,
            'response': json.dumps(result),
            'ttl': int((datetime.utcnow() + timedelta(hours=24)).timestamp())
        })
    
    return result
```

#### 2. Use DynamoDB Conditional Writes

```python
# Prevent duplicate items with same name in short time window
table.put_item(
    Item=item,
    ConditionExpression='attribute_not_exists(itemId) OR createdAt < :threshold',
    ExpressionAttributeValues={
        ':threshold': (datetime.utcnow() - timedelta(seconds=5)).isoformat()
    }
)
```

#### 3. Client-Side Idempotency

Frontend should:
- Generate UUID for each write operation
- Include in `Idempotency-Key` header
- Retry with same key on failure

## Testing Idempotency

### Test Cases

1. **Duplicate Add Item Request**
   ```bash
   # Send same request twice
   curl -X POST "$API_URL/inventory" \
     -H "Authorization: Bearer $TOKEN" \
     -H "Idempotency-Key: test-key-123" \
     -d '{"name":"Milk","quantity":2}'
   
   # Should return same item ID on retry
   ```

2. **Network Retry Simulation**
   - Send request
   - Simulate timeout
   - Retry with same idempotency key
   - Verify no duplicate created

3. **Concurrent Requests**
   - Send multiple requests with same idempotency key simultaneously
   - Verify only one item created

## Monitoring

Track idempotency violations:
- CloudWatch metric: `IdempotencyKeyHits` (when cached response returned)
- CloudWatch metric: `IdempotencyKeyMisses` (new requests)
- Alert if miss rate is high (indicates retry issues)

## Conclusion

**Current State**: Basic idempotency for read/delete operations. Write operations may create duplicates on retry.

**Recommendation**: For MVP, current state is acceptable. For production, implement idempotency keys for all write operations.

