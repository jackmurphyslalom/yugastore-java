# Client Requirements Interview — Yugabyte Product Owner

Raw intake from a client interview, not yet a spec. Feed into `/speckit.specify` or
`/speckit.aisdlc.triage` when someone picks up one of these.

## Source
- `docs/context/sources/2026-09-14-client-requirements-interview.md` (archived transcript;
  originally `client_interview_edited.docx`, retrieved 2026-09-14 15:40).
- Meeting: "AI Immersion Meeting-20260914_150758" (2026-09-14, ~16 min).
- Participants: **Tristan Leonard** — product owner for Yugabyte (the client stakeholder);
  **Young Chul Kim** — facilitator (addressed once by Tristan as "Mike"); **Jack Murphy** — asked
  one follow-up question (attributed under Young Chul Kim's transcript turn at 11:53, so the
  speaker label there may not be fully reliable).
- This interview directly answers the three open questions previously logged in
  `specs/intake/2026-09-14-ai-immersion-open-questions.md` from an earlier, second-hand
  description of a "client problem" slide deck. Treat this transcript as the primary source for
  those three topics going forward.
- Timestamps below are the transcript's own mm:ss markers, used as stable anchors.

## Client-Stated Requirements

Tristan framed these as three optional directions ("you don't have to do all of them... pick one
or two... or come up with something pretty similar"), not a mandatory checklist. *(anchor 6:57–7:03)*

### 1. Constant experiments without engineering as a bottleneck
- **Problem**: wants to launch a pricing or homepage experiment on Monday and read results by
  Friday without waiting on an engineering release train. *(anchor 7:18)*
- **Client's understanding of current state**: product catalog and pricing live inside the
  product service; the React UI is a single build; any experiment today means a code change,
  redeploy, and delay. *(anchor 7:18)*
- **Client-volunteered technical directions** (offered despite saying technical detail wasn't
  needed): externalize pricing/recommendation logic behind configuration or feature flags instead
  of hard-coding it; an experimentation/A-B layer at the API gateway; UI reads experiment variants
  from a config service. *(anchor 7:18–7:57)*
- **No recommendation engine exists today** — explicitly called out as greenfield room for a team
  to add one. *(anchor 7:57)*
- **Primary persona**: merchandisers / category managers, who own the catalog, pricing, and
  promotions for a product category; want to change prices weekly, run promos, and reorder what's
  featured on the homepage; today they file a ticket and wait for an engineering deploy.
  *(anchor 12:28–13:41)*
- **Possible secondary persona (not committed)**: a pricing/revenue analyst who owns pricing
  strategy, target margin, and elasticity testing, and would test price points/promotion rules
  against revenue rather than just clicks. *(anchor 14:00–14:52)*
- **Scope clarification**: when asked whether cross-UX experimentation and weekly pricing-rule
  changes are interrelated or separate, Tristan said to treat them as tightly coupled for now.
  *(anchor 13:41–14:52)*

### 2. Graceful degradation / resilience
- **Problem**: when a dependent service slows down or goes down (example given: checkout), the
  storefront should degrade gracefully instead of hanging the whole site or showing a blank white
  screen. *(anchor 8:32–9:03)*
- **Demo scenario given by client**: kill the checkout service mid-demo; customers should still be
  able to browse and add to cart, with a "try again shortly" message instead of a blank screen.
  *(anchor 9:03)*
- **Client's read of current state**: the product is built on Spring Cloud, which has resilience
  tooling, but the client does not believe the product fully implements it today; a slow
  products/checkout call can currently hang the entire site. *(anchor 8:32–9:03)*
- **Client-volunteered technical directions**: circuit breakers, better timeouts, fallbacks,
  retries with backoff, and user-facing messaging that the site is working on recovering.
  *(anchor 9:03–9:38)*
- **Open sub-question (unresolved)**: asked whether resilience also implies an uptime dashboard or
  other metrics. Tristan was uncertain, said he'd need to check what administrative/observability
  views currently exist, and speculated a non-production "toggle to intentionally add latency" for
  chaos-style testing would be useful, but could not recall if such a feature already exists or its
  name. **Needs verification against the actual repo before being treated as a requirement.**
  *(anchor 11:01–11:53)*

### 3. Dynamic pricing rules without redeploy
- **Problem**: pricing rules change on a weekly basis; today a merchandiser changes a price rule in
  a table or admin screen, but it requires a full redeploy to take effect; the client wants changes
  live "in minutes" without redeploying code. *(anchor 9:38–10:19)*
- **Client frames this as the same underlying problem as #1**: pricing is hard-coded in the product
  service; the fix is a "better rules and configuration engine." *(anchor 10:19)*
- **Quality expectation stated by the client**: keep the site running, have tests, and target
  roughly 85% code coverage ("my grandma always told me 85% code coverage is the sweet spot" —
  informal framing, but stated as an actual target, not just a joke). *(anchor 10:19–10:51)*

## Not Yet Resolved
- No specific A/B testing framework, config-service technology, or rules-engine technology was
  chosen; the client explicitly deferred technical decisions to the delivery team.
- Whether an uptime dashboard, other metrics, or a non-production latency-injection/chaos toggle is
  in scope is unresolved — pending verification of what admin/observability views exist in the
  current site (see `docs/context/gaps.md`).
- The persona split between merchandiser/category-manager (primary) and pricing/revenue analyst
  (secondary, not committed) should be confirmed before scoping any spec that assumes both.
- The 85% code coverage figure was given informally; confirm whether it should become a hard
  quality gate before citing it as a formal acceptance criterion.

## Related
- `specs/intake/2026-09-14-ai-immersion-open-questions.md` — the team's earlier, second-hand
  version of these same three questions; that file's assumptions (e.g., about how pricing is
  currently stored) still need code-level verification even though the client's problem statements
  are now directly confirmed here.
- `docs/decisions/2026-09-14-1758-immersion-kickoff-decisions.md` — team-process decisions from the
  same engagement.
