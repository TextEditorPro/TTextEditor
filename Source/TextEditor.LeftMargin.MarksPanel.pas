unit TextEditor.LeftMargin.MarksPanel;

interface

uses
  System.Classes, Vcl.Graphics, TextEditor.Types;

type
  TTextEditorLeftMarginMarksPanel = class(TPersistent)
  strict private
    FOnChange: TNotifyEvent;
    FOptions: TTextEditorLeftMarginBookmarkPanelOptions;
    FVisible: Boolean;
    FWidth: Integer;
    procedure DoChange;
    procedure SetWidth(const AValue: Integer);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure ChangeScale(const AMultiplier, ADivider: Integer);
    procedure SetOption(const AOption: TTextEditorLeftMarginBookmarkPanelOption; const AEnabled: Boolean);
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Options: TTextEditorLeftMarginBookmarkPanelOptions read FOptions write FOptions default [bpoToggleBookmarkByClick];
    property Visible: Boolean read FVisible write SetVisible default True;
    property Width: Integer read FWidth write SetWidth default 20;
  end;

implementation

uses
  Winapi.Windows, System.Math;

constructor TTextEditorLeftMarginMarksPanel.Create;
begin
  inherited;

  FWidth := 20;
  FOptions := [bpoToggleBookmarkByClick];
  FVisible := True;
end;

procedure TTextEditorLeftMarginMarksPanel.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorLeftMarginMarksPanel) then
  with ASource as TTextEditorLeftMarginMarksPanel do
  begin
    Self.FVisible := FVisible;
    Self.FWidth := FWidth;
    if Assigned(Self.FOnChange) then
      Self.FOnChange(Self);
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorLeftMarginMarksPanel.ChangeScale(const AMultiplier, ADivider: Integer);
begin
  FWidth := MulDiv(FWidth, AMultiplier, ADivider);
end;

procedure TTextEditorLeftMarginMarksPanel.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorLeftMarginMarksPanel.SetWidth(const AValue: Integer);
var
  LValue: Integer;
begin
  LValue := Max(0, AValue);
  if FWidth <> LValue then
  begin
    FWidth := LValue;
    DoChange
  end;
end;

procedure TTextEditorLeftMarginMarksPanel.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    DoChange
  end;
end;

procedure TTextEditorLeftMarginMarksPanel.SetOption(const AOption: TTextEditorLeftMarginBookmarkPanelOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

end.
