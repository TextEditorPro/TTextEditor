unit TTextEditorDemo.Form.Main;

interface

uses
  Winapi.Messages, Winapi.Windows, System.Actions, System.Classes, System.ImageList, System.SysUtils, Vcl.ActnCtrls, Vcl.ActnList,
  Vcl.ActnMan, Vcl.ActnMenus, Vcl.BaseImageCollection, Vcl.Buttons, Vcl.ComCtrls, Vcl.Controls, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms,
  Vcl.ImageCollection, Vcl.ImgList, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ToolWin, Vcl.VirtualImageList,
  MyControl.ObjectInspector, TextEditor, TextEditor.Compare.ScrollBar, TextEditor.Print, TextEditor.Print.Preview, TextEditor.Types,
  TTextEditorDemo.Frame.PrintPreview, TTextEditorDemo.Frame.TextCompare, TTextEditorDemo.Frame.TextEditor;

type
  TMainForm = class(TForm)
    ActionBookmarksNextBookmark: TAction;
    ActionBookmarksPreviousBookmark: TAction;
    ActionBookmarksToggleBookmark: TAction;
    ActionFileExit: TAction;
    ActionFileExportToHTML: TAction;
    ActionFileLoadHighlighterSample: TAction;
    ActionFileOpen: TAction;
    ActionFileSave: TAction;
    ActionFileSaveAs: TAction;
    ActionList: TActionList;
    ActionMainMenuBar: TActionMainMenuBar;
    ActionManager: TActionManager;
    ActionSearchGoToLine: TAction;
    ActionTestClipboardRoundTrip: TAction;
    ActionTestHighlighterSweep: TAction;
    ActionTestSaveLoad: TAction;
    ActionTestSelectionInvariants: TAction;
    ActionTestUndoRedo: TAction;
    ActionToolBar1: TActionToolBar;
    ActionViewDarkTheme: TAction;
    ActionViewPrintPreview: TAction;
    ActionViewTextCompare: TAction;
    ActionViewTextEditor: TAction;
    ImageCollection: TImageCollection;
    MenuItemZoom100: TMenuItem;
    MenuItemZoom125: TMenuItem;
    MenuItemZoom150: TMenuItem;
    MenuItemZoom200: TMenuItem;
    MenuItemZoom300: TMenuItem;
    OpenDialog: TOpenDialog;
    PanelMain: TPanel;
    PanelSidebar: TPanel;
    PopupMenuHighlighters: TPopupMenu;
    PopupMenuThemes: TPopupMenu;
    PopupMenuZoom: TPopupMenu;
    SaveDialog: TSaveDialog;
    SaveDialogHTML: TSaveDialog;
    SpeedButtonDarkTheme: TSpeedButton;
    SpeedButtonPrintPreview: TSpeedButton;
    SpeedButtonTextCompare: TSpeedButton;
    SpeedButtonTextEditor: TSpeedButton;
    StatusBar: TStatusBar;
    VirtualImageList: TVirtualImageList;
    procedure ActionBookmarksNextBookmarkExecute(Sender: TObject);
    procedure ActionBookmarksPreviousBookmarkExecute(Sender: TObject);
    procedure ActionBookmarksToggleBookmarkExecute(Sender: TObject);
    procedure ActionFileExitExecute(Sender: TObject);
    procedure ActionFileExportToHTMLExecute(Sender: TObject);
    procedure ActionFileLoadHighlighterSampleExecute(Sender: TObject);
    procedure ActionFileOpenExecute(Sender: TObject);
    procedure ActionFileSaveAsExecute(Sender: TObject);
    procedure ActionFileSaveExecute(Sender: TObject);
    procedure ActionSearchGoToLineExecute(Sender: TObject);
    procedure ActionTestClipboardRoundTripExecute(Sender: TObject);
    procedure ActionTestHighlighterSweepExecute(Sender: TObject);
    procedure ActionTestSaveLoadExecute(Sender: TObject);
    procedure ActionTestSelectionInvariantsExecute(Sender: TObject);
    procedure ActionTestUndoRedoExecute(Sender: TObject);
    procedure ActionViewDarkThemeExecute(Sender: TObject);
    procedure ActionViewExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuItemZoomClick(Sender: TObject);
    procedure SelectHighlighter(Sender: TObject);
    procedure SelectTheme(Sender: TObject);
    procedure StatusBarClick(Sender: TObject);
    procedure TextEditorCaretChanged(const ASender: TObject; const X, Y: Integer; const AOffset: Integer);
    procedure TextEditorChange(Sender: TObject);
  private
    FFileName: string;
    FFramePrintPreview: TFramePrintPreview;
    FFrameTextCompare: TFrameTextCompare;
    FFrameTextEditor: TFrameTextEditor;
    FIsCustomStyleActive: Boolean;
    FObjectInspector: TMyObjectInspector;
    FSplitterRight: TSplitter;
    FWndProcGuardActive: Boolean;
    procedure AddFileNamesFromPathIntoPopupMenu(const APath: string; const APopupMenu: TPopupMenu);
    procedure AddFileNamesFromPathIntoSubPopupMenu(const APath: string; const APopupMenu: TPopupMenu);
    procedure CreateFrames;
    procedure CreateInspector;
    procedure CreateRightSplitter;
    procedure InitializeHighlightersAndThemes;
    procedure InspectObject(const AObject: TComponent);
    procedure SetSelectedHighlighter(const AValue: string);
    procedure SetSelectedTheme(const AValue: string);
    procedure UpdateCaption;
    procedure UpdateModifiedState;
    procedure UpdatePosition;
  public
    procedure WndProc(var AMessage: TMessage); override;
  end;

