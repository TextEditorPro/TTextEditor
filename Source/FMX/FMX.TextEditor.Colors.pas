unit FMX.TextEditor.Colors;

interface

uses
  System.Classes, System.UITypes, FMX.TextEditor.Consts;

type
  TTextEditorColors = class(TPersistent)
  strict private
    FActiveLineBackground: TAlphaColor;
    FActiveLineBackgroundUnfocused: TAlphaColor;
    FActiveLineBorder: TAlphaColor;
    FActiveLineForeground: TAlphaColor;
    FActiveLineForegroundUnfocused: TAlphaColor;
    FBookmarkBlue: TAlphaColor;
    FBookmarkGreen: TAlphaColor;
    FBookmarkLineBackground: TAlphaColor;
    FBookmarkPurple: TAlphaColor;
    FBookmarkRed: TAlphaColor;
    FBookmarkYellow: TAlphaColor;
    FCaretMultiEditBackground: TAlphaColor;
    FCaretMultiEditForeground: TAlphaColor;
    FCaretNonBlinkingBackground: TAlphaColor;
    FCaretNonBlinkingForeground: TAlphaColor;
    FCodeFoldingActiveLineBackground: TAlphaColor;
    FCodeFoldingActiveLineBackgroundUnfocused: TAlphaColor;
    FCodeFoldingBackground: TAlphaColor;
    FCodeFoldingCollapsedLine: TAlphaColor;
    FCodeFoldingFoldingLine: TAlphaColor;
    FCodeFoldingFoldingLineHighlight: TAlphaColor;
    FCodeFoldingHintBackground: TAlphaColor;
    FCodeFoldingHintBorder: TAlphaColor;
    FCodeFoldingHintIndicatorBackground: TAlphaColor;
    FCodeFoldingHintIndicatorBorder: TAlphaColor;
    FCodeFoldingHintIndicatorMark: TAlphaColor;
    FCodeFoldingHintText: TAlphaColor;
    FCodeFoldingIndent: TAlphaColor;
    FCodeFoldingIndentHighlight: TAlphaColor;
    FCompareBackground: TAlphaColor;
    FCompareForeground: TAlphaColor;
    FCompletionProposalBackground: TAlphaColor;
    FCompletionProposalBorder: TAlphaColor;
    FCompletionProposalForeground: TAlphaColor;
    FCompletionProposalSelectedBackground: TAlphaColor;
    FCompletionProposalSelectedText: TAlphaColor;
    FEditorAssemblerCommentBackground: TAlphaColor;
    FEditorAssemblerCommentForeground: TAlphaColor;
    FEditorAssemblerReservedWordBackground: TAlphaColor;
    FEditorAssemblerReservedWordForeground: TAlphaColor;
    FEditorAttributeBackground: TAlphaColor;
    FEditorAttributeForeground: TAlphaColor;
    FEditorBackground: TAlphaColor;
    FEditorCharacterBackground: TAlphaColor;
    FEditorCharacterForeground: TAlphaColor;
    FEditorCommentBackground: TAlphaColor;
    FEditorCommentForeground: TAlphaColor;
    FEditorDirectiveBackground: TAlphaColor;
    FEditorDirectiveForeground: TAlphaColor;
    FEditorForeground: TAlphaColor;
    FEditorHexNumberBackground: TAlphaColor;
    FEditorHexNumberForeground: TAlphaColor;
    FEditorHighlightedBlockBackground: TAlphaColor;
    FEditorHighlightedBlockForeground: TAlphaColor;
    FEditorHighlightedBlockSymbolBackground: TAlphaColor;
    FEditorHighlightedBlockSymbolForeground: TAlphaColor;
    FEditorLogicalOperatorBackground: TAlphaColor;
    FEditorLogicalOperatorForeground: TAlphaColor;
    FEditorMethodBackground: TAlphaColor;
    FEditorMethodForeground: TAlphaColor;
    FEditorMethodItalicBackground: TAlphaColor;
    FEditorMethodItalicForeground: TAlphaColor;
    FEditorMethodNameBackground: TAlphaColor;
    FEditorMethodNameForeground: TAlphaColor;
    FEditorNumberBackground: TAlphaColor;
    FEditorNumberForeground: TAlphaColor;
    FEditorReservedWordBackground: TAlphaColor;
    FEditorReservedWordForeground: TAlphaColor;
    FEditorStringBackground: TAlphaColor;
    FEditorStringForeground: TAlphaColor;
    FEditorSymbolBackground: TAlphaColor;
    FEditorSymbolForeground: TAlphaColor;
    FEditorValueBackground: TAlphaColor;
    FEditorValueForeground: TAlphaColor;
    FEditorWebLinkBackground: TAlphaColor;
    FEditorWebLinkForeground: TAlphaColor;
    FHintBackground: TAlphaColor;
    FHintBorder: TAlphaColor;
    FHintText: TAlphaColor;
    FInDesign: Boolean;
    FLeftMarginActiveLineBackground: TAlphaColor;
    FLeftMarginActiveLineBackgroundUnfocused: TAlphaColor;
    FLeftMarginActiveLineNumber: TAlphaColor;
    FLeftMarginBackground: TAlphaColor;
    FLeftMarginBookmarkPanelBackground: TAlphaColor;
    FLeftMarginBorder: TAlphaColor;
    FLeftMarginLineNumberLine: TAlphaColor;
    FLeftMarginLineNumbers: TAlphaColor;
    FLeftMarginLineStateModified: TAlphaColor;
    FLeftMarginLineStateNormal: TAlphaColor;
    FMatchingPairMatched: TAlphaColor;
    FMatchingPairUnderline: TAlphaColor;
    FMatchingPairUnmatched: TAlphaColor;
    FMinimapBackground: TAlphaColor;
    FMinimapBookmark: TAlphaColor;
    FMinimapVisibleRows: TAlphaColor;
    FOnChange: TNotifyEvent;
    FRightMargin: TAlphaColor;
    FRightMovingEdge: TAlphaColor;
    FRulerBackground: TAlphaColor;
    FRulerBorder: TAlphaColor;
    FRulerLines: TAlphaColor;
    FRulerMovingEdge: TAlphaColor;
    FRulerNumbers: TAlphaColor;
    FRulerSelection: TAlphaColor;
    FSearchHighlighterBackground: TAlphaColor;
    FSearchHighlighterBorder: TAlphaColor;
    FSearchHighlighterForeground: TAlphaColor;
    FSearchInSelectionBackground: TAlphaColor;
    FSearchMapActiveLine: TAlphaColor;
    FSearchMapBackground: TAlphaColor;
    FSearchMapForeground: TAlphaColor;
    FSelectionBackground: TAlphaColor;
    FSelectionBackgroundUnfocused: TAlphaColor;
    FSelectionForeground: TAlphaColor;
    FSelectionForegroundUnfocused: TAlphaColor;
    FSyncEditBackground: TAlphaColor;
    FSyncEditEditBorder: TAlphaColor;
    FSyncEditWordBorder: TAlphaColor;
    FWordWrapIndicatorArrow: TAlphaColor;
    FWordWrapIndicatorLines: TAlphaColor;
    function SetColorDef(const AColor: TAlphaColor; const ADefault: TAlphaColor): TAlphaColor; inline;
    procedure DoChange;
    procedure SetActiveLineBackground(const AValue: TAlphaColor);
    procedure SetActiveLineBackgroundUnfocused(const AValue: TAlphaColor);
    procedure SetActiveLineBorder(const AValue: TAlphaColor);
    procedure SetActiveLineForeground(const AValue: TAlphaColor);
    procedure SetActiveLineForegroundUnfocused(const AValue: TAlphaColor);
    procedure SetBookmarkBlue(const AValue: TAlphaColor);
    procedure SetBookmarkGreen(const AValue: TAlphaColor);
    procedure SetBookmarkLineBackground(const AValue: TAlphaColor);
    procedure SetBookmarkPurple(const AValue: TAlphaColor);
    procedure SetBookmarkRed(const AValue: TAlphaColor);
    procedure SetBookmarkYellow(const AValue: TAlphaColor);
    procedure SetCaretMultiEditBackground(const AValue: TAlphaColor);
    procedure SetCaretMultiEditForeground(const AValue: TAlphaColor);
    procedure SetCaretNonBlinkingBackground(const AValue: TAlphaColor);
    procedure SetCaretNonBlinkingForeground(const AValue: TAlphaColor);
    procedure SetCodeFoldingActiveLineBackground(const AValue: TAlphaColor);
    procedure SetCodeFoldingActiveLineBackgroundUnfocused(const AValue: TAlphaColor);
    procedure SetCodeFoldingBackground(const AValue: TAlphaColor);
    procedure SetCodeFoldingCollapsedLine(const AValue: TAlphaColor);
    procedure SetCodeFoldingFoldingLine(const AValue: TAlphaColor);
    procedure SetCodeFoldingFoldingLineHighlight(const AValue: TAlphaColor);
    procedure SetCodeFoldingHintBackground(const AValue: TAlphaColor);
    procedure SetCodeFoldingHintBorder(const AValue: TAlphaColor);
    procedure SetCodeFoldingHintIndicatorBackground(const AValue: TAlphaColor);
    procedure SetCodeFoldingHintIndicatorBorder(const AValue: TAlphaColor);
    procedure SetCodeFoldingHintIndicatorMark(const AValue: TAlphaColor);
    procedure SetCodeFoldingHintText(const AValue: TAlphaColor);
    procedure SetCodeFoldingIndent(const AValue: TAlphaColor);
    procedure SetCodeFoldingIndentHighlight(const AValue: TAlphaColor);
    procedure SetCompareBackground(const AValue: TAlphaColor);
    procedure SetCompareForeground(const AValue: TAlphaColor);
    procedure SetCompletionProposalBackground(const AValue: TAlphaColor);
    procedure SetCompletionProposalBorder(const AValue: TAlphaColor);
    procedure SetCompletionProposalForeground(const AValue: TAlphaColor);
    procedure SetCompletionProposalSelectedBackground(const AValue: TAlphaColor);
    procedure SetCompletionProposalSelectedText(const AValue: TAlphaColor);
    procedure SetEditorAssemblerCommentBackground(const AValue: TAlphaColor);
    procedure SetEditorAssemblerCommentForeground(const AValue: TAlphaColor);
    procedure SetEditorAssemblerReservedWordBackground(const AValue: TAlphaColor);
    procedure SetEditorAssemblerReservedWordForeground(const AValue: TAlphaColor);
    procedure SetEditorAttributeBackground(const AValue: TAlphaColor);
    procedure SetEditorAttributeForeground(const AValue: TAlphaColor);
    procedure SetEditorBackground(const AValue: TAlphaColor);
    procedure SetEditorCharacterBackground(const AValue: TAlphaColor);
    procedure SetEditorCharacterForeground(const AValue: TAlphaColor);
    procedure SetEditorCommentBackground(const AValue: TAlphaColor);
    procedure SetEditorCommentForeground(const AValue: TAlphaColor);
    procedure SetEditorDirectiveBackground(const AValue: TAlphaColor);
    procedure SetEditorDirectiveForeground(const AValue: TAlphaColor);
    procedure SetEditorForeground(const AValue: TAlphaColor);
    procedure SetEditorHexNumberBackground(const AValue: TAlphaColor);
    procedure SetEditorHexNumberForeground(const AValue: TAlphaColor);
    procedure SetEditorHighlightedBlockBackground(const AValue: TAlphaColor);
    procedure SetEditorHighlightedBlockForeground(const AValue: TAlphaColor);
    procedure SetEditorHighlightedBlockSymbolBackground(const AValue: TAlphaColor);
    procedure SetEditorHighlightedBlockSymbolForeground(const AValue: TAlphaColor);
    procedure SetEditorLogicalOperatorBackground(const AValue: TAlphaColor);
    procedure SetEditorLogicalOperatorForeground(const AValue: TAlphaColor);
    procedure SetEditorMethodBackground(const AValue: TAlphaColor);
    procedure SetEditorMethodForeground(const AValue: TAlphaColor);
    procedure SetEditorMethodItalicBackground(const AValue: TAlphaColor);
    procedure SetEditorMethodItalicForeground(const AValue: TAlphaColor);
    procedure SetEditorMethodNameBackground(const AValue: TAlphaColor);
    procedure SetEditorMethodNameForeground(const AValue: TAlphaColor);
    procedure SetEditorNumberBackground(const AValue: TAlphaColor);
    procedure SetEditorNumberForeground(const AValue: TAlphaColor);
    procedure SetEditorReservedWordBackground(const AValue: TAlphaColor);
    procedure SetEditorReservedWordForeground(const AValue: TAlphaColor);
    procedure SetEditorStringBackground(const AValue: TAlphaColor);
    procedure SetEditorStringForeground(const AValue: TAlphaColor);
    procedure SetEditorSymbolBackground(const AValue: TAlphaColor);
    procedure SetEditorSymbolForeground(const AValue: TAlphaColor);
    procedure SetEditorValueBackground(const AValue: TAlphaColor);
    procedure SetEditorValueForeground(const AValue: TAlphaColor);
    procedure SetEditorWebLinkBackground(const AValue: TAlphaColor);
    procedure SetEditorWebLinkForeground(const AValue: TAlphaColor);
    procedure SetHintBackground(const AValue: TAlphaColor);
    procedure SetHintBorder(const AValue: TAlphaColor);
    procedure SetHintText(const AValue: TAlphaColor);
    procedure SetLeftMarginActiveLineBackground(const AValue: TAlphaColor);
    procedure SetLeftMarginActiveLineBackgroundUnfocused(const AValue: TAlphaColor);
    procedure SetLeftMarginActiveLineNumber(const AValue: TAlphaColor);
    procedure SetLeftMarginBackground(const AValue: TAlphaColor);
    procedure SetLeftMarginBookmarkPanelBackground(const AValue: TAlphaColor);
    procedure SetLeftMarginBorder(const AValue: TAlphaColor);
    procedure SetLeftMarginLineNumberLine(const AValue: TAlphaColor);
    procedure SetLeftMarginLineNumbers(const AValue: TAlphaColor);
    procedure SetLeftMarginLineStateModified(const AValue: TAlphaColor);
    procedure SetLeftMarginLineStateNormal(const AValue: TAlphaColor);
    procedure SetMatchingPairMatched(const AValue: TAlphaColor);
    procedure SetMatchingPairUnderline(const AValue: TAlphaColor);
    procedure SetMatchingPairUnmatched(const AValue: TAlphaColor);
    procedure SetMinimapBackground(const AValue: TAlphaColor);
    procedure SetMinimapBookmark(const AValue: TAlphaColor);
    procedure SetMinimapVisibleRows(const AValue: TAlphaColor);
    procedure SetRightMargin(const AValue: TAlphaColor);
    procedure SetRightMovingEdge(const AValue: TAlphaColor);
    procedure SetRulerBackground(const AValue: TAlphaColor);
    procedure SetRulerBorder(const AValue: TAlphaColor);
    procedure SetRulerLines(const AValue: TAlphaColor);
    procedure SetRulerMovingEdge(const AValue: TAlphaColor);
    procedure SetRulerNumbers(const AValue: TAlphaColor);
    procedure SetRulerSelection(const AValue: TAlphaColor);
    procedure SetSearchHighlighterBackground(const AValue: TAlphaColor);
    procedure SetSearchHighlighterBorder(const AValue: TAlphaColor);
    procedure SetSearchHighlighterForeground(const AValue: TAlphaColor);
    procedure SetSearchInSelectionBackground(const AValue: TAlphaColor);
    procedure SetSearchMapActiveLine(const AValue: TAlphaColor);
    procedure SetSearchMapBackground(const AValue: TAlphaColor);
    procedure SetSearchMapForeground(const AValue: TAlphaColor);
    procedure SetSelectionBackground(const AValue: TAlphaColor);
    procedure SetSelectionBackgroundUnfocused(const AValue: TAlphaColor);
    procedure SetSelectionForeground(const AValue: TAlphaColor);
    procedure SetSelectionForegroundUnfocused(const AValue: TAlphaColor);
    procedure SetSyncEditBackground(const AValue: TAlphaColor);
    procedure SetSyncEditEditBorder(const AValue: TAlphaColor);
    procedure SetSyncEditWordBorder(const AValue: TAlphaColor);
    procedure SetWordWrapIndicatorArrow(const AValue: TAlphaColor);
    procedure SetWordWrapIndicatorLines(const AValue: TAlphaColor);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure SetDefaults;
    property InDesign: Boolean read FInDesign write FInDesign;
  published
    property ActiveLineBackground: TAlphaColor read FActiveLineBackground write SetActiveLineBackground default TDefaultColors.ActiveLineBackground;
    property ActiveLineBackgroundUnfocused: TAlphaColor read FActiveLineBackgroundUnfocused write SetActiveLineBackgroundUnfocused default TDefaultColors.ActiveLineBackgroundUnfocused;
    property ActiveLineBorder: TAlphaColor read FActiveLineBorder write SetActiveLineBorder default TDefaultColors.ActiveLineBorder;
    property ActiveLineForeground: TAlphaColor read FActiveLineForeground write SetActiveLineForeground default TDefaultColors.ActiveLineForeground;
    property ActiveLineForegroundUnfocused: TAlphaColor read FActiveLineForegroundUnfocused write SetActiveLineForegroundUnfocused default TDefaultColors.ActiveLineForegroundUnfocused;
    property BookmarkBlue: TAlphaColor read FBookmarkBlue write SetBookmarkBlue default TDefaultColors.BookmarkBlue;
    property BookmarkGreen: TAlphaColor read FBookmarkGreen write SetBookmarkGreen default TDefaultColors.BookmarkGreen;
    property BookmarkLineBackground: TAlphaColor read FBookmarkLineBackground write SetBookmarkLineBackground default TAlphaColors.Null;
    property BookmarkPurple: TAlphaColor read FBookmarkPurple write SetBookmarkPurple default TDefaultColors.BookmarkPurple;
    property BookmarkRed: TAlphaColor read FBookmarkRed write SetBookmarkRed default TDefaultColors.BookmarkRed;
    property BookmarkYellow: TAlphaColor read FBookmarkYellow write SetBookmarkYellow default TDefaultColors.BookmarkYellow;
    property CaretMultiEditBackground: TAlphaColor read FCaretMultiEditBackground write SetCaretMultiEditBackground default TAlphaColors.Black;
    property CaretMultiEditForeground: TAlphaColor read FCaretMultiEditForeground write SetCaretMultiEditForeground default TAlphaColors.White;
    property CaretNonBlinkingBackground: TAlphaColor read FCaretNonBlinkingBackground write SetCaretNonBlinkingBackground default TAlphaColors.Black;
    property CaretNonBlinkingForeground: TAlphaColor read FCaretNonBlinkingForeground write SetCaretNonBlinkingForeground default TAlphaColors.White;
    property CodeFoldingActiveLineBackground: TAlphaColor read FCodeFoldingActiveLineBackground write SetCodeFoldingActiveLineBackground default TDefaultColors.ActiveLineBackground;
    property CodeFoldingActiveLineBackgroundUnfocused: TAlphaColor read FCodeFoldingActiveLineBackgroundUnfocused write SetCodeFoldingActiveLineBackgroundUnfocused default TDefaultColors.ActiveLineBackgroundUnfocused;
    property CodeFoldingBackground: TAlphaColor read FCodeFoldingBackground write SetCodeFoldingBackground default TDefaultColors.LeftMarginBackground;
    property CodeFoldingCollapsedLine: TAlphaColor read FCodeFoldingCollapsedLine write SetCodeFoldingCollapsedLine default TDefaultColors.LineNumbers;
    property CodeFoldingFoldingLine: TAlphaColor read FCodeFoldingFoldingLine write SetCodeFoldingFoldingLine default TDefaultColors.LineNumbers;
    property CodeFoldingFoldingLineHighlight: TAlphaColor read FCodeFoldingFoldingLineHighlight write SetCodeFoldingFoldingLineHighlight default TDefaultColors.LineNumbers;
    property CodeFoldingHintBackground: TAlphaColor read FCodeFoldingHintBackground write SetCodeFoldingHintBackground default TAlphaColors.White;
    property CodeFoldingHintBorder: TAlphaColor read FCodeFoldingHintBorder write SetCodeFoldingHintBorder default TDefaultColors.LineNumbers;
    property CodeFoldingHintIndicatorBackground: TAlphaColor read FCodeFoldingHintIndicatorBackground write SetCodeFoldingHintIndicatorBackground default TDefaultColors.LeftMarginBackground;
    property CodeFoldingHintIndicatorBorder: TAlphaColor read FCodeFoldingHintIndicatorBorder write SetCodeFoldingHintIndicatorBorder default TDefaultColors.LineNumbers;
    property CodeFoldingHintIndicatorMark: TAlphaColor read FCodeFoldingHintIndicatorMark write SetCodeFoldingHintIndicatorMark default TDefaultColors.LineNumbers;
    property CodeFoldingHintText: TAlphaColor read FCodeFoldingHintText write SetCodeFoldingHintText default TAlphaColors.Black;
    property CodeFoldingIndent: TAlphaColor read FCodeFoldingIndent write SetCodeFoldingIndent default TDefaultColors.LineNumbers;
    property CodeFoldingIndentHighlight: TAlphaColor read FCodeFoldingIndentHighlight write SetCodeFoldingIndentHighlight default TDefaultColors.LineNumbers;
    property CompareBackground: TAlphaColor read FCompareBackground write SetCompareBackground default TDefaultColors.PaleRed;
    property CompareForeground: TAlphaColor read FCompareForeground write SetCompareForeground default TDefaultColors.Red;
    property CompletionProposalBackground: TAlphaColor read FCompletionProposalBackground write SetCompletionProposalBackground default TAlphaColors.White;
    property CompletionProposalBorder: TAlphaColor read FCompletionProposalBorder write SetCompletionProposalBorder default TDefaultColors.LineNumbers;
    property CompletionProposalForeground: TAlphaColor read FCompletionProposalForeground write SetCompletionProposalForeground default TAlphaColors.Black;
    property CompletionProposalSelectedBackground: TAlphaColor read FCompletionProposalSelectedBackground write SetCompletionProposalSelectedBackground default TDefaultColors.SysHighlight;
    property CompletionProposalSelectedText: TAlphaColor read FCompletionProposalSelectedText write SetCompletionProposalSelectedText default TDefaultColors.SysHighlightText;
    property EditorAssemblerCommentBackground: TAlphaColor read FEditorAssemblerCommentBackground write SetEditorAssemblerCommentBackground default TDefaultColors.BlockBackground;
    property EditorAssemblerCommentForeground: TAlphaColor read FEditorAssemblerCommentForeground write SetEditorAssemblerCommentForeground default TAlphaColors.Green;
    property EditorAssemblerReservedWordBackground: TAlphaColor read FEditorAssemblerReservedWordBackground write SetEditorAssemblerReservedWordBackground default TDefaultColors.BlockBackground;
    property EditorAssemblerReservedWordForeground: TAlphaColor read FEditorAssemblerReservedWordForeground write SetEditorAssemblerReservedWordForeground default TAlphaColors.Navy;
    property EditorAttributeBackground: TAlphaColor read FEditorAttributeBackground write SetEditorAttributeBackground default TAlphaColors.White;
    property EditorAttributeForeground: TAlphaColor read FEditorAttributeForeground write SetEditorAttributeForeground default TAlphaColors.Maroon;
    property EditorBackground: TAlphaColor read FEditorBackground write SetEditorBackground default TAlphaColors.White;
    property EditorCharacterBackground: TAlphaColor read FEditorCharacterBackground write SetEditorCharacterBackground default TAlphaColors.White;
    property EditorCharacterForeground: TAlphaColor read FEditorCharacterForeground write SetEditorCharacterForeground default TAlphaColors.Purple;
    property EditorCommentBackground: TAlphaColor read FEditorCommentBackground write SetEditorCommentBackground default TAlphaColors.White;
    property EditorCommentForeground: TAlphaColor read FEditorCommentForeground write SetEditorCommentForeground default TAlphaColors.Green;
    property EditorDirectiveBackground: TAlphaColor read FEditorDirectiveBackground write SetEditorDirectiveBackground default TAlphaColors.White;
    property EditorDirectiveForeground: TAlphaColor read FEditorDirectiveForeground write SetEditorDirectiveForeground default TAlphaColors.Teal;
    property EditorForeground: TAlphaColor read FEditorForeground write SetEditorForeground default TAlphaColors.Black;
    property EditorHexNumberBackground: TAlphaColor read FEditorHexNumberBackground write SetEditorHexNumberBackground default TAlphaColors.White;
    property EditorHexNumberForeground: TAlphaColor read FEditorHexNumberForeground write SetEditorHexNumberForeground default TAlphaColors.Blue;
    property EditorHighlightedBlockBackground: TAlphaColor read FEditorHighlightedBlockBackground write SetEditorHighlightedBlockBackground default TDefaultColors.BlockBackground;
    property EditorHighlightedBlockForeground: TAlphaColor read FEditorHighlightedBlockForeground write SetEditorHighlightedBlockForeground default TAlphaColors.Black;
    property EditorHighlightedBlockSymbolBackground: TAlphaColor read FEditorHighlightedBlockSymbolBackground write SetEditorHighlightedBlockSymbolBackground default TDefaultColors.BlockBackground;
    property EditorHighlightedBlockSymbolForeground: TAlphaColor read FEditorHighlightedBlockSymbolForeground write SetEditorHighlightedBlockSymbolForeground default TAlphaColors.Navy;
    property EditorLogicalOperatorBackground: TAlphaColor read FEditorLogicalOperatorBackground write SetEditorLogicalOperatorBackground default TAlphaColors.White;
    property EditorLogicalOperatorForeground: TAlphaColor read FEditorLogicalOperatorForeground write SetEditorLogicalOperatorForeground default TAlphaColors.Navy;
    property EditorMethodBackground: TAlphaColor read FEditorMethodBackground write SetEditorMethodBackground default TAlphaColors.Null;
    property EditorMethodForeground: TAlphaColor read FEditorMethodForeground write SetEditorMethodForeground default TAlphaColors.Navy;
    property EditorMethodItalicBackground: TAlphaColor read FEditorMethodItalicBackground write SetEditorMethodItalicBackground default TAlphaColors.Null;
    property EditorMethodItalicForeground: TAlphaColor read FEditorMethodItalicForeground write SetEditorMethodItalicForeground default TAlphaColors.Navy;
    property EditorMethodNameBackground: TAlphaColor read FEditorMethodNameBackground write SetEditorMethodNameBackground default TAlphaColors.Null;
    property EditorMethodNameForeground: TAlphaColor read FEditorMethodNameForeground write SetEditorMethodNameForeground default TAlphaColors.Black;
    property EditorNumberBackground: TAlphaColor read FEditorNumberBackground write SetEditorNumberBackground default TAlphaColors.White;
    property EditorNumberForeground: TAlphaColor read FEditorNumberForeground write SetEditorNumberForeground default TAlphaColors.Blue;
    property EditorReservedWordBackground: TAlphaColor read FEditorReservedWordBackground write SetEditorReservedWordBackground default TAlphaColors.White;
    property EditorReservedWordForeground: TAlphaColor read FEditorReservedWordForeground write SetEditorReservedWordForeground default TAlphaColors.Navy;
    property EditorStringBackground: TAlphaColor read FEditorStringBackground write SetEditorStringBackground default TAlphaColors.White;
    property EditorStringForeground: TAlphaColor read FEditorStringForeground write SetEditorStringForeground default TAlphaColors.Blue;
    property EditorSymbolBackground: TAlphaColor read FEditorSymbolBackground write SetEditorSymbolBackground default TAlphaColors.White;
    property EditorSymbolForeground: TAlphaColor read FEditorSymbolForeground write SetEditorSymbolForeground default TAlphaColors.Navy;
    property EditorValueBackground: TAlphaColor read FEditorValueBackground write SetEditorValueBackground default TAlphaColors.White;
    property EditorValueForeground: TAlphaColor read FEditorValueForeground write SetEditorValueForeground default TAlphaColors.Navy;
    property EditorWebLinkBackground: TAlphaColor read FEditorWebLinkBackground write SetEditorWebLinkBackground default TAlphaColors.White;
    property EditorWebLinkForeground: TAlphaColor read FEditorWebLinkForeground write SetEditorWebLinkForeground default TAlphaColors.Blue;
    property HintBackground: TAlphaColor read FHintBackground write SetHintBackground default TDefaultColors.HintBackground;
    property HintBorder: TAlphaColor read FHintBorder write SetHintBorder default TDefaultColors.LineNumbers;
    property HintText: TAlphaColor read FHintText write SetHintText default TDefaultColors.HintText;
    property LeftMarginActiveLineBackground: TAlphaColor read FLeftMarginActiveLineBackground write SetLeftMarginActiveLineBackground default TDefaultColors.ActiveLineBackground;
    property LeftMarginActiveLineBackgroundUnfocused: TAlphaColor read FLeftMarginActiveLineBackgroundUnfocused write SetLeftMarginActiveLineBackgroundUnfocused default TDefaultColors.ActiveLineBackgroundUnfocused;
    property LeftMarginActiveLineNumber: TAlphaColor read FLeftMarginActiveLineNumber write SetLeftMarginActiveLineNumber default TDefaultColors.LineNumbers;
    property LeftMarginBackground: TAlphaColor read FLeftMarginBackground write SetLeftMarginBackground default TDefaultColors.LeftMarginBackground;
    property LeftMarginBookmarkPanelBackground: TAlphaColor read FLeftMarginBookmarkPanelBackground write SetLeftMarginBookmarkPanelBackground default TAlphaColors.White;
    property LeftMarginBorder: TAlphaColor read FLeftMarginBorder write SetLeftMarginBorder default TDefaultColors.LeftMarginBackground;
    property LeftMarginLineNumberLine: TAlphaColor read FLeftMarginLineNumberLine write SetLeftMarginLineNumberLine default TDefaultColors.LineNumbers;
    property LeftMarginLineNumbers: TAlphaColor read FLeftMarginLineNumbers write SetLeftMarginLineNumbers default TDefaultColors.LineNumbers;
    property LeftMarginLineStateModified: TAlphaColor read FLeftMarginLineStateModified write SetLeftMarginLineStateModified default TAlphaColors.Yellow;
    property LeftMarginLineStateNormal: TAlphaColor read FLeftMarginLineStateNormal write SetLeftMarginLineStateNormal default TAlphaColors.Lime;
    property MatchingPairMatched: TAlphaColor read FMatchingPairMatched write SetMatchingPairMatched default TAlphaColors.Aqua;
    property MatchingPairUnderline: TAlphaColor read FMatchingPairUnderline write SetMatchingPairUnderline default TDefaultColors.MatchingPairUnderline;
    property MatchingPairUnmatched: TAlphaColor read FMatchingPairUnmatched write SetMatchingPairUnmatched default TAlphaColors.Yellow;
    property MinimapBackground: TAlphaColor read FMinimapBackground write SetMinimapBackground default TAlphaColors.Null;
    property MinimapBookmark: TAlphaColor read FMinimapBookmark write SetMinimapBookmark default TDefaultColors.MinimapBookmark;
    property MinimapVisibleRows: TAlphaColor read FMinimapVisibleRows write SetMinimapVisibleRows default TDefaultColors.ActiveLineBackground;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property RightMargin: TAlphaColor read FRightMargin write SetRightMargin default TAlphaColors.Silver;
    property RightMovingEdge: TAlphaColor read FRightMovingEdge write SetRightMovingEdge default TAlphaColors.Silver;
    property RulerBackground: TAlphaColor read FRulerBackground write SetRulerBackground default TDefaultColors.LeftMarginBackground;
    property RulerBorder: TAlphaColor read FRulerBorder write SetRulerBorder default TDefaultColors.LineNumbers;
    property RulerLines: TAlphaColor read FRulerLines write SetRulerLines default TDefaultColors.LineNumbers;
    property RulerMovingEdge: TAlphaColor read FRulerMovingEdge write SetRulerMovingEdge default TAlphaColors.Silver;
    property RulerNumbers: TAlphaColor read FRulerNumbers write SetRulerNumbers default TDefaultColors.LineNumbers;
    property RulerSelection: TAlphaColor read FRulerSelection write SetRulerSelection default TDefaultColors.ActiveLineBackground;
    property SearchHighlighterBackground: TAlphaColor read FSearchHighlighterBackground write SetSearchHighlighterBackground default TDefaultColors.SearchHighlighter;
    property SearchHighlighterBorder: TAlphaColor read FSearchHighlighterBorder write SetSearchHighlighterBorder default TAlphaColors.Null;
    property SearchHighlighterForeground: TAlphaColor read FSearchHighlighterForeground write SetSearchHighlighterForeground default TAlphaColors.Black;
    property SearchInSelectionBackground: TAlphaColor read FSearchInSelectionBackground write SetSearchInSelectionBackground default TDefaultColors.SearchInSelectionBackground;
    property SearchMapActiveLine: TAlphaColor read FSearchMapActiveLine write SetSearchMapActiveLine default TDefaultColors.ActiveLineBackgroundUnfocused;
    property SearchMapBackground: TAlphaColor read FSearchMapBackground write SetSearchMapBackground default TAlphaColors.Null;
    property SearchMapForeground: TAlphaColor read FSearchMapForeground write SetSearchMapForeground default TDefaultColors.SearchHighlighter;
    property SelectionBackground: TAlphaColor read FSelectionBackground write SetSelectionBackground default TDefaultColors.Selection;
    property SelectionBackgroundUnfocused: TAlphaColor read FSelectionBackgroundUnfocused write SetSelectionBackgroundUnfocused default TDefaultColors.SelectionUnfocused;
    property SelectionForeground: TAlphaColor read FSelectionForeground write SetSelectionForeground default TAlphaColors.White;
    property SelectionForegroundUnfocused: TAlphaColor read FSelectionForegroundUnfocused write SetSelectionForegroundUnfocused default TAlphaColors.White;
    property SyncEditBackground: TAlphaColor read FSyncEditBackground write SetSyncEditBackground default TDefaultColors.SearchInSelectionBackground;
    property SyncEditEditBorder: TAlphaColor read FSyncEditEditBorder write SetSyncEditEditBorder default TAlphaColors.Black;
    property SyncEditWordBorder: TAlphaColor read FSyncEditWordBorder write SetSyncEditWordBorder default TDefaultColors.Selection;
    property WordWrapIndicatorArrow: TAlphaColor read FWordWrapIndicatorArrow write SetWordWrapIndicatorArrow default TDefaultColors.WordWrapIndicatorArrow;
    property WordWrapIndicatorLines: TAlphaColor read FWordWrapIndicatorLines write SetWordWrapIndicatorLines default TDefaultColors.WordWrapIndicatorLines;
  end;

