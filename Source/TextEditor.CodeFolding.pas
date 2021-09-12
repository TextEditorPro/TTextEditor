unit TextEditor.CodeFolding;

interface

uses
  System.Classes, System.SysUtils, Vcl.Graphics, TextEditor.CodeFolding.Colors, TextEditor.CodeFolding.Hint,
  TextEditor.TextFolding, TextEditor.Types;

const
  TEXTEDITOR_CODE_FOLDING_DEFAULT_OPTIONS = [cfoAutoPadding, cfoAutoWidth, cfoHighlightIndentGuides, cfoHighlightMatchingPair, cfoShowIndentGuides,
    cfoShowTreeLine, cfoExpandByHintClick];

type
  TTextEditorCodeFolding = class(TPersistent)
  strict private
    FCollapsedRowCharacterCount: Integer;
    FColors: TTextEditorCodeFoldingColors;
    FDelayInterval: Cardinal;
    FGuideLineStyle: TTextEditorCodeFoldingGuideLineStyle;
    FHint: TTextEditorCodeFoldingHint;
    FMarkStyle: TTextEditorCodeFoldingMarkStyle;
    FMouseOverHint: Boolean;
    FOnChange: TTextEditorCodeFoldingChangeEvent;
    FOptions: TTextEditorCodeFoldingOptions;
    FOutlining: Boolean;
    FPadding: Integer;
    FTextFolding: TTextEditorTextFolding;
    FVisible: Boolean;
    FWidth: Integer;
    procedure DoChange;
    procedure SetColors(const AValue: TTextEditorCodeFoldingColors);
    procedure SetGuideLineStyle(const AValue: TTextEditorCodeFoldingGuideLineStyle);
    procedure SetHint(const AValue: TTextEditorCodeFoldingHint);
    procedure SetMarkStyle(const AValue: TTextEditorCodeFoldingMarkStyle);
    procedure SetOptions(const AValue: TTextEditorCodeFoldingOptions);
    procedure SetPadding(const AValue: Integer);
    procedure SetTextFolding(const AValue: TTextEditorTextFolding);
    procedure SetVisible(const AValue: Boolean);
    procedure SetWidth(const AValue: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    function GetWidth: Integer;
    procedure Assign(ASource: TPersistent); override;
    procedure ChangeScale(const AMultiplier, ADivider: Integer);
    procedure SetOption(const AOption: TTextEditorCodeFoldingOption; const AEnabled: Boolean);
    property MouseOverHint: Boolean read FMouseOverHint write FMouseOverHint;
  published
    property CollapsedRowCharacterCount: Integer read FCollapsedRowCharacterCount write FCollapsedRowCharacterCount default 20;
    property Colors: TTextEditorCodeFoldingColors read FColors write SetColors;
    property DelayInterval: Cardinal read FDelayInterval write FDelayInterval default 300;
    property GuideLineStyle: TTextEditorCodeFoldingGuideLineStyle read FGuideLineStyle write SetGuideLineStyle default lsDot;
    property Hint: TTextEditorCodeFoldingHint read FHint write SetHint;
    property MarkStyle: TTextEditorCodeFoldingMarkStyle read FMarkStyle write SetMarkStyle default msSquare;
    property OnChange: TTextEditorCodeFoldingChangeEvent read FOnChange write FOnChange;
    property Options: TTextEditorCodeFoldingOptions read FOptions write SetOptions default TEXTEDITOR_CODE_FOLDING_DEFAULT_OPTIONS;
    property Outlining: Boolean read FOutlining write FOutlining default False;
    property Padding: Integer read FPadding write SetPadding default 2;
    property TextFolding: TTextEditorTextFolding read FTextFolding write SetTextFolding;
    property Visible: Boolean read FVisible write SetVisible default False;
    property Width: Integer read FWidth write SetWidth default 14;
  end;

implementation

uses
  Winapi.Windows, System.Math;

constructor TTextEditorCodeFolding.Create;
begin
  inherited;

  FVisible := False;
  FOptions := TEXTEDITOR_CODE_FOLDING_DEFAULT_OPTIONS;
  FGuideLineStyle := lsDot;
  FMarkStyle := msSquare;
  FColors := TTextEditorCodeFoldingColors.Create;
  FCollapsedRowCharacterCount := 20;
  FHint := TTextEditorCodeFoldingHint.Create;
  FPadding := 2;
  FWidth := 14;
  FDelayInterval := 300;
  FOutlining := False;
  FMouseOverHint := False;
  FTextFolding := TTextEditorTextFolding.Create;
end;

destructor TTextEditorCodeFolding.Destroy;
begin
  FColors.Free;
  FHint.Free;
  FTextFolding.Free;

  inherited;
end;

procedure TTextEditorCodeFolding.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCodeFolding) then
  with ASource as TTextEditorCodeFolding do
  begin
    Self.FVisible := FVisible;
    Self.FOptions := FOptions;
    Self.FColors.Assign(FColors);
    Self.FCollapsedRowCharacterCount := FCollapsedRowCharacterCount;
    Self.FHint.Assign(FHint);
    Self.FWidth := FWidth;
    Self.FDelayInterval := FDelayInterval;
    Self.FTextFolding.Assign(FTextFolding);
    Self.FPadding := FPadding;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorCodeFolding.ChangeScale(const AMultiplier, ADivider: Integer);
