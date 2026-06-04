---
name: screenshots
description: Load the most recent N screenshots from ~/Desktop as visual context for the surrounding prompt. Use when the user appends /screenshots [N] to a request, or refers to "the latest screenshot(s)", "my recent screenshot", or a screenshot they just took. Default N is 1.
---

Load the most recent screenshots from `~/Desktop/` so they become visual context for whatever the user asked in the same message. This skill only *gathers* the images — the actual task lives in the rest of the user's prompt.

## Step 1 — Determine how many to load

The argument is the count N (e.g. `/screenshots 2` → N = 2).

- If no number is given, N = 1.
- If the argument is not a positive integer, default to N = 1 and note the assumption.

## Step 2 — Find the most recent N image files

Run this to list image files newest-first by modification time, then take the top N:

```
find ~/Desktop -maxdepth 1 -type f \
  \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) \
  -exec stat -f '%m %N' {} + | sort -rn | head -n N | cut -d' ' -f2-
```

Notes:
- Sort by modification time (`stat -f '%m'`), not by the date in the filename — a file may have been renamed or copied.
- `find` is used instead of a shell glob so the command works in both zsh and bash and never aborts when one extension has no matches (a bare `*.jpg` glob errors under zsh's default `nomatch`).
- `-iname` is case-insensitive, so `.PNG` etc. are caught too.
- Only images. Skip `.mov`/`.mp4` recordings and `.DS_Store`; this skill reads still images, which Read renders visually.
- If the command returns nothing (folder empty or missing), tell the user and stop.

## Step 3 — Read each selected screenshot

Read each path returned in Step 2 with the Read tool (it renders images visually). Read all N in a single batch of parallel Read calls.

## Step 4 — Hand back to the surrounding prompt

Do **not** treat this skill as the whole task. Once the images are loaded:

- If the user's message included an instruction alongside `/screenshots N`, carry that out using the screenshots as context.
- If `/screenshots N` was the entire message with no other instruction, give a brief description of what each screenshot shows and ask what they'd like done with it.

When referring to a screenshot, use its filename (and the timestamp it encodes) so it's clear which one you mean.