implementation

uses
  FMX.TextEditor.Utils;

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
  FActiveLineBorder := TDefaultColors.ActiveLineBorder;
  FActiveLineForeground := TDefaultColors.ActiveLineForeground;
  FActiveLineForegroundUnfocused := TDefaultColors.ActiveLineForegroundUnfocused;
  { Bookmarks }
  FBookmarkBlue := TDefaultColors.BookmarkBlue;
  FBookmarkGreen := TDefaultColors.BookmarkGreen;
  FBookmarkLineBackground := TAlphaColors.Null;
  FBookmarkPurple := TDefaultColors.BookmarkPurple;
  FBookmarkRed := TDefaultColors.BookmarkRed;
  FBookmarkYellow := TDefaultColors.BookmarkYellow;
  { Caret multiedit }
  FCaretMultiEditBackground := TAlphaColors.Black;
  FCaretMultiEditForeground := TAlphaColors.White;
  { Caret non-blinking }
  FCaretNonBlinkingBackground := TAlphaColors.Black;
  FCaretNonBlinkingForeground := TAlphaColors.White;
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
  FCodeFoldingHintBackground := TAlphaColors.White;
  FCodeFoldingHintBorder := TDefaultColors.LineNumbers;
  FCodeFoldingHintText := TAlphaColors.Black;
  { Code folding hint indicator }
  FCodeFoldingHintIndicatorBackground := TDefaultColors.LeftMarginBackground;
  FCodeFoldingHintIndicatorBorder := TDefaultColors.LineNumbers;
  FCodeFoldingHintIndicatorMark := TDefaultColors.LineNumbers;
  { Compare }
  FCompareBackground := TDefaultColors.PaleRed;
  FCompareForeground := TDefaultColors.Red;
  { Completion proposal }
  FCompletionProposalBackground := TAlphaColors.White;
  FCompletionProposalBorder := TDefaultColors.LineNumbers;
  FCompletionProposalForeground := TAlphaColors.Black;
  FCompletionProposalSelectedBackground := TDefaultColors.SysHighlight;
  FCompletionProposalSelectedText := TDefaultColors.SysHighlightText;
  { Editor }
  FEditorAssemblerCommentBackground := TDefaultColors.BlockBackground;
  FEditorAssemblerCommentForeground := TAlphaColors.Green;
  FEditorAssemblerReservedWordBackground := TDefaultColors.BlockBackground;
  FEditorAssemblerReservedWordForeground := TAlphaColors.Navy;
  FEditorAttributeBackground := TAlphaColors.White;
  FEditorAttributeForeground := TAlphaColors.Maroon;
  FEditorBackground := TAlphaColors.White;
  FEditorCharacterBackground := TAlphaColors.White;
  FEditorCharacterForeground := TAlphaColors.Purple;
  FEditorCommentBackground := TAlphaColors.White;
  FEditorCommentForeground := TAlphaColors.Green;
  FEditorDirectiveBackground := TAlphaColors.White;
  FEditorDirectiveForeground := TAlphaColors.Teal;
  FEditorForeground := TAlphaColors.Black;
  FEditorHexNumberBackground := TAlphaColors.White;
  FEditorHexNumberForeground := TAlphaColors.Blue;
  FEditorHighlightedBlockBackground := TDefaultColors.BlockBackground;
  FEditorHighlightedBlockForeground := TAlphaColors.Black;
  FEditorHighlightedBlockSymbolBackground := TDefaultColors.BlockBackground;
  FEditorHighlightedBlockSymbolForeground := TAlphaColors.Navy;
  FEditorLogicalOperatorBackground := TAlphaColors.White;
  FEditorLogicalOperatorForeground := TAlphaColors.Navy;
  FEditorMethodBackground := TAlphaColors.Null;
  FEditorMethodForeground := TAlphaColors.Navy;
  FEditorMethodItalicBackground := TAlphaColors.Null;
  FEditorMethodItalicForeground := TAlphaColors.Navy;
  FEditorMethodNameBackground := TAlphaColors.Null;
  FEditorMethodNameForeground := TAlphaColors.Black;
  FEditorNumberBackground := TAlphaColors.White;
  FEditorNumberForeground := TAlphaColors.Blue;
  FEditorReservedWordBackground := TAlphaColors.White;
  FEditorReservedWordForeground := TAlphaColors.Navy;
  FEditorStringBackground := TAlphaColors.White;
  FEditorStringForeground := TAlphaColors.Blue;
  FEditorSymbolBackground := TAlphaColors.White;
  FEditorSymbolForeground := TAlphaColors.Navy;
  FEditorValueBackground := TAlphaColors.White;
  FEditorValueForeground := TAlphaColors.Navy;
  FEditorWebLinkBackground := TAlphaColors.White;
  FEditorWebLinkForeground := TAlphaColors.Blue;
  { Hint }
  FHintBackground := TDefaultColors.HintBackground;
  FHintBorder := TDefaultColors.LineNumbers;
  FHintText := TDefaultColors.HintText;
  { Left margin }
  FLeftMarginActiveLineBackground := TDefaultColors.ActiveLineBackground;
  FLeftMarginActiveLineBackgroundUnfocused := TDefaultColors.ActiveLineBackgroundUnfocused;
  FLeftMarginActiveLineNumber := TDefaultColors.LineNumbers;
  FLeftMarginBackground := TDefaultColors.LeftMarginBackground;
  FLeftMarginBookmarkPanelBackground := TAlphaColors.White;
  FLeftMarginBorder := TDefaultColors.LeftMarginBackground;
  FLeftMarginLineNumberLine := TDefaultColors.LineNumbers;
  FLeftMarginLineNumbers := TDefaultColors.LineNumbers;
  FLeftMarginLineStateModified := TAlphaColors.Yellow;
  FLeftMarginLineStateNormal := TAlphaColors.Lime;
  { Matching pair }
  FMatchingPairMatched := TAlphaColors.Aqua;
  FMatchingPairUnderline := TDefaultColors.MatchingPairUnderline;
  FMatchingPairUnmatched := TAlphaColors.Yellow;
  { Minimap }
  FMinimapBackground := TAlphaColors.Null;
  FMinimapBookmark := TDefaultColors.MinimapBookmark;
  FMinimapVisibleRows := TDefaultColors.ActiveLineBackground;
  { Right margin }
  FRightMargin := TAlphaColors.Silver;
  FRightMovingEdge := TAlphaColors.Silver;
  { Ruler }
  FRulerBackground := TDefaultColors.LeftMarginBackground;
  FRulerBorder := TDefaultColors.LineNumbers;
  FRulerLines := TDefaultColors.LineNumbers;
  FRulerMovingEdge := TAlphaColors.Silver;
  FRulerNumbers := TDefaultColors.LineNumbers;
  FRulerSelection := TDefaultColors.ActiveLineBackground;
  { Search highlighter }
  FSearchHighlighterBackground := TDefaultColors.SearchHighlighter;
  FSearchHighlighterBorder := TAlphaColors.Null;
  FSearchHighlighterForeground := TAlphaColors.Black;
  { Search in selection }
  FSearchInSelectionBackground := TDefaultColors.SearchInSelectionBackground;
  { Search map }
  FSearchMapActiveLine := TDefaultColors.ActiveLineBackgroundUnfocused;
  FSearchMapBackground := TAlphaColors.Null;
  FSearchMapForeground := TDefaultColors.SearchHighlighter;
  { Selection }
  FSelectionBackground := TDefaultColors.Selection;
  FSelectionBackgroundUnfocused := TDefaultColors.SelectionUnfocused;
  FSelectionForeground := TAlphaColors.White;
  FSelectionForegroundUnfocused := TAlphaColors.White;
  { Sync edit }
  FSyncEditBackground := TDefaultColors.SearchInSelectionBackground;
  FSyncEditEditBorder := TAlphaColors.Black;
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
    Self.FActiveLineBorder := FActiveLineBorder;
    Self.FActiveLineForeground := FActiveLineForeground;
    Self.FActiveLineForegroundUnfocused := FActiveLineForegroundUnfocused;
    { Bookmarks }
    Self.FBookmarkBlue := FBookmarkBlue;
    Self.FBookmarkGreen := FBookmarkGreen;
    Self.FBookmarkLineBackground := FBookmarkLineBackground;
    Self.FBookmarkPurple := FBookmarkPurple;
    Self.FBookmarkRed := FBookmarkRed;
    Self.FBookmarkYellow := FBookmarkYellow;
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
    { Compare }
    Self.FCompareBackground := FCompareBackground;
    Self.FCompareForeground := FCompareForeground;
    { Completion proposal }
    Self.FCompletionProposalBackground := FCompletionProposalBackground;
    Self.FCompletionProposalBorder := FCompletionProposalBorder;
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
    { Hint }
    Self.FHintBackground := FHintBackground;
    Self.FHintBorder := FHintBorder;
    Self.FHintText := FHintText;
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

