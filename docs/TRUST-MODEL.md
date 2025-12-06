# Trust Model

## Overview

This document defines the trust boundaries, security assumptions, threat model, and trust relationships for the Cloud Pantry Tracker system.

## Trust Boundaries

### Boundary 1: Public Internet → API Gateway

**Trust Assumption**: 
- Users connecting from public internet are untrusted
- All communication must use HTTPS (enforced by API Gateway)
- No authentication required at gateway level

**Protection Mechanisms**:
- HTTPS/TLS encryption (API Gateway default)
- CORS policy (allows all origins - can be restricted in production)
- API Gateway rate limiting (can be configured)

**Threats**:
- Man-in-the-middle attacks → Mitigated by HTTPS
- DDoS attacks → Mitigated by API Gateway throttling
- Unauthorized access attempts → Handled by Lambda authentication

---

### Boundary 2: API Gateway → Lambda Function

**Trust Assumption**:
- API Gateway is trusted AWS service
- Lambda execution environment is trusted
- IAM role provides secure access

**Protection Mechanisms**:
- IAM role-based authentication (API Gateway → Lambda)
- VPC isolation (default, no custom VPC)
- Environment variable encryption (JWT_SECRET stored securely)

**Threats**:
- Unauthorized Lambda invocation → Mitigated by IAM policies
- Environment variable exposure → Mitigated by AWS Secrets Manager (future) or secure parameter storage

---

### Boundary 3: Lambda Function → DynamoDB

**Trust Assumption**:
- Lambda function code is trusted (developed by team)
- DynamoDB is trusted AWS service
- IAM policies enforce least privilege

**Protection Mechanisms**:
- IAM policy: `DynamoDBCrudPolicy` (read/write only to specific tables)
- User data isolation: `householdId = username` ensures users can only access their own data
- No cross-user data access possible

**Threats**:
- Unauthorized data access → Mitigated by IAM policies and application-level checks
- Data leakage → Mitigated by user isolation in data model

---

### Boundary 4: User → Frontend Application

**Trust Assumption**:
- Frontend code is delivered over HTTPS
- JWT tokens stored in browser localStorage (client-side)
- Users may have malicious intent (defense in depth)

**Protection Mechanisms**:
- HTTPS for all frontend delivery
- JWT token validation on every request
- Token expiration (7 days)
- No sensitive data in frontend code (API keys removed)

**Threats**:
- XSS attacks → Mitigated by proper input validation and escaping
- Token theft → Mitigated by HTTPS and token expiration
- Client-side manipulation → Mitigated by server-side validation

---

## Trust Relationships

### User Trust

**What Users Trust**:
- System will protect their data (inventory items)
- Passwords are securely stored (hashed)
- No unauthorized access to their inventory
- System availability and reliability

**What System Trusts About Users**:
- Users provide valid credentials
- Users follow API usage patterns
- Users don't attempt to access other users' data

**Trust Violations**:
- User attempts to access another user's data → Rejected by application logic
- User provides invalid credentials → Authentication fails
- User attempts abuse → Rate limiting and monitoring detect

---

### System Component Trust

#### Lambda Trusts DynamoDB
- DynamoDB will correctly store and retrieve data
- DynamoDB IAM policies are correctly configured
- DynamoDB availability and consistency

#### API Gateway Trusts Lambda
- Lambda will correctly process requests
- Lambda will return valid responses
- Lambda will handle errors gracefully

#### Frontend Trusts API
- API will correctly authenticate users
- API will return accurate inventory data
- API will maintain data consistency

---

## Threat Model

### Threat 1: Unauthorized Access

**Description**: Attacker attempts to access another user's inventory

**Attack Vector**:
- Steal JWT token
- Modify JWT token
- Guess username/password

**Mitigation**:
- ✅ JWT token validation on every request
- ✅ Token contains username, verified server-side
- ✅ Passwords hashed (SHA-256)
- ✅ User data isolated by `householdId = username`
- ✅ No way to query other users' data

**Residual Risk**: Low - Multiple layers of protection

---

### Threat 2: Data Interception

**Description**: Attacker intercepts data in transit

**Attack Vector**:
- Man-in-the-middle attack
- Network sniffing

