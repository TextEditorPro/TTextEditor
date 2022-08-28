unit TextEditor.RightMargin;

interface

uses
  System.Classes, System.UITypes, Vcl.Graphics, TextEditor.Types;

type
  TTextEditorRightMargin = class(TPersistent)
  strict private
    FCursor: TCursor;
    FMouseOver: Boolean;
    FMoving: Boolean;
    FOnChange: TNotifyEvent;
    FOptions: TTextEditorRightMarginOptions;
    FPosition: Integer;
    FVisible: Boolean;
    procedure DoChange;
    procedure SetPosition(const AValue: Integer);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TTextEditorRightMarginOption; const AEnabled: Boolean);
    property Moving: Boolean read FMoving write FMoving;
    property MouseOver: Boolean read FMouseOver write FMouseOver;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Cursor: TCursor read FCursor write FCursor default crHSplit;
    property Options: TTextEditorRightMarginOptions read FOptions write FOptions default [rmoMouseMove, rmoShowMovingHint];
    property Position: Integer read FPosition write SetPosition default 80;
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

implementation

constructor TTextEditorRightMargin.Create;
begin
  inherited;

  FVisible := True;
  FPosition := 80;
  FOptions := [rmoMouseMove, rmoShowMovingHint];
  FMoving := False;
  FMouseOver := False;
  FCursor := crHSplit;
end;

procedure TTextEditorRightMargin.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorRightMargin) then
  with ASource as TTextEditorRightMargin do
  begin
    Self.FVisible := FVisible;
    Self.FPosition := FPosition;
    Self.FOptions := FOptions;
    Self.FCursor := FCursor;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorRightMargin.SetOption(const AOption: TTextEditorRightMarginOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

procedure TTextEditorRightMargin.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorRightMargin.SetPosition(const AValue: Integer);
begin
  if FPosition <> AValue then
  begin
    FPosition := AValue;
    DoChange
  end;
end;

procedure TTextEditorRightMargin.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    DoChange
  end;
end;


end.
