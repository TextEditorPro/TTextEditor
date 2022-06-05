unit TextEditor.Highlighter.Colors;

interface

uses
  System.Classes, Vcl.Graphics, TextEditor.Types;

const
  DEFAULT_OPTIONS = [hcoUseColorThemeFontNames, hcoUseColorThemeFontSizes];

type
  PTextEditorHighlighterElement = ^TTextEditorHighlighterElement;
  TTextEditorHighlighterElement = record
    Background: TColor;
    Foreground: TColor;
    Name: string;
    FontStyles: TFontStyles;
  end;

  TTextEditorHighlighterColors = class(TObject)
  strict private
    FElements: TList;
    FFilename: string;
    FName: string;
    FOptions: TTextEditorHighlighterColorOptions;
    FOwner: TObject;
  public
    constructor Create(AOwner: TObject);
    destructor Destroy; override;
    function GetElement(const Name: string): PTextEditorHighlighterElement;
    procedure Clear;
    procedure LoadFromFile(const AFilename: string);
    procedure LoadFromStream(AStream: TStream);
    procedure SetOption(const AOption: TTextEditorHighlighterColorOption; const AEnabled: Boolean);
    property Filename: string read FFilename write FFilename;
    property Name: string read FName write FName;
    property Options: TTextEditorHighlighterColorOptions read FOptions write FOptions default DEFAULT_OPTIONS;
    property Styles: TList read FElements write FElements;
  end;

implementation

uses
  System.SysUtils, TextEditor.Highlighter, TextEditor.Highlighter.Import.JSON;

constructor TTextEditorHighlighterColors.Create(AOwner: TObject);
begin
  inherited Create;

  FOptions := DEFAULT_OPTIONS;
  FOwner := AOwner;
  FElements := TList.Create;
end;

destructor TTextEditorHighlighterColors.Destroy;
begin
  Clear;
  FElements.Free;

  inherited;
end;

procedure TTextEditorHighlighterColors.Clear;
var
  LIndex: Integer;
begin
  for LIndex := FElements.Count - 1 downto 0 do
    Dispose(PTextEditorHighlighterElement(FElements.Items[LIndex]));
  FElements.Clear;
end;

function TTextEditorHighlighterColors.GetElement(const Name: string): PTextEditorHighlighterElement;
var
  LIndex: Integer;
  LElement: PTextEditorHighlighterElement;
begin
  Result := nil;

  for LIndex := 0 to FElements.Count - 1 do
  begin
    LElement := PTextEditorHighlighterElement(FElements.Items[LIndex]);
    if LElement^.Name = Name then
      Exit(LElement);
  end;
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

  LHighlighter.UpdateColors;
  LHighlighter.Loading := False;
end;

procedure TTextEditorHighlighterColors.SetOption(const AOption: TTextEditorHighlighterColorOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Options := Options + [AOption]
  else
    Options := Options - [AOption];
end;

end.
