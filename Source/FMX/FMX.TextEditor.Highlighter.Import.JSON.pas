unit FMX.TextEditor.Highlighter.Import.JSON;

{$I FMX.TextEditor.Defines.inc}

interface

uses
  System.Classes, System.SysUtils, FMX.TextEditor, FMX.TextEditor.CodeFolding.Regions, FMX.TextEditor.Highlighter,
  FMX.TextEditor.Highlighter.Attributes, FMX.TextEditor.Highlighter.Colors, FMX.TextEditor.Highlighter.Rules,
  FMX.TextEditor.JSONDataObjects, FMX.TextEditor.SkipRegions;

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
    procedure ImportHighlightLine(const AHighlightLineObject: TJSONObject);
    procedure ImportHighlighter(const AJSONObject: TJSONObject);
    procedure ImportKeyList(const AKeyList: TTextEditorKeyList; const AKeyListObject: TJSONObject; const AElementPrefix: string);
    procedure ImportKeywordImages(const AKeywordImagesObject: TJSONObject);
    procedure ImportMatchingPair(const AMatchingPairObject: TJSONObject);
    procedure ImportRange(const ARange: TTextEditorRange; const ARangeObject: TJSONObject; const AParentRange: TTextEditorRange = nil;
      const ASkipBeforeSubRules: Boolean = False; const AElementPrefix: string = '');
    procedure ImportSample(const AHighlighterObject: TJSONObject);
    procedure ImportSet(const ASet: TTextEditorSet; const ASetObject: TJSONObject; const AElementPrefix: string);
  public
    constructor Create(const AHighlighter: TTextEditorHighlighter); overload;
    procedure ImportColorsFromStream(const AStream: TStream);
    procedure ImportFromStream(const AStream: TStream);
  end;

  EJSONImportException = class(Exception);

implementation

uses
  System.TypInfo, System.UITypes, FMX.Graphics, FMX.TextEditor.Consts, FMX.TextEditor.Highlighter.Token, FMX.TextEditor.HighlightLine,
  FMX.TextEditor.Language, FMX.TextEditor.Types;

function TextEditorFontFamily(const AFont: TFont): string;
begin
  Result := AFont.Family;
end;

procedure SetTextEditorFontFamily(const AFont: TFont; const AFamily: string);
begin
  AFont.Family := AFamily;
end;

function TextEditorFontSize(const AFont: TFont): Single;
begin
  Result := AFont.Size;
end;

procedure SetTextEditorFontSize(const AFont: TFont; const ASize: Single);
begin
{$IFDEF TEXT_EDITOR_FMX_FONT_POINTS_TO_DIPS}
  AFont.Size := ASize * 96 / 72;
{$ELSE}
  AFont.Size := ASize;
{$ENDIF}
end;

function StrToFontStyle(const AString: string): TFontStyles;
begin
  Result := [];

  if Pos(TFontStyleNames.Bold, AString) > 0 then
    Include(Result, TFontStyle.fsBold);

  if Pos(TFontStyleNames.Italic, AString) > 0 then
    Include(Result, TFontStyle.fsItalic);

  if Pos(TFontStyleNames.Underline, AString) > 0 then
    Include(Result, TFontStyle.fsUnderline);

  if Pos(TFontStyleNames.StrikeOut, AString) > 0 then
    Include(Result, TFontStyle.fsStrikeOut);
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

    LEditor.URIOpener := StrToBoolDef(AEditorObject['URIOpener'].Value, False);

    with LEditor.CodeFolding do
    begin
      Outlining := StrToBoolDef(AEditorObject['Outlining'].Value, False);
      TextFolding.Active := LEditor.CodeFolding.Outlining or StrToBoolDef(AEditorObject['TextFolding'].Value, False);
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
  LJSONDataValue: PJSONDataValue;
  LElementName: string;
  LFontStyle: TFontStyles;
