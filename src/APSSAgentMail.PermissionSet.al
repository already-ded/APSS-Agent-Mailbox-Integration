namespace APSS.AgentMailbox;

permissionset 90200 "APSS AGENT MAIL"
{
    Caption = 'APSS Agent Mailbox';
    Assignable = true;

    Permissions =
        tabledata "APSS Agent Mail Setup" = RIMD,
        table "APSS Agent Mail Setup" = X,
        page "APSS Agent Mail Setup" = X,
        page "APSS Custom Agent Lookup" = X,
        page "APSS Agent User Lookup" = X,
        codeunit "APSS Agent Mail Dispatcher" = X,
        codeunit "APSS Agent Mail Error Hdlr." = X,
        codeunit "APSS Agent Retrieve Emails" = X,
        codeunit "APSS Agent Send Replies" = X,
        codeunit "APSS Agent Mail Management" = X,
        tabledata "APSS Source Email" = RIMD,
        table "APSS Source Email" = X,
        codeunit "APSS Sales Agent Handoff" = X,
        codeunit "APSS Sales Handoff Runner" = X,
        codeunit "APSS External Events" = X,
        tabledata "APSS Brand Lookup Buffer" = RIMD,
        table "APSS Brand Lookup Buffer" = X,
        page "APSS Brand Lookup" = X,
        tabledata "APSS Item Request Draft" = RIM,
        table "APSS Item Request Draft" = X,
        page "APSS Item Request Drafts" = X,
        page "APSS Item Request Draft Card" = X,
        page "APSS Item Agent Role Center" = X,
        page "APSS Item Agent Home" = X;
}
