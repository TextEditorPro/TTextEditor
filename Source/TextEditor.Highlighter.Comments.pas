unit TextEditor.Highlighter.Comments;

interface

uses
  TextEditor.Consts, TextEditor.Types;

type
  TTextEditorHighlighterComments = class(TObject)
  strict private
    FChars: TTextEditorCharSet;
    FBlockComments: TTextEditorArrayOfString;
    FBlockCommentsFound: Boolean;
    FLineComments: TTextEditorArrayOfString;
    FLineCommentsFound: Boolean;
    procedure AddChars(const AToken: string);
  public
    destructor Destroy; override;
    procedure AddBlockComment(const AOpenToken: string; const ACloseToken: string);
    procedure AddLineComment(const AToken: string);
    procedure Clear;
    property BlockComments: TTextEditorArrayOfString read FBlockComments;
    property BlockCommentsFound: Boolean read FBlockCommentsFound;
    property Chars: TTextEditorCharSet read FChars write FChars;
    property LineComments: TTextEditorArrayOfString read FLineComments;
    property LineCommentsFound: Boolean read FLineCommentsFound;
  end;

implementation

uses
  System.SysUtils;

destructor TTextEditorHighlighterComments.Destroy;
begin
  Clear;

  inherited Destroy;
end;

procedure TTextEditorHighlighterComments.AddChars(const AToken: string);
var
  LIndex: Integer;
begin
  for LIndex := 1 to AToken.Length do
    FChars := FChars + [AToken[LIndex]];
end;

procedure TTextEditorHighlighterComments.AddBlockComment(const AOpenToken: string; const ACloseToken: string);
var
  LIndex, LLength: Integer;
begin
  LLength := Length(FBlockComments);
  LIndex := 0;

  while LIndex < LLength do
  begin
    if (FBlockComments[LIndex] = AOpenToken) and (FBlockComments[LIndex + 1] = ACloseToken) then
      Exit;

    Inc(LIndex, 2);
  end;

  SetLength(FBlockComments, LLength + 2);
  FBlockComments[LLength] := AOpenToken;
  FBlockComments[LLength + 1] := ACloseToken;

  FBlockCommentsFound := True;

  AddChars(AOpenToken);
  AddChars(ACloseToken);
end;

procedure TTextEditorHighlighterComments.AddLineComment(const AToken: string);
var
  LIndex, LLength: Integer;
begin
  LLength := Length(FLineComments);

  for LIndex := 0 to LLength - 1 do
  if FLineComments[LIndex] = AToken then
    Exit;

  SetLength(FLineComments, LLength + 1);
  FLineComments[LLength] := AToken;

  FLineCommentsFound := True;

  AddChars(AToken);
end;

procedure TTextEditorHighlighterComments.Clear;
begin
  FBlockCommentsFound := False;
  SetLength(FBlockComments, 0);
  FLineCommentsFound := False;
  SetLength(FLineComments, 0);
  FChars := [];
end;

end.
