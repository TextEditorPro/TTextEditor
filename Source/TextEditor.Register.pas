unit TextEditor.Register;

interface

uses
  System.Classes, TextEditor, TextEditor.Compare.ScrollBar, TextEditor.MacroRecorder, TextEditor.Print,
  TextEditor.Print.Preview, TextEditor.SpellCheck;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('TextEditor', [TTextEditor, TDBTextEditor, TTextEditorPrint, TTextEditorPrintPreview,
    TTextEditorMacroRecorder, TTextEditorSpellCheck, TTextEditorCompareScrollBar]);
end;

end.
