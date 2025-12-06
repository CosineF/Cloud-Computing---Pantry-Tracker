# Architecture Decision Records (ADRs)

This document records significant architectural decisions made for the Cloud Pantry Tracker project.

## ADR-001: Serverless Architecture Choice

**Status**: Accepted  
**Date**: 2024-12-02  
**Deciders**: Development Team

### Context
We needed to choose between:
- Traditional server-based architecture (EC2, containers)
- Serverless architecture (Lambda, API Gateway)
- Hybrid approach

### Decision
We chose a **serverless architecture** using AWS Lambda, API Gateway, and DynamoDB.

### Rationale
1. **Cost Efficiency**: Pay only for actual usage, no idle server costs
2. **Scalability**: Automatic scaling without manual intervention
3. **Simplicity**: No server management, patching, or infrastructure maintenance
4. **MVP Focus**: Faster development and deployment for capstone project
5. **AWS Free Tier**: Significant cost savings during development

### Consequences
**Positive**:
- Low operational overhead
- Automatic scaling
- Cost-effective for MVP
- Fast deployment

**Negative**:
- Cold start latency (2-3 seconds for first request)
- Vendor lock-in to AWS
- Limited control over execution environment
- Debugging can be more complex

### Alternatives Considered
- **EC2 + RDS**: More control but higher cost and maintenance
- **ECS/Fargate**: Better for long-running processes, overkill for API
- **Hybrid**: Added complexity without clear benefits for MVP

---

## ADR-002: DynamoDB vs Relational Database

**Status**: Accepted  
**Date**: 2024-12-02  
**Deciders**: Development Team

### Context
We needed to choose a database for storing inventory and user data.

### Decision
We chose **DynamoDB** (NoSQL) over a relational database (RDS/PostgreSQL).

### Rationale
1. **Serverless Integration**: Native integration with Lambda
2. **Auto-Scaling**: Built-in capacity management
3. **Simple Data Model**: Our data model is simple (users, items)
4. **Cost**: PAY_PER_REQUEST model is cost-effective for variable traffic
5. **Performance**: Single-digit millisecond latency
6. **No SQL Management**: No database server to manage

### Consequences
**Positive**:
- Simple data model fits our needs
- Excellent performance
- Automatic scaling
- Low operational overhead

**Negative**:
- Limited query flexibility (no complex joins)
- Partition key design is critical
- Cost can spike with high traffic (mitigated with auto-scaling)

### Alternatives Considered
- **RDS PostgreSQL**: More query flexibility but requires server management
- **Aurora Serverless**: Good option but more expensive and complex
- **MongoDB Atlas**: Similar to DynamoDB but less AWS-native

---

## ADR-003: JWT Authentication vs API Keys

**Status**: Accepted  
**Date**: 2024-12-02  
**Deciders**: Development Team

### Context
We needed to choose an authentication mechanism for the API.

### Decision
We chose **JWT (JSON Web Tokens)** over simple API keys.

### Rationale
1. **User-Specific**: Each user has their own credentials
2. **Stateless**: No server-side session storage needed
3. **Scalable**: Works well with serverless architecture
4. **Security**: Tokens expire (7 days), can be revoked
5. **User Isolation**: Each user can only access their own data
6. **Industry Standard**: Well-understood and widely used

### Consequences
**Positive**:
- Better security than shared API key
- User data isolation
- Stateless (works with Lambda)
- Token expiration provides security

**Negative**:
- More complex than API keys
- Token management in frontend
- Need to handle token refresh (future enhancement)

### Alternatives Considered
- **API Key**: Simple but insecure (anyone with key can access all data)
- **AWS Cognito**: More features but adds complexity and cost
- **OAuth 2.0**: Overkill for MVP, adds complexity

---

## ADR-004: Password Hashing: SHA-256 vs bcrypt

**Status**: Accepted (with future improvement noted)  
**Date**: 2024-12-02  
**Deciders**: Development Team

### Context
We needed to choose a password hashing algorithm.

### Decision
We chose **SHA-256** for MVP, with plan to upgrade to **bcrypt** for production.

### Rationale
1. **MVP Simplicity**: SHA-256 is simple and sufficient for MVP
2. **No External Dependencies**: Built into Python standard library
3. **Fast Implementation**: Quick to implement for capstone
4. **Future Improvement**: Documented plan to use bcrypt for production

