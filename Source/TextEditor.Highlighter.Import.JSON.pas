unit TextEditor.Highlighter.Import.JSON;

interface

uses
  System.Classes, System.SysUtils, TextEditor, TextEditor.CodeFolding.Regions, TextEditor.Highlighter,
  TextEditor.Highlighter.Attributes, TextEditor.Highlighter.Colors, TextEditor.Highlighter.Import.JSON.Parser,
  TextEditor.Highlighter.Rules, TextEditor.SkipRegions;

type
  TTextEditorHighlighterImportJSON = class(TObject)
  private
    FHighlighter: TTextEditorHighlighter;
    procedure ImportAttributes(const AHighlighterAttribute: TTextEditorHighlighterAttribute; const AAttributesObject: TJSONObject;
      const AElementPrefix: string);
    procedure ImportCodeFolding(const ACodeFoldingObject: TJSONObject);
    procedure ImportCodeFoldingFoldRegion(const ACodeFoldingRegion: TTextEditorCodeFoldingRegion; const ACodeFoldingObject: TJSONObject);
    procedure ImportCodeFoldingOptions(const ACodeFoldingRegion: TTextEditorCodeFoldingRegion; const ACodeFoldingObject: TJSONObject);
    procedure ImportCodeFoldingSkipRegion(const ACodeFoldingRegion: TTextEditorCodeFoldingRegion; const ACodeFoldingObject: TJSONObject);
    procedure ImportColors(const AJSONObject: TJSONObject; const AScaleFontHeight: Boolean = False);
    procedure ImportColorsEditorProperties(const AEditorObject: TJSONObject; const AScaleFontHeight: Boolean = False);
    procedure ImportCompletionProposal(const ACompletionProposalObject: TJSONObject);
    procedure ImportEditorProperties(const AEditorObject: TJSONObject);
    procedure ImportElements(const AColorsObject: TJSONObject);
    procedure ImportHighlighter(const AJSONObject: TJSONObject);
    procedure ImportKeyList(const AKeyList: TTextEditorKeyList; const AKeyListObject: TJSONObject; const AElementPrefix: string);
    procedure ImportMatchingPair(const AMatchingPairObject: TJSONObject);
    procedure ImportRange(const ARange: TTextEditorRange; const ARangeObject: TJSONObject; const AParentRange: TTextEditorRange = nil;
      const ASkipBeforeSubRules: Boolean = False; const AElementPrefix: string = '');
    procedure ImportSample(const AHighlighterObject: TJSONObject);
    procedure ImportSet(const ASet: TTextEditorSet; const ASetObject: TJSONObject; const AElementPrefix: string);
  public
    constructor Create(const AHighlighter: TTextEditorHighlighter); overload;
    procedure ImportFromStream(const AStream: TStream);
    procedure ImportColorsFromStream(const AStream: TStream; const AScaleFontHeight: Boolean = False);
  end;

  EJSONImportException = class(Exception);

implementation

uses
  System.TypInfo, System.UITypes, Vcl.Dialogs, Vcl.Forms, Vcl.Graphics, Vcl.GraphUtil, TextEditor.Consts,
  TextEditor.Highlighter.Token, TextEditor.Language, TextEditor.Types, TextEditor.Utils
{$IFDEF ALPHASKINS}, sCommonData{$ENDIF};

function StringToColorDef(const AString: string; const DefaultColor: TColor): Integer;
begin
  if System.SysUtils.Trim(AString) = '' then
    Result := DefaultColor
  else
  if FastPos('clWeb', AString) = 1 then
    Result := WebColorNameToColor(AString)
  else
    Result := StringToColor(AString);
end;

function StrToSet(const AString: string): TTextEditorCharSet;
var
  LIndex: Integer;
begin
  Result := [];
  for LIndex := 1 to Length(AString) do
    Result := Result + [AString[LIndex]];
end;

function StrToStrDef(const AString: string; const AStringDef: string): string;
begin
  if System.SysUtils.Trim(AString) = '' then
    Result := AStringDef
  else
    Result := AString
end;

function StrToFontStyle(const AString: string): TFontStyles;
begin
  Result := [];
  if FastPos('Bold', AString) > 0 then
    Include(Result, fsBold);
  if FastPos('Italic', AString) > 0 then
    Include(Result, fsItalic);
  if FastPos('Underline', AString) > 0 then
    Include(Result, fsUnderline);
  if FastPos('StrikeOut', AString) > 0 then
    Include(Result, fsStrikeOut);
