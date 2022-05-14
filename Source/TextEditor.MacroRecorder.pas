unit TextEditor.MacroRecorder;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, System.WideStrUtils, Vcl.Controls, Vcl.Graphics, Vcl.Menus,
  TextEditor.KeyCommands, TextEditor.Language, TextEditor.Types;

type
  TTextEditorMacroState = (msStopped, msRecording, msPlaying, msPaused);

  TTextEditorMacroEvent = class(TObject)
  protected
    FRepeatCount: Byte;
    procedure InitEventParameters(const AString: string); virtual; abstract;
  public
    constructor Create; virtual;
    procedure Initialize(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer); virtual; abstract;
    procedure LoadFromStream(const AStream: TStream); virtual; abstract;
    procedure Playback(const AEditor: TCustomControl); virtual; abstract;
    procedure SaveToStream(const AStream: TStream); virtual; abstract;
    property RepeatCount: Byte read FRepeatCount write FRepeatCount;
  end;

  TTextEditorBasicEvent = class(TTextEditorMacroEvent)
  protected
    FCommand: TTextEditorCommand;
    procedure InitEventParameters(const AString: string); override;
  public
    procedure Initialize(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer); override;
    procedure LoadFromStream(const AStream: TStream); override;
    procedure Playback(const AEditor: TCustomControl); override;
    procedure SaveToStream(const AStream: TStream); override;
  public
    property Command: TTextEditorCommand read FCommand write FCommand;
  end;

  TTextEditorCharEvent = class(TTextEditorMacroEvent)
  protected
    FKey: Char;
    procedure InitEventParameters(const AString: string); override;
  public
    procedure Initialize(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer); override;
    procedure LoadFromStream(const AStream: TStream); override;
    procedure Playback(const AEditor: TCustomControl); override;
    procedure SaveToStream(const AStream: TStream); override;
  public
    property Key: Char read FKey write FKey;
  end;

  TTextEditorTextEvent = class(TTextEditorMacroEvent)
  protected
    FString: string;
    procedure InitEventParameters(const AString: string); override;
  public
    procedure Initialize(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer); override;
    procedure LoadFromStream(const AStream: TStream); override;
    procedure Playback(const AEditor: TCustomControl); override;
    procedure SaveToStream(const AStream: TStream); override;
  public
    property Value: string read FString write FString;
  end;

  TTextEditorPositionEvent = class(TTextEditorBasicEvent)
  protected
    FPosition: TTextEditorTextPosition;
    procedure InitEventParameters(const AString: string); override;
  public
    procedure Initialize(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer); override;
    procedure LoadFromStream(const AStream: TStream); override;
    procedure Playback(const AEditor: TCustomControl); override;
    procedure SaveToStream(const AStream: TStream); override;
  public
    property Position: TTextEditorTextPosition read FPosition write FPosition;
  end;

  TTextEditorDataEvent = class(TTextEditorBasicEvent)
  protected
    FData: Pointer;
  public
    procedure Initialize(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer); override;
    procedure LoadFromStream(const AStream: TStream); override;
    procedure Playback(const AEditor: TCustomControl); override;
    procedure SaveToStream(const AStream: TStream); override;
  end;

  TCustomEditorMacroRecorder = class;

  TTextEditorUserCommandEvent = procedure(const ASender: TCustomEditorMacroRecorder; const ACommand: TTextEditorCommand;
    var AEvent: TTextEditorMacroEvent) of object;

  TCustomEditorMacroRecorder = class(TComponent)
  strict private
    FMacroName: string;
    FOnStateChange: TNotifyEvent;
    FOnUserCommand: TTextEditorUserCommandEvent;
    FPlaybackShortCut: TShortCut;
    FRecordShortCut: TShortCut;
    FSaveMarkerPos: Boolean;
    function GetEditor: TCustomControl;
    function GetEditorCount: Integer;
    function GetEditors(const AIndex: Integer): TCustomControl;
    function GetEvent(const AIndex: Integer): TTextEditorMacroEvent;
    function GetEventCount: Integer;
    procedure SetEditor(const AValue: TCustomControl);
  protected
    FCurrentEditor: TCustomControl;
    FEditors: TList;
    FEvents: TList;
    FPlaybackCommandID: TTextEditorCommand;
    FRecordCommandID: TTextEditorCommand;
    FState: TTextEditorMacroState;
    function CreateMacroEvent(const ACommand: TTextEditorCommand): TTextEditorMacroEvent;
    function GetIsEmpty: Boolean;
    procedure DoAddEditor(const AEditor: TCustomControl);
    procedure DoRemoveEditor(const AEditor: TCustomControl);
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
    procedure OnCommand(const ASender: TObject; const AAfterProcessing: Boolean; var AHandled: Boolean; var ACommand: TTextEditorCommand;
      var AChar: Char; const AData: Pointer);
    procedure SetPlaybackShortCut(const AValue: TShortCut);
    procedure SetRecordShortCut(const AValue: TShortCut);
    procedure StateChanged;
  protected
    procedure HookEditor(const AEditor: TCustomControl; const ACommandID: TTextEditorCommand; const AOldShortCut, ANewShortCut: TShortCut);
    procedure UnHookEditor(const AEditor: TCustomControl; const ACommandID: TTextEditorCommand; const AShortCut: TShortCut);
    property PlaybackCommandID: TTextEditorCommand read FPlaybackCommandID;
    property RecordCommandID: TTextEditorCommand read FRecordCommandID;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function AddEditor(const AEditor: TCustomControl): Integer;
    function RemoveEditor(const AEditor: TCustomControl): Integer;
    procedure AddCustomEvent(const AEvent: TTextEditorMacroEvent);
    procedure AddEvent(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);
    procedure Clear;
    procedure DeleteEvent(const AIndex: Integer);
    procedure Error(const AMessage: string);
    procedure InsertCustomEvent(const AIndex: Integer; const AEvent: TTextEditorMacroEvent);
    procedure InsertEvent(const AIndex: Integer; const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);
    procedure LoadFromFile(const AFilename: string);
    procedure LoadFromStream(const ASource: TStream; const AClear: Boolean = True);
    procedure Pause;
    procedure PlaybackMacro(const AEditor: TCustomControl);
    procedure RecordMacro(const AEditor: TCustomControl);
    procedure Resume;
    procedure SaveToFile(const AFilename: string);
    procedure SaveToStream(const ADestination: TStream);
    procedure Stop;
    property EditorCount: Integer read GetEditorCount;
    property Editors[const AIndex: Integer]: TCustomControl read GetEditors;
    property EventCount: Integer read GetEventCount;
    property Events[const AIndex: Integer]: TTextEditorMacroEvent read GetEvent;
    property IsEmpty: Boolean read GetIsEmpty;
    property MacroName: string read FMacroName write FMacroName;
    property OnStateChange: TNotifyEvent read FOnStateChange write FOnStateChange;
    property OnUserCommand: TTextEditorUserCommandEvent read FOnUserCommand write FOnUserCommand;
    property PlaybackShortCut: TShortCut read FPlaybackShortCut write SetPlaybackShortCut;
    property RecordShortCut: TShortCut read FRecordShortCut write SetRecordShortCut;
    property SaveMarkerPos: Boolean read FSaveMarkerPos write FSaveMarkerPos default False;
    property State: TTextEditorMacroState read FState;
  published
    property Editor: TCustomControl read GetEditor write SetEditor;
  end;

  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
  TTextEditorMacroRecorder = class(TCustomEditorMacroRecorder)
  published
    property OnStateChange;
    property OnUserCommand;
    property PlaybackShortCut;
    property RecordShortCut;
    property SaveMarkerPos;
  end;

  ETextEditorMacroRecorderException = class(Exception);

