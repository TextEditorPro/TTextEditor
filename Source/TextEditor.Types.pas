unit TextEditor.Types;

interface

uses
  Winapi.Windows, System.Classes, System.Generics.Collections, System.SysUtils, Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms,
  Vcl.Graphics, TextEditor.Consts, TextEditor.Marks;

type
  IAutoCursor = interface(IInterface)
    ['{B291F81E-29FB-453E-B3AF-51D4EC1352CF}']
    procedure BeginCursor(const ACursor: TCursor);
    procedure EndCursor;
  end;

  { Lines }
  TTextEditorLinesRange = Pointer;

  TTextEditorStringFlag = (sfHasTabs, sfHasNoTabs, sfExpandedLengthUnknown, sfEmptyLine, sfModify,
    sfLineBreakCR, sfLineBreakLF, sfLineStateNormal, sfLineStateModified);
  TTextEditorStringFlags = set of TTextEditorStringFlag;

  TTextEditorSortOption = (soAsc, soDesc, soIgnoreCase, {$IF CompilerVersion >= 34.0}soNatural,{$ENDIF} soRandom);
  TTextEditorSortOptions = set of TTextEditorSortOption;

  TTextEditorLineState = (lsNone, lsNormal, lsModified);
  TTextEditorLineBreak = (lbCRLF, lbLF, lbCR);

  PTextEditorStringRecord = ^TTextEditorStringRecord;
  TTextEditorStringRecord = record
    Flags: TTextEditorStringFlags;
    ExpandedLength: Integer;
    Range: TTextEditorLinesRange;
    TextLine: string;
    OriginalLineNumber: Integer;
  end;

  TTextEditorArrayOfString = array of string;
  TTextEditorArrayOfSingle = array of Single;

  TStringListChangeEvent = procedure(ASender: TObject; const AIndex: Integer; const ACount: Integer) of object;

  { Editor painting }
  TRGBTriple = record
    Blue, Green, Red: Byte;
  end;
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..100] of TRGBTriple;

  TTextEditorColorChanges = (ccBoth, ccBackground, ccForeground);

  TTextEditorStateFlag = (sfCaretChanged, sfLinesChanging, sfIgnoreNextChar, sfCaretVisible, sfDblClicked,
    sfWaitForDragging, sfCodeFoldingCollapseMarkClicked, sfInSelection, sfDragging);
  TTextEditorStateFlags = set of TTextEditorStateFlag;

  PTextEditorTextPosition = ^TTextEditorTextPosition;
  TTextEditorTextPosition = record
    Char: Integer;
    Line: Integer;
  end;

  PTextEditorViewPosition = ^TTextEditorViewPosition;
  TTextEditorViewPosition = record
    Column: Integer;
    Row: Integer;
  end;

  PTextEditorMultiCaretRecord = ^TTextEditorMultiCaretRecord;
  TTextEditorMultiCaretRecord = record
    ViewPosition: TTextEditorViewPosition;
    SelectionBegin: TTextEditorTextPosition;
  end;

  TTextEditorEmptySpace = (esNone, esControlCharacter, esSpace, esNull, esTab, esZeroWidthSpace);

  TTextEditorUnderline = (ulNone, ulDoubleUnderline, ulUnderline, ulWaveLine, ulWavyZigzag);

  TTextEditorMoveDirection = (mdUp, mdDown, mdLeft, mdRight);
  TTextEditorProgressType = (ptNone, ptProcessing, ptLoading);

  PTextEditorQuadColor = ^TTextEditorQuadColor;
  TTextEditorQuadColor = record
  case Boolean of
    True: (Blue, Green, Red, Alpha: Byte);
    False: (Quad: Cardinal);
  end;

  { Caret }
  TTextEditorCaretStyle = (csVerticalLine, csThinVerticalLine, csHorizontalLine, csThinHorizontalLine, csHalfBlock, csBlock);

  TTextEditorCaretOption = (coRightMouseClickMove);
  TTextEditorCaretOptions = set of TTextEditorCaretOption;

  TTextEditorCaretMultiEditOption = (meoShowActiveLine, meoShowGhost);
  TTextEditorCaretMultiEditOptions = set of TTextEditorCaretMultiEditOption;

  { Replace }
  TTextEditorReplaceAction = (raCancel, raSkip, raReplace, raReplaceAll);
  TTextEditorReplaceChanges = (rcEngineUpdate);
  TTextEditorReplaceOption = (roBackwards, roCaseSensitive, roEntireScope, roPrompt, roReplaceAll, roSelectedOnly,
    roWholeWordsOnly);
  TTextEditorReplaceOptions = set of TTextEditorReplaceOption;
  TTextEditorReplaceActionOption = (eraReplace, eraDeleteLine);

  { Completion proposal }
  TCompletionProposalOptions = record
    AddHighlighterKeywords: Boolean;
    AddSnippets: Boolean;
    CodeInsight: Boolean;
    ParseItemsFromText: Boolean;
    ShowDescription: Boolean;
    SortByDescription: Boolean;
    SortByKeyword: Boolean;
    Triggered: Boolean;
  end;

  TTextEditorCompletionProposalOption = (cpoAutoInvoke, cpoAutoConstraints, cpoAddHighlighterKeywords, cpoCaseSensitive,
    cpoFiltered, cpoParseItemsFromText, cpoShowShadow);
  TTextEditorCompletionProposalOptions = set of TTextEditorCompletionProposalOption;

  TTextEditorCompletionProposalKeywordCase = (kcUpperCase, kcLowerCase, kcSentenceCase);

  TTextEditorCompletionProposalItem = record
    Keyword: string;
    Description: string;
    SnippetIndex: Integer;
  end;
  TTextEditorCompletionProposalItems = TList<TTextEditorCompletionProposalItem>;

  { Editor options }
  TTextEditorOption = (eoAddHTMLCodeToClipboard, eoAutoIndent, eoDragDropEditing, eoDropFiles,
    eoShowControlCharacters, eoShowLineNumbersInHTMLExport, eoShowNonBreakingSpaceAsSpace, eoShowNullCharacters
{$IFDEF TEXT_EDITOR_SPELL_CHECK}, eoSpellCheck{$ENDIF}, eoShowZeroWidthSpaces, eoTrimTrailingSpaces, eoTrailingLineBreak);
  TTextEditorOptions = set of TTextEditorOption;

  TTextEditorOvertypeMode = (omInsert, omOverwrite);

  PTextEditorSelectionMode = ^TTextEditorSelectionMode;
  TTextEditorSelectionMode = (smColumn, smNormal);

  { Scroll }
  TTextEditorScrollOption = (soHalfPage, soHintFollows, soPastEndOfFileMarker, soPastEndOfLine, soShowVerticalScrollHint,
    soWheelClickMove);
  TTextEditorScrollOptions = set of TTextEditorScrollOption;

  TTextEditorScrollHintFormat = (shfTopLineOnly, shfTopToBottom);

  { Tabs }
  TTextEditorTabOption = (toColumns, toPreviousLineIndent, toSelectedBlockIndent, toTabsToSpaces);
  TTextEditorTabOptions = set of TTextEditorTabOption;

  { Selection }
  TTextEditorSelectionOption = (soALTSetsColumnMode, soExpandPrefix, soExpandRealNumbers, soHighlightSimilarTerms,
    soTermsCaseSensitive, soToEndOfLine, soTripleClickRowSelect, soAutoCopyToClipboard);
  TTextEditorSelectionOptions = set of TTextEditorSelectionOption;

  { Search }
  TTextEditorSearchChanges = (scRefresh, scSearch, scEngineUpdate, scInSelectionActive, scVisible);

  TTextEditorSearchOption = (soBeepIfStringNotFound, soCaseSensitive, soEntireScope, soHighlightResults,
    soSearchOnTyping, soShowSearchStringNotFound, soShowSearchMatchNotFound, soWholeWordsOnly,
    soWrapAround);
  TTextEditorSearchOptions = set of TTextEditorSearchOption;

  TTextEditorSearchEngine = (seNormal, seExtended, seRegularExpression, seWildcard);

  PTextEditorSearchItem = ^TTextEditorSearchItem;
  TTextEditorSearchItem = record
    BeginTextPosition: TTextEditorTextPosition;
    EndTextPosition: TTextEditorTextPosition;
  end;

  TTextEditorSearchMapAlign = (saLeft, saRight);

  { Sync edit }
  TTextEditorSyncEditOption = (seCaseSensitive);
  TTextEditorSyncEditOptions = set of TTextEditorSyncEditOption;

  { Ruler }
  TTextEditorRulerOption = (roShowSelection);
  TTextEditorRulerOptions = set of TTextEditorRulerOption;

  { Search map }
  TTextEditorSearchMapOption = (moShowActiveLine);
  TTextEditorSearchMapOptions = set of TTextEditorSearchMapOption;

  { Left margin }
  TTextEditorLeftMarginBookmarkPanelOption = (bpoToggleBookmarkByClick, bpoToggleMarkByClick, bpoShowBookmarkColorsPopup);
  TTextEditorLeftMarginBookmarkPanelOptions = set of TTextEditorLeftMarginBookmarkPanelOption;

  TTextEditorLeftMarginLineNumberOption = (lnoIntens, lnoLeadingZeros, lnoAfterLastLine, lnoCompareMode);
  TTextEditorLeftMarginLineNumberOptions = set of TTextEditorLeftMarginLineNumberOption;

  TTextEditorLeftMarginBorderStyle = (mbsNone, mbsMiddle, mbsRight);
  TTextEditorLeftMarginLineStateAlign = (lsLeft, lsRight);

  { Right margin }
  TTextEditorRightMarginOption = (rmoAutoLinebreak, rmoMouseMove, rmoShowMovingHint);
  TTextEditorRightMarginOptions = set of TTextEditorRightMarginOption;

  { Matching pair }
  PTextEditorMatchingPairToken = ^TTextEditorMatchingPairToken;
  TTextEditorMatchingPairToken = record
    OpenToken: string;
    CloseToken: string;
  end;

  TTextEditorMatchingTokenResult = (trCloseAndOpenTokenFound, trCloseTokenFound, trNotFound, trOpenTokenFound,
    trOpenAndCloseTokenFound);

  TTextEditorMatchingPairOption = (mpoHighlightAfterToken, mpoHighlightUnmatched, mpoUnderline, mpoUseMatchedColor);
  TTextEditorMatchingPairOptions = set of TTextEditorMatchingPairOption;

  { Highlighter }
  TTextEditorBreakType = (btUnspecified, btAny, btTerm);

  TTextEditorRangeType = (ttUnspecified, ttAddress, ttAssemblerComment, ttAssemblerReservedWord, ttAttribute,
    ttBlockComment, ttCharacter, ttDirective, ttHexNumber, ttHighlightedBlock, ttHighlightedBlockSymbol, ttLineComment,
    ttMailtoLink, ttMethod, ttMethodName, ttNumber, ttReservedWord, ttString, ttSymbol, ttWebLink);

  TTextEditorKeyCharType = (ctFoldOpen, ctFoldClose, ctSkipOpen, ctSkipClose);

  TTextEditorHighlighterOption = (hoExecuteBeforePrepare, hoMultiHighlighter);
  TTextEditorHighlighterOptions = set of TTextEditorHighlighterOption;

  TTextEditorHighlighterColorOption = (hcoUseColorThemeFontNames, hcoUseColorThemeFontSizes, hcoUseDefaultColors);
  TTextEditorHighlighterColorOptions = set of TTextEditorHighlighterColorOption;

  { Special chars }
  TTextEditorSpecialCharsLineBreakStyle = (eolArrow, eolCRLF, eolEnter, eolPilcrow);

  TTextEditorSpecialCharsOption = (scoTextColor, scoMiddleColor, scoShowOnlyInSelection);
  TTextEditorSpecialCharsOptions = set of TTextEditorSpecialCharsOption;
  TTextEditorSpecialCharsStyle = (scsDot, scsSolid);

  { Minimap }
  TTextEditorMinimapOption = (moShowBookmarks, moShowIndentGuides, moShowSearchResults, moShowSelection,
    moShowSpecialChars);
  TTextEditorMinimapOptions = set of TTextEditorMinimapOption;
  TTextEditorMinimapAlign = (maLeft, maRight);
  TTextEditorMinimapIndicatorOption = (ioInvertBlending, ioShowBorder, ioUseBlending);
  TTextEditorMinimapIndicatorOptions = set of TTextEditorMinimapIndicatorOption;

  { Undo }
  TTextEditorUndoOption = (
    uoGroupUndo,
    uoUndoAfterSave
  );
  TTextEditorUndoOptions = set of TTextEditorUndoOption;

  TTextEditorChangeReason = (crInsert, crPaste, crDragDropInsert, crDelete, crLineBreak, crIndent, crUnindent, crCaret,
    crSelection, crNothing, crGroupBreak);

  { Case }
  TTextEditorCase = (cNone=-1, cUpper=0, cLower=1, cAlternating=2, cSentence=3, cTitle=4, cOriginal=5);

  { Trim }
  TTextEditorTrimStyle = (tsBoth, tsLeft, tsRight);

  { Coding }
  TTextEditorCoding = (eASCIIDecimal, eBase32, eBase64, eBase85, eBase91, eBase128, eBase256, eBase1024,
    eBase4096, eBase64WithLineBreaks, eBinary, eHex, eHexWithoutSpaces, eHTML, eOctal, eRotate5, eRotate13, eRotate18,
    eRotate47, eURL);

  { Word wrap }
  TTextEditorWordWrapWidth = (wwwPage, wwwRightMargin);

  { Code folding }
  TTextEditorCodeFoldingGuideLineStyle = (lsDash, lsDot, lsSolid);
  TTextEditorCodeFoldingMarkStyle = (msCircle, msSquare, msTriangle);
  TTextEditorCodeFoldingHintIndicatorMarkStyle = (imsThreeDots, imsTriangle);
  TTextEditorCodeFoldingChanges = (fcRefresh, fcVisible);
  TTextEditorCodeFoldingHintIndicatorOption = (hioShowBorder, hioShowMark);
  TTextEditorCodeFoldingHintIndicatorOptions = set of TTextEditorCodeFoldingHintIndicatorOption;

  TTextEditorCodeFoldingOption = (cfoAutoPadding, cfoAutoWidth, cfoFoldMultilineComments, cfoHighlightFoldingLine,
    cfoHighlightIndentGuides, cfoHighlightMatchingPair, cfoShowCollapsedLine, cfoShowIndentGuides, cfoShowTreeLine,
    cfoShowCollapseMarkAtTheEnd, cfoExpandByHintClick);
  TTextEditorCodeFoldingOptions = set of TTextEditorCodeFoldingOption;

  TTextEditorCodeFoldingHintIndicatorPadding = class(TPadding)
  protected
    class procedure InitDefaults(Margins: TMargins); override;
  published
    property Left default 0;
    property Top default 1;
    property Right default 0;
    property Bottom default 1;
  end;

  { Completion proposal }
  TCompletionProposalParams = record
    Items: TTextEditorCompletionProposalItems;
    LastWord: string;
    Options: TCompletionProposalOptions;
    PreviousCharAtCursor: string;
  end;

  { Snippets }
  TTextEditorSnippetExecuteWith = (seListOnly = -1, seEnter = 0, seSpace = 1);

  { Print }
  TTextEditorFrameType = (ftLine, ftBox, ftShaded);
  TTextEditorFrameTypes = set of TTextEditorFrameType;
  TTextEditorUnitSystem = (usMM, usCm, usInch, muThousandthsOfInches);
  TTextEditorPrintStatus = (psBegin, psNewPage, psEnd);
  TTextEditorPrintStatusEvent = procedure(ASender: TObject; const AStatus: TTextEditorPrintStatus; const APageNumber: Integer;
    var AAbort: Boolean) of object;
  TTextEditorPrintLineEvent = procedure(ASender: TObject; const ALineNumber: Integer; const APageNumber: Integer) of object;

  TTextEditorWrapPosition = class
  public
    Index: Integer;
  end;

  { Events }
  TOnCompletionProposalExecute = procedure(const ASender: TObject; var AParams: TCompletionProposalParams) of object;

  TTextEditorBookmarkDeletedEvent = procedure(const ASender: TObject; const ABookmark: TTextEditorMark) of object;
  TTextEditorBookmarkPlacedEvent = procedure(const ASender: TObject; const AIndex: Integer; const AImageIndex: Integer; const ATextPosition: TTextEditorTextPosition) of object;
  TTextEditorCaretChangedEvent = procedure(const ASender: TObject; const X, Y: Integer; const AOffset: Integer) of object;
  TTextEditorCodeColorEvent = procedure(const AEvent: TTextEditorColorChanges) of object;
  TTextEditorCodeFoldingChangeEvent = procedure(const AEvent: TTextEditorCodeFoldingChanges) of object;
  TTextEditorContextHelpEvent = procedure(const ASender: TObject; const AWord: string) of object;
  TTextEditorCreateHighlighterStreamEvent = procedure(const ASender: TObject; const AName: string;
    var AStream: TStream) of object;
  TTextEditorCustomLineColorsEvent = procedure(const ASender: TObject; const ALine: Integer; var AUseColors: Boolean;
    var AForeground: TColor; var ABackground: TColor) of object;
  TTextEditorCustomTokenAttributeEvent = procedure(const ASender: TObject; const AText: string; const ALine: Integer;
    const AChar: Integer; var AForegroundColor: TColor; var ABackgroundColor: TColor; var AStyles: TFontStyles;
    var AUnderline: TTextEditorUnderline; var AUnderlineColor: TColor) of object;
  TTextEditorDropFilesEvent = procedure(const ASender: TObject; const APos: TPoint; const AFiles: TStrings) of object;
  TTextEditorHighlighterPrepare = procedure of object;
  TTextEditorKeyPressWEvent = procedure(const ASender: TObject; var AKey: Char) of object;
  TTextEditorLinePaintEvent = procedure(const ASender: TObject; const ACanvas: TCanvas; const ARect: TRect;
    const ALineNumber: Integer; const AIsMinimapLine: Boolean) of object;
  TTextEditorMarkPanelLinePaintEvent = procedure(const ASender: TObject; const ACanvas: TCanvas; const ARect: TRect;
    const ALineNumber: Integer) of object;
  TTextEditorMarkPanelPaintEvent = procedure(const ASender: TObject; const ACanvas: TCanvas; const ARect: TRect;
    const AFirstLine: Integer; const ALastLine: Integer) of object;
  TTextEditorMouseCursorEvent = procedure(const ASender: TObject; const ALineCharPos: TTextEditorTextPosition;
    var ACursor: TCursor) of object;
  TTextEditorPaintEvent = procedure(const ASender: TObject; const ACanvas: TCanvas) of object;
  TTextEditorReplaceChangeEvent = procedure(const AEvent: TTextEditorReplaceChanges) of object;
  TTextEditorReplaceSearchCountEvent = procedure(const ASender: TObject; const ACount: Integer;
    const APageIndex: Integer) of object;
  TTextEditorReplaceTextEvent = procedure(const ASender: TObject; const ASearch, AReplace: string;
    const ALine, AColumn: Integer; const ADeleteLine: Boolean; var AAction: TTextEditorReplaceAction) of object;
  TTextEditorScrollEvent = procedure(const ASender: TObject; const AScrollBar: TScrollBarKind) of object;
  TTextEditorSearchChangeEvent = procedure(const AEvent: TTextEditorSearchChanges) of object;

  TTextEditorTimer = class(TTimer)
  public
    procedure Restart;
  end;

  function SearchEngineAsText(const ASearchEngine: TTextEditorSearchEngine): string;
  function TextAsSearchEngine(const ASearchEngineName: string): TTextEditorSearchEngine;
  function CompletionProposalItemFound(const AItems: TTextEditorCompletionProposalItems; const AItem: TTextEditorCompletionProposalItem): Boolean;

