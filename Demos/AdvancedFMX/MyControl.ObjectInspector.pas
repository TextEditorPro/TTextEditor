unit MyControl.ObjectInspector;

interface

uses
  System.Classes, System.SysUtils, System.Types, System.TypInfo, System.UITypes, FMX.Colors, FMX.Controls, FMX.Edit, FMX.Graphics,
  FMX.Layouts, FMX.ListBox, FMX.Objects, FMX.StdCtrls, FMX.TreeView, FMX.Types;

type
  TMyArrayOfString = array of string;

  TMyObjectInspector = class;

  TMyInspectorItem = class(TTreeViewItem)
  strict private
    FCheckBox: TCheckBox;
    FColorSwatch: TRectangle;
    FGrip: TLayout;
    FNameText: TText;
    FPlaceholder: TTreeViewItem;
    FValueText: TText;
    function Inspector: TMyObjectInspector;
    procedure CheckBoxChange(Sender: TObject);
    procedure ValueTextClick(Sender: TObject);
  protected
    procedure SetIsExpanded(const Value: Boolean); override;
  public
    ChildrenLoaded: Boolean;
    HasChildren: Boolean;
    IsBooleanValue: Boolean;
    IsReadOnly: Boolean;
    IsSetValue: Boolean;
    PropTypeInfo: PTypeInfo;
    PropertyInfo: PPropInfo;
    PropertyName: string;
    PropertyObject: TObject;
    PropertyValue: string;
    SetIndex: Integer;
    function ValueLeft: Single;
    procedure AddPlaceholder;
    procedure BuildCells;
    procedure Relayout;
    procedure UpdateValueDisplay(const AParentObject: TObject);
    property ValueText: TText read FValueText;
  end;

  TMyObjectInspector = class(TTreeView)
  strict private
    FDragStartWidth: Single;
    FDragStartX: Single;
    FDraggingColumn: Boolean;
    FEditItem: TMyInspectorItem;
    FEditor: TControl;
    FInspectedObject: TObject;
    FNameColumnWidth: Single;
    FNameTextColor: TAlphaColor;
    FReadOnlyTextColor: TAlphaColor;
    FUnlistedProperties: TStrings;
    FUpdating: Boolean;
    FValueTextColor: TAlphaColor;
    function ParentObjectOf(const AItem: TMyInspectorItem): TObject;
    function PropertyValueAsString(AObject: TObject; APropertyInfo: PPropInfo): string;
    function UnlistedProperty(const APropertyName: string): Boolean;
    procedure ColorComboChange(Sender: TObject);
    procedure ComboChange(Sender: TObject);
    procedure DoObjectChange;
    procedure EditFileNameProperty(const AItem: TMyInspectorItem);
    procedure EditStringsProperty(const AItem: TMyInspectorItem);
    procedure EditorExit(Sender: TObject);
    procedure EditorKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure ForEachItem(const AProc: TProc<TMyInspectorItem>);
    procedure ReleaseEditor;
    procedure SetInspectedObject(const AValue: TObject);
    procedure SetNameColumnWidth(const AValue: Single);
  private
    function CreatePropertyItem(const AParent: TTreeViewItem; const AObject: TObject; const APropertyInfo: PPropInfo): TMyInspectorItem;
    procedure GripMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure GripMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure GripMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure LoadChildren(const AItem: TMyInspectorItem);
    property ValueSyncing: Boolean read FUpdating write FUpdating;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AddUnlistedProperties(const AProperties: TMyArrayOfString);
    procedure BeginEdit(const AItem: TMyInspectorItem);
    procedure EndEdit(const AApply: Boolean);
    procedure SetValueAsString(const AItem: TMyInspectorItem; const AValue: string);
    property InspectedObject: TObject read FInspectedObject write SetInspectedObject;
    property NameColumnWidth: Single read FNameColumnWidth write SetNameColumnWidth;
    property NameTextColor: TAlphaColor read FNameTextColor write FNameTextColor;
    property ReadOnlyTextColor: TAlphaColor read FReadOnlyTextColor write FReadOnlyTextColor;
    property ValueTextColor: TAlphaColor read FValueTextColor write FValueTextColor;
  end;

implementation

uses
  System.Math, System.UIConsts, FMX.Dialogs, FMX.Forms, FMX.Memo, FMX.Menus, FMX.Platform;

