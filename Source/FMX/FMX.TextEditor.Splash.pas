unit FMX.TextEditor.Splash;

interface

implementation

uses
  Winapi.Windows, ToolsAPI;

const
  TEXT_EDITOR_VERSION = '1.0.0';

procedure Init;
begin
  { NOTE: This unit is not part of FMX.TextEditor.Delphi.Designtime - the VCL designtime package already adds the
    IDE splash entry, and both packages installed together would show it twice. Kept only in case an FMX-only
    installation ever wants its own entry. }
  SplashScreenServices.AddPluginBitmap('Text Editor ' + TEXT_EDITOR_VERSION,
    LoadBitmap(FindResourceHInstance(HInstance), 'TTEXTEDITOR'), False, '');
end;

initialization

  Init;

end.