function TTextEditorColors.SetColorDef(const AColor: TAlphaColor; const ADefault: TAlphaColor): TAlphaColor;
begin
  Result := if AColor = TDefaultColors.SysDefault then ADefault else AColor;
end;

procedure TTextEditorColors.SetActiveLineBackground(const AValue: TAlphaColor);
begin
  FActiveLineBackground := SetColorDef(AValue, TDefaultColors.ActiveLineBackground);
end;

procedure TTextEditorColors.SetActiveLineBackgroundUnfocused(const AValue: TAlphaColor);
begin
  FActiveLineBackgroundUnfocused := SetColorDef(AValue, TDefaultColors.ActiveLineBackgroundUnfocused);

  DoChange;
end;

procedure TTextEditorColors.SetActiveLineBorder(const AValue: TAlphaColor);
begin
  FActiveLineBorder := SetColorDef(AValue, TDefaultColors.ActiveLineBorder);

  DoChange;
end;

procedure TTextEditorColors.SetActiveLineForeground(const AValue: TAlphaColor);
begin
  FActiveLineForeground := SetColorDef(AValue, TDefaultColors.ActiveLineForeground);
end;

procedure TTextEditorColors.SetActiveLineForegroundUnfocused(const AValue: TAlphaColor);
begin
  FActiveLineForegroundUnfocused := SetColorDef(AValue, TDefaultColors.ActiveLineForegroundUnfocused);

  DoChange;
