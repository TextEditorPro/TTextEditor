unit TextEditor.LanguageServer.Manager;

{ Maps editors to language servers. One server process is shared by every attached editor whose file matches the same
  definition and resolves to the same root folder; it is stopped once it has had no documents for IdleTimeout milliseconds. }

interface

uses
  System.Classes, System.Diagnostics, System.Generics.Collections, System.SysUtils, Vcl.ExtCtrls, TextEditor, TextEditor.LanguageServer;

type
  TTextEditorLanguageServerRootPathKind = (rpDocumentFolder, rpFixedFolder, rpMarkerFile);
  TTextEditorLanguageServerSettingsFallback = (sfNone, sfDelphiLsp);

  TTextEditorLanguageServerDefinition = class(TCollectionItem)
  strict private
    FCommandLine: string;
    FConfiguration: string;
    FEnabled: Boolean;
    FExtensions: string;
    FInitializationOptions: string;
    FLanguageId: string;
    FName: string;
    FRootPath: string;
    FRootPathKind: TTextEditorLanguageServerRootPathKind;
    FSettingsFallback: TTextEditorLanguageServerSettingsFallback;
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(ACollection: TCollection); override;
    function MatchesFileName(const AFileName: string): Boolean;
    procedure Assign(ASource: TPersistent); override;
  published
    property CommandLine: string read FCommandLine write FCommandLine;
    property Configuration: string read FConfiguration write FConfiguration;
    property Enabled: Boolean read FEnabled write FEnabled default True;
    property Extensions: string read FExtensions write FExtensions;
    property InitializationOptions: string read FInitializationOptions write FInitializationOptions;
    property LanguageId: string read FLanguageId write FLanguageId;
    property Name: string read FName write FName;
    property RootPath: string read FRootPath write FRootPath;
    property RootPathKind: TTextEditorLanguageServerRootPathKind read FRootPathKind write FRootPathKind default rpDocumentFolder;
    property SettingsFallback: TTextEditorLanguageServerSettingsFallback read FSettingsFallback write FSettingsFallback default sfNone;
  end;

  TTextEditorLanguageServerDefinitions = class(TOwnedCollection)
  strict private
    function GetItem(const AIndex: Integer): TTextEditorLanguageServerDefinition;
    procedure SetItem(const AIndex: Integer; const AValue: TTextEditorLanguageServerDefinition);
  public
    function Add: TTextEditorLanguageServerDefinition;
    function FindByName(const AName: string): TTextEditorLanguageServerDefinition;
    property Items[const AIndex: Integer]: TTextEditorLanguageServerDefinition read GetItem write SetItem; default;
  end;

  TTextEditorLanguageServers = class(TComponent)
  strict private type
    TServerInstance = class(TObject)
    strict private
      FConfiguration: string;
      FDefinitionId: Integer;
      FDefinitionName: string;
      FIdleStopwatch: TStopwatch;
      FRetired: Boolean;
      FRootPath: string;
      FServer: TTextEditorLanguageServer;
    public
      destructor Destroy; override;
      function IdleMilliseconds: Int64;
      procedure MarkBusy;
      procedure MarkIdle;
      property Configuration: string read FConfiguration write FConfiguration;
      property DefinitionId: Integer read FDefinitionId write FDefinitionId;
      property DefinitionName: string read FDefinitionName write FDefinitionName;
      property Retired: Boolean read FRetired write FRetired;
      property RootPath: string read FRootPath write FRootPath;
      property Server: TTextEditorLanguageServer read FServer write FServer;
    end;
  strict private
    FAutoRestart: Boolean;
    FCleanupTimer: TTimer;
    FCompletionTriggerEnabled: Boolean;
    FEditors: TDictionary<TCustomTextEditor, TServerInstance>;
    FHoverDelay: Integer;
    FHoverEnabled: Boolean;
    FIdleTimeout: Integer;
    FInstances: TObjectList<TServerInstance>;
    FLogTraffic: Boolean;
    FOnDiagnostics: TTextEditorLanguageServerDiagnosticsEvent;
    FOnGotoLocation: TTextEditorLanguageServerLocationEvent;
    FOnLog: TTextEditorLanguageServerLogEvent;
    FOnStateChange: TTextEditorLanguageServerStateEvent;
    FServers: TTextEditorLanguageServerDefinitions;
    FSignatureHelpEnabled: Boolean;
    FSyncRequestTimeout: Integer;
    function BuildConfiguration(const ADefinition: TTextEditorLanguageServerDefinition; const AMarkerFileName: string): string;
    function CreateDelphiLspFallbackSettings(const ADefinition: TTextEditorLanguageServerDefinition; const AFileName: string): string;
    function CreateInstance(const ADefinition: TTextEditorLanguageServerDefinition; const ARootPath: string; const AConfiguration: string): TServerInstance;
    function FindInstance(const ADefinitionId: Integer; const ARootPath: string): TServerInstance;
    function InstanceForServer(const AServer: TObject): TServerInstance;
    function ResolveConfiguration(const ADefinition: TTextEditorLanguageServerDefinition; const AFileName: string; out ARootPath: string): string;
    function ResolveRootPath(const ADefinition: TTextEditorLanguageServerDefinition; const AFileName: string; out AMarkerFileName: string): string;
    procedure CleanupTimerTimer(ASender: TObject);
    procedure InstanceDiagnostics(const ASender: TObject; const AEditor: TCustomTextEditor; const ADiagnostics: TArray<TTextEditorLanguageServerDiagnostic>);
    procedure InstanceGotoLocation(const ASender: TObject; const AEditor: TCustomTextEditor; const ALocation: TTextEditorLanguageServerLocation);
    procedure InstanceLog(const ASender: TObject; const AMessage: string);
    procedure InstanceStateChange(const ASender: TObject; const AState: TTextEditorLanguageServerState);
    procedure Retire(const AInstance: TServerInstance);
    procedure SetServers(const AValue: TTextEditorLanguageServerDefinitions);
  protected
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Attach(const AEditor: TCustomTextEditor; const AFileName: string): TTextEditorLanguageServer;
    function DefinitionForFileName(const AFileName: string): TTextEditorLanguageServerDefinition;
    function InstanceForEditor(const AEditor: TCustomTextEditor): TTextEditorLanguageServer;
    procedure Detach(const AEditor: TCustomTextEditor);
    procedure DetectInstalledServers;
    procedure DocumentSaved(const AEditor: TCustomTextEditor);
    procedure StopAll;
  published
    property AutoRestart: Boolean read FAutoRestart write FAutoRestart default False;
    property CompletionTriggerEnabled: Boolean read FCompletionTriggerEnabled write FCompletionTriggerEnabled default True;
    property HoverDelay: Integer read FHoverDelay write FHoverDelay default 600;
    property HoverEnabled: Boolean read FHoverEnabled write FHoverEnabled default True;
    { Milliseconds a server is kept alive without documents; 0 stops it at once, a negative value keeps it running }
    property IdleTimeout: Integer read FIdleTimeout write FIdleTimeout default 60000;
    property LogTraffic: Boolean read FLogTraffic write FLogTraffic default False;
    property OnDiagnostics: TTextEditorLanguageServerDiagnosticsEvent read FOnDiagnostics write FOnDiagnostics;
    property OnGotoLocation: TTextEditorLanguageServerLocationEvent read FOnGotoLocation write FOnGotoLocation;
    property OnLog: TTextEditorLanguageServerLogEvent read FOnLog write FOnLog;
    property OnStateChange: TTextEditorLanguageServerStateEvent read FOnStateChange write FOnStateChange;
    property Servers: TTextEditorLanguageServerDefinitions read FServers write SetServers;
    property SignatureHelpEnabled: Boolean read FSignatureHelpEnabled write FSignatureHelpEnabled default True;
    property SyncRequestTimeout: Integer read FSyncRequestTimeout write FSyncRequestTimeout default 1000;
  end;

