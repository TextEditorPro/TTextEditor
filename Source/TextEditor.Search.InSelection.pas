unit TextEditor.Search.InSelection;

interface

uses
  System.Classes, System.UITypes, TextEditor.Consts, TextEditor.Types;

type
  TTextEditorSearchInSelection = class(TPersistent)
  strict private
    FActive: Boolean;
    FOnChange: TTextEditorSearchChangeEvent;
    FSelectionBeginPosition: TTextEditorTextPosition;
    FSelectionEndPosition: TTextEditorTextPosition;
    procedure DoChange;
    procedure SetActive(const AValue: Boolean);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    property SelectionBeginPosition: TTextEditorTextPosition read FSelectionBeginPosition write FSelectionBeginPosition;
    property SelectionEndPosition: TTextEditorTextPosition read FSelectionEndPosition write FSelectionEndPosition;
  published
    property Active: Boolean read FActive write SetActive default False;
    property OnChange: TTextEditorSearchChangeEvent read FOnChange write FOnChange;
  end;

implementation

constructor TTextEditorSearchInSelection.Create;
begin
  inherited;

  FActive := False;
end;

procedure TTextEditorSearchInSelection.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(scInSelectionActive);
end;

procedure TTextEditorSearchInSelection.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorSearchInSelection) then
  with ASource as TTextEditorSearchInSelection do
  begin
    Self.FActive := FActive;
    Self.FSelectionBeginPosition := FSelectionBeginPosition;
    Self.FSelectionEndPosition := FSelectionEndPosition;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorSearchInSelection.SetActive(const AValue: Boolean);
begin
  if FActive <> AValue then
  begin
    FActive := AValue;
    DoChange;
  end;
end;

end.
