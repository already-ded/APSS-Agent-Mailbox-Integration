namespace APSS.AgentMailbox;

using Microsoft.Inventory.Item;

permissionset 90201 "APSS ITEM APPROVE"
{
    Caption = 'APSS Item Request Approver';
    Assignable = true;

    Permissions =
        tabledata "APSS Item Request Draft" = RIMD,
        table "APSS Item Request Draft" = X,
        page "APSS Item Request Drafts" = X,
        page "APSS Item Request Draft Card" = X,
        codeunit "APSS Item Request Mgt." = X,
        codeunit "APSS Sales Agent Handoff" = X,
        codeunit "APSS Sales Handoff Runner" = X,
        codeunit "APSS External Events" = X,
        tabledata "APSS Brand Lookup Buffer" = RIMD,
        table "APSS Brand Lookup Buffer" = X,
        page "APSS Brand Lookup" = X,
        tabledata "APSS Source Email" = RIM,
        table "APSS Source Email" = X,
        tabledata Item = RIM;
}
