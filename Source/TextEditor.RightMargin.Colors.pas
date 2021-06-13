unit TextEditor.RightMargin.Colors;

interface

uses
  System.Classes, Vcl.Graphics;

type
  TTextEditorRightMarginColors = class(TPersistent)
  strict private
    FMargin: TColor;
    FMovingEdge: TColor;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Margin: TColor read FMargin write FMargin default clSilver;
    property MovingEdge: TColor read FMovingEdge write FMovingEdge default clSilver;
  end;

implementation

constructor TTextEditorRightMarginColors.Create;
begin
  inherited;

  FMargin := clSilver;
  FMovingEdge := clSilver;
end;

procedure TTextEditorRightMarginColors.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorRightMarginColors) then
  with ASource as TTextEditorRightMarginColors do
  begin
    Self.FMargin := FMargin;
    Self.FMovingEdge := FMovingEdge;
  end
  else
    inherited Assign(ASource);
end;

end.
