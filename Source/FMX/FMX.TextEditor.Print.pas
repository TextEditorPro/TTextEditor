{$WARN WIDECHAR_REDUCED OFF} // CharInSet is slow in loops
unit FMX.TextEditor.Print;

interface

uses
  System.Classes, System.SysUtils, System.Types, System.UITypes, FMX.Graphics, FMX.Types, FMX.TextEditor, FMX.TextEditor.Highlighter,
  FMX.TextEditor.Lines, FMX.TextEditor.PaintHelper, FMX.TextEditor.Print.HeaderFooter, FMX.TextEditor.Print.Margins,
  FMX.TextEditor.Print.PrinterInfo, FMX.TextEditor.Selection, FMX.TextEditor.Types, FMX.TextEditor.Utils;

type
  TTextEditorPageLine = class
  private
    FFirstLine: Integer;
  public
    property FirstLine: Integer read FFirstLine write FFirstLine;
  end;

  [ComponentPlatformsAttribute(pidWin32 or pidWin64 or pidOSX64 or pidOSXArm64 or pidiOSDevice64 or pidiOSSimulatorArm64 or pidAndroidArm32 or pidAndroidArm64 or pidLinux64)]
  TTextEditorPrint = class(TComponent)
  strict private
    FAbort: Boolean;
    FBlockBeginPosition: TTextEditorTextPosition;
    FBlockEndPosition: TTextEditorTextPosition;
    FCanvas: TCanvas;
    FCharWidth: Integer;
    FColors: Boolean;
    FColumns: Boolean;
    FCopies: Integer;
    FDefaultBackground: TAlphaColor;
    FDocumentTitle: string;
    FEditor: TCustomTextEditor;
    FFont: TFont;
    FFontColor: TAlphaColor;
    FFooter: TTextEditorPrintFooter;
    FHeader: TTextEditorPrintHeader;
    FHighlight: Boolean;
    FHighlighter: TTextEditorHighlighter;
    FHighlighterRangesSet: Boolean;
    FLineHeight: Integer;
    FLineNumber: Integer;
    FLineNumbers: Boolean;
    FLineNumbersInMargin: Boolean;
    FLineOffset: Integer;
    FLines: TStrings;
    FMargins: TTextEditorPrintMargins;
    FMaxColumn: Integer;
    FMaxLeftChar: Integer;
    FMaxWidth: Integer;
    FOldFont: TFont;
    FOnPrintLine: TTextEditorPrintLineEvent;
    FOnPrintStatus: TTextEditorPrintStatusEvent;
    FPageCount: Integer;
    FPageOffset: Integer;
    FPages: TList;
    FPagesCounted: Boolean;
    FPaintHelper: TTextEditorPaintHelper;
    FPrinterInfo: TTextEditorPrinterInfo;
    FPrinting: Boolean;
    FSelectedOnly: Boolean;
    FSelectionAvailable: Boolean;
    FSelectionMode: TTextEditorSelectionMode;
    FTabWidth: Integer;
    FTitle: string;
    FWordWrap: Boolean;
    FYPos: Integer;
    function ClipLineToRect(var ALine: string): string;
    function GetPageCount: Integer;
    function WrapTextEx(const ALine: string; const ABreakChars: TSysCharSet; const AMaxColumn: Integer; const AList: TList): Boolean;
    procedure CalculatePages;
    procedure HandleWrap(const AText: string);
    procedure InitHighlighterRanges;
    procedure InitPrint;
    procedure PrintPage(APageNumber: Integer);
    procedure RestoreFont;
    procedure SaveFont;
    procedure SetCharWidth(const AValue: Integer);
    procedure SetEditor(const AValue: TCustomTextEditor);
    procedure SetFont(const AValue: TFont);
    procedure SetFooter(const AValue: TTextEditorPrintFooter);
    procedure SetHeader(const AValue: TTextEditorPrintHeader);
    procedure SetHighlighter(const AValue: TTextEditorHighlighter);
    procedure SetLines(const AValue: TTextEditorLines);
    procedure SetMargins(const AValue: TTextEditorPrintMargins);
    procedure SetMaxLeftChar(const aValue: Integer);
    procedure SetWordWrap(const AValue: Boolean);
    procedure TextOut(const AText: string; const AList: TList);
    procedure WriteLine(const AText: string);
    procedure WriteLineNumber;
  protected
    procedure PrintStatus(const AStatus: TTextEditorPrintStatus; const APageNumber: Integer; var AAbort: Boolean); virtual;
    property CharWidth: Integer read FCharWidth write SetCharWidth;
    property MaxLeftChar: Integer read FMaxLeftChar write SetMaxLeftChar;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure LoadFromStream(const AStream: TStream);
    procedure Print(const AStartPage: Integer = 1; const AEndPage: Integer = -1);
    procedure PrintToCanvas(const ACanvas: TCanvas; const PageNumber: Integer);
    procedure SaveToStream(const AStream: TStream);
    procedure UpdatePages(const ACanvas: TCanvas);
    property Editor: TCustomTextEditor read FEditor write SetEditor;
    property PageCount: Integer read GetPageCount;
    property PrinterInfo: TTextEditorPrinterInfo read FPrinterInfo;
  published
    property Color: TAlphaColor read FDefaultBackground write FDefaultBackground;
    property Colors: Boolean read FColors write FColors default False;
    property Copies: Integer read FCopies write FCopies;
    property DocumentTitle: string read FDocumentTitle write FDocumentTitle;
    property Font: TFont read FFont write SetFont;
    property Footer: TTextEditorPrintFooter read FFooter write SetFooter;
    property Header: TTextEditorPrintHeader read FHeader write SetHeader;
    property Highlight: Boolean read FHighlight write FHighlight default True;
    property Highlighter: TTextEditorHighlighter read FHighlighter write SetHighlighter;
    property LineNumbers: Boolean read FLineNumbers write FLineNumbers default False;
    property LineNumbersInMargin: Boolean read FLineNumbersInMargin write FLineNumbersInMargin default False;
    property LineOffset: Integer read FLineOffset write FLineOffset default 0;
    property Margins: TTextEditorPrintMargins read FMargins write SetMargins;
    property OnPrintLine: TTextEditorPrintLineEvent read FOnPrintLine write FOnPrintLine;
    property OnPrintStatus: TTextEditorPrintStatusEvent read FOnPrintStatus write FOnPrintStatus;
    property PageOffset: Integer read FPageOffset write FPageOffset default 0;
    property SelectedOnly: Boolean read FSelectedOnly write FSelectedOnly default False;
    property Title: string read FTitle write FTitle;
    property WordWrap: Boolean read FWordWrap write SetWordWrap default True;
  end;

