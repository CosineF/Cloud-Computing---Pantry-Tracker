# AI Collaboration Log (Socratic Log)

Purpose: Make AI use accountable and generative. Log the moments that changed your mind—not the entire chat.

---

## Sprint 1: Architecture & Cost Decisions

### Context
Initial design phase: choosing between serverless (Lambda) and traditional servers (EC2), and selecting authentication mechanism.

### Prompt A (Design Alternatives)
**"Compare Lambda vs EC2 cost efficiency for a low-traffic API with variable usage patterns. Should we use serverless or traditional servers?"**

**AI Response**: Provided detailed cost breakdown showing:
- EC2: $7.50/month minimum (always running, even with 0 requests)
- Lambda: $0/month idle, ~$0.40/month for 100K requests/day
- Savings: 68-100% for variable traffic patterns

**Option Tested**: Analyzed idle vs surge scenarios, calculated actual costs for both architectures.

**Evidence**: `docs/COST-MODELING-WORKSHEET.md` (lines 5-128), `docs/ADRs.md#ADR-001`

**Outcome**: Chose Lambda architecture. Validated through cost modeling worksheet showing 100% savings at idle, 68-100% savings overall. This decision shaped the entire serverless architecture.

---

### Prompt B (Red-Team)
**"What are the security risks of using a single API key for all users? What if someone gets the key?"**

**AI Response**: Identified critical security flaw:
- Single API key = anyone with key can access ALL user data
- No user-level isolation
- No way to revoke access per user
- Violates privacy requirements (cross-household access)

**Risk Checked**: Reviewed authentication requirements, privacy clauses, and stakeholder needs.

**Evidence**: `docs/ADRs.md#ADR-003`, `backend/lambda_function.py` (JWT implementation), `docs/AUTHENTICATION-UPDATE.md`

**Outcome**: Rejected API key approach. Implemented JWT authentication with user-specific tokens. This was a critical security improvement that aligned with privacy-first design.

---

## Sprint 2: DynamoDB Billing & Reliability

### Context
Production readiness: choosing DynamoDB billing mode and implementing reliability features.

### Prompt A (Design Alternatives)
**"Compare PAY_PER_REQUEST vs PROVISIONED DynamoDB billing. Which is better for cost predictability and surge scenarios?"**

**AI Response**: Provided cost analysis:
- PAY_PER_REQUEST: $0.15/month idle, but 89x surge multiplier (unpredictable)
- PROVISIONED with auto-scaling: $4/month idle, 9.4x surge multiplier (predictable)
- Recommendation: PROVISIONED for production (better predictability, meets budget)

**Option Tested**: Created dual design comparison (Design A vs Design B), calculated surge costs for both.

**Evidence**: `docs/COST-MODELING-WORKSHEET.md` (lines 146-300), `docs/ADRs.md#ADR-005`, `template.yaml` (auto-scaling configuration)

**Outcome**: Selected Design B (PROVISIONED with auto-scaling). Validated through cost worksheet showing 9.4x vs 89x surge multiplier. This provided cost predictability while staying within $50/month budget.

---

### Prompt B (Red-Team)
**"What happens if Lambda gets overwhelmed or DynamoDB throttles? How do we prevent cost explosions?"**

**AI Response**: Identified risks:
- Unbounded Lambda concurrency = runaway costs
- DynamoDB throttling = user-facing errors
- No kill switches = can't stop cost spikes
- No monitoring = can't detect issues

**Risk Checked**: Reviewed reliability requirements, SLO targets, and cost guardrails.

**Evidence**: `template.yaml` (reserved concurrency, auto-scaling, alarms), `kill-switch.sh`, `docs/DR-RUNBOOK.md`, `docs/SLO-ALERT-CONFIG.md`

**Outcome**: Implemented comprehensive reliability features:
- Lambda reserved concurrency (100 max)
- DynamoDB auto-scaling (5-100 RCU/WCU)
- 6 CloudWatch alarms with PagerDuty integration
- Kill switch scripts for emergency cost control
- Incident response runbook

This transformed the system from MVP to production-ready.

---

## Sprint 3: Privacy & Ethics

### Context
Privacy-first design: implementing Clause→Control→Test framework and ethics guardrails.

### Prompt A (Design Alternatives)
**"How do we ensure users can't access other households' data? What controls and tests do we need?"**

**AI Response**: Suggested CCT framework:
- **Clause**: Privacy promise (e.g., "inventory actions stay within caller's household")
- **Control**: Code enforcement (derive householdId from JWT, ignore request body)
- **Test**: Automated test that verifies control works

**Option Tested**: Implemented 3 critical privacy clauses with controls and tests.

**Evidence**: `docs/CCT.md`, `backend/test_privacy_cct.py`, `backend/lambda_function.py` (authentication logic)

