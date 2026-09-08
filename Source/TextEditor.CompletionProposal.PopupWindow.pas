unit TextEditor.CompletionProposal.PopupWindow;

{$I TextEditor.Defines.inc}

interface

uses
  Winapi.Messages, Winapi.Windows, System.Classes, System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, TextEditor.CompletionProposal,
  TextEditor.Lines, TextEditor.PopupWindow, TextEditor.Types, TextEditor.Utils;

type
  TTextEditorValidateEvent = procedure(ASender: TObject; const AEndToken: Char) of object;

  TTextEditorCompletionProposalPopupWindow = class(TTextEditorPopupWindow)
  strict private
    FBitmapBuffer: Vcl.Graphics.TBitmap;
    FCaseSensitive: Boolean;
    FCodeInsight: Boolean;
    FCompletionProposal: TTextEditorCompletionProposal;
    FCurrentString: string;
    FFiltered: Boolean;
    FItemDescriptionWidth: Integer;
    FItemHeight: Integer;
    FItemIndexArray: array of Integer;
    FItemKindWidth: Integer;
    FItemWidth: Integer;
    FItems: TTextEditorCompletionProposalItems;
    FLines: TTextEditorLines;
    FMargin: Integer;
    FOnSelectedItemChange: TNotifyEvent;
    FOnValidate: TTextEditorValidateEvent;
    FScrollBarDragOffset: Integer;
    FScrollBarDragging: Boolean;
    FSelectedLine: Integer;
    FShowDescription: Boolean;
    FTopLine: Integer;
    FUserSizing: Boolean;
    FValueSet: Boolean;
    function GetItemHeight: Integer;
    function ResizeCornerSize: Integer;
    function ResizeGripSize: Integer;
    function ScrollBarArrowSize: Integer;
    function ScrollBarMaxTopLine: Integer;
    function ScrollBarRect: TRect;
    function ScrollBarResizeCornerSize: Integer;
    function ScrollBarThumbRect: TRect;
    function ScrollBarVisible: Boolean;
    function ScrollBarWidth: Integer;
    function UseStyledScrollBar: Boolean;
    procedure ActivateDropShadow(const AHandle: THandle);
    procedure AddKeyHandlers;
    procedure EditorKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
    procedure EditorKeyPress(const ASender: TObject; var AKey: Char);
    procedure HandleDblClick(ASender: TObject);
    procedure HandleOnValidate(ASender: TObject; const AEndToken: Char);
    procedure MoveSelectedLine(const ALineCount: Integer);
    procedure NotifySelectedItemChange;
    procedure PaintFlatScrollBar(const ACanvas: TCanvas);
{$IFDEF ALPHASKINS}
    procedure PaintSkinnedScrollBar(const ACanvas: TCanvas);
{$ENDIF}
    procedure PaintStyledScrollBar(const ACanvas: TCanvas);
    procedure RemoveKeyHandlers;
    procedure SetCurrentString(const AValue: string);
    procedure SetTopLine(const AValue: Integer);
    procedure UpdateScrollBar;
    procedure WMEnterSizeMove(var AMessage: TMessage); message WM_ENTERSIZEMOVE;
    procedure WMExitSizeMove(var AMessage: TMessage); message WM_EXITSIZEMOVE;
    procedure WMGetMinMaxInfo(var AMessage: TWMGetMinMaxInfo); message WM_GETMINMAXINFO;
    procedure WMNCHitTest(var AMessage: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMSizing(var AMessage: TMessage); message WM_SIZING;
    procedure WMVScroll(var AMessage: TWMScroll); message WM_VSCROLL;
  protected
    procedure Paint; override;
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(AShift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer); override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetCurrentInput: string;
    function SelectedItemIndex: Integer;
    procedure Assign(ASource: TPersistent); override;
    procedure Execute(const ACurrentString: string; const APoint: TPoint; const AOptions: TCompletionProposalOptions);
    procedure MouseWheel(AShift: TShiftState; AWheelDelta: Integer);
    property CodeInsight: Boolean read FCodeInsight write FCodeInsight;
    property CurrentString: string read FCurrentString write SetCurrentString;
    property Items: TTextEditorCompletionProposalItems read FItems write FItems;
    property Lines: TTextEditorLines read FLines write FLines;
    property OnSelectedItemChange: TNotifyEvent read FOnSelectedItemChange write FOnSelectedItemChange;
    property OnValidate: TTextEditorValidateEvent read FOnValidate write FOnValidate;
    property ShowDescription: Boolean read FShowDescription write FShowDescription;
    property TopLine: Integer read FTopLine write SetTopLine;
    property UserSizing: Boolean read FUserSizing;
  end;

implementation

uses
  System.Generics.Defaults, System.Math, System.SysUtils, System.UITypes, TextEditor, TextEditor.CompletionProposal.Snippets,
  TextEditor.Consts, TextEditor.Highlighter, TextEditor.KeyCommands, TextEditor.PaintHelper, Vcl.Themes
{$IFDEF ALPHASKINS}
  , acntUtils, acSBUtils, sConst, sGraphUtils, sSkinManager, sStyleSimply
{$ENDIF};

const
  { Logical pixels at 96 dpi }
  RESIZE_GRIP_SIZE = 4;
  RESIZE_CORNER_SIZE = 16;
  SCROLL_BAR_MIN_THUMB_SIZE = 8;
  SCROLL_BAR_RESIZE_CORNER_SIZE = 8;

{$IFDEF ALPHASKINS}
  SCROLL_METRIC_BUTTON_SIZE = 0;
{$ENDIF}

constructor TTextEditorCompletionProposalPopupWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FCaseSensitive := False;
  FFiltered := False;
  FItemHeight := 0;
  FBorderColor := (Owner as TCustomTextEditor).Colors.CompletionProposalBorder;
  FMargin := 2;
  FValueSet := False;
  Visible := False;

  AddKeyHandlers;

  FItems := TTextEditorCompletionProposalItems.Create;

  FBitmapBuffer := Vcl.Graphics.TBitmap.Create;

  OnValidate := HandleOnValidate;
  OnDblClick := HandleDblClick;
end;

destructor TTextEditorCompletionProposalPopupWindow.Destroy;
begin
  RemoveKeyHandlers;

  FBitmapBuffer.Free;

  SetLength(FItemIndexArray, 0);
  FItems.Free;

  inherited Destroy;
end;

procedure TTextEditorCompletionProposalPopupWindow.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCompletionProposal) then
  begin
    FCompletionProposal := ASource as TTextEditorCompletionProposal;

    with FCompletionProposal do
    begin
      Self.FCaseSensitive := cpoCaseSensitive in Options;
      Self.FFiltered := cpoFiltered in Options;
      Self.Font.Assign(Font);
      Self.Constraints.Assign(Constraints);
    end
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorCompletionProposalPopupWindow.AddKeyHandlers;
var
  LTextEditor: TCustomTextEditor;
