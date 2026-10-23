unit TextEditor.DB.Design;

interface

uses
  Winapi.Windows, System.Classes, System.Generics.Collections, System.Types, Vcl.Graphics, DesignIntf, TextEditor.DB;

type
  TTextEditorDBIDEDesignHook = class(TTextEditorDBDesignHook)
  strict private
    FDesignNotification: IDesignNotification;
    FEditors: TList<TCustomDBTextEditor>;
    FImages: TObjectDictionary<string, TGraphic>;
  public
    constructor Create;
    destructor Destroy; override;
    function GetComponentImage(const AComponent: TComponent; const ASize: Integer): TGraphic; override;
    function IsComponentSelected(const AInstance: TPersistent): Boolean; override;
    procedure InvalidateEditors;
    procedure RegisterEditor(const AEditor: TCustomDBTextEditor); override;
    procedure SelectComponent(const AInstance: TPersistent); override;
    procedure ShowComponentMenu(const AComponent: TComponent; const AScreenPoint: TPoint); override;
    procedure UnregisterEditor(const AEditor: TCustomDBTextEditor); override;
  end;

  TTextEditorDBDesignNotification = class(TInterfacedObject, IDesignNotification)
  strict private
    FDesignHook: TTextEditorDBIDEDesignHook;
  public
    constructor Create(const ADesignHook: TTextEditorDBIDEDesignHook);
    procedure DesignerClosed(const ADesigner: IDesigner; AGoingDormant: Boolean);
    procedure DesignerOpened(const ADesigner: IDesigner; AResurrecting: Boolean);
    procedure ItemDeleted(const ADesigner: IDesigner; AItem: TPersistent);
    procedure ItemInserted(const ADesigner: IDesigner; AItem: TPersistent);
    procedure ItemsModified(const ADesigner: IDesigner);
    procedure SelectionChanged(const ADesigner: IDesigner; const ASelection: IDesignerSelections);
  end;

function LoadComponentImage(const AClass: TClass; const ASize: Integer): TGraphic;
function TryLoadComponentImage(const AModule: HMODULE; const AClass: TClass; const ASize: Integer; out AImage: TGraphic): Boolean;

implementation

uses
  System.SysUtils, DesignMenus;

{ Component images }

function TryLoadComponentImage(const AModule: HMODULE; const AClass: TClass; const ASize: Integer; out AImage: TGraphic): Boolean;
var
  LBitmap: TBitmap;
  LName, LSizedName: string;
begin
  AImage := nil;

  LName := UpperCase(AClass.ClassName);

  if ASize >= 32 then
    LSizedName := LName + '32'
  else
  if ASize <= 16 then
    LSizedName := LName + '16'
  else
    LSizedName := LName;

  if FindResource(AModule, PChar(LSizedName), RT_BITMAP) <> 0 then
    LName := LSizedName
  else
  if (LSizedName = LName) or (FindResource(AModule, PChar(LName), RT_BITMAP) = 0) then
    Exit(False);

  LBitmap := TBitmap.Create;
  try
    LBitmap.LoadFromResourceName(AModule, LName);

    if LBitmap.PixelFormat = pf32bit then
      LBitmap.AlphaFormat := afDefined
    else
      LBitmap.Transparent := True;
  except
    LBitmap.Free;

    Exit(False);
  end;

  AImage := LBitmap;

  Result := True;
end;

function LoadComponentImage(const AClass: TClass; const ASize: Integer): TGraphic;
var
  LClass: TClass;
  LModule: PLibModule;
begin
  LClass := AClass;

  while Assigned(LClass) and LClass.InheritsFrom(TComponent) do
  begin
    LModule := LibModuleList;

    while Assigned(LModule) do
    begin
      if TryLoadComponentImage(LModule.Instance, LClass, ASize, Result) then
        Exit;

      LModule := LModule.Next;
    end;

    LClass := LClass.ClassParent;
  end;

  Result := nil;
end;

{ TTextEditorDBIDEDesignHook }

constructor TTextEditorDBIDEDesignHook.Create;
begin
  inherited Create;

  FEditors := TList<TCustomDBTextEditor>.Create;
  FImages := TObjectDictionary<string, TGraphic>.Create([doOwnsValues]);
  FDesignNotification := TTextEditorDBDesignNotification.Create(Self);

  RegisterDesignNotification(FDesignNotification);
end;

destructor TTextEditorDBIDEDesignHook.Destroy;
begin
  UnregisterDesignNotification(FDesignNotification);
  FDesignNotification := nil;

  FEditors.Free;
  FImages.Free;

  inherited Destroy;
end;

function TTextEditorDBIDEDesignHook.GetComponentImage(const AComponent: TComponent; const ASize: Integer): TGraphic;
var
  LKey: string;
begin
  LKey := Format('%s:%d', [AComponent.ClassName, ASize]);

  if not FImages.TryGetValue(LKey, Result) then
  begin
    Result := LoadComponentImage(AComponent.ClassType, ASize);

    FImages.Add(LKey, Result);
  end;
end;

function TTextEditorDBIDEDesignHook.IsComponentSelected(const AInstance: TPersistent): Boolean;
var
  LDesigner: IDesigner;
  LSelections: IDesignerSelections;
begin
  if not Supports(FindRootDesigner(AInstance), IDesigner, LDesigner) then
    Exit(False);

  LSelections := CreateSelectionList;
  LDesigner.GetSelections(LSelections);

  for var LIndex := 0 to LSelections.Count - 1 do
  if LSelections[LIndex] = AInstance then
    Exit(True);

  Result := False;
end;

procedure TTextEditorDBIDEDesignHook.InvalidateEditors;
begin
  for var LIndex := 0 to FEditors.Count - 1 do
    FEditors[LIndex].InvalidateDesignLinks;
end;

procedure TTextEditorDBIDEDesignHook.RegisterEditor(const AEditor: TCustomDBTextEditor);
begin
  if not FEditors.Contains(AEditor) then
    FEditors.Add(AEditor);
end;

procedure TTextEditorDBIDEDesignHook.SelectComponent(const AInstance: TPersistent);
var
  LDesigner: IDesigner;
begin
  if Supports(FindRootDesigner(AInstance), IDesigner, LDesigner) then
    LDesigner.SelectComponent(AInstance);
end;

procedure TTextEditorDBIDEDesignHook.ShowComponentMenu(const AComponent: TComponent; const AScreenPoint: TPoint);
var
  LDesigner: IDesigner;
  LLocalMenu: IDesignLocalMenu;
  LRootDesigner: IDesignerNotify;
  LSelections: IDesignerSelections;
begin
  LRootDesigner := FindRootDesigner(AComponent);

  if not Supports(LRootDesigner, IDesigner, LDesigner) or not Supports(LRootDesigner, IDesignLocalMenu, LLocalMenu) then
    Exit;

  LDesigner.SelectComponent(AComponent);

  LSelections := CreateSelectionList;
  LDesigner.GetSelections(LSelections);

  LLocalMenu.BuildLocalMenu(LSelections, [lmComponent]).Popup(AScreenPoint.X, AScreenPoint.Y);
end;

procedure TTextEditorDBIDEDesignHook.UnregisterEditor(const AEditor: TCustomDBTextEditor);
begin
  FEditors.Remove(AEditor);
end;

{ TTextEditorDBDesignNotification }

constructor TTextEditorDBDesignNotification.Create(const ADesignHook: TTextEditorDBIDEDesignHook);
begin
  inherited Create;

  FDesignHook := ADesignHook;
end;

procedure TTextEditorDBDesignNotification.DesignerClosed(const ADesigner: IDesigner; AGoingDormant: Boolean);
begin
end;

procedure TTextEditorDBDesignNotification.DesignerOpened(const ADesigner: IDesigner; AResurrecting: Boolean);
begin
end;

procedure TTextEditorDBDesignNotification.ItemDeleted(const ADesigner: IDesigner; AItem: TPersistent);
begin
  FDesignHook.InvalidateEditors;
end;

procedure TTextEditorDBDesignNotification.ItemInserted(const ADesigner: IDesigner; AItem: TPersistent);
begin
end;

procedure TTextEditorDBDesignNotification.ItemsModified(const ADesigner: IDesigner);
begin
  { A data source's DataSet can change in the Object Inspector without the editor being notified }
  FDesignHook.InvalidateEditors;
end;

procedure TTextEditorDBDesignNotification.SelectionChanged(const ADesigner: IDesigner; const ASelection: IDesignerSelections);
begin
  FDesignHook.InvalidateEditors;
end;

initialization
  GTextEditorDBDesignHook := TTextEditorDBIDEDesignHook.Create;

finalization
  FreeAndNil(GTextEditorDBDesignHook);

end.
