# Call-outs: Next Steps, Limits, and Acknowledgements

What we would do next, the boundaries to keep in mind, and who helped shape this work.

## Next we would ship
- **Resilient UX for flaky networks:** Add client retries/backoff, optimistic updates, and cached last-known inventory so low-bandwidth households are not blocked.
- **Accessibility pass:** Semantic HTML/ARIA, keyboard nav, focus management, and WCAG contrast fixes to support screen readers and keyboard-only users.
- **Localization/clarity:** Plain-language copy and string externalization to support ESL/low-literacy users.
- **Auth hardening:** Move to salted bcrypt with shorter JWT TTL and refresh, per `docs/ETHICS-DEBT.md`.
- **AI-assisted item entry (guardrailed):** Prototype optional AWS Rekognition image-to-item suggestions with strict privacy constraints (opt-in, client-side redaction, no image logging or retention).

## Known limits
- No offline mode yet; current flows require live API calls to view/edit inventory.
- Accessibility gaps remain; current UI may not be screen-reader friendly.
- English-only labels; no localization or glossary for low-literacy users yet.
- Password hashing is SHA-256 in this MVP; token lifetime is 7 days until the planned change lands.
- No item deduping/merge logic; rapid repeated adds can create near-duplicate entries.
- AI image support is not implemented; would require privacy review and explicit consent before any rollout.

## Ethics debt (snapshot)
- **Unreliable connectivity inclusion:** Add retries/optimistic UI and local caching to reduce drop-offs on slow networks.
- **Accessibility for visually impaired users:** Ship ARIA/semantic structure, keyboard support, and contrast fixes; add a11y checks to PRs.
- **Language and clarity:** Simplify labels and prepare strings for localization.
- **Auth/privacy hardening:** Salted bcrypt + shorter TTL and refresh flow; telemetry linting to prevent PII in logs.

Full ledger: `docs/ETHICS-DEBT.md`.

## Acknowledgements
- Household shoppers and caregivers who stressed low-friction, privacy-first flows.
- The “empty chair” stakeholders: low-bandwidth/shared-device users, visually impaired users, and ESL/low-literacy shoppers who shaped inclusion priorities.
- Teammates maintaining the Telemetry Matrix, SLOs, and privacy clause/control/tests that keep us accountable.
