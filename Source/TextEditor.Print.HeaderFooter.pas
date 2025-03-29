unit TextEditor.Print.HeaderFooter;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, System.UITypes, Vcl.Graphics, TextEditor.Print.Margins,
  TextEditor.Types, TextEditor.Utils;

type
  TTextEditorSectionItem = class
  strict private
    FAlignment: TAlignment;
    FFont: TFont;
    FIndex: Integer;
    FLineNumber: Integer;
    FText: string;
    procedure SetFont(const AValue: TFont);
  public
    constructor Create;
    destructor Destroy; override;
    function GetText(const ANumberOfPages, APageNumber: Integer; const ARoman: Boolean; const ATitle, ATime, ADate: string): string;
    procedure LoadFromStream(const AStream: TStream);
    procedure SaveToStream(const AStream: TStream);
  public
    property Alignment: TAlignment read FAlignment write FAlignment;
    property Font: TFont read FFont write SetFont;
    property &Index: Integer read FIndex write FIndex;
    property LineNumber: Integer read FLineNumber write FLineNumber;
    property Text: string read FText write FText;
  end;

  TTextEditorSectionType = (stHeader, stFooter);

  TTextEditorLineInfo = class
  public
    LineHeight: Integer;
    MaxBaseDistance: Integer;
  end;

  TTextEditorSection = class(TPersistent)
  strict private
    FDate: string;
    FDefaultFont: TFont;
    FFrameHeight: Integer;
    FFrameTypes: TTextEditorFrameTypes;
    FItems: TList;
    FLineColor: TColor;
    FLineCount: Integer;
    FLineInfo: TList;
    FMargins: TTextEditorPrintMargins;
    FMirrorPosition: Boolean;
    FNumberOfPages: Integer;
    FOldBrush: TBrush;
    FOldFont: TFont;
    FOldPen: TPen;
    FRomanNumbers: Boolean;
    FSectionType: TTextEditorSectionType;
    FShadedColor: TColor;
    FTime: string;
    FTitle: string;
    procedure CalculateHeight(const ACanvas: TCanvas);
    procedure DrawFrame(const ACanvas: TCanvas);
    procedure RestoreFontPenBrush(const ACanvas: TCanvas);
    procedure SaveFontPenBrush(const ACanvas: TCanvas);
    procedure SetDefaultFont(const AValue: TFont);
  public
    constructor Create;
    destructor Destroy; override;
    function Add(const AText: string; const AFont: TFont; const AAlignment: TAlignment; const ALineNumber: Integer): Integer;
    function Count: Integer;
    function Get(const AIndex: Integer): TTextEditorSectionItem;
    procedure Assign(ASource: TPersistent); override;
    procedure Clear;
    procedure Delete(const AIndex: Integer);
    procedure FixLines;
    procedure InitPrint(const ACanvas: TCanvas; const NumberOfPages: Integer; const Title: string; const Margins: TTextEditorPrintMargins);
    procedure LoadFromStream(const AStream: TStream);
    procedure Print(ACanvas: TCanvas; PageNum: Integer);
    procedure SaveToStream(const AStream: TStream);
    procedure SetPixelsPerInch(const AValue: Integer);
    property NumberOfPages: Integer read FNumberOfPages write FNumberOfPages;
    property SectionType: TTextEditorSectionType read FSectionType write FSectionType;
  published
    property DefaultFont: TFont read FDefaultFont write SetDefaultFont;
    property FrameTypes: TTextEditorFrameTypes read FFrameTypes write FFrameTypes default [ftLine];
    property LineColor: TColor read FLineColor write FLineColor default TColors.Black;
    property MirrorPosition: Boolean read FMirrorPosition write FMirrorPosition default False;
    property RomanNumbers: Boolean read FRomanNumbers write FRomanNumbers default False;
    property ShadedColor: TColor read FShadedColor write FShadedColor default TColors.Silver;
  end;

  TTextEditorPrintHeader = class(TTextEditorSection)
  public
    constructor Create;
  end;

  TTextEditorPrintFooter = class(TTextEditorSection)
  public
    constructor Create;
  end;