implementation

uses
  System.Types, Vcl.Forms, TextEditor, TextEditor.Consts, TextEditor.Utils;

{ TTextEditorDatAEvent }

procedure TTextEditorDataEvent.Initialize(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);
begin
  FCommand := ACommand;
  Assert(AChar = TControlCharacters.Null);
  FData := AData;
end;

procedure TTextEditorDataEvent.LoadFromStream(const AStream: TStream);
begin
  AStream.Read(FData, SizeOf(FData));
end;

procedure TTextEditorDataEvent.Playback(const AEditor: TCustomControl);
begin
  TCustomTextEditor(AEditor).CommandProcessor(Command, TControlCharacters.Null, FData);
end;

procedure TTextEditorDataEvent.SaveToStream(const AStream: TStream);
begin
  inherited;
  AStream.Write(FData, SizeOf(FData));
end;

{ TCustomEditorMacroRecorder }

procedure TCustomEditorMacroRecorder.AddCustomEvent(const AEvent: TTextEditorMacroEvent);
begin
  InsertCustomEvent(EventCount, AEvent);
end;

function TCustomEditorMacroRecorder.AddEditor(const AEditor: TCustomControl): Integer;
begin
  if not Assigned(FEditors) then
    FEditors := TList.Create
  else
  if FEditors.IndexOf(AEditor) >= 0 then
  begin
    Result := -1;
    Exit;
  end;
  AEditor.FreeNotification(Self);
  Result := FEditors.Add(AEditor);
  DoAddEditor(AEditor);
