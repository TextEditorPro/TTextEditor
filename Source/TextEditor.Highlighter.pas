{$WARN WIDECHAR_REDUCED OFF} // CharInSet is slow in loops
unit TextEditor.Highlighter;

interface

uses
  System.Classes, System.SysUtils, Vcl.Controls, Vcl.Graphics, TextEditor.CodeFolding.Regions, TextEditor.Consts,
  TextEditor.Highlighter.Attributes, TextEditor.Highlighter.Colors, TextEditor.Highlighter.Comments,
  TextEditor.Highlighter.Rules, TextEditor.Highlighter.Token, TextEditor.Lines, TextEditor.SkipRegions,
  TextEditor.Types;

type
  TTextEditorHighlighter = class(TObject)
  strict private
    FAllDelimiters: TTextEditorCharSet;
    FAttributes: TStringList;
    FBeforePrepare: TTextEditorHighlighterPrepare;
    FBeginningOfLine: Boolean;
    FChanged: Boolean;
    FCodeFoldingRangeCount: Integer;
    FCodeFoldingRegions: TTextEditorCodeFoldingRegions;
    FColors: TTextEditorHighlighterColors;
    FComments: TTextEditorHighlighterComments;
    FCompletionProposalSkipRegions: TTextEditorSkipRegions;
    FEditor: TWinControl;
    FEndOfLine: Boolean;
    FExludedWordBreakCharacters: TTextEditorCharSet;
    FFoldCloseKeyChars: TTextEditorCharSet;
    FFoldKeyChars: TTextEditorCharSet;
    FFoldOpenKeyChars: TTextEditorCharSet;
    FFoldTags: Boolean;
    FLine: PChar;
    FLines: TTextEditorLines;
    FLoaded: Boolean;
    FLoading: Boolean;
    FMainRules: TTextEditorRange;
    FMatchingPairHighlight: Boolean;
    FMatchingPairs: TList;
    FName: string;
    FOptions: TTextEditorHighlighterOptions;
    FPreviousEndOfLine: Boolean;
    FRange: TTextEditorRange;
    FRightToLeftToken: Boolean;
    FRunPosition: Integer;
    FSample: string;
    FSkipCloseKeyChars: TTextEditorCharSet;
    FSkipOpenKeyChars: TTextEditorCharSet;
    FTemporaryTokens: TList;
    FToken: TTextEditorToken;
    FTokenPosition: Integer;
    procedure AddAllAttributes(const ARange: TTextEditorRange);
    procedure FreeTemporaryTokens;
    procedure UpdateAttributes(const ARange: TTextEditorRange; const AParentRange: TTextEditorRange);
  protected
    function GetAttribute(const AIndex: Integer): TTextEditorHighlighterAttribute;
    procedure AddAttribute(const AHighlighterAttribute: TTextEditorHighlighterAttribute);
    procedure Prepare;
    procedure Reset;
    procedure SetCodeFoldingRangeCount(const AValue: Integer);
  public
    constructor Create(AOwner: TWinControl);
    destructor Destroy; override;
    function RangeAttribute: TTextEditorHighlighterAttribute;
    function TokenAttribute: TTextEditorHighlighterAttribute;
    function TokenLength: Integer;
    function TokenType: TTextEditorRangeType;
    procedure AddKeyChar(const AKeyCharType: TTextEditorKeyCharType; const AChar: Char);
    procedure Clear;
    procedure GetKeywords(var AStringList: TStringList);
    procedure GetToken(var AResult: string);
    procedure LoadFromFile(const AFilename: string);
    procedure LoadFromStream(const AStream: TStream);
    procedure Next;
    procedure NextToEndOfLine;
    procedure PrepareYAMLHighlighter;
    procedure ResetRange;
    procedure SetLine(const AValue: string);
    procedure SetOption(const AOption: TTextEditorHighlighterOption; const AEnabled: Boolean);
    procedure SetRange(const AValue: Pointer);
    procedure UpdateColors;
    property Attribute[const AIndex: Integer]: TTextEditorHighlighterAttribute read GetAttribute;
    property Attributes: TStringList read FAttributes;
    property BeforePrepare: TTextEditorHighlighterPrepare read FBeforePrepare write FBeforePrepare;
    property Changed: Boolean read FChanged write FChanged default False;
    property CodeFoldingRangeCount: Integer read FCodeFoldingRangeCount write SetCodeFoldingRangeCount;
    property CodeFoldingRegions: TTextEditorCodeFoldingRegions read FCodeFoldingRegions write FCodeFoldingRegions;
    property Colors: TTextEditorHighlighterColors read FColors write FColors;
    property Comments: TTextEditorHighlighterComments read FComments write FComments;
    property CompletionProposalSkipRegions: TTextEditorSkipRegions read FCompletionProposalSkipRegions write FCompletionProposalSkipRegions;
    property Editor: TWinControl read FEditor;
    property EndOfLine: Boolean read FEndOfLine;
    property ExludedWordBreakCharacters: TTextEditorCharSet read FExludedWordBreakCharacters write FExludedWordBreakCharacters;
    property FoldCloseKeyChars: TTextEditorCharSet read FFoldCloseKeyChars write FFoldCloseKeyChars;
    property FoldKeyChars: TTextEditorCharSet read FFoldKeyChars write FFoldKeyChars;
    property FoldOpenKeyChars: TTextEditorCharSet read FFoldOpenKeyChars write FFoldOpenKeyChars;
    property FoldTags: Boolean read FFoldTags write FFoldTags default False;
    property Lines: TTextEditorLines read FLines write FLines;
    property Loaded: Boolean read FLoaded write FLoaded;
    property Loading: Boolean read FLoading write FLoading;
    property MainRules: TTextEditorRange read FMainRules;
    property MatchingPairHighlight: Boolean read FMatchingPairHighlight write FMatchingPairHighlight default True;
    property MatchingPairs: TList read FMatchingPairs write FMatchingPairs;
    property Name: string read FName write FName;
    property Options: TTextEditorHighlighterOptions read FOptions write FOptions;
    property Range: TTextEditorRange read FRange;
    property RightToLeftToken: Boolean read FRightToLeftToken write FRightToLeftToken;
    property Sample: string read FSample write FSample;
    property SkipCloseKeyChars: TTextEditorCharSet read FSkipCloseKeyChars write FSkipCloseKeyChars;
    property SkipOpenKeyChars: TTextEditorCharSet read FSkipOpenKeyChars write FSkipOpenKeyChars;
    property TokenPosition: Integer read FTokenPosition;
  end;

