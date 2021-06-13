unit TextEditor.MatchingPair.Colors;

interface

uses
  System.Classes, Vcl.Graphics, TextEditor.Consts;

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
    property Matched: TColor read FMatched write FMatched default clAqua;
    property Underline: TColor read FUnderline write FUnderline default clMatchingPairUnderline;
    property Unmatched: TColor read FUnmatched write FUnmatched default clYellow;
  end;

implementation

constructor TTextEditorMatchingPairColors.Create;
begin
  inherited;

  FMatched := clAqua;
  FUnderline := clMatchingPairUnderline;
  FUnmatched := clYellow;
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
