unit TextEditor.Caret.Offsets;

interface

uses
  System.Classes;

type
  TTextEditorCaretOffsets = class(TPersistent)
  strict private
    FLeft: Integer;
    FOnChange: TNotifyEvent;
    FTop: Integer;
    procedure DoChange(const ASender: TObject);
    procedure SetLeft(const AValue: Integer);
    procedure SetTop(const AValue: Integer);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Left: Integer read FLeft write SetLeft default 0;
    property Top: Integer read FTop write SetTop default 0;
  end;

implementation

constructor TTextEditorCaretOffsets.Create;
begin
  inherited;

  FLeft := 0;
  FTop := 0;
end;

procedure TTextEditorCaretOffsets.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCaretOffsets) then
  with ASource as TTextEditorCaretOffsets do
  begin
    Self.FLeft := FLeft;
    Self.FTop := FTop;
    Self.DoChange(Self);
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorCaretOffsets.DoChange(const ASender: TObject);
begin
  if Assigned(FOnChange) then
    FOnChange(ASender);
end;

procedure TTextEditorCaretOffsets.SetLeft(const AValue: Integer);
begin
  if FLeft <> AValue then
  begin
    FLeft := AValue;
    DoChange(Self);
  end;
end;

procedure TTextEditorCaretOffsets.SetTop(const AValue: Integer);
begin
  if FTop <> AValue then
  begin
    FTop := AValue;
    DoChange(Self);
  end;
end;

end.
