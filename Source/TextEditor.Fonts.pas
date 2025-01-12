unit TextEditor.Fonts;

{$I TextEditor.Defines.inc}

interface

uses
  System.Classes, Vcl.Graphics;

type
  TTextEditorFonts = class(TPersistent)
  strict private
    FCodeFoldingHint: TFont;
    FCompletionProposal: TFont;
    FLineNumbers: TFont;
    FMinimap: TFont;
    FOnChange: TNotifyEvent;
    FRuler: TFont;
    FText: TFont;
    function IsCodeFoldingHintFontStored: Boolean;
    function IsCompletionProposalFontStored: Boolean;
    function IsLineNumbersFontStored: Boolean;
    function IsMinimapFontStored: Boolean;
    function IsRulerFontStored: Boolean;
    function IsTextFontStored: Boolean;
    procedure DoChange;
    procedure SetCodeFoldingHint(const AValue: TFont);
    procedure SetCompletionProposal(const AValue: TFont);
    procedure SetLineNumbers(const AValue: TFont);
    procedure SetMinimap(const AValue: TFont);
    procedure SetRuler(const AValue: TFont);
    procedure SetText(const AValue: TFont);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    procedure ChangeScale(const AMultiplier: Integer; const ADivider: Integer{$IF CompilerVersion >= 31}; const AIsDpiChange: Boolean{$IFEND});
    procedure SetDefaults;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property CodeFoldingHint: TFont read FCodeFoldingHint write SetCodeFoldingHint stored IsCodeFoldingHintFontStored;
    property CompletionProposal: TFont read FCompletionProposal write SetCompletionProposal stored IsCompletionProposalFontStored;
    property LineNumbers: TFont read FLineNumbers write SetLineNumbers stored IsLineNumbersFontStored;
    property Minimap: TFont read FMinimap write SetMinimap stored IsMinimapFontStored;
    property Ruler: TFont read FRuler write SetRuler stored IsRulerFontStored;
    property Text: TFont read FText write SetText stored IsTextFontStored;
  end;

  TTextEditorFontStyles = class(TPersistent)
  strict private
    FAssemblerComment: TFontStyles;
    FAssemblerReservedWord: TFontStyles;
    FAttribute: TFontStyles;
    FCharacter: TFontStyles;
    FComment: TFontStyles;
    FDirective: TFontStyles;
    FEditor: TFontStyles;
    FHexNumber: TFontStyles;
    FHighlightedBlock: TFontStyles;
    FHighlightedBlockSymbol: TFontStyles;
    FLogicalOperator: TFontStyles;
    FMethod: TFontStyles;
    FMethodItalic: TFontStyles;
    FNameOfMethod: TFontStyles;
    FNumber: TFontStyles;
    FReservedWord: TFontStyles;
    FStringOfCharacters: TFontStyles;
    FSymbol: TFontStyles;
    FValue: TFontStyles;
    FWebLink: TFontStyles;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure Clear;
    procedure SetDefaults;
  published
    property AssemblerComment: TFontStyles read FAssemblerComment write FAssemblerComment default [fsItalic];
    property AssemblerReservedWord: TFontStyles read FAssemblerReservedWord write FAssemblerReservedWord default [fsBold];
    property Attribute: TFontStyles read FAttribute write FAttribute default [];
    property Character: TFontStyles read FCharacter write FCharacter default [];
    property Comment: TFontStyles read FComment write FComment default [fsItalic];
    property Directive: TFontStyles read FDirective write FDirective default [];
    property Editor: TFontStyles read FEditor write FEditor default [];
    property HexNumber: TFontStyles read FHexNumber write FHexNumber default [];
    property HighlightedBlock: TFontStyles read FHighlightedBlock write FHighlightedBlock default [];
    property HighlightedBlockSymbol: TFontStyles read FHighlightedBlockSymbol write FHighlightedBlockSymbol default [];
    property LogicalOperator: TFontStyles read FLogicalOperator write FLogicalOperator default [fsBold];
    property Method: TFontStyles read FMethod write FMethod default [fsBold];
    property MethodItalic: TFontStyles read FMethodItalic write FMethodItalic default [fsItalic];
    property NameOfMethod: TFontStyles read FNameOfMethod write FNameOfMethod default [];
    property Number: TFontStyles read FNumber write FNumber default [];
    property ReservedWord: TFontStyles read FReservedWord write FReservedWord default [fsBold];
    property StringOfCharacters: TFontStyles read FStringOfCharacters write FStringOfCharacters default [];
    property Symbol: TFontStyles read FSymbol write FSymbol default [];
    property Value: TFontStyles read FValue write FValue default [fsBold];
    property WebLink: TFontStyles read FWebLink write FWebLink default [];
  end;

