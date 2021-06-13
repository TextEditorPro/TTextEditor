program TTextEditorDemo;

uses
  Vcl.Forms,
  TTextEditorDemo.Form.Main in 'TTextEditorDemo.Form.Main.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.