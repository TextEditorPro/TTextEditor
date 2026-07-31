unit TTextEditorDemo.Form.Main;

interface

uses
  System.Classes, System.SysUtils, System.UITypes, FMX.Controls, FMX.Controls.Presentation, FMX.Forms, FMX.Layouts, FMX.ListBox, FMX.Menus,
  FMX.Objects, FMX.StdCtrls, FMX.TextEditor, FMX.TextEditor.Types, FMX.Types;

type
  TMainForm = class(TForm)
    LabelZoom: TLabel;
    ListBoxHighlighters: TListBox;
    ListBoxThemes: TListBox;
    MenuItemZoom100: TMenuItem;
    MenuItemZoom125: TMenuItem;
    MenuItemZoom150: TMenuItem;
    MenuItemZoom200: TMenuItem;
    MenuItemZoom300: TMenuItem;
    PopupMenuZoom: TPopupMenu;
    RectangleLeft: TRectangle;
    RectangleThemes: TRectangle;
    SplitterHorizontal: TSplitter;
    SplitterVertical: TSplitter;
    StatusBar: TStatusBar;
    TextEditor: TTextEditor;
    procedure FormCreate(Sender: TObject);
    procedure ListBoxHighlightersChange(Sender: TObject);
    procedure ListBoxThemesChange(Sender: TObject);
    procedure MenuItemZoomClick(Sender: TObject);
    procedure StatusBarClick(Sender: TObject);
    procedure TextEditorCompletionProposalExecute(const ASender: TObject; var AParams: TCompletionProposalParams);
    procedure TextEditorCreateHighlighterStream(const ASender: TObject; const AName: string; var AStream: TStream);
  private
    FUpdating: Boolean;
    function IsHighlighterSelected(const AName: string): Boolean;
    procedure AddSnippetExamples;
    procedure SetSelectedColor;
    procedure SetSelectedHighlighter;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
  FMX.TextEditor.CompletionProposal.Snippets;

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
      AListBox.Items.Add(LSearchRec.Name);
    until FindNext(LSearchRec) <> 0;
  finally
    FindClose(LSearchRec);
  end;
end;

function TMainForm.IsHighlighterSelected(const AName: string): Boolean;
begin
  Result := (ListBoxHighlighters.ItemIndex >= 0) and (ListBoxHighlighters.Items[ListBoxHighlighters.ItemIndex] = AName);
end;

procedure TMainForm.TextEditorCompletionProposalExecute(const ASender: TObject; var AParams: TCompletionProposalParams);
var
  LItem: TTextEditorCompletionProposalItem;
begin
  { Custom keyword example }
  if IsHighlighterSelected('Object Pascal.json') then
  for var LIndex := 5 downto 1 do
  begin
    LItem.Keyword := 'Custom keyword ' + LIndex.ToString;
    LItem.Description := 'Example ' + LIndex.ToString;
    LItem.SnippetIndex := -1;
    AParams.Items.Insert(0, LItem);
  end;
end;

procedure TMainForm.TextEditorCreateHighlighterStream(const ASender: TObject; const AName: string; var AStream: TStream);
begin
  { Multi-highlighter stream loading. For example HTML with scripts (PHP, Javascript, and CSS). }
  if not AName.IsEmpty then
    AStream := TFileStream.Create(TDemoPaths.Highlighters + AName + '.json', fmOpenRead);
end;

procedure TMainForm.MenuItemZoomClick(Sender: TObject);
var
  LMenuItem: TMenuItem;
begin
  LMenuItem := TMenuItem(Sender);

  MenuItemZoom100.IsChecked := LMenuItem = MenuItemZoom100;
  MenuItemZoom125.IsChecked := LMenuItem = MenuItemZoom125;
  MenuItemZoom150.IsChecked := LMenuItem = MenuItemZoom150;
  MenuItemZoom200.IsChecked := LMenuItem = MenuItemZoom200;
  MenuItemZoom300.IsChecked := LMenuItem = MenuItemZoom300;

  TextEditor.ZoomPercentage := Integer(LMenuItem.Tag);

  LabelZoom.Text := 'Zoom: ' + LMenuItem.Text;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FUpdating := True;
  try
    AddFileNamesFromPathIntoListBox(TDemoPaths.Highlighters, ListBoxHighlighters);
    AddFileNamesFromPathIntoListBox(TDemoPaths.Themes, ListBoxThemes);

    ListBoxHighlighters.ItemIndex := ListBoxHighlighters.Items.IndexOf('Object Pascal.json');
    ListBoxThemes.ItemIndex := ListBoxThemes.Items.IndexOf('Default.json');
  finally
    FUpdating := False;
  end;

  SetSelectedHighlighter;
  SetSelectedColor;
end;

procedure TMainForm.SetSelectedColor;
begin
  if ListBoxThemes.ItemIndex >= 0 then
    TextEditor.Highlighter.Colors.LoadFromFile(TDemoPaths.Themes + ListBoxThemes.Items[ListBoxThemes.ItemIndex]);
end;

procedure TMainForm.SetSelectedHighlighter;
begin
  if ListBoxHighlighters.ItemIndex >= 0 then
    TextEditor.Highlighter.LoadFromFile(TDemoPaths.Highlighters + ListBoxHighlighters.Items[ListBoxHighlighters.ItemIndex]);

  TextEditor.Lines.Text := TextEditor.Highlighter.Sample;

  AddSnippetExamples;
end;

procedure TMainForm.AddSnippetExamples;
var
  LItem: TTextEditorCompletionProposalSnippetItem;
begin
  TextEditor.CompletionProposal.Snippets.Items.Clear;

  if IsHighlighterSelected('Object Pascal.json') then
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
  if IsHighlighterSelected('HTML with Scripts.json') then
  begin
    { "<br />" with shortcut shift + enter }
    LItem := TextEditor.CompletionProposal.Snippets.Items.Add;

    with LItem do
    begin
      Description := '<br />';
      ShortCut := scShift or vkReturn; { Shift+Enter }
    end;

    with LItem.Position do
    begin
      Active := True;
      Column := 7;
      Row := 1;
    end;

    LItem.Snippet.Add('<br />');
  end;
end;

procedure TMainForm.StatusBarClick(Sender: TObject);
begin
  PopupMenuZoom.Popup(Screen.MousePos.X, Screen.MousePos.Y);
end;

procedure TMainForm.ListBoxThemesChange(Sender: TObject);
begin
  if not FUpdating then
    SetSelectedColor;
end;

procedure TMainForm.ListBoxHighlightersChange(Sender: TObject);
begin
  if not FUpdating then
    SetSelectedHighlighter;
end;

end.

