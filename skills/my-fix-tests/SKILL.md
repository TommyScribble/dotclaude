---
name: my-fix-tests
description: Fix failing tests, reading failures from Wallaby rather than running Jest. Use when Tommy runs /my-fix-tests or asks to fix failing tests.
disable-model-invocation: true
---

1. Get the actual errors before changing anything. Read them from Wallaby (`mcp__wallaby__*`). In `website-front-end`, do not start Jest: it disrupts Tommy's dev server. If Wallaby isn't connected, ask Tommy to paste the failures.
2. Find the root cause. If the failure follows a change to text or labels, grep for that text across ALL test files before fixing, so every affected test is found at once.
3. Decide whether the test or the code is wrong. Fix the code when the test describes the intended behaviour, and say which one you changed and why.
4. Use data-driven assertions: derive expected values from fixtures (`mockData.name`, not `'Some Name'`). Hardcode only as a last resort.
5. Test data lives in `test/data/`, organised by domain. Add new fixtures there, not next to the component.
6. Do not import from `.tsx` files in test utilities: it pulls in SCSS and breaks.
7. Confirm the fix in Wallaby. If Wallaby isn't connected, give Tommy the exact `npx jest <file> --runInBand` command to run.