implementation

function SearchEngineAsText(const ASearchEngine: TTextEditorSearchEngine): string;
begin
  case ASearchEngine of
    seNormal:
      Result := TSearchEngine.Normal;
    seExtended:
      Result := TSearchEngine.Extended;
    seRegularExpression:
      Result := TSearchEngine.RegularExpression;
    seWildcard:
      Result := TSearchEngine.Wildcard;
  end;
end;

function TextAsSearchEngine(const ASearchEngineName: string): TTextEditorSearchEngine;
begin
  if ASearchEngineName = TSearchEngine.Extended then
    Result := seExtended
  else
  if ASearchEngineName = TSearchEngine.RegularExpression then
    Result := seRegularExpression
  else
  if ASearchEngineName = TSearchEngine.Wildcard then
    Result := seWildcard
  else
    Result := seNormal
end;

function CompletionProposalItemFound(const AItems: TTextEditorCompletionProposalItems; const AItem: TTextEditorCompletionProposalItem): Boolean;
var
  LIndex: Integer;
  LItem: TTextEditorCompletionProposalItem;
begin
  Result := True;

  for LIndex := 0 to AItems.Count - 1 do
  begin
    LItem := AItems[LIndex];
    if LItem.Keyword.Trim = AItem.Keyword.Trim then
      if LItem.Description.Trim = AItem.Description.Trim then
        Exit;
  end;

  Result := False;
end;

{ TTextEditorCodeFoldingHintIndicatorPadding }

class procedure TTextEditorCodeFoldingHintIndicatorPadding.InitDefaults(Margins: TMargins);
begin
  with Margins do
  begin
    Left := 0;
    Right := 0;
    Top := 1;
    Bottom := 1;
  end;
end;

{ TTextEditorTimer }

procedure TTextEditorTimer.Restart;
begin
  Enabled := False;
  Enabled := True; //FI:W508 Variable is assigned twice successively
end;

end.
