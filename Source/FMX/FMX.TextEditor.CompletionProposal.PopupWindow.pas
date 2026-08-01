unit FMX.TextEditor.CompletionProposal.PopupWindow;

interface

uses
  System.Classes, System.Types, System.UITypes, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.TextEditor.CompletionProposal,
  FMX.TextEditor.Lines, FMX.TextEditor.PopupWindow, FMX.TextEditor.Types, FMX.TextEditor.Utils, FMX.Types;

type
  TTextEditorValidateEvent = procedure(ASender: TObject; const AEndToken: Char) of object;

  TTextEditorCompletionProposalPopupWindow = class(TTextEditorPopupWindow)
  strict private
    FBitmapBuffer: TBitmap;
    FCaseSensitive: Boolean;
    FCodeInsight: Boolean;
    FCompletionProposal: TTextEditorCompletionProposal;
    FCurrentString: string;
    FFiltered: Boolean;
    FFormWidth: Integer;
    FItemDescriptionWidth: Single;
    FItemHeight: Single;
    FItemIndexArray: array of Integer;
    FItemWidth: Single;
    FItems: TTextEditorCompletionProposalItems;
    FLines: TTextEditorLines;
    FMargin: Integer;
    FOnKeyPress: TTextEditorKeyPressWEvent;
    FOnValidate: TTextEditorValidateEvent;
    FPopupCaretPoint: TPointF;
    FPopupOrigin: TPointF;
    FPopupShownAboveCaret: Boolean;
    FSelectedLine: Integer;
    FShowDescription: Boolean;
    FTopLine: Integer;
    FValueSet: Boolean;
    function GetItemHeight: Single;
    procedure AddKeyHandlers;
    procedure EditorKeyDown(ASender: TObject; var AKey: Word; var AKeyChar: WideChar; AShift: TShiftState);
    procedure EditorKeyPress(const ASender: TObject; var AKey: Char);
    procedure HandleDblClick(ASender: TObject);
    procedure HandleOnValidate(ASender: TObject; const AEndToken: Char);
    procedure MoveSelectedLine(const ALineCount: Integer);
    procedure RemoveKeyHandlers;
    procedure SetCurrentString(const AValue: string);
    procedure SetTopLine(const AValue: Integer);
  protected
    procedure Paint; override;
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Single); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CurrentStringEqualsEnterSnippet: Boolean;
    function GetCurrentInput: string;
    procedure AcceptSelection;
    procedure Assign(ASource: TPersistent); override;
    procedure Execute(const ACurrentString: string; const APoint: TPointF; const AOptions: TCompletionProposalOptions);
    procedure MouseWheel(AShift: TShiftState; AWheelDelta: Integer); reintroduce;
    property CodeInsight: Boolean read FCodeInsight write FCodeInsight;
    property CurrentString: string read FCurrentString write SetCurrentString;
    property Items: TTextEditorCompletionProposalItems read FItems write FItems;
    property Lines: TTextEditorLines read FLines write FLines;
    property OnKeyPress: TTextEditorKeyPressWEvent read FOnKeyPress write FOnKeyPress;
    property OnValidate: TTextEditorValidateEvent read FOnValidate write FOnValidate;
    property ShowDescription: Boolean read FShowDescription write FShowDescription;
    property TopLine: Integer read FTopLine write SetTopLine;
  end;

implementation

uses
  System.Generics.Defaults, System.Math, System.SysUtils, FMX.TextEditor, FMX.TextEditor.CompletionProposal.Snippets, FMX.TextEditor.Consts,
  FMX.TextEditor.Highlighter, FMX.TextEditor.KeyCommands, FMX.TextEditor.PaintHelper;

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

  FBitmapBuffer := TBitmap.Create;
  FBitmapBuffer.SetSize(1, 1);

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
      Self.FFormWidth := Width;
    end
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorCompletionProposalPopupWindow.AddKeyHandlers;
begin
  var LTextEditor: TCustomTextEditor := if Assigned(Owner) then Owner as TCustomTextEditor else nil;

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
    if csDestroying in LTextEditor.ComponentState then
      Exit;

    LTextEditor.RemoveKeyPressHandler(EditorKeyPress);
    LTextEditor.RemoveKeyDownHandler(EditorKeyDown);
  end;
end;

function TTextEditorCompletionProposalPopupWindow.GetItemHeight: Single;
var
  LTextEditor: TCustomTextEditor;
