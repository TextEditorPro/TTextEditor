unit TTextEditorDemo.Form.Main;

interface

uses
  Winapi.Messages, Winapi.Windows, System.Classes, System.ImageList, System.SysUtils, System.Variants, Vcl.Controls,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms, Vcl.Graphics, Vcl.ImgList, Vcl.StdCtrls, TextEditor;

type
  TMainForm = class(TForm)
    Editor: TTextEditor;
    ListBoxHighlighters: TListBox;
    ListBoxThemes: TListBox;
    PanelLeft: TPanel;
    SplitterHorizontal: TSplitter;
    SplitterVertical: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure ListBoxThemesClick(Sender: TObject);
    procedure ListBoxHighlightersClick(Sender: TObject);
    procedure EditorCreateHighlighterStream(const ASender: TObject; const AName: string; var AStream: TStream);
  private
    procedure SetSelectedColor;
    procedure SetSelectedHighlighter;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

const
  HIGHLIGHTERS_PATH = '..\..\Highlighters\';
  THEMES_PATH = '..\..\Themes\';

procedure AddFileNamesFromPathIntoListBox(const APath: string; AListBox: TListBox);
var
  LSearchRec: TSearchRec;
begin
  if FindFirst(APath + '*.json', faNormal, LSearchRec) = 0 then
  try
    repeat
      AListBox.AddItem(LSearchRec.Name, nil);
    until FindNext(LSearchRec) <> 0;
  finally
    FindClose(LSearchRec);
  end;
end;

procedure TMainForm.EditorCreateHighlighterStream(const ASender: TObject; const AName: string; var AStream: TStream);
begin
  { Multi-highlighter stream loaging. For example HTML with scripts (PHP, Javascript, and CSS). }
  if AName <> '' then
    AStream := TFileStream.Create(HIGHLIGHTERS_PATH + AName + '.json', fmOpenRead);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  AddFileNamesFromPathIntoListBox(HIGHLIGHTERS_PATH, ListBoxHighlighters);
  AddFileNamesFromPathIntoListBox(THEMES_PATH, ListBoxThemes);

  with ListBoxHighlighters do
  Selected[Items.IndexOf('Object Pascal.json')] := True;

  with ListBoxThemes do
  Selected[Items.IndexOf('Default.json')] := True;

  SetSelectedHighlighter;
  SetSelectedColor;
end;

procedure TMainForm.SetSelectedColor;
begin
  with ListBoxThemes do
  Editor.Highlighter.Colors.LoadFromFile(THEMES_PATH + Items[ItemIndex]);
end;

procedure TMainForm.SetSelectedHighlighter;
begin
  with ListBoxHighlighters do
  Editor.Highlighter.LoadFromFile(HIGHLIGHTERS_PATH + Items[ItemIndex]);

  Editor.Lines.Text := Editor.Highlighter.Sample;
end;

procedure TMainForm.ListBoxThemesClick(Sender: TObject);
begin
  SetSelectedColor;
end;

procedure TMainForm.ListBoxHighlightersClick(Sender: TObject);
begin
  SetSelectedHighlighter;
end;

end.