unit TextEditor.PaintHelper;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, System.Types, System.UITypes, Vcl.Graphics, TextEditor.Types;

const
  CFontStyleCount = Ord(High(TFontStyle)) + 1;
  CFontStyleCombineCount = 1 shl CFontStyleCount;

type
  TTextEditorStockFontPatterns = 0 .. CFontStyleCombineCount - 1;

  PTextEditorFontData = ^TTextEditorFontData;
  TTextEditorFontData = record
    CharHeight: Integer;
    CharWidth: Integer;
    FixedSize: Boolean;
    Handle: HFont;
    Style: TFontStyles;
  end;

  TTextEditorFontsData = array [TTextEditorStockFontPatterns] of TTextEditorFontData;

  PTextEditorSharedFontsInfo = ^TTextEditorSharedFontsInfo;
  TTextEditorSharedFontsInfo = record
    BaseFont: TFont;
    BaseLogFont: TLogFont;
    FontsData: TTextEditorFontsData;
    LockCount: Integer;
    RefCount: Integer;
  end;

  { TTextEditorFontsInfoManager }

  TTextEditorFontsInfoManager = class(TObject)
  strict private
    FFontsInfo: TList;
    function CreateFontsInfo(const ABaseFont: TFont; const ALogFont: TLogFont): PTextEditorSharedFontsInfo;
    function FindFontsInfo(const ALogFont: TLogFont): PTextEditorSharedFontsInfo;
    procedure DestroyFontHandles(const ASharedFontsInfo: PTextEditorSharedFontsInfo);
    procedure RetrieveLogFontForComparison(const ABaseFont: TFont; var ALogFont: TLogFont);
  public
    constructor Create;
    destructor Destroy; override;
    function GetFontsInfo(const ABaseFont: TFont): PTextEditorSharedFontsInfo;
    procedure LockFontsInfo(const ASharedFontsInfo: PTextEditorSharedFontsInfo);
    procedure ReleaseFontsInfo(const ASharedFontsInfo: PTextEditorSharedFontsInfo);
    procedure UnlockFontsInfo(const ASharedFontsInfo: PTextEditorSharedFontsInfo);
  end;

  TTextEditorFontStock = class(TObject)
  strict private
    FBaseLogFont: TLogFont;
    FCurrentFont: HFont;
    FCurrentStyle: TFontStyles;
    FHandle: HDC;
    FHandleRefCount: Integer;
    FPCurrentFontData: PTextEditorFontData;
    FSharedFontsInfo: PTextEditorSharedFontsInfo;
    FUsingFontHandles: Boolean;
    function GetBaseFont: TFont;
  protected
    function GetCharHeight: Integer;
    function GetCharWidth: Integer;
    function GetFixedSizeFont: Boolean;
    function GetFontData(const AIndex: Integer): PTextEditorFontData;
    function InternalCreateFont(const AStyle: TFontStyles): HFont;
    function InternalGetHandle: HDC;
    procedure CalculateFontMetrics(const AHandle: HDC; const ACharHeight: PInteger; const ACharWidth: PInteger);
    procedure InternalReleaseDC(const AValue: HDC);
    procedure ReleaseFontsInfo;
    procedure SetBaseFont(const AValue: TFont);
    procedure SetStyle(const AValue: TFontStyles);
    procedure UseFontHandles;
    property FontData[const AIndex: Integer]: PTextEditorFontData read GetFontData;
  public
    constructor Create(const AInitialFont: TFont);
    destructor Destroy; override;
    procedure ReleaseFontHandles; virtual;
    property BaseFont: TFont read GetBaseFont;
    property CharWidth: Integer read GetCharWidth;
    property FontHandle: HFont read FCurrentFont;
  end;

  ETextEditorFontStockException = class(Exception);

  { TTextEditorPaintHelper }

  TTextEditorPaintHelper = class(TObject)
  strict private
    FBackgroundColor: TColor;
    FCalcExtentBaseStyle: TFontStyles;
    FCharHeight: Integer;
    FCharWidth: Integer;
    FColor: TColor;
    FCurrentFont: HFont;
    FDrawingCount: Integer;
    FFixedSizeFont: Boolean;
    FFontStock: TTextEditorFontStock;
    FHandle: HDC;
    FSaveHandle: Integer;
    FStockBitmap: Vcl.Graphics.TBitmap;
  protected
    property DrawingCount: Integer read FDrawingCount;
  public
    constructor Create(const ACalcExtentBaseStyle: TFontStyles; const ABaseFont: TFont);
    destructor Destroy; override;
    procedure BeginDrawing(const AHandle: HDC);
    procedure EndDrawing;
    procedure SetBackgroundColor(const AValue: TColor);
    procedure SetBaseFont(const AValue: TFont);
    procedure SetBaseStyle(const AValue: TFontStyles);
    procedure SetForegroundColor(const AValue: TColor);
    procedure SetStyle(const AValue: TFontStyles);
    property BackgroundColor: TColor read FBackgroundColor;
    property CharHeight: Integer read FCharHeight;
    property CharWidth: Integer read FCharWidth;
    property Color: TColor read FColor;
    property FixedSizeFont: Boolean read FFixedSizeFont;
    property FontStock: TTextEditorFontStock read FFontStock;
    property StockBitmap: Vcl.Graphics.TBitmap read FStockBitmap;
  end;

  ETextEditorPaintHelperException = class(Exception);

