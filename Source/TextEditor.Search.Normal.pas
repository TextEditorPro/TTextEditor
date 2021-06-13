unit TextEditor.Search.Normal;

interface

uses
  System.Classes, System.SysUtils, TextEditor.Lines, TextEditor.Search.Base;

type
  TTextEditorNormalSearch = class(TTextEditorSearchBase)
  strict private
    FCount: Integer;
    FExtended: Boolean;
    FLookAt: Integer;
    FOrigin: PChar;
    FCasedPattern: string;
    FLineBreak: string;
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
    constructor Create(const AExtended: Boolean; const ALineBreak: string);
    function SearchAll(const ALines: TTextEditorLines): Integer; override;
    function FindFirst(const AText: string): Integer;
    function Next: Integer;
    property Count: Integer read FCount write FCount;
    property Finished: Boolean read GetFinished;
    property Pattern read FCasedPattern;
  end;

implementation

uses
  Winapi.Windows, System.Character, TextEditor.Consts, TextEditor.Language;

constructor TTextEditorNormalSearch.Create(const AExtended: Boolean; const ALineBreak: string);
begin
  inherited Create;

  FExtended := AExtended;
  FLineBreak := ALineBreak;
end;

function TTextEditorNormalSearch.GetFinished: Boolean;
begin
  Result := (FRun >= FTheEnd) or (FPatternLength >= FTextLength);
end;

procedure TTextEditorNormalSearch.InitShiftTable;
var
  LAnsiChar: AnsiChar;
  LIndex: Integer;
begin
  FPatternLength := Length(FPattern);
  if FPatternLength = 0 then
    Status := STextEditorPatternIsEmpty;
  FPatternLengthSuccessor := FPatternLength + 1;
  FLookAt := 1;
  for LAnsiChar := Low(AnsiChar) to High(AnsiChar) do
    FShift[LAnsiChar] := FPatternLengthSuccessor;
  for LIndex := 1 to FPatternLength do
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
var
  LPTest: PChar;

  function IsWordBreakChar(AChar: Char): Boolean;
  begin
    if (AChar < TEXT_EDITOR_EXCLAMATION_MARK) or AChar.IsWhiteSpace then
      Result := True
    else
    if AChar = TEXT_EDITOR_LOW_LINE then
      Result := False
    else
      Result := not AChar.IsLetterOrDigit;
  end;

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
          if WholeWordsOnly then
            if not TestWholeWord then
              Break;
          Inc(FCount);
          Result := FRun - FOrigin - FPatternLength + 2;
          Exit;
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
    LValue := StringReplace(LValue, '\n', FLineBreak, [rfReplaceAll]);
    LValue := StringReplace(LValue, '\t', TEXT_EDITOR_TAB_CHAR, [rfReplaceAll]);
    LValue := StringReplace(LValue, '\0', TEXT_EDITOR_SUBSTITUTE_CHAR, [rfReplaceAll]);
  end;

  if FPattern <> LValue then
  begin
    FCasedPattern := LValue;
    if CaseSensitive then
      FPattern := FCasedPattern
    else
      FPattern := AnsiLowerCase(FCasedPattern);
    FShiftInitialized := False;
  end;
  FCount := 0;
end;

procedure TTextEditorNormalSearch.CaseSensitiveChanged;
begin
  if CaseSensitive then
    FPattern := FCasedPattern
  else
    FPattern := AnsiLowerCase(FCasedPattern);
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
    FResults.Add(Pointer(LPosition));
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
  FTextLength := Length(AText);
  if FTextLength >= FPatternLength then
  begin
    FTextToSearch := AText;
    if not CaseSensitive then
      CharLowerBuff(PChar(FTextToSearch), FTextLength);
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
