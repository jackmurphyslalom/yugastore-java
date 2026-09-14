# Provider-Neutral Pull Request Feedback Contract

## Normalized Records

```ts
type ReviewThreadState = 'open' | 'resolved' | 'outdated';
type WorkItemRelationship = 'closes' | 'references';

interface ReviewComment {
  id: string;
  author?: string;
  body: string;
  createdAt?: string;
  url?: string;
}

interface ReviewThread {
  provider: 'github' | 'azure-devops';
  id: string;
  state: ReviewThreadState;
  path?: string;
  line?: number;
  comments: ReviewComment[];
  url: string;
}

interface LinkedWorkItem {
  provider: 'github' | 'azure-devops';
  id: string;
  title: string;
  url: string;
  state?: string;
  relationship: WorkItemRelationship;
}

interface ProviderWarning {
  code: 'linked-item-incomplete' | 'unsupported';
  message: string;
}

interface ProviderError {
  code: 'authentication' | 'rate-limit' | 'pagination-incomplete' | 'provider-error';
  message: string;
  retryAfter?: string;
}

interface ProviderCollectionResult {
  threads: ReviewThread[];
  linkedWorkItems: LinkedWorkItem[];
  pagesCollected: number;
  paginationComplete: boolean;
  warnings: ProviderWarning[];
  errors: ProviderError[];
}
```

## Adapter Requirements

- GitHub uses GraphQL `reviewThreads(first:, after:)` until `hasNextPage` is false. It retrieves
  closing and cross-referenced issues best-effort.
- Azure DevOps uses the pull-request `threads` REST endpoint until no continuation token remains.
- A repeated cursor or continuation token is a pagination error.
- A later occurrence of the same stable thread ID replaces the earlier record.
- Preserve ordered comments, optional path/line, and open, resolved, or outdated state.
- Map closing and explicitly referenced work items to `closes` or `references`.
- Azure DevOps HTTP 203 and login-shaped or non-JSON responses are authentication failures.
  Classify GitHub GraphQL error payloads before describing a result as complete.
- GitHub requires repository pull-request and issue read access. Azure DevOps requires code-review
  and linked-work-item read access; encode its PAT as Basic authentication with an empty username
  and never expose it.
- Linked-item collection is bounded to one provider page. When more pages exist, preserve completed
  thread results and emit `linked-item-incomplete`.

Collection is complete only when required thread pagination is complete and `errors` is empty.
Incomplete results may be presented as partial but cannot be posted as a final summary.

Summary ownership remains keyed by exactly:

```html
<!-- aisdlc-pr-review-summary:v1 -->
```
