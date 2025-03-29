unit TextEditor.StyleHooks;

{ Copyright (c) 1999-2001 digital publishing AG, written by Mike Lischke (public@soft-gems.net, www.soft-gems.net).
  Based on: https://github.com/JAM-Software/Virtual-TreeView/blob/master/Source/VirtualTrees.StyleHooks.pas
  MPL 1.1 license: https://www.mozilla.org/en-US/MPL/1.1/

  Code review for TTextEditor }

interface

{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CAST OFF}
{$WARN UNSAFE_CODE OFF}

{$if CompilerVersion < 34}
  {$DEFINE NOT_USE_VCL_STYLEHOOK}  // Do not use inherited style hook but own code in this class. Needed for older Delphi versions 10.3 and below
{$ifend}

uses
  Winapi.Messages, Winapi.UxTheme, Winapi.Windows, System.Classes, System.UITypes, Vcl.Controls, Vcl.Forms,
  Vcl.Graphics, Vcl.Themes;

const
  CM_UPDATE_VCLSTYLE_SCROLLBARS = CM_BASE + 2050;

type
  TVclStyleScrollBarsHook = class(TScrollingStyleHook)
{$IFDEF NOT_USE_VCL_STYLEHOOK}
  strict private type
  {$REGION 'TVclStyleScrollBarWindow'}
      TScrollWindow = class(TWinControl)
      strict private
        FStyleHook: TVclStyleScrollBarsHook;
        FVertical: Boolean;
        procedure WMEraseBkgnd(var AMessage: TMessage); message WM_ERASEBKGND;
        procedure WMNCHitTest(var AMessage: TWMNCHitTest); message WM_NCHITTEST;
        procedure WMPaint(var AMessage: TWMPaint); message WM_PAINT;
      public
        constructor Create(AOwner: TComponent); override;
        property StyleHook: TVclStyleScrollBarsHook read FStyleHook write FStyleHook;
        property Vertical: Boolean read FVertical write FVertical;
      end;
  {$ENDREGION}
  private
    FHorzScrollWnd: TScrollWindow;
    FLeftButtonDown: Boolean;
    FVertScrollWnd: TScrollWindow;
    function NCMousePosToClient(const APoint: TPoint): TPoint;
    procedure InitScrollBars;
    procedure WMCaptureChanged(var AMessage: TMessage); message WM_CAPTURECHANGED;
    procedure WMEraseBkgnd(var AMessage: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMHScroll(var AMessage: TWMHScroll); message WM_HSCROLL;
    procedure WMKeyDown(var AMessage: TMessage); message WM_KEYDOWN;
    procedure WMKeyUp(var AMessage: TMessage); message WM_KEYUP;
    procedure WMLButtonDown(var AMessage: TWMMouse);  message WM_LBUTTONDOWN;
    procedure WMLButtonUp(var AMessage: TWMMouse); message WM_LBUTTONUP;
    procedure WMMouseWheel(var AMessage: TMessage); message WM_MOUSEWHEEL;
    procedure WMMove(var AMessage: TMessage); message WM_MOVE;
    procedure WMNCLButtonDblClk(var AMessage: TWMMouse); message WM_NCLBUTTONDBLCLK;
    procedure WMNCLButtonDown(var AMessage: TWMMouse); message WM_NCLBUTTONDOWN;
    procedure WMNCLButtonUp(var AMessage: TWMMouse); message WM_NCLBUTTONUP;
    procedure WMNCMouseMove(var AMessage: TWMMouse); message WM_NCMOUSEMOVE;
    procedure WMPosChanged(var AMessage: TMessage); message WM_WINDOWPOSCHANGED;
    procedure WMSize(var AMessage: TMessage); message WM_SIZE;
    procedure WMVScroll(var AMessage: TWMVScroll); message WM_VSCROLL;
{$ENDIF}
    procedure WMMouseMove(var AMessage: TWMMouse); message WM_MOUSEMOVE;
  private
    procedure CMUpdateVclStyleScrollbars(var AMessage: TMessage); message CM_UPDATE_VCLSTYLE_SCROLLBARS;
  protected
    procedure CalcScrollBarsRect; virtual;
    procedure UpdateScroll;{$IF CompilerVersion >= 34}override;{$IFEND}
{$IFDEF NOT_USE_VCL_STYLEHOOK}
    procedure DrawHorzScrollBar(DC: HDC); virtual;
    procedure DrawVertScrollBar(DC: HDC); virtual;
    procedure MouseLeave; override;
    procedure PaintScroll; override;
    property HorzScrollWnd: TScrollWindow read FHorzScrollWnd;
    property LeftButtonDown: Boolean read FLeftButtonDown;
    property VertScrollWnd: TScrollWindow read FVertScrollWnd;
{$ENDIF}
  public
    constructor Create(AControl: TWinControl); override;
{$IFDEF NOT_USE_VCL_STYLEHOOK}
    destructor Destroy; override;
{$ENDIF}
    /// Draws an expand arrow like used in the RAD Studio IDE.
    /// The code is not yet dpi-aware.
    class procedure DrawExpandArrow(pBitmap: TBitmap; pExpanded: Boolean; pColor: TColor = clNone);
    property HorzScrollRect;
    property VertScrollRect;
  end;

implementation

uses
  System.Math, System.SysUtils, System.Types, TextEditor;

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

constructor TVclStyleScrollBarsHook.Create(AControl: TWinControl);
begin
  inherited;

{$IFDEF NOT_USE_VCL_STYLEHOOK}
  VertSliderState := tsThumbBtnVertNormal;
  VertUpState := tsArrowBtnUpNormal;
  VertDownState := tsArrowBtnDownNormal;
  HorzSliderState := tsThumbBtnHorzNormal;
  HorzUpState := tsArrowBtnLeftNormal;
  HorzDownState := tsArrowBtnRightNormal;
{$ENDIF}
end;

class procedure TVclStyleScrollBarsHook.DrawExpandArrow(pBitmap: TBitmap; pExpanded: Boolean; pColor: TColor);
const
  Size: TRect = (Left: 0; Top: 0; Right: 12; Bottom: 12);
  ArrowPoints: array[Boolean, 0..5] of TPoint = (
    ((X:3; Y:1), (X:8; Y:6), (X:3; Y:11), (X:4; Y:11), (X:9; Y:6), (X:3; Y:0)),
    ((X:1; Y:3), (X:6; Y:8), (X:11; Y:3), (X:11; Y:4), (X:6; Y:9), (X:0; Y:3))
  );
var
  LCanvas: TCanvas;
begin
  pBitmap.SetSize(Size.Width, Size.Height);

  LCanvas := pBitmap.Canvas;
  LCanvas.FillRect(Size);

  if pColor = clNone then
    LCanvas.Pen.Color := Vcl.Themes.StyleServices.GetSystemColor(clGrayText)
  else
    LCanvas.Pen.Color := pColor;

  LCanvas.Pen.Width := 1;
  LCanvas.Polyline(ArrowPoints[pExpanded]);
end;

procedure TVclStyleScrollBarsHook.UpdateScroll;
var
  LRect: TRect;
  LBorderSize: Integer;
begin
  if VertScrollWnd = nil then
    InitScrollBars;

  CalcScrollBarsRect;

  LBorderSize := 0;

  if HasBorder then
    Inc(LBorderSize, GetSystemMetrics(SM_CYEDGE));

  if Assigned(VertScrollWnd) and not VertScrollWnd.HandleAllocated or
     Assigned(HorzScrollWnd) and not HorzScrollWnd.HandleAllocated then
  begin
    if VertScrollWnd <> nil then
      FreeAndNil({$IFDEF NOT_USE_VCL_STYLEHOOK}FVertScrollWnd{$ELSE}VertScrollWnd{$ENDIF});

    if HorzScrollWnd <> nil then
      FreeAndNil({$IFDEF NOT_USE_VCL_STYLEHOOK}FHorzScrollWnd{$ELSE}HorzScrollWnd{$ENDIF});

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
      SetWindowPos(VertScrollWnd.Handle, HWND_TOP, Control.Left + LRect.Left, Control.Top + LRect.Top, LRect.Width,
        Control.Height - (LBorderSize * 2), SWP_SHOWWINDOW);
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
      SetWindowPos(HorzScrollWnd.Handle, HWND_TOP, Control.Left + LRect.Left, Control.Top + LRect.Top, LRect.Width,
        LRect.Height, SWP_SHOWWINDOW);
    end
    else
      ShowWindow(HorzScrollWnd.Handle, SW_HIDE);
  end;
end;

procedure TVclStyleScrollBarsHook.CMUpdateVclStyleScrollbars(var AMessage: TMessage);
begin
  CalcScrollBarsRect;
  PaintScroll;
end;

{$IFDEF NOT_USE_VCL_STYLEHOOK}

function TVclStyleScrollBarsHook.NCMousePosToClient(const APoint: TPoint): TPoint;
begin
  Result := APoint;

  ScreenToClient(Handle, Result);

  if HasBorder then
  begin
    if HasClientEdge then
      Result.Offset(2, 2)
    else
      Result.Offset(1, 1);
  end;
end;

procedure TVclStyleScrollBarsHook.DrawHorzScrollBar(DC: HDC);
var
  LBitmap: TBitmap;
  LDetails: TThemedElementDetails;
  LRect: TRect;
begin
  if ((Handle = 0) or (DC = 0)) then
    Exit;

  if HorzScrollWnd.Visible and StyleServices.Available and (seBorder in Control.StyleElements) then
  begin
    LBitmap := TBitmap.Create;
    try
      LRect := HorzScrollRect;
      LBitmap.Width := LRect.Width;
      LBitmap.Height := LRect.Height;
      MoveWindowOrg(LBitmap.Canvas.Handle, -LRect.Left, -LRect.Top);

      LRect.Left := HorzUpButtonRect.Right;
      LRect.Right := HorzDownButtonRect.Left;
      LDetails := StyleServices.GetElementDetails(tsUpperTrackHorzNormal);
      StyleServices.DrawElement(LBitmap.Canvas.Handle, LDetails, LRect{$IF CompilerVersion  >= 34}, nil, VertScrollWnd.CurrentPPI{$IFEND});

      if HorzScrollWnd.Enabled then
        LDetails := StyleServices.GetElementDetails(HorzSliderState);

      StyleServices.DrawElement(LBitmap.Canvas.Handle, LDetails, HorzSliderRect{$IF CompilerVersion  >= 34}, nil, VertScrollWnd.CurrentPPI{$IFEND});

      if HorzScrollWnd.Enabled then
        LDetails := StyleServices.GetElementDetails(HorzUpState)
      else
        LDetails := StyleServices.GetElementDetails(tsArrowBtnLeftDisabled);

      StyleServices.DrawElement(LBitmap.Canvas.Handle, LDetails, HorzUpButtonRect{$IF CompilerVersion  >= 34}, nil, VertScrollWnd.CurrentPPI{$IFEND});

      if HorzScrollWnd.Enabled then
        LDetails := StyleServices.GetElementDetails(HorzDownState)
      else
        LDetails := StyleServices.GetElementDetails(tsArrowBtnRightDisabled);

      StyleServices.DrawElement(LBitmap.Canvas.Handle, LDetails, HorzDownButtonRect{$IF CompilerVersion  >= 34}, nil, VertScrollWnd.CurrentPPI{$IFEND});

      LRect := HorzScrollRect;
      MoveWindowOrg(LBitmap.Canvas.Handle, LRect.Left, LRect.Top);
      BitBlt(DC, LRect.Left, LRect.Top, LBitmap.Width, LBitmap.Height, LBitmap.Canvas.Handle, 0, 0, SRCCOPY);
    finally
      LBitmap.Free;
    end;
  end;
end;

procedure TVclStyleScrollBarsHook.DrawVertScrollBar(DC: HDC);
var
  LBitmap: TBitmap;
  LDetails: TThemedElementDetails;
  LRect: TRect;
begin
  if ((Handle = 0) or (DC = 0)) then
    Exit;

  if VertScrollWnd.Visible and StyleServices.Available and (seBorder in Control.StyleElements) then
  begin
    LBitmap := TBitmap.Create;
    try
      LRect := VertScrollRect;
      LBitmap.Width := LRect.Width;
      LBitmap.Height := VertScrollWnd.Height;
      MoveWindowOrg(LBitmap.Canvas.Handle, -LRect.Left, -LRect.Top);

      LRect.Bottom := LBitmap.Height + LRect.Top;
      LDetails := StyleServices.GetElementDetails(tsUpperTrackVertNormal);
      StyleServices.DrawElement(LBitmap.Canvas.Handle, LDetails, LRect{$IF CompilerVersion  >= 34}, nil, VertScrollWnd.CurrentPPI{$ENDIF});

      LRect.Top := VertUpButtonRect.Bottom;
      LRect.Bottom := VertDownButtonRect.Top;
      LDetails := StyleServices.GetElementDetails(tsUpperTrackVertNormal);
      StyleServices.DrawElement(LBitmap.Canvas.Handle, LDetails, LRect{$IF CompilerVersion  >= 34}, nil, VertScrollWnd.CurrentPPI{$ENDIF});

      if VertScrollWnd.Enabled then
        LDetails := StyleServices.GetElementDetails(VertSliderState);

      StyleServices.DrawElement(LBitmap.Canvas.Handle, LDetails, VertSliderRect{$IF CompilerVersion  >= 34}, nil, VertScrollWnd.CurrentPPI{$ENDIF});

      if VertScrollWnd.Enabled then
        LDetails := StyleServices.GetElementDetails(VertUpState)
      else
        LDetails := StyleServices.GetElementDetails(tsArrowBtnUpDisabled);

      StyleServices.DrawElement(LBitmap.Canvas.Handle, LDetails, VertUpButtonRect{$IF CompilerVersion  >= 34}, nil, VertScrollWnd.CurrentPPI{$ENDIF});

      if VertScrollWnd.Enabled then
        LDetails := StyleServices.GetElementDetails(VertDownState)
      else
        LDetails := StyleServices.GetElementDetails(tsArrowBtnDownDisabled);

      StyleServices.DrawElement(LBitmap.Canvas.Handle, LDetails, VertDownButtonRect{$IF CompilerVersion  >= 34}, nil, VertScrollWnd.CurrentPPI{$ENDIF});

      LRect := VertScrollRect;
      MoveWindowOrg(LBitmap.Canvas.Handle, LRect.Left, LRect.Top);
      BitBlt(DC, LRect.Left, LRect.Top, LBitmap.Width, LBitmap.Height, LBitmap.Canvas.Handle, 0, 0, SRCCOPY);
    finally
      LBitmap.Free;
    end;
  end;
end;

procedure TVclStyleScrollBarsHook.MouseLeave;
begin
  inherited;

  if VertSliderState = tsThumbBtnVertHot then
    VertSliderState := tsThumbBtnVertNormal;

  if HorzSliderState = tsThumbBtnHorzHot then
    HorzSliderState := tsThumbBtnHorzNormal;

  if VertUpState = tsArrowBtnUpHot then
    VertUpState := tsArrowBtnUpNormal;

  if VertDownState = tsArrowBtnDownHot then
    VertDownState := tsArrowBtnDownNormal;

  if HorzUpState = tsArrowBtnLeftHot then
    HorzUpState := tsArrowBtnLeftNormal;

  if HorzDownState = tsArrowBtnRightHot then
    HorzDownState := tsArrowBtnRightNormal;

  PaintScroll;
end;

procedure TVclStyleScrollBarsHook.WMCaptureChanged(var AMessage: TMessage);
begin
  if VertScrollWnd.Visible and VertScrollWnd.Enabled then
  begin
    if VertUpState = tsArrowBtnUpPressed then
    begin
      VertUpState := tsArrowBtnUpNormal;
      PaintScroll;
    end;

    if VertDownState = tsArrowBtnDownPressed then
    begin
      VertDownState := tsArrowBtnDownNormal;
      PaintScroll;
    end;
  end;

  if HorzScrollWnd.Visible and HorzScrollWnd.Enabled then
  begin
    if HorzUpState = tsArrowBtnLeftPressed then
    begin
      HorzUpState := tsArrowBtnLeftNormal;
      PaintScroll;
    end;

    if HorzDownState = tsArrowBtnRightPressed then
    begin
      HorzDownState := tsArrowBtnRightNormal;
      PaintScroll;
    end;
  end;

  CallDefaultProc(TMessage(AMessage));
  Handled := True;
end;

destructor TVclStyleScrollBarsHook.Destroy;
begin
  FVertScrollWnd.StyleHook := nil;
  FreeAndNil(FVertScrollWnd);
  FHorzScrollWnd.StyleHook := nil;
  FreeAndNil(FHorzScrollWnd);

  inherited;
end;

procedure TVclStyleScrollBarsHook.WMEraseBkgnd(var AMessage: TWMEraseBkgnd);
begin
  Handled := True;
end;

procedure TVclStyleScrollBarsHook.PaintScroll;
begin
  if FVertScrollWnd.HandleAllocated then
  begin
    FVertScrollWnd.Repaint;
    RedrawWindow(FVertScrollWnd.Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE);
  end;

  if FHorzScrollWnd.HandleAllocated then
  begin
    FHorzScrollWnd.Repaint;
    RedrawWindow(FHorzScrollWnd.Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE);
  end;
end;

procedure TVclStyleScrollBarsHook.WMKeyDown(var AMessage: TMessage);
begin
  CallDefaultProc(TMessage(AMessage));
  PaintScroll;
  Handled := True;
end;

procedure TVclStyleScrollBarsHook.WMKeyUp(var AMessage: TMessage);
begin
  CallDefaultProc(TMessage(AMessage));
  PaintScroll;
  Handled := True;
end;

procedure TVclStyleScrollBarsHook.WMLButtonDown(var AMessage: TWMMouse);
begin
  CallDefaultProc(TMessage(AMessage));
  UpdateScroll;
  Handled := True;
end;

procedure TVclStyleScrollBarsHook.InitScrollBars;
begin
  FVertScrollWnd := TScrollWindow.CreateParented(GetParent(Control.Handle));
  FVertScrollWnd.StyleHook := Self;
  FVertScrollWnd.Vertical := True;

  FHorzScrollWnd := TScrollWindow.CreateParented(GetParent(Control.Handle));
  FHorzScrollWnd.StyleHook := Self;
end;

procedure TVclStyleScrollBarsHook.WMLButtonUp(var AMessage: TWMMouse);
var
  LPoint: TPoint;
begin
  LPoint := Point(AMessage.XPos, AMessage.YPos);
  ScreenToClient(Handle, LPoint);

  if VertScrollWnd.Visible then
  begin
    if VertSliderState = tsThumbBtnVertPressed then
    begin
      PostMessage(Handle, WM_VSCROLL, WPARAM(UInt32(SmallPoint(SB_ENDSCROLL, 0))), 0);
      FLeftButtonDown := False;
      VertSliderState := tsThumbBtnVertNormal;
      PaintScroll;
      Handled := True;
      Mouse.Capture := 0;
      Exit;
    end
    else
    if VertUpState = tsArrowBtnUpPressed then
      VertUpState := tsArrowBtnUpNormal
    else
    if VertDownState = tsArrowBtnDownPressed then
      VertDownState := tsArrowBtnDownNormal;
  end;

  if FHorzScrollWnd.Visible then
  begin
    if HorzSliderState = tsThumbBtnHorzPressed then
    begin
      PostMessage(Handle, WM_HSCROLL, WPARAM(UInt32(SmallPoint(SB_ENDSCROLL, 0))), 0);
      FLeftButtonDown := False;
      HorzSliderState := tsThumbBtnHorzNormal;
      PaintScroll;
      Handled := True;
      Mouse.Capture := 0;
      Exit;
    end
    else
    if HorzUpState = tsArrowBtnLeftPressed then
      HorzUpState := tsArrowBtnLeftNormal
    else
    if HorzDownState = tsArrowBtnRightPressed then
      HorzDownState := tsArrowBtnRightNormal;
  end;

  PaintScroll;

  FLeftButtonDown := False;
end;

procedure TVclStyleScrollBarsHook.WMNCLButtonDown(var AMessage: TWMMouse);
var
  LPoint: TPoint;
  LScrollInfo: TScrollInfo;
begin
  LPoint := NCMousePosToClient(Point(AMessage.XPos, AMessage.YPos));

  if VertScrollWnd.Visible and VertScrollWnd.Enabled then
  begin
    if PtInRect(VertSliderRect, LPoint) then
    begin
      FLeftButtonDown := True;
      LScrollInfo.fMask := SIF_ALL;
      LScrollInfo.cbSize := SizeOf(LScrollInfo);
      GetScrollInfo(Handle, SB_VERT, LScrollInfo);
      ListPos := LScrollInfo.nPos;
      ScrollPos := LScrollInfo.nPos;
      PrevScrollPos := Mouse.CursorPos.Y;
      VertSliderState := tsThumbBtnVertPressed;
      PaintScroll;
      Mouse.Capture := Handle;
      Handled := True;
      Exit;
    end
    else
    if PtInRect(VertDownButtonRect, LPoint) then
      VertDownState := tsArrowBtnDownPressed
    else
    if PtInRect(VertUpButtonRect, LPoint) then
      VertUpState := tsArrowBtnUpPressed;
  end;

  if FHorzScrollWnd.Visible and FHorzScrollWnd.Enabled then
  begin
    if PtInRect(HorzSliderRect, LPoint) then
    begin
      FLeftButtonDown := True;
      LScrollInfo.fMask := SIF_ALL;
      LScrollInfo.cbSize := SizeOf(LScrollInfo);
      GetScrollInfo(Handle, SB_HORZ, LScrollInfo);
      ListPos := LScrollInfo.nPos;
      ScrollPos := LScrollInfo.nPos;
      PrevScrollPos := Mouse.CursorPos.X;
      HorzSliderState := tsThumbBtnHorzPressed;
      PaintScroll;
      Mouse.Capture := Handle;
      Handled := True;
      Exit;
    end
    else
    if PtInRect(HorzDownButtonRect, LPoint) then
      HorzDownState := tsArrowBtnRightPressed
    else
    if PtInRect(HorzUpButtonRect, LPoint) then
      HorzUpState := tsArrowBtnLeftPressed;
  end;

  FLeftButtonDown := True;
  PaintScroll;
end;

procedure TVclStyleScrollBarsHook.WMNCLButtonUp(var AMessage: TWMMouse);
var
  LPoint: TPoint;
begin
  LPoint := NCMousePosToClient(Point(AMessage.XPos, AMessage.YPos));

  if VertScrollWnd.Visible and VertScrollWnd.Enabled then
  begin
    if VertSliderState = tsThumbBtnVertPressed then
    begin
      FLeftButtonDown := False;
      VertSliderState := tsThumbBtnVertNormal;
      PaintScroll;
      Handled := True;
      Exit;
    end;

    if PtInRect(VertDownButtonRect, LPoint) then
      VertDownState := tsArrowBtnDownHot
    else
      VertDownState := tsArrowBtnDownNormal;

    if PtInRect(VertUpButtonRect, LPoint) then
      VertUpState := tsArrowBtnUpHot
    else
      VertUpState := tsArrowBtnUpNormal;
  end;

  if FHorzScrollWnd.Visible and FHorzScrollWnd.Enabled then
  begin
    if HorzSliderState = tsThumbBtnHorzPressed then
    begin
      FLeftButtonDown := False;
      HorzSliderState := tsThumbBtnHorzNormal;
      PaintScroll;
      Handled := True;
      Exit;
    end;

    if PtInRect(HorzDownButtonRect, LPoint) then
      HorzDownState := tsArrowBtnRightHot
    else
      HorzDownState := tsArrowBtnRightNormal;

    if PtInRect(HorzUpButtonRect, LPoint) then
      HorzUpState := tsArrowBtnLeftHot
    else
      HorzUpState := tsArrowBtnLeftNormal;
  end;

  CallDefaultProc(TMessage(AMessage));

  if FHorzScrollWnd.Visible or FVertScrollWnd.Visible then
    PaintScroll;

  Handled := True;
end;

procedure TVclStyleScrollBarsHook.WMNCLButtonDblClk(var AMessage: TWMMouse);
begin
  WMNCLButtonDown(AMessage);
end;

procedure TVclStyleScrollBarsHook.WMHScroll(var AMessage: TWMHScroll);
begin
  CallDefaultProc(TMessage(AMessage));
  PaintScroll;
  Handled := True;
end;

procedure TVclStyleScrollBarsHook.WMMouseWheel(var AMessage: TMessage);
begin
  CallDefaultProc(TMessage(AMessage));
  CalcScrollBarsRect;
  PaintScroll;
  Handled := True;
end;

{$ENDIF}

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

{$IFDEF NOT_USE_VCL_STYLEHOOK}

procedure TVclStyleScrollBarsHook.WMNCMouseMove(var AMessage: TWMMouse);
var
  LPoint: TPoint;
  LMustUpdateScroll: Boolean;
  LPtInRect: Boolean;
begin
  inherited;

  LPoint := NCMousePosToClient(Point(AMessage.XPos, AMessage.YPos));

  LMustUpdateScroll := False;

  if VertScrollWnd.Visible and VertScrollWnd.Enabled then
  begin
    LPtInRect := PtInRect(VertSliderRect, LPoint);

    if LPtInRect and (VertSliderState = tsThumbBtnVertNormal) then
    begin
      VertSliderState := tsThumbBtnVertHot;
      LMustUpdateScroll := True;
    end
    else
    if not LPtInRect and (VertSliderState = tsThumbBtnVertHot) then
    begin
      VertSliderState := tsThumbBtnVertNormal;
      LMustUpdateScroll := True;
    end;

    LPtInRect := PtInRect(VertDownButtonRect, LPoint);

    if LPtInRect and (VertDownState = tsArrowBtnDownNormal) then
    begin
      VertDownState := tsArrowBtnDownHot;
      LMustUpdateScroll := True;
    end
    else
    if not LPtInRect and (VertDownState = tsArrowBtnDownHot) then
    begin
      VertDownState := tsArrowBtnDownNormal;
      LMustUpdateScroll := True;
    end;

    LPtInRect := PtInRect(VertUpButtonRect, LPoint);

    if LPtInRect and (VertUpState = tsArrowBtnUpNormal) then
    begin
      VertUpState := tsArrowBtnUpHot;
      LMustUpdateScroll := True;
    end
    else
    if not LPtInRect and (VertUpState = tsArrowBtnUpHot) then
    begin
      VertUpState := tsArrowBtnUpNormal;
      LMustUpdateScroll := True;
    end;
  end;

  if HorzScrollWnd.Visible and HorzScrollWnd.Enabled then
  begin
    LPtInRect := PtInRect(HorzSliderRect, LPoint);

    if LPtInRect and (HorzSliderState = tsThumbBtnHorzNormal) then
    begin
      HorzSliderState := tsThumbBtnHorzHot;
      LMustUpdateScroll := True;
    end
    else
    if not LPtInRect and (HorzSliderState = tsThumbBtnHorzHot) then
    begin
      HorzSliderState := tsThumbBtnHorzNormal;
      LMustUpdateScroll := True;
    end;

    LPtInRect := PtInRect(HorzDownButtonRect, LPoint);

    if LPtInRect and (HorzDownState = tsArrowBtnRightNormal) then
    begin
      HorzDownState := tsArrowBtnRightHot;
      LMustUpdateScroll := True;
    end
    else
    if not LPtInRect and (HorzDownState = tsArrowBtnRightHot) then
    begin
      HorzDownState := tsArrowBtnRightNormal;
      LMustUpdateScroll := True;
    end;

    LPtInRect := PtInRect(HorzUpButtonRect, LPoint);

    if LPtInRect and (HorzUpState = tsArrowBtnLeftNormal) then
    begin
      HorzUpState := tsArrowBtnLeftHot;
      LMustUpdateScroll := True;
    end
    else
    if not LPtInRect and (HorzUpState = tsArrowBtnLeftHot) then
    begin
      HorzUpState := tsArrowBtnLeftNormal;
      LMustUpdateScroll := True;
    end;
  end;

  if LMustUpdateScroll then
    PaintScroll;
end;

procedure TVclStyleScrollBarsHook.WMSize(var AMessage: TMessage);
begin
  CallDefaultProc(TMessage(AMessage));
  UpdateScroll;
  PaintScroll;
  Handled := True;
end;

procedure TVclStyleScrollBarsHook.WMMove(var AMessage: TMessage);
begin
  CallDefaultProc(TMessage(AMessage));

  UpdateScroll;
  PaintScroll;

  Handled := True;
end;

procedure TVclStyleScrollBarsHook.WMPosChanged(var AMessage: TMessage);
begin
  WMMove(AMessage);
end;

procedure TVclStyleScrollBarsHook.WMVScroll(var AMessage: TWMVScroll);
begin
  CallDefaultProc(TMessage(AMessage));
  PaintScroll;
  Handled := True;
end;

{ TVclStyleScrollBarsHook.TVclStyleScrollBarWindow }

constructor TVclStyleScrollBarsHook.TScrollWindow.Create(AOwner: TComponent);
begin
  inherited;

  ControlStyle := ControlStyle + [csOverrideStylePaint];
  FStyleHook := nil;
  FVertical := False;
end;

procedure TVclStyleScrollBarsHook.TScrollWindow.WMEraseBkgnd(var AMessage: TMessage);
begin
  AMessage.Result := 1;
end;

procedure TVclStyleScrollBarsHook.TScrollWindow.WMNCHitTest(var AMessage: TWMNCHitTest);
begin
  AMessage.Result := HTTRANSPARENT;
end;

procedure TVclStyleScrollBarsHook.TScrollWindow.WMPaint(var AMessage: TWMPaint);
var
  LPaintStruct: TPaintStruct;
  LDC: HDC;
  LRect: TRect;
begin
  BeginPaint(Handle, LPaintStruct);
  try
    if FStyleHook <> nil then
    begin
      LDC := GetWindowDC(Handle);
      try
        if FVertical then
        begin
          LRect := FStyleHook.VertScrollRect;
          MoveWindowOrg(LDC, -LRect.Left, -LRect.Top);
          FStyleHook.DrawVertScrollBar(LDC);
        end
        else
        begin
          LRect := FStyleHook.HorzScrollRect;
          MoveWindowOrg(LDC, -LRect.Left, -LRect.Top);
          FStyleHook.DrawHorzScrollBar(LDC);
        end;
      finally
        ReleaseDC(Handle, LDC);
      end;
    end;
  finally
    EndPaint(Handle, LPaintStruct);
  end;
end;

{$ENDIF}

initialization

  TCustomStyleEngine.RegisterStyleHook(TTextEditor, TVclStyleScrollBarsHook);
  TCustomStyleEngine.RegisterStyleHook(TDBTextEditor, TVclStyleScrollBarsHook);

finalization

  TCustomStyleEngine.UnRegisterStyleHook(TTextEditor, TVclStyleScrollBarsHook);
  TCustomStyleEngine.UnRegisterStyleHook(TDBTextEditor, TVclStyleScrollBarsHook);

end.

