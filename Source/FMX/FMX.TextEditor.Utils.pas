{$WARN WIDECHAR_REDUCED OFF} // CharInSet is slow in loops
{$WARN IMPLICIT_STRING_CAST OFF}
unit FMX.TextEditor.Utils;

interface

uses
  System.Classes, System.SysUtils, System.Types, System.UITypes, FMX.Graphics, FMX.TextEditor.Types;

function AutoCursor(const ACursor: TCursor = crHourGlass): IAutoCursor;
function CaseNone(const AChar: Char): Char; inline;
function CaseStringNone(const AString: string): string; inline;
function CaseUpper(const AChar: Char): Char; inline;
function CharInString(const AChar: Char; const AString: string): Boolean; inline;
function ConvertTabs(const ALine: string; ATabWidth: Integer; var AHasTabs: Boolean; const AColumns: Boolean): string;
function DeleteWhitespace(const AValue: string): string;
function FormatForClipboard(const AText: string): UTF8String;
function GetBOFPosition: TTextEditorTextPosition; inline;
function GetPosition(const AChar, ALine: Integer): TTextEditorTextPosition; inline;
function GetViewPosition(const AColumn: Integer; const ARow: Integer): TTextEditorViewPosition; inline;
function IsAnsiUnicodeChar(const AChar: Char): Boolean; inline;
function IsCombiningCharacter(const AChar: PChar): Boolean; inline;
function IsRightToLeftCharacter(const AChar: Char; const AAllowEmptySpace: Boolean = True): Boolean; inline;
function IsSamePosition(const APosition1, APosition2: TTextEditorTextPosition): Boolean; inline;
function IsUTF8Buffer(const ABuffer: TBytes; out AWithBOM: Boolean): Boolean;
function MiddleColor(const AColor1, AColor2: TAlphaColor): TAlphaColor; inline;
function TextEditorAlphaColorToColor(const AColor: TAlphaColor): TColor;
function TextEditorColorToAlphaColor(const AColor: TColor): TAlphaColor;
function TextAdvance(const ACanvas: TCanvas; const AText: string): Single;
function TextHeight(const ACanvas: TCanvas; const AText: string): Single; inline;
function TextWidth(const ACanvas: TCanvas; const AText: string): Single; inline;
function TitleCase(const AValue: string): string;
function ToggleCase(const AValue: string): string;
function Trim(const AText: string): string;
function TrimLeft(const AText: string): string;
function TrimRight(const AText: string): string;
procedure ClearList(var AList: TList);
procedure FreeList(var AList: TList);
procedure ResizeBitmap(const ABitmap: TBitmap; const ANewWidth, ANewHeight: Integer);
procedure TextEditorBeep;
{$IFDEF MSWINDOWS}
function TrySetClipboardTextWithHTML(const AText, AHTML: string): Boolean;
{$ENDIF}

implementation

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$ENDIF}
  System.Character, System.Generics.Collections, FMX.Forms, FMX.TextEditor.Consts;

const
  TEXT_EDITOR_UTF8_BOM: array [0 .. 2] of Byte = ($EF, $BB, $BF);

type
  TCursorPair = record
    NewCursor : TCursor;
    OriginalCursor: TCursor;
    procedure Initialize(const AOriginalCursor, ANewCursor: TCursor);
  end;

  TAutoCursor = class(TInterfacedObject, IAutoCursor)
  private
    FCursorStack: TList<TCursorPair>;
    function AddCursorToStack(const ACursor: TCursor): Integer;
    procedure EndCursor(const AResetToFirst: Boolean); overload;
  public
    constructor Create(const ACursor: TCursor);
    destructor Destroy; override;
    procedure BeginCursor(const ACursor: TCursor);
    procedure EndCursor; overload;
  end;

function AutoCursor(const ACursor: TCursor = crHourGlass): IAutoCursor;
begin
  Result := TAutoCursor.Create(aCursor);
end;

function ToggleCase(const AValue: string): string;
var
  LValue: string;
begin
  Result := UpperCase(AValue);

  LValue := LowerCase(AValue);

  for var LIndex := 1 to AValue.Length do
  if Result[LIndex] = AValue[LIndex] then
    Result[LIndex] := LValue[LIndex];
