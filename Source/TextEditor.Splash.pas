unit TextEditor.Splash;

interface

implementation

{$R TextEditor.res}

uses
  Winapi.Windows, System.Classes, TextEditor.Consts, ToolsAPI;

const
  TEXT_EDITOR_VERSION = '1.0.0';

procedure Init;
begin
  SplashScreenServices.AddPluginBitmap('Text Editor ' + TEXT_EDITOR_VERSION,
    LoadBitmap(FindResourceHInstance(HInstance), 'TTEXTEDITOR'), False, '');
end;

initialization

  Init;

finalization

end.