implementation

uses
  System.Types, TextEditor, TextEditor.Highlighter.Import.JSON, TextEditor.Utils;

procedure TTextEditorHighlighter.AddKeyChar(const AKeyCharType: TTextEditorKeyCharType; const AChar: Char);
begin
  case AKeyCharType of
    ctFoldOpen:
      begin
        FFoldOpenKeyChars := FFoldOpenKeyChars + [AChar];
        FFoldKeyChars := FFoldKeyChars + [AChar];
      end;
    ctFoldClose:
      begin
        FFoldCloseKeyChars := FFoldCloseKeyChars + [AChar];
        FFoldKeyChars := FFoldKeyChars + [AChar];
      end;
    ctSkipOpen: FSkipOpenKeyChars := FSkipOpenKeyChars + [AChar];
    ctSkipClose: FSkipCloseKeyChars := FSkipCloseKeyChars + [AChar];
  end;
end;

constructor TTextEditorHighlighter.Create(AOwner: TWinControl);
begin
  inherited Create;

  FEditor := AOwner;
  FChanged := False;
  FRightToLeftToken := False;

  FAttributes := TStringList.Create;
  FAttributes.Duplicates := dupIgnore;
  FAttributes.Sorted := False;

  FCodeFoldingRangeCount := 0;

  FComments := TTextEditorHighlighterComments.Create;

  FCompletionProposalSkipRegions := TTextEditorSkipRegions.Create(TTextEditorSkipRegionItem);

  FMainRules := TTextEditorRange.Create;
  FMainRules.Parent := FMainRules;

  FEndOfLine := False;
  FBeginningOfLine := True;
  FPreviousEndOfLine := False;
  FRange := MainRules;

  FColors := TTextEditorHighlighterColors.Create(Self);
  FMatchingPairs := TList.Create;

  FTemporaryTokens := TList.Create;

  FAllDelimiters := TCharacterSets.DefaultDelimiters + TCharacterSets.AbsoluteDelimiters;

  FLoading := False;
  FLoaded := False;

  FExludedWordBreakCharacters := [];
