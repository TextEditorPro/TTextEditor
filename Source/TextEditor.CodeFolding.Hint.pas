unit TextEditor.CodeFolding.Hint;

interface

uses
  System.Classes, System.UITypes, Vcl.Graphics, TextEditor.CodeFolding.Hint.Colors,
  TextEditor.CodeFolding.Hint.Indicator;

type
  TTextEditorCodeFoldingHint = class(TPersistent)
  strict private
    FColors: TTextEditorCodeFoldingHintColors;
    FCursor: TCursor;
    FFont: TFont;
    FIndicator: TTextEditorCodeFoldingHintIndicator;
    FRowCount: Integer;
    FVisible: Boolean;
    procedure SetFont(const AValue: TFont);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
  published
    property Colors: TTextEditorCodeFoldingHintColors read FColors write FColors;
    property Cursor: TCursor read FCursor write FCursor default crHandPoint;
    property Font: TFont read FFont write SetFont;
    property Indicator: TTextEditorCodeFoldingHintIndicator read FIndicator write FIndicator;
    property RowCount: Integer read FRowCount write FRowCount default 40;
    property Visible: Boolean read FVisible write FVisible default True;
  end;

implementation

constructor TTextEditorCodeFoldingHint.Create;
begin
  inherited;

  FColors := TTextEditorCodeFoldingHintColors.Create;
  FIndicator := TTextEditorCodeFoldingHintIndicator.Create;
  FCursor := crHandPoint;
  FRowCount := 40;
  FVisible := True;
  FFont := TFont.Create;
  FFont.Name := 'Courier New';
  FFont.Size := 8;
end;

destructor TTextEditorCodeFoldingHint.Destroy;
begin
  FColors.Free;
  FIndicator.Free;
  FFont.Free;

  inherited;
end;

procedure TTextEditorCodeFoldingHint.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCodeFoldingHint) then
  with ASource as TTextEditorCodeFoldingHint do
  begin
    Self.FColors.Assign(FColors);
    Self.FIndicator.Assign(FIndicator);
    Self.FCursor := FCursor;
    Self.FFont.Assign(FFont);
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorCodeFoldingHint.SetFont(const AValue: TFont);
begin
  FFont.Assign(AValue);
end;

end.