const
  TYPE_BITMAP = 'TBitmap';
  TYPE_FILENAME = 'TFileName';
  ITEM_HEIGHT = 21;
  LEVEL_INDENT = 19;

  ShortCuts: array [0 .. 110] of TShortCut = (
    scNone,
    Byte('A') or scCtrl, Byte('B') or scCtrl, Byte('C') or scCtrl, Byte('D') or scCtrl, Byte('E') or scCtrl,
    Byte('F') or scCtrl, Byte('G') or scCtrl, Byte('H') or scCtrl, Byte('I') or scCtrl, Byte('J') or scCtrl,
    Byte('K') or scCtrl, Byte('L') or scCtrl, Byte('M') or scCtrl, Byte('N') or scCtrl, Byte('O') or scCtrl,
    Byte('P') or scCtrl, Byte('Q') or scCtrl, Byte('R') or scCtrl, Byte('S') or scCtrl, Byte('T') or scCtrl,
    Byte('U') or scCtrl, Byte('V') or scCtrl, Byte('W') or scCtrl, Byte('X') or scCtrl, Byte('Y') or scCtrl,
    Byte('Z') or scCtrl,
    Byte('A') or scCtrl or scAlt, Byte('B') or scCtrl or scAlt, Byte('C') or scCtrl or scAlt,
    Byte('D') or scCtrl or scAlt, Byte('E') or scCtrl or scAlt, Byte('F') or scCtrl or scAlt,
    Byte('G') or scCtrl or scAlt, Byte('H') or scCtrl or scAlt, Byte('I') or scCtrl or scAlt,
    Byte('J') or scCtrl or scAlt, Byte('K') or scCtrl or scAlt, Byte('L') or scCtrl or scAlt,
    Byte('M') or scCtrl or scAlt, Byte('N') or scCtrl or scAlt, Byte('O') or scCtrl or scAlt,
    Byte('P') or scCtrl or scAlt, Byte('Q') or scCtrl or scAlt, Byte('R') or scCtrl or scAlt,
    Byte('S') or scCtrl or scAlt, Byte('T') or scCtrl or scAlt, Byte('U') or scCtrl or scAlt,
    Byte('V') or scCtrl or scAlt, Byte('W') or scCtrl or scAlt, Byte('X') or scCtrl or scAlt,
    Byte('Y') or scCtrl or scAlt, Byte('Z') or scCtrl or scAlt,
    vkF1, vkF2, vkF3, vkF4, vkF5, vkF6, vkF7, vkF8, vkF9, vkF10, vkF11, vkF12,
    vkF1 or scCtrl, vkF2 or scCtrl, vkF3 or scCtrl, vkF4 or scCtrl, vkF5 or scCtrl, vkF6 or scCtrl,
    vkF7 or scCtrl, vkF8 or scCtrl, vkF9 or scCtrl, vkF10 or scCtrl, vkF11 or scCtrl, vkF12 or scCtrl,
    vkF1 or scShift, vkF2 or scShift, vkF3 or scShift, vkF4 or scShift, vkF5 or scShift, vkF6 or scShift,
    vkF7 or scShift, vkF8 or scShift, vkF9 or scShift, vkF10 or scShift, vkF11 or scShift, vkF12 or scShift,
    vkF1 or scShift or scCtrl, vkF2 or scShift or scCtrl, vkF3 or scShift or scCtrl, vkF4 or scShift or scCtrl,
    vkF5 or scShift or scCtrl, vkF6 or scShift or scCtrl, vkF7 or scShift or scCtrl, vkF8 or scShift or scCtrl,
    vkF9 or scShift or scCtrl, vkF10 or scShift or scCtrl, vkF11 or scShift or scCtrl, vkF12 or scShift or scCtrl,
    scCtrl or vkReturn, scCtrl or vkSpace,
    vkInsert, vkInsert or scShift, vkInsert or scCtrl,
    vkDelete, vkDelete or scShift, vkDelete or scCtrl,
    vkBack or scAlt, vkBack or scShift or scAlt);

type
  TPropertyArray = array of PPropInfo;

function ShortCutAsText(const AShortCut: TShortCut): string;
var
  LMenuService: IFMXMenuService;
begin
  Result := '';

  if TPlatformServices.Current.SupportsPlatformService(IFMXMenuService, LMenuService) then
    Result := LMenuService.ShortCutToText(AShortCut);
end;

function IsBooleanIdent(const AValue: string): Boolean;
begin
  Result := (CompareText(AValue, BooleanIdents[True]) = 0) or (CompareText(AValue, BooleanIdents[False]) = 0);
end;

{ TMyInspectorItem }

function TMyInspectorItem.Inspector: TMyObjectInspector;
begin
  Result := TreeView as TMyObjectInspector;
end;

procedure TMyInspectorItem.AddPlaceholder;
begin
  FPlaceholder := TTreeViewItem.Create(Self);
  FPlaceholder.Parent := Self;
  FPlaceholder.Text := '';
end;

function TMyInspectorItem.ValueLeft: Single;
var
  LLevel: Integer;
  LItem: TTreeViewItem;
begin
  LLevel := 0;
  LItem := ParentItem;

  while Assigned(LItem) do
  begin
    Inc(LLevel);
    LItem := LItem.ParentItem;
  end;

  Result := Max(60, Inspector.NameColumnWidth - LLevel * LEVEL_INDENT);