end;

procedure TCustomEditorMacroRecorder.AddEvent(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);
begin
  InsertEvent(EventCount, ACommand, AChar, AData);
end;

procedure TCustomEditorMacroRecorder.Clear;
var
  LIndex: Integer;
  LObject: TObject;
begin
  if Assigned(FEvents) then
  begin
    for LIndex := FEvents.Count - 1 downto 0 do
    begin
      LObject := FEvents[LIndex];
      FEvents.Delete(LIndex);
      LObject.Free;
    end;
    FEvents.Free;
    FEvents := nil;
  end;
end;

const
  ecCommandBase = 64000; //FI:O803 Constant is declared but never used (bug)

var
  GCurrentCommand: Integer = ecCommandBase;

function NewPluginCommand: TTextEditorCommand;
begin
  Result := GCurrentCommand;
  Inc(GCurrentCommand);
end;

constructor TCustomEditorMacroRecorder.Create(AOwner: TComponent);
begin
  inherited;

  FMacroName := STextEditorMacroNameUnnamed;
  FRecordCommandID := NewPluginCommand;
  FPlaybackCommandID := NewPluginCommand;
  FRecordShortCut := Vcl.Menus.ShortCut(Ord('R'), [ssCtrl, ssShift]);
  FPlaybackShortCut := Vcl.Menus.ShortCut(Ord('P'), [ssCtrl, ssShift]);
end;

function TCustomEditorMacroRecorder.CreateMacroEvent(const ACommand: TTextEditorCommand): TTextEditorMacroEvent;

  function WantDefaultEvent(var AEvent: TTextEditorMacroEvent): Boolean;
  begin
    if Assigned(OnUserCommand) then
      OnUserCommand(Self, ACommand, AEvent);

    Result := not Assigned(AEvent);
  end;

begin
  case ACommand of
    TKeyCommands.GoToXY, TKeyCommands.SelectionGoToXY, TKeyCommands.SetBookmark1 .. TKeyCommands.SetBookmark9:
      begin
        Result := TTextEditorPositionEvent.Create;

        TTextEditorPositionEvent(Result).Command := ACommand;
      end;
    TKeyCommands.Char:
      Result := TTextEditorCharEvent.Create;
    TKeyCommands.Text:
      Result := TTextEditorTextEvent.Create;
  else
    begin
      Result := nil;

      if (ACommand < TKeyCommands.UserFirst) or WantDefaultEvent(Result) then
      begin
        Result := TTextEditorBasicEvent.Create;
        TTextEditorBasicEvent(Result).Command := ACommand;
      end;
    end;
  end;
end;

function TCustomEditorMacroRecorder.GetEditors(const AIndex: Integer): TCustomControl;
begin
  Result := FEditors[AIndex];
end;

procedure TCustomEditorMacroRecorder.DeleteEvent(const AIndex: Integer);
var
  LObject: Pointer;
begin
  LObject := FEvents[AIndex];
  FEvents.Delete(AIndex);
  TObject(LObject).Free;
end;

procedure ReleasePluginCommand(ACommand: TTextEditorCommand);
begin
  if ACommand = GCurrentCommand - 1 then
    GCurrentCommand := ACommand;
