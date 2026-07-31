unit TextEditor.Border;

interface

uses
  System.Classes, System.UITypes, Vcl.Forms, Vcl.ToolWin, TextEditor.Consts, TextEditor.Glyph;

type
  TTextEditorBorder = class(TPersistent)
  strict private
    FColor: TColor;
    FColoredEdges: TEdgeBorders;
    FOnChange: TNotifyEvent;
    FOnStyleChange: TNotifyEvent;
    FStyle: TBorderStyle;
    FWidth: Integer;
    procedure DoChange(const ASender: TObject);
    procedure DoStyleChange(const ASender: TObject);
    procedure SetColor(const AValue: TColor);
    procedure SetColoredEdges(const AValue: TEdgeBorders);
    procedure SetStyle(const AValue: TBorderStyle);
    procedure SetWidth(const AValue: Integer);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnStyleChange: TNotifyEvent read FOnStyleChange write FOnStyleChange;
  published
    property Color: TColor read FColor write SetColor default TColors.SysActiveBorder;
    property ColoredEdges: TEdgeBorders read FColoredEdges write SetColoredEdges default [];
    property Style: TBorderStyle read FStyle write SetStyle default bsSingle;
    property Width: Integer read FWidth write SetWidth default 0;
  end;

implementation

constructor TTextEditorBorder.Create;
begin
  inherited;

  FColor := TColors.SysActiveBorder;
  FColoredEdges := [];
  FStyle := bsSingle;
  FWidth := 0;
end;

procedure TTextEditorBorder.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorBorder) then
  with ASource as TTextEditorBorder do
  begin
    Self.FColor := FColor;
    Self.FStyle := FStyle;
    Self.FWidth := FWidth;

    Self.DoChange(Self);
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorBorder.DoChange(const ASender: TObject);
begin
  if Assigned(FOnChange) then
    FOnChange(ASender);
end;

procedure TTextEditorBorder.DoStyleChange(const ASender: TObject);
begin
  if Assigned(FOnStyleChange) then
    FOnStyleChange(ASender);
end;

procedure TTextEditorBorder.SetColor(const AValue: TColor);
begin
  if FColor <> AValue then
  begin
    FColor := AValue;

    DoChange(Self);
  end;
end;

procedure TTextEditorBorder.SetColoredEdges(const AValue: TEdgeBorders);
begin
  if FColoredEdges <> AValue then
  begin
    FColoredEdges := AValue;

    DoStyleChange(Self);
  end;
end;

procedure TTextEditorBorder.SetStyle(const AValue: TBorderStyle);
begin
  if FStyle <> AValue then
  begin
    FStyle := AValue;

    DoStyleChange(Self);
  end;
end;

procedure TTextEditorBorder.SetWidth(const AValue: Integer);
begin
  if FWidth <> AValue then
  begin
    FWidth := AValue;

    DoChange(Self);
  end;
end;

end.
