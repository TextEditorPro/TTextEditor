unit TextEditor.Highlighter.Import.JSON;

interface

uses
  System.Classes, System.JSON, System.SysUtils, TextEditor, TextEditor.CodeFolding.Regions, TextEditor.Highlighter,
  TextEditor.Highlighter.Attributes, TextEditor.Highlighter.Colors, TextEditor.Highlighter.Rules, TextEditor.SkipRegions;

type
  TTextEditorHighlighterImportJSON = class(TObject)
  strict private
    FHighlighter: TTextEditorHighlighter;
    procedure ImportAttributes(const AHighlighterAttribute: TTextEditorHighlighterAttribute; const AAttributesObject: TJSONObject;
      const AElementPrefix: string);
    procedure ImportCodeFolding(const ACodeFoldingObject: TJSONObject);
    procedure ImportCodeFoldingFoldRegion(const ACodeFoldingRegion: TTextEditorCodeFoldingRegion; const ACodeFoldingObject: TJSONObject);
    procedure ImportCodeFoldingSkipRegion(const ACodeFoldingRegion: TTextEditorCodeFoldingRegion; const ACodeFoldingObject: TJSONObject);
    procedure ImportCodeFoldingVoidElements(const ACodeFoldingObject: TJSONObject);
    procedure ImportColorTheme(const AThemeObject: TJSONObject);
    procedure ImportCompletionProposal(const ACompletionProposalObject: TJSONObject);
    procedure ImportEditorProperties(const AEditorObject: TJSONObject);
    procedure ImportHighlighter(const AJSONObject: TJSONObject);
    procedure ImportHighlightLine(const AHighlightLineObject: TJSONObject);
    procedure ImportKeyList(const AKeyList: TTextEditorKeyList; const AKeyListObject: TJSONObject; const AElementPrefix: string);
    procedure ImportKeywordImages(const AKeywordImagesObject: TJSONObject);
    procedure ImportMatchingPair(const AMatchingPairObject: TJSONObject);
    procedure ImportRange(const ARange: TTextEditorRange; const ARangeObject: TJSONObject; const AParentRange: TTextEditorRange = nil;
      const ASkipBeforeSubRules: Boolean = False; const AElementPrefix: string = '');
    procedure ImportSample(const AHighlighterObject: TJSONObject);
    procedure ImportSet(const ASet: TTextEditorSet; const ASetObject: TJSONObject; const AElementPrefix: string);
  public
    constructor Create(const AHighlighter: TTextEditorHighlighter); overload;
    procedure ImportFromStream(const AStream: TStream);
    procedure ImportColorsFromStream(const AStream: TStream);
  end;

  EJSONImportException = class(Exception);

implementation

uses
  System.TypInfo, System.UITypes, Vcl.Graphics, TextEditor.Consts, TextEditor.Highlighter.Token, TextEditor.HighlightLine,
  TextEditor.JSON.Helper, TextEditor.Language, TextEditor.Types;

function StrToFontStyle(const AString: string): TFontStyles;
begin
  Result := [];

  if Pos(TFontStyleNames.Bold, AString) > 0 then
    Include(Result, fsBold);

  if Pos(TFontStyleNames.Italic, AString) > 0 then
    Include(Result, fsItalic);

  if Pos(TFontStyleNames.Underline, AString) > 0 then
    Include(Result, fsUnderline);

  if Pos(TFontStyleNames.StrikeOut, AString) > 0 then
    Include(Result, fsStrikeOut);
end;

function StrToBreakType(const AString: string): TTextEditorBreakType;
begin
  if AString = TBreakType.Any then
    Result := btAny
  else
  if (AString = TBreakType.Term) or AString.IsEmpty then
    Result := btTerm
  else
    Result := btUnspecified;
end;

function StrToRegionType(const AString: string): TTextEditorSkipRegionItemType;
begin
  if AString = TRegionType.SingleLine then
    Result := ritSingleLineComment
  else
  if AString = TRegionType.MultiLine then
    Result := ritMultiLineComment
  else
  if AString = TRegionType.SingleLineString then
    Result := ritSingleLineString
  else
    Result := ritMultiLineString;
end;

function StrToRangeType(const AString: string): TTextEditorRangeType;
var
  LIndex: Integer;
begin
  LIndex := GetEnumValue(TypeInfo(TTextEditorRangeType), 'tt' + AString);

  Result := if LIndex = -1 then ttUnspecified else TTextEditorRangeType(LIndex);
end;

{ TTextEditorHighlighterImportJSON }

constructor TTextEditorHighlighterImportJSON.Create(const AHighlighter: TTextEditorHighlighter);
begin
  inherited Create;

  FHighlighter := AHighlighter;
end;

procedure TTextEditorHighlighterImportJSON.ImportSample(const AHighlighterObject: TJSONObject);
var
  LHighlighter: TTextEditorHighlighter;
  LSampleArray: TJSONArray;
begin
  if Assigned(AHighlighterObject) and Assigned(FHighlighter.Editor) then
  begin
    LHighlighter := TCustomTextEditor(FHighlighter.Editor).Highlighter;
    LSampleArray := AHighlighterObject.ValueArray['Sample'];

    LHighlighter.Sample := '';

    for var LIndex := 0 to LSampleArray.Count - 1 do
      LHighlighter.Sample := LHighlighter.Sample + LSampleArray.ValueString[LIndex];
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportEditorProperties(const AEditorObject: TJSONObject);
var
  LEditor: TCustomTextEditor;
begin
  if Assigned(AEditorObject) and Assigned(FHighlighter.Editor) then
  begin
    LEditor := FHighlighter.Editor as TCustomTextEditor;

    LEditor.URIOpener := AEditorObject.ValueBoolean['URIOpener'];

    with LEditor.CodeFolding do
    begin
      Outlining := AEditorObject.ValueBoolean['Outlining'];
      TextFolding.Active := LEditor.CodeFolding.Outlining or AEditorObject.ValueBoolean['TextFolding'];
    end;
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportColorTheme(const AThemeObject: TJSONObject);
var
  LEditor: TCustomTextEditor;
  LColorsObject: TJSONObject;
  LFontsObject: TJSONObject;
  LFontSizesObject: TJSONObject;
  LStylesArray: TJSONArray;
  LItemObject: TJSONObject;
  LElementName: string;
  LFontStyle: TFontStyles;
