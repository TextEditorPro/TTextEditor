unit TextEditor.Highlighter.Import.JSON;

interface

uses
  System.Classes, System.SysUtils, TextEditor, TextEditor.CodeFolding.Regions, TextEditor.Highlighter,
  TextEditor.Highlighter.Attributes, TextEditor.Highlighter.Colors, TextEditor.Highlighter.Rules,
  TextEditor.JSONDataObjects, TextEditor.SkipRegions;

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
  System.TypInfo, System.UITypes, Vcl.Graphics, TextEditor.Consts, TextEditor.Highlighter.Token,
  TextEditor.HighlightLine, TextEditor.Language, TextEditor.Types;

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
    Result := ritMultiLineString
end;

function StrToRangeType(const AString: string): TTextEditorRangeType;
var
  LIndex: Integer;
begin
  LIndex := GetEnumValue(TypeInfo(TTextEditorRangeType), 'tt' + AString);

  if LIndex = -1 then
    Result := ttUnspecified
  else
    Result := TTextEditorRangeType(LIndex);
end;

{ TTextEditorHighlighterImportJSON }

constructor TTextEditorHighlighterImportJSON.Create(const AHighlighter: TTextEditorHighlighter);
begin
  inherited Create;

  FHighlighter := AHighlighter;
end;

procedure TTextEditorHighlighterImportJSON.ImportSample(const AHighlighterObject: TJSONObject);
var
  LIndex: Integer;
  LSampleArray: TJSONArray;
  LHighlighter: TTextEditorHighlighter;
