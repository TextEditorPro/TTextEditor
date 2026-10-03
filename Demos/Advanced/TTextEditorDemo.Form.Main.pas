unit TTextEditorDemo.Form.Main;

interface

uses
  Winapi.Messages, Winapi.Windows, System.Actions, System.Classes, System.ImageList, System.SysUtils, Vcl.ActnCtrls, Vcl.ActnList,
  Vcl.ActnMan, Vcl.ActnMenus, Vcl.BaseImageCollection, Vcl.Buttons, Vcl.ComCtrls, Vcl.Controls, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms,
  Vcl.ImageCollection, Vcl.ImgList, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ToolWin, Vcl.VirtualImageList,
  MyControl.ObjectInspector, TextEditor, TextEditor.Compare.ScrollBar, TextEditor.MacroRecorder, TextEditor.Print,
  TextEditor.Print.Preview, TextEditor.Types, TTextEditorDemo.Frame.PrintPreview, TTextEditorDemo.Frame.SyncEditors,
  TTextEditorDemo.Frame.TextCompare, TTextEditorDemo.Frame.TextEditor;

type
  TMainForm = class(TForm)
    ActionBookmarksNextBookmark: TAction;
    ActionBookmarksPreviousBookmark: TAction;
    ActionBookmarksToggleBookmark: TAction;
    ActionFileExit: TAction;
    ActionFileExportToHTML: TAction;
    ActionFileLoadHighlighterSample: TAction;
    ActionFileOpen: TAction;
    ActionFilePrint: TAction;
    ActionFileSave: TAction;
    ActionFileSaveAs: TAction;
    ActionList: TActionList;
    ActionMacroPause: TAction;
    ActionMacroPlay: TAction;
    ActionMacroRecord: TAction;
    ActionMacroStop: TAction;
    ActionMainMenuBar: TActionMainMenuBar;
    ActionManager: TActionManager;
    ActionSearchGoToLine: TAction;
    ActionTestCaretNavigation: TAction;
    ActionTestClipboardRoundTrip: TAction;
    ActionTestHighlighterSweep: TAction;
    ActionTestMacro: TAction;
    ActionTestPastEndOfFile: TAction;
    ActionTestSaveLoad: TAction;
    ActionTestSelectionInvariants: TAction;
    ActionTestUndoRedo: TAction;
    ActionTestWordSelection: TAction;
    ActionToolBar1: TActionToolBar;
    ActionViewDarkTheme: TAction;
    ActionViewPrintPreview: TAction;
    ActionViewSyncEditors: TAction;
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
    PrintDialog: TPrintDialog;
    SaveDialog: TSaveDialog;
    SaveDialogHTML: TSaveDialog;
    SpeedButtonDarkTheme: TSpeedButton;
    SpeedButtonPrintPreview: TSpeedButton;
    SpeedButtonSyncEditors: TSpeedButton;
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
    procedure ActionFilePrintExecute(Sender: TObject);
    procedure ActionFileSaveAsExecute(Sender: TObject);
    procedure ActionFileSaveExecute(Sender: TObject);
    procedure ActionMacroPauseExecute(Sender: TObject);
    procedure ActionMacroPlayExecute(Sender: TObject);
    procedure ActionMacroRecordExecute(Sender: TObject);
    procedure ActionMacroStopExecute(Sender: TObject);
    procedure ActionSearchGoToLineExecute(Sender: TObject);
    procedure ActionTestCaretNavigationExecute(Sender: TObject);
    procedure ActionTestClipboardRoundTripExecute(Sender: TObject);
    procedure ActionTestHighlighterSweepExecute(Sender: TObject);
    procedure ActionTestMacroExecute(Sender: TObject);
    procedure ActionTestPastEndOfFileExecute(Sender: TObject);
    procedure ActionTestSaveLoadExecute(Sender: TObject);
    procedure ActionTestSelectionInvariantsExecute(Sender: TObject);
    procedure ActionTestUndoRedoExecute(Sender: TObject);
    procedure ActionTestWordSelectionExecute(Sender: TObject);
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
    FFrameSyncEditors: TFrameSyncEditors;
    FFrameTextCompare: TFrameTextCompare;
    FFrameTextEditor: TFrameTextEditor;
    FIsCustomStyleActive: Boolean;
    FMacroRecorder: TTextEditorMacroRecorder;
    FObjectInspector: TMyObjectInspector;
    FSplitterRight: TSplitter;
    FWndProcGuardActive: Boolean;
    function HighlighterForFileName(const AFileName: string): string;
    procedure AddFileNamesFromPathIntoPopupMenu(const APath: string; const APopupMenu: TPopupMenu);
    procedure AddFileNamesFromPathIntoSubPopupMenu(const APath: string; const APopupMenu: TPopupMenu);
    procedure CreateFrames;
    procedure CreateInspector;
    procedure CreateMacroRecorder;
    procedure CreateRightSplitter;
    procedure InitializeHighlightersAndThemes;
    procedure InspectObject(const AObject: TComponent);
    procedure MacroRecorderStateChange(Sender: TObject);
    procedure OpenFile(const AFileName: string);
    procedure SetSelectedHighlighter(const AValue: string);
    procedure SetSelectedTheme(const AValue: string);
    procedure UpdateCaption;
    procedure UpdateMacroActions;
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
  public
    class function Highlighters: string; static;
    class function Themes: string; static;
  end;

