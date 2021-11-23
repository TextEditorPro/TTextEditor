unit TextEditor.CompletionProposal.Snippets;

interface

uses
  System.Classes, System.SysUtils, TextEditor.Types;

type
  TTextEditorCompletionProposalSnippetItemPosition = class(TPersistent)
  strict private
    FActive: Boolean;
    FColumn: Integer;
    FRow: Integer;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Active: Boolean read FActive write FActive default False;
    property Column: Integer read FColumn write FColumn default 0;
    property Row: Integer read FRow write FRow default 0;
  end;

  TTextEditorCompletionProposalSnippetItemSelection = class(TPersistent)
  strict private
    FActive: Boolean;
    FFromColumn: Integer;
    FFromRow: Integer;
    FToColumn: Integer;
    FToRow: Integer;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Active: Boolean read FActive write FActive default False;
    property FromColumn: Integer read FFromColumn write FFromColumn default 0;
    property FromRow: Integer read FFromRow write FFromRow default 0;
    property ToColumn: Integer read FToColumn write FToColumn default 0;
    property ToRow: Integer read FToRow write FToRow default 0;
  end;

  TTextEditorCompletionProposalSnippetItem = class(TCollectionItem)
  strict private
    FDescription: string;
    FExecuteWith: TTextEditorSnippetExecuteWith;
    FGroupName: string;
    FKeyword: string;
    FPosition: TTextEditorCompletionProposalSnippetItemPosition;
    FSelection: TTextEditorCompletionProposalSnippetItemSelection;
    FShortCut: TShortCut;
    FSnippet: TStrings;
    procedure SetSnippet(const AValue: TStrings);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
  published
    property Description: string read FDescription write FDescription;
    property ExecuteWith: TTextEditorSnippetExecuteWith read FExecuteWith write FExecuteWith default seListOnly;
    property Keyword: string read FKeyword write FKeyword;
    property Position: TTextEditorCompletionProposalSnippetItemPosition read FPosition write FPosition;
    property Selection: TTextEditorCompletionProposalSnippetItemSelection read FSelection write FSelection;
    property ShortCut: TShortCut read FShortCut write FShortCut default scNone;
    property Snippet: TStrings read FSnippet write SetSnippet;
  end;

  TTextEditorCompletionProposalSnippetItems = class(TOwnedCollection)
  protected
    function GetItem(const AIndex: Integer): TTextEditorCompletionProposalSnippetItem;
    procedure SetItem(const AIndex: Integer; const AValue: TTextEditorCompletionProposalSnippetItem);
  public
    function Add: TTextEditorCompletionProposalSnippetItem;
    function DoesKeywordExist(const AKeyword: string): Boolean;
    function Insert(const AIndex: Integer): TTextEditorCompletionProposalSnippetItem;
    property Items[const AIndex: Integer]: TTextEditorCompletionProposalSnippetItem read GetItem write SetItem;
  end;

  TTextEditorCompletionProposalSnippets = class(TPersistent)
  strict private
    FActive: Boolean;
    FItems: TTextEditorCompletionProposalSnippetItems;
    FOwner: TPersistent;
    function GetItem(const AIndex: Integer): TTextEditorCompletionProposalSnippetItem;
    procedure SetItems(const AValue: TTextEditorCompletionProposalSnippetItems);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(const AOwner: TPersistent);
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    property Item[const AIndex: Integer]: TTextEditorCompletionProposalSnippetItem read GetItem;
  published
    property Active: Boolean read FActive write FActive default True;
    property Items: TTextEditorCompletionProposalSnippetItems read FItems write SetItems;
  end;

  ETextEditorCompletionProposalSnippetException = class(Exception);

implementation

{ TTextEditorCompletionProposalSnippetItemPosition }

constructor TTextEditorCompletionProposalSnippetItemPosition.Create;
begin
  inherited;

  FActive := False;
  FColumn := 0;
  FRow := 0;
end;

procedure TTextEditorCompletionProposalSnippetItemPosition.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCompletionProposalSnippetItemPosition) then
  with ASource as TTextEditorCompletionProposalSnippetItemPosition do
  begin
    Self.FActive := FActive;
    Self.FColumn := FColumn;
    Self.FRow := FRow;
  end
  else
    inherited Assign(ASource);
end;

{ TTextEditorCompletionProposalSnippetItemSelection }

constructor TTextEditorCompletionProposalSnippetItemSelection.Create;
begin
  inherited;

  FActive := False;
  FFromColumn := 0;
  FFromRow := 0;
  FToColumn := 0;
  FToRow := 0;
end;

