unit TextEditor.Ruler.Colors;

interface

uses
  System.Classes, System.UITypes, TextEditor.Consts;

type
  TTextEditorRulerColors = class(TPersistent)
  strict private
    FBackground: TColor;
    FBorder: TColor;
    FLines: TColor;
    FMovingEdge: TColor;
    FSelection: TColor;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Background: TColor read FBackground write FBackground default TDefaultColors.LeftMarginBackground;
    property Border: TColor read FBorder write FBorder default TDefaultColors.LeftMarginFontForeground;
    property Lines: TColor read FLines write FLines default TDefaultColors.LeftMarginFontForeground;
    property MovingEdge: TColor read FMovingEdge write FMovingEdge default TColors.Silver;
    property Selection: TColor read FSelection write FSelection default TColors.SysBtnFace;
  end;

implementation

constructor TTextEditorRulerColors.Create;
begin
  inherited;

  FBackground := TDefaultColors.LeftMarginBackground;
  FBorder := TDefaultColors.LeftMarginFontForeground;
  FLines := TDefaultColors.LeftMarginFontForeground;
  FMovingEdge := TColors.Silver;
  FSelection := TColors.SysBtnFace;
end;

procedure TTextEditorRulerColors.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorRulerColors) then
  with ASource as TTextEditorRulerColors do
  begin
    Self.FBackground := FBackground;
    Self.FBorder := FBorder;
    Self.FLines := FLines;
    Self.FMovingEdge := FMovingEdge;
    Self.FSelection := FSelection;
  end
  else
    inherited Assign(ASource);
end;

end.