class function TDemoPaths.Highlighters: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + '..\..\Highlighters\';
end;

class function TDemoPaths.Themes: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + '..\..\Themes\';
end;

type
  TFileTypeHighlighter = record
    Extensions: string;
    Highlighter: string;
  end;

const
  cFileTypeHighlighters: array [0 .. 109] of TFileTypeHighlighter = (
    (Extensions: '.abap'; Highlighter: 'ABAP'),
    (Extensions: '.as'; Highlighter: 'ActionScript'),
    (Extensions: '.ads;.adb'; Highlighter: 'Ada'),
    (Extensions: '.cls'; Highlighter: 'Apex'),
    (Extensions: '.ino'; Highlighter: 'Arduino'),
    (Extensions: '.asp'; Highlighter: 'ASP'),
    (Extensions: '.hc11;.asc'; Highlighter: 'Assembler - 68HC11'),
    (Extensions: '.a65'; Highlighter: 'Assembler - 6502'),
    (Extensions: '.asm;.s;.nasm'; Highlighter: 'Assembler - x86'),
    (Extensions: '.ahk'; Highlighter: 'AutoHotkey'),
    (Extensions: '.au3'; Highlighter: 'AutoIt v3'),
    (Extensions: '.awk'; Highlighter: 'AWK'),
    (Extensions: '.sh'; Highlighter: 'Bash'),
    (Extensions: '.bat;.cmd'; Highlighter: 'Batch'),
    (Extensions: '.cs'; Highlighter: 'C#'),
    (Extensions: '.cpp;.hpp'; Highlighter: 'C++'),
    (Extensions: '.c;.h'; Highlighter: 'C'),
    (Extensions: '.carbon'; Highlighter: 'Carbon'),
    (Extensions: '.chpl'; Highlighter: 'Chapel'),
    (Extensions: '.clj;.cljs;.cljc;.edn'; Highlighter: 'Clojure'),
    (Extensions: '.cmake'; Highlighter: 'CMake'),
    (Extensions: '.cbl;.cob;.cobol'; Highlighter: 'Cobol'),
    (Extensions: '.coffee'; Highlighter: 'CoffeeScript'),
    (Extensions: '.cp'; Highlighter: 'Component Pascal'),
    (Extensions: '.cf'; Highlighter: 'Command File'),
    (Extensions: '.css'; Highlighter: 'CSS'),
    (Extensions: '.d;.di'; Highlighter: 'D'),
    (Extensions: '.dart'; Highlighter: 'Dart'),
    (Extensions: '.dfm;.fmx'; Highlighter: 'Delphi Form Module'),
    (Extensions: '.diff'; Highlighter: 'Diff'),
    (Extensions: '.dockerfile'; Highlighter: 'Dockerfile'),
    (Extensions: '.dws'; Highlighter: 'DWScript'),
    (Extensions: '.e;.es'; Highlighter: 'Eiffel'),
    (Extensions: '.exs'; Highlighter: 'Elixir'),
    (Extensions: '.elm'; Highlighter: 'Elm'),
    (Extensions: '.erl;.hrl'; Highlighter: 'Erlang'),
    (Extensions: '.ex;.exw;.edb'; Highlighter: 'Euphoria'),
    (Extensions: '.fs'; Highlighter: 'F#'),
    (Extensions: '.f90;.f95;.f03;.f08;.f;.for'; Highlighter: 'Fortran'),
    (Extensions: '.pp;.lpr'; Highlighter: 'Free Pascal'),
    (Extensions: '.bi;.bas'; Highlighter: 'FreeBASIC'),
    (Extensions: '.nc;.gcode'; Highlighter: 'G-code'),
    (Extensions: '.gd'; Highlighter: 'GDScript'),
    (Extensions: '.gitattributes;.gitignore'; Highlighter: 'Git'),
    (Extensions: '.glsl'; Highlighter: 'GLSL'),
    (Extensions: '.go'; Highlighter: 'Go'),
    (Extensions: '.gravity'; Highlighter: 'Gravity'),
    (Extensions: '.groovy;.gvy;.gy;.gsh'; Highlighter: 'Groovy'),
    (Extensions: '.hh;.hck;.hack'; Highlighter: 'Hack'),
    (Extensions: '.hs'; Highlighter: 'Haskell'),
    (Extensions: '.html;.htm'; Highlighter: 'HTML with Scripts'),
    (Extensions: '.ini;.lng'; Highlighter: 'INI'),
    (Extensions: '.iss'; Highlighter: 'Inno Setup'),
    (Extensions: '.java'; Highlighter: 'Java'),
    (Extensions: '.js;.jsx;.mjs'; Highlighter: 'JavaScript'),
    (Extensions: '.json'; Highlighter: 'JSON'),
    (Extensions: '.json5'; Highlighter: 'JSON5'),
    (Extensions: '.jl'; Highlighter: 'Julia'),
    (Extensions: '.kt;.kts'; Highlighter: 'Kotlin'),
    (Extensions: '.lat;.tex;.lex'; Highlighter: 'LaTex'),
    (Extensions: '.lisp'; Highlighter: 'Lisp'),
    (Extensions: '.log'; Highlighter: 'Log file'),
    (Extensions: '.lua'; Highlighter: 'Lua'),
    (Extensions: '.mk;.mak;.make'; Highlighter: 'Makefile'),
    (Extensions: '.md'; Highlighter: 'Markdown'),
    (Extensions: '.matlab'; Highlighter: 'MATLAB'),
    (Extensions: '.eml;.mht'; Highlighter: 'MIME'),
    (Extensions: '.mod;.m2;.def;.mi'; Highlighter: 'Modula-2'),
    (Extensions: '.m3;.i3;.ig;.mg'; Highlighter: 'Modula-3'),
    (Extensions: '.nim'; Highlighter: 'Nim'),
    (Extensions: '.nsi'; Highlighter: 'NSIS'),
    (Extensions: '.obs'; Highlighter: 'Objeck'),
    (Extensions: '.pas;.dpr;.dpk'; Highlighter: 'Object Pascal'),
    (Extensions: '.mm'; Highlighter: 'Objective-C++'),
    (Extensions: '.m'; Highlighter: 'Objective-C'),
    (Extensions: '.ml'; Highlighter: 'OCaml'),
    (Extensions: '.odin'; Highlighter: 'Odin'),
    (Extensions: '.pl;.pm;.cgi'; Highlighter: 'Perl'),
    (Extensions: '.php;.class;.inc'; Highlighter: 'PHP'),
    (Extensions: '.pine'; Highlighter: 'Pine Script'),
    (Extensions: '.ps1'; Highlighter: 'PowerShell'),
    (Extensions: '.pb;.pbp'; Highlighter: 'PureBasic'),
    (Extensions: '.py;.pyi'; Highlighter: 'Python'),
    (Extensions: '.r;.rdata;.rds;.rda'; Highlighter: 'R'),
    (Extensions: '.rkt'; Highlighter: 'Racket'),
    (Extensions: '.red;.reds'; Highlighter: 'Red'),
    (Extensions: '.reg'; Highlighter: 'Registry'),
    (Extensions: '.rtf'; Highlighter: 'Rich Text Format'),
    (Extensions: '.rb;.rbw'; Highlighter: 'Ruby'),
    (Extensions: '.rs;.rc'; Highlighter: 'Rust'),
    (Extensions: '.scala'; Highlighter: 'Scala'),
    (Extensions: '.sol'; Highlighter: 'Solidity'),
    (Extensions: '.sql'; Highlighter: 'SQL - Standard'),
    (Extensions: '.st;.iecst'; Highlighter: 'Structured Text'),
    (Extensions: '.swift'; Highlighter: 'Swift'),
    (Extensions: '.tcl'; Highlighter: 'TclTk'),
    (Extensions: '.txt'; Highlighter: 'Text'),
    (Extensions: '.toml'; Highlighter: 'TOML'),
    (Extensions: '.ts;.tsx'; Highlighter: 'TypeScript'),
    (Extensions: '.uc'; Highlighter: 'UnrealScript'),
    (Extensions: '.v'; Highlighter: 'V'),
    (Extensions: '.vbs'; Highlighter: 'VBScript'),
    (Extensions: '.vb'; Highlighter: 'Visual Basic'),
    (Extensions: '.prg;.pjx'; Highlighter: 'Visual FoxPro'),
    (Extensions: '.vrc;.vrcm'; Highlighter: 'VRCalc++'),
    (Extensions: '.vtl'; Highlighter: 'VTL'),
    (Extensions: '.xml;.xsd;.csl;.dtd;.cbproj;.dproj;.groupproj;.form;.opml;.rdf;.svg;.wxs'; Highlighter: 'XML'),
    (Extensions: '.xsl;.xslt'; Highlighter: 'XSL'),
    (Extensions: '.yml;.yaml'; Highlighter: 'YAML'),
    (Extensions: '.zig'; Highlighter: 'Zig'));

