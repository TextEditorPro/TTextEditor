unit TextEditor.SkipRegions;

interface

uses
  System.Classes, System.SysUtils, TextEditor.Consts;

type
  TTextEditorSkipRegionItemType = (ritUnspecified, ritMultiLineString, ritSingleLineString, ritMultiLineComment, ritSingleLineComment);

  TTextEditorSkipRegionItem = class(TCollectionItem)
  strict private
    FCloseToken: string;
    FOpenToken: string;
    FRegionType: TTextEditorSkipRegionItemType;
    FSkipEmptyChars: Boolean;
    FSkipIfNextCharIsNot: Char;
  public
    property OpenToken: string read FOpenToken write FOpenToken;
    property CloseToken: string read FCloseToken write FCloseToken;
    property RegionType: TTextEditorSkipRegionItemType read FRegionType write FRegionType;
    property SkipEmptyChars: Boolean read FSkipEmptyChars write FSkipEmptyChars;
    property SkipIfNextCharIsNot: Char read FSkipIfNextCharIsNot write FSkipIfNextCharIsNot default TControlCharacters.Null;
  end;

  TTextEditorSkipRegions = class(TCollection)
  strict private
    function GetSkipRegionItem(const AIndex: Integer): TTextEditorSkipRegionItem;
  public
    function Add(const AOpenToken, ACloseToken: string): TTextEditorSkipRegionItem;
    function Contains(const AOpenToken, ACloseToken: string): Boolean;
    property SkipRegionItems[const AIndex: Integer]: TTextEditorSkipRegionItem read GetSkipRegionItem; default;
  end;

implementation



{ TTextEditorSkipRegions }

function TTextEditorSkipRegions.Add(const AOpenToken, ACloseToken: string): TTextEditorSkipRegionItem;
begin
  Result := TTextEditorSkipRegionItem(inherited Add);
  with Result do
  begin
    OpenToken := AOpenToken;
    CloseToken := ACloseToken;
  end;
end;

function TTextEditorSkipRegions.Contains(const AOpenToken, ACloseToken: string): Boolean;
var
  LIndex: Integer;
  LSkipRegion: TTextEditorSkipRegionItem;
begin
  Result := False;
  for LIndex := 0 to Count - 1 do
  begin
    LSkipRegion := SkipRegionItems[LIndex];
    if (LSkipRegion.OpenToken = AOpenToken) and (LSkipRegion.CloseToken = ACloseToken) then
      Exit(True);
  end;
end;

function TTextEditorSkipRegions.GetSkipRegionItem(const AIndex: Integer): TTextEditorSkipRegionItem;
begin
  Result := TTextEditorSkipRegionItem(inherited Items[AIndex]);
end;

end.
