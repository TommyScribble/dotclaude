---
name: event-model-ticket
description: >
  Slice one flow from an event modelling board in FigJam into tickets, grill the user on one slice,
  then draft its Monday ticket. Use when the user shares a Figma or FigJam link to an event modelling
  session and wants tickets for a flow, slice or event, or says "slice this flow", "ticket this",
  "grill me on this slice".
argument-hint: A FigJam link to a flow on the board (its section or title), plus the Figma design file for its screens.
---

# Event model → Monday ticket

Turn one **flow** on an event modelling board (Sign in, Create an account, Reset password…) into a
set of slices, then interview the user about **one slice** until it is a ticket someone can pick up
cold. The board and the designs are the starting point, not the spec.

Needs the **Figma MCP plugin** to read the files; if it is missing, say so and stop. Checking the
board for existing tickets (step 3) and posting (step 6) need **`/monday-ticket`**; without it, ask
the user for the flow's existing ticket titles and stop at the draft.

The outline script lives next to this file:
`~/.claude/skills/event-model-ticket/scripts/figma_outline.py`. Run it with `python3 -I`.

## What a slice is

A slice is **one path a user can take through a flow, end to end**: from the screen they start on,
through every system it touches, to what they see at the end. It crosses swimlanes.

A slice that only touches the website is one ticket. A slice that touches the **Website API or
Cognito** becomes **two tickets**: a frontend ticket (the website lane: pages, components, calling the
API) and a backend ticket (the API and Cognito lanes, plus the emails and messages they send). Both
carry the same slice name and the same API contract, and the frontend ticket depends on the backend
one.

A flow splits **by variant**: each way through the flow is its own slice. Email and password is one;
social sign in is another. Whether to also split by path (happy and sad) is asked per flow in step 3.

A single event box ("Account created in DB") is never a slice on its own; it is one step inside one.

Some flows are **screens only**: an area of pages (an account area with a dashboard, lists and
settings) that the board lays out as wireframes, with no commands, events or swimlanes. There are no
variants to split by, so a slice is **one page, or one page with its detail page** (a list and the
detail page its cards open). The rules come from the design notes, and the contracts come from the
grill and from the endpoints the code already calls.

## 1. Read the board

The user gives a FigJam link (`figma.com/board/<fileKey>/…?node-id=<a-b>`). Turn its `node-id` into
`a:b` for the MCP calls; a link with no `node-id` means the whole board, so use `0:1`.

1. `create_session` with the file key, then `get_figjam` on the node with `includeImagesOfNodes: false`.
2. A board is usually too big to return inline, and the tool saves it to a file. Outline that file
   instead of reading it whole. A result small enough to come back inline can be read directly.

   ```sh
   python3 -I ~/.claude/skills/event-model-ticket/scripts/figma_outline.py <saved-file> --within <section-id>
   python3 -I ~/.claude/skills/event-model-ticket/scripts/figma_outline.py <saved-file> --near <node-id>
   ```

   It prints the visible text (boxes, stickies, sections, labels) with absolute positions, grouped
   by screen frame, then every arrow that touches it, labelled arrows included. Use `--within` when
   the flow is a section, and `--near` on the flow's title or any box or frame in it when it isn't,
   raising `--radius` (default 4000) until the whole flow is in view. Include the flow's
   failure-state section too.
3. `get_screenshot` on the flow's section, or on its boxes and frames when it has no section, and
   look at it. The outline cannot tell you box **colours**, and on these boards colour is the box
   type. Match colours against the board's legend (boxes labelled `View`, `Command`, `Event`).
4. If the flow has no command or event boxes near its screens, it is a screens-only flow (see
   *What a slice is*). Say so, and expect the design notes to carry the rules.
5. If the link points at the whole board, list the flows you found (the flow titles, and sections
   such as `Failure states / <flow>`) and ask which one.

### How the boards are laid out

- **Timeline runs left to right**: a screen (wireframe) → the command it sends → the event(s) that
  result → the views and screens that read them.
- **Swimlanes run top to bottom**, labelled on the left (e.g. `Email / Whatsapp`, `Cognito`,
  `Website`, `AFS API`). A box belongs to the lane whose label is level with it.
- **Commands carry their payload**, often as a JSON-ish example (`{ email: '…', password: '…' }`).
- **Labelled arrows are branches** (`Expired`, `Email already registered`), usually between screens.
  **Failure-state sections** hold the unhappy paths for a flow.
- **Violet stickies are open questions.** Yellow stickies are to-do lists, not requirements.

These are conventions, not rules. When a board does it differently, follow the board and say what
you assumed.