var
  MainForm: TMainForm;

procedure ToggleDarkStyle(const AValue: Boolean);

implementation

{$R *.dfm}

uses
  System.Generics.Collections, System.Math, System.Types, System.UITypes, Vcl.Themes, TextEditor.Lines;

type
  TDemoPaths = record
  const
    Highlighters = '..\..\Highlighters\';
    Themes = '..\..\Themes\';
  end;

var
  FDarkStyleEnabled: Boolean;
  FStyleLoaded: Boolean;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FIsCustomStyleActive := IsCustomStyleActive;

  CreateFrames;

  InitializeHighlightersAndThemes;

  UpdatePosition;
  UpdateModifiedState;

  CreateInspector;

  SetSelectedHighlighter('Object Pascal');
  SetSelectedTheme('Visual Studio Dark');

  InspectObject(FFrameTextEditor.TextEditor);

  CreateRightSplitter;
end;

procedure TMainForm.SetSelectedHighlighter(const AValue: string);
var
  LFileName: string;
begin
  LFileName := TDemoPaths.Highlighters + AValue + '.json';

  FFrameTextEditor.TextEditor.Highlighter.LoadFromFile(LFileName);
  FFrameTextCompare.EditorCompareLeft.Highlighter.LoadFromFile(LFileName);
  FFrameTextCompare.EditorCompareRight.Highlighter.LoadFromFile(LFileName);

  { The import turns code folding on when the highlighter defines fold regions.

    Folding cannot be active in the compare editors - the aligned view inserts placeholder lines behind the editor's back, which would
    desync the fold ranges. }
  FFrameTextCompare.EditorCompareLeft.CodeFolding.Visible := False;
  FFrameTextCompare.EditorCompareRight.CodeFolding.Visible := False;

  if FFileName.IsEmpty then
    FFrameTextEditor.TextEditor.Lines.Text := FFrameTextEditor.TextEditor.Highlighter.Sample;

  StatusBar.Panels[4].Text := AValue;
end;

procedure TMainForm.SetSelectedTheme(const AValue: string);
var
  LFileName: string;
begin
  LFileName := TDemoPaths.Themes + AValue + '.json';

  FFrameTextEditor.TextEditor.Highlighter.Colors.LoadFromFile(LFileName);
  FFrameTextCompare.EditorCompareLeft.Highlighter.Colors.LoadFromFile(LFileName);
  FFrameTextCompare.EditorCompareRight.Highlighter.Colors.LoadFromFile(LFileName);

  FFrameTextCompare.CompareScrollBar.Invalidate;

  StatusBar.Panels[5].Text := AValue;
end;

procedure TMainForm.SelectHighlighter(Sender: TObject);
begin
  var LCaption := StringReplace(TMenuItem(Sender).Caption, '&', '', []);

  SetSelectedHighlighter(LCaption);
end;

