program TTextEditorDemo;

uses
  Vcl.Forms,
  Vcl.Styles,
  Vcl.Themes,
  MyControl.ObjectInspector in 'MyControl.ObjectInspector.pas',
  TTextEditorDemo.Form.Main in 'TTextEditorDemo.Form.Main.pas' {MainForm},
  TTextEditorDemo.Frame.PrintPreview in 'TTextEditorDemo.Frame.PrintPreview.pas' {FramePrintPreview: TFrame},
  TTextEditorDemo.Frame.TextCompare in 'TTextEditorDemo.Frame.TextCompare.pas' {FrameTextCompare: TFrame},
  TTextEditorDemo.Frame.TextEditor in 'TTextEditorDemo.Frame.TextEditor.pas' {FrameTextEditor: TFrame};

{$R *.res}
{$R DarkStyle.res}

begin
  ToggleDarkStyle(True);

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.