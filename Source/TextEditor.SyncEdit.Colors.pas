unit TextEditor.SyncEdit.Colors;

interface

uses
  System.Classes, Vcl.Graphics, TextEditor.Consts;

type
  TTextEditorSyncEditColors = class(TPersistent)
  strict private
    FBackground: TColor;
    FEditBorder: TColor;
    FWordBorder: TColor;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Background: TColor read FBackground write FBackground default clSyncEditBackground;
    property EditBorder: TColor read FEditBorder write FEditBorder default clWindowText;
    property WordBorder: TColor read FWordBorder write FWordBorder default clHighlight;
  end;

implementation

constructor TTextEditorSyncEditColors.Create;
begin
  inherited;

  FBackground := clSyncEditBackground;
  FEditBorder := clWindowText;
  FWordBorder := clHighlight;
end;

procedure TTextEditorSyncEditColors.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorSyncEditColors) then
  with ASource as TTextEditorSyncEditColors do
  begin
    Self.FBackground := FBackground;
    Self.FEditBorder := FEditBorder;
    Self.FWordBorder := FWordBorder;
  end
  else
    inherited Assign(ASource);
end;

end.