implementation

uses
  System.Math, System.Math.Vectors, FMX.Controls, FMX.Printer, FMX.TextEditor.Consts, FMX.TextEditor.Highlighter.Attributes;

{ TTextEditorPrint }

constructor TTextEditorPrint.Create(AOwner: TComponent);
var
  LFont: TFont;
begin
  inherited;

  FFooter := TTextEditorPrintFooter.Create;
  FHeader := TTextEditorPrintHeader.Create;
  FLines := TStringList.Create;
  FMargins := TTextEditorPrintMargins.Create;
  FPrinterInfo := TTextEditorPrinterInfo.Create;
  FFont := TFont.Create;
  FOldFont := TFont.Create;

  FCopies := 1;
  FMaxLeftChar := 1024;
  FWordWrap := True;
  FHighlight := True;
  FColors := False;
  FLineNumbers := False;
  FLineOffset := 0;
  FPageOffset := 0;
  FLineNumbersInMargin := False;
  FPages := TList.Create;
  FTabWidth := 8;
  FDefaultBackground := TAlphaColors.White;

  LFont := TFont.Create;
  try
    LFont.Family := 'Courier New';
    LFont.Size := 13;
    FPaintHelper := TTextEditorPaintHelper.Create([TFontStyle.fsBold], LFont);
  finally
    LFont.Free;
  end;
end;

destructor TTextEditorPrint.Destroy;
begin
  FFooter.Free;
  FHeader.Free;
  FLines.Free;
  FMargins.Free;
  FPrinterInfo.Free;
  FFont.Free;
  FOldFont.Free;

  for var LIndex := FPages.Count - 1 downto 0 do
    TTextEditorPageLine(FPages[LIndex]).Free;

  FPages.Free;
  FPaintHelper.Free;

  inherited;
