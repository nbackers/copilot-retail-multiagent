---
name: major-incident-response
description: Triages a critical or high-priority IT incident at Northwind Retail Group - assesses trading impact, checks SLA position, identifies unassigned or breached tickets, sets out the workaround and the communications that need to go out. Activate when someone reports POS or network down, a security or phishing incident, a store unable to trade, a P1 or P2 incident, or asks what is broken right now.
---

# Major Incident Response

When a store can't trade, the answer needs to arrive in the first thirty seconds. This
skill front-loads impact and workaround, and leaves the process detail for later.

## When to use this

- A store or lane cannot process sales
- Network, Wi-Fi or a core system is down
- A suspected security incident - phishing, credential compromise, malware
- Someone asks what P1 or P2 incidents are currently open

For a single routine issue - a jammed printer, one password reset - handle it normally.
This is for anything with trading or security impact.

## Step 1 - Impact first, always

Before any lookup, before any process, answer:

- **Can the store still take money?** If not, that is the entire problem.
- **How many lanes, terminals or staff are affected?**
- **Is customer or payment data potentially exposed?**

If the answer to the third is anything other than a clear no, treat it as P1 security
regardless of how it was first reported, and say so.

## Step 2 - Find the ticket

Search `nwr_itticket` for the store and symptom. Read `nwr_name`, `nwr_subject`,
`nwr_description`, `nwr_priority`, `nwr_ticketstatus`, `nwr_assignedto`,
`nwr_sladuedate`, `nwr_reporteddate`.

Three things matter more than the rest:

- **Is it assigned?** `Unassigned` on a P1 is the finding. Lead with it.
- **Is the SLA breached or breaching?** Compare `nwr_sladuedate` to now. Say "breached
  two hours ago" or "due in 40 minutes", not a raw timestamp.
- **Is this the only one?** Check for other open tickets at the same store and other
  stores reporting the same symptom. Two stores with the same fault is not two incidents,
  it's one - and that changes the response entirely. Say so explicitly.

If no ticket exists, that's the immediate action: one must be raised. Give the priority it
should carry and why.

## Step 3 - Priority

| | Meaning |
|---|---|
| **P1 - Critical** | Store cannot trade, or a security incident is suspected |
| **P2 - High** | Trading degraded - some lanes, some functions |
| **P3 - Medium** | Workaround exists, trading continues |
| **P4 - Low** | Inconvenience only |

If the recorded priority understates the real impact, say so plainly and recommend the
escalation. Getting the priority wrong is the most common reason a major incident is
handled too slowly.

## Step 4 - Respond in this shape

```
## <Ticket number if known> - <one-line description>
<Priority> | <Status> | <Store> | <SLA position in plain words>

**Right now**
<The immediate workaround, so trading continues. Numbered, shortest path first.
If there is no workaround, say that first - don't bury it.>

**Impact**
<Lanes or staff affected, and whether the store can trade.>

**Owner**
<Who is on it. If unassigned, say so and state that assignment is the blocker.>

**Who needs to know**
<Store manager, regional manager, security team - whoever is genuinely
warranted by the severity. Not a blanket list.>

**Next update**
<When, and from whom.>
```

## Rules

- **Workaround before process.** A store losing revenue needs a way to keep selling, not an
  explanation of the escalation matrix.
- **Never speculate on cause during a live incident.** Guessing wrong sends people down the
  wrong path and costs more time than saying "under investigation".
- For anything security-related: preserve evidence, do not delete the suspicious email, and
  escalate to the Security Team immediately. Never advise a user to interact with a
  suspected phishing message to test it.
- Never invent a ticket number, SLA time, assignee or root cause.
- Read choice fields as their labels. Never show a raw option value, GUID, column name or
  table name.
- Times in plain language relative to now.
- No blame. The point is restoring trade.

## Multi-store pattern check

Always worth one extra lookup. Query open tickets across all stores with a similar subject
or category. If three stores report POS faults the same morning, that's a platform
incident and the response is entirely different from three local faults. This is the single
highest-value thing this skill does - nobody looking at one ticket ever sees it.
