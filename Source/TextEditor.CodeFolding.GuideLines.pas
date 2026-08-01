unit TextEditor.CodeFolding.GuideLines;

interface

uses
  System.Classes, TextEditor.Types;

type
  TTextEditorCodeFoldingGuideLines = class(TPersistent)
  strict private
    FHighlightStyle: TTextEditorCodeFoldingGuideLineStyle;
    FOnChange: TNotifyEvent;
    FOptions: TTextEditorCodeFoldingGuideLineOptions;
    FPadding: Integer;
    FStyle: TTextEditorCodeFoldingGuideLineStyle;
    FVisible: Boolean;
    procedure DoChange;
    procedure SetHighlightStyle(const AValue: TTextEditorCodeFoldingGuideLineStyle);
    procedure SetOptions(const AValue: TTextEditorCodeFoldingGuideLineOptions);
    procedure SetPadding(const AValue: Integer);
    procedure SetStyle(const AValue: TTextEditorCodeFoldingGuideLineStyle);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TTextEditorCodeFoldingGuideLineOption; const AEnabled: Boolean);
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property HighlightStyle: TTextEditorCodeFoldingGuideLineStyle read FHighlightStyle write SetHighlightStyle default lsDash;
    property Options: TTextEditorCodeFoldingGuideLineOptions read FOptions write SetOptions default TTextEditorDefaultOptions.CodeFoldingGuideLines;
    property Padding: Integer read FPadding write SetPadding default 3;
    property Style: TTextEditorCodeFoldingGuideLineStyle read FStyle write SetStyle default lsDash;
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

implementation

constructor TTextEditorCodeFoldingGuideLines.Create;
begin
  inherited;

  FHighlightStyle := lsDash;
  FOptions := TTextEditorDefaultOptions.CodeFoldingGuideLines;
  FPadding := 3;
  FStyle := lsDash;
  FVisible := True;
end;

procedure TTextEditorCodeFoldingGuideLines.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCodeFoldingGuideLines) then
  with ASource as TTextEditorCodeFoldingGuideLines do
  begin
    Self.FHighlightStyle := FHighlightStyle;
    Self.FOptions := FOptions;
    Self.FPadding := FPadding;
    Self.FStyle := FStyle;
    Self.FVisible := FVisible;

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorCodeFoldingGuideLines.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorCodeFoldingGuideLines.SetHighlightStyle(const AValue: TTextEditorCodeFoldingGuideLineStyle);
begin
  if FHighlightStyle <> AValue then
  begin
    FHighlightStyle := AValue;

    DoChange;
  end;
end;

procedure TTextEditorCodeFoldingGuideLines.SetOption(const AOption: TTextEditorCodeFoldingGuideLineOption; const AEnabled: Boolean);
var
  LOptions: TTextEditorCodeFoldingGuideLineOptions;
begin
  LOptions := FOptions;

  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);

  if FOptions <> LOptions then
    DoChange;
end;

procedure TTextEditorCodeFoldingGuideLines.SetOptions(const AValue: TTextEditorCodeFoldingGuideLineOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;

    DoChange;
  end;
end;

procedure TTextEditorCodeFoldingGuideLines.SetPadding(const AValue: Integer);
begin
  if FPadding <> AValue then
  begin
    FPadding := AValue;

    DoChange;
  end;
end;

procedure TTextEditorCodeFoldingGuideLines.SetStyle(const AValue: TTextEditorCodeFoldingGuideLineStyle);
begin
  if FStyle <> AValue then
  begin
    FStyle := AValue;

    DoChange;
  end;
end;

procedure TTextEditorCodeFoldingGuideLines.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;

    DoChange;
  end;
end;

end.
