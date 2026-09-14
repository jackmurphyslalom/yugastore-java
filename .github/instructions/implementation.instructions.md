---
applyTo: "src/**/*"
---

# Implementation Standards

When working in source files, consult:

1. **Framework-managed skills**
   - `.agents/skills/aisdlc-skill-authoring`
   - `.agents/skills/aisdlc-grilling`
   - `.agents/skills/aisdlc-domain-modeling`
   - `.agents/skills/aisdlc-knowledge-ingestion`
   - `.agents/skills/aisdlc-pr`
   - Apply only the skills relevant to the task

2. **Security skill** (installed with `npx skills` as needed)
   - Validate all inputs
   - Handle auth properly
   - Protect sensitive data

3. **Relevant optional skills** based on file type:
   - React files -> React skill guidance
   - API endpoints -> API design skill guidance

Install skills:
- https://skills.sh/
- `npx skills add https://github.com/anthropics/skills --skill <skill-name>`