end;

procedure TTextEditorPrint.SetLines(const AValue: TTextEditorLines);
var
  LPosition: Integer;
  LLine: string;
  LHasTabs: Boolean;
begin
  with FLines do
  begin
    BeginUpdate;
    try
      Clear;

      for var LIndex := 0 to AValue.Count - 1 do
      begin
        LLine := ConvertTabs(AValue[LIndex], FTabWidth, LHasTabs, FColumns);
        LPosition := Pos(TControlCharacters.Tab, LLine);

        while LPosition > 0 do
        begin
          LLine[LPosition] := ' ';
          LPosition := Pos(TControlCharacters.Tab, LLine);
        end;

        Add(LLine);
      end;
    finally
      EndUpdate;
    end;
  end;

  FHighlighterRangesSet := False;
  FPagesCounted := False;
end;

procedure TTextEditorPrint.SetFont(const AValue: TFont);
begin
  FFont.Assign(AValue);
  FPagesCounted := False;
end;

procedure TTextEditorPrint.SetCharWidth(const AValue: Integer);
begin
  if FCharWidth <> AValue then
    FCharWidth := AValue;
end;

procedure TTextEditorPrint.SetMaxLeftChar(const AValue: Integer);
begin
  if FMaxLeftChar <> AValue then
    FMaxLeftChar := AValue;
end;

procedure TTextEditorPrint.SetHighlighter(const AValue: TTextEditorHighlighter);
begin
  FHighlighter := AValue;
  FHighlighterRangesSet := False;
  FPagesCounted := False;
end;

procedure TTextEditorPrint.SetWordWrap(const AValue: Boolean);
begin
  if AValue <> FWordWrap then
  begin
    FWordWrap := AValue;

    if FPages.Count > 0 then
    begin
      CalculatePages;
      FHeader.NumberOfPages := FPageCount;
      FFooter.NumberOfPages := FPageCount;
   end;
  end;
end;

procedure TTextEditorPrint.InitPrint;
begin
  FFontColor := TAlphaColors.Black;

  FCanvas.Font.Assign(FFont);
  FCanvas.Font.Style := [TFontStyle.fsBold, TFontStyle.fsItalic, TFontStyle.fsUnderline, TFontStyle.fsStrikeOut];

  FPaintHelper.SetBaseFont(FFont);
  FPaintHelper.SetStyle(FFont.Style);

  CharWidth := Round(FPaintHelper.CharWidth);
  FLineHeight := Round(FPaintHelper.CharHeight);

  FMargins.InitPage(FCanvas, 1, FPrinterInfo, FLineNumbers, FLineNumbersInMargin, FLines.Count - 1 + FLineOffset);
  CalculatePages;
  FHeader.InitPrint(FCanvas, FPageCount, FTitle, FMargins);
  FFooter.InitPrint(FCanvas, FPageCount, FTitle, FMargins);
end;

procedure TTextEditorPrint.InitHighlighterRanges;
var
  LIndex: Integer;
begin
  if not FHighlighterRangesSet and Assigned(FHighlighter) and (FLines.Count > 0) then
  begin
    FHighlighter.ResetRange;
    FLines.Objects[0] := FHighlighter.Range;

    LIndex := 1;

    while LIndex < FLines.Count do
    begin
      FHighlighter.SetLine(FLines[LIndex - 1]);
      FHighlighter.NextToEndOfLine;
      FLines.Objects[LIndex] := FHighlighter.Range;
      Inc(LIndex);
    end;

    FHighlighterRangesSet := True;
  end;
end;

procedure TTextEditorPrint.CalculatePages;
var
  LYPos: Integer;
  LList: TList;

  procedure CountWrapped;
  begin
    LYPos := LYPos + LList.Count * FLineHeight;
  end;

var
  LPageLine: TTextEditorPageLine;
  LStartLine, LEndLine: Integer;
  LText: string;
  LSelectionStart, LSelectionLength: Integer;
