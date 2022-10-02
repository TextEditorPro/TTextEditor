unit TTextEditorDemo.Form.Main;

interface

uses
  Winapi.Messages, Winapi.Windows, System.Actions, System.Classes, System.SysUtils, System.Variants, Vcl.ActnList,
  Vcl.ComCtrls, Vcl.Controls, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms, Vcl.Graphics, Vcl.Menus, Vcl.StdCtrls, TextEditor,
  TextEditor.Types;

type
  TMainForm = class(TForm)
    ActionList: TActionList;
    ActionUseDefaultTheme: TAction;
    ActionZoom100: TAction;
    ActionZoom125: TAction;
    ActionZoom150: TAction;
    ActionZoom200: TAction;
    ActionZoom300: TAction;
    CheckBoxUseDefaultTheme: TCheckBox;
    ListBoxHighlighters: TListBox;
    ListBoxThemes: TListBox;
    MenuItemZoom100: TMenuItem;
    MenuItemZoom125: TMenuItem;
    MenuItemZoom150: TMenuItem;
    MenuItemZoom200: TMenuItem;
    MenuItemZoom300: TMenuItem;
    PanelLeft: TPanel;
    PanelThemes: TPanel;
    PopupMenuZoom: TPopupMenu;
    SplitterHorizontal: TSplitter;
    SplitterVertical: TSplitter;
    StatusBar: TStatusBar;
    TextEditor: TTextEditor;
    procedure ActionUseDefaultThemeExecute(Sender: TObject);
    procedure ActionZoomExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ListBoxHighlightersClick(Sender: TObject);
    procedure ListBoxThemesClick(Sender: TObject);
    procedure StatusBarClick(Sender: TObject);
    procedure TextEditorCompletionProposalExecute(const ASender: TObject; var AParams: TCompletionProposalParams);
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
  TextEditor.CompletionProposal.Snippets;

type
  TDemoPaths = record
  const
    Highlighters = '..\..\Highlighters\';
    Themes = '..\..\Themes\';
  end;

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

procedure TMainForm.TextEditorCompletionProposalExecute(const ASender: TObject; var AParams: TCompletionProposalParams);
var
  LIndex: Integer;
  LItem: TTextEditorCompletionProposalItem;
begin
  { Custom keyword example }
  if ListBoxHighlighters.Selected[ListBoxHighlighters.Items.IndexOf('Object Pascal.json')] then
  for LIndex := 5 downto 1 do
  begin
    LItem.Keyword := 'Custom keyword ' + LIndex.ToString;
    LItem.Description := 'Example ' + LIndex.ToString;
    LItem.SnippetIndex := -1;
    AParams.Items.Insert(0, LItem);
  end;
end;

procedure TMainForm.TextEditorCreateHighlighterStream(const ASender: TObject; const AName: string; var AStream: TStream);
begin
  { Multi-highlighter stream loaging. For example HTML with scripts (PHP, Javascript, and CSS). }
  if AName <> '' then
    AStream := TFileStream.Create(TDemoPaths.Highlighters + AName + '.json', fmOpenRead);
end;

procedure TMainForm.ActionUseDefaultThemeExecute(Sender: TObject);
begin
  ListBoxThemes.Enabled := not CheckBoxUseDefaultTheme.Checked;

  if CheckBoxUseDefaultTheme.Checked then
    TextEditor.Highlighter.Colors.SetDefaults
  else
    SetSelectedColor;
end;

procedure TMainForm.ActionZoomExecute(Sender: TObject);
begin
  TextEditor.Zoom(TAction(Sender).Tag);
  StatusBar.Panels[0].Text := 'Zoom: ' + TAction(Sender).Caption;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  AddFileNamesFromPathIntoListBox(TDemoPaths.Highlighters, ListBoxHighlighters);
  AddFileNamesFromPathIntoListBox(TDemoPaths.Themes, ListBoxThemes);

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
  TextEditor.Highlighter.Colors.LoadFromFile(TDemoPaths.Themes + Items[ItemIndex]);
end;

procedure TMainForm.SetSelectedHighlighter;
var
  LItem: TTextEditorCompletionProposalSnippetItem;
begin
  with ListBoxHighlighters do
  TextEditor.Highlighter.LoadFromFile(TDemoPaths.Highlighters + Items[ItemIndex]);

  TextEditor.Lines.Text := TextEditor.Highlighter.Sample;

  { Snippet examples }
  TextEditor.CompletionProposal.Snippets.Items.Clear;

  if ListBoxHighlighters.Selected[ListBoxHighlighters.Items.IndexOf('Object Pascal.json')] then
  begin
    { "begin..end" with enter }
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
    { "if True then" with space }
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
  if ListBoxHighlighters.Selected[ListBoxHighlighters.Items.IndexOf('HTML with Scripts.json')] then
  begin
    { "<br />" with shortcut shift + enter }
    LItem := TextEditor.CompletionProposal.Snippets.Items.Add;
    with LItem do
    begin
      Description := '<br />';
      ShortCut := TextToShortCut('Shift+Enter');
    end;
    with LItem.Position do
    begin
      Active := True;
      Column := 7;
      Row := 1;
    end;
    LItem.Snippet.Add('<br />');
  end
end;

procedure TMainForm.StatusBarClick(Sender: TObject);
var
  LPoint: TPoint;
begin
  if GetCursorPos(LPoint) then
    PopupMenuZoom.Popup(LPoint.X, LPoint.Y);
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