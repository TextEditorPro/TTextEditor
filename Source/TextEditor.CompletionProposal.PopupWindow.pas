unit TextEditor.CompletionProposal.PopupWindow;

interface

uses
  Winapi.Messages, System.Classes, System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, TextEditor.CompletionProposal,
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
    FFormWidth: Integer;
    FItemDescriptionWidth: Integer;
    FItemHeight: Integer;
    FItemIndexArray: array of Integer;
    FItems: TTextEditorCompletionProposalItems;
    FItemWidth: Integer;
    FLines: TTextEditorLines;
    FMargin: Integer;
    FOnValidate: TTextEditorValidateEvent;
    FSelectedLine: Integer;
    FShowDescription: Boolean;
    FTopLine: Integer;
    FValueSet: Boolean;
    function GetItemHeight: Integer;
    procedure AddKeyHandlers;
    procedure EditorKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
    procedure EditorKeyPress(const ASender: TObject; var AKey: Char);
    procedure HandleDblClick(ASender: TObject);
    procedure HandleOnValidate(ASender: TObject; const AEndToken: Char);
    procedure MoveSelectedLine(const ALineCount: Integer);
    procedure RemoveKeyHandlers;
    procedure SetCurrentString(const AValue: string);
    procedure SetTopLine(const AValue: Integer);
    procedure UpdateScrollBar;
    procedure WMVScroll(var AMessage: TWMScroll); message WM_VSCROLL;
  protected
    procedure Paint; override;
    procedure Hide; override;
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetCurrentInput: string;
    procedure Assign(ASource: TPersistent); override;
    procedure Execute(const ACurrentString: string; const APoint: TPoint; const AOptions: TCompletionProposalOptions);
    procedure MouseWheel(AShift: TShiftState; AWheelDelta: Integer);
    property CodeInsight: Boolean read FCodeInsight write FCodeInsight;
    property CurrentString: string read FCurrentString write SetCurrentString;
    property Items: TTextEditorCompletionProposalItems read FItems write FItems;
    property Lines: TTextEditorLines read FLines write FLines;
    property OnValidate: TTextEditorValidateEvent read FOnValidate write FOnValidate;
    property ShowDescription: Boolean read FShowDescription write FShowDescription;
    property TopLine: Integer read FTopLine write SetTopLine;
  end;

implementation

uses
  Winapi.Windows, System.Generics.Defaults, System.Math, System.SysUtils, System.UITypes, Vcl.Dialogs, TextEditor,
  TextEditor.CompletionProposal.Snippets, TextEditor.Consts, TextEditor.Highlighter, TextEditor.KeyCommands,
  TextEditor.PaintHelper;

constructor TTextEditorCompletionProposalPopupWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FCaseSensitive := False;
  FFiltered := False;
  FItemHeight := 0;
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

procedure TTextEditorCompletionProposalPopupWindow.Hide;
begin
  RemoveKeyHandlers;

  inherited Hide;
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
      Self.Font.Assign(Font);
      Self.Constraints.Assign(Constraints);
    end
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorCompletionProposalPopupWindow.AddKeyHandlers;
var
  LEditor: TCustomTextEditor;
begin
  LEditor := Owner as TCustomTextEditor;
  if Assigned(LEditor) then
  begin
    LEditor.AddKeyPressHandler(EditorKeyPress);
    LEditor.AddKeyDownHandler(EditorKeyDown);
  end;
end;

procedure TTextEditorCompletionProposalPopupWindow.RemoveKeyHandlers;
var
  LEditor: TCustomTextEditor;
begin
  LEditor := Owner as TCustomTextEditor;
  if Assigned(LEditor) then
  begin
    LEditor.RemoveKeyPressHandler(EditorKeyPress);
    LEditor.RemoveKeyDownHandler(EditorKeyDown);
  end;
end;

function TTextEditorCompletionProposalPopupWindow.GetItemHeight: Integer;
begin
  FBitmapBuffer.Canvas.Font.Assign(FCompletionProposal.Font);
  Result := TextHeight(FBitmapBuffer.Canvas, 'X');
end;

procedure TTextEditorCompletionProposalPopupWindow.EditorKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState); //FI:O804 Method parameter is declared but never used
var
  LChar: Char;
  LEditor: TCustomTextEditor;
  LTextPosition: TTextEditorTextPosition;
