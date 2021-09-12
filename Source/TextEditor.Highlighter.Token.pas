unit TextEditor.Highlighter.Token;

interface

uses
  System.Classes, TextEditor.Highlighter.Attributes, TextEditor.Types;

type
  TTextEditorAbstractRule = class(TObject)
  strict private
    FTokenType: TTextEditorRangeType;
  public
    property TokenType: TTextEditorRangeType read FTokenType write FTokenType;
  end;

  TTextEditorAbstractToken = class(TObject)
  strict private
    FAttribute: TTextEditorHighlighterAttribute;
    FBreakType: TTextEditorBreakType;
    FOpenRule: TTextEditorAbstractRule;
  public
    constructor Create(const AHighlighterAttribute: TTextEditorHighlighterAttribute); reintroduce; overload;
    constructor Create(const AToken: TTextEditorAbstractToken); reintroduce; overload;
    constructor Create; reintroduce; overload;
    procedure Clear;
    property Attribute: TTextEditorHighlighterAttribute read FAttribute write FAttribute;
    property BreakType: TTextEditorBreakType read FBreakType write FBreakType;
    property OpenRule: TTextEditorAbstractRule read FOpenRule write FOpenRule;
  end;

  TTextEditorMultiToken = class(TTextEditorAbstractToken)
  strict private
    FSymbols: TStringList;
    function GetSymbol(const AIndex: Integer): string;
    procedure SetSymbol(const AIndex: Integer; const ASymbol: string);
  public
    constructor Create(const AMultiToken: TTextEditorMultiToken); reintroduce; overload;
    constructor Create; reintroduce; overload;
    destructor Destroy; override;
    function AddSymbol(const ASymbol: string): Integer;
    function SymbolCount: Integer;
    procedure Clear;
    procedure DeleteSymbol(const AIndex: Integer);
    property Symbols[const AIndex: Integer]: string read GetSymbol write SetSymbol;
  end;

  TTextEditorToken = class(TTextEditorAbstractToken)
  strict private
    FClosingToken: TTextEditorToken;
    FSymbol: string;
    FTemporary: Boolean;
  public
    constructor Create(const AHighlighterAttribute: TTextEditorHighlighterAttribute); overload;
    constructor Create(const AMultiToken: TTextEditorMultiToken; const AIndex: Integer); overload;
    constructor Create(const AToken: TTextEditorToken); overload;
    constructor Create; overload;
    procedure Clear;
    property ClosingToken: TTextEditorToken read FClosingToken write FClosingToken;
    property Symbol: string read FSymbol write FSymbol;
    property Temporary: Boolean read FTemporary write FTemporary;
  end;

  TTextEditorTokenNodeList = class;

  TTextEditorTokenNode = class(TObject)
  strict private
    FChar: Char;
    FBreakType: TTextEditorBreakType;
    FNextNodes: TTextEditorTokenNodeList;
    FToken: TTextEditorToken;
  public
    constructor Create(const AChar: Char); overload;
    constructor Create(const AChar: Char; const AToken: TTextEditorToken; const ABreakType: TTextEditorBreakType); overload;
    destructor Destroy; override;
    property BreakType: TTextEditorBreakType read FBreakType write FBreakType;
    property Char: Char read FChar write FChar;
    property NextNodes: TTextEditorTokenNodeList read FNextNodes write FNextNodes;
    property Token: TTextEditorToken read FToken write FToken;
  end;

  TTextEditorTokenNodeList = class(TObject)
  strict private
    FNodeList: TList;
  public
    constructor Create;
    destructor Destroy; override;
    function FindNode(const AChar: Char): TTextEditorTokenNode;
    function GetCount: Integer;
    function GetNode(const AIndex: Integer): TTextEditorTokenNode;
    procedure AddNode(const ANode: TTextEditorTokenNode);
    procedure SetNode(const AIndex: Integer; const AValue: TTextEditorTokenNode);
    property Count: Integer read GetCount;
    property Nodes[const Aindex: Integer]: TTextEditorTokenNode read GetNode write SetNode;
  end;

implementation

uses
  System.SysUtils, TextEditor.Utils;

{ TTextEditorAbstractToken }

constructor TTextEditorAbstractToken.Create;
begin
  inherited;

  FAttribute := nil;
  FOpenRule := nil;
  FBreakType := btUnspecified;
end;

constructor TTextEditorAbstractToken.Create(const AHighlighterAttribute: TTextEditorHighlighterAttribute);
begin
  Create;
  FAttribute := AHighlighterAttribute;
end;

constructor TTextEditorAbstractToken.Create(const AToken: TTextEditorAbstractToken);
begin
  inherited Create;
  FAttribute := AToken.Attribute;
  FBreakType := AToken.BreakType;
end;

procedure TTextEditorAbstractToken.Clear;
begin
  FBreakType := btUnspecified;
end;

{ TTextEditorMultiToken }

