unit FMX.TextEditor.Print.Preview;

{$I FMX.TextEditor.Defines.inc}

{$M+}

interface

uses
  System.Classes, System.SysUtils, System.Types, System.UITypes, FMX.Controls, FMX.Graphics, FMX.StdCtrls, FMX.Types,
  FMX.TextEditor.Border, FMX.TextEditor.Print, FMX.TextEditor.Types;

type
  TTextEditorPreviewPageEvent = procedure(ASender: TObject; APageNumber: Integer) of object;
  TTextEditorPreviewScale = (pscWholePage, pscPageWidth, pscUserScaled);

  [ComponentPlatformsAttribute(pidWin32 or pidWin64 or pidOSX64 or pidOSXArm64 or pidiOSDevice64 or pidiOSSimulatorArm64 or pidAndroidArm32 or pidAndroidArm64 or pidLinux64)]
  TTextEditorPrintPreview = class(TControl)
  strict private const
    MARGIN_WIDTH_LEFT_AND_RIGHT = 12;
    MARGIN_HEIGHT_TOP_AND_BOTTOM = 12;
    SCROLLBAR_SIZE = 16;
    WHEEL_DELTA = 120;
  strict private
    FBackgroundColor: TAlphaColor;
    FBorderStyle: TBorderStyle;
    FEditorPrint: TTextEditorPrint;
    FHorizontalScrollBar: TScrollBar;
    FOnPreviewPage: TTextEditorPreviewPageEvent;
    FOnScaleChange: TNotifyEvent;
    FPageBackgroundColor: TAlphaColor;
    FPageNumber: Integer;
    FPageSize: TPoint;
    FScaleMode: TTextEditorPreviewScale;
    FScalePercent: Integer;
    FScrollPosition: TPoint;
    FUpdatingScrollBars: Boolean;
    FVerticalScrollBar: TScrollBar;
    FVirtualOffset: TPoint;
    FVirtualSize: TPoint;
    FWheelAccumulator: Integer;
    function ClientHeightWithoutBars: Integer;
    function ClientWidthWithoutBars: Integer;
    function GetEditorPrint: TTextEditorPrint;
    function GetPageCount: Integer;
    function GetPageHeight100Percent: Integer;
    function GetPageHeightFromWidth(const AWidth: Integer): Integer;
    function GetPageWidth100Percent: Integer;
    function GetPageWidthFromHeight(const AHeight: Integer): Integer;
    procedure HorizontalScrollBarChange(ASender: TObject);
    procedure SetBackgroundColor(const AValue: TAlphaColor);
    procedure SetBorderStyle(const AValue: TBorderStyle);
    procedure SetEditorPrint(const AValue: TTextEditorPrint);
    procedure SetPageBackgroundColor(const AValue: TAlphaColor);
    procedure SetPageNumberAndNotify(const AValue: Integer);
    procedure SetScaleMode(const AValue: TTextEditorPreviewScale);
    procedure SetScalePercent(const AValue: Integer);
    procedure VerticalScrollBarChange(ASender: TObject);
  protected
    procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Single); override;
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Paint; override;
    procedure Resize; override;
    procedure ScrollHorizontallyFor(const AValue: Integer);
    procedure ScrollHorizontallyTo(const AValue: Integer); virtual;
    procedure ScrollVerticallyFor(const AValue: Integer);
    procedure ScrollVerticallyTo(const AValue: Integer); virtual;
    procedure SizeChanged; virtual;
    procedure UpdateScrollbars; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    procedure FirstPage;
    procedure LastPage;
    procedure NextPage;
    procedure PreviousPage;
    procedure Print;
    procedure UpdatePreview;
    property PageCount: Integer read GetPageCount;
    property PageNumber: Integer read FPageNumber;
  published
    property Align default TAlignLayout.Client;
    property Anchors;
    property BackgroundColor: TAlphaColor read FBackgroundColor write SetBackgroundColor default $FFABABAB;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsSingle;
    property CanFocus default True;
    property Cursor;
    property EditorPrint: TTextEditorPrint read GetEditorPrint write SetEditorPrint;
    property Enabled;
    property Height;
    property Margins;
    property OnClick;
    property OnMouseDown;
    property OnMouseUp;
    property OnPreviewPage: TTextEditorPreviewPageEvent read FOnPreviewPage write FOnPreviewPage;
    property OnScaleChange: TNotifyEvent read FOnScaleChange write FOnScaleChange;
    property PageBackgroundColor: TAlphaColor read FPageBackgroundColor write SetPageBackgroundColor default TAlphaColors.White;
    property PopupMenu;
    property Position;
    property ScaleMode: TTextEditorPreviewScale read FScaleMode write SetScaleMode default pscUserScaled;
    property ScalePercent: Integer read FScalePercent write SetScalePercent default 100;
    property Size;
    property TabOrder;
    property Visible default True;
    property Width;
  end;

implementation

uses
  System.Math, System.Math.Vectors;

{ TTextEditorPrintPreview }

constructor TTextEditorPrintPreview.Create(AOwner: TComponent);
begin
  inherited;

  Align := TAlignLayout.Client;
  FBorderStyle := bsSingle;
  FScaleMode := pscUserScaled;
  FScalePercent := 100;
  FBackgroundColor := $FFABABAB;
  FPageBackgroundColor := TAlphaColors.White;
  Width := 200;
  Height := 120;
  FPageNumber := 1;
  FWheelAccumulator := 0;
  CanFocus := True;
  Visible := True;

  FVerticalScrollBar := TScrollBar.Create(Self);
  FVerticalScrollBar.Stored := False;
  FVerticalScrollBar.Parent := Self;
  FVerticalScrollBar.Orientation := TOrientation.Vertical;
  FVerticalScrollBar.Cursor := crArrow;
  FVerticalScrollBar.Width := SCROLLBAR_SIZE;
  FVerticalScrollBar.SmallChange := 1;
  FVerticalScrollBar.Visible := False;
  FVerticalScrollBar.OnChange := VerticalScrollBarChange;

  FHorizontalScrollBar := TScrollBar.Create(Self);
  FHorizontalScrollBar.Stored := False;
  FHorizontalScrollBar.Parent := Self;
  FHorizontalScrollBar.Orientation := TOrientation.Horizontal;
  FHorizontalScrollBar.Cursor := crArrow;
  FHorizontalScrollBar.Height := SCROLLBAR_SIZE;
  FHorizontalScrollBar.SmallChange := 1;
  FHorizontalScrollBar.Visible := False;
  FHorizontalScrollBar.OnChange := HorizontalScrollBarChange;
end;

function TTextEditorPrintPreview.ClientWidthWithoutBars: Integer;
begin
  Result := Round(Width);

  if FVerticalScrollBar.Visible then
    Dec(Result, SCROLLBAR_SIZE);
end;

function TTextEditorPrintPreview.ClientHeightWithoutBars: Integer;
begin
  Result := Round(Height);

  if FHorizontalScrollBar.Visible then
    Dec(Result, SCROLLBAR_SIZE);
end;

function TTextEditorPrintPreview.GetPageHeightFromWidth(const AWidth: Integer): Integer;
begin
  with FEditorPrint.PrinterInfo do
  Result := if Assigned(FEditorPrint) then MulDiv(AWidth, PhysicalHeight, PhysicalWidth) else MulDiv(AWidth, 141, 100);
end;

function TTextEditorPrintPreview.GetPageWidthFromHeight(const AHeight: Integer): Integer;
begin
  with FEditorPrint.PrinterInfo do
  Result := if Assigned(FEditorPrint) then MulDiv(AHeight, PhysicalWidth, PhysicalHeight) else MulDiv(AHeight, 100, 141);
end;

