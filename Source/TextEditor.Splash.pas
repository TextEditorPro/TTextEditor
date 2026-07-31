unit TextEditor.Splash;

interface

implementation

uses
  Winapi.Windows, ToolsAPI;

const
  TEXT_EDITOR_VERSION = '1.0.0';

procedure Init;
begin
  SplashScreenServices.AddPluginBitmap('Text Editor ' + TEXT_EDITOR_VERSION,
    LoadBitmap(FindResourceHInstance(HInstance), 'TTEXTEDITOR'), False, '');
end;

initialization

  Init;

end.
