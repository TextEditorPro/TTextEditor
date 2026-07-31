unit TextEditor.InternalImage;

interface

uses
  System.UITypes, Vcl.Graphics, Vcl.ImgList;

type
  TTextEditorBookmarkColors = record
    Yellow: TColor;
    Red: TColor;
    Green: TColor;
    Blue: TColor;
    Purple: TColor;
  end;

  TTextEditorInternalImage = class(TObject)
  public const
    DefaultImageCount = 14;
  strict private
    FColors: TTextEditorBookmarkColors;
    FCount: Integer;
    FHeight: Integer;
    FImages: Vcl.Graphics.TBitmap;
    FSprites: Vcl.Graphics.TBitmap;
    FWidth: Integer;
    function CreateBitmapFromImageList(AImageList: TCustomImageList; const APixelsPerInch: Integer): Vcl.Graphics.TBitmap;
    function GlyphFillColor(const ANumber: Integer): Cardinal;
    procedure ChangeScale(const ABitmap: Vcl.Graphics.TBitmap; const AMultiplier: Integer);
    procedure DrawGlyph(const ACanvas: TCanvas; const ANumber: Integer; const X, Y, AWidth, AHeight: Single);
    procedure FreeBitmapFromInternalList;
    procedure RequireSprites;
  public
    constructor Create(const AImageList: TCustomImageList; const APixelsPerInch: Integer = 96); overload;
    constructor Create(const ACount: Integer = 1; const APixelsPerInch: Integer = 96); overload;
    destructor Destroy; override;
    function GetBitmap(const AImageIndex: Integer; const ABackgroundColor: TColor): Vcl.Graphics.TBitmap;
    procedure Draw(const ACanvas: TCanvas; const ANumber: Integer; const X: Integer; const Y: Integer; const ALineHeight: Integer; const ATransparentColor: TColor = TColors.SysNone);
    procedure SetColors(const AColors: TTextEditorBookmarkColors);
    property Height: Integer read FHeight write FHeight;
    property Width: Integer read FWidth write FWidth;
  end;

implementation

uses
  Winapi.GDIPAPI, Winapi.GDIPOBJ, Winapi.Windows, System.Classes, System.Math, System.SysUtils, System.Types,
  TextEditor.Consts, TextEditor.Utils;

type
  TInternalResource = class(TObject)
  public
    Bitmap: Vcl.Graphics.TBitmap;
    Name: string;
    UsageCount: Integer;
  end;

const
  BookmarkDigitFontCapHeight = 0.7;
  BookmarkDigitFontName = 'Segoe UI';
  BookmarkDigitHeightFactor = 0.5;
  BookmarkGlyphHeight = 14;
  BookmarkGlyphWidth = 10;
  BookmarkLineGap = 2;
  BookmarkNotchDepthFactor = 0.18;
  BookmarkNotchWidthFactor = 0.6;

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

constructor TTextEditorInternalImage.Create(const AImageList: TCustomImageList; const APixelsPerInch: Integer = 96);
begin
  inherited Create;

  FCount := AImageList.Count;
  FHeight := AImageList.Height;
  FWidth := AImageList.Width;

  FImages := CreateBitmapFromImageList(AImageList, APixelsPerInch);
end;

destructor TTextEditorInternalImage.Destroy;
begin
  FreeBitmapFromInternalList;
  FSprites.Free;

  inherited Destroy;
end;

function TTextEditorInternalImage.GetBitmap(const AImageIndex: Integer; const ABackgroundColor: TColor): Vcl.Graphics.TBitmap;
begin
  Result := Vcl.Graphics.TBitmap.Create;
  Result.TransparentColor := TColors.Fuchsia;
  Result.Canvas.Brush.Color := ABackgroundColor;
  Result.Width := FWidth;
  Result.Height := FHeight;

  if Assigned(FImages) then
    Draw(Result.Canvas, AImageIndex, 0, 0, FHeight, TColors.Fuchsia)
  else
    DrawGlyph(Result.Canvas, AImageIndex, 0, 0, FWidth, FHeight);
end;

procedure TTextEditorInternalImage.ChangeScale(const ABitmap: Vcl.Graphics.TBitmap; const AMultiplier: Integer);
begin
  if AMultiplier = 96 then
    Exit;

  FHeight := MulDiv(FHeight, AMultiplier, 96);
  FWidth := MulDiv(FWidth, AMultiplier, 96);

  ResizeBitmap(ABitmap, FWidth * FCount, FHeight);