end;

destructor TCustomEditorMacroRecorder.Destroy;
begin
  while Assigned(FEditors) do
    RemoveEditor(Editors[0]);

  Clear;

  inherited;

  ReleasePluginCommand(PlaybackCommandID);
  ReleasePluginCommand(RecordCommandID);
end;

function TCustomEditorMacroRecorder.GetEditor: TCustomControl;
begin
  if Assigned(FEditors) then
    Result := FEditors[0]
  else
    Result := nil;
end;

procedure TCustomEditorMacroRecorder.SetEditor(const AValue: TCustomControl);
var
  LEditor: TCustomTextEditor;
begin
  LEditor := Editor as TCustomTextEditor;
  if LEditor <> AValue then
  try
    if Assigned(LEditor) and (FEditors.Count = 1) then
      RemoveEditor(LEditor);

    if Assigned(AValue) then
      AddEditor(AValue);
  except
    if [csDesigning] * ComponentState = [csDesigning] then
      Application.HandleException(Self)
    else
      raise;
  end;
end;

function TCustomEditorMacroRecorder.GetEditorCount: Integer;
begin
  if Assigned(FEditors) then
    Result := FEditors.Count
  else
    Result := 0;
end;

procedure TCustomEditorMacroRecorder.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited;

  if AOperation = opRemove then
    if (AComponent = Editor) or (AComponent is TCustomTextEditor) then
      RemoveEditor(TCustomTextEditor(AComponent));
end;

procedure TCustomEditorMacroRecorder.DoAddEditor(const AEditor: TCustomControl);
begin
  HookEditor(AEditor, RecordCommandID, 0, RecordShortCut);
  HookEditor(AEditor, PlaybackCommandID, 0, PlaybackShortCut);
end;

procedure TCustomEditorMacroRecorder.DoRemoveEditor(const AEditor: TCustomControl);
begin
  UnHookEditor(AEditor, RecordCommandID, RecordShortCut);
  UnHookEditor(AEditor, PlaybackCommandID, PlaybackShortCut);
end;

procedure TCustomEditorMacroRecorder.Error(const AMessage: string);
begin
  raise ETextEditorMacroRecorderException.Create(AMessage);
end;

function TCustomEditorMacroRecorder.GetEvent(const AIndex: Integer): TTextEditorMacroEvent;
begin
  Result := TTextEditorMacroEvent(FEvents[AIndex]);
end;

function TCustomEditorMacroRecorder.GetEventCount: Integer;
begin
  if Assigned(FEvents) then
    Result := FEvents.Count
  else
    Result := 0;
end;

function TCustomEditorMacroRecorder.GetIsEmpty: Boolean;
begin
  Result := not Assigned(FEvents) or (FEvents.Count = 0);
end;

procedure TCustomEditorMacroRecorder.InsertCustomEvent(const AIndex: Integer; const AEvent: TTextEditorMacroEvent);
begin
  if not Assigned(FEvents) then
    FEvents := TList.Create;
  FEvents.Insert(AIndex, AEvent);
end;

procedure TCustomEditorMacroRecorder.InsertEvent(const AIndex: Integer; const ACommand: TTextEditorCommand; const AChar: Char;
  const AData: Pointer);
var
  LEvent: TTextEditorMacroEvent;
begin
  LEvent := CreateMacroEvent(ACommand);
  try
    LEvent.Initialize(ACommand, AChar, AData);
    InsertCustomEvent(AIndex, LEvent);
  except
    LEvent.Free;
    raise;
  end;
end;

procedure TCustomEditorMacroRecorder.LoadFromStream(const ASource: TStream; const AClear: Boolean = True);
var
  LCommand: TTextEditorCommand;
  LEvent: TTextEditorMacroEvent;
  LCount, LIndex: Integer;
begin
  Stop;
  if AClear then
    Clear;

  FEvents := TList.Create;
  ASource.Read(LCount, SizeOf(LCount));
  LIndex := 0;
  FEvents.Capacity := ASource.Size div SizeOf(TTextEditorCommand);

  while (ASource.Position < ASource.Size) and (LIndex < LCount) do
  begin
    ASource.Read(LCommand, SizeOf(TTextEditorCommand));
    LEvent := CreateMacroEvent(LCommand);
    LEvent.Initialize(LCommand, TControlCharacters.Null, nil);
    LEvent.LoadFromStream(ASource);
    FEvents.Add(LEvent);
    Inc(LIndex);
  end;
end;

procedure TCustomEditorMacroRecorder.OnCommand(const ASender: TObject; const AAfterProcessing: Boolean; var AHandled: Boolean;
  var ACommand: TTextEditorCommand; var AChar: Char; const AData: Pointer);
var
  LEvent: TTextEditorMacroEvent;
begin
  if AAfterProcessing then
  begin
    if (ASender = FCurrentEditor) and (State = msRecording) and (not AHandled) then
    begin
      LEvent := CreateMacroEvent(ACommand);
      LEvent.Initialize(ACommand, AChar, AData);
      FEvents.Add(LEvent);

      if SaveMarkerPos and (ACommand >= TKeyCommands.SetBookmark1) and (ACommand <= TKeyCommands.SetBookmark9) and not Assigned(AData) then
        TTextEditorPositionEvent(LEvent).Position := TCustomTextEditor(FCurrentEditor).TextPosition;
    end;
  end
  else
  begin
    { not AfterProcessing }
    case State of
      msStopped:
        if ACommand = RecordCommandID then
        begin
          RecordMacro(TCustomTextEditor(ASender));
          AHandled := True;
        end
        else
        if ACommand = PlaybackCommandID then
        begin
          PlaybackMacro(TCustomTextEditor(ASender));
          AHandled := True;
        end;
      msPlaying:
        ;
      msPaused:
        if ACommand = PlaybackCommandID then
        begin
          Resume;
          AHandled := True;
        end;
      msRecording:
        if ACommand = PlaybackCommandID then
        begin
          Pause;
          AHandled := True;
        end
        else
        if ACommand = RecordCommandID then
        begin
          Stop;
          AHandled := True;
        end;
    end;
  end;
end;

procedure TCustomEditorMacroRecorder.Pause;
begin
  if State <> msRecording then
    Error(STextEditorCannotPause);

  FState := msPaused;
  StateChanged;
end;

procedure TCustomEditorMacroRecorder.PlaybackMacro(const AEditor: TCustomControl);
var
  LIndex: Integer;
begin
  if State <> msStopped then
    Error(STextEditorCannotPlay);

  FState := msPlaying;
  try
    StateChanged;
    for LIndex := 0 to EventCount - 1 do
    begin
      Events[LIndex].Playback(AEditor);
      if State <> msPlaying then
        break;
    end;
  finally
    if State = msPlaying then
    begin
      FState := msStopped;
      StateChanged;
    end;
  end;
end;

procedure TCustomEditorMacroRecorder.RecordMacro(const AEditor: TCustomControl);
begin
  if FState <> msStopped then
    Error(STextEditorCannotRecord);

  Clear;
  FEvents := TList.Create;
  FEvents.Capacity := 512;
  FState := msRecording;
  FCurrentEditor := AEditor;
  StateChanged;
end;

function TCustomEditorMacroRecorder.RemoveEditor(const AEditor: TCustomControl): Integer;
begin
  if not Assigned(FEditors) then
  begin
    Result := -1;
    Exit;
  end;

  Result := FEditors.Remove(AEditor);

  if FEditors.Count = 0 then
  begin
    FEditors.Free;
    FEditors := nil;
  end;

  if Result >= 0 then
    DoRemoveEditor(AEditor);
end;

procedure TCustomEditorMacroRecorder.Resume;
begin
  if FState <> msPaused then
    Error(STextEditorCannotResume);

  FState := msRecording;
  StateChanged;
end;

procedure TCustomEditorMacroRecorder.SaveToStream(const ADestination: TStream);
var
  i, LCount: Integer;
begin
  LCount := EventCount;
  ADestination.Write(LCount, SizeOf(LCount));

  for i := 0 to LCount - 1 do
    Events[i].SaveToStream(ADestination);
end;

procedure TCustomEditorMacroRecorder.SetRecordShortCut(const AValue: TShortCut);
var
  LIndex: Integer;