implementation

uses
  TextEditor.Language;

var
  GFontsInfoManager: TTextEditorFontsInfoManager;

{ TTextEditorFontsInfoManager }

procedure TTextEditorFontsInfoManager.LockFontsInfo(const ASharedFontsInfo: PTextEditorSharedFontsInfo);
begin
  Inc(ASharedFontsInfo^.LockCount);
end;

constructor TTextEditorFontsInfoManager.Create;
begin
  inherited;

  FFontsInfo := TList.Create;
end;

function TTextEditorFontsInfoManager.CreateFontsInfo(const ABaseFont: TFont; const ALogFont: TLogFont): PTextEditorSharedFontsInfo;
begin
  New(Result);
  FillChar(Result^, SizeOf(TTextEditorSharedFontsInfo), 0);
  with Result^ do
  try
    BaseFont := TFont.Create;
    BaseFont.Assign(ABaseFont);
    BaseLogFont := ALogFont;
  except
    Result^.BaseFont.Free;
    Dispose(Result);
    raise;
  end;
end;

procedure TTextEditorFontsInfoManager.UnlockFontsInfo(const ASharedFontsInfo: PTextEditorSharedFontsInfo);
begin
  with ASharedFontsInfo^ do
  begin
    Dec(LockCount);
    if LockCount = 0 then
      DestroyFontHandles(ASharedFontsInfo);
  end;
end;

destructor TTextEditorFontsInfoManager.Destroy;
begin
  GFontsInfoManager := nil;

  if Assigned(FFontsInfo) then
  begin
    while FFontsInfo.Count > 0 do
    begin
      Assert(1 = PTextEditorSharedFontsInfo(FFontsInfo[FFontsInfo.Count - 1])^.RefCount);
      ReleaseFontsInfo(PTextEditorSharedFontsInfo(FFontsInfo[FFontsInfo.Count - 1]));
    end;
    FFontsInfo.Free;
  end;

  inherited;
end;

procedure TTextEditorFontsInfoManager.DestroyFontHandles(const ASharedFontsInfo: PTextEditorSharedFontsInfo);
var
  LIndex: Integer;
  LFontData: TTextEditorFontData;
begin
  with ASharedFontsInfo^ do
  for LIndex := Low(TTextEditorStockFontPatterns) to High(TTextEditorStockFontPatterns) do
  begin
    LFontData := FontsData[LIndex];
    if LFontData.Handle <> 0 then
    begin
      DeleteObject(LFontData.Handle);
      LFontData.Handle := 0;
    end;
  end;
end;

