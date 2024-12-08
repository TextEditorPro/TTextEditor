unit TextEditor.Glyph;

interface

uses
  System.Classes, System.UITypes, Vcl.Graphics;

type
  TTextEditorGlyph = class(TPersistent)
  strict private
    FBitmap: TBitmap;
    FInternalGlyph: TBitmap;
    FInternalMaskColor: TColor;
    FLeft: Integer;
    FMaskColor: TColor;
    FOnChange: TNotifyEvent;
    FVisible: Boolean;
    function GetHeight: Integer;
    function GetWidth: Integer;
    procedure SetBitmap(const AValue: TBitmap);
    procedure SetLeft(const AValue: Integer);
    procedure SetMaskColor(const AValue: TColor);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create(const AModule: THandle = 0; const AName: string = ''; const AMaskColor: TColor = TColors.Fuchsia);
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    procedure ChangeScale(const AMultiplier, ADivider: Integer);
    procedure Draw(const ACanvas: TCanvas; const X, Y: Integer; const ALineHeight: Integer = 0);
    property Bitmap: TBitmap read FBitmap write SetBitmap;
    property Height: Integer read GetHeight;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property Width: Integer read GetWidth;
  published
    property Left: Integer read FLeft write SetLeft default 2;
    property MaskColor: TColor read FMaskColor write SetMaskColor default TColors.SysNone;
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

implementation

uses
  Winapi.Windows, System.SysUtils, TextEditor.Utils;

constructor TTextEditorGlyph.Create(const AModule: THandle = 0; const AName: string = ''; const AMaskColor: TColor = TColors.Fuchsia);
begin
  inherited Create;

  if AName.IsEmpty then
    FInternalMaskColor := TColors.SysNone
  else
  begin
    FInternalGlyph := Vcl.Graphics.TBitmap.Create;
    FInternalGlyph.Handle := LoadBitmap(AModule, PChar(AName));
    FInternalMaskColor := AMaskColor;
  end;

  FVisible := True;
  FBitmap := Vcl.Graphics.TBitmap.Create;
  FMaskColor := TColors.SysNone;
  FLeft := 2;
end;

destructor TTextEditorGlyph.Destroy;
begin
  if Assigned(FInternalGlyph) then
    FInternalGlyph.Free;

  FBitmap.Free;

  inherited Destroy;
end;

procedure TTextEditorGlyph.ChangeScale(const AMultiplier, ADivider: Integer);
var
  LNumerator: Integer;
begin
  LNumerator := (AMultiplier div ADivider) * ADivider;

  if Assigned(FInternalGlyph) then
    ResizeBitmap(FInternalGlyph, MulDiv(FInternalGlyph.Width, LNumerator, ADivider), MulDiv(FInternalGlyph.Height, LNumerator, ADivider));

  if (FBitmap.Height <> 0) and (FBitmap.Width <> 0) then
    ResizeBitmap(FBitmap, MulDiv(FBitmap.Width, LNumerator, ADivider), MulDiv(FBitmap.Height, LNumerator, ADivider));
end;

procedure TTextEditorGlyph.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorGlyph) then
  with ASource as TTextEditorGlyph do
  begin
    if Assigned(FInternalGlyph) then
      Self.FInternalGlyph.Assign(FInternalGlyph);

    Self.FInternalMaskColor := FInternalMaskColor;
    Self.FVisible := FVisible;
    Self.FBitmap.Assign(FBitmap);
    Self.FMaskColor := FMaskColor;
    Self.FLeft := FLeft;

    if Assigned(Self.FOnChange) then
      Self.FOnChange(Self);
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorGlyph.Draw(const ACanvas: TCanvas; const X, Y: Integer; const ALineHeight: Integer = 0);
var
  LGlyphBitmap: Vcl.Graphics.TBitmap;
  LMaskColor: TColor;
  LY: Integer;
begin
  if not FBitmap.Empty then
  begin
    LGlyphBitmap := FBitmap;
    LMaskColor := FMaskColor;
  end
  else
  if Assigned(FInternalGlyph) then
  begin
    LGlyphBitmap := FInternalGlyph;
    LMaskColor := FInternalMaskColor;
  end
  else
    Exit;

  LY := Y;

  if ALineHeight <> 0 then
    Inc(LY, Abs(LGlyphBitmap.Height - ALineHeight) div 2);

  LGlyphBitmap.Transparent := True;
  LGlyphBitmap.TransparentMode := tmFixed;
  LGlyphBitmap.TransparentColor := LMaskColor;

  ACanvas.Draw(X, LY, LGlyphBitmap);
end;

procedure TTextEditorGlyph.SetBitmap(const AValue: Vcl.Graphics.TBitmap);
begin
  FBitmap.Assign(AValue);
end;

procedure TTextEditorGlyph.SetMaskColor(const AValue: TColor);
begin
  if FMaskColor <> AValue then
  begin
    FMaskColor := AValue;

    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TTextEditorGlyph.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;

    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TTextEditorGlyph.SetLeft(const AValue: Integer);
begin
  if FLeft <> AValue then
  begin
    FLeft := AValue;

    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

function TTextEditorGlyph.GetWidth: Integer;
begin
  if not FBitmap.Empty then
    Result := FBitmap.Width
  else
  if Assigned(FInternalGlyph) then
    Result := FInternalGlyph.Width
  else
    Result := 0;
end;

function TTextEditorGlyph.GetHeight: Integer;
begin
  if not FBitmap.Empty then
    Result := FBitmap.Height
  else
  if Assigned(FInternalGlyph) then
    Result := FInternalGlyph.Height
  else
    Result := 0;
end;

end.
