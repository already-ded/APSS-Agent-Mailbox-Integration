# Installation and configuration

## 1. Add the project

This ZIP is a complete source project.

1. Back up or commit your current AL project.
2. Extract this ZIP into a new folder.
3. Open the extracted folder in Visual Studio Code.
4. If you prefer to update your existing project, replace its `src` folder and `app.json` with the ones from this ZIP. Do not keep duplicate copies of the same AL objects.
5. Keep your own `.vscode/launch.json`; an environment-neutral example is included as `.vscode/launch.json.example`.

## 2. Package and publish

1. Confirm the sandbox is compatible with Business Central application 27.5 and AI Development Toolkit 27.5.
2. Run **AL: Download Symbols**.
3. Run **AL: Package**.
4. Publish the newly generated version `1.0.2.4` application to the sandbox with schema synchronization.
5. Do not publish either old `1.0.0.0` or `1.0.1.4` package after publishing this version.

The generated `.app` is created by the AL extension after packaging; it is not included in this source ZIP.

## 3. Configure permissions

- Mailbox administrator or integration user: assign `APSS AGENT MAIL`.
- Human reviewer who approves drafts and creates Items: assign `APSS ITEM APPROVE` plus the normal Item permissions required by your company.
- Custom Item Agent: assign `APSS ITEM DRAFT`.
- Ensure the reviewer and Item Agent have the required read permission supplied by the extension that owns APSS Item Brand table 50001.

## 4. Configure the Item Agent profile

Publishing the profile does not automatically change an existing agent.

1. Open **Agents**.
2. Select **ITEM AGENT**.
3. Open **Setup**.
4. Return to **APSS Agent Mailbox Setup** and run **Apply Item Agent Profile**. Selecting the Item Agent again also applies the profile.
5. Confirm the agent's permission set includes **APSS ITEM DRAFT**.
6. Replace the custom agent instructions with `ITEM-AGENT-INSTRUCTIONS.md` from this ZIP.
7. End or cancel any Item Agent task that started before the profile was applied. Send a new test email or start a new task; an already-running task keeps its earlier page context.

If the task mentions `APSS-SG` or opens **My Accounts**, the Item Agent still has the wrong profile.

## 5. Configure mailbox and Sales Agent

1. Open **APSS Agent Mailbox Setup**.
2. Select the custom Item Agent first.
3. Select the Sales Agent. The Cloud-safe lookup displays users whose user/full name identifies the Microsoft Sales Order Agent, excludes the configured Item Agent, and validates the selected result as an active agent.
4. Select the Microsoft 365 email account.
5. Enable the setup and schedule synchronization.
6. Keep **Raise Mailbox Filing Event** enabled only when a Power Automate flow uses the event to move or archive the original email.

## 6. Test the complete workflow

1. Send a new test email. Use a new message because historical messages retrieved by an older version might not have an `APSS Source Email` record.
2. Pull incoming requests and allow the Item Agent task to run.
3. Confirm draft rows appear on **APSS Item Request Drafts**.
4. In Edit List mode, verify Brand Code shows a lookup and select a valid Brand.
5. Correct any agent-created values, approve the draft lines, and create the Items.
6. Confirm the Item Description equals Manufacturer Part No. and the Item is not blocked.
7. After every line from that email is Item Created, confirm a new task appears for the Sales Order Agent.
8. If the handoff fails, correct the Sales Agent setup and run **Activate Sales Order Agent** on one of the source draft rows. The already-created Items remain intact.
