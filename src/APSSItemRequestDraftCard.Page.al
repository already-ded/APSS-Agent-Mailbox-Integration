namespace APSS.AgentMailbox;

page 90211 "APSS Item Request Draft Card"
{
    Caption = 'APSS Item Request Draft';
    PageType = Card;
    SourceTable = "APSS Item Request Draft";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Review)
            {
                Caption = 'Review';
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Proposed Item No."; Rec."Proposed Item No.") { ApplicationArea = All; }
                field("Manufacturer Part No."; Rec."Manufacturer Part No.") { ApplicationArea = All; }
                field("Brand Code"; Rec."Brand Code")
                {
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Selects a valid Brand Code from APSS Item Brand table 50001. The reviewer can correct the value before approval.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemRequestMgt: Codeunit "APSS Item Request Mgt.";
                        SelectedBrandCode: Code[50];
                    begin
                        SelectedBrandCode := Rec."Brand Code";
                        if not ItemRequestMgt.LookupBrandCode(SelectedBrandCode) then
                            exit(false);
                        Rec.Validate("Brand Code", SelectedBrandCode);
                        Text := SelectedBrandCode;
                        exit(true);
                    end;
                }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Description 2"; Rec."Description 2") { ApplicationArea = All; }
                field("Technical Description"; Rec."Technical Description") { ApplicationArea = All; MultiLine = true; }
                field("Base Unit of Measure"; Rec."Base Unit of Measure") { ApplicationArea = All; }
                field("Item Category Code"; Rec."Item Category Code") { ApplicationArea = All; }
                field("Inventory Posting Group"; Rec."Inventory Posting Group") { ApplicationArea = All; }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group") { ApplicationArea = All; }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group") { ApplicationArea = All; }
                field("Costing Method"; Rec."Costing Method") { ApplicationArea = All; }
                field("Unit Cost"; Rec."Unit Cost") { ApplicationArea = All; }
                field("Vendor No."; Rec."Vendor No.") { ApplicationArea = All; }
                field("Vendor Item No."; Rec."Vendor Item No.") { ApplicationArea = All; }
                field("Manufacturer Code"; Rec."Manufacturer Code") { ApplicationArea = All; }
                field("Agent Notes"; Rec."Agent Notes") { ApplicationArea = All; MultiLine = true; }
            }
            group(Source)
            {
                Caption = 'Source Email';
                field("Source Sender"; Rec."Source Sender") { ApplicationArea = All; }
                field("Email Subject"; Rec."Email Subject") { ApplicationArea = All; }
                field("Source Message ID"; Rec."Source Message ID") { ApplicationArea = All; }
                field("Source Conversation ID"; Rec."Source Conversation ID") { ApplicationArea = All; }
                field("Request Line No."; Rec."Request Line No.") { ApplicationArea = All; }
            }
            group(Result)
            {
                Caption = 'Result';
                field("Created Item No."; Rec."Created Item No.") { ApplicationArea = All; }
                field("Sales Agent Task Created"; Rec."Sales Agent Task Created") { ApplicationArea = All; }
                field("Sales Agent Task ID"; Rec."Sales Agent Task ID") { ApplicationArea = All; }
                field("Sales Agent Task Created At"; Rec."Sales Agent Task Created At") { ApplicationArea = All; }
                field("Ready Event Raised"; Rec."Ready Event Raised") { ApplicationArea = All; }
                field("Ready Event Raised At"; Rec."Ready Event Raised At") { ApplicationArea = All; }
            }
        }
    }
}