implementation

uses
  System.Math, System.Types, TextEditor.Consts;

{ TTextEditorSectionItem }

constructor TTextEditorSectionItem.Create;
begin
  inherited;

  FFont := TFont.Create;
end;

destructor TTextEditorSectionItem.Destroy;
begin
  inherited;

  FFont.Free;
end;

function TTextEditorSectionItem.GetText(const ANumberOfPages, APageNumber: Integer; const ARoman: Boolean; const ATitle, ATime, ADate: string): string;
var
  LLength, Start, Run: Integer;
  LString: string;

  procedure DoAppend(AText: string);
  begin
    Result := Result + AText;
  end;

  procedure TryAppend(var First: Integer; After: Integer);
  begin
    if After > First then
    begin
      DoAppend(Copy(LString, First, After - First));
      First := After;
    end;
  end;

  function IntToRoman(const AValue: Integer): string;
  var
    LValue: Integer;
  begin
    Result := '';

    LValue := AValue;
    while LValue >= 1000 do
    begin
      Result := Result + 'M';
      Dec(LValue, 1000);
    end;

    if LValue >= 900 then
    begin
      Result := Result + 'CM';
      Dec(LValue, 900);
    end;

    while LValue >= 500 do
    begin
      Result := Result + 'D';
      Dec(LValue, 500);
    end;

    if LValue >= 400 then
    begin
      Result := Result + 'CD';
      Dec(LValue, 400);
    end;

    while LValue >= 100 do
    begin
      Result := Result + 'C';
      Dec(LValue, 100);
    end;

    if LValue >= 90 then
    begin
      Result := Result + 'XC';
      Dec(LValue, 90);
    end;

    while LValue >= 50 do
    begin
      Result := Result + 'L';
      Dec(LValue, 50);
    end;

    if LValue >= 40 then
    begin
      Result := Result + 'XL';
      Dec(LValue, 40);
    end;

    while LValue >= 10 do
    begin
      Result := Result + 'X';
      Dec(LValue, 10);
    end;

    if LValue >= 9 then
    begin
      Result := Result + 'IX';
      Dec(LValue, 9);
    end;

    while LValue >= 5 do
    begin
      Result := Result + 'V';
      Dec(LValue, 5);
    end;

    if LValue >= 4 then
    begin
      Result := Result + 'IV';
      Dec(LValue, 4);
    end;

    while LValue > 0 do
    begin
      Result := Result + 'I';
      Dec(LValue);
    end;
  end;

  function TryExecuteMacro: Boolean;
  var
    Macro: string;
  begin
    Result := True;
    Macro := AnsiUpperCase(Copy(FText, Start, Run - Start + 1));

    if Macro = '$PAGENUM$' then
    begin
      if ARoman then
        DoAppend(IntToRoman(APageNumber))
      else
        DoAppend(IntToStr(APageNumber));

      Exit;
    end;

    if Macro = '$PAGECOUNT$' then
    begin
      if ARoman then
        DoAppend(IntToRoman(ANumberOfPages))
      else
        DoAppend(IntToStr(ANumberOfPages));

      Exit;
    end;

    if Macro = '$TITLE$' then
    begin
      DoAppend(ATitle);
      Exit;
    end;

    if Macro = '$DATE$' then
    begin
      DoAppend(ADate);
      Exit;
    end;

    if Macro = '$TIME$' then
    begin
      DoAppend(ATime);
      Exit;
    end;

    if Macro = '$DATETIME$' then
    begin
      DoAppend(ADate + ' ' + ATime);
      Exit;
    end;

    if Macro = '$TIMEDATE$' then
    begin
      DoAppend(ATime + ' ' + ADate);
      Exit;
    end;

    Result := False;
  end;

