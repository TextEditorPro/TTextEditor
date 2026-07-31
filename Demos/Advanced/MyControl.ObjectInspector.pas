unit MyControl.ObjectInspector;

interface

uses
  Winapi.Messages, Winapi.Windows, System.Classes, System.Types, System.TypInfo, System.UITypes, Vcl.ComCtrls, Vcl.Controls, Vcl.Graphics,
  Vcl.StdCtrls;

type
  TMyArrayOfString = array of string;

  TMyObjectInspector = class;

  TMyInspectorNode = class(TTreeNode)
  public
    ChildrenLoaded: Boolean;
    IsBooleanValue: Boolean;
    IsReadOnly: Boolean;
    IsSetValue: Boolean;
    PropTypeInfo: PTypeInfo;
    PropertyInfo: PPropInfo;
    PropertyName: string;
    PropertyObject: TObject;
    PropertyValue: string;
    SetIndex: Integer;
  end;

  TMyObjectInspector = class(TTreeView)
  strict private
    FDraggingColumn: Boolean;
    FEditNode: TMyInspectorNode;
    FEditor: TWinControl;
    FInspectedObject: TObject;
    FNameColumnWidth: Integer;
    FUnlistedProperties: TStrings;
    function CreateChildNode(const AParent: TTreeNode; const AName: string): TMyInspectorNode;
    function FitNodeText(const AName: string; const ALevel: Integer): string;
    function OnColumnSeparator(const X: Integer): Boolean;
    function ParentObjectOf(const ANode: TMyInspectorNode): TObject;
    function PropertyValueAsString(AObject: TObject; APropertyInfo: PPropInfo): string;
    function UnlistedProperty(const APropertyName: string): Boolean;
    function ValueDisplayText(const ANode: TMyInspectorNode): string;
    procedure ColorBoxSelect(Sender: TObject);
    procedure ComboChange(Sender: TObject);
    procedure DoAdvancedDrawItem(Sender: TCustomTreeView; Node: TTreeNode; State: TCustomDrawState; Stage: TCustomDrawStage; var PaintImages, DefaultDraw: Boolean);
    procedure DoObjectChange;
    procedure EditFileNameProperty(const ANode: TMyInspectorNode);
    procedure EditStringsProperty(const ANode: TMyInspectorNode);
    procedure EditorExit(Sender: TObject);
    procedure EditorKeyPress(Sender: TObject; var Key: Char);
    procedure LoadChildren(const ANode: TMyInspectorNode);
    procedure ReleaseEditor;
    procedure SetInspectedObject(const AValue: TObject);
    procedure SetNameColumnWidth(const AValue: Integer);
    procedure UpdateNodeTexts;
    procedure WMHScroll(var AMessage: TWMHScroll); message WM_HSCROLL;
    procedure WMMouseWheel(var AMessage: TWMMouseWheel); message WM_MOUSEWHEEL;
    procedure WMSize(var AMessage: TWMSize); message WM_SIZE;
    procedure WMVScroll(var AMessage: TWMVScroll); message WM_VSCROLL;
  protected
    function CanExpand(Node: TTreeNode): Boolean; override;
    function CreateNode: TTreeNode; override;
    procedure Collapse(Node: TTreeNode); override;
    procedure CreateWnd; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AddUnlistedProperties(const AProperties: TMyArrayOfString);
    procedure BeginEdit(const ANode: TMyInspectorNode);
    procedure EndEdit(const AApply: Boolean);
    procedure SetValueAsString(const ANode: TMyInspectorNode; const AValue: string);
    property InspectedObject: TObject read FInspectedObject write SetInspectedObject;
    property NameColumnWidth: Integer read FNameColumnWidth write SetNameColumnWidth;
  end;

implementation

uses
  Winapi.CommCtrl, Winapi.UxTheme, System.Math, System.SysUtils, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms, Vcl.Menus, Vcl.Themes;

const
  TYPE_BITMAP = 'TBitmap';
  TYPE_FILENAME = 'TFileName';
  ITEM_HEIGHT = 22;

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

