---
source: https://cloud.google.com/transform/from-the-twelve-to-sixteen-factor-app
source_type: url
retrieved: 2026-09-14 00:00
original_filename: N/A
---

# From the Twelve to Sixteen-Factor App: Rethinking app dev for AI

By Kunal Kumar Gupta, Strategic Cloud Engineer
Posted October 15, 2025, in AI & Machine Learning

For over a decade, the [Twelve-Factor App methodology](https://www.12factor.net/) has been the bedrock for building scalable cloud applications. It has taught us to run stateless processes, and treat backing services as attached resources, and separate configuration from code. But the rise of generative AI introduces new challenges like conversational memory, non-deterministic behavior, and unique security risks that the original principles alone don't address.

To build robust and responsible AI applications, we need to evolve the Twelve-Factor App playbook. This isn't about replacing the original 12 factors; it's about extending them with four new principles designed for the AI era.

## XII + IV = XVI

As a quick refresher, the Twelve-Factor App methodology provides the blueprint for modern cloud applications by emphasizing principles like:

1. **Codebase**: A single codebase tracked in version control, with explicitly declared dependencies and configuration stored in the environment
2. **Dependencies**: An application must never rely on system-level dependencies. It must explicitly declare all its dependencies in a manifest and use an isolation tool to ensure a consistent and reproducible environment.
3. **Config**: Anything that varies between deployments (such as credentials and hostnames) must be stored outside the code in environment variables. This keeps code and configuration strictly separate.
4. **Backing services**: Any external service the app consumes (like a database, message queue, cache) should be treated as an attached resource that can be swapped out easily without any code changes
5. **Build, release, run**: Maintain a strict separation between the Build, Release and Run stages. Build stage converts code into a runnable artifact. Release stage combines the artifact with its environment specific config. Finally, the Run stage executes the release in the target environment.
6. **Processes**: The application must run as one or more stateless processes. Any data that needs to be persisted like user sessions must be stored in a stateful backing service.
7. **Port binding**: A 12-factor app is completely self-contained. It exports its services by binding to a port (ex an HTTP server on port 8080) and listening for requests.
8. **Concurrency**: Scaling is achieved by running more copies of the application's stateless processes. This is a simple, effective horizontal scaling model where load is distributed across multiple identical processes.
9. **Disposability**: Processes should be disposable, such that they can be started or stopped gracefully any time. This helps in elastic scaling, quick deployments and robust crash recovery
10. **Dev/prod parity**: Minimize the differences between development, staging, and production environments. By keeping the tools, and backing services as similar as possible across all environments, reduce the risk of "it works on my machine" bugs and enable continuous deployment.
11. **Logs**: Treat logs as a time-ordered event stream and write them to standard output. The execution environment is responsible for capturing, collecting and routing the stream to its final destination.
12. **Admin Processes**: Administrative tasks should be run as one-off processes. They must run in an identical environment, using the same codebase and config to ensure consistency and avoid drift.

## The new manifesto: The four new factors

As developers incorporate AI into their applications, we propose the following new factors, and how to use them in practice in a Google Cloud Platform environment.

### XIII: Prompts as code

In AI applications, a significant portion of an application's logic lives in natural language. But treating just the prompt as the new source code is insufficient. The true "code" for an AI system has three parts: the specification, the context-engineering logic, and the base prompt template.

- **Specification-driven development**: A static, version-controlled prompt doesn't capture the desired behavior. We must first define the AI's behavior with a "spec"—this could be a "golden dataset" of inputs and expected outputs, a set of persona guidelines, detailed instructions, or a suite of unit tests that define the AI's rules, boundaries, and expected responses.
- **Smart context engineering**: The most critical application logic is often the code that dynamically engineers the context sent to the model. This includes retrieving data (RAG), selecting and formatting conversational history, and deciding which tools to make available. This context-engineering code is the application and must be versioned, tested, and managed as a first-class citizen.
- **Prompts as templates**: The prompt itself is a versioned asset, but it's better thought of as a template that the context-engineering logic populates.

*In practice*: Use Vertex AI Studio as an interactive playground to experiment with and refine base prompt templates. Once an effective prompt has been crafted, commit it to the Git repository as a versioned file.

However, also commit the behavioral specs (e.g. test datasets) and the application code responsible for context engineering. The CI/CD pipeline (e.g. Cloud Build and Vertex AI Pipelines) should then automatically run an evaluation job that tests the new prompt and the context logic against the spec. This prevents behavioral regressions and ensures the AI's performance is measurable and consistent, not just a magic string buried in a function.

### XIV: State as a service

The original sixth factor demands stateless processes, yet conversational AI is inherently stateful; it must remember context from prompt to prompt, to avoid duplicating inference processes. The solution is to externalize conversational memory into a dedicated backing service. Your application process remains stateless, but it retrieves and updates the conversation history from an external store with each turn, passing a session ID to track the interaction.

- **In practice**: The Agent Development Kit (ADK) formalizes this pattern by making a crucial distinction between two types of memory:
  - The Agent Development Kit (ADK) formalizes this pattern through an abstraction called the [SessionService](https://google.github.io/adk-docs/sessions/session/#the-session-lifecycle). With each turn, the service is used to read the current conversation state from a persistent store at the beginning of a request and write any updates back at the end, being responsible for low-latency read/write of the active conversation.
  - **Long-term knowledge**: This is the persistent, searchable archive of past conversations. The ADK's MemoryService abstraction handles this by utilizing the fully managed VertexAiMemoryBankService. This service, part of the ADK's ecosystem, intelligently extracts meaningful information from completed conversations, stores it persistently, and provides advanced semantic search, allowing your agent to "remember" and learn from past interactions.

### XV: Observability for non-determinism

Traditional monitoring tells you if your app is up, but AI apps can fail in subtler ways. An AI app can be fast and return a 200 OK status but provide useless or incorrect answers. You must expand observability to include AI quality and behavior, not just system health. You need to log prompts, responses, token counts, and tool-use errors, and also instrument user-feedback mechanisms to understand the quality of your AI's output.

- **In practice**: For each turn in a conversation, the ADK can generate a rich LogEntry that captures the complete lifecycle of the request. This includes the agent_request from the user, the final llm_request sent to the model, and details of any tool_calls made in between. Because this structured log can be enriched with custom metadata and is integrated with OpenTelemetry, it can be automatically exported to Cloud Logging. From there, you can sink the data to BigQuery to analyze costs, debug failures, and measure quality, using Looker to visualize these new AI-specific metrics.

### XVI: Trust & safety by design

The security landscape for AI is different. Prompt injection is the new SQL injection, and a misconfigured AI tool can expose sensitive data. You must architect for trust and safety from the start. This means sanitizing user inputs, implementing guardrails on AI outputs, and applying the principle of least privilege to any tool or API the AI can access.

- **In practice**: A robust trust and safety model requires defense in depth. Think of it in three distinct layers: securing the model, controlling the application based on user identity, and locking down the infrastructure.
  - **Layer 1: Model-level safety** — Start by using [Gemini's built-in safety filters](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/configure-safety-filters) then add [Model Armor](https://cloud.google.com/security/products/model-armor) as a comprehensive, platform-level security wrapper. Model Armor inspects all incoming prompts and outgoing responses to help detect and block threats like prompt injection and data exfiltration, while also filtering for harmful content. It integrates with Cloud Logging and Security Command Center to provide crucial audit logs for security events.
  - **Layer 2: Application-level access control** — Adapt the agent's capabilities based on the user persona. For example, limit anonymous users to public-data tools, allow authenticated customers to access their own data with tools like getOrderStatus(customer_id), and grant trusted internal employees access to more powerful, aggregated data tools.
  - **Layer 3: Infrastructure-level permissions** — Enforce the principle of [least privilege](https://cloud.google.com/iam/docs/using-iam-securely#least_privilege) at the infrastructure level. The agent's service account should have granular, custom IAM roles, not broad permissions like Project Editor. This provides the ultimate backstop: even if a prompt is compromised, an attempt to delete data will fail if the service account's role lacks delete permissions.

## Evolve the playbook

Adopting AI is more than an API call; it's an evolution in our development discipline. The original 12 factors gave us a roadmap for the cloud. These four new principles provide the necessary extensions for building the next generation of intelligent applications.

Now it's your turn. Apply these factors to your next project on Google Cloud. What would you add as the 17th factor?

## Related articles

- [What sports cars can teach us about optimizing AI token spend (Q&A)](https://cloud.google.com/transform/gemini-enterprise-optimize-ai-token-spend) — By Mike Clark
- [Tokenomics: Why smart teams spend more on AI, on purpose](https://cloud.google.com/transform/tokenomics-why-smart-teams-spend-more-on-ai-on-purpose) — By Eric Lam
- [Meet the researcher fighting AI hallucinations at Google Cloud](https://cloud.google.com/transform/meet-the-researcher-fighting-ai-hallucinations-at-google-cloud) — By Cyrus Rashtchian
- [How leaders can scale AI by trading control for trust (Q&A)](https://cloud.google.com/transform/scale-ai-by-trading-control-for-trust) — By Michael Gerstenhaber
