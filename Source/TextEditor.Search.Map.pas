unit TextEditor.Search.Map;

interface

uses
  System.Classes, System.UITypes, TextEditor.Types;

type
  TTextEditorSearchMap = class(TPersistent)
  strict private
    FAlign: TTextEditorSearchMapAlign;
    FCursor: TCursor;
    FOnChange: TTextEditorSearchChangeEvent;
    FOptions: TTextEditorSearchMapOptions;
    FVisible: Boolean;
    FWidth: Integer;
    procedure DoChange;
    procedure SetAlign(const AValue: TTextEditorSearchMapAlign);
    procedure SetOptions(const AValue: TTextEditorSearchMapOptions);
    procedure SetVisible(const AValue: Boolean);
    procedure SetWidth(const AValue: Integer);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure ChangeScale(const AMultiplier, ADivider: Integer);
    function GetWidth: Integer;
  published
    property Align: TTextEditorSearchMapAlign read FAlign write SetAlign default saRight;
    property Cursor: TCursor read FCursor write FCursor default crArrow;
    property OnChange: TTextEditorSearchChangeEvent read FOnChange write FOnChange;
    property Options: TTextEditorSearchMapOptions read FOptions write SetOptions default [moShowActiveLine];
    property Visible: Boolean read FVisible write SetVisible default False;
    property Width: Integer read FWidth write SetWidth default 5;
  end;

implementation

uses
  Winapi.Windows, System.Math;

constructor TTextEditorSearchMap.Create;
begin
  inherited;

  FAlign := saRight;
  FOptions := [moShowActiveLine];
  FVisible := False;
  FWidth := 5;
  FCursor := crArrow;
end;

procedure TTextEditorSearchMap.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorSearchMap) then
  with ASource as TTextEditorSearchMap do
  begin
    Self.FAlign := FAlign;
    Self.FVisible := FVisible;
    Self.FOptions := Options;
    Self.FWidth := FWidth;
    Self.FCursor := FCursor;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorSearchMap.ChangeScale(const AMultiplier, ADivider: Integer);
begin
  FWidth := MulDiv(FWidth, AMultiplier, ADivider);
  DoChange;
end;

procedure TTextEditorSearchMap.SetWidth(const AValue: Integer);
var
  LValue: Integer;
begin
  LValue := Max(0, AValue);

  if FWidth <> LValue then
    FWidth := LValue;

  DoChange;
end;

procedure TTextEditorSearchMap.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(scSearch);
end;

procedure TTextEditorSearchMap.SetAlign(const AValue: TTextEditorSearchMapAlign);
begin
  if FAlign <> AValue then
  begin
    FAlign := AValue;
    DoChange;
  end;
end;

procedure TTextEditorSearchMap.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    DoChange;
  end;
end;

procedure TTextEditorSearchMap.SetOptions(const AValue: TTextEditorSearchMapOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;
    DoChange;
  end;
end;

function TTextEditorSearchMap.GetWidth: Integer;
begin
  if FVisible then
    Result := FWidth
  else
    Result := 0;
end;

end.
