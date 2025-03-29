﻿unit TextEditor.Export.HTML;

interface

uses
  System.Classes, System.SysUtils, Vcl.Controls, Vcl.Graphics, TextEditor.Highlighter.Attributes;

type
  TTextEditorExportHTML = class(TObject)
  private
    FCharSet: string;
    FFont: TFont;
    FStringList: TStrings;
    FTextEditor: TCustomControl;
    procedure CreateFooter;
    procedure CreateHTMLDocument;
    procedure CreateHeader;
    procedure CreateLines;
    procedure GetStyle(const AHighlighterAttribute: TTextEditorHighlighterAttribute; var AStyle: string);
  public
    constructor Create(const ATextEditor: TCustomControl; const AFont: TFont; const ACharSet: string); overload;
    destructor Destroy; override;
    function AsText(const AClipboardFormat: Boolean = False): string;
    procedure SaveToStream(AStream: TStream; AEncoding: System.SysUtils.TEncoding);
  end;

implementation

uses
  Winapi.Windows, System.NetEncoding, System.UITypes, TextEditor, TextEditor.Consts, TextEditor.Types, TextEditor.Utils;

constructor TTextEditorExportHTML.Create(const ATextEditor: TCustomControl; const AFont: TFont; const ACharSet: string);
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
  FStringList.Add('<!DOCTYPE HTML>');
  FStringList.Add('');
  FStringList.Add('<html>');
  FStringList.Add('<head>');
	FStringList.Add('  <meta charset="' + FCharSet + '">');
  FStringList.Add('</head>');
  FStringList.Add('');
  FStringList.Add('<body>');
end;

procedure TTextEditorExportHTML.GetStyle(const AHighlighterAttribute: TTextEditorHighlighterAttribute; var AStyle: string);
begin
  AStyle := 'box-sizing:border-box;font-family:' + FFont.Name +
    ';font-size:' + IntToStr(FFont.Size) + 'pt' +
    ';color:' + ColorToHex(AHighlighterAttribute.Foreground).ToLower +
    ';background-color:' + ColorToHex(AHighlighterAttribute.Background).ToLower;

  if TFontStyle.fsBold in AHighlighterAttribute.FontStyles then
    AStyle := AStyle + ';font-weight:700'
  else
    AStyle := AStyle + ';font-weight:400';

  if TFontStyle.fsItalic in AHighlighterAttribute.FontStyles then
    AStyle := AStyle + ';font-style:italic';

  if TFontStyle.fsUnderline in AHighlighterAttribute.FontStyles then
    AStyle := AStyle + ';text-decoration:underline';

  if TFontStyle.fsStrikeOut in AHighlighterAttribute.FontStyles then
    AStyle := AStyle + ';text-decoration:line-through';
end;

procedure TTextEditorExportHTML.CreateLines;
var
  LIndex, LStartLine, LEndLine: Integer;
  LLineNumber, LLineNumberHTML, LTextLine, LSpaces, LToken, LStyle: string;
  LHighlighterAttribute: TTextEditorHighlighterAttribute;
  LPreviousElement: string;
  LTextEditor: TTextEditor;
  LShowLineNumbers: Boolean;
begin
  LTextEditor := FTextEditor as TTextEditor;

  LShowLineNumbers := eoShowLineNumbersInHTMLExport in LTextEditor.Options;
  LPreviousElement := '';

  if LTextEditor.SelectionAvailable then
  begin
    LStartLine := LTextEditor.SelectionBeginPosition.Line;
    LEndLine := LTextEditor.SelectionEndPosition.Line;
  end
  else
  begin
    LStartLine := 0;
    LEndLine := LTextEditor.Lines.Count - 1;
  end;

  LLineNumber := '';

  if LShowLineNumbers then
    LLineNumberHTML := '<span style="display:inline-block;text-align:right;text-valign:center;' +
      ';font-family:' + LTextEditor.Fonts.LineNumbers.Name +
      ';font-size:' + IntToStr(LTextEditor.Fonts.LineNumbers.Size) + 'pt' +
      ';color:' + ColorToHex(LTextEditor.Colors.LeftMarginLineNumbers).ToLower +
      ';background-color:' + ColorToHex(LTextEditor.Colors.LeftMarginBackground).ToLower +
      ';width:' + LTextEditor.Canvas.TextWidth(StringOfChar('X', LEndLine.ToString.Length + 1)).ToString + 'px' +
      '">%d&nbsp;</span>'
  else
    LLineNumberHTML := '';

  LTextEditor.Highlighter.ResetRange;

  for LIndex := LStartLine to LEndLine do
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
      'line-height:' + IntToStr(LTextEditor.Fonts.Text.Size + 1) + 'pt;' +
      'color:' + ColorToHex(LTextEditor.Colors.EditorForeground).ToLower + ';' +
      'background-color:' + ColorToHex(LTextEditor.Colors.EditorBackground).ToLower + '">' +
      LLineNumber + LTextLine + '<br style="box-sizing:border-box"></p>');
  end;
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
