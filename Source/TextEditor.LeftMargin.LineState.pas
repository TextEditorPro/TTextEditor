unit TextEditor.LeftMargin.LineState;

interface

uses
  System.Classes, TextEditor.Types;

type
  TTextEditorLeftMarginLineState = class(TPersistent)
  strict private
    FAlign: TTextEditorLeftMarginLineStateAlign;
    FOffset: Integer;
    FOnChange: TNotifyEvent;
    FPixelsPerInch: Integer;
    FShowOnlyModified: Boolean;
    FVisible: Boolean;
    FWidth: Integer;
    function GetScaledOffset: Integer;
    function GetScaledWidth: Integer;
    procedure DoChange;
    procedure SetOnChange(const AValue: TNotifyEvent);
    procedure SetVisible(const AValue: Boolean);
    procedure SetWidth(const AValue: Integer);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure ChangeScale(const AMultiplier, ADivider: Integer);
    property OnChange: TNotifyEvent read FOnChange write SetOnChange;
    property ScaledOffset: Integer read GetScaledOffset;
    property ScaledWidth: Integer read GetScaledWidth;
  published
    property Align: TTextEditorLeftMarginLineStateAlign read FAlign write FAlign default lsRight;
    property Offset: Integer read FOffset write FOffset default 0;
    property ShowOnlyModified: Boolean read FShowOnlyModified write FShowOnlyModified default True;
    property Visible: Boolean read FVisible write SetVisible default True;
    property Width: Integer read FWidth write SetWidth default 2;
  end;

implementation

constructor TTextEditorLeftMarginLineState.Create;
begin
  inherited;

  FAlign := lsRight;
  FOffset := 0;
  FPixelsPerInch := 96;
  FShowOnlyModified := True;
  FVisible := True;
  FWidth := 2;
end;

procedure TTextEditorLeftMarginLineState.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorLeftMarginLineState) then
  with ASource as TTextEditorLeftMarginLineState do
  begin
    Self.FAlign := FAlign;
    Self.FOffset := FOffset;
    Self.FShowOnlyModified := FShowOnlyModified;
    Self.FVisible := FVisible;
    Self.FWidth := FWidth;

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorLeftMarginLineState.ChangeScale(const AMultiplier, ADivider: Integer); //FI:O804 Method parameter is declared but never used
begin
  FPixelsPerInch := AMultiplier;
end;

function TTextEditorLeftMarginLineState.GetScaledOffset: Integer;
begin
  Result := FOffset * FPixelsPerInch div 96;
end;

function TTextEditorLeftMarginLineState.GetScaledWidth: Integer;
begin
  Result := FWidth * FPixelsPerInch div 96;

  if (Result = 0) and (FWidth > 0) then
    Result := 1;
end;

procedure TTextEditorLeftMarginLineState.SetOnChange(const AValue: TNotifyEvent);
begin
  FOnChange := AValue;
end;

procedure TTextEditorLeftMarginLineState.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorLeftMarginLineState.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;

    DoChange;
  end;
end;

procedure TTextEditorLeftMarginLineState.SetWidth(const AValue: Integer);
begin
  if FWidth <> AValue then
  begin
    FWidth := AValue;

    DoChange;
  end;
end;

end.
