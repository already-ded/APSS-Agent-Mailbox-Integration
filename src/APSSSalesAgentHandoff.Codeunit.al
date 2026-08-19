namespace APSS.AgentMailbox;

using System.Agents;
using System.Email;

codeunit 90211 "APSS Sales Agent Handoff"
{
    Access = Internal;
    Permissions = tabledata "APSS Source Email" = rimd;

    var
        TaskTitleLbl: Label 'Sales order request from %1', Comment = '%1 = sender name or address';
        SalesMessageLbl: Label 'EMAIL FROM: %1\SUBJECT: %2\\%3', Comment = '%1 = sender address, %2 = subject, %3 = email body';

    procedure CreateTask(SourceMessageId: Text[250]): BigInteger
    var
        Setup: Record "APSS Agent Mail Setup";
        SourceEmail: Record "APSS Source Email";
        Agent: Codeunit Agent;
        AgentTaskId: BigInteger;
    begin
        if not Setup.Get(1) then
            Error('APSS Agent Mailbox Setup has not been configured.');
        Setup.TestField("Sales Agent User Security ID");
        if not Agent.IsActive(Setup."Sales Agent User Security ID") then
            Error('The configured Sales Order Agent is not active.');

        if not SourceEmail.Get(SourceMessageId) then
            Error('Source email %1 was not captured. Pull the email again after publishing this version, or use a new test email.', SourceMessageId);

        if SourceEmail."Sales Agent Task Created" then
            exit(SourceEmail."Sales Agent Task ID");

        AgentTaskId := AddOriginalEmailToAgent(Setup, SourceEmail);
        SourceEmail."Sales Agent Task Created" := true;
        SourceEmail."Sales Agent Task ID" := AgentTaskId;
        SourceEmail."Sales Agent Task Created At" := CurrentDateTime();
        SourceEmail.Modify();
        exit(AgentTaskId);
    end;

    local procedure AddOriginalEmailToAgent(Setup: Record "APSS Agent Mail Setup"; SourceEmail: Record "APSS Source Email"): BigInteger
    var
        AgentTaskBuilder: Codeunit "Agent Task Builder";
    begin
        if AgentTaskBuilder.TaskExists(Setup."Sales Agent User Security ID", SourceEmail."Conversation ID") then
            exit(AddToExistingTask(Setup, SourceEmail));
        exit(AddToNewTask(Setup, SourceEmail));
    end;

    local procedure AddToExistingTask(Setup: Record "APSS Agent Mail Setup"; SourceEmail: Record "APSS Source Email"): BigInteger
    var
        AgentTask: Record "Agent Task";
        AgentTaskMessage: Record "Agent Task Message";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        EmailMessage: Codeunit "Email Message";
        MessageText: Text;
    begin
        AgentTask.SetRange("Agent User Security ID", Setup."Sales Agent User Security ID");
        AgentTask.SetRange("External ID", SourceEmail."Conversation ID");
        if not AgentTask.FindFirst() then
            Error('The Sales Order Agent task for conversation %1 could not be found.', SourceEmail."Conversation ID");

        AgentTaskMessage.SetRange("Task ID", AgentTask.ID);
        AgentTaskMessage.SetRange("External ID", SourceEmail."External Message ID");
        if not AgentTaskMessage.IsEmpty() then
            exit(AgentTask.ID);

        EmailMessage.Get(SourceEmail."Email Message ID");
        MessageText := StrSubstNo(SalesMessageLbl, SourceEmail."Sender Address", SourceEmail.Subject, EmailMessage.GetBody());
        AgentTaskMessageBuilder.Initialize(SourceEmail."Sender Address", MessageText)
            .SetMessageExternalID(SourceEmail."External Message ID")
            .SetIgnoreAttachment(false)
            .SetAgentTask(AgentTask);
        AddSupportedAttachments(EmailMessage, AgentTaskMessageBuilder);
        AgentTaskMessageBuilder.Create();
        exit(AgentTask.ID);
    end;

    local procedure AddToNewTask(Setup: Record "APSS Agent Mail Setup"; SourceEmail: Record "APSS Source Email"): BigInteger
    var
        AgentTask: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        EmailMessage: Codeunit "Email Message";
        MessageText: Text;
        TitleSource: Text;
        TaskTitle: Text[150];
    begin
        EmailMessage.Get(SourceEmail."Email Message ID");
        MessageText := StrSubstNo(SalesMessageLbl, SourceEmail."Sender Address", SourceEmail.Subject, EmailMessage.GetBody());
        TitleSource := SourceEmail."Sender Name";
        if TitleSource = '' then
            TitleSource := SourceEmail."Sender Address";
        TaskTitle := CopyStr(StrSubstNo(TaskTitleLbl, TitleSource), 1, MaxStrLen(AgentTask.Title));

        AgentTaskMessageBuilder.Initialize(SourceEmail."Sender Address", MessageText)
            .SetMessageExternalID(SourceEmail."External Message ID")
            .SetIgnoreAttachment(false);
        AddSupportedAttachments(EmailMessage, AgentTaskMessageBuilder);

        AgentTaskBuilder.Initialize(Setup."Sales Agent User Security ID", TaskTitle)
            .SetExternalId(SourceEmail."Conversation ID")
            .AddTaskMessage(AgentTaskMessageBuilder)
            .Create();

        AgentTask.SetRange("Agent User Security ID", Setup."Sales Agent User Security ID");
        AgentTask.SetRange("External ID", SourceEmail."Conversation ID");
        if not AgentTask.FindFirst() then
            Error('The Sales Order Agent task was created but could not be retrieved.');
        exit(AgentTask.ID);
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