begin
  InitHighlighterRanges;

  for var LIndex := 0 to FPages.Count - 1 do
    TTextEditorPageLine(FPages[LIndex]).Free;

  FPages.Clear;

  FMaxWidth := FMargins.PixelRight - FMargins.PixelLeft;
  FMaxColumn := FMaxWidth div Max(1, Round(TextAdvance(FCanvas, 'W'))) - 1;
  FMaxWidth := Round(TextAdvance(FCanvas, StringOfChar('W', FMaxColumn)));
  FPageCount := 1;

  LPageLine := TTextEditorPageLine.Create;

  LPageLine.FirstLine := 0;
  FPages.Add(LPageLine);

  LYPos := FMargins.PixelTop;

  if SelectedOnly then
  begin
    LStartLine := FBlockBeginPosition.Line - 1;
    LEndLine := FBlockEndPosition.Line - 1;
  end
  else
  begin
    LStartLine := 0;
    LEndLine := FLines.Count - 1;
  end;

  for var LIndex := LStartLine to LEndLine do
  begin
    if LYPos + FLineHeight > FMargins.PixelBottom then
    begin
      LYPos := FMargins.PixelTop;
      FPageCount := FPageCount + 1;
      LPageLine := TTextEditorPageLine.Create;
      LPageLine.FirstLine := LIndex;
      FPages.Add(LPageLine);
    end;

    if FWordWrap then
    begin
      if not FSelectedOnly then
        LText := FLines[LIndex]
      else
      begin
        LSelectionStart := if (FSelectionMode = smColumn) or (LIndex = FBlockBeginPosition.Line - 1) then FBlockBeginPosition.Char else 1;
        LSelectionLength := if (FSelectionMode = smColumn) or (LIndex = FBlockEndPosition.Line - 1) then FBlockEndPosition.Char - LSelectionStart else MaxInt;

        LText := Copy(FLines[LIndex], LSelectionStart, LSelectionLength);
      end;

      if TextAdvance(FCanvas, LText) > FMaxWidth then
      begin
        LList := TList.Create;
        try
          if WrapTextEx(LText, [' ', '-', TControlCharacters.Tab, ',', ';', ')', '.'], FMaxColumn, LList) then
            CountWrapped
          else
          while LText.Length > 0 do
          begin
            Delete(LText, 1, FMaxColumn);

            if LText.Length > 0 then
              LYPos := LYPos + FLineHeight;
          end;

          for var LIndex2 := LList.Count - 1 downto 0 do
            TTextEditorWrapPosition(LList[LIndex2]).Free;
        finally
          LList.Free;
        end;
      end;
    end;

    LYPos := LYPos + FLineHeight;
  end;
  FPagesCounted := True;
end;

procedure TTextEditorPrint.WriteLineNumber;
var
  LLineNumber: string;
  LWidth: Single;
begin
  SaveFont;

  LLineNumber := (FLineNumber + FLineOffset).ToString + ': ';

  FCanvas.Font.Style := [];
  LWidth := TextAdvance(FCanvas, LLineNumber);
  FCanvas.Fill.Kind := TBrushKind.Solid;
  FCanvas.Fill.Color := TAlphaColors.Black;
  FCanvas.FillText(RectF(FMargins.PixelLeft - LWidth, FYPos, FMargins.PixelLeft + LWidth, FYPos + FLineHeight), LLineNumber, False, 1, [], TTextAlign.Leading, TTextAlign.Leading);
  RestoreFont;
end;

procedure TTextEditorPrint.HandleWrap(const AText: string);
var
  LList: TList;

  procedure WrapPrimitive;
  var
    LIndex: Integer;
    LText: string;
    LWrapPosition: TTextEditorWrapPosition;
  begin
    LIndex := 1;

    while LIndex <= AText.Length do
    begin
      LText := '';

      while (Length(LText) < FMaxColumn) and (LIndex <= AText.Length) do
      begin
        LText := LText + AText[LIndex];
        Inc(LIndex);
      end;

      LWrapPosition := TTextEditorWrapPosition.Create;
      LWrapPosition.Index := LIndex - 1;

      LList.Add(LWrapPosition);

      if (Length(LText) - LIndex) <= FMaxColumn then
        Break;
    end;
  end;

