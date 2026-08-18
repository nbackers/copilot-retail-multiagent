---
name: weekly-replenishment-plan
description: Builds the weekly reorder plan for a Northwind Retail Group store by comparing stock positions against reorder levels, netting off purchase orders already inbound, and factoring in supplier lead time and reliability before recommending what to order. Activate when someone asks what to reorder, requests a replenishment or stock ordering plan, asks what to buy this week, or asks whether stock will arrive in time.
---

# Weekly Replenishment Plan

Work out what actually needs ordering - after accounting for what's already on its way.

## When to use this

Someone is planning orders for a store. The value here is the netting off: a product below
reorder level with a purchase order already inbound does **not** need reordering, and
double-ordering is the most common and most expensive mistake in this workflow.

## Step 1 - Store

One store per plan. Ask if not given.

## Step 2 - Find what's below the line

Query `nwr_inventory` for the store. For each line compute:

- **Available** = `nwr_quantityonhand` minus `nwr_quantityreserved`
- **Gap** = `nwr_reorderlevel` minus available

Include the line if the gap is greater than zero, or if `nwr_stockstatus` is `Low Stock`
or `Out of Stock`.

Exclude `Discontinued` - flag those separately as lines to run down rather than replenish.

## Step 3 - Net off what's already coming

For each flagged product, check `nwr_purchaseorder` for open orders - status
`Sent to Supplier`, `Acknowledged`, `In Production`, `Shipped`, `Partially Received` or
`Delayed`.

- **Enough inbound, arriving in time** - no action. Say so and give the arrival date. This
  is a result, not an omission.
- **Enough inbound, arriving too late** - don't reorder the same thing. Expedite the
  existing PO, or transfer from another store to bridge the gap.
- **Some inbound, not enough** - order the shortfall only.
- **Nothing inbound** - order the full gap.
- **Status is `Delayed`** - treat as arriving late until the supplier confirms otherwise.
  A delayed PO is not cover.

## Step 4 - Check the supplier can deliver in time

For each product to order, pull the supplier's `nwr_leadtimedays` and
`nwr_performancerating`.

- If lead time exceeds the days of cover remaining, the order will land after the stockout.
  Say so, and recommend a transfer to bridge.
- If the supplier's rating is below 3.0, or their status is `Suspended` or `Under Review`,
  flag it. Don't quietly plan around a supplier who may not deliver.
- Order sooner than the arithmetic suggests where the supplier has a poor record. Lead time
  is a promise, not a fact.

## Step 5 - Present

```
## Replenishment plan - <store>, week of <date>

**Order now**
<Product> - <qty>. <N> available against a reorder level of <R>.
Supplier <name>, <L> day lead time, arriving around <date>.
<Any risk flag.>

**Already covered**
<Product> - <qty> inbound on <PO>, arriving <date>. No action.

**At risk**
<Product> - <what's wrong: lead time won't make it, PO delayed, supplier
suspended - and what to do instead.>

**Cycle count needed**
<Any line where on hand is below reserved, or the count looks wrong.>
```

## Rules

- **Never recommend ordering something already inbound in sufficient quantity.** This is the
  whole point of the skill.
- **Available to sell = on hand minus reserved.** Reorder decisions made on the on-hand
  figure order too little, every time.
- Order the shortfall, not the full reorder level, where stock is partly covered.
- Never invent a lead time, arrival date, quantity or PO number. If a supplier link is
  missing, say the supplier needs confirming rather than assuming one.
- Read choice fields as their labels. Never show a raw option value, GUID, column name or
  table name.
- Dates as "around 12 August".

## Finish with

The one line most likely to stock out before its cover arrives, and the specific action
that prevents it. That's the sentence the manager actually needs.