end;

procedure TMyInspectorItem.BuildCells;
begin
  Text := '';
  Height := ITEM_HEIGHT;

  FGrip := TLayout.Create(Self);
  FGrip.Parent := Self;
  FGrip.SetBounds(ValueLeft - 6, 0, 8, ITEM_HEIGHT);
  FGrip.HitTest := True;
  FGrip.AutoCapture := True;
  FGrip.Cursor := crHSplit;
  FGrip.OnMouseDown := Inspector.GripMouseDown;
  FGrip.OnMouseMove := Inspector.GripMouseMove;
  FGrip.OnMouseUp := Inspector.GripMouseUp;

  FNameText := TText.Create(Self);
  FNameText.Parent := Self;
  FNameText.SetBounds(20, 0, ValueLeft - 22, ITEM_HEIGHT);
  FNameText.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akBottom];
  FNameText.TextSettings.HorzAlign := TTextAlign.Leading;
  FNameText.TextSettings.WordWrap := False;
  FNameText.TextSettings.Trimming := TTextTrimming.Character;
  FNameText.HitTest := False;
  FNameText.TextSettings.FontColor := Inspector.NameTextColor;
  FNameText.Text := PropertyName;

  if IsBooleanValue or IsSetValue then
  begin
    FCheckBox := TCheckBox.Create(Self);
    FCheckBox.Parent := Self;
    FCheckBox.SetBounds(ValueLeft, 1, 19, ITEM_HEIGHT - 2);
    FCheckBox.Text := '';
    FCheckBox.Enabled := not IsReadOnly;
    FCheckBox.OnChange := CheckBoxChange;

    Exit;
  end;

  if PropTypeInfo = System.TypeInfo(TAlphaColor) then
  begin
    FColorSwatch := TRectangle.Create(Self);
    FColorSwatch.Parent := Self;
    FColorSwatch.SetBounds(ValueLeft, 4, ITEM_HEIGHT - 8, ITEM_HEIGHT - 8);
    FColorSwatch.Stroke.Color := TAlphaColorRec.Black;
    FColorSwatch.HitTest := False;
  end;

  FValueText := TText.Create(Self);
  FValueText.Parent := Self;

  if Assigned(FColorSwatch) then
    FValueText.SetBounds(ValueLeft + ITEM_HEIGHT - 4, 0, Max(Width - ValueLeft - ITEM_HEIGHT, 40), ITEM_HEIGHT)
  else
    FValueText.SetBounds(ValueLeft, 0, Max(Width - ValueLeft - 4, 40), ITEM_HEIGHT);

  FValueText.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight, TAnchorKind.akBottom];
  FValueText.TextSettings.HorzAlign := TTextAlign.Leading;
  FValueText.TextSettings.WordWrap := False;
  FValueText.TextSettings.Trimming := TTextTrimming.Character;
  FValueText.HitTest := True;
  FValueText.OnClick := ValueTextClick;
end;

{ Repositions the cells after the name column width changed }
procedure TMyInspectorItem.Relayout;
begin
  if Assigned(FGrip) then
    FGrip.Position.X := ValueLeft - 6;

  if Assigned(FNameText) then
    FNameText.Width := ValueLeft - 22;

  if Assigned(FCheckBox) then
    FCheckBox.Position.X := ValueLeft;

  if Assigned(FColorSwatch) then
    FColorSwatch.Position.X := ValueLeft;

  if Assigned(FValueText) then
  begin
    if Assigned(FColorSwatch) then
      FValueText.SetBounds(ValueLeft + ITEM_HEIGHT - 4, 0, Max(Width - ValueLeft - ITEM_HEIGHT, 40), ITEM_HEIGHT)
    else
      FValueText.SetBounds(ValueLeft, 0, Max(Width - ValueLeft - 4, 40), ITEM_HEIGHT);
  end;
end;

procedure TMyInspectorItem.UpdateValueDisplay(const AParentObject: TObject);
var
  LDisplayValue: string;
begin
  Inspector.ValueSyncing := True;
  try
    if Assigned(FCheckBox) then
      FCheckBox.IsChecked := CompareText(PropertyValue, BooleanIdents[True]) = 0;
  finally
    Inspector.ValueSyncing := False;
  end;

  if Assigned(FColorSwatch) then
  try
    FColorSwatch.Fill.Color := StringToAlphaColor(PropertyValue);
  except
    FColorSwatch.Fill.Color := TAlphaColorRec.Null;
  end;

  if not Assigned(FValueText) then
    Exit;

  LDisplayValue := PropertyValue;

  if PropTypeInfo = System.TypeInfo(TShortCut) then
    LDisplayValue := ShortCutAsText(StrToIntDef(PropertyValue, 0));

  FValueText.Text := LDisplayValue;

  if IsReadOnly then
    FValueText.TextSettings.FontColor := Inspector.ReadOnlyTextColor
  else
    FValueText.TextSettings.FontColor := Inspector.ValueTextColor;

  if Assigned(AParentObject) and Assigned(PropertyInfo) and IsStoredProp(AParentObject, PropertyInfo) and
    not IsDefaultPropertyValue(AParentObject, PropertyInfo, nil) then
    FValueText.TextSettings.Font.Style := [TFontStyle.fsBold]
  else
    FValueText.TextSettings.Font.Style := [];
