program TTextEditorDemo;

uses
  Vcl.Forms,
  TTextEditorDemo.Form.Main in 'TTextEditorDemo.Form.Main.pas' {MainForm},
  MyControl.ObjectInspector in 'MyControl.ObjectInspector.pas',
  Vcl.Themes,
  Vcl.Styles,
  TTextEditorDemo.Frame.TextEditor in 'TTextEditorDemo.Frame.TextEditor.pas' {FrameTextEditor: TFrame},
  TTextEditorDemo.Frame.TextCompare in 'TTextEditorDemo.Frame.TextCompare.pas' {FrameTextCompare: TFrame},
  TTextEditorDemo.Frame.PrintPreview in 'TTextEditorDemo.Frame.PrintPreview.pas' {FramePrintPreview: TFrame};

{$R *.res}

begin
  ToggleDarkStyle(True);

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.