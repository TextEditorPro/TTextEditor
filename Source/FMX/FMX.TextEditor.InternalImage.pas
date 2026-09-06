unit FMX.TextEditor.InternalImage;

interface

uses
  System.UITypes, FMX.Graphics, FMX.ImgList, FMX.Types;

type
  TTextEditorBookmarkColors = record
    Yellow: TAlphaColor;
    Red: TAlphaColor;
    Green: TAlphaColor;
    Blue: TAlphaColor;
    Purple: TAlphaColor;
  end;

  TTextEditorInternalImage = class(TObject)
  public const
    DefaultImageCount = 14;
  strict private
    FColors: TTextEditorBookmarkColors;
    FCount: Integer;
    FHeight: Integer;
    FImages: TBitmap;
    FSprites: TBitmap;
    FSpriteScale: Single;
    FWidth: Integer;
    function CreateBitmapFromImageList(AImageList: TCustomImageList; const APixelsPerInch: Integer): TBitmap;
    function GlyphFillColor(const ANumber: Integer): TAlphaColor;
    procedure DrawGlyph(const ACanvas: TCanvas; const ANumber: Integer; const X, Y, AWidth, AHeight: Single);
    procedure FreeBitmapFromInternalList;
    procedure RequireSprites(const AScale: Single);
  public
    constructor Create(const ACount: Integer = 1; const APixelsPerInch: Integer = 96); overload;
    constructor Create(const AImageList: TCustomImageList; const APixelsPerInch: Integer = 96); overload;
    destructor Destroy; override;
    function GetBitmap(const AImageIndex: Integer; const ABackgroundColor: TAlphaColor; const AScale: Single = 1): TBitmap;
    procedure Draw(const ACanvas: TCanvas; const ANumber: Integer; const X, Y: Single; const ALineHeight: Single;
      const ATransparentColor: TAlphaColor = TAlphaColors.Null);
    procedure SetColors(const AColors: TTextEditorBookmarkColors);
    property Height: Integer read FHeight write FHeight;
    property Width: Integer read FWidth write FWidth;
  end;

implementation

uses
  System.Classes, System.Math, System.Math.Vectors, System.SysUtils, System.Types, FMX.TextEditor.Consts, FMX.TextEditor.Types,
  FMX.TextLayout;

type
  TInternalResource = class(TObject)
  public
    Bitmap: TBitmap;
    Name: string;
    UsageCount: Integer;
  end;

const
  BookmarkDigitHeightFactor = 0.58;
  BookmarkGlyphHeight = 14;
  BookmarkGlyphWidth = 10;
  BookmarkLineGap = 2;
  BookmarkNotchDepthFactor = 0.22;

var
  GInternalResources: TList;

constructor TTextEditorInternalImage.Create(const ACount: Integer = 1; const APixelsPerInch: Integer = 96);
begin
  inherited Create;

  FCount := ACount;
  FWidth := MulDiv(BookmarkGlyphWidth, APixelsPerInch, 96);
  FHeight := MulDiv(BookmarkGlyphHeight, APixelsPerInch, 96);

  FColors.Yellow := TDefaultColors.BookmarkYellow;
  FColors.Red := TDefaultColors.BookmarkRed;
  FColors.Green := TDefaultColors.BookmarkGreen;
  FColors.Blue := TDefaultColors.BookmarkBlue;
  FColors.Purple := TDefaultColors.BookmarkPurple;
end;

function TTextEditorInternalImage.GlyphFillColor(const ANumber: Integer): TAlphaColor;
begin
  case ANumber of
    10: Result := FColors.Red;
    11: Result := FColors.Green;
    12: Result := FColors.Blue;
    13: Result := FColors.Purple;
  else
    Result := FColors.Yellow;
  end;
end;

