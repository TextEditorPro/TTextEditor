unit TextEditor.Lines;

{$I TextEditor.Defines.inc}

interface

uses
  System.Classes, System.SysUtils, TextEditor.Consts, TextEditor.Types, TextEditor.Utils;

const
  TEXT_EDITOR_STRING_RECORD_SIZE = SizeOf(TTextEditorStringRecord);
  TEXT_EDITOR_MAX_STRING_COUNT = MaxInt div TEXT_EDITOR_STRING_RECORD_SIZE;

type
  TTextEditorLines = class;
  TTextEditorStringListSortCompare = function(const AList: TTextEditorLines; const ALeft, ARight: Integer): Integer;

  PEditorStringRecordItems = ^TTextEditorStringRecordItems;
  TTextEditorStringRecordItems = array [0 .. TEXT_EDITOR_MAX_STRING_COUNT - 1] of TTextEditorStringRecord;

  TTextEditorLines = class(TStrings)
  strict private
    FBufferSize: Integer;
    FCapacity: Integer;
    FColumns: Boolean;
    FCount: Integer;
    FEncoding: System.SysUtils.TEncoding;
    FIndexOfLongestLine: Integer;
    FItems: PEditorStringRecordItems;
    FLengthOfLongestLine: Integer;
    FLineBreak: TTextEditorLineBreak;
    FLongestLineNeedsUpdate: Boolean;
    FOnAfterSetText: TNotifyEvent;
    FOnBeforePutted: TStringListChangeEvent;
    FOnBeforeSetText: TNotifyEvent;
    FOnChange: TNotifyEvent;
    FOnChanging: TNotifyEvent;
    FOnCleared: TNotifyEvent;
    FOnDeleted: TStringListChangeEvent;
    FOnInserted: TStringListChangeEvent;
    FOnPutted: TStringListChangeEvent;
    FOwner: TObject;
    FPaintProgress: TNotifyEvent;
    FProgressPosition: Byte;
    FProgressStep: Int64;
    FProgressType: TTextEditorProgressType;
    FSavingToStream: Boolean;
    FShowProgress: Boolean;
    FSortOptions: TTextEditorSortOptions;
    FStreaming: Boolean;
    FTabWidth: Integer;
    FTextLength: Integer;
    FTrimTrailingSpaces: Boolean;
    FUnknownCharHigh: Byte;
    FUnknownCharsVisible: Boolean;
    function ExpandString(const AIndex: Integer): string;
    function GetExpandedString(const AIndex: Integer): string;
    function GetExpandedStringLength(const AIndex: Integer): Integer;
    function GetLineBreakFromFlags(const AFlags: TTextEditorStringFlags): string; inline;
    function GetLineState(const AIndex: Integer): TTextEditorLineState;
    function GetPartialTextLength(const AStart, AEnd: Integer): Integer;
    function GetPartialTextStr(const AStart, AEnd: Integer): string;
    function GetRanges(const AIndex: Integer): TTextEditorLinesRange;
    function IsValidIndex(const AIndex: Integer): Boolean; inline;
    procedure ExchangeItems(const AIndex1, AIndex2: Integer);
    procedure Grow;
    procedure QuickSort(const ALeft, ARight: Integer; const ACompare: TTextEditorStringListSortCompare);
    procedure SetLineState(const AIndex: Integer; const AValue: TTextEditorLineState);
    procedure SetRanges(const AIndex: Integer; const ARange: TTextEditorLinesRange);
    procedure SetUnknownCharHigh;
  protected
    function CompareStrings(const S1, S2: string): Integer; override;
    function Get(AIndex: Integer): string; override;
    function GetCapacity: Integer; override;
    function GetCount: Integer; override;
    function GetTextStr: string; override;
    procedure InsertItem(const AIndex: Integer; const AValue: string);
    procedure Put(AIndex: Integer; const AValue: string); override;
    procedure SetCapacity(AValue: Integer); override;
    procedure SetEncoding(const AValue: System.SysUtils.TEncoding); override;
    procedure SetTabWidth(const AValue: Integer);
    procedure SetTextStr(const AValue: string); override;
    procedure SetUpdateState(AUpdating: Boolean); override;
  public
    constructor Create(AOwner: TObject);
    destructor Destroy; override;
    function Add(const AValue: string): Integer; override;
    function DefaultLineBreak: string;
    function GetLengthOfLongestLine: Integer;
    function GetLineBreak(const AIndex: Integer): string;
    function GetTextLength: Integer;
    function InternationalCharacterFound(var AChar, ALine: Integer): Boolean;
    function LineBreakLength(const AIndex: Integer): Integer;
    function StringLength(const AIndex: Integer): Integer;
    procedure AddLine(const AValue: string);
    procedure Clear; override;
    procedure ClearCompareFlags;
    procedure CustomSort(const ABeginLine: Integer; const AEndLine: Integer; ACompare: TTextEditorStringListSortCompare); virtual;
    procedure Delete(AIndex: Integer); override;
    procedure DeleteLines(const AIndex: Integer; const ACount: Integer);
    procedure DoTrimTrailingSpaces(const AIndex: Integer);
    procedure ExcludeFlag(const AIndex: Integer; const AFlag: TTextEditorStringFlag);
    procedure IncludeFlag(const AIndex: Integer; const AFlag: TTextEditorStringFlag);
    procedure Insert(AIndex: Integer; const AValue: string); override;
    procedure InsertLine(const AIndex: Integer; const AFlag: TTextEditorStringFlag);
    procedure InsertLines(const AIndex, ACount: Integer; const AModified: Boolean; const AStrings: TStrings = nil);
    procedure InsertText(const AIndex: Integer; const AText: string);
    procedure LoadFromFile(const AFileName: string; AEncoding: System.SysUtils.TEncoding); override;
    procedure LoadFromStream(AStream: TStream; AEncoding: System.SysUtils.TEncoding = nil); override;
    procedure LoadFromStrings(var AStrings: TStringList);
    procedure SaveToStream(AStream: TStream; AEncoding: System.SysUtils.TEncoding = nil); override;
    procedure Sort(const ABeginLine: Integer; const AEndLine: Integer); virtual;
    procedure Trim(const ATrimStyle: TTextEditorTrimStyle; const ABeginLine: Integer; const AEndLine: Integer);
    property BufferSize: Integer read FBufferSize write FBufferSize;
    property Columns: Boolean read FColumns write FColumns;
    property Count: Integer read FCount;
    property Encoding: TEncoding read FEncoding write SetEncoding;
    property ExpandedStringLengths[const AIndex: Integer]: Integer read GetExpandedStringLength;
    property ExpandedStrings[const AIndex: Integer]: string read GetExpandedString;
    property Items: PEditorStringRecordItems read FItems;
    property LineBreak: TTextEditorLineBreak read FLineBreak write FLineBreak default lbCRLF;
    property LineState[const AIndex: Integer]: TTextEditorLineState read GetLineState write SetLineState;
    property OnAfterSetText: TNotifyEvent read FOnAfterSetText write FOnAfterSetText;
    property OnBeforePutted: TStringListChangeEvent read FOnBeforePutted write FOnBeforePutted;
    property OnBeforeSetText: TNotifyEvent read FOnBeforeSetText write FOnBeforeSetText;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnChanging: TNotifyEvent read FOnChanging write FOnChanging;
    property OnCleared: TNotifyEvent read FOnCleared write FOnCleared;
    property OnDeleted: TStringListChangeEvent read FOnDeleted write FOnDeleted;
    property OnInserted: TStringListChangeEvent read FOnInserted write FOnInserted;
    property OnPutted: TStringListChangeEvent read FOnPutted write FOnPutted;
    property Owner: TObject read FOwner write FOwner;
    property PaintProgress: TNotifyEvent read FPaintProgress write FPaintProgress;
    property ProgressPosition: Byte read FProgressPosition write FProgressPosition;
    property ProgressStep: Int64 read FProgressStep write FProgressStep;
    property ProgressType: TTextEditorProgressType read FProgressType write FProgressType;
    property Ranges[const AIndex: Integer]: TTextEditorLinesRange read GetRanges write SetRanges;
    property ShowProgress: Boolean read FShowProgress write FShowProgress;
    property SortOptions: TTextEditorSortOptions read FSortOptions write FSortOptions;
    property Streaming: Boolean read FStreaming write FStreaming;
    property Strings[AIndex: Integer]: string read Get write Put; default; //FI:C110 Getter or setter name is different from property declaration
    property TabWidth: Integer read FTabWidth write SetTabWidth;
    property Text: string read GetTextStr write SetTextStr; //FI:C110 Getter or setter name is different from property declaration
    property TrimTrailingSpaces: Boolean read FTrimTrailingSpaces write FTrimTrailingSpaces;
    property UnknownCharHigh: Byte read FUnknownCharHigh;
    property UnknownCharsVisible: Boolean write FUnknownCharsVisible;
  end;

  ETextEditorLinesException = class(Exception);

