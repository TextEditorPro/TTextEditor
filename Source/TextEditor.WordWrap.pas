unit TextEditor.WordWrap;

interface

uses
  System.Classes, Vcl.Graphics, TextEditor.Glyph, TextEditor.Types, TextEditor.WordWrap.Colors;

type
  TTextEditorWordWrap = class(TPersistent)
  strict private
    FActive: Boolean;
    FBitmap: Vcl.Graphics.TBitmap;
    FColors: TTextEditorWordWrapColors;
    FIndicator: TTextEditorGlyph;
    FOnChange: TNotifyEvent;
    FWidth: TTextEditorWordWrapWidth;
    procedure DoChange;
    procedure SetActive(const AValue: Boolean);
    procedure SetColors(const AValue: TTextEditorWordWrapColors);
    procedure SetIndicator(const AValue: TTextEditorGlyph);
    procedure SetOnChange(const AValue: TNotifyEvent);
    procedure SetWidth(const AValue: TTextEditorWordWrapWidth);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    procedure CreateInternalBitmap;
    property OnChange: TNotifyEvent read FOnChange write SetOnChange;
  published
    property Active: Boolean read FActive write SetActive default False;
    property Colors: TTextEditorWordWrapColors read FColors write SetColors;
    property Indicator: TTextEditorGlyph read FIndicator write SetIndicator;
    property Width: TTextEditorWordWrapWidth read FWidth write SetWidth default wwwPage;
  end;

implementation

uses
  System.UITypes;

constructor TTextEditorWordWrap.Create;
begin
  inherited;

  FActive := False;
  FColors := TTextEditorWordWrapColors.Create;
  FIndicator := TTextEditorGlyph.Create(HInstance, '', TColors.Fuchsia);
  CreateInternalBitmap;
  FWidth := wwwPage;
end;

destructor TTextEditorWordWrap.Destroy;
begin
  FBitmap.Free;
  FIndicator.Free;
  FColors.Free;

  inherited;
end;

procedure TTextEditorWordWrap.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorWordWrap) then
  with ASource as TTextEditorWordWrap do
  begin
    Self.FColors.Assign(FColors);
    Self.FActive := FActive;
    Self.FWidth := FWidth;
    Self.FIndicator.Assign(FIndicator);
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorWordWrap.CreateInternalBitmap;
begin
  if Assigned(FBitmap) then
  begin
    FBitmap.Free;
    FBitmap := nil;
  end;

  FBitmap := Vcl.Graphics.TBitmap.Create;
  with FBitmap do
  begin
    Canvas.Brush.Color := TColors.Fuchsia;
    Width := 15;
    Height := 14;
    Canvas.Pen.Color := FColors.Arrow;
    Canvas.MoveTo(6, 4);
    Canvas.LineTo(13, 4);
    Canvas.MoveTo(13, 5);
    Canvas.LineTo(13, 9);
    Canvas.MoveTo(12, 9);
    Canvas.LineTo(7, 9);
    Canvas.MoveTo(10, 7);
    Canvas.LineTo(10, 12);
    Canvas.MoveTo(9, 8);
    Canvas.LineTo(9, 11);
    Canvas.Pen.Color := FColors.Lines;
    Canvas.MoveTo(2, 6);
    Canvas.LineTo(7, 6);
    Canvas.MoveTo(2, 8);
    Canvas.LineTo(5, 8);
    Canvas.MoveTo(2, 10);
    Canvas.LineTo(5, 10);
    Canvas.MoveTo(2, 12);
    Canvas.LineTo(7, 12);
  end;

  FIndicator.MaskColor := TColors.Fuchsia;
  FIndicator.Bitmap.Handle := FBitmap.Handle;
end;

procedure TTextEditorWordWrap.SetOnChange(const AValue: TNotifyEvent);
begin
  FOnChange := AValue;
  FIndicator.OnChange := AValue;
end;

procedure TTextEditorWordWrap.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorWordWrap.SetActive(const AValue: Boolean);
begin
  if FActive <> AValue then
  begin
    FActive := AValue;
    DoChange;
  end;
end;

procedure TTextEditorWordWrap.SetIndicator(const AValue: TTextEditorGlyph);
begin
  FIndicator.Assign(AValue);
end;

procedure TTextEditorWordWrap.SetWidth(const AValue: TTextEditorWordWrapWidth);
begin
  if FWidth <> AValue then
  begin
    FWidth := AValue;
    DoChange;
  end;
end;

procedure TTextEditorWordWrap.SetColors(const AValue: TTextEditorWordWrapColors);
begin
  FColors.Assign(AValue);
end;

end.
