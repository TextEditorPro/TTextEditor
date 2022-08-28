{$WARN WIDECHAR_REDUCED OFF} // CharInSet is slow in loops
unit TextEditor.Highlighter.Rules;

interface

uses
  System.Classes, System.SysUtils, Vcl.Graphics, TextEditor.Consts, TextEditor.Highlighter.Attributes,
  TextEditor.Highlighter.Token, TextEditor.Types;

type
  TTextEditorRange = class;
  TTextEditorSet = class;

  TTextEditorAbstractParser = class abstract
  public
    function GetToken(const ACurrentRule: TTextEditorRange; const APLine: PChar; var ARun: Integer; var AToken: TTextEditorToken): Boolean; virtual; abstract;
  end;

  TTextEditorParser = class(TTextEditorAbstractParser)
  strict private
    FHeadNode: TTextEditorTokenNode;
    FSets: TList;
  public
    constructor Create(const AChar: Char; const AToken: TTextEditorToken; const ABreakType: TTextEditorBreakType); reintroduce; overload; virtual;
    constructor Create(const ASet: TTextEditorSet); reintroduce; overload; virtual;
    destructor Destroy; override;
    function GetToken(const ACurrentRange: TTextEditorRange; const APLine: PChar; var ARun: Integer; var AToken: TTextEditorToken): Boolean; override;
    procedure AddSet(const ASet: TTextEditorSet);
    procedure AddTokenNode(const AString: string; const AToken: TTextEditorToken; const ABreakType: TTextEditorBreakType);
    property HeadNode: TTextEditorTokenNode read FHeadNode;
    property Sets: TList read FSets;
  end;

  TTextEditorDefaultParser = class(TTextEditorAbstractParser)
  strict private
    FToken: TTextEditorToken;
  public
    constructor Create(const AToken: TTextEditorToken); reintroduce; virtual;
    destructor Destroy; override;

    function GetToken(const ACurrentRange: TTextEditorRange; const APLine: PChar; var ARun: Integer; var AToken: TTextEditorToken): Boolean; override;
    property Token: TTextEditorToken read FToken;
  end;

  TDelimitersParser = class(TTextEditorAbstractParser)
  strict private
    FToken: TTextEditorToken;
  public
    constructor Create(const AToken: TTextEditorToken); virtual;
    destructor Destroy; override;

    function GetToken(const ACurrentRange: TTextEditorRange; const APLine: PChar; var ARun: Integer; var AToken: TTextEditorToken): Boolean; override;
    property Token: TTextEditorToken read FToken;
  end;

  TTextEditorRule = class(TTextEditorAbstractRule)
  private
    FStyle: string;
    FAttribute: TTextEditorHighlighterAttribute;
  protected
    FParent: TTextEditorRange;
  public
    constructor Create;
    destructor Destroy; override;

    property Attribute: TTextEditorHighlighterAttribute read FAttribute;
    property Parent: TTextEditorRange read FParent write FParent;
    property Style: string read FStyle;
  end;

  TTextEditorKeyList = class(TTextEditorRule)
  strict private
    FKeyList: TStringList;
  public
    constructor Create;
    destructor Destroy; override;

    property KeyList: TStringList read FKeyList write FKeyList;
  end;

  TTextEditorSet = class(TTextEditorRule)
  strict private
    FCharSet: TTextEditorCharSet;
  public
    constructor Create(const ACharSet: TTextEditorCharSet = []);
    property CharSet: TTextEditorCharSet read FCharSet write FCharSet;
  end;

  TTextEditorAbstractParserArray = array [AnsiChar] of TTextEditorAbstractParser;

  TTextEditorCaseFunction = function(const AChar: Char): Char;
  TTextEditorStringCaseFunction = function(const AString: string): string;

  TTextEditorRange = class(TTextEditorRule)
  strict private
    FAllowedCharacters: TTextEditorCharSet;
    FAlternativeCloseArray: TTextEditorArrayOfString;
    FAlternativeCloseArrayCount: Integer;
    FCaseFunct: TTextEditorCaseFunction;
    FCaseSensitive: Boolean;
    FCloseOnEndOfLine: Boolean;
    FCloseOnTerm: Boolean;
    FCloseParent: Boolean;
    FCloseToken: TTextEditorMultiToken;
    FClosingToken: TTextEditorToken;
    FDefaultSymbols: TTextEditorDefaultParser;
    FDefaultTermSymbol: TDelimitersParser;
    FDefaultToken: TTextEditorToken;
    FDelimiters: TTextEditorCharSet;
    FHereDocument: Boolean;
    FKeyList: TList;
    FOpenBeginningOfLine: Boolean;
    FOpenToken: TTextEditorMultiToken;
    FPrepared: Boolean;
    FRanges: TList;
    FSets: TList;
    FSkipWhitespace: Boolean;
    FSkipWhitespaceOnce: Boolean;
    FStringCaseFunct: TTextEditorStringCaseFunction;
    FSymbolList: TTextEditorAbstractParserArray;
    FTokens: TList;
    FUseDelimitersForText: Boolean;
    function GetKeyList(const AIndex: Integer): TTextEditorKeyList;
    function GetKeyListCount: Integer;
    function GetRange(const AIndex: Integer): TTextEditorRange;
    function GetRangeCount: Integer;
    function GetSet(const AIndex: Integer): TTextEditorSet;
    function GetSetCount: Integer;
    function GetToken(const AIndex: Integer): TTextEditorToken;
    procedure SetAlternativeCloseArrayCount(const AValue: Integer);
    procedure SetCaseSensitive(const AValue: Boolean);
  public
    constructor Create(const AOpenToken: string = ''; const ACloseToken: string = ''); virtual;
    destructor Destroy; override;
    function FindToken(const AString: string): TTextEditorToken;
    procedure AddKeyList(const ANewKeyList: TTextEditorKeyList);
    procedure AddRange(const ANewRange: TTextEditorRange);
    procedure AddSet(const ANewSet: TTextEditorSet);
    procedure AddToken(const AToken: TTextEditorToken);
    procedure AddTokenRange(const AOpenToken: string; AOpenTokenBreakType: TTextEditorBreakType; const ACloseToken: string;
      const ACloseTokenBreakType: TTextEditorBreakType);
    procedure Clear;
    procedure ClearReservedWords;
    procedure Prepare;
    procedure Reset;
    procedure SetDelimiters(const ADelimiters: TTextEditorCharSet);
    property AllowedCharacters: TTextEditorCharSet read FAllowedCharacters write FAllowedCharacters;
    property AlternativeCloseArray: TTextEditorArrayOfString read FAlternativeCloseArray write FAlternativeCloseArray;
    property AlternativeCloseArrayCount: Integer read FAlternativeCloseArrayCount write SetAlternativeCloseArrayCount;
    property OpenBeginningOfLine: Boolean read FOpenBeginningOfLine write FOpenBeginningOfLine;
    property CaseFunct: TTextEditorCaseFunction read FCaseFunct;
    property CaseSensitive: Boolean read FCaseSensitive write SetCaseSensitive;
    property CloseOnEndOfLine: Boolean read FCloseOnEndOfLine write FCloseOnEndOfLine;
    property CloseOnTerm: Boolean read FCloseOnTerm write FCloseOnTerm;
    property SkipWhitespace: Boolean read FSkipWhitespace write FSkipWhitespace;
    property SkipWhitespaceOnce: Boolean read FSkipWhitespaceOnce write FSkipWhitespaceOnce;
    property CloseParent: Boolean read FCloseParent write FCloseParent;
    property CloseToken: TTextEditorMultiToken read FCloseToken write FCloseToken;
    property ClosingToken: TTextEditorToken read FClosingToken write FClosingToken;
    property DefaultToken: TTextEditorToken read FDefaultToken;
    property Delimiters: TTextEditorCharSet read FDelimiters write FDelimiters;
    property HereDocument: Boolean read FHereDocument write FHereDocument;
    property KeyListCount: Integer read GetKeyListCount;
    property KeyList[const AIndex: Integer]: TTextEditorKeyList read GetKeyList;
    property OpenToken: TTextEditorMultiToken read FOpenToken write FOpenToken;
    property Prepared: Boolean read FPrepared;
    property RangeCount: Integer read GetRangeCount;
    property Ranges[const AIndex: Integer]: TTextEditorRange read GetRange;
    property SetCount: Integer read GetSetCount;
    property Sets[const AIndex: Integer]: TTextEditorSet read GetSet;
    property StringCaseFunct: TTextEditorStringCaseFunction read FStringCaseFunct;
    property SymbolList: TTextEditorAbstractParserArray read FSymbolList;
    property Tokens[const AIndex: Integer]: TTextEditorToken read GetToken;
    property UseDelimitersForText: Boolean read FUseDelimitersForText write FUseDelimitersForText;
  end;