end;

procedure TMyInspectorItem.CheckBoxChange(Sender: TObject);
begin
  if Inspector.ValueSyncing then
    Exit;

  Inspector.SetValueAsString(Self, BooleanIdents[FCheckBox.IsChecked]);
end;

procedure TMyInspectorItem.ValueTextClick(Sender: TObject);
begin
  Select;
  Inspector.BeginEdit(Self);
end;

procedure TMyInspectorItem.SetIsExpanded(const Value: Boolean);
begin
  if Value and HasChildren and not ChildrenLoaded then
  begin
    ChildrenLoaded := True;

    Inspector.LoadChildren(Self);

    if Assigned(FPlaceholder) then
    begin
      FPlaceholder.Free;
      FPlaceholder := nil;
    end;
  end;

  inherited SetIsExpanded(Value);
end;

{ TMyObjectInspector }

constructor TMyObjectInspector.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FNameColumnWidth := 160;
  FNameTextColor := TAlphaColorRec.Black;
  FReadOnlyTextColor := TAlphaColorRec.Gray;
  FUnlistedProperties := TStringList.Create;
  FValueTextColor := TAlphaColorRec.Navy;

  ItemHeight := ITEM_HEIGHT;
end;

destructor TMyObjectInspector.Destroy;
begin
  FUnlistedProperties.Free;

  inherited;
end;

function TMyObjectInspector.UnlistedProperty(const APropertyName: string): Boolean;
begin
  Result := FUnlistedProperties.IndexOf(APropertyName) <> -1;
end;

procedure TMyObjectInspector.AddUnlistedProperties(const AProperties: TMyArrayOfString);
begin
  for var LIndex := 0 to Length(AProperties) - 1 do
    FUnlistedProperties.Add(AProperties[LIndex]);
end;

procedure TMyObjectInspector.SetInspectedObject(const AValue: TObject);
begin
  if AValue <> FInspectedObject then
  begin
    FInspectedObject := AValue;

    DoObjectChange;
  end;
end;

function TMyObjectInspector.ParentObjectOf(const AItem: TMyInspectorItem): TObject;
begin
  Result := if AItem.ParentItem is TMyInspectorItem then TMyInspectorItem(AItem.ParentItem).PropertyObject else FInspectedObject;
end;

procedure TMyObjectInspector.ForEachItem(const AProc: TProc<TMyInspectorItem>);

  procedure Walk(const AItem: TTreeViewItem);
  begin
    if AItem is TMyInspectorItem then
      AProc(TMyInspectorItem(AItem));

    for var LIndex := 0 to AItem.Count - 1 do
      Walk(AItem.Items[LIndex]);
  end;

begin
  for var LIndex := 0 to Count - 1 do
    Walk(Items[LIndex]);
end;

procedure TMyObjectInspector.SetNameColumnWidth(const AValue: Single);
begin
  if FNameColumnWidth <> AValue then
  begin
    FNameColumnWidth := AValue;

    ForEachItem(
      procedure(AItem: TMyInspectorItem)
      begin
        AItem.Relayout;
      end);
  end;
end;

procedure TMyObjectInspector.GripMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button <> TMouseButton.mbLeft then
    Exit;

  EndEdit(True);

  FDraggingColumn := True;
  FDragStartX := AbsoluteToLocal(TControl(Sender).LocalToAbsolute(PointF(X, Y))).X;
  FDragStartWidth := FNameColumnWidth;
end;

procedure TMyObjectInspector.GripMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  LX: Single;
begin
  if not FDraggingColumn then
    Exit;

  if not (ssLeft in Shift) then
  begin
    FDraggingColumn := False;
    Exit;
  end;

  LX := AbsoluteToLocal(TControl(Sender).LocalToAbsolute(PointF(X, Y))).X;

  NameColumnWidth := EnsureRange(FDragStartWidth + (LX - FDragStartX), 60, Width - 60);
end;

procedure TMyObjectInspector.GripMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FDraggingColumn := False;
end;

function TMyObjectInspector.CreatePropertyItem(const AParent: TTreeViewItem; const AObject: TObject;
  const APropertyInfo: PPropInfo): TMyInspectorItem;
