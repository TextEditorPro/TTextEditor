unit TextEditor.Search.Map.Colors;

interface

uses
  System.Classes, System.UITypes, TextEditor.Consts, TextEditor.Types;

type
  TTextEditorSearchMapColors = class(TPersistent)
  strict private
    FActiveLine: TColor;
    FBackground: TColor;
    FForeground: TColor;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property ActiveLine: TColor read FActiveLine write FActiveLine default TDefaultColors.SearchMapActiveLine;
    property Background: TColor read FBackground write FBackground default TDefaultColors.LeftMarginBackground;
    property Foreground: TColor read FForeground write FForeground default TDefaultColors.SearchHighlighter;
  end;

implementation

constructor TTextEditorSearchMapColors.Create;
begin
  inherited;

  FActiveLine := TDefaultColors.SearchMapActiveLine;
  FBackground := TDefaultColors.LeftMarginBackground;
  FForeground := TDefaultColors.SearchHighlighter;
end;

procedure TTextEditorSearchMapColors.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorSearchMapColors) then
  with ASource as TTextEditorSearchMapColors do
  begin
    Self.FBackground := FBackground;
    Self.FForeground := FForeground;
    Self.FActiveLine := FActiveLine;
  end
  else
    inherited Assign(ASource);
end;

end.
