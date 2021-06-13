unit TextEditor.Caret.NonBlinking;

interface

uses
  System.Classes, TextEditor.Caret.NonBlinking.Colors;

type
  TTextEditorCaretNonBlinking = class(TPersistent)
  strict private
    FActive: Boolean;
    FColors: TTextEditorCaretNonBlinkingColors;
    FOnChange: TNotifyEvent;
    procedure DoChange;
    procedure SetActive(const AValue: Boolean);
    procedure SetColors(const AValue: TTextEditorCaretNonBlinkingColors);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Active: Boolean read FActive write SetActive default False;
    property Colors: TTextEditorCaretNonBlinkingColors read FColors write SetColors;
  end;

implementation

constructor TTextEditorCaretNonBlinking.Create;
begin
  inherited;

  FColors := TTextEditorCaretNonBlinkingColors.Create;
  FActive := False;
end;

destructor TTextEditorCaretNonBlinking.Destroy;
begin
  FColors.Free;

  inherited;
end;

procedure TTextEditorCaretNonBlinking.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCaretNonBlinking) then
  with ASource as TTextEditorCaretNonBlinking do
  begin
    Self.FColors.Assign(FColors);
    Self.FActive := FActive;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorCaretNonBlinking.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorCaretNonBlinking.SetActive(const AValue: Boolean);
begin
  if FActive <> AValue then
  begin
    FActive := AValue;
    DoChange;
  end;
end;

procedure TTextEditorCaretNonBlinking.SetColors(const AValue: TTextEditorCaretNonBlinkingColors);
begin
  FColors.Assign(AValue);
end;

end.
