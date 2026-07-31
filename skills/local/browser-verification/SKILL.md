---
name: browser-verification
description: Verify a UI slice by driving the running app in Chrome through the chrome-devtools MCP server — four breakpoints, both themes, JS on and off, console and network clean, contrast and tap targets measured, Lighthouse per theme. Use it as the exit gate of any slice that adds or changes a screen, navigation, or a UI component, run by an agent distinct from the one that implemented it. It reads the run recipe from .harness/config.yml to launch the app, and the design reference from docs/design.md to compare against. Also use it as a review grid to decide whether a frontend change may be called done. Trigger on "test the UI", "check it in the browser", "vérifie dans le navigateur", "final tests", "visual check", "is the frontend done", or when the orchestrator reaches phase 6b — even if no one says the words "browser verification".
---

# Browser Verification

This skill has two modes. In **guide mode** it drives the running app and produces a numbered list of gaps. In **review mode** it decides whether a UI slice may be called done. Read it all; the review grid at the end is the contract.

This is the concrete implementation of the evaluator clause in the `orchestrator` skill: *the evaluator should exercise the running result, not just read the diff — behavior is verified by use, not by inspection*. A green build proves the code compiles. Green AI-written tests prove the code does what the same agent thought it should do. Neither proves the page renders correctly at 390px in dark mode. That last gap is what this skill closes, and it is the reason the harness's gap map lists a behaviour harness as an open item.

**Run it as a separate agent.** The agent that implemented the slice does not verify its own UI — evaluator separation is the whole point (see `orchestrator`, "The evaluator is a separate, skeptical agent"). The verifier receives the slice's acceptance criteria and the design reference, never the implementer's summary of what it did.

## When this runs

Same trigger list as the design phase (3b): the slice **adds or changes a screen, changes navigation, adds or restyles UI components**, or architecture flagged a frontend surface. Skip it for purely backend slices — a new API endpoint, a batch job, a service-to-service integration.

Where it sits: **pre-merge, after the automated suite is green**. It is not a CI job (it needs a browser, a human-scale judgment, and a frontier-tier model); `ci-setup`'s `test-e2e` job stays the automated half. Both are necessary; neither replaces the other.

## What to read first

1. **`.harness/config.yml` → `run:`** — the recipe to get the app running: dev command, build command, URL, dependencies to start, seed, gotchas, teardown. If the block is empty or stale, **fill it as the first act of this skill** and commit it. The recipe is harness state, not session state: an agent that rediscovers the port, the database container and the seed procedure every session is burning frontier tokens on something that should have been written down once.
2. **`docs/design.md`** — the design decisions this UI is supposed to embody, plus any reference screenshots. Without a design reference there is nothing to compare against and this skill degrades to a smoke test; if `docs/design.md` is empty on a UI slice, that is a phase-3b failure and the work bounces back there.
3. **The slice's acceptance criteria** (`docs/specs/<NN>-<slice>.md`) — the done contract agreed before implementation.

Tool-level recipes, gotchas and snippets: `references/chrome-devtools-mcp.md`.

## Verify against a real build, not the dev server

Use `run.build` when it exists (`npm run build && npm run preview` and equivalents). Dev servers inject HMR clients, skip minification, and serve unhashed assets — verifying there means verifying something the user will never receive. Verify dev-mode only when the project has no build step.

## The loop

```
launch (run recipe) → navigate → run the check matrix → measure → numbered gaps → back to the generator → re-verify → teardown
```

Gaps are reported as **`observed value vs expected value`**, never as prose impressions. "The spacing feels tight" is not actionable; "gap between cards is 8px, design says 24px" is a fix instruction. Each gap gets a number, a location (page, breakpoint, theme), and the smallest fix. The generator iterates against that list and only the verifier closes items.

## The check matrix

Every cell is pass/fail, not a matter of taste.

- **Breakpoints — 390 / 768 / 1280 / 1440.** No horizontal overflow at any of them (`document.documentElement.scrollWidth <= clientWidth`), no clipped or overlapping text, no element escaping its container.
- **Both themes.** Light and dark, every breakpoint that has theme-dependent styling. A single-theme check is how a contrast failure ships.
- **JS enabled and disabled**, where the app claims to degrade gracefully. Submit the real form with JS off and follow the redirect; do not assume the no-JS path works because it was written.
- **Console clean.** No errors, no warnings. A React key warning or a 404 on a font is a finding, not noise.
- **Network clean.** No failed requests, no unexpected 4xx/5xx, no request the page shouldn't be making.
- **Against the design reference.** Compare measured computed values — colors, spacing, font sizes, radii — with `docs/design.md` and reference screenshots. Crop the reference to the region under test rather than eyeballing two full-page images.
- **Accessibility basics.** Contrast ≥ AA (4.5:1 body, 3:1 large text) **measured in both themes**, interactive targets ≥ 44×44px at 390px, focus visible on every interactive element, one `h1` and a sane heading order, landmarks present, images with alt text.
- **Lighthouse per theme**, snapshot mode. An audit in light theme says nothing about dark theme.
- **The acceptance criteria of the slice**, each exercised through the UI — click the button, submit the form, check the resulting state, and where an external effect is claimed (an email, a file, a row), check the effect too.