begin
  LList := TList.Create;
  try
    if WrapTextEx(AText, [' ', '-', TControlCharacters.Tab, ',', ';', ')', '.'], FMaxColumn, LList) then
      TextOut(AText, LList)
    else
    begin
      WrapPrimitive;
      TextOut(AText, LList);
    end;

    for var LListIndex := LList.Count - 1 downto 0 do
      TTextEditorWrapPosition(LList[LListIndex]).Free;
  finally
    LList.Free;
  end;
end;

procedure TTextEditorPrint.SaveFont;
begin
  FOldFont.Assign(FCanvas.Font);
end;

procedure TTextEditorPrint.RestoreFont;
begin
  FCanvas.Font.Assign(FOldFont);
end;

function TTextEditorPrint.ClipLineToRect(var ALine: string): string;
begin
  while TextAdvance(FCanvas, ALine) > FMaxWidth do
    SetLength(ALine, ALine.Length - 1);

  Result := ALine;
end;

procedure TTextEditorPrint.TextOut(const AText: string; const AList: TList);
var
  LClipRect: TRectF;
  LTextColor: TAlphaColor;

  procedure ClippedTextOut(const X, Y: Single; AText: string);
  begin
    AText := ClipLineToRect(AText);

    FCanvas.Fill.Kind := TBrushKind.Solid;
    FCanvas.Fill.Color := LTextColor;
    FCanvas.FillText(RectF(X, Y, X + TextWidth(FCanvas, AText) + 2, Y + FLineHeight), AText, False, 1, [], TTextAlign.Leading, TTextAlign.Leading);
  end;

var
  LToken: string;
  LTokenPosition, LTokenStart: Integer;
  LCount: Integer;

  procedure SplitToken;
  var
    LLast, LFirstPosition, LTokenEnd: Integer;
    LTempText: string;
  begin
    LLast := LTokenPosition;
    LFirstPosition := LTokenPosition;
    LTokenEnd := LTokenPosition + LToken.Length;

    while (LCount < AList.Count) and (LTokenEnd > TTextEditorWrapPosition(AList[LCount]).Index) do
    begin
      LTempText := Copy(AText, LLast + 1, TTextEditorWrapPosition(AList[LCount]).Index - LLast);
      LLast := TTextEditorWrapPosition(AList[LCount]).Index;
      ClippedTextOut(FMargins.PixelLeft + LFirstPosition * FPaintHelper.CharWidth, FYPos, LTempText);
      LFirstPosition := 0;
      LCount := LCount + 1;
      FYPos := FYPos + FLineHeight;
    end;

    LTempText := Copy(AText, LLast + 1, LTokenEnd - LLast);
    ClippedTextOut(FMargins.PixelLeft + LFirstPosition * FPaintHelper.CharWidth, FYPos, LTempText);
    LTokenStart := LTokenPosition + LToken.Length - LTempText.Length;
  end;

var
  LLeft: Single;
  LHighlighterAttribute: TTextEditorHighlighterAttribute;
  LColor: TAlphaColor;
  LHandled: Boolean;
  LLines: TStringList;
  LOldWrapPosition: Integer;
  LTempText: string;
  LWrapPosition: Integer;
