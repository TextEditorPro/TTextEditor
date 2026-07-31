unit FMX.TextEditor.Print.PrinterInfo;

interface

uses
  System.Types;

type
  TTextEditorPrinterInfo = class
  strict private
    FBottomMargin: Integer;
    FDotsPerDipX: Single;
    FDotsPerDipY: Single;
    FIsUpdated: Boolean;
    FLeftMargin: Integer;
    FPhysicalHeight: Integer;
    FPhysicalWidth: Integer;
    FPrintableHeight: Integer;
    FPrintableWidth: Integer;
    FRightMargin: Integer;
    FTopMargin: Integer;
    FXPixPerInch: Integer;
    FXPixPermm: Single;
    FYPixPerInch: Integer;
    FYPixPermm: Single;
    function GetBottomMargin: Integer;
    function GetDotsPerDipX: Single;
    function GetDotsPerDipY: Single;
    function GetLeftMargin: Integer;
    function GetPhysicalHeight: Integer;
    function GetPhysicalWidth: Integer;
    function GetPrintableHeight: Integer;
    function GetPrintableWidth: Integer;
    function GetRightMargin: Integer;
    function GetTopMargin: Integer;
    function GetXPixPerInch: Integer;
    function GetXPixPermm: Single;
    function GetYPixPerInch: Integer;
    function GetYPixPermm: Single;
    procedure FillDefault;
  public
    function PixFromBottom(const AValue: Double): Integer;
    function PixFromLeft(const AValue: Double): Integer;
    function PixFromRight(const AValue: Double): Integer;
    function PixFromTop(const AValue: Double): Integer;
    procedure UpdatePrinter;
    property BottomMargin: Integer read GetBottomMargin;
    property DotsPerDipX: Single read GetDotsPerDipX;
    property DotsPerDipY: Single read GetDotsPerDipY;
    property LeftMargin: Integer read GetLeftMargin;
    property PhysicalHeight: Integer read GetPhysicalHeight;
    property PhysicalWidth: Integer read GetPhysicalWidth;
    property PrintableHeight: Integer read GetPrintableHeight;
    property PrintableWidth: Integer read GetPrintableWidth;
    property RightMargin: Integer read GetRightMargin;
    property TopMargin: Integer read GetTopMargin;
    property XPixPerInch: Integer read GetXPixPerInch;
    property XPixPermm: Single read GetXPixPermm;
    property YPixPerInch: Integer read GetYPixPerInch;
    property YPixPermm: Single read GetYPixPermm;
  end;

implementation

uses
  FMX.Printer;

{ TTextEditorPrinterInfo }

function TTextEditorPrinterInfo.PixFromBottom(const AValue: Double): Integer;
begin
  if not FIsUpdated then
    UpdatePrinter;

  Result := Round(AValue * FYPixPermm - FBottomMargin);
end;

function TTextEditorPrinterInfo.PixFromLeft(const AValue: Double): Integer;
begin
  if not FIsUpdated then
    UpdatePrinter;

  Result := Round(AValue * FXPixPermm - FLeftMargin);
end;

function TTextEditorPrinterInfo.PixFromRight(const AValue: Double): Integer;
begin
  if not FIsUpdated then
    UpdatePrinter;

  Result := Round(AValue * FXPixPermm - FRightMargin);
end;

function TTextEditorPrinterInfo.PixFromTop(const AValue: Double): Integer;
begin
  if not FIsUpdated then
    UpdatePrinter;

  Result := Round(AValue * FYPixPermm - FTopMargin);
end;

procedure TTextEditorPrinterInfo.FillDefault;
begin
  FPhysicalWidth := 794;
  FPhysicalHeight := 1123;
  FPrintableWidth := FPhysicalWidth;
  FPrintableHeight := FPhysicalHeight;
  FLeftMargin := 0;
  FRightMargin := 0;
  FTopMargin := 0;
  FBottomMargin := 0;
  FXPixPerInch := 96;
  FYPixPerInch := 96;
  FXPixPermm := FXPixPerInch / 25.4;
  FYPixPermm := FYPixPerInch / 25.4;
  FDotsPerDipX := 1;
  FDotsPerDipY := 1;