implementation

uses
  System.Math, TextEditor.Encoding, TextEditor.Language;

{ TTextEditorLines }

{$IFDEF TEXT_EDITOR_RANGE_CHECKS}
procedure ListIndexOutOfBounds(const AIndex: Integer);
begin
  raise ETextEditorLinesException.CreateFmt(STextEditorListIndexOutOfBounds, [AIndex]);
end;
{$ENDIF}

constructor TTextEditorLines.Create;
begin
  inherited Create;

  FCount := 0;
  FOwner := AOwner;
  FIndexOfLongestLine := -1;
  FLengthOfLongestLine := 0;
  FLongestLineNeedsUpdate := False;
  FSavingToStream := False;
  FShowProgress := False;
  FTextLength := 0;
  TabWidth := 4;
  TrailingLineBreak := False;
  FLineBreak := lbCRLF;
  FEncoding := TEncoding.Default;
  Add(EmptyStr);
end;

destructor TTextEditorLines.Destroy;
begin
  FOnChange := nil;
  FOnChanging := nil;

  if FCount > 0 then
    Finalize(FItems^[0], FCount);

  FCount := 0;
  SetCapacity(0);

  inherited;
end;

procedure TTextEditorLines.AddLine(const AValue: string);
begin
  Add(AValue + DefaultLineBreak);
end;

function TTextEditorLines.Add(const AValue: string): Integer;
begin
  Result := FCount;

  InsertItem(Result, AValue);

  if Assigned(OnInserted) then
    OnInserted(Self, Result, 1);
end;

function TTextEditorLines.CompareStrings(const S1, S2: string): Integer;
begin
  if soRandom in FSortOptions then
    Exit(Random(2) - 1);

{$IF CompilerVersion >= 34.0}
  var LOptions: TCompareOptions := [];

  if soNatural in FSortOptions then
    Include(LOptions, coDigitAsNumbers);

  if soIgnoreCase in FSortOptions then
    Include(LOptions, coIgnoreCase);

  Result := String.Compare(S1, S2, LOptions);
{$ELSE}
  if soIgnoreCase in FSortOptions then
    Result := CompareText(S1, S2)
  else
    Result := CompareStr(S1, S2);
{$ENDIF}

  if soDesc in FSortOptions then
    Result := -1 * Result;
end;

function TTextEditorLines.GetLengthOfLongestLine: Integer;
var
  LIndex, LMaxLength: Integer;
  LPStringRecord: PTextEditorStringRecord;
