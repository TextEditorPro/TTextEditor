unit TextEditor.LeftMargin.Bookmarks;

interface

uses
  System.Classes, Vcl.ImgList;

type
  TTextEditorLeftMarginBookmarks = class(TPersistent)
  strict private
    FAutoNumber: Boolean;
    FImages: TCustomImageList;
    FLeftMargin: Integer;
    FOnChange: TNotifyEvent;
    FOwner: TComponent;
    FScaled: Boolean;
    FShortCuts: Boolean;
    FVisible: Boolean;
    procedure DoChange;
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create(AOwner: TComponent);
    procedure Assign(ASource: TPersistent); override;
    procedure ChangeScale(const AMultiplier, ADivider: Integer);
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property AutoNumber: Boolean read FAutoNumber write FAutoNumber default False;
    property Images: TCustomImageList read FImages write SetImages;
    property LeftMargin: Integer read FLeftMargin write FLeftMargin default 2;
    property Scaled: Boolean read FScaled write FScaled default True;
    property ShortCuts: Boolean read FShortCuts write FShortCuts default True;
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

implementation

uses
  Winapi.Windows;

constructor TTextEditorLeftMarginBookmarks.Create(AOwner: TComponent);
begin
  inherited Create;

  FOwner := AOwner;
  FAutoNumber := False;
  FLeftMargin := 2;
  FScaled := True;
  FShortCuts := True;
  FVisible := True;
end;

procedure TTextEditorLeftMarginBookmarks.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorLeftMarginBookmarks) then
  with ASource as TTextEditorLeftMarginBookmarks do
  begin
    Self.FAutoNumber := FAutoNumber;
    Self.FImages := FImages;
    Self.FLeftMargin := FLeftMargin;
    Self.FShortCuts := FShortCuts;
    Self.FVisible := FVisible;

    if Assigned(Self.FOnChange) then
      Self.FOnChange(Self);
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorLeftMarginBookmarks.ChangeScale(const AMultiplier, ADivider: Integer);
begin
  FLeftMargin := MulDiv(FLeftMargin, AMultiplier, ADivider);
end;

procedure TTextEditorLeftMarginBookmarks.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorLeftMarginBookmarks.SetImages(const AValue: TCustomImageList);
begin
  if FImages <> AValue then
  begin
    FImages := AValue;

    if Assigned(FImages) then
      FImages.FreeNotification(FOwner);

    DoChange;
  end;
end;

procedure TTextEditorLeftMarginBookmarks.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;

    DoChange;
  end;
end;

end.