procedure TTextEditorInternalImage.SetColors(const AColors: TTextEditorBookmarkColors);
begin
  if (FColors.Yellow <> AColors.Yellow) or (FColors.Red <> AColors.Red) or (FColors.Green <> AColors.Green) or
    (FColors.Blue <> AColors.Blue) or (FColors.Purple <> AColors.Purple) then
  begin
    FColors := AColors;
    FreeAndNil(FSprites);
  end;
end;

constructor TTextEditorInternalImage.Create(const AImageList: TCustomImageList; const APixelsPerInch: Integer = 96);
begin
  inherited Create;

  FCount := AImageList.Count;

  if FCount > 0 then
  begin
    var LRect := AImageList.Destination[0].Layers[0].SourceRect.Rect;

    FHeight := MulDiv(Round(LRect.Height), APixelsPerInch, 96);
    FWidth := MulDiv(Round(LRect.Width), APixelsPerInch, 96);
  end
  else
  begin
    FHeight := MulDiv(16, APixelsPerInch, 96);
    FWidth := MulDiv(16, APixelsPerInch, 96);
  end;

  FImages := CreateBitmapFromImageList(AImageList, APixelsPerInch);
end;

destructor TTextEditorInternalImage.Destroy;
begin
  FreeBitmapFromInternalList;
  FSprites.Free;

  inherited Destroy;
end;

function TTextEditorInternalImage.GetBitmap(const AImageIndex: Integer; const ABackgroundColor: TAlphaColor; const AScale: Single = 1): TBitmap;
begin
  Result := TBitmap.Create;

  Result.BitmapScale := AScale;
  Result.SetSize(Round(FWidth * AScale), Round(FHeight * AScale));

  if Result.Canvas.BeginScene then
  try
    Result.Canvas.Clear(ABackgroundColor);

    if Assigned(FImages) then
      Draw(Result.Canvas, AImageIndex, 0, 0, FHeight)
    else
      DrawGlyph(Result.Canvas, AImageIndex, 0, 0, FWidth, FHeight);
  finally
    Result.Canvas.EndScene;
  end;
end;

procedure TTextEditorInternalImage.RequireSprites(const AScale: Single);
begin
  if Assigned(FSprites) and SameValue(FSpriteScale, AScale) then
    Exit;

  FSprites.Free;

  FSprites := TBitmap.Create;
  FSprites.BitmapScale := AScale;
  FSprites.SetSize(Round(FWidth * FCount * AScale), Round(FHeight * AScale));

  if FSprites.Canvas.BeginScene then
  try
    FSprites.Canvas.Clear(TAlphaColors.Null);

    for var LIndex := 0 to FCount - 1 do
      DrawGlyph(FSprites.Canvas, LIndex, LIndex * FWidth, 0, FWidth, FHeight);
  finally
    FSprites.Canvas.EndScene;
  end;

  FSpriteScale := AScale;
end;

function TTextEditorInternalImage.CreateBitmapFromImageList(AImageList: TCustomImageList; const APixelsPerInch: Integer): TBitmap;
var
  LInternalResource: TInternalResource;
  LKey: string;
begin
  LKey := IntToHex(NativeUInt(AImageList), SizeOf(Pointer) * 2);

  for var LIndex := 0 to GInternalResources.Count - 1 do
  begin
    LInternalResource := TInternalResource(GInternalResources[LIndex]);

    if LInternalResource.Name = LKey then
    with LInternalResource do
    begin
      UsageCount := UsageCount + 1;

      FHeight := Bitmap.Height;
      FWidth := Bitmap.Width div FCount;

      Exit(Bitmap);
    end;
  end;

  Result := TBitmap.Create;

  Result.SetSize(FWidth * AImageList.Count, FHeight);

  if Result.Canvas.BeginScene then
  try
    Result.Canvas.Clear(TAlphaColors.Null);

    for var LIndex := 0 to AImageList.Count - 1 do
      AImageList.Draw(Result.Canvas, RectF(LIndex * FWidth, 0, (LIndex + 1) * FWidth, FHeight), LIndex);
  finally
    Result.Canvas.EndScene;
  end;

  LInternalResource := TInternalResource.Create;

  with LInternalResource do
  begin
    UsageCount := 1;
    Name := LKey;
    Bitmap := Result;
  end;

  GInternalResources.Add(LInternalResource);
