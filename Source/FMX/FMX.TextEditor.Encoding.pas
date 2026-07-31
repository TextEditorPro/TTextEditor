unit FMX.TextEditor.Encoding;

interface

uses
  System.SysUtils;

type
  TUTF8WithoutBOM = class(TUTF8Encoding)
  public
    function GetPreamble: TBytes; override;
  end;

  TEncoding = class(System.SysUtils.TEncoding)
  strict private
  class var
    FUTF8WithoutBOM: TEncoding;
    class function GetUTF8WithoutBOM: TEncoding; static;
  public
    class property UTF8WithoutBOM: TEncoding read GetUTF8WithoutBOM;
  end;

implementation

const
  CP_UTF8 = 65001;

{ TUTF8WithoutBOM }

function TUTF8WithoutBOM.GetPreamble: TBytes;
begin
  SetLength(Result, 0);
end;

{ TEncoding }

class function TEncoding.GetUTF8WithoutBOM: TEncoding;
var
  LEncoding: System.SysUtils.TEncoding;
begin
  if not Assigned(FUTF8WithoutBOM) then
  begin
    LEncoding := TUTF8WithoutBOM.Create(CP_UTF8, 0, 0);

    if Assigned(AtomicCmpExchange(Pointer(FUTF8WithoutBOM), Pointer(LEncoding), nil)) then
      LEncoding.Free;
  end;

  Result := FUTF8WithoutBOM;
end;

initialization

finalization

  TEncoding.UTF8WithoutBOM.Free;

end.
