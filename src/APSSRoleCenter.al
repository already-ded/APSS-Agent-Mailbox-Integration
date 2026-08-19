namespace APSS.AgentMailbox;

page 90212 "APSS Item Agent Role Center"
{
    PageType = RoleCenter;
    Caption = 'APSS Item Agent';
    ApplicationArea = All;

    layout
    {
        area(RoleCenter)
        {
            part(AgentHome; "APSS Item Agent Home")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Sections)
        {
            group(ItemRequests)
            {
                Caption = 'Item Requests';

                action(ItemRequestDrafts)
                {
                    Caption = 'APSS Item Request Drafts';
                    ApplicationArea = All;
                    RunObject = page "APSS Item Request Drafts";
                }
            }
        }
    }
}