function IsBooleanIdent(const AValue: string): Boolean;
begin
  Result := (CompareText(AValue, BooleanIdents[True]) = 0) or (CompareText(AValue, BooleanIdents[False]) = 0);
end;

{ TMyObjectInspector }

constructor TMyObjectInspector.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FNameColumnWidth := 160;
  FUnlistedProperties := TStringList.Create;

  DoubleBuffered := True;
  HideSelection := False;
  ReadOnly := True;
  RowSelect := True;
  ShowLines := False;
  ShowRoot := True;

  OnAdvancedCustomDrawItem := DoAdvancedDrawItem;
end;

destructor TMyObjectInspector.Destroy;
begin
  FUnlistedProperties.Free;

  inherited;
end;

procedure TMyObjectInspector.CreateWnd;
begin
  inherited;

  SendMessage(Handle, TVM_SETITEMHEIGHT, ITEM_HEIGHT, 0);
end;

function TMyObjectInspector.CreateNode: TTreeNode;
begin
  Result := TMyInspectorNode.Create(Items);
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

function TMyObjectInspector.ParentObjectOf(const ANode: TMyInspectorNode): TObject;
begin
  Result := if ANode.Parent is TMyInspectorNode then TMyInspectorNode(ANode.Parent).PropertyObject else FInspectedObject;
end;

function TMyObjectInspector.FitNodeText(const AName: string; const ALevel: Integer): string;
var
  LAvailable: Integer;
begin
  Result := AName;

  if not HandleAllocated then
    Exit;

  Canvas.Font := Font;

  LAvailable := FNameColumnWidth - 10 - (ALevel + 1) * Indent;

  if Canvas.TextWidth(Result) <= LAvailable then
    Exit;

  while (Result.Length > 1) and (Canvas.TextWidth(Result + '...') > LAvailable) do
    SetLength(Result, Result.Length - 1);

  Result := Result + '...';
end;

procedure TMyObjectInspector.UpdateNodeTexts;
begin
  Items.BeginUpdate;
  try
    for var LIndex := 0 to Items.Count - 1 do
    if Items[LIndex] is TMyInspectorNode then
      Items[LIndex].Text := FitNodeText(TMyInspectorNode(Items[LIndex]).PropertyName, Items[LIndex].Level);
  finally
    Items.EndUpdate;
  end;
end;

procedure TMyObjectInspector.SetNameColumnWidth(const AValue: Integer);
begin
  if FNameColumnWidth <> AValue then
  begin
    FNameColumnWidth := AValue;

    UpdateNodeTexts;
    Invalidate;
  end;
end;

function TMyObjectInspector.CreateChildNode(const AParent: TTreeNode; const AName: string): TMyInspectorNode;
begin
  var LLevel := if Assigned(AParent) then AParent.Level + 1 else 0;

  Result := Items.AddChild(AParent, FitNodeText(AName, LLevel)) as TMyInspectorNode;
  Result.PropertyName := AName;
end;

procedure TMyObjectInspector.DoObjectChange;
var
  LPropertyCount: Integer;
  LPropertyArray: TPropertyArray;
  LNode: TMyInspectorNode;
