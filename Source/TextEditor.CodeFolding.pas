unit TextEditor.CodeFolding;

interface

uses
  System.Classes, System.SysUtils, TextEditor.CodeFolding.GuideLines, TextEditor.CodeFolding.Hint,
  TextEditor.TextFolding, TextEditor.Types;

type
  TTextEditorCodeFolding = class(TPersistent)
  strict private
    FCollapsedRowCharacterCount: Integer;
    FDelayInterval: Cardinal;
    FGuideLines: TTextEditorCodeFoldingGuideLines;
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
    procedure SetGuideLines(const AValue: TTextEditorCodeFoldingGuideLines);
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
    property DelayInterval: Cardinal read FDelayInterval write FDelayInterval default 300;
    property GuideLines: TTextEditorCodeFoldingGuideLines read FGuideLines write SetGuideLines;
    property Hint: TTextEditorCodeFoldingHint read FHint write SetHint;
    property MarkStyle: TTextEditorCodeFoldingMarkStyle read FMarkStyle write SetMarkStyle default msSquare;
    property OnChange: TTextEditorCodeFoldingChangeEvent read FOnChange write FOnChange;
    property Options: TTextEditorCodeFoldingOptions read FOptions write SetOptions default TTextEditorDefaultOptions.CodeFolding;
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

  FCollapsedRowCharacterCount := 20;
  FDelayInterval := 300;
  FGuideLines := TTextEditorCodeFoldingGuideLines.Create;
  FHint := TTextEditorCodeFoldingHint.Create;
  FMarkStyle := msSquare;
  FMouseOverHint := False;
  FOptions := TTextEditorDefaultOptions.CodeFolding;
  FOutlining := False;
  FPadding := 2;
  FTextFolding := TTextEditorTextFolding.Create;
  FVisible := False;
  FWidth := 14;
end;

destructor TTextEditorCodeFolding.Destroy;
begin
  FGuideLines.Free;
  FHint.Free;
  FTextFolding.Free;

  inherited;
end;

procedure TTextEditorCodeFolding.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCodeFolding) then
  with ASource as TTextEditorCodeFolding do
  begin
    Self.FCollapsedRowCharacterCount := FCollapsedRowCharacterCount;
    Self.FDelayInterval := FDelayInterval;
    Self.FGuideLines.Assign(FGuideLines);
    Self.FHint.Assign(FHint);
    Self.FOptions := FOptions;
    Self.FPadding := FPadding;
    Self.FTextFolding.Assign(FTextFolding);
    Self.FVisible := FVisible;
    Self.FWidth := FWidth;

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorCodeFolding.ChangeScale(const AMultiplier, ADivider: Integer);
begin
  FGuideLines.Padding := MulDiv(FGuideLines.Padding, AMultiplier, ADivider);
  FHint.Indicator.Glyph.ChangeScale(AMultiplier, ADivider);
  FPadding := MulDiv(FPadding, AMultiplier, ADivider);
  FWidth := MulDiv(FWidth, AMultiplier, ADivider);

  DoChange;
end;

procedure TTextEditorCodeFolding.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(fcRefresh);
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

procedure TTextEditorCodeFolding.SetGuideLines(const AValue: TTextEditorCodeFoldingGuideLines);
begin
  FGuideLines.Assign(AValue);
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
