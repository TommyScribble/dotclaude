---
name: my-styling
description: Write and review SCSS styles following website-front-end conventions
disable-model-invocation: true
---

Apply these conventions when writing or reviewing SCSS styles in this codebase.

## File Structure

- One `styles.module.scss` per component, co-located in the component folder (always this exact filename).
- Every file starts with these two imports:
  ```scss
  @import '@afs/styles/settings/settings';
  @import '@afs/styles/tools/tools';
  ```
- Use section comment headers to organise the file:
  ```scss
  // ==========================================================================
  // Section Name
  // ==========================================================================
  ```

## Class Naming

- **camelCase** for all class names (`.cardInner`, `.searchButtonMobile`, `.textWrapper`).
- Variants use compound names (`.cardWithButton`, `.wrapperSticky`), not BEM modifiers.
- State classes are separate (`.disabled`, `.active`, `.visible`), applied conditionally via `classnames`.

## Consuming Styles in Components

```tsx
import styles from './styles.module.scss'
import classNames from 'classnames'

// Simple
<div className={styles.card}>

// Conditional
<div className={classNames(styles.card, { [styles.active]: isActive })}>
```

- Components that accept external styling define `className?: string` and merge it onto the root element: `classNames(styles.base, className)`.

## Overriding a Child Component's Styles

Two single-class rules from different CSS modules on the same element tie on specificity, so bundle order decides, and Next orders CSS per page across shared chunks. An override that relies on order works on one route and breaks on another. Make it win on specificity instead:

```scss
// Loses or wins depending on load order: ties with Link's .alpha
.link { color: $colour-charlie; }

// Scoped under an ancestor class from this module
.header .heading { font-size: 20px; }

// Type-qualified when there is no classed ancestor
a.link { color: $colour-charlie; }
label.labelDisabled:hover { cursor: not-allowed; }
```

- Raise only the properties that compete with the child, not the whole block, unless nothing else in it is contested.
- Check the module's own state and sibling rules still win afterwards (`.list ~ .buttonMobile` is 0,2,0 and still beats `button.showMoreBtn` at 0,1,1). A base rule that gains specificity can also outrank its own `:hover`/disabled rules, so qualify those to match.
- Check callers that pass `className` into the component: their single-class overrides now lose to the raised rule.
- If a declaration only repeats what the child already applies, delete it.
- Never fix a clash by moving imports. That only moves the break to another page.
- Storybook's injected CSS order differs from Next's, so a story that looks right proves nothing about load order. Verify on a production build (`next start`) or with `node scripts/css-clash-audit/cli.js` after building.
- The `afs/override-specificity` ESLint rule (warn) flags this in the editor. It traces the class into the child's JSX, wrappers included, and compares it with the child's rules for the element that receives it. "Sets X, which Child also sets on that element" means raise specificity. "Repeats X with the value Child already sets" means delete the declaration: it's only said when the child always applies that value, never when it comes from a variant the child adds conditionally. It reads source only: it can't see `@extend` or values that only match once compiled (`gutter(1)` against `8px`), so the clash audit stays the check.

## Spacing

- 8px grid via the `gutter()` function: `gutter(1)` = 8px, `gutter(2)` = 16px, `gutter(3)` = 24px, etc.
- Half values are valid: `gutter(1.5)` = 12px, `gutter(2.5)` = 20px.
- Use `@include responsive-gutters` for consistent page-level padding.
- Use `@include padding-left(gutter(3), gutter(5), 720px, 1048px)` for responsive spacing between two breakpoints.

## Responsive Design