## 2. Read the designs

If the user gave a link to the design file (`figma.com/design/<fileKey>/…`), read the screens for the
flow. The designs hold rules the board leaves out.

1. `get_metadata` on the file key with **no** node id lists the pages. The **area pages** are every
   page except separators (names made only of dashes, of any length) and working pages
   (Components, View in context, Prototype, Playground, Wireframes, Research, Cover). There is
   usually one per area: menu, sign in, a wizard, the account area, emails, prompt cards.
   List the area pages back to the user with a count, so a missing page gets noticed.
   **Check every area page, not just the obvious one.** A flow usually spans several. Creating an
   account, for example, touches the sign-in page (form and failure states), the emails page
   (verification email), the wizard page (where the user lands after verifying) and the prompt-card
   page (the entry points that send people to sign up).
2. `get_metadata` on each page, and outline the saved file with the same script, whole or
   `--within <flow-frame-id>`.

   Each top-level frame or section is a flow (`Sign in & create an account / mobile`,
   `Failed states / Create an account`). The label above each screen names its state, and the text
   under the label is often a **rule**: "Shown for every submission", "There is no 'account
   already exists' state". Treat those as requirements.
3. `get_screenshot` on each state frame in the slice, and on each `DS-comment-box` instance, and look
   at them. Comment boxes don't show their text in the metadata, and a whole flow frame is too wide
   to read at the default size; raise `maxDimension` if a single frame is still unreadable.
   The screenshot URLs expire quickly, so download each one straight away (`curl -fsSL -o <file>
   <url>`) into a folder in the scratchpad, named after its state (`desktop-signed-out.png`,
   `help-dropdown.png`). These files become the ticket's images.
4. Note anything labelled as out of the phase ("not for phase 1"): it is out of scope. Email designs
   often carry a `Template ID:` (the SendGrid template); keep it for the ticket, but check it
   against the email inventory (see *Side effects* in the grill) before trusting it.
5. Map each screen on the board to its design frame. Where the board and the designs disagree,
   raise it in the grill. Don't pick a side yourself.

## 3. Propose the slices

Work out the slices for the flow from what you read:

- **Variants** come from the board's branches near the start of the flow (a password command and an
  SSO command, say) and from the design's variants (a social sign-in overlay next to the form).
- **Each variant** runs to its successful end, including where the user lands (a dashboard, the
  page they started on, a wizard).
- **Failure states** come from the flow's failure-state section on the board and its
  `Failed states / <flow>` frame in the designs. Note which variant each one belongs to.
- **For a screens-only flow**, propose one slice per page instead, with its detail page and its
  empty, loading and error states in the same slice. Check the code for each page's existing route
  and endpoints, and mark a slice **FE + BE** when the design shows data those endpoints don't
  return. A page that shows cards from other pages (a dashboard) depends on the slices whose
  backends supply that data.

Ask whether to split happy and sad paths; it is never the default, because teams split this way
only to cut the size of each ticket. Base the recommendation on size: a couple of failure states with
one shared error screen belong in their variant's slice; many failure states, or ones that need
their own screens, emails or backend handling, are worth a separate slice.

Then look at what is already on the board: use `/monday-ticket`'s `list` and find any ticket whose
title names this flow, so you don't propose a slice that already has a ticket, and so a new one fits
the existing names and prefix.

**Number slices only when they depend on each other.** Slice B depends on slice A when B cannot be
completed until A is done (social sign in is added to the page that email sign in creates). A chain
of dependent slices is numbered `01`, `02`, `03` in the order they have to be built; a slice nothing
depends on, and which depends on nothing, gets no number. Continue an existing sequence on the board
rather than starting a new one. A number that a posted ticket already uses in a planned title is
taken, even though that ticket doesn't exist yet.

**A planned title wins over numbering.** When a posted ticket already names a slice by a planned
title, keep that title exactly, numbered or not, even if this rule would number it differently, and
state the dependency in the body instead. A split slice appends ` – FE` or ` – BE` to the planned
title. Say in the playback which titles are fixed this way.

Play the list back with what each slice covers, its dependencies, the board evidence, and
**FE + BE** where it becomes two tickets:

```
Create an account 01: Email & Password                       FE + BE
  form → "Check your email" → verify link → profile wizard
  failures: email already registered, breach check, expired link, network error
  board 782:32515 → 782:34208 → 782:34371, 781:40586; designs 2498:31136, 3067:90256
Create an account 02: Social                                FE + BE
  depends on 01: adds social sign up to the form 01 creates
  failures: failed social sign in
```

