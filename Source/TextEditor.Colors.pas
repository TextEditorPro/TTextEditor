unit TextEditor.Colors;

interface

uses
  System.Classes, System.UITypes, TextEditor.Consts;

type
  TTextEditorColors = class(TPersistent)
  strict private
    FActiveLineBackground: TColor;
    FActiveLineBackgroundUnfocused: TColor;
    FActiveLineForeground: TColor;
    FActiveLineForegroundUnfocused: TColor;
    FBookmarkLineBackground: TColor;
    FCaretMultiEditBackground: TColor;
    FCaretMultiEditForeground: TColor;
    FCaretNonBlinkingBackground: TColor;
    FCaretNonBlinkingForeground: TColor;
    FCodeFoldingActiveLineBackground: TColor;
    FCodeFoldingActiveLineBackgroundUnfocused: TColor;
    FCodeFoldingBackground: TColor;
    FCodeFoldingCollapsedLine: TColor;
    FCodeFoldingFoldingLine: TColor;
    FCodeFoldingFoldingLineHighlight: TColor;
    FCodeFoldingHintBackground: TColor;
    FCodeFoldingHintBorder: TColor;
    FCodeFoldingHintIndicatorBackground: TColor;
    FCodeFoldingHintIndicatorBorder: TColor;
    FCodeFoldingHintIndicatorMark: TColor;
    FCodeFoldingHintText: TColor;
    FCodeFoldingIndent: TColor;
    FCodeFoldingIndentHighlight: TColor;
    FCompletionProposalBackground: TColor;
    FCompletionProposalForeground: TColor;
    FCompletionProposalSelectedBackground: TColor;
    FCompletionProposalSelectedText: TColor;
    FEditorAssemblerCommentBackground: TColor;
    FEditorAssemblerCommentForeground: TColor;
    FEditorAssemblerReservedWordBackground: TColor;
    FEditorAssemblerReservedWordForeground: TColor;
    FEditorAttributeBackground: TColor;
    FEditorAttributeForeground: TColor;
    FEditorBackground: TColor;
    FEditorCharacterBackground: TColor;
    FEditorCharacterForeground: TColor;
    FEditorCommentBackground: TColor;
    FEditorCommentForeground: TColor;
    FEditorDirectiveBackground: TColor;
    FEditorDirectiveForeground: TColor;
    FEditorForeground: TColor;
    FEditorHexNumberBackground: TColor;
    FEditorHexNumberForeground: TColor;
    FEditorHighlightedBlockBackground: TColor;
    FEditorHighlightedBlockForeground: TColor;
    FEditorHighlightedBlockSymbolBackground: TColor;
    FEditorHighlightedBlockSymbolForeground: TColor;
    FEditorLogicalOperatorBackground: TColor;
    FEditorLogicalOperatorForeground: TColor;
    FEditorMethodBackground: TColor;
    FEditorMethodForeground: TColor;
    FEditorMethodItalicBackground: TColor;
    FEditorMethodItalicForeground: TColor;
    FEditorMethodNameBackground: TColor;
    FEditorMethodNameForeground: TColor;
    FEditorNumberBackground: TColor;
    FEditorNumberForeground: TColor;
    FEditorReservedWordBackground: TColor;
    FEditorReservedWordForeground: TColor;
    FEditorStringBackground: TColor;
    FEditorStringForeground: TColor;
    FEditorSymbolBackground: TColor;
    FEditorSymbolForeground: TColor;
    FEditorValueBackground: TColor;
    FEditorValueForeground: TColor;
    FEditorWebLinkBackground: TColor;
    FEditorWebLinkForeground: TColor;
    FInDesign: Boolean;
    FLeftMarginActiveLineBackground: TColor;
    FLeftMarginActiveLineBackgroundUnfocused: TColor;
    FLeftMarginActiveLineNumber: TColor;
    FLeftMarginBackground: TColor;
    FLeftMarginBookmarkPanelBackground: TColor;
    FLeftMarginBorder: TColor;
    FLeftMarginLineNumberLine: TColor;
    FLeftMarginLineNumbers: TColor;
    FLeftMarginLineStateModified: TColor;
    FLeftMarginLineStateNormal: TColor;
    FMatchingPairMatched: TColor;
    FMatchingPairUnderline: TColor;
    FMatchingPairUnmatched: TColor;
    FMinimapBackground: TColor;
    FMinimapBookmark: TColor;
    FMinimapVisibleRows: TColor;
    FOnChange: TNotifyEvent;
    FRightMargin: TColor;
    FRightMovingEdge: TColor;
    FRulerBackground: TColor;
    FRulerBorder: TColor;
    FRulerLines: TColor;
    FRulerMovingEdge: TColor;
    FRulerNumbers: TColor;
    FRulerSelection: TColor;
    FSearchHighlighterBackground: TColor;
    FSearchHighlighterBorder: TColor;
    FSearchHighlighterForeground: TColor;
    FSearchInSelectionBackground: TColor;
    FSearchMapActiveLine: TColor;
    FSearchMapBackground: TColor;
    FSearchMapForeground: TColor;
    FSelectionBackground: TColor;
    FSelectionBackgroundUnfocused: TColor;
    FSelectionForeground: TColor;
    FSelectionForegroundUnfocused: TColor;
    FSyncEditBackground: TColor;
    FSyncEditEditBorder: TColor;
    FSyncEditWordBorder: TColor;
    FWordWrapIndicatorArrow: TColor;
    FWordWrapIndicatorLines: TColor;
    procedure DoChange;
    procedure SetActiveLineBackground(const AValue: TColor);
    procedure SetActiveLineBackgroundUnfocused(const AValue: TColor);
    procedure SetActiveLineForeground(const AValue: TColor);
    procedure SetActiveLineForegroundUnfocused(const AValue: TColor);
    procedure SetBookmarkLineBackground(const AValue: TColor);
    procedure SetCaretMultiEditBackground(const AValue: TColor);
    procedure SetCaretMultiEditForeground(const AValue: TColor);
    procedure SetCaretNonBlinkingBackground(const AValue: TColor);
    procedure SetCaretNonBlinkingForeground(const AValue: TColor);
    procedure SetCodeFoldingActiveLineBackground(const AValue: TColor);
    procedure SetCodeFoldingActiveLineBackgroundUnfocused(const AValue: TColor);
    procedure SetCodeFoldingBackground(const AValue: TColor);
    procedure SetCodeFoldingCollapsedLine(const AValue: TColor);
    procedure SetCodeFoldingFoldingLine(const AValue: TColor);
    procedure SetCodeFoldingFoldingLineHighlight(const AValue: TColor);
    procedure SetCodeFoldingHintBackground(const AValue: TColor);
    procedure SetCodeFoldingHintBorder(const AValue: TColor);
    procedure SetCodeFoldingHintIndicatorBackground(const AValue: TColor);
    procedure SetCodeFoldingHintIndicatorBorder(const AValue: TColor);
    procedure SetCodeFoldingHintIndicatorMark(const AValue: TColor);
    procedure SetCodeFoldingHintText(const AValue: TColor);
    procedure SetCodeFoldingIndent(const AValue: TColor);
    procedure SetCodeFoldingIndentHighlight(const AValue: TColor);
    procedure SetCompletionProposalBackground(const AValue: TColor);
    procedure SetCompletionProposalForeground(const AValue: TColor);
    procedure SetCompletionProposalSelectedBackground(const AValue: TColor);
    procedure SetCompletionProposalSelectedText(const AValue: TColor);
    procedure SetEditorAssemblerCommentBackground(const AValue: TColor);
    procedure SetEditorAssemblerCommentForeground(const AValue: TColor);
    procedure SetEditorAssemblerReservedWordBackground(const AValue: TColor);
    procedure SetEditorAssemblerReservedWordForeground(const AValue: TColor);
    procedure SetEditorAttributeBackground(const AValue: TColor);
    procedure SetEditorAttributeForeground(const AValue: TColor);
    procedure SetEditorBackground(const AValue: TColor);
    procedure SetEditorCharacterBackground(const AValue: TColor);
    procedure SetEditorCharacterForeground(const AValue: TColor);
    procedure SetEditorCommentBackground(const AValue: TColor);
    procedure SetEditorCommentForeground(const AValue: TColor);
    procedure SetEditorDirectiveBackground(const AValue: TColor);
    procedure SetEditorDirectiveForeground(const AValue: TColor);
    procedure SetEditorForeground(const AValue: TColor);
    procedure SetEditorHexNumberBackground(const AValue: TColor);
    procedure SetEditorHexNumberForeground(const AValue: TColor);
    procedure SetEditorHighlightedBlockBackground(const AValue: TColor);
    procedure SetEditorHighlightedBlockForeground(const AValue: TColor);
    procedure SetEditorHighlightedBlockSymbolBackground(const AValue: TColor);
    procedure SetEditorHighlightedBlockSymbolForeground(const AValue: TColor);
    procedure SetEditorLogicalOperatorBackground(const AValue: TColor);
    procedure SetEditorLogicalOperatorForeground(const AValue: TColor);
    procedure SetEditorMethodBackground(const AValue: TColor);
    procedure SetEditorMethodForeground(const AValue: TColor);
    procedure SetEditorMethodItalicBackground(const AValue: TColor);
    procedure SetEditorMethodItalicForeground(const AValue: TColor);
    procedure SetEditorMethodNameBackground(const AValue: TColor);
    procedure SetEditorMethodNameForeground(const AValue: TColor);
    procedure SetEditorNumberBackground(const AValue: TColor);
    procedure SetEditorNumberForeground(const AValue: TColor);
    procedure SetEditorReservedWordBackground(const AValue: TColor);
    procedure SetEditorReservedWordForeground(const AValue: TColor);
    procedure SetEditorStringBackground(const AValue: TColor);
    procedure SetEditorStringForeground(const AValue: TColor);
    procedure SetEditorSymbolBackground(const AValue: TColor);
    procedure SetEditorSymbolForeground(const AValue: TColor);
    procedure SetEditorValueBackground(const AValue: TColor);
    procedure SetEditorValueForeground(const AValue: TColor);
    procedure SetEditorWebLinkBackground(const AValue: TColor);
    procedure SetEditorWebLinkForeground(const AValue: TColor);
    procedure SetLeftMarginActiveLineBackground(const AValue: TColor);
    procedure SetLeftMarginActiveLineBackgroundUnfocused(const AValue: TColor);
    procedure SetLeftMarginActiveLineNumber(const AValue: TColor);
    procedure SetLeftMarginBackground(const AValue: TColor);
    procedure SetLeftMarginBookmarkPanelBackground(const AValue: TColor);
    procedure SetLeftMarginBorder(const AValue: TColor);
    procedure SetLeftMarginLineNumberLine(const AValue: TColor);
    procedure SetLeftMarginLineNumbers(const AValue: TColor);
    procedure SetLeftMarginLineStateModified(const AValue: TColor);
    procedure SetLeftMarginLineStateNormal(const AValue: TColor);
    procedure SetMatchingPairMatched(const AValue: TColor);
    procedure SetMatchingPairUnderline(const AValue: TColor);
    procedure SetMatchingPairUnmatched(const AValue: TColor);
    procedure SetMinimapBackground(const AValue: TColor);
    procedure SetMinimapBookmark(const AValue: TColor);
    procedure SetMinimapVisibleRows(const AValue: TColor);
    procedure SetRightMargin(const AValue: TColor);
    procedure SetRightMovingEdge(const AValue: TColor);
    procedure SetRulerBackground(const AValue: TColor);
    procedure SetRulerBorder(const AValue: TColor);
    procedure SetRulerLines(const AValue: TColor);
    procedure SetRulerMovingEdge(const AValue: TColor);
    procedure SetRulerNumbers(const AValue: TColor);
    procedure SetRulerSelection(const AValue: TColor);
    procedure SetSearchHighlighterBackground(const AValue: TColor);
    procedure SetSearchHighlighterBorder(const AValue: TColor);
    procedure SetSearchHighlighterForeground(const AValue: TColor);
    procedure SetSearchInSelectionBackground(const AValue: TColor);
    procedure SetSearchMapActiveLine(const AValue: TColor);
    procedure SetSearchMapBackground(const AValue: TColor);
    procedure SetSearchMapForeground(const AValue: TColor);
    procedure SetSelectionBackground(const AValue: TColor);
    procedure SetSelectionBackgroundUnfocused(const AValue: TColor);
    procedure SetSelectionForeground(const AValue: TColor);
    procedure SetSelectionForegroundUnfocused(const AValue: TColor);
    procedure SetSyncEditBackground(const AValue: TColor);
    procedure SetSyncEditEditBorder(const AValue: TColor);
    procedure SetSyncEditWordBorder(const AValue: TColor);
    procedure SetWordWrapIndicatorArrow(const AValue: TColor);
    procedure SetWordWrapIndicatorLines(const AValue: TColor);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure SetDefaults;
    property InDesign: Boolean read FInDesign write FInDesign;
  published
    property ActiveLineBackground: TColor read FActiveLineBackground write SetActiveLineBackground default TDefaultColors.ActiveLineBackground;
    property ActiveLineBackgroundUnfocused: TColor read FActiveLineBackgroundUnfocused write SetActiveLineBackgroundUnfocused default TDefaultColors.ActiveLineBackgroundUnfocused;
    property ActiveLineForeground: TColor read FActiveLineForeground write SetActiveLineForeground default TDefaultColors.ActiveLineForeground;
    property ActiveLineForegroundUnfocused: TColor read FActiveLineForegroundUnfocused write SetActiveLineForegroundUnfocused default TDefaultColors.ActiveLineForegroundUnfocused;
    property BookmarkLineBackground: TColor read FBookmarkLineBackground write SetBookmarkLineBackground default TColors.SysNone;
    property CaretMultiEditBackground: TColor read FCaretMultiEditBackground write SetCaretMultiEditBackground default TColors.Black;
    property CaretMultiEditForeground: TColor read FCaretMultiEditForeground write SetCaretMultiEditForeground default TColors.White;
    property CaretNonBlinkingBackground: TColor read FCaretNonBlinkingBackground write SetCaretNonBlinkingBackground default TColors.Black;
    property CaretNonBlinkingForeground: TColor read FCaretNonBlinkingForeground write SetCaretNonBlinkingForeground default TColors.White;
    property CodeFoldingActiveLineBackground: TColor read FCodeFoldingActiveLineBackground write SetCodeFoldingActiveLineBackground default TDefaultColors.ActiveLineBackground;
    property CodeFoldingActiveLineBackgroundUnfocused: TColor read FCodeFoldingActiveLineBackgroundUnfocused write SetCodeFoldingActiveLineBackgroundUnfocused default TDefaultColors.ActiveLineBackgroundUnfocused;
    property CodeFoldingBackground: TColor read FCodeFoldingBackground write SetCodeFoldingBackground default TDefaultColors.LeftMarginBackground;
    property CodeFoldingCollapsedLine: TColor read FCodeFoldingCollapsedLine write SetCodeFoldingCollapsedLine default TDefaultColors.LineNumbers;
    property CodeFoldingFoldingLine: TColor read FCodeFoldingFoldingLine write SetCodeFoldingFoldingLine default TDefaultColors.LineNumbers;
    property CodeFoldingFoldingLineHighlight: TColor read FCodeFoldingFoldingLineHighlight write SetCodeFoldingFoldingLineHighlight default TDefaultColors.LineNumbers;
    property CodeFoldingHintBackground: TColor read FCodeFoldingHintBackground write SetCodeFoldingHintBackground default TColors.White;
    property CodeFoldingHintBorder: TColor read FCodeFoldingHintBorder write SetCodeFoldingHintBorder default TDefaultColors.LineNumbers;
    property CodeFoldingHintIndicatorBackground: TColor read FCodeFoldingHintIndicatorBackground write SetCodeFoldingHintIndicatorBackground default TDefaultColors.LeftMarginBackground;
    property CodeFoldingHintIndicatorBorder: TColor read FCodeFoldingHintIndicatorBorder write SetCodeFoldingHintIndicatorBorder default TDefaultColors.LineNumbers;
    property CodeFoldingHintIndicatorMark: TColor read FCodeFoldingHintIndicatorMark write SetCodeFoldingHintIndicatorMark default TDefaultColors.LineNumbers;
    property CodeFoldingHintText: TColor read FCodeFoldingHintText write SetCodeFoldingHintText default TColors.Black;
    property CodeFoldingIndent: TColor read FCodeFoldingIndent write SetCodeFoldingIndent default TDefaultColors.LineNumbers;
    property CodeFoldingIndentHighlight: TColor read FCodeFoldingIndentHighlight write SetCodeFoldingIndentHighlight default TDefaultColors.LineNumbers;
    property CompletionProposalBackground: TColor read FCompletionProposalBackground write SetCompletionProposalBackground default TColors.White;
    property CompletionProposalForeground: TColor read FCompletionProposalForeground write SetCompletionProposalForeground default TColors.Black;
    property CompletionProposalSelectedBackground: TColor read FCompletionProposalSelectedBackground write SetCompletionProposalSelectedBackground default TColors.SysHighlight;
    property CompletionProposalSelectedText: TColor read FCompletionProposalSelectedText write SetCompletionProposalSelectedText default TColors.SysHighlightText;
    property EditorAssemblerCommentBackground: TColor read FEditorAssemblerCommentBackground write SetEditorAssemblerCommentBackground default TDefaultColors.BlockBackground;
    property EditorAssemblerCommentForeground: TColor read FEditorAssemblerCommentForeground write SetEditorAssemblerCommentForeground default TColors.Green;
    property EditorAssemblerReservedWordBackground: TColor read FEditorAssemblerReservedWordBackground write SetEditorAssemblerReservedWordBackground default TDefaultColors.BlockBackground;
    property EditorAssemblerReservedWordForeground: TColor read FEditorAssemblerReservedWordForeground write SetEditorAssemblerReservedWordForeground default TColors.Navy;
    property EditorAttributeBackground: TColor read FEditorAttributeBackground write SetEditorAttributeBackground default TColors.White;
    property EditorAttributeForeground: TColor read FEditorAttributeForeground write SetEditorAttributeForeground default TColors.Maroon;
    property EditorBackground: TColor read FEditorBackground write SetEditorBackground default TColors.White;
    property EditorCharacterBackground: TColor read FEditorCharacterBackground write SetEditorCharacterBackground default TColors.White;
    property EditorCharacterForeground: TColor read FEditorCharacterForeground write SetEditorCharacterForeground default TColors.Purple;
    property EditorCommentBackground: TColor read FEditorCommentBackground write SetEditorCommentBackground default TColors.White;
    property EditorCommentForeground: TColor read FEditorCommentForeground write SetEditorCommentForeground default TColors.Green;
    property EditorDirectiveBackground: TColor read FEditorDirectiveBackground write SetEditorDirectiveBackground default TColors.White;
    property EditorDirectiveForeground: TColor read FEditorDirectiveForeground write SetEditorDirectiveForeground default TColors.Teal;
    property EditorForeground: TColor read FEditorForeground write SetEditorForeground default TColors.Black;
    property EditorHexNumberBackground: TColor read FEditorHexNumberBackground write SetEditorHexNumberBackground default TColors.White;
    property EditorHexNumberForeground: TColor read FEditorHexNumberForeground write SetEditorHexNumberForeground default TColors.Blue;
    property EditorHighlightedBlockBackground: TColor read FEditorHighlightedBlockBackground write SetEditorHighlightedBlockBackground default TDefaultColors.BlockBackground;
    property EditorHighlightedBlockForeground: TColor read FEditorHighlightedBlockForeground write SetEditorHighlightedBlockForeground default TColors.Black;
    property EditorHighlightedBlockSymbolBackground: TColor read FEditorHighlightedBlockSymbolBackground write SetEditorHighlightedBlockSymbolBackground default TDefaultColors.BlockBackground;
    property EditorHighlightedBlockSymbolForeground: TColor read FEditorHighlightedBlockSymbolForeground write SetEditorHighlightedBlockSymbolForeground default TColors.Navy;
    property EditorLogicalOperatorBackground: TColor read FEditorLogicalOperatorBackground write SetEditorLogicalOperatorBackground default TColors.White;
    property EditorLogicalOperatorForeground: TColor read FEditorLogicalOperatorForeground write SetEditorLogicalOperatorForeground default TColors.Navy;
    property EditorMethodBackground: TColor read FEditorMethodBackground write SetEditorMethodBackground default TColors.SysNone;
    property EditorMethodForeground: TColor read FEditorMethodForeground write SetEditorMethodForeground default TColors.Navy;
    property EditorMethodItalicBackground: TColor read FEditorMethodItalicBackground write SetEditorMethodItalicBackground default TColors.SysNone;
    property EditorMethodItalicForeground: TColor read FEditorMethodItalicForeground write SetEditorMethodItalicForeground default TColors.Navy;
    property EditorMethodNameBackground: TColor read FEditorMethodNameBackground write SetEditorMethodNameBackground default TColors.SysNone;
    property EditorMethodNameForeground: TColor read FEditorMethodNameForeground write SetEditorMethodNameForeground default TColors.Black;
    property EditorNumberBackground: TColor read FEditorNumberBackground write SetEditorNumberBackground default TColors.White;
    property EditorNumberForeground: TColor read FEditorNumberForeground write SetEditorNumberForeground default TColors.Blue;
    property EditorReservedWordBackground: TColor read FEditorReservedWordBackground write SetEditorReservedWordBackground default TColors.White;
    property EditorReservedWordForeground: TColor read FEditorReservedWordForeground write SetEditorReservedWordForeground default TColors.Navy;
    property EditorStringBackground: TColor read FEditorStringBackground write SetEditorStringBackground default TColors.White;
    property EditorStringForeground: TColor read FEditorStringForeground write SetEditorStringForeground default TColors.Blue;
    property EditorSymbolBackground: TColor read FEditorSymbolBackground write SetEditorSymbolBackground default TColors.White;
    property EditorSymbolForeground: TColor read FEditorSymbolForeground write SetEditorSymbolForeground default TColors.Navy;
    property EditorValueBackground: TColor read FEditorValueBackground write SetEditorValueBackground default TColors.White;
    property EditorValueForeground: TColor read FEditorValueForeground write SetEditorValueForeground default TColors.Navy;
    property EditorWebLinkBackground: TColor read FEditorWebLinkBackground write SetEditorWebLinkBackground default TColors.White;
    property EditorWebLinkForeground: TColor read FEditorWebLinkForeground write SetEditorWebLinkForeground default TColors.Blue;
    property LeftMarginActiveLineBackground: TColor read FLeftMarginActiveLineBackground write SetLeftMarginActiveLineBackground default TDefaultColors.ActiveLineBackground;
    property LeftMarginActiveLineBackgroundUnfocused: TColor read FLeftMarginActiveLineBackgroundUnfocused write SetLeftMarginActiveLineBackgroundUnfocused default TDefaultColors.ActiveLineBackgroundUnfocused;
    property LeftMarginActiveLineNumber: TColor read FLeftMarginActiveLineNumber write SetLeftMarginActiveLineNumber default TDefaultColors.LineNumbers;
    property LeftMarginBackground: TColor read FLeftMarginBackground write SetLeftMarginBackground default TDefaultColors.LeftMarginBackground;
    property LeftMarginBookmarkPanelBackground: TColor read FLeftMarginBookmarkPanelBackground write SetLeftMarginBookmarkPanelBackground default TColors.White;
    property LeftMarginBorder: TColor read FLeftMarginBorder write SetLeftMarginBorder default TDefaultColors.LeftMarginBackground;
    property LeftMarginLineNumberLine: TColor read FLeftMarginLineNumberLine write SetLeftMarginLineNumberLine default TDefaultColors.LineNumbers;
    property LeftMarginLineNumbers: TColor read FLeftMarginLineNumbers write SetLeftMarginLineNumbers default TDefaultColors.LineNumbers;
    property LeftMarginLineStateModified: TColor read FLeftMarginLineStateModified write SetLeftMarginLineStateModified default TColors.Yellow;
    property LeftMarginLineStateNormal: TColor read FLeftMarginLineStateNormal write SetLeftMarginLineStateNormal default TColors.Lime;
    property MatchingPairMatched: TColor read FMatchingPairMatched write SetMatchingPairMatched default TColors.Aqua;
    property MatchingPairUnderline: TColor read FMatchingPairUnderline write SetMatchingPairUnderline default TDefaultColors.MatchingPairUnderline;
    property MatchingPairUnmatched: TColor read FMatchingPairUnmatched write SetMatchingPairUnmatched default TColors.Yellow;
    property MinimapBackground: TColor read FMinimapBackground write SetMinimapBackground default TColors.SysNone;
    property MinimapBookmark: TColor read FMinimapBookmark write SetMinimapBookmark default TDefaultColors.MinimapBookmark;
    property MinimapVisibleRows: TColor read FMinimapVisibleRows write SetMinimapVisibleRows default TDefaultColors.ActiveLineBackground;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property RightMargin: TColor read FRightMargin write SetRightMargin default TColors.Silver;
    property RightMovingEdge: TColor read FRightMovingEdge write SetRightMovingEdge default TColors.Silver;
    property RulerBackground: TColor read FRulerBackground write SetRulerBackground default TDefaultColors.LeftMarginBackground;
    property RulerBorder: TColor read FRulerBorder write SetRulerBorder default TDefaultColors.LineNumbers;
    property RulerLines: TColor read FRulerLines write SetRulerLines default TDefaultColors.LineNumbers;
    property RulerMovingEdge: TColor read FRulerMovingEdge write SetRulerMovingEdge default TColors.Silver;
    property RulerNumbers: TColor read FRulerNumbers write SetRulerNumbers default TDefaultColors.LineNumbers;
    property RulerSelection: TColor read FRulerSelection write SetRulerSelection default TDefaultColors.ActiveLineBackground;
    property SearchHighlighterBackground: TColor read FSearchHighlighterBackground write SetSearchHighlighterBackground default TDefaultColors.SearchHighlighter;
    property SearchHighlighterBorder: TColor read FSearchHighlighterBorder write SetSearchHighlighterBorder default TColors.SysNone;
    property SearchHighlighterForeground: TColor read FSearchHighlighterForeground write SetSearchHighlighterForeground default TColors.Black;
    property SearchInSelectionBackground: TColor read FSearchInSelectionBackground write SetSearchInSelectionBackground default TDefaultColors.SearchInSelectionBackground;
    property SearchMapActiveLine: TColor read FSearchMapActiveLine write SetSearchMapActiveLine default TDefaultColors.ActiveLineBackgroundUnfocused;
    property SearchMapBackground: TColor read FSearchMapBackground write SetSearchMapBackground default TColors.SysNone;
    property SearchMapForeground: TColor read FSearchMapForeground write SetSearchMapForeground default TDefaultColors.SearchHighlighter;
    property SelectionBackground: TColor read FSelectionBackground write SetSelectionBackground default TDefaultColors.Selection;
    property SelectionBackgroundUnfocused: TColor read FSelectionBackgroundUnfocused write SetSelectionBackgroundUnfocused default TDefaultColors.SelectionUnfocused;
    property SelectionForeground: TColor read FSelectionForeground write SetSelectionForeground default TColors.White;
    property SelectionForegroundUnfocused: TColor read FSelectionForegroundUnfocused write SetSelectionForegroundUnfocused default TColors.White;
    property SyncEditBackground: TColor read FSyncEditBackground write SetSyncEditBackground default TDefaultColors.SearchInSelectionBackground;
    property SyncEditEditBorder: TColor read FSyncEditEditBorder write SetSyncEditEditBorder default TColors.Black;
    property SyncEditWordBorder: TColor read FSyncEditWordBorder write SetSyncEditWordBorder default TDefaultColors.Selection;
    property WordWrapIndicatorArrow: TColor read FWordWrapIndicatorArrow write SetWordWrapIndicatorArrow default TDefaultColors.WordWrapIndicatorArrow;
    property WordWrapIndicatorLines: TColor read FWordWrapIndicatorLines write SetWordWrapIndicatorLines default TDefaultColors.WordWrapIndicatorLines;
  end;