begin
  if Assigned(AHighlighterObject) and Assigned(FHighlighter.Editor) then
  begin
    LHighlighter := TCustomTextEditor(FHighlighter.Editor).Highlighter;

    LSampleArray := AHighlighterObject.ValueArray['Sample'];
    LHighlighter.Sample := '';
    for LIndex := 0 to LSampleArray.Count - 1 do
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
  LIndex: Integer;
  LColorsObject, LFontsObject, LFontSizesObject: TJSONObject;
  LStylesArray: TJSONArray;
  LElementName: string;
  LJSONDataValue: PJSONDataValue;
  LEditor: TCustomTextEditor;
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
        ActiveLineBackground := LColorsObject['ActiveLineBackground'].ToColor;
        ActiveLineBackgroundUnfocused := LColorsObject['ActiveLineBackgroundUnfocused'].ToColor;
        ActiveLineForeground := LColorsObject['ActiveLineForeground'].ToColor;
        ActiveLineForegroundUnfocused := LColorsObject['ActiveLineForegroundUnfocused'].ToColor;
        CaretMultiEditBackground := LColorsObject['CaretMultiEditBackground'].ToColor;
        CaretMultiEditForeground := LColorsObject['CaretMultiEditForeground'].ToColor;
        CodeFoldingActiveLineBackground := LColorsObject['CodeFoldingActiveLineBackground'].ToColor;
        CodeFoldingActiveLineBackgroundUnfocused := LColorsObject['CodeFoldingActiveLineBackgroundUnfocused'].ToColor;
        CodeFoldingBackground := LColorsObject['CodeFoldingBackground'].ToColor;
        CodeFoldingCollapsedLine := LColorsObject['CodeFoldingCollapsedLine'].ToColor;
        CodeFoldingFoldingLine := LColorsObject['CodeFoldingFoldingLine'].ToColor;
        CodeFoldingFoldingLineHighlight := LColorsObject['CodeFoldingFoldingLineHighlight'].ToColor;
        CodeFoldingHintBackground := LColorsObject['CodeFoldingHintBackground'].ToColor;
        CodeFoldingHintBorder := LColorsObject['CodeFoldingHintBorder'].ToColor;
        CodeFoldingHintIndicatorBackground := LColorsObject['CodeFoldingHintIndicatorBackground'].ToColor;
        CodeFoldingHintIndicatorBorder := LColorsObject['CodeFoldingHintIndicatorBorder'].ToColor;
        CodeFoldingHintIndicatorMark := LColorsObject['CodeFoldingHintIndicatorMark'].ToColor;
        CodeFoldingHintText := LColorsObject['CodeFoldingHintText'].ToColor;
        CodeFoldingIndent := LColorsObject['CodeFoldingIndent'].ToColor;
        CodeFoldingIndentHighlight := LColorsObject['CodeFoldingIndentHighlight'].ToColor;
        CompletionProposalBackground := LColorsObject['CompletionProposalBackground'].ToColor;
        CompletionProposalForeground := LColorsObject['CompletionProposalForeground'].ToColor;
        CompletionProposalSelectedBackground := LColorsObject['CompletionProposalSelectedBackground'].ToColor;
        CompletionProposalSelectedText := LColorsObject['CompletionProposalSelectedText'].ToColor;
        EditorAssemblerCommentBackground := LColorsObject['EditorAssemblerCommentBackground'].ToColor;
        EditorAssemblerCommentForeground := LColorsObject['EditorAssemblerCommentForeground'].ToColor;
        EditorAssemblerReservedWordBackground := LColorsObject['EditorAssemblerReservedWordBackground'].ToColor;
        EditorAssemblerReservedWordForeground := LColorsObject['EditorAssemblerReservedWordForeground'].ToColor;
        EditorAttributeBackground := LColorsObject['EditorAttributeBackground'].ToColor;
        EditorAttributeForeground := LColorsObject['EditorAttributeForeground'].ToColor;
        EditorBackground := LColorsObject['EditorBackground'].ToColor;
        EditorCharacterBackground := LColorsObject['EditorCharacterBackground'].ToColor;
        EditorCharacterForeground := LColorsObject['EditorCharacterForeground'].ToColor;
        EditorCommentBackground := LColorsObject['EditorCommentBackground'].ToColor;
        EditorCommentForeground := LColorsObject['EditorCommentForeground'].ToColor;
        EditorDirectiveBackground := LColorsObject['EditorDirectiveBackground'].ToColor;
        EditorDirectiveForeground := LColorsObject['EditorDirectiveForeground'].ToColor;
        EditorForeground := LColorsObject['EditorForeground'].ToColor;
        EditorHexNumberBackground := LColorsObject['EditorHexNumberBackground'].ToColor;
        EditorHexNumberForeground := LColorsObject['EditorHexNumberForeground'].ToColor;
        EditorHighlightedBlockBackground := LColorsObject['EditorHighlightedBlockBackground'].ToColor;
        EditorHighlightedBlockForeground := LColorsObject['EditorHighlightedBlockForeground'].ToColor;
        EditorHighlightedBlockSymbolBackground := LColorsObject['EditorHighlightedBlockSymbolBackground'].ToColor;
        EditorHighlightedBlockSymbolForeground := LColorsObject['EditorHighlightedBlockSymbolForeground'].ToColor;
        EditorLogicalOperatorBackground := LColorsObject['EditorLogicalOperatorBackground'].ToColor;
        EditorLogicalOperatorForeground := LColorsObject['EditorLogicalOperatorForeground'].ToColor;
        EditorMethodBackground := LColorsObject['EditorMethodBackground'].ToColor;
        EditorMethodForeground := LColorsObject['EditorMethodForeground'].ToColor;
        EditorMethodItalicBackground := LColorsObject['EditorMethodItalicBackground'].ToColor;
        EditorMethodItalicForeground := LColorsObject['EditorMethodItalicForeground'].ToColor;
        EditorMethodNameBackground := LColorsObject['EditorMethodNameBackground'].ToColor;
        EditorMethodNameForeground := LColorsObject['EditorMethodNameForeground'].ToColor;
        EditorNumberBackground := LColorsObject['EditorNumberBackground'].ToColor;
        EditorNumberForeground := LColorsObject['EditorNumberForeground'].ToColor;
        EditorReservedWordBackground := LColorsObject['EditorReservedWordBackground'].ToColor;
        EditorReservedWordForeground := LColorsObject['EditorReservedWordForeground'].ToColor;
        EditorStringBackground := LColorsObject['EditorStringBackground'].ToColor;
        EditorStringForeground := LColorsObject['EditorStringForeground'].ToColor;
        EditorSymbolBackground := LColorsObject['EditorSymbolBackground'].ToColor;
        EditorSymbolForeground := LColorsObject['EditorSymbolForeground'].ToColor;
        EditorValueBackground := LColorsObject['EditorValueBackground'].ToColor;
        EditorValueForeground := LColorsObject['EditorValueForeground'].ToColor;
        EditorWebLinkBackground := LColorsObject['EditorWebLinkBackground'].ToColor;
        EditorWebLinkForeground := LColorsObject['EditorWebLinkForeground'].ToColor;
        LeftMarginActiveLineBackground := LColorsObject['LeftMarginActiveLineBackground'].ToColor;
        LeftMarginActiveLineBackgroundUnfocused := LColorsObject['LeftMarginActiveLineBackgroundUnfocused'].ToColor;
        LeftMarginActiveLineNumber := LColorsObject['LeftMarginActiveLineNumber'].ToColor;
        LeftMarginBackground := LColorsObject['LeftMarginBackground'].ToColor;
        LeftMarginBookmarkPanelBackground := LColorsObject['LeftMarginBookmarkPanelBackground'].ToColor;
        LeftMarginBorder := LColorsObject['LeftMarginBorder'].ToColor;
        LeftMarginLineNumberLine := LColorsObject['LeftMarginLineNumberLine'].ToColor;
        LeftMarginLineNumbers := LColorsObject['LeftMarginLineNumbers'].ToColor;
        LeftMarginLineStateModified := LColorsObject['LeftMarginLineStateModified'].ToColor;
        LeftMarginLineStateNormal := LColorsObject['LeftMarginLineStateNormal'].ToColor;
        MatchingPairMatched := LColorsObject['MatchingPairMatched'].ToColor;
        MatchingPairUnderline := LColorsObject['MatchingPairUnderline'].ToColor;
        MatchingPairUnmatched := LColorsObject['MatchingPairUnmatched'].ToColor;
        MinimapBackground := LColorsObject['MinimapBackground'].ToColor;
        MinimapBookmark := LColorsObject['MinimapBookmark'].ToColor;
        MinimapVisibleRows := LColorsObject['MinimapVisibleRows'].ToColor;
        RightMargin := LColorsObject['RightMargin'].ToColor;
        RightMovingEdge := LColorsObject['RightMovingEdge'].ToColor;
        RulerBackground := LColorsObject['RulerBackground'].ToColor;
        RulerBorder := LColorsObject['RulerBorder'].ToColor;
        RulerLines := LColorsObject['RulerLines'].ToColor;
        RulerMovingEdge := LColorsObject['RulerMovingEdge'].ToColor;
        RulerNumbers := LColorsObject['RulerNumbers'].ToColor;
        RulerSelection := LColorsObject['RulerSelection'].ToColor;
        SearchHighlighterBackground := LColorsObject['SearchHighlighterBackground'].ToColor;
        SearchHighlighterBorder := LColorsObject['SearchHighlighterBorder'].ToColor;
        SearchHighlighterForeground := LColorsObject['SearchHighlighterForeground'].ToColor;
        SearchInSelectionBackground := LColorsObject['SearchInSelectionBackground'].ToColor;
        SearchMapActiveLine := LColorsObject['SearchMapActiveLine'].ToColor;
        SearchMapBackground := LColorsObject['SearchMapBackground'].ToColor;
        SearchMapForeground := LColorsObject['SearchMapForeground'].ToColor;
        SelectionBackground := LColorsObject['SelectionBackground'].ToColor;
        SelectionBackgroundUnfocused := LColorsObject['SelectionBackgroundUnfocused'].ToColor;
        SelectionForeground := LColorsObject['SelectionForeground'].ToColor;
        SelectionForegroundUnfocused := LColorsObject['SelectionForegroundUnfocused'].ToColor;
        SyncEditBackground := LColorsObject['SyncEditBackground'].ToColor;
        SyncEditEditBorder := LColorsObject['SyncEditEditBorder'].ToColor;
        SyncEditWordBorder := LColorsObject['SyncEditWordBorder'].ToColor;
        WordWrapIndicatorArrow := LColorsObject['WordWrapIndicatorArrow'].ToColor;
        WordWrapIndicatorLines := LColorsObject['WordWrapIndicatorLines'].ToColor;
      end;

      LEditor.WordWrap.FreeIndicatorBitmap; { Colors are changed }
      LEditor.UpdateColors;
    end;

    if (csDesigning in LEditor.ComponentState) or (eoLoadFontNames in LEditor.Options) then
    begin
      LFontsObject := AThemeObject['Fonts'].ObjectValue;
      if Assigned(LFontsObject) then
      with LEditor.Fonts do
      begin
        CodeFoldingHint.Name := LFontsObject['CodeFoldingHint'].ToStr(CodeFoldingHint.Name);
        CompletionProposal.Name := LFontsObject['CompletionProposal'].ToStr(CompletionProposal.Name);
        LineNumbers.Name := LFontsObject['LineNumbers'].ToStr(LineNumbers.Name);
        Minimap.Name := LFontsObject['Minimap'].ToStr(Minimap.Name);
        Ruler.Name := LFontsObject['Ruler'].ToStr(Ruler.Name);
        Text.Name := LFontsObject['Text'].ToStr(Text.Name);
      end;
    end;

    if (csDesigning in LEditor.ComponentState) or (eoLoadFontSizes in LEditor.Options) then
    begin
      LFontSizesObject := AThemeObject['FontSizes'].ObjectValue;
      if Assigned(LFontSizesObject) then
      with LEditor.Fonts do
      begin
        CodeFoldingHint.Size := LFontSizesObject['CodeFoldingHint'].ToInt(CodeFoldingHint.Size);
        CompletionProposal.Size := LFontSizesObject['CompletionProposal'].ToInt(CompletionProposal.Size);
        LineNumbers.Size := LFontSizesObject['LineNumbers'].ToInt(LineNumbers.Size);
        Minimap.Size := LFontSizesObject['Minimap'].ToInt(Minimap.Size);
        Ruler.Size := LFontSizesObject['Ruler'].ToInt(Ruler.Size);
        Text.Size := LFontSizesObject['Text'].ToInt(Text.Size);
      end;
    end;

    if (csDesigning in LEditor.ComponentState) or (eoLoadFontStyles in LEditor.Options) then
    begin
      LStylesArray := AThemeObject['Styles'].ArrayValue;
      with LEditor.FontStyles do
      begin
        Clear;

        for LIndex := 0 to LStylesArray.Count - 1 do
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
            Editor := LFontStyle
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
  LIndex: Integer;
  LWordArray: TJSONArray;