end;

function TitleCase(const AValue: string): string;
var
  LIndex, LLength: Integer;
  LChar: string;
begin
  Result := '';

  LIndex := 1;
  LLength := AValue.Length;

  SetLength(Result, LLength);

  while LIndex <= LLength do
  begin
    LChar := AValue[LIndex];

    if LIndex > 1 then
      LChar := if AValue[LIndex - 1] = ' ' then UpperCase(LChar) else LowerCase(LChar)
    else
      LChar := UpperCase(LChar);

    Result[LIndex] := LChar[1];

    Inc(LIndex);
  end;
end;

function Trim(const AText: string): string;
var
  LLength, LIndex: Integer;
begin
  LLength := AText.Length - 1;
  LIndex := 0;

  if (LLength = -1) or (AText.Chars[LIndex] > ' ') and (AText.Chars[LLength] > ' ') then
    Exit(AText);

  while (LIndex <= LLength) and (AText.Chars[LIndex] <= ' ') do
  if AText.Chars[LIndex] = TControlCharacters.Substitute then
    Break
  else
    Inc(LIndex);

  if LIndex > LLength then
    Exit('');

  while AText.Chars[LLength] <= ' ' do
  if AText.Chars[LIndex] = TControlCharacters.Substitute then
    Break
  else
    Dec(LLength);

  Result := AText.SubString(LIndex, LLength - LIndex + 1);
end;

function TrimLeft(const AText: string): string;
var
  LLength, LIndex: Integer;
begin
  LLength := AText.Length - 1;
  LIndex := 0;

  while (LIndex <= LLength) and (AText.Chars[LIndex] <= ' ') do
  if AText.Chars[LIndex] = TControlCharacters.Substitute then
    Break
  else
    Inc(LIndex);

  if LIndex > 0 then
    Result := AText.SubString(LIndex)
  else
    Result := AText;
end;

function TrimRight(const AText: string): string;
var
  LIndex: Integer;
begin
  LIndex := AText.Length - 1;

  if (LIndex >= 0) and (AText[LIndex] > ' ') then
    Result := AText
  else
  begin
    while (LIndex >= 0) and (AText.Chars[LIndex] <= ' ') do
    if AText.Chars[LIndex] = TControlCharacters.Substitute then
      Break
    else
      Dec(LIndex);

    Result := AText.SubString(0, LIndex + 1);
  end;
end;

function CaseNone(const AChar: Char): Char;
begin
  Result := AChar;
end;

function CaseStringNone(const AString: string): string;
begin
  Result := AString;
end;

function CaseUpper(const AChar: Char): Char;
begin
  Result := AChar;

  case AChar of
    'a'..'z':
      Result := Char(Word(AChar) and $FFDF);
    { Turkish special characters }
    'ç', 'Ç':
      Result := 'C';
    'ı', 'İ':
      Result := 'I';
    'ş', 'Ş':
      Result := 'S';
    'ğ', 'Ğ':
      Result := 'G';
  end;
end;

function CharInString(const AChar: Char; const AString: string): Boolean;
var
  LLength: Integer;
begin
  Result := False;

  LLength := AString.Length;

  if LLength = 0 then
    Exit;

  for var LIndex := 1 to LLength do
  if AChar = AString[LIndex] then
    Exit(True);
end;

function ConvertTabs(const ALine: string; ATabWidth: Integer; var AHasTabs: Boolean; const AColumns: Boolean): string;
var
  LPosition: Integer;
  LCount: Integer;
begin
  Result := ALine;

  AHasTabs := False;

  LPosition := 1;

  while True do
  begin
    LPosition := Pos(TControlCharacters.Tab, Result, LPosition);

    if LPosition = 0 then
      Break;

    AHasTabs := True;

    Delete(Result, LPosition, Length(TControlCharacters.Tab));

    LCount := ATabWidth;

    if AColumns then
      LCount := LCount - (LPosition - ATabWidth - 1) mod ATabWidth;

    Insert(StringOfChar(TCharacters.Space, LCount), Result, LPosition);

    Inc(LPosition, LCount);
  end;
