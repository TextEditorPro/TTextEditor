unit TextEditor.Print;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, Vcl.Graphics, Vcl.Printers, TextEditor, TextEditor.Highlighter,
  TextEditor.PaintHelper, TextEditor.Print.HeaderFooter, TextEditor.Print.Margins, TextEditor.Print.PrinterInfo,
  TextEditor.Selection, TextEditor.Types, TextEditor.Utils;

type
  TTextEditorPageLine = class
  private
    FFirstLine: Integer;
  public
    property FirstLine: Integer read FFirstLine write FFirstLine;
  end;

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
    FDefaultBackground: TColor;
    FDocumentTitle: string;
    FEditor: TCustomTextEditor;
    FFont: TFont;
    FFontColor: TColor;
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
    FPaintHelper: TTextEditorPaintHelper;
    FPageCount: Integer;
    FPageOffset: Integer;
    FPages: TList;
    FPagesCounted: Boolean;
    FPrinterInfo: TTextEditorPrinterInfo;
    FPrinting: Boolean;
    FSelectionAvailable: Boolean;
    FSelectedOnly: Boolean;
    FSelectionMode: TTextEditorSelectionMode;
    FTabWidth: Integer;
    FTitle: string;
    FWrap: Boolean;
    FYPos: Integer;
    function ClipLineToRect(var ALine: string): string;
    function GetPageCount: Integer;
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
    procedure SetLines(const AValue: TStrings);
    procedure SetMargins(const AValue: TTextEditorPrintMargins);
    procedure SetMaxLeftChar(const aValue: Integer);
    procedure SetPixelsPerInch;
    procedure SetWrap(const AValue: Boolean);
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
    property Color: TColor read FDefaultBackground write FDefaultBackground;
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
    property Wrap: Boolean read FWrap write SetWrap default True;
  end;

implementation

uses
  System.Types, System.UITypes, TextEditor.Consts, TextEditor.Highlighter.Attributes;

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
  FWrap := True;
  FHighlight := True;
  FColors := False;
  FLineNumbers := False;
  FLineOffset := 0;
  FPageOffset := 0;
  FLineNumbersInMargin := False;
  FPages := TList.Create;
  FTabWidth := 8;
  FDefaultBackground := TColors.White;

  LFont := TFont.Create;
  try
    LFont.Name := 'Courier New';
    LFont.Size := 10;
    FPaintHelper := TTextEditorPaintHelper.Create([fsBold], LFont);
  finally
    LFont.Free;
  end;
end;

destructor TTextEditorPrint.Destroy;
var
  LIndex: Integer;
begin
  FEditor.Free;
  FFooter.Free;
  FHeader.Free;
  FLines.Free;
  FMargins.Free;
  FPrinterInfo.Free;
  FFont.Free;
  FOldFont.Free;
  for LIndex := FPages.Count - 1 downto 0 do
    TTextEditorPageLine(FPages[LIndex]).Free;
  FPages.Free;
  FPaintHelper.Free;

  inherited;
end;

procedure TTextEditorPrint.SetLines(const AValue: TStrings);
var
  LIndex, LPosition: Integer;
  LLine: string;
  LHasTabs: Boolean;
begin
  with FLines do
  begin
    BeginUpdate;
    try
      Clear;
      for LIndex := 0 to AValue.Count - 1 do
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

procedure TTextEditorPrint.SetWrap(const AValue: Boolean);
begin
  if AValue <> FWrap then
  begin
    FWrap := AValue;
    if FPages.Count > 0 then
    begin
      CalculatePages;
      FHeader.NumberOfPages := FPageCount;
      FFooter.NumberOfPages := FPageCount;
   end;
  end;
end;

procedure TTextEditorPrint.InitPrint;
var
  LSize: Integer;
  LTextMetric: TTextMetric;
begin
  FFontColor := FFont.Color;

  FCanvas.Font.Assign(FFont);

  SetPixelsPerInch;
  LSize := FCanvas.Font.Size;
  FCanvas.Font.PixelsPerInch := FFont.PixelsPerInch;
  FCanvas.Font.Size := LSize;
  FCanvas.Font.Style := [fsBold, fsItalic, fsUnderline, fsStrikeOut];

  GetTextMetrics(FCanvas.Handle, LTextMetric);
  CharWidth := LTextMetric.tmAveCharWidth;
  FLineHeight := LTextMetric.tmHeight + LTextMetric.tmExternalLeading;

  FPaintHelper.SetBaseFont(FFont);
  FPaintHelper.SetStyle(FFont.Style);

  FMargins.InitPage(FCanvas, 1, FPrinterInfo, FLineNumbers, FLineNumbersInMargin, FLines.Count - 1 + FLineOffset);
  CalculatePages;
  FHeader.InitPrint(FCanvas, FPageCount, FTitle, FMargins);
  FFooter.InitPrint(FCanvas, FPageCount, FTitle, FMargins);
