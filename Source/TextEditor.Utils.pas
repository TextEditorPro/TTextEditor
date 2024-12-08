{$WARN WIDECHAR_REDUCED OFF} // CharInSet is slow in loops
{$WARN IMPLICIT_STRING_CAST OFF}
unit TextEditor.Utils;

{$I TextEditor.Defines.inc}

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, System.UITypes, Vcl.Graphics, TextEditor.Types;

function AutoCursor(const ACursor: TCursor = crHourGlass): IAutoCursor;
function CaseNone(const AChar: Char): Char; inline;
function CaseStringNone(const AString: string): string; inline;
function CaseUpper(const AChar: Char): Char; inline;
function CharInString(const AChar: Char; const AString: string): Boolean; inline;
function ColorToHex(const AColor: TColor): string; inline;
function ConvertTabs(const ALine: string; ATabWidth: Integer; var AHasTabs: Boolean; const AColumns: Boolean): string;
function DeleteWhitespace(const AValue: string): string;
function GetBOFPosition: TTextEditorTextPosition; inline;
function GetClipboardText: string;
function GetPosition(const AChar, ALine: Integer): TTextEditorTextPosition; inline;
function GetViewPosition(const AColumn: Integer; const ARow: Integer): TTextEditorViewPosition; inline;
function IsAnsiUnicodeChar(const AChar: Char): Boolean; inline;
function IsCombiningCharacter(const AChar: PChar): Boolean; inline;
function IsRightToLeftCharacter(const AChar: Char; const AAllowEmptySpace: Boolean = True): Boolean; inline;
function IsSamePosition(const APosition1, APosition2: TTextEditorTextPosition): Boolean; inline;
function IsUTF8Buffer(const ABuffer: TBytes; out AWithBOM: Boolean): Boolean;
function MessageDialog(const AMessage: string; const ADlgType: TMsgDlgType; const AButtons: TMsgDlgButtons; const ADefaultButton: TMsgDlgBtn): Integer;
function MiddleColor(const AColor1, AColor2: TColor): TColor; inline;
function TextHeight(const ACanvas: TCanvas; const AText: string): Integer; inline;
function TextWidth(const ACanvas: TCanvas; const AText: string): Integer; inline;
function TitleCase(const AValue: string): string;
function ToggleCase(const AValue: string): string;
function Trim(const AText: string): string;
function TrimLeft(const AText: string): string;
function TrimRight(const AText: string): string;
procedure ClearList(var AList: TList);
procedure FreeList(var AList: TList);
procedure ResizeBitmap(const ABitmap: TBitmap; const ANewWidth, ANewHeight: Integer);
procedure SetClipboardText(const AText: string; const AHTML: string);

implementation

uses
  Winapi.ActiveX, System.Character, System.Generics.Collections, Vcl.ClipBrd, Vcl.Controls, Vcl.Forms, TextEditor.Consts
{$IFDEF ALPHASKINS}
  , sDialogs
{$ELSE}
  , Vcl.Dialogs
{$ENDIF};

const
  TEXT_EDITOR_UTF8_BOM: array [0 .. 2] of Byte = ($EF, $BB, $BF);

type
  TCursorPair = record
    NewCursor : TCursor;
    OriginalCursor: TCursor;
    procedure Initalize(const AOriginalCursor, ANewCursor: TCursor);
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

var
  CF_HTML: TClipFormat = 0;

function AutoCursor(const ACursor: TCursor = crHourGlass): IAutoCursor;
begin
  Result := TAutoCursor.Create(aCursor);
end;

function ToggleCase(const AValue: string): string;
var
  LIndex: Integer;
  LValue: string;
begin
  Result := UpperCase(AValue);

  LValue := LowerCase(AValue);

  for LIndex := 1 to Length(AValue) do
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
  LLength := Length(AValue);

  SetLength(Result, LLength);

  while LIndex <= LLength do
  begin
    LChar := AValue[LIndex];

    if LIndex > 1 then
    begin
      if AValue[LIndex - 1] = ' ' then
        LChar := UpperCase(LChar)
      else
        LChar := LowerCase(LChar);
    end
    else
      LChar := UpperCase(LChar);

    Result[LIndex] := LChar[1];

    Inc(LIndex);
  end;
