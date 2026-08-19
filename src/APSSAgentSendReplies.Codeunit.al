namespace APSS.AgentMailbox;

using System.Agents;
using System.Email;

codeunit 90203 "APSS Agent Send Replies"
{
    Access = Internal;
    TableNo = "APSS Agent Mail Setup";
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        EmailSubjectTxt: Label 'Agent reply to task %1', Comment = '%1 = Agent Task ID';

    trigger OnRun()
    begin
        if Rec."Allow Reviewed Replies" then
            SendReviewedReplies(Rec);
    end;

    local procedure SendReviewedReplies(Setup: Record "APSS Agent Mail Setup")
    var
        OutputMessage: Record "Agent Task Message";
        InputMessage: Record "Agent Task Message";
        AgentMessage: Codeunit "Agent Message";
    begin
        OutputMessage.ReadIsolation(IsolationLevel::ReadCommitted);
        OutputMessage.SetRange(Status, OutputMessage.Status::Reviewed);
        OutputMessage.SetRange(Type, OutputMessage.Type::Output);
        OutputMessage.SetRange("Agent User Security ID", Setup."Agent User Security ID");
        if not OutputMessage.FindSet() then
            exit;

        repeat
            if InputMessage.Get(OutputMessage."Task ID", OutputMessage."Input Message ID") then
                if InputMessage."External ID" <> '' then
                    if TryReply(Setup, InputMessage, OutputMessage) then
                        AgentMessage.SetStatusToSent(OutputMessage);
        until OutputMessage.Next() = 0;
        Commit();
    end;

    local procedure TryReply(Setup: Record "APSS Agent Mail Setup"; var InputMessage: Record "Agent Task Message"; var OutputMessage: Record "Agent Task Message"): Boolean
    var
        AgentMessage: Codeunit "Agent Message";
        Email: Codeunit Email;
        EmailMessage: Codeunit "Email Message";
        Body: Text;
        Subject: Text;
    begin
        Subject := StrSubstNo(EmailSubjectTxt, InputMessage."Task ID");
        Body := AgentMessage.GetText(OutputMessage);
        EmailMessage.CreateReplyAll(Subject, Body, true, InputMessage."External ID");
        AddMessageAttachments(EmailMessage, OutputMessage);

        exit(Email.ReplyAll(EmailMessage, Setup."Email Account ID", Setup."Email Connector"));
    end;

    local procedure AddMessageAttachments(var EmailMessage: Codeunit "Email Message"; var AgentTaskMessage: Record "Agent Task Message")
    var
        AgentTaskFile: Record "Agent Task File";
        MessageAttachment: Record "Agent Task Message Attachment";
        AttachmentInStream: InStream;
    begin
        MessageAttachment.SetRange("Task ID", AgentTaskMessage."Task ID");
        MessageAttachment.SetRange("Message ID", AgentTaskMessage.ID);
        if not MessageAttachment.FindSet() then
            exit;

        repeat
            if AgentTaskFile.Get(MessageAttachment."Task ID", MessageAttachment."File ID") then begin
                AgentTaskFile.CalcFields(Content);
                AgentTaskFile.Content.CreateInStream(AttachmentInStream, TextEncoding::UTF8);
                EmailMessage.AddAttachment(AgentTaskFile."File Name", AgentTaskFile."File MIME Type", AttachmentInStream);
            end;
        until MessageAttachment.Next() = 0;
    end;
}