begin
  LEditor := nil;
  if Assigned(Owner) then
    LEditor := Owner as TCustomTextEditor;
  case AKey of
    vkReturn, vkTab:
      if Assigned(FOnValidate) then
        FOnValidate(Self, TControlCharacters.Null);
    vkEscape:
      Hide;
    vkLeft:
      if Length(FCurrentString) > 0 then
      begin
        CurrentString := Copy(FCurrentString, 1, Length(FCurrentString) - 1);
        if Assigned(LEditor) then
          LEditor.CommandProcessor(TKeyCommands.Left, TControlCharacters.Null, nil);
      end
      else
      begin
        if Assigned(LEditor) then
          LEditor.CommandProcessor(TKeyCommands.Left, TControlCharacters.Null, nil);
        Hide;
      end;
    vkRight:
      if Assigned(LEditor) then
      with LEditor do
      begin
        LTextPosition := TextPosition;
        if LTextPosition.Char <= Length(FLines[LTextPosition.Line]) then
          LChar := FLines[LTextPosition.Line][LTextPosition.Char]
        else
          LChar := TCharacters.Space;

        if IsWordBreakChar(LChar) then
          Self.Hide
        else
          CurrentString := FCurrentString + LChar;

        CommandProcessor(TKeyCommands.Right, TControlCharacters.Null, nil);
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
        if Length(FCurrentString) > 0 then
        begin
          CurrentString := Copy(FCurrentString, 1, Length(FCurrentString) - 1);

          if Assigned(LEditor) then
            LEditor.CommandProcessor(TKeyCommands.Backspace, TControlCharacters.Null, nil);
        end
        else
        begin
          if Assigned(LEditor) then
            LEditor.CommandProcessor(TKeyCommands.Backspace, TControlCharacters.Null, nil);

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
  LIndex: Integer;
  LTop: Integer;
  LItemIndex: Integer;
  LText, LTemp, LDescription: string;
  LPosition, LWidth: Integer;
  LItem: TTextEditorCompletionProposalItem;
begin
  with FBitmapBuffer do
  begin
    Canvas.Brush.Color := FCompletionProposal.Colors.Background;
    Height := 0;
    Width := ClientWidth;
    Height := ClientHeight;

    LTop := 0;

    for LIndex := 0 to Min(FCompletionProposal.VisibleLines, Length(FItemIndexArray) - 1) do
    begin
      if LIndex + TopLine >= Length(FItemIndexArray) then
        Break;

      if (LIndex + TopLine = FSelectedLine) and not CodeInsight then
      begin
        Canvas.Font.Color := FCompletionProposal.Colors.SelectedText;
        Canvas.Brush.Color := FCompletionProposal.Colors.SelectedBackground;
        Canvas.Pen.Color := FCompletionProposal.Colors.SelectedBackground;
        Canvas.Rectangle(0, FItemHeight * LIndex, ClientWidth, FItemHeight * (LIndex + 1));
      end
      else
      begin
        Canvas.Font.Color := FCompletionProposal.Colors.Foreground;
        Canvas.Brush.Color := FCompletionProposal.Colors.Background;
      end;

      LItemIndex := FItemIndexArray[TopLine + LIndex];

      LItem := FItems[LItemIndex];
      LText := LItem.Keyword;
      LDescription := LItem.Description;

      if FCaseSensitive then
        LPosition := FastPos(AnsiUpperCase(FCurrentString), AnsiUpperCase(LText))
      else
        LPosition := FastPos(FCurrentString, LText);

      if LPosition > 0 then
      begin
        LWidth := 0;
        if LPosition > 1 then
        begin
          LTemp := Copy(LText, 1, LPosition - 1);
          Canvas.TextOut(FMargin, LTop, LTemp);
          Inc(LWidth, Canvas.TextWidth(LTemp));
        end;
        Canvas.Font.Style := Canvas.Font.Style + [fsUnderline];
        LTemp := Copy(LText, LPosition, Length(FCurrentString));
        Canvas.TextOut(FMargin + LWidth, LTop, LTemp);
        Inc(LWidth, Canvas.TextWidth(LTemp));
        Canvas.Font.Style := Canvas.Font.Style - [fsUnderline];
        LTemp := Copy(LText, LPosition + Length(FCurrentString));
        if LTemp <> '' then
          Canvas.TextOut(FMargin + LWidth, LTop, LTemp);
      end
      else
        Canvas.TextOut(FMargin, LTop, LText);

      if ShowDescription then
        Canvas.TextOut(FMargin + FItemWidth, LTop, LDescription);

      Inc(LTop, FItemHeight);
    end;
  end;
  Canvas.Draw(0, 0, FBitmapBuffer);
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

    if FCaseSensitive then
      Result := FastPos(AnsiUpperCase(AValue), AnsiUpperCase(LCompareString)) = 1
    else
      Result := FastPos(AValue, LCompareString) = 1;
  end;

  function MatchItem2(const AIndex: Integer): Boolean;
  var
    LCompareString: string;
  begin
    LCompareString := FItems[AIndex].Keyword;

    if FCaseSensitive then
      Result := FastPos(AnsiUpperCase(AValue), AnsiUpperCase(LCompareString)) > 1
    else
      Result := FastPos(AValue, LCompareString) > 1;
  end;

  procedure RecalcList(const AShowAllItems: Boolean);
  var
    LIndex, LIndex2, LItemsCount: Integer;
  begin
    LIndex2 := 0;
    LItemsCount := FItems.Count;
    SetLength(FItemIndexArray, 0);
    SetLength(FItemIndexArray, LItemsCount);
    for LIndex := 0 to LItemsCount - 1 do
    if AShowAllItems or MatchItem1(LIndex) then
    begin
      FItemIndexArray[LIndex2] := LIndex;
      Inc(LIndex2);
    end;
    for LIndex := 0 to LItemsCount - 1 do
    if MatchItem2(LIndex) then
    begin
      FItemIndexArray[LIndex2] := LIndex;
      Inc(LIndex2);
    end;
    SetLength(FItemIndexArray, LIndex2);
  end;

