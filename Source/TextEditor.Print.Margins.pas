unit TextEditor.Print.Margins;

interface

uses
  System.Classes, System.SysUtils, Vcl.Graphics, TextEditor.Print.PrinterInfo, TextEditor.Types, TextEditor.Utils;

type
  TTextEditorPrintMargins = class(TPersistent)
  strict private
    FBottom: Double;
    FFooter: Double;
    FHeader: Double;
    FInternalMargin: Double;
    FLeft: Double;
    FLeftTextIndent: Double;
    FMargin: Double;
    FMirrorMargins: Boolean;
    FPixelBottom: Integer;
    FPixelFooter: Integer;
    FPixelHeader: Integer;
    FPixelInternalMargin: Integer;
    FPixelLeft: Integer;
    FPixelLeftTextIndent: Integer;
    FPixelMargin: Integer;
    FPixelRight: Integer;
    FPixelRightTextIndent: Integer;
    FPixelTop: Integer;
    FRight: Double;
    FRightTextIndent: Double;
    FTop: Double;
    FUnitSystem: TTextEditorUnitSystem;
    function ConvertFrom(AValue: Double): Double;
    function ConvertTo(AValue: Double): Double;
    function GetBottom: Double;
    function GetFooter: Double;
    function GetHeader: Double;
    function GetInternalMargin: Double;
    function GetLeft: Double;
    function GetLeftTextIndent: Double;
    function GetMargin: Double;
    function GetRight: Double;
    function GetRightTextIndent: Double;
    function GetTop: Double;
    procedure SetBottom(const AValue: Double);
    procedure SetFooter(const AValue: Double);
    procedure SetHeader(const AValue: Double);
    procedure SetInternalMargin(const AValue: Double);
    procedure SetLeft(const AValue: Double);
    procedure SetLeftTextIndent(const AValue: Double);
    procedure SetMargin(const AValue: Double);
    procedure SetRight(const AValue: Double);
    procedure SetRightTextIndent(const AValue: Double);
    procedure SetTop(const AValue: Double);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure InitPage(const ACanvas: TCanvas; const APageNumber: Integer; const APrinterInfo: TTextEditorPrinterInfo;
      const ALineNumbers, ALineNumbersInMargin: Boolean; const AMaxLineNumber: Integer);
    procedure LoadFromStream(const AStream: TStream);
    procedure SaveToStream(const AStream: TStream);
    property PixelBottom: Integer read FPixelBottom write FPixelBottom;
    property PixelFooter: Integer read FPixelFooter write FPixelFooter;
    property PixelHeader: Integer read FPixelHeader write FPixelHeader;
    property PixelInternalMargin: Integer read FPixelInternalMargin write FPixelInternalMargin;
    property PixelLeft: Integer read FPixelLeft write FPixelLeft;
    property PixelLeftTextIndent: Integer read FPixelLeftTextIndent write FPixelLeftTextIndent;
    property PixelMargin: Integer read FPixelMargin write FPixelMargin;
    property PixelRight: Integer read FPixelRight write FPixelRight;
    property PixelRightTextIndent: Integer read FPixelRightTextIndent write FPixelRightTextIndent;
    property PixelTop: Integer read FPixelTop write FPixelTop;
  published
    property Bottom: Double read GetBottom write SetBottom;
    property Footer: Double read GetFooter write SetFooter;
    property Header: Double read GetHeader write SetHeader;
    property InternalMargin: Double read GetInternalMargin write SetInternalMargin;
    property Left: Double read GetLeft write SetLeft;
    property LeftTextIndent: Double read GetLeftTextIndent write SetLeftTextIndent;
    property Margin: Double read GetMargin write SetMargin;
    property MirrorMargins: Boolean read FMirrorMargins write FMirrorMargins;
    property Right: Double read GetRight write SetRight;
    property RightTextIndent: Double read GetRightTextIndent write SetRightTextIndent;
    property Top: Double read GetTop write SetTop;
    property UnitSystem: TTextEditorUnitSystem read FUnitSystem write FUnitSystem default usMM;
  end;

