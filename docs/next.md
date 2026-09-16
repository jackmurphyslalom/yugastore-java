


We are going to implement base functionality into this project to support the karpathy llm wiki. The source document for this is https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f

We want to establish a single source of truth for the local wiki with a robust tagging ontology. We want to develop a lifecycle to support document or pattern research across a few various prompts. We have established a /rabbit-* prefix for our prompts, and skills for this project. The new wiki lifeycle should be supported by the following prompt skill pairs. 

/rabbit-ingest
/rabbit-analyze
/rabbit-session-close

As a user when i ingest a new assets into the knowledgebase, i want to create an immutable data source of the original_assets, the transformed document, and the raw markdown. This should have a unique slug for the the name. This will ensure we have proper chain of custody for bringing content into our project. 

as a user when rabbit_analyze is run, we want to have set of subagents that analyze the new markdown assets for ingest and create an idiomatic entry into our wiki kb. It should have access to the current ontology, and also generate new connections in the ontology as new data comes in. In [information science](https://en.wikipedia.org/wiki/Information_science "Information science"), an **ontology** encompasses a representation, formal naming, and definitions of the categories, properties, and relations between the concepts, data, or entities that pertain to one, many, or all [domains of discourse](https://en.wikipedia.org/wiki/Domain_of_discourse "Domain of discourse"). You should generate a rough draft of these based on what you know about the project, slalom, and solution architecture.

rabbit-session-close should be reflection session once an activity has been concluded that opportunistly looks to update our knowledgegraph and assosciated formats. 

Finally, we also want to plan to support the primary Query and Lint prompts outlined in the karpathy approach. 

Go through all question 1by1 in chat, sequentially. I will answer one and then you need to recalibrate based on my response. You will always use a SCQA format. You will always use asd-ste100 simplified technical english. You will always wait for me to say bingo before moving to the next questions. When i answer only with a Letter, you may infer Bingo. You can also ask me to agree or disagree to change direction. Never use semicolns or em dashes in any of your writing. Always list them A,B,C and provide your top recomendation"

Notes: /rabbit-ingest should look at a new folder called pending_imports in root

-----

Architecture Assessment

Given that we are onboarding a new client (Yugastore), When we are approaching an unknown code base, then we want a prompt and a skill that assess each tier within the project and generates a SCQA overview and a 16 factor assessment for the each component. The output should live in a new folder called architecture_assessment. This should be a reusable skill  that is run once for each tier in the application. One for api gateway, one for cart etc. etc. This should also be captured in markdown. There should be a README.md in root that acts as an entry point into the architecture assessment. Once we have completed an architecture assessment pass on each tier, using that foundation, we should roll it up into a C4 model and assosciated diagrams for (C1,C2,C3,C4) in mermaid on this index page. 


-----

Recommendation and Insights 

Given that you now have a full architecure assessment for current-state, we want to generate a new document for future state. This can include stategic enhancements to harden different areas of the existing program, but it should also closely answer the 3 core areas from the client requests. 

**Yugastore**

- "We want to **run constant experiments (pricing, UX, recommendations)** without engineering becoming a bottleneck."
- "When any service slows down or goes down, **the storefront must degrade gracefully**."
- "Pricing rules change weekly. Engineers shouldn't need to redeploy everything."
 
----