begin
  LTextEditor := if Assigned(Owner) then Owner as TCustomTextEditor else nil;

  if Assigned(LTextEditor) then
  begin
    Result := 0;

    if FBitmapBuffer.Canvas.BeginScene then
    try
      FBitmapBuffer.Canvas.Font.Assign(LTextEditor.Fonts.CompletionProposal);
      Result := TextHeight(FBitmapBuffer.Canvas, 'X');
    finally
      FBitmapBuffer.Canvas.EndScene;
    end;
  end
  else
    Result := 0;
end;

procedure TTextEditorCompletionProposalPopupWindow.EditorKeyDown(ASender: TObject; var AKey: Word; var AKeyChar: WideChar; AShift: TShiftState);
var
  LTextEditor: TCustomTextEditor;
  LTextPosition: TTextEditorTextPosition;
  LChar: Char;
begin
  LTextEditor := if Assigned(Owner) then Owner as TCustomTextEditor else nil;

  case AKey of
    vkReturn, vkTab:
      begin
        if Assigned(FOnValidate) then
          FOnValidate(Self, TControlCharacters.Null);

        Hide;
      end;
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

  Repaint;
end;

procedure TTextEditorCompletionProposalPopupWindow.EditorKeyPress(const ASender: TObject; var AKey: Char);
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
        if Assigned(FOnKeyPress) and not CodeInsight then
          FOnKeyPress(Self, AKey);
      end;
    TControlCharacters.Backspace:
      if not CodeInsight then
      with Owner as TCustomTextEditor do
        CommandProcessor(TKeyCommands.Char, AKey, nil);
  end;

  Repaint;
end;

procedure TTextEditorCompletionProposalPopupWindow.Paint;
var
  LTextEditor: TCustomTextEditor;
  LTop: Single;
  LItemIndex: Integer;
  LItem: TTextEditorCompletionProposalItem;
  LText, LTemp, LDescription: string;
  LPosition, LWidth: Integer;
  LTextRect: TRectF;
  LBackgroundColor: TAlphaColor;
  LForegroundColor: TAlphaColor;
  LSelectedBackgroundColor: TAlphaColor;
  LSelectedTextColor: TAlphaColor;
  LBorderColor: TAlphaColor;
  LTextColor: TAlphaColor;

  function AlignToPixelCenter(const AValue: Single; const AScale: Single = 1): Single;
  begin
    Result := (Floor(AValue * AScale) + 0.5) / AScale;
  end;

  procedure DrawPixelLine(const AX1, AY1, AX2, AY2: Single; const AOpacity: Single = 1);
  var
    LOldStrokeThickness: Single;
    LScale: Single;
  begin
    LScale := 1;
    if Assigned(Scene) then
      LScale := Scene.GetSceneScale;
    if LScale <= 0 then
      LScale := 1;

    LOldStrokeThickness := Canvas.Stroke.Thickness;
    Canvas.Stroke.Thickness := 1 / LScale;
    try
      Canvas.DrawLine(
        PointF(AlignToPixelCenter(AX1, LScale), AlignToPixelCenter(AY1, LScale)),
        PointF(AlignToPixelCenter(AX2, LScale), AlignToPixelCenter(AY2, LScale)), AOpacity);
    finally
      Canvas.Stroke.Thickness := LOldStrokeThickness;
    end;
  end;

  procedure DrawPixelRect(const ARect: TRectF; const AOpacity: Single = 1);
  begin
    DrawPixelLine(ARect.Left, ARect.Top, ARect.Right, ARect.Top, AOpacity);
    DrawPixelLine(ARect.Right, ARect.Top, ARect.Right, ARect.Bottom, AOpacity);
    DrawPixelLine(ARect.Right, ARect.Bottom, ARect.Left, ARect.Bottom, AOpacity);
    DrawPixelLine(ARect.Left, ARect.Bottom, ARect.Left, ARect.Top, AOpacity);
  end;

  procedure DrawText(const ALeft, ATop: Single; const AText: string; const ATextColor: TAlphaColor);
  begin
    if AText.IsEmpty then
      Exit;

    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := ATextColor;
    LTextRect := RectF(ALeft, ATop, Width, ATop + FItemHeight);
    Canvas.FillText(LTextRect, AText, False, 1, [], TTextAlign.Leading, TTextAlign.Leading);
  end;

  procedure DrawScrollBar;
  const
    CScrollBarWidth = 16;
    CMinimumThumbHeight = 12;
  var
    LItemCount: Integer;
    LTrackRect: TRectF;
    LThumbHeight: Single;
    LThumbTop: Single;
    LScrollableItems: Integer;
  begin
    LItemCount := Length(FItemIndexArray);

    if LItemCount <= FCompletionProposal.VisibleLines then
      Exit;

    LTrackRect := RectF(Width - CScrollBarWidth, 1, Width - 1, Height - 1);

    Canvas.Fill.Color := LBackgroundColor;
    Canvas.FillRect(LTrackRect, 0, 0, [], 1);

    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Color := LBorderColor;
    DrawPixelLine(LTrackRect.Left, LTrackRect.Top, LTrackRect.Left, LTrackRect.Bottom);

    LThumbHeight := Max(CMinimumThumbHeight, LTrackRect.Height * FCompletionProposal.VisibleLines / LItemCount);
    LScrollableItems := Max(1, LItemCount - FCompletionProposal.VisibleLines);
    LThumbTop := LTrackRect.Top + (LTrackRect.Height - LThumbHeight) * TopLine / LScrollableItems;

    Canvas.Fill.Color := LForegroundColor;
    Canvas.FillRect(RectF(LTrackRect.Left + 3, LThumbTop, LTrackRect.Right - 3, LThumbTop + LThumbHeight), 2, 2, [], 0.45);
  end;

