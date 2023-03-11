unit TextEditor.KeyCommands;

interface

uses
  System.Classes, System.SysUtils, Vcl.Menus;

type
  TKeyCommands = record
  const
    None = 0;
    EditCommandFirst = 501;
    EditCommandLast = 1000;
    { Caret moving }
    Left = 1;
    Right = 2;
    Up = 3;
    Down = 4;
    WordLeft = 5;
    WordRight = 6;
    LineBegin = 7;
    LineEnd = 8;
    PageUp = 9;
    PageDown = 10;
    PageLeft = 11;
    PageRight = 12;
    PageTop = 13;
    PageBottom = 14;
    EditorTop = 15;
    EditorBottom = 16;
    GoToXY = 17;
    { Selection }
    Selection = 100;
    SelectionLeft = Left + Selection;
    SelectionRight = Right + Selection;
    SelectionUp = Up + Selection;
    SelectionDown = Down + Selection;
    SelectionWordLeft = WordLeft + Selection;
    SelectionWordRight = WordRight + Selection;
    SelectionLineBegin = LineBegin + Selection;
    SelectionLineEnd = LineEnd + Selection;
    SelectionPageUp = PageUp + Selection;
    SelectionPageDown = PageDown + Selection;
    SelectionPageLeft = PageLeft + Selection;
    SelectionPageRight = PageRight + Selection;
    SelectionPageTop = PageTop + Selection;
    SelectionPageBottom = PageBottom + Selection;
    SelectionEditorTop = EditorTop + Selection;
    SelectionEditorBottom = EditorBottom + Selection;
    SelectionGoToXY = GoToXY + Selection;
    SelectionWord = Selection + 21;
    SelectAll = Selection + 22;
    { Scrolling }
    ScrollUp = 211;
    ScrollDown = 212;
    ScrollLeft = 213;
    ScrollRight = 214;
    { Mode }
    InsertMode = 221;
    OverwriteMode = 222;
    ToggleMode = 223;
    { Bookmark }
    ToggleBookmark = 300;
    GoToBookmark1 = 310;
    GoToBookmark2 = 311;
    GoToBookmark3 = 312;
    GoToBookmark4 = 313;
    GoToBookmark5 = 314;
    GoToBookmark6 = 315;
    GoToBookmark7 = 316;
    GoToBookmark8 = 317;
    GoToBookmark9 = 318;
    SetBookmark1 = 320;
    SetBookmark2 = 321;
    SetBookmark3 = 322;
    SetBookmark4 = 323;
    SetBookmark5 = 324;
    SetBookmark6 = 325;
    SetBookmark7 = 326;
    SetBookmark8 = 327;
    SetBookmark9 = 328;
    GoToNextBookmark = 330;
    GoToPreviousBookmark = 331;
    { Deletion }
    Backspace = 501;
    Clear = 502;
    DeleteBeginningOfLine = 503;
    DeleteChar = 504;
    DeleteEndOfLine = 505;
    DeleteLine = 506;
    DeleteWhitespaceBackward = 507;
    DeleteWhitespaceForward = 508;
    DeleteWord = 509;
    DeleteWordBackward = 510;
    DeleteWordForward = 511;
    { Insert }
    LineBreak = 512;
    InsertLine = 513;
    Char = 514;
    Text = 515;
    ImeStr = 550;
    { Clipboard }
    Undo = 601;
    Redo = 602;
    Copy = 603;
    Cut = 604;
    Paste = 605;
    { Indent }
    BlockIndent = 610;
    BlockUnindent = 611;
    Tab = 612;
    ShiftTab = 613;
    { Case }
    UpperCase = 620;
    LowerCase = 621;
    AlternatingCase = 622;
    SentenceCase = 623;
    TitleCase = 624;
    UpperCaseBlock = 625;
    LowerCaseBlock = 626;
    AlternatingCaseBlock = 627;
    KeywordsUpperCase = 628;
    KeywordsLowerCase = 629;
    KeywordsTitleCase = 630;
    { Move }
    MoveLineUp = 701;
    MoveLineDown = 702;
    { Search }
    SearchNext = 800;
    SearchPrevious = 801;
    { Comments }
    LineComment = 900;
    BlockComment = 901;
    { Folding }
    FoldingCollapseLine = 910;
    FoldingExpandLine = 911;
    FoldingGoToNext = 912;
    FoldingGoToPrevious = 913;

    UserFirst = 1001;
  end;

  TTextEditorCommand = type Word;

  TTextEditorHookedCommandEvent = procedure(const ASender: TObject; const AAfterProcessing: Boolean; var AHandled: Boolean;
    var ACommand: TTextEditorCommand; var AChar: Char; const Data: Pointer) of object;
  TTextEditorProcessCommandEvent = procedure(const ASender: TObject; var ACommand: TTextEditorCommand; const AChar: Char;
    const AData: Pointer) of object;

  TTextEditorHookedCommandHandler = class(TObject)
  strict private
    FData: Pointer;
    FEvent: TTextEditorHookedCommandEvent;
  public
    constructor Create(AEvent: TTextEditorHookedCommandEvent; AData: pointer);
    function Equals(AEvent: TTextEditorHookedCommandEvent): Boolean; reintroduce;
    property Data: Pointer read FData write FData;
    property Event: TTextEditorHookedCommandEvent read FEvent write FEvent;
  end;

  TTextEditorKeyCommand = class(TCollectionItem)
  strict private
    FCommand: TTextEditorCommand;
    FKey: Word;
    FSecondaryKey: Word;
    FSecondaryShiftState: TShiftState;
    FShiftState: TShiftState;
    function GetSecondaryShortCut: TShortCut;
    function GetShortCut: TShortCut;
    procedure SetCommand(const AValue: TTextEditorCommand);
    procedure SetKey(const AValue: Word);
    procedure SetSecondaryKey(const AValue: Word);
    procedure SetSecondaryShiftState(const AValue: TShiftState);
    procedure SetSecondaryShortCut(const AValue: TShortCut);
    procedure SetShiftState(const AValue: TShiftState);
    procedure SetShortCut(const AValue: TShortCut);
  protected
    function GetDisplayName: string; override;
  public
    procedure Assign(ASource: TPersistent); override;
    property Key: Word read FKey write SetKey;
    property SecondaryKey: Word read FSecondaryKey write SetSecondaryKey;
    property SecondaryShiftState: TShiftState read FSecondaryShiftState write SetSecondaryShiftState;
    property ShiftState: TShiftState read FShiftState write SetShiftState;
  published
    property Command: TTextEditorCommand read FCommand write SetCommand;
    property SecondaryShortCut: TShortCut read GetSecondaryShortCut write SetSecondaryShortCut default 0;
    property ShortCut: TShortCut read GetShortCut write SetShortCut default 0;
  end;

  ETextEditorKeyCommandException = class(Exception);

  TTextEditorKeyCommands = class(TCollection)
  strict private
    FOwner: TPersistent;
    function GetItem(const AIndex: Integer): TTextEditorKeyCommand;
    procedure SetItem(const AIndex: Integer; AValue: TTextEditorKeyCommand);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TPersistent);
    function FindCommand(const ACommand: TTextEditorCommand): Integer;
    function FindKeyCode(const AKeyCode: Word; const AShift: TShiftState): Integer;
    function FindKeyCodes(const AKeyCode: Word; const AShift: TShiftState; const ASecondaryKeycode: Word; const ASecondaryShift: TShiftState): Integer;
    function FindShortcut(const AShortCut: TShortCut): Integer;
    function FindShortcuts(const AShortCut, ASecondaryShortCut: TShortCut): Integer;
    function NewItem: TTextEditorKeyCommand;
    procedure Add(const ACommand: TTextEditorCommand; const AShift: TShiftState; const AKey: Word);
    procedure Assign(ASource: TPersistent); override;
    procedure ResetDefaults;
  public
    property Items[const AIndex: Integer]: TTextEditorKeyCommand read GetItem write SetItem; default;
  end;

