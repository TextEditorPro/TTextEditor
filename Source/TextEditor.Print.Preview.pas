unit TextEditor.Print.Preview;

{$I TextEditor.Defines.inc}

{$M+}

interface

uses
  Winapi.Messages, Winapi.Windows, System.Classes, System.SysUtils, System.UITypes, Vcl.Controls, Vcl.Forms,
  Vcl.Graphics, TextEditor.Print
{$IFDEF ALPHASKINS}, acSBUtils, sCommonData{$ENDIF};

type
  TTextEditorPreviewPageEvent = procedure(ASender: TObject; APageNumber: Integer) of object;
  TTextEditorPreviewScale = (pscWholePage, pscPageWidth, pscUserScaled);

  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
  TTextEditorPrintPreview = class(TCustomControl)
  strict private
    FBorderStyle: TBorderStyle;
    FBuffer: TBitmap;
{$IFDEF ALPHASKINS}
    FSkinData: TsScrollWndData;
{$ENDIF}
    FEditorPrint: TTextEditorPrint;
    FOnPreviewPage: TTextEditorPreviewPageEvent;
    FOnScaleChange: TNotifyEvent;
    FPageBackgroundColor: TColor;
    FPageNumber: Integer;
    FPageSize: TPoint;
    FScaleMode: TTextEditorPreviewScale;
    FScalePercent: Integer;
    FScrollPosition: TPoint;
{$IFDEF ALPHASKINS}
    FScrollWnd: TacScrollWnd;
{$ENDIF}
    FShowScrollHint: Boolean;
    FWheelAccumulator: Integer;
    FVirtualOffset: TPoint;
    FVirtualSize: TPoint;
    function GetEditorPrint: TTextEditorPrint;
    function GetPageCount: Integer;
    function GetPageHeight100Percent: Integer;
    function GetPageHeightFromWidth(AWidth: Integer): Integer;
    function GetPageWidth100Percent: Integer;
    function GetPageWidthFromHeight(AHeight: Integer): Integer;
    procedure PaintPaper(const ACanvas: TCanvas);
    procedure SetBorderStyle(AValue: TBorderStyle);
    procedure SetEditorPrint(AValue: TTextEditorPrint);
    procedure SetPageBackgroundColor(AValue: TColor);
    procedure SetScaleMode(AValue: TTextEditorPreviewScale);
    procedure SetScalePercent(AValue: Integer);
    procedure WMEraseBkgnd(var AMessage: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMGetDlgCode(var AMessage: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMHScroll(var AMessage: TWMHScroll); message WM_HSCROLL;
    procedure WMMouseWheel(var Message: TWMMouseWheel); message WM_MOUSEWHEEL;
    procedure WMPaint(var AMessage: TWMPaint); message WM_PAINT;
    procedure WMSize(var AMessage: TWMSize); message WM_SIZE;
    procedure WMVScroll(var AMessage: TWMVScroll); message WM_VSCROLL;
  protected
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    //procedure PaintWindow(DC: HDC); override;
    procedure ScrollHorizontallyFor(AValue: Integer);
    procedure ScrollHorizontallyTo(AValue: Integer); virtual;
    procedure ScrollVerticallyFor(AValue: Integer);
    procedure ScrollVerticallyTo(AValue: Integer); virtual;
    procedure SizeChanged; virtual;
    procedure UpdateScrollbars; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function CanFocus: Boolean; override;
    procedure AfterConstruction; override;
    procedure FirstPage;
    procedure LastPage;
    procedure Loaded; override;
    procedure NextPage;
    procedure Paint; override;
    procedure PreviousPage;
    procedure Print;
    procedure UpdatePreview;
{$IFDEF ALPHASKINS}
    procedure WndProc(var AMessage: TMessage); override;
{$ENDIF}
    property PageCount: Integer read GetPageCount;
    property PageNumber: Integer read FPageNumber;
  published
    property Align default alClient;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsSingle;
    property Color default TColors.SysAppWorkspace;
    property Cursor;
    property EditorPrint: TTextEditorPrint read GetEditorPrint write SetEditorPrint;
    property OnClick;
    property OnMouseDown;
    property OnMouseUp;
    property OnPreviewPage: TTextEditorPreviewPageEvent read FOnPreviewPage write FOnPreviewPage;
    property OnScaleChange: TNotifyEvent read FOnScaleChange write FOnScaleChange;
    property PageBackgroundColor: TColor read FPageBackgroundColor write SetPageBackgroundColor default TColors.White;
    property PopupMenu;
    property ScaleMode: TTextEditorPreviewScale read FScaleMode write SetScaleMode default pscUserScaled;
    property ScalePercent: Integer read FScalePercent write SetScalePercent default 100;
    property ShowScrollHint: Boolean read FShowScrollHint write FShowScrollHint default True;
{$IFDEF ALPHASKINS}
    property SkinData: TsScrollWndData read FSkinData write FSkinData;
{$ENDIF}
    property Visible default True;
  end;

implementation

uses
  System.Types
{$IFDEF ALPHASKINS}, Winapi.CommCtrl, sConst, sMessages, sStyleSimply, sVCLUtils{$ENDIF};

const
  MARGIN_WIDTH_LEFT_AND_RIGHT = 12;
  MARGIN_HEIGHT_TOP_AND_BOTTOM = 12;

{ TTextEditorPrintPreview }

constructor TTextEditorPrintPreview.Create(AOwner: TComponent);
begin
{$IFDEF ALPHASKINS}
  FSkinData := TsScrollWndData.Create(Self, True);
  FSkinData.COC := COC_TsMemo;
{$ENDIF}

  inherited;

  Align := alClient;
  ControlStyle := ControlStyle + [csOpaque, csNeedsBorderPaint];
  FBorderStyle := bsSingle;
  FScaleMode := pscUserScaled;
  FScalePercent := 100;
  FPageBackgroundColor := TColors.White;
  Width := 200;
  Height := 120;
  ParentColor := False;
  Color := TColors.SysAppWorkspace;
  FPageNumber := 1;
  FShowScrollHint := True;
  FWheelAccumulator := 0;
  Visible := True;

  FBuffer := TBitmap.Create;
end;

procedure TTextEditorPrintPreview.AfterConstruction;
begin
  inherited AfterConstruction;
{$IFDEF ALPHASKINS}
  if HandleAllocated then
    RefreshEditScrolls(SkinData, FScrollWnd);

  UpdateData(FSkinData);
{$ENDIF}
end;

procedure TTextEditorPrintPreview.Loaded;
begin
  inherited Loaded;
{$IFDEF ALPHASKINS}
  FSkinData.Loaded(False);
  RefreshEditScrolls(SkinData, FScrollWnd);
{$ENDIF}
end;

destructor TTextEditorPrintPreview.Destroy;
begin
  FBuffer.Free;
{$IFDEF ALPHASKINS}
  if Assigned(FScrollWnd) then
  begin
    FScrollWnd.Free;
    FScrollWnd := nil;
  end;
  if Assigned(FSkinData) then
  begin
    FSkinData.Free;
    FSkinData := nil;
  end;
{$ENDIF}
  inherited;
end;

procedure TTextEditorPrintPreview.CreateParams(var AParams: TCreateParams);
const
  BorderStyles: array [TBorderStyle] of Cardinal = (0, WS_BORDER);
begin
  inherited;

  with AParams do
  begin
    Style := Style or WS_HSCROLL or WS_VSCROLL or BorderStyles[FBorderStyle] or WS_CLIPCHILDREN;
    if NewStyleControls and Ctl3D and (FBorderStyle = bsSingle) then
    begin
      Style := Style and not WS_BORDER;
      ExStyle := ExStyle or WS_EX_CLIENTEDGE;
    end;
  end;
end;

function TTextEditorPrintPreview.GetPageHeightFromWidth(AWidth: Integer): Integer;
begin
  if Assigned(FEditorPrint) then
  with FEditorPrint.PrinterInfo do
    Result := MulDiv(AWidth, PhysicalHeight, PhysicalWidth)
  else
    Result := MulDiv(AWidth, 141, 100);
end;

function TTextEditorPrintPreview.GetPageWidthFromHeight(AHeight: Integer): Integer;
begin
  if Assigned(FEditorPrint) then
  with FEditorPrint.PrinterInfo do
    Result := MulDiv(AHeight, PhysicalWidth, PhysicalHeight)
  else
    Result := MulDiv(AHeight, 100, 141);
end;

function TTextEditorPrintPreview.GetPageHeight100Percent: Integer;
var
  LHandle: HDC;
  LScreenDPI: Integer;
begin
  Result := 0;
  LHandle := GetDC(0);
  LScreenDPI := GetDeviceCaps(LHandle, LogPixelsY);
  ReleaseDC(0, LHandle);
  if Assigned(FEditorPrint) then
  with FEditorPrint.PrinterInfo do
    Result := MulDiv(PhysicalHeight, LScreenDPI, YPixPerInch);
end;

function TTextEditorPrintPreview.GetPageWidth100Percent: Integer;
var
  LHandle: HDC;
  LScreenDPI: Integer;
begin
  Result := 0;
  LHandle := GetDC(0);
  LScreenDPI := GetDeviceCaps(LHandle, LogPixelsX);
  ReleaseDC(0, LHandle);
  if Assigned(FEditorPrint) then
  with FEditorPrint.PrinterInfo do
    Result := MulDiv(PhysicalWidth, LScreenDPI, XPixPerInch);
end;

procedure TTextEditorPrintPreview.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FEditorPrint) then
    EditorPrint := nil;
end;

procedure TTextEditorPrintPreview.PaintPaper(const ACanvas: TCanvas);
var
  LClipRect, LPaperRect: TRect;
  LPaperRGN: HRGN;
begin
  with ACanvas do
  begin
    LClipRect := ClipRect;
    if IsRectEmpty(LClipRect) then
      Exit;
    Brush.Color := Self.Color;
    Brush.Style := bsSolid;
    Pen.Color := TColors.Black;
    Pen.Width := 1;
    Pen.Style := psSolid;
    if (csDesigning in ComponentState) or not Assigned(FEditorPrint) then
    begin
      Winapi.Windows.ExtTextOut(Handle, 0, 0, ETO_OPAQUE, LClipRect, '', 0, nil);
      Brush.Color := FPageBackgroundColor;
      Rectangle(MARGIN_WIDTH_LEFT_AND_RIGHT, MARGIN_HEIGHT_TOP_AND_BOTTOM, MARGIN_WIDTH_LEFT_AND_RIGHT + 30,
        MARGIN_HEIGHT_TOP_AND_BOTTOM + 43);
      Exit;
    end;
    LPaperRect.Left := FVirtualOffset.X + FScrollPosition.X;
    if ScaleMode = pscWholePage then
      LPaperRect.Top := FVirtualOffset.Y
    else
      LPaperRect.Top := FVirtualOffset.Y + FScrollPosition.Y;
    LPaperRect.Right := LPaperRect.Left + FPageSize.X;
    LPaperRect.Bottom := LPaperRect.Top + FPageSize.Y;
    LPaperRGN := CreateRectRgn(LPaperRect.Left, LPaperRect.Top, LPaperRect.Right + 1, LPaperRect.Bottom + 1);
    if NULLREGION <> ExtSelectClipRgn(Handle, LPaperRGN, RGN_DIFF) then
      Winapi.Windows.ExtTextOut(Handle, 0, 0, ETO_OPAQUE, LClipRect, '', 0, nil);
    SelectClipRgn(Handle, LPaperRGN);
    Brush.Color := FPageBackgroundColor;
    Rectangle(LPaperRect.Left, LPaperRect.Top, LPaperRect.Right + 1, LPaperRect.Bottom + 1);
    DeleteObject(LPaperRGN);
  end;
end;

procedure TTextEditorPrintPreview.Paint;
var
  LOriginalScreenPoint: TPoint;
  LOldMode: Integer;
begin
  PaintPaper(Canvas);

  if (csDesigning in ComponentState) or not Assigned(FEditorPrint) then
    Exit;

  LOldMode := SetMapMode(Canvas.Handle, MM_ANISOTROPIC);
  try
    SetWindowExtEx(Canvas.Handle, FEditorPrint.PrinterInfo.PhysicalWidth, FEditorPrint.PrinterInfo.PhysicalHeight, nil);
    SetViewPortExtEx(Canvas.Handle, FPageSize.X, FPageSize.Y, nil);
    LOriginalScreenPoint.X := MulDiv(FEditorPrint.PrinterInfo.LeftMargin, FPageSize.X, FEditorPrint.PrinterInfo.PhysicalWidth);
    LOriginalScreenPoint.Y := MulDiv(FEditorPrint.PrinterInfo.TopMargin, FPageSize.Y, FEditorPrint.PrinterInfo.PhysicalHeight);
    Inc(LOriginalScreenPoint.X, FVirtualOffset.X + FScrollPosition.X);
    if ScaleMode = pscWholePage then
      Inc(LOriginalScreenPoint.Y, FVirtualOffset.Y)
    else
      Inc(LOriginalScreenPoint.Y, FVirtualOffset.Y + FScrollPosition.Y);
    SetViewPortOrgEx(Canvas.Handle, LOriginalScreenPoint.X, LOriginalScreenPoint.Y, nil);
    IntersectClipRect(Canvas.Handle, 0, 0, FEditorPrint.PrinterInfo.PrintableWidth, FEditorPrint.PrinterInfo.PrintableHeight);

    FEditorPrint.PrintToCanvas(Canvas, FPageNumber);

    SetWindowExtEx(Canvas.Handle, 0, 0, nil);
    SetViewPortExtEx(Canvas.Handle, 0, 0, nil);
    SetViewPortOrgEx(Canvas.Handle, 0, 0, nil);
  finally
    SetMapMode(Canvas.Handle, LOldMode);
  end;
end;

procedure TTextEditorPrintPreview.ScrollHorizontallyFor(AValue: Integer);
begin
  ScrollHorizontallyTo(FScrollPosition.X + AValue);
end;

procedure TTextEditorPrintPreview.ScrollHorizontallyTo(AValue: Integer);
var
  LWidth, LPosition: Integer;
begin
  LWidth := ClientWidth;
  LPosition := LWidth - FVirtualSize.X;

  if AValue < LPosition then
    AValue := LPosition;

  if AValue > 0 then
    AValue := 0;

  if FScrollPosition.X <> AValue then
  begin
    FScrollPosition.X := AValue;
    UpdateScrollbars;
    Invalidate;
  end;
end;

procedure TTextEditorPrintPreview.ScrollVerticallyFor(AValue: Integer);
begin
  ScrollVerticallyTo(FScrollPosition.Y + AValue);
end;

procedure TTextEditorPrintPreview.ScrollVerticallyTo(AValue: Integer);
var
  LHeight, LPosition: Integer;
begin
  LHeight := ClientHeight;
  LPosition := LHeight - FVirtualSize.Y;
  if AValue < LPosition then
    AValue := LPosition;
  if AValue > 0 then
    AValue := 0;
  if FScrollPosition.Y <> AValue then
  begin
    FScrollPosition.Y := AValue;
    UpdateScrollbars;
    Invalidate;
  end;
end;

procedure TTextEditorPrintPreview.SizeChanged;
var
  LWidth: Integer;
begin
  if not (HandleAllocated and Assigned(FEditorPrint)) then
    Exit;

  case FScaleMode of
    pscWholePage:
      begin
        FPageSize.X := ClientWidth - 2 * MARGIN_WIDTH_LEFT_AND_RIGHT;
        FPageSize.Y := ClientHeight - 2 * MARGIN_HEIGHT_TOP_AND_BOTTOM;
        LWidth := GetPageWidthFromHeight(FPageSize.Y);
        if LWidth < FPageSize.X then
          FPageSize.X := LWidth
        else
          FPageSize.Y := GetPageHeightFromWidth(FPageSize.X);
      end;
    pscPageWidth:
      begin
        FPageSize.X := ClientWidth - 2 * MARGIN_WIDTH_LEFT_AND_RIGHT;
        FPageSize.Y := GetPageHeightFromWidth(FPageSize.X);
      end;
    pscUserScaled:
      begin
        FPageSize.X := MulDiv(GetPageWidth100Percent, FScalePercent, 100);
        FPageSize.Y := MulDiv(GetPageHeight100Percent, FScalePercent, 100);
      end;
  end;
  FVirtualSize.X := FPageSize.X + 2 * MARGIN_WIDTH_LEFT_AND_RIGHT;
  FVirtualSize.Y := FPageSize.Y + 2 * MARGIN_HEIGHT_TOP_AND_BOTTOM;
  FVirtualOffset.X := MARGIN_WIDTH_LEFT_AND_RIGHT;
  if FVirtualSize.X < ClientWidth then
    Inc(FVirtualOffset.X, (ClientWidth - FVirtualSize.X) div 2);
  FVirtualOffset.Y := MARGIN_HEIGHT_TOP_AND_BOTTOM;
  if FVirtualSize.Y < ClientHeight then
    Inc(FVirtualOffset.Y, (ClientHeight - FVirtualSize.Y) div 2);
  UpdateScrollbars;
  FScrollPosition := Point(0, 0);
end;

procedure TTextEditorPrintPreview.UpdateScrollbars;
var
  LScrollInfo: TScrollInfo;
begin
  FillChar(LScrollInfo, SizeOf(TScrollInfo), 0);
  LScrollInfo.cbSize := SizeOf(TScrollInfo);
  LScrollInfo.fMask := SIF_ALL;
  case FScaleMode of
    pscWholePage:
      begin
        ShowScrollbar(Handle, SB_HORZ, False);
        LScrollInfo.fMask := LScrollInfo.fMask or SIF_DISABLENOSCROLL;
        LScrollInfo.nMin := 1;
        if Assigned(FEditorPrint) then
        begin
          LScrollInfo.nMax := FEditorPrint.PageCount;
          LScrollInfo.nPos := FPageNumber;
        end
        else
        begin
          LScrollInfo.nMax := 1;
          LScrollInfo.nPos := 1;
        end;
        LScrollInfo.nPage := 1;
        SetScrollInfo(Handle, SB_VERT, LScrollInfo, True);
      end;
    pscPageWidth:
      begin
        ShowScrollbar(Handle, SB_HORZ, False);
        LScrollInfo.fMask := LScrollInfo.fMask or SIF_DISABLENOSCROLL;
        LScrollInfo.nMax := FVirtualSize.Y;
        LScrollInfo.nPos := -FScrollPosition.Y;
        LScrollInfo.nPage := ClientHeight;
        SetScrollInfo(Handle, SB_VERT, LScrollInfo, True);
      end;
    pscUserScaled:
      begin
        ShowScrollbar(Handle, SB_HORZ, True);
        ShowScrollbar(Handle, SB_VERT, True);
        LScrollInfo.fMask := LScrollInfo.fMask or SIF_DISABLENOSCROLL;
        LScrollInfo.nMax := FVirtualSize.X;
        LScrollInfo.nPos := -FScrollPosition.X;
        LScrollInfo.nPage := ClientWidth;
        SetScrollInfo(Handle, SB_HORZ, LScrollInfo, True);
        LScrollInfo.nMax := FVirtualSize.Y;
        LScrollInfo.nPos := -FScrollPosition.Y;
        LScrollInfo.nPage := ClientHeight;
        SetScrollInfo(Handle, SB_VERT, LScrollInfo, True);
      end;
  end;
end;

procedure TTextEditorPrintPreview.SetBorderStyle(AValue: TBorderStyle);
begin
  if FBorderStyle <> AValue then
  begin
    FBorderStyle := AValue;
    RecreateWnd;
  end;
end;

procedure TTextEditorPrintPreview.SetPageBackgroundColor(AValue: TColor);
begin
  if FPageBackgroundColor <> AValue then
  begin
    FPageBackgroundColor := AValue;
    Invalidate;
  end;
end;

function TTextEditorPrintPreview.GetEditorPrint: TTextEditorPrint;
begin
  if not Assigned(FEditorPrint) then
    FEditorPrint := TTextEditorPrint.Create(Self);
  Result := FEditorPrint
end;

procedure TTextEditorPrintPreview.SetEditorPrint(AValue: TTextEditorPrint);
begin
  if FEditorPrint <> AValue then
  begin
    FEditorPrint := AValue;
    if Assigned(FEditorPrint) then
      FEditorPrint.FreeNotification(Self);
  end;
end;

procedure TTextEditorPrintPreview.SetScaleMode(AValue: TTextEditorPreviewScale);
begin
  if FScaleMode <> AValue then
  begin
    FScaleMode := AValue;
    FScrollPosition := Point(0, 0);
    SizeChanged;
    UpdateScrollbars;
    if Assigned(FOnScaleChange) then
      FOnScaleChange(Self);
    Invalidate;
  end;
end;

procedure TTextEditorPrintPreview.SetScalePercent(AValue: Integer);
begin
  if FScalePercent <> AValue then
  begin
    FScaleMode := pscUserScaled;
    FScrollPosition := Point(0, 0);
    FScalePercent := AValue;
    SizeChanged;
    UpdateScrollbars;
    Invalidate;
  end
  else
    ScaleMode := pscUserScaled;
  if Assigned(FOnScaleChange) then
    FOnScaleChange(Self);
end;

procedure TTextEditorPrintPreview.WMEraseBkgnd(var AMessage: TWMEraseBkgnd);
begin
  AMessage.Result := 1;
end;

procedure TTextEditorPrintPreview.WMHScroll(var AMessage: TWMHScroll);
var
  LWidth: Integer;
begin
  AMessage.Result := 0;

  if FScaleMode <> pscWholePage then
  begin
    LWidth := ClientWidth;
    case AMessage.ScrollCode of
      SB_TOP:
        ScrollHorizontallyTo(0);
      SB_BOTTOM:
        ScrollHorizontallyTo(-FVirtualSize.X);
      SB_LINEDOWN:
        ScrollHorizontallyFor(-(LWidth div 10));
      SB_LINEUP:
        ScrollHorizontallyFor(LWidth div 10);
      SB_PAGEDOWN:
        ScrollHorizontallyFor(-(LWidth div 2));
      SB_PAGEUP:
        ScrollHorizontallyFor(LWidth div 2);
      SB_THUMBPOSITION, SB_THUMBTRACK:
      begin
{$IFDEF ALPHASKINS}
        Skindata.BeginUpdate;
{$ENDIF}
        ScrollHorizontallyTo(-AMessage.Pos);
{$IFDEF ALPHASKINS}
        Skindata.EndUpdate(True);
{$ENDIF}
      end;
    end;
  end;
end;

procedure TTextEditorPrintPreview.WMSize(var AMessage: TWMSize);
begin
  inherited;

  if not (csDesigning in ComponentState) then
    SizeChanged;
end;

var
  GScrollHintWnd: THintWindow;

function GetScrollHint: THintWindow;
begin
  if not Assigned(GScrollHintWnd) then
  begin
    GScrollHintWnd := HintWindowClass.Create(Application);
    GScrollHintWnd.Visible := False;
  end;
  Result := GScrollHintWnd;
end;

procedure TTextEditorPrintPreview.WMVScroll(var AMessage: TWMVScroll);
begin
  AMessage.Result := 0;

  case AMessage.ScrollCode of
    SB_TOP:
      ScrollVerticallyTo(0);
    SB_BOTTOM:
      ScrollVerticallyTo(-FVirtualSize.Y);
    SB_LINEDOWN:
      ScrollVerticallyFor(-(ClientHeight div 10));
    SB_LINEUP:
      ScrollVerticallyFor(ClientHeight div 10);
    SB_PAGEDOWN:
      begin
        FPageNumber := FPageNumber + 1;
        if FPageNumber > FEditorPrint.PageCount then
          FPageNumber := FEditorPrint.PageCount;
        Invalidate;
      end;
    SB_PAGEUP:
      begin
        FPageNumber := FPageNumber - 1;
        if FPageNumber < 1 then
          FPageNumber := 1;
        Invalidate;
      end;
    SB_THUMBPOSITION, SB_THUMBTRACK:
      begin
{$IFDEF ALPHASKINS}
        Skindata.BeginUpdate;
{$ENDIF}
        ScrollVerticallyTo(-AMessage.Pos);
{$IFDEF ALPHASKINS}
        Skindata.EndUpdate(True);
{$ENDIF}
      end;
  end;
end;

procedure TTextEditorPrintPreview.KeyDown(var Key: Word; Shift: TShiftState);
begin
  case Key of
    vkNext:
      begin
        FPageNumber := FPageNumber + 1;
        if FPageNumber > FEditorPrint.PageCount then
          FPageNumber := FEditorPrint.PageCount;
      end;
    vkPrior:
      begin
        FPageNumber := FPageNumber - 1;
        if FPageNumber < 1 then
          FPageNumber := 1;
      end;
    vkDown:
      ScrollVerticallyFor(-(ClientHeight div 10));
    vkUp:
      ScrollVerticallyFor(ClientHeight div 10);
    vkRight:
      ScrollHorizontallyFor(-(ClientWidth div 10));
    vkLeft:
      ScrollHorizontallyFor(ClientWidth div 10);
  end;
  Invalidate;
end;

procedure TTextEditorPrintPreview.WMMouseWheel(var Message: TWMMouseWheel);
var
  LCtrlPressed: Boolean;

  procedure MouseWheelUp;
  begin
    if LCtrlPressed and (FPageNumber > 1) then
      PreviousPage
    else
      ScrollVerticallyFor(WHEEL_DELTA);
  end;

  procedure MouseWheelDown;
  begin
    if LCtrlPressed and (FPageNumber < PageCount) then
      NextPage
    else
      ScrollVerticallyFor(-WHEEL_DELTA);
  end;

var
  IsNegative: Boolean;
begin
  LCtrlPressed := GetKeyState(vkControl) < 0;

  Inc(FWheelAccumulator, message.WheelDelta);

  while Abs(FWheelAccumulator) >= WHEEL_DELTA do
  begin
    IsNegative := FWheelAccumulator < 0;
    FWheelAccumulator := Abs(FWheelAccumulator) - WHEEL_DELTA;
    if IsNegative then
    begin
      if FWheelAccumulator <> 0 then
        FWheelAccumulator := -FWheelAccumulator;
      MouseWheelDown;
    end
    else
      MouseWheelUp;
  end;
end;

procedure TTextEditorPrintPreview.UpdatePreview;
var
  LOldScale: Integer;
  LOldMode: TTextEditorPreviewScale;
begin
  LOldScale := ScalePercent;
  LOldMode := ScaleMode;
  ScalePercent := 100;
  if Assigned(FEditorPrint) then
    FEditorPrint.UpdatePages(Canvas);
  SizeChanged;
  Invalidate;
  ScaleMode := LOldMode;
  if ScaleMode = pscUserScaled then
    ScalePercent := LOldScale;
  if FPageNumber > FEditorPrint.PageCount then
    FPageNumber := FEditorPrint.PageCount;
  if Assigned(FOnPreviewPage) then
    FOnPreviewPage(Self, FPageNumber);
  UpdateScrollbars;
end;

procedure TTextEditorPrintPreview.FirstPage;
begin
  FPageNumber := 1;
  if Assigned(FOnPreviewPage) then
    FOnPreviewPage(Self, FPageNumber);
  Invalidate;
end;

procedure TTextEditorPrintPreview.LastPage;
begin
  if Assigned(FEditorPrint) then
    FPageNumber := FEditorPrint.PageCount;
  if Assigned(FOnPreviewPage) then
    FOnPreviewPage(Self, FPageNumber);
  Invalidate;
end;

procedure TTextEditorPrintPreview.NextPage;
begin
  FPageNumber := FPageNumber + 1;
  if Assigned(FEditorPrint) and (FPageNumber > FEditorPrint.PageCount) then
    FPageNumber := FEditorPrint.PageCount;
  if Assigned(FOnPreviewPage) then
    FOnPreviewPage(Self, FPageNumber);
  Invalidate;
end;

procedure TTextEditorPrintPreview.PreviousPage;
begin
  FPageNumber := FPageNumber - 1;
  if Assigned(FEditorPrint) and (FPageNumber < 1) then
    FPageNumber := 1;
  if Assigned(FOnPreviewPage) then
    FOnPreviewPage(Self, FPageNumber);
  Invalidate;
end;

procedure TTextEditorPrintPreview.Print;
begin
  if Assigned(FEditorPrint) then
  begin
    FEditorPrint.Print;
    UpdatePreview;
  end;
end;

function TTextEditorPrintPreview.GetPageCount: Integer;
begin
  Result := EditorPrint.PageCount;
end;

{$IFDEF ALPHASKINS}
procedure TTextEditorPrintPreview.WndProc(var AMessage: TMessage);
const
  ALT_KEY_DOWN = $20000000;
begin
  { Prevent Alt-Backspace from beeping }
  if (AMessage.Msg = WM_SYSCHAR) and (AMessage.wParam = vkBack) and (AMessage.LParam and ALT_KEY_DOWN <> 0) then
    AMessage.Msg := 0;

  if AMessage.Msg = SM_ALPHACMD then
    case AMessage.WParamHi of
      AC_CTRLHANDLED:
        begin
          AMessage.Result := 1;
          Exit;
        end;

      AC_GETAPPLICATION:
        begin
          AMessage.Result := LRESULT(Application);
          Exit
        end;

      AC_REMOVESKIN:
        if (ACUInt(AMessage.LParam) = ACUInt(SkinData.SkinManager)) and not (csDestroying in ComponentState) then
        begin
          if Assigned(FScrollWnd) then
          begin
            FreeAndNil(FScrollWnd);
            RecreateWnd;
          end;
          Exit;
        end;

      AC_REFRESH:
        if (ACUInt(AMessage.LParam) = ACUInt(SkinData.SkinManager)) and Visible then
        begin
          RefreshEditScrolls(SkinData, FScrollWnd);
          CommonMessage(AMessage, FSkinData);
          //Perform(WM_NCPAINT, 0, 0);
          if HandleAllocated and Visible then
            RedrawWindow(Handle, nil, 0, RDWA_REPAINT);
          Exit;
        end;

      AC_SETNEWSKIN:
        if (ACUInt(AMessage.LParam) = ACUInt(SkinData.SkinManager)) then
        begin
          CommonMessage(AMessage, FSkinData);
          Exit;
        end;

      AC_GETDEFINDEX:
        begin
          if Assigned(FSkinData.SkinManager) then
            AMessage.Result := FSkinData.SkinManager.SkinCommonInfo.Sections[ssEdit] + 1;
          Exit;
        end;

      AC_ENDUPDATE:
        Perform(CM_INVALIDATE, 0, 0);
    end;

  if not ControlIsReady(Self) or not Assigned(FSkinData) or not FSkinData.Skinned then
    inherited
  else
  begin
    if AMessage.Msg = SM_ALPHACMD then
      case AMessage.WParamHi of
        AC_ENDPARENTUPDATE:
          if FSkinData.Updating then
          begin
            if not InUpdating(FSkinData, True) then
              Perform(WM_NCPAINT, 0, 0);
            Exit;
          end;
      end;

    if CommonWndProc(AMessage, FSkinData) then
      Exit;

    inherited;

    case AMessage.Msg of
      TB_SETANCHORHIGHLIGHT, WM_SIZE:
        Perform(WM_NCPAINT, 0, 0);
      CM_SHOWINGCHANGED:
        RefreshEditScrolls(SkinData, FScrollWnd);
      CM_VISIBLECHANGED, CM_ENABLEDCHANGED, WM_SETFONT:
        FSkinData.Invalidate;
    end;
  end;
end;
{$ENDIF}

function TTextEditorPrintPreview.CanFocus: Boolean;
begin
  if csDesigning in ComponentState then
    Result := False
  else
    Result := inherited CanFocus;
end;

procedure TTextEditorPrintPreview.WMGetDlgCode(var AMessage: TWMGetDlgCode);
begin
  AMessage.Result := DLGC_WANTARROWS or DLGC_WANTCHARS;
end;

procedure TTextEditorPrintPreview.WMPaint(var AMessage: TWMPaint);
var
  LDC, LCompatibleDC: HDC;
  LCompatibleBitmap, LOldBitmap: HBITMAP;
  LPaintStruct: TPaintStruct;
begin
  if AMessage.DC <> 0 then
  begin
    if not (csCustomPaint in ControlState) and (ControlCount = 0) then
      inherited
    else
      PaintHandler(AMessage);
  end
  else
  begin
    LDC := GetDC(0);

    LCompatibleBitmap := CreateCompatibleBitmap(LDC, Width, Height);
    ReleaseDC(0, LDC);
    LCompatibleDC := CreateCompatibleDC(0);
    LOldBitmap := SelectObject(LCompatibleDC, LCompatibleBitmap);
    try
      LDC := BeginPaint(Handle, LPaintStruct);
      AMessage.DC := LCompatibleDC;
      WMPaint(AMessage);
      BitBlt(LDC, 0, 0, Width, Height, LCompatibleDC, 0, 0, SRCCOPY);
      EndPaint(Handle, LPaintStruct);
    finally
      SelectObject(LCompatibleDC, LOldBitmap);
      DeleteObject(LCompatibleBitmap);
      DeleteDC(LCompatibleDC);
    end;
  end;
end;

end.
