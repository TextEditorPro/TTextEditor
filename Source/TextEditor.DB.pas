unit TextEditor.DB;

{$I TextEditor.Defines.inc}

interface

uses
  Winapi.Messages, System.Classes, System.Types, Vcl.Controls, Vcl.DBCtrls, Vcl.Graphics, Data.DB, TextEditor,
  TextEditor.KeyCommands;

type
  TCustomDBTextEditor = class;

  TTextEditorDBDesignHook = class abstract(TObject)
  public
    function GetComponentImage(const AComponent: TComponent; const ASize: Integer): TGraphic; virtual; abstract;
    function IsComponentSelected(const AInstance: TPersistent): Boolean; virtual; abstract;
    procedure RegisterEditor(const AEditor: TCustomDBTextEditor); virtual; abstract;
    procedure SelectComponent(const AInstance: TPersistent); virtual; abstract;
    procedure ShowComponentMenu(const AComponent: TComponent; const AScreenPoint: TPoint); virtual; abstract;
    procedure UnregisterEditor(const AEditor: TCustomDBTextEditor); virtual; abstract;
  end;

  TCustomDBTextEditor = class abstract(TCustomTextEditor)
  strict private
    FBeginEdit: Boolean;
    FDataLink: TFieldDataLink;
    FEditing: Boolean;
    FLoadData: TNotifyEvent;
    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetDesignLinkAt(const AX, AY: Integer): TComponent;
    function GetDesignLinkRect(const AIndex, ACount: Integer): TRect;
    function GetDesignLinks: TArray<TComponent>;
    function GetField: TField;
    function HandleDesignMouseMessage(var AMessage: TMessage): Boolean;
    function ScaleMetric(const AValue: Integer): Integer;
    procedure CMDesignHitTest(var AMessage: TCMDesignHitTest); message CM_DESIGNHITTEST;
    procedure CMEnter(var AMessage: TCMEnter); message CM_ENTER;
    procedure CMExit(var AMessage: TCMExit); message CM_EXIT;
    procedure CMGetDataLink(var AMessage: TMessage); message CM_GETDATALINK;
    procedure DataChange(Sender: TObject);
    procedure EditingChange(Sender: TObject);
    procedure PaintDesignHandles(const ARect: TRect);
    procedure PaintDesignLinks;
    procedure SetDataField(const AValue: string);
    procedure SetDataSource(const AValue: TDataSource);
    procedure SetEditing(const AValue: Boolean);
    procedure UpdateData(Sender: TObject);
  protected
    function GetReadOnly: Boolean; override;
    procedure DoChange; override;
    procedure Loaded; override;
    procedure Paint; override;
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
    procedure InvalidateDesignLinks;
    procedure LoadBlob;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
    procedure WndProc(var AMessage: TMessage); override;
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
    property KeywordImages;
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

var
  GTextEditorDBDesignHook: TTextEditorDBDesignHook;

implementation

uses
  Winapi.Windows, System.SysUtils, System.UITypes, TextEditor.Consts, TextEditor.Encoding;

const
  DESIGN_HANDLE_BORDER_COLOR = TColor($00B56B2D);
  DESIGN_HANDLE_COLOR = TColor($00E8AE78);
  DESIGN_HANDLE_SIZE = 7;
  DESIGN_LINK_IMAGE_SIZE = 24;
  DESIGN_LINK_MARGIN = 4;
  DESIGN_LINK_MAX_COUNT = 2;
  DESIGN_LINK_SIZE = 28;

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
  if Assigned(GTextEditorDBDesignHook) then
    GTextEditorDBDesignHook.UnregisterEditor(Self);

  FDataLink.Free;
  FDataLink := nil;

  inherited Destroy;
end;

procedure TCustomDBTextEditor.CMDesignHitTest(var AMessage: TCMDesignHitTest);
begin
  if Assigned(GetDesignLinkAt(AMessage.XPos, AMessage.YPos)) then
    AMessage.Result := 1
  else
    inherited;
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

function TCustomDBTextEditor.GetDesignLinkAt(const AX, AY: Integer): TComponent;
var
  LComponents: TArray<TComponent>;
begin
  LComponents := GetDesignLinks;

  for var LIndex := 0 to High(LComponents) do
  if GetDesignLinkRect(LIndex, Length(LComponents)).Contains(Point(AX, AY)) then
    Exit(LComponents[LIndex]);

  Result := nil;
end;

function TCustomDBTextEditor.GetDesignLinkRect(const AIndex, ACount: Integer): TRect;
var
  LMargin, LSize: Integer;
begin
  LMargin := ScaleMetric(DESIGN_LINK_MARGIN);
  LSize := ScaleMetric(DESIGN_LINK_SIZE);

  Result.Right := ClientWidth - LMargin - (ACount - 1 - AIndex) * (LSize + LMargin);
  Result.Left := Result.Right - LSize;
  Result.Bottom := ClientHeight - LMargin;
  Result.Top := Result.Bottom - LSize;
end;

function TCustomDBTextEditor.GetDesignLinks: TArray<TComponent>;
begin
  Result := nil;

  if not (csDesigning in ComponentState) or not Assigned(FDataLink) or not Assigned(FDataLink.DataSource) then
    Exit;

  Result := [FDataLink.DataSource];

  if Assigned(FDataLink.DataSource.DataSet) then
    Result := Result + [FDataLink.DataSource.DataSet];
end;

function TCustomDBTextEditor.GetField: TField;
begin
  Result := FDataLink.Field;
end;

