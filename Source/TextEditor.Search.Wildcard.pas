unit TextEditor.Search.Wildcard;

interface

uses
  System.Classes, TextEditor.Search.RegularExpressions;

type
  TTextEditorWildcardSearch = class(TTextEditorRegexSearch)
  protected
    function WildCardToRegExpr(const AWildCard: string): string;
    procedure SetPattern(const AValue: string); override;
  end;

implementation

procedure TTextEditorWildcardSearch.SetPattern(const AValue: string);
begin
  FPattern := WildCardToRegExpr(AValue);
end;

function TTextEditorWildcardSearch.WildCardToRegExpr(const AWildCard: string): string;
var
  LIndex: Integer;
begin
  Result := '';

  for LIndex := 1 to Length(AWildCard) do
  case AWildCard[LIndex] of
    '*':
      Result := Result + '.*';
    '?':
      Result := Result + '.?';
    '|':
      Result := Result + '\|';
    '#':
      Result := Result + '[0-9]';
  else
    Result := Result + AWildCard[LIndex];
  end;
end;

end.
