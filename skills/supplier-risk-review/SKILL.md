---
name: supplier-risk-review
description: Produces a supplier risk scorecard for Northwind Retail Group, combining performance rating, lead time, delivery reliability from purchase order history, contract expiry and account status into a single assessment with a recommendation. Activate when someone asks how a supplier is performing, requests a supplier review or scorecard, asks which suppliers are at risk, asks about contract renewals, or asks whether to keep using a supplier.
---

# Supplier Risk Review

Turn scattered supplier data into a judgement someone can act on at a procurement meeting.

## When to use this

Someone is deciding whether to renew, escalate, expand or exit a supplier relationship.
Also use it for the portfolio view - "which suppliers should I be worried about".

For "where is my order", that's a straight purchase order lookup, not a review.

## Step 1 - Scope

One supplier, or the whole portfolio. If the user names a supplier, review that one. If
they ask a general risk question, run the portfolio scan in Step 4.

## Step 2 - Gather

From `nwr_supplier`: `nwr_name`, `nwr_suppliercode`, `nwr_performancerating`,
`nwr_leadtimedays`, `nwr_contractexpiry`, `nwr_supplierstatus`, `nwr_paymentterms`,
`nwr_categoriessupplied`, and the contact fields.

From `nwr_purchaseorder` filtered to that supplier: every PO with `nwr_postatus`,
`nwr_podate`, `nwr_expectedarrival`, `nwr_quantityordered`, `nwr_totalcost`.

The rating alone is not a review. The story is in the gap between what the supplier
promises and what the purchase orders actually show.

## Step 3 - Assess against these thresholds

**Performance rating** (out of 5)
- 4.0 and above - healthy
- 3.0 to 3.9 - watch
- Below 3.0 - at risk, needs an escalation path

**Delivery reliability** - count POs with `nwr_postatus` of `Delayed` against the total.
Any delayed PO against a supplier already rated below 3.5 is a compounding signal, not two
separate problems. Say so.

**Lead time** - compare `nwr_leadtimedays` to others supplying the same category. A long
lead time isn't a fault on its own; a long lead time plus unreliability is.

**Contract expiry** - anything inside 90 days needs a renewal decision now, because the
negotiation itself takes time. Inside 30 days is urgent.

**Status** - `Suspended` or `Under Review` overrides everything. Lead with it.

## Step 4 - Portfolio scan

When asked generally, surface only suppliers meeting at least one of:
- Rating below 3.5
- Status of `Suspended` or `Under Review`
- Contract expiring within 90 days
- One or more purchase orders currently `Delayed`

Rank by how many of those they trip. A supplier tripping three is a different conversation
from one tripping one.

## Step 5 - Write it up

```
## <Supplier> - <code>
Status: <status> | Rating: <n>/5 | Lead time: <n> days | Contract expires <date>

**Assessment**
<Two or three sentences. What the data actually shows, including the gap between
rating and delivery record. Not a restatement of the numbers above.>

**Risk factors**
<Bulleted, most material first. Only real ones.>

**Open purchase orders**
<PO number, product, quantity, expected date, status. Delays first.>

**Recommendation**
<One clear course of action.>
```

For the portfolio view, one compact block per supplier, worst first, then a closing line
on where to spend attention.

## Rules

- **Be direct.** If a supplier is failing, say so. A hedged supplier review is worthless to
  the person who has to make the call.
- Equally, don't overstate. One delayed PO against an otherwise strong record is a delay,
  not a pattern.
- Commercial terms, pricing and contract detail are internal. Never repeat them to a
  customer-facing context.
- Never invent a rating, date, PO number or contract term.
- Read choice fields as their labels. Never show a raw option value, GUID, column name or
  table name.
- Money in AUD. Dates as "31 August 2026".
- If the assessment implies exiting or suspending a supplier, note that the decision sits
  with Procurement - you are informing it, not making it.
