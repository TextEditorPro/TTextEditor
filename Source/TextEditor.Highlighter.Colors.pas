unit TextEditor.Highlighter.Colors;

interface

uses
  System.Classes, System.Generics.Collections, Vcl.Graphics;

type
  TTextEditorHighlighterElement = record
    Background: TColor;
    FontStyles: TFontStyles;
    Foreground: TColor;
    Name: string;
  end;

  TTextEditorElements = TDictionary<string, TTextEditorHighlighterElement>;

  TTextEditorHighlighterColors = class(TObject)
  strict private
    FElements: TTextEditorElements;
    FFilename: string;
    FName: string;
    FOwner: TObject;
  public
    constructor Create(AOwner: TObject);
    destructor Destroy; override;
    procedure LoadFromFile(const AFilename: string);
    procedure LoadFromStream(AStream: TStream);
    procedure SaveToFile(const AFilename: string);
    procedure SetDefaults;
    property Elements: TTextEditorElements read FElements write FElements;
    property Filename: string read FFilename write FFilename;
    property Name: string read FName write FName;
  end;

implementation

uses
  System.SysUtils, TextEditor, TextEditor.Highlighter, TextEditor.Highlighter.Export.JSON,
  TextEditor.Highlighter.Import.JSON;

constructor TTextEditorHighlighterColors.Create(AOwner: TObject);
begin
  inherited Create;

  FOwner := AOwner;
  FElements := TTextEditorElements.Create;
end;

destructor TTextEditorHighlighterColors.Destroy;
begin
  FElements.Clear;
  FreeAndNil(FElements);

  inherited;
end;

procedure TTextEditorHighlighterColors.LoadFromFile(const AFilename: string);
var
  LFileStream: TFileStream;
begin
  LFileStream := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyNone);
  try
    LoadFromStream(LFileStream);
  finally
    LFileStream.Free;
  end;
end;

procedure TTextEditorHighlighterColors.LoadFromStream(AStream: TStream);
var
  LHighlighter: TTextEditorHighlighter;
begin
  LHighlighter := TTextEditorHighlighter(FOwner);

  LHighlighter.Loading := True;

  with TTextEditorHighlighterImportJSON.Create(LHighlighter) do
  try
    ImportColorsFromStream(AStream);
  finally
    Free;
  end;

  LHighlighter.UpdateAttributes;
  LHighlighter.Loading := False;

  TCustomTextEditor(LHighlighter.Editor).ClearMinimapBuffer;
  LHighlighter.Editor.Invalidate;
end;

procedure TTextEditorHighlighterColors.SaveToFile(const AFilename: string);
var
  LTextEditor: TCustomTextEditor;
begin
  LTextEditor := TTextEditorHighlighter(FOwner).Editor as TCustomTextEditor;

  with TTextEditorHighlighterExportJSON.Create(LTextEditor) do
  try
    SaveThemeToFile(AFilename);
  finally
    Free;
  end;
end;

procedure TTextEditorHighlighterColors.SetDefaults;
var
  LHighlighter: TTextEditorHighlighter;
  LTextEditor: TCustomTextEditor;
begin
  LHighlighter := TTextEditorHighlighter(FOwner);
  LHighlighter.Loading := True;

  LTextEditor := TCustomTextEditor(LHighlighter.Editor);

  LTextEditor.Colors.SetDefaults;
  LTextEditor.Fonts.SetDefaults;
  LTextEditor.FontStyles.SetDefaults;

  with TTextEditorHighlighterImportJSON.Create(LHighlighter) do
  try
    AddElements;
  finally
    Free;
  end;

  LHighlighter.UpdateAttributes;
  LHighlighter.Loading := False;

  LTextEditor.Invalidate;
end;

end.