begin
  Result := '';

  LString := FText;

  if TextEditor.Utils.Trim(LString).IsEmpty then
    Exit;

  LLength := Length(LString);

  if LLength > 0 then
  begin
    Start := 1;
    Run := 1;

    while Run <= LLength do
    begin
      if LString[Run] = '$' then
      begin
        TryAppend(Start, Run);
        Inc(Run);

        while Run <= LLength do
        begin
          if LString[Run] = '$' then
          begin
            if TryExecuteMacro then
            begin
              Inc(Run);
              Start := Run;
              Break;
            end
            else
            begin
              TryAppend(Start, Run);
              Inc(Run);
            end;
          end
          else
            Inc(Run);
        end;
      end
      else
        Inc(Run);
    end;

    TryAppend(Start, Run);
  end;
end;

procedure TTextEditorSectionItem.LoadFromStream(const AStream: TStream);
var
  LCharset: TFontCharset;
  LColor: TColor;
  LHeight: Integer;
  LName: TFontName;
  LPitch: TFontPitch;
  LSize: Integer;
  LStyle: TFontStyles;
  LLength, BufferSize: Integer;
  LBuffer: Pointer;
begin
  with AStream do
  begin
    Read(LLength, SizeOf(LLength));
    BufferSize := LLength * SizeOf(Char);
    GetMem(LBuffer, BufferSize + SizeOf(Char));

    try
      Read(LBuffer^, BufferSize);
      PChar(LBuffer)[BufferSize div SizeOf(Char)] := TControlCharacters.Null;
      FText := PChar(LBuffer);
    finally
      FreeMem(LBuffer);
    end;

    Read(FLineNumber, SizeOf(FLineNumber));
    Read(LCharset, SizeOf(lCharset));
    Read(LColor, SizeOf(LColor));
    Read(LHeight, SizeOf(LHeight));
    Read(BufferSize, SizeOf(BufferSize));
    GetMem(LBuffer, BufferSize + 1);

    try
      Read(LBuffer^, BufferSize);
      PAnsiChar(LBuffer)[BufferSize div SizeOf(AnsiChar)] := TControlCharacters.Null;
      LName := string(PAnsiChar(LBuffer));
    finally
      FreeMem(LBuffer);
    end;

    Read(LPitch, SizeOf(LPitch));
    Read(LSize, SizeOf(LSize));
    Read(LStyle, SizeOf(LStyle));
    FFont.Charset := LCharset;
    FFont.Color := LColor;
    FFont.Height := LHeight;
    FFont.Name := LName;
    FFont.Pitch := LPitch;
    FFont.Size := LSize;
    FFont.Style := LStyle;
    Read(FAlignment, SizeOf(FAlignment));
  end;
end;

procedure TTextEditorSectionItem.SaveToStream(const AStream: TStream);
var
  LCharset: TFontCharset;
  LColor: TColor;
  LHeight: Integer;
  LName: TFontName;
  LPitch: TFontPitch;
  LSize: Integer;
  LStyle: TFontStyles;
  LLength: Integer;
begin
  with AStream do
  begin
    LLength := FText.Length;
    Write(LLength, SizeOf(LLength));
    Write(PChar(FText)^, LLength * SizeOf(Char));
    Write(FLineNumber, SizeOf(FLineNumber));
    lCharset := FFont.Charset;
    LColor := FFont.Color;
    LHeight := FFont.Height;
    LName := FFont.Name;
    LPitch := FFont.Pitch;
    LSize := FFont.Size;
    LStyle := FFont.Style;
    Write(LCharset, SizeOf(LCharset));
    Write(LColor, SizeOf(LColor));
    Write(LHeight, SizeOf(LHeight));
    LLength := Length(LName);
    Write(LLength, SizeOf(LLength));
    Write(PAnsiChar(AnsiString(LName))^, LLength);
    Write(LPitch, SizeOf(LPitch));
    Write(LSize, SizeOf(LSize));
    Write(LStyle, SizeOf(LStyle));
    Write(FAlignment, SizeOf(FAlignment));
  end;