end;

function TTextEditorInternalImage.CreateBitmapFromImageList(AImageList: TCustomImageList; const APixelsPerInch: Integer): Vcl.Graphics.TBitmap;
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

  Result := Vcl.Graphics.TBitmap.Create;

  Result.Width := AImageList.Width * AImageList.Count;
  Result.Height := AImageList.Height;
  Result.PixelFormat := pf32bit;
  Result.Canvas.Brush.Color := TColors.Fuchsia;
  Result.Canvas.FillRect(Rect(0, 0, Result.Width, Result.Height));

  for var LIndex := 0 to AImageList.Count - 1 do
    AImageList.Draw(Result.Canvas, LIndex * AImageList.Width, 0, LIndex);

  ChangeScale(Result, APixelsPerInch);

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
  LInternalResource: TInternalResource;
begin
  if not Assigned(FImages) then
    Exit;

  var LIndex := FindImageIndex;

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

procedure DrawGlyphCore(const AGraphics: TGPGraphics; const ANumber, ALeft, ATop, AWidth, AHeight: Integer;
  const AFillColor: Cardinal);

  procedure MakeRibbon(const ALeft, ATop, ARibbonWidth, ARibbonHeight: Single; var APoints: array of TGPPointF);
  var
    LNotchHalfWidth, LNotchDepth: Single;
  begin
    LNotchHalfWidth := ARibbonWidth * BookmarkNotchWidthFactor * 0.5;
    LNotchDepth := ARibbonHeight * BookmarkNotchDepthFactor;

    APoints[0] := MakePoint(ALeft, ATop);
    APoints[1] := MakePoint(ALeft + ARibbonWidth, ATop);
    APoints[2] := MakePoint(ALeft + ARibbonWidth, ATop + ARibbonHeight);
    APoints[3] := MakePoint(ALeft + ARibbonWidth * 0.5 + LNotchHalfWidth, ATop + ARibbonHeight);
    APoints[4] := MakePoint(ALeft + ARibbonWidth * 0.5, ATop + ARibbonHeight - LNotchDepth);
    APoints[5] := MakePoint(ALeft + ARibbonWidth * 0.5 - LNotchHalfWidth, ATop + ARibbonHeight);
    APoints[6] := MakePoint(ALeft, ATop + ARibbonHeight);
  end;

var
  LBrush: TGPSolidBrush;
  LFontFamily: TGPFontFamily;
  LFont: TGPFont;
  LStringFormat: TGPStringFormat;
  LPoints: array [0 .. 6] of TGPPointF;
  LCapHeight, LFontSize, LAscent, LBaseline: Single;
begin
  AGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
  AGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);

  MakeRibbon(ALeft, ATop, AWidth, AHeight, LPoints);

  LBrush := TGPSolidBrush.Create(AFillColor);
  try
    AGraphics.FillPolygon(LBrush, PGPPointF(@LPoints[0]), Length(LPoints));
  finally
    LBrush.Free;
  end;

  if ANumber < 9 then
  begin
    AGraphics.SetTextRenderingHint(TextRenderingHintAntiAliasGridFit);

    LFontFamily := TGPFontFamily.Create(BookmarkDigitFontName);
    LStringFormat := TGPStringFormat.Create(StringFormatFlagsNoClip);
    LBrush := TGPSolidBrush.Create($FF000000);
    try
      LCapHeight := AHeight * BookmarkDigitHeightFactor;
      LFontSize := LCapHeight / BookmarkDigitFontCapHeight;
      LAscent := LFontFamily.GetCellAscent(FontStyleBold) * LFontSize / LFontFamily.GetEmHeight(FontStyleBold);
      LBaseline := Round(ATop + (AHeight * (1 - BookmarkNotchDepthFactor) + LCapHeight) * 0.5);

      LFont := TGPFont.Create(LFontFamily, LFontSize, FontStyleBold, UnitPixel);
      try
        LStringFormat.SetAlignment(StringAlignmentCenter);

        AGraphics.DrawString(IntToStr(ANumber + 1), -1, LFont, MakeRect(ALeft + 0.5, LBaseline - LAscent, AWidth, 0), LStringFormat, LBrush);
      finally
        LFont.Free;
      end;
    finally
      LBrush.Free;
      LStringFormat.Free;
      LFontFamily.Free;
    end;
  end;
end;

function TTextEditorInternalImage.GlyphFillColor(const ANumber: Integer): Cardinal;
var
  LColor: TColor;
  LRGBColor: Longint;