var
  FDarkStyleEnabled: Boolean;
  FStyleLoaded: Boolean;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FIsCustomStyleActive := IsCustomStyleActive;

  CreateFrames;
  CreateMacroRecorder;

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
  FFrameSyncEditors.EditorLeft.Highlighter.LoadFromFile(LFileName);
  FFrameSyncEditors.EditorRight.Highlighter.LoadFromFile(LFileName);

  if FFileName.IsEmpty then
    FFrameTextEditor.TextEditor.Lines.Text := FFrameTextEditor.TextEditor.Highlighter.Sample;

  StatusBar.Panels[3].Text := AValue;
end;

procedure TMainForm.SetSelectedTheme(const AValue: string);
var
  LFileName: string;
begin
  LFileName := TDemoPaths.Themes + AValue + '.json';

  FFrameTextEditor.TextEditor.Highlighter.Colors.LoadFromFile(LFileName);
  FFrameTextCompare.EditorCompareLeft.Highlighter.Colors.LoadFromFile(LFileName);
  FFrameTextCompare.EditorCompareRight.Highlighter.Colors.LoadFromFile(LFileName);
  FFrameSyncEditors.EditorLeft.Highlighter.Colors.LoadFromFile(LFileName);
  FFrameSyncEditors.EditorRight.Highlighter.Colors.LoadFromFile(LFileName);

  FFrameTextCompare.CompareScrollBar.Invalidate;

  StatusBar.Panels[4].Text := AValue;
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
  FFrameTextEditor.OnOpenFileRequest := OpenFile;
  FFrameTextEditor.Parent := PanelMain;

  { Text compare }
  FFrameTextCompare := TFrameTextCompare.Create(Self);
  FFrameTextCompare.Visible := False;
  FFrameTextCompare.Parent := PanelMain;

  { Print preview }
  FFramePrintPreview := TFramePrintPreview.Create(Self);
  FFramePrintPreview.Visible := False;
  FFramePrintPreview.Parent := PanelMain;

  { Sync editors }
  FFrameSyncEditors := TFrameSyncEditors.Create(Self);
  FFrameSyncEditors.Visible := False;
  FFrameSyncEditors.Parent := PanelMain;
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