function IdentToEditorCommand(const AIdent: string; var ACommand: Integer): Boolean;
function EditorCommandToIdent(ACommand: Integer; var AIdent: string): Boolean;

implementation

uses
  Winapi.Windows, System.UITypes, TextEditor.Language;

type
  TTextEditorCommandString = record
    Value: TTextEditorCommand;
    Name: string;
  end;

const
  EditorCommandStrings: array [0 .. 108] of TTextEditorCommandString = (
    (Value: TKeyCommands.None; Name: 'TKeyCommands.None'),
    (Value: TKeyCommands.Left; Name: 'TKeyCommands.Left'),
    (Value: TKeyCommands.Right; Name: 'TKeyCommands.Right'),
    (Value: TKeyCommands.Up; Name: 'TKeyCommands.Up'),
    (Value: TKeyCommands.Down; Name: 'TKeyCommands.Down'),
    (Value: TKeyCommands.WordLeft; Name: 'TKeyCommands.WordLeft'),
    (Value: TKeyCommands.WordRight; Name: 'TKeyCommands.WordRight'),
    (Value: TKeyCommands.LineBegin; Name: 'TKeyCommands.LineBegin'),
    (Value: TKeyCommands.LineEnd; Name: 'TKeyCommands.LineEnd'),
    (Value: TKeyCommands.PageUp; Name: 'TKeyCommands.PageUp'),
    (Value: TKeyCommands.PageDown; Name: 'TKeyCommands.PageDown'),
    (Value: TKeyCommands.PageLeft; Name: 'TKeyCommands.PageLeft'),
    (Value: TKeyCommands.PageRight; Name: 'TKeyCommands.PageRight'),
    (Value: TKeyCommands.PageTop; Name: 'TKeyCommands.PageTop'),
    (Value: TKeyCommands.PageBottom; Name: 'TKeyCommands.PageBottom'),
    (Value: TKeyCommands.EditorTop; Name: 'TKeyCommands.EditorTop'),
    (Value: TKeyCommands.EditorBottom; Name: 'TKeyCommands.EditorBottom'),
    (Value: TKeyCommands.GoToXY; Name: 'TKeyCommands.GoToXY'),
    (Value: TKeyCommands.SelectionLeft; Name: 'TKeyCommands.SelectionLeft'),
    (Value: TKeyCommands.SelectionRight; Name: 'TKeyCommands.SelectionRight'),
    (Value: TKeyCommands.SelectionUp; Name: 'TKeyCommands.SelectionUp'),
    (Value: TKeyCommands.SelectionDown; Name: 'TKeyCommands.SelectionDown'),
    (Value: TKeyCommands.SelectionWordLeft; Name: 'TKeyCommands.SelectionWordLeft'),
    (Value: TKeyCommands.SelectionWordRight; Name: 'TKeyCommands.SelectionWordRight'),
    (Value: TKeyCommands.SelectionLineBegin; Name: 'TKeyCommands.SelectionLineBegin'),
    (Value: TKeyCommands.SelectionLineEnd; Name: 'TKeyCommands.SelectionLineEnd'),
    (Value: TKeyCommands.SelectionPageUp; Name: 'TKeyCommands.SelectionPageUp'),
    (Value: TKeyCommands.SelectionPageDown; Name: 'TKeyCommands.SelectionPageDown'),
    (Value: TKeyCommands.SelectionPageLeft; Name: 'TKeyCommands.SelectionPageLeft'),
    (Value: TKeyCommands.SelectionPageRight; Name: 'TKeyCommands.SelectionPageRight'),
    (Value: TKeyCommands.SelectionPageTop; Name: 'TKeyCommands.SelectionPageTop'),
    (Value: TKeyCommands.SelectionPageBottom; Name: 'TKeyCommands.SelectionPageBottom'),
    (Value: TKeyCommands.SelectionEditorTop; Name: 'TKeyCommands.SelectionEditorTop'),
    (Value: TKeyCommands.SelectionEditorBottom; Name: 'TKeyCommands.SelectionEditorBottom'),
    (Value: TKeyCommands.SelectionGoToXY; Name: 'TKeyCommands.SelectionGoToXY'),
    (Value: TKeyCommands.SelectionWord; Name: 'TKeyCommands.SelectionWord'),
    (Value: TKeyCommands.SelectAll; Name: 'TKeyCommands.SelectAll'),
    (Value: TKeyCommands.ScrollUp; Name: 'TKeyCommands.ScrollUp'),
    (Value: TKeyCommands.ScrollDown; Name: 'TKeyCommands.ScrollDown'),
    (Value: TKeyCommands.ScrollLeft; Name: 'TKeyCommands.ScrollLeft'),
    (Value: TKeyCommands.ScrollRight; Name: 'TKeyCommands.ScrollRight'),
    (Value: TKeyCommands.Backspace; Name: 'TKeyCommands.Backspace'),
    (Value: TKeyCommands.DeleteChar; Name: 'TKeyCommands.DeleteChar'),
    (Value: TKeyCommands.DeleteWhitespaceForward; Name: 'TKeyCommands.DeleteWhitespaceForward'),
    (Value: TKeyCommands.DeleteWhitespaceBackward; Name: 'TKeyCommands.DeleteWhitespaceBackward'),
    (Value: TKeyCommands.DeleteWord; Name: 'TKeyCommands.DeleteWord'),
    (Value: TKeyCommands.DeleteWordForward; Name: 'TKeyCommands.DeleteWordForward'),
    (Value: TKeyCommands.DeleteWordBackward; Name: 'TKeyCommands.DeleteWordBackward'),
    (Value: TKeyCommands.DeleteBeginningOfLine; Name: 'TKeyCommands.DeleteBeginningOfLine'),
    (Value: TKeyCommands.DeleteEndOfLine; Name: 'TKeyCommands.DeleteEndOfLine'),
    (Value: TKeyCommands.DeleteLine; Name: 'TKeyCommands.DeleteLine'),
    (Value: TKeyCommands.Clear; Name: 'TKeyCommands.Clear'),
    (Value: TKeyCommands.LineBreak; Name: 'TKeyCommands.LineBreak'),
    (Value: TKeyCommands.InsertLine; Name: 'TKeyCommands.InsertLine'),
    (Value: TKeyCommands.Char; Name: 'TKeyCommands.Char'),
    (Value: TKeyCommands.ImeStr; Name: 'TKeyCommands.ImeStr'),
    (Value: TKeyCommands.Undo; Name: 'TKeyCommands.Undo'),
    (Value: TKeyCommands.Redo; Name: 'TKeyCommands.Redo'),
    (Value: TKeyCommands.Cut; Name: 'TKeyCommands.Cut'),
    (Value: TKeyCommands.Copy; Name: 'TKeyCommands.Copy'),
    (Value: TKeyCommands.Paste; Name: 'TKeyCommands.Paste'),
    (Value: TKeyCommands.InsertMode; Name: 'TKeyCommands.InsertMode'),
    (Value: TKeyCommands.OverwriteMode; Name: 'TKeyCommands.OverwriteMode'),
    (Value: TKeyCommands.ToggleMode; Name: 'TKeyCommands.ToggleMode'),
    (Value: TKeyCommands.BlockIndent; Name: 'TKeyCommands.BlockIndent'),
    (Value: TKeyCommands.BlockUnindent; Name: 'TKeyCommands.BlockUnindent'),
    (Value: TKeyCommands.Tab; Name: 'TKeyCommands.Tab'),
    (Value: TKeyCommands.ShiftTab; Name: 'TKeyCommands.ShiftTab'),
    (Value: TKeyCommands.UserFirst; Name: 'TKeyCommands.UserFirst'),
    (Value: TKeyCommands.ToggleBookmark; Name: 'TKeyCommands.ToggleBookmark'),
    (Value: TKeyCommands.GoToBookmark1; Name: 'TKeyCommands.GoToBookmark1'),
    (Value: TKeyCommands.GoToBookmark2; Name: 'TKeyCommands.GoToBookmark2'),
    (Value: TKeyCommands.GoToBookmark3; Name: 'TKeyCommands.GoToBookmark3'),
    (Value: TKeyCommands.GoToBookmark4; Name: 'TKeyCommands.GoToBookmark4'),
    (Value: TKeyCommands.GoToBookmark5; Name: 'TKeyCommands.GoToBookmark5'),
    (Value: TKeyCommands.GoToBookmark6; Name: 'TKeyCommands.GoToBookmark6'),
    (Value: TKeyCommands.GoToBookmark7; Name: 'TKeyCommands.GoToBookmark7'),
    (Value: TKeyCommands.GoToBookmark8; Name: 'TKeyCommands.GoToBookmark8'),
    (Value: TKeyCommands.GoToBookmark9; Name: 'TKeyCommands.GoToBookmark9'),
    (Value: TKeyCommands.SetBookmark1; Name: 'TKeyCommands.SetBookmark1'),
    (Value: TKeyCommands.SetBookmark2; Name: 'TKeyCommands.SetBookmark2'),
    (Value: TKeyCommands.SetBookmark3; Name: 'TKeyCommands.SetBookmark3'),
    (Value: TKeyCommands.SetBookmark4; Name: 'TKeyCommands.SetBookmark4'),
    (Value: TKeyCommands.SetBookmark5; Name: 'TKeyCommands.SetBookmark5'),
    (Value: TKeyCommands.SetBookmark6; Name: 'TKeyCommands.SetBookmark6'),
    (Value: TKeyCommands.SetBookmark7; Name: 'TKeyCommands.SetBookmark7'),
    (Value: TKeyCommands.SetBookmark8; Name: 'TKeyCommands.SetBookmark8'),
    (Value: TKeyCommands.SetBookmark9; Name: 'TKeyCommands.SetBookmark9'),
    (Value: TKeyCommands.GoToNextBookmark; Name: 'TKeyCommands.GoToNextBookmark'),
    (Value: TKeyCommands.GoToPreviousBookmark; Name: 'TKeyCommands.GoToPreviousBookmark'),
    (Value: TKeyCommands.Text; Name: 'TKeyCommands.Text'),
    (Value: TKeyCommands.MoveLineUp; Name: 'TKeyCommands.MoveLineUp'),
    (Value: TKeyCommands.MoveLineDown; Name: 'TKeyCommands.MoveLineDown'),
    (Value: TKeyCommands.UpperCase; Name: 'TKeyCommands.UpperCase'),
    (Value: TKeyCommands.LowerCase; Name: 'TKeyCommands.LowerCase'),
    (Value: TKeyCommands.AlternatingCase; Name: 'TKeyCommands.AlternatingCase'),
    (Value: TKeyCommands.SentenceCase; Name: 'TKeyCommands.SentenceCase'),
    (Value: TKeyCommands.TitleCase; Name: 'TKeyCommands.TitleCase'),
    (Value: TKeyCommands.UpperCaseBlock; Name: 'TKeyCommands.UpperCaseBlock'),
    (Value: TKeyCommands.LowerCaseBlock; Name: 'TKeyCommands.LowerCaseBlock'),
    (Value: TKeyCommands.AlternatingCaseBlock; Name: 'TKeyCommands.AlternatingCaseBlock'),
    (Value: TKeyCommands.SearchNext; Name: 'TKeyCommands.SearchNext'),
    (Value: TKeyCommands.SearchPrevious; Name: 'TKeyCommands.SearchPrevious'),
    (Value: TKeyCommands.LineComment; Name: 'TKeyCommands.LineComment'),
    (Value: TKeyCommands.BlockComment; Name: 'TKeyCommands.BlockComment'),
    (Value: TKeyCommands.FoldingCollapseLine; Name: 'TKeyCommands.FoldingCollapseLine'),
    (Value: TKeyCommands.FoldingExpandLine; Name: 'TKeyCommands.FoldingExpandLine'),
    (Value: TKeyCommands.FoldingGoToNext; Name: 'TKeyCommands.FoldingGoToNext'),
    (Value: TKeyCommands.FoldingGoToPrevious; Name: 'TKeyCommands.FoldingGoToPrevious')
  );