implementation

uses
  TextEditor.Utils;

constructor TTextEditorColors.Create;
begin
  inherited Create;

  SetDefaults;
end;

procedure TTextEditorColors.SetDefaults;
begin
  { Active line }
  FActiveLineBackground := TDefaultColors.ActiveLineBackground;
  FActiveLineBackgroundUnfocused := TDefaultColors.ActiveLineBackgroundUnfocused;
  FActiveLineForeground := TDefaultColors.ActiveLineForeground;
  FActiveLineForegroundUnfocused := TDefaultColors.ActiveLineForegroundUnfocused;
  { Bookmarks }
  FBookmarkLineBackground := TColors.SysNone;
  { Caret multiedit }
  FCaretMultiEditBackground := TColors.Black;
  FCaretMultiEditForeground := TColors.White;
  { Caret non-blinking }
  FCaretNonBlinkingBackground := TColors.Black;
  FCaretNonBlinkingForeground := TColors.White;
  { Code folding }
  FCodeFoldingActiveLineBackground := TDefaultColors.ActiveLineBackground;
  FCodeFoldingActiveLineBackgroundUnfocused := TDefaultColors.ActiveLineBackgroundUnfocused;
  FCodeFoldingBackground := TDefaultColors.LeftMarginBackground;
  FCodeFoldingCollapsedLine := TDefaultColors.LineNumbers;
  FCodeFoldingFoldingLine := TDefaultColors.LineNumbers;
  FCodeFoldingFoldingLineHighlight := TDefaultColors.LineNumbers;
  FCodeFoldingIndent := TDefaultColors.LineNumbers;
  FCodeFoldingIndentHighlight := TDefaultColors.LineNumbers;
  { Code folding hint }
  FCodeFoldingHintBackground := TColors.White;
  FCodeFoldingHintBorder := TDefaultColors.LineNumbers;
  FCodeFoldingHintText := TColors.Black;
  { Code folding hint indicator }
  FCodeFoldingHintIndicatorBackground := TDefaultColors.LeftMarginBackground;
  FCodeFoldingHintIndicatorBorder := TDefaultColors.LineNumbers;
  FCodeFoldingHintIndicatorMark := TDefaultColors.LineNumbers;
  { Completion proposal }
  FCompletionProposalBackground := TColors.White;
  FCompletionProposalForeground := TColors.Black;
  FCompletionProposalSelectedBackground := TColors.SysHighlight;
  FCompletionProposalSelectedText := TColors.SysHighlightText;
  { Editor }
  FEditorAssemblerCommentBackground := TDefaultColors.BlockBackground;
  FEditorAssemblerCommentForeground := TColors.Green;
  FEditorAssemblerReservedWordBackground := TDefaultColors.BlockBackground;
  FEditorAssemblerReservedWordForeground := TColors.Navy;
  FEditorAttributeBackground := TColors.White;
  FEditorAttributeForeground := TColors.Maroon;
  FEditorBackground := TColors.White;
  FEditorCharacterBackground := TColors.White;
  FEditorCharacterForeground := TColors.Purple;
  FEditorCommentBackground := TColors.White;
  FEditorCommentForeground := TColors.Green;
  FEditorDirectiveBackground := TColors.White;
  FEditorDirectiveForeground := TColors.Teal;
  FEditorForeground := TColors.Black;
  FEditorHexNumberBackground := TColors.White;
  FEditorHexNumberForeground := TColors.Blue;
  FEditorHighlightedBlockBackground := TDefaultColors.BlockBackground;
  FEditorHighlightedBlockForeground := TColors.Black;
  FEditorHighlightedBlockSymbolBackground := TDefaultColors.BlockBackground;
  FEditorHighlightedBlockSymbolForeground := TColors.Navy;
  FEditorLogicalOperatorBackground := TColors.White;
  FEditorLogicalOperatorForeground := TColors.Navy;
  FEditorMethodBackground := TColors.SysNone;
  FEditorMethodForeground := TColors.Navy;
  FEditorMethodItalicBackground := TColors.SysNone;
  FEditorMethodItalicForeground := TColors.Navy;
  FEditorMethodNameBackground := TColors.SysNone;
  FEditorMethodNameForeground := TColors.Black;
  FEditorNumberBackground := TColors.White;
  FEditorNumberForeground := TColors.Blue;
  FEditorReservedWordBackground := TColors.White;
  FEditorReservedWordForeground := TColors.Navy;
  FEditorStringBackground := TColors.White;
  FEditorStringForeground := TColors.Blue;
  FEditorSymbolBackground := TColors.White;
  FEditorSymbolForeground := TColors.Navy;
  FEditorValueBackground := TColors.White;
  FEditorValueForeground := TColors.Navy;
  FEditorWebLinkBackground := TColors.White;
  FEditorWebLinkForeground := TColors.Blue;
  { Left margin }
  FLeftMarginActiveLineBackground := TDefaultColors.ActiveLineBackground;
  FLeftMarginActiveLineBackgroundUnfocused := TDefaultColors.ActiveLineBackgroundUnfocused;
  FLeftMarginActiveLineNumber := TDefaultColors.LineNumbers;
  FLeftMarginBackground := TDefaultColors.LeftMarginBackground;
  FLeftMarginBookmarkPanelBackground := TColors.White;
  FLeftMarginBorder := TDefaultColors.LeftMarginBackground;
  FLeftMarginLineNumberLine := TDefaultColors.LineNumbers;
  FLeftMarginLineNumbers := TDefaultColors.LineNumbers;
  FLeftMarginLineStateModified := TColors.Yellow;
  FLeftMarginLineStateNormal := TColors.Lime;
  { Matching pair }
  FMatchingPairMatched := TColors.Aqua;
  FMatchingPairUnderline := TDefaultColors.MatchingPairUnderline;
  FMatchingPairUnmatched := TColors.Yellow;
  { Minimap }
  FMinimapBackground := TColors.SysNone;
  FMinimapBookmark := TDefaultColors.MinimapBookmark;
  FMinimapVisibleRows := TDefaultColors.ActiveLineBackground;
  { Right margin }
  FRightMargin := TColors.Silver;
  FRightMovingEdge := TColors.Silver;
  { Ruler }
  FRulerBackground := TDefaultColors.LeftMarginBackground;
  FRulerBorder := TDefaultColors.LineNumbers;
  FRulerLines := TDefaultColors.LineNumbers;
  FRulerMovingEdge := TColors.Silver;
  FRulerNumbers := TDefaultColors.LineNumbers;
  FRulerSelection := TDefaultColors.ActiveLineBackground;
  { Search highlighter }
  FSearchHighlighterBackground := TDefaultColors.SearchHighlighter;
  FSearchHighlighterBorder := TColors.SysNone;
  FSearchHighlighterForeground := TColors.Black;
  { Search in selection }
  FSearchInSelectionBackground := TDefaultColors.SearchInSelectionBackground;
  { Search map }
  FSearchMapActiveLine := TDefaultColors.ActiveLineBackgroundUnfocused;
  FSearchMapBackground := TColors.SysNone;
  FSearchMapForeground := TDefaultColors.SearchHighlighter;
  { Selection }
  FSelectionBackground := TDefaultColors.Selection;
  FSelectionBackgroundUnfocused := TDefaultColors.SelectionUnfocused;
  FSelectionForeground := TColors.White;
  FSelectionForegroundUnfocused := TColors.White;
  { Sync edit }
  FSyncEditBackground := TDefaultColors.SearchInSelectionBackground;
  FSyncEditEditBorder := TColors.Black;
  FSyncEditWordBorder := TDefaultColors.Selection;
  { Word wrap indicator }
  FWordWrapIndicatorArrow := TDefaultColors.WordWrapIndicatorArrow;
  FWordWrapIndicatorLines := TDefaultColors.WordWrapIndicatorLines;
