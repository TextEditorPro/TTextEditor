unit TextEditor.LeftMargin.Marks;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Graphics, Vcl.ImgList;

type
  TTextEditorLeftMarginMarks = class(TPersistent)
  strict private
    FDefaultImageIndex: Integer;
    FImages: TCustomImageList;
    FLeftMargin: Integer;
    FOnChange: TNotifyEvent;
    FOverlappingOffset: Integer;
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
    property DefaultImageIndex: Integer read FDefaultImageIndex write FDefaultImageIndex default -1;
    property Images: TCustomImageList read FImages write SetImages;
    property LeftMargin: Integer read FLeftMargin write FLeftMargin default 2;
    property OverlappingOffset: Integer read FOverlappingOffset write FOverlappingOffset default 4;
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

implementation

uses
  Winapi.Windows;

constructor TTextEditorLeftMarginMarks.Create(AOwner: TComponent);
begin
  inherited Create;

  FOwner := AOwner;
  FDefaultImageIndex := -1;
  FLeftMargin := 2;
  FOverlappingOffset := 4;
  FShortCuts := True;
  FVisible := True;
end;

procedure TTextEditorLeftMarginMarks.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorLeftMarginMarks) then
  with ASource as TTextEditorLeftMarginMarks do
  begin
    Self.FDefaultImageIndex := FDefaultImageIndex;
    Self.FImages := FImages;
    Self.FLeftMargin := FLeftMargin;
    Self.FOverlappingOffset := FOverlappingOffset;
    Self.FShortCuts := FShortCuts;
    Self.FVisible := FVisible;
    if Assigned(Self.FOnChange) then
      Self.FOnChange(Self);
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorLeftMarginMarks.ChangeScale(const AMultiplier, ADivider: Integer);
var
  LNumerator: Integer;
begin
  LNumerator := (AMultiplier div ADivider) * ADivider;
  FLeftMargin := MulDiv(FLeftMargin, LNumerator, ADivider);
  FOverlappingOffset := MulDiv(FOverlappingOffset, LNumerator, ADivider);
end;

procedure TTextEditorLeftMarginMarks.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorLeftMarginMarks.SetImages(const AValue: TCustomImageList);
begin
  if FImages <> AValue then
  begin
    FImages := AValue;
    if Assigned(FImages) then
      FImages.FreeNotification(FOwner);
    DoChange;
  end;
end;

procedure TTextEditorLeftMarginMarks.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    DoChange;
  end;
end;

end.