function TTextEditorPrintPreview.GetPageHeight100Percent: Integer;
begin
  { The print pipeline works in device-independent pixels, which are also the preview's units - 1:1 at 100% }
  Result := if Assigned(FEditorPrint) then FEditorPrint.PrinterInfo.PhysicalHeight else 0;
end;

function TTextEditorPrintPreview.GetPageWidth100Percent: Integer;
begin
  Result := if Assigned(FEditorPrint) then FEditorPrint.PrinterInfo.PhysicalWidth else 0;
end;

procedure TTextEditorPrintPreview.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;

  if (Operation = opRemove) and (AComponent = FEditorPrint) then
    EditorPrint := nil;
end;

procedure TTextEditorPrintPreview.Paint;
var
  LPaperRect: TRectF;
  LCanvasState: TCanvasSaveState;
  LScaleX, LScaleY: Single;

  procedure DrawBorder;
  begin
    if FBorderStyle = bsSingle then
    begin
      Canvas.Stroke.Kind := TBrushKind.Solid;
      Canvas.Stroke.Color := TAlphaColors.Gray;
      Canvas.Stroke.Thickness := 1;
      Canvas.DrawRect(RectF(0.5, 0.5, Width - 0.5, Height - 0.5), 0, 0, [], AbsoluteOpacity);
    end;
  end;

begin
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := FBackgroundColor;
  Canvas.FillRect(LocalRect, 0, 0, [], AbsoluteOpacity);

  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Color := TAlphaColors.Black;
  Canvas.Stroke.Thickness := 1;

  if (csDesigning in ComponentState) or not Assigned(FEditorPrint) then
  begin
    LPaperRect := RectF(MARGIN_WIDTH_LEFT_AND_RIGHT, MARGIN_HEIGHT_TOP_AND_BOTTOM, MARGIN_WIDTH_LEFT_AND_RIGHT + 30,
      MARGIN_HEIGHT_TOP_AND_BOTTOM + 43);
    Canvas.Fill.Color := FPageBackgroundColor;
    Canvas.FillRect(LPaperRect, 0, 0, [], AbsoluteOpacity);
    Canvas.DrawRect(LPaperRect, 0, 0, [], AbsoluteOpacity);
    DrawBorder;
    Exit;
  end;

  LPaperRect.Left := FVirtualOffset.X + FScrollPosition.X;
  LPaperRect.Top := if FScaleMode = pscWholePage then FVirtualOffset.Y else FVirtualOffset.Y + FScrollPosition.Y;
  LPaperRect.Right := LPaperRect.Left + FPageSize.X;
  LPaperRect.Bottom := LPaperRect.Top + FPageSize.Y;

  Canvas.Fill.Color := FPageBackgroundColor;
  Canvas.FillRect(LPaperRect, 0, 0, [], AbsoluteOpacity);
  Canvas.DrawRect(LPaperRect, 0, 0, [], AbsoluteOpacity);

  if (FEditorPrint.PrinterInfo.PhysicalWidth > 0) and (FEditorPrint.PrinterInfo.PhysicalHeight > 0) then
  begin
    LScaleX := FPageSize.X / FEditorPrint.PrinterInfo.PhysicalWidth;
    LScaleY := FPageSize.Y / FEditorPrint.PrinterInfo.PhysicalHeight;

    LCanvasState := Canvas.SaveState;
    try
      Canvas.IntersectClipRect(LPaperRect);
      Canvas.SetMatrix(TMatrix.CreateScaling(LScaleX, LScaleY) * TMatrix.CreateTranslation(LPaperRect.Left, LPaperRect.Top) *
        Canvas.Matrix);
      FEditorPrint.PrintToCanvas(Canvas, FPageNumber);
    finally
      Canvas.RestoreState(LCanvasState);
    end;
  end;

  DrawBorder;
end;

procedure TTextEditorPrintPreview.ScrollHorizontallyFor(const AValue: Integer);
begin
  ScrollHorizontallyTo(FScrollPosition.X + AValue);
end;

procedure TTextEditorPrintPreview.ScrollHorizontallyTo(const AValue: Integer);
var
  LWidth, LPosition, LValue: Integer;
begin
  LWidth := ClientWidthWithoutBars;
  LPosition := LWidth - FVirtualSize.X;
  LValue := AValue;

  if LValue < LPosition then
    LValue := LPosition;

  if LValue > 0 then
    LValue := 0;

  if FScrollPosition.X <> LValue then
  begin
    FScrollPosition.X := LValue;
    UpdateScrollbars;
    Repaint;
  end;
end;

procedure TTextEditorPrintPreview.ScrollVerticallyFor(const AValue: Integer);
begin
  ScrollVerticallyTo(FScrollPosition.Y + AValue);
end;

procedure TTextEditorPrintPreview.ScrollVerticallyTo(const AValue: Integer);
var
  LHeight, LPosition, LValue: Integer;
begin
  LHeight := ClientHeightWithoutBars;
  LPosition := LHeight - FVirtualSize.Y;
  LValue := AValue;

  if LValue < LPosition then
    LValue := LPosition;

  if LValue > 0 then
    LValue := 0;

  if FScrollPosition.Y <> LValue then
  begin
    FScrollPosition.Y := LValue;
    UpdateScrollbars;
    Repaint;
  end;
end;

procedure TTextEditorPrintPreview.Resize;
begin
  inherited;

  if not (csDesigning in ComponentState) then
    SizeChanged;
end;

procedure TTextEditorPrintPreview.SizeChanged;
var
  LWidth: Integer;
begin
  if not Assigned(FEditorPrint) then
    Exit;

  FVerticalScrollBar.Visible := True;
  FHorizontalScrollBar.Visible := FScaleMode = pscUserScaled;

  case FScaleMode of
    pscWholePage:
      begin
        FPageSize.X := ClientWidthWithoutBars - 2 * MARGIN_WIDTH_LEFT_AND_RIGHT;
        FPageSize.Y := ClientHeightWithoutBars - 2 * MARGIN_HEIGHT_TOP_AND_BOTTOM;

        LWidth := GetPageWidthFromHeight(FPageSize.Y);

        if LWidth < FPageSize.X then
          FPageSize.X := LWidth
        else
          FPageSize.Y := GetPageHeightFromWidth(FPageSize.X);
      end;
    pscPageWidth:
      begin
        FPageSize.X := ClientWidthWithoutBars - 2 * MARGIN_WIDTH_LEFT_AND_RIGHT;
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

  if FVirtualSize.X < ClientWidthWithoutBars then
    Inc(FVirtualOffset.X, (ClientWidthWithoutBars - FVirtualSize.X) shr 1);

  FVirtualOffset.Y := MARGIN_HEIGHT_TOP_AND_BOTTOM;

  if FVirtualSize.Y < ClientHeightWithoutBars then
    Inc(FVirtualOffset.Y, (ClientHeightWithoutBars - FVirtualSize.Y) shr 1);

  FScrollPosition := Point(0, 0);
  UpdateScrollbars;
end;

procedure TTextEditorPrintPreview.UpdateScrollbars;
begin
  FUpdatingScrollBars := True;
  try
    case FScaleMode of
      pscWholePage:
        begin
          FVerticalScrollBar.Min := 1;
          FVerticalScrollBar.Max := if Assigned(FEditorPrint) then FEditorPrint.PageCount + 1 else 2;
          FVerticalScrollBar.ViewportSize := 1;
          FVerticalScrollBar.SmallChange := 1;
          FVerticalScrollBar.Value := FPageNumber;
        end;
      pscPageWidth, pscUserScaled:
        begin
          FVerticalScrollBar.Min := 0;
          FVerticalScrollBar.Max := FVirtualSize.Y;
          FVerticalScrollBar.ViewportSize := ClientHeightWithoutBars;
          FVerticalScrollBar.SmallChange := ClientHeightWithoutBars div 10;
          FVerticalScrollBar.Value := -FScrollPosition.Y;

          if FScaleMode = pscUserScaled then
          begin
            FHorizontalScrollBar.Min := 0;
            FHorizontalScrollBar.Max := FVirtualSize.X;
            FHorizontalScrollBar.ViewportSize := ClientWidthWithoutBars;
            FHorizontalScrollBar.SmallChange := ClientWidthWithoutBars div 10;
            FHorizontalScrollBar.Value := -FScrollPosition.X;
          end;
        end;
    end;

    if FVerticalScrollBar.Visible then
      FVerticalScrollBar.SetBounds(Width - SCROLLBAR_SIZE, 0, SCROLLBAR_SIZE,
        Height - (if FHorizontalScrollBar.Visible then SCROLLBAR_SIZE else 0));

    if FHorizontalScrollBar.Visible then
      FHorizontalScrollBar.SetBounds(0, Height - SCROLLBAR_SIZE,
        Width - (if FVerticalScrollBar.Visible then SCROLLBAR_SIZE else 0), SCROLLBAR_SIZE);
  finally
    FUpdatingScrollBars := False;
  end;
end;

procedure TTextEditorPrintPreview.VerticalScrollBarChange(ASender: TObject);
begin
  if FUpdatingScrollBars then
    Exit;

  if FScaleMode = pscWholePage then
  begin
    SetPageNumberAndNotify(Round(FVerticalScrollBar.Value));
    Repaint;
  end
  else
    ScrollVerticallyTo(-Round(FVerticalScrollBar.Value));
end;

procedure TTextEditorPrintPreview.HorizontalScrollBarChange(ASender: TObject);
begin
  if FUpdatingScrollBars then
    Exit;

  if FScaleMode <> pscWholePage then
    ScrollHorizontallyTo(-Round(FHorizontalScrollBar.Value));
end;

procedure TTextEditorPrintPreview.SetBackgroundColor(const AValue: TAlphaColor);
begin
  if FBackgroundColor <> AValue then
  begin
    FBackgroundColor := AValue;

    Repaint;
  end;
end;

procedure TTextEditorPrintPreview.SetBorderStyle(const AValue: TBorderStyle);
begin
  if FBorderStyle <> AValue then
  begin
    FBorderStyle := AValue;

    Repaint;
  end;
end;

procedure TTextEditorPrintPreview.SetPageBackgroundColor(const AValue: TAlphaColor);
begin
  if FPageBackgroundColor <> AValue then
  begin
    FPageBackgroundColor := AValue;

    Repaint;
  end;
end;

function TTextEditorPrintPreview.GetEditorPrint: TTextEditorPrint;
begin
  if not Assigned(FEditorPrint) then
    FEditorPrint := TTextEditorPrint.Create(Self);

  Result := FEditorPrint;
end;

procedure TTextEditorPrintPreview.SetEditorPrint(const AValue: TTextEditorPrint);
begin
  if FEditorPrint <> AValue then
  begin
    FEditorPrint := AValue;

    if Assigned(FEditorPrint) then
      FEditorPrint.FreeNotification(Self);
  end;
end;

procedure TTextEditorPrintPreview.SetPageNumberAndNotify(const AValue: Integer);
begin
  FPageNumber := EnsureRange(AValue, 1, Max(1, PageCount));

  if Assigned(FOnPreviewPage) then
    FOnPreviewPage(Self, FPageNumber);
end;

procedure TTextEditorPrintPreview.SetScaleMode(const AValue: TTextEditorPreviewScale);
begin
  if FScaleMode <> AValue then
  begin
    FScaleMode := AValue;
    FScrollPosition := Point(0, 0);
    SizeChanged;

    if Assigned(FOnScaleChange) then
      FOnScaleChange(Self);

    Repaint;
  end;
end;

procedure TTextEditorPrintPreview.SetScalePercent(const AValue: Integer);
begin
  if FScalePercent <> AValue then
  begin
    FScaleMode := pscUserScaled;
    FScrollPosition := Point(0, 0);
    FScalePercent := AValue;
    SizeChanged;
    Repaint;
  end
  else
    ScaleMode := pscUserScaled;

  if Assigned(FOnScaleChange) then
    FOnScaleChange(Self);
end;

procedure TTextEditorPrintPreview.MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Single);
begin
  inherited;

  if CanFocus then
    SetFocus;