var
  LIndex: Integer;
begin
  FCurrentString := AValue;

  if FFiltered then
  begin
    RecalcList(AValue = '');
    TopLine := 0;
    Repaint;
  end
  else
  begin
    LIndex := 0;
    while (LIndex < FItems.Count) and not MatchItem1(LIndex) do
      Inc(LIndex);

    if LIndex < FItems.Count then
      TopLine := LIndex
    else
      TopLine := 0;
  end;

  UpdateScrollBar;
  Invalidate;
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

  if ssCtrl in aShift then
    LLinesToScroll := FCompletionProposal.VisibleLines
  else
    LLinesToScroll := 1;

  if AWheelDelta > 0 then
    TopLine := Max(0, TopLine - LLinesToScroll)
  else
    TopLine := Min(FItems.Count - FCompletionProposal.VisibleLines, TopLine + LLinesToScroll);

  Invalidate;
end;

procedure TTextEditorCompletionProposalPopupWindow.Execute(const ACurrentString: string; const APoint: TPoint;
  const AOptions: TCompletionProposalOptions);
var
  LPoint: TPoint;

  procedure CalculateFormPlacement;
  var
    LWidth: Integer;
    LHeight: Integer;
    LIndex, LMaxIndex, LMaxDescriptionIndex: Integer;
    LLength, LMaxLength, LMaxDescriptionLength: Integer;
    LText, LDescription: string;
    LItem: TTextEditorCompletionProposalItem;
  begin
    LPoint.X := APoint.X - TextWidth(FBitmapBuffer.Canvas, ACurrentString);
    LPoint.Y := APoint.Y;

    LMaxIndex := 0;
    LMaxDescriptionIndex := -1;
    LMaxLength := 0;
    LMaxDescriptionLength := 0;
    for LIndex := 0 to FItems.Count - 1 do
    begin
      LItem := FItems[LIndex];
      LText := LItem.Keyword;
      LDescription := LItem.Description;

      LLength := Length(LText);
      if LLength > LMaxLength then
      begin
        LMaxLength := LLength;
        LMaxIndex := LIndex;
      end;

      if ShowDescription then
      begin
        LLength := Length(LDescription);
        if LLength > LMaxDescriptionLength then
        begin
          LMaxDescriptionLength := LLength;
          LMaxDescriptionIndex := LIndex;
        end;
      end;
    end;

    LText := FItems[LMaxIndex].Keyword;

    FItemWidth := TextWidth(FBitmapBuffer.Canvas, LText);
    LWidth := FItemWidth + 2 * GetSystemMetrics(SM_CXVSCROLL);

    FItemDescriptionWidth := 0;
    if LMaxDescriptionIndex > -1 then
    begin
      LText := FItems[LMaxDescriptionIndex].Description;

      Inc(FItemWidth, TextWidth(FBitmapBuffer.Canvas, 'X'));
      FItemDescriptionWidth := TextWidth(FBitmapBuffer.Canvas, LText);
      Inc(LWidth, FItemDescriptionWidth);
    end;

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
    if cpoAutoConstraints in FCompletionProposal.Options then
    begin
      Constraints.MinHeight := Height;
      Constraints.MinWidth := Width;
    end;
  end;

