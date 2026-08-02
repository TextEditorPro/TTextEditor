unit TextEditor.DB;

{$I TextEditor.Defines.inc}

interface

uses
  Winapi.Messages, System.Classes, Vcl.Controls, Vcl.DBCtrls, Data.DB, TextEditor, TextEditor.KeyCommands;

type
  TCustomDBTextEditor = class abstract(TCustomTextEditor)
  strict private
    FBeginEdit: Boolean;
    FDataLink: TFieldDataLink;
    FEditing: Boolean;
    FLoadData: TNotifyEvent;
    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;
    procedure CMEnter(var AMessage: TCMEnter); message CM_ENTER;
    procedure CMExit(var AMessage: TCMExit); message CM_EXIT;
    procedure CMGetDataLink(var AMessage: TMessage); message CM_GETDATALINK;
    procedure DataChange(Sender: TObject);
    procedure EditingChange(Sender: TObject);
    procedure SetDataField(const AValue: string);
    procedure SetDataSource(const AValue: TDataSource);
    procedure SetEditing(const AValue: Boolean);
    procedure UpdateData(Sender: TObject);
  protected
    function GetReadOnly: Boolean; override;
    procedure DoChange; override;
    procedure Loaded; override;
    procedure SetReadOnly(const AValue: Boolean); override;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property Field: TField read GetField;
    property OnLoadData: TNotifyEvent read FLoadData write FLoadData;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DragDrop(ASource: TObject; X, Y: Integer); override;
    procedure ExecuteCommand(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer); override;
    procedure LoadBlob;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  end;

  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
  TDBTextEditor = class(TCustomDBTextEditor)
  published
    property ActiveLine;
    property Align;
    property Anchors;
    property Border;
{$IFDEF ALPHASKINS}
    property BoundLabel;
{$ENDIF}
    property Caret;
    property CodeFolding;
    property Colors;
    property CompletionProposal;
    property Constraints;
    property Ctl3D;
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
    property ImeMode;
    property ImeName;
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
    property OnChangeScale;
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
    property OnEndDock;
    property OnEndDrag;
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
    property OnMouseWheelDown;
    property OnMouseWheelUp;
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
    property OnStartDock;
    property OnStartDrag;
    property Options;
    property OvertypeMode;
    property ParentColor;
    property ParentCtl3D;
    property ParentShowHint;
    property PartialLoad;
    property PopupMenu;
    property ReadOnly;
    property Replace;
    property RightMargin;
    property Ruler;
    property Scroll;
    property Search;
    property Selection;
    property ShowHint;
{$IFDEF ALPHASKINS}
    property SkinData;
{$ENDIF}
    property SpecialChars;
{$IFDEF TEXT_EDITOR_SPELL_CHECK}
    property SpellCheck;
{$ENDIF}
    property StyleElements;
    property SyncEdit;
    property TabOrder;
    property Tabs;
    property TabStop;
    property Tag;
    property Theme;
    property Touch;
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
  Winapi.Windows, System.SysUtils, TextEditor.Consts, TextEditor.Encoding
{$IFDEF TEXT_EDITOR_STYLE_HOOKS}
  , Vcl.Themes, TextEditor.StyleHooks
{$ENDIF};

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

procedure TCustomDBTextEditor.CMEnter(var AMessage: TCMEnter);
begin
  if not ReadOnly and FDataLink.CanModify then
    SetEditing(True);

  inherited;
end;

procedure TCustomDBTextEditor.CMExit(var AMessage: TCMExit);
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

procedure TCustomDBTextEditor.CMGetDataLink(var AMessage: TMessage);
begin
  AMessage.Result := Winapi.Windows.LRESULT(FDataLink);
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

procedure TCustomDBTextEditor.DragDrop(ASource: TObject; X, Y: Integer);
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
        LEncoding := TextEditor.Encoding.TEncoding.UTF8WithoutBOM;
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

{$IFDEF TEXT_EDITOR_STYLE_HOOKS}

initialization

  TCustomStyleEngine.RegisterStyleHook(TDBTextEditor, TVclStyleScrollBarsHook);

finalization

  TCustomStyleEngine.UnRegisterStyleHook(TDBTextEditor, TVclStyleScrollBarsHook);

{$ENDIF}

end.