end;

function IsAnsiUnicodeChar(const AChar: Char): Boolean;
begin
  case AChar of
    '™', '€', 'ƒ', '„', '†', '‡', 'ˆ', '‰', 'Š', '‹', 'Œ', 'Ž', '‘', '’', '“', '”', '•', '–', '—', '˜', 'š', '›', 'œ',
    'ž', 'Ÿ':
    Result := True;
  else
    Result := False;
  end;
end;

function IsCombiningCharacter(const AChar: PChar): Boolean;
begin
  Result := AChar^.GetUnicodeCategory in [TUnicodeCategory.ucCombiningMark, TUnicodeCategory.ucEnclosingMark,
    TUnicodeCategory.ucNonSpacingMark];
end;

function MiddleColor(const AColor1, AColor2: TAlphaColor): TAlphaColor;
begin
  TAlphaColorRec(Result).A := (TAlphaColorRec(AColor1).A + TAlphaColorRec(AColor2).A) shr 1;
  TAlphaColorRec(Result).R := (TAlphaColorRec(AColor1).R + TAlphaColorRec(AColor2).R) shr 1;
  TAlphaColorRec(Result).G := (TAlphaColorRec(AColor1).G + TAlphaColorRec(AColor2).G) shr 1;
  TAlphaColorRec(Result).B := (TAlphaColorRec(AColor1).B + TAlphaColorRec(AColor2).B) shr 1;
end;

procedure FreeList(var AList: TList);
begin
  ClearList(AList);

  if Assigned(AList) then
  begin
    AList.Free;
    AList := nil;
  end;
end;

procedure ClearList(var AList: TList);
begin
  if not Assigned(AList) then
    Exit;

  for var LIndex := AList.Count - 1 downto 0 do
  if Assigned(AList[LIndex]) then
  begin
    TObject(AList[LIndex]).Free;
    AList[LIndex] := nil;
  end;

  AList.Clear;
end;

function DeleteWhitespace(const AValue: string): string;
var
  LIndex2: Integer;
begin
  SetLength(Result, AValue.Length);

  LIndex2 := 0;

  for var LIndex := 1 to AValue.Length do
  if not AValue[LIndex].IsWhiteSpace then
  begin
    Inc(LIndex2);
    Result[LIndex2] := AValue[LIndex];
  end;

  SetLength(Result, LIndex2);
end;

{ The two functions below are the ONLY place where VCL TColor (BGR) and FMX TAlphaColor (ARGB) meet.
  They are used at the theme JSON import/export boundary - theme files are shared with the VCL editor
  and keep the VCL TColor format. }

function TextEditorAlphaColorToColor(const AColor: TAlphaColor): TColor;
begin
  if AColor = TAlphaColors.Null then
    Exit(TColors.SysNone);

  if AColor = TDefaultColors.SysDefault then
    Exit(TColors.SysDefault);

  TColorRec(Result).R := TAlphaColorRec(AColor).R;
  TColorRec(Result).G := TAlphaColorRec(AColor).G;
  TColorRec(Result).B := TAlphaColorRec(AColor).B;
  TColorRec(Result).A := if TAlphaColorRec(AColor).A = $FF then 0 else TAlphaColorRec(AColor).A;
end;

function TextEditorColorToAlphaColor(const AColor: TColor): TAlphaColor;
var
  LAlpha: Cardinal;
  LColor: Cardinal;
  LRGB: Cardinal;
begin
  if AColor = TColors.SysNone then
    Exit(TAlphaColors.Null);

  LColor := Cardinal(AColor);
  LAlpha := LColor and $FF000000;

  if LAlpha = 0 then
    LAlpha := $FF000000;

  LRGB := LColor and $00FFFFFF;
  Result := TAlphaColor(LAlpha or
    ((LRGB and $000000FF) shl 16) or
    (LRGB and $0000FF00) or
    ((LRGB and $00FF0000) shr 16));
end;

function TextWidth(const ACanvas: TCanvas; const AText: string): Single;
begin
  Result := ACanvas.TextWidth(AText);