begin
  LTextEditor := if Assigned(Owner) then Owner as TCustomTextEditor else nil;

  if Assigned(LTextEditor) then
  begin
    LTextEditor.AddKeyPressHandler(EditorKeyPress);
    LTextEditor.AddKeyDownHandler(EditorKeyDown);
  end;
end;

procedure TTextEditorCompletionProposalPopupWindow.RemoveKeyHandlers;
var
  LTextEditor: TCustomTextEditor;
begin
  LTextEditor := if Assigned(Owner) then Owner as TCustomTextEditor else nil;

  if Assigned(LTextEditor) then
  begin
    LTextEditor.RemoveKeyPressHandler(EditorKeyPress);
    LTextEditor.RemoveKeyDownHandler(EditorKeyDown);

    if not (csDestroying in ComponentState) then
      LTextEditor.SetFocus;
  end;
end;

procedure TTextEditorCompletionProposalPopupWindow.ActivateDropShadow(const AHandle: THandle);

  function IsXP: Boolean;
  begin
    Result := (Win32Platform = VER_PLATFORM_WIN32_NT) and CheckWin32Version(5, 1);
  end;

const
  SPI_SETDROPSHADOW = $1025;
  CS_DROPSHADOW = $00020000;
var
  LParam: Boolean;
  LClassLong: UInt64;
begin
  LParam := True;

  if IsXP and SystemParametersInfo(SPI_SETDROPSHADOW, 0, @LParam, 0) then
  begin
    LClassLong := GetClassLong(AHandle, GCL_STYLE);
    LClassLong := LClassLong or CS_DROPSHADOW;

    if SetClassLong(AHandle, GCL_STYLE, LClassLong) <> 0 then
      SendMessage(AHandle, CM_RECREATEWND, 0, 0);
  end;
end;

function TTextEditorCompletionProposalPopupWindow.GetItemHeight: Integer;
var
  LTextEditor: TCustomTextEditor;
begin
  LTextEditor := if Assigned(Owner) then Owner as TCustomTextEditor else nil;

  if Assigned(LTextEditor) then
  begin
    AssignFont(FBitmapBuffer.Canvas.Font, LTextEditor.Fonts.CompletionProposal);

    Result := TextHeight(FBitmapBuffer.Canvas, 'X');
  end
  else
    Result := 0;
end;

procedure TTextEditorCompletionProposalPopupWindow.EditorKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState); //FI:O804 Method parameter is declared but never used
var
  LTextEditor: TCustomTextEditor;
  LTextPosition: TTextEditorTextPosition;
  LChar: Char;
begin
  LTextEditor := if Assigned(Owner) then Owner as TCustomTextEditor else nil;

  case AKey of
    vkReturn, vkTab:
      if Assigned(FOnValidate) then
        FOnValidate(Self, TControlCharacters.Null);
    vkEscape:
      Hide;
    vkLeft:
      if FCurrentString.Length > 0 then
      begin
        CurrentString := Copy(FCurrentString, 1, FCurrentString.Length - 1);

        if Assigned(LTextEditor) then
          LTextEditor.CommandProcessor(TKeyCommands.Left, TControlCharacters.Null, nil);
      end
      else
      begin
        if Assigned(LTextEditor) then
          LTextEditor.CommandProcessor(TKeyCommands.Left, TControlCharacters.Null, nil);

        Hide;
      end;
    vkRight:
      if Assigned(LTextEditor) then
      begin
        LTextPosition := LTextEditor.TextPosition;
        LChar :=
          if LTextPosition.Char <= FLines[LTextPosition.Line].Length then
            FLines[LTextPosition.Line][LTextPosition.Char]
          else
            TCharacters.Space;

        if LTextEditor.IsWordBreakChar(LChar) then
          Hide
        else
          CurrentString := FCurrentString + LChar;

        LTextEditor.CommandProcessor(TKeyCommands.Right, TControlCharacters.Null, nil);
      end;
    vkPrior:
      MoveSelectedLine(-FCompletionProposal.VisibleLines);
    vkNext:
      MoveSelectedLine(FCompletionProposal.VisibleLines);
    vkEnd:
      TopLine := Length(FItemIndexArray) - 1;
    vkHome:
      TopLine := 0;
    vkUp:
      if ssCtrl in AShift then
        FSelectedLine := 0
      else
        MoveSelectedLine(-1);
    vkDown:
      if ssCtrl in AShift then
        FSelectedLine := Length(FItemIndexArray) - 1
      else
        MoveSelectedLine(1);
    vkBack:
      if AShift = [] then
      begin
        if FCurrentString.Length > 0 then
        begin
          CurrentString := Copy(FCurrentString, 1, FCurrentString.Length - 1);

          if Assigned(LTextEditor) then
            LTextEditor.CommandProcessor(TKeyCommands.Backspace, TControlCharacters.Null, nil);
        end
        else
        begin
          if Assigned(LTextEditor) then
            LTextEditor.CommandProcessor(TKeyCommands.Backspace, TControlCharacters.Null, nil);

          Hide;
        end;
      end;
  end;

  AKey := 0;

  Invalidate;
end;

procedure TTextEditorCompletionProposalPopupWindow.EditorKeyPress(const ASender: TObject; var AKey: Char); //FI:O804 Method parameter is declared but never used
begin
  case AKey of
    TControlCharacters.CarriageReturn, TControlCharacters.Tab:
      Hide;
    TCharacters.Space .. High(Char):
      begin
        if not CodeInsight then
        begin
          if not (cpoAutoInvoke in FCompletionProposal.Options) then
            if (Owner as TCustomTextEditor).IsWordBreakChar(AKey) and Assigned(FOnValidate) then
              if AKey = TCharacters.Space then
                FOnValidate(Self, TControlCharacters.Null);

          CurrentString := FCurrentString + AKey;
        end;

        if (cpoAutoInvoke in FCompletionProposal.Options) and (Length(FItemIndexArray) = 0) or
          (Pos(AKey, FCompletionProposal.CloseChars) <> 0) then
          Hide
        else
        if Assigned(OnKeyPress) and not CodeInsight then
          OnKeyPress(Self, AKey);
      end;
    TControlCharacters.Backspace:
      if not CodeInsight then
      with Owner as TCustomTextEditor do
        CommandProcessor(TKeyCommands.Char, AKey, nil);
  end;

  Invalidate;
end;

procedure TTextEditorCompletionProposalPopupWindow.Paint;
var
  LTextEditor: TCustomTextEditor;
  LTop: Integer;
  LItemIndex: Integer;
  LItem: TTextEditorCompletionProposalItem;
  LText, LTemp, LDescription: string;
  LPosition, LWidth, LLeft: Integer;
