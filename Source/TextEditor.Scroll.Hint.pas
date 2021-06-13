unit TextEditor.Scroll.Hint;

interface

uses
  System.Classes, Vcl.Graphics, TextEditor.Types;

type
  TTextEditorScrollHint = class(TPersistent)
  strict private
    FFormat: TTextEditorScrollHintFormat;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Format: TTextEditorScrollHintFormat read FFormat write FFormat default shfTopLineOnly;
  end;

implementation

constructor TTextEditorScrollHint.Create;
begin
  inherited;

  FFormat := shfTopLineOnly;
end;

procedure TTextEditorScrollHint.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorScrollHint) then
  with ASource as TTextEditorScrollHint do
    Self.FFormat := FFormat
  else
    inherited Assign(ASource);
end;

end.
