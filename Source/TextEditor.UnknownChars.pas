unit TextEditor.UnknownChars;

interface

uses
  System.Classes;

type
  TTextEditorUnknownChars = class(TPersistent)
  strict private
    FOnChange: TNotifyEvent;
    FReplaceChar: AnsiChar;
    FVisible: Boolean;
    procedure DoChange;
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property ReplaceChar: AnsiChar read FReplaceChar write FReplaceChar default '?';
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

implementation

constructor TTextEditorUnknownChars.Create;
begin
  inherited;

  FReplaceChar := '?';
  FVisible := True;
end;

procedure TTextEditorUnknownChars.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorUnknownChars) then
  with ASource as TTextEditorUnknownChars do
  begin
    Self.FReplaceChar := FReplaceChar;
    Self.FVisible := FVisible;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorUnknownChars.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorUnknownChars.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    DoChange;
  end;
end;

end.
