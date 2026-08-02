unit FMX.TextEditor.MatchingPairs;

interface

uses
  System.Classes, FMX.TextEditor.Types;

type
  TTextEditorMatchingPairs = class(TPersistent)
  strict private
    FActive: Boolean;
    FAutoComplete: Boolean;
    FOnChange: TNotifyEvent;
    FOptions: TTextEditorMatchingPairOptions;
    procedure DoChange;
    procedure SetActive(const AValue: Boolean);
    procedure SetOptions(const AValue: TTextEditorMatchingPairOptions);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TTextEditorMatchingPairOption; const AEnabled: Boolean);
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Active: Boolean read FActive write SetActive default True;
    property AutoComplete: Boolean read FAutoComplete write FAutoComplete default False;
    property Options: TTextEditorMatchingPairOptions read FOptions write SetOptions default [mpoUseMatchedColor];
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
    Self.FOptions := FOptions;

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorMatchingPairs.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorMatchingPairs.SetActive(const AValue: Boolean);
begin
  if FActive <> AValue then
  begin
    FActive := AValue;

    DoChange;
  end;
end;

procedure TTextEditorMatchingPairs.SetOption(const AOption: TTextEditorMatchingPairOption; const AEnabled: Boolean);
var
  LOptions: TTextEditorMatchingPairOptions;
begin
  LOptions := FOptions;

  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);

  if FOptions <> LOptions then
    DoChange;
end;

procedure TTextEditorMatchingPairs.SetOptions(const AValue: TTextEditorMatchingPairOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;

    DoChange;
  end;
end;

end.