begin
  if Assigned(AKeyListObject) then
  begin
    AKeyList.TokenType := StrToRangeType(AKeyListObject['Type'].Value);
    LWordArray := AKeyListObject.ValueArray['Words'];

    for LIndex := 0 to LWordArray.Count - 1 do
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
  LIndex, LIndex2: Integer;
  LName, LOpenToken, LCloseToken: string;
  LNewRange: TTextEditorRange;
  LNewKeyList: TTextEditorKeyList;
  LNewSet: TTextEditorSet;
  LSubRulesObject, LPropertiesObject, LTokenRangeObject: TJSONObject;
  LJSONObject, LJSONSubRulesObject: TJSONObject;
  LArrayValue: TJSONArray;
  LFileStream: TStream;
  LEditor: TCustomTextEditor;
  LElementPrefix: string;
begin
  if Assigned(ARangeObject) then
  begin
    LName := ARangeObject['File'].Value;
    if (hoMultiHighlighter in FHighlighter.Options) and (LName <> '') then
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
            for LIndex := 0 to LSubRulesObject.Count - 1 do
            begin
              if LSubRulesObject.Names[LIndex] = 'Range' then
              begin
                LArrayValue := LSubRulesObject.Items[LIndex].ArrayValue;
                for LIndex2 := 0 to LArrayValue.Count - 1 do
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

        if ARangeObject['AllowedCharacters'].Value <> '' then
          ARange.AllowedCharacters := ARangeObject['AllowedCharacters'].ToSet;

        if ARangeObject['Delimiters'].Value <> '' then
          ARange.Delimiters := ARangeObject['Delimiters'].ToSet;

        ARange.TokenType := StrToRangeType(ARangeObject['Type'].Value);

        LPropertiesObject := ARangeObject['Properties'].ObjectValue;

        if Assigned(LPropertiesObject) then
        begin
          with ARange do
          begin
            CloseOnEndOfLine := LPropertiesObject.ValueBoolean['CloseOnEndOfLine'];
            CloseOnTerm := LPropertiesObject.ValueBoolean['CloseOnTerm'];
            SkipWhitespace := LPropertiesObject.ValueBoolean['SkipWhitespace'];
            SkipWhitespaceOnce := LPropertiesObject.ValueBoolean['SkipWhitespaceOnce'];
            CloseParent := LPropertiesObject.ValueBoolean['CloseParent'];
            UseDelimitersForText := LPropertiesObject.ValueBoolean['UseDelimitersForText'];
            HereDocument := LPropertiesObject.ValueBoolean['HereDocument'];
          end;

          LArrayValue := LPropertiesObject['AlternativeClose'].ArrayValue;

          if LArrayValue.Count > 0 then
          begin
            ARange.AlternativeCloseArrayCount := LArrayValue.Count;

            for LIndex := 0 to ARange.AlternativeCloseArrayCount - 1 do
              ARange.AlternativeCloseArray[LIndex] := LArrayValue.Items[LIndex].Value;
          end;

          ARange.OpenBeginningOfLine := LPropertiesObject.ValueBoolean['OpenBeginningOfLine'];
          ARange.OpenEndOfLine := LPropertiesObject.ValueBoolean['OpenEndOfLine'];
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
      for LIndex := 0 to LSubRulesObject.Count - 1 do
      begin
        LName := LSubRulesObject.Names[LIndex];
        LArrayValue := LSubRulesObject.Items[LIndex].ArrayValue;

        if LName = 'Range' then
        for LIndex2 := 0 to LArrayValue.Count - 1 do
        begin
          LNewRange := TTextEditorRange.Create;
          ImportRange(LNewRange, LArrayValue.ValueObject[LIndex2], ARange); { ARange is for the MainRules include }
          ARange.AddRange(LNewRange);
        end
        else
        if LName = 'KeyList' then
        for LIndex2 := 0 to LArrayValue.Count - 1 do
        begin
          LNewKeyList := TTextEditorKeyList.Create;
          ImportKeyList(LNewKeyList, LArrayValue.ValueObject[LIndex2], AElementPrefix);
          ARange.AddKeyList(LNewKeyList);
        end
        else
        if LName = 'Set' then
        for LIndex2 := 0 to LArrayValue.Count - 1 do
        begin
          LNewSet := TTextEditorSet.Create;
          ImportSet(LNewSet, LArrayValue.ValueObject[LIndex2], AElementPrefix);
          ARange.AddSet(LNewSet);
        end
      end;
    end;
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportCompletionProposal(const ACompletionProposalObject: TJSONObject);
var
  LIndex: Integer;
  LSkipRegionItem: TTextEditorSkipRegionItem;
  LJSONDataValue: PJSONDataValue;
  LName: string;
  LEditor: TCustomTextEditor;
  LFileStream: TStream;
  LJSONObject: TJSONObject;
  LSkipRegionArray: TJSONArray;
