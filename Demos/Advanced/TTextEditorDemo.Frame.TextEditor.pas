unit TTextEditorDemo.Frame.TextEditor;

interface

uses
  System.Classes, System.SysUtils, Vcl.Controls, Vcl.Forms, TextEditor;

type
  TFrameTextEditor = class(TFrame)
    TextEditor: TTextEditor;
    procedure TextEditorCreateHighlighterStream(const ASender: TObject; const AName: string; var AStream: TStream);
  end;

implementation

{$R *.dfm}

procedure TFrameTextEditor.TextEditorCreateHighlighterStream(const ASender: TObject; const AName: string; var AStream: TStream);
begin
  if not AName.IsEmpty then
    AStream := TFileStream.Create('..\..\Highlighters\' + AName + '.json', fmOpenRead);
end;

end.