end;

procedure TTextEditorColors.SetBookmarkBlue(const AValue: TAlphaColor);
begin
  FBookmarkBlue := SetColorDef(AValue, TDefaultColors.BookmarkBlue);
end;

procedure TTextEditorColors.SetBookmarkGreen(const AValue: TAlphaColor);
begin
  FBookmarkGreen := SetColorDef(AValue, TDefaultColors.BookmarkGreen);
end;

procedure TTextEditorColors.SetBookmarkLineBackground(const AValue: TAlphaColor);
begin
  FBookmarkLineBackground := SetColorDef(AValue, TAlphaColors.Null);
end;

procedure TTextEditorColors.SetBookmarkPurple(const AValue: TAlphaColor);
begin
  FBookmarkPurple := SetColorDef(AValue, TDefaultColors.BookmarkPurple);
end;

procedure TTextEditorColors.SetBookmarkRed(const AValue: TAlphaColor);
begin
  FBookmarkRed := SetColorDef(AValue, TDefaultColors.BookmarkRed);
end;

procedure TTextEditorColors.SetBookmarkYellow(const AValue: TAlphaColor);
begin
  FBookmarkYellow := SetColorDef(AValue, TDefaultColors.BookmarkYellow);
end;

procedure TTextEditorColors.SetCaretMultiEditBackground(const AValue: TAlphaColor);
begin
  FCaretMultiEditBackground := SetColorDef(AValue, TAlphaColors.Black);