begin
  if Assigned(AThemeObject) and Assigned(FHighlighter.Editor) then
  begin
    LEditor := FHighlighter.Editor as TCustomTextEditor;

    if (csDesigning in LEditor.ComponentState) or (eoLoadColors in LEditor.Options) then
    begin
      LColorsObject := AThemeObject.ValueObject['Colors'];

      if Assigned(LColorsObject) then
      with LEditor.Colors do
      begin
        ActiveLineBackground := LColorsObject.ValueColor['ActiveLineBackground'];
        ActiveLineBackgroundUnfocused := LColorsObject.ValueColor['ActiveLineBackgroundUnfocused'];
        ActiveLineBorder := LColorsObject.ValueColor['ActiveLineBorder'];
        ActiveLineForeground := LColorsObject.ValueColor['ActiveLineForeground'];
        ActiveLineForegroundUnfocused := LColorsObject.ValueColor['ActiveLineForegroundUnfocused'];
        BookmarkBlue := LColorsObject.ValueColor['BookmarkBlue'];
        BookmarkGreen := LColorsObject.ValueColor['BookmarkGreen'];
        BookmarkPurple := LColorsObject.ValueColor['BookmarkPurple'];
        BookmarkRed := LColorsObject.ValueColor['BookmarkRed'];
        BookmarkYellow := LColorsObject.ValueColor['BookmarkYellow'];
        CaretMultiEditBackground := LColorsObject.ValueColor['CaretMultiEditBackground'];
        CaretMultiEditForeground := LColorsObject.ValueColor['CaretMultiEditForeground'];
        CodeFoldingActiveLineBackground := LColorsObject.ValueColor['CodeFoldingActiveLineBackground'];
        CodeFoldingActiveLineBackgroundUnfocused := LColorsObject.ValueColor['CodeFoldingActiveLineBackgroundUnfocused'];
        CodeFoldingBackground := LColorsObject.ValueColor['CodeFoldingBackground'];
        CodeFoldingCollapsedLine := LColorsObject.ValueColor['CodeFoldingCollapsedLine'];
        CodeFoldingFoldingLine := LColorsObject.ValueColor['CodeFoldingFoldingLine'];
        CodeFoldingFoldingLineHighlight := LColorsObject.ValueColor['CodeFoldingFoldingLineHighlight'];
        CodeFoldingHintBackground := LColorsObject.ValueColor['CodeFoldingHintBackground'];
        CodeFoldingHintBorder := LColorsObject.ValueColor['CodeFoldingHintBorder'];
        CodeFoldingHintIndicatorBackground := LColorsObject.ValueColor['CodeFoldingHintIndicatorBackground'];
        CodeFoldingHintIndicatorBorder := LColorsObject.ValueColor['CodeFoldingHintIndicatorBorder'];
        CodeFoldingHintIndicatorMark := LColorsObject.ValueColor['CodeFoldingHintIndicatorMark'];
        CodeFoldingHintText := LColorsObject.ValueColor['CodeFoldingHintText'];
        CodeFoldingIndent := LColorsObject.ValueColor['CodeFoldingIndent'];
        CodeFoldingIndentHighlight := LColorsObject.ValueColor['CodeFoldingIndentHighlight'];
        CompareBackground := LColorsObject.ValueColor['CompareBackground'];
        CompareForeground := LColorsObject.ValueColor['CompareForeground'];
        CompletionProposalBackground := LColorsObject.ValueColor['CompletionProposalBackground'];
        CompletionProposalBorder := LColorsObject.ValueColor['CompletionProposalBorder'];
        CompletionProposalForeground := LColorsObject.ValueColor['CompletionProposalForeground'];
        CompletionProposalSelectedBackground := LColorsObject.ValueColor['CompletionProposalSelectedBackground'];
        CompletionProposalSelectedText := LColorsObject.ValueColor['CompletionProposalSelectedText'];
        EditorAssemblerCommentBackground := LColorsObject.ValueColor['EditorAssemblerCommentBackground'];
        EditorAssemblerCommentForeground := LColorsObject.ValueColor['EditorAssemblerCommentForeground'];
        EditorAssemblerReservedWordBackground := LColorsObject.ValueColor['EditorAssemblerReservedWordBackground'];
        EditorAssemblerReservedWordForeground := LColorsObject.ValueColor['EditorAssemblerReservedWordForeground'];
        EditorAttributeBackground := LColorsObject.ValueColor['EditorAttributeBackground'];
        EditorAttributeForeground := LColorsObject.ValueColor['EditorAttributeForeground'];
        EditorBackground := LColorsObject.ValueColor['EditorBackground'];
        EditorCharacterBackground := LColorsObject.ValueColor['EditorCharacterBackground'];
        EditorCharacterForeground := LColorsObject.ValueColor['EditorCharacterForeground'];
        EditorCommentBackground := LColorsObject.ValueColor['EditorCommentBackground'];
        EditorCommentForeground := LColorsObject.ValueColor['EditorCommentForeground'];
        EditorDirectiveBackground := LColorsObject.ValueColor['EditorDirectiveBackground'];
        EditorDirectiveForeground := LColorsObject.ValueColor['EditorDirectiveForeground'];
        EditorForeground := LColorsObject.ValueColor['EditorForeground'];
        EditorHexNumberBackground := LColorsObject.ValueColor['EditorHexNumberBackground'];
        EditorHexNumberForeground := LColorsObject.ValueColor['EditorHexNumberForeground'];
        EditorHighlightedBlockBackground := LColorsObject.ValueColor['EditorHighlightedBlockBackground'];
        EditorHighlightedBlockForeground := LColorsObject.ValueColor['EditorHighlightedBlockForeground'];
        EditorHighlightedBlockSymbolBackground := LColorsObject.ValueColor['EditorHighlightedBlockSymbolBackground'];
        EditorHighlightedBlockSymbolForeground := LColorsObject.ValueColor['EditorHighlightedBlockSymbolForeground'];
        EditorLogicalOperatorBackground := LColorsObject.ValueColor['EditorLogicalOperatorBackground'];
        EditorLogicalOperatorForeground := LColorsObject.ValueColor['EditorLogicalOperatorForeground'];
        EditorMethodBackground := LColorsObject.ValueColor['EditorMethodBackground'];
        EditorMethodForeground := LColorsObject.ValueColor['EditorMethodForeground'];
        EditorMethodItalicBackground := LColorsObject.ValueColor['EditorMethodItalicBackground'];
        EditorMethodItalicForeground := LColorsObject.ValueColor['EditorMethodItalicForeground'];
        EditorMethodNameBackground := LColorsObject.ValueColor['EditorMethodNameBackground'];
        EditorMethodNameForeground := LColorsObject.ValueColor['EditorMethodNameForeground'];
        EditorNumberBackground := LColorsObject.ValueColor['EditorNumberBackground'];
        EditorNumberForeground := LColorsObject.ValueColor['EditorNumberForeground'];
        EditorReservedWordBackground := LColorsObject.ValueColor['EditorReservedWordBackground'];
        EditorReservedWordForeground := LColorsObject.ValueColor['EditorReservedWordForeground'];
        EditorStringBackground := LColorsObject.ValueColor['EditorStringBackground'];
        EditorStringForeground := LColorsObject.ValueColor['EditorStringForeground'];
        EditorSymbolBackground := LColorsObject.ValueColor['EditorSymbolBackground'];
        EditorSymbolForeground := LColorsObject.ValueColor['EditorSymbolForeground'];
        EditorValueBackground := LColorsObject.ValueColor['EditorValueBackground'];
        EditorValueForeground := LColorsObject.ValueColor['EditorValueForeground'];
        EditorWebLinkBackground := LColorsObject.ValueColor['EditorWebLinkBackground'];
        EditorWebLinkForeground := LColorsObject.ValueColor['EditorWebLinkForeground'];
        HintBackground := LColorsObject.ValueColor['HintBackground'];
        HintBorder := LColorsObject.ValueColor['HintBorder'];
        HintText := LColorsObject.ValueColor['HintText'];
        KeywordImageArrowDown := LColorsObject.ValueColor['KeywordImageArrowDown'];
        KeywordImageArrowUp := LColorsObject.ValueColor['KeywordImageArrowUp'];
        LeftMarginActiveLineBackground := LColorsObject.ValueColor['LeftMarginActiveLineBackground'];
        LeftMarginActiveLineBackgroundUnfocused := LColorsObject.ValueColor['LeftMarginActiveLineBackgroundUnfocused'];
        LeftMarginActiveLineNumber := LColorsObject.ValueColor['LeftMarginActiveLineNumber'];
        LeftMarginBackground := LColorsObject.ValueColor['LeftMarginBackground'];
        LeftMarginBookmarkPanelBackground := LColorsObject.ValueColor['LeftMarginBookmarkPanelBackground'];
        LeftMarginBorder := LColorsObject.ValueColor['LeftMarginBorder'];
        LeftMarginLineNumberLine := LColorsObject.ValueColor['LeftMarginLineNumberLine'];
        LeftMarginLineNumbers := LColorsObject.ValueColor['LeftMarginLineNumbers'];
        LeftMarginLineStateModified := LColorsObject.ValueColor['LeftMarginLineStateModified'];
        LeftMarginLineStateNormal := LColorsObject.ValueColor['LeftMarginLineStateNormal'];
        MatchingPairMatched := LColorsObject.ValueColor['MatchingPairMatched'];
        MatchingPairUnderline := LColorsObject.ValueColor['MatchingPairUnderline'];
        MatchingPairUnmatched := LColorsObject.ValueColor['MatchingPairUnmatched'];
        MinimapBackground := LColorsObject.ValueColor['MinimapBackground'];
        MinimapBookmark := LColorsObject.ValueColor['MinimapBookmark'];
        MinimapVisibleRows := LColorsObject.ValueColor['MinimapVisibleRows'];
        RightMargin := LColorsObject.ValueColor['RightMargin'];
        RightMovingEdge := LColorsObject.ValueColor['RightMovingEdge'];
        RulerBackground := LColorsObject.ValueColor['RulerBackground'];
        RulerBorder := LColorsObject.ValueColor['RulerBorder'];
        RulerLines := LColorsObject.ValueColor['RulerLines'];
        RulerMovingEdge := LColorsObject.ValueColor['RulerMovingEdge'];
        RulerNumbers := LColorsObject.ValueColor['RulerNumbers'];
        RulerSelection := LColorsObject.ValueColor['RulerSelection'];
        SearchHighlighterBackground := LColorsObject.ValueColor['SearchHighlighterBackground'];
        SearchHighlighterBorder := LColorsObject.ValueColor['SearchHighlighterBorder'];
        SearchHighlighterForeground := LColorsObject.ValueColor['SearchHighlighterForeground'];
        SearchInSelectionBackground := LColorsObject.ValueColor['SearchInSelectionBackground'];
        SearchMapActiveLine := LColorsObject.ValueColor['SearchMapActiveLine'];
        SearchMapBackground := LColorsObject.ValueColor['SearchMapBackground'];
        SearchMapForeground := LColorsObject.ValueColor['SearchMapForeground'];
        SelectionBackground := LColorsObject.ValueColor['SelectionBackground'];
        SelectionBackgroundUnfocused := LColorsObject.ValueColor['SelectionBackgroundUnfocused'];
        SelectionForeground := LColorsObject.ValueColor['SelectionForeground'];
        SelectionForegroundUnfocused := LColorsObject.ValueColor['SelectionForegroundUnfocused'];
        SyncEditBackground := LColorsObject.ValueColor['SyncEditBackground'];
        SyncEditEditBorder := LColorsObject.ValueColor['SyncEditEditBorder'];
        SyncEditWordBorder := LColorsObject.ValueColor['SyncEditWordBorder'];
        WordWrapIndicatorArrow := LColorsObject.ValueColor['WordWrapIndicatorArrow'];
        WordWrapIndicatorLines := LColorsObject.ValueColor['WordWrapIndicatorLines'];
      end;

      LEditor.UpdateColors;
    end;

    if (csDesigning in LEditor.ComponentState) or (eoLoadFontNames in LEditor.Options) then
    begin
      LFontsObject := AThemeObject.ValueObject['Fonts'];

      if Assigned(LFontsObject) then
      with LEditor.Fonts do
      begin
        CodeFoldingHint.Name := LFontsObject.ValueStringDef('CodeFoldingHint', CodeFoldingHint.Name);
        CompletionProposal.Name := LFontsObject.ValueStringDef('CompletionProposal', CompletionProposal.Name);
        Hint.Name := LFontsObject.ValueStringDef('Hint', Hint.Name);
        LineNumbers.Name := LFontsObject.ValueStringDef('LineNumbers', LineNumbers.Name);
        Minimap.Name := LFontsObject.ValueStringDef('Minimap', Minimap.Name);
        Ruler.Name := LFontsObject.ValueStringDef('Ruler', Ruler.Name);
        Text.Name := LFontsObject.ValueStringDef('Text', Text.Name);
      end;
    end;

    if (csDesigning in LEditor.ComponentState) or (eoLoadFontSizes in LEditor.Options) then
    begin
      LFontSizesObject := AThemeObject.ValueObject['FontSizes'];

      if Assigned(LFontSizesObject) then
      with LEditor.Fonts do
      begin
        CodeFoldingHint.Size := LFontSizesObject.ValueIntegerDef('CodeFoldingHint', CodeFoldingHint.Size);
        CompletionProposal.Size := LFontSizesObject.ValueIntegerDef('CompletionProposal', CompletionProposal.Size);
        Hint.Size := LFontSizesObject.ValueIntegerDef('Hint', Hint.Size);
        LineNumbers.Size := LFontSizesObject.ValueIntegerDef('LineNumbers', LineNumbers.Size);
        Minimap.Size := LFontSizesObject.ValueIntegerDef('Minimap', Minimap.Size);
        Ruler.Size := LFontSizesObject.ValueIntegerDef('Ruler', Ruler.Size);
        Text.Size := LFontSizesObject.ValueIntegerDef('Text', Text.Size);
      end;
    end;

    if (csDesigning in LEditor.ComponentState) or (eoLoadFontStyles in LEditor.Options) then
    begin
      LStylesArray := AThemeObject.ValueArray['Styles'];

      with LEditor.FontStyles do
      begin
        Clear;

        for var LIndex := 0 to LStylesArray.Count - 1 do
        begin
          LItemObject := LStylesArray.ValueObject[LIndex];
          LElementName := LItemObject.ValueString['Name'];
          LFontStyle := StrToFontStyle(LItemObject.ValueString['Style']);

          if LElementName = TElement.MethodItalic then
            MethodItalic := LFontStyle
          else
          if LElementName = TElement.ReservedWord then
            ReservedWord := LFontStyle
          else
          if LElementName = TElement.AssemblerReservedWord then
            AssemblerReservedWord := LFontStyle
          else
          if LElementName = TElement.Value then
            Value := LFontStyle
          else
          if LElementName = TElement.Comment then
            Comment := LFontStyle
          else
          if LElementName = TElement.Method then
            Method := LFontStyle
          else
          if LElementName = TElement.AssemblerComment then
            AssemblerComment := LFontStyle
          else
          if LElementName = TElement.LogicalOperator then
            LogicalOperator := LFontStyle
          else
          if LElementName = TElement.Directive then
            Directive := LFontStyle
          else
          if LElementName = TElement.Attribute then
            Attribute := LFontStyle
          else
          if LElementName = TElement.Character then
            Character := LFontStyle
          else
          if LElementName = TElement.HexNumber then
            HexNumber := LFontStyle
          else
          if LElementName = TElement.HighlightedBlock then
            HighlightedBlock := LFontStyle
          else
          if LElementName = TElement.HighlightedBlockSymbol then
            HighlightedBlockSymbol := LFontStyle
          else
          if LElementName = TElement.NameOfMethod then
            NameOfMethod := LFontStyle
          else
          if LElementName = TElement.Number then
            Number := LFontStyle
          else
          if LElementName = TElement.StringOfCharacters then
            StringOfCharacters := LFontStyle
          else
          if LElementName = TElement.Symbol then
            Symbol := LFontStyle
          else
          if LElementName = TElement.WebLink then
            WebLink := LFontStyle
          else
          if LElementName = TElement.Editor then
            Editor := LFontStyle;
        end;
      end;
    end;
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportAttributes(const AHighlighterAttribute: TTextEditorHighlighterAttribute;
  const AAttributesObject: TJSONObject; const AElementPrefix: string);
