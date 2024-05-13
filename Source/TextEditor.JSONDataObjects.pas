{$WARN WIDECHAR_REDUCED OFF} // CharInSet is slow in loops
unit TextEditor.JSONDataObjects;

{ Based on: https://github.com/ahausladen/JsonDataObjects

  Copyright (c) 2015-2016 Andreas Hausladen
  MIT license: https://github.com/ahausladen/JsonDataObjects/blob/master/LICENSE

  Unnecessary bloat for TTextEditor removed and some useful features added. }

interface

uses
  System.Classes, System.SysUtils, System.UITypes, Vcl.Graphics, TextEditor.Consts;

type
  TJSONBaseObject = class;
  TJSONObject = class;
  TJSONArray = class;

  EJSONException = class(Exception);
  EJSONCastException = class(EJSONException);
  EJSONPathException = class(EJSONException);

  EJSONParserException = class(EJSONException)
  private
    FColumn: NativeInt;
    FLineNum: NativeInt;
    FPosition: NativeInt;
  public
    constructor CreateResFmt(const ResStringRec: PResStringRec; const Args: array of const; const ALineNum, AColumn, APosition: NativeInt);
    constructor CreateRes(const ResStringRec: PResStringRec; const ALineNum, AColumn, APosition: NativeInt);
    property Column: NativeInt read FColumn;
    property LineNum: NativeInt read FLineNum;
    property Position: NativeInt read FPosition;
  end;

  TJSONOutputWriter = record
  private type
    TLastType = (ltInitial, ltIndent, ltUnindent, ltIntro, ltValue, ltSeparator);

    PJSONStringArray = ^TJSONStringArray;
    TJSONStringArray = array [0 .. MaxInt div SizeOf(string) - 1] of string;
    PJSONStringBuilder = ^TJSONStringBuilder;

    TJSONStringBuilder = record
    private
      FCapacity: Integer;
      FData: PChar;
      FDataLength: Integer;
      procedure Grow(MinLen: Integer);
    public
      function Append(const AValue: string): PJSONStringBuilder; overload;
      function Append2(const S1: string; S2: PChar; S2Len: Integer): PJSONStringBuilder; overload;
      function FlushToBytes(var Bytes: PByte; var Size: NativeInt; Encoding: TEncoding): NativeInt;
      procedure Append(const P: PChar; const Len: Integer); overload;
      procedure Append2(const Ch1: Char; const Ch2: Char); overload;
      procedure Append3(const Ch1: Char; const P2: PChar; P2Len: Integer; const Ch3: Char); overload;
      procedure Append3(const Ch1: Char; const S2, S3: string); overload;
      procedure Append3(const Ch1: Char; const S2: string; const Ch3: Char); overload;
      procedure Done;
      procedure DoneConvertToString(var S: string);
      procedure FlushToMemoryStream(const Stream: TMemoryStream; const Encoding: TEncoding);
      procedure FlushToString(var S: string);
      procedure FlushToStringBuffer(var Buffer: TJSONStringBuilder);
      procedure Init;
      property Data: PChar read FData;
      property DataLength: Integer read FDataLength;
    end;

  private
    FCompact: Boolean;
    FEncoding: TEncoding;
    FIndent: Integer;
    FIndents: PJSONStringArray;
    FIndentsLen: Integer;
    FLastLine: TJSONStringBuilder;
    FLastType: TLastType;
    FLines: TStrings;
    FStream: TStream;
    FStreamEncodingBuffer: PByte;
    FStreamEncodingBufferLen: NativeInt;
    FStringBuffer: TJSONStringBuilder;
    procedure AppendLine(const AppendOn: TLastType; const S: string); overload;
    procedure ExpandIndents;
    procedure FlushLastLine;
    procedure StreamFlush;
    procedure StreamFlushPossible;
  private
    function Done: string;
    procedure AppendIntro(const P: PChar; const Len: Integer);
    procedure AppendSeparator(const S: string);
    procedure AppendStrValue(const P: PChar; const Len: Integer);
    procedure AppendValue(const S: string); overload;
    procedure FreeIndents;
    procedure Indent(const S: string);
    procedure Init(const ACompact: Boolean; const AStream: TStream; const AEncoding: TEncoding; const ALines: TStrings);
    procedure Unindent(const S: string);
  end;

  TJSONDataType = (jdtNone, jdtString, jdtBool, jdtArray, jdtObject);

  PJSONDataValue = ^TJSONDataValue;

  TJSONDataValue = packed record
  private type
    TJSONDataValueRec = record
      case TJSONDataType of
        jdtNone:
          (ValuePChar: PChar);
        jdtString:
          (ValueString: Pointer);
        jdtBool:
          (ValueBoolean: Boolean);
        jdtArray:
          (ValueArray: Pointer);
        jdtObject:
          (ValueObject: Pointer);
    end;
  private
    FDataType: TJSONDataType;
    FValue: TJSONDataValueRec;
    function GetValue: string;
    function GetValueArrayValue: TJSONArray;
    function GetValueBooleanValue: Boolean;
    function GetValueObjectValue: TJSONObject;
    procedure Clear;
    procedure InternSetValueArrayValue(const AValue: TJSONArray);
    procedure InternSetValueObjectValue(const AValue: TJSONObject);
    procedure InternSetValueTransfer(var AValue: string);
    procedure InternToJSON(var Writer: TJSONOutputWriter);
    procedure SetValue(const AValue: string);
    procedure SetValueArrayValue(const AValue: TJSONArray);
    procedure SetValueBooleanValue(const AValue: Boolean);
    procedure SetValueObjectValue(const AValue: TJSONObject);
    procedure TypeCastError(const AExpectedType: TJSONDataType);
  public
    property ArrayValue: TJSONArray read GetValueArrayValue write SetValueArrayValue;
    property BoolValue: Boolean read GetValueBooleanValue write SetValueBooleanValue;
    property DataType: TJSONDataType read FDataType;
    property ObjectValue: TJSONObject read GetValueObjectValue write SetValueObjectValue;
    property Value: string read GetValue write SetValue;
  end;

  TJSONDataValueHelper = record
  private
    class procedure SetInternValue(const AItem: PJSONDataValue; const AValue: TJSONDataValueHelper); static;
    function GetTyp: TJSONDataType;
    function GetValue: string;
    function GetValueArray(const AName: string): TJSONArray;
    function GetValueArrayCount: Integer;
    function GetValueArrayItem(const AIndex: Integer): TJSONDataValueHelper;
    function GetValueArrayValue: TJSONArray;
    function GetValueBooleanValue: Boolean;
    function GetValueObject(const AName: string): TJSONDataValueHelper;
    function GetValueObjectBool(const AName: string): Boolean;
    function GetValueObjectPath(const AName: string): TJSONDataValueHelper;
    function GetValueObjectString(const AName: string): string;
    function GetValueObjectValue: TJSONObject;
    procedure ResolveName;
    procedure SetValue(const AValue: string);
    procedure SetValueArray(const AName: string; const AValue: TJSONArray);
    procedure SetValueArrayValue(const AValue: TJSONArray);
    procedure SetValueBooleanValue(const AValue: Boolean);
    procedure SetValueObject(const AName: string; const AValue: TJSONDataValueHelper);
    procedure SetValueObjectBool(const AName: string; const AValue: Boolean);
    procedure SetValueObjectPath(const AName: string; const AValue: TJSONDataValueHelper);
    procedure SetValueObjectString(const AName, AValue: string);
    procedure SetValueObjectValue(const AValue: TJSONObject);
  public
    class operator Implicit(const AValue: Boolean): TJSONDataValueHelper; overload;
    class operator Implicit(const AValue: string): TJSONDataValueHelper; overload;
    class operator Implicit(const AValue: TJSONArray): TJSONDataValueHelper; overload;
    class operator Implicit(const AValue: TJSONDataValueHelper): Boolean; overload;
    class operator Implicit(const AValue: TJSONDataValueHelper): string; overload;
    class operator Implicit(const AValue: TJSONDataValueHelper): TJSONArray; overload;
    class operator Implicit(const AValue: TJSONDataValueHelper): TJSONObject; overload;
    class operator Implicit(const AValue: TJSONObject): TJSONDataValueHelper; overload;
    function ToColor: TColor;
    function ToInt(Default: Integer): Integer;
    function ToSet: TTextEditorCharSet;
    function ToStr(const ADefault: string): string;
    property ArrayValue: TJSONArray read GetValueArrayValue write SetValueArrayValue;
    property BoolValue: Boolean read GetValueBooleanValue write SetValueBooleanValue;
    property Count: Integer read GetValueArrayCount;
    property Items[const AIndex: Integer]: TJSONDataValueHelper read GetValueArrayItem;
    property ObjectPath[const AName: string]: TJSONDataValueHelper read GetValueObjectPath write SetValueObjectPath;
    property ObjectValue: TJSONObject read GetValueObjectValue write SetValueObjectValue;
    property Typ: TJSONDataType read GetTyp;
    property Value: string read GetValue write SetValue;
    property ValueArray[const AName: string]: TJSONArray read GetValueArray write SetValueArray;
    property ValueBoolean[const AName: string]: Boolean read GetValueObjectBool write SetValueObjectBool;
    property ValueObject[const AName: string]: TJSONDataValueHelper read GetValueObject write SetValueObject; default;
    property ValueObjectString[const AName: string]: string read GetValueObjectString write SetValueObjectString;
  private
    FData: record
      FIntern: PJSONDataValue;
      FName: string;
      FNameResolver: TJSONObject;
      FValue: string;
      case FDataType: TJSONDataType of
        jdtBool:
          (FBoolValue: Boolean);
        jdtObject:
          (FObj: TJSONBaseObject);
    end;
  end;

  TJSONBaseObject = class abstract(TObject)
  private type
    TWriterAppendMethod = procedure(const P: PChar; const Len: Integer) of object;

    TStreamInfo = record
      Buffer: PByte;
      Size: NativeInt;
      AllocationBase: Pointer;
    end;

  private
    class procedure EscapeStrToJSONStr(F, P, EndP: PChar; const AppendMethod: TWriterAppendMethod); static;
    class procedure GetStreamBytes(const Stream: TStream; var Encoding: TEncoding; const Utf8WithoutBOM: Boolean; var StreamInfo: TStreamInfo); static;
    class procedure InternInitAndAssignItem(const Dest, Source: PJSONDatAValue); static;
    class procedure StrToJSONStr(const AppendMethod: TWriterAppendMethod; const S: string); static;
  protected
    procedure InternToJSON(var Writer: TJSONOutputWriter); virtual; abstract;
  public const
    DataTypeNames: array [TJSONDataType] of string = ('null', 'String', 'Bool', 'Array', 'Object');
    class function Parse(const Bytes: TBytes; const ByteIndex: Integer = 0; ByteCount: Integer = -1): TJSONBaseObject; overload; static;
    class function Parse(const S: UnicodeString): TJSONBaseObject; overload; static; inline;
    class function Parse(S: PWideChar; Len: Integer = -1): TJSONBaseObject; overload; static;
    class function ParseFromStream(const Stream: TStream): TJSONBaseObject; static;
    class function ParseUtf8Bytes(const S: PByte; Len: Integer = -1): TJSONBaseObject; static;
    function ToJSON(const ACompact: Boolean = True): string;
    function ToString: string; override;
    procedure FromJSON(const S: UnicodeString); overload;
    procedure FromJSON(S: PWideChar; Len: Integer = -1); overload;
    procedure FromUtf8JSON(const S: PByte; Len: Integer = -1); overload;
    procedure LoadFromStream(const Stream: TStream);
  end;

  PJSONDataValueArray = ^TJSONDataValueArray;
  TJSONDataValueArray = array [0 .. MaxInt div SizeOf(TJSONDataValue) - 1] of TJSONDataValue;

  TJSONArrayEnumerator = class(TObject)
  private
    FIndex: Integer;
    FArray: TJSONArray;
  public
    constructor Create(const AArray: TJSONArray);

    function GetCurrent: TJSONDataValueHelper;
    function MoveNext: Boolean;
    property Current: TJSONDataValueHelper read GetCurrent;
  end;

  TJSONArray = class(TJSONBaseObject)
  private
    FCapacity: Integer;
    FCount: Integer;
    FItems: PJSONDataValueArray;
    function AddItem: PJSONDataValue;
    function GetValueArray(const AIndex: Integer): TJSONArray;
    function GetValueBoolean(const AIndex: Integer): Boolean;
    function GetItem(const AIndex: Integer): PJSONDataValue;
    function GetValueObject(const AIndex: Integer): TJSONObject;
    function GetValueString(const AIndex: Integer): string;
    function GetType(const AIndex: Integer): TJSONDataType;
    function GetValue(const AIndex: Integer): TJSONDataValueHelper;
    function InsertItem(const AIndex: Integer): PJSONDataValue;
    procedure Grow;
    procedure InternApplyCapacity;
    procedure SetValueArray(const AIndex: Integer; const AValue: TJSONArray);
    procedure SetValueBoolean(const AIndex: Integer; const AValue: Boolean);
    procedure SetCapacity(const AValue: Integer);
    procedure SetCount(const AValue: Integer);
    procedure SetValueObject(const AIndex: Integer; const AValue: TJSONObject);
    procedure SetValueString(const AIndex: Integer; const AValue: string);
    procedure SetValue(const AIndex: Integer; const AValue: TJSONDataValueHelper);
  protected
    procedure InternToJSON(var Writer: TJSONOutputWriter); override;
    class procedure RaiseListError(const AIndex: Integer); static;
  public
    destructor Destroy; override;
    function AddArray: TJSONArray;
    function AddObject: TJSONObject; overload;
    function GetEnumerator: TJSONArrayEnumerator;
    function InsertArray(const AIndex: Integer): TJSONArray;
    function InsertObject(const AIndex: Integer): TJSONObject; overload;
    procedure Add(const AValue: Boolean); overload;
    procedure Add(const AValue: string); overload;
    procedure Add(const AValue: TJSONArray); overload;
    procedure Add(const AValue: TJSONObject); overload;
    procedure AddObject(const AValue: TJSONObject); overload;
    procedure Assign(const ASource: TJSONArray);
    procedure Clear;
    procedure Delete(const AIndex: Integer);
    procedure Insert(const AIndex: Integer; const AValue: Boolean); overload;
    procedure Insert(const AIndex: Integer; const AValue: string); overload;
    procedure Insert(const AIndex: Integer; const AValue: TJSONArray); overload;
    procedure Insert(const AIndex: Integer; const AValue: TJSONObject); overload;
    procedure InsertObject(const AIndex: Integer; const AValue: TJSONObject); overload;
    property Capacity: Integer read FCapacity write SetCapacity;
    property Count: Integer read FCount write SetCount;
    property Items[const AIndex: Integer]: PJSONDataValue read GetItem;
    property Types[const AIndex: Integer]: TJSONDataType read GetType;
    property ValueArray[const AIndex: Integer]: TJSONArray read GetValueArray write SetValueArray;
    property ValueBoolean[const AIndex: Integer]: Boolean read GetValueBoolean write SetValueBoolean;
    property ValueObject[const AIndex: Integer]: TJSONObject read GetValueObject write SetValueObject;
    property ValueString[const AIndex: Integer]: string read GetValueString write SetValueString;
    property Values[const AIndex: Integer]: TJSONDataValueHelper read GetValue write SetValue; default;
  end;

  TJSONNameValuePair = record
    Name: string;
    Value: TJSONDataValueHelper;
  end;

  TJSONObjectEnumerator = class(TObject)
  protected
    FIndex: Integer;
    FObject: TJSONObject;
  public
    constructor Create(const AObject: TJSONObject);

    function GetCurrent: TJSONNameValuePair;
    function MoveNext: Boolean;
    property Current: TJSONNameValuePair read GetCurrent;
  end;

  TJSONObject = class(TJSONBaseObject)
  private type
    PJSONStringArray = ^TJSONStringArray;
    TJSONStringArray = array [0 .. MaxInt div SizeOf(string) - 1] of string;
  private
    FCapacity: Integer;
    FCount: Integer;
    FItems: PJSONDataValueArray;
    FNames: PJSONStringArray;
    function AddItem(const AName: string): PJSONDataValue;
    function FindItem(const AName: string; var Item: PJSONDataValue): Boolean;
    function GetItem(const AIndex: Integer): PJSONDataValue;
    function GetName(const AIndex: Integer): string;
    function GetPath(const ANamePath: string): TJSONDataValueHelper;
    function GetType(const AName: string): TJSONDataType;
    function GetValue(const AName: string): TJSONDataValueHelper;
    function GetValueArray(const AName: string): TJSONArray;
    function GetValueBoolean(const AName: string): Boolean;
    function GetValueObject(const AName: string): TJSONObject;
    function GetValueString(const AName: string): string;
    function IndexOfPChar(const S: PChar; const Len: Integer): Integer;
    function InternAddArray(var AName: string): TJSONArray;
    function InternAddItem(var AName: string): PJSONDataValue;
    function InternAddObject(var AName: string): TJSONObject;
    function RequireItem(const AName: string): PJSONDataValue;
    procedure Grow;
    procedure InternAdd(var AName: string; const AValue: Boolean); overload;
    procedure InternAdd(var AName: string; const AValue: TJSONArray); overload;
    procedure InternAdd(var AName: string; const AValue: TJSONObject); overload;
    procedure InternApplyCapacity;
    procedure PathError(const P, EndP: PChar);
    procedure PathIndexError(const P, EndP: PChar; const Count: Integer);
    procedure PathNullError(const P, EndP: PChar);
    procedure SetCapacity(const AValue: Integer);
    procedure SetPath(const ANamePath: string; const AValue: TJSONDataValueHelper);
    procedure SetValue(const AName: string; const AValue: TJSONDataValueHelper);
    procedure SetValueArray(const AName: string; const AValue: TJSONArray);
    procedure SetValueBoolean(const AName: string; const AValue: Boolean);
    procedure SetValueObject(const AName: string; const AValue: TJSONObject);
    procedure SetValueString(const AName, AValue: string);
  protected
    procedure InternToJSON(var Writer: TJSONOutputWriter); override;
  public
    destructor Destroy; override;
    function Contains(const AName: string): Boolean;
    function Extract(const AName: string): TJSONBaseObject;
    function ExtractArray(const AName: string): TJSONArray;
    function ExtractObject(const AName: string): TJSONObject;
    function GetEnumerator: TJSONObjectEnumerator;
    function IndexOf(const AName: string): Integer;
    procedure Assign(const ASource: TJSONObject);
    procedure Clear;
    procedure Delete(const AIndex: Integer);
    procedure Remove(const AName: string);
    property Capacity: Integer read FCapacity write SetCapacity;
    property Count: Integer read FCount;
    property Items[const AIndex: Integer]: PJSONDataValue read GetItem;
    property Names[const AIndex: Integer]: string read GetName;
    property Path[const ANamePath: string]: TJSONDataValueHelper read GetPath write SetPath;
    property Types[const AName: string]: TJSONDataType read GetType;
    property ValueArray[const AName: string]: TJSONArray read GetValueArray write SetValueArray;
    property ValueBoolean[const AName: string]: Boolean read GetValueBoolean write SetValueBoolean;
    property ValueObject[const AName: string]: TJSONObject read GetValueObject write SetValueObject;
    property Values[const AName: string]: TJSONDataValueHelper read GetValue write SetValue; default;
    property ValueString[const AName: string]: string read GetValueString write SetValueString;
  end;