implementation

uses
  Winapi.Windows, System.SysUtils
{$IFDEF ALPHASKINS}
  , sSkinManager
{$ENDIF};

const
  DEFAULT_FONT = 'Courier New';

{ TTextEditorFonts }

constructor TTextEditorFonts.Create;
begin
  inherited Create;

  FCodeFoldingHint := TFont.Create;
  FCompletionProposal := TFont.Create;
  FLineNumbers := TFont.Create;
  FMinimap := TFont.Create;
  FRuler := TFont.Create;
  FText := TFont.Create;

  SetDefaults;
end;

destructor TTextEditorFonts.Destroy;
begin
  FCodeFoldingHint.Free;
  FCompletionProposal.Free;
  FLineNumbers.Free;
  FMinimap.Free;
  FRuler.Free;
  FText.Free;

  inherited Destroy;
end;

function TTextEditorFonts.IsCodeFoldingHintFontStored: Boolean;
begin
  Result := (FCodeFoldingHint.Name <> DEFAULT_FONT) or (FCodeFoldingHint.Size <> 8);
end;

function TTextEditorFonts.IsCompletionProposalFontStored: Boolean;
begin
  Result := (FCompletionProposal.Name <> DEFAULT_FONT) or (FCompletionProposal.Size <> 9);
end;

function TTextEditorFonts.IsLineNumbersFontStored: Boolean;
begin
  Result := (FLineNumbers.Name <> DEFAULT_FONT) or (FLineNumbers.Size <> 8);
end;

function TTextEditorFonts.IsMinimapFontStored: Boolean;
begin
  Result := (FMinimap.Name <> DEFAULT_FONT) or (FMinimap.Size <> 1);
end;

function TTextEditorFonts.IsRulerFontStored: Boolean;
begin
  Result := (FRuler.Name <> DEFAULT_FONT) or (FRuler.Size <> 8);
end;

function TTextEditorFonts.IsTextFontStored: Boolean;
begin
  Result := (FText.Name <> DEFAULT_FONT) or (FText.Size <> 9);
end;

procedure TTextEditorFonts.SetDefaults;

  procedure SetDefault(const AFont: TFont; const ASize: Integer);
  begin
    AFont.Name := DEFAULT_FONT;
    AFont.Size := ASize;
  end;

begin
  SetDefault(FCodeFoldingHint, 8);
  SetDefault(FCompletionProposal, 9);
  SetDefault(FLineNumbers, 8);
  SetDefault(FMinimap, 1);
  SetDefault(FRuler, 8);
  SetDefault(FText, 9);
end;

procedure TTextEditorFonts.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorFonts) then
  with ASource as TTextEditorFonts do
  begin
    Self.FCodeFoldingHint.Assign(FCodeFoldingHint);
    Self.FCompletionProposal.Assign(FCompletionProposal);
    Self.FLineNumbers.Assign(FLineNumbers);
    Self.FMinimap.Assign(FMinimap);
    Self.FRuler.Assign(FRuler);
    Self.FText.Assign(FText);

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorFonts.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorFonts.ChangeScale(const AMultiplier: Integer; const ADivider: Integer{$IF CompilerVersion >= 31}; const AIsDpiChange: Boolean{$IFEND});

  procedure ChangeScale(const AFont: TFont);
  begin
    if AFont.PixelsPerInch <> AMultiplier then
    begin
      AFont.Height := MulDiv(AFont.Height, AMultiplier, ADivider);

