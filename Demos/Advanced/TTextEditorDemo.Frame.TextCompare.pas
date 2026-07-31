unit TTextEditorDemo.Frame.TextCompare;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms, Vcl.Graphics, TextEditor,
  TextEditor.Compare.ScrollBar;

type
  TFrameTextCompare = class(TFrame)
    CompareScrollBar: TTextEditorCompareScrollBar;
    EditorCompareLeft: TTextEditor;
    EditorCompareRight: TTextEditor;
    GridPanel: TGridPanel;
    procedure CompareTimerTimer(Sender: TObject);
    procedure EditorCompareAfterLinePaint(const ASender: TObject; const ACanvas: TCanvas; const ARect: TRect; const ALineNumber: Integer; const AIsMinimapLine: Boolean);
    procedure EditorCompareChange(Sender: TObject);
    procedure EditorCompareCustomLineColors(const ASender: TObject; const ALine: Integer; var AUseColors: Boolean; var AForeground, ABackground: TColor);
    procedure EditorCompareScroll(const ASender: TObject; const AScrollBar: TScrollBarKind);
  private
    FCompareTimer: TTimer;
    FComparing: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    procedure CompareEditors;
  end;

implementation

{$R *.dfm}

uses
  System.Generics.Collections, System.Math, TextEditor.Lines, TextEditor.Types;

type
  TCompareRow = (crSame, crModify, crLeftOnly, crRightOnly);

const
  CompareSampleLeft = '''
    unit Calculator;

    interface

    uses
      System.SysUtils;

    function Add(const A, B: Integer): Integer;
    function Subtract(const A, B: Integer): Integer;

    implementation

    function Add(const A, B: Integer): Integer;
    begin
      Result := A + B;
    end;

    { Subtraction }
    function Subtract(const A, B: Integer): Integer;
    begin
      Result := A - B;
    end;

    end.
    ''';

  CompareSampleRight = '''
    unit Calculator;

    interface

    uses
      System.Math, System.SysUtils;

    function Add(const A, B: Integer): Integer;
    function Subtract(const A, B: Integer): Integer;
    function Multiply(const A, B: Integer): Integer;

    implementation

    function Add(const A, B: Integer): Integer;
    begin
      Result := A + B;
    end;

    function Subtract(const A, B: Integer): Integer;
    begin
      Result := A - B;
    end;

    function Multiply(const A, B: Integer): Integer;
    begin
      Result := A * B;
    end;

    end.
    ''';

constructor TFrameTextCompare.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FCompareTimer := TTimer.Create(Self);
  FCompareTimer.Enabled := False;
  FCompareTimer.Interval := 300;
  FCompareTimer.OnTimer := CompareTimerTimer;

  EditorCompareLeft.Lines.Text := CompareSampleLeft;
  EditorCompareRight.Lines.Text := CompareSampleRight;
end;

procedure TFrameTextCompare.CompareTimerTimer(Sender: TObject);
begin
  FCompareTimer.Enabled := False;
  CompareEditors;
end;

procedure TFrameTextCompare.EditorCompareAfterLinePaint(const ASender: TObject; const ACanvas: TCanvas; const ARect: TRect;
  const ALineNumber: Integer; const AIsMinimapLine: Boolean);
var
  LEditor: TTextEditor;
  LBrushStyle: TBrushStyle;
begin
  LEditor := ASender as TTextEditor;

  if (ALineNumber < LEditor.Lines.Count) and (sfEmptyLine in LEditor.Lines.Flags[ALineNumber]) then
  begin
    LBrushStyle := ACanvas.Brush.Style;

    ACanvas.Brush.Color := LEditor.Colors.CodeFoldingCollapsedLine;
    ACanvas.Brush.Style := bsBDiagonal;

    SetBkColor(ACanvas.Handle, ColorToRGB(LEditor.Colors.EditorBackground));

    ACanvas.FillRect(ARect);
    ACanvas.Brush.Style := LBrushStyle;
  end;
end;

procedure TFrameTextCompare.EditorCompareChange(Sender: TObject);
begin
  if FComparing or not Assigned(FCompareTimer) then
    Exit;

  FCompareTimer.Enabled := False;
  FCompareTimer.Enabled := True;
end;

procedure TFrameTextCompare.EditorCompareCustomLineColors(const ASender: TObject; const ALine: Integer; var AUseColors: Boolean;
  var AForeground, ABackground: TColor);
begin
  var LEditor := ASender as TTextEditor;
  var LOther := if LEditor = EditorCompareLeft then EditorCompareRight else EditorCompareLeft;

  if (ALine < LEditor.Lines.Count) and (sfModify in LEditor.Lines.Flags[ALine]) or
    (ALine < LOther.Lines.Count) and (sfEmptyLine in LOther.Lines.Flags[ALine]) then
  begin
    AForeground := LEditor.Colors.CompareForeground;
    ABackground := LEditor.Colors.CompareBackground;
    AUseColors := True;
  end;
end;

procedure TFrameTextCompare.EditorCompareScroll(const ASender: TObject; const AScrollBar: TScrollBarKind);
begin
  if AScrollBar = TScrollBarKind.sbVertical then
    CompareScrollBar.TopLine := (ASender as TTextEditor).TopLine;
end;

procedure TFrameTextCompare.CompareEditors;
var
  LRows: TList<TCompareRow>;
  LHashesLeft, LHashesRight: TArray<Cardinal>;
  LLcs: TArray<TArray<Integer>>;
  LCountLeft, LCountRight: Integer;
  LIndexLeft, LIndexRight: Integer;
  LLeftRun, LRightRun: Integer;

  function HashLine(const ALine: string): Cardinal;
  const
    FNV_OFFSET_BASIS = 2166136261;
    FNV_PRIME = 16777619;
  begin
    Result := FNV_OFFSET_BASIS;

    for var LIndex := 1 to ALine.Length do
      Result := (Result xor Cardinal(Ord(ALine[LIndex]))) * FNV_PRIME;
  end;

  procedure AddPendingRows;
  begin
    while (LLeftRun > 0) and (LRightRun > 0) do
    begin
      LRows.Add(crModify);
      Dec(LLeftRun);
      Dec(LRightRun);
    end;

    while LLeftRun > 0 do
    begin
      LRows.Add(crLeftOnly);
      Dec(LLeftRun);
    end;

    while LRightRun > 0 do
    begin
      LRows.Add(crRightOnly);
      Dec(LRightRun);
    end;
  end;

begin
  FComparing := True;
  try
    EditorCompareLeft.Lines.ClearCompareFlags;
    EditorCompareRight.Lines.ClearCompareFlags;

    LCountLeft := EditorCompareLeft.Lines.Count;
    LCountRight := EditorCompareRight.Lines.Count;

    SetLength(LHashesLeft, LCountLeft);

    for var LIndex := 0 to LCountLeft - 1 do
      LHashesLeft[LIndex] := HashLine(EditorCompareLeft.Lines[LIndex]);

    SetLength(LHashesRight, LCountRight);

    for var LIndex := 0 to LCountRight - 1 do
      LHashesRight[LIndex] := HashLine(EditorCompareRight.Lines[LIndex]);

    SetLength(LLcs, LCountLeft + 1, LCountRight + 1);

    for var LLeft := LCountLeft - 1 downto 0 do
    for var LRight := LCountRight - 1 downto 0 do
      LLcs[LLeft, LRight] :=
        if LHashesLeft[LLeft] = LHashesRight[LRight] then
          LLcs[LLeft + 1, LRight + 1] + 1
        else
          Max(LLcs[LLeft + 1, LRight], LLcs[LLeft, LRight + 1]);

    LRows := TList<TCompareRow>.Create;
    try
      LIndexLeft := 0;
      LIndexRight := 0;
      LLeftRun := 0;
      LRightRun := 0;

      while (LIndexLeft < LCountLeft) and (LIndexRight < LCountRight) do
      if LHashesLeft[LIndexLeft] = LHashesRight[LIndexRight] then
      begin
        AddPendingRows;
        LRows.Add(crSame);
        Inc(LIndexLeft);
        Inc(LIndexRight);
      end
      else
      if LLcs[LIndexLeft + 1, LIndexRight] >= LLcs[LIndexLeft, LIndexRight + 1] then
      begin
        Inc(LLeftRun);
        Inc(LIndexLeft);
      end
      else
      begin
        Inc(LRightRun);
        Inc(LIndexRight);
      end;

      Inc(LLeftRun, LCountLeft - LIndexLeft);
      Inc(LRightRun, LCountRight - LIndexRight);
      AddPendingRows;

      EditorCompareLeft.Lines.BeginUpdate;
      EditorCompareRight.Lines.BeginUpdate;
      try
        for var LIndex := 0 to LRows.Count - 1 do
        case LRows[LIndex] of
          crModify:
            begin
              EditorCompareLeft.Lines.IncludeFlag(LIndex, sfModify);
              EditorCompareRight.Lines.IncludeFlag(LIndex, sfModify);
            end;
          crLeftOnly:
            EditorCompareRight.Lines.InsertLine(LIndex, sfEmptyLine);
          crRightOnly:
            EditorCompareLeft.Lines.InsertLine(LIndex, sfEmptyLine);
        end;
      finally
        EditorCompareLeft.Lines.EndUpdate;

        if Assigned(EditorCompareLeft.Lines.OnInserted) then
          EditorCompareLeft.Lines.OnInserted(EditorCompareLeft.Lines, 0, EditorCompareLeft.Lines.Count);

        EditorCompareRight.Lines.EndUpdate;

        if Assigned(EditorCompareRight.Lines.OnInserted) then
          EditorCompareRight.Lines.OnInserted(EditorCompareRight.Lines, 0, EditorCompareRight.Lines.Count);
      end;
    finally
      LRows.Free;
    end;

    CompareScrollBar.Invalidate;
    EditorCompareLeft.Invalidate;
    EditorCompareRight.Invalidate;
  finally
    FComparing := False;
  end;
end;

end.
