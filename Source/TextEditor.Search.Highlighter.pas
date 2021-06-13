unit TextEditor.Search.Highlighter;

interface

uses
  System.Classes, Vcl.Graphics, TextEditor.Search.Highlighter.Colors, TextEditor.Types;

type
  TTextEditorSearchHighlighter = class(TPersistent)
  strict private
    FColors: TTextEditorSearchColors;
    FOnChange: TTextEditorSearchChangeEvent;
    procedure SetColors(const AValue: TTextEditorSearchColors);
    procedure DoChange;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
  published
    property Colors: TTextEditorSearchColors read FColors write SetColors;
    property OnChange: TTextEditorSearchChangeEvent read FOnChange write FOnChange;
  end;

implementation

constructor TTextEditorSearchHighlighter.Create;
begin
  inherited;

  FColors := TTextEditorSearchColors.Create;
end;

destructor TTextEditorSearchHighlighter.Destroy;
begin
  FColors.Free;
  inherited;
end;

procedure TTextEditorSearchHighlighter.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorSearchHighlighter) then
  with ASource as TTextEditorSearchHighlighter do
  begin
    Self.FColors.Assign(Colors);
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorSearchHighlighter.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(scRefresh);
end;

procedure TTextEditorSearchHighlighter.SetColors(const AValue: TTextEditorSearchColors);
begin
  FColors.Assign(AValue);
end;

end.