end;

function StrToBreakType(const AString: string): TTextEditorBreakType;
begin
  if AString = 'Any' then
    Result := btAny
  else
  if (AString = 'Term') or (AString = '') then
    Result := btTerm
  else
    Result := btUnspecified;
end;

function StrToRegionType(const AString: string): TTextEditorSkipRegionItemType;
begin
  if AString = 'SingleLine' then
    Result := ritSingleLineComment
  else
  if AString = 'MultiLine' then
    Result := ritMultiLineComment
  else
  if AString = 'SingleLineString' then
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
    LEditor.CodeFolding.Outlining := StrToBoolDef(AEditorObject['Outlining'].Value, False);
    LEditor.CodeFolding.TextFolding.Active := LEditor.CodeFolding.Outlining or StrToBoolDef(AEditorObject['TextFolding'].Value, False);
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportColorsEditorProperties(const AEditorObject: TJSONObject; const AScaleFontHeight: Boolean = False);
var
  LColorsObject, LFontsObject, LFontSizesObject: TJSONObject;
  LEditor: TCustomTextEditor;
begin
  if Assigned(AEditorObject) and Assigned(FHighlighter.Editor) then
  begin
    LEditor := FHighlighter.Editor as TCustomTextEditor;
    LColorsObject := AEditorObject['Colors'].ObjectValue;
    if Assigned(LColorsObject) then
    begin
      LEditor.Colors.Background := StringToColorDef(LColorsObject['Background'].Value, LEditor.Colors.Background);
      LEditor.ActiveLine.Colors.Background := StringToColorDef(LColorsObject['ActiveLineBackground'].Value, LEditor.ActiveLine.Colors.Background);
      LEditor.ActiveLine.Colors.BackgroundUnfocused := StringToColorDef(LColorsObject['ActiveLineBackgroundUnfocused'].Value, LEditor.ActiveLine.Colors.Background);
      LEditor.ActiveLine.Colors.Foreground := StringToColorDef(LColorsObject['ActiveLineForeground'].Value, LEditor.ActiveLine.Colors.Foreground);
      LEditor.ActiveLine.Colors.ForegroundUnfocused := StringToColorDef(LColorsObject['ActiveLineForegroundUnfocused'].Value, LEditor.ActiveLine.Colors.Foreground);
      LEditor.Caret.MultiEdit.Colors.Background :=  StringToColorDef(LColorsObject['MultiEditBackground'].Value, LEditor.Caret.MultiEdit.Colors.Background);
      LEditor.Caret.MultiEdit.Colors.Foreground :=  StringToColorDef(LColorsObject['MultiEditForeground'].Value, LEditor.Caret.MultiEdit.Colors.Foreground);
      LEditor.CodeFolding.Colors.ActiveLineBackground := StringToColorDef(LColorsObject['CodeFoldingActiveLineBackground'].Value, LEditor.CodeFolding.Colors.ActiveLineBackground);
      LEditor.CodeFolding.Colors.ActiveLineBackgroundUnfocused := StringToColorDef(LColorsObject['CodeFoldingActiveLineBackgroundUnfocused'].Value, LEditor.CodeFolding.Colors.ActiveLineBackground);
      LEditor.CodeFolding.Colors.Background := StringToColorDef(LColorsObject['CodeFoldingBackground'].Value, LEditor.CodeFolding.Colors.Background);
      LEditor.CodeFolding.Colors.CollapsedLine := StringToColorDef(LColorsObject['CodeFoldingCollapsedLine'].Value, LEditor.CodeFolding.Colors.CollapsedLine);
      LEditor.CodeFolding.Colors.FoldingLine := StringToColorDef(LColorsObject['CodeFoldingFoldingLine'].Value, LEditor.CodeFolding.Colors.FoldingLine);
      LEditor.CodeFolding.Colors.FoldingLineHighlight := StringToColorDef(LColorsObject['CodeFoldingFoldingLineHighlight'].Value, LEditor.CodeFolding.Colors.FoldingLineHighlight);
      LEditor.CodeFolding.Colors.Indent := StringToColorDef(LColorsObject['CodeFoldingIndent'].Value, LEditor.CodeFolding.Colors.Indent);
      LEditor.CodeFolding.Colors.IndentHighlight := StringToColorDef(LColorsObject['CodeFoldingIndentHighlight'].Value, LEditor.CodeFolding.Colors.IndentHighlight);
      LEditor.CodeFolding.Hint.Colors.Background := StringToColorDef(LColorsObject['CodeFoldingHintBackground'].Value, LEditor.CodeFolding.Hint.Colors.Background);
      LEditor.CodeFolding.Hint.Colors.Border := StringToColorDef(LColorsObject['CodeFoldingHintBorder'].Value, LEditor.CodeFolding.Hint.Colors.Border);
      LEditor.CodeFolding.Hint.Font.Color := StringToColorDef(LColorsObject['CodeFoldingHintText'].Value, LEditor.CodeFolding.Hint.Font.Color);
      LEditor.CodeFolding.Hint.Indicator.Colors.Background := StringToColorDef(LColorsObject['CodeFoldingHintIndicatorBackground'].Value, LEditor.CodeFolding.Hint.Indicator.Colors.Background);
      LEditor.CodeFolding.Hint.Indicator.Colors.Border := StringToColorDef(LColorsObject['CodeFoldingHintIndicatorBorder'].Value, LEditor.CodeFolding.Hint.Indicator.Colors.Border);
      LEditor.CodeFolding.Hint.Indicator.Colors.Mark := StringToColorDef(LColorsObject['CodeFoldingHintIndicatorMark'].Value, LEditor.CodeFolding.Hint.Indicator.Colors.Mark);
      LEditor.CompletionProposal.Colors.Background := StringToColorDef(LColorsObject['CompletionProposalBackground'].Value, LEditor.CompletionProposal.Colors.Background);
      LEditor.CompletionProposal.Colors.Foreground := StringToColorDef(LColorsObject['CompletionProposalForeground'].Value, LEditor.CompletionProposal.Colors.Foreground);
      LEditor.CompletionProposal.Colors.SelectedBackground := StringToColorDef(LColorsObject['CompletionProposalSelectedBackground'].Value, LEditor.CompletionProposal.Colors.SelectedBackground);
      LEditor.CompletionProposal.Colors.SelectedText := StringToColorDef(LColorsObject['CompletionProposalSelectedText'].Value, LEditor.CompletionProposal.Colors.SelectedText);
      LEditor.LeftMargin.Colors.ActiveLineBackground := StringToColorDef(LColorsObject['LeftMarginActiveLineBackground'].Value, LEditor.LeftMargin.Colors.ActiveLineBackground);
      LEditor.LeftMargin.Colors.ActiveLineBackgroundUnfocused := StringToColorDef(LColorsObject['LeftMarginActiveLineBackgroundUnfocused'].Value, LEditor.LeftMargin.Colors.ActiveLineBackground);
      LEditor.LeftMargin.Colors.Background := StringToColorDef(LColorsObject['LeftMarginBackground'].Value, LEditor.LeftMargin.Colors.Background);
      LEditor.LeftMargin.Colors.Border := StringToColorDef(LColorsObject['LeftMarginBorder'].Value, LEditor.LeftMargin.Colors.Border);
      LEditor.LeftMargin.Colors.ActiveLineNumber := StringToColorDef(LColorsObject['LeftMarginActiveLineNumber'].Value, LEditor.LeftMargin.Colors.ActiveLineNumber);
      LEditor.LeftMargin.Colors.LineNumberLine := StringToColorDef(LColorsObject['LeftMarginLineNumberLine'].Value, LEditor.LeftMargin.Colors.LineNumberLine);
      LEditor.LeftMargin.Font.Color := StringToColorDef(LColorsObject['LeftMarginLineNumbers'].Value, LEditor.LeftMargin.Font.Color);
      LEditor.LeftMargin.Colors.BookmarkPanelBackground := StringToColorDef(LColorsObject['LeftMarginBookmarkPanel'].Value, LEditor.LeftMargin.Colors.BookmarkPanelBackground);
      LEditor.LeftMargin.Colors.LineStateModified := StringToColorDef(LColorsObject['LeftMarginLineStateModified'].Value, LEditor.LeftMargin.Colors.LineStateModified);
      LEditor.LeftMargin.Colors.LineStateNormal := StringToColorDef(LColorsObject['LeftMarginLineStateNormal'].Value, LEditor.LeftMargin.Colors.LineStateNormal);
      LEditor.Minimap.Colors.Background := StringToColorDef(LColorsObject['MinimapBackground'].Value, LEditor.Minimap.Colors.Background);
      LEditor.Minimap.Colors.Bookmark := StringToColorDef(LColorsObject['MinimapBookmark'].Value, LEditor.Minimap.Colors.Bookmark);
      LEditor.Minimap.Colors.VisibleLines := StringToColorDef(LColorsObject['MinimapVisibleLines'].Value, LEditor.Minimap.Colors.VisibleLines);
      LEditor.MatchingPairs.Colors.Matched := StringToColorDef(LColorsObject['MatchingPairMatched'].Value, LEditor.MatchingPairs.Colors.Matched);
      LEditor.MatchingPairs.Colors.Underline := StringToColorDef(LColorsObject['MatchingPairUnderline'].Value, LEditor.MatchingPairs.Colors.Underline);
      LEditor.MatchingPairs.Colors.Unmatched := StringToColorDef(LColorsObject['MatchingPairUnmatched'].Value, LEditor.MatchingPairs.Colors.Unmatched);
      LEditor.RightMargin.Colors.Margin := StringToColorDef(LColorsObject['RightMargin'].Value, LEditor.RightMargin.Colors.Margin);
      LEditor.RightMargin.Colors.MovingEdge := StringToColorDef(LColorsObject['RightMovingEdge'].Value, LEditor.RightMargin.Colors.MovingEdge);
      LEditor.Ruler.Colors.Background := StringToColorDef(LColorsObject['RulerBackground'].Value, LEditor.Ruler.Colors.Background);
      LEditor.Ruler.Colors.Border := StringToColorDef(LColorsObject['RulerBorder'].Value, LEditor.Ruler.Colors.Border);
      LEditor.Ruler.Colors.Lines := StringToColorDef(LColorsObject['RulerLines'].Value, LEditor.Ruler.Colors.Lines);
      LEditor.Ruler.Colors.MovingEdge := StringToColorDef(LColorsObject['RulerMovingEdge'].Value, LEditor.Ruler.Colors.MovingEdge);
      LEditor.Ruler.Colors.Selection := StringToColorDef(LColorsObject['RulerSelection'].Value, LEditor.Ruler.Colors.Selection);
      LEditor.Ruler.Font.Color := StringToColorDef(LColorsObject['RulerNumbers'].Value, LEditor.Ruler.Font.Color);
      LEditor.Search.Highlighter.Colors.Background := StringToColorDef(LColorsObject['SearchHighlighterBackground'].Value, LEditor.Search.Highlighter.Colors.Background);
      LEditor.Search.Highlighter.Colors.Border := StringToColorDef(LColorsObject['SearchHighlighterBorder'].Value, LEditor.Search.Highlighter.Colors.Border);
      LEditor.Search.Highlighter.Colors.Foreground := StringToColorDef(LColorsObject['SearchHighlighterForeground'].Value, LEditor.Search.Highlighter.Colors.Foreground);
      LEditor.Search.InSelection.Background := StringToColorDef(LColorsObject['SearchInSelectionBackground'].Value, LEditor.Search.InSelection.Background);
      LEditor.Search.Map.Colors.ActiveLine := StringToColorDef(LColorsObject['SearchMapActiveLine'].Value, LEditor.Search.Map.Colors.ActiveLine);
      LEditor.Search.Map.Colors.Background := StringToColorDef(LColorsObject['SearchMapBackground'].Value, LEditor.Search.Map.Colors.Background);
      LEditor.Search.Map.Colors.Foreground := StringToColorDef(LColorsObject['SearchMapForeground'].Value, LEditor.Search.Map.Colors.Foreground);
      LEditor.Selection.Colors.Background := StringToColorDef(LColorsObject['SelectionBackground'].Value, LEditor.Selection.Colors.Background);
      LEditor.Selection.Colors.Foreground := StringToColorDef(LColorsObject['SelectionForeground'].Value, LEditor.Selection.Colors.Foreground);
      LEditor.SyncEdit.Colors.Background := StringToColorDef(LColorsObject['SyncEditBackground'].Value, LEditor.SyncEdit.Colors.Background);
      LEditor.SyncEdit.Colors.EditBorder := StringToColorDef(LColorsObject['SyncEditEditBorder'].Value, LEditor.SyncEdit.Colors.EditBorder);
      LEditor.SyncEdit.Colors.WordBorder := StringToColorDef(LColorsObject['SyncEditWordBorder'].Value, LEditor.SyncEdit.Colors.WordBorder);
      LEditor.WordWrap.Colors.Arrow := StringToColorDef(LColorsObject['WordWrapIndicatorArrow'].Value, LEditor.WordWrap.Colors.Arrow);
      LEditor.WordWrap.Colors.Lines := StringToColorDef(LColorsObject['WordWrapIndicatorLines'].Value, LEditor.WordWrap.Colors.Lines);
      LEditor.WordWrap.CreateInternalBitmap;
    end;
    LFontsObject := AEditorObject['Fonts'].ObjectValue;
    if Assigned(LFontsObject) then
    begin
      LEditor.LeftMargin.Font.Name := StrToStrDef(LFontsObject['LineNumbers'].Value, LEditor.LeftMargin.Font.Name);
      LEditor.Font.Name := StrToStrDef(LFontsObject['Text'].Value, LEditor.Font.Name);
      LEditor.Minimap.Font.Name := StrToStrDef(LFontsObject['Minimap'].Value, LEditor.Minimap.Font.Name);
      LEditor.CodeFolding.Hint.Font.Name := StrToStrDef(LFontsObject['CodeFoldingHint'].Value, LEditor.CodeFolding.Hint.Font.Name);
      LEditor.CompletionProposal.Font.Name := StrToStrDef(LFontsObject['CompletionProposal'].Value, LEditor.CompletionProposal.Font.Name);
    end;
    LFontSizesObject := AEditorObject['FontSizes'].ObjectValue;
    if Assigned(LFontSizesObject) then
    begin
      LEditor.LeftMargin.Font.Size := StrToIntDef(LFontSizesObject['LineNumbers'].Value, LEditor.LeftMargin.Font.Size);
      LEditor.Minimap.Font.Size := StrToIntDef(LFontSizesObject['Minimap'].Value, LEditor.Minimap.Font.Size);
      LEditor.CodeFolding.Hint.Font.Size := StrToIntDef(LFontSizesObject['CodeFoldingHint'].Value, LEditor.CodeFolding.Hint.Font.Size);
      LEditor.CompletionProposal.Font.Size := StrToIntDef(LFontSizesObject['CompletionProposal'].Value, LEditor.CompletionProposal.Font.Size);
      LEditor.Font.Size := StrToIntDef(LFontSizesObject['Text'].Value, LEditor.Font.Size);
      LEditor.OriginalFontSize := LEditor.Font.Size;
      LEditor.OriginalLeftMarginFontSize := LEditor.LeftMargin.Font.Size;
{$IFDEF ALPHASKINS}
      if AScaleFontHeight then
      begin
        LEditor.LeftMargin.Font.Height := ScaleInt(LEditor.LeftMargin.Font.Height);
        LEditor.Minimap.Font.Height := ScaleInt(LEditor.LeftMargin.Font.Height);
        LEditor.CodeFolding.Hint.Font.Height := ScaleInt(LEditor.LeftMargin.Font.Height);
        LEditor.CompletionProposal.Font.Height := ScaleInt(LEditor.LeftMargin.Font.Height);
        LEditor.Font.Height := ScaleInt(LEditor.Font.Height);
      end;
{$ENDIF}
    end;
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportAttributes(const AHighlighterAttribute: TTextEditorHighlighterAttribute;
  const AAttributesObject: TJSONObject; const AElementPrefix: string);