begin
  if Assigned(AAttributesObject) then
  with AHighlighterAttribute do
  begin
    Element := AElementPrefix + AAttributesObject.ValueString['Element'];
    ParentForeground := AAttributesObject.ValueBoolean['ParentForeground'];
    ParentBackground := AAttributesObject.ValueBoolean['ParentBackground'];

    if AAttributesObject.Contains('EscapeChar') then
      EscapeChar := AAttributesObject.ValueString['EscapeChar'][1];
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportKeyList(const AKeyList: TTextEditorKeyList; const AKeyListObject: TJSONObject;
  const AElementPrefix: string);
var
  LWordArray: TJSONArray;
begin
  if Assigned(AKeyListObject) then
  begin
    AKeyList.TokenType := StrToRangeType(AKeyListObject.ValueString['Type']);

    LWordArray := AKeyListObject.ValueArray['Words'];

    for var LIndex := 0 to LWordArray.Count - 1 do
      AKeyList.KeyList.Add(LWordArray.ValueString[LIndex]);

    ImportAttributes(AKeyList.Attribute, AKeyListObject.ValueObject['Attributes'], AElementPrefix);
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportSet(const ASet: TTextEditorSet; const ASetObject: TJSONObject;
  const AElementPrefix: string);
begin
  if Assigned(ASetObject) then
  begin
    ASet.CharSet := ASetObject.ValueCharSet['Symbols'];
    ImportAttributes(ASet.Attribute, ASetObject.ValueObject['Attributes'], AElementPrefix);
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportRange(const ARange: TTextEditorRange; const ARangeObject: TJSONObject;
  const AParentRange: TTextEditorRange = nil; const ASkipBeforeSubRules: Boolean = False;
  const AElementPrefix: string = ''); { Recursive method }
