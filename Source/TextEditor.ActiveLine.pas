unit TextEditor.ActiveLine;

interface

uses
  System.Classes, System.UITypes, TextEditor.Glyph, TextEditor.Types;

type
  TTextEditorActiveLine = class(TPersistent)
  strict private
    FIndicator: TTextEditorGlyph;
    FOnChange: TNotifyEvent;
    FOptions: TTextEditorActiveLineOptions;
    FStyle: TTextEditorActiveLineStyle;
    FVisible: Boolean;
    function IsIndicatorStored: Boolean;
    procedure DoChange(const ASender: TObject);
    procedure SetIndicator(const AValue: TTextEditorGlyph);
    procedure SetOnChange(const AValue: TNotifyEvent);
    procedure SetOptions(const AValue: TTextEditorActiveLineOptions);
    procedure SetStyle(const AValue: TTextEditorActiveLineStyle);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write SetOnChange;
  published
    property Indicator: TTextEditorGlyph read FIndicator write SetIndicator stored IsIndicatorStored;
    property Options: TTextEditorActiveLineOptions read FOptions write SetOptions default [aloHighlightLeftMargin];
    property Style: TTextEditorActiveLineStyle read FStyle write SetStyle default alsFill;
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

implementation

constructor TTextEditorActiveLine.Create;
begin
  inherited;

  FIndicator := TTextEditorGlyph.Create(igActiveLine);

  FIndicator.Visible := False;
  FOptions := [aloHighlightLeftMargin];
  FStyle := alsFill;
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
    Self.FOptions := FOptions;
    Self.FStyle := FStyle;
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

procedure TTextEditorActiveLine.SetOptions(const AValue: TTextEditorActiveLineOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;

    DoChange(Self);
  end;
end;

procedure TTextEditorActiveLine.SetStyle(const AValue: TTextEditorActiveLineStyle);
begin
  if FStyle <> AValue then
  begin
    FStyle := AValue;

    DoChange(Self);
  end;
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
