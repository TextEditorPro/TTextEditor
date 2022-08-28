unit TextEditor.ActiveLine;

interface

uses
  System.Classes, System.UITypes, TextEditor.Consts, TextEditor.Glyph;

type
  TTextEditorActiveLine = class(TPersistent)
  strict private
    FIndicator: TTextEditorGlyph;
    FOnChange: TNotifyEvent;
    FVisible: Boolean;
    function IsIndicatorStored: Boolean;
    procedure DoChange(const ASender: TObject);
    procedure SetIndicator(const AValue: TTextEditorGlyph);
    procedure SetOnChange(const AValue: TNotifyEvent);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write SetOnChange;
  published
    property Indicator: TTextEditorGlyph read FIndicator write SetIndicator stored IsIndicatorStored;
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

implementation

constructor TTextEditorActiveLine.Create;
begin
  inherited;

  FIndicator := TTextEditorGlyph.Create(HInstance, TResourceBitmap.ActiveLine, TColors.Fuchsia);
  FIndicator.Visible := False;
  FVisible := True;
end;

destructor TTextEditorActiveLine.Destroy;
begin
  FIndicator.Free;

  inherited;
end;

procedure TTextEditorActiveLine.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorActiveLine) then
  with ASource as TTextEditorActiveLine do
  begin
    Self.FVisible := FVisible;
    Self.FIndicator.Assign(FIndicator);
    Self.DoChange(Self);
  end
  else
    inherited Assign(ASource);
end;

function TTextEditorActiveLine.IsIndicatorStored: Boolean;
begin
  Result := FIndicator.Visible or (FIndicator.MaskColor <> TColors.SysNone) or (FIndicator.Left <> 2);
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