begin
  LTextEditor := if Assigned(Owner) then Owner as TCustomTextEditor else nil;

  if not Assigned(LTextEditor) then
    Exit;

  inherited;

  if Length(FItemIndexArray) = 0 then
    Exit;

  LBackgroundColor := LTextEditor.Colors.CompletionProposalBackground;
  LForegroundColor := LTextEditor.Colors.CompletionProposalForeground;
  LSelectedBackgroundColor := LTextEditor.Colors.CompletionProposalSelectedBackground;
  LSelectedTextColor := LTextEditor.Colors.CompletionProposalSelectedText;
  LBorderColor := FBorderColor;

  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := LBackgroundColor;
  Canvas.FillRect(LocalRect, 0, 0, [], 1);
  Canvas.Font.Assign(LTextEditor.Fonts.CompletionProposal);
  LTop := 0;

  for var LIndex := 0 to Min(FCompletionProposal.VisibleLines, Length(FItemIndexArray)) - 1 do
  begin
    if LIndex + TopLine >= Length(FItemIndexArray) then
      Break;

    if (LIndex + TopLine = FSelectedLine) and not CodeInsight then
    begin
      Canvas.Fill.Color := LSelectedBackgroundColor;
      Canvas.FillRect(RectF(0, FItemHeight * LIndex, Width, FItemHeight * (LIndex + 1)), 0, 0, [], 1);
      LTextColor := LSelectedTextColor;
    end
    else
      LTextColor := LForegroundColor;

    LItemIndex := FItemIndexArray[TopLine + LIndex];

    LItem := FItems[LItemIndex];
    LText := LItem.Keyword;
    LDescription := LItem.Description;
    LPosition := if FCaseSensitive then Pos(FCurrentString, LText) else Pos(AnsiUpperCase(FCurrentString), AnsiUpperCase(LText));

    if LPosition > 0 then
    begin
      LWidth := 0;

      if LPosition > 1 then
      begin
        LTemp := Copy(LText, 1, LPosition - 1);
        DrawText(FMargin, LTop, LTemp, LTextColor);
        Inc(LWidth, Round(Canvas.TextWidth(LTemp)));
      end;

      Canvas.Font.Style := Canvas.Font.Style + [TFontStyle.fsUnderline];
      LTemp := Copy(LText, LPosition, FCurrentString.Length);
      DrawText(FMargin + LWidth, LTop, LTemp, LTextColor);
      Inc(LWidth, Round(Canvas.TextWidth(LTemp)));
      Canvas.Font.Style := Canvas.Font.Style - [TFontStyle.fsUnderline];
      LTemp := Copy(LText, LPosition + FCurrentString.Length);

      if not LTemp.IsEmpty then
        DrawText(FMargin + LWidth, LTop, LTemp, LTextColor);
    end
    else
      DrawText(FMargin, LTop, LText, LTextColor);

    if ShowDescription then
      DrawText(FMargin + FItemWidth, LTop, LDescription, LTextColor);

    LTop := LTop + FItemHeight;
  end;

  DrawScrollBar;

  if FBorderWidth > 0 then
  begin
    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Color := LBorderColor;
    DrawPixelRect(RectF(0, 0, Width, Height));
  end;