**Outcome**: Created comprehensive CCT documentation with 3 critical clauses, all with red-bar passing tests. This provided verifiable privacy guarantees.

---

### Prompt B (Red-Team)
**"What telemetry are we collecting? Could we accidentally log PII or violate privacy?"**

**AI Response**: Identified risks:
- CloudWatch logs could contain request bodies with PII
- No structured logging = hard to filter PII
- No retention policies = data accumulates
- No telemetry matrix = unclear what we're collecting

**Risk Checked**: Reviewed telemetry practices, privacy requirements, and data minimization principles.

**Evidence**: `docs/TELEMETRY-DISCIPLINE.md`, `docs/ETHICS-DEBT.md` (telemetry PII minimization entry)

**Outcome**: Created telemetry matrix documenting all events, fields, purposes, and guardrails. Added ethics debt entry for structured logging with allowlist fields. This established privacy-first telemetry discipline.

---

## Inflection Points

### 1. Lambda vs EC2 Decision
**What Changed**: Initial instinct was to use EC2 (familiar, more control). AI cost analysis showed 100% savings at idle, which was critical for MVP with variable traffic.

**Why**: The cost comparison was compelling—$0 vs $7.50/month minimum. This validated serverless architecture and shaped all subsequent decisions.

**Impact**: Entire architecture became serverless, enabling automatic scaling and low operational overhead.

---

### 2. JWT Authentication Upgrade
**What Changed**: Started with simple API key. AI red-team prompt exposed critical security flaw (anyone with key = access to all data).

**Why**: Privacy requirements demanded user-level isolation. API keys couldn't provide this.

**Impact**: Complete authentication refactor from API keys to JWT tokens. This was a major security improvement that aligned with privacy-first design.

---

### 3. PROVISIONED DynamoDB Selection
**What Changed**: Initial plan was PAY_PER_REQUEST (simpler, cheaper idle). AI cost analysis showed 89x surge multiplier was too unpredictable.

**Why**: Production needs cost predictability. 9.4x surge multiplier (PROVISIONED) was acceptable and stayed within budget.

**Impact**: Implemented auto-scaling, which required more infrastructure code but provided better reliability and cost control.

---

## Attributions

### AI-Generated (with human review and testing)
- Cost modeling calculations and comparisons (`docs/COST-MODELING-WORKSHEET.md`)
- ADR template structure (`docs/ADRs.md`)
- CloudWatch alarm configurations (`template.yaml`)
- Telemetry matrix structure (`docs/TELEMETRY-DISCIPLINE.md`)
- Incident response runbook template (`docs/DR-RUNBOOK.md`)

### Human-Generated (with AI assistance)
- All Lambda function code (`backend/lambda_function.py`) - AI suggested structure, human implemented logic
- Frontend JavaScript (`frontend/app.js`, `frontend/auth.js`) - Human wrote, AI reviewed
- Privacy clause definitions (`docs/CCT.md`) - Human defined requirements, AI suggested test structure
- Stakeholder analysis (`docs/STAKEHOLDER-STORY.md`) - Human wrote, AI reviewed for completeness

### Collaborative
- Architecture diagrams (`docs/ARCHITECTURE-DIAGRAM.md`) - AI generated Mermaid, human added text descriptions
- Cost worksheet decisions - AI provided calculations, human made final decisions based on budget
- Reliability features - AI suggested alarms/metrics, human configured thresholds based on SLOs

---

## Key Learnings

1. **AI as Thinking Partner**: AI didn't make decisions—it provided alternatives, cost analysis, and risk identification. Human team made final decisions based on requirements and budget.

2. **Red-Team Prompts Are Critical**: The "what if someone gets the API key?" prompt exposed a fundamental security flaw that would have violated privacy requirements.

3. **Cost Analysis Drove Architecture**: Detailed cost comparisons (Lambda vs EC2, PAY_PER_REQUEST vs PROVISIONED) were essential for making informed decisions.

4. **Testing Validates AI Suggestions**: All AI-suggested code was tested. Privacy tests (`test_privacy_cct.py`) caught edge cases that AI didn't identify.

5. **Documentation Templates Accelerated Work**: AI-provided templates (ADRs, runbooks, telemetry matrix) saved time while maintaining consistency.

---

## Outcome Summary

**What Changed**:
- Architecture: EC2 → Lambda (cost-driven)
- Authentication: API keys → JWT (security-driven)
- DynamoDB: PAY_PER_REQUEST → PROVISIONED (predictability-driven)
- Reliability: Minimal → Production-ready (requirement-driven)

**What Stayed**:
- Privacy-first design (human requirement)
- Serverless architecture (after validation)
- Simple data model (human design)
- MVP scope (human decision)

**Validation**: All decisions validated through testing (`load-test.sh`, `test_privacy_cct.py`), cost modeling, and SLO attainment (99.8% availability, 0.2% error rate).



