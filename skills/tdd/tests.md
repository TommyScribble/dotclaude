# Good and Bad Tests

## Good Tests

Integration-style: test through real interfaces, not mocks of internal parts.

```typescript
// Tests observable behavior through the public API
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

Characteristics:
- Tests behavior callers care about
- Uses public API only
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test
- Clear name that reads like a specification

```typescript
// Good: name describes behavior, tests real code
test('retries failed operations 3 times', async () => {
  let attempts = 0;
  const operation = () => {
    attempts++;
    if (attempts < 3) throw new Error('fail');
    return 'success';
  };

  const result = await retryOperation(operation);

  expect(result).toBe('success');
  expect(attempts).toBe(3);
});
```

## Bad Tests

Implementation-detail tests are coupled to internal structure.

```typescript
// BAD: Tests that a mock was called, not that behavior works
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

```typescript
// BAD: Vague name, tests mock not code
test('retry works', async () => {
  const mock = jest.fn()
    .mockRejectedValueOnce(new Error())
    .mockRejectedValueOnce(new Error())
    .mockResolvedValueOnce('success');
  await retryOperation(mock);
  expect(mock).toHaveBeenCalledTimes(3);
});
```

```typescript
// BAD: Bypasses the interface to verify via external means
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// GOOD: Verifies through the interface
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

## Red Flags

- Mocking internal collaborators (your own classes/modules)
- Testing private methods
- Asserting on call counts or call order
- Test breaks when refactoring without behavior change
- Test name describes HOW not WHAT
- Verifying through external means (database queries, file system checks) instead of through the interface
- Test passes immediately when first written (you never saw it fail)
- "and" in the test name — split it into separate tests
