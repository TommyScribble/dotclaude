---
name: monday-ticket
description: >
  Read and write tickets on the team's Monday board.
  Use when the user asks to file, create, post, fetch, read, edit, rename, or comment on a Monday ticket,
  or says "put this on the board". Also use after producing a ticket as markdown,
  to offer posting it. Do not use for GitHub issues — the team does not use them.
---

# Monday Ticket

Read and write tickets on the team's Monday board. This skill can **only** read tickets, create
them, comment on them, and edit them (title, body, non-status columns). It cannot delete, archive,
move, reassign, change a status, or alter board structure. If the user asks for one of those, say
it is not wired up and offer to add it.

## Setup state

Board and group IDs live in `config.json` next to this file. If that file is missing or still has
placeholder values, run the setup below before anything else.

## Commands

All via `scripts/monday.mjs` (Node 20+, no dependencies):

```
node scripts/monday.mjs describe <boardId>                      # groups, columns, label values
node scripts/monday.mjs list <boardId> [limit]                  # recent tickets
node scripts/monday.mjs get <itemId>                            # one ticket + its updates
node scripts/monday.mjs create <boardId> <groupId|""> <title> [bodyFile] [columnsJsonFile]
node scripts/monday.mjs comment <itemId> <bodyFile>             # append an update
node scripts/monday.mjs rename <itemId> <title>                  # change the ticket title
node scripts/monday.mjs edit-update <updateId> <bodyFile>        # rewrite an existing update
node scripts/monday.mjs set-columns <itemId> <columnsJsonFile>   # change column values (not status)
```

`get` prints each update's id (`--- update <id> · …`). A ticket's body is its **first** update, so
editing the body means `edit-update` on that id.

`create` prints the new item id. Build the ticket URL as
`https://accommodation-for-students-team.monday.com/boards/<boardId>/pulses/<itemId>`.

## Authentication

The token is read from the macOS keychain, falling back to `MONDAY_API_TOKEN`:

```
security add-generic-password -s monday-api-token -a "$USER" -w
```

Never print the token, never pass it as a command argument, never write it into a file or a
commit. If it is missing the script says so and exits — pass that message on rather than
inventing a workaround.

Note the token itself carries full account permissions; the read/write-tickets limit is enforced
by this script's command surface, not by the credential.

## What a good ticket contains

Spend the effort here, not on board metadata. A ticket someone else can pick up cold has:

- **A title that states the defect**, not the symptom — "getLocations returns undefined on failure
  and crashes SSR on four routes", not "Fix property page error".
- **Root cause**, with the offending code quoted and its `file:line`. Name the mechanism, not the
  area.
- **Every affected call site**, each with `file:line` — including ones not yet reported, so the fix
  is complete rather than whack-a-mole.
- **Evidence**, with the specific numbers: issue ids, user and event counts, dates, the time window.
  Say explicitly what the evidence *rules out* as well as what it shows.
- **A proposed fix that names its trade-offs.** If one call site needs different handling from the
  rest, say so and say why — that is usually the part a reviewer would otherwise get wrong.
- **Acceptance criteria someone else could verify** without re-deriving the investigation.

State plainly when something is inferred rather than established, and correct it in the ticket if it
later turns out wrong. A confident ticket that is wrong costs more than a hedged one.

## Writing a ticket

1. Write the ticket body as markdown to a file first — use the scratchpad directory, or
   `~/Documents/Obsidian Vault/claude-docs/` when it is a document worth keeping.
2. Show the user the title, target group, and body, and **wait for approval**. Posting to the
   board is outward-facing and visible to the team; never post unprompted.
3. Create it, then report the item id and URL.

Monday updates take **HTML, not markdown**. A body file ending in `.md` is converted
automatically — headings, bold, inline code, fenced code blocks, links and both list styles.
Tables are not converted, so write them as lists. Nested lists are flattened to one level, so keep
lists flat and group items under sub-headings instead. A file not ending in `.md` is posted verbatim,
for when you want to hand-write the HTML.

Column values are a JSON object keyed by column id, written to a file and passed as the last
argument. Get the ids and valid label values from `describe` — never guess them:

```json
{ "status": { "label": "Backlog" }, "priority": { "label": "High" } }
```

## Editing a ticket

1. `get` the ticket first and read the current title, columns and body — edit from what is there,
   not from memory.
2. Write the new body as a file (markdown is converted, as for comments), and show the user the
   exact change — old versus new title, the changed sections of the body, or the column values —
   and **wait for approval**. An edit overwrites what the team sees; there is no undo in this script.
3. Apply it, then `get` again to confirm it landed.

`set-columns` refuses a `status` key. Moving a ticket between statuses stays a manual board action.

## First-time setup

1. Ask the user for the board id — it is in the board URL, `/boards/<id>`.
2. Ask them to store the token via the keychain command above, **in their own terminal**, so it
   never lands in a transcript.
3. Run `describe <boardId>` and record the group ids, column ids and label values in
   `config.json`.
4. Confirm the mapping with the user before the first real ticket.