end;

procedure TTextEditorColors.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorColors) then
  with ASource as TTextEditorColors do
  begin
    { Active line }
    Self.FActiveLineBackground := FActiveLineBackground;
    Self.FActiveLineBackgroundUnfocused := FActiveLineBackgroundUnfocused;
    Self.FActiveLineForeground := FActiveLineForeground;
    Self.FActiveLineForegroundUnfocused := FActiveLineForegroundUnfocused;
    { Bookmarks }
    Self.FBookmarkLineBackground := FBookmarkLineBackground;
    { Caret multiedit }
    Self.FCaretMultiEditBackground := FCaretMultiEditBackground;
    Self.FCaretMultiEditForeground := FCaretMultiEditForeground;
    { Caret non-blinking }
    Self.FCaretNonBlinkingBackground := FCaretNonBlinkingBackground;
    Self.FCaretNonBlinkingForeground := FCaretNonBlinkingForeground;
    { Code folding }
    Self.FCodeFoldingActiveLineBackground := FCodeFoldingActiveLineBackground;
    Self.FCodeFoldingActiveLineBackgroundUnfocused := FCodeFoldingActiveLineBackgroundUnfocused;
    Self.FCodeFoldingBackground := FCodeFoldingBackground;
    Self.FCodeFoldingCollapsedLine := FCodeFoldingCollapsedLine;
    Self.FCodeFoldingFoldingLine := FCodeFoldingFoldingLine;
    Self.FCodeFoldingFoldingLineHighlight := FCodeFoldingFoldingLineHighlight;
    Self.FCodeFoldingIndent := FCodeFoldingIndent;
    Self.FCodeFoldingIndentHighlight := FCodeFoldingIndentHighlight;
    { Code folding hint }
    Self.FCodeFoldingHintBackground := FCodeFoldingHintBackground;
    Self.FCodeFoldingHintBorder := FCodeFoldingHintBorder;
    Self.FCodeFoldingHintText := FCodeFoldingHintText;
    { Code folding hint indicator }
    Self.FCodeFoldingHintIndicatorBackground := FCodeFoldingHintIndicatorBackground;
    Self.FCodeFoldingHintIndicatorBorder := FCodeFoldingHintIndicatorBorder;
    Self.FCodeFoldingHintIndicatorMark := FCodeFoldingHintIndicatorMark;
    { Completion proposal }
    Self.FCompletionProposalBackground := FCompletionProposalBackground;
    Self.FCompletionProposalForeground := FCompletionProposalForeground;
    Self.FCompletionProposalSelectedBackground := FCompletionProposalSelectedBackground;
    Self.FCompletionProposalSelectedText := FCompletionProposalSelectedText;
    { Editor }
    Self.FEditorAssemblerCommentBackground := FEditorAssemblerCommentBackground;
    Self.FEditorAssemblerCommentForeground := FEditorAssemblerCommentForeground;
    Self.FEditorAssemblerReservedWordBackground := FEditorAssemblerReservedWordBackground;
    Self.FEditorAssemblerReservedWordForeground := FEditorAssemblerReservedWordForeground;
    Self.FEditorAttributeBackground := FEditorAttributeBackground;
    Self.FEditorAttributeForeground := FEditorAttributeForeground;
    Self.FEditorBackground := FEditorBackground;
    Self.FEditorCharacterBackground := FEditorCharacterBackground;
    Self.FEditorCharacterForeground := FEditorCharacterForeground;
    Self.FEditorCommentBackground := FEditorCommentBackground;
    Self.FEditorCommentForeground := FEditorCommentForeground;
    Self.FEditorDirectiveBackground := FEditorDirectiveBackground;
    Self.FEditorDirectiveForeground := FEditorDirectiveForeground;
    Self.FEditorForeground := FEditorForeground;
    Self.FEditorHexNumberBackground := FEditorHexNumberBackground;
    Self.FEditorHexNumberForeground := FEditorHexNumberForeground;
    Self.FEditorHighlightedBlockBackground := FEditorHighlightedBlockBackground;
    Self.FEditorHighlightedBlockForeground := FEditorHighlightedBlockForeground;
    Self.FEditorHighlightedBlockSymbolBackground := FEditorHighlightedBlockSymbolBackground;
    Self.FEditorHighlightedBlockSymbolForeground := FEditorHighlightedBlockSymbolForeground;
    Self.FEditorLogicalOperatorBackground := FEditorLogicalOperatorBackground;
    Self.FEditorLogicalOperatorForeground := FEditorLogicalOperatorForeground;
    Self.FEditorMethodBackground := FEditorMethodBackground;
    Self.FEditorMethodForeground := FEditorMethodForeground;
    Self.FEditorMethodItalicBackground := FEditorMethodItalicBackground;
    Self.FEditorMethodItalicForeground := FEditorMethodItalicForeground;
    Self.FEditorMethodNameBackground := FEditorMethodNameBackground;
    Self.FEditorMethodNameForeground := FEditorMethodNameForeground;
    Self.FEditorNumberBackground := FEditorNumberBackground;
    Self.FEditorNumberForeground := FEditorNumberForeground;
    Self.FEditorReservedWordBackground := FEditorReservedWordBackground;
    Self.FEditorReservedWordForeground := FEditorReservedWordForeground;
    Self.FEditorStringBackground := FEditorStringBackground;
    Self.FEditorStringForeground := FEditorStringForeground;
    Self.FEditorSymbolBackground := FEditorSymbolBackground;
    Self.FEditorSymbolForeground := FEditorSymbolForeground;
    Self.FEditorValueBackground := FEditorValueBackground;
    Self.FEditorValueForeground := FEditorValueForeground;
    Self.FEditorWebLinkBackground := FEditorWebLinkBackground;
    Self.FEditorWebLinkForeground := FEditorWebLinkForeground;
    { Left margin }
    Self.FLeftMarginActiveLineBackground := FLeftMarginActiveLineBackground;
    Self.FLeftMarginActiveLineBackgroundUnfocused := FLeftMarginActiveLineBackgroundUnfocused;
    Self.FLeftMarginActiveLineNumber := FLeftMarginActiveLineNumber;
    Self.FLeftMarginBackground := FLeftMarginBackground;
    Self.FLeftMarginBookmarkPanelBackground := FLeftMarginBookmarkPanelBackground;
    Self.FLeftMarginBorder := FLeftMarginBorder;
    Self.FLeftMarginLineNumberLine := FLeftMarginLineNumberLine;
    Self.FLeftMarginLineNumbers := FLeftMarginLineNumbers;
    Self.FLeftMarginLineStateModified := FLeftMarginLineStateModified;
    Self.FLeftMarginLineStateNormal := FLeftMarginLineStateNormal;
    { Matching pair }
    Self.FMatchingPairMatched := FMatchingPairMatched;
    Self.FMatchingPairUnderline := FMatchingPairUnderline;
    Self.FMatchingPairUnmatched := FMatchingPairUnmatched;
    { Minimap }
    Self.FMinimapBackground := FMinimapBackground;
    Self.FMinimapBookmark := FMinimapBookmark;
    Self.FMinimapVisibleRows := FMinimapVisibleRows;
    { Right margin }
    Self.FRightMargin := FRightMargin;
    Self.FRightMovingEdge := FRightMovingEdge;
    { Ruler }
    Self.FRulerBackground := FRulerBackground;
    Self.FRulerBorder := FRulerBorder;
    Self.FRulerLines := FRulerLines;
    Self.FRulerMovingEdge := FRulerMovingEdge;
    Self.FRulerSelection := FRulerSelection;
    { Search highlighter }
    Self.FSearchHighlighterBackground := FSearchHighlighterBackground;
    Self.FSearchHighlighterBorder := FSearchHighlighterBorder;
    Self.FSearchHighlighterForeground := FSearchHighlighterForeground;
    { Search in selection }
    Self.FSearchInSelectionBackground := FSearchInSelectionBackground;
    { Search map }
    Self.FSearchMapActiveLine := FSearchMapActiveLine;
    Self.FSearchMapBackground := FSearchMapBackground;
    Self.FSearchMapForeground := FSearchMapForeground;
    { Selection }
    Self.FSelectionBackground := FSelectionBackground;
    Self.FSelectionBackgroundUnfocused := FSelectionBackgroundUnfocused;
    Self.FSelectionForeground := FSelectionForeground;
    Self.FSelectionForegroundUnfocused := FSelectionForegroundUnfocused;
    { Sync edit }
    Self.FSyncEditBackground := FSyncEditBackground;
    Self.FSyncEditEditBorder := FSyncEditEditBorder;
    Self.FSyncEditWordBorder := FSyncEditWordBorder;
    { Word wrap }
    Self.FWordWrapIndicatorArrow := FWordWrapIndicatorArrow;
    Self.FWordWrapIndicatorLines := FWordWrapIndicatorLines;

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TTextEditorColors.DoChange;
begin
  if InDesign and Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTextEditorColors.SetActiveLineBackground(const AValue: TColor);
