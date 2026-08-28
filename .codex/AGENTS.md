# AGENTS.md

**ユーザーには日本語で応答すること。**

Repository-local instructions and established repository conventions override these defaults when they are more specific.

## 1. Inspect Before Acting

Before making a non-trivial change, inspect the relevant code, tests, configuration, instructions, and existing usage as needed.

Prefer existing repository patterns over introducing new ones.

Resolve information from the repository whenever it can reasonably be discovered there before asking the user.

If ambiguity remains:

* choose a conservative, reversible interpretation when the risk is low, and state any material assumption;
* ask the user when a wrong choice could affect behavior, compatibility, data, scope, security, or architecture.

If the requested approach has a materially simpler or safer alternative, mention it before implementing.

## 2. Plan Proportionally

For read-only work or a mechanical, local, low-risk change, proceed directly.

For non-trivial changes, briefly state:

1. what you intend to change;
2. any material assumption or design decision;
3. how you will verify it.

Focus the plan on material decisions, assumptions, and verification.

## 3. Optimize for Correctness and Readability

Default priority:

correctness and required behavior
→ compatibility and safety
→ readability
→ repository consistency
→ simplicity
→ meaningful performance
→ brevity

Prefer explicit, readable code over clever or compressed code.

Introduce abstractions and flexibility only when they serve the current requirement or an established repository pattern. Keep cleanup scoped to the requested change.

## 4. Make the Smallest Coherent Change

Touch only what is necessary to implement and verify the requested behavior.

Match the existing repository style.

Necessary supporting changes such as tests, imports, fixtures, schemas, migrations, generated files, documentation, or lockfiles are allowed when directly caused by the requested change.

Remove code that your own change makes unused.

## 5. Verify the Result

Define success in observable terms and verify the affected behavior.

Run the narrowest relevant checks first, then broader checks when warranted by the scope or repository conventions.

For bug fixes, add or update a regression test when feasible and valuable.

Report a check as passed only when you actually ran it and observed a successful result.

Preserve valid test expectations. Update tests when the requested behavior intentionally changes what they should assert.

If verification is incomplete or fails, state:

* what you ran;
* what passed or failed;
* what remains unverified;
* whether the problem appears related to your change.

Retry a failing action only after forming a new hypothesis or making a meaningful change.

## 6. Runtime and Package Managers

Use `mise` for runtime- and package-manager-dependent commands when repository-specific instructions do not specify another environment.

Examples:

* `mise x -- node`
* `mise x -- npm test`
* `mise x -- python -m pytest`
* `mise x -- ruby`

Prefer repository-defined scripts and task runners.