procedure TMainForm.CreateMacroRecorder;
begin
  FMacroRecorder := TTextEditorMacroRecorder.Create(Self);
  FMacroRecorder.Editor := FFrameTextEditor.TextEditor;
  FMacroRecorder.OnStateChange := MacroRecorderStateChange;

  UpdateMacroActions;
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

  StatusBar.Panels[2].Text := 'Zoom: ' + TMenuItem(Sender).Caption;
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
    OpenFile(OpenDialog.FileName);
end;

procedure TMainForm.ActionFilePrintExecute(Sender: TObject);
begin
  ActionViewExecute(ActionViewPrintPreview);

  if PrintDialog.Execute(Handle) then
  with FFramePrintPreview.PrintPreview.EditorPrint do
  begin
    Copies := PrintDialog.Copies;
    SelectedOnly := PrintDialog.PrintRange = prSelection;

    if PrintDialog.PrintRange = prPageNums then
      Print(PrintDialog.FromPage, PrintDialog.ToPage)
    else
      Print;
  end;
end;

procedure TMainForm.ActionFileSaveAsExecute(Sender: TObject);
begin
  if SaveDialog.Execute then
  begin
    FFileName := SaveDialog.FileName;

    FFrameTextEditor.TextEditor.SaveToFile(FFileName);
    FFrameTextEditor.OpenDocument(FFileName);
    FFrameTextEditor.DocumentSaved;

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
    FFrameTextEditor.DocumentSaved;

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