begin
  if not Assigned(ACompletionProposalObject) then
    Exit;

  LSkipRegionArray := ACompletionProposalObject['SkipRegion'].ArrayValue;

  for LIndex := 0 to LSkipRegionArray.Count - 1 do
  begin
    LJSONDataValue := LSkipRegionArray.Items[LIndex];

    if hoMultiHighlighter in FHighlighter.Options then
    begin
      LName := LJSONDataValue.ObjectValue['File'].Value;

      if LName <> '' then
      begin
        LEditor := FHighlighter.Editor as TCustomTextEditor;
        LFileStream := LEditor.CreateHighlighterStream(LName);

        if Assigned(LFileStream) then
        begin
          LJSONObject := TJSONObject.ParseFromStream(LFileStream) as TJSONObject;

          if Assigned(LJSONObject) then
          try
            if LJSONObject.Contains('CompletionProposal') then
              ImportCompletionProposal(LJSONObject['CompletionProposal'].ObjectValue);
          finally
            LJSONObject.Free;
            LFileStream.Free;
          end;
        end;
      end;

      if FHighlighter.CompletionProposalSkipRegions.Contains(LJSONDataValue.ObjectValue['OpenToken'].Value, LJSONDataValue.ObjectValue['CloseToken'].Value) then
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
  LIndex: Integer;
  LVoidElementArray: TJSONArray;
  LJSONDataValue: PJSONDataValue;
