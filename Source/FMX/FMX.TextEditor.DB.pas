unit FMX.TextEditor.DB;

interface

uses
  System.Classes, System.Types, Data.DB, FMX.TextEditor, FMX.TextEditor.KeyCommands, FMX.Types;

type
  TFieldDataLink = class(TDataLink)
  private
    FField: TField;
    FFieldName: string;
    FControl: TComponent;
    FEditing: Boolean;
    FModified: Boolean;
    FOnDataChange: TNotifyEvent;
    FOnEditingChange: TNotifyEvent;
    FOnUpdateData: TNotifyEvent;
    FOnActiveChange: TNotifyEvent;
    function GetCanModify: Boolean;
    procedure SetEditing(Value: Boolean);
    procedure SetField(Value: TField);
    procedure SetFieldName(const Value: string);
    procedure UpdateField;
  protected
    procedure ActiveChanged; override;
    procedure DataEvent(Event: TDataEvent; Info: NativeInt); override;
    procedure EditingChanged; override;
    procedure FocusControl(Field: TFieldRef); override;
    procedure LayoutChanged; override;
    procedure RecordChanged(Field: TField); override;
    procedure UpdateData; override;
  public
    constructor Create;
    function Edit: Boolean;
    procedure Modified;
    procedure Reset;
    property CanModify: Boolean read GetCanModify;
    property Control: TComponent read FControl write FControl;
    property Editing: Boolean read FEditing;
    property Field: TField read FField;
    property FieldName: string read FFieldName write SetFieldName;
    property OnDataChange: TNotifyEvent read FOnDataChange write FOnDataChange;
    property OnEditingChange: TNotifyEvent read FOnEditingChange write FOnEditingChange;
    property OnUpdateData: TNotifyEvent read FOnUpdateData write FOnUpdateData;
    property OnActiveChange: TNotifyEvent read FOnActiveChange write FOnActiveChange;
  end;

  TCustomDBTextEditor = class abstract(TCustomTextEditor)
  strict private
    FBeginEdit: Boolean;
    FDataLink: TFieldDataLink;
    FEditing: Boolean;
    FLoadData: TNotifyEvent;
    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;
    procedure DataChange(Sender: TObject);
    procedure EditingChange(Sender: TObject);
    procedure SetDataField(const AValue: string);
    procedure SetDataSource(const AValue: TDataSource);
    procedure SetEditing(const AValue: Boolean);
    procedure UpdateData(Sender: TObject);
  protected
    function GetReadOnly: Boolean; override;
    procedure DoChange; override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure Loaded; override;
    procedure SetReadOnly(const AValue: Boolean); override;
    property DataField: string read GetDataField write SetDataField;
    property DataLink: TFieldDataLink read FDataLink;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property Field: TField read GetField;
    property OnLoadData: TNotifyEvent read FLoadData write FLoadData;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DragDrop(const AData: TDragObject; const APoint: TPointF); override;
    procedure ExecuteCommand(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer); override;
    procedure LoadBlob;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  end;

  [ComponentPlatformsAttribute(pidWin32 or pidWin64 or pidOSX64 or pidOSXArm64 or pidiOSDevice64 or pidiOSSimulatorArm64 or pidAndroidArm32 or pidAndroidArm64 or pidLinux64)]
  TDBTextEditor = class(TCustomDBTextEditor)
  published
    property ActiveLine;
    property Align;
    property Anchors;
    property Border;
    property Caret;
    property CodeFolding;
    property Colors;
    property CompletionProposal;
    property Cursor;
    property DataField;
    property DataSource;
    property EditorMode;
    property Enabled;
    property Field;
    property FileMaxReadBufferSize;
    property FileMinShowProgressSize;
    property FontStyles;
    property Fonts;
    property Height;
    property HighlightLine;
    property Highlighter;
    property KeyCommands;
    property LeftMargin;
    property LineSpacing;
    property MatchingPairs;
    property MaxLength;
    property Minimap;
    property Name;
    property OnAdditionalKeywords;
    property OnAfterBookmarkPlaced;
    property OnAfterDeleteBookmark;
    property OnAfterDeleteMark;
    property OnAfterLinePaint;
    property OnAfterLoadFromStream;
    property OnAfterMarkPanelPaint;
    property OnAfterMarkPlaced;
    property OnBeforeDeleteMark;
    property OnBeforeMarkPanelPaint;
    property OnBeforeMarkPlaced;
    property OnBeforeSaveToFile;
    property OnCaretChanged;
    property OnChange;
    property OnClick;
    property OnCommandProcessed;
    property OnCompletionProposalCanceled;
    property OnCompletionProposalExecute;
    property OnCreateHighlighterStream;
    property OnCustomLineColors;
    property OnCustomTokenAttribute;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDropFiles;
    property OnEnter;
    property OnExit;
    property OnHideProgressDialog;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnLeftMarginClick;
    property OnLinkClick;
    property OnLoadData;
    property OnLoadingProgress;
    property OnMarkPanelLinePaint;
    property OnModified;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnPaint;
    property OnProcessCommand;
    property OnProcessUserCommand;
    property OnReplaceSearchCount;
    property OnReplaceText;
    property OnRightMarginMouseUp;
    property OnScroll;
    property OnSearchEngineChanged;
    property OnSelectionChanged;
    property OnShowProgressDialog;
    property Options;
    property OvertypeMode;
    property ParentShowHint;
    property PartialLoad;
    property Margins;
    property Position;
    property Size;
    property PopupMenu;
    property ReadOnly;
    property Replace;
    property RightMargin;
    property Ruler;
    property Scroll;
    property Search;
    property Selection;
    property ShowHint;
    property SpecialChars;
    property SyncEdit;
    property TabOrder;
    property TabStop;
    property Tabs;
    property Tag;
    property Theme;
    property Touch;
    property TripleClickInterval;
    property Undo;
    property UnknownChars;
    property Visible;
    property WantReturns;
    property Width;
    property WordWrap;
    property ZoomPercentage;
  end;

