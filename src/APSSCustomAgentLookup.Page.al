namespace APSS.AgentMailbox;

using System.Agents.Designer.CustomAgent;

page 90201 "APSS Custom Agent Lookup"
{
    Caption = 'Select Custom Agent';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Custom Agent Info";
    SourceTableTemporary = true;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Agents)
            {
                field("User Name"; Rec."User Name")
                {
                    ApplicationArea = All;
                    Caption = 'Agent Name';
                }
                field("User Security ID"; Rec."User Security ID")
                {
                    ApplicationArea = All;
                    Caption = 'Agent User Security ID';
                    Visible = false;
                }
            }
        }
    }

    procedure LoadAgents(var SourceAgents: Record "Custom Agent Info" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();
        if SourceAgents.FindSet() then
            repeat
                Rec := SourceAgents;
                Rec.Insert();
            until SourceAgents.Next() = 0;
        Rec.FindFirst();
    end;

    procedure GetSelectedAgent(var SelectedAgent: Record "Custom Agent Info" temporary)
    begin
        SelectedAgent := Rec;
    end;
}
