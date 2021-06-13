unit TextEditor.Search.Highlighter.Colors;

interface

uses
  System.Classes, Vcl.Graphics, TextEditor.Consts, TextEditor.Types;

type
  TTextEditorSearchColors = class(TPersistent)
  strict private
    FBackground: TColor;
    FBorder: TColor;
    FForeground: TColor;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Background: TColor read FBackground write FBackground default clSearchHighlighter;
    property Border: TColor read FBorder write FBorder default clNone;
    property Foreground: TColor read FForeground write FForeground default clWindowText;
  end;

implementation

constructor TTextEditorSearchColors.Create;
begin
  inherited;

  FBackground := clSearchHighlighter;
  FBorder := clNone;
  FForeground := clWindowText;
end;

procedure TTextEditorSearchColors.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorSearchColors) then
  with ASource as TTextEditorSearchColors do
  begin
    Self.FBackground := FBackground;
    Self.FBorder := FBorder;
    Self.FForeground := FForeground;
  end
  else
    inherited Assign(ASource);
end;

end.
