namespace APSS.AgentMailbox;

table 90214 "APSS Brand Lookup Buffer"
{
    Caption = 'APSS Brand Lookup Buffer';
    TableType = Temporary;
    DataClassification = SystemMetadata;
    LookupPageId = "APSS Brand Lookup";
    DrillDownPageId = "APSS Brand Lookup";

    fields
    {
        field(1; Code; Code[50])
        {
            Caption = 'Brand Code';
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}