begin
  EndEdit(False);

  Items.BeginUpdate;
  try
    Items.Clear;

    if not Assigned(FInspectedObject) then
      Exit;

    LPropertyCount := GetPropList(FInspectedObject.ClassInfo, tkProperties, nil);
    SetLength(LPropertyArray, LPropertyCount);
    GetPropList(FInspectedObject.ClassInfo, tkProperties, PPropList(LPropertyArray));

    for var LIndex := 0 to LPropertyCount - 1 do
    begin
      if UnlistedProperty(string(LPropertyArray[LIndex].Name)) then
        Continue;

      if (LPropertyArray[LIndex].PropType^.Kind = tkClass) and not Assigned(GetObjectProp(FInspectedObject, LPropertyArray[LIndex])) then
        Continue;

      LNode := CreateChildNode(nil, string(LPropertyArray[LIndex].Name));
      LNode.PropertyInfo := LPropertyArray[LIndex];
      LNode.PropTypeInfo := LNode.PropertyInfo^.PropType^;
      LNode.PropertyValue := PropertyValueAsString(FInspectedObject, LNode.PropertyInfo);
      LNode.IsBooleanValue := (LNode.PropTypeInfo.Kind = tkEnumeration) and IsBooleanIdent(LNode.PropertyValue);
      LNode.IsReadOnly := not Assigned(LNode.PropertyInfo.SetProc);

      if LNode.PropTypeInfo.Kind = tkClass then
        LNode.PropertyObject := GetObjectProp(FInspectedObject, LNode.PropertyInfo);

      LNode.HasChildren := (LNode.PropTypeInfo.Kind = tkSet) or
        ((LNode.PropTypeInfo.Kind = tkClass) and (LNode.PropTypeInfo.Name <> TYPE_BITMAP) and (LNode.PropertyValue <> '') and
        not (LNode.PropertyObject is TStrings));
    end;
  finally
    Items.EndUpdate;
  end;
end;

function TMyObjectInspector.CanExpand(Node: TTreeNode): Boolean;
var
  LNode: TMyInspectorNode;
begin
  Result := inherited CanExpand(Node);

  if Result and (Node is TMyInspectorNode) then
  begin
    LNode := TMyInspectorNode(Node);

    if not LNode.ChildrenLoaded then
    begin
      LNode.ChildrenLoaded := True;

      LoadChildren(LNode);

      if Node.Count = 0 then
      begin
        Node.HasChildren := False;
        Result := False;
      end;
    end;
  end;
end;

procedure TMyObjectInspector.Collapse(Node: TTreeNode);
begin
  EndEdit(True);

  inherited;
end;

procedure TMyObjectInspector.LoadChildren(const ANode: TMyInspectorNode);
var
  LObject: TObject;
  LCollection: TCollection;
  LNode: TMyInspectorNode;
  LPropertyCount: Integer;
  LPropertyArray: TPropertyArray;
  LSetTypeData: PTypeData;
  LSetAsIntValue: NativeInt;
  LParentObject: TObject;
