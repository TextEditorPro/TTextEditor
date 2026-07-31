unit TextEditor.Glyph;

interface

uses
  System.Classes, System.UITypes, Vcl.Graphics, TextEditor.Types;

type
  TTextEditorGlyph = class(TPersistent)
  strict private
    FBitmap: TBitmap;
    FColor: TColor;
    FInternalGlyph: TBitmap;
    FInternalGlyphKind: TTextEditorInternalGlyph;
    FLeft: Integer;
    FMaskColor: TColor;
    FOnChange: TNotifyEvent;
    FVisible: Boolean;
    function GetHeight: Integer;
    function GetWidth: Integer;
    procedure DrawInternalGlyph(const ACanvas: TCanvas; const X, Y, AWidth, AHeight: Integer);
    procedure SetBitmap(const AValue: TBitmap);
    procedure SetLeft(const AValue: Integer);
    procedure SetMaskColor(const AValue: TColor);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create(const AGlyph: TTextEditorInternalGlyph = igNone);
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    procedure ChangeScale(const AMultiplier, ADivider: Integer);
    procedure Draw(const ACanvas: TCanvas; const X, Y: Integer; const ALineHeight: Integer = 0);
    property Color: TColor read FColor write FColor;
    property Height: Integer read GetHeight;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property Width: Integer read GetWidth;
  published
    property Bitmap: TBitmap read FBitmap write SetBitmap;
    property Left: Integer read FLeft write SetLeft default 2;
    property MaskColor: TColor read FMaskColor write SetMaskColor default TColors.SysNone;
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

implementation

uses
  Winapi.GDIPAPI, Winapi.GDIPOBJ, Winapi.Windows, System.Math, System.SysUtils, TextEditor.Utils;

constructor TTextEditorGlyph.Create(const AGlyph: TTextEditorInternalGlyph = igNone);
begin
  inherited Create;

  if AGlyph <> igNone then
  begin
    FInternalGlyph := Vcl.Graphics.TBitmap.Create;

    if AGlyph = igMouseMoveScroll then
      FInternalGlyph.SetSize(22, 22)
    else
      FInternalGlyph.SetSize(16, 16);

    FInternalGlyphKind := AGlyph;
  end;

  FVisible := True;
  FBitmap := Vcl.Graphics.TBitmap.Create;
  FColor := TColors.SysNone;
  FMaskColor := TColors.SysNone;
  FLeft := 2;
end;

destructor TTextEditorGlyph.Destroy;
begin
  if Assigned(FInternalGlyph) then
    FInternalGlyph.Free;

  FBitmap.Free;

  inherited Destroy;
end;

procedure TTextEditorGlyph.ChangeScale(const AMultiplier, ADivider: Integer);
begin
  if Assigned(FInternalGlyph) then
    ResizeBitmap(FInternalGlyph, Max(1, MulDiv(FInternalGlyph.Width, AMultiplier, ADivider)),
      Max(1, MulDiv(FInternalGlyph.Height, AMultiplier, ADivider)));

  if (FBitmap.Height <> 0) and (FBitmap.Width <> 0) then
    ResizeBitmap(FBitmap, Max(1, MulDiv(FBitmap.Width, AMultiplier, ADivider)),
      Max(1, MulDiv(FBitmap.Height, AMultiplier, ADivider)));
end;