begin
  if Assigned(AThemeObject) and Assigned(FHighlighter.Editor) then
  begin
    LEditor := FHighlighter.Editor as TCustomTextEditor;

    if (csDesigning in LEditor.ComponentState) or (eoLoadColors in LEditor.Options) then
    begin
      LColorsObject := AThemeObject['Colors'].ObjectValue;

      if Assigned(LColorsObject) then
      with LEditor.Colors do
      begin
        ActiveLineBackground := LColorsObject['ActiveLineBackground'].ToAlphaColor;
        ActiveLineBackgroundUnfocused := LColorsObject['ActiveLineBackgroundUnfocused'].ToAlphaColor;
        ActiveLineBorder := LColorsObject['ActiveLineBorder'].ToAlphaColor;
        ActiveLineForeground := LColorsObject['ActiveLineForeground'].ToAlphaColor;
        ActiveLineForegroundUnfocused := LColorsObject['ActiveLineForegroundUnfocused'].ToAlphaColor;
        BookmarkBlue := LColorsObject['BookmarkBlue'].ToAlphaColor;
        BookmarkGreen := LColorsObject['BookmarkGreen'].ToAlphaColor;
        BookmarkPurple := LColorsObject['BookmarkPurple'].ToAlphaColor;
        BookmarkRed := LColorsObject['BookmarkRed'].ToAlphaColor;
        BookmarkYellow := LColorsObject['BookmarkYellow'].ToAlphaColor;
        CaretMultiEditBackground := LColorsObject['CaretMultiEditBackground'].ToAlphaColor;
        CaretMultiEditForeground := LColorsObject['CaretMultiEditForeground'].ToAlphaColor;
        CodeFoldingActiveLineBackground := LColorsObject['CodeFoldingActiveLineBackground'].ToAlphaColor;
        CodeFoldingActiveLineBackgroundUnfocused := LColorsObject['CodeFoldingActiveLineBackgroundUnfocused'].ToAlphaColor;
        CodeFoldingBackground := LColorsObject['CodeFoldingBackground'].ToAlphaColor;
        CodeFoldingCollapsedLine := LColorsObject['CodeFoldingCollapsedLine'].ToAlphaColor;
        CodeFoldingFoldingLine := LColorsObject['CodeFoldingFoldingLine'].ToAlphaColor;
        CodeFoldingFoldingLineHighlight := LColorsObject['CodeFoldingFoldingLineHighlight'].ToAlphaColor;
        CodeFoldingHintBackground := LColorsObject['CodeFoldingHintBackground'].ToAlphaColor;
        CodeFoldingHintBorder := LColorsObject['CodeFoldingHintBorder'].ToAlphaColor;
        CodeFoldingHintIndicatorBackground := LColorsObject['CodeFoldingHintIndicatorBackground'].ToAlphaColor;
        CodeFoldingHintIndicatorBorder := LColorsObject['CodeFoldingHintIndicatorBorder'].ToAlphaColor;
        CodeFoldingHintIndicatorMark := LColorsObject['CodeFoldingHintIndicatorMark'].ToAlphaColor;
        CodeFoldingHintText := LColorsObject['CodeFoldingHintText'].ToAlphaColor;
        CodeFoldingIndent := LColorsObject['CodeFoldingIndent'].ToAlphaColor;
        CodeFoldingIndentHighlight := LColorsObject['CodeFoldingIndentHighlight'].ToAlphaColor;
        CompareBackground := LColorsObject['CompareBackground'].ToAlphaColor;
        CompareForeground := LColorsObject['CompareForeground'].ToAlphaColor;
        CompletionProposalBackground := LColorsObject['CompletionProposalBackground'].ToAlphaColor;
        CompletionProposalBorder := LColorsObject['CompletionProposalBorder'].ToAlphaColor;
        CompletionProposalForeground := LColorsObject['CompletionProposalForeground'].ToAlphaColor;
        CompletionProposalSelectedBackground := LColorsObject['CompletionProposalSelectedBackground'].ToAlphaColor;
        CompletionProposalSelectedText := LColorsObject['CompletionProposalSelectedText'].ToAlphaColor;
        EditorAssemblerCommentBackground := LColorsObject['EditorAssemblerCommentBackground'].ToAlphaColor;
        EditorAssemblerCommentForeground := LColorsObject['EditorAssemblerCommentForeground'].ToAlphaColor;
        EditorAssemblerReservedWordBackground := LColorsObject['EditorAssemblerReservedWordBackground'].ToAlphaColor;
        EditorAssemblerReservedWordForeground := LColorsObject['EditorAssemblerReservedWordForeground'].ToAlphaColor;
        EditorAttributeBackground := LColorsObject['EditorAttributeBackground'].ToAlphaColor;
        EditorAttributeForeground := LColorsObject['EditorAttributeForeground'].ToAlphaColor;
        EditorBackground := LColorsObject['EditorBackground'].ToAlphaColor;
        EditorCharacterBackground := LColorsObject['EditorCharacterBackground'].ToAlphaColor;
        EditorCharacterForeground := LColorsObject['EditorCharacterForeground'].ToAlphaColor;
        EditorCommentBackground := LColorsObject['EditorCommentBackground'].ToAlphaColor;
        EditorCommentForeground := LColorsObject['EditorCommentForeground'].ToAlphaColor;
        EditorDirectiveBackground := LColorsObject['EditorDirectiveBackground'].ToAlphaColor;
        EditorDirectiveForeground := LColorsObject['EditorDirectiveForeground'].ToAlphaColor;
        EditorForeground := LColorsObject['EditorForeground'].ToAlphaColor;
        EditorHexNumberBackground := LColorsObject['EditorHexNumberBackground'].ToAlphaColor;
        EditorHexNumberForeground := LColorsObject['EditorHexNumberForeground'].ToAlphaColor;
        EditorHighlightedBlockBackground := LColorsObject['EditorHighlightedBlockBackground'].ToAlphaColor;
        EditorHighlightedBlockForeground := LColorsObject['EditorHighlightedBlockForeground'].ToAlphaColor;
        EditorHighlightedBlockSymbolBackground := LColorsObject['EditorHighlightedBlockSymbolBackground'].ToAlphaColor;
        EditorHighlightedBlockSymbolForeground := LColorsObject['EditorHighlightedBlockSymbolForeground'].ToAlphaColor;
        EditorLogicalOperatorBackground := LColorsObject['EditorLogicalOperatorBackground'].ToAlphaColor;
        EditorLogicalOperatorForeground := LColorsObject['EditorLogicalOperatorForeground'].ToAlphaColor;
        EditorMethodBackground := LColorsObject['EditorMethodBackground'].ToAlphaColor;
        EditorMethodForeground := LColorsObject['EditorMethodForeground'].ToAlphaColor;
        EditorMethodItalicBackground := LColorsObject['EditorMethodItalicBackground'].ToAlphaColor;
        EditorMethodItalicForeground := LColorsObject['EditorMethodItalicForeground'].ToAlphaColor;
        EditorMethodNameBackground := LColorsObject['EditorMethodNameBackground'].ToAlphaColor;
        EditorMethodNameForeground := LColorsObject['EditorMethodNameForeground'].ToAlphaColor;
        EditorNumberBackground := LColorsObject['EditorNumberBackground'].ToAlphaColor;
        EditorNumberForeground := LColorsObject['EditorNumberForeground'].ToAlphaColor;
        EditorReservedWordBackground := LColorsObject['EditorReservedWordBackground'].ToAlphaColor;
        EditorReservedWordForeground := LColorsObject['EditorReservedWordForeground'].ToAlphaColor;
        EditorStringBackground := LColorsObject['EditorStringBackground'].ToAlphaColor;
        EditorStringForeground := LColorsObject['EditorStringForeground'].ToAlphaColor;
        EditorSymbolBackground := LColorsObject['EditorSymbolBackground'].ToAlphaColor;
        EditorSymbolForeground := LColorsObject['EditorSymbolForeground'].ToAlphaColor;
        EditorValueBackground := LColorsObject['EditorValueBackground'].ToAlphaColor;
        EditorValueForeground := LColorsObject['EditorValueForeground'].ToAlphaColor;
        EditorWebLinkBackground := LColorsObject['EditorWebLinkBackground'].ToAlphaColor;
        EditorWebLinkForeground := LColorsObject['EditorWebLinkForeground'].ToAlphaColor;
        HintBackground := LColorsObject['HintBackground'].ToAlphaColor;
        HintBorder := LColorsObject['HintBorder'].ToAlphaColor;
        HintText := LColorsObject['HintText'].ToAlphaColor;
        KeywordImageArrowDown := LColorsObject['KeywordImageArrowDown'].ToAlphaColor;
        KeywordImageArrowUp := LColorsObject['KeywordImageArrowUp'].ToAlphaColor;
        LeftMarginActiveLineBackground := LColorsObject['LeftMarginActiveLineBackground'].ToAlphaColor;
        LeftMarginActiveLineBackgroundUnfocused := LColorsObject['LeftMarginActiveLineBackgroundUnfocused'].ToAlphaColor;
        LeftMarginActiveLineNumber := LColorsObject['LeftMarginActiveLineNumber'].ToAlphaColor;
        LeftMarginBackground := LColorsObject['LeftMarginBackground'].ToAlphaColor;
        LeftMarginBookmarkPanelBackground := LColorsObject['LeftMarginBookmarkPanelBackground'].ToAlphaColor;
        LeftMarginBorder := LColorsObject['LeftMarginBorder'].ToAlphaColor;
        LeftMarginLineNumberLine := LColorsObject['LeftMarginLineNumberLine'].ToAlphaColor;
        LeftMarginLineNumbers := LColorsObject['LeftMarginLineNumbers'].ToAlphaColor;
        LeftMarginLineStateModified := LColorsObject['LeftMarginLineStateModified'].ToAlphaColor;
        LeftMarginLineStateNormal := LColorsObject['LeftMarginLineStateNormal'].ToAlphaColor;
        MatchingPairMatched := LColorsObject['MatchingPairMatched'].ToAlphaColor;
        MatchingPairUnderline := LColorsObject['MatchingPairUnderline'].ToAlphaColor;
        MatchingPairUnmatched := LColorsObject['MatchingPairUnmatched'].ToAlphaColor;
        MinimapBackground := LColorsObject['MinimapBackground'].ToAlphaColor;
        MinimapBookmark := LColorsObject['MinimapBookmark'].ToAlphaColor;
        MinimapVisibleRows := LColorsObject['MinimapVisibleRows'].ToAlphaColor;
        RightMargin := LColorsObject['RightMargin'].ToAlphaColor;
        RightMovingEdge := LColorsObject['RightMovingEdge'].ToAlphaColor;
        RulerBackground := LColorsObject['RulerBackground'].ToAlphaColor;
        RulerBorder := LColorsObject['RulerBorder'].ToAlphaColor;
        RulerLines := LColorsObject['RulerLines'].ToAlphaColor;
        RulerMovingEdge := LColorsObject['RulerMovingEdge'].ToAlphaColor;
        RulerNumbers := LColorsObject['RulerNumbers'].ToAlphaColor;
        RulerSelection := LColorsObject['RulerSelection'].ToAlphaColor;
        SearchHighlighterBackground := LColorsObject['SearchHighlighterBackground'].ToAlphaColor;
        SearchHighlighterBorder := LColorsObject['SearchHighlighterBorder'].ToAlphaColor;
        SearchHighlighterForeground := LColorsObject['SearchHighlighterForeground'].ToAlphaColor;
        SearchInSelectionBackground := LColorsObject['SearchInSelectionBackground'].ToAlphaColor;
        SearchMapActiveLine := LColorsObject['SearchMapActiveLine'].ToAlphaColor;
        SearchMapBackground := LColorsObject['SearchMapBackground'].ToAlphaColor;
        SearchMapForeground := LColorsObject['SearchMapForeground'].ToAlphaColor;
        SelectionBackground := LColorsObject['SelectionBackground'].ToAlphaColor;
        SelectionBackgroundUnfocused := LColorsObject['SelectionBackgroundUnfocused'].ToAlphaColor;
        SelectionForeground := LColorsObject['SelectionForeground'].ToAlphaColor;
        SelectionForegroundUnfocused := LColorsObject['SelectionForegroundUnfocused'].ToAlphaColor;
        SyncEditBackground := LColorsObject['SyncEditBackground'].ToAlphaColor;
        SyncEditEditBorder := LColorsObject['SyncEditEditBorder'].ToAlphaColor;
        SyncEditWordBorder := LColorsObject['SyncEditWordBorder'].ToAlphaColor;
        WordWrapIndicatorArrow := LColorsObject['WordWrapIndicatorArrow'].ToAlphaColor;
        WordWrapIndicatorLines := LColorsObject['WordWrapIndicatorLines'].ToAlphaColor;
      end;
    end;

    if (csDesigning in LEditor.ComponentState) or (eoLoadFontNames in LEditor.Options) then
    begin
      LFontsObject := AThemeObject['Fonts'].ObjectValue;

      if Assigned(LFontsObject) then
      with LEditor.Fonts do
      begin
        SetTextEditorFontFamily(CodeFoldingHint, LFontsObject['CodeFoldingHint'].ToStr(TextEditorFontFamily(CodeFoldingHint)));
        SetTextEditorFontFamily(CompletionProposal, LFontsObject['CompletionProposal'].ToStr(TextEditorFontFamily(CompletionProposal)));
        SetTextEditorFontFamily(Hint, LFontsObject['Hint'].ToStr(TextEditorFontFamily(Hint)));
        SetTextEditorFontFamily(LineNumbers, LFontsObject['LineNumbers'].ToStr(TextEditorFontFamily(LineNumbers)));
        SetTextEditorFontFamily(Minimap, LFontsObject['Minimap'].ToStr(TextEditorFontFamily(Minimap)));
        SetTextEditorFontFamily(Ruler, LFontsObject['Ruler'].ToStr(TextEditorFontFamily(Ruler)));
        SetTextEditorFontFamily(Text, LFontsObject['Text'].ToStr(TextEditorFontFamily(Text)));
      end;
    end;

    if (csDesigning in LEditor.ComponentState) or (eoLoadFontSizes in LEditor.Options) then
    begin
      LFontSizesObject := AThemeObject['FontSizes'].ObjectValue;

      if Assigned(LFontSizesObject) then
      with LEditor.Fonts do
      begin
        SetTextEditorFontSize(CodeFoldingHint, LFontSizesObject['CodeFoldingHint'].ToSingle(TextEditorFontSize(CodeFoldingHint)));
        SetTextEditorFontSize(CompletionProposal, LFontSizesObject['CompletionProposal'].ToSingle(TextEditorFontSize(CompletionProposal)));
        SetTextEditorFontSize(Hint, LFontSizesObject['Hint'].ToSingle(TextEditorFontSize(Hint)));
        SetTextEditorFontSize(LineNumbers, LFontSizesObject['LineNumbers'].ToSingle(TextEditorFontSize(LineNumbers)));
        SetTextEditorFontSize(Minimap, LFontSizesObject['Minimap'].ToSingle(TextEditorFontSize(Minimap)));
        SetTextEditorFontSize(Ruler, LFontSizesObject['Ruler'].ToSingle(TextEditorFontSize(Ruler)));
        SetTextEditorFontSize(Text, LFontSizesObject['Text'].ToSingle(TextEditorFontSize(Text)));
      end;
    end;

    if (csDesigning in LEditor.ComponentState) or (eoLoadFontStyles in LEditor.Options) then
    begin
      LStylesArray := AThemeObject['Styles'].ArrayValue;

      with LEditor.FontStyles do
      begin
        Clear;

        for var LIndex := 0 to LStylesArray.Count - 1 do
        begin
          LJSONDataValue := LStylesArray.Items[LIndex];
          LElementName := LJSONDataValue.ObjectValue['Name'].Value;
          LFontStyle := StrToFontStyle(LJSONDataValue.ObjectValue['Style'].Value);

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
    Element := AElementPrefix + AAttributesObject['Element'].Value;
    ParentForeground := StrToBoolDef(AAttributesObject['ParentForeground'].Value, False);
    ParentBackground := StrToBoolDef(AAttributesObject['ParentBackground'].Value, False);

    if AAttributesObject.Contains('EscapeChar') then
      EscapeChar := AAttributesObject['EscapeChar'].Value[1];
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportKeyList(const AKeyList: TTextEditorKeyList; const AKeyListObject: TJSONObject;
  const AElementPrefix: string);
var
  LWordArray: TJSONArray;
begin
  if Assigned(AKeyListObject) then
  begin
    AKeyList.TokenType := StrToRangeType(AKeyListObject['Type'].Value);

    LWordArray := AKeyListObject.ValueArray['Words'];

    for var LIndex := 0 to LWordArray.Count - 1 do
      AKeyList.KeyList.Add(LWordArray.ValueString[LIndex]);

    ImportAttributes(AKeyList.Attribute, AKeyListObject['Attributes'].ObjectValue, AElementPrefix);
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportSet(const ASet: TTextEditorSet; const ASetObject: TJSONObject;
  const AElementPrefix: string);
begin
  if Assigned(ASetObject) then
  begin
    ASet.CharSet := ASetObject['Symbols'].ToSet;
    ImportAttributes(ASet.Attribute, ASetObject['Attributes'].ObjectValue, AElementPrefix);
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
    LName := ARangeObject['File'].Value;

    if (hoMultiHighlighter in FHighlighter.Options) and not LName.IsEmpty then
    begin
      LElementPrefix := ARangeObject['ElementPrefix'].Value;
      LEditor := FHighlighter.Editor as TCustomTextEditor;
      LFileStream := LEditor.CreateHighlighterStream(LName);

      if Assigned(LFileStream) then
      begin
        LJSONObject := TJSONObject.ParseFromStream(LFileStream) as TJSONObject;

        if Assigned(LJSONObject) then
        try
          LTokenRangeObject := LJSONObject['Highlighter']['MainRules'].ObjectValue;

          { You can include MainRules... }
          if LTokenRangeObject['Name'].Value = ARangeObject['IncludeRange'].Value then
            ImportRange(AParentRange, LTokenRangeObject, nil, True, LElementPrefix)
          else
          { or SubRules... }
          begin
            LSubRulesObject := LTokenRangeObject['SubRules'].ObjectValue;

            if Assigned(LSubRulesObject) then
            for var LIndex := 0 to LSubRulesObject.Count - 1 do
            begin
              if LSubRulesObject.Names[LIndex] = 'Range' then
              begin
                LArrayValue := LSubRulesObject.Items[LIndex].ArrayValue;

                for var LIndex2 := 0 to LArrayValue.Count - 1 do
                begin
                  LJSONSubRulesObject := LArrayValue.ValueObject[LIndex2];

                  if LJSONSubRulesObject.ValueString['Name'] = ARangeObject['IncludeRange'].Value then
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
        ImportAttributes(ARange.Attribute, ARangeObject['Attributes'].ObjectValue, AElementPrefix);

        if not ARangeObject['AllowedCharacters'].Value.IsEmpty then
          ARange.AllowedCharacters := ARangeObject['AllowedCharacters'].ToSet;

        if not ARangeObject['Delimiters'].Value.IsEmpty then
          ARange.Delimiters := ARangeObject['Delimiters'].ToSet;

        ARange.TokenType := StrToRangeType(ARangeObject['Type'].Value);
        ARange.Nested := FHighlighter.NestedComments and (ARange.TokenType = ttBlockComment);

        LPropertiesObject := ARangeObject['Properties'].ObjectValue;

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
            OpenBeginningOfLine := LPropertiesObject.ValueBoolean['OpenBeginningOfLine'];
            OpenEndOfLine := LPropertiesObject.ValueBoolean['OpenEndOfLine'];
            SkipWhitespace := LPropertiesObject.ValueBoolean['SkipWhitespace'];
            SkipWhitespaceOnce := LPropertiesObject.ValueBoolean['SkipWhitespaceOnce'];
            UseDelimitersForText := LPropertiesObject.ValueBoolean['UseDelimitersForText'];
          end;

          LArrayValue := LPropertiesObject['AlternativeClose'].ArrayValue;

          if LArrayValue.Count > 0 then
          begin
            ARange.AlternativeCloseArrayCount := LArrayValue.Count;

            for var LIndex := 0 to ARange.AlternativeCloseArrayCount - 1 do
              ARange.AlternativeCloseArray[LIndex] := LArrayValue.Items[LIndex].Value;
          end;
        end;

        with ARange do
        begin
          OpenToken.Clear;
          OpenToken.BreakType := btUnspecified;
          CloseToken.Clear;
          CloseToken.BreakType := btUnspecified;
        end;

        LTokenRangeObject := ARangeObject['TokenRange'].ObjectValue;

        if Assigned(LTokenRangeObject) then
        begin
          LOpenToken := LTokenRangeObject['Open'].Value;
          LCloseToken := LTokenRangeObject['Close'].Value;

          ARange.AddTokenRange(LOpenToken, StrToBreakType(LTokenRangeObject['OpenBreakType'].Value), LCloseToken,
            StrToBreakType(LTokenRangeObject['CloseBreakType'].Value));

          case ARange.TokenType of
            ttLineComment: FHighlighter.Comments.AddLineComment(LOpenToken);
            ttBlockComment: FHighlighter.Comments.AddBlockComment(LOpenToken, LCloseToken);
          end;
        end;
      end;
      { Sub rules }
      LSubRulesObject := ARangeObject['SubRules'].ObjectValue;

      if Assigned(LSubRulesObject) then
      for var LIndex := 0 to LSubRulesObject.Count - 1 do
      begin
        LName := LSubRulesObject.Names[LIndex];
        LArrayValue := LSubRulesObject.Items[LIndex].ArrayValue;

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
  LJSONDataValue: PJSONDataValue;
  LName: string;
  LEditor: TCustomTextEditor;
  LFileStream: TStream;
  LJSONObject: TJSONObject;
  LSkipRegionItem: TTextEditorSkipRegionItem;