begin
  LParentObject := ParentObjectOf(ANode);

  Items.BeginUpdate;
  try
    if (ANode.PropTypeInfo.Kind = tkClass) and (ANode.PropertyValue <> '') then
    begin
      LObject := if LParentObject is TCollection then ANode.PropertyObject else GetObjectProp(LParentObject, ANode.PropertyInfo);

      if LObject is TCollection then
      begin
        LCollection := LObject as TCollection;

        for var LIndex := 0 to LCollection.Count - 1 do
        begin
          LNode := CreateChildNode(ANode, 'Item[' + LIndex.ToString + ']');
          LNode.PropertyInfo := nil;
          LNode.PropertyValue := '(' + LCollection.ItemClass.ClassName + ')';
          LNode.PropTypeInfo := LCollection.ItemClass.ClassInfo;
          LNode.PropertyObject := LCollection.Items[LIndex];
          LNode.IsReadOnly := True;
          LNode.HasChildren := True;
        end;
      end
      else
      if Assigned(LObject) then
      begin
        LPropertyCount := GetPropList(LObject.ClassInfo, tkProperties, nil);
        SetLength(LPropertyArray, LPropertyCount);
        GetPropList(LObject.ClassInfo, tkProperties, PPropList(LPropertyArray));

        for var LIndex := 0 to LPropertyCount - 1 do
        begin
          if UnlistedProperty(string(LPropertyArray[LIndex].Name)) then
            Continue;

          LNode := CreateChildNode(ANode, string(LPropertyArray[LIndex].Name));
          LNode.PropertyInfo := LPropertyArray[LIndex];
          LNode.PropTypeInfo := LNode.PropertyInfo^.PropType^;
          LNode.PropertyValue := PropertyValueAsString(LObject, LNode.PropertyInfo);
          LNode.IsBooleanValue := (LNode.PropTypeInfo.Kind = tkEnumeration) and IsBooleanIdent(LNode.PropertyValue);
          LNode.IsReadOnly := not Assigned(LNode.PropertyInfo.SetProc);

          if LNode.PropTypeInfo.Kind = tkClass then
            LNode.PropertyObject := GetObjectProp(LObject, LNode.PropertyInfo);

          LNode.HasChildren := (LNode.PropTypeInfo.Kind = tkSet) or
            ((LNode.PropTypeInfo.Kind = tkClass) and (LNode.PropTypeInfo.Name <> TYPE_BITMAP) and (LNode.PropertyValue <> '') and
            not (LNode.PropertyObject is TStrings));
        end;
      end;
    end
    else
    if ANode.PropTypeInfo.Kind = tkSet then
    begin
      LSetTypeData := GetTypeData(GetTypeData(ANode.PropTypeInfo)^.CompType^);
      LSetAsIntValue := GetOrdProp(LParentObject, ANode.PropertyInfo);

      for var LIndex := LSetTypeData.MinValue to LSetTypeData.MaxValue do
      begin
        LNode := CreateChildNode(ANode, GetEnumName(GetTypeData(ANode.PropTypeInfo)^.CompType^, LIndex));
        LNode.PropertyInfo := ANode.PropertyInfo;
        LNode.PropertyValue := BooleanIdents[LIndex in TIntegerSet(LSetAsIntValue)];
        LNode.PropTypeInfo := nil;
        LNode.IsBooleanValue := True;
        LNode.IsSetValue := True;
        LNode.SetIndex := LIndex;
      end;
    end;
  finally
    Items.EndUpdate;
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

procedure TMyObjectInspector.SetValueAsString(const ANode: TMyInspectorNode; const AValue: string);
var
  LIntegerSet: TIntegerSet;
  LParentNode: TMyInspectorNode;
  LParentObject: TObject;
  LIdentToInt: TIdentToInt;
  LOrdValue: Integer;
begin
  LParentNode := if ANode.Parent is TMyInspectorNode then TMyInspectorNode(ANode.Parent) else nil;
  LParentObject := ParentObjectOf(ANode);

  if ANode.IsSetValue then
  begin
    Integer(LIntegerSet) := StringToSet(LParentNode.PropertyInfo, LParentNode.PropertyValue);

    if CompareText(AValue, BooleanIdents[True]) = 0 then
      Include(LIntegerSet, ANode.SetIndex)
    else
      Exclude(LIntegerSet, ANode.SetIndex);

    ANode.PropertyValue := AValue;

    SetValueAsString(LParentNode, SetToString(LParentNode.PropertyInfo, Integer(LIntegerSet)));

    Invalidate;
    Exit;
  end;

  if ANode.PropTypeInfo = System.TypeInfo(TColor) then
    SetPropValue(LParentObject, ANode.PropertyName, StringToColor(AValue))
  else
  if ANode.PropTypeInfo = System.TypeInfo(TShortCut) then
    SetPropValue(LParentObject, ANode.PropertyName, TextToShortCut(AValue))
  else
  if ANode.PropTypeInfo.Kind = tkInteger then
  begin
    LIdentToInt := FindIdentToInt(ANode.PropTypeInfo);

    if Assigned(LIdentToInt) and LIdentToInt(AValue, LOrdValue) then
      SetOrdProp(LParentObject, ANode.PropertyInfo, LOrdValue)
    else
      SetPropValue(LParentObject, ANode.PropertyName, StrToIntDef(AValue, 0));
  end
  else
  if ANode.PropTypeInfo.Kind = tkFloat then
    SetPropValue(LParentObject, ANode.PropertyName, StrToFloat(AValue))
  else
    SetPropValue(LParentObject, ANode.PropertyName, AValue);

  if Assigned(LParentObject) and Assigned(ANode.PropertyInfo) then
    ANode.PropertyValue := PropertyValueAsString(LParentObject, ANode.PropertyInfo)
  else
    ANode.PropertyValue := AValue;

  Invalidate;
