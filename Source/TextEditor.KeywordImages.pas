unit TextEditor.KeywordImages;

{$I TextEditor.Defines.inc}

interface

uses
  System.Classes, System.UITypes, Vcl.ImgList;

type
  TTextEditorKeywordImageItem = class(TCollectionItem)
  strict private
    FImageIndex: System.UITypes.TImageIndex;
    FKeyword: string;
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(ACollection: TCollection); override;
    procedure Assign(ASource: TPersistent); override;
  published
    property ImageIndex: System.UITypes.TImageIndex read FImageIndex write FImageIndex default -1;
    property Keyword: string read FKeyword write FKeyword;
  end;

  TTextEditorKeywordImageItems = class(TOwnedCollection)
  protected
    function GetItem(const AIndex: Integer): TTextEditorKeywordImageItem;
    procedure SetItem(const AIndex: Integer; const AValue: TTextEditorKeywordImageItem);
  public
    function Add: TTextEditorKeywordImageItem;
    function FindItem(const AKeyword: string): TTextEditorKeywordImageItem;
    property Items[const AIndex: Integer]: TTextEditorKeywordImageItem read GetItem write SetItem;
  end;

  TTextEditorKeywordImages = class(TPersistent)
  strict private
    FImages: TCustomImageList;
    FItems: TTextEditorKeywordImageItems;
    FOnChange: TNotifyEvent;
    FOwner: TComponent;
    FVisible: Boolean;
    function IsItemsStored: Boolean;
    procedure DoChange;
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetItems(const AValue: TTextEditorKeywordImageItems);
    procedure SetVisible(const AValue: Boolean);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(const AOwner: TComponent);
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Images: TCustomImageList read FImages write SetImages;
    property Items: TTextEditorKeywordImageItems read FItems write SetItems stored IsItemsStored;
    property Visible: Boolean read FVisible write SetVisible default False;
  end;

implementation

uses
  System.SysUtils;

{ TTextEditorKeywordImageItem }

constructor TTextEditorKeywordImageItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);

  FImageIndex := -1;
end;

procedure TTextEditorKeywordImageItem.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorKeywordImageItem) then
  with ASource as TTextEditorKeywordImageItem do
  begin
    Self.FImageIndex := FImageIndex;
    Self.FKeyword := FKeyword;
  end
  else
    inherited Assign(ASource);
end;

function TTextEditorKeywordImageItem.GetDisplayName: string;
begin
  Result := FKeyword;
end;

{ TTextEditorKeywordImageItems }

function TTextEditorKeywordImageItems.GetItem(const AIndex: Integer): TTextEditorKeywordImageItem;
begin
  Result := TTextEditorKeywordImageItem(inherited GetItem(AIndex));
end;

procedure TTextEditorKeywordImageItems.SetItem(const AIndex: Integer; const AValue: TTextEditorKeywordImageItem);
begin
  inherited SetItem(AIndex, AValue);
end;

function TTextEditorKeywordImageItems.Add: TTextEditorKeywordImageItem;
begin
  Result := TTextEditorKeywordImageItem(inherited Add);
end;

function TTextEditorKeywordImageItems.FindItem(const AKeyword: string): TTextEditorKeywordImageItem;
begin
  for var LIndex := 0 to Count - 1 do
  begin
    Result := GetItem(LIndex);

    if SameText(Result.Keyword, AKeyword) then
      Exit;
  end;

  Result := nil;
end;

{ TTextEditorKeywordImages }

constructor TTextEditorKeywordImages.Create(const AOwner: TComponent);
begin
  inherited Create;

  FOwner := AOwner;
  FItems := TTextEditorKeywordImageItems.Create(Self, TTextEditorKeywordImageItem);
  FVisible := False;
end;

destructor TTextEditorKeywordImages.Destroy;
begin
  FItems.Free;

  inherited Destroy;
end;

procedure TTextEditorKeywordImages.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorKeywordImages) then
  with ASource as TTextEditorKeywordImages do
  begin
    Self.FImages := FImages;
    Self.FItems.Assign(FItems);
    Self.FVisible := FVisible;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

function TTextEditorKeywordImages.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

function TTextEditorKeywordImages.IsItemsStored: Boolean;
begin
  Result := FItems.Count > 0;
end;

procedure TTextEditorKeywordImages.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorKeywordImages.SetImages(const AValue: TCustomImageList);
begin
  if FImages <> AValue then
  begin
    FImages := AValue;

    if Assigned(FImages) then
      FImages.FreeNotification(FOwner);

    DoChange;
  end;
end;

procedure TTextEditorKeywordImages.SetItems(const AValue: TTextEditorKeywordImageItems);
begin
  FItems.Assign(AValue);

  DoChange;
end;

procedure TTextEditorKeywordImages.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;

    DoChange;
  end;
end;

end.