implementation

const
  mmPerInch = 25.4;
  mmPerCm = 10;

constructor TTextEditorPrintMargins.Create;
begin
  inherited;

  FUnitSystem := usMM;
  FLeft := 20;
  FRight := 15;
  FTop := 18;
  FBottom := 18;
  FHeader := 15;
  FFooter := 15;
  FLeftTextIndent := 2;
  FRightTextIndent := 2;
  FInternalMargin := 0.5;
  FMargin := 0;
  FMirrorMargins := False;
end;

function TTextEditorPrintMargins.ConvertTo(AValue: Double): Double;
begin
  case FUnitSystem of
    usCm:
      Result := AValue * mmPerCm;
    usInch:
      Result := AValue * mmPerInch;
    muThousandthsOfInches:
      Result := mmPerInch * AValue / 1000;
  else
    Result := AValue;
  end;
end;

function TTextEditorPrintMargins.ConvertFrom(AValue: Double): Double;
begin
  case FUnitSystem of
    usCm:
      Result := AValue / mmPerCm;
    usInch:
      Result := AValue / mmPerInch;
    muThousandthsOfInches:
      Result := 1000 * AValue / mmPerInch;
  else
    Result := AValue;
  end;
end;

function TTextEditorPrintMargins.GetBottom: Double;
begin
  Result := ConvertFrom(FBottom);
end;

function TTextEditorPrintMargins.GetFooter: Double;
begin
  Result := ConvertFrom(FFooter);
end;

function TTextEditorPrintMargins.GetMargin: Double;
begin
  Result := ConvertFrom(FMargin);
end;

function TTextEditorPrintMargins.GetHeader: Double;
begin
  Result := ConvertFrom(FHeader);
end;

function TTextEditorPrintMargins.GetLeft: Double;
begin
  Result := ConvertFrom(FLeft);
end;

function TTextEditorPrintMargins.GetRight: Double;
begin
  Result := ConvertFrom(FRight);
end;

function TTextEditorPrintMargins.GetTop: Double;
begin
  Result := ConvertFrom(FTop);
end;

function TTextEditorPrintMargins.GetLeftTextIndent: Double;
begin
  Result := ConvertFrom(FLeftTextIndent);
end;

function TTextEditorPrintMargins.GetRightTextIndent: Double;
begin
  Result := ConvertFrom(FRightTextIndent);
end;

function TTextEditorPrintMargins.GetInternalMargin: Double;
begin
  Result := ConvertFrom(FInternalMargin);
end;

procedure TTextEditorPrintMargins.SetBottom(const AValue: Double);
begin
  FBottom := ConvertTo(AValue);
end;

procedure TTextEditorPrintMargins.SetFooter(const AValue: Double);
begin
  FFooter := ConvertTo(AValue);
end;

procedure TTextEditorPrintMargins.SetMargin(const AValue: Double);
begin
  FMargin := ConvertTo(AValue);
end;

procedure TTextEditorPrintMargins.SetHeader(const AValue: Double);
begin
  FHeader := ConvertTo(AValue);
end;

procedure TTextEditorPrintMargins.SetLeft(const AValue: Double);
begin
  FLeft := ConvertTo(AValue);
end;

procedure TTextEditorPrintMargins.SetRight(const AValue: Double);
begin
  FRight := ConvertTo(AValue);
end;

procedure TTextEditorPrintMargins.SetTop(const AValue: Double);
begin
  FTop := ConvertTo(AValue);
end;

procedure TTextEditorPrintMargins.SetLeftTextIndent(const AValue: Double);
begin
  FLeftTextIndent := ConvertTo(AValue);
end;

procedure TTextEditorPrintMargins.SetRightTextIndent(const AValue: Double);
begin
  FRightTextIndent := ConvertTo(AValue);
end;

procedure TTextEditorPrintMargins.SetInternalMargin(const AValue: Double);
begin
  FInternalMargin := ConvertTo(AValue);
end;

