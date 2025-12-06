# Monetization Plan (Freemium, Privacy-First)

How we will sustain Cloud Pantry Tracker without selling or exploiting user data.

## Principles
- Privacy is non-negotiable: no data sales, no ad targeting, no resale of telemetry.
- Free stays useful: core pantry tracking must remain valuable at the free tier.
- Transparent value exchange: paid plans charge for premium capabilities and support, not for user data.

## Tiers
- **Free (default)**
  - Single household space tied to the account
  - Unlimited basic items and real-time updates
  - Standard availability (best effort)
  - Community/FAQ support
- **Pro (paid)**
  - Multiple household spaces (e.g., home + pantry for a family member)
  - Shared access controls (invite helpers, manage roles)
  - Item history/export and bulk actions (CSV)
  - Higher availability target with incident comms
  - Email support/SLA window
- **Add-ons (future)**
  - Managed hosting for community orgs (multi-tenant isolation, SSO)
  - Observability pack (dashboards/alerts) for admins

## Pricing
- Initial pilot pricing TBD; goal is to keep Pro affordable for households while funding operations.
- Add-ons priced for organizations that need support/SLA, not for individual consumers.

## Guardrails on monetization
- No ads, tracking pixels, or sale/enrichment of user data or telemetry.
- Feature usage analytics (if added) must be aggregated/anonymized and documented in `docs/TELEMETRY-DISCIPLINE.md` before collection.
- Any AI-assisted features (e.g., Rekognition for item suggestions) must be explicit opt-in, avoid image retention, and be excluded from monetization.

## Rollout plan
- Ship Pro features behind feature flags; validate value with small cohorts.
- Keep Free solid: ensure core inventory flows and reliability remain first-class.
- Publish data use notice in the UI and docs to reinforce the “no data sale” boundary.
- Re-evaluate pricing after measuring operating costs (DynamoDB, API Gateway, support).

## Success measures
- Activation/retention in Free without increased error rates.
- Conversion to Pro based on premium capabilities (multi-space, roles, exports), not ads.
- Zero violations of the no-monetization-of-data guardrail.