begin
  LTextColor := FFontColor;

  with FMargins do
    LClipRect := RectF(PixelLeft, PixelTop, PixelRight, PixelBottom);

  if Highlight and Assigned(FHighlighter) and (FLines.Count > 0) then
  begin
    SaveFont;

    if FLineNumber = 0 then
      FHighlighter.ResetRange
    else
      FHighlighter.SetRange(FLines.Objects[FLineNumber - 1]);

    FHighlighter.SetLine(AText);
    LToken := '';
    LTokenStart := 0;
    LCount := 0;

    LLeft := FMargins.PixelLeft;

    while not FHighlighter.EndOfLine do
    begin
      FHighlighter.GetToken(LToken);
      LTokenPosition := FHighlighter.TokenPosition;
      LHighlighterAttribute := FHighlighter.TokenAttribute;

      LTextColor := FFontColor;

      if Assigned(LHighlighterAttribute) then
      begin
        FCanvas.Font.Style := LHighlighterAttribute.FontStyles;

        if FColors then
        begin
          LColor := LHighlighterAttribute.Foreground;

          if LColor = TAlphaColors.Null then
            LColor := FFontColor;

          LTextColor := LColor;
        end
        else
          LTextColor := TAlphaColors.Black;
      end;

      LHandled := False;

      if Assigned(AList) then
        if LCount < AList.Count then
        begin
          if LTokenPosition >= TTextEditorWrapPosition(AList[LCount]).Index then
          begin
            LLeft := FMargins.PixelLeft;
            LCount := LCount + 1;
            LTokenStart := LTokenPosition;
            FYPos := FYPos + FLineHeight;
          end
          else
          if LTokenPosition + LToken.Length > TTextEditorWrapPosition(AList[LCount]).Index then
          begin
            LHandled := True;
            SplitToken;
          end;
        end;

      if not LHandled then
      begin
        if not FWordWrap and (LLeft + TextAdvance(FCanvas, LToken) > LClipRect.Right) then
          Break;

        ClippedTextOut(LLeft, FYPos, LToken);
        LLeft := LLeft + TextAdvance(FCanvas, LToken);
      end;

      FHighlighter.Next;
    end;

    RestoreFont;
  end
  else
  begin
    LLines := TStringList.Create;
    try
      LOldWrapPosition := 0;

      if Assigned(AList) then
      for var LIndex := 0 to AList.Count - 1 do
      begin
        LWrapPosition := TTextEditorWrapPosition(AList[LIndex]).Index;

        LTempText := if LIndex = 0 then Copy(AText, 1, LWrapPosition) else Copy(AText, LOldWrapPosition + 1, LWrapPosition - LOldWrapPosition);

        LLines.Add(LTempText);
        LOldWrapPosition := LWrapPosition;
      end;

      if AText.Length > 0 then
        LLines.Add(Copy(AText, LOldWrapPosition + 1, MaxInt));

      for var LIndex := 0 to LLines.Count - 1 do
      begin
        ClippedTextOut(FMargins.PixelLeft, FYPos, LLines[LIndex]);

        if LIndex < LLines.Count - 1 then
          FYPos := FYPos + FLineHeight;
      end;
    finally
      LLines.Free;
    end;
  end;
end;

procedure TTextEditorPrint.WriteLine(const AText: string);
begin
  if FLineNumbers then
    WriteLineNumber;

  if FWordWrap and (TextAdvance(FCanvas, AText) > FMaxWidth) then
    HandleWrap(AText)
  else
    TextOut(AText, nil);

  FYPos := FYPos + FLineHeight;
end;

procedure TTextEditorPrint.PrintPage(APageNumber: Integer);
var
  LEndLine: Integer;
  LSelectionStart, LSelectionLength: Integer;
begin
  PrintStatus(psNewPage, APageNumber, FAbort);

  if not FAbort then
  begin
    if FDefaultBackground <> TAlphaColors.White then
    begin
      FCanvas.Fill.Kind := TBrushKind.Solid;
      FCanvas.Fill.Color := FDefaultBackground;
      FCanvas.FillRect(RectF(0, 0, FPrinterInfo.PrintableWidth, FPrinterInfo.PrintableHeight), 0, 0, [], 1);
    end;

    FMargins.InitPage(FCanvas, APageNumber, FPrinterInfo, FLineNumbers, FLineNumbersInMargin, FLines.Count - 1 + FLineOffset);
    FHeader.Print(FCanvas, APageNumber + FPageOffset);

    if FPages.Count > 0 then
    begin
      FYPos := FMargins.PixelTop;

      LEndLine := if APageNumber = FPageCount then FLines.Count - 1 else TTextEditorPageLine(FPages[APageNumber]).FirstLine - 1;

      for var LIndex := TTextEditorPageLine(FPages[APageNumber - 1]).FirstLine to LEndLine do
      begin
        FLineNumber := LIndex + 1;

        if not FSelectedOnly or ((LIndex >= FBlockBeginPosition.Line - 1) and (LIndex <= FBlockEndPosition.Line - 1)) then
        begin
          if not FSelectedOnly then
            WriteLine(FLines[LIndex])
          else
          begin
            LSelectionStart := if (FSelectionMode = smColumn) or (LIndex = FBlockBeginPosition.Line - 1) then FBlockBeginPosition.Char else 1;
            LSelectionLength := if (FSelectionMode = smColumn) or (LIndex = FBlockEndPosition.Line - 1) then FBlockEndPosition.Char - LSelectionStart else MaxInt;

            WriteLine(Copy(FLines[LIndex], LSelectionStart, LSelectionLength));
          end;

          if Assigned(FOnPrintLine) then
            FOnPrintLine(Self, LIndex + 1, APageNumber);
        end;
      end;
    end;

    FFooter.Print(FCanvas, APageNumber + FPageOffset);
  end;
