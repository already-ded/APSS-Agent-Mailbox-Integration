namespace APSS.AgentMailbox;

table 90211 "APSS Source Email"
{
    Caption = 'APSS Source Email';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "External Message ID"; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(2; "Email Message ID"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(3; "Conversation ID"; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(4; "Sender Address"; Text[250])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Sender Name"; Text[250])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; Subject; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(7; "Sales Agent Task Created"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(8; "Sales Agent Task ID"; BigInteger)
        {
            DataClassification = SystemMetadata;
        }
        field(9; "Sales Agent Task Created At"; DateTime)
        {
            DataClassification = SystemMetadata;
        }
        field(10; "Created At"; DateTime)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "External Message ID")
        {
            Clustered = true;
        }
    }
}