procedure TMainForm.SelectTheme(Sender: TObject);
begin
  var LCaption := StringReplace(TMenuItem(Sender).Caption, '&', '', []);

  SetSelectedTheme(LCaption);
end;

procedure TMainForm.AddFileNamesFromPathIntoSubPopupMenu(const APath: string; const APopupMenu: TPopupMenu);
var
  LSearchRec: TSearchRec;
  LMenuItem, LSubMenuItem: TMenuItem;
  LCaption, LFirstCharacter: string;

  function FindMenuItem(const ACaption: string): TMenuItem;
  var
    LItem: TMenuItem;
  begin
    Result := nil;

    for var LIndex := 0 to APopupMenu.Items.Count - 1 do
    begin
      LItem := APopupMenu.Items[LIndex];

      if LItem.Caption = ACaption then
        Exit(LItem);
    end;
  end;

begin
  if FindFirst(APath + '*.json', faNormal, LSearchRec) = 0 then
  try
    repeat
      LCaption := ChangeFileExt(LSearchRec.Name, '');

      LFirstCharacter := LCaption[1];

      LMenuItem := FindMenuItem(LFirstCharacter);

      if not Assigned(LMenuItem) then
      begin
        LMenuItem := TMenuItem.Create(APopupMenu);
        LMenuItem.Caption := LFirstCharacter;

        APopupMenu.Items.Add(LMenuItem);
      end;

      LSubMenuItem := TMenuItem.Create(APopupMenu);
      LSubMenuItem.Caption := LCaption;
      LSubMenuItem.OnClick := SelectHighlighter;

      LMenuItem.Add(LSubMenuItem);
    until FindNext(LSearchRec) <> 0;
  finally
    FindClose(LSearchRec);
  end;
end;

procedure TMainForm.AddFileNamesFromPathIntoPopupMenu(const APath: string; const APopupMenu: TPopupMenu);
var
  LSearchRec: TSearchRec;
  LMenuItem: TMenuItem;
begin
  if FindFirst(APath + '*.json', faNormal, LSearchRec) = 0 then
  try
    repeat
      LMenuItem := TMenuItem.Create(APopupMenu);
      LMenuItem.Caption := ChangeFileExt(LSearchRec.Name, '');
      LMenuItem.OnClick := SelectTheme;

      APopupMenu.Items.Add(LMenuItem);
    until FindNext(LSearchRec) <> 0;
  finally
    FindClose(LSearchRec);
  end;
end;

procedure TMainForm.CreateFrames;
begin
  { Text editor }
  FFrameTextEditor := TFrameTextEditor.Create(Self);
  FFrameTextEditor.TextEditor.OnCaretChanged := TextEditorCaretChanged;
  FFrameTextEditor.TextEditor.OnChange := TextEditorChange;
  FFrameTextEditor.Parent := PanelMain;

  { Text compare }
  FFrameTextCompare := TFrameTextCompare.Create(Self);
  FFrameTextCompare.Visible := False;
  FFrameTextCompare.Parent := PanelMain;

  { Print preview }
  FFramePrintPreview := TFramePrintPreview.Create(Self);
  FFramePrintPreview.Visible := False;
  FFramePrintPreview.Parent := PanelMain;
end;

procedure TMainForm.InitializeHighlightersAndThemes;
begin
  AddFileNamesFromPathIntoSubPopupMenu(TDemoPaths.Highlighters, PopupMenuHighlighters);
  AddFileNamesFromPathIntoPopupMenu(TDemoPaths.Themes, PopupMenuThemes);
end;

procedure TMainForm.CreateInspector;
begin
  FObjectInspector := TMyObjectInspector.Create(Self);
  FObjectInspector.Parent := PanelMain;
  FObjectInspector.Align := alRight;
  FObjectInspector.Width := 350;
  FObjectInspector.AddUnlistedProperties(['JSON']);
end;

procedure TMainForm.CreateRightSplitter;
begin
  FSplitterRight := TSplitter.Create(Self);
  FSplitterRight.Parent := PanelMain;
  FSplitterRight.Align := alRight;
  FSplitterRight.Left := FObjectInspector.Left - FSplitterRight.Width;
end;

procedure TMainForm.InspectObject(const AObject: TComponent);
begin
  FObjectInspector.InspectedObject := AObject;
end;

