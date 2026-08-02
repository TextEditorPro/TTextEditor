unit TTextEditorDemo.Frame.TextEditor;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms, Vcl.StdCtrls, TextEditor, TextEditor.MacroRecorder;

type
  TFrameTextEditor = class(TFrame)
    LabelTestRun: TLabel;
    PanelTests: TPanel;
    TextEditor: TTextEditor;
    procedure TextEditorCreateHighlighterStream(const ASender: TObject; const AName: string; var AStream: TStream);
  private
    FClipboardDirty: Boolean;
    FTestMacroRecorder: TCustomEditorMacroRecorder;
    function RunClipboardRoundTripSeed(ASeed: Integer): string;
    function RunMacroSeed(ASeed: Integer): string;
    function RunSaveLoadSeed(ASeed: Integer): string;
    function RunSelectionInvariantsSeed(ASeed: Integer): string;
    function RunUndoRedoSeed(ASeed: Integer): string;
    function TestCommandNames(const ASeed, ASkip, ACount: Integer): string;
    procedure ExecuteTestCommand(const ACommand: Integer; const AViaCommandProcessor: Boolean = False);
    procedure LoadTestDocument;
    procedure PrepareTestClipboard;
    procedure RunTestLoop(const ASeeds: Integer; const ARun: TFunc<Integer, string>);
  public
    procedure RunClipboardRoundTripTest;
    procedure RunHighlighterSweepTest;
    procedure RunMacroTest(const ARecorder: TCustomEditorMacroRecorder);
    procedure RunSaveLoadTest;
    procedure RunSelectionInvariantsTest;
    procedure RunUndoRedoTest;
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils, System.Math, Vcl.Clipbrd, Vcl.Dialogs, TextEditor.KeyCommands, TextEditor.Types;

procedure TFrameTextEditor.TextEditorCreateHighlighterStream(const ASender: TObject; const AName: string; var AStream: TStream);
begin
  if not AName.IsEmpty then
    AStream := TFileStream.Create('..\..\Highlighters\' + AName + '.json', fmOpenRead);
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

  { CommandProcessor is the full input path - it notifies hooked command handlers (the macro recorder records through
    them), ExecuteCommand bypasses them }
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
  cActionsCount = 4;
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

  LHighlighters := TDirectory.GetFiles('..\..\Highlighters', '*.json');
  LThemes := TDirectory.GetFiles('..\..\Themes', '*.json');

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

end.
