---
name: stock-transfer-request
description: Runs the inter-store stock transfer workflow for Northwind Retail Group - finds which stores genuinely have a product available, checks the transfer won't strand the sending store below its reorder level, and produces a transfer request summary. Activate when a team member asks to move, transfer, source or reserve stock from another store, or asks "who has one I can get". Do not activate for supplier purchase orders.
---

# Stock Transfer Request

Source a product from another store without creating a new stockout in the process.

## When to use this

A team member needs a unit their store doesn't have available. Usually because a customer
is standing in front of them.

Do **not** use this for ordering new stock from a supplier - that's a purchase order and
belongs to Supplier Management.

## Step 1 - Pin down the product and the requesting store

You need three things before you look anything up:

1. **The exact product.** Confirm the model. "A Meridian TV" is not enough - Northwind Retail Group
   carries many. Match against `nwr_product` (`nwr_name`, `nwr_sku`, `nwr_brand`).
2. **The requesting store.**
3. **How many units.** Default to 1 if they don't say, but state that you've assumed it.

Ask for whatever's missing. One short question, not a form.

## Step 2 - Confirm the requesting store actually needs it

Check `nwr_inventory` for the product at the requesting store. Compute available as
`nwr_quantityonhand` minus `nwr_quantityreserved`.

If they already have enough available, say so and stop. Staff sometimes don't realise
their own reserved units aren't sellable, or that a colleague has already found one.

## Step 3 - Find the sources

Query `nwr_inventory` for the product across all stores. For each store with stock,
compute:

- **Available** = `nwr_quantityonhand` minus `nwr_quantityreserved`
- **Headroom** = available minus `nwr_reorderlevel`

A store is a **safe source** if it can send the requested quantity and still sit at or
above its reorder level.

A store is a **possible source** if it has the units available but sending them would push
it below reorder. Include these, but label the trade-off explicitly - never quietly
recommend stranding another store.

A store is **not a source** if available is zero or less, no matter what
`nwr_quantityonhand` says.

## Step 4 - Recommend

Rank safe sources by headroom, highest first - take from whoever can most afford it. Prefer
same-state stores where the choice is close, since the transfer will land sooner.

Present it like this:

```
## <Product> - transfer to <requesting store>

**Recommended source: <store>**
<N> available (<X> on hand, <Y> reserved). Sending <requested> leaves <N-requested>,
still above their reorder level of <R>.

**Also available**
<store> - <N> available, <headroom> above reorder
<store> - <N> available, but sending would drop them to <N-requested> against a
reorder level of <R>. Only use if the recommended source falls through.

**Next step**
<What the requester does now, and the realistic timeframe.>
```

## Rules

- **Available to sell = on hand minus reserved.** Never quote on hand as if it were
  sellable.
- A reservation is only real once it is recorded. Never tell a team member stock is being
  held for them unless a reservation exists in the data.
- Give the realistic transfer timeframe, not the best case. Interstate takes longer.
- If a store shows `nwr_quantityonhand` below `nwr_quantityreserved`, that store is a data
  error, not a source. Flag it for a cycle count and exclude it.
- If nowhere has it available, say so plainly, report when stock is next landing
  (`nwr_nextdeliverydate`), and if `nwr_stockstatus` is `Discontinued`, say that and offer
  comparable alternatives in the same category and price band.
- Never invent a quantity, store or date.
- Read choice fields as their labels. Never show a raw option value, GUID, column name or
  table name.

## What you cannot do

You can recommend and document a transfer. You cannot execute one - the requester raises
it in the transfer system. Be clear about that boundary so nobody walks away thinking
stock is on its way when it isn't.