function IdentToEditorCommand(const AIdent: string; var ACommand: Integer): Boolean;
var
  LIndex: Integer;
  LCommandString: TTextEditorCommandString;
begin
  Result := True;

  for LIndex := Low(EditorCommandStrings) to High(EditorCommandStrings) do
  begin
    LCommandString := EditorCommandStrings[LIndex];
    if CompareText(LCommandString.Name, AIdent) = 0 then
    begin
      ACommand := LCommandString.Value;
      Exit;
    end;
  end;

  Result := False;
end;

function EditorCommandToIdent(ACommand: Integer; var AIdent: string): Boolean;
var
  LIndex: Integer;
  LCommandString: TTextEditorCommandString;
begin
  Result := True;

  for LIndex := Low(EditorCommandStrings) to High(EditorCommandStrings) do
  begin
    LCommandString := EditorCommandStrings[LIndex];
    if LCommandString.Value = ACommand then
    begin
      AIdent := LCommandString.Name;
      Exit;
    end;
  end;

  Result := False;
end;

function EditorCommandToCodeString(const ACommand: TTextEditorCommand): string;
begin
  if not EditorCommandToIdent(ACommand, Result) then
    Result := IntToStr(ACommand);
end;

{ TTextEditorHookedCommandHandler }

constructor TTextEditorHookedCommandHandler.Create(AEvent: TTextEditorHookedCommandEvent; AData: pointer);
begin
  inherited Create;

  FEvent := AEvent;
  FData := AData;
