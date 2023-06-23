unit TextEditor.CodeFolding.Hint;

interface

uses
  System.Classes, System.UITypes, TextEditor.CodeFolding.Hint.Indicator;

type
  TTextEditorCodeFoldingHint = class(TPersistent)
  strict private
    FCursor: TCursor;
    FIndicator: TTextEditorCodeFoldingHintIndicator;
    FRowCount: Integer;
    FVisible: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
  published
    property Cursor: TCursor read FCursor write FCursor default crHandPoint;
    property Indicator: TTextEditorCodeFoldingHintIndicator read FIndicator write FIndicator;
    property RowCount: Integer read FRowCount write FRowCount default 40;
    property Visible: Boolean read FVisible write FVisible default True;
  end;

implementation

uses
  System.SysUtils;

constructor TTextEditorCodeFoldingHint.Create;
begin
  inherited;

  FCursor := crHandPoint;
  FIndicator := TTextEditorCodeFoldingHintIndicator.Create;
  FRowCount := 40;
  FVisible := True;
end;

destructor TTextEditorCodeFoldingHint.Destroy;
begin
  FreeAndNil(FIndicator);

  inherited;
end;

procedure TTextEditorCodeFoldingHint.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCodeFoldingHint) then
  with ASource as TTextEditorCodeFoldingHint do
  begin
    Self.FCursor := FCursor;
    Self.FIndicator.Assign(FIndicator);
    Self.FRowCount := FRowCount;
    Self.FVisible := FVisible;
  end
  else
    inherited Assign(ASource);
end;

end.
