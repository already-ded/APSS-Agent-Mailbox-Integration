namespace APSS.AgentMailbox;

codeunit 90215 "APSS Sales Handoff Runner"
{
    Access = Internal;
    TableNo = "APSS Source Email";
    Permissions = tabledata "APSS Source Email" = RIMD;

    trigger OnRun()
    var
        ItemRequestMgt: Codeunit "APSS Item Request Mgt.";
    begin
        ItemRequestMgt.ActivateSalesAgentForSource(Rec."External Message ID");
    end;
}
