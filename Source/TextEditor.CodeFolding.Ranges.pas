unit TextEditor.CodeFolding.Ranges;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, TextEditor.CodeFolding.Regions;

type
  TTextEditorCodeFoldingRange = class;
  TTextEditorAllCodeFoldingRanges = class;

  TTextEditorCodeFoldingRanges = class(TPersistent)
  strict private
    FList: TList;
    function GetCount: Integer;
    function GetItem(const AIndex: Integer): TTextEditorCodeFoldingRange;
  public
    constructor Create;
    destructor Destroy; override;
    function Add(const AAllCodeFoldingRanges: TTextEditorAllCodeFoldingRanges; const AFromLine, AIndentLevel, AFoldRangeLevel: Integer;
      const ARegionItem: TTextEditorCodeFoldingRegionItem; const AToLine: Integer = 0): TTextEditorCodeFoldingRange;
    procedure Clear;
    property Count: Integer read GetCount;
    property Items[const AIndex: Integer]: TTextEditorCodeFoldingRange read GetItem; default;
  end;

  TTextEditorAllCodeFoldingRanges = class(TTextEditorCodeFoldingRanges)
  strict private
    FList: TList;
    function GetAllCount: Integer;
    function GetItem(const AIndex: Integer): TTextEditorCodeFoldingRange;
    procedure SetItem(const AIndex: Integer; const Value: TTextEditorCodeFoldingRange);
  public
    constructor Create;
    destructor Destroy; override;
    procedure ClearAll;
    procedure Delete(const AFoldRange: TTextEditorCodeFoldingRange); overload;
    procedure Delete(const AIndex: Integer); overload;
    procedure SetParentCollapsedOfSubCodeFoldingRanges(const AFoldRange: TTextEditorCodeFoldingRange);
    procedure UpdateFoldRanges;
    property AllCount: Integer read GetAllCount;
    property Items[const AIndex: Integer]: TTextEditorCodeFoldingRange read GetItem write SetItem; default;
    property List: TList read FList;
  end;

  TTextEditorCodeFoldingRange = class
  strict private
    FAllCodeFoldingRanges: TTextEditorAllCodeFoldingRanges;
    FCollapsed: Boolean;
    FCollapsedBy: Integer;
    FCollapseMarkRect: TRect;
    FFoldRangeLevel: Integer;
    FFromLine: Integer;
    FIndentLevel: Integer;
    FIsExtraTokenFound: Boolean;
    FParentCollapsed: Boolean;
    FRegionItem: TTextEditorCodeFoldingRegionItem;
    FSubCodeFoldingRanges: TTextEditorCodeFoldingRanges;
    FToLine: Integer;
    FUndoListed: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function Collapsable: Boolean;
    procedure MoveBy(const ALineCount: Integer);
    procedure MoveChildren(const ABy: Integer);
    procedure SetParentCollapsedOfSubCodeFoldingRanges(const AParentCollapsed: Boolean; const ACollapsedBy: Integer);
    procedure Widen(const ALineCount: Integer);
    property AllCodeFoldingRanges: TTextEditorAllCodeFoldingRanges read FAllCodeFoldingRanges write FAllCodeFoldingRanges;
    property Collapsed: Boolean read FCollapsed write FCollapsed default False;
    property CollapsedBy: Integer read FCollapsedBy write FCollapsedBy;
    property CollapseMarkRect: TRect read FCollapseMarkRect write FCollapseMarkRect;
    property FoldRangeLevel: Integer read FFoldRangeLevel write FFoldRangeLevel;
    property FromLine: Integer read FFromLine write FFromLine;
    property IndentLevel: Integer read FIndentLevel write FIndentLevel;
    property IsExtraTokenFound: Boolean read FIsExtraTokenFound write FIsExtraTokenFound default False;
    property ParentCollapsed: Boolean read FParentCollapsed write FParentCollapsed;
    property RegionItem: TTextEditorCodeFoldingRegionItem read FRegionItem write FRegionItem;
    property SubCodeFoldingRanges: TTextEditorCodeFoldingRanges read FSubCodeFoldingRanges;
    property ToLine: Integer read FToLine write FToLine;
    property UndoListed: Boolean read FUndoListed write FUndoListed default False;
  end;