implementation

uses
  Winapi.Windows, System.AnsiStrings, System.RTLConsts, TextEditor.Language;

type
  TJSONTokenKind = (jtkEof, jtkInvalidSymbol, jtkLBrace, jtkRBrace, jtkLBracket, jtkRBracket, jtkComma, jtkColon,
    jtkIdent, jtkValue, jtkString, jtkTrue, jtkFalse, jtkNull);

const
  JSONTokenKindToStr: array [TJSONTokenKind] of string = ('end of file', 'invalid symbol', '"{"', '"}"', '"["', '"]"',
    '","', '":"', 'identifier', 'value', 'value', 'value', 'value', 'value');

var
  sTrue: string = 'true';
  sFalse: string = 'false';

const
  sNull = 'null';
  sQuoteChar = '"';

resourcestring
  RsInvalidHexNumber = 'Invalid hex number "%s"';
  RsInvalidStringCharacter = 'Invalid character in string';
  RsStringNotClosed = 'String not closed';
  RsUnexpectedEndOfFile = 'Unexpected end of file where %s was expected';
  RsUnexpectedToken = 'Expected %s but found %s';

type
  PStrRec = ^TStrRec;

  TStrRec = packed record
{$IF defined(CPU64BITS)}
    Padding: Integer;
{$IFEND}
    CodePage: Word;
    ElemSize: Word;
    RefCnt: Integer;
    Length: Integer;
  end;

  TEncodingStrictAccess = class(TEncoding)
  public
    function GetByteCountEx(Chars: PChar; CharCount: Integer): Integer;
    function GetBytesEx(Chars: PChar; CharCount: Integer; Bytes: PByte; ByteCount: Integer): Integer;
    function GetCharCountEx(Bytes: PByte; ByteCount: Integer): Integer;
    function GetCharsEx(Bytes: PByte; ByteCount: Integer; Chars: PChar; CharCount: Integer): Integer;
  end;

  TStringIntern = record
  private type
    PJSONStringEntry = ^TJSONStringEntry;

    TJSONStringEntry = record
      Next: Integer;
      Hash: Integer;
      Name: string;
    end;

    PJSONStringEntryArray = ^TJSONStringEntryArray;
    TJSONStringEntryArray = array [0 .. MaxInt div SizeOf(TJSONStringEntry) - 1] of TJSONStringEntry;

    PJSONIntegerArray = ^TJSONIntegerArray;
    TJSONIntegerArray = array [0 .. MaxInt div SizeOf(Integer) - 1] of Integer;
  private
    FStrings: PJSONStringEntryArray;
    FBuckets: PJSONIntegerArray;
    FCapacity: Integer;
    FCount: Integer;
    class function GetHash(const AName: string): Integer; static;
    procedure Grow;
    function Find(const Hash: Integer; const S: string): Integer;
    procedure InternAdd(const AHash: Integer; const S: string);
  public
    procedure Done;
    procedure Init;
    procedure Intern(var S: string; var PropName: string);
  end;

  TJSONToken = record
    Kind: TJSONTokenKind;
    Value: string;
  end;

  TJSONReader = class(TObject)
  private
    FPropName: string;
    procedure Accept(TokenKind: TJSONTokenKind);
    procedure ParseObjectBody(const Data: TJSONObject);
    procedure ParseObjectProperty(const Data: TJSONObject);
    procedure ParseObjectPropertyValue(const Data: TJSONObject);
    procedure ParseArrayBody(const Data: TJSONArray);
    procedure ParseArrayPropertyValue(const Data: TJSONArray);
    procedure AcceptFailed(TokenKind: TJSONTokenKind);
  protected
    FLook: TJSONToken;
    FLineNum: Integer;
    FStart: Pointer;
    FLineStart: Pointer;
    function GetLineColumn: NativeInt;
    function GetPosition: NativeInt;
    function GetCharOffset(const StartPos: Pointer): NativeInt; virtual; abstract;
    function Next: Boolean; virtual; abstract;
    class procedure InvalidStringCharacterError(const Reader: TJSONReader); static;
    class procedure StringNotClosedError(const Reader: TJSONReader); static;
    class procedure JSONStrToStr(P, EndP: PChar; FirstEscapeIndex: Integer; var S: string; const Reader: TJSONReader); static;
    class procedure JSONUtf8StrToStr(P, EndP: PByte; FirstEscapeIndex: Integer; var S: string; const Reader: TJSONReader); static;
  public
    constructor Create(AStart: Pointer);
    destructor Destroy; override;
    procedure Parse(Data: TJSONBaseObject);
  end;

  TJSONUTF8Reader = class sealed(TJSONReader)
  private
    FText: PByte;
    FTextEnd: PByte;
  protected
    function GetCharOffset(const StartPos: Pointer): NativeInt; override; final;
    function Next: Boolean; override; final;
    procedure LexString(P: PByte);
    procedure LexIdent(P: PByte);
  public
    constructor Create(S: PByte; Len: NativeInt);
  end;

  TJSONStringReader = class sealed(TJSONReader)
  private
    FText: PChar;
    FTextEnd: PChar;
  protected
    function GetCharOffset(const StartPos: Pointer): NativeInt; override; final;
    function Next: Boolean; override; final;
    procedure LexString(P: PChar);
    procedure LexIdent(P: PChar);
  public
    constructor Create(S: PChar; Len: Integer);
  end;

  TMemoryStreamAccess = class(TMemoryStream);

{ EJSONParserSyntaxException }

constructor EJSONParserException.CreateResFmt(const ResStringRec: PResStringRec; const Args: array of const;
  const ALineNum, AColumn, APosition: NativeInt);
begin
  inherited CreateResFmt(ResStringRec, Args);

  FLineNum := ALineNum;
  FColumn := AColumn;
  FPosition := APosition;

  if FLineNum > 0 then
    Message := Format('%s (%d, %d)', [Message, FLineNum, FColumn]);
end;

constructor EJSONParserException.CreateRes(const ResStringRec: PResStringRec; const ALineNum, AColumn, APosition: NativeInt);
begin
  inherited CreateRes(ResStringRec);

  FLineNum := ALineNum;
  FColumn := AColumn;
  FPosition := APosition;

  if FLineNum > 0 then
    Message := Format('%s (%d, %d)', [Message, FLineNum, FColumn]);
end;

procedure ListError(Msg: PResStringRec; Data: Integer);
begin
  raise EStringListError.CreateFmt(LoadResString(Msg), [Data]);
end;

procedure SetValueStringUtf8(var S: string; P: PByte; Len: Integer);
var
  LLength: Integer;
begin
  if S <> '' then
    S := '';

  if (P = nil) or (Len = 0) then
    Exit;

  SetLength(S, Len);

  LLength := Utf8ToUnicode(PWideChar(Pointer(S)), Len + 1, PAnsiChar(P), Len);

  if LLength > 0 then
  begin
    if LLength - 1 <> Len then
      SetLength(S, LLength - 1);
  end
  else
    S := '';
end;

procedure AppendStringUtf8(var S: string; P: PByte; Len: Integer);
var
  L, OldLen: Integer;
begin
  if (P = nil) or (Len = 0) then
    Exit;

  OldLen := Length(S);
  SetLength(S, OldLen + Len);

  L := Utf8ToUnicode(PWideChar(Pointer(S)) + OldLen, Len + 1, PAnsiChar(P), Len);

  if L > 0 then
  begin
    if L - 1 <> Len then
      SetLength(S, OldLen + L - 1);
  end
  else
    SetLength(S, OldLen);
end;

{ TJSONReader }

constructor TJSONReader.Create(AStart: Pointer);
begin
  // inherited Create;

  FStart := AStart;
  FLineNum := 1; // base 1
  FLineStart := nil;
end;

destructor TJSONReader.Destroy; //FI:W504 Missing INHERITED call in destructor
begin
  // inherited Destroy;
end;

function TJSONReader.GetLineColumn: NativeInt;
begin
  if FLineStart = nil then
    FLineStart := FStart;

  Result := GetCharOffset(FLineStart) + 1; // base 1
end;

function TJSONReader.GetPosition: NativeInt;
begin
  Result := GetCharOffset(FStart);
end;

class procedure TJSONReader.InvalidStringCharacterError(const Reader: TJSONReader);
begin
  raise EJSONParserException.CreateRes(@RsInvalidStringCharacter,
    Reader.FLineNum, Reader.GetLineColumn, Reader.GetPosition);
end;

class procedure TJSONReader.StringNotClosedError(const Reader: TJSONReader);
begin
  raise EJSONParserException.CreateRes(@RsStringNotClosed,
    Reader.FLineNum, Reader.GetLineColumn, Reader.GetPosition);
end;

function GetHexDigits(P: PChar; Count: Integer; const Reader: TJSONReader): LongWord;
var
  LChar: Char;
begin
  Result := 0;

  while Count > 0 do
  begin
    LChar := P^;

    case P^ of
      '0'..'9': Result := (Result shl 4) or LongWord(Ord(LChar) - Ord('0'));
      'A'..'F': Result := (Result shl 4) or LongWord(Ord(LChar) - (Ord('A') - 10));
      'a'..'f': Result := (Result shl 4) or LongWord(Ord(LChar) - (Ord('a') - 10));
    else
      Break;
    end;

    Inc(P);
    Dec(Count);
  end;

  if Count > 0 then
    raise EJSONParserException.CreateResFmt(@RsInvalidHexNumber, [P^], Reader.FLineNum, Reader.GetLineColumn,
      Reader.GetPosition);
end;

procedure AppendString(var S: string; P: PChar; Len: Integer);
var
  LLength: Integer;
begin
  if (P = nil) or (Len = 0) then
    Exit;

  LLength := Length(S);
  SetLength(S, LLength + Len);
  Move(P^, PChar(Pointer(S))[LLength], Len * SizeOf(Char));
end;

class procedure TJSONReader.JSONStrToStr(P, EndP: PChar; FirstEscapeIndex: Integer; var S: string;
  const Reader: TJSONReader);
const
  MaxBufPos = 127;
var
  Buf: array[0..MaxBufPos] of Char;
  F: PChar;
  BufPos, Len: Integer;