end;

function Trim(const AText: string): string;
var
  LIndex, LLength: Integer;
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
  LIndex, LLength: Integer;
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

function CharInString(const AChar: Char; const AString: string): Boolean; inline;
var
  LIndex: Integer;
  LLength: Integer;
begin
  Result := False;

  LLength := AString.Length;

  if LLength = 0 then
    Exit;

  for LIndex := 1 to LLength do
  if AChar = AString[LIndex] then
    Exit(True);
end;

function ColorToHex(const AColor: TColor): string;
begin
  Result := '#' + IntToHex(GetRValue(AColor), 2) + IntToHex(GetGValue(AColor), 2) + IntToHex(GetBValue(AColor), 2);
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

function MiddleColor(const AColor1, AColor2: TColor): TColor;
var
  LRed, LGreen, LBlue: Byte;
begin
  LRed := (GetRValue(AColor1) + GetRValue(AColor2)) div 2;
  LGreen := (GetGValue(AColor1) + GetGValue(AColor2)) div 2;
  LBlue := (GetBValue(AColor1) + GetBValue(AColor2)) div 2;

  Result := RGB(LRed, LGreen, LBlue);
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
var
  LIndex: Integer;
begin
  if not Assigned(AList) then
    Exit;

  for LIndex := AList.Count - 1 downto 0 do
  if Assigned(AList[LIndex]) then
  begin
    TObject(AList[LIndex]).Free;
    AList[LIndex] := nil;
  end;

  AList.Clear;
end;

function DeleteWhitespace(const AValue: string): string;
var
  LIndex, LIndex2: Integer;
begin
  SetLength(Result, Length(AValue));
  LIndex2 := 0;

  for LIndex := 1 to Length(AValue) do
  if not AValue[LIndex].IsWhiteSpace then
  begin
    Inc(LIndex2);
    Result[LIndex2] := AValue[LIndex];
  end;

  SetLength(Result, LIndex2);
end;

function MessageDialog(const AMessage: string; const ADlgType: TMsgDlgType; const AButtons: TMsgDlgButtons;
  const ADefaultButton: TMsgDlgBtn): Integer;
begin
{$IFDEF ALPHASKINS}
  with sCreateMessageDialog(AMessage, ADlgType, AButtons, ADefaultButton) do
{$ELSE}
  with CreateMessageDialog(AMessage, ADlgType, AButtons, ADefaultButton) do
{$ENDIF}
  try
    HelpContext := 0;
    HelpFile := '';
    Position := poMainFormCenter;
    Result := ShowModal;
  finally
    Free;
  end;
end;

function TextWidth(const ACanvas: TCanvas; const AText: string): Integer;
var
  LSize: TSize;
begin
  GetTextExtentPoint32(ACanvas.Handle, PChar(AText), Length(AText), LSize);
  Result := LSize.cx;
end;

function TextHeight(const ACanvas: TCanvas; const AText: string): Integer;
var
  LSize: TSize;
begin
  GetTextExtentPoint32(ACanvas.Handle, PChar(AText), Length(AText), LSize);
  Result := LSize.cy;
end;

function GetBOFPosition: TTextEditorTextPosition; inline;
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
const
  MinimumCountOfUTF8Strings = 1;
var
  LIndex, LBufferSize, LFoundUTF8Strings: Integer;

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
        { trailing bytes are consumed when handling leading bytes, any occurence of "orphaned" trailing bytes is invalid UTF-8 }
        $80 .. $BF:
          Break;
      end;

      if LFoundUTF8Strings = MinimumCountOfUTF8Strings then
        Exit(True);

      Inc(LIndex);
    end;
  end;
end;

