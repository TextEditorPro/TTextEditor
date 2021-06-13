unit TextEditor.Tabs;

interface

uses
  System.Classes, TextEditor.Types;

const
  TEXTEDITOR_DEFAULT_TAB_OPTIONS = [toColumns, toSelectedBlockIndent];

type
  TTextEditorTabs = class(TPersistent)
  strict private
    FOnChange: TNotifyEvent;
    FOptions: TTextEditorTabOptions;
    FWantTabs: Boolean;
    FWidth: Integer;
    procedure DoChange;
    procedure SetOptions(const AValue: TTextEditorTabOptions);
    procedure SetWantTabs(const AValue: Boolean);
    procedure SetWidth(const AValue: Integer);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TTextEditorTabOption; const AEnabled: Boolean);
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Options: TTextEditorTabOptions read FOptions write SetOptions default TEXTEDITOR_DEFAULT_TAB_OPTIONS;
    property WantTabs: Boolean read FWantTabs write SetWantTabs default True;
    property Width: Integer read FWidth write SetWidth default 2;
  end;

implementation

uses
  System.Math;

constructor TTextEditorTabs.Create;
begin
  inherited;

  FOptions := TEXTEDITOR_DEFAULT_TAB_OPTIONS;
  FWantTabs := True;
  FWidth := 2;
end;

procedure TTextEditorTabs.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorTabs.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorTabs) then
  with ASource as TTextEditorTabs do
  begin
    Self.FOptions := FOptions;
    Self.FWantTabs := FWantTabs;
    Self.FWidth := FWidth;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorTabs.SetOption(const AOption: TTextEditorTabOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

procedure TTextEditorTabs.SetOptions(const AValue: TTextEditorTabOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;
    DoChange;
  end;
end;

procedure TTextEditorTabs.SetWidth(const AValue: Integer);
var
  LValue: Integer;
begin
  LValue := EnsureRange(AValue, 1, 256);

  if FWidth <> LValue then
  begin
    FWidth := LValue;
    DoChange;
  end;
end;

procedure TTextEditorTabs.SetWantTabs(const AValue: Boolean);
begin
  if FWantTabs <> AValue then
  begin
    FWantTabs := AValue;
    DoChange;
  end;
end;

end.
