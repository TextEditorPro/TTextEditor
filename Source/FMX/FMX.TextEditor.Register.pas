unit FMX.TextEditor.Register;

interface

uses
  System.Classes, FMX.TextEditor, FMX.TextEditor.DB, FMX.TextEditor.MacroRecorder, FMX.TextEditor.Print, FMX.TextEditor.Print.Preview,
  FMX.TextEditor.Compare.ScrollBar;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('TextEditor', [TTextEditor, TDBTextEditor, TTextEditorMacroRecorder, TTextEditorPrint, TTextEditorPrintPreview,
    TTextEditorCompareScrollBar]);
end;

end.