begin
  if not Assigned(ACompletionProposalObject) then
    Exit;

  LSkipRegionArray := ACompletionProposalObject['SkipRegion'].ArrayValue;

  for var LIndex := 0 to LSkipRegionArray.Count - 1 do
  begin
    LJSONDataValue := LSkipRegionArray.Items[LIndex];

    if hoMultiHighlighter in FHighlighter.Options then
    begin
      LName := LJSONDataValue.ObjectValue['File'].Value;

      if not LName.IsEmpty then
      begin
        LEditor := FHighlighter.Editor as TCustomTextEditor;
        LFileStream := LEditor.CreateHighlighterStream(LName);

        if Assigned(LFileStream) then
        try
          LJSONObject := TJSONObject.ParseFromStream(LFileStream) as TJSONObject;

          if Assigned(LJSONObject) then
          try
            if LJSONObject.Contains('CompletionProposal') then
              ImportCompletionProposal(LJSONObject['CompletionProposal'].ObjectValue);
          finally
            LJSONObject.Free;
          end;
        finally
          LFileStream.Free;
        end;
      end;

      if FHighlighter.CompletionProposalSkipRegions.Contains(LJSONDataValue.ObjectValue['OpenToken'].Value,
        LJSONDataValue.ObjectValue['CloseToken'].Value) then
        Continue;
    end;

    LSkipRegionItem := FHighlighter.CompletionProposalSkipRegions.Add(LJSONDataValue.ObjectValue['OpenToken'].Value,
      LJSONDataValue.ObjectValue['CloseToken'].Value);
    LSkipRegionItem.RegionType := StrToRegionType(LJSONDataValue.ObjectValue['RegionType'].Value);
    LSkipRegionItem.SkipEmptyChars := LJSONDataValue.ObjectValue.ValueBoolean['SkipEmptyChars'];
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportCodeFoldingVoidElements(const ACodeFoldingObject: TJSONObject);
var
  LVoidElementArray: TJSONArray;
  LJSONDataValue: PJSONDataValue;