begin
  if Assigned(AAttributesObject) then
  begin
    AHighlighterAttribute.Element := AElementPrefix + AAttributesObject['Element'].Value;
    AHighlighterAttribute.ParentForeground := StrToBoolDef(AAttributesObject['ParentForeground'].Value, False);
    AHighlighterAttribute.ParentBackground := StrToBoolDef(AAttributesObject['ParentBackground'].Value, True);
    if AAttributesObject.Contains('EscapeChar') then
      AHighlighterAttribute.EscapeChar := AAttributesObject['EscapeChar'].Value[1];
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
    ASet.CharSet := StrToSet(ASetObject['Symbols'].Value);
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
        if ARangeObject['Delimiters'].Value <> '' then
          ARange.Delimiters := StrToSet(ARangeObject['Delimiters'].Value);
        ARange.TokenType := StrToRangeType(ARangeObject['Type'].Value);

        LPropertiesObject := ARangeObject['Properties'].ObjectValue;
        if Assigned(LPropertiesObject) then
        begin
          ARange.CloseOnEndOfLine := LPropertiesObject.ValueBoolean['CloseOnEndOfLine'];
          ARange.CloseOnTerm := LPropertiesObject.ValueBoolean['CloseOnTerm'];
          ARange.SkipWhitespace := LPropertiesObject.ValueBoolean['SkipWhitespace'];
          ARange.CloseParent := LPropertiesObject.ValueBoolean['CloseParent'];
          ARange.UseDelimitersForText := LPropertiesObject.ValueBoolean['UseDelimitersForText'];
          ARange.HereDocument := LPropertiesObject.ValueBoolean['HereDocument'];

          LArrayValue := LPropertiesObject['AlternativeClose'].ArrayValue;
          if LArrayValue.Count > 0 then
          begin
            ARange.AlternativeCloseArrayCount := LArrayValue.Count;
            for LIndex := 0 to ARange.AlternativeCloseArrayCount - 1 do
              ARange.AlternativeCloseArray[LIndex] := LArrayValue.Items[LIndex].Value;
          end;
          ARange.OpenBeginningOfLine := LPropertiesObject.ValueBoolean['OpenBeginningOfLine'];
        end;

        ARange.OpenToken.Clear;
        ARange.OpenToken.BreakType := btUnspecified;
        ARange.CloseToken.Clear;
        ARange.CloseToken.BreakType := btUnspecified;

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
  { Skip regions }
  LSkipRegionArray := ACompletionProposalObject['SkipRegion'].ArrayValue;
  for LIndex := 0 to LSkipRegionArray.Count - 1 do
  begin
    LJSONDataValue := LSkipRegionArray.Items[LIndex];

    if hoMultiHighlighter in FHighlighter.Options then
    begin
      { Multi highlighter code folding skip region include }
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
      { Skip duplicates }
      if FHighlighter.CompletionProposalSkipRegions.Contains(LJSONDataValue.ObjectValue['OpenToken'].Value, LJSONDataValue.ObjectValue['CloseToken'].Value) then
        Continue;
    end;

    LSkipRegionItem := FHighlighter.CompletionProposalSkipRegions.Add(LJSONDataValue.ObjectValue['OpenToken'].Value,
      LJSONDataValue.ObjectValue['CloseToken'].Value);
    LSkipRegionItem.RegionType := StrToRegionType(LJSONDataValue.ObjectValue['RegionType'].Value);
    LSkipRegionItem.SkipEmptyChars := LJSONDataValue.ObjectValue.ValueBoolean['SkipEmptyChars'];
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
        { Multi highlighter code folding skip region include }
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
        { Skip duplicates }
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
        LSkipRegionItem.RegionType := LSkipRegionType;
        LSkipRegionItem.SkipEmptyChars := LJSONDataValue.ObjectValue.ValueBoolean['SkipEmptyChars'];
        LSkipRegionItem.SkipIfNextCharIsNot := TEXT_EDITOR_NONE_CHAR;
        if LJSONDataValue.ObjectValue.Contains('NextCharIsNot') then
          LSkipRegionItem.SkipIfNextCharIsNot := LJSONDataValue.ObjectValue['NextCharIsNot'].Value[1];
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
        { Multi highlighter code folding fold region include }
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
        { Skip duplicates }
        if ACodeFoldingRegion.Contains(LOpenToken, LCloseToken) then
          Continue;
      end;

      LRegionItem := ACodeFoldingRegion.Add(LOpenToken, LCloseToken);

      LMemberObject := LJSONDataValue.ObjectValue['Properties'].ObjectValue;
      if Assigned(LMemberObject) then
      begin
        { Options }
        LRegionItem.OpenTokenBeginningOfLine := LMemberObject.ValueBoolean['OpenTokenBeginningOfLine'];
        LRegionItem.CloseTokenBeginningOfLine := LMemberObject.ValueBoolean['CloseTokenBeginningOfLine'];
        LRegionItem.SharedClose := LMemberObject.ValueBoolean['SharedClose'];
        LRegionItem.OpenIsClose := LMemberObject.ValueBoolean['OpenIsClose'];
        LRegionItem.OpenTokenCanBeFollowedBy := LMemberObject['OpenTokenCanBeFollowedBy'].Value;
        LRegionItem.TokenEndIsPreviousLine := LMemberObject.ValueBoolean['TokenEndIsPreviousLine'];
        LRegionItem.NoDuplicateClose := LMemberObject.ValueBoolean['NoDuplicateClose'];
        LRegionItem.NoSubs := LMemberObject.ValueBoolean['NoSubs'];
        LRegionItem.BeginWithBreakChar := LMemberObject.ValueBoolean['BeginWithBreakChar'];

        LSkipIfFoundAfterOpenTokenArray := LMemberObject['SkipIfFoundAfterOpenToken'].ArrayValue;
        if LSkipIfFoundAfterOpenTokenArray.Count > 0 then
        begin
          LRegionItem.SkipIfFoundAfterOpenTokenArrayCount := LSkipIfFoundAfterOpenTokenArray.Count;
          for LIndex2 := 0 to LRegionItem.SkipIfFoundAfterOpenTokenArrayCount - 1 do
            LRegionItem.SkipIfFoundAfterOpenTokenArray[LIndex2] := LSkipIfFoundAfterOpenTokenArray.Items[LIndex2].Value;
        end;

        if LMemberObject.Contains('BreakCharFollows') then
          LRegionItem.BreakCharFollows := LMemberObject.ValueBoolean['BreakCharFollows'];
        LRegionItem.BreakIfNotFoundBeforeNextRegion := LMemberObject['BreakIfNotFoundBeforeNextRegion'].Value;
        LRegionItem.OpenTokenEnd := LMemberObject['OpenTokenEnd'].Value;
        LRegionItem.ShowGuideLine := StrToBoolDef(LMemberObject['ShowGuideLine'].Value, True);
        LRegionItem.OpenTokenBreaksLine := LMemberObject.ValueBoolean['OpenTokenBreaksLine'];
        LRegionItem.RemoveRange := LMemberObject.ValueBoolean['RemoveRange'];
        LRegionItem.CheckIfThenOneLiner := LMemberObject.ValueBoolean['CheckIfThenOneLiner'];
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