implementation

uses
  TextEditor.Utils;

{ TTextEditorAllCodeFoldingRanges }

constructor TTextEditorAllCodeFoldingRanges.Create;
begin
  inherited;

  FList := TList.Create;
end;

destructor TTextEditorAllCodeFoldingRanges.Destroy;
begin
  FreeList(FList);

  inherited;
end;

procedure TTextEditorAllCodeFoldingRanges.ClearAll;
begin
  Clear;
  ClearList(FList);
end;

procedure TTextEditorAllCodeFoldingRanges.Delete(const AFoldRange: TTextEditorCodeFoldingRange);
var
  LIndex: Integer;
begin
  for LIndex := FList.Count - 1 downto 0 do
  if FList[LIndex] = AFoldRange then
  begin
    TTextEditorCodeFoldingRange(FList[LIndex]).Free;
    FList[LIndex] := nil;
    FList.Delete(LIndex);
    Break;
  end;
end;

procedure TTextEditorAllCodeFoldingRanges.Delete(const AIndex: Integer);
begin
  FList.Delete(AIndex);
end;

function TTextEditorAllCodeFoldingRanges.GetAllCount: Integer;
begin
  Result := FList.Count;
end;

function TTextEditorAllCodeFoldingRanges.GetItem(const AIndex: Integer): TTextEditorCodeFoldingRange;
begin
  if Cardinal(AIndex) < Cardinal(FList.Count) then
    Result := FList.List[AIndex]
  else
    Result := nil;
end;

procedure TTextEditorAllCodeFoldingRanges.SetItem(const AIndex: Integer; const Value: TTextEditorCodeFoldingRange);
begin
  FList[AIndex] := Value;
end;

procedure TTextEditorAllCodeFoldingRanges.SetParentCollapsedOfSubCodeFoldingRanges(const AFoldRange: TTextEditorCodeFoldingRange);
var
	LIndex: Integer;
  LFoldRange: TTextEditorCodeFoldingRange;
begin
  for LIndex := 0 to AllCount - 1 do
  begin
    LFoldRange := GetItem(LIndex);

    if LFoldRange = AFoldRange then
      Continue;

    if LFoldRange.FromLine > AFoldRange.ToLine then
      Break;

    if (LFoldRange.FromLine > AFoldRange.FromLine) and (LFoldRange.FromLine <> AFoldRange.ToLine) then
      LFoldRange.ParentCollapsed := True;
  end;
end;

procedure TTextEditorAllCodeFoldingRanges.UpdateFoldRanges;
var
  LIndex: Integer;
  LFoldRange: TTextEditorCodeFoldingRange;
begin
  for LIndex := 0 to AllCount - 1 do
  begin
    LFoldRange := GetItem(LIndex);
    if Assigned(LFoldRange) then
      LFoldRange.ParentCollapsed := False;
  end;

  for LIndex := 0 to AllCount - 1 do
  begin
    LFoldRange := GetItem(LIndex);
    if Assigned(LFoldRange) and not LFoldRange.ParentCollapsed then
      SetParentCollapsedOfSubCodeFoldingRanges(LFoldRange);
  end;
end;

{ TTextEditorCodeFoldingRanges }

constructor TTextEditorCodeFoldingRanges.Create;
begin
  inherited;

  FList := TList.Create;
end;

destructor TTextEditorCodeFoldingRanges.Destroy;
begin
  FList.Clear;
  FList.Free;
  FList := nil;

  inherited;
end;