begin
  if ACodeFoldingObject.Contains('VoidElements') then
  begin
    FHighlighter.CreateCodeFoldingVoidElements;

    FHighlighter.CodeFoldingVoidElements.BeginUpdate;
    try
      LVoidElementArray := ACodeFoldingObject['VoidElements'].ArrayValue;

      for LIndex := 0 to LVoidElementArray.Count - 1 do
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
  LIndex: Integer;
  LJSONDataValue: PJSONDataValue;
  LSkipRegionType: TTextEditorSkipRegionItemType;
  LRegionItem: TTextEditorCodeFoldingRegionItem;
  LSkipRegionItem: TTextEditorSkipRegionItem;
  LName: string;
  LEditor: TCustomTextEditor;
  LFileStream: TStream;
  LJSONObject: TJSONObject;
  LOpenToken, LCloseToken: string;
  LSkipRegionArray: TJSONArray;
begin
  if ACodeFoldingObject.Contains('SkipRegion') then
  begin
    LSkipRegionArray := ACodeFoldingObject['SkipRegion'].ArrayValue;

    for LIndex := 0 to LSkipRegionArray.Count - 1 do
    begin
      LJSONDataValue := LSkipRegionArray.Items[LIndex];

      LOpenToken := LJSONDataValue.ObjectValue['OpenToken'].Value;
      LCloseToken := LJSONDataValue.ObjectValue['CloseToken'].Value;

      if hoMultiHighlighter in FHighlighter.Options then
      begin
        LName := LJSONDataValue.ObjectValue['File'].Value;

        if LName <> '' then
        begin
          LEditor := FHighlighter.Editor as TCustomTextEditor;
          LFileStream := LEditor.CreateHighlighterStream(LName);

          if Assigned(LFileStream) then
          begin
            LJSONObject := TJSONObject.ParseFromStream(LFileStream) as TJSONObject;
            if Assigned(LJSONObject) then
            try
              if LJSONObject.Contains('CodeFolding') then
                ImportCodeFoldingSkipRegion(ACodeFoldingRegion, LJSONObject['CodeFolding']['Ranges'].ArrayValue.Items[0].ObjectValue);
            finally
              LJSONObject.Free;
              LFileStream.Free;
            end;
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

        if LCloseToken <> '' then
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
        end;

        if LOpenToken <> '' then
          FHighlighter.AddKeyChar(ctSkipOpen, LOpenToken[1]);

        if LCloseToken <> '' then
          FHighlighter.AddKeyChar(ctSkipClose, LCloseToken[1]);
      end;
    end;
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportCodeFoldingFoldRegion(const ACodeFoldingRegion: TTextEditorCodeFoldingRegion;
  const ACodeFoldingObject: TJSONObject);
