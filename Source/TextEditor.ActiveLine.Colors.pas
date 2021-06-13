unit TextEditor.ActiveLine.Colors;

interface

uses
  System.Classes, Vcl.Graphics, TextEditor.Consts;

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
    property Background: TColor read FBackground write FBackground default clActiveLineBackground;
    property BackgroundUnfocused: TColor read FBackgroundUnfocused write FBackgroundUnfocused default clActiveLineBackgroundUnfocused;
    property Foreground: TColor read FForeground write FForeground default clActiveLineForeground;
    property ForegroundUnfocused: TColor read FForegroundUnfocused write FForegroundUnfocused default clActiveLineForegroundUnfocused;
  end;

implementation

constructor TTextEditorActiveLineColors.Create;
begin
  inherited;

  FBackground := clActiveLineBackground;
  FBackgroundUnfocused := clActiveLineBackgroundUnfocused;
  FForeground := clActiveLineForeground;
  FForegroundUnfocused := clActiveLineForegroundUnfocused;
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
