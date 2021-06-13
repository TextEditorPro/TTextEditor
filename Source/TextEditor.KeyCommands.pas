unit TextEditor.KeyCommands;

interface

uses
  System.Classes, System.SysUtils, Vcl.Menus;

const
  ecNone = 0;
  ecEditCommandFirst = 501;
  ecEditCommandLast = 1000;
  { Caret moving }
  ecLeft = 1;
  ecRight = 2;
  ecUp = 3;
  ecDown = 4;
  ecWordLeft = 5;
  ecWordRight = 6;
  ecLineBegin = 7;
  ecLineEnd = 8;
  ecPageUp = 9;
  ecPageDown = 10;
  ecPageLeft = 11;
  ecPageRight = 12;
  ecPageTop = 13;
  ecPageBottom = 14;
  ecEditorTop = 15;
  ecEditorBottom = 16;
  ecGoToXY = 17;
  { Selection }
  ecSelection = 100;
  ecSelectionLeft = ecLeft + ecSelection;
  ecSelectionRight = ecRight + ecSelection;
  ecSelectionUp = ecUp + ecSelection;
  ecSelectionDown = ecDown + ecSelection;
  ecSelectionWordLeft = ecWordLeft + ecSelection;
  ecSelectionWordRight = ecWordRight + ecSelection;
  ecSelectionLineBegin = ecLineBegin + ecSelection;
  ecSelectionLineEnd = ecLineEnd + ecSelection;
  ecSelectionPageUp = ecPageUp + ecSelection;
  ecSelectionPageDown = ecPageDown + ecSelection;
  ecSelectionPageLeft = ecPageLeft + ecSelection;
  ecSelectionPageRight = ecPageRight + ecSelection;
  ecSelectionPageTop = ecPageTop + ecSelection;
  ecSelectionPageBottom = ecPageBottom + ecSelection;
  ecSelectionEditorTop = ecEditorTop + ecSelection;
  ecSelectionEditorBottom = ecEditorBottom + ecSelection;
  ecSelectionGoToXY = ecGoToXY + ecSelection;
  ecSelectionWord = ecSelection + 21;
  ecSelectAll = ecSelection + 22;
  { Scrolling }
  ecScrollUp = 211;
  ecScrollDown = 212;
  ecScrollLeft = 213;
  ecScrollRight = 214;
  { Mode }
  ecInsertMode = 221;
  ecOverwriteMode = 222;
  ecToggleMode = 223;
  { Bookmark }
  ecToggleBookmark = 300;
  ecGoToBookmark1 = 310;
  ecGoToBookmark2 = 311;
  ecGoToBookmark3 = 312;
  ecGoToBookmark4 = 313;
  ecGoToBookmark5 = 314;
  ecGoToBookmark6 = 315;
  ecGoToBookmark7 = 316;
  ecGoToBookmark8 = 317;
  ecGoToBookmark9 = 318;
  ecSetBookmark1 = 320;
  ecSetBookmark2 = 321;
  ecSetBookmark3 = 322;
  ecSetBookmark4 = 323;
  ecSetBookmark5 = 324;
  ecSetBookmark6 = 325;
  ecSetBookmark7 = 326;
  ecSetBookmark8 = 327;
  ecSetBookmark9 = 328;
  ecGoToNextBookmark = 330;
  ecGoToPreviousBookmark = 331;
  { Deletion }
  ecBackspace = 501;
  ecDeleteChar = 502;
  ecDeleteWord = 503;
  ecDeleteWordForward = 504;
  ecDeleteWordBackward = 505;
  ecDeleteBeginningOfLine = 506;
  ecDeleteEndOfLine = 507;
  ecDeleteLine = 508;
  ecClear = 509;
  { Insert }
  ecLineBreak = 510;
  ecInsertLine = 511;
  ecChar = 512;
  ecString = 513;
  ecImeStr = 550;
  { Clipboard }
  ecUndo = 601;
  ecRedo = 602;
  ecCopy = 603;
  ecCut = 604;
  ecPaste = 605;
  { Indent }
  ecBlockIndent = 610;
  ecBlockUnindent = 611;
  ecTab = 612;
  ecShiftTab = 613;
  { Case }
  ecUpperCase = 620;
  ecLowerCase = 621;
  ecAlternatingCase = 622;
  ecSentenceCase = 623;
  ecTitleCase = 624;
  ecUpperCaseBlock = 625;
  ecLowerCaseBlock = 626;
  ecAlternatingCaseBlock = 627;
  { Move }
  ecMoveLineUp = 701;
  ecMoveLineDown = 702;
  { Search }
  ecSearchNext = 800;
  ecSearchPrevious = 801;
  { Comments }
  ecLineComment = 900;
  ecBlockComment = 901;
  { Folding }
  ecFoldingCollapseLine = 910;
  ecFoldingExpandLine = 911;
  ecFoldingGoToNext = 912;
  ecFoldingGoToPrevious = 913;

  ecUserFirst = 1001;

