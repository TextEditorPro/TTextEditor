unit TextEditor.Compare.ScrollBar;

{$I TextEditor.Defines.inc}

interface

uses
  Winapi.Messages, System.Classes, System.Types, Vcl.Controls, Vcl.Forms, TextEditor
{$IFDEF ALPHASKINS}
  , acSBUtils, sCommonData
{$ENDIF};

type
  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
  TTextEditorCompareScrollBar = class(TCustomControl)
  strict private
    FBorderStyle: TBorderStyle;
    FEditorLeft: TTextEditor;
    FEditorRight: TTextEditor;
    FMouseDownY: Integer;
    FScrollBarClicked: Boolean;
    FScrollBarDragging: Boolean;
    FScrollBarOffsetY: Integer;
    FScrollBarTopLine: Integer;
{$IFDEF ALPHASKINS}
    FScrollWnd: TacScrollWnd;
    FSkinData: TsScrollWndData;
{$ENDIF}
    FScrollBarVisible: Boolean;
    FSystemMetricsCYDRAG: Integer;
    FTopLine: Integer;
    FVisibleLines: Integer;
    procedure DoOnScrollBarClick(const Y: Integer);
    procedure DragMinimap(const AY: Integer);
    procedure FillRect(const ARect: TRect);
    procedure SetBorderStyle(const AValue: TBorderStyle);
    procedure SetEditorLeft(const AEditor: TTextEditor);
    procedure SetEditorRight(const AEditor: TTextEditor);
    procedure SetScrollBarVisible(const AValue: Boolean);
    procedure SetTopLine(const AValue: Integer);
    procedure WMEraseBkgnd(var AMessage: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMPaint(var AMessage: TWMPaint); message WM_PAINT;
    procedure WMSize(var AMessage: TWMSize); message WM_SIZE;
    procedure WMVScroll(var AMessage: TWMScroll); message WM_VSCROLL;
  protected
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure CreateWnd; override;
    procedure Loaded; override;
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(AShift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CanFocus: Boolean; override;
    procedure AfterConstruction; override;
    procedure Invalidate; override;
    procedure UpdateScrollBars;
{$IFDEF ALPHASKINS}
    procedure WndProc(var AMessage: TMessage); override;
    property SkinData: TsScrollWndData read FSkinData write FSkinData;
{$ENDIF}
    property TopLine: Integer read FTopLine write SetTopLine;
  published
    property Align;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsSingle;
    property BorderWidth;
    property EditorLeft: TTextEditor read FEditorLeft write SetEditorLeft;
    property EditorRight: TTextEditor read FEditorRight write SetEditorRight;
    property ScrollBarVisible: Boolean read FScrollBarVisible write SetScrollBarVisible default False;
  end;

implementation

uses
  Winapi.Windows, System.Math, System.SysUtils, System.UITypes, Vcl.Graphics, Vcl.Themes, TextEditor.Consts, TextEditor.Types
{$IFDEF ALPHASKINS}
  , Winapi.CommCtrl, sConst, sMessages, sSkinManager, sStyleSimply, sVCLUtils
{$ENDIF}
{$IFDEF TEXT_EDITOR_STYLE_HOOKS}
  , TextEditor.StyleHooks
{$ENDIF};

constructor TTextEditorCompareScrollBar.Create(AOwner: TComponent);
begin
{$IFDEF ALPHASKINS}
  FSkinData := TsScrollWndData.Create(Self);
  FSkinData.COC := COC_TsMemo;
{$ENDIF}

  inherited Create(AOwner);

  FBorderStyle := bsSingle;
  FScrollBarVisible := False;
  FScrollBarTopLine := 1;
  FTopLine := 1;
  Color := TColors.SysWindow;
  DoubleBuffered := False;
  ControlStyle := ControlStyle + [csOpaque, csSetCaption, csNeedsBorderPaint];
  FSystemMetricsCYDRAG := GetSystemMetrics(SM_CYDRAG);
end;

procedure TTextEditorCompareScrollBar.CreateParams(var AParams: TCreateParams);
const
  ClassStylesOff = CS_VREDRAW or CS_HREDRAW;
  BorderStyles: array[TBorderStyle] of DWORD = (0, WS_BORDER);
begin
  StrDispose(WindowText);
  WindowText := nil;

  inherited CreateParams(AParams);

  with AParams do
  begin
    WindowClass.Style := WindowClass.Style and not ClassStylesOff;
    Style := Style or BorderStyles[FBorderStyle];

    if NewStyleControls and Ctl3D and (FBorderStyle = bsSingle) then
    begin
      Style := Style and not WS_BORDER;
      ExStyle := ExStyle or WS_EX_CLIENTEDGE;
    end;
  end;
end;

destructor TTextEditorCompareScrollBar.Destroy;
begin
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

  inherited Destroy;
end;

procedure TTextEditorCompareScrollBar.AfterConstruction;
begin
  inherited AfterConstruction;

{$IFDEF ALPHASKINS}
  FSkinData.Loaded(False);

  if HandleAllocated then
    RefreshEditScrolls(SkinData, FScrollWnd);
{$ENDIF}
end;

procedure TTextEditorCompareScrollBar.WMEraseBkgnd(var AMessage: TWMEraseBkgnd);
begin
  AMessage.Result := 1;
end;

procedure TTextEditorCompareScrollBar.WMPaint(var AMessage: TWMPaint);
var
  LDC: HDC;
  LCompatibleBitmap: HBITMAP;
  LCompatibleDC: HDC;
  LOldBitmap: HGDIOBJ;
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
    LCompatibleBitmap := CreateCompatibleBitmap(LDC, ClientWidth, ClientHeight);

    ReleaseDC(0, LDC);

    LCompatibleDC := CreateCompatibleDC(0);
    LOldBitmap := SelectObject(LCompatibleDC, LCompatibleBitmap);
    try
      LDC := BeginPaint(Handle, LPaintStruct);
      AMessage.DC := LCompatibleDC;
      WMPaint(AMessage);
      BitBlt(LDC, 0, 0, ClientWidth, ClientHeight, LCompatibleDC, 0, 0, SRCCOPY);
      EndPaint(Handle, LPaintStruct);
    finally
      SelectObject(LCompatibleDC, LOldBitmap);
      DeleteObject(LCompatibleBitmap);
      DeleteDC(LCompatibleDC);
    end;
  end;
end;

procedure TTextEditorCompareScrollBar.FillRect(const ARect: TRect);
begin
  Winapi.Windows.ExtTextOut(Canvas.Handle, 0, 0, ETO_OPAQUE, ARect, '', 0, nil);
end;

procedure TTextEditorCompareScrollBar.Paint;
var
  LClipRect: TRect;
  LLine: Integer;
  LHalfWidth: Integer;
  LStringRecord: TTextEditorStringRecord;
begin
  if not Assigned(FEditorLeft) or not Assigned(FEditorRight) then
    Exit;

  LClipRect := ClientRect;

  Canvas.Brush.Color := FEditorLeft.Colors.EditorBackground;
  FillRect(LClipRect);

  if FEditorLeft.Lines.Count <> FEditorRight.Lines.Count then
    Exit;

  if csDesigning in ComponentState then
    Exit;

  Canvas.Pen.Width := 1;
  Canvas.Pen.Style := psSolid;

  LLine := 0;
  LHalfWidth := ClientWidth shr 1;

  for var LIndex := Max(1, FScrollBarTopLine) to Min(FScrollBarTopLine + ClientHeight - 1, FEditorLeft.Lines.Count) do
  begin
    Canvas.Pen.Color :=
      if (LIndex >= FTopLine) and (LIndex < FTopLine + FVisibleLines) then
        FEditorLeft.Colors.CompareForeground
      else
        FEditorLeft.Colors.CompareBackground;

    LStringRecord := FEditorLeft.Lines.Items^[LIndex - 1];

    if sfModify in LStringRecord.Flags then
    begin
      Canvas.MoveTo(0, LLine);
      Canvas.LineTo(LHalfWidth, LLine);
    end;

    if sfEmptyLine in LStringRecord.Flags then
    begin
      Canvas.MoveTo(LHalfWidth, LLine);
      Canvas.LineTo(ClientWidth, LLine);
    end;

    LStringRecord := FEditorRight.Lines.Items^[LIndex - 1];

    if sfModify in LStringRecord.Flags then
    begin
      Canvas.MoveTo(LHalfWidth, LLine);
      Canvas.LineTo(ClientWidth, LLine);
    end;

    if sfEmptyLine in LStringRecord.Flags then
    begin
      Canvas.MoveTo(0, LLine);
      Canvas.LineTo(LHalfWidth, LLine);
    end;

    Inc(LLine);
  end;

  LClipRect.Top := FTopLine - FScrollBarTopLine;
  LClipRect.Bottom := LClipRect.Top + FVisibleLines;
{$IFDEF ALPHASKINS}
  Canvas.Pen.Color := SkinData.SkinManager.GetHighlightColor;
{$ELSE}
  Canvas.Pen.Color :=
    if TStyleManager.IsCustomStyleActive then
      StyleServices.GetSystemColor(TColors.SysHighlight)
    else
      TColors.SysHighlight;
{$ENDIF}
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(LClipRect);
end;

procedure TTextEditorCompareScrollBar.Invalidate;
begin
  if ComponentState * [csLoading, csDesigning] <> [] then
    Exit;

  if Assigned(FEditorLeft) then
    FVisibleLines := FEditorLeft.VisibleLineCount;

  UpdateScrollBars;

  inherited Invalidate;
end;

procedure TTextEditorCompareScrollBar.Loaded;
begin
  inherited Loaded;

  Invalidate;
end;

procedure TTextEditorCompareScrollBar.CreateWnd;
begin
  inherited CreateWnd;

  UpdateScrollBars;
end;

procedure TTextEditorCompareScrollBar.WMSize(var AMessage: TWMSize);
begin
  Invalidate;
end;

procedure TTextEditorCompareScrollBar.SetBorderStyle(const AValue: TBorderStyle);
begin
  if FBorderStyle <> AValue then
  begin
    FBorderStyle := AValue;

    RecreateWnd;
  end;
end;

procedure TTextEditorCompareScrollBar.SetEditorLeft(const AEditor: TTextEditor);
begin
  FEditorLeft := AEditor;

  if Assigned(FEditorLeft) then
    FEditorLeft.EditorMode := emCompare;

  Invalidate;
end;

procedure TTextEditorCompareScrollBar.SetEditorRight(const AEditor: TTextEditor);
begin
  FEditorRight := AEditor;

  if Assigned(FEditorRight) then
    FEditorRight.EditorMode := emCompare;

  Invalidate;
end;

procedure TTextEditorCompareScrollBar.SetScrollBarVisible(const AValue: Boolean);
begin
  if FScrollBarVisible <> AValue then
  begin
    FScrollBarVisible := AValue;

    UpdateScrollBars;
  end;
end;

procedure TTextEditorCompareScrollBar.UpdateScrollBars;
var
  LScrollInfo: TScrollInfo;
  LVerticalMaxScroll: Integer;
begin
  if not HandleAllocated then
    Exit;

  if ScrollBarVisible and not (csDesigning in ComponentState) then
  begin
    LScrollInfo.cbSize := SizeOf(ScrollInfo);
    LScrollInfo.fMask := SIF_ALL;
    LScrollInfo.fMask := LScrollInfo.fMask or SIF_DISABLENOSCROLL;

    LVerticalMaxScroll := if Assigned(FEditorLeft) then FEditorLeft.LineNumbersCount else 1;

    LScrollInfo.nMin := 1;
    LScrollInfo.nTrackPos := 0;

    if LVerticalMaxScroll <= TMaxValues.ScrollRange then
    begin
      LScrollInfo.nMax := Max(1, LVerticalMaxScroll);
      LScrollInfo.nPage := FVisibleLines;
      LScrollInfo.nPos := TopLine;
    end
    else
    begin
      LScrollInfo.nMax := TMaxValues.ScrollRange;
      LScrollInfo.nPage := MulDiv(TMaxValues.ScrollRange, FVisibleLines, LVerticalMaxScroll);
      LScrollInfo.nPos := MulDiv(TMaxValues.ScrollRange, TopLine, LVerticalMaxScroll);
    end;

    if Assigned(FEditorLeft) and (FEditorLeft.LineNumbersCount <= FVisibleLines) then
      TopLine := 1;

    ShowScrollBar(Handle, SB_VERT, LScrollInfo.nMax > FVisibleLines);
    SetScrollInfo(Handle, SB_VERT, LScrollInfo, True);
    EnableScrollBar(Handle, SB_VERT, ESB_ENABLE_BOTH);
  end
  else
    ShowScrollBar(Handle, SB_VERT, False);
end;

procedure TTextEditorCompareScrollBar.SetTopLine(const AValue: Integer);
var
  LValue: Integer;
begin
  if (csDesigning in ComponentState) or not Assigned(FEditorLeft) then
    Exit;

  LValue := Min(AValue, FEditorLeft.LineNumbersCount - FVisibleLines + 1);
  LValue := Max(LValue, 1);

  if FTopLine <> LValue then
  begin
    FTopLine := LValue;

    FScrollBarTopLine := Max(FTopLine - Abs(Trunc((ClientHeight - FVisibleLines) *
      (FTopLine / Max(FEditorLeft.LineNumbersCount - FVisibleLines, 1)))), 1);

    FEditorLeft.Scroll.Dragging := True;
    FEditorLeft.TopLine := FTopLine;
    FEditorLeft.Scroll.Dragging := False;

    if Assigned(FEditorRight) then
    begin
      FEditorRight.Scroll.Dragging := True;
      FEditorRight.TopLine := FTopLine;
      FEditorRight.Scroll.Dragging := False;
    end;

    UpdateScrollBars;
    Invalidate;
  end;
end;

procedure TTextEditorCompareScrollBar.MouseMove(AShift: TShiftState; X, Y: Integer);
begin
  if FScrollBarClicked then
  begin
    if FScrollBarDragging then
    begin
      DragMinimap(Y);

      if Assigned(FEditorLeft) then
        FEditorLeft.Invalidate;

      if Assigned(FEditorRight) then
        FEditorRight.Invalidate;
    end;

    if not FScrollBarDragging and (ssLeft in AShift) and MouseCapture and (Abs(FMouseDownY - Y) >= FSystemMetricsCYDRAG) then
      FScrollBarDragging := True;

    Exit;
  end;

  inherited MouseMove(AShift, X, Y);
end;

procedure TTextEditorCompareScrollBar.MouseUp(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer);
begin
  FScrollBarClicked := False;
  FScrollBarDragging := False;

  inherited MouseUp(AButton, AShift, X, Y);
end;

procedure TTextEditorCompareScrollBar.MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer);
begin
  if AButton = mbLeft then
    FMouseDownY := Y;

  if not FScrollBarDragging and InRange(X, ClientRect.Left, ClientRect.Right) then
  begin
    DoOnScrollBarClick(Y);
    Invalidate;
    Exit;
  end;

  inherited MouseDown(AButton, AShift, X, Y);
end;

procedure TTextEditorCompareScrollBar.DoOnScrollBarClick(const Y: Integer);
var
  LNewLine: Integer;
begin
  FScrollBarClicked := True;

  LNewLine := Max(1, FScrollBarTopLine + Y);

  if (LNewLine < TopLine) or (LNewLine >= TopLine + FVisibleLines) then
    TopLine := LNewLine - FVisibleLines shr 1;

  FScrollBarOffsetY := Y - (FTopLine - FScrollBarTopLine);
end;

procedure TTextEditorCompareScrollBar.DragMinimap(const AY: Integer);
var
  LTemp, LTemp2: Integer;
  LTopLine: Integer;
begin
  if not Assigned(FEditorLeft) then
    Exit;

  LTemp := FEditorLeft.LineNumbersCount - ClientHeight;
  LTemp2 := Max(AY - FScrollBarOffsetY, 0);

  FScrollBarTopLine := Max(1, Trunc((LTemp / Max(ClientHeight - FVisibleLines, 1)) * LTemp2));

  if (LTemp > 0) and (FScrollBarTopLine > LTemp) then
    FScrollBarTopLine := LTemp;

  LTopLine := Max(1, FScrollBarTopLine + LTemp2);

  if TopLine <> LTopLine then
  begin
    TopLine := LTopLine;
    FScrollBarTopLine := Max(FTopLine - Abs(Trunc((ClientHeight - FVisibleLines) *
      (FTopLine / Max(Max(FEditorLeft.LineNumbersCount, 1) - FVisibleLines, 1)))), 1);

    Repaint;
  end;
end;

procedure TTextEditorCompareScrollBar.WMVScroll(var AMessage: TWMScroll);
var
  LLineNumbersCount: Integer;
begin
  AMessage.Result := 0;
{$IFDEF ALPHASKINS}
  Skindata.BeginUpdate;
{$ENDIF}
  case AMessage.ScrollCode of
    SB_TOP:
      TopLine := 1;
    SB_BOTTOM:
      if Assigned(FEditorLeft) then
        TopLine := FEditorLeft.LineNumbersCount - FVisibleLines + 1;
    SB_LINEDOWN:
      TopLine := TopLine + 1;
    SB_LINEUP:
      TopLine := TopLine - 1;
    SB_PAGEDOWN:
      TopLine := TopLine + FVisibleLines;
    SB_PAGEUP:
      TopLine := TopLine - FVisibleLines;
    SB_THUMBPOSITION, SB_THUMBTRACK:
      begin
        LLineNumbersCount := if Assigned(FEditorLeft) then FEditorLeft.LineNumbersCount else 0;

        TopLine :=
          if LLineNumbersCount > TMaxValues.ScrollRange then
            MulDiv(LLineNumbersCount, Min(Abs(AMessage.Pos), TMaxValues.ScrollRange), TMaxValues.ScrollRange)
          else
            AMessage.Pos;
      end;
  end;
{$IFDEF ALPHASKINS}
  Skindata.EndUpdate(True);
{$ENDIF}
end;

{$IFDEF ALPHASKINS}
procedure TTextEditorCompareScrollBar.WndProc(var AMessage: TMessage);
const
  ALT_KEY_DOWN = $20000000;
begin
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
        Exit;
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
        Perform(WM_NCPAINT, 0, 0);
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

    CommonWndProc(AMessage, FSkinData);

    inherited;

    case AMessage.Msg of
      TB_SETANCHORHIGHLIGHT, WM_SIZE:
        Perform(WM_NCPAINT, 0, 0);
      CM_SHOWINGCHANGED:
        RefreshEditScrolls(SkinData, FScrollWnd);
    end;
  end;
end;
{$ENDIF}

function TTextEditorCompareScrollBar.CanFocus: Boolean;
begin
  Result := if csDesigning in ComponentState then False else inherited CanFocus;
end;

{$IFDEF TEXT_EDITOR_STYLE_HOOKS}

initialization

  TCustomStyleEngine.RegisterStyleHook(TTextEditorCompareScrollBar, TVclStyleScrollBarsHook);

finalization

  TCustomStyleEngine.UnRegisterStyleHook(TTextEditorCompareScrollBar, TVclStyleScrollBarsHook);

{$ENDIF}

end.