{ Macro }

procedure TMainForm.ActionMacroRecordExecute(Sender: TObject);
begin
  if not FFrameTextEditor.Visible then
    ActionViewTextEditor.Execute;

  FMacroRecorder.RecordMacro(FFrameTextEditor.TextEditor);

  FFrameTextEditor.TextEditor.SetFocus;
end;

procedure TMainForm.ActionMacroPauseExecute(Sender: TObject);
begin
  if FMacroRecorder.State = msPaused then
    FMacroRecorder.Resume
  else
    FMacroRecorder.Pause;
end;

procedure TMainForm.ActionMacroStopExecute(Sender: TObject);
begin
  FMacroRecorder.Stop;
end;

procedure TMainForm.ActionMacroPlayExecute(Sender: TObject);
begin
  if not FFrameTextEditor.Visible then
    ActionViewTextEditor.Execute;

  FMacroRecorder.PlaybackMacro(FFrameTextEditor.TextEditor);

  FFrameTextEditor.TextEditor.SetFocus;
end;

function TMainForm.HighlighterForFileName(const AFileName: string): string;
var
  LExtension: string;
  LFileName: string;
begin
  LExtension := ExtractFileExt(AFileName).ToLower;

  if LExtension.IsEmpty then
  begin
    LFileName := ExtractFileName(AFileName).ToLower;

    if LFileName = 'dockerfile' then
      Exit('Dockerfile');

    if LFileName = 'makefile' then
      Exit('Makefile');

    Exit('');
  end;

  for var LIndex := Low(cFileTypeHighlighters) to High(cFileTypeHighlighters) do
  if (';' + cFileTypeHighlighters[LIndex].Extensions + ';').Contains(';' + LExtension + ';') then
    Exit(cFileTypeHighlighters[LIndex].Highlighter);

  Result := '';