procedure TMainForm.UpdateCaption;
begin
  Caption := 'TTextEditor Advanced Demo';

  if FFileName <> '' then
    Caption := Caption + ' - ' + FFileName;
end;

procedure TMainForm.MenuItemZoomClick(Sender: TObject);
begin
  FFrameTextEditor.TextEditor.ZoomPercentage := TMenuItem(Sender).Tag;

  StatusBar.Panels[3].Text := 'Zoom: ' + TMenuItem(Sender).Caption;
end;

procedure ToggleDarkStyle(const AValue: Boolean);
begin
  if not FStyleLoaded then
  begin
    TStyleManager.AutoDiscoverStyleResources := False; // Specifies whether the style manager should automatically load all styles of registered types or not.
    try
      TStyleManager.LoadFromResource(HInstance, 'DARKSTYLE');
      FStyleLoaded := True;
    except
      Exit;
    end;
  end;

  FDarkStyleEnabled := AValue;



  TStyleManager.TrySetStyle(if AValue then 'Windows11 Modern Dark' else 'Windows');
end;

procedure TMainForm.ActionBookmarksNextBookmarkExecute(Sender: TObject);
begin
  FFrameTextEditor.TextEditor.GoToNextBookmark;
end;

procedure TMainForm.ActionBookmarksPreviousBookmarkExecute(Sender: TObject);
begin
  FFrameTextEditor.TextEditor.GoToPreviousBookmark;
end;

procedure TMainForm.ActionBookmarksToggleBookmarkExecute(Sender: TObject);
begin
  FFrameTextEditor.TextEditor.ToggleBookmark;
end;

procedure TMainForm.ActionFileExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.ActionFileExportToHTMLExecute(Sender: TObject);
begin
  if SaveDialogHTML.Execute then
    FFrameTextEditor.TextEditor.ExportToHTML(SaveDialogHTML.FileName);
end;

procedure TMainForm.ActionFileLoadHighlighterSampleExecute(Sender: TObject);
begin
  FFileName := '';

  FFrameTextEditor.TextEditor.Lines.Text := FFrameTextEditor.TextEditor.Highlighter.Sample;

  UpdateCaption;
  UpdateModifiedState;
end;

procedure TMainForm.ActionFileOpenExecute(Sender: TObject);
begin
  if OpenDialog.Execute then
  begin
    FFileName := OpenDialog.FileName;

    FFrameTextEditor.TextEditor.LoadFromFile(FFileName);

    UpdateCaption;
    UpdateModifiedState;
  end;
end;

procedure TMainForm.ActionFileSaveAsExecute(Sender: TObject);
begin
  if SaveDialog.Execute then
  begin
    FFileName := SaveDialog.FileName;

    FFrameTextEditor.TextEditor.SaveToFile(FFileName);

    UpdateCaption;
    UpdateModifiedState;
  end;
end;

procedure TMainForm.ActionFileSaveExecute(Sender: TObject);
begin
  if FFileName.IsEmpty then
    ActionFileSaveAs.Execute
  else
  begin
    FFrameTextEditor.TextEditor.SaveToFile(FFileName);

    UpdateModifiedState;
  end;
end;

procedure TMainForm.ActionSearchGoToLineExecute(Sender: TObject);
var
  LValue: string;
  LLine: Integer;
begin
  if InputQuery('Go to line', 'Line number', LValue) and TryStrToInt(LValue, LLine) then
    FFrameTextEditor.TextEditor.GoToLineAndSetPosition(LLine);
end;

procedure TMainForm.ActionTestUndoRedoExecute(Sender: TObject);
begin
  FFrameTextEditor.RunUndoRedoTest;
end;

procedure TMainForm.ActionTestSelectionInvariantsExecute(Sender: TObject);
begin
  FFrameTextEditor.RunSelectionInvariantsTest;
end;

procedure TMainForm.ActionTestSaveLoadExecute(Sender: TObject);
begin
  FFrameTextEditor.RunSaveLoadTest;
end;

procedure TMainForm.ActionTestClipboardRoundTripExecute(Sender: TObject);
begin
  FFrameTextEditor.RunClipboardRoundTripTest;
end;

procedure TMainForm.ActionTestHighlighterSweepExecute(Sender: TObject);
begin
  FFrameTextEditor.RunHighlighterSweepTest;
