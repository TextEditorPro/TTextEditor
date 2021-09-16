unit TTextEditorDemo.Form.Main;

interface

uses
  Winapi.Messages, Winapi.Windows, System.Classes, System.ImageList, System.SysUtils, System.Variants, Vcl.Controls,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms, Vcl.Graphics, Vcl.ImgList, Vcl.StdCtrls, TextEditor;

type
  TMainForm = class(TForm)
    ListBoxHighlighters: TListBox;
    ListBoxThemes: TListBox;
    PanelLeft: TPanel;
    SplitterHorizontal: TSplitter;
    SplitterVertical: TSplitter;
    TextEditor: TTextEditor;
    procedure FormCreate(Sender: TObject);
    procedure ListBoxThemesClick(Sender: TObject);
    procedure ListBoxHighlightersClick(Sender: TObject);
    procedure TextEditorCreateHighlighterStream(const ASender: TObject; const AName: string; var AStream: TStream);
  private
    procedure SetSelectedColor;
    procedure SetSelectedHighlighter;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  TextEditor.CompletionProposal.Snippets, TextEditor.Types;

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

procedure TMainForm.TextEditorCreateHighlighterStream(const ASender: TObject; const AName: string; var AStream: TStream);
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
  TextEditor.Highlighter.Colors.LoadFromFile(THEMES_PATH + Items[ItemIndex]);
end;

procedure TMainForm.SetSelectedHighlighter;
var
  LItem: TTextEditorCompletionProposalSnippetItem;
begin
  with ListBoxHighlighters do
  TextEditor.Highlighter.LoadFromFile(HIGHLIGHTERS_PATH + Items[ItemIndex]);

  TextEditor.Lines.Text := TextEditor.Highlighter.Sample;

  { Snippet examples }
  if ListBoxHighlighters.Selected[ListBoxHighlighters.Items.IndexOf('Object Pascal.json')] then
  begin
    { Add begin..end with enter }
    LItem := TextEditor.CompletionProposal.Snippets.Items.Add;
    with LItem do
    begin
      Description := 'begin..end';
      Keyword := 'begin';
      ExecuteWith := seEnter;
    end;
    with LItem.Position do
    begin
      Active := True;
      Column := 2;
      Row := 2;
    end;
    with LItem.Snippet do
    begin
      Add('begin');
      Add('');
      Add('end');
    end;
    { Add if True then with space }
    LItem := TextEditor.CompletionProposal.Snippets.Items.Add;
    with LItem do
    begin
      Description := 'if True then';
      Keyword := 'if';
      ExecuteWith := seSpace;
    end;
    with LItem.Selection do
    begin
      Active := True;
      FromColumn := 4;
      ToColumn := 8;
      FromRow := 1;
      ToRow := 1;
    end;
    LItem.Snippet.Add('if True then');
  end
  else
    TextEditor.CompletionProposal.Snippets.Items.Clear;
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