unit TextEditor.Encoding;

{$I TextEditor.Defines.inc}

interface

uses
  System.SysUtils
{$IFDEF BASENCODING}
  , System.NetEncoding
{$ENDIF};

type
  TUTF8WithoutBOM = class(TUTF8Encoding)
  public
    function GetPreamble: TBytes; override;
  end;

  TEncoding = class(System.SysUtils.TEncoding)
  strict private
  class var
    FUTF8WithoutBOM: TEncoding;
    class function GetUTF8WithoutBOM: TEncoding; static;
  public
    class property UTF8WithoutBOM: TEncoding read GetUTF8WithoutBOM;
  end;

{$IFDEF BASENCODING}
  TASCIIDecimalEncoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  TBinaryEncoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  THexEncoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  THexBigEndianEncoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  THexLittleEndianEncoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  THexWithoutSpacesEncoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  THexBigEndianWithoutSpacesEncoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  THexLittleEndianWithoutSpacesEncoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  TOctalEncoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  TRotate5Encoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  TRotate13Encoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  TRotate18Encoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  TRotate47Encoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  TBase32Encoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  TBase64NoLineBreaksEncoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  TBase85Encoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  TBase91Encoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  TBase128Encoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  TBase256Encoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  TBase1024Encoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  TBase4096Encoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  TNetEncoding = class(System.NetEncoding.TNetEncoding)
  private
    class var
      FASCIIDecimal: TASCIIDecimalEncoding;
      FBase32: TBase32Encoding;
      FBase64NoLineBreaks: TBase64NoLineBreaksEncoding;
      FBase85: TBase85Encoding;
      FBase91: TBase91Encoding;
      FBase128: TBase128Encoding;
      FBase256: TBase256Encoding;
      FBase1024: TBase1024Encoding;
      FBase4096: TBase4096Encoding;
      FBinary: TBinaryEncoding;
      FHex: THexEncoding;
      FHexBigEndian: THexBigEndianEncoding;
      FHexLittleEndian: THexLittleEndianEncoding;
      FHexWithoutSpaces: THexWithoutSpacesEncoding;
      FHexBigEndianWithoutSpaces: THexBigEndianWithoutSpacesEncoding;
      FHexLittleEndianWithoutSpaces: THexLittleEndianWithoutSpacesEncoding;
      FOctal: TOctalEncoding;
      FRotate5: TRotate5Encoding;
      FRotate13: TRotate13Encoding;
      FRotate18: TRotate18Encoding;
      FRotate47: TRotate47Encoding;
    class function GetASCIIDecimal: TASCIIDecimalEncoding; static;
    class function GetBase32: TBase32Encoding; static;
    class function GetBase64NoLineBreaks: TBase64NoLineBreaksEncoding; static;
    class function GetBase85: TBase85Encoding; static;
    class function GetBase91: TBase91Encoding; static;
    class function GetBase128: TBase128Encoding; static;
    class function GetBase256: TBase256Encoding; static;
    class function GetBase1024: TBase1024Encoding; static;
    class function GetBase4096: TBase4096Encoding; static;
    class function GetBinary: TBinaryEncoding; static;
    class function GetHex: THexEncoding; static;
    class function GetHexBigEndian: THexBigEndianEncoding; static;
    class function GetHexLittleEndian: THexLittleEndianEncoding; static;
    class function GetHexWithoutSpaces: THexWithoutSpacesEncoding; static;
    class function GetHexBigEndianWithoutSpaces: THexBigEndianWithoutSpacesEncoding; static;
    class function GetHexLittleEndianWithoutSpaces: THexLittleEndianWithoutSpacesEncoding; static;
    class function GetOctal: TOctalEncoding; static;
    class function GetRotate5: TRotate5Encoding; static;
    class function GetRotate13: TRotate13Encoding; static;
    class function GetRotate18: TRotate18Encoding; static;
    class function GetRotate47: TRotate47Encoding; static;

    class destructor Destroy;
  public
    class property ASCIIDecimal: TASCIIDecimalEncoding read GetASCIIDecimal;
    class property Base32: TBase32Encoding read GetBase32;
    class property Base64NoLineBreaks: TBase64NoLineBreaksEncoding read GetBase64NoLineBreaks;
    class property Base85: TBase85Encoding read GetBase85;
    class property Base91: TBase91Encoding read GetBase91;
    class property Base128: TBase128Encoding read GetBase128;
    class property Base256: TBase256Encoding read GetBase256;
    class property Base1024: TBase1024Encoding read GetBase1024;
    class property Base4096: TBase4096Encoding read GetBase4096;
    class property Binary: TBinaryEncoding read GetBinary;
    class property Hex: THexEncoding read GetHex;
    class property HexBigEndian: THexBigEndianEncoding read GetHexBigEndian;
    class property HexLittleEndian: THexLittleEndianEncoding read GetHexLittleEndian;
    class property HexWithoutSpaces: THexWithoutSpacesEncoding read GetHexWithoutSpaces;
    class property HexBigEndianWithoutSpaces: THexBigEndianWithoutSpacesEncoding read GetHexBigEndianWithoutSpaces;
    class property HexLittleEndianWithoutSpaces: THexLittleEndianWithoutSpacesEncoding read GetHexLittleEndianWithoutSpaces;
    class property Octal: TOctalEncoding read GetOctal;
    class property Rotate5: TRotate5Encoding read GetRotate5;
    class property Rotate13: TRotate13Encoding read GetRotate13;
    class property Rotate18: TRotate18Encoding read GetRotate18;
    class property Rotate47: TRotate47Encoding read GetRotate47;
  end;
{$ENDIF}