begin
  FActiveLineBackground := SetColorDef(AValue, TDefaultColors.ActiveLineBackground);
end;

procedure TTextEditorColors.SetActiveLineBackgroundUnfocused(const AValue: TColor);
begin
  FActiveLineBackgroundUnfocused := SetColorDef(AValue, TDefaultColors.ActiveLineBackgroundUnfocused);
  DoChange;
end;

procedure TTextEditorColors.SetActiveLineForeground(const AValue: TColor);
begin
  FActiveLineForeground := SetColorDef(AValue, TDefaultColors.ActiveLineForeground);
end;

procedure TTextEditorColors.SetActiveLineForegroundUnfocused(const AValue: TColor);
begin
  FActiveLineForegroundUnfocused := SetColorDef(AValue, TDefaultColors.ActiveLineForegroundUnfocused);
  DoChange;
end;

procedure TTextEditorColors.SetBookmarkLineBackground(const AValue: TColor);
begin
  FBookmarkLineBackground := SetColorDef(AValue, TColors.SysNone);
end;

procedure TTextEditorColors.SetCaretMultiEditBackground(const AValue: TColor);
begin
  FCaretMultiEditBackground := SetColorDef(AValue, TColors.Black);
end;

procedure TTextEditorColors.SetCaretMultiEditForeground(const AValue: TColor);
begin
  FCaretMultiEditForeground := SetColorDef(AValue, TColors.White);
end;

procedure TTextEditorColors.SetCaretNonBlinkingBackground(const AValue: TColor);
begin
  FCaretNonBlinkingBackground := SetColorDef(AValue, TColors.Black);
end;

procedure TTextEditorColors.SetCaretNonBlinkingForeground(const AValue: TColor);
begin
  FCaretNonBlinkingForeground := SetColorDef(AValue, TColors.White);
end;

procedure TTextEditorColors.SetCodeFoldingActiveLineBackground(const AValue: TColor);
begin
  FCodeFoldingActiveLineBackground := SetColorDef(AValue, TDefaultColors.ActiveLineBackground);
end;

procedure TTextEditorColors.SetCodeFoldingActiveLineBackgroundUnfocused(const AValue: TColor);
begin
  FCodeFoldingActiveLineBackgroundUnfocused := SetColorDef(AValue, TDefaultColors.ActiveLineBackgroundUnfocused);
end;

procedure TTextEditorColors.SetCodeFoldingBackground(const AValue: TColor);
begin
  FCodeFoldingBackground := SetColorDef(AValue, TDefaultColors.LeftMarginBackground);
end;

procedure TTextEditorColors.SetCodeFoldingCollapsedLine(const AValue: TColor);
begin
  FCodeFoldingCollapsedLine := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetCodeFoldingFoldingLine(const AValue: TColor);
begin
  FCodeFoldingFoldingLine := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetCodeFoldingFoldingLineHighlight(const AValue: TColor);
begin
  FCodeFoldingFoldingLineHighlight := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetCodeFoldingHintBackground(const AValue: TColor);
begin
  FCodeFoldingHintBackground := SetColorDef(AValue, TColors.White);
end;

procedure TTextEditorColors.SetCodeFoldingHintBorder(const AValue: TColor);
begin
  FCodeFoldingHintBorder := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetCodeFoldingHintIndicatorBackground(const AValue: TColor);
begin
  FCodeFoldingHintIndicatorBackground := SetColorDef(AValue, TDefaultColors.LeftMarginBackground);
end;

procedure TTextEditorColors.SetCodeFoldingHintIndicatorBorder(const AValue: TColor);
begin
  FCodeFoldingHintIndicatorBorder := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetCodeFoldingHintIndicatorMark(const AValue: TColor);
begin
  FCodeFoldingHintIndicatorMark := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetCodeFoldingHintText(const AValue: TColor);
begin
  FCodeFoldingHintText := SetColorDef(AValue, TColors.Black);
end;

procedure TTextEditorColors.SetCodeFoldingIndent(const AValue: TColor);
begin
  FCodeFoldingIndent := SetColorDef(AValue, TDefaultColors.LineNumbers)