### Consequences
**Positive**:
- Simple implementation
- No additional dependencies
- Fast for MVP development

**Negative**:
- Less secure than bcrypt (no salt, fast to crack)
- Not production-ready for sensitive data
- Will need migration for production use

### Future Improvement
For production, migrate to bcrypt:
- Slower hashing (intentional, prevents brute force)
- Built-in salt
- Industry standard for password hashing

---

## ADR-005: DynamoDB Billing: PAY_PER_REQUEST vs PROVISIONED

**Status**: Accepted  
**Date**: 2024-12-02  
**Deciders**: Development Team

### Context
We needed to choose DynamoDB billing mode for the inventory table.

### Decision
We chose **PROVISIONED with auto-scaling** (5-100 RCU/WCU) over PAY_PER_REQUEST.

### Rationale
1. **Cost Predictability**: More predictable costs than PAY_PER_REQUEST
2. **Auto-Scaling**: Handles traffic spikes automatically
3. **Reliability**: Prevents throttling with proper capacity planning
4. **Monitoring**: Better visibility into capacity utilization
5. **Production-Ready**: More suitable for production workloads

### Consequences
**Positive**:
- Predictable costs
- Automatic scaling prevents throttling
- Better for production
- Cost-effective for steady traffic

**Negative**:
- Higher baseline cost ($2.34/month vs $0.15/month idle)
- Need to monitor capacity
- More complex than PAY_PER_REQUEST

### Alternatives Considered
- **PAY_PER_REQUEST**: Lower idle cost but unpredictable under surge
- **Fixed Provisioned**: No auto-scaling, manual capacity management

---

## ADR-006: Frontend: Framework vs Vanilla JavaScript

**Status**: Accepted  
**Date**: 2024-12-02  
**Deciders**: Development Team

### Context
We needed to choose frontend technology.

### Decision
We chose **Vanilla JavaScript** (no framework) over React/Vue/Angular.

### Rationale
1. **Simplicity**: No build process, no dependencies
2. **MVP Focus**: Fast development, minimal complexity
3. **Static Hosting**: Easy to deploy anywhere (S3, Netlify, etc.)
4. **Learning Curve**: Team familiar with vanilla JS
5. **Bundle Size**: No framework overhead

### Consequences
**Positive**:
- Simple and fast to develop
- Easy to deploy
- No build process
- Small bundle size

**Negative**:
- More code for complex interactions
- No component reusability
- Manual state management
- Less maintainable at scale

### Alternatives Considered
- **React**: More features but adds complexity and build process
- **Vue**: Lighter than React but still adds complexity
- **Svelte**: Modern but less familiar to team

---

## ADR-007: Monitoring: CloudWatch vs Third-Party

**Status**: Accepted  
**Date**: 2024-12-02  
**Deciders**: Development Team

### Context
We needed to choose monitoring and observability solution.

### Decision
We chose **AWS CloudWatch** (native) over third-party solutions (Datadog, New Relic).

### Rationale
1. **Native Integration**: Built into AWS, no additional setup
2. **Cost**: Included in AWS ecosystem, reasonable pricing
3. **Lambda Insights**: Native support for Lambda monitoring
4. **Alarms**: Integrated with SNS for alerting
5. **No Vendor Lock-in Risk**: Already using AWS

### Consequences
**Positive**:
- Native AWS integration
- Good Lambda support
- Reasonable cost
- Easy to set up

**Negative**:
- Less feature-rich than specialized tools
- UI can be clunky
- Log analysis requires CloudWatch Logs Insights

### Alternatives Considered
- **Datadog**: More features but additional cost and complexity
- **New Relic**: Better APM but overkill for MVP
- **Prometheus + Grafana**: Open source but requires infrastructure

---

## ADR-008: Error Handling: Fail-Fast vs Graceful Degradation

**Status**: Accepted  
**Date**: 2024-12-02  
**Deciders**: Development Team

### Context
We needed to decide on error handling strategy.

### Decision
We chose **Fail-Fast with Clear Error Messages** over graceful degradation.

### Rationale
1. **Simplicity**: Easier to implement and debug
2. **User Clarity**: Users know immediately if something is wrong
3. **MVP Scope**: Limited features, less need for degradation
4. **Reliability**: Better to fail clearly than degrade silently