end;

function TTextEditorHookedCommandHandler.Equals(AEvent: TTextEditorHookedCommandEvent): Boolean;
var
  LClassMethod, LParamMethod: TMethod;
begin
  LClassMethod := TMethod(FEvent);
  LParamMethod := TMethod(AEvent);
  Result := (LClassMethod.Code = LParamMethod.Code) and (LClassMethod.Data = LParamMethod.Data);
end;

{ TTextEditorKeyCommand }

procedure TTextEditorKeyCommand.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorKeyCommand) then
  with ASource as TTextEditorKeyCommand do
  begin
    Self.FCommand := FCommand;
    Self.FKey := FKey;
    Self.FSecondaryKey := FSecondaryKey;
    Self.FShiftState := FShiftState;
    Self.FSecondaryShiftState := FSecondaryShiftState;
  end
  else
    inherited Assign(ASource);
end;

function TTextEditorKeyCommand.GetDisplayName: string;
begin
  Result := EditorCommandToCodeString(Command) + ' - ' + ShortCutToText(ShortCut);
  if SecondaryShortCut <> 0 then
    Result := Result + ' ' + ShortCutToText(SecondaryShortCut);
  if Result = '' then
    Result := inherited GetDisplayName;
end;

function TTextEditorKeyCommand.GetShortCut: TShortCut;
begin
  Result := Vcl.Menus.ShortCut(Key, ShiftState);