implementation

uses
  System.Hash, System.IOUtils;

const
  CLEANUP_INTERVAL_MS = 1000;

{ TTextEditorLanguageServerDefinition }

constructor TTextEditorLanguageServerDefinition.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);

  FEnabled := True;
  FRootPathKind := rpDocumentFolder;
end;

function TTextEditorLanguageServerDefinition.GetDisplayName: string;
begin
  Result := if FName.IsEmpty then inherited GetDisplayName else FName;
end;

function TTextEditorLanguageServerDefinition.MatchesFileName(const AFileName: string): Boolean;
var
  LExtension, LCandidate: string;
begin
  LExtension := ExtractFileExt(AFileName).ToLower;

  if LExtension.IsEmpty then
    Exit(False);

  for LCandidate in FExtensions.ToLower.Split([';']) do
  if LCandidate.Trim = LExtension then
    Exit(True);

  Result := False;
end;

procedure TTextEditorLanguageServerDefinition.Assign(ASource: TPersistent);
begin
  if ASource is TTextEditorLanguageServerDefinition then
  with ASource as TTextEditorLanguageServerDefinition do
  begin
    Self.FCommandLine := CommandLine;
    Self.FConfiguration := Configuration;
    Self.FEnabled := Enabled;
    Self.FExtensions := Extensions;
    Self.FInitializationOptions := InitializationOptions;
    Self.FLanguageId := LanguageId;
    Self.FName := Name;
    Self.FRootPath := RootPath;
    Self.FRootPathKind := RootPathKind;
    Self.FSettingsFallback := SettingsFallback;
  end
  else
    inherited Assign(ASource);