function OpenClipboard: Boolean;
var
  LRetryCount: Integer;
  LDelayStepMs: Integer;
begin
  Result := False;

  LDelayStepMs := TClipboardDefaults.DelayStepMs;

  for LRetryCount := 1 to TClipboardDefaults.MaxRetries do
  try
    Clipboard.Open;
    Exit(True);
  except
    on Exception do
    if LRetryCount = TClipboardDefaults.MaxRetries then
      raise
    else
    begin
      Sleep(LDelayStepMs);
      Inc(LDelayStepMs, TClipboardDefaults.DelayStepMs);
    end;
  end;
end;

function GetClipboardText: string;
var
  LGlobalMem: HGlobal;
  LLocaleID: LCID;
  LBytePointer: PByte;

  function AnsiStringToString(const AValue: AnsiString; const ACodePage: Word): string;
  var
    LInputLength, LOutputLength: Integer;
  begin
    LInputLength := Length(AValue);
    LOutputLength := MultiByteToWideChar(ACodePage, 0, PAnsiChar(AValue), LInputLength, nil, 0);
    SetLength(Result, LOutputLength);
    MultiByteToWideChar(ACodePage, 0, PAnsiChar(AValue), LInputLength, PChar(Result), LOutputLength);
  end;

  function CodePageFromLocale(const ALanguage: LCID): Integer;
  var
    LBuffer: array [0 .. 6] of Char;
  begin
    GetLocaleInfo(ALanguage, LOCALE_IDEFAULTANSICODEPAGE, LBuffer, 6);
    Result := StrToIntDef(LBuffer, GetACP);
  end;

begin
  Result := '';

  if OpenClipboard then
  try
    if Clipboard.HasFormat(CF_UNICODETEXT) then
    begin
      LGlobalMem := Clipboard.GetAsHandle(CF_UNICODETEXT);

      if LGlobalMem <> 0 then
      try
        Result := PChar(GlobalLock(LGlobalMem));
      finally
        GlobalUnlock(LGlobalMem);
      end;
    end
    else
    begin
      LLocaleID := 0;
      LGlobalMem := Clipboard.GetAsHandle(CF_LOCALE);

      if LGlobalMem <> 0 then
      try
        LLocaleID := PInteger(GlobalLock(LGlobalMem))^;
      finally
        GlobalUnlock(LGlobalMem);
      end;

      LGlobalMem := Clipboard.GetAsHandle(CF_TEXT);

      if LGlobalMem <> 0 then
      try
        LBytePointer := GlobalLock(LGlobalMem);
        Result := AnsiStringToString(PAnsiChar(LBytePointer), CodePageFromLocale(LLocaleID));
      finally
        GlobalUnlock(LGlobalMem);
      end;
    end;
  finally
    Clipboard.Close;
  end;
end;

function GetHTMLClipboardFormat: TClipFormat;
begin
  if CF_HTML = 0 then
    CF_HTML := RegisterClipboardFormat('HTML Format');

  Result := CF_HTML;
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
  DescriptionLength = Length(Version) + Length(StartHTML) + Length(EndHTML) + Length(StartFragment) +
    Length(EndFragment) + 40;
var
  LStartHTML: Integer;
  LEndHTML: Integer;
  LStartFragment: Integer;
  LEndFragment: Integer;
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

{ TODO: Refactor }
procedure SetClipboardText(const AText: string; const AHTML: string);
var
  LGlobalMem: HGlobal;
  LPGlobalLock: PByte;
  LHTML: UTF8String;
  LLength: Integer;
  LText: string;