end;

procedure TTextEditorKeyCommand.SetCommand(const AValue: TTextEditorCommand);
begin
  if FCommand <> AValue then
    FCommand := AValue;
end;

procedure TTextEditorKeyCommand.SetKey(const AValue: Word);
begin
  if FKey <> AValue then
    FKey := AValue;
end;

procedure TTextEditorKeyCommand.SetShiftState(const AValue: TShiftState);
begin
  if FShiftState <> AValue then
    FShiftState := AValue;
end;

procedure TTextEditorKeyCommand.SetShortCut(const AValue: TShortCut);
var
  LNewKey: Word;
  LNewShiftState: TShiftState;
  LDuplicate: Integer;
begin
  if AValue <> 0 then
  begin
    LDuplicate := TTextEditorKeyCommands(Collection).FindShortcuts(AValue, SecondaryShortCut);
    if (LDuplicate <> -1) and (LDuplicate <> Self.Index) then
      raise ETextEditorKeyCommandException.Create(STextEditorDuplicateShortcut);
  end;

  Vcl.Menus.ShortCutToKey(AValue, LNewKey, LNewShiftState);

  if (LNewKey <> Key) or (LNewShiftState <> ShiftState) then
  begin
    Key := LNewKey;
    ShiftState := LNewShiftState;
  end;