## Measure, don't eyeball

A screenshot judged by eye is not evidence. Read computed values from the page (`evaluate_script`) and compare them to numbers. This is the single highest-yield rule in this skill: real defects found this way — contrast just under AA, tap targets at 36px, anchors landing under a sticky header — are invisible to a model looking at a picture, and are exactly the class of defect a human reports the week after merge.

Screenshots are still taken, but as *evidence attached to a measured claim*, not as the claim.

## Evidence rule

The verdict cites measured values and the screenshots taken, per check. A grid item marked passing with no observation behind it is a failed grid item. "Looks fine" is not a verdict; it is the absence of one.

## Teardown

Stop what the recipe started — servers, containers, ports — per `run.teardown`. A slice that leaves a container holding port 5432 breaks the next slice's verification and costs a debugging session to diagnose.

## Anti-patterns to reject

- **"The build is green, so the UI is done."** A build proves compilation. It says nothing about rendering, contrast, or layout at 390px.
- **"The tests pass, so the UI is done."** AI-written tests encode the implementer's assumptions. Treat them as necessary, not sufficient.
- **The implementer verifying its own UI.** Generators grade themselves positively and rationalize the gap between "looks done" and "is done". Different agent, always.
- **Judging a screenshot by eye.** Produces confident approval of measurably wrong values. Measure.
- **Verifying one theme.** Half a check, reported as a whole one.
- **Verifying the dev server.** Not what ships.
- **Accepting the implementer's report instead of re-checking.** The report describes intent; the browser shows behavior.
- **Prose findings.** "Alignment is off" bounces back with no fix instruction. Numbers, locations, expected values.
- **Triggering a native dialog** (`alert`, `confirm`, `beforeunload`). It blocks the MCP session and costs a manual rescue — see the reference file.
- **Leaving the environment running.** Teardown is part of the pass.

---

## Review grid (review mode)

**Setup**
- [ ] `.harness/config.yml` has a filled `run:` block, and it actually worked (app reachable at `run.url`).
- [ ] Verification ran against a real build (`run.build`), or the project has no build step.
- [ ] A design reference exists (`docs/design.md` non-empty, screenshots if any) and was used as the comparison basis.
- [ ] The verifying agent is not the implementing agent.

**Rendering**
- [ ] 390 / 768 / 1280 / 1440 checked, each in both themes.
- [ ] No horizontal overflow at any breakpoint (measured, not eyeballed).
- [ ] No clipped, overlapping, or escaping content.
- [ ] Computed values (color, spacing, type scale) match the design reference; every deviation is listed with observed vs expected.

**Behavior**
- [ ] Every acceptance criterion of the slice was exercised through the UI, not inferred.
- [ ] Claimed external effects (email sent, file stored, record created) were checked at the destination.
- [ ] The no-JS path was tested if the app claims to degrade gracefully.
- [ ] Console has no errors or warnings.
- [ ] No failed or unexpected network requests.

**Accessibility**
- [ ] Contrast measured ≥ AA in **both** themes.
- [ ] Interactive targets ≥ 44×44px at 390px.
- [ ] Focus visible on every interactive element; keyboard reaches all of them.
- [ ] One `h1`, sane heading order, landmarks present, images have alt text.
- [ ] Lighthouse run per theme, snapshot mode; scores recorded.

**Hygiene**
- [ ] Findings are numbered, located (page / breakpoint / theme), and stated as observed vs expected with a smallest fix.
- [ ] Evidence (measured values + screenshots) is attached to each passing check, not asserted.
- [ ] Teardown ran; no stray processes, containers, or held ports.

**Verdict**
- State **UI VERIFIED** only if every box passes. Otherwise **UI NOT VERIFIED** with the failing items, each as `gap — observed vs expected — smallest fix`. A verdict without measurements is not a verdict; if the environment could not be launched, say so and stop — an unverifiable slice is not a passing slice.