var
  LName: string;
  LElementPrefix: string;
  LEditor: TCustomTextEditor;
  LFileStream: TStream;
  LJSONObject: TJSONObject;
  LTokenRangeObject: TJSONObject;
  LSubRulesObject: TJSONObject;
  LJSONSubRulesObject: TJSONObject;
  LArrayValue: TJSONArray;
  LPropertiesObject: TJSONObject;
  LOpenToken, LCloseToken: string;
  LNewRange: TTextEditorRange;
  LNewKeyList: TTextEditorKeyList;
  LNewSet: TTextEditorSet;
begin
  if Assigned(ARangeObject) then
  begin
    LName := ARangeObject.ValueString['File'];

    if (hoMultiHighlighter in FHighlighter.Options) and not LName.IsEmpty then
    begin
      LElementPrefix := ARangeObject.ValueString['ElementPrefix'];
      LEditor := FHighlighter.Editor as TCustomTextEditor;
      LFileStream := LEditor.CreateHighlighterStream(LName);

      if Assigned(LFileStream) then
      begin
        LJSONObject := TJSONObject.ParseFromStream(LFileStream);

        if Assigned(LJSONObject) then
        try
          LTokenRangeObject := LJSONObject.ValueObject['Highlighter'].ValueObject['MainRules'];

          { You can include MainRules... }
          if LTokenRangeObject.ValueString['Name'] = ARangeObject.ValueString['IncludeRange'] then
            ImportRange(AParentRange, LTokenRangeObject, nil, True, LElementPrefix)
          else
          { or SubRules... }
          begin
            LSubRulesObject := LTokenRangeObject.ValueObject['SubRules'];

            if Assigned(LSubRulesObject) then
            for var LPair in LSubRulesObject do
            begin
              if LPair.JsonString.Value = 'Range' then
              begin
                LArrayValue := LPair.JsonValue as TJSONArray;

                for var LIndex2 := 0 to LArrayValue.Count - 1 do
                begin
                  LJSONSubRulesObject := LArrayValue.ValueObject[LIndex2];

                  if LJSONSubRulesObject.ValueString['Name'] = ARangeObject.ValueString['IncludeRange'] then
                  begin
                    ImportRange(ARange, LJSONSubRulesObject, nil, False, LElementPrefix);
                    Break;
                  end;
                end;
              end;
            end;
          end;
        finally
          LJSONObject.Free;
          LFileStream.Free;
        end;
      end;
    end
    else
    begin
      if not ASkipBeforeSubRules then
      begin
        ARange.Clear;
        ARange.CaseSensitive := ARangeObject.ValueBoolean['CaseSensitive'];
        ImportAttributes(ARange.Attribute, ARangeObject.ValueObject['Attributes'], AElementPrefix);

        if not ARangeObject.ValueString['AllowedCharacters'].IsEmpty then
          ARange.AllowedCharacters := ARangeObject.ValueCharSet['AllowedCharacters'];

        if not ARangeObject.ValueString['Delimiters'].IsEmpty then
          ARange.Delimiters := ARangeObject.ValueCharSet['Delimiters'];

        ARange.TokenType := StrToRangeType(ARangeObject.ValueString['Type']);
        ARange.Nested := FHighlighter.NestedComments and (ARange.TokenType = ttBlockComment);

        LPropertiesObject := ARangeObject.ValueObject['Properties'];

        if Assigned(LPropertiesObject) then
        begin
          if ARange = FHighlighter.MainRules then
            FHighlighter.NestedComments := LPropertiesObject.ValueBoolean['NestedComments'];

          if LPropertiesObject.Contains('Nested') then
            ARange.Nested := LPropertiesObject.ValueBoolean['Nested'];

          with ARange do
          begin
            CloseOnAnyTerm := LPropertiesObject.ValueBoolean['CloseOnAnyTerm'];
            CloseOnEndOfLine := LPropertiesObject.ValueBoolean['CloseOnEndOfLine'];
            CloseOnTerm := LPropertiesObject.ValueBoolean['CloseOnTerm'];
            CloseParent := LPropertiesObject.ValueBoolean['CloseParent'];
            HereDocument := LPropertiesObject.ValueBoolean['HereDocument'];
            HighlightMethodCalls := LPropertiesObject.ValueBoolean['HighlightMethodCalls'];
            OpenBeginningOfLine := LPropertiesObject.ValueBoolean['OpenBeginningOfLine'];
            OpenEndOfLine := LPropertiesObject.ValueBoolean['OpenEndOfLine'];
            SkipWhitespace := LPropertiesObject.ValueBoolean['SkipWhitespace'];
            SkipWhitespaceOnce := LPropertiesObject.ValueBoolean['SkipWhitespaceOnce'];
            UseDelimitersForText := LPropertiesObject.ValueBoolean['UseDelimitersForText'];
          end;

          LArrayValue := LPropertiesObject.ValueArray['AlternativeClose'];

          if LArrayValue.Count > 0 then
          begin
            ARange.AlternativeCloseArrayCount := LArrayValue.Count;

            for var LIndex := 0 to ARange.AlternativeCloseArrayCount - 1 do
              ARange.AlternativeCloseArray[LIndex] := LArrayValue.ValueString[LIndex];
          end;
        end;

        with ARange do
        begin
          OpenToken.Clear;
          OpenToken.BreakType := btUnspecified;
          CloseToken.Clear;
          CloseToken.BreakType := btUnspecified;
        end;

        LTokenRangeObject := ARangeObject.ValueObject['TokenRange'];

        if Assigned(LTokenRangeObject) then
        begin
          LOpenToken := LTokenRangeObject.ValueString['Open'];
          LCloseToken := LTokenRangeObject.ValueString['Close'];

          ARange.AddTokenRange(LOpenToken, StrToBreakType(LTokenRangeObject.ValueString['OpenBreakType']), LCloseToken,
            StrToBreakType(LTokenRangeObject.ValueString['CloseBreakType']));

          case ARange.TokenType of
            ttLineComment: FHighlighter.Comments.AddLineComment(LOpenToken);
            ttBlockComment: FHighlighter.Comments.AddBlockComment(LOpenToken, LCloseToken);
          end;
        end;
      end;
      { Sub rules }
      LSubRulesObject := ARangeObject.ValueObject['SubRules'];

      if Assigned(LSubRulesObject) then
      for var LPair in LSubRulesObject do
      begin
        LName := LPair.JsonString.Value;
        LArrayValue := LPair.JsonValue as TJSONArray;

        if LName = 'Range' then
        for var LIndex2 := 0 to LArrayValue.Count - 1 do
        begin
          LNewRange := TTextEditorRange.Create;
          ImportRange(LNewRange, LArrayValue.ValueObject[LIndex2], ARange); { ARange is for the MainRules include }
          ARange.AddRange(LNewRange);
        end
        else
        if LName = 'KeyList' then
        for var LIndex2 := 0 to LArrayValue.Count - 1 do
        begin
          LNewKeyList := TTextEditorKeyList.Create;
          ImportKeyList(LNewKeyList, LArrayValue.ValueObject[LIndex2], AElementPrefix);
          ARange.AddKeyList(LNewKeyList);
        end
        else
        if LName = 'Set' then
        for var LIndex2 := 0 to LArrayValue.Count - 1 do
        begin
          LNewSet := TTextEditorSet.Create;
          ImportSet(LNewSet, LArrayValue.ValueObject[LIndex2], AElementPrefix);
          ARange.AddSet(LNewSet);
        end;
      end;
    end;
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportCompletionProposal(const ACompletionProposalObject: TJSONObject);
var
  LSkipRegionArray: TJSONArray;
  LItemObject: TJSONObject;
  LName: string;
  LEditor: TCustomTextEditor;
  LFileStream: TStream;
  LJSONObject: TJSONObject;
  LSkipRegionItem: TTextEditorSkipRegionItem;
