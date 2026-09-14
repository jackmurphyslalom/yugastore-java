---
applyTo: "**/*.test.{ts,tsx,js,jsx},**/*.spec.{ts,tsx,js,jsx},**/tests/**/*"
---

# Testing Standards

When writing or modifying tests, consult:

the relevant framework-managed guidance first, then any installed testing skills (`npx skills`).

Key patterns:
- AAA pattern (Arrange-Act-Assert)
- Descriptive test names: "should {behavior} when {condition}"
- Mock external dependencies
- Test edge cases and error paths
- Aim for 80%+ coverage on business logic

Install skills:
- https://skills.sh/
- Framework-managed: `.agents/skills/aisdlc-skill-authoring`
- Framework-managed: `.agents/skills/aisdlc-grilling`
- Framework-managed: `.agents/skills/aisdlc-domain-modeling`
- Framework-managed: `.agents/skills/aisdlc-knowledge-ingestion`
- Framework-managed: `.agents/skills/aisdlc-pr`
- `npx skills add https://github.com/anthropics/skills --skill <skill-name>`