begin
  LTextEditor := if Assigned(Owner) then Owner as TCustomTextEditor else nil;

  if not Assigned(LTextEditor) then
    Exit;

  with FBitmapBuffer do
  begin
    Canvas.Brush.Color := LTextEditor.Colors.CompletionProposalBackground;

    Height := 0;
    Width := ClientWidth;
    Height := ClientHeight;
    LTop := 0;

    for var LIndex := 0 to Min(FCompletionProposal.VisibleLines, Length(FItemIndexArray) - 1) do
    begin
      if LIndex + TopLine >= Length(FItemIndexArray) then
        Break;

      if (LIndex + TopLine = FSelectedLine) and not CodeInsight then
      begin
        Canvas.Font.Color := LTextEditor.Colors.CompletionProposalSelectedText;
        Canvas.Brush.Color := LTextEditor.Colors.CompletionProposalSelectedBackground;
        Canvas.Pen.Color := LTextEditor.Colors.CompletionProposalSelectedBackground;
        Canvas.Rectangle(0, FItemHeight * LIndex, ClientWidth, FItemHeight * (LIndex + 1));
      end
      else
      begin
        Canvas.Font.Color := LTextEditor.Colors.CompletionProposalForeground;
        Canvas.Brush.Color := LTextEditor.Colors.CompletionProposalBackground;
      end;

      LItemIndex := FItemIndexArray[TopLine + LIndex];

      LItem := FItems[LItemIndex];
      LText := LItem.Keyword;
      LDescription := LItem.Description;
      LLeft := FMargin + FItemKindWidth;

      if not LItem.Kind.IsEmpty then
        Canvas.TextOut(FMargin, LTop, LItem.Kind);

      LPosition := if FCaseSensitive then Pos(FCurrentString, LText) else Pos(AnsiUpperCase(FCurrentString), AnsiUpperCase(LText));

      if LPosition > 0 then
      begin
        LWidth := 0;

        if LPosition > 1 then
        begin
          LTemp := Copy(LText, 1, LPosition - 1);
          Canvas.TextOut(LLeft, LTop, LTemp);
          Inc(LWidth, Canvas.TextWidth(LTemp));
        end;

        Canvas.Font.Style := Canvas.Font.Style + [fsUnderline];
        LTemp := Copy(LText, LPosition, FCurrentString.Length);
        Canvas.TextOut(LLeft + LWidth, LTop, LTemp);
        Inc(LWidth, Canvas.TextWidth(LTemp));
        Canvas.Font.Style := Canvas.Font.Style - [fsUnderline];
        LTemp := Copy(LText, LPosition + FCurrentString.Length);

        if not LTemp.IsEmpty then
          Canvas.TextOut(LLeft + LWidth, LTop, LTemp);
      end
      else
        Canvas.TextOut(LLeft, LTop, LText);

      if ShowDescription then
      begin
        if LItem.Kind.IsEmpty then
          Canvas.TextOut(LLeft + FItemWidth, LTop, LDescription)
        else
          Canvas.TextOut(LLeft + Canvas.TextWidth(LText), LTop, LDescription);
      end;

      Inc(LTop, FItemHeight);
    end;
  end;

  if ScrollBarVisible then
    PaintStyledScrollBar(FBitmapBuffer.Canvas);

  Canvas.Draw(0, 0, FBitmapBuffer);

  PaintClientBorder;
end;

function TTextEditorCompletionProposalPopupWindow.SelectedItemIndex: Integer;
begin
  Result := if (FSelectedLine >= 0) and (FSelectedLine < Length(FItemIndexArray)) then FItemIndexArray[FSelectedLine] else -1;
end;

procedure TTextEditorCompletionProposalPopupWindow.NotifySelectedItemChange;
begin
  if Assigned(FOnSelectedItemChange) then
    FOnSelectedItemChange(Self);
end;

procedure TTextEditorCompletionProposalPopupWindow.MoveSelectedLine(const ALineCount: Integer);
begin
  FSelectedLine := EnsureRange(FSelectedLine + ALineCount, 0, Max(Length(FItemIndexArray) - 1, 0));

  if FSelectedLine >= TopLine + FCompletionProposal.VisibleLines then
    TopLine := FSelectedLine - FCompletionProposal.VisibleLines + 1;

  if FSelectedLine < TopLine then
    TopLine := FSelectedLine;

  NotifySelectedItemChange;
end;

procedure TTextEditorCompletionProposalPopupWindow.SetCurrentString(const AValue: string);

  function MatchItem1(const AIndex: Integer): Boolean;
  var
    LCompareString: string;
  begin
    LCompareString := FItems[AIndex].Keyword;

    Result :=
      if FCaseSensitive then
        Pos(AValue, LCompareString) = 1
      else
        Pos(AnsiUpperCase(AValue), AnsiUpperCase(LCompareString)) = 1;
  end;

  function MatchItem2(const AIndex: Integer): Boolean;
  var
    LCompareString: string;
  begin
    LCompareString := FItems[AIndex].Keyword;

    Result :=
      if FCaseSensitive then
        Pos(AValue, LCompareString) > 1
      else
        Pos(AnsiUpperCase(AValue), AnsiUpperCase(LCompareString)) > 1;
  end;

  function RecalcList(const AShowAllItems: Boolean): Integer;
  var
    LItemsCount: Integer;
  begin
    Result := 0;

    LItemsCount := FItems.Count;

    SetLength(FItemIndexArray, 0);
    SetLength(FItemIndexArray, LItemsCount);

    for var LIndex := 0 to LItemsCount - 1 do
    if AShowAllItems or MatchItem1(LIndex) then
    begin
      FItemIndexArray[Result] := LIndex;
      Inc(Result);
    end;

    for var LIndex := 0 to LItemsCount - 1 do
    if MatchItem2(LIndex) then
    begin
      FItemIndexArray[Result] := LIndex;
      Inc(Result);
    end;

    SetLength(FItemIndexArray, Result);
  end;

var
  LCount: Integer;
  LHeight: Integer;
  LIndex: Integer;
begin
  FCurrentString := AValue;

  if FFiltered then
  begin
    LCount := RecalcList(AValue.IsEmpty);
    LHeight := FItemHeight * Min(LCount, FCompletionProposal.VisibleLines) + 2;

    if (cpoAutoConstraints in FCompletionProposal.Options) and not (cpoResizable in FCompletionProposal.Options) then
      Constraints.MinHeight := LHeight;

    Height := LHeight;
    TopLine := 0;
    Repaint;
  end
  else
  begin
    LIndex := 0;

    while (LIndex < FItems.Count) and not MatchItem1(LIndex) do
      Inc(LIndex);

    TopLine := if LIndex < FItems.Count then LIndex else 0;
  end;

  if Visible then
  begin
    UpdateScrollBar;
    Invalidate;
  end;

  NotifySelectedItemChange;
end;