end;

procedure TTextEditorSectionItem.SetFont(const AValue: TFont);
begin
  FFont.Assign(AValue);
end;

{ TTextEditorSection }

constructor TTextEditorSection.Create;
begin
  inherited;

  FFrameTypes := [ftLine];
  FShadedColor := TColors.Silver;
  FLineColor := TColors.Black;
  FItems := TList.Create;
  FDefaultFont := TFont.Create;
  FOldPen := TPen.Create;
  FOldBrush := TBrush.Create;
  FOldFont := TFont.Create;
  FRomanNumbers := False;
  FMirrorPosition := False;
  FLineInfo := TList.Create;

  with FDefaultFont do
  begin
    Name := 'Courier New';
    Size := 9;
    Color := TColors.Black;
  end;
end;

destructor TTextEditorSection.Destroy;
var
  LIndex: Integer;
begin
  Clear;

  FItems.Free;
  FDefaultFont.Free;
  FOldPen.Free;
  FOldBrush.Free;
  FOldFont.Free;

  for LIndex := 0 to FLineInfo.Count - 1 do
    TTextEditorLineInfo(FLineInfo[LIndex]).Free;

  FLineInfo.Free;

  inherited;
end;

function TTextEditorSection.Add(const AText: string; const AFont: TFont; const AAlignment: TAlignment; const ALineNumber: Integer): Integer;
var
  LSectionItem: TTextEditorSectionItem;
begin
  LSectionItem := TTextEditorSectionItem.Create;

  if not Assigned(AFont) then
    LSectionItem.Font := FDefaultFont
  else
    LSectionItem.Font := AFont;

  LSectionItem.Alignment := AAlignment;
  LSectionItem.LineNumber := ALineNumber;
  LSectionItem.Index := FItems.Add(LSectionItem);
  LSectionItem.Text := AText;

  Result := LSectionItem.Index;
end;

