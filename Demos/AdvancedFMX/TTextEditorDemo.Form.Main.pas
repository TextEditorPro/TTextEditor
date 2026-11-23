unit TTextEditorDemo.Form.Main;

interface

uses
  System.Classes, System.SysUtils, System.Types, System.UITypes, FMX.Controls, FMX.Controls.Presentation, FMX.Dialogs, FMX.Edit, FMX.Forms,
  FMX.Graphics, FMX.Layouts, FMX.ListBox, FMX.Menus, FMX.Objects, FMX.Printer, FMX.StdCtrls, FMX.TabControl, FMX.TextEditor,
  FMX.TextEditor.Compare.ScrollBar, FMX.TextEditor.MacroRecorder, FMX.TextEditor.Print, FMX.TextEditor.Print.Preview, FMX.TextEditor.Types,
  FMX.Types, MyControl.ObjectInspector;

type
  TMainForm = class(TForm)
    ButtonFindNext: TButton;
    ButtonFindPrevious: TButton;
    ButtonPageFirst: TButton;
    ButtonPageLast: TButton;
    ButtonPageNext: TButton;
    ButtonPagePrevious: TButton;
    CheckBoxColors: TCheckBox;
    CheckBoxHighlight: TCheckBox;
    CheckBoxLineNumbers: TCheckBox;
    CheckBoxWordWrap: TCheckBox;
    ComboBoxHighlighters: TComboBox;
    ComboBoxPreviewScale: TComboBox;
    ComboBoxThemes: TComboBox;
    CompareScrollBar: TTextEditorCompareScrollBar;
    EditSearch: TEdit;
    EditorCompareLeft: TTextEditor;
    EditorCompareRight: TTextEditor;
    LabelHighlighter: TLabel;
    LabelMacroState: TLabel;
    LabelModifiedState: TLabel;
    LabelPage: TLabel;
    LabelPosition: TLabel;
    LabelPreviewScale: TLabel;
    LabelSearch: TLabel;
    LabelTestRun: TLabel;
    LabelTheme: TLabel;
    LabelZoom: TLabel;
    MenuBar: TMenuBar;
    MenuItemBookmarkNext: TMenuItem;
    MenuItemBookmarkPrevious: TMenuItem;
    MenuItemBookmarkToggle: TMenuItem;
    MenuItemBookmarks: TMenuItem;
    MenuItemExit: TMenuItem;
    MenuItemExportToHTML: TMenuItem;
    MenuItemFile: TMenuItem;
    MenuItemFileSeparator1: TMenuItem;
    MenuItemFileSeparator2: TMenuItem;
    MenuItemGoToLine: TMenuItem;
    MenuItemMacro: TMenuItem;
    MenuItemMacroPause: TMenuItem;
    MenuItemMacroPlay: TMenuItem;
    MenuItemMacroRecord: TMenuItem;
    MenuItemMacroStop: TMenuItem;
    MenuItemOpen: TMenuItem;
    MenuItemPrint: TMenuItem;
    MenuItemSample: TMenuItem;
    MenuItemSave: TMenuItem;
    MenuItemSaveAs: TMenuItem;
    MenuItemSearch: TMenuItem;
    MenuItemTest: TMenuItem;
    MenuItemTestCaretNavigation: TMenuItem;
    MenuItemTestClipboardRoundTrip: TMenuItem;
    MenuItemTestHighlighterSweep: TMenuItem;
    MenuItemTestLineBreakIndent: TMenuItem;
    MenuItemTestMacro: TMenuItem;
    MenuItemTestMultiCaretEditing: TMenuItem;
    MenuItemTestPastEndOfFile: TMenuItem;
    MenuItemTestSaveLoad: TMenuItem;
    MenuItemTestSelectionInvariants: TMenuItem;
    MenuItemTestUndoRedo: TMenuItem;
    MenuItemTestWordSelection: TMenuItem;
    MenuItemZoom100: TMenuItem;
    MenuItemZoom125: TMenuItem;
    MenuItemZoom150: TMenuItem;
    MenuItemZoom200: TMenuItem;
    MenuItemZoom300: TMenuItem;
    OpenDialog: TOpenDialog;
    PopupMenuZoom: TPopupMenu;
    PrintPreview: TTextEditorPrintPreview;
    RectanglePreviewBar: TRectangle;
    RectangleSearch: TRectangle;
    SaveDialog: TSaveDialog;
    SaveDialogHTML: TSaveDialog;
    StatusBar: TStatusBar;
    TabControl: TTabControl;
    TabItemCompare: TTabItem;
    TabItemEditor: TTabItem;
    TabItemPrintPreview: TTabItem;
    TextEditor: TTextEditor;
    PrintDialog: TPrintDialog;
    procedure ButtonFindNextClick(Sender: TObject);
    procedure ButtonFindPreviousClick(Sender: TObject);
    procedure ButtonPageFirstClick(Sender: TObject);
    procedure ButtonPageLastClick(Sender: TObject);
    procedure ButtonPageNextClick(Sender: TObject);
    procedure ButtonPagePreviousClick(Sender: TObject);
    procedure CheckBoxPreviewOptionChange(Sender: TObject);
    procedure ComboBoxHighlightersChange(Sender: TObject);
    procedure ComboBoxPreviewScaleChange(Sender: TObject);
    procedure ComboBoxThemesChange(Sender: TObject);
    procedure CompareEditorAfterLinePaint(const ASender: TObject; const ACanvas: TCanvas; const ARect: TRectF; const ALineNumber: Integer; const AIsMinimapLine: Boolean);
    procedure CompareEditorChange(Sender: TObject);
    procedure CompareEditorCustomLineColors(const ASender: TObject; const ALine: Integer; var AUseColors: Boolean; var AForeground: TAlphaColor; var ABackground: TAlphaColor);
    procedure CompareEditorScroll(const ASender: TObject; const AScrollBar: TScrollBarKind);
    procedure EditSearchChangeTracking(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuItemBookmarkNextClick(Sender: TObject);
    procedure MenuItemBookmarkPreviousClick(Sender: TObject);
    procedure MenuItemBookmarkToggleClick(Sender: TObject);
    procedure MenuItemExitClick(Sender: TObject);
    procedure MenuItemExportToHTMLClick(Sender: TObject);
    procedure MenuItemGoToLineClick(Sender: TObject);
    procedure MenuItemMacroPauseClick(Sender: TObject);
    procedure MenuItemMacroPlayClick(Sender: TObject);
    procedure MenuItemMacroRecordClick(Sender: TObject);
    procedure MenuItemMacroStopClick(Sender: TObject);
    procedure MenuItemOpenClick(Sender: TObject);
    procedure MenuItemPrintClick(Sender: TObject);
    procedure MenuItemSampleClick(Sender: TObject);
    procedure MenuItemSaveAsClick(Sender: TObject);
    procedure MenuItemSaveClick(Sender: TObject);
    procedure MenuItemTestCaretNavigationClick(Sender: TObject);
    procedure MenuItemTestClipboardRoundTripClick(Sender: TObject);
    procedure MenuItemTestHighlighterSweepClick(Sender: TObject);
    procedure MenuItemTestLineBreakIndentClick(Sender: TObject);
    procedure MenuItemTestMacroClick(Sender: TObject);
    procedure MenuItemTestMultiCaretEditingClick(Sender: TObject);
    procedure MenuItemTestPastEndOfFileClick(Sender: TObject);
    procedure MenuItemTestSaveLoadClick(Sender: TObject);
    procedure MenuItemTestSelectionInvariantsClick(Sender: TObject);
    procedure MenuItemTestUndoRedoClick(Sender: TObject);
    procedure MenuItemTestWordSelectionClick(Sender: TObject);
    procedure MenuItemZoomClick(Sender: TObject);
    procedure PrintPreviewPreviewPage(ASender: TObject; APageNumber: Integer);
    procedure StatusBarClick(Sender: TObject);
    procedure TabControlChange(Sender: TObject);
    procedure TextEditorCaretChanged(const ASender: TObject; const X, Y: Single; const AOffset: Integer);
    procedure TextEditorChange(Sender: TObject);
    procedure TextEditorCreateHighlighterStream(const ASender: TObject; const AName: string; var AStream: TStream);
  private
    FComparing: Boolean;
    FFileName: string;
    FInspectorHeader: TLabel;
    FInspectorLayout: TLayout;
    FMacroRecorder: TTextEditorMacroRecorder;
    FObjectInspector: TMyObjectInspector;
    FSplitterRight: TSplitter;
    FUpdating: Boolean;
    FCompareTimer: TTimer;
    function RunCaretNavigationSeed(ASeed: Integer): string;
    function RunClipboardRoundTripSeed(ASeed: Integer): string;
    function RunLineBreakIndentSeed(ASeed: Integer): string;
    function RunMacroSeed(ASeed: Integer): string;
    function RunMultiCaretEditingSeed(ASeed: Integer): string;
    function RunPastEndOfFileSeed(ASeed: Integer): string;
    function RunSaveLoadSeed(ASeed: Integer): string;
    function RunSelectionInvariantsSeed(ASeed: Integer): string;
    function RunUndoRedoSeed(ASeed: Integer): string;
    function RunWordSelectionSeed(ASeed: Integer): string;
    function TestCommandNames(const ASeed, ASkip, ACount: Integer): string;
    procedure ExecuteTestCommand(const ACommand: Integer; const AViaCommandProcessor: Boolean = False);
    procedure LoadTestDocument;
    procedure RunTestLoop(const ASeeds: Integer; const ARun: TFunc<Integer, string>);
    procedure CompareEditors;
    procedure CompareTabResize(Sender: TObject);
    procedure CompareTimerTimer(Sender: TObject);
    procedure InspectObject(const AObject: TComponent);
    procedure MacroRecorderStateChange(Sender: TObject);
    procedure SetSelectedColor;
    procedure SetSelectedHighlighter;
    procedure UpdateCaption;
    procedure UpdateMacroMenu;
    procedure UpdateModifiedState;
    procedure UpdatePageLabel;
    procedure UpdatePosition;
    procedure UpdatePrintPreview;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
  System.Generics.Collections, System.Hash, System.IOUtils, System.Math, System.StrUtils, FMX.DialogService.Sync, FMX.Platform,
  FMX.TextEditor.Consts, FMX.TextEditor.KeyCommands, FMX.TextEditor.Lines, FMX.TextEditor.PaintHelper;

type
  TDemoPaths = record
  public
    class function Highlighters: string; static;
    class function Themes: string; static;
  end;

  TCompareRow = (crSame, crModify, crLeftOnly, crRightOnly);

class function TDemoPaths.Highlighters: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + '..\..\Highlighters\';
end;

class function TDemoPaths.Themes: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + '..\..\Themes\';
end;

const
  CompareSampleLeft = '''
    unit Calculator;

    interface

    uses
      System.SysUtils;

    function Add(const A, B: Integer): Integer;
    function Subtract(const A, B: Integer): Integer;

    implementation

    function Add(const A, B: Integer): Integer;
    begin
      Result := A + B;
    end;

    { Subtraction }
    function Subtract(const A, B: Integer): Integer;
    begin
      Result := A - B;
    end;

    end.
    ''';

  CompareSampleRight = '''
    unit Calculator;

    interface

    uses
      System.Math, System.SysUtils;

    function Add(const A, B: Integer): Integer;
    function Subtract(const A, B: Integer): Integer;
    function Multiply(const A, B: Integer): Integer;

    implementation

    function Add(const A, B: Integer): Integer;
    begin
      Result := A + B;
    end;

    function Subtract(const A, B: Integer): Integer;
    begin
      Result := A - B;
    end;

    function Multiply(const A, B: Integer): Integer;
    begin
      Result := A * B;
    end;

    end.
    ''';

procedure AddFileNamesFromPathIntoComboBox(const APath: string; AComboBox: TComboBox);
var
  LSearchRec: TSearchRec;
begin
  if FindFirst(APath + '*.json', faNormal, LSearchRec) = 0 then
  try
    repeat
      AComboBox.Items.Add(ChangeFileExt(LSearchRec.Name, ''));
    until FindNext(LSearchRec) <> 0;
  finally
    FindClose(LSearchRec);
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FUpdating := True;
  try
    AddFileNamesFromPathIntoComboBox(TDemoPaths.Highlighters, ComboBoxHighlighters);
    AddFileNamesFromPathIntoComboBox(TDemoPaths.Themes, ComboBoxThemes);

    ComboBoxHighlighters.ItemIndex := ComboBoxHighlighters.Items.IndexOf('Object Pascal');
    ComboBoxThemes.ItemIndex := ComboBoxThemes.Items.IndexOf('Default');
  finally
    FUpdating := False;
  end;

  SetSelectedHighlighter;
  SetSelectedColor;

  UpdatePosition;
  UpdateModifiedState;

  PrintPreview.EditorPrint.Header.Add('$TITLE$', nil, taCenter, 1);
  PrintPreview.EditorPrint.Footer.Add('Page $PAGENUM$ of $PAGECOUNT$', nil, taCenter, 1);

  FUpdating := True;
  try
    ComboBoxPreviewScale.ItemIndex := 1;
  finally
    FUpdating := False;
  end;

  PrintPreview.ScaleMode := pscPageWidth;

  FComparing := True;
  try
    EditorCompareLeft.Lines.Text := CompareSampleLeft;
    EditorCompareRight.Lines.Text := CompareSampleRight;
  finally
    FComparing := False;
  end;

  CompareEditors;

  TabControl.OnResize := CompareTabResize;
  CompareTabResize(nil);

  FCompareTimer := TTimer.Create(Self);
  FCompareTimer.Enabled := False;
  FCompareTimer.Interval := 300;
  FCompareTimer.OnTimer := CompareTimerTimer;

  FMacroRecorder := TTextEditorMacroRecorder.Create(Self);
  FMacroRecorder.Editor := TextEditor;
  FMacroRecorder.OnStateChange := MacroRecorderStateChange;

  UpdateMacroMenu;

  FInspectorLayout := TLayout.Create(Self);
  FInspectorLayout.Parent := Self;
  FInspectorLayout.Align := TAlignLayout.Right;
  FInspectorLayout.Width := 350;
  FInspectorLayout.Margins.Left := 0;
  FInspectorLayout.Margins.Top := 3;
  FInspectorLayout.Margins.Right := 3;
  FInspectorLayout.Margins.Bottom := 3;

  FInspectorHeader := TLabel.Create(Self);
  FInspectorHeader.Parent := FInspectorLayout;
  FInspectorHeader.Align := TAlignLayout.Top;
  FInspectorHeader.Margins.Left := 2;
  FInspectorHeader.Margins.Bottom := 2;

  FObjectInspector := TMyObjectInspector.Create(Self);
  FObjectInspector.Parent := FInspectorLayout;
  FObjectInspector.Align := TAlignLayout.Client;
  FObjectInspector.AddUnlistedProperties(['JSON']);

  InspectObject(TextEditor);

  FSplitterRight := TSplitter.Create(Self);
  FSplitterRight.Parent := Self;
  FSplitterRight.Align := TAlignLayout.Right;
  FSplitterRight.ShowGrip := False;
end;

procedure TMainForm.InspectObject(const AObject: TComponent);
begin
  FObjectInspector.InspectedObject := AObject;
  FInspectorHeader.Text := AObject.Name + ': ' + AObject.ClassName;
end;

procedure TMainForm.UpdateCaption;
begin
  Caption := 'TTextEditor FMX Advanced Demo';

  if not FFileName.IsEmpty then
    Caption := Caption + ' - ' + FFileName;
end;

procedure TMainForm.MenuItemOpenClick(Sender: TObject);
begin
  if OpenDialog.Execute then
  begin
    FFileName := OpenDialog.FileName;

    TextEditor.LoadFromFile(FFileName);

    UpdateCaption;
    UpdateModifiedState;
  end;
end;

procedure TMainForm.MenuItemPrintClick(Sender: TObject);
begin
  TabControl.TabIndex := 1;

  if PrintDialog.Execute then
  with PrintPreview.EditorPrint do
  begin
    Copies := PrintDialog.Copies;
    SelectedOnly := PrintDialog.PrintRange = TPrintRange.prSelection;

    if PrintDialog.PrintRange = TPrintRange.prPageNums then
      Print(PrintDialog.FromPage, PrintDialog.ToPage)
    else
      Print;
  end;
end;

procedure TMainForm.MenuItemSaveClick(Sender: TObject);
begin
  if FFileName.IsEmpty then
    MenuItemSaveAsClick(Sender)
  else
  begin
    TextEditor.SaveToFile(FFileName);

    UpdateModifiedState;
  end;
end;

procedure TMainForm.MenuItemSaveAsClick(Sender: TObject);
begin
  if SaveDialog.Execute then
  begin
    FFileName := SaveDialog.FileName;

    TextEditor.SaveToFile(FFileName);

    UpdateCaption;
    UpdateModifiedState;
  end;
end;

procedure TMainForm.MenuItemExportToHTMLClick(Sender: TObject);
begin
  if SaveDialogHTML.Execute then
    TextEditor.ExportToHTML(SaveDialogHTML.FileName);
end;

procedure TMainForm.MenuItemSampleClick(Sender: TObject);
begin
  FFileName := '';

  TextEditor.Lines.Text := TextEditor.Highlighter.Sample;

  UpdateCaption;
  UpdateModifiedState;
end;

procedure TMainForm.MenuItemExitClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.EditSearchChangeTracking(Sender: TObject);
begin
  TextEditor.Search.SearchText := EditSearch.Text;
end;

procedure TMainForm.ButtonFindNextClick(Sender: TObject);
begin
  TextEditor.FindNext;
end;

procedure TMainForm.ButtonFindPreviousClick(Sender: TObject);
begin
  TextEditor.FindPrevious;
end;

procedure TMainForm.MenuItemGoToLineClick(Sender: TObject);
var
  LValues: array [0 .. 0] of string;
  LLine: Integer;
begin
  LValues[0] := '';

  if TDialogServiceSync.InputQuery('Go to line', ['Line number'], LValues) and Integer.TryParse(LValues[0], LLine) then
    TextEditor.GoToLineAndSetPosition(LLine);
end;

{ Bookmarks }

procedure TMainForm.MenuItemBookmarkToggleClick(Sender: TObject);
begin
  TextEditor.ToggleBookmark;
end;

procedure TMainForm.MenuItemBookmarkNextClick(Sender: TObject);
begin
  TextEditor.GoToNextBookmark;
end;

procedure TMainForm.MenuItemBookmarkPreviousClick(Sender: TObject);
begin
  TextEditor.GoToPreviousBookmark;
end;

{ Macro }

procedure TMainForm.MenuItemMacroRecordClick(Sender: TObject);
begin
  TabControl.ActiveTab := TabItemEditor;

  FMacroRecorder.RecordMacro(TextEditor);

  TextEditor.SetFocus;
end;

procedure TMainForm.MenuItemMacroPauseClick(Sender: TObject);
begin
  if FMacroRecorder.State = msPaused then
    FMacroRecorder.Resume
  else
    FMacroRecorder.Pause;
end;

procedure TMainForm.MenuItemMacroStopClick(Sender: TObject);
begin
  FMacroRecorder.Stop;
end;

procedure TMainForm.MenuItemMacroPlayClick(Sender: TObject);
begin
  TabControl.ActiveTab := TabItemEditor;

  FMacroRecorder.PlaybackMacro(TextEditor);

  TextEditor.SetFocus;
end;

procedure TMainForm.MacroRecorderStateChange(Sender: TObject);
begin
  UpdateMacroMenu;
end;

procedure TMainForm.UpdateMacroMenu;
begin
  MenuItemMacroRecord.Enabled := FMacroRecorder.State = msStopped;
  MenuItemMacroPause.Enabled := FMacroRecorder.State in [msRecording, msPaused];
  MenuItemMacroPause.IsChecked := FMacroRecorder.State = msPaused;
  MenuItemMacroStop.Enabled := FMacroRecorder.State in [msRecording, msPaused];
  MenuItemMacroPlay.Enabled := (FMacroRecorder.State = msStopped) and not FMacroRecorder.IsEmpty;

  case FMacroRecorder.State of
    msRecording:
      LabelMacroState.Text := 'Recording';
    msPaused:
      LabelMacroState.Text := 'Paused';
  else
    LabelMacroState.Text := '';
  end;
end;

{ Compare }

procedure TMainForm.CompareEditors;
var
  LRows: TList<TCompareRow>;
  LHashesLeft, LHashesRight: TArray<Cardinal>;
  LLcs: TArray<TArray<Integer>>;
  LCountLeft, LCountRight: Integer;
  LIndexLeft, LIndexRight: Integer;
  LLeftRun, LRightRun: Integer;

  procedure AddPendingRows;
  begin
    { A run of left-only lines facing a run of right-only lines is shown as modified rows, the leftover stays one-sided }
    while (LLeftRun > 0) and (LRightRun > 0) do
    begin
      LRows.Add(crModify);
      Dec(LLeftRun);
      Dec(LRightRun);
    end;

    while LLeftRun > 0 do
    begin
      LRows.Add(crLeftOnly);
      Dec(LLeftRun);
    end;

    while LRightRun > 0 do
    begin
      LRows.Add(crRightOnly);
      Dec(LRightRun);
    end;
  end;

begin
  FComparing := True;
  try
    EditorCompareLeft.Lines.ClearCompareFlags;
    EditorCompareRight.Lines.ClearCompareFlags;

    LCountLeft := EditorCompareLeft.Lines.Count;
    LCountRight := EditorCompareRight.Lines.Count;

    SetLength(LHashesLeft, LCountLeft);

    for var LIndex := 0 to LCountLeft - 1 do
      LHashesLeft[LIndex] := Cardinal(THashFNV1a32.GetHashValue(EditorCompareLeft.Lines[LIndex]));

    SetLength(LHashesRight, LCountRight);

    for var LIndex := 0 to LCountRight - 1 do
      LHashesRight[LIndex] := Cardinal(THashFNV1a32.GetHashValue(EditorCompareRight.Lines[LIndex]));

    SetLength(LLcs, LCountLeft + 1, LCountRight + 1);

    for var LLeft := LCountLeft - 1 downto 0 do
    for var LRight := LCountRight - 1 downto 0 do
      LLcs[LLeft, LRight] :=
        if LHashesLeft[LLeft] = LHashesRight[LRight] then
          LLcs[LLeft + 1, LRight + 1] + 1
        else
          Max(LLcs[LLeft + 1, LRight], LLcs[LLeft, LRight + 1]);

    LRows := TList<TCompareRow>.Create;
    try
      LIndexLeft := 0;
      LIndexRight := 0;
      LLeftRun := 0;
      LRightRun := 0;

      while (LIndexLeft < LCountLeft) and (LIndexRight < LCountRight) do
      if LHashesLeft[LIndexLeft] = LHashesRight[LIndexRight] then
      begin
        AddPendingRows;
        LRows.Add(crSame);
        Inc(LIndexLeft);
        Inc(LIndexRight);
      end
      else
      if LLcs[LIndexLeft + 1, LIndexRight] >= LLcs[LIndexLeft, LIndexRight + 1] then
      begin
        Inc(LLeftRun);
        Inc(LIndexLeft);
      end
      else
      begin
        Inc(LRightRun);
        Inc(LIndexRight);
      end;

      Inc(LLeftRun, LCountLeft - LIndexLeft);
      Inc(LRightRun, LCountRight - LIndexRight);
      AddPendingRows;

      EditorCompareLeft.Lines.BeginUpdate;
      EditorCompareRight.Lines.BeginUpdate;
      try
        for var LIndex := 0 to LRows.Count - 1 do
        case LRows[LIndex] of
          crModify:
            begin
              EditorCompareLeft.Lines.IncludeFlag(LIndex, sfModify);
              EditorCompareRight.Lines.IncludeFlag(LIndex, sfModify);
            end;
          crLeftOnly:
            EditorCompareRight.Lines.InsertLine(LIndex, sfEmptyLine);
          crRightOnly:
            EditorCompareLeft.Lines.InsertLine(LIndex, sfEmptyLine);
        end;
      finally
        EditorCompareLeft.Lines.EndUpdate;

        if Assigned(EditorCompareLeft.Lines.OnInserted) then
          EditorCompareLeft.Lines.OnInserted(EditorCompareLeft.Lines, 0, EditorCompareLeft.Lines.Count);

        EditorCompareRight.Lines.EndUpdate;

        if Assigned(EditorCompareRight.Lines.OnInserted) then
          EditorCompareRight.Lines.OnInserted(EditorCompareRight.Lines, 0, EditorCompareRight.Lines.Count);
      end;
    finally
      LRows.Free;
    end;

    CompareScrollBar.Invalidate;
    EditorCompareLeft.Repaint;
    EditorCompareRight.Repaint;
  finally
    FComparing := False;
  end;
end;

procedure TMainForm.CompareEditorChange(Sender: TObject);
begin
  if FComparing or not Assigned(FCompareTimer) then
    Exit;

  FCompareTimer.Enabled := False;
  FCompareTimer.Enabled := True;
end;

procedure TMainForm.CompareTimerTimer(Sender: TObject);
begin
  FCompareTimer.Enabled := False;
  CompareEditors;
end;

procedure TMainForm.CompareEditorCustomLineColors(const ASender: TObject; const ALine: Integer; var AUseColors: Boolean;
  var AForeground: TAlphaColor; var ABackground: TAlphaColor);
var
  LEditor, LOther: TTextEditor;
begin
  LEditor := ASender as TTextEditor;
  LOther := if LEditor = EditorCompareLeft then EditorCompareRight else EditorCompareLeft;

  if (ALine < LEditor.Lines.Count) and (sfModify in LEditor.Lines.Flags[ALine]) or
    (ALine < LOther.Lines.Count) and (sfEmptyLine in LOther.Lines.Flags[ALine]) then
  begin
    AForeground := LEditor.Colors.CompareForeground;
    ABackground := LEditor.Colors.CompareBackground;
    AUseColors := True;
  end;
end;

procedure TMainForm.CompareEditorAfterLinePaint(const ASender: TObject; const ACanvas: TCanvas; const ARect: TRectF;
  const ALineNumber: Integer; const AIsMinimapLine: Boolean);
var
  LEditor: TTextEditor;
  LCanvasState: TCanvasSaveState;
  LX: Single;
begin
  LEditor := ASender as TTextEditor;

  if (ALineNumber < LEditor.Lines.Count) and (sfEmptyLine in LEditor.Lines.Flags[ALineNumber]) then
  begin
    LCanvasState := ACanvas.SaveState;
    try
      ACanvas.IntersectClipRect(ARect);
      ACanvas.Stroke.Kind := TBrushKind.Solid;
      ACanvas.Stroke.Thickness := 1;
      ACanvas.Stroke.Color := LEditor.Colors.CodeFoldingCollapsedLine;

      LX := 8 * Floor((ARect.Left - ARect.Height + ARect.Bottom) / 8) - ARect.Bottom;

      while LX < ARect.Right do
      begin
        ACanvas.DrawLine(PointF(LX, ARect.Bottom), PointF(LX + ARect.Height, ARect.Top), LEditor.AbsoluteOpacity);
        LX := LX + 8;
      end;
    finally
      ACanvas.RestoreState(LCanvasState);
    end;
  end;
end;

procedure TMainForm.CompareTabResize(Sender: TObject);
begin
  if Assigned(EditorCompareLeft.ParentControl) then
    EditorCompareLeft.Width := (EditorCompareLeft.ParentControl.Width - CompareScrollBar.Width) / 2;
end;

procedure TMainForm.CompareEditorScroll(const ASender: TObject; const AScrollBar: TScrollBarKind);
begin
  if AScrollBar = TScrollBarKind.sbVertical then
    CompareScrollBar.TopLine := (ASender as TTextEditor).TopLine;
end;

{ Print preview }

procedure TMainForm.UpdatePageLabel;
begin
  LabelPage.Text := Format('Page %d / %d', [PrintPreview.PageNumber, PrintPreview.PageCount]);
end;

procedure TMainForm.UpdatePrintPreview;
begin
  PrintPreview.EditorPrint.Title := if FFileName.IsEmpty then 'TTextEditor' else ExtractFileName(FFileName);
  PrintPreview.EditorPrint.Editor := TextEditor;
  PrintPreview.UpdatePreview;

  UpdatePageLabel;
end;

procedure TMainForm.TabControlChange(Sender: TObject);
begin
  if csLoading in ComponentState then
    Exit;

  if TabControl.ActiveTab = TabItemPrintPreview then
    UpdatePrintPreview;

  if TabControl.ActiveTab = TabItemCompare then
    CompareScrollBar.Invalidate;

  if Assigned(FObjectInspector) then
  begin
    if TabControl.ActiveTab = TabItemPrintPreview then
      InspectObject(PrintPreview)
    else
    if TabControl.ActiveTab = TabItemCompare then
      InspectObject(CompareScrollBar)
    else
      InspectObject(TextEditor);
  end;
end;

procedure TMainForm.PrintPreviewPreviewPage(ASender: TObject; APageNumber: Integer);
begin
  UpdatePageLabel;
end;

procedure TMainForm.ButtonPageFirstClick(Sender: TObject);
begin
  PrintPreview.FirstPage;
end;

procedure TMainForm.ButtonPagePreviousClick(Sender: TObject);
begin
  PrintPreview.PreviousPage;
end;

procedure TMainForm.ButtonPageNextClick(Sender: TObject);
begin
  PrintPreview.NextPage;
end;

procedure TMainForm.ButtonPageLastClick(Sender: TObject);
begin
  PrintPreview.LastPage;
end;

procedure TMainForm.ComboBoxPreviewScaleChange(Sender: TObject);
begin
  if FUpdating then
    Exit;

  case ComboBoxPreviewScale.ItemIndex of
    0:
      PrintPreview.ScaleMode := pscWholePage;
    1:
      PrintPreview.ScaleMode := pscPageWidth;
  else
    PrintPreview.ScalePercent := ComboBoxPreviewScale.Items[ComboBoxPreviewScale.ItemIndex].Replace(' %', '').ToInteger;
  end;
end;

procedure TMainForm.CheckBoxPreviewOptionChange(Sender: TObject);
begin
  if FUpdating or (csLoading in ComponentState) then
    Exit;

  PrintPreview.EditorPrint.Colors := CheckBoxColors.IsChecked;
  PrintPreview.EditorPrint.LineNumbers := CheckBoxLineNumbers.IsChecked;
  PrintPreview.EditorPrint.WordWrap := CheckBoxWordWrap.IsChecked;
  PrintPreview.EditorPrint.Highlight := CheckBoxHighlight.IsChecked;

  UpdatePrintPreview;
end;

procedure TMainForm.SetSelectedColor;
var
  LFileName: string;
begin
  if ComboBoxThemes.ItemIndex >= 0 then
  begin
    LFileName := TDemoPaths.Themes + ComboBoxThemes.Items[ComboBoxThemes.ItemIndex] + '.json';

    TextEditor.Highlighter.Colors.LoadFromFile(LFileName);
    EditorCompareLeft.Highlighter.Colors.LoadFromFile(LFileName);
    EditorCompareRight.Highlighter.Colors.LoadFromFile(LFileName);

    CompareScrollBar.Invalidate;
  end;
end;

procedure TMainForm.SetSelectedHighlighter;
var
  LFileName: string;
begin
  if ComboBoxHighlighters.ItemIndex >= 0 then
  begin
    LFileName := TDemoPaths.Highlighters + ComboBoxHighlighters.Items[ComboBoxHighlighters.ItemIndex] + '.json';

    TextEditor.Highlighter.LoadFromFile(LFileName);
    EditorCompareLeft.Highlighter.LoadFromFile(LFileName);
    EditorCompareRight.Highlighter.LoadFromFile(LFileName);
  end;

  if FFileName.IsEmpty then
    TextEditor.Lines.Text := TextEditor.Highlighter.Sample;
end;

procedure TMainForm.ComboBoxHighlightersChange(Sender: TObject);
begin
  if not FUpdating then
    SetSelectedHighlighter;
end;

procedure TMainForm.ComboBoxThemesChange(Sender: TObject);
begin
  if not FUpdating then
    SetSelectedColor;
end;

procedure TMainForm.TextEditorCreateHighlighterStream(const ASender: TObject; const AName: string; var AStream: TStream);
begin
  if not AName.IsEmpty then
    AStream := TFileStream.Create(TDemoPaths.Highlighters + AName + '.json', fmOpenRead);
end;

procedure TMainForm.UpdatePosition;
begin
  LabelPosition.Text := Format('Ln %d: Col %d', [TextEditor.TextPosition.Line + 1, TextEditor.TextPosition.Char]);
end;

procedure TMainForm.UpdateModifiedState;
begin
  LabelModifiedState.Text := if TextEditor.Modified then 'Modified' else '';
end;

procedure TMainForm.TextEditorCaretChanged(const ASender: TObject; const X, Y: Single; const AOffset: Integer);
begin
  UpdatePosition;
end;

procedure TMainForm.TextEditorChange(Sender: TObject);
begin
  UpdateModifiedState;
end;

procedure TMainForm.MenuItemZoomClick(Sender: TObject);
begin
  var LMenuItem := TMenuItem(Sender);

  MenuItemZoom100.IsChecked := LMenuItem = MenuItemZoom100;
  MenuItemZoom125.IsChecked := LMenuItem = MenuItemZoom125;
  MenuItemZoom150.IsChecked := LMenuItem = MenuItemZoom150;
  MenuItemZoom200.IsChecked := LMenuItem = MenuItemZoom200;
  MenuItemZoom300.IsChecked := LMenuItem = MenuItemZoom300;

  TextEditor.ZoomPercentage := Integer(LMenuItem.Tag);

  LabelZoom.Text := 'Zoom: ' + LMenuItem.Text;
end;

procedure TMainForm.StatusBarClick(Sender: TObject);
begin
  PopupMenuZoom.Popup(Screen.MousePos.X, Screen.MousePos.Y);
end;

{ Tests }

const
  cTestCommands: array [0..70] of Integer = (
    TKeyCommands.Char, TKeyCommands.Text, TKeyCommands.Char, TKeyCommands.Text, TKeyCommands.Char, TKeyCommands.Tab, TKeyCommands.ShiftTab,
    TKeyCommands.InsertLine, TKeyCommands.LineBreak, TKeyCommands.DeleteChar, TKeyCommands.Backspace, TKeyCommands.DeleteLine,
    TKeyCommands.DeleteWord, TKeyCommands.Left, TKeyCommands.Right, TKeyCommands.Up, TKeyCommands.Down, TKeyCommands.PageUp,
    TKeyCommands.PageDown, TKeyCommands.SelectionLeft, TKeyCommands.SelectionRight, TKeyCommands.SelectionUp, TKeyCommands.SelectionDown,
    TKeyCommands.LineBegin, TKeyCommands.LineEnd, TKeyCommands.WordLeft, TKeyCommands.WordRight, TKeyCommands.SelectionLineBegin,
    TKeyCommands.SelectionLineEnd, TKeyCommands.SelectionWordLeft, TKeyCommands.SelectionWordRight, TKeyCommands.PageUp,
    TKeyCommands.PageDown, TKeyCommands.SelectionPageUp, TKeyCommands.SelectionPageDown, TKeyCommands.LineComment,
    TKeyCommands.BlockComment, TKeyCommands.BlockIndent, TKeyCommands.BlockUnindent, TKeyCommands.Copy, TKeyCommands.Cut,
    TKeyCommands.Paste, TKeyCommands.MoveLinesUp, TKeyCommands.MoveLinesDown,
    TKeyCommands.DeleteBeginningOfLine, TKeyCommands.DeleteEndOfLine, TKeyCommands.DeleteWhitespaceBackward,
    TKeyCommands.DeleteWhitespaceForward, TKeyCommands.DeleteWordBackward, TKeyCommands.DeleteWordForward,
    TKeyCommands.EditorTop, TKeyCommands.EditorBottom, TKeyCommands.SelectionEditorTop, TKeyCommands.SelectionEditorBottom,
    TKeyCommands.PageTop, TKeyCommands.PageBottom, TKeyCommands.SelectionPageTop, TKeyCommands.SelectionPageBottom,
    TKeyCommands.SelectAll, TKeyCommands.SelectionWord,
    TKeyCommands.UpperCase, TKeyCommands.LowerCase, TKeyCommands.AlternatingCase, TKeyCommands.SentenceCase, TKeyCommands.TitleCase,
    TKeyCommands.UpperCaseBlock, TKeyCommands.LowerCaseBlock, TKeyCommands.AlternatingCaseBlock,
    TKeyCommands.KeywordsUpperCase, TKeyCommands.KeywordsLowerCase, TKeyCommands.KeywordsTitleCase);

  cTestDocumentText = 'a1'#13#10'b2'#13#10'c3'#13#10'd4'#13#10'e5'#13#10;
  cTestDocumentState = 'a1,b2,c3,d4,e5,';
  cSimilarTermColor = TAlphaColor($FFFF00FF);

procedure SetTestClipboardText(const AText: string);
var
  LService: IFMXClipboardService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LService) then
    LService.SetClipboard(AText);
end;

function GetTestClipboardText: string;
var
  LService: IFMXClipboardService;
begin
  Result := '';

  if TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LService) then
    Result := LService.GetClipboard.ToString;
end;

procedure TMainForm.LoadTestDocument;
begin
  TextEditor.Clear;

  var LStringStream := TStringStream.Create(cTestDocumentText);
  try
    TextEditor.LoadFromStream(LStringStream);
  finally
    LStringStream.Free;
  end;
end;

procedure TMainForm.ExecuteTestCommand(const ACommand: Integer; const AViaCommandProcessor: Boolean = False);

  procedure Execute(const ACommand: Integer; const AChar: Char);
  begin
    if AViaCommandProcessor then
      TextEditor.CommandProcessor(ACommand, AChar, nil)
    else
      TextEditor.ExecuteCommand(ACommand, AChar, nil);
  end;

begin
  case ACommand of
    TKeyCommands.Text:
      for var LIndex := 1 to Random(10) + 1 do
        Execute(TKeyCommands.Char, 'c');
  else
    Execute(ACommand, 'a');
  end;
end;

function TMainForm.TestCommandNames(const ASeed, ASkip, ACount: Integer): string;
var
  LIdent: string;
begin
  Result := '';

  RandSeed := ASeed;

  for var LIndex := 1 to ASkip + ACount do
  begin
    EditorCommandToIdent(cTestCommands[Random(Length(cTestCommands))], LIdent);

    if LIndex <= ASkip then
      Continue;

    Result := Result + ', ' + LIdent;
  end;