implementation

uses
  System.SysUtils, FMX.Controls, FMX.TextEditor.Consts, FMX.TextEditor.Encoding;

{ TFieldDataLink }

constructor TFieldDataLink.Create;
begin
  inherited Create;
  VisualControl := True;
end;

procedure TFieldDataLink.SetEditing(Value: Boolean);
begin
  if FEditing <> Value then
  begin
    FEditing := Value;
    FModified := False;
    if Assigned(FOnEditingChange) then FOnEditingChange(Self);
  end;
end;

procedure TFieldDataLink.SetFieldName(const Value: string);
begin
  if FFieldName <> Value then
  begin
    FFieldName :=  Value;
    UpdateField;
  end;
end;

procedure TFieldDataLink.SetField(Value: TField);
begin
  if FField <> Value then
  begin
    FField := Value;
    if (Dataset = nil) or not DataSet.ControlsDisabled then
    begin
      EditingChanged;
      RecordChanged(nil);
    end;
  end;
end;

procedure TFieldDataLink.UpdateField;
begin
  if Active and (FFieldName <> '') then
  begin
    FField := nil;

    if Assigned(FControl) then
      SetField(GetFieldProperty(DataSource.DataSet, FControl, FFieldName))
    else
      SetField(DataSource.DataSet.FieldByName(FFieldName));
  end
  else
    SetField(nil);
end;

function TFieldDataLink.Edit: Boolean;
begin
  if CanModify then
    inherited Edit;

  Result := FEditing;
end;

function TFieldDataLink.GetCanModify: Boolean;
begin
  Result := not ReadOnly and (Field <> nil) and Field.CanModify;
end;

procedure TFieldDataLink.Modified;
begin
  FModified := True;
end;

procedure TFieldDataLink.Reset;
begin
  RecordChanged(nil);
end;

procedure TFieldDataLink.ActiveChanged;
begin
  UpdateField;
  if Assigned(FOnActiveChange) then FOnActiveChange(Self);
end;

procedure TFieldDataLink.EditingChanged;
begin
  SetEditing(inherited Editing and CanModify);
end;

procedure TFieldDataLink.FocusControl(Field: TFieldRef);
begin
  if (Field^ <> nil) and (Field^ = FField) and (FControl is TControl) then
    if TControl(FControl).CanFocus then
    begin
      Field^ := nil;
      TControl(FControl).SetFocus;
    end;
end;

procedure TFieldDataLink.RecordChanged(Field: TField);
begin
  if (Field = nil) or (Field = FField) then
  begin
    if Assigned(FOnDataChange) then FOnDataChange(Self);
    FModified := False;
  end;
end;

procedure TFieldDataLink.LayoutChanged;
begin
  UpdateField;
end;

procedure TFieldDataLink.UpdateData;
begin
  if FModified then
  begin
    if (Field <> nil) and Assigned(FOnUpdateData) then FOnUpdateData(Self);
    FModified := False;
  end;
end;

procedure TFieldDataLink.DataEvent(Event: TDataEvent; Info: NativeInt);
begin
  inherited;
  if Event = deDisabledStateChange then
  begin
    if Boolean(Info) then
      UpdateField
    else
      FField := nil;
  end;
end;

{ TCustomDBTextEditor }

constructor TCustomDBTextEditor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FDataLink := TFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := DataChange;
  FDataLink.OnEditingChange := EditingChange;
  FDataLink.OnUpdateData := UpdateData;
end;

destructor TCustomDBTextEditor.Destroy;
begin
  FDataLink.Free;
  FDataLink := nil;

  inherited Destroy;
