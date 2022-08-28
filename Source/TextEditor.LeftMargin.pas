unit TextEditor.LeftMargin;

interface

uses
  System.Classes, System.UITypes, Vcl.Graphics, TextEditor.Consts, TextEditor.LeftMargin.Bookmarks,
  TextEditor.LeftMargin.Border, TextEditor.LeftMargin.LineNumbers, TextEditor.LeftMargin.LineState,
  TextEditor.LeftMargin.Marks, TextEditor.LeftMargin.MarksPanel, TextEditor.Marks;

type
  TLeftMarginGetTextEvent = procedure(ASender: TObject; ALine: Integer; var AText: string) of object;
  TLeftMarginPaintEvent = procedure(ASender: TObject; ALine: Integer; X, Y: Integer) of object;
  TLeftMarginClickEvent = procedure(ASender: TObject; AButton: TMouseButton; X, Y, ALine: Integer; AMark: TTextEditorMark) of object;

  TTextEditorLeftMargin = class(TPersistent)
  strict private
    FAutosize: Boolean;
    FBookmarks: TTextEditorLeftMarginBookmarks;
    FBorder: TTextEditorLeftMarginBorder;
    FCursor: TCursor;
    FLineState: TTextEditorLeftMarginLineState;
    FLineNumbers: TTextEditorLeftMarginLineNumbers;
    FMarks: TTextEditorLeftMarginMarks;
    FMarksPanel: TTextEditorLeftMarginMarksPanel;
    FOnChange: TNotifyEvent;
    FVisible: Boolean;
    FWidth: Integer;
    procedure DoChange;
    procedure SetAutosize(const AValue: Boolean);
    procedure SetBookmarks(const AValue: TTextEditorLeftMarginBookmarks);
    procedure SetMarks(const AValue: TTextEditorLeftMarginMarks);
    procedure SetOnChange(const AValue: TNotifyEvent);
    procedure SetVisible(const AValue: Boolean);
    procedure SetWidth(const AValue: Integer);
  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;
    function GetWidth: Integer;
    function FormatLineNumber(const ALine: Integer): string;
    function RealLeftMarginWidth(const ACharWidth: Integer): Integer;
    procedure Assign(ASource: TPersistent); override;
    procedure AutosizeDigitCount(const ALinesCount: Integer);
    procedure ChangeScale(const AMultiplier, ADivider: Integer);
    property OnChange: TNotifyEvent read FOnChange write SetOnChange;
  published
    property Autosize: Boolean read FAutosize write SetAutosize default True;
    property Bookmarks: TTextEditorLeftMarginBookmarks read FBookmarks write SetBookmarks;
    property Border: TTextEditorLeftMarginBorder read FBorder write FBorder;
    property Cursor: TCursor read FCursor write FCursor default crDefault;
    property LineNumbers: TTextEditorLeftMarginLineNumbers read FLineNumbers write FLineNumbers;
    property LineState: TTextEditorLeftMarginLineState read FLineState write FLineState;
    property Marks: TTextEditorLeftMarginMarks read FMarks write SetMarks;
    property MarksPanel: TTextEditorLeftMarginMarksPanel read FMarksPanel write FMarksPanel;
    property Visible: Boolean read FVisible write SetVisible default True;
    property Width: Integer read FWidth write SetWidth default 50;
  end;

implementation

uses
  Winapi.Windows, System.Math, System.SysUtils, TextEditor.Types;

constructor TTextEditorLeftMargin.Create(AOwner: TComponent);
begin
  inherited Create;

  FAutosize := True;
  FCursor := crDefault;
  FBorder := TTextEditorLeftMarginBorder.Create;
  FWidth := 50;
  FVisible := True;

  FBookmarks := TTextEditorLeftMarginBookmarks.Create(AOwner);
  FMarks := TTextEditorLeftMarginMarks.Create(AOwner);
  FLineState := TTextEditorLeftMarginLineState.Create;
  FLineNumbers := TTextEditorLeftMarginLineNumbers.Create;
  FMarksPanel := TTextEditorLeftMarginMarksPanel.Create;
end;

destructor TTextEditorLeftMargin.Destroy;
begin
  FBookmarks.Free;
  FMarks.Free;
  FBorder.Free;
  FLineState.Free;
  FLineNumbers.Free;
  FMarksPanel.Free;

  inherited Destroy;
end;

procedure TTextEditorLeftMargin.ChangeScale(const AMultiplier, ADivider: Integer);
begin
  FWidth := MulDiv(FWidth, AMultiplier, ADivider);
  FBookmarks.ChangeScale(AMultiplier, ADivider);
  FMarks.ChangeScale(AMultiplier, ADivider);
  FLineState.ChangeScale(AMultiplier, ADivider);
  FMarksPanel.ChangeScale(AMultiplier, ADivider);

  DoChange;
end;

procedure TTextEditorLeftMargin.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorLeftMargin) then
  with ASource as TTextEditorLeftMargin do
  begin
    Self.FAutosize := FAutosize;
    Self.FBookmarks.Assign(FBookmarks);
    Self.FMarks.Assign(FMarks);
    Self.FBorder.Assign(FBorder);
    Self.FCursor := FCursor;
    Self.FLineNumbers.Assign(FLineNumbers);
    Self.FMarksPanel.Assign(FMarksPanel);
    Self.FWidth := FWidth;
    Self.FVisible := FVisible;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorLeftMargin.SetOnChange(const AValue: TNotifyEvent);
begin
  FOnChange := AValue;

  FBookmarks.OnChange := AValue;
  FBorder.OnChange := AValue;
  FLineState.OnChange := AValue;
  FLineNumbers.OnChange := AValue;
  FMarksPanel.OnChange := AValue;
end;

procedure TTextEditorLeftMargin.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TTextEditorLeftMargin.RealLeftMarginWidth(const ACharWidth: Integer): Integer;
var
  LPanelWidth: Integer;
begin
  LPanelWidth := FMarksPanel.Width;
  if not FMarksPanel.Visible and not FBookmarks.Visible and not FMarks.Visible then
    LPanelWidth := 0;

  if not FVisible then
    Result := 0
  else
  if FLineNumbers.Visible then
    Result := LPanelWidth + FLineState.Width + FLineNumbers.AutosizeDigitCount * ACharWidth + 5
  else
    Result := FWidth;
end;

function TTextEditorLeftMargin.GetWidth: Integer;
begin
  if FVisible then
    Result := FWidth
  else
    Result := 0;
end;

procedure TTextEditorLeftMargin.SetAutosize(const AValue: Boolean);
begin
  if FAutosize <> AValue then
  begin
    FAutosize := AValue;
    DoChange
  end;
end;

procedure TTextEditorLeftMargin.SetWidth(const AValue: Integer);
var
  LValue: Integer;
begin
  LValue := Max(0, AValue);
  if FWidth <> LValue then
  begin
    FWidth := LValue;
    DoChange
  end;
end;

procedure TTextEditorLeftMargin.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    DoChange
  end;
end;

procedure TTextEditorLeftMargin.SetBookmarks(const AValue: TTextEditorLeftMarginBookmarks);
begin
  FBookmarks.Assign(AValue);
end;

procedure TTextEditorLeftMargin.SetMarks(const AValue: TTextEditorLeftMarginMarks);
begin
  FMarks.Assign(AValue);
end;

procedure TTextEditorLeftMargin.AutosizeDigitCount(const ALinesCount: Integer);
var
  LNumberOfDigits: Integer;
  LLinesCount: Integer;
begin
  if FLineNumbers.Visible and FAutosize then
  begin
    LLinesCount := ALinesCount;
    if FLineNumbers.StartFrom = 0 then
      Dec(LLinesCount)
    else
    if FLineNumbers.StartFrom > 1 then
      Inc(LLinesCount, FLineNumbers.StartFrom - 1);

    LNumberOfDigits := Max(Length(LLinesCount.ToString), FLineNumbers.DigitCount);
    if FLineNumbers.AutosizeDigitCount <> LNumberOfDigits then
    begin
      FLineNumbers.AutosizeDigitCount := LNumberOfDigits;
      if Assigned(FOnChange) then
        FOnChange(Self);
    end;
  end
  else
    FLineNumbers.AutosizeDigitCount := FLineNumbers.DigitCount;
end;

function TTextEditorLeftMargin.FormatLineNumber(const ALine: Integer): string;
var
  LIndex: Integer;
  LLine: Integer;
begin
  LLine := ALine;
  if FLineNumbers.StartFrom = 0 then
    Dec(LLine)
  else
  if FLineNumbers.StartFrom > 1 then
    Inc(LLine, FLineNumbers.StartFrom - 1);

  Result := Format('%*d', [FLineNumbers.AutosizeDigitCount, LLine]);

  if lnoLeadingZeros in FLineNumbers.Options then
  for LIndex := 1 to FLineNumbers.AutosizeDigitCount - 1 do
  begin
    if Result[LIndex] <> ' ' then
      Break;
    Result[LIndex] := '0';
  end;
end;

end.