procedure TTextEditorCompletionProposalSnippetItemSelection.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCompletionProposalSnippetItemPosition) then
  with ASource as TTextEditorCompletionProposalSnippetItemPosition do
  begin
    Self.FActive := FActive;
    Self.FFromColumn := FFromColumn;
    Self.FFromRow := FFromRow;
    Self.FToColumn := FToColumn;
    Self.FToRow := FToRow;
  end
  else
    inherited Assign(ASource);
end;

{ TTextEditorCompletionProposalSnippetItem }

constructor TTextEditorCompletionProposalSnippetItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);

  FExecuteWith := seListOnly;
  FSnippet := TStringList.Create;
  FSnippet.TrailingLineBreak := False;
  FPosition := TTextEditorCompletionProposalSnippetItemPosition.Create;
  FSelection := TTextEditorCompletionProposalSnippetItemSelection.Create;
  FShortCut := scNone;
end;

destructor TTextEditorCompletionProposalSnippetItem.Destroy;
begin
  FSnippet.Free;
  FPosition.Free;
  FSelection.Free;

  inherited Destroy;
end;

procedure TTextEditorCompletionProposalSnippetItem.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCompletionProposalSnippetItem) then
  with ASource as TTextEditorCompletionProposalSnippetItem do
  begin
    Self.FDescription := FDescription;
    Self.FExecuteWith := FExecuteWith;
    Self.FGroupName := FGroupName;
    Self.FKeyword := FKeyword;
    Self.FPosition.Assign(FPosition);
    Self.FSelection.Assign(FSelection);
    Self.FShortCut := FShortCut;
    Self.FSnippet.Assign(FSnippet);
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorCompletionProposalSnippetItem.SetSnippet(const AValue: TStrings);
begin
  if AValue <> FSnippet then
    FSnippet.Assign(AValue);
end;

function TTextEditorCompletionProposalSnippetItem.GetDisplayName: string;
begin
  if FKeyword <> '' then
    Result := FKeyword
  else
    Result := '(unnamed)';
end;

{ TTextEditorCompletionProposalSnippetItems }

function TTextEditorCompletionProposalSnippetItems.GetItem(const AIndex: Integer): TTextEditorCompletionProposalSnippetItem;
begin
  Result := TTextEditorCompletionProposalSnippetItem(inherited GetItem(AIndex));
end;

procedure TTextEditorCompletionProposalSnippetItems.SetItem(const AIndex: Integer; const AValue: TTextEditorCompletionProposalSnippetItem);
begin
  inherited SetItem(AIndex, AValue);
end;

function TTextEditorCompletionProposalSnippetItems.DoesKeywordExist(const AKeyword: string): Boolean;
var
  LIndex: Integer;
begin
  Result := True;

  for LIndex := 0 to Count - 1 do
  if CompareText(Items[LIndex].Keyword, AKeyword) = 0 then
    Exit;

  Result := False;
end;

function TTextEditorCompletionProposalSnippetItems.Add: TTextEditorCompletionProposalSnippetItem;
begin
  Result := TTextEditorCompletionProposalSnippetItem(inherited Add);
end;

function TTextEditorCompletionProposalSnippetItems.Insert(const AIndex: Integer): TTextEditorCompletionProposalSnippetItem;
begin
  Result := Add;
  Result.Index := AIndex;
end;

{ TTextEditorCompletionProposalSnippets }

constructor TTextEditorCompletionProposalSnippets.Create(const AOwner: TPersistent);
begin
  inherited Create;

  FOwner := AOwner;
  FActive := True;
  FItems := TTextEditorCompletionProposalSnippetItems.Create(Self, TTextEditorCompletionProposalSnippetItem);
end;

destructor TTextEditorCompletionProposalSnippets.Destroy;
begin
  FItems.Free;

  inherited Destroy;
end;

procedure TTextEditorCompletionProposalSnippets.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCompletionProposalSnippets) then
  with ASource as TTextEditorCompletionProposalSnippets do
  begin
    Self.FActive := FActive;
    Self.FItems.Assign(FItems);
  end
  else
    inherited Assign(ASource);
end;

function TTextEditorCompletionProposalSnippets.GetItem(const AIndex: Integer): TTextEditorCompletionProposalSnippetItem;
begin
{$IFDEF TEXT_EDITOR_RANGE_CHECKS}
  if (AIndex < 0) or (AIndex > FItems.Count) then
    ListIndexOutOfBounds(AIndex);
{$ENDIF}
  Result := FItems.Items[AIndex];
end;

procedure TTextEditorCompletionProposalSnippets.SetItems(const AValue: TTextEditorCompletionProposalSnippetItems);
begin
  FItems.Assign(AValue);
end;

function TTextEditorCompletionProposalSnippets.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

end.
