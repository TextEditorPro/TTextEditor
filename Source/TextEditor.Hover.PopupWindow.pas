unit TextEditor.Hover.PopupWindow;

{$I TextEditor.Defines.inc}

interface

uses
  System.Classes, System.Generics.Collections, System.Types, System.UITypes, Vcl.Controls, Vcl.Graphics, TextEditor.PopupWindow,
  TextEditor.Utils;

type
  TTextEditorHoverPopupLineKind = (hlCode, hlText);

  TTextEditorHoverPopupLine = record
    Kind: TTextEditorHoverPopupLineKind;
    Text: string;
    HighlightBegin: Integer;
    HighlightLength: Integer;
  end;

  TTextEditorHoverPopupRowKind = (hrCode, hrText, hrLink, hrSeparator);

  TTextEditorHoverPopupRow = record
    Kind: TTextEditorHoverPopupRowKind;
    Text: string;
    Left: Integer;
    Top: Integer;
    Height: Integer;
    HighlightBegin: Integer;
    HighlightLength: Integer;
    SameLine: Boolean;
  end;

  TTextEditorHoverPopupWindow = class(TTextEditorPopupWindow)
  strict private
    FBackgroundColor: TColor;
    FCodeFont: TFont;
    FLines: TList<TTextEditorHoverPopupLine>;
    FLinkColor: TColor;
    FLinkHot: Boolean;
    FLinkRect: TRect;
    FLinkText: string;
    FOnLinkClick: TNotifyEvent;
    FRows: TList<TTextEditorHoverPopupRow>;
    FTextColor: TColor;
    FTextFont: TFont;
    function RowFont(const AKind: TTextEditorHoverPopupRowKind): TFont;
    function RowTextWidth(const ARow: TTextEditorHoverPopupRow): Integer;
    function WrapLine(const AText: string; const AMaxWidth: Integer): TArray<string>;
    procedure ApplyEditorAppearance;
    procedure BuildLayout(const AMaxWidth: Integer; const AMaxHeight: Integer; out AContentWidth: Integer; out AContentHeight: Integer);
  protected
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(AShift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AddLine(const AKind: TTextEditorHoverPopupLineKind; const AText: string; const AHighlightBegin: Integer = 0;
      const AHighlightLength: Integer = 0);
    procedure Clear;
    procedure Execute(const AAnchorRect: TRect; const APreferAbove: Boolean = False);
    property LinkText: string read FLinkText write FLinkText;
    property OnLinkClick: TNotifyEvent read FOnLinkClick write FOnLinkClick;
  end;

implementation

uses
  System.Math, System.SysUtils, Vcl.Forms, TextEditor, TextEditor.Consts;

const
  HORIZONTAL_MARGIN = 6;
  VERTICAL_MARGIN = 4;
  ROW_GAP = 2;
  SEPARATOR_HEIGHT = 7;
  LINK_SEPARATOR = ' - ';

constructor TTextEditorHoverPopupWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FCodeFont := TFont.Create;
  FTextFont := TFont.Create;
  FLines := TList<TTextEditorHoverPopupLine>.Create;
  FRows := TList<TTextEditorHoverPopupRow>.Create;

  FBorderWidth := 1;
end;

destructor TTextEditorHoverPopupWindow.Destroy;
begin
  FCodeFont.Free;
  FTextFont.Free;
  FLines.Free;
  FRows.Free;

  inherited Destroy;
end;

function TTextEditorHoverPopupWindow.RowFont(const AKind: TTextEditorHoverPopupRowKind): TFont;
begin
  Result := if AKind = hrCode then FCodeFont else FTextFont;
end;

function TTextEditorHoverPopupWindow.RowTextWidth(const ARow: TTextEditorHoverPopupRow): Integer;
begin
  Canvas.Font.Assign(RowFont(ARow.Kind));

  if ARow.HighlightLength <= 0 then
    Exit(Canvas.TextWidth(ARow.Text));

  Result := Canvas.TextWidth(Copy(ARow.Text, 1, ARow.HighlightBegin - 1));

  Canvas.Font.Style := Canvas.Font.Style + [fsBold];
  Inc(Result, Canvas.TextWidth(Copy(ARow.Text, ARow.HighlightBegin, ARow.HighlightLength)));
  Canvas.Font.Style := Canvas.Font.Style - [fsBold];

  Inc(Result, Canvas.TextWidth(Copy(ARow.Text, ARow.HighlightBegin + ARow.HighlightLength)));
end;

procedure TTextEditorHoverPopupWindow.AddLine(const AKind: TTextEditorHoverPopupLineKind; const AText: string;
  const AHighlightBegin: Integer = 0; const AHighlightLength: Integer = 0);
var
  LLine: TTextEditorHoverPopupLine;
begin
  LLine.Kind := AKind;
  LLine.Text := AText;
  LLine.HighlightBegin := AHighlightBegin;
  LLine.HighlightLength := AHighlightLength;

  FLines.Add(LLine);
end;

procedure TTextEditorHoverPopupWindow.Clear;
begin
  FLines.Clear;
  FRows.Clear;

  FLinkText := '';
  FLinkHot := False;
  FLinkRect := TRect.Empty;
end;

procedure TTextEditorHoverPopupWindow.ApplyEditorAppearance;
var
  LEditor: TCustomTextEditor;
begin
  LEditor := Owner as TCustomTextEditor;

  FBackgroundColor := LEditor.Colors.HintBackground;
  FBorderColor := LEditor.Colors.HintBorder;
  FTextColor := LEditor.Colors.HintText;
  FLinkColor := TColors.SysHotLight;

  AssignFont(FCodeFont, LEditor.Fonts.Text);
  AssignFont(FTextFont, LEditor.Fonts.Hint);

  Color := FBackgroundColor;
end;

function TTextEditorHoverPopupWindow.WrapLine(const AText: string; const AMaxWidth: Integer): TArray<string>;
var
  LResult: TList<string>;
  LText: string;
  LLow, LHigh, LMiddle, LBreakIndex: Integer;
begin
  LResult := TList<string>.Create;
  try
    LText := AText;

    while (LText.Length > 0) and (Canvas.TextWidth(LText) > AMaxWidth) do
    begin
      LLow := 1;
      LHigh := LText.Length - 1;

      while LLow < LHigh do
      begin
        LMiddle := (LLow + LHigh + 1) div 2;

        if Canvas.TextWidth(Copy(LText, 1, LMiddle)) > AMaxWidth then
          LHigh := LMiddle - 1
        else
          LLow := LMiddle;
      end;

      LBreakIndex := LLow;

      while (LBreakIndex > 1) and (LText[LBreakIndex] <> ' ') do
        Dec(LBreakIndex);

      if LBreakIndex = 1 then
        LBreakIndex := LLow;

      LResult.Add(Copy(LText, 1, LBreakIndex).TrimRight);
      LText := Copy(LText, LBreakIndex + 1).TrimLeft;
    end;

    LResult.Add(LText);

    Result := LResult.ToArray;
  finally
    LResult.Free;
  end;
end;

procedure TTextEditorHoverPopupWindow.BuildLayout(const AMaxWidth: Integer; const AMaxHeight: Integer; out AContentWidth: Integer;
  out AContentHeight: Integer);
const
  MAX_ROWS = 100;
var
  LLine: TTextEditorHoverPopupLine;
  LRow: TTextEditorHoverPopupRow;
  LRowKind: TTextEditorHoverPopupRowKind;
  LText: string;
  LIndex, LTop, LRowWidth, LLinkWidth, LSeparatorWidth: Integer;
  LCompact: Boolean;
  LMaxTextWidth: Integer;
begin
  FRows.Clear;
  FLinkRect := TRect.Empty;

  LMaxTextWidth := AMaxWidth - 2 * HORIZONTAL_MARGIN;

  for LLine in FLines do
  begin
    LRowKind := if LLine.Kind = hlCode then hrCode else hrText;

    Canvas.Font.Assign(RowFont(LRowKind));

    { Highlighted lines carry character indexes into their text, so they stay on a single unwrapped row. }
    if LLine.HighlightLength > 0 then
    begin
      LRow := Default(TTextEditorHoverPopupRow);
      LRow.Kind := LRowKind;
      LRow.Text := LLine.Text;
      LRow.Left := HORIZONTAL_MARGIN;
      LRow.HighlightBegin := LLine.HighlightBegin;
      LRow.HighlightLength := LLine.HighlightLength;
      FRows.Add(LRow);
    end
    else
    for LText in WrapLine(LLine.Text, LMaxTextWidth) do
    begin
      LRow := Default(TTextEditorHoverPopupRow);
      LRow.Kind := LRowKind;
      LRow.Text := LText;
      LRow.Left := HORIZONTAL_MARGIN;
      FRows.Add(LRow);

      if FRows.Count >= MAX_ROWS then
        Break;
    end;

    if FRows.Count >= MAX_ROWS then
      Break;
  end;

  if not FLinkText.IsEmpty then
  begin
    Canvas.Font.Assign(FTextFont);
    LLinkWidth := Canvas.TextWidth(FLinkText);
    LSeparatorWidth := Canvas.TextWidth(LINK_SEPARATOR);

    LCompact := False;
    LRowWidth := 0;

    if FRows.Count = 1 then
    begin
      Canvas.Font.Assign(RowFont(FRows[0].Kind));
      LRowWidth := Canvas.TextWidth(FRows[0].Text);
      LCompact := LRowWidth + LSeparatorWidth + LLinkWidth <= LMaxTextWidth;
    end;

    if LCompact then
    begin
      LRow := Default(TTextEditorHoverPopupRow);
      LRow.Kind := hrText;
      LRow.Text := LINK_SEPARATOR;
      LRow.Left := HORIZONTAL_MARGIN + LRowWidth;
      LRow.SameLine := True;
      FRows.Add(LRow);

      LRow.Kind := hrLink;
      LRow.Text := FLinkText;
      LRow.Left := HORIZONTAL_MARGIN + LRowWidth + LSeparatorWidth;
      FRows.Add(LRow);
    end
    else
    begin
      if FRows.Count > 0 then
      begin
        LRow := Default(TTextEditorHoverPopupRow);
        LRow.Kind := hrSeparator;
        FRows.Add(LRow);
      end;

      LRow := Default(TTextEditorHoverPopupRow);
      LRow.Kind := hrLink;
      LRow.Text := FLinkText;
      LRow.Left := HORIZONTAL_MARGIN;
      FRows.Add(LRow);
    end;
  end;

  LTop := VERTICAL_MARGIN;
  AContentWidth := 0;
  LIndex := 0;

  while LIndex < FRows.Count do
  begin
    LRow := FRows[LIndex];

    Canvas.Font.Assign(RowFont(LRow.Kind));

    LRow.Height := if LRow.Kind = hrSeparator then SEPARATOR_HEIGHT else Canvas.TextHeight('X') + ROW_GAP;

    if LRow.SameLine and (LIndex > 0) then
      LRow.Top := FRows[LIndex - 1].Top + FRows[LIndex - 1].Height - LRow.Height
    else
    begin
      if (LTop + LRow.Height > AMaxHeight) and (LIndex > 0) then
      begin
        FRows.DeleteRange(LIndex, FRows.Count - LIndex);

        Canvas.Font.Assign(FTextFont);

        LRow := Default(TTextEditorHoverPopupRow);
        LRow.Kind := hrText;
        LRow.Text := TCharacters.ThreeDots;
        LRow.Left := HORIZONTAL_MARGIN;
        LRow.Top := LTop;
        LRow.Height := Canvas.TextHeight('X') + ROW_GAP;
        FRows.Add(LRow);

        Inc(LTop, LRow.Height);

        Break;
      end;

      LRow.Top := LTop;
      Inc(LTop, LRow.Height);
    end;

    if LRow.Kind <> hrSeparator then
      AContentWidth := Max(AContentWidth, LRow.Left + RowTextWidth(LRow));

    if LRow.Kind = hrLink then
      FLinkRect := Rect(LRow.Left, LRow.Top, LRow.Left + Canvas.TextWidth(LRow.Text), LRow.Top + LRow.Height);

    FRows[LIndex] := LRow;

    Inc(LIndex);
  end;

  AContentWidth := AContentWidth + HORIZONTAL_MARGIN;
  AContentHeight := LTop + VERTICAL_MARGIN;
end;

procedure TTextEditorHoverPopupWindow.Execute(const AAnchorRect: TRect; const APreferAbove: Boolean = False);
var
  LWorkArea: TRect;
  LContentWidth, LContentHeight: Integer;
  LWidth, LHeight: Integer;
  LPoint: TPoint;
begin
  HandleNeeded;
  ApplyEditorAppearance;

  LWorkArea := Screen.MonitorFromPoint(AAnchorRect.TopLeft).WorkareaRect;

  BuildLayout(LWorkArea.Width * 2 div 3, LWorkArea.Height div 2, LContentWidth, LContentHeight);

  if FRows.Count = 0 then
    Exit;

  LWidth := LContentWidth + 2 * FBorderWidth;
  LHeight := LContentHeight + 2 * FBorderWidth;

  LPoint.X := EnsureRange(AAnchorRect.Left, LWorkArea.Left, Max(LWorkArea.Left, LWorkArea.Right - LWidth));

  if APreferAbove then
  begin
    LPoint.Y := AAnchorRect.Top - LHeight - 2;

    if LPoint.Y < LWorkArea.Top then
      LPoint.Y := AAnchorRect.Bottom + 2;
  end
  else
  begin
    LPoint.Y := AAnchorRect.Bottom + 2;

    if LPoint.Y + LHeight > LWorkArea.Bottom then
      LPoint.Y := Max(LWorkArea.Top, AAnchorRect.Top - LHeight - 2);
  end;

  FLinkHot := False;
  Cursor := crDefault;

  Width := LWidth;
  Height := LHeight;

  Invalidate;
  Show(LPoint);
end;

procedure TTextEditorHoverPopupWindow.Paint;
var
  LRow: TTextEditorHoverPopupRow;
  LText: string;
  LLeft: Integer;
begin
  Canvas.Brush.Color := FBackgroundColor;
  Canvas.FillRect(ClientRect);

  Canvas.Brush.Style := bsClear;

  for LRow in FRows do
  case LRow.Kind of
    hrSeparator:
      begin
        Canvas.Pen.Color := FBorderColor;
        Canvas.MoveTo(HORIZONTAL_MARGIN, LRow.Top + LRow.Height div 2);
        Canvas.LineTo(ClientWidth - HORIZONTAL_MARGIN, LRow.Top + LRow.Height div 2);
      end;
    hrLink:
      begin
        Canvas.Font.Assign(FTextFont);
        Canvas.Font.Color := FLinkColor;

        if FLinkHot then
          Canvas.Font.Style := Canvas.Font.Style + [fsUnderline];

        Canvas.TextOut(LRow.Left, LRow.Top + 1, LRow.Text);
      end;
  else
    Canvas.Font.Assign(RowFont(LRow.Kind));
    Canvas.Font.Color := FTextColor;

    if LRow.HighlightLength > 0 then
    begin
      LLeft := LRow.Left;
      LText := Copy(LRow.Text, 1, LRow.HighlightBegin - 1);
      Canvas.TextOut(LLeft, LRow.Top + 1, LText);
      Inc(LLeft, Canvas.TextWidth(LText));

      Canvas.Font.Style := Canvas.Font.Style + [fsBold];
      LText := Copy(LRow.Text, LRow.HighlightBegin, LRow.HighlightLength);
      Canvas.TextOut(LLeft, LRow.Top + 1, LText);
      Inc(LLeft, Canvas.TextWidth(LText));
      Canvas.Font.Style := Canvas.Font.Style - [fsBold];

      Canvas.TextOut(LLeft, LRow.Top + 1, Copy(LRow.Text, LRow.HighlightBegin + LRow.HighlightLength));
    end
    else
      Canvas.TextOut(LRow.Left, LRow.Top + 1, LRow.Text);
  end;

  PaintClientBorder;
end;

procedure TTextEditorHoverPopupWindow.MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(AButton, AShift, X, Y);

  if (AButton = mbLeft) and PtInRect(FLinkRect, Point(X, Y)) and Assigned(FOnLinkClick) then
    FOnLinkClick(Self);
end;

procedure TTextEditorHoverPopupWindow.MouseMove(AShift: TShiftState; X, Y: Integer);
var
  LHot: Boolean;
begin
  inherited MouseMove(AShift, X, Y);

  LHot := PtInRect(FLinkRect, Point(X, Y));

  if LHot <> FLinkHot then
  begin
    FLinkHot := LHot;
    Cursor := if LHot then crHandPoint else crDefault;

    Invalidate;
  end;
end;

end.
