unit TextEditor.ActiveLine;

interface

uses
  System.Classes, System.UITypes, TextEditor.ActiveLine.Colors, TextEditor.Consts, TextEditor.Glyph;

type
  TTextEditorActiveLine = class(TPersistent)
  strict private
    FColors: TTextEditorActiveLineColors;
    FIndicator: TTextEditorGlyph;
    FOnChange: TNotifyEvent;
    FVisible: Boolean;
    procedure DoChange(const ASender: TObject);
    procedure SetColors(const AValue: TTextEditorActiveLineColors);
    procedure SetIndicator(const AValue: TTextEditorGlyph);
    procedure SetOnChange(const AValue: TNotifyEvent);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write SetOnChange;
  published
    property Colors: TTextEditorActiveLineColors read FColors write SetColors;
    property Indicator: TTextEditorGlyph read FIndicator write SetIndicator;
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

implementation

constructor TTextEditorActiveLine.Create;
begin
  inherited;

  FColors := TTextEditorActiveLineColors.Create;
  FIndicator := TTextEditorGlyph.Create(HInstance, TEXT_EDITOR_ACTIVE_LINE, TColors.Fuchsia);
  FIndicator.Visible := False;
  FVisible := True;
end;

destructor TTextEditorActiveLine.Destroy;
begin
  FColors.Free;
  FIndicator.Free;

  inherited;
end;

procedure TTextEditorActiveLine.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorActiveLine) then
  with ASource as TTextEditorActiveLine do
  begin
    Self.FColors.Assign(FColors);
    Self.FVisible := FVisible;
    Self.FIndicator.Assign(FIndicator);
    Self.DoChange(Self);
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorActiveLine.SetOnChange(const AValue: TNotifyEvent);
begin
  FOnChange := AValue;
  FIndicator.OnChange := AValue;
end;

procedure TTextEditorActiveLine.DoChange(const ASender: TObject);
begin
  if Assigned(FOnChange) then
    FOnChange(ASender);
end;

procedure TTextEditorActiveLine.SetColors(const AValue: TTextEditorActiveLineColors);
begin
  FColors.Assign(AValue);
  DoChange(Self);
end;

procedure TTextEditorActiveLine.SetIndicator(const AValue: TTextEditorGlyph);
begin
  FIndicator.Assign(AValue);
end;

procedure TTextEditorActiveLine.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    DoChange(Self);
  end;
end;

end.