{$IF CompilerVersion >= 31}
      if AIsDpiChange then
        AFont.PixelsPerInch := AMultiplier;
{$IFEND}
    end;
  end;

begin
  ChangeScale(FCodeFoldingHint);
  ChangeScale(FCompletionProposal);
  ChangeScale(FLineNumbers);
  ChangeScale(FMinimap);
  ChangeScale(FRuler);
  ChangeScale(FText);
end;

procedure TTextEditorFonts.SetCodeFoldingHint(const AValue: TFont);
begin
  FCodeFoldingHint.Assign(AValue);
end;

procedure TTextEditorFonts.SetCompletionProposal(const AValue: TFont);
begin
  FCompletionProposal.Assign(AValue);
end;

procedure TTextEditorFonts.SetLineNumbers(const AValue: TFont);
begin
  FLineNumbers.Assign(AValue);
end;

procedure TTextEditorFonts.SetMinimap(const AValue: TFont);
begin
  FMinimap.Assign(AValue);
end;

procedure TTextEditorFonts.SetRuler(const AValue: TFont);
begin
  FRuler.Assign(AValue);
end;

procedure TTextEditorFonts.SetText(const AValue: TFont);
begin
  FText.Assign(AValue);
end;

{ TTextEditorFontStyles }

constructor TTextEditorFontStyles.Create;
begin
  inherited Create;

  SetDefaults
end;

procedure TTextEditorFontStyles.SetDefaults;
begin
  Clear;

  FAssemblerComment := [fsItalic];
  FAssemblerReservedWord := [fsBold];
  FComment := [fsItalic];
  FLogicalOperator := [fsBold];
  FMethod := [fsBold];
  FMethodItalic := [fsItalic];
  FReservedWord := [fsBold];
  FValue := [fsBold];
end;

procedure TTextEditorFontStyles.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorFontStyles) then
  with ASource as TTextEditorFontStyles do
  begin
    Self.FAssemblerComment := FAssemblerComment;
    Self.FAssemblerReservedWord := FAssemblerReservedWord;
    Self.FAttribute := FAttribute;
    Self.FCharacter := FCharacter;
    Self.FComment := FComment;
    Self.FDirective := FDirective;
    Self.FEditor := FEditor;
    Self.FHexNumber := FHexNumber;
    Self.FHighlightedBlock := FHighlightedBlock;
    Self.FHighlightedBlockSymbol := FHighlightedBlockSymbol;
    Self.FLogicalOperator := FLogicalOperator;
    Self.FMethod := FMethod;
    Self.FMethodItalic := FMethodItalic;
    Self.FNameOfMethod := FNameOfMethod;
    Self.FNumber := FNumber;
    Self.FReservedWord := FReservedWord;
    Self.FStringOfCharacters := FStringOfCharacters;
    Self.FSymbol := FSymbol;
    Self.FValue := FValue;
    Self.FWebLink := FWebLink;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorFontStyles.Clear;
begin
  FAssemblerComment := [];
  FAssemblerReservedWord := [];
  FAttribute := [];
  FCharacter := [];
  FComment := [];
  FDirective := [];
  FEditor := [];
  FHexNumber := [];
  FHighlightedBlock := [];
  FHighlightedBlockSymbol := [];
  FLogicalOperator := [];
  FMethod := [];
  FMethodItalic := [];
  FNameOfMethod := [];
  FNumber := [];
  FReservedWord := [];
  FStringOfCharacters := [];
  FSymbol := [];
  FValue := [];
  FWebLink := [];
end;

end.