end;

{ TTextEditorLanguageServerDefinitions }

function TTextEditorLanguageServerDefinitions.GetItem(const AIndex: Integer): TTextEditorLanguageServerDefinition;
begin
  Result := inherited GetItem(AIndex) as TTextEditorLanguageServerDefinition;
end;

procedure TTextEditorLanguageServerDefinitions.SetItem(const AIndex: Integer; const AValue: TTextEditorLanguageServerDefinition);
begin
  inherited SetItem(AIndex, AValue);
end;

function TTextEditorLanguageServerDefinitions.Add: TTextEditorLanguageServerDefinition;
begin
  Result := inherited Add as TTextEditorLanguageServerDefinition;
end;

function TTextEditorLanguageServerDefinitions.FindByName(const AName: string): TTextEditorLanguageServerDefinition;
begin
  for var LIndex := 0 to Count - 1 do
  if SameText(Items[LIndex].Name, AName) then
    Exit(Items[LIndex]);

  Result := nil;
end;

{ TTextEditorLanguageServers.TServerInstance }

destructor TTextEditorLanguageServers.TServerInstance.Destroy;
begin
  FServer.Free;

  inherited Destroy;
end;

function TTextEditorLanguageServers.TServerInstance.IdleMilliseconds: Int64;
begin
  Result := if FIdleStopwatch.IsRunning then FIdleStopwatch.ElapsedMilliseconds else -1;
end;

procedure TTextEditorLanguageServers.TServerInstance.MarkBusy;
begin
  FIdleStopwatch.Reset;
end;

procedure TTextEditorLanguageServers.TServerInstance.MarkIdle;
begin
  FIdleStopwatch := TStopwatch.StartNew;
end;

{ TTextEditorLanguageServers }

constructor TTextEditorLanguageServers.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FServers := TTextEditorLanguageServerDefinitions.Create(Self, TTextEditorLanguageServerDefinition);
  FEditors := TDictionary<TCustomTextEditor, TServerInstance>.Create;
  FInstances := TObjectList<TServerInstance>.Create(True);

  FCleanupTimer := TTimer.Create(Self);
  FCleanupTimer.Enabled := False;
  FCleanupTimer.Interval := CLEANUP_INTERVAL_MS;
  FCleanupTimer.OnTimer := CleanupTimerTimer;

  FCompletionTriggerEnabled := True;
  FHoverDelay := 600;
  FHoverEnabled := True;
  FIdleTimeout := 60000;
  FSignatureHelpEnabled := True;
  FSyncRequestTimeout := 1000;
end;

destructor TTextEditorLanguageServers.Destroy;
begin
  StopAll;

  FInstances.Free;
  FEditors.Free;
  FServers.Free;

  inherited Destroy;
end;

procedure TTextEditorLanguageServers.SetServers(const AValue: TTextEditorLanguageServerDefinitions);
begin
  FServers.Assign(AValue);
end;

procedure TTextEditorLanguageServers.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited Notification(AComponent, AOperation);

  if (AOperation = opRemove) and (AComponent is TCustomTextEditor) then
    Detach(TCustomTextEditor(AComponent));
end;

