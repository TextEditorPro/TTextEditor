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
    constructor CreateResFmt(const AMessage: PResStringRec; const AArgs: array of const; const ALineNum, AColumn, APosition: NativeInt);
    constructor CreateRes(const AMessage: PResStringRec; const ALineNum, AColumn, APosition: NativeInt);
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
      procedure Grow(const ALength: Integer);
    public
      function Append(const AValue: string): PJSONStringBuilder; overload;
      function Append2(const AValue1: string; AValue2: PChar; AValue2Length: Integer): PJSONStringBuilder; overload;
      function FlushToBytes(var ABytes: PByte; var ASize: NativeInt; const AEncoding: TEncoding): NativeInt;
      procedure Append(const AValue: PChar; const ALength: Integer); overload;
      procedure Append2(const AChar1: Char; const AChar2: Char); overload;
      procedure Append3(const AChar1: Char; const AChar2: PChar; const AChar2Length: Integer; const AChar3: Char); overload;
      procedure Append3(const AChar1: Char; const AValue2, AValue3: string); overload;
      procedure Append3(const AChar1: Char; const AValue2: string; const AChar3: Char); overload;
      procedure Done;
      procedure DoneConvertToString(var AValue: string);
      procedure FlushToMemoryStream(const AStream: TMemoryStream; const AEncoding: TEncoding);
      procedure FlushToString(var AValue: string);
      procedure FlushToStringBuffer(var ABuffer: TJSONStringBuilder);
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
    function Done: string;
    procedure AppendIntro(const AValue: PChar; const ALength: Integer);
    procedure AppendLine(const AType: TLastType; const AValue: string); overload;
    procedure AppendSeparator(const AValue: string);
    procedure AppendStrValue(const AValue: PChar; const ALength: Integer);
    procedure AppendValue(const AValue: string); overload;
    procedure ExpandIndents;
    procedure FlushLastLine;
    procedure FreeIndents;
    procedure Indent(const AValue: string);
    procedure Init(const ACompact: Boolean; const AStream: TStream; const AEncoding: TEncoding; const ALines: TStrings);
    procedure StreamFlush;
    procedure StreamFlushPossible;
    procedure Unindent(const AValue: string);
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
    procedure InternToJSON(var AWriter: TJSONOutputWriter);
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
    FData: record
      Intern: PJSONDataValue;
      Name: string;
      NameResolver: TJSONObject;
      Value: string;
      case DataType: TJSONDataType of
        jdtBool:
          (BoolValue: Boolean);
        jdtObject:
          (ObjectValue: TJSONBaseObject);
    end;
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
    function ToInt(const ADefault: Integer): Integer;
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
  end;

  TJSONBaseObject = class abstract(TObject)
  private type
    TWriterAppendMethod = procedure(const AValue: PChar; const ALength: Integer) of object;

    TStreamInfo = record
      Buffer: PByte;
      Size: NativeInt;
      AllocationBase: Pointer;
    end;
  private
    class procedure EscapeStrToJSONStr(AValueStart, AValue, AValueEnd: PChar; const AAppendMethod: TWriterAppendMethod); static;
    class procedure GetStreamBytes(const AStream: TStream; var AEncoding: TEncoding; const AUtf8WithoutBOM: Boolean; var AStreamInfo: TStreamInfo); static;
    class procedure InternInitAndAssignItem(const ADest, ASource: PJSONDatAValue); static;
    class procedure StrToJSONStr(const AAppendMethod: TWriterAppendMethod; const AValue: string); static;
  protected
    procedure InternToJSON(var AWriter: TJSONOutputWriter); virtual; abstract;
  public
    const DataTypeNames: array [TJSONDataType] of string = ('null', 'String', 'Bool', 'Array', 'Object');
    class function Parse(const ABytes: TBytes; const AByteIndex: Integer = 0; AByteCount: Integer = -1): TJSONBaseObject; overload; static;
    class function Parse(const AJSON: UnicodeString): TJSONBaseObject; overload; static; inline;
    class function Parse(AJSON: PWideChar; ALength: Integer = -1): TJSONBaseObject; overload; static;
    class function ParseFromStream(const AJSON: TStream): TJSONBaseObject; static;
    class function ParseUtf8Bytes(const AJSON: PByte; ALength: Integer = -1): TJSONBaseObject; static;
    function ToJSON(const ACompact: Boolean = True): string;
    function ToString: string; override;
    procedure FromJSON(const AJSON: UnicodeString); overload;
    procedure FromJSON(AJSON: PWideChar; ALength: Integer = -1); overload;
    procedure FromUtf8JSON(const AJSON: PByte; ALength: Integer = -1); overload;
    procedure LoadFromStream(const AJSON: TStream);
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
    function InsertArray(const AIndex: Integer): TJSONArray;
    function InsertObject(const AIndex: Integer): TJSONObject; overload;
    procedure Add(const AValue: Boolean); overload;
    procedure Add(const AValue: string); overload;
    procedure Add(const AValue: TJSONArray); overload;
    procedure Add(const AValue: TJSONObject); overload;
    procedure AddObject(const AValue: TJSONObject); overload;
    procedure Assign(const ASource: TJSONArray);
    procedure Clear;
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
    PJsonStringSortIndexArray = ^TJsonStringSortIndexArray;
    TJsonStringSortIndexArray = array[0..MaxInt div SizeOf(Integer) - 1] of Integer;
  private
    FCapacity: Integer;
    FCount: Integer;
    FItems: PJSONDataValueArray;
    FNames: PJSONStringArray;
    FSortedNames: PJsonStringSortIndexArray;
    FFirstUnsortedNameIndex: Integer;
    function AddItem(const AName: string): PJSONDataValue;
    function CompareSortedName(const AIndex1, AIndex2: Integer): Integer;
    function FindItem(const AName: string; var Item: PJSONDataValue): Boolean;
    function GetItem(const AIndex: Integer): PJSONDataValue;
    function GetName(const AIndex: Integer): string;
    function GetPath(const ANamePath: string): TJSONDataValueHelper;
    function GetValue(const AName: string): TJSONDataValueHelper;
    function GetValueArray(const AName: string): TJSONArray;
    function GetValueBoolean(const AName: string): Boolean;
    function GetValueString(const AName: string): string;
    function IndexOfPChar(const AValue: PChar; const ALength: Integer): Integer;
    function InternAddArray(var AName: string): TJSONArray;
    function InternAddItem(var AName: string): PJSONDataValue;
    function InternAddObject(var AName: string): TJSONObject;
    function InternFindSortedNameInsertIndex(const AIndex: Integer): Integer;
    function InternIndexOfSortedName(const AName: string): Integer;
    function RequireItem(const AName: string): PJSONDataValue;
    procedure Grow;
    procedure InternAdd(var AName: string; const AValue: Boolean); overload;
    procedure InternAdd(var AName: string; const AValue: TJSONArray); overload;
    procedure InternAdd(var AName: string; const AValue: TJSONObject); overload;
    procedure InternApplyCapacity;
    procedure InternDeleteSortedName(const AIndex: Integer);
    procedure PathError(const AValue, AValueEnd: PChar);
    procedure PathIndexError(const AValue, AValueEnd: PChar; const ACount: Integer);
    procedure PathNullError(const AValue, AValueEnd: PChar);
    procedure QuickSortNames(ALeft, ARight: Integer);
    procedure SetCapacity(const AValue: Integer);
    procedure SetPath(const ANamePath: string; const AValue: TJSONDataValueHelper);
    procedure SetValue(const AName: string; const AValue: TJSONDataValueHelper);
    procedure SetValueArray(const AName: string; const AValue: TJSONArray);
    procedure SetValueBoolean(const AName: string; const AValue: Boolean);
    procedure SetValueString(const AName, AValue: string);
    procedure SortUnsortedNames;
  protected
    procedure InternToJSON(var Writer: TJSONOutputWriter); override;
  public
    destructor Destroy; override;
    function Contains(const AName: string): Boolean;
    function IndexOf(const AName: string): Integer;
    procedure Assign(const ASource: TJSONObject);
    procedure Clear;
    procedure Delete(const AIndex: Integer);
    property Capacity: Integer read FCapacity write SetCapacity;
    property Count: Integer read FCount;
    property Items[const AIndex: Integer]: PJSONDataValue read GetItem;
    property Names[const AIndex: Integer]: string read GetName;
    property Path[const ANamePath: string]: TJSONDataValueHelper read GetPath write SetPath;
    property ValueArray[const AName: string]: TJSONArray read GetValueArray write SetValueArray;
    property ValueBoolean[const AName: string]: Boolean read GetValueBoolean write SetValueBoolean;
    property Values[const AName: string]: TJSONDataValueHelper read GetValue write SetValue; default;
    property ValueString[const AName: string]: string read GetValueString write SetValueString;
  end;

