namespace APSS.AgentMailbox;

permissionset 90202 "APSS ITEM DRAFT"
{
    Caption = 'APSS Item Draft Writer';
    Assignable = true;

    Permissions =
        tabledata "APSS Item Request Draft" = RIM,
        table "APSS Item Request Draft" = X,
        tabledata "APSS Brand Lookup Buffer" = RIMD,
        table "APSS Brand Lookup Buffer" = X,
        page "APSS Brand Lookup" = X,
        page "APSS Item Request Drafts" = X,
        page "APSS Item Request Draft Card" = X,
        page "APSS Item Agent Role Center" = X,
        page "APSS Item Agent Home" = X;
}
