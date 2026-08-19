namespace APSS.AgentMailbox;

using System.Email;

table 90200 "APSS Agent Mail Setup"
{
    Caption = 'APSS Agent Mailbox Setup';
    Access = Internal;
    Extensible = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    DataClassification = SystemMetadata;
    DataCaptionFields = "Agent Name", "Email Address";

    fields
    {
        field(1; Id; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Agent User Security ID"; Guid)
        {
            Caption = 'Item Agent User Security ID';
            DataClassification = SystemMetadata;
        }
        field(3; "Agent Name"; Text[100])
        {
            Caption = 'Item Agent Name';
            DataClassification = CustomerContent;
        }
        field(4; "Email Account ID"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(5; "Email Connector"; Enum "Email Connector")
        {
            DataClassification = SystemMetadata;
        }
        field(6; "Email Address"; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(7; "Last Sync At"; DateTime)
        {
            DataClassification = SystemMetadata;
        }
        field(8; "Earliest Sync At"; DateTime)
        {
            DataClassification = SystemMetadata;
        }
        field(9; "Scheduled Task ID"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(10; Enabled; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(11; "Allow Reviewed Replies"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(12; "Sync Interval (Minutes)"; Integer)
        {
            Caption = 'Sync Interval (Minutes)';
            MinValue = 1;
            MaxValue = 60;
        }
        field(13; "Max Emails Per Run"; Integer)
        {
            DataClassification = SystemMetadata;
            MinValue = 1;
            MaxValue = 50;
        }
        field(14; "Sales Agent User Security ID"; Guid)
        {
            Caption = 'Sales Order Agent User Security ID';
            DataClassification = SystemMetadata;
        }
        field(15; "Sales Agent Name"; Text[100])
        {
            Caption = 'Sales Order Agent Name';
            DataClassification = CustomerContent;
        }
        field(16; "Raise Ready Business Event"; Boolean)
        {
            Caption = 'Raise Mailbox Filing Event';
            DataClassification = SystemMetadata;
            InitValue = true;
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if Id = 0 then
            Id := 1;
        if "Earliest Sync At" = 0DT then
            "Earliest Sync At" := CurrentDateTime();
        if "Sync Interval (Minutes)" = 0 then
            "Sync Interval (Minutes)" := 2;
        if "Max Emails Per Run" = 0 then
            "Max Emails Per Run" := 50;
        "Raise Ready Business Event" := true;
    end;
}
