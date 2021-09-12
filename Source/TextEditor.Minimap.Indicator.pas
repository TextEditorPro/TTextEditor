unit TextEditor.Minimap.Indicator;

interface

uses
  System.Classes, TextEditor.Types;

type
  TTextEditorMinimapIndicator = class(TPersistent)
  strict private
    FAlphaBlending: Byte;
    FOnChange: TNotifyEvent;
    FOptions: TTextEditorMinimapIndicatorOptions;
    procedure DoChange;
    procedure SetAlphaBlending(const AValue: Byte);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TTextEditorMinimapIndicatorOption; const AEnabled: Boolean);
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property AlphaBlending: Byte read FAlphaBlending write SetAlphaBlending default 96;
    property Options: TTextEditorMinimapIndicatorOptions read FOptions write FOptions default [];
  end;

implementation

constructor TTextEditorMinimapIndicator.Create;
begin
  inherited;

  FAlphaBlending := 96;
  FOptions := [];
end;

procedure TTextEditorMinimapIndicator.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorMinimapIndicator) then
  with ASource as TTextEditorMinimapIndicator do
  begin
    Self.FAlphaBlending := FAlphaBlending;
    Self.FOptions := FOptions;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorMinimapIndicator.SetOption(const AOption: TTextEditorMinimapIndicatorOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;


procedure TTextEditorMinimapIndicator.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorMinimapIndicator.SetAlphaBlending(const AValue: Byte);
begin
  if FAlphaBlending <> AValue then
  begin
    FAlphaBlending := AValue;
    DoChange;
  end;
end;

end.
