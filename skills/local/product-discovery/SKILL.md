---
name: product-discovery
description: Run product discovery BEFORE any feature is specified or built. Use this whenever a new project, product, feature, or capability is being defined — to extract the real user problem, the specific target user, the desired outcomes and how they're measured, the riskiest assumptions, and a bounded scope, through structured questioning, and to produce a product brief that downstream architecture and planning can consume. Also use it as a review grid to judge whether a spec or feature list rests on real discovery or jumped straight to a solution. Trigger on "build/add a feature", "new project", "what should we build", "define the requirements", "product spec", "scope this", or any request that proposes a solution before the problem is established — even if no one says the words "PM", "PO", or "discovery".
---

# Product Discovery

This skill has two modes. In **guide mode** it conducts discovery and produces a product brief. In **review mode** it judges whether a brief or feature list is grounded in discovery or is solution-first wishful thinking. Read it all once; the review grid at the end is the contract.

This is the most upstream role in the lifecycle. It runs before architecture and before any plan. Its output — the product brief — is the input the architecture and planning phases consume. It pairs with (does not replace) a brainstorming/clarification phase: brainstorming refines *how* to build; discovery establishes *what* is worth building and *for whom*, and *why*.

## The one rule everything derives from

**Establish the problem and the outcome before entertaining any solution. Optimize for outcomes, not outputs.**

The dominant failure mode of both humans and LLMs here is rushing to a solution. Someone says "we need a dashboard" and the instinct is to start listing dashboard features. Stop. A dashboard is a *solution*. Discovery's job is to find out whose problem it solves, what that problem actually is, and what outcome would tell us it's solved — because nine times out of ten the stated solution is not the best one, and sometimes the real problem needs no software at all.

## Problem space vs solution space — never collapse them

- **Problem space**: who the user is, the job they're trying to do, the pain in their current path, the outcome they want. This is what discovery investigates.
- **Solution space**: features, screens, APIs, the dashboard. This comes *after*, and only as a hypothesis mapped back to a problem.

When a request arrives already in solution space ("add export to CSV"), pull it back one level: *what is the user trying to accomplish that export would serve?* Often the real need reshapes the solution. Treat every proposed feature as an answer to a question you must first surface.

## The highest-leverage questions (guide mode)

Ask **one question at a time** and wait for the answer before the next — never flood the human with a questionnaire. For every question, **propose your own recommended answer**, so the human's job is to confirm, reject, or adjust rather than to write an essay. And before asking anything, check whether you can answer it yourself by exploring the codebase, the existing docs, or the conversation — only ask the human what they alone can answer. Lead with these, roughly in order:

- **Who, specifically, is the user?** Not "users" or "the team" — a concrete person in a concrete situation. Vague users produce vague products.
- **What job are they hiring this for?** What are they trying to get done? (Jobs-to-be-done framing: the progress they want to make.)
- **What do they do today, and what's painful about it?** The current workaround reveals the real pain and the bar you must clear.
- **What outcome would tell us this worked?** A change in user behavior or a measurable result — not "the feature shipped".
- **What happens if we do nothing?** If the answer is "not much", that's a signal about priority, not a reason to build.

Each answer usually opens the next question. Keep going until you could explain the problem to a stranger in three sentences and they'd agree it's worth solving.

## Surface assumptions, then attack the riskiest first

Every product idea rests on assumptions — that the user has this problem, that they'd change behavior, that the solution is feasible, that it's worth their switching cost. List them explicitly. Then identify the **riskiest assumption**: the single belief that, if false, makes the whole thing pointless. Discovery's highest-value act is naming that assumption and proposing the cheapest way to test it before heavy investment. A perfectly architected product built on a false core assumption is wasted craft.

## Outcomes over outputs

Define success as an outcome, and make it observable. "Users complete onboarding without support tickets" is an outcome. "We built an onboarding wizard" is an output. A brief whose success criteria are a list of shipped features has no way to know if it succeeded. Push every objective toward a behavior change or a metric, even a rough one. Beware vanity metrics (totals that only go up); prefer metrics tied to the user actually getting their job done.