end;

destructor TTextEditorHighlighter.Destroy;
begin
  Clear;

  FComments.Free;
  FComments := nil;
  FMainRules.Free;
  FMainRules := nil;
  FAttributes.Free;
  FAttributes := nil;
  FCompletionProposalSkipRegions.Free;
  FCompletionProposalSkipRegions := nil;
  FMatchingPairs.Free;
  FMatchingPairs := nil;
  FColors.Free;
  FColors := nil;
  FreeTemporaryTokens;
  FTemporaryTokens.Free;
  FTemporaryTokens := nil;

  inherited;
end;

procedure TTextEditorHighlighter.AddAllAttributes(const ARange: TTextEditorRange);
var
  LIndex: Integer;
begin
  AddAttribute(ARange.Attribute);
  for LIndex := 0 to ARange.KeyListCount - 1 do
    AddAttribute(ARange.KeyList[LIndex].Attribute);
  for LIndex := 0 to ARange.SetCount - 1 do
    AddAttribute(ARange.Sets[LIndex].Attribute);
  for LIndex := 0 to ARange.RangeCount - 1 do
    AddAllAttributes(ARange.Ranges[LIndex]);
end;

procedure TTextEditorHighlighter.SetLine(const AValue: string);
begin
  if hoExecuteBeforePrepare in Options then
  begin
    if Assigned(FBeforePrepare) then
      FBeforePrepare;
    Prepare;
  end
  else
  if Assigned(FRange) then
    if not FRange.Prepared then
      Prepare;

  FLine := PChar(AValue);
  FRunPosition := 0;
  FTokenPosition := 0;
  FEndOfLine := False;
  FBeginningOfLine := True;
  FPreviousEndOfLine := False;
  FRightToLeftToken := False;
  FToken := nil;
  Next;
end;

procedure TTextEditorHighlighter.FreeTemporaryTokens;
var
  LIndex: Integer;
  LToken: TTextEditorToken;
begin
  for LIndex := FTemporaryTokens.Count - 1 downto 0 do
  begin
    LToken := TTextEditorToken(FTemporaryTokens[LIndex]);
    LToken.Free;
    FTemporaryTokens.Delete(LIndex);
  end;
end;

procedure TTextEditorHighlighter.Next;
var
  LIndex, LPosition: Integer;
  LParser: TTextEditorAbstractParser;
  LKeyword: PChar;
  LCloseParent: Boolean;
  LDelimiters: TTextEditorCharSet;
