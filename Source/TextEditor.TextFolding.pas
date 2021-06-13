unit TextEditor.TextFolding;

interface

uses
  System.Classes;

type
  TTextEditorTextFolding = class(TPersistent)
  strict private
    FActive: Boolean;
    FOutlinedBySpacesAndTabs: Boolean;
    FOutlineCharacter: Char;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Active: Boolean read FActive write FActive default False;
    property OutlinedBySpacesAndTabs: Boolean read FOutlinedBySpacesAndTabs write FOutlinedBySpacesAndTabs default True;
    property OutlineCharacter: Char read FOutlineCharacter write FOutlineCharacter default '.';
  end;

implementation

constructor TTextEditorTextFolding.Create;
begin
  inherited;

  FActive := False;
  FOutlinedBySpacesAndTabs := True;
  FOutlineCharacter := '.';
end;

procedure TTextEditorTextFolding.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorTextFolding) then
  with ASource as TTextEditorTextFolding do
  begin
    Self.FActive := FActive;
    Self.FOutlinedBySpacesAndTabs := FOutlinedBySpacesAndTabs;
    Self.FOutlineCharacter := FOutlineCharacter;
  end
  else
    inherited Assign(ASource);
end;

end.