var
  LIndex, LIndex2: Integer;
  LJSONDataValue: PJSONDataValue;
  LRegionItem: TTextEditorCodeFoldingRegionItem;
  LMemberObject: TJSONObject;
  LName: string;
  LEditor: TCustomTextEditor;
  LFileStream: TStream;
  LJSONObject: TJSONObject;
  LOpenToken, LCloseToken: string;
  LSkipIfFoundAfterOpenTokenArray: TJSONArray;
  LFoldRegionArray: TJSONArray;
begin
  if ACodeFoldingObject.Contains('FoldRegion') then
  begin
    LFoldRegionArray := ACodeFoldingObject['FoldRegion'].ArrayValue;

    for LIndex := 0 to LFoldRegionArray.Count - 1 do
    begin
      LJSONDataValue := LFoldRegionArray.Items[LIndex];
      LOpenToken := LJSONDataValue.ObjectValue['OpenToken'].Value;
      LCloseToken := LJSONDataValue.ObjectValue['CloseToken'].Value;

      if hoMultiHighlighter in FHighlighter.Options then
      begin
        LName := LJSONDataValue.ObjectValue['File'].Value;
        if LName <> '' then
        begin
          LEditor := FHighlighter.Editor as TCustomTextEditor;
          LFileStream := LEditor.CreateHighlighterStream(LName);
          if Assigned(LFileStream) then
          begin
            LJSONObject := TJSONObject.ParseFromStream(LFileStream) as TJSONObject;
            if Assigned(LJSONObject) then
            try
              if LJSONObject.Contains('CodeFolding') then
                ImportCodeFoldingFoldRegion(ACodeFoldingRegion, LJSONObject['CodeFolding']['Ranges'].ArrayValue.Items[0].ObjectValue);
            finally
              LJSONObject.Free;
              LFileStream.Free;
            end;
          end;
        end;

        if ACodeFoldingRegion.Contains(LOpenToken, LCloseToken) then
          Continue;
      end;

      LRegionItem := ACodeFoldingRegion.Add(LOpenToken, LCloseToken);

      LMemberObject := LJSONDataValue.ObjectValue['Properties'].ObjectValue;
      if Assigned(LMemberObject) then
      with LRegionItem do
      begin
        { Options }
        OpenTokenBeginningOfLine := LMemberObject.ValueBoolean['OpenTokenBeginningOfLine'];
        CloseTokenBeginningOfLine := LMemberObject.ValueBoolean['CloseTokenBeginningOfLine'];
        SharedClose := LMemberObject.ValueBoolean['SharedClose'];
        OpenIsClose := LMemberObject.ValueBoolean['OpenIsClose'];
        OpenTokenCanBeFollowedBy := LMemberObject['OpenTokenCanBeFollowedBy'].Value;
        TokenEndIsPreviousLine := LMemberObject.ValueBoolean['TokenEndIsPreviousLine'];
        NoDuplicateClose := LMemberObject.ValueBoolean['NoDuplicateClose'];
        NoSubs := LMemberObject.ValueBoolean['NoSubs'];
        BeginWithBreakChar := LMemberObject.ValueBoolean['BeginWithBreakChar'];

        LSkipIfFoundAfterOpenTokenArray := LMemberObject['SkipIfFoundAfterOpenToken'].ArrayValue;

        if LSkipIfFoundAfterOpenTokenArray.Count > 0 then
        begin
          SkipIfFoundAfterOpenTokenArrayCount := LSkipIfFoundAfterOpenTokenArray.Count;

          for LIndex2 := 0 to SkipIfFoundAfterOpenTokenArrayCount - 1 do
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

      if LOpenToken <> '' then
        FHighlighter.AddKeyChar(ctFoldOpen, LOpenToken[1]);

      if LRegionItem.BreakIfNotFoundBeforeNextRegion <> '' then
        FHighlighter.AddKeyChar(ctFoldOpen, LRegionItem.BreakIfNotFoundBeforeNextRegion[1]);

      if LCloseToken <> '' then
        FHighlighter.AddKeyChar(ctFoldClose, LCloseToken[1]);
    end;
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportCodeFolding(const ACodeFoldingObject: TJSONObject);
var
  LIndex, LRegionIndex: Integer;
  LCount, LRangeCount: Integer;
  LCodeFoldingObject, LObject: TJSONObject;
  LArray: TJSONArray;
  LEditor: TCustomTextEditor;
  LCodeFoldingRegion: TTextEditorCodeFoldingRegion;
  LEscapeChar, LStringEscapeChar: Char;
  LHideGuideLineAtFirstColumn: Boolean;
begin
  if not Assigned(ACodeFoldingObject) then
    Exit;

  LArray := ACodeFoldingObject['Ranges'].ArrayValue;
  LCount := LArray.Count;
  LHideGuideLineAtFirstColumn := False;

  if LCount > 0 then
  begin
    LRangeCount := 0;
    LEscapeChar := TControlCharacters.Null;
    LStringEscapeChar := TControlCharacters.Null;

    for LIndex := 0 to LCount - 1 do
    begin
      LCodeFoldingObject := LArray.Items[LIndex].ObjectValue;

      if LCodeFoldingObject.Contains('Options') then
      begin
        LObject := LCodeFoldingObject['Options'].ObjectValue;

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

    for LIndex := 0 to LCount - 1 do
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
  LEditor.CodeFolding.Visible := LCount > 0;
  LEditor.CodeFolding.GuideLines.SetOption(cfgHideAtFirstColumn, LHideGuideLineAtFirstColumn);
end;

procedure TTextEditorHighlighterImportJSON.ImportMatchingPair(const AMatchingPairObject: TJSONObject);
var
  LIndex: Integer;
  LTokenMatch: PTextEditorMatchingPairToken;
  LJSONDataValue: PJSONDataValue;
  LName: string;
  LEditor: TCustomTextEditor;
  LFileStream: TStream;
  LJSONObject: TJSONObject;
  LArray: TJSONArray;