begin
  if AText.IsEmpty then
    Exit;

  LText := StringReplace(AText, TControlCharacters.Null, '', [rfReplaceAll]);
  LLength := Length(LText);

  if OpenClipboard then
  try
    Clipboard.Clear;

    { Set ANSI text only on Win9X, WinNT automatically creates ANSI from Unicode }
    if Win32Platform <> VER_PLATFORM_WIN32_NT then
    begin
      LGlobalMem := GlobalAlloc(GMEM_MOVEABLE or GMEM_DDESHARE, LLength + 1);

      if LGlobalMem <> 0 then
      begin
        LPGlobalLock := GlobalLock(LGlobalMem);
        try
          if Assigned(LPGlobalLock) then
          begin
            Move(PAnsiChar(AnsiString(LText))^, LPGlobalLock^, LLength + 1);
            Clipboard.SetAsHandle(CF_TEXT, LGlobalMem);
          end;
        finally
          GlobalUnlock(LGlobalMem);
        end;
      end;
    end;

    { Set unicode text, this also works on Win9X, even if the clipboard-viewer
      can't show it, Word 2000+ can paste it including the unicode only characters }
    LGlobalMem := GlobalAlloc(GMEM_MOVEABLE or GMEM_DDESHARE, (LLength + 1) * SizeOf(Char));

    if LGlobalMem <> 0 then
    begin
      LPGlobalLock := GlobalLock(LGlobalMem);
      try
        if Assigned(LPGlobalLock) then
        begin
          Move(PChar(LText)^, LPGlobalLock^, (LLength + 1) * SizeOf(Char));
          Clipboard.SetAsHandle(CF_UNICODETEXT, LGlobalMem);
        end;
      finally
        GlobalUnlock(LGlobalMem);
      end;
    end;

    if not AHTML.IsEmpty then
    begin
      LHTML := FormatForClipboard(AHTML) + #0;
      LLength := Length(LHTML);

      LGlobalMem := GlobalAlloc(GMEM_MOVEABLE or GMEM_DDESHARE, LLength);

      if LGlobalMem <> 0 then
      begin
        LPGlobalLock := GlobalLock(LGlobalMem);
        try
          if Assigned(LPGlobalLock) then
          begin
            Move(PAnsiChar(LHTML)^, LPGlobalLock^, LLength);
            Clipboard.SetAsHandle(GetHTMLClipboardFormat, LGlobalMem);
          end;
        finally
          GlobalUnlock(LGlobalMem);
        end;
      end;
    end;
  finally
    Clipboard.Close;
  end;
end;

procedure ResizeBitmap(const ABitmap: TBitmap; const ANewWidth, ANewHeight: Integer);
var
  LBitmap: TBitmap;
begin
  LBitmap := TBitmap.Create;
  try
    LBitmap.PixelFormat := ABitmap.PixelFormat;
    LBitmap.SetSize(ANewWidth, ANewHeight);
    LBitmap.Canvas.StretchDraw(Rect(0, 0, ANewWidth, ANewHeight), ABitmap);
    ABitmap.SetSize(ANewWidth, ANewHeight);
    ABitmap.Canvas.Draw(0, 0, LBitmap);
  finally
    LBitmap.Free;
  end;
end;

{ TAutoCursor }

function TAutoCursor.AddCursorToStack(const ACursor: TCursor): Integer;
var
  LCursorPair: TCursorPair;
begin
  LCursorPair.Initalize(Screen.Cursor, ACursor);
  Result := FCursorStack.Add(LCursorPair);
end;

procedure TAutoCursor.BeginCursor(const ACursor: TCursor);
var
  LIndex: Integer;
begin
  LIndex := AddCursorToStack(ACursor);
  Screen.Cursor := FCursorStack[LIndex].NewCursor;
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
    begin
      Screen.Cursor := FCursorStack[0].OriginalCursor;
      FCursorStack.Clear;
    end
    else
    begin
      LLastIndex := FCursorStack.Count - 1;
      Screen.Cursor := FCursorStack[LLastIndex].OriginalCursor;
      FCursorStack.Delete(LLastIndex);
    end;
  end;
end;

{ TCursorPair }

procedure TCursorPair.Initalize(const AOriginalCursor, ANewCursor: TCursor);
begin
  OriginalCursor := AOriginalCursor;
  NewCursor := ANewCursor;
end;

end.