end;

procedure TTextEditorColors.SetCaretMultiEditForeground(const AValue: TAlphaColor);
begin
  FCaretMultiEditForeground := SetColorDef(AValue, TAlphaColors.White);
end;

procedure TTextEditorColors.SetCaretNonBlinkingBackground(const AValue: TAlphaColor);
begin
  FCaretNonBlinkingBackground := SetColorDef(AValue, TAlphaColors.Black);
end;

procedure TTextEditorColors.SetCaretNonBlinkingForeground(const AValue: TAlphaColor);
begin
  FCaretNonBlinkingForeground := SetColorDef(AValue, TAlphaColors.White);
end;

procedure TTextEditorColors.SetCodeFoldingActiveLineBackground(const AValue: TAlphaColor);
begin
  FCodeFoldingActiveLineBackground := SetColorDef(AValue, TDefaultColors.ActiveLineBackground);
end;

procedure TTextEditorColors.SetCodeFoldingActiveLineBackgroundUnfocused(const AValue: TAlphaColor);
begin
  FCodeFoldingActiveLineBackgroundUnfocused := SetColorDef(AValue, TDefaultColors.ActiveLineBackgroundUnfocused);
end;

procedure TTextEditorColors.SetCodeFoldingBackground(const AValue: TAlphaColor);
begin
  FCodeFoldingBackground := SetColorDef(AValue, TDefaultColors.LeftMarginBackground);
