unit TextEditor.Highlighter.Colors;

interface

uses
  System.Classes, Vcl.Graphics;

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
    FFilename: string;
    FElements: TList;
    FName: string;
    FOwner: TObject;
  public
    constructor Create(AOwner: TObject);
    destructor Destroy; override;

    function GetElement(const Name: string): PTextEditorHighlighterElement;
    procedure Clear;
    procedure LoadFromStream(AStream: TStream; const AScaleFontHeight: Boolean = False);
    property Filename: string read FFilename write FFilename;
    property Name: string read FName write FName;
    property Styles: TList read FElements write FElements;
  end;

implementation

uses
  System.SysUtils, TextEditor.Highlighter, TextEditor.Highlighter.Import.JSON;

constructor TTextEditorHighlighterColors.Create(AOwner: TObject);
begin
  inherited Create;

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

procedure TTextEditorHighlighterColors.LoadFromStream(AStream: TStream; const AScaleFontHeight: Boolean = False);
var
  LHighlighter: TTextEditorHighlighter;
begin
  LHighlighter := TTextEditorHighlighter(FOwner);

  LHighlighter.Loading := True;
  with TTextEditorHighlighterImportJSON.Create(LHighlighter) do
  try
    ImportColorsFromStream(AStream, AScaleFontHeight);
  finally
    Free;
  end;
  LHighlighter.UpdateColors;
  LHighlighter.Loading := False;
end;

end.
