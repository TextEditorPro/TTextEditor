unit TextEditor.LanguageServer;

{ Language Server Protocol client for TTextEditor built on the LSP-Pascal-Library (https://github.com/rickard67/LSP-Pascal-Library).
  Requires the System.JSON based library (2024 or later, with TLSPClient.SendSyncRequest and the Json...ToObject functions in
  XLSPFunctions); the earlier XSuperObject based library does not compile with this unit.

  One instance drives one server process and holds one document per attached editor. Response handlers run in the library's
  server thread and only convert JSON to plain values; everything that touches an editor is queued to the main thread. }

interface

uses
  Winapi.Windows, System.Classes, System.Generics.Collections, System.JSON, System.SysUtils, System.Types, System.UITypes, Vcl.Controls,
  Vcl.ExtCtrls, TextEditor, TextEditor.CompletionProposal.PopupWindow, TextEditor.Hover.PopupWindow, TextEditor.Marks, TextEditor.Types,
  XLSPClient, XLSPTypes;

type
  TTextEditorLanguageServerState = (lssStopped, lssStarting, lssRunning, lssStopping);

  TTextEditorLanguageServerDiagnostic = record
    BeginPosition: TTextEditorTextPosition;
    Deprecated: Boolean;
    EndPosition: TTextEditorTextPosition;
    &Message: string;
    Severity: Integer;
    Source: string;
    Unnecessary: Boolean;
  end;

  TTextEditorLanguageServerHoverPart = record
    Code: Boolean;
    Text: string;
  end;

  TTextEditorLanguageServerLocation = record
    FileName: string;
    TextPosition: TTextEditorTextPosition;
  end;

  TTextEditorLanguageServerSignature = record
    Parameters: TArray<string>;
    Text: string;
  end;

  TTextEditorLanguageServerSignatureHelp = record
    ActiveParameter: Integer;
    ActiveSignature: Integer;
    Signatures: TArray<TTextEditorLanguageServerSignature>;
  end;

  ITextEditorLanguageServerLifetime = interface
    ['{5B0C2E3A-9D1F-4C6B-8E27-3A4F1D0B7C90}']
    function IsAlive: Boolean;
    procedure Expire;
  end;

  TTextEditorLanguageServerDocument = class(TObject)
  strict private
    FChangePending: Boolean;
    FDiagnostics: TArray<TTextEditorLanguageServerDiagnostic>;
    FEditor: TCustomTextEditor;
    FFileName: string;
    FLanguageId: string;
    FMarkCount: Integer;
    FOpen: Boolean;
    FVersion: Integer;
  public
    constructor Create(const AEditor: TCustomTextEditor; const AFileName: string; const ALanguageId: string);
    function Uri: string;
    property ChangePending: Boolean read FChangePending write FChangePending;
    property Diagnostics: TArray<TTextEditorLanguageServerDiagnostic> read FDiagnostics write FDiagnostics;
    property Editor: TCustomTextEditor read FEditor;
    property FileName: string read FFileName write FFileName;
    property LanguageId: string read FLanguageId write FLanguageId;
    property MarkCount: Integer read FMarkCount write FMarkCount;
    property Open: Boolean read FOpen write FOpen;
    property Version: Integer read FVersion write FVersion;
  end;

  TTextEditorLanguageServerDiagnosticsEvent = procedure(const ASender: TObject; const AEditor: TCustomTextEditor; const ADiagnostics: TArray<TTextEditorLanguageServerDiagnostic>) of object;
  TTextEditorLanguageServerLocationEvent = procedure(const ASender: TObject; const AEditor: TCustomTextEditor; const ALocation: TTextEditorLanguageServerLocation) of object;
  TTextEditorLanguageServerLogEvent = procedure(const ASender: TObject; const AMessage: string) of object;
  TTextEditorLanguageServerStateEvent = procedure(const ASender: TObject; const AState: TTextEditorLanguageServerState) of object;

  TTextEditorLanguageServer = class(TComponent)
  strict private
    FAutoRestart: Boolean;
    FChangeTimer: TTimer;
    FClient: TLSPClient;
    FCompletionEditor: TCustomTextEditor;
    FCompletionGeneration: Integer;
    FCompletionIncomplete: Boolean;
    FCompletionItems: TArray<TLSPCompletionItem>;
    FCompletionItemsOffset: Integer;
    FCompletionItemsResolved: TArray<Boolean>;
    FCompletionTriggerEditor: TCustomTextEditor;
    FCompletionTriggerEnabled: Boolean;
    FCompletionTriggerTimer: TTimer;
    FConfiguration: string;
    FDiagnosticErrorColor: TColor;
    FDiagnosticInformationColor: TColor;
    FDiagnosticMarkImageIndex: Integer;
    FDiagnosticMarkIndex: Integer;
    FDiagnosticWarningColor: TColor;
    FDocuments: TObjectList<TTextEditorLanguageServerDocument>;
    FExitCode: Integer;
    FHoverCloseTimer: TTimer;
    FHoverCursorPoint: TPoint;
    FHoverDelay: Integer;
    FHoverEditor: TCustomTextEditor;
    FHoverEnabled: Boolean;
    FHoverKeepRect: TRect;
    FHoverLocation: TTextEditorLanguageServerLocation;
    FHoverLocationValid: Boolean;
    FHoverParts: TArray<TTextEditorLanguageServerHoverPart>;
    FHoverPendingCount: Integer;
    FHoverPopup: TTextEditorHoverPopupWindow;
    FHoverPosition: TTextEditorTextPosition;
    FHoverSerial: Integer;
    FHoverTimer: TTimer;
    FHoverWord: string;
    FInitializationOptions: string;
    FLifetime: ITextEditorLanguageServerLifetime;
    FLogTraffic: Boolean;
    FOnDiagnostics: TTextEditorLanguageServerDiagnosticsEvent;
    FOnGotoLocation: TTextEditorLanguageServerLocationEvent;
    FOnLog: TTextEditorLanguageServerLogEvent;
    FOnStateChange: TTextEditorLanguageServerStateEvent;
    FResolveTimer: TTimer;
    FRestartCount: Integer;
    FRestartTimer: TTimer;
    FRootPath: string;
    FServerCommandLine: string;
    FServerDirectory: string;
    FSignatureHelpActive: Boolean;
    FSignatureHelpEditor: TCustomTextEditor;
    FSignatureHelpEnabled: Boolean;
    FSignatureHelpPopup: TTextEditorHoverPopupWindow;
    FSignatureHelpSerial: Integer;
    FSignatureHelpTimer: TTimer;
    FState: TTextEditorLanguageServerState;
    FSyncRequestTimeout: Integer;
    class function ConvertHover(const AHover: TLSPHoverResult): TArray<TTextEditorLanguageServerHoverPart>;
    class function ConvertSignatureHelp(const AResult: TLSPSignatureHelpResult; out AHelp: TTextEditorLanguageServerSignatureHelp): Boolean;
    class function DecodeRawJsonString(const AText: string): string;
    class function ExtractGotoLocation(const AGotoResult: TLSPGotoResult; out ALocation: TTextEditorLanguageServerLocation): Boolean;
    class function FadeColor(const AColor: TColor; const ABackground: TColor): TColor;
    class function ParseHoverParts(const AText: string; const ACode: Boolean): TArray<TTextEditorLanguageServerHoverPart>;
    class function PositionToEditor(const APosition: TLSPPosition): TTextEditorTextPosition;
    class function PositionToLSP(const ATextPosition: TTextEditorTextPosition): TLSPPosition;
    class function ResolvedItemDescription(const AItem: TLSPCompletionItem): string;
    class function StripSnippetPlaceholders(const AText: string): string;
    class function TruncateDescription(const AText: string): string;
    class procedure QueueToMainThread(const ALifetime: ITextEditorLanguageServerLifetime; const AProc: TThreadProcedure);
    function CompletionItemInsertText(const AItem: TLSPCompletionItem; const ALineText: string; const AWordStartChar: Integer): string;
    function CompletionItemKindText(const AKind: Integer; const ADetail: string; const ALanguageId: string): string;
    function DocumentForEditor(const AEditor: TCustomTextEditor): TTextEditorLanguageServerDocument;
    function DocumentForUri(const AUri: string): TTextEditorLanguageServerDocument;
    function GetActive: Boolean;
    function GetDocumentCount: Integer;
    function GetInitialized: Boolean;
    function HoverKeepZone: TRect;
    function IsCompletionTriggerCharacter(const AChar: Char): Boolean;
    function IsSignatureHelpTriggerCharacter(const AChar: Char): Boolean;
    function OpenDocumentFor(const AEditor: TCustomTextEditor): TTextEditorLanguageServerDocument;
    function QuotedCommandLine(const ACommandLine: string): string;
    function SyncRequest(const AKind: TLSPKind; const AParams: TLSPBaseParams; const AConvert: TFunc<TJSONValue, TObject>): TObject;
    procedure ApplyDiagnostics(const ADocument: TTextEditorLanguageServerDocument);
    procedure ApplyResolvedDescription(const AEditor: TCustomTextEditor; const AGeneration: Integer; const AItemsIndex: Integer; const ADescription: string);
    procedure ChangeTimerTimer(ASender: TObject);
    procedure ClientError(ASender: TObject; const AId, AErrorCode: Integer; const AErrorMessage: string; ARetriggerRequest: Boolean);
    procedure ClientExit(ASender: TObject; AExitCode: Integer; const ARestartServer: Boolean);
    procedure ClientInitialize(ASender: TObject; var AValue: TLSPInitializeParams);
    procedure ClientInitialized(ASender: TObject; var AValue: TLSPInitializeResult);
    procedure ClientLogMessage(ASender: TObject; const AType: TLSPMessageType; const AMessage: string);
    procedure ClientPublishDiagnostics(ASender: TObject; const AUri: string; const AVersion: Cardinal; const ADiagnostics: TArray<TLSPDiagnostic>);
    procedure CompletionSelectedItemChange(ASender: TObject);
    procedure CompletionTriggerTimerTimer(ASender: TObject);
    procedure EditorCompletionProposalExecute(const ASender: TObject; var AParams: TCompletionProposalParams);
    procedure EditorCustomTokenAttribute(const ASender: TObject; const AText: string; const ALine: Integer; const AChar: Integer;
      var AForegroundColor: TColor; var ABackgroundColor: TColor; var AStyles: TFontStyles; var AUnderline: TTextEditorUnderline;
      var AUnderlineColor: TColor);
    procedure EditorDocumentChanged(ASender: TObject);
    procedure EditorKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
    procedure EditorKeyPress(const ASender: TObject; var AKey: Char);
    procedure EditorMouseCursor(const ASender: TObject; const ALineCharPos: TTextEditorTextPosition; var ACursor: TCursor);
    procedure EditorMouseDown(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
    procedure EnsureHoverPopup(const AEditor: TCustomTextEditor);
    procedure EnsureSignatureHelpPopup(const AEditor: TCustomTextEditor);
    procedure FreeCompletionItems;
    procedure FreeHoverPopup;
    procedure FreeSignatureHelpPopup;
    procedure HideHover;
    procedure HideSignatureHelp;
    procedure HookEditor(const AEditor: TCustomTextEditor);
    procedure HoverCloseTimerTimer(ASender: TObject);
    procedure HoverLinkClick(ASender: TObject);
    procedure HoverRequestCompleted;
    procedure HoverTimerTimer(ASender: TObject);
    procedure InternalStart;
    procedure Log(const AMessage: string);
    procedure RemoveDocument(const ADocument: TTextEditorLanguageServerDocument);
    procedure RequestHover;
    procedure ResolveTimerTimer(ASender: TObject);
    procedure RestartTimerTimer(ASender: TObject);
    procedure SendDidChange(const ADocument: TTextEditorLanguageServerDocument);
    procedure SendDidClose(const ADocument: TTextEditorLanguageServerDocument);
    procedure SendDidOpen(const ADocument: TTextEditorLanguageServerDocument);
    procedure SetHoverDelay(const AValue: Integer);
    procedure SetState(const AValue: TTextEditorLanguageServerState);
    procedure ShowHoverPopup;
    procedure ShowSignatureHelpPopup(const AEditor: TCustomTextEditor; const AHelp: TTextEditorLanguageServerSignatureHelp);
    procedure SignatureHelpTimerTimer(ASender: TObject);
    procedure StartCompletionTrigger(const AEditor: TCustomTextEditor; const AInterval: Integer);
    procedure SyncDocument(const ADocument: TTextEditorLanguageServerDocument);
    procedure UnhookEditor(const AEditor: TCustomTextEditor);
    procedure UpdateSignatureHelp(const AEditor: TCustomTextEditor);
    procedure WaitForExit(const ATimeout: Integer);
  protected
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class function FileNameToUri(const AFileName: string): string;
    function Completion(const AEditor: TCustomTextEditor; const AItems: TTextEditorCompletionProposalItems): Boolean;
    function DiagnosticAt(const AEditor: TCustomTextEditor; const ATextPosition: TTextEditorTextPosition; out ADiagnostic: TTextEditorLanguageServerDiagnostic): Boolean;
    function DiagnosticsFor(const AEditor: TCustomTextEditor): TArray<TTextEditorLanguageServerDiagnostic>;
    function FindDefinition(const AEditor: TCustomTextEditor; const ATextPosition: TTextEditorTextPosition; out ALocation: TTextEditorLanguageServerLocation): Boolean;
    function HasDocument(const AEditor: TCustomTextEditor): Boolean;
    function Hover(const AEditor: TCustomTextEditor; const ATextPosition: TTextEditorTextPosition): string;
    function HoverParts(const AEditor: TCustomTextEditor; const ATextPosition: TTextEditorTextPosition): TArray<TTextEditorLanguageServerHoverPart>;
    function SignatureHelp(const AEditor: TCustomTextEditor; const ATextPosition: TTextEditorTextPosition; out AHelp: TTextEditorLanguageServerSignatureHelp): Boolean;
    procedure BeforeDestruction; override;
    procedure CloseDocument(const AEditor: TCustomTextEditor);
    procedure DocumentSaved(const AEditor: TCustomTextEditor);
    procedure GotoDefinition(const AEditor: TCustomTextEditor);
    procedure OpenDocument(const AEditor: TCustomTextEditor; const AFileName: string; const ALanguageId: string);
    procedure SendConfiguration(const ASettingsJson: string);
    procedure Start;
    procedure Stop;
    property Active: Boolean read GetActive;
    property DocumentCount: Integer read GetDocumentCount;
    property ExitCode: Integer read FExitCode;
    property Initialized: Boolean read GetInitialized;
    property State: TTextEditorLanguageServerState read FState;
  published
    property AutoRestart: Boolean read FAutoRestart write FAutoRestart default False;
    property CompletionTriggerEnabled: Boolean read FCompletionTriggerEnabled write FCompletionTriggerEnabled default True;
    property Configuration: string read FConfiguration write FConfiguration;
    property DiagnosticErrorColor: TColor read FDiagnosticErrorColor write FDiagnosticErrorColor default TColors.Red;
    property DiagnosticInformationColor: TColor read FDiagnosticInformationColor write FDiagnosticInformationColor default TColors.Dodgerblue;
    property DiagnosticMarkImageIndex: Integer read FDiagnosticMarkImageIndex write FDiagnosticMarkImageIndex default -1;
    property DiagnosticMarkIndex: Integer read FDiagnosticMarkIndex write FDiagnosticMarkIndex default 1000;
    property DiagnosticWarningColor: TColor read FDiagnosticWarningColor write FDiagnosticWarningColor default TColors.Orange;
    property HoverDelay: Integer read FHoverDelay write SetHoverDelay default 600;
    property HoverEnabled: Boolean read FHoverEnabled write FHoverEnabled default True;
    property InitializationOptions: string read FInitializationOptions write FInitializationOptions;
    property LogTraffic: Boolean read FLogTraffic write FLogTraffic default False;
    property OnDiagnostics: TTextEditorLanguageServerDiagnosticsEvent read FOnDiagnostics write FOnDiagnostics;
    property OnGotoLocation: TTextEditorLanguageServerLocationEvent read FOnGotoLocation write FOnGotoLocation;
    property OnLog: TTextEditorLanguageServerLogEvent read FOnLog write FOnLog;
    property OnStateChange: TTextEditorLanguageServerStateEvent read FOnStateChange write FOnStateChange;
    property RootPath: string read FRootPath write FRootPath;
    property ServerCommandLine: string read FServerCommandLine write FServerCommandLine;
    property ServerDirectory: string read FServerDirectory write FServerDirectory;
    property SignatureHelpEnabled: Boolean read FSignatureHelpEnabled write FSignatureHelpEnabled default True;
    property SyncRequestTimeout: Integer read FSyncRequestTimeout write FSyncRequestTimeout default 1000;
  end;

const
  LANGUAGE_SERVER_SEVERITY_ERROR = 1;
  LANGUAGE_SERVER_SEVERITY_WARNING = 2;
  LANGUAGE_SERVER_SEVERITY_INFORMATION = 3;
  LANGUAGE_SERVER_SEVERITY_HINT = 4;
  LANGUAGE_SERVER_TAG_UNNECESSARY = 1;
  LANGUAGE_SERVER_TAG_DEPRECATED = 2;

implementation

uses
  System.Diagnostics, System.Generics.Defaults, System.Math, Vcl.Graphics, TextEditor.Consts, TextEditor.Highlighter,
  TextEditor.PaintHelper, XLSPFunctions;

type
  ITextEditorLanguageServerResultHolder = interface
    ['{A1D4F7B2-6E3C-4B9A-9C58-0F2E7D1B3A64}']
    function Extract: TObject;
    procedure SetValue(const AValue: TObject);
  end;

  { Keeps a converted response alive until either the waiting caller extracts it or, after a timeout, the late response handler
    is released together with the holder. A late response therefore never leaks and never reaches a caller that has moved on. }
  TTextEditorLanguageServerResultHolder = class(TInterfacedObject, ITextEditorLanguageServerResultHolder)
  strict private
    FValue: TObject;
  public
    destructor Destroy; override;
    function Extract: TObject;
    procedure SetValue(const AValue: TObject);
  end;

  TTextEditorLanguageServerLifetime = class(TInterfacedObject, ITextEditorLanguageServerLifetime)
  strict private
    FAlive: Boolean;
  public
    constructor Create;
    function IsAlive: Boolean;
    procedure Expire;
  end;

const
  CHANGE_DEBOUNCE_MS = 300;
  EXIT_WAIT_MS = 1500;
  HOVER_CLOSE_POLL_MS = 100;
  INSERT_TEXT_FORMAT_SNIPPET = 2;
  MAX_COMPLETION_DESCRIPTION_LENGTH = 100;
  MAX_RESTART_COUNT = 3;
  RESOLVE_DELAY_MS = 150;
  RESTART_DELAY_MS = 1000;
  RETRIGGER_DELAY_MS = 50;
  SIGNATURE_HELP_DELAY_MS = 50;

{ TTextEditorLanguageServerResultHolder }

destructor TTextEditorLanguageServerResultHolder.Destroy;
begin
  FValue.Free;

  inherited Destroy;
end;

function TTextEditorLanguageServerResultHolder.Extract: TObject;
begin
  Result := FValue;
  FValue := nil;
end;

procedure TTextEditorLanguageServerResultHolder.SetValue(const AValue: TObject);
begin
  FValue.Free;
  FValue := AValue;
end;

{ TTextEditorLanguageServerLifetime }

constructor TTextEditorLanguageServerLifetime.Create;
begin
  inherited Create;

  FAlive := True;
end;

function TTextEditorLanguageServerLifetime.IsAlive: Boolean;
begin
  Result := FAlive;
end;

procedure TTextEditorLanguageServerLifetime.Expire;
begin
  FAlive := False;
end;

{ TTextEditorLanguageServerDocument }

constructor TTextEditorLanguageServerDocument.Create(const AEditor: TCustomTextEditor; const AFileName: string; const ALanguageId: string);
begin
  inherited Create;

  FEditor := AEditor;
  FFileName := AFileName;
  FLanguageId := ALanguageId;
  FVersion := 1;
end;

function TTextEditorLanguageServerDocument.Uri: string;
begin
  Result := FilePathToUri(FFileName);
end;

{ TTextEditorLanguageServer }

constructor TTextEditorLanguageServer.Create(AOwner: TComponent);

  function NewTimer(const AInterval: Integer; const AOnTimer: TNotifyEvent): TTimer;
  begin
    Result := TTimer.Create(Self);
    Result.Enabled := False;
    Result.Interval := AInterval;
    Result.OnTimer := AOnTimer;
  end;

begin
  inherited Create(AOwner);

  FLifetime := TTextEditorLanguageServerLifetime.Create;
  FDocuments := TObjectList<TTextEditorLanguageServerDocument>.Create(True);

  FCompletionTriggerEnabled := True;
  FDiagnosticErrorColor := TColors.Red;
  FDiagnosticInformationColor := TColors.Dodgerblue;
  FDiagnosticMarkImageIndex := -1;
  FDiagnosticMarkIndex := 1000;
  FDiagnosticWarningColor := TColors.Orange;
  FHoverDelay := 600;
  FHoverEnabled := True;
  FSignatureHelpEnabled := True;
  FSyncRequestTimeout := 1000;

  FClient := TLSPClient.Create(Self);
  FClient.OnError := ClientError;
  FClient.OnExit := ClientExit;
  FClient.OnInitialize := ClientInitialize;
  FClient.OnInitialized := ClientInitialized;
  FClient.OnLogMessage := ClientLogMessage;
  FClient.OnShowMessage := ClientLogMessage;
  FClient.OnPublishDiagnostics := ClientPublishDiagnostics;

  FChangeTimer := NewTimer(CHANGE_DEBOUNCE_MS, ChangeTimerTimer);
  FCompletionTriggerTimer := NewTimer(RETRIGGER_DELAY_MS, CompletionTriggerTimerTimer);
  FHoverCloseTimer := NewTimer(HOVER_CLOSE_POLL_MS, HoverCloseTimerTimer);
  FHoverTimer := NewTimer(FHoverDelay, HoverTimerTimer);
  FResolveTimer := NewTimer(RESOLVE_DELAY_MS, ResolveTimerTimer);
  FRestartTimer := NewTimer(RESTART_DELAY_MS, RestartTimerTimer);
  FSignatureHelpTimer := NewTimer(SIGNATURE_HELP_DELAY_MS, SignatureHelpTimerTimer);
end;

procedure TTextEditorLanguageServer.BeforeDestruction;
begin
  { Shut the server down before the inherited call flags the owned client as destroying: from then on the library drops its
    exit event, the state would never reach stopped, and the client would have to kill the server thread, which then frees
    itself after the application has already finalized (a leak or an access violation at exit). }
  FAutoRestart := False;
  Stop;
  WaitForExit(EXIT_WAIT_MS);

  inherited BeforeDestruction;
end;

destructor TTextEditorLanguageServer.Destroy;
begin
  FLifetime.Expire;

  FAutoRestart := False;
  FOnDiagnostics := nil;
  FOnGotoLocation := nil;
  FOnLog := nil;
  FOnStateChange := nil;

  while FDocuments.Count > 0 do
    RemoveDocument(FDocuments.Last);

  FreeCompletionItems;
  FreeHoverPopup;
  FreeSignatureHelpPopup;
  FDocuments.Free;

  inherited Destroy;
end;

class function TTextEditorLanguageServer.FileNameToUri(const AFileName: string): string;
begin
  Result := FilePathToUri(AFileName);
end;

class function TTextEditorLanguageServer.DecodeRawJsonString(const AText: string): string;
var
  LValue: TJSONValue;
begin
  Result := AText;

  if not AText.StartsWith('"') then
    Exit;

  LValue := TJSONObject.ParseJSONValue(AText);
  try
    if LValue is TJSONString then
      Result := TJSONString(LValue).Value;
  finally
    LValue.Free;
  end;
end;

class function TTextEditorLanguageServer.PositionToLSP(const ATextPosition: TTextEditorTextPosition): TLSPPosition;
begin
  Result.line := Max(0, ATextPosition.Line);
  Result.character := Max(0, ATextPosition.Char - 1);
end;

class function TTextEditorLanguageServer.FadeColor(const AColor: TColor; const ABackground: TColor): TColor;
var
  LColor, LBackground: Longint;
begin
  LColor := ColorToRGB(AColor);
  LBackground := ColorToRGB(ABackground);

  Result := RGB((GetRValue(LColor) + GetRValue(LBackground)) div 2, (GetGValue(LColor) + GetGValue(LBackground)) div 2,
    (GetBValue(LColor) + GetBValue(LBackground)) div 2);
end;

class function TTextEditorLanguageServer.PositionToEditor(const APosition: TLSPPosition): TTextEditorTextPosition;
begin
  Result.Line := APosition.line;
  Result.Char := APosition.character + 1;
end;

class function TTextEditorLanguageServer.TruncateDescription(const AText: string): string;
begin
  Result := AText.Replace(#13, '').Replace(#10, ' ');

  if Result.Length > MAX_COMPLETION_DESCRIPTION_LENGTH then
    Result := Copy(Result, 1, MAX_COMPLETION_DESCRIPTION_LENGTH - 3) + '...';
end;

class procedure TTextEditorLanguageServer.QueueToMainThread(const ALifetime: ITextEditorLanguageServerLifetime;
  const AProc: TThreadProcedure);
begin
  TThread.Queue(nil,
    procedure
    begin
      if ALifetime.IsAlive then
        AProc;
    end);
end;

function TTextEditorLanguageServer.GetActive: Boolean;
begin
  Result := FState in [lssStarting, lssRunning];
end;

function TTextEditorLanguageServer.GetDocumentCount: Integer;
begin
  Result := FDocuments.Count;
end;

function TTextEditorLanguageServer.GetInitialized: Boolean;
begin
  Result := (FState = lssRunning) and FClient.Initialized;
end;

procedure TTextEditorLanguageServer.Log(const AMessage: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, AMessage);
end;

procedure TTextEditorLanguageServer.SetHoverDelay(const AValue: Integer);
begin
  FHoverDelay := AValue;
  FHoverTimer.Interval := Max(1, AValue);
end;

procedure TTextEditorLanguageServer.SetState(const AValue: TTextEditorLanguageServerState);
begin
  if AValue = FState then
    Exit;

  FState := AValue;

  if Assigned(FOnStateChange) then
    FOnStateChange(Self, FState);
end;

procedure TTextEditorLanguageServer.Notification(AComponent: TComponent; AOperation: TOperation);
var
  LDocument: TTextEditorLanguageServerDocument;
begin
  inherited Notification(AComponent, AOperation);

  if AOperation <> opRemove then
    Exit;

  if AComponent = FHoverPopup then
    FHoverPopup := nil;

  if AComponent = FSignatureHelpPopup then
    FSignatureHelpPopup := nil;

  if AComponent is TCustomTextEditor then
  begin
    LDocument := DocumentForEditor(TCustomTextEditor(AComponent));

    if Assigned(LDocument) then
      RemoveDocument(LDocument);
  end;
end;

{ Documents }

function TTextEditorLanguageServer.DocumentForEditor(const AEditor: TCustomTextEditor): TTextEditorLanguageServerDocument;
var
  LDocument: TTextEditorLanguageServerDocument;
begin
  for LDocument in FDocuments do
  if LDocument.Editor = AEditor then
    Exit(LDocument);

  Result := nil;
end;

function TTextEditorLanguageServer.DocumentForUri(const AUri: string): TTextEditorLanguageServerDocument;
var
  LDocument: TTextEditorLanguageServerDocument;
  LFileName: string;
begin
  LFileName := UriToFilePath(AUri);

  for LDocument in FDocuments do
  if SameText(LDocument.FileName, LFileName) then
    Exit(LDocument);

  Result := nil;
end;

function TTextEditorLanguageServer.OpenDocumentFor(const AEditor: TCustomTextEditor): TTextEditorLanguageServerDocument;
begin
  Result := DocumentForEditor(AEditor);

  if Assigned(Result) and (not Result.Open or not Initialized) then
    Result := nil;
end;

function TTextEditorLanguageServer.HasDocument(const AEditor: TCustomTextEditor): Boolean;
begin
  Result := Assigned(DocumentForEditor(AEditor));
end;

procedure TTextEditorLanguageServer.HookEditor(const AEditor: TCustomTextEditor);
begin
  AEditor.FreeNotification(Self);
  AEditor.AddChangeNotification(EditorDocumentChanged);
  AEditor.AddCompletionProposalExecuteHandler(EditorCompletionProposalExecute);
  AEditor.AddCustomTokenAttributeHandler(EditorCustomTokenAttribute);
  AEditor.AddKeyDownHandler(EditorKeyDown);
  AEditor.AddKeyPressHandler(EditorKeyPress);
  AEditor.AddMouseCursorHandler(EditorMouseCursor);
  AEditor.AddMouseDownHandler(EditorMouseDown);
end;

procedure TTextEditorLanguageServer.UnhookEditor(const AEditor: TCustomTextEditor);
begin
  if FHoverEditor = AEditor then
    HideHover;

  if FSignatureHelpEditor = AEditor then
    HideSignatureHelp;

  if FCompletionTriggerEditor = AEditor then
  begin
    FCompletionTriggerTimer.Enabled := False;
    FCompletionTriggerEditor := nil;
  end;

  if FCompletionEditor = AEditor then
  begin
    FResolveTimer.Enabled := False;
    FCompletionEditor := nil;
  end;

  if Assigned(FHoverPopup) and (FHoverPopup.Owner = AEditor) then
    FreeHoverPopup;

  if Assigned(FSignatureHelpPopup) and (FSignatureHelpPopup.Owner = AEditor) then
    FreeSignatureHelpPopup;

  if csDestroying in AEditor.ComponentState then
    Exit;

  AEditor.RemoveFreeNotification(Self);
  AEditor.RemoveChangeNotification(EditorDocumentChanged);
  AEditor.RemoveCompletionProposalExecuteHandler(EditorCompletionProposalExecute);
  AEditor.RemoveCustomTokenAttributeHandler(EditorCustomTokenAttribute);
  AEditor.RemoveKeyDownHandler(EditorKeyDown);
  AEditor.RemoveKeyPressHandler(EditorKeyPress);
  AEditor.RemoveMouseCursorHandler(EditorMouseCursor);
  AEditor.RemoveMouseDownHandler(EditorMouseDown);
end;

procedure TTextEditorLanguageServer.OpenDocument(const AEditor: TCustomTextEditor; const AFileName: string; const ALanguageId: string);
var
  LDocument: TTextEditorLanguageServerDocument;
begin
  if not Assigned(AEditor) then
    raise Exception.Create('Language server document requires an editor');

  if AFileName.IsEmpty then
    raise Exception.Create('Language server document requires a file name');

  LDocument := DocumentForEditor(AEditor);

  if Assigned(LDocument) then
  begin
    if SameText(LDocument.FileName, AFileName) and (LDocument.LanguageId = ALanguageId) then
    begin
      if LDocument.Open then
        SendDidChange(LDocument)
      else
        SendDidOpen(LDocument);

      Exit;
    end;

    SendDidClose(LDocument);

    LDocument.FileName := AFileName;
    LDocument.LanguageId := ALanguageId;
  end
  else
  begin
    LDocument := TTextEditorLanguageServerDocument.Create(AEditor, AFileName, ALanguageId);
    FDocuments.Add(LDocument);
    HookEditor(AEditor);
  end;

  SendDidOpen(LDocument);
end;

procedure TTextEditorLanguageServer.CloseDocument(const AEditor: TCustomTextEditor);
var
  LDocument: TTextEditorLanguageServerDocument;
begin
  LDocument := DocumentForEditor(AEditor);

  if Assigned(LDocument) then
    RemoveDocument(LDocument);
end;

procedure TTextEditorLanguageServer.RemoveDocument(const ADocument: TTextEditorLanguageServerDocument);
var
  LEditor: TCustomTextEditor;
begin
  LEditor := ADocument.Editor;

  SendDidClose(ADocument);
  UnhookEditor(LEditor);

  FDocuments.Remove(ADocument);
end;

procedure TTextEditorLanguageServer.SendDidOpen(const ADocument: TTextEditorLanguageServerDocument);
var
  LParams: TLSPDidOpenTextDocumentParams;
begin
  if not Initialized then
    Exit;

  ADocument.Version := 1;
  ADocument.ChangePending := False;

  LParams := TLSPDidOpenTextDocumentParams.Create;
  try
    LParams.textDocument.uri := ADocument.Uri;
    LParams.textDocument.languageId := ADocument.LanguageId;
    LParams.textDocument.version := ADocument.Version;
    LParams.textDocument.text := ADocument.Editor.Text;

    FClient.SendNotification(lspDidOpenTextDocument, '', LParams);
  finally
    LParams.Free;
  end;

  ADocument.Open := True;
end;

procedure TTextEditorLanguageServer.SendDidClose(const ADocument: TTextEditorLanguageServerDocument);
var
  LParams: TLSPDidCloseTextDocumentParams;
begin
  if ADocument.Open and Initialized then
  begin
    LParams := TLSPDidCloseTextDocumentParams.Create;
    try
      LParams.textDocument.uri := ADocument.Uri;

      FClient.SendNotification(lspDidCloseTextDocument, '', LParams);
    finally
      LParams.Free;
    end;
  end;

  ADocument.Open := False;
  ADocument.ChangePending := False;
  ADocument.Diagnostics := nil;

  ApplyDiagnostics(ADocument);
end;

procedure TTextEditorLanguageServer.SendDidChange(const ADocument: TTextEditorLanguageServerDocument);
var
  LParams: TLSPDidChangeTextDocumentParams;
  LChange: TLSPBaseTextDocumentContentChangeEvent;
begin
  if not ADocument.Open or not Initialized then
    Exit;

  ADocument.ChangePending := False;
  ADocument.Version := ADocument.Version + 1;

  LChange := TLSPBaseTextDocumentContentChangeEvent.Create;
  LChange.text := ADocument.Editor.Text;

  LParams := TLSPDidChangeTextDocumentParams.Create;
  try
    LParams.textDocument.uri := ADocument.Uri;
    LParams.textDocument.version := ADocument.Version;
    LParams.contentChanges := [LChange];

    FClient.SendNotification(lspDidChangeTextDocument, '', LParams);
  finally
    LParams.Free;
  end;
end;

procedure TTextEditorLanguageServer.SyncDocument(const ADocument: TTextEditorLanguageServerDocument);
begin
  if ADocument.ChangePending then
    SendDidChange(ADocument);
end;

procedure TTextEditorLanguageServer.DocumentSaved(const AEditor: TCustomTextEditor);
var
  LDocument: TTextEditorLanguageServerDocument;
  LParams: TLSPDidSaveTextDocumentParams;
begin
  LDocument := OpenDocumentFor(AEditor);

  if not Assigned(LDocument) then
    Exit;

  SyncDocument(LDocument);

  LParams := TLSPDidSaveTextDocumentParams.Create;
  try
    LParams.textDocument.uri := LDocument.Uri;

    if FClient.IncludeText(lspDidSaveTextDocument, False) then
      LParams.text := AEditor.Text;

    FClient.SendNotification(lspDidSaveTextDocument, '', LParams);
  finally
    LParams.Free;
  end;
end;

procedure TTextEditorLanguageServer.EditorDocumentChanged(ASender: TObject);
var
  LDocument: TTextEditorLanguageServerDocument;
begin
  HideHover;

  LDocument := DocumentForEditor(TCustomTextEditor(ASender));

  if Assigned(LDocument) and LDocument.Open then
  begin
    LDocument.ChangePending := True;

    FChangeTimer.Enabled := False;
    FChangeTimer.Enabled := True;
  end;
end;

procedure TTextEditorLanguageServer.ChangeTimerTimer(ASender: TObject);
var
  LDocument: TTextEditorLanguageServerDocument;
begin
  FChangeTimer.Enabled := False;

  for LDocument in FDocuments do
  if LDocument.ChangePending then
    SendDidChange(LDocument);
end;

{ Server lifecycle }

procedure TTextEditorLanguageServer.Start;
begin
  FRestartCount := 0;

  InternalStart;
end;

procedure TTextEditorLanguageServer.InternalStart;
var
  LCommandLine: string;
begin
  if Active then
    Exit;

  if FState = lssStopping then
    raise Exception.Create('Language server is still stopping');

  if FServerCommandLine.IsEmpty then
    raise Exception.Create('Language server command line is not set');

  FExitCode := 0;
  LCommandLine := QuotedCommandLine(FServerCommandLine);

  Log('Starting ' + LCommandLine);

  SetState(lssStarting);

  FClient.RunServer(LCommandLine, FServerDirectory);
  FClient.SendRequest(lspInitialize);
end;

procedure TTextEditorLanguageServer.Stop;
var
  LDocument: TTextEditorLanguageServerDocument;
begin
  FRestartTimer.Enabled := False;

  if not Active then
    Exit;

  HideHover;
  HideSignatureHelp;

  FChangeTimer.Enabled := False;
  FCompletionTriggerTimer.Enabled := False;
  FResolveTimer.Enabled := False;

  for LDocument in FDocuments do
    SendDidClose(LDocument);

  Log('Stopping server');

  SetState(lssStopping);

  { The library answers the shutdown response with the exit notification and reports the exit through ClientExit }
  FClient.CloseServer;
end;

procedure TTextEditorLanguageServer.WaitForExit(const ATimeout: Integer);
var
  LStopwatch: TStopwatch;
begin
  LStopwatch := TStopwatch.StartNew;

  while ((FState = lssStopping) or FClient.Initialized) and (LStopwatch.ElapsedMilliseconds < ATimeout) do
    CheckSynchronize(10);
end;

procedure TTextEditorLanguageServer.RestartTimerTimer(ASender: TObject);
begin
  FRestartTimer.Enabled := False;

  if FState <> lssStopped then
    Exit;

  try
    InternalStart;
  except
    on E: Exception do
      Log('Restart failed: ' + E.Message);
  end;
end;

function TTextEditorLanguageServer.QuotedCommandLine(const ACommandLine: string): string;

  function WithExecutable(const AExecutable, AArguments: string): string;
  begin
    if SameText(ExtractFileExt(AExecutable), '.cmd') or SameText(ExtractFileExt(AExecutable), '.bat') then
      Result := 'cmd.exe /c "' + AExecutable + '"' + AArguments
    else
    if AExecutable.Contains(' ') then
      Result := '"' + AExecutable + '"' + AArguments
    else
      Result := AExecutable + AArguments;
  end;

var
  LIndex: Integer;
  LCandidate: string;
begin
  Result := ACommandLine.Trim;

  if Result.IsEmpty then
    Exit;

  if Result.StartsWith('"') then
  begin
    LIndex := Result.IndexOf('"', 1);

    if LIndex > 1 then
      Result := WithExecutable(Result.Substring(1, LIndex - 1), Result.Substring(LIndex + 1));

    Exit;
  end;

  if Result.IndexOf(' ') < 0 then
    Exit(WithExecutable(Result, ''));

  LIndex := 0;

  while LIndex >= 0 do
  begin
    LIndex := Result.IndexOf(' ', LIndex + 1);

    LCandidate := if LIndex < 0 then Result else Result.Substring(0, LIndex);

    if FileExists(LCandidate) then
      Exit(WithExecutable(LCandidate, Result.Substring(LCandidate.Length)));
  end;
end;

procedure TTextEditorLanguageServer.ClientInitialize(ASender: TObject; var AValue: TLSPInitializeParams);
var
  LRootPath: string;
begin
  LRootPath := FRootPath;

  if LRootPath.IsEmpty and (FDocuments.Count > 0) then
    LRootPath := ExtractFileDir(FDocuments[0].FileName);

  if not LRootPath.IsEmpty then
  begin
    AValue.AddRoot(LRootPath);
    AValue.AddWorkspaceFolders([LRootPath]);
  end;

  if not FInitializationOptions.IsEmpty then
    AValue.initializationOptions := FInitializationOptions;

  AValue.capabilities.AddSynchronizationSupport(True, False, False, False);
  AValue.capabilities.AddPublishDiagnosticsSupport(True, False, False, False);
  AValue.capabilities.AddCompletionSupport(False, False, False, True, True, False, False, False, False, [], ['detail', 'documentation']);
  AValue.capabilities.AddHoverSupport(False, False, True);
  AValue.capabilities.AddSignatureHelpSupport(False, True, True, False, False);
  AValue.capabilities.AddDefinitionSupport(False);
end;

procedure TTextEditorLanguageServer.ClientInitialized(ASender: TObject; var AValue: TLSPInitializeResult);
var
  LDocument: TTextEditorLanguageServerDocument;
begin
  if FState <> lssStarting then
    Exit;

  Log('Server initialized');

  SetState(lssRunning);

  if not FConfiguration.IsEmpty then
    SendConfiguration(FConfiguration);

  for LDocument in FDocuments do
    SendDidOpen(LDocument);
end;

procedure TTextEditorLanguageServer.SendConfiguration(const ASettingsJson: string);
begin
  if not Initialized then
    Exit;

  FClient.SendNotification(lspDidChangeConfiguration, '', nil, ASettingsJson);
end;

procedure TTextEditorLanguageServer.ClientExit(ASender: TObject; AExitCode: Integer; const ARestartServer: Boolean);
var
  LDocument: TTextEditorLanguageServerDocument;
  LWasStopping: Boolean;
begin
  FExitCode := AExitCode;
  LWasStopping := FState = lssStopping;

  HideHover;
  HideSignatureHelp;

  FChangeTimer.Enabled := False;
  FCompletionTriggerTimer.Enabled := False;
  FResolveTimer.Enabled := False;

  for LDocument in FDocuments do
  begin
    LDocument.Open := False;
    LDocument.ChangePending := False;
    LDocument.Diagnostics := nil;

    ApplyDiagnostics(LDocument);
  end;

  Log('Server exited with code ' + AExitCode.ToString);

  SetState(lssStopped);

  if not LWasStopping and FAutoRestart and (FRestartCount < MAX_RESTART_COUNT) then
  begin
    Inc(FRestartCount);

    Log(Format('Restarting server (%d/%d)', [FRestartCount, MAX_RESTART_COUNT]));

    FRestartTimer.Enabled := True;
  end;
end;

procedure TTextEditorLanguageServer.ClientError(ASender: TObject; const AId, AErrorCode: Integer; const AErrorMessage: string;
  ARetriggerRequest: Boolean);
begin
  Log(Format('Error %d (request %d): %s', [AErrorCode, AId, AErrorMessage]));
end;

procedure TTextEditorLanguageServer.ClientLogMessage(ASender: TObject; const AType: TLSPMessageType; const AMessage: string);
begin
  if not FLogTraffic and (AType = lspMsgLog) and AMessage.TrimLeft.StartsWith('{') then
    Exit;

  Log(AMessage);
end;

function TTextEditorLanguageServer.SyncRequest(const AKind: TLSPKind; const AParams: TLSPBaseParams;
  const AConvert: TFunc<TJSONValue, TObject>): TObject;
var
  LHolder: ITextEditorLanguageServerResultHolder;
begin
  Result := nil;
  LHolder := TTextEditorLanguageServerResultHolder.Create;

  if FClient.SendSyncRequest(AKind, AParams,
    procedure(AJson: TJSONObject)
    var
      LValue: TJSONValue;
    begin
      LValue := AJson.Values['result'];

      if Assigned(LValue) and not LValue.Null then
        LHolder.SetValue(AConvert(LValue));
    end, FSyncRequestTimeout) then
    Result := LHolder.Extract;
end;

{ Diagnostics }

procedure TTextEditorLanguageServer.ClientPublishDiagnostics(ASender: TObject; const AUri: string; const AVersion: Cardinal;
  const ADiagnostics: TArray<TLSPDiagnostic>);
var
  LDocument: TTextEditorLanguageServerDocument;
  LDiagnostics: TArray<TTextEditorLanguageServerDiagnostic>;
  LIndex, LTag: Integer;
begin
  LDocument := DocumentForUri(AUri);

  if not Assigned(LDocument) then
    Exit;

  if (AVersion > 0) and (Integer(AVersion) < LDocument.Version) then
    Exit;

  SetLength(LDiagnostics, Length(ADiagnostics));

  for LIndex := 0 to High(ADiagnostics) do
  begin
    LDiagnostics[LIndex].BeginPosition := PositionToEditor(ADiagnostics[LIndex].range.start);
    LDiagnostics[LIndex].EndPosition := PositionToEditor(ADiagnostics[LIndex].range.&end);
    LDiagnostics[LIndex].Message := DecodeRawJsonString(ADiagnostics[LIndex].&message);
    LDiagnostics[LIndex].Severity := ADiagnostics[LIndex].severity;
    LDiagnostics[LIndex].Source := ADiagnostics[LIndex].source;

    for LTag in ADiagnostics[LIndex].tags do
    case LTag of
      LANGUAGE_SERVER_TAG_UNNECESSARY:
        LDiagnostics[LIndex].Unnecessary := True;
      LANGUAGE_SERVER_TAG_DEPRECATED:
        LDiagnostics[LIndex].Deprecated := True;
    end;
  end;

  LDocument.Diagnostics := LDiagnostics;

  ApplyDiagnostics(LDocument);

  if Assigned(FOnDiagnostics) then
    FOnDiagnostics(Self, LDocument.Editor, LDiagnostics);
end;

procedure TTextEditorLanguageServer.ApplyDiagnostics(const ADocument: TTextEditorLanguageServerDocument);
var
  LEditor: TCustomTextEditor;
  LDiagnostics: TArray<TTextEditorLanguageServerDiagnostic>;
  LIndex, LMarkCount: Integer;
  LMark: TTextEditorMark;
  LLinesMarked: TDictionary<Integer, Boolean>;
begin
  LEditor := ADocument.Editor;

  if csDestroying in LEditor.ComponentState then
    Exit;

  for LIndex := 0 to ADocument.MarkCount - 1 do
  begin
    LMark := LEditor.Marks.Find(FDiagnosticMarkIndex + LIndex);

    if Assigned(LMark) then
      LEditor.DeleteMark(LMark);
  end;

  LMarkCount := 0;
  LDiagnostics := ADocument.Diagnostics;

  if FDiagnosticMarkImageIndex >= 0 then
  begin
    LLinesMarked := TDictionary<Integer, Boolean>.Create;
    try
      for LIndex := 0 to High(LDiagnostics) do
      if not LDiagnostics[LIndex].Unnecessary and not LLinesMarked.ContainsKey(LDiagnostics[LIndex].BeginPosition.Line) then
      begin
        LLinesMarked.Add(LDiagnostics[LIndex].BeginPosition.Line, True);
        LEditor.SetMark(FDiagnosticMarkIndex + LMarkCount, LDiagnostics[LIndex].BeginPosition, FDiagnosticMarkImageIndex);
        Inc(LMarkCount);
      end;
    finally
      LLinesMarked.Free;
    end;
  end;

  ADocument.MarkCount := LMarkCount;

  LEditor.Invalidate;
end;

function TTextEditorLanguageServer.DiagnosticsFor(const AEditor: TCustomTextEditor): TArray<TTextEditorLanguageServerDiagnostic>;
var
  LDocument: TTextEditorLanguageServerDocument;
begin
  LDocument := DocumentForEditor(AEditor);

  Result := if Assigned(LDocument) then LDocument.Diagnostics else nil;
end;

function TTextEditorLanguageServer.DiagnosticAt(const AEditor: TCustomTextEditor; const ATextPosition: TTextEditorTextPosition;
  out ADiagnostic: TTextEditorLanguageServerDiagnostic): Boolean;
var
  LDiagnostic: TTextEditorLanguageServerDiagnostic;
begin
  for LDiagnostic in DiagnosticsFor(AEditor) do
  begin
    if (ATextPosition.Line < LDiagnostic.BeginPosition.Line) or (ATextPosition.Line > LDiagnostic.EndPosition.Line) then
      Continue;

    if (ATextPosition.Line = LDiagnostic.BeginPosition.Line) and (ATextPosition.Char < LDiagnostic.BeginPosition.Char) then
      Continue;

    if (ATextPosition.Line = LDiagnostic.EndPosition.Line) and (ATextPosition.Char >= LDiagnostic.EndPosition.Char) then
      Continue;

    ADiagnostic := LDiagnostic;
    Exit(True);
  end;

  Result := False;
end;

procedure TTextEditorLanguageServer.EditorCustomTokenAttribute(const ASender: TObject; const AText: string; const ALine: Integer;
  const AChar: Integer; var AForegroundColor: TColor; var ABackgroundColor: TColor; var AStyles: TFontStyles;
  var AUnderline: TTextEditorUnderline; var AUnderlineColor: TColor);
var
  LDocument: TTextEditorLanguageServerDocument;
  LDiagnostic: TTextEditorLanguageServerDiagnostic;
  LTokenBeginChar, LTokenEndChar: Integer;
  LSeverity, LDiagnosticSeverity: Integer;
  LDeprecated, LUnnecessary: Boolean;
  LEditor: TCustomTextEditor;
  LForegroundColor: TColor;
begin
  LDocument := DocumentForEditor(TCustomTextEditor(ASender));

  if not Assigned(LDocument) or (Length(LDocument.Diagnostics) = 0) then
    Exit;

  LTokenBeginChar := AChar + 1;
  LTokenEndChar := LTokenBeginChar + Max(0, Length(AText) - 1);
  LSeverity := 0;
  LDeprecated := False;
  LUnnecessary := False;

  for LDiagnostic in LDocument.Diagnostics do
  begin
    if (LDiagnostic.BeginPosition.Line > ALine) or (LDiagnostic.EndPosition.Line < ALine) then
      Continue;

    if (LDiagnostic.BeginPosition.Line = ALine) and (LDiagnostic.BeginPosition.Char > LTokenEndChar) then
      Continue;

    if (LDiagnostic.EndPosition.Line = ALine) and (LDiagnostic.EndPosition.Char <= LTokenBeginChar) then
      Continue;

    if LDiagnostic.Unnecessary then
    begin
      LUnnecessary := True;
      Continue;
    end;

    if LDiagnostic.Deprecated then
      LDeprecated := True;

    LDiagnosticSeverity := if LDiagnostic.Severity = 0 then LANGUAGE_SERVER_SEVERITY_INFORMATION else LDiagnostic.Severity;

    if (LSeverity = 0) or (LDiagnosticSeverity < LSeverity) then
      LSeverity := LDiagnosticSeverity;
  end;

  if LUnnecessary then
  begin
    LEditor := TCustomTextEditor(ASender);
    LForegroundColor := if AForegroundColor = TColors.SysNone then LEditor.Colors.EditorForeground else AForegroundColor;
    AForegroundColor := FadeColor(LForegroundColor, LEditor.Colors.EditorBackground);
  end;

  if LDeprecated then
    AStyles := AStyles + [fsStrikeOut];

  if LSeverity = 0 then
    Exit;

  AUnderline := ulWaveLine;

  case LSeverity of
    LANGUAGE_SERVER_SEVERITY_ERROR:
      AUnderlineColor := FDiagnosticErrorColor;
    LANGUAGE_SERVER_SEVERITY_WARNING:
      AUnderlineColor := FDiagnosticWarningColor;
  else
    AUnderlineColor := FDiagnosticInformationColor;
  end;
end;

{ Completion }

function TTextEditorLanguageServer.CompletionItemKindText(const AKind: Integer; const ADetail: string; const ALanguageId: string): string;

  function IsFunctionDetail: Boolean;
  var
    LRest: string;
    LIndex, LParenthesisCount: Integer;
  begin
    LRest := ADetail.TrimLeft;

    if LRest.StartsWith('(') then
    begin
      LParenthesisCount := 0;

      for LIndex := 1 to LRest.Length do
      begin
        if LRest[LIndex] = '(' then
          Inc(LParenthesisCount)
        else
        if LRest[LIndex] = ')' then
        begin
          Dec(LParenthesisCount);

          if LParenthesisCount = 0 then
          begin
            LRest := LRest.Substring(LIndex);
            Break;
          end;
        end;
      end;
    end;

    Result := LRest.TrimLeft.StartsWith(':');
  end;

var
  LPascal: Boolean;
begin
  LPascal := SameText(ALanguageId, 'pascal');

  case AKind of
    TLSPCompletionItemKind.cMethod, TLSPCompletionItemKind.cFunction:
      if LPascal then
        Result := if IsFunctionDetail then 'function' else 'procedure'
      else
        Result := if AKind = TLSPCompletionItemKind.cMethod then 'method' else 'function';
    TLSPCompletionItemKind.cConstructor:
      Result := 'constructor';
    TLSPCompletionItemKind.cField:
      Result := if LPascal then 'var' else 'field';
    TLSPCompletionItemKind.cVariable:
      Result := if LPascal then 'var' else 'variable';
    TLSPCompletionItemKind.cClass:
      Result := if LPascal then 'type' else 'class';
    TLSPCompletionItemKind.cInterface:
      Result := if LPascal then 'type' else 'interface';
    TLSPCompletionItemKind.cModule:
      Result := if LPascal then 'unit' else 'module';
    TLSPCompletionItemKind.cProperty:
      Result := 'property';
    TLSPCompletionItemKind.cUnit:
      Result := 'unit';
    TLSPCompletionItemKind.cValue:
      Result := if LPascal then 'const' else 'value';
    TLSPCompletionItemKind.cEnum:
      Result := if LPascal then 'type' else 'enum';
    TLSPCompletionItemKind.cKeyword:
      Result := 'keyword';
    TLSPCompletionItemKind.cSnippet:
      Result := 'snippet';
    TLSPCompletionItemKind.cFile:
      Result := 'file';
    TLSPCompletionItemKind.cFolder:
      Result := 'folder';
    TLSPCompletionItemKind.cEnumMember:
      Result := if LPascal then 'const' else 'enum member';
    TLSPCompletionItemKind.cConstant:
      Result := 'const';
    TLSPCompletionItemKind.cStruct:
      Result := if LPascal then 'type' else 'struct';
    TLSPCompletionItemKind.cEvent:
      Result := 'event';
    TLSPCompletionItemKind.cOperator:
      Result := 'operator';
    TLSPCompletionItemKind.cTypeParameter:
      Result := 'type';
  else
    Result := '';
  end;
end;

class function TTextEditorLanguageServer.StripSnippetPlaceholders(const AText: string): string;
var
  LBuilder: TStringBuilder;
  LIndex, LLength, LDepth: Integer;
  LChar: Char;
begin
  LBuilder := TStringBuilder.Create;
  try
    LLength := AText.Length;
    LIndex := 1;
    LDepth := 0;

    while LIndex <= LLength do
    begin
      LChar := AText[LIndex];

      if (LChar = '\') and (LIndex < LLength) then
      begin
        LBuilder.Append(AText[LIndex + 1]);
        Inc(LIndex, 2);
      end
      else
      if (LChar = '$') and (LIndex < LLength) and CharInSet(AText[LIndex + 1], ['0'..'9']) then
      begin
        Inc(LIndex);

        while (LIndex <= LLength) and CharInSet(AText[LIndex], ['0'..'9']) do
          Inc(LIndex);
      end
      else
      if (LChar = '$') and (LIndex < LLength) and (AText[LIndex + 1] = '{') then
      begin
        Inc(LIndex, 2);

        while (LIndex <= LLength) and CharInSet(AText[LIndex], ['0'..'9', 'A'..'Z', 'a'..'z', '_']) do
          Inc(LIndex);

        if (LIndex <= LLength) and (AText[LIndex] = ':') then
        begin
          { A placeholder with a default keeps the default text; its closing brace is consumed below }
          Inc(LIndex);
          Inc(LDepth);
        end
        else
        if (LIndex <= LLength) and (AText[LIndex] = '|') then
        begin
          Inc(LIndex);

          while (LIndex <= LLength) and not CharInSet(AText[LIndex], [',', '|']) do
          begin
            LBuilder.Append(AText[LIndex]);
            Inc(LIndex);
          end;

          while (LIndex <= LLength) and (AText[LIndex] <> '}') do
            Inc(LIndex);

          Inc(LIndex);
        end
        else
        begin
          while (LIndex <= LLength) and (AText[LIndex] <> '}') do
            Inc(LIndex);

          Inc(LIndex);
        end;
      end
      else
      if (LChar = '}') and (LDepth > 0) then
      begin
        Dec(LDepth);
        Inc(LIndex);
      end
      else
      begin
        LBuilder.Append(LChar);
        Inc(LIndex);
      end;
    end;

    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function TTextEditorLanguageServer.CompletionItemInsertText(const AItem: TLSPCompletionItem; const ALineText: string;
  const AWordStartChar: Integer): string;
var
  LRangeStartChar: Integer;
  LPrefix: string;
begin
  Result := AItem.textEdit.newText;

  if not Result.IsEmpty then
  begin
    { The popup replaces the word at the caret, so drop the part of the edit that covers text before that word }
    if AItem.textEdit.insertReplaceEdit then
      LRangeStartChar := AItem.textEdit.insert.start.character + 1
    else
      LRangeStartChar := AItem.textEdit.range.start.character + 1;

    if LRangeStartChar < AWordStartChar then
    begin
      LPrefix := Copy(ALineText, LRangeStartChar, AWordStartChar - LRangeStartChar);

      if not LPrefix.IsEmpty and Result.StartsWith(LPrefix) then
        Result := Result.Substring(LPrefix.Length);
    end;
  end
  else
    Result := AItem.insertText;

  if Result.IsEmpty then
  begin
    Result := AItem.&label.Trim;

    if Result.EndsWith('?') then
      Result := Result.Substring(0, Result.Length - 1);
  end;

  if AItem.insertTextFormat = INSERT_TEXT_FORMAT_SNIPPET then
    Result := StripSnippetPlaceholders(Result);
end;

procedure TTextEditorLanguageServer.FreeCompletionItems;
begin
  FResolveTimer.Enabled := False;

  FCompletionItems := nil;
  FCompletionItemsResolved := nil;
  FCompletionIncomplete := False;
end;

function TTextEditorLanguageServer.Completion(const AEditor: TCustomTextEditor; const AItems: TTextEditorCompletionProposalItems): Boolean;
var
  LDocument: TTextEditorLanguageServerDocument;
  LParams: TLSPCompletionParams;
  LList: TLSPCompletionList;
  LIndexes: TArray<Integer>;
  LIndex, LItemCount, LWordStartChar: Integer;
  LItem: TLSPCompletionItem;
  LProposalItem: TTextEditorCompletionProposalItem;
  LTextPosition: TTextEditorTextPosition;
  LLineText: string;
begin
  Result := False;

  LDocument := OpenDocumentFor(AEditor);

  if not Assigned(LDocument) or not FClient.IsRequestSupported(lspCompletion) then
    Exit;

  FreeCompletionItems;

  FCompletionEditor := AEditor;
  Inc(FCompletionGeneration);

  SendDidChange(LDocument);

  LTextPosition := AEditor.TextPosition;

  LParams := TLSPCompletionParams.Create;
  try
    LParams.textDocument.uri := LDocument.Uri;
    LParams.position := PositionToLSP(LTextPosition);

    LList := TLSPCompletionList(SyncRequest(lspCompletion, LParams,
      function(AValue: TJSONValue): TObject
      begin
        Result := JsonCompletionResultToObject(AValue);
      end));
  finally
    LParams.Free;
  end;

  if not Assigned(LList) then
    Exit;

  try
    SetLength(LIndexes, Length(LList.items));

    for LIndex := 0 to High(LIndexes) do
      LIndexes[LIndex] := LIndex;

    TArray.Sort<Integer>(LIndexes, TComparer<Integer>.Construct(
      function(const ALeft, ARight: Integer): Integer
      var
        LLeftKey, LRightKey: string;
      begin
        LLeftKey := if LList.items[ALeft].sortText.IsEmpty then LList.items[ALeft].&label else LList.items[ALeft].sortText;
        LRightKey := if LList.items[ARight].sortText.IsEmpty then LList.items[ARight].&label else LList.items[ARight].sortText;

        Result := CompareStr(LLeftKey, LRightKey);

        if Result = 0 then
          Result := ALeft - ARight;
      end));

    FCompletionIncomplete := LList.isIncomplete;
    FCompletionItemsOffset := AItems.Count;
    SetLength(FCompletionItems, Length(LList.items));
    SetLength(FCompletionItemsResolved, Length(LList.items));

    LLineText := AEditor.Lines[LTextPosition.Line];
    LWordStartChar := AEditor.WordStart(LTextPosition).Char;
    LItemCount := 0;

    for LIndex in LIndexes do
    begin
      LItem := LList.items[LIndex];

      LProposalItem.Keyword := CompletionItemInsertText(LItem, LLineText, LWordStartChar);
      LProposalItem.Kind := CompletionItemKindText(LItem.kind, LItem.detail, LDocument.LanguageId);
      LProposalItem.Description := TruncateDescription(LItem.detail);
      LProposalItem.SnippetIndex := -1;

      FCompletionItems[LItemCount] := LItem;
      Inc(LItemCount);

      AItems.Add(LProposalItem);
    end;

    Result := LItemCount > 0;
  finally
    LList.Free;
  end;
end;

procedure TTextEditorLanguageServer.EditorCompletionProposalExecute(const ASender: TObject; var AParams: TCompletionProposalParams);
var
  LEditor: TCustomTextEditor;
begin
  LEditor := TCustomTextEditor(ASender);

  if not Assigned(OpenDocumentFor(LEditor)) then
    Exit;

  AParams.Options.ParseItemsFromText := False;
  AParams.Options.AddHighlighterKeywords := False;
  AParams.Options.AddSnippets := False;

  if not Completion(LEditor, AParams.Items) then
    Exit;

  AParams.Options.ShowDescription := True;
  AParams.Options.SortByKeyword := False; { the server's sortText ranking is already applied }

  if FClient.IsRequestSupported(lspCompletionItemResolve) and Assigned(LEditor.CompletionProposalPopupWindow) then
  begin
    LEditor.CompletionProposalPopupWindow.OnSelectedItemChange := CompletionSelectedItemChange;
    CompletionSelectedItemChange(LEditor.CompletionProposalPopupWindow);
  end;
end;

procedure TTextEditorLanguageServer.CompletionSelectedItemChange(ASender: TObject);
begin
  FResolveTimer.Enabled := False;
  FResolveTimer.Enabled := True;
end;

class function TTextEditorLanguageServer.ResolvedItemDescription(const AItem: TLSPCompletionItem): string;
var
  LLine: string;
begin
  Result := AItem.detail;

  if Result.IsEmpty then
  for LLine in AItem.documentationMarkup.value.Replace(#13, '').Split([#10]) do
  if not LLine.Trim.IsEmpty then
  begin
    Result := LLine.Trim;
    Break;
  end;

  Result := TruncateDescription(Result);
end;

procedure TTextEditorLanguageServer.ApplyResolvedDescription(const AEditor: TCustomTextEditor; const AGeneration: Integer;
  const AItemsIndex: Integer; const ADescription: string);
var
  LPopupWindow: TTextEditorCompletionProposalPopupWindow;
  LProposalItem: TTextEditorCompletionProposalItem;
begin
  if (AGeneration <> FCompletionGeneration) or (FCompletionEditor <> AEditor) then
    Exit;

  LPopupWindow := AEditor.CompletionProposalPopupWindow;

  if not Assigned(LPopupWindow) or not LPopupWindow.Visible or (AItemsIndex < 0) or (AItemsIndex >= LPopupWindow.Items.Count) then
    Exit;

  LProposalItem := LPopupWindow.Items[AItemsIndex];
  LProposalItem.Description := ADescription;
  LPopupWindow.Items[AItemsIndex] := LProposalItem;
  LPopupWindow.Invalidate;
end;

procedure TTextEditorLanguageServer.ResolveTimerTimer(ASender: TObject);
var
  LEditor: TCustomTextEditor;
  LPopupWindow: TTextEditorCompletionProposalPopupWindow;
  LItemsIndex, LArrayIndex, LGeneration: Integer;
  LParams: TLSPCompletionItemResolveParams;
  LLifetime: ITextEditorLanguageServerLifetime;
begin
  FResolveTimer.Enabled := False;

  LEditor := FCompletionEditor;

  if not Initialized or not Assigned(LEditor) then
    Exit;

  LPopupWindow := LEditor.CompletionProposalPopupWindow;

  if not Assigned(LPopupWindow) or not LPopupWindow.Visible then
    Exit;

  LItemsIndex := LPopupWindow.SelectedItemIndex;
  LArrayIndex := LItemsIndex - FCompletionItemsOffset;

  if (LItemsIndex < 0) or (LItemsIndex >= LPopupWindow.Items.Count) or (LArrayIndex < 0) or (LArrayIndex >= Length(FCompletionItems)) then
    Exit;

  if FCompletionItemsResolved[LArrayIndex] then
    Exit;

  FCompletionItemsResolved[LArrayIndex] := True;

  if not LPopupWindow.Items[LItemsIndex].Description.IsEmpty then
    Exit;

  LGeneration := FCompletionGeneration;
  LLifetime := FLifetime;

  LParams := TLSPCompletionItemResolveParams.Create;
  try
    LParams.completionItem := FCompletionItems[LArrayIndex];

    FClient.SendRequest(lspCompletionItemResolve, LParams,
      procedure(AJson: TJSONObject)
      var
        LResult: TLSPCompetionItemResolveResult;
        LDescription: string;
      begin
        if not Assigned(AJson.Values['result']) or AJson.Values['result'].Null then
          Exit;

        LResult := JsonCompletionItemResolveResultToObject(AJson.Values['result']);
        try
          LDescription := ResolvedItemDescription(LResult.completionItem);
        finally
          LResult.Free;
        end;

        if LDescription.IsEmpty then
          Exit;

        QueueToMainThread(LLifetime,
          procedure
          begin
            ApplyResolvedDescription(LEditor, LGeneration, LItemsIndex, LDescription);
          end);
      end);
  finally
    LParams.Free;
  end;
end;

procedure TTextEditorLanguageServer.StartCompletionTrigger(const AEditor: TCustomTextEditor; const AInterval: Integer);
begin
  FCompletionTriggerEditor := AEditor;
  FCompletionTriggerTimer.Enabled := False;
  FCompletionTriggerTimer.Interval := Max(1, AInterval);
  FCompletionTriggerTimer.Enabled := True;
end;

procedure TTextEditorLanguageServer.CompletionTriggerTimerTimer(ASender: TObject);
var
  LEditor: TCustomTextEditor;
begin
  FCompletionTriggerTimer.Enabled := False;

  LEditor := FCompletionTriggerEditor;

  if Assigned(LEditor) and Assigned(OpenDocumentFor(LEditor)) then
    LEditor.ShowCompletionProposal(True);
end;

function TTextEditorLanguageServer.IsCompletionTriggerCharacter(const AChar: Char): Boolean;
var
  LProvider: TLSPCompletionOptions;
  LCharacter: string;
begin
  LProvider := if Assigned(FClient.ServerCapabilities) then FClient.ServerCapabilities.completionProvider else nil;

  if not Assigned(LProvider) or (Length(LProvider.triggerCharacters) = 0) then
    Exit(AChar = '.');

  for LCharacter in LProvider.triggerCharacters do
  if LCharacter = AChar then
    Exit(True);

  Result := False;
end;

function TTextEditorLanguageServer.IsSignatureHelpTriggerCharacter(const AChar: Char): Boolean;
var
  LProvider: TLSPSignatureHelpOptions;
  LCharacter: string;
begin
  LProvider := if Assigned(FClient.ServerCapabilities) then FClient.ServerCapabilities.signatureHelpProvider else nil;

  if not Assigned(LProvider) or (Length(LProvider.triggerCharacters) = 0) then
    Exit(CharInSet(AChar, ['(', ',']));

  for LCharacter in LProvider.triggerCharacters do
  if LCharacter = AChar then
    Exit(True);

  for LCharacter in LProvider.retriggerCharacters do
  if FSignatureHelpActive and (LCharacter = AChar) then
    Exit(True);

  Result := False;
end;

{ Keyboard and mouse }

procedure TTextEditorLanguageServer.EditorKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
begin
  HideHover;

  if FSignatureHelpActive and (FSignatureHelpEditor = ASender) then
  case AKey of
    VK_ESCAPE:
      begin
        HideSignatureHelp;
        AKey := 0;
      end;
    VK_BACK, VK_DELETE, VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN, VK_HOME, VK_END, VK_RETURN:
      begin
        FSignatureHelpTimer.Enabled := False;
        FSignatureHelpTimer.Enabled := True;
      end;
  end;
end;

procedure TTextEditorLanguageServer.EditorKeyPress(const ASender: TObject; var AKey: Char);
var
  LEditor: TCustomTextEditor;
  LPopupWindow: TTextEditorCompletionProposalPopupWindow;
begin
  LEditor := TCustomTextEditor(ASender);

  if not Assigned(OpenDocumentFor(LEditor)) then
    Exit;

  if FSignatureHelpEnabled and (IsSignatureHelpTriggerCharacter(AKey) or (FSignatureHelpActive and (AKey = ')'))) then
  begin
    FSignatureHelpEditor := LEditor;
    FSignatureHelpTimer.Enabled := False;
    FSignatureHelpTimer.Enabled := True;
  end;

  FCompletionTriggerTimer.Enabled := False;

  if FSignatureHelpEnabled and FClient.IsRequestSupported(lspSignatureHelp) and IsSignatureHelpTriggerCharacter(AKey) then
    Exit;

  if not FCompletionTriggerEnabled or not LEditor.CompletionProposal.Active or not FClient.IsRequestSupported(lspCompletion) then
    Exit;

  if IsCompletionTriggerCharacter(AKey) then
  begin
    if not LEditor.CompletionProposal.Trigger.Active or (Pos(AKey, LEditor.CompletionProposal.Trigger.Chars) = 0) then
      StartCompletionTrigger(LEditor, LEditor.CompletionProposal.Trigger.Interval);

    Exit;
  end;

  LPopupWindow := LEditor.CompletionProposalPopupWindow;

  { An incomplete list only covers the prefix it was asked for, so ask again once the prefix grows }
  if FCompletionIncomplete and (FCompletionEditor = LEditor) and Assigned(LPopupWindow) and LPopupWindow.Visible and (AKey > ' ') and
    not LEditor.IsWordBreakChar(AKey) then
    StartCompletionTrigger(LEditor, RETRIGGER_DELAY_MS);
end;

procedure TTextEditorLanguageServer.EditorMouseDown(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
begin
  HideHover;
  HideSignatureHelp;
end;

procedure TTextEditorLanguageServer.EditorMouseCursor(const ASender: TObject; const ALineCharPos: TTextEditorTextPosition;
  var ACursor: TCursor);
var
  LEditor: TCustomTextEditor;
  LCursorPoint: TPoint;
  LTextPosition: TTextEditorTextPosition;
  LWord: string;
begin
  LEditor := TCustomTextEditor(ASender);

  if not FHoverEnabled or not Assigned(OpenDocumentFor(LEditor)) then
    Exit;

  LCursorPoint := Mouse.CursorPos;

  if LCursorPoint = FHoverCursorPoint then
    Exit;

  FHoverCursorPoint := LCursorPoint;

  if Assigned(FHoverPopup) and FHoverPopup.Visible and PtInRect(HoverKeepZone, LCursorPoint) then
    Exit;

  if not LEditor.GetTextPositionOfMouse(LTextPosition) then
  begin
    HideHover;
    Exit;
  end;

  LWord := LEditor.WordAtTextPosition(LTextPosition);

  if (LEditor = FHoverEditor) and (LTextPosition.Line = FHoverPosition.Line) and (LWord = FHoverWord) and not LWord.IsEmpty then
    Exit;

  HideHover;

  FHoverEditor := LEditor;
  FHoverPosition := LTextPosition;
  FHoverWord := LWord;
  FHoverTimer.Enabled := not LWord.IsEmpty;
end;

{ Hover }

class function TTextEditorLanguageServer.ParseHoverParts(const AText: string; const ACode: Boolean): TArray<TTextEditorLanguageServerHoverPart>;
var
  LParts: TList<TTextEditorLanguageServerHoverPart>;
  LLines: TArray<string>;
  LLine, LTrimmedLine: string;
  LInCode: Boolean;
  LBracketIndex, LLinkEndIndex: Integer;

  function IsMarkdownRule(const ALine: string): Boolean;
  begin
    Result := False;

    if (ALine.Length < 3) or not CharInSet(ALine[1], ['-', '*', '_']) then
      Exit;

    for var LIndex := 2 to ALine.Length do
    if ALine[LIndex] <> ALine[1] then
      Exit;

    Result := True;
  end;

  function LastPartIsBlank: Boolean;
  begin
    Result := (LParts.Count = 0) or LParts.Last.Text.IsEmpty;
  end;

  procedure AddPart(const ACodePart: Boolean; const AText: string);
  var
    LPart: TTextEditorLanguageServerHoverPart;
  begin
    if (LParts.Count > 0) and not AText.IsEmpty and (LParts.Last.Code = ACodePart) and (LParts.Last.Text = AText) then
      Exit;

    LPart.Code := ACodePart;
    LPart.Text := AText;
    LParts.Add(LPart);
  end;

begin
  LParts := TList<TTextEditorLanguageServerHoverPart>.Create;
  try
    LInCode := ACode;
    LLines := AText.Replace(#13, '').Split([#10]);

    for LLine in LLines do
    begin
      LTrimmedLine := LLine.TrimRight;

      if LTrimmedLine.TrimLeft.StartsWith('```') then
      begin
        LInCode := not LInCode;
        Continue;
      end;

      if LInCode then
      begin
        if LTrimmedLine.IsEmpty and LastPartIsBlank then
          Continue;

        AddPart(True, LTrimmedLine);

        Continue;
      end;

      LBracketIndex := LTrimmedLine.IndexOf('[');

      while LBracketIndex >= 0 do
      begin
        LLinkEndIndex := LTrimmedLine.IndexOf(')', LBracketIndex);

        if (LLinkEndIndex > LBracketIndex) and (LTrimmedLine.IndexOf('](', LBracketIndex) > LBracketIndex) and
          (LTrimmedLine.IndexOf('](', LBracketIndex) < LLinkEndIndex) then
        begin
          var LLabelText := LTrimmedLine.Substring(LBracketIndex + 1, LTrimmedLine.IndexOf('](', LBracketIndex) - LBracketIndex - 1);
          LTrimmedLine := LTrimmedLine.Substring(0, LBracketIndex) + LLabelText + LTrimmedLine.Substring(LLinkEndIndex + 1);
        end
        else
          Break;

        LBracketIndex := LTrimmedLine.IndexOf('[');
      end;

      LTrimmedLine := LTrimmedLine.Replace('**', '').Replace('`', '').Trim;

      while LTrimmedLine.StartsWith('#') do
        LTrimmedLine := LTrimmedLine.Substring(1).TrimLeft;

      if IsMarkdownRule(LTrimmedLine) then
        LTrimmedLine := '';

      if LTrimmedLine.IsEmpty and LastPartIsBlank then
        Continue;

      AddPart(False, LTrimmedLine);
    end;

    while (LParts.Count > 0) and LParts.Last.Text.IsEmpty do
      LParts.Delete(LParts.Count - 1);

    Result := LParts.ToArray;
  finally
    LParts.Free;
  end;
end;

class function TTextEditorLanguageServer.ConvertHover(const AHover: TLSPHoverResult): TArray<TTextEditorLanguageServerHoverPart>;
var
  LMarked: TLSPMarkedString;
begin
  Result := nil;

  if not AHover.contents.value.IsEmpty then
    Result := ParseHoverParts(AHover.contents.value, False)
  else
  if not AHover.contentsMarked.value.IsEmpty then
    Result := ParseHoverParts(AHover.contentsMarked.value, not AHover.contentsMarked.language.IsEmpty)
  else
  for LMarked in AHover.contentsMarkedArray do
    Result := Result + ParseHoverParts(LMarked.value, not LMarked.language.IsEmpty);
end;

function TTextEditorLanguageServer.HoverParts(const AEditor: TCustomTextEditor;
  const ATextPosition: TTextEditorTextPosition): TArray<TTextEditorLanguageServerHoverPart>;
var
  LDocument: TTextEditorLanguageServerDocument;
  LParams: TLSPHoverParams;
  LHover: TLSPHoverResult;
begin
  Result := nil;

  LDocument := OpenDocumentFor(AEditor);

  if not Assigned(LDocument) or not FClient.IsRequestSupported(lspHover) then
    Exit;

  SyncDocument(LDocument);

  LParams := TLSPHoverParams.Create;
  try
    LParams.textDocument.uri := LDocument.Uri;
    LParams.position := PositionToLSP(ATextPosition);

    LHover := TLSPHoverResult(SyncRequest(lspHover, LParams,
      function(AValue: TJSONValue): TObject
      begin
        Result := JsonHoverResultToObject(AValue);
      end));
  finally
    LParams.Free;
  end;

  if not Assigned(LHover) then
    Exit;

  try
    Result := ConvertHover(LHover);
  finally
    LHover.Free;
  end;
end;

function TTextEditorLanguageServer.Hover(const AEditor: TCustomTextEditor; const ATextPosition: TTextEditorTextPosition): string;
var
  LPart: TTextEditorLanguageServerHoverPart;
  LText: string;
begin
  LText := '';

  for LPart in HoverParts(AEditor, ATextPosition) do
    LText := LText + LPart.Text + sLineBreak;

  Result := LText.TrimRight;
end;

function TTextEditorLanguageServer.HoverKeepZone: TRect;
begin
  Result := FHoverKeepRect;

  if Assigned(FHoverPopup) and FHoverPopup.Visible then
    Result := TRect.Union(Result, FHoverPopup.BoundsRect);

  Result.Inflate(2, 2);
end;

procedure TTextEditorLanguageServer.HideHover;
begin
  FHoverTimer.Enabled := False;
  FHoverCloseTimer.Enabled := False;
  FHoverWord := '';
  FHoverEditor := nil;
  FHoverPendingCount := 0;
  Inc(FHoverSerial);

  if Assigned(FHoverPopup) then
    FHoverPopup.Hide;
end;

procedure TTextEditorLanguageServer.EnsureHoverPopup(const AEditor: TCustomTextEditor);
begin
  if Assigned(FHoverPopup) and (FHoverPopup.Owner <> AEditor) then
    FreeHoverPopup;

  if not Assigned(FHoverPopup) then
  begin
    FHoverPopup := TTextEditorHoverPopupWindow.Create(AEditor);
    FHoverPopup.FreeNotification(Self);
    FHoverPopup.OnLinkClick := HoverLinkClick;
  end;
end;

procedure TTextEditorLanguageServer.FreeHoverPopup;
begin
  if not Assigned(FHoverPopup) then
    Exit;

  FHoverPopup.RemoveFreeNotification(Self);
  FreeAndNil(FHoverPopup);
end;

procedure TTextEditorLanguageServer.HoverTimerTimer(ASender: TObject);
begin
  FHoverTimer.Enabled := False;

  RequestHover;
end;

procedure TTextEditorLanguageServer.HoverCloseTimerTimer(ASender: TObject);
begin
  if not Assigned(FHoverPopup) or not FHoverPopup.Visible then
  begin
    FHoverCloseTimer.Enabled := False;
    Exit;
  end;

  if not PtInRect(HoverKeepZone, Mouse.CursorPos) then
    HideHover;
end;

procedure TTextEditorLanguageServer.HoverLinkClick(ASender: TObject);
var
  LEditor: TCustomTextEditor;
  LDocument: TTextEditorLanguageServerDocument;
  LLocation: TTextEditorLanguageServerLocation;
begin
  LEditor := FHoverEditor;

  HideHover;

  if not FHoverLocationValid or not Assigned(LEditor) then
    Exit;

  LLocation := FHoverLocation;
  LDocument := DocumentForEditor(LEditor);

  if Assigned(LDocument) and SameText(LLocation.FileName, LDocument.FileName) then
    LEditor.GoToLineAndSetPosition(LLocation.TextPosition.Line, LLocation.TextPosition.Char);

  if Assigned(FOnGotoLocation) then
    FOnGotoLocation(Self, LEditor, LLocation);
end;

procedure TTextEditorLanguageServer.RequestHover;
var
  LEditor: TCustomTextEditor;
  LDocument: TTextEditorLanguageServerDocument;
  LTextPosition: TTextEditorTextPosition;
  LDiagnostic: TTextEditorLanguageServerDiagnostic;
  LHoverParams: TLSPHoverParams;
  LDefinitionParams: TLSPTextDocumentPositionParams;
  LSerial: Integer;
  LLifetime: ITextEditorLanguageServerLifetime;
begin
  LEditor := FHoverEditor;

  if not Assigned(LEditor) or FHoverWord.IsEmpty then
    Exit;

  LDocument := OpenDocumentFor(LEditor);

  if not Assigned(LDocument) then
    Exit;

  if not LEditor.GetTextPositionOfMouse(LTextPosition) or (LTextPosition.Line <> FHoverPosition.Line) or
    (LEditor.WordAtTextPosition(LTextPosition) <> FHoverWord) then
    Exit;

  FHoverParts := nil;
  FHoverLocationValid := False;
  FHoverPendingCount := 0;

  if DiagnosticAt(LEditor, FHoverPosition, LDiagnostic) then
  begin
    FHoverParts := ParseHoverParts(LDiagnostic.Message, False);
    ShowHoverPopup;
    Exit;
  end;

  SyncDocument(LDocument);

  Inc(FHoverSerial);
  LSerial := FHoverSerial;
  LLifetime := FLifetime;

  if FClient.IsRequestSupported(lspHover) then
  begin
    Inc(FHoverPendingCount);

    LHoverParams := TLSPHoverParams.Create;
    try
      LHoverParams.textDocument.uri := LDocument.Uri;
      LHoverParams.position := PositionToLSP(FHoverPosition);

      FClient.SendRequest(lspHover, LHoverParams,
        procedure(AJson: TJSONObject)
        var
          LHover: TLSPHoverResult;
          LParts: TArray<TTextEditorLanguageServerHoverPart>;
        begin
          LParts := nil;

          if Assigned(AJson.Values['result']) and not AJson.Values['result'].Null then
          begin
            LHover := JsonHoverResultToObject(AJson.Values['result']);
            try
              LParts := ConvertHover(LHover);
            finally
              LHover.Free;
            end;
          end;

          QueueToMainThread(LLifetime,
            procedure
            begin
              if LSerial <> FHoverSerial then
                Exit;

              FHoverParts := LParts;
              HoverRequestCompleted;
            end);
        end);
    finally
      LHoverParams.Free;
    end;
  end;

  if FClient.IsRequestSupported(lspGotoDefinition) then
  begin
    Inc(FHoverPendingCount);

    LDefinitionParams := TLSPTextDocumentPositionParams.Create;
    try
      LDefinitionParams.textDocument.uri := LDocument.Uri;
      LDefinitionParams.position := PositionToLSP(FHoverPosition);

      FClient.SendRequest(lspGotoDefinition, LDefinitionParams,
        procedure(AJson: TJSONObject)
        var
          LResult: TLSPGotoResult;
          LLocation: TTextEditorLanguageServerLocation;
          LFound: Boolean;
        begin
          LFound := False;
          LLocation := Default(TTextEditorLanguageServerLocation);

          if Assigned(AJson.Values['result']) and not AJson.Values['result'].Null then
          begin
            LResult := JsonGotoResultToObject(AJson.Values['result']);
            try
              LFound := ExtractGotoLocation(LResult, LLocation);
            finally
              LResult.Free;
            end;
          end;

          QueueToMainThread(LLifetime,
            procedure
            begin
              if LSerial <> FHoverSerial then
                Exit;

              FHoverLocation := LLocation;
              FHoverLocationValid := LFound;
              HoverRequestCompleted;
            end);
        end);
    finally
      LDefinitionParams.Free;
    end;
  end;
end;

procedure TTextEditorLanguageServer.HoverRequestCompleted;
begin
  Dec(FHoverPendingCount);

  if FHoverPendingCount <= 0 then
    ShowHoverPopup;
end;

procedure TTextEditorLanguageServer.ShowHoverPopup;
var
  LEditor: TCustomTextEditor;
  LPart: TTextEditorLanguageServerHoverPart;
  LTextPosition: TTextEditorTextPosition;
  LAnchorRect: TRect;
  LTopLeft, LBottomRight: TPoint;
begin
  LEditor := FHoverEditor;

  if not Assigned(LEditor) or FHoverWord.IsEmpty then
    Exit;

  if (Length(FHoverParts) = 0) and not FHoverLocationValid then
    Exit;

  if not LEditor.GetTextPositionOfMouse(LTextPosition) or (LTextPosition.Line <> FHoverPosition.Line) or
    (LEditor.WordAtTextPosition(LTextPosition) <> FHoverWord) then
    Exit;

  EnsureHoverPopup(LEditor);

  FHoverPopup.Clear;

  for LPart in FHoverParts do
  if LPart.Code then
    FHoverPopup.AddLine(hlCode, LPart.Text)
  else
    FHoverPopup.AddLine(hlText, LPart.Text);

  if FHoverLocationValid then
    FHoverPopup.LinkText := Format('%s (%d)', [ExtractFileName(FHoverLocation.FileName), FHoverLocation.TextPosition.Line + 1]);

  LTopLeft := LEditor.ViewPositionToPixels(LEditor.TextToViewPosition(LEditor.WordStart(FHoverPosition)));
  LBottomRight := LEditor.ViewPositionToPixels(LEditor.TextToViewPosition(LEditor.WordEnd(FHoverPosition)));

  LAnchorRect.TopLeft := LEditor.ClientToScreen(LTopLeft);
  LAnchorRect.BottomRight := LEditor.ClientToScreen(Point(LBottomRight.X, LBottomRight.Y + LEditor.LineHeight));

  FHoverKeepRect := LAnchorRect;

  FHoverPopup.Execute(LAnchorRect);
  FHoverCloseTimer.Enabled := FHoverPopup.Visible;
end;

{ Definition }

class function TTextEditorLanguageServer.ExtractGotoLocation(const AGotoResult: TLSPGotoResult; out ALocation: TTextEditorLanguageServerLocation): Boolean;
var
  LUri: string;
  LRange: TLSPRange;
begin
  if Length(AGotoResult.locations) > 0 then
  begin
    LUri := AGotoResult.locations[0].uri;
    LRange := AGotoResult.locations[0].range;
  end
  else
  if Length(AGotoResult.locationLinks) > 0 then
  begin
    LUri := AGotoResult.locationLinks[0].targetUri;
    LRange := AGotoResult.locationLinks[0].targetSelectionRange;
  end
  else
  begin
    LUri := AGotoResult.location.uri;
    LRange := AGotoResult.location.range;
  end;

  if LUri.IsEmpty then
    Exit(False);

  ALocation.FileName := UriToFilePath(LUri);
  ALocation.TextPosition := PositionToEditor(LRange.start);

  Result := True;
end;

function TTextEditorLanguageServer.FindDefinition(const AEditor: TCustomTextEditor; const ATextPosition: TTextEditorTextPosition;
  out ALocation: TTextEditorLanguageServerLocation): Boolean;
var
  LDocument: TTextEditorLanguageServerDocument;
  LParams: TLSPTextDocumentPositionParams;
  LGotoResult: TLSPGotoResult;
begin
  Result := False;
  ALocation := Default(TTextEditorLanguageServerLocation);

  LDocument := OpenDocumentFor(AEditor);

  if not Assigned(LDocument) or not FClient.IsRequestSupported(lspGotoDefinition) then
    Exit;

  SyncDocument(LDocument);

  LParams := TLSPTextDocumentPositionParams.Create;
  try
    LParams.textDocument.uri := LDocument.Uri;
    LParams.position := PositionToLSP(ATextPosition);

    LGotoResult := TLSPGotoResult(SyncRequest(lspGotoDefinition, LParams,
      function(AValue: TJSONValue): TObject
      begin
        Result := JsonGotoResultToObject(AValue);
      end));
  finally
    LParams.Free;
  end;

  if not Assigned(LGotoResult) then
    Exit;

  try
    Result := ExtractGotoLocation(LGotoResult, ALocation);
  finally
    LGotoResult.Free;
  end;
end;

procedure TTextEditorLanguageServer.GotoDefinition(const AEditor: TCustomTextEditor);
var
  LDocument: TTextEditorLanguageServerDocument;
  LParams: TLSPTextDocumentPositionParams;
  LLifetime: ITextEditorLanguageServerLifetime;
begin
  LDocument := OpenDocumentFor(AEditor);

  if not Assigned(LDocument) or not FClient.IsRequestSupported(lspGotoDefinition) then
    Exit;

  SyncDocument(LDocument);

  LLifetime := FLifetime;

  LParams := TLSPTextDocumentPositionParams.Create;
  try
    LParams.textDocument.uri := LDocument.Uri;
    LParams.position := PositionToLSP(AEditor.TextPosition);

    FClient.SendRequest(lspGotoDefinition, LParams,
      procedure(AJson: TJSONObject)
      var
        LResult: TLSPGotoResult;
        LLocation: TTextEditorLanguageServerLocation;
        LFound: Boolean;
      begin
        if not Assigned(AJson.Values['result']) or AJson.Values['result'].Null then
          Exit;

        LResult := JsonGotoResultToObject(AJson.Values['result']);
        try
          LFound := ExtractGotoLocation(LResult, LLocation);
        finally
          LResult.Free;
        end;

        if not LFound then
          Exit;

        QueueToMainThread(LLifetime,
          procedure
          var
            LTargetDocument: TTextEditorLanguageServerDocument;
          begin
            LTargetDocument := DocumentForEditor(AEditor);

            if not Assigned(LTargetDocument) then
              Exit;

            if SameText(LLocation.FileName, LTargetDocument.FileName) then
              AEditor.GoToLineAndSetPosition(LLocation.TextPosition.Line, LLocation.TextPosition.Char);

            if Assigned(FOnGotoLocation) then
              FOnGotoLocation(Self, AEditor, LLocation);
          end);
      end);
  finally
    LParams.Free;
  end;
end;

{ Signature help }

class function TTextEditorLanguageServer.ConvertSignatureHelp(const AResult: TLSPSignatureHelpResult; out AHelp: TTextEditorLanguageServerSignatureHelp): Boolean;
var
  LIndex, LParameterIndex: Integer;
begin
  AHelp := Default(TTextEditorLanguageServerSignatureHelp);

  SetLength(AHelp.Signatures, Length(AResult.signatures));

  for LIndex := 0 to High(AResult.signatures) do
  begin
    AHelp.Signatures[LIndex].Text := AResult.signatures[LIndex].&label;

    SetLength(AHelp.Signatures[LIndex].Parameters, Length(AResult.signatures[LIndex].parameters));

    for LParameterIndex := 0 to High(AResult.signatures[LIndex].parameters) do
      AHelp.Signatures[LIndex].Parameters[LParameterIndex] := AResult.signatures[LIndex].parameters[LParameterIndex].&label;
  end;

  if Length(AHelp.Signatures) > 0 then
    AHelp.ActiveSignature := EnsureRange(Integer(AResult.activeSignature), 0, High(AHelp.Signatures));

  AHelp.ActiveParameter := Integer(AResult.activeParameter);

  Result := Length(AHelp.Signatures) > 0;
end;

function TTextEditorLanguageServer.SignatureHelp(const AEditor: TCustomTextEditor; const ATextPosition: TTextEditorTextPosition;
  out AHelp: TTextEditorLanguageServerSignatureHelp): Boolean;
var
  LDocument: TTextEditorLanguageServerDocument;
  LParams: TLSPSignatureHelpParams;
  LHelpResult: TLSPSignatureHelpResult;
begin
  Result := False;
  AHelp := Default(TTextEditorLanguageServerSignatureHelp);

  LDocument := OpenDocumentFor(AEditor);

  if not Assigned(LDocument) or not FClient.IsRequestSupported(lspSignatureHelp) then
    Exit;

  SyncDocument(LDocument);

  LParams := TLSPSignatureHelpParams.Create;
  try
    LParams.textDocument.uri := LDocument.Uri;
    LParams.position := PositionToLSP(ATextPosition);
    LParams.context.triggerKind := 1;
    LParams.context.isRetrigger := FSignatureHelpActive;

    LHelpResult := TLSPSignatureHelpResult(SyncRequest(lspSignatureHelp, LParams,
      function(AValue: TJSONValue): TObject
      begin
        Result := JsonSignatureHelpResultToObject(AValue);
      end));
  finally
    LParams.Free;
  end;

  if not Assigned(LHelpResult) then
    Exit;

  try
    Result := ConvertSignatureHelp(LHelpResult, AHelp);
  finally
    LHelpResult.Free;
  end;
end;

procedure TTextEditorLanguageServer.HideSignatureHelp;
begin
  FSignatureHelpTimer.Enabled := False;
  FSignatureHelpActive := False;
  FSignatureHelpEditor := nil;
  Inc(FSignatureHelpSerial);

  if Assigned(FSignatureHelpPopup) then
    FSignatureHelpPopup.Hide;
end;

procedure TTextEditorLanguageServer.EnsureSignatureHelpPopup(const AEditor: TCustomTextEditor);
begin
  if Assigned(FSignatureHelpPopup) and (FSignatureHelpPopup.Owner <> AEditor) then
    FreeSignatureHelpPopup;

  if not Assigned(FSignatureHelpPopup) then
  begin
    FSignatureHelpPopup := TTextEditorHoverPopupWindow.Create(AEditor);
    FSignatureHelpPopup.FreeNotification(Self);
  end;
end;

procedure TTextEditorLanguageServer.FreeSignatureHelpPopup;
begin
  if not Assigned(FSignatureHelpPopup) then
    Exit;

  FSignatureHelpPopup.RemoveFreeNotification(Self);
  FreeAndNil(FSignatureHelpPopup);
end;

procedure TTextEditorLanguageServer.SignatureHelpTimerTimer(ASender: TObject);
begin
  FSignatureHelpTimer.Enabled := False;

  if Assigned(FSignatureHelpEditor) then
    UpdateSignatureHelp(FSignatureHelpEditor);
end;

procedure TTextEditorLanguageServer.UpdateSignatureHelp(const AEditor: TCustomTextEditor);
var
  LDocument: TTextEditorLanguageServerDocument;
  LParams: TLSPSignatureHelpParams;
  LSerial: Integer;
  LLifetime: ITextEditorLanguageServerLifetime;
begin
  LDocument := OpenDocumentFor(AEditor);

  if not FSignatureHelpEnabled or not Assigned(LDocument) or not FClient.IsRequestSupported(lspSignatureHelp) then
  begin
    HideSignatureHelp;
    Exit;
  end;

  SyncDocument(LDocument);

  Inc(FSignatureHelpSerial);
  LSerial := FSignatureHelpSerial;
  LLifetime := FLifetime;

  LParams := TLSPSignatureHelpParams.Create;
  try
    LParams.textDocument.uri := LDocument.Uri;
    LParams.position := PositionToLSP(AEditor.TextPosition);
    LParams.context.triggerKind := 1;
    LParams.context.isRetrigger := FSignatureHelpActive;

    FClient.SendRequest(lspSignatureHelp, LParams,
      procedure(AJson: TJSONObject)
      var
        LResult: TLSPSignatureHelpResult;
        LHelp: TTextEditorLanguageServerSignatureHelp;
        LFound: Boolean;
      begin
        LFound := False;
        LHelp := Default(TTextEditorLanguageServerSignatureHelp);

        if Assigned(AJson.Values['result']) and not AJson.Values['result'].Null then
        begin
          LResult := JsonSignatureHelpResultToObject(AJson.Values['result']);
          try
            LFound := ConvertSignatureHelp(LResult, LHelp);
          finally
            LResult.Free;
          end;
        end;

        QueueToMainThread(LLifetime,
          procedure
          begin
            if LSerial <> FSignatureHelpSerial then
              Exit;

            if LFound then
              ShowSignatureHelpPopup(AEditor, LHelp)
            else
              HideSignatureHelp;
          end);
      end);
  finally
    LParams.Free;
  end;
end;

procedure TTextEditorLanguageServer.ShowSignatureHelpPopup(const AEditor: TCustomTextEditor; const AHelp: TTextEditorLanguageServerSignatureHelp);
var
  LSignature: TTextEditorLanguageServerSignature;
  LIndex, LSearchIndex, LFoundIndex: Integer;
  LHighlightBegin, LHighlightLength: Integer;
  LPoint: TPoint;
  LAnchorRect: TRect;
begin
  if FSignatureHelpEditor <> AEditor then
    Exit;

  EnsureSignatureHelpPopup(AEditor);

  FSignatureHelpPopup.Clear;

  for LSignature in AHelp.Signatures do
  begin
    LHighlightBegin := 0;
    LHighlightLength := 0;

    if (AHelp.ActiveParameter >= 0) and (AHelp.ActiveParameter < Length(LSignature.Parameters)) then
    begin
      LSearchIndex := 0;

      for LIndex := 0 to AHelp.ActiveParameter do
      begin
        LFoundIndex := LSignature.Text.IndexOf(LSignature.Parameters[LIndex], LSearchIndex);

        if LFoundIndex < 0 then
          Break;

        if LIndex = AHelp.ActiveParameter then
        begin
          LHighlightBegin := LFoundIndex + 1;
          LHighlightLength := LSignature.Parameters[LIndex].Length;
        end
        else
          LSearchIndex := LFoundIndex + LSignature.Parameters[LIndex].Length;
      end;
    end;

    FSignatureHelpPopup.AddLine(hlCode, LSignature.Text, LHighlightBegin, LHighlightLength);
  end;

  LPoint := AEditor.ClientToScreen(AEditor.ViewPositionToPixels(AEditor.ViewPosition));

  LAnchorRect.TopLeft := LPoint;
  LAnchorRect.BottomRight := Point(LPoint.X, LPoint.Y + AEditor.LineHeight);

  FSignatureHelpPopup.Execute(LAnchorRect, True);
  FSignatureHelpActive := FSignatureHelpPopup.Visible;
end;

end.