function TTextEditorLanguageServers.DefinitionForFileName(const AFileName: string): TTextEditorLanguageServerDefinition;
begin
  for var LIndex := 0 to FServers.Count - 1 do
  if FServers[LIndex].Enabled and FServers[LIndex].MatchesFileName(AFileName) then
    Exit(FServers[LIndex]);

  Result := nil;
end;

function TTextEditorLanguageServers.InstanceForEditor(const AEditor: TCustomTextEditor): TTextEditorLanguageServer;
var
  LInstance: TServerInstance;
begin
  Result := if FEditors.TryGetValue(AEditor, LInstance) then LInstance.Server else nil;
end;

function TTextEditorLanguageServers.InstanceForServer(const AServer: TObject): TServerInstance;
var
  LInstance: TServerInstance;
begin
  for LInstance in FInstances do
  if LInstance.Server = AServer then
    Exit(LInstance);

  Result := nil;
end;

function TTextEditorLanguageServers.FindInstance(const ADefinitionId: Integer; const ARootPath: string): TServerInstance;
var
  LInstance: TServerInstance;
begin
  for LInstance in FInstances do
  if not LInstance.Retired and (LInstance.DefinitionId = ADefinitionId) and SameText(LInstance.RootPath, ARootPath) then
    Exit(LInstance);

  Result := nil;
end;

function TTextEditorLanguageServers.ResolveRootPath(const ADefinition: TTextEditorLanguageServerDefinition;
  const AFileName: string; out AMarkerFileName: string): string;
var
  LDirectory, LParentDirectory, LPattern: string;
  LPatterns, LFiles: TArray<string>;
begin
  AMarkerFileName := '';
  Result := ExtractFileDir(AFileName);

  case ADefinition.RootPathKind of
    rpFixedFolder:
      if not ADefinition.RootPath.IsEmpty then
        Result := ADefinition.RootPath;
    rpMarkerFile:
      begin
        LPatterns := ADefinition.RootPath.Split([';']);
        LDirectory := ExtractFileDir(AFileName);

        while not LDirectory.IsEmpty do
        begin
          for LPattern in LPatterns do
          begin
            if LPattern.Trim.IsEmpty then
              Continue;

            LFiles := TDirectory.GetFiles(LDirectory, LPattern.Trim);

            if Length(LFiles) > 0 then
            begin
              AMarkerFileName := LFiles[0];
              Exit(LDirectory);
            end;
          end;

          LParentDirectory := ExtractFileDir(LDirectory);

          if LParentDirectory = LDirectory then
            Break;

          LDirectory := LParentDirectory;
        end;
      end;
  end;
end;

function TTextEditorLanguageServers.BuildConfiguration(const ADefinition: TTextEditorLanguageServerDefinition;
  const AMarkerFileName: string): string;
begin
  Result := ADefinition.Configuration;

  if Result.Contains('%MARKERFILEURI%') then
  begin
    if AMarkerFileName.IsEmpty then
      Exit('');

    Result := Result.Replace('%MARKERFILEURI%', TTextEditorLanguageServer.FileNameToUri(AMarkerFileName));
  end;
end;