implementation

uses
  System.Types, System.UITypes, TextEditor.Utils;

{ TTextEditorParser }

constructor TTextEditorParser.Create(const AChar: Char; const AToken: TTextEditorToken; const ABreakType: TTextEditorBreakType);
begin
  inherited Create;

  FHeadNode := TTextEditorTokenNode.Create(AChar, AToken, ABreakType);
  FSets := TList.Create;
end;

constructor TTextEditorParser.Create(const ASet: TTextEditorSet);
begin
  inherited Create;

  FSets := TList.Create;
  AddSet(ASet);
end;

destructor TTextEditorParser.Destroy;
begin
  if Assigned(FHeadNode) then
  begin
    FHeadNode.Free;
    FHeadNode := nil;
  end;

  FSets.Clear;
  FSets.Free;
  FSets := nil;

  inherited;
end;

procedure TTextEditorParser.AddTokenNode(const AString: string; const AToken: TTextEditorToken;
  const ABreakType: TTextEditorBreakType);
var
  LIndex: Integer;
  LLength: Integer;
  LTokenNode: TTextEditorTokenNode;
  LTokenNodeList: TTextEditorTokenNodeList;
  LChar: Char;
begin
  LTokenNodeList := HeadNode.NextNodes;
  LTokenNode := nil;
  LLength := Length(AString);
  for LIndex := 1 to LLength do
  begin
    LChar := AString[LIndex];
    LTokenNode := LTokenNodeList.FindNode(LChar);
    if not Assigned(LTokenNode) then
    begin
      LTokenNode := TTextEditorTokenNode.Create(LChar);
      LTokenNodeList.AddNode(LTokenNode);
    end;
    LTokenNodeList := LTokenNode.NextNodes;
  end;
  LTokenNode.BreakType := ABreakType;
  LTokenNode.Token := AToken;