end;

{ The GDI+ canvas (the only printer canvas on Windows) measures text with a constant ~1/3 em padding per call, so
  accumulating TextWidth results spreads tokens apart. Doubling the text cancels the padding, leaving the true advance.
  On tight-measuring canvases (D2D) the result equals TextWidth. }
function TextAdvance(const ACanvas: TCanvas; const AText: string): Single;
begin
  if AText.IsEmpty then
    Exit(0);

  Result := ACanvas.TextWidth(AText + AText) - ACanvas.TextWidth(AText);
end;

function TextHeight(const ACanvas: TCanvas; const AText: string): Single;
begin
  Result := ACanvas.TextHeight(AText);
end;

function GetBOFPosition: TTextEditorTextPosition;
begin
  Result.Char := 1;
  Result.Line := 0;
end;

function GetPosition(const AChar, ALine: Integer): TTextEditorTextPosition;
begin
  Result.Char := AChar;
  Result.Line := ALine;
end;

function GetViewPosition(const AColumn: Integer; const ARow: Integer): TTextEditorViewPosition;
begin
  Result.Column := AColumn;
  Result.Row := ARow;
end;

function IsRightToLeftCharacter(const AChar: Char; const AAllowEmptySpace: Boolean = True): Boolean;
begin
  { Hebrew: 1424-1535, Arabic: 1536-1791, Arabic Supplement: 1872–1919 }
  case Ord(AChar) of
    9, 32:
      Result := AAllowEmptySpace;
    1424..1791, 1872..1919:
      Result := True;
  else
    Result := False;
  end;
end;

function IsSamePosition(const APosition1, APosition2: TTextEditorTextPosition): Boolean;
begin
  Result := (APosition1.Line = APosition2.Line) and (APosition1.Char = APosition2.Char);
end;

{ checks for a BOM in UTF-8 format or searches the buffer for typical UTF-8 octet sequences }
function IsUTF8Buffer(const ABuffer: TBytes; out AWithBOM: Boolean): Boolean;
var
  LIndex, LBufferSize, LFoundUTF8Strings: Integer;
const
  MinimumCountOfUTF8Strings = 1;

  { 3 trailing bytes are the maximum in valid UTF-8 streams, so a count of 4 trailing bytes is enough to detect invalid
    UTF-8 streams }
  function CountOfTrailingBytes: Integer;
  begin
    Result := 0;

    Inc(LIndex);

    while (LIndex < LBufferSize) and (Result < 4) do
    begin
      case ABuffer[LIndex] of
        $80 .. $BF:
          Inc(Result)
      else
        Break;
      end;

      Inc(LIndex);
    end;
  end;

