unit TextEditor.Undo;

interface

uses
  System.Classes, TextEditor.Types;

type
  TTextEditorUndo = class(TPersistent)
  strict private
    FOptions: TTextEditorUndoOptions;
    procedure SetOptions(const AValue: TTextEditorUndoOptions);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TTextEditorUndoOption; const AEnabled: Boolean);
  published
    property Options: TTextEditorUndoOptions read FOptions write SetOptions default [uoGroupUndo];
  end;

implementation

constructor TTextEditorUndo.Create;
begin
  inherited;

  FOptions := [uoGroupUndo];
end;

procedure TTextEditorUndo.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorUndo) then
  with ASource as TTextEditorUndo do
    Self.FOptions := FOptions
  else
    inherited Assign(ASource);
end;

procedure TTextEditorUndo.SetOption(const AOption: TTextEditorUndoOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

procedure TTextEditorUndo.SetOptions(const AValue: TTextEditorUndoOptions);
begin
  if FOptions <> AValue then
    FOptions := AValue;
end;

end.