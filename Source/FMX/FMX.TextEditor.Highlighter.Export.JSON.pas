unit FMX.TextEditor.Highlighter.Export.JSON;

interface

uses
  System.Classes, FMX.TextEditor, FMX.TextEditor.JSONDataObjects;

type
  TTextEditorHighlighterExportJSON = class(TObject)
  strict private
    FEditor: TCustomTextEditor;
    procedure ExportColorTheme(const AThemeObject: TJSONObject);
  public
    constructor Create(const AEditor: TCustomTextEditor); overload;
    procedure SaveThemeToFile(const AFileName: string);
  end;

implementation

uses
  System.SysUtils, System.TypInfo, System.UIConsts, System.UITypes, FMX.Graphics, FMX.TextEditor.Utils;

type
  TPropertyArray = array of PPropInfo;

constructor TTextEditorHighlighterExportJSON.Create(const AEditor: TCustomTextEditor);
begin
  inherited Create;

  FEditor := AEditor;
end;

procedure TTextEditorHighlighterExportJSON.SaveThemeToFile(const AFileName: string);
const
  THEME_FILE_FORMAT = '{ "Theme": { "Colors": {}, "Fonts": {}, "FontSizes": {}, "Styles": [] } }';
var
  LJSONObject: TJSONObject;
  LStringList: TStringList;
begin
  LJSONObject := TJSONObject.Parse(THEME_FILE_FORMAT) as TJSONObject;
  try
    ExportColorTheme(LJSONObject['Theme']);

    LStringList := TStringList.Create;
    try
      LStringList.Text := LJSONObject.ToJSON;
      LStringList.SaveToFile(AFileName);
    finally
      LStringList.Free;
    end;
  finally
    LJSONObject.Free;
  end;
end;

function IntegerAsString(const ATypeInfo: PTypeInfo; const AValue: Integer): string;
var
  LIntToIdent: TIntToIdent;
  LIdent: string;
begin
  LIntToIdent := FindIntToIdent(ATypeInfo);

  Result := if Assigned(LIntToIdent) and LIntToIdent(AValue, LIdent) then LIdent else '$' + IntToHex(AValue, SizeOf(Integer) * 2);
end;

function ColorAsString(const AColor: TAlphaColor): string;
var
  LColor: TColor;
  LIdent: string;
begin
  { Theme files are shared with the VCL editor and store VCL TColor values }
  LColor := TextEditorAlphaColorToColor(AColor);

  Result := if ColorToIdent(LColor, LIdent) then LIdent else '$' + IntToHex(LColor, SizeOf(Integer) * 2);
end;

function SetAsString(const ATypeInfo: PTypeInfo; const AValue: Integer): string;
var
  LBaseType: PTypeInfo;
begin
  Result := '';

  LBaseType := GetTypeData(ATypeInfo)^.CompType^;

  for var LIndex := 0 to SizeOf(TIntegerSet) * 8 - 1 do
  if LIndex in TIntegerSet(AValue) then
  begin
    if not Result.IsEmpty then
      Result := Result + ';';

    Result := Result + Copy(GetEnumName(LBaseType, LIndex), 3);
  end;
end;

procedure TTextEditorHighlighterExportJSON.ExportColorTheme(const AThemeObject: TJSONObject);
var
  LPropertyArray: TPropertyArray;
  LPropertyCount: Integer;

  procedure GetPropertyArray(const APTypeInfo: PTypeInfo);
  begin
    LPropertyCount := GetPropList(APTypeInfo, tkProperties, nil);
    SetLength(LPropertyArray, LPropertyCount);
    GetPropList(APTypeInfo, tkProperties, PPropList(LPropertyArray));
  end;

  procedure ClearPropertyArray;
  begin
    SetLength(LPropertyArray, 0);
  end;

var
  LJSONObject, LJSONObject2: TJSONObject;
  LPPropInfo: PPropInfo;
  LObject: TObject;
  LJSONArray: TJSONArray;
  LStyle: string;
begin
  { Colors }
  LJSONObject := AThemeObject['Colors'].ObjectValue;

  GetPropertyArray(FEditor.Colors.ClassInfo);
  try
    for var LIndex := 0 to LPropertyCount - 1 do
    begin
      LPPropInfo := LPropertyArray[LIndex];

      if LPPropInfo^.PropType^ = TypeInfo(TAlphaColor) then
        LJSONObject[string(LPPropInfo.Name)] := ColorAsString(TAlphaColor(GetOrdProp(FEditor.Colors, LPPropInfo)))
      else
        LJSONObject[string(LPPropInfo.Name)] := IntegerAsString(LPPropInfo^.PropType^, GetOrdProp(FEditor.Colors, LPPropInfo));
    end;
  finally
    ClearPropertyArray;
  end;
  { Fonts and font sizes }
  LJSONObject := AThemeObject['Fonts'].ObjectValue;
  LJSONObject2 := AThemeObject['FontSizes'].ObjectValue;

  GetPropertyArray(FEditor.Fonts.ClassInfo);
  try
    for var LIndex := 0 to LPropertyCount - 1 do
    begin
      LPPropInfo := LPropertyArray[LIndex];

      LObject := GetObjectProp(FEditor.Fonts, LPPropInfo);

      LJSONObject[string(LPPropInfo.Name)] := TFont(LObject).Family;
      LJSONObject2[string(LPPropInfo.Name)] := TFont(LObject).Size.ToString;
    end;
  finally
    ClearPropertyArray;
  end;
  { Styles }
  LJSONArray := AThemeObject.ValueArray['Styles'];

  GetPropertyArray(FEditor.FontStyles.ClassInfo);
  try
    for var LIndex := 0 to LPropertyCount - 1 do
    begin
      LPPropInfo := LPropertyArray[LIndex];

      LStyle := SetAsString(LPPropInfo^.PropType^, GetOrdProp(FEditor.FontStyles, LPPropInfo));

      if not LStyle.IsEmpty then
      begin
        LJSONObject := LJSONArray.AddObject;
        LJSONObject['Name'] := string(LPPropInfo.Name);
        LJSONObject['Style'] := LStyle;
      end;
    end;
  finally
    ClearPropertyArray;
  end;
end;

end.
