# Cloud Pantry Tracker: Capstone Final Report

**Authors**: Jacob Wu (jwu100), Kexin (Cosine) Feng (kfeng11)  
**Course**: CPSC 436C - Cloud Computing  
**Date**: 05 December 2025  
**Repository**: [Repository link](https://github.students.cs.ubc.ca/CPSC436C-2025W-T1/jwu100-kfeng11-capstone)

---

## Executive Summary

Cloud Pantry Tracker is a serverless inventory management application designed for multi-person households to track shared pantry items in real time. Built on AWS Lambda, API Gateway, and DynamoDB, the system provides a cost-effective, scalable solution that prioritizes user privacy and data isolation. This report summarizes the problem framing, architectural decisions, privacy guardrails, reliability measures, and lessons learned. Detailed documentation is available in the repository's `docs/` directory.

---

## 1. Problem & Stakeholders

### 1.1 Problem Narrative

Shared households face a common challenge: pantry state information lives in fragmented, unreliable sources (sticky notes, group chats, individual memories), leading to double purchases, stockouts, and coordination overhead as grocery duties are handed off between roommates, partners, caregivers, and mutual-aid volunteers.

The solution must be easy to use on borrowed devices, privacy-preserving, reliable for time-sensitive decisions, and accessible to users with varying technical literacy and connectivity.

**Reference**: See `docs/STAKEHOLDER-STORY.md` for detailed problem narrative and stakeholder analysis.

### 1.2 Stakeholder Map

Our primary stakeholders include:
- **Primary household shoppers**: Need accurate inventory with protection from cross-household access
- **Invited helpers**: Need temporary access without oversharing identity
- **Operators**: Need operational signals without peeking at pantry contents

**Reference**: Complete stakeholder map with needs, decisions, and blocked harms in `docs/STAKEHOLDER-STORY.md`.

### 1.3 Empty Chairs

We kept seats open for:
1. **Low-bandwidth roommate/caregiver** on shared devices (drove auth scoping and redacted telemetry)
2. **Visually impaired user** relying on screen readers (planned accessibility work)
3. **Non-English speaker** or low-literacy user (planned localization)

**Reference**: Detailed empty chair analysis in `docs/STAKEHOLDER-STORY.md`; planned work in `docs/ETHICS-DEBT.md`.

### 1.4 Success Metrics

- **Functional**: Users can add, view, and remove items (see `frontend/app.js`, `backend/lambda_function.py`)
- **Privacy**: Zero cross-household data access (enforced by `backend/test_privacy_cct.py`)
- **Reliability**: 99.5% uptime, < 1% error rate (see `docs/SLO-ALERT-CONFIG.md`)
- **Cost**: < $50/month normal, < $100/month max (see `docs/COST-MODELING-WORKSHEET.md`)
- **Performance**: P50 < 200ms, P95 < 500ms (validated via `load-test.sh`)

---

## 2. Architecture & Trade-offs

### 2.1 Final Architecture

The system follows a serverless architecture: Frontend (static HTML/JS) → API Gateway → Lambda Function → DynamoDB, with CloudWatch monitoring and SNS alerting.

**Reference**: Complete architecture diagrams (text and Mermaid) in `docs/ARCHITECTURE-DIAGRAM.md`. Infrastructure definition in `template.yaml`.

### 2.2 Key Architectural Decisions

We documented 11 major architectural decisions in `docs/ADRs.md`. Key decisions include:

1. **ADR-001: Serverless Architecture (Lambda vs EC2)**
   - **Decision**: AWS Lambda over EC2
   - **Rationale**: 68-100% cost savings, automatic scaling, no idle costs
   - **Reference**: `docs/ADRs.md#ADR-001`, cost comparison in `docs/COST-MODELING-WORKSHEET.md`

2. **ADR-002: DynamoDB vs Relational Database**
   - **Decision**: DynamoDB (NoSQL) over RDS/PostgreSQL
   - **Rationale**: Serverless integration, auto-scaling, simple data model
   - **Reference**: `docs/ADRs.md#ADR-002`, schema in `docs/API-SCHEMA.md`

3. **ADR-003: JWT Authentication vs API Keys**
   - **Decision**: JWT tokens over API keys
   - **Rationale**: User-specific credentials, stateless, better security
   - **Reference**: `docs/ADRs.md#ADR-003`, implementation in `backend/lambda_function.py`

4. **ADR-005: DynamoDB Billing (PROVISIONED vs PAY_PER_REQUEST)**
   - **Decision**: PROVISIONED with auto-scaling (5-100 RCU/WCU)
   - **Rationale**: Cost predictability (9.4x vs 89x surge multiplier)
   - **Reference**: `docs/ADRs.md#ADR-005`, cost analysis in `docs/COST-MODELING-WORKSHEET.md`

**All ADRs**: See `docs/ADRs.md` for complete context, rationale, consequences, and alternatives for all 11 decisions.

### 2.3 Alternatives Considered

Each ADR documents alternatives considered. Key rejections:
- **EC2 + RDS**: Higher cost and operational overhead (see `docs/COST-MODELING-WORKSHEET.md`)
- **API Keys**: Security concerns (anyone with key can access all data)
- **PAY_PER_REQUEST DynamoDB**: Cost unpredictability (89x surge multiplier)

**Reference**: Alternatives documented in each ADR in `docs/ADRs.md`.

### 2.4 Architecture Evolution

**Initial MVP Design** (Project 3): API key auth, PAY_PER_REQUEST DynamoDB, minimal monitoring.

**Final Production Design**: JWT auth, PROVISIONED DynamoDB with auto-scaling, comprehensive monitoring (6 CloudWatch alarms, Lambda Insights), kill switches, incident response runbook.

**Key Changes**: Upgraded authentication (`docs/AUTHENTICATION-UPDATE.md`), added auto-scaling (`template.yaml`), implemented monitoring (`docs/SLO-ALERT-CONFIG.md`), documented runbooks (`docs/DR-RUNBOOK.md`).

**Reference**: Architecture evolution documented in `docs/ARCHITECTURE-DIAGRAM.md`; implementation in `template.yaml`, `backend/lambda_function.py`.

---

## 3. Clause→Control→Test & Ethics

### 3.1 Critical Privacy Clauses

Our system makes three critical privacy promises, each enforced by code controls and automated tests:

1. **Inventory Actions Stay Within Caller's Household**
   - **Clause**: Users cannot write into or read another household by spoofing IDs
   - **Control**: Lambda derives `householdId` from JWT username, ignores request body
   - **Test**: `test_inventory_actions_bound_to_token_identity` in `backend/test_privacy_cct.py`
   - **Status**: ✅ Red-bar passing

2. **Expired or Forged Credentials Cannot Access Data**
   - **Clause**: Expired/forged credentials cannot fetch or mutate inventory
   - **Control**: `verify_token` rejects expired JWTs before database operations
   - **Test**: `test_expired_token_denied_before_database_access` in `backend/test_privacy_cct.py`
   - **Status**: ✅ Red-bar passing

3. **Credentials Never Leave Auth Boundary in Plaintext**
   - **Clause**: Credentials never leave auth boundary in plaintext
   - **Control**: Signup hashes password before storage, omits from responses
   - **Test**: `test_signup_hashes_and_never_echoes_password` in `backend/test_privacy_cct.py`
   - **Status**: ✅ Red-bar passing

**Reference**: Complete CCT documentation in `docs/CCT.md`; implementation in `backend/lambda_function.py`; tests in `backend/test_privacy_cct.py`.

### 3.2 Ethics Ledger Snapshot

Our ethics ledger tracks known privacy and ethics debts with risk assessments, resolutions, and target dates.

**Key Debts**:
- Stronger password protection (SHA-256 → bcrypt): Planned next sprint
- Token lifetime review (7-day → 24h TTL): Planned next sprint
- Telemetry PII minimization: In progress
- Rate limiting: Planned this sprint
- Accessibility (ARIA, keyboard nav): Backlog

**Reference**: Complete ethics ledger with all debts, risks, resolutions, and status in `docs/ETHICS-DEBT.md`.

### 3.3 Telemetry Matrix

Our telemetry discipline ensures we collect only the minimum operational signals needed, with explicit privacy guardrails for each event type.

**Key Principles**: Minimize, de-identify, bound storage (14-day operational, 30-day security), no monetization.

**Changes Since Project 3**: Added structured telemetry matrix, implemented hashing for identifiers, documented retention policies, planned CI/PR linting.

**Reference**: Complete telemetry matrix with all events, fields, purposes, and guardrails in `docs/TELEMETRY-DISCIPLINE.md`.

---

## 4. Reliability, Cost, and Operability

### 4.1 Load Testing & Chaos Engineering

**Load Testing Results**:
- **Tool**: `load-test.sh` (custom bash script)
- **Scenarios**: Baseline (10 users), Moderate (50 users), High (100 users)
- **Findings**: System handles 10x traffic surge, auto-scaling works as designed, error rates < 1%

**Chaos Testing Scenarios**:
- Lambda function failure: Alarm fires in 2 minutes, system recovers
- DynamoDB throttling: Auto-scaling handles capacity issues
- Concurrency limit: Kill switch prevents cost explosions

**Reference**: Complete load test results and chaos engineering scenarios in `docs/CHAOS-LOAD-TEST-NOTES.md`; test script in `load-test.sh`.

### 4.2 SLO Attainment

**Target SLOs**: Availability 99.5%, Latency P50 < 200ms, P95 < 500ms, Error Rate < 1%

**Actual Performance**: ✅ 99.8% availability, ~150ms P50, ~450ms P95, 0.2% error rate (all exceed targets)

**CloudWatch Alarms**: 6 alarms configured (Lambda errors/throttles/duration, DynamoDB throttles, API Gateway 5xx) with PagerDuty and email notifications.

**Reference**: SLO targets and alarm configuration in `docs/SLO-ALERT-CONFIG.md`; alarm definitions in `template.yaml`; reliability summary in `docs/RELIABILITY-SCALABILITY-SUMMARY.md`.

### 4.3 Cost Model Updates

**Design Decision**: Selected Design B (Production-Ready) over Design A (Minimal MVP).

**Cost Comparison**: Design B costs $4/month idle vs $0.15/month (Design A), but provides 9.4x surge multiplier vs 89x (much more predictable) and full reliability features.

**Decision Rationale**: Meets rubric requirements, fits budget ($50/month target), better predictability, reduces operational overhead, validated through testing.

**Actual Costs**: ~$4/month idle (matches Design B estimate).

**Cost Controls**: Lambda reserved concurrency (100), DynamoDB max capacity (100 RCU/WCU), kill switch scripts (`kill-switch.sh`, `restore-capacity.sh`), cost monitoring (`cost-monitor.sh`).

**Why Lambda vs EC2**: Lambda saves 68-100% compared to EC2 ($0 when idle vs $7.50/month minimum).

**Reference**: Complete cost analysis with idle vs surge scenarios, Lambda vs EC2 comparison, and decision rationale in `docs/COST-MODELING-WORKSHEET.md`.

### 4.4 Runbook Insights

Our incident response playbook covers four critical scenarios: cost spike, DynamoDB throttling, Lambda function errors, and security incidents.

**Key Learnings**: Automated monitoring (2-minute detection), auto-scaling prevents most incidents, kill switches provide emergency cost control, runbooks reduce MTTR.

**Incident Response Workflow**: Detection → Assessment → Mitigation → Resolution → Post-Incident (documented in runbook).

**Reference**: Complete incident response procedures, recovery steps, and runbook in `docs/DR-RUNBOOK.md`; kill switch scripts in `kill-switch.sh`, `restore-capacity.sh`.

---

## 5. Learning & Next Steps

### 5.1 Changes After Peer Design & Formative Feedback

**Initial Design (Project 3)**: API key auth, PAY_PER_REQUEST DynamoDB, minimal monitoring, no auto-scaling.

**Feedback Received**: Need better authentication, cost model for surge scenarios, monitoring/alerting, auto-scaling.

**Changes Implemented**:
1. **Authentication Upgrade**: API keys → JWT tokens (`docs/AUTHENTICATION-UPDATE.md`, `backend/lambda_function.py`)
2. **Cost Model Refinement**: Design A vs B analysis, implemented Design B (`docs/COST-MODELING-WORKSHEET.md`)
3. **Monitoring & Alerting**: 6 CloudWatch alarms, Lambda Insights, SNS integration (`template.yaml`, `docs/SLO-ALERT-CONFIG.md`)
4. **Auto-Scaling**: DynamoDB auto-scaling 5-100 RCU/WCU (`template.yaml`)

**Impact**: System is now production-ready with proper reliability, monitoring, and cost controls.

### 5.2 GenAI Assistance & Citations

**AI Tools Used**: Cursor AI (Auto) for code generation and documentation, Claude (Anthropic) for design review.

**Key AI Contributions**:
1. Architecture design guidance (Lambda vs EC2 cost comparison)
2. Code implementation (JWT authentication, Lambda function structure)
3. Documentation templates (ADR format, report structure)
4. Cost modeling analysis (DynamoDB billing comparison)

**AI Usage Disclosure**: All AI-generated code was reviewed and tested. AI suggestions were evaluated against requirements. Final decisions made by development team.

**External Citations**:
- AWS Lambda Pricing: https://aws.amazon.com/lambda/pricing/
- DynamoDB Pricing: https://aws.amazon.com/dynamodb/pricing/
- JWT Best Practices: https://jwt.io/introduction
- CloudWatch Alarms: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html

**Reference**: Detailed AI collaboration log documenting prompts, design alternatives, red-team analysis, and inflection points in `docs/AI-COLLABORATION-LOG.md`. All AI-generated code was reviewed and tested before use.

### 5.3 What We Would Tackle Next

**Short-term (Next Sprint)**: Password security (SHA-256 → bcrypt), token lifetime (7-day → 24h), rate limiting, telemetry linting.

**Medium-term (Next Quarter)**: Accessibility (ARIA, keyboard nav), localization, offline support, user data deletion.

**Long-term (Future Enhancements)**: Multi-user households, expiry date tracking, shopping list generation, mobile app, image recognition (with privacy constraints).

**Reference**: Planned work documented in `docs/ETHICS-DEBT.md`; future enhancements in `docs/README.md`; monetization plan in `docs/MONETIZATION-PLAN.md`.

---

## 6. Conclusion

Cloud Pantry Tracker successfully delivers a production-ready serverless inventory management system that balances functionality, privacy, reliability, and cost. Key achievements:

1. **Privacy-First Design**: Automated tests ensure zero cross-household data access
2. **Cost-Effective Architecture**: Lambda saves 68-100% compared to EC2
3. **Reliable Operations**: Auto-scaling, monitoring, and alerting ensure 99.8% availability
4. **Production-Ready**: Comprehensive runbooks, kill switches, and incident response procedures

The system meets all capstone requirements while maintaining a clear path for future improvements in security, accessibility, and functionality.

---

## Appendix A: Repository Structure

Complete repository structure with all files:

**Backend**:
- `backend/lambda_function.py` - Main Lambda handler with authentication and inventory operations
- `backend/requirements.txt` - Python dependencies (boto3, PyJWT, bcrypt)
- `backend/test_privacy_cct.py` - Privacy clause tests (CCT enforcement)

**Frontend**:
- `frontend/index.html` - Main inventory UI
- `frontend/login.html` - Authentication UI (signup/login)
- `frontend/app.js` - Frontend logic for inventory operations
- `frontend/auth.js` - Authentication handling (JWT token management)
- `frontend/styles.css` - UI styling
- `frontend/config.js` - API configuration (git-ignored)
- `frontend/config.example.js` - Configuration template
- `frontend/index-mock.html`, `frontend/app-mock.js` - Mock frontend for local testing

**Documentation** (`docs/`):
- `ARCHITECTURE-DIAGRAM.md` - System architecture (text and Mermaid diagrams)
- `ADRs.md` - 11 architectural decision records
- `TRUST-MODEL.md` - Security boundaries and threat model
- `API-SCHEMA.md` - Complete API and data schema documentation
- `CCT.md` - Clause→Control→Test documentation
- `ETHICS-DEBT.md` - Ethics ledger snapshot
- `TELEMETRY-DISCIPLINE.md` - Telemetry matrix and privacy guardrails
- `SLO-ALERT-CONFIG.md` - Service level objectives and alert configuration
- `DR-RUNBOOK.md` - Disaster recovery and incident response procedures
- `COST-MODELING-WORKSHEET.md` - Cost analysis (idle vs surge, Lambda vs EC2)
- `CHAOS-LOAD-TEST-NOTES.md` - Load testing and chaos engineering notes
- `IDEMPOTENCY-PLAN.md` - Idempotency strategy
- `RELIABILITY-SCALABILITY-SUMMARY.md` - Reliability features summary
- `STAKEHOLDER-STORY.md` - Problem narrative and stakeholder analysis
- `AI-COLLABORATION-LOG.md` - Socratic log of AI collaboration and decision inflection points
- `README.md` - Setup and deployment instructions
- `TESTING.md` - Comprehensive testing guide
- `TESTING-QUICKSTART.md` - Quick testing reference
- `AWS-SETUP.md` - AWS CLI and credentials setup
- `AUTHENTICATION-UPDATE.md` - JWT authentication implementation guide
- `README-CONFIG.md` - Configuration file guide
- `CALLOUTS.md` - Feature callouts and future enhancements
- `MONETIZATION-PLAN.md` - Monetization strategy

**Infrastructure**:
- `template.yaml` - AWS SAM template (Lambda, DynamoDB, API Gateway, CloudWatch alarms, auto-scaling)
- `samconfig.toml` - SAM CLI configuration

**Scripts**:
- `smoke-test.sh` - Quick deployment verification (5 tests)
- `load-test.sh` - Load testing script (concurrent users, requests)
- `test-api.sh` - API testing script (full CRUD operations)
- `kill-switch.sh` - Emergency cost control (reduce capacity)
- `restore-capacity.sh` - Restore normal capacity after kill switch
- `cost-monitor.sh` - Daily/monthly cost monitoring
- `verify-setup.sh` - Setup verification (SAM CLI, Python, Docker, AWS CLI)
- `configure-aws.sh` - AWS configuration helper

**Testing**:
- `events/get-inventory-event.json` - Sample event for local Lambda testing
- `events/add-item-event.json` - Sample event for adding items
- `events/remove-item-event.json` - Sample event for removing items
- `TESTING-AUTH.md` - Authentication testing guide

**Other**:
- `SYSTEM-DESIGN-INDEX.md` - Index of all system design artifacts

## Appendix B: Key Metrics Summary

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Availability | 99.5% | 99.8% | ✅ Exceeds |
| Latency P50 | < 200ms | ~150ms | ✅ Meets |
| Latency P95 | < 500ms | ~450ms | ✅ Meets |
| Error Rate | < 1% | 0.2% | ✅ Meets |
| Monthly Cost (Idle) | < $50 | ~$4 | ✅ Well below |
| Monthly Cost (Surge) | < $100 | ~$38 | ✅ Meets |

**Reference**: Metrics validated via `load-test.sh` and CloudWatch monitoring; SLO targets in `docs/SLO-ALERT-CONFIG.md`.

## Appendix C: Complete File References

### Core Implementation
- `backend/lambda_function.py` - Main Lambda handler (auth, inventory CRUD)
- `backend/requirements.txt` - Dependencies (boto3, PyJWT, bcrypt)
- `backend/test_privacy_cct.py` - Privacy clause tests
- `frontend/index.html` - Main UI
- `frontend/login.html` - Auth UI
- `frontend/app.js` - Frontend logic
- `frontend/auth.js` - JWT token management
- `frontend/styles.css` - Styling
- `template.yaml` - Infrastructure as code

### System Design
- `docs/ARCHITECTURE-DIAGRAM.md` - Architecture diagrams
- `docs/ADRs.md` - 11 architectural decisions
- `docs/TRUST-MODEL.md` - Security boundaries
- `docs/API-SCHEMA.md` - API documentation
- `docs/SYSTEM-DESIGN-INDEX.md` - Design artifacts index

### Privacy & Ethics
- `docs/CCT.md` - Clause→Control→Test
- `docs/ETHICS-DEBT.md` - Ethics ledger
- `docs/TELEMETRY-DISCIPLINE.md` - Telemetry matrix
- `docs/STAKEHOLDER-STORY.md` - Problem and stakeholders

### Reliability & Operations
- `docs/SLO-ALERT-CONFIG.md` - SLOs and alerts
- `docs/DR-RUNBOOK.md` - Incident response
- `docs/RELIABILITY-SCALABILITY-SUMMARY.md` - Reliability features
- `docs/IDEMPOTENCY-PLAN.md` - Idempotency strategy
- `docs/CHAOS-LOAD-TEST-NOTES.md` - Testing notes

### Cost & Operability
- `docs/COST-MODELING-WORKSHEET.md` - Cost analysis
- `kill-switch.sh` - Emergency cost control
- `restore-capacity.sh` - Capacity restoration
- `cost-monitor.sh` - Cost monitoring

### Testing & Deployment
- `docs/TESTING.md` - Testing guide
- `docs/TESTING-QUICKSTART.md` - Quick reference
- `smoke-test.sh` - Deployment verification
- `load-test.sh` - Load testing
- `test-api.sh` - API testing
- `events/*.json` - Sample events for local testing

### Setup & Configuration
- `docs/README.md` - Setup instructions
- `docs/AWS-SETUP.md` - AWS CLI setup
- `docs/AUTHENTICATION-UPDATE.md` - Auth implementation
- `docs/README-CONFIG.md` - Configuration guide
- `verify-setup.sh` - Setup verification
- `configure-aws.sh` - AWS configuration

### AI Collaboration
- `docs/AI-COLLABORATION-LOG.md` - Socratic log of AI collaboration, design alternatives, and decision inflection points

### Other
- `docs/CALLOUTS.md` - Feature callouts
- `docs/MONETIZATION-PLAN.md` - Monetization strategy
- `samconfig.toml` - SAM configuration

---

**End of Report**

