unit TextEditor.SyncEdit;

interface

uses
  System.Classes, TextEditor.Glyph, TextEditor.SyncEdit.Colors, TextEditor.Types;

type
  TTextEditorSyncEdit = class(TPersistent)
  private
    FActivator: TTextEditorGlyph;
    FActive: Boolean;
    FBlockBeginPosition: TTextEditorTextPosition;
    FBlockEndPosition: TTextEditorTextPosition;
    FBlockSelected: Boolean;
    FColors: TTextEditorSyncEditColors;
    FEditBeginPosition: TTextEditorTextPosition;
    FEditEndPosition: TTextEditorTextPosition;
    FEditWidth: Integer;
    FInEditor: Boolean;
    FOnChange: TNotifyEvent;
    FOptions: TTextEditorSyncEditOptions;
    FShortCut: TShortCut;
    FSyncItems: TList;
    FVisible: Boolean;
    procedure DoChange(const ASender: TObject);
    procedure SetActivator(const AValue: TTextEditorGlyph);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    function IsTextPositionInBlock(ATextPosition: TTextEditorTextPosition): Boolean;
    function IsTextPositionInEdit(ATextPosition: TTextEditorTextPosition): Boolean;
    procedure Abort;
    procedure Assign(ASource: TPersistent); override;
    procedure ClearSyncItems;
    procedure MoveBeginPositionChar(ACount: Integer);
    procedure MoveEndPositionChar(ACount: Integer);
    procedure SetOption(const AOption: TTextEditorSyncEditOption; const AEnabled: Boolean);
    property BlockBeginPosition: TTextEditorTextPosition read FBlockBeginPosition write FBlockBeginPosition;
    property BlockEndPosition: TTextEditorTextPosition read FBlockEndPosition write FBlockEndPosition;
    property BlockSelected: Boolean read FBlockSelected write FBlockSelected default False;
    property EditBeginPosition: TTextEditorTextPosition read FEditBeginPosition write FEditBeginPosition;
    property EditEndPosition: TTextEditorTextPosition read FEditEndPosition write FEditEndPosition;
    property EditWidth: Integer read FEditWidth write FEditWidth;
    property InEditor: Boolean read FInEditor write FInEditor default False;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property SyncItems: TList read FSyncItems write FSyncItems;
    property Visible: Boolean read FVisible write SetVisible default False;
  published
    property Activator: TTextEditorGlyph read FActivator write SetActivator;
    property Active: Boolean read FActive write FActive default True;
    property Colors: TTextEditorSyncEditColors read FColors write FColors;
    property Options: TTextEditorSyncEditOptions read FOptions write FOptions default [seCaseSensitive];
    property ShortCut: TShortCut read FShortCut write FShortCut;
  end;

implementation

uses
  System.UITypes, Vcl.Graphics, Vcl.Menus, TextEditor.Consts;

constructor TTextEditorSyncEdit.Create;
begin
  inherited Create;

  FActive := True;
  FVisible := False;
  FBlockSelected := False;
  FInEditor := False;
  FShortCut := Vcl.Menus.ShortCut(Ord('J'), [ssCtrl, ssShift]);
  FOptions := [seCaseSensitive];
  FSyncItems := TList.Create;
  FColors := TTextEditorSyncEditColors.Create;
  FActivator := TTextEditorGlyph.Create(HInstance, TEXT_EDITOR_SYNCEDIT, TColors.Fuchsia);
end;

destructor TTextEditorSyncEdit.Destroy;
begin
  ClearSyncItems;
  FSyncItems.Free;
  FColors.Free;
  FActivator.Free;

  inherited;
end;

procedure TTextEditorSyncEdit.ClearSyncItems;
var
  LIndex: Integer;
begin
  for LIndex := FSyncItems.Count - 1 downto 0 do
    Dispose(PTextEditorTextPosition(FSyncItems.Items[LIndex]));
  FSyncItems.Clear;
end;

procedure TTextEditorSyncEdit.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorSyncEdit) then
  with ASource as TTextEditorSyncEdit do
  begin
    Self.FActive := FActive;
    Self.FShortCut := FShortCut;
    Self.FActivator.Assign(FActivator);
    Self.FColors.Assign(FColors);
    Self.DoChange(Self);
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorSyncEdit.DoChange(const ASender: TObject);
begin
  if Assigned(FOnChange) then
    FOnChange(ASender);
end;

procedure TTextEditorSyncEdit.SetVisible(const AValue: Boolean);
begin
  FVisible := AValue;
  DoChange(Self);
end;

procedure TTextEditorSyncEdit.SetActivator(const AValue: TTextEditorGlyph);
begin
  FActivator.Assign(AValue);
end;

function TTextEditorSyncEdit.IsTextPositionInEdit(ATextPosition: TTextEditorTextPosition): Boolean;
begin
  Result := ((ATextPosition.Line > FEditBeginPosition.Line) or
    (ATextPosition.Line = FEditBeginPosition.Line) and (ATextPosition.Char >= FEditBeginPosition.Char))
    and
    ((ATextPosition.Line < FEditEndPosition.Line) or
    (ATextPosition.Line = FEditEndPosition.Line) and (ATextPosition.Char < FEditEndPosition.Char));
end;

function TTextEditorSyncEdit.IsTextPositionInBlock(ATextPosition: TTextEditorTextPosition): Boolean;
begin
  Result := ((ATextPosition.Line > FBlockBeginPosition.Line) or
    (ATextPosition.Line = FBlockBeginPosition.Line) and (ATextPosition.Char >= FBlockBeginPosition.Char))
    and
    ((ATextPosition.Line < FBlockEndPosition.Line) or
    (ATextPosition.Line = FBlockEndPosition.Line) and (ATextPosition.Char < FBlockEndPosition.Char));
end;

procedure TTextEditorSyncEdit.SetOption(const AOption: TTextEditorSyncEditOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

procedure TTextEditorSyncEdit.MoveBeginPositionChar(ACount: Integer);
begin
  Inc(FEditBeginPosition.Char, ACount);
end;

procedure TTextEditorSyncEdit.MoveEndPositionChar(ACount: Integer);
begin
  Inc(FEditEndPosition.Char, ACount);
end;

procedure TTextEditorSyncEdit.Abort;
begin
  FVisible := False;
end;

end.
