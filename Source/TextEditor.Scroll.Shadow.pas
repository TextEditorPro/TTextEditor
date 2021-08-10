unit TextEditor.Scroll.Shadow;

interface

uses
  System.Classes, System.UITypes;

type
  TTextEditorScrollShadow = class(TPersistent)
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
    property Visible: Boolean read FVisible write SetVisible default True;
    property Width: Integer read FWidth write SetWidth default 8;
  end;

implementation

constructor TTextEditorScrollShadow.Create;
begin
  inherited;

  FAlphaBlending := 96;
  FColor := TColors.Black;
  FVisible := True;
  FWidth := 8;
end;

procedure TTextEditorScrollShadow.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorScrollShadow) then
  with ASource as TTextEditorScrollShadow do
  begin
    Self.FAlphaBlending := FAlphaBlending;
    Self.FColor := FColor;
    Self.FVisible := FVisible;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorScrollShadow.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorScrollShadow.SetAlphaBlending(const AValue: Byte);
begin
  if FAlphaBlending <> AValue then
  begin
    FAlphaBlending := AValue;
    DoChange;
  end;
end;

procedure TTextEditorScrollShadow.SetColor(const AValue: TColor);
begin
  if FColor <> AValue then
  begin
    FColor := AValue;
    DoChange;
  end;
end;

procedure TTextEditorScrollShadow.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    DoChange;
  end;
end;

procedure TTextEditorScrollShadow.SetWidth(const AValue: Integer);
begin
  if FWidth <> AValue then
  begin
    FWidth := AValue;
    DoChange;
  end;
end;

end.