procedure TTextEditorGlyph.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorGlyph) then
  with ASource as TTextEditorGlyph do
  begin
    if Assigned(FInternalGlyph) then
      Self.FInternalGlyph.Assign(FInternalGlyph);

    Self.FColor := FColor;
    Self.FInternalGlyphKind := FInternalGlyphKind;
    Self.FVisible := FVisible;
    Self.FBitmap.Assign(FBitmap);
    Self.FMaskColor := FMaskColor;
    Self.FLeft := FLeft;

    if Assigned(Self.FOnChange) then
      Self.FOnChange(Self);
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorGlyph.DrawInternalGlyph(const ACanvas: TCanvas; const X, Y, AWidth, AHeight: Integer);
var
  LGraphics: TGPGraphics;
  LGrid: Single;
  LScale: Single;

  function Px(const AValue: Single): Single;
  begin
    Result := X + AValue * AWidth / LGrid;
  end;

  function Py(const AValue: Single): Single;
  begin
    Result := Y + AValue * AHeight / LGrid;
  end;

  procedure FillPolygon(const APoints: array of TGPPointF; const AFillColor: Cardinal;
    const AStrokeColor: Cardinal = 0; const AStrokeWidth: Single = 1; const AStrokeBehind: Boolean = False);
  var
    LBrush: TGPSolidBrush;
    LPen: TGPPen;
  begin
    LPen := nil;

    if AStrokeColor <> 0 then
      LPen := TGPPen.Create(AStrokeColor, AStrokeWidth);

    LBrush := TGPSolidBrush.Create(AFillColor);
    try
      if AStrokeBehind and Assigned(LPen) then
        LGraphics.DrawPolygon(LPen, PGPPointF(@APoints[0]), Length(APoints));

      LGraphics.FillPolygon(LBrush, PGPPointF(@APoints[0]), Length(APoints));

      if not AStrokeBehind and Assigned(LPen) then
        LGraphics.DrawPolygon(LPen, PGPPointF(@APoints[0]), Length(APoints));
    finally
      LBrush.Free;
      LPen.Free;
    end;
  end;

  procedure DrawActiveLineArrow;
  begin
    LGrid := 16;
    LScale := AWidth / LGrid;

    FillPolygon([MakePoint(Px(3), Py(5)), MakePoint(Px(8), Py(5)), MakePoint(Px(8), Py(2)), MakePoint(Px(14), Py(8)),
      MakePoint(Px(8), Py(14)), MakePoint(Px(8), Py(11)), MakePoint(Px(3), Py(11))], $FF299CFF, $FF186B8C, LScale);
    FillPolygon([MakePoint(Px(4), Py(6)), MakePoint(Px(8.5), Py(6)), MakePoint(Px(8.5), Py(7)), MakePoint(Px(4), Py(7))],
      $FF9CD6FF);
  end;

  procedure DrawMouseMoveScroll;
  var
    LBrush: TGPSolidBrush;
  begin
    LGrid := 22;
    LScale := AWidth / LGrid;

    FillPolygon([MakePoint(Px(11), Py(1)), MakePoint(Px(15.5), Py(6.5)), MakePoint(Px(6.5), Py(6.5))],
      $FF2B2B2B, $FFFFFFFF, 2 * LScale, True); { North }
    FillPolygon([MakePoint(Px(21), Py(11)), MakePoint(Px(15.5), Py(15.5)), MakePoint(Px(15.5), Py(6.5))],
      $FF2B2B2B, $FFFFFFFF, 2 * LScale, True); { East }
    FillPolygon([MakePoint(Px(11), Py(21)), MakePoint(Px(6.5), Py(15.5)), MakePoint(Px(15.5), Py(15.5))],
      $FF2B2B2B, $FFFFFFFF, 2 * LScale, True); { South }
    FillPolygon([MakePoint(Px(1), Py(11)), MakePoint(Px(6.5), Py(6.5)), MakePoint(Px(6.5), Py(15.5))],
      $FF2B2B2B, $FFFFFFFF, 2 * LScale, True); { West }

    LBrush := TGPSolidBrush.Create($FFFFFFFF);
    try
      LGraphics.FillEllipse(LBrush, Px(8), Py(8), 6 * LScale, 6 * LScale);
    finally
      LBrush.Free;
    end;

    LBrush := TGPSolidBrush.Create($FF2B2B2B);
    try
      LGraphics.FillEllipse(LBrush, Px(9), Py(9), 4 * LScale, 4 * LScale);
    finally
      LBrush.Free;
    end;
  end;

  procedure DrawWordWrapArrow;
  var
    LColor: Cardinal;
    LRGBColor: Cardinal;
    LThickness, LHeadHalf: Integer;
    LStemLeft, LStemRight, LStemTop, LBarTop, LBarBottom, LHeadRight, LHeadTipX: Integer;
    LHeadCenterY: Single;

    function P(const AX, AY: Single): TGPPointF;
    begin
      Result := MakePoint(AX, AY);
    end;

  begin
    LGrid := 16;

    if FColor = TColors.SysNone then
      LColor := $FF2E9BD6
    else
    begin
      LRGBColor := ColorToRGB(FColor);
      LColor := MakeColor(255, GetRValue(LRGBColor), GetGValue(LRGBColor), GetBValue(LRGBColor));
    end;

    LThickness := Max(1, Round(2 * AWidth / LGrid));
    LStemRight := Round(Px(12));
    LStemLeft := LStemRight - LThickness;
    LStemTop := Round(Py(3));
    LBarBottom := Round(Py(11));
    LBarTop := LBarBottom - LThickness;
    LHeadRight := Round(Px(7));
    LHeadTipX := Round(Px(2));
    LHeadHalf := Max(2, Round(4.5 * AHeight / LGrid));
    LHeadCenterY := (LBarTop + LBarBottom) / 2;

    FillPolygon([P(LStemLeft, LStemTop), P(LStemRight, LStemTop), P(LStemRight, LBarBottom),
      P(LHeadRight, LBarBottom), P(LHeadRight, LHeadCenterY + LHeadHalf), P(LHeadTipX, LHeadCenterY),
      P(LHeadRight, LHeadCenterY - LHeadHalf), P(LHeadRight, LBarTop), P(LStemLeft, LBarTop)], LColor);
  end;

  procedure DrawSyncEditChainLink;
  var
    LPen: TGPPen;

    procedure Link(const ACenterX, ACenterY: Single);
    var
      LPath: TGPGraphicsPath;
      LDiameter: Single;
    begin
      LDiameter := 4.4 * LScale;

      LPath := TGPGraphicsPath.Create;
      try
        LPath.AddArc(-4 * LScale, -2.2 * LScale, LDiameter, LDiameter, 90, 180);
        LPath.AddArc(4 * LScale - LDiameter, -2.2 * LScale, LDiameter, LDiameter, 270, 180);
        LPath.CloseFigure;

        LGraphics.TranslateTransform(Px(ACenterX), Py(ACenterY));
        LGraphics.RotateTransform(-45);
        LGraphics.DrawPath(LPen, LPath);
        LGraphics.ResetTransform;
      finally
        LPath.Free;
      end;
    end;

  begin
    LGrid := 16;
    LScale := AWidth / LGrid;

    LPen := TGPPen.Create($FF2E9BD6, 1.6 * LScale);
    try
      Link(5.3, 10.7);
      Link(10.7, 5.3);
    finally
      LPen.Free;
    end;
  end;

