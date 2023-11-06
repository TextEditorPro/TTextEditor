unit TextEditor.Register;

{$I TextEditor.Defines.inc}

interface

uses
  System.Classes, TextEditor, TextEditor.Compare.ScrollBar, TextEditor.MacroRecorder, TextEditor.Print,
  TextEditor.Print.Preview{$IFDEF TEXT_EDITOR_SPELL_CHECK}, TextEditor.SpellCheck{$ENDIF};

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('TextEditor', [TTextEditor, TDBTextEditor, TTextEditorPrint, TTextEditorPrintPreview,
    TTextEditorMacroRecorder{$IFDEF TEXT_EDITOR_SPELL_CHECK}, TTextEditorSpellCheck{$ENDIF}, TTextEditorCompareScrollBar]);
end;

end.
