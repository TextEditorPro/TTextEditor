unit FMX.TextEditor.Compare.ScrollBar;

{$I FMX.TextEditor.Defines.inc}

interface

uses
  System.Classes, System.Types, System.UITypes, FMX.Controls, FMX.StdCtrls, FMX.Types, FMX.TextEditor,
  FMX.TextEditor.Border;

type
  [ComponentPlatformsAttribute(pidWin32 or pidWin64 or pidOSX64 or pidOSXArm64 or pidiOSDevice64 or pidiOSSimulatorArm64 or pidAndroidArm32 or pidAndroidArm64 or pidLinux64)]
  TTextEditorCompareScrollBar = class(TControl)
  strict private const
    SCROLLBAR_SIZE = 16;
    DRAG_THRESHOLD = 4;
  strict private
    FBorderStyle: TBorderStyle;
    FEditorLeft: TTextEditor;
    FEditorRight: TTextEditor;
    FMouseDownY: Integer;
    FScrollBar: TScrollBar;
    FScrollBarClicked: Boolean;
    FScrollBarDragging: Boolean;
    FScrollBarOffsetY: Integer;
    FScrollBarTopLine: Integer;
    FScrollBarVisible: Boolean;
    FTopLine: Integer;
    FUpdatingScrollBar: Boolean;
    FVisibleLines: Integer;
    function ClientHeight: Integer;
    function ClientWidth: Integer;
    procedure DoOnScrollBarClick(const Y: Integer);
    procedure DragMinimap(const AY: Integer);
    procedure ScrollBarChange(ASender: TObject);
    procedure SetBorderStyle(const AValue: TBorderStyle);
    procedure SetEditorLeft(const AEditor: TTextEditor);
    procedure SetEditorRight(const AEditor: TTextEditor);
    procedure SetScrollBarVisible(const AValue: Boolean);
    procedure SetTopLine(const AValue: Integer);
  protected
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Single); override;
    procedure MouseMove(AShift: TShiftState; X, Y: Single); override;
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; X, Y: Single); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Invalidate;
    procedure UpdateScrollBars;
    property TopLine: Integer read FTopLine write SetTopLine;
  published
    property Align;
    property Anchors;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsSingle;
    property EditorLeft: TTextEditor read FEditorLeft write SetEditorLeft;
    property EditorRight: TTextEditor read FEditorRight write SetEditorRight;
    property Height;
    property Margins;
    property Position;
    property ScrollBarVisible: Boolean read FScrollBarVisible write SetScrollBarVisible default False;
    property Size;
    property Visible default True;
    property Width;
  end;

implementation

uses
  System.Math, FMX.Graphics, FMX.TextEditor.Colors, FMX.TextEditor.Consts, FMX.TextEditor.Lines,
  FMX.TextEditor.Scroll, FMX.TextEditor.Types;

constructor TTextEditorCompareScrollBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FBorderStyle := bsSingle;
  FScrollBarVisible := False;

  FScrollBar := TScrollBar.Create(Self);
  FScrollBar.Stored := False;
  FScrollBar.Parent := Self;
  FScrollBar.Orientation := TOrientation.Vertical;
  FScrollBar.Cursor := crArrow;
  FScrollBar.Width := SCROLLBAR_SIZE;
  FScrollBar.SmallChange := 1;
  FScrollBar.Visible := False;
  FScrollBar.OnChange := ScrollBarChange;
end;

function TTextEditorCompareScrollBar.ClientHeight: Integer;
begin
  Result := Round(Height);
end;

function TTextEditorCompareScrollBar.ClientWidth: Integer;
begin
  Result := Round(Width);

  if FScrollBar.Visible then
    Dec(Result, SCROLLBAR_SIZE);
end;

procedure TTextEditorCompareScrollBar.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);

  if Operation = opRemove then
  begin
    if AComponent = FEditorLeft then
      FEditorLeft := nil;

    if AComponent = FEditorRight then
      FEditorRight := nil;
  end;
end;

procedure TTextEditorCompareScrollBar.Paint;
var
  LLine: Integer;
  LHalfWidth, LClientWidth: Integer;
  LY: Single;
  LViewRect: TRectF;
  LStringRecord: TTextEditorStringRecord;

  procedure DrawBorder;
  begin
    if FBorderStyle = bsSingle then
    begin
      Canvas.Stroke.Kind := TBrushKind.Solid;
      Canvas.Stroke.Color := TAlphaColor($FFB4B4B4);
      Canvas.Stroke.Thickness := 1;
      Canvas.DrawRect(RectF(0.5, 0.5, Width - 0.5, Height - 0.5), 0, 0, [], AbsoluteOpacity);
    end;
  end;