end;

procedure TTextEditorCompletionProposalPopupWindow.MoveSelectedLine(const ALineCount: Integer);
begin
  FSelectedLine := EnsureRange(FSelectedLine + ALineCount, 0, Max(Length(FItemIndexArray) - 1, 0));

  if FSelectedLine >= TopLine + FCompletionProposal.VisibleLines then
    TopLine := FSelectedLine - FCompletionProposal.VisibleLines + 1;

  if FSelectedLine < TopLine then
    TopLine := FSelectedLine;
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
  LHeight: Single;
  LIndex: Integer;
begin
  FCurrentString := AValue;

  if FFiltered then
  begin
    LCount := RecalcList(AValue.IsEmpty);

    if LCount = 0 then
    begin
      SetLength(FItemIndexArray, 0);
      Visible := False;
      Width := 0;
      Height := 0;

      if Parent is TControl then
        (Parent as TControl).Repaint;

      if Owner is TControl then
        (Owner as TControl).Repaint;

      Exit;
    end;

    LHeight := FItemHeight * Min(LCount, FCompletionProposal.VisibleLines) + 2;

    Height := LHeight;

    if FPopupShownAboveCaret then
    begin
      FPopupOrigin.Y := FPopupCaretPoint.Y - LHeight - (Owner as TCustomTextEditor).LineHeight - 2;

      if FPopupOrigin.Y < 0 then
        FPopupOrigin.Y := 0;

      if Visible then
        SetOrigin(FPopupOrigin);
    end;

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
    Repaint;
end;

procedure TTextEditorCompletionProposalPopupWindow.SetTopLine(const AValue: Integer);
var
  LMaxTopLine: Integer;
  LTopLine: Integer;
begin
  LMaxTopLine := Max(Length(FItemIndexArray) - FCompletionProposal.VisibleLines, 0);
  LTopLine := EnsureRange(AValue, 0, LMaxTopLine);

  if TopLine <> LTopLine then
  begin
    FTopLine := LTopLine;
    Repaint;
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

  Repaint;
end;

procedure TTextEditorCompletionProposalPopupWindow.Execute(const ACurrentString: string; const APoint: TPointF;
  const AOptions: TCompletionProposalOptions);
var
  LPoint: TPointF;

  function GetScrollBarWidth: Single;
  begin
    Result := 16;
  end;

  function GetWorkAreaWidth: Integer;
  begin
    Result := Round((Owner as TCustomTextEditor).Width);
  end;

  function GetWorkAreaHeight: Integer;
  begin
    Result := Round((Owner as TCustomTextEditor).Height);
  end;

  procedure CalculateFormPlacement;
  var
    LShownAboveCaret: Boolean;
    LMaxIndex: Integer;
    LMaxDescriptionIndex: Integer;
    LMaxLength: Integer;
    LMaxDescriptionLength: Integer;
    LLength: Integer;
    LText, LDescription: string;
    LItem: TTextEditorCompletionProposalItem;
    LWidth: Single;
    LHeight: Single;
  begin
    LShownAboveCaret := False;

    LPoint.X := APoint.X - TextWidth(FBitmapBuffer.Canvas, ACurrentString);
    LPoint.Y := APoint.Y;

    LMaxIndex := 0;
    LMaxDescriptionIndex := -1;
    LMaxLength := 0;
    LMaxDescriptionLength := 0;

    for var LIndex := 0 to FItems.Count - 1 do
    begin
      LItem := FItems[LIndex];
      LText := LItem.Keyword;
      LDescription := LItem.Description;

      LLength := LText.Length;

      if LLength > LMaxLength then
      begin
        LMaxLength := LLength;
        LMaxIndex := LIndex;
      end;

      if ShowDescription then
      begin
        LLength := LDescription.Length;

        if LLength > LMaxDescriptionLength then
        begin
          LMaxDescriptionLength := LLength;
          LMaxDescriptionIndex := LIndex;
        end;
      end;
    end;

    LText := FItems[LMaxIndex].Keyword;

    FItemWidth := TextWidth(FBitmapBuffer.Canvas, LText);

    LWidth := FItemWidth + 2 * GetScrollBarWidth;

    FItemDescriptionWidth := 0;

    if LMaxDescriptionIndex > -1 then
    begin
      LText := FItems[LMaxDescriptionIndex].Description;

      FItemWidth := FItemWidth + TextWidth(FBitmapBuffer.Canvas, 'X');
      FItemDescriptionWidth := TextWidth(FBitmapBuffer.Canvas, LText);
      LWidth := LWidth + FItemDescriptionWidth;
    end;

    LHeight := FItemHeight * Min(FItems.Count, FCompletionProposal.VisibleLines) + 2;

    if LPoint.X + LWidth > GetWorkAreaWidth then
    begin
      LPoint.X := GetWorkAreaWidth - LWidth - 5;

      if LPoint.X < 0 then
        LPoint.X := 0;
    end;

    if LPoint.Y + LHeight > GetWorkAreaHeight then
    begin
      LPoint.Y := LPoint.Y - LHeight - (Owner as TCustomTextEditor).LineHeight - 2;
      LShownAboveCaret := True;

      if LPoint.Y < 0 then
        LPoint.Y := 0;
    end;

    Width := LWidth;
    Height := LHeight;

    FPopupCaretPoint := APoint;
    FPopupOrigin := LPoint;
    FPopupShownAboveCaret := LShownAboveCaret;
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

    if not FBitmapBuffer.Canvas.BeginScene then
      Exit;

    try
      FBitmapBuffer.Canvas.Font.Assign((Owner as TCustomTextEditor).Fonts.CompletionProposal);
      CalculateFormPlacement;
    finally
      FBitmapBuffer.Canvas.EndScene;
    end;

    CurrentString := ACurrentString;

    if Length(FItemIndexArray) > 0 then
    begin
      FBorderWidth := if cpoShowBorder in FCompletionProposal.Options then 1 else 0;

      Repaint;
      Show(FPopupOrigin);
    end;
  end;
