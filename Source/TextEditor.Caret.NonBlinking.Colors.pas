unit TextEditor.Caret.NonBlinking.Colors;

interface

uses
  System.Classes, System.UITypes;

type
  TTextEditorCaretNonBlinkingColors = class(TPersistent)
  strict private
    FBackground: TColor;
    FForeground: TColor;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Background: TColor read FBackground write FBackground default TColors.Black;
    property Foreground: TColor read FForeground write FForeground default TColors.White;
  end;

implementation

constructor TTextEditorCaretNonBlinkingColors.Create;
begin
  inherited;

  FBackground := TColors.Black;
  FForeground := TColors.White;
end;

procedure TTextEditorCaretNonBlinkingColors.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCaretNonBlinkingColors) then
  with ASource as TTextEditorCaretNonBlinkingColors do
  begin
    Self.FBackground := FBackground;
    Self.FForeground := FForeground;
  end
  else
    inherited Assign(ASource);
end;

end.
