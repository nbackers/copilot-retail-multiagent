# Design rationale

Why this is four agents and six skills, and how to decide the same question for your own build.

---

## The decision

Multi-agent orchestration is frequently adopted because it sounds like maturity. It is a real
architectural choice with a real cost, and the cost lands in one place: **routing accuracy**.

Every child agent you add is another `description` competing to answer the same question. With two
children, routing is nearly always right. With six overlapping ones, the orchestrator starts making
arbitrary picks and the failure is invisible - the agent answers confidently from the wrong domain.

So the question isn't "would separate agents be tidier?" It's **"do I have workflows that require
more than one domain at once?"**

## The test

Use one agent when:
- One coherent set of instructions covers the whole scope without contradicting itself
- Users ask questions of broadly one kind
- Data lives in a handful of related tables
- No meaningful cross-domain joins are needed

Use orchestration when **all** of these hold:
- Domains have genuinely different vocabulary, data and permissions
- You can name at least three workflows that span two or more domains
- A single instruction set has started contradicting itself between domains
- Different domains need different grounding or access control

If you cannot name three cross-cutting workflows, you want one agent.

## The counter-example

A read-only records-lookup assistant - one domain, one table, one question shape - is a
**single-agent** design, even at 3,000+ users. Scale is not the trigger for orchestration; domain
diversity is.

Splitting that assistant into "record lookup" and "record export" agents would add routing risk and
gain nothing, because no workflow needs both at once.

## Why this build justifies four

The four domains - Inventory, Supplier, Employee Self-Service, IT Support - differ on every axis
that matters:

| | Inventory | Supplier | Employee | IT |
|---|---|---|---|---|
| Vocabulary | on hand, reserved, reorder level | scorecard, contract, delivery record | leave, roster, onboarding | priority, SLA, incident |
| Data | stock, products, stores | suppliers, purchase orders | employees, leave requests | tickets |
| Sensitivity | operational | commercial | personal | operational |
| Audience | floor staff | procurement | everyone | everyone |

Employee data alone justifies separation - leave records need different access control from stock
levels, and mixing them into one instruction set makes that boundary a matter of prompt wording
rather than configuration.

## Why the skills are cross-cutting

Here is the part that is usually missed. Once you split into four agents, **no child agent can
answer a cross-domain question** - by construction. The morning briefing needs stock, purchase
orders, IT tickets and roster in one pass. The Inventory agent can't produce it. Neither can any
of the others.

That's what the skills are for. Each of the six spans two or three domains:

| Skill | Spans | The join it makes |
|---|---|---|
| `store-morning-briefing` | Inventory + Supplier + IT + People | One prioritised picture instead of four questions |
| `stock-transfer-request` | Inventory × 2 stores | Sourcing without stranding the sending store |
| `weekly-replenishment-plan` | Inventory + Supplier | Nets off purchase orders already inbound |
| `supplier-risk-review` | Supplier + Inventory | Rating versus actual delivery record |
| `major-incident-response` | IT + multi-store | Is this one store's problem or a pattern? |
| `new-starter-setup` | People + IT | Two-sided checklist, blockers surfaced early |

**Orchestration creates the gap; skills fill it.** A design with four agents and no cross-cutting
skills has taken the cost without the benefit.

## Where business rules belong

Domain rules go in **skill steps**, not agent instructions.

```
Available to sell = quantity on hand − quantity reserved
```

Reserved units are already sold. Quoting on-hand as sellable is the most common error in this
domain, and it is exactly the kind of rule that must apply identically everywhere.

Reasons it belongs in the skill:
- **Versioned** - a skill is a file, reviewable in a pull request
- **Testable in isolation** - you can exercise one skill without the whole agent
- **Reusable** - the same rule applies in briefing, transfer and replenishment
- **Doesn't bloat instructions** - instructions stay about tone, scope and escalation

Agent instructions cannot fix behavioural problems that are really rule problems. Microsoft
documents that instructions are for tone and flow, and specifically that they *can't* modify how
adaptive cards are triggered. The same principle applies more broadly: if the fix you're reaching
for is "add another sentence to the prompt", check whether it belongs in a skill instead.

## Routing, concretely

The orchestrator routes on each child agent's **`description`**. Not its name, and not its
instructions.

Practical consequences:

1. **Tune descriptions first.** If a question lands in the wrong domain, the description is the fix.
2. **Make them non-overlapping.** Two descriptions that both plausibly cover "stock" will route
   arbitrarily between them.
3. **Say what it is not for.** Negative scope is as useful as positive scope.
4. **Encode the ambiguous calls explicitly.** "Damaged on arrival" reads like warranty and is
   actually delivery. Write that down, in the description.

Skills work the same way - the front matter `description` is the router's input.

## What this costs

Being honest about the downsides:
- **Six skills is six uploads,** one at a time, through the portal.
- **More surface to keep consistent.** A schema change may touch several skills - hence the
  rebranding script.
- **Harder to reason about.** Any question could be answered by a child agent or a skill, and
  working out which happened takes tracing.
- **Routing needs tuning** after real usage. Expect to revise descriptions once you see traffic.

Worth it when the cross-domain workflows are real. Not worth it otherwise.
