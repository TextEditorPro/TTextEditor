unit TextEditor.PopupWindow;

{$I TextEditor.Defines.inc}

interface

uses
  Winapi.Messages, System.Classes, System.Types, Vcl.Controls
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
  protected
    FActiveControl: TWinControl;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Hide; virtual;
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
  FSkinData.COC := COC_TsListBox;
{$ENDIF}

  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csNoDesignVisible, csReplicatable];

{$IFDEF ALPHASKINS}
  DoubleBuffered := False;
{$ELSE}
  DoubleBuffered := True;
{$ENDIF}
  Ctl3D := False;
  ParentCtl3D := False;
  Parent := AOwner as TWinControl;
  Visible := False;
end;

destructor TTextEditorPopupWindow.Destroy;
begin
  inherited Destroy;

{$IFDEF ALPHASKINS}
  if Assigned(FScrollWnd) then
    FreeAndNil(FScrollWnd);

  if Assigned(FSkinData) then
    FreeAndNil(FSkinData);
{$ENDIF}
end;

procedure TTextEditorPopupWindow.CreateWnd;
{$IFDEF ALPHASKINS}
var
  LSkinParams: TacSkinParams;
{$ENDIF}
begin
  inherited;
{$IFDEF ALPHASKINS}
  FSkinData.Loaded(False);

  if Assigned(FScrollWnd) and FScrollWnd.Destroyed then
    FreeAndNil(FScrollWnd);

  if not Assigned(FScrollWnd) then
    FScrollWnd := TacEditWnd.Create(Handle, SkinData, SkinData.SkinManager, LSkinParams, False);
{$ENDIF}
end;

procedure TTextEditorPopupWindow.Hide;
begin
  SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_NOZORDER or SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_HIDEWINDOW);
  Visible := False;
end;

procedure TTextEditorPopupWindow.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);

  Params.Style := WS_POPUP or WS_BORDER;
end;

procedure TTextEditorPopupWindow.Show(const AOrigin: TPoint);
begin
  SetWindowPos(Handle, HWND_TOPMOST, AOrigin.X, AOrigin.Y, Width, Height, SWP_NOSIZE or SWP_NOACTIVATE or SWP_SHOWWINDOW or
    SWP_NOSENDCHANGING or SWP_NOOWNERZORDER);

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

procedure TTextEditorPopupWindow.WndProc(var AMessage: TMessage);
begin
{$IFDEF ALPHASKINS}
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
    AC_REFRESH:
      if RefreshNeeded(SkinData, AMessage) then
      begin
        RefreshEditScrolls(SkinData, FScrollWnd);
        CommonMessage(AMessage, FSkinData);

        if HandleAllocated and Visible then
          RedrawWindow(Handle, nil, 0, RDWA_REPAINT);

        Exit;
      end;
  end;
{$ENDIF}

  inherited;
end;

end.
