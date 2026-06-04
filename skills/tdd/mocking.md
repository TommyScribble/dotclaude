# When and How to Mock

## When to Mock

Mock at system boundaries only:
- External APIs (payment, email, third-party services)
- Databases (prefer a test database when practical)
- Time and randomness
- File system (sometimes)

## When NOT to Mock

- Your own classes and modules
- Internal collaborators
- Anything you control

If you're mocking your own code, the design is too coupled. Introduce dependency injection instead of mocking around the coupling.

## Designing for Mockability

### 1. Use dependency injection

Pass external dependencies in rather than creating them internally:

```typescript
// Easy to mock — dependency is injected
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// Hard to mock — dependency is created internally
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

### 2. Prefer SDK-style interfaces over generic fetchers

Create specific functions for each external operation instead of one generic function:

```typescript
// GOOD: Each function is independently mockable
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  getOrders: (userId) => fetch(`/users/${userId}/orders`),
  createOrder: (data) => fetch('/orders', { method: 'POST', body: data }),
};

// BAD: Mocking requires conditional logic inside the mock
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

The SDK approach means each mock returns one specific shape, no conditional logic in test setup, and you can see which endpoints a test exercises.

## Mocking Anti-Patterns

### Testing mock behavior instead of real behavior

```typescript
// BAD: You're testing that the mock exists
test('renders sidebar', () => {
  render(<Page />);
  expect(screen.getByTestId('sidebar-mock')).toBeInTheDocument();
});

// GOOD: Test real component or don't mock it
test('renders sidebar', () => {
  render(<Page />);
  expect(screen.getByRole('navigation')).toBeInTheDocument();
});
```

Before asserting on any mock element, ask: "Am I testing real behavior or just mock existence?" If mock existence — delete the assertion or unmock the component.

### Mocking without understanding dependencies

```typescript
// BAD: Mock prevents config write that the test depends on
test('detects duplicate server', () => {
  vi.mock('ToolCatalog', () => ({
    discoverAndCacheTools: vi.fn().mockResolvedValue(undefined)
  }));
  await addServer(config);
  await addServer(config); // Should throw — but won't
});

// GOOD: Mock the slow part, preserve behavior the test needs
test('detects duplicate server', () => {
  vi.mock('MCPServerManager'); // Just mock slow server startup
  await addServer(config);  // Config written
  await addServer(config);  // Duplicate detected
});
```

Before mocking any method:
1. What side effects does the real method have?
2. Does this test depend on any of those side effects?
3. If yes — mock at a lower level, preserving the behavior the test needs

### Incomplete mocks

Mock the COMPLETE data structure as it exists in reality, not just the fields your immediate test uses. Partial mocks hide structural assumptions and fail silently when downstream code accesses fields you didn't include.

```typescript
// BAD: Missing fields downstream code uses
const mockResponse = {
  status: 'success',
  data: { userId: '123', name: 'Alice' }
};

// GOOD: Mirror real API completeness
const mockResponse = {
  status: 'success',
  data: { userId: '123', name: 'Alice' },
  metadata: { requestId: 'req-789', timestamp: 1234567890 }
};
```

## Warning Signs

- Mock setup is longer than test logic
- You're mocking everything to make the test pass
- Test breaks when you change the mock
- You can't explain why a specific mock is needed
- You're mocking "just to be safe"

When mocks get too complex, consider integration tests with real components — they're often simpler.
