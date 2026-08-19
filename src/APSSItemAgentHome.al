namespace APSS.AgentMailbox;

page 90213 "APSS Item Agent Home"
{
    PageType = CardPart;
    Caption = 'APSS Item Agent Home';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Guidance; GuidanceText)
            {
                Caption = 'Instructions';
                ApplicationArea = All;
                Editable = false;
                MultiLine = true;
            }
        }
    }

    trigger OnOpenPage()
    begin
        GuidanceText := 'Open Item Requests > APSS Item Request Drafts. Create one draft line for every requested item.';
    end;

    var
        GuidanceText: Text[250];
}
