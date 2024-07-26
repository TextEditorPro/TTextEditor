unit TextEditor.Undo.List;

interface

uses
  System.Classes, TextEditor.Types, TextEditor.Undo.Item;

type
  TTextEditorUndoList = class(TPersistent)
  protected
    FBlockCount: Integer;
    FBlockNumber: Integer;
    FChangeBlockNumber: Integer;
    FChanged: Boolean;
    FChangeCount: Integer;
    FInsideRedo: Boolean;
    FInsideUndoBlock: Boolean;
    FInsideUndoBlockCount: Integer;
    FItems: TList;
    FLockCount: Integer;
    FOnAddedUndo: TNotifyEvent;
    function GetCanUndo: Boolean;
    function GetItemCount: Integer;
    function GetItems(const AIndex: Integer): TTextEditorUndoItem;
    procedure SetItems(const AIndex: Integer; const AValue: TTextEditorUndoItem);
  public
    constructor Create;
    destructor Destroy; override;
    function PeekItem: TTextEditorUndoItem;
    function PopItem: TTextEditorUndoItem;
    function LastChangeBlockNumber: Integer; inline;
    function LastChangeReason: TTextEditorChangeReason; inline;
    function LastChangeString: string;
    procedure AddChange(AReason: TTextEditorChangeReason;
      const ACaretPosition, ASelectionBeginPosition, ASelectionEndPosition: TTextEditorTextPosition;
      const AChangeText: string; SelectionMode: TTextEditorSelectionMode; AChangeBlockNumber: Integer = 0);
    procedure BeginBlock(AChangeBlockNumber: Integer = 0);
    procedure Clear;
    procedure EndBlock;
    procedure Lock;
    procedure PushItem(const AItem: TTextEditorUndoItem);
    procedure Unlock;
  public
    procedure AddGroupBreak;
    procedure Assign(ASource: TPersistent); override;
    property BlockCount: Integer read FBlockCount;
    property CanUndo: Boolean read GetCanUndo;
    property Changed: Boolean read FChanged write FChanged;
    property ChangeCount: Integer read FChangeCount;
    property InsideRedo: Boolean read FInsideRedo write FInsideRedo default False;
    property InsideUndoBlock: Boolean read FInsideUndoBlock write FInsideUndoBlock default False;
    property ItemCount: Integer read GetItemCount;
    property Items[const AIndex: Integer]: TTextEditorUndoItem read GetItems write SetItems;
    property OnAddedUndo: TNotifyEvent read FOnAddedUndo write FOnAddedUndo;
  end;

implementation

const
  TEXTEDITOR_MODIFYING_CHANGE_REASONS = [crInsert, crPaste, crDragDropInsert, crDelete, crLineBreak, crIndent, crUnindent];

constructor TTextEditorUndoList.Create;
begin
  inherited;

  FItems := TList.Create;
  FInsideRedo := False;
  FInsideUndoBlock := False;
  FInsideUndoBlockCount := 0;
  FChangeCount := 0;
  FBlockNumber := 10;
end;

destructor TTextEditorUndoList.Destroy;
begin
  Clear;
  FItems.Free;
  inherited Destroy;
end;

procedure TTextEditorUndoList.Assign(ASource: TPersistent);
var
  LIndex: Integer;
  LUndoItem: TTextEditorUndoItem;
begin
  if Assigned(ASource) and (ASource is TTextEditorUndoList) then
  with ASource as TTextEditorUndoList do
  begin
    Self.Clear;

    for LIndex := 0 to (ASource as TTextEditorUndoList).FItems.Count - 1 do
    begin
      LUndoItem := TTextEditorUndoItem.Create;
      LUndoItem.Assign(FItems[LIndex]);
      Self.FItems.Add(LUndoItem);
    end;

    Self.FInsideUndoBlock := FInsideUndoBlock;
    Self.FBlockCount := FBlockCount;
    Self.FChangeBlockNumber := FChangeBlockNumber;
    Self.FLockCount := FLockCount;
    Self.FInsideRedo := FInsideRedo;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorUndoList.AddChange(AReason: TTextEditorChangeReason;
  const ACaretPosition, ASelectionBeginPosition, ASelectionEndPosition: TTextEditorTextPosition;
  const AChangeText: string; SelectionMode: TTextEditorSelectionMode; AChangeBlockNumber: Integer = 0);
var
  LNewItem: TTextEditorUndoItem;