## Scope discipline and the smallest valuable slice

- Make **in scope / out of scope** explicit. The out-of-scope list prevents more rework than any other part of the brief.
- Define the **smallest slice that delivers a real outcome** (or tests the riskiest assumption) — not a feature-complete v1. This is not "MVP" as a buzzword; it's the minimum that produces a genuine signal or genuine value.
- Each prioritized opportunity in the brief should map to roughly one **vertical use-case slice** downstream. This is the handoff: discovery's opportunity list becomes the architecture phase's candidate slices, each ownable by one subagent. Keeping opportunities slice-sized here makes the later decomposition fall out cleanly.

## Interaction style

Discovery is human-in-the-loop by nature — it needs the human's product intent. Work the decision tree one question at a time, each with your recommended answer, resolving dependencies between decisions before moving on; explore the codebase or docs instead of asking whenever the answer is findable there. Present the emerging brief in chunks short enough to react to, not as a finished wall of text. If you must proceed without answers (the human is unavailable), do not silently invent facts: state each assumption you're making explicitly and flag them as unvalidated in the brief, so the architecture phase inherits the uncertainty rather than a false certainty.

## Output: the Product Brief

Write to `docs/product/brief.md`. Keep it tight — a brief, not a PRD novel.

```markdown
# Product Brief: [name]

## Problem
[The user problem in 2-3 sentences. Problem space only — no solution.]

## Target user
[Specific user in a specific situation. Who, doing what, where.]

## Jobs / opportunities
[The jobs-to-be-done / needs / pains, prioritized. Each is a candidate slice.]

## Desired outcomes & success measures
[Observable outcomes — behavior change or metric. One line each.]

## Riskiest assumptions
[Listed worst-first. For the top one: the cheapest way to test it.]

## Scope
**In:** [bounded list]
**Out:** [explicit exclusions — the rework firewall]

## Proposed features (hypotheses)
[Each feature traced to the opportunity it serves. Solution space, clearly labeled as hypotheses.]

## Open questions
[What's still unknown and who can answer it.]
```

## Anti-patterns to reject

- **Solution-first.** Jumping to features before the problem, user, and outcome are clear.
- **Abstract user.** Building for "users" / "everyone" instead of a specific person in a situation.
- **Feature factory.** Measuring success by features shipped rather than outcomes achieved.
- **Stakeholder request mistaken for user need.** "The client asked for X" is a data point, not a validated need; trace it to a user problem.
- **Untested riskiest assumption.** The core belief is never named or never challenged.
- **Unbounded scope.** No out-of-scope list; everything is "nice to have"; v1 is feature-complete.
- **Vanity success criteria.** Metrics that only go up and don't reflect the job getting done.

---

## Review grid (review mode)

Apply this to a product brief, spec, or feature list. Each item is pass/fail. Verify, don't trust — assume the author may have rationalized a pet solution.

**Problem grounding**
- [ ] The problem is stated in problem space, with no solution baked in.
- [ ] The target user is a specific person in a specific situation, not "users".
- [ ] The job-to-be-done / pain is explicit and plausible.

**Outcomes**
- [ ] Success is defined as an observable outcome (behavior change or metric), not as shipped outputs.
- [ ] Success measures avoid vanity metrics and tie to the user's job.

**Risk**
- [ ] Assumptions are listed; the riskiest one is identified.
- [ ] There is a cheap way proposed to test the riskiest assumption before heavy build.

**Scope & traceability**
- [ ] In-scope and out-of-scope are both explicit.
- [ ] A smallest-valuable-slice is defined, not a feature-complete v1.
- [ ] Every proposed feature traces to a stated opportunity/problem; none are orphan solutions.
- [ ] Opportunities are roughly slice-sized (one maps to ~one downstream use-case slice).

**Verdict**
- State **READY FOR ARCHITECTURE** only if every box passes. Otherwise **NEEDS DISCOVERY** with the failing items, each as `section — what's missing — the question to ask next`. A brief that fails here will produce wasted architecture and code downstream, so this gate matters more than it looks.
