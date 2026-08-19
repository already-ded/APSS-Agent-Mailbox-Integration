namespace APSS.AgentMailbox;

codeunit 90201 "APSS Agent Mail Error Hdlr."
{
    Access = Internal;
    TableNo = "APSS Agent Mail Setup";
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        Management: Codeunit "APSS Agent Mail Management";
    begin
        if Management.ShouldRun(Rec) then
            Management.ScheduleNextRun(Rec);
    end;
}