begin
  if UnlistedProperty(string(APropertyInfo.Name)) then
    Exit(nil);

  Result := TMyInspectorItem.Create(Self);
  Result.PropertyInfo := APropertyInfo;
  Result.PropTypeInfo := APropertyInfo^.PropType^;
  Result.PropertyName := string(APropertyInfo.Name);
  Result.PropertyValue := PropertyValueAsString(AObject, APropertyInfo);
  Result.IsBooleanValue := (Result.PropTypeInfo.Kind = tkEnumeration) and IsBooleanIdent(Result.PropertyValue);
  Result.IsReadOnly := not Assigned(APropertyInfo.SetProc);

  if Result.PropTypeInfo.Kind = tkClass then
    Result.PropertyObject := GetObjectProp(AObject, APropertyInfo);

  Result.HasChildren := (Result.PropTypeInfo.Kind = tkSet) or
    ((Result.PropTypeInfo.Kind = tkClass) and (Result.PropTypeInfo.Name <> TYPE_BITMAP) and (Result.PropertyValue <> '') and
    not (Result.PropertyObject is TStrings));

  if Assigned(AParent) then
    Result.Parent := AParent
  else
    Result.Parent := Self;

  Result.BuildCells;
  Result.UpdateValueDisplay(AObject);

  if Result.HasChildren then
    Result.AddPlaceholder;
end;

procedure TMyObjectInspector.DoObjectChange;
var
  LPropertyCount: Integer;
  LPropertyArray: TPropertyArray;
begin
  EndEdit(False);

  if not Assigned(FInspectedObject) then
  begin
    Clear;
    Exit;
  end;

  LPropertyCount := GetPropList(FInspectedObject.ClassInfo, tkProperties, nil);
  SetLength(LPropertyArray, LPropertyCount);
  GetPropList(FInspectedObject.ClassInfo, tkProperties, PPropList(LPropertyArray));

  BeginUpdate;
  try
    Clear;

    for var LIndex := 0 to LPropertyCount - 1 do
    begin
      if (LPropertyArray[LIndex].PropType^.Kind = tkClass) and not Assigned(GetObjectProp(FInspectedObject, LPropertyArray[LIndex])) then
        Continue;

      CreatePropertyItem(nil, FInspectedObject, LPropertyArray[LIndex]);
    end;
  finally
    EndUpdate;
  end;
end;

procedure TMyObjectInspector.LoadChildren(const AItem: TMyInspectorItem);
var
  LObject: TObject;
  LCollection: TCollection;
  LItem: TMyInspectorItem;
  LPropertyCount: Integer;
  LPropertyArray: TPropertyArray;
  LSetTypeData: PTypeData;
  LSetAsIntValue: NativeInt;
  LParentObject: TObject;
begin
  LParentObject := ParentObjectOf(AItem);

  BeginUpdate;
  try
    if (AItem.PropTypeInfo.Kind = tkClass) and (AItem.PropertyValue <> '') then
    begin
      LObject := if LParentObject is TCollection then AItem.PropertyObject else GetObjectProp(LParentObject, AItem.PropertyInfo);

      if LObject is TCollection then
      begin
        LCollection := LObject as TCollection;

        for var LIndex := 0 to LCollection.Count - 1 do
        begin
          LItem := TMyInspectorItem.Create(Self);
          LItem.PropertyInfo := nil;
          LItem.PropertyName := 'Item[' + LIndex.ToString + ']';
          LItem.PropertyValue := '(' + LCollection.ItemClass.ClassName + ')';
          LItem.PropTypeInfo := LCollection.ItemClass.ClassInfo;
          LItem.HasChildren := True;
          LItem.PropertyObject := LCollection.Items[LIndex];
          LItem.IsReadOnly := True;
          LItem.Parent := AItem;
          LItem.BuildCells;
          LItem.UpdateValueDisplay(nil);
          LItem.AddPlaceholder;
        end;
      end
      else
      if Assigned(LObject) then
      begin
        LPropertyCount := GetPropList(LObject.ClassInfo, tkProperties, nil);
        SetLength(LPropertyArray, LPropertyCount);
        GetPropList(LObject.ClassInfo, tkProperties, PPropList(LPropertyArray));

        for var LIndex := 0 to LPropertyCount - 1 do
          CreatePropertyItem(AItem, LObject, LPropertyArray[LIndex]);
      end;
    end
    else
    if AItem.PropTypeInfo.Kind = tkSet then
    begin
      LSetTypeData := GetTypeData(GetTypeData(AItem.PropTypeInfo)^.CompType^);
      LSetAsIntValue := GetOrdProp(LParentObject, AItem.PropertyInfo);

      for var LIndex := LSetTypeData.MinValue to LSetTypeData.MaxValue do
      begin
        LItem := TMyInspectorItem.Create(Self);
        LItem.PropertyInfo := AItem.PropertyInfo;
        LItem.PropertyName := GetEnumName(GetTypeData(AItem.PropTypeInfo)^.CompType^, LIndex);
        LItem.PropertyValue := BooleanIdents[LIndex in TIntegerSet(Integer(LSetAsIntValue))];
        LItem.PropTypeInfo := nil;
        LItem.IsBooleanValue := True;
        LItem.IsSetValue := True;
        LItem.SetIndex := LIndex;
        LItem.Parent := AItem;
        LItem.BuildCells;
        LItem.UpdateValueDisplay(nil);
      end;
    end;
  finally
    EndUpdate;
  end;
