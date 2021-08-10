unit TextEditor.Ruler;

interface

uses
  System.Classes, System.UITypes, Vcl.Graphics, TextEditor.Ruler.Colors, TextEditor.Types;

type
  TTextEditorRuler = class(TPersistent)
  strict private
    FColors: TTextEditorRulerColors;
    FCursor: TCursor;
    FFont: TFont;
    FHeight: Integer;
    FMoving: Boolean;
    FOnChange: TNotifyEvent;
    FOptions: TTextEditorRulerOptions;
    FVisible: Boolean;
    procedure DoChange;
    procedure SetColors(const AValue: TTextEditorRulerColors);
    procedure SetFont(AValue: TFont);
    procedure SetHeight(AValue: Integer);
    procedure SetOnChange(const AValue: TNotifyEvent);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Assign(ASource: TPersistent); override;
    procedure ChangeScale(const AMultiplier, ADivider: Integer);
    procedure SetOption(const AOption: TTextEditorRulerOption; const AEnabled: Boolean);
    property Moving: Boolean read FMoving write FMoving;
    property OnChange: TNotifyEvent read FOnChange write SetOnChange;
  published
    property Colors: TTextEditorRulerColors read FColors write SetColors;
    property Cursor: TCursor read FCursor write FCursor default crDefault;
    property Font: TFont read FFont write SetFont;
    property Height: Integer read FHeight write SetHeight default 18;
    property Options: TTextEditorRulerOptions read FOptions write FOptions default [roShowSelection];
    property Visible: Boolean read FVisible write SetVisible default False;
  end;

implementation

uses
  Winapi.Windows, TextEditor.Consts;

constructor TTextEditorRuler.Create;
begin
  inherited Create;

  FColors := TTextEditorRulerColors.Create;
  FCursor := crDefault;
  FFont := TFont.Create;
  FFont.Name := 'Courier New';
  FFont.Size := 8;
  FFont.Style := [];
  FFont.Color := TDefaultColors.LeftMarginFontForeground;
  FHeight := 18;
  FMoving := False;
  FVisible := False;
  FOptions := [roShowSelection];
end;

destructor TTextEditorRuler.Destroy;
begin
  FColors.Free;
  FFont.Free;

  inherited Destroy;
end;

procedure TTextEditorRuler.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorRuler) then
  with ASource as TTextEditorRuler do
  begin
    Self.FColors.Assign(FColors);
    Self.FCursor := FCursor;
    Self.FFont.Assign(FFont);
    Self.FHeight := FHeight;
    Self.FVisible := FVisible;
    Self.FOptions := FOptions;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorRuler.ChangeScale(const AMultiplier, ADivider: Integer);
begin
  FHeight := MulDiv(FHeight, AMultiplier, ADivider);
  FFont.Height := MulDiv(FFont.Height, AMultiplier, ADivider);
  DoChange;
end;

procedure TTextEditorRuler.SetOnChange(const AValue: TNotifyEvent);
begin
  FOnChange := AValue;

  FFont.OnChange := AValue;
end;

procedure TTextEditorRuler.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorRuler.SetColors(const AValue: TTextEditorRulerColors);
begin
  FColors.Assign(AValue);
end;

procedure TTextEditorRuler.SetFont(AValue: TFont);
begin
  FFont.Assign(AValue);
end;

procedure TTextEditorRuler.SetHeight(AValue: Integer);
begin
  if FHeight <> AValue then
  begin
    FHeight := AValue;
    DoChange
  end;
end;

procedure TTextEditorRuler.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    DoChange
  end;
end;

procedure TTextEditorRuler.SetOption(const AOption: TTextEditorRulerOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

end.