end;

procedure TTextEditorPrint.UpdatePages(const ACanvas: TCanvas);
begin
  FCanvas := ACanvas;
  FPrinterInfo.UpdatePrinter;
  InitPrint;
end;

procedure TTextEditorPrint.PrintToCanvas(const ACanvas: TCanvas; const PageNumber: Integer);
begin
  FAbort := False;
  FPrinting := False;
  FCanvas := ACanvas;
  PrintPage(PageNumber);
end;

procedure TTextEditorPrint.Print(const AStartPage: Integer = 1; const AEndPage: Integer = -1);
var
  LEndPage: Integer;
  LPage: Integer;

  procedure ApplyPageScale;
  begin
    { The print pipeline works in device-independent pixels - scale them to device dots }
    FCanvas.SetMatrix(TMatrix.CreateScaling(FPrinterInfo.DotsPerDipX, FPrinterInfo.DotsPerDipY));
  end;

begin
  if FSelectedOnly and not FSelectionAvailable then
    Exit;

  LEndPage := AEndPage;

  FPrinting := True;
  FAbort := False;

  Printer.Title := if FDocumentTitle.IsEmpty then FTitle else FDocumentTitle;

  Printer.BeginDoc;

  if Printer.Printing then
  begin
    PrintStatus(psBegin, AStartPage, FAbort);
    UpdatePages(Printer.Canvas);
    ApplyPageScale;

    for var LIndex := 1 to Copies do
    begin
      LPage := AStartPage;

      if LEndPage < 0 then
        LEndPage := FPageCount;

      while (LPage <= LEndPage) and (not FAbort) do
      begin
        PrintPage(LPage);

        if not FAbort and ((LPage < LEndPage) or (LIndex < Copies)) then
        begin
          Printer.NewPage;
          ApplyPageScale;
        end;

        Inc(LPage);
      end;
    end;

    if not FAbort then
      PrintStatus(psEnd, LEndPage, FAbort);

    Printer.EndDoc;
  end;

  FPrinting := False;
end;

procedure TTextEditorPrint.PrintStatus(const AStatus: TTextEditorPrintStatus; const APageNumber: Integer; var AAbort: Boolean);
begin
  AAbort := False;

  if Assigned(FOnPrintStatus) then
    FOnPrintStatus(Self, AStatus, APageNumber, AAbort);

  if AAbort and FPrinting then
    Printer.Abort;
end;

function TTextEditorPrint.GetPageCount: Integer;
var
  LBitmap: TBitmap;
begin
  if FPagesCounted then
    Result := FPageCount
  else
  begin
    LBitmap := TBitmap.Create(8, 8);
    try
      UpdatePages(LBitmap.Canvas);
      Result := FPageCount;
      FPagesCounted := True;
    finally
      LBitmap.Free;
    end;
  end;
end;

function TTextEditorPrint.WrapTextEx(const ALine: string; const ABreakChars: TSysCharSet; const AMaxColumn: Integer; const AList: TList): Boolean;
var
  LPosition, LPreviousPosition: Integer;
  LWrapPosition: TTextEditorWrapPosition;
  LFound: Boolean;
begin
  if ALine.Length <= AMaxColumn then
  begin
    Result := True;
    Exit;
  end;

  Result := False;

  LPosition := 1;
  LPreviousPosition := 0;
  LWrapPosition := TTextEditorWrapPosition.Create;

  while LPosition <= ALine.Length do
  begin
    LFound := (LPosition - LPreviousPosition > AMaxColumn) and (LWrapPosition.Index <> 0);

    if not LFound and (ALine[LPosition] <= High(Char)) and (Char(ALine[LPosition]) in ABreakChars) then
      LWrapPosition.Index := LPosition;

    if LFound then
    begin
      Result := True;
      AList.Add(LWrapPosition);
      LPreviousPosition := LWrapPosition.Index;

      if (ALine.Length - LPreviousPosition > AMaxColumn) and (LPosition < ALine.Length) then
        LWrapPosition := TTextEditorWrapPosition.Create
      else
        Break;
    end;

    Inc(LPosition);
  end;

  if (AList.Count = 0) or (AList.Last <> LWrapPosition) then
    LWrapPosition.Free;