end;

procedure TTextEditorColors.SetCodeFoldingCollapsedLine(const AValue: TAlphaColor);
begin
  FCodeFoldingCollapsedLine := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetCodeFoldingFoldingLine(const AValue: TAlphaColor);
begin
  FCodeFoldingFoldingLine := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetCodeFoldingFoldingLineHighlight(const AValue: TAlphaColor);
begin
  FCodeFoldingFoldingLineHighlight := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetCodeFoldingHintBackground(const AValue: TAlphaColor);
begin
  FCodeFoldingHintBackground := SetColorDef(AValue, TAlphaColors.White);
end;

procedure TTextEditorColors.SetCodeFoldingHintBorder(const AValue: TAlphaColor);
begin
  FCodeFoldingHintBorder := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetCodeFoldingHintIndicatorBackground(const AValue: TAlphaColor);
begin
  FCodeFoldingHintIndicatorBackground := SetColorDef(AValue, TDefaultColors.LeftMarginBackground);
end;

procedure TTextEditorColors.SetCodeFoldingHintIndicatorBorder(const AValue: TAlphaColor);
begin
  FCodeFoldingHintIndicatorBorder := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetCodeFoldingHintIndicatorMark(const AValue: TAlphaColor);
begin
  FCodeFoldingHintIndicatorMark := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetCodeFoldingHintText(const AValue: TAlphaColor);
begin
  FCodeFoldingHintText := SetColorDef(AValue, TAlphaColors.Black);
end;

procedure TTextEditorColors.SetCodeFoldingIndent(const AValue: TAlphaColor);
begin
  FCodeFoldingIndent := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetCodeFoldingIndentHighlight(const AValue: TAlphaColor);
begin
  FCodeFoldingIndentHighlight := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetCompareBackground(const AValue: TAlphaColor);
begin
  FCompareBackground := SetColorDef(AValue, TDefaultColors.PaleRed);
end;

procedure TTextEditorColors.SetCompareForeground(const AValue: TAlphaColor);
begin
  FCompareForeground := SetColorDef(AValue, TDefaultColors.Red);
end;

procedure TTextEditorColors.SetCompletionProposalBackground(const AValue: TAlphaColor);
begin
  FCompletionProposalBackground := SetColorDef(AValue, TAlphaColors.White);
end;

procedure TTextEditorColors.SetCompletionProposalBorder(const AValue: TAlphaColor);
begin
  FCompletionProposalBorder := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetCompletionProposalForeground(const AValue: TAlphaColor);
begin
  FCompletionProposalForeground := SetColorDef(AValue, TAlphaColors.Black);
end;

procedure TTextEditorColors.SetCompletionProposalSelectedBackground(const AValue: TAlphaColor);
begin
  FCompletionProposalSelectedBackground := SetColorDef(AValue, TDefaultColors.SysHighlight);
end;

procedure TTextEditorColors.SetCompletionProposalSelectedText(const AValue: TAlphaColor);
begin
  FCompletionProposalSelectedText := SetColorDef(AValue, TDefaultColors.SysHighlightText);
