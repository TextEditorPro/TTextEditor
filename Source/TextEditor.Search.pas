unit TextEditor.Search;

interface

uses
  System.Classes, TextEditor.Search.InSelection, TextEditor.Search.Map, TextEditor.Search.NearOperator, TextEditor.Types;

const
  TEXTEDITOR_SEARCH_OPTIONS = [soHighlightResults, soSearchOnTyping, soBeepIfStringNotFound, soShowSearchMatchNotFound];

type
  TTextEditorSearch = class(TPersistent)
  strict private
    FEnabled: Boolean;
    FEngine: TTextEditorSearchEngine;
    FInSelection: TTextEditorSearchInSelection;
    FItemIndex: Integer;
    FItems: TList;
    FMap: TTextEditorSearchMap;
    FNearOperator: TTextEditorSearchNearOperator;
    FOnChange: TTextEditorSearchChangeEvent;
    FOptions: TTextEditorSearchOptions;
    FResultPosition: TTextEditorResultPosition;
    FSearchText: string;
    FVisible: Boolean;
    procedure DoChange;
    procedure SetEnabled(const AValue: Boolean);
    procedure SetEngine(const AValue: TTextEditorSearchEngine);
    procedure SetInSelection(const AValue: TTextEditorSearchInSelection);
    procedure SetMap(const AValue: TTextEditorSearchMap);
    procedure SetNearOperator(const AValue: TTextEditorSearchNearOperator);
    procedure SetOnChange(const AValue: TTextEditorSearchChangeEvent);
    procedure SetSearchText(const AValue: string);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    function GetNextSearchItemIndex(const ATextPosition: TTextEditorTextPosition): Integer;
    function GetPreviousSearchItemIndex(const ATextPosition: TTextEditorTextPosition): Integer;
    procedure Assign(ASource: TPersistent); override;
    procedure ClearItems;
    procedure Execute;
    procedure SetOption(const AOption: TTextEditorSearchOption; const AEnabled: Boolean);
    property ItemIndex: Integer read FItemIndex write FItemIndex;
    property Items: TList read FItems write FItems;
    property Visible: Boolean read FVisible write SetVisible;
  published
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property Engine: TTextEditorSearchEngine read FEngine write SetEngine default seNormal;
    property InSelection: TTextEditorSearchInSelection read FInSelection write SetInSelection;
    property Map: TTextEditorSearchMap read FMap write SetMap;
    property NearOperator: TTextEditorSearchNearOperator read FNearOperator write SetNearOperator;
    property OnChange: TTextEditorSearchChangeEvent read FOnChange write SetOnChange;
    property Options: TTextEditorSearchOptions read FOptions write FOptions default TEXTEDITOR_SEARCH_OPTIONS;
    property ResultPosition: TTextEditorResultPosition read FResultPosition write FResultPosition default rpMiddle;
    property SearchText: string read FSearchText write SetSearchText;
  end;

implementation

constructor TTextEditorSearch.Create;
begin
  inherited;

  FEnabled := True;
  FEngine := seNormal;
  FInSelection := TTextEditorSearchInSelection.Create;
  FItemIndex := 0;
  FItems := TList.Create;
  FMap := TTextEditorSearchMap.Create;
  FNearOperator := TTextEditorSearchNearOperator.Create;
  FOptions := TEXTEDITOR_SEARCH_OPTIONS;
  FSearchText := '';
  FResultPosition := rpMiddle;
end;

destructor TTextEditorSearch.Destroy;
begin
  ClearItems;

  FInSelection.Free;
  FItems.Free;
  FMap.Free;
  FNearOperator.Free;

  inherited;
end;

procedure TTextEditorSearch.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorSearch) then
  with ASource as TTextEditorSearch do
  begin
    Self.FEnabled := FEnabled;
    Self.FSearchText := FSearchText;
    Self.FEngine := FEngine;
    Self.FOptions := FOptions;
    Self.FMap.Assign(FMap);
    Self.FInSelection.Assign(FInSelection);
    Self.FNearOperator.Assign(FNearOperator);

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorSearch.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(scRefresh);
end;