var
  LIndex, LCount: Integer;
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
  for LIndex := 0 to LCount - 1 do
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
      UpdateScrollBar;
      Show(LPoint);
    end;
  end;
end;

procedure TTextEditorCompletionProposalPopupWindow.HandleOnValidate(ASender: TObject; const AEndToken: Char); //FI:O804 Method parameter is declared but never used
var
  LEditor: TCustomTextEditor;
  LValue, LLine: string;
  LTextPosition: TTextEditorTextPosition;
  LLineText: string;
  LIndex: Integer;
  LItem: TTextEditorCompletionProposalItem;
  LStringList: TStringList;
  LAddedSnippet: Boolean;
  LSnippetPosition, LSnippetSelectionBeginPosition, LSnippetSelectionEndPosition: TTextEditorTextPosition;
  LCharCount: Integer;
  LSpaces: string;
  LSnippetItem: TTextEditorCompletionProposalSnippetItem;
  LPLineText: PChar;
  LBeginChar: Integer;

  function GetBeginChar(const ARow: Integer): Integer;
  begin
    if ARow = 1 then
      Result := LEditor.SelectionBeginPosition.Char
    else
      Result := LCharCount + 1;
  end;

begin
  if not Assigned(Owner) or CodeInsight then
    Exit;

  LEditor := Owner as TCustomTextEditor;
  with LEditor do
  begin
    BeginUpdate;
    BeginUndoBlock;
    try
      LTextPosition := TextPosition;
      LLineText := FLines[LTextPosition.Line];

      if not SelectionAvailable then
      begin
        LIndex := LTextPosition.Char - 1;
        if LIndex <= Length(LLineText) then
        while (LIndex > 0) and (LLineText[LIndex] > TCharacters.Space) and not LEditor.IsWordBreakChar(LLineText[LIndex]) do
          Dec(LIndex);

        SelectionBeginPosition := GetPosition(LIndex + 1, LTextPosition.Line);
        if AEndToken = TControlCharacters.Null then
        begin
          LLine := Lines[LTextPosition.Line];
          if (Length(LLine) >= LTextPosition.Char) and IsWordBreakChar(LLine[LTextPosition.Char]) then
            SelectionEndPosition := LTextPosition
          else
            SelectionEndPosition := GetPosition(WordEnd.Char, LTextPosition.Line)
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
          LStringList.TrailingLineBreak := False;
          try
            LSnippetItem := CompletionProposal.Snippets.Item[LItem.SnippetIndex];

            LStringList.Text := LSnippetItem.Snippet.Text;

            LCharCount := 0;
            LPLineText := PChar(LLineText);
            for LIndex := 0 to SelectionBeginPosition.Char - 1 do
            begin
              if LPLineText^ = TControlCharacters.Tab then
                Inc(LCharCount, Tabs.Width)
              else
                Inc(LCharCount);

              if LPLineText^ <> TControlCharacters.Null then
                Inc(LPLineText);
            end;
            Dec(LCharCount);

            if toTabsToSpaces in Tabs.Options then
              LSpaces := StringOfChar(TCharacters.Space, LCharCount)
            else
            begin
              LSpaces := StringOfChar(TControlCharacters.Tab, LCharCount div Tabs.Width);
              LSpaces := LSpaces + StringOfChar(TCharacters.Space, LCharCount mod Tabs.Width);
            end;

            for LIndex := 1 to LStringList.Count - 1 do
              LStringList[LIndex] := LSpaces + LStringList[LIndex];

            if LSnippetItem.Position.Active then
            begin
              LBeginChar := GetBeginChar(LSnippetItem.Position.Row);
              LSnippetPosition := GetPosition(LBeginChar + LSnippetItem.Position.Column - 1,
                SelectionBeginPosition.Line + LSnippetItem.Position.Row - 1);
            end;

            if LSnippetItem.Selection.Active then
            begin
              LBeginChar := GetBeginChar(LSnippetItem.Selection.FromRow);
              LSnippetSelectionBeginPosition := GetPosition(LBeginChar + LSnippetItem.Selection.FromColumn - 1,
                SelectionBeginPosition.Line + LSnippetItem.Selection.FromRow - 1);
              LBeginChar := GetBeginChar(LSnippetItem.Selection.ToRow);
              LSnippetSelectionEndPosition := GetPosition(LBeginChar + LSnippetItem.Selection.ToColumn - 1,
                SelectionBeginPosition.Line + LSnippetItem.Selection.ToRow - 1);
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
          SelectionBeginPosition := LSnippetSelectionBeginPosition;
          SelectionEndPosition := LSnippetSelectionEndPosition;
        end
        else
        begin
          SelectionBeginPosition := TextPosition;
          SelectionEndPosition := SelectionBeginPosition;
        end;
      end
      else
      begin
        TextPosition := SelectionEndPosition;
        SelectionBeginPosition := TextPosition;
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
  LIndex: Integer;
  LLineText: string;
  LEditor: TCustomTextEditor;
  LTextPosition: TTextEditorTextPosition;