begin
  if FIndexOfLongestLine < 0 then
  begin
    LMaxLength := 0;

    if FCount > 0 then
    begin
      LPStringRecord := @FItems^[0];

      for LIndex := 0 to FCount - 1 do
      begin
        if sfExpandedLengthUnknown in LPStringRecord^.Flags then
          ExpandString(LIndex);

        if LPStringRecord^.ExpandedLength > LMaxLength then
        begin
          LMaxLength := LPStringRecord^.ExpandedLength;
          FIndexOfLongestLine := LIndex;
        end;

        Inc(LPStringRecord);
      end;
    end;
  end;

  if (FIndexOfLongestLine >= 0) and (FIndexOfLongestLine < FCount) then
    Result := FItems^[FIndexOfLongestLine].ExpandedLength
  else
    Result := 0;
end;

function TTextEditorLines.GetLineBreakFromFlags(const AFlags: TTextEditorStringFlags): string;
begin
  if (sfLineBreakCR in AFlags) and (sfLineBreakLF in AFlags) then
    Result := TControlCharacters.CarriageReturnLineFeed
  else
  if sfLineBreakLF in AFlags then
    Result := TControlCharacters.Linefeed
  else
  if sfLineBreakCR in AFlags then
    Result := TControlCharacters.CarriageReturn
  else
    Result := DefaultLineBreak;
end;

function TTextEditorLines.GetLineBreak(const AIndex: Integer): string;
var
  LFlags: TTextEditorStringFlags;
  LPStringRecord: PTextEditorStringRecord;
begin
  LFlags := [];

  LPStringRecord := @FItems^[AIndex];

  if Assigned(LPStringRecord) then
    LFlags := LPStringRecord^.Flags;

  Result := GetLineBreakFromFlags(LFlags);
end;

function TTextEditorLines.LineBreakLength(const AIndex: Integer): Integer;
var
  LLineBreak: string;
begin
  if (AIndex < 0) or (AIndex > FCount - 1) then
    Exit(0);

  if (AIndex = FCount - 1) and not TrailingLineBreak then
    Result := 0
  else
  begin
    LLineBreak := GetLineBreak(AIndex);
    Result := Length(LLineBreak);
  end;
end;

function TTextEditorLines.StringLength(const AIndex: Integer): Integer;
begin
  if (AIndex < 0) or (AIndex > FCount - 1) then
    Result := 0
  else
    Result := Length(FItems^[AIndex].TextLine);
end;

procedure TTextEditorLines.Clear;
begin
  if FCount <> 0 then
  begin
    Finalize(FItems^[0], FCount);
    FCount := 0;
    SetCapacity(0);

    if Assigned(FOnCleared) then
      FOnCleared(Self);
  end;

  FIndexOfLongestLine := -1;
  FLengthOfLongestLine := 0;
end;

procedure TTextEditorLines.Delete(AIndex: Integer);
begin
{$IFDEF TEXT_EDITOR_RANGE_CHECKS}
  if (AIndex < 0) or (AIndex > FCount) then
    ListIndexOutOfBounds(AIndex);
{$ENDIF}

  Finalize(FItems^[AIndex]);
  Dec(FCount);

  if AIndex < FCount then
    System.Move(FItems[AIndex + 1], FItems[AIndex], (FCount - AIndex) * TEXT_EDITOR_STRING_RECORD_SIZE);

  FIndexOfLongestLine := -1;

  if Assigned(FOnDeleted) then
    FOnDeleted(Self, AIndex, 1);
end;

procedure TTextEditorLines.DeleteLines(const AIndex: Integer; const ACount: Integer);
var
  LLinesAfter: Integer;
  LCount: Integer;
begin
  LCount := ACount;

  if LCount > 0 then
  begin
{$IFDEF TEXT_EDITOR_RANGE_CHECKS}
    if (AIndex < 0) or (AIndex > FCount) then
      ListIndexOutOfBounds(AIndex);
{$ENDIF}

    LLinesAfter := FCount - (AIndex + LCount);

    if LLinesAfter < 0 then
      LCount := FCount - AIndex - 1;

    Finalize(FItems^[AIndex], LCount);

    if LLinesAfter > 0 then
      System.Move(FItems[AIndex + LCount], FItems[AIndex], LLinesAfter * TEXT_EDITOR_STRING_RECORD_SIZE);

    Dec(FCount, LCount);

    FIndexOfLongestLine := -1;

    if Assigned(FOnDeleted) then
      FOnDeleted(Self, AIndex, LCount);
  end;
end;

function TTextEditorLines.ExpandString(const AIndex: Integer): string;
var
  LHasTabs: Boolean;
begin
  with FItems^[AIndex] do
  begin
    if TextLine.IsEmpty then
    begin
      Result := '';

      Exclude(Flags, sfExpandedLengthUnknown);
      Exclude(Flags, sfHasTabs);
      Include(Flags, sfHasNoTabs);
      ExpandedLength := 0;
    end
    else
    begin
      Result := ConvertTabs(TextLine, FTabWidth, LHasTabs, FColumns);

      ExpandedLength := Length(Result);
      Exclude(Flags, sfExpandedLengthUnknown);
      Exclude(Flags, sfHasTabs);
      Exclude(Flags, sfHasNoTabs);

      if LHasTabs then
        Include(Flags, sfHasTabs)
      else
        Include(Flags, sfHasNoTabs);
    end;
  end;
end;

function TTextEditorLines.IsValidIndex(const AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < FCount);
end;

function TTextEditorLines.Get(AIndex: Integer): string;
begin
  if IsValidIndex(AIndex) then
    Result := FItems^[AIndex].TextLine
  else
    Result := '';
end;

function TTextEditorLines.GetCapacity: Integer;
begin
  Result := FCapacity;
end;

function TTextEditorLines.GetCount: Integer;
begin
  Result := FCount;
end;

function TTextEditorLines.GetExpandedString(const AIndex: Integer): string;
begin
  if IsValidIndex(AIndex) then
  begin
    if sfHasNoTabs in FItems^[AIndex].Flags then
      Result := Get(AIndex)
    else
      Result := ExpandString(AIndex);
  end
  else
    Result := '';
end;