end;

procedure TTextEditorPrint.SetEditor(const AValue: TCustomTextEditor);
begin
  FEditor := AValue;

  if Assigned(AValue) then
  begin
    Highlighter := AValue.Highlighter;
    Font := AValue.Fonts.Text;
    CharWidth := Round(AValue.CharWidth);
    FColumns := toColumns in AValue.Tabs.Options;
    FTabWidth := AValue.Tabs.Width;
    SetLines(AValue.Lines);
    FSelectionAvailable := AValue.SelectionAvailable;
    FBlockBeginPosition := AValue.SelectionStartPosition;
    FBlockEndPosition := AValue.SelectionEndPosition;
    FSelectionMode := AValue.Selection.Mode;
  end;
end;

procedure TTextEditorPrint.LoadFromStream(const AStream: TStream);
var
  LLength, LBufferSize: Integer;
  LBuffer: PChar;
begin
  FHeader.LoadFromStream(AStream);
  FFooter.LoadFromStream(AStream);
  FMargins.LoadFromStream(AStream);

  with AStream do
  begin
    Read(LLength, SizeOf(LLength));

    LBufferSize := LLength * SizeOf(Char);

    GetMem(LBuffer, LBufferSize + SizeOf(Char));
    try
      Read(LBuffer^, LBufferSize);
      LBuffer[LBufferSize div SizeOf(Char)] := TControlCharacters.Null;
      FTitle := LBuffer;
    finally
      FreeMem(LBuffer);
    end;

    Read(LLength, SizeOf(LLength));
    LBufferSize := LLength * SizeOf(Char);
    GetMem(LBuffer, LBufferSize + SizeOf(Char));
    try
      Read(LBuffer^, LBufferSize);
      LBuffer[LBufferSize div SizeOf(Char)] := TControlCharacters.Null;
      FDocumentTitle := LBuffer;
    finally
      FreeMem(LBuffer);
    end;

    Read(FWordWrap, SizeOf(FWordWrap));
    Read(FHighlight, SizeOf(FHighlight));
    Read(FColors, SizeOf(FColors));
    Read(FLineNumbers, SizeOf(FLineNumbers));
    Read(FLineOffset, SizeOf(FLineOffset));
    Read(FPageOffset, SizeOf(FPageOffset));
  end;
end;

procedure TTextEditorPrint.SaveToStream(const AStream: TStream);
var
  LLength: Integer;
begin
  FHeader.SaveToStream(AStream);
  FFooter.SaveToStream(AStream);
  FMargins.SaveToStream(AStream);

  with AStream do
  begin
    LLength := FTitle.Length;

    Write(LLength, SizeOf(LLength));
    Write(PChar(FTitle)^, LLength * SizeOf(Char));
    LLength := FDocumentTitle.Length;
    Write(LLength, SizeOf(LLength));
    Write(PChar(FDocumentTitle)^, LLength * SizeOf(Char));
    Write(FWordWrap, SizeOf(FWordWrap));
    Write(FHighlight, SizeOf(FHighlight));
    Write(FColors, SizeOf(FColors));
    Write(FLineNumbers, SizeOf(FLineNumbers));
    Write(FLineOffset, SizeOf(FLineOffset));
    Write(FPageOffset, SizeOf(FPageOffset));
  end;
end;

procedure TTextEditorPrint.SetFooter(const AValue: TTextEditorPrintFooter);
begin
  FFooter.Assign(AValue);
end;

procedure TTextEditorPrint.SetHeader(const AValue: TTextEditorPrintHeader);
begin
  FHeader.Assign(AValue);
end;

procedure TTextEditorPrint.SetMargins(const AValue: TTextEditorPrintMargins);
begin
  FMargins.Assign(AValue);
end;

initialization

  GroupDescendentsWith(TTextEditorPrint, FMX.Controls.TControl);

end.
