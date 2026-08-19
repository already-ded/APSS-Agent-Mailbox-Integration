namespace APSS.AgentMailbox;

using System.Agents;
using System.Agents.Designer.CustomAgent;
using System.Email;
using System.Security.AccessControl;
using System.Threading;

page 90200 "APSS Agent Mail Setup"
{
    Caption = 'APSS Agent Mailbox Setup';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "APSS Agent Mail Setup";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Agents)
            {
                Caption = 'Agents';

                field("Agent Name"; Rec."Agent Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the custom Item Agent that receives incoming request emails.';

                    trigger OnAssistEdit()
                    begin
                        SelectItemAgent();
                    end;
                }
                field("Sales Agent Name"; Rec."Sales Agent Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the active Sales Order Agent that receives the original email after every requested item has been created.';

                    trigger OnAssistEdit()
                    begin
                        SelectSalesAgent();
                    end;
                }
            }
            group(Mailbox)
            {
                Caption = 'Mailbox';

                field("Email Address"; Rec."Email Address")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the Microsoft 365 email account monitored by this integration.';

                    trigger OnAssistEdit()
                    begin
                        SelectEmailAccount();
                    end;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
                field("Allow Reviewed Replies"; Rec."Allow Reviewed Replies")
                {
                    ApplicationArea = All;
                }
                field("Raise Ready Business Event"; Rec."Raise Ready Business Event")
                {
                    ApplicationArea = All;
                    ToolTip = 'Raises the optional emailReadyForSales business event after the Sales Order Agent task is created. Use the event only to move or archive the mailbox message.';
                }
            }
            group(Synchronization)
            {
                Caption = 'Synchronization';

                field("Earliest Sync At"; Rec."Earliest Sync At")
                {
                    ApplicationArea = All;
                }
                field("Sync Interval (Minutes)"; Rec."Sync Interval (Minutes)")
                {
                    ApplicationArea = All;
                }
                field("Max Emails Per Run"; Rec."Max Emails Per Run")
                {
                    ApplicationArea = All;
                }
                field("Last Sync At"; Rec."Last Sync At")
                {
                    ApplicationArea = All;
                }
                field("Scheduled Task ID"; Rec."Scheduled Task ID")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ScheduleSync)
            {
                Caption = 'Schedule Sync';
                ApplicationArea = All;

                trigger OnAction()
                var
                    Management: Codeunit "APSS Agent Mail Management";
                begin
                    CurrPage.SaveRecord();
                    ValidateAgents();
                    Management.ScheduleNextRun(Rec);
                    CurrPage.Update(false);
                    Message('Mailbox synchronization has been scheduled.');
                end;
            }
            action(RemoveScheduledSync)
            {
                Caption = 'Stop Sync';
                ApplicationArea = All;

                trigger OnAction()
                var
                    Management: Codeunit "APSS Agent Mail Management";
                begin
                    Management.RemoveScheduledTask(Rec);
                    CurrPage.Update(false);
                    Message('Mailbox synchronization has been stopped.');
                end;
            }
            action(PullIncomingRequests)
            {
                Caption = 'Pull Incoming Requests';
                ApplicationArea = All;
                Image = GetEntries;

                trigger OnAction()
                var
                    RetrieveEmails: Codeunit "APSS Agent Retrieve Emails";
                    Management: Codeunit "APSS Agent Mail Management";
                    RetrievedCount: Integer;
                begin
                    CurrPage.SaveRecord();
                    ValidateAgents();
                    Management.ValidateForScheduling(Rec);
                    RetrievedCount := RetrieveEmails.RetrieveNow(Rec);
                    CurrPage.Update(false);
                    Message('%1 incoming email(s) were sent to the Item Agent.', RetrievedCount);
                end;
            }
            action(ItemRequestDrafts)
            {
                Caption = 'Item Request Drafts';
                ApplicationArea = All;
                Image = List;
                RunObject = page "APSS Item Request Drafts";
            }
            action(ApplyItemAgentProfile)
            {
                Caption = 'Apply Item Agent Profile';
                ApplicationArea = All;
                Image = Setup;
                ToolTip = 'Assigns the APSS ITEM AGENT profile and Role Center to the configured custom Item Agent. Start a new agent task after applying it.';

                trigger OnAction()
                begin
                    Rec.TestField("Agent User Security ID");
                    SetItemAgentProfile(Rec."Agent User Security ID");
                    Message('The APSS ITEM AGENT profile was assigned. End any task that was already running under the previous profile, then start a new Item Agent task.');
                end;
            }
            action(ScheduledTasks)
            {
                Caption = 'Scheduled Tasks';
                ApplicationArea = All;

                trigger OnAction()
                var
                    ScheduledTask: Page "Scheduled Tasks";
                begin
                    ScheduledTask.Run();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get(1) then begin
            Rec.Init();
            Rec.Id := 1;
            Rec.Insert(true);
        end;
    end;

    local procedure SelectItemAgent()
    var
        TempCustomAgentInfo: Record "Custom Agent Info" temporary;
        SelectedAgentInfo: Record "Custom Agent Info" temporary;
        CustomAgent: Codeunit "Custom Agent";
        AgentLookup: Page "APSS Custom Agent Lookup";
    begin
        CustomAgent.GetCustomAgents(TempCustomAgentInfo);
        if TempCustomAgentInfo.IsEmpty() then
            Error('There are no custom agents available. Create and activate the Item Agent first.');

        AgentLookup.LoadAgents(TempCustomAgentInfo);
        AgentLookup.LookupMode(true);
        if AgentLookup.RunModal() <> Action::LookupOK then
            exit;

        AgentLookup.GetSelectedAgent(SelectedAgentInfo);
        SetItemAgentProfile(SelectedAgentInfo."User Security ID");
        Rec."Agent User Security ID" := SelectedAgentInfo."User Security ID";
        Rec."Agent Name" := CopyStr(SelectedAgentInfo."User Name", 1, MaxStrLen(Rec."Agent Name"));
        Rec.Modify(true);
        CurrPage.Update(false);
    end;

    local procedure SelectSalesAgent()
    var
        SelectedUser: Record User;
        AgentLookup: Page "APSS Agent User Lookup";
    begin
        Rec.TestField("Agent User Security ID");
        AgentLookup.LoadSalesOrderAgentCandidates(Rec."Agent User Security ID");
        AgentLookup.LookupMode(true);
        if AgentLookup.RunModal() <> Action::LookupOK then
            exit;

        AgentLookup.GetSelectedUser(SelectedUser);
        if SelectedUser."User Security ID" = Rec."Agent User Security ID" then
            Error('The Item Agent and Sales Order Agent must be different agents.');
        if not IsActiveAgent(SelectedUser."User Security ID") then
            Error('The selected agent is not active. Activate the Microsoft Sales Order Agent and select it again.');

        Rec."Sales Agent User Security ID" := SelectedUser."User Security ID";
        Rec."Sales Agent Name" := CopyStr(SelectedUser."User Name", 1, MaxStrLen(Rec."Sales Agent Name"));
        Rec.Modify(true);
        CurrPage.Update(false);
    end;

    local procedure ValidateAgents()
    begin
        Rec.TestField("Agent User Security ID");
        Rec.TestField("Sales Agent User Security ID");
        if Rec."Agent User Security ID" = Rec."Sales Agent User Security ID" then
            Error('The Item Agent and Sales Order Agent must be different agents.');
        if not IsActiveAgent(Rec."Agent User Security ID") then
            Error('The selected Item Agent is not active.');
        if not IsActiveAgent(Rec."Sales Agent User Security ID") then
            Error('The selected Sales Order Agent is not active.');
    end;

    local procedure IsActiveAgent(UserSecurityId: Guid): Boolean
    var
        IsActive: Boolean;
    begin
        if not TryGetAgentActive(UserSecurityId, IsActive) then
            exit(false);
        exit(IsActive);
    end;

    [TryFunction]
    local procedure TryGetAgentActive(UserSecurityId: Guid; var IsActive: Boolean)
    var
        AgentMgt: Codeunit Agent;
    begin
        IsActive := AgentMgt.IsActive(UserSecurityId);
    end;

    local procedure SetItemAgentProfile(ItemAgentUserSecurityId: Guid)
    var
        AgentMgt: Codeunit Agent;
        ProfileAppId: Guid;
    begin
        if not Evaluate(ProfileAppId, '7f89fd6b-6506-4d68-9a3b-4f7f3a4340d4') then
            Error('The APSS extension App ID is invalid.');
        AgentMgt.SetProfile(ItemAgentUserSecurityId, 'APSS ITEM AGENT', ProfileAppId);
    end;

    local procedure SelectEmailAccount()
    var
        TempEmailAccount: Record "Email Account" temporary;
        EmailAccounts: Page "Email Accounts";
    begin
        if not HasMicrosoft365EmailAccount() then
            Page.RunModal(Page::"Email Account Wizard");
        if not HasMicrosoft365EmailAccount() then
            exit;

        EmailAccounts.EnableLookupMode();
        EmailAccounts.FilterConnectorV4Accounts(true);
        if EmailAccounts.RunModal() <> Action::LookupOK then
            exit;

        EmailAccounts.GetAccount(TempEmailAccount);
        Rec."Email Account ID" := TempEmailAccount."Account Id";
        Rec."Email Connector" := TempEmailAccount.Connector;
        Rec."Email Address" := CopyStr(TempEmailAccount."Email Address", 1, MaxStrLen(Rec."Email Address"));
        Rec.Modify(true);
        CurrPage.Update(false);
    end;

    local procedure HasMicrosoft365EmailAccount(): Boolean
    var
        EmailAccounts: Record "Email Account";
        EmailAccount: Codeunit "Email Account";
        IConnector: Interface "Email Connector";
    begin
        EmailAccount.GetAllAccounts(false, EmailAccounts);
        if not EmailAccounts.FindSet() then
            exit(false);
        repeat
            IConnector := EmailAccounts.Connector;
            if IConnector is "Email Connector v4" then
                exit(true);
        until EmailAccounts.Next() = 0;
        exit(false);
    end;
}
