unit TextEditor.RegisterProperty;

interface

procedure Register;

implementation

uses
  DesignIntf, DesignEditors, VCLEditors, StrEdit, System.Classes, System.SysUtils, Vcl.Controls, TextEditor.MacroRecorder;

{ Register }

procedure Register;
begin
  RegisterPropertyEditor(TypeInfo(Char), nil, '', TCharProperty);
  RegisterPropertyEditor(TypeInfo(TStrings), nil, '', TStringListProperty);
  RegisterPropertyEditor(TypeInfo(TShortCut), TTextEditorMacroRecorder, '', TShortCutProperty);
end;

end.
