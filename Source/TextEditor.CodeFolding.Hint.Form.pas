unit TextEditor.CodeFolding.Hint.Form;

interface

uses
  Winapi.Messages, Winapi.Windows, System.Classes, System.Types, System.UITypes, Vcl.Controls, Vcl.Forms, Vcl.Graphics;

type
  TTextEditorCodeFoldingHintForm = class(TCustomForm)
  strict private
    FBackgroundColor: TColor;
    FBufferBitmap: TBitmap;
    FBorderColor: TColor;
    FEffectiveItemHeight: Integer;
    FFont: TFont;
    FFontHeight: Integer;
    FFormWidth: Integer;
    FHeightBuffer: Integer;
    FItemHeight: Integer;
    FItemList: TStrings;
    FMargin: Integer;
    FVisibleLines: Integer;
    procedure AdjustMetrics;
    procedure FontChange(ASender: TObject);
    procedure RecalculateItemHeight;
    procedure SetFont(const AValue: TFont);
    procedure SetItemHeight(const AValue: Integer);
    procedure SetItemList(const AValue: TStrings);
    procedure WMEraseBackgrnd(var AMessage: TMessage); message WM_ERASEBKGND;
    procedure WMGetDlgCode(var AMessage: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    procedure Activate; override;
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure Deactivate; override;
    procedure DoKeyPressW(AKey: Char);
    procedure KeyDown(var AKey: Word; AShift: TShiftState); override;
    procedure KeyPressW(var AKey: Char); virtual;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); overload; override;
    destructor Destroy; override;
    procedure Execute(const X, Y: Integer);
    property BackgroundColor: TColor read FBackgroundColor write FBackgroundColor default TColors.SysWindow;
    property BorderColor: TColor read FBorderColor write FBorderColor default TColors.SysBtnFace;
    property Font: TFont read FFont write SetFont;
    property FormWidth: Integer read FFormWidth write FFormWidth; { Don't use the width because it triggers resizing }
    property ItemHeight: Integer read FItemHeight write SetItemHeight default 0;
    property ItemList: TStrings read FItemList write SetItemList;
    property Margin: Integer read FMargin write FMargin default 2;
    property VisibleLines: Integer read FVisibleLines write FVisibleLines;
  end;

implementation

uses
  System.SysUtils, TextEditor, TextEditor.Consts, TextEditor.KeyCommands, TextEditor.PaintHelper, TextEditor.Utils
{$IFDEF ALPHASKINS}, sSkinProvider{$ENDIF};

constructor TTextEditorCodeFoldingHintForm.Create(AOwner: TComponent); //FI:W525 Missing INHERITED call in constructor
begin
  CreateNew(AOwner);

  ControlStyle := ControlStyle + [csNoDesignVisible, csReplicatable];
  if not (csDesigning in ComponentState) then
    ControlStyle := ControlStyle + [csAcceptsControls];

  FBufferBitmap := Vcl.Graphics.TBitmap.Create;
  Visible := False;

  Color := FBackgroundColor;

  FItemList := TStringList.Create;

  FFont := TFont.Create;
  FFont.Name := 'Courier New';
  FFont.Size := 8;

  FBackgroundColor := TColors.SysWindow;
  FBorderColor := TColors.SysBtnFace;

  BorderStyle := bsNone;
  FormStyle := fsStayOnTop;

  FItemHeight := 0;
  FMargin := 2;
  FEffectiveItemHeight := 0;
  RecalculateItemHeight;

  FHeightBuffer := 0;
  FFont.OnChange := FontChange;
{$IFDEF ALPHASKINS}
  with TsSkinProvider.Create(Self) do
  if SkinData.Skinned then
  begin
    DrawNonClientArea := False;
    DrawClientArea := False;
  end;
{$ENDIF}
end;

destructor TTextEditorCodeFoldingHintForm.Destroy;
begin
  FBufferBitmap.Free;
  FItemList.Free;
  FFont.Free;

  inherited Destroy;
end;

procedure TTextEditorCodeFoldingHintForm.CreateParams(var AParams: TCreateParams);
begin
  inherited CreateParams(AParams);

  with AParams do
  if ((Win32Platform and VER_PLATFORM_WIN32_NT) <> 0) and (Win32MajorVersion > 4) and (Win32MinorVersion > 0) then
    WindowClass.Style := WindowClass.Style or CS_DROPSHADOW;
end;

procedure TTextEditorCodeFoldingHintForm.Activate;
begin
  Visible := True;
end;

procedure TTextEditorCodeFoldingHintForm.Deactivate;
begin
  Close;
end;

procedure TTextEditorCodeFoldingHintForm.KeyDown(var AKey: Word; AShift: TShiftState);
var
  LChar: Char;
  LData: Pointer;
  LEditorCommand: TTextEditorCommand;
begin
  with Owner as TCustomTextEditor do
  begin
    LData := nil;
    LChar := TControlCharacters.Null;
    LEditorCommand := TranslateKeyCode(AKey, AShift);
    CommandProcessor(LEditorCommand, LChar, LData);
  end;

  Invalidate;
end;

procedure TTextEditorCodeFoldingHintForm.DoKeyPressW(AKey: Char);
begin
  if AKey <> TControlCharacters.Null then
    KeyPressW(AKey);
end;

procedure TTextEditorCodeFoldingHintForm.KeyPressW(var AKey: Char);
begin
  if Assigned(OnKeyPress) then
    OnKeyPress(Self, AKey);
  Invalidate;
end;

procedure TTextEditorCodeFoldingHintForm.Paint;

  procedure ResetCanvas;
  begin
    with FBufferBitmap.Canvas do
    begin
      Pen.Color := FBackgroundColor;
      Brush.Color := FBackgroundColor;
      Font.Assign(FFont);
    end;
  end;

var
  LRect: TRect;
  LIndex: Integer;
begin
  ResetCanvas;
  LRect := ClientRect;
  Winapi.Windows.ExtTextOut(FBufferBitmap.Canvas.Handle, 0, 0, ETO_OPAQUE, LRect, '', 0, nil);
  FBufferBitmap.Canvas.Pen.Color := FBorderColor;
  FBufferBitmap.Canvas.Rectangle(LRect);

  for LIndex := 0 to FItemList.Count - 1 do
    FBufferBitmap.Canvas.TextOut(FMargin + 1, FEffectiveItemHeight * LIndex + FMargin, FItemList[LIndex]);

  Canvas.Draw(0, 0, FBufferBitmap);
end;

procedure TTextEditorCodeFoldingHintForm.SetItemList(const AValue: TStrings);
begin
  FItemList.Assign(AValue);
end;

procedure TTextEditorCodeFoldingHintForm.SetItemHeight(const AValue: Integer);
begin
  if FItemHeight <> AValue then
  begin
    FItemHeight := AValue;

    RecalculateItemHeight;
  end;
end;

procedure TTextEditorCodeFoldingHintForm.RecalculateItemHeight;
begin
  Canvas.Font.Assign(FFont);
  FFontHeight := TextHeight(Canvas, 'X');

  if FItemHeight > 0 then
    FEffectiveItemHeight := FItemHeight
  else
    FEffectiveItemHeight := FFontHeight;
end;

procedure TTextEditorCodeFoldingHintForm.WMEraseBackgrnd(var AMessage: TMessage);
begin
  AMessage.Result := 1;
end;

procedure TTextEditorCodeFoldingHintForm.WMGetDlgCode(var AMessage: TWMGetDlgCode);
begin
  inherited;

  AMessage.Result := AMessage.Result or DLGC_WANTTAB;
end;

procedure TTextEditorCodeFoldingHintForm.SetFont(const AValue: TFont);
begin
  FFont.Assign(AValue);

  RecalculateItemHeight;
  AdjustMetrics;
end;

procedure TTextEditorCodeFoldingHintForm.FontChange(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  RecalculateItemHeight;
  AdjustMetrics;
end;

procedure TTextEditorCodeFoldingHintForm.Execute(const X, Y: Integer);

  function GetWorkAreaWidth: Integer;
  begin
    Result := Screen.DesktopWidth;
  end;

  function GetWorkAreaHeight: Integer;
  begin
    Result := Screen.DesktopHeight;
  end;

  procedure RecalculateFormPlacement;
  var
    LIndex: Integer;
    LWidth: Integer;
    LHeight: Integer;
    LX, LY: Integer;
    LBorderWidth: Integer;
    LNewWidth: Integer;
  begin
    LX := X;
    LY := Y;
    LWidth := 0;

    LBorderWidth := 2;
    LHeight := FEffectiveItemHeight * ItemList.Count + LBorderWidth + 2 * Margin;

    Canvas.Font.Assign(Font);
    for LIndex := 0 to ItemList.Count - 1 do
    begin
      LNewWidth := Canvas.TextWidth(ItemList[LIndex]);
      if LNewWidth > LWidth then
        LWidth := LNewWidth;
    end;

    Inc(LWidth, 2 * Margin + LBorderWidth + 4);

    if LX + LWidth > GetWorkAreaWidth then
    begin
      LX := GetWorkAreaWidth - LWidth - 5;
      if LX < 0 then
        LX := 0;
    end;

    if LY + LHeight > GetWorkAreaHeight then
    begin
      LY := LY - LHeight - (Owner as TCustomTextEditor).LineHeight - 2;
      if LY < 0 then
        LY := 0;
    end;

    Width := LWidth;
    Height := LHeight;

    SetWindowPos(Handle, HWND_TOP, LX, LY, 0, 0, SWP_NOACTIVATE or SWP_SHOWWINDOW or SWP_NOSIZE);
  end;

begin
  RecalculateFormPlacement;
  AdjustMetrics;

  Visible := True;
end;

procedure TTextEditorCodeFoldingHintForm.AdjustMetrics;
begin
  if (ClientWidth > 0) and (ClientHeight > 0) then
  begin
    FBufferBitmap.Width := ClientWidth;
    FBufferBitmap.Height := ClientHeight;
  end;
end;

end.