function TTextEditorFontsInfoManager.FindFontsInfo(const ALogFont: TLogFont): PTextEditorSharedFontsInfo;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FFontsInfo.Count - 1 do
  begin
    Result := PTextEditorSharedFontsInfo(FFontsInfo[LIndex]);
    if CompareMem(@(Result^.BaseLogFont), @ALogFont, SizeOf(TLogFont)) then
      Exit;
  end;

  Result := nil;
end;

function TTextEditorFontsInfoManager.GetFontsInfo(const ABaseFont: TFont): PTextEditorSharedFontsInfo;
var
  LLogFont: TLogFont;
begin
  Assert(Assigned(ABaseFont));

  RetrieveLogFontForComparison(ABaseFont, LLogFont);
  Result := FindFontsInfo(LLogFont);
  if not Assigned(Result) then
  begin
    Result := CreateFontsInfo(ABaseFont, LLogFont);
    FFontsInfo.Add(Result);
  end;

  if Assigned(Result) then
    Inc(Result^.RefCount);
end;

procedure TTextEditorFontsInfoManager.ReleaseFontsInfo(const ASharedFontsInfo: PTextEditorSharedFontsInfo);
begin
  Assert(Assigned(ASharedFontsInfo));

  with ASharedFontsInfo^ do
  begin
    Assert(LockCount < RefCount);
    if RefCount > 1 then
      Dec(RefCount)
    else
    begin
      FFontsInfo.Remove(ASharedFontsInfo);
      BaseFont.Free;
      Dispose(ASharedFontsInfo);
    end;
  end;
end;

procedure TTextEditorFontsInfoManager.RetrieveLogFontForComparison(const ABaseFont: TFont; var ALogFont: TLogFont);
var
  LPEnd: PChar;
begin
  GetObject(ABaseFont.Handle, SizeOf(TLogFont), @ALogFont);
  with ALogFont do
  begin
    lfItalic := 0;
    lfUnderline := 0;
    lfStrikeOut := 0;
    LPEnd := StrEnd(lfFaceName);
    FillChar(LPEnd[1], @lfFaceName[High(lfFaceName)] - LPEnd, 0);
  end;
end;

{ TTextEditorFontStock }

procedure TTextEditorFontStock.CalculateFontMetrics(const AHandle: HDC; const ACharHeight: PInteger; const ACharWidth: PInteger);
var
  LTextMetric: TTextMetric;
  LCharInfo: TABC;
  LHasABC: Boolean;
begin
  GetTextMetrics(AHandle, LTextMetric);

  LHasABC := GetCharABCWidths(AHandle, Ord(' '), Ord(' '), LCharInfo);
  if not LHasABC then
  begin
    with LCharInfo do
    begin
      abcA := 0;
      abcB := LTextMetric.tmAveCharWidth;
      abcC := 0;
    end;
    LTextMetric.tmOverhang := 0;
  end;

  with LCharInfo do
    ACharWidth^ := abcA + Integer(abcB) + abcC + LTextMetric.tmOverhang;
  ACharHeight^ := Abs(LTextMetric.tmHeight)
end;

constructor TTextEditorFontStock.Create(const AInitialFont: TFont);
begin
  inherited Create;

  SetBaseFont(AInitialFont);
end;

destructor TTextEditorFontStock.Destroy;
begin
  ReleaseFontsInfo;
  Assert(FHandleRefCount = 0);

  inherited;
end;

function TTextEditorFontStock.GetBaseFont: TFont;
begin
  Result := FSharedFontsInfo^.BaseFont;
end;

function TTextEditorFontStock.GetCharWidth: Integer;
begin
  Result := FPCurrentFontData^.CharWidth;
end;

function TTextEditorFontStock.GetCharHeight: Integer;
begin
  Result := FPCurrentFontData^.CharHeight;
end;

function TTextEditorFontStock.GetFixedSizeFont: Boolean;
begin
  Result := FPCurrentFontData^.FixedSize;
end;

function TTextEditorFontStock.GetFontData(const AIndex: Integer): PTextEditorFontData;
begin
  Result := @FSharedFontsInfo^.FontsData[AIndex];
end;

