namespace APSS.AgentMailbox;

using Microsoft.Inventory.Item;

codeunit 90210 "APSS Item Request Mgt."
{
    var
        HandoffFailureCount: Integer;

    procedure ApproveSelected(var ItemRequestDraft: Record "APSS Item Request Draft"): Integer
    var
        ApprovedCount: Integer;
    begin
        if ItemRequestDraft.FindSet(true) then
            repeat
                if ItemRequestDraft.Status in [ItemRequestDraft.Status::Draft, ItemRequestDraft.Status::"Pending Review"] then begin
                    ValidateDraft(ItemRequestDraft);
                    ItemRequestDraft.Status := ItemRequestDraft.Status::Approved;
                    ItemRequestDraft."Reviewed By" := CopyStr(UserId(), 1, MaxStrLen(ItemRequestDraft."Reviewed By"));
                    ItemRequestDraft."Reviewed At" := CurrentDateTime();
                    ItemRequestDraft.Modify(true);
                    ApprovedCount += 1;
                end;
            until ItemRequestDraft.Next() = 0;
        exit(ApprovedCount);
    end;

    procedure RejectSelected(var ItemRequestDraft: Record "APSS Item Request Draft"): Integer
    var
        RejectedCount: Integer;
    begin
        if ItemRequestDraft.FindSet(true) then
            repeat
                if ItemRequestDraft.Status <> ItemRequestDraft.Status::"Item Created" then begin
                    ItemRequestDraft.Status := ItemRequestDraft.Status::Rejected;
                    ItemRequestDraft."Reviewed By" := CopyStr(UserId(), 1, MaxStrLen(ItemRequestDraft."Reviewed By"));
                    ItemRequestDraft."Reviewed At" := CurrentDateTime();
                    ItemRequestDraft.Modify(true);
                    RejectedCount += 1;
                end;
            until ItemRequestDraft.Next() = 0;
        exit(RejectedCount);
    end;

    procedure CreateSelectedItems(var ItemRequestDraft: Record "APSS Item Request Draft"): Integer
    var
        SourceMessageIds: List of [Text[250]];
        SourceMessageId: Text[250];
        CreatedCount: Integer;
    begin
        HandoffFailureCount := 0;
        ValidateSelectedForCreation(ItemRequestDraft);
        if ItemRequestDraft.FindSet(true) then
            repeat
                SourceMessageId := ItemRequestDraft."Source Message ID";
                if not SourceMessageIds.Contains(SourceMessageId) then
                    SourceMessageIds.Add(SourceMessageId);
                CreateItem(ItemRequestDraft);
                CreatedCount += 1;
            until ItemRequestDraft.Next() = 0;

        // Keep successfully created Items even if the separate Sales Agent handoff fails.
        Commit();
        foreach SourceMessageId in SourceMessageIds do
            AttemptAutomaticHandoff(SourceMessageId);

        exit(CreatedCount);
    end;

    procedure GetHandoffFailureCount(): Integer
    begin
        exit(HandoffFailureCount);
    end;

    procedure ActivateSalesAgentForSource(SourceMessageId: Text[250])
    begin
        TryActivateSalesAgent(SourceMessageId, true);
    end;

    procedure LookupBrandCode(var BrandCode: Code[50]): Boolean
    var
        SelectedBrand: Record "APSS Brand Lookup Buffer" temporary;
        BrandLookup: Page "APSS Brand Lookup";
    begin
        BrandLookup.LookupMode(true);
        if BrandLookup.RunModal() <> Action::LookupOK then
            exit(false);
        BrandLookup.GetRecord(SelectedBrand);
        BrandCode := SelectedBrand.Code;
        exit(BrandCode <> '');
    end;

    local procedure ValidateSelectedForCreation(var ItemRequestDraft: Record "APSS Item Request Draft")
    begin
        if ItemRequestDraft.IsEmpty() then
            Error('Select at least one approved item request.');
        if ItemRequestDraft.FindSet() then
            repeat
                ItemRequestDraft.TestField(Status, ItemRequestDraft.Status::Approved);
                ValidateDraft(ItemRequestDraft);
            until ItemRequestDraft.Next() = 0;
    end;

    local procedure ValidateDraft(ItemRequestDraft: Record "APSS Item Request Draft")
    var
        Item: Record Item;
    begin
        ItemRequestDraft.TestField("Source Message ID");
        ItemRequestDraft.TestField("Manufacturer Part No.");
        ItemRequestDraft.TestField("Brand Code");
        ValidateBrandCode(ItemRequestDraft."Brand Code");
        ItemRequestDraft.TestField("Base Unit of Measure");
        ItemRequestDraft.TestField("Inventory Posting Group");
        ItemRequestDraft.TestField("Gen. Prod. Posting Group");
        if ItemRequestDraft."Proposed Item No." <> '' then
            if Item.Get(ItemRequestDraft."Proposed Item No.") then
                Error('Item %1 already exists. Change or clear Proposed Item No. on request entry %2.', ItemRequestDraft."Proposed Item No.", ItemRequestDraft."Entry No.");
    end;

    local procedure CreateItem(var ItemRequestDraft: Record "APSS Item Request Draft")
    var
        Item: Record Item;
    begin
        Item.Init();
        Item."No." := ItemRequestDraft."Proposed Item No.";
        // Assign the valid Brand before Insert so an invalid default Brand
        // (for example AC) cannot block the Item OnInsert processing.
        AssignBrand(Item, ItemRequestDraft."Brand Code");
        Item.Insert(true);

        // The requested short Item Description is the Manufacturer Part No., not the draft long description.
        Item.Validate(Description, CopyStr(ItemRequestDraft."Manufacturer Part No.", 1, MaxStrLen(Item.Description)));
        if ItemRequestDraft."Description 2" <> '' then
            Item.Validate("Description 2", ItemRequestDraft."Description 2");

        Item.Validate("Base Unit of Measure", ItemRequestDraft."Base Unit of Measure");
        Item.Validate("Inventory Posting Group", ItemRequestDraft."Inventory Posting Group");
        Item.Validate("Gen. Prod. Posting Group", ItemRequestDraft."Gen. Prod. Posting Group");
        if ItemRequestDraft."VAT Prod. Posting Group" <> '' then
            Item.Validate("VAT Prod. Posting Group", ItemRequestDraft."VAT Prod. Posting Group");
        if ItemRequestDraft."Item Category Code" <> '' then
            Item.Validate("Item Category Code", ItemRequestDraft."Item Category Code");
        Item.Validate("Costing Method", ItemRequestDraft."Costing Method");
        if ItemRequestDraft."Unit Cost" <> 0 then
            Item.Validate("Unit Cost", ItemRequestDraft."Unit Cost");
        if ItemRequestDraft."Vendor No." <> '' then
            Item.Validate("Vendor No.", ItemRequestDraft."Vendor No.");
        if ItemRequestDraft."Vendor Item No." <> '' then
            Item.Validate("Vendor Item No.", ItemRequestDraft."Vendor Item No.");
        if ItemRequestDraft."Manufacturer Code" <> '' then
            Item.Validate("Manufacturer Code", ItemRequestDraft."Manufacturer Code");

        UnblockItem(Item, ItemRequestDraft."Brand Code");

        ItemRequestDraft.Status := ItemRequestDraft.Status::"Item Created";
        ItemRequestDraft."Created Item No." := Item."No.";
        ItemRequestDraft."Item Created By" := CopyStr(UserId(), 1, MaxStrLen(ItemRequestDraft."Item Created By"));
        ItemRequestDraft."Item Created At" := CurrentDateTime();
        ItemRequestDraft.Modify(true);
    end;

    local procedure AttemptAutomaticHandoff(SourceMessageId: Text[250])
    var
        SourceEmail: Record "APSS Source Email";
    begin
        if not IsSourceReadyForHandoff(SourceMessageId) then
            exit;
        if not SourceEmail.Get(SourceMessageId) then begin
            HandoffFailureCount += 1;
            exit;
        end;

        // A Boolean Codeunit.Run catches and rolls back only the handoff transaction.
        // The Items were committed before this call and therefore remain available.
        if not Codeunit.Run(Codeunit::"APSS Sales Handoff Runner", SourceEmail) then
            HandoffFailureCount += 1;
    end;

    local procedure IsSourceReadyForHandoff(SourceMessageId: Text[250]): Boolean
    var
        Draft: Record "APSS Item Request Draft";
    begin
        Draft.SetRange("Source Message ID", SourceMessageId);
        if Draft.IsEmpty() then
            exit(false);
        Draft.SetFilter(Status, '<>%1', Draft.Status::"Item Created");
        exit(Draft.IsEmpty());
    end;

    local procedure ValidateBrandCode(BrandCode: Text)
    var
        BrandRecordRef: RecordRef;
        BrandPrimaryKeyRef: KeyRef;
        BrandCodeFieldRef: FieldRef;
    begin
        BrandRecordRef.Open(50001);
        BrandPrimaryKeyRef := BrandRecordRef.KeyIndex(1);
        if BrandPrimaryKeyRef.FieldCount() = 0 then
            Error('APSS Item Brand table 50001 does not have a primary-key field.');

        BrandCodeFieldRef := BrandPrimaryKeyRef.FieldIndex(1);
        BrandCodeFieldRef.SetRange(BrandCode);
        if not BrandRecordRef.FindFirst() then
            Error('Brand Code %1 does not exist in APSS Item Brand. Use the lookup on the draft and select an existing Brand Code.', BrandCode);
    end;

    local procedure AssignBrand(var Item: Record Item; BrandCode: Text)
    var
        ItemRef: RecordRef;
        BrandField: FieldRef;
    begin
        if BrandCode = '' then
            Error('Brand Code must be specified for item %1.', Item."No.");

        ItemRef.GetTable(Item);
        // 50001 is the related Brand table number, not the Item field number.
        FindSingleFieldRelatedToTable(ItemRef, 50001, 'APSS Item Brand', BrandField);
        if StrLen(BrandCode) > BrandField.Length() then
            Error('Brand Code %1 exceeds the maximum length of %2 characters allowed by Item field %3.', BrandCode, BrandField.Length(), BrandField.Caption());
        BrandField.Validate(BrandCode);
        ItemRef.SetTable(Item);
    end;

    local procedure UnblockItem(var Item: Record Item; BrandCode: Text)
    begin
        Item.Validate(Blocked, false);
        Item.Validate("Sales Blocked", false);
        Item."Block Reason" := '';
        Item.Modify(true);
        Item.Get(Item."No.");
        if Item.Blocked or Item."Sales Blocked" then
            Error('Item %1 remains blocked after assigning APSS Brand Code %2.', Item."No.", BrandCode);
    end;

    local procedure FindSingleFieldRelatedToTable(var SourceRecordRef: RecordRef; RelatedTableNo: Integer; RelatedTableDescription: Text; var ResultFieldRef: FieldRef)
    var
        CandidateFieldRef: FieldRef;
        FieldIndex: Integer;
        MatchingFieldCount: Integer;
    begin
        for FieldIndex := 1 to SourceRecordRef.FieldCount() do begin
            CandidateFieldRef := SourceRecordRef.FieldIndex(FieldIndex);
            if CandidateFieldRef.Active() and (CandidateFieldRef.Relation() = RelatedTableNo) then begin
                MatchingFieldCount += 1;
                ResultFieldRef := CandidateFieldRef;
            end;
        end;
        if MatchingFieldCount = 0 then
            Error('No field on table %1 has a relationship to %2 table %3.', SourceRecordRef.Caption(), RelatedTableDescription, RelatedTableNo);
        if MatchingFieldCount > 1 then
            Error('More than one field on table %1 is related to %2 table %3. Use Page Inspection to identify the correct Item field number.', SourceRecordRef.Caption(), RelatedTableDescription, RelatedTableNo);
    end;

    local procedure TryActivateSalesAgent(SourceMessageId: Text[250]; RaiseErrorIfNotReady: Boolean)
    var
        Draft: Record "APSS Item Request Draft";
        Setup: Record "APSS Agent Mail Setup";
        SalesAgentHandoff: Codeunit "APSS Sales Agent Handoff";
        ExternalEvents: Codeunit "APSS External Events";
        ConversationId: Text[250];
        EmailSubject: Text[250];
        SalesAgentTaskId: BigInteger;
        HandoffAt: DateTime;
    begin
        if SourceMessageId = '' then
            exit;
        Draft.SetRange("Source Message ID", SourceMessageId);
        if not Draft.FindSet() then
            exit;

        repeat
            if Draft.Status <> Draft.Status::"Item Created" then begin
                if RaiseErrorIfNotReady then
                    Error('All item requests from email %1 must be Item Created before activating the Sales Order Agent.', SourceMessageId);
                exit;
            end;
            if Draft."Sales Agent Task Created" then
                exit;
            if ConversationId = '' then
                ConversationId := Draft."Source Conversation ID";
            if EmailSubject = '' then
                EmailSubject := Draft."Email Subject";
        until Draft.Next() = 0;

        SalesAgentTaskId := SalesAgentHandoff.CreateTask(SourceMessageId);
        HandoffAt := CurrentDateTime();

        if not Setup.Get(1) then
            Error('APSS Agent Mailbox Setup has not been configured.');
        if Setup."Raise Ready Business Event" then
            ExternalEvents.EmailReadyForSales(Setup."Email Address", SourceMessageId, ConversationId, EmailSubject);

        Draft.Reset();
        Draft.SetRange("Source Message ID", SourceMessageId);
        Draft.ModifyAll("Sales Agent Task Created", true);
        Draft.ModifyAll("Sales Agent Task ID", SalesAgentTaskId);
        Draft.ModifyAll("Sales Agent Task Created At", HandoffAt);
        if Setup."Raise Ready Business Event" then begin
            Draft.ModifyAll("Ready Event Raised", true);
            Draft.ModifyAll("Ready Event Raised At", HandoffAt);
        end;
    end;
}