### Consequences
**Positive**:
- Clear error messages for users
- Easier debugging
- Simple implementation

**Negative**:
- No partial functionality during failures
- Users see errors instead of degraded experience

### Future Improvement
For production, consider:
- Retry logic with exponential backoff
- Circuit breaker pattern
- Graceful degradation for non-critical features

---

## ADR-009: Data Model: Username as Household ID

**Status**: Accepted  
**Date**: 2024-12-02  
**Deciders**: Development Team

### Context
We needed to decide how to model user data and household relationships.

### Decision
We use **username as householdId** (one user = one household) instead of separate household management.

### Rationale
1. **Simplicity**: Simplest data model for MVP
2. **User Isolation**: Natural data isolation per user
3. **No Complex Relationships**: No need for user-household mapping
4. **Future Extensibility**: Can add household sharing later

### Consequences
**Positive**:
- Simple data model
- Natural user isolation
- Easy to implement
- Clear data boundaries

**Negative**:
- No multi-user households (future feature)
- Each user has separate inventory
- Will need migration if adding household sharing

### Future Improvement
To support multi-user households:
- Add `Households` table
- Add `HouseholdMembers` table
- Update inventory queries to support householdId from membership

---

## ADR-010: Deployment: SAM vs Manual CloudFormation

**Status**: Accepted  
**Date**: 2024-12-02  
**Deciders**: Development Team

### Context
We needed to choose infrastructure as code tool.

### Decision
We chose **AWS SAM (Serverless Application Model)** over manual CloudFormation.

### Rationale
1. **Serverless Optimized**: Designed specifically for serverless applications
2. **Simpler Syntax**: Less verbose than raw CloudFormation
3. **Local Testing**: `sam local` for testing Lambda locally
4. **Best Practices**: Enforces serverless best practices
5. **Team Familiarity**: Easier to learn than raw CloudFormation

### Consequences
**Positive**:
- Simpler template syntax
- Local testing capability
- Serverless-focused
- Good documentation

**Negative**:
- Less flexible than raw CloudFormation
- Additional tool to learn
- SAM CLI dependency

### Alternatives Considered
- **Terraform**: More flexible but adds complexity
- **CDK**: More powerful but steeper learning curve
- **Manual CloudFormation**: More control but verbose

---

## ADR-011: Auto-Scaling Strategy: Target Tracking vs Step Scaling

**Status**: Accepted  
**Date**: 2024-12-02  
**Deciders**: Development Team

### Context
We needed to choose DynamoDB auto-scaling policy type.

### Decision
We chose **Target Tracking Scaling** (70% utilization) over Step Scaling.

### Rationale
1. **Simplicity**: Single target value, easier to configure
2. **Automatic**: AWS manages scaling decisions
3. **Smooth Scaling**: Gradual capacity changes
4. **Industry Standard**: Common pattern for DynamoDB

### Consequences
**Positive**:
- Simple configuration
- Automatic scaling decisions
- Smooth capacity changes
- Prevents throttling

**Negative**:
- Less control over scaling behavior
- May scale too aggressively or conservatively
- Need to tune target value

### Configuration
- **Target**: 70% capacity utilization
- **Min Capacity**: 5 RCU/WCU
- **Max Capacity**: 100 RCU/WCU
- **Scale-Out Cooldown**: 60 seconds (default)
- **Scale-In Cooldown**: 300 seconds (default)

---

## Summary

| ADR | Decision | Key Rationale |
|-----|----------|----------------|
| ADR-001 | Serverless Architecture | Cost, scalability, simplicity |
| ADR-002 | DynamoDB | Serverless integration, auto-scaling |
| ADR-003 | JWT Authentication | User-specific, stateless, secure |
| ADR-004 | SHA-256 (MVP) | Simplicity, upgrade to bcrypt later |
| ADR-005 | PROVISIONED + Auto-scaling | Cost predictability, reliability |
| ADR-006 | Vanilla JavaScript | Simplicity, no build process |
| ADR-007 | CloudWatch | Native integration, reasonable cost |
| ADR-008 | Fail-Fast | Simplicity, clear errors |
| ADR-009 | Username = HouseholdId | Simple data model |
| ADR-010 | AWS SAM | Serverless-optimized, simpler syntax |
| ADR-011 | Target Tracking | Simplicity, automatic scaling |

