unit TextEditor.TextFolding;

interface

uses
  System.Classes;

type
  TTextEditorTextFolding = class(TPersistent)
  strict private
    FActive: Boolean;
    FOnChange: TNotifyEvent;
    FOutlinedBySpacesAndTabs: Boolean;
    FOutlineCharacter: Char;
    procedure DoChange;
    procedure SetActive(const AValue: Boolean);
    procedure SetOutlinedBySpacesAndTabs(const AValue: Boolean);
    procedure SetOutlineCharacter(const AValue: Char);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Active: Boolean read FActive write SetActive default False;
    property OutlinedBySpacesAndTabs: Boolean read FOutlinedBySpacesAndTabs write SetOutlinedBySpacesAndTabs default True;
    property OutlineCharacter: Char read FOutlineCharacter write SetOutlineCharacter default '.';
  end;

implementation

constructor TTextEditorTextFolding.Create;
begin
  inherited;

  FActive := False;
  FOutlinedBySpacesAndTabs := True;
  FOutlineCharacter := '.';
end;

procedure TTextEditorTextFolding.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorTextFolding) then
  with ASource as TTextEditorTextFolding do
  begin
    Self.FActive := FActive;
    Self.FOutlinedBySpacesAndTabs := FOutlinedBySpacesAndTabs;
    Self.FOutlineCharacter := FOutlineCharacter;

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorTextFolding.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorTextFolding.SetActive(const AValue: Boolean);
begin
  if FActive <> AValue then
  begin
    FActive := AValue;

    DoChange;
  end;
end;

procedure TTextEditorTextFolding.SetOutlinedBySpacesAndTabs(const AValue: Boolean);
begin
  if FOutlinedBySpacesAndTabs <> AValue then
  begin
    FOutlinedBySpacesAndTabs := AValue;

    DoChange;
  end;
end;

procedure TTextEditorTextFolding.SetOutlineCharacter(const AValue: Char);
begin
  if FOutlineCharacter <> AValue then
  begin
    FOutlineCharacter := AValue;

    DoChange;
  end;
end;

end.
