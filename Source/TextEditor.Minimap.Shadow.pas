unit TextEditor.Minimap.Shadow;

interface

uses
  System.Classes, System.UITypes;

type
  TTextEditorMinimapShadow = class(TPersistent)
  strict private
    FAlphaBlending: Byte;
    FColor: TColor;
    FOnChange: TNotifyEvent;
    FVisible: Boolean;
    FWidth: Integer;
    procedure DoChange;
    procedure SetAlphaBlending(const AValue: Byte);
    procedure SetColor(const AValue: TColor);
    procedure SetVisible(const AValue: Boolean);
    procedure SetWidth(const AValue: Integer);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property AlphaBlending: Byte read FAlphaBlending write SetAlphaBlending default 96;
    property Color: TColor read FColor write SetColor default TColors.Black;
    property Visible: Boolean read FVisible write SetVisible default False;
    property Width: Integer read FWidth write SetWidth default 8;
  end;

implementation

constructor TTextEditorMinimapShadow.Create;
begin
  inherited;

  FAlphaBlending := 96;
  FColor := TColors.Black;
  FVisible := False;
  FWidth := 8;
end;

procedure TTextEditorMinimapShadow.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorMinimapShadow) then
  with ASource as TTextEditorMinimapShadow do
  begin
    Self.FAlphaBlending := FAlphaBlending;
    Self.FColor := FColor;
    Self.FVisible := FVisible;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorMinimapShadow.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorMinimapShadow.SetAlphaBlending(const AValue: Byte);
begin
  if FAlphaBlending <> AValue then
  begin
    FAlphaBlending := AValue;
    DoChange;
  end;
end;

procedure TTextEditorMinimapShadow.SetColor(const AValue: TColor);
begin
  if FColor <> AValue then
  begin
    FColor := AValue;
    DoChange;
  end;
end;

procedure TTextEditorMinimapShadow.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    DoChange;
  end;
end;

procedure TTextEditorMinimapShadow.SetWidth(const AValue: Integer);
begin
  if FWidth <> AValue then
  begin
    FWidth := AValue;
    DoChange;
  end;
end;

end.
