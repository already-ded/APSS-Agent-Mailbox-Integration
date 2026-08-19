namespace APSS.AgentMailbox;

using System.Security.AccessControl;

page 90202 "APSS Agent User Lookup"
{
    Caption = 'Select Sales Order Agent';
    PageType = List;
    SourceTable = User;
    SourceTableTemporary = true;
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Agents)
            {
                field("User Name"; Rec."User Name")
                {
                    ApplicationArea = All;
                }
                field("Full Name"; Rec."Full Name")
                {
                    ApplicationArea = All;
                }
                field("User Security ID"; Rec."User Security ID")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
            }
        }
    }

    procedure LoadSalesOrderAgentCandidates(ItemAgentUserSecurityId: Guid)
    var
        SourceUser: Record User;
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if SourceUser.FindSet() then
            repeat
                if (SourceUser."User Security ID" <> ItemAgentUserSecurityId) and IsSalesOrderAgentName(SourceUser) then begin
                    Rec := SourceUser;
                    Rec.Insert();
                end;
            until SourceUser.Next() = 0;

        if Rec.IsEmpty() then
            Error('The Microsoft Sales Order Agent user could not be found. Open the Agents page, activate Sales Order Agent, and then reopen this lookup.');
    end;

    procedure GetSelectedUser(var SelectedUser: Record User)
    begin
        SelectedUser := Rec;
    end;

    local procedure IsSalesOrderAgentName(SourceUser: Record User): Boolean
    var
        SearchText: Text;
    begin
        SearchText := UpperCase(SourceUser."User Name" + ' ' + SourceUser."Full Name");
        exit(
            (StrPos(SearchText, 'SALES') > 0) and
            (StrPos(SearchText, 'ORDER') > 0) and
            (StrPos(SearchText, 'AGENT') > 0));
    end;
}
