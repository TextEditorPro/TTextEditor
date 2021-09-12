unit TextEditor.Search.Highlighter.Colors;

interface

uses
  System.Classes, System.UITypes, TextEditor.Consts, TextEditor.Types;

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
    property Background: TColor read FBackground write FBackground default TDefaultColors.SearchHighlighter;
    property Border: TColor read FBorder write FBorder default TColors.SysNone;
    property Foreground: TColor read FForeground write FForeground default TColors.SysWindowText;
  end;

implementation

constructor TTextEditorSearchColors.Create;
begin
  inherited;

  FBackground := TDefaultColors.SearchHighlighter;
  FBorder := TColors.SysNone;
  FForeground := TColors.SysWindowText;
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