begin
  LGraphics := TGPGraphics.Create(ACanvas.Handle);
  try
    LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);

    LGrid := 16;
    LScale := AWidth / LGrid;

    case FInternalGlyphKind of
      igActiveLine:
        DrawActiveLineArrow;
      igSyncEdit:
        DrawSyncEditChainLink;
      igMouseMoveScroll:
        DrawMouseMoveScroll;
      igWordWrap:
        DrawWordWrapArrow;
    end;
  finally
    LGraphics.Free;
  end;
end;

procedure TTextEditorGlyph.Draw(const ACanvas: TCanvas; const X, Y: Integer; const ALineHeight: Integer = 0);
var
  LY: Integer;
  LWidth, LHeight: Integer;
begin
  if not FBitmap.Empty then
  begin
    LY := Y;

    if ALineHeight <> 0 then
      Inc(LY, (ALineHeight - FBitmap.Height) div 2);

    FBitmap.Transparent := True;
    FBitmap.TransparentMode := tmFixed;
    FBitmap.TransparentColor := FMaskColor;

    ACanvas.Draw(X, LY, FBitmap);
  end
  else
  if Assigned(FInternalGlyph) then
  begin
    LWidth := FInternalGlyph.Width;
    LHeight := FInternalGlyph.Height;

    if (ALineHeight > 0) and (LHeight > ALineHeight) then
    begin
      LWidth := MulDiv(LWidth, ALineHeight, LHeight);
      LHeight := ALineHeight;
    end;

    LY := Y;

    if ALineHeight <> 0 then
      Inc(LY, (ALineHeight - LHeight) div 2);

    DrawInternalGlyph(ACanvas, X, LY, LWidth, LHeight);
  end;
end;

procedure TTextEditorGlyph.SetBitmap(const AValue: Vcl.Graphics.TBitmap);
begin
  FBitmap.Assign(AValue);
end;

procedure TTextEditorGlyph.SetMaskColor(const AValue: TColor);
begin
  if FMaskColor <> AValue then
  begin
    FMaskColor := AValue;

    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TTextEditorGlyph.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;

    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TTextEditorGlyph.SetLeft(const AValue: Integer);
begin
  if FLeft <> AValue then
  begin
    FLeft := AValue;

    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

function TTextEditorGlyph.GetWidth: Integer;
begin
  if not FBitmap.Empty then
    Result := FBitmap.Width
  else
  if Assigned(FInternalGlyph) then
    Result := FInternalGlyph.Width
  else
    Result := 0;
end;

function TTextEditorGlyph.GetHeight: Integer;
begin
  if not FBitmap.Empty then
    Result := FBitmap.Height
  else
  if Assigned(FInternalGlyph) then
    Result := FInternalGlyph.Height
  else
    Result := 0;
end;

end.