begin
  if FRecordShortCut <> AValue then
  begin
    if Assigned(FEditors) then
      if AValue <> 0 then
      for LIndex := 0 to FEditors.Count - 1 do
        HookEditor(Editors[LIndex], FRecordCommandID, FRecordShortCut, AValue)
      else
      for LIndex := 0 to FEditors.Count - 1 do
        UnHookEditor(Editors[LIndex], FRecordCommandID, FRecordShortCut);

    FRecordShortCut := AValue;
  end;
end;

procedure TCustomEditorMacroRecorder.SetPlaybackShortCut(const AValue: TShortCut);
var
  LIndex: Integer;
begin
  if FPlaybackShortCut <> AValue then
  begin
    if Assigned(FEditors) then
      if AValue <> 0 then
      for LIndex := 0 to FEditors.Count - 1 do
        HookEditor(Editors[LIndex], FPlaybackCommandID, FPlaybackShortCut, AValue)
      else
      for LIndex := 0 to FEditors.Count - 1 do
        UnHookEditor(Editors[LIndex], FPlaybackCommandID, FPlaybackShortCut);

    FPlaybackShortCut := AValue;
  end;
end;

procedure TCustomEditorMacroRecorder.StateChanged;
begin
  if Assigned(OnStateChange) then
    OnStateChange(Self);
end;

procedure TCustomEditorMacroRecorder.Stop;
begin
  if FState = msStopped then
    Exit;

  FState := msStopped;
  FCurrentEditor := nil;

  if FEvents.Count = 0 then
  begin
    FEvents.Free;
    FEvents := nil;
  end;

  StateChanged;
end;

procedure TCustomEditorMacroRecorder.LoadFromFile(const AFilename: string);
var
  LFileStream: TFileStream;
begin
  LFileStream := TFileStream.Create(AFilename, fmOpenRead);
  try
    LoadFromStream(LFileStream);
    MacroName := ChangeFileExt(ExtractFilename(AFilename), '');
  finally
    LFileStream.Free;
  end;
end;

procedure TCustomEditorMacroRecorder.SaveToFile(const AFilename: string);
var
  LFileStream: TFileStream;
begin
  LFileStream := TFileStream.Create(AFilename, fmCreate);
  try
    SaveToStream(LFileStream);
  finally
    LFileStream.Free;
  end;
end;

procedure TCustomEditorMacroRecorder.HookEditor(const AEditor: TCustomControl; const ACommandID: TTextEditorCommand;
  const AOldShortCut, ANewShortCut: TShortCut);
var
  LIndex: Integer;
  LKeyCommand: TTextEditorKeyCommand;
begin
  Assert(ANewShortCut <> 0);
  if [csDesigning] * ComponentState = [csDesigning] then
    if TCustomTextEditor(AEditor).KeyCommands.FindShortcut(ANewShortCut) >= 0 then
      raise ETextEditorMacroRecorderException.Create(STextEditorShortcutAlreadyExists)
    else
      Exit;

  if AOldShortCut <> 0 then
  begin
    LIndex := TCustomTextEditor(AEditor).KeyCommands.FindShortcut(AOldShortCut);
    if LIndex >= 0 then
    begin
      LKeyCommand := TCustomTextEditor(AEditor).KeyCommands[LIndex];
      if LKeyCommand.Command = ACommandID then
      begin
        LKeyCommand.ShortCut := ANewShortCut;
        Exit;
      end;
    end;
  end;

  LKeyCommand := TCustomTextEditor(AEditor).KeyCommands.NewItem;
  try
    LKeyCommand.ShortCut := ANewShortCut;
  except
    LKeyCommand.Free;
    raise;
  end;
  LKeyCommand.Command := ACommandID;
  TCustomTextEditor(AEditor).RegisterCommandHandler(OnCommand, Self);
end;

procedure TCustomEditorMacroRecorder.UnHookEditor(const AEditor: TCustomControl; const ACommandID: TTextEditorCommand;
  const AShortCut: TShortCut);
var
  LIndex: Integer;
  LEditor: TCustomTextEditor;
