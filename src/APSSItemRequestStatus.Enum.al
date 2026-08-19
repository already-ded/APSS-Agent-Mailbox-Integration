namespace APSS.AgentMailbox;

enum 90210 "APSS Item Request Status"
{
    Extensible = false;

    value(0; Draft) { Caption = 'Draft'; }
    value(1; "Pending Review") { Caption = 'Pending Review'; }
    value(2; Approved) { Caption = 'Approved'; }
    value(3; Rejected) { Caption = 'Rejected'; }
    value(4; "Item Created") { Caption = 'Item Created'; }
}
