# Storybook Reference

## Core concepts

- [Component Story Format (CSF3)](https://storybook.js.org/docs/api/csf) — the story file format this skill targets
- [Args](https://storybook.js.org/docs/writing-stories/args) — how args flow into stories and controls
- [ArgTypes](https://storybook.js.org/docs/api/argtypes) — control type mappings, disable/hide rules
- [Controls](https://storybook.js.org/docs/essentials/controls) — knob types and `parameters.controls.include`
- [Actions](https://storybook.js.org/docs/essentials/actions) — `{ action: '...' }` handler setup
- [Parameters](https://storybook.js.org/docs/api/parameters) — `layout`, `controls`, `docs`

## TypeScript

- [TypeScript support](https://storybook.js.org/docs/configure/typescript) — `Meta<typeof Component>`, `StoryObj<T>`
- [Typing stories](https://storybook.js.org/docs/writing-stories/typescript) — best practices for typed meta and story args

## Interactivity

- [useArgs()](https://storybook.js.org/docs/writing-stories/args#setting-args-from-within-a-story) — live arg mutation from within a render function

## Layouts

- [Layout parameter](https://storybook.js.org/docs/configure/story-layout) — `'padded'`, `'centered'`, `'fullscreen'`

## Versions used in this project

- `@storybook/react` — check `package.json` for pinned version
- `@storybook/preview-api` — provides `useArgs()`
