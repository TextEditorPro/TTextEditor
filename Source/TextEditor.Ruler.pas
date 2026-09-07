unit TextEditor.Ruler;

interface

uses
  System.Classes, System.UITypes, TextEditor.Types;

const
  TEXTEDITOR_DEFAULT_RULER_OPTIONS = [roShowGuideLine, roShowSelection];

type
  TTextEditorRuler = class(TPersistent)
  strict private
    FCursor: TCursor;
    FHeight: TTextEditorScaledInteger;
    FMoving: Boolean;
    FOnChange: TNotifyEvent;
    FOptions: TTextEditorRulerOptions;
    FVisible: Boolean;
    function GetHeight: Integer;
    procedure DoChange;
    procedure SetHeight(const AValue: Integer);
    procedure SetOnChange(const AValue: TNotifyEvent);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure ChangeScale(const AMultiplier, ADivider: Integer);
    procedure SetOption(const AOption: TTextEditorRulerOption; const AEnabled: Boolean);
    property Moving: Boolean read FMoving write FMoving;
    property OnChange: TNotifyEvent read FOnChange write SetOnChange;
  published
    property Cursor: TCursor read FCursor write FCursor default crDefault;
    property Height: Integer read GetHeight write SetHeight default 18;
    property Options: TTextEditorRulerOptions read FOptions write FOptions default TEXTEDITOR_DEFAULT_RULER_OPTIONS;
    property Visible: Boolean read FVisible write SetVisible default False;
  end;

implementation

uses
  Winapi.Windows;

constructor TTextEditorRuler.Create;
begin
  inherited Create;

  FCursor := crDefault;
  FHeight := TTextEditorScaledInteger.Create(18);
  FMoving := False;
  FVisible := False;
  FOptions := TEXTEDITOR_DEFAULT_RULER_OPTIONS;
end;

procedure TTextEditorRuler.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorRuler) then
  with ASource as TTextEditorRuler do
  begin
    Self.FCursor := FCursor;
    Self.FHeight := FHeight;
    Self.FVisible := FVisible;
    Self.FOptions := FOptions;

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorRuler.ChangeScale(const AMultiplier, ADivider: Integer);
begin
  FHeight.ChangeScale(AMultiplier, ADivider);
  DoChange;
end;

function TTextEditorRuler.GetHeight: Integer;
begin
  Result := FHeight.Value;
end;

procedure TTextEditorRuler.SetOnChange(const AValue: TNotifyEvent);
begin
  FOnChange := AValue;
end;

procedure TTextEditorRuler.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorRuler.SetHeight(const AValue: Integer);
begin
  if FHeight.Value <> AValue then
  begin
    FHeight.SetValue(AValue);

    DoChange;
  end;
end;

procedure TTextEditorRuler.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;

    DoChange;
  end;
end;

procedure TTextEditorRuler.SetOption(const AOption: TTextEditorRulerOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

end.
