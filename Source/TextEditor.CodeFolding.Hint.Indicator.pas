unit TextEditor.CodeFolding.Hint.Indicator;

interface

uses
  System.Classes, Vcl.Controls, TextEditor.Glyph, TextEditor.Types;

type
  TTextEditorCodeFoldingHintIndicator = class(TPersistent)
  strict private
    FGlyph: TTextEditorGlyph;
    FMarkStyle: TTextEditorCodeFoldingHintIndicatorMarkStyle;
    FOptions: TTextEditorCodeFoldingHintIndicatorOptions;
    FPadding: TTextEditorCodeFoldingHintIndicatorPadding;
    FVisible: Boolean;
    FWidth: Integer;
    function IsGlyphStored: Boolean;
    procedure SetGlyph(const AValue: TTextEditorGlyph);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
  published
    property Glyph: TTextEditorGlyph read FGlyph write SetGlyph stored IsGlyphStored;
    property MarkStyle: TTextEditorCodeFoldingHintIndicatorMarkStyle read FMarkStyle write FMarkStyle default imsThreeDots;
    property Options: TTextEditorCodeFoldingHintIndicatorOptions read FOptions write FOptions default TTextEditorDefaultOptions.CodeFoldingHint;
    property Padding: TTextEditorCodeFoldingHintIndicatorPadding read FPadding write FPadding;
    property Visible: Boolean read FVisible write FVisible default True;
    property Width: Integer read FWidth write FWidth default 26;
  end;

implementation

uses
  System.UITypes;

constructor TTextEditorCodeFoldingHintIndicator.Create;
begin
  inherited;

  FGlyph := TTextEditorGlyph.Create;
  FPadding := TTextEditorCodeFoldingHintIndicatorPadding.Create(nil);
  FGlyph.Visible := False;
  FMarkStyle := imsThreeDots;
  FVisible := True;
  FOptions := TTextEditorDefaultOptions.CodeFoldingHint;
  FWidth := 26;
end;

destructor TTextEditorCodeFoldingHintIndicator.Destroy;
begin
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
    Self.FGlyph.Assign(FGlyph);
    Self.FPadding.Assign(FPadding);
  end
  else
    inherited Assign(ASource);
end;

function TTextEditorCodeFoldingHintIndicator.IsGlyphStored: Boolean;
begin
  Result := FGlyph.Visible or (FGlyph.Left <> 2) or (FGlyph.MaskColor <> TColors.SysNone);
end;

procedure TTextEditorCodeFoldingHintIndicator.SetGlyph(const AValue: TTextEditorGlyph);
begin
  FGlyph.Assign(AValue);
end;

end.
