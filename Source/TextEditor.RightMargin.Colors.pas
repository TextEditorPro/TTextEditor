unit TextEditor.RightMargin.Colors;

interface

uses
  System.Classes, System.UITypes;

type
  TTextEditorRightMarginColors = class(TPersistent)
  strict private
    FMargin: TColor;
    FMovingEdge: TColor;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Margin: TColor read FMargin write FMargin default TColors.Silver;
    property MovingEdge: TColor read FMovingEdge write FMovingEdge default TColors.Silver;
  end;

implementation

constructor TTextEditorRightMarginColors.Create;
begin
  inherited;

  FMargin := TColors.Silver;
  FMovingEdge := TColors.Silver;
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
