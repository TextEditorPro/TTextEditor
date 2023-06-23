unit TextEditor.Caret.MultiEdit;

interface

uses
  System.Classes, TextEditor.Types;

type
  TTextEditorCaretMultiEdit = class(TPersistent)
  strict private
    FActive: Boolean;
    FOnChange: TNotifyEvent;
    FOptions: TTextEditorCaretMultiEditOptions;
    FStyle: TTextEditorCaretStyle;
    procedure DoChange;
    procedure SetActive(const AValue: Boolean);
    procedure SetOptions(const AValue: TTextEditorCaretMultiEditOptions);
    procedure SetStyle(const AValue: TTextEditorCaretStyle);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TTextEditorCaretMultiEditOption; const AEnabled: Boolean);
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Active: Boolean read FActive write SetActive default True;
    property Options: TTextEditorCaretMultiEditOptions read FOptions write SetOptions default TTextEditorDefaultOptions.MultiEdit;
    property Style: TTextEditorCaretStyle read FStyle write SetStyle default csThinVerticalLine;
  end;

implementation

constructor TTextEditorCaretMultiEdit.Create;
begin
  inherited;

  FActive := True;
  FStyle := csThinVerticalLine;
  FOptions := TTextEditorDefaultOptions.MultiEdit;
end;

procedure TTextEditorCaretMultiEdit.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCaretMultiEdit) then
  with ASource as TTextEditorCaretMultiEdit do
  begin
    Self.FActive := FActive;
    Self.FOptions := FOptions;
    Self.FStyle := FStyle;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorCaretMultiEdit.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorCaretMultiEdit.SetActive(const AValue: Boolean);
begin
  if FActive <> AValue then
  begin
    FActive := AValue;
    DoChange;
  end;
end;

procedure TTextEditorCaretMultiEdit.SetStyle(const AValue: TTextEditorCaretStyle);
begin
  if FStyle <> AValue then
  begin
    FStyle := AValue;
    DoChange;
  end;
end;

procedure TTextEditorCaretMultiEdit.SetOptions(const AValue: TTextEditorCaretMultiEditOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;
    DoChange;
  end;
end;

procedure TTextEditorCaretMultiEdit.SetOption(const AOption: TTextEditorCaretMultiEditOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

end.
