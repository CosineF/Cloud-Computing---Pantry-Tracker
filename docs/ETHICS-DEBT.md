# Ethics Debt Resolutions

Snapshot of known privacy and ethics debts, their trade-offs, and our resolution plans.

## Ethics Ledger (Snapshot)

| Debt | Risk / Trade-off | Decision / Resolution | Owner | Status | Target |
| --- | --- | --- | --- | --- | --- |
| Stronger password protection | Current SHA-256 hashing lacks salt/work factor; risk of credential cracking if leaked | Migrate to salted bcrypt (work factor 12), backfill on next login/signup; add KDF unit tests | Backend | Planned | Next sprint |
| Token lifetime review | 7-day JWT tokens increase replay window | Add configurable TTL (default 24h) and refresh flow; enforce token revocation on password change | Backend | Planned | Next sprint |
| Telemetry PII minimization | CloudWatch logs could accidentally receive PII if code logs bodies | Adopt structured logger with allowlist fields (see Telemetry Matrix); add PR lint to block `print(event)` | Infra | In progress | This sprint |
| Data residency clarity | No explicit region pinning in logs/storage policies | Set `AWS_REGION`/`AWS_DEFAULT_REGION` defaults and document; add deployment check for region tags | Infra | Planned | This sprint |
| User data deletion | No automated erase workflow | Add admin endpoint + script to delete a user and all inventory rows; document SLA | Backend | Planned | Next sprint |
| Rate limiting | Unbounded auth attempts enable brute-force | Introduce API Gateway/Lambda authorizer rate limits; lock account on 10 failed attempts/hour | Security | Planned | This sprint |
| Consent and transparency | Telemetry purpose not surfaced to users | Add privacy notice and telemetry summary in UI; opt-out for non-essential telemetry | Frontend | Planned | Next sprint |
| Unreliable connectivity inclusion | Inventory flows fail or stall on flaky/low-bandwidth links; risk of double-buys or drop-offs | Add request retry/backoff, small payloads, optimistic UI with eventual consistency notes, and cache-last inventory snapshot client-side | Frontend | Planned | Next sprint |
| Accessibility for visually impaired users | Screen readers and keyboard-only users may be blocked by current UI | Add semantic HTML and ARIA labels, focus management, keyboard nav, and WCAG contrast fixes; add a11y lint/checklist to PRs | Frontend | Backlog | Upcoming sprint |
| Language and clarity for ESL/low-literacy households | English-only copy and dense wording exclude some users | Simplify labels, add plain-language helper text, and prepare strings for localization (resource file + docs on adding locales) | Frontend | Backlog | Upcoming sprint |

## Notes on Data Collection and Storage
- **Minimal scope:** Only hashed identifiers and coarse IP prefixes are logged; item names/quantities are excluded.
- **Retention:** Operational logs 14 days; security alerts/errors 30 days; DynamoDB data per product needs; add TTL where feasible.
- **Access controls:** Log access limited to ops/security; audited with break-glass procedure.
- **Encryption:** Rely on managed encryption for logs and DynamoDB; enforce TLS in transit.
- **Future guardrails:** Add automated scanners to detect PII patterns in logs and schemas.