begin
  if not Assigned(AEditor) then
    Exit;

  LEditor := AEditor as TCustomTextEditor;
  LEditor.UnregisterCommandHandler(OnCommand);
  if Assigned(LEditor.KeyCommands) then
  begin
    LIndex := LEditor.KeyCommands.FindShortcut(AShortCut);
    if (LIndex >= 0) and (LEditor.KeyCommands[LIndex].Command = ACommandID) then
      LEditor.KeyCommands[LIndex].Free;
  end;
end;

{ TTextEditorBasicEvent }

procedure TTextEditorBasicEvent.InitEventParameters(const AString: string);
begin
  RepeatCount := StrToIntDef(TextEditor.Utils.Trim(AString), 1);
end;

procedure TTextEditorBasicEvent.Initialize(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);
begin
  Command := ACommand;
end;

procedure TTextEditorBasicEvent.LoadFromStream(const AStream: TStream);
begin
  AStream.Read(FRepeatCount, SizeOf(FRepeatCount));
end;

procedure TTextEditorBasicEvent.Playback(const AEditor: TCustomControl);
var
  LIndex: Integer;
begin
  for LIndex := 1 to RepeatCount do //FI:W528 Variable not used in FOR-loop
    TCustomTextEditor(AEditor).CommandProcessor(Command, TControlCharacters.Null, nil);
end;

procedure TTextEditorBasicEvent.SaveToStream(const AStream: TStream);
begin
  AStream.Write(Command, SizeOf(TTextEditorCommand));
  AStream.Write(RepeatCount, SizeOf(RepeatCount));
end;

{ TTextEditorCharEvent }

procedure TTextEditorCharEvent.InitEventParameters(const AString: string);
var
  LString: string;
begin
  LString := AString;
  if Length(LString) >= 1 then
    Key := LString[1]
  else
    Key := ' ';
  Delete(LString, 1, 1);
  RepeatCount := StrToIntDef(TextEditor.Utils.Trim(LString), 1);
end;

procedure TTextEditorCharEvent.Initialize(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);
begin
  Key := AChar;
  Assert(not Assigned(AData));
end;

procedure TTextEditorCharEvent.LoadFromStream(const AStream: TStream);
begin
  AStream.Read(FKey, SizeOf(Key));
  AStream.Read(FRepeatCount, SizeOf(FRepeatCount));
end;

procedure TTextEditorCharEvent.Playback(const AEditor: TCustomControl);
var
  LIndex: Integer;
begin
  for LIndex := 1 to RepeatCount do //FI:W528 Variable not used in FOR-loop
    TCustomTextEditor(AEditor).CommandProcessor(TKeyCommands.Char, Key, nil);
end;

procedure TTextEditorCharEvent.SaveToStream(const AStream: TStream);
const
  CharCommand: TTextEditorCommand = TKeyCommands.Char;
begin
  AStream.Write(CharCommand, SizeOf(TTextEditorCommand));
  AStream.Write(Key, SizeOf(Key));
  AStream.Write(RepeatCount, SizeOf(RepeatCount));
end;

{ TTextEditorPositionEvent }

procedure TTextEditorPositionEvent.InitEventParameters(const AString: string);
var
  LDotPosition, LOpenPosition, LClosePosition: Integer;
  X, Y: Integer;
  LValue: string;
  LString: string;
begin
  inherited;

  LString := TextEditor.Utils.Trim(AString);
  LDotPosition := Pos(',', LString);
  LOpenPosition := Pos('(', LString);
  LClosePosition := Pos(')', LString);
  if (not((LDotPosition = 0) or (LOpenPosition = 0) or (LClosePosition = 0))) and ((LDotPosition > LOpenPosition) and
    (LDotPosition < LClosePosition)) then
  begin
    LValue := Copy(LString, LOpenPosition + 1, LDotPosition - LOpenPosition - 1);
    X := StrToIntDef(LValue, 1);
    Delete(LString, 1, LDotPosition);
    LString := TextEditor.Utils.Trim(LString);
    LClosePosition := Pos(')', LString);
    LValue := Copy(LString, 1, LClosePosition - 1);
    Y := StrToIntDef(LValue, 1);
    Position := GetPosition(X, Y);
    Delete(LString, 1, LClosePosition);
    LString := TextEditor.Utils.Trim(LString);
    RepeatCount := StrToIntDef(LString, 1);
  end;
