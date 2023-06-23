unit TextEditor.RegisterProperty;

interface

uses
  System.SysUtils, DesignEditors, DesignIntf;

type
  TFileNameProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

procedure Register;

implementation

uses
  System.Classes, Vcl.Dialogs, Vcl.Forms, StrEdit, TextEditor.Language, TextEditor.MacroRecorder, VCLEditors;

{ Register }

procedure Register;
begin
  RegisterPropertyEditor(TypeInfo(Char), nil, '', TCharProperty);
  RegisterPropertyEditor(TypeInfo(TStrings), nil, '', TStringListProperty);
  RegisterPropertyEditor(TypeInfo(TShortCut), TTextEditorMacroRecorder, '', TShortCutProperty);
  RegisterPropertyEditor(TypeInfo(TFileName), nil, '', TFileNameProperty);
end;

{ TFileNameProperty }

function TFileNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog]
end;

procedure TFileNameProperty.Edit;
begin
  if GetName = 'ThemeLoad' then
  with TOpenDialog.Create(Application) do
  try
    DefaultExt := '.json';
    Title := STextEditorThemeLoadFromFile;
    Filename := '';
    Filter := 'JSON Files (*.json)|*.json';
    HelpContext := 0;
    Options := Options + [ofShowHelp, ofPathMustExist, ofFileMustExist];
    if Execute then
      SetValue(Filename);
  finally
    Free;
  end;

  if GetName = 'ThemeSave' then
  with TSaveDialog.Create(Application) do
  try
    DefaultExt := '.json';
    Title := STextEditorThemeSaveToFile;
    Filename := 'Theme.json';
    Filter := 'JSON Files (*.json)|*.json';
    HelpContext := 0;
    if Execute then
      SetValue(Filename);
  finally
    Free;
  end;
end;

end.
