unit TextEditor.Highlighter.Info;

interface

type
  TTextEditorAuthorInfo = record
    Name: string;
    Email: string;
    Comments: string;
  end;

  TTextEditorGeneralInfo = record
    Version: string;
    Date: string;
    Sample: string;
  end;

  TTextEditorHighlighterInfo = class
  public
    Author: TTextEditorAuthorInfo;
    General: TTextEditorGeneralInfo;
    procedure Clear;
  end;

implementation

procedure TTextEditorHighlighterInfo.Clear;
begin
  General.Version := '';
  General.Date := '';
  General.Sample := '';
  Author.Name := '';
  Author.Email := '';
  Author.Comments := '';
end;

end.