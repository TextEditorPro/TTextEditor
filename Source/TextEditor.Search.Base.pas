unit TextEditor.Search.Base;

interface

uses
  System.Classes, TextEditor.Lines, TextEditor.Types;

type
  TTextEditorSearchBase = class
  strict private
    FCaseSensitive: Boolean;
    FEngine: TTextEditorSearchEngine;
    FStatus: string;
    FWholeWordsOnly: Boolean;
    procedure SetCaseSensitive(const AValue: Boolean);
  protected
    FPattern: string;
    FResults: TList;
    function GetLength(const AIndex: Integer): Integer; virtual; abstract;
    function GetResult(const AIndex: Integer): Integer; virtual;
    function GetResultCount: Integer; virtual;
    procedure CaseSensitiveChanged; virtual; abstract;
    procedure SetPattern(const AValue: string); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    function SearchAll(const ALines: TTextEditorLines): Integer; virtual; abstract;
    procedure Clear; virtual;
    property CaseSensitive: Boolean read FCaseSensitive write SetCaseSensitive default False;
    property Engine: TTextEditorSearchEngine read FEngine write FEngine;
    property Lengths[const AIndex: Integer]: Integer read GetLength;
    property Pattern: string read FPattern write SetPattern;
    property ResultCount: Integer read GetResultCount;
    property Results[const AIndex: Integer]: Integer read GetResult;
    property Status: string read FStatus write FStatus;
    property WholeWordsOnly: Boolean read FWholeWordsOnly write FWholeWordsOnly default False;
  end;

implementation

constructor TTextEditorSearchBase.Create;
begin
  inherited;

  FCaseSensitive := False;
  FWholeWordsOnly := False;
  FPattern := '';
  FResults := TList.Create;
end;

destructor TTextEditorSearchBase.Destroy;
begin
  FResults.Free;
  inherited Destroy;
end;

procedure TTextEditorSearchBase.SetCaseSensitive(const AValue: Boolean);
begin
  FCaseSensitive := AValue;
  CaseSensitiveChanged;
end;

function TTextEditorSearchBase.GetResult(const AIndex: Integer): Integer;
begin
  Result := 0;
  if (AIndex >= 0) and (AIndex < FResults.Count) then
    Result := Integer(FResults[AIndex]);
end;

function TTextEditorSearchBase.GetResultCount: Integer;
begin
  Result := FResults.Count;
end;

procedure TTextEditorSearchBase.Clear;
begin
  FResults.Clear;
end;

procedure TTextEditorSearchBase.SetPattern(const AValue: string);
begin
  FPattern := AValue;
end;

end.
