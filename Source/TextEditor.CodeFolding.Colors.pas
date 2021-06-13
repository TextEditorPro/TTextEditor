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
    property ActiveLineBackground: TColor read FActiveLineBackground write FActiveLineBackground default clActiveLineBackground;
    property ActiveLineBackgroundUnfocused: TColor read FActiveLineBackgroundUnfocused write FActiveLineBackgroundUnfocused default clActiveLineBackgroundUnfocused;
    property CollapsedLine: TColor read FCollapsedLine write FCollapsedLine default clLeftMarginFontForeground;
    property Background: TColor read FBackground write FBackground default clLeftMarginBackground;
    property FoldingLine: TColor read FFoldingLine write FFoldingLine default clLeftMarginFontForeground;
    property FoldingLineHighlight: TColor read FFoldingLineHighlight write FFoldingLineHighlight default clLeftMarginFontForeground;
    property Indent: TColor read FIndent write FIndent default clIndent;
    property IndentHighlight: TColor read FIndentHighlight write FIndentHighlight default clIndentHighlight;
  end;

implementation

constructor TTextEditorCodeFoldingColors.Create;
begin
  inherited;

  FActiveLineBackground := clActiveLineBackground;
  FActiveLineBackgroundUnfocused := clActiveLineBackgroundUnfocused;
  FCollapsedLine := clLeftMarginFontForeground;
  FBackground := clLeftMarginBackground;
  FFoldingLine := clLeftMarginFontForeground;
  FFoldingLineHighlight := clLeftMarginFontForeground;
  FIndent := clIndent;
  FIndentHighlight := clIndentHighlight;
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
