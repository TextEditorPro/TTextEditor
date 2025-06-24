unit TextEditor.InternalImage;

interface

uses
  System.UITypes, Vcl.Graphics, Vcl.ImgList;

type
  TTextEditorInternalImage = class(TObject)
  strict private
    FCount: Integer;
    FHeight: Integer;
    FImages: Vcl.Graphics.TBitmap;
    FWidth: Integer;
    function CreateBitmapFromImageList(AImageList: TCustomImageList; const AName: string; const APixelsPerInch: Integer): Vcl.Graphics.TBitmap;
    function CreateBitmapFromInternalList(const AModule: THandle; const AName: string; const APixelsPerInch: Integer): Vcl.Graphics.TBitmap;
    procedure ChangeScale(const ABitmap: Vcl.Graphics.TBitmap;const AMultiplier: Integer);
    procedure FreeBitmapFromInternalList;
  public
    constructor Create(const AModule: THandle; const AName: string; const ACount: Integer = 1; const APixelsPerInch: Integer = 96); overload;
    constructor Create(const AImageList: TCustomImageList; const AName: string; const APixelsPerInch: Integer = 96); overload;
    destructor Destroy; override;
    function GetBitmap(const AImageIndex: Integer; const ABackgroundColor: TColor): Vcl.Graphics.TBitmap;
    procedure Draw(const ACanvas: TCanvas; const ANumber: Integer; const X: Integer; const Y: Integer;
      const ALineHeight: Integer; const ATransparentColor: TColor = TColors.SysNone);
    property Height: Integer read FHeight write FHeight;
    property Width: Integer read FWidth write FWidth;
  end;

implementation

uses
  Winapi.Windows, System.Classes, System.SysUtils, System.Types, TextEditor.Utils;

type
  TInternalResource = class(TObject)
  public
    Bitmap: Vcl.Graphics.TBitmap;
    Name: string;
    UsageCount: Integer;
  end;

var
  GInternalResources: TList;

constructor TTextEditorInternalImage.Create(const AModule: THandle; const AName: string; const ACount: Integer = 1;
  const APixelsPerInch: Integer = 96);
begin
  inherited Create;

  FCount := ACount;
  FImages := CreateBitmapFromInternalList(AModule, AName, APixelsPerInch);
end;

constructor TTextEditorInternalImage.Create(const AImageList: TCustomImageList; const AName: string;
  const APixelsPerInch: Integer = 96);
begin
  inherited Create;

  FCount := AImageList.Count;
  FHeight := AImageList.Height;
  FWidth := AImageList.Width;

  FImages := CreateBitmapFromImageList(AImageList, AName, APixelsPerInch);
end;

destructor TTextEditorInternalImage.Destroy;
begin
  FreeBitmapFromInternalList;

  inherited Destroy;
end;

function TTextEditorInternalImage.GetBitmap(const AImageIndex: Integer; const ABackgroundColor: TColor): Vcl.Graphics.TBitmap;
begin
  Result := Vcl.Graphics.TBitmap.Create;
  Result.TransparentColor := TCOlors.Fuchsia;
  Result.Canvas.Brush.Color := ABackgroundColor;
  Result.Width := FWidth;
  Result.Height := FHeight;

  Draw(Result.Canvas, AImageIndex, 0, 0, FHeight, TColors.Fuchsia);
end;

procedure TTextEditorInternalImage.ChangeScale(const ABitmap: Vcl.Graphics.TBitmap; const AMultiplier: Integer);
begin
  if AMultiplier = 96 then
    Exit;

  FHeight := MulDiv(FHeight, AMultiplier, 96);
  FWidth := MulDiv(FWidth, AMultiplier, 96);

  ResizeBitmap(ABitmap, FWidth * FCount, FHeight);
end;

function TTextEditorInternalImage.CreateBitmapFromInternalList(const AModule: THandle; const AName: string;
  const APixelsPerInch: Integer): Vcl.Graphics.TBitmap;
var
  LIndex: Integer;
  LInternalResource: TInternalResource;
begin
  Result := nil;
  try
    for LIndex := 0 to GInternalResources.Count - 1 do
    begin
      LInternalResource := TInternalResource(GInternalResources[LIndex]);

      if LInternalResource.Name = UpperCase(AName) then
      with LInternalResource do
      begin
        UsageCount := UsageCount + 1;
        Exit(Bitmap);
      end;
    end;

    Result := Vcl.Graphics.TBitmap.Create;
    Result.Handle := LoadBitmap(AModule, PChar(AName));

    FHeight := Result.Height;
    FWidth := Result.Width div FCount;

    LInternalResource := TInternalResource.Create;

    with LInternalResource do
    begin
      UsageCount := 1;
      Name := UpperCase(AName);
      Bitmap := Result;
    end;

    GInternalResources.Add(LInternalResource);
  finally
    if Assigned(Result) then
      ChangeScale(Result, APixelsPerInch);
  end;
