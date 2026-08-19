namespace APSS.AgentMailbox;

codeunit 90200 "APSS Agent Mail Dispatcher"
{
    Access = Internal;
    TableNo = "APSS Agent Mail Setup";
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        RunAgentMailboxCycle(Rec);
    end;

    local procedure RunAgentMailboxCycle(Setup: Record "APSS Agent Mail Setup")
    var
        Management: Codeunit "APSS Agent Mail Management";
        LastSync: DateTime;
        RetrievalSuccess: Boolean;
    begin
        if not Management.ShouldRun(Setup) then
            exit;

        LastSync := CurrentDateTime();
        RetrievalSuccess := Codeunit.Run(Codeunit::"APSS Agent Retrieve Emails", Setup);
        Codeunit.Run(Codeunit::"APSS Agent Send Replies", Setup);

        Management.ScheduleNextRun(Setup);

        if RetrievalSuccess then
            UpdateLastSync(Setup, LastSync);
    end;

    local procedure UpdateLastSync(var Setup: Record "APSS Agent Mail Setup"; LastSync: DateTime)
    begin
        Setup.GetBySystemId(Setup.SystemId);
        Setup."Last Sync At" := LastSync;
        Setup.Modify();
        Commit();
    end;
}
