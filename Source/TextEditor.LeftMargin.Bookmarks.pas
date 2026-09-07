unit TextEditor.LeftMargin.Bookmarks;

interface

uses
  System.Classes, Vcl.ImgList, TextEditor.Types;

type
  TTextEditorLeftMarginBookmarks = class(TPersistent)
  strict private
    FImages: TCustomImageList;
    FLeftMargin: Integer;
    FOnChange: TNotifyEvent;
    FOptions: TTextEditorLeftMarginBookmarkOptions;
    FOwner: TComponent;
    FVisible: Boolean;
    procedure DoChange;
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetOptions(const AValue: TTextEditorLeftMarginBookmarkOptions);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create(AOwner: TComponent);
    procedure Assign(ASource: TPersistent); override;
    procedure ChangeScale(const AMultiplier, ADivider: Integer);
    procedure SetOption(const AOption: TTextEditorLeftMarginBookmarkOption; const AEnabled: Boolean);
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Images: TCustomImageList read FImages write SetImages;
    property LeftMargin: Integer read FLeftMargin write FLeftMargin default 2;
    property Options: TTextEditorLeftMarginBookmarkOptions read FOptions write SetOptions default TTextEditorDefaultOptions.Bookmarks;
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
  FOptions := TTextEditorDefaultOptions.Bookmarks;
  FVisible := True;
end;

procedure TTextEditorLeftMarginBookmarks.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorLeftMarginBookmarks) then
  with ASource as TTextEditorLeftMarginBookmarks do
  begin
    Self.FImages := FImages;
    Self.FLeftMargin := FLeftMargin;
    Self.FOptions := FOptions;
    Self.FVisible := FVisible;

    Self.DoChange;
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

procedure TTextEditorLeftMarginBookmarks.SetOption(const AOption: TTextEditorLeftMarginBookmarkOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
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

procedure TTextEditorLeftMarginBookmarks.SetOptions(const AValue: TTextEditorLeftMarginBookmarkOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;

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