function TTextEditorLines.GetExpandedStringLength(const AIndex: Integer): Integer;
begin
  if IsValidIndex(AIndex) then
  begin
    if sfExpandedLengthUnknown in FItems^[AIndex].Flags then
      Result := Length(ExpandedStrings[AIndex])
    else
      Result := FItems^[AIndex].ExpandedLength;
  end
  else
    Result := 0;
end;

function TTextEditorLines.GetLineState(const AIndex: Integer): TTextEditorLineState;
var
  LFlags: TTextEditorStringFlags;
begin
  Result := lsNone;

  if IsValidIndex(AIndex) then
  begin
    LFlags := FItems^[AIndex].Flags;

    if sfLineStateNormal in LFlags then
      Result := lsNormal
    else
    if sfLineStateModified in LFlags then
      Result := lsModified
  end
end;

procedure TTextEditorLines.ExcludeFlag(const AIndex: Integer; const AFlag: TTextEditorStringFlag);
begin
  if IsValidIndex(AIndex) then
    Exclude(FItems^[AIndex].Flags, AFlag);
end;

procedure TTextEditorLines.IncludeFlag(const AIndex: Integer; const AFlag: TTextEditorStringFlag);
begin
  if IsValidIndex(AIndex) then
    Include(FItems^[AIndex].Flags, AFlag);
end;

procedure TTextEditorLines.SetLineState(const AIndex: Integer; const AValue: TTextEditorLineState);
begin
  if IsValidIndex(AIndex) then
  with FItems^[AIndex] do
  begin
    Exclude(Flags, sfLineStateNormal);
    Exclude(Flags, sfLineStateModified);

    if AValue = lsNormal then
      Include(Flags, sfLineStateNormal)
    else
    if AValue = lsModified then
      Include(Flags, sfLineStateModified)
  end;
end;

function TTextEditorLines.GetRanges(const AIndex: Integer): TTextEditorLinesRange;
begin
  if IsValidIndex(AIndex) then
    Result := FItems^[AIndex].Range
  else
    Result := nil;
end;

function TTextEditorLines.GetTextLength: Integer;
var
  LIndex: Integer;
begin
  Result := 0;

  for LIndex := 0 to FCount - 1 do
  with FItems^[LIndex] do
  begin
    if FSavingToStream and TrimTrailingSpaces then
      TextLine := TextEditor.Utils.TrimRight(TextLine);

    if FSavingToStream and (sfEmptyLine in Flags) then
      Continue;

    Inc(Result, Length(TextLine) + LineBreakLength(LIndex))
  end;
end;

function TTextEditorLines.InternationalCharacterFound(var AChar, ALine: Integer): Boolean;
var
  LIndex, LLength: Integer;
  LPValue, LPLastChar, LPStart: PChar;
  LStringRecord: TTextEditorStringRecord;
begin
  Result := True;

  for LIndex := 0 to FCount - 1 do
  begin
    LStringRecord := FItems^[LIndex];

    LLength := Length(LStringRecord.TextLine);

    if LLength > 0 then
    begin
      LPValue := @LStringRecord.TextLine[1];
      LPStart := LPValue;
      LPLastChar := @LStringRecord.TextLine[LLength];

      while LPValue <= LPLastChar do
      begin
        if Ord(LPValue^) > 255 then
        begin
          ALine := LIndex;
          AChar := LPValue - LPStart + 1;
          Exit;
        end;

        Inc(LPValue);
      end;
    end;
  end;

  Result := False;
end;

