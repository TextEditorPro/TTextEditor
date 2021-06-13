unit TextEditor.LeftMargin.LineNumbers;

interface

uses
  System.Classes, TextEditor.Types;

type
  TTextEditorLeftMarginLineNumbers = class(TPersistent)
  strict private
    FAutosizeDigitCount: Integer;
    FDigitCount: Integer;
    FOnChange: TNotifyEvent;
    FOptions: TTextEditorLeftMarginLineNumberOptions;
    FStartFrom: Integer;
    FVisible: Boolean;
    procedure DoChange;
    procedure SetDigitCount(const AValue: Integer);
    procedure SetOptions(const AValue: TTextEditorLeftMarginLineNumberOptions);
    procedure SetStartFrom(const AValue: Integer);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TTextEditorLeftMarginLineNumberOption; const AEnabled: Boolean);
    property AutosizeDigitCount: Integer read FAutosizeDigitCount write FAutosizeDigitCount;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property DigitCount: Integer read FDigitCount write SetDigitCount default 4;
    property Options: TTextEditorLeftMarginLineNumberOptions read FOptions write SetOptions default [lnoIntens];
    property StartFrom: Integer read FStartFrom write SetStartFrom default 1;
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

implementation

uses
  System.Math;

constructor TTextEditorLeftMarginLineNumbers.Create;
begin
  inherited;

  FAutosizeDigitCount := 4;
  FDigitCount := 4;
  FOptions := [lnoIntens];
  FStartFrom := 1;
  FVisible := True;
end;

procedure TTextEditorLeftMarginLineNumbers.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorLeftMarginLineNumbers) then
  with ASource as TTextEditorLeftMarginLineNumbers do
  begin
    Self.FAutosizeDigitCount := FAutosizeDigitCount;
    Self.FDigitCount := FDigitCount;
    Self.FOptions := FOptions;
    Self.FStartFrom := FStartFrom;
    Self.FVisible := FVisible;

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorLeftMarginLineNumbers.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorLeftMarginLineNumbers.SetOption(const AOption: TTextEditorLeftMarginLineNumberOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

procedure TTextEditorLeftMarginLineNumbers.SetDigitCount(const AValue: Integer);
var
  LValue: Integer;
begin
  LValue := EnsureRange(AValue, 2, 12);
  if FDigitCount <> LValue then
  begin
    FDigitCount := LValue;
    FAutosizeDigitCount := FDigitCount;
    DoChange
  end;
end;

procedure TTextEditorLeftMarginLineNumbers.SetOptions(const AValue: TTextEditorLeftMarginLineNumberOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;
    DoChange
  end;
end;

procedure TTextEditorLeftMarginLineNumbers.SetStartFrom(const AValue: Integer);
begin
  if FStartFrom <> AValue then
  begin
    FStartFrom := AValue;
    if FStartFrom < 0 then
      FStartFrom := 0;
    DoChange
  end;
end;

procedure TTextEditorLeftMarginLineNumbers.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    DoChange
  end;
end;

end.
