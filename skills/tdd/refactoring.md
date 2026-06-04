# Refactor Candidates

After the TDD cycle gets you to GREEN, look for these improvements:

- **Duplication** → Extract function or class
- **Long methods** → Break into private helpers (keep tests on public interface)
- **Shallow modules** → Combine or deepen (push complexity behind simpler interface)
- **Feature envy** → Move logic to where the data lives
- **Primitive obsession** → Introduce value objects
- **Existing code the new code reveals as problematic** → Refactor it now while you have context

## Rules During Refactor

- Never refactor while RED — get to GREEN first
- Run tests after each refactor step
- Don't add behavior during refactor — if you need new behavior, go back to RED
- Keep the public interface stable — refactoring changes internals, not contracts