end;

procedure TMainForm.ActionViewDarkThemeExecute(Sender: TObject);
begin
  ToggleDarkStyle(not FDarkStyleEnabled);

  if FDarkStyleEnabled then
    SetSelectedTheme('Visual Studio Dark')
  else
    SetSelectedTheme('Default');

  Application.ProcessMessages;

  FObjectInspector.InspectedObject := FObjectInspector.InspectedObject;
end;

procedure TMainForm.ActionViewExecute(Sender: TObject);
begin
  var LTag := TAction(Sender).Tag;

  case LTag of
    0:
      begin
        InspectObject(FFrameTextEditor.TextEditor);
        SpeedButtonTextEditor.Down := True;
      end;
    1:
      begin
        FFrameTextCompare.CompareEditors;
        FFrameTextCompare.CompareScrollBar.Invalidate;
        InspectObject(FFrameTextCompare.CompareScrollBar);
        SpeedButtonTextCompare.Down := True;
      end;
    2:
      begin
        FFramePrintPreview.UpdatePrintPreview(FFileName);
        FFramePrintPreview.PrintPreview.EditorPrint.Editor := FFrameTextEditor.TextEditor;
        InspectObject(FFramePrintPreview.PrintPreview);
        SpeedButtonPrintPreview.Down := True;
      end;
  end;

  FFrameTextEditor.Visible := LTag = 0;
  FFrameTextCompare.Visible := LTag = 1;
  FFramePrintPreview.Visible := LTag = 2;
end;

procedure TMainForm.UpdatePosition;
begin
  StatusBar.Panels[1].Text := Format('Ln %d : Col %d', [FFrameTextEditor.TextEditor.TextPosition.Line + 1, FFrameTextEditor.TextEditor.TextPosition.Char]);
end;

procedure TMainForm.UpdateModifiedState;
begin
  StatusBar.Panels[2].Text := if FFrameTextEditor.TextEditor.Modified then 'Modified' else '';
end;

procedure TMainForm.TextEditorCaretChanged(const ASender: TObject; const X, Y: Integer; const AOffset: Integer);
begin
  UpdatePosition;
end;

procedure TMainForm.TextEditorChange(Sender: TObject);
begin
  UpdateModifiedState;
end;

procedure TMainForm.StatusBarClick(Sender: TObject);
var
  LPoint: TPoint;

  function GetPanelIndex: Integer;
  begin
    Result := -1;

    var LPointStatusBar := StatusBar.ScreenToClient(LPoint);
    var LWidth := 0;
    var LPanelWidth: Integer;

    for var LIndex := 0 to StatusBar.Panels.Count - 1 do
    begin
      LPanelWidth := StatusBar.Panels[LIndex].Width;

      if (LPointStatusBar.X > LWidth) and (LPointStatusBar.X < LWidth + LPanelWidth) then
        Exit(LIndex);

      LWidth := LWidth + LPanelWidth;
    end;

  end;

begin
  if GetCursorPos(LPoint) then
  case GetPanelIndex of
    3: PopupMenuZoom.Popup(LPoint.X, LPoint.Y);
    4: PopupMenuHighlighters.Popup(LPoint.X, LPoint.Y);
    5: PopupMenuThemes.Popup(LPoint.X, LPoint.Y);
  end;
end;

{ Embarcadero style fix }

procedure TMainForm.WndProc(var AMessage: TMessage);
begin
  if FIsCustomStyleActive and (AMessage.Msg = CM_SHOWINGCHANGED) and Showing and not FWndProcGuardActive and not (csDesigning in ComponentState) then
  begin
    FWndProcGuardActive := True;
    try
      AlphaBlend := True;
      AlphaBlendValue := 0;

      inherited WndProc(AMessage);

      if HandleAllocated then
        RedrawWindow(Handle, nil, 0, RDW_ALLCHILDREN or RDW_INVALIDATE or RDW_UPDATENOW);

      AlphaBlendValue := 0;

      for var LIndex := 1 to 3 do
      begin
        Sleep(8);
        Application.ProcessMessages;

        AlphaBlendValue := AlphaBlendValue + 85;
      end;

      AlphaBlend := False;
    finally
      FWndProcGuardActive := False;
    end;
  end
  else
    inherited WndProc(AMessage);
end;

end.
