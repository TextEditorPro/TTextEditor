unit TTextEditorDemo.Form.Main;

interface

uses
  System.Classes, System.SysUtils, System.Types, System.UITypes, FMX.Controls, FMX.Controls.Presentation, FMX.Dialogs, FMX.Edit, FMX.Forms,
  FMX.Graphics, FMX.Layouts, FMX.ListBox, FMX.Menus, FMX.Objects, FMX.StdCtrls, FMX.TabControl, FMX.TextEditor,
  FMX.TextEditor.Compare.ScrollBar, FMX.TextEditor.Print, FMX.TextEditor.Print.Preview, FMX.TextEditor.Types, FMX.Types,
  MyControl.ObjectInspector;

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
    MenuItemOpen: TMenuItem;
    MenuItemSample: TMenuItem;
    MenuItemSave: TMenuItem;
    MenuItemSaveAs: TMenuItem;
    MenuItemSearch: TMenuItem;
    MenuItemTest: TMenuItem;
    MenuItemTestClipboardRoundTrip: TMenuItem;
    MenuItemTestHighlighterSweep: TMenuItem;
    MenuItemTestSaveLoad: TMenuItem;
    MenuItemTestSelectionInvariants: TMenuItem;
    MenuItemTestUndoRedo: TMenuItem;
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
    procedure MenuItemOpenClick(Sender: TObject);
    procedure MenuItemSampleClick(Sender: TObject);
    procedure MenuItemSaveAsClick(Sender: TObject);
    procedure MenuItemSaveClick(Sender: TObject);
    procedure MenuItemTestClipboardRoundTripClick(Sender: TObject);
    procedure MenuItemTestHighlighterSweepClick(Sender: TObject);
    procedure MenuItemTestSaveLoadClick(Sender: TObject);
    procedure MenuItemTestSelectionInvariantsClick(Sender: TObject);
    procedure MenuItemTestUndoRedoClick(Sender: TObject);
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
    FObjectInspector: TMyObjectInspector;
    FSplitterRight: TSplitter;
    FUpdating: Boolean;
    FCompareTimer: TTimer;
    function RunClipboardRoundTripSeed(ASeed: Integer): string;
    function RunSaveLoadSeed(ASeed: Integer): string;
    function RunSelectionInvariantsSeed(ASeed: Integer): string;
    function RunUndoRedoSeed(ASeed: Integer): string;
    function TestCommandNames(const ASeed, ACount: Integer): string;
    procedure ExecuteTestCommand(const ACommand: Integer);
    procedure LoadTestDocument;
    procedure RunTestLoop(const ASeeds: Integer; const ARun: TFunc<Integer, string>);
    procedure CompareEditors;
    procedure CompareTabResize(Sender: TObject);
    procedure CompareTimerTimer(Sender: TObject);
    procedure InspectObject(const AObject: TComponent);
    procedure SetSelectedColor;
    procedure SetSelectedHighlighter;
    procedure UpdateCaption;
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
  System.Generics.Collections, System.IOUtils, System.Math, FMX.DialogService.Sync, FMX.Platform, FMX.TextEditor.Consts,
  FMX.TextEditor.KeyCommands, FMX.TextEditor.Lines;

type
  TDemoPaths = record
  const
    Highlighters = '..\..\Highlighters\';
    Themes = '..\..\Themes\';
  end;

  { One row of the aligned compare result }
  TCompareRow = (crSame, crModify, crLeftOnly, crRightOnly);

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

  { Keep the compare editors evenly split around the middle scroll bar }
  TabControl.OnResize := CompareTabResize;
  CompareTabResize(nil);

  { Recompare is deferred - mutating the line lists inside OnChange crashes the editor's own change processing }
  FCompareTimer := TTimer.Create(Self);
  FCompareTimer.Enabled := False;
  FCompareTimer.Interval := 300;
  FCompareTimer.OnTimer := CompareTimerTimer;

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

{ Compare }

procedure TMainForm.CompareEditors;
var
  LRows: TList<TCompareRow>;
  LHashesLeft, LHashesRight: TArray<Cardinal>;
  LLcs: TArray<TArray<Integer>>;
  LCountLeft, LCountRight: Integer;
  LIndexLeft, LIndexRight: Integer;
  LLeftRun, LRightRun: Integer;

  function HashLine(const ALine: string): Cardinal;
  const
    FNV_OFFSET_BASIS = 2166136261;
    FNV_PRIME = 16777619;
  begin
    Result := FNV_OFFSET_BASIS;

    for var LIndex := 1 to ALine.Length do
      Result := (Result xor Cardinal(Ord(ALine[LIndex]))) * FNV_PRIME;
  end;

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
      LHashesLeft[LIndex] := HashLine(EditorCompareLeft.Lines[LIndex]);

    SetLength(LHashesRight, LCountRight);

    for var LIndex := 0 to LCountRight - 1 do
      LHashesRight[LIndex] := HashLine(EditorCompareRight.Lines[LIndex]);

    { Longest common subsequence lengths for line suffixes }
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

  { Modified lines and lines missing from the other file - the placeholder rows themselves get a hatch instead }
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
    { FMX has no hatch brushes - draw the placeholder row's diagonal pattern by hand }
    LCanvasState := ACanvas.SaveState;
    try
      ACanvas.IntersectClipRect(ARect);
      ACanvas.Stroke.Kind := TBrushKind.Solid;
      ACanvas.Stroke.Thickness := 1;
      ACanvas.Stroke.Color := LEditor.Colors.CodeFoldingCollapsedLine;

      { Anchor the diagonals to absolute coordinates (lines x + y = 8n) so the pattern continues seamlessly
        across the rows of a multi-line block at any line height }
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

  { The editors have no size until the tab is shown - refresh the visible line count }
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
  PrintPreview.EditorPrint.Wrap := CheckBoxWordWrap.IsChecked;
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

    { The import turns code folding on when the highlighter defines fold regions. Folding cannot be active in the
      compare editors - the aligned view inserts placeholder lines behind the editor's back, which would desync the
      fold ranges. }
    EditorCompareLeft.CodeFolding.Visible := False;
    EditorCompareRight.CodeFolding.Visible := False;
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

procedure TMainForm.ExecuteTestCommand(const ACommand: Integer);
begin
  case ACommand of
    TKeyCommands.Text:
      for var LIndex := 1 to Random(10) + 1 do
        TextEditor.ExecuteCommand(TKeyCommands.Char, 'c', nil);
  else
    TextEditor.ExecuteCommand(ACommand, 'a', nil);
  end;
end;

function TMainForm.TestCommandNames(const ASeed, ACount: Integer): string;
var
  LIdent: string;
begin
  RandSeed := ASeed;
  Result := '';

  for var LIndex := 1 to ACount do
  begin
    EditorCommandToIdent(cTestCommands[Random(Length(cTestCommands))], LIdent);
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
  cActionsCount = 4;
begin
  LoadTestDocument;
  SetTestClipboardText('b');

  RandSeed := ASeed;

  for var LIndex := 1 to cActionsCount do
    ExecuteTestCommand(cTestCommands[Random(Length(cTestCommands))]);

  var LFinalState := TextEditor.Lines.CommaText;

  for var LIndex := 1 to cActionsCount do
    TextEditor.ExecuteCommand(TKeyCommands.Undo, #0, nil);

  if TextEditor.Lines.CommaText <> cTestDocumentState then
    Exit('Failed for RandSeed = ' + ASeed.ToString + TestCommandNames(ASeed, cActionsCount));

  for var LIndex := 1 to cActionsCount do
    TextEditor.ExecuteCommand(TKeyCommands.Redo, #0, nil);

  if (TextEditor.Lines.CommaText <> LFinalState) and (TextEditor.Lines.CommaText <> '""') then
    Exit('Failed Redo for RandSeed = ' + ASeed.ToString + TestCommandNames(ASeed, cActionsCount));

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
        TestCommandNames(ASeed, cActionsCount));
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
    Result := 'Failed for RandSeed = ' + ASeed.ToString + TestCommandNames(ASeed, cActionsCount);
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
        TextEditor.Repaint;
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

end.
