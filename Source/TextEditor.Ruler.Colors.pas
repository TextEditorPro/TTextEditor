unit TextEditor.Ruler.Colors;

interface

uses
  System.Classes, Vcl.Graphics, TextEditor.Consts;

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
    property Background: TColor read FBackground write FBackground default clLeftMarginBackground;
    property Border: TColor read FBorder write FBorder default clLeftMarginFontForeground;
    property Lines: TColor read FLines write FLines default clLeftMarginFontForeground;
    property MovingEdge: TColor read FMovingEdge write FMovingEdge default clSilver;
    property Selection: TColor read FSelection write FSelection default clBtnFace;
  end;

implementation

constructor TTextEditorRulerColors.Create;
begin
  inherited;

  FBackground := clLeftMarginBackground;
  FBorder := clLeftMarginFontForeground;
  FLines := clLeftMarginFontForeground;
  FMovingEdge := clSilver;
  FSelection := clBtnFace;
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