begin
  FreeTemporaryTokens;

  if FPreviousEndOfLine then
  begin
    while Assigned(FRange) and (FRange.CloseOnEndOfLine or FRange.CloseOnTerm) do
      FRange := FRange.Parent;

    FEndOfLine := True;

    Exit;
  end;

  if Assigned(FRange) and (FRange.AlternativeCloseArrayCount > 0) then
  for LIndex := 0 to FRange.AlternativeCloseArrayCount - 1 do
  begin
    LKeyword := PChar(FRange.AlternativeCloseArray[LIndex]);
    LPosition := FRunPosition;

    while (FLine[LPosition] <> TControlCharacters.Null) and (FLine[LPosition] = LKeyword^) do
    begin
      Inc(LKeyword);
      Inc(LPosition);
    end;

    if LKeyword^ = TControlCharacters.Null then
    begin
      FRange := FRange.Parent;

      Break;
    end;
  end;

  FTokenPosition := FRunPosition;

  if Assigned(FRange) then
  begin
    LCloseParent := FRange.CloseParent;
    if FRange.CloseOnTerm and (FLine[FRunPosition] in FRange.Delimiters) and
      not (FRange.SkipWhitespace and (FLine[FRunPosition] in TCharacterSets.AbsoluteDelimiters)) then
    begin
      FRange := FRange.Parent;
      if Assigned(FRange) then
        if LCloseParent then
          FRange := FRange.Parent;
    end;

    if Ord(FLine[FRunPosition]) < TCharacters.AnsiCharCount then
      LParser := FRange.SymbolList[AnsiChar(FRange.CaseFunct(FLine[FRunPosition]))]
    else
    case FLine[FRunPosition] of
    { Turkish special characters }
      'ç', 'Ç':
        LParser := FRange.SymbolList['C'];
      'ı', 'İ':
        LParser := FRange.SymbolList['I'];
      'ş', 'Ş':
        LParser := FRange.SymbolList['S'];
      'ğ', 'Ğ':
        LParser := FRange.SymbolList['G'];
    else
      LParser := FRange.SymbolList['a'];
    end;

    FRightToLeftToken := False;

    if not Assigned(LParser) then
      Inc(FRunPosition)
    else
    if not LParser.GetToken(FRange, FLine, FRunPosition, FToken) then
    begin
      FToken := FRange.DefaultToken;

      if FRange.UseDelimitersForText then
        LDelimiters := FRange.Delimiters + [TControlCharacters.Null]
      else
        LDelimiters := FAllDelimiters;

      if IsRightToLeftCharacter(FLine[FRunPosition], False) then
      begin
        FRightToLeftToken := True;

        while IsRightToLeftCharacter(FLine[FRunPosition]) do
          Inc(FRunPosition);

        while (FRunPosition > 1) and (FLine[FRunPosition - 1] in [TControlCharacters.Tab, TCharacters.Space]) do
          Dec(FRunPosition);
      end
      else
      while not (FLine[FRunPosition] in LDelimiters) do
        Inc(FRunPosition);
    end
    else
    if FRange.ClosingToken = FToken then
      FRange := FRange.Parent
    else
    if Assigned(FToken) and Assigned(FToken.OpenRule) and (FToken.OpenRule is TTextEditorRange) then
    begin
      FRange := TTextEditorRange(FToken.OpenRule);
      FRange.ClosingToken := FToken.ClosingToken;

      if FRange.OpenBeginningOfLine and not FBeginningOfLine then
      begin
        FRange := FRange.Parent;
        FToken := FRange.DefaultToken;
      end;
    end;

    if Assigned(FToken) and FToken.Temporary then
      FTemporaryTokens.Add(FToken);
  end;

  if FBeginningOfLine and (FRunPosition >= 1) and not (FLine[FRunPosition - 1] in TCharacterSets.AbsoluteDelimiters) then
    FBeginningOfLine := False;

  if FLine[FRunPosition] = TControlCharacters.Null then
    FPreviousEndOfLine := True;
end;

function TTextEditorHighlighter.RangeAttribute: TTextEditorHighlighterAttribute;
begin
  Result := nil;
  if Assigned(FRange) then
    Result := FRange.Attribute;
end;

function TTextEditorHighlighter.TokenAttribute: TTextEditorHighlighterAttribute;
begin
  if Assigned(FToken) then
    Result := FToken.Attribute
  else
    Result := nil;
end;

procedure TTextEditorHighlighter.ResetRange;
begin
  FRange := MainRules;
end;

procedure TTextEditorHighlighter.SetCodeFoldingRangeCount(const AValue: Integer);
begin
  if FCodeFoldingRangeCount <> AValue then
  begin
    SetLength(FCodeFoldingRegions, AValue);
    FCodeFoldingRangeCount := AValue;
  end;
end;

procedure TTextEditorHighlighter.SetRange(const AValue: Pointer);
begin
  FRange := TTextEditorRange(AValue);
end;

procedure TTextEditorHighlighter.GetKeywords(var AStringList: TStringList);
var
  LIndex, LIndex2: Integer;
  LKeyList: TTextEditorKeyList;
begin
  if not Assigned(AStringList) then
    Exit;

  for LIndex := 0 to FMainRules.KeyListCount - 1 do
  begin
    LKeyList := FMainRules.KeyList[LIndex];

    for LIndex2 := 0 to LKeyList.KeyList.Count - 1 do
      AStringList.Add(LKeyList.KeyList[LIndex2]);
  end;
end;

procedure TTextEditorHighlighter.GetToken(var AResult: string);
var
  LLength: Integer;
begin
  LLength := FRunPosition - FTokenPosition;
  SetString(AResult, FLine + FTokenPosition, LLength);
end;

procedure TTextEditorHighlighter.Reset;
begin
  MainRules.Reset;
end;

function TTextEditorHighlighter.TokenType: TTextEditorRangeType;
var
  LIndex: Integer;
  LToken: string;
  LTokenType: TTextEditorRangeType;
  LRangeKeyList: TTextEditorKeyList;