begin
  FWidth := MulDiv(FWidth, AMultiplier, ADivider);
  FPadding := MulDiv(FPadding, AMultiplier, ADivider);
  FHint.Indicator.Glyph.ChangeScale(AMultiplier, ADivider);
  DoChange;
end;

procedure TTextEditorCodeFolding.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(fcRefresh);
end;

procedure TTextEditorCodeFolding.SetGuideLineStyle(const AValue: TTextEditorCodeFoldingGuideLineStyle);
begin
  if FGuideLineStyle <> AValue then
  begin
    FGuideLineStyle := AValue;
    DoChange;
  end;
end;

procedure TTextEditorCodeFolding.SetMarkStyle(const AValue: TTextEditorCodeFoldingMarkStyle);
begin
  if FMarkStyle <> AValue then
  begin
    FMarkStyle := AValue;
    DoChange;
  end;
end;

procedure TTextEditorCodeFolding.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    if Assigned(FOnChange) then
      FOnChange(fcVisible);
  end;
end;

procedure TTextEditorCodeFolding.SetOptions(const AValue: TTextEditorCodeFoldingOptions);
begin
  FOptions := AValue;
  DoChange;
end;

procedure TTextEditorCodeFolding.SetOption(const AOption: TTextEditorCodeFoldingOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

procedure TTextEditorCodeFolding.SetColors(const AValue: TTextEditorCodeFoldingColors);
begin
  FColors.Assign(AValue);
end;

procedure TTextEditorCodeFolding.SetHint(const AValue: TTextEditorCodeFoldingHint);
begin
  FHint.Assign(AValue);
end;

procedure TTextEditorCodeFolding.SetTextFolding(const AValue: TTextEditorTextFolding);
begin
  FTextFolding.Assign(AValue);
end;

procedure TTextEditorCodeFolding.SetPadding(const AValue: Integer);
begin
  if FPadding <> AValue then
  begin
    FPadding := AValue;
    DoChange;
  end;
end;

function TTextEditorCodeFolding.GetWidth: Integer;
begin
  if FVisible then
    Result := FWidth
  else
    Result := 0;
end;

procedure TTextEditorCodeFolding.SetWidth(const AValue: Integer);
var
  LValue: Integer;
begin
  LValue := Max(0, AValue);
  if FWidth <> LValue then
  begin
    FWidth := LValue;
    DoChange;
  end;
end;

end.