end;

procedure TTextEditorCompletionProposalPopupWindow.HandleOnValidate(ASender: TObject; const AEndToken: Char);
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
            LSnippetItem := FCompletionProposal.Snippets.Item[LItem.SnippetIndex];

            LStringList.Text := LSnippetItem.Snippet.Text;

            LCharCount := 0;
            LPLineText := PChar(LLineText);

            for LIndex := 0 to SelectionStartPosition.Char - 1 do
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

procedure TTextEditorCompletionProposalPopupWindow.AcceptSelection;
begin
  if Assigned(FOnValidate) then
    FOnValidate(Self, TControlCharacters.Null);

  Hide;
end;

procedure TTextEditorCompletionProposalPopupWindow.HandleDblClick(ASender: TObject);
begin
  AcceptSelection;
end;

function TTextEditorCompletionProposalPopupWindow.CurrentStringEqualsEnterSnippet: Boolean;
var
  LCurrentString: string;
  LIndex: Integer;
  LItem: TTextEditorCompletionProposalItem;
  LSnippetItem: TTextEditorCompletionProposalSnippetItem;

  function KeywordMatches(const AKeyword: string): Boolean;
  begin
    if FCaseSensitive then
      Result := SameStr(LCurrentString, AKeyword)
    else
      Result := SameText(LCurrentString, AKeyword);
  end;

  function ItemMatchesEnterSnippet(const AItem: TTextEditorCompletionProposalItem): Boolean;
  begin
    Result := False;

    if (AItem.SnippetIndex < 0) or (AItem.SnippetIndex >= FCompletionProposal.Snippets.Items.Count) then
      Exit;

    LSnippetItem := FCompletionProposal.Snippets.Item[AItem.SnippetIndex];
    Result := (LSnippetItem.ExecuteWith = seEnter) and KeywordMatches(AItem.Keyword);
  end;

begin
  Result := False;

  LCurrentString := GetCurrentInput;

  if LCurrentString.IsEmpty then
    LCurrentString := FCurrentString;

  if LCurrentString.IsEmpty then
    Exit;

  for LIndex := 0 to Length(FItemIndexArray) - 1 do
  begin
    LItem := FItems[FItemIndexArray[LIndex]];

    if ItemMatchesEnterSnippet(LItem) then
      Exit(True);
  end;
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

procedure TTextEditorCompletionProposalPopupWindow.MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Single);
begin
  if not CodeInsight then
  begin
    FSelectedLine := Max(0, Round(TopLine + Y / FItemHeight));

    inherited MouseDown(AButton, AShift, X, Y);

    Repaint;
  end;
end;

end.
