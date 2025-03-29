unit TextEditor.KeyboardHandler;

interface

uses
  System.Classes, System.SysUtils, Vcl.Controls, TextEditor.Types;

type
  TTextEditorMethodList = class
  strict private
    FData: TList;
    function GetCount: Integer;
    function GetItem(const AIndex: Integer): TMethod;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AHandler: TMethod);
    procedure Remove(const AHandler: TMethod);
    property Count: Integer read GetCount;
    property Items[const AIndex: Integer]: TMethod read GetItem; default;
  end;

  TTextEditorKeyboardHandler = class(TObject)
  strict private
    FInKeyDown: Boolean;
    FInKeyPress: Boolean;
    FInKeyUp: Boolean;
    FInMouseCursor: Boolean;
    FInMouseDown: Boolean;
    FInMouseUp: Boolean;
    FKeyDownChain: TTextEditorMethodList;
    FKeyPressChain: TTextEditorMethodList;
    FKeyUpChain: TTextEditorMethodList;
    FMouseCursorChain: TTextEditorMethodList;
    FMouseDownChain: TTextEditorMethodList;
    FMouseUpChain: TTextEditorMethodList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddKeyDownHandler(const AHandler: TKeyEvent);
    procedure AddKeyPressHandler(const AHandler: TTextEditorKeyPressWEvent);
    procedure AddKeyUpHandler(const AHandler: TKeyEvent);
    procedure AddMouseCursorHandler(const AHandler: TTextEditorMouseCursorEvent);
    procedure AddMouseDownHandler(const AHandler: TMouseEvent);
    procedure AddMouseUpHandler(const AHandler: TMouseEvent);
    procedure ExecuteKeyDown(ASender: TObject; var Key: Word; Shift: TShiftState);
    procedure ExecuteKeyPress(ASender: TObject; var Key: Char);
    procedure ExecuteKeyUp(ASender: TObject; var Key: Word; Shift: TShiftState);
    procedure ExecuteMouseCursor(ASender: TObject; const ALineCharPos: TTextEditorTextPosition; var ACursor: TCursor);
    procedure ExecuteMouseDown(ASender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ExecuteMouseUp(ASender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure RemoveKeyDownHandler(const AHandler: TKeyEvent);
    procedure RemoveKeyPressHandler(const AHandler: TTextEditorKeyPressWEvent);
    procedure RemoveKeyUpHandler(const AHandler: TKeyEvent);
    procedure RemoveMouseCursorHandler(const AHandler: TTextEditorMouseCursorEvent);
    procedure RemoveMouseDownHandler(const AHandler: TMouseEvent);
    procedure RemoveMouseUpHandler(const AHandler: TMouseEvent);
  end;

implementation

uses
  TextEditor.Consts;

{ TTextEditorMethodList }

constructor TTextEditorMethodList.Create;
begin
  inherited;

  FData := TList.Create;
end;

destructor TTextEditorMethodList.Destroy;
begin
  FData.Free;

  inherited;
end;

function TTextEditorMethodList.GetCount: Integer;
begin
  Result := FData.Count shr 1;
end;

function TTextEditorMethodList.GetItem(const AIndex: Integer): TMethod;
var
  LIndex: Integer;
begin
  LIndex := AIndex * 2;

  Result.Data := FData[LIndex];
  Result.Code := FData[LIndex + 1];
end;

procedure TTextEditorMethodList.Add(const AHandler: TMethod);
begin
  FData.Add(AHandler.Data);
  FData.Add(AHandler.Code);
end;

procedure TTextEditorMethodList.Remove(const AHandler: TMethod);
var
  LIndex: Integer;
begin
  if Assigned(FData) then
  begin
    LIndex := FData.Count - 2;

    while LIndex >= 0 do
    begin
      if (FData.List[LIndex] = AHandler.Data) and (FData.List[LIndex + 1] = AHandler.Code) then
      begin
        FData.Delete(LIndex);
        FData.Delete(LIndex);
        Exit;
      end;

      Dec(LIndex, 2);
    end;
  end;
end;

{ TTextEditorKeyboardHandler }

constructor TTextEditorKeyboardHandler.Create;
begin
  inherited;

  FKeyDownChain := TTextEditorMethodList.Create;
  FKeyUpChain := TTextEditorMethodList.Create;
  FKeyPressChain := TTextEditorMethodList.Create;
  FMouseDownChain := TTextEditorMethodList.Create;
  FMouseUpChain := TTextEditorMethodList.Create;
  FMouseCursorChain := TTextEditorMethodList.Create;
end;

destructor TTextEditorKeyboardHandler.Destroy;
begin
  FKeyPressChain.Free;
  FKeyDownChain.Free;
  FKeyUpChain.Free;
  FMouseDownChain.Free;
  FMouseUpChain.Free;
  FMouseCursorChain.Free;

  inherited Destroy;
end;

procedure TTextEditorKeyboardHandler.AddKeyDownHandler(const AHandler: TKeyEvent);
begin
  FKeyDownChain.Add(TMethod(AHandler));
end;

procedure TTextEditorKeyboardHandler.AddKeyUpHandler(const AHandler: TKeyEvent);
begin
  FKeyUpChain.Add(TMethod(AHandler));
end;

procedure TTextEditorKeyboardHandler.AddKeyPressHandler(const AHandler: TTextEditorKeyPressWEvent);
begin
  FKeyPressChain.Add(TMethod(AHandler));
end;

procedure TTextEditorKeyboardHandler.AddMouseDownHandler(const AHandler: TMouseEvent);
begin
  FMouseDownChain.Add(TMethod(AHandler));
end;

procedure TTextEditorKeyboardHandler.AddMouseUpHandler(const AHandler: TMouseEvent);
begin
  FMouseUpChain.Add(TMethod(AHandler));
end;

procedure TTextEditorKeyboardHandler.AddMouseCursorHandler(const AHandler: TTextEditorMouseCursorEvent);
begin
  FMouseCursorChain.Add(TMethod(AHandler));
end;

procedure TTextEditorKeyboardHandler.ExecuteKeyDown(ASender: TObject; var Key: Word; Shift: TShiftState);
var
  LIndex: Integer;
begin
  if FInKeyDown then
    Exit;

  FInKeyDown := True;
  try
    with FKeyDownChain do
    for LIndex := Count - 1 downto 0 do
    begin
      TKeyEvent(Items[LIndex])(ASender, Key, Shift);

      if Key = 0 then
      begin
        FInKeyDown := False;
        Exit;
      end;
    end;
  finally
    FInKeyDown := False;
  end;
end;

procedure TTextEditorKeyboardHandler.ExecuteKeyUp(ASender: TObject; var Key: Word; Shift: TShiftState);
var
  LIndex: Integer;
begin
  if FInKeyUp then
    Exit;

  FInKeyUp := True;
  try
    with FKeyUpChain do
    for LIndex := Count - 1 downto 0 do
    begin
      TKeyEvent(Items[LIndex])(ASender, Key, Shift);

      if Key = 0 then
      begin
        FInKeyUp := False;
        Exit;
      end;
    end;
  finally
    FInKeyUp := False;
  end;
end;

procedure TTextEditorKeyboardHandler.ExecuteKeyPress(ASender: TObject; var Key: Char);
var
  LIndex: Integer;
begin
  if FInKeyPress then
    Exit;

  FInKeyPress := True;
  try
    with FKeyPressChain do
    for LIndex := Count - 1 downto 0 do
    begin
      TTextEditorKeyPressWEvent(Items[LIndex])(ASender, Key);

      if Key = TControlCharacters.Null then
      begin
        FInKeyPress := False;
        Exit;
      end;
    end;
  finally
    FInKeyPress := False;
  end;
end;

procedure TTextEditorKeyboardHandler.ExecuteMouseDown(ASender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  LIndex: Integer;
begin
  if FInMouseDown then
    Exit;

  FInMouseDown := True;
  try
    for LIndex := FMouseDownChain.Count - 1 downto 0 do
      TMouseEvent(FMouseDownChain[LIndex])(ASender, Button, Shift, X, Y);
  finally
    FInMouseDown := False;
  end;
end;

procedure TTextEditorKeyboardHandler.ExecuteMouseUp(ASender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  LIndex: Integer;
begin
  if FInMouseUp then
    Exit;

  FInMouseUp := True;
  try
    for LIndex := FMouseUpChain.Count - 1 downto 0 do
      TMouseEvent(FMouseUpChain[LIndex])(ASender, Button, Shift, X, Y);
  finally
    FInMouseUp := False;
  end;
end;

procedure TTextEditorKeyboardHandler.ExecuteMouseCursor(ASender: TObject; const ALineCharPos: TTextEditorTextPosition;
  var ACursor: TCursor);
var
  LIndex: Integer;
begin
  if FInMouseCursor then
    Exit;

  FInMouseCursor := True;
  try
    for LIndex := FMouseCursorChain.Count - 1 downto 0 do
      TTextEditorMouseCursorEvent(FMouseCursorChain[LIndex])(ASender, ALineCharPos, ACursor);
  finally
    FInMouseCursor := False;
  end;
end;

procedure TTextEditorKeyboardHandler.RemoveKeyDownHandler(const AHandler: TKeyEvent);
begin
  FKeyDownChain.Remove(TMethod(AHandler));
end;

procedure TTextEditorKeyboardHandler.RemoveKeyUpHandler(const AHandler: TKeyEvent);
begin
  FKeyUpChain.Remove(TMethod(AHandler));
end;

procedure TTextEditorKeyboardHandler.RemoveKeyPressHandler(const AHandler: TTextEditorKeyPressWEvent);
begin
  FKeyPressChain.Remove(TMethod(AHandler));
end;

procedure TTextEditorKeyboardHandler.RemoveMouseDownHandler(const AHandler: TMouseEvent);
begin
  FMouseDownChain.Remove(TMethod(AHandler));
end;

procedure TTextEditorKeyboardHandler.RemoveMouseUpHandler(const AHandler: TMouseEvent);
begin
  FMouseUpChain.Remove(TMethod(AHandler));
end;

procedure TTextEditorKeyboardHandler.RemoveMouseCursorHandler(const AHandler: TTextEditorMouseCursorEvent);
begin
  FMouseCursorChain.Remove(TMethod(AHandler));
end;

end.