function TTextEditorCodeFoldingRanges.Add(const AAllCodeFoldingRanges: TTextEditorAllCodeFoldingRanges;
  const AFromLine, AIndentLevel, AFoldRangeLevel: Integer;
  const ARegionItem: TTextEditorCodeFoldingRegionItem; const AToLine: Integer): TTextEditorCodeFoldingRange;
begin
  Result := TTextEditorCodeFoldingRange.Create;
  with Result do
  begin
    FromLine := AFromLine;
    ToLine := AToLine;
    IndentLevel := AIndentLevel;
    FoldRangeLevel := AFoldRangeLevel;
    AllCodeFoldingRanges := AAllCodeFoldingRanges;
    RegionItem := ARegionItem;
  end;
  FList.Add(Result);
  AAllCodeFoldingRanges.List.Add(Result);
end;

procedure TTextEditorCodeFoldingRanges.Clear;
begin
  FList.Clear;
end;

function TTextEditorCodeFoldingRanges.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TTextEditorCodeFoldingRanges.GetItem(const AIndex: Integer): TTextEditorCodeFoldingRange;
begin
  Result := FList[AIndex];
end;

{ TTextEditorCodeFoldingRange }

function TTextEditorCodeFoldingRange.Collapsable: Boolean;
begin
  Result := (FFromLine < FToLine) or RegionItem.TokenEndIsPreviousLine and (FFromLine = FToLine);
end;

constructor TTextEditorCodeFoldingRange.Create;
begin
  inherited;

  FSubCodeFoldingRanges := TTextEditorCodeFoldingRanges.Create;
  FCollapsed := False;
  FCollapsedBy := -1;
  FIsExtraTokenFound := False;
  FUndoListed := False;
end;

destructor TTextEditorCodeFoldingRange.Destroy;
begin;
  FSubCodeFoldingRanges.Clear;
  FSubCodeFoldingRanges.Free;
  FSubCodeFoldingRanges := nil;

  inherited;
end;

procedure TTextEditorCodeFoldingRange.MoveBy(const ALineCount: Integer);
begin
  Inc(FFromLine, ALineCount);
  Inc(FToLine, ALineCount);
end;

procedure TTextEditorCodeFoldingRange.MoveChildren(const ABy: Integer);
var
  LIndex: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  for LIndex := 0 to FSubCodeFoldingRanges.Count - 1 do
  begin
    LCodeFoldingRange := FSubCodeFoldingRanges[LIndex];
    if Assigned(LCodeFoldingRange) then
    begin
      LCodeFoldingRange.MoveChildren(ABy);

      with FAllCodeFoldingRanges.List do
      if LCodeFoldingRange.FParentCollapsed then
        Move(IndexOf(LCodeFoldingRange), IndexOf(LCodeFoldingRange) + ABy);
    end;
  end;
end;

procedure TTextEditorCodeFoldingRange.SetParentCollapsedOfSubCodeFoldingRanges(const AParentCollapsed: Boolean; const ACollapsedBy: Integer);
var
  LIndex: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  if Assigned(FSubCodeFoldingRanges) then
  for LIndex := 0 to FSubCodeFoldingRanges.Count - 1 do
  begin
    LCodeFoldingRange := FSubCodeFoldingRanges[LIndex];
    LCodeFoldingRange.SetParentCollapsedOfSubCodeFoldingRanges(AParentCollapsed, ACollapsedBy);

    if (LCodeFoldingRange.FCollapsedBy = -1) or (LCodeFoldingRange.FCollapsedBy = ACollapsedBy) then
    begin
      LCodeFoldingRange.FParentCollapsed := AParentCollapsed;

      with LCodeFoldingRange do
      if not AParentCollapsed then
        FCollapsedBy := -1
      else
        FCollapsedBy := ACollapsedBy;
    end;
  end;
end;

procedure TTextEditorCodeFoldingRange.Widen(const ALineCount: Integer);
begin
  Inc(FToLine, ALineCount);
end;

end.