end;

procedure TTextEditorParser.AddSet(const ASet: TTextEditorSet);
begin
  Sets.Add(ASet);
end;

function TTextEditorParser.GetToken(const ACurrentRange: TTextEditorRange; const APLine: PChar; var ARun: Integer;
  var AToken: TTextEditorToken): Boolean;
var
  LCurrentTokenNode, LStartTokenNode, LFindTokenNode: TTextEditorTokenNode;
  LIndex, LStartPosition, LNextPosition, LPreviousPosition: Integer;
  LAllowedDelimiters: TTextEditorCharSet;
  LSet: TTextEditorSet;
  LChar: Char;
begin
  Result := False;

  LStartPosition := ARun;
  if Assigned(HeadNode) then
  begin
    LCurrentTokenNode := HeadNode;
    LNextPosition := LStartPosition;
    LStartTokenNode := nil;
    repeat
      if Assigned(LStartTokenNode) then
      begin
        LCurrentTokenNode := LStartTokenNode;
        ARun := LNextPosition;
        LStartTokenNode := nil;
      end;

      if Assigned(LCurrentTokenNode.Token) then
        LFindTokenNode := LCurrentTokenNode
      else
        LFindTokenNode := nil;

      LPreviousPosition := ARun;
      while (LCurrentTokenNode.NextNodes.Count > 0) and (APLine[ARun] <> TControlCharacters.Null) do
      begin
        Inc(ARun);
        LCurrentTokenNode := LCurrentTokenNode.NextNodes.FindNode(ACurrentRange.CaseFunct(APLine[ARun]));
        if not Assigned(LCurrentTokenNode) then
        begin
          Dec(ARun);
          Break;
        end;

        if Assigned(LCurrentTokenNode.Token) then
        begin
          LFindTokenNode := LCurrentTokenNode;
          LPreviousPosition := ARun;
        end;

        if not Assigned(LStartTokenNode) then
          if LCurrentTokenNode.Char in ACurrentRange.Delimiters then
          begin
            LStartTokenNode := LCurrentTokenNode;
            LNextPosition := ARun;
          end;
      end;

      ARun := LPreviousPosition;

      if not Assigned(LFindTokenNode) or not Assigned(LFindTokenNode.Token) or
        ((LFindTokenNode.Token.Attribute.EscapeChar <> TControlCharacters.Null) and
        (LStartPosition > 0) and (APLine[LStartPosition - 1] = LFindTokenNode.Token.Attribute.EscapeChar)) then
        Continue;

      if APLine[ARun] <> TControlCharacters.Null then
        Inc(ARun);

      if not (LFindTokenNode.Char in TCharacterSets.Numbers) and ((LFindTokenNode.BreakType = btAny) or (APLine[ARun] in ACurrentRange.Delimiters)) then
      begin
        AToken := LFindTokenNode.Token;
        Exit(True);
      end;
    until not Assigned(LStartTokenNode);
  end;

  LAllowedDelimiters := ACurrentRange.Delimiters;
  for LIndex := 0 to Sets.Count - 1 do
    LAllowedDelimiters := LAllowedDelimiters - TTextEditorSet(Sets.List[LIndex]).CharSet;

  for LIndex := 0 to Sets.Count - 1 do
  begin
    ARun := LStartPosition;
    LSet := TTextEditorSet(Sets.List[LIndex]);
    repeat
      Inc(ARun);
      LChar := APLine[ARun];
    until not (LChar in LSet.CharSet) or (LChar = TControlCharacters.Null);

    if LChar in LAllowedDelimiters then
    begin
      AToken := TTextEditorToken.Create(LSet.Attribute);
      AToken.Temporary := True;
      Exit(True);
    end;
  end;

  ARun := LStartPosition + 1;