begin
  if not Assigned(AMatchingPairObject) then
    Exit;

  LArray := AMatchingPairObject['Pairs'].ArrayValue;
  for LIndex := 0 to LArray.Count - 1 do
  begin
    LJSONDataValue := LArray.Items[LIndex];

    if hoMultiHighlighter in FHighlighter.Options then
    begin
      LName := LJSONDataValue.ObjectValue['File'].Value;
      if LName <> '' then
      begin
        LEditor := FHighlighter.Editor as TCustomTextEditor;
        LFileStream := LEditor.CreateHighlighterStream(LName);
        if Assigned(LFileStream) then
        begin
          LJSONObject := TJSONObject.ParseFromStream(LFileStream) as TJSONObject;
          if Assigned(LJSONObject) then
          try
            if LJSONObject.Contains('MatchingPair') then
              ImportMatchingPair(LJSONObject['MatchingPair'].ObjectValue);
          finally
            LJSONObject.Free;
            LFileStream.Free;
          end;
        end;
      end;
    end;

    New(LTokenMatch);
    LTokenMatch.OpenToken := LJSONDataValue.ObjectValue['OpenToken'].Value;
    LTokenMatch.CloseToken := LJSONDataValue.ObjectValue['CloseToken'].Value;
    FHighlighter.MatchingPairs.Add(LTokenMatch)
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportHighlighter(const AJSONObject: TJSONObject);
var
  LHighlighterObject: TJSONObject;
begin
  FHighlighter.Clear;

  LHighlighterObject := AJSONObject['Highlighter'];

  FHighlighter.SetOption(hoMultiHighlighter, LHighlighterObject.ValueBoolean['MultiHighlighter']);
  FHighlighter.ExludedWordBreakCharacters := LHighlighterObject.Values['ExcludedWordBreakCharacters'].ToSet;

  if LHighlighterObject.ValueBoolean['YAML'] then
    FHighlighter.BeforePrepare := FHighlighter.PrepareYAMLHighlighter
  else
    FHighlighter.BeforePrepare := nil;

  ImportSample(LHighlighterObject);
  ImportEditorProperties(LHighlighterObject['Editor'].ObjectValue);
  ImportRange(FHighlighter.MainRules, LHighlighterObject['MainRules'].ObjectValue);
  ImportCodeFolding(AJSONObject['CodeFolding'].ObjectValue);
  ImportMatchingPair(AJSONObject['MatchingPair'].ObjectValue);
  ImportCompletionProposal(AJSONObject['CompletionProposal'].ObjectValue);

  FHighlighter.Colors.AddElements;

  ImportHighlightLine(AJSONObject['HighlightLine'].ObjectValue);
end;

procedure TTextEditorHighlighterImportJSON.ImportHighlightLine(const AHighlightLineObject: TJSONObject);
var
  LArray: TJSONArray;
  LEditor: TCustomTextEditor;
  LFileStream: TStream;
  LIndex: Integer;
  LItem: TTextEditorHighlightLineItem;
  LJSONDataValue: PJSONDataValue;
  LJSONObject: TJSONObject;
  LName: string;
  LElement: string;
begin
  if not Assigned(AHighlightLineObject) then
    Exit;

  LArray := AHighlightLineObject['Items'].ArrayValue;

  for LIndex := 0 to LArray.Count - 1 do
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
        begin
          LJSONObject := TJSONObject.ParseFromStream(LFileStream) as TJSONObject;

          if Assigned(LJSONObject) then
          try
            if LJSONObject.Contains('HighlightLine') then
              ImportMatchingPair(LJSONObject['HighlightLine'].ObjectValue);
          finally
            LJSONObject.Free;
            LFileStream.Free;
          end;
        end;
      end;
    end;

    LEditor := FHighlighter.Editor as TCustomTextEditor;
    LEditor.HighlightLine.Active := True;

    LItem := LEditor.HighlightLine.Items.Add;

    LItem.Background := LJSONDataValue.ObjectValue['BackgroundColor'].ToColor;
    LItem.Foreground := LJSONDataValue.ObjectValue['ForegroundColor'].ToColor;

    { Currently only Method and MethodName elements supported for Makefile highlighter.
      Add more element support, if needed. }
    LElement := LJSONDataValue.ObjectValue['Element'].Value;

    if not LElement.IsEmpty then
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
