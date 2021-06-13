unit TextEditor.Undo.Item;

interface

uses
  System.Classes, TextEditor.Types;

type
  TTextEditorUndoItem = class(TPersistent)
  protected
    FChangeBeginPosition: TTextEditorTextPosition;
    FChangeBlockNumber: Integer;
    FChangeCaretPosition: TTextEditorTextPosition;
    FChangeData: Pointer;
    FChangeEndPosition: TTextEditorTextPosition;
    FChangeReason: TTextEditorChangeReason;
    FChangeSelectionMode: TTextEditorSelectionMode;
    FChangeString: string;
  public
    procedure Assign(ASource: TPersistent); override;
    property ChangeBeginPosition: TTextEditorTextPosition read FChangeBeginPosition write FChangeBeginPosition;
    property ChangeBlockNumber: Integer read FChangeBlockNumber write FChangeBlockNumber;
    property ChangeCaretPosition: TTextEditorTextPosition read FChangeCaretPosition write FChangeCaretPosition;
    property ChangeData: Pointer read FChangeData write FChangeData;
    property ChangeEndPosition: TTextEditorTextPosition read FChangeEndPosition write FChangeEndPosition;
    property ChangeReason: TTextEditorChangeReason read FChangeReason write FChangeReason;
    property ChangeSelectionMode: TTextEditorSelectionMode read FChangeSelectionMode write FChangeSelectionMode;
    property ChangeString: string read FChangeString write FChangeString;
  end;

implementation

procedure TTextEditorUndoItem.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorUndoItem) then
  with ASource as TTextEditorUndoItem do
  begin
    Self.FChangeBeginPosition := FChangeBeginPosition;
    Self.FChangeBlockNumber := FChangeBlockNumber;
    Self.FChangeCaretPosition := FChangeCaretPosition;
    Self.FChangeData := FChangeData;
    Self.FChangeEndPosition := FChangeEndPosition;
    Self.FChangeReason := FChangeReason;
    Self.FChangeSelectionMode := FChangeSelectionMode;
    Self.FChangeString := FChangeString;
  end
  else
    inherited Assign(ASource);
end;

end.
