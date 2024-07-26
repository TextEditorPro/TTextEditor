unit TextEditor.LeftMargin.Bookmarks;

interface

uses
  System.Classes, Vcl.ImgList;

type
  TTextEditorLeftMarginBookmarks = class(TPersistent)
  strict private
    FImages: TCustomImageList;
    FLeftMargin: Integer;
    FOnChange: TNotifyEvent;
    FOwner: TComponent;
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
    property Images: TCustomImageList read FImages write SetImages;
    property LeftMargin: Integer read FLeftMargin write FLeftMargin default 2;
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
  FLeftMargin := 2;
  FShortCuts := True;
  FVisible := True;
end;

procedure TTextEditorLeftMarginBookmarks.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorLeftMarginBookmarks) then
  with ASource as TTextEditorLeftMarginBookmarks do
  begin
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
var
  LNumerator: Integer;
begin
  LNumerator := (AMultiplier div ADivider) * ADivider;
  FLeftMargin := MulDiv(FLeftMargin, LNumerator, ADivider);
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
