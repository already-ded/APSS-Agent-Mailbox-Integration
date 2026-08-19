namespace APSS.AgentMailbox;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Vendor;

table 90210 "APSS Item Request Draft"
{
    Caption = 'APSS Item Request Draft';
    DataClassification = CustomerContent;
    DrillDownPageId = "APSS Item Request Drafts";
    LookupPageId = "APSS Item Request Drafts";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Source Message ID"; Text[250])
        {
            Caption = 'Source Message ID';
        }
        field(3; "Source Conversation ID"; Text[250])
        {
            Caption = 'Source Conversation ID';
        }
        field(4; "Request Line No."; Integer)
        {
            Caption = 'Request Line No.';
            MinValue = 0;
        }
        field(5; "Source Sender"; Text[250])
        {
            Caption = 'Source Sender';
        }
        field(6; "Email Subject"; Text[250])
        {
            Caption = 'Email Subject';
        }
        field(7; Status; Enum "APSS Item Request Status")
        {
            Caption = 'Status';
        }
        field(10; "Proposed Item No."; Code[20])
        {
            Caption = 'Proposed Item No.';
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Reviewer-editable draft description. The created Item Description is always taken from Manufacturer Part No.';
        }
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(13; "Technical Description"; Text[250])
        {
            Caption = 'Technical Description';
            ToolTip = 'Stores the detailed description on the draft for reviewer reference. It is not written to a non-existent Long Description field on the Item.';
        }
        field(14; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            TableRelation = "Unit of Measure".Code;
        }
        field(15; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category".Code;
        }
        field(16; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group".Code;
        }
        field(17; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group".Code;
        }
        field(18; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group".Code;
        }
        field(19; "Costing Method"; Enum "Costing Method")
        {
            Caption = 'Costing Method';
        }
        field(20; "Unit Cost"; Decimal)
        {
            Caption = 'Unit Cost';
            MinValue = 0;
            AutoFormatType = 2;
        }
        field(21; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor."No.";
        }
        field(22; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
        }
        field(23; "Manufacturer Code"; Code[10])
        {
            Caption = 'Manufacturer Code';
            TableRelation = Manufacturer.Code;
        }
        field(24; "Manufacturer Part No."; Text[50])
        {
            Caption = 'Manufacturer Part No.';

            trigger OnValidate()
            begin
                Description := CopyStr("Manufacturer Part No.", 1, MaxStrLen(Description));
            end;
        }
        field(25; "Agent Notes"; Text[2048])
        {
            Caption = 'Agent Notes';
        }
        field(26; "Brand Code"; Code[50])
        {
            Caption = 'Brand Code';
            ToolTip = 'The reviewer can select or correct this value before approval. The lookup is opened dynamically from APSS Item Brand table 50001.';
        }
        field(30; "Created Item No."; Code[20])
        {
            Caption = 'Created Item No.';
            Editable = false;
            TableRelation = Item."No.";
        }
        field(31; "Created At"; DateTime)
        {
            Caption = 'Draft Created At';
            Editable = false;
        }
        field(32; "Reviewed By"; Text[100])
        {
            Caption = 'Reviewed By';
            Editable = false;
        }
        field(33; "Reviewed At"; DateTime)
        {
            Caption = 'Reviewed At';
            Editable = false;
        }
        field(34; "Item Created By"; Text[100])
        {
            Caption = 'Item Created By';
            Editable = false;
        }
        field(35; "Item Created At"; DateTime)
        {
            Caption = 'Item Created At';
            Editable = false;
        }
        field(36; "Ready Event Raised"; Boolean)
        {
            Caption = 'Mailbox Filing Event Raised';
            Editable = false;
        }
        field(37; "Ready Event Raised At"; DateTime)
        {
            Caption = 'Mailbox Filing Event Raised At';
            Editable = false;
        }
        field(38; "Sales Agent Task Created"; Boolean)
        {
            Caption = 'Sales Agent Task Created';
            Editable = false;
        }
        field(39; "Sales Agent Task ID"; BigInteger)
        {
            Caption = 'Sales Agent Task ID';
            Editable = false;
        }
        field(40; "Sales Agent Task Created At"; DateTime)
        {
            Caption = 'Sales Agent Task Created At';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(SourceMessageLine; "Source Message ID", "Request Line No.") { Unique = true; }
        key(StatusCreatedAt; Status, "Created At") { }
    }

    trigger OnInsert()
    begin
        AssignRequestLineNo();
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();
    end;

    trigger OnModify()
    begin
        if Status = Status::"Item Created" then
            TestField("Created Item No.");
    end;

    local procedure AssignRequestLineNo()
    var
        ExistingDraft: Record "APSS Item Request Draft";
    begin
        if "Request Line No." <> 0 then
            exit;
        TestField("Source Message ID");
        ExistingDraft.SetRange("Source Message ID", "Source Message ID");
        if ExistingDraft.FindLast() then
            "Request Line No." := ExistingDraft."Request Line No." + 10000
        else
            "Request Line No." := 10000;
    end;
}
