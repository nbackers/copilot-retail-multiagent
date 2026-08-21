# Agent setup

Build order for the orchestrator and four child agents in the **new** Copilot Studio experience.

---

## 1. Dataverse first

Create the tables before the agents - the MCP tool needs something to ground against.
See [../dataverse/README.md](../dataverse/README.md).

## 2. Create the child agents

Create four agents. These are **purely generative** - they hold instructions and grounding, no
actions.

| Agent | Owns |
|---|---|
| Inventory and Stock | Stock levels, availability, transfers, reorder points, products |
| Supplier Management | Suppliers, purchase orders, delivery performance, contracts |
| Employee Self-Service | Leave, roster, onboarding, employee records |
| IT Support | Tickets, incidents, priorities, SLAs |

For each, set the `description` carefully - see [design-rationale.md](design-rationale.md#routing-concretely).
This is what the orchestrator routes on.

Descriptions are in [../agents/](../agents/).

## 3. Add the Dataverse MCP tool

Add the Dataverse MCP server to each child agent, scoped to the tables that agent owns.

```yaml
kind: McpTool
authMode: Maker
connectionReference: <your connection reference>
connectorId: /providers/Microsoft.PowerApps/apis/shared_commondataserviceforapps
operationId: InvokeMCP
```

> **Read-only is enforced by instruction, not by the tool.** The MCP tool is neutral - it will
> create and update if asked. If the agent must not write, say so explicitly in its instructions
> *and* scope the tables it can reach. Do not assume the tool restricts it for you.

Scope each agent to its own tables rather than all eleven. Narrower grounding gives better answers
and enforces the domain boundary.

## 4. Create the orchestrator

Create the parent agent and connect the four children. The orchestrator's job is routing and
summary - keep its own grounding minimal.

## 5. Upload the skills

**Copilot Studio → Build → Skills → Add skill → Upload a skill.** One zip at a time.

Rebrand first if you're using your own prefix:

```powershell
.\scripts\Set-SkillBranding.ps1 -Prefix con -RetailerName 'Contoso Retail' -Repackage
```

Requirements:
- `SKILL.md` at the **root** of the zip, not inside a folder
- `name` in the front matter: lowercase letters, numbers and hyphens only
- `name` must match the folder name
- UTF-8 **without BOM** - a BOM breaks front matter parsing

## 6. Test routing before testing answers

Routing failures look like bad answers, so separate the two. For each question below, confirm the
*right agent or skill* picked it up before judging the response:

| Ask | Should reach |
|---|---|
| "What's low on stock at Northgate?" | Inventory child agent |
| "How is Halberd Appliances performing?" | Supplier child agent (via skill) |
| "Morning briefing for Northgate" | `store-morning-briefing` skill |
| "POS is down at Northgate" | `major-incident-response` skill |
| "New sales consultant starting Monday" | `new-starter-setup` skill |
| "When is my leave approved?" | Employee Self-Service child agent |

If a question reaches the wrong place, fix the **description** - not the instructions.

---

## Manual steps with no headless equivalent

Worth knowing before planning automation:
- **Connection binding** - OAuth consent, once per environment, in the portal.
- **Skill upload** - portal only, one zip at a time.
- **Flow creation** - no `pac flow create`; portal or MCP tooling.

`pac copilot create / clone / push / publish` covers agent provisioning from source, but cannot bind
connections.

---

## Verification checklist
- [ ] All 11 tables exist and contain data
- [ ] Each child agent reaches only its own tables
- [ ] Read-only instruction present where required
- [ ] All six skills uploaded and enabled
- [ ] Routing test table above passes
- [ ] Available-to-sell subtraction correct in a stock answer
- [ ] Choice fields render as labels, never raw option values
- [ ] Agent says a section is clear rather than inventing content
