# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) for the genui_anthropic package.

## What is an ADR?

An Architecture Decision Record captures an important architectural decision made along with its context and consequences.

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-0001](0001-sealed-exception-hierarchy.md) | Sealed Exception Hierarchy | Accepted |
| [ADR-0002](0002-circuit-breaker-pattern.md) | Circuit Breaker Pattern | Accepted |
| [ADR-0003](0003-dual-mode-architecture.md) | Dual Mode Architecture | Accepted |
| [ADR-0004](0004-retry-with-exponential-backoff.md) | Retry with Exponential Backoff | Accepted |

## Template

When creating a new ADR, use this template:

```markdown
# ADR-XXXX: Title

## Status

Proposed | Accepted | Deprecated | Superseded

## Context

What is the issue that we're seeing that is motivating this decision or change?

## Decision

What is the change that we're proposing and/or doing?

## Consequences

What becomes easier or more difficult to do because of this change?
```