begin
  if not Assigned(ACompletionProposalObject) then
    Exit;

  LSkipRegionArray := ACompletionProposalObject.ValueArray['SkipRegion'];

  for var LIndex := 0 to LSkipRegionArray.Count - 1 do
  begin
    LItemObject := LSkipRegionArray.ValueObject[LIndex];

    if hoMultiHighlighter in FHighlighter.Options then
    begin
      LName := LItemObject.ValueString['File'];

      if not LName.IsEmpty then
      begin
        LEditor := FHighlighter.Editor as TCustomTextEditor;
        LFileStream := LEditor.CreateHighlighterStream(LName);

        if Assigned(LFileStream) then
        try
          LJSONObject := TJSONObject.ParseFromStream(LFileStream);

          if Assigned(LJSONObject) then
          try
            if LJSONObject.Contains('CompletionProposal') then
              ImportCompletionProposal(LJSONObject.ValueObject['CompletionProposal']);
          finally
            LJSONObject.Free;
          end;
        finally
          LFileStream.Free;
        end;
      end;

      if FHighlighter.CompletionProposalSkipRegions.Contains(LItemObject.ValueString['OpenToken'],
        LItemObject.ValueString['CloseToken']) then
        Continue;
    end;

    LSkipRegionItem := FHighlighter.CompletionProposalSkipRegions.Add(LItemObject.ValueString['OpenToken'],
      LItemObject.ValueString['CloseToken']);
    LSkipRegionItem.RegionType := StrToRegionType(LItemObject.ValueString['RegionType']);
    LSkipRegionItem.SkipEmptyChars := LItemObject.ValueBoolean['SkipEmptyChars'];
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportCodeFoldingVoidElements(const ACodeFoldingObject: TJSONObject);
var
  LVoidElementArray: TJSONArray;
  LVoidElement: string;
begin
  if ACodeFoldingObject.Contains('VoidElements') then
  begin
    FHighlighter.CreateCodeFoldingVoidElements;
    FHighlighter.CodeFoldingVoidElements.BeginUpdate;
    try
      LVoidElementArray := ACodeFoldingObject.ValueArray['VoidElements'];

      for var LIndex := 0 to LVoidElementArray.Count - 1 do
      begin
        LVoidElement := LVoidElementArray.ValueString[LIndex];

        if FHighlighter.CodeFoldingVoidElements.IndexOf(LVoidElement) = -1 then
          FHighlighter.CodeFoldingVoidElements.Add(LVoidElement);
      end;
    finally
      FHighlighter.CodeFoldingVoidElements.EndUpdate;
    end;
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportCodeFoldingSkipRegion(const ACodeFoldingRegion: TTextEditorCodeFoldingRegion;
  const ACodeFoldingObject: TJSONObject);