function TTextEditorFontStock.InternalCreateFont(const AStyle: TFontStyles): HFont;
const
  CBolds: array [Boolean] of Integer = (400, 700);
begin
  with FBaseLogFont do
  begin
    lfWeight := CBolds[fsBold in AStyle];
    lfItalic := Ord(BOOL(fsItalic in AStyle));
    lfUnderline := Ord(BOOL(fsUnderline in AStyle));
    lfStrikeOut := Ord(BOOL(fsStrikeOut in AStyle));
  end;
  Result := CreateFontIndirect(FBaseLogFont);
end;

function TTextEditorFontStock.InternalGetHandle: HDC;
begin
  if FHandleRefCount = 0 then
  begin
    Assert(FHandle = 0);
    FHandle := GetDC(0);
  end;
  Inc(FHandleRefCount);
  Result := FHandle;
end;

procedure TTextEditorFontStock.InternalReleaseDC(const AValue: HDC);
begin
  Dec(FHandleRefCount);
  if FHandleRefCount <= 0 then
  begin
    Assert((FHandle <> 0) and (FHandle = AValue));
    ReleaseDC(0, FHandle);
    FHandle := 0;
    Assert(FHandleRefCount = 0);
  end;
end;

procedure TTextEditorFontStock.ReleaseFontHandles;
begin
  if FUsingFontHandles then
  with GFontsInfoManager do
  begin
    UnlockFontsInfo(FSharedFontsInfo);
    FUsingFontHandles := False;
  end;
end;

procedure TTextEditorFontStock.ReleaseFontsInfo;
begin
  if Assigned(FSharedFontsInfo) then
  with GFontsInfoManager do
  begin
    if FUsingFontHandles then
    begin
      UnlockFontsInfo(FSharedFontsInfo);
      FUsingFontHandles := False;
    end;
    ReleaseFontsInfo(FSharedFontsInfo);
    FSharedFontsInfo := nil;
  end;
end;

procedure TTextEditorFontStock.SetBaseFont(const AValue: TFont);
var
  LSharedFontsInfo: PTextEditorSharedFontsInfo;
begin
  if Assigned(AValue) then
  begin
    LSharedFontsInfo := GFontsInfoManager.GetFontsInfo(AValue);
    if LSharedFontsInfo = FSharedFontsInfo then
      GFontsInfoManager.ReleaseFontsInfo(LSharedFontsInfo)
    else
    begin
      ReleaseFontsInfo;
      FSharedFontsInfo := LSharedFontsInfo;
      FBaseLogFont := FSharedFontsInfo^.BaseLogFont;
      SetStyle(AValue.Style);
    end;
  end
  else
    raise ETextEditorFontStockException.Create(STextEditorValueMustBeSpecified);
end;

procedure TTextEditorFontStock.SetStyle(const AValue: TFontStyles);
var
  LIndex: Integer;
  LHandle: HDC;
  LOldFont: HFont;
  LFontDataPointer: PTextEditorFontData;
  LSize1, LSize2: TSize;
begin
  Assert(SizeOf(TFontStyles) = 1);

  LIndex := Byte(AValue);
  Assert(LIndex <= High(TTextEditorStockFontPatterns));

  UseFontHandles;
  LFontDataPointer := FontData[LIndex];
  if FPCurrentFontData = LFontDataPointer then
    Exit;

  FPCurrentFontData := LFontDataPointer;
  with LFontDataPointer^ do
  if Handle <> 0 then
  begin
    FCurrentFont := Handle;
    FCurrentStyle := Style;
    Exit;
  end;

  FCurrentFont := InternalCreateFont(AValue);
  LHandle := InternalGetHandle;
  LOldFont := SelectObject(LHandle, FCurrentFont);

  GetTextExtentPoint32(LHandle, 'W', 1, LSize1);
  GetTextExtentPoint32(LHandle, '!', 1, LSize2);

  with FPCurrentFontData^ do
  begin
    Handle := FCurrentFont;
    CalculateFontMetrics(LHandle, @CharHeight, @CharWidth);
    FixedSize := LSize1.cx = LSize2.cx;
  end;

  SelectObject(LHandle, LOldFont);
  InternalReleaseDC(LHandle);
