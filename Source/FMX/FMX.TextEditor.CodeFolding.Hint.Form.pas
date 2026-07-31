unit FMX.TextEditor.CodeFolding.Hint.Form;

interface

uses
  System.Classes, System.Types, System.UITypes, FMX.Controls, FMX.Graphics, FMX.TextEditor.PopupWindow, FMX.Types;

type
  TTextEditorCodeFoldingHintForm = class(TTextEditorPopupWindow)
  strict private
    FBackgroundColor: TAlphaColor;
    FBufferBitmap: TBitmap;
    FEffectiveItemHeight: Single;
    FFont: TFont;
    FFontHeight: Single;
    FFormWidth: Integer;
    FItemHeight: Integer;
    FItemList: TStrings;
    FMargin: Integer;
    FTextColor: TAlphaColor;
    FVisibleLines: Integer;
    procedure RecalculateItemHeight;
    procedure SetFont(const AValue: TFont);
    procedure SetItemHeight(const AValue: Integer);
    procedure SetItemList(const AValue: TStrings);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Execute(const X, Y: Single);
    property BackgroundColor: TAlphaColor read FBackgroundColor write FBackgroundColor;
    property BorderColor: TAlphaColor read FBorderColor write FBorderColor;
    property Font: TFont read FFont write SetFont;
    property FormWidth: Integer read FFormWidth write FFormWidth; { Don't use the width because it triggers resizing }
    property ItemHeight: Integer read FItemHeight write SetItemHeight default 0;
    property ItemList: TStrings read FItemList write SetItemList;
    property Margin: Integer read FMargin write FMargin default 2;
    property TextColor: TAlphaColor read FTextColor write FTextColor;
    property VisibleLines: Integer read FVisibleLines write FVisibleLines;
  end;

implementation

uses
  FMX.TextEditor, FMX.TextEditor.PaintHelper, FMX.TextEditor.Utils;

constructor TTextEditorCodeFoldingHintForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  HitTest := False;

  FBufferBitmap := TBitmap.Create;

  FItemList := TStringList.Create;

  FFont := TFont.Create;
  FFont.Family := 'Courier New';
  FFont.Size := 8 * 96 / 72;

  FBackgroundColor := TAlphaColors.White;
  FBorderColor := TAlphaColors.Lightgray;
  FTextColor := TAlphaColors.Black;

  FItemHeight := 0;
  FMargin := 2;
  FEffectiveItemHeight := 0;

  RecalculateItemHeight;
end;

destructor TTextEditorCodeFoldingHintForm.Destroy;
begin
  FBufferBitmap.Free;
  FItemList.Free;
  FFont.Free;

  inherited Destroy;
end;

procedure TTextEditorCodeFoldingHintForm.Paint;
var
  LRect: TRectF;
begin
  LRect := LocalRect;

  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := FBackgroundColor;
  Canvas.FillRect(LRect, 0, 0, [], AbsoluteOpacity);

  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Color := FBorderColor;
  Canvas.DrawRect(RectF(LRect.Left + 0.5, LRect.Top + 0.5, LRect.Right - 0.5, LRect.Bottom - 0.5), 0, 0, [],
    AbsoluteOpacity);

  Canvas.Font.Assign(FFont);
  Canvas.Fill.Color := FTextColor;

  for var LIndex := 0 to FItemList.Count - 1 do
    Canvas.FillText(RectF(FMargin + 1, FEffectiveItemHeight * LIndex + FMargin, LRect.Right - FMargin,
      FEffectiveItemHeight * (LIndex + 1) + FMargin), FItemList[LIndex], False, AbsoluteOpacity, [],
      TTextAlign.Leading, TTextAlign.Leading);
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
  FBufferBitmap.SetSize(1, 1);

  if FBufferBitmap.Canvas.BeginScene then
  try
    FBufferBitmap.Canvas.Font.Assign(FFont);
    FFontHeight := TextHeight(FBufferBitmap.Canvas, 'X');
  finally
    FBufferBitmap.Canvas.EndScene;
  end;

  FEffectiveItemHeight := if FItemHeight > 0 then FItemHeight else FFontHeight;
end;

procedure TTextEditorCodeFoldingHintForm.SetFont(const AValue: TFont);
begin
  FFont.Assign(AValue);

  RecalculateItemHeight;
end;

procedure TTextEditorCodeFoldingHintForm.Execute(const X, Y: Single);
var
  LEditor: TCustomTextEditor;
  LX, LY: Single;
  LWidth: Single;
  LBorderWidth: Integer;
  LHeight: Single;
  LNewWidth: Single;
begin
  LEditor := Owner as TCustomTextEditor;

  LX := X;
  LY := Y;
  LWidth := 0;
  LBorderWidth := 2;
  LHeight := FEffectiveItemHeight * ItemList.Count + LBorderWidth + 2 * Margin;

  FBufferBitmap.SetSize(1, 1);

  if FBufferBitmap.Canvas.BeginScene then
  try
    FBufferBitmap.Canvas.Font.Assign(FFont);

    for var LIndex := 0 to ItemList.Count - 1 do
    begin
      LNewWidth := TextWidth(FBufferBitmap.Canvas, ItemList[LIndex]);

      if LNewWidth > LWidth then
        LWidth := LNewWidth;
    end;
  finally
    FBufferBitmap.Canvas.EndScene;
  end;

  LWidth := LWidth + 2 * Margin + LBorderWidth + 4;

  if LX + LWidth > LEditor.Width then
  begin
    LX := LEditor.Width - LWidth - 5;

    if LX < 0 then
      LX := 0;
  end;

  if LY + LHeight > LEditor.Height then
  begin
    LY := LY - LHeight - LEditor.LineHeight - 2;

    if LY < 0 then
      LY := 0;
  end;

  SetBounds(Position.X, Position.Y, LWidth, LHeight);

  Show(PointF(LX, LY));
end;

end.
