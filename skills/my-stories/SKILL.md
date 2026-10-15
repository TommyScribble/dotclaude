---
name: my-stories
description: Generate Storybook CSF3 story files for a React component in website-front-end
disable-model-invocation: true
---

Generate Storybook story files for the component code provided by the user.

If no component code was provided, ask the user to paste the component source before proceeding.

## Output rules

- Default: return ONE file `<Name>.stories.tsx`.
- If clearly beneficial (complex molecule/organism/page): also return `test-data.ts`.
- If multiple meaningful states exist: use the Adaptive TS scaffold with a `preset` select control + `test-data.ts`. Presets should live in `test-data.ts` as a `PRESETS` constant (screaming snake case).
- If two files: separate with a single line `---`.
- No explanations.

## Conventions

- React 18; TS preferred (use JS if input is JS).
- CSF3; typed meta: `const meta: Meta<typeof Component> = { ... }` (always use `typeof Component`, not the props type directly).
- Title: `"<Group>/<Name>"`; default layout `padded`.

## Rules

- Don't widen types or change prop names.
- Keep a single `Default` story unless multiple meaningful states exist; in that case use the Adaptive scaffold with a `preset` select control rather than separate named stories.
- Use `preset` + derived `render` only when it adds real value.
- **Preset override rule**: in the `render` function, ALWAYS spread in the order `{...rest} {...derived}` so that preset-driven props always win over stale arg values. Never reverse this order.
- **Preset-owned props rule**: any prop whose value comes entirely from the preset MUST be disabled in `argTypes` via `{ table: { disable: true } }`. This prevents Storybook from holding a stale independent copy that would override the preset. Omitting this is a bug.
- Use `useArgs()` only for live interactivity.
- Hide internal/derived props; keep copy short/realistic.
- **Custom StoryArgs rule**: If `StoryArgs` does not extend the component's own props (e.g. it uses wrapper args like `count` that replace rather than augment the props), omit `component` from meta to avoid type incompatibility. Only include `component` when `StoryArgs` is the component's props type or a superset of it.

## Controls (inference + hygiene)

- Pick the right control, and show only a small curated set via `parameters.controls.include`.
- Map types → controls:
  - boolean → `{ control: { type: 'boolean' } }`
  - string → `{ control: { type: 'text' } }`
  - number → `{ control: { type: 'number' } }` (or `{ type: 'range' }` with `min/max/step` if bounded)
  - string union ≤4 → `radio`; >4 → `select`
  - enum / `as const` → `select` with values
  - color-ish → `'color'`
  - Date/`date` → `'date'`
- Handlers → `{ action: '…', table: { disable: true } }`
- Always disable (table): `className`, `style`, `as`, `id`, `ref`, `key`, `data-*`, `aria-*`, `testId`, complex objects better handled by presets, any prop derived from or owned by `preset`.

## Minimal TS story (use when simple)

```tsx
import type { Meta, StoryObj } from '@storybook/react'
import Component from './index'

const meta: Meta<typeof Component> = {
  title: 'Components/Component',
  component: Component,
  parameters: { layout: 'padded' },
}
export default meta

type Story = StoryObj<typeof Component>
export const Default: Story = {}
```

## Adaptive TS scaffold (use when multiple meaningful states exist)

```tsx
import type { Meta, StoryObj } from '@storybook/react'
import Component, { type ComponentProps } from './index'
import { PRESETS, stubbedComponentProps } from './test-data'

type PresetKey = keyof typeof PRESETS
type StoryArgs = ComponentProps & { preset?: PresetKey }

const meta: Meta<StoryArgs> = {
  title: 'Molecules/Component',
  component: Component,
  args: { ...stubbedComponentProps, preset: 'BASE' },
  argTypes: {
    preset: { control: { type: 'select' }, options: Object.keys(PRESETS) },
    disabled: { control: { type: 'boolean' } },
    size: { control: { type: 'radio' }, options: ['sm', 'md', 'lg'] },
    variant: { control: { type: 'select' }, options: ['primary', 'secondary'] },
    onClick: { action: 'clicked', table: { disable: true } },
    className: { table: { disable: true } },
    style: { table: { disable: true } },
    // ↓ Every prop owned by the preset MUST be disabled here
    presetOwnedProp: { table: { disable: true } },
  },
  parameters: {
    layout: 'padded',
    controls: {
      include: ['preset', 'size', 'variant', 'disabled'],
      expanded: true,
    },
  },
}
export default meta

type Story = StoryObj<StoryArgs>
export const Default: Story = {
  render: ({ preset, ...rest }) => {
    const derived = PRESETS[(preset ?? 'BASE') as PresetKey]
    // derived spreads LAST so preset values always win over stale args
    return <Component {...rest} {...derived} />
  },
}
```

## Optional useArgs() harness (only for live interactivity)

```tsx
import { useArgs } from '@storybook/preview-api'
export const Interactive: Story = {
  render: (initial) => {
    const [{ value }, set] = useArgs()
    return (
      <Component
        value={value}
        onChange={(v) => set({ value: v })}
        {...initial}
      />
    )
  },
}
```

## Optional overlay/fullscreen wrapper

```tsx
export const FullscreenDemo: Story = {
  parameters: { layout: 'fullscreen', docs: { story: { height: '70vh' } } },
  render: (args) => (
    <div style={{ height: '70vh', padding: 24 }}>
      <Component {...args} />
    </div>
  ),
}
```

## Minimal test-data.ts (include only if justified)

```ts
import type { ComponentProps } from './index'

export const PRESETS: Record<string, ComponentProps> = {
  BASE: {
    /* minimal valid props */
  },
  RICH: {
    /* fuller variant */
  },
}

export const stubbedComponentProps: ComponentProps = { ...PRESETS.BASE }
```

## Decision logic

- If props are simple and the component renders with defaults: use Minimal TS story.
- If multiple meaningful states exist: use Adaptive TS scaffold with a `preset` select control + `test-data.ts`.
- If input state must change live: add useArgs() harness.
- If overlay/portal: add Fullscreen wrapper.

## Input formats

- If the user pastes TSX/TS: generate TS stories.
- If the user pastes JSX/JS: generate JS stories.
- If the user pastes only the prop types or an interface: produce a best-guess story with realistic args.

## Strict formatting

- Output only the files.
- Wrap each file in a fenced code block with the correct language tag.
- No semicolons (project ESLint rule: `semi: ['error', 'never']`).