end;

constructor TTextEditorDefaultParser.Create(const AToken: TTextEditorToken);
begin
  inherited Create;

  FToken := AToken;
end;

destructor TTextEditorDefaultParser.Destroy;
begin
  FreeAndNil(FToken);

  inherited;
end;

function TTextEditorDefaultParser.GetToken(const ACurrentRange: TTextEditorRange; const APLine: PChar; var ARun: Integer;
  var AToken: TTextEditorToken): Boolean;
begin
  Inc(ARun);

  Result := False;
end;

constructor TDelimitersParser.Create(const AToken: TTextEditorToken);
begin
  inherited Create;

  FToken := AToken;
end;

destructor TDelimitersParser.Destroy;
begin
  FreeAndNil(FToken);

  inherited;
end;

function TDelimitersParser.GetToken(const ACurrentRange: TTextEditorRange; const APLine: PChar; var ARun: Integer; var AToken: TTextEditorToken): Boolean;
begin
  if APLine[ARun] <> TControlCharacters.Null then
    Inc(ARun);

  AToken := Self.Token;
  Result := True;
end;

constructor TTextEditorRule.Create;
begin
  inherited;

  FAttribute := TTextEditorHighlighterAttribute.Create('');
end;

destructor TTextEditorRule.Destroy;
begin
  FAttribute.Free;
  FAttribute := nil;

  inherited;
end;

{ TTextEditorRange }

constructor TTextEditorRange.Create(const AOpenToken: string; const ACloseToken: string);
begin
  inherited Create;

  FOpenToken := TTextEditorMultiToken.Create;
  FCloseToken := TTextEditorMultiToken.Create;
  AddTokenRange(AOpenToken, btUnspecified, ACloseToken, btUnspecified);

  SetCaseSensitive(False);

  FAlternativeCloseArrayCount := 0;

  FPrepared := False;

  FRanges := TList.Create;
  FKeyList := TList.Create;
  FSets := TList.Create;
  FTokens := TList.Create;

  FDelimiters := TCharacterSets.DefaultDelimiters;
  FAllowedCharacters := [];
end;

destructor TTextEditorRange.Destroy;
begin
  Clear;
  Reset;

  FreeAndNil(FOpenToken);
  FreeAndNil(FCloseToken);
  FreeAndNil(FAttribute);
  FreeAndNil(FKeyList);
  FreeAndNil(FSets);
  FreeAndNil(FTokens);
  FreeAndNil(FRanges);

  inherited;
end;