end;

function TMyObjectInspector.PropertyValueAsString(AObject: TObject; APropertyInfo: PPropInfo): string;
var
  LPropertyType: PTypeInfo;
  LTypeKind: TTypeKind;

  function SetAsString(const AValue: Integer): string;
  begin
    var LBaseType: PTypeInfo := GetTypeData(LPropertyType)^.CompType^;

    Result := '';

    for var LIndex := 0 to SizeOf(TIntegerSet) * 8 - 1 do
    if LIndex in TIntegerSet(AValue) then
    begin
      if not Result.IsEmpty then
        Result := Result + ',';

      Result := Result + GetEnumName(LBaseType, LIndex);
    end;

    Result := '[' + Result + ']';
  end;

  function IntegerAsString(const ATypeInfo: PTypeInfo; const AValue: Integer): string;
  begin
    var LIntToIdent: TIntToIdent := FindIntToIdent(ATypeInfo);
    var LIdent: string;

    Result := if Assigned(LIntToIdent) and LIntToIdent(AValue, LIdent) then LIdent else IntToStr(AValue);
  end;

  function OrdAsString: string;
  begin
    var LValue: NativeInt := GetOrdProp(AObject, APropertyInfo);

    case LTypeKind of
      tkInteger:
        if LPropertyType = System.TypeInfo(TAlphaColor) then
          Result := AlphaColorToString(LValue)
        else
          Result := IntegerAsString(LPropertyType, LValue);
      tkChar:
        Result := Chr(LValue);
      tkSet:
        Result := SetAsString(LValue);
      tkEnumeration:
        Result := GetEnumName(LPropertyType, LValue);
    end;
  end;

  function FloatAsString: string;
  begin
    var LValue: Extended := GetFloatProp(AObject, APropertyInfo);

    Result := FloatToStr(LValue);
  end;

  function StrAsString: string;
  begin
    Result := GetWideStrProp(AObject, APropertyInfo);
  end;

  function ObjectAsString: string;
  begin
    var LValue: TObject := GetObjectProp(AObject, APropertyInfo);

    Result := if Assigned(LValue) then '(' + LValue.ClassName + ')' else '';
  end;

begin
  Result := '';

  LPropertyType := APropertyInfo^.PropType^;
  LTypeKind := LPropertyType^.Kind;

  case LTypeKind of
    tkInteger, tkChar, tkEnumeration, tkSet:
      Result := OrdAsString;
    tkFloat:
      Result := FloatAsString;
    tkString, tkLString, tkWString, tkUString:
      Result := StrAsString;
    tkClass:
      Result := ObjectAsString;
  end;
end;

procedure TMyObjectInspector.SetValueAsString(const AItem: TMyInspectorItem; const AValue: string);
var
  LIntegerSet: TIntegerSet;
  LParentItem: TMyInspectorItem;
  LParentObject: TObject;
  LIdentToInt: TIdentToInt;
  LOrdValue: Integer;
begin
  LParentItem := if AItem.ParentItem is TMyInspectorItem then TMyInspectorItem(AItem.ParentItem) else nil;
  LParentObject := ParentObjectOf(AItem);

  if AItem.IsSetValue then
  begin
    Integer(LIntegerSet) := StringToSet(LParentItem.PropertyInfo, LParentItem.PropertyValue);

    if CompareText(AValue, BooleanIdents[True]) = 0 then
      Include(LIntegerSet, AItem.SetIndex)
    else
      Exclude(LIntegerSet, AItem.SetIndex);

    AItem.PropertyValue := AValue;

    SetValueAsString(LParentItem, SetToString(LParentItem.PropertyInfo, Integer(LIntegerSet)));

    Exit;
  end;

  if AItem.PropTypeInfo = System.TypeInfo(TAlphaColor) then
    SetOrdProp(LParentObject, AItem.PropertyInfo, StringToAlphaColor(AValue))
  else
  if AItem.PropTypeInfo = System.TypeInfo(TShortCut) then
    SetPropValue(LParentObject, AItem.PropertyName, TextToShortCut(AValue))
  else
  if AItem.PropTypeInfo.Kind = tkInteger then
  begin
    LIdentToInt := FindIdentToInt(AItem.PropTypeInfo);

    if Assigned(LIdentToInt) and LIdentToInt(AValue, LOrdValue) then
      SetOrdProp(LParentObject, AItem.PropertyInfo, LOrdValue)
    else
      SetPropValue(LParentObject, AItem.PropertyName, StrToIntDef(AValue, 0));
  end
  else
  if AItem.PropTypeInfo.Kind = tkFloat then
    SetPropValue(LParentObject, AItem.PropertyName, StrToFloat(AValue))
  else
    SetPropValue(LParentObject, AItem.PropertyName, AValue);

  if Assigned(LParentObject) and Assigned(AItem.PropertyInfo) then
    AItem.PropertyValue := PropertyValueAsString(LParentObject, AItem.PropertyInfo)
  else
    AItem.PropertyValue := AValue;

  AItem.UpdateValueDisplay(LParentObject);
