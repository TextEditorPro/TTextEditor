unit FMX.TextEditor.PartialLoad;

interface

uses
  System.Classes, System.UITypes, FMX.TextEditor.Types;

type
  TTextEditorPartialLoad = class(TPersistent)
  strict private
    FEnabled: Boolean;
    FFrom: TTextEditorPartialLoadFrom;
    FRows: Integer;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Enabled: Boolean read FEnabled write FEnabled default False;
    property From: TTextEditorPartialLoadFrom read FFrom write FFrom default plfTail;
    property Rows: Integer read FRows write FRows default 200;
  end;

implementation

constructor TTextEditorPartialLoad.Create;
begin
  inherited;

  FEnabled := False;
  FFrom := plfTail;
  FRows := 100;
end;

procedure TTextEditorPartialLoad.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorPartialLoad) then
  with ASource as TTextEditorPartialLoad do
  begin
    Self.FEnabled := FEnabled;
    Self.FFrom := FFrom;
    Self.FRows := FRows;
  end
  else
    inherited Assign(ASource);
end;

end.
