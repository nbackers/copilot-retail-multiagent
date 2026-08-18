---
name: store-morning-briefing
description: Produces the pre-open operational briefing for a single Northwind Retail Group store, pulling together stock exceptions, inbound purchase orders, open IT tickets and roster gaps into one prioritised summary. Activate when a team member asks for a morning briefing, daily huddle notes, a start-of-day summary, "what do I need to know today", or a store health check. Requires a store name.
---

# Store Morning Briefing

Give a store manager everything they need for the pre-open huddle in one pass, so they
don't have to ask four separate questions.

## When to use this

The user wants a consolidated start-of-day picture for one store. If they ask about only
one domain ("what's low on stock?"), answer that directly instead - don't run the full
briefing.

## Step 1 - Establish the store

You need exactly one store. If the user didn't name one, ask which store before doing
anything else. If they give a suburb, match it against `nwr_store` (`nwr_name`,
`nwr_suburb`). If two stores could match, ask rather than guess.

## Step 2 - Gather, in this order

Use the Dataverse MCP tool. Run all four lookups before writing anything - the value of
this briefing is in the cross-domain picture, not the individual facts.

**1. Stock exceptions** - `nwr_inventory` filtered to the store.
Flag a line if any of these are true:
- Available (`nwr_quantityonhand` minus `nwr_quantityreserved`) is at or below
  `nwr_reorderlevel`
- `nwr_stockstatus` is `Out of Stock` or `Low Stock`
- `nwr_quantityonhand` is less than `nwr_quantityreserved` - this is a data error and
  always warrants a cycle count
- Stock is zero with no `nwr_nextdeliverydate` recorded

**2. Inbound purchase orders** - `nwr_purchaseorder` where `nwr_postatus` is `Shipped`,
`In Production`, `Partially Received` or `Delayed`. Anything `Delayed` leads.
Include `nwr_expectedarrival` and the supplier name.

**3. Open IT tickets** - `nwr_itticket` for the store where `nwr_ticketstatus` is not
`Resolved` or `Closed`. Sort by `nwr_priority`. Call out anything P1, anything
`Unassigned`, and anything where `nwr_sladuedate` is today or already past.

**4. People** - `nwr_leaverequest` for employees whose `nwr_store` is this store, where the
leave period covers today and the status is approved. This tells the manager who is
actually not on the floor.

## Step 3 - Write the briefing

Use this structure exactly. Keep the whole thing under about 300 words - a huddle briefing
that needs scrolling doesn't get read.

```
## <Store name> - <day, date>

**Needs a decision today**
<The 1-3 things that will go wrong if nobody acts. If there are none, say
"Nothing urgent." Do not manufacture urgency.>

**Stock**
<Exception lines only. Format: Product - X available (Y on hand, Z reserved),
reorder at N. Never list healthy stock.>

**Inbound**
<PO number, product, quantity, supplier, expected date. Delays first, with the
revised date.>

**IT**
<Ticket number, subject, priority, status. P1 and breached SLAs first.>

**Off today**
<Names and return dates. If nobody, say "Full roster.">
```

## Rules

- **Available to sell = on hand minus reserved.** Always do the subtraction and lead with
  the available figure. Reserved units belong to customers who have already paid; quoting
  on hand as if it were sellable is how broken promises start.
- Only exceptions belong in a briefing. A list of everything that is fine is noise.
- Never invent a number, date or status. If a lookup returns nothing, say that section is
  clear rather than filling it in.
- Read choice fields as their labels. Never show a raw option value, GUID, column name or
  table name.
- If a P1 ticket is unassigned, that goes under "Needs a decision today" regardless of
  what else is happening.
- Dates as "Thursday 30 July", not `2026-07-30T00:00:00Z`.
- Direct, plain plain English. This is an internal audience; brevity is respected.

## Finish with

One line naming the single most important action and who owns it. Not a summary of what
you just said - a recommendation.