function TTextEditorLines.GetPartialTextLength(const AStart, AEnd: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := 0;

  for LIndex := AStart to AEnd - 1 do
  with FItems^[LIndex] do
  begin
    if FSavingToStream and TrimTrailingSpaces then
      TextLine := TextEditor.Utils.TrimRight(TextLine);

    if FSavingToStream and (sfEmptyLine in Flags) then
      Continue;

    Inc(Result, Length(TextLine) + LineBreakLength(LIndex))
  end;
end;

procedure TTextEditorLines.ClearCompareFlags;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FCount - 1 do
    Exclude(FItems^[LIndex].Flags, sfModify);

  for LIndex := Count - 1 downto 0 do
  if sfEmptyLine in FItems^[LIndex].Flags then
  begin
    Finalize(FItems^[LIndex]);
    Dec(FCount);

    if LIndex < FCount then
      System.Move(FItems[LIndex + 1], FItems[LIndex], (FCount - LIndex) * TEXT_EDITOR_STRING_RECORD_SIZE);
  end;
end;

function TTextEditorLines.DefaultLineBreak: string;
begin
  case FLineBreak of
    lbCRLF:
      Result := TControlCharacters.CarriageReturnLinefeed;
    lbCR:
      Result := TControlCharacters.CarriageReturn;
    lbLF:
      Result := TControlCharacters.Linefeed;
  end;
end;

function TTextEditorLines.GetPartialTextStr(const AStart, AEnd: Integer): string;
var
  LIndex, LIndex2, LLength, LSize, LLineBreakLength: Integer;
  LPValue: PChar;
  LLineBreak: string;
  LStringRecord: TTextEditorStringRecord;
begin
  if FTextLength = 0 then
    LSize := GetPartialTextLength(AStart, AEnd)
  else
    LSize := FTextLength;

  SetString(Result, nil, LSize);

  FTextLength := 0;
  LPValue := Pointer(Result);

  for LIndex := AStart to AEnd - 1 do
  begin
    LStringRecord := FItems^[LIndex];

    if FSavingToStream and (sfEmptyLine in LStringRecord.Flags) then
      Continue;

    LLineBreak := GetLineBreakFromFlags(LStringRecord.Flags);
    LLineBreakLength := LLineBreak.Length;
    LLength := LStringRecord.TextLine.Length;

    if LLength <> 0 then
    begin
      System.Move(Pointer(LStringRecord.TextLine)^, LPValue^, LLength * SizeOf(Char));

      LIndex2 := 0;

      while LIndex2 < LLength do
      begin
        if LPValue^ = TControlCharacters.Substitute then
          LPValue^ := TControlCharacters.Null;

        Inc(LPValue);
        Inc(LIndex2);
      end;
    end;

    if TrailingLineBreak or (LIndex < Count - 1) then
    begin
      System.Move(Pointer(LLineBreak)^, LPValue^, LLineBreakLength * SizeOf(Char));
      Inc(LPValue, LLineBreakLength);
    end;
  end;
end;

function TTextEditorLines.GetTextStr: string;
var
  LIndex, LIndex2, LLength, LSize, LLineBreakLength: Integer;
  LPValue: PChar;
  LLineBreak: string;
  LStringRecord: TTextEditorStringRecord;
begin
  if FTextLength = 0 then
    LSize := GetTextLength
  else
    LSize := FTextLength;

  FTextLength := 0;

  SetString(Result, nil, LSize);
  LPValue := Pointer(Result);

  for LIndex := 0 to FCount - 1 do
  begin
    LStringRecord := FItems^[LIndex];

    if FSavingToStream and (sfEmptyLine in LStringRecord.Flags) then
      Continue;

    LLineBreak := GetLineBreakFromFlags(LStringRecord.Flags);
    LLineBreakLength := LLineBreak.Length;
    LLength := LStringRecord.TextLine.Length;

    if LLength <> 0 then
    begin
      System.Move(Pointer(LStringRecord.TextLine)^, LPValue^, LLength * SizeOf(Char));
      LIndex2 := 0;

      while LIndex2 < LLength do
      begin
        if LPValue^ = TControlCharacters.Substitute then
          LPValue^ := TControlCharacters.Null;

        Inc(LPValue);
        Inc(LIndex2);
      end;
    end;

    if TrailingLineBreak or (LIndex < Count - 1) then
    begin
      System.Move(Pointer(LLineBreak)^, LPValue^, LLineBreakLength * SizeOf(Char));
      Inc(LPValue, LLineBreakLength);
    end;
  end;
end;

{$IF CompilerVersion >= 33.0}
procedure TTextEditorLines.Grow;
begin
  SetCapacity(GrowCollection(FCapacity, FCount + 1));
end;
{$ELSE}
procedure TTextEditorLines.Grow;
var
  LDelta: Integer;
begin
  if FCapacity > 64 then
    LDelta := (FCapacity * 3) shr 1
  else
  if FCapacity > 8 then
    LDelta := 16
  else
    LDelta :=  4;

  SetCapacity(FCapacity + LDelta);
end;
{$ENDIF}

procedure TTextEditorLines.Insert(AIndex: Integer; const AValue: string);
begin
{$IFDEF TEXT_EDITOR_RANGE_CHECKS}
  if (AIndex < 0) or (AIndex > FCount) then
    ListIndexOutOfBounds(AIndex);
{$ENDIF}
  BeginUpdate;

  InsertItem(AIndex, AValue);

  if Assigned(FOnInserted) then
    FOnInserted(Self, AIndex, 1);

  EndUpdate;
end;

procedure TTextEditorLines.InsertItem(const AIndex: Integer; const AValue: string);
begin
  if FCount = FCapacity then
    Grow;

  if AIndex < FCount then
    System.Move(FItems^[AIndex], FItems^[AIndex + 1], (FCount - AIndex) * TEXT_EDITOR_STRING_RECORD_SIZE);

  FIndexOfLongestLine := -1;

  with FItems^[AIndex] do
  begin
    Pointer(TextLine) := nil;
    TextLine := AValue;
    Range := nil;
    ExpandedLength := -1;
    Flags := [sfExpandedLengthUnknown];
  end;

  Inc(FCount);
end;

procedure TTextEditorLines.InsertLine(const AIndex: Integer; const AFlag: TTextEditorStringFlag);
begin
{$IFDEF TEXT_EDITOR_RANGE_CHECKS}
  if (AIndex < 0) or (AIndex > FCount) then
    ListIndexOutOfBounds(AIndex);
{$ENDIF}
  SetCapacity(FCount + 1);

  if AIndex < FCount then
    System.Move(FItems^[AIndex], FItems^[AIndex + 1], (FCount - AIndex) * TEXT_EDITOR_STRING_RECORD_SIZE);

  FIndexOfLongestLine := -1;

  with FItems^[AIndex] do
  begin
    Pointer(TextLine) := nil;
    TextLine := '';
    Range := nil;
    ExpandedLength := -1;
    Flags := [AFlag];
  end;

  Inc(FCount);

  if Assigned(OnInserted) and (AFlag <> sfEmptyLine) then
    OnInserted(Self, AIndex, 1);
end;

procedure TTextEditorLines.InsertLines(const AIndex, ACount: Integer; const AModified: Boolean; const AStrings: TStrings = nil);
var
  LIndex: Integer;
  LLine: Integer;
begin
{$IFDEF TEXT_EDITOR_RANGE_CHECKS}
  if (AIndex < 0) or (AIndex > FCount) then
    ListIndexOutOfBounds(AIndex);
{$ENDIF}
  if ACount > 0 then
  begin
    SetCapacity(FCount + ACount);

    if AIndex < FCount then
      System.Move(FItems^[AIndex], FItems^[AIndex + ACount], (FCount - AIndex) * TEXT_EDITOR_STRING_RECORD_SIZE);

    FIndexOfLongestLine := -1;
    LIndex := 0;

    for LLine := AIndex to AIndex + ACount - 1 do
    with FItems^[LLine] do
    begin
      Pointer(TextLine) := nil;

      if Assigned(AStrings) then
        TextLine := AStrings[LIndex];

      Inc(LIndex);
      Range := nil;
      ExpandedLength := -1;

      if AModified then
        Flags := [sfExpandedLengthUnknown, sfLineStateModified]
      else
        Flags := [sfExpandedLengthUnknown];
    end;

    Inc(FCount, ACount);

    if Assigned(OnInserted) then
      OnInserted(Self, AIndex, ACount);
  end;
end;

procedure TTextEditorLines.InsertText(const AIndex: Integer; const AText: string);
var
  LStringList: TStringList;
begin
  if AText.IsEmpty then
    Exit;

  LStringList := TStringList.Create;
  try
    LStringList.Text := AText;
    InsertLines(AIndex, LStringList.Count, True, LStringList);
  finally
    LStringList.Free;
  end;
end;

procedure TTextEditorLines.SetUnknownCharHigh;
begin
  FUnknownCharHigh := 0;

  if FUnknownCharsVisible then
  begin
    if Encoding = System.SysUtils.TEncoding.ANSI then
      FUnknownCharHigh := 255
    else
    if Encoding = System.SysUtils.TEncoding.ASCII then
      FUnknownCharHigh := 127
  end;
end;

function StringListCompareStrings(const AList: TTextEditorLines; const ALeft, ARight: Integer): Integer;
begin
  Result := AList.CompareStrings(AList[ALeft], AList[ARight]);
end;

procedure TTextEditorLines.Sort(const ABeginLine: Integer; const AEndLine: Integer);
begin
  CustomSort(ABeginLine, AEndLine, StringListCompareStrings);
end;

procedure TTextEditorLines.Trim(const ATrimStyle: TTextEditorTrimStyle; const ABeginLine: Integer; const AEndLine: Integer);
var
  LIndex: Integer;
begin
  for LIndex := ABeginLine to AEndLine do
  with FItems^[LIndex] do
  case ATrimStyle of
    tsBoth:
      TextLine := TextEditor.Utils.Trim(TextLine);
    tsLeft:
      TextLine := TextEditor.Utils.TrimLeft(TextLine);
    tsRight:
      TextLine := TextEditor.Utils.TrimRight(TextLine);
  end;
end;

procedure TTextEditorLines.CustomSort(const ABeginLine: Integer; const AEndLine: Integer;
  ACompare: TTextEditorStringListSortCompare);
begin
  if FCount > 1 then
    QuickSort(ABeginLine, AEndLine, ACompare);
end;

procedure TTextEditorLines.ExchangeItems(const AIndex1, AIndex2: Integer);
var
  Item1, Item2: PTextEditorStringRecord;
  LFlags: TTextEditorStringFlags;
  LExpandedLength: Integer;
  LRange: TTextEditorLinesRange;
  LValue: Pointer;
begin
  Item1 := @FItems[AIndex1];
  Item2 := @FItems[AIndex2];

  LFlags := Item1^.Flags;
  Item1^.Flags := Item2^.Flags;
  Item2^.Flags := LFlags;

  LExpandedLength := Item1^.ExpandedLength;
  Item1^.ExpandedLength := Item2^.ExpandedLength;
  Item2^.ExpandedLength := LExpandedLength;

  LRange := Pointer(Item1^.Range);
  Pointer(Item1^.Range) := Pointer(Item2^.Range);
  Pointer(Item2^.Range) := LRange;

  LValue := Pointer(Item1^.TextLine);
  Pointer(Item1^.TextLine) := Pointer(Item2^.TextLine);
  Pointer(Item2^.TextLine) := LValue;
end;

procedure TTextEditorLines.QuickSort(const ALeft, ARight: Integer; const ACompare: TTextEditorStringListSortCompare);
var
  LLeft, LRight, LMiddle: Integer;
begin
  LLeft := ALeft;
  LRight := ARight;
  LMiddle := (ALeft + ARight) shr 1;

  repeat
    while ACompare(Self, LLeft, LMiddle) < 0 do
      Inc(LLeft);

    while ACompare(Self, LRight, LMiddle) > 0 do
      Dec(LRight);

    if LLeft <= LRight then
    begin
      if LLeft <> LRight then
        ExchangeItems(LLeft, LRight);

      if LMiddle = LLeft then
        LMiddle := LRight
      else
      if LMiddle = LRight then
        LMiddle := LLeft;

      Inc(LLeft);
      Dec(LRight);
    end;
  until LLeft > LRight;

  if LRight > ALeft then
    QuickSort(ALeft, LRight, ACompare);

  if LLeft < ARight then
    QuickSort(LLeft, ARight, ACompare);
end;

procedure TTextEditorLines.LoadFromStrings(var AStrings: TStringList);
var
  LIndex: Integer;
begin
  FStreaming := True;

  BeginUpdate;
  try
    if Assigned(FOnBeforeSetText) then
      FOnBeforeSetText(Self);

    Clear;
    FIndexOfLongestLine := -1;
    FCount := AStrings.Count;

    if FCount > 0 then
    begin
      SetCapacity(AStrings.Capacity);

      for LIndex := 0 to FCount - 1 do
      with FItems^[LIndex] do
      begin
        Pointer(TextLine) := nil;
        TextLine := AStrings[LIndex];
        Range := nil;
        ExpandedLength := -1;
        Flags := [sfExpandedLengthUnknown];
        OriginalLineNumber := LIndex;
      end;
    end;

    AStrings.Clear;

    if Assigned(FOnInserted) then
      FOnInserted(Self, 0, FCount);

    if Assigned(FOnChange) then
      FOnChange(Self);

    if Assigned(FOnAfterSetText) then
      FOnAfterSetText(Self);
  finally
    EndUpdate;
  end;

  FStreaming := False;
end;

procedure TTextEditorLines.LoadFromFile(const AFileName: string; AEncoding: System.SysUtils.TEncoding);
var
  LStream: TStream;
begin
  if not FileExists(AFilename) then
    Exit;

  LStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(LStream, AEncoding);
  finally
    LStream.Free;
  end;
end;

procedure TTextEditorLines.LoadFromStream(AStream: TStream; AEncoding: System.SysUtils.TEncoding = nil);
var
  LBuffer: TBytes;
  LBufferSize: Integer;
  LEncoding: System.SysUtils.TEncoding;
  LWithBOM: Boolean;
  LStreamReader: TStreamReader;
  LCharBuffer: TCharArray;
  LContent: string;
  LProgressPosition, LProgress: Int64;
  LPValue, LPLastChar, LPStartValue: PChar;
  LReadCount: Integer;
  LFlags: TTextEditorStringFlags;
  LLineBreak: Boolean;
  LTempLine: string;
begin
  FStreaming := True;

  if AStream.Size > FBufferSize then
    LBufferSize := FBufferSize
  else
    LBufferSize := AStream.Size;

  LEncoding := nil;

  if Assigned(AEncoding) then
    LEncoding := AEncoding
  else
  begin
    SetLength(LBuffer, LBufferSize);
    AStream.ReadBuffer(LBuffer, Length(LBuffer));

    if IsUTF8Buffer(LBuffer, LWithBOM) then
    begin
      if LWithBOM then
        LEncoding := TEncoding.UTF8
      else
        LEncoding := TextEditor.Encoding.TEncoding.UTF8WithoutBOM;
    end
    else
      TEncoding.GetBufferEncoding(LBuffer, LEncoding);

    SetLength(LBuffer, 0);
  end;

  Encoding := LEncoding;

  LProgress := FProgressStep;
  LProgressPosition := 0;
  LLineBreak := True;

  BeginUpdate;
  try
    Clear;

    AStream.Position := 0;

    LStreamReader := TStreamReader.Create(AStream, Encoding, True, LBufferSize);
    try
      try
        SetLength(LCharBuffer, LBufferSize);

        while not LStreamReader.EndOfStream do
        begin
          LReadCount := LStreamReader.ReadBlock(LCharBuffer, 0, LBufferSize);

          if LReadCount > 0 then
          begin
            SetString(LContent, PChar(@LCharBuffer[0]), LReadCount);

            LPValue := @LContent[1];
            LPLastChar := @LContent[LReadCount];

            while LPValue <= LPLastChar do
            begin
              LPStartValue := LPValue;

              while LPValue <= LPLastChar do
              begin
                if IsLineTerminatorCharacter(LPValue^) then
                  Break;

                if LPValue^ = TControlCharacters.Null then
                  LPValue^ := TControlCharacters.Substitute;

                Inc(LPValue);
              end;

              if FCount = FCapacity then
                Grow;

              with FItems^[FCount] do
              begin
                if LLineBreak then
                  Pointer(TextLine) := nil;

                if LPValue = LPStartValue then
                  TextLine := ''
                else
                  SetString(TextLine, LPStartValue, LPValue - LPStartValue);

                if not LLineBreak then
                  TextLine := LTempLine + TextLine;

                Range := nil;
                ExpandedLength := -1;
                Flags := [sfExpandedLengthUnknown];
                OriginalLineNumber := FCount;

                if LPValue^ = TControlCharacters.CarriageReturn then
                begin
                  Inc(LPValue);
                  Include(Flags, sfLineBreakCR);
                end;

                if LPValue^ = TControlCharacters.Linefeed then
                begin
                  Inc(LPValue);
                  Include(Flags, sfLineBreakLF);
                end;

                LLineBreak := Flags * [sfLineBreakCR, sfLineBreakLF] <> [];

                if LLineBreak then
                  Inc(FCount)
                else
                  LTempLine := TextLine;
              end;

              if FShowProgress then
              begin
                Inc(LProgressPosition, LPValue - LPStartValue);

                if LProgressPosition > LProgress then
                begin
                  Inc(FProgressPosition);

                  if Assigned(FPaintProgress) then
                    FPaintProgress(nil);

                  Inc(LProgress, FProgressStep);
                end;
              end;
            end;
          end;
        end;

        if not LLineBreak then
          Inc(FCount);

        if FCount > 0 then
        begin
          if LLineBreak then
          begin
            if FCount = FCapacity then
              Grow;

            with FItems^[FCount] do
            begin
              Pointer(TextLine) := nil;
              TextLine := '';
              Range := nil;
              ExpandedLength := -1;
              Flags := [sfExpandedLengthUnknown];
              OriginalLineNumber := FCount;
            end;

            Inc(FCount);
          end;

          LFlags := FItems^[0].Flags;

          if (sfLineBreakCR in LFlags) and (sfLineBreakLF in LFlags) then
            LineBreak := lbCRLF
          else
          if sfLineBreakCR in LFlags then
            LineBreak := lbCR
          else
          if sfLineBreakLF in LFlags then
            LineBreak := lbLF;
        end;
      except
        on E: Exception do
          raise ETextEditorLinesException.Create(E.Message);
      end;
    finally
      LStreamReader.Free;
    end;
  finally
    EndUpdate;
  end;

  if Assigned(OnInserted) then
    OnInserted(Self, 0, FCount);

  if Assigned(FOnChange) then
    FOnChange(Self);

  FStreaming := False;
end;

procedure TTextEditorLines.SaveToStream(AStream: TStream; AEncoding: System.SysUtils.TEncoding);
var
  LBuffer, LPreamble: TBytes;
  LStart, LPreviousStart, LEnd, LLineInc: Integer;
  LText: string;
begin
  if Assigned(AEncoding) then
    Encoding := AEncoding;

  WriteBOM := FEncoding <> TEncoding.UTF8WithoutBOM;

  FStreaming := True;
  FSavingToStream := True;
  try
    LPreamble := FEncoding.GetPreamble;

    if Length(LPreamble) > 0 then
      AStream.WriteBuffer(LPreamble[0], Length(LPreamble));

    FTextLength := GetTextLength;

    if FTextLength >= TMaxValues.TextLength then
    begin
      LPreviousStart := 0;
      LEnd := 0;
      LLineInc := FCount shr 1;

      while LEnd < FCount do
      begin
        LStart := LEnd;
        LEnd := Min(LEnd + LLineInc, FCount);
        FTextLength := GetPartialTextLength(LStart, LEnd);

        if FTextLength >= TMaxValues.TextLength then
        begin
          LEnd := LPreviousStart;
          LLineInc := LLineInc shr 1;
        end
        else
        begin
          LPreviousStart := LStart;
          LText := GetPartialTextStr(LStart, LEnd);
          LBuffer := FEncoding.GetBytes(LText);
          SetLength(LText, 0);
          AStream.WriteBuffer(LBuffer[0], Length(LBuffer));
        end;
      end
    end
    else
    if FTextLength > 0 then
    begin
      LText := GetTextStr;
      LBuffer := FEncoding.GetBytes(LText);
      SetLength(LText, 0);
      AStream.WriteBuffer(LBuffer[0], Length(LBuffer));
    end;
  finally
    FSavingToStream := False;
    FStreaming := False;
  end;
end;

procedure TTextEditorLines.Put(AIndex: Integer; const AValue: string);
var
  LHasTabs: Boolean;
begin
  if (AIndex = 0) and (FCount = 0) or (FCount = AIndex) then
  begin
    Add(AValue);
    Include(FItems^[AIndex].Flags, sfLineStateModified);
  end
  else
  begin
{$IFDEF TEXT_EDITOR_RANGE_CHECKS}
    if (AIndex < 0) or (AIndex >= FCount) then
      ListIndexOutOfBounds(AIndex);
{$ENDIF}
    if Assigned(OnBeforePutted) then
      OnBeforePutted(Self, AIndex, 1);

    with FItems^[AIndex] do
    begin
      Include(Flags, sfExpandedLengthUnknown);
      Exclude(Flags, sfHasTabs);
      Exclude(Flags, sfHasNoTabs);
      Exclude(Flags, sfEmptyLine);
      TextLine := AValue;
      Include(Flags, sfLineStateModified);
    end;

    if FIndexOfLongestLine <> -1 then
      if FItems^[FIndexOfLongestLine].ExpandedLength < Length(ConvertTabs(AValue, FTabWidth, LHasTabs, FColumns)) then
        FIndexOfLongestLine := AIndex;

    if Assigned(FOnPutted) then
      FOnPutted(Self, AIndex, 1);
  end;
end;

procedure TTextEditorLines.DoTrimTrailingSpaces(const AIndex: Integer);
begin
{$IFDEF TEXT_EDITOR_RANGE_CHECKS}
  if IsValidIndex(AIndex) then
{$ENDIF}
  with FItems^[AIndex] do
  TextLine := TextEditor.Utils.TrimRight(TextLine);
end;

procedure TTextEditorLines.SetRanges(const AIndex: Integer; const ARange: TTextEditorLinesRange);
begin
{$IFDEF TEXT_EDITOR_RANGE_CHECKS}
  if (AIndex < 0) or (AIndex >= FCount) then
    ListIndexOutOfBounds(AIndex);
{$ENDIF}

  FItems^[AIndex].Range := ARange;
end;

procedure TTextEditorLines.SetCapacity(AValue: Integer);
begin
  if AValue < Count then
    EListError.Create(STextEditorInvalidCapacity);

  if AValue <> FCapacity then
  begin
    ReallocMem(FItems, AValue * TEXT_EDITOR_STRING_RECORD_SIZE);
    FCapacity := AValue;
  end;

  if (FCapacity > 0) and not Assigned(FItems) then
    OutOfMemoryError;
end;

procedure TTextEditorLines.SetEncoding(const AValue: System.SysUtils.TEncoding);
begin
  FEncoding := AValue;

  SetUnknownCharHigh;
end;

procedure TTextEditorLines.SetTabWidth(const AValue: Integer);
var
  LIndex: Integer;
begin
  if FTabWidth <> AValue then
  begin
    FTabWidth := AValue;
    FIndexOfLongestLine := -1;

    for LIndex := 0 to FCount - 1 do
    with FItems^[LIndex] do
    begin
      ExpandedLength := -1;
      Exclude(Flags, sfHasNoTabs);
      Include(Flags, sfExpandedLengthUnknown);
    end;
  end;
end;

procedure TTextEditorLines.SetTextStr(const AValue: string);
var
  LLength: Integer;
  LPValue, LPStartValue, LPLastChar: PChar;
begin
  if Assigned(FOnBeforeSetText) then
    FOnBeforeSetText(Self);

  BeginUpdate;
  try
    Clear;
    FIndexOfLongestLine := -1;
    LLength := Length(AValue);

    if LLength > 0 then
    begin
      LPValue := @AValue[1];
      LPLastChar := @AValue[LLength];

      while LPValue <= LPLastChar do
      begin
        LPStartValue := LPValue;

        while LPValue <= LPLastChar do
        if IsLineTerminatorCharacter(LPValue^) then
          Break
        else
          Inc(LPValue);

        if FCount = FCapacity then
          Grow;

        with FItems^[FCount] do
        begin
          Pointer(TextLine) := nil;

          if LPValue = LPStartValue then
            TextLine := ''
          else
            SetString(TextLine, LPStartValue, LPValue - LPStartValue);

          Range := nil;
          ExpandedLength := -1;
          Flags := [sfExpandedLengthUnknown];
          OriginalLineNumber := FCount;

          Inc(FCount);

          if LPValue^ = TControlCharacters.CarriageReturn then
          begin
            Inc(LPValue);
            Include(Flags, sfLineBreakCR);
          end;

          if LPValue^ = TControlCharacters.Linefeed then
          begin
            Inc(LPValue);
            Include(Flags, sfLineBreakLF);
          end;
        end;
      end;
    end;
  finally
    EndUpdate;
  end;

  if Assigned(FOnInserted) then
    FOnInserted(Self, 0, FCount);

  if Assigned(FOnChange) then
    FOnChange(Self);

  if Assigned(FOnAfterSetText) then
    FOnAfterSetText(Self);
end;

procedure TTextEditorLines.SetUpdateState(AUpdating: Boolean);
begin
  if AUpdating then
  begin
    if Assigned(FOnChanging) then
      FOnChanging(Self);
  end
  else
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

end.