- **Mobile-first.** Write base (unqualified) styles for the smallest screen, then layer larger-screen overrides on top. **Prefer `@include above(...)`** to `@include below(...)` and `@include between(...)` wherever possible — reach for `below()`/`between()` only when a rule genuinely can't be expressed mobile-first.
- To scope a rule to a band, **prefer two `above()` statements** (set the value at the lower bound, reset it at the upper bound) over a single `@include between(...)`. Only use `between()` when the band genuinely can't be expressed that way.
- Mixin-based media queries (never raw `@media`):
  ```scss
  .card {
    flex-direction: column; // mobile default

    @include above(820px) {
      flex-direction: row; // preferred: layer larger-screen styles on top
    }
  }

  // Preferred way to target a band — two above() statements:
  .banner {
    @include above(720px) { display: block; }
    @include above(820px) { display: none; }
  }

  @include below(720px) { }         // use only when above() won't do
  @include between(720px, 820px) { } // use only when a band can't be expressed with two above()
  ```
- Named breakpoints from `@afs/styles`: `xxsmall` (375px), `xsmall` (480px), `small` (660px), `medium` (768px), `large` (960px), `xlarge` (1024px), `xxlarge` (1280px).
- Local breakpoint variables are fine when a component needs a specific value: `$single-column-breakpoint: 820px;`.
- Fluid sizing: `@include responsiveSize('font-size', 16px, 20px)`.

## Design Tokens

### Colours
- Palette variables from `@afs/styles`: `$colour-alpha`, `$colour-alpha-dark`, `$colour-alpha-light-400`, `$colour-charlie`, `$colour-foxtrot`, `$colour-white`, `$colour-cool-grey-100` through `$colour-cool-grey-900`, `$colour-warm-grey-50` through `$colour-warm-grey-400`.

### Typography
- **Prefer `@include font(...)`** for all text and heading styles:
  ```scss
  @include font('2xs', $responsive-font-size: false);
  ```
- **Deprecated — do not use in new work:** `@mixin p-tiny()`, `@mixin p-small()`, `@mixin p-normal()`, `@mixin p-large()`, and `@include heading(...)`. These have been superseded by `@include font(...)`; migrate to it rather than copying existing usages.
- Still available: `@mixin label()`, `@mixin button-label()`.

### Transitions & Animation
- Use the shared timing values: `map-get($core-interactions, 'timing')` (0.3s), `map-get($core-interactions, 'easing')`, `map-get($core-interactions, 'transition')`.
- Define `@keyframes` locally within the module file.
- Respect reduced motion: `@media (prefers-reduced-motion: reduce)`.

### Shadows
- `@function shadow()` and `@mixin focus-shadow`.

## Focus & Accessibility

- Keyboard focus styles use the global tabbing class:
  ```scss
  :global(.user-is-tabbing) &:focus {
    @include focus-shadow;
  }
  ```
- Screen-reader-only content: `@include hidden-visually()`.

## Nesting

- Keep nesting shallow — 1-2 levels maximum.
- Nest only for pseudo-selectors (`:hover`, `::before`), state (`.card.active`), and `:global()` selectors.

## Third-Party Style Overrides

- Use `:global()` scoped under a local class:
  ```scss
  .slider :global(.carousel__slider-tray-wrapper) {
    width: 100%;
  }
  ```

## CSS Custom Properties

- Use sparingly and strategically — for values that change at breakpoints or are set dynamically from JS:
  ```scss
  .base {
    --card-w: 187px;
    @include above(small) { --card-w: 208px; }
  }
  .card { width: var(--card-w); }
  ```
- When setting from JS, cast with `as CSSProperties`: `style={{ '--card-w': '200px' } as CSSProperties}`.

## Data Attributes for Style Triggers

- Use `data-*` attributes for animation/interaction states rather than toggling many classes:
  ```scss
  .wrapper[data-interacted='true'] .icon {
    animation: draw-burst 1.2s ease-out forwards;
  }
  ```

## Things to Avoid

- No CSS-in-JS or inline styles (except for CSS custom property injection).
- No `!important` unless clearly justified.
- No single-class override of another module's class on the same element (see "Overriding a Child Component's Styles").
- No deep nesting (3+ levels).
- No raw `@media` queries — always use the `above()`, `below()`, or `between()` mixins.
- No shared/utility SCSS files — styles are either local to the component or from `@afs/styles`.
- No semicolons in TS/TSX (ESLint rule).
- Single quotes in SCSS.
