unit TextEditor.SpellCheck;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, System.Types, TextEditor.Types;

type
  TIncompatCharBehaviour = (icUseDefault, icBestFit, icError);

  TTextEditorSpellCheck = class(TComponent)
  private
    FCodePage: Word;
    FFilename: string;
    FHandle: Pointer;
    FItems: TList;
    FLibraryLoaded: Boolean;
    function DLLToUnicodeString(const AValue: PAnsiChar): UnicodeString;
    function UnicodeToDLLString(const AValue: string; const AIncompatCharBehaviour: TIncompatCharBehaviour): AnsiString;
    procedure LoadSpellCheckLibrary;
    procedure SetFilename(const AValue: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetNextErrorItemIndex(const ATextPosition: TTextEditorTextPosition): Integer;
    function GetPreviousErrorItemIndex(const ATextPosition: TTextEditorTextPosition): Integer;
    function GetSuggestions(const AWord: string): TStringDynArray;
    function IsCorrectlyWritten(const AWord: string): Boolean; dynamic;
    procedure ClearItems;
    procedure Close; dynamic;
    procedure Open; dynamic;
    property Items: TList read FItems write FItems;
  published
    property Filename: string read FFilename write SetFilename;
  end;

  ETextEditorSpellCheckException = class(Exception);

implementation

uses
  System.AnsiStrings, TextEditor.Language;

type
  TPAnsiCharArray = packed array[0..MaxLongint div SizeOf(PAnsiChar) -1] of PAnsiChar;
  PPAnsiCharArray = ^TPAnsiCharArray;

const
  LIBRARY_DLL = 'Hunspell.dll';
  LIBRARY_CREATE = 'Hunspell_create';
  LIBRARY_DESTROY = 'Hunspell_destroy';
  LIBRARY_SPELL = 'Hunspell_spell';
  LIBRARY_GET_DIC_ENCODING = 'Hunspell_get_dic_encoding';
  LIBRARY_SUGGEST = 'Hunspell_suggest';
  LIBRARY_FREE_LIST = 'Hunspell_free_list';

var
  SpellCheckInitialize: function(const AAFFFilename: PAnsiChar; const ADicFilename: PAnsiChar): Pointer; cdecl;
  SpellCheckUninitialize: procedure(const AHandle: Pointer); cdecl;
  SpellCheckSpell: function(const AHandle: Pointer; const AWord: PAnsiChar): Integer; cdecl;
  SpellCheckGetDICEncoding: function(const AHandle: Pointer): PAnsiChar; cdecl;
  SpellCheckSuggest: function (AHandle: Pointer; var AList: PPAnsiCharArray; const AWord: PAnsiChar): Integer; cdecl;
  SpellCheckFreeList: procedure (AHandle: Pointer; var AList: PPAnsiCharArray; ACount: Integer); cdecl;

  SpellCheckDLLHandle: THandle;

{ TTextEditorSpellCheck }

constructor TTextEditorSpellCheck.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FLibraryLoaded := False;
  FItems := TList.Create;
end;

destructor TTextEditorSpellCheck.Destroy;
begin
  Close;
  ClearItems;
  FItems.Free;

  inherited Destroy;
end;

procedure TTextEditorSpellCheck.ClearItems;
var
  LIndex: Integer;
begin
  for LIndex := FItems.Count - 1 downto 0 do
    Dispose(PTextEditorTextPosition(FItems[LIndex]));
  FItems.Clear;
end;

procedure TTextEditorSpellCheck.LoadSpellCheckLibrary;
begin
  SpellCheckDLLHandle := LoadLibrary(PChar(LIBRARY_DLL));
  if SpellCheckDLLHandle = 0 then
    raise ETextEditorSpellCheckException.CreateRes(@STextEditorSpellCheckEngineCantLoadLibrary);

  @SpellCheckInitialize := GetProcAddress(SpellCheckDLLHandle, LIBRARY_CREATE);
  @SpellCheckUninitialize := GetProcAddress(SpellCheckDLLHandle, LIBRARY_DESTROY);
  @SpellCheckSpell := GetProcAddress(SpellCheckDLLHandle, LIBRARY_SPELL);
  @SpellCheckGetDICEncoding := GetProcAddress(SpellCheckDLLHandle, LIBRARY_GET_DIC_ENCODING);
  @SpellCheckSuggest := GetProcAddress(SpellCheckDLLHandle, LIBRARY_SUGGEST);
  @SpellCheckFreeList := GetProcAddress(SpellCheckDLLHandle, LIBRARY_FREE_LIST);

  if not (Assigned(@SpellCheckinitialize) and Assigned(@SpellCheckuninitialize) and Assigned(@SpellCheckspell) and
    Assigned(@SpellCheckGetDICEncoding) and Assigned(@SpellCheckSuggest) and Assigned(@SpellCheckFreeList)) then
    raise ETextEditorSpellCheckException.CreateRes(@STextEditorSpellCheckEngineCantInitialize);

  FLibraryLoaded := True;
end;

procedure TTextEditorSpellCheck.Close;
begin
  if Assigned(FHandle) then
  begin
    SpellCheckUninitialize(FHandle);
    FHandle := nil;
  end;
  FLibraryLoaded := False;
end;

function TTextEditorSpellCheck.DLLToUnicodeString(const AValue: PAnsiChar): UnicodeString; //FI:W521 FixInsight bug
var
  LWideBuffer: array [0..511] of WideChar;
  LWideLen: Integer;
begin
  LWideLen := MultiByteToWideChar(FCodePage, 0, AValue, -1, LWideBuffer, Length(LWideBuffer)) - 1;
  SetString(Result, LWideBuffer, LWideLen)
end;

function TTextEditorSpellCheck.UnicodeToDLLString(const AValue: UnicodeString; const AIncompatCharBehaviour: TIncompatCharBehaviour): AnsiString;
const
  Flags: array [TIncompatCharBehaviour] of DWORD = (WC_NO_BEST_FIT_CHARS, 0, WC_NO_BEST_FIT_CHARS);
var
  LAnsiBuffer: array [0..1023] of AnsiChar;
  LAnsiLen: Integer;
  LUsedDefaultChar: BOOL;
begin
  if FCodePage = CP_UTF8 then //MSDN: last two params *must* be nill if converting to UTF-8...
    LAnsiLen := WideCharToMultiByte(FCodePage, 0, PWideChar(AValue),
      Length(AValue), LAnsiBuffer, Length(LAnsiBuffer), nil, nil)
  else
  begin
    LAnsiLen := WideCharToMultiByte(FCodePage, Flags[AIncompatCharBehaviour], PWideChar(AValue),
      Length(AValue), LAnsiBuffer, Length(LAnsiBuffer), nil, @LUsedDefaultChar);
    if LUsedDefaultChar and (AIncompatCharBehaviour = icError) then
      raise ETextEditorSpellCheckException.CreateResFmt(@STextEditorContainsInvalidChars, [string(AValue)]);
  end;
  SetString(Result, LAnsiBuffer, LAnsiLen);
end;

function TTextEditorSpellCheck.IsCorrectlyWritten(const AWord: string): Boolean;
begin
  Result := SpellCheckSpell(FHandle, PAnsiChar(UnicodeToDLLString(AWord, icUseDefault))) <> 0;
end;

function ASCIILowerCase(const S: AnsiString): AnsiString;
begin
  SetString(Result, PAnsiChar(S), Length(S));
  System.AnsiStrings.StrLower(PAnsiChar(Result));
end;

function ASCIIStartsStr(const ASubText, AText: AnsiString): Boolean;
begin
  Result := System.AnsiStrings.StrLComp(PAnsiChar(ASubText), PAnsiChar(AText), Length(ASubText)) = 0;
end;

function RightBStr(const AText: AnsiString; const AByteCount: Integer): AnsiString;
begin
  Result := Copy(AText, Length(AText) + 1 - AByteCount, AByteCount);
end;

procedure TTextEditorSpellCheck.Open;
const
  ISO_LATIN1 = 28591;
var
  LCodePage: AnsiString;
  LSysCodePage: Word;
  LValue: Integer;
begin
  if not FLibraryLoaded then
    LoadSpellCheckLibrary;

  FHandle := SpellCheckInitialize(PAnsiChar(AnsiString(FFilename + '.aff')), PAnsiChar(AnsiString(FFilename + '.dic')));
  if not Assigned(FHandle) then
    raise ETextEditorSpellCheckException.CreateRes(@STextEditorSpellCheckEngineCantInitialize);

  LSysCodePage := GetACP;
  LCodePage := AnsiReplaceText(ASCIILowerCase(SpellCheckGetDICEncoding(FHandle)), '-', '');
  if LCodePage = 'utf8' then
    FCodePage := CP_UTF8
  else
  begin
    FCodePage := LSysCodePage;
    if ASCIIStartsStr('iso', LCodePage) then
    begin
      if LCodePage = 'iso88591' then
        FCodePage := ISO_LATIN1
      else
      if LCodePage = 'iso88592' then
        FCodePage := 28592
      else
      if LCodePage = 'iso88593' then
        FCodePage := 28593
      else
      if LCodePage = 'iso88594' then
        FCodePage := 28594
      else
      if LCodePage = 'iso88595' then
        FCodePage := 28595
      else
      if LCodePage = 'iso88596' then
        FCodePage := 28596
      else
      if LCodePage = 'iso88597' then
        FCodePage := 28597
      else
      if LCodePage = 'iso88598' then
        FCodePage := 28598
      else
      if LCodePage = 'iso88599' then
        FCodePage := 28599
      else
      if LCodePage = 'iso885913' then
        FCodePage := 28603
      else
      if LCodePage = 'iso885915' then
        FCodePage := 28605;
    end
    else
    if (LCodePage = 'koi8r') or (LCodePage = 'koi8u') then
      FCodePage := 20866
    else
    if (ASCIIStartsStr('windows', LCodePage) or ASCIIStartsStr('microsoft', LCodePage)) and
      TryStrToInt(string(RightBStr(LCodePage, 4)), LValue) then
        FCodePage := Word(LValue);
  end;
end;

procedure TTextEditorSpellCheck.SetFilename(const AValue: string);
begin
  Close;
  FFilename := AValue;
  Open;
end;

function TTextEditorSpellCheck.GetPreviousErrorItemIndex(const ATextPosition: TTextEditorTextPosition): Integer;
var
  LLow, LHigh, LMiddle: Integer;
  LErrorItem: PTextEditorTextPosition;

  function IsTextPositionBetweenErrorItems: Boolean;
  var
    LNextErrorItem: PTextEditorTextPosition;
  begin
    LNextErrorItem := PTextEditorTextPosition(FItems[LMiddle + 1]);

    Result :=
      ( (LErrorItem^.Line < ATextPosition.Line) or
        (LErrorItem^.Line = ATextPosition.Line) and (LErrorItem^.Char < ATextPosition.Char) )
      and
      ( (LNextErrorItem^.Line > ATextPosition.Line) or
        (LNextErrorItem^.Line = ATextPosition.Line) and (LNextErrorItem^.Char >= ATextPosition.Char) )
  end;

  function IsErrorItemGreaterThanTextPosition: Boolean;
  begin
    Result := (LErrorItem^.Line > ATextPosition.Line) or
      (LErrorItem^.Line = ATextPosition.Line) and (LErrorItem^.Char >= ATextPosition.Char)
  end;

  function IsErrorItemLowerThanTextPosition: Boolean;
  begin
    Result := (LErrorItem^.Line < ATextPosition.Line) or
      (LErrorItem^.Line = ATextPosition.Line) and (LErrorItem^.Char < ATextPosition.Char)
  end;

begin
  Result := -1;

  if FItems.Count = 0 then
    Exit;

  LHigh := FItems.Count - 1;

  LErrorItem := PTextEditorTextPosition(FItems[0]);
  if IsErrorItemGreaterThanTextPosition then
    Exit(LHigh);

  LErrorItem := PTextEditorTextPosition(FItems[LHigh]);
  if IsErrorItemLowerThanTextPosition then
    Exit(LHigh);

  LLow := 0;
  Dec(LHigh);

  while LLow <= LHigh do
  begin
    LMiddle := (LLow + LHigh) div 2;

    LErrorItem := PTextEditorTextPosition(FItems[LMiddle]);

    if IsTextPositionBetweenErrorItems then
      Exit(LMiddle)
    else
    if IsErrorItemGreaterThanTextPosition then
      LHigh := LMiddle - 1
    else
    if IsErrorItemLowerThanTextPosition then
      LLow := LMiddle + 1
  end;
end;

function TTextEditorSpellCheck.GetSuggestions(const AWord: string): TStringDynArray;
var
  LList: PPAnsiCharArray;
  LListCount, LIndex: Integer;
begin
  if not FLibraryLoaded then
    ETextEditorSpellCheckException.CreateRes(@STextEditorHunspellHandleNeeded);
  LListCount := SpellCheckSuggest(FHandle, LList, PAnsiChar(UnicodeToDLLString(AWord, icBestFit)));
  SetLength(Result, LListCount);
  for LIndex := 0 to LListCount - 1 do
    Result[LIndex] := DLLToUnicodeString(LList[LIndex]);
  SpellCheckFreeList(FHandle, LList, LListCount);
end;

function TTextEditorSpellCheck.GetNextErrorItemIndex(const ATextPosition: TTextEditorTextPosition): Integer;
var
  LLow, LHigh, LMiddle: Integer;
  LErrorItem: PTextEditorTextPosition;

  function IsTextPositionBetweenErrorItems: Boolean;
  var
    LPreviousErrorItem: PTextEditorTextPosition;
  begin
    LPreviousErrorItem := PTextEditorTextPosition(FItems[LMiddle - 1]);

    Result :=
      ( (LPreviousErrorItem^.Line < ATextPosition.Line) or
        (LPreviousErrorItem^.Line = ATextPosition.Line) and (LPreviousErrorItem^.Char <= ATextPosition.Char) )
      and
      ( (LErrorItem^.Line > ATextPosition.Line) or
        (LErrorItem^.Line = ATextPosition.Line) and (LErrorItem^.Char > ATextPosition.Char) );
  end;

  function IsErrorItemGreaterThanTextPosition: Boolean;
  begin
    Result := (LErrorItem^.Line > ATextPosition.Line) or
      (LErrorItem^.Line = ATextPosition.Line) and (LErrorItem^.Char > ATextPosition.Char)
  end;

  function IsErrorItemLowerThanTextPosition: Boolean;
  begin
    Result := (LErrorItem^.Line < ATextPosition.Line) or
      (LErrorItem^.Line = ATextPosition.Line) and (LErrorItem^.Char <= ATextPosition.Char)
  end;

begin
  Result := -1;

  if FItems.Count = 0 then
    Exit;

  LErrorItem := PTextEditorTextPosition(FItems[0]);
  if IsErrorItemGreaterThanTextPosition then
    Exit(0);

  LHigh := FItems.Count - 1;

  LErrorItem := PTextEditorTextPosition(FItems[LHigh]);
  if IsErrorItemLowerThanTextPosition then
    Exit(0);

  LLow := 1;

  while LLow <= LHigh do
  begin
    LMiddle := (LLow + LHigh) div 2;

    LErrorItem := PTextEditorTextPosition(FItems[LMiddle]);

    if IsTextPositionBetweenErrorItems then
      Exit(LMiddle)
    else
    if IsErrorItemGreaterThanTextPosition then
      LHigh := LMiddle - 1
    else
    if IsErrorItemLowerThanTextPosition then
      LLow := LMiddle + 1
  end;
end;

initialization

finalization

  if SpellCheckDLLHandle <> 0 then
    FreeLibrary(SpellCheckDLLHandle);

end.