end;

procedure TTextEditorPrint.SetPixelsPerInch;
var
  LSize: Integer;
begin
  FHeader.SetPixelsPerInch(FPrinterInfo.YPixPerInch);
  FFooter.SetPixelsPerInch(FPrinterInfo.YPixPerInch);
  LSize := FFont.Size;
  FFont.PixelsPerInch := FPrinterInfo.YPixPerInch;
  FFont.Size := LSize;
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
  LText: string;
  LIndex, LIndex2: Integer;
  LList: TList;
  LYPos: Integer;
  LPageLine: TTextEditorPageLine;
  LStartLine, LEndLine: Integer;
  LSelectionStart, LSelectionLength: Integer;

  procedure CountWrapped;
  begin
    LYPos := LYPos + LList.Count * FLineHeight;
  end;

begin
  InitHighlighterRanges;

  for LIndex := 0 to FPages.Count - 1 do
    TTextEditorPageLine(FPages[LIndex]).Free;
  FPages.Clear;

  FMaxWidth := FMargins.PixelRight - FMargins.PixelLeft;
  FMaxColumn := FMaxWidth div TextWidth(FCanvas, 'W') - 1;
  FMaxWidth := TextWidth(FCanvas, StringOfChar('W', FMaxColumn));
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

  for LIndex := LStartLine to LEndLine do
  begin
    if LYPos + FLineHeight > FMargins.PixelBottom then
    begin
      LYPos := FMargins.PixelTop;
      FPageCount := FPageCount + 1;
      LPageLine := TTextEditorPageLine.Create;
      LPageLine.FirstLine := LIndex;
      FPages.Add(LPageLine);
    end;

    if Wrap then
    begin
      if not FSelectedOnly then
        LText := FLines[LIndex]
      else
      begin
        if (FSelectionMode = smColumn) or (LIndex = FBlockBeginPosition.Line - 1) then
          LSelectionStart := FBlockBeginPosition.Char
        else
          LSelectionStart := 1;

        if (FSelectionMode = smColumn) or (LIndex = FBlockEndPosition.Line - 1) then
          LSelectionLength := FBlockEndPosition.Char - LSelectionStart
        else
          LSelectionLength := MaxInt;

        LText := Copy(FLines[LIndex], LSelectionStart, LSelectionLength);
      end;

      if TextWidth(FCanvas, LText) > FMaxWidth then
      begin
        LList := TList.Create;
        try
          if WrapTextEx(LText, [' ', '-', TControlCharacters.Tab, ','], FMaxColumn, LList) then
            CountWrapped
          else
          if WrapTextEx(LText, [';', ')', '.'], FMaxColumn, LList) then
            CountWrapped
          else
          while Length(LText) > 0 do
          begin
            Delete(LText, 1, FMaxColumn);
            if Length(LText) > 0 then
              LYPos := LYPos + FLineHeight;
          end;

          for LIndex2 := LList.Count - 1 downto 0 do
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
begin
  SaveFont;
  LLineNumber := (FLineNumber + FLineOffset).ToString + ': ';
  FCanvas.Brush.Color := FDefaultBackground;
  FCanvas.Font.Style := [];
  FCanvas.Font.Color := TColors.Black;
  FCanvas.TextOut(FMargins.PixelLeft - FCanvas.TextWidth(LLineNumber), FYPos, LLineNumber);
  RestoreFont;
end;

procedure TTextEditorPrint.HandleWrap(const AText: string);
var
  LList: TList;
  LListIndex: Integer;

  procedure WrapPrimitive;
  var
    LIndex: Integer;
    LText: string;
    LWrapPosition: TTextEditorWrapPosition;
  begin
    LIndex := 1;
    while LIndex <= Length(AText) do
    begin
      LText := '';
      while (Length(LText) < FMaxColumn) and (LIndex <= Length(AText)) do
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
    if WrapTextEx(AText, [' ', '-', TControlCharacters.Tab, ','], FMaxColumn, LList) then
      TextOut(AText, LList)
    else
    if WrapTextEx(AText, [';', ')', '.'], FMaxColumn, LList) then
      TextOut(AText, LList)
    else
    begin
      WrapPrimitive;
      TextOut(AText, LList)
    end;

    for LListIndex := LList.Count - 1 downto 0 do
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
  while FCanvas.TextWidth(ALine) > FMaxWidth do
    SetLength(ALine, Length(ALine) - 1);

  Result := ALine;
