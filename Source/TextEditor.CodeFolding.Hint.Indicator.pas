unit TextEditor.CodeFolding.Hint.Indicator;

interface

uses
  System.Classes, Vcl.Controls, TextEditor.CodeFolding.Hint.Indicator.Colors, TextEditor.Glyph, TextEditor.Types;

const
  TEXTEDITOR_CODE_FOLDING_HINT_INDICATOR_DEFAULT_OPTIONS = [hioShowBorder, hioShowMark];

type
  TTextEditorCodeFoldingHintIndicator = class(TPersistent)
  strict private
    FColors: TTextEditorCodeFoldingHintIndicatorColors;
    FGlyph: TTextEditorGlyph;
    FMarkStyle: TTextEditorCodeFoldingHintIndicatorMarkStyle;
    FOptions: TTextEditorCodeFoldingHintIndicatorOptions;
    FPadding: TTextEditorCodeFoldingHintIndicatorPadding;
    FVisible: Boolean;
    FWidth: Integer;
    procedure SetGlyph(const AValue: TTextEditorGlyph);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
  published
    property Colors: TTextEditorCodeFoldingHintIndicatorColors read FColors write FColors;
    property Glyph: TTextEditorGlyph read FGlyph write SetGlyph;
    property MarkStyle: TTextEditorCodeFoldingHintIndicatorMarkStyle read FMarkStyle write FMarkStyle default imsThreeDots;
    property Options: TTextEditorCodeFoldingHintIndicatorOptions read FOptions write FOptions default TEXTEDITOR_CODE_FOLDING_HINT_INDICATOR_DEFAULT_OPTIONS;
    property Padding: TTextEditorCodeFoldingHintIndicatorPadding read FPadding write FPadding;
    property Visible: Boolean read FVisible write FVisible default True;
    property Width: Integer read FWidth write FWidth default 26;
  end;

implementation

constructor TTextEditorCodeFoldingHintIndicator.Create;
begin
  inherited;

  FColors := TTextEditorCodeFoldingHintIndicatorColors.Create;
  FGlyph := TTextEditorGlyph.Create;
  FPadding := TTextEditorCodeFoldingHintIndicatorPadding.Create(nil);
  FGlyph.Visible := False;
  FMarkStyle := imsThreeDots;
  FVisible := True;
  FOptions := TEXTEDITOR_CODE_FOLDING_HINT_INDICATOR_DEFAULT_OPTIONS;
  FWidth := 26;
end;

destructor TTextEditorCodeFoldingHintIndicator.Destroy;
begin
  FColors.Free;
  FGlyph.Free;
  FPadding.Free;

  inherited;
end;

procedure TTextEditorCodeFoldingHintIndicator.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCodeFoldingHintIndicator) then
  with ASource as TTextEditorCodeFoldingHintIndicator do
  begin
    Self.FVisible := FVisible;
    Self.FMarkStyle := FMarkStyle;
    Self.FWidth := FWidth;
    Self.FColors.Assign(FColors);
    Self.FGlyph.Assign(FGlyph);
    Self.FPadding.Assign(FPadding);
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorCodeFoldingHintIndicator.SetGlyph(const AValue: TTextEditorGlyph);
begin
  FGlyph.Assign(AValue);
end;

end.
