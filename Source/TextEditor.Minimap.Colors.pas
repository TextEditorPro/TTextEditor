unit TextEditor.Minimap.Colors;

interface

uses
  System.Classes, System.UITypes, TextEditor.Consts;

type
  TTextEditorMinimapColors = class(TPersistent)
  strict private
    FBackground: TColor;
    FBookmark: TColor;
    FVisibleLines: TColor;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Background: TColor read FBackground write FBackground default TColors.SysNone;
    property Bookmark: TColor read FBookmark write FBookmark default TDefaultColors.MinimapBookmark;
    property VisibleLines: TColor read FVisibleLines write FVisibleLines default TDefaultColors.MinimapVisibleLines;
  end;

implementation

constructor TTextEditorMinimapColors.Create;
begin
  inherited;

  FBackground := TColors.SysNone;
  FBookmark := TDefaultColors.MinimapBookmark;
  FVisibleLines := TDefaultColors.MinimapVisibleLines;
end;

procedure TTextEditorMinimapColors.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorMinimapColors) then
  with ASource as TTextEditorMinimapColors do
  begin
    Self.FBackground := FBackground;
    Self.FBookmark := FBookmark;
    Self.FVisibleLines := FVisibleLines;
  end
  else
    inherited Assign(ASource);
end;

end.