procedure TTextEditorSearch.SetOption(const AOption: TTextEditorSearchOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

procedure TTextEditorSearch.SetOnChange(const AValue: TTextEditorSearchChangeEvent);
begin
  FOnChange := AValue;
  FMap.OnChange := FOnChange;
  FInSelection.OnChange := FOnChange;
end;

procedure TTextEditorSearch.SetEngine(const AValue: TTextEditorSearchEngine);
begin
  if FEngine <> AValue then
  begin
    FEngine := AValue;

    if Assigned(FOnChange) then
      FOnChange(scEngineUpdate);
  end;
end;

procedure TTextEditorSearch.Execute;
begin
  if Assigned(FOnChange) then
    FOnChange(scSearch);
end;

procedure TTextEditorSearch.SetSearchText(const AValue: string);
begin
  FSearchText := AValue;

  Execute;
end;

procedure TTextEditorSearch.SetEnabled(const AValue: Boolean);
begin
  if FEnabled <> AValue then
  begin
    FEnabled := AValue;

    Execute;
  end;
end;

procedure TTextEditorSearch.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;

    if Assigned(FOnChange) then
      FOnChange(scVisible);
  end;
end;

procedure TTextEditorSearch.SetInSelection(const AValue: TTextEditorSearchInSelection);
begin
  FInSelection.Assign(AValue);
end;

procedure TTextEditorSearch.SetMap(const AValue: TTextEditorSearchMap);
begin
  FMap.Assign(AValue);
end;

procedure TTextEditorSearch.SetNearOperator(const AValue: TTextEditorSearchNearOperator);
begin
  FNearOperator.Assign(AValue);
end;

procedure TTextEditorSearch.ClearItems;
var
  LIndex: Integer;
begin
  for LIndex := FItems.Count - 1 downto 0 do
    Dispose(PTextEditorSearchItem(FItems[LIndex]));

  FItems.Clear;
end;

function TTextEditorSearch.GetPreviousSearchItemIndex(const ATextPosition: TTextEditorTextPosition): Integer;
var
  LLow, LHigh, LMiddle: Integer;
  LSearchItem: PTextEditorSearchItem;

  function IsTextPositionBetweenSearchItems: Boolean;
  var
    LNextSearchItem: PTextEditorSearchItem;
  begin
    LNextSearchItem := PTextEditorSearchItem(FItems[LMiddle + 1]);

    Result :=
      ( (LSearchItem^.EndTextPosition.Line < ATextPosition.Line) or
        (LSearchItem^.EndTextPosition.Line = ATextPosition.Line) and (LSearchItem^.EndTextPosition.Char <= ATextPosition.Char) )
      and
      ( (LNextSearchItem^.EndTextPosition.Line > ATextPosition.Line) or
        (LNextSearchItem^.EndTextPosition.Line = ATextPosition.Line) and (LNextSearchItem^.EndTextPosition.Char > ATextPosition.Char) )
  end;

  function IsSearchItemGreaterThanTextPosition: Boolean;
  begin
    Result := (LSearchItem^.EndTextPosition.Line > ATextPosition.Line) or
      (LSearchItem^.EndTextPosition.Line = ATextPosition.Line) and (LSearchItem^.EndTextPosition.Char > ATextPosition.Char)
  end;

  function IsSearchItemLowerThanTextPosition: Boolean;
  begin
    Result := (LSearchItem^.EndTextPosition.Line < ATextPosition.Line) or
      (LSearchItem^.EndTextPosition.Line = ATextPosition.Line) and (LSearchItem^.EndTextPosition.Char < ATextPosition.Char)
  end;

begin
  Result := -1;

  if FItems.Count = 0 then
    Exit;

  LHigh := FItems.Count - 1;

  LSearchItem := PTextEditorSearchItem(FItems[0]);

  if IsSearchItemGreaterThanTextPosition then
    if soWrapAround in Options then
      Exit(LHigh)
    else
      Exit;

  LSearchItem := PTextEditorSearchItem(FItems[LHigh]);

  if IsSearchItemLowerThanTextPosition then
    Exit(LHigh);

  LLow := 0;
  Dec(LHigh);

  while LLow <= LHigh do
  begin
    LMiddle := (LLow + LHigh) shr 1;

    LSearchItem := PTextEditorSearchItem(FItems[LMiddle]);

    if IsTextPositionBetweenSearchItems then
      Exit(LMiddle)
    else
    if IsSearchItemGreaterThanTextPosition then
      LHigh := LMiddle - 1
    else
    if IsSearchItemLowerThanTextPosition then
      LLow := LMiddle + 1
  end;
end;

function TTextEditorSearch.GetNextSearchItemIndex(const ATextPosition: TTextEditorTextPosition): Integer;
var
  LLow, LHigh, LMiddle: Integer;
  LSearchItem: PTextEditorSearchItem;

  function IsTextPositionBetweenSearchItems: Boolean;
  var
    LPreviousSearchItem: PTextEditorSearchItem;
  begin
    LPreviousSearchItem := PTextEditorSearchItem(FItems[LMiddle - 1]);

    Result :=
      ( (LPreviousSearchItem^.BeginTextPosition.Line < ATextPosition.Line) or
        (LPreviousSearchItem^.BeginTextPosition.Line = ATextPosition.Line) and (LPreviousSearchItem^.BeginTextPosition.Char < ATextPosition.Char) )
      and
      ( (LSearchItem^.BeginTextPosition.Line > ATextPosition.Line) or
        (LSearchItem^.BeginTextPosition.Line = ATextPosition.Line) and (LSearchItem^.BeginTextPosition.Char >= ATextPosition.Char) );
  end;

  function IsSearchItemGreaterThanTextPosition: Boolean;
  begin
    Result := (LSearchItem^.BeginTextPosition.Line > ATextPosition.Line) or
      (LSearchItem^.BeginTextPosition.Line = ATextPosition.Line) and (LSearchItem^.BeginTextPosition.Char >= ATextPosition.Char)
  end;

  function IsSearchItemLowerThanTextPosition: Boolean;
  begin
    Result := (LSearchItem^.BeginTextPosition.Line < ATextPosition.Line) or
      (LSearchItem^.BeginTextPosition.Line = ATextPosition.Line) and (LSearchItem^.BeginTextPosition.Char < ATextPosition.Char)
  end;

begin
  Result := -1;

  if FItems.Count = 0 then
    Exit;

  LSearchItem := PTextEditorSearchItem(FItems[0]);

  if IsSearchItemGreaterThanTextPosition then
    Exit(0);

  LHigh := FItems.Count - 1;
  LSearchItem := PTextEditorSearchItem(FItems[LHigh]);

  if IsSearchItemLowerThanTextPosition then
    if soWrapAround in Options then
      Exit(0)
    else
      Exit;

  LLow := 1;

  while LLow <= LHigh do
  begin
    LMiddle := (LLow + LHigh) shr 1;

    LSearchItem := PTextEditorSearchItem(FItems[LMiddle]);

    if IsTextPositionBetweenSearchItems then
      Exit(LMiddle)
    else
    if IsSearchItemGreaterThanTextPosition then
      LHigh := LMiddle - 1
    else
    if IsSearchItemLowerThanTextPosition then
      LLow := LMiddle + 1
  end;
end;

end.