With happy and sad paths split, the same flow would list `01: Email & Password (Happy path)`,
`02: Social (Happy path)` and `03: Create an account (Sad path)`.

The user confirms, merges, splits or renames slices, then picks **one** to grill. A split slice is
grilled once and drafted as both tickets. Run the skill again for the next one.

## 4. Grill

Grill the user on the chosen slice as `/grill-me` does: one question at a time, and look up anything
the code can answer (an existing page, endpoint or component) instead of asking. With each question,
give your recommended answer and the evidence behind it from the board or the designs, so they can
say "yes" and move on.

Walk these branches in order. Skip any the slice doesn't touch, and record decisions as you go:

1. **Scope.** Which variant, and which paths if the flow was split, stated as a qualifier ("email
   and password only, happy path only: an account already exists and uses email and password").
   Who it applies to.
2. **Entry points.** Every way a user reaches the start: header buttons, prompt cards, a direct link
   to a private page.
3. **The path.** Screen by screen and system by system, what happens: each command, what it
   records, what each system returns.
4. **Outcomes.** Where the user ends up for each entry point, including redirects
   (`?redirect=…`), and for each failure state the slice covers, the condition and what the user
   sees.
5. **Screens and copy.** The design states in this slice. Quote copy exactly; placeholders like
   `{verifyExpiry}` are open questions until someone sets a value.
6. **Knock-on changes outside the slice.** Pages, components and apps the flow doesn't show but
   that have to change to stay consistent with it. Find candidates before asking:
   - **The same copy elsewhere**: search the codebase for the slice's new copy and for the copy it
     replaces (support options, phone numbers, button labels). The home page and `/contact-us`
     repeating the help overlay's support options is the typical case.
   - **The same component elsewhere**: a header, button or overlay this slice changes that other
     flows also use (the booking flow's focused header).
   - **Other user types and apps**: the same change for signed-in landlords in landlord admin, or
     for signed-out users.
   - **Designs in other files**: a page outside this design file. Ask for the link; don't guess it.

   Ask about each candidate in turn: does it belong in this ticket, a ticket of its own, or out of
   scope? Anything kept goes in the ticket with its design link and a note on the existing component
   or page it changes.

   Also search the code for **existing components that already look or behave like the design**
   (a tooltip with an arrow and **Got it**, a hover label, an overlay, an account menu), even on
   unrelated pages. Name each one in the ticket, with its path, as the thing to reuse or extend.
7. **Contracts.** For a split slice, always: every call between frontend and backend, with its
   request, its response and each status code. This is the line between the two tickets, so it
   must be settled before either is drafted. For a website-only slice, skip it.
8. **Side effects.** Emails and messages (template ID, link expiry), third-party calls, rate limits.
   For each email, look it up in the
   [AFS Email Inventory](https://accommodation-for-students-team.monday.com/boards/5091875916)
   (`/monday-ticket list 5091875916`) before calling it new. Its **Hosted In** column says where an
   existing email lives: `SendGrid` (a SendGrid dynamic template) or `New World` (the
   `afs-emails-react` repo). State in the ticket whether the email is new or existing, and where it
   lives or will live. Ask which one a new email should use; don't assume.
9. **Open questions.** Every sticky in the slice. Resolve it now, or park it with an owner and say
   whether it blocks the work.
10. **Dependencies.** Which other slices this one needs finished first, and why, plus anything
    outside the board (Cognito setup, Apple or Meta developer accounts).
11. **Board columns, last.** Priority, value stream and any other column the user wants set. Ask;
    never guess, and leave unset what they don't answer. `/monday-ticket` sets them as column
    values, with ids and labels from its `describe`.

Stop when every branch is decided or explicitly parked. If an answer contradicts the board, say so
and suggest the user update the board. Never edit the Figma file.

## 5. Draft the ticket

Write the ticket as `/monday-ticket` asks: its guidance on what a good ticket contains and how to
format the body, schemas included, applies here unchanged. This skill only adds:

- **Title:** `<PREFIX>: <Flow> <NN>: <Variant>`, dropping `<NN>: ` for a slice with no dependency
  chain, and adding ` (Happy path)` or ` (Sad path)` only when the flow was split that way. A split
  slice ends in ` – FE` or ` – BE`; both tickets keep the slice's number. Use the prefix the flow's
  existing tickets use (e.g. `SA:`); if there are none, ask.
- **For a split slice, two drafts.** Each covers only its own lanes and refers to the other for the
  rest. Both contain the same contract, copied exactly.
- **A summary for people, first.** Open the body with a `Summary` heading and a bullet list of
  three to five short points a product owner or tester could scan in a few seconds: what the user
  can now see or do, and where. Lead a point with a bold label when it is about one place or
  device (**Desktop:**, **Mobile:**), and end with **Waits on:** naming the slices it depends on
  in plain words, when there are any. No code, endpoints, file paths, node ids or field names; those belong
  in the details. A divider (`---` on its own paragraph) follows the summary, and everything after
  it sits under a `Details` heading: the exhaustive body, written
  for developers and agents to work from. The summary never states anything the details don't.
- **Heading levels**: in the markdown body, `Summary`, `Details` and every section after `Details`
  (`Designs and board`, `Changes`, `Contract`, `Out of scope`, `Dependencies`,
  `Acceptance criteria`…) are `##`; sub-sections under `Changes` are `###`. `/monday-ticket`
  converts `##` to `<h3>` and `###` to `<h4>`, which is what the board's tickets use. Don't nest
  the sections one level under `Details`: `###` and `####` come out a size too small, and fixing
  that later means another edit, with every image passed again.
- **The scope qualifier** from the grill, as the opening line of the details.
- **Links**: the design flow frame and the board flow. Build them as
  `https://www.figma.com/design/<fileKey>/<file-name>?node-id=<a-b>` and
  `https://www.figma.com/board/<fileKey>/<file-name>?node-id=<a-b>`, with the `:` in the node id
  turned into `-`.
- **Dependencies, stated in the body**: each slice this one depends on, by its full ticket title and
  URL, with one line on why ("adds social sign in to the /sign-in page created in Sign in 01"). A
  slice that hasn't been posted yet is named by its planned title.
- **Screenshots**: the design states this ticket builds, from step 2, attached as images. Pick the
  ones a developer needs (each screen state and its comment boxes), leave out the rest, and list
  the files with the draft so the user approves them with it. For a split slice, the frontend ticket
  gets the screens; the backend ticket gets only images that show backend behaviour, if any.
- **Copy that differs from the designs**: when the grill changed anything the attached images
  still show (copy, a label, a missing or extra option), open Changes with a section listing each
  difference: what the ticket says, and what the design shows.

Mark anything inferred rather than confirmed by the user, the board or the designs as
**(assumed)**. A confident ticket that is wrong costs more than a hedged one.

Three rules for the body:

- **Explain only this ticket.** Don't explain how other slices, pages or flows behave, or why
  something is left out. Dependencies name other tickets; they don't describe them.
- **Out of scope lists only what a developer might otherwise build here**: something the designs
  show, the code nearby invites, or the grill excluded. State the thing left out, not the ticket
  that owns it, and never list sibling slices just because they exist. Leave the section out when
  nothing qualifies.
- **Use real routes.** Every example URL or page must exist: check the app's routes in the code
  before writing it, or ask. Never make one up to illustrate a point.
- **Test only what this slice builds.** Acceptance criteria check this slice's own behaviour. When
  the slice links to something another slice builds, check the link, not what happens after it (a
  header ticket checks that **Sign in** points to `/sign-in`, not that signing in works).

## 6. Post

Hand over to `/monday-ticket`, which shows the user the draft and **waits for approval** before
posting. Pass on the ticket id and URL it reports.

Then attach the approved screenshots to the ticket's body: `get` the ticket for its first update's
id, `attach` the files to that update in the order they appear in the body, and `get` again to
confirm they landed.

Post dependent slices in order, so each ticket can link to the real URL of the one before it. For a
split slice, post the backend ticket first, then the frontend ticket with its dependency on the
backend one, then comment on the backend ticket with the link to the frontend one.

Planned titles are promises other tickets rely on:

- **Before posting**, search the board's tickets for this slice's planned title, wherever it
  appears (Dependencies, Out of scope, the opening line), including tickets from earlier sessions:
  `list` the board, `get` each ticket whose title shares the flow's prefix, and look in its body.
  Offer to replace each mention with a link to the new ticket.
- **When a planned slice is dropped**, offer to edit every ticket that names it, so none points at a
  ticket that will never exist.

Each follow-up comment or edit is outward-facing too: show the user the exact text and wait for
approval, as for posting. Editing a body removes its images unless they're passed again, and the
scratchpad doesn't survive between sessions; for an edit in a later session, fetch the screenshots
again from Figma, with the same node ids and file names, before calling `edit-update`.

When the last ticket for the flow is posted, list every design discrepancy the grill found (copy the
user overrode, frames missing an item, unclear frame names), so the user can pass them to the
designer. Draft a message to the designer only if asked.
