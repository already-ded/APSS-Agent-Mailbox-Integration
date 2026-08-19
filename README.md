# APSS Agent Mailbox Integration v2 — corrected complete source

This is the complete AL source project for the APSS Item Agent to Sales Order Agent workflow.

## Corrected in version 1.0.2.4

- Brand Code is editable and opens an actual lookup populated from APSS Item Brand table 50001.
- Selecting a Brand now returns the code through the lookup trigger and immediately updates both the draft list and draft card fields.
- The temporary Brand buffer is not stored as company data.
- Brand is assigned before the Item is inserted, preventing an invalid default Brand such as `AC` from blocking Item creation.
- Item `Description` is populated from `Manufacturer Part No.`.
- `Technical Description` remains on the draft for reviewer reference; item creation no longer assumes that a custom `Long Description` field exists.
- The APSS Item Agent profile, Role Center, Home part, navigation action, and required page permissions are included.
- The Sales Agent lookup is Cloud-safe: it finds the Microsoft Sales Order Agent in the `User` table by its user/full name, excludes the configured Item Agent, and validates only the selected result through the public Agent API.
- All direct references and permissions for the OnPrem-scoped `Agent` table have been removed.
- The setup can assign the `APSS ITEM AGENT` profile directly to the custom Item Agent.
- The Item Agent and Sales Agent cannot be the same agent.
- Items are committed before the Sales Agent handoff. A handoff failure no longer rolls back successfully created Items.
- A failed handoff remains available for the `Activate Sales Order Agent` retry action.
- Only one source version is included. Obsolete `.app` files are intentionally excluded.

See `INSTALLATION.md` for publishing and configuration steps and `ITEM-AGENT-INSTRUCTIONS.md` for the instructions to paste into the custom Item Agent.
