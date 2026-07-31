program TTextEditorDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  MyControl.ObjectInspector in 'MyControl.ObjectInspector.pas',
  TTextEditorDemo.Form.Main in 'TTextEditorDemo.Form.Main.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