end;

function TTextEditorInternalImage.CreateBitmapFromImageList(AImageList: TCustomImageList; const AName: string;
  const APixelsPerInch: Integer): Vcl.Graphics.TBitmap;
var
  LIndex: Integer;
  LInternalResource: TInternalResource;
begin
  Result := nil;
  try
    for LIndex := 0 to GInternalResources.Count - 1 do
    begin
      LInternalResource := TInternalResource(GInternalResources[LIndex]);

      if LInternalResource.Name = UpperCase(AName) then
      with LInternalResource do
      begin
        UsageCount := UsageCount + 1;
        Exit(Bitmap);
      end;
    end;

    Result := Vcl.Graphics.TBitmap.Create;
    Result.Width := AImageList.Width * AImageList.Count;
    Result.Height := AImageList.Height;
    Result.PixelFormat := pf32bit;
    Result.AlphaFormat := afPremultiplied;
    FillChar(Result.ScanLine[Result.Height - 1]^, Result.Width * Result.Height * 4, 0);
    //Result.Canvas.Brush.Color := TColors.Fuchsia;
    //Result.Canvas.FillRect(Rect(0, 0, Result.Width, Result.Height));

    for LIndex := 0 to AImageList.Count - 1 do
      AImageList.Draw(Result.Canvas, LIndex * AImageList.Width, 0, LIndex);

    LInternalResource := TInternalResource.Create;

    with LInternalResource do
    begin
      UsageCount := 1;
      Name := UpperCase(AName);
      Bitmap := Result;
    end;

    GInternalResources.Add(LInternalResource);
  finally
    if Assigned(Result) then
      ChangeScale(Result, APixelsPerInch);
  end;
end;

procedure TTextEditorInternalImage.FreeBitmapFromInternalList;
var
  LIndex: Integer;
  LInternalResource: TInternalResource;

  function FindImageIndex: Integer;
  begin
    for Result := 0 to GInternalResources.Count - 1 do
    if TInternalResource(GInternalResources[Result]).Bitmap = FImages then
      Exit;

    Result := -1;
  end;

begin
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

procedure TTextEditorInternalImage.Draw(const ACanvas: TCanvas; const ANumber: Integer; const X: Integer; const Y: Integer;
  const ALineHeight: Integer; const ATransparentColor: TColor = TColors.SysNone);
var
  LSourceRect, LDestinationRect: TRect;
  LY: Integer;
  Blend: BLENDFUNCTION;
begin
  if (ANumber >= 0) and (ANumber < FCount) then
  begin
    LY := Y;

    if ALineHeight >= FHeight then
    begin
      LSourceRect := Rect(ANumber * FWidth, 0, (ANumber + 1) * FWidth, FHeight);
      Inc(LY, (ALineHeight - FHeight) div 2);
      LDestinationRect := Rect(X, LY, X + FWidth, LY + FHeight);
    end
    else
    begin
      LDestinationRect := Rect(X, LY, X + FWidth, LY + ALineHeight);
      LY := (FHeight - ALineHeight) div 2;
      LSourceRect := Rect(ANumber * FWidth, LY, (ANumber + 1) * FWidth, LY + ALineHeight);
    end;

    ACanvas.Brush.Style := bsClear;

    if ATransparentColor = TColors.SysNone then
    begin
      Blend.BlendOp := AC_SRC_OVER;
      Blend.BlendFlags := 0;
      Blend.SourceConstantAlpha := 255;
      Blend.AlphaFormat := AC_SRC_ALPHA;
      AlphaBlend(ACanvas.Handle, LDestinationRect.Left, LDestinationRect.Top, LDestinationRect.Width, LDestinationRect.Height, FImages.Canvas.Handle,
      LSourceRect.Left, LSourceRect.Top, LSourceRect.Width, LSourceRect.Height, Blend);
      //ACanvas.CopyRect(LDestinationRect, FImages.Canvas, LSourceRect)
    end
    else
      ACanvas.BrushCopy(LDestinationRect, FImages, LSourceRect, ATransparentColor);
  end;
end;

initialization

  GInternalResources := TList.Create;

finalization

  GInternalResources.Free;
  GInternalResources := nil;

end.
