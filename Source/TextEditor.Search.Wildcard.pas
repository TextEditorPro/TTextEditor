unit TextEditor.Search.Wildcard;

interface

uses
  TextEditor.Search.RegularExpressions;

type
  TTextEditorWildcardSearch = class(TTextEditorRegexSearch)
  protected
    function WildCardToRegExpr(const AWildCard: string): string;
    procedure SetPattern(const AValue: string); override;
  end;

implementation

uses
  System.SysUtils;

procedure TTextEditorWildcardSearch.SetPattern(const AValue: string);
begin
  FPattern := WildCardToRegExpr(AValue);
end;

function TTextEditorWildcardSearch.WildCardToRegExpr(const AWildCard: string): string;
begin
  Result := AWildCard;

  Result := StringReplace(Result, '.', '[.]', [rfReplaceAll]);
  Result := StringReplace(Result, '*', '.*', [rfReplaceAll]);
  Result := StringReplace(Result, '?', '.?', [rfReplaceAll]);
  Result := StringReplace(Result, '#', '[0-9]', [rfReplaceAll]);
  Result := StringReplace(Result, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, '|', '\|', [rfReplaceAll]);
  Result := StringReplace(Result, '(', '\(', [rfReplaceAll]);
  Result := StringReplace(Result, ')', '\)', [rfReplaceAll]);
  Result := StringReplace(Result, '^', '\^', [rfReplaceAll]);
  Result := StringReplace(Result, '$', '\$', [rfReplaceAll]);
end;

end.
