unit TextEditor.CodeFolding.GuideLines;

interface

uses
  System.Classes, TextEditor.Types;

type
  TTextEditorCodeFoldingGuideLines = class(TPersistent)
  strict private
    FOptions: TTextEditorCodeFoldingGuideLineOptions;
    FPadding: Integer;
    FStyle: TTextEditorCodeFoldingGuideLineStyle;
    FVisible: Boolean;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TTextEditorCodeFoldingGuideLineOption; const AEnabled: Boolean);
  published
    property Options: TTextEditorCodeFoldingGuideLineOptions read FOptions write FOptions default TTextEditorDefaultOptions.CodeFoldingGuideLines;
    property Padding: Integer read FPadding write FPadding default 3;
    property Style: TTextEditorCodeFoldingGuideLineStyle read FStyle write FStyle default lsDash;
    property Visible: Boolean read FVisible write FVisible default True;
  end;

implementation

constructor TTextEditorCodeFoldingGuideLines.Create;
begin
  inherited;

  FOptions := TTextEditorDefaultOptions.CodeFoldingGuideLines;
  FPadding := 3;
  FStyle := lsDash;
  FVisible := True;
end;

procedure TTextEditorCodeFoldingGuideLines.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCodeFoldingGuideLines) then
  with ASource as TTextEditorCodeFoldingGuideLines do
  begin
    Self.FOptions := FOptions;
    Self.FPadding := FPadding;
    Self.FStyle := FStyle;
    Self.FVisible := FVisible;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorCodeFoldingGuideLines.SetOption(const AOption: TTextEditorCodeFoldingGuideLineOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

end.
