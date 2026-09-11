unit TextEditor.Selection;

interface

uses
  System.Classes, TextEditor.Consts, TextEditor.Types;

type
  TTextEditorSelection = class(TPersistent)
  strict private
    FActiveMode: TTextEditorSelectionMode;
    FExpandCharacters: string;
    FMode: TTextEditorSelectionMode;
    FOnChange: TNotifyEvent;
    FOptions: TTextEditorSelectionOptions;
    FVisible: Boolean;
    function IsExpandCharactersStored: Boolean;
    procedure DoChange;
    procedure SetActiveMode(const AValue: TTextEditorSelectionMode);
    procedure SetMode(const AValue: TTextEditorSelectionMode);
    procedure SetOptions(const AValue: TTextEditorSelectionOptions);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TTextEditorSelectionOption; const AEnabled: Boolean);
    property ActiveMode: TTextEditorSelectionMode read FActiveMode write SetActiveMode stored False;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property ExpandCharacters: string read FExpandCharacters write FExpandCharacters stored IsExpandCharactersStored;
    property Mode: TTextEditorSelectionMode read FMode write SetMode default smNormal;
    property Options: TTextEditorSelectionOptions read FOptions write SetOptions default [soHighlightSimilarTerms, soTermsCaseSensitive];
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

implementation

constructor TTextEditorSelection.Create;
begin
  inherited;

  FActiveMode := smNormal;
  FExpandCharacters := TCharacterSets.DefaultSelectionExpandCharacters;
  FMode := smNormal;
  FOptions := [soHighlightSimilarTerms, soTermsCaseSensitive];
  FVisible := True;
end;

procedure TTextEditorSelection.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorSelection) then
  with ASource as TTextEditorSelection do
  begin
    Self.FActiveMode := FActiveMode;
    Self.FExpandCharacters := FExpandCharacters;
    Self.FMode := FMode;
    Self.FOptions := FOptions;
    Self.FVisible := FVisible;

    if Assigned(Self.FOnChange) then
      Self.FOnChange(Self);
  end
  else
    inherited Assign(ASource);
end;

function TTextEditorSelection.IsExpandCharactersStored: Boolean;
begin
  Result := FExpandCharacters <> TCharacterSets.DefaultSelectionExpandCharacters;
end;

procedure TTextEditorSelection.SetOption(const AOption: TTextEditorSelectionOption; const AEnabled: Boolean);
begin
   if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

procedure TTextEditorSelection.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorSelection.SetMode(const AValue: TTextEditorSelectionMode);
begin
  if FMode <> AValue then
  begin
    FMode := AValue;
    ActiveMode := AValue;

    DoChange;
  end;
end;

procedure TTextEditorSelection.SetActiveMode(const AValue: TTextEditorSelectionMode);
begin
  if FActiveMode <> AValue then
  begin
    FActiveMode := AValue;

    DoChange;
  end;
end;

procedure TTextEditorSelection.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;

    DoChange;
  end;
end;

procedure TTextEditorSelection.SetOptions(const AValue: TTextEditorSelectionOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;

    DoChange;
  end;
end;

end.
