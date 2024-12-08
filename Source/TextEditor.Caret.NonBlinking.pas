unit TextEditor.Caret.NonBlinking;

interface

uses
  System.Classes;

type
  TTextEditorCaretNonBlinking = class(TPersistent)
  strict private
    FActive: Boolean;
    FOnChange: TNotifyEvent;
    procedure DoChange;
    procedure SetActive(const AValue: Boolean);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Active: Boolean read FActive write SetActive default False;
  end;

implementation

constructor TTextEditorCaretNonBlinking.Create;
begin
  inherited;

  FActive := False;
end;

procedure TTextEditorCaretNonBlinking.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCaretNonBlinking) then
  with ASource as TTextEditorCaretNonBlinking do
  begin
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

end.