implementation

uses
  Winapi.Windows, System.AnsiStrings, System.Math, System.RTLConsts, TextEditor.Language;

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
    procedure Intern(var AValue: string; var APropName: string);
  end;

  TJSONToken = record
    Kind: TJSONTokenKind;
    Value: string;
  end;

  TJSONReader = class(TObject)
  private
    FPropName: string;
    procedure Accept(TokenKind: TJSONTokenKind);
    procedure ParseObjectBody(const AData: TJSONObject);
    procedure ParseObjectProperty(const AData: TJSONObject);
    procedure ParseObjectPropertyValue(const AData: TJSONObject);
    procedure ParseArrayBody(const AData: TJSONArray);
    procedure ParseArrayPropertyValue(const AData: TJSONArray);
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

constructor EJSONParserException.CreateResFmt(const AMessage: PResStringRec; const AArgs: array of const;
  const ALineNum, AColumn, APosition: NativeInt);
begin
  inherited CreateResFmt(AMessage, AArgs);

  FLineNum := ALineNum;
  FColumn := AColumn;
  FPosition := APosition;

  if FLineNum > 0 then
    Message := Format('%s (%d, %d)', [Message, FLineNum, FColumn]);
end;

constructor EJSONParserException.CreateRes(const AMessage: PResStringRec; const ALineNum, AColumn, APosition: NativeInt);
begin
  inherited CreateRes(AMessage);

  FLineNum := ALineNum;
  FColumn := AColumn;
  FPosition := APosition;

  if FLineNum > 0 then
    Message := Format('%s (%d, %d)', [Message, FLineNum, FColumn]);
end;

procedure ListError(const AMessage: PResStringRec; const AData: Integer);
begin
  raise EStringListError.CreateFmt(LoadResString(AMessage), [AData]);
end;

procedure SetValueStringUtf8(var AValue: string; APByte: PByte; ALength: Integer);
var
  LLength: Integer;
begin
  if not AValue.IsEmpty then
    AValue := '';

  if (APByte = nil) or (ALength = 0) then
    Exit;

  SetLength(AValue, ALength);

  LLength := Utf8ToUnicode(PWideChar(Pointer(AValue)), ALength + 1, PAnsiChar(APByte), ALength);

  if LLength > 0 then
  begin
    if LLength - 1 <> ALength then
      SetLength(AValue, LLength - 1);
  end
  else
    AValue := '';
end;

procedure AppendStringUtf8(var S: string; P: PByte; Len: Integer);
var
  L, OldLen: Integer;
begin
  if (P = nil) or (Len = 0) then
    Exit;

  OldLen := S.Length;
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

  LLength := S.Length;
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
        Len := S.Length;
        SetLength(S, Len + BufPos);
        Move(Buf[0], PChar(Pointer(S))[Len], BufPos * SizeOf(Char));
        BufPos := 0;
      end;
    end;

    // append remaining buffer
    if BufPos > 0 then
    begin
      Len := S.Length;
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


procedure SetStringUtf8(var AValue: string; APByte: PByte; const ALength: Integer);
var
  LValue: Integer;
begin
  if not AValue.IsEmpty then
    AValue := '';

  if (APByte = nil) or (ALength = 0) then
    Exit;

  SetLength(AValue, ALength);

  LValue := Utf8ToUnicode(PWideChar(Pointer(AValue)), ALength + 1, PAnsiChar(APByte), ALength);

  if LValue > 0 then
  begin
    if LValue - 1 <> ALength then
      SetLength(AValue, LValue - 1);
  end
  else
    AValue := '';
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
        Len := S.Length;
        SetLength(S, Len + BufPos);
        Move(Buf[0], PChar(Pointer(S))[Len], BufPos * SizeOf(Char));
        BufPos := 0;
      end;
    end;

    // append remaining buffer
    if BufPos > 0 then
    begin
      Len := S.Length;
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

procedure TJSONReader.ParseObjectBody(const AData: TJSONObject);
begin
  if FLook.Kind <> jtkRBrace then
  begin
    while FLook.Kind <> jtkEof do
    begin
      ParseObjectProperty(AData);

      if FLook.Kind = jtkRBrace then
        Break;

      Accept(jtkComma);
    end;
  end;
end;

procedure TJSONReader.ParseObjectProperty(const AData: TJSONObject);
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
  ParseObjectPropertyValue(AData);
end;

procedure TJSONReader.ParseObjectPropertyValue(const AData: TJSONObject);
begin
  case FLook.Kind of
    jtkLBrace:
      begin
        Accept(jtkLBrace);
        ParseObjectBody(AData.InternAddObject(FPropName));
        Accept(jtkRBrace);
      end;
    jtkLBracket:
      begin
        Accept(jtkLBracket);
        ParseArrayBody(AData.InternAddArray(FPropName));
        Accept(jtkRBracket);
      end;
    jtkNull:
      begin
        AData.InternAdd(FPropName, TJSONObject(nil));
        Next;
      end;
    jtkIdent, jtkString:
      begin
        AData.InternAddItem(FPropName).InternSetValueTransfer(FLook.Value);
        Next;
      end;
    jtkTrue:
      begin
        AData.InternAdd(FPropName, True);
        Next;
      end;
    jtkFalse:
      begin
        AData.InternAdd(FPropName, False);
        Next;
      end
  else
    Accept(jtkValue);
  end;
end;

