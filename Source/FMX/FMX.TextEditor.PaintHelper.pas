unit FMX.TextEditor.PaintHelper;

interface

uses
  System.Classes, System.Math, System.SysUtils, System.Types, System.UITypes, FMX.Graphics;

type
  HDC = Pointer;
  HFont = Pointer;

const
  CFontStyleCount = Ord(High(TFontStyle)) + 1;
  CFontStyleCombineCount = 1 shl CFontStyleCount;

type
  TTextEditorStockFontPatterns = 0 .. CFontStyleCombineCount - 1;

  TTextEditorFontStock = class(TObject)
  strict private
    FBaseFont: TFont;
    FCharHeight: Single;
    FCharWidth: Single;
    FFixedSizeFont: Boolean;
    FMeasureBitmap: TBitmap;
    function GetFontHandle: HFont;
    procedure MeasureFont;
  protected
    function GetCharHeight: Single;
    function GetCharWidth: Single;
    function GetFixedSizeFont: Boolean;
    procedure SetBaseFont(const AValue: TFont);
    procedure SetStyle(const AValue: TFontStyles);
  public
    constructor Create(const AInitialFont: TFont);
    destructor Destroy; override;
    procedure ReleaseFontHandles; virtual;
    property BaseFont: TFont read FBaseFont;
    property CharWidth: Single read GetCharWidth;
    property FontHandle: HFont read GetFontHandle;
  end;

  ETextEditorFontStockException = class(Exception);

  TTextEditorPaintHelper = class(TObject)
  strict private
    FBackgroundColor: TAlphaColor;
    FCalcExtentBaseStyle: TFontStyles;
    FCharHeight: Single;
    FCharWidth: Single;
    FColor: TAlphaColor;
    FDrawingCount: Integer;
    FFixedSizeFont: Boolean;
    FFontStock: TTextEditorFontStock;
    FLastFontFamily: string;
    FLastFontSize: Single;
    FLastFontStyle: TFontStyles;
    FLastFontValid: Boolean;
    FStockBitmap: TBitmap;
  protected
    property DrawingCount: Integer read FDrawingCount;
  public
    constructor Create(const ACalcExtentBaseStyle: TFontStyles; const ABaseFont: TFont);
    destructor Destroy; override;
    procedure BeginDrawing(const AHandle: HDC);
    procedure EndDrawing;
    procedure SetBackgroundColor(const AValue: TAlphaColor);
    procedure SetBaseFont(const AValue: TFont);
    procedure SetBaseStyle(const AValue: TFontStyles);
    procedure SetForegroundColor(const AValue: TAlphaColor);
    procedure SetStyle(const AValue: TFontStyles);
    property BackgroundColor: TAlphaColor read FBackgroundColor;
    property CharHeight: Single read FCharHeight;
    property CharWidth: Single read FCharWidth;
    property Color: TAlphaColor read FColor;
    property FixedSizeFont: Boolean read FFixedSizeFont;
    property FontStock: TTextEditorFontStock read FFontStock;
    property StockBitmap: TBitmap read FStockBitmap;
  end;

  ETextEditorPaintHelperException = class(Exception);

implementation

uses
  FMX.TextEditor.Language;

{ TTextEditorFontStock }

constructor TTextEditorFontStock.Create(const AInitialFont: TFont);
begin
  inherited Create;

  FBaseFont := TFont.Create;
  FMeasureBitmap := TBitmap.Create(1, 1);
  SetBaseFont(AInitialFont);
end;

destructor TTextEditorFontStock.Destroy;
begin
  FMeasureBitmap.Free;
  FBaseFont.Free;

  inherited;
end;

function TTextEditorFontStock.GetCharHeight: Single;
begin
  Result := FCharHeight;
end;

function TTextEditorFontStock.GetCharWidth: Single;
begin
  Result := FCharWidth;
end;

function TTextEditorFontStock.GetFixedSizeFont: Boolean;
begin
  Result := FFixedSizeFont;
end;

function TTextEditorFontStock.GetFontHandle: HFont;
begin
  Result := nil;
end;

procedure TTextEditorFontStock.MeasureFont;
var
  LWidth1: Single;
  LWidth2: Single;
