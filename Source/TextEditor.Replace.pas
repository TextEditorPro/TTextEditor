unit TextEditor.Replace;

interface

uses
  System.Classes, TextEditor.Types;

type
  TTextEditorReplace = class(TPersistent)
  strict private
    FAction: TTextEditorReplaceTextAction;
    FEngine: TTextEditorSearchEngine;
    FOnChange: TTextEditorReplaceChangeEvent;
    FOptions: TTextEditorReplaceOptions;
    procedure SetEngine(const AValue: TTextEditorSearchEngine);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TTextEditorReplaceOption; const AEnabled: Boolean);
  published
    property Action: TTextEditorReplaceTextAction read FAction write FAction default rtaReplace;
    property Engine: TTextEditorSearchEngine read FEngine write SetEngine default seNormal;
    property OnChange: TTextEditorReplaceChangeEvent read FOnChange write FOnChange;
    property Options: TTextEditorReplaceOptions read FOptions write FOptions default [roPrompt];
  end;

implementation

constructor TTextEditorReplace.Create;
begin
  inherited;

  FAction := rtaReplace;
  FEngine := seNormal;
  FOptions := [roPrompt];
end;

procedure TTextEditorReplace.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorReplace) then
  with ASource as TTextEditorReplace do
  begin
    Self.FEngine := Engine;
    Self.FOptions := Options;
    Self.FAction := Action;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorReplace.SetOption(const AOption: TTextEditorReplaceOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

procedure TTextEditorReplace.SetEngine(const AValue: TTextEditorSearchEngine);
begin
  if FEngine <> AValue then
  begin
    FEngine := AValue;
    if Assigned(FOnChange) then
      FOnChange(rcEngineUpdate);
  end;
end;

end.