procedure TTextEditorSection.Delete(const AIndex: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FItems.Count - 1 do
  if TTextEditorSectionItem(FItems[LIndex]).Index = AIndex then
  begin
    FItems.Delete(LIndex);
    Break;
  end;
end;

procedure TTextEditorSection.Clear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FItems.Count - 1 do
    TTextEditorSectionItem(FItems[LIndex]).Free;

  FItems.Clear;
end;

procedure TTextEditorSection.SetDefaultFont(const AValue: TFont);
begin
  FDefaultFont.Assign(AValue);
end;

procedure TTextEditorSection.FixLines;
var
  LIndex, LCurrentLine: Integer;
  LLineInfo: TTextEditorLineInfo;
  LSectionItem: TTextEditorSectionItem;
begin
  for LIndex := 0 to FLineInfo.Count - 1 do
    TTextEditorLineInfo(FLineInfo[LIndex]).Free;

  FLineInfo.Clear;
  LCurrentLine := 0;
  FLineCount := 0;

  for LIndex := 0 to FItems.Count - 1 do
  begin
    LSectionItem := TTextEditorSectionItem(FItems[LIndex]);

    if LSectionItem.LineNumber <> LCurrentLine then
    begin
      LCurrentLine := LSectionItem.LineNumber;
      FLineCount := FLineCount + 1;
      LLineInfo := TTextEditorLineInfo.Create;
      FLineInfo.Add(LLineInfo);
    end;

    LSectionItem.LineNumber := FLineCount;
  end;
end;

procedure TTextEditorSection.CalculateHeight(const ACanvas: TCanvas);
var
  LIndex, LCurrentLine: Integer;
  LSectionItem: TTextEditorSectionItem;
  LOrginalHeight: Integer;
  LTextMetric: TTextMetric;
begin
  FFrameHeight := -1;

  if FItems.Count <= 0 then
    Exit;

  LCurrentLine := 1;
  FFrameHeight := 0;
  LOrginalHeight := FFrameHeight;

  for LIndex := 0 to FItems.Count - 1 do
  begin
    LSectionItem := TTextEditorSectionItem(FItems[LIndex]);

    if LSectionItem.LineNumber <> LCurrentLine then
    begin
      LCurrentLine := LSectionItem.LineNumber;
      LOrginalHeight := FFrameHeight;
    end;

    ACanvas.Font.Assign(LSectionItem.Font);
    GetTextMetrics(ACanvas.Handle, LTextMetric);

    with TTextEditorLineInfo(FLineInfo[LCurrentLine - 1]), LTextMetric do
    begin
      LineHeight := Max(LineHeight, TextHeight(ACanvas, 'W'));
      MaxBaseDistance := Max(MaxBaseDistance, tmHeight - tmDescent);
    end;

    FFrameHeight := Max(FFrameHeight, LOrginalHeight + TextHeight(ACanvas, 'W'));
  end;

  FFrameHeight := FFrameHeight + 2 * FMargins.PixelInternalMargin;
end;

function CompareItems(Item1, Item2: Pointer): Integer;
begin
  Result := TTextEditorSectionItem(Item1).LineNumber - TTextEditorSectionItem(Item2).LineNumber;

  if Result = 0 then
    Result := Integer(Item1) - Integer(Item2);
end;

procedure TTextEditorSection.SetPixelsPerInch(const AValue: Integer);
var
  LIndex, LSize: Integer;
  LFont: TFont;
begin
  for LIndex := 0 to FItems.Count - 1 do
  begin
    LFont := TTextEditorSectionItem(FItems[LIndex]).Font;
    LSize := LFont.Size;
    LFont.PixelsPerInch := AValue;
    LFont.Size := LSize;
  end;
end;

procedure TTextEditorSection.InitPrint(const ACanvas: TCanvas; const NumberOfPages: Integer; const Title: string; const Margins: TTextEditorPrintMargins);
begin
  SaveFontPenBrush(ACanvas);
  FDate := DateToStr(Now);
  FTime := TimeToStr(Now);
  FNumberOfPages := NumberOfPages;
  FMargins := Margins;
  FTitle := Title;
  FItems.Sort(CompareItems);
  FixLines;
  CalculateHeight(ACanvas);
  RestoreFontPenBrush(ACanvas);
end;

procedure TTextEditorSection.SaveFontPenBrush(const ACanvas: TCanvas);
begin
  FOldFont.Assign(ACanvas.Font);
  FOldBrush.Assign(ACanvas.Brush);
  FOldPen.Assign(ACanvas.Pen);
end;

procedure TTextEditorSection.RestoreFontPenBrush(const ACanvas: TCanvas);
begin
  ACanvas.Font.Assign(FOldFont);
  ACanvas.Brush.Assign(FOldBrush);
  ACanvas.Pen.Assign(FOldPen);
end;

procedure TTextEditorSection.DrawFrame(const ACanvas: TCanvas);
begin
  if FrameTypes = [] then
    Exit;

  with ACanvas, FMargins do
  begin
    Pen.Color := LineColor;
    Brush.Color := ShadedColor;

    if ftShaded in FrameTypes then
      Brush.Style := bsSolid
    else
      Brush.Style := bsClear;

    if ftBox in FrameTypes then
      Pen.Style := psSolid
    else
      Pen.Style := psClear;

    if FrameTypes * [ftBox, ftShaded] <> [] then
    begin
      if FSectionType = stHeader then
        Rectangle(PixelLeft, PixelHeader - FFrameHeight, PixelRight, PixelHeader)
      else
        Rectangle(PixelLeft, PixelFooter, PixelRight, PixelFooter + FFrameHeight);
    end;

    if ftLine in FrameTypes then
    begin
      Pen.Style := psSolid;

      if FSectionType = stHeader then
      begin
        MoveTo(PixelLeft, PixelHeader);
        LineTo(PixelRight, PixelHeader);
      end
      else
      begin
        MoveTo(PixelLeft, PixelFooter);
        LineTo(PixelRight, PixelFooter);
      end
    end;
  end;
end;

procedure TTextEditorSection.Print(ACanvas: TCanvas; PageNum: Integer);
var
  LIndex, LX, LY, LCurrentLine: Integer;
  LText: string;
  LSectionItem: TTextEditorSectionItem;
  LOldAlign: UINT;
  LAlignment: TAlignment;
begin
  SaveFontPenBrush(ACanvas);
  DrawFrame(ACanvas);
  ACanvas.Brush.Style := bsClear;

  if FSectionType = stHeader then
    LY := FMargins.PixelHeader - FFrameHeight
  else
    LY := FMargins.PixelFooter;

  LY := LY + FMargins.PixelInternalMargin;

  LCurrentLine := 1;

  for LIndex := 0 to FItems.Count - 1 do
  begin
    LSectionItem := TTextEditorSectionItem(FItems[LIndex]);
    ACanvas.Font := LSectionItem.Font;
    ACanvas.Font.Color := TColors.Black;

    if LSectionItem.LineNumber <> LCurrentLine then
    begin
      LY := LY + TTextEditorLineInfo(FLineInfo[LCurrentLine - 1]).LineHeight;
      LCurrentLine := LSectionItem.LineNumber;
    end;

    LText := LSectionItem.GetText(FNumberOfPages, PageNum, FRomanNumbers, FTitle, FTime, FDate);
    LAlignment := LSectionItem.Alignment;

    if MirrorPosition and ((PageNum mod 2) = 0) then
    case LSectionItem.Alignment of
      taRightJustify:
        LAlignment := taLeftJustify;
      taLeftJustify:
        LAlignment := taRightJustify;
    end;

    with FMargins do
    begin
      LX := PixelLeftTextIndent;

      case LAlignment of
        taRightJustify:
          LX := PixelRightTextIndent - TextWidth(ACanvas, LText);
        taCenter:
          LX := (PixelLeftTextIndent + PixelRightTextIndent - TextWidth(ACanvas, LText)) shr 1;
      end;
    end;

    LOldAlign := SetTextAlign(ACanvas.Handle, TA_BASELINE);
    Winapi.Windows.ExtTextOut(ACanvas.Handle, LX, LY + TTextEditorLineInfo(FLineInfo[LCurrentLine - 1]).MaxBaseDistance,
      0, nil, PChar(LText), Length(LText), nil);
    SetTextAlign(ACanvas.Handle, LOldAlign);
  end;

  RestoreFontPenBrush(ACanvas);
end;

procedure TTextEditorSection.Assign(ASource: TPersistent);
var
  LIndex: Integer;
  LSectionItem: TTextEditorSectionItem;
begin
  if Assigned(ASource) and (ASource is TTextEditorSection) then
  with ASource as TTextEditorSection do
  begin
    Clear;
    Self.FSectionType := FSectionType;
    Self.FFrameTypes := FFrameTypes;
    Self.FShadedColor := FShadedColor;
    Self.FLineColor := FLineColor;

    for LIndex := 0 to FItems.Count - 1 do
    begin
      LSectionItem := TTextEditorSectionItem(FItems[LIndex]);
      Self.Add(LSectionItem.Text, LSectionItem.Font, LSectionItem.Alignment, LSectionItem.LineNumber);
    end;

    Self.FDefaultFont.Assign(FDefaultFont);
    Self.FRomanNumbers := FRomanNumbers;
    Self.FMirrorPosition := FMirrorPosition;
  end
  else
    inherited Assign(ASource);
end;

function TTextEditorSection.Count: Integer;
begin
  Result := FItems.Count;
end;

function TTextEditorSection.Get(const AIndex: Integer): TTextEditorSectionItem;
begin
  Result := TTextEditorSectionItem(FItems[AIndex]);
end;

procedure TTextEditorSection.LoadFromStream(const AStream: TStream);
var
  LCount, LIndex: Integer;
  LCharset: TFontCharset;
  LColor: TColor;
  LHeight: Integer;
  LName: TFontName;
  LPitch: TFontPitch;
  LSize: Integer;
  LStyle: TFontStyles;
  LBufferSize: Integer;
  LBuffer: PAnsiChar;
begin
  with AStream do
  begin
    Read(FFrameTypes, SizeOf(FFrameTypes));
    Read(FShadedColor, SizeOf(FShadedColor));
    Read(FLineColor, SizeOf(FLineColor));
    Read(FRomanNumbers, SizeOf(FRomanNumbers));
    Read(FMirrorPosition, SizeOf(FMirrorPosition));
    Read(LCharset, SizeOf(LCharset));
    Read(LColor, SizeOf(LColor));
    Read(LHeight, SizeOf(LHeight));
    Read(LBufferSize, SizeOf(LBufferSize));
    GetMem(LBuffer, LBufferSize + 1);

    try
      Read(LBuffer^, LBufferSize);
      LBuffer[LBufferSize] := TControlCharacters.Null;
      LName := string(LBuffer);
    finally
      FreeMem(LBuffer);
    end;

    Read(LPitch, SizeOf(LPitch));
    Read(LSize, SizeOf(LSize));
    Read(LStyle, SizeOf(LStyle));
    FDefaultFont.Charset := LCharset;
    FDefaultFont.Color := LColor;
    FDefaultFont.Height := LHeight;
    FDefaultFont.Name := LName;
    FDefaultFont.Pitch := LPitch;
    FDefaultFont.Size := LSize;
    FDefaultFont.Style := LStyle;
    Read(LCount, SizeOf(LCount));

    while LCount > 0 do
    begin
      LIndex := Add('', nil, taLeftJustify, 1);
      Get(LIndex).LoadFromStream(AStream);
      Dec(LCount);
    end;
  end;
end;

procedure TTextEditorSection.SaveToStream(const AStream: TStream);
var
  LIndex, LCount: Integer;
  LCharset: TFontCharset;
  LColor: TColor;
  LHeight: Integer;
  LName: TFontName;
  LPitch: TFontPitch;
  LSize: Integer;
  LStyle: TFontStyles;
  LLength: Integer;
begin
  with AStream do
  begin
    Write(FFrameTypes, SizeOf(FFrameTypes));
    Write(FShadedColor, SizeOf(FShadedColor));
    Write(FLineColor, SizeOf(FLineColor));
    Write(FRomanNumbers, SizeOf(FRomanNumbers));
    Write(FMirrorPosition, SizeOf(FMirrorPosition));
    LCharset := FDefaultFont.Charset;
    LColor := FDefaultFont.Color;
    LHeight := FDefaultFont.Height;
    LName := FDefaultFont.Name;
    LPitch := FDefaultFont.Pitch;
    LSize := FDefaultFont.Size;
    LStyle := FDefaultFont.Style;
    Write(LCharset, SizeOf(LCharset));
    Write(LColor, SizeOf(LColor));
    Write(LHeight, SizeOf(LHeight));
    LLength := Length(LName);
    Write(LLength, SizeOf(LLength));
    Write(PAnsiChar(AnsiString(LName))^, Length(LName));
    Write(LPitch, SizeOf(LPitch));
    Write(LSize, SizeOf(LSize));
    Write(LStyle, SizeOf(LStyle));
    LCount := Count;
    Write(LCount, SizeOf(LCount));

    for LIndex := 0 to LCount - 1 do
      Get(LIndex).SaveToStream(AStream);
  end;
end;

{ TTextEditorPrintHeader }

constructor TTextEditorPrintHeader.Create;
begin
  inherited;

  SectionType := stHeader;
end;

{ TTextEditorPrintFooter }

constructor TTextEditorPrintFooter.Create;
begin
  inherited;

  SectionType := stFooter;
end;

end.
