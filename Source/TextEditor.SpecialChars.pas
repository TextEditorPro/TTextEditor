unit TextEditor.SpecialChars;

interface

uses
  System.Classes, Vcl.Graphics, TextEditor.SpecialChars.LineBreak, TextEditor.SpecialChars.Selection, TextEditor.Types;

type
  TTextEditorSpecialChars = class(TPersistent)
  strict private
    FColor: TColor;
    FLineBreak: TTextEditorSpecialCharsLineBreak;
    FOnChange: TNotifyEvent;
    FOptions: TTextEditorSpecialCharsOptions;
    FSelection: TTextEditorSpecialCharsSelection;
    FStyle: TTextEditorSpecialCharsStyle;
    FVisible: Boolean;
    procedure DoChange;
    procedure SetColor(const AValue: TColor);
    procedure SetLineBreak(const AValue: TTextEditorSpecialCharsLineBreak);
    procedure SetOnChange(const AValue: TNotifyEvent);
    procedure SetOptions(const AValue: TTextEditorSpecialCharsOptions);
    procedure SetSelection(const AValue: TTextEditorSpecialCharsSelection);
    procedure SetStyle(const AValue: TTextEditorSpecialCharsStyle);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TTextEditorSpecialCharsOption; const AEnabled: Boolean);
    property OnChange: TNotifyEvent read FOnChange write SetOnChange;
  published
    property Color: TColor read FColor write SetColor default clBlack;
    property LineBreak: TTextEditorSpecialCharsLineBreak read FLineBreak write SetLineBreak;
    property Options: TTextEditorSpecialCharsOptions read FOptions write SetOptions default [scoMiddleColor];
    property Selection: TTextEditorSpecialCharsSelection read FSelection write SetSelection;
    property Style: TTextEditorSpecialCharsStyle read FStyle write SetStyle;
    property Visible: Boolean read FVisible write SetVisible default False;
  end;

implementation

constructor TTextEditorSpecialChars.Create;
begin
  inherited;

  FColor := clBlack;
  FLineBreak := TTextEditorSpecialCharsLineBreak.Create;
  FSelection := TTextEditorSpecialCharsSelection.Create;
  FVisible := False;
  FOptions := [scoMiddleColor];
end;

destructor TTextEditorSpecialChars.Destroy;
begin
  FLineBreak.Free;
  FSelection.Free;
  inherited Destroy;
end;

procedure TTextEditorSpecialChars.SetOnChange(const AValue: TNotifyEvent);
begin
  FOnChange := AValue;
  FLineBreak.OnChange := FOnChange;
  FSelection.OnChange := FOnChange;
end;

procedure TTextEditorSpecialChars.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorSpecialChars) then
  with ASource as TTextEditorSpecialChars do
  begin
    Self.FColor := FColor;
    Self.FLineBreak.Assign(FLineBreak);
    Self.FOptions := FOptions;
    Self.FSelection.Assign(FSelection);
    Self.FVisible := FVisible;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorSpecialChars.SetOption(const AOption: TTextEditorSpecialCharsOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

procedure TTextEditorSpecialChars.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorSpecialChars.SetColor(const AValue: TColor);
begin
  if FColor <> AValue then
  begin
    FColor := AValue;
    DoChange;
  end;
end;

procedure TTextEditorSpecialChars.SetLineBreak(const AValue: TTextEditorSpecialCharsLineBreak);
begin
  FLineBreak.Assign(AValue);
end;

procedure TTextEditorSpecialChars.SetSelection(const AValue: TTextEditorSpecialCharsSelection);
begin
  FSelection.Assign(AValue);
end;

procedure TTextEditorSpecialChars.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    DoChange;
  end;
end;

procedure TTextEditorSpecialChars.SetStyle(const AValue: TTextEditorSpecialCharsStyle);
begin
  if FStyle <> AValue then
  begin
    FStyle := AValue;
    DoChange;
  end;
end;

procedure TTextEditorSpecialChars.SetOptions(const AValue: TTextEditorSpecialCharsOptions);
var
  LValue: TTextEditorSpecialCharsOptions;
begin
  LValue := AValue;
  if FOptions <> LValue then
  begin
    if scoTextColor in LValue then
      Exclude(LValue, scoMiddleColor);
    if scoMiddleColor in LValue then
      Exclude(LValue, scoTextColor);
    FOptions := LValue;
    DoChange;
  end;
end;

end.
