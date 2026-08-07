unit FMX.TextEditor.SpecialChars.Selection;

interface

uses
  System.Classes, System.UITypes;

type
  TTextEditorSpecialCharsSelection = class(TPersistent)
  strict private
    FColor: TAlphaColor;
    FOnChange: TNotifyEvent;
    FVisible: Boolean;
    procedure DoChange;
    procedure SetColor(const AValue: TAlphaColor);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Color: TAlphaColor read FColor write SetColor default TAlphaColors.Null;
    property Visible: Boolean read FVisible write SetVisible default False;
  end;

implementation

constructor TTextEditorSpecialCharsSelection.Create;
begin
  inherited;

  FColor := TAlphaColors.Null;
  FVisible := False;
end;

procedure TTextEditorSpecialCharsSelection.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorSpecialCharsSelection) then
  with ASource as TTextEditorSpecialCharsSelection do
  begin
    Self.FColor := FColor;
    Self.FVisible := FVisible;

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorSpecialCharsSelection.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorSpecialCharsSelection.SetColor(const AValue: TAlphaColor);
begin
  if FColor <> AValue then
  begin
    FColor := AValue;

    DoChange;
  end;
end;

procedure TTextEditorSpecialCharsSelection.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;

    DoChange;
  end;
end;

end.
