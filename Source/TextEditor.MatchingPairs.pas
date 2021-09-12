unit TextEditor.MatchingPairs;

interface

uses
  System.Classes, TextEditor.MatchingPair.Colors, TextEditor.Types;

type
  TTextEditorMatchingPairs = class(TPersistent)
  strict private
    FActive: Boolean;
    FAutoComplete: Boolean;
    FColors: TTextEditorMatchingPairColors;
    FOptions: TTextEditorMatchingPairOptions;
    procedure SetColors(const AValue: TTextEditorMatchingPairColors);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TTextEditorMatchingPairOption; const AEnabled: Boolean);
  published
    property Active: Boolean read FActive write FActive default True;
    property AutoComplete: Boolean read FAutoComplete write FAutoComplete default False;
    property Colors: TTextEditorMatchingPairColors read FColors write SetColors;
    property Options: TTextEditorMatchingPairOptions read FOptions write FOptions default [mpoUseMatchedColor];
  end;

implementation

constructor TTextEditorMatchingPairs.Create;
begin
  inherited;

  FAutoComplete := False;
  FColors := TTextEditorMatchingPairColors.Create;
  FActive := True;
  FOptions := [mpoUseMatchedColor];
end;

destructor TTextEditorMatchingPairs.Destroy;
begin
  FColors.Free;

  inherited;
end;

procedure TTextEditorMatchingPairs.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorMatchingPairs) then
  with ASource as TTextEditorMatchingPairs do
  begin
    Self.FActive := FActive;
    Self.FAutoComplete := FAutoComplete;
    Self.FColors.Assign(FColors);
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

procedure TTextEditorMatchingPairs.SetColors(const AValue: TTextEditorMatchingPairColors);
begin
  FColors.Assign(AValue);
end;

end.
