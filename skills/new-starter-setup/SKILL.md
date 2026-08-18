---
name: new-starter-setup
description: Builds the complete day-one readiness checklist for a new Northwind Retail Group team member, spanning People and Culture onboarding and the IT accounts, devices and system access they need. Activate when someone asks about onboarding a new starter, setting up a new employee, day-one checklists, what a new team member needs, or offboarding a leaver. Covers both the people side and the IT side in one pass.
---

# New Starter Setup

Get a new team member productive on day one. This deliberately spans People and Culture
and IT, because that's exactly where onboarding falls over - each side assumes the other
has it covered.

## When to use this

Someone is joining, changing store or role, or leaving. Any of those needs the same
two-sided checklist.

## Step 1 - Establish who and what

You need:
- **Who** - name, and their `nwr_employee` record if they already exist
- **Which store** - `nwr_store`
- **What role** - `nwr_role`, because access follows role
- **Start date** - this drives every deadline below

If the employee record already exists, read it: `nwr_employeenumber`, `nwr_role`,
`nwr_store`, `nwr_managername`, `nwr_employmenttype`, `nwr_startdate`. If it doesn't
exist yet, that's your first gap - People and Culture create it, and IT can't provision
against nothing.

## Step 2 - Work out what the role needs

Access follows role. Use the Employee Handbook and the IT Service Catalogue for the
authoritative lists, but as a general shape:

| Role | Typically needs |
|---|---|
| Sales Consultant | POS login, store network, email, Teams, mobile device |
| Store Manager | All of the above, plus reporting access and approval rights |
| Warehouse | Scanner, warehouse system, label printer access |
| Procurement | Supplier portal, purchase order approval |
| Head office | Email, Teams, laptop, relevant line-of-business systems |

Never assert a specific entitlement that isn't in the handbook or catalogue. If you're not
sure, list it as "confirm with the hiring manager" rather than inventing it.

## Step 3 - Produce the checklist

Two columns, because two different people action them.

```
## New starter - <name>, <role>, <store>
Start date: <date> (<N> business days away)

### People and Culture
- [ ] <item> - owner, due <date>

### IT
- [ ] <item> - owner, due <date>

### Blocked or needs a decision
<Anything that can't proceed, and what's blocking it. If nothing, omit
this section entirely.>
```

Work backwards from the start date, not forwards from today. Anything with a lead time
longer than the days remaining goes in **Blocked** immediately - flagging it late is the
same as not flagging it.

## Step 4 - Check for existing tickets

Look in `nwr_itticket` for tickets already raised for this person
(`nwr_employee`, or their name in `nwr_subject`). Don't tell someone to raise a ticket
that already exists. Report its number, status and SLA date instead.

## Rules

- **Both sides, every time.** A new starter with a signed contract and no POS login can't
  work. A provisioned laptop with no employment record is a compliance problem. Never
  produce a one-sided checklist.
- Employee personal details, pay and leave are visible only to that person, their manager
  and People and Culture. If you can't tell who's asking, give the process, not the
  personal data.
- Never invent an employee number, system name, entitlement or date.
- Read choice fields as their labels. Never show a raw option value, GUID, column name or
  table name.
- Dates as "Monday 3 August", with the working days remaining.

## Offboarding

Same skill, run in reverse, and the sequencing matters more:

1. **Access first, on the last day.** Accounts, POS, building, mobile, supplier portal.
2. Then equipment return - device, uniform, keys.
3. Then the People and Culture close-out - final pay, leave payout, exit conversation.

Flag any open IT ticket assigned to a leaver, and anything only they can approve. Those
strand silently and nobody notices until someone needs them.

## Finish with

The single item most likely to be missed, and who owns it. Usually it's whatever has the
longest lead time and the least visible owner.
