unit TextEditor.Caret;

interface

uses
  System.Classes, System.Types, TextEditor.Caret.MultiEdit, TextEditor.Caret.NonBlinking, TextEditor.Caret.Offsets,
  TextEditor.Caret.Styles, TextEditor.Types;

type
  TTextEditorCaret = class(TPersistent)
  strict private
    FMultiEdit: TTextEditorCaretMultiEdit;
    FNonBlinking: TTextEditorCaretNonBlinking;
    FOffsets: TTextEditorCaretOffsets;
    FOnChange: TNotifyEvent;
    FOptions: TTextEditorCaretOptions;
    FStyles: TTextEditorCaretStyles;
    FVisible: Boolean;
    procedure DoChange(const ASender: TObject);
    procedure SetMultiEdit(const AValue: TTextEditorCaretMultiEdit);
    procedure SetNonBlinking(const AValue: TTextEditorCaretNonBlinking);
    procedure SetOffsets(const AValue: TTextEditorCaretOffsets);
    procedure SetOnChange(const AValue: TNotifyEvent);
    procedure SetOptions(const AValue: TTextEditorCaretOptions);
    procedure SetStyles(const AValue: TTextEditorCaretStyles);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TTextEditorCaretOption; const AEnabled: Boolean);
    property OnChange: TNotifyEvent read FOnChange write SetOnChange;
  published
    property MultiEdit: TTextEditorCaretMultiEdit read FMultiEdit write SetMultiEdit;
    property NonBlinking: TTextEditorCaretNonBlinking read FNonBlinking write SetNonBlinking;
    property Offsets: TTextEditorCaretOffsets read FOffsets write SetOffsets;
    property Options: TTextEditorCaretOptions read FOptions write SetOptions default [];
    property Styles: TTextEditorCaretStyles read FStyles write SetStyles;
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

implementation

constructor TTextEditorCaret.Create;
begin
  inherited;

  FMultiEdit := TTextEditorCaretMultiEdit.Create;
  FNonBlinking := TTextEditorCaretNonBlinking.Create;
  FOffsets := TTextEditorCaretOffsets.Create;
  FStyles := TTextEditorCaretStyles.Create;
  FVisible := True;
  FOptions := [];
end;

destructor TTextEditorCaret.Destroy;
begin
  FMultiEdit.Free;
  FNonBlinking.Free;
  FOffsets.Free;
  FStyles.Free;

  inherited;
end;

procedure TTextEditorCaret.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCaret) then
  with ASource as TTextEditorCaret do
  begin
    Self.FStyles.Assign(FStyles);
    Self.FMultiEdit.Assign(FMultiEdit);
    Self.FNonBlinking.Assign(FNonBlinking);
    Self.FOffsets.Assign(FOffsets);
    Self.FOptions := FOptions;
    Self.FVisible := FVisible;
    Self.DoChange(Self);
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorCaret.SetOnChange(const AValue: TNotifyEvent);
begin
  FOnChange := AValue;
  FOffsets.OnChange := AValue;
  FStyles.OnChange := AValue;
  FMultiEdit.OnChange := AValue;
  FNonBlinking.OnChange := AValue;
end;

procedure TTextEditorCaret.DoChange(const ASender: TObject);
begin
  if Assigned(FOnChange) then
    FOnChange(ASender);
end;

procedure TTextEditorCaret.SetStyles(const AValue: TTextEditorCaretStyles);
begin
  FStyles.Assign(AValue);
end;

procedure TTextEditorCaret.SetMultiEdit(const AValue: TTextEditorCaretMultiEdit);
begin
  FMultiEdit.Assign(AValue);
end;

procedure TTextEditorCaret.SetNonBlinking(const AValue: TTextEditorCaretNonBlinking);
begin
  FNonBlinking.Assign(AValue);
end;

procedure TTextEditorCaret.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    DoChange(Self);
  end;
end;

procedure TTextEditorCaret.SetOffsets(const AValue: TTextEditorCaretOffsets);
begin
  FOffsets.Assign(AValue);
end;

procedure TTextEditorCaret.SetOption(const AOption: TTextEditorCaretOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

procedure TTextEditorCaret.SetOptions(const AValue: TTextEditorCaretOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;
    DoChange(Self);
  end;
end;

end.
