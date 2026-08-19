namespace APSS.AgentMailbox;

using System.Integration;

codeunit 90212 "APSS External Events"
{
    [ExternalBusinessEvent('emailReadyForSales', 'Email ready for sales filing', 'Raised after the Sales Order Agent task has been created. Use it to move or archive the original mailbox email.', EventCategory::"APSS Agent Mail", '1.0')]
    procedure EmailReadyForSales(MailboxAddress: Text[250]; SourceMessageId: Text[250]; ConversationId: Text[250]; EmailSubject: Text[250])
    begin
    end;
}
