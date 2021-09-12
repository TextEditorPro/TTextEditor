unit TextEditor.Selection.Colors;

interface

uses
  System.Classes, System.UITypes, TextEditor.Consts;

type
  TTextEditorSelectionColors = class(TPersistent)
  strict private
    FBackground: TColor;
    FForeground: TColor;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Background: TColor read FBackground write FBackground default TDefaultColors.SelectionColor;
    property Foreground: TColor read FForeground write FForeground default TColors.SysHighlightText;
  end;

implementation

constructor TTextEditorSelectionColors.Create;
begin
  inherited;

  FBackground := TDefaultColors.SelectionColor;
  FForeground := TColors.SysHighlightText;
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