begin
  Result := False;

  LBufferSize := Length(ABuffer);
  AWithBOM := False;

  if LBufferSize > 0 then
  begin
    if (LBufferSize >= Length(TEXT_EDITOR_UTF8_BOM)) and CompareMem(@ABuffer[0], @TEXT_EDITOR_UTF8_BOM[0], Length(TEXT_EDITOR_UTF8_BOM)) then
    begin
      AWithBOM := True;
      Exit(True);
    end;

    { If no BOM was found, check for leading/trailing byte sequences, which are uncommon in usual non UTF-8 encoded text.

      NOTE: There is no 100% safe way to detect UTF-8 streams. The bigger MinimumCountOfUTF8Strings, the lower is the
      probability of a false positive. On the other hand, a big MinimumCountOfUTF8Strings makes it unlikely to detect
      files with only little usage of non US-ASCII chars, like usual in European languages. }
    LFoundUTF8Strings := 0;

    LIndex := 0;

    while LIndex < LBufferSize do
    begin
      case ABuffer[LIndex] of
        { skip US-ASCII characters as they could belong to various charsets }
        $00 .. $7F:
          ;
        $C2 .. $DF:
          if CountOfTrailingBytes = 1 then
            Inc(LFoundUTF8Strings)
          else
            Break;
        $E0:
          begin
            Inc(LIndex);

            if (CountOfTrailingBytes = 1) and (LIndex < LBufferSize) and (ABuffer[LIndex] in [$A0 .. $BF]) then
              Inc(LFoundUTF8Strings)
            else
              Break;
          end;
        $E1 .. $EC, $EE .. $EF:
          if CountOfTrailingBytes = 2 then
            Inc(LFoundUTF8Strings)
          else
            Break;
        $ED:
          begin
            Inc(LIndex);

            if (CountOfTrailingBytes = 1) and (LIndex < LBufferSize) and (ABuffer[LIndex] in [$80 .. $9F]) then
              Inc(LFoundUTF8Strings)
            else
              Break;
          end;
        $F0:
          begin
            Inc(LIndex);

            if (CountOfTrailingBytes = 2) and (LIndex < LBufferSize) and (ABuffer[LIndex] in [$90 .. $BF]) then
              Inc(LFoundUTF8Strings)
            else
              Break;
          end;
        $F1 .. $F3:
          if CountOfTrailingBytes = 3 then
            Inc(LFoundUTF8Strings)
          else
            Break;
        $F4:
          begin
            Inc(LIndex);

            if (CountOfTrailingBytes = 2) and (LIndex < LBufferSize) and (ABuffer[LIndex] in [$80 .. $8F]) then
              Inc(LFoundUTF8Strings)
            else
              Break;
          end;
        { invalid UTF-8 bytes }
        $C0, $C1, $F5 .. $FF:
          Break;
        { trailing bytes are consumed when handling leading bytes, any occurrence of "orphaned" trailing bytes is invalid UTF-8 }
        $80 .. $BF:
          Break;
      end;

      if LFoundUTF8Strings = MinimumCountOfUTF8Strings then
        Exit(True);

      Inc(LIndex);
    end;
  end;
end;