procedure TTextEditorRange.AddToken(const AToken: TTextEditorToken);
var
  LToken: TTextEditorToken;
  LLow, LHigh, LMiddle, LCompare: Integer;
begin
  LLow := 0;
  LHigh := FTokens.Count - 1;

  while LLow <= LHigh do
  begin
    LMiddle := LLow + (LHigh - LLow) shr 1;
    LToken := TTextEditorToken(FTokens.Items[LMiddle]);
    LCompare := CompareStr(LToken.Symbol, AToken.Symbol);

    if LCompare < 0 then
      LLow := LMiddle + 1
    else
    if LCompare > 0 then
      LHigh := LMiddle - 1
    else
      Exit;
  end;

  FTokens.Insert(LLow, AToken);
end;

function TTextEditorRange.FindToken(const AString: string): TTextEditorToken;
var
  LToken: TTextEditorToken;
  LLow, LHigh, LMiddle, LCompare: Integer;
begin
  Result := nil;

  LLow := 0;
  LHigh := FTokens.Count - 1;

  while LLow <= LHigh do
  begin
    LMiddle := LLow + (LHigh - LLow) shr 1;

    LToken := TTextEditorToken(FTokens.Items[LMiddle]);
    LCompare := CompareStr(LToken.Symbol, AString);

    if LCompare = 0 then
      Exit(LToken)
    else
    if LCompare < 0 then
      LLow := LMiddle + 1
    else
      LHigh := LMiddle - 1;
  end;
end;

procedure TTextEditorRange.AddRange(const ANewRange: TTextEditorRange);
begin
  FRanges.Add(ANewRange);
  ANewRange.Parent := Self;
end;

procedure TTextEditorRange.AddKeyList(const ANewKeyList: TTextEditorKeyList);
begin
  FKeyList.Add(ANewKeyList);
  ANewKeyList.Parent := Self;
end;

procedure TTextEditorRange.AddSet(const ANewSet: TTextEditorSet);
begin
  FSets.Add(ANewSet);
  ANewSet.Parent := Self;
end;

function TTextEditorRange.GetRangeCount: Integer;
begin
  Result := FRanges.Count;
end;

function TTextEditorRange.GetKeyListCount: Integer;
begin
  Result := FKeyList.Count;
end;

function TTextEditorRange.GetSetCount: Integer;
begin
  Result := FSets.Count;
end;

function TTextEditorRange.GetToken(const AIndex: Integer): TTextEditorToken;
begin
  Result := TTextEditorToken(FTokens[AIndex]);
end;

function TTextEditorRange.GetRange(const AIndex: Integer): TTextEditorRange;
begin
  Result := TTextEditorRange(FRanges[AIndex]);
end;

function TTextEditorRange.GetKeyList(const AIndex: Integer): TTextEditorKeyList;
begin
  Result := TTextEditorKeyList(FKeyList[AIndex]);
end;

function TTextEditorRange.GetSet(const AIndex: Integer): TTextEditorSet;
begin
  Result := TTextEditorSet(FSets.List[AIndex]);
end;

procedure TTextEditorRange.AddTokenRange(const AOpenToken: string; AOpenTokenBreakType: TTextEditorBreakType; const ACloseToken: string;
  const ACloseTokenBreakType: TTextEditorBreakType);
begin
  FOpenToken.AddSymbol(AOpenToken);
  FOpenToken.BreakType := AOpenTokenBreakType;
  FCloseToken.AddSymbol(ACloseToken);
  FCloseToken.BreakType := ACloseTokenBreakType;
end;

procedure TTextEditorRange.SetDelimiters(const ADelimiters: TTextEditorCharSet);
var
  LIndex: Integer;
begin
  Delimiters := ADelimiters;
  for LIndex := 0 to RangeCount - 1 do
    Ranges[LIndex].SetDelimiters(ADelimiters);
end;

procedure TTextEditorRange.SetAlternativeCloseArrayCount(const AValue: Integer);
begin
  FAlternativeCloseArrayCount := AValue;
  SetLength(FAlternativeCloseArray, AValue);
end;

procedure TTextEditorRange.SetCaseSensitive(const AValue: Boolean);
begin
  FCaseSensitive := AValue;
  if AValue then
  begin
    FCaseFunct := CaseNone;
    FStringCaseFunct := CaseStringNone;
  end
  else
  begin
    FCaseFunct := CaseUpper;
    FStringCaseFunct := AnsiUpperCase;
  end