begin
  if ACodeFoldingObject.Contains('VoidElements') then
  begin
    FHighlighter.CreateCodeFoldingVoidElements;
    FHighlighter.CodeFoldingVoidElements.BeginUpdate;
    try
      LVoidElementArray := ACodeFoldingObject['VoidElements'].ArrayValue;

      for var LIndex := 0 to LVoidElementArray.Count - 1 do
      begin
        LJSONDataValue := LVoidElementArray.Items[LIndex];

        if FHighlighter.CodeFoldingVoidElements.IndexOf(LJSONDataValue.Value) = -1 then
          FHighlighter.CodeFoldingVoidElements.Add(LJSONDataValue.Value);
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
  LJSONDataValue: PJSONDataValue;
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
    LSkipRegionArray := ACodeFoldingObject['SkipRegion'].ArrayValue;

    for var LIndex := 0 to LSkipRegionArray.Count - 1 do
    begin
      LJSONDataValue := LSkipRegionArray.Items[LIndex];

      LOpenToken := LJSONDataValue.ObjectValue['OpenToken'].Value;
      LCloseToken := LJSONDataValue.ObjectValue['CloseToken'].Value;

      if hoMultiHighlighter in FHighlighter.Options then
      begin
        LName := LJSONDataValue.ObjectValue['File'].Value;

        if not LName.IsEmpty then
        begin
          LEditor := FHighlighter.Editor as TCustomTextEditor;
          LFileStream := LEditor.CreateHighlighterStream(LName);

          if Assigned(LFileStream) then
          try
            LJSONObject := TJSONObject.ParseFromStream(LFileStream) as TJSONObject;

            if Assigned(LJSONObject) then
            try
              if LJSONObject.Contains('CodeFolding') then
                ImportCodeFoldingSkipRegion(ACodeFoldingRegion, LJSONObject['CodeFolding']['Ranges'].ArrayValue.Items[0].ObjectValue);
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

      LSkipRegionType := StrToRegionType(LJSONDataValue.ObjectValue['RegionType'].Value);

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
          SkipEmptyChars := LJSONDataValue.ObjectValue.ValueBoolean['SkipEmptyChars'];
          SkipIfNextCharIsNot := TControlCharacters.Null;

          if LJSONDataValue.ObjectValue.Contains('NextCharIsNot') then
            SkipIfNextCharIsNot := LJSONDataValue.ObjectValue['NextCharIsNot'].Value[1];

          Nested := FHighlighter.NestedComments and (LSkipRegionType = ritMultiLineComment);

          if LJSONDataValue.ObjectValue.Contains('Nested') then
            Nested := LJSONDataValue.ObjectValue.ValueBoolean['Nested'];
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
  LJSONDataValue: PJSONDataValue;
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

    LFoldRegionArray := ACodeFoldingObject['FoldRegion'].ArrayValue;

    for var LIndex := 0 to LFoldRegionArray.Count - 1 do
    begin
      LJSONDataValue := LFoldRegionArray.Items[LIndex];
      LOpenToken := LJSONDataValue.ObjectValue['OpenToken'].Value;
      LCloseToken := LJSONDataValue.ObjectValue['CloseToken'].Value;
      LAlternativeCloseToken := LJSONDataValue.ObjectValue['AlternativeCloseToken'].Value;

      if hoMultiHighlighter in FHighlighter.Options then
      begin
        LName := LJSONDataValue.ObjectValue['File'].Value;

        if not LName.IsEmpty then
        begin
          LEditor := FHighlighter.Editor as TCustomTextEditor;
          LFileStream := LEditor.CreateHighlighterStream(LName);

          if Assigned(LFileStream) then
          try
            LJSONObject := TJSONObject.ParseFromStream(LFileStream) as TJSONObject;

            if Assigned(LJSONObject) then
            try
              if LJSONObject.Contains('CodeFolding') then
                ImportCodeFoldingFoldRegion(ACodeFoldingRegion, LJSONObject['CodeFolding']['Ranges'].ArrayValue.Items[0].ObjectValue);
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
      LMemberObject := LJSONDataValue.ObjectValue['Properties'].ObjectValue;

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
        OpenTokenCanBeFollowedBy := LMemberObject['OpenTokenCanBeFollowedBy'].Value;
        TokenEndIsPreviousLine := LMemberObject.ValueBoolean['TokenEndIsPreviousLine'];
        NoSubs := LMemberObject.ValueBoolean['NoSubs'];
        BeginWithBreakChar := LMemberObject.ValueBoolean['BeginWithBreakChar'];
        LSkipIfFoundAfterOpenTokenArray := LMemberObject['SkipIfFoundAfterOpenToken'].ArrayValue;

        if LSkipIfFoundAfterOpenTokenArray.Count > 0 then
        begin
          SkipIfFoundAfterOpenTokenArrayCount := LSkipIfFoundAfterOpenTokenArray.Count;

          for var LIndex2 := 0 to SkipIfFoundAfterOpenTokenArrayCount - 1 do
            SkipIfFoundAfterOpenTokenArray[LIndex2] := LSkipIfFoundAfterOpenTokenArray.Items[LIndex2].Value;
        end;

        if LMemberObject.Contains('BreakCharFollows') then
          BreakCharFollows := LMemberObject.ValueBoolean['BreakCharFollows'];

        BreakIfNotFoundBeforeNextRegion := LMemberObject['BreakIfNotFoundBeforeNextRegion'].Value;
        OpenTokenEnd := LMemberObject['OpenTokenEnd'].Value;
        ShowGuideLine := StrToBoolDef(LMemberObject['ShowGuideLine'].Value, True);
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

  LArray := ACodeFoldingObject['Ranges'].ArrayValue;
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
      LCodeFoldingObject := LArray.Items[LIndex].ObjectValue;

      if LCodeFoldingObject.Contains('Options') then
      begin
        LObject := LCodeFoldingObject['Options'].ObjectValue;

        if LObject.Contains('BythonPreprocessor') then
        begin
          FHighlighter.BythonPreprocessor := LObject.ValueBoolean['BythonPreprocessor'];
          LVisible := FHighlighter.BythonPreprocessor;
        end;

        if LObject.Contains('EscapeChar') then
          LEscapeChar := LObject['EscapeChar'].Value[1];

        if LObject.Contains('StringEscapeChar') then
          LStringEscapeChar := LObject['StringEscapeChar'].Value[1];

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
      LCodeFoldingObject := LArray.Items[LIndex].ObjectValue;

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
  LJSONDataValue: PJSONDataValue;
  LKeyword, LImageName: string;
  LKind: TTextEditorKeywordImageKind;
