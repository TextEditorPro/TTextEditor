unit TextEditor.CodeFolding.Hint.Indicator.Colors;

interface

uses
  System.Classes, Vcl.Graphics, TextEditor.Consts;

type
  TTextEditorCodeFoldingHintIndicatorColors = class(TPersistent)
  strict private
    FBackground: TColor;
    FBorder: TColor;
    FMark: TColor;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Background: TColor read FBackground write FBackground default TDefaultColors.LeftMarginBackground;
    property Border: TColor read FBorder write FBorder default TDefaultColors.LeftMarginFontForeground;
    property Mark: TColor read FMark write FMark default TDefaultColors.LeftMarginFontForeground;
  end;

implementation

constructor TTextEditorCodeFoldingHintIndicatorColors.Create;
begin
  inherited;

  FBackground := TDefaultColors.LeftMarginBackground;
  FBorder := TDefaultColors.LeftMarginFontForeground;
  FMark := TDefaultColors.LeftMarginFontForeground;
end;

procedure TTextEditorCodeFoldingHintIndicatorColors.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCodeFoldingHintIndicatorColors) then
  with ASource as TTextEditorCodeFoldingHintIndicatorColors do
  begin
    Self.FBackground := FBackground;
    Self.FBorder := FBorder;
    Self.FMark := FMark;
  end
  else
    inherited Assign(ASource);
end;

end.