procedure TTextEditorHighlighterImportJSON.ImportCodeFoldingOptions(const ACodeFoldingRegion: TTextEditorCodeFoldingRegion;
  const ACodeFoldingObject: TJSONObject);
var
  LCodeFoldingObject: TJSONObject;
begin
  FHighlighter.MatchingPairHighlight := True;

  if ACodeFoldingObject.Contains('Options') then
  begin
    LCodeFoldingObject := ACodeFoldingObject['Options'].ObjectValue;

    if LCodeFoldingObject.Contains('OpenToken') then
      ACodeFoldingRegion.OpenToken := LCodeFoldingObject['OpenToken'].Value;

    if LCodeFoldingObject.Contains('CloseToken') then
      ACodeFoldingRegion.CloseToken := LCodeFoldingObject['CloseToken'].Value;

    if LCodeFoldingObject.Contains('EscapeChar') then
      ACodeFoldingRegion.EscapeChar := LCodeFoldingObject['EscapeChar'].Value[1];

    if LCodeFoldingObject.Contains('FoldTags') then
      ACodeFoldingRegion.FoldTags := LCodeFoldingObject.ValueBoolean['FoldTags'];

    if LCodeFoldingObject.Contains('StringEscapeChar') then
      ACodeFoldingRegion.StringEscapeChar := LCodeFoldingObject['StringEscapeChar'].Value[1];

    if LCodeFoldingObject.Contains('MatchingPairHighlight') then
      FHighlighter.MatchingPairHighlight := LCodeFoldingObject.ValueBoolean['MatchingPairHighlight'];
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportCodeFolding(const ACodeFoldingObject: TJSONObject);
var
  LIndex, LCount: Integer;
  LCodeFoldingObject: TJSONObject;
  LArray: TJSONArray;