end;

procedure TTextEditorFontStock.UseFontHandles;
begin
  if not FUsingFontHandles then
  with GFontsInfoManager do
  begin
    LockFontsInfo(FSharedFontsInfo);
    FUsingFontHandles := True;
  end;
end;

{ TTextEditorPaintHelper }

constructor TTextEditorPaintHelper.Create(const ACalcExtentBaseStyle: TFontStyles; const ABaseFont: TFont);
begin
  inherited Create;

  FFontStock := TTextEditorFontStock.Create(ABaseFont);
  FStockBitmap := Vcl.Graphics.TBitmap.Create;
  FStockBitmap.Canvas.Brush.Color := TColors.White;
  FCalcExtentBaseStyle := ACalcExtentBaseStyle;
  SetBaseFont(ABaseFont);
  FColor := TColors.SysWindowText;
  FBackgroundColor := clWindow;
end;

destructor TTextEditorPaintHelper.Destroy;
begin
  FStockBitmap.Free;
  FFontStock.Free;

  inherited;
end;

procedure TTextEditorPaintHelper.BeginDrawing(const AHandle: HDC);
begin
  if FHandle = AHandle then
    Assert(FHandle <> 0)
  else
  begin
    Assert((FHandle = 0) and (AHandle <> 0) and (FDrawingCount = 0));
    FHandle := AHandle;
    FSaveHandle := SaveDC(AHandle);
    SelectObject(AHandle, FCurrentFont);
    Winapi.Windows.SetTextColor(AHandle, ColorToRGB(FColor));
    Winapi.Windows.SetBkColor(AHandle, ColorToRGB(FBackgroundColor));
  end;

  Inc(FDrawingCount);
end;

procedure TTextEditorPaintHelper.EndDrawing;
begin
  Assert(FDrawingCount >= 1);
  Dec(FDrawingCount);
  if FDrawingCount <= 0 then
  begin
    if FHandle <> 0 then
      RestoreDC(FHandle, FSaveHandle);
    FSaveHandle := 0;
    FHandle := 0;
    FDrawingCount := 0;
  end;
end;

procedure TTextEditorPaintHelper.SetBaseFont(const AValue: TFont);
begin
  if Assigned(AValue) then
  begin
    FStockBitmap.Canvas.Font.Assign(AValue);
    FStockBitmap.Canvas.Font.Style := [];
    with FFontStock do
    begin
      SetBaseFont(AValue);
      SetStyle(FCalcExtentBaseStyle);
      FCharWidth := GetCharWidth;
      FCharHeight := GetCharHeight;
      FFixedSizeFont := GetFixedSizeFont;
    end;
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
    with FFontStock do
    begin
      SetStyle(AValue);
      FCharWidth := GetCharWidth;
      FCharHeight := GetCharHeight;
      FFixedSizeFont := GetFixedSizeFont;
    end;
  end;
end;

procedure TTextEditorPaintHelper.SetStyle(const AValue: TFontStyles);
begin
  with FFontStock do
  begin
    SetStyle(AValue);
    Self.FCurrentFont := FontHandle;
  end;
  FStockBitmap.Canvas.Font.Style := AValue;
  if FHandle <> 0 then
    SelectObject(FHandle, FCurrentFont);
end;

procedure TTextEditorPaintHelper.SetForegroundColor(const AValue: TColor);
begin
  if FColor <> AValue then
  begin
    FColor := AValue;
    if FHandle <> 0 then
      SetTextColor(FHandle, ColorToRGB(AValue));
  end;
end;

procedure TTextEditorPaintHelper.SetBackgroundColor(const AValue: TColor);
begin
  if FBackgroundColor <> AValue then
  begin
    FBackgroundColor := AValue;
    if FHandle <> 0 then
      Winapi.Windows.SetBkColor(FHandle, ColorToRGB(AValue));
  end;
end;

initialization

  GFontsInfoManager := TTextEditorFontsInfoManager.Create;

finalization

  GFontsInfoManager.Free;

end.