end;

procedure TMainForm.RunTestLoop(const ASeeds: Integer; const ARun: TFunc<Integer, string>);
var
  LRun: string;
begin
  LabelTestRun.Visible := True;

  for var LIndex := 0 to ASeeds do
  begin
    if LIndex and 127 = 0 then
    begin
      LabelTestRun.Text := LIndex.ToString;
      Application.ProcessMessages;
    end;

    LRun := ARun(LIndex);

    if not LRun.IsEmpty then
    begin
      LabelTestRun.Text := LIndex.ToString + ': ' + LRun;
      SetTestClipboardText(LRun);
      Exit;
    end;
  end;

  ShowMessage('Done.');
  LabelTestRun.Visible := False;
end;

function TMainForm.RunUndoRedoSeed(ASeed: Integer): string;
const
  cActionsCount = 10;
  cSkipCount = 0;
var
  LCommand: TTextEditorCommand;
begin
  LoadTestDocument;
  SetTestClipboardText('b');

  RandSeed := ASeed;

  for var LIndexAction := 1 to cSkipCount + cActionsCount do
  begin
    LCommand := cTestCommands[Random(Length(cTestCommands))];

    if LIndexAction <= cSkipCount then
      Continue;

    ExecuteTestCommand(LCommand);
  end;

  var LFinalState := TextEditor.Lines.CommaText;

  for var LIndex := 1 to cActionsCount do
    TextEditor.ExecuteCommand(TKeyCommands.Undo, #0, nil);

  if TextEditor.Lines.CommaText <> cTestDocumentState then
    Exit('Failed for RandSeed = ' + ASeed.ToString + TestCommandNames(ASeed, cSkipCount, cActionsCount));

  for var LIndex := 1 to cActionsCount do
    TextEditor.ExecuteCommand(TKeyCommands.Redo, #0, nil);

  if (TextEditor.Lines.CommaText <> LFinalState) and (TextEditor.Lines.CommaText <> '""') then
    Exit('Failed Redo for RandSeed = ' + ASeed.ToString + TestCommandNames(ASeed, cSkipCount, cActionsCount));

  Result := '';

  for var LIndex := 1 to cActionsCount do
    TextEditor.ExecuteCommand(TKeyCommands.Undo, #0, nil);
end;

procedure TMainForm.MenuItemTestUndoRedoClick(Sender: TObject);
begin
  RunTestLoop(10000, RunUndoRedoSeed);
end;

function TMainForm.RunSelectionInvariantsSeed(ASeed: Integer): string;
const
  cActionsCount = 6;

  function CheckPosition(const AName: string; const APosition: TTextEditorTextPosition): string;
  begin
    Result := '';

    var LMaxLine := Max(TextEditor.Lines.Count - 1, 0);

    if (APosition.Line < 0) or (APosition.Line > LMaxLine) then
      Result := AName + '.Line = ' + APosition.Line.ToString + ' out of [0, ' + LMaxLine.ToString + ']'
    else
    if APosition.Char < 1 then
      Result := AName + '.Char = ' + APosition.Char.ToString + ' < 1';
  end;

var
  LError: string;
begin
  Result := '';

  LoadTestDocument;
  SetTestClipboardText('b');

  RandSeed := ASeed;

  for var LIndex := 1 to cActionsCount do
  begin
    ExecuteTestCommand(cTestCommands[Random(Length(cTestCommands))]);

    LError := CheckPosition('TextPosition', TextEditor.TextPosition);

    if LError.IsEmpty and TextEditor.SelectionAvailable then
    begin
      LError := CheckPosition('SelectionStart', TextEditor.SelectionStartPosition);

      if LError.IsEmpty then
        LError := CheckPosition('SelectionEnd', TextEditor.SelectionEndPosition);
    end;

    if not LError.IsEmpty then
      Exit('Failed for RandSeed = ' + ASeed.ToString + ' after command ' + LIndex.ToString + ' (' + LError + ')' +
        TestCommandNames(ASeed, 0, cActionsCount));
  end;
end;

procedure TMainForm.MenuItemTestSelectionInvariantsClick(Sender: TObject);
begin
  RunTestLoop(10000, RunSelectionInvariantsSeed);
end;

function TMainForm.RunSaveLoadSeed(ASeed: Integer): string;
const
  cActionsCount = 4;
var
  LText: string;
begin
  Result := '';

  LoadTestDocument;
  SetTestClipboardText('b');

  RandSeed := ASeed;

  for var LIndex := 1 to cActionsCount do
    ExecuteTestCommand(cTestCommands[Random(Length(cTestCommands))]);

  LText := TextEditor.Text;

  var LStream := TMemoryStream.Create;
  try
    TextEditor.SaveToStream(LStream);
    LStream.Position := 0;
    TextEditor.Clear;
    TextEditor.LoadFromStream(LStream);
  finally
    LStream.Free;
  end;

  if TextEditor.Text <> LText then
    Result := 'Failed for RandSeed = ' + ASeed.ToString + TestCommandNames(ASeed, 0, cActionsCount);
end;

procedure TMainForm.MenuItemTestSaveLoadClick(Sender: TObject);
begin
  RunTestLoop(10000, RunSaveLoadSeed);
end;

function TMainForm.RunClipboardRoundTripSeed(ASeed: Integer): string;
var
  LPosition: TTextEditorTextPosition;
  LSelectedText: string;
  LOriginalText: string;

  function Run: string;
  begin
    Result := '';

    LoadTestDocument;

    RandSeed := ASeed;

    LOriginalText := TextEditor.Text;

    LPosition.Char := Random(5) + 1;
    LPosition.Line := Random(TextEditor.Lines.Count);
    TextEditor.TextPosition := LPosition;
    TextEditor.SelectionStartPosition := LPosition;
    LPosition.Char := Random(5) + 1;
    LPosition.Line := Random(TextEditor.Lines.Count);
    TextEditor.SelectionEndPosition := LPosition;

    LSelectedText := TextEditor.SelectedText;

    if LSelectedText.IsEmpty then
      Exit;

    TextEditor.ExecuteCommand(TKeyCommands.Copy, #0, nil);

    if GetTestClipboardText <> LSelectedText then
      Exit('Failed Copy for RandSeed = ' + ASeed.ToString + ', clipboard [' + GetTestClipboardText + '] selected [' + LSelectedText + ']');

    TextEditor.ExecuteCommand(TKeyCommands.Cut, #0, nil);
    TextEditor.ExecuteCommand(TKeyCommands.Paste, #0, nil);

    if TextEditor.Text <> LOriginalText then
      Exit('Failed Cut+Paste for RandSeed = ' + ASeed.ToString);

    TextEditor.ExecuteCommand(TKeyCommands.Undo, #0, nil);
    TextEditor.ExecuteCommand(TKeyCommands.Undo, #0, nil);

    if TextEditor.Text <> LOriginalText then
      Exit('Failed Undo after Cut+Paste for RandSeed = ' + ASeed.ToString);
  end;

begin
  Result := Run;

  for var LAttempt := 1 to 2 do
  begin
    if Result.IsEmpty then
      Break;

    Sleep(10);

    Result := Run;
  end;
end;

procedure TMainForm.MenuItemTestClipboardRoundTripClick(Sender: TObject);
begin
  RunTestLoop(2000, RunClipboardRoundTripSeed);
end;

function TMainForm.RunMacroSeed(ASeed: Integer): string;
const
  cActionsCount = 4;
var
  LFinalText: string;
  LFinalPosition: TTextEditorTextPosition;

  procedure Playback;
  begin
    LoadTestDocument;
    SetTestClipboardText('b');

    FMacroRecorder.PlaybackMacro(TextEditor);
  end;

  function Run: string;
  begin
    Result := '';

    LoadTestDocument;
    SetTestClipboardText('b');

    RandSeed := ASeed;

    FMacroRecorder.RecordMacro(TextEditor);
    try
      for var LIndex := 1 to cActionsCount do
        ExecuteTestCommand(cTestCommands[Random(Length(cTestCommands))], True);
    finally
      FMacroRecorder.Stop;
    end;

    LFinalText := TextEditor.Text;
    LFinalPosition := TextEditor.TextPosition;

    Playback;

    if TextEditor.Text <> LFinalText then
      Exit('Failed playback for RandSeed = ' + ASeed.ToString + TestCommandNames(ASeed, 0, cActionsCount));

    if (TextEditor.TextPosition.Line <> LFinalPosition.Line) or (TextEditor.TextPosition.Char <> LFinalPosition.Char) then
      Exit('Failed playback caret for RandSeed = ' + ASeed.ToString + TestCommandNames(ASeed, 0, cActionsCount));

    var LStream := TMemoryStream.Create;
    try
      FMacroRecorder.SaveToStream(LStream);
      LStream.Position := 0;
      FMacroRecorder.LoadFromStream(LStream);
    finally
      LStream.Free;
    end;

    Playback;

    if TextEditor.Text <> LFinalText then
      Exit('Failed playback after macro save/load for RandSeed = ' + ASeed.ToString + TestCommandNames(ASeed, 0, cActionsCount));
  end;

begin
  Result := Run;

  for var LAttempt := 1 to 2 do
  begin
    if Result.IsEmpty then
      Break;

    Sleep(10);

    Result := Run;
  end;
end;

procedure TMainForm.MenuItemTestMacroClick(Sender: TObject);
begin
  FMacroRecorder.Stop;

  RunTestLoop(2000, RunMacroSeed);

  UpdateMacroMenu;
end;

procedure TMainForm.MenuItemTestHighlighterSweepClick(Sender: TObject);
var
  LHighlighters, LThemes: TArray<string>;
  LCurrentFile: string;
begin
  LabelTestRun.Visible := True;

  LHighlighters := TDirectory.GetFiles(TDemoPaths.Highlighters, '*.json');
  LThemes := TDirectory.GetFiles(TDemoPaths.Themes, '*.json');

  try
    for var LIndex := 0 to High(LHighlighters) do
    begin
      LabelTestRun.Text := Format('%d / %d: %s', [LIndex + 1, Length(LHighlighters), TPath.GetFileName(LHighlighters[LIndex])]);
      Application.ProcessMessages;

      LCurrentFile := LHighlighters[LIndex];
      TextEditor.Highlighter.LoadFromFile(LCurrentFile);
      TextEditor.Lines.Text := TextEditor.Highlighter.Sample;

      for var LTheme in LThemes do
      begin
        LCurrentFile := LTheme;
        TextEditor.Highlighter.Colors.LoadFromFile(LTheme);

        { Loading the colors only invalidates the editor - the paint runs when the messages are processed }
        Application.ProcessMessages;
      end;
    end;
  except
    on E: Exception do
    begin
      var LError := 'Failed loading ' + LCurrentFile + ': ' + E.ClassName + ' ' + E.Message;

      LabelTestRun.Text := LError;
      SetTestClipboardText(LError);

      Exit;
    end;
  end;

  ShowMessage('Done.');

  LabelTestRun.Visible := False;
end;

function TMainForm.RunCaretNavigationSeed(ASeed: Integer): string;
const
  cBookmarkCount = 4;
var
  LPositions: array [0 .. cBookmarkCount - 1] of TTextEditorTextPosition;
  LPosition, LEditPosition: TTextEditorTextPosition;
begin
  Result := '';

  LoadTestDocument;

  RandSeed := ASeed;

  { Caret bookmarks return in last-in-first-out order }
  for var LIndex := 0 to cBookmarkCount - 1 do
  begin
    LPosition.Char := Random(3) + 1;
    LPosition.Line := Random(TextEditor.Lines.Count);
    TextEditor.TextPosition := LPosition;
    LPositions[LIndex] := TextEditor.TextPosition;

    TextEditor.AddCaretBookmark;
  end;

  for var LIndex := cBookmarkCount - 1 downto 0 do
  begin
    TextEditor.ExecuteCommand(TKeyCommands.ReturnToCaretBookmark, #0, nil);

    LPosition := TextEditor.TextPosition;

    if (LPosition.Line <> LPositions[LIndex].Line) or (LPosition.Char <> LPositions[LIndex].Char) then
      Exit('Caret bookmark ' + LIndex.ToString + ' returned to a wrong position for RandSeed = ' + ASeed.ToString);
  end;

  if TextEditor.CaretBookmarks.Count <> 0 then
    Exit('Caret bookmark list is not empty for RandSeed = ' + ASeed.ToString);

  { Swap toggles between the caret and the topmost caret bookmark }
  TextEditor.TextPosition := LPositions[0];
  TextEditor.AddCaretBookmark;
  TextEditor.TextPosition := LPositions[1];
  TextEditor.ExecuteCommand(TKeyCommands.SwapCaretBookmark, #0, nil);

  LPosition := TextEditor.TextPosition;

  if (LPosition.Line <> LPositions[0].Line) or (LPosition.Char <> LPositions[0].Char) then
    Exit('Swap did not move the caret to the bookmark for RandSeed = ' + ASeed.ToString);

  TextEditor.ExecuteCommand(TKeyCommands.SwapCaretBookmark, #0, nil);

  LPosition := TextEditor.TextPosition;

  if (LPosition.Line <> LPositions[1].Line) or (LPosition.Char <> LPositions[1].Char) then
    Exit('Swap did not move the caret back for RandSeed = ' + ASeed.ToString);

  TextEditor.ExecuteCommand(TKeyCommands.ReturnToCaretBookmark, #0, nil);

  { Go to last edit position finds the edit after the caret moved away }
  LPosition.Char := Random(3) + 1;
  LPosition.Line := Random(TextEditor.Lines.Count);
  TextEditor.TextPosition := LPosition;
  TextEditor.ExecuteCommand(TKeyCommands.Char, 'x', nil);
  LEditPosition := TextEditor.TextPosition;

  LPosition.Char := 1;
  LPosition.Line := (LEditPosition.Line + 1) mod TextEditor.Lines.Count;
  TextEditor.TextPosition := LPosition;

  TextEditor.ExecuteCommand(TKeyCommands.GoToLastEditPosition, #0, nil);

  if TextEditor.TextPosition.Line <> LEditPosition.Line then
    Exit('Go to last edit position landed on line ' + TextEditor.TextPosition.Line.ToString + ' instead of ' +
      LEditPosition.Line.ToString + ' for RandSeed = ' + ASeed.ToString);
end;

procedure TMainForm.MenuItemTestCaretNavigationClick(Sender: TObject);
begin
  RunTestLoop(10000, RunCaretNavigationSeed);
end;

function TMainForm.RunPastEndOfFileSeed(ASeed: Integer): string;
const
  cActionsCount = 6;
var
  LPosition: TTextEditorTextPosition;
  LTargetLine: Integer;
begin
  Result := '';

  LoadTestDocument;
  SetTestClipboardText('b');

  RandSeed := ASeed;

  TextEditor.Scroll.Options := TextEditor.Scroll.Options + [soPastEndOfFileMarker];

  if Odd(ASeed) then
    TextEditor.Scroll.Options := TextEditor.Scroll.Options + [soPastEndOfLine]
  else
    TextEditor.Scroll.Options := TextEditor.Scroll.Options - [soPastEndOfLine];

  try
    { Typing on a virtual line past the end of file materializes the missing lines }
    LTargetLine := TextEditor.Lines.Count + Random(5);
    LPosition.Char := Random(6) + 1;
    LPosition.Line := LTargetLine;
    TextEditor.TextPosition := LPosition;

    TextEditor.ExecuteCommand(TKeyCommands.Char, 'w', nil);

    if TextEditor.Lines.Count <= LTargetLine then
      Exit('Typing on a virtual line did not materialize the lines for RandSeed = ' + ASeed.ToString);

    if not TextEditor.Lines[LTargetLine].Contains('w') then
      Exit('Typed character not found on the target line for RandSeed = ' + ASeed.ToString);

    { Random commands with the caret dropped on virtual positions must keep the position valid }
    for var LIndex := 1 to cActionsCount do
    begin
      LPosition.Char := Random(6) + 1;
      LPosition.Line := TextEditor.Lines.Count + Random(3);
      TextEditor.TextPosition := LPosition;

      ExecuteTestCommand(cTestCommands[Random(Length(cTestCommands))]);

      LPosition := TextEditor.TextPosition;

      if (LPosition.Line < 0) or (LPosition.Char < 1) then
        Exit('Invalid caret position after command ' + LIndex.ToString + ' for RandSeed = ' + ASeed.ToString);
    end;
  except
    on E: Exception do
      Exit(E.ClassName + ': ' + E.Message + ' for RandSeed = ' + ASeed.ToString);
  end;
end;

procedure TMainForm.MenuItemTestPastEndOfFileClick(Sender: TObject);
var
  LOptions: TTextEditorScrollOptions;
begin
  LOptions := TextEditor.Scroll.Options;
  try
    RunTestLoop(10000, RunPastEndOfFileSeed);
  finally
    TextEditor.Scroll.Options := LOptions;
  end;
end;

function TMainForm.RunLineBreakIndentSeed(ASeed: Integer): string;
var
  LPosition: TTextEditorTextPosition;
begin
  Result := '';

  RandSeed := ASeed;

  { Repeated line breaks keep the auto indent with and without trimming - only the abandoned lines differ }
  var LTrimTrailingSpaces := Odd(ASeed);

  if LTrimTrailingSpaces then
    TextEditor.Options := TextEditor.Options + [eoTrimTrailingSpaces]
  else
    TextEditor.Options := TextEditor.Options - [eoTrimTrailingSpaces];

  if Random(2) = 0 then
    TextEditor.Scroll.Options := TextEditor.Scroll.Options + [soPastEndOfLine]
  else
    TextEditor.Scroll.Options := TextEditor.Scroll.Options - [soPastEndOfLine];

  var LIndent := StringOfChar(' ', Random(8) + 1);
  var LLineBreakCount := Random(4) + 2;
  var LDocument := LIndent + 'a1';

  if Random(2) = 0 then
    LDocument := LDocument + #13#10'b2'#13#10;

  TextEditor.Clear;

  var LStringStream := TStringStream.Create(LDocument);
  try
    TextEditor.LoadFromStream(LStringStream);
  finally
    LStringStream.Free;
  end;

  var LOriginalText := TextEditor.Text;

  try
    LPosition.Char := LIndent.Length + 3;
    LPosition.Line := 0;
    TextEditor.TextPosition := LPosition;

    for var LIndex := 1 to LLineBreakCount do
      TextEditor.ExecuteCommand(TKeyCommands.LineBreak, #0, nil);

    LPosition := TextEditor.TextPosition;

    if (LPosition.Line <> LLineBreakCount) or (LPosition.Char <> LIndent.Length + 1) then
      Exit('Caret at ' + LPosition.Char.ToString + ', ' + LPosition.Line.ToString + ' lost the indent for RandSeed = ' +
        ASeed.ToString);

    var LAbandonedLine := '';

    if not LTrimTrailingSpaces then
      LAbandonedLine := LIndent;

    for var LLine := 1 to LLineBreakCount - 1 do
    if TextEditor.Lines[LLine] <> LAbandonedLine then
      Exit('Abandoned line ' + LLine.ToString + ' is [' + TextEditor.Lines[LLine] + '] for RandSeed = ' + ASeed.ToString);

    TextEditor.ExecuteCommand(TKeyCommands.Char, 'w', nil);

    if TextEditor.Lines[LLineBreakCount] <> LIndent + 'w' then
      Exit('Typed line is [' + TextEditor.Lines[LLineBreakCount] + '] for RandSeed = ' + ASeed.ToString);

    var LFinalText := TextEditor.Text;

    while TextEditor.CanUndo do
      TextEditor.ExecuteCommand(TKeyCommands.Undo, #0, nil);

    if TextEditor.Text <> LOriginalText then
      Exit('Failed Undo for RandSeed = ' + ASeed.ToString);

    while TextEditor.CanRedo do
      TextEditor.ExecuteCommand(TKeyCommands.Redo, #0, nil);

    if TextEditor.Text <> LFinalText then
      Exit('Failed Redo for RandSeed = ' + ASeed.ToString);
  except
    on E: Exception do
      Exit(E.ClassName + ': ' + E.Message + ' for RandSeed = ' + ASeed.ToString);
  end;
end;

procedure TMainForm.MenuItemTestLineBreakIndentClick(Sender: TObject);
var
  LOptions: TTextEditorOptions;
  LScrollOptions: TTextEditorScrollOptions;
  LTabOptions: TTextEditorTabOptions;
begin
  LOptions := TextEditor.Options;
  LScrollOptions := TextEditor.Scroll.Options;
  LTabOptions := TextEditor.Tabs.Options;

  TextEditor.Options := TextEditor.Options + [eoAutoIndent];
  TextEditor.Tabs.Options := TextEditor.Tabs.Options + [toTabsToSpaces];
  try
    RunTestLoop(10000, RunLineBreakIndentSeed);
  finally
    TextEditor.Options := LOptions;
    TextEditor.Scroll.Options := LScrollOptions;
    TextEditor.Tabs.Options := LTabOptions;
  end;
end;

function TMainForm.RunWordSelectionSeed(ASeed: Integer): string;
const
  cWordCount = 6;
  cCores: array [0 .. 3] of string = ('test', 'name', 'value', 'x1');
  cExpandCharacters = '$%:@';
type
  TTestWord = record
    Core: string;
    CoreBegin: Integer;
    Decorated: string;
    ExpectedSelection: string;
  end;
var
  LWords: array [0 .. cWordCount - 1] of TTestWord;
  LLine: string;
  LUseExpandCharacters: Boolean;
  LPosition: TTextEditorTextPosition;
  LBitmap: TBitmap;
  LBitmapData: TBitmapData;

  function IsHighlighted(const AChar, ALine: Integer): Boolean;
  var
    LCheckPosition: TTextEditorTextPosition;
  begin
    Result := False;

    LCheckPosition.Char := AChar;
    LCheckPosition.Line := ALine;

    var LPoint := TextEditor.ViewPositionToPixels(TextEditor.TextToViewPosition(LCheckPosition));
    var LPixelX := Round((LPoint.X + 2) * LBitmap.BitmapScale);

    if (LPixelX < 0) or (LPixelX >= LBitmapData.Width) then
      Exit;

    for var LOffsetY := 1 to Trunc(TextEditor.LineHeight) - 2 do
    begin
      var LPixelY := Round((LPoint.Y + LOffsetY) * LBitmap.BitmapScale);

      if (LPixelY >= 0) and (LPixelY < LBitmapData.Height) and (LBitmapData.GetPixel(LPixelX, LPixelY) = cSimilarTermColor) then
        Exit(True);
    end;
  end;

begin
  Result := '';

  RandSeed := ASeed;

  LUseExpandCharacters := not Odd(ASeed);

  if LUseExpandCharacters then
    TextEditor.Selection.Options := TextEditor.Selection.Options + [soUseExpandCharacters]
  else
    TextEditor.Selection.Options := TextEditor.Selection.Options - [soUseExpandCharacters];

  LLine := '';

  for var LIndex := 0 to cWordCount - 1 do
  begin
    var LWord: TTestWord;
    LWord.Core := cCores[Random(Length(cCores))];

    var LPrefix := '';

    for var LPrefixIndex := 1 to Random(3) do
      LPrefix := LPrefix + cExpandCharacters[Random(cExpandCharacters.Length) + 1];

    LWord.CoreBegin := LLine.Length + 1;
    LWord.Decorated := LWord.Core;
    LWord.ExpectedSelection := LWord.Core;

    if not LPrefix.IsEmpty then
    case Random(3) of
      0: { Prefix only - $name }
        begin
          LWord.Decorated := LPrefix + LWord.Core;
          LWord.CoreBegin := LWord.CoreBegin + LPrefix.Length;

          if LUseExpandCharacters then
            LWord.ExpectedSelection := LWord.Decorated;
        end;
      1: { Wrapping prefix - %test% - the mirrored trailing characters belong to the selection }
        begin
          LWord.Decorated := LPrefix + LWord.Core + ReverseString(LPrefix);
          LWord.CoreBegin := LWord.CoreBegin + LPrefix.Length;

          if LUseExpandCharacters then
            LWord.ExpectedSelection := LWord.Decorated;
        end;
      2: { Suffix only - never part of the selection }
        LWord.Decorated := LWord.Core + LPrefix;
    end;

    LWords[LIndex] := LWord;
    LLine := LLine + LWord.Decorated + ' ';
  end;

  TextEditor.Text := LLine;

  var LTarget := Random(cWordCount);

  LPosition.Char := LWords[LTarget].CoreBegin + Random(LWords[LTarget].Core.Length);
  LPosition.Line := 0;
  TextEditor.TextPosition := LPosition;
  TextEditor.ExecuteCommand(TKeyCommands.SelectionWord, #0, nil);

  if TextEditor.SelectedText <> LWords[LTarget].ExpectedSelection then
    Exit('Selected [' + TextEditor.SelectedText + '] instead of [' + LWords[LTarget].ExpectedSelection +
      '] for RandSeed = ' + ASeed.ToString);

  if TextEditor.WordAtTextPosition(LPosition) <> LWords[LTarget].ExpectedSelection then
    Exit('Word at text position [' + TextEditor.WordAtTextPosition(LPosition) + '] differs from the selection [' +
      LWords[LTarget].ExpectedSelection + '] for RandSeed = ' + ASeed.ToString);

  { Every 100th seed: the term must highlight as one similar term on another line, expand characters included }
  if LUseExpandCharacters and (ASeed mod 100 = 0) and (LWords[LTarget].ExpectedSelection <> LWords[LTarget].Core) then
  begin
    TextEditor.Text := LLine + sLineBreak + 'zz ' + LWords[LTarget].Decorated + ' qq';
    TextEditor.TextPosition := LPosition;
    TextEditor.ExecuteCommand(TKeyCommands.SelectionWord, #0, nil);

    LBitmap := TextEditor.MakeScreenshot;
    try
      if not LBitmap.Map(TMapAccess.Read, LBitmapData) then
        Exit('Editor screenshot is not readable for RandSeed = ' + ASeed.ToString);

      try
        var LOccurrenceBegin := 4;
        var LOccurrenceEnd := LOccurrenceBegin + LWords[LTarget].Decorated.Length - 1;

        if not IsHighlighted(LOccurrenceBegin, 1) or not IsHighlighted(LOccurrenceEnd, 1) then
          Exit('Similar term [' + LWords[LTarget].Decorated + '] is not highlighted for RandSeed = ' + ASeed.ToString);

        if IsHighlighted(1, 1) then
          Exit('Text outside the similar term [' + LWords[LTarget].Decorated + '] is highlighted for RandSeed = ' +
            ASeed.ToString);
      finally
        LBitmap.Unmap(LBitmapData);
      end;
    finally
      LBitmap.Free;
    end;
  end;
end;

procedure TMainForm.MenuItemTestWordSelectionClick(Sender: TObject);
var
  LOptions: TTextEditorSelectionOptions;
  LColor: TAlphaColor;
begin
  TabControl.ActiveTab := TabItemEditor;

  LOptions := TextEditor.Selection.Options;
  LColor := TextEditor.Colors.SearchHighlighterBackground;

  { Similar term highlighting compares highlighter tokens - the default empty highlighter has no usable tokens }
  TextEditor.Highlighter.LoadFromFile(TDemoPaths.Highlighters + 'Object Pascal.json');

  TextEditor.Selection.Options := TextEditor.Selection.Options + [soHighlightSimilarTerms] -
    [soExpandRealNumbers, soTermsCaseSensitive];
  TextEditor.Colors.SearchHighlighterBackground := cSimilarTermColor;
  try
    RunTestLoop(10000, RunWordSelectionSeed);
  finally
    TextEditor.Selection.Options := LOptions;
    TextEditor.Colors.SearchHighlighterBackground := LColor;
  end;
end;

function TMainForm.RunMultiCaretEditingSeed(ASeed: Integer): string;
const
  cMaxLineCount = 5;
  cMaxLineLength = 6;
  cMaxCaretCount = 5;
  cMaxCommandCount = 8;
  cBackspace = 'B';
  cDelete = 'D';
var
  LInitialText, LText, LInitialCarets, LCommands: string;
  LOffsets: TList<Integer>;
  LCommand: Char;
  LCaretsActive: Boolean;

  function Failure(const AMessage: string): string;
  begin
    Result := AMessage + ' for RandSeed = ' + ASeed.ToString + ', text [' + LInitialText.Replace(#10, '|') + '], carets ' +
      LInitialCarets + ', commands ' + LCommands;
  end;

  function CaretsToString(const ATextPositions: TArray<TTextEditorTextPosition>): string;
  begin
    Result := '';

    for var LTextPosition in ATextPositions do
      Result := Result + Format('(%d,%d)', [LTextPosition.Line, LTextPosition.Char]);
  end;

  function EditorCarets: string;
  begin
    Result := CaretsToString(TextEditor.GetMultiCaretTextPositions);
  end;

  function EditorText: string;
  begin
    Result := '';

    for var LLine := 0 to TextEditor.Lines.Count - 1 do
    begin
      if LLine > 0 then
        Result := Result + #10;

      Result := Result + TextEditor.Lines[LLine];
    end;
  end;

  function ModelCarets: TArray<TTextEditorTextPosition>;
  begin
    SetLength(Result, LOffsets.Count);

    for var LIndex := 0 to LOffsets.Count - 1 do
    begin
      Result[LIndex].Line := 0;
      Result[LIndex].Char := 1;

      for var LPosition := 1 to LOffsets[LIndex] do
      if LText[LPosition] = #10 then
      begin
        Inc(Result[LIndex].Line);
        Result[LIndex].Char := 1;
      end
      else
        Inc(Result[LIndex].Char);
    end;
  end;

  procedure ApplyToModel(const ACommand: Char);
  var
    LOffset, LChange: Integer;
  begin
    for var LIndex1 := LOffsets.Count - 1 downto 0 do
    begin
      LOffset := LOffsets[LIndex1];
      LChange := 0;

      case ACommand of
        cBackspace:
          if LOffset > 0 then
          begin
            Delete(LText, LOffset, 1);
            LOffsets[LIndex1] := LOffset - 1;
            LChange := -1;
          end;
        cDelete:
          if LOffset < LText.Length then
          begin
            Delete(LText, LOffset + 1, 1);
            LChange := -1;
          end;
      else
        Insert(ACommand, LText, LOffset + 1);
        LOffsets[LIndex1] := LOffset + 1;
        LChange := 1;
      end;

      for var LIndex2 := LIndex1 + 1 to LOffsets.Count - 1 do
        LOffsets[LIndex2] := LOffsets[LIndex2] + LChange;
    end;

    for var LIndex := LOffsets.Count - 1 downto 1 do
    if LOffsets[LIndex] = LOffsets[LIndex - 1] then
      LOffsets.Delete(LIndex);
  end;

begin
  Result := '';

  RandSeed := ASeed;

  TextEditor.WordWrap.Active := Odd(ASeed);

  { The model keeps the document as one string with single line feeds and the carets as offsets into it }
  LInitialText := '';

  for var LLine := 1 to Random(cMaxLineCount) + 1 do
  begin
    if LLine > 1 then
      LInitialText := LInitialText + #10;

    for var LIndex := 1 to Random(cMaxLineLength + 1) do
      LInitialText := LInitialText + Chr(Ord('a') + Random(26));
  end;

  { A trailing empty line would be dropped when the text is assigned to the editor }
  LInitialText := LInitialText + 'z';

  LText := LInitialText;
  LCommands := '';

  LOffsets := TList<Integer>.Create;
  try
    try
      for var LIndex := 1 to Random(cMaxCaretCount - 1) + 2 do
      begin
        var LOffset := Random(LText.Length + 1);

        if not LOffsets.Contains(LOffset) then
          LOffsets.Add(LOffset);
      end;

      if LOffsets.Count < 2 then
        Exit;

      LOffsets.Sort;
      LInitialCarets := CaretsToString(ModelCarets);

      TextEditor.FreeMultiCarets;
      TextEditor.Text := LInitialText.Replace(#10, sLineBreak);
      TextEditor.ClearUndo;
      TextEditor.SetMultiCaretTextPositions(ModelCarets);

      if EditorCarets <> LInitialCarets then
        Exit(Failure('Carets were set to ' + EditorCarets));

      LCaretsActive := True;

      for var LIndex := 1 to Random(cMaxCommandCount) + 1 do
      begin
        case Random(3) of
          0:
            LCommand := cBackspace;
          1:
            LCommand := cDelete;
        else
          LCommand := Chr(Ord('0') + Random(10));
        end;

        LCommands := LCommands + LCommand;

        ApplyToModel(LCommand);

        case LCommand of
          cBackspace:
            TextEditor.CommandProcessor(TKeyCommands.Backspace, #0, nil);
          cDelete:
            TextEditor.CommandProcessor(TKeyCommands.DeleteChar, #0, nil);
        else
          TextEditor.CommandProcessor(TKeyCommands.Char, LCommand, nil);
        end;

        if EditorText <> LText then
          Exit(Failure('Text is [' + EditorText.Replace(#10, '|') + '] instead of [' + LText.Replace(#10, '|') + ']'));

        { Multi-caret editing ends when the carets merge into one }
        if LOffsets.Count < 2 then
        begin
          LCaretsActive := False;

          if not EditorCarets.IsEmpty then
            Exit(Failure('Merged carets left ' + EditorCarets));

          Break;
        end;

        if EditorCarets <> CaretsToString(ModelCarets) then
          Exit(Failure('Carets are ' + EditorCarets + ' instead of ' + CaretsToString(ModelCarets)));
      end;

      TextEditor.CommandProcessor(TKeyCommands.Undo, #0, nil);

      if EditorText <> LInitialText then
        Exit(Failure('Undo left the text as [' + EditorText.Replace(#10, '|') + ']'));

      if LCaretsActive and (EditorCarets <> LInitialCarets) then
        Exit(Failure('Undo left the carets at ' + EditorCarets));

      TextEditor.CommandProcessor(TKeyCommands.Redo, #0, nil);

      if EditorText <> LText then
        Exit(Failure('Redo left the text as [' + EditorText.Replace(#10, '|') + '] instead of [' + LText.Replace(#10, '|') + ']'));

      if LCaretsActive and (EditorCarets <> CaretsToString(ModelCarets)) then
        Exit(Failure('Redo left the carets at ' + EditorCarets + ' instead of ' + CaretsToString(ModelCarets)));
    except
      on E: Exception do
        Exit(Failure(E.ClassName + ': ' + E.Message));
    end;
  finally
    LOffsets.Free;
  end;
end;

procedure TMainForm.MenuItemTestMultiCaretEditingClick(Sender: TObject);
var
  LMultiEditActive, LWordWrapActive: Boolean;
  LUndoOptions: TTextEditorUndoOptions;
begin
  TabControl.ActiveTab := TabItemEditor;

  LMultiEditActive := TextEditor.Caret.MultiEdit.Active;
  LUndoOptions := TextEditor.Undo.Options;
  LWordWrapActive := TextEditor.WordWrap.Active;

  { One undo has to take back the whole command sequence }
  TextEditor.Caret.MultiEdit.Active := True;
  TextEditor.Undo.Options := TextEditor.Undo.Options + [uoGroupUndo];
  try
    RunTestLoop(10000, RunMultiCaretEditingSeed);
  finally
    TextEditor.FreeMultiCarets;

    TextEditor.Caret.MultiEdit.Active := LMultiEditActive;
    TextEditor.Undo.Options := LUndoOptions;
    TextEditor.WordWrap.Active := LWordWrapActive;
  end;
end;

end.
