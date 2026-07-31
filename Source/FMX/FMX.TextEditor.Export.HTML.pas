unit FMX.TextEditor.Export.HTML;

interface

uses
  System.Classes, System.SysUtils, FMX.Controls, FMX.Graphics, FMX.TextEditor.Highlighter.Attributes;

type
  TTextEditorExportHTML = class(TObject)
  private
    FCharSet: string;
    FFont: TFont;
    FStringList: TStrings;
    FTextEditor: TControl;
    procedure CreateFooter;
    procedure CreateHTMLDocument;
    procedure CreateHeader;
    procedure CreateLines;
    procedure GetStyle(const AHighlighterAttribute: TTextEditorHighlighterAttribute; var AStyle: string);
  public
    constructor Create(const ATextEditor: TControl; const AFont: TFont; const ACharSet: string); overload;
    destructor Destroy; override;
    function AsText(const AClipboardFormat: Boolean = False): string;
    procedure SaveToStream(AStream: TStream; AEncoding: System.SysUtils.TEncoding);
  end;

implementation

uses
  System.NetEncoding, System.UITypes, FMX.TextEditor, FMX.TextEditor.Consts, FMX.TextEditor.Types;

function TextEditorColorToHTML(const AColor: TAlphaColor): string;
begin
  Result := '#' + IntToHex(TAlphaColorRec(AColor).R, 2) + IntToHex(TAlphaColorRec(AColor).G, 2) + IntToHex(TAlphaColorRec(AColor).B, 2);
end;

function TextEditorFontFamily(const AFont: TFont): string;
begin
  Result := AFont.Family;
end;

function TextEditorFontSize(const AFont: TFont): Integer;
begin
  Result := Round(AFont.Size);
end;

constructor TTextEditorExportHTML.Create(const ATextEditor: TControl; const AFont: TFont; const ACharSet: string);
begin
  inherited Create;

  FTextEditor := ATextEditor;
  FFont := AFont;
  FCharSet := ACharSet;

  if FCharSet.IsEmpty then
    FCharSet := 'utf-8';

  FStringList := TStringList.Create;
end;

destructor TTextEditorExportHTML.Destroy;
begin
  FStringList.Free;

  inherited Destroy;
end;

procedure TTextEditorExportHTML.CreateHTMLDocument;
begin
  FStringList.BeginUpdate;

  CreateHeader;
  CreateLines;
  CreateFooter;

  FStringList.EndUpdate;
end;

procedure TTextEditorExportHTML.CreateHeader;
begin
  with FStringList do
  begin
    Add('<!DOCTYPE HTML>');
    Add('<html>');
    Add('<head>');
	  Add('  <meta charset="' + FCharSet + '">');
    Add('</head>');
    Add('<body>');
  end;
end;

procedure TTextEditorExportHTML.GetStyle(const AHighlighterAttribute: TTextEditorHighlighterAttribute; var AStyle: string);
begin
  AStyle := 'box-sizing:border-box;font-family:' + FFont.Family +
    ';font-size:' + FloatToStr(FFont.Size) + 'pt' +
    ';color:' + TextEditorColorToHTML(AHighlighterAttribute.Foreground).ToLower +
    ';background-color:' + TextEditorColorToHTML(AHighlighterAttribute.Background).ToLower;

  AStyle := AStyle + ';font-weight:' + if TFontStyle.fsBold in AHighlighterAttribute.FontStyles then '700' else '400';

  if TFontStyle.fsItalic in AHighlighterAttribute.FontStyles then
    AStyle := AStyle + ';font-style:italic';

  if TFontStyle.fsUnderline in AHighlighterAttribute.FontStyles then
    AStyle := AStyle + ';text-decoration:underline';

  if TFontStyle.fsStrikeOut in AHighlighterAttribute.FontStyles then
    AStyle := AStyle + ';text-decoration:line-through';
end;

procedure TTextEditorExportHTML.CreateLines;
var
  LTextEditor: TTextEditor;
  LShowLineNumbers: Boolean;
  LPreviousElement: string;
  LSelectionAvailable: Boolean;
  LStartLine: Integer;
  LEndLine: Integer;
  LLineNumber: string;
  LLineNumberHTML: string;
  LTextLine, LSpaces, LToken, LStyle: string;
  LHighlighterAttribute: TTextEditorHighlighterAttribute;
begin
  LTextEditor := FTextEditor as TTextEditor;
  LShowLineNumbers := eoShowLineNumbersInHTMLExport in LTextEditor.Options;
  LPreviousElement := '';
  LSelectionAvailable := LTextEditor.SelectionAvailable;
  LStartLine := if LSelectionAvailable then LTextEditor.SelectionStartPosition.Line else 0;
  LEndLine := if LSelectionAvailable then LTextEditor.SelectionEndPosition.Line else LTextEditor.Lines.Count - 1;
  LLineNumber := '';
  LLineNumberHTML :=
    if LShowLineNumbers then
      '<span style="display:inline-block;text-align:right;text-valign:center;' +
      ';font-family:' + TextEditorFontFamily(LTextEditor.Fonts.LineNumbers) +
      ';font-size:' + IntToStr(TextEditorFontSize(LTextEditor.Fonts.LineNumbers)) + 'pt' +
      ';color:' + TextEditorColorToHTML(LTextEditor.Colors.LeftMarginLineNumbers).ToLower +
      ';background-color:' + TextEditorColorToHTML(LTextEditor.Colors.LeftMarginBackground).ToLower +
      ';width:' + LTextEditor.Canvas.TextWidth(StringOfChar('X', LEndLine.ToString.Length + 1)).ToString + 'px' +
      '">%d&nbsp;</span>'
    else
      '';

  LTextEditor.Highlighter.ResetRange;

  for var LIndex := LStartLine to LEndLine do
  begin
    if LIndex > 0 then
      LTextEditor.Highlighter.SetRange(LTextEditor.Lines.Ranges[LIndex - 1]);

    LTextEditor.Highlighter.SetLine(LTextEditor.Lines.ExpandedStrings[LIndex]);

    if LShowLineNumbers then
      LLineNumber := Format(LLineNumberHTML, [LIndex + 1]);

    LPreviousElement := '';
    LTextLine := '';
    LSpaces := '';

    while not LTextEditor.Highlighter.EndOfLine do
    begin
      LHighlighterAttribute := LTextEditor.Highlighter.TokenAttribute;
      LTextEditor.Highlighter.GetToken(LToken);

      LToken := TNetEncoding.HTML.Encode(LToken);

      if LToken = TCharacters.Space then
        LSpaces := LSpaces + '&nbsp;'
      else
      if Assigned(LHighlighterAttribute) then
      begin
        if not LPreviousElement.IsEmpty and (LPreviousElement <> LHighlighterAttribute.Element) then
          LTextLine := LTextLine + '</span>';

        if LPreviousElement <> LHighlighterAttribute.Element then
        begin
          GetStyle(LHighlighterAttribute, LStyle);
          LTextLine := LTextLine + '<span style="' + LStyle + '">';
        end;

        if not LSpaces.IsEmpty then
        begin
          LTextLine := LTextLine + LSpaces;
          LSpaces := '';
        end;

        LTextLine := LTextLine + LToken;
        LPreviousElement := LHighlighterAttribute.Element;
      end
      else
        LTextLine := LTextLine + LToken;

      LTextEditor.Highlighter.Next;
    end;

    FStringList.Add('<p style="box-sizing:border-box;margin:0px;' +
      'line-height:' + IntToStr(TextEditorFontSize(LTextEditor.Fonts.Text) + 1) + 'pt;' +
      'color:' + TextEditorColorToHTML(LTextEditor.Colors.EditorForeground).ToLower + ';' +
      'background-color:' + TextEditorColorToHTML(LTextEditor.Colors.EditorBackground).ToLower + '">' +
      LLineNumber + LTextLine + '<br style="box-sizing:border-box"></p>');
  end;
end;

procedure TTextEditorExportHTML.CreateFooter;
begin
  with FStringList do
  begin
    Add('</body>');
    Add('</html>');
  end;
end;

procedure TTextEditorExportHTML.SaveToStream(AStream: TStream; AEncoding: System.SysUtils.TEncoding);
begin
  CreateHTMLDocument;

  if not Assigned(AEncoding) then
    AEncoding := TEncoding.UTF8;

  FStringList.SaveToStream(AStream, AEncoding);
end;

function TTextEditorExportHTML.AsText(const AClipboardFormat: Boolean = False): string;
begin
  FStringList.Clear;

  if AClipboardFormat then
    CreateLines
  else
    CreateHTMLDocument;

  Result := FStringList.Text;
end;

end.
