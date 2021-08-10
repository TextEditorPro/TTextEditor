unit TextEditor.MatchingPair.Colors;

interface

uses
  System.Classes, System.UITypes, TextEditor.Consts;

type
  TTextEditorMatchingPairColors = class(TPersistent)
  strict private
    FMatched: TColor;
    FUnderline: TColor;
    FUnmatched: TColor;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Matched: TColor read FMatched write FMatched default TColors.Aqua;
    property Underline: TColor read FUnderline write FUnderline default TDefaultColors.MatchingPairUnderline;
    property Unmatched: TColor read FUnmatched write FUnmatched default TColors.Yellow;
  end;

implementation

constructor TTextEditorMatchingPairColors.Create;
begin
  inherited;

  FMatched := TColors.Aqua;
  FUnderline := TDefaultColors.MatchingPairUnderline;
  FUnmatched := TColors.Yellow;
end;

procedure TTextEditorMatchingPairColors.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorMatchingPairColors) then
  with ASource as TTextEditorMatchingPairColors do
  begin
    Self.FMatched := FMatched;
    Self.FUnmatched := FUnmatched;
  end
  else
    inherited Assign(ASource);
end;

end.
