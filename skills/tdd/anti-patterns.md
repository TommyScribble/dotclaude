# Testing Anti-Patterns

Load this when: writing or changing tests, adding mocks, or tempted to add test-only code to production classes.

## Anti-Pattern 1: Horizontal Slicing

Writing all tests first, then all implementation.

```
WRONG:
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT:
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
```

Tests written in bulk test imagined behavior, not actual behavior. You end up testing the shape of things (data structures, function signatures) rather than user-facing behavior. Each test should respond to what you learned from the previous cycle.

## Anti-Pattern 2: Testing Mock Behavior

```typescript
// BAD: Testing that the mock exists
test('renders sidebar', () => {
  render(<Page />);
  expect(screen.getByTestId('sidebar-mock')).toBeInTheDocument();
});
```

You're verifying the mock works, not that the component works. Test real behavior or unmock the component.

See [mocking.md](mocking.md) for detailed mocking guidance.

## Anti-Pattern 3: Test-Only Methods in Production

```typescript
// BAD: destroy() only exists for test cleanup
class Session {
  async destroy() {
    await this._workspaceManager?.destroyWorkspace(this.id);
  }
}
```

Production classes should not contain methods only used by tests. Move test-specific logic to test utilities:

```typescript
// GOOD: Test utility handles cleanup
// In test-utils/
export async function cleanupSession(session: Session) {
  const workspace = session.getWorkspaceInfo();
  if (workspace) {
    await workspaceManager.destroyWorkspace(workspace.id);
  }
}
```

Before adding any method to a production class, ask: "Is this only used by tests?" If yes, put it in test utilities.

## Anti-Pattern 4: Mocking Without Understanding

```typescript
// BAD: Mock prevents config write that test depends on
test('detects duplicate server', () => {
  vi.mock('ToolCatalog', () => ({
    discoverAndCacheTools: vi.fn().mockResolvedValue(undefined)
  }));
  await addServer(config);
  await addServer(config); // Should throw — but won't
});
```

Before mocking any method: understand what side effects the real method has, and whether the test depends on any of them. Mock at the lowest level that isolates the slow or external part while preserving the behavior the test needs.

## Anti-Pattern 5: Incomplete Mocks

Mocking only the fields you think you need. Downstream code depends on fields you didn't include, and failures are silent.

Mock the COMPLETE data structure as it exists in reality.

## Anti-Pattern 6: Tests as Afterthought

Implementation complete, no tests written, "ready for testing." Testing is part of implementation. The TDD cycle ensures this by making tests the entry point.

## Anti-Pattern 7: Retrofitting Tests Around Existing Code

Writing tests after the code to "verify it works." Tests written after code pass immediately, and passing immediately proves nothing — the test might verify the wrong thing, test implementation instead of behavior, or miss edge cases. The failing step is what proves the test catches real problems.

## Red Flags

- Asserting on `*-mock` test IDs
- Methods only called in test files
- Mock setup is more than half the test
- Test fails when you remove the mock
- Can't explain why a mock is needed
- "and" in the test name
- Test passes immediately when first written
- Test breaks on refactor but behavior hasn't changed
