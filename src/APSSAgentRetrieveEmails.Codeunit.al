namespace APSS.AgentMailbox;

using System.Agents;
using System.Email;

codeunit 90202 "APSS Agent Retrieve Emails"
{
    Access = Internal;
    TableNo = "APSS Agent Mail Setup";
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Email Inbox" = rd,
                  tabledata "APSS Source Email" = rimd;

    var
        AgentTaskTitleLbl: Label 'Email from %1', Comment = '%1 = Sender Name';
        MessageTemplateLbl: Label '<b>Source sender:</b> %1<br/><b>Source conversation ID:</b> %2<br/><b>Source message ID:</b> %3<br/><b>Subject:</b> %4<br/><b>Body:</b> %5';

    trigger OnRun()
    begin
        RetrieveNow(Rec);
    end;

    procedure RetrieveNow(Setup: Record "APSS Agent Mail Setup"): Integer
    var
        EmailInbox: Record "Email Inbox";
        TempFilters: Record "Email Retrieval Filters" temporary;
        Email: Codeunit Email;
        RetrievalStartedAt: DateTime;
        RetrievedCount: Integer;
    begin
        RetrievalStartedAt := CurrentDateTime();
        SetEmailFilters(Setup, TempFilters);
        Email.RetrieveEmails(Setup."Email Account ID", Setup."Email Connector", EmailInbox, TempFilters);

        RetrievedCount := EmailInbox.Count();
        if EmailInbox.FindSet() then
            repeat
                SaveSourceEmail(EmailInbox);
                AddEmailToAgentTask(Setup, EmailInbox);
            until EmailInbox.Next() = 0;

        UpdateEarliestSyncTime(Setup, RetrievedCount, RetrievalStartedAt);
        Commit();
        exit(RetrievedCount);
    end;

    local procedure SetEmailFilters(Setup: Record "APSS Agent Mail Setup"; var TempFilters: Record "Email Retrieval Filters" temporary)
    begin
        TempFilters."Unread Emails" := true;
        TempFilters."Load Attachments" := true;
        TempFilters."Last Message Only" := true;
        TempFilters."Earliest Email" := Setup."Earliest Sync At";
        TempFilters."Max No. of Emails" := Setup."Max Emails Per Run";
        TempFilters.Insert();
    end;

    local procedure SaveSourceEmail(var EmailInbox: Record "Email Inbox")
    var
        SourceEmail: Record "APSS Source Email";
        EmailMessage: Codeunit "Email Message";
        ExternalMessageId: Text[250];
    begin
        EmailMessage.Get(EmailInbox."Message ID");
        ExternalMessageId := CopyStr(EmailInbox."External Message ID", 1, MaxStrLen(ExternalMessageId));
        if not SourceEmail.Get(ExternalMessageId) then begin
            SourceEmail.Init();
            SourceEmail."External Message ID" := ExternalMessageId;
            SourceEmail."Created At" := CurrentDateTime();
            SourceEmail.Insert();
        end;

        SourceEmail."Email Message ID" := EmailInbox."Message ID";
        SourceEmail."Conversation ID" := CopyStr(EmailInbox."Conversation ID", 1, MaxStrLen(SourceEmail."Conversation ID"));
        SourceEmail."Sender Address" := CopyStr(EmailInbox."Sender Address", 1, MaxStrLen(SourceEmail."Sender Address"));
        SourceEmail."Sender Name" := CopyStr(EmailInbox."Sender Name", 1, MaxStrLen(SourceEmail."Sender Name"));
        SourceEmail.Subject := CopyStr(EmailMessage.GetSubject(), 1, MaxStrLen(SourceEmail.Subject));
        SourceEmail.Modify();
    end;

    local procedure UpdateEarliestSyncTime(var Setup: Record "APSS Agent Mail Setup"; RetrievedCount: Integer; RetrievalStartedAt: DateTime)
    begin
        Setup.GetBySystemId(Setup.SystemId);
        if RetrievedCount < Setup."Max Emails Per Run" then
            Setup."Earliest Sync At" := RetrievalStartedAt;
        Setup.Modify();
    end;

    local procedure AddEmailToAgentTask(Setup: Record "APSS Agent Mail Setup"; var EmailInbox: Record "Email Inbox")
    var
        AgentTaskBuilder: Codeunit "Agent Task Builder";
    begin
        if AgentTaskBuilder.TaskExists(Setup."Agent User Security ID", EmailInbox."Conversation ID") then
            AddEmailToExistingTask(Setup, EmailInbox)
        else
            AddEmailToNewTask(Setup, EmailInbox);
        MarkEmailAsProcessed(Setup, EmailInbox);
    end;

    local procedure AddEmailToExistingTask(Setup: Record "APSS Agent Mail Setup"; var EmailInbox: Record "Email Inbox")
    var
        AgentTask: Record "Agent Task";
        AgentTaskMessage: Record "Agent Task Message";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        EmailMessage: Codeunit "Email Message";
        MessageText: Text;
    begin
        AgentTask.ReadIsolation(IsolationLevel::ReadCommitted);
        AgentTask.SetRange("Agent User Security ID", Setup."Agent User Security ID");
        AgentTask.SetRange("External ID", EmailInbox."Conversation ID");
        if not AgentTask.FindFirst() then
            exit;

        AgentTaskMessage.SetRange("Task ID", AgentTask.ID);
        AgentTaskMessage.SetRange("External ID", EmailInbox."External Message ID");
        if not AgentTaskMessage.IsEmpty() then
            exit;

        EmailMessage.Get(EmailInbox."Message ID");
        MessageText := StrSubstNo(MessageTemplateLbl, EmailInbox."Sender Address", EmailInbox."Conversation ID", EmailInbox."External Message ID", EmailMessage.GetSubject(), EmailMessage.GetBody());
        AgentTaskMessageBuilder.Initialize(EmailInbox."Sender Address", MessageText)
            .SetMessageExternalID(EmailInbox."External Message ID")
            .SetIgnoreAttachment(false)
            .SetAgentTask(AgentTask);
        AddSupportedAttachments(EmailMessage, AgentTaskMessageBuilder);
        AgentTaskMessageBuilder.Create();
    end;

    local procedure AddEmailToNewTask(Setup: Record "APSS Agent Mail Setup"; var EmailInbox: Record "Email Inbox")
    var
        AgentTask: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        EmailMessage: Codeunit "Email Message";
        MessageText: Text;
        AgentTaskTitle: Text[150];
    begin
        EmailMessage.Get(EmailInbox."Message ID");
        MessageText := StrSubstNo(MessageTemplateLbl, EmailInbox."Sender Address", EmailInbox."Conversation ID", EmailInbox."External Message ID", EmailMessage.GetSubject(), EmailMessage.GetBody());
        AgentTaskTitle := CopyStr(StrSubstNo(AgentTaskTitleLbl, EmailInbox."Sender Name"), 1, MaxStrLen(AgentTask.Title));

        AgentTaskMessageBuilder.Initialize(EmailInbox."Sender Address", MessageText)
            .SetMessageExternalID(EmailInbox."External Message ID")
            .SetIgnoreAttachment(false);
        AddSupportedAttachments(EmailMessage, AgentTaskMessageBuilder);

        AgentTaskBuilder.Initialize(Setup."Agent User Security ID", AgentTaskTitle)
            .SetExternalId(EmailInbox."Conversation ID")
            .AddTaskMessage(AgentTaskMessageBuilder)
            .Create();
    end;

    local procedure MarkEmailAsProcessed(Setup: Record "APSS Agent Mail Setup"; var EmailInbox: Record "Email Inbox")
    var
        Email: Codeunit Email;
    begin
        Email.MarkAsRead(Setup."Email Account ID", Setup."Email Connector", EmailInbox."External Message ID");
    end;

    local procedure AddSupportedAttachments(var EmailMessage: Codeunit "Email Message"; var AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder")
    var
        AttachmentInStream: InStream;
        MimeType: Text[100];
    begin
        if not EmailMessage.Attachments_First() then
            exit;
        repeat
            MimeType := CopyStr(LowerCase(EmailMessage.Attachments_GetContentType()), 1, MaxStrLen(MimeType));
            if IsSupportedMimeType(MimeType) then begin
                EmailMessage.Attachments_GetContent(AttachmentInStream);
                AgentTaskMessageBuilder.AddAttachment(EmailMessage.Attachments_GetName(), MimeType, AttachmentInStream, false);
            end;
        until EmailMessage.Attachments_Next() = 0;
    end;

    local procedure IsSupportedMimeType(MimeType: Text): Boolean
    begin
        exit((MimeType = 'application/pdf') or (MimeType = 'image/png') or (MimeType = 'image/jpeg') or (MimeType = 'image/jpg'));
    end;
}
