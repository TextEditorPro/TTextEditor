unit TextEditor.SpecialChars.LineBreak;

interface

uses
  System.Classes, System.UITypes, TextEditor.Types;

type
  TTextEditorSpecialCharsLineBreak = class(TPersistent)
  strict private
    FColor: TColor;
    FOnChange: TNotifyEvent;
    FStyle: TTextEditorSpecialCharsLineBreakStyle;
    FVisible: Boolean;
    procedure DoChange;
    procedure SetColor(const AValue: TColor);
    procedure SetStyle(const AValue: TTextEditorSpecialCharsLineBreakStyle);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Color: TColor read FColor write SetColor default TColors.Black;
    property Style: TTextEditorSpecialCharsLineBreakStyle read FStyle write SetStyle default eolArrow;
    property Visible: Boolean read FVisible write SetVisible default False;
  end;

implementation

constructor TTextEditorSpecialCharsLineBreak.Create;
begin
  inherited;

  FColor := TColors.Black;
  FStyle := eolArrow;
  FVisible := False;
end;

procedure TTextEditorSpecialCharsLineBreak.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorSpecialCharsLineBreak) then
  with ASource as TTextEditorSpecialCharsLineBreak do
  begin
    Self.FColor := FColor;
    Self.FStyle := FStyle;
    Self.FVisible := FVisible;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorSpecialCharsLineBreak.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorSpecialCharsLineBreak.SetColor(const AValue: TColor);
begin
  if FColor <> AValue then
  begin
    FColor := AValue;
    DoChange;
  end;
end;

procedure TTextEditorSpecialCharsLineBreak.SetStyle(const AValue: TTextEditorSpecialCharsLineBreakStyle);
begin
  if FStyle <> AValue then
  begin
    FStyle := AValue;
    DoChange;
  end;
end;

procedure TTextEditorSpecialCharsLineBreak.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    DoChange;
  end;
end;

end.