procedure TJSONReader.ParseArrayBody(const AData: TJSONArray);
begin
  if FLook.Kind <> jtkRBracket then
  while FLook.Kind <> jtkEof do
  begin
    ParseArrayPropertyValue(AData);

    if FLook.Kind = jtkRBracket then
      Break;

    Accept(jtkComma);
  end;
end;

procedure TJSONReader.ParseArrayPropertyValue(const AData: TJSONArray);
begin
  case FLook.Kind of
    jtkLBrace:
      begin
        Accept(jtkLBrace);
        ParseObjectBody(AData.AddObject);
        Accept(jtkRBrace);
      end;
    jtkLBracket:
      begin
        Accept(jtkLBracket);
        ParseArrayBody(AData.AddArray);
        Accept(jtkRBracket);
      end;
    jtkNull:
      begin
        AData.Add(TJSONObject(nil));
        Next;
      end;
    jtkIdent, jtkString:
      begin
        AData.Add(FLook.Value);
        Next;
      end;
    jtkTrue:
      begin
        AData.Add(True);
        Next;
      end;
    jtkFalse:
      begin
        AData.Add(False);
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

procedure TJSONDataValue.InternToJSON(var AWriter: TJSONOutputWriter);
begin
  case FDataType of
    jdtNone:
      AWriter.AppendValue(sNull);
    jdtString:
      TJSONBaseObject.StrToJSONStr(AWriter.AppendStrValue, string(FValue.ValueString));
    jdtBool:
      if FValue.ValueBoolean then
        AWriter.AppendValue(sTrue)
      else
        AWriter.AppendValue(sFalse);
    jdtArray:
      if (FValue.ValueArray = nil) or (TJSONArray(FValue.ValueArray).Count = 0) then
        AWriter.AppendValue('[]')
      else
        TJSONArray(FValue.ValueArray).InternToJSON(AWriter);
    jdtObject:
      if FValue.ValueObject = nil then
        AWriter.AppendValue(sNull)
      else
        TJSONObject(FValue.ValueObject).InternToJSON(AWriter);
  end;
end;

{ TJSONBaseObject }

class procedure TJSONBaseObject.StrToJSONStr(const AAppendMethod: TWriterAppendMethod; const AValue: string);
var
  LValue, LValueStart, LValueEnd: PChar;
begin
  LValue := PChar(Pointer(AValue));

  if LValue <> nil then
  begin
    LValueEnd := LValue + PInteger(@PByte(AValue)[-4])^;

    LValueStart := LValue;

    while LValue < LValueEnd do
      case LValue^ of
        #0 .. #31, '\', '"':
          Break;
      else
        Inc(LValue);
      end;

    if LValue = LValueEnd then
      AAppendMethod(PChar(AValue), AValue.Length)
    else
      EscapeStrToJSONStr(LValueStart, LValue, LValueEnd, AAppendMethod);
  end
  else
    AAppendMethod(nil, 0);
end;

class procedure TJSONBaseObject.EscapeStrToJSONStr(AValueStart, AValue, AValueEnd: PChar; const AAppendMethod: TWriterAppendMethod);
const
  HexChars: array [0 .. 15] of Char = '0123456789abcdef';
var
  LStringBuilder: TJSONOutputWriter.TJSONStringBuilder;
  LChar: Char;
begin
  LStringBuilder.Init;
  try
    repeat
      if AValue <> AValueStart then
        LStringBuilder.Append(AValueStart, AValue - AValueStart);

      if AValue < AValueEnd then
      begin
        LChar := AValue^;

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

        Inc(AValue);
        AValueStart := AValue;

        while AValue < AValueEnd do
        case AValue^ of
          #0 .. #31, '\', '"':
            Break;
        else
          Inc(AValue);
        end;
      end
      else
        Break;
    until False;

    AAppendMethod(LStringBuilder.Data, LStringBuilder.DataLength);
  finally
    LStringBuilder.Done;
  end;
end;

class function TJSONBaseObject.ParseUtf8Bytes(const AJSON: PByte; ALength: Integer): TJSONBaseObject;
var
  LJSON: PByte;
  LLength: Integer;
begin
  if (AJSON = nil) or (ALength = 0) then
    Result := nil
  else
  begin
    if ALength < 0 then
      ALength := System.AnsiStrings.StrLen(PAnsiChar(AJSON));

    LJSON := AJSON;
    LLength := ALength;

    while (LLength > 0) and (LJSON^ <= 32) do
    begin
      Inc(LJSON);
      Dec(LLength);
    end;

    if LLength = 0 then
      Result := nil
    else
    begin
      if (LLength > 0) and (LJSON^ = Byte(Ord('['))) then
        Result := TJSONArray.Create
      else
        Result := TJSONObject.Create;

      try
        Result.FromUtf8JSON(AJSON, ALength);
      except
        Result.Free;
        raise;
      end;
    end;
  end;
end;

class function TJSONBaseObject.Parse(const ABytes: TBytes; const AByteIndex: Integer; AByteCount: Integer): TJSONBaseObject;
var
  LLength: Integer;
begin
  LLength := Length(ABytes);

  if AByteCount = -1 then
    AByteCount := LLength - AByteIndex;

  if (AByteCount <= 0) or (AByteIndex + AByteCount > LLength) then
    Result := nil
  else
    Result := ParseUtf8Bytes(PByte(@ABytes[AByteIndex]), AByteCount)
end;

class function TJSONBaseObject.Parse(const AJSON: UnicodeString): TJSONBaseObject;
begin
  Result := Parse(PWideChar(Pointer(AJSON)), AJSON.Length);
end;

class function TJSONBaseObject.Parse(AJSON: PWideChar; ALength: Integer): TJSONBaseObject;
var
  LJSON: PWideChar;
  LLength: Integer;
