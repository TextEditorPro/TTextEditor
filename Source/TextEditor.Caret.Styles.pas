unit TextEditor.Caret.Styles;

interface

uses
  System.Classes, TextEditor.Types;

type
  TTextEditorCaretStyles = class(TPersistent)
  strict private
    FInsert: TTextEditorCaretStyle;
    FOnChange: TNotifyEvent;
    FOverwrite: TTextEditorCaretStyle;
    procedure DoChange;
    procedure SetInsert(const AValue: TTextEditorCaretStyle);
    procedure SetOverwrite(const AValue: TTextEditorCaretStyle);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Insert: TTextEditorCaretStyle read FInsert write SetInsert default csThinVerticalLine;
    property Overwrite: TTextEditorCaretStyle read FOverwrite write SetOverwrite default csThinVerticalLine;
  end;

implementation

constructor TTextEditorCaretStyles.Create;
begin
  inherited;

  FInsert := csThinVerticalLine;
  FOverwrite := csThinVerticalLine;
end;

procedure TTextEditorCaretStyles.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCaretStyles) then
  with ASource as TTextEditorCaretStyles do
  begin
    Self.FOverwrite := FOverwrite;
    Self.FInsert := FInsert;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorCaretStyles.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorCaretStyles.SetInsert(const AValue: TTextEditorCaretStyle);
begin
  if FInsert <> AValue then
  begin
    FInsert := AValue;
    DoChange;
  end;
end;

procedure TTextEditorCaretStyles.SetOverwrite(const AValue: TTextEditorCaretStyle);
begin
  if FOverwrite <> AValue then
  begin
    FOverwrite := AValue;
    DoChange;
  end;
end;

end.
