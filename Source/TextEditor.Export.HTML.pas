unit TextEditor.Export.HTML;

interface

uses
  System.Classes, System.SysUtils, Vcl.Graphics, TextEditor.Highlighter, TextEditor.Lines;

type
  TTextEditorExportHTML = class(TObject)
  private
    FCharSet: string;
    FFont: TFont;
    FHighlighter: TTextEditorHighlighter;
    FLines: TTextEditorLines;
    FStringList: TStrings;
    procedure CreateHTMLDocument;
    procedure CreateHeader;
    procedure CreateInternalCSS;
    procedure CreateLines;
    procedure CreateFooter;
  public
    constructor Create(const ALines: TTextEditorLines; const AHighlighter: TTextEditorHighlighter; const AFont: TFont;
      const ACharSet: string); overload;
    destructor Destroy; override;

    procedure SaveToStream(AStream: TStream; AEncoding: System.SysUtils.TEncoding);
  end;

implementation

uses
  Winapi.Windows, System.UITypes, TextEditor.Consts, TextEditor.Highlighter.Attributes, TextEditor.Highlighter.Colors,
  TextEditor.Utils;

constructor TTextEditorExportHTML.Create(const ALines: TTextEditorLines; const AHighlighter: TTextEditorHighlighter;
  const AFont: TFont; const ACharSet: string);
begin
  inherited Create;

  FStringList := TStringList.Create;

  FCharSet := ACharSet;
  if FCharSet = '' then
    FCharSet := 'utf-8';
  FLines := ALines;
  FHighlighter := AHighlighter;
  FFont := AFont;
end;

destructor TTextEditorExportHTML.Destroy;
begin
  FStringList.Free;

  inherited Destroy;
end;

procedure TTextEditorExportHTML.CreateHTMLDocument;
begin
  if not Assigned(FHighlighter) then
    Exit;
  if FLines.Count = 0 then
    Exit;

  CreateHeader;
  CreateLines;
  CreateFooter;
end;

procedure TTextEditorExportHTML.CreateHeader;
begin
  FStringList.Add('<!DOCTYPE HTML>');
  FStringList.Add('');
  FStringList.Add('<html>');
  FStringList.Add('<head>');
	FStringList.Add('  <meta charset="' + FCharSet + '">');

  CreateInternalCSS;

  FStringList.Add('</head>');
  FStringList.Add('');
  FStringList.Add('<body class="Editor">');
end;

procedure TTextEditorExportHTML.CreateInternalCSS;
var
  LIndex: Integer;
  LStyles: TList;
  LElement: PTextEditorHighlighterElement;
begin
  FStringList.Add('  <style>');

  FStringList.Add('    body {');
  FStringList.Add('      font-family: ' + FFont.Name + ';');
  FStringList.Add('      font-size: ' + IntToStr(FFont.Size) + 'px;');
  FStringList.Add('    }');

  LStyles := FHighlighter.Colors.Styles;
  for LIndex := 0 to LStyles.Count - 1 do
  begin
    LElement := LStyles.Items[LIndex];

    FStringList.Add('    .' + LElement^.Name + ' { ');
    FStringList.Add('      color: ' + ColorToHex(LElement^.Foreground) + ';');
    FStringList.Add('      background-color: ' + ColorToHex(LElement^.Background) + ';');

    if TFontStyle.fsBold in LElement^.FontStyles then
      FStringList.Add('      font-weight: bold;');

    if TFontStyle.fsItalic in LElement^.FontStyles then
      FStringList.Add('      font-style: italic;');

    if TFontStyle.fsUnderline in LElement^.FontStyles then
      FStringList.Add('      text-decoration: underline;');

    if TFontStyle.fsStrikeOut in LElement^.FontStyles then
      FStringList.Add('      text-decoration: line-through;');

    FStringList.Add('    }');
    FStringList.Add('');
  end;
  FStringList.Add('  </style>');
end;

procedure TTextEditorExportHTML.CreateLines;
var
  LIndex: Integer;
  LTextLine, LToken: string;
  LHighlighterAttribute: TTextEditorHighlighterAttribute;
  LPreviousElement: string;
begin
  LPreviousElement := '';
  for LIndex := 0 to FLines.Count - 1 do
  begin
    if LIndex = 0 then
      FHighlighter.ResetRange
    else
      FHighlighter.SetRange(FLines.Items^[LIndex - 1].Range);
    FHighlighter.SetLine(FLines.ExpandedStrings[LIndex]);
    LTextLine := '';
    while not FHighlighter.EndOfLine do
    begin
      LHighlighterAttribute := FHighlighter.TokenAttribute;
      FHighlighter.GetToken(LToken);
      if LToken = TCharacters.Space then
        LTextLine := LTextLine + '&nbsp;'
      else
      if LToken = '&' then
        LTextLine := LTextLine + '&amp;'
      else
      if LToken = '<' then
        LTextLine := LTextLine + '&lt;'
      else
      if LToken = '>' then
        LTextLine := LTextLine + '&gt;'
      else
      if LToken = '"' then
        LTextLine := LTextLine + '&quot;'
      else
      if Assigned(LHighlighterAttribute) then
      begin
        if (LPreviousElement <> '') and (LPreviousElement <> LHighlighterAttribute.Element) then
          LTextLine := LTextLine + '</span>';
        if LPreviousElement <> LHighlighterAttribute.Element then
          LTextLine := LTextLine + '<span class="' + LHighlighterAttribute.Element + '">';
        LTextLine := LTextLine + LToken;
        LPreviousElement := LHighlighterAttribute.Element;
      end
      else
        LTextLine := LTextLine + LToken;
      FHighlighter.Next;
    end;
    FStringList.Add(LTextLine + '<br>');
  end;
  if LPreviousElement <> '' then
    FStringList.Add('</span>');
end;

procedure TTextEditorExportHTML.CreateFooter;
begin
  FStringList.Add('</body>');
  FStringList.Add('</html>');
end;

procedure TTextEditorExportHTML.SaveToStream(AStream: TStream; AEncoding: System.SysUtils.TEncoding);
begin
  CreateHTMLDocument;
  if not Assigned(AEncoding) then
    AEncoding := TEncoding.UTF8;
  FStringList.SaveToStream(AStream, AEncoding);
end;

end.