procedure TTextEditorCompletionProposalPopupWindow.SetTopLine(const AValue: Integer);
begin
  if TopLine <> AValue then
  begin
    FTopLine := AValue;
    UpdateScrollBar;
    Invalidate;
  end;
end;

procedure TTextEditorCompletionProposalPopupWindow.MouseWheel(AShift: TShiftState; AWheelDelta: Integer);
var
  LLinesToScroll: Integer;
begin
  if csDesigning in ComponentState then
    Exit;

  LLinesToScroll := if ssCtrl in aShift then FCompletionProposal.VisibleLines else 1;

  TopLine :=
    if AWheelDelta > 0 then
      Max(0, TopLine - LLinesToScroll)
    else
      Min(FItems.Count - FCompletionProposal.VisibleLines, TopLine + LLinesToScroll);

  Invalidate;
end;

procedure TTextEditorCompletionProposalPopupWindow.Execute(const ACurrentString: string; const APoint: TPoint;
  const AOptions: TCompletionProposalOptions);
var
  LPoint: TPoint;

  procedure CalculateFormPlacement;
  var
    LItem: TTextEditorCompletionProposalItem;
    LText: string;
    LFlowWidth: Integer;
    LWidth: Integer;
    LHeight: Integer;
  begin
    LPoint.X := APoint.X - TextWidth(FBitmapBuffer.Canvas, ACurrentString);
    LPoint.Y := APoint.Y;

    FItemWidth := 0;
    FItemDescriptionWidth := 0;
    FItemKindWidth := 0;
    LFlowWidth := 0;

    for var LIndex := 0 to FItems.Count - 1 do
    begin
      LItem := FItems[LIndex];

      if LItem.Kind.IsEmpty then
      begin
        FItemWidth := Max(FItemWidth, TextWidth(FBitmapBuffer.Canvas, LItem.Keyword));

        if ShowDescription then
          FItemDescriptionWidth := Max(FItemDescriptionWidth, TextWidth(FBitmapBuffer.Canvas, LItem.Description));
      end
      else
      begin
        FItemKindWidth := Max(FItemKindWidth, TextWidth(FBitmapBuffer.Canvas, LItem.Kind));

        LText := if ShowDescription then LItem.Keyword + LItem.Description else LItem.Keyword;
        LFlowWidth := Max(LFlowWidth, TextWidth(FBitmapBuffer.Canvas, LText));
      end;
    end;

    if FItemDescriptionWidth > 0 then
      Inc(FItemWidth, TextWidth(FBitmapBuffer.Canvas, 'X'));

    if FItemKindWidth > 0 then
      Inc(FItemKindWidth, 2 * TextWidth(FBitmapBuffer.Canvas, 'X'));

    LWidth := Max(FItemWidth + FItemDescriptionWidth, FItemKindWidth + LFlowWidth) + 2 * GetSystemMetrics(SM_CXVSCROLL);

    if FCompletionProposal.Width > 0 then
      LWidth := FCompletionProposal.Width;

    LWidth := Min(LWidth, Screen.WorkAreaRect.Width - 2 * FMargin);

    LHeight := FItemHeight * Min(FItems.Count, FCompletionProposal.VisibleLines) + 2;

    if LPoint.X + LWidth > Screen.DesktopWidth then
    begin
      LPoint.X := Screen.DesktopWidth - LWidth - 5;

      if LPoint.X < 0 then
        LPoint.X := 0;
    end;

    if LPoint.Y + LHeight > Screen.DesktopHeight then
    begin
      LPoint.Y := LPoint.Y - LHeight - (Owner as TCustomTextEditor).LineHeight - 2;

      if LPoint.Y < 0 then
        LPoint.Y := 0;
    end;

    Width := LWidth;
    Height := LHeight;
  end;

  procedure SetAutoConstraints;
  begin
    if (cpoAutoConstraints in FCompletionProposal.Options) and not (cpoResizable in FCompletionProposal.Options) then
    begin
      Constraints.MinHeight := Height;
      Constraints.MinWidth := Width;
    end;
  end;

var
  LCount: Integer;
begin
  if AOptions.SortByDescription then
    FItems.Sort(TComparer<TTextEditorCompletionProposalItem>.Construct(
      function(const ALeft, ARight: TTextEditorCompletionProposalItem): Integer
      begin
        Result := CompareStr(ALeft.Description, ARight.Description);

        if Result = 0 then
          Result := CompareStr(ALeft.Keyword, ARight.Keyword);
      end))
  else
  if AOptions.SortByKeyword then
    FItems.Sort(TComparer<TTextEditorCompletionProposalItem>.Construct(
      function(const ALeft, ARight: TTextEditorCompletionProposalItem): Integer
      begin
        Result := CompareStr(ALeft.Keyword, ARight.Keyword);
      end));

  LCount := FItems.Count;

  SetLength(FItemIndexArray, 0);
  SetLength(FItemIndexArray, LCount);

  for var LIndex := 0 to LCount - 1 do
    FItemIndexArray[LIndex] := LIndex;

  if Length(FItemIndexArray) > 0 then
  begin
    FItemHeight := GetItemHeight;
    CalculateFormPlacement;
    SetAutoConstraints;
    CurrentString := ACurrentString;

    if Length(FItemIndexArray) > 0 then
    begin
      if cpoShowShadow in FCompletionProposal.Options then
        ActivateDropShadow(Handle);

      FBorderWidth := if cpoShowBorder in FCompletionProposal.Options then 1 else 0;

      UpdateScrollBar;
      Invalidate;
      Show(LPoint);
    end;
  end;
end;

procedure TTextEditorCompletionProposalPopupWindow.HandleOnValidate(ASender: TObject; const AEndToken: Char); //FI:O804 Method parameter is declared but never used
var
  LTextEditor: TCustomTextEditor;

  function GetBeginChar(const ARow: Integer; const ACharCount: Integer): Integer;
  begin
    Result := if ARow = 1 then LTextEditor.SelectionStartPosition.Char else ACharCount + 1;
  end;

var
  LTextPosition: TTextEditorTextPosition;
  LLineText: string;
  LIndex: Integer;
  LLine: string;
  LAddedSnippet: Boolean;
  LSnippetItem: TTextEditorCompletionProposalSnippetItem;
  LValue: string;
  LSnippetPosition, LSnippetSelectionStartPosition, LSnippetSelectionEndPosition: TTextEditorTextPosition;
  LItem: TTextEditorCompletionProposalItem;
  LStringList: TStringList;
  LCharCount: Integer;
  LPLineText: PChar;
  LSpaces: string;
  LBeginChar: Integer;
begin
  if CodeInsight then
    Exit;

  LTextEditor := if Assigned(Owner) then Owner as TCustomTextEditor else nil;

  if Assigned(LTextEditor) then
  with LTextEditor do
  begin
    BeginUpdate;
    BeginUndoBlock;
    try
      LTextPosition := TextPosition;
      LLineText := FLines[LTextPosition.Line];

      if not SelectionAvailable then
      begin
        LIndex := LTextPosition.Char - 1;

        if LIndex <= LLineText.Length then
        while (LIndex > 0) and (LLineText[LIndex] > TCharacters.Space) and not LTextEditor.IsWordBreakChar(LLineText[LIndex]) do
          Dec(LIndex);

        SelectionStartPosition := GetPosition(LIndex + 1, LTextPosition.Line);

        if AEndToken = TControlCharacters.Null then
        begin
          LLine := Lines[LTextPosition.Line];

          SelectionEndPosition :=
            if (Length(LLine) >= LTextPosition.Char) and IsWordBreakChar(LLine[LTextPosition.Char]) then
              LTextPosition
            else
              GetPosition(WordEnd.Char, LTextPosition.Line)
        end
        else
          SelectionEndPosition := LTextPosition;
      end;

      LAddedSnippet := False;
      LSnippetItem := nil;

      if FSelectedLine < Length(FItemIndexArray) then
      begin
        LItem := FItems[FItemIndexArray[FSelectedLine]];

        if LItem.SnippetIndex = -1 then
          LValue := LItem.Keyword
        else
        begin
          LAddedSnippet := True;

          LStringList := TStringList.Create;
          try
            LStringList.TrailingLineBreak := False;
            LSnippetItem := CompletionProposal.Snippets.Item[LItem.SnippetIndex];

            LStringList.Text := LSnippetItem.Snippet.Text;

            LCharCount := 0;
            LPLineText := PChar(LLineText);

            for LIndex := 0 to SelectionStartPosition.Char - 1 do //FI:W528 Variable 'LIndex' not used in FOR-loop
            begin
              Inc(LCharCount, if LPLineText^ = TControlCharacters.Tab then Tabs.Width else 1);

              if LPLineText^ <> TControlCharacters.Null then
                Inc(LPLineText);
            end;

            Dec(LCharCount);

            LSpaces :=
              if toTabsToSpaces in Tabs.Options then
                StringOfChar(TCharacters.Space, LCharCount)
              else
                StringOfChar(TControlCharacters.Tab, LCharCount div Tabs.Width) + StringOfChar(TCharacters.Space, LCharCount mod Tabs.Width);

            for LIndex := 1 to LStringList.Count - 1 do
              LStringList[LIndex] := LSpaces + LStringList[LIndex];

            if LSnippetItem.Position.Active then
            begin
              LBeginChar := GetBeginChar(LSnippetItem.Position.Row, LCharCount);
              LSnippetPosition := GetPosition(LBeginChar + LSnippetItem.Position.Column - 1, SelectionStartPosition.Line + LSnippetItem.Position.Row - 1);
            end;

            if LSnippetItem.Selection.Active then
            begin
              LBeginChar := GetBeginChar(LSnippetItem.Selection.FromRow, LCharCount);
              LSnippetSelectionStartPosition := GetPosition(LBeginChar + LSnippetItem.Selection.FromColumn - 1, SelectionStartPosition.Line + LSnippetItem.Selection.FromRow - 1);
              LBeginChar := GetBeginChar(LSnippetItem.Selection.ToRow, LCharCount);
              LSnippetSelectionEndPosition := GetPosition(LBeginChar + LSnippetItem.Selection.ToColumn - 1, SelectionStartPosition.Line + LSnippetItem.Selection.ToRow - 1);
            end;

            LValue := LStringList.Text
          finally
            LStringList.Free;
          end;
        end;
      end
      else
        LValue := SelectedText;

      FValueSet := SelectedText <> LValue;

      if FValueSet then
        SelectedText := LValue;

      if CanFocus then
        SetFocus;

      EnsureCursorPositionVisible;

      if LAddedSnippet then
      begin
        if Assigned(LSnippetItem) and LSnippetItem.Position.Active then
          TextPosition := LSnippetPosition
        else
        if Assigned(LSnippetItem) and LSnippetItem.Selection.Active then
          TextPosition := LSnippetSelectionEndPosition
        else
          TextPosition := SelectionEndPosition;

        if Assigned(LSnippetItem) and LSnippetItem.Selection.Active then
        begin
          SelectionStartPosition := LSnippetSelectionStartPosition;
          SelectionEndPosition := LSnippetSelectionEndPosition;
        end
        else
        begin
          SelectionStartPosition := TextPosition;
          SelectionEndPosition := SelectionStartPosition;
        end;
      end
      else
      begin
        TextPosition := SelectionEndPosition;
        SelectionStartPosition := TextPosition;
      end;
    finally
      EndUndoBlock;
      EndUpdate;
    end;
  end;
end;