end;

function TMyObjectInspector.ValueDisplayText(const ANode: TMyInspectorNode): string;
var
  LColor: Integer;
begin
  Result := ANode.PropertyValue;

  if ANode.PropTypeInfo = System.TypeInfo(TShortCut) then
    Result := ShortCutToText(StrToIntDef(ANode.PropertyValue, 0))
  else
  if (ANode.PropTypeInfo = System.TypeInfo(TColor)) and not IdentToColor(ANode.PropertyValue, LColor) then
    Result := ColorToString(StrToIntDef(ANode.PropertyValue, 0));
end;

procedure TMyObjectInspector.DoAdvancedDrawItem(Sender: TCustomTreeView; Node: TTreeNode; State: TCustomDrawState;
  Stage: TCustomDrawStage; var PaintImages, DefaultDraw: Boolean);
var
  LNode: TMyInspectorNode;
  LRect, LBoxRect: TRect;
  LSize: TSize;
  LHandle: THandle;
  LParentObject: TObject;
  LText: string;

  function BackgroundColorIsLight: Boolean;
  begin
    var LRGB := ColorToRGB(if TStyleManager.IsCustomStyleActive then StyleServices.GetStyleColor(scTreeView) else Color);

    Result := ((LRGB and $FF) + (LRGB shr 8 and $FF) + (LRGB shr 16 and $FF)) >= $180;
  end;

