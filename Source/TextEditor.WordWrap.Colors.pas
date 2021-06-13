unit TextEditor.WordWrap.Colors;

interface

uses
  System.Classes, Vcl.Graphics, TextEditor.Consts;

type
  TTextEditorWordWrapColors = class(TPersistent)
  strict private
    FArrow: TColor;
    FLines: TColor;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Arrow: TColor read FArrow write FArrow default clWordWrapIndicatorArrow;
    property Lines: TColor read FLines write FLines default clWordWrapIndicatorLines;
  end;

implementation

constructor TTextEditorWordWrapColors.Create;
begin
  inherited;

  FArrow := clWordWrapIndicatorArrow;
  FLines := clWordWrapIndicatorLines;
end;

procedure TTextEditorWordWrapColors.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorWordWrapColors) then
  with ASource as TTextEditorWordWrapColors do
  begin
    Self.FArrow := FArrow;
    Self.FLines := FLines;
  end
  else
    inherited Assign(ASource);
end;

end.
