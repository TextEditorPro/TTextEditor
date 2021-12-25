unit TextEditor.Highlighter.Attributes;

interface

uses
  Winapi.Windows, System.Classes, System.UITypes, TextEditor.Consts;

type
  TTextEditorHighlighterAttribute = class(TPersistent)
  strict private
    FBackground: TColor;
    FElement: string;
    FEscapeChar: Char;
    FFontStyles: TFontStyles;
    FForeground: TColor;
    FName: string;
    FParentBackground: Boolean;
    FParentForeground: Boolean;
  public
    constructor Create(const AttributeName: string);
    procedure Assign(ASource: TPersistent); override;
  public
    property Name: string read FName write FName;
    property Background: TColor read FBackground write FBackground default TColors.SysNone;
    property Element: string read FElement write FElement;
    property EscapeChar: Char read FEscapeChar write FEscapeChar default TControlCharacters.Null;
    property FontStyles: TFontStyles read FFontStyles write FFontStyles;
    property Foreground: TColor read FForeground write FForeground default TColors.SysNone;
    property ParentBackground: Boolean read FParentBackground write FParentBackground;
    property ParentForeground: Boolean read FParentForeground write FParentForeground;
  end;

implementation

uses
  System.SysUtils;

constructor TTextEditorHighlighterAttribute.Create(const AttributeName: string);
begin
  inherited Create;

  FBackground := TColors.SysNone;
  FForeground := TColors.SysNone;
  FName := AttributeName;
  FEscapeChar := TControlCharacters.Null;
end;

procedure TTextEditorHighlighterAttribute.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorHighlighterAttribute) then
  with ASource as TTextEditorHighlighterAttribute do
  begin
    Self.FName := FName;
    Self.FBackground := FBackground;
    Self.FForeground := FForeground;
    Self.FFontStyles := FFontStyles;
    Self.FParentForeground := ParentForeground;
    Self.FParentBackground := ParentBackground;
  end
  else
    inherited Assign(ASource);
end;

end.