end;

{ Inline editors }

procedure TMyObjectInspector.BeginEdit(const AItem: TMyInspectorItem);
var
  LEdit: TEdit;
  LComboBox: TComboBox;
  LColorComboBox: TComboColorBox;
  LTypeData: PTypeData;
  LValueLeft: Single;
begin
  EndEdit(True);

  if AItem.IsReadOnly or AItem.IsBooleanValue or AItem.IsSetValue or not Assigned(AItem.PropTypeInfo) then
    Exit;

  if AItem.PropTypeInfo.Name = TYPE_FILENAME then
  begin
    EditFileNameProperty(AItem);
    Exit;
  end;

  if (AItem.PropTypeInfo.Kind = tkClass) and (AItem.PropertyObject is TStrings) then
  begin
    EditStringsProperty(AItem);
    Exit;
  end;

  if (AItem.PropTypeInfo.Kind in [tkClass, tkSet]) then
    Exit;

  FEditItem := AItem;
  LValueLeft := AItem.ValueLeft;

  if AItem.PropTypeInfo = System.TypeInfo(TAlphaColor) then
  begin
    LColorComboBox := TComboColorBox.Create(Self);
    FEditor := LColorComboBox;
    LColorComboBox.Parent := AItem;
    LColorComboBox.SetBounds(LValueLeft, 0, Max(AItem.Width - LValueLeft - 4, 60), ITEM_HEIGHT);
    LColorComboBox.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];
    LColorComboBox.Color := StringToAlphaColor(AItem.PropertyValue);
    LColorComboBox.OnChange := ColorComboChange;
    LColorComboBox.OnExit := EditorExit;
    LColorComboBox.SetFocus;
  end
  else
  if (AItem.PropTypeInfo.Kind = tkEnumeration) or (AItem.PropTypeInfo = System.TypeInfo(TShortCut)) then
  begin
    LComboBox := TComboBox.Create(Self);
    FEditor := LComboBox;
    LComboBox.Parent := AItem;
    LComboBox.SetBounds(LValueLeft, 0, Max(AItem.Width - LValueLeft - 4, 60), ITEM_HEIGHT);
    LComboBox.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];

    LComboBox.Items.BeginUpdate;

    if AItem.PropTypeInfo = System.TypeInfo(TShortCut) then
    begin
      for var LIndex := 1 to High(ShortCuts) do
        LComboBox.Items.Add(ShortCutAsText(ShortCuts[LIndex]));

      LComboBox.ItemIndex := LComboBox.Items.IndexOf(ShortCutAsText(StrToIntDef(AItem.PropertyValue, 0)));
    end
    else
    begin
      LTypeData := GetTypeData(AItem.PropTypeInfo);

      for var LIndex := LTypeData.MinValue to LTypeData.MaxValue do
        LComboBox.Items.Add(GetEnumName(AItem.PropTypeInfo, LIndex));

      LComboBox.ItemIndex := LComboBox.Items.IndexOf(AItem.PropertyValue);
    end;

    LComboBox.Items.EndUpdate;
    LComboBox.OnChange := ComboChange;
    LComboBox.OnExit := EditorExit;
    LComboBox.SetFocus;
    LComboBox.DropDown;
  end
  else
  begin
    LEdit := TEdit.Create(Self);
    FEditor := LEdit;
    LEdit.Parent := AItem;
    LEdit.SetBounds(LValueLeft, 0, Max(AItem.Width - LValueLeft - 4, 60), ITEM_HEIGHT);
    LEdit.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];
    LEdit.Text := AItem.PropertyValue;
    LEdit.OnKeyDown := EditorKeyDown;
    LEdit.OnExit := EditorExit;
    LEdit.SetFocus;
    LEdit.SelectAll;
  end;
end;

procedure TMyObjectInspector.EditFileNameProperty(const AItem: TMyInspectorItem);
var
  LDialog: TOpenDialog;
begin
  if AItem.PropertyName.Contains('Save') then
    LDialog := TSaveDialog.Create(Self)
  else
    LDialog := TOpenDialog.Create(Self);

  try
    LDialog.Filter := 'JSON files (*.json)|*.json|All files (*.*)|*.*';

    if LDialog.Execute then
      SetValueAsString(AItem, LDialog.FileName);
  finally
    LDialog.Free;
  end;