function TTextEditorLanguageServers.CreateDelphiLspFallbackSettings(const ADefinition: TTextEditorLanguageServerDefinition;
  const AFileName: string): string;

  function EscapedPath(const APath: string): string;
  begin
    Result := APath.Replace('\', '\\');
  end;

  function ServerFileName: string;
  var
    LCommandLine: string;
    LIndex: Integer;
  begin
    LCommandLine := ADefinition.CommandLine.Trim;

    if LCommandLine.StartsWith('"') then
    begin
      LIndex := LCommandLine.IndexOf('"', 1);
      Result := if LIndex > 1 then LCommandLine.Substring(1, LIndex - 1) else ''
    end
    else
      Result := LCommandLine.Split([' '])[0];
  end;

var
  LBinDirectory, LLibDirectory, LDirectory, LDocumentDirectory: string;
  LCompilerFileNames: TArray<string>;
  LProjectFileName, LSettingsFileName: string;
begin
  Result := '';

  LBinDirectory := ExtractFileDir(ServerFileName);
  LLibDirectory := ExtractFileDir(LBinDirectory) + '\lib\Win32\release';

  if not TDirectory.Exists(LLibDirectory) then
    Exit;

  LCompilerFileNames := TDirectory.GetFiles(LBinDirectory, 'dcc32*.dll');

  if Length(LCompilerFileNames) = 0 then
    Exit;

  LDocumentDirectory := ExtractFileDir(AFileName);
  LDirectory := TPath.Combine(TPath.GetTempPath, 'TTextEditor');
  LProjectFileName := TPath.Combine(LDirectory, 'Fallback.dproj');
  LSettingsFileName := TPath.Combine(LDirectory, 'Fallback.' +
    IntToHex(THashFNV1a32.GetHashValue(LDocumentDirectory.ToLower), 8) + '.delphilsp.json');

  try
    TDirectory.CreateDirectory(LDirectory);
    TFile.WriteAllText(LProjectFileName, '<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003"/>',
      TEncoding.UTF8);
    TFile.WriteAllText(LSettingsFileName,
      '{"settings":{"project":"' + TTextEditorLanguageServer.FileNameToUri(LProjectFileName) +
      '","dllname":"' + ExtractFileName(LCompilerFileNames[High(LCompilerFileNames)]) +
      '","dccOptions":"-U\"' + EscapedPath(LDocumentDirectory) + '\";\"' + EscapedPath(LLibDirectory) + '\" ' +
      '-NSSystem;Xml;Data;Datasnap;Web;Soap;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;Winapi;System.Win"}}',
      TEncoding.UTF8);
  except
    Exit('');
  end;

  Result := LSettingsFileName;
end;

function TTextEditorLanguageServers.ResolveConfiguration(const ADefinition: TTextEditorLanguageServerDefinition;
  const AFileName: string; out ARootPath: string): string;
var
  LMarkerFileName: string;
begin
  ARootPath := ResolveRootPath(ADefinition, AFileName, LMarkerFileName);

  if LMarkerFileName.IsEmpty and (ADefinition.SettingsFallback = sfDelphiLsp) and
    ADefinition.Configuration.Contains('%MARKERFILEURI%') then
  begin
    LMarkerFileName := CreateDelphiLspFallbackSettings(ADefinition, AFileName);

    if Assigned(FOnLog) then
      if LMarkerFileName.IsEmpty then
        FOnLog(Self, '[' + ADefinition.Name + '] No ' + ADefinition.RootPath +
          ' found for this file and no default settings could be generated - completions will be keywords only.')
      else
        FOnLog(Self, '[' + ADefinition.Name + '] No ' + ADefinition.RootPath +
          ' found for this file - using generated default settings (the file''s folder and the Studio library).');
  end;

  Result := BuildConfiguration(ADefinition, LMarkerFileName);
end;

function TTextEditorLanguageServers.CreateInstance(const ADefinition: TTextEditorLanguageServerDefinition; const ARootPath: string;
  const AConfiguration: string): TServerInstance;
var
  LServer: TTextEditorLanguageServer;
begin
  LServer := TTextEditorLanguageServer.Create(nil);
  LServer.ServerCommandLine := ADefinition.CommandLine;
  LServer.RootPath := ARootPath;
  LServer.ServerDirectory := ARootPath;
  LServer.InitializationOptions := ADefinition.InitializationOptions;
  LServer.Configuration := AConfiguration;
  LServer.AutoRestart := FAutoRestart;
  LServer.CompletionTriggerEnabled := FCompletionTriggerEnabled;
  LServer.HoverDelay := FHoverDelay;
  LServer.HoverEnabled := FHoverEnabled;
  LServer.LogTraffic := FLogTraffic;
  LServer.SignatureHelpEnabled := FSignatureHelpEnabled;
  LServer.SyncRequestTimeout := FSyncRequestTimeout;
  LServer.OnDiagnostics := InstanceDiagnostics;
  LServer.OnGotoLocation := InstanceGotoLocation;
  LServer.OnLog := InstanceLog;
  LServer.OnStateChange := InstanceStateChange;

  Result := TServerInstance.Create;
  Result.Server := LServer;
  Result.DefinitionId := ADefinition.ID;
  Result.DefinitionName := ADefinition.Name;
  Result.RootPath := ARootPath;
  Result.Configuration := AConfiguration;

  FInstances.Add(Result);
  FCleanupTimer.Enabled := True;

  LServer.Start;
end;

function TTextEditorLanguageServers.Attach(const AEditor: TCustomTextEditor; const AFileName: string): TTextEditorLanguageServer;
var
  LDefinition: TTextEditorLanguageServerDefinition;
  LInstance, LCurrentInstance: TServerInstance;
  LConfiguration, LRootPath: string;
begin
  LDefinition := DefinitionForFileName(AFileName);

  if not Assigned(LDefinition) then
  begin
    Detach(AEditor);
    Exit(nil);
  end;

  LConfiguration := ResolveConfiguration(LDefinition, AFileName, LRootPath);
  LInstance := FindInstance(LDefinition.ID, LRootPath);

  if FEditors.TryGetValue(AEditor, LCurrentInstance) and (LCurrentInstance <> LInstance) then
    Detach(AEditor);

  if not Assigned(LInstance) then
    LInstance := CreateInstance(LDefinition, LRootPath, LConfiguration)
  else
  begin
    if LInstance.Server.State = lssStopped then
      LInstance.Server.Start;

    if LConfiguration <> LInstance.Configuration then
    begin
      LInstance.Configuration := LConfiguration;
      LInstance.Server.Configuration := LConfiguration;
      LInstance.Server.SendConfiguration(LConfiguration);
    end;
  end;

  LInstance.MarkBusy;
  LInstance.Server.OpenDocument(AEditor, AFileName, LDefinition.LanguageId);

  FEditors.AddOrSetValue(AEditor, LInstance);
  AEditor.FreeNotification(Self);

  Result := LInstance.Server;
end;

procedure TTextEditorLanguageServers.Detach(const AEditor: TCustomTextEditor);
var
  LInstance: TServerInstance;
begin
  if not FEditors.TryGetValue(AEditor, LInstance) then
    Exit;

  FEditors.Remove(AEditor);
  LInstance.Server.CloseDocument(AEditor);

  if LInstance.Server.DocumentCount = 0 then
  begin
    if FIdleTimeout = 0 then
      Retire(LInstance)
    else
      LInstance.MarkIdle;
  end;
end;

procedure TTextEditorLanguageServers.DocumentSaved(const AEditor: TCustomTextEditor);
var
  LInstance: TServerInstance;
begin
  if FEditors.TryGetValue(AEditor, LInstance) then
    LInstance.Server.DocumentSaved(AEditor);
end;

procedure TTextEditorLanguageServers.Retire(const AInstance: TServerInstance);
begin
  AInstance.Retired := True;
  AInstance.Server.Stop;

  FCleanupTimer.Enabled := True;
end;

procedure TTextEditorLanguageServers.CleanupTimerTimer(ASender: TObject);
var
  LIndex: Integer;
  LInstance: TServerInstance;
begin
  for LIndex := FInstances.Count - 1 downto 0 do
  begin
    LInstance := FInstances[LIndex];

    if LInstance.Retired then
    begin
      if LInstance.Server.State = lssStopped then
        FInstances.Delete(LIndex);
    end
    else
    if (LInstance.Server.DocumentCount = 0) and (FIdleTimeout >= 0) and (LInstance.IdleMilliseconds >= FIdleTimeout) then
      Retire(LInstance);
  end;

  FCleanupTimer.Enabled := FInstances.Count > 0;
end;

procedure TTextEditorLanguageServers.StopAll;
begin
  FCleanupTimer.Enabled := False;
  FEditors.Clear;
  FInstances.Clear;
end;

procedure TTextEditorLanguageServers.InstanceDiagnostics(const ASender: TObject; const AEditor: TCustomTextEditor;
  const ADiagnostics: TArray<TTextEditorLanguageServerDiagnostic>);
begin
  if Assigned(FOnDiagnostics) then
    FOnDiagnostics(ASender, AEditor, ADiagnostics);
end;

procedure TTextEditorLanguageServers.InstanceGotoLocation(const ASender: TObject; const AEditor: TCustomTextEditor;
  const ALocation: TTextEditorLanguageServerLocation);
begin
  if Assigned(FOnGotoLocation) then
    FOnGotoLocation(ASender, AEditor, ALocation);
end;

procedure TTextEditorLanguageServers.InstanceLog(const ASender: TObject; const AMessage: string);
var
  LInstance: TServerInstance;
begin
  if not Assigned(FOnLog) then
    Exit;

  LInstance := InstanceForServer(ASender);

  if Assigned(LInstance) then
    FOnLog(ASender, '[' + LInstance.DefinitionName + '] ' + AMessage)
  else
    FOnLog(ASender, AMessage);
end;

procedure TTextEditorLanguageServers.InstanceStateChange(const ASender: TObject; const AState: TTextEditorLanguageServerState);
begin
  if Assigned(FOnStateChange) then
    FOnStateChange(ASender, AState);
end;

procedure TTextEditorLanguageServers.DetectInstalledServers;

  function ProgramFilesDirectory: string;
  begin
    Result := GetEnvironmentVariable('ProgramW6432');

    if Result.IsEmpty then
      Result := GetEnvironmentVariable('ProgramFiles');
  end;

  function AddDefinition(const AName, ACommandLine, AExtensions, ALanguageId, AMarkerFiles: string): TTextEditorLanguageServerDefinition;
  begin
    Result := FServers.FindByName(AName);

    if not Assigned(Result) then
    begin
      Result := FServers.Add;
      Result.Name := AName;
    end;

    Result.CommandLine := ACommandLine;
    Result.Extensions := AExtensions;
    Result.LanguageId := ALanguageId;
    Result.RootPathKind := rpMarkerFile;
    Result.RootPath := AMarkerFiles;
  end;

  function NodeCommandLine(const AScriptFileName: string): string;
  var
    LNodeFileName, LScriptFileName: string;
  begin
    Result := '';

    LNodeFileName := ProgramFilesDirectory + '\nodejs\node.exe';
    LScriptFileName := GetEnvironmentVariable('APPDATA') + '\npm\node_modules\' + AScriptFileName;

    if FileExists(LNodeFileName) and FileExists(LScriptFileName) then
      Result := '"' + LNodeFileName + '" "' + LScriptFileName + '" --stdio';
  end;

var
  LDirectory, LFileName, LCommandLine: string;
  LDefinition: TTextEditorLanguageServerDefinition;
begin
  LDirectory := GetEnvironmentVariable('ProgramFiles(x86)') + '\Embarcadero\Studio';
  LCommandLine := '';

  if TDirectory.Exists(LDirectory) then
  for var LStudioDirectory in TDirectory.GetDirectories(LDirectory) do
  begin
    LFileName := LStudioDirectory + '\bin\DelphiLSP.exe';

    if FileExists(LFileName) then
      LCommandLine := '"' + LFileName + '"';
  end;

  if not LCommandLine.IsEmpty then
  begin
    LDefinition := AddDefinition('DelphiLSP', LCommandLine, '.pas;.dpr;.dpk;.inc', 'pascal', '*.delphilsp.json');
    LDefinition.Configuration := '{"settings":{"settingsFile":"%MARKERFILEURI%"}}';
    LDefinition.SettingsFallback := sfDelphiLsp;
  end;

  LFileName := ProgramFilesDirectory + '\LLVM\bin\clangd.exe';

  if FileExists(LFileName) then
  begin
    AddDefinition('clangd (C)', '"' + LFileName + '"', '.c;.h', 'c', 'compile_commands.json;compile_flags.txt;.clangd');
    AddDefinition('clangd (C++)', '"' + LFileName + '"', '.cpp;.cc;.cxx;.hpp', 'cpp', 'compile_commands.json;compile_flags.txt;.clangd');
  end;

  LCommandLine := NodeCommandLine('pyright\langserver.index.js');

  if not LCommandLine.IsEmpty then
    AddDefinition('Pyright', LCommandLine, '.py;.pyi', 'python', 'pyrightconfig.json;pyproject.toml');

  LCommandLine := NodeCommandLine('typescript-language-server\lib\cli.mjs');

  if not LCommandLine.IsEmpty then
  begin
    AddDefinition('TypeScript', LCommandLine, '.ts;.tsx', 'typescript', 'tsconfig.json;jsconfig.json;package.json');
    AddDefinition('JavaScript', LCommandLine, '.js;.jsx;.mjs', 'javascript', 'tsconfig.json;jsconfig.json;package.json');
  end;
end;

end.
