# Stakeholder Story

Why we built Cloud Pantry Tracker, who it serves, the harms we targeted, and the empty chair that kept us honest.

## Problem narrative
- Shared households double-buy staples or run out because pantry state lives in sticky notes and group chats instead of a live source of truth.
- Grocery duties are handed off (roommates, partners, caregivers, mutual-aid volunteers), so the list must be easy to use and must not leak who lives together or what they buy.
- Operators need enough signal to keep the service reliable without collecting or exposing personal data.

## Stakeholder map
| Stakeholder | Needs | Decisions aligned to them | Harms we are blocking |
| --- | --- | --- | --- |
| Primary household shoppers (roommates/partners) | Accurate, up-to-date list with low effort; protection from other households editing or seeing their data | Authenticated inventory scope is derived from the JWT username; frontend hides the household selector; minimal fields to add/remove items | Cross-household leakage, typos overwriting other homes, stale inventory that drives waste |
| Invited helpers (caregivers, mutual-aid volunteers) | Temporary access without oversharing identity or household makeup; usable on borrowed devices | No email/address collection; JWT auth for each call; small JSON responses that load on low bandwidth | Exposure of household composition, over-collection of PII, exclusion for low-connectivity users |
| Operators and support | Operational signals without peeking at pantry contents | Telemetry Matrix hashes usernames/household IDs and drops item names/quantities with 14/30-day retention | PII in logs, secondary use beyond reliability/security |

## Targeted harms and guardrails
- Cross-household data access: backend derives `householdId` from the validated JWT username and ignores any client-supplied household IDs; UI removes the household field to avoid mis-routed requests.
- Unauthorized access and replay: signup/login required for all inventory actions; JWTs gate every route; password hashing in place now with planned move to salted bcrypt and shorter token TTL per `docs/ETHICS-DEBT.md`.
- Over-collection and stigma: no emails, addresses, or item contents in logs; telemetry hashes identifiers and uses coarse IP prefixes with bounded retention as captured in `docs/TELEMETRY-DISCIPLINE.md`.
- Inclusion and ease: only two inputs to get started (username, password); inventory flows avoid optional fields; responses stay small for low-bandwidth users.
- Unreliable connectivity: keep payloads small, document planned retries/optimistic UI, and avoid server round trips that would block a quick grocery run.

## The empty chair we kept filled
We kept seats open for:
- A low-bandwidth roommate or caregiver on a shared/borrowed device who cannot risk exposing who they live with or what they stock. This drove scoping to auth (no household dropdown), lightweight auth with a path to stronger hashing/TTL, and redacted telemetry.
- A visually impaired user relying on a screen reader (to be supported in the upcoming accessibility work). This keeps us honest about shipping semantic HTML/ARIA, keyboard navigation, and contrast fixes instead of deferring inclusivity.
- A shopper in a place where English is not their first language or written instructions are hard to parse. That pushed us toward plain-language labels and a localization plan rather than assuming English-only instructions are enough.

## How we will stay accountable
- Run `backend/test_privacy_cct.py` so the clause/control/test around household scoping and token validation keeps passing.
- Keep the ethics ledger updated as we ship the bcrypt + token TTL changes and enforce telemetry linting.
- Watch SLOs/alerts (see `docs/SLO-ALERT-CONFIG.md` and `docs/RELIABILITY-SCALABILITY-SUMMARY.md`) to keep the service available to the people we prioritized above.
