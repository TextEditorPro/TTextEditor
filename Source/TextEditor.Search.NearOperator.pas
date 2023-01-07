unit TextEditor.Search.NearOperator;

interface

uses
  System.Classes, System.UITypes, TextEditor.Types;

type
  TTextEditorSearchNearOperator = class(TPersistent)
  strict private
    FEnabled: Boolean;
    FMaxDistance: Integer;
    FMinDistance: Integer;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Enabled: Boolean read FEnabled write FEnabled default False;
    property MaxDistance: Integer read FMaxDistance write FMaxDistance default 3;
    property MinDistance: Integer read FMinDistance write FMinDistance default 1;
  end;

implementation

constructor TTextEditorSearchNearOperator.Create;
begin
  inherited;

  FEnabled := False;
  FMaxDistance := 3;
  FMinDistance := 1;
end;

procedure TTextEditorSearchNearOperator.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorSearchNearOperator) then
  with ASource as TTextEditorSearchNearOperator do
  begin
    Self.FEnabled := FEnabled;
    Self.FMaxDistance := FMaxDistance;
    Self.FMinDistance := FMinDistance;
  end
  else
    inherited Assign(ASource);
end;

end.