var
  LOpenToken, LCloseToken: string;
  LSkipRegionArray: TJSONArray;
  LItemObject: TJSONObject;
  LName: string;
  LEditor: TCustomTextEditor;
  LFileStream: TStream;
  LJSONObject: TJSONObject;
  LSkipRegionType: TTextEditorSkipRegionItemType;
  LRegionItem: TTextEditorCodeFoldingRegionItem;
  LSkipRegionItem: TTextEditorSkipRegionItem;
begin
  if ACodeFoldingObject.Contains('SkipRegion') then
  begin
    LSkipRegionArray := ACodeFoldingObject.ValueArray['SkipRegion'];

    for var LIndex := 0 to LSkipRegionArray.Count - 1 do
    begin
      LItemObject := LSkipRegionArray.ValueObject[LIndex];

      LOpenToken := LItemObject.ValueString['OpenToken'];
      LCloseToken := LItemObject.ValueString['CloseToken'];

      if hoMultiHighlighter in FHighlighter.Options then
      begin
        LName := LItemObject.ValueString['File'];

        if not LName.IsEmpty then
        begin
          LEditor := FHighlighter.Editor as TCustomTextEditor;
          LFileStream := LEditor.CreateHighlighterStream(LName);

          if Assigned(LFileStream) then
          try
            LJSONObject := TJSONObject.ParseFromStream(LFileStream);

            if Assigned(LJSONObject) then
            try
              if LJSONObject.Contains('CodeFolding') then
                ImportCodeFoldingSkipRegion(ACodeFoldingRegion,
                  LJSONObject.ValueObject['CodeFolding'].ValueArray['Ranges'].ValueObject[0]);
            finally
              LJSONObject.Free;
            end
          finally
            LFileStream.Free;
          end;
        end;

        if ACodeFoldingRegion.SkipRegions.Contains(LOpenToken, LCloseToken) then
          Continue;
      end;

      LSkipRegionType := StrToRegionType(LItemObject.ValueString['RegionType']);

      if (LSkipRegionType = ritMultiLineComment) and (cfoFoldMultilineComments in TCustomTextEditor(FHighlighter.Editor).CodeFolding.Options) then
      begin
        LRegionItem := ACodeFoldingRegion.Add(LOpenToken, LCloseToken);

        LRegionItem.NoSubs := True;
        FHighlighter.AddKeyChar(ctFoldOpen, LOpenToken[1]);

        if not LCloseToken.IsEmpty then
          FHighlighter.AddKeyChar(ctFoldClose, LCloseToken[1]);
      end
      else
      begin
        LSkipRegionItem := ACodeFoldingRegion.SkipRegions.Add(LOpenToken, LCloseToken);

        with LSkipRegionItem do
        begin
          RegionType := LSkipRegionType;
          SkipEmptyChars := LItemObject.ValueBoolean['SkipEmptyChars'];
          SkipIfNextCharIsNot := TControlCharacters.Null;

          if LItemObject.Contains('NextCharIsNot') then
            SkipIfNextCharIsNot := LItemObject.ValueString['NextCharIsNot'][1];

          Nested := FHighlighter.NestedComments and (LSkipRegionType = ritMultiLineComment);

          if LItemObject.Contains('Nested') then
            Nested := LItemObject.ValueBoolean['Nested'];
        end;

        if not LOpenToken.IsEmpty then
          FHighlighter.AddKeyChar(ctSkipOpen, LOpenToken[1]);

        if not LCloseToken.IsEmpty then
          FHighlighter.AddKeyChar(ctSkipClose, LCloseToken[1]);
      end;
    end;
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportCodeFoldingFoldRegion(const ACodeFoldingRegion: TTextEditorCodeFoldingRegion;
  const ACodeFoldingObject: TJSONObject);
var
  LOpenToken, LCloseToken, LAlternativeCloseToken: string;
  LFoldRegionArray: TJSONArray;
  LItemObject: TJSONObject;
  LName: string;
  LEditor: TCustomTextEditor;
  LFileStream: TStream;
  LJSONObject: TJSONObject;
  LRegionItem: TTextEditorCodeFoldingRegionItem;
  LMemberObject: TJSONObject;
  LSkipIfFoundAfterOpenTokenArray: TJSONArray;
