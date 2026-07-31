unit FMX.TextEditor.Glyph;

interface

uses
  System.Classes, System.Types, System.UITypes, FMX.Graphics, FMX.TextEditor.Types;

type
  TTextEditorGlyph = class(TPersistent)
  strict private
    FBitmap: TBitmap;
    FColor: TAlphaColor;
    FInternalGlyph: TBitmap;
    FInternalGlyphKind: TTextEditorInternalGlyph;
    FLeft: Integer;
    FMaskColor: TAlphaColor;
    FOnChange: TNotifyEvent;
    FVisible: Boolean;
    function GetHeight: Integer;
    function GetWidth: Integer;
    procedure ApplyMaskColor;
    procedure SetBitmap(const AValue: TBitmap);
    procedure SetLeft(const AValue: Integer);
    procedure SetMaskColor(const AValue: TAlphaColor);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create(const AGlyph: TTextEditorInternalGlyph = igNone);
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    procedure ChangeScale(const AMultiplier, ADivider: Integer);
    procedure Draw(const ACanvas: TCanvas; const X, Y: Single; const ALineHeight: Single = 0);
    property Color: TAlphaColor read FColor write FColor;
    property Height: Integer read GetHeight;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property Width: Integer read GetWidth;
  published
    property Bitmap: TBitmap read FBitmap write SetBitmap;
    property Left: Integer read FLeft write SetLeft default 2;
    property MaskColor: TAlphaColor read FMaskColor write SetMaskColor default TAlphaColors.Null;
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

implementation

uses
  System.Math, System.Math.Vectors, System.SysUtils, FMX.Types, FMX.TextEditor.Utils;


function IsBitmapEmpty(const ABitmap: TBitmap): Boolean;
begin
  Result := ABitmap.IsEmpty;
end;

procedure TTextEditorGlyph.ChangeScale(const AMultiplier, ADivider: Integer);
begin
  { The internal glyph is drawn as vector graphics, so it can scale by any ratio. Keep at least one pixel -
    a zero-sized bitmap could never scale back up. }
  if Assigned(FInternalGlyph) then
    ResizeBitmap(FInternalGlyph, Max(1, MulDiv(FInternalGlyph.Width, AMultiplier, ADivider)),
      Max(1, MulDiv(FInternalGlyph.Height, AMultiplier, ADivider)));

  if (FBitmap.Height <> 0) and (FBitmap.Width <> 0) then
    ResizeBitmap(FBitmap, Max(1, MulDiv(FBitmap.Width, AMultiplier, ADivider)),
      Max(1, MulDiv(FBitmap.Height, AMultiplier, ADivider)));
end;

constructor TTextEditorGlyph.Create(const AGlyph: TTextEditorInternalGlyph = igNone);
begin
  inherited Create;

  if AGlyph <> igNone then
  begin
    FInternalGlyph := TBitmap.Create;

    { Sizes of the original TextEditor.res bitmaps }
    if AGlyph = igMouseMoveScroll then
      FInternalGlyph.SetSize(22, 22)
    else
      FInternalGlyph.SetSize(16, 16);

    FInternalGlyphKind := AGlyph;
  end;

  FVisible := True;
  FBitmap := TBitmap.Create;
  FColor := TAlphaColors.Null;
  FMaskColor := TAlphaColors.Null;
  FLeft := 2;
end;

destructor TTextEditorGlyph.Destroy;
begin
  if Assigned(FInternalGlyph) then
    FInternalGlyph.Free;

  FBitmap.Free;

  inherited Destroy;
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