begin
  LTokenType := FRange.TokenType;

  if LTokenType <> ttUnspecified then
    Result := LTokenType
  else
  { keyword token type }
  begin
    GetToken(LToken);

    for LIndex := 0 to FRange.KeyListCount - 1 do
    begin
      LRangeKeyList := FRange.KeyList[LIndex];

      if LRangeKeyList.KeyList.IndexOf(LToken) <> -1 then
        Exit(LRangeKeyList.TokenType);
    end;

    Result := ttUnspecified
  end;
end;

procedure TTextEditorHighlighter.Clear;
var
  LIndex: Integer;
begin
  FFoldTags := False;
  FMatchingPairHighlight := True;
  FFoldKeyChars := [#0];
  FFoldOpenKeyChars := [];
  FFoldCloseKeyChars := [];
  FSkipOpenKeyChars := [];
  FSkipCloseKeyChars := [];
  FAttributes.Clear;
  FMainRules.Clear;
  FComments.Clear;
  FCompletionProposalSkipRegions.Clear;

  for LIndex := FMatchingPairs.Count - 1 downto 0 do
    Dispose(PTextEditorMatchingPairToken(FMatchingPairs.Items[LIndex]));

  FMatchingPairs.Clear;

  for LIndex := 0 to FCodeFoldingRangeCount - 1 do
  begin
    FCodeFoldingRegions[LIndex].Free;
    FCodeFoldingRegions[LIndex] := nil;
  end;

  CodeFoldingRangeCount := 0;

  if Assigned(Editor) then
    TCustomTextEditor(Editor).ClearMatchingPair;
end;

procedure TTextEditorHighlighter.Prepare;
begin
  FAttributes.Clear;
  AddAllAttributes(MainRules);
  FMainRules.Reset;
  FMainRules.Prepare;
end;

procedure TTextEditorHighlighter.UpdateAttributes(const ARange: TTextEditorRange; const AParentRange: TTextEditorRange);
var
  LIndex: Integer;

  procedure SetAttributes(const AAttribute: TTextEditorHighlighterAttribute; const AParentRange: TTextEditorRange);
  var
    LElement: PTextEditorHighlighterElement;
  begin
    LElement := FColors.GetElement(AAttribute.Element);

    if AAttribute.ParentBackground and Assigned(AParentRange) then
      AAttribute.Background := AParentRange.Attribute.Background
    else
    if Assigned(LElement) then
      AAttribute.Background := LElement.Background;
    if AAttribute.ParentForeground and Assigned(AParentRange) then
      AAttribute.Foreground := AParentRange.Attribute.Foreground
    else
    if Assigned(LElement) then
      AAttribute.Foreground := LElement.Foreground;
    if Assigned(LElement) then
      AAttribute.FontStyles := LElement.FontStyles;
  end;

begin
  SetAttributes(ARange.Attribute, AParentRange);

  for LIndex := 0 to ARange.KeyListCount - 1 do
    SetAttributes(ARange.KeyList[LIndex].Attribute, ARange);
  for LIndex := 0 to ARange.SetCount - 1 do
    SetAttributes(ARange.Sets[LIndex].Attribute, ARange);
  for LIndex := 0 to ARange.RangeCount - 1 do
    UpdateAttributes(ARange.Ranges[LIndex], ARange);
end;

procedure TTextEditorHighlighter.UpdateColors;
var
  LEditor: TCustomTextEditor;
  LFontDummy: TFont;
begin
  UpdateAttributes(MainRules, nil);

  LEditor := TCustomTextEditor(FEditor);
  if Assigned(LEditor) then
  begin
    LFontDummy := TFont.Create;
    try
      LFontDummy.Name := LEditor.Font.Name;
      LFontDummy.Size := LEditor.Font.Size;
      FChanged := True;
      LEditor.Font.Assign(LFontDummy);
      LEditor.SizeOrFontChanged(True);
    finally
      LFontDummy.Free;
    end;
  end;
end;

procedure TTextEditorHighlighter.PrepareYAMLHighlighter;
var
  LKeyList: TTextEditorKeyList;
  LLine: Integer;
  LPText, LPStart: PChar;
  LTextLine: string;
  LKeyWord: string;
  LInside: Boolean;
begin
  if Assigned(FLines) then
  begin
    { Parse keywords from text }
    MainRules.ClearReservedWords;
    LKeyList := TTextEditorKeyList.Create;
    try
      LKeyList.TokenType := ttReservedWord;
      LKeyList.Attribute.Element := 'ReservedWord';
      LKeyList.Attribute.ParentBackground := True;
      LKeyList.Attribute.ParentForeground := False;
      for LLine := FLines.Count - 1 downto 0 do
      begin
        LTextLine := FLines[LLine];
        LPText := PChar(LTextLine);
        LPStart := LPText;
        Inc(LPText, Length(LTextLine));
        LInside := False;
        while LPText > LPStart do
        begin
          if (LPText^ = '"') or (LPText^ = '`') and ((LPText - 1)^ = '`') then
            LInside := not LInside;

          if not LInside then
            if LPText^ = ':' then
            begin
              Dec(LPText);
              { Space or tab characters }
              LKeyWord := ':';
              while (LPText >= LPStart) and (LPText^ in [TCharacters.Space, TControlCharacters.Tab]) do
              begin
                LKeyWord := LPText^ + LKeyWord;
                Dec(LPText);
              end;
              { Keyword }
              while (LPText >= LPStart) and not (LPText^ in [TCharacters.Space, TControlCharacters.Tab, '{', '(']) do
              begin
                LKeyWord := LPText^ + LKeyWord;
                Dec(LPText);
              end;
              if TextEditor.Utils.Trim(LKeyWord) <> ':' then
                LKeyList.KeyList.Add(LKeyWord);
            end;
          Dec(LPText);
        end;
      end;
    finally
      if LKeyList.KeyList.Count > 0 then
      begin
        MainRules.AddKeyList(LKeyList);
        UpdateAttributes(MainRules, nil);
      end
      else
        LKeyList.Free;

      SetOption(hoExecuteBeforePrepare, False);
    end;
  end;
end;

procedure TTextEditorHighlighter.LoadFromFile(const AFilename: string);
var
  LFileStream: TFileStream;
begin
  LFileStream := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyNone);
  try
    LoadFromStream(LFileStream);
  finally
    LFileStream.Free;
  end;
