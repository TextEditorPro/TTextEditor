unit FMX.TextEditor.Highlighter.Colors;

interface

uses
  System.Classes, System.Generics.Collections, System.UITypes;

type
  TTextEditorHighlighterElement = record
    Background: TAlphaColor;
    FontStyles: TFontStyles;
    Foreground: TAlphaColor;
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
    procedure AddElements;
    procedure BeginUpdate;
    procedure EndUpdate;
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
  System.SysUtils, FMX.TextEditor, FMX.TextEditor.Highlighter, FMX.TextEditor.Highlighter.Export.JSON,
  FMX.TextEditor.Highlighter.Import.JSON, FMX.TextEditor.Types;

constructor TTextEditorHighlighterColors.Create(AOwner: TObject);
begin
  inherited Create;

  FOwner := AOwner;
  FElements := TTextEditorElements.Create;
end;

destructor TTextEditorHighlighterColors.Destroy;
begin
  FElements.Clear;
  FElements.Free;

  inherited;
end;

procedure TTextEditorHighlighterColors.LoadFromFile(const AFilename: string);
begin
  var LFileStream := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyNone);
  try
    LoadFromStream(LFileStream);
  finally
    LFileStream.Free;
  end;
end;

procedure TTextEditorHighlighterColors.BeginUpdate;
begin
  var LHighlighter := TTextEditorHighlighter(FOwner);

  LHighlighter.Loading := True;
end;

procedure TTextEditorHighlighterColors.EndUpdate;
begin
  var LHighlighter := TTextEditorHighlighter(FOwner);

  AddElements;

  LHighlighter.UpdateAttributes;
  LHighlighter.Loading := False;

  with TCustomTextEditor(LHighlighter.Editor) do
  begin
    ClearMinimapBuffer;
    SizeOrFontChanged;
  end;

  LHighlighter.Editor.Repaint;
end;

procedure TTextEditorHighlighterColors.LoadFromStream(AStream: TStream);
begin
  var LHighlighter := TTextEditorHighlighter(FOwner);

  BeginUpdate;

  AStream.Position := 0;

  var LEditor := TCustomTextEditor(LHighlighter.Editor);
  var LZoom := LEditor.ZoomPercentage;

  LEditor.ZoomPercentage := TTextEditorDefaults.ZoomPercentage;

  with TTextEditorHighlighterImportJSON.Create(TTextEditorHighlighter(FOwner)) do
  try
    ImportColorsFromStream(AStream);
  finally
    Free;
  end;

  LEditor.ZoomPercentage := LZoom;

  EndUpdate;
end;

procedure TTextEditorHighlighterColors.SaveToFile(const AFilename: string);
begin
  var LTextEditor := TTextEditorHighlighter(FOwner).Editor as TCustomTextEditor;

  with TTextEditorHighlighterExportJSON.Create(LTextEditor) do
  try
    SaveThemeToFile(AFilename);
  finally
    Free;
  end;
end;

procedure TTextEditorHighlighterColors.SetDefaults;
begin
  var LHighlighter := TTextEditorHighlighter(FOwner);

  LHighlighter.Loading := True;

  var LTextEditor := TCustomTextEditor(LHighlighter.Editor);

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

  LTextEditor.Repaint;
end;

procedure TTextEditorHighlighterColors.AddElements;

  function GetElement(const AName: string; const ABackground: TAlphaColor; const AForeground: TAlphaColor; const AFontStyles: TFontStyles): TTextEditorHighlighterElement;
  begin
    Result.Name := AName;
    Result.Background := ABackground;
    Result.Foreground := AForeground;
    Result.FontStyles := AFontStyles;
  end;

