unit TextEditor.PopupWindow;

{$I TextEditor.Defines.inc}

interface

uses
  Winapi.Messages, System.Classes, System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics
{$IFDEF ALPHASKINS}
  , acSBUtils, sCommonData, sStyleSimply
{$ENDIF};

type
  TTextEditorPopupWindow = class(TCustomControl)
  private
{$IFDEF ALPHASKINS}
    FScrollWnd: TacScrollWnd;
    FSkinData: TsScrollWndData;
{$ENDIF}
    procedure WMEraseBkgnd(var AMessage: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMMouseActivate(var AMessage: TWMMouseActivate); message WM_MOUSEACTIVATE;
    procedure WMNCCalcSize(var AMessage: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMNCPaint(var AMessage: TWMNCPaint); message WM_NCPAINT;
  protected
    FActiveControl: TWinControl;
    FBorderColor: TColor;
    FBorderWidth: Integer;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Show(const AOrigin: TPoint); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure CreateWnd; override;
    procedure WndProc(var AMessage: TMessage); override;
    property ActiveControl: TWinControl read FActiveControl;
{$IFDEF ALPHASKINS}
    property SkinData: TsScrollWndData read FSkinData write FSkinData;
{$ENDIF}
  end;

implementation

uses
  Winapi.Windows
{$IFDEF ALPHASKINS}
  , System.SysUtils, sConst, sMessages, sSkinProps, sSkinManager
{$ENDIF};

constructor TTextEditorPopupWindow.Create(AOwner: TComponent);
begin
{$IFDEF ALPHASKINS}
  FSkinData := TsScrollWndData.Create(Self, True);
  FSkinData.COC := COC_TsEdit;
  FSkinData.CustomColor := True;
  FSkinData.CustomFont := True;
  StyleElements := [];
{$ENDIF}

  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csNoDesignVisible, csOpaque];

  Ctl3D := False;
  ParentCtl3D := False;
  Visible := False;
  DoubleBuffered := True;

  FBorderColor := clGray;
  FBorderWidth := 0;

  Parent := AOwner as TWinControl;
end;

destructor TTextEditorPopupWindow.Destroy;
begin
{$IFDEF ALPHASKINS}
  if Assigned(FScrollWnd) then
    FreeAndNil(FScrollWnd);

  if Assigned(FSkinData) then
    FreeAndNil(FSkinData);
{$ENDIF}

  inherited Destroy;
end;

procedure TTextEditorPopupWindow.CreateWnd;
begin
  inherited;

{$IFDEF ALPHASKINS}
  FSkinData.Loaded(False);

  if Assigned(FScrollWnd) and FScrollWnd.Destroyed then
    FreeAndNil(FScrollWnd);

  var LSkinParams: TacSkinParams;

  if not Assigned(FScrollWnd) and FSkinData.SkinManager.Active then
    FScrollWnd := TacEditWnd.Create(Handle, SkinData, SkinData.SkinManager, LSkinParams, False);
{$ENDIF}
end;

procedure TTextEditorPopupWindow.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);

  Params.Style := WS_POPUP;
  Params.ExStyle := WS_EX_TOPMOST or WS_EX_NOACTIVATE;
end;

procedure TTextEditorPopupWindow.Show(const AOrigin: TPoint);
begin
  Left := AOrigin.X;
  Top := AOrigin.Y;

  Visible := True;
end;

procedure TTextEditorPopupWindow.WMMouseActivate(var AMessage: TWMMouseActivate);
begin
  AMessage.Result := MA_NOACTIVATE;
end;

procedure TTextEditorPopupWindow.WMEraseBkgnd(var AMessage: TWMEraseBkgnd);
begin
  AMessage.Result := 1;
end;

procedure TTextEditorPopupWindow.WMNCCalcSize(var AMessage: TWMNCCalcSize);
begin
  inherited;

  InflateRect(AMessage.CalcSize_Params.rgrc[0], -FBorderWidth, -FBorderWidth);
end;

procedure TTextEditorPopupWindow.WMNCPaint(var AMessage: TWMNCPaint);
var
  LDC: HDC;
  LRect: TRect;
  LBrush: HBRUSH;
begin
  inherited;

  LDC := GetWindowDC(Handle);
  try
    GetWindowRect(Handle, LRect);
    OffsetRect(LRect, -LRect.Left, -LRect.Top);
    ExcludeClipRect(LDC, FBorderWidth, FBorderWidth, LRect.Right - FBorderWidth, LRect.Bottom - FBorderWidth);

    LBrush := CreateSolidBrush(ColorToRGB(FBorderColor));
    try
      FillRect(LDC, LRect, LBrush);
    finally
      DeleteObject(LBrush);
    end;
  finally
    ReleaseDC(Handle, LDC);
  end;
end;

procedure TTextEditorPopupWindow.WndProc(var AMessage: TMessage);
begin
{$IFDEF ALPHASKINS}
  if csDestroying in ComponentState then
    Exit;

  case AMessage.Msg of
    WM_NCPAINT:
      begin
        WMNCPaint(TWMNCPaint(AMessage));
        Exit;
      end;
    WM_PAINT:
      begin
        inherited;
        WMNCPaint(TWMNCPaint(AMessage));
        Exit;
      end;
  end;

  if AMessage.Msg = SM_ALPHACMD then
  case AMessage.WParamHi of
    AC_CTRLHANDLED:
      begin
        AMessage.Result := 1;
        Exit;
      end;

    AC_GETDEFINDEX:
      begin
        if Assigned(FSkinData.SkinManager) then
          AMessage.Result := FSkinData.SkinManager.SkinCommonInfo.Sections[ssEdit] + 1;

        Exit;
      end;
  end;
{$ENDIF}

  inherited;
end;

end.