end;

procedure TTextEditorRange.Prepare;
var
  LIndex, LIndex2: Integer;
  LLength: Integer;
  LSymbol: string;
  LFirstChar: Char;
  LBreakType: TTextEditorBreakType;

  function InsertTokenDefault(const AToken: TTextEditorToken; const ARules: TTextEditorRange;
    const AAttribute: TTextEditorHighlighterAttribute): TTextEditorToken;
  begin
    Result := ARules.FindToken(AToken.Symbol);
    if Assigned(Result) then
      AToken.Free
    else
      Result := AToken;

    ARules.AddToken(Result);
    if not Assigned(Result.Attribute) then
      Result.Attribute := AAttribute;
  end;

  procedure InsertToken(const AToken: TTextEditorToken; const ARules: TTextEditorRange);
  var
    LToken: TTextEditorToken;
  begin
    LToken := ARules.FindToken(AToken.Symbol);
    if Assigned(LToken) then
    begin
      LToken.Attribute := AToken.Attribute;
      AToken.Free;
    end
    else
      ARules.AddToken(AToken)
  end;

var
  LRange: TTextEditorRange;
  LKeyList: TTextEditorKeyList;
  LToken, LTempToken: TTextEditorToken;
  LAnsiChar: AnsiChar;
  LChar: Char;
  LSet: TTextEditorSet;
begin
  Reset;

  FDefaultToken := TTextEditorToken.Create(Attribute);
  if Assigned(FDefaultTermSymbol) then
  begin
    FDefaultTermSymbol.Free;
    FDefaultTermSymbol := nil;
  end;
  FDefaultTermSymbol := TDelimitersParser.Create(TTextEditorToken.Create(Attribute));
  FDefaultSymbols := TTextEditorDefaultParser.Create(TTextEditorToken.Create(Attribute));

  FDelimiters := FDelimiters + TCharacterSets.AbsoluteDelimiters;

  if Assigned(FRanges) then
  for LIndex := 0 to FRanges.Count - 1 do
  begin
    LRange := TTextEditorRange(FRanges[LIndex]);

    for LIndex2 := 0 to LRange.FOpenToken.SymbolCount - 1 do
    begin
      LTempToken := TTextEditorToken.Create(LRange.OpenToken, LIndex2);
      LToken := InsertTokenDefault(LTempToken, Self, LRange.Attribute);
      LToken.OpenRule := LRange;

      LTempToken := TTextEditorToken.Create(LRange.CloseToken, LIndex2);
      LToken.ClosingToken := InsertTokenDefault(LTempToken, LRange, LRange.Attribute);
    end;
    LRange.Prepare;
  end;

  if Assigned(FKeyList) then
  for LIndex := 0 to FKeyList.Count - 1 do
  begin
    LKeyList := TTextEditorKeyList(FKeyList[LIndex]);

    for LIndex2 := 0 to LKeyList.KeyList.Count - 1 do
    begin
      LTempToken := TTextEditorToken.Create(LKeyList.Attribute);
      LTempToken.Symbol := LKeyList.KeyList[LIndex2];
      InsertToken(LTempToken, Self);
    end;
  end;

  if Assigned(FTokens) then
  for LIndex := 0 to FTokens.Count - 1 do
  begin
    LTempToken := TTextEditorToken(FTokens[LIndex]);
    LLength := Length(LTempToken.Symbol);
    if LLength < 1 then
      Continue;

    LSymbol := LTempToken.Symbol;
    LFirstChar := LSymbol[1];

    if LFirstChar in FDelimiters then
      LBreakType := btAny
    else
    if LTempToken.BreakType <> btUnspecified then
      LBreakType := LTempToken.BreakType
    else
      LBreakType := btTerm;

    LChar := CaseFunct(LFirstChar);
    if Ord(LChar) < TCharacters.AnsiCharCount then
    begin
      LAnsiChar := AnsiChar(LChar);
      if not Assigned(SymbolList[LAnsiChar]) then
      begin
        if LLength = 1 then
          FSymbolList[LAnsiChar] := TTextEditorParser.Create(LFirstChar, LTempToken, LBreakType)
        else
          FSymbolList[LAnsiChar] := TTextEditorParser.Create(LFirstChar, FDefaultToken, LBreakType);
      end;

      if LSymbol[LLength] in FDelimiters then
        LBreakType := btAny;

      if LLength <> 1 then
        TTextEditorParser(SymbolList[LAnsiChar]).AddTokenNode(StringCaseFunct(Copy(LSymbol, 2)), LTempToken,
          LBreakType);
    end;
  end;

  if Assigned(FSets) then
    if FSets.Count > 0 then
    for LIndex := 0 to 255 do
    begin
      LAnsiChar := AnsiChar(CaseFunct(Char(LIndex)));
      for LIndex2 := 0 to FSets.Count - 1 do
      begin
        LSet := TTextEditorSet(FSets.List[LIndex2]);
        if LAnsiChar in LSet.CharSet then
          if not Assigned(SymbolList[LAnsiChar]) then
            FSymbolList[LAnsiChar] := TTextEditorParser.Create(LSet)
          else
            TTextEditorParser(SymbolList[LAnsiChar]).AddSet(LSet);
      end;
    end;

  for LIndex := 0 to 255 do
  begin
    LAnsiChar := AnsiChar(LIndex);
    if not Assigned(SymbolList[LAnsiChar]) then
    begin
      if LAnsiChar in FDelimiters then
        FSymbolList[LAnsiChar] := FDefaultTermSymbol
      else
        FSymbolList[LAnsiChar] := FDefaultSymbols;
    end;
  end;

  FPrepared := True;