end;

procedure TTextEditorColors.SetEditorAssemblerCommentBackground(const AValue: TAlphaColor);
begin
  FEditorAssemblerCommentBackground := SetColorDef(AValue, TDefaultColors.BlockBackground);
end;

procedure TTextEditorColors.SetEditorAssemblerCommentForeground(const AValue: TAlphaColor);
begin
  FEditorAssemblerCommentForeground := SetColorDef(AValue, TAlphaColors.Green);
end;

procedure TTextEditorColors.SetEditorAssemblerReservedWordBackground(const AValue: TAlphaColor);
begin
  FEditorAssemblerReservedWordBackground := SetColorDef(AValue, TDefaultColors.BlockBackground);
end;

procedure TTextEditorColors.SetEditorAssemblerReservedWordForeground(const AValue: TAlphaColor);
begin
  FEditorAssemblerReservedWordForeground := SetColorDef(AValue, TAlphaColors.Navy);
end;

procedure TTextEditorColors.SetEditorAttributeBackground(const AValue: TAlphaColor);
begin
  FEditorAttributeBackground := SetColorDef(AValue, TAlphaColors.White);
end;

procedure TTextEditorColors.SetEditorAttributeForeground(const AValue: TAlphaColor);
begin
  FEditorAttributeForeground := SetColorDef(AValue, TAlphaColors.Maroon);
end;

procedure TTextEditorColors.SetEditorBackground(const AValue: TAlphaColor);
begin
  FEditorBackground := AValue;

  DoChange;
end;

procedure TTextEditorColors.SetEditorCharacterBackground(const AValue: TAlphaColor);
begin
  FEditorCharacterBackground := SetColorDef(AValue, TAlphaColors.White);
end;

procedure TTextEditorColors.SetEditorCharacterForeground(const AValue: TAlphaColor);
begin
  FEditorCharacterForeground := SetColorDef(AValue, TAlphaColors.Purple);
end;

procedure TTextEditorColors.SetEditorCommentBackground(const AValue: TAlphaColor);
begin
  FEditorCommentBackground := SetColorDef(AValue, TAlphaColors.White);
end;

procedure TTextEditorColors.SetEditorCommentForeground(const AValue: TAlphaColor);
begin
  FEditorCommentForeground := SetColorDef(AValue, TAlphaColors.Green);
end;

procedure TTextEditorColors.SetEditorDirectiveBackground(const AValue: TAlphaColor);
begin
  FEditorDirectiveBackground := SetColorDef(AValue, TAlphaColors.White);
end;

procedure TTextEditorColors.SetEditorDirectiveForeground(const AValue: TAlphaColor);
begin
  FEditorDirectiveForeground := SetColorDef(AValue, TAlphaColors.Teal);
end;

procedure TTextEditorColors.SetEditorForeground(const AValue: TAlphaColor);
begin
  FEditorForeground := AValue;

  DoChange;
end;

procedure TTextEditorColors.SetEditorHexNumberBackground(const AValue: TAlphaColor);
begin
  FEditorHexNumberBackground := SetColorDef(AValue, TAlphaColors.White);
end;

procedure TTextEditorColors.SetEditorHexNumberForeground(const AValue: TAlphaColor);
begin
  FEditorHexNumberForeground := SetColorDef(AValue, TAlphaColors.Blue);
end;

procedure TTextEditorColors.SetEditorHighlightedBlockBackground(const AValue: TAlphaColor);
begin
  FEditorHighlightedBlockBackground := SetColorDef(AValue, TDefaultColors.BlockBackground);
end;

procedure TTextEditorColors.SetEditorHighlightedBlockForeground(const AValue: TAlphaColor);
begin
  FEditorHighlightedBlockForeground := SetColorDef(AValue, TAlphaColors.Black);
end;

procedure TTextEditorColors.SetEditorHighlightedBlockSymbolBackground(const AValue: TAlphaColor);
begin
  FEditorHighlightedBlockSymbolBackground := SetColorDef(AValue, TDefaultColors.BlockBackground);
end;

procedure TTextEditorColors.SetEditorHighlightedBlockSymbolForeground(const AValue: TAlphaColor);
begin
  FEditorHighlightedBlockSymbolForeground := SetColorDef(AValue, TAlphaColors.Navy);
end;

procedure TTextEditorColors.SetEditorLogicalOperatorBackground(const AValue: TAlphaColor);
begin
  FEditorLogicalOperatorBackground := SetColorDef(AValue, TAlphaColors.White);
end;

procedure TTextEditorColors.SetEditorLogicalOperatorForeground(const AValue: TAlphaColor);
begin
  FEditorLogicalOperatorForeground := SetColorDef(AValue, TAlphaColors.Navy);
end;

procedure TTextEditorColors.SetEditorMethodBackground(const AValue: TAlphaColor);
begin
  FEditorMethodBackground := SetColorDef(AValue, TAlphaColors.Null);
end;

procedure TTextEditorColors.SetEditorMethodForeground(const AValue: TAlphaColor);
begin
  FEditorMethodForeground := SetColorDef(AValue, TAlphaColors.Navy);
end;

procedure TTextEditorColors.SetEditorMethodItalicBackground(const AValue: TAlphaColor);
begin
  FEditorMethodItalicBackground := SetColorDef(AValue, TAlphaColors.Null);
end;

procedure TTextEditorColors.SetEditorMethodItalicForeground(const AValue: TAlphaColor);
begin
  FEditorMethodItalicForeground := SetColorDef(AValue, TAlphaColors.Navy);
end;

procedure TTextEditorColors.SetEditorMethodNameBackground(const AValue: TAlphaColor);
begin
  FEditorMethodNameBackground := SetColorDef(AValue, TAlphaColors.Null);
end;

procedure TTextEditorColors.SetEditorMethodNameForeground(const AValue: TAlphaColor);
begin
  FEditorMethodNameForeground := SetColorDef(AValue, TAlphaColors.Black);
end;

procedure TTextEditorColors.SetEditorNumberBackground(const AValue: TAlphaColor);
begin
  FEditorNumberBackground := SetColorDef(AValue, TAlphaColors.White);
end;

procedure TTextEditorColors.SetEditorNumberForeground(const AValue: TAlphaColor);
begin
  FEditorNumberForeground := SetColorDef(AValue, TAlphaColors.Blue);
end;

procedure TTextEditorColors.SetEditorReservedWordBackground(const AValue: TAlphaColor);
begin
  FEditorReservedWordBackground := SetColorDef(AValue, TAlphaColors.White);
end;

procedure TTextEditorColors.SetEditorReservedWordForeground(const AValue: TAlphaColor);
begin
  FEditorReservedWordForeground := SetColorDef(AValue, TAlphaColors.Navy);
end;

procedure TTextEditorColors.SetEditorStringBackground(const AValue: TAlphaColor);
begin
  FEditorStringBackground := SetColorDef(AValue, TAlphaColors.White);
end;

procedure TTextEditorColors.SetEditorStringForeground(const AValue: TAlphaColor);
begin
  FEditorStringForeground := SetColorDef(AValue, TAlphaColors.Blue);
end;

procedure TTextEditorColors.SetEditorSymbolBackground(const AValue: TAlphaColor);
begin
  FEditorSymbolBackground := SetColorDef(AValue, TAlphaColors.White);
end;

procedure TTextEditorColors.SetEditorSymbolForeground(const AValue: TAlphaColor);
begin
  FEditorSymbolForeground := SetColorDef(AValue, TAlphaColors.Navy);
end;

procedure TTextEditorColors.SetEditorValueBackground(const AValue: TAlphaColor);
begin
  FEditorValueBackground := SetColorDef(AValue, TAlphaColors.White);
end;

procedure TTextEditorColors.SetEditorValueForeground(const AValue: TAlphaColor);
begin
  FEditorValueForeground := SetColorDef(AValue, TAlphaColors.Navy);
end;

procedure TTextEditorColors.SetEditorWebLinkBackground(const AValue: TAlphaColor);
begin
  FEditorWebLinkBackground := SetColorDef(AValue, TAlphaColors.White);
end;

procedure TTextEditorColors.SetEditorWebLinkForeground(const AValue: TAlphaColor);
begin
  FEditorWebLinkForeground := SetColorDef(AValue, TAlphaColors.Blue);
end;

procedure TTextEditorColors.SetHintBackground(const AValue: TAlphaColor);
begin
  FHintBackground := SetColorDef(AValue, TDefaultColors.HintBackground);
end;

