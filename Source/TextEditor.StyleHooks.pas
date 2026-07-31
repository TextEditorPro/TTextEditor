unit TextEditor.StyleHooks;

interface

uses
  Winapi.Messages, Winapi.UxTheme, Winapi.Windows, System.Classes, System.UITypes, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Themes;

const
  CM_UPDATE_VCLSTYLE_SCROLLBARS = CM_BASE + 2150;

type
  TVclStyleScrollBarsHook = class(TScrollingStyleHook)
  strict private type
    TCornerWindow = class(TWinControl)
    strict private
      FStyleHook: TVclStyleScrollBarsHook;
      procedure WMEraseBkgnd(var AMessage: TMessage); message WM_ERASEBKGND;
      procedure WMPaint(var AMessage: TWMPaint); message WM_PAINT;
    public
      constructor Create(AOwner: TComponent); override;
      property StyleHook: TVclStyleScrollBarsHook read FStyleHook write FStyleHook;
    end;
    procedure WMMouseMove(var AMessage: TWMMouse); message WM_MOUSEMOVE;
  private
    FCornerWnd: TCornerWindow;
    procedure CMUpdateVclStyleScrollbars(var AMessage: TMessage); message CM_UPDATE_VCLSTYLE_SCROLLBARS;
    procedure DrawCorner(DC: HDC);
  protected
    procedure CalcScrollBarsRect; virtual;
    procedure PaintScroll; override;
    procedure UpdateScroll; override;
  public
    destructor Destroy; override;
    property HorzScrollRect;
    property VertScrollRect;
  end;

implementation

uses
  System.Math, System.SysUtils, System.Types;


{ TVclStyleScrollBarsHook.TCornerWindow }

constructor TVclStyleScrollBarsHook.TCornerWindow.Create(AOwner: TComponent);
begin
  inherited;

  ControlStyle := ControlStyle + [csOverrideStylePaint];
  FStyleHook := nil;
end;

procedure TVclStyleScrollBarsHook.TCornerWindow.WMEraseBkgnd(var AMessage: TMessage);
begin
  AMessage.Result := 1;
end;

procedure TVclStyleScrollBarsHook.TCornerWindow.WMPaint(var AMessage: TWMPaint);
var
  LPaintStruct: TPaintStruct;
  LDC: HDC;
begin
  BeginPaint(Handle, LPaintStruct);
  try
    if Assigned(FStyleHook) then
    begin
      LDC := GetWindowDC(Handle);
      try
        FStyleHook.DrawCorner(LDC);
      finally
        ReleaseDC(Handle, LDC);
      end;
    end;
  finally
    EndPaint(Handle, LPaintStruct);
  end;
end;

{ TVclStyleScrollBarsHook }

procedure TVclStyleScrollBarsHook.CalcScrollBarsRect;

  procedure CalcVerticalRects;
  var
    LBarInfo: TScrollBarInfo;
    LResult: BOOL;
  begin
    if not Assigned(VertScrollWnd) then // Might happen, when FInitingScrollBars is set, so InitScrollBars did not yet initialize the members
      Exit;

    LBarInfo.cbSize := SizeOf(LBarInfo);

    LResult := GetScrollBarInfo(Handle, Integer(OBJID_VSCROLL), LBarInfo);

    VertScrollWnd.Visible := (seBorder in Control.StyleElements) and LResult and (not (STATE_SYSTEM_INVISIBLE and LBarInfo.rgstate[0] <> 0));
    VertScrollWnd.Enabled := VertScrollWnd.Visible and (not (STATE_SYSTEM_UNAVAILABLE and LBarInfo.rgstate[0] <> 0));
  end;

  procedure CalcHorizontalRects;
  var
    LBarInfo: TScrollBarInfo;
    LResult: BOOL;
  begin
    if not Assigned(HorzScrollWnd) then // Might happen, when FInitingScrollBars is set, so InitScrollBars did not yet initialize the members
      Exit;

    LBarInfo.cbSize := SizeOf(LBarInfo);

    LResult := GetScrollBarInfo(Handle, Integer(OBJID_HSCROLL), LBarInfo);

    HorzScrollWnd.Visible := (seBorder in Control.StyleElements) and LResult and (not (STATE_SYSTEM_INVISIBLE and LBarInfo.rgstate[0] <> 0));
    HorzScrollWnd.Enabled := HorzScrollWnd.Visible and (not (STATE_SYSTEM_UNAVAILABLE and LBarInfo.rgstate[0] <> 0));
  end;