constructor TTextEditorMultiToken.Create;
begin
  inherited;

  FSymbols := TStringList.Create;
  BreakType := btUnspecified;
end;

constructor TTextEditorMultiToken.Create(const AMultiToken: TTextEditorMultiToken);
begin
  inherited Create(AMultiToken as TTextEditorAbstractToken);

  Create;
end;

destructor TTextEditorMultiToken.Destroy;
begin
  FSymbols.Free;
  FSymbols := nil;
  inherited;
end;

function TTextEditorMultiToken.AddSymbol(const ASymbol: string): Integer;
begin
  Result := FSymbols.Add(ASymbol);
end;

procedure TTextEditorMultiToken.Clear;
begin
  FSymbols.Clear;
end;

procedure TTextEditorMultiToken.DeleteSymbol(const AIndex: Integer);
begin
{$IFDEF TEXT_EDITOR_RANGE_CHECKS}
  if (AIndex > -1) and (AIndex < FSymbols.Count) then
{$ENDIF}
    FSymbols.Delete(AIndex)
end;

function TTextEditorMultiToken.GetSymbol(const AIndex: Integer): string;
begin
{$IFDEF TEXT_EDITOR_RANGE_CHECKS}
  Result := '';
  if (AIndex > -1) and (AIndex < FSymbols.Count) then
{$ENDIF}
    Result := FSymbols[AIndex]
end;

procedure TTextEditorMultiToken.SetSymbol(const AIndex: Integer; const ASymbol: string);
begin
{$IFDEF TEXT_EDITOR_RANGE_CHECKS}
  if (AIndex > -1) and (AIndex < FSymbols.Count) then
{$ENDIF}
    FSymbols[AIndex] := ASymbol
end;

function TTextEditorMultiToken.SymbolCount: Integer;
begin
  Result := FSymbols.Count;
end;

constructor TTextEditorToken.Create;
begin
  inherited Create;

  Symbol := '';
  FTemporary := False;
end;

constructor TTextEditorToken.Create(const AHighlighterAttribute: TTextEditorHighlighterAttribute);
begin
  inherited Create(AHighlighterAttribute);

  Symbol := '';
end;

constructor TTextEditorToken.Create(const AToken: TTextEditorToken);
begin
  inherited Create(AToken as TTextEditorAbstractToken);

  Symbol := AToken.Symbol;
end;

constructor TTextEditorToken.Create(const AMultiToken: TTextEditorMultiToken; const AIndex: Integer);
begin
  inherited Create(AMultiToken as TTextEditorAbstractToken);

  Symbol := AMultiToken.Symbols[AIndex];
end;

procedure TTextEditorToken.Clear;
begin
  Symbol := '';
end;

{ TTextEditorTokenNode }

constructor TTextEditorTokenNode.Create(const AChar: Char);
begin
  inherited Create;

  FChar := AChar;
  FNextNodes := TTextEditorTokenNodeList.Create;
  FToken := nil;
end;

constructor TTextEditorTokenNode.Create(const AChar: Char; const AToken: TTextEditorToken; const ABreakType: TTextEditorBreakType);
begin
  Create(AChar);
  FBreakType := ABreakType;
  FToken := AToken;
end;

destructor TTextEditorTokenNode.Destroy;
begin
  FNextNodes.Free;
  FNextNodes := nil;

  inherited;
end;

{ TTextEditorTokenNodeList }

constructor TTextEditorTokenNodeList.Create;
begin
  inherited;

  FNodeList := TList.Create;
end;

destructor TTextEditorTokenNodeList.Destroy;
begin
  FreeList(FNodeList);

  inherited;
end;

procedure TTextEditorTokenNodeList.AddNode(const ANode: TTextEditorTokenNode);
begin
  FNodeList.Add(ANode);
end;

function TTextEditorTokenNodeList.FindNode(const AChar: Char): TTextEditorTokenNode;
var
  LIndex: Integer;
  LTokenNode: TTextEditorTokenNode;
begin
  Result := nil;

  for LIndex := FNodeList.Count - 1 downto 0 do
  begin
    LTokenNode := TTextEditorTokenNode(FNodeList.List[LIndex]);
    if LTokenNode.Char = AChar then
      Exit(LTokenNode);
  end;
end;

function TTextEditorTokenNodeList.GetCount: Integer;
begin
  Result := FNodeList.Count;
end;

function TTextEditorTokenNodeList.GetNode(const AIndex: Integer): TTextEditorTokenNode;
begin
  Result := TTextEditorTokenNode(FNodeList[AIndex]);
end;

procedure TTextEditorTokenNodeList.SetNode(const AIndex: Integer; const AValue: TTextEditorTokenNode);
begin
  if AIndex < FNodeList.Count then
    TTextEditorTokenNode(FNodeList[AIndex]).Free;

  FNodeList[AIndex] := AValue;
end;

end.