begin
  if not Assigned(AKeywordImagesObject) then
    Exit;

  LArray := AKeywordImagesObject['Items'].ArrayValue;

  for var LIndex := 0 to LArray.Count - 1 do
  begin
    LJSONDataValue := LArray.Items[LIndex];

    LKeyword := LJSONDataValue.ObjectValue['Word'].Value;
    LImageName := LJSONDataValue.ObjectValue['Image'].Value;

    if LKeyword.IsEmpty then
      Continue;

    if SameText(LImageName, 'ArrowUp') then
      LKind := kikArrowUp
    else
    if SameText(LImageName, 'ArrowDown') then
      LKind := kikArrowDown
    else
      Continue;

    FHighlighter.KeywordImages.AddOrSetValue(if FHighlighter.MainRules.CaseSensitive then LKeyword else AnsiLowerCase(LKeyword), LKind);
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportMatchingPair(const AMatchingPairObject: TJSONObject);
var
  LArray: TJSONArray;
  LJSONDataValue: PJSONDataValue;
  LName: string;
  LEditor: TCustomTextEditor;
  LFileStream: TStream;
  LJSONObject: TJSONObject;
  LTokenMatch: PTextEditorMatchingPairToken;
begin
  if not Assigned(AMatchingPairObject) then
    Exit;

  LArray := AMatchingPairObject['Pairs'].ArrayValue;

  for var LIndex := 0 to LArray.Count - 1 do
  begin
    LJSONDataValue := LArray.Items[LIndex];

    if hoMultiHighlighter in FHighlighter.Options then
    begin
      LName := LJSONDataValue.ObjectValue['File'].Value;

      if not LName.IsEmpty then
      begin
        LEditor := FHighlighter.Editor as TCustomTextEditor;
        LFileStream := LEditor.CreateHighlighterStream(LName);

        if Assigned(LFileStream) then
        try
          LJSONObject := TJSONObject.ParseFromStream(LFileStream) as TJSONObject;

          if Assigned(LJSONObject) then
          try
            if LJSONObject.Contains('MatchingPair') then
              ImportMatchingPair(LJSONObject['MatchingPair'].ObjectValue);
          finally
            LJSONObject.Free;
          end
        finally
          LFileStream.Free;
        end;
      end;
    end;

    New(LTokenMatch);

    LTokenMatch.OpenToken := LJSONDataValue.ObjectValue['OpenToken'].Value;
    LTokenMatch.CloseToken := LJSONDataValue.ObjectValue['CloseToken'].Value;

    FHighlighter.MatchingPairs.Add(LTokenMatch);
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportHighlighter(const AJSONObject: TJSONObject);
var
  LHighlighterObject: TJSONObject;
