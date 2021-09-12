unit TextEditor.LeftMargin.Colors;

interface

uses
  System.Classes, System.UITypes, TextEditor.Consts;

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
    property ActiveLineBackground: TColor read FActiveLineBackground write FActiveLineBackground default TDefaultColors.ActiveLineBackground;
    property ActiveLineBackgroundUnfocused: TColor read FActiveLineBackgroundUnfocused write FActiveLineBackgroundUnfocused default TDefaultColors.ActiveLineBackgroundUnfocused;
    property ActiveLineNumber: TColor read FActiveLineNumber write FActiveLineNumber default TColors.SysNone;
    property Background: TColor read FBackground write FBackground default TDefaultColors.LeftMarginBackground;
    property BookmarkBackground: TColor read FBookmarkBackground write FBookmarkBackground default TColors.SysNone;
    property BookmarkPanelBackground: TColor read FBookmarkPanelBackground write FBookmarkPanelBackground default TDefaultColors.LeftMarginBackground;
    property Border: TColor read FBorder write FBorder default TDefaultColors.LeftMarginBackground;
    property LineNumberLine: TColor read FLineNumberLine write FLineNumberLine default TDefaultColors.LeftMarginFontForeground;
    property LineStateModified: TColor read FLineStateModified write FLineStateModified default TColors.Yellow;
    property LineStateNormal: TColor read FLineStateNormal write FLineStateNormal default TColors.Lime;
    property MarkDefaultBackground: TColor read FMarkDefaultBackground write FMarkDefaultBackground default TColors.SysNone;
  end;

implementation

constructor TTextEditorLeftMarginColors.Create;
begin
  inherited;

  FActiveLineBackground := TDefaultColors.ActiveLineBackground;
  FActiveLineBackgroundUnfocused := TDefaultColors.ActiveLineBackgroundUnfocused;
  FActiveLineNumber := TColors.SysNone;
  FBackground := TDefaultColors.LeftMarginBackground;
  FBookmarkBackground := TColors.SysNone;
  FBookmarkPanelBackground := TDefaultColors.LeftMarginBackground;
  FBorder := TDefaultColors.LeftMarginBackground;
  FLineNumberLine := TDefaultColors.LeftMarginFontForeground;
  FLineStateModified := TColors.Yellow;
  FLineStateNormal := TColors.Lime;
  FMarkDefaultBackground := TColors.SysNone;
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