{ https://docs.microsoft.com/en-us/troubleshoot/developer/visualstudio/cpp/general/add-html-code-clipboard }
function FormatForClipboard(const AText: string): UTF8String;
const
  Version = 'Version:1.0';
  StartHTML = 'StartHTML:';
  EndHTML = 'EndHTML:';
  StartFragment = 'StartFragment:';
  EndFragment = 'EndFragment:';
  DocType = '<!DOCTYPE>';
  HTMLBegin = '<html><body><!--StartFragment-->';
  HTMLEnd = '<!--EndFragment--></body></html>';
  DescriptionLength = Length(Version) + Length(StartHTML) + Length(EndHTML) + Length(StartFragment) + Length(EndFragment) + 40;
var
  LStartHTML, LStartFragment, LEndFragment, LEndHTML: Integer;
begin
  Result := AText;

  LStartHTML := DescriptionLength;
  LStartFragment := LStartHTML + Length(DocType) + Length(HTMLBegin);
  LEndFragment := LStartFragment + Length(Result);
  LEndHTML := LEndFragment + Length(HTMLEnd);

  Result := Version + sLineBreak +
    Format('%s%.8d', [StartHTML, LStartHTML]) + sLineBreak +
    Format('%s%.8d', [EndHTML, LEndHTML]) + sLineBreak +
    Format('%s%.8d', [StartFragment, LStartFragment]) + sLineBreak +
    Format('%s%.8d', [EndFragment, LEndFragment]) + sLineBreak +
    DocType + HTMLBegin + Result + HTMLEnd;
end;

procedure TextEditorBeep;
begin
  System.SysUtils.Beep;
end;

procedure ResizeBitmap(const ABitmap: FMX.Graphics.TBitmap; const ANewWidth, ANewHeight: Integer);
var
  LBitmap: FMX.Graphics.TBitmap;
begin
  LBitmap := FMX.Graphics.TBitmap.Create;
  try
    LBitmap.SetSize(ABitmap.Width, ABitmap.Height);

    if LBitmap.Canvas.BeginScene then
    try
      LBitmap.Canvas.DrawBitmap(ABitmap, System.Types.RectF(0, 0, ABitmap.Width, ABitmap.Height),
        System.Types.RectF(0, 0, ABitmap.Width, ABitmap.Height), 1);
    finally
      LBitmap.Canvas.EndScene;
    end;

    ABitmap.SetSize(ANewWidth, ANewHeight);

    if ABitmap.Canvas.BeginScene then
    try
      ABitmap.Canvas.DrawBitmap(LBitmap, System.Types.RectF(0, 0, LBitmap.Width, LBitmap.Height),
        System.Types.RectF(0, 0, ANewWidth, ANewHeight), 1);
    finally
      ABitmap.Canvas.EndScene;
    end;
  finally
    LBitmap.Free;
  end;
end;

{$IFDEF MSWINDOWS}
var
  CF_HTML: Cardinal = 0;

function GetHTMLClipboardFormat: Cardinal;
begin
  if CF_HTML = 0 then
    CF_HTML := RegisterClipboardFormat('HTML Format');

  Result := CF_HTML;
end;

procedure SetClipboardBuffer(const AFormat: UINT; var ABuffer; const ASize: NativeInt);
var
  LData: THandle;
  LDataPointer: Pointer;
begin
  LData := GlobalAlloc(GMEM_MOVEABLE or GMEM_DDESHARE, ASize);
  try
    LDataPointer := GlobalLock(LData);
    try
      Move(ABuffer, LDataPointer^, ASize);

      if SetClipboardData(AFormat, LData) = 0 then
        RaiseLastOSError;
    finally
      GlobalUnlock(LData);
    end;
  except
    GlobalFree(LData);
    raise;
  end;
end;

{ The FMX clipboard service supports plain text only - putting the HTML format on the clipboard next to the
  text needs the Windows clipboard API. Returns False when the clipboard could not be opened. }
function TrySetClipboardTextWithHTML(const AText, AHTML: string): Boolean;
var
  LDelayMs: Integer;
  LOpened: Boolean;
  LHTML: UTF8String;
begin
  Result := False;

  LDelayMs := TClipboardDefaults.DelayStepMs;

  for var LRetry := 1 to TClipboardDefaults.MaxRetries do
  begin
    LOpened := OpenClipboard(0);

    if LOpened then
      Break;

    Sleep(LDelayMs);
    Inc(LDelayMs, TClipboardDefaults.DelayStepMs);
  end;

  if not LOpened then
    Exit;

  try
    EmptyClipboard;

    SetClipboardBuffer(CF_UNICODETEXT, PChar(AText)^, (AText.Length + 1) * SizeOf(Char));

    if not AHTML.IsEmpty then
    begin
      LHTML := FormatForClipboard(AHTML) + #0;

      SetClipboardBuffer(GetHTMLClipboardFormat, PAnsiChar(LHTML)^, Length(LHTML));
    end;

    Result := True;
  finally
    CloseClipboard;
  end;
end;
{$ENDIF}

{ TAutoCursor }

function TAutoCursor.AddCursorToStack(const ACursor: TCursor): Integer;
var
  LCursorPair: TCursorPair;
begin
  LCursorPair.Initialize(crDefault, ACursor);

  Result := FCursorStack.Add(LCursorPair);
end;

procedure TAutoCursor.BeginCursor(const ACursor: TCursor);
begin
  AddCursorToStack(ACursor);
end;

constructor TAutoCursor.Create(const ACursor: TCursor);
begin
  inherited Create;

  FCursorStack := TList<TCursorPair>.Create;

  BeginCursor(ACursor);
end;

destructor TAutoCursor.Destroy;
begin
  EndCursor(True);

  FCursorStack.Free;

  inherited;
end;

procedure TAutoCursor.EndCursor;
begin
  EndCursor(False);
end;

procedure TAutoCursor.EndCursor(const AResetToFirst: Boolean);
var
  LLastIndex: Integer;
begin
  if FCursorStack.Count >= 1 then
  begin
    if AResetToFirst then
      FCursorStack.Clear
    else
    begin
      LLastIndex := FCursorStack.Count - 1;

      FCursorStack.Delete(LLastIndex);
    end;
  end;
end;

{ TCursorPair }

procedure TCursorPair.Initialize(const AOriginalCursor, ANewCursor: TCursor);
begin
  OriginalCursor := AOriginalCursor;
  NewCursor := ANewCursor;
end;

end.
