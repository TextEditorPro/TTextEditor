unit TextEditor.LeftMargin.Colors;

interface

uses
  System.Classes, Vcl.Graphics, TextEditor.Consts;

type
  TTextEditorLeftMarginColors = class(TPersistent)
  strict private
    FActiveLineBackground: TColor;
    FActiveLineBackgroundUnfocused: TColor;
    FActiveLineNumber: TColor;
    FBackground: TColor;
    FBookmarkBackground: TColor;
    FBookmarkPanelBackground: TColor;
    FBorder: TColor;
    FLineNumberLine: TColor;
    FLineStateModified: TColor;
    FLineStateNormal: TColor;
    FMarkDefaultBackground: TColor;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property ActiveLineBackground: TColor read FActiveLineBackground write FActiveLineBackground default clActiveLineBackground;
    property ActiveLineBackgroundUnfocused: TColor read FActiveLineBackgroundUnfocused write FActiveLineBackgroundUnfocused default clActiveLineBackgroundUnfocused;
    property ActiveLineNumber: TColor read FActiveLineNumber write FActiveLineNumber default clNone;
    property Background: TColor read FBackground write FBackground default clLeftMarginBackground;
    property BookmarkBackground: TColor read FBookmarkBackground write FBookmarkBackground default clNone;
    property BookmarkPanelBackground: TColor read FBookmarkPanelBackground write FBookmarkPanelBackground default clLeftMarginBackground;
    property Border: TColor read FBorder write FBorder default clLeftMarginBackground;
    property LineNumberLine: TColor read FLineNumberLine write FLineNumberLine default clLeftMarginFontForeground;
    property LineStateModified: TColor read FLineStateModified write FLineStateModified default clYellow;
    property LineStateNormal: TColor read FLineStateNormal write FLineStateNormal default clLime;
    property MarkDefaultBackground: TColor read FMarkDefaultBackground write FMarkDefaultBackground default clNone;
  end;

implementation

constructor TTextEditorLeftMarginColors.Create;
begin
  inherited;

  FActiveLineBackground := clActiveLineBackground;
  FActiveLineBackgroundUnfocused := clActiveLineBackgroundUnfocused;
  FActiveLineNumber := clNone;
  FBackground := clLeftMarginBackground;
  FBookmarkBackground := clNone;
  FBookmarkPanelBackground := clLeftMarginBackground;
  FBorder := clLeftMarginBackground;
  FLineNumberLine := clLeftMarginFontForeground;
  FLineStateModified := clYellow;
  FLineStateNormal := clLime;
  FMarkDefaultBackground := clNone;
end;

procedure TTextEditorLeftMarginColors.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorLeftMarginColors) then
  with ASource as TTextEditorLeftMarginColors do
  begin
    Self.FActiveLineBackground := FActiveLineBackground;
    Self.FActiveLineBackgroundUnfocused := FActiveLineBackgroundUnfocused;
    Self.FBackground := FBackground;
    Self.FBookmarkPanelBackground := FBookmarkPanelBackground;
    Self.FBorder := FBorder;
    Self.FLineNumberLine := FLineNumberLine;
    Self.FLineStateModified := FLineStateModified;
    Self.FLineStateNormal := FLineStateNormal;
    Self.FMarkDefaultBackground := FMarkDefaultBackground;
  end
  else
    inherited Assign(ASource);
end;

end.