begin
  if (AJSON = nil) or (ALength = 0) then
    Result := nil
  else
  begin
    if ALength < 0 then
      ALength := StrLen(AJSON);

    LJSON := AJSON;
    LLength := ALength;

    while (LLength > 0) and (LJSON^ <= #32) do
    begin
      Inc(LJSON);
      Dec(LLength);
    end;

    if LLength = 0 then
      Result := nil
    else
    begin
      if (LLength > 0) and (LJSON^ = '[') then
        Result := TJSONArray.Create
      else
        Result := TJSONObject.Create;

      try
        Result.FromJSON(AJSON, ALength);
      except
        Result.Free;
        raise;
      end;
    end;
  end;
end;

procedure TJSONBaseObject.FromJSON(const AJSON: UnicodeString);
begin
  FromJSON(PWideChar(AJSON), AJSON.Length);
end;

procedure TJSONBaseObject.FromJSON(AJSON: PWideChar; ALength: Integer);
var
  LReader: TJSONReader;
begin
  if ALength < 0 then
    ALength := StrLen(AJSON);

  LReader := TJSONStringReader.Create(AJSON, ALength);
  try
    LReader.Parse(Self);
  finally
    LReader.Free;
  end;
end;

class function TJSONBaseObject.ParseFromStream(const AJSON: TStream): TJSONBaseObject;
var
  LStreamInfo: TStreamInfo;
  LEncoding: TEncoding;
begin
  LEncoding := nil;
  GetStreamBytes(AJSON, LEncoding, True, LStreamInfo);
  try
    Result := ParseUtf8Bytes(LStreamInfo.Buffer, LStreamInfo.Size)
  finally
    FreeMem(LStreamInfo.AllocationBase);
  end;
end;

procedure TJSONBaseObject.FromUtf8JSON(const AJSON: PByte; ALength: Integer);
var
  LReader: TJSONReader;
begin
  if ALength < 0 then
    ALength := System.AnsiStrings.StrLen(PAnsiChar(AJSON));

  LReader := TJSONUTF8Reader.Create(AJSON, ALength);
  try
    LReader.Parse(Self);
  finally
    LReader.Free;
  end;
end;

class procedure TJSONBaseObject.GetStreamBytes(const AStream: TStream; var AEncoding: TEncoding;
  const AUtf8WithoutBOM: Boolean; var AStreamInfo: TStreamInfo);
var
  LPosition: Int64;
  LSize: NativeInt;
  LBytes: PByte;
  LBufStart: Integer;
begin
  LBufStart := 0;
  LPosition := AStream.Position;
  LSize := AStream.Size - LPosition;

  AStreamInfo.Buffer := nil;
  AStreamInfo.Size := 0;
  AStreamInfo.AllocationBase := nil;
  try
    LBytes := nil;

    if LSize > 0 then
    begin
      if AStream is TCustomMemoryStream then
      begin
        LBytes := TCustomMemoryStream(AStream).Memory;
        TCustomMemoryStream(AStream).Position := LPosition + LSize;
        Inc(LBytes, LPosition);
      end
      else
      begin
        GetMem(AStreamInfo.AllocationBase, LSize);
        LBytes := AStreamInfo.AllocationBase;
        AStream.ReadBuffer(AStreamInfo.AllocationBase^, LSize);
      end;
    end;

    if AEncoding = nil then
    begin
      if AUtf8WithoutBOM then
        AEncoding := TEncoding.UTF8
      else
        AEncoding := TEncoding.Default;

      if LSize >= 2 then
      begin
        if (LBytes[0] = $EF) and (LBytes[1] = $BB) then
        begin
          if LBytes[2] = $BF then
          begin
            AEncoding := TEncoding.UTF8;
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
            AEncoding := TEncoding.Unicode;
            LBufStart := 2;
          end;
        end
        else
        if (LBytes[0] = $FE) and (LBytes[1] = $FF) then
        begin
          AEncoding := TEncoding.BigEndianUnicode;
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
    AStreamInfo.Buffer := LBytes;
    AStreamInfo.Size := LSize - LBufStart;
  except
    FreeMem(AStreamInfo.AllocationBase);
    raise;
  end;
end;

procedure TJSONBaseObject.LoadFromStream(const AJSON: TStream);
var
  LStreamInfo: TStreamInfo;
  LEncoding: TEncoding;
begin
  LEncoding := nil;

  GetStreamBytes(AJSON, LEncoding, True, LStreamInfo);
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

class procedure TJSONBaseObject.InternInitAndAssignItem(const ADest, ASource: PJSONDatAValue);
begin
  ADest.FDataType := ASource.FDataType;

  case ASource.DataType of
    jdtString:
      begin
        ADest.FValue.ValuePChar := nil;
        string(ADest.FValue.ValueString) := string(ASource.FValue.ValueString);
      end;
    jdtBool:
      ADest.FValue.ValueBoolean := ASource.FValue.ValueBoolean;
    jdtArray:
      if ASource.FValue.ValueArray <> nil then
      begin
        TJSONArray(ADest.FValue.ValueArray) := TJSONArray.Create;
        TJSONArray(ADest.FValue.ValueArray).Assign(TJSONArray(ASource.FValue.ValueArray));
      end
      else
        ADest.FValue.ValueArray := nil;
    jdtObject:
      if ASource.FValue.ValueObject <> nil then
      begin
        TJSONObject(ADest.FValue.ValueObject) := TJSONObject.Create;
        TJSONObject(aDest.FValue.ValueObject).Assign(TJSONObject(ASource.FValue.ValueObject));
      end
      else
        ADest.FValue.ValueObject := nil;
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
  Result.FData.Intern := @FItems[AIndex];
  Result.FData.DataType := jdtNone;
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
  Result.Value.FData.Intern := FObject.Items[FIndex];
  Result.Value.FData.DataType := jdtNone;
end;

{ TJSONObject }

destructor TJSONObject.Destroy; //FI:W504 FixInsight ignore - Missing INHERITED call in destructor
begin
  Clear;
  FreeMem(FItems);
  FreeMem(FNames);
  FreeMem(FSortedNames);

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
  ReallocMem(Pointer(FSortedNames), FCapacity * SizeOf(FSortedNames[0]));
end;

procedure TJsonObject.InternDeleteSortedName(const AIndex: Integer);
begin
  if AIndex < FCount - 1 then
    Move(FSortedNames[AIndex + 1], FSortedNames[AIndex], (FCount - AIndex) * SizeOf(FSortedNames[0]));
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
  FFirstUnsortedNameIndex := -1;
end;

function TJSONObject.AddItem(const AName: string): PJSONDataValue;
var
  LPName: PString;
begin
  if FCount = FCapacity then
    Grow;

  Result := @FItems[FCount];
  LPName := @FNames[FCount];
  Pointer(LPName^) := nil;
  LPName^ := AName;

  if FFirstUnsortedNameIndex = -1 then
    FFirstUnsortedNameIndex := FCount;

  Inc(FCount);

  Result.FValue.ValuePChar := nil;
  Result.FDataType := jdtNone;
end;

function TJsonObject.CompareSortedName(const AIndex1, AIndex2: Integer): Integer;
var
  P1, P2: PString;
begin
  P1 := @FNames[FSortedNames[AIndex1]];
  P2 := @FNames[FSortedNames[AIndex2]];

  Result := Length(P1^) - Length(P2^);

  if Result = 0 then
    Result := CompareStr(P1^, P2^);
end;

function TJSONObject.InternAddItem(var AName: string): PJSONDataValue;
var
  LPName: PString;
begin
  if FCount = FCapacity then
    Grow;

  Result := @FItems[FCount];
  LPName := @FNames[FCount];

  Pointer(LPName^) := Pointer(AName);
  Pointer(AName) := nil;

  if FFirstUnsortedNameIndex = -1 then
    FFirstUnsortedNameIndex := FCount;

  Inc(FCount);

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

procedure TJSONObject.SetValueString(const AName, AValue: string);
begin
  RequireItem(AName).Value := AValue;
end;

procedure TJsonObject.SortUnsortedNames;
var
  LIndex: Integer;
begin
  if FFirstUnsortedNameIndex <> -1 then
  begin
    if FCount <> 0 then
    begin
      if FCount - FFirstUnsortedNameIndex = 1 then
      begin
        LIndex := InternFindSortedNameInsertIndex(FFirstUnsortedNameIndex);

        if LIndex < FFirstUnsortedNameIndex then
          Move(FSortedNames[LIndex], FSortedNames[LIndex + 1], (FFirstUnsortedNameIndex - LIndex) * SizeOf(FSortedNames[0]));

        FSortedNames[LIndex] := FFirstUnsortedNameIndex;
      end
      else
      begin
        for LIndex := 0 to FCount - 1 do
          FSortedNames[LIndex] := LIndex;

        QuickSortNames(0, FCount - 1);
      end;
    end;

    FFirstUnsortedNameIndex := -1;
  end;
end;

function TJSONObject.Contains(const AName: string): Boolean;
begin
  Result := IndexOf(AName) <> -1;
end;

function TJSONObject.IndexOfPChar(const AValue: PChar; const ALength: Integer): Integer;
var
  LPArray: PJSONStringArray;
begin
  LPArray := FNames;

  if ALength = 0 then
  begin
    for Result := 0 to FCount - 1 do
    if LPArray[Result].IsEmpty then
      Exit
  end
  else
  for Result := 0 to FCount - 1 do
  if (Length(LPArray[Result]) = ALength) and CompareMem(AValue, Pointer(LPArray[Result]), ALength * SizeOf(Char)) then
    Exit;

  Result := -1;
end;

function TJSONObject.IndexOf(const AName: string): Integer;
begin
  if FFirstUnsortedNameIndex <> -1 then
    SortUnsortedNames;

  Result := InternIndexOfSortedName(AName);

  if Result <> -1 then
    Result := FSortedNames[Result];
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
var
  LSortIndex, LNameIndex, LSortCount: Integer;
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    ListError(@SListIndexError, AIndex);

  LSortCount := FFirstUnsortedNameIndex;

  if LSortCount = -1 then
    LSortCount := FCount;

  for LSortIndex := LSortCount - 1 downto 0 do
  begin
    LNameIndex := FSortedNames[LSortIndex];

    if LNameIndex = AIndex then
      InternDeleteSortedName(LSortIndex)
    else
    if LNameIndex > AIndex then
      Dec(FSortedNames[LSortIndex]);
  end;

  if (FFirstUnsortedNameIndex <> -1) and (FFirstUnsortedNameIndex < AIndex) then
    Dec(FFirstUnsortedNameIndex);

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
  if not FindItem(AName, Result.FData.Intern) then
  begin
    Result.FData.Intern := nil;
    Result.FData.NameResolver := Self;
    Result.FData.Name := AName;
  end;

  Result.FData.DataType := jdtNone;
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

function TJsonObject.InternFindSortedNameInsertIndex(const AIndex: Integer): Integer;
var
  LCount, LMiddle, LValue, LLength: Integer;
  LName: string;
begin
  Result := 0;

  LName := FNames[AIndex];
  LLength := LName.Length;;

  if FFirstUnsortedNameIndex <> -1 then
    LCount := FFirstUnsortedNameIndex - 1
  else
    LCount := FCount - 1;

  while Result <= LCount do
  begin
    LMiddle := (Result + LCount) shr 1;
    LValue := FNames[FSortedNames[LMiddle]].Length - LLength;

    if LValue = 0 then
      LValue := CompareStr(FNames[FSortedNames[LMiddle]], LName);

    if LValue < 0 then
      Result := LMiddle + 1
    else
    begin
      LCount := LMiddle - 1;

      if LCount = 0 then
        Exit(LMiddle);
    end;
  end;
end;

function TJsonObject.InternIndexOfSortedName(const AName: string): Integer;
var
  LCount, LMiddle, LValue: Integer;
  LLength: Integer;
begin
  Result := 0;

  LLength := AName.Length;
  LCount := FCount - 1;

  while Result <= LCount do
  begin
    LMiddle := (Result + LCount) shr 1;
    LValue := FNames[FSortedNames[LMiddle]].Length - LLength;

    if LValue = 0 then
      LValue := CompareStr(FNames[FSortedNames[LMiddle]], AName);

    if LValue < 0 then
      Result := LMiddle + 1
    else
    begin
      LCount := LMiddle - 1;

      if LValue = 0 then
        Exit(LMiddle);
    end;
  end;

  Result := -1;
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
      FSortedNames[LIndex] := ASource.FSortedNames[LIndex];
      FFirstUnsortedNameIndex := ASource.FFirstUnsortedNameIndex;
      InternInitAndAssignItem(@FItems[LIndex], @ASource.FItems[LIndex]);
    end;
  end
  else
  begin
    FreeMem(FItems);
    FreeMem(FNames);
    FreeMem(FSortedNames);

    FCapacity := 0;
  end;
end;

procedure TJSONObject.PathError(const AValue, AValueEnd: PChar);
var
  LValue: string;
begin
  System.SetString(LValue, AValue, AValueEnd - AValue);

  raise EJSONPathException.CreateResFmt(@STextEditorInvalidJSONPath, [LValue]);
end;

procedure TJSONObject.PathNullError(const AValue, AValueEnd: PChar);
var
  LValue: string;
begin
  System.SetString(LValue, AValue, AValueEnd - AValue);

  raise EJSONPathException.CreateResFmt(@STextEditorJSONPathContainsNullValue, [LValue]);
end;

procedure TJsonObject.QuickSortNames(ALeft, ARight: Integer);
var
  LIndex, LRight, LMiddle, LValue: Integer;
begin
  repeat
    LIndex := ALeft;
    LRight := ARight;
    LMiddle := (ALeft + ARight) shr 1;

    repeat
      while CompareSortedName(LIndex, LMiddle) < 0 do
        Inc(LIndex);

      while CompareSortedName(LRight, LMiddle) > 0 do
        Dec(LRight);

      if LIndex <= LRight then
      begin
        if LIndex <> LRight then
        begin
          LValue := FSortedNames[LRight];

          FSortedNames[LRight] := FSortedNames[LIndex];
          FSortedNames[LIndex] := LValue
        end;

        if LMiddle = LIndex then
          LMiddle := LRight
        else
        if LMiddle = LRight then
          LMiddle := LIndex;

        Inc(LIndex);
        Dec(LRight);
      end;
    until LIndex > LRight;

    if ALeft < LRight then
    begin
      if LRight - ALeft <= ARight - LIndex then
      begin
        QuickSortNames(ALeft, LRight);

        ALeft := LIndex;
      end
      else
      begin
        QuickSortNames(LIndex, ARight);

        ARight := LRight;
        LIndex := ALeft;
      end;
    end
    else
      ALeft := LIndex;
  until LIndex >= ARight;
end;

procedure TJSONObject.PathIndexError(const AValue, AValueEnd: PChar; const ACount: Integer);
var
  LValue: string;
begin
  System.SetString(LValue, AValue, AValueEnd - AValue);

  raise EJSONPathException.CreateResFmt(@STextEditorJSONPathIndexError, [ACount, LValue]);
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
    Exit(Self);

  Result.FData.Intern := nil;
  Result.FData.DataType := jdtNone;

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
              Result.FData.Intern := @LObject.FItems[LIndex]
            else
            begin
              Result.FData.NameResolver := LObject;
              System.SetString(Result.FData.Name, LPFirstChar, LPEndChar - LPFirstChar);
            end;
          end
          else
            Result.FData.Intern := LDataValue;

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
            Result.FData.Intern := LDataValue;
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
  TJSONDataValueHelper.SetInternValue(LPathValue.FData.Intern, AValue);
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

procedure TStringIntern.Intern(var AValue: string; var APropName: string);
var
  LIndex: Integer;
  LHash: Integer;
  LSource: Pointer;
begin
  if not APropName.IsEmpty then
    APropName := '';

  if not AValue.IsEmpty then
  begin
    LHash := GetHash(AValue);
    LIndex := Find(LHash, AValue);

    if LIndex = -1 then
    begin
      Pointer(APropName) := Pointer(AValue);
      Pointer(AValue) := nil;
      InternAdd(LHash, APropName);
    end
    else
    begin
      LSource := Pointer(FStrings[LIndex].Name);

      if LSource <> nil then
      begin
        Pointer(APropName) := LSource;
        Inc(PInteger(@PByte(LSource)[-8])^);
      end;

      AValue := '';
    end
  end;
end;

class function TStringIntern.GetHash(const AName: string): Integer;
label
  Pad2, Pad1;
const
  FNV_PRIME = $01000193;
  FNV_SEED  = $811C9DC5;
var
  LLength: NativeInt;
  LPChar: PWideChar;
begin
  Result := 0;

  LPChar := PWideChar(Pointer(AName));

  if LPChar <> nil then
  begin
    LLength := PStrRec(@PByte(AName)[-SizeOf(TStrRec)]).Length;
    LPChar := @LPChar[LLength];
    LLength := -LLength + 4;

    Result := Integer(FNV_SEED);

    while LLength <= 0 do
    begin
      Result := (Result xor Word(LPChar[LLength - 4])) * FNV_PRIME;
      Result := (Result xor Word(LPChar[LLength - 3])) * FNV_PRIME;
      Result := (Result xor Word(LPChar[LLength - 2])) * FNV_PRIME;
      Result := (Result xor Word(LPChar[LLength - 1])) * FNV_PRIME;
      Inc(LLength, 4);
    end;

    case 4 - LLength of
      3:
        begin
          Result := (Result xor Word(LPChar[-3])) * FNV_PRIME;
          goto Pad2;
        end;
      2:
        begin
Pad2:
          Result := (Result xor Word(LPChar[-2])) * FNV_PRIME;
          goto Pad1;
        end;
      1:
        begin
Pad1:
          Result := (Result xor Word(LPChar[-1])) * FNV_PRIME;
        end;
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

procedure TJSONOutputWriter.AppendLine(const AType: TLastType; const AValue: string);
begin
  if FLastType = AType then
    FLastLine.Append(AValue)
  else
  begin
    FlushLastLine;
    StreamFlushPossible;
    FLastLine.Append2(FIndents[FIndent], PChar(Pointer(AValue)), AValue.Length);
  end;
end;

procedure TJSONOutputWriter.Indent(const AValue: string);
var
  LSelf: ^TJSONOutputWriter;
begin
  LSelf := @Self;

  if LSelf.FCompact then
  begin
    LSelf.FStringBuffer.Append(AValue);
    LSelf.StreamFlushPossible;
  end
  else
  begin
    LSelf.AppendLine(ltIntro, AValue);

    Inc(LSelf.FIndent);

    if LSelf.FIndent >= LSelf.FIndentsLen then
      ExpandIndents;

    LSelf.FLastType := ltIndent;
  end;
end;

procedure TJSONOutputWriter.Unindent(const AValue: string);
var
  LSelf: ^TJSONOutputWriter;
begin
  LSelf := @Self;

  if LSelf.FCompact then
  begin
    LSelf.FStringBuffer.Append(AValue);
    LSelf.StreamFlushPossible;
  end
  else
  begin
    Dec(LSelf.FIndent);

    LSelf.AppendLine(ltIndent, AValue);
    LSelf.FLastType := ltUnindent;
  end;
end;

procedure TJSONOutputWriter.AppendIntro(const AValue: PChar; const ALength: Integer);
const
  sQuoteCharColon = '":';
var
  LOutputWriter: ^TJSONOutputWriter;
begin
  LOutputWriter := @Self;

  if LOutputWriter.FCompact then
  begin
    LOutputWriter.FStringBuffer.Append2(sQuoteChar, AValue, ALength).Append(sQuoteCharColon, 2);
    LOutputWriter.StreamFlushPossible;
  end
  else
  begin
    FlushLastLine;
    LOutputWriter.StreamFlushPossible;
    LOutputWriter.FLastLine.Append(LOutputWriter.FIndents[LOutputWriter.FIndent]).Append2(sQuoteChar, AValue, ALength).Append('": ', 3);
    LOutputWriter.FLastType := ltIntro;
  end;
end;

procedure TJSONOutputWriter.AppendValue(const AValue: string);
var
  LOutputWriter: ^TJSONOutputWriter;
begin
  LOutputWriter := @Self;

  if LOutputWriter.FCompact then
  begin
    LOutputWriter.FStringBuffer.Append(AValue);
    LOutputWriter.StreamFlushPossible;
  end
  else
  begin
    LOutputWriter.AppendLine(ltIntro, AValue);
    LOutputWriter.FLastType := ltValue;
  end;
end;

procedure TJSONOutputWriter.AppendStrValue(const AValue: PChar; const ALength: Integer);
var
  LOutputWriter: ^TJSONOutputWriter;
begin
  LOutputWriter := @Self;

  if LOutputWriter.FCompact then
  begin
    LOutputWriter.FStringBuffer.Append3(sQuoteChar, AValue, ALength, sQuoteChar);
    LOutputWriter.StreamFlushPossible;
  end
  else
  begin
    if LOutputWriter.FLastType = ltIntro then
      LOutputWriter.FLastLine.Append3(sQuoteChar, AValue, ALength, sQuoteChar)
    else
    begin
      FlushLastLine;
      LOutputWriter.StreamFlushPossible;
      LOutputWriter.FLastLine.Append(LOutputWriter.FIndents[LOutputWriter.FIndent]).Append3(sQuoteChar, AValue, ALength,
        sQuoteChar);
    end;

    LOutputWriter.FLastType := ltValue;
  end;
end;

procedure TJSONOutputWriter.AppendSeparator(const AValue: string);
var
  LOutputWriter: ^TJSONOutputWriter;
begin
  LOutputWriter := @Self;

  if LOutputWriter.FCompact then
  begin
    LOutputWriter.FStringBuffer.Append(AValue);
    LOutputWriter.StreamFlushPossible;
  end
  else
  begin
    if LOutputWriter.FLastType in [ltValue, ltUnindent] then
      LOutputWriter.FLastLine.Append(AValue)
    else
    begin
      FlushLastLine;
      LOutputWriter.StreamFlushPossible;
      LOutputWriter.FLastLine.Append2(LOutputWriter.FIndents[LOutputWriter.FIndent], PChar(Pointer(AValue)), AValue.Length);
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
var
  LPChar, LPEndChar: PByte;
  LChar: Byte;
  LEndReached: Boolean;
begin
  LPChar := FText;
  LPEndChar := FTextEnd;
  LEndReached := False;

  while True do
  begin
    LChar := 0;

    while True do
    begin
      if LPChar = LPEndChar then
      begin
        LEndReached := True;
        Break;
      end;

      LChar := LPChar^;

      if LChar > 32 then
        Break;

      if not (LChar in [9, 32]) then
        Break;

      Inc(LPChar);
    end;

    if LEndReached then
      Break;

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
  Result.FData.Name := '';
  Result.FData.NameResolver := nil;
  Result.FData.Intern := nil;
  Result.FData.DataType := jdtString;
  Result.FData.Value := AValue;
end;

class operator TJSONDataValueHelper.Implicit(const AValue: TJSONDataValueHelper): string;
begin
  if AValue.FData.Intern <> nil then
    Result := AValue.FData.Intern.Value
  else
  case AValue.FData.DataType of
    jdtString:
      Result := AValue.FData.Value;
    jdtBool:
      if AValue.FData.BoolValue then
        Result := sTrue
      else
        Result := sFalse;
  else
    Result := '';
  end;
end;

class operator TJSONDataValueHelper.Implicit(const AValue: Boolean): TJSONDataValueHelper;
begin
  Result.FData.Name := '';
  Result.FData.NameResolver := nil;
  Result.FData.Intern := nil;
  Result.FData.DataType := jdtBool;
  Result.FData.BoolValue := AValue;
end;

class operator TJSONDataValueHelper.Implicit(const AValue: TJSONDataValueHelper): Boolean;
begin
  if AValue.FData.Intern <> nil then
    Result := AValue.FData.Intern.BoolValue
  else
  case AValue.FData.DataType of
    jdtString:
      Result := AValue.FData.Value = 'true';
    jdtBool:
      Result := AValue.FData.BoolValue;
  else
    Result := False;
  end;
end;

class operator TJSONDataValueHelper.Implicit(const AValue: TJSONArray): TJSONDataValueHelper;
begin
  Result.FData.Name := '';
  Result.FData.NameResolver := nil;
  Result.FData.Intern := nil;
  Result.FData.DataType := jdtArray;
  Result.FData.ObjectValue := AValue;
end;

class operator TJSONDataValueHelper.Implicit(const AValue: TJSONDataValueHelper): TJSONArray;
begin
  AValue.ResolveName;

  if AValue.FData.Intern <> nil then
  begin
    if AValue.FData.Intern.FDataType = jdtNone then
      AValue.FData.Intern.ArrayValue := TJSONArray.Create;

    Result := AValue.FData.Intern.ArrayValue;
  end
  else
  if AValue.FData.DataType = jdtArray then
    Result := TJSONArray(AValue.FData.ObjectValue)
  else
    Result := nil;
end;

class operator TJSONDataValueHelper.Implicit(const AValue: TJSONObject): TJSONDataValueHelper;
begin
  Result.FData.Name := '';
  Result.FData.NameResolver := nil;
  Result.FData.Intern := nil;
  Result.FData.DataType := jdtObject;
  Result.FData.ObjectValue := AValue;
end;

class operator TJSONDataValueHelper.Implicit(const AValue: TJSONDataValueHelper): TJSONObject;
begin
  AValue.ResolveName;

  if AValue.FData.Intern <> nil then
  begin
    if AValue.FData.Intern.FDataType = jdtNone then
      AValue.FData.Intern.ObjectValue := TJSONObject.Create;

    Result := AValue.FData.Intern.ObjectValue;
  end
  else
  if AValue.FData.DataType = jdtObject then
    Result := TJSONObject(AValue.FData.ObjectValue)
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

  if FData.Intern <> nil then
    FData.Intern.Value := AValue
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

  if FData.Intern <> nil then
    FData.Intern.BoolValue := AValue
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

  if FData.Intern <> nil then
    FData.Intern.ArrayValue := AValue
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

  if FData.Intern <> nil then
    FData.Intern.ObjectValue := AValue
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

function TJSONDataValueHelper.ToInt(const ADefault: Integer): Integer;
var
  LErrorCode: Integer;
begin
  Val(Self, Result, LErrorCode);

  if LErrorCode <> 0 then
    Result := ADefault;
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
  if FData.Intern <> nil then
    Result := FData.Intern.DataType
  else
    Result := FData.DataType;
end;

class procedure TJSONDataValueHelper.SetInternValue(const AItem: PJSONDataValue; const AValue: TJSONDataValueHelper);
begin
  AValue.ResolveName;

  if AValue.FData.Intern <> nil then
  begin
    AItem.Clear;
    TJSONBaseObject.InternInitAndAssignItem(AItem, AValue.FData.Intern);
  end
  else
  case AValue.FData.DataType of
    jdtString:
      AItem.Value := AValue.FData.Value;
    jdtBool:
      AItem.BoolValue := AValue.FData.BoolValue;
    jdtArray:
      AItem.ArrayValue := TJSONArray(AValue.FData.ObjectValue);
    jdtObject:
      AItem.ObjectValue := TJSONObject(AValue.FData.ObjectValue);
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
  if not Assigned(FData.Intern) and Assigned(FData.NameResolver) then
  begin
    FData.Intern := FData.NameResolver.RequireItem(FData.Name);
    FData.NameResolver := nil;
    FData.Name := '';
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

procedure TJSONOutputWriter.TJSONStringBuilder.DoneConvertToString(var AValue: string);
var
  LPStrRec: PStrRec;
  LPChar: PChar;
begin
  AValue := '';

  if FData <> nil then
  begin
    LPStrRec := PStrRec(PByte(FData) - SizeOf(TStrRec));

    if DataLength <> FCapacity then
      ReallocMem(Pointer(LPStrRec), SizeOf(TStrRec) + (FDataLength + 1) * SizeOf(Char));

    LPStrRec.Length := DataLength;
    LPChar := PChar(PByte(LPStrRec) + SizeOf(TStrRec));
    LPChar[DataLength] := #0;
    Pointer(AValue) := LPChar;
  end;
end;

function TJSONOutputWriter.TJSONStringBuilder.FlushToBytes(var ABytes: PByte; var ASize: NativeInt; const AEncoding: TEncoding): NativeInt;
begin
  if FDataLength > 0 then
  begin
    Result := TEncodingStrictAccess(AEncoding).GetByteCountEx(FData, FDataLength);

    if Result > 0 then
    begin
      if Result > ASize then
      begin
        ASize := (Result + 4095) and not 4095;
        ReallocMem(ABytes, ASize);
      end;

      TEncodingStrictAccess(AEncoding).GetBytesEx(FData, FDataLength, ABytes, Result);
    end;

    FDataLength := 0;
  end
  else
    Result := 0;
end;

procedure TJSONOutputWriter.TJSONStringBuilder.FlushToMemoryStream(const AStream: TMemoryStream; const AEncoding: TEncoding);
var
  LByteCount: Integer;
  LIndex, LNewSize: NativeInt;
begin
  if FDataLength > 0 then
  begin
    LByteCount := TEncodingStrictAccess(AEncoding).GetByteCountEx(FData, FDataLength);

    if LByteCount > 0 then
    begin
      LIndex := AStream.Position;
      LNewSize := LIndex + LByteCount;

      if LNewSize > TMemoryStreamAccess(AStream).Capacity then
        TMemoryStreamAccess(AStream).Capacity := LNewSize;

      TEncodingStrictAccess(AEncoding).GetBytesEx(FData, FDataLength, @PByte(AStream.Memory)[LIndex], LByteCount);
      TMemoryStreamAccess(AStream).SetPointer(AStream.Memory, LNewSize);
      AStream.Position := LNewSize;
    end;
  end;

  FDataLength := 0;
end;

procedure TJSONOutputWriter.TJSONStringBuilder.Grow(const ALength: Integer);
var
  LCapacity: Integer;
  LPStrRec: PStrRec;
  LLength: Integer;
begin
  LCapacity := FCapacity;
  LCapacity := LCapacity * 2;

  LLength := Max(ALength, 256);

{$IFNDEF CPUX64}
  if LCapacity > 256 * 1024 * 1024 then
  begin
    LCapacity := FCapacity;
    LCapacity := LCapacity + (LCapacity div 3);

    if LCapacity < LLength then
      LCapacity := LLength;
  end
  else
{$ENDIF ~CPUX64}
  if LCapacity < LLength then
    LCapacity := LLength;

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
  LValueLength := AValue.Length;

  if LValueLength > 0 then
  begin
    if LDataLength + LValueLength >= FCapacity then
      Grow(LDataLength + LValueLength);

    case LValueLength of
      1: FData[LDataLength] := PChar(Pointer(AValue))^;
      2: PLongWord(@FData[LDataLength])^ := PLongWord(Pointer(AValue))^;
    else
      Move(PChar(Pointer(AValue))[0], FData[LDataLength], LValueLength * SizeOf(Char));
    end;

    FDataLength := LDataLength + LValueLength;
  end;

  Result := @Self;
end;

procedure TJSONOutputWriter.TJSONStringBuilder.Append(const AValue: PChar; const ALength: Integer);
var
  LLength: Integer;
begin
  LLength := FDataLength;

  if ALength > 0 then
  begin
    if LLength + ALength >= FCapacity then
      Grow(LLength + ALength);

    case ALength of
      1: FData[LLength] := AValue^;
      2: PLongWord(@FData[LLength])^ := PLongWord(AValue)^;
    else
      Move(AValue[0], FData[LLength], ALength * SizeOf(Char));
    end;

    FDataLength := LLength + ALength;
  end;
end;

function TJSONOutputWriter.TJSONStringBuilder.Append2(const AValue1: string; AValue2: PChar; AValue2Length: Integer): PJSONStringBuilder;
var
  LLength, LString1Length, LDataLength: Integer;
begin
  LDataLength := FDataLength;
  LString1Length := AValue1.Length;
  LLength := LString1Length + AValue2Length;

  if LDataLength + LLength >= FCapacity then
    Grow(LDataLength + LLength);

  case LString1Length of
    0: ;
    1: FData[LDataLength] := PChar(Pointer(AValue1))^;
    2: PLongWord(@FData[LDataLength])^ := PLongWord(Pointer(AValue1))^;
  else
    Move(PChar(Pointer(AValue1))[0], FData[LDataLength], LString1Length * SizeOf(Char));
  end;

  Inc(LDataLength, LString1Length);

  case AValue2Length of
    0: ;
    1: FData[LDataLength] := AValue2^;
    2: PLongWord(@FData[LDataLength])^ := PLongWord(Pointer(AValue2))^;
  else
    Move(AValue2[0], FData[LDataLength], AValue2Length * SizeOf(Char));
  end;

  FDataLength := LDataLength + AValue2Length;

  Result := @Self;
end;

procedure TJSONOutputWriter.TJSONStringBuilder.Append2(const AChar1: Char; const AChar2: Char);
var
  LDataLength: Integer;
begin
  LDataLength := FDataLength;

  if LDataLength + 2 >= FCapacity then
    Grow(2);

  FData[LDataLength] := AChar1;
  FData[LDataLength + 1] := AChar2;
  FDataLength := LDataLength + 2;
end;

procedure TJSONOutputWriter.TJSONStringBuilder.Append3(const AChar1: Char; const AValue2, AValue3: string);
var
  LLength, LString2Length, LString3Length, LDataLength: Integer;
begin
  LDataLength := FDataLength;
  LString2Length := AValue2.Length;
  LString3Length := AValue3.Length;
  LLength := 1 + LString2Length + LString3Length;

  if LDataLength + LLength >= FCapacity then
    Grow(LDataLength + LLength);

  FData[LDataLength] := AChar1;
  Inc(LDataLength);

  case LString2Length of
    0: ;
    1: FData[LDataLength] := PChar(Pointer(AValue2))^;
    2: PLongWord(@FData[LDataLength])^ := PLongWord(Pointer(AValue2))^;
  else
    Move(PChar(Pointer(AValue2))[0], FData[LDataLength], LString2Length * SizeOf(Char));
  end;

  Inc(LDataLength, LString2Length);

  case LString3Length of
    1: FData[LDataLength] := PChar(Pointer(AValue3))^;
    2: PLongWord(@FData[LDataLength])^ := PLongWord(Pointer(AValue3))^;
  else
    Move(PChar(Pointer(AValue3))[0], FData[LDataLength], LString3Length * SizeOf(Char));
  end;

  FDataLength := LDataLength + LString3Length;
end;

procedure TJSONOutputWriter.TJSONStringBuilder.Append3(const AChar1: Char; const AChar2: PChar;
  const AChar2Length: Integer; const AChar3: Char);
var
  LLength, LDataLength: Integer;
begin
  LDataLength := FDataLength;
  LLength := 2 + AChar2Length;

  if LDataLength + LLength >= FCapacity then
    Grow(LDataLength + LLength);

  FData[LDataLength] := AChar1;
  Inc(LDataLength);

  case AChar2Length of
    0: ;
    1: FData[LDataLength] := AChar2^;
    2: PLongWord(@FData[LDataLength])^ := PLongWord(AChar2)^;
  else
    Move(AChar2[0], FData[LDataLength], AChar2Length * SizeOf(Char));
  end;

  Inc(LDataLength, AChar2Length);

  FData[LDataLength] := AChar1;
  FDataLength := LDataLength + 1;
end;

procedure TJSONOutputWriter.TJSONStringBuilder.Append3(const AChar1: Char; const AValue2: string; const AChar3: Char);
begin
  Append3(AChar1, PChar(Pointer(AValue2)), AValue2.Length, AChar3);
end;

procedure TJSONOutputWriter.TJSONStringBuilder.FlushToStringBuffer(var ABuffer: TJSONStringBuilder);
begin
  ABuffer.Append(FData, FDataLength);
  FDataLength := 0;
end;

procedure TJSONOutputWriter.TJSONStringBuilder.FlushToString(var AValue: string);
begin
  System.SetString(AValue, FData, FDataLength);
  FDataLength := 0;
end;

initialization

  UniqueString(sTrue);
  UniqueString(sFalse);

end.