begin
  CalcVerticalRects;
  CalcHorizontalRects;
end;

procedure TVclStyleScrollBarsHook.UpdateScroll;
var
  LBorderSize: Integer;
  LRect: TRect;
begin
  if VertScrollWnd = nil then
    InitScrollBars;

  CalcScrollBarsRect;

  LBorderSize := 0;

  if HasBorder then
    Inc(LBorderSize, GetSystemMetrics(SM_CYEDGE));

  if Assigned(VertScrollWnd) and not VertScrollWnd.HandleAllocated or Assigned(HorzScrollWnd) and not HorzScrollWnd.HandleAllocated then
  begin
    if VertScrollWnd <> nil then
      FreeAndNil(VertScrollWnd);

    if HorzScrollWnd <> nil then
      FreeAndNil(HorzScrollWnd);

    InitScrollBars;
  end;

  if Control.HandleAllocated then
  begin
    if VertScrollWnd.Visible then
    begin
      LRect := VertScrollRect;

      if Control.UseRightToLeftScrollBar then
        OffsetRect(LRect, -LRect.Left + LBorderSize, 0);

      ShowWindow(VertScrollWnd.Handle, SW_SHOW);
      SetWindowPos(VertScrollWnd.Handle, HWND_TOP, Control.Left + LRect.Left, Control.Top + LRect.Top, LRect.Width, LRect.Height, SWP_SHOWWINDOW);
    end
    else
      ShowWindow(VertScrollWnd.Handle, SW_HIDE);
  end;

  if Control.HandleAllocated then
  begin
    if HorzScrollWnd.Visible then
    begin
      LRect := HorzScrollRect;

      if Control.UseRightToLeftScrollBar then
        OffsetRect(LRect, VertScrollRect.Width, 0);

      ShowWindow(HorzScrollWnd.Handle, SW_SHOW);
      SetWindowPos(HorzScrollWnd.Handle, HWND_TOP, Control.Left + LRect.Left, Control.Top + LRect.Top, LRect.Width, LRect.Height, SWP_SHOWWINDOW);
    end
    else
      ShowWindow(HorzScrollWnd.Handle, SW_HIDE);
  end;

  if Control.HandleAllocated and VertScrollWnd.Visible and HorzScrollWnd.Visible then
  begin
    if FCornerWnd = nil then
    begin
      FCornerWnd := TCornerWindow.CreateParented(GetParent(Control.Handle));
      FCornerWnd.StyleHook := Self;
    end;

    LRect := VertScrollRect;
    if Control.UseRightToLeftScrollBar then
      OffsetRect(LRect, -LRect.Left + LBorderSize, 0);

    ShowWindow(FCornerWnd.Handle, SW_SHOW);
    SetWindowPos(FCornerWnd.Handle, HWND_TOP, Control.Left + LRect.Left, Control.Top + HorzScrollRect.Top, LRect.Width, HorzScrollRect.Height, SWP_SHOWWINDOW);
  end
  else
  if Assigned(FCornerWnd) then
    ShowWindow(FCornerWnd.Handle, SW_HIDE);
end;

procedure TVclStyleScrollBarsHook.PaintScroll;
begin
  inherited;

  if Assigned(FCornerWnd) and FCornerWnd.HandleAllocated then
  begin
    FCornerWnd.Repaint;
    RedrawWindow(FCornerWnd.Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE);
  end;
end;

procedure TVclStyleScrollBarsHook.CMUpdateVclStyleScrollbars(var AMessage: TMessage);
begin
  CalcScrollBarsRect;
  PaintScroll;
end;

procedure TVclStyleScrollBarsHook.DrawCorner(DC: HDC);
var
  LDetails: TThemedElementDetails;
  LRect: TRect;
begin
  if (DC = 0) or not Assigned(FCornerWnd) then
    Exit;

  if (seBorder in Control.StyleElements) and StyleServices.Available then
  begin
    LRect := Rect(0, 0, FCornerWnd.Width, FCornerWnd.Height);
    LDetails := StyleServices.GetElementDetails(tsUpperTrackVertNormal);
    StyleServices.DrawElement(DC, LDetails, LRect);
  end;
end;

destructor TVclStyleScrollBarsHook.Destroy;
begin
  if Assigned(FCornerWnd) then
    FCornerWnd.StyleHook := nil;

  FreeAndNil(FCornerWnd);

  inherited;
end;

procedure TVclStyleScrollBarsHook.WMMouseMove(var AMessage: TWMMouse);
var
  LScrollInfo: TScrollInfo;
  LOverrideMax: Integer;
begin
  if VertSliderState = tsThumbBtnVertPressed then
  begin
    LScrollInfo.fMask := SIF_ALL;
    LScrollInfo.cbSize := SizeOf(LScrollInfo);
    GetScrollInfo(Handle, SB_VERT, LScrollInfo);

    LOverrideMax := LScrollInfo.nMax;

    if 0 < LScrollInfo.nPage then
      LOverrideMax := LScrollInfo.nMax - Integer(LScrollInfo.nPage) + 1;

    ScrollPos := System.Math.EnsureRange(ListPos + (LOverrideMax - LScrollInfo.nMin) *
      ((Mouse.CursorPos.Y - PrevScrollPos) / (VertTrackRect.Height - VertSliderRect.Height)), LScrollInfo.nMin, LOverrideMax);
    LScrollInfo.fMask := SIF_POS;
    LScrollInfo.nPos := Round(ScrollPos);
    SetScrollInfo(Handle, SB_VERT, LScrollInfo, False);
    PostMessage(Handle, WM_VSCROLL, WPARAM(UInt32(SmallPoint(SB_THUMBPOSITION, Min(LScrollInfo.nPos, High(SmallInt))))), 0);

    PaintScroll;
    Handled := True;
    Exit;
  end
  else
  if VertSliderState = tsThumbBtnVertHot then
  begin
    VertSliderState := tsThumbBtnVertNormal;
    PaintScroll;
  end;

  if HorzSliderState = tsThumbBtnHorzPressed then
  begin
    LScrollInfo.fMask := SIF_ALL;
    LScrollInfo.cbSize := SizeOf(LScrollInfo);
    GetScrollInfo(Handle, SB_HORZ, LScrollInfo);

    LOverrideMax := LScrollInfo.nMax;

    if 0 < LScrollInfo.nPage then
      LOverrideMax := LScrollInfo.nMax - Integer(LScrollInfo.nPage) + 1;

    ScrollPos := System.Math.EnsureRange(ListPos + (LOverrideMax - LScrollInfo.nMin) *
      ((Mouse.CursorPos.X - PrevScrollPos) / (HorzTrackRect.Width - HorzSliderRect.Width)), LScrollInfo.nMin, LOverrideMax);
    LScrollInfo.fMask := SIF_POS;
    LScrollInfo.nPos := Round(ScrollPos);
    SetScrollInfo(Handle, SB_HORZ, LScrollInfo, False);
    PostMessage(Handle, WM_HSCROLL, WPARAM(UInt32(SmallPoint(SB_THUMBPOSITION, Min(LScrollInfo.nPos, High(SmallInt))))), 0);

    PaintScroll;
    Handled := True;
    Exit;
  end
  else
  if HorzSliderState = tsThumbBtnHorzHot then
  begin
    HorzSliderState := tsThumbBtnHorzNormal;
    PaintScroll;
  end;

  if (HorzUpState <> tsArrowBtnLeftPressed) and (HorzUpState = tsArrowBtnLeftHot) then
  begin
    HorzUpState := tsArrowBtnLeftNormal;
    PaintScroll;
  end;

  if (HorzDownState <> tsArrowBtnRightPressed) and (HorzDownState = tsArrowBtnRightHot) then
  begin
    HorzDownState := tsArrowBtnRightNormal;
    PaintScroll;
  end;

  if (VertUpState <> tsArrowBtnUpPressed) and (VertUpState = tsArrowBtnUpHot) then
  begin
    VertUpState := tsArrowBtnUpNormal;
    PaintScroll;
  end;

  if (VertDownState <> tsArrowBtnDownPressed) and (VertDownState = tsArrowBtnDownHot) then
  begin
    VertDownState := tsArrowBtnDownNormal;
    PaintScroll;
  end;

  CallDefaultProc(TMessage(AMessage));

  if LeftButtonDown then
    PaintScroll;

  Handled := True;
end;

end.