procedure TTextEditorGlyph.Draw(const ACanvas: TCanvas; const X, Y: Single; const ALineHeight: Single = 0);
var
  LGlyphBitmap: TBitmap;
  LY: Single;
  LWidth, LHeight: Single;

  { Vector versions of the original TextEditor.res bitmaps }
  procedure DrawInternalGlyph;
  var
    LRect: TRectF;
    LGrid: Single;

    function Pt(const AX, AY: Single): TPointF;
    begin
      Result := PointF(LRect.Left + AX * LRect.Width / LGrid, LRect.Top + AY * LRect.Height / LGrid);
    end;

    procedure FillPolygon(const APoints: array of TPointF; const AFillColor: TAlphaColor;
      const AStrokeColor: TAlphaColor = TAlphaColors.Null; const AStrokeBehind: Boolean = False);
    var
      LPath: TPathData;
    begin
      LPath := TPathData.Create;
      try
        LPath.MoveTo(APoints[0]);

        for var LIndex := 1 to High(APoints) do
          LPath.LineTo(APoints[LIndex]);

        LPath.ClosePath;

        if AStrokeBehind and (AStrokeColor <> TAlphaColors.Null) then
        begin
          ACanvas.Stroke.Color := AStrokeColor;
          ACanvas.DrawPath(LPath, 1);
        end;

        ACanvas.Fill.Color := AFillColor;
        ACanvas.FillPath(LPath, 1);

        if not AStrokeBehind and (AStrokeColor <> TAlphaColors.Null) then
        begin
          ACanvas.Stroke.Color := AStrokeColor;
          ACanvas.DrawPath(LPath, 1);
        end;
      finally
        LPath.Free;
      end;
    end;

    { Blue right-pointing arrow }
    procedure DrawActiveLineArrow;
    begin
      LGrid := 16;

      FillPolygon([Pt(3, 5), Pt(8, 5), Pt(8, 2), Pt(14, 8), Pt(8, 14), Pt(8, 11), Pt(3, 11)], $FF299CFF, $FF186B8C);
      FillPolygon([Pt(4, 6), Pt(8.5, 6), Pt(8.5, 7), Pt(4, 7)], $FF9CD6FF);
    end;

    { Four direction arrows around a center dot }
    procedure DrawMouseMoveScroll;
    begin
      LGrid := 22;

      ACanvas.Stroke.Thickness := 2 * LRect.Width / LGrid;

      FillPolygon([Pt(11, 1), Pt(15.5, 6.5), Pt(6.5, 6.5)], $FF2B2B2B, TAlphaColors.White, True); { North }
      FillPolygon([Pt(21, 11), Pt(15.5, 15.5), Pt(15.5, 6.5)], $FF2B2B2B, TAlphaColors.White, True); { East }
      FillPolygon([Pt(11, 21), Pt(6.5, 15.5), Pt(15.5, 15.5)], $FF2B2B2B, TAlphaColors.White, True); { South }
      FillPolygon([Pt(1, 11), Pt(6.5, 6.5), Pt(6.5, 15.5)], $FF2B2B2B, TAlphaColors.White, True); { West }

      ACanvas.Fill.Color := TAlphaColors.White;
      ACanvas.FillEllipse(TRectF.Create(Pt(8, 8), Pt(14, 14)), 1);
      ACanvas.Fill.Color := $FF2B2B2B;
      ACanvas.FillEllipse(TRectF.Create(Pt(9, 9), Pt(13, 13)), 1);
    end;

    { Return arrow - the line continues below. One filled polygon with pixel-snapped points - a stroked path
      reads as a blur at 16 px, and shrink-to-fit puts unsnapped coordinates off the pixel grid. The stem width
      and bar height derive from ONE rounded thickness - independently rounded edges can differ by a pixel
      (Round() is banker's rounding, so 13.5 and 16.5 round to 14 and 16). All math in device pixels. }
    procedure DrawWordWrapArrow;
    var
      LColor: TAlphaColor;
      LCanvasScale: Single;
      LThickness, LHeadHalf: Integer;
      LStemLeft, LStemRight, LStemTop, LBarTop, LBarBottom, LHeadRight, LHeadTipX: Integer;
      LHeadCenterY: Single;

      function DeviceX(const AGridValue: Single): Integer;
      begin
        Result := Round((LRect.Left + AGridValue * LRect.Width / LGrid) * LCanvasScale);
      end;

      function DeviceY(const AGridValue: Single): Integer;
      begin
        Result := Round((LRect.Top + AGridValue * LRect.Height / LGrid) * LCanvasScale);
      end;

      function P(const AX, AY: Single): TPointF;
      begin
        Result := PointF(AX / LCanvasScale, AY / LCanvasScale);
      end;

    begin
      LGrid := 16;

      LCanvasScale := ACanvas.Scale;

      if LCanvasScale <= 0 then
        LCanvasScale := 1;

      LColor := if FColor = TAlphaColors.Null then $FF2E9BD6 else FColor;

      LThickness := Max(1, Round(2 * LRect.Width / LGrid * LCanvasScale));
      LStemRight := DeviceX(12);
      LStemLeft := LStemRight - LThickness;
      LStemTop := DeviceY(3);
      LBarBottom := DeviceY(11);
      LBarTop := LBarBottom - LThickness;
      LHeadRight := DeviceX(7);
      LHeadTipX := DeviceX(2);
      LHeadHalf := Max(2, Round(4.5 * LRect.Height / LGrid * LCanvasScale));
      LHeadCenterY := (LBarTop + LBarBottom) / 2;

      { Stem down from the top right, bar to the left, arrowhead pointing left }
      FillPolygon([P(LStemLeft, LStemTop), P(LStemRight, LStemTop), P(LStemRight, LBarBottom),
        P(LHeadRight, LBarBottom), P(LHeadRight, LHeadCenterY + LHeadHalf), P(LHeadTipX, LHeadCenterY),
        P(LHeadRight, LHeadCenterY - LHeadHalf), P(LHeadRight, LBarTop), P(LStemLeft, LBarTop)], LColor);
    end;

    { Two interlocked chain links - linked editing }
    procedure DrawSyncEditChainLink;
    var
      LSavedMatrix: TMatrix;
      LScale: Single;

      procedure Link(const ACenterX, ACenterY: Single);
      var
        LCenter: TPointF;
      begin
        LCenter := Pt(ACenterX, ACenterY);

        ACanvas.SetMatrix(TMatrix.CreateRotation(-Pi / 4) * TMatrix.CreateTranslation(LCenter.X, LCenter.Y) * LSavedMatrix);
        ACanvas.DrawRect(RectF(-4 * LScale, -2.2 * LScale, 4 * LScale, 2.2 * LScale), 2.2 * LScale, 2.2 * LScale,
          AllCorners, 1);
      end;

    begin
      LGrid := 16;
      LScale := LRect.Width / LGrid;
      LSavedMatrix := ACanvas.Matrix;

      ACanvas.Stroke.Thickness := 1.6 * LScale;
      ACanvas.Stroke.Color := $FF2E9BD6;
      try
        Link(5.3, 10.7);
        Link(10.7, 5.3);
      finally
        ACanvas.SetMatrix(LSavedMatrix);
      end;
    end;

  begin
    LRect := RectF(X, LY, X + LWidth, LY + LHeight);
    LGrid := 16;

    ACanvas.Stroke.Kind := TBrushKind.Solid;
    ACanvas.Stroke.Thickness := LRect.Width / LGrid;
    ACanvas.Fill.Kind := TBrushKind.Solid;

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
  end;
begin
  if not IsBitmapEmpty(FBitmap) then
    LGlyphBitmap := FBitmap
  else
  if Assigned(FInternalGlyph) then
    LGlyphBitmap := FInternalGlyph
  else
    Exit;

  LWidth := LGlyphBitmap.Width;
  LHeight := LGlyphBitmap.Height;

  { The internal glyph is vector-drawn - shrink it to fit the line instead of overflowing into neighbor lines }
  if (LGlyphBitmap = FInternalGlyph) and (ALineHeight > 0) and (LHeight > ALineHeight) then
  begin
    LWidth := LWidth * ALineHeight / LHeight;
    LHeight := ALineHeight;
  end;

  LY := Y;

  { Center on the line - when the glyph is taller than the line, this shifts it up instead of down }
  if ALineHeight <> 0 then
    LY := LY + (ALineHeight - LHeight) / 2;

  if LGlyphBitmap = FInternalGlyph then
    DrawInternalGlyph
  else
    ACanvas.DrawBitmap(LGlyphBitmap, RectF(0, 0, LGlyphBitmap.Width, LGlyphBitmap.Height),
      RectF(X, LY, X + LWidth, LY + LHeight), 1);
end;

{ FMX has no transparent-color support when drawing bitmaps, so make the mask color pixels really transparent.
  Applying twice is harmless - already masked pixels no longer match the mask color. }
procedure TTextEditorGlyph.ApplyMaskColor;
var
  LBitmapData: TBitmapData;
begin
  if (FMaskColor = TAlphaColors.Null) or FBitmap.IsEmpty then
    Exit;

  if FBitmap.Map(TMapAccess.ReadWrite, LBitmapData) then
  try
    for var LY := 0 to FBitmap.Height - 1 do
    for var LX := 0 to FBitmap.Width - 1 do
    if LBitmapData.GetPixel(LX, LY) = FMaskColor then
      LBitmapData.SetPixel(LX, LY, TAlphaColors.Null);
  finally
    FBitmap.Unmap(LBitmapData);
  end;
end;

procedure TTextEditorGlyph.SetBitmap(const AValue: TBitmap);
begin
  FBitmap.Assign(AValue);
  ApplyMaskColor;
end;

procedure TTextEditorGlyph.SetMaskColor(const AValue: TAlphaColor);
begin
  if FMaskColor <> AValue then
  begin
    FMaskColor := AValue;
    ApplyMaskColor;

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
  if not IsBitmapEmpty(FBitmap) then
    Result := FBitmap.Width
  else
  if Assigned(FInternalGlyph) then
    Result := FInternalGlyph.Width
  else
    Result := 0;
end;

function TTextEditorGlyph.GetHeight: Integer;
begin
  if not IsBitmapEmpty(FBitmap) then
    Result := FBitmap.Height
  else
  if Assigned(FInternalGlyph) then
    Result := FInternalGlyph.Height
  else
    Result := 0;
end;

end.