begin
  case ANumber of
    10: LColor := FColors.Red;
    11: LColor := FColors.Green;
    12: LColor := FColors.Blue;
    13: LColor := FColors.Purple;
  else
    LColor := FColors.Yellow;
  end;

  LRGBColor := ColorToRGB(LColor);

  Result := $FF000000 or Cardinal(GetRValue(LRGBColor)) shl 16 or Cardinal(GetGValue(LRGBColor)) shl 8 or
    GetBValue(LRGBColor);
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

procedure TTextEditorInternalImage.DrawGlyph(const ACanvas: TCanvas; const ANumber: Integer; const X, Y, AWidth, AHeight: Single);
var
  LGraphics: TGPGraphics;
begin
  LGraphics := TGPGraphics.Create(ACanvas.Handle);
  try
    DrawGlyphCore(LGraphics, ANumber, Round(X), Round(Y), Round(AWidth), Round(AHeight), GlyphFillColor(ANumber));
  finally
    LGraphics.Free;
  end;
end;

procedure TTextEditorInternalImage.RequireSprites;
var
  LGPBitmap: TGPBitmap;
  LGraphics: TGPGraphics;
  LData: TBitmapData;
begin
  if Assigned(FSprites) then
    Exit;

  LGPBitmap := TGPBitmap.Create(FWidth * FCount, FHeight, PixelFormat32bppPARGB);
  try
    LGraphics := TGPGraphics.Create(LGPBitmap);
    try
      for var LIndex := 0 to FCount - 1 do
        DrawGlyphCore(LGraphics, LIndex, LIndex * FWidth, 0, FWidth, FHeight, GlyphFillColor(LIndex));
    finally
      LGraphics.Free;
    end;

    FSprites := Vcl.Graphics.TBitmap.Create;
    FSprites.PixelFormat := pf32bit;
    FSprites.SetSize(FWidth * FCount, FHeight);

    if LGPBitmap.LockBits(MakeRect(0, 0, FWidth * FCount, FHeight), ImageLockModeRead, PixelFormat32bppPARGB, LData) = Ok then
    try
      for var LRow := 0 to FHeight - 1 do
        Move(PByte(LData.Scan0)[LRow * LData.Stride], PByte(FSprites.ScanLine[LRow])^, FWidth * FCount * 4);
    finally
      LGPBitmap.UnlockBits(LData);
    end;
  finally
    LGPBitmap.Free;
  end;
end;

procedure TTextEditorInternalImage.Draw(const ACanvas: TCanvas; const ANumber: Integer; const X: Integer; const Y: Integer; const ALineHeight: Integer; const ATransparentColor: TColor = TColors.SysNone);
var
  LY: Integer;
  LHeight: Single;
  LSourceRect, LDestinationRect: TRect;
  LBlendFunction: TBlendFunction;
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
      RequireSprites;

      LBlendFunction.BlendOp := AC_SRC_OVER;
      LBlendFunction.BlendFlags := 0;
      LBlendFunction.SourceConstantAlpha := 255;
      LBlendFunction.AlphaFormat := AC_SRC_ALPHA;

      Winapi.Windows.AlphaBlend(ACanvas.Handle, X, Y, FWidth, FHeight, FSprites.Canvas.Handle, ANumber * FWidth, 0, FWidth, FHeight, LBlendFunction);
    end;

    Exit;
  end;

  LY := Y;

  if ALineHeight >= FHeight then
  begin
    LSourceRect := Rect(ANumber * FWidth, 0, (ANumber + 1) * FWidth, FHeight);
    Inc(LY, (ALineHeight - FHeight) shr 1);
    LDestinationRect := Rect(X, LY, X + FWidth, LY + FHeight);
  end
  else
  begin
    LDestinationRect := Rect(X, LY, X + FWidth, LY + ALineHeight);
    LY := (FHeight - ALineHeight) shr 1;
    LSourceRect := Rect(ANumber * FWidth, LY, (ANumber + 1) * FWidth, LY + ALineHeight);
  end;

  ACanvas.Brush.Style := bsClear;

  if ATransparentColor = TColors.SysNone then
    ACanvas.CopyRect(LDestinationRect, FImages.Canvas, LSourceRect)
  else
    ACanvas.BrushCopy(LDestinationRect, FImages, LSourceRect, ATransparentColor);
end;

initialization

  GInternalResources := TList.Create;

finalization

  GInternalResources.Free;
  GInternalResources := nil;

end.
