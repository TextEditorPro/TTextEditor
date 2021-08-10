unit TextEditor.WordWrap.Colors;

interface

uses
  System.Classes, System.UITypes, TextEditor.Consts;

type
  TTextEditorWordWrapColors = class(TPersistent)
  strict private
    FArrow: TColor;
    FLines: TColor;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Arrow: TColor read FArrow write FArrow default TDefaultColors.WordWrapIndicatorArrow;
    property Lines: TColor read FLines write FLines default TDefaultColors.WordWrapIndicatorLines;
  end;

implementation

constructor TTextEditorWordWrapColors.Create;
begin
  inherited;

  FArrow := TDefaultColors.WordWrapIndicatorArrow;
  FLines := TDefaultColors.WordWrapIndicatorLines;
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
