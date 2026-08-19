namespace APSS.AgentMailbox;

page 90214 "APSS Brand Lookup"
{
    Caption = 'Select APSS Brand';
    PageType = List;
    SourceTable = "APSS Brand Lookup Buffer";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Brands)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        RefreshBrands();
    end;

    local procedure RefreshBrands()
    var
        BrandRecordRef: RecordRef;
        BrandPrimaryKeyRef: KeyRef;
        BrandCodeFieldRef: FieldRef;
        BrandDescriptionFieldRef: FieldRef;
        HasDescription: Boolean;
    begin
        Rec.Reset();
        Rec.LockTable();
        Rec.DeleteAll();

        BrandRecordRef.Open(50001);
        BrandPrimaryKeyRef := BrandRecordRef.KeyIndex(1);
        if BrandPrimaryKeyRef.FieldCount() = 0 then
            Error('APSS Item Brand table 50001 does not have a primary-key field.');

        BrandCodeFieldRef := BrandPrimaryKeyRef.FieldIndex(1);
        HasDescription := FindFieldByNameOrCaption(BrandRecordRef, 'Description', BrandDescriptionFieldRef);

        if BrandRecordRef.FindSet() then
            repeat
                Rec.Init();
                Rec.Code := CopyStr(Format(BrandCodeFieldRef.Value()), 1, MaxStrLen(Rec.Code));
                if HasDescription then
                    Rec.Description := CopyStr(Format(BrandDescriptionFieldRef.Value()), 1, MaxStrLen(Rec.Description));
                if Rec.Code <> '' then
                    Rec.Insert();
            until BrandRecordRef.Next() = 0;

        if Rec.IsEmpty() then
            Error('APSS Item Brand table 50001 does not contain any Brand Codes.');
        Rec.FindFirst();
    end;

    local procedure FindFieldByNameOrCaption(var SourceRecordRef: RecordRef; ExpectedNameOrCaption: Text; var ResultFieldRef: FieldRef): Boolean
    var
        CandidateFieldRef: FieldRef;
        FieldIndex: Integer;
    begin
        for FieldIndex := 1 to SourceRecordRef.FieldCount() do begin
            CandidateFieldRef := SourceRecordRef.FieldIndex(FieldIndex);
            if CandidateFieldRef.Active() then
                if (CandidateFieldRef.Name() = ExpectedNameOrCaption) or (CandidateFieldRef.Caption() = ExpectedNameOrCaption) then begin
                    ResultFieldRef := CandidateFieldRef;
                    exit(true);
                end;
        end;
        exit(false);
    end;
}