**Mitigation**:
- ✅ HTTPS/TLS for all communications
- ✅ API Gateway enforces HTTPS
- ✅ No sensitive data in URLs (all in request body/headers)

**Residual Risk**: Very Low - Industry standard encryption

---

### Threat 3: Denial of Service (DoS)

**Description**: Attacker overwhelms system with requests

**Attack Vector**:
- High volume of requests
- Resource exhaustion

**Mitigation**:
- ✅ Lambda reserved concurrency (100 max)
- ✅ DynamoDB auto-scaling with max limits (100 RCU/WCU)
- ✅ API Gateway throttling (can be configured)
- ✅ CloudWatch monitoring and alerts

**Residual Risk**: Medium - Protected but can be overwhelmed with sufficient resources

---

### Threat 4: Credential Theft

**Description**: Attacker steals user credentials

**Attack Vector**:
- Phishing
- XSS attacks
- Token theft from localStorage

**Mitigation**:
- ✅ Passwords hashed (cannot be reversed)
- ✅ JWT tokens expire (7 days)
- ✅ HTTPS prevents token interception
- ✅ Input validation prevents XSS

**Residual Risk**: Medium - Depends on user security practices

---

### Threat 5: Insider Threat

**Description**: Authorized user (developer) abuses access

**Attack Vector**:
- Developer with AWS access modifies data
- Developer views user data inappropriately

**Mitigation**:
- ✅ IAM least privilege (only necessary permissions)
- ✅ CloudTrail logging (all API calls logged)
- ✅ No direct database access (all through Lambda)
- ✅ Code review process

**Residual Risk**: Low - Limited access, all actions logged

---

### Threat 6: Data Loss

**Description**: System failure causes data loss

**Attack Vector**:
- DynamoDB failure
- Accidental deletion
- Corruption

**Mitigation**:
- ✅ DynamoDB automatic backups (point-in-time recovery available)
- ✅ No direct delete operations (only through API)
- ✅ Application-level validation prevents corruption
- ⚠️ Manual backup procedures documented (not automated)

**Residual Risk**: Medium - Backups available but not automated for MVP

---

## Security Assumptions

### Assumed Secure

1. **AWS Infrastructure**: 
   - AWS services (Lambda, DynamoDB, API Gateway) are secure
   - AWS IAM policies are correctly enforced
   - AWS network isolation is effective

2. **HTTPS/TLS**:
   - TLS encryption is secure
   - Certificate validation works correctly
   - No TLS vulnerabilities in use

3. **JWT Implementation**:
   - PyJWT library is secure
   - HS256 algorithm is sufficient for MVP
   - JWT_SECRET is kept secret

4. **Password Hashing**:
   - SHA-256 is sufficient for MVP (not production)
   - Passwords are never stored in plain text
   - Hash cannot be reversed

### Not Assumed Secure

1. **Frontend Code**:
   - Frontend JavaScript can be modified by users
   - All validation must be server-side
   - Client-side code is not trusted

2. **User Input**:
   - All user input is validated
   - SQL injection not applicable (NoSQL)
   - XSS prevention through input sanitization

3. **Network**:
   - Public internet is not trusted
   - All communication uses HTTPS
   - No sensitive data in URLs

---

## Trust Zones

```
┌─────────────────────────────────────────────────────────────┐
│                    UNTRUSTED ZONE                           │
│  - Public Internet                                          │
│  - User Browsers                                            │
│  - User Input                                               │
└────────────────────────────┬────────────────────────────────┘
                              │
                              │ HTTPS/TLS
                              │ JWT Validation
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    TRUSTED ZONE 1                           │
│  - API Gateway (AWS Managed)                                │
│  - Lambda Function (Our Code)                               │
│  - IAM Roles & Policies                                     │
└────────────────────────────┬────────────────────────────────┘
                              │
                              │ IAM Authentication
                              │ Application Logic
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    TRUSTED ZONE 2                           │
│  - DynamoDB (AWS Managed)                                   │
│  - User Data (Isolated by username)                         │
│  - CloudWatch (Monitoring)                                  │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow Trust

### Authentication Flow

```
Untrusted User
    │
    │ Provides credentials
    │
    ▼
