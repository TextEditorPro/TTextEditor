unit FMX.TextEditor.Fonts;

{$I FMX.TextEditor.Defines.inc}

interface

uses
  System.Classes, System.UITypes, FMX.Graphics;

type
  TTextEditorFonts = class(TPersistent)
  strict private
    FCodeFoldingHint: TFont;
    FCompletionProposal: TFont;
    FHint: TFont;
    FLineNumbers: TFont;
    FMinimap: TFont;
    FOnChange: TNotifyEvent;
    FRuler: TFont;
    FText: TFont;
    function IsCodeFoldingHintFontStored: Boolean;
    function IsCompletionProposalFontStored: Boolean;
    function IsHintFontStored: Boolean;
    function IsLineNumbersFontStored: Boolean;
    function IsMinimapFontStored: Boolean;
    function IsRulerFontStored: Boolean;
    function IsTextFontStored: Boolean;
    procedure DoChange;
    procedure SetCodeFoldingHint(const AValue: TFont);
    procedure SetCompletionProposal(const AValue: TFont);
    procedure SetHint(const AValue: TFont);
    procedure SetLineNumbers(const AValue: TFont);
    procedure SetMinimap(const AValue: TFont);
    procedure SetRuler(const AValue: TFont);
    procedure SetText(const AValue: TFont);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    procedure ChangeScale(const AMultiplier: Integer; const ADivider: Integer; const AIsDpiChange: Boolean);
    procedure SetDefaults;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property CodeFoldingHint: TFont read FCodeFoldingHint write SetCodeFoldingHint stored IsCodeFoldingHintFontStored;
    property CompletionProposal: TFont read FCompletionProposal write SetCompletionProposal stored IsCompletionProposalFontStored;
    property Hint: TFont read FHint write SetHint stored IsHintFontStored;
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
    property AssemblerComment: TFontStyles read FAssemblerComment write FAssemblerComment default [TFontStyle.fsItalic];
    property AssemblerReservedWord: TFontStyles read FAssemblerReservedWord write FAssemblerReservedWord default [TFontStyle.fsBold];
    property Attribute: TFontStyles read FAttribute write FAttribute default [];
    property Character: TFontStyles read FCharacter write FCharacter default [];
    property Comment: TFontStyles read FComment write FComment default [TFontStyle.fsItalic];
    property Directive: TFontStyles read FDirective write FDirective default [];
    property Editor: TFontStyles read FEditor write FEditor default [];
    property HexNumber: TFontStyles read FHexNumber write FHexNumber default [];
    property HighlightedBlock: TFontStyles read FHighlightedBlock write FHighlightedBlock default [];
    property HighlightedBlockSymbol: TFontStyles read FHighlightedBlockSymbol write FHighlightedBlockSymbol default [];
    property LogicalOperator: TFontStyles read FLogicalOperator write FLogicalOperator default [TFontStyle.fsBold];
    property Method: TFontStyles read FMethod write FMethod default [TFontStyle.fsBold];
    property MethodItalic: TFontStyles read FMethodItalic write FMethodItalic default [TFontStyle.fsItalic];
    property NameOfMethod: TFontStyles read FNameOfMethod write FNameOfMethod default [];
    property Number: TFontStyles read FNumber write FNumber default [];
    property ReservedWord: TFontStyles read FReservedWord write FReservedWord default [TFontStyle.fsBold];
    property StringOfCharacters: TFontStyles read FStringOfCharacters write FStringOfCharacters default [];
    property Symbol: TFontStyles read FSymbol write FSymbol default [];
    property Value: TFontStyles read FValue write FValue default [TFontStyle.fsBold];
    property WebLink: TFontStyles read FWebLink write FWebLink default [];
  end;

implementation

uses
  System.SysUtils;

const
  DEFAULT_FONT = 'Courier New';

type
  TDefaultFontSize = record
  const
{$IFDEF TEXT_EDITOR_FMX_FONT_POINTS_TO_DIPS}
    CodeFoldingHint = 8 * 96 / 72;
    CompletionProposal = 9 * 96 / 72;
    Hint = 8 * 96 / 72;
    LineNumbers = 8 * 96 / 72;
    Minimap = 1 * 96 / 72;
    Ruler = 8 * 96 / 72;
    Text = 9 * 96 / 72;
{$ELSE}
    CodeFoldingHint = 8;
    CompletionProposal = 9;
    Hint = 8;
    LineNumbers = 8;
    Minimap = 1;
    Ruler = 8;
    Text = 9;
{$ENDIF}
  end;

{ TTextEditorFonts }