end;

procedure TTextEditorPrint.TextOut(const AText: string; const AList: TList);
var
  LIndex: Integer;
  LToken: string;
  LTokenPosition: Integer;
  LHighlighterAttribute: TTextEditorHighlighterAttribute;
  LColor: TColor;
  LTokenStart: Integer;
  LCount: Integer;
  LHandled: Boolean;
  LWrapPosition, LOldWrapPosition: Integer;
  LLines: TStringList;
  LClipRect: TRect;

  procedure ClippedTextOut(X, Y: Integer; AText: string);
  begin
    AText := ClipLineToRect(AText);
    if Highlight and Assigned(FHighlighter) and (FLines.Count > 0) then
    begin
      SetBkMode(FCanvas.Handle, TRANSPARENT);
      Winapi.Windows.ExtTextOut(FCanvas.Handle, X, Y, 0, @LClipRect, PChar(AText), Length(AText), nil);
      SetBkMode(FCanvas.Handle, OPAQUE);
    end
    else
      Winapi.Windows.ExtTextOut(FCanvas.Handle, X, Y, 0, nil, PChar(AText), Length(AText), nil);
  end;

  procedure SplitToken;
  var
    LTempText: string;
    LLast: Integer;
    LFirstPosition: Integer;
    LTokenEnd: Integer;
  begin
    LLast := LTokenPosition;
    LFirstPosition := LTokenPosition;
    LTokenEnd := LTokenPosition + Length(LToken);
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
    LTokenStart := LTokenPosition + Length(LToken) - Length(LTempText);
  end;

var
  LTempText: string;
  LLeft: Integer;
begin
  FPaintHelper.BeginDrawing(FCanvas.Handle);
  try
    with FMargins do
      LClipRect := Rect(PixelLeft, PixelTop, PixelRight, PixelBottom);

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

        FCanvas.Font.Color := FFontColor;
        FCanvas.Brush.Color := FDefaultBackground;

        if Assigned(LHighlighterAttribute) then
        begin
          FCanvas.Font.Style := LHighlighterAttribute.FontStyles;
          if FColors then
          begin
            LColor := LHighlighterAttribute.Foreground;
            if LColor = TColors.SysNone then
              LColor := FFont.Color;
            FCanvas.Font.Color := LColor;
            LColor := LHighlighterAttribute.Background;
            if LColor = TColors.SysNone then
              LColor := FDefaultBackground;
            FCanvas.Brush.Color := LColor;
          end
          else
            FCanvas.Font.Color := TColors.Black;
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
            if LTokenPosition + Length(LToken) > TTextEditorWrapPosition(AList[LCount]).Index then
            begin
              LHandled := True;
              SplitToken;
            end;
          end;
        if not LHandled then
        begin
          if not Wrap and (LLeft + TextWidth(FCanvas, LToken) > LClipRect.Right) then
            Break;

          ClippedTextOut(LLeft, FYPos, LToken);
          Inc(LLeft, TextWidth(FCanvas, LToken));
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
        for LIndex := 0 to AList.Count - 1 do
        begin
          LWrapPosition := TTextEditorWrapPosition(AList[LIndex]).Index;
          if LIndex = 0 then
            LTempText := Copy(AText, 1, LWrapPosition)
          else
            LTempText := Copy(AText, LOldWrapPosition + 1, LWrapPosition - LOldWrapPosition);
          LLines.Add(LTempText);
          LOldWrapPosition := LWrapPosition;
        end;

        if Length(AText) > 0 then
          LLines.Add(Copy(AText, LOldWrapPosition + 1, MaxInt));

        for LIndex := 0 to LLines.Count - 1 do
        begin
          ClippedTextOut(FMargins.PixelLeft, FYPos, LLines[LIndex]);
          if LIndex < LLines.Count - 1 then
            FYPos := FYPos + FLineHeight;
        end;
      finally
        LLines.Free;
      end
    end;
  finally
    FPaintHelper.EndDrawing;
  end;
end;

procedure TTextEditorPrint.WriteLine(const AText: string);
begin
  if FLineNumbers then
    WriteLineNumber;

  if Wrap and (FCanvas.TextWidth(AText) > FMaxWidth) then
    HandleWrap(AText)
  else
    TextOut(AText, nil);

  FYPos := FYPos + FLineHeight;