end;

procedure TCustomDBTextEditor.DoEnter;
begin
  if not ReadOnly and FDataLink.CanModify then
    SetEditing(True);

  inherited;
end;

procedure TCustomDBTextEditor.DoExit;
begin
  if not ReadOnly and FDataLink.CanModify then
  begin
    try
      FDataLink.UpdateRecord;
    except
      SetFocus;
      raise;
    end;

    SetEditing(False);
  end;

  inherited;
end;

procedure TCustomDBTextEditor.DataChange(Sender: TObject);
begin
  if Assigned(FDataLink.Field) then
  begin
    if FBeginEdit then
    begin
      FBeginEdit := False;
      Exit;
    end;

    if FDataLink.Field.IsBlob then
      LoadBlob
    else
      Text := FDataLink.Field.Text;

    if Assigned(FLoadData) then
      FLoadData(Self);
  end
  else
    Text := if csDesigning in ComponentState then Name else '';
end;

procedure TCustomDBTextEditor.DragDrop(const AData: TDragObject; const APoint: TPointF);
begin
  FDataLink.Edit;

  inherited;
end;

procedure TCustomDBTextEditor.EditingChange(Sender: TObject);
begin
  if FDataLink.Editing and Assigned(FDataLink.DataSource) and (FDataLink.DataSource.State <> dsInsert) then
    FBeginEdit := True;
end;

procedure TCustomDBTextEditor.ExecuteCommand(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);
begin
  if (ACommand = TKeyCommands.Char) and (AChar = TControlCharacters.Escape) then
    FDataLink.Reset
  else
  if (ACommand <> TKeyCommands.Copy) and (ACommand >= TKeyCommands.EditCommandFirst) and (ACommand <= TKeyCommands.EditCommandLast) then
    if not FDataLink.Edit then
      Exit;

  inherited;
end;

function TCustomDBTextEditor.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

function TCustomDBTextEditor.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

function TCustomDBTextEditor.GetField: TField;
begin
  Result := FDataLink.Field;
end;

function TCustomDBTextEditor.GetReadOnly: Boolean;
begin
  Result := FDataLink.ReadOnly;
end;

procedure TCustomDBTextEditor.Loaded;
begin
  inherited Loaded;

  if csDesigning in ComponentState then
    DataChange(Self);
end;

procedure TCustomDBTextEditor.LoadBlob;
var
  LStream: TStream;
  LEncoding: System.SysUtils.TEncoding;
begin
  LStream := FDataLink.DataSet.CreateBlobStream(FDataLink.Field, bmRead);
  try
    LEncoding := nil;

    case FDataLink.Field.DataType of
      ftWideString, ftWideMemo:
        LEncoding := FMX.TextEditor.Encoding.TEncoding.UTF8WithoutBOM;
    end;

    LoadFromStream(LStream, LEncoding);
  finally
    LStream.Free;
  end;
end;

procedure TCustomDBTextEditor.DoChange;
begin
  FDataLink.Modified;

  inherited;
end;

procedure TCustomDBTextEditor.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited Notification(AComponent, AOperation);

  if (AOperation = opRemove) and Assigned(FDataLink) and (AComponent = DataSource) then
    DataSource := nil;
end;

procedure TCustomDBTextEditor.SetDataField(const AValue: string);
begin
  FDataLink.FieldName := AValue;
end;

procedure TCustomDBTextEditor.SetDataSource(const AValue: TDataSource);
begin
  if not (FDataLink.DataSourceFixed and (csLoading in ComponentState)) then
    FDataLink.DataSource := AValue;

  if Assigned(AValue) then
    AValue.FreeNotification(Self);
end;

procedure TCustomDBTextEditor.SetEditing(const AValue: Boolean);
begin
  if FEditing <> AValue then
  begin
    FEditing := AValue;

    if not Assigned(FDataLink.Field) or not FDataLink.Field.IsBlob then
      FDataLink.Reset;
  end;
end;

procedure TCustomDBTextEditor.SetReadOnly(const AValue: Boolean);
begin
  FDataLink.ReadOnly := AValue;
end;

procedure TCustomDBTextEditor.UpdateData(Sender: TObject);
var
  LBlobField: TBlobField;
  LStream: TMemoryStream;
begin
  if not FDataLink.CanModify or not Modified then
    Exit;

  FDataLink.Edit;

  if FDataLink.Field.IsBlob then
  begin
    LBlobField := FDataLink.Field as TBlobField;

    LStream := TMemoryStream.Create;
    try
      SaveToStream(LStream, Lines.Encoding);

      LBlobField.ReadOnly := False;
      LBlobField.LoadFromStream(LStream);
    finally
      LStream.Free;
    end;
  end
  else
    FDataLink.Field.AsString := Text;
end;

end.
