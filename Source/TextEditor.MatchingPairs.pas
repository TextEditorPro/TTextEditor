unit TextEditor.MatchingPairs;

interface

uses
  System.Classes, TextEditor.Types;

type
  TTextEditorMatchingPairs = class(TPersistent)
  strict private
    FActive: Boolean;
    FAutoComplete: Boolean;
    FOptions: TTextEditorMatchingPairOptions;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TTextEditorMatchingPairOption; const AEnabled: Boolean);
  published
    property Active: Boolean read FActive write FActive default True;
    property AutoComplete: Boolean read FAutoComplete write FAutoComplete default False;
    property Options: TTextEditorMatchingPairOptions read FOptions write FOptions default [mpoUseMatchedColor];
  end;

implementation

constructor TTextEditorMatchingPairs.Create;
begin
  inherited;

  FAutoComplete := False;
  FActive := True;
  FOptions := [mpoUseMatchedColor];
end;

procedure TTextEditorMatchingPairs.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorMatchingPairs) then
  with ASource as TTextEditorMatchingPairs do
  begin
    Self.FActive := FActive;
    Self.FAutoComplete := FAutoComplete;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorMatchingPairs.SetOption(const AOption: TTextEditorMatchingPairOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

end.