begin
  var LHighlighter := TTextEditorHighlighter(FOwner);
  var LEditor := LHighlighter.Editor as TCustomTextEditor;

  if csDesigning in LEditor.ComponentState then
    Exit;

  FElements.Clear;

  with FElements do
  begin
    Add(TElement.AssemblerComment, GetElement(TElement.AssemblerComment, LEditor.Colors.EditorAssemblerCommentBackground,
      LEditor.Colors.EditorAssemblerCommentForeground, LEditor.FontStyles.AssemblerComment));
    Add(TElement.AssemblerReservedWord, GetElement(TElement.AssemblerReservedWord, LEditor.Colors.EditorAssemblerReservedWordBackground,
      LEditor.Colors.EditorAssemblerReservedWordForeground, LEditor.FontStyles.AssemblerReservedWord));
    Add(TElement.Attribute, GetElement(TElement.Attribute, LEditor.Colors.EditorAttributeBackground,
      LEditor.Colors.EditorAttributeForeground, LEditor.FontStyles.Attribute));
    Add(TElement.Character, GetElement(TElement.Character, LEditor.Colors.EditorCharacterBackground,
      LEditor.Colors.EditorCharacterForeground, LEditor.FontStyles.Character));
    Add(TElement.Comment, GetElement(TElement.Comment, LEditor.Colors.EditorCommentBackground, LEditor.Colors.EditorCommentForeground,
      LEditor.FontStyles.Comment));
    Add(TElement.Directive, GetElement(TElement.Directive, LEditor.Colors.EditorDirectiveBackground,
      LEditor.Colors.EditorDirectiveForeground, LEditor.FontStyles.Directive));
    Add(TElement.Editor, GetElement(TElement.Editor, LEditor.Colors.EditorBackground, LEditor.Colors.EditorForeground,
      LEditor.FontStyles.Editor));
    Add(TElement.HexNumber, GetElement(TElement.HexNumber, LEditor.Colors.EditorHexNumberBackground,
      LEditor.Colors.EditorHexNumberForeground, LEditor.FontStyles.HexNumber));
    Add(TElement.HighlightedBlock, GetElement(TElement.HighlightedBlock, LEditor.Colors.EditorHighlightedBlockBackground,
      LEditor.Colors.EditorHighlightedBlockForeground, LEditor.FontStyles.HighlightedBlock));
    Add(TElement.HighlightedBlockSymbol, GetElement(TElement.HighlightedBlockSymbol, LEditor.Colors.EditorHighlightedBlockSymbolBackground,
      LEditor.Colors.EditorHighlightedBlockSymbolForeground, LEditor.FontStyles.HighlightedBlockSymbol));
    Add(TElement.LogicalOperator, GetElement(TElement.LogicalOperator, LEditor.Colors.EditorLogicalOperatorBackground,
      LEditor.Colors.EditorLogicalOperatorForeground, LEditor.FontStyles.LogicalOperator));
    Add(TElement.Method, GetElement(TElement.Method, LEditor.Colors.EditorMethodBackground,
      LEditor.Colors.EditorMethodForeground, LEditor.FontStyles.Method));
    Add(TElement.MethodItalic, GetElement(TElement.MethodItalic, LEditor.Colors.EditorMethodItalicBackground,
      LEditor.Colors.EditorMethodItalicForeground, LEditor.FontStyles.MethodItalic));
    Add(TElement.NameOfMethod, GetElement(TElement.NameOfMethod, LEditor.Colors.EditorMethodNameBackground,
      LEditor.Colors.EditorMethodNameForeground, LEditor.FontStyles.NameOfMethod));
    Add(TElement.Number, GetElement(TElement.Number, LEditor.Colors.EditorNumberBackground,
      LEditor.Colors.EditorNumberForeground, LEditor.FontStyles.Number));
    Add(TElement.ReservedWord, GetElement(TElement.ReservedWord, LEditor.Colors.EditorReservedWordBackground,
      LEditor.Colors.EditorReservedWordForeground, LEditor.FontStyles.ReservedWord));
    Add(TElement.StringOfCharacters, GetElement(TElement.StringOfCharacters, LEditor.Colors.EditorStringBackground,
      LEditor.Colors.EditorStringForeground, LEditor.FontStyles.StringOfCharacters));
    Add(TElement.Symbol, GetElement(TElement.Symbol, LEditor.Colors.EditorSymbolBackground,
      LEditor.Colors.EditorSymbolForeground, LEditor.FontStyles.Symbol));
    Add(TElement.Value, GetElement(TElement.Value, LEditor.Colors.EditorValueBackground,
      LEditor.Colors.EditorValueForeground, LEditor.FontStyles.Value));
    Add(TElement.WebLink, GetElement(TElement.WebLink, LEditor.Colors.EditorWebLinkBackground,
      LEditor.Colors.EditorWebLinkForeground, LEditor.FontStyles.WebLink));
  end;
end;

end.