begin
  if not Assigned(ACodeFoldingObject) then
    Exit;
  LArray := ACodeFoldingObject['Ranges'].ArrayValue;
  LCount := LArray.Count;
  if LCount > 0 then
  begin
    FHighlighter.CodeFoldingRangeCount := LCount;
    for LIndex := 0 to LCount - 1 do
    begin
      FHighlighter.CodeFoldingRegions[LIndex] := TTextEditorCodeFoldingRegion.Create(TTextEditorCodeFoldingRegionItem);
      LCodeFoldingObject := LArray.Items[LIndex].ObjectValue;

      ImportCodeFoldingOptions(FHighlighter.CodeFoldingRegions[LIndex], LCodeFoldingObject);
      ImportCodeFoldingSkipRegion(FHighlighter.CodeFoldingRegions[LIndex], LCodeFoldingObject);
      ImportCodeFoldingFoldRegion(FHighlighter.CodeFoldingRegions[LIndex], LCodeFoldingObject);
    end;
  end;
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
  { Matching token pairs }
  LArray := AMatchingPairObject['Pairs'].ArrayValue;
  for LIndex := 0 to LArray.Count - 1 do
  begin
    LJSONDataValue := LArray.Items[LIndex];

    if hoMultiHighlighter in FHighlighter.Options then
    begin
      { Multi highlighter code folding fold region include }
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