Trusted Lambda (validates, hashes password)
    │
    │ Stores in DynamoDB
    │
    ▼
Trusted DynamoDB (IAM protected)
    │
    │ Returns user data
    │
    ▼
Trusted Lambda (generates JWT)
    │
    │ Returns token
    │
    ▼
Untrusted User (stores token in localStorage)
```

### Data Access Flow

```
Untrusted User (with JWT token)
    │
    │ Sends request with token
    │
    ▼
Trusted Lambda (validates JWT, extracts username)
    │
    │ Queries DynamoDB with username as householdId
    │
    ▼
Trusted DynamoDB (returns only user's data)
    │
    │ Application ensures: householdId = username
    │
    ▼
Trusted Lambda (returns data)
    │
    │ Sends to user
    │
    ▼
Untrusted User (receives only their own data)
```

## Trust Violation Detection

### Monitoring

1. **CloudWatch Alarms**:
   - Lambda errors (may indicate attack)
   - Unusual request patterns
   - Throttling events

2. **CloudTrail Logs**:
   - All API calls logged
   - IAM policy violations logged
   - Unusual access patterns

3. **Application Logs**:
   - Authentication failures
   - Authorization failures
   - Invalid token attempts

### Response to Trust Violations

1. **Immediate**:
   - Block suspicious IPs (if detected)
   - Rotate JWT secret (if compromised)
   - Revoke user tokens (if user compromised)

2. **Investigation**:
   - Review CloudTrail logs
   - Analyze attack patterns
   - Identify compromised accounts

3. **Remediation**:
   - Update security policies
   - Patch vulnerabilities
   - Notify affected users

## Trust Assumptions for MVP

### Acceptable for MVP

1. **Password Hashing**: SHA-256 (upgrade to bcrypt for production)
2. **CORS**: Open to all origins (restrict in production)
3. **Rate Limiting**: Not implemented (add for production)
4. **Token Refresh**: Not implemented (tokens expire, users re-login)
5. **Multi-Factor Authentication**: Not implemented

### Production Requirements

1. **Password Hashing**: bcrypt with salt
2. **CORS**: Restricted to specific domains
3. **Rate Limiting**: Per-user and per-IP
4. **Token Refresh**: Automatic token refresh mechanism
5. **MFA**: Optional multi-factor authentication
6. **Audit Logging**: Enhanced logging for compliance
7. **Data Encryption**: Encryption at rest (DynamoDB encryption)

## Trust Model Summary

| Component | Trust Level | Protection | Residual Risk |
|-----------|-------------|------------|---------------|
| Public Internet | Untrusted | HTTPS, JWT validation | Medium |
| API Gateway | Trusted | AWS managed, IAM | Low |
| Lambda Function | Trusted | IAM, code review | Low |
| DynamoDB | Trusted | IAM, data isolation | Low |
| Frontend | Untrusted | Server-side validation | Medium |
| User Input | Untrusted | Validation, sanitization | Medium |

## Compliance Considerations

### Data Privacy

- **User Data**: Stored in DynamoDB, isolated by username
- **Password Storage**: Hashed, never plain text
- **Data Access**: Only through authenticated API
- **Data Retention**: No automatic deletion (can be added)

### Regional Compliance

- **Data Residency**: All data in us-west-2 (can be configured)
- **GDPR**: Not fully compliant (no data export/deletion API)
- **PIPEDA**: Basic compliance (data stored in Canada-friendly region)

### Audit Trail

- **CloudTrail**: All AWS API calls logged
- **Application Logs**: Authentication and authorization events
- **CloudWatch**: Metrics and alarms for security events

---

## Trust Model Validation

### Testing Trust Boundaries

1. **Authentication Bypass**: Attempt to access API without token → Should fail
2. **Cross-User Access**: Attempt to access another user's data → Should fail
3. **Token Manipulation**: Modify JWT token → Should fail validation
4. **SQL Injection**: Not applicable (NoSQL)
5. **XSS**: Test input sanitization → Should be safe

### Trust Model Maintenance

- Review quarterly
- Update when adding new features
- Validate assumptions through security testing
- Document any trust boundary changes

