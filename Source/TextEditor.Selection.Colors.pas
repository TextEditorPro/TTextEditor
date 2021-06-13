unit TextEditor.Selection.Colors;

interface

uses
  System.Classes, Vcl.Graphics, TextEditor.Consts;

type
  TTextEditorSelectionColors = class(TPersistent)
  strict private
    FBackground: TColor;
    FForeground: TColor;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Background: TColor read FBackground write FBackground default clSelectionColor;
    property Foreground: TColor read FForeground write FForeground default clHighLightText;
  end;

implementation

constructor TTextEditorSelectionColors.Create;
begin
  inherited;

  FBackground := clSelectionColor;
  FForeground := clHighLightText;
end;

procedure TTextEditorSelectionColors.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorSelectionColors) then
  with ASource as TTextEditorSelectionColors do
  begin
    Self.FBackground := FBackground;
    Self.FForeground := FForeground;
  end
  else
    inherited Assign(ASource);
end;

end.
