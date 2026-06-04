# Interface Design for Testability

Good interfaces make testing natural.

## 1. Accept dependencies, don't create them

```typescript
// Testable — dependency is visible and replaceable
function processOrder(order, paymentGateway) {}

// Hard to test — dependency hidden inside
function processOrder(order) {
  const gateway = new StripeGateway();
}
```

## 2. Return results, don't produce side effects

```typescript
// Testable — assert on the return value
function calculateDiscount(cart): Discount {}

// Hard to test — mutates input, nothing to assert on
function applyDiscount(cart): void {
  cart.total -= discount;
}
```

## 3. Small surface area

- Fewer methods = fewer tests needed
- Fewer parameters = simpler test setup
- Ask: can I reduce the number of methods? Can I simplify the parameters? Can I hide more complexity inside?

## 4. Separate decisions from effects

When a function both decides what to do and does it, testing requires mocking the effects to verify the decision. Instead, split them: one function decides (returns a value), another executes (performs the effect). Test the decision function with simple assertions.