end;

procedure TTextEditorColors.SetCodeFoldingIndentHighlight(const AValue: TColor);
begin
  FCodeFoldingIndentHighlight := SetColorDef(AValue, TDefaultColors.LineNumbers)
end;

procedure TTextEditorColors.SetCompletionProposalBackground(const AValue: TColor);
begin
  FCompletionProposalBackground := SetColorDef(AValue, TColors.White);
end;

procedure TTextEditorColors.SetCompletionProposalForeground(const AValue: TColor);
begin
  FCompletionProposalForeground := SetColorDef(AValue, TColors.Black);
end;

procedure TTextEditorColors.SetCompletionProposalSelectedBackground(const AValue: TColor);
begin
  FCompletionProposalSelectedBackground := SetColorDef(AValue, TColors.SysHighlight);
end;

procedure TTextEditorColors.SetCompletionProposalSelectedText(const AValue: TColor);
begin
  FCompletionProposalSelectedText := SetColorDef(AValue, TColors.SysHighlightText);
end;

procedure TTextEditorColors.SetEditorAssemblerCommentBackground(const AValue: TColor);
begin
  FEditorAssemblerCommentBackground := SetColorDef(AValue, TDefaultColors.BlockBackground);
end;

procedure TTextEditorColors.SetEditorAssemblerCommentForeground(const AValue: TColor);
begin
  FEditorAssemblerCommentForeground := SetColorDef(AValue, TColors.Green);
end;

procedure TTextEditorColors.SetEditorAssemblerReservedWordBackground(const AValue: TColor);
begin
  FEditorAssemblerReservedWordBackground := SetColorDef(AValue, TDefaultColors.BlockBackground);
end;

procedure TTextEditorColors.SetEditorAssemblerReservedWordForeground(const AValue: TColor);
begin
  FEditorAssemblerReservedWordForeground := SetColorDef(AValue, TColors.Navy);
end;

procedure TTextEditorColors.SetEditorAttributeBackground(const AValue: TColor);
begin
  FEditorAttributeBackground := SetColorDef(AValue, TColors.White);
end;

procedure TTextEditorColors.SetEditorAttributeForeground(const AValue: TColor);
begin
  FEditorAttributeForeground := SetColorDef(AValue, TColors.Maroon);
end;

procedure TTextEditorColors.SetEditorBackground(const AValue: TColor);
begin
  FEditorBackground := AValue;
  DoChange;
end;

procedure TTextEditorColors.SetEditorCharacterBackground(const AValue: TColor);
begin
  FEditorCharacterBackground := SetColorDef(AValue, TColors.White);
end;

procedure TTextEditorColors.SetEditorCharacterForeground(const AValue: TColor);
begin
  FEditorCharacterForeground := SetColorDef(AValue, TColors.Purple);
end;

procedure TTextEditorColors.SetEditorCommentBackground(const AValue: TColor);
begin
  FEditorCommentBackground := SetColorDef(AValue, TColors.White);
end;

procedure TTextEditorColors.SetEditorCommentForeground(const AValue: TColor);
begin
  FEditorCommentForeground := SetColorDef(AValue, TColors.Green);
end;

procedure TTextEditorColors.SetEditorDirectiveBackground(const AValue: TColor);
begin
  FEditorDirectiveBackground := SetColorDef(AValue, TColors.White);
end;

procedure TTextEditorColors.SetEditorDirectiveForeground(const AValue: TColor);
begin
  FEditorDirectiveForeground := SetColorDef(AValue, TColors.Teal);
end;

procedure TTextEditorColors.SetEditorForeground(const AValue: TColor);
begin
  FEditorForeground := AValue;
  DoChange;
end;

procedure TTextEditorColors.SetEditorHexNumberBackground(const AValue: TColor);
begin
  FEditorHexNumberBackground := SetColorDef(AValue, TColors.White);
end;

procedure TTextEditorColors.SetEditorHexNumberForeground(const AValue: TColor);
begin
  FEditorHexNumberForeground := SetColorDef(AValue, TColors.Blue);
end;

procedure TTextEditorColors.SetEditorHighlightedBlockBackground(const AValue: TColor);
begin
  FEditorHighlightedBlockBackground := SetColorDef(AValue, TDefaultColors.BlockBackground);
end;

procedure TTextEditorColors.SetEditorHighlightedBlockForeground(const AValue: TColor);
begin
  FEditorHighlightedBlockForeground := SetColorDef(AValue, TColors.Black);
end;

procedure TTextEditorColors.SetEditorHighlightedBlockSymbolBackground(const AValue: TColor);
begin
  FEditorHighlightedBlockSymbolBackground := SetColorDef(AValue, TDefaultColors.BlockBackground);
end;

procedure TTextEditorColors.SetEditorHighlightedBlockSymbolForeground(const AValue: TColor);
begin
  FEditorHighlightedBlockSymbolForeground := SetColorDef(AValue, TColors.Navy);
end;

procedure TTextEditorColors.SetEditorLogicalOperatorBackground(const AValue: TColor);
begin
  FEditorLogicalOperatorBackground := SetColorDef(AValue, TColors.White);
end;

procedure TTextEditorColors.SetEditorLogicalOperatorForeground(const AValue: TColor);
begin
  FEditorLogicalOperatorForeground := SetColorDef(AValue, TColors.Navy);
end;

procedure TTextEditorColors.SetEditorMethodBackground(const AValue: TColor);
begin
  FEditorMethodBackground := SetColorDef(AValue, TColors.SysNone);
end;

procedure TTextEditorColors.SetEditorMethodForeground(const AValue: TColor);
begin
  FEditorMethodForeground := SetColorDef(AValue, TColors.Navy);
end;

procedure TTextEditorColors.SetEditorMethodItalicBackground(const AValue: TColor);
begin
  FEditorMethodItalicBackground := SetColorDef(AValue, TColors.SysNone);
end;

procedure TTextEditorColors.SetEditorMethodItalicForeground(const AValue: TColor);
begin
  FEditorMethodItalicForeground := SetColorDef(AValue, TColors.Navy);
end;

procedure TTextEditorColors.SetEditorMethodNameBackground(const AValue: TColor);
begin
  FEditorMethodNameBackground := SetColorDef(AValue, TColors.SysNone);
end;

procedure TTextEditorColors.SetEditorMethodNameForeground(const AValue: TColor);
begin
  FEditorMethodNameForeground := SetColorDef(AValue, TColors.Black);
end;

procedure TTextEditorColors.SetEditorNumberBackground(const AValue: TColor);
begin
  FEditorNumberBackground := SetColorDef(AValue, TColors.White);
end;

procedure TTextEditorColors.SetEditorNumberForeground(const AValue: TColor);
begin
  FEditorNumberForeground := SetColorDef(AValue, TColors.Blue);
end;

procedure TTextEditorColors.SetEditorReservedWordBackground(const AValue: TColor);
begin
  FEditorReservedWordBackground := SetColorDef(AValue, TColors.White);
end;

procedure TTextEditorColors.SetEditorReservedWordForeground(const AValue: TColor);
begin
  FEditorReservedWordForeground := SetColorDef(AValue, TColors.Navy);
end;

procedure TTextEditorColors.SetEditorStringBackground(const AValue: TColor);
begin
  FEditorStringBackground := SetColorDef(AValue, TColors.White);
end;

procedure TTextEditorColors.SetEditorStringForeground(const AValue: TColor);
begin
  FEditorStringForeground := SetColorDef(AValue, TColors.Blue);
end;

procedure TTextEditorColors.SetEditorSymbolBackground(const AValue: TColor);
begin
  FEditorSymbolBackground := SetColorDef(AValue, TColors.White);
end;

procedure TTextEditorColors.SetEditorSymbolForeground(const AValue: TColor);
begin
  FEditorSymbolForeground := SetColorDef(AValue, TColors.Navy);
end;

procedure TTextEditorColors.SetEditorValueBackground(const AValue: TColor);
begin
  FEditorValueBackground := SetColorDef(AValue, TColors.White);
end;

procedure TTextEditorColors.SetEditorValueForeground(const AValue: TColor);
begin
  FEditorValueForeground := SetColorDef(AValue, TColors.Navy);
