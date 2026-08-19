namespace APSS.AgentMailbox;

using System.Agents;

codeunit 90204 "APSS Agent Mail Management"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure ShouldRun(Setup: Record "APSS Agent Mail Setup"): Boolean
    var
        Agent: Codeunit Agent;
    begin
        if not Setup.Enabled then
            exit(false);
        if IsNullGuid(Setup."Agent User Security ID") then
            exit(false);
        if IsNullGuid(Setup."Email Account ID") then
            exit(false);

        exit(Agent.IsActive(Setup."Agent User Security ID"));
    end;

    procedure ValidateForScheduling(Setup: Record "APSS Agent Mail Setup")
    var
        Agent: Codeunit Agent;
    begin
        Setup.TestField(Enabled, true);
        if IsNullGuid(Setup."Agent User Security ID") then
            Error('Select a custom agent.');
        if not Agent.IsActive(Setup."Agent User Security ID") then
            Error('The selected custom agent is not active. Activate it before scheduling synchronization.');
        if IsNullGuid(Setup."Email Account ID") then
            Error('Select a Microsoft 365 email account.');
        Setup.TestField("Earliest Sync At");
        Setup.TestField("Sync Interval (Minutes)");
        Setup.TestField("Max Emails Per Run");
    end;

    procedure ScheduleNextRun(Setup: Record "APSS Agent Mail Setup")
    var
        DelayInMilliseconds: Integer;
    begin
        ValidateForScheduling(Setup);

        Setup.LockTable();
        Setup.GetBySystemId(Setup.SystemId);
        RemoveScheduledTask(Setup);

        DelayInMilliseconds := Setup."Sync Interval (Minutes)" * 60 * 1000;
        Setup."Scheduled Task ID" := TaskScheduler.CreateTask(
            Codeunit::"APSS Agent Mail Dispatcher",
            Codeunit::"APSS Agent Mail Error Hdlr.",
            true,
            CompanyName(),
            CurrentDateTime() + DelayInMilliseconds,
            Setup.RecordId);
        Setup.Modify();
        Commit();
    end;

    procedure RemoveScheduledTask(var Setup: Record "APSS Agent Mail Setup")
    var
        NullGuid: Guid;
    begin
        if TaskScheduler.TaskExists(Setup."Scheduled Task ID") then
            TaskScheduler.CancelTask(Setup."Scheduled Task ID");

        Setup."Scheduled Task ID" := NullGuid;
        Setup.Modify();
    end;
}