end;

procedure TTextEditorInternalImage.FreeBitmapFromInternalList;

  function FindImageIndex: Integer;
  begin
    for Result := 0 to GInternalResources.Count - 1 do
    if TInternalResource(GInternalResources[Result]).Bitmap = FImages then
      Exit;

    Result := -1;
  end;

var
  LIndex: Integer;
  LInternalResource: TInternalResource;
begin
  if not Assigned(FImages) then
    Exit;

  LIndex := FindImageIndex;

  if LIndex = -1 then
    Exit;

  LInternalResource := TInternalResource(GInternalResources[LIndex]);

  with LInternalResource do
  begin
    UsageCount := UsageCount - 1;

    if UsageCount = 0 then
    begin
      Bitmap.Free;
      Bitmap := nil;

      GInternalResources.Delete(LIndex);

      Free;
    end;
  end;
end;

procedure TTextEditorInternalImage.DrawGlyph(const ACanvas: TCanvas; const ANumber: Integer; const X, Y, AWidth, AHeight: Single);
var
  LScale: Single;

  function Snap(const AValue: Single): Single;
  begin
    Result := Round(AValue * LScale) / LScale;
  end;

  procedure FillRibbon(const ALeft, ATop, ARibbonWidth, ARibbonHeight: Single; const AColor: TAlphaColor);
  var
    LPath: TPathData;
    LNotchDepth: Single;
  begin
    LNotchDepth := ARibbonHeight * BookmarkNotchDepthFactor;

    LPath := TPathData.Create;
    try
      LPath.MoveTo(PointF(ALeft, ATop));
      LPath.LineTo(PointF(ALeft + ARibbonWidth, ATop));
      LPath.LineTo(PointF(ALeft + ARibbonWidth, ATop + ARibbonHeight));
      LPath.LineTo(PointF(ALeft + ARibbonWidth * 0.5, ATop + ARibbonHeight - LNotchDepth));
      LPath.LineTo(PointF(ALeft, ATop + ARibbonHeight));
      LPath.ClosePath;

      ACanvas.Fill.Kind := TBrushKind.Solid;
      ACanvas.Fill.Color := AColor;
      ACanvas.FillPath(LPath, 1);
    finally
      LPath.Free;
    end;
  end;

  function DigitCenterX(const APath: TPathData; const ABounds: TRectF): Single;
  var
    LPolygon: TPolygon;
    LBottom, LMinX, LMaxX: Single;
  begin
    Result := ABounds.Left + ABounds.Width * 0.5;

    if ANumber <> 0 then
      Exit;

    APath.FlattenToPolygon(LPolygon);

    LBottom := ABounds.Top + ABounds.Height * 0.98;
    LMinX := ABounds.Right;
    LMaxX := ABounds.Left;

    for var LPoint in LPolygon do
    if (LPoint.Y >= LBottom) and (LPoint.Y <= ABounds.Bottom) then
    begin
      LMinX := Min(LMinX, LPoint.X);
      LMaxX := Max(LMaxX, LPoint.X);
    end;

    if LMaxX > LMinX then
      Result := (LMinX + LMaxX) * 0.5;
  end;

var
  LLayout: TTextLayout;
  LDigitPath: TPathData;
  LBounds: TRectF;
  LLeft, LTop, LWidth, LHeight, LDigitHeight, LDigitScale, LCenterX: Single;
  LFillColor: TAlphaColor;