begin
  FHighlighter.Clear;

  LHighlighterObject := AJSONObject['Highlighter'];

  FHighlighter.SetOption(hoMultiHighlighter, LHighlighterObject.ValueBoolean['MultiHighlighter']);
  FHighlighter.ExcludedWordBreakCharacters := LHighlighterObject.Values['ExcludedWordBreakCharacters'].ToSet;
  FHighlighter.BeforePrepare := if LHighlighterObject.ValueBoolean['YAML'] then FHighlighter.PrepareYAMLHighlighter else nil;

  ImportSample(LHighlighterObject);
  ImportEditorProperties(LHighlighterObject['Editor'].ObjectValue);
  ImportRange(FHighlighter.MainRules, LHighlighterObject['MainRules'].ObjectValue);
  ImportCodeFolding(AJSONObject['CodeFolding'].ObjectValue);
  ImportKeywordImages(AJSONObject['KeywordImages'].ObjectValue);
  ImportMatchingPair(AJSONObject['MatchingPair'].ObjectValue);
  ImportCompletionProposal(AJSONObject['CompletionProposal'].ObjectValue);

  FHighlighter.Colors.AddElements;

  ImportHighlightLine(AJSONObject['HighlightLine'].ObjectValue);
end;

procedure TTextEditorHighlighterImportJSON.ImportHighlightLine(const AHighlightLineObject: TJSONObject);
var
  LArray: TJSONArray;
  LJSONDataValue: PJSONDataValue;
  LName: string;
  LEditor: TCustomTextEditor;
  LFileStream: TStream;
  LJSONObject: TJSONObject;
  LItem: TTextEditorHighlightLineItem;
  LElement: string;