begin
  DefaultDraw := True;

  if (Stage <> cdPostPaint) or not (Node is TMyInspectorNode) then
    Exit;

  LNode := TMyInspectorNode(Node);
  LRect := Node.DisplayRect(False);
  LRect.Left := FNameColumnWidth;
  InflateRect(LRect, -2, 0);

  Canvas.Pen.Color := if TStyleManager.IsCustomStyleActive then StyleServices.GetStyleColor(scBorder) else clBtnFace;
  Canvas.MoveTo(FNameColumnWidth - 4, LRect.Top);
  Canvas.LineTo(FNameColumnWidth - 4, LRect.Bottom);

  if LNode.IsBooleanValue or LNode.IsSetValue then
  begin
    LBoxRect := LRect;

    if StyleServices.Enabled then
    begin
      LHandle := OpenThemeData(Handle, 'BUTTON');

      if LHandle <> 0 then
      try
        GetThemePartSize(LHandle, Canvas.Handle, BP_CHECKBOX, CBS_CHECKEDNORMAL, nil, TS_DRAW, LSize);
        LBoxRect.Top := LBoxRect.Top + (LBoxRect.Height - LSize.cy) div 2;
        LBoxRect.Right := LBoxRect.Left + LSize.cx;
        LBoxRect.Bottom := LBoxRect.Top + LSize.cy;

        DrawThemeBackground(LHandle, Canvas.Handle, BP_CHECKBOX,
          IfThen(CompareText(LNode.PropertyValue, BooleanIdents[True]) = 0, CBS_CHECKEDNORMAL, CBS_UNCHECKEDNORMAL), LBoxRect, nil);
      finally
        CloseThemeData(LHandle);
      end;
    end
    else
    begin
      LBoxRect.Right := LBoxRect.Left + GetSystemMetrics(SM_CXMENUCHECK);

      DrawFrameControl(Canvas.Handle, LBoxRect, DFC_BUTTON,
        IfThen(CompareText(LNode.PropertyValue, BooleanIdents[True]) = 0, DFCS_CHECKED, DFCS_BUTTONCHECK));
    end;

    Exit;
  end;

  if LNode.PropTypeInfo = System.TypeInfo(TColor) then
  begin
    LBoxRect := LRect;
    Inc(LBoxRect.Top, 3);
    Dec(LBoxRect.Bottom, 3);
    LBoxRect.Right := LBoxRect.Left + LBoxRect.Height;

    Canvas.Brush.Color := StringToColor(LNode.PropertyValue);
    Canvas.FillRect(LBoxRect);
    Canvas.Brush.Color := clBlack;
    Canvas.FrameRect(LBoxRect);

    LRect.Left := LBoxRect.Right + 4;
  end;

  LText := ValueDisplayText(LNode);

  if LText.IsEmpty then
    Exit;

  Canvas.Font := Font;
  Canvas.Font.Style := [];

  if (cdsSelected in State) and not StyleServices.Enabled then
    Canvas.Font.Color := clHighlightText
  else
  if LNode.IsReadOnly then
    Canvas.Font.Color := clGrayText
  else
  if BackgroundColorIsLight then
    Canvas.Font.Color := TColors.Navy
  else
    Canvas.Font.Color := TColor($00FFB466);

  LParentObject := ParentObjectOf(LNode);

  if Assigned(LParentObject) and Assigned(LNode.PropertyInfo) and IsStoredProp(LParentObject, LNode.PropertyInfo) and
    not IsDefaultPropertyValue(LParentObject, LNode.PropertyInfo, nil) then
    Canvas.Font.Style := [fsBold];

  Canvas.Brush.Style := bsClear;
  SetBkMode(Canvas.Handle, TRANSPARENT);

  DrawTextW(Canvas.Handle, PWideChar(LText), Length(LText), LRect, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
end;

function TMyObjectInspector.OnColumnSeparator(const X: Integer): Boolean;
begin
  Result := Abs(X - (FNameColumnWidth - 4)) <= 3;
end;

procedure TMyObjectInspector.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if FDraggingColumn then
  begin
    if not (ssLeft in Shift) then
      FDraggingColumn := False
    else
      NameColumnWidth := EnsureRange(X + 4, 60, ClientWidth - 60);

    Exit;
  end;

  Cursor := if OnColumnSeparator(X) then crHSplit else crDefault;

  inherited MouseMove(Shift, X, Y);
end;

procedure TMyObjectInspector.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FDraggingColumn := False;

  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TMyObjectInspector.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LNode: TTreeNode;
  LInspectorNode: TMyInspectorNode;
begin
  EndEdit(True);

  if (Button = mbLeft) and OnColumnSeparator(X) then
  begin
    FDraggingColumn := True;
    Exit;
  end;

  inherited MouseDown(Button, Shift, X, Y);

  if Button <> mbLeft then
    Exit;

  LNode := GetNodeAt(X, Y);

  if not (LNode is TMyInspectorNode) then
    Exit;

  LInspectorNode := TMyInspectorNode(LNode);
  LInspectorNode.Selected := True;

  if X < FNameColumnWidth then
    Exit;

  if (LInspectorNode.IsBooleanValue or LInspectorNode.IsSetValue) and not LInspectorNode.IsReadOnly then
  begin
    if CompareText(LInspectorNode.PropertyValue, BooleanIdents[True]) = 0 then
      SetValueAsString(LInspectorNode, BooleanIdents[False])
    else
      SetValueAsString(LInspectorNode, BooleanIdents[True]);

    Exit;
  end;

  BeginEdit(LInspectorNode);
end;

procedure TMyObjectInspector.BeginEdit(const ANode: TMyInspectorNode);
var
  LRect: TRect;
  LEdit: TEdit;
  LComboBox: TComboBox;
  LColorBox: TColorBox;
  LTypeData: PTypeData;
begin
  EndEdit(True);

  if ANode.IsReadOnly or ANode.IsBooleanValue or ANode.IsSetValue or not Assigned(ANode.PropTypeInfo) then
    Exit;

  if ANode.PropTypeInfo.Name = TYPE_FILENAME then
  begin
    EditFileNameProperty(ANode);
    Exit;
  end;

  if (ANode.PropTypeInfo.Kind = tkClass) and (ANode.PropertyObject is TStrings) then
  begin
    EditStringsProperty(ANode);
    Exit;
  end;

  if ANode.PropTypeInfo.Kind in [tkClass, tkSet] then
    Exit;

  FEditNode := ANode;

  LRect := ANode.DisplayRect(False);
  LRect.Left := FNameColumnWidth - 2;
  LRect.Width := ClientWidth - LRect.Left - 2;

  if ANode.PropTypeInfo = System.TypeInfo(TColor) then
  begin
    LColorBox := TColorBox.Create(nil);
    FEditor := LColorBox;
    LColorBox.Parent := Self;
    LColorBox.Style := LColorBox.Style + [cbCustomColor];
    LColorBox.BoundsRect := LRect;
    LColorBox.Selected := StringToColor(ANode.PropertyValue);
    LColorBox.OnSelect := ColorBoxSelect;
    LColorBox.OnExit := EditorExit;
    LColorBox.Show;
    LColorBox.SetFocus;
  end
  else
  if (ANode.PropTypeInfo.Kind = tkEnumeration) or (ANode.PropTypeInfo = System.TypeInfo(TShortCut)) then
  begin
    LComboBox := TComboBox.Create(nil);
    FEditor := LComboBox;
    LComboBox.Parent := Self;
    LComboBox.Style := csDropDownList;
    LComboBox.BoundsRect := LRect;

    LComboBox.Items.BeginUpdate;

    if ANode.PropTypeInfo = System.TypeInfo(TShortCut) then
    begin
      for var LIndex := 1 to High(ShortCuts) do
        LComboBox.Items.Add(ShortCutToText(ShortCuts[LIndex]));

      LComboBox.ItemIndex := LComboBox.Items.IndexOf(ShortCutToText(StrToIntDef(ANode.PropertyValue, 0)));
    end
    else
    begin
      LTypeData := GetTypeData(ANode.PropTypeInfo);

      for var LIndex := LTypeData.MinValue to LTypeData.MaxValue do
        LComboBox.Items.Add(GetEnumName(ANode.PropTypeInfo, LIndex));

      LComboBox.ItemIndex := LComboBox.Items.IndexOf(ANode.PropertyValue);
    end;

    LComboBox.Items.EndUpdate;
    LComboBox.OnChange := ComboChange;
    LComboBox.OnExit := EditorExit;
    LComboBox.Show;
    LComboBox.SetFocus;
    LComboBox.DroppedDown := True;
  end
  else
  begin
    LEdit := TEdit.Create(nil);
    FEditor := LEdit;
    LEdit.Parent := Self;
    LEdit.BoundsRect := LRect;
    LEdit.Text := ANode.PropertyValue;
    LEdit.OnKeyPress := EditorKeyPress;
    LEdit.OnExit := EditorExit;
    LEdit.Show;
    LEdit.SetFocus;
    LEdit.SelectAll;
  end;
end;

procedure TMyObjectInspector.EndEdit(const AApply: Boolean);
var
  LValue: string;
  LApply: Boolean;
begin
  if not Assigned(FEditor) then
    Exit;

  LApply := AApply and Assigned(FEditNode);

  if LApply then
  begin
    LValue := '';

    if FEditor is TColorBox then
      LValue := ColorToString(TColorBox(FEditor).Selected)
    else
    if FEditor is TComboBox then
    begin
      if TComboBox(FEditor).ItemIndex >= 0 then
        LValue := TComboBox(FEditor).Items[TComboBox(FEditor).ItemIndex]
      else
        LApply := False;
    end
    else
    if FEditor is TEdit then
      LValue := TEdit(FEditor).Text;

    if LApply then
    try
      SetValueAsString(FEditNode, LValue);
    except
      { Ignore }
    end;
  end;

  ReleaseEditor;
end;

procedure TMyObjectInspector.ReleaseEditor;
var
  LEditor: TWinControl;
begin
  LEditor := FEditor;
  FEditor := nil;
  FEditNode := nil;

  if Assigned(LEditor) then
  begin
    LEditor.Hide;
    LEditor.Parent := nil;

    TThread.ForceQueue(nil,
      procedure
      begin
        LEditor.Free;
      end);
  end;
end;

procedure TMyObjectInspector.EditorKeyPress(Sender: TObject; var Key: Char);
begin
  case Key of
    #13:
      begin
        Key := #0;
        EndEdit(True);
      end;
    #27:
      begin
        Key := #0;
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

procedure TMyObjectInspector.ColorBoxSelect(Sender: TObject);
begin
  EndEdit(True);
end;

procedure TMyObjectInspector.EditFileNameProperty(const ANode: TMyInspectorNode);
var
  LDialog: TOpenDialog;
begin
  if ANode.PropertyName.Contains('Save') then
    LDialog := TSaveDialog.Create(Self)
  else
    LDialog := TOpenDialog.Create(Self);

  try
    LDialog.Filter := 'JSON files (*.json)|*.json|All files (*.*)|*.*';

    if LDialog.Execute then
      SetValueAsString(ANode, LDialog.FileName);
  finally
    LDialog.Free;
  end;
end;

procedure TMyObjectInspector.EditStringsProperty(const ANode: TMyInspectorNode);
var
  LForm: TForm;
  LMemo: TMemo;
  LPanel: TPanel;
  LButton: TButton;
  LParentObject: TObject;
  LStrings: TStringList;
begin
  LForm := TForm.CreateNew(Self);
  try
    LForm.Caption := ANode.PropertyName;
    LForm.Position := poScreenCenter;
    LForm.ClientWidth := 560;
    LForm.ClientHeight := 480;

    LPanel := TPanel.Create(LForm);
    LPanel.Parent := LForm;
    LPanel.Align := alBottom;
    LPanel.BevelOuter := bvNone;
    LPanel.Height := 42;

    LButton := TButton.Create(LForm);
    LButton.Parent := LPanel;
    LButton.SetBounds(LForm.ClientWidth - 170, 9, 80, 25);
    LButton.Anchors := [akRight, akTop];
    LButton.Caption := 'OK';
    LButton.Default := True;
    LButton.ModalResult := mrOk;

    LButton := TButton.Create(LForm);
    LButton.Parent := LPanel;
    LButton.SetBounds(LForm.ClientWidth - 86, 9, 80, 25);
    LButton.Anchors := [akRight, akTop];
    LButton.Caption := 'Cancel';
    LButton.Cancel := True;
    LButton.ModalResult := mrCancel;

    LMemo := TMemo.Create(LForm);
    LMemo.Parent := LForm;
    LMemo.AlignWithMargins := True;
    LMemo.Margins.SetBounds(8, 8, 8, 0);
    LMemo.Align := alClient;
    LMemo.ScrollBars := ssBoth;
    LMemo.WordWrap := False;
    LMemo.Lines.Assign(TStrings(ANode.PropertyObject));

    if LForm.ShowModal = mrOk then
    begin
      LParentObject := ParentObjectOf(ANode);

      if Assigned(ANode.PropertyInfo) and Assigned(ANode.PropertyInfo.SetProc) then
      begin
        LStrings := TStringList.Create;
        try
          LStrings.Assign(LMemo.Lines);

          SetObjectProp(LParentObject, ANode.PropertyInfo, LStrings);
        finally
          LStrings.Free;
        end;
      end
      else
        TStrings(ANode.PropertyObject).Assign(LMemo.Lines);
    end;
  finally
    LForm.Free;
  end;
end;

procedure TMyObjectInspector.WMVScroll(var AMessage: TWMVScroll);
begin
  EndEdit(True);

  inherited;
end;

procedure TMyObjectInspector.WMHScroll(var AMessage: TWMHScroll);
begin
  EndEdit(True);

  inherited;
end;

procedure TMyObjectInspector.WMMouseWheel(var AMessage: TWMMouseWheel);
begin
  EndEdit(True);

  inherited;
end;

procedure TMyObjectInspector.WMSize(var AMessage: TWMSize);
begin
  EndEdit(True);

  inherited;
end;

end.
