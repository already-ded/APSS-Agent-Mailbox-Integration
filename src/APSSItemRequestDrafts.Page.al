namespace APSS.AgentMailbox;

page 90210 "APSS Item Request Drafts"
{
    Caption = 'APSS Item Request Drafts';
    PageType = List;
    SourceTable = "APSS Item Request Draft";
    ApplicationArea = All;
    UsageCategory = Lists;
    DelayedInsert = true;
    CardPageId = "APSS Item Request Draft Card";

    layout
    {
        area(Content)
        {
            repeater(Drafts)
            {
                field(Status; Rec.Status) { ApplicationArea = All; StyleExpr = StatusStyle; }
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; Editable = false; }
                field("Source Sender"; Rec."Source Sender") { ApplicationArea = All; }
                field("Email Subject"; Rec."Email Subject") { ApplicationArea = All; }
                field("Proposed Item No."; Rec."Proposed Item No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Description 2"; Rec."Description 2") { ApplicationArea = All; }
                field("Technical Description"; Rec."Technical Description") { ApplicationArea = All; }
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
                field("Agent Notes"; Rec."Agent Notes") { ApplicationArea = All; }
                field("Created Item No."; Rec."Created Item No.") { ApplicationArea = All; }
                field("Source Message ID"; Rec."Source Message ID") { ApplicationArea = All; }
                field("Source Conversation ID"; Rec."Source Conversation ID") { ApplicationArea = All; }
                field("Request Line No."; Rec."Request Line No.") { ApplicationArea = All; }
                field("Sales Agent Task Created"; Rec."Sales Agent Task Created") { ApplicationArea = All; }
                field("Sales Agent Task ID"; Rec."Sales Agent Task ID") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PullIncomingRequests)
            {
                Caption = 'Pull Incoming Requests';
                ApplicationArea = All;
                Image = GetEntries;

                trigger OnAction()
                var
                    Setup: Record "APSS Agent Mail Setup";
                    RetrieveEmails: Codeunit "APSS Agent Retrieve Emails";
                    RetrievedCount: Integer;
                begin
                    if not Setup.Get(1) then
                        Error('Complete APSS Agent Mailbox Setup first.');
                    Setup.TestField(Enabled, true);
                    RetrievedCount := RetrieveEmails.RetrieveNow(Setup);
                    CurrPage.Update(false);
                    Message('%1 incoming email(s) were sent to the Item Agent.', RetrievedCount);
                end;
            }
            action(ApproveSelected)
            {
                Caption = 'Approve Selected';
                ApplicationArea = All;
                Image = Approve;

                trigger OnAction()
                var
                    SelectedDraft: Record "APSS Item Request Draft";
                    ItemRequestMgt: Codeunit "APSS Item Request Mgt.";
                    ApprovedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(SelectedDraft);
                    ApprovedCount := ItemRequestMgt.ApproveSelected(SelectedDraft);
                    CurrPage.Update(false);
                    Message('%1 item request(s) were approved.', ApprovedCount);
                end;
            }
            action(CreateSelectedItems)
            {
                Caption = 'Create Selected Items';
                ApplicationArea = All;
                Image = NewItem;
                ToolTip = 'Creates Items. When all lines from an email are created, the original email is submitted directly to the Sales Order Agent.';

                trigger OnAction()
                var
                    SelectedDraft: Record "APSS Item Request Draft";
                    ItemRequestMgt: Codeunit "APSS Item Request Mgt.";
                    CreatedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(SelectedDraft);
                    if not Confirm('Create official Item records for the selected approved drafts?', false) then
                        exit;
                    CreatedCount := ItemRequestMgt.CreateSelectedItems(SelectedDraft);
                    CurrPage.Update(false);
                    if ItemRequestMgt.GetHandoffFailureCount() = 0 then
                        Message('%1 item(s) were created. Any source email whose lines are all complete was handed to the Sales Order Agent.', CreatedCount)
                    else
                        Message('%1 item(s) were created and kept. %2 Sales Order Agent handoff(s) failed; correct the setup and use Activate Sales Order Agent to retry.', CreatedCount, ItemRequestMgt.GetHandoffFailureCount());
                end;
            }
            action(ActivateSalesOrderAgent)
            {
                Caption = 'Activate Sales Order Agent';
                ApplicationArea = All;
                Image = Process;
                ToolTip = 'Retries the Sales Order Agent handoff for the source email on the current row.';

                trigger OnAction()
                var
                    ItemRequestMgt: Codeunit "APSS Item Request Mgt.";
                begin
                    Rec.TestField("Source Message ID");
                    ItemRequestMgt.ActivateSalesAgentForSource(Rec."Source Message ID");
                    CurrPage.Update(false);
                    Message('The source email was handed to the Sales Order Agent.');
                end;
            }
            action(RejectSelected)
            {
                Caption = 'Reject Selected';
                ApplicationArea = All;
                Image = Reject;

                trigger OnAction()
                var
                    SelectedDraft: Record "APSS Item Request Draft";
                    ItemRequestMgt: Codeunit "APSS Item Request Mgt.";
                    RejectedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(SelectedDraft);
                    if not Confirm('Reject the selected item requests?', false) then
                        exit;
                    RejectedCount := ItemRequestMgt.RejectSelected(SelectedDraft);
                    CurrPage.Update(false);
                    Message('%1 item request(s) were rejected.', RejectedCount);
                end;
            }
        }
        area(Promoted)
        {
            actionref(PullIncomingRequestsPromoted; PullIncomingRequests) { }
            actionref(ApproveSelectedPromoted; ApproveSelected) { }
            actionref(CreateSelectedItemsPromoted; CreateSelectedItems) { }
            actionref(ActivateSalesOrderAgentPromoted; ActivateSalesOrderAgent) { }
        }
    }

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Draft, Rec.Status::"Pending Review": StatusStyle := 'Ambiguous';
            Rec.Status::Approved: StatusStyle := 'Favorable';
            Rec.Status::Rejected: StatusStyle := 'Unfavorable';
            Rec.Status::"Item Created": StatusStyle := 'StrongAccent';
        end;
    end;

    var
        StatusStyle: Text;
}