begin
  Result := '';

  LEditor := Owner as TCustomTextEditor;

  LTextPosition := LEditor.TextPosition;

  LLineText := FLines[LTextPosition.Line];
  LIndex := LTextPosition.Char - 1;
  if LIndex <= Length(LLineText) then
  begin
    while (LIndex > 0) and (LLineText[LIndex] > TCharacters.Space) and not LEditor.IsWordBreakChar(LLineText[LIndex]) do
      Dec(LIndex);

    Result := Copy(LLineText, LIndex + 1, LTextPosition.Char - LIndex - 1);
  end;
end;

procedure TTextEditorCompletionProposalPopupWindow.UpdateScrollBar;
var
  LScrollInfo: TScrollInfo;
begin
  LScrollInfo.cbSize := SizeOf(ScrollInfo);
  LScrollInfo.fMask := SIF_ALL;
  LScrollInfo.fMask := LScrollInfo.fMask or SIF_DISABLENOSCROLL;

  if Visible then
    SendMessage(Handle, WM_SETREDRAW, 0, 0);

  LScrollInfo.nMin := 0;
  LScrollInfo.nMax := Max(0, Length(FItemIndexArray) - 1);
  LScrollInfo.nPage := FCompletionProposal.VisibleLines;
  LScrollInfo.nPos := TopLine;

  ShowScrollBar(Handle, SB_VERT, Length(FItemIndexArray) > FCompletionProposal.VisibleLines);
  SetScrollInfo(Handle, SB_VERT, LScrollInfo, True);

  if FItems.Count <= FCompletionProposal.VisibleLines then
    EnableScrollBar(Handle, SB_VERT, ESB_DISABLE_BOTH)
  else
  begin
    EnableScrollBar(Handle, SB_VERT, ESB_ENABLE_BOTH);
    if TopLine <= 0 then
      EnableScrollBar(Handle, SB_VERT, ESB_DISABLE_UP)
    else
    if TopLine + FCompletionProposal.VisibleLines >= Length(FItemIndexArray) then
      EnableScrollBar(Handle, SB_VERT, ESB_DISABLE_DOWN);
  end;

  if Visible then
    SendMessage(Handle, WM_SETREDRAW, -1, 0);
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

procedure TTextEditorCompletionProposalPopupWindow.MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer);
begin
  if not CodeInsight then
  begin
    FSelectedLine := Max(0, TopLine + (Y div FItemHeight));

    inherited MouseDown(AButton, AShift, X, Y);

    Refresh;
  end;
end;

end.
