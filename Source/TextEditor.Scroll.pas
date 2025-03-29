unit TextEditor.Scroll;

interface

uses
  System.Classes, System.UITypes, TextEditor.Glyph, TextEditor.Scroll.Hint, TextEditor.Scroll.Shadow, TextEditor.Types;

const
  TEXTEDITOR_DEFAULT_SCROLL_OPTIONS = [soShowVerticalScrollHint, soWheelClickMove];

type
  TTextEditorScroll = class(TPersistent)
  strict private
    FBars: System.UITypes.TScrollStyle;
    FHint: TTextEditorScrollHint;
    FIndicator: TTextEditorGlyph;
    FOnChange: TNotifyEvent;
    FOptions: TTextEditorScrollOptions;
    FShadow: TTextEditorScrollShadow;
    procedure DoChange;
    procedure SetBars(const AValue: System.UITypes.TScrollStyle);
    procedure SetHint(const AValue: TTextEditorScrollHint);
    procedure SetIndicator(const AValue: TTextEditorGlyph);
    procedure SetOnChange(const AValue: TNotifyEvent);
    procedure SetOptions(const AValue: TTextEditorScrollOptions);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TTextEditorScrollOption; const AEnabled: Boolean);
    property OnChange: TNotifyEvent read FOnChange write SetOnChange;
  published
    property Bars: System.UITypes.TScrollStyle read FBars write SetBars default System.UITypes.TScrollStyle.ssBoth;
    property Hint: TTextEditorScrollHint read FHint write SetHint;
    property Indicator: TTextEditorGlyph read FIndicator write SetIndicator;
    property Options: TTextEditorScrollOptions read FOptions write SetOptions default TEXTEDITOR_DEFAULT_SCROLL_OPTIONS;
    property Shadow: TTextEditorScrollShadow read FShadow write FShadow;
  end;

implementation

uses
  TextEditor.Consts;

constructor TTextEditorScroll.Create;
begin
  inherited;

  FOptions := TEXTEDITOR_DEFAULT_SCROLL_OPTIONS;
  FBars := System.UITypes.TScrollStyle.ssBoth;
  FHint := TTextEditorScrollHint.Create;
  FIndicator := TTextEditorGlyph.Create(HInstance, TResourceBitmap.MouseMoveScroll, TColors.Fuchsia);
  FShadow := TTextEditorScrollShadow.Create;
end;

destructor TTextEditorScroll.Destroy;
begin
  FHint.Free;
  FIndicator.Free;
  FShadow.Free;

  inherited;
end;

procedure TTextEditorScroll.SetOnChange(const AValue: TNotifyEvent);
begin
  FOnChange := AValue;
  FShadow.OnChange := AValue;
end;

procedure TTextEditorScroll.SetBars(const AValue: System.UITypes.TScrollStyle);
begin
  if FBars <> AValue then
  begin
    FBars := AValue;

    DoChange;
  end;
end;

procedure TTextEditorScroll.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorScroll.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorScroll) then
  with ASource as TTextEditorScroll do
  begin
    Self.FBars := FBars;
    Self.FHint.Assign(FHint);
    Self.FIndicator.Assign(FIndicator);
    Self.FShadow.Assign(FShadow);
    Self.FOptions := FOptions;

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorScroll.SetOption(const AOption: TTextEditorScrollOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

procedure TTextEditorScroll.SetOptions(const AValue: TTextEditorScrollOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;

    DoChange;
  end;
end;

procedure TTextEditorScroll.SetHint(const AValue: TTextEditorScrollHint);
begin
  FHint.Assign(AValue);
end;

procedure TTextEditorScroll.SetIndicator(const AValue: TTextEditorGlyph);
begin
  FIndicator.Assign(AValue);
end;

end.