procedure TTextEditorColors.SetHintBorder(const AValue: TAlphaColor);
begin
  FHintBorder := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetHintText(const AValue: TAlphaColor);
begin
  FHintText := SetColorDef(AValue, TDefaultColors.HintText);
end;

procedure TTextEditorColors.SetLeftMarginActiveLineBackground(const AValue: TAlphaColor);
begin
  FLeftMarginActiveLineBackground := SetColorDef(AValue, TDefaultColors.ActiveLineBackground);
end;

procedure TTextEditorColors.SetLeftMarginActiveLineBackgroundUnfocused(const AValue: TAlphaColor);
begin
  FLeftMarginActiveLineBackgroundUnfocused := SetColorDef(AValue, TDefaultColors.ActiveLineBackgroundUnfocused);

  DoChange;
end;

procedure TTextEditorColors.SetLeftMarginActiveLineNumber(const AValue: TAlphaColor);
begin
  FLeftMarginActiveLineNumber := SetColorDef(AValue, TAlphaColors.Null);

  DoChange;
end;

procedure TTextEditorColors.SetLeftMarginBackground(const AValue: TAlphaColor);
begin
  FLeftMarginBackground := SetColorDef(AValue, TDefaultColors.LeftMarginBackground);

  DoChange;
end;

procedure TTextEditorColors.SetLeftMarginBookmarkPanelBackground(const AValue: TAlphaColor);
begin
  FLeftMarginBookmarkPanelBackground := SetColorDef(AValue, TAlphaColors.Null);

  DoChange;
end;

procedure TTextEditorColors.SetLeftMarginBorder(const AValue: TAlphaColor);
begin
  FLeftMarginBorder := SetColorDef(AValue, TDefaultColors.LeftMarginBackground);

  DoChange;
end;

procedure TTextEditorColors.SetLeftMarginLineNumberLine(const AValue: TAlphaColor);
begin
  FLeftMarginLineNumberLine := SetColorDef(AValue, TDefaultColors.LineNumbers);

  DoChange;
end;

procedure TTextEditorColors.SetLeftMarginLineNumbers(const AValue: TAlphaColor);
begin
  FLeftMarginLineNumbers := SetColorDef(AValue, TAlphaColors.Black);

  DoChange;
end;

procedure TTextEditorColors.SetLeftMarginLineStateModified(const AValue: TAlphaColor);
begin
  FLeftMarginLineStateModified := SetColorDef(AValue, TAlphaColors.Yellow);
end;

procedure TTextEditorColors.SetLeftMarginLineStateNormal(const AValue: TAlphaColor);
begin
  FLeftMarginLineStateNormal := SetColorDef(AValue, TAlphaColors.Lime);
end;

procedure TTextEditorColors.SetMatchingPairMatched(const AValue: TAlphaColor);
begin
  FMatchingPairMatched := SetColorDef(AValue, TAlphaColors.Aqua);
end;

procedure TTextEditorColors.SetMatchingPairUnderline(const AValue: TAlphaColor);
begin
  FMatchingPairUnderline := SetColorDef(AValue, TDefaultColors.MatchingPairUnderline);
end;

procedure TTextEditorColors.SetMatchingPairUnmatched(const AValue: TAlphaColor);
begin
  FMatchingPairUnmatched := SetColorDef(AValue, TAlphaColors.Yellow);
end;

procedure TTextEditorColors.SetMinimapBackground(const AValue: TAlphaColor);
begin
  FMinimapBackground := SetColorDef(AValue, TAlphaColors.Null);
end;

procedure TTextEditorColors.SetMinimapBookmark(const AValue: TAlphaColor);
begin
  FMinimapBookmark := SetColorDef(AValue, TDefaultColors.MinimapBookmark);
end;

procedure TTextEditorColors.SetMinimapVisibleRows(const AValue: TAlphaColor);
begin
  FMinimapVisibleRows := SetColorDef(AValue, TDefaultColors.ActiveLineBackground);
end;

procedure TTextEditorColors.SetRightMargin(const AValue: TAlphaColor);
begin
  FRightMargin := SetColorDef(AValue, TAlphaColors.Silver);
end;

procedure TTextEditorColors.SetRightMovingEdge(const AValue: TAlphaColor);
begin
  FRightMovingEdge := SetColorDef(AValue, TAlphaColors.Silver);
end;

procedure TTextEditorColors.SetRulerBackground(const AValue: TAlphaColor);
begin
  FRulerBackground := SetColorDef(AValue, TDefaultColors.LeftMarginBackground);
end;

procedure TTextEditorColors.SetRulerBorder(const AValue: TAlphaColor);
begin
  FRulerBorder := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetRulerLines(const AValue: TAlphaColor);
begin
  FRulerLines := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetRulerMovingEdge(const AValue: TAlphaColor);
begin
  FRulerMovingEdge := SetColorDef(AValue, TAlphaColors.Silver);
end;

procedure TTextEditorColors.SetRulerNumbers(const AValue: TAlphaColor);
begin
  FRulerNumbers := SetColorDef(AValue, TDefaultColors.LineNumbers);
end;

procedure TTextEditorColors.SetRulerSelection(const AValue: TAlphaColor);
begin
  FRulerSelection := SetColorDef(AValue, TDefaultColors.ActiveLineBackground);
end;

procedure TTextEditorColors.SetSearchHighlighterBackground(const AValue: TAlphaColor);
begin
  FSearchHighlighterBackground := SetColorDef(AValue, TDefaultColors.SearchHighlighter);
end;

procedure TTextEditorColors.SetSearchHighlighterBorder(const AValue: TAlphaColor);
begin
  FSearchHighlighterBorder := SetColorDef(AValue, TAlphaColors.Null);
end;

procedure TTextEditorColors.SetSearchHighlighterForeground(const AValue: TAlphaColor);
begin
  FSearchHighlighterForeground := SetColorDef(AValue, TAlphaColors.Black);
end;

procedure TTextEditorColors.SetSearchInSelectionBackground(const AValue: TAlphaColor);
begin
  FSearchInSelectionBackground := SetColorDef(AValue, TDefaultColors.SearchInSelectionBackground);
end;

procedure TTextEditorColors.SetSearchMapActiveLine(const AValue: TAlphaColor);
begin
  FSearchMapActiveLine := SetColorDef(AValue, TDefaultColors.ActiveLineBackgroundUnfocused);
end;

procedure TTextEditorColors.SetSearchMapBackground(const AValue: TAlphaColor);
begin
  FSearchMapBackground := SetColorDef(AValue, TAlphaColors.Null);
end;

procedure TTextEditorColors.SetSearchMapForeground(const AValue: TAlphaColor);
begin
  FSearchMapForeground := SetColorDef(AValue, TDefaultColors.SearchHighlighter);
end;

procedure TTextEditorColors.SetSelectionBackground(const AValue: TAlphaColor);
begin
  FSelectionBackground := SetColorDef(AValue, TDefaultColors.Selection);
end;

procedure TTextEditorColors.SetSelectionBackgroundUnfocused(const AValue: TAlphaColor);
begin
  FSelectionBackgroundUnfocused := SetColorDef(AValue, TDefaultColors.SelectionUnfocused);
end;

procedure TTextEditorColors.SetSelectionForeground(const AValue: TAlphaColor);
begin
  FSelectionForeground := SetColorDef(AValue, TAlphaColors.White);
end;

procedure TTextEditorColors.SetSelectionForegroundUnfocused(const AValue: TAlphaColor);
begin
  FSelectionForegroundUnfocused := SetColorDef(AValue, TAlphaColors.White);
end;

procedure TTextEditorColors.SetSyncEditBackground(const AValue: TAlphaColor);
begin
  FSyncEditBackground := SetColorDef(AValue, TDefaultColors.SearchInSelectionBackground);
end;

procedure TTextEditorColors.SetSyncEditEditBorder(const AValue: TAlphaColor);
begin
  FSyncEditEditBorder := SetColorDef(AValue, TAlphaColors.Black);
end;

procedure TTextEditorColors.SetSyncEditWordBorder(const AValue: TAlphaColor);
begin
  FSyncEditWordBorder := SetColorDef(AValue, TDefaultColors.Selection);
end;

procedure TTextEditorColors.SetWordWrapIndicatorArrow(const AValue: TAlphaColor);
begin
  FWordWrapIndicatorArrow := SetColorDef(AValue, TDefaultColors.WordWrapIndicatorArrow);
end;

procedure TTextEditorColors.SetWordWrapIndicatorLines(const AValue: TAlphaColor);
begin
  FWordWrapIndicatorLines := SetColorDef(AValue, TDefaultColors.WordWrapIndicatorLines);
end;

end.
