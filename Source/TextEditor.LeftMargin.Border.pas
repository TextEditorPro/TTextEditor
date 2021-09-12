unit TextEditor.LeftMargin.Border;

interface

uses
  System.Classes, Vcl.Graphics, TextEditor.Types;

type
  TTextEditorLeftMarginBorder = class(TPersistent)
  strict private
    FOnChange: TNotifyEvent;
    FStyle: TTextEditorLeftMarginBorderStyle;
    procedure SetStyle(const AValue: TTextEditorLeftMarginBorderStyle);
    procedure DoChange;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Style: TTextEditorLeftMarginBorderStyle read FStyle write SetStyle default mbsNone;
  end;

implementation

constructor TTextEditorLeftMarginBorder.Create;
begin
  inherited;

  FStyle := mbsNone;
end;

procedure TTextEditorLeftMarginBorder.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorLeftMarginBorder.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorLeftMarginBorder) then
  with ASource as TTextEditorLeftMarginBorder do
  begin
    Self.FStyle := FStyle;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorLeftMarginBorder.SetStyle(const AValue: TTextEditorLeftMarginBorderStyle);
begin
  FStyle := AValue;
  DoChange
end;

end.