end;

procedure TTextEditorRange.Reset;
var
  LIndex: Integer;
  LAnsiChar: AnsiChar;
begin
  if not FPrepared then
    Exit;

  for LIndex := 0 to 255 do
  begin
    LAnsiChar := AnsiChar(LIndex);

    if Assigned(SymbolList[LAnsiChar]) and (SymbolList[LAnsiChar] <> FDefaultTermSymbol) and (SymbolList[LAnsiChar] <> FDefaultSymbols) then
      FSymbolList[LAnsiChar].Free;

    FSymbolList[LAnsiChar] := nil;
  end;

  FreeAndNil(FDefaultToken);
  FreeAndNil(FDefaultTermSymbol);
  FreeAndNil(FDefaultSymbols);

  if Assigned(FRanges) then
  for LIndex := 0 to FRanges.Count - 1 do
    TTextEditorRange(FRanges[LIndex]).Reset;

  ClearList(FTokens);
  FPrepared := False;
end;

procedure TTextEditorRange.Clear;
var
  LIndex: Integer;
begin
  OpenToken.Clear;
  CloseToken.Clear;
  FCloseOnTerm := False;
  FCloseOnEndOfLine := False;
  FCloseParent := False;
  FHereDocument := False;
  Reset;

  if Assigned(FRanges) then
  for LIndex := 0 to FRanges.Count - 1 do
    TTextEditorRange(FRanges[LIndex]).Clear;

  ClearList(FRanges);
  ClearList(FTokens);
  ClearList(FKeyList);
  ClearList(FSets);
end;

procedure TTextEditorRange.ClearReservedWords;
var
  LIndex: Integer;
  LKeyList: TTextEditorKeyList;
begin
  if not Assigned(FKeyList) then
    Exit;

  for LIndex := FKeyList.Count - 1 downto 0 do
  begin
    LKeyList := TTextEditorKeyList(FKeyList[LIndex]);
    if Assigned(LKeyList) and (LKeyList.TokenType = ttReservedWord) then
    begin
      LKeyList.Free;

      FKeyList.Delete(LIndex);
    end;
  end;
end;

constructor TTextEditorKeyList.Create;
begin
  inherited;

  FKeyList := TStringList.Create;
  FKeyList.Sorted := True;
  FAttribute.Foreground := TColors.SysWindowText;
  FAttribute.Background := TColors.SysWindow;
end;

destructor TTextEditorKeyList.Destroy;
begin
  FreeAndNil(FKeyList);

  inherited;
end;

constructor TTextEditorSet.Create(const ACharSet: TTextEditorCharSet = []);
begin
  inherited Create;

  FCharSet := ACharSet;

  FAttribute.Foreground := TColors.SysWindowText;
  FAttribute.Background := TColors.SysWindow;
end;

end.
