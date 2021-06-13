unit TextEditor.InternalImage;

interface

uses
  Vcl.Graphics;

type
  TTextEditorInternalImage = class(TObject)
  strict private
    FCount: Integer;
    FHeight: Integer;
    FImages: Vcl.Graphics.TBitmap;
    FWidth: Integer;
    function CreateBitmapFromInternalList(const AModule: THandle; const AName: string): Vcl.Graphics.TBitmap;
    procedure FreeBitmapFromInternalList;
  public
    constructor Create(const AModule: THandle; const AName: string; const ACount: Integer = 1);
    destructor Destroy; override;
    procedure ChangeScale(const AMultiplier, ADivider: Integer); virtual;
    procedure Draw(const ACanvas: TCanvas; const ANumber: Integer; const X: Integer; const Y: Integer;
      const ALineHeight: Integer; const ATransparentColor: TColor = clNone);
  end;

implementation

uses
  Winapi.Windows, System.Classes, System.SysUtils, System.Types, TextEditor.Utils;

type
  TInternalResource = class(TObject)
  public
    UsageCount: Integer;
    Name: string;
    Bitmap: Vcl.Graphics.TBitmap;
  end;

var
  GInternalResources: TList;

constructor TTextEditorInternalImage.Create(const AModule: THandle; const AName: string; const ACount: Integer = 1);
begin
  inherited Create;

  FImages := CreateBitmapFromInternalList(AModule, AName);
  FWidth := (FImages.Width + ACount shr 1) div ACount;
  FHeight := FImages.Height;
  FCount := ACount;
end;

destructor TTextEditorInternalImage.Destroy;
begin
  FreeBitmapFromInternalList;

  inherited Destroy;
end;

procedure TTextEditorInternalImage.ChangeScale(const AMultiplier, ADivider: Integer);
Var
  LNumerator: Integer;
begin
  LNumerator := (AMultiplier div ADivider) * ADivider;
  FWidth := MulDiv(FWidth, LNumerator, ADivider);
  ResizeBitmap(FImages, FWidth * FCount, MulDiv(fImages.Height, LNumerator, ADivider));
  FHeight := FImages.Height;
end;

function TTextEditorInternalImage.CreateBitmapFromInternalList(const AModule: THandle; const AName: string): Vcl.Graphics.TBitmap;
var
  LIndex: Integer;
  LInternalResource: TInternalResource;
begin
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

  LInternalResource := TInternalResource.Create;
  with LInternalResource do
  begin
    UsageCount := 1;
    Name := UpperCase(AName);
    Bitmap := Result;
  end;
  GInternalResources.Add(LInternalResource);
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
      LInternalResource.Free;
    end;
  end;
end;

procedure TTextEditorInternalImage.Draw(const ACanvas: TCanvas; const ANumber: Integer; const X: Integer; const Y: Integer;
  const ALineHeight: Integer; const ATransparentColor: TColor = clNone);
var
  LSourceRect, LDestinationRect: TRect;
  LY: Integer;
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

    if ATransparentColor = clNone then
      ACanvas.CopyRect(LDestinationRect, FImages.Canvas, LSourceRect)
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