begin
  FCharWidth := 8;
  FCharHeight := 12;
  FFixedSizeFont := True;

  try
    FMeasureBitmap.SetSize(256, 128);

    if FMeasureBitmap.Canvas.BeginScene then
    try
      FMeasureBitmap.Canvas.Font.Assign(FBaseFont);
      LWidth1 := FMeasureBitmap.Canvas.TextWidth('W');
      LWidth2 := FMeasureBitmap.Canvas.TextWidth('!');
      FCharWidth := FMeasureBitmap.Canvas.TextWidth(' ');
      FCharHeight := Round(FMeasureBitmap.Canvas.TextHeight('W')) + 1;
      FFixedSizeFont := SameValue(LWidth1, LWidth2);
    finally
      FMeasureBitmap.Canvas.EndScene;
    end;
  except
    on ECanvasException do
      ;
  end;
end;

procedure TTextEditorFontStock.ReleaseFontHandles;
begin
end;

procedure TTextEditorFontStock.SetBaseFont(const AValue: TFont);
begin
  if Assigned(AValue) then
  begin
    FBaseFont.Assign(AValue);
    MeasureFont;
  end
  else
    raise ETextEditorFontStockException.Create(STextEditorValueMustBeSpecified);
end;

procedure TTextEditorFontStock.SetStyle(const AValue: TFontStyles);
begin
  FBaseFont.Style := AValue;
  MeasureFont;
end;

{ TTextEditorPaintHelper }

constructor TTextEditorPaintHelper.Create(const ACalcExtentBaseStyle: TFontStyles; const ABaseFont: TFont);
begin
  inherited Create;

  FFontStock := TTextEditorFontStock.Create(ABaseFont);
  FStockBitmap := TBitmap.Create(1, 1);
  FCalcExtentBaseStyle := ACalcExtentBaseStyle;
  FColor := TAlphaColors.Black;
  FBackgroundColor := TAlphaColors.White;

  SetBaseFont(ABaseFont);
end;

destructor TTextEditorPaintHelper.Destroy;
begin
  FStockBitmap.Free;
  FFontStock.Free;

  inherited;
end;

procedure TTextEditorPaintHelper.BeginDrawing(const AHandle: HDC);
begin
  Inc(FDrawingCount);
end;

procedure TTextEditorPaintHelper.EndDrawing;
begin
  if FDrawingCount > 0 then
    Dec(FDrawingCount);
end;

procedure TTextEditorPaintHelper.SetBaseFont(const AValue: TFont);
begin
  if Assigned(AValue) then
  begin
    { Re-measuring the font is costly (bitmap BeginScene + text measurement) and Paint calls this every
      frame with the same font. Skip the work when nothing relevant changed. }
    if FLastFontValid and (FLastFontFamily = AValue.Family) and SameValue(FLastFontSize, AValue.Size) and
      (FLastFontStyle = AValue.Style) then
      Exit;

    FLastFontFamily := AValue.Family;
    FLastFontSize := AValue.Size;
    FLastFontStyle := AValue.Style;
    FLastFontValid := True;

    try
      if FStockBitmap.Canvas.BeginScene then
      try
        FStockBitmap.Canvas.Font.Assign(AValue);
        FStockBitmap.Canvas.Font.Style := [];
      finally
        FStockBitmap.Canvas.EndScene;
      end;
    except
      on ECanvasException do
        ;
    end;

    FFontStock.SetBaseFont(AValue);
    FFontStock.SetStyle(FCalcExtentBaseStyle);
    FCharWidth := FFontStock.GetCharWidth;
    FCharHeight := FFontStock.GetCharHeight;
    FFixedSizeFont := FFontStock.GetFixedSizeFont;
    SetStyle(AValue.Style);
  end
  else
    raise ETextEditorPaintHelperException.Create(STextEditorValueMustBeSpecified);
end;

procedure TTextEditorPaintHelper.SetBaseStyle(const AValue: TFontStyles);
begin
  if FCalcExtentBaseStyle <> AValue then
  begin
    FCalcExtentBaseStyle := AValue;
    FFontStock.SetStyle(AValue);
    FCharWidth := FFontStock.GetCharWidth;
    FCharHeight := FFontStock.GetCharHeight;
    FFixedSizeFont := FFontStock.GetFixedSizeFont;
  end;
end;

procedure TTextEditorPaintHelper.SetStyle(const AValue: TFontStyles);
begin
  FFontStock.SetStyle(AValue);

  try
    if FStockBitmap.Canvas.BeginScene then
    try
      FStockBitmap.Canvas.Font.Style := AValue;
    finally
      FStockBitmap.Canvas.EndScene;
    end;
  except
    on ECanvasException do
      ;
  end;
end;

procedure TTextEditorPaintHelper.SetForegroundColor(const AValue: TAlphaColor);
begin
  FColor := AValue;
end;

procedure TTextEditorPaintHelper.SetBackgroundColor(const AValue: TAlphaColor);
begin
  FBackgroundColor := AValue;
end;

end.