begin
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := if Assigned(FEditorLeft) then FEditorLeft.Colors.EditorBackground else TAlphaColors.White;
  Canvas.FillRect(LocalRect, 0, 0, [], AbsoluteOpacity);

  if not Assigned(FEditorLeft) or not Assigned(FEditorRight) then
  begin
    DrawBorder;
    Exit;
  end;

  if FEditorLeft.Lines.Count <> FEditorRight.Lines.Count then
  begin
    DrawBorder;
    Exit;
  end;

  if csDesigning in ComponentState then
  begin
    DrawBorder;
    Exit;
  end;

  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Thickness := 1;

  LLine := 0;
  LClientWidth := ClientWidth;
  LHalfWidth := LClientWidth shr 1;

  for var LIndex := FScrollBarTopLine to Min(FScrollBarTopLine + ClientHeight - 1, FEditorLeft.Lines.Count) do
  begin
    Canvas.Stroke.Color :=
      if (LIndex >= FTopLine) and (LIndex < FTopLine + FVisibleLines) then
        FEditorLeft.Colors.CompareForeground
      else
        FEditorLeft.Colors.CompareBackground;

    LY := LLine + 0.5;
    LStringRecord := FEditorLeft.Lines.Items^[LIndex - 1];

    if sfModify in LStringRecord.Flags then
      Canvas.DrawLine(PointF(0, LY), PointF(LHalfWidth, LY), AbsoluteOpacity);

    if sfEmptyLine in LStringRecord.Flags then
      Canvas.DrawLine(PointF(LHalfWidth, LY), PointF(LClientWidth, LY), AbsoluteOpacity);

    LStringRecord := FEditorRight.Lines.Items^[LIndex - 1];

    if sfModify in LStringRecord.Flags then
      Canvas.DrawLine(PointF(LHalfWidth, LY), PointF(LClientWidth, LY), AbsoluteOpacity);

    if sfEmptyLine in LStringRecord.Flags then
      Canvas.DrawLine(PointF(0, LY), PointF(LHalfWidth, LY), AbsoluteOpacity);

    Inc(LLine);
  end;

  LViewRect.Left := 0.5;
  LViewRect.Top := FTopLine - FScrollBarTopLine + 0.5;
  LViewRect.Right := LClientWidth - 0.5;
  LViewRect.Bottom := LViewRect.Top + FVisibleLines - 1;

  Canvas.Stroke.Color := TDefaultColors.SysHighlight;
  Canvas.DrawRect(LViewRect, 0, 0, [], AbsoluteOpacity);

  DrawBorder;
end;

procedure TTextEditorCompareScrollBar.Invalidate;
begin
  if csDesigning in ComponentState then
    Exit;

  if Assigned(FEditorLeft) then
    FVisibleLines := FEditorLeft.VisibleLineCount;

  UpdateScrollBars;
  Repaint;
end;

procedure TTextEditorCompareScrollBar.Resize;
begin
  inherited Resize;

  Invalidate;
end;

procedure TTextEditorCompareScrollBar.SetBorderStyle(const AValue: TBorderStyle);
begin
  if FBorderStyle <> AValue then
  begin
    FBorderStyle := AValue;

    Repaint;
  end;
end;

procedure TTextEditorCompareScrollBar.SetEditorLeft(const AEditor: TTextEditor);
begin
  FEditorLeft := AEditor;

  if Assigned(FEditorLeft) then
    FEditorLeft.FreeNotification(Self);

  Invalidate;
end;

procedure TTextEditorCompareScrollBar.SetEditorRight(const AEditor: TTextEditor);
begin
  FEditorRight := AEditor;

  if Assigned(FEditorRight) then
    FEditorRight.FreeNotification(Self);

  Invalidate;
end;

procedure TTextEditorCompareScrollBar.SetScrollBarVisible(const AValue: Boolean);
begin
  if FScrollBarVisible <> AValue then
  begin
    FScrollBarVisible := AValue;

    UpdateScrollBars;
    Repaint;
  end;
end;

procedure TTextEditorCompareScrollBar.UpdateScrollBars;
var
  LLineNumbersCount: Integer;
begin
  if not Assigned(FScrollBar) or FUpdatingScrollBar then
    Exit;

  LLineNumbersCount := if Assigned(FEditorLeft) then FEditorLeft.LineNumbersCount else 1;

  if FScrollBarVisible and not (csDesigning in ComponentState) and Assigned(FEditorLeft) and
    (LLineNumbersCount <= FVisibleLines) then
    TopLine := 1;

  FUpdatingScrollBar := True;
  try
    if FScrollBarVisible and not (csDesigning in ComponentState) then
    begin
      FScrollBar.Visible := LLineNumbersCount > FVisibleLines;

      if FScrollBar.Visible then
      begin
        FScrollBar.Min := 1;
        FScrollBar.Max := Max(1, LLineNumbersCount) + 1;
        FScrollBar.ViewportSize := FVisibleLines;
        FScrollBar.Value := TopLine;
        FScrollBar.SetBounds(Width - SCROLLBAR_SIZE, 0, SCROLLBAR_SIZE, Height);
      end;
    end
    else
      FScrollBar.Visible := False;
  finally
    FUpdatingScrollBar := False;
  end;
end;

procedure TTextEditorCompareScrollBar.ScrollBarChange(ASender: TObject);
begin
  if FUpdatingScrollBar then
    Exit;

  TopLine := Round(FScrollBar.Value);
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
    Repaint;
  end;
end;

procedure TTextEditorCompareScrollBar.MouseMove(AShift: TShiftState; X, Y: Single);
begin
  if FScrollBarClicked then
  begin
    if FScrollBarDragging then
    begin
      DragMinimap(Round(Y));

      if Assigned(FEditorLeft) then
        FEditorLeft.Repaint;

      if Assigned(FEditorRight) then
        FEditorRight.Repaint;
    end;

    if not FScrollBarDragging and (ssLeft in AShift) and (Abs(FMouseDownY - Round(Y)) >= DRAG_THRESHOLD) then
      FScrollBarDragging := True;

    Exit;
  end;

  inherited MouseMove(AShift, X, Y);
end;

procedure TTextEditorCompareScrollBar.MouseUp(AButton: TMouseButton; AShift: TShiftState; X, Y: Single);
begin
  FScrollBarClicked := False;
  FScrollBarDragging := False;

  inherited MouseUp(AButton, AShift, X, Y);
end;

procedure TTextEditorCompareScrollBar.MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Single);
begin
  if AButton = TMouseButton.mbLeft then
    FMouseDownY := Round(Y);

  if not FScrollBarDragging and InRange(Round(X), 0, ClientWidth) then
  begin
    DoOnScrollBarClick(Round(Y));
    Repaint;
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

end.