end;

procedure TTextEditorPrint.PrintPage(APageNumber: Integer);
var
  LIndex, LEndLine: Integer;
  LSelectionStart, LSelectionLength: Integer;
begin
  PrintStatus(psNewPage, APageNumber, FAbort);

  if not FAbort then
  begin
    FCanvas.Brush.Color := Color;
    FMargins.InitPage(FCanvas, APageNumber, FPrinterInfo, FLineNumbers, FLineNumbersInMargin, FLines.Count - 1 + FLineOffset);
    FHeader.Print(FCanvas, APageNumber + FPageOffset);
    if FPages.Count > 0 then
    begin
      FYPos := FMargins.PixelTop;
      if APageNumber = FPageCount then
        LEndLine := FLines.Count - 1
      else
        LEndLine := TTextEditorPageLine(FPages[APageNumber]).FirstLine - 1;
      for LIndex := TTextEditorPageLine(FPages[APageNumber - 1]).FirstLine to LEndLine do
      begin
        FLineNumber := LIndex + 1;
        if (not FSelectedOnly or ((LIndex >= FBlockBeginPosition.Line - 1) and (LIndex <= FBlockEndPosition.Line - 1))) then
        begin
          if not FSelectedOnly then
            WriteLine(FLines[LIndex])
          else
          begin
            if (FSelectionMode = smColumn) or (LIndex = FBlockBeginPosition.Line - 1) then
              LSelectionStart := FBlockBeginPosition.Char
            else
              LSelectionStart := 1;
            if (FSelectionMode = smColumn) or (LIndex = FBlockEndPosition.Line - 1) then
              LSelectionLength := FBlockEndPosition.Char - LSelectionStart
            else
              LSelectionLength := MaxInt;
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
  LIndex: Integer;
  LPage, LEndPage: Integer;
begin
  if FSelectedOnly and not FSelectionAvailable then
    Exit;

  LEndPage := AEndPage;
  FPrinting := True;
  FAbort := False;
  if FDocumentTitle <> '' then
    Printer.Title := FDocumentTitle
  else
    Printer.Title := FTitle;
  Printer.BeginDoc;
  if Printer.Printing then
  begin
    PrintStatus(psBegin, AStartPage, FAbort);
    UpdatePages(Printer.Canvas);

    for LIndex := 1 to Copies do
    begin
      LPage := AStartPage;
      if LEndPage < 0 then
        LEndPage := FPageCount;
      while (LPage <= LEndPage) and (not FAbort) do
      begin
        PrintPage(LPage);
        if ((LPage < LEndPage) or (LIndex < Copies)) and not FAbort then
          Printer.NewPage;
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
  LCanvas: TCanvas;
  LHandle: HDC;
begin
  Result := 0;
  if FPagesCounted then
    Result := FPageCount
  else
  begin
    LCanvas := TCanvas.Create;
    LHandle := GetDC(0);
    try
      if LHandle <> 0 then
      begin
        LCanvas.Handle := LHandle;
        UpdatePages(LCanvas);
        LCanvas.Handle := 0;
        Result := FPageCount;
        FPagesCounted := True;
      end;
    finally
      ReleaseDC(0, LHandle);
      LCanvas.Free;
    end;
  end;
end;

procedure TTextEditorPrint.SetEditor(const AValue: TCustomTextEditor);
begin
  FEditor := AValue;
  Highlighter := AValue.Highlighter;
  Font := AValue.Font;
  CharWidth := AValue.CharWidth;
  FColumns := toColumns in AValue.Tabs.Options;
  FTabWidth := AValue.Tabs.Width;
  SetLines(AValue.Lines);
  FSelectionAvailable := AValue.SelectionAvailable;
  FBlockBeginPosition := AValue.SelectionBeginPosition;
  FBlockEndPosition := AValue.SelectionEndPosition;
  FSelectionMode := AValue.Selection.Mode;
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

    Read(FWrap, SizeOf(FWrap));
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
    LLength := Length(FTitle);
    Write(LLength, SizeOf(LLength));
    Write(PChar(FTitle)^, LLength * SizeOf(Char));
    LLength := Length(FDocumentTitle);
    Write(LLength, SizeOf(LLength));
    Write(PChar(FDocumentTitle)^, LLength * SizeOf(Char));
    Write(FWrap, SizeOf(FWrap));
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

end.
