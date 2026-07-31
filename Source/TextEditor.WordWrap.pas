unit TextEditor.WordWrap;

interface

uses
  System.Classes, TextEditor.Glyph, TextEditor.Types;

type
  TTextEditorWordWrap = class(TPersistent)
  strict private
    FActive: Boolean;
    FIndicator: TTextEditorGlyph;
    FOnChange: TNotifyEvent;
    FWidth: TTextEditorWordWrapWidth;
    procedure DoChange;
    procedure SetActive(const AValue: Boolean);
    procedure SetIndicator(const AValue: TTextEditorGlyph);
    procedure SetOnChange(const AValue: TNotifyEvent);
    procedure SetWidth(const AValue: TTextEditorWordWrapWidth);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write SetOnChange;
  published
    property Active: Boolean read FActive write SetActive default False;
    property Indicator: TTextEditorGlyph read FIndicator write SetIndicator;
    property Width: TTextEditorWordWrapWidth read FWidth write SetWidth default wwwPage;
  end;

implementation

constructor TTextEditorWordWrap.Create;
begin
  inherited;

  FActive := False;
  FIndicator := TTextEditorGlyph.Create(igWordWrap);
  FWidth := wwwPage;
end;

destructor TTextEditorWordWrap.Destroy;
begin
  FIndicator.Free;

  inherited;
end;

procedure TTextEditorWordWrap.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorWordWrap) then
  with ASource as TTextEditorWordWrap do
  begin
    Self.FActive := FActive;
    Self.FWidth := FWidth;
    Self.FIndicator.Assign(FIndicator);

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorWordWrap.SetOnChange(const AValue: TNotifyEvent);
begin
  FOnChange := AValue;
  FIndicator.OnChange := AValue;
end;

procedure TTextEditorWordWrap.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorWordWrap.SetActive(const AValue: Boolean);
begin
  if FActive <> AValue then
  begin
    FActive := AValue;

    DoChange;
  end;
end;

procedure TTextEditorWordWrap.SetIndicator(const AValue: TTextEditorGlyph);
begin
  FIndicator.Assign(AValue);
end;

procedure TTextEditorWordWrap.SetWidth(const AValue: TTextEditorWordWrapWidth);
begin
  if FWidth <> AValue then
  begin
    FWidth := AValue;

    DoChange;
  end;
end;

end.