implementation

uses
  Winapi.Windows
{$IFDEF BASENCODING}, BcpBase1024, BcpBase128, BcpBase256, BcpBase32, BcpBase4096, BcpBase64, BcpBase85, BcpBase91,
  BcpIBaseInterfaces, TextEditor.Consts, TextEditor.Utils{$ENDIF};

{ TUTF8WithoutBOM }

function TUTF8WithoutBOM.GetPreamble: TBytes;
begin
  SetLength(Result, 0);
end;

{ TEncoding }

class function TEncoding.GetUTF8WithoutBOM: TEncoding;
var
  LEncoding: System.SysUtils.TEncoding;
begin
  if not Assigned(FUTF8WithoutBOM) then
  begin
    LEncoding := TUTF8WithoutBOM.Create(CP_UTF8, 0, 0);

    if Assigned(AtomicCmpExchange(Pointer(FUTF8WithoutBOM), Pointer(LEncoding), nil)) then
      LEncoding.Free;
  end;

  Result := FUTF8WithoutBOM;
end;

{ TASCIIDecimalEncoding }

{$IFDEF BASENCODING}
function TASCIIDecimalEncoding.DoDecode(const AInput: string): string;
var
  LInput: string;
  LIndex: Integer;
  LValue: string;

  procedure AddToResult;
  begin
    if LValue <> '' then
    begin
      Result := Result + Chr(StrToIntDef(LValue, 0));
      LValue := '';
    end;
  end;

begin
  Result := '';
  LInput := TextEditor.Utils.Trim(StringReplace(AInput, TControlCharacters.CarriageReturnLinefeed, ' ', [rfReplaceAll]));
  LInput := TextEditor.Utils.Trim(StringReplace(LInput, TControlCharacters.Linefeed, ' ', [rfReplaceAll]));
  for LIndex := 1 to Length(LInput) do
  begin
    if LInput[LIndex] = ' ' then
      AddToResult
    else
      LValue := LValue + LInput[LIndex];
  end;
  AddToResult;
end;

