unit TextEditor.CodeFolding.Colors;

interface

uses
  System.Classes, Vcl.Graphics, TextEditor.Consts, TextEditor.Types;

type
  TTextEditorCodeFoldingColors = class(TPersistent)
  strict private
    FActiveLineBackground: TColor;
    FActiveLineBackgroundUnfocused: TColor;
    FBackground: TColor;
    FCollapsedLine: TColor;
    FFoldingLine: TColor;
    FFoldingLineHighlight: TColor;
    FIndent: TColor;
    FIndentHighlight: TColor;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property ActiveLineBackground: TColor read FActiveLineBackground write FActiveLineBackground default TDefaultColors.ActiveLineBackground;
    property ActiveLineBackgroundUnfocused: TColor read FActiveLineBackgroundUnfocused write FActiveLineBackgroundUnfocused default TDefaultColors.ActiveLineBackgroundUnfocused;
    property CollapsedLine: TColor read FCollapsedLine write FCollapsedLine default TDefaultColors.LeftMarginFontForeground;
    property Background: TColor read FBackground write FBackground default TDefaultColors.LeftMarginBackground;
    property FoldingLine: TColor read FFoldingLine write FFoldingLine default TDefaultColors.LeftMarginFontForeground;
    property FoldingLineHighlight: TColor read FFoldingLineHighlight write FFoldingLineHighlight default TDefaultColors.LeftMarginFontForeground;
    property Indent: TColor read FIndent write FIndent default TDefaultColors.Indent;
    property IndentHighlight: TColor read FIndentHighlight write FIndentHighlight default TDefaultColors.IndentHighlight;
  end;

implementation

constructor TTextEditorCodeFoldingColors.Create;
begin
  inherited;

  FActiveLineBackground := TDefaultColors.ActiveLineBackground;
  FActiveLineBackgroundUnfocused := TDefaultColors.ActiveLineBackgroundUnfocused;
  FCollapsedLine := TDefaultColors.LeftMarginFontForeground;
  FBackground := TDefaultColors.LeftMarginBackground;
  FFoldingLine := TDefaultColors.LeftMarginFontForeground;
  FFoldingLineHighlight := TDefaultColors.LeftMarginFontForeground;
  FIndent := TDefaultColors.Indent;
  FIndentHighlight := TDefaultColors.IndentHighlight;
end;

procedure TTextEditorCodeFoldingColors.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCodeFoldingColors) then
  with ASource as TTextEditorCodeFoldingColors do
  begin
    Self.FActiveLineBackground := FActiveLineBackground;
    Self.FActiveLineBackgroundUnfocused := FActiveLineBackgroundUnfocused;
    Self.FCollapsedLine := FCollapsedLine;
    Self.FBackground := FBackground;
    Self.FFoldingLine := FFoldingLine;
    Self.FFoldingLineHighlight := FFoldingLineHighlight;
    Self.FIndentHighlight := FIndentHighlight;
  end
  else
    inherited Assign(ASource);
end;

end.