end;

procedure TTextEditorColors.SetEditorWebLinkBackground(const AValue: TColor);
begin
  FEditorWebLinkBackground := SetColorDef(AValue, TColors.White);
end;

procedure TTextEditorColors.SetEditorWebLinkForeground(const AValue: TColor);
begin
  FEditorWebLinkForeground := SetColorDef(AValue, TColors.Blue);
end;

procedure TTextEditorColors.SetLeftMarginActiveLineBackground(const AValue: TColor);
begin
  FLeftMarginActiveLineBackground := SetColorDef(AValue, TDefaultColors.ActiveLineBackground);
end;

procedure TTextEditorColors.SetLeftMarginActiveLineBackgroundUnfocused(const AValue: TColor);
begin
  FLeftMarginActiveLineBackgroundUnfocused := SetColorDef(AValue, TDefaultColors.ActiveLineBackgroundUnfocused);
  DoChange;
end;

procedure TTextEditorColors.SetLeftMarginActiveLineNumber(const AValue: TColor);
begin
  FLeftMarginActiveLineNumber := SetColorDef(AValue, TColors.SysNone);
  DoChange;
end;

procedure TTextEditorColors.SetLeftMarginBackground(const AValue: TColor);
begin
  FLeftMarginBackground := SetColorDef(AValue, TDefaultColors.LeftMarginBackground);
  DoChange;
end;

procedure TTextEditorColors.SetLeftMarginBookmarkPanelBackground(const AValue: TColor);
begin
  FLeftMarginBookmarkPanelBackground := SetColorDef(AValue, TColors.SysNone);
  DoChange;
end;

procedure TTextEditorColors.SetLeftMarginBorder(const AValue: TColor);
begin
  FLeftMarginBorder := SetColorDef(AValue, TDefaultColors.LeftMarginBackground);
  DoChange;
end;

procedure TTextEditorColors.SetLeftMarginLineNumberLine(const AValue: TColor);
begin
  FLeftMarginLineNumberLine := SetColorDef(AValue, TDefaultColors.LineNumbers);
  DoChange;
end;

procedure TTextEditorColors.SetLeftMarginLineNumbers(const AValue: TColor);
begin
  FLeftMarginLineNumbers := SetColorDef(AValue, TColors.SysWindowText);
  DoChange;
end;

procedure TTextEditorColors.SetLeftMarginLineStateModified(const AValue: TColor);
begin
  FLeftMarginLineStateModified := SetColorDef(AValue, TColors.Yellow);
end;

procedure TTextEditorColors.SetLeftMarginLineStateNormal(const AValue: TColor);
begin
  FLeftMarginLineStateNormal := SetColorDef(AValue, TColors.Lime);
end;

procedure TTextEditorColors.SetMatchingPairMatched(const AValue: TColor);
begin
  FMatchingPairMatched := SetColorDef(AValue, TColors.Aqua);
end;

procedure TTextEditorColors.SetMatchingPairUnderline(const AValue: TColor);
begin
  FMatchingPairUnderline := SetColorDef(AValue, TDefaultColors.MatchingPairUnderline);
end;

procedure TTextEditorColors.SetMatchingPairUnmatched(const AValue: TColor);
begin
  FMatchingPairUnmatched := SetColorDef(AValue, TColors.Yellow);
end;

procedure TTextEditorColors.SetMinimapBackground(const AValue: TColor);
begin
  FMinimapBackground := SetColorDef(AValue, TColors.SysNone);
end;

procedure TTextEditorColors.SetMinimapBookmark(const AValue: TColor);
begin
  FMinimapBookmark := SetColorDef(AValue, TDefaultColors.MinimapBookmark);
end;

procedure TTextEditorColors.SetMinimapVisibleRows(const AValue: TColor);
begin
  FMinimapVisibleRows := SetColorDef(AValue, TDefaultColors.ActiveLineBackground);
end;

procedure TTextEditorColors.SetRightMargin(const AValue: TColor);
begin
  FRightMargin := SetColorDef(AValue, TColors.Silver);
end;

procedure TTextEditorColors.SetRightMovingEdge(const AValue: TColor);
begin
  FRightMovingEdge := SetColorDef(AValue, TColors.Silver);
end;

procedure TTextEditorColors.SetRulerBackground(const AValue: TColor);
begin
  FRulerBackground := SetColorDef(AValue, TDefaultColors.LeftMarginBackground);
end;

procedure TTextEditorColors.SetRulerBorder(const AValue: TColor);
begin
  FRulerBorder := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetRulerLines(const AValue: TColor);
begin
  FRulerLines := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetRulerMovingEdge(const AValue: TColor);
begin
  FRulerMovingEdge := SetColorDef(AValue, TColors.Silver);
end;

procedure TTextEditorColors.SetRulerNumbers(const AValue: TColor);
begin
  FRulerNumbers := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetRulerSelection(const AValue: TColor);
begin
  FRulerSelection := SetColorDef(AValue, TDefaultColors.ActiveLineBackground);
end;

procedure TTextEditorColors.SetSearchHighlighterBackground(const AValue: TColor);
begin
  FSearchHighlighterBackground := SetColorDef(AValue, TDefaultColors.SearchHighlighter);
end;

procedure TTextEditorColors.SetSearchHighlighterBorder(const AValue: TColor);
begin
  FSearchHighlighterBorder := SetColorDef(AValue, TColors.SysNone);
end;

procedure TTextEditorColors.SetSearchHighlighterForeground(const AValue: TColor);
begin
  FSearchHighlighterForeground := SetColorDef(AValue, TColors.Black);
end;

procedure TTextEditorColors.SetSearchInSelectionBackground(const AValue: TColor);
begin
  FSearchInSelectionBackground := SetColorDef(AValue, TDefaultColors.SearchInSelectionBackground);
end;

procedure TTextEditorColors.SetSearchMapActiveLine(const AValue: TColor);
begin
  FSearchMapActiveLine := SetColorDef(AValue, TDefaultColors.ActiveLineBackgroundUnfocused);
end;

procedure TTextEditorColors.SetSearchMapBackground(const AValue: TColor);
begin
  FSearchMapBackground := SetColorDef(AValue, TColors.SysNone);
end;

procedure TTextEditorColors.SetSearchMapForeground(const AValue: TColor);
begin
  FSearchMapForeground := SetColorDef(AValue, TDefaultColors.SearchHighlighter);
end;

procedure TTextEditorColors.SetSelectionBackground(const AValue: TColor);
begin
  FSelectionBackground := SetColorDef(AValue, TDefaultColors.Selection);
end;

procedure TTextEditorColors.SetSelectionBackgroundUnfocused(const AValue: TColor);
begin
  FSelectionBackgroundUnfocused := SetColorDef(AValue, TDefaultColors.SelectionUnfocused);
end;

procedure TTextEditorColors.SetSelectionForeground(const AValue: TColor);
begin
  FSelectionForeground := SetColorDef(AValue, TColors.White);
end;

procedure TTextEditorColors.SetSelectionForegroundUnfocused(const AValue: TColor);
begin
  FSelectionForegroundUnfocused := SetColorDef(AValue, TColors.White);
end;

procedure TTextEditorColors.SetSyncEditBackground(const AValue: TColor);
begin
  FSyncEditBackground := SetColorDef(AValue, TDefaultColors.SearchInSelectionBackground);
end;

procedure TTextEditorColors.SetSyncEditEditBorder(const AValue: TColor);
begin
  FSyncEditEditBorder := SetColorDef(AValue, TColors.Black);
end;

procedure TTextEditorColors.SetSyncEditWordBorder(const AValue: TColor);
begin
  FSyncEditWordBorder := SetColorDef(AValue, TDefaultColors.Selection);
end;

procedure TTextEditorColors.SetWordWrapIndicatorArrow(const AValue: TColor);
begin
  FWordWrapIndicatorArrow := SetColorDef(AValue, TDefaultColors.WordWrapIndicatorArrow);
end;

procedure TTextEditorColors.SetWordWrapIndicatorLines(const AValue: TColor);
begin
  FWordWrapIndicatorLines := SetColorDef(AValue, TDefaultColors.WordWrapIndicatorLines);
end;

end.