procedure TTextEditorHighlighterImportJSON.ImportElements(const AColorsObject: TJSONObject);
var
  LIndex: Integer;
  LElement: PTextEditorHighlighterElement;
  LJSONDataValue: PJSONDataValue;
  LElementsArray: TJSONArray;
  LEditor: TCustomTextEditor;
begin
  if not Assigned(AColorsObject) then
    Exit;

  LEditor := nil;
  if Assigned(FHighlighter.Editor) then
    LEditor := FHighlighter.Editor as TCustomTextEditor;

  LElementsArray :=  AColorsObject['Elements'].ArrayValue;
  for LIndex := 0 to LElementsArray.Count - 1 do
  begin
    LJSONDataValue := LElementsArray.Items[LIndex];
    New(LElement);
    LElement.Background := StringToColorDef(LJSONDataValue.ObjectValue['Background'].Value, TColors.SysWindow);
    LElement.Foreground := StringToColorDef(LJSONDataValue.ObjectValue['Foreground'].Value, TColors.SysWindowText);
    LElement.Name := LJSONDataValue.ObjectValue['Name'].Value;
    LElement.FontStyles := StrToFontStyle(LJSONDataValue.ObjectValue['Style'].Value);
    FHighlighter.Colors.Styles.Add(LElement);

    if Assigned(LEditor) then
    begin
      if LElement.Name = 'Editor' then
        LEditor.Colors.Foreground := LElement.Foreground;
      if LElement.Name = 'ReservedWord' then
        LEditor.Colors.ReservedWord := LElement.Foreground;
    end;
  end;
