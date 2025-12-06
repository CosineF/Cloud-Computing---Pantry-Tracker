# Telemetry Discipline

Telemetry must protect user privacy by default. We only collect the minimum operational signals needed to keep the service healthy and secure.

## Principles
- Minimize: capture only data required for reliability, security, and abuse prevention.
- De-identify: prefer hashed or tokenized identifiers; never store plaintext secrets.
- Bound storage: define retention, access, and encryption for every datum.
- Purpose-bound use: no secondary use (e.g., marketing) without explicit consent.
- No data monetization: telemetry and user signals may not be sold, shared for ads, or repurposed for growth targeting.

## Telemetry Matrix

| Event / Signal | Fields Collected | Purpose | Storage / Retention | Privacy Guardrails |
| --- | --- | --- | --- | --- |
| Auth success | `username_hash` (SHA-256 of lowercase username), `requestId`, `timestamp`, `ip_prefix` (/24 only) | Detect auth anomalies without storing full identifiers | CloudWatch Logs, 14 days, encryption at rest | Hash usernames; drop full IP; no token or password storage |
| Auth failure | `username_hash`, `failure_reason` (enum), `requestId`, `timestamp`, `ip_prefix` | Brute-force detection and lockout tuning | CloudWatch Logs, 14 days, encryption at rest | No plaintext usernames, passwords, or tokens; redact request bodies |
| Inventory read | `actor_username_hash`, `householdId_hash`, `requestId`, `timestamp` | Detect cross-tenant access attempts | CloudWatch Logs, 14 days | Hash household IDs; do not log item names or quantities |
| Inventory write (add/remove) | `actor_username_hash`, `householdId_hash`, `requestId`, `timestamp`, `operation` (add/remove) | Abuse detection and troubleshooting | CloudWatch Logs, 14 days | Redact item names and quantities; hash identifiers |
| System error | `requestId`, `path`, `httpMethod`, `timestamp`, `error_code` | Triage reliability issues | CloudWatch Logs, 30 days | Strip headers and bodies; no tokens or credentials |
| Security alert (rate-limit / JWT failure) | `requestId`, `ip_prefix`, `timestamp`, `alert_type` | Identify hostile traffic | CloudWatch Logs, 30 days | No user identifiers; prefix IP only |

## Data Handling Decisions
- **Not collected:** item names, quantities, plaintext usernames, emails, passwords, JWTs, or full IP addresses.
- **Hashing:** usernames and household IDs hashed client-side or at edge before logging to reduce linkage risk.
- **Redaction:** request/response bodies and headers are stripped from logs; structured fields only.
- **Retention:** operational logs 14 days (30 for security alerts/errors); auto-expire via log retention policy.
- **Access:** least-privilege IAM for log readers; break-glass access requires approval.
- **Encryption:** rely on provider-managed encryption at rest; TLS in transit.
- **Monetization boundary:** operational telemetry cannot be shared with third parties except processors needed to run the service; no enrichment/resale; any feature usage analytics must be aggregated/anonymized and documented before collection.

## Implementation Hooks
- Wrap logging utilities to enforce redaction and hashing before emit.
- Centralize log schemas to avoid accidental PII fields.
- Add CI/PR lint to block logging of raw headers/bodies or tokens.

## Verification Ideas
- Unit tests to ensure log payload builders hash identifiers and drop PII fields.
- Canaries that attempt to log forbidden keys (e.g., `Authorization`) and assert rejection.
- Periodic log sampling to confirm schemas match the matrix.