function TASCIIDecimalEncoding.DoEncode(const AInput: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 1 to Length(AInput) do
  begin
    Result := Result + IntToStr(Ord(AInput[LIndex]));
    Result := Result + ' ';
  end;
  Result := TextEditor.Utils.Trim(Result);
end;

{ TBinaryEncoding }

function TBinaryEncoding.DoDecode(const AInput: string): string;
const
  ByteArray: array[0..7] of Byte = (128, 64, 32, 16, 8, 4, 2, 1);
var
  LIndex: Integer;
  LInput: string;
  LByte, LByteIndex: Byte;
begin
  Result := '';
  LInput := TextEditor.Utils.Trim(StringReplace(AInput, TControlCharacters.CarriageReturnLinefeed, ' ', [rfReplaceAll]));
  LInput := TextEditor.Utils.Trim(StringReplace(LInput, TControlCharacters.Linefeed, ' ', [rfReplaceAll]));
  LInput := StringReplace(LInput, ' ', '', [rfReplaceAll]);
  LByte := 0;
  LByteIndex := 0;
  for LIndex := 1 to Length(LInput) do
  begin
    if LInput[LIndex] = '1' then
      Inc(LByte, ByteArray[LByteIndex]);
    Inc(LByteIndex);
    if LByteIndex = 8 then
    begin
      Result := Result + Chr(LByte);
      LByteIndex := 0;
      LByte := 0;
    end;
  end;
end;

function TBinaryEncoding.DoEncode(const AInput: string): string;
const
  BitArray: array[0..15] of string = ('0000', '0001', '0010', '0011', '0100', '0101', '0110', '0111', '1000', '1001',
    '1010', '1011', '1100', '1101', '1110', '1111');
var
  LIndex: Integer;
  lLoBits: Byte;
  LHiBits: Byte;
begin
  Result := '';
  for LIndex := 1 to Length(AInput) do
  begin
    LHiBits := (Byte(AInput[LIndex]) and $F0) shr 4;
    LLoBits := Byte(AInput[LIndex]) and $0F;
    Result := Result + BitArray[LHiBits];
    Result := Result + BitArray[LLoBits];
    Result := Result + ' ';
  end;
  Result := TextEditor.Utils.Trim(Result);
end;

{ THexEncoding }

function THexEncoding.DoDecode(const AInput: string): string;
var
  LInput: string;
  LIndex: Integer;
  LValue: string;

  procedure AddToResult;
  begin
    if LValue <> '' then
    begin
      Result := Result + Chr(StrToIntDef('$' + LValue, 0));
      LValue := '';
    end;
  end;

begin
  Result := '';
  LInput := TextEditor.Utils.Trim(StringReplace(AInput, TControlCharacters.CarriageReturnLinefeed, ' ', [rfReplaceAll]));
  LInput := TextEditor.Utils.Trim(StringReplace(LInput, TControlCharacters.Linefeed, ' ', [rfReplaceAll]));
  for LIndex := 1 to Length(LInput) do
  begin
    if LInput[LIndex] = ' ' then
      AddToResult
    else
      LValue := LValue + LInput[LIndex];
  end;
  AddToResult;
end;

function THexEncoding.DoEncode(const AInput: string): string;
var
  LIndex: Integer;
  LBytes: TBytes;
begin
  Result := '';
  LBytes := TEncoding.UTF8.GetBytes(AInput);
  for LIndex := 0 to Length(LBytes) - 1 do
  begin
    Result := Result + IntToHex(LBytes[LIndex], 2);
    Result := Result + ' ';
  end;
end;

{ THexBigEndianEncoding }

function THexBigEndianEncoding.DoDecode(const AInput: string): string;
var
  LInput: string;
  LIndex: Integer;
  LValue: string;

  procedure AddToResult;
  begin
    if LValue <> '' then
    begin
      Result := Result + Chr(StrToIntDef('$' + LValue, 0));
      LValue := '';
    end;
  end;

begin
  Result := '';
  LInput := TextEditor.Utils.Trim(StringReplace(AInput, TControlCharacters.CarriageReturnLinefeed, ' ', [rfReplaceAll]));
  LInput := TextEditor.Utils.Trim(StringReplace(LInput, TControlCharacters.Linefeed, ' ', [rfReplaceAll]));
  for LIndex := 1 to Length(LInput) do
  begin
    if LInput[LIndex] = ' ' then
      AddToResult
    else
      LValue := LValue + LInput[LIndex];
  end;
  AddToResult;
end;

function THexBigEndianEncoding.DoEncode(const AInput: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 1 to Length(AInput) do
  begin
    Result := Result + IntToHex(Integer(AInput[LIndex]), 4);
    Result := Result + ' ';
  end;
  Result := TextEditor.Utils.Trim(Result);
end;

{ THexLittleEndianEncoding }

procedure SwapChar(var AChar: Char);
var
  LChar: Word absolute AChar;
begin
  LChar := Swap(LChar);
end;

function THexLittleEndianEncoding.DoDecode(const AInput: string): string;
var
  LInput: string;
  LIndex: Integer;
  LValue: string;

  procedure AddToResult;
  begin
    if LValue <> '' then
    begin
      Result := Result + Chr(StrToIntDef('$' + LValue, 0));
      LValue := '';
    end;
  end;

begin
  Result := '';
  LInput := TextEditor.Utils.Trim(StringReplace(AInput, TControlCharacters.CarriageReturnLinefeed, ' ', [rfReplaceAll]));
  LInput := TextEditor.Utils.Trim(StringReplace(LInput, TControlCharacters.Linefeed, ' ', [rfReplaceAll]));
  for LIndex := 1 to Length(LInput) do
  begin
    if LInput[LIndex] = ' ' then
      AddToResult
    else
      LValue := LValue + LInput[LIndex];
  end;
  AddToResult;
end;

function THexLittleEndianEncoding.DoEncode(const AInput: string): string;
var
  LIndex: Integer;
  LChar: Char;
begin
  Result := '';
  for LIndex := 1 to Length(AInput) do
  begin
    LChar := AInput[LIndex];
    SwapChar(LChar);
    Result := Result + IntToHex(Integer(LChar), 4);
    Result := Result + ' ';
  end;
  Result := TextEditor.Utils.Trim(Result);
end;

{ THexWithoutSpacesEncoding }

function THexWithoutSpacesEncoding.DoDecode(const AInput: string): string;
var
  LInput: string;
  LIndex: Integer;
  LValue: string;
begin
  Result := '';
  LInput := TextEditor.Utils.Trim(StringReplace(AInput, TControlCharacters.CarriageReturnLinefeed, ' ', [rfReplaceAll]));
  LInput := TextEditor.Utils.Trim(StringReplace(LInput, TControlCharacters.Linefeed, ' ', [rfReplaceAll]));
  LIndex := 1;
  while LIndex < Length(LInput) do
  begin
    LValue := LInput[LIndex] + LInput[LIndex + 1];
    Result := Result + Chr(StrToIntDef('$' + LValue, 0));
    Inc(LIndex, 2);
  end;
end;

function THexWithoutSpacesEncoding.DoEncode(const AInput: string): string;
var
  LIndex: Integer;
  LBytes: TBytes;
begin
  Result := '';
  LBytes := TEncoding.UTF8.GetBytes(AInput);
  for LIndex := 0 to Length(LBytes) - 1 do
    Result := Result + IntToHex(LBytes[LIndex], 2);
end;

{ THexBigEndianWithoutSpacesEncoding }

function THexBigEndianWithoutSpacesEncoding.DoDecode(const AInput: string): string;
var
  LInput: string;
  LIndex: Integer;
  LValue: string;
begin
  Result := '';
  LInput := TextEditor.Utils.Trim(StringReplace(AInput, TControlCharacters.CarriageReturnLinefeed, ' ', [rfReplaceAll]));
  LInput := TextEditor.Utils.Trim(StringReplace(LInput, TControlCharacters.Linefeed, ' ', [rfReplaceAll]));
  LIndex := 1;
  while LIndex < Length(LInput) do
  begin
    LValue := LInput[LIndex] + LInput[LIndex + 1] + LInput[LIndex + 2] + LInput[LIndex + 3];
    Result := Result + Chr(StrToIntDef('$' + LValue, 0));
    Inc(LIndex, 4);
  end;
end;

function THexBigEndianWithoutSpacesEncoding.DoEncode(const AInput: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 1 to Length(AInput) do
    Result := Result + IntToHex(Integer(AInput[LIndex]), 4);
  Result := TextEditor.Utils.Trim(Result);
end;

{ THexLittleEndianWithoutSpacesEncoding }

function THexLittleEndianWithoutSpacesEncoding.DoDecode(const AInput: string): string;
var
  LInput: string;
  LIndex: Integer;
  LValue: string;
begin
  Result := '';
  LInput := TextEditor.Utils.Trim(StringReplace(AInput, TControlCharacters.CarriageReturnLinefeed, ' ', [rfReplaceAll]));
  LInput := TextEditor.Utils.Trim(StringReplace(LInput, TControlCharacters.Linefeed, ' ', [rfReplaceAll]));
  LIndex := 1;
  while LIndex < Length(LInput) do
  begin
    LValue := LInput[LIndex] + LInput[LIndex + 1] + LInput[LIndex + 2] + LInput[LIndex + 3];
    Result := Result + Chr(StrToIntDef('$' + LValue, 0));
    Inc(LIndex, 4);
  end;
end;

function THexLittleEndianWithoutSpacesEncoding.DoEncode(const AInput: string): string;
var
  LIndex: Integer;
  LChar: Char;
begin
  Result := '';
  for LIndex := 1 to Length(AInput) do
  begin
    LChar := AInput[LIndex];
    SwapChar(LChar);
    Result := Result + IntToHex(Integer(LChar), 4);
  end;
  Result := TextEditor.Utils.Trim(Result);
end;

{ TOctalEncoding }

function IntToOct(const AValue: Integer; const ADigits: Integer = 2): string;
var
  LValue, LRest, LCount: Integer;
begin
  Result := '';
  LValue := AValue;
  while LValue <> 0 do
  begin
    LRest  := LValue mod 8;
    LValue := LValue div 8;
    Result := IntToStr(LRest) + Result;
  end;
  LCount := ADigits - Length(Result) - 1;
  if LCount > 0 then
    Result := StringOfChar('0', LCount) + Result;
end;

function OctToInt(const AValue: string): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 1 to Length(AValue) do
    Result := Result * 8 + StrToInt(Copy(AValue, LIndex, 1));
end;

function TOctalEncoding.DoDecode(const AInput: string): string;
var
  LInput: string;
  LIndex: Integer;
  LValue: string;

  procedure AddToResult;
  begin
    if LValue <> '' then
    begin
      Result := Result + Chr(OctToInt(LValue));
      LValue := '';
    end;
  end;

begin
  Result := '';
  LInput := TextEditor.Utils.Trim(StringReplace(AInput, TControlCharacters.CarriageReturnLinefeed, ' ', [rfReplaceAll]));
  LInput := TextEditor.Utils.Trim(StringReplace(LInput, TControlCharacters.Linefeed, ' ', [rfReplaceAll]));
  for LIndex := 1 to Length(LInput) do
  begin
    if LInput[LIndex] = ' ' then
      AddToResult
    else
      LValue := LValue + LInput[LIndex];
  end;
  AddToResult;
end;

function TOctalEncoding.DoEncode(const AInput: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 1 to Length(AInput) do
  begin
    Result := Result + IntToOct(Ord(AInput[LIndex]), 2);
    Result := Result + ' ';
  end;
  Result := TextEditor.Utils.Trim(Result);
end;

{ TRotateXEncoding }

function RotateBy(const AValue: String; const ARotate: Integer): string;

  function RotateChar(const AChr: Char; const ARotate: Integer): Char;
  var
    LStart, LRotate: Integer;
  begin
    LStart := 0;
    LRotate := 0;
    case ARotate of
      5:
        if AChr in TCharacterSets.Numbers then
        begin
          LStart := 48; // '0'
          LRotate := 5;
        end;
      13:
        if AChr in TCharacterSets.UpperCharacters then
        begin
          LStart := 65; // 'A'
          LRotate := 13;
        end
        else
        if AChr in TCharacterSets.LowerCharacters then
        begin
          LStart := 97; // 'a'
          LRotate := 13;
        end;
      18:
        if AChr in TCharacterSets.Numbers then
        begin
          LStart := 48; // '0'
          LRotate := 5;
        end
        else
        if AChr in TCharacterSets.UpperCharacters then
        begin
          LStart := 65; // 'A'
          LRotate := 13;
        end
        else
        if AChr in TCharacterSets.LowerCharacters then
        begin
          LStart := 97; // 'a'
          LRotate := 13;
        end;
      47:
        if AChr in ['!'..'~'] then
        begin
          LStart := 33; // '!'
          LRotate := 47;
        end
    end;

    if LStart <> 0 then
      Result := Chr(LStart + ((Ord(AChr) - LStart + LRotate) mod (LRotate * 2)))
    else
      Result := AChr;
  end;

var
  LIndex: Integer;
begin
  Result := '';

  SetLength(Result, Length(AValue));
  for LIndex := 1 to Length(AValue) do
    Result[LIndex] := RotateChar(AValue[LIndex], ARotate);
end;

function TRotate5Encoding.DoDecode(const AInput: string): string;
begin
  Result := RotateBy(AInput, 5);
end;

function TRotate5Encoding.DoEncode(const AInput: string): string;
begin
  Result := RotateBy(AInput, 5);
end;

function TRotate13Encoding.DoDecode(const AInput: string): string;
begin
  Result := RotateBy(AInput, 13);
end;

function TRotate13Encoding.DoEncode(const AInput: string): string;
begin
  Result := RotateBy(AInput, 13);
end;

function TRotate18Encoding.DoDecode(const AInput: string): string;
begin
  Result := RotateBy(AInput, 18);
end;

function TRotate18Encoding.DoEncode(const AInput: string): string;
begin
  Result := RotateBy(AInput, 18);
end;

{ TRotate47Encoding }

function TRotate47Encoding.DoDecode(const AInput: string): string;
begin
  Result := RotateBy(AInput, 47);
end;

function TRotate47Encoding.DoEncode(const AInput: string): string;
begin
  Result := RotateBy(AInput, 47);
end;

{ TBase32 }

function TBase32Encoding.DoDecode(const AInput: string): string;
var
  LMethod: IBase;
begin
  LMethod := TBase32.Create;
  Result := LMethod.DecodeToString(AInput);
end;

function TBase32Encoding.DoEncode(const AInput: string): string;
var
  LMethod: IBase;
begin
  LMethod := TBase32.Create;
  Result := LMethod.EncodeString(AInput);
end;

{ TBase64NoLineBreaksEncoding }

function TBase64NoLineBreaksEncoding.DoDecode(const AInput: string): string;
var
  LMethod: IBase;
begin
  LMethod := TBase64.Create;
  Result := LMethod.DecodeToString(AInput);
end;

function TBase64NoLineBreaksEncoding.DoEncode(const AInput: string): string;
var
  LMethod: IBase;
begin
  LMethod := TBase64.Create;
  Result := LMethod.EncodeString(AInput);
end;

{ TBase85 }

function TBase85Encoding.DoDecode(const AInput: string): string;
var
  LMethod: IBase;
begin
  LMethod := TBase85.Create;
  Result := LMethod.DecodeToString(AInput);
end;

function TBase85Encoding.DoEncode(const AInput: string): string;
var
  LMethod: IBase;
begin
  LMethod := TBase85.Create;
  Result := LMethod.EncodeString(AInput);
end;

{ TBase91 }

function TBase91Encoding.DoDecode(const AInput: string): string;
var
  LMethod: IBase;
begin
  LMethod := TBase91.Create;
  Result := LMethod.DecodeToString(AInput);
end;

function TBase91Encoding.DoEncode(const AInput: string): string;
var
  LMethod: IBase;
begin
  LMethod := TBase91.Create;
  Result := LMethod.EncodeString(AInput);
end;

{ TBase128 }

function TBase128Encoding.DoDecode(const AInput: string): string;
var
  LMethod: IBase;
begin
  LMethod := TBase128.Create;
  Result := LMethod.DecodeToString(AInput);
end;

function TBase128Encoding.DoEncode(const AInput: string): string;
var
  LMethod: IBase;
begin
  LMethod := TBase128.Create;
  Result := LMethod.EncodeString(AInput);
end;

{ TBase256 }

function TBase256Encoding.DoDecode(const AInput: string): string;
var
  LMethod: IBase;
begin
  LMethod := TBase256.Create;
  Result := LMethod.DecodeToString(AInput);
end;

function TBase256Encoding.DoEncode(const AInput: string): string;
var
  LMethod: IBase;
begin
  LMethod := TBase256.Create;
  Result := LMethod.EncodeString(AInput);
end;

{ TBase1024 }

function TBase1024Encoding.DoDecode(const AInput: string): string;
var
  LMethod: IBase;
begin
  LMethod := TBase1024.Create;
  Result := LMethod.DecodeToString(AInput);
end;

function TBase1024Encoding.DoEncode(const AInput: string): string;
var
  LMethod: IBase;
begin
  LMethod := TBase1024.Create;
  Result := LMethod.EncodeString(AInput);
end;

{ TBase4096 }

function TBase4096Encoding.DoDecode(const AInput: string): string;
var
  LMethod: IBase;
begin
  LMethod := TBase4096.Create;
  Result := LMethod.DecodeToString(AInput);
end;

function TBase4096Encoding.DoEncode(const AInput: string): string;
var
  LMethod: IBase;
begin
  LMethod := TBase4096.Create;
  Result := LMethod.EncodeString(AInput);
end;

class function TNetEncoding.GetASCIIDecimal: TASCIIDecimalEncoding;
var
  LEncoding: TASCIIDecimalEncoding;
begin
  if not Assigned(FASCIIDecimal) then
  begin
    LEncoding := TASCIIDecimalEncoding.Create;
    if AtomicCmpExchange(Pointer(FASCIIDecimal), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FASCIIDecimal.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FASCIIDecimal;
end;

class function TNetEncoding.GetBinary: TBinaryEncoding;
var
  LEncoding: TBinaryEncoding;
begin
  if not Assigned(FBinary) then
  begin
    LEncoding := TBinaryEncoding.Create;
    if AtomicCmpExchange(Pointer(FBinary), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FBinary.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FBinary;
end;

class function TNetEncoding.GetHex: THexEncoding;
var
  LEncoding: THexEncoding;
begin
  if not Assigned(FHex) then
  begin
    LEncoding := THexEncoding.Create;
    if AtomicCmpExchange(Pointer(FHex), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FHex.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FHex;
end;

class function TNetEncoding.GetHexBigEndian: THexBigEndianEncoding;
var
  LEncoding: THexBigEndianEncoding;
begin
  if not Assigned(FHexBigEndian) then
  begin
    LEncoding := THexBigEndianEncoding.Create;
    if AtomicCmpExchange(Pointer(FHexBigEndian), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FHexBigEndian.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FHexBigEndian;
end;

class function TNetEncoding.GetHexLittleEndian: THexLittleEndianEncoding;
var
  LEncoding: THexLittleEndianEncoding;
begin
  if not Assigned(FHexLittleEndian) then
  begin
    LEncoding := THexLittleEndianEncoding.Create;
    if AtomicCmpExchange(Pointer(FHexLittleEndian), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FHexLittleEndian.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FHexLittleEndian;
end;

class function TNetEncoding.GetHexWithoutSpaces: THexWithoutSpacesEncoding;
var
  LEncoding: THexWithoutSpacesEncoding;
begin
  if not Assigned(FHexWithoutSpaces) then
  begin
    LEncoding := THexWithoutSpacesEncoding.Create;
    if AtomicCmpExchange(Pointer(FHexWithoutSpaces), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FHexWithoutSpaces.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FHexWithoutSpaces;
end;

class function TNetEncoding.GetHexBigEndianWithoutSpaces: THexBigEndianWithoutSpacesEncoding;
var
  LEncoding: THexBigEndianWithoutSpacesEncoding;
begin
  if not Assigned(FHexBigEndianWithoutSpaces) then
  begin
    LEncoding := THexBigEndianWithoutSpacesEncoding.Create;
    if AtomicCmpExchange(Pointer(FHexBigEndianWithoutSpaces), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FHexBigEndianWithoutSpaces.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FHexBigEndianWithoutSpaces;
end;

class function TNetEncoding.GetHexLittleEndianWithoutSpaces: THexLittleEndianWithoutSpacesEncoding;
var
  LEncoding: THexLittleEndianWithoutSpacesEncoding;
begin
  if not Assigned(FHexLittleEndianWithoutSpaces) then
  begin
    LEncoding := THexLittleEndianWithoutSpacesEncoding.Create;
    if AtomicCmpExchange(Pointer(FHexLittleEndianWithoutSpaces), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FHexLittleEndianWithoutSpaces.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FHexLittleEndianWithoutSpaces;
end;

class function TNetEncoding.GetOctal: TOctalEncoding;
var
  LEncoding: TOctalEncoding;
begin
  if not Assigned(FOctal) then
  begin
    LEncoding := TOctalEncoding.Create;
    if AtomicCmpExchange(Pointer(FOctal), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FOctal.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FOctal;
end;

class function TNetEncoding.GetRotate5: TRotate5Encoding;
var
  LEncoding: TRotate5Encoding;
begin
  if not Assigned(FRotate5) then
  begin
    LEncoding := TRotate5Encoding.Create;
    if AtomicCmpExchange(Pointer(FRotate5), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FRotate5.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FRotate5;
end;

class function TNetEncoding.GetRotate13: TRotate13Encoding;
var
  LEncoding: TRotate13Encoding;
begin
  if not Assigned(FRotate13) then
  begin
    LEncoding := TRotate13Encoding.Create;
    if AtomicCmpExchange(Pointer(FRotate13), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FRotate13.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FRotate13;
end;

class function TNetEncoding.GetRotate18: TRotate18Encoding;
var
  LEncoding: TRotate18Encoding;
begin
  if not Assigned(FRotate18) then
  begin
    LEncoding := TRotate18Encoding.Create;
    if AtomicCmpExchange(Pointer(FRotate18), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FRotate18.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FRotate18;
end;

class function TNetEncoding.GetRotate47: TRotate47Encoding;
var
  LEncoding: TRotate47Encoding;
begin
  if not Assigned(FRotate47) then
  begin
    LEncoding := TRotate47Encoding.Create;
    if AtomicCmpExchange(Pointer(FRotate47), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FRotate47.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FRotate47;
end;

class function TNetEncoding.GetBase32: TBase32Encoding;
var
  LEncoding: TBase32Encoding;
begin
  if not Assigned(FBase32) then
  begin
    LEncoding := TBase32Encoding.Create;
    if AtomicCmpExchange(Pointer(FBase32), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FBase32.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FBase32;
end;

class function TNetEncoding.GetBase64NoLineBreaks: TBase64NoLineBreaksEncoding;
var
  LEncoding: TBase64NoLineBreaksEncoding;
begin
  if not Assigned(FBase64NoLineBreaks) then
  begin
    LEncoding := TBase64NoLineBreaksEncoding.Create;
    if AtomicCmpExchange(Pointer(FBase64NoLineBreaks), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FBase64NoLineBreaks.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FBase64NoLineBreaks;
end;

class function TNetEncoding.GetBase85: TBase85Encoding;
var
  LEncoding: TBase85Encoding;
begin
  if not Assigned(FBase85) then
  begin
    LEncoding := TBase85Encoding.Create;
    if AtomicCmpExchange(Pointer(FBase85), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FURLEncoding.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FBase85;
end;

class function TNetEncoding.GetBase91: TBase91Encoding;
var
  LEncoding: TBase91Encoding;
begin
  if not Assigned(FBase91) then
  begin
    LEncoding := TBase91Encoding.Create;
    if AtomicCmpExchange(Pointer(FBase91), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FBase91.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FBase91;
end;

class function TNetEncoding.GetBase128: TBase128Encoding;
var
  LEncoding: TBase128Encoding;
begin
  if not Assigned(FBase128) then
  begin
    LEncoding := TBase128Encoding.Create;
    if AtomicCmpExchange(Pointer(FBase128), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FBase128.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FBase128;
end;

class function TNetEncoding.GetBase256: TBase256Encoding;
var
  LEncoding: TBase256Encoding;
begin
  if FBase256 = nil then
  begin
    LEncoding := TBase256Encoding.Create;
    if AtomicCmpExchange(Pointer(FBase256), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FBase256.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FBase256;
end;

class function TNetEncoding.GetBase1024: TBase1024Encoding;
var
  LEncoding: TBase1024Encoding;
begin
  if FBase1024 = nil then
  begin
    LEncoding := TBase1024Encoding.Create;
    if AtomicCmpExchange(Pointer(FBase1024), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FBase1024.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FBase1024;
end;

class function TNetEncoding.GetBase4096: TBase4096Encoding;
var
  LEncoding: TBase4096Encoding;
begin
  if FBase4096 = nil then
  begin
    LEncoding := TBase4096Encoding.Create;
    if AtomicCmpExchange(Pointer(FBase4096), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free;
{$IFDEF AUTOREFCOUNT}
    FBase4096.__ObjAddRef;
{$ENDIF AUTOREFCOUNT}
  end;
  Result := FBase4096;
end;

class destructor TNetEncoding.Destroy;
begin
  FreeAndNil(FASCIIDecimal);
  FreeAndNil(FBinary);
  FreeAndNil(FHex);
  FreeAndNil(FHexBigEndian);
  FreeAndNil(FHexLittleEndian);
  FreeAndNil(FHexWithoutSpaces);
  FreeAndNil(FHexBigEndianWithoutSpaces);
  FreeAndNil(FHexLittleEndianWithoutSpaces);
  FreeAndNil(FOctal);
  FreeAndNil(FRotate5);
  FreeAndNil(FRotate13);
  FreeAndNil(FRotate18);
  FreeAndNil(FRotate47);
  FreeAndNil(FBase32);
  FreeAndNil(FBase64NoLineBreaks);
  FreeAndNil(FBase85);
  FreeAndNil(FBase91);
  FreeAndNil(FBase128);
  FreeAndNil(FBase256);
  FreeAndNil(FBase1024);
  FreeAndNil(FBase4096);
  inherited;
end;
{$ENDIF}

initialization

finalization

  TEncoding.UTF8WithoutBOM.Free;

end.