procedure TTextEditorPrintMargins.InitPage(const ACanvas: TCanvas; const APageNumber: Integer; const APrinterInfo: TTextEditorPrinterInfo;
  const ALineNumbers, ALineNumbersInMargin: Boolean; const AMaxLineNumber: Integer);
begin
  if FMirrorMargins and ((APageNumber mod 2) = 0) then
  begin
    PixelLeft := APrinterInfo.PixFromLeft(FRight);
    PixelRight := APrinterInfo.PrintableWidth - APrinterInfo.PixFromRight(FLeft + FMargin);
  end
  else
  begin
    PixelLeft := APrinterInfo.PixFromLeft(FLeft + FMargin);
    PixelRight := APrinterInfo.PrintableWidth - APrinterInfo.PixFromRight(FRight);
  end;
  if ALineNumbers and (not ALineNumbersInMargin) then
    PixelLeft := PixelLeft + TextWidth(ACanvas, IntToStr(AMaxLineNumber) + ': ');
  PixelTop := APrinterInfo.PixFromTop(FTop);
  PixelBottom := APrinterInfo.PrintableHeight - APrinterInfo.PixFromBottom(FBottom);
  PixelHeader := APrinterInfo.PixFromTop(FHeader);
  PixelFooter := APrinterInfo.PrintableHeight - APrinterInfo.PixFromBottom(FFooter);
  PixelInternalMargin := Round(APrinterInfo.YPixPermm * FInternalMargin);
  PixelMargin := Round(APrinterInfo.XPixPermm * FMargin);
  PixelRightTextIndent := PixelRight - Round(APrinterInfo.XPixPermm * FRightTextIndent);
  PixelLeftTextIndent := PixelLeft + Round(APrinterInfo.XPixPermm * FLeftTextIndent);
end;

procedure TTextEditorPrintMargins.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorPrintMargins) then
  with ASource as TTextEditorPrintMargins do
  begin
    Self.FLeft := FLeft;
    Self.FRight := FRight;
    Self.FTop := FTop;
    Self.FBottom := FBottom;
    Self.FHeader := FHeader;
    Self.FFooter := FFooter;
    Self.FLeftTextIndent := FLeftTextIndent;
    Self.FRightTextIndent := FRightTextIndent;
    Self.FInternalMargin := FInternalMargin;
    Self.FMargin := FMargin;
    Self.FMirrorMargins := FMirrorMargins;
    Self.FUnitSystem := FUnitSystem;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorPrintMargins.LoadFromStream(const AStream: TStream);
begin
  with AStream do
  begin
    Read(FUnitSystem, SizeOf(FUnitSystem));
    Read(FLeft, SizeOf(FLeft));
    Read(FRight, SizeOf(FRight));
    Read(FTop, SizeOf(FTop));
    Read(FBottom, SizeOf(FBottom));
    Read(FHeader, SizeOf(FHeader));
    Read(FFooter, SizeOf(FFooter));
    Read(FLeftTextIndent, SizeOf(FLeftTextIndent));
    Read(FRightTextIndent, SizeOf(FRightTextIndent));
    Read(FInternalMargin, SizeOf(FInternalMargin));
    Read(FMargin, SizeOf(FMargin));
    Read(FMirrorMargins, SizeOf(FMirrorMargins));
  end;
end;

procedure TTextEditorPrintMargins.SaveToStream(const AStream: TStream);
begin
  with AStream do
  begin
    Write(FUnitSystem, SizeOf(FUnitSystem));
    Write(FLeft, SizeOf(FLeft));
    Write(FRight, SizeOf(FRight));
    Write(FTop, SizeOf(FTop));
    Write(FBottom, SizeOf(FBottom));
    Write(FHeader, SizeOf(FHeader));
    Write(FFooter, SizeOf(FFooter));
    Write(FLeftTextIndent, SizeOf(FLeftTextIndent));
    Write(FRightTextIndent, SizeOf(FRightTextIndent));
    Write(FInternalMargin, SizeOf(FInternalMargin));
    Write(FMargin, SizeOf(FMargin));
    Write(FMirrorMargins, SizeOf(FMirrorMargins));
  end;
end;

end.
