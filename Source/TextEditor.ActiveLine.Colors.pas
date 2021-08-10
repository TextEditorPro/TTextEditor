unit TextEditor.ActiveLine.Colors;

interface

uses
  System.Classes, System.UITypes, TextEditor.Consts;

type
  TTextEditorActiveLineColors = class(TPersistent)
  strict private
    FBackground: TColor;
    FBackgroundUnfocused: TColor;
    FForeground: TColor;
    FForegroundUnfocused: TColor;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Background: TColor read FBackground write FBackground default TDefaultColors.ActiveLineBackground;
    property BackgroundUnfocused: TColor read FBackgroundUnfocused write FBackgroundUnfocused default TDefaultColors.ActiveLineBackgroundUnfocused;
    property Foreground: TColor read FForeground write FForeground default TDefaultColors.ActiveLineForeground;
    property ForegroundUnfocused: TColor read FForegroundUnfocused write FForegroundUnfocused default TDefaultColors.ActiveLineForegroundUnfocused;
  end;

implementation

constructor TTextEditorActiveLineColors.Create;
begin
  inherited;

  FBackground := TDefaultColors.ActiveLineBackground;
  FBackgroundUnfocused := TDefaultColors.ActiveLineBackgroundUnfocused;
  FForeground := TDefaultColors.ActiveLineForeground;
  FForegroundUnfocused := TDefaultColors.ActiveLineForegroundUnfocused;
end;

procedure TTextEditorActiveLineColors.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorActiveLineColors) then
  with ASource as TTextEditorActiveLineColors do
  begin
    Self.FBackground := FBackground;
    Self.FBackgroundUnfocused := FBackgroundUnfocused;
    Self.FForeground := FForeground;
    Self.FForegroundUnfocused := FForegroundUnfocused;
  end
  else
    inherited Assign(ASource);
end;

end.
