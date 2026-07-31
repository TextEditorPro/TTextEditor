unit FMX.TextEditor.Splash;

interface

implementation

uses
  Winapi.Windows, ToolsAPI;

const
  TEXT_EDITOR_VERSION = '1.0.0';

procedure Init;
begin
  // TODO: The TTEXTEDITOR splash bitmap was removed along with FMX.TextEditor.res - draw or embed a new one when this unit is ported
  SplashScreenServices.AddPluginBitmap('Text Editor ' + TEXT_EDITOR_VERSION,
    LoadBitmap(FindResourceHInstance(HInstance), 'TTEXTEDITOR'), False, '');
end;

initialization

  Init;

end.