end;

procedure TTextEditorPositionEvent.Initialize(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);
begin
  inherited;

  if Assigned(AData) then
    Position := TTextEditorTextPosition(AData^)
  else
    Position := GetBOFPosition;
end;

procedure TTextEditorPositionEvent.LoadFromStream(const AStream: TStream);
begin
  AStream.Read(FPosition, SizeOf(Position));
end;

procedure TTextEditorPositionEvent.Playback(const AEditor: TCustomControl);
begin
  if (Position.Char <> 0) or (Position.Line <> 0) then
    TCustomTextEditor(AEditor).CommandProcessor(Command, TControlCharacters.Null, @Position)
  else
    TCustomTextEditor(AEditor).CommandProcessor(Command, TControlCharacters.Null, nil);
end;

procedure TTextEditorPositionEvent.SaveToStream(const AStream: TStream);
begin
  inherited;

  AStream.Write(Position, SizeOf(Position));
end;

{ TTextEditorTextEvent }

procedure TTextEditorTextEvent.InitEventParameters(const AString: string);
var
  LOpenPosition, LClosePosition: Integer;
  LValue: string;
  LString: string;

  function WideLastDelimiter(const Delimiters, S: string): Integer;
  var
    P: PChar;
  begin
    Result := Length(S);
    P := PChar(Delimiters);
    while Result > 0 do
    begin
      if (S[Result] <> TControlCharacters.Null) and Assigned(WStrScan(P, S[Result])) then
        Exit;
      Dec(Result);
    end;
  end;

begin
  LString := AString;
  LOpenPosition := Pos('''', LString);
  LClosePosition := WideLastDelimiter('''', LString);
  LValue := Copy(LString, LOpenPosition + 1, LClosePosition - LOpenPosition - 1);
  Value := StringReplace(LValue, '''''', '''', [rfReplaceAll]);
  Delete(LString, 1, LClosePosition);
  RepeatCount := StrToIntDef(TextEditor.Utils.Trim(LString), 1);
end;

procedure TTextEditorTextEvent.Initialize(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);
begin
  Value := string(AData);
end;

procedure TTextEditorTextEvent.LoadFromStream(const AStream: TStream);
var
  LLength: Integer;
  LPBuffer: PChar;
begin
  AStream.Read(LLength, SizeOf(LLength));
  GetMem(LPBuffer, LLength * SizeOf(Char));
  try
    FillMemory(LPBuffer, LLength, 0);
    AStream.Read(LPBuffer^, LLength * SizeOf(Char));
    FString := LPBuffer;
  finally
    FreeMem(LPBuffer);
  end;
  AStream.Read(FRepeatCount, SizeOf(FRepeatCount));
end;

procedure TTextEditorTextEvent.Playback(const AEditor: TCustomControl);
var
  LIndex, LIndex2: Integer;
begin
  for LIndex := 1 to RepeatCount do //FI:W528 Variable not used in FOR-loop
    for LIndex2 := 1 to Length(Value) do
      TCustomTextEditor(AEditor).CommandProcessor(TKeyCommands.Char, Value[LIndex2], nil);
end;

procedure TTextEditorTextEvent.SaveToStream(const AStream: TStream);
const
  Command: TTextEditorCommand = TKeyCommands.Text;
var
  LLength: Integer;
  LPBuffer: PChar;
begin
  AStream.Write(Command, SizeOf(Command));
  LLength := Length(Value) + 1;
  AStream.Write(LLength, SizeOf(LLength));
  GetMem(LPBuffer, LLength * SizeOf(Char));
  try
    FillMemory(LPBuffer, LLength, 0);
    WStrCopy(LPBuffer, PChar(Value));
    AStream.Write(LPBuffer^, LLength * SizeOf(Char));
  finally
    FreeMem(LPBuffer);
  end;
  AStream.Write(RepeatCount, SizeOf(RepeatCount));
end;

{ TTextEditorMacroEvent }

constructor TTextEditorMacroEvent.Create;
begin
  inherited;

  FRepeatCount := 1;
end;

end.