end;

procedure TTextEditorKeyCommand.SetSecondaryKey(const AValue: Word);
begin
  if FSecondaryKey <> AValue then
    FSecondaryKey := AValue;
end;

procedure TTextEditorKeyCommand.SetSecondaryShiftState(const AValue: TShiftState);
begin
  if FSecondaryShiftState <> AValue then
    FSecondaryShiftState := AValue;
end;

procedure TTextEditorKeyCommand.SetSecondaryShortCut(const AValue: TShortCut);
var
  LNewKey: Word;
  LNewShiftState: TShiftState;
  LDuplicate: Integer;
begin
  if AValue <> 0 then
  begin
    LDuplicate := TTextEditorKeyCommands(Collection).FindShortcuts(ShortCut, AValue);
    if (LDuplicate <> -1) and (LDuplicate <> Self.Index) then
      raise ETextEditorKeyCommandException.Create(STextEditorDuplicateShortcut);
  end;

  Vcl.Menus.ShortCutToKey(AValue, LNewKey, LNewShiftState);
  if (LNewKey <> SecondaryKey) or (LNewShiftState <> SecondaryShiftState) then
  begin
    SecondaryKey := LNewKey;
    SecondaryShiftState := LNewShiftState;
  end;
end;

function TTextEditorKeyCommand.GetSecondaryShortCut: TShortCut;
begin
  Result := Vcl.Menus.ShortCut(SecondaryKey, SecondaryShiftState);
end;

{ TTextEditorKeyCommands }

function TTextEditorKeyCommands.NewItem: TTextEditorKeyCommand;
begin
  Result := TTextEditorKeyCommand(inherited Add);
end;

procedure TTextEditorKeyCommands.Add(const ACommand: TTextEditorCommand; const AShift: TShiftState; const AKey: Word);
var
  LNewKeystroke: TTextEditorKeyCommand;
begin
  LNewKeystroke := NewItem;
  LNewKeystroke.Key := AKey;
  LNewKeystroke.ShiftState := AShift;
  LNewKeystroke.Command := ACommand;
end;

procedure TTextEditorKeyCommands.Assign(ASource: TPersistent);
var
  LIndex: Integer;
  LKeyCommands: TTextEditorKeyCommands;
begin
  if Assigned(ASource) and (ASource is TTextEditorKeyCommands) then
  begin
    LKeyCommands := ASource as TTextEditorKeyCommands;
    Self.Clear;
    for LIndex := 0 to LKeyCommands.Count - 1 do
      NewItem.Assign(LKeyCommands[LIndex]);
  end
  else
    inherited Assign(ASource);
end;

constructor TTextEditorKeyCommands.Create(AOwner: TPersistent);
begin
  inherited Create(TTextEditorKeyCommand);

  FOwner := AOwner;
end;

function TTextEditorKeyCommands.FindCommand(const ACommand: TTextEditorCommand): Integer;
var
  LIndex: Integer;
begin
  Result := -1;
  for LIndex := 0 to Count - 1 do
  if Items[LIndex].Command = ACommand then
    Exit(LIndex);
end;

function TTextEditorKeyCommands.FindKeyCode(const AKeycode: Word;const AShift: TShiftState): Integer;
var
  LIndex: Integer;
  LKeyCommand: TTextEditorKeyCommand;
begin
  Result := -1;
  for LIndex := 0 to Count - 1 do
  begin
    LKeyCommand := Items[LIndex];
    if (LKeyCommand.Key = AKeyCode) and (LKeyCommand.ShiftState = AShift) and (LKeyCommand.SecondaryKey = 0) then
      Exit(LIndex);
  end;
end;

function TTextEditorKeyCommands.FindKeyCodes(const AKeyCode: Word;const AShift: TShiftState;const ASecondaryKeyCode: Word;const ASecondaryShift: TShiftState): Integer;
var
  LIndex: Integer;
  LKeyCommand: TTextEditorKeyCommand;
begin
  Result := -1;
  for LIndex := 0 to Count - 1 do
  begin
    LKeyCommand := Items[LIndex];
    if (LKeyCommand.Key = AKeyCode) and (LKeyCommand.ShiftState = AShift) and (LKeyCommand.SecondaryKey = ASecondaryKeyCode) and
      (LKeyCommand.SecondaryShiftState = ASecondaryShift) then
      Exit(LIndex);
  end;
end;

function TTextEditorKeyCommands.FindShortcut(const AShortCut: TShortCut): Integer;
var
  LIndex: Integer;
