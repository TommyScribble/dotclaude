# Deep Modules

From "A Philosophy of Software Design":

A deep module has a small interface and a rich implementation. It hides complexity behind a simple contract.

```
┌─────────────────────┐
│   Small Interface   │  ← Few methods, simple params
├─────────────────────┤
│                     │
│  Deep Implementation│  ← Complex logic hidden inside
│                     │
└─────────────────────┘
```

A shallow module has a large interface and thin implementation — it exposes complexity instead of absorbing it.

```
┌─────────────────────────────────┐
│       Large Interface           │  ← Many methods, complex params
├─────────────────────────────────┤
│  Thin Implementation            │  ← Just passes through
└─────────────────────────────────┘
```

## Design Questions

When designing or refactoring an interface:
- Can I reduce the number of methods?
- Can I simplify the parameters?
- Can I hide more complexity inside?
- Is this module absorbing complexity or just passing it through?

## Relationship to TDD

Deep modules emerge during the REFACTOR phase, not during GREEN. During GREEN, write the minimal code to pass the test. During REFACTOR, look for opportunities to push complexity behind simpler interfaces. The tests guide this — if the public interface is clean and the tests all pass through it, you can restructure internals freely.