end;

procedure TMyObjectInspector.EditStringsProperty(const AItem: TMyInspectorItem);
var
  LForm: TForm;
  LMemo: TMemo;
  LLayout: TLayout;
  LButton: TButton;
  LParentObject: TObject;
  LStrings: TStringList;
begin
  LForm := TForm.CreateNew(Self);
  try
    LForm.Caption := AItem.PropertyName;
    LForm.Position := TFormPosition.ScreenCenter;
    LForm.ClientWidth := 560;
    LForm.ClientHeight := 480;

    LLayout := TLayout.Create(LForm);
    LLayout.Parent := LForm;
    LLayout.Align := TAlignLayout.Bottom;
    LLayout.Height := 44;

    LButton := TButton.Create(LForm);
    LButton.Parent := LLayout;
    LButton.SetBounds(LForm.ClientWidth - 172, 10, 80, 24);
    LButton.Anchors := [TAnchorKind.akRight, TAnchorKind.akTop];
    LButton.Text := 'OK';
    LButton.Default := True;
    LButton.ModalResult := mrOk;

    LButton := TButton.Create(LForm);
    LButton.Parent := LLayout;
    LButton.SetBounds(LForm.ClientWidth - 88, 10, 80, 24);
    LButton.Anchors := [TAnchorKind.akRight, TAnchorKind.akTop];
    LButton.Text := 'Cancel';
    LButton.Cancel := True;
    LButton.ModalResult := mrCancel;

    LMemo := TMemo.Create(LForm);
    LMemo.Parent := LForm;
    LMemo.Align := TAlignLayout.Client;
    LMemo.Margins.Rect := TRectF.Create(8, 8, 8, 0);
    LMemo.Lines.Assign(TStrings(AItem.PropertyObject));

    if LForm.ShowModal = mrOk then
    begin
      LParentObject := ParentObjectOf(AItem);

      if Assigned(AItem.PropertyInfo) and Assigned(AItem.PropertyInfo.SetProc) then
      begin
        LStrings := TStringList.Create;
        try
          LStrings.Assign(LMemo.Lines);

          SetObjectProp(LParentObject, AItem.PropertyInfo, LStrings);
        finally
          LStrings.Free;
        end;
      end
      else
        TStrings(AItem.PropertyObject).Assign(LMemo.Lines);
    end;
  finally
    LForm.Free;
  end;
end;

procedure TMyObjectInspector.EndEdit(const AApply: Boolean);
var
  LValue: string;
  LApply: Boolean;
begin
  if not Assigned(FEditor) then
    Exit;

  LApply := AApply and Assigned(FEditItem);

  if LApply then
  begin
    LValue := '';

    if FEditor is TEdit then
      LValue := TEdit(FEditor).Text
    else
    if FEditor is TComboBox then
    begin
      if TComboBox(FEditor).ItemIndex >= 0 then
      begin
        if FEditItem.PropTypeInfo = System.TypeInfo(TShortCut) then
          LValue := IntToStr(ShortCuts[TComboBox(FEditor).ItemIndex + 1])
        else
          LValue := TComboBox(FEditor).Items[TComboBox(FEditor).ItemIndex];
      end
      else
        LApply := False;
    end
    else
    if FEditor is TComboColorBox then
      LValue := AlphaColorToString(TComboColorBox(FEditor).Color);

    if LApply then
    try
      if FEditItem.PropTypeInfo = System.TypeInfo(TShortCut) then
        SetValueAsString(FEditItem, ShortCutAsText(StrToIntDef(LValue, 0)))
      else
        SetValueAsString(FEditItem, LValue);
    except
      { Ignore }
    end;
  end;

  ReleaseEditor;
end;

procedure TMyObjectInspector.ReleaseEditor;
var
  LEditor: TControl;
begin
  LEditor := FEditor;
  FEditor := nil;
  FEditItem := nil;

  if Assigned(LEditor) then
  begin
    LEditor.Visible := False;
    LEditor.Parent := nil;

    TThread.ForceQueue(nil,
      procedure
      begin
        LEditor.Free;
      end);
  end;
end;

procedure TMyObjectInspector.EditorKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  case Key of
    vkReturn:
      begin
        Key := 0;
        EndEdit(True);
      end;
    vkEscape:
      begin
        Key := 0;
        EndEdit(False);
      end;
  end;
end;

procedure TMyObjectInspector.EditorExit(Sender: TObject);
begin
  EndEdit(True);
end;

procedure TMyObjectInspector.ComboChange(Sender: TObject);
begin
  EndEdit(True);
end;

procedure TMyObjectInspector.ColorComboChange(Sender: TObject);
begin
  if Assigned(FEditItem) and Assigned(FEditor) then
    SetValueAsString(FEditItem, AlphaColorToString(TComboColorBox(FEditor).Color));
end;

end.
