unit TTextEditorDemo.Frame.TextEditor;

{ Define TEXTEDITOR_LSP to enable the language server panel.
  Requires the LSP-Pascal-Library sources (https://github.com/rickard67/LSP-Pascal-Library) on the search path. }

{.$DEFINE TEXTEDITOR_LSP}

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms, Vcl.StdCtrls, TextEditor,
  TextEditor.MacroRecorder, TextEditor.Types
{$IFDEF TEXTEDITOR_LSP}
  , TextEditor.LanguageServer, TextEditor.LanguageServer.Manager
{$ENDIF};

type
  TOpenFileEvent = procedure(const AFileName: string) of object;

  TFrameTextEditor = class(TFrame)
    ButtonServerStart: TButton;
    ButtonServerStop: TButton;
    EditServerCommandLine: TEdit;
    LabelServerCommandLine: TLabel;
    LabelTestRun: TLabel;
    MemoServerLog: TMemo;
    PanelLanguageServer: TPanel;
    PanelTests: TPanel;
    TextEditor: TTextEditor;
    procedure ButtonServerStartClick(Sender: TObject);
    procedure ButtonServerStopClick(Sender: TObject);
    procedure TextEditorCreateHighlighterStream(const ASender: TObject; const AName: string; var AStream: TStream);
  private
    FClipboardDirty: Boolean;
    FFileName: string;
    FOnOpenFileRequest: TOpenFileEvent;
    FTestMacroRecorder: TCustomEditorMacroRecorder;
{$IFDEF TEXTEDITOR_LSP}
    FLanguageServers: TTextEditorLanguageServers;
    procedure LanguageServerGotoLocation(const ASender: TObject; const AEditor: TCustomTextEditor;
      const ALocation: TTextEditorLanguageServerLocation);
    procedure LanguageServerLog(const ASender: TObject; const AMessage: string);
    procedure LanguageServerStateChange(const ASender: TObject; const AState: TTextEditorLanguageServerState);
    procedure TextEditorKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure UpdateServerButtons;
{$ENDIF}
    function RunCaretNavigationSeed(ASeed: Integer): string;
    function RunClipboardRoundTripSeed(ASeed: Integer): string;
    function RunMacroSeed(ASeed: Integer): string;
    function RunPastEndOfFileSeed(ASeed: Integer): string;
    function RunSaveLoadSeed(ASeed: Integer): string;
    function RunSelectionInvariantsSeed(ASeed: Integer): string;
    function RunUndoRedoSeed(ASeed: Integer): string;
    function RunWordSelectionSeed(ASeed: Integer): string;
    function TestCommandNames(const ASeed, ASkip, ACount: Integer): string;
    procedure ExecuteTestCommand(const ACommand: Integer; const AViaCommandProcessor: Boolean = False);
    procedure LoadTestDocument;
    procedure PrepareTestClipboard;
    procedure RunTestLoop(const ASeeds: Integer; const ARun: TFunc<Integer, string>);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DocumentSaved;
    procedure OpenDocument(const AFileName: string);
    procedure RunCaretNavigationTest;
    procedure RunClipboardRoundTripTest;
    procedure RunHighlighterSweepTest;
    procedure RunMacroTest(const ARecorder: TCustomEditorMacroRecorder);
    procedure RunPastEndOfFileTest;
    procedure RunSaveLoadTest;
    procedure RunSelectionInvariantsTest;
    procedure RunUndoRedoTest;
    procedure RunWordSelectionTest;
    property OnOpenFileRequest: TOpenFileEvent read FOnOpenFileRequest write FOnOpenFileRequest;
{$IFDEF TEXTEDITOR_LSP}
    function ActiveLanguageServer: TTextEditorLanguageServer;
    property LanguageServers: TTextEditorLanguageServers read FLanguageServers;
{$ENDIF}
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils, System.Math, System.StrUtils, Vcl.Clipbrd, Vcl.Dialogs, Vcl.Graphics, TextEditor.KeyCommands, TextEditor.PaintHelper;


procedure TFrameTextEditor.ButtonServerStartClick(Sender: TObject);
begin
{$IFDEF TEXTEDITOR_LSP}
  if FFileName.IsEmpty then
  begin
    MemoServerLog.Lines.Add('Open a file first so the server gets a document and a root folder.');
    Exit;
  end;

  var LDefinition := FLanguageServers.DefinitionForFileName(FFileName);

  if not Assigned(LDefinition) then
  begin
    MemoServerLog.Lines.Add('No language server registered for this file type.');
    Exit;
  end;

  LDefinition.CommandLine := EditServerCommandLine.Text;

  FLanguageServers.Attach(TextEditor, FFileName);
  UpdateServerButtons;
{$ENDIF}
end;

procedure TFrameTextEditor.ButtonServerStopClick(Sender: TObject);
begin
{$IFDEF TEXTEDITOR_LSP}
  FLanguageServers.Detach(TextEditor);
  UpdateServerButtons;
{$ENDIF}
end;

{$IFDEF TEXTEDITOR_LSP}

constructor TFrameTextEditor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FLanguageServers := TTextEditorLanguageServers.Create(Self);
  FLanguageServers.OnGotoLocation := LanguageServerGotoLocation;
  FLanguageServers.OnLog := LanguageServerLog;
  FLanguageServers.OnStateChange := LanguageServerStateChange;
  FLanguageServers.DetectInstalledServers;

  TextEditor.OnKeyDown := TextEditorKeyDown;
end;

destructor TFrameTextEditor.Destroy;
begin
  FLanguageServers.StopAll;

  inherited Destroy;
end;

function TFrameTextEditor.ActiveLanguageServer: TTextEditorLanguageServer;
begin
  Result := FLanguageServers.InstanceForEditor(TextEditor);
end;

procedure TFrameTextEditor.DocumentSaved;
begin
  FLanguageServers.DocumentSaved(TextEditor);
end;

procedure TFrameTextEditor.UpdateServerButtons;
var
  LInstance: TTextEditorLanguageServer;
begin
  LInstance := ActiveLanguageServer;

  ButtonServerStart.Enabled := not Assigned(LInstance) or (LInstance.State = lssStopped);
  ButtonServerStop.Enabled := not ButtonServerStart.Enabled;
end;

procedure TFrameTextEditor.OpenDocument(const AFileName: string);
var
  LDefinition: TTextEditorLanguageServerDefinition;
begin
  FFileName := AFileName;

  LDefinition := FLanguageServers.DefinitionForFileName(AFileName);

  if Assigned(LDefinition) then
  begin
    LabelServerCommandLine.Caption := 'Language server: ' + LDefinition.Name;
    EditServerCommandLine.Text := LDefinition.CommandLine;
  end
  else
  begin
    LabelServerCommandLine.Caption := 'Language server: none registered for this file type';
    EditServerCommandLine.Text := '';
  end;

  if ActiveLanguageServer <> nil then
  begin
    FLanguageServers.Attach(TextEditor, AFileName);
    UpdateServerButtons;
  end;
end;

procedure TFrameTextEditor.LanguageServerLog(const ASender: TObject; const AMessage: string);
begin
  MemoServerLog.Lines.Add(AMessage);
end;

procedure TFrameTextEditor.LanguageServerStateChange(const ASender: TObject; const AState: TTextEditorLanguageServerState);
begin
  UpdateServerButtons;
end;

procedure TFrameTextEditor.LanguageServerGotoLocation(const ASender: TObject; const AEditor: TCustomTextEditor;
  const ALocation: TTextEditorLanguageServerLocation);
begin
  if SameText(ALocation.FileName, FFileName) then
    Exit;

  if not Assigned(FOnOpenFileRequest) or not FileExists(ALocation.FileName) then
  begin
    MemoServerLog.Lines.Add(Format('Definition is in %s (%d:%d) - open it to navigate.', [ALocation.FileName,
      ALocation.TextPosition.Line + 1, ALocation.TextPosition.Char]));
    Exit;
  end;

  FOnOpenFileRequest(ALocation.FileName);

  if SameText(FFileName, ALocation.FileName) then
  begin
    TextEditor.GoToLineAndSetPosition(ALocation.TextPosition.Line, ALocation.TextPosition.Char);
    TextEditor.SetFocus;
  end;
end;

procedure TFrameTextEditor.TextEditorKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_F12) and (ssCtrl in Shift) then
  begin
    Key := 0;

    var LInstance := ActiveLanguageServer;

    if Assigned(LInstance) then
      LInstance.GotoDefinition(TextEditor);
  end;
end;

{$ELSE}

constructor TFrameTextEditor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  PanelLanguageServer.Visible := False;
end;

destructor TFrameTextEditor.Destroy;
begin
  inherited Destroy;
end;

procedure TFrameTextEditor.DocumentSaved;
begin
end;

procedure TFrameTextEditor.OpenDocument(const AFileName: string);
begin
  FFileName := AFileName;
end;

{$ENDIF}


procedure TFrameTextEditor.TextEditorCreateHighlighterStream(const ASender: TObject; const AName: string; var AStream: TStream);
begin
  if not AName.IsEmpty then
    AStream := TFileStream.Create(ExtractFilePath(ParamStr(0)) + '..\..\Highlighters\' + AName + '.json', fmOpenRead);
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
    TKeyCommands.Paste, TKeyCommands.MoveLinesUp, TKeyCommands.MoveLinesDown, TKeyCommands.DeleteBeginningOfLine,
    TKeyCommands.DeleteEndOfLine, TKeyCommands.DeleteWhitespaceBackward, TKeyCommands.DeleteWhitespaceForward,
    TKeyCommands.DeleteWordBackward, TKeyCommands.DeleteWordForward, TKeyCommands.EditorTop, TKeyCommands.EditorBottom,
    TKeyCommands.SelectionEditorTop, TKeyCommands.SelectionEditorBottom, TKeyCommands.PageTop, TKeyCommands.PageBottom,
    TKeyCommands.SelectionPageTop, TKeyCommands.SelectionPageBottom, TKeyCommands.SelectAll, TKeyCommands.SelectionWord,
    TKeyCommands.UpperCase, TKeyCommands.LowerCase, TKeyCommands.AlternatingCase, TKeyCommands.SentenceCase, TKeyCommands.TitleCase,
    TKeyCommands.UpperCaseBlock, TKeyCommands.LowerCaseBlock, TKeyCommands.AlternatingCaseBlock, TKeyCommands.KeywordsUpperCase,
    TKeyCommands.KeywordsLowerCase, TKeyCommands.KeywordsTitleCase);

  cTestDocumentText = 'a1'#13#10'b2'#13#10'c3'#13#10'd4'#13#10'e5'#13#10;
  cTestDocumentState = 'a1,b2,c3,d4,e5,';
  cSimilarTermColor = TColor($00FF00FF);

type
  TTestClipboard = class(TPersistent)
  private
    FOpenRefCount: Integer;
    procedure HardClose;
    procedure HardOpen;
  end;

procedure TTestClipboard.HardClose;
begin
  CloseClipboard;

  TTestClipboard(Clipboard).FOpenRefCount:=0;
end;

procedure TTestClipboard.HardOpen;
begin
  while not OpenClipboard(Application.Handle) do
    Sleep(1);

  TTestClipboard(Clipboard).FOpenRefCount := 1;
end;

procedure TFrameTextEditor.LoadTestDocument;
begin
  TextEditor.Clear;

  var LStringStream := TStringStream.Create(cTestDocumentText);
  try
    TextEditor.LoadFromStream(LStringStream);
  finally
    LStringStream.Free;
  end;
end;

procedure TFrameTextEditor.PrepareTestClipboard;
begin
  if not FClipboardDirty then
    Exit;

  TTestClipboard(Clipboard).HardOpen;
  try
    Clipboard.AsText := 'b';
  finally
    TTestClipboard(Clipboard).HardClose;
  end;

  FClipboardDirty := False;
end;

procedure TFrameTextEditor.ExecuteTestCommand(const ACommand: Integer; const AViaCommandProcessor: Boolean = False);

  procedure Execute(const ACommand: Integer; const AChar: Char);
  begin
    if AViaCommandProcessor then
      TextEditor.CommandProcessor(ACommand, AChar, nil)
    else
      TextEditor.ExecuteCommand(ACommand, AChar, nil);
  end;

begin
  case ACommand of
    TKeyCommands.Cut, TKeyCommands.Copy, TKeyCommands.Paste:
      begin
         TTestClipboard(Clipboard).HardOpen;
         try
            Execute(ACommand, 'a');
         finally
            TTestClipboard(Clipboard).HardClose;
         end;

         if ACommand <> TKeyCommands.Paste then
           FClipboardDirty := True;
      end;
    TKeyCommands.Text:
      for var LIndex := 1 to Random(10) + 1 do
        Execute(TKeyCommands.Char, 'c');
  else
    Execute(ACommand, 'a');
  end;
end;

function TFrameTextEditor.TestCommandNames(const ASeed, ASkip, ACount: Integer): string;
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

procedure TFrameTextEditor.RunTestLoop(const ASeeds: Integer; const ARun: TFunc<Integer, string>);
var
  LRun: string;
begin
  PanelTests.Visible := True;
  FClipboardDirty := True;

  for var LIndex := 0 to ASeeds do
  begin
    if LIndex and 127 = 0 then
    begin
      LabelTestRun.Caption := LIndex.ToString;
      Application.ProcessMessages;
    end;

    LRun := ARun(LIndex);

    if not LRun.IsEmpty then
    begin
      LabelTestRun.Caption := LIndex.ToString + ': ' + LRun;
      Clipboard.AsText := LRun;
      Exit;
    end;
  end;

  ShowMessage('Done.');
  PanelTests.Visible := False;
end;

function TFrameTextEditor.RunUndoRedoSeed(ASeed: Integer): string;
const
  cActionsCount = 4;
  cSkipCount = 0;
var
  LCommand: TTextEditorCommand;
begin
  LoadTestDocument;
  PrepareTestClipboard;

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

procedure TFrameTextEditor.RunUndoRedoTest;
begin
  RunTestLoop(10000, RunUndoRedoSeed);
end;

function TFrameTextEditor.RunCaretNavigationSeed(ASeed: Integer): string;
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

procedure TFrameTextEditor.RunCaretNavigationTest;
begin
  RunTestLoop(10000, RunCaretNavigationSeed);
end;

function TFrameTextEditor.RunPastEndOfFileSeed(ASeed: Integer): string;
const
  cActionsCount = 6;
var
  LPosition: TTextEditorTextPosition;
  LTargetLine: Integer;
begin
  Result := '';

  LoadTestDocument;
  PrepareTestClipboard;

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

procedure TFrameTextEditor.RunPastEndOfFileTest;
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

function TFrameTextEditor.RunSelectionInvariantsSeed(ASeed: Integer): string;
const
  cActionsCount = 6;

  function CheckPosition(const AName: string; const APosition: TTextEditorTextPosition): string;
  begin
    Result := '';

    { An empty document still has the caret on line 0 }
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
  PrepareTestClipboard;

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

procedure TFrameTextEditor.RunSelectionInvariantsTest;
begin
  RunTestLoop(10000, RunSelectionInvariantsSeed);
end;

function TFrameTextEditor.RunSaveLoadSeed(ASeed: Integer): string;
const
  cActionsCount = 10;
var
  LText: string;
begin
  Result := '';

  LoadTestDocument;
  PrepareTestClipboard;

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

procedure TFrameTextEditor.RunSaveLoadTest;
begin
  RunTestLoop(10000, RunSaveLoadSeed);
end;

function TFrameTextEditor.RunClipboardRoundTripSeed(ASeed: Integer): string;
var
  LPosition: TTextEditorTextPosition;
  LSelectedText: string;
  LOriginalText: string;
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

  FClipboardDirty := True;

  TTestClipboard(Clipboard).HardOpen;
  try
    TextEditor.ExecuteCommand(TKeyCommands.Copy, #0, nil);

    if Clipboard.AsText <> LSelectedText then
      Exit('Failed Copy for RandSeed = ' + ASeed.ToString + ', clipboard [' + Clipboard.AsText + '] selected [' + LSelectedText + ']');

    TextEditor.ExecuteCommand(TKeyCommands.Cut, #0, nil);
    TextEditor.ExecuteCommand(TKeyCommands.Paste, #0, nil);
  finally
    TTestClipboard(Clipboard).HardClose;
  end;

  if TextEditor.Text <> LOriginalText then
    Exit('Failed Cut+Paste for RandSeed = ' + ASeed.ToString);

  TextEditor.ExecuteCommand(TKeyCommands.Undo, #0, nil);
  TextEditor.ExecuteCommand(TKeyCommands.Undo, #0, nil);

  if TextEditor.Text <> LOriginalText then
    Exit('Failed Undo after Cut+Paste for RandSeed = ' + ASeed.ToString);
end;

procedure TFrameTextEditor.RunClipboardRoundTripTest;
begin
  RunTestLoop(2000, RunClipboardRoundTripSeed);
end;

function TFrameTextEditor.RunMacroSeed(ASeed: Integer): string;
const
  cActionsCount = 4;
var
  LFinalText: string;
  LFinalPosition: TTextEditorTextPosition;

  procedure Playback;
  begin
    LoadTestDocument;

    FClipboardDirty := True;
    PrepareTestClipboard;

    TTestClipboard(Clipboard).HardOpen;
    try
      FTestMacroRecorder.PlaybackMacro(TextEditor);
    finally
      TTestClipboard(Clipboard).HardClose;
    end;
  end;

begin
  Result := '';

  LoadTestDocument;

  FClipboardDirty := True;
  PrepareTestClipboard;

  RandSeed := ASeed;

  FTestMacroRecorder.RecordMacro(TextEditor);
  try
    for var LIndex := 1 to cActionsCount do
      ExecuteTestCommand(cTestCommands[Random(Length(cTestCommands))], True);
  finally
    FTestMacroRecorder.Stop;
  end;

  LFinalText := TextEditor.Text;
  LFinalPosition := TextEditor.TextPosition;

  Playback;

  if TextEditor.Text <> LFinalText then
    Exit('Failed playback for RandSeed = ' + ASeed.ToString + TestCommandNames(ASeed, 0, cActionsCount));

  if (TextEditor.TextPosition.Line <> LFinalPosition.Line) or (TextEditor.TextPosition.Char <> LFinalPosition.Char) then
    Exit('Failed playback caret for RandSeed = ' + ASeed.ToString + TestCommandNames(ASeed, 0, cActionsCount));

  { The macro must survive its own stream format }
  var LStream := TMemoryStream.Create;
  try
    FTestMacroRecorder.SaveToStream(LStream);
    LStream.Position := 0;
    FTestMacroRecorder.LoadFromStream(LStream);
  finally
    LStream.Free;
  end;

  Playback;

  if TextEditor.Text <> LFinalText then
    Exit('Failed playback after macro save/load for RandSeed = ' + ASeed.ToString + TestCommandNames(ASeed, 0, cActionsCount));
end;

procedure TFrameTextEditor.RunMacroTest(const ARecorder: TCustomEditorMacroRecorder);
begin
  FTestMacroRecorder := ARecorder;

  FTestMacroRecorder.Stop;

  RunTestLoop(2000, RunMacroSeed);
end;

procedure TFrameTextEditor.RunHighlighterSweepTest;
var
  LHighlighters, LThemes: TArray<string>;
  LCurrentFile: string;
begin
  PanelTests.Visible := True;

  LHighlighters := TDirectory.GetFiles(ExtractFilePath(ParamStr(0)) + '..\..\Highlighters', '*.json');
  LThemes := TDirectory.GetFiles(ExtractFilePath(ParamStr(0)) + '..\..\Themes', '*.json');

  try
    for var LIndex := 0 to High(LHighlighters) do
    begin
      LabelTestRun.Caption := Format('%d / %d: %s', [LIndex + 1, Length(LHighlighters), TPath.GetFileName(LHighlighters[LIndex])]);
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
      LabelTestRun.Caption := LError;
      Clipboard.AsText := LError;
      Exit;
    end;
  end;

  ShowMessage('Done.');
  PanelTests.Visible := False;
end;

function TFrameTextEditor.RunWordSelectionSeed(ASeed: Integer): string;
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

  function IsHighlighted(const AChar, ALine: Integer): Boolean;
  var
    LCheckPosition: TTextEditorTextPosition;
  begin
    Result := False;

    LCheckPosition.Char := AChar;
    LCheckPosition.Line := ALine;

    var LPoint := TextEditor.ViewPositionToPixels(TextEditor.TextToViewPosition(LCheckPosition));

    for var LOffsetY := 1 to TextEditor.LineHeight - 2 do
    if LBitmap.Canvas.Pixels[LPoint.X + 2, LPoint.Y + LOffsetY] = cSimilarTermColor then
      Exit(True);
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

    LBitmap := TBitmap.Create;
    try
      LBitmap.SetSize(TextEditor.ClientWidth, TextEditor.ClientHeight);

      { A VCL style hook can swallow WM_PAINT sent to a foreign canvas - capture the screen content instead of PaintTo }
      TextEditor.Repaint;

      var LDC := GetDC(TextEditor.Handle);
      try
        BitBlt(LBitmap.Canvas.Handle, 0, 0, TextEditor.ClientWidth, TextEditor.ClientHeight, LDC, 0, 0, SRCCOPY);
      finally
        ReleaseDC(TextEditor.Handle, LDC);
      end;

      var LOccurrenceBegin := 4;
      var LOccurrenceEnd := LOccurrenceBegin + LWords[LTarget].Decorated.Length - 1;

      if not IsHighlighted(LOccurrenceBegin, 1) or not IsHighlighted(LOccurrenceEnd, 1) then
        Exit('Similar term [' + LWords[LTarget].Decorated + '] is not highlighted for RandSeed = ' + ASeed.ToString);

      if IsHighlighted(1, 1) then
        Exit('Text outside the similar term [' + LWords[LTarget].Decorated + '] is highlighted for RandSeed = ' +
          ASeed.ToString);
    finally
      LBitmap.Free;
    end;
  end;
end;

procedure TFrameTextEditor.RunWordSelectionTest;
var
  LOptions: TTextEditorSelectionOptions;
  LColor: TColor;
begin
  LOptions := TextEditor.Selection.Options;
  LColor := TextEditor.Colors.SearchHighlighterBackground;

  { Similar term highlighting compares highlighter tokens - the default empty highlighter has no usable tokens }
  TextEditor.Highlighter.LoadFromFile(ExtractFilePath(ParamStr(0)) + '..\..\Highlighters\Object Pascal.json');

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

end.