end;

procedure TTextEditorPrintPreview.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  inherited;

  case Key of
    vkNext:
      SetPageNumberAndNotify(FPageNumber + 1);
    vkPrior:
      SetPageNumberAndNotify(FPageNumber - 1);
    vkDown:
      ScrollVerticallyFor(-(ClientHeightWithoutBars div 10));
    vkUp:
      ScrollVerticallyFor(ClientHeightWithoutBars div 10);
    vkRight:
      ScrollHorizontallyFor(-(ClientWidthWithoutBars div 10));
    vkLeft:
      ScrollHorizontallyFor(ClientWidthWithoutBars div 10);
  else
    Exit;
  end;

  Key := 0;
  UpdateScrollbars;
  Repaint;
end;

procedure TTextEditorPrintPreview.MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
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
  LIsNegative: Boolean;
begin
  inherited;

  if Handled then
    Exit;

  LCtrlPressed := ssCtrl in Shift;

  Inc(FWheelAccumulator, WheelDelta);

  while Abs(FWheelAccumulator) >= WHEEL_DELTA do
  begin
    LIsNegative := FWheelAccumulator < 0;

    FWheelAccumulator := Abs(FWheelAccumulator) - WHEEL_DELTA;

    if LIsNegative then
    begin
      if FWheelAccumulator <> 0 then
        FWheelAccumulator := -FWheelAccumulator;

      MouseWheelDown;
    end
    else
      MouseWheelUp;
  end;

  Handled := True;
end;

procedure TTextEditorPrintPreview.UpdatePreview;
var
  LOldScale: Integer;
  LOldMode: TTextEditorPreviewScale;
  LBitmap: TBitmap;
begin
  LOldScale := ScalePercent;
  LOldMode := ScaleMode;

  ScalePercent := 100;

  if Assigned(FEditorPrint) then
  begin
    LBitmap := TBitmap.Create(8, 8);
    try
      FEditorPrint.UpdatePages(LBitmap.Canvas);
    finally
      LBitmap.Free;
    end;
  end;

  SizeChanged;
  Repaint;
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
  SetPageNumberAndNotify(1);
  UpdateScrollbars;
  Repaint;
end;

procedure TTextEditorPrintPreview.LastPage;
begin
  SetPageNumberAndNotify(PageCount);
  UpdateScrollbars;
  Repaint;
end;

procedure TTextEditorPrintPreview.NextPage;
begin
  SetPageNumberAndNotify(FPageNumber + 1);
  UpdateScrollbars;
  Repaint;
end;

procedure TTextEditorPrintPreview.PreviousPage;
begin
  SetPageNumberAndNotify(FPageNumber - 1);
  UpdateScrollbars;
  Repaint;
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

end.