begin
  Dec(FirstEscapeIndex);

  if FirstEscapeIndex > 0 then
  begin
    SetString(S, P, FirstEscapeIndex);
    Inc(P, FirstEscapeIndex);
  end
  else
    S := '';

  while True do
  begin
    BufPos := 0;
    while (P < EndP) and (P^ = '\') do
    begin
      Inc(P);
      if P = EndP then // broken escaped character
        Break;
      case P^ of
        '"': Buf[BufPos] := '"';
        '\': Buf[BufPos] := '\';
        '/': Buf[BufPos] := '/';
        'b': Buf[BufPos] := #8;
        'f': Buf[BufPos] := #12;
        'n': Buf[BufPos] := #10;
        'r': Buf[BufPos] := #13;
        't': Buf[BufPos] := #9;
        'u':
          begin
            Inc(P);
            if P + 3 >= EndP then
              Break;
            Buf[BufPos] := Char(GetHexDigits(P, 4, TJSONReader(Reader)));
            Inc(P, 3);
          end;
      else
        Break;
      end;
      Inc(P);

      Inc(BufPos);
      if BufPos > MaxBufPos then
      begin
        Len := Length(S);
        SetLength(S, Len + BufPos);
        Move(Buf[0], PChar(Pointer(S))[Len], BufPos * SizeOf(Char));
        BufPos := 0;
      end;
    end;
    // append remaining buffer
    if BufPos > 0 then
    begin
      Len := Length(S);
      SetLength(S, Len + BufPos);
      Move(Buf[0], PChar(Pointer(S))[Len], BufPos * SizeOf(Char));
    end;

    // fast forward
    F := P;
    while (P < EndP) and (P^ <> '\') do
      Inc(P);

    if P > F then
      AppendString(S, F, P - F);

    if P >= EndP then
      Break;
  end;
end;


procedure SetStringUtf8(var S: string; P: PByte; Len: Integer);
var
  L: Integer;
begin
  if S <> '' then
    S := '';
  if (P = nil) or (Len = 0) then
    Exit;
  SetLength(S, Len);

  L := Utf8ToUnicode(PWideChar(Pointer(S)), Len + 1, PAnsiChar(P), Len);
  if L > 0 then
  begin
    if L - 1 <> Len then
      SetLength(S, L - 1);
  end
  else
    S := '';
end;

function GetHexDigitsUtf8(P: PByte; Count: Integer; const Reader: TJSONReader): LongWord;
var
  Ch: Byte;
begin
  Result := 0;
  while Count > 0 do
  begin
    Ch := P^;
    case P^ of
      Ord('0')..Ord('9'): Result := (Result shl 4) or LongWord(Ch - Ord('0'));
      Ord('A')..Ord('F'): Result := (Result shl 4) or LongWord(Ch - (Ord('A') - 10));
      Ord('a')..Ord('f'): Result := (Result shl 4) or LongWord(Ch - (Ord('a') - 10));
    else
      Break;
    end;
    Inc(P);
    Dec(Count);
  end;
  if Count > 0 then
    raise EJSONParserException.CreateResFmt(@RsInvalidHexNumber, [P^], Reader.FLineNum, Reader.GetLineColumn,
      Reader.GetPosition);
end;

class procedure TJSONReader.JSONUtf8StrToStr(P, EndP: PByte; FirstEscapeIndex: Integer; var S: string;
  const Reader: TJSONReader);
const
  MaxBufPos = 127;
var
  Buf: array[0..MaxBufPos] of Char;
  F: PByte;
  BufPos, Len: Integer;
begin
  Dec(FirstEscapeIndex);

  if FirstEscapeIndex > 0 then
  begin
    SetStringUtf8(S, P, FirstEscapeIndex);
    Inc(P, FirstEscapeIndex);
  end
  else
    S := '';

  while True do
  begin
    BufPos := 0;
    while (P < EndP) and (P^ = Byte(Ord('\'))) do
    begin
      Inc(P);
      if P = EndP then // broken escaped character
        Break;
      case P^ of
        Ord('"'): Buf[BufPos] := '"';
        Ord('\'): Buf[BufPos] := '\';
        Ord('/'): Buf[BufPos] := '/';
        Ord('b'): Buf[BufPos] := #8;
        Ord('f'): Buf[BufPos] := #12;
        Ord('n'): Buf[BufPos] := #10;
        Ord('r'): Buf[BufPos] := #13;
        Ord('t'): Buf[BufPos] := #9;
        Ord('u'):
          begin
            Inc(P);
            if P + 3 >= EndP then
              Break;
            Buf[BufPos] := Char(GetHexDigitsUtf8(P, 4, TJSONReader(Reader)));
            Inc(P, 3);
          end;
      else
        Break;
      end;
      Inc(P);

      Inc(BufPos);
      if BufPos > MaxBufPos then
      begin
        Len := Length(S);
        SetLength(S, Len + BufPos);
        Move(Buf[0], PChar(Pointer(S))[Len], BufPos * SizeOf(Char));
        BufPos := 0;
      end;
    end;

    // append remaining buffer
    if BufPos > 0 then
    begin
      Len := Length(S);
      SetLength(S, Len + BufPos);
      Move(Buf[0], PChar(Pointer(S))[Len], BufPos * SizeOf(Char));
    end;

    // fast forward
    F := P;

    while (P < EndP) and (P^ <> Byte(Ord('\'))) do
      Inc(P);

    if P > F then
      AppendStringUtf8(S, F, P - F);

    if P >= EndP then
      Break;
  end;
end;

procedure TJSONReader.Parse(Data: TJSONBaseObject);
begin
  if Data is TJSONObject then
  begin
    TJSONObject(Data).Clear;
    Next; // initialize Lexer
    Accept(jtkLBrace);
    ParseObjectBody(TJSONObject(Data));
    Accept(jtkRBrace);
  end
  else
  if Data is TJSONArray then
  begin
    TJSONArray(Data).Clear;
    Next; // initialize Lexer
    Accept(jtkLBracket);
    ParseArrayBody(TJSONArray(Data));
    Accept(jtkRBracket)
  end;
end;

procedure TJSONReader.ParseObjectBody(const Data: TJSONObject);
begin
  if FLook.Kind <> jtkRBrace then
  begin
    while FLook.Kind <> jtkEof do
    begin
      ParseObjectProperty(Data);

      if FLook.Kind = jtkRBrace then
        Break;

      Accept(jtkComma);
    end;
  end;
end;

procedure TJSONReader.ParseObjectProperty(const Data: TJSONObject);
begin
  if FLook.Kind >= jtkIdent then
  begin
    FPropName := '';
    Pointer(FPropName) := Pointer(FLook.Value);
    Pointer(FLook.Value) := nil;
    Next;
  end
  else
    Accept(jtkString);

  Accept(jtkColon);
  ParseObjectPropertyValue(Data);
end;

procedure TJSONReader.ParseObjectPropertyValue(const Data: TJSONObject);
begin
  case FLook.Kind of
    jtkLBrace:
      begin
        Accept(jtkLBrace);
        ParseObjectBody(Data.InternAddObject(FPropName));
        Accept(jtkRBrace);
      end;
    jtkLBracket:
      begin
        Accept(jtkLBracket);
        ParseArrayBody(Data.InternAddArray(FPropName));
        Accept(jtkRBracket);
      end;
    jtkNull:
      begin
        Data.InternAdd(FPropName, TJSONObject(nil));
        Next;
      end;
    jtkIdent, jtkString:
      begin
        Data.InternAddItem(FPropName).InternSetValueTransfer(FLook.Value);
        Next;
      end;
    jtkTrue:
      begin
        Data.InternAdd(FPropName, True);
        Next;
      end;
    jtkFalse:
      begin
        Data.InternAdd(FPropName, False);
        Next;
      end
  else
    Accept(jtkValue);
  end;
end;

procedure TJSONReader.ParseArrayBody(const Data: TJSONArray);
begin
  if FLook.Kind <> jtkRBracket then
  while FLook.Kind <> jtkEof do
  begin
    ParseArrayPropertyValue(Data);
    if FLook.Kind = jtkRBracket then
      Break;
    Accept(jtkComma);
  end;
end;

procedure TJSONReader.ParseArrayPropertyValue(const Data: TJSONArray);
begin
  case FLook.Kind of
    jtkLBrace:
      begin
        Accept(jtkLBrace);
        ParseObjectBody(Data.AddObject);
        Accept(jtkRBrace);
      end;
    jtkLBracket:
      begin
        Accept(jtkLBracket);
        ParseArrayBody(Data.AddArray);
        Accept(jtkRBracket);
      end;
    jtkNull:
      begin
        Data.Add(TJSONObject(nil));
        Next;
      end;
    jtkIdent, jtkString:
      begin
        Data.Add(FLook.Value);
        Next;
      end;
    jtkTrue:
      begin
        Data.Add(True);
        Next;
      end;
    jtkFalse:
      begin
        Data.Add(False);
        Next;
      end;
  else
    Accept(jtkValue);
  end;
end;

procedure TJSONReader.AcceptFailed(TokenKind: TJSONTokenKind);
var
  Col, Position: NativeInt;
begin
  Col := GetLineColumn;
  Position := GetPosition;
  if FLook.Kind = jtkEof then
    raise EJSONParserException.CreateResFmt(@RsUnexpectedEndOfFile, [JSONTokenKindToStr[TokenKind]], FLineNum, Col, Position);
  raise EJSONParserException.CreateResFmt(@RsUnexpectedToken, [JSONTokenKindToStr[TokenKind], JSONTokenKindToStr[FLook.Kind]], FLineNum, Col, Position);
end;

procedure TJSONReader.Accept(TokenKind: TJSONTokenKind);
begin
  if FLook.Kind <> TokenKind then
    AcceptFailed(TokenKind);
  Next;
end;

{ TJSONDataValue }

procedure TJSONDataValue.Clear;
begin
  case FDataType of
    jdtString:
      string(FValue.ValueString) := '';
    jdtBool:
      FValue.ValueBoolean := False;
    jdtArray, jdtObject:
      begin
        TJSONBaseObject(FValue.ValueObject).Free;
        TJSONBaseObject(FValue.ValueObject) := nil;
      end;
  end;

  FDataType := jdtNone;
end;

function TJSONDataValue.GetValueArrayValue: TJSONArray;
begin
  if FDataType = jdtArray then
    Result := TJSONArray(FValue.ValueArray)
  else
  if FDataType = jdtNone then
    Result := nil
  else
  begin
    TypeCastError(jdtArray);
    Result := nil;
  end;
end;

procedure TJSONDataValue.SetValueArrayValue(const AValue: TJSONArray);
var
  LDataType: TJSONDataType;
begin
  LDataType := FDataType;

  if (LDataType <> jdtArray) or (AValue <> FValue.ValueArray) then
  begin
    if LDataType <> jdtNone then
      Clear;

    FDataType := jdtArray;
    TJSONArray(FValue.ValueArray) := AValue;
  end;
end;

function TJSONDataValue.GetValueObjectValue: TJSONObject;
begin
  if FDataType = jdtObject then
    Result := TJSONObject(FValue.ValueObject)
  else
  if FDataType = jdtNone then
    Result := nil
  else
  begin
    TypeCastError(jdtObject);
    Result := nil;
  end;
end;

procedure TJSONDataValue.SetValueObjectValue(const AValue: TJSONObject);
var
  LDataType: TJSONDataType;
begin
  LDataType := FDataType;

  if (LDataType <> jdtObject) or (AValue <> FValue.ValueObject) then
  begin
    if LDataType <> jdtNone then
      Clear;

    FDataType := jdtObject;
    TJSONObject(FValue.ValueObject) := AValue;
  end;
end;

procedure TJSONDataValue.InternSetValueArrayValue(const AValue: TJSONArray);
begin
  FDataType := jdtArray;
  TJSONArray(FValue.ValueArray) := AValue;
end;

procedure TJSONDataValue.InternSetValueObjectValue(const AValue: TJSONObject);
begin
  FDataType := jdtObject;
  TJSONObject(FValue.ValueObject) := AValue;
end;

function TJSONDataValue.GetValue: string;
begin
  case FDataType of
    jdtNone:
      Result := '';
    jdtString:
      Result := string(FValue.ValueString);
    jdtBool:
      if FValue.ValueBoolean then
        Result := sTrue
      else
        Result := sFalse;
  else
    TypeCastError(jdtString);
    Result := '';
  end;
end;

procedure TJSONDataValue.SetValue(const AValue: string);
var
  LDataType: TJSONDataType;
begin
  LDataType := FDataType;

  if (LDataType <> jdtString) or (AValue <> string(FValue.ValueString)) then
  begin
    if LDataType <> jdtNone then
      Clear;

    FDataType := jdtString;
    string(FValue.ValueString) := AValue;
  end;
end;

procedure TJSONDataValue.InternSetValueTransfer(var AValue: string);
begin
  FDataType := jdtString;
  FValue.ValueString := Pointer(AValue);
  Pointer(AValue) := nil;
end;

function TJSONDataValue.GetValueBooleanValue: Boolean;
begin
  case FDataType of
    jdtNone:
      Result := False;
    jdtString:
      Result := string(FValue.ValueString) = 'true';
    jdtBool:
      Result := FValue.ValueBoolean;
  else
    TypeCastError(jdtBool);
    Result := False;
  end;
end;

procedure TJSONDataValue.SetValueBooleanValue(const AValue: Boolean);
var
  LDataType: TJSONDataType;
begin
  LDataType := FDataType;

  if (LDataType <> jdtBool) or (AValue <> FValue.ValueBoolean) then
  begin
    if LDataType <> jdtNone then
      Clear;

    FDataType := jdtBool;
    FValue.ValueBoolean := AValue;
  end;
end;

procedure TJSONDataValue.InternToJSON(var Writer: TJSONOutputWriter);
begin
  case FDataType of
    jdtNone:
      Writer.AppendValue(sNull);
    jdtString:
      TJSONBaseObject.StrToJSONStr(Writer.AppendStrValue, string(FValue.ValueString));
    jdtBool:
      if FValue.ValueBoolean then
        Writer.AppendValue(sTrue)
      else
        Writer.AppendValue(sFalse);
    jdtArray:
      if (FValue.ValueArray = nil) or (TJSONArray(FValue.ValueArray).Count = 0) then
        Writer.AppendValue('[]')
      else
        TJSONArray(FValue.ValueArray).InternToJSON(Writer);
    jdtObject:
      if FValue.ValueObject = nil then
        Writer.AppendValue(sNull)
      else
        TJSONObject(FValue.ValueObject).InternToJSON(Writer);
  end;
end;

{ TJSONBaseObject }

class procedure TJSONBaseObject.StrToJSONStr(const AppendMethod: TWriterAppendMethod; const S: string);
var
  P, EndP, F: PChar;
begin
  P := PChar(Pointer(S));
  if P <> nil then
  begin
    EndP := P + PInteger(@PByte(S)[-4])^;

    F := P;
    while P < EndP do
      case P^ of
        #0 .. #31, '\', '"':
          Break;
      else
        Inc(P);
      end;

    if P = EndP then
      AppendMethod(PChar(S), Length(S))
    else
      EscapeStrToJSONStr(F, P, EndP, AppendMethod);
  end
  else
    AppendMethod(nil, 0);
end;

class procedure TJSONBaseObject.EscapeStrToJSONStr(F, P, EndP: PChar; const AppendMethod: TWriterAppendMethod);
const
  HexChars: array [0 .. 15] of Char = '0123456789abcdef';
var
  LStringBuilder: TJSONOutputWriter.TJSONStringBuilder;
  LChar: Char;
begin
  LStringBuilder.Init;
  try
    repeat
      if P <> F then
        LStringBuilder.Append(F, P - F);
      if P < EndP then
      begin
        LChar := P^;
        case LChar of
          #0 .. #7, #11, #14 .. #31:
            begin
              LStringBuilder.Append('\u00', 4);
              LStringBuilder.Append2(HexChars[Word(LChar) shr 4], HexChars[Word(LChar) and $F]);
            end;
          #8:
            LStringBuilder.Append('\b', 2);
          #9:
            LStringBuilder.Append('\t', 2);
          #10:
            LStringBuilder.Append('\n', 2);
          #12:
            LStringBuilder.Append('\f', 2);
          #13:
            LStringBuilder.Append('\r', 2);
          '\':
            LStringBuilder.Append('\\', 2);
          '"':
            LStringBuilder.Append('\"', 2);
        end;
        Inc(P);
        F := P;
        while P < EndP do
          case P^ of
            #0 .. #31, '\', '"':
              Break;
          else
            Inc(P);
          end;
      end
      else
        Break;
    until False;

    AppendMethod(LStringBuilder.Data, LStringBuilder.DataLength);
  finally
    LStringBuilder.Done;
  end;
end;

class function TJSONBaseObject.ParseUtf8Bytes(const S: PByte; Len: Integer): TJSONBaseObject;
var
  P: PByte;
  LLength: Integer;
begin
  if (S = nil) or (Len = 0) then
    Result := nil
  else
  begin
    if Len < 0 then
      Len := System.AnsiStrings.StrLen(PAnsiChar(S));

    P := S;
    LLength := Len;

    while (LLength > 0) and (P^ <= 32) do
    begin
      Inc(P);
      Dec(LLength);
    end;

    if LLength = 0 then
      Result := nil
    else
    begin
      if (LLength > 0) and (P^ = Byte(Ord('['))) then
        Result := TJSONArray.Create
      else
        Result := TJSONObject.Create;

      try
        Result.FromUtf8JSON(S, Len);
      except
        Result.Free;
        raise;
      end;
    end;
  end;
end;

class function TJSONBaseObject.Parse(const Bytes: TBytes; const ByteIndex: Integer; ByteCount: Integer): TJSONBaseObject;
var
  LLength: Integer;
begin
  LLength := Length(Bytes);

  if ByteCount = -1 then
    ByteCount := LLength - ByteIndex;

  if (ByteCount <= 0) or (ByteIndex + ByteCount > LLength) then
    Result := nil
  else
    Result := ParseUtf8Bytes(PByte(@Bytes[ByteIndex]), ByteCount)
end;

class function TJSONBaseObject.Parse(const S: UnicodeString): TJSONBaseObject;
begin
  Result := Parse(PWideChar(Pointer(S)), Length(S));
end;

class function TJSONBaseObject.Parse(S: PWideChar; Len: Integer): TJSONBaseObject;
var
  P: PWideChar;
  LLength: Integer;
begin
  if (S = nil) or (Len = 0) then
    Result := nil
  else
  begin
    if Len < 0 then
      Len := StrLen(S);

    P := S;
    LLength := Len;

    while (LLength > 0) and (P^ <= #32) do
    begin
      Inc(P);
      Dec(LLength);
    end;

    if LLength = 0 then
      Result := nil
    else
    begin
      if (LLength > 0) and (P^ = '[') then
        Result := TJSONArray.Create
      else
        Result := TJSONObject.Create;

      try
        Result.FromJSON(S, Len);
      except
        Result.Free;
        raise;
      end;
    end;
  end;
end;

procedure TJSONBaseObject.FromJSON(const S: UnicodeString);
begin
  FromJSON(PWideChar(S), Length(S));
end;

procedure TJSONBaseObject.FromJSON(S: PWideChar; Len: Integer);
var
  LReader: TJSONReader;
begin
  if Len < 0 then
    Len := StrLen(S);

  LReader := TJSONStringReader.Create(S, Len);
  try
    LReader.Parse(Self);
  finally
    LReader.Free;
  end;
end;

class function TJSONBaseObject.ParseFromStream(const Stream: TStream): TJSONBaseObject;
var
  LStreamInfo: TStreamInfo;
  LEncoding: TEncoding;
begin
  LEncoding := nil;
  GetStreamBytes(Stream, LEncoding, True, LStreamInfo);
  try
    Result := ParseUtf8Bytes(LStreamInfo.Buffer, LStreamInfo.Size)
  finally
    FreeMem(LStreamInfo.AllocationBase);
  end;
end;

procedure TJSONBaseObject.FromUtf8JSON(const S: PByte; Len: Integer);
var
  LReader: TJSONReader;
begin
  if Len < 0 then
    Len := System.AnsiStrings.StrLen(PAnsiChar(S));

  LReader := TJSONUTF8Reader.Create(S, Len);
  try
    LReader.Parse(Self);
  finally
    LReader.Free;
  end;
end;

class procedure TJSONBaseObject.GetStreamBytes(const Stream: TStream; var Encoding: TEncoding; const Utf8WithoutBOM: Boolean;
  var StreamInfo: TStreamInfo);
var
  LPosition: Int64;
  LSize: NativeInt;
  LBytes: PByte;
  LBufStart: Integer;
begin
  LBufStart := 0;
  LPosition := Stream.Position;
  LSize := Stream.Size - LPosition;

  StreamInfo.Buffer := nil;
  StreamInfo.Size := 0;
  StreamInfo.AllocationBase := nil;
  try
    LBytes := nil;

    if LSize > 0 then
    begin
      if Stream is TCustomMemoryStream then
      begin
        LBytes := TCustomMemoryStream(Stream).Memory;
        TCustomMemoryStream(Stream).Position := LPosition + LSize;
        Inc(LBytes, LPosition);
      end
      else
      begin
        GetMem(StreamInfo.AllocationBase, LSize);
        LBytes := StreamInfo.AllocationBase;
        Stream.ReadBuffer(StreamInfo.AllocationBase^, LSize);
      end;
    end;

    if Encoding = nil then
    begin
      if Utf8WithoutBOM then
        Encoding := TEncoding.UTF8
      else
        Encoding := TEncoding.Default;

      if LSize >= 2 then
      begin
        if (LBytes[0] = $EF) and (LBytes[1] = $BB) then
        begin
          if LBytes[2] = $BF then
          begin
            Encoding := TEncoding.UTF8;
            LBufStart := 3;
          end;
        end
        else
        if (LBytes[0] = $FF) and (LBytes[1] = $FE) then
        begin
          if (LBytes[2] = 0) and (LBytes[3] = 0) then
            raise EJSONException.CreateRes(@STextEditorUnsupportedFileEncoding)
          else
          begin
            Encoding := TEncoding.Unicode;
            LBufStart := 2;
          end;
        end
        else
        if (LBytes[0] = $FE) and (LBytes[1] = $FF) then
        begin
          Encoding := TEncoding.BigEndianUnicode;
          LBufStart := 2;
        end
        else
        if (LBytes[0] = 0) and (LBytes[1] = 0) and (LSize >= 4) then
        begin
          if (LBytes[2] = $FE) and (LBytes[3] = $FF) then
            raise EJSONException.CreateRes(@STextEditorUnsupportedFileEncoding);
        end;
      end;
    end;

    Inc(LBytes, LBufStart);
    StreamInfo.Buffer := LBytes;
    StreamInfo.Size := LSize - LBufStart;
  except
    FreeMem(StreamInfo.AllocationBase);
    raise;
  end;
end;

procedure TJSONBaseObject.LoadFromStream(const Stream: TStream);
var
  LStreamInfo: TStreamInfo;
  LEncoding: TEncoding;
begin
  LEncoding := nil;
  GetStreamBytes(Stream, LEncoding, True, LStreamInfo);
  try
    FromUtf8JSON(LStreamInfo.Buffer, LStreamInfo.Size)
  finally
    FreeMem(LStreamInfo.AllocationBase);
  end;
end;

function TJSONBaseObject.ToJSON(const ACompact: Boolean): string;
var
  LJSONOutputWriter: TJSONOutputWriter;
begin
  LJSONOutputWriter.Init(ACompact, nil, nil, nil);
  try
    InternToJSON(LJSONOutputWriter);
  finally
    Result := LJSONOutputWriter.Done;
  end;
end;

function TJSONBaseObject.ToString: string;
begin
  Result := ToJSON;
end;

class procedure TJSONBaseObject.InternInitAndAssignItem(const Dest, Source: PJSONDatAValue);
begin
  Dest.FDataType := Source.FDataType;

  case Source.DataType of
    jdtString:
      begin
        Dest.FValue.ValuePChar := nil;
        string(Dest.FValue.ValueString) := string(Source.FValue.ValueString);
      end;
    jdtBool:
      Dest.FValue.ValueBoolean := Source.FValue.ValueBoolean;
    jdtArray:
      if Source.FValue.ValueArray <> nil then
      begin
        TJSONArray(Dest.FValue.ValueArray) := TJSONArray.Create;
        TJSONArray(Dest.FValue.ValueArray).Assign(TJSONArray(Source.FValue.ValueArray));
      end
      else
        Dest.FValue.ValueArray := nil;
    jdtObject:
      if Source.FValue.ValueObject <> nil then
      begin
        TJSONObject(Dest.FValue.ValueObject) := TJSONObject.Create;
        TJSONObject(Dest.FValue.ValueObject).Assign(TJSONObject(Source.FValue.ValueObject));
      end
      else
        Dest.FValue.ValueObject := nil;
  end;
end;

procedure TJSONDataValue.TypeCastError(const AExpectedType: TJSONDataType);
begin
  raise EJSONCastException.CreateResFmt(@STextEditorTypeCastError, [TJSONBaseObject.DataTypeNames[FDataType],
    TJSONBaseObject.DataTypeNames[AExpectedType]]);
end;

{ TJSONArrayEnumerator }

constructor TJSONArrayEnumerator.Create(const AArray: TJSONArray);
begin
  inherited Create;

  FIndex := -1;
  FArray := AArray;
end;

function TJSONArrayEnumerator.GetCurrent: TJSONDataValueHelper;
begin
  Result := FArray[FIndex];
end;

function TJSONArrayEnumerator.MoveNext: Boolean;
begin
  Result := FIndex < FArray.Count - 1;

  if Result then
    Inc(FIndex);
end;

{ TJSONArray }

destructor TJSONArray.Destroy; //FI:W504 FixInsight ignore - Missing INHERITED call in destructor
begin
  Clear;
  FreeMem(FItems);
  FItems := nil;
  // inherited Destroy;
end;

procedure TJSONArray.Clear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FCount - 1 do
    FItems[LIndex].Clear;

  FCount := 0;
end;

procedure TJSONArray.Delete(const AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    ListError(@SListIndexError, AIndex);

  FItems[AIndex].Clear;
  Dec(FCount);

  if AIndex < FCount then
    Move(FItems[AIndex + 1], FItems[AIndex], (FCount - AIndex) * SizeOf(TJSONDataValue));
end;

function TJSONArray.AddItem: PJSONDataValue;
begin
  if FCount = FCapacity then
    Grow;

  Result := @FItems[FCount];
  Result.FDataType := jdtNone;
  Result.FValue.ValuePChar := nil;

  Inc(FCount);
end;

function TJSONArray.InsertItem(const AIndex: Integer): PJSONDataValue;
begin
  if Cardinal(AIndex) > Cardinal(FCount) then
    RaiseListError(AIndex);

  if FCount = FCapacity then
    Grow;

  Result := @FItems[AIndex];

  if AIndex < FCount then
    Move(Result^, FItems[AIndex + 1], (FCount - AIndex) * SizeOf(TJSONDataValue));

  Result.FDataType := jdtNone;
  Result.FValue.ValuePChar := nil;

  Inc(FCount);
end;

procedure TJSONArray.Grow;
var
  LCapacity, LDelta: Integer;
begin
  LCapacity := FCapacity;

  if LCapacity > 64 then
    LDelta := LCapacity div 4
  else
  if LCapacity > 8 then
    LDelta := 16
  else
    LDelta := 4;

  FCapacity := LCapacity + LDelta;

  InternApplyCapacity;
end;

procedure TJSONArray.InternApplyCapacity;
begin
  ReallocMem(Pointer(FItems), FCapacity * SizeOf(TJSONDataValue));
end;

procedure TJSONArray.SetCapacity(const AValue: Integer);
var
  LIndex: Integer;
begin
  if AValue <> FCapacity then
  begin
    if FCapacity < FCount then
    begin
      for LIndex := FCapacity to FCount - 1 do
        FItems[LIndex].Clear;

      FCount := FCapacity;
    end;

    FCapacity := AValue;

    InternApplyCapacity;
  end;
end;

function TJSONArray.GetValueArray(const AIndex: Integer): TJSONArray;
begin
  Result := FItems[AIndex].ArrayValue;
end;

function TJSONArray.GetValueBoolean(const AIndex: Integer): Boolean;
begin
  Result := FItems[AIndex].BoolValue;
end;

function TJSONArray.GetValueObject(const AIndex: Integer): TJSONObject;
begin
  Result := FItems[AIndex].ObjectValue;
end;

function TJSONArray.GetItem(const AIndex: Integer): PJSONDataValue;
begin
  Result := @FItems[AIndex];
end;

function TJSONArray.GetValueString(const AIndex: Integer): string;
begin
  Result := FItems[AIndex].Value;
end;

procedure TJSONArray.Add(const AValue: TJSONObject);
var
  LData: PJSONDataValue;
begin
  LData := AddItem;
  LData.ObjectValue := AValue;
end;

procedure TJSONArray.Add(const AValue: TJSONArray);
var
  LData: PJSONDataValue;
begin
  LData := AddItem;
  LData.ArrayValue := AValue;
end;

procedure TJSONArray.Add(const AValue: Boolean);
var
  LData: PJSONDataValue;
begin
  LData := AddItem;
  LData.BoolValue := AValue;
end;

procedure TJSONArray.Add(const AValue: string);
var
  LData: PJSONDataValue;
begin
  LData := AddItem;
  LData.Value := AValue;
end;

function TJSONArray.AddArray: TJSONArray;
begin
  Result := TJSONArray.Create;
  Add(Result);
end;

function TJSONArray.AddObject: TJSONObject;
begin
  Result := TJSONObject.Create;
  Add(Result);
end;

procedure TJSONArray.AddObject(const AValue: TJSONObject);
begin
  Add(AValue);
end;

procedure TJSONArray.Insert(const AIndex: Integer; const AValue: TJSONObject);
var
  LData: PJSONDataValue;
begin
  LData := InsertItem(AIndex);
  LData.ObjectValue := AValue;
end;

procedure TJSONArray.Insert(const AIndex: Integer; const AValue: TJSONArray);
var
  LData: PJSONDataValue;
begin
  LData := InsertItem(AIndex);
  LData.ArrayValue := AValue;
end;

procedure TJSONArray.Insert(const AIndex: Integer; const AValue: Boolean);
var
  LData: PJSONDataValue;
begin
  LData := InsertItem(AIndex);
  LData.BoolValue := AValue;
end;

procedure TJSONArray.Insert(const AIndex: Integer; const AValue: string);
var
  LData: PJSONDataValue;
begin
  LData := InsertItem(AIndex);
  LData.Value := AValue;
end;

function TJSONArray.InsertArray(const AIndex: Integer): TJSONArray;
begin
  Result := TJSONArray.Create;
  try
    Insert(AIndex, Result);
  except
    Result.Free;
    raise;
  end;
end;

function TJSONArray.InsertObject(const AIndex: Integer): TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Insert(AIndex, Result);
  except
    Result.Free;
    raise;
  end;
end;

procedure TJSONArray.InsertObject(const AIndex: Integer; const AValue: TJSONObject);
begin
  Insert(AIndex, AValue);
end;

function TJSONArray.GetEnumerator: TJSONArrayEnumerator;
begin
  Result := TJSONArrayEnumerator.Create(Self);
end;

procedure TJSONArray.SetValueString(const AIndex: Integer; const AValue: string);
begin
  FItems[AIndex].Value := AValue;
end;

procedure TJSONArray.SetValueBoolean(const AIndex: Integer; const AValue: Boolean);
begin
  FItems[AIndex].BoolValue := AValue;
end;

procedure TJSONArray.SetValueArray(const AIndex: Integer; const AValue: TJSONArray);
begin
  FItems[AIndex].ArrayValue := AValue;
end;

procedure TJSONArray.SetValueObject(const AIndex: Integer; const AValue: TJSONObject);
begin
  FItems[AIndex].ObjectValue := AValue;
end;

function TJSONArray.GetType(const AIndex: Integer): TJSONDataType;
begin
  Result := FItems[AIndex].DataType;
end;

function TJSONArray.GetValue(const AIndex: Integer): TJSONDataValueHelper;
begin
  Result.FData.FIntern := @FItems[AIndex];
  Result.FData.FDataType := jdtNone;
end;

procedure TJSONArray.SetValue(const AIndex: Integer; const AValue: TJSONDataValueHelper);
begin
  TJSONDataValueHelper.SetInternValue(@FItems[AIndex], AValue);
end;

procedure TJSONArray.InternToJSON(var Writer: TJSONOutputWriter);
var
  LIndex: Integer;
begin
  if FCount = 0 then
    Writer.AppendValue('[]')
  else
  begin
    Writer.Indent('[');
    FItems[0].InternToJSON(Writer);

    for LIndex := 1 to FCount - 1 do
    begin
      Writer.AppendSeparator(',');
      FItems[LIndex].InternToJSON(Writer);
    end;

    Writer.Unindent(']');
  end;
end;

procedure TJSONArray.Assign(const ASource: TJSONArray);
var
  LIndex: Integer;
begin
  Clear;

  if ASource <> nil then
  begin
    if FCapacity < ASource.Count then
    begin
      FCapacity := ASource.Count;
      ReallocMem(FItems, ASource.Count * SizeOf(TJSONDataValue));
    end;

    FCount := ASource.Count;

    for LIndex := 0 to ASource.Count - 1 do
      InternInitAndAssignItem(@FItems[LIndex], @ASource.FItems[LIndex]);
  end
  else
  begin
    FreeMem(FItems);
    FCapacity := 0;
  end;
end;

class procedure TJSONArray.RaiseListError(const AIndex: Integer);
begin
  ListError(@SListIndexError, AIndex);
end;

procedure TJSONArray.SetCount(const AValue: Integer);
var
  LIndex: Integer;
begin
  if AValue <> FCount then
  begin
    SetCapacity(AValue);

    for LIndex := FCount to AValue - 1 do
    begin
      FItems[LIndex].FDataType := jdtObject;
      FItems[LIndex].FValue.ValuePChar := nil;
    end;

    FCount := AValue;
  end;
end;

{ TJSONObjectEnumerator }

constructor TJSONObjectEnumerator.Create(const AObject: TJSONObject);
begin
  inherited Create;

  FIndex := -1;
  FObject := AObject;
end;

function TJSONObjectEnumerator.MoveNext: Boolean;
begin
  Result := FIndex < FObject.Count - 1;

  if Result then
    Inc(FIndex);
end;

function TJSONObjectEnumerator.GetCurrent: TJSONNameValuePair;
begin
  Result.Name := FObject.Names[FIndex];
  Result.Value.FData.FIntern := FObject.Items[FIndex];
  Result.Value.FData.FDataType := jdtNone;
end;

{ TJSONObject }

destructor TJSONObject.Destroy; //FI:W504 FixInsight ignore - Missing INHERITED call in destructor
begin
  Clear;
  FreeMem(FItems);
  FreeMem(FNames);

  // inherited Destroy;
end;

procedure TJSONObject.Grow;
var
  LCapacity, LDelta: Integer;
begin
  LCapacity := FCapacity;

  if LCapacity > 64 then
    LDelta := LCapacity div 4
  else
  if LCapacity > 8 then
    LDelta := 16
  else
    LDelta := 4;

  FCapacity := LCapacity + LDelta;

  InternApplyCapacity;
end;

procedure TJSONObject.InternApplyCapacity;
begin
  ReallocMem(Pointer(FItems), FCapacity * SizeOf(FItems[0]));
  ReallocMem(Pointer(FNames), FCapacity * SizeOf(FNames[0]));
end;

procedure TJSONObject.SetCapacity(const AValue: Integer);
var
  LIndex: Integer;
begin
  if AValue <> FCapacity then
  begin
    if FCapacity < FCount then
    begin
      for LIndex := FCapacity to FCount - 1 do
      begin
        FNames[LIndex] := '';
        FItems[LIndex].Clear;
      end;

      FCount := FCapacity;
    end;

    FCapacity := AValue;
    InternApplyCapacity;
  end;
end;

procedure TJSONObject.Clear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FCount - 1 do
  begin
    FNames[LIndex] := '';
    FItems[LIndex].Clear;
  end;

  FCount := 0;
end;

procedure TJSONObject.Remove(const AName: string);
var
  LIndex: Integer;
begin
  LIndex := IndexOf(AName);

  if LIndex <> -1 then
    Delete(LIndex);
end;

function TJSONObject.Extract(const AName: string): TJSONBaseObject;
var
  LIndex: Integer;
begin
  LIndex := IndexOf(AName);

  if LIndex = -1 then
    Result := nil
  else
  begin
    if FItems[LIndex].FDataType in [jdtNone, jdtArray, jdtObject] then
    begin
      Result := TJSONBaseObject(FItems[LIndex].FValue.ValueObject);
      TJSONBaseObject(FItems[LIndex].FValue.ValueObject) := nil;
    end
    else
      Result := nil;

    Delete(LIndex);
  end
end;

function TJSONObject.ExtractArray(const AName: string): TJSONArray;
begin
  Result := Extract(AName) as TJSONArray;
end;

function TJSONObject.ExtractObject(const AName: string): TJSONObject;
begin
  Result := Extract(AName) as TJSONObject;
end;

function TJSONObject.GetEnumerator: TJSONObjectEnumerator;
begin
  Result := TJSONObjectEnumerator.Create(Self);
end;

function TJSONObject.AddItem(const AName: string): PJSONDataValue;
var
  LPName: PString;
begin
  if FCount = FCapacity then
    Grow;

  Result := @FItems[FCount];
  LPName := @FNames[FCount];
  Inc(FCount);
  Pointer(LPName^) := nil;
  LPName^ := AName;

  Result.FValue.ValuePChar := nil;
  Result.FDataType := jdtNone;
end;

function TJSONObject.InternAddItem(var AName: string): PJSONDataValue;
var
  LPName: PString;
begin
  if FCount = FCapacity then
    Grow;

  Result := @FItems[FCount];
  LPName := @FNames[FCount];

  Inc(FCount);

  Pointer(LPName^) := Pointer(AName);
  Pointer(AName) := nil;

  Result.FValue.ValuePChar := nil;
  Result.FDataType := jdtNone;
end;

function TJSONObject.GetValueArray(const AName: string): TJSONArray;
var
  LItem: PJSONDataValue;
begin
  if FindItem(AName, LItem) then
    Result := LItem.ArrayValue
  else
  begin
    Result := TJSONArray.Create;
    AddItem(AName).ArrayValue := Result;
  end;
end;

function TJSONObject.GetValueBoolean(const AName: string): Boolean;
var
  LItem: PJSONDataValue;
begin
  if FindItem(AName, LItem) then
    Result := LItem.BoolValue
  else
    Result := False;
end;

function TJSONObject.GetValueObject(const AName: string): TJSONObject;
var
  LItem: PJSONDataValue;
begin
  if FindItem(AName, LItem) then
    Result := LItem.ObjectValue
  else
  begin
    Result := TJSONObject.Create;
    AddItem(AName).ObjectValue := Result;
  end;
end;

function TJSONObject.GetValueString(const AName: string): string;
var
  LItem: PJSONDataValue;
begin
  if FindItem(AName, LItem) then
    Result := LItem.Value
  else
    Result := '';
end;

procedure TJSONObject.SetValueArray(const AName: string; const AValue: TJSONArray);
begin
  RequireItem(AName).ArrayValue := AValue;
end;

procedure TJSONObject.SetValueBoolean(const AName: string; const AValue: Boolean);
begin
  RequireItem(AName).BoolValue := AValue;
end;

procedure TJSONObject.SetValueObject(const AName: string; const AValue: TJSONObject);
begin
  RequireItem(AName).ObjectValue := AValue;
end;

procedure TJSONObject.SetValueString(const AName, AValue: string);
begin
  RequireItem(AName).Value := AValue;
end;

function TJSONObject.GetType(const AName: string): TJSONDataType;
var
  LItem: PJSONDataValue;
begin
  if FindItem(AName, LItem) then
    Result := LItem.DataType
  else
    Result := jdtNone;
end;

function TJSONObject.Contains(const AName: string): Boolean;
begin
  Result := IndexOf(AName) <> -1;
end;

function TJSONObject.IndexOfPChar(const S: PChar; const Len: Integer): Integer;
var
  LPArray: PJSONStringArray;
begin
  LPArray := FNames;

  if Len = 0 then
  begin
    for Result := 0 to FCount - 1 do
    if LPArray[Result] = '' then
      Exit
  end
  else
  for Result := 0 to FCount - 1 do
  if (Length(LPArray[Result]) = Len) and CompareMem(S, Pointer(LPArray[Result]), Len * SizeOf(Char)) then
    Exit;

  Result := -1;
end;

function TJSONObject.IndexOf(const AName: string): Integer;
var
  LPArray: PJSONStringArray;
begin
  LPArray := FNames;

  for Result := 0 to FCount - 1 do
  if AName = LPArray[Result] then
    Exit;

  Result := -1;
end;

function TJSONObject.FindItem(const AName: string; var Item: PJSONDataValue): Boolean;
var
  LIndex: Integer;
begin
  LIndex := IndexOf(AName);

  Result := LIndex <> -1;

  if Result then
    Item := @FItems[LIndex]
  else
    Item := nil;
end;

function TJSONObject.RequireItem(const AName: string): PJSONDataValue;
begin
  if not FindItem(AName, Result) then
    Result := AddItem(AName);
end;

procedure TJSONObject.InternToJSON(var Writer: TJSONOutputWriter);
var
  LIndex: Integer;
begin
  if Count = 0 then
    Writer.AppendValue('{}')
  else
  begin
    Writer.Indent('{');
    TJSONBaseObject.StrToJSONStr(Writer.AppendIntro, FNames[0]);
    FItems[0].InternToJSON(Writer);

    for LIndex := 1 to FCount - 1 do
    begin
      Writer.AppendSeparator(',');
      TJSONBaseObject.StrToJSONStr(Writer.AppendIntro, FNames[LIndex]);
      FItems[LIndex].InternToJSON(Writer);
    end;

    Writer.Unindent('}');
  end;
end;

function TJSONObject.GetName(const AIndex: Integer): string;
begin
  Result := FNames[AIndex];
end;

function TJSONObject.GetItem(const AIndex: Integer): PJSONDataValue;
begin
  Result := @FItems[AIndex];
end;

procedure TJSONObject.Delete(const AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    ListError(@SListIndexError, AIndex);

  FNames[AIndex] := '';
  FItems[AIndex].Clear;
  Dec(FCount);

  if AIndex < FCount then
  begin
    Move(FItems[AIndex + 1], FItems[AIndex], (FCount - AIndex) * SizeOf(FItems[0]));
    Move(FNames[AIndex + 1], FNames[AIndex], (FCount - AIndex) * SizeOf(FNames[0]));
  end;
end;

function TJSONObject.GetValue(const AName: string): TJSONDataValueHelper;
begin
  if not FindItem(AName, Result.FData.FIntern) then
  begin
    Result.FData.FIntern := nil;
    Result.FData.FNameResolver := Self;
    Result.FData.FName := AName;
  end;

  Result.FData.FDataType := jdtNone;
end;

procedure TJSONObject.SetValue(const AName: string; const AValue: TJSONDataValueHelper);
var
  LPData: PJSONDataValue;
begin
  LPData := RequireItem(AName);
  TJSONDataValueHelper.SetInternValue(LPData, AValue);
end;

procedure TJSONObject.InternAdd(var AName: string; const AValue: TJSONArray);
var
  LPData: PJSONDataValue;
begin
  LPData := InternAddItem(AName);
  LPData.InternSetValueArrayValue(AValue);
end;

procedure TJSONObject.InternAdd(var AName: string; const AValue: TJSONObject);
var
  LPData: PJSONDataValue;
begin
  LPData := InternAddItem(AName);
  LPData.InternSetValueObjectValue(AValue);
end;

procedure TJSONObject.InternAdd(var AName: string; const AValue: Boolean);
var
  LPData: PJSONDataValue;
begin
  LPData := InternAddItem(AName);
  LPData.BoolValue := AValue;
end;

function TJSONObject.InternAddArray(var AName: string): TJSONArray;
begin
  Result := TJSONArray.Create;
  InternAdd(AName, Result);
end;

function TJSONObject.InternAddObject(var AName: string): TJSONObject;
begin
  Result := TJSONObject.Create;
  InternAdd(AName, Result);
end;

procedure TJSONObject.Assign(const ASource: TJSONObject);
var
  LIndex: Integer;
begin
  Clear;

  if ASource <> nil then
  begin
    FCapacity := ASource.Count;

    InternApplyCapacity;

    FCount := ASource.Count;

    for LIndex := 0 to ASource.Count - 1 do
    begin
      Pointer(FNames[LIndex]) := nil;
      FNames[LIndex] := ASource.FNames[LIndex];
      InternInitAndAssignItem(@FItems[LIndex], @ASource.FItems[LIndex]);
    end;
  end
  else
  begin
    FreeMem(FItems);
    FreeMem(FNames);

    FCapacity := 0;
  end;
end;

procedure TJSONObject.PathError(const P, EndP: PChar);
var
  S: string;
begin
  System.SetString(S, P, EndP - P);
  raise EJSONPathException.CreateResFmt(@STextEditorInvalidJSONPath, [S]);
end;

procedure TJSONObject.PathNullError(const P, EndP: PChar);
var
  S: string;
begin
  System.SetString(S, P, EndP - P);
  raise EJSONPathException.CreateResFmt(@STextEditorJSONPathContainsNullValue, [S]);
end;

procedure TJSONObject.PathIndexError(const P, EndP: PChar; const Count: Integer);
var
  S: string;
begin
  System.SetString(S, P, EndP - P);
  raise EJSONPathException.CreateResFmt(@STextEditorJSONPathIndexError, [Count, S]);
end;

function TJSONObject.GetPath(const ANamePath: string): TJSONDataValueHelper;
var
  LPFirstChar, LPChar, LPEndChar, LPLastEndChar: PChar;
  LChar: Char;
  LIndex: Integer;
  LObject: TJSONObject;
  LArray: TJSONArray;
  LDataValue: PJSONDataValue;
  LString: string;
begin
  LPChar := PChar(ANamePath);

  if LPChar^ = #0 then
  begin
    Result := Self;
    Exit;
  end;

  Result.FData.FIntern := nil;
  Result.FData.FDataType := jdtNone;

  LObject := Self;
  LDataValue := nil;
  LPLastEndChar := nil;

  while True do
  begin
    LPFirstChar := LPChar;

    LChar := LPChar^;

    while True do
    case LChar of
      #0, '[', '.':
        Break;
    else
      Inc(LPChar);
      LChar := LPChar^;
    end;

    LPEndChar := LPChar;

    if LPFirstChar = LPEndChar then
      PathError(PChar(Pointer(ANamePath)), LPChar + 1);

    Inc(LPChar);

    case LChar of
      #0:
        begin
          if LObject <> nil then
          begin
            LIndex := LObject.IndexOfPChar(LPFirstChar, LPEndChar - LPFirstChar);

            if LIndex <> -1 then
              Result.FData.FIntern := @LObject.FItems[LIndex]
            else
            begin
              Result.FData.FNameResolver := LObject;
              System.SetString(Result.FData.FName, LPFirstChar, LPEndChar - LPFirstChar);
            end;
          end
          else
            Result.FData.FIntern := LDataValue;

          Break;
        end;
      '.':
        begin
          if LObject = nil then
            PathNullError(PChar(Pointer(ANamePath)), LPLastEndChar);

          LIndex := LObject.IndexOfPChar(LPFirstChar, LPEndChar - LPFirstChar);

          if LIndex <> -1 then
            LObject := LObject.FItems[LIndex].ObjectValue
          else
          begin
            System.SetString(LString, LPFirstChar, LPEndChar - LPFirstChar);
            LObject := LObject.InternAddObject(LString);
          end;
        end;
      '[':
        begin
          if LObject = nil then
            PathNullError(PChar(Pointer(ANamePath)), LPLastEndChar);

          LIndex := LObject.IndexOfPChar(LPFirstChar, LPEndChar - LPFirstChar);

          if LIndex <> -1 then
          begin
            LArray := LObject.FItems[LIndex].ArrayValue;

            if LArray = nil then
            begin
              LArray := TJSONArray.Create;
              LObject.FItems[LIndex].ArrayValue := LArray;
            end;
          end
          else
          begin
            System.SetString(LString, LPFirstChar, LPEndChar - LPFirstChar);
            LArray := LObject.InternAddArray(LString);
          end;

          LChar := LPChar^;
          LIndex := 0;

          while LChar in ['0' .. '9'] do
          begin
            LIndex := LIndex * 10 + (Word(LChar) - Ord('0'));
            Inc(LPChar);
            LChar := LPChar^;
          end;

          if LPChar^ <> ']' then
            PathError(PChar(Pointer(ANamePath)), LPChar + 1);

          Inc(LPChar);

          if LIndex >= LArray.Count then
            PathIndexError(PChar(Pointer(ANamePath)), LPChar, LArray.Count);

          LDataValue := @LArray.FItems[LIndex];

          if LPChar^ = '.' then
          begin
            Inc(LPChar);
            LObject := LDataValue.ObjectValue;
            LDataValue := nil;
          end
          else
          if LPChar^ = #0 then
          begin
            Result.FData.FIntern := LDataValue;
            Break;
          end;
        end;
    end;

    LPLastEndChar := LPEndChar;
  end;
end;

procedure TJSONObject.SetPath(const ANamePath: string; const AValue: TJSONDataValueHelper);
var
  LPathValue: TJSONDataValueHelper;
begin
  LPathValue := Path[ANamePath];
  LPathValue.ResolveName;
  TJSONDataValueHelper.SetInternValue(LPathValue.FData.FIntern, AValue);
end;

{ TStringIntern }

procedure TStringIntern.Init;
begin
  FCount := 0;
  FCapacity := 17;
  GetMem(FStrings, FCapacity * SizeOf(FStrings[0]));
  GetMem(FBuckets, FCapacity * SizeOf(FBuckets[0]));
  FillChar(FBuckets[0], FCapacity * SizeOf(FBuckets[0]), $FF);
end;

procedure TStringIntern.Done;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FCount - 1 do
    FStrings[LIndex].Name := '';

  FreeMem(FStrings);
  FreeMem(FBuckets);
end;

procedure TStringIntern.Intern(var S: string; var PropName: string);
var
  LIndex: Integer;
  LHash: Integer;
  LSource: Pointer;
begin
  if PropName <> '' then
    PropName := '';

  if S <> '' then
  begin
    LHash := GetHash(S);
    LIndex := Find(LHash, S);

    if LIndex = -1 then
     begin
      Pointer(PropName) := Pointer(S);
      Pointer(S) := nil;
      InternAdd(LHash, PropName);
    end
    else
    begin
      LSource := Pointer(FStrings[LIndex].Name);

      if LSource <> nil then
      begin
        Pointer(PropName) := LSource;
        Inc(PInteger(@PByte(LSource)[-8])^);
      end;

      S := '';
    end
  end;
end;

class function TStringIntern.GetHash(const AName: string): Integer;
var
  LPChar: PChar;
  LChar: Word;
begin
  Result := 0;

  LPChar := PChar(Pointer(AName));

  if LPChar <> nil then
  begin
    Result := PInteger(@PByte(AName)[-4])^;

    while True do
    begin
      LChar := Word(LPChar[0]);

      if LChar = 0 then
        Break;

      Result := Result + LChar;

      LChar := Word(LPChar[1]);

      if LChar = 0 then
        Break;

      Result := Result + LChar;

      LChar := Word(LPChar[2]);

      if LChar = 0 then
        Break;

      Result := Result + LChar;

      LChar := Word(LPChar[3]);

      if LChar = 0 then
        Break;

      Result := Result + LChar;
      Result := (Result shl 6) or ((Result shr 26) and $3F);

      Inc(LPChar, 4);
    end;
  end;
end;

procedure TStringIntern.InternAdd(const AHash: Integer; const S: string);
var
  LIndex: Integer;
  LPBucket: PInteger;
begin
  if FCount = FCapacity then
    Grow;

  LIndex := FCount;
  Inc(FCount);

  LPBucket := @FBuckets[(AHash and $7FFFFFFF) mod FCapacity];

  with FStrings[LIndex] do
  begin
    Next := LPBucket^;
    Hash := AHash;
    Pointer(Name) := Pointer(S);
    Inc(PInteger(@PByte(Name)[-8])^);
  end;

  LPBucket^ := LIndex;
end;

procedure TStringIntern.Grow;
var
  LStringIndex: Integer;
  LIndex: Integer;
  Len: Integer;
begin
  Len := FCapacity;

  case Len of
    17:
      Len := 37;
    37:
      Len := 59;
    59:
      Len := 83;
    83:
      Len := 127;
    127:
      Len := 353;
    353:
      Len := 739;
    739:
      Len := 1597;
    1597:
      Len := 2221;
  else
    Len := Len * 2 + 1;
  end;

  FCapacity := Len;

  ReallocMem(FStrings, Len * SizeOf(FStrings[0]));
  ReallocMem(FBuckets, Len * SizeOf(FBuckets[0]));
  FillChar(FBuckets[0], Len * SizeOf(FBuckets[0]), $FF);

  for LStringIndex := 0 to FCount - 1 do
  begin
    LIndex := (FStrings[LStringIndex].Hash and $7FFFFFFF) mod Len;
    FStrings[LStringIndex].Next := FBuckets[LIndex];
    FBuckets[LIndex] := LStringIndex;
  end;
end;

function TStringIntern.Find(const Hash: Integer; const S: string): Integer;
var
  LStrings: PJSONStringEntryArray;
begin
  Result := -1;

  if FCount <> 0 then
  begin
    Result := FBuckets[(Hash and $7FFFFFFF) mod FCapacity];

    if Result <> -1 then
    begin
      LStrings := FStrings;

      while True do
      begin
        if (LStrings[Result].Hash = Hash) and (LStrings[Result].Name = S) then
          Break;

        Result := LStrings[Result].Next;

        if Result = -1 then
          Break;
      end;
    end;
  end;
end;

{ TJSONOutputWriter }

procedure TJSONOutputWriter.Init(const ACompact: Boolean; const AStream: TStream; const AEncoding: TEncoding; const ALines: TStrings);
begin
  FCompact := ACompact;
  FStream := AStream;
  FEncoding := AEncoding;

  if Assigned(ALines) then
  begin
    FCompact := False;
    FLines := ALines;
  end
  else
  begin
    FStreamEncodingBuffer := nil;
    FStreamEncodingBufferLen := 0;
    FLines := nil;
    FStringBuffer.Init;
  end;

  if not ACompact then
  begin
    FLastLine.Init;

    FIndent := 0;
    FLastType := ltInitial;

    FIndents := AllocMem(5 * SizeOf(string));
    FIndentsLen := 5;
    FIndents[1] := #9;
    FIndents[2] := FIndents[1] + #9;
    FIndents[3] := FIndents[2] + #9;
    FIndents[4] := FIndents[3] + #9;
  end;
end;

procedure TJSONOutputWriter.FreeIndents;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FIndentsLen - 1 do
    FIndents[LIndex] := '';

  FreeMem(FIndents);
end;

function TJSONOutputWriter.Done: string;
begin
  Result := '';

  if not FCompact then
  begin
    FlushLastLine;
    FreeIndents;
    FLastLine.Done;
  end;

  if FLines = nil then
    FStringBuffer.DoneConvertToString(Result);
end;

procedure TJSONOutputWriter.FlushLastLine;
var
  LString: Pointer;
begin
  if FLastLine.DataLength > 0 then
  begin
    if FLines = nil then
    begin
      FLastLine.FlushToStringBuffer(FStringBuffer);
      FStringBuffer.Append(sLineBreak);
    end
    else
    begin
      LString := nil;
      try
        FLastLine.FlushToString(string(LString));
        FLines.Add(string(LString));
      finally
        string(LString) := '';
      end;
    end
  end;
end;

procedure TJSONOutputWriter.StreamFlush;
var
  LSize: NativeInt;
begin
  if FStringBuffer.DataLength > 0 then
  begin
    if FEncoding = TEncoding.Unicode then
    begin
      FStream.Write(FStringBuffer.Data[0], FStringBuffer.DataLength);
      FStringBuffer.FDataLength := 0;
    end
    else
    if FStream is TMemoryStream then
      FStringBuffer.FlushToMemoryStream(TMemoryStream(FStream), FEncoding)
    else
    begin
      LSize := FStringBuffer.FlushToBytes(FStreamEncodingBuffer, FStreamEncodingBufferLen, FEncoding);

      if LSize > 0 then
        FStream.Write(FStreamEncodingBuffer[0], LSize);
    end;
  end;
end;

procedure TJSONOutputWriter.StreamFlushPossible;
const
  MinFlushBufferLen = 1024 * 1024;
begin
  if (FStream <> nil) and (FStringBuffer.DataLength >= MinFlushBufferLen) then
    StreamFlush;
end;

procedure TJSONOutputWriter.ExpandIndents;
begin
  Inc(FIndentsLen);
  ReallocMem(Pointer(FIndents), FIndentsLen * SizeOf(string));
  Pointer(FIndents[FIndent]) := nil;
  FIndents[FIndent] := FIndents[FIndent - 1] + #9;
end;

procedure TJSONOutputWriter.AppendLine(const AppendOn: TLastType; const S: string);
begin
  if FLastType = AppendOn then
    FLastLine.Append(S)
  else
  begin
    FlushLastLine;
    StreamFlushPossible;
    FLastLine.Append2(FIndents[FIndent], PChar(Pointer(S)), Length(S));
  end;
end;

procedure TJSONOutputWriter.Indent(const S: string);
var
  LSelf: ^TJSONOutputWriter;
begin
  LSelf := @Self;

  if LSelf.FCompact then
  begin
    LSelf.FStringBuffer.Append(S);
    LSelf.StreamFlushPossible;
  end
  else
  begin
    LSelf.AppendLine(ltIntro, S);

    Inc(LSelf.FIndent);

    if LSelf.FIndent >= LSelf.FIndentsLen then
      ExpandIndents;

    LSelf.FLastType := ltIndent;
  end;
end;

procedure TJSONOutputWriter.Unindent(const S: string);
var
  LSelf: ^TJSONOutputWriter;
begin
  LSelf := @Self;

  if LSelf.FCompact then
  begin
    LSelf.FStringBuffer.Append(S);
    LSelf.StreamFlushPossible;
  end
  else
  begin
    Dec(LSelf.FIndent);

    LSelf.AppendLine(ltIndent, S);
    LSelf.FLastType := ltUnindent;
  end;
end;

procedure TJSONOutputWriter.AppendIntro(const P: PChar; const Len: Integer);
const
  sQuoteCharColon = '":';
var
  LOutputWriter: ^TJSONOutputWriter;
begin
  LOutputWriter := @Self;

  if LOutputWriter.FCompact then
  begin
    LOutputWriter.FStringBuffer.Append2(sQuoteChar, P, Len).Append(sQuoteCharColon, 2);
    LOutputWriter.StreamFlushPossible;
  end
  else
  begin
    FlushLastLine;
    LOutputWriter.StreamFlushPossible;
    LOutputWriter.FLastLine.Append(LOutputWriter.FIndents[LOutputWriter.FIndent]).Append2(sQuoteChar, P, Len).Append('": ', 3);
    LOutputWriter.FLastType := ltIntro;
  end;
end;

procedure TJSONOutputWriter.AppendValue(const S: string);
var
  LOutputWriter: ^TJSONOutputWriter;
begin
  LOutputWriter := @Self;

  if LOutputWriter.FCompact then
  begin
    LOutputWriter.FStringBuffer.Append(S);
    LOutputWriter.StreamFlushPossible;
  end
  else
  begin
    LOutputWriter.AppendLine(ltIntro, S);
    LOutputWriter.FLastType := ltValue;
  end;
end;

procedure TJSONOutputWriter.AppendStrValue(const P: PChar; const Len: Integer);
var
  LOutputWriter: ^TJSONOutputWriter;
begin
  LOutputWriter := @Self;

  if LOutputWriter.FCompact then
  begin
    LOutputWriter.FStringBuffer.Append3(sQuoteChar, P, Len, sQuoteChar);
    LOutputWriter.StreamFlushPossible;
  end
  else
  begin
    if LOutputWriter.FLastType = ltIntro then
      LOutputWriter.FLastLine.Append3(sQuoteChar, P, Len, sQuoteChar)
    else
    begin
      FlushLastLine;
      LOutputWriter.StreamFlushPossible;
      LOutputWriter.FLastLine.Append(LOutputWriter.FIndents[LOutputWriter.FIndent]).Append3(sQuoteChar, P, Len, sQuoteChar);
    end;

    LOutputWriter.FLastType := ltValue;
  end;
end;

procedure TJSONOutputWriter.AppendSeparator(const S: string);
var
  LOutputWriter: ^TJSONOutputWriter;
begin
  LOutputWriter := @Self;

  if LOutputWriter.FCompact then
  begin
    LOutputWriter.FStringBuffer.Append(S);
    LOutputWriter.StreamFlushPossible;
  end
  else
  begin
    if LOutputWriter.FLastType in [ltValue, ltUnindent] then
      LOutputWriter.FLastLine.Append(S)
    else
    begin
      FlushLastLine;
      LOutputWriter.StreamFlushPossible;
      LOutputWriter.FLastLine.Append2(LOutputWriter.FIndents[LOutputWriter.FIndent], PChar(Pointer(S)), Length(S));
    end;

    LOutputWriter.FLastType := ltSeparator;
  end;
end;

{ TJSONUTF8Reader }

constructor TJSONUTF8Reader.Create(S: PByte; Len: NativeInt);
begin
  inherited Create(S);

  FText := S;
  FTextEnd := S + Len;
end;

function TJSONUTF8Reader.GetCharOffset(const StartPos: Pointer): NativeInt;
begin
  Result := FText - PByte(StartPos);
end;

function TJSONUTF8Reader.Next: Boolean;
label
  EndReached;
var
  LPChar, LPEndChar: PByte;
  LChar: Byte;
begin
  LPChar := FText;
  LPEndChar := FTextEnd;

  while True do
  begin
    while True do
    begin
      if LPChar = LPEndChar then
        goto EndReached;

      LChar := LPChar^;

      if LChar > 32 then
        Break;

      if not (LChar in [9, 32]) then
        Break;

      Inc(LPChar);
    end;

    case LChar of
      10:
        begin
          FLineStart := LPChar + 1;
          Inc(FLineNum);
        end;
      13:
        begin
          Inc(FLineNum);

          if (LPChar + 1 < LPEndChar) and (LPChar[1] = 10) then
            Inc(LPChar);

          FLineStart := LPChar + 1;
        end;
    else
      Break;
    end;

    Inc(LPChar);
  end;

EndReached:
  if LPChar < LPEndChar then
  begin
    case LPChar^ of
      Ord('{'):
        begin
          FLook.Kind := jtkLBrace;
          FText := LPChar + 1;
        end;
      Ord('}'):
        begin
          FLook.Kind := jtkRBrace;
          FText := LPChar + 1;
        end;
      Ord('['):
        begin
          FLook.Kind := jtkLBracket;
          FText := LPChar + 1;
        end;
      Ord(']'):
        begin
          FLook.Kind := jtkRBracket;
          FText := LPChar + 1;
        end;
      Ord(':'):
        begin
          FLook.Kind := jtkColon;
          FText := LPChar + 1;
        end;
      Ord(','):
        begin
          FLook.Kind := jtkComma;
          FText := LPChar + 1;
        end;
      Ord('"'): // String
        LexString(LPChar);
    else
      LexIdent(LPChar);
    end;

    Result := True;
  end
  else
  begin
    FText := LPEndChar;
    FLook.Kind := jtkEof;
    Result := False;
  end;
end;

procedure TJSONUTF8Reader.LexString(P: PByte);
var
  LPEndChar: PByte;
  LEscapeSequences: PByte;
  LChar: Byte;
  LIndex: Integer;
begin
  Inc(P);
  LPEndChar := FTextEnd;
  LEscapeSequences := nil;
  LChar := 0;
  LIndex := P - LPEndChar;

  repeat
    if LIndex = 0 then
      Break;

    LChar := LPEndChar[LIndex];

    if (LChar = Byte(Ord('"'))) or (LChar = 10) or (LChar = 13) then
      Break;

    Inc(LIndex);

    if LChar <> Byte(Ord('\')) then
      Continue;

    if LIndex = 0 then
      Break;

    if LEscapeSequences = nil then
      LEscapeSequences := @LPEndChar[LIndex];

    Inc(LIndex);
  until False;

  if LIndex = 0 then
  begin
    FText := P - 1;
    TJSONReader.StringNotClosedError(Self);
  end;

  LPEndChar := @LPEndChar[LIndex];

  if LEscapeSequences = nil then
    SetStringUtf8(FLook.Value, P, LPEndChar - P)
  else
    TJSONUTF8Reader.JSONUtf8StrToStr(P, LPEndChar, LEscapeSequences - P, FLook.Value, Self);

  if LChar = Byte(Ord('"')) then
    Inc(LPEndChar);

  FLook.Kind := jtkString;
  FText := LPEndChar;

  if LChar in [10, 13] then
    TJSONReader.InvalidStringCharacterError(Self);
end;

procedure TJSONUTF8Reader.LexIdent(P: PByte);
const
  NullStr = LongWord(Ord('n') or (Ord('u') shl 8) or (Ord('l') shl 16) or (Ord('l') shl 24));
  TrueStr = LongWord(Ord('t') or (Ord('r') shl 8) or (Ord('u') shl 16) or (Ord('e') shl 24));
  FalseStr = LongWord(Ord('a') or (Ord('l') shl 8) or (Ord('s') shl 16) or (Ord('e') shl 24));
var
  LPChar: PByte;
  LPEndChar: PByte;
  LLength: LongWord;
begin
  LPChar := P;
  LPEndChar := FTextEnd;

  case P^ of
    Ord('A')..Ord('Z'), Ord('a')..Ord('z'), Ord('_'), Ord('$'):
      begin
        Inc(P);

        while P < LPEndChar do
        case P^ of
          Ord('A')..Ord('Z'), Ord('a')..Ord('z'), Ord('_'), Ord('0')..Ord('9'): Inc(P);
        else
          Break;
        end;

        LLength := P - LPChar;

        if LLength = 4 then
        begin
          LLength := PLongWord(LPChar)^;

          if LLength = NullStr then
            FLook.Kind := jtkNull
          else
          if LLength = TrueStr then
            FLook.Kind := jtkTrue
          else
          begin
            SetStringUtf8(FLook.Value, LPChar, P - LPChar);
            FLook.Kind := jtkIdent;
          end;
        end
        else
        if (LLength = 5) and (LPChar^ = Ord('f')) and (PLongWord(LPChar + 1)^ = FalseStr) then
          FLook.Kind := jtkFalse
        else
        begin
          SetStringUtf8(FLook.Value, LPChar, P - LPChar);
          FLook.Kind := jtkIdent;
        end;
      end;
  else
    FLook.Kind := jtkInvalidSymbol;
    Inc(P);
  end;

  FText := P;
end;

{ TJSONStringReader }

constructor TJSONStringReader.Create(S: PChar; Len: Integer);
begin
  inherited Create(S);

  FText := S;
  FTextEnd := S + Len;
end;

function TJSONStringReader.GetCharOffset(const StartPos: Pointer): NativeInt;
begin
  Result := FText - PChar(StartPos);
end;

function TJSONStringReader.Next: Boolean;
var
  LPChar, LPEndChar: PChar;
begin
  LPChar := FText;
  LPEndChar := FTextEnd;

  while (LPChar < LPEndChar) and (LPChar^ <= #32) do
    Inc(LPChar);

  if LPChar < LPEndChar then
  begin
    case LPChar^ of
      '{':
        begin
          FLook.Kind := jtkLBrace;
          FText := LPChar + 1;
        end;
      '}':
        begin
          FLook.Kind := jtkRBrace;
          FText := LPChar + 1;
        end;
      '[':
        begin
          FLook.Kind := jtkLBracket;
          FText := LPChar + 1;
        end;
      ']':
        begin
          FLook.Kind := jtkRBracket;
          FText := LPChar + 1;
        end;
      ':':
        begin
          FLook.Kind := jtkColon;
          FText := LPChar + 1;
        end;
      ',':
        begin
          FLook.Kind := jtkComma;
          FText := LPChar + 1;
        end;
      '"':
        LexString(LPChar);
    else
      LexIdent(LPChar);
    end;

    Result := True;
  end
  else
  begin
    FText := LPEndChar;
    FLook.Kind := jtkEof;
    Result := False;
  end;
end;

procedure TJSONStringReader.LexString(P: PChar);
var
  LPEndChar: PChar;
  LEscapeSequences: PChar;
  LChar: Char;
  LIndex: Integer;
begin
  Inc(P);
  LPEndChar := FTextEnd;
  LEscapeSequences := nil;
  LChar := #0;
  LIndex := P - LPEndChar;

  repeat
    if LIndex = 0 then
      Break;

    LChar := LPEndChar[LIndex];

    if (LChar = '"') or (LChar = #10) or (LChar = #13) then
      Break;

    Inc(LIndex);

    if LChar <> '\' then
      Continue;

    if LIndex = 0 then
      Break;

    if LEscapeSequences = nil then
      LEscapeSequences := @LPEndChar[LIndex];

    Inc(LIndex);
  until False;

  if LIndex = 0 then
  begin
    FText := P - 1;
    TJSONReader.StringNotClosedError(Self);
  end;

  LPEndChar := @LPEndChar[LIndex];

  if LEscapeSequences = nil then
    SetString(FLook.Value, P, LPEndChar - P)
  else
    TJSONReader.JSONStrToStr(P, LPEndChar, LEscapeSequences - P, FLook.Value, Self);

  if LChar = '"' then
    Inc(LPEndChar);

  FLook.Kind := jtkString;
  FText := LPEndChar;

  if LChar in [#10, #13] then
    TJSONReader.InvalidStringCharacterError(Self);
end;

procedure TJSONStringReader.LexIdent(P: PChar);
const
  NullStr1 = LongWord(Ord('n') or (Ord('u') shl 16));
  NullStr2 = LongWord(Ord('l') or (Ord('l') shl 16));
  TrueStr1 = LongWord(Ord('t') or (Ord('r') shl 16));
  TrueStr2 = LongWord(Ord('u') or (Ord('e') shl 16));
  FalseStr1 = LongWord(Ord('a') or (Ord('l') shl 16));
  FalseStr2 = LongWord(Ord('s') or (Ord('e') shl 16));
var
  LPChar: PChar;
  LPEndChar: PChar;
  LLength: LongWord;
begin
  LPChar := P;
  LPEndChar := FTextEnd;

  case P^ of
    'A'..'Z', 'a'..'z', '_', '$':
      begin
        Inc(P);

        while P < LPEndChar do
          case P^ of
            'A'..'Z', 'a'..'z', '_', '0'..'9': Inc(P);
          else
            Break;
          end;

        LLength := P - LPChar;

        if LLength = 4 then
        begin
          LLength := PLongWord(LPChar)^;

          if (LLength = NullStr1) and (PLongWord(LPChar + 2)^ = NullStr2) then
            FLook.Kind := jtkNull
          else
          if (LLength = TrueStr1) and (PLongWord(LPChar + 2)^ = TrueStr2) then
            FLook.Kind := jtkTrue
          else
          begin
            SetString(FLook.Value, LPChar, P - LPChar);
            FLook.Kind := jtkIdent;
          end;
        end
        else
        if (LLength = 5) and (LPChar^ = 'f') and (PLongWord(LPChar + 1)^ = FalseStr1) and (PLongWord(LPChar + 3)^ = FalseStr2) then
          FLook.Kind := jtkFalse
        else
        begin
          SetString(FLook.Value, LPChar, P - LPChar);
          FLook.Kind := jtkIdent;
        end;
      end;
  else
    FLook.Kind := jtkInvalidSymbol;
    Inc(P);
  end;
  FText := P;
end;

{ TJSONDataValueHelper }

class operator TJSONDataValueHelper.Implicit(const AValue: string): TJSONDataValueHelper;
begin
  Result.FData.FName := '';
  Result.FData.FNameResolver := nil;
  Result.FData.FIntern := nil;
  Result.FData.FDataType := jdtString;
  Result.FData.FValue := AValue;
end;

class operator TJSONDataValueHelper.Implicit(const AValue: TJSONDataValueHelper): string;
begin
  if AValue.FData.FIntern <> nil then
    Result := AValue.FData.FIntern.Value
  else
  case AValue.FData.FDataType of
    jdtString:
      Result := AValue.FData.FValue;
    jdtBool:
      if AValue.FData.FBoolValue then
        Result := sTrue
      else
        Result := sFalse;
  else
    Result := '';
  end;
end;

class operator TJSONDataValueHelper.Implicit(const AValue: Boolean): TJSONDataValueHelper;
begin
  Result.FData.FName := '';
  Result.FData.FNameResolver := nil;
  Result.FData.FIntern := nil;
  Result.FData.FDataType := jdtBool;
  Result.FData.FBoolValue := AValue;
end;

class operator TJSONDataValueHelper.Implicit(const AValue: TJSONDataValueHelper): Boolean;
begin
  if AValue.FData.FIntern <> nil then
    Result := AValue.FData.FIntern.BoolValue
  else
  case AValue.FData.FDataType of
    jdtString:
      Result := AValue.FData.FValue = 'true';
    jdtBool:
      Result := AValue.FData.FBoolValue;
  else
    Result := False;
  end;
end;

class operator TJSONDataValueHelper.Implicit(const AValue: TJSONArray): TJSONDataValueHelper;
begin
  Result.FData.FName := '';
  Result.FData.FNameResolver := nil;
  Result.FData.FIntern := nil;
  Result.FData.FDataType := jdtArray;
  Result.FData.FObj := AValue;
end;

class operator TJSONDataValueHelper.Implicit(const AValue: TJSONDataValueHelper): TJSONArray;
begin
  AValue.ResolveName;

  if AValue.FData.FIntern <> nil then
  begin
    if AValue.FData.FIntern.FDataType = jdtNone then
      AValue.FData.FIntern.ArrayValue := TJSONArray.Create;

    Result := AValue.FData.FIntern.ArrayValue;
  end
  else
  if AValue.FData.FDataType = jdtArray then
    Result := TJSONArray(AValue.FData.FObj)
  else
    Result := nil;
end;

class operator TJSONDataValueHelper.Implicit(const AValue: TJSONObject): TJSONDataValueHelper;
begin
  Result.FData.FName := '';
  Result.FData.FNameResolver := nil;
  Result.FData.FIntern := nil;
  Result.FData.FDataType := jdtObject;
  Result.FData.FObj := AValue;
end;

class operator TJSONDataValueHelper.Implicit(const AValue: TJSONDataValueHelper): TJSONObject;
begin
  AValue.ResolveName;

  if AValue.FData.FIntern <> nil then
  begin
    if AValue.FData.FIntern.FDataType = jdtNone then
      AValue.FData.FIntern.ObjectValue := TJSONObject.Create;

    Result := AValue.FData.FIntern.ObjectValue;
  end
  else
  if AValue.FData.FDataType = jdtObject then
    Result := TJSONObject(AValue.FData.FObj)
  else
    Result := nil;
end;

function TJSONDataValueHelper.GetValue: string;
begin
  Result := Self;
end;

procedure TJSONDataValueHelper.SetValue(const AValue: string);
begin
  ResolveName;

  if FData.FIntern <> nil then
    FData.FIntern.Value := AValue
  else
    Self := AValue;
end;

function TJSONDataValueHelper.GetValueBooleanValue: Boolean;
begin
  Result := Self;
end;

procedure TJSONDataValueHelper.SetValueBooleanValue(const AValue: Boolean);
begin
  ResolveName;

  if FData.FIntern <> nil then
    FData.FIntern.BoolValue := AValue
  else
    Self := AValue;
end;

function TJSONDataValueHelper.GetValueArrayValue: TJSONArray;
begin
  Result := Self;
end;

procedure TJSONDataValueHelper.SetValueArrayValue(const AValue: TJSONArray);
begin
  ResolveName;

  if FData.FIntern <> nil then
    FData.FIntern.ArrayValue := AValue
  else
    Self := AValue;
end;

function TJSONDataValueHelper.GetValueObjectValue: TJSONObject;
begin
  Result := Self;
end;

procedure TJSONDataValueHelper.SetValueObjectValue(const AValue: TJSONObject);
begin
  ResolveName;

  if FData.FIntern <> nil then
    FData.FIntern.ObjectValue := AValue
  else
    Self := AValue;
end;

function TJSONDataValueHelper.ToColor: TColor;
begin
  if string(Self).Trim.IsEmpty then
    Result := TColors.SysDefault
  else
    Result := Vcl.Graphics.StringToColor(Self);
end;

function TJSONDataValueHelper.ToInt(Default: Integer): Integer;
var
  LErrorCode: Integer;
begin
  Val(Self, Result, LErrorCode);

  if LErrorCode <> 0 then
    Result := Default;
end;

function TJSONDataValueHelper.ToSet: TTextEditorCharSet;
var
  LIndex: Integer;
begin
  Result := [];

  for LIndex := 1 to Length(Self) do
    Result := Result + [string(Self)[LIndex]];
end;

function TJSONDataValueHelper.ToStr(const ADefault: string): string;
begin
  if string(Self).Trim.IsEmpty then
    Result := ADefault
  else
    Result := Self;
end;

function TJSONDataValueHelper.GetTyp: TJSONDataType;
begin
  if FData.FIntern <> nil then
    Result := FData.FIntern.DataType
  else
    Result := FData.FDataType;
end;

class procedure TJSONDataValueHelper.SetInternValue(const AItem: PJSONDataValue; const AValue: TJSONDataValueHelper);
begin
  AValue.ResolveName;

  if AValue.FData.FIntern <> nil then
  begin
    AItem.Clear;
    TJSONBaseObject.InternInitAndAssignItem(AItem, AValue.FData.FIntern);
  end
  else
  case AValue.FData.FDataType of
    jdtString:
      AItem.Value := AValue.FData.FValue;
    jdtBool:
      AItem.BoolValue := AValue.FData.FBoolValue;
    jdtArray:
      AItem.ArrayValue := TJSONArray(AValue.FData.FObj);
    jdtObject:
      AItem.ObjectValue := TJSONObject(AValue.FData.FObj);
  else
    AItem.Clear;
  end;
end;

function TJSONDataValueHelper.GetValueArrayItem(const AIndex: Integer): TJSONDataValueHelper;
begin
  Result := ArrayValue.Values[AIndex];
end;

function TJSONDataValueHelper.GetValueArrayCount: Integer;
begin
  Result := ArrayValue.Count;
end;

procedure TJSONDataValueHelper.ResolveName;
begin
  if not Assigned(FData.FIntern) and Assigned(FData.FNameResolver) then
  begin
    FData.FIntern := FData.FNameResolver.RequireItem(FData.FName);
    FData.FNameResolver := nil;
    FData.FName := '';
  end;
end;

function TJSONDataValueHelper.GetValueObjectString(const AName: string): string;
begin
  Result := ObjectValue.ValueString[AName];
end;

function TJSONDataValueHelper.GetValueObjectBool(const AName: string): Boolean;
begin
  Result := ObjectValue.ValueBoolean[AName];
end;

function TJSONDataValueHelper.GetValueArray(const AName: string): TJSONArray;
begin
  Result := ObjectValue.ValueArray[AName];
end;

function TJSONDataValueHelper.GetValueObject(const AName: string): TJSONDataValueHelper;
begin
  Result := ObjectValue.Values[AName];
end;

procedure TJSONDataValueHelper.SetValueObjectString(const AName, AValue: string);
begin
  ObjectValue.ValueString[AName] := AValue;
end;

procedure TJSONDataValueHelper.SetValueObjectBool(const AName: string; const AValue: Boolean);
begin
  ObjectValue.ValueBoolean[AName] := AValue;
end;

procedure TJSONDataValueHelper.SetValueArray(const AName: string; const AValue: TJSONArray);
begin
  ObjectValue.ValueArray[AName] := AValue;
end;

procedure TJSONDataValueHelper.SetValueObject(const AName: string; const AValue: TJSONDataValueHelper);
begin
  ObjectValue.Values[AName] := AValue;
end;

function TJSONDataValueHelper.GetValueObjectPath(const AName: string): TJSONDataValueHelper;
begin
  Result := ObjectValue.Path[AName];
end;

procedure TJSONDataValueHelper.SetValueObjectPath(const AName: string; const AValue: TJSONDataValueHelper);
begin
  ObjectValue.Path[AName] := AValue;
end;

{ TEncodingStrictAccess }

function TEncodingStrictAccess.GetByteCountEx(Chars: PChar; CharCount: Integer): Integer;
begin
  Result := GetByteCount(Chars, CharCount);
end;

function TEncodingStrictAccess.GetBytesEx(Chars: PChar; CharCount: Integer; Bytes: PByte; ByteCount: Integer): Integer;
begin
  Result := GetBytes(Chars, CharCount, Bytes, ByteCount);
end;

function TEncodingStrictAccess.GetCharCountEx(Bytes: PByte; ByteCount: Integer): Integer;
begin
  Result := GetCharCount(Bytes, ByteCount);
end;

function TEncodingStrictAccess.GetCharsEx(Bytes: PByte; ByteCount: Integer; Chars: PChar; CharCount: Integer): Integer;
begin
  Result := GetChars(Bytes, ByteCount, Chars, CharCount);
end;

{ TJSONOutputWriter.TJSONStringBuilder }

procedure TJSONOutputWriter.TJSONStringBuilder.Init;
begin
  FDataLength := 0;
  FCapacity := 0;
  FData := nil;
end;

procedure TJSONOutputWriter.TJSONStringBuilder.Done;
var
  LPStrRec: PStrRec;
begin
  if FData <> nil then
  begin
    LPStrRec := PStrRec(PByte(FData) - SizeOf(TStrRec));
    FreeMem(LPStrRec);
  end;
end;

procedure TJSONOutputWriter.TJSONStringBuilder.DoneConvertToString(var S: string);
var
  LPStrRec: PStrRec;
  LPChar: PChar;
begin
  S := '';

  if FData <> nil then
  begin
    LPStrRec := PStrRec(PByte(FData) - SizeOf(TStrRec));

    if DataLength <> FCapacity then
      ReallocMem(Pointer(LPStrRec), SizeOf(TStrRec) + (FDataLength + 1) * SizeOf(Char));

    LPStrRec.Length := DataLength;
    LPChar := PChar(PByte(LPStrRec) + SizeOf(TStrRec));
    LPChar[DataLength] := #0;
    Pointer(S) := LPChar;
  end;
end;

function TJSONOutputWriter.TJSONStringBuilder.FlushToBytes(var Bytes: PByte; var Size: NativeInt; Encoding: TEncoding): NativeInt;
begin
  if FDataLength > 0 then
  begin
    Result := TEncodingStrictAccess(Encoding).GetByteCountEx(FData, FDataLength);

    if Result > 0 then
    begin
      if Result > Size then
      begin
        Size := (Result + 4095) and not 4095;
        ReallocMem(Bytes, Size);
      end;

      TEncodingStrictAccess(Encoding).GetBytesEx(FData, FDataLength, Bytes, Result);
    end;

    FDataLength := 0;
  end
  else
    Result := 0;
end;

procedure TJSONOutputWriter.TJSONStringBuilder.FlushToMemoryStream(const Stream: TMemoryStream; const Encoding: TEncoding);
var
  LByteCount: Integer;
  LIndex, LNewSize: NativeInt;
begin
  if FDataLength > 0 then
  begin
    LByteCount := TEncodingStrictAccess(Encoding).GetByteCountEx(FData, FDataLength);

    if LByteCount > 0 then
    begin
      LIndex := Stream.Position;
      LNewSize := LIndex + LByteCount;

      if LNewSize > TMemoryStreamAccess(Stream).Capacity then
        TMemoryStreamAccess(Stream).Capacity := LNewSize;

      TEncodingStrictAccess(Encoding).GetBytesEx(FData, FDataLength, @PByte(Stream.Memory)[LIndex], LByteCount);
      TMemoryStreamAccess(Stream).SetPointer(Stream.Memory, LNewSize);
      Stream.Position := LNewSize;
    end;
  end;

  FDataLength := 0;
end;

procedure TJSONOutputWriter.TJSONStringBuilder.Grow(MinLen: Integer);
var
  LCapacity: Integer;
  LPStrRec: PStrRec;
begin
  LCapacity := FCapacity;
  LCapacity := LCapacity * 2;

  if MinLen < 256 then
    MinLen := 256;

{$IFNDEF CPUX64}
  if LCapacity > 256 * 1024 * 1024 then
  begin
    LCapacity := FCapacity;
    LCapacity := LCapacity + (LCapacity div 3);

    if LCapacity < MinLen then
      LCapacity := MinLen;
  end
  else
{$ENDIF ~CPUX64}
  if LCapacity < MinLen then
    LCapacity := MinLen;

  FCapacity := LCapacity;

  if Assigned(FData) then
  begin
    LPStrRec := Pointer(PByte(FData) - SizeOf(TStrRec));
    ReallocMem(LPStrRec, SizeOf(TStrRec) + (LCapacity + 1) * SizeOf(Char));
  end
  else
  begin
    GetMem(Pointer(LPStrRec), SizeOf(TStrRec) + (LCapacity + 1) * SizeOf(Char));
    LPStrRec.CodePage := Word(DefaultUnicodeCodePage);
    LPStrRec.ElemSize := SizeOf(Char);
    LPStrRec.RefCnt := 1;
    LPStrRec.Length := 0;
  end;

  FData := PChar(PByte(LPStrRec) + SizeOf(TStrRec));
end;

function TJSONOutputWriter.TJSONStringBuilder.Append(const AValue: string): PJSONStringBuilder;
var
  LValueLength, LDataLength: Integer;
begin
  LDataLength := FDataLength;
  LValueLength := Length(AValue);

  if LValueLength > 0 then
  begin
    if LDataLength + LValueLength >= FCapacity then
      Grow(LDataLength + LValueLength);

    case LValueLength of
      1:
        FData[LDataLength] := PChar(Pointer(AValue))^;
      2:
        PLongWord(@FData[LDataLength])^ := PLongWord(Pointer(AValue))^;
    else
      Move(PChar(Pointer(AValue))[0], FData[LDataLength], LValueLength * SizeOf(Char));
    end;

    FDataLength := LDataLength + LValueLength;
  end;

  Result := @Self;
end;

procedure TJSONOutputWriter.TJSONStringBuilder.Append(const P: PChar; const Len: Integer);
var
  LLength: Integer;
begin
  LLength := FDataLength;

  if Len> 0 then
  begin
    if LLength + Len >= FCapacity then
      Grow(LLength + Len);

    case Len of
      1:
        FData[LLength] := P^;
      2:
        PLongWord(@FData[LLength])^ := PLongWord(P)^;
    else
      Move(P[0], FData[LLength], Len * SizeOf(Char));
    end;

    FDataLength := LLength + Len;
  end;
end;

function TJSONOutputWriter.TJSONStringBuilder.Append2(const S1: string; S2: PChar; S2Len: Integer): PJSONStringBuilder;
var
  LLength, LString1Length, LDataLength: Integer;
begin
  LDataLength := FDataLength;
  LString1Length := Length(S1);
  LLength := LString1Length + S2Len;

  if LDataLength + LLength >= FCapacity then
    Grow(LDataLength + LLength);

  case LString1Length of
    0:
      ;
    1:
      FData[LDataLength] := PChar(Pointer(S1))^;
    2:
      PLongWord(@FData[LDataLength])^ := PLongWord(Pointer(S1))^;
  else
    Move(PChar(Pointer(S1))[0], FData[LDataLength], LString1Length * SizeOf(Char));
  end;

  Inc(LDataLength, LString1Length);

  case S2Len of
    0:
      ;
    1:
      FData[LDataLength] := S2^;
    2:
      PLongWord(@FData[LDataLength])^ := PLongWord(Pointer(S2))^;
  else
    Move(S2[0], FData[LDataLength], S2Len * SizeOf(Char));
  end;

  FDataLength := LDataLength + S2Len;

  Result := @Self;
end;

procedure TJSONOutputWriter.TJSONStringBuilder.Append2(const Ch1: Char; const Ch2: Char);
var
  LDataLength: Integer;
begin
  LDataLength := FDataLength;

  if LDataLength + 2 >= FCapacity then
    Grow(2);

  FData[LDataLength] := Ch1;
  FData[LDataLength + 1] := Ch2;
  FDataLength := LDataLength + 2;
end;

procedure TJSONOutputWriter.TJSONStringBuilder.Append3(const Ch1: Char; const S2, S3: string);
var
  LLength, LString2Length, LString3Length, LDataLength: Integer;
begin
  LDataLength := FDataLength;
  LString2Length := Length(S2);
  LString3Length := Length(S3);
  LLength := 1 + LString2Length + LString3Length;

  if LDataLength + LLength >= FCapacity then
    Grow(LDataLength + LLength);

  FData[LDataLength] := Ch1;
  Inc(LDataLength);

  case LString2Length of
    0:
      ;
    1:
      FData[LDataLength] := PChar(Pointer(S2))^;
    2:
      PLongWord(@FData[LDataLength])^ := PLongWord(Pointer(S2))^;
  else
    Move(PChar(Pointer(S2))[0], FData[LDataLength], LString2Length * SizeOf(Char));
  end;

  Inc(LDataLength, LString2Length);

  case LString3Length of
    1:
      FData[LDataLength] := PChar(Pointer(S3))^;
    2:
      PLongWord(@FData[LDataLength])^ := PLongWord(Pointer(S3))^;
  else
    Move(PChar(Pointer(S3))[0], FData[LDataLength], LString3Length * SizeOf(Char));
  end;

  FDataLength := LDataLength + LString3Length;
end;

procedure TJSONOutputWriter.TJSONStringBuilder.Append3(const Ch1: Char; const P2: PChar; P2Len: Integer; const Ch3: Char);
var
  LLength, LDataLength: Integer;
begin
  LDataLength := FDataLength;
  LLength := 2 + P2Len;

  if LDataLength + LLength >= FCapacity then
    Grow(LDataLength + LLength);

  FData[LDataLength] := Ch1;
  Inc(LDataLength);

  case P2Len of
    0:
      ;
    1:
      FData[LDataLength] := P2^;
    2:
      PLongWord(@FData[LDataLength])^ := PLongWord(P2)^;
  else
    Move(P2[0], FData[LDataLength], P2Len * SizeOf(Char));
  end;

  Inc(LDataLength, P2Len);

  FData[LDataLength] := Ch1;
  FDataLength := LDataLength + 1;
end;

procedure TJSONOutputWriter.TJSONStringBuilder.Append3(const Ch1: Char; const S2: string; const Ch3: Char);
begin
  Append3(Ch1, PChar(Pointer(S2)), Length(S2), Ch3);
end;

procedure TJSONOutputWriter.TJSONStringBuilder.FlushToStringBuffer(var Buffer: TJSONStringBuilder);
begin
  Buffer.Append(FData, FDataLength);
  FDataLength := 0;
end;

procedure TJSONOutputWriter.TJSONStringBuilder.FlushToString(var S: string);
begin
  System.SetString(S, FData, FDataLength);
  FDataLength := 0;
end;

initialization

  UniqueString(sTrue);
  UniqueString(sFalse);

end.