end;

function TTextEditorPrinterInfo.GetBottomMargin: Integer;
begin
  if not FIsUpdated then
    UpdatePrinter;

  Result := FBottomMargin;
end;

function TTextEditorPrinterInfo.GetDotsPerDipX: Single;
begin
  if not FIsUpdated then
    UpdatePrinter;

  Result := FDotsPerDipX;
end;

function TTextEditorPrinterInfo.GetDotsPerDipY: Single;
begin
  if not FIsUpdated then
    UpdatePrinter;

  Result := FDotsPerDipY;
end;

function TTextEditorPrinterInfo.GetLeftMargin: Integer;
begin
  if not FIsUpdated then
    UpdatePrinter;

  Result := FLeftMargin;
end;

function TTextEditorPrinterInfo.GetPhysicalHeight: Integer;
begin
  if not FIsUpdated then
    UpdatePrinter;

  Result := FPhysicalHeight;
end;

function TTextEditorPrinterInfo.GetPhysicalWidth: Integer;
begin
  if not FIsUpdated then
    UpdatePrinter;

  Result := FPhysicalWidth;
end;

function TTextEditorPrinterInfo.GetPrintableHeight: Integer;
begin
  if not FIsUpdated then
    UpdatePrinter;

  Result := FPrintableHeight;
end;

function TTextEditorPrinterInfo.GetPrintableWidth: Integer;
begin
  if not FIsUpdated then
    UpdatePrinter;

  Result := FPrintableWidth;
end;

function TTextEditorPrinterInfo.GetRightMargin: Integer;
begin
  if not FIsUpdated then
    UpdatePrinter;

  Result := FRightMargin;
end;

function TTextEditorPrinterInfo.GetTopMargin: Integer;
begin
  if not FIsUpdated then
    UpdatePrinter;

  Result := FTopMargin;
end;

function TTextEditorPrinterInfo.GetXPixPerInch: Integer;
begin
  if not FIsUpdated then
    UpdatePrinter;

  Result := FXPixPerInch;
end;

function TTextEditorPrinterInfo.GetXPixPermm: Single;
begin
  if not FIsUpdated then
    UpdatePrinter;

  Result := FXPixPermm;
end;

function TTextEditorPrinterInfo.GetYPixPerInch: Integer;
begin
  if not FIsUpdated then
    UpdatePrinter;

  Result := FYPixPerInch;
end;

function TTextEditorPrinterInfo.GetYPixPermm: Single;
begin
  if not FIsUpdated then
    UpdatePrinter;

  Result := FYPixPermm;
end;

procedure TTextEditorPrinterInfo.UpdatePrinter;
var
  LDPI: TPoint;
begin
  FIsUpdated := True;

  try
    if Printer.Count <= 0 then
    begin
      FillDefault;
      Exit;
    end;

    Printer.ActivePrinter.SelectDPI(300, 300);
    LDPI := Printer.ActivePrinter.ActiveDPI;

    if (LDPI.X <= 0) or (LDPI.Y <= 0) then
    begin
      FillDefault;
      Exit;
    end;

    FDotsPerDipX := LDPI.X / 96;
    FDotsPerDipY := LDPI.Y / 96;
    FPhysicalWidth := Round(Printer.PageWidth / FDotsPerDipX);
    FPhysicalHeight := Round(Printer.PageHeight / FDotsPerDipY);
    FPrintableWidth := FPhysicalWidth;
    FPrintableHeight := FPhysicalHeight;
    FLeftMargin := 0;
    FTopMargin := 0;
    FRightMargin := 0;
    FBottomMargin := 0;
    FXPixPerInch := 96;
    FYPixPerInch := 96;
    FXPixPermm := FXPixPerInch / 25.4;
    FYPixPermm := FYPixPerInch / 25.4;
  except
    FillDefault;
  end;
end;

end.