begin
  if ACodeFoldingObject.Contains('FoldRegion') then
  begin
    FHighlighter.IsSharedCloseFound := False;

    LFoldRegionArray := ACodeFoldingObject.ValueArray['FoldRegion'];

    for var LIndex := 0 to LFoldRegionArray.Count - 1 do
    begin
      LItemObject := LFoldRegionArray.ValueObject[LIndex];
      LOpenToken := LItemObject.ValueString['OpenToken'];
      LCloseToken := LItemObject.ValueString['CloseToken'];
      LAlternativeCloseToken := LItemObject.ValueString['AlternativeCloseToken'];

      if hoMultiHighlighter in FHighlighter.Options then
      begin
        LName := LItemObject.ValueString['File'];

        if not LName.IsEmpty then
        begin
          LEditor := FHighlighter.Editor as TCustomTextEditor;
          LFileStream := LEditor.CreateHighlighterStream(LName);

          if Assigned(LFileStream) then
          try
            LJSONObject := TJSONObject.ParseFromStream(LFileStream);

            if Assigned(LJSONObject) then
            try
              if LJSONObject.Contains('CodeFolding') then
                ImportCodeFoldingFoldRegion(ACodeFoldingRegion,
                  LJSONObject.ValueObject['CodeFolding'].ValueArray['Ranges'].ValueObject[0]);
            finally
              LJSONObject.Free;
            end
          finally
            LFileStream.Free;
          end;
        end;

        if ACodeFoldingRegion.Contains(LOpenToken) then
          Continue;
      end;

      LRegionItem := ACodeFoldingRegion.Add(LOpenToken, LCloseToken, LAlternativeCloseToken);
      LMemberObject := LItemObject.ValueObject['Properties'];

      if Assigned(LMemberObject) then
      with LRegionItem do
      begin
        { Options }
        SingleInstance := LMemberObject.ValueBoolean['SingleInstance'];
        OpenTokenBeginningOfLine := LMemberObject.ValueBoolean['OpenTokenBeginningOfLine'];
        CloseTokenBeginningOfLine := LMemberObject.ValueBoolean['CloseTokenBeginningOfLine'];
        SharedClose := LMemberObject.ValueBoolean['SharedClose'];

        if SharedClose then
          FHighlighter.IsSharedCloseFound := True;

        OpenIsClose := LMemberObject.ValueBoolean['OpenIsClose'];
        OpenTokenCanBeFollowedBy := LMemberObject.ValueString['OpenTokenCanBeFollowedBy'];
        TokenEndIsPreviousLine := LMemberObject.ValueBoolean['TokenEndIsPreviousLine'];
        NoSubs := LMemberObject.ValueBoolean['NoSubs'];
        BeginWithBreakChar := LMemberObject.ValueBoolean['BeginWithBreakChar'];
        LSkipIfFoundAfterOpenTokenArray := LMemberObject.ValueArray['SkipIfFoundAfterOpenToken'];

        if LSkipIfFoundAfterOpenTokenArray.Count > 0 then
        begin
          SkipIfFoundAfterOpenTokenArrayCount := LSkipIfFoundAfterOpenTokenArray.Count;

          for var LIndex2 := 0 to SkipIfFoundAfterOpenTokenArrayCount - 1 do
            SkipIfFoundAfterOpenTokenArray[LIndex2] := LSkipIfFoundAfterOpenTokenArray.ValueString[LIndex2];
        end;

        if LMemberObject.Contains('BreakCharFollows') then
          BreakCharFollows := LMemberObject.ValueBoolean['BreakCharFollows'];

        BreakIfNotFoundBeforeNextRegion := LMemberObject.ValueString['BreakIfNotFoundBeforeNextRegion'];
        OpenTokenEnd := LMemberObject.ValueString['OpenTokenEnd'];
        ShowGuideLine := LMemberObject.ValueBooleanDef('ShowGuideLine', True);
        OpenTokenBreaksLine := LMemberObject.ValueBoolean['OpenTokenBreaksLine'];
        RemoveRange := LMemberObject.ValueBoolean['RemoveRange'];
        CheckIfThenOneLiner := LMemberObject.ValueBoolean['CheckIfThenOneLiner'];
      end;

      if not LOpenToken.IsEmpty then
        FHighlighter.AddKeyChar(ctFoldOpen, LOpenToken[1]);

      if not LRegionItem.BreakIfNotFoundBeforeNextRegion.IsEmpty then
        FHighlighter.AddKeyChar(ctFoldOpen, LRegionItem.BreakIfNotFoundBeforeNextRegion[1]);

      if not LCloseToken.IsEmpty then
        FHighlighter.AddKeyChar(ctFoldClose, LCloseToken[1]);
    end;
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportCodeFolding(const ACodeFoldingObject: TJSONObject);
var
  LArray: TJSONArray;
  LCount: Integer;
  LHideGuideLineAtFirstColumn: Boolean;
  LVisible: Boolean;
  LRangeCount: Integer;
  LEscapeChar: Char;
  LStringEscapeChar: Char;
  LCodeFoldingObject, LObject: TJSONObject;
  LRegionIndex: Integer;
  LCodeFoldingRegion: TTextEditorCodeFoldingRegion;
  LEditor: TCustomTextEditor;
begin
  if not Assigned(ACodeFoldingObject) then
    Exit;

  LArray := ACodeFoldingObject.ValueArray['Ranges'];
  LCount := LArray.Count;
  LHideGuideLineAtFirstColumn := False;
  LVisible := True;

  if LCount > 0 then
  begin
    LRangeCount := 0;
    LEscapeChar := TControlCharacters.Null;
    LStringEscapeChar := TControlCharacters.Null;

    for var LIndex := 0 to LCount - 1 do
    begin
      LCodeFoldingObject := LArray.ValueObject[LIndex];

      if LCodeFoldingObject.Contains('Options') then
      begin
        LObject := LCodeFoldingObject.ValueObject['Options'];

        if LObject.Contains('BythonPreprocessor') then
        begin
          FHighlighter.BythonPreprocessor := LObject.ValueBoolean['BythonPreprocessor'];
          LVisible := FHighlighter.BythonPreprocessor;
        end;

        if LObject.Contains('EscapeChar') then
          LEscapeChar := LObject.ValueString['EscapeChar'][1];

        if LObject.Contains('StringEscapeChar') then
          LStringEscapeChar := LObject.ValueString['StringEscapeChar'][1];

        if LObject.Contains('FoldTags') and LObject.ValueBoolean['FoldTags'] then
          FHighlighter.FoldTags := True;

        if LObject.Contains('MatchingPairHighlight') and not LObject.ValueBoolean['MatchingPairHighlight'] then
          FHighlighter.MatchingPairHighlight := False;

        if LObject.Contains('HideGuideLineAtFirstColumn') and LObject.ValueBoolean['HideGuideLineAtFirstColumn'] then
          LHideGuideLineAtFirstColumn := True;
      end;

      if LCodeFoldingObject.Contains('FoldRegion') or LCodeFoldingObject.Contains('SkipRegion') then
        Inc(LRangeCount);
    end;

    FHighlighter.CodeFoldingRangeCount := LRangeCount;

    LRegionIndex := 0;

    for var LIndex := 0 to LCount - 1 do
    begin
      LCodeFoldingObject := LArray.ValueObject[LIndex];

      ImportCodeFoldingVoidElements(LCodeFoldingObject);

      if LCodeFoldingObject.Contains('FoldRegion') or LCodeFoldingObject.Contains('SkipRegion') then
      begin
        LCodeFoldingRegion := TTextEditorCodeFoldingRegion.Create(TTextEditorCodeFoldingRegionItem);
        LCodeFoldingRegion.EscapeChar := LEscapeChar;
        LCodeFoldingRegion.StringEscapeChar := LStringEscapeChar;
        FHighlighter.CodeFoldingRegions[LRegionIndex] := LCodeFoldingRegion;
        Inc(LRegionIndex);

        ImportCodeFoldingSkipRegion(LCodeFoldingRegion, LCodeFoldingObject);
        ImportCodeFoldingFoldRegion(LCodeFoldingRegion, LCodeFoldingObject);
      end;
    end;
  end;

  LEditor := FHighlighter.Editor as TCustomTextEditor;

  LEditor.CodeFolding.Visible := LVisible and (LCount > 0);
  LEditor.CodeFolding.GuideLines.SetOption(cfgHideAtFirstColumn, LHideGuideLineAtFirstColumn);
end;

procedure TTextEditorHighlighterImportJSON.ImportKeywordImages(const AKeywordImagesObject: TJSONObject);
var
  LArray: TJSONArray;
  LItemObject: TJSONObject;
  LKeyword, LImageName: string;
  LKind: TTextEditorKeywordImageKind;
begin
  if not Assigned(AKeywordImagesObject) then
    Exit;

  LArray := AKeywordImagesObject.ValueArray['Items'];

  for var LIndex := 0 to LArray.Count - 1 do
  begin
    LItemObject := LArray.ValueObject[LIndex];

    LKeyword := LItemObject.ValueString['Word'];
    LImageName := LItemObject.ValueString['Image'];

    if LKeyword.IsEmpty then
      Continue;

    if SameText(LImageName, 'ArrowUp') then
      LKind := kikArrowUp
    else
    if SameText(LImageName, 'ArrowDown') then
      LKind := kikArrowDown
    else
      Continue;

    FHighlighter.KeywordImages.AddOrSetValue(
      if FHighlighter.MainRules.CaseSensitive then LKeyword else AnsiLowerCase(LKeyword), LKind);
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportMatchingPair(const AMatchingPairObject: TJSONObject);
var
  LArray: TJSONArray;
  LItemObject: TJSONObject;
  LName: string;
  LEditor: TCustomTextEditor;
  LFileStream: TStream;
  LJSONObject: TJSONObject;
  LTokenMatch: PTextEditorMatchingPairToken;