begin
  Result := -1;
  for LIndex := 0 to Count - 1 do
  if Items[LIndex].ShortCut = AShortCut then
    Exit(LIndex);
end;

function TTextEditorKeyCommands.FindShortcuts(const AShortCut, ASecondaryShortCut: TShortCut): Integer;
var
  LIndex: Integer;
  LKeyCommand: TTextEditorKeyCommand;
begin
  Result := -1;
  for LIndex := 0 to Count - 1 do
  begin
    LKeyCommand := Items[LIndex];
    if (LKeyCommand.ShortCut = AShortCut) and (LKeyCommand.SecondaryShortCut = ASecondaryShortCut) then
      Exit(LIndex);
  end;
end;

function TTextEditorKeyCommands.GetItem(const AIndex: Integer): TTextEditorKeyCommand;
begin
  Result := TTextEditorKeyCommand(inherited GetItem(AIndex));
end;

function TTextEditorKeyCommands.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TTextEditorKeyCommands.ResetDefaults;
begin
  Clear;

  { Scrolling, caret moving and selection }
  Add(TKeyCommands.Down, [], vkDown);
  Add(TKeyCommands.EditorBottom, [ssCtrl], vkEnd);
  Add(TKeyCommands.EditorTop, [ssCtrl], vkHome);
  Add(TKeyCommands.Left, [], vkLeft);
  Add(TKeyCommands.LineBegin, [], vkHome);
  Add(TKeyCommands.LineEnd, [], vkEnd);
  Add(TKeyCommands.PageBottom, [ssCtrl], vkNext);
  Add(TKeyCommands.PageDown, [], vkNext);
  Add(TKeyCommands.PageTop, [ssCtrl], vkPrior);
  Add(TKeyCommands.PageUp, [], vkPrior);
  Add(TKeyCommands.Right, [], vkRight);
  Add(TKeyCommands.ScrollDown, [ssCtrl], vkDown);
  Add(TKeyCommands.ScrollUp, [ssCtrl], vkUp);
  Add(TKeyCommands.SelectionDown, [ssAlt], vkDown);
  Add(TKeyCommands.SelectionDown, [ssShift], vkDown);
  Add(TKeyCommands.SelectionEditorBottom, [ssShift, ssCtrl], vkEnd);
  Add(TKeyCommands.SelectionEditorTop, [ssShift, ssCtrl], vkHome);
  Add(TKeyCommands.SelectionLeft, [ssAlt], vkLeft);
  Add(TKeyCommands.SelectionLeft, [ssShift], vkLeft);
  Add(TKeyCommands.SelectionLineBegin, [ssShift], vkHome);
  Add(TKeyCommands.SelectionLineEnd, [ssShift], vkEnd);
  Add(TKeyCommands.SelectionPageBottom, [ssShift, ssCtrl], vkNext);
  Add(TKeyCommands.SelectionPageDown, [ssShift], vkNext);
  Add(TKeyCommands.SelectionPageTop, [ssShift, ssCtrl], vkPrior);
  Add(TKeyCommands.SelectionPageUp, [ssShift], vkPrior);
  Add(TKeyCommands.SelectionRight, [ssAlt], vkRight);
  Add(TKeyCommands.SelectionRight, [ssShift], vkRight);
  Add(TKeyCommands.SelectionUp, [ssAlt], vkUp);
  Add(TKeyCommands.SelectionUp, [ssShift], vkUp);
  Add(TKeyCommands.SelectionWordLeft, [ssShift, ssCtrl], vkLeft);
  Add(TKeyCommands.SelectionWordRight, [ssShift, ssCtrl], vkRight);
  Add(TKeyCommands.Up, [], vkUp);
  Add(TKeyCommands.WordLeft, [ssCtrl], vkLeft);
  Add(TKeyCommands.WordRight, [ssCtrl], vkRight);
  { Insert key alone }
  Add(TKeyCommands.ToggleMode, [], vkInsert);
  { Deletion }
  Add(TKeyCommands.DeleteChar, [], vkDelete);
  Add(TKeyCommands.Backspace, [], vkBack);
  Add(TKeyCommands.Backspace, [ssShift], vkBack);
  { Search }
  Add(TKeyCommands.SearchNext, [], vkF3);
  Add(TKeyCommands.SearchPrevious, [ssShift], vkF3);
  { Enter (return) & Tab }
  Add(TKeyCommands.LineBreak, [], vkReturn);
  Add(TKeyCommands.Tab, [], vkTab);
  Add(TKeyCommands.ShiftTab, [ssShift], vkTab);
  { Standard edit commands }
  Add(TKeyCommands.Undo, [ssCtrl], Ord('Z'));
  Add(TKeyCommands.Redo, [ssCtrl, ssShift], Ord('Z'));
  Add(TKeyCommands.Cut, [ssCtrl], Ord('X'));
  Add(TKeyCommands.Cut, [ssShift], vkDelete);
  Add(TKeyCommands.Copy, [ssCtrl], Ord('C'));
  Add(TKeyCommands.Copy, [ssCtrl], vkInsert);
  Add(TKeyCommands.Paste, [ssCtrl], Ord('V'));
  Add(TKeyCommands.Paste, [ssShift], vkInsert);
  Add(TKeyCommands.SelectAll, [ssCtrl], Ord('A'));
  { Block commands }
  Add(TKeyCommands.BlockIndent, [ssCtrl, ssShift], Ord('I'));
  Add(TKeyCommands.BlockUnindent, [ssCtrl, ssShift], Ord('U'));
  { Fragment deletion }
  Add(TKeyCommands.DeleteWord, [ssCtrl], Ord('W'));
  Add(TKeyCommands.DeleteWhitespaceBackward, [ssCtrl, ssShift], vkBack);
  Add(TKeyCommands.DeleteWhitespaceForward, [ssCtrl, ssShift], vkDelete);
  Add(TKeyCommands.DeleteWordBackward, [ssCtrl], vkBack);
  Add(TKeyCommands.DeleteWordForward, [ssCtrl], vkDelete);
  { Line operations }
  Add(TKeyCommands.InsertLine, [ssCtrl], Ord('M'));
  Add(TKeyCommands.MoveLineUp, [ssCtrl, ssShift], vkUp);
  Add(TKeyCommands.MoveLineDown, [ssCtrl, ssShift], vkDown);
  Add(TKeyCommands.DeleteLine, [ssCtrl], Ord('Y'));
  Add(TKeyCommands.DeleteEndOfLine, [ssCtrl, ssShift], Ord('Y'));
  { Bookmarks }
  Add(TKeyCommands.ToggleBookmark, [ssCtrl], vkF2);
  Add(TKeyCommands.GoToBookmark1, [ssCtrl], Ord('1'));
  Add(TKeyCommands.GoToBookmark2, [ssCtrl], Ord('2'));
  Add(TKeyCommands.GoToBookmark3, [ssCtrl], Ord('3'));
  Add(TKeyCommands.GoToBookmark4, [ssCtrl], Ord('4'));
  Add(TKeyCommands.GoToBookmark5, [ssCtrl], Ord('5'));
  Add(TKeyCommands.GoToBookmark6, [ssCtrl], Ord('6'));
  Add(TKeyCommands.GoToBookmark7, [ssCtrl], Ord('7'));
  Add(TKeyCommands.GoToBookmark8, [ssCtrl], Ord('8'));
  Add(TKeyCommands.GoToBookmark9, [ssCtrl], Ord('9'));
  Add(TKeyCommands.SetBookmark1, [ssCtrl, ssShift], Ord('1'));
  Add(TKeyCommands.SetBookmark2, [ssCtrl, ssShift], Ord('2'));
  Add(TKeyCommands.SetBookmark3, [ssCtrl, ssShift], Ord('3'));
  Add(TKeyCommands.SetBookmark4, [ssCtrl, ssShift], Ord('4'));
  Add(TKeyCommands.SetBookmark5, [ssCtrl, ssShift], Ord('5'));
  Add(TKeyCommands.SetBookmark6, [ssCtrl, ssShift], Ord('6'));
  Add(TKeyCommands.SetBookmark7, [ssCtrl, ssShift], Ord('7'));
  Add(TKeyCommands.SetBookmark8, [ssCtrl, ssShift], Ord('8'));
  Add(TKeyCommands.SetBookmark9, [ssCtrl, ssShift], Ord('9'));
  Add(TKeyCommands.GoToNextBookmark, [], vkF2);
  Add(TKeyCommands.GoToPreviousBookmark, [ssShift], vkF2);
  { Comments }
  Add(TKeyCommands.LineComment, [ssCtrl], vkSlash);
  Add(TKeyCommands.BlockComment, [ssCtrl, ssShift], vkSlash);
  { Folding }
  Add(TKeyCommands.FoldingCollapseLine, [ssCtrl, ssAlt], vkLeft);
  Add(TKeyCommands.FoldingExpandLine, [ssCtrl, ssAlt], vkRight);
  Add(TKeyCommands.FoldingGoToNext, [ssCtrl, ssAlt], vkDown);
  Add(TKeyCommands.FoldingGoToPrevious, [ssCtrl, ssAlt], vkUp);
end;

procedure TTextEditorKeyCommands.SetItem(const AIndex: Integer; AValue: TTextEditorKeyCommand);
begin
  inherited SetItem(AIndex, AValue);
end;

initialization

  RegisterIntegerConsts(TypeInfo(TTextEditorCommand), IdentToEditorCommand, EditorCommandToIdent);

finalization

  UnregisterIntegerConsts(TypeInfo(TTextEditorCommand), IdentToEditorCommand, EditorCommandToIdent);

end.