type
  TTextEditorCommand = type Word;

  TTextEditorHookedCommandEvent = procedure(const ASender: TObject; const AAfterProcessing: Boolean; var AHandled: Boolean;
    var ACommand: TTextEditorCommand; var AChar: Char; const Data: Pointer) of object;
  TTextEditorProcessCommandEvent = procedure(const ASender: TObject; var ACommand: TTextEditorCommand; const AChar: Char;
    const AData: Pointer) of object;

  TTextEditorHookedCommandHandler = class(TObject)
  strict private
    FEvent: TTextEditorHookedCommandEvent;
    FData: Pointer;
  public
    constructor Create(AEvent: TTextEditorHookedCommandEvent; AData: pointer);
    function Equals(AEvent: TTextEditorHookedCommandEvent): Boolean; reintroduce;
    property Data: Pointer read FData write FData;
    property Event: TTextEditorHookedCommandEvent read FEvent write FEvent;
  end;

  TTextEditorKeyCommand = class(TCollectionItem)
  strict private
    FKey: Word;
    FSecondaryKey: Word;
    FShiftState: TShiftState;
    FSecondaryShiftState: TShiftState;
    FCommand: TTextEditorCommand;
    function GetShortCut: TShortCut;
    function GetSecondaryShortCut: TShortCut;
    procedure SetCommand(const AValue: TTextEditorCommand);
    procedure SetKey(const AValue: Word);
    procedure SetSecondaryKey(const AValue: Word);
    procedure SetShiftState(const AValue: TShiftState);
    procedure SetSecondaryShiftState(const AValue: TShiftState);
    procedure SetShortCut(const AValue: TShortCut);
    procedure SetSecondaryShortCut(const AValue: TShortCut);
  protected
    function GetDisplayName: string; override;
  public
    procedure Assign(ASource: TPersistent); override;
    property Key: Word read FKey write SetKey;
    property SecondaryKey: Word read FSecondaryKey write SetSecondaryKey;
    property ShiftState: TShiftState read FShiftState write SetShiftState;
    property SecondaryShiftState: TShiftState read FSecondaryShiftState write SetSecondaryShiftState;
  published
    property Command: TTextEditorCommand read FCommand write SetCommand;
    property ShortCut: TShortCut read GetShortCut write SetShortCut default 0;
    property SecondaryShortCut: TShortCut read GetSecondaryShortCut write SetSecondaryShortCut default 0;
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
  Winapi.Windows, TextEditor.Language;

type
  TTextEditorCommandString = record
    Value: TTextEditorCommand;
    Name: string;
  end;