end;

procedure TTextEditorHighlighterImportJSON.ImportHighlighter(const AJSONObject: TJSONObject);
var
  LHighlighterObject: TJSONObject;
begin
  FHighlighter.Clear;

  LHighlighterObject := AJSONObject['Highlighter'];

  FHighlighter.SetOption(hoMultiHighlighter, LHighlighterObject.ValueBoolean['MultiHighlighter']);
  FHighlighter.ExludedWordBreakCharacters := StrToSet(LHighlighterObject.ValueString['ExcludedWordBreakCharacters']);

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
end;

procedure TTextEditorHighlighterImportJSON.ImportColors(const AJSONObject: TJSONObject; const AScaleFontHeight: Boolean = False);
var
  LColorsObject: TJSONObject;
begin
  FHighlighter.Colors.Clear;

  LColorsObject := AJSONObject['Colors'];
  ImportColorsEditorProperties(LColorsObject['Editor'].ObjectValue, AScaleFontHeight);
  ImportElements(AJSONObject['Colors'].ObjectValue);
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

procedure TTextEditorHighlighterImportJSON.ImportColorsFromStream(const AStream: TStream; const AScaleFontHeight: Boolean = False);
var
  LJSONObject: TJSONObject;
begin
  try
    LJSONObject := TJSONObject.ParseFromStream(AStream) as TJSONObject;
    if Assigned(LJSONObject) then
    try
      ImportColors(LJSONObject, AScaleFontHeight);
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
