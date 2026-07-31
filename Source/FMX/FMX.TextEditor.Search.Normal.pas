unit FMX.TextEditor.Search.Normal;

interface

uses
  System.SysUtils, FMX.TextEditor.Lines, FMX.TextEditor.Search.Base;

type
  TTextEditorNormalSearch = class(TTextEditorSearchBase)
  strict private
    FCasedPattern: string;
    FCount: Integer;
    FExtended: Boolean;
    FLookAt: Integer;
    FOrigin: PChar;
    FPatternLength, FPatternLengthSuccessor: Integer;
    FRun: PChar;
    FShift: array [AnsiChar] of Integer;
    FShiftInitialized: Boolean;
    FTextLength: Integer;
    FTextToSearch: string;
    FTheEnd: PChar;
    function GetFinished: Boolean;
    procedure InitShiftTable;
  protected
    function GetLength(const AIndex: Integer): Integer; override;
    function TestWholeWord: Boolean;
    procedure CaseSensitiveChanged; override;
    procedure SetPattern(const AValue: string); override;
  public
    constructor Create(const AExtended: Boolean);
    function FindFirst(const AText: string): Integer;
    function Next: Integer;
    function SearchAll(const ALines: TTextEditorLines): Integer; override;
    property Count: Integer read FCount write FCount;
    property Finished: Boolean read GetFinished;
    property Pattern read FCasedPattern;
  end;

implementation

uses
  System.Character, FMX.TextEditor.Consts, FMX.TextEditor.Language;

constructor TTextEditorNormalSearch.Create(const AExtended: Boolean);
begin
  inherited Create;

  FExtended := AExtended;
end;

function TTextEditorNormalSearch.GetFinished: Boolean;
begin
  Result := (FRun >= FTheEnd) or (FPatternLength >= FTextLength);
end;

procedure TTextEditorNormalSearch.InitShiftTable;
begin
  FPatternLength := FPattern.Length;

  if FPatternLength = 0 then
    Status := STextEditorPatternIsEmpty;

  FPatternLengthSuccessor := FPatternLength + 1;
  FLookAt := 1;

  for var LAnsiChar := Low(AnsiChar) to High(AnsiChar) do
    FShift[LAnsiChar] := FPatternLengthSuccessor;

  for var LIndex := 1 to FPatternLength do
    FShift[AnsiChar(FPattern[LIndex])] := FPatternLengthSuccessor - LIndex;

  while FLookAt < FPatternLength do
  begin
    if FPattern[FPatternLength] = FPattern[FPatternLength - FLookAt] then
      Break;

    Inc(FLookAt);
  end;

  FShiftInitialized := True;
end;

function TTextEditorNormalSearch.TestWholeWord: Boolean;

  function IsWordBreakChar(const AChar: Char): Boolean;
  begin
    if (AChar < TCharacters.ExclamationMark) or AChar.IsWhiteSpace then
      Result := True
    else
      Result := if AChar = TCharacters.LowLine then False else not AChar.IsLetterOrDigit;
  end;

var
  LPTest: PChar;
begin
  LPTest := FRun - FPatternLength;

  Result := ((LPTest < FOrigin) or IsWordBreakChar(LPTest[0])) and ((FRun >= FTheEnd) or IsWordBreakChar(FRun[1]));
end;

function TTextEditorNormalSearch.Next: Integer;
var
  LIndex: Integer;
  LPValue: PChar;
begin
  Result := 0;

  Inc(FRun, FPatternLength);

  while FRun < FTheEnd do
  begin
    if FPattern[FPatternLength] <> FRun^ then
      Inc(FRun, FShift[AnsiChar((FRun + 1)^)])
    else
    begin
      LPValue := FRun - FPatternLength + 1;
      LIndex := 1;

      while FPattern[LIndex] = LPValue^ do
      begin
        if LIndex = FPatternLength then
        begin
          if WholeWordsOnly and not TestWholeWord then
            Break;

          Inc(FCount);

          Exit(FRun - FOrigin - FPatternLength + 2);
        end;

        Inc(LIndex);
        Inc(LPValue);
      end;

      Inc(FRun, FLookAt);

      if FRun >= FTheEnd then
        Break;

      Inc(FRun, FShift[AnsiChar(FRun^)] - 1);
    end;
  end;
end;

procedure TTextEditorNormalSearch.SetPattern(const AValue: string);
var
  LValue: string;
begin
  LValue := AValue;

  if FExtended then
  begin
    LValue := StringReplace(LValue, '\r', TControlCharacters.CarriageReturn, [rfReplaceAll]);
    LValue := StringReplace(LValue, '\n', TControlCharacters.Linefeed, [rfReplaceAll]);
    LValue := StringReplace(LValue, '\t', TControlCharacters.Tab, [rfReplaceAll]);
    LValue := StringReplace(LValue, '\0', TControlCharacters.Substitute, [rfReplaceAll]);
  end;

  if FPattern <> LValue then
  begin
    FCasedPattern := LValue;
    FPattern := if CaseSensitive then FCasedPattern else AnsiLowerCase(FCasedPattern);
    FShiftInitialized := False;
  end;

  FCount := 0;
end;

procedure TTextEditorNormalSearch.CaseSensitiveChanged;
begin
  FPattern := if CaseSensitive then FCasedPattern else AnsiLowerCase(FCasedPattern);

  FShiftInitialized := False;
end;

function TTextEditorNormalSearch.SearchAll(const ALines: TTextEditorLines): Integer;
var
  LPosition: Integer;
begin
  Status := '';
  Clear;

  LPosition := FindFirst(ALines.Text);

  while LPosition > 0 do
  begin
    FResults.Add(LPosition);
    LPosition := Next;
  end;

  Result := FResults.Count;

  SetLength(FTextToSearch, 0);
end;

function TTextEditorNormalSearch.FindFirst(const AText: string): Integer;
begin
  if not FShiftInitialized then
    InitShiftTable;

  Result := 0;

  FTextLength := AText.Length;

  if FTextLength >= FPatternLength then
  begin
    FTextToSearch := AText;

    if not CaseSensitive then
      FTextToSearch := AnsiLowerCase(FTextToSearch);

    FOrigin := PChar(FTextToSearch);
    FTheEnd := FOrigin + FTextLength;
    FRun := FOrigin - 1;

    Result := Next;
  end;
end;

function TTextEditorNormalSearch.GetLength(const AIndex: Integer): Integer;
begin
  Result := FPatternLength;
end;

end.