begin
  if FLockCount = 0 then
  begin
    if not FChanged then
      FChanged := AReason in TEXTEDITOR_MODIFYING_CHANGE_REASONS;

    if AReason in TEXTEDITOR_MODIFYING_CHANGE_REASONS then
      Inc(FChangeCount);

    LNewItem := TTextEditorUndoItem.Create;
    with LNewItem do
    begin
      if AChangeBlockNumber <> 0 then
        ChangeBlockNumber := AChangeBlockNumber
      else
      if FInsideUndoBlock then
        ChangeBlockNumber := FChangeBlockNumber
      else
        ChangeBlockNumber := 0;

      ChangeReason := AReason;
      ChangeSelectionMode := SelectionMode;
      ChangeCaretPosition := ACaretPosition;
      ChangeBeginPosition := ASelectionBeginPosition;
      ChangeEndPosition := ASelectionEndPosition;
      ChangeString := AChangeText;
    end;

    PushItem(LNewItem);
  end;
end;

procedure TTextEditorUndoList.BeginBlock(AChangeBlockNumber: Integer = 0);
begin
  Inc(FBlockCount);

  if FInsideUndoBlock then
    Exit;

  if AChangeBlockNumber = 0 then
  begin
    Inc(FBlockNumber);
    FChangeBlockNumber := FBlockNumber;
  end
  else
    FChangeBlockNumber := AChangeBlockNumber;

  FInsideUndoBlockCount := FBlockCount;
  FInsideUndoBlock := True;
end;

procedure TTextEditorUndoList.Clear;
var
  LIndex: Integer;
begin
  FBlockCount := 0;

  for LIndex := 0 to FItems.Count - 1 do
    TTextEditorUndoItem(FItems[LIndex]).Free;

  FItems.Clear;
  FChangeCount := 0;
end;

procedure TTextEditorUndoList.EndBlock;
begin
  Assert(FBlockCount > 0);

  if FInsideUndoBlockCount = FBlockCount then
    FInsideUndoBlock := False;

  Dec(FBlockCount);
end;

function TTextEditorUndoList.GetCanUndo: Boolean;
begin
  Result := FItems.Count > 0;
end;

function TTextEditorUndoList.GetItemCount: Integer;
begin
  Result := FItems.Count;
end;

procedure TTextEditorUndoList.Lock;
begin
  Inc(FLockCount);
end;

function TTextEditorUndoList.PeekItem: TTextEditorUndoItem;
var
  LIndex: Integer;
begin
  Result := nil;

  LIndex := FItems.Count - 1;

  if LIndex >= 0 then
    Result := FItems[LIndex];
end;

function TTextEditorUndoList.PopItem: TTextEditorUndoItem;
var
  LIndex: Integer;
begin
  Result := nil;

  LIndex := FItems.Count - 1;

  if LIndex >= 0 then
  begin
    Result := FItems[LIndex];
    FItems.Delete(LIndex);
    FChanged := Result.ChangeReason in TEXTEDITOR_MODIFYING_CHANGE_REASONS;

    if FChanged then
      Dec(FChangeCount);
  end;
end;

procedure TTextEditorUndoList.PushItem(const AItem: TTextEditorUndoItem);
begin
  if Assigned(AItem) then
  begin
    FItems.Add(AItem);

    if (AItem.ChangeReason <> crGroupBreak) and Assigned(OnAddedUndo) then
      OnAddedUndo(Self);
  end;
end;

procedure TTextEditorUndoList.Unlock;
begin
  if FLockCount > 0 then
    Dec(FLockCount);
end;

function TTextEditorUndoList.LastChangeReason: TTextEditorChangeReason;
begin
  if FItems.Count = 0 then
    Result := crNothing
  else
    Result := TTextEditorUndoItem(FItems[FItems.Count - 1]).ChangeReason;
end;

function TTextEditorUndoList.LastChangeBlockNumber: Integer;
begin
  if FItems.Count = 0 then
    Result := 0
  else
    Result := TTextEditorUndoItem(FItems[FItems.Count - 1]).ChangeBlockNumber;
end;

function TTextEditorUndoList.LastChangeString: string;
begin
  if FItems.Count = 0 then
    Result := ''
  else
    Result := TTextEditorUndoItem(FItems[FItems.Count - 1]).ChangeString;
end;

procedure TTextEditorUndoList.AddGroupBreak;
var
  LTextPosition: TTextEditorTextPosition;
begin
  if (LastChangeBlockNumber = 0) and (LastChangeReason <> crGroupBreak) then
    AddChange(crGroupBreak, LTextPosition, LTextPosition, LTextPosition, '', smNormal);
end;

function TTextEditorUndoList.GetItems(const AIndex: Integer): TTextEditorUndoItem;
begin
  Result := TTextEditorUndoItem(FItems[AIndex]);
end;

procedure TTextEditorUndoList.SetItems(const AIndex: Integer; const AValue: TTextEditorUndoItem);
begin
  FItems[AIndex] := AValue;
end;

end.