const
  EditorCommandStrings: array [0 .. 106] of TTextEditorCommandString = (
    (Value: ecNone; Name: 'ecNone'),
    (Value: ecLeft; Name: 'ecLeft'),
    (Value: ecRight; Name: 'ecRight'),
    (Value: ecUp; Name: 'ecUp'),
    (Value: ecDown; Name: 'ecDown'),
    (Value: ecWordLeft; Name: 'ecWordLeft'),
    (Value: ecWordRight; Name: 'ecWordRight'),
    (Value: ecLineBegin; Name: 'ecLineBegin'),
    (Value: ecLineEnd; Name: 'ecLineEnd'),
    (Value: ecPageUp; Name: 'ecPageUp'),
    (Value: ecPageDown; Name: 'ecPageDown'),
    (Value: ecPageLeft; Name: 'ecPageLeft'),
    (Value: ecPageRight; Name: 'ecPageRight'),
    (Value: ecPageTop; Name: 'ecPageTop'),
    (Value: ecPageBottom; Name: 'ecPageBottom'),
    (Value: ecEditorTop; Name: 'ecEditorTop'),
    (Value: ecEditorBottom; Name: 'ecEditorBottom'),
    (Value: ecGoToXY; Name: 'ecGoToXY'),
    (Value: ecSelectionLeft; Name: 'ecSelectionLeft'),
    (Value: ecSelectionRight; Name: 'ecSelectionRight'),
    (Value: ecSelectionUp; Name: 'ecSelectionUp'),
    (Value: ecSelectionDown; Name: 'ecSelectionDown'),
    (Value: ecSelectionWordLeft; Name: 'ecSelectionWordLeft'),
    (Value: ecSelectionWordRight; Name: 'ecSelectionWordRight'),
    (Value: ecSelectionLineBegin; Name: 'ecSelectionLineBegin'),
    (Value: ecSelectionLineEnd; Name: 'ecSelectionLineEnd'),
    (Value: ecSelectionPageUp; Name: 'ecSelectionPageUp'),
    (Value: ecSelectionPageDown; Name: 'ecSelectionPageDown'),
    (Value: ecSelectionPageLeft; Name: 'ecSelectionPageLeft'),
    (Value: ecSelectionPageRight; Name: 'ecSelectionPageRight'),
    (Value: ecSelectionPageTop; Name: 'ecSelectionPageTop'),
    (Value: ecSelectionPageBottom; Name: 'ecSelectionPageBottom'),
    (Value: ecSelectionEditorTop; Name: 'ecSelectionEditorTop'),
    (Value: ecSelectionEditorBottom; Name: 'ecSelectionEditorBottom'),
    (Value: ecSelectionGoToXY; Name: 'ecSelectionGoToXY'),
    (Value: ecSelectionWord; Name: 'ecSelectionWord'),
    (Value: ecSelectAll; Name: 'ecSelectAll'),
    (Value: ecScrollUp; Name: 'ecScrollUp'),
    (Value: ecScrollDown; Name: 'ecScrollDown'),
    (Value: ecScrollLeft; Name: 'ecScrollLeft'),
    (Value: ecScrollRight; Name: 'ecScrollRight'),
    (Value: ecBackspace; Name: 'ecBackspace'),
    (Value: ecDeleteChar; Name: 'ecDeleteChar'),
    (Value: ecDeleteWord; Name: 'ecDeleteWord'),
    (Value: ecDeleteWordForward; Name: 'ecDeleteWordForward'),
    (Value: ecDeleteWordBackward; Name: 'ecDeleteWordBackward'),
    (Value: ecDeleteBeginningOfLine; Name: 'ecDeleteBeginningOfLine'),
    (Value: ecDeleteEndOfLine; Name: 'ecDeleteEndOfLine'),
    (Value: ecDeleteLine; Name: 'ecDeleteLine'),
    (Value: ecClear; Name: 'ecClear'),
    (Value: ecLineBreak; Name: 'ecLineBreak'),
    (Value: ecInsertLine; Name: 'ecInsertLine'),
    (Value: ecChar; Name: 'ecChar'),
    (Value: ecImeStr; Name: 'ecImeStr'),
    (Value: ecUndo; Name: 'ecUndo'),
    (Value: ecRedo; Name: 'ecRedo'),
    (Value: ecCut; Name: 'ecCut'),
    (Value: ecCopy; Name: 'ecCopy'),
    (Value: ecPaste; Name: 'ecPaste'),
    (Value: ecInsertMode; Name: 'ecInsertMode'),
    (Value: ecOverwriteMode; Name: 'ecOverwriteMode'),
    (Value: ecToggleMode; Name: 'ecToggleMode'),
    (Value: ecBlockIndent; Name: 'ecBlockIndent'),
    (Value: ecBlockUnindent; Name: 'ecBlockUnindent'),
    (Value: ecTab; Name: 'ecTab'),
    (Value: ecShiftTab; Name: 'ecShiftTab'),
    (Value: ecUserFirst; Name: 'ecUserFirst'),
    (Value: ecToggleBookmark; Name: 'ecToggleBookmark'),
    (Value: ecGoToBookmark1; Name: 'ecGoToBookmark1'),
    (Value: ecGoToBookmark2; Name: 'ecGoToBookmark2'),
    (Value: ecGoToBookmark3; Name: 'ecGoToBookmark3'),
    (Value: ecGoToBookmark4; Name: 'ecGoToBookmark4'),
    (Value: ecGoToBookmark5; Name: 'ecGoToBookmark5'),
    (Value: ecGoToBookmark6; Name: 'ecGoToBookmark6'),
    (Value: ecGoToBookmark7; Name: 'ecGoToBookmark7'),
    (Value: ecGoToBookmark8; Name: 'ecGoToBookmark8'),
    (Value: ecGoToBookmark9; Name: 'ecGoToBookmark9'),
    (Value: ecSetBookmark1; Name: 'ecSetBookmark1'),
    (Value: ecSetBookmark2; Name: 'ecSetBookmark2'),
    (Value: ecSetBookmark3; Name: 'ecSetBookmark3'),
    (Value: ecSetBookmark4; Name: 'ecSetBookmark4'),
    (Value: ecSetBookmark5; Name: 'ecSetBookmark5'),
    (Value: ecSetBookmark6; Name: 'ecSetBookmark6'),
    (Value: ecSetBookmark7; Name: 'ecSetBookmark7'),
    (Value: ecSetBookmark8; Name: 'ecSetBookmark8'),
    (Value: ecSetBookmark9; Name: 'ecSetBookmark9'),
    (Value: ecGoToNextBookmark; Name: 'ecGoToNextBookmark'),
    (Value: ecGoToPreviousBookmark; Name: 'ecGoToPreviousBookmark'),
    (Value: ecString; Name: 'ecString'),
    (Value: ecMoveLineUp; Name: 'ecMoveLineUp'),
    (Value: ecMoveLineDown; Name: 'ecMoveLineDown'),
    (Value: ecUpperCase; Name: 'ecUpperCase'),
    (Value: ecLowerCase; Name: 'ecLowerCase'),
    (Value: ecAlternatingCase; Name: 'ecAlternatingCase'),
    (Value: ecSentenceCase; Name: 'ecSentenceCase'),
    (Value: ecTitleCase; Name: 'ecTitleCase'),
    (Value: ecUpperCaseBlock; Name: 'ecUpperCaseBlock'),
    (Value: ecLowerCaseBlock; Name: 'ecLowerCaseBlock'),
    (Value: ecAlternatingCaseBlock; Name: 'ecAlternatingCaseBlock'),
    (Value: ecSearchNext; Name: 'ecSearchNext'),
    (Value: ecSearchPrevious; Name: 'ecSearchPrevious'),
    (Value: ecLineComment; Name: 'ecLineComment'),
    (Value: ecBlockComment; Name: 'ecBlockComment'),
    (Value: ecFoldingCollapseLine; Name: 'ecFoldingCollapseLine'),
    (Value: ecFoldingExpandLine; Name: 'ecFoldingExpandLine'),
    (Value: ecFoldingGoToNext; Name: 'ecFoldingGoToNext'),
    (Value: ecFoldingGoToPrevious; Name: 'ecFoldingGoToPrevious')
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
  Add(ecUp, [], VK_UP);
  Add(ecSelectionUp, [ssShift], VK_UP);
  Add(ecScrollUp, [ssCtrl], VK_UP);
  Add(ecDown, [], VK_DOWN);
  Add(ecSelectionDown, [ssShift], VK_DOWN);
  Add(ecScrollDown, [ssCtrl], VK_DOWN);
  Add(ecLeft, [], VK_LEFT);
  Add(ecSelectionLeft, [ssShift], VK_LEFT);
  Add(ecWordLeft, [ssCtrl], VK_LEFT);
  Add(ecSelectionWordLeft, [ssShift, ssCtrl], VK_LEFT);
  Add(ecRight, [], VK_RIGHT);
  Add(ecSelectionRight, [ssShift], VK_RIGHT);
  Add(ecWordRight, [ssCtrl], VK_RIGHT);
  Add(ecSelectionWordRight, [ssShift, ssCtrl], VK_RIGHT);
  Add(ecPageDown, [], VK_NEXT);
  Add(ecSelectionPageDown, [ssShift], VK_NEXT);
  Add(ecPageBottom, [ssCtrl], VK_NEXT);
  Add(ecSelectionPageBottom, [ssShift, ssCtrl], VK_NEXT);
  Add(ecPageUp, [], VK_PRIOR);
  Add(ecSelectionPageUp, [ssShift], VK_PRIOR);
  Add(ecPageTop, [ssCtrl], VK_PRIOR);
  Add(ecSelectionPageTop, [ssShift, ssCtrl], VK_PRIOR);
  Add(ecLineBegin, [], VK_HOME);
  Add(ecSelectionLineBegin, [ssShift], VK_HOME);
  Add(ecEditorTop, [ssCtrl], VK_HOME);
  Add(ecSelectionEditorTop, [ssShift, ssCtrl], VK_HOME);
  Add(ecLineEnd, [], VK_END);
  Add(ecSelectionLineEnd, [ssShift], VK_END);
  Add(ecEditorBottom, [ssCtrl], VK_END);
  Add(ecSelectionEditorBottom, [ssShift, ssCtrl], VK_END);
  { Insert key alone }
  Add(ecToggleMode, [], VK_INSERT);
  { Deletion }
  Add(ecDeleteChar, [], VK_DELETE);
  Add(ecBackspace, [], VK_BACK);
  Add(ecBackspace, [ssShift], VK_BACK);
  { Search }
  Add(ecSearchNext, [], VK_F3);
  Add(ecSearchPrevious, [ssShift], VK_F3);
  { Enter (return) & Tab }
  Add(ecLineBreak, [], VK_RETURN);
  Add(ecTab, [], VK_TAB);
  Add(ecShiftTab, [ssShift], VK_TAB);
  { Standard edit commands }
  Add(ecUndo, [ssCtrl], Ord('Z'));
  Add(ecRedo, [ssCtrl, ssShift], Ord('Z'));
  Add(ecCut, [ssCtrl], Ord('X'));
  Add(ecCut, [ssShift], VK_DELETE);
  Add(ecCopy, [ssCtrl], Ord('C'));
  Add(ecCopy, [ssCtrl], VK_INSERT);
  Add(ecPaste, [ssCtrl], Ord('V'));
  Add(ecPaste, [ssShift], VK_INSERT);
  Add(ecSelectAll, [ssCtrl], Ord('A'));
  { Block commands }
  Add(ecBlockIndent, [ssCtrl, ssShift], Ord('I'));
  Add(ecBlockUnindent, [ssCtrl, ssShift], Ord('U'));
  { Fragment deletion }
  Add(ecDeleteWord, [ssCtrl], Ord('W'));
  Add(ecDeleteWordBackward, [ssCtrl], VK_BACK);
  Add(ecDeleteWordForward, [ssCtrl], VK_DELETE);
  { Line operations }
  Add(ecInsertLine, [ssCtrl], Ord('M'));
  Add(ecMoveLineUp, [ssCtrl, ssShift], VK_UP);
  Add(ecMoveLineDown, [ssCtrl, ssShift], VK_DOWN);
  Add(ecDeleteLine, [ssCtrl], Ord('Y'));
  Add(ecDeleteEndOfLine, [ssCtrl, ssShift], Ord('Y'));
  { Bookmarks }
  Add(ecToggleBookmark, [ssCtrl], VK_F2);
  Add(ecGoToBookmark1, [ssCtrl], Ord('1'));
  Add(ecGoToBookmark2, [ssCtrl], Ord('2'));
  Add(ecGoToBookmark3, [ssCtrl], Ord('3'));
  Add(ecGoToBookmark4, [ssCtrl], Ord('4'));
  Add(ecGoToBookmark5, [ssCtrl], Ord('5'));
  Add(ecGoToBookmark6, [ssCtrl], Ord('6'));
  Add(ecGoToBookmark7, [ssCtrl], Ord('7'));
  Add(ecGoToBookmark8, [ssCtrl], Ord('8'));
  Add(ecGoToBookmark9, [ssCtrl], Ord('9'));
  Add(ecSetBookmark1, [ssCtrl, ssShift], Ord('1'));
  Add(ecSetBookmark2, [ssCtrl, ssShift], Ord('2'));
  Add(ecSetBookmark3, [ssCtrl, ssShift], Ord('3'));
  Add(ecSetBookmark4, [ssCtrl, ssShift], Ord('4'));
  Add(ecSetBookmark5, [ssCtrl, ssShift], Ord('5'));
  Add(ecSetBookmark6, [ssCtrl, ssShift], Ord('6'));
  Add(ecSetBookmark7, [ssCtrl, ssShift], Ord('7'));
  Add(ecSetBookmark8, [ssCtrl, ssShift], Ord('8'));
  Add(ecSetBookmark9, [ssCtrl, ssShift], Ord('9'));
  Add(ecGoToNextBookmark, [], VK_F2);
  Add(ecGoToPreviousBookmark, [ssShift], VK_F2);
  { Comments }
  Add(ecLineComment, [ssCtrl], VK_OEM_2);
  Add(ecBlockComment, [ssCtrl, ssShift], VK_OEM_2);
  { Folding }
  Add(ecFoldingCollapseLine, [ssAlt], VK_LEFT);
  Add(ecFoldingExpandLine, [ssAlt], VK_RIGHT);
  Add(ecFoldingGoToNext, [ssAlt], VK_DOWN);
  Add(ecFoldingGoToPrevious, [ssAlt], VK_UP);
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