function TCustomDBTextEditor.HandleDesignMouseMessage(var AMessage: TMessage): Boolean;
var
  LComponent: TComponent;
  LPoint: TPoint;
begin
  case AMessage.Msg of
    WM_LBUTTONDOWN, WM_LBUTTONDBLCLK, WM_LBUTTONUP, WM_RBUTTONDOWN, WM_RBUTTONUP:
      LPoint := Point(TWMMouse(AMessage).XPos, TWMMouse(AMessage).YPos);
    WM_CONTEXTMENU:
      LPoint := ScreenToClient(Point(TWMContextMenu(AMessage).XPos, TWMContextMenu(AMessage).YPos));
  else
    Exit(False);
  end;

  LComponent := GetDesignLinkAt(LPoint.X, LPoint.Y);

  if not Assigned(LComponent) then
    Exit(False);

  if Assigned(GTextEditorDBDesignHook) then
  case AMessage.Msg of
    WM_LBUTTONDOWN:
      GTextEditorDBDesignHook.SelectComponent(LComponent);
    WM_RBUTTONDOWN:
      GTextEditorDBDesignHook.ShowComponentMenu(LComponent, ClientToScreen(LPoint));
  end;

  AMessage.Result := 0;

  Result := True;
end;

function TCustomDBTextEditor.GetReadOnly: Boolean;
begin
  Result := FDataLink.ReadOnly;
end;

procedure TCustomDBTextEditor.InvalidateDesignLinks;
var
  LRect: TRect;
begin
  if not HandleAllocated then
    Exit;

  { Covers the largest link count, so a link removed since the last paint is erased too }
  LRect := TRect.Union(GetDesignLinkRect(0, DESIGN_LINK_MAX_COUNT), GetDesignLinkRect(DESIGN_LINK_MAX_COUNT - 1, DESIGN_LINK_MAX_COUNT));

  InvalidateRect(Handle, LRect, False);
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

procedure TCustomDBTextEditor.Paint;
begin
  inherited Paint;

  if not (csDesigning in ComponentState) then
    Exit;

  if Assigned(GTextEditorDBDesignHook) then
    GTextEditorDBDesignHook.RegisterEditor(Self);

  PaintDesignLinks;
end;

procedure TCustomDBTextEditor.PaintDesignHandles(const ARect: TRect);
var
  LHandleSize: Integer;

  procedure PaintHandle(const ACenterX, ACenterY: Integer);
  var
    LHandleRect: TRect;
  begin
    LHandleRect := Bounds(ACenterX - LHandleSize div 2, ACenterY - LHandleSize div 2, LHandleSize, LHandleSize);

    Canvas.Brush.Color := DESIGN_HANDLE_BORDER_COLOR;
    Canvas.FrameRect(LHandleRect);

    LHandleRect.Inflate(-1, -1);

    Canvas.Brush.Color := DESIGN_HANDLE_COLOR;
    Canvas.FillRect(LHandleRect);
  end;

begin
  LHandleSize := ScaleMetric(DESIGN_HANDLE_SIZE);

  PaintHandle(ARect.Left, ARect.Top);
  PaintHandle(ARect.Right - 1, ARect.Top);
  PaintHandle(ARect.Left, ARect.Bottom - 1);
  PaintHandle(ARect.Right - 1, ARect.Bottom - 1);
end;

procedure TCustomDBTextEditor.PaintDesignLinks;
var
  LComponents: TArray<TComponent>;
  LImage: TGraphic;
  LImageSize: Integer;
  LLinkRect, LRect: TRect;
  LText: string;
begin
  LComponents := GetDesignLinks;

  if Length(LComponents) = 0 then
    Exit;

  LImageSize := ScaleMetric(DESIGN_LINK_IMAGE_SIZE);

  for var LIndex := 0 to High(LComponents) do
  begin
    LLinkRect := GetDesignLinkRect(LIndex, Length(LComponents));
    LRect := LLinkRect;

    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := TColors.SysBtnShadow;
    Canvas.FrameRect(LRect);

    LRect.Inflate(-1, -1);

    Canvas.Brush.Color := TColors.SysBtnFace;
    Canvas.FillRect(LRect);

    LImage := nil;

    if Assigned(GTextEditorDBDesignHook) then
      LImage := GTextEditorDBDesignHook.GetComponentImage(LComponents[LIndex], LImageSize);

    if Assigned(LImage) then
      Canvas.StretchDraw(Bounds(LRect.Left + (LRect.Width - LImageSize) div 2, LRect.Top + (LRect.Height - LImageSize) div 2,
        LImageSize, LImageSize), LImage)
    else
    begin
      LText := Copy(LComponents[LIndex].ClassName, 2, 1);

      Canvas.Font.Color := TColors.SysBtnText;
      Canvas.TextRect(LRect, LRect.Left + (LRect.Width - Canvas.TextWidth(LText)) div 2,
        LRect.Top + (LRect.Height - Canvas.TextHeight(LText)) div 2, LText);
    end;

    if Assigned(GTextEditorDBDesignHook) and GTextEditorDBDesignHook.IsComponentSelected(LComponents[LIndex]) then
      PaintDesignHandles(LLinkRect);
  end;
end;

function TCustomDBTextEditor.ScaleMetric(const AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, CurrentPPI, USER_DEFAULT_SCREEN_DPI);
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

  if csDesigning in ComponentState then
    Invalidate;
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

procedure TCustomDBTextEditor.WndProc(var AMessage: TMessage);
begin
  if (csDesigning in ComponentState) and HandleDesignMouseMessage(AMessage) then
    Exit;

  inherited WndProc(AMessage);
end;

end.