begin
  if not Assigned(AMatchingPairObject) then
    Exit;

  LArray := AMatchingPairObject.ValueArray['Pairs'];

  for var LIndex := 0 to LArray.Count - 1 do
  begin
    LItemObject := LArray.ValueObject[LIndex];

    if hoMultiHighlighter in FHighlighter.Options then
    begin
      LName := LItemObject.ValueString['File'];

      if not LName.IsEmpty then
      begin
        LEditor := FHighlighter.Editor as TCustomTextEditor;
        LFileStream := LEditor.CreateHighlighterStream(LName);

        if Assigned(LFileStream) then
        try
          LJSONObject := TJSONObject.ParseFromStream(LFileStream);

          if Assigned(LJSONObject) then
          try
            if LJSONObject.Contains('MatchingPair') then
              ImportMatchingPair(LJSONObject.ValueObject['MatchingPair']);
          finally
            LJSONObject.Free;
          end
        finally
          LFileStream.Free;
        end;
      end;
    end;

    New(LTokenMatch);

    LTokenMatch.OpenToken := LItemObject.ValueString['OpenToken'];
    LTokenMatch.CloseToken := LItemObject.ValueString['CloseToken'];

    FHighlighter.MatchingPairs.Add(LTokenMatch);
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportHighlighter(const AJSONObject: TJSONObject);
var
  LHighlighterObject: TJSONObject;
begin
  FHighlighter.Clear;

  LHighlighterObject := AJSONObject.ValueObject['Highlighter'];

  FHighlighter.SetOption(hoMultiHighlighter, LHighlighterObject.ValueBoolean['MultiHighlighter']);
  FHighlighter.ExcludedWordBreakCharacters := LHighlighterObject.ValueCharSet['ExcludedWordBreakCharacters'];
  FHighlighter.BeforePrepare := if LHighlighterObject.ValueBoolean['YAML'] then FHighlighter.PrepareYAMLHighlighter else nil;

  ImportSample(LHighlighterObject);
  ImportEditorProperties(LHighlighterObject.ValueObject['Editor']);
  ImportRange(FHighlighter.MainRules, LHighlighterObject.ValueObject['MainRules']);
  ImportCodeFolding(AJSONObject.ValueObject['CodeFolding']);
  ImportKeywordImages(AJSONObject.ValueObject['KeywordImages']);
  ImportMatchingPair(AJSONObject.ValueObject['MatchingPair']);
  ImportCompletionProposal(AJSONObject.ValueObject['CompletionProposal']);

  FHighlighter.Colors.AddElements;

  ImportHighlightLine(AJSONObject.ValueObject['HighlightLine']);
end;

procedure TTextEditorHighlighterImportJSON.ImportHighlightLine(const AHighlightLineObject: TJSONObject);
var
  LArray: TJSONArray;
  LItemObject: TJSONObject;
  LName: string;
  LEditor: TCustomTextEditor;
  LFileStream: TStream;
  LJSONObject: TJSONObject;
  LItem: TTextEditorHighlightLineItem;
  LElement: string;
begin
  if not Assigned(AHighlightLineObject) then
    Exit;

  LArray := AHighlightLineObject.ValueArray['Items'];

  for var LIndex := 0 to LArray.Count - 1 do
  begin
    LItemObject := LArray.ValueObject[LIndex];

    if hoMultiHighlighter in FHighlighter.Options then
    begin
      LName := LItemObject.ValueString['File'];

      if not LName.IsEmpty then
      begin
        LEditor := FHighlighter.Editor as TCustomTextEditor;
        LFileStream := LEditor.CreateHighlighterStream(LName);

        if Assigned(LFileStream) then
        try
          LJSONObject := TJSONObject.ParseFromStream(LFileStream);

          if Assigned(LJSONObject) then
          try
            if LJSONObject.Contains('HighlightLine') then
              ImportMatchingPair(LJSONObject.ValueObject['HighlightLine']);
          finally
            LJSONObject.Free;
          end
        finally
          LFileStream.Free;
        end;
      end;
    end;

    LEditor := FHighlighter.Editor as TCustomTextEditor;

    LEditor.HighlightLine.Active := True;

    LItem := LEditor.HighlightLine.Items.Add;

    LItem.Imported := True;
    LItem.Background := LItemObject.ValueColor['BackgroundColor'];
    LItem.Foreground := LItemObject.ValueColor['ForegroundColor'];

    { Currently only Method and MethodName elements supported for Makefile highlighter.
      Add more element support, if needed. }
    LElement := LItemObject.ValueString['Element'];

    if not LElement.IsEmpty then
    begin
      if LElement = TElement.Method then
      begin
        LItem.Background := LEditor.Colors.EditorMethodBackground;
        LItem.Foreground := LEditor.Colors.EditorMethodForeground;
      end
      else
      if LElement = TElement.NameOfMethod then
      begin
        LItem.Background := LEditor.Colors.EditorMethodNameBackground;
        LItem.Foreground := LEditor.Colors.EditorMethodNameForeground;
      end;
    end;

    if LItemObject.ValueBoolean['IgnoreCase'] then
      LItem.Options := LItem.Options + [hlIgnoreCase];

    if LItemObject.ValueBoolean['Multiline'] then
      LItem.Options := LItem.Options + [hlMultiline];

    LItem.Pattern := LItemObject.ValueString['Pattern'];
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportFromStream(const AStream: TStream);
var
  LJSONObject: TJSONObject;
begin
  try
    LJSONObject := TJSONObject.ParseFromStream(AStream);

    if Assigned(LJSONObject) then
    try
      ImportHighlighter(LJSONObject);
    finally
      LJSONObject.Free;
    end;
  except
    on E: EJSONParseException do
      raise EJSONImportException.Create(Format(STextEditorErrorInHighlighterParse, [E.Line, E.Position, E.Message]));
    on E: Exception do
      raise EJSONImportException.Create(Format(STextEditorErrorInHighlighterImport, [E.Message]));
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportColorsFromStream(const AStream: TStream);
var
  LJSONObject: TJSONObject;
begin
  try
    LJSONObject := TJSONObject.ParseFromStream(AStream);

    if Assigned(LJSONObject) then
    try
      ImportColorTheme(LJSONObject.ValueObject['Theme']);
    finally
      LJSONObject.Free;
    end;
  except
    on E: EJSONParseException do
      raise EJSONImportException.Create(Format(STextEditorErrorInHighlighterParse, [E.Line, E.Position, E.Message]));
    on E: Exception do
      raise EJSONImportException.Create(Format(STextEditorErrorInHighlighterImport, [E.Message]));
  end;
end;

end.
