# Dataverse schema

Eleven tables, publisher prefix `nwr_`. The skills reference these column names directly, so if you
change the prefix, run `scripts/Set-SkillBranding.ps1` to keep them in step.

---

## Tables

| Table | Purpose | Key columns |
|---|---|---|
| `nwr_store` | Store network | `nwr_name`, `nwr_suburb` |
| `nwr_product` | Product catalogue | `nwr_name`, `nwr_sku`, `nwr_category` |
| `nwr_inventory` | Stock per store | `nwr_quantityonhand`, `nwr_quantityreserved`, `nwr_reorderlevel`, `nwr_stockstatus`, `nwr_nextdeliverydate` |
| `nwr_supplier` | Suppliers | `nwr_name`, `nwr_rating`, `nwr_status`, `nwr_contractexpiry` |
| `nwr_purchaseorder` | Inbound orders | `nwr_postatus`, `nwr_expectedarrival`, `nwr_quantity` |
| `nwr_employee` | Staff | `nwr_name`, `nwr_role`, `nwr_store` |
| `nwr_leaverequest` | Leave | `nwr_startdate`, `nwr_enddate`, `nwr_status` |
| `nwr_itticket` | IT tickets | `nwr_ticketstatus`, `nwr_priority`, `nwr_sladuedate`, `nwr_subject` |
| `nwr_order` | Customer orders | `nwr_ordernumber`, `nwr_deliverynotes`, `nwr_status` |
| `nwr_customer` | Customers | `nwr_name` |
| `nwr_warrantyclaim` | Warranty claims | `nwr_claimnumber`, `nwr_status` |

## The column that matters most

```
available to sell = nwr_quantityonhand − nwr_quantityreserved
```

There is deliberately **no stored `available` column**. Storing it would let it drift from the two
values it derives from, and a stale availability figure is worse than no figure - it produces
confident promises that can't be met.

Every skill does the subtraction explicitly.

### The data-error case

If `nwr_quantityonhand` is **less than** `nwr_quantityreserved`, that is a data error, not negative
stock. The skills treat it as a cycle-count trigger and never present it as availability.

## Choice fields

Several columns are choice fields:

| Column | Values |
|---|---|
| `nwr_stockstatus` | In Stock, Low Stock, Out of Stock |
| `nwr_postatus` | Ordered, In Production, Shipped, Partially Received, Delayed, Received |
| `nwr_ticketstatus` | New, Assigned, In Progress, Resolved, Closed |
| `nwr_priority` | P1, P2, P3, P4 |
| `nwr_status` (supplier) | Active, Under Review, Suspended |

**Always render the label, never the raw option value.** A user shown `74100040` has been given
nothing. Every skill states this rule.

Also note: a `Delayed` purchase order **is not cover**. Skills exclude delayed POs when deciding
whether inbound stock offsets a reorder.

## Demo data

To exercise the skills properly, seed data that produces a real decision rather than a healthy
board:
- A store with **zero** stock of a product another store holds - drives `stock-transfer-request`
- A product where on hand is at or below reorder level, with a **delayed** PO inbound - drives
  `weekly-replenishment-plan`
- An **unassigned P1** ticket with an SLA due today - drives `major-incident-response`
- A supplier with a poor rating, `Suspended` status and a contract expiring soon - drives
  `supplier-risk-review`
- Approved leave covering today - makes the briefing's roster section meaningful
- One row where on hand < reserved - proves the data-error path

Exception-only reporting means a fully healthy dataset makes every skill correctly return "nothing
urgent", which demonstrates nothing.

## Alternate keys

If you look records up by a natural identifier - employee email, ticket number, order number - add an **alternate key** on that column. It keeps queries delegable at scale and avoids passing
GUIDs around in conversation.