constructor TTextEditorFonts.Create;
begin
  inherited Create;

  FCodeFoldingHint := TFont.Create;
  FCompletionProposal := TFont.Create;
  FHint := TFont.Create;
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
  FHint.Free;
  FLineNumbers.Free;
  FMinimap.Free;
  FRuler.Free;
  FText.Free;

  inherited Destroy;
end;

function TextEditorFontFamily(const AFont: TFont): string;
begin
  Result := AFont.Family;
end;

procedure SetTextEditorFontFamily(const AFont: TFont; const AFamily: string);
begin
  AFont.Family := AFamily;
end;

function TTextEditorFonts.IsCodeFoldingHintFontStored: Boolean;
begin
  Result := (TextEditorFontFamily(FCodeFoldingHint) <> DEFAULT_FONT) or (FCodeFoldingHint.Size <> TDefaultFontSize.CodeFoldingHint);
end;

function TTextEditorFonts.IsCompletionProposalFontStored: Boolean;
begin
  Result := (TextEditorFontFamily(FCompletionProposal) <> DEFAULT_FONT) or (FCompletionProposal.Size <> TDefaultFontSize.CompletionProposal);
end;

function TTextEditorFonts.IsHintFontStored: Boolean;
begin
  Result := (TextEditorFontFamily(FHint) <> DEFAULT_FONT) or (FHint.Size <> TDefaultFontSize.Hint);
end;

function TTextEditorFonts.IsLineNumbersFontStored: Boolean;
begin
  Result := (TextEditorFontFamily(FLineNumbers) <> DEFAULT_FONT) or (FLineNumbers.Size <> TDefaultFontSize.LineNumbers);
end;

function TTextEditorFonts.IsMinimapFontStored: Boolean;
begin
  Result := (TextEditorFontFamily(FMinimap) <> DEFAULT_FONT) or (FMinimap.Size <> TDefaultFontSize.Minimap);
end;

function TTextEditorFonts.IsRulerFontStored: Boolean;
begin
  Result := (TextEditorFontFamily(FRuler) <> DEFAULT_FONT) or (FRuler.Size <> TDefaultFontSize.Ruler);
end;

function TTextEditorFonts.IsTextFontStored: Boolean;
begin
  Result := (TextEditorFontFamily(FText) <> DEFAULT_FONT) or (FText.Size <> TDefaultFontSize.Text);
end;

procedure TTextEditorFonts.SetDefaults;

  procedure SetDefault(const AFont: TFont; const ASize: Single);
  begin
    SetTextEditorFontFamily(AFont, DEFAULT_FONT);
    AFont.Size := ASize;
  end;

begin
  SetDefault(FCodeFoldingHint, TDefaultFontSize.CodeFoldingHint);
  SetDefault(FCompletionProposal, TDefaultFontSize.CompletionProposal);
  SetDefault(FHint, TDefaultFontSize.Hint);
  SetDefault(FLineNumbers, TDefaultFontSize.LineNumbers);
  SetDefault(FMinimap, TDefaultFontSize.Minimap);
  SetDefault(FRuler, TDefaultFontSize.Ruler);
  SetDefault(FText, TDefaultFontSize.Text);
end;

procedure TTextEditorFonts.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorFonts) then
  with ASource as TTextEditorFonts do
  begin
    Self.FCodeFoldingHint.Assign(FCodeFoldingHint);
    Self.FCompletionProposal.Assign(FCompletionProposal);
    Self.FHint.Assign(FHint);
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

procedure TTextEditorFonts.ChangeScale(const AMultiplier: Integer; const ADivider: Integer; const AIsDpiChange: Boolean);

  procedure ChangeScale(const AFont: TFont);
  begin
    AFont.Size := AFont.Size * AMultiplier / ADivider;
  end;

begin
  ChangeScale(FCodeFoldingHint);
  ChangeScale(FCompletionProposal);
  ChangeScale(FHint);
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

procedure TTextEditorFonts.SetHint(const AValue: TFont);
begin
  FHint.Assign(AValue);
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

  SetDefaults;
end;

procedure TTextEditorFontStyles.SetDefaults;
begin
  Clear;

  FAssemblerComment := [TFontStyle.fsItalic];
  FAssemblerReservedWord := [TFontStyle.fsBold];
  FComment := [TFontStyle.fsItalic];
  FLogicalOperator := [TFontStyle.fsBold];
  FMethod := [TFontStyle.fsBold];
  FMethodItalic := [TFontStyle.fsItalic];
  FReservedWord := [TFontStyle.fsBold];
  FValue := [TFontStyle.fsBold];
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