procedure TTextEditorCompletionProposalPopupWindow.HandleDblClick(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  if Assigned(FOnValidate) then
    FOnValidate(Self, TControlCharacters.Null);

  Hide;
end;

function TTextEditorCompletionProposalPopupWindow.GetCurrentInput: string;
var
  LTextEditor: TCustomTextEditor;
  LTextPosition: TTextEditorTextPosition;
  LLineText: string;
  LIndex: Integer;
begin
  Result := '';

  LTextEditor := if Assigned(Owner) then Owner as TCustomTextEditor else nil;

  if Assigned(LTextEditor) then
  begin
    LTextPosition := LTextEditor.TextPosition;
    LLineText := FLines[LTextPosition.Line];
    LIndex := LTextPosition.Char - 1;

    if LIndex <= LLineText.Length then
    begin
      while (LIndex > 0) and (LLineText[LIndex] > TCharacters.Space) and not LTextEditor.IsWordBreakChar(LLineText[LIndex]) do
        Dec(LIndex);

      Result := Copy(LLineText, LIndex + 1, LTextPosition.Char - LIndex - 1);
    end;
  end;
end;

function TTextEditorCompletionProposalPopupWindow.ResizeCornerSize: Integer;
begin
  Result := MulDiv(RESIZE_CORNER_SIZE, CurrentPPI, USER_DEFAULT_SCREEN_DPI);
end;

function TTextEditorCompletionProposalPopupWindow.ResizeGripSize: Integer;
begin
  Result := MulDiv(RESIZE_GRIP_SIZE, CurrentPPI, USER_DEFAULT_SCREEN_DPI);
end;

function TTextEditorCompletionProposalPopupWindow.ScrollBarResizeCornerSize: Integer;
begin
  Result := MulDiv(SCROLL_BAR_RESIZE_CORNER_SIZE, CurrentPPI, USER_DEFAULT_SCREEN_DPI);
end;

function TTextEditorCompletionProposalPopupWindow.UseStyledScrollBar: Boolean;
begin
  Result := TStyleManager.IsCustomStyleActive or IsSkinned;
end;

function TTextEditorCompletionProposalPopupWindow.ScrollBarVisible: Boolean;
begin
  Result := UseStyledScrollBar and (Length(FItemIndexArray) > FCompletionProposal.VisibleLines);
end;

function TTextEditorCompletionProposalPopupWindow.ScrollBarWidth: Integer;
begin
{$IFDEF ALPHASKINS}
  if IsSkinned and Assigned(ScrollWnd.sBarVert) then
    Exit(GetScrollMetric(ScrollWnd.sBarVert, SM_SCROLLWIDTH));
{$ENDIF}

  Result := GetSystemMetrics(SM_CXVSCROLL);
end;

function TTextEditorCompletionProposalPopupWindow.ScrollBarArrowSize: Integer;
begin
{$IFDEF ALPHASKINS}
  if IsSkinned and Assigned(ScrollWnd.sBarVert) then
    Exit(GetScrollMetric(ScrollWnd.sBarVert, SCROLL_METRIC_BUTTON_SIZE, True));
{$ENDIF}

  Result := GetSystemMetrics(SM_CYVSCROLL);
end;

function TTextEditorCompletionProposalPopupWindow.ScrollBarMaxTopLine: Integer;
begin
  Result := Max(0, Length(FItemIndexArray) - FCompletionProposal.VisibleLines);
end;

function TTextEditorCompletionProposalPopupWindow.ScrollBarRect: TRect;
begin
  Result := Rect(ClientWidth - ScrollBarWidth, 0, ClientWidth, ClientHeight);
end;

function TTextEditorCompletionProposalPopupWindow.ScrollBarThumbRect: TRect;
var
  LRect: TRect;
  LTrackTop, LTrackHeight, LMinThumbHeight, LThumbHeight, LThumbTop: Integer;
begin
  LRect := ScrollBarRect;
  LTrackTop := LRect.Top + ScrollBarArrowSize;
  LTrackHeight := Max(0, LRect.Height - 2 * ScrollBarArrowSize);

  { The arrow size is no minimum with arrowless skinned scroll bars. }
  LMinThumbHeight := Min(Max(ScrollBarArrowSize, MulDiv(SCROLL_BAR_MIN_THUMB_SIZE, CurrentPPI, USER_DEFAULT_SCREEN_DPI)),
    LTrackHeight);
  LThumbHeight := EnsureRange(MulDiv(LTrackHeight, FCompletionProposal.VisibleLines, Max(1, Length(FItemIndexArray))),
    LMinThumbHeight, LTrackHeight);
  LThumbTop := LTrackTop + MulDiv(TopLine, LTrackHeight - LThumbHeight, Max(1, ScrollBarMaxTopLine));

  Result := Rect(LRect.Left, LThumbTop, LRect.Right, LThumbTop + LThumbHeight);
end;

procedure TTextEditorCompletionProposalPopupWindow.PaintFlatScrollBar(const ACanvas: TCanvas);
var
  LTextEditor: TCustomTextEditor;
  LRect: TRect;
  LAccentColor: TColor;

  procedure PaintArrow(const ARect: TRect; const ADownwards: Boolean);
  var
    LCenterX, LCenterY, LSize: Integer;
  begin
    LSize := ARect.Width div 4;
    LCenterX := (ARect.Left + ARect.Right) div 2;
    LCenterY := (ARect.Top + ARect.Bottom) div 2;

    if ADownwards then
      ACanvas.Polygon([Point(LCenterX - LSize, LCenterY - LSize div 2), Point(LCenterX + LSize, LCenterY - LSize div 2),
        Point(LCenterX, LCenterY + LSize div 2)])
    else
      ACanvas.Polygon([Point(LCenterX - LSize, LCenterY + LSize div 2), Point(LCenterX + LSize, LCenterY + LSize div 2),
        Point(LCenterX, LCenterY - LSize div 2)]);
  end;

begin
  LTextEditor := if Assigned(Owner) then Owner as TCustomTextEditor else nil;

  if not Assigned(LTextEditor) then
    Exit;

  LRect := ScrollBarRect;
  LAccentColor := MiddleColor(LTextEditor.Colors.CompletionProposalBackground,
    LTextEditor.Colors.CompletionProposalForeground);

  ACanvas.Brush.Color := LTextEditor.Colors.CompletionProposalBackground;
  ACanvas.FillRect(LRect);

  ACanvas.Brush.Color := LAccentColor;
  ACanvas.Pen.Color := LAccentColor;
  ACanvas.FillRect(ScrollBarThumbRect);

  PaintArrow(Rect(LRect.Left, LRect.Top, LRect.Right, LRect.Top + ScrollBarArrowSize), False);
  PaintArrow(Rect(LRect.Left, LRect.Bottom - ScrollBarArrowSize, LRect.Right, LRect.Bottom), True);
end;

{$IFDEF ALPHASKINS}
{ Paints the scroll bar with the active skin's own scroll bar art, using the same public painting routines AlphaSkins
  uses for its non-client scroll bars. }
procedure TTextEditorCompletionProposalPopupWindow.PaintSkinnedScrollBar(const ACanvas: TCanvas);
var
  LTextEditor: TCustomTextEditor;
  LSkinData: TacSkinData;
  LRect, LThumbRect: TRect;
  LBitmap: Vcl.Graphics.TBitmap;
  LCacheInfo: TCacheInfo;
  LThumbMiddle, LArrowSize: Integer;
begin
  LTextEditor := if Assigned(Owner) then Owner as TCustomTextEditor else nil;

  if not Assigned(LTextEditor) then
    Exit;

  LSkinData := SkinData.CommonSkinData;
  LRect := ScrollBarRect;

  { The window can be painted into the skin cache before it has its final size - the skin art cannot be painted into
    degenerate rects. }
  if (LRect.Width < 2) or (LRect.Height < 4) then
    Exit;

  LThumbRect := ScrollBarThumbRect;
  OffsetRect(LThumbRect, -LRect.Left, -LRect.Top);

  LBitmap := CreateBmp32(MkRect(LRect.Width, LRect.Height));
  try
    LCacheInfo.Bmp := nil;
    LCacheInfo.X := 0;
    LCacheInfo.Y := 0;
    LCacheInfo.FillColor := ColorToRGB(LTextEditor.Colors.CompletionProposalBackground);
    LCacheInfo.FillRect := MkRect;
    LCacheInfo.Ready := False;

    LThumbMiddle := EnsureRange(LThumbRect.Top + LThumbRect.Height div 2, 2, LBitmap.Height - 2);

    with LSkinData.Scrolls[asTop] do
      PaintItemFast(SkinIndex, MaskIndex, BGIndex[0], BGIndex[1], LCacheInfo, True, 0,
        MkRect(LBitmap.Width, LThumbMiddle), LRect.TopLeft, LBitmap, LSkinData);

    with LSkinData.Scrolls[asBottom] do
      PaintItemFast(SkinIndex, MaskIndex, BGIndex[0], BGIndex[1], LCacheInfo, True, 0,
        Rect(0, LThumbMiddle, LBitmap.Width, LBitmap.Height), Point(LRect.Left, LRect.Top + LThumbMiddle), LBitmap,
        LSkinData);

    LArrowSize := ScrollBarArrowSize;

    if LArrowSize > 0 then
    begin
      ac_DrawScrollBtn(Rect(0, 0, LBitmap.Width, LArrowSize), 0, LBitmap, LSkinData, asTop);
      ac_DrawScrollBtn(Rect(0, LBitmap.Height - LArrowSize, LBitmap.Width, LBitmap.Height), 0, LBitmap, LSkinData,
        asBottom);
    end;

    if LThumbRect.Height >= 2 then
      ac_DrawSlider(LThumbRect, 0, LBitmap, LSkinData, True);

    ACanvas.Draw(LRect.Left, LRect.Top, LBitmap);
  finally
    LBitmap.Free;
  end;
end;
{$ENDIF}

procedure TTextEditorCompletionProposalPopupWindow.PaintStyledScrollBar(const ACanvas: TCanvas);
var
  LRect, LArrowRect: TRect;
begin
  if IsSkinned and not TStyleManager.IsCustomStyleActive then
  begin
{$IFDEF ALPHASKINS}
    if IsValidIndex(SkinData.CommonSkinData.Scrolls[asTop].SkinIndex, Length(SkinData.CommonSkinData.gd)) then
      PaintSkinnedScrollBar(ACanvas)
    else
{$ENDIF}
      PaintFlatScrollBar(ACanvas);

    Exit;
  end;

  LRect := ScrollBarRect;

  StyleServices.DrawElement(ACanvas.Handle, StyleServices.GetElementDetails(tsUpperTrackVertNormal), LRect);

  LArrowRect := Rect(LRect.Left, LRect.Top, LRect.Right, LRect.Top + ScrollBarArrowSize);
  StyleServices.DrawElement(ACanvas.Handle, StyleServices.GetElementDetails(tsArrowBtnUpNormal), LArrowRect);

  LArrowRect := Rect(LRect.Left, LRect.Bottom - ScrollBarArrowSize, LRect.Right, LRect.Bottom);
  StyleServices.DrawElement(ACanvas.Handle, StyleServices.GetElementDetails(tsArrowBtnDownNormal), LArrowRect);

  StyleServices.DrawElement(ACanvas.Handle, StyleServices.GetElementDetails(tsThumbBtnVertNormal), ScrollBarThumbRect);
end;

procedure TTextEditorCompletionProposalPopupWindow.UpdateScrollBar;
var
  LScrollInfo: TScrollInfo;
  LItemCount: Integer;
begin
  if UseStyledScrollBar then
  begin
    ShowScrollBar(Handle, SB_VERT, False);
    Invalidate;
    Exit;
  end;

  LItemCount := Length(FItemIndexArray);

  LScrollInfo.cbSize := SizeOf(ScrollInfo);
  LScrollInfo.fMask := SIF_RANGE or SIF_PAGE or SIF_POS or SIF_DISABLENOSCROLL;
  LScrollInfo.nMin := 0;
  LScrollInfo.nMax := Max(0, LItemCount - 1);
  LScrollInfo.nPage := FCompletionProposal.VisibleLines;
  LScrollInfo.nPos := TopLine;

  ShowScrollBar(Handle, SB_VERT, LItemCount > FCompletionProposal.VisibleLines);
  SetScrollInfo(Handle, SB_VERT, LScrollInfo, True);

  if LItemCount <= FCompletionProposal.VisibleLines then
    EnableScrollBar(Handle, SB_VERT, ESB_DISABLE_BOTH)
  else
  begin
    EnableScrollBar(Handle, SB_VERT, ESB_ENABLE_BOTH);

    if TopLine <= 0 then
      EnableScrollBar(Handle, SB_VERT, ESB_DISABLE_UP)
    else
    if TopLine + FCompletionProposal.VisibleLines >= LItemCount then
      EnableScrollBar(Handle, SB_VERT, ESB_DISABLE_DOWN);
  end;

end;

procedure TTextEditorCompletionProposalPopupWindow.WMVScroll(var AMessage: TWMScroll);
begin
  AMessage.Result := 0;

  case AMessage.ScrollCode of
    SB_TOP:
      TopLine := 0;
    SB_BOTTOM:
      TopLine := FItems.Count - 1;
    SB_LINEDOWN:
      TopLine := Min(FItems.Count - FCompletionProposal.VisibleLines, TopLine + 1);
    SB_LINEUP:
      TopLine := Max(0, TopLine - 1);
    SB_PAGEDOWN:
      TopLine := Min(FItems.Count - FCompletionProposal.VisibleLines, TopLine + FCompletionProposal.VisibleLines);
    SB_PAGEUP:
      TopLine := Max(0, TopLine - FCompletionProposal.VisibleLines);
    SB_THUMBPOSITION, SB_THUMBTRACK:
      TopLine := AMessage.Pos;
  end;

  Invalidate;
end;

procedure TTextEditorCompletionProposalPopupWindow.WMNCHitTest(var AMessage: TWMNCHitTest);
var
  LRect: TRect;
  LGripSize, LCornerSize: Integer;
  LOnLeftEdge, LOnTopEdge, LOnRightEdge, LOnBottomEdge: Boolean;
  LNearLeftCorner, LNearTopCorner, LNearRightCorner, LNearBottomCorner: Boolean;
begin
  inherited;

  if (AMessage.Result <> HTCLIENT) and (AMessage.Result <> HTBORDER) and (AMessage.Result <> HTVSCROLL) then
    Exit;

  if not Assigned(FCompletionProposal) or not (cpoResizable in FCompletionProposal.Options) then
    Exit;

  GetWindowRect(Handle, LRect);

  if AMessage.Result = HTVSCROLL then
  begin
    LCornerSize := ScrollBarResizeCornerSize;

    if AMessage.YPos >= LRect.Bottom - LCornerSize then
      AMessage.Result := HTBOTTOMRIGHT
    else
    if AMessage.YPos < LRect.Top + LCornerSize then
      AMessage.Result := HTTOPRIGHT
    else
    if AMessage.XPos >= LRect.Right - ResizeGripSize then
      AMessage.Result := HTRIGHT;

    Exit;
  end;

  LGripSize := ResizeGripSize;
  LCornerSize := ResizeCornerSize;

  LOnLeftEdge := AMessage.XPos < LRect.Left + LGripSize;
  LOnTopEdge := AMessage.YPos < LRect.Top + LGripSize;
  LOnRightEdge := AMessage.XPos >= LRect.Right - LGripSize;
  LOnBottomEdge := AMessage.YPos >= LRect.Bottom - LGripSize;

  LNearLeftCorner := AMessage.XPos < LRect.Left + LCornerSize;
  LNearTopCorner := AMessage.YPos < LRect.Top + LCornerSize;
  LNearRightCorner := AMessage.XPos >= LRect.Right - LCornerSize;
  LNearBottomCorner := AMessage.YPos >= LRect.Bottom - LCornerSize;

  if LOnTopEdge then
  begin
    if LNearLeftCorner then
      AMessage.Result := HTTOPLEFT
    else
    if LNearRightCorner then
      AMessage.Result := HTTOPRIGHT
    else
      AMessage.Result := HTTOP;
  end
  else
  if LOnBottomEdge then
  begin
    if LNearLeftCorner then
      AMessage.Result := HTBOTTOMLEFT
    else
    if LNearRightCorner then
      AMessage.Result := HTBOTTOMRIGHT
    else
      AMessage.Result := HTBOTTOM;
  end
  else
  if LOnLeftEdge then
  begin
    if LNearTopCorner then
      AMessage.Result := HTTOPLEFT
    else
    if LNearBottomCorner then
      AMessage.Result := HTBOTTOMLEFT
    else
      AMessage.Result := HTLEFT;
  end
  else
  if LOnRightEdge then
  begin
    if LNearTopCorner then
      AMessage.Result := HTTOPRIGHT
    else
    if LNearBottomCorner then
      AMessage.Result := HTBOTTOMRIGHT
    else
      AMessage.Result := HTRIGHT;
  end;
end;

procedure TTextEditorCompletionProposalPopupWindow.WMGetMinMaxInfo(var AMessage: TWMGetMinMaxInfo);
begin
  inherited;

  if not Assigned(FCompletionProposal) then
    Exit;

  with AMessage.MinMaxInfo^ do
  begin
    ptMinTrackSize.X := Max(FCompletionProposal.MinWidth, 4 * GetSystemMetrics(SM_CXVSCROLL));
    ptMinTrackSize.Y := Max(FCompletionProposal.MinHeight, FItemHeight + 2);
  end;
end;

procedure TTextEditorCompletionProposalPopupWindow.WMEnterSizeMove(var AMessage: TMessage);
begin
  inherited;

  FUserSizing := True;
end;

procedure TTextEditorCompletionProposalPopupWindow.WMExitSizeMove(var AMessage: TMessage);
var
  LTextEditor: TCustomTextEditor;
begin
  inherited;

  FUserSizing := False;

  if not Assigned(FCompletionProposal) or (FItemHeight <= 0) then
    Exit;

  Height := FItemHeight * Min(Length(FItemIndexArray), FCompletionProposal.VisibleLines) + 2;
  FCompletionProposal.Width := Width;

  LTextEditor := if Assigned(Owner) then Owner as TCustomTextEditor else nil;

  if Assigned(LTextEditor) and LTextEditor.HandleAllocated and (GetFocus = Handle) then
    Winapi.Windows.SetFocus(LTextEditor.Handle);
end;

procedure TTextEditorCompletionProposalPopupWindow.WMSizing(var AMessage: TMessage);
var
  LRect: PRect;
  LBorderHeight, LRows: Integer;
begin
  inherited;

  if FItemHeight <= 0 then
    Exit;

  LRect := PRect(AMessage.LParam);
  LBorderHeight := Height - ClientHeight;
  LRows := Max(1, (LRect.Height - LBorderHeight + FItemHeight div 2) div FItemHeight);

  case AMessage.WParam of
    WMSZ_TOP, WMSZ_TOPLEFT, WMSZ_TOPRIGHT:
      LRect.Top := LRect.Bottom - (LRows * FItemHeight + LBorderHeight);
  else
    LRect.Bottom := LRect.Top + LRows * FItemHeight + LBorderHeight;
  end;

  AMessage.Result := 1;
end;

procedure TTextEditorCompletionProposalPopupWindow.Resize;
var
  LVisibleLines: Integer;
begin
  inherited Resize;

  if not FUserSizing or not Assigned(FCompletionProposal) or (FItemHeight <= 0) then
    Exit;

  LVisibleLines := Max(1, ClientHeight div FItemHeight);

  if LVisibleLines <> FCompletionProposal.VisibleLines then
  begin
    FCompletionProposal.VisibleLines := LVisibleLines;
    TopLine := Min(TopLine, ScrollBarMaxTopLine);
  end;

  UpdateScrollBar;
  Invalidate;
end;

procedure TTextEditorCompletionProposalPopupWindow.MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer);
var
  LRect, LThumbRect: TRect;
