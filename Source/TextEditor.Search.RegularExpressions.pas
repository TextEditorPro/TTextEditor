unit TextEditor.Search.RegularExpressions;

interface

uses
  System.Classes, System.RegularExpressions, TextEditor.Lines, TextEditor.Search.Base;

type
  TTextEditorRegexSearch = class(TTextEditorSearchBase)
  strict private
    FLengths: TList;
    FOptions: TRegexOptions;
  protected
    function GetLength(const AIndex: Integer): Integer; override;
    procedure CaseSensitiveChanged; override;
  public
    constructor Create;
    destructor Destroy; override;
    function SearchAll(const ALines: TTextEditorLines): Integer; override;
    procedure Clear; override;
  end;

implementation

uses
  System.SysUtils;

constructor TTextEditorRegexSearch.Create;
begin
  inherited Create;

  FOptions := [roMultiLine, roNotEmpty];
  FLengths := TList.Create;
end;

destructor TTextEditorRegexSearch.Destroy;
begin
  inherited;
  FLengths.Free;
end;

procedure TTextEditorRegexSearch.CaseSensitiveChanged;
begin
  if CaseSensitive then
    Exclude(FOptions, roIgnoreCase)
  else
    Include(FOptions, roIgnoreCase);
end;

function TTextEditorRegexSearch.SearchAll(const ALines: TTextEditorLines): Integer;

  procedure AddResult(const APos, ALength: Integer);
  begin
    FResults.Add(Pointer(APos));
    FLengths.Add(Pointer(ALength));
  end;

var
  LRegex: TRegEx;
  LMatch: TMatch;
begin
  Result := 0;
  Clear;
  Status := '';
  try
    LRegex := TRegEx.Create(FPattern, FOptions);
    LMatch := LRegex.Match(ALines.Text);
    while LMatch.Success do
    begin
      AddResult(LMatch.Index, LMatch.Length);
      LMatch := LMatch.NextMatch;
      Inc(Result);
    end;
  except
    on E: Exception do
      Status := E.Message;
  end;
end;

procedure TTextEditorRegexSearch.Clear;
begin
  inherited;

  FLengths.Clear;
end;

function TTextEditorRegexSearch.GetLength(const AIndex: Integer): Integer;
begin
  Result := Integer(FLengths[AIndex]);
end;

end.