begin
  if not Assigned(AHighlightLineObject) then
    Exit;

  LArray := AHighlightLineObject['Items'].ArrayValue;

  for var LIndex := 0 to LArray.Count - 1 do
  begin
    LJSONDataValue := LArray.Items[LIndex];

    if hoMultiHighlighter in FHighlighter.Options then
    begin
      LName := LJSONDataValue.ObjectValue['File'].Value;

      if not LName.IsEmpty then
      begin
        LEditor := FHighlighter.Editor as TCustomTextEditor;
        LFileStream := LEditor.CreateHighlighterStream(LName);

        if Assigned(LFileStream) then
        try
          LJSONObject := TJSONObject.ParseFromStream(LFileStream) as TJSONObject;

          if Assigned(LJSONObject) then
          try
            if LJSONObject.Contains('HighlightLine') then
              ImportMatchingPair(LJSONObject['HighlightLine'].ObjectValue);
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
    LItem.Background := LJSONDataValue.ObjectValue['BackgroundColor'].ToAlphaColor;
    LItem.Foreground := LJSONDataValue.ObjectValue['ForegroundColor'].ToAlphaColor;

    { Currently only Method and MethodName elements supported for Makefile highlighter.
      Add more element support, if needed. }
    LElement := LJSONDataValue.ObjectValue['Element'].Value;

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

    if LJSONDataValue.ObjectValue.ValueBoolean['IgnoreCase'] then
      LItem.Options := LItem.Options + [hlIgnoreCase];

    if LJSONDataValue.ObjectValue.ValueBoolean['Multiline'] then
      LItem.Options := LItem.Options + [hlMultiline];

    LItem.Pattern := LJSONDataValue.ObjectValue['Pattern'].Value;
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportFromStream(const AStream: TStream);
var
  LJSONObject: TJSONObject;
begin
  try
    LJSONObject := TJSONObject.ParseFromStream(AStream) as TJSONObject;

    if Assigned(LJSONObject) then
    try
      ImportHighlighter(LJSONObject);
    finally
      LJSONObject.Free;
    end;
  except
    on E: EJSONParserException do
      raise EJSONImportException.Create(Format(STextEditorErrorInHighlighterParse, [E.LineNum, E.Column, E.Message]));
    on E: Exception do
      raise EJSONImportException.Create(Format(STextEditorErrorInHighlighterImport, [E.Message]));
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportColorsFromStream(const AStream: TStream);
var
  LJSONObject: TJSONObject;
begin
  try
    LJSONObject := TJSONObject.ParseFromStream(AStream) as TJSONObject;

    if Assigned(LJSONObject) then
    try
      ImportColorTheme(LJSONObject['Theme']);
    finally
      LJSONObject.Free;
    end;
  except
    on E: EJSONParserException do
      raise EJSONImportException.Create(Format(STextEditorErrorInHighlighterParse, [E.LineNum, E.Column, E.Message]));
    on E: Exception do
      raise EJSONImportException.Create(Format(STextEditorErrorInHighlighterImport, [E.Message]));
  end;
end;

end.