begin
  LScale := ACanvas.Scale;

  LLeft := Snap(X);
  LTop := Snap(Y);
  LWidth := Snap(AWidth);
  LHeight := Snap(AHeight);

  LFillColor := GlyphFillColor(ANumber);

  FillRibbon(LLeft, LTop, LWidth, LHeight, LFillColor);

  if ANumber < 9 then
  begin
    LLayout := TTextLayoutManager.DefaultTextLayout.Create;
    LDigitPath := TPathData.Create;
    try
      LLayout.BeginUpdate;
      LLayout.Text := IntToStr(ANumber + 1);
      LLayout.Font.Size := 100;
      LLayout.Font.Style := [TFontStyle.fsBold];
      LLayout.EndUpdate;
      LLayout.ConvertToPath(LDigitPath);

      LBounds := LDigitPath.GetBounds;
      LDigitHeight := Snap(LHeight * BookmarkDigitHeightFactor);

      if LBounds.Height > 0 then
      begin
        LDigitScale := LDigitHeight / LBounds.Height;
        LCenterX := DigitCenterX(LDigitPath, LBounds);

        LDigitPath.Scale(LDigitScale, LDigitScale);
        LDigitPath.Translate(LLeft + LWidth * 0.5 - LCenterX * LDigitScale,
          LTop + Snap((LHeight * (1 - BookmarkNotchDepthFactor) - LDigitHeight) * 0.5) - LBounds.Top * LDigitScale);

        ACanvas.Fill.Kind := TBrushKind.Solid;
        ACanvas.Fill.Color := TAlphaColors.Black;
        ACanvas.FillPath(LDigitPath, 1);
      end;
    finally
      LDigitPath.Free;
      LLayout.Free;
    end;
  end;
end;

procedure TTextEditorInternalImage.Draw(const ACanvas: TCanvas; const ANumber: Integer; const X, Y: Single; const ALineHeight: Single;
  const ATransparentColor: TAlphaColor = TAlphaColors.Null);
var
  LY, LHeight: Single;
  LSourceRect, LDestinationRect: TRectF;
begin
  if (ANumber < 0) or (ANumber >= FCount) then
    Exit;

  if not Assigned(FImages) then
  begin
    if ALineHeight - BookmarkLineGap < FHeight then
    begin
      LHeight := Max(1, ALineHeight - BookmarkLineGap);
      DrawGlyph(ACanvas, ANumber, X, Y, FWidth * LHeight / FHeight, LHeight);
    end
    else
    begin
      RequireSprites(ACanvas.Scale);

      LSourceRect := RectF(ANumber * FWidth * FSpriteScale, 0, (ANumber + 1) * FWidth * FSpriteScale,
        FHeight * FSpriteScale);
      LDestinationRect.Left := Round(X * FSpriteScale) / FSpriteScale;
      LDestinationRect.Top := Round(Y * FSpriteScale) / FSpriteScale;
      LDestinationRect.Right := LDestinationRect.Left + FWidth;
      LDestinationRect.Bottom := LDestinationRect.Top + FHeight;

      ACanvas.DrawBitmap(FSprites, LSourceRect, LDestinationRect, 1);
    end;

    Exit;
  end;

  LY := Y;

  if ALineHeight >= FHeight then
  begin
    LSourceRect := RectF(ANumber * FWidth, 0, (ANumber + 1) * FWidth, FHeight);

    LY := LY + (ALineHeight - FHeight) / 2;

    LDestinationRect := RectF(X, LY, X + FWidth, LY + FHeight);
  end
  else
  begin
    LDestinationRect := RectF(X, LY, X + FWidth, LY + ALineHeight);

    LY := (FHeight - ALineHeight) / 2;

    LSourceRect := RectF(ANumber * FWidth, LY, (ANumber + 1) * FWidth, LY + ALineHeight);
  end;

  ACanvas.DrawBitmap(FImages, LSourceRect, LDestinationRect, 1);
end;

initialization

  GInternalResources := TList.Create;

finalization

  GInternalResources.Free;
  GInternalResources := nil;

end.