end;

procedure TMainForm.OpenFile(const AFileName: string);
var
  LHighlighter: string;
begin
  FFileName := AFileName;

  LHighlighter := HighlighterForFileName(AFileName);

  if not LHighlighter.IsEmpty then
    SetSelectedHighlighter(LHighlighter);

  FFrameTextEditor.TextEditor.LoadFromFile(FFileName);
  FFrameTextEditor.OpenDocument(FFileName);

  UpdateCaption;
  UpdateModifiedState;
end;

procedure TMainForm.MacroRecorderStateChange(Sender: TObject);
begin
  UpdateMacroActions;
end;

procedure TMainForm.UpdateMacroActions;
begin
  ActionMacroRecord.Enabled := FMacroRecorder.State = msStopped;
  ActionMacroPause.Enabled := FMacroRecorder.State in [msRecording, msPaused];
  ActionMacroPause.Checked := FMacroRecorder.State = msPaused;
  ActionMacroStop.Enabled := FMacroRecorder.State in [msRecording, msPaused];
  ActionMacroPlay.Enabled := (FMacroRecorder.State = msStopped) and not FMacroRecorder.IsEmpty;
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

procedure TMainForm.ActionTestCaretNavigationExecute(Sender: TObject);
begin
  FFrameTextEditor.RunCaretNavigationTest;
end;

procedure TMainForm.ActionTestPastEndOfFileExecute(Sender: TObject);
begin
  FFrameTextEditor.RunPastEndOfFileTest;
end;

procedure TMainForm.ActionTestMacroExecute(Sender: TObject);
begin
  FFrameTextEditor.RunMacroTest(FMacroRecorder);

  UpdateMacroActions;
end;

procedure TMainForm.ActionTestWordSelectionExecute(Sender: TObject);
begin
  if not FFrameTextEditor.Visible then
    ActionViewTextEditor.Execute;

  FFrameTextEditor.RunWordSelectionTest;
end;

procedure TMainForm.ActionViewDarkThemeExecute(Sender: TObject);
begin
  PanelSidebar.SetFocus;

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
        FFramePrintPreview.PrintPreview.EditorPrint.Editor := FFrameTextEditor.TextEditor;
        FFramePrintPreview.UpdatePrintPreview(FFileName);
        InspectObject(FFramePrintPreview.PrintPreview);
        SpeedButtonPrintPreview.Down := True;
      end;
    3:
      begin
        InspectObject(FFrameSyncEditors.EditorLeft);
        SpeedButtonSyncEditors.Down := True;
      end;
  end;

  FFrameTextEditor.Visible := LTag = 0;
  FFrameTextCompare.Visible := LTag = 1;
  FFramePrintPreview.Visible := LTag = 2;
  FFrameSyncEditors.Visible := LTag = 3;
end;

procedure TMainForm.UpdatePosition;
begin
  StatusBar.Panels[0].Text := Format('Ln %d : Col %d', [FFrameTextEditor.TextEditor.TextPosition.Line + 1, FFrameTextEditor.TextEditor.TextPosition.Char]);
end;

procedure TMainForm.UpdateModifiedState;
begin
  StatusBar.Panels[1].Text := if FFrameTextEditor.TextEditor.Modified then 'Modified' else '';
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
    2: PopupMenuZoom.Popup(LPoint.X, LPoint.Y);
    3: PopupMenuHighlighters.Popup(LPoint.X, LPoint.Y);
    4: PopupMenuThemes.Popup(LPoint.X, LPoint.Y);
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

      AlphaBlend := False;
    finally
      FWndProcGuardActive := False;
    end;
  end
  else
    inherited WndProc(AMessage);
end;

end.