begin
  if (AButton = mbLeft) and ScrollBarVisible and (X >= ScrollBarRect.Left) then
  begin
    LRect := ScrollBarRect;
    LThumbRect := ScrollBarThumbRect;

    if Y < LRect.Top + ScrollBarArrowSize then
      TopLine := Max(0, TopLine - 1)
    else
    if Y >= LRect.Bottom - ScrollBarArrowSize then
      TopLine := Min(ScrollBarMaxTopLine, TopLine + 1)
    else
    if Y < LThumbRect.Top then
      TopLine := Max(0, TopLine - FCompletionProposal.VisibleLines)
    else
    if Y >= LThumbRect.Bottom then
      TopLine := Min(ScrollBarMaxTopLine, TopLine + FCompletionProposal.VisibleLines)
    else
    begin
      FScrollBarDragging := True;
      FScrollBarDragOffset := Y - LThumbRect.Top;
    end;

    Exit;
  end;

  if not CodeInsight then
  begin
    FSelectedLine := Max(0, TopLine + (Y div FItemHeight));

    inherited MouseDown(AButton, AShift, X, Y);

    Refresh;
    NotifySelectedItemChange;
  end;
end;

procedure TTextEditorCompletionProposalPopupWindow.MouseMove(AShift: TShiftState; X, Y: Integer);
var
  LRect: TRect;
  LTrackHeight, LMaxThumbTop: Integer;
begin
  if FScrollBarDragging then
  begin
    LRect := ScrollBarRect;
    LTrackHeight := LRect.Height - 2 * ScrollBarArrowSize;
    LMaxThumbTop := LTrackHeight - ScrollBarThumbRect.Height;

    if LMaxThumbTop > 0 then
      TopLine := EnsureRange(MulDiv(Y - FScrollBarDragOffset - LRect.Top - ScrollBarArrowSize, ScrollBarMaxTopLine,
        LMaxThumbTop), 0, ScrollBarMaxTopLine);

    Exit;
  end;

  inherited MouseMove(AShift, X, Y);
end;

procedure TTextEditorCompletionProposalPopupWindow.MouseUp(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer);
begin
  FScrollBarDragging := False;

  inherited MouseUp(AButton, AShift, X, Y);
end;

end.