end;

procedure TTextEditorHighlighter.LoadFromStream(const AStream: TStream);
var
  LEditor: TCustomTextEditor;
  LTempLines: TStringList;
  LTopLine: Integer;
  LIndex: Integer;
  LTextPosition: TTextEditorTextPosition;
begin
  Clear;

  LEditor := TCustomTextEditor(FEditor);
  if Assigned(LEditor) then
  begin
    FLoading := True;
    LTempLines := TStringList.Create;
    try
      if LEditor.Visible then
        LTextPosition := LEditor.TextPosition;

      LTopLine := LEditor.TopLine;
      for LIndex := 0 to FLines.Count - 1 do
      if not (sfEmptyLine in FLines.Items^[LIndex].Flags) then
        LTempLines.Add(FLines.Items^[LIndex].TextLine);

      FLines.Clear;
      with TTextEditorHighlighterImportJSON.Create(Self) do
      try
        ImportFromStream(AStream);
      finally
        Free;
      end;
      FLines.LoadFromStrings(LTempLines);

      LEditor.TopLine := LTopLine;
      if LEditor.Visible then
        LEditor.TextPosition := LTextPosition;
    finally
      LTempLines.Free;
    end;
    UpdateColors;

    if Assigned(FBeforePrepare) then
      SetOption(hoExecuteBeforePrepare, True);

    FLoading := False;
    FLoaded := True;
  end;
end;

function TTextEditorHighlighter.GetAttribute(const AIndex: Integer): TTextEditorHighlighterAttribute;
begin
  Result := nil;
  if (AIndex >= 0) and (AIndex < FAttributes.Count) then
    Result := TTextEditorHighlighterAttribute(FAttributes.Objects[AIndex]);
end;

procedure TTextEditorHighlighter.AddAttribute(const AHighlighterAttribute: TTextEditorHighlighterAttribute);
begin
  FAttributes.AddObject(AHighlighterAttribute.Name, AHighlighterAttribute);
end;

procedure TTextEditorHighlighter.SetOption(const AOption: TTextEditorHighlighterOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Options := Options + [AOption]
  else
    Options := Options - [AOption];
end;

procedure TTextEditorHighlighter.NextToEndOfLine;
begin
  while not FEndOfLine do
    Next;
end;

function TTextEditorHighlighter.TokenLength: Integer;
begin
  Result := FRunPosition - FTokenPosition;
end;

end.
