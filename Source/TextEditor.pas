{$WARN WIDECHAR_REDUCED OFF} // CharInSet is slow in loops
unit TextEditor;

interface

uses
  Winapi.Messages, Winapi.Windows, System.Classes, System.Contnrs, System.Math, System.SysUtils, System.UITypes,
  Vcl.Controls, Vcl.DBCtrls, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, Data.DB,
  TextEditor.ActiveLine, TextEditor.Caret, TextEditor.CodeFolding, TextEditor.CodeFolding.Hint.Form,
  TextEditor.CodeFolding.Ranges, TextEditor.CodeFolding.Regions, TextEditor.Colors, TextEditor.CompletionProposal,
  TextEditor.CompletionProposal.PopupWindow, TextEditor.CompletionProposal.Snippets, TextEditor.Consts,
  TextEditor.Glyph, TextEditor.Highlighter, TextEditor.Highlighter.Attributes, TextEditor.InternalImage,
  TextEditor.KeyboardHandler, TextEditor.KeyCommands, TextEditor.LeftMargin, TextEditor.Lines,
  TextEditor.MacroRecorder, TextEditor.Marks, TextEditor.MatchingPairs, TextEditor.Minimap, TextEditor.PaintHelper,
  TextEditor.Replace, TextEditor.RightMargin, TextEditor.Ruler, TextEditor.Scroll, TextEditor.Search,
  TextEditor.Search.Base, TextEditor.Selection, TextEditor.SkipRegions, TextEditor.SpecialChars, TextEditor.SyncEdit,
  TextEditor.Tabs, TextEditor.Types, TextEditor.Undo, TextEditor.Undo.List, TextEditor.UnknownChars, TextEditor.Utils,
  TextEditor.WordWrap
{$IFDEF ALPHASKINS}, acSBUtils, sCommonData{$ENDIF}
{$IFDEF TEXT_EDITOR_SPELL_CHECK}, TextEditor.SpellCheck{$ENDIF};

const
  TEXTEDITOR_DEFAULT_OPTIONS = [eoAutoIndent, eoDragDropEditing, eoShowNullCharacters, eoShowControlCharacters];

type
  TCustomTextEditor = class(TCustomControl)
  private type
    TTextEditorCaretHelper = record
      ShowAlways: Boolean;
      Offset: TPoint;
    end;

    TTextEditorCodeFoldings = record
      AllRanges: TTextEditorAllCodeFoldingRanges;
      DelayTimer: TTextEditorTimer;
      Exists: Boolean;
      HintForm: TTextEditorCodeFoldingHintForm;
      RangeFromLine: array of TTextEditorCodeFoldingRange;
      RangeToLine: array of TTextEditorCodeFoldingRange;
      Rescan: Boolean;
      TreeLine: array of Boolean;
    end;

    TTextEditorEvents = record
      OnAfterBookmarkPlaced: TTextEditorBookmarkPlacedEvent;
      OnAfterDeleteBookmark: TTextEditorBookmarkDeletedEvent;
      OnAfterDeleteMark: TNotifyEvent;
      OnAfterLinePaint: TTextEditorLinePaintEvent;
      OnAfterMarkPanelPaint: TTextEditorMarkPanelPaintEvent;
      OnAfterMarkPlaced: TNotifyEvent;
      OnBeforeDeleteMark: TTextEditorMarkEvent;
      OnBeforeMarkPanelPaint: TTextEditorMarkPanelPaintEvent;
      OnBeforeMarkPlaced: TTextEditorMarkEvent;
      OnCaretChanged: TTextEditorCaretChangedEvent;
      OnChainLinesChanged: TNotifyEvent;
      OnChainLinesChanging: TNotifyEvent;
      OnChainLinesCleared: TNotifyEvent;
      OnChainLinesDeleted: TStringListChangeEvent;
      OnChainLinesInserted: TStringListChangeEvent;
      OnChainLinesPutted: TStringListChangeEvent;
      OnChainRedoAdded: TNotifyEvent;
      OnChainUndoAdded: TNotifyEvent;
      OnChange: TNotifyEvent;
      OnCommandProcessed: TTextEditorProcessCommandEvent;
      OnCompletionProposalCanceled: TNotifyEvent;
      OnCompletionProposalExecute: TOnCompletionProposalExecute;
      OnCreateHighlighterStream: TTextEditorCreateHighlighterStreamEvent;
      OnCustomLineColors: TTextEditorCustomLineColorsEvent;
      OnCustomTokenAttribute: TTextEditorCustomTokenAttributeEvent;
      OnDropFiles: TTextEditorDropFilesEvent;
      OnKeyPressW: TTextEditorKeyPressWEvent;
      OnLeftMarginClick: TLeftMarginClickEvent;
      OnLinesDeleted: TStringListChangeEvent;
      OnLinesInserted: TStringListChangeEvent;
      OnLinesPutted: TStringListChangeEvent;
      OnLoadingProgress: TNotifyEvent;
      OnMarkPanelLinePaint: TTextEditorMarkPanelLinePaintEvent;
      OnModified: TNotifyEvent;
      OnPaint: TTextEditorPaintEvent;
      OnProcessCommand: TTextEditorProcessCommandEvent;
      OnProcessUserCommand: TTextEditorProcessCommandEvent;
      OnReplaceSearchCount: TTextEditorReplaceSearchCountEvent;
      OnReplaceText: TTextEditorReplaceTextEvent;
      OnRightMarginMouseUp: TNotifyEvent;
      OnScroll: TTextEditorScrollEvent;
      OnSearchEngineChanged: TNotifyEvent;
      OnSelectionChanged: TNotifyEvent;
    end;

    TTextEditorFile = record
      DateTime: TDateTime;
      FullName: string;
      HotName: string;
      Loaded: Boolean;
      Name: string;
      Path: string;
    end;

    TTextEditorItalic = record
      Bitmap: TBitmap;
      Offset: Byte;
      OffsetCache: array [AnsiChar] of Byte;
    end;

    TTextEditorLast = record
      ViewPosition: TTextEditorViewPosition;
      DblClick: Cardinal;
      DeletedLine: Integer;
      Key: Word;
      LineNumberCount: Integer;
      MouseMovePoint: TPoint;
      Row: Integer;
      ShiftState: TShiftState;
      SortOrder: TTextEditorSortOrder;
      TopLine: Integer;
    end;

    TTextEditorLineNumbers = record
      Cache: array of Integer;
      Count: Integer;
      ResetCache: Boolean;
      TopLine: Integer;
      VisibleCount: Integer;
    end;

    TTextEditorMatchingPairMatch = record
      CloseToken: string;
      CloseTokenPos: TTextEditorTextPosition;
      OpenToken: string;
      OpenTokenPos: TTextEditorTextPosition;
      TokenAttribute: TTextEditorHighlighterAttribute;
    end;

    TTextEditorMatchingPairTokenMatch = record
      Position: TTextEditorTextPosition;
      Token: string;
    end;

    TTextEditorMatchingPair = record
      MatchStack: array of TTextEditorMatchingPairTokenMatch;
      OpenDuplicate, CloseDuplicate: array of Integer;
      Current: TTextEditorMatchingTokenResult;
      CurrentMatch: TTextEditorMatchingPairMatch;
    end;

    TTextEditorMinimapShadowHelper = record
      AlphaArray: TTextEditorArrayOfSingle;
      AlphaByteArray: PByteArray;
      AlphaByteArrayLength: Integer;
      Bitmap: Vcl.Graphics.TBitmap;
      BlendFunction: TBlendFunction;
    end;

    TTextEditorMinimapIndicatorHelper = record
      Bitmap: Vcl.Graphics.TBitmap;
      BlendFunction: TBlendFunction;
    end;

    TTextEditorMinimapHelper = record
      BufferBitmap: Vcl.Graphics.TBitmap;
      ClickOffsetY: Integer;
      Indicator: TTextEditorMinimapIndicatorHelper;
      Left: Integer;
      Right: Integer;
      Shadow: TTextEditorMinimapShadowHelper;
    end;

    TTextEditorMouse = record
      Down: TPoint;
      DownInText: Boolean;
      IsScrolling: Boolean;
      OverURI: Boolean;
      ScrollCursors: array [0 .. 7] of HCursor;
      ScrollingPoint: TPoint;
      ScrollTimer: TTextEditorTimer;
      WheelAccumulator: Integer;
    end;

    TTextEditorMultiCaret = record
      Carets: TList;
      Draw: Boolean;
      Position: TTextEditorViewPosition;
      Timer: TTextEditorTimer;
    end;

    TTextEditorOriginal = record
      FontSize: Integer;
      LeftMarginFontSize: Integer;
      Lines: TTextEditorLines;
      RedoList: TTextEditorUndoList;
      UndoList: TTextEditorUndoList;
    end;

    TTextEditorPosition = record
      Text: TTextEditorTextPosition;
      BeginSelection: TTextEditorTextPosition;
      CompletionProposal: TTextEditorViewPosition;
      EndSelection: TTextEditorTextPosition;
    end;

    TTextEditorScrollShadowHelper = record
      AlphaArray: TTextEditorArrayOfSingle;
      AlphaByteArray: PByteArray;
      AlphaByteArrayLength: Integer;
      Bitmap: Vcl.Graphics.TBitmap;
      BlendFunction: TBlendFunction;
    end;

    TTextEditorScrollHelper = record
      Delta: TPoint;
      HorizontalPosition: Integer;
      IsScrolling: Boolean;
      PageWidth: Integer;
      Shadow: TTextEditorScrollShadowHelper;
      Timer: TTextEditorTimer;
{$IFDEF ALPHASKINS}
      Wnd: TacScrollWnd;
{$ENDIF}
    end;

    TTextEditorState = record
      AltDown: Boolean;
      CanChangeSize: Boolean;
      ExecutingSelectionCommand: Boolean;
      Flags: TTextEditorStateFlags;
      Modified: Boolean;
      ReadOnly: Boolean;
      ReplaceLock: Boolean;
      UndoRedo: Boolean;
      UnknownChars: TTextEditorUnknownChars;
      URIOpener: Boolean;
      WantReturns: Boolean;
    end;

    TTextEditorSystemMetrics = record
      HorizontalDrag: Integer;
      VerticalDrag: Integer;
      VerticalScroll: Integer;
    end;

    TTextEditorToggleCase = record
      Cycle: TTextEditorCase;
      Text: string;
    end;

    TTextEditorTokenHelper = record
      Background: TColor;
      Border: TColor;
      CharsBefore: Integer;
      EmptySpace: TTextEditorEmptySpace;
      ExpandedCharsBefore: Integer;
      FontStyle: TFontStyles;
      Foreground: TColor;
      IsItalic: Boolean;
      Length: Integer;
      RightToLeftToken: Boolean;
      Text: string;
      Underline: TTextEditorUnderline;
      UnderlineColor: TColor;
    end;

    TTextEditorWordWrapLine = record
      ViewLength: array of Integer;
      Length: array of Integer;
      Width: array of Integer;
    end;

  strict private
    FActiveLine: TTextEditorActiveLine;
    FBookmarkList: TTextEditorMarkList;
    FBorderStyle: TBorderStyle;
{$IFDEF ALPHASKINS}
    FBoundLabel: TsBoundLabel;
{$ENDIF}
    FCaret: TTextEditorCaret;
    FCaretHelper: TTextEditorCaretHelper;
    FChainedEditor: TCustomTextEditor;
    FCodeFolding: TTextEditorCodeFolding;
    FCodeFoldings: TTextEditorCodeFoldings;
    FColors: TTextEditorColors;
    FCompareLineNumberOffsetCache: array of Integer;
    FCompletionProposal: TTextEditorCompletionProposal;
    FCompletionProposalPopupWindow: TTextEditorCompletionProposalPopupWindow;
    FCompletionProposalTimer: TTextEditorTimer;
    FDoubleClickTime: Cardinal;
    FEvents: TTextEditorEvents;
    FFile: TTextEditorFile;
    FHighlightedFoldRange: TTextEditorCodeFoldingRange;
    FHighlighter: TTextEditorHighlighter;
    FHookedCommandHandlers: TObjectList;
    FImagesBookmark: TTextEditorInternalImage;
    FItalic: TTextEditorItalic;
    FKeyboardHandler: TTextEditorKeyboardHandler;
    FKeyCommands: TTextEditorKeyCommands;
    FLast: TTextEditorLast;
    FLeftMargin: TTextEditorLeftMargin;
    FLeftMarginCharWidth: Integer;
    FLeftMarginWidth: Integer;
    FLineNumbers: TTextEditorLineNumbers;
    FLines: TTextEditorLines;
    FLineSpacing: Integer;
    FMacroRecorder: TTextEditorMacroRecorder;
    FMarkList: TTextEditorMarkList;
    FMatchingPair: TTextEditorMatchingPair;
    FMatchingPairs: TTextEditorMatchingPairs;
    FMinimap: TTextEditorMinimap;
    FMinimapHelper: TTextEditorMinimapHelper;
    FMouse: TTextEditorMouse;
    FMultiCaret: TTextEditorMultiCaret;
    FOptions: TTextEditorOptions;
    FOriginal: TTextEditorOriginal;
    FPaintHelper: TTextEditorPaintHelper;
    FPaintLock: Integer;
    FPosition: TTextEditorPosition;
    FRedoList: TTextEditorUndoList;
    FReplace: TTextEditorReplace;
    FRightMargin: TTextEditorRightMargin;
    FRightMarginMovePosition: Integer;
    FRuler: TTextEditorRuler;
    FRulerMovePosition: Integer;
    FSaveScrollOption: Boolean;
    FSaveSelectionMode: TTextEditorSelectionMode;
    FScroll: TTextEditorScroll;
    FScrollHelper: TTextEditorScrollHelper;
    FSearch: TTextEditorSearch;
    FSearchEngine: TTextEditorSearchBase;
    FSearchString: string;
    FSelection: TTextEditorSelection;
{$IFDEF ALPHASKINS}
    FSkinData: TsScrollWndData;
{$ENDIF}
    FOvertypeMode: TTextEditorOvertypeMode;
    FSpecialChars: TTextEditorSpecialChars;
{$IFDEF TEXT_EDITOR_SPELL_CHECK}
    FSpellCheck: TTextEditorSpellCheck;
{$ENDIF}
    FState: TTextEditorState;
    FSyncEdit: TTextEditorSyncEdit;
    FSystemMetrics: TTextEditorSystemMetrics;
    FTabs: TTextEditorTabs;
    FToggleCase: TTextEditorToggleCase;
    FUndo: TTextEditorUndo;
    FUndoList: TTextEditorUndoList;
    FUnknownChars: TTextEditorUnknownChars;
    FViewPosition: TTextEditorViewPosition;
    FWordWrap: TTextEditorWordWrap;
    FWordWrapLine: TTextEditorWordWrapLine;
    function AddSnippet(const AExecuteWith: TTextEditorSnippetExecuteWith; const ATextPosition: TTextEditorTextPosition): Boolean;
    function AllWhiteUpToTextPosition(const ATextPosition: TTextEditorTextPosition; const ALine: string; const ALength: Integer): Boolean;
    function AreTextPositionsEqual(const ATextPosition1: TTextEditorTextPosition; const ATextPosition2: TTextEditorTextPosition): Boolean; inline;
    function CharIndexToTextPosition(const ACharIndex: Integer): TTextEditorTextPosition; overload;
    function CharIndexToTextPosition(const ACharIndex: Integer; const ATextBeginPosition: TTextEditorTextPosition; const ACountLineBreak: Boolean = True): TTextEditorTextPosition; overload;
    function CodeFoldingCollapsableFoldRangeForLine(const ALine: Integer): TTextEditorCodeFoldingRange;
    function CodeFoldingFoldRangeForLineTo(const ALine: Integer): TTextEditorCodeFoldingRange;
    function CodeFoldingLineInsideRange(const ALine: Integer): TTextEditorCodeFoldingRange;
    function CodeFoldingRangeForLine(const ALine: Integer): TTextEditorCodeFoldingRange;
    function CodeFoldingTreeEndForLine(const ALine: Integer): Boolean;
    function CodeFoldingTreeLineForLine(const ALine: Integer): Boolean;
    function DoOnCodeFoldingHintClick(const APoint: TPoint): Boolean;
    function FindHookedCommandEvent(const AHookedCommandEvent: TTextEditorHookedCommandEvent): Integer;
    function FreeMinimapBitmaps: Boolean;
    function GetCanPaste: Boolean;
    function GetCanRedo: Boolean;
    function GetCanUndo: Boolean;
    function GetCaretIndex: Integer;
    function GetCharAtCursor: Char;
    function GetCharAtTextPosition(const ATextPosition: TTextEditorTextPosition): Char;
    function GetCharWidth: Integer;
    function GetEndOfLine(const ALine: PChar): PChar;
    function GetFoldingOnCurrentLine: Boolean;
    function GetHighlighterAttributeAtRowColumn(const ATextPosition: TTextEditorTextPosition; var AToken: string; var ATokenType: TTextEditorRangeType; var AStart: Integer; var AHighlighterAttribute: TTextEditorHighlighterAttribute): Boolean;
    function GetHookedCommandHandlersCount: Integer;
    function GetHorizontalScrollMax: Integer;
    function GetLastWordFromCursor: string;
    function GetLeadingExpandedLength(const AText: string; const ABorder: Integer = 0): Integer;
    function GetLeftMarginWidth: Integer;
    function GetLineHeight: Integer; inline;
    function GetLineIndentLevel(const ALine: Integer): Integer; inline;
    function GetMarkBackgroundColor(const ALine: Integer): TColor;
    function GetMatchingToken(const AViewPosition: TTextEditorViewPosition; var AMatch: TTextEditorMatchingPairMatch): TTextEditorMatchingTokenResult;
    function GetMouseScrollCursorIndex: Integer;
    function GetMouseScrollCursors(const AIndex: Integer): HCursor;
    function GetPreviousCharAtCursor: Char;
    function GetRowCountFromPixel(const AY: Integer): Integer;
    function GetScrollPageWidth: Integer;
    function GetSearchResultCount: Integer;
    function GetSelectedRow(const AY: Integer): Integer;
    function GetSelectedText: string;
    function GetSelectionAvailable: Boolean;
    function GetSelectionBeginPosition: TTextEditorTextPosition;
    function GetSelectionEndPosition: TTextEditorTextPosition;
    function GetSelectionLength: Integer;
    function GetSelectionLineCount: Integer;
    function GetSelectionStart: Integer;
    function GetText: string;
    function GetTextBetween(const ATextBeginPosition: TTextEditorTextPosition; const ATextEndPosition: TTextEditorTextPosition): string;
    function GetTextPosition: TTextEditorTextPosition;
    function GetTokenCharCount(const AToken: string; const ACharsBefore: Integer): Integer; inline;
    function GetTokenWidth(const AToken: string; const ALength: Integer; const ACharsBefore: Integer; const AMinimap: Boolean = False; const ARTLReading: Boolean = False): Integer;
    function GetViewLineNumber(const AViewLineNumber: Integer): Integer;
    function GetViewTextLineNumber(const AViewLineNumber: Integer): Integer;
    function GetVisibleChars(const ARow: Integer; const ALineText: string = ''): Integer;
    function IsCommentAtCaretPosition: Boolean;
    function IsKeywordAtCaretPosition(const APOpenKeyWord: PBoolean = nil): Boolean;
    function IsKeywordAtCaretPositionOrAfter(const ATextPosition: TTextEditorTextPosition): Boolean;
    function IsMultiEditCaretFound(const ALine: Integer): Boolean;
    function IsTextPositionInSearchBlock(const ATextPosition: TTextEditorTextPosition): Boolean;
    function IsWordSelected: Boolean;
    function LeftSpaceCount(const ALine: string; const AWantTabs: Boolean = False): Integer;
    function NextWordPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition; overload;
    function NextWordPosition: TTextEditorTextPosition; overload;
    function PreviousWordPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition; overload;
    function PreviousWordPosition: TTextEditorTextPosition; overload;
    function ScanHighlighterRangesFrom(const AIndex: Integer): Integer;
    function ShortCutPressed: Boolean;
    function StringWordEnd(const ALine: string; var AStart: Integer): Integer;
    function StringWordStart(const ALine: string; var AStart: Integer): Integer;
    function TextPositionToCharIndex(const ATextPosition: TTextEditorTextPosition): Integer;
    function WordWrapWidth: Integer;
    procedure ActiveLineChanged(ASender: TObject);
    procedure AddHighlighterKeywords(const AItems: TTextEditorCompletionProposalItems; const AAddDescription: Boolean = False);
    procedure AddSnippets(const AItems: TTextEditorCompletionProposalItems; const AAddDescription: Boolean = False);
    procedure AfterSetText(ASender: TObject);
    procedure AssignSearchEngine(const AEngine: TTextEditorSearchEngine);
    procedure BeforeSetText(ASender: TObject);
    procedure BookmarkListChange(ASender: TObject);
    procedure CaretChanged(ASender: TObject);
    procedure CheckIfAtMatchingKeywords;
    procedure ClearCodeFolding;
    procedure ClearMinimapBuffer;
    procedure CodeFoldingCollapse(const AFoldRange: TTextEditorCodeFoldingRange);
    procedure CodeFoldingLinesDeleted(const AFirstLine: Integer; const ACount: Integer);
    procedure CodeFoldingOnChange(const AEvent: TTextEditorCodeFoldingChanges);
    procedure CodeFoldingResetCaches;
    procedure ColorsOnChange(const AEvent: TTextEditorColorChanges);
    procedure CompletionProposalTimerHandler(ASender: TObject);
    procedure ComputeScroll(const APoint: TPoint);
    procedure CreateBookmarkImages;
    procedure CreateLineNumbersCache(const AReset: Boolean = False);
    procedure CreateShadowBitmap(const AClipRect: TRect; const ABitmap: Vcl.Graphics.TBitmap; const AShadowAlphaArray: TTextEditorArrayOfSingle; const AShadowAlphaByteArray: PByteArray);
    procedure DeflateMinimapAndSearchMapRect(var ARect: TRect);
    procedure DeleteChar;
    procedure DeleteLine;
{$IFDEF TEXT_EDITOR_SPELL_CHECK}
    procedure DeleteSpellCheckItems(const AFromLine: Integer; const AToLine: Integer);
{$ENDIF}
    procedure DeleteText(const ACommand: TTextEditorCommand);
    procedure DoBackspace;
    procedure DoBlockComment;
    procedure DoChar(const AChar: Char);
    procedure DoCutToClipboard;
    procedure DoEditorBottom(const ACommand: TTextEditorCommand);
    procedure DoEditorTop(const ACommand: TTextEditorCommand);
    procedure DoEndKey(const ASelection: Boolean);
    procedure DoExecuteCompletionProposal(const ATriggered: Boolean = False);
    procedure DoHomeKey(const ASelection: Boolean);
    procedure DoImeStr(const AData: Pointer);
    procedure DoInsertText(const AText: string);
    procedure DoLeftMarginAutoSize;
    procedure DoLineBreak(const AAddSpaceBuffer: Boolean = True);
    procedure DoLineComment;
    procedure DoOnBookmarkPopup(Sender: TObject);
    procedure DoPageLeftOrRight(const ACommand: TTextEditorCommand);
    procedure DoPageTopOrBottom(const ACommand: TTextEditorCommand);
    procedure DoPageUpOrDown(const ACommand: TTextEditorCommand);
    procedure DoPasteFromClipboard;
    procedure DoScroll(const ACommand: TTextEditorCommand);
    procedure DoSelectedText(const APasteMode: TTextEditorSelectionMode; const AValue: PChar; const AAddToUndoList: Boolean; const ATextPosition: TTextEditorTextPosition; const AChangeBlockNumber: Integer = 0); overload;
    procedure DoSelectedText(const AValue: string); overload;
    procedure DoSetBookmark(const ACommand: TTextEditorCommand; const AData: Pointer);
    procedure DoShiftTabKey;
    procedure DoSyncEdit;
    procedure DoTabKey;
    procedure DoToggleBookmark(const AImageIndex: Integer = -1);
    procedure DoToggleMark;
    procedure DoToggleSelectedCase(const ACommand: TTextEditorCommand);
    procedure DoTrimTrailingSpaces(const ATextLine: Integer; const AForceTrim: Boolean = False);
    procedure DoWordLeft(const ACommand: TTextEditorCommand);
    procedure DoWordRight(const ACommand: TTextEditorCommand);
    procedure DragMinimap(const AY: Integer);
    procedure FindWords(const AWord: string; const AList: TList; const ACaseSensitive: Boolean; const AWholeWordsOnly: Boolean);
    procedure FontChanged(ASender: TObject);
    procedure FreeMultiCarets;
    procedure FreeScrollShadowBitmap;
    procedure GetCommentAtTextPosition(const ATextPosition: TTextEditorTextPosition; var AComment: string);
    procedure GetMinimapLeftRight(var ALeft: Integer; var ARight: Integer);
    procedure InitCodeFolding;
    procedure InitializeScrollShadow;
    procedure InsertLine; overload;
    procedure InsertSnippet(const AItem: TTextEditorCompletionProposalSnippetItem; const ATextPosition: TTextEditorTextPosition);
    procedure LinesChanging(ASender: TObject);
    procedure MinimapChanged(ASender: TObject);
    procedure MouseScrollTimerHandler(ASender: TObject);
    procedure MoveCaretAndSelection(const ABeforeTextPosition, AAfterTextPosition: TTextEditorTextPosition; const ASelectionCommand: Boolean);
    procedure MoveCaretHorizontally(const X: Integer; const ASelectionCommand: Boolean);
    procedure MoveCaretVertically(const Y: Integer; const ASelectionCommand: Boolean);
    procedure MoveLineDown;
    procedure MoveLineUp;
{$IFDEF TEXT_EDITOR_SPELL_CHECK}
    procedure MoveSpellCheckItems(const ALine: Integer; const ACount: Integer);
{$ENDIF}
    procedure MultiCaretTimerHandler(ASender: TObject);
    procedure OnCodeFoldingDelayTimer(ASender: TObject);
    procedure OpenLink(const AURI: string);
    procedure RemoveDuplicateMultiCarets;
    procedure ReplaceChanged(const AEvent: TTextEditorReplaceChanges);
    procedure RightMarginChanged(ASender: TObject);
    procedure RulerChanged(ASender: TObject);
{$IFDEF TEXT_EDITOR_SPELL_CHECK}
    procedure ScanSpellCheck(const AFromLine: Integer; const AToLine: Integer);
{$ENDIF}
    procedure ScrollingChanged(ASender: TObject);
    procedure ScrollTimerHandler(ASender: TObject);
    procedure SearchAll(const ASearchText: string = '');
    procedure SearchChanged(const AEvent: TTextEditorSearchChanges);
    procedure SelectionChanged(ASender: TObject);
    procedure SetActiveLine(const AValue: TTextEditorActiveLine);
    procedure SetBorderStyle(const AValue: TBorderStyle);
    procedure SetCaretIndex(const AValue: Integer);
    procedure SetCodeFolding(const AValue: TTextEditorCodeFolding);
    procedure SetCompletionProposalPopupWindowLocation;
    procedure SetDefaultKeyCommands;
    procedure SetFullFilename(const AName: string);
    procedure SetHorizontalScrollPosition(const AValue: Integer);
    procedure SetKeyCommands(const AValue: TTextEditorKeyCommands);
    procedure SetLeftMargin(const AValue: TTextEditorLeftMargin);
    procedure SetLine(const ALine: Integer; const ALineText: string); inline;
    procedure SetLines(const AValue: TTextEditorLines);
    procedure SetModified(const AValue: Boolean);
    procedure SetMouseScrollCursors(const AIndex: Integer; const AValue: HCursor);
    procedure SetOppositeColors;
    procedure SetOptions(const AValue: TTextEditorOptions);
    procedure SetOvertypeMode(const AValue: TTextEditorOvertypeMode);
    procedure SetRightMargin(const AValue: TTextEditorRightMargin);
    procedure SetScroll(const AValue: TTextEditorScroll);
    procedure SetSearch(const AValue: TTextEditorSearch);
    procedure SetSelectedText(const AValue: string);
    procedure SetSelectedWord;
    procedure SetSelection(const AValue: TTextEditorSelection);
    procedure SetSelectionBeginPosition(const AValue: TTextEditorTextPosition);
    procedure SetSelectionEndPosition(const AValue: TTextEditorTextPosition);
    procedure SetSelectionLength(const AValue: Integer);
    procedure SetSelectionStart(const AValue: Integer);
    procedure SetSpecialChars(const AValue: TTextEditorSpecialChars);
    procedure SetSyncEdit(const AValue: TTextEditorSyncEdit);
    procedure SetTabs(const AValue: TTextEditorTabs);
    procedure SetText(const AValue: string);
    procedure SetTextBetween(const ATextBeginPosition: TTextEditorTextPosition; const ATextEndPosition: TTextEditorTextPosition; const AValue: string);
    procedure SetTextCaretX(const AValue: Integer);
    procedure SetTextCaretY(const AValue: Integer);
    procedure SetTextPosition(const AValue: TTextEditorTextPosition);
    procedure SetTopLine(const AValue: Integer);
    procedure SetUndo(const AValue: TTextEditorUndo);
    procedure SetUnknownChars(const AValue: TTextEditorUnknownChars);
    procedure SetWordBlock(const ATextPosition: TTextEditorTextPosition);
    procedure SetWordWrap(const AValue: TTextEditorWordWrap);
    procedure SpecialCharsChanged(ASender: TObject);
    procedure SplitTextIntoWords(const AItems: TTextEditorCompletionProposalItems; const AAddDescription: Boolean = False);
    procedure SwapInt(var ALeft: Integer; var ARight: Integer);
    procedure SyncEditChanged(ASender: TObject);
    procedure TabsChanged(ASender: TObject);
    procedure UndoRedoAdded(ASender: TObject);
    procedure UnknownCharsChanged(ASender: TObject);
    procedure UpdateFoldingRanges(const ACurrentLine: Integer; const ALineCount: Integer); overload;
    procedure UpdateFoldingRanges(const AFoldRanges: TTextEditorCodeFoldingRanges; const ALineCount: Integer); overload;
    procedure UpdateScrollBars;
{$IFDEF TEXT_EDITOR_SPELL_CHECK}
    procedure UpdateSpellCheckItems(const ALine: Integer; const ACount: Integer);
{$ENDIF}
    procedure UpdateWordWrap(const AValue: Boolean);
    procedure WMCaptureChanged(var AMessage: TMessage); message WM_CAPTURECHANGED;
    procedure WMChar(var AMessage: TWMChar); message WM_CHAR;
    procedure WMClear(var AMessage: TMessage); message WM_CLEAR;
    procedure WMCopy(var AMessage: TMessage); message WM_COPY;
    procedure WMCut(var AMessage: TMessage); message WM_CUT;
    procedure WMDropFiles(var AMessage: TMessage); message WM_DROPFILES;
    procedure WMEraseBkgnd(var AMessage: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMGetDlgCode(var AMessage: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMGetText(var AMessage: TWMGetText); message WM_GETTEXT;
    procedure WMGetTextLength(var AMessage: TWMGetTextLength); message WM_GETTEXTLENGTH;
    procedure WMHScroll(var AMessage: TWMScroll); message WM_HSCROLL;
    procedure WMIMEChar(var AMessage: TMessage); message WM_IME_CHAR;
    procedure WMIMEComposition(var AMessage: TMessage); message WM_IME_COMPOSITION;
    procedure WMIMENotify(var AMessage: TMessage); message WM_IME_NOTIFY;
    procedure WMKillFocus(var AMessage: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMPaint(var AMessage: TWMPaint); message WM_PAINT;
    procedure WMPaste(var AMessage: TMessage); message WM_PASTE;
    procedure WMSetCursor(var AMessage: TWMSetCursor); message WM_SETCURSOR;
    procedure WMSetFocus(var AMessage: TWMSetFocus); message WM_SETFOCUS;
    procedure WMSetText(var AMessage: TWMSetText); message WM_SETTEXT;
    procedure WMSize(var AMessage: TWMSize); message WM_SIZE;
    procedure WMUndo(var AMessage: TMessage); message WM_UNDO;
    procedure WMVScroll(var AMessage: TWMScroll); message WM_VSCROLL;
    procedure WordWrapChanged(ASender: TObject);
  protected
    function DoMouseWheel(AShift: TShiftState; AWheelDelta: Integer; AMousePos: TPoint): Boolean; override;
    function DoOnReplaceText(const ASearch, AReplace: string; const ALine, AColumn: Integer; const ADeleteLine: Boolean): TTextEditorReplaceAction;
    function DoSearchMatchNotFoundWraparoundDialog: Boolean; virtual;
    function GetReadOnly: Boolean; virtual;
    function PixelAndRowToViewPosition(const X, ARow: Integer; const ALineText: string = ''): TTextEditorViewPosition;
    function PixelsToViewPosition(const X, Y: Integer): TTextEditorViewPosition;
    procedure ChainLinesChanged(ASender: TObject);
    procedure ChainLinesChanging(ASender: TObject);
    procedure ChainLinesCleared(ASender: TObject);
    procedure ChainLinesDeleted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
    procedure ChainLinesInserted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
    procedure ChainLinesPutted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
    procedure ChainUndoRedoAdded(ASender: TObject);
    procedure CodeFoldingExpand(const AFoldRange: TTextEditorCodeFoldingRange);
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure CreateWnd; override;
    procedure DblClick; override;
    procedure DestroyWnd; override;
    procedure DoBlockIndent;
    procedure DoBlockUnindent;
    procedure DoChange; virtual;
    procedure DoCopyToClipboard(const AText: string);
    procedure DoKeyPressW(var AMessage: TWMKey);
    procedure DoOnCommandProcessed(ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);
    procedure DoOnLeftMarginClick(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer);
    procedure DoOnMinimapClick(const Y: Integer);
    procedure DoOnPaint;
    procedure DoOnProcessCommand(var ACommand: TTextEditorCommand; var AChar: Char; const AData: Pointer); virtual;
    procedure DoOnSearchMapClick(const Y: Integer);
    procedure DoSearchStringNotFoundDialog; virtual;
    procedure DoTripleClick;
    procedure DragCanceled; override;
    procedure DragOver(ASource: TObject; X, Y: Integer; AState: TDragState; var AAccept: Boolean); override;
    procedure FreeCompletionProposalPopupWindow;
    procedure FreeHintForm;
    procedure HideCaret;
    procedure KeyDown(var AKey: Word; AShift: TShiftState); override;
    procedure KeyPressW(var AKey: Char);
    procedure KeyUp(var AKey: Word; AShift: TShiftState); override;
    procedure LinesBeforeDeleted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
    procedure LinesBeforeInserted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
    procedure LinesBeforePutted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
    procedure LinesChanged(ASender: TObject);
    procedure LinesCleared(ASender: TObject);
    procedure LinesDeleted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
    procedure LinesHookChanged;
    procedure LinesInserted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
    procedure LinesPutted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
    procedure Loaded; override;
    procedure MarkListChange(ASender: TObject);
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(AShift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer); override;
    procedure NotifyHookedCommandHandlers(const AAfterProcessing: Boolean; var ACommand: TTextEditorCommand; var AChar: Char; const AData: Pointer);
    procedure Paint; override;
    procedure PaintCaret;
    procedure PaintCaretBlock(const AViewPosition: TTextEditorViewPosition);
    procedure PaintCodeFolding(const AClipRect: TRect; const AFirstRow, ALastRow: Integer);
    procedure PaintCodeFoldingCollapsedLine(const AFoldRange: TTextEditorCodeFoldingRange; const ALineRect: TRect);
    procedure PaintCodeFoldingCollapseMark(const AFoldRange: TTextEditorCodeFoldingRange; const ACurrentLineText: string; const ATokenPosition, ATokenLength, ALine: Integer; const ALineRect: TRect);
    procedure PaintCodeFoldingLine(const AClipRect: TRect; const ALine: Integer);
    procedure PaintGuides(const AFirstRow, ALastRow: Integer; const AMinimap: Boolean);
    procedure PaintLeftMargin(const AClipRect: TRect; const AFirstLine, ALastTextLine, ALastLine: Integer);
    procedure PaintMinimapIndicator(const AClipRect: TRect);
    procedure PaintMinimapShadow(const ACanvas: TCanvas; const AClipRect: TRect);
    procedure PaintMouseScrollPoint;
    procedure PaintProgress(Sender: TObject);
    procedure PaintProgressBar;
    procedure PaintRightMargin(const AClipRect: TRect);
    procedure PaintRightMarginMove;
    procedure PaintRuler;
    procedure PaintRulerMove;
    procedure PaintScrollShadow(const ACanvas: TCanvas; const AClipRect: TRect);
    procedure PaintSearchMap(const AClipRect: TRect);
    procedure PaintSpecialCharsEndOfLine(const ALine: Integer; const ALineEndRect: TRect; const ALineEndInsideSelection: Boolean);
    procedure PaintSyncItems;
    procedure PaintTextLines(const AClipRect: TRect; const AFirstLine, ALastLine: Integer; const AMinimap: Boolean);
    procedure RedoItem;
    procedure ResetCaret;
    procedure ScanCodeFoldingRanges; virtual;
    procedure ScanMatchingPair;
    procedure SetAlwaysShowCaret(const AValue: Boolean);
    procedure SetName(const AValue: TComponentName); override;
    procedure SetReadOnly(const AValue: Boolean); virtual;
    procedure SetViewPosition(const AValue: TTextEditorViewPosition);
    procedure SetWantReturns(const AValue: Boolean);
    procedure ShowCaret;
    procedure UndoItem;
    procedure UpdateMouseCursor;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CanFocus: Boolean; override;
    function CaretInView: Boolean;
    function CharacterCount(const ASelected: Boolean = False): Integer;
    function CreateHighlighterStream(const AName: string): TStream; virtual;
    function DeleteBookmark(const ALine: Integer; const AIndex: Integer): Boolean; overload;
    function FindNext(const AHandleNotFound: Boolean = True): Boolean;
    function FindPrevious(const AHandleNotFound: Boolean = True): Boolean;
    function GetBookmark(const AIndex: Integer; var ATextPosition: TTextEditorTextPosition): Boolean;
    function GetCompareLineNumberOffsetCache(const ALine: Integer): Integer;
    function GetNextBreakPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition;
    function GetPreviousBreakPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition;
    function GetTextPositionOfMouse(out ATextPosition: TTextEditorTextPosition): Boolean;
    function GetWordAtPixels(const X, Y: Integer): string;
    function IsCommentChar(const AChar: Char): Boolean;
    function IsTextPositionInSelection(const ATextPosition: TTextEditorTextPosition): Boolean;
    function IsWordBreakChar(const AChar: Char): Boolean; inline;
    function PixelsToTextPosition(const X, Y: Integer): TTextEditorTextPosition;
    function ReplaceSelectedText(const AReplaceText: string; const ASearchText: string; const ADeleteLine: Boolean): Boolean;
    function ReplaceText(const ASearchText: string; const AReplaceText: string; const APageIndex: Integer = -1): Integer;
    function SearchStatus: string;
    function TextToViewPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorViewPosition;
    function TranslateKeyCode(const ACode: Word; const AShift: TShiftState): TTextEditorCommand;
    function ViewPositionToPixels(const AViewPosition: TTextEditorViewPosition; const ALineText: string = ''): TPoint;
    function ViewToTextPosition(const AViewPosition: TTextEditorViewPosition): TTextEditorTextPosition;
    function WordAtCursor: string;
    function WordAtMouse(const ASelect: Boolean = False): string;
    function WordAtTextPosition(const ATextPosition: TTextEditorTextPosition; const ASelect: Boolean = False; const AAllowedBrealChars: TSysCharSet = []): string;
    function WordCount(const ASelected: Boolean = False): Integer;
    function WordEnd(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition; overload;
    function WordEnd: TTextEditorTextPosition; overload;
    function WordStart(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition; overload;
    function WordStart: TTextEditorTextPosition; overload;
    procedure AddCaret(const AViewPosition: TTextEditorViewPosition);
    procedure AddKeyCommand(const ACommand: TTextEditorCommand; const AShift: TShiftState; const AKey: Word; const ASecondaryShift: TShiftState = []; const ASecondaryKey: Word = 0);
    procedure AddKeyDownHandler(AHandler: TKeyEvent);
    procedure AddKeyPressHandler(AHandler: TTextEditorKeyPressWEvent);
    procedure AddKeyUpHandler(AHandler: TKeyEvent);
    procedure AddMouseCursorHandler(AHandler: TTextEditorMouseCursorEvent);
    procedure AddMouseDownHandler(AHandler: TMouseEvent);
    procedure AddMouseUpHandler(AHandler: TMouseEvent);
    procedure AddMultipleCarets(const AViewPosition: TTextEditorViewPosition);
    procedure AfterConstruction; override;
    procedure BeginUndoBlock;
    procedure BeginUpdate;
    procedure ChainEditor(const AEditor: TCustomTextEditor);
    procedure ChangeObjectScale(const AMultiplier, ADivider: Integer);
    procedure Clear;
    procedure ClearBookmarks;
    procedure ClearMarks;
    procedure ClearMatchingPair;
    procedure ClearSelection;
    procedure ClearUndo;
    procedure CollapseAll(const AFromLineNumber: Integer = -1; const AToLineNumber: Integer = -1);
    procedure CollapseAllByLevel(const AFromLevel: Integer; const AToLevel: Integer);
    procedure CommandProcessor(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);
    procedure CopyToClipboard(const AWithLineNumbers: Boolean = False);
    procedure CutToClipboard;
{$IFDEF BASENCODING}
    procedure Decode(const ACoding: TTextEditorCoding);
{$ENDIF}
    procedure DecPaintLock;
    procedure DeleteBookmark(ABookmark: TTextEditorMark); overload;
    procedure DeleteComments;
    procedure DeleteLines(const ALineNumber: Integer; const ACount: Integer);
    procedure DeleteMark(AMark: TTextEditorMark);
    procedure DeleteSelection;
    procedure DeleteWhitespace;
    procedure DoRedo;
{$IFDEF TEXT_EDITOR_SPELL_CHECK}
    procedure DoSpellCheck;
{$ENDIF}
    procedure DoUndo;
    procedure DragDrop(ASource: TObject; X, Y: Integer); override;
{$IFDEF BASENCODING}
    procedure Encode(const ACoding: TTextEditorCoding);
{$ENDIF}
    procedure EndUndoBlock;
    procedure EndUpdate;
    procedure EnsureCursorPositionVisible(const AForceToMiddle: Boolean = False; const AEvenIfVisible: Boolean = False);
    procedure ExecuteCommand(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer); virtual;
    procedure ExpandAll(const AFromLineNumber: Integer = -1; const AToLineNumber: Integer = -1);
    procedure ExpandAllByLevel(const AFromLevel: Integer; const AToLevel: Integer);
    procedure ExportToHTML(const AFilename: string; const ACharSet: string = ''; const AEncoding: System.SysUtils.TEncoding = nil); overload;
    procedure ExportToHTML(const AStream: TStream; const ACharSet: string = ''; const AEncoding: System.SysUtils.TEncoding = nil); overload;
    procedure FillRect(const ARect: TRect);
    procedure FindAll;
    procedure FoldingCollapseLine;
    procedure FoldingExpandLine;
    procedure FoldingGoToNext;
    procedure FoldingGoToPrevious;
    procedure GoToBookmark(const AIndex: Integer);
    procedure GoToLine(const ALine: Integer);
    procedure GoToLineAndCenter(const ALine: Integer; const AChar: Integer = 1);
    procedure GoToNextBookmark;
    procedure GoToOriginalLineAndCenter(const ALine: Integer; const AChar: Integer; const AText: string = '');
    procedure GoToPreviousBookmark;
    procedure HookEditorLines(const ALines: TTextEditorLines; const AUndo, ARedo: TTextEditorUndoList);
    procedure IncPaintLock;
    procedure InsertBlock(const ABlockBeginPosition, ABlockEndPosition: TTextEditorTextPosition; const AChangeStr: PChar; const AAddToUndoList: Boolean);
    procedure InsertLine(const ALineNumber: Integer; const AValue: string); overload;
    procedure InsertText(const AText: string);
    procedure LeftMarginChanged(ASender: TObject);
    procedure LoadFromFile(const AFilename: string; const AEncoding: System.SysUtils.TEncoding = nil);
    procedure LoadFromStream(const AStream: TStream; const AEncoding: System.SysUtils.TEncoding = nil);
    procedure LockUndo;
    procedure MoveCaretToBeginning;
    procedure MoveCaretToEnd;
    procedure MoveSelection(const ADirection: TTextEditorMoveDirection);
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
    procedure PasteFromClipboard;
    procedure RegisterCommandHandler(const AHookedCommandEvent: TTextEditorHookedCommandEvent; const AHandlerData: Pointer);
    procedure RemoveChainedEditor;
    procedure RemoveKeyDownHandler(AHandler: TKeyEvent);
    procedure RemoveKeyPressHandler(AHandler: TTextEditorKeyPressWEvent);
    procedure RemoveKeyUpHandler(AHandler: TKeyEvent);
    procedure RemoveMouseCursorHandler(AHandler: TTextEditorMouseCursorEvent);
    procedure RemoveMouseDownHandler(AHandler: TMouseEvent);
    procedure RemoveMouseUpHandler(AHandler: TMouseEvent);
    procedure ReplaceLine(const ALineNumber: Integer; const AValue: string; const AFlags: TTextEditorStringFlags);
    procedure RescanCodeFoldingRanges;
    procedure SaveToFile(const AFilename: string; const AEncoding: System.SysUtils.TEncoding = nil);
    procedure SaveToStream(const AStream: TStream; const AEncoding: System.SysUtils.TEncoding = nil);
    procedure SelectAll;
    procedure ChangeScale(AMultiplier, ADivider: Integer; AIsDpiChange: Boolean); override;
    procedure SetBookmark(const AIndex: Integer; const ATextPosition: TTextEditorTextPosition; const AImageIndex: Integer = -1);
    procedure SetCaretAndSelection(const ATextPosition, ABlockBeginPosition, ABlockEndPosition: TTextEditorTextPosition);
    procedure SetFocus; override;
    procedure SetMark(const AIndex: Integer; const ATextPosition: TTextEditorTextPosition; const AImageIndex: Integer; const AColor: TColor = TColors.SysNone);
    procedure SetOption(const AOption: TTextEditorOption; const AEnabled: Boolean);
    procedure SetSelectedTextEmpty(const AChangeString: string = '');
    procedure SizeOrFontChanged(const AFontChanged: Boolean = True);
    procedure Sort(const ASortOrder: TTextEditorSortOrder = soAsc; const ACaseSensitive: Boolean = False);
{$IFDEF TEXT_EDITOR_SPELL_CHECK}
    procedure SpellCheckFindNextError;
    procedure SpellCheckFindPreviousError;
{$ENDIF}
    procedure ToggleBookmark(const AIndex: Integer = -1);
    procedure ToggleSelectedCase(const ACase: TTextEditorCase = cNone);
    procedure Trim(const ATrimStyle: TTextEditorTrimStyle);
    procedure TrimBeginning;
    procedure TrimEnd;
    procedure TrimTrailingSpaces;
    procedure UnhookEditorLines;
    procedure UnlockUndo;
    procedure UnregisterCommandHandler(AHookedCommandEvent: TTextEditorHookedCommandEvent);
    procedure UpdateCaret;
    procedure WndProc(var AMessage: TMessage); override;
    property ActiveLine: TTextEditorActiveLine read FActiveLine write SetActiveLine;
    property AllCodeFoldingRanges: TTextEditorAllCodeFoldingRanges read FCodeFoldings.AllRanges;
    property AlwaysShowCaret: Boolean read FCaretHelper.ShowAlways write SetAlwaysShowCaret;
    property Bookmarks: TTextEditorMarkList read FBookmarkList;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsSingle;
{$IFDEF ALPHASKINS}
    property BoundLabel: TsBoundLabel read FBoundLabel write FBoundLabel;
{$ENDIF}
    property CanChangeSize: Boolean read FState.CanChangeSize write FState.CanChangeSize default True;
    property CanPaste: Boolean read GetCanPaste;
    property CanRedo: Boolean read GetCanRedo;
    property CanUndo: Boolean read GetCanUndo;
    property Canvas;
    property Caret: TTextEditorCaret read FCaret write FCaret;
    property CaretIndex: Integer read GetCaretIndex write SetCaretIndex;
    property CharAtCursor: Char read GetCharAtCursor;
    property CharWidth: Integer read GetCharWidth;
    property CodeFolding: TTextEditorCodeFolding read FCodeFolding write SetCodeFolding;
    property Colors: TTextEditorColors read FColors write FColors;
    property CompletionProposal: TTextEditorCompletionProposal read FCompletionProposal write FCompletionProposal;
    property Cursor default crIBeam;
    property FileDateTime: TDateTime read FFile.DateTime write FFile.DateTime;
    property Filename: string read FFile.Name write FFile.Name;
    property FilePath: string read FFile.Path write FFile.Path;
    property FoldingExists: Boolean read FCodeFoldings.Exists;
    property FoldingOnCurrentLine: Boolean read GetFoldingOnCurrentLine;
    property Font;
    property FullFilename: string read FFile.FullName write SetFullFilename;
    property Highlighter: TTextEditorHighlighter read FHighlighter;
    property HorizontalScrollPosition: Integer read FScrollHelper.HorizontalPosition write SetHorizontalScrollPosition;
    property HotFilename: string read FFile.HotName write FFile.HotName;
    property IsScrolling: Boolean read FScrollHelper.IsScrolling;
    property KeyCommands: TTextEditorKeyCommands read FKeyCommands write SetKeyCommands stored False;
    property LeftMargin: TTextEditorLeftMargin read FLeftMargin write SetLeftMargin;
    property LineHeight: Integer read GetLineHeight;
    property LineNumbersCount: Integer read FLineNumbers.Count;
    property Lines: TTextEditorLines read FLines write SetLines;
    property LineSpacing: Integer read FLineSpacing write FLineSpacing;
    property MacroRecorder: TTextEditorMacroRecorder read FMacroRecorder write FMacroRecorder;
    property Marks: TTextEditorMarkList read FMarkList;
    property MatchingPairs: TTextEditorMatchingPairs read FMatchingPairs write FMatchingPairs;
    property Minimap: TTextEditorMinimap read FMinimap write FMinimap;
    property Modified: Boolean read FState.Modified write SetModified;
    property MouseScrollCursors[const AIndex: Integer]: HCursor read GetMouseScrollCursors write SetMouseScrollCursors;
    property OnAfterBookmarkPlaced: TTextEditorBookmarkPlacedEvent read FEvents.OnAfterBookmarkPlaced write FEvents.OnAfterBookmarkPlaced;
    property OnAfterDeleteBookmark: TTextEditorBookmarkDeletedEvent read FEvents.OnAfterDeleteBookmark write FEvents.OnAfterDeleteBookmark;
    property OnAfterDeleteMark: TNotifyEvent read FEvents.OnAfterDeleteMark write FEvents.OnAfterDeleteMark;
    property OnAfterLinePaint: TTextEditorLinePaintEvent read FEvents.OnAfterLinePaint write FEvents.OnAfterLinePaint;
    property OnAfterMarkPanelPaint: TTextEditorMarkPanelPaintEvent read FEvents.OnAfterMarkPanelPaint write FEvents.OnAfterMarkPanelPaint;
    property OnAfterMarkPlaced: TNotifyEvent read FEvents.OnAfterMarkPlaced write FEvents.OnAfterMarkPlaced;
    property OnBeforeDeleteMark: TTextEditorMarkEvent read FEvents.OnBeforeDeleteMark write FEvents.OnBeforeDeleteMark;
    property OnBeforeMarkPanelPaint: TTextEditorMarkPanelPaintEvent read FEvents.OnBeforeMarkPanelPaint write FEvents.OnBeforeMarkPanelPaint;
    property OnBeforeMarkPlaced: TTextEditorMarkEvent read FEvents.OnBeforeMarkPlaced write FEvents.OnBeforeMarkPlaced;
    property OnCaretChanged: TTextEditorCaretChangedEvent read FEvents.OnCaretChanged write FEvents.OnCaretChanged;
    property OnChange: TNotifyEvent read FEvents.OnChange write FEvents.OnChange;
    property OnCommandProcessed: TTextEditorProcessCommandEvent read FEvents.OnCommandProcessed write FEvents.OnCommandProcessed;
    property OnCompletionProposalCanceled: TNotifyEvent read FEvents.OnCompletionProposalCanceled write FEvents.OnCompletionProposalCanceled;
    property OnCompletionProposalExecute: TOnCompletionProposalExecute read FEvents.OnCompletionProposalExecute write FEvents.OnCompletionProposalExecute;
    property OnCreateHighlighterStream: TTextEditorCreateHighlighterStreamEvent read FEvents.OnCreateHighlighterStream write FEvents.OnCreateHighlighterStream;
    property OnCustomLineColors: TTextEditorCustomLineColorsEvent read FEvents.OnCustomLineColors write FEvents.OnCustomLineColors;
    property OnCustomTokenAttribute: TTextEditorCustomTokenAttributeEvent read FEvents.OnCustomTokenAttribute write FEvents.OnCustomTokenAttribute;
    property OnDropFiles: TTextEditorDropFilesEvent read FEvents.OnDropFiles write FEvents.OnDropFiles;
    property OnKeyDown;
    property OnKeyPress: TTextEditorKeyPressWEvent read FEvents.OnKeyPressW write FEvents.OnKeyPressW;
    property OnLeftMarginClick: TLeftMarginClickEvent read FEvents.OnLeftMarginClick write FEvents.OnLeftMarginClick;
    property OnLinesDeleted: TStringListChangeEvent read FEvents.OnLinesDeleted write FEvents.OnLinesDeleted;
    property OnLinesInserted: TStringListChangeEvent read FEvents.OnLinesInserted write FEvents.OnLinesInserted;
    property OnLinesPutted: TStringListChangeEvent read FEvents.OnLinesPutted write FEvents.OnLinesPutted;
    property OnLoadingProgress: TNotifyEvent read FEvents.OnLoadingProgress write FEvents.OnLoadingProgress;
    property OnMarkPanelLinePaint: TTextEditorMarkPanelLinePaintEvent read FEvents.OnMarkPanelLinePaint write FEvents.OnMarkPanelLinePaint;
    property OnModified: TNotifyEvent read FEvents.OnModified write FEvents.OnModified;
    property OnPaint: TTextEditorPaintEvent read FEvents.OnPaint write FEvents.OnPaint;
    property OnProcessCommand: TTextEditorProcessCommandEvent read FEvents.OnProcessCommand write FEvents.OnProcessCommand;
    property OnProcessUserCommand: TTextEditorProcessCommandEvent read FEvents.OnProcessUserCommand write FEvents.OnProcessUserCommand;
    property OnReplaceSearchCount: TTextEditorReplaceSearchCountEvent read FEvents.OnReplaceSearchCount write FEvents.OnReplaceSearchCount;
    property OnReplaceText: TTextEditorReplaceTextEvent read FEvents.OnReplaceText write FEvents.OnReplaceText;
    property OnRightMarginMouseUp: TNotifyEvent read FEvents.OnRightMarginMouseUp write FEvents.OnRightMarginMouseUp;
    property OnScroll: TTextEditorScrollEvent read FEvents.OnScroll write FEvents.OnScroll;
    property OnSearchEngineChanged: TNotifyEvent read FEvents.OnSearchEngineChanged write FEvents.OnSearchEngineChanged;
    property OnSelectionChanged: TNotifyEvent read FEvents.OnSelectionChanged write FEvents.OnSelectionChanged;
    property Options: TTextEditorOptions read FOptions write SetOptions default TEXTEDITOR_DEFAULT_OPTIONS;
    property OriginalFontSize: Integer read FOriginal.FontSize write FOriginal.FontSize;
    property OriginalLeftMarginFontSize: Integer read FOriginal.LeftMarginFontSize write FOriginal.LeftMarginFontSize;
    property PaintLock: Integer read FPaintLock write FPaintLock;
    property ParentColor default False;
    property ParentFont default False;
    property PreviousCharAtCursor: Char read GetPreviousCharAtCursor;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property RedoList: TTextEditorUndoList read FRedoList;
    property Replace: TTextEditorReplace read FReplace write FReplace;
    property RightMargin: TTextEditorRightMargin read FRightMargin write SetRightMargin;
    property Ruler: TTextEditorRuler read FRuler write FRuler;
    property Scroll: TTextEditorScroll read FScroll write SetScroll;
    property Search: TTextEditorSearch read FSearch write SetSearch;
    property SearchResultCount: Integer read GetSearchResultCount;
    property SearchString: string read FSearchString write FSearchString;
    property SelectedText: string read GetSelectedText write SetSelectedText;
    property Selection: TTextEditorSelection read FSelection write SetSelection;
    property SelectionAvailable: Boolean read GetSelectionAvailable;
    property SelectionBeginPosition: TTextEditorTextPosition read GetSelectionBeginPosition write SetSelectionBeginPosition;
    property SelectionEndPosition: TTextEditorTextPosition read GetSelectionEndPosition write SetSelectionEndPosition;
    property SelectionLength: Integer read GetSelectionLength write SetSelectionLength;
    property SelectionLineCount: Integer read GetSelectionLineCount;
    property SelectionStart: Integer read GetSelectionStart write SetSelectionStart;
{$IFDEF ALPHASKINS}
    property SkinData: TsScrollWndData read FSkinData write FSkinData;
{$ENDIF}
    property SpecialChars: TTextEditorSpecialChars read FSpecialChars write SetSpecialChars;
{$IFDEF TEXT_EDITOR_SPELL_CHECK}
    property SpellCheck: TTextEditorSpellCheck read FSpellCheck write FSpellCheck;
{$ENDIF}
    property SyncEdit: TTextEditorSyncEdit read FSyncEdit write SetSyncEdit;
    property Tabs: TTextEditorTabs read FTabs write SetTabs;
    property TabStop default True;
    property Text: string read GetText write SetText;
    property TextBetween[const ATextBeginPosition: TTextEditorTextPosition; const ATextEndPosition: TTextEditorTextPosition]: string read GetTextBetween write SetTextBetween;
    property TextPosition: TTextEditorTextPosition read GetTextPosition write SetTextPosition;
    property OvertypeMode: TTextEditorOvertypeMode read FOvertypeMode write SetOvertypeMode default omInsert;
    property TopLine: Integer read FLineNumbers.TopLine write SetTopLine;
    property Undo: TTextEditorUndo read FUndo write SetUndo;
    property UndoList: TTextEditorUndoList read FUndoList;
    property UnknownChars: TTextEditorUnknownChars read FUnknownChars write SetUnknownChars;
    property URIOpener: Boolean read FState.URIOpener write FState.URIOpener;
    property ViewPosition: TTextEditorViewPosition read FViewPosition write SetViewPosition;
    property VisibleLineCount: Integer read FLineNumbers.VisibleCount;
    property WantReturns: Boolean read FState.WantReturns write SetWantReturns default True;
    property WordWrap: TTextEditorWordWrap read FWordWrap write SetWordWrap;
  end;

  TTextEditor = class(TCustomTextEditor)
  published
    property ActiveLine;
    property Align;
    property Anchors;
    property BorderStyle;
    property BorderWidth;
{$IFDEF ALPHASKINS}
    property BoundLabel;
{$ENDIF}
    property Caret;
    property CodeFolding;
    property CompletionProposal;
    property Constraints;
    property Ctl3D;
    property Enabled;
    property Font;
    property Height;
    property ImeMode;
    property ImeName;
    property KeyCommands;
    property LeftMargin;
    property LineSpacing;
    property MatchingPairs;
    property Minimap;
    property Name;
    property OnAfterBookmarkPlaced;
    property OnAfterDeleteBookmark;
    property OnAfterDeleteMark;
    property OnAfterLinePaint;
    property OnAfterMarkPanelPaint;
    property OnAfterMarkPlaced;
    property OnBeforeDeleteMark;
    property OnBeforeMarkPanelPaint;
    property OnBeforeMarkPlaced;
    property OnCaretChanged;
    property OnChange;
    property OnClick;
    property OnCommandProcessed;
    property OnCompletionProposalCanceled;
    property OnCompletionProposalExecute;
    property OnCreateHighlighterStream;
    property OnCustomLineColors;
    property OnCustomTokenAttribute;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDropFiles;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnLeftMarginClick;
    property OnLoadingProgress;
    property OnMarkPanelLinePaint;
    property OnModified;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnPaint;
    property OnProcessCommand;
    property OnProcessUserCommand;
    property OnReplaceSearchCount;
    property OnReplaceText;
    property OnRightMarginMouseUp;
    property OnScroll;
    property OnSearchEngineChanged;
    property OnSelectionChanged;
    property OnStartDock;
    property OnStartDrag;
    property Options;
    property OvertypeMode;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property Replace;
    property RightMargin;
    property Ruler;
    property Scroll;
    property Search;
    property Selection;
    property ShowHint;
{$IFDEF ALPHASKINS}
    property SkinData;
{$ENDIF}
    property SpecialChars;
{$IFDEF TEXT_EDITOR_SPELL_CHECK}
    property SpellCheck;
{$ENDIF}
    property SyncEdit;
    property TabOrder;
    property Tabs;
    property TabStop;
    property Tag;
    property Undo;
    property UnknownChars;
    property Visible;
    property WantReturns;
    property Width;
    property WordWrap;
  end;

  TCustomDBTextEditor = class(TCustomTextEditor)
  strict private
    FBeginEdit: Boolean;
    FDataLink: TFieldDataLink;
    FEditing: Boolean;
    FLoadData: TNotifyEvent;
    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;
    procedure CMEnter(var AMessage: TCMEnter); message CM_ENTER;
    procedure CMExit(var AMessage: TCMExit); message CM_EXIT;
    procedure CMGetDataLink(var AMessage: TMessage); message CM_GETDATALINK;
    procedure DataChange(Sender: TObject);
    procedure EditingChange(Sender: TObject);
    procedure SetDataField(const AValue: string);
    procedure SetDataSource(const AValue: TDataSource);
    procedure SetEditing(const AValue: Boolean);
    procedure UpdateData(Sender: TObject);
  protected
    function GetReadOnly: Boolean; override;
    procedure DoChange; override;
    procedure Loaded; override;
    procedure SetReadOnly(const AValue: Boolean); override;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property Field: TField read GetField;
    property OnLoadData: TNotifyEvent read FLoadData write FLoadData;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DragDrop(ASource: TObject; X, Y: Integer); override;
    procedure ExecuteCommand(const ACommand: TTextEditorCommand; const AChar: Char; const AData: pointer); override;
    procedure LoadMemo;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  end;

  TDBTextEditor = class(TCustomDBTextEditor)
  published
    property ActiveLine;
    property Align;
    property Anchors;
    property BorderStyle;
    property BorderWidth;
{$IFDEF ALPHASKINS}
    property BoundLabel;
{$ENDIF}
    property Caret;
    property CodeFolding;
    property CompletionProposal;
    property Constraints;
    property Ctl3D;
    property DataField;
    property DataSource;
    property Enabled;
    property Field;
    property Font;
    property Height;
    property ImeMode;
    property ImeName;
    property KeyCommands;
    property LeftMargin;
    property LineSpacing;
    property MatchingPairs;
    property Minimap;
    property Name;
    property OnAfterBookmarkPlaced;
    property OnAfterDeleteBookmark;
    property OnAfterDeleteMark;
    property OnAfterLinePaint;
    property OnAfterMarkPanelPaint;
    property OnAfterMarkPlaced;
    property OnBeforeDeleteMark;
    property OnBeforeMarkPanelPaint;
    property OnBeforeMarkPlaced;
    property OnCaretChanged;
    property OnChange;
    property OnClick;
    property OnCommandProcessed;
    property OnCompletionProposalCanceled;
    property OnCompletionProposalExecute;
    property OnCreateHighlighterStream;
    property OnCustomLineColors;
    property OnCustomTokenAttribute;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDropFiles;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnLeftMarginClick;
    property OnLoadData;
    property OnLoadingProgress;
    property OnMarkPanelLinePaint;
    property OnModified;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnPaint;
    property OnProcessCommand;
    property OnProcessUserCommand;
    property OnReplaceSearchCount;
    property OnReplaceText;
    property OnRightMarginMouseUp;
    property OnScroll;
    property OnSearchEngineChanged;
    property OnSelectionChanged;
    property OnStartDock;
    property OnStartDrag;
    property Options;
    property OvertypeMode;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property Replace;
    property RightMargin;
    property Ruler;
    property Scroll;
    property Search;
    property Selection;
    property ShowHint;
{$IFDEF ALPHASKINS}
    property SkinData;
{$ENDIF}
    property SpecialChars;
{$IFDEF TEXT_EDITOR_SPELL_CHECK}
    property SpellCheck;
{$ENDIF}
    property SyncEdit;
    property TabOrder;
    property Tabs;
    property TabStop;
    property Tag;
    property Undo;
    property UnknownChars;
    property Visible;
    property WantReturns;
    property Width;
    property WordWrap;
  end;

  ETextEditorBaseException = class(Exception);

implementation

{$R TextEditor.res}

uses
  Winapi.Imm, Winapi.ShellAPI, System.Character, System.RegularExpressions, System.StrUtils, System.Types, Vcl.ImgList,
  Vcl.Menus, TextEditor.Encoding, TextEditor.Export.HTML, TextEditor.Highlighter.Rules, TextEditor.Language,
  TextEditor.LeftMargin.Border, TextEditor.LeftMargin.LineNumbers, TextEditor.Scroll.Hint, TextEditor.Search.Map,
  TextEditor.Search.Normal, TextEditor.Search.RegularExpressions, TextEditor.Search.WildCard, TextEditor.Undo.Item
{$IFDEF VCL_STYLES}, TextEditor.StyleHooks{$ENDIF}
{$IFDEF ALPHASKINS}, acGlow, sConst, sMessages, sSkinManager, sStyleSimply, sVCLUtils{$ENDIF};

type
  TTextEditorAccessWinControl = class(TWinControl);

var
  GHintWindow: THintWindow;

function GetHintWindow: THintWindow;
begin
  if not Assigned(GHintWindow) then
  begin
    GHintWindow := THintWindow.Create(Application);
    GHintWindow.DoubleBuffered := True;
  end;

  Result := GHintWindow;
end;

{ TCustomEditor }

constructor TCustomTextEditor.Create(AOwner: TComponent);
var
  LIndex: Integer;
  LFont: TFont;
begin
{$IFDEF ALPHASKINS}
  FSkinData := TsScrollWndData.Create(Self, True);
  FSkinData.COC := COC_TsMemo;
{$ENDIF}

  inherited Create(AOwner);

  Height := 150;
  Width := 200;
  Cursor := crIBeam;
  Color := TColors.SysWindow;
  DoubleBuffered := False;
  ControlStyle := ControlStyle + [csOpaque, csSetCaption, csNeedsBorderPaint];
  FState.CanChangeSize := True;
  FFile.Loaded := False;

  FSystemMetrics.HorizontalDrag := GetSystemMetrics(SM_CXDRAG);
  FSystemMetrics.VerticalDrag := GetSystemMetrics(SM_CYDRAG);
  FSystemMetrics.VerticalScroll := GetSystemMetrics(SM_CYVSCROLL);

  FBorderStyle := bsSingle;
  FDoubleClickTime := GetDoubleClickTime;
  FLast.SortOrder := soDesc;
  FLineNumbers.ResetCache := True;
  FToggleCase.Text := '';
  FState.URIOpener := False;
  FState.ReplaceLock := False;
  FMultiCaret.Position.Row := -1;

  { Code folding }
  FCodeFoldings.AllRanges := TTextEditorAllCodeFoldingRanges.Create;
  FCodeFolding := TTextEditorCodeFolding.Create;
  FCodeFolding.OnChange := CodeFoldingOnChange;
  FCodeFoldings.DelayTimer := TTextEditorTimer.Create(Self);
  FCodeFoldings.DelayTimer.OnTimer := OnCodeFoldingDelayTimer;
  { Colors }
  FColors := TTextEditorColors.Create;
  FColors.OnChange := ColorsOnChange;
  { Matching pair }
  FMatchingPairs := TTextEditorMatchingPairs.Create;
  { Line spacing }
  FLineSpacing := 0;
  { Special chars }
  FSpecialChars := TTextEditorSpecialChars.Create;
  FSpecialChars.OnChange := SpecialCharsChanged;
  { Caret }
  FCaret := TTextEditorCaret.Create;
  FCaret.OnChange := CaretChanged;
  { Lines }
  FLines := TTextEditorLines.Create(Self);
  FLines.PaintProgress := PaintProgress;
  FOriginal.Lines := FLines;
  with FLines do
  begin
    OnBeforeSetText := BeforeSetText;
    OnAfterSetText := AfterSetText;
    OnChange := LinesChanged;
    OnChanging := LinesChanging;
    OnCleared := LinesCleared;
    OnDeleted := LinesDeleted;
    OnInserted := LinesInserted;
    OnPutted := LinesPutted;
    OnBeforePutted := LinesBeforePutted;
  end;
  { Unknown chars }
  FUnknownChars := TTextEditorUnknownChars.Create;
  FUnknownChars.OnChange := UnknownCharsChanged;
  { Font }
  LFont := TFont.Create;
  try
    LFont.Name := 'Courier New';
    LFont.Size := 9;
    Font.Assign(LFont);
    Font.OnChange := FontChanged;
    FPaintHelper := TTextEditorPaintHelper.Create([], LFont);
  finally
    LFont.Free;
  end;
  { Painting }
  FItalic.Bitmap := TBitmap.Create;
  FItalic.Offset := 0;
  ParentFont := False;
  ParentColor := False;
  { Undo & Redo }
  FState.UndoRedo := False;
  FUndo := TTextEditorUndo.Create;
  FUndoList := TTextEditorUndoList.Create;
  FUndoList.OnAddedUndo := UndoRedoAdded;
  FOriginal.UndoList := FUndoList;
  FRedoList := TTextEditorUndoList.Create;
  FRedoList.OnAddedUndo := UndoRedoAdded;
  FOriginal.RedoList := FRedoList;
  { Active line, selection }
  FSelection := TTextEditorSelection.Create;
  FSelection.OnChange := SelectionChanged;
  { Bookmarks }
  FBookmarkList := TTextEditorMarkList.Create(Self);
  FBookmarkList.OnChange := BookmarkListChange;
  { Marks }
  FMarkList := TTextEditorMarkList.Create(Self);
  FMarkList.OnChange := MarkListChange;
  { Right edge }
  FRightMargin := TTextEditorRightMargin.Create;
  FRightMargin.OnChange := RightMarginChanged;
  { Ruler }
  FRuler := TTextEditorRuler.Create;
  FRuler.OnChange := RulerChanged;
  { Tabs }
  TabStop := True;
  FTabs := TTextEditorTabs.Create;
  FTabs.OnChange := TabsChanged;
  { Text }
  FOvertypeMode := omInsert;
  FKeyboardHandler := TTextEditorKeyboardHandler.Create;
  FKeyCommands := TTextEditorKeyCommands.Create(Self);
  SetDefaultKeyCommands;
  FState.WantReturns := True;
  FScrollHelper.HorizontalPosition := 0;
  FLineNumbers.TopLine := 1;
  FViewPosition.Column := 1;
  FViewPosition.Row := 1;
  FPosition.BeginSelection.Char := 1;
  FPosition.BeginSelection.Line := 1;
  FPosition.EndSelection := FPosition.BeginSelection;
  FOptions := TEXTEDITOR_DEFAULT_OPTIONS;
  { Scroll }
  with FScrollHelper.Shadow.BlendFunction do
  begin
    BlendOp := AC_SRC_OVER;
    BlendFlags := 0;
    AlphaFormat := AC_SRC_ALPHA;
  end;
  FScrollHelper.Timer := TTextEditorTimer.Create(Self);
  FScrollHelper.Timer.Enabled := False;
  FScrollHelper.Timer.Interval := 100;
  FScrollHelper.Timer.OnTimer := ScrollTimerHandler;
  FMouse.ScrollTimer := TTextEditorTimer.Create(Self);
  FMouse.ScrollTimer.Enabled := False;
  FMouse.ScrollTimer.Interval := 100;
  FMouse.ScrollTimer.OnTimer := MouseScrollTimerHandler;
  { Completion proposal }
  FCompletionProposal := TTextEditorCompletionProposal.Create(Self);
  FCompletionProposalTimer := TTextEditorTimer.Create(Self);
  FCompletionProposalTimer.Enabled := False;
  FCompletionProposalTimer.OnTimer := CompletionProposalTimerHandler;
  { Search }
  FSearch := TTextEditorSearch.Create;
  FSearch.OnChange := SearchChanged;
  AssignSearchEngine(FSearch.Engine);
  FReplace := TTextEditorReplace.Create;
  FReplace.OnChange := ReplaceChanged;
  { Scroll }
  FScroll := TTextEditorScroll.Create;
  FScroll.OnChange := ScrollingChanged;
  InitializeScrollShadow;
  { Minimap }
  with FMinimapHelper.Indicator.BlendFunction do
  begin
    BlendOp := AC_SRC_OVER;
    BlendFlags := 0;
    AlphaFormat := 0;
  end;
  with FMinimapHelper.Shadow.BlendFunction do
  begin
    BlendOp := AC_SRC_OVER;
    BlendFlags := 0;
    AlphaFormat := AC_SRC_ALPHA;
  end;
  FMinimap := TTextEditorMinimap.Create;
  FMinimap.OnChange := MinimapChanged;
  { Active line }
  FActiveLine := TTextEditorActiveLine.Create;
  FActiveLine.OnChange := ActiveLineChanged;
  { Word wrap }
  FWordWrap := TTextEditorWordWrap.Create;
  FWordWrap.OnChange := WordWrapChanged;
  { Sync edit }
  FSyncEdit := TTextEditorSyncEdit.Create;
  FSyncEdit.OnChange := SyncEditChanged;
  { LeftMargin }
  FLeftMargin := TTextEditorLeftMargin.Create(Self);
  FLeftMargin.OnChange := LeftMarginChanged;
  FLeftMarginCharWidth := FPaintHelper.CharWidth;
  FLeftMarginWidth := GetLeftMarginWidth;
  { Update character constraints }
  FontChanged(nil);
  TabsChanged(nil);
  { Highlighter }
  FHighlighter := TTextEditorHighlighter.Create(Self);
  FHighlighter.Lines := FLines;
  { Mouse wheel scroll cursors }
  for LIndex := 0 to 7 do
    FMouse.ScrollCursors[LIndex] := LoadCursor(HInstance, PChar(TResourceBitmap.MouseMoveScroll + IntToStr(LIndex)));
{$IFDEF ALPHASKINS}
  FBoundLabel := TsBoundLabel.Create(Self, FSkinData);
{$ENDIF}
end;

destructor TCustomTextEditor.Destroy;
begin
{$IFDEF ALPHASKINS}
  if Assigned(FScrollHelper.Wnd) then
  begin
    FScrollHelper.Wnd.Free;
    FScrollHelper.Wnd := nil;
  end;

  if Assigned(FSkinData) then
  begin
    FSkinData.Free;
    FSkinData := nil;
  end;
{$ENDIF}
  if Assigned(FChainedEditor) then
    RemoveChainedEditor;
  ClearCodeFolding;
  FCodeFolding.Free;
  FCodeFolding := nil;
  FCodeFoldings.DelayTimer.Free;
  FCodeFoldings.DelayTimer := nil;
  FColors.Free;
  FColors := nil;
  FCodeFoldings.AllRanges.Free;
  FCodeFoldings.AllRanges := nil;
  FHighlighter.Free;
  FHighlighter := nil;
  FreeCompletionProposalPopupWindow;
  { Do not use FreeAndNil, it first nils and then frees causing problems with code accessing FHookedCommandHandlers
    while destruction }
  FHookedCommandHandlers.Free;
  FHookedCommandHandlers := nil;
  FBookmarkList.Free;
  FBookmarkList := nil;
  FMarkList.Free;
  FMarkList := nil;
  FKeyCommands.Free;
  FKeyCommands := nil;
  FKeyboardHandler.Free;
  FKeyboardHandler := nil;
  FSelection.Free;
  FSelection := nil;
  FOriginal.UndoList.Free;
  FOriginal.UndoList := nil;
  FOriginal.RedoList.Free;
  FOriginal.RedoList := nil;
  FLeftMargin.Free;
  FLeftMargin := nil; { Notification has a check }
  FMinimap.Free;
  FMinimap := nil;
  FRuler.Free;
  FRuler := nil;
  FWordWrap.Free;
  FWordWrap := nil;
  FPaintHelper.Free;
  FPaintHelper := nil;
  FImagesBookmark.Free;
  FImagesBookmark := nil;
  FOriginal.Lines.Free;
  FOriginal.Lines := nil;
  FreeScrollShadowBitmap;
  FreeMinimapBitmaps;
  FActiveLine.Free;
  FActiveLine := nil;
  FRightMargin.Free;
  FRightMargin := nil;
  FScroll.Free;
  FScroll := nil;
  FSearch.Free;
  FSearch := nil;
  FReplace.Free;
  FReplace := nil;
  FTabs.Free;
  FTabs := nil;
  FUndo.Free;
  FUndo := nil;
  FSpecialChars.Free;
  FSpecialChars := nil;
  FUnknownChars.Free;
  FUnknownChars := nil;
  FCaret.Free;
  FCaret := nil;
  FreeMultiCarets;
  FMatchingPairs.Free;
  FMatchingPairs := nil;
  FCompletionProposal.Free;
  FCompletionProposal := nil;
  FSyncEdit.Free;
  FSyncEdit := nil;
  FItalic.Bitmap.Free;
  FItalic.Bitmap := nil;
  if Assigned(FMinimapHelper.Shadow.AlphaByteArray) then
  begin
    FreeMem(FMinimapHelper.Shadow.AlphaByteArray);
    FMinimapHelper.Shadow.AlphaByteArray := nil;
  end;

  if Assigned(FScrollHelper.Shadow.AlphaByteArray) then
  begin
    FreeMem(FScrollHelper.Shadow.AlphaByteArray);
    FScrollHelper.Shadow.AlphaByteArray := nil;
  end;

  if Assigned(FSearchEngine) then
  begin
    FSearchEngine.Free;
    FSearchEngine := nil;
  end;

  if Assigned(FCodeFoldings.HintForm) then
  begin
    FCodeFoldings.HintForm.Free;
    FCodeFoldings.HintForm := nil;
  end;

  if Length(FWordWrapLine.Length) > 0 then
    SetLength(FWordWrapLine.Length, 0);

  if Length(FWordWrapLine.ViewLength) > 0 then
    SetLength(FWordWrapLine.ViewLength, 0);

  if Length(FWordWrapLine.Width) > 0 then
    SetLength(FWordWrapLine.Width, 0);
{$IFDEF ALPHASKINS}
  FreeAndNil(FBoundLabel);
{$ENDIF}
  inherited Destroy;
end;

{ Private declarations }

function TCustomTextEditor.AddSnippet(const AExecuteWith: TTextEditorSnippetExecuteWith; const ATextPosition: TTextEditorTextPosition): Boolean;
var
  LIndex: Integer;
  LTextPosition: TTextEditorTextPosition;
  LKeyword: string;
  LSnippetItem: TTextEditorCompletionProposalSnippetItem;
begin
  Result := False;

  if FCompletionProposal.Snippets.Items.Count = 0 then
    Exit;

  LTextPosition := ATextPosition;
  Dec(LTextPosition.Char);
  LKeyword := WordAtTextPosition(LTextPosition).Trim;

  if LKeyword = '' then
    Exit;

  for LIndex := 0 to FCompletionProposal.Snippets.Items.Count - 1 do
  begin
    LSnippetItem := FCompletionProposal.Snippets.Item[LIndex];
    if (LSnippetItem.ExecuteWith = AExecuteWith) and (LSnippetItem.Keyword.Trim = LKeyword) then
    begin
      InsertSnippet(LSnippetItem, LTextPosition);
      Result := True;
    end;
  end;
end;

procedure TCustomTextEditor.InsertSnippet(const AItem: TTextEditorCompletionProposalSnippetItem; const ATextPosition: TTextEditorTextPosition);
var
  LIndex: Integer;
  LStringList: TStringList;
  LText: string;
  LSnippetPosition, LSnippetSelectionBeginPosition, LSnippetSelectionEndPosition: TTextEditorTextPosition;
  LCharCount: Integer;
  LSpaces: string;
  LPLineText: PChar;
  LBeginChar: Integer;
  LLineText: string;
  LScrollPastEndOfLine: Boolean;

  function GetBeginChar(const ARow: Integer): Integer;
  begin
    if ARow = 1 then
      Result := SelectionBeginPosition.Char
    else
      Result := LCharCount + 1;
  end;

begin
  BeginUpdate;
  BeginUndoBlock;
  try
    WordAtTextPosition(ATextPosition, True);

    LStringList := TStringList.Create;
    LStringList.TrailingLineBreak := False;
    try
      LText := AItem.Snippet.Text;
      LText := StringReplace(LText, TSnippetReplaceTags.CurrentWord, WordAtCursor, [rfReplaceAll]);
      LText := StringReplace(LText, TSnippetReplaceTags.SelectedText, SelectedText, [rfReplaceAll]);
      LText := StringReplace(LText, TSnippetReplaceTags.Text, Text, [rfReplaceAll]);

      LStringList.Text := LText;

      LLineText := FLines[ATextPosition.Line];
      LCharCount := 0;
      LPLineText := PChar(LLineText);
      for LIndex := 0 to SelectionBeginPosition.Char - 1 do
      begin
        if LPLineText^ = TControlCharacters.Tab then
          Inc(LCharCount, Tabs.Width)
        else
          Inc(LCharCount);

        if LPLineText^ <> TControlCharacters.Null then
          Inc(LPLineText);
      end;
      Dec(LCharCount);

      if toTabsToSpaces in Tabs.Options then
        LSpaces := StringOfChar(TCharacters.Space, LCharCount)
      else
      begin
        LSpaces := StringOfChar(TControlCharacters.Tab, LCharCount div Tabs.Width);
        LSpaces := LSpaces + StringOfChar(TCharacters.Space, LCharCount mod Tabs.Width);
      end;

      for LIndex := 1 to LStringList.Count - 1 do
        LStringList[LIndex] := LSpaces + LStringList[LIndex];

      if AItem.Position.Active then
      begin
        LBeginChar := GetBeginChar(AItem.Position.Row);
        LSnippetPosition := GetPosition(LBeginChar + AItem.Position.Column - 1,
          SelectionBeginPosition.Line + AItem.Position.Row - 1);
      end;

      if AItem.Selection.Active then
      begin
        LBeginChar := GetBeginChar(AItem.Selection.FromRow);
        LSnippetSelectionBeginPosition := GetPosition(LBeginChar + AItem.Selection.FromColumn - 1,
          SelectionBeginPosition.Line + AItem.Selection.FromRow - 1);
        LBeginChar := GetBeginChar(AItem.Selection.ToRow);
        LSnippetSelectionEndPosition := GetPosition(LBeginChar + AItem.Selection.ToColumn - 1,
          SelectionBeginPosition.Line + AItem.Selection.ToRow - 1);
      end;

      SelectedText := LStringList.Text
    finally
      LStringList.Free;
    end;

    SetFocus;

    LScrollPastEndOfLine := not (soPastEndOfLine in FScroll.Options);
    if LScrollPastEndOfLine then
      FScroll.SetOption(soPastEndOfLine, True);

    EnsureCursorPositionVisible;

    if AItem.Position.Active then
      TextPosition := LSnippetPosition
    else
    if AItem.Selection.Active then
      TextPosition := LSnippetSelectionEndPosition
    else
      TextPosition := SelectionEndPosition;

    if AItem.Selection.Active then
    begin
      SelectionBeginPosition := LSnippetSelectionBeginPosition;
      SelectionEndPosition := LSnippetSelectionEndPosition;
    end
    else
    begin
      SelectionBeginPosition := TextPosition;
      SelectionEndPosition := SelectionBeginPosition;
    end;

    if LScrollPastEndOfLine then
      FScroll.SetOption(soPastEndOfLine, False);
  finally
    EndUndoBlock;
    EndUpdate;
  end;
end;

function TCustomTextEditor.AllWhiteUpToTextPosition(const ATextPosition: TTextEditorTextPosition; const ALine: string;
  const ALength: Integer): Boolean;
var
  LIndex: Integer;
begin
  if (ALength = 0) or (ATextPosition.Char = 1) then
    Exit(True);

  Result := False;

  LIndex := 1;
  while (LIndex <= ALength) and (LIndex < ATextPosition.Char) do
  begin
    if ALine[LIndex] > TCharacters.Space then
      Exit;
    Inc(LIndex);
  end;

  Result := True;
end;

function TCustomTextEditor.AreTextPositionsEqual(const ATextPosition1: TTextEditorTextPosition;
  const ATextPosition2: TTextEditorTextPosition): Boolean;
begin
  Result := (ATextPosition1.Line = ATextPosition2.Line) and (ATextPosition1.Char = ATextPosition2.Char);
end;

function TCustomTextEditor.CharIndexToTextPosition(const ACharIndex: Integer): TTextEditorTextPosition;
begin
  Result := CharIndexToTextPosition(ACharIndex, GetPosition(0, 0));
end;

function TCustomTextEditor.CharIndexToTextPosition(const ACharIndex: Integer;
  const ATextBeginPosition: TTextEditorTextPosition; const ACountLineBreak: Boolean = True): TTextEditorTextPosition;
var
  LIndex, LCharIndex, LBeginChar: Integer;
  LLineLength: Integer;
begin
  Result.Line := ATextBeginPosition.Line;
  LBeginChar := ATextBeginPosition.Char;
  LCharIndex := ACharIndex;
  for LIndex := ATextBeginPosition.Line to FLines.Count do
  begin
    LLineLength := Length(FLines.Items^[LIndex].TextLine) - LBeginChar;
    if ACountLineBreak then
      Inc(LLineLength, FLines.LineBreakLength(LIndex));

    if LCharIndex < LLineLength then
    begin
      Result.Char := LBeginChar + LCharIndex;
      Break;
    end
    else
    begin
      Inc(Result.Line);
      Dec(LCharIndex, LLineLength);
    end;

    LBeginChar := 0;
  end;
end;

function TCustomTextEditor.CodeFoldingCollapsableFoldRangeForLine(const ALine: Integer): TTextEditorCodeFoldingRange;
var
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  Result := nil;

  LCodeFoldingRange := CodeFoldingRangeForLine(ALine);
  if Assigned(LCodeFoldingRange) and LCodeFoldingRange.Collapsable then
    Result := LCodeFoldingRange;
end;

function TCustomTextEditor.CodeFoldingFoldRangeForLineTo(const ALine: Integer): TTextEditorCodeFoldingRange;
var
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  Result := nil;

  if (ALine > 0) and (ALine < Length(FCodeFoldings.RangeToLine)) then
  begin
    LCodeFoldingRange := FCodeFoldings.RangeToLine[ALine];
    if Assigned(LCodeFoldingRange) then
      if (LCodeFoldingRange.ToLine = ALine) and not LCodeFoldingRange.ParentCollapsed then
        Result := LCodeFoldingRange;
  end;
end;

function TCustomTextEditor.CodeFoldingLineInsideRange(const ALine: Integer): TTextEditorCodeFoldingRange;
var
  LLength: Integer;
  LLine: Integer;
begin
  Result := nil;

  LLine := ALine;
  LLength := Length(FCodeFoldings.RangeFromLine) - 1;
  if LLine > LLength then
    LLine := LLength;
  while (LLine > 0) and not Assigned(FCodeFoldings.RangeFromLine[LLine]) do
    Dec(LLine);
  if (LLine > 0) and Assigned(FCodeFoldings.RangeFromLine[LLine]) then
    Result := FCodeFoldings.RangeFromLine[LLine]
end;

function TCustomTextEditor.CodeFoldingRangeForLine(const ALine: Integer): TTextEditorCodeFoldingRange;
begin
  Result := nil;
  if (ALine > 0) and (ALine < Length(FCodeFoldings.RangeFromLine)) then
    Result := FCodeFoldings.RangeFromLine[ALine]
end;

function TCustomTextEditor.CodeFoldingTreeEndForLine(const ALine: Integer): Boolean;
begin
  Result := False;
  if (ALine > 0) and (ALine < Length(FCodeFoldings.RangeToLine)) then
    Result := Assigned(FCodeFoldings.RangeToLine[ALine]);
end;

function TCustomTextEditor.CodeFoldingTreeLineForLine(const ALine: Integer): Boolean;
begin
  Result := False;
  if (ALine > 0) and (ALine < Length(FCodeFoldings.TreeLine)) then
    Result := FCodeFoldings.TreeLine[ALine]
end;

function TCustomTextEditor.DoOnCodeFoldingHintClick(const APoint: TPoint): Boolean;
var
  LFoldRange: TTextEditorCodeFoldingRange;
  LCollapseMarkRect: TRect;
begin
  Result := True;

  LFoldRange := CodeFoldingCollapsableFoldRangeForLine(GetViewTextLineNumber(GetSelectedRow(APoint.Y)));

  if Assigned(LFoldRange) and LFoldRange.Collapsed then
  begin
    LCollapseMarkRect := LFoldRange.CollapseMarkRect;
    OffsetRect(LCollapseMarkRect, -FLeftMarginWidth, 0);

    if LCollapseMarkRect.Right > FLeftMarginWidth then
      if PtInRect(LCollapseMarkRect, APoint) then
      begin
        FreeHintForm;
        CodeFoldingExpand(LFoldRange);

        Exit;
      end;
  end;

  Result := False;
end;

function TCustomTextEditor.FindHookedCommandEvent(const AHookedCommandEvent: TTextEditorHookedCommandEvent): Integer;
var
  LHookedCommandHandler: TTextEditorHookedCommandHandler;
begin
  Result := GetHookedCommandHandlersCount - 1;
  while Result >= 0 do
  begin
    LHookedCommandHandler := TTextEditorHookedCommandHandler(FHookedCommandHandlers[Result]);

    if LHookedCommandHandler.Equals(AHookedCommandEvent) then
      Break;

    Dec(Result);
  end;
end;

procedure TCustomTextEditor.DoTrimTrailingSpaces(const ATextLine: Integer; const AForceTrim: Boolean = False);
begin
  if (eoTrimTrailingSpaces in FOptions) or AForceTrim then
    FLines.DoTrimTrailingSpaces(ATextLine);
end;

procedure TCustomTextEditor.TrimTrailingSpaces;
var
  LLine: Integer;
begin
  for LLine := 0 to FLines.Count - 1 do
    DoTrimTrailingSpaces(LLine, True);

  Invalidate;
end;

procedure TCustomTextEditor.DoWordLeft(const ACommand: TTextEditorCommand);
var
  LCaretNewPosition: TTextEditorTextPosition;
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := TextPosition;

  FUndoList.BeginBlock;
  FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);

  LCaretNewPosition := WordStart;

  if AreTextPositionsEqual(LCaretNewPosition, LTextPosition) or (ACommand = TKeyCommands.WordLeft) then
    LCaretNewPosition := PreviousWordPosition;

  MoveCaretAndSelection(LTextPosition, LCaretNewPosition, ACommand = TKeyCommands.SelectionWordLeft);

  FUndoList.EndBlock;
end;

procedure TCustomTextEditor.DoWordRight(const ACommand: TTextEditorCommand);
var
  LCaretNewPosition: TTextEditorTextPosition;
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := TextPosition;

  FUndoList.BeginBlock;
  FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);

  LCaretNewPosition := WordEnd;

  if AreTextPositionsEqual(LCaretNewPosition, LTextPosition) or (ACommand = TKeyCommands.WordRight) then
    LCaretNewPosition := NextWordPosition;

  MoveCaretAndSelection(LTextPosition, LCaretNewPosition, ACommand = TKeyCommands.SelectionWordRight);

  FUndoList.EndBlock;
end;

procedure TCustomTextEditor.DragMinimap(const AY: Integer);
var
  LTopLine, LTemp, LTemp2: Integer;
begin
  LTemp := FLineNumbers.Count - FMinimap.VisibleLineCount;
  LTemp2 := Max(AY div FMinimap.CharHeight - FMinimapHelper.ClickOffsetY, 0);
  FMinimap.TopLine := Max(1, Trunc((LTemp / Max(FMinimap.VisibleLineCount - VisibleLineCount, 1)) * LTemp2));

  if (LTemp > 0) and (FMinimap.TopLine > LTemp) then
    FMinimap.TopLine := LTemp;

  LTopLine := Max(1, FMinimap.TopLine + LTemp2);

  if TopLine <> LTopLine then
  begin
    TopLine := LTopLine;
    FMinimap.TopLine := Max(FLineNumbers.TopLine - Abs(Trunc((FMinimap.VisibleLineCount - VisibleLineCount) *
      (FLineNumbers.TopLine / Max(Max(FLineNumbers.Count, 1) - VisibleLineCount, 1)))), 1);

    Repaint;
  end;
end;

procedure TCustomTextEditor.PaintCaret;
var
  LIndex: Integer;
  LViewPosition: TTextEditorViewPosition;
begin
  if GetSelectionAvailable then
    Exit;

  if Assigned(FMultiCaret.Carets) and (FMultiCaret.Carets.Count > 0) then
  for LIndex := 0 to FMultiCaret.Carets.Count - 1 do
  begin
    LViewPosition := PTextEditorViewPosition(FMultiCaret.Carets[LIndex])^;
    if (LViewPosition.Row >= FLineNumbers.TopLine) and (LViewPosition.Row <= FLineNumbers.TopLine + VisibleLineCount) then
      PaintCaretBlock(LViewPosition);
  end
  else
    PaintCaretBlock(FViewPosition);
end;

procedure TCustomTextEditor.FillRect(const ARect: TRect);
begin
  Winapi.Windows.ExtTextOut(Canvas.Handle, 0, 0, ETO_OPAQUE, ARect, '', 0, nil);
end;

function TCustomTextEditor.GetCanPaste: Boolean;
begin
  Result := not ReadOnly and (IsClipboardFormatAvailable(CF_TEXT) or IsClipboardFormatAvailable(CF_UNICODETEXT));
end;

function TCustomTextEditor.GetCanRedo: Boolean;
begin
  Result := not ReadOnly and FRedoList.CanUndo;
end;

function TCustomTextEditor.GetCanUndo: Boolean;
begin
  Result := not ReadOnly and FUndoList.CanUndo;
end;

function TCustomTextEditor.GetCaretIndex: Integer;
var
  LPText: PChar;
  LTextPosition: TTextEditorTextPosition;
  LLine: Integer;
  LLineFeed: Boolean;
begin
  Result := 0;

  LPText := PChar(Text);
  LTextPosition := TextPosition;
  LLine := 0;
  while LPText^ <> TControlCharacters.Null do
  begin
    if LLine = LTextPosition.Line then
    begin
      Inc(Result, LTextPosition.Char);
      Exit;
    end;

    LLineFeed := LPText^ in [TControlCharacters.CarriageReturn, TControlCharacters.Linefeed];

    if LPText^ = TControlCharacters.CarriageReturn then
    begin
      Inc(Result);
      Inc(LPText);
    end;

    if LPText^ = TControlCharacters.Linefeed then
    begin
      Inc(Result);
      Inc(LPText);
    end;

    if LLineFeed then
      Inc(LLine)
    else
    begin
      Inc(Result);
      Inc(LPText);
    end;
  end;
end;

function TCustomTextEditor.GetCharAtCursor: Char;
begin
  Result := GetCharAtTextPosition(TextPosition);
end;

function TCustomTextEditor.GetCharAtTextPosition(const ATextPosition: TTextEditorTextPosition): Char;
var
  LTextLine: string;
  LLength: Integer;
begin
  Result := TControlCharacters.Null;
  if (ATextPosition.Line >= 0) and (ATextPosition.Line < FLines.Count) then
  begin
    LTextLine := FLines.Items^[ATextPosition.Line].TextLine;
    LLength := Length(LTextLine);
    if LLength = 0 then
      Exit;

    if ATextPosition.Char <= LLength then
      Result := LTextLine[ATextPosition.Char];
  end;
end;

function TCustomTextEditor.GetPreviousCharAtCursor: Char;
var
  LTextPosition: TTextEditorTextPosition;
  LTextLine: string;
  LLength: Integer;
  LPosition: Integer;
begin
  Result := TControlCharacters.Null;
  LTextPosition := TextPosition;
  if (LTextPosition.Line >= 0) and (LTextPosition.Line < FLines.Count) then
  begin
    LTextLine := FLines.Items^[LTextPosition.Line].TextLine;

    LLength := Length(LTextLine);
    if LLength = 0 then
      Exit;

    LPosition := LTextPosition.Char - 1;
    if (LPosition > 0) and (LPosition <= LLength) then
      Result := LTextLine[LPosition];
  end;
end;

procedure TCustomTextEditor.GetCommentAtTextPosition(const ATextPosition: TTextEditorTextPosition; var AComment: string);
var
  LTextLine: string;
  LLength, LStop: Integer;
  LTextPosition: TTextEditorTextPosition;
begin
  AComment := '';
  LTextPosition := ATextPosition;
  if (LTextPosition.Line >= 0) and (LTextPosition.Line < FLines.Count) then
  begin
    LTextLine := FLines.Items^[LTextPosition.Line].TextLine;
    LLength := Length(LTextLine);
    if LLength = 0 then
      Exit;

    if (LTextPosition.Char >= 1) and (LTextPosition.Char <= LLength) and IsCommentChar(LTextLine[LTextPosition.Char]) then
    begin
      LStop := LTextPosition.Char;

      while (LStop <= LLength) and IsCommentChar(LTextLine[LStop]) do
        Inc(LStop);

      while (LTextPosition.Char > 1) and IsCommentChar(LTextLine[LTextPosition.Char - 1]) do
        Dec(LTextPosition.Char);

      if LStop > LTextPosition.Char then
        AComment := Copy(LTextLine, LTextPosition.Char, LStop - LTextPosition.Char);
    end;
  end;
end;

function TCustomTextEditor.GetCharWidth: Integer;
begin
  Result := FPaintHelper.CharWidth;
end;

function TCustomTextEditor.GetViewLineNumber(const AViewLineNumber: Integer): Integer;
var
  LLength, LFirst, LLast, LPivot: Integer;
begin
  Result := AViewLineNumber;

  LLength := Length(FLineNumbers.Cache);
  if Assigned(FLineNumbers.Cache) and (LLength > 0) and (AViewLineNumber > FLineNumbers.Cache[LLength - 1]) then
    CreateLineNumbersCache(True);

  if Assigned(FLineNumbers.Cache) and (AViewLineNumber < Length(FLineNumbers.Cache)) and
    (FLineNumbers.Cache[AViewLineNumber] = AViewLineNumber) then
    Result := AViewLineNumber
  else
  begin
    LFirst := 1;
    LLast := FLineNumbers.Count;

    while LFirst <= LLast do
    begin
      LPivot := (LFirst + LLast) div 2;

      if FLineNumbers.Cache[LPivot] > AViewLineNumber then
        LLast := LPivot - 1
      else
      if FLineNumbers.Cache[LPivot] < AViewLineNumber then
        LFirst := LPivot + 1
      else
      begin
        Result := LPivot;
        if FWordWrap.Active then
        begin
          Dec(LPivot);
          while FLineNumbers.Cache[LPivot] = AViewLineNumber do
          begin
            Result := LPivot;
            Dec(LPivot);
          end;
        end;

        Exit;
      end
    end;
  end;
end;

function TCustomTextEditor.GetEndOfLine(const ALine: PChar): PChar;
begin
  Result := ALine;

  if Assigned(Result) then
  while not (Result^ in [TControlCharacters.Null, TControlCharacters.Linefeed, TControlCharacters.CarriageReturn]) do
    Inc(Result);
end;

function TCustomTextEditor.GetFoldingOnCurrentLine: Boolean;
begin
  Result := Assigned(CodeFoldingRangeForLine(FPosition.Text.Line + 1));
end;

function TCustomTextEditor.GetHighlighterAttributeAtRowColumn(const ATextPosition: TTextEditorTextPosition;
  var AToken: string; var ATokenType: TTextEditorRangeType; var AStart: Integer;
  var AHighlighterAttribute: TTextEditorHighlighterAttribute): Boolean;
var
  LPositionX, LPositionY: Integer;
  LLine: string;
  LTokenType: TTextEditorRangeType;
  LToken: string;
  LEnd: Integer;
begin
  LPositionY := ATextPosition.Line;
  if Assigned(FHighlighter) and (LPositionY >= 0) and (LPositionY < FLines.Count) then
  begin
    LLine := FLines.Items^[LPositionY].TextLine;

    if LPositionY = 0 then
      FHighlighter.ResetRange
    else
      FHighlighter.SetRange(FLines.Ranges[LPositionY - 1]);

    FHighlighter.SetLine(LLine);

    LPositionX := ATextPosition.Char;
    if (LPositionX > 0) and (LPositionX <= Length(LLine)) then
    while not FHighlighter.EndOfLine do
    begin
      AToken := '';
      AStart := FHighlighter.TokenPosition + 1;
      LEnd := AStart;
      LTokenType := FHighlighter.TokenType;

      AHighlighterAttribute := FHighlighter.TokenAttribute;

      while not FHighlighter.EndOfLine and (LTokenType = FHighlighter.TokenType) do
      begin
        FHighlighter.GetToken(LToken);
        Inc(LEnd, Length(LToken));
        AToken := AToken + LToken;

        FHighlighter.Next;
      end;

      if (LPositionX >= AStart) and (LPositionX < LEnd) then
      begin
        ATokenType := LTokenType;

        Exit(True);
      end;
    end;
  end;
  AToken := '';
  AHighlighterAttribute := nil;
  Result := False;
end;

function TCustomTextEditor.GetHookedCommandHandlersCount: Integer;
begin
  if Assigned(FHookedCommandHandlers) then
    Result := FHookedCommandHandlers.Count
  else
    Result := 0;
end;

function TCustomTextEditor.GetHorizontalScrollMax: Integer;
begin
  Result := Max(Max(FLines.GetLengthOfLongestLine * FPaintHelper.CharWidth, FScrollHelper.HorizontalPosition),
    FScrollHelper.PageWidth);

  if soPastEndOfLine in FScroll.Options then
    Result := Result + FScrollHelper.PageWidth;
end;

function TCustomTextEditor.GetTextPosition: TTextEditorTextPosition;
begin
  Result := ViewToTextPosition(ViewPosition);
  FPosition.Text := Result;
end;

function TCustomTextEditor.GetLeadingExpandedLength(const AText: string; const ABorder: Integer = 0): Integer;
var
  LChar: PChar;
  LLength: Integer;
begin
  Result := 0;

  LChar := PChar(AText);

  if ABorder > 0 then
    LLength := Min(PInteger(LChar - 2)^, ABorder)
  else
    LLength := PInteger(LChar - 2)^;

  while LLength > 0 do
  begin
    if LChar^ = TControlCharacters.Tab then
      Inc(Result, FTabs.Width - (Result mod FTabs.Width))
    else
    if (LChar^ = TCharacters.Space) or (LChar^ = TControlCharacters.Substitute) then
      Inc(Result)
    else
      Exit;

    Inc(LChar);
    Dec(LLength);
  end;
end;

function TCustomTextEditor.GetLeftMarginWidth: Integer;
begin
  Result := FLeftMargin.GetWidth + FCodeFolding.GetWidth;

  if FMinimap.Align = maLeft then
    Inc(Result, FMinimap.GetWidth);

  if FSearch.Map.Align = saLeft then
    Inc(Result, FSearch.Map.GetWidth);
end;

function TCustomTextEditor.GetLineHeight: Integer;
begin
  Result := FPaintHelper.CharHeight + FLineSpacing;
end;

function TCustomTextEditor.GetLineIndentLevel(const ALine: Integer): Integer;
var
  LPLine: PChar;
begin
  Result := 0;

  if ALine >= FLines.Count then
    Exit;

  LPLine := PChar(FLines.Items^[ALine].TextLine);
  while (LPLine^ <> TControlCharacters.Null) and
    (LPLine^ in [TControlCharacters.Tab, TCharacters.Space, TControlCharacters.Substitute]) do
  begin
    if LPLine^ = TControlCharacters.Tab then
    begin
      if FLines.Columns then
        Inc(Result, FTabs.Width - Result mod FTabs.Width)
      else
        Inc(Result, FTabs.Width);
    end
    else
      Inc(Result);

    Inc(LPLine);
  end;
end;

function TCustomTextEditor.GetMarkBackgroundColor(const ALine: Integer): TColor;
var
  LIndex: Integer;
  LMark: TTextEditorMark;
begin
  Result := TColors.SysNone;
  { Bookmarks }
  if FLeftMargin.Colors.BookmarkBackground <> TColors.SysNone then
  for LIndex := 0 to FBookmarkList.Count - 1 do
  begin
    LMark := FBookmarkList.Items[LIndex];
    if LMark.Line + 1 = ALine then
    begin
      Result := FLeftMargin.Colors.BookmarkBackground;
      Break;
    end;
  end;
  { Custom marks }
  for LIndex := 0 to FMarkList.Count - 1 do
  begin
    LMark := FMarkList.Items[LIndex];
    if (LMark.Line + 1 = ALine) and (LMark.Background <> TColors.SysNone) then
    begin
      Result := LMark.Background;
      Break;
    end;
  end;
end;

function TCustomTextEditor.GetMatchingToken(const AViewPosition: TTextEditorViewPosition;
  var AMatch: TTextEditorMatchingPairMatch): TTextEditorMatchingTokenResult;
var
  LIndex, LCount: Integer;
  LTokenMatch: PTextEditorMatchingPairToken;
  LToken, LOriginalToken: string;
  LLevel, LDeltaLevel: Integer;
  LMatchStackID: Integer;
  LOpenDuplicateLength, LCloseDuplicateLength: Integer;
  LCurrentLineText: string;
  LTextPosition: TTextEditorTextPosition;
  LIsBlockComment: Boolean;
  LTokenType: TTextEditorRangeType;

  function IsOpenToken: Boolean;
  var
    LIndex: Integer;
  begin
    Result := True;

    for LIndex := 0 to LOpenDuplicateLength - 1 do
    if LToken = PTextEditorMatchingPairToken(FHighlighter.MatchingPairs[FMatchingPair.OpenDuplicate[LIndex]])^.OpenToken then
      Exit;

    Result := False
  end;

  function IsCloseToken: Boolean;
  var
    LIndex: Integer;
  begin
    Result := True;

    for LIndex := 0 to LCloseDuplicateLength - 1 do
    if LToken = PTextEditorMatchingPairToken(FHighlighter.MatchingPairs[FMatchingPair.CloseDuplicate[LIndex]])^.CloseToken then
      Exit;

    Result := False
  end;

  function CheckToken: Boolean;
  begin
    with FHighlighter do
    if LIsBlockComment or (TokenType = LTokenType) then
    begin
      GetToken(LToken);
      LToken := LowerCase(LToken);

      if IsCloseToken then
        Dec(LLevel)
      else
      if IsOpenToken then
        Inc(LLevel);

      if LLevel = 0 then
      begin
        GetMatchingToken := trOpenAndCloseTokenFound;
        GetToken(AMatch.CloseToken);
        AMatch.CloseTokenPos.Line := LTextPosition.Line;
        AMatch.CloseTokenPos.Char := TokenPosition + 1;

        Result := True;
      end
      else
      begin
        Next;
        Result := False;
      end;
    end
    else
    begin
      Next;
      Result := False;
    end
  end;

  procedure CheckTokenBack;
  begin
    with FHighlighter do
    begin
      if LIsBlockComment or (TokenType = LTokenType) then
      begin
        GetToken(LToken);
        LToken := LowerCase(LToken);
        if IsOpenToken then
        begin
          Inc(LLevel);
          Inc(LMatchStackID);

          if LMatchStackID >= Length(FMatchingPair.MatchStack) then
            SetLength(FMatchingPair.MatchStack, Length(FMatchingPair.MatchStack) + 32);

          GetToken(FMatchingPair.MatchStack[LMatchStackID].Token);

          FMatchingPair.MatchStack[LMatchStackID].Position.Line := LTextPosition.Line;
          FMatchingPair.MatchStack[LMatchStackID].Position.Char := TokenPosition + 1;
        end
        else
        if IsCloseToken then
        begin
          Dec(LLevel);
          if LMatchStackID >= 0 then
            Dec(LMatchStackID);
        end;
      end;

      Next;
    end;
  end;

  procedure InitializeCurrentLine;
  begin
    if LTextPosition.Line = 0 then
      FHighlighter.ResetRange
    else
      FHighlighter.SetRange(FLines.Ranges[LTextPosition.Line - 1]);

    LCurrentLineText := FLines[LTextPosition.Line];

    FHighlighter.SetLine(LCurrentLineText);
  end;

  function CheckComment(const AToken: string; const AComment: string): Boolean; inline;
  var
    LPComment, LPCommentAtCursor: PChar;
  begin
    LPComment := PChar(AComment);
    LPCommentAtCursor := PChar(AToken);

    while (LPComment^ <> TControlCharacters.Null) and (LPCommentAtCursor^ <> TControlCharacters.Null) and
      (LPCommentAtCursor^ = LPComment^) do
    begin
      Inc(LPComment);
      Inc(LPCommentAtCursor);
    end;

    Result := LPComment^ = TControlCharacters.Null;
  end;

  function IsBlockComment(const AToken: string): Boolean;
  var
    LIndex: Integer;
  begin
    Result := False;

    LIndex := 0;
    while LIndex < Length(FHighlighter.Comments.BlockComments) do
    begin
      if CheckComment(AToken, FHighlighter.Comments.BlockComments[LIndex]) then
        Exit(True);

      if CheckComment(AToken, FHighlighter.Comments.BlockComments[LIndex + 1]) then
        Exit(True);

      Inc(LIndex, 2);
    end;
  end;

var
  LMathingPairToken: TTextEditorMatchingPairToken;
  LTempToken: string;
  LTokenCount: Integer;
  LCheckOnlyOneLine: Boolean;
begin
  Result := trNotFound;

  if not Assigned(FHighlighter) then
    Exit;

  LTextPosition := ViewToTextPosition(AViewPosition);

  with FHighlighter do
  begin
    InitializeCurrentLine;

    while not EndOfLine and (LTextPosition.Char > TokenPosition + TokenLength) do
      Next;

    if EndOfLine then
      Exit;

    LIndex := 0;
    LCheckOnlyOneLine := False;
    LCount := FHighlighter.MatchingPairs.Count;

    GetToken(LOriginalToken);
    LToken := TextEditor.Utils.Trim(LowerCase(LOriginalToken));

    if LToken = '' then
      Exit;

    LTokenType := TokenType;
    LIsBlockComment := IsBlockComment(LToken);
    if not (LTokenType in [ttReservedWord, ttSymbol]) and not (LIsBlockComment and (LTokenType = ttBlockComment)) then
      Exit;

    while LIndex < LCount do
    begin
      LMathingPairToken := PTextEditorMatchingPairToken(FHighlighter.MatchingPairs[LIndex])^;
      if (LToken = LMathingPairToken.OpenToken) and (LToken = LMathingPairToken.CloseToken) then
      begin
        LCheckOnlyOneLine := True;
        InitializeCurrentLine;
        LTokenCount := 0;
        while not EndOfLine and (LTextPosition.Char > TokenPosition + TokenLength) do
        begin
          GetToken(LTempToken);

          if LOriginalToken = LTempToken then
            Inc(LTokenCount);

          Next;
        end;

        if LTokenCount mod 2 = 0 then
        begin
          Result := trOpenTokenFound;

          AMatch.OpenToken := LOriginalToken;
          AMatch.OpenTokenPos.Line := LTextPosition.Line;
          AMatch.OpenTokenPos.Char := TokenPosition + 1;

          Break;
        end
        else
        begin
          Result := trCloseTokenFound;

          AMatch.CloseToken := LOriginalToken;
          AMatch.CloseTokenPos.Line := LTextPosition.Line;
          AMatch.CloseTokenPos.Char := TokenPosition + 1;

          Break;
        end;
      end
      else
      if LToken = LMathingPairToken.OpenToken then
      begin
        Result := trOpenTokenFound;

        AMatch.OpenToken := LOriginalToken;
        AMatch.OpenTokenPos.Line := LTextPosition.Line;
        AMatch.OpenTokenPos.Char := TokenPosition + 1;

        Break;
      end
      else
      if LToken = LMathingPairToken.CloseToken then
      begin
        Result := trCloseTokenFound;

        AMatch.CloseToken := LOriginalToken;
        AMatch.CloseTokenPos.Line := LTextPosition.Line;
        AMatch.CloseTokenPos.Char := TokenPosition + 1;

        Break;
      end;
      Inc(LIndex);
    end;

    if Result = trNotFound then
      Exit;

    LTokenMatch := FHighlighter.MatchingPairs.Items[LIndex];
    AMatch.TokenAttribute := TokenAttribute;

    if LCount > Length(FMatchingPair.OpenDuplicate) then
    begin
      SetLength(FMatchingPair.OpenDuplicate, LCount);
      SetLength(FMatchingPair.CloseDuplicate, LCount);
    end;

    LOpenDuplicateLength := 0;
    LCloseDuplicateLength := 0;

    for LIndex := 0 to LCount - 1 do
    begin
      LMathingPairToken := PTextEditorMatchingPairToken(FHighlighter.MatchingPairs[LIndex])^;

      if LTokenMatch^.OpenToken = LMathingPairToken.OpenToken then
      begin
        FMatchingPair.CloseDuplicate[LCloseDuplicateLength] := LIndex;
        Inc(LCloseDuplicateLength);
      end;

      if LTokenMatch^.CloseToken = LMathingPairToken.CloseToken then
      begin
        FMatchingPair.OpenDuplicate[LOpenDuplicateLength] := LIndex;
        Inc(LOpenDuplicateLength);
      end;
    end;

    if Result = trOpenTokenFound then
    begin
      LLevel := 1;
      Next;
      while True do
      begin
        while not EndOfLine do
        if CheckToken then
          Exit;

        if LCheckOnlyOneLine then
          Break;

        Inc(LTextPosition.Line);
        if LTextPosition.Line > FLines.Count then
          Break;

        InitializeCurrentLine;
      end;
    end
    else
    begin
      if Length(FMatchingPair.MatchStack) < 32 then
        SetLength(FMatchingPair.MatchStack, 32);

      LMatchStackID := -1;
      LLevel := -1;

      InitializeCurrentLine;

      while not EndOfLine and (TokenPosition < AMatch.CloseTokenPos.Char - 1) do
        CheckTokenBack;

      if LMatchStackID > -1 then
      begin
        Result := trCloseAndOpenTokenFound;

        with FMatchingPair.MatchStack[LMatchStackID] do
        begin
          AMatch.OpenToken := Token;
          AMatch.OpenTokenPos := Position;
        end;
      end
      else
      while LTextPosition.Line > 0 do
      begin
        if LCheckOnlyOneLine then
          Break;
        LDeltaLevel := -LLevel - 1;
        Dec(LTextPosition.Line);

        InitializeCurrentLine;

        LMatchStackID := -1;
        while not EndOfLine do
          CheckTokenBack;

        if LDeltaLevel <= LMatchStackID then
        begin
          Result := trCloseAndOpenTokenFound;

          with FMatchingPair.MatchStack[LMatchStackID - LDeltaLevel] do
          begin
            AMatch.OpenToken := Token;
            AMatch.OpenTokenPos := Position;
          end;

          Exit;
        end;
      end;
    end;
  end;
end;

function TCustomTextEditor.GetMouseScrollCursors(const AIndex: Integer): HCursor;
begin
  Result := 0;
  if (AIndex >= Low(FMouse.ScrollCursors)) and (AIndex <= High(FMouse.ScrollCursors)) then
    Result := FMouse.ScrollCursors[AIndex];
end;

function TCustomTextEditor.GetMouseScrollCursorIndex: Integer;
var
  LCursorPoint: TPoint;
  LLeftX, LRightX, LTopY, LBottomY: Integer;
begin
  Result := scNone;

  Winapi.Windows.GetCursorPos(LCursorPoint);
  LCursorPoint := ScreenToClient(LCursorPoint);

  LLeftX := FMouse.ScrollingPoint.X - FScroll.Indicator.Width;
  LRightX := FMouse.ScrollingPoint.X + 4;
  LTopY := FMouse.ScrollingPoint.Y - FScroll.Indicator.Height;
  LBottomY := FMouse.ScrollingPoint.Y + 4;

  if LCursorPoint.Y < LTopY then
  begin
    if LCursorPoint.X < LLeftX then
      Exit(TMouseWheel.ScrollCursor.NorthWest)
    else
    if (LCursorPoint.X >= LLeftX) and (LCursorPoint.X <= LRightX) then
      Exit(TMouseWheel.ScrollCursor.North)
    else
      Exit(TMouseWheel.ScrollCursor.NorthEast)
  end;

  if LCursorPoint.Y > LBottomY then
  begin
    if LCursorPoint.X < LLeftX then
      Exit(TMouseWheel.ScrollCursor.SouthWest)
    else
    if (LCursorPoint.X >= LLeftX) and (LCursorPoint.X <= LRightX) then
      Exit(TMouseWheel.ScrollCursor.South)
    else
      Exit(TMouseWheel.ScrollCursor.SouthEast)
  end;

  if LCursorPoint.X < LLeftX then
    Exit(TMouseWheel.ScrollCursor.West);

  if LCursorPoint.X > LRightX then
    Exit(TMouseWheel.ScrollCursor.East);
end;

function TCustomTextEditor.GetScrollPageWidth: Integer;
begin
  Result := Max(ClientRect.Right - FLeftMargin.GetWidth - FCodeFolding.GetWidth - 2 - FMinimap.GetWidth - FSearch.Map.GetWidth, 0);
end;

function TCustomTextEditor.GetSelectionAvailable: Boolean;
begin
  Result := FSelection.Visible and ((FPosition.BeginSelection.Char <> FPosition.EndSelection.Char) or
    ((FPosition.BeginSelection.Line <> FPosition.EndSelection.Line) and (FSelection.ActiveMode <> smColumn)));
end;

function TCustomTextEditor.GetSelectedText: string;

  function CopyPadded(const AValue: string;  const AIndex, ACount: Integer): string;
  var
    LIndex: Integer;
    LSourceLength, LDestinationLength: Integer;
    LPResult: PChar;
  begin
    LSourceLength := Length(AValue);
    LDestinationLength := AIndex + ACount;

    if LSourceLength >= LDestinationLength then
      Result := Copy(AValue, AIndex, ACount)
    else
    begin
      SetLength(Result, LDestinationLength);
      LPResult := PChar(Result);
      StrCopy(LPResult, PChar(Copy(AValue, AIndex, ACount)));
      Inc(LPResult, Length(AValue));

      for LIndex := 0 to LDestinationLength - LSourceLength - 1 do
        LPResult[LIndex] := TCharacters.Space;
    end;
  end;

  procedure CopyAndForward(const AValue: string; AIndex: Integer; const ACount: Integer; var APResult: PChar);
  var
    LPSource: PChar;
    LSourceLength: Integer;
    LDestinationLength: Integer;
  begin
    LSourceLength := Length(AValue);

    if (AIndex <= LSourceLength) and (ACount > 0) then
    begin
      Dec(AIndex);
      LPSource := PChar(AValue) + AIndex;
      LDestinationLength := Min(LSourceLength - AIndex, ACount);
      Move(LPSource^, APResult^, LDestinationLength * SizeOf(Char));
      Inc(APResult, LDestinationLength);
      APResult^ := TControlCharacters.Null;
    end;
  end;

  function CopyPaddedAndForward(const AValue: string; const AIndex, ACount: Integer; var PResult: PChar): Integer;
  var
    LPResult: PChar;
    LIndex, LLength: Integer;
  begin
    Result := 0;

    LPResult := PResult;
    CopyAndForward(AValue, AIndex, ACount, PResult);
    LLength := ACount - (PResult - LPResult);

    if not (eoTrimTrailingSpaces in Options) and (PResult - LPResult > 0) then
    begin
      for LIndex := 0 to LLength - 1 do
        PResult[LIndex] := TCharacters.Space;
      Inc(PResult, LLength);
    end
    else
      Result := LLength;
  end;

  function DoGetSelectedText: string;
  var
    LFirstLine, LLastLine, LTotalLength: Integer;
    LColumnFrom, LColumnTo: Integer;
    LLine, LLeftCharPosition, LRightCharPosition: Integer;
    LLineText: string;
    LPResult: PChar;
    LRow: Integer;
    LTextPosition: TTextEditorTextPosition;
    LViewPosition: TTextEditorViewPosition;
    LTrimCount: Integer;
  begin
    LColumnFrom := SelectionBeginPosition.Char;
    LFirstLine := SelectionBeginPosition.Line;
    LColumnTo := SelectionEndPosition.Char;
    LLastLine := SelectionEndPosition.Line;

    case FSelection.ActiveMode of
      smNormal:
        begin
          if LFirstLine = LLastLine then
            Result := Copy(FLines[LFirstLine], LColumnFrom, LColumnTo - LColumnFrom)
          else
          begin
            { Calculate total length of result string }
            LTotalLength := Max(0, Length(FLines[LFirstLine]) - LColumnFrom + 1);
            Inc(LTotalLength, FLines.LineBreakLength(LFirstLine));

            for LLine := LFirstLine + 1 to LLastLine - 1 do
            begin
              Inc(LTotalLength, Length(FLines[LLine]));
              if not (sfEmptyLine in FLines.Items^[LLine].Flags) then
                Inc(LTotalLength, FLines.LineBreakLength(LLine));
            end;

            Inc(LTotalLength, LColumnTo - 1);

            SetLength(Result, LTotalLength);
            LPResult := PChar(Result);
            CopyAndForward(FLines[LFirstLine], LColumnFrom, LTotalLength, LPResult);
            CopyAndForward(FLines.GetLineBreak(LFirstLine), 1, LTotalLength, LPResult);

            for LLine := LFirstLine + 1 to LLastLine - 1 do
            begin
              CopyAndForward(FLines[LLine], 1, LTotalLength, LPResult);
              if not (sfEmptyLine in FLines.Items^[LLine].Flags) then
                CopyAndForward(FLines.GetLineBreak(LLine), 1, LTotalLength, LPResult);
            end;

            CopyAndForward(FLines[LLastLine], 1, LColumnTo - 1, LPResult);
          end;
        end;
      smColumn:
        begin
          with TextToViewPosition(SelectionBeginPosition) do
          begin
            LFirstLine := Row;
            LColumnFrom := Column;
          end;

          with TextToViewPosition(SelectionEndPosition) do
          begin
            LLastLine := Row;
            LColumnTo := Column;
          end;

          if LColumnFrom > LColumnTo then
            SwapInt(LColumnFrom, LColumnTo);

          LTotalLength := ((LColumnTo - LColumnFrom) + FLines.DefaultLineBreak.Length) * (LLastLine - LFirstLine + 1);
          SetLength(Result, LTotalLength);
          LPResult := PChar(Result);

          LTotalLength := 0;
          for LRow := LFirstLine to LLastLine do
          begin
            LViewPosition.Row := LRow;
            LViewPosition.Column := LColumnFrom;
            LTextPosition := ViewToTextPosition(LViewPosition);

            LLeftCharPosition := LTextPosition.Char;
            LLineText := FLines.Items^[LTextPosition.Line].TextLine;
            LViewPosition.Column := LColumnTo;
            LRightCharPosition := ViewToTextPosition(LViewPosition).Char;
            LTrimCount := CopyPaddedAndForward(LLineText, LLeftCharPosition, LRightCharPosition - LLeftCharPosition,
              LPResult);
            LTotalLength := LTotalLength + (LRightCharPosition - LLeftCharPosition) - LTrimCount +
              FLines.LineBreakLength(LTextPosition.Line);

            CopyAndForward(FLines.GetLineBreak(LTextPosition.Line), 1, LTotalLength, LPResult);
          end;
          SetLength(Result, Max(LTotalLength, 0));
        end;
    end;
  end;

begin
  Result := '';

  if GetSelectionAvailable then
    Result := DoGetSelectedText;
end;

function TCustomTextEditor.GetSearchResultCount: Integer;
begin
  Result := FSearch.Items.Count;
end;

function TCustomTextEditor.GetSelectionBeginPosition: TTextEditorTextPosition;
var
  LLineLength: Integer;
begin
  if (FPosition.EndSelection.Line < FPosition.BeginSelection.Line) or
    ((FPosition.EndSelection.Line = FPosition.BeginSelection.Line) and
     (FPosition.EndSelection.Char < FPosition.BeginSelection.Char)) then
    Result := FPosition.EndSelection
  else
    Result := FPosition.BeginSelection;

  if FSelection.Mode = smNormal then
  begin
    LLineLength := Length(FLines[Result.Line]);

    if Result.Char > LLineLength then
      Result.Char := LLineLength + 1;
  end;
end;

function TCustomTextEditor.GetSelectionEndPosition: TTextEditorTextPosition;
var
  LLineLength: Integer;
begin
  if (FPosition.EndSelection.Line < FPosition.BeginSelection.Line) or
    ((FPosition.EndSelection.Line = FPosition.BeginSelection.Line) and
     (FPosition.EndSelection.Char < FPosition.BeginSelection.Char)) then
    Result := FPosition.BeginSelection
  else
    Result := FPosition.EndSelection;

  if FSelection.Mode = smNormal then
  begin
    LLineLength := Length(FLines[Result.Line]);

    if Result.Char > LLineLength then
      Result.Char := LLineLength + 1;
  end;
end;

function TCustomTextEditor.GetRowCountFromPixel(const AY: Integer): Integer;
var
  LY: Integer;
begin
  LY := AY;

  if FRuler.Visible then
    Dec(LY, FRuler.Height);

  Result := LY div GetLineHeight;
end;

function TCustomTextEditor.GetSelectedRow(const AY: Integer): Integer;
begin
  Result := Max(1, Min(TopLine + GetRowCountFromPixel(AY), FLineNumbers.Count));
end;

function TCustomTextEditor.GetSelectionStart: Integer;
begin
  Result := TextPositionToCharIndex(SelectionBeginPosition);
end;

function TCustomTextEditor.GetText: string;
begin
  if csDestroying in ComponentState then
    Result := ''
  else
    Result := FLines.Text;
end;

function TCustomTextEditor.GetTextBetween(const ATextBeginPosition: TTextEditorTextPosition;
  const ATextEndPosition: TTextEditorTextPosition): string;
var
  LSelectionMode: TTextEditorSelectionMode;
begin
  LSelectionMode := FSelection.Mode;
  FSelection.Mode := smNormal;
  FPosition.BeginSelection := ATextBeginPosition;
  FPosition.EndSelection := ATextEndPosition;

  Result := SelectedText;

  FSelection.Mode := LSelectionMode;
end;

function TCustomTextEditor.WordWrapWidth: Integer;
begin
  case FWordWrap.Width of
    wwwPage:
      Result := FScrollHelper.PageWidth;
    wwwRightMargin:
      Result := FRightMargin.Position * FPaintHelper.CharWidth;
  else
    Result := 0;
  end
end;

function TCustomTextEditor.GetTokenCharCount(const AToken: string; const ACharsBefore: Integer): Integer;
var
  LPToken: PChar;
begin
  LPToken := PChar(AToken);
  if LPToken^ = TControlCharacters.Tab then
  begin
    if FLines.Columns then
      Result := FTabs.Width - ACharsBefore mod FTabs.Width
    else
      Result := FTabs.Width;
  end
  else
    Result := Length(AToken);
end;

function TCustomTextEditor.GetTokenWidth(const AToken: string; const ALength: Integer; const ACharsBefore: Integer;
  const AMinimap: Boolean = False; const ARTLReading: Boolean = False): Integer;
var
  LChar: Char;
  LRect: TRect;
  LPToken: PChar;
  LToken: string;
  LFlags: Cardinal;

  function FixedSizeFont: Boolean;
  begin
    Result := FPaintHelper.FixedSizeFont and (AMinimap or (FLines.Encoding = System.SysUtils.TEncoding.ANSI) or
      (FLines.Encoding = System.SysUtils.TEncoding.ASCII));
  end;

  function GetTokenWidth(const AToken: string): Integer;
  begin
    DrawText(FPaintHelper.StockBitmap.Canvas.Handle, AToken, ALength, LRect, LFlags);

    Result := LRect.Width;
  end;

  function GetControlCharacterWidth: Integer;
  begin
    LToken := ControlCharacterToName(LChar);

    if FixedSizeFont then
      Result := (FPaintHelper.FontStock.CharWidth * Length(LToken) + 3) * ALength
    else
      Result := GetTokenWidth(LToken);
  end;

begin
  Result := 0;

  if (AToken = '') or (ALength = 0) then
    Exit;

  LChar := AToken[1];

  LFlags := DT_LEFT or DT_CALCRECT or DT_NOPREFIX or DT_SINGLELINE;
  if ARTLReading then
    LFlags := LFlags or DT_RTLREADING;

  if ARTLReading then
  begin
    { Right-to-left token can start with space or tabs }
    LPToken := PChar(AToken);
    while LPToken^ <> TControlCharacters.Null do
    begin
      if Ord(LPToken^) > TCharacters.AnsiCharCount then
        Exit(GetTokenWidth(AToken));

      Inc(LPToken);
    end;

    Result := FPaintHelper.FontStock.CharWidth * ALength;
  end
  else
  if LChar = TControlCharacters.Substitute then
  begin
    if eoShowNullCharacters in Options then
      Result := GetControlCharacterWidth
    else
      Result := 0
  end
  else
  if (LChar < TCharacters.Space) and (LChar in TControlCharacters.AsSet) then
  begin
    if eoShowControlCharacters in Options then
      Result := GetControlCharacterWidth
    else
      Result := 0;
  end
  else
  if LChar = TCharacters.ZeroWidthSpace then
  begin
    if eoShowZeroWidthSpaces in Options then
      Result := GetControlCharacterWidth
    else
      Result := 0
  end
  else
  if LChar = TCharacters.Space then
    Result := FPaintHelper.FontStock.CharWidth * ALength
  else
  if LChar = TControlCharacters.Tab then
  begin
    if FLines.Columns then
      Result := FTabs.Width - ACharsBefore mod FTabs.Width
    else
      Result := FTabs.Width;

    Result := Result * FPaintHelper.FontStock.CharWidth + (ALength - 1) * FPaintHelper.FontStock.CharWidth * FTabs.Width;
  end
  else
  if FixedSizeFont then
    Result := FPaintHelper.FontStock.CharWidth * ALength
  else
  if not FPaintHelper.FixedSizeFont then
    Result := GetTokenWidth(AToken)
  else
  begin
    LPToken := PChar(AToken);
    while LPToken^ <> TControlCharacters.Null do
    begin
      if Ord(LPToken^) > TCharacters.AnsiCharCount then
        Exit(GetTokenWidth(AToken));

      Inc(LPToken);
    end;

    Result := FPaintHelper.FontStock.CharWidth * ALength;
  end;
end;

procedure TCustomTextEditor.CreateLineNumbersCache(const AReset: Boolean = False);
var
  LIndex, LCurrentLine, LCacheLength: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
  LCollapsedCodeFolding: array of Boolean;
  LLineNumbersCacheLength: Integer;
  LCompareMode: Boolean;
  LCompareOffset: Integer;

  procedure ResizeCacheArray;
  begin
    if FWordWrap.Active and (LCacheLength >= LLineNumbersCacheLength) then
    begin
      Inc(LLineNumbersCacheLength, 256);
      SetLength(FLineNumbers.Cache, LLineNumbersCacheLength);
      SetLength(FWordWrapLine.Length, LLineNumbersCacheLength);
      SetLength(FWordWrapLine.ViewLength, LLineNumbersCacheLength);
      SetLength(FWordWrapLine.Width, LLineNumbersCacheLength);
    end;
  end;

  procedure AddLineNumberIntoCache;
  begin
    FLineNumbers.Cache[LCacheLength] := LCurrentLine;
    Inc(LCacheLength);

    ResizeCacheArray;
  end;

  procedure AddWrappedLineNumberIntoCache;
  var
    LTokenText, LNextTokenText, LFirstPartOfToken, LSecondPartOfToken: string;
    LHighlighterAttribute: TTextEditorHighlighterAttribute;
    LLength, LViewLength, LTokenWidth, LWidth, LMaxWidth: Integer;
    LCharsBefore: Integer;
    LPToken: PChar;
    LTokenLength: Integer;
    LLine: string;
  begin
    if not Visible then
      Exit;

    LMaxWidth := WordWrapWidth;

    if LCurrentLine = 1 then
      FHighlighter.ResetRange
    else
      FHighlighter.SetRange(FLines.Ranges[LCurrentLine - 2]);

    LLine := FLines.Items^[LCurrentLine - 1].TextLine;

    FHighlighter.SetLine(LLine);

    LWidth := 0;
    LLength := 0;
    LViewLength := 0;
    LCharsBefore := 0;
    while not FHighlighter.EndOfLine do
    begin
      if LNextTokenText = '' then
        FHighlighter.GetToken(LTokenText)
      else
        LTokenText := LNextTokenText;

      LNextTokenText := '';
      LTokenLength := Length(LTokenText);

      LHighlighterAttribute := FHighlighter.TokenAttribute;
      if Assigned(LHighlighterAttribute) then
        FPaintHelper.SetStyle(LHighlighterAttribute.FontStyles);

      LTokenWidth := GetTokenWidth(LTokenText, LTokenLength, LCharsBefore);

      if LTokenWidth > LMaxWidth then
      begin
        LTokenWidth := 0;
        LPToken := PChar(LTokenText);
        LFirstPartOfToken := '';

        while (LPToken^ <> TControlCharacters.Null) and (LWidth + LTokenWidth <= LMaxWidth) do
        begin
          LSecondPartOfToken := LPToken^;
          while True do
          begin
            Inc(LPToken);

            if (LPToken^ <> TControlCharacters.Null) and IsCombiningCharacter(LPToken) then
              LSecondPartOfToken := LSecondPartOfToken + LPToken^
            else
              Break;
          end;
          LTokenWidth := GetTokenWidth(LFirstPartOfToken + LSecondPartOfToken, Length(LFirstPartOfToken +
            LSecondPartOfToken), LCharsBefore);

          if LWidth + LTokenWidth < LMaxWidth then
            LFirstPartOfToken := LFirstPartOfToken + LSecondPartOfToken;
        end;

        if (LLength = 0) and (LFirstPartOfToken = '') then
          LFirstPartOfToken := LPToken^;

        Inc(LLength, LFirstPartOfToken.Length);
        Inc(LViewLength, GetTokenCharCount(LFirstPartOfToken, LViewLength));

        FWordWrapLine.Length[LCacheLength] := LLength;
        FWordWrapLine.ViewLength[LCacheLength] := LViewLength;
        FWordWrapLine.Width[LCacheLength] := LWidth;
        AddLineNumberIntoCache;

        Inc(LCharsBefore, GetTokenCharCount(LFirstPartOfToken, LCharsBefore));
        LLength := 0;
        LViewLength := 0;
        LWidth := 0;
        LNextTokenText := Copy(LTokenText, Length(LFirstPartOfToken) + 1, Length(LTokenText));

        if LNextTokenText = '' then
          FHighlighter.Next;

        Continue;
      end
      else
      if LWidth + LTokenWidth > LMaxWidth then
      begin
        FWordWrapLine.Length[LCacheLength] := LLength;
        FWordWrapLine.ViewLength[LCacheLength] := LViewLength;
        FWordWrapLine.Width[LCacheLength] := LWidth;
        AddLineNumberIntoCache;
        LLength := 0;
        LViewLength := 0;
        LWidth := 0;
        Continue;
      end;

      Inc(LCharsBefore, GetTokenCharCount(LTokenText, LCharsBefore));
      Inc(LLength, LTokenText.Length);
      Inc(LViewLength, GetTokenCharCount(LTokenText, LViewLength));

      Inc(LWidth, LTokenWidth);
      FHighlighter.Next;
    end;

    if (LLength > 0) or (LLine = '') then
    begin
      FWordWrapLine.Length[LCacheLength] := LLength;
      FWordWrapLine.ViewLength[LCacheLength] := LViewLength;
      FWordWrapLine.Width[LCacheLength] := LWidth;
      AddLineNumberIntoCache;
    end;
  end;

begin
  if not Assigned(Parent) or FLines.Streaming or FHighlighter.Loading then
    Exit;

  if FLineNumbers.ResetCache or AReset then
  begin
    FLineNumbers.ResetCache := False;
    SetLength(LCollapsedCodeFolding, FLines.Count + 1);

    for LIndex := 0 to FCodeFoldings.AllRanges.AllCount - 1 do
    begin
      LCodeFoldingRange := FCodeFoldings.AllRanges[LIndex];
      if Assigned(LCodeFoldingRange) and LCodeFoldingRange.Collapsed then
      for LCurrentLine := LCodeFoldingRange.FromLine + 1 to LCodeFoldingRange.ToLine do
        LCollapsedCodeFolding[LCurrentLine] := True;
    end;

    LCompareMode := lnoCompareMode in FLeftMargin.LineNumbers.Options;
    SetLength(FLineNumbers.Cache, 0);
    SetLength(FWordWrapLine.Length, 0);
    SetLength(FWordWrapLine.ViewLength, 0);
    SetLength(FWordWrapLine.Width, 0);

    if LCompareMode then
      SetLength(FCompareLineNumberOffsetCache, 0);

    LLineNumbersCacheLength := FLines.Count + 1;

    if FWordWrap.Active then
    begin
      Inc(LLineNumbersCacheLength, 256);
      SetLength(FWordWrapLine.Length, LLineNumbersCacheLength);
      SetLength(FWordWrapLine.ViewLength, LLineNumbersCacheLength);
      SetLength(FWordWrapLine.Width, LLineNumbersCacheLength);
    end;

    SetLength(FLineNumbers.Cache, LLineNumbersCacheLength);

    if LCompareMode then
      SetLength(FCompareLineNumberOffsetCache, LLineNumbersCacheLength);

    LCurrentLine := 1;
    LCacheLength := 1;
    LCompareOffset := 0;

    for LIndex := 1 to FLines.Count do
    begin
      while (LCurrentLine <= FLines.Count) and LCollapsedCodeFolding[LCurrentLine] do { Skip collapsed lines }
        Inc(LCurrentLine);

      if LCurrentLine > FLines.Count then
        Break;

      if FWordWrap.Active then
        AddWrappedLineNumberIntoCache
      else
        AddLineNumberIntoCache;

      Inc(LCurrentLine);

      if LCompareMode then
      begin
        if sfEmptyLine in FLines.Items^[LIndex - 1].Flags then
          Inc(LCompareOffset);

        FCompareLineNumberOffsetCache[LIndex] := LCompareOffset;
      end;
    end;

    if LCacheLength <> Length(FLineNumbers.Cache) then
    begin
      SetLength(FLineNumbers.Cache, LCacheLength);

      if FWordWrap.Active then
      begin
        SetLength(FWordWrapLine.Length, LCacheLength);
        SetLength(FWordWrapLine.ViewLength, LCacheLength);
        SetLength(FWordWrapLine.Width, LCacheLength);
      end;
    end;

    SetLength(LCollapsedCodeFolding, 0);
    FLineNumbers.Count := Length(FLineNumbers.Cache) - 1;
  end;
end;

procedure TCustomTextEditor.CreateShadowBitmap(const AClipRect: TRect; const ABitmap: Vcl.Graphics.TBitmap;
  const AShadowAlphaArray: TTextEditorArrayOfSingle; const AShadowAlphaByteArray: PByteArray);
var
  LRow, LColumn: Integer;
  LPixel: PTextEditorQuadColor;
  LAlpha: Single;
begin
  ABitmap.Height := 0; { background color }
  ABitmap.Height := AClipRect.Height; //FI:W508 Variable is assigned twice successively

  for LRow := 0 to ABitmap.Height - 1 do
  begin
    LPixel := ABitmap.Scanline[LRow];

    for LColumn := 0 to ABitmap.Width - 1 do
    begin
      LAlpha := AShadowAlphaArray[LColumn];
      LPixel.Alpha := AShadowAlphaByteArray[LColumn];
      LPixel.Red := Round(LPixel.Red * LAlpha);
      LPixel.Green := Round(LPixel.Green * LAlpha);
      LPixel.Blue := Round(LPixel.Blue * LAlpha);
      Inc(LPixel);
    end;
  end;
end;

function TCustomTextEditor.ViewPositionToPixels(const AViewPosition: TTextEditorViewPosition;
  const ALineText: string = ''): TPoint;
var
  LPositionY: Integer;
  LLineText, LToken, LNextTokenText: string;
  LHighlighterAttribute: TTextEditorHighlighterAttribute;
  LFontStyles, LPreviousFontStyles: TFontStyles;
  LTokenLength, LLength: Integer;
  LCharsBefore: Integer;
  LRow, LCurrentRow: Integer;
begin
  LRow := AViewPosition.Row;
  LPositionY := LRow - FLineNumbers.TopLine;
  Result.Y := LPositionY * GetLineHeight;

  if FRuler.Visible then
    Inc(Result.Y, FRuler.Height);

  Result.X := 0;

  if FWordWrap.Active then
    LRow := GetViewTextLineNumber(LRow);

  if LRow = 1 then
    FHighlighter.ResetRange
  else
    FHighlighter.SetRange(FLines.Ranges[LRow - 2]);

  if ALineText = '' then
    LLineText := FLines.ExpandedStrings[LRow - 1]
  else
    LLineText := ALineText;

  FHighlighter.SetLine(LLineText);

  LCurrentRow := AViewPosition.Row;

  if FWordWrap.Active then
  while (LCurrentRow > 1) and (GetViewTextLineNumber(LCurrentRow - 1) = LRow) do
    Dec(LCurrentRow);

  LLength := 0;
  LCharsBefore := 0;
  LFontStyles := [];
  LPreviousFontStyles := [];

  while not FHighlighter.EndOfLine do
  begin
    if LNextTokenText = '' then
      FHighlighter.GetToken(LToken)
    else
      LToken := LNextTokenText;

    LNextTokenText := '';

    LHighlighterAttribute := FHighlighter.TokenAttribute;
    if Assigned(LHighlighterAttribute) then
      LFontStyles := LHighlighterAttribute.FontStyles;

    if LFontStyles <> LPreviousFontStyles then
    begin
      FPaintHelper.SetStyle(LFontStyles);
      LPreviousFontStyles := LFontStyles;
    end;

    LTokenLength := Length(LToken);

    if FWordWrap.Active then
      if (LCurrentRow < AViewPosition.Row) and (LLength + LTokenLength > FWordWrapLine.Length[LCurrentRow]) then
      begin
        LNextTokenText := Copy(LToken, FWordWrapLine.Length[LCurrentRow] - LLength + 1, LTokenLength);
        LTokenLength := FWordWrapLine.Length[LCurrentRow] - LLength;
        LToken := Copy(LToken, 1, LTokenLength);

        Inc(LCurrentRow);
        LLength := 0;
        Inc(LCharsBefore, GetTokenCharCount(LToken, LCharsBefore));

        Continue;
      end;

    if LCurrentRow = AViewPosition.Row then
    begin
      if LLength + LTokenLength >= AViewPosition.Column - 1 then
      begin
        if FHighlighter.RightToLeftToken then
        begin
          Inc(Result.X, GetTokenWidth(LToken, LTokenLength, LCharsBefore, False, True));
          Dec(Result.X, GetTokenWidth(LToken, AViewPosition.Column - LLength - 1, LCharsBefore, False, True));
        end
        else
          Inc(Result.X, GetTokenWidth(LToken, AViewPosition.Column - LLength - 1, LCharsBefore));

        Inc(LLength, LTokenLength);

        Break;
      end;

      Inc(Result.X, GetTokenWidth(LToken, Length(LToken), LCharsBefore));
    end;

    Inc(LLength, LTokenLength);
    Inc(LCharsBefore, GetTokenCharCount(LToken, LCharsBefore));

    FHighlighter.Next;
  end;

  if LLength < AViewPosition.Column then
    Inc(Result.X, (AViewPosition.Column - LLength - 1) * FPaintHelper.CharWidth);

  Inc(Result.X, FLeftMarginWidth - FScrollHelper.HorizontalPosition);
end;

function TCustomTextEditor.GetViewTextLineNumber(const AViewLineNumber: Integer): Integer;
begin
  Result := AViewLineNumber;

  CreateLineNumbersCache;

  if Assigned(FLineNumbers.Cache) and (Result <= FLineNumbers.Count) then
    Result := FLineNumbers.Cache[Result];
end;

function TCustomTextEditor.WordAtCursor: string;
begin
  Result := WordAtTextPosition(TextPosition);
end;

function TCustomTextEditor.WordAtMouse(const ASelect: Boolean = False): string;
var
  LTextPosition: TTextEditorTextPosition;
begin
  Result := '';

  if GetTextPositionOfMouse(LTextPosition) then
    Result := WordAtTextPosition(LTextPosition, ASelect);
end;

function TCustomTextEditor.IsWordBreakChar(const AChar: Char): Boolean;
begin
  Result := AChar in [TControlCharacters.Null .. TCharacters.Space] + TCharacterSets.WordBreak -
    FHighlighter.ExludedWordBreakCharacters;
end;

function TCustomTextEditor.WordAtTextPosition(const ATextPosition: TTextEditorTextPosition;
  const ASelect: Boolean = False; const AAllowedBrealChars: TSysCharSet = []): string;
var
  LTextLine: string;
  LLength, LChar: Integer;
  LTextPosition: TTextEditorTextPosition;
begin
  Result := '';

  LTextPosition := ATextPosition;
  if (LTextPosition.Line >= 0) and (LTextPosition.Line < FLines.Count) then
  begin
    LTextLine := FLines.Items^[LTextPosition.Line].TextLine;

    LLength := Length(LTextLine);
    if LLength = 0 then
      Exit;

    if (LTextPosition.Char >= 1) and (LTextPosition.Char <= LLength) and
      not IsWordBreakChar(LTextLine[LTextPosition.Char]) then
    begin
      LChar := LTextPosition.Char;

      while (LChar <= LLength) and not IsWordBreakChar(LTextLine[LChar]) do
        Inc(LChar);

      while (LTextPosition.Char > 1) and (not IsWordBreakChar(LTextLine[LTextPosition.Char - 1]) or
        (LTextLine[LTextPosition.Char - 1] in AAllowedBrealChars)) do
        Dec(LTextPosition.Char);

      if soExpandRealNumbers in FSelection.Options then
      while (LTextPosition.Char > 0) and (LTextLine[LTextPosition.Char - 1] in TCharacterSets.RealNumbers) do
        Dec(LTextPosition.Char);

      if soExpandPrefix in FSelection.Options then
      while (LTextPosition.Char > 0) and CharInString(LTextLine[LTextPosition.Char - 1], FSelection.PrefixCharacters) do
        Dec(LTextPosition.Char);

      if LChar > LTextPosition.Char then
        Result := Copy(LTextLine, LTextPosition.Char, LChar - LTextPosition.Char);

      if ASelect then
      begin
        FPosition.BeginSelection.Char := LTextPosition.Char;
        FPosition.BeginSelection.Line := LTextPosition.Line;
        FPosition.EndSelection.Char := LChar;
        FPosition.EndSelection.Line := LTextPosition.Line;
      end;
    end;
  end;
end;

function TCustomTextEditor.GetVisibleChars(const ARow: Integer; const ALineText: string = ''): Integer;
var
  LRect: TRect;
begin
  LRect := ClientRect;
  DeflateMinimapAndSearchMapRect(LRect);

  Result := PixelAndRowToViewPosition(LRect.Right, ARow, ALineText).Column;

  if FWordWrap.Active and (FWordWrap.Width = wwwRightMargin) then
    Result := FRightMargin.Position;
end;

function TCustomTextEditor.IsCommentAtCaretPosition: Boolean;
var
  LIndex: Integer;
  LTextPosition: TTextEditorTextPosition;
  LCommentAtCursor: string;

  function CheckComment(const AComment: string): Boolean;
  var
    LPComment, LPCommentAtCursor: PChar;
  begin
    LPComment := PChar(AComment);
    LPCommentAtCursor := PChar(LCommentAtCursor);

    while (LPComment^ <> TControlCharacters.Null) and (LPCommentAtCursor^ <> TControlCharacters.Null) and
      (LPCommentAtCursor^ = LPComment^) do
    begin
      Inc(LPComment);
      Inc(LPCommentAtCursor);
    end;

    Result := LPComment^ = TControlCharacters.Null;
  end;

begin
  Result := False;

  if not FCodeFolding.Visible or FCodeFolding.TextFolding.Active then
    Exit;

  if Assigned(FHighlighter) and (Length(FHighlighter.Comments.BlockComments) = 0) and
    (Length(FHighlighter.Comments.LineComments) = 0) then
    Exit;

  if Assigned(FHighlighter) then
  begin
    LTextPosition := FPosition.Text;

    Dec(LTextPosition.Char);
    GetCommentAtTextPosition(LTextPosition, LCommentAtCursor);

    if LCommentAtCursor <> '' then
    begin
      LIndex := 0;
      while LIndex < Length(FHighlighter.Comments.BlockComments) do
      begin
        if CheckComment(FHighlighter.Comments.BlockComments[LIndex]) then
          Exit(True);

        if CheckComment(FHighlighter.Comments.BlockComments[LIndex + 1]) then
          Exit(True);

        Inc(LIndex, 2);
      end;

      for LIndex := 0 to Length(FHighlighter.Comments.LineComments) - 1 do
      if CheckComment(FHighlighter.Comments.LineComments[LIndex]) then
        Exit(True);
    end;
  end;
end;

function TCustomTextEditor.IsKeywordAtCaretPosition(const APOpenKeyWord: PBoolean = nil): Boolean;
var
  LIndex1, LIndex2: Integer;
  LFoldRegion: TTextEditorCodeFoldingRegion;
  LFoldRegionItem: TTextEditorCodeFoldingRegionItem;
  LCaretPosition: TTextEditorTextPosition;
  LLineText: string;
  LPLine: PChar;

  function CheckToken(const AKeyword: string; const ABeginWithBreakChar: Boolean): Boolean;
  var
    LPWordAtCursor: PChar;

    function AreKeywordsSame(APKeyword: PChar): Boolean;
    begin
      while (APKeyword^ <> TControlCharacters.Null) and (LPWordAtCursor^ <> TControlCharacters.Null) and
        (CaseUpper(LPWordAtCursor^) = APKeyword^) do
      begin
        Inc(APKeyword);
        Inc(LPWordAtCursor);
      end;

      Result := APKeyword^ = TControlCharacters.Null;
    end;

  begin
    Result := False;

    LPWordAtCursor := LPLine;
    if ABeginWithBreakChar then
      Dec(LPWordAtCursor);

    if AreKeywordsSame(PChar(AKeyword)) then
      Result := True;

    if Result and Assigned(APOpenKeyWord) then
      APOpenKeyWord^ := True;
  end;

begin
  Result := False;

  if not FCodeFolding.Visible or FCodeFolding.TextFolding.Active or
    Assigned(FHighlighter) and (Length(FHighlighter.CodeFoldingRegions) = 0) then
    Exit;

  if Assigned(FHighlighter) then
  begin
    LCaretPosition := FPosition.Text;

    LLineText := FLines[LCaretPosition.Line];

    if TextEditor.Utils.Trim(LLineText) = '' then
      Exit;

    LPLine := PChar(LLineText);

    Inc(LPLine, LCaretPosition.Char - 2);
    if not IsWordBreakChar(LPLine^) then
    begin
      while not IsWordBreakChar(LPLine^) and (LCaretPosition.Char > 0) do
      begin
        Dec(LPLine);
        Dec(LCaretPosition.Char);
      end;

      Inc(LPLine);
    end;

    for LIndex1 := 0 to Length(FHighlighter.CodeFoldingRegions) - 1 do
    begin
      LFoldRegion := FHighlighter.CodeFoldingRegions[LIndex1];

      for LIndex2 := 0 to LFoldRegion.Count - 1 do
      begin
        LFoldRegionItem := LFoldRegion.Items[LIndex2];
        if CheckToken(LFoldRegionItem.OpenToken, LFoldRegionItem.BeginWithBreakChar) then
          Exit(True);

        if LFoldRegionItem.OpenTokenCanBeFollowedBy <> '' then
          if CheckToken(LFoldRegionItem.OpenTokenCanBeFollowedBy, LFoldRegionItem.BeginWithBreakChar) then
            Exit(True);

        if CheckToken(LFoldRegionItem.CloseToken, LFoldRegionItem.BeginWithBreakChar) then
          Exit(True);
      end;
    end;
  end;
end;

function TCustomTextEditor.IsKeywordAtCaretPositionOrAfter(const ATextPosition: TTextEditorTextPosition): Boolean;
var
  LIndex1, LIndex2: Integer;
  LLineText: string;
  LFoldRegion: TTextEditorCodeFoldingRegion;
  LFoldRegionItem: TTextEditorCodeFoldingRegionItem;
  LPKeyWord, LPBookmarkText, LPText, LPLine: PChar;
  LCaretPosition: TTextEditorTextPosition;

  function IsWholeWord(const AFirstChar: PChar; const ALastChar: PChar): Boolean; inline;
  begin
    Result := not (AFirstChar^ in TCharacterSets.ValidKeyword) and not (ALastChar^ in TCharacterSets.ValidKeyword);
  end;

begin
  Result := False;

  if not FCodeFolding.Visible or FCodeFolding.TextFolding.Active or
    Assigned(FHighlighter) and (Length(FHighlighter.CodeFoldingRegions) = 0) then
    Exit;

  LCaretPosition := ATextPosition;

  LLineText := FLines[LCaretPosition.Line];

  if TextEditor.Utils.Trim(LLineText) = '' then
    Exit;

  LPLine := PChar(LLineText);

  if LCaretPosition.Char > 1 then
    Inc(LPLine, LCaretPosition.Char - 2);
  if not IsWordBreakChar(LPLine^) then
  begin
    while not IsWordBreakChar(LPLine^) and (LCaretPosition.Char > 0) do
    begin
      Dec(LPLine);
      Dec(LCaretPosition.Char);
    end;

    Inc(LPLine);
  end;

  if LPLine^ = TControlCharacters.Null then
    Exit;

  if Assigned(FHighlighter) then
  for LIndex1 := 0 to Length(FHighlighter.CodeFoldingRegions) - 1 do
  begin
    LFoldRegion := FHighlighter.CodeFoldingRegions[LIndex1];
    for LIndex2 := 0 to LFoldRegion.Count - 1 do
    begin
      LFoldRegionItem := LFoldRegion.Items[LIndex2];
      LPText := LPLine;

      if LFoldRegionItem.BeginWithBreakChar then
        Dec(LPText);

      while LPText^ <> TControlCharacters.Null do
      begin
        while (LPText^ < TCharacters.ExclamationMark) and (LPText^ <> TControlCharacters.Null) do
          Inc(LPText);

        LPBookmarkText := LPText;
        { Check if the open keyword found }
        LPKeyWord := PChar(LFoldRegionItem.OpenToken);
        while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and
          (CaseUpper(LPText^) = LPKeyWord^) do
        begin
          Inc(LPText);
          Inc(LPKeyWord);
        end;

        if LPKeyWord^ = TControlCharacters.Null then { If found, pop skip region from the stack }
        begin
          if IsWholeWord(LPBookmarkText - 1, LPText) then { Not interested in partial hits }
            Exit(True)
          else
            LPText := LPBookmarkText; { Skip region close not found, return pointer back }
        end
        else
          LPText := LPBookmarkText; { Skip region close not found, return pointer back }

        { Check if the close keyword found }
        LPKeyWord := PChar(LFoldRegionItem.CloseToken);

        while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and
          (CaseUpper(LPText^) = LPKeyWord^) do
        begin
          Inc(LPText);
          Inc(LPKeyWord);
        end;

        if LPKeyWord^ = TControlCharacters.Null then { If found, pop skip region from the stack }
        begin
          if IsWholeWord(LPBookmarkText - 1, LPText) then { Not interested in partial hits }
            Exit(True)
          else
            LPText := LPBookmarkText; { Skip region close not found, return pointer back }
        end
        else
          LPText := LPBookmarkText; { Skip region close not found, return pointer back }

        Inc(LPText);
        { Skip until next word }
        while (LPText^ <> TControlCharacters.Null) and ((LPText - 1)^ in TCharacterSets.ValidKeyword) do
          Inc(LPText);
      end;
    end;
  end;
end;

function TCustomTextEditor.IsMultiEditCaretFound(const ALine: Integer): Boolean;
var
  LIndex: Integer;
begin
  Result := False;
  if (meoShowActiveLine in FCaret.MultiEdit.Options) and Assigned(FMultiCaret.Carets) and (FMultiCaret.Carets.Count > 0) then
  for LIndex := 0 to FMultiCaret.Carets.Count - 1 do
  if PTextEditorViewPosition(FMultiCaret.Carets[LIndex])^.Row = ALine then
    Exit(True);
end;

function TCustomTextEditor.IsWordSelected: Boolean;
var
  LIndex: Integer;
  LLineText: string;
  LPText: PChar;
begin
  Result := False;

  if FPosition.BeginSelection.Line <> FPosition.EndSelection.Line then
    Exit;

  LLineText := FLines[FPosition.BeginSelection.Line];
  if LLineText = '' then
    Exit;

  LPText := PChar(LLineText);
  LIndex := FPosition.BeginSelection.Char;
  Inc(LPText, LIndex - 1);
  while (LPText^ <> TControlCharacters.Null) and (LIndex < FPosition.EndSelection.Char) do
  begin
    if IsWordBreakChar(LPText^) then
      Exit;

    Inc(LPText);
    Inc(LIndex);
  end;
  Result := True;
end;

function TCustomTextEditor.LeftSpaceCount(const ALine: string; const AWantTabs: Boolean = False): Integer;
var
  LPLine: PChar;
begin
  LPLine := PChar(ALine);

  Result := 0;

  if Assigned(LPLine) and (eoAutoIndent in FOptions) then
  while (LPLine^ > TControlCharacters.Null) and (LPLine^ <= TCharacters.Space) do
  begin
    if (LPLine^ = TControlCharacters.Tab) and AWantTabs then
    begin
      if FLines.Columns then
        Inc(Result, FTabs.Width - Result mod FTabs.Width)
      else
        Inc(Result, FTabs.Width)
    end
    else
      Inc(Result);

    Inc(LPLine);
  end;
end;

function TCustomTextEditor.NextWordPosition: TTextEditorTextPosition;
begin
  Result := NextWordPosition(TextPosition);
end;

function TCustomTextEditor.NextWordPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition;
var
  LLine: string;
  LLength: Integer;

  function NextWord(var ATextPosition: TTextEditorTextPosition): Boolean;
  begin
    Inc(ATextPosition.Line);
    ATextPosition.Char := 1;
    LLine := FLines[ATextPosition.Line];
    Result := (LLine = '') or IsWordBreakChar(LLine[ATextPosition.Char]);
  end;

begin
  Result := ATextPosition;

  if (Result.Line >= 0) and (Result.Line < FLines.Count) then
  begin
    LLine := FLines.Items^[Result.Line].TextLine;
    LLength := Length(LLine);

    if Result.Char > LLength then
    begin
      if NextWord(Result) then
        Result := NextWordPosition(Result);
    end
    else
    begin
      while (Result.Char <= LLength) and not IsWordBreakChar(LLine[Result.Char]) do
        Inc(Result.Char);

      if (Result.Char > LLength + 1) and (Result.Line < FLines.Count) then
      begin
        if NextWord(Result) then
          Result := NextWordPosition(Result);
      end
      else
      while (Result.Char <= LLength) and IsWordBreakChar(LLine[Result.Char]) do
        Inc(Result.Char);
    end;
  end
  else
  if not GetSelectionAvailable then
  begin
    Result.Line := 0;
    Result.Char := 1;
  end;
end;

function TCustomTextEditor.PixelsToViewPosition(const X, Y: Integer): TTextEditorViewPosition;
begin
  Result := PixelAndRowToViewPosition(X, GetSelectedRow(Y));
end;

function TCustomTextEditor.PixelAndRowToViewPosition(const X, ARow: Integer; const ALineText: string = ''): TTextEditorViewPosition;
var
  LToken, LNextTokenText: string;
  LFontStyles, LPreviousFontStyles: TFontStyles;
  LLineText: string;
  LHighlighterAttribute: TTextEditorHighlighterAttribute;
  LXInEditor: Integer;
  LTextWidth, LTokenWidth, LTokenLength, LPreviousCharCount, LCharCount: Integer;
  LPToken: PChar;
  LCharsBefore: Integer;
  LRow, LCurrentRow: Integer;
  LLength: Integer;
begin
  Result.Row := ARow;
  Result.Column := 1;

  if (FScrollHelper.HorizontalPosition = 0) and (X < FLeftMarginWidth) then
    Exit;

  LRow := ARow;
  if FWordWrap.Active then
    LRow := GetViewTextLineNumber(LRow);

  if ALineText = '' then
    LLineText := FLines.ExpandedStrings[LRow - 1]
  else
    LLineText := ALineText;

  if LRow = 1 then
    FHighlighter.ResetRange
  else
    FHighlighter.SetRange(FLines.Ranges[LRow - 2]);
  FHighlighter.SetLine(LLineText);

  LCurrentRow := ARow;

  if FWordWrap.Active then
  while (LCurrentRow > 1) and (GetViewTextLineNumber(LCurrentRow - 1) = LRow) do
    Dec(LCurrentRow);

  LFontStyles := [];
  LPreviousFontStyles := [];
  LTextWidth := 0;
  LCharsBefore := 0;
  LXInEditor := X + FScrollHelper.HorizontalPosition - FLeftMarginWidth + 4;
  LLength := 0;

  LHighlighterAttribute := FHighlighter.TokenAttribute;
  if Assigned(LHighlighterAttribute) then
    LPreviousFontStyles := LHighlighterAttribute.FontStyles;
  FPaintHelper.SetStyle(LPreviousFontStyles);
  while not FHighlighter.EndOfLine do
  begin
    if LNextTokenText = '' then
      FHighlighter.GetToken(LToken)
    else
      LToken := LNextTokenText;

    LNextTokenText := '';

    LTokenLength := Length(LToken);
    LHighlighterAttribute := FHighlighter.TokenAttribute;
    if Assigned(LHighlighterAttribute) then
      LFontStyles := LHighlighterAttribute.FontStyles;
    if LFontStyles <> LPreviousFontStyles then
    begin
      FPaintHelper.SetStyle(LFontStyles);
      LPreviousFontStyles := LFontStyles;
    end;

    if FWordWrap.Active then
      if LCurrentRow < ARow then
        if LLength + LTokenLength > FWordWrapLine.Length[LCurrentRow] then
        begin
          LNextTokenText := Copy(LToken, FWordWrapLine.Length[LCurrentRow] - LLength + 1, LTokenLength);
          LTokenLength := FWordWrapLine.Length[LCurrentRow] - LLength;
          LToken := Copy(LToken, 1, LTokenLength);

          Inc(LCurrentRow);
          LLength := 0;
          LTextWidth := 0;
          Inc(LCharsBefore, GetTokenCharCount(LToken, LCharsBefore));

          Continue;
        end;

    if LCurrentRow = ARow then
    begin
      LTokenWidth := GetTokenWidth(LToken, LTokenLength, LCharsBefore);
      if (LXInEditor > 0) and (LTextWidth + LTokenWidth > LXInEditor) then
      begin
        LPToken := PChar(LToken);
        LCharCount := 0;
        LPreviousCharCount := 0;
        LTokenWidth := 0;
        { This is not an optimal solution but avoids unnecessary complexity. }
        while LTextWidth + LTokenWidth < LXInEditor do
        begin
          LPreviousCharCount := LCharCount;
          Inc(LCharCount);

          while True do
          begin
            Inc(LPToken);
            if (LPToken^ <> TControlCharacters.Null) and IsCombiningCharacter(LPToken) then
              Inc(LCharCount)
            else
              Break;
          end;

          LTokenWidth := GetTokenWidth(LToken, LCharCount, LCharsBefore, False, FHighlighter.RightToLeftToken);
        end;

        if FHighlighter.RightToLeftToken then
          Inc(Result.Column, LTokenLength - LPreviousCharCount)
        else
          Inc(Result.Column, LPreviousCharCount);

        Exit;
      end
      else
      begin
        LTextWidth := LTextWidth + LTokenWidth;
        Inc(Result.Column, LTokenLength);
      end;
    end;

    Inc(LLength, LTokenLength);
    Inc(LCharsBefore, GetTokenCharCount(LToken, LCharsBefore));

    FHighlighter.Next;
  end;

  if not FWordWrap.Active then
    Inc(Result.Column, (X + FScrollHelper.HorizontalPosition - FLeftMarginWidth - LTextWidth) div FPaintHelper.CharWidth);
end;

function TCustomTextEditor.PixelsToTextPosition(const X, Y: Integer): TTextEditorTextPosition;
var
  LViewPosition: TTextEditorViewPosition;
  LWordWrapLineLength: Integer;
begin
  LViewPosition := PixelsToViewPosition(X, Y);
  LViewPosition.Row := EnsureRange(LViewPosition.Row, 1, Max(FLineNumbers.Count, 1));
  if FWordWrap.Active then
  begin
    LWordWrapLineLength := FWordWrapLine.ViewLength[LViewPosition.Row];
    if LWordWrapLineLength <> 0 then
      LViewPosition.Column := EnsureRange(LViewPosition.Column, 1, LWordWrapLineLength + 1);
  end;
  Result := ViewToTextPosition(LViewPosition);
end;

function TCustomTextEditor.PreviousWordPosition: TTextEditorTextPosition;
begin
  Result := PreviousWordPosition(TextPosition);
end;

function TCustomTextEditor.PreviousWordPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition;
var
  LLine: string;
begin
  Result := ATextPosition;

  if (Result.Line >= 0) and (Result.Line < FLines.Count) then
  begin
    LLine := FLines.Items^[Result.Line].TextLine;
    Result.Char := Min(Result.Char, Length(LLine)) - 1;

    if Result.Char <= 1 then
    begin
      if Result.Line > 0 then
        Dec(Result.Line)
      else
      if not GetSelectionAvailable then
        Result.Line := FLines.Count - 1;

      Result.Char := Length(FLines.Items^[Result.Line].TextLine) + 1;
    end
    else
    begin
      while (Result.Char > 0) and IsWordBreakChar(LLine[Result.Char]) do
        Dec(Result.Char);

      if (Result.Char = 0) and (Result.Line > 0) then
      begin
        Dec(Result.Line);
        Result.Char := Length(FLines.Items^[Result.Line].TextLine);
        Result := PreviousWordPosition(Result);
      end
      else
      begin
        while (Result.Char > 1) and not IsWordBreakChar(LLine[Result.Char]) do
          Dec(Result.Char);

        if Result.Char > 1 then
          Inc(Result.Char)
      end;
    end;
  end;
end;

function TCustomTextEditor.ScanHighlighterRangesFrom(const AIndex: Integer): Integer;
var
  LRange: TTextEditorRange;
  LProgress, LProgressInc: Int64;
begin
  Result := AIndex;

  if Result > FLines.Count then
    Exit;

  if Result = 0 then
    FHighlighter.ResetRange
  else
    FHighlighter.SetRange(FLines.Ranges[Result - 1]);

  LProgress := 0;
  LProgressInc := 0;
  if FLines.ShowProgress then
  begin
    FLines.ProgressPosition := 0;
    FLines.ProgressType := ptProcessing;
    LProgressInc := FLines.Count div 100;
  end;

  repeat
    with FLines.Items^[Result] do
    begin
      FHighlighter.SetLine(TextLine);
      FHighlighter.NextToEndOfLine;
      LRange := FHighlighter.Range;

      if Range = LRange then
        Exit;

      Range := LRange;
    end;

    Inc(Result);

    if FLines.ShowProgress then
    begin
      if Result > LProgress then
      begin
        FLines.ProgressPosition := FLines.ProgressPosition + 1;

        if Assigned(FEvents.OnLoadingProgress) then
          FEvents.OnLoadingProgress(Self)
        else
          Paint;

        Inc(LProgress, LProgressInc);
      end;
    end;

  until Result >= FLines.Count;

  Dec(Result);
end;

function TCustomTextEditor.TextPositionToCharIndex(const ATextPosition: TTextEditorTextPosition): Integer;
var
  LIndex: Integer;
  LLine: Integer;
  LItem: TTextEditorStringRecord;
begin
  Result := 0;

  LLine := Min(FLines.Count, ATextPosition.Line) - 1;
  for LIndex := 0 to LLine do
  begin
    LItem := FLines.Items^[LIndex];
    Inc(Result, Length(LItem.TextLine));

    if sfLineBreakCR in LItem.Flags then
      Inc(Result);

    if sfLineBreakLF in LItem.Flags then
      Inc(Result);
  end;
  Inc(Result, ATextPosition.Char - 1);
end;

procedure TCustomTextEditor.ActiveLineChanged(ASender: TObject);
begin
  if not (csLoading in ComponentState) then
    if (ASender is TTextEditorActiveLine) or (ASender is TTextEditorGlyph) then
      Invalidate;
end;

procedure TCustomTextEditor.AssignSearchEngine(const AEngine: TTextEditorSearchEngine);
begin
  if Assigned(FSearchEngine) then
  begin
    FSearchEngine.Free;
    FSearchEngine := nil;
  end;

  case AEngine of
    seNormal, seExtended:
      FSearchEngine := TTextEditorNormalSearch.Create(AEngine = seExtended, FLines.DefaultLineBreak);
    seRegularExpression:
      FSearchEngine := TTextEditorRegexSearch.Create;
    seWildCard:
      FSearchEngine := TTextEditorWildCardSearch.Create;
  end;
end;

procedure TCustomTextEditor.AfterSetText(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  InitCodeFolding;
end;

procedure TCustomTextEditor.BeforeSetText(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  ClearCodeFolding;
end;

procedure TCustomTextEditor.BookmarkListChange(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  Invalidate;
end;

procedure TCustomTextEditor.CaretChanged(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  FreeMultiCarets;
  ResetCaret;
end;

procedure TCustomTextEditor.CheckIfAtMatchingKeywords;
var
  LNewFoldRange: TTextEditorCodeFoldingRange;
  LIsKeyWord, LOpenKeyWord: Boolean;
  LLine: Integer;
begin
  LIsKeyWord := IsKeywordAtCaretPosition(@LOpenKeyWord);

  LNewFoldRange := nil;

  LLine := FPosition.Text.Line + 1;

  if LIsKeyWord and LOpenKeyWord then
    LNewFoldRange := CodeFoldingRangeForLine(LLine)
  else
  if LIsKeyWord and not LOpenKeyWord then
    LNewFoldRange := CodeFoldingFoldRangeForLineTo(LLine);

  if LNewFoldRange <> FHighlightedFoldRange then
    FHighlightedFoldRange := LNewFoldRange;
end;

procedure TCustomTextEditor.CodeFoldingCollapse(const AFoldRange: TTextEditorCodeFoldingRange);
begin
  ClearMatchingPair;
  FLineNumbers.ResetCache := True;

  with AFoldRange do
  begin
    Collapsed := True;
    SetParentCollapsedOfSubCodeFoldingRanges(True, FoldRangeLevel);
  end;

  CheckIfAtMatchingKeywords;
  UpdateScrollBars;
end;

procedure TCustomTextEditor.CodeFoldingLinesDeleted(const AFirstLine: Integer; const ACount: Integer);
var
  LIndex: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  if ACount > 0 then
  begin
    for LIndex := AFirstLine + ACount - 1 downto AFirstLine do
    begin
      LCodeFoldingRange := CodeFoldingRangeForLine(LIndex);
      if Assigned(LCodeFoldingRange) then
        FCodeFoldings.AllRanges.Delete(LCodeFoldingRange);
    end;

    UpdateFoldingRanges(AFirstLine, -ACount);
    LeftMarginChanged(Self);
  end;
end;

procedure TCustomTextEditor.ColorsOnChange(const AEvent: TTextEditorColorChanges);
begin
  if (AEvent = ccBoth) or (AEvent = ccBackground) then
    Color := FColors.Background;

  if (AEvent = ccBoth) or (AEvent = ccForeground) then
    Font.Color := FColors.Foreground;

  Invalidate;
end;

procedure TCustomTextEditor.CodeFoldingResetCaches;
var
  LIndex, LIndexRange, LLength: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  if not FCodeFolding.Visible then
    Exit;

  FCodeFoldings.Exists := False;
  LLength := FLines.Count + 1;
  SetLength(FCodeFoldings.TreeLine, 0);
  SetLength(FCodeFoldings.TreeLine, LLength);
  SetLength(FCodeFoldings.RangeFromLine, 0);
  SetLength(FCodeFoldings.RangeFromLine, LLength);
  SetLength(FCodeFoldings.RangeToLine, 0);
  SetLength(FCodeFoldings.RangeToLine, LLength);

  for LIndex := FCodeFoldings.AllRanges.AllCount - 1 downto 0 do
  begin
    LCodeFoldingRange := FCodeFoldings.AllRanges[LIndex];
    if Assigned(LCodeFoldingRange) then
      if (not LCodeFoldingRange.ParentCollapsed) and ((LCodeFoldingRange.FromLine <> LCodeFoldingRange.ToLine) or
        Assigned(LCodeFoldingRange.RegionItem) and LCodeFoldingRange.RegionItem.TokenEndIsPreviousLine and
        (LCodeFoldingRange.FromLine = LCodeFoldingRange.ToLine)) then
        if (LCodeFoldingRange.FromLine > 0) and (LCodeFoldingRange.FromLine <= LLength) then
        begin
          FCodeFoldings.RangeFromLine[LCodeFoldingRange.FromLine] := LCodeFoldingRange;
          FCodeFoldings.Exists := True;
          if LCodeFoldingRange.Collapsable then
          begin
            for LIndexRange := LCodeFoldingRange.FromLine + 1 to LCodeFoldingRange.ToLine - 1 do
              FCodeFoldings.TreeLine[LIndexRange] := True;

            FCodeFoldings.RangeToLine[LCodeFoldingRange.ToLine] := LCodeFoldingRange;
          end;
        end;
  end;
end;

procedure TCustomTextEditor.CodeFoldingOnChange(const AEvent: TTextEditorCodeFoldingChanges);
begin
  if AEvent = fcVisible then
  begin
    if FCodeFolding.Visible then
      InitCodeFolding
    else
      ExpandAll;
  end;

  FLeftMarginWidth := GetLeftMarginWidth;
  FCodeFoldings.DelayTimer.Interval := FCodeFolding.DelayInterval;

  Invalidate;
end;

procedure TCustomTextEditor.CodeFoldingExpand(const AFoldRange: TTextEditorCodeFoldingRange);
begin
  ClearMatchingPair;

  FLineNumbers.ResetCache := True;

  with AFoldRange do
  begin
    Collapsed := False;
    SetParentCollapsedOfSubCodeFoldingRanges(False, FoldRangeLevel);
  end;

  CheckIfAtMatchingKeywords;
  UpdateScrollBars;
end;

procedure TCustomTextEditor.CompletionProposalTimerHandler(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  FCompletionProposalTimer.Enabled := False;

  DoExecuteCompletionProposal(True);
end;

procedure TCustomTextEditor.ComputeScroll(const APoint: TPoint);
var
  LScrollBounds: TRect;
  LScrollBoundsLeft, LScrollBoundsRight: Integer;
  LCursorIndex: Integer;
begin
  if FMouse.IsScrolling then
  begin
    if not PtInRect(ClientRect, APoint) then
    begin
      FMouse.ScrollTimer.Enabled := False;
      Exit;
    end;

    LCursorIndex := GetMouseScrollCursorIndex;
    case LCursorIndex of
      TMouseWheel.ScrollCursor.NorthWest, TMouseWheel.ScrollCursor.West, TMouseWheel.ScrollCursor.SouthWest:
        FScrollHelper.Delta.X := (APoint.X - FMouse.ScrollingPoint.X) div FPaintHelper.CharWidth - 1;
      TMouseWheel.ScrollCursor.NorthEast, TMouseWheel.ScrollCursor.East, TMouseWheel.ScrollCursor.SouthEast:
        FScrollHelper.Delta.X := (APoint.X - FMouse.ScrollingPoint.X) div FPaintHelper.CharWidth + 1;
    else
      FScrollHelper.Delta.X := 0;
    end;

    case LCursorIndex of
      TMouseWheel.ScrollCursor.NorthWest, TMouseWheel.ScrollCursor.North, TMouseWheel.ScrollCursor.NorthEast:
        FScrollHelper.Delta.Y := (APoint.Y - FMouse.ScrollingPoint.Y) div GetLineHeight - 1;
      TMouseWheel.ScrollCursor.SouthWest, TMouseWheel.ScrollCursor.South, TMouseWheel.ScrollCursor.SouthEast:
        FScrollHelper.Delta.Y := (APoint.Y - FMouse.ScrollingPoint.Y) div GetLineHeight + 1;
    else
      FScrollHelper.Delta.Y := 0;
    end;

    FMouse.ScrollTimer.Enabled := (FScrollHelper.Delta.X <> 0) or (FScrollHelper.Delta.Y <> 0);
  end
  else
  begin
    if not MouseCapture and not Dragging then
    begin
      FScrollHelper.Timer.Enabled := False;
      Exit;
    end;

    LScrollBoundsLeft := FLeftMarginWidth;
    LScrollBoundsRight := LScrollBoundsLeft + FScrollHelper.PageWidth + 4;

    LScrollBounds := Bounds(LScrollBoundsLeft, 0, LScrollBoundsRight, VisibleLineCount * GetLineHeight);

    DeflateMinimapAndSearchMapRect(LScrollBounds);

    if BorderStyle = bsNone then
      InflateRect(LScrollBounds, -2, -2);

    if APoint.X < LScrollBounds.Left then
      FScrollHelper.Delta.X := (APoint.X - LScrollBounds.Left) div FPaintHelper.CharWidth - 1
    else
    if APoint.X >= LScrollBounds.Right then
      FScrollHelper.Delta.X := (APoint.X - LScrollBounds.Right) div FPaintHelper.CharWidth + 1
    else
      FScrollHelper.Delta.X := 0;

    if APoint.Y < LScrollBounds.Top then
      FScrollHelper.Delta.Y := (APoint.Y - LScrollBounds.Top) div GetLineHeight - 1
    else
    if APoint.Y >= LScrollBounds.Bottom then
      FScrollHelper.Delta.Y := (APoint.Y - LScrollBounds.Bottom) div GetLineHeight + 1
    else
      FScrollHelper.Delta.Y := 0;

    FScrollHelper.Timer.Enabled := (FScrollHelper.Delta.X <> 0) or (FScrollHelper.Delta.Y <> 0);
  end;
end;

procedure TCustomTextEditor.DeflateMinimapAndSearchMapRect(var ARect: TRect);
begin
  if FMinimap.Align = maRight then
    ARect.Right := Width - FMinimap.GetWidth
  else
    ARect.Left := FMinimap.GetWidth;

  if FSearch.Map.Align = saRight then
    Dec(ARect.Right, FSearch.Map.GetWidth)
  else
    Inc(ARect.Left, FSearch.Map.GetWidth);
end;

procedure TCustomTextEditor.SetLine(const ALine: Integer; const ALineText: string);
begin
  if eoTrimTrailingSpaces in Options then
    FLines[ALine] := TextEditor.Utils.TrimRight(ALineText)
  else
    FLines[ALine] := ALineText;
end;

procedure TCustomTextEditor.DeleteChar;
var
  LLineText: string;
  LLength: Integer;
  LHelper: string;
  LSpaceBuffer: string;
  LSpaceCount: Integer;
  LTextPosition: TTextEditorTextPosition;
  LWidth: Integer;
  LCharAtCursor: Char;
begin
  LTextPosition := TextPosition;
  LCharAtCursor := GetCharAtTextPosition(GetPosition(LTextPosition.Char + 1, LTextPosition.Line));

  if GetSelectionAvailable then
  begin
    SetSelectedTextEmpty;
    FLineNumbers.ResetCache := True;
  end
  else
  begin
    LLineText := FLines.Items^[LTextPosition.Line].TextLine;
    LLength := Length(LLineText);
    if LTextPosition.Char <= LLength then
    begin
      LHelper := Copy(LLineText, LTextPosition.Char, 1);
      Delete(LLineText, LTextPosition.Char, 1);
      SetLine(LTextPosition.Line, LLineText);
      FUndoList.AddChange(crDelete, LTextPosition, LTextPosition, GetPosition(LTextPosition.Char + 1,
        LTextPosition.Line), LHelper, smNormal);

      if FWordWrap.Active then
      begin
        LWidth := GetTokenWidth(LHelper, 1, 0);
        FWordWrapLine.Length[FViewPosition.Row] := FWordWrapLine.Length[FViewPosition.Row] - 1;
        FWordWrapLine.ViewLength[FViewPosition.Row] := FWordWrapLine.ViewLength[FViewPosition.Row] - 1;
        FWordWrapLine.Width[FViewPosition.Row] := FWordWrapLine.Width[FViewPosition.Row] - LWidth;
        if (LCharAtCursor = TControlCharacters.Tab) or (FWordWrapLine.Length[FViewPosition.Row] <= 0) then
          FLineNumbers.ResetCache := True;
      end;
    end
    else
    if LTextPosition.Line < FLines.Count - 1 then
    begin
      FUndoList.BeginBlock;
      LSpaceCount := LTextPosition.Char - 1 - LLength;
      LSpaceBuffer := StringOfChar(TCharacters.Space, LSpaceCount);

      if LSpaceCount > 0 then
        FUndoList.AddChange(crInsert, LTextPosition, GetPosition(LTextPosition.Char - LSpaceCount,
          LTextPosition.Line), GetPosition(LTextPosition.Char, LTextPosition.Line), '', smNormal);

      with LTextPosition do
      begin
        Char := 1;
        Line := Line + 1;
      end;

      FUndoList.AddChange(crDelete, LTextPosition, TextPosition, LTextPosition,
        FLines.GetLineBreak(LTextPosition.Line), smNormal);

      FLines[LTextPosition.Line - 1] := LLineText + LSpaceBuffer + FLines[LTextPosition.Line];
      FLines.LineState[LTextPosition.Line - 1] := lsModified;
      FLines.Delete(LTextPosition.Line);

      FUndoList.EndBlock;

      FLineNumbers.ResetCache := True;
    end;
  end;
end;

procedure TCustomTextEditor.DeleteLine;
var
  LTextPosition, LTextBeginPosition, LTextEndPosition: TTextEditorTextPosition;
  LTextLine: string;
begin
  LTextPosition := TextPosition;
  FUndoList.BeginBlock;
  try
    FUndoList.AddChange(crCaret, LTextPosition, SelectionBeginPosition, SelectionEndPosition, '', smNormal);

    LTextLine := FLines.Items^[LTextPosition.Line].TextLine;

    if FLines.Count = 1 then
    begin
      LTextBeginPosition := GetPosition(1, LTextPosition.Line);
      LTextEndPosition := GetPosition(Length(FLines.Items^[LTextPosition.Line].TextLine) + 1, LTextPosition.Line);
    end
    else
    if LTextPosition.Line < FLines.Count - 1 then
    begin
      LTextBeginPosition := GetPosition(1, LTextPosition.Line);
      LTextEndPosition := GetPosition(1, LTextPosition.Line + 1);
      LTextLine := LTextLine + FLines.DefaultLineBreak
    end
    else
    begin
      LTextBeginPosition := GetPosition(FLines.StringLength(LTextPosition.Line - 1) + 1,
        Max(LTextPosition.Line - 1, 0));
      LTextEndPosition := GetPosition(Length(LTextLine) + 1, LTextPosition.Line);
      LTextLine := FLines.DefaultLineBreak + LTextLine;
    end;

    FLines.BeginUpdate;
    FLines.Delete(LTextPosition.Line);
    FLines.EndUpdate;

    LTextPosition.Line := Max(LTextPosition.Line, 0);
    LTextPosition.Char := 1;
    TextPosition := LTextPosition;

    FUndoList.AddChange(crDelete, LTextPosition, LTextBeginPosition, LTextEndPosition, LTextLine, smNormal);
  finally
    FUndoList.EndBlock;
  end;
end;

procedure TCustomTextEditor.DeleteText(const ACommand: TTextEditorCommand);
var
  LLineText: string;
  LTextPosition, LSelectionBeginPosition, LSelectionEndPosition: TTextEditorTextPosition;
  LBeginCaretPosition: TTextEditorTextPosition;
  LEndCaretPosition: TTextEditorTextPosition;
  LHelper: string;

  function DeleteWord(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition;
  var
    LLine: string;
    LPChar: PChar;

    function SelectNextLine(var ATextPosition: TTextEditorTextPosition): Boolean;
    begin
      Result := True;

      if not Assigned(LPChar) or (LPChar^ = TControlCharacters.Null) then
      begin
        if ATextPosition.Line + 1 < FLines.Count then
        begin
          Inc(ATextPosition.Line);
          ATextPosition.Char := 1;
        end;

        Exit;
      end;

      Result := False;
    end;

  begin
    Result := ATextPosition;

    if (Result.Char >= 1) and (Result.Line < FLines.Count) then
    begin
      LLine := FLines.Items^[Result.Line].TextLine;

      LPChar := PChar(@LLine[Result.Char]);

      if SelectNextLine(Result) then
        Exit;

      if IsWordBreakChar(LPChar^) then
      begin
        while (LPChar^ <> TControlCharacters.Null) and IsWordBreakChar(LPChar^) do
        begin
          Inc(LPChar);
          Inc(Result.Char)
        end;

        SelectNextLine(Result);
      end
      else
      while (LPChar^ <> TControlCharacters.Null) and not IsWordBreakChar(LPChar^) do
      begin
        Inc(LPChar);
        Inc(Result.Char)
      end;
    end;
  end;

begin
  LTextPosition := TextPosition;
  LBeginCaretPosition := LTextPosition;
  LSelectionBeginPosition := SelectionBeginPosition;
  LSelectionEndPosition := SelectionEndPosition;

  LLineText := FLines.Items^[LBeginCaretPosition.Line].TextLine;
  if ACommand = TKeyCommands.DeleteWord then
  begin
    LBeginCaretPosition := LTextPosition;
    LEndCaretPosition := DeleteWord(LBeginCaretPosition);
  end
  else
  if ACommand = TKeyCommands.DeleteWordBackward then
  begin
    LBeginCaretPosition := WordStart;
    LEndCaretPosition := LTextPosition;
  end
  else
  if ACommand = TKeyCommands.DeleteWordForward then
  begin
    LBeginCaretPosition := LTextPosition;
    LEndCaretPosition := WordEnd(LBeginCaretPosition);
  end
  else
  if ACommand = TKeyCommands.DeleteBeginningOfLine then
  begin
    LBeginCaretPosition.Char := 1;
    LEndCaretPosition := LTextPosition;
  end
  else
  begin
    LEndCaretPosition.Char := Length(LLineText) + 1;
    LEndCaretPosition.Line := LBeginCaretPosition.Line;
  end;

  if not IsSamePosition(LBeginCaretPosition, LEndCaretPosition) then
  begin
    FUndoList.BeginBlock;
    try
      SetSelectionBeginPosition(LBeginCaretPosition);
      SetSelectionEndPosition(LEndCaretPosition);
      FSelection.ActiveMode := smNormal;
      LHelper := SelectedText;

      DoSelectedText('');

      FUndoList.AddChange(crSelection, LTextPosition, LSelectionBeginPosition, LSelectionEndPosition, '', smNormal);
      FUndoList.AddChange(crDelete, LBeginCaretPosition, LBeginCaretPosition, LEndCaretPosition, LHelper, smNormal);
    finally
      FUndoList.EndBlock;
      SelectionEndPosition := SelectionBeginPosition;
    end;
  end;
end;

procedure TCustomTextEditor.DoBackspace;
var
  LLineText: string;
  LLength: Integer;
  LHelper: string;
  LSpaceCount1, LSpaceCount2: Integer;
  LVisualSpaceCount1, LVisualSpaceCount2: Integer;
  LBackCounterLine: Integer;
  LCaretNewPosition: TTextEditorTextPosition;
  LFoldRange: TTextEditorCodeFoldingRange;
  LCharPosition: Integer;
  LSpaceBuffer: string;
  LChar: Char;
  LTextPosition: TTextEditorTextPosition;
  LViewPosition: TTextEditorViewPosition;
  LWidth: Integer;
  LCharAtCursor: Char;
begin
  LTextPosition := TextPosition;
  LCharAtCursor := GetCharAtTextPosition(GetPosition(LTextPosition.Char, LTextPosition.Line));

  FUndoList.BeginBlock;
  FUndoList.AddChange(crCaret, LTextPosition, SelectionBeginPosition, SelectionEndPosition, '', smNormal);
  if GetSelectionAvailable then
  begin
    if FSyncEdit.Visible then
    begin
      if LTextPosition.Char < FSyncEdit.EditBeginPosition.Char then
        Exit;
      FSyncEdit.MoveEndPositionChar(-FPosition.EndSelection.Char + FPosition.BeginSelection.Char);
    end;

    SetSelectedTextEmpty;
    FLineNumbers.ResetCache := True;
  end
  else
  begin
    if FSyncEdit.Visible then
    begin
      if LTextPosition.Char <= FSyncEdit.EditBeginPosition.Char then
        Exit;
      FSyncEdit.MoveEndPositionChar(-1);
    end;

    LLineText := FLines[LTextPosition.Line];
    LLength := Length(LLineText);
    if LTextPosition.Char > LLength + 1 then
    begin
      LHelper := '';
      if LLength > 0 then
        SetTextCaretX(LLength + 1)
      else
      begin
        LSpaceCount1 := LTextPosition.Char - 1;
        LSpaceCount2 := 0;
        if LSpaceCount1 > 0 then
        begin
          LBackCounterLine := LTextPosition.Line;
          if (eoTrimTrailingSpaces in Options) and (LLength = 0) then
          while LBackCounterLine >= 0 do
          begin
            LSpaceCount2 := LeftSpaceCount(FLines[LBackCounterLine], True);

            if LSpaceCount2 < LSpaceCount1 then
              Break;

            Dec(LBackCounterLine);
          end
          else
          while LBackCounterLine >= 0 do
          begin
            LSpaceCount2 := LeftSpaceCount(FLines[LBackCounterLine]);

            if LSpaceCount2 < LSpaceCount1 then
              Break;

            Dec(LBackCounterLine);
          end;

          if (LBackCounterLine = -1) and (LSpaceCount2 > LSpaceCount1) then
            LSpaceCount2 := 0;
        end;

        if LSpaceCount2 = LSpaceCount1 then
          LSpaceCount2 := 0;

        SetTextCaretX(LTextPosition.Char - (LSpaceCount1 - LSpaceCount2));
        Include(FState.Flags, sfCaretChanged);
        FLineNumbers.ResetCache := True;
      end;
    end
    else
    if LTextPosition.Char = 1 then
    begin
      if LTextPosition.Line > 0 then
      begin
        LCaretNewPosition.Line := LTextPosition.Line - 1;
        LCaretNewPosition.Char := Length(FLines[LTextPosition.Line - 1]) + 1;

        FUndoList.AddChange(crDelete, LTextPosition, LCaretNewPosition, LTextPosition,
          FLines.GetLineBreak(LTextPosition.Line), smNormal);

        FLines.BeginUpdate;

        if eoTrimTrailingSpaces in Options then
          LLineText := TextEditor.Utils.TrimRight(LLineText);

        FLines[LCaretNewPosition.Line] := FLines.Items^[LCaretNewPosition.Line].TextLine + LLineText;
        FLines.Delete(LTextPosition.Line);

        FLines.EndUpdate;

        LHelper := FLines.DefaultLineBreak;

        LViewPosition := TextToViewPosition(LCaretNewPosition);

        LFoldRange := CodeFoldingFoldRangeForLineTo(LViewPosition.Row);
        if Assigned(LFoldRange) and LFoldRange.Collapsed then
        begin
          LCaretNewPosition.Line := LFoldRange.FromLine - 1;
          Inc(LCaretNewPosition.Char, Length(FLines.Items^[LCaretNewPosition.Line].TextLine) + 1);
        end;

        TextPosition := LCaretNewPosition;
        FLineNumbers.ResetCache := True;
      end;
    end
    else
    begin
      LSpaceCount1 := LeftSpaceCount(LLineText);
      LSpaceCount2 := 0;
      if (LLineText[LTextPosition.Char - 1] <= TCharacters.Space) and
        (LSpaceCount1 = LTextPosition.Char - 1) then
      begin
        LVisualSpaceCount1 := GetLeadingExpandedLength(LLineText);
        LVisualSpaceCount2 := 0;
        LBackCounterLine := LTextPosition.Line - 1;

        while LBackCounterLine >= 0 do
        begin
          LVisualSpaceCount2 := GetLeadingExpandedLength(FLines.Items^[LBackCounterLine].TextLine);

          if LVisualSpaceCount2 < LVisualSpaceCount1 then
          begin
            LSpaceCount2 := LeftSpaceCount(FLines.Items^[LBackCounterLine].TextLine);
            Break;
          end;

          Dec(LBackCounterLine);
        end;

        if (LBackCounterLine = -1) and (LSpaceCount2 > LSpaceCount1) then
          LSpaceCount2 := 0;

        if LSpaceCount2 = LSpaceCount1 then
          LSpaceCount2 := 0;

        if LSpaceCount2 > 0 then
        begin
          LCharPosition := LTextPosition.Char - 2;
          LLength := GetLeadingExpandedLength(LLineText, LCharPosition);

          while (LCharPosition > 0) and (LLength > LVisualSpaceCount2) do
          begin
            Dec(LCharPosition);
            LLength := GetLeadingExpandedLength(LLineText, LCharPosition);
          end;

          LHelper := Copy(LLineText, LCharPosition + 1, LSpaceCount1 - LCharPosition);
          Delete(LLineText, LCharPosition + 1, LSpaceCount1 - LCharPosition);

          FUndoList.AddChange(crDelete, LTextPosition, GetPosition(LCharPosition + 1,
            LTextPosition.Line), LTextPosition, LHelper, smNormal);

          LSpaceBuffer := '';
          if LVisualSpaceCount2 - LLength > 0 then
            LSpaceBuffer := StringOfChar(TCharacters.Space, LVisualSpaceCount2 - LLength);

          Insert(LSpaceBuffer, LLineText, LCharPosition + 1);
          SetTextCaretX(LCharPosition + Length(LSpaceBuffer) + 1);
        end
        else
        begin
          LVisualSpaceCount2 := LVisualSpaceCount1 - (LVisualSpaceCount1 mod FTabs.Width);

          if LVisualSpaceCount2 = LVisualSpaceCount1 then
            LVisualSpaceCount2 := Max(LVisualSpaceCount2 - FTabs.Width, 0);

          LCharPosition := LTextPosition.Char - 2;
          LLength := GetLeadingExpandedLength(LLineText, LCharPosition);
          while (LCharPosition > 0) and (LLength > LVisualSpaceCount2) do
          begin
            Dec(LCharPosition);
            LLength := GetLeadingExpandedLength(LLineText, LCharPosition);
          end;

          LHelper := Copy(LLineText, LCharPosition + 1, LSpaceCount1 - LCharPosition);
          Delete(LLineText, LCharPosition + 1, LSpaceCount1 - LCharPosition);
          FUndoList.AddChange(crDelete, LTextPosition, GetPosition(LCharPosition + 1,
            LTextPosition.Line), LTextPosition, LHelper, smNormal);
          SetTextCaretX(LCharPosition + 1);
        end;
        FLines[LTextPosition.Line] := LLineText;
        Include(FState.Flags, sfCaretChanged);
        FLineNumbers.ResetCache := True;
      end
      else
      begin
        LChar := LLineText[LTextPosition.Char - 1];
        LCharPosition := 1;
        if LChar.IsSurrogate then
          LCharPosition := 2;
        LHelper := Copy(LLineText, LTextPosition.Char - LCharPosition, LCharPosition);
        FUndoList.AddChange(crDelete, LTextPosition, GetPosition(LTextPosition.Char - LCharPosition,
          LTextPosition.Line), LTextPosition, LHelper, smNormal);

        Delete(LLineText, LTextPosition.Char - LCharPosition, LCharPosition);
        FLines[LTextPosition.Line] := LLineText;

        if FWordWrap.Active then
        begin
          LWidth := GetTokenWidth(LHelper, 1, 0);
          FWordWrapLine.Length[FViewPosition.Row] := FWordWrapLine.Length[FViewPosition.Row] - 1;
          FWordWrapLine.ViewLength[FViewPosition.Row] := FWordWrapLine.ViewLength[FViewPosition.Row] -
            GetTokenCharCount(LChar, FViewPosition.Row);
          FWordWrapLine.Width[FViewPosition.Row] := FWordWrapLine.Width[FViewPosition.Row] - LWidth;
          if (LCharAtCursor = TControlCharacters.Tab) or (FWordWrapLine.Length[FViewPosition.Row] <= 0) then
            CreateLineNumbersCache(True);
        end;

        if GetKeyState(vkShift) >= 0 then
        begin
          Dec(LTextPosition.Char, LCharPosition);
          TextPosition := LTextPosition;
        end;
      end;
    end;
  end;

  if FSyncEdit.Visible then
    DoSyncEdit;

  FUndoList.EndBlock;

  Invalidate;
end;

procedure TCustomTextEditor.DoBlockComment;
var
  LIndex: Integer;
  LLength: Integer;
  LBeginLine, LEndLine: Integer;
  LComment: string;
  LCommentIndex: Integer;
  LSpaceCount: Integer;
  LSpaces: string;
  LLineText: string;
  LTextPosition, LSelectionBeginPosition, LSelectionEndPosition: TTextEditorTextPosition;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
  LDeleteComment: Boolean;
  LPosition: Integer;
begin
  LLength := Length(FHighlighter.Comments.BlockComments);

  if LLength > 0 then
  begin
    LTextPosition := TextPosition;
    LSelectionBeginPosition := SelectionBeginPosition;
    LSelectionEndPosition := SelectionEndPosition;

    if GetSelectionAvailable then
    begin
      LBeginLine := LSelectionBeginPosition.Line;
      LEndLine := LSelectionEndPosition.Line;
    end
    else
    begin
      LBeginLine := LTextPosition.Line;
      LEndLine := LTextPosition.Line;
    end;

    for LIndex := LBeginLine to LEndLine do
    begin
      LCodeFoldingRange := CodeFoldingRangeForLine(LIndex + 1);
      if Assigned(LCodeFoldingRange) and LCodeFoldingRange.Collapsed then
        CodeFoldingExpand(LCodeFoldingRange);
    end;

    LIndex := 0;
    LCommentIndex := -2;
    LLineText := FLines.Items^[LBeginLine].TextLine;
    LSpaceCount := LeftSpaceCount(LLineText, False);
    LSpaces := Copy(LLineText, 1, LSpaceCount);
    LLineText := TextEditor.Utils.TrimLeft(LLineText);

    if LLineText <> '' then
    while LIndex < LLength - 1 do
    begin
      if FastPos(FHighlighter.Comments.BlockComments[LIndex], LLineText) = 1 then
      begin
        LCommentIndex := LIndex;
        Break;
      end;
      Inc(LIndex, 2);
    end;

    FUndoList.BeginBlock;

    FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);

    LDeleteComment := False;
    if LCommentIndex <> -2 then
    begin
      LDeleteComment := True;
      LComment := FHighlighter.Comments.BlockComments[LCommentIndex];
      FUndoList.AddChange(crDelete, LTextPosition, GetPosition(LSpaceCount + 1, LBeginLine),
        GetPosition(LSpaceCount + Length(LComment) + 1, LBeginLine), LComment, FSelection.ActiveMode);
      LLineText := Copy(LLineText, Length(LComment) + 1, Length(LLineText));
    end;

    Inc(LCommentIndex, 2);
    LComment := '';
    if LCommentIndex < LLength - 1 then
      LComment := FHighlighter.Comments.BlockComments[LCommentIndex];

    LLineText := LSpaces + LComment + LLineText;

    FLines.BeginUpdate;
    FLines.Strings[LBeginLine] := LLineText;

    FUndoList.AddChange(crInsert, LTextPosition, GetPosition(1 + LSpaceCount, LBeginLine),
      GetPosition(1 + LSpaceCount + Length(LComment), LBeginLine), '', FSelection.ActiveMode);

    Inc(LCommentIndex);
    LLineText := FLines.Items^[LEndLine].TextLine;
    LSpaceCount := LeftSpaceCount(LLineText, False);
    LSpaces := Copy(LLineText, 1, LSpaceCount);
    LLineText := TextEditor.Utils.TrimLeft(LLineText);

    if LDeleteComment and (LLineText <> '') then
    begin
      LComment := FHighlighter.Comments.BlockComments[LCommentIndex - 2];
      LPosition := Length(LLineText) - Length(LComment) + 1;
      if (LPosition > 0) and (Pos(LComment, LLineText) = LPosition) then
      begin
        FUndoList.AddChange(crDelete, LTextPosition,
          GetPosition(LSpaceCount + Length(LLineText) - Length(LComment) + 1, LEndLine),
          GetPosition(LSpaceCount + Length(LLineText) + 1, LEndLine), LComment, FSelection.ActiveMode);
        LLineText := Copy(LLineText, 1, Length(LLineText) - Length(LComment));
      end;
    end;

    if (LCommentIndex > 0) and (LCommentIndex < LLength) then
      LComment := FHighlighter.Comments.BlockComments[LCommentIndex]
    else
      LComment := '';

    LLineText := LSpaces + LLineText + LComment;

    FLines.Strings[LEndLine] := LLineText;

    FUndoList.AddChange(crInsert, LTextPosition, GetPosition(Length(LLineText) - Length(LComment) + 1,
      LEndLine), GetPosition(Length(LLineText) + Length(LComment) + 1, LEndLine), '', FSelection.ActiveMode);

    FUndoList.EndBlock;
    FLines.EndUpdate;

    TextPosition := LTextPosition;
    FPosition.BeginSelection := LSelectionBeginPosition;
    FPosition.EndSelection := LSelectionEndPosition;
    RescanCodeFoldingRanges;
    ScanMatchingPair;
  end;
end;

procedure TCustomTextEditor.DoChar(const AChar: Char);
var
  LTextPosition: TTextEditorTextPosition;
  LLineText: string;
  LLength: Integer;
  LSpaceCount1: Integer;
  LSpaceBuffer: string;
  LBlockStartPosition: TTextEditorTextPosition;
  LHelper: string;
  LCharCount: Integer;
  LWidth: Integer;
  LIndex: Integer;
  LMathingPairToken: TTextEditorMatchingPairToken;
  LCloseToken: string;
  LToken: string;
  LTokenCount: Integer;
  LCharAtCursor: Char;

  procedure InitializeCurrentLine;
  begin
    if LTextPosition.Line = 0 then
      FHighlighter.ResetRange
    else
      FHighlighter.SetRange(FLines.Ranges[LTextPosition.Line - 1]);

    FHighlighter.SetLine(FLines[LTextPosition.Line]);
  end;

begin
  LTextPosition := TextPosition;

  if (AChar = TCharacters.Space) and AddSnippet(seSpace, LTextPosition) then
    Exit;

  LCharAtCursor := GetCharAtTextPosition(LTextPosition);

  FUndoList.BeginBlock(3);

  if (rmoAutoLinebreak in FRightMargin.Options) and (FViewPosition.Column > FRightMargin.Position) then
  begin
    DoLineBreak;
    LTextPosition.Char := 1;
    Inc(LTextPosition.Line);
  end;

  if GetSelectionAvailable then
  begin
    if FSyncEdit.Visible then
      FSyncEdit.MoveEndPositionChar(-FPosition.EndSelection.Char + FPosition.BeginSelection.Char + 1);
    SetSelectedTextEmpty(AChar);
  end
  else
  begin
    if FSyncEdit.Visible then
      FSyncEdit.MoveEndPositionChar(1);

    LLineText := FLines[LTextPosition.Line];
    LLength := Length(LLineText);

    LSpaceCount1 := 0;
    if LLength < LTextPosition.Char - 1 then
    begin
      LCharCount := LTextPosition.Char - LLength - 1 - Ord(FOvertypeMode);
      if toTabsToSpaces in FTabs.Options then
        LSpaceBuffer := StringOfChar(TCharacters.Space, LCharCount)
      else
      if AllWhiteUpToTextPosition(LTextPosition, LLineText, LLength) then
        LSpaceBuffer := StringOfChar(TControlCharacters.Tab, LCharCount div FTabs.Width) +
          StringOfChar(TCharacters.Space, LCharCount mod FTabs.Width)
      else
        LSpaceBuffer := StringOfChar(TCharacters.Space, LCharCount);
      LSpaceCount1 := Length(LSpaceBuffer);
    end;

    LBlockStartPosition := LTextPosition;

    if FOvertypeMode = omInsert then
    begin
      LCloseToken := '';
      if FMatchingPairs.AutoComplete then
      for LIndex := 0 to FHighlighter.MatchingPairs.Count - 1 do
      begin
        LMathingPairToken := PTextEditorMatchingPairToken(FHighlighter.MatchingPairs[LIndex])^;
        if (LMathingPairToken.OpenToken = AChar) and (LMathingPairToken.CloseToken = AChar) then
        begin
          InitializeCurrentLine;
          LTokenCount := 0;
          with FHighlighter do
          while not EndOfLine and (LTextPosition.Char > TokenPosition + TokenLength) do
          begin
            GetToken(LToken);
            if AChar = LToken then
              Inc(LTokenCount);

            Next;
          end;

          if LTokenCount mod 2 = 0 then
          begin
            LCloseToken := LMathingPairToken.CloseToken;

            Break;
          end;
        end
        else
        if LMathingPairToken.OpenToken = AChar then
        begin
          LCloseToken := LMathingPairToken.CloseToken;
          Break;
        end
        else
        if (LMathingPairToken.OpenToken.Length > 1) and
          (LMathingPairToken.OpenToken[LMathingPairToken.OpenToken.Length] = AChar) and
          (WordAtTextPosition(GetPosition(LTextPosition.Char - 1, LTextPosition.Line)) +
          AChar = LMathingPairToken.OpenToken) then
        begin
          LCloseToken := LMathingPairToken.CloseToken;
          Break;
        end;
      end;

      if LSpaceCount1 > 0 then
        LLineText := LLineText + LSpaceBuffer + AChar + LCloseToken
      else
        Insert(AChar + LCloseToken, LLineText, LTextPosition.Char);

      FLines[LTextPosition.Line] := LLineText;
      FLines.ExcludeFlag(LTextPosition.Line, sfEmptyLine);

      if LSpaceCount1 > 0 then
      begin
        LTextPosition.Char := LLength + LSpaceCount1 + 2;
        FUndoList.AddChange(crInsert, GetPosition(LLength + 1, LTextPosition.Line),
          GetPosition(LLength + 1, LTextPosition.Line),
          GetPosition(LLength + LSpaceCount1 + 2  + Length(LCloseToken), LTextPosition.Line), '', smNormal);
        FLines.LineState[LTextPosition.Line] := lsModified;
      end
      else
      begin
        LTextPosition.Char := LTextPosition.Char + 1;
        FUndoList.AddChange(crInsert, LBlockStartPosition, LBlockStartPosition,
          GetPosition(LTextPosition.Char + Length(LCloseToken), LTextPosition.Line), '', smNormal);
        FLines.LineState[LTextPosition.Line] := lsModified;
      end;
      FUndoList.AddChange(crSelection, LTextPosition, LBlockStartPosition, LBlockStartPosition, '', smNormal);
    end
    else
    begin
      LHelper := '';
      if LTextPosition.Char <= LLength then
        LHelper := Copy(LLineText, LTextPosition.Char, 1);

      if LTextPosition.Char <= LLength then
        LLineText[LTextPosition.Char] := AChar
      else
      if LSpaceCount1 > 0 then
      begin
        LSpaceBuffer[LSpaceCount1] := AChar;
        LLineText := LLineText + LSpaceBuffer;
      end
      else
        LLineText := LLineText + AChar;

      FLines[LTextPosition.Line] := LLineText;
      FLines.ExcludeFlag(LTextPosition.Line, sfEmptyLine);

      if LSpaceCount1 > 0 then
      begin
        LTextPosition.Char := LLength + LSpaceCount1 + 1;
        FUndoList.AddChange(crInsert, LTextPosition, GetPosition(LLength + 1, LTextPosition.Line),
          GetPosition(LLength + LSpaceCount1 + 1, LTextPosition.Line), '', smNormal);
        FLines.LineState[LTextPosition.Line] := lsModified;
      end
      else
      begin
        LTextPosition.Char := LTextPosition.Char + 1;
        FUndoList.AddChange(crInsert, LTextPosition, LBlockStartPosition, LTextPosition, LHelper, smNormal);
        FLines.LineState[LTextPosition.Line] := lsModified;
      end;
    end;

    if FWordWrap.Active then
      if FViewPosition.Row < Length(FWordWrapLine.ViewLength) then
      begin
        LWidth := GetTokenWidth(LSpaceBuffer, Length(LSpaceBuffer), 0) + GetTokenWidth(AChar, 1, 0);
        if (LCharAtCursor = TControlCharacters.Tab) or
          (FWordWrapLine.Width[FViewPosition.Row] + LWidth > FScrollHelper.PageWidth) or
          (FViewPosition.Column > FWordWrapLine.ViewLength[FViewPosition.Row]) then
          CreateLineNumbersCache(True)
        else
        begin
          FWordWrapLine.Length[FViewPosition.Row] := FWordWrapLine.Length[FViewPosition.Row] + 1;
          FWordWrapLine.ViewLength[FViewPosition.Row] := FWordWrapLine.ViewLength[FViewPosition.Row] + 1;
          FWordWrapLine.Width[FViewPosition.Row] := FWordWrapLine.Width[FViewPosition.Row] + LWidth;
        end;
      end;

    TextPosition := LTextPosition;
  end;

  FUndoList.EndBlock;

  if FSyncEdit.Visible then
    DoSyncEdit;
end;

procedure TCustomTextEditor.DoCutToClipboard;
begin
  if not ReadOnly and GetSelectionAvailable then
  begin
    Screen.Cursor := crHourGlass;
    try
      FUndoList.BeginBlock;

      DoCopyToClipboard(SelectedText);
      SetSelectedTextEmpty;

      FUndoList.EndBlock;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TCustomTextEditor.DoEditorBottom(const ACommand: TTextEditorCommand);
var
  LCaretNewPosition: TTextEditorTextPosition;
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := TextPosition;

  with LCaretNewPosition do
  begin
    Char := 1;
    Line := FLines.Count - 1;
    if Line > 0 then
      Char := Length(FLines.Items^[Line].TextLine) + 1;
  end;

  MoveCaretAndSelection(LTextPosition, LCaretNewPosition, ACommand = TKeyCommands.SelectionEditorBottom);
end;

procedure TCustomTextEditor.DoEditorTop(const ACommand: TTextEditorCommand);
var
  LCaretNewPosition: TTextEditorTextPosition;
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := TextPosition;

  with LCaretNewPosition do
  begin
    Char := 1;
    Line := 0;
  end;

  MoveCaretAndSelection(LTextPosition, LCaretNewPosition, ACommand = TKeyCommands.SelectionEditorTop);
end;

procedure TCustomTextEditor.DoToggleSelectedCase(const ACommand: TTextEditorCommand);
var
  LSelectedText: string;
  LOldCaretPosition, LOldBlockBeginPosition, LOldBlockEndPosition: TTextEditorTextPosition;
begin
  Assert((ACommand >= TKeyCommands.UpperCase) and (ACommand <= TKeyCommands.AlternatingCaseBlock));

  LOldBlockBeginPosition := SelectionBeginPosition;
  LOldBlockEndPosition := SelectionEndPosition;
  LOldCaretPosition := TextPosition;
  try
    LSelectedText := SelectedText;
    if LSelectedText <> '' then
    begin
      case ACommand of
        TKeyCommands.UpperCase, TKeyCommands.UpperCaseBlock:
          LSelectedText := AnsiUpperCase(LSelectedText);
        TKeyCommands.LowerCase, TKeyCommands.LowerCaseBlock:
          LSelectedText := AnsiLowerCase(LSelectedText);
        TKeyCommands.AlternatingCase, TKeyCommands.AlternatingCaseBlock:
          LSelectedText := ToggleCase(LSelectedText);
        TKeyCommands.SentenceCase:
          LSelectedText := AnsiUpperCase(LSelectedText[1]) + AnsiLowerCase(Copy(LSelectedText, 2));
        TKeyCommands.TitleCase:
          LSelectedText := TitleCase(LSelectedText);
      end;
      FUndoList.BeginBlock;
      try
        SetSelectedTextEmpty(LSelectedText);
      finally
        FUndoList.EndBlock;
      end;
    end;
  finally
    SelectionBeginPosition := LOldBlockBeginPosition;
    SelectionEndPosition := LOldBlockEndPosition;
    TextPosition := LOldCaretPosition;
  end;
end;

procedure TCustomTextEditor.DoEndKey(const ASelection: Boolean);
var
  LLineText: string;
  LTextPosition: TTextEditorTextPosition;
  LEndOfLineCaretPosition: TTextEditorTextPosition;
  LPLine: PChar;
  LChar: Integer;
begin
  LTextPosition := TextPosition;
  LLineText := FLines.Items^[LTextPosition.Line].TextLine;
  LEndOfLineCaretPosition := GetPosition(Length(LLineText) + 1, LTextPosition.Line);
  LPLine := PChar(LLineText);
  Inc(LPLine, LEndOfLineCaretPosition.Char - 2);
  LChar := LEndOfLineCaretPosition.Char;

  while (LPLine^ > TControlCharacters.Null) and (LPLine^ <= TCharacters.Space) do
  begin
    Dec(LChar);
    Dec(LPLine);
  end;

  if LTextPosition.Char < LChar then
    LEndOfLineCaretPosition.Char := LChar;

  MoveCaretAndSelection(LTextPosition, LEndOfLineCaretPosition, ASelection);
end;

{$IFDEF BASENCODING}
procedure TCustomTextEditor.Decode(const ACoding: TTextEditorCoding);
var
  LText: string;
  LBytes: TBytes;
begin
  FUndoList.BeginBlock;
  FUndoList.AddChange(crCaret, TextPosition, SelectionBeginPosition, SelectionBeginPosition, '',
    FSelection.ActiveMode);
  try
    if not SelectionAvailable then
      SelectAll;

    case ACoding of
      eASCIIDecimal: LText := TNetEncoding.ASCIIDecimal.Decode(SelectedText);
      eBase32: LText := TNetEncoding.Base32.Decode(SelectedText);
      eBase64: LText := TNetEncoding.Base64NoLineBreaks.Decode(SelectedText);
      eBase64WithLineBreaks: LBytes := TNetEncoding.Base64.Decode(FLines.Encoding.GetBytes(SelectedText));
      eBase85: LText := TNetEncoding.Base85.Decode(SelectedText);
      eBase91: LText := TNetEncoding.Base91.Decode(SelectedText);
      eBase128: LText := TNetEncoding.Base128.Decode(SelectedText);
      eBase256: LText := TNetEncoding.Base256.Decode(SelectedText);
      eBase1024: LText := TNetEncoding.Base1024.Decode(SelectedText);
      eBase4096: LText := TNetEncoding.Base4096.Decode(SelectedText);
      eBinary: LText := TNetEncoding.Binary.Decode(SelectedText);
      eHex:
        if FLines.Encoding = TEncoding.BigEndianUnicode then
          LText := TNetEncoding.HexBigEndian.Decode(SelectedText)
        else
        if FLines.Encoding = TEncoding.Unicode then
          LText := TNetEncoding.HexLittleEndian.Decode(SelectedText)
        else
          LText := TNetEncoding.Hex.Decode(SelectedText);
      eHexWithoutSpaces:
        if FLines.Encoding = TEncoding.BigEndianUnicode then
          LText := TNetEncoding.HexBigEndianWithoutSpaces.Decode(SelectedText)
        else
        if FLines.Encoding = TEncoding.Unicode then
          LText := TNetEncoding.HexLittleEndianWithoutSpaces.Decode(SelectedText)
        else
          LText := TNetEncoding.HexWithoutSpaces.Decode(SelectedText);
      eHTML: LBytes := TNetEncoding.HTML.Decode(FLines.Encoding.GetBytes(SelectedText));
      eOctal: LText := TNetEncoding.Octal.Decode(SelectedText);
      eRotate5: LText := TNetEncoding.Rotate5.Decode(SelectedText);
      eRotate13: LText := TNetEncoding.Rotate13.Decode(SelectedText);
      eRotate18: LText := TNetEncoding.Rotate18.Decode(SelectedText);
      eRotate47: LText := TNetEncoding.Rotate47.Decode(SelectedText);
      eURL: LBytes := TNetEncoding.URL.Decode(FLines.Encoding.GetBytes(SelectedText));
    end;

    case ACoding of
      eBase64WithLineBreaks, eHTML, eURL: LText := FLines.Encoding.GetString(LBytes);
    end;

    if LText <> '' then
      SetSelectedTextEmpty(LText);
  finally
    FUndoList.EndBlock;

    Invalidate;
  end;
end;

procedure TCustomTextEditor.Encode(const ACoding: TTextEditorCoding);
var
  LBytes: TBytes;
  LText: string;
begin
  FUndoList.BeginBlock;
  FUndoList.AddChange(crCaret, TextPosition, SelectionBeginPosition, SelectionBeginPosition, '',
    FSelection.ActiveMode);
  try
    if not SelectionAvailable then
      SelectAll;

    case ACoding of
      eASCIIDecimal: LText := TNetEncoding.ASCIIDecimal.Encode(SelectedText);
      eBase32: LText := TNetEncoding.Base32.Encode(SelectedText);
      eBase64: LText := TNetEncoding.Base64NoLineBreaks.Encode(SelectedText);
      eBase64WithLineBreaks: LBytes := TNetEncoding.Base64.Encode(FLines.Encoding.GetBytes(SelectedText));
      eBase85: LText := TNetEncoding.Base85.Encode(SelectedText);
      eBase91: LText := TNetEncoding.Base91.Encode(SelectedText);
      eBase128: LText := TNetEncoding.Base128.Encode(SelectedText);
      eBase256: LText := TNetEncoding.Base256.Encode(SelectedText);
      eBase1024: LText := TNetEncoding.Base1024.Encode(SelectedText);
      eBase4096: LText := TNetEncoding.Base4096.Encode(SelectedText);
      eBinary: LText := TNetEncoding.Binary.Encode(SelectedText);
      eHex:
        if FLines.Encoding = TEncoding.BigEndianUnicode then
          LText := TNetEncoding.HexBigEndian.Encode(SelectedText)
        else
        if FLines.Encoding = TEncoding.Unicode then
          LText := TNetEncoding.HexLittleEndian.Encode(SelectedText)
        else
          LText := TNetEncoding.Hex.Encode(SelectedText);
      eHexWithoutSpaces:
        if FLines.Encoding = TEncoding.BigEndianUnicode then
          LText := TNetEncoding.HexBigEndianWithoutSpaces.Encode(SelectedText)
        else
        if FLines.Encoding = TEncoding.Unicode then
          LText := TNetEncoding.HexLittleEndianWithoutSpaces.Encode(SelectedText)
        else
          LText := TNetEncoding.HexWithoutSpaces.Encode(SelectedText);
      eHTML: LBytes := TNetEncoding.HTML.Encode(FLines.Encoding.GetBytes(SelectedText));
      eOctal: LText := TNetEncoding.Octal.Encode(SelectedText);
      eRotate5: LText := TNetEncoding.Rotate5.Encode(SelectedText);
      eRotate13: LText := TNetEncoding.Rotate13.Encode(SelectedText);
      eRotate18: LText := TNetEncoding.Rotate18.Encode(SelectedText);
      eRotate47: LText := TNetEncoding.Rotate47.Encode(SelectedText);
      eURL: LBytes := TNetEncoding.URL.Encode(FLines.Encoding.GetBytes(SelectedText));
    end;

    case ACoding of
      eBase64WithLineBreaks, eHTML, eURL: LText := FLines.Encoding.GetString(LBytes);
    end;

    if LText <> '' then
      SetSelectedTextEmpty(LText);
  finally
    FUndoList.EndBlock;

    Invalidate;
  end;
end;
{$ENDIF}

procedure TCustomTextEditor.GoToNextBookmark;
var
  LIndex: Integer;
  LMark: TTextEditorMark;
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := TextPosition;
  for LIndex := 0 to FBookmarkList.Count - 1 do
  begin
    LMark := FBookmarkList.Items[LIndex];
    if (LMark.Line > LTextPosition.Line) or
      (LMark.Line = LTextPosition.Line) and (LMark.Char > LTextPosition.Char) then
    begin
      GoToBookmark(LMark.Index);
      Exit;
    end;
  end;

  if FBookmarkList.Count > 0 then
    GoToBookmark(FBookmarkList.Items[0].Index);
end;

procedure TCustomTextEditor.GoToPreviousBookmark;
var
  LIndex: Integer;
  LMark: TTextEditorMark;
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := TextPosition;
  for LIndex := FBookmarkList.Count - 1 downto 0 do
  begin
    LMark := FBookmarkList.Items[LIndex];
    if (LMark.Line < LTextPosition.Line) or
      (LMark.Line = LTextPosition.Line) and (LMark.Char < LTextPosition.Char) then
    begin
      GoToBookmark(LMark.Index);
      Exit;
    end;
  end;

  if FBookmarkList.Count > 0 then
    GoToBookmark(FBookmarkList.Items[FBookmarkList.Count - 1].Index);
end;

procedure TCustomTextEditor.DoHomeKey(const ASelection: Boolean);
var
  LLineText: string;
  LTextPosition: TTextEditorTextPosition;
  LSpaceCount: Integer;
begin
  LTextPosition := TextPosition;
  LLineText := FLines.Items^[LTextPosition.Line].TextLine;
  LSpaceCount := LeftSpaceCount(LLineText) + 1;

  if LTextPosition.Char <= LSpaceCount then
    LSpaceCount := 1;

  MoveCaretAndSelection(LTextPosition, GetPosition(LSpaceCount, FPosition.Text.Line), ASelection);
end;

procedure TCustomTextEditor.DoImeStr(const AData: Pointer);
var
  S: string;
  LLength: Integer;
  LHelper: string;
  LLineText: string;
  LChangeScrollPastEndOfLine: Boolean;
  LTextPosition: TTextEditorTextPosition;
  LBlockStartPosition: TTextEditorTextPosition;
begin
  LTextPosition := TextPosition;
  LLength := Length(PChar(AData));

  SetString(S, PChar(AData), LLength);
  if GetSelectionAvailable then
  begin
    FUndoList.BeginBlock;
    try
      FUndoList.AddChange(crDelete, LTextPosition, FPosition.BeginSelection, FPosition.EndSelection, LHelper,
        smNormal);
      LBlockStartPosition := FPosition.BeginSelection;
      DoSelectedText(S);
      FUndoList.AddChange(crInsert, LTextPosition, FPosition.BeginSelection, FPosition.EndSelection, LHelper,
        smNormal);
    finally
      FUndoList.EndBlock;
    end;

    Invalidate;
  end
  else
  begin
    LLineText := FLines[LTextPosition.Line];
    LLength := Length(LLineText);
    if LLength < LTextPosition.Char then
      LLineText := LLineText + StringOfChar(TCharacters.Space, LTextPosition.Char - LLength - 1);
    LChangeScrollPastEndOfLine := not (soPastEndOfLine in FScroll.Options);
    try
      if LChangeScrollPastEndOfLine then
        FScroll.SetOption(soPastEndOfLine, True);

      LBlockStartPosition := LTextPosition;

      if FOvertypeMode = omOverwrite then
      begin
        LHelper := Copy(LLineText, LTextPosition.Char, LLength);
        Delete(LLineText, LTextPosition.Char, LLength);
      end;

      Insert(S, LLineText, LTextPosition.Char);
      FViewPosition.Column := FViewPosition.Column + Length(S);
      SetLine(FPosition.Text.Line, LLineText);
      if FOvertypeMode = omInsert then
        LHelper := '';
      FUndoList.AddChange(crInsert, LTextPosition, LBlockStartPosition, TextPosition, LHelper, smNormal);
    finally
      if LChangeScrollPastEndOfLine then
        FScroll.SetOption(soPastEndOfLine, False);
    end;
  end;
end;

procedure TCustomTextEditor.DoLeftMarginAutoSize;
var
  LWidth: Integer;
begin
  if not Assigned(Parent) then
    Exit;

  if FLeftMargin.Autosize then
  begin
    if FLeftMargin.LineNumbers.Visible then
      FLeftMargin.AutosizeDigitCount(FLines.Count);

    FPaintHelper.SetBaseFont(FLeftMargin.Font);
    LWidth := FLeftMargin.RealLeftMarginWidth(FPaintHelper.CharWidth);
    FLeftMarginCharWidth := FPaintHelper.CharWidth;
    FPaintHelper.SetBaseFont(Font);

    if FLeftMargin.Width <> LWidth then
    begin
      FLeftMargin.OnChange := nil;
      FLeftMargin.Width := LWidth;
      FLeftMargin.OnChange := LeftMarginChanged;
      FScrollHelper.PageWidth := GetScrollPageWidth;
      if HandleAllocated then
        if FWordWrap.Active then
        begin
          FLineNumbers.ResetCache := True;
          UpdateScrollBars;
        end;
    end;
    FLeftMarginWidth := GetLeftMarginWidth;
  end;
end;

procedure TCustomTextEditor.DoLineBreak(const AAddSpaceBuffer: Boolean = True);
var
  LTextPosition: TTextEditorTextPosition;
  LLineText: string;
  LLength: Integer;
  LSpaceCount1: Integer;
  LSpaceBuffer: string;

  function GetSpaceBuffer(const ASpaceCount: Integer): string;
  begin
    Result := '';
    if eoAutoIndent in FOptions then
      if toTabsToSpaces in FTabs.Options then
        Result := StringOfChar(TCharacters.Space, ASpaceCount)
      else
      begin
        Result := StringOfChar(TControlCharacters.Tab, ASpaceCount div FTabs.Width);
        Result := Result + StringOfChar(TCharacters.Space, ASpaceCount mod FTabs.Width);
      end;
  end;

begin
  LTextPosition := TextPosition;

  if AddSnippet(seEnter, LTextPosition) then
    Exit;

  DoTrimTrailingSpaces(LTextPosition.Line);

  FUndoList.BeginBlock(4);
  try
    if GetSelectionAvailable then
    begin
      SetSelectedTextEmpty;
      LTextPosition := TextPosition;
    end;

    FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);

    LLineText := FLines[LTextPosition.Line];
    LLength := Length(LLineText);

    if LLength > 0 then
    begin
      with FLines.Items^[LTextPosition.Line] do
      begin
        Exclude(Flags, sfLineBreakCR);
        Exclude(Flags, sfLineBreakLF);
      end;

      if LLength >= LTextPosition.Char then
      begin
        if LTextPosition.Char > 1 then
        begin
          { A line break after the first char and before the end of the line. }
          LSpaceCount1 := LeftSpaceCount(LLineText, True);
          LSpaceBuffer := '';
          if AAddSpaceBuffer then
            LSpaceBuffer := GetSpaceBuffer(LSpaceCount1);

          FLines[LTextPosition.Line] := Copy(LLineText, 1, LTextPosition.Char - 1);

          LLineText := Copy(LLineText, LTextPosition.Char, MaxInt);

          FUndoList.AddChange(crDelete, LTextPosition, LTextPosition,
            GetPosition(LTextPosition.Char + Length(LLineText), LTextPosition.Line), LLineText, smNormal);

          if (eoAutoIndent in FOptions) and (LSpaceCount1 > 0) then
            LLineText := LSpaceBuffer + LLineText;

          FLines.Insert(LTextPosition.Line + 1, LLineText);

          FUndoList.AddChange(crLineBreak, GetPosition(1, LTextPosition.Line + 1), LTextPosition,
            GetPosition(1, LTextPosition.Line + 1), '', smNormal);

          FUndoList.AddChange(crInsert, GetPosition(Length(LSpaceBuffer) + 1, LTextPosition.Line + 1),
            GetPosition(1, LTextPosition.Line + 1), GetPosition(Length(LLineText) + 1,
            LTextPosition.Line + 1), LLineText, smNormal);

          with FLines do
          begin
            LineState[LTextPosition.Line] := lsModified;
            LineState[LTextPosition.Line + 1] := lsModified;
          end;

          LTextPosition.Char := Length(LSpaceBuffer) + 1;
          Inc(LTextPosition.Line);
          FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);
        end
        else
        begin
          { A line break at the first char. }
          FLines.Insert(LTextPosition.Line, '');
          FUndoList.AddChange(crLineBreak, LTextPosition, LTextPosition, LTextPosition, '', smNormal);
          Inc(LTextPosition.Line);
          with FLines do
            LineState[LTextPosition.Line] := lsModified;
        end;
      end
      else
      begin
        { A line break after the end of the line. }
        LSpaceCount1 := 0;
        if eoAutoIndent in FOptions then
          LSpaceCount1 := LeftSpaceCount(LLineText, True);

        LSpaceBuffer := '';
        if AAddSpaceBuffer then
          LSpaceBuffer := GetSpaceBuffer(LSpaceCount1);

        FLines.Insert(LTextPosition.Line + 1, LSpaceBuffer);

        if LTextPosition.Char > LLength + 1 then
          LTextPosition.Char := LLength + 1;

        FUndoList.AddChange(crLineBreak, LTextPosition, LTextPosition,
          GetPosition(1, LTextPosition.Line + 1), '', smNormal);

        LTextPosition.Char := Length(LSpaceBuffer) + 1;
        Inc(LTextPosition.Line);

        FUndoList.AddChange(crInsert, GetPosition(Length(LSpaceBuffer) + 1, LTextPosition.Line),
          GetPosition(1, LTextPosition.Line), GetPosition(Length(LSpaceBuffer) + 1,
          LTextPosition.Line), LSpaceBuffer, smNormal);

        FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);

        FLines.LineState[LTextPosition.Line] := lsModified;
      end;
    end
    else
    begin
      { A line break at the empty line. }
      if FLines.Count = 0 then
        FLines.Add('');

      FLines.Insert(LTextPosition.Line, '');

      LTextPosition.Line := Min(LTextPosition.Line + 1, FLines.Count);
      LTextPosition.Char := 1;

      FUndoList.AddChange(crLineBreak, LTextPosition, LTextPosition,
        GetPosition(1, LTextPosition.Line), '', smNormal);

      FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);

      FLines.LineState[LTextPosition.Line] := lsModified;
    end;

    SelectionBeginPosition := LTextPosition;
    SelectionEndPosition := LTextPosition;
    TextPosition := LTextPosition;

    EnsureCursorPositionVisible;
  finally
    UndoList.EndBlock;
  end;
end;

procedure TCustomTextEditor.DoLineComment;
var
  LIndex: Integer;
  LLength: Integer;
  LLine, LEndLine: Integer;
  LCommentIndex: Integer;
  LSpaceCount: Integer;
  LSpaces: string;
  LLineText: string;
  LComment: string;
  LTextPosition, LSelectionBeginPosition, LSelectionEndPosition: TTextEditorTextPosition;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  LLength := Length(FHighlighter.Comments.LineComments);
  if LLength > 0 then
  begin
    LTextPosition := TextPosition;
    LSelectionBeginPosition := SelectionBeginPosition;
    LSelectionEndPosition := SelectionEndPosition;

    if GetSelectionAvailable then
    begin
      LLine := LSelectionBeginPosition.Line;
      LEndLine := LSelectionEndPosition.Line;
    end
    else
    begin
      LLine := LTextPosition.Line;
      LEndLine := LLine;
    end;

    FLines.BeginUpdate;
    FUndoList.BeginBlock;
    for LLine := LLine to LEndLine do
    begin
      LCodeFoldingRange := CodeFoldingRangeForLine(LLine + 1);
      if Assigned(LCodeFoldingRange) and LCodeFoldingRange.Collapsed then
        CodeFoldingExpand(LCodeFoldingRange);

      LIndex := 0;
      LCommentIndex := -1;
      LLineText := FLines.Items^[LLine].TextLine;
      LSpaceCount := LeftSpaceCount(LLineText, False);
      LSpaces := Copy(LLineText, 1, LSpaceCount);
      LLineText := TextEditor.Utils.TrimLeft(LLineText);

      if LLineText <> '' then
      while LIndex < LLength do
      begin
        if FastPos(FHighlighter.Comments.LineComments[LIndex], LLineText) = 1 then
        begin
          LCommentIndex := LIndex;
          Break;
        end;
        Inc(LIndex);
      end;

      if LCommentIndex <> -1 then
      begin
        LComment := FHighlighter.Comments.LineComments[LCommentIndex];
        FUndoList.AddChange(crDelete, LTextPosition, GetPosition(1 + LSpaceCount, LLine),
          GetPosition(Length(LComment) + 1 + LSpaceCount, LLine), LComment, smNormal);
        LLineText := Copy(LLineText, Length(FHighlighter.Comments.LineComments[LCommentIndex]) + 1, Length(LLineText));
      end;

      Inc(LCommentIndex);
      LComment := '';
      if LCommentIndex < LLength then
        LComment := FHighlighter.Comments.LineComments[LCommentIndex];

      LLineText := LComment + LSpaces + LLineText;

      FLines.Strings[LLine] := LLineText;

      FUndoList.AddChange(crInsert, LTextPosition, GetPosition(1, LLine),
        GetPosition(Length(LComment) + 1, LLine), '', smNormal);

      if not GetSelectionAvailable then
      begin
        Inc(LTextPosition.Line);
        TextPosition := LTextPosition;
      end;
    end;
    FUndoList.EndBlock;
    FLines.EndUpdate;

    FPosition.BeginSelection := LSelectionBeginPosition;
    FPosition.EndSelection := LSelectionEndPosition;
    if GetSelectionAvailable then
      TextPosition := LTextPosition;
    RescanCodeFoldingRanges;
    ScanMatchingPair;
  end;
end;

procedure TCustomTextEditor.DoPageLeftOrRight(const ACommand: TTextEditorCommand);
var
  LVisibleChars: Integer;
begin
  LVisibleChars := GetVisibleChars(FViewPosition.Row);
  if ACommand in [TKeyCommands.PageLeft, TKeyCommands.SelectionPageLeft] then
    LVisibleChars := -LVisibleChars;
  MoveCaretHorizontally(LVisibleChars, ACommand in [TKeyCommands.SelectionPageLeft, TKeyCommands.SelectionPageRight]);
end;

procedure TCustomTextEditor.DoPageTopOrBottom(const ACommand: TTextEditorCommand);
var
  LLineCount: Integer;
  LCaretNewPosition: TTextEditorTextPosition;
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := TextPosition;
  LLineCount := 0;
  if ACommand in [TKeyCommands.PageBottom, TKeyCommands.SelectionPageBottom] then
    LLineCount := VisibleLineCount - 1;
  LCaretNewPosition := ViewToTextPosition(GetViewPosition(FViewPosition.Column, TopLine + LLineCount));
  MoveCaretAndSelection(LTextPosition, LCaretNewPosition, ACommand in [TKeyCommands.SelectionPageTop, TKeyCommands.SelectionPageBottom]);
end;

procedure TCustomTextEditor.DoPageUpOrDown(const ACommand: TTextEditorCommand);
var
  LLineCount: Integer;
begin
  LLineCount := VisibleLineCount shr Ord(soHalfPage in FScroll.Options);
  if ACommand in [TKeyCommands.PageUp, TKeyCommands.SelectionPageUp] then
    LLineCount := -LLineCount;
  TopLine := TopLine + LLineCount;

  MoveCaretVertically(LLineCount, ACommand in [TKeyCommands.SelectionPageUp, TKeyCommands.SelectionPageDown]);
end;

procedure TCustomTextEditor.DoPasteFromClipboard;
begin
  Screen.Cursor := crHourGlass;
  try
    DoInsertText(GetClipboardText);
    RescanCodeFoldingRanges;
    EnsureCursorPositionVisible;
    UpdateScrollBars;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TCustomTextEditor.DoInsertText(const AText: string);
var
  LTextPosition: TTextEditorTextPosition;
  LSelectionBeginPosition: TTextEditorTextPosition;
  LSelectionEndPosition: TTextEditorTextPosition;
  LPasteMode: TTextEditorSelectionMode;
  LLength, LCharCount: Integer;
  LSpaces: string;
begin
  LTextPosition := TextPosition;
  LSelectionBeginPosition := SelectionBeginPosition;
  LSelectionEndPosition := SelectionEndPosition;
  LPasteMode := FSelection.Mode;

  FUndoList.BeginBlock;
  FUndoList.AddChange(crCaret, LTextPosition, LSelectionBeginPosition, SelectionEndPosition, '', smNormal);

  LLength := Length(FLines[LTextPosition.Line]);

  if GetSelectionAvailable then
    FUndoList.AddChange(crDelete, LTextPosition, SelectionBeginPosition, SelectionEndPosition, GetSelectedText,
      FSelection.ActiveMode)
  else
  begin
    FSelection.ActiveMode := Selection.Mode;

    if LTextPosition.Char > LLength + 1 then
    begin
      LCharCount := LTextPosition.Char - LLength - 1;
      if toTabsToSpaces in FTabs.Options then
        LSpaces := StringOfChar(TCharacters.Space, LCharCount)
      else
      begin
        LSpaces := StringOfChar(TControlCharacters.Tab, LCharCount div FTabs.Width);
        LSpaces := LSpaces + StringOfChar(TCharacters.Space, LCharCount mod FTabs.Width);
      end;
    end;
  end;

  if GetSelectionAvailable then
  begin
    FPosition.BeginSelection := LSelectionBeginPosition;
    FPosition.EndSelection := LSelectionEndPosition;

    if FSyncEdit.Visible then
      FSyncEdit.MoveEndPositionChar(-FPosition.EndSelection.Char + FPosition.BeginSelection.Char + Length(AText));
  end
  else
  begin
    LSelectionBeginPosition := LTextPosition;

    if FSyncEdit.Visible then
      FSyncEdit.MoveEndPositionChar(Length(AText));
  end;

  DoSelectedText(LPasteMode, PChar(AText), True, TextPosition);

  FPosition.BeginSelection := FPosition.EndSelection;

  FUndoList.AddChange(crPaste, LTextPosition, LSelectionBeginPosition, TextPosition, SelectedText, LPasteMode);
  FUndoList.EndBlock;

  if FSyncEdit.Visible then
    DoSyncEdit;

  EnsureCursorPositionVisible;

  Invalidate;
end;

procedure TCustomTextEditor.DoScroll(const ACommand: TTextEditorCommand);
var
  LCaretRow: Integer;
begin
  LCaretRow := FViewPosition.Row;
  if (LCaretRow < TopLine) or (LCaretRow >= TopLine + VisibleLineCount) then
    EnsureCursorPositionVisible
  else
  begin
    if ACommand = TKeyCommands.ScrollUp then
    begin
      TopLine := TopLine - 1;
      if LCaretRow > TopLine + VisibleLineCount - 1 then
        MoveCaretVertically((TopLine + VisibleLineCount - 1) - LCaretRow, False);
    end
    else
    begin
      TopLine := TopLine + 1;
      if LCaretRow < TopLine then
        MoveCaretVertically(TopLine - LCaretRow, False);
    end;

    EnsureCursorPositionVisible;
  end;
end;

procedure TCustomTextEditor.DoSetBookmark(const ACommand: TTextEditorCommand; const AData: Pointer);
var
  LIndex: Integer;
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := TextPosition;
  LIndex := ACommand - TKeyCommands.SetBookmark1;
  if Assigned(AData) then
    LTextPosition := TTextEditorTextPosition(AData^);
  if not DeleteBookmark(LTextPosition.Line, LIndex) then
    SetBookmark(LIndex, LTextPosition);
end;

procedure TCustomTextEditor.DoShiftTabKey;
var
  LNewX, LTabWidth: Integer;
  LTextLine, LOldSelectedText: string;
  LTextPosition: TTextEditorTextPosition;
  LChangeScrollPastEndOfLine: Boolean;
begin
  if (toSelectedBlockIndent in FTabs.Options) and GetSelectionAvailable then
  begin
    DoBlockUnindent;
    Exit;
  end;

  LTextPosition := TextPosition;
  if toTabsToSpaces in FTabs.Options then
    LTabWidth := FTabs.Width
  else
    LTabWidth := 1;
  LNewX := TextPosition.Char - LTabWidth;

  if LNewX < 1 then
    LNewX := 1;

  if LNewX <> TextPosition.Char then
  begin
    LOldSelectedText := Copy(FLines.Items^[LTextPosition.Line].TextLine, LNewX, LTabWidth);

    if toTabsToSpaces in FTabs.Options then
    begin
      if LOldSelectedText <> StringOfChar(TCharacters.Space, FTabs.Width) then
        Exit;
    end
    else
    if LOldSelectedText <> TControlCharacters.Tab then
      Exit;

    LTextLine := FLines.Items^[LTextPosition.Line].TextLine;
    Delete(LTextLine, LNewX, LTabWidth);
    FLines[LTextPosition.Line] := LTextLine;

    LChangeScrollPastEndOfLine := not (soPastEndOfLine in FScroll.Options);
    try
      if LChangeScrollPastEndOfLine then
        FScroll.SetOption(soPastEndOfLine, True);

      SetTextCaretX(LNewX);
    finally
      if LChangeScrollPastEndOfLine then
        FScroll.SetOption(soPastEndOfLine, False);
    end;

    FUndoList.AddChange(crDelete, LTextPosition, TextPosition, LTextPosition, LOldSelectedText,
      smNormal, 2);
  end;
end;

procedure TCustomTextEditor.DoSyncEdit;
var
  LIndex1, LIndex2: Integer;
  LEditText, LOldText: string;
  LTextPosition, LTextBeginPosition, LTextEndPosition, LTextSameLinePosition: TTextEditorTextPosition;
  LDifference: Integer;
  LLine: string;
begin
  LTextPosition := TextPosition;

  LEditText := Copy(FLines.Items^[FSyncEdit.EditBeginPosition.Line].TextLine, FSyncEdit.EditBeginPosition.Char,
    FSyncEdit.EditEndPosition.Char - FSyncEdit.EditBeginPosition.Char);
  LDifference := Length(LEditText) - FSyncEdit.EditWidth;
  for LIndex1 := 0 to FSyncEdit.SyncItems.Count - 1 do
  begin
    LTextBeginPosition := PTextEditorTextPosition(FSyncEdit.SyncItems.Items[LIndex1])^;

    if (LTextBeginPosition.Line = FSyncEdit.EditBeginPosition.Line) and
      (LTextBeginPosition.Char < FSyncEdit.EditBeginPosition.Char) then
    begin
      FSyncEdit.MoveBeginPositionChar(LDifference);
      FSyncEdit.MoveEndPositionChar(LDifference);
      Inc(LTextPosition.Char, LDifference);
    end;

    if (LTextBeginPosition.Line = FSyncEdit.EditBeginPosition.Line) and
      (LTextBeginPosition.Char > FSyncEdit.EditBeginPosition.Char) then
    begin
      Inc(LTextBeginPosition.Char, LDifference);
      PTextEditorTextPosition(FSyncEdit.SyncItems.Items[LIndex1])^.Char := LTextBeginPosition.Char;
    end;

    LTextEndPosition := LTextBeginPosition;
    Inc(LTextEndPosition.Char, FSyncEdit.EditWidth);
    LOldText := Copy(FLines.Items^[LTextBeginPosition.Line].TextLine, LTextBeginPosition.Char, FSyncEdit.EditWidth);

    FUndoList.AddChange(crDelete, LTextPosition, LTextBeginPosition, LTextEndPosition, '', FSelection.ActiveMode);

    LTextEndPosition := LTextBeginPosition;
    Inc(LTextEndPosition.Char, Length(LEditText));

    FUndoList.AddChange(crInsert, LTextPosition, LTextBeginPosition, LTextEndPosition, LOldText,
      FSelection.ActiveMode);
    FLines.BeginUpdate;
    LLine := FLines.Items^[LTextBeginPosition.Line].TextLine;
    FLines[LTextBeginPosition.Line] := Copy(LLine, 1, LTextBeginPosition.Char - 1) + LEditText +
      Copy(LLine, LTextBeginPosition.Char + FSyncEdit.EditWidth, Length(LLine));
    FLines.EndUpdate;
    LIndex2 := LIndex1 + 1;
    if LIndex2 < FSyncEdit.SyncItems.Count then
    begin
      LTextSameLinePosition := PTextEditorTextPosition(FSyncEdit.SyncItems.Items[LIndex2])^;

      while (LIndex2 < FSyncEdit.SyncItems.Count) and (LTextSameLinePosition.Line = LTextBeginPosition.Line) do
      begin
        PTextEditorTextPosition(FSyncEdit.SyncItems.Items[LIndex2])^.Char := LTextSameLinePosition.Char + LDifference;

        Inc(LIndex2);
        if LIndex2 < FSyncEdit.SyncItems.Count then
          LTextSameLinePosition := PTextEditorTextPosition(FSyncEdit.SyncItems.Items[LIndex2])^;
      end;
    end;
  end;
  FSyncEdit.EditWidth := FSyncEdit.EditEndPosition.Char - FSyncEdit.EditBeginPosition.Char;
  TextPosition := LTextPosition;
end;

procedure TCustomTextEditor.DoTabKey;
var
  LTextPosition, LNewTextPosition: TTextEditorTextPosition;
  LViewPosition: TTextEditorViewPosition;
  LTabText, LTextLine: string;
  LCharCount, LLengthAfterLine, LPreviousLine, LPreviousLineCharCount: Integer;
  LChangeScrollPastEndOfLine: Boolean;
  LWidth: Integer;
begin
  if GetSelectionAvailable and (FPosition.BeginSelection.Line <> FPosition.EndSelection.Line) and
    (toSelectedBlockIndent in FTabs.Options) then
  begin
    DoBlockIndent;
    Exit;
  end;

  FUndoList.BeginBlock(1);
  try
    LTextPosition := TextPosition;
    if GetSelectionAvailable then
    begin
      FUndoList.AddChange(crDelete, LTextPosition, SelectionBeginPosition, SelectionEndPosition, GetSelectedText,
        FSelection.ActiveMode);
      DoSelectedText('');
      LTextPosition := FPosition.BeginSelection;
    end;

    LTextLine := FLines[LTextPosition.Line];

    LViewPosition := ViewPosition;
    LLengthAfterLine := Max(LViewPosition.Column - FLines.ExpandedStringLengths[LTextPosition.Line], 1);

    if LLengthAfterLine > 1 then
      LCharCount := LLengthAfterLine
    else
      LCharCount := FTabs.Width;

    if toPreviousLineIndent in FTabs.Options then
      if TextEditor.Utils.Trim(FLines[LTextPosition.Line]) = '' then
      begin
        LPreviousLine := LTextPosition.Line - 1;
        while (LPreviousLine >= 0) and (FLines.Items^[LPreviousLine].TextLine = '') do
          Dec(LPreviousLine);
        LPreviousLineCharCount := LeftSpaceCount(FLines.Items^[LPreviousLine].TextLine, toTabsToSpaces in FTabs.Options);
        if LPreviousLineCharCount > LTextPosition.Char then
          LCharCount := LPreviousLineCharCount - LeftSpaceCount(FLines.Items^[LTextPosition.Line].TextLine,
            toTabsToSpaces in FTabs.Options);
      end;

    if LLengthAfterLine > 1 then
      LTextPosition.Char := Length(LTextLine) + 1;

    if toTabsToSpaces in FTabs.Options then
    begin
      if FLines.Columns then
        LTabText := StringOfChar(TCharacters.Space, LCharCount - (LViewPosition.Column - 1) mod FTabs.Width)
      else
        LTabText := StringOfChar(TCharacters.Space, LCharCount)
    end
    else
    begin
      LTabText := StringOfChar(TControlCharacters.Tab, LCharCount div FTabs.Width);
      LTabText := LTabText + StringOfChar(TCharacters.Space, LCharCount mod FTabs.Width);
    end;

    Insert(LTabText, LTextLine, LTextPosition.Char);
    FLines[LTextPosition.Line] := LTextLine;

    if FWordWrap.Active then
      if FViewPosition.Row < Length(FWordWrapLine.ViewLength) then
      begin
        LWidth := GetTokenWidth(LTabText, 1, 0);
        if (FWordWrapLine.Width[FViewPosition.Row] + LWidth > FScrollHelper.PageWidth) or
          (FViewPosition.Column > FWordWrapLine.ViewLength[FViewPosition.Row]) then
          CreateLineNumbersCache(True)
        else
        begin
          FWordWrapLine.Length[FViewPosition.Row] := FWordWrapLine.Length[FViewPosition.Row] + 1;
          FWordWrapLine.ViewLength[FViewPosition.Row] := FWordWrapLine.ViewLength[FViewPosition.Row] +
            GetTokenCharCount(LTabText, FViewPosition.Column - 1);
          FWordWrapLine.Width[FViewPosition.Row] := FWordWrapLine.Width[FViewPosition.Row] + LWidth;
        end;
      end;

    LChangeScrollPastEndOfLine := not (soPastEndOfLine in FScroll.Options);
    try
      if LChangeScrollPastEndOfLine then
        FScroll.SetOption(soPastEndOfLine, True);
      SetTextCaretX(LTextPosition.Char + Length(LTabText));
    finally
      if LChangeScrollPastEndOfLine then
        FScroll.SetOption(soPastEndOfLine, False);
    end;
    EnsureCursorPositionVisible;

    LNewTextPosition := TextPosition;

    FUndoList.AddChange(crInsert, LTextPosition, LTextPosition, LNewTextPosition, '',
      FSelection.ActiveMode);
    FUndoList.AddChange(crSelection, LNewTextPosition, LNewTextPosition, LNewTextPosition, '',
      FSelection.ActiveMode);
  finally
    FUndoList.EndBlock;
  end;
end;

procedure TCustomTextEditor.DoToggleBookmark(const AImageIndex: Integer = -1);
var
  LIndex, LMarkIndex: Integer;
  LMark: TTextEditorMark;
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := TextPosition;
  LMarkIndex := 0;
  for LIndex := 0 to FBookmarkList.Count - 1 do
  begin
    LMark := FBookmarkList.Items[LIndex];

    if LMark.Line = LTextPosition.Line then
    begin
      DeleteBookmark(LMark);
      if AImageIndex <> -1 then
        Break;
      Exit;
    end;

    if LMark.Index > LMarkIndex then
      LMarkIndex := LMark.Index;
  end;

  LMarkIndex := Max(10, LMarkIndex + 1);
  SetBookmark(LMarkIndex, LTextPosition, AImageIndex);
end;

procedure TCustomTextEditor.DoToggleMark;
var
  LIndex, LMarkIndex: Integer;
  LMark: TTextEditorMark;
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := TextPosition;
  LMarkIndex := 0;
  for LIndex := 0 to FMarkList.Count - 1 do
  begin
    LMark := FMarkList.Items[LIndex];
    if LMark.Line = LTextPosition.Line then
    begin
      DeleteMark(LMark);
      Exit;
    end;
    if LMark.Index > LMarkIndex then
      LMarkIndex := LMark.Index;
  end;
  Inc(LMarkIndex);
  SetMark(LMarkIndex, LTextPosition, FLeftMargin.Marks.DefaultImageIndex);
end;

procedure TCustomTextEditor.PaintCaretBlock(const AViewPosition: TTextEditorViewPosition);
var
  LPoint: TPoint;
  LCaretStyle: TTextEditorCaretStyle;
  LCaretWidth, LCaretHeight, X, Y: Integer;
  LTempBitmap: Vcl.Graphics.TBitmap;
  LBackgroundColor, LForegroundColor: TColor;
  LLineText: string;
begin
  LPoint := ViewPositionToPixels(AViewPosition);
  Y := 0;
  X := 0;
  LCaretHeight := 1;
  LCaretWidth := FPaintHelper.CharWidth;

  if Assigned(FMultiCaret.Carets) and (FMultiCaret.Carets.Count > 0) or (FMultiCaret.Position.Row <> -1) then
  begin
    LBackgroundColor := FCaret.MultiEdit.Colors.Background;
    LForegroundColor := FCaret.MultiEdit.Colors.Foreground;
    LCaretStyle := FCaret.MultiEdit.Style
  end
  else
  begin
    LBackgroundColor := FCaret.NonBlinking.Colors.Background;
    LForegroundColor := FCaret.NonBlinking.Colors.Foreground;
    if FOvertypeMode = omInsert then
      LCaretStyle := FCaret.Styles.Insert
    else
      LCaretStyle := FCaret.Styles.Overwrite;
  end;

  case LCaretStyle of
    csHorizontalLine, csThinHorizontalLine:
      begin
        if LCaretStyle = csHorizontalLine then
          LCaretHeight := 2;
        Y := GetLineHeight - LCaretHeight;
        Inc(LPoint.Y, Y);
        Inc(LPoint.X);
      end;
    csHalfBlock:
      begin
        LCaretHeight := GetLineHeight div 2;
        Y := GetLineHeight div 2;
        Inc(LPoint.Y, Y);
        Inc(LPoint.X);
      end;
    csBlock:
      begin
        LCaretHeight := GetLineHeight;
        Inc(LPoint.X);
      end;
    csVerticalLine, csThinVerticalLine:
      begin
        LCaretWidth := 1;
        if LCaretStyle = csVerticalLine then
          LCaretWidth := 2;
        LCaretHeight := GetLineHeight;
        X := 1;
      end;
  end;
  LTempBitmap := Vcl.Graphics.TBitmap.Create;
  try
    { Background }
    LTempBitmap.Canvas.Pen.Color := LBackgroundColor;
    LTempBitmap.Canvas.Brush.Color := LBackgroundColor;
    { Size }
    LTempBitmap.Width := FPaintHelper.CharWidth;
    LTempBitmap.Height := GetLineHeight;
    { Character }
    LTempBitmap.Canvas.Brush.Style := bsClear;
    LTempBitmap.Canvas.Font.Name := Font.Name;
    LTempBitmap.Canvas.Font.Color := LForegroundColor;
    LTempBitmap.Canvas.Font.Style := Font.Style;
    LTempBitmap.Canvas.Font.Size := Font.Size;

    LLineText := FLines[AViewPosition.Row - 1];
    if (AViewPosition.Column > 0) and (AViewPosition.Column <= Length(LLineText)) then
      LTempBitmap.Canvas.TextOut(X, 0, LLineText[AViewPosition.Column]);

    Canvas.CopyRect(Rect(LPoint.X + FCaret.Offsets.Left, LPoint.Y + FCaret.Offsets.Top,
      LPoint.X + FCaret.Offsets.Left + LCaretWidth, LPoint.Y + FCaret.Offsets.Top + LCaretHeight), LTempBitmap.Canvas,
      Rect(0, Y, LCaretWidth, Y + LCaretHeight));
  finally
    LTempBitmap.Free
  end;
end;

function TCustomTextEditor.IsTextPositionInSearchBlock(const ATextPosition: TTextEditorTextPosition): Boolean;
var
  LSelectionBeginPosition, LSelectionEndPosition: TTextEditorTextPosition;
begin
  Result := False;

  LSelectionBeginPosition := FSearch.InSelection.SelectionBeginPosition;
  LSelectionEndPosition := FSearch.InSelection.SelectionEndPosition;

  if FSelection.ActiveMode = smNormal then
    Result :=
      ((ATextPosition.Line > LSelectionBeginPosition.Line) or
       (ATextPosition.Line = LSelectionBeginPosition.Line) and (ATextPosition.Char >= LSelectionBeginPosition.Char))
      and
      ((ATextPosition.Line < LSelectionEndPosition.Line) or
       (ATextPosition.Line = LSelectionEndPosition.Line) and (ATextPosition.Char < LSelectionEndPosition.Char))
  else
  if FSelection.ActiveMode = smColumn then
    Result :=
      ((ATextPosition.Line >= LSelectionBeginPosition.Line) and (ATextPosition.Char >= LSelectionBeginPosition.Char))
      and
      ((ATextPosition.Line <= LSelectionEndPosition.Line) and (ATextPosition.Char < LSelectionEndPosition.Char));
end;

procedure TCustomTextEditor.SearchAll(const ASearchText: string = '');
var
  LLine, LResultIndex, LSearchAllCount, LTextPosition, LSearchLength, LCurrentLineLength: Integer;
  LSearchText: string;
  LPSearchItem: PTextEditorSearchItem;
  LBeginTextPosition, LEndTextPosition: TTextEditorTextPosition;
  LSelectionBeginPosition, LSelectionEndPosition:  TTextEditorTextPosition;
  LSelectedOnly: Boolean;

  function IsLineInSearch: Boolean;
  begin
    Result := not FSearch.InSelection.Active
      or
      LSelectedOnly and IsTextPositionInSelection(LSelectionBeginPosition) and IsTextPositionInSelection(LSelectionEndPosition)
      or
      FSearch.InSelection.Active and
      (FSearch.InSelection.SelectionBeginPosition.Line <= LLine) and
      (FSearch.InSelection.SelectionEndPosition.Line >= LLine)
  end;

  function CanAddResult: Boolean;
  begin
    Result := not FSearch.InSelection.Active
      or
      LSelectedOnly and IsTextPositionInSelection(LSelectionBeginPosition) and IsTextPositionInSelection(LSelectionEndPosition)
      or
      FSearch.InSelection.Active and
      ((FSearch.InSelection.SelectionBeginPosition.Line < LLine) and (FSearch.InSelection.SelectionEndPosition.Line > LLine) or
      IsTextPositionInSearchBlock(LBeginTextPosition) and IsTextPositionInSearchBlock(LEndTextPosition));
  end;

begin
  FSearch.ClearItems;

  if not FSearch.Enabled then
    Exit;

  if ASearchText = '' then
    LSearchText := FSearch.SearchText
  else
    LSearchText := ASearchText;

  if LSearchText = '' then
    Exit;

  LSelectedOnly := False;
  FSearchEngine.Pattern := LSearchText;
  if ASearchText = '' then
  begin
    FSearchEngine.CaseSensitive := soCaseSensitive in FSearch.Options;
    FSearchEngine.WholeWordsOnly := soWholeWordsOnly in FSearch.Options;

    FPosition.BeginSelection := FPosition.EndSelection;
  end
  else
  begin
    FSearchEngine.CaseSensitive := roCaseSensitive in FReplace.Options;
    FSearchEngine.WholeWordsOnly := roWholeWordsOnly in FReplace.Options;
    LSelectionBeginPosition := SelectionBeginPosition;
    LSelectionEndPosition := SelectionEndPosition;
    LSelectedOnly := roSelectedOnly in FReplace.Options;
  end;

  LResultIndex := 0;
  LSearchAllCount := FSearchEngine.SearchAll(FLines);
  if LSearchAllCount > 0 then
  begin
    LLine := 0;
    LCurrentLineLength := Length(FLines.Items^[LLine].TextLine) + FLines.LineBreakLength(LLine);
    LTextPosition := 0;
    while (LLine < FLines.Count) and (LResultIndex < LSearchAllCount) do
    begin
      if IsLineInSearch then
      begin
        while (LLine < FLines.Count) and (LResultIndex < LSearchAllCount) and
          (FSearchEngine.Results[LResultIndex] <= LTextPosition + LCurrentLineLength) do
        begin
          if FLines.Items^[LLine].TextLine = '' then
            Inc(LLine);

          LSearchLength := FSearchEngine.Lengths[LResultIndex];

          LBeginTextPosition.Char := FSearchEngine.Results[LResultIndex] - LTextPosition;
          LBeginTextPosition.Line := LLine;
          LEndTextPosition.Char := LBeginTextPosition.Char + LSearchLength;
          LEndTextPosition.Line := LLine;

          if CanAddResult then
          begin
            New(LPSearchItem);
            LPSearchItem^.BeginTextPosition := LBeginTextPosition;
            LPSearchItem^.EndTextPosition := LEndTextPosition;
            FSearch.Items.Add(LPSearchItem);
          end;

          Inc(LResultIndex);
        end;
      end;
      Inc(LLine);
      Inc(LTextPosition, LCurrentLineLength);
      LCurrentLineLength := FLines.StringLength(LLine) + FLines.LineBreakLength(LLine);
    end;
  end;
end;

procedure TCustomTextEditor.FindWords(const AWord: string; const AList: TList; const ACaseSensitive: Boolean;
  const AWholeWordsOnly: Boolean);
var
  LLine, LFirstLine, LFirstChar, LLastLine, LLastChar: Integer;
  LLineText: string;
  LPText, LPTextBegin, LPKeyword, LPBookmarkText: PChar;
  LPTextPosition: PTextEditorTextPosition;

  function AreCharsSame(const APChar1, APChar2: PChar): Boolean;
  begin
    if ACaseSensitive then
      Result := APChar1^ = APChar2^
    else
      Result := CaseUpper(APChar1^) = CaseUpper(APChar2^)
  end;

  function IsWholeWord(const AFirstChar, ALastChar: PChar): Boolean;
  begin
    Result := IsWordBreakChar(AFirstChar^) and IsWordBreakChar(ALastChar^);
  end;

begin
  if FSearch.InSelection.Active then
  begin
    LFirstLine := FSearch.InSelection.SelectionBeginPosition.Line;
    LFirstChar := FSearch.InSelection.SelectionBeginPosition.Char - 1;
    LLastLine := FSearch.InSelection.SelectionEndPosition.Line;
    LLastChar := FSearch.InSelection.SelectionEndPosition.Char;
  end
  else
  begin
    LFirstLine := 0;
    LFirstChar := 0;
    LLastLine := FLines.Count - 1;
    LLastChar := 0;
  end;
  for LLine := LFirstLine to LLastLine do
  begin
    LLineText := FLines.Items^[LLine].TextLine;
    LPText := PChar(LLineText);
    LPTextBegin := LPText;
    if (LLine = LFirstLine) and (LFirstChar > 0) then
      Inc(LPText, LFirstChar);
    while LPText^ <> TControlCharacters.Null do
    begin
      if AreCharsSame(LPText, PChar(AWord)) then { If the first character is a match }
      begin
        LPKeyWord := PChar(AWord);
        LPBookmarkText := LPText;
        { Check if the keyword found }
        while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and
          AreCharsSame(LPText, LPKeyWord) do
        begin
          Inc(LPText);
          Inc(LPKeyWord);
        end;
        if (LPKeyWord^ = TControlCharacters.Null) and
          (not AWholeWordsOnly or AWholeWordsOnly and IsWholeWord(LPBookmarkText - 1, LPText)) then
        begin
          Dec(LPText);
          New(LPTextPosition);
          LPTextPosition^.Char := LPBookmarkText - PChar(LLineText) + 1;
          LPTextPosition^.Line := LLine;
          AList.Add(LPTextPosition)
        end
        else
          LPText := LPBookmarkText; { Not found, return pointer back }
      end;

      Inc(LPText);

      if (LLine = LLastLine) and (LLastChar > 0) then
        if LPTextBegin - LPText > LLastChar then
          Break;
    end;
  end;
end;

procedure TCustomTextEditor.FreeScrollShadowBitmap;
begin
  if Assigned(FScrollHelper.Shadow.Bitmap) then
  begin
    FScrollHelper.Shadow.Bitmap.Free;
    FScrollHelper.Shadow.Bitmap := nil;
  end;
end;

function TCustomTextEditor.FreeMinimapBitmaps: Boolean;
begin
  Result := Assigned(FMinimapHelper.BufferBitmap) or Assigned(FMinimapHelper.Shadow.Bitmap) or
    Assigned(FMinimapHelper.Indicator.Bitmap);

  if Assigned(FMinimapHelper.BufferBitmap) then
  begin
    FMinimapHelper.BufferBitmap.Free;
    FMinimapHelper.BufferBitmap := nil;
  end;

  if Assigned(FMinimapHelper.Shadow.Bitmap) then
  begin
    FMinimapHelper.Shadow.Bitmap.Free;
    FMinimapHelper.Shadow.Bitmap := nil;
  end;

  if Assigned(FMinimapHelper.Indicator.Bitmap) then
  begin
    FMinimapHelper.Indicator.Bitmap.Free;
    FMinimapHelper.Indicator.Bitmap := nil;
  end;
end;

procedure TCustomTextEditor.FreeMultiCarets;
var
  LIndex: Integer;
begin
  if Assigned(FMultiCaret.Carets) then
  begin
    FMultiCaret.Timer.Enabled := False;
    FMultiCaret.Timer.Free;
    FMultiCaret.Timer := nil;

    for LIndex := FMultiCaret.Carets.Count - 1 downto 0 do
      Dispose(PTextEditorViewPosition(FMultiCaret.Carets.Items[LIndex]));

    FMultiCaret.Carets.Clear;
    FMultiCaret.Carets.Free;
    FMultiCaret.Carets := nil;
  end;
end;

procedure TCustomTextEditor.FontChanged(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  if Assigned(FHighlighter) and not FHighlighter.Loading then
    SizeOrFontChanged;
end;

procedure TCustomTextEditor.GetMinimapLeftRight(var ALeft: Integer; var ARight: Integer);
begin
  if FMinimap.Align = maRight then
  begin
    ALeft := Width - FMinimap.GetWidth;
    ARight := Width;
  end
  else
  begin
    ALeft := 0;
    ARight := FMinimap.GetWidth;
  end;

  if FSearch.Map.Align = saRight then
  begin
    Dec(ALeft, FSearch.Map.GetWidth);
    Dec(ARight, FSearch.Map.GetWidth);
  end
  else
  begin
    Inc(ALeft, FSearch.Map.GetWidth);
    Inc(ARight, FSearch.Map.GetWidth);
  end;
end;

procedure TCustomTextEditor.InitCodeFolding;
begin
  if FState.ReplaceLock then
    Exit;

  ClearCodeFolding;

  if Visible then
    CreateLineNumbersCache(True);

  if FCodeFolding.Visible then
  begin
    ScanCodeFoldingRanges;
    CodeFoldingResetCaches;
  end;
end;

procedure TCustomTextEditor.InsertLine;
var
  LTextPosition: TTextEditorTextPosition;
  LLineText: string;
  LLength: Integer;
begin
  LTextPosition := TextPosition;
  FUndoList.BeginBlock;
  try
    FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);
    LLineText := FLines.Items^[LTextPosition.Line].TextLine;
    LLength := Length(LLineText);
    FLines.Insert(LTextPosition.Line + 1, '');
    FUndoList.AddChange(crInsert, LTextPosition, GetPosition(LLength + 1, LTextPosition.Line),
      GetPosition(1, LTextPosition.Line + 1), '', smNormal);

    FLines.LineState[LTextPosition.Line + 1] := lsModified;

    FViewPosition.Column := 1;
    FViewPosition.Row := FViewPosition.Row + 1;
  finally
    FUndoList.EndBlock;

    Invalidate;
  end;
end;

procedure TCustomTextEditor.InsertText(const AText: string);
begin
  DoInsertText(AText);
end;

procedure TCustomTextEditor.LinesChanging(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  Include(FState.Flags, sfLinesChanging);
end;

procedure TCustomTextEditor.ClearMinimapBuffer;
begin
  if Assigned(FMinimapHelper.BufferBitmap) then
    FMinimapHelper.BufferBitmap.Height := 0;
end;

procedure TCustomTextEditor.MinimapChanged(ASender: TObject); //FI:O804 Method parameter is declared but never used
var
  LIndex: Integer;

  procedure Validate;
  begin
    FLeftMarginWidth := GetLeftMarginWidth;
    SizeOrFontChanged;

    Invalidate;
  end;

begin
  if FMinimap.Visible then
  begin
    if not Assigned(FMinimapHelper.BufferBitmap) then
      FMinimapHelper.BufferBitmap := Vcl.Graphics.TBitmap.Create;

    ClearMinimapBuffer;

    if ioUseBlending in FMinimap.Indicator.Options then
      if not Assigned(FMinimapHelper.Indicator.Bitmap) then
        FMinimapHelper.Indicator.Bitmap := Vcl.Graphics.TBitmap.Create;

    if FMinimap.Shadow.Visible then
    begin
      FMinimapHelper.Shadow.BlendFunction.SourceConstantAlpha := FMinimap.Shadow.AlphaBlending;

      if not Assigned(FMinimapHelper.Shadow.Bitmap) then
      begin
        FMinimapHelper.Shadow.Bitmap := Vcl.Graphics.TBitmap.Create;
        FMinimapHelper.Shadow.Bitmap.PixelFormat := pf32Bit;
      end;

      FMinimapHelper.Shadow.Bitmap.Canvas.Brush.Color := FMinimap.Shadow.Color;
      FMinimapHelper.Shadow.Bitmap.Height := 0;
      FMinimapHelper.Shadow.Bitmap.Width := Max(FMinimap.Shadow.Width, 1);

      SetLength(FMinimapHelper.Shadow.AlphaArray, FMinimapHelper.Shadow.Bitmap.Width);
      if FMinimapHelper.Shadow.AlphaByteArrayLength <> FMinimapHelper.Shadow.Bitmap.Width then
      begin
        FMinimapHelper.Shadow.AlphaByteArrayLength := FMinimapHelper.Shadow.Bitmap.Width;
        ReallocMem(FMinimapHelper.Shadow.AlphaByteArray, FMinimapHelper.Shadow.AlphaByteArrayLength * SizeOf(Byte));
      end;

      for LIndex := 0 to FMinimapHelper.Shadow.Bitmap.Width - 1 do
      begin
        if FMinimap.Align = maLeft then
          FMinimapHelper.Shadow.AlphaArray[LIndex] := (FMinimapHelper.Shadow.Bitmap.Width - LIndex) /
            FMinimapHelper.Shadow.Bitmap.Width
        else
          FMinimapHelper.Shadow.AlphaArray[LIndex] := LIndex / FMinimapHelper.Shadow.Bitmap.Width;
        FMinimapHelper.Shadow.AlphaByteArray[LIndex] := Min(Round(Power(FMinimapHelper.Shadow.AlphaArray[LIndex], 4) * 255.0), 255);
      end;
    end;

    Validate;
  end
  else
  if FreeMinimapBitmaps then
    Validate;
end;

procedure TCustomTextEditor.MouseScrollTimerHandler(ASender: TObject); //FI:O804 Method parameter is declared but never used
var
  LCursorPoint: TPoint;
begin
  IncPaintLock;
  try
    Winapi.Windows.GetCursorPos(LCursorPoint);
    LCursorPoint := ScreenToClient(LCursorPoint);

    if FScrollHelper.Delta.X <> 0 then
      SetHorizontalScrollPosition(FScrollHelper.HorizontalPosition + FScrollHelper.Delta.X);

    if FScrollHelper.Delta.Y <> 0 then
    begin
      if GetKeyState(vkShift) < 0 then
        TopLine := TopLine + FScrollHelper.Delta.Y * VisibleLineCount
      else
        TopLine := TopLine + FScrollHelper.Delta.Y;
    end;
  finally
    DecPaintLock;

    Invalidate;
  end;

  ComputeScroll(LCursorPoint);
end;

procedure TCustomTextEditor.MoveCaretAndSelection(const ABeforeTextPosition, AAfterTextPosition: TTextEditorTextPosition;
  const ASelectionCommand: Boolean);
var
  LReason: TTextEditorChangeReason;
begin
  IncPaintLock;

  if not (uoGroupUndo in FUndo.Options) and UndoList.CanUndo then
    FUndoList.AddGroupBreak;

  FUndoList.BeginBlock(5);

  if GetSelectionAvailable then
    LReason := crSelection
  else
    LReason := crCaret;
  FUndoList.AddChange(LReason, FPosition.Text, SelectionBeginPosition, SelectionEndPosition, '', FSelection.ActiveMode);

  if ASelectionCommand then
  begin
    if not GetSelectionAvailable then
      SetSelectionBeginPosition(ABeforeTextPosition);
    SetSelectionEndPosition(AAfterTextPosition);
  end
  else
    SetSelectionBeginPosition(AAfterTextPosition);

  TextPosition := AAfterTextPosition;

  FUndoList.EndBlock;

  DecPaintLock;
end;

procedure TCustomTextEditor.MoveCaretHorizontally(const X: Integer; const ASelectionCommand: Boolean);
var
  LTextPosition: TTextEditorTextPosition;
  LDestinationPosition: TTextEditorTextPosition;
  LCurrentLineLength: Integer;
  LChangeY: Boolean;
  LPLine: PChar;
begin
  LTextPosition := TextPosition;
  if not GetSelectionAvailable then
  begin
    FPosition.BeginSelection := LTextPosition;
    FPosition.EndSelection := LTextPosition;
  end;

  if not (uoGroupUndo in FUndo.Options) and UndoList.CanUndo then
    FUndoList.AddGroupBreak;

  LDestinationPosition := LTextPosition;

  LCurrentLineLength := Length(FLines[LTextPosition.Line]);
  LChangeY := not (soPastEndOfLine in FScroll.Options) or FWordWrap.Active;

  if LChangeY and (X = -1) and (LTextPosition.Char = 1) and (LTextPosition.Line >= 1) then
  with LDestinationPosition do
  begin
    Line := Line - 1;
    Char := FLines.StringLength(Line) + 1;
  end
  else
  if LChangeY and (X = 1) and (LTextPosition.Char > LCurrentLineLength) and
    (LTextPosition.Line < FLines.Count) then
  with LDestinationPosition do
  begin
    if LDestinationPosition.Line + 1 >= FLines.Count then
      Exit;
    Line := LDestinationPosition.Line + 1;
    Char := 1;
  end
  else
  begin
    LDestinationPosition.Char := Max(1, LDestinationPosition.Char + X);
    if (X > 0) and LChangeY then
      LDestinationPosition.Char := Min(LDestinationPosition.Char, LCurrentLineLength + 1);

    { Skip combined and non-spacing marks }
    if LDestinationPosition.Char <= FLines.StringLength(LDestinationPosition.Line) then
    begin
      LPLine := PChar(FLines.Items^[LDestinationPosition.Line].TextLine);
      Inc(LPLine, LDestinationPosition.Char - 1);
      while (LPLine^ <> TControlCharacters.Null) and
        (IsCombiningCharacter(LPLine) or
         not (eoShowNullCharacters in Options) and (LPLine^ = TControlCharacters.Substitute) or
         not (eoShowControlCharacters in Options) and (LPLine^ < TCharacters.Space) and (LPLine^ in TControlCharacters.AsSet) or
         not (eoShowZeroWidthSpaces in Options) and (LPLine^ = TCharacters.ZeroWidthSpace)) do
      if X > 0 then
      begin
        Inc(LPLine);
        Inc(LDestinationPosition.Char);
      end
      else
      begin
        Dec(LPLine);
        Dec(LDestinationPosition.Char);
      end;
    end;
  end;

  if not ASelectionCommand and (LDestinationPosition.Line <> LTextPosition.Line) then
  begin
    DoTrimTrailingSpaces(LTextPosition.Line);
    DoTrimTrailingSpaces(LDestinationPosition.Line);
  end;

  MoveCaretAndSelection(FPosition.BeginSelection, LDestinationPosition, ASelectionCommand);
end;

procedure TCustomTextEditor.MoveCaretVertically(const Y: Integer; const ASelectionCommand: Boolean);
var
  LDestinationPosition: TTextEditorViewPosition;
  LDestinationLineChar: TTextEditorTextPosition;
begin
  LDestinationPosition := ViewPosition;

  Inc(LDestinationPosition.Row, Y);
  if Y >= 0 then
  begin
    if LDestinationPosition.Row > FLineNumbers.Count then
    begin
      LDestinationPosition.Row := Max(1, FLineNumbers.Count);
      LDestinationPosition.Column := FLines.StringLength(LDestinationPosition.Row - 1) + 1;
    end;
  end
  else
  if LDestinationPosition.Row < 1 then
    LDestinationPosition.Row := 1;

  LDestinationLineChar := ViewToTextPosition(LDestinationPosition);

  if not ASelectionCommand and (LDestinationLineChar.Line <> FPosition.BeginSelection.Line) then
  begin
    DoTrimTrailingSpaces(FPosition.BeginSelection.Line);
    DoTrimTrailingSpaces(LDestinationLineChar.Line);
  end;

  if not GetSelectionAvailable then
  begin
    FPosition.BeginSelection := TextPosition;
    FPosition.EndSelection := FPosition.BeginSelection;
  end;

  MoveCaretAndSelection(FPosition.BeginSelection, LDestinationLineChar, ASelectionCommand);
end;

procedure TCustomTextEditor.MoveLineDown;
var
  LTextPosition: TTextEditorTextPosition;
  LSelectionBeginPosition, LSelectionEndPosition: TTextEditorTextPosition;
  LLineText: string;
begin
  LTextPosition := TextPosition;
  if LTextPosition.Line < FLines.Count - 1 then
  begin
    LSelectionBeginPosition := SelectionBeginPosition;
    LSelectionEndPosition := SelectionEndPosition;

    FUndoList.BeginBlock;
    LLineText := FLines.Items^[LTextPosition.Line].TextLine;
    DeleteLine;
    Inc(LTextPosition.Line);

    InsertLine(Min(LTextPosition.Line + 1, FLines.Count + 1), LLineText);

    if LSelectionBeginPosition.Line = LTextPosition.Line - 1 then
    begin
      Inc(LSelectionBeginPosition.Line);
      Inc(LSelectionEndPosition.Line);
    end
    else
    if LSelectionBeginPosition.Line = LTextPosition.Line then
    begin
      Dec(LSelectionBeginPosition.Line);
      Dec(LSelectionEndPosition.Line);
    end;

    SetCaretAndSelection(LTextPosition, LSelectionBeginPosition, LSelectionEndPosition);
    FUndoList.EndBlock;
  end;
end;

procedure TCustomTextEditor.MoveLineUp;
var
  LTextPosition: TTextEditorTextPosition;
  LSelectionBeginPosition, LSelectionEndPosition: TTextEditorTextPosition;
  LLineText: string;
begin
  LTextPosition := TextPosition;
  if LTextPosition.Line > 0 then
  begin
    LSelectionBeginPosition := SelectionBeginPosition;
    LSelectionEndPosition := SelectionEndPosition;

    FUndoList.BeginBlock;
    LLineText := FLines.Items^[LTextPosition.Line].TextLine;
    DeleteLine;
    Dec(LTextPosition.Line);

    InsertLine(LTextPosition.Line + 1, LLineText);

    if LSelectionBeginPosition.Line = LTextPosition.Line + 1 then
    begin
      Dec(LSelectionBeginPosition.Line);
      Dec(LSelectionEndPosition.Line);
    end
    else
    if LSelectionBeginPosition.Line = LTextPosition.Line then
    begin
      Inc(LSelectionBeginPosition.Line);
      Inc(LSelectionEndPosition.Line);
    end;

    SetCaretAndSelection(LTextPosition, LSelectionBeginPosition, LSelectionEndPosition);
    FUndoList.EndBlock;
  end;
end;

procedure TCustomTextEditor.MultiCaretTimerHandler(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  FMultiCaret.Draw := not FMultiCaret.Draw;

  Invalidate;
end;

procedure TCustomTextEditor.OnCodeFoldingDelayTimer(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  FCodeFoldings.DelayTimer.Enabled := False;
  if FCodeFoldings.Rescan then
    RescanCodeFoldingRanges;
end;

procedure TCustomTextEditor.OpenLink(const AURI: string);
begin
  ShellExecute(0, nil, PChar(AURI), nil, nil, SW_SHOWNORMAL);
end;

procedure TCustomTextEditor.RemoveDuplicateMultiCarets;
var
  LIndex1, LIndex2: Integer;
  LPViewPosition1, LPViewPosition2: PTextEditorViewPosition;
begin
  if Assigned(FMultiCaret.Carets) then
  for LIndex1 := 0 to FMultiCaret.Carets.Count - 1 do
    for LIndex2 := FMultiCaret.Carets.Count - 1 downto LIndex1 + 1 do
    begin
      LPViewPosition1 := PTextEditorViewPosition(FMultiCaret.Carets[LIndex1]);
      LPViewPosition2 := PTextEditorViewPosition(FMultiCaret.Carets[LIndex2]);
      if (LPViewPosition1^.Row = LPViewPosition2^.Row) and
        (LPViewPosition1^.Column = LPViewPosition2^.Column) then
      begin
        Dispose(LPViewPosition2);
        FMultiCaret.Carets.Delete(LIndex2);
      end;
    end;
end;

procedure TCustomTextEditor.ReplaceChanged(const AEvent: TTextEditorReplaceChanges);
begin
  if AEvent = rcEngineUpdate then
    AssignSearchEngine(FReplace.Engine);
end;

procedure TCustomTextEditor.RightMarginChanged(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  if FWordWrap.Active and (FWordWrap.Width = wwwRightMargin) then
    FLineNumbers.ResetCache := True;

  if not (csLoading in ComponentState) then
    Invalidate;
end;

procedure TCustomTextEditor.RulerChanged(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  if not (csLoading in ComponentState) and FFile.Loaded then
    SizeOrFontChanged(False);

  Invalidate;
end;

procedure TCustomTextEditor.ScanCodeFoldingRanges;
const
  DEFAULT_CODE_FOLDING_RANGE_INDEX = 0;
var
  LLine, LFoldCount: Integer;
  LPText: PChar;
  LBeginningOfLine: Boolean;
  LPKeyWord, LPBookmarkText, LPBookmarkText2: PChar;
  LLastFoldRange: TTextEditorCodeFoldingRange;
  LOpenTokenSkipFoldRangeList: TList;
  LOpenTokenFoldRangeList: TList;
  LCodeFoldingRangeIndexList: TList;
  LFoldRanges: TTextEditorCodeFoldingRanges;
  LCurrentCodeFoldingRegion: TTextEditorCodeFoldingRegion;

  function IsWholeWord(const AFirstChar, ALastChar: PChar): Boolean; inline;
  begin
    Result := not (AFirstChar^ in TCharacterSets.ValidFoldingWord) and not (ALastChar^ in TCharacterSets.ValidFoldingWord);
  end;

  function CountCharsBefore(const APText: PChar; const Character: Char): Integer;
  var
    LPText: PChar;
  begin
    Result := 0;
    LPText := APText - 1;
    while LPText^ = Character do
    begin
      Inc(Result);
      Dec(LPText);
    end;
  end;

  function OddCountOfStringEscapeChars(const APText: PChar): Boolean;
  begin
    Result := False;
    if LCurrentCodeFoldingRegion.StringEscapeChar <> TControlCharacters.Null then
      Result := Odd(CountCharsBefore(APText, LCurrentCodeFoldingRegion.StringEscapeChar));
  end;

  function EscapeChar(const APText: PChar): Boolean;
  begin
    Result := False;
    if LCurrentCodeFoldingRegion.EscapeChar <> TControlCharacters.Null then
      Result := APText^ = LCurrentCodeFoldingRegion.EscapeChar;
  end;

  function IsNextSkipChar(const APText: PChar; const ASkipRegionItem: TTextEditorSkipRegionItem): Boolean;
  begin
    Result := False;
    if ASkipRegionItem.SkipIfNextCharIsNot <> TControlCharacters.Null then
      Result := APText^ = ASkipRegionItem.SkipIfNextCharIsNot;
  end;

  function SkipRegionsClose: Boolean;
  var
    LSkipRegionItem: TTextEditorSkipRegionItem;
  begin
    Result := False;
    { Note! Check Close before Open because close and open keys might be same. }
    if (LOpenTokenSkipFoldRangeList.Count > 0) and (LPText^ in FHighlighter.SkipCloseKeyChars) and
      not OddCountOfStringEscapeChars(LPText) then
    begin
      LSkipRegionItem := LOpenTokenSkipFoldRangeList.Last;
      LPKeyWord := PChar(LSkipRegionItem.CloseToken);
      LPBookmarkText := LPText;
      { Check if the close keyword found }
      while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and
        ((LPText^ = LPKeyWord^) or (LSkipRegionItem.SkipEmptyChars and (LPText^ < TCharacters.ExclamationMark))) do
      begin
        if (LPText^ <> TCharacters.Space) and (LPText^ <> TControlCharacters.Tab) and
          (LPText^ <> TControlCharacters.Substitute) then
          Inc(LPKeyWord);
        Inc(LPText);
      end;
      if LPKeyWord^ = TControlCharacters.Null then { If found, pop skip region from the stack }
      begin
        LOpenTokenSkipFoldRangeList.Delete(LOpenTokenSkipFoldRangeList.Count - 1);
        Result := True;
      end
      else
        LPText := LPBookmarkText; { Skip region close not found, return pointer back }
    end;
  end;

  function SkipRegionsOpen: Boolean;
  var
    LIndex, LCount: Integer;
    LSkipRegionItem: TTextEditorSkipRegionItem;
  begin
    Result := False;

    if LPText^ in FHighlighter.SkipOpenKeyChars then
      if LOpenTokenSkipFoldRangeList.Count = 0 then
      begin
        LCount := LCurrentCodeFoldingRegion.SkipRegions.Count - 1;
        for LIndex := 0 to LCount do
        begin
          LSkipRegionItem := LCurrentCodeFoldingRegion.SkipRegions[LIndex];
          if (LPText^ = PChar(LSkipRegionItem.OpenToken)^) and not OddCountOfStringEscapeChars(LPText) and
            not IsNextSkipChar(LPText + Length(LSkipRegionItem.OpenToken), LSkipRegionItem) then
          begin
            LPKeyWord := PChar(LSkipRegionItem.OpenToken);
            LPBookmarkText := LPText;
            { Check, if the open keyword found }
            while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and
              ((LPText^ = LPKeyWord^) or (LSkipRegionItem.SkipEmptyChars and (LPText^ < TCharacters.ExclamationMark))) do
            begin
              if not LSkipRegionItem.SkipEmptyChars or
                (LSkipRegionItem.SkipEmptyChars and (LPText^ <> TCharacters.Space) and
                (LPText^ <> TControlCharacters.Tab) and (LPText^ <> TControlCharacters.Substitute)) then
                Inc(LPKeyWord);
              Inc(LPText);
            end;
            if LPKeyWord^ = TControlCharacters.Null then { If found, skip single line comment or push skip region into stack }
            begin
              if LSkipRegionItem.RegionType = ritSingleLineString then
              begin
                LPKeyWord := PChar(LSkipRegionItem.CloseToken);
                while (LPText^ <> TControlCharacters.Null) and
                  ( (LPText^ <> LPKeyWord^) or (LPText^ = LPKeyWord^) and OddCountOfStringEscapeChars(LPText) ) do
                  Inc(LPText);
                Inc(LPText);
              end
              else
              if LSkipRegionItem.RegionType = ritSingleLineComment then
                { Single line comment skip until next line }
                Exit(True)
              else
                LOpenTokenSkipFoldRangeList.Add(LSkipRegionItem);
              Dec(LPText); { The end of the while loop will increase }
              Break;
            end
            else
              LPText := LPBookmarkText; { Skip region open not found, return pointer back }
          end;
        end;
      end;
  end;

  procedure RegionItemsClose;
  var
    LIndex, LItemIndex, LIndexDecrease: Integer;
    LCodeFoldingRange, LCodeFoldingRangeLast: TTextEditorCodeFoldingRange;

    procedure SetCodeFoldingRangeToLine(const ACodeFoldingRange: TTextEditorCodeFoldingRange);
    var
      LIndex: Integer;
    begin
      if ACodeFoldingRange.RegionItem.TokenEndIsPreviousLine then
      begin
        LIndex := LLine - 1;
        while (LIndex > 0) and (FLines[LIndex - 1] = '') do
          Dec(LIndex);
        ACodeFoldingRange.ToLine := LIndex
      end
      else
        ACodeFoldingRange.ToLine := LLine;
    end;

  begin
    if LOpenTokenSkipFoldRangeList.Count <> 0 then
      Exit;

    if LOpenTokenFoldRangeList.Count > 0 then
      if CaseUpper(LPText^) in FHighlighter.FoldCloseKeyChars then
      begin
        LIndexDecrease := 1;
        repeat
          LIndex := LOpenTokenFoldRangeList.Count - LIndexDecrease;
          if LIndex < 0 then
            Break;
          LCodeFoldingRange := LOpenTokenFoldRangeList.Items[LIndex];

          if LCodeFoldingRange.RegionItem.CloseTokenBeginningOfLine and not LBeginningOfLine then
            Exit;

          LPKeyWord := PChar(LCodeFoldingRange.RegionItem.CloseToken);
          LPBookmarkText := LPText;
          { Check if the close keyword found }
          while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and
            (CaseUpper(LPText^) = LPKeyWord^) do
          begin
            Inc(LPText);
            Inc(LPKeyWord);
          end;

          if LPKeyWord^ = TControlCharacters.Null then { If found, pop skip region from the stack }
          begin
            if not LCodeFoldingRange.RegionItem.BreakCharFollows or
              LCodeFoldingRange.RegionItem.BreakCharFollows and IsWholeWord(LPBookmarkText - 1, LPText) then
            begin
              LOpenTokenFoldRangeList.Remove(LCodeFoldingRange);
              Dec(LFoldCount);

              if LCodeFoldingRange.RegionItem.BreakIfNotFoundBeforeNextRegion <> '' then
                if not LCodeFoldingRange.IsExtraTokenFound then
                begin
                  LPText := LPBookmarkText;
                  Exit;
                end;

              SetCodeFoldingRangeToLine(LCodeFoldingRange);

              { Check if the code folding ranges have shared close }
              if LOpenTokenFoldRangeList.Count > 0 then
                for LItemIndex := LOpenTokenFoldRangeList.Count - 1 downto 0 do
                begin
                  LCodeFoldingRangeLast := LOpenTokenFoldRangeList.Items[LItemIndex];
                  if Assigned(LCodeFoldingRangeLast.RegionItem) and LCodeFoldingRangeLast.RegionItem.SharedClose then
                  begin
                    LPKeyWord := PChar(LCodeFoldingRangeLast.RegionItem.CloseToken);
                    LPText := LPBookmarkText;
                    while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and
                      (CaseUpper(LPText^) = LPKeyWord^) do
                    begin
                      Inc(LPText);
                      Inc(LPKeyWord);
                    end;
                    if LPKeyWord^ = TControlCharacters.Null then
                    begin
                      SetCodeFoldingRangeToLine(LCodeFoldingRangeLast);
                      LOpenTokenFoldRangeList.Remove(LCodeFoldingRangeLast);
                      Dec(LFoldCount);
                    end;
                  end;
                end;

              if not LCodeFoldingRange.RegionItem.NoDuplicateClose then
                LPText := LPBookmarkText; { Go back where we were }
            end
            else
              LPText := LPBookmarkText; { Region close not found, return pointer back }
          end
          else
            LPText := LPBookmarkText; { Region close not found, return pointer back }

          Inc(LIndexDecrease);
        until Assigned(LCodeFoldingRange) and ((LCodeFoldingRange.RegionItem.BreakIfNotFoundBeforeNextRegion = '') or
          (LOpenTokenFoldRangeList.Count - LIndexDecrease < 0));
      end;
  end;

  function RegionItemsOpen: Boolean;
  var
    LIndex, LArrayIndex: Integer;
    LSkipIfFoundAfterOpenToken: Boolean;
    LRegionItem: TTextEditorCodeFoldingRegionItem;
    LCodeFoldingRange: TTextEditorCodeFoldingRange;
    LPTempText, LPTempKeyWord: PChar;
    LTemp: string;
    LLength, LPosition: Integer;
  begin
    Result := False;

    if LOpenTokenSkipFoldRangeList.Count <> 0 then
      Exit;

    if CaseUpper(LPText^) in FHighlighter.FoldOpenKeyChars then
    begin
      LCodeFoldingRange := nil;

      if LOpenTokenFoldRangeList.Count > 0 then
        LCodeFoldingRange := LOpenTokenFoldRangeList.Last;

      if Assigned(LCodeFoldingRange) and LCodeFoldingRange.RegionItem.NoSubs then
        Exit;

      for LIndex := 0 to LCurrentCodeFoldingRegion.Count - 1 do
      begin
        LRegionItem := LCurrentCodeFoldingRegion[LIndex];
        if (LRegionItem.OpenTokenBeginningOfLine and LBeginningOfLine) or (not LRegionItem.OpenTokenBeginningOfLine) then
        begin
          { Check if extra token found }
          if Assigned(LCodeFoldingRange) then
          begin
            if LCodeFoldingRange.RegionItem.BreakIfNotFoundBeforeNextRegion <> '' then
              if LPText^ = PChar(LCodeFoldingRange.RegionItem.BreakIfNotFoundBeforeNextRegion)^ then { If first character match }
              begin
                LPKeyWord := PChar(LCodeFoldingRange.RegionItem.BreakIfNotFoundBeforeNextRegion);
                LPBookmarkText := LPText;
                { Check if open keyword found }
                while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and
                  ((CaseUpper(LPText^) = LPKeyWord^) or (LPText^ = TCharacters.Space) or
                  (LPText^ = TControlCharacters.Tab) or (LPText^ = TControlCharacters.Substitute)) do
                begin
                  if ((LPKeyWord^ = TCharacters.Space) or (LPKeyWord^ = TControlCharacters.Tab) or
                    (LPKeyWord^ = TControlCharacters.Substitute)) or
                    (LPText^ <> TCharacters.Space) and (LPText^ <> TControlCharacters.Tab) and
                    (LPText^ = TControlCharacters.Substitute) then
                    Inc(LPKeyWord);
                  Inc(LPText);
                end;

                if LPKeyWord^ = TControlCharacters.Null then
                begin
                  LCodeFoldingRange.IsExtraTokenFound := True;
                  Continue;
                end
                else
                  LPText := LPBookmarkText; { Region not found, return pointer back }
              end;
          end;
          { First word after newline }
          if CaseUpper(LPText^) = PChar(LRegionItem.OpenToken)^ then { If first character match }
          begin
            LPKeyWord := PChar(LRegionItem.OpenToken);
            LPBookmarkText := LPText;
            { Check if open keyword found }
            while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and
              (CaseUpper(LPText^) = LPKeyWord^) do
            begin
              Inc(LPText);
              Inc(LPKeyWord);
            end;

            if LRegionItem.OpenTokenCanBeFollowedBy <> '' then
              if CaseUpper(LPText^) = PChar(LRegionItem.OpenTokenCanBeFollowedBy)^ then
              begin
                LPTempText := LPText;
                LPTempKeyWord := PChar(LRegionItem.OpenTokenCanBeFollowedBy);
                while (LPTempText^ <> TControlCharacters.Null) and (LPTempKeyWord^ <> TControlCharacters.Null) and
                  (CaseUpper(LPTempText^) = LPTempKeyWord^) do
                begin
                  Inc(LPTempText);
                  Inc(LPTempKeyWord);
                end;

                if LPTempKeyWord^ = TControlCharacters.Null then
                  LPText := LPTempText;
              end;

            if LPKeyWord^ = TControlCharacters.Null then
            begin
              if (not LRegionItem.BreakCharFollows or LRegionItem.BreakCharFollows and IsWholeWord(LPBookmarkText - 1, LPText)) and
                not EscapeChar(LPBookmarkText - 1) then { Not interested in partial hits }
              begin
                { Check if special rule found }
                LSkipIfFoundAfterOpenToken := False;

                if LRegionItem.SkipIfFoundAfterOpenTokenArrayCount > 0 then
                begin
                  while LPText^ <> TControlCharacters.Null do
                  begin
                    for LArrayIndex := 0 to LRegionItem.SkipIfFoundAfterOpenTokenArrayCount - 1 do
                    begin
                      LPKeyWord := PChar(LRegionItem.SkipIfFoundAfterOpenTokenArray[LArrayIndex]);
                      LPBookmarkText2 := LPText;
                      if CaseUpper(LPText^) = LPKeyWord^ then { If first character match }
                      begin
                        while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and
                          (CaseUpper(LPText^) = LPKeyWord^) do
                        begin
                          Inc(LPText);
                          Inc(LPKeyWord);
                        end;

                        if LPKeyWord^ = TControlCharacters.Null then
                        begin
                          LSkipIfFoundAfterOpenToken := True;
                          Break; { for }
                        end
                        else
                          LPText := LPBookmarkText2; { Region not found, return pointer back }
                      end;
                    end;

                    if LSkipIfFoundAfterOpenToken then
                      Break; { while }

                    Inc(LPText);
                  end;
                end;

                if LSkipIfFoundAfterOpenToken then
                begin
                  LPText := LPBookmarkText; { Skip found, return pointer back }
                  Continue;
                end;

                { Visual Basic has one liner if statements, skip if found. }
                if LRegionItem.CheckIfThenOneLiner then
                begin
                  LPTempText := LPText;
                  LLength := 0;
                  while LPText^ <> TControlCharacters.Null do
                  begin
                    Inc(LLength);
                    Inc(LPText);
                  end;
                  LPText := LPTempText;
                  SetString(LTemp, LPText, LLength + 1); { +1 from #0 }
                  LTemp := TextEditor.Utils.Trim(LTemp);
                  LPosition := Pos('THEN', UpperCase(LTemp));
                  if LPosition > 0 then
                    if LPosition + 4 < Length(LTemp) then
                    begin
                      LPText := LPBookmarkText; { Skip found, return pointer back }
                      Continue;
                    end;
                end;

                if Assigned(LCodeFoldingRange) and (LCodeFoldingRange.RegionItem.BreakIfNotFoundBeforeNextRegion <> '')
                  and not LCodeFoldingRange.IsExtraTokenFound and not LRegionItem.RemoveRange then
                begin
                  LOpenTokenFoldRangeList.Remove(LCodeFoldingRange);
                  Dec(LFoldCount);
                end;

                if LOpenTokenFoldRangeList.Count > 0 then
                  LFoldRanges := TTextEditorCodeFoldingRange(LOpenTokenFoldRangeList.Last).SubCodeFoldingRanges
                else
                  LFoldRanges := FCodeFoldings.AllRanges;

                LCodeFoldingRange := LFoldRanges.Add(FCodeFoldings.AllRanges, LLine, GetLineIndentLevel(LLine - 1),
                  LFoldCount, LRegionItem, LLine);
                { Open keyword found }
                LOpenTokenFoldRangeList.Add(LCodeFoldingRange);
                Inc(LFoldCount);
                Dec(LPText); { The end of the while loop will increase }
                Result := LRegionItem.OpenTokenBreaksLine;

                if LRegionItem.OpenTokenBreaksLine and LRegionItem.RemoveRange then
                begin
                  LOpenTokenFoldRangeList.Remove(LCodeFoldingRange);
                  Dec(LFoldCount);
                end;

                Break;
              end
              else
                LPText := LPBookmarkText; { Region not found, return pointer back }
            end
            else
              LPText := LPBookmarkText; { Region not found, return pointer back }
          end;
        end;
      end;
    end;
  end;

  function MultiHighlighterOpen: Boolean;
  var
    LIndex: Integer;
    LCodeFoldingRegion: TTextEditorCodeFoldingRegion;
    LChar: Char;
  begin
    Result := False;

    if LOpenTokenSkipFoldRangeList.Count <> 0 then
      Exit;

    LChar := CaseUpper(LPText^);
    LPBookmarkText := LPText;
    for LIndex := 1 to Highlighter.CodeFoldingRangeCount - 1 do { First (0) is the default range }
    begin
      LCodeFoldingRegion := Highlighter.CodeFoldingRegions[LIndex];

      if LChar = PChar(LCodeFoldingRegion.OpenToken)^ then { If first character match }
      begin
        LPKeyWord := PChar(LCodeFoldingRegion.OpenToken);
        { Check if open keyword found }
        while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and
          (CaseUpper(LPText^) = LPKeyWord^) do
        begin
          Inc(LPText);
          Inc(LPKeyWord);
        end;

        LPText := LPBookmarkText; { Return pointer always back }

        if LPKeyWord^ = TControlCharacters.Null then
        begin
          LCodeFoldingRangeIndexList.Add(Pointer(LIndex));
          LCurrentCodeFoldingRegion := Highlighter.CodeFoldingRegions[LIndex];

          Exit(True);
        end
      end;
    end;
  end;

  procedure MultiHighlighterClose;
  var
    LIndex: Integer;
    LCodeFoldingRegion: TTextEditorCodeFoldingRegion;
    LChar: Char;
  begin
    if LOpenTokenSkipFoldRangeList.Count <> 0 then
      Exit;
    LChar := CaseUpper(LPText^);
    LPBookmarkText := LPText;
    for LIndex := 1 to Highlighter.CodeFoldingRangeCount - 1 do { First (0) is the default range }
    begin
      LCodeFoldingRegion := Highlighter.CodeFoldingRegions[LIndex];

      if LChar = PChar(LCodeFoldingRegion.CloseToken)^ then { If first character match }
      begin
        LPKeyWord := PChar(LCodeFoldingRegion.CloseToken);
        { Check if close keyword found }
        while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and
          (CaseUpper(LPText^) = LPKeyWord^) do
        begin
          Inc(LPText);
          Inc(LPKeyWord);
        end;

        LPText := LPBookmarkText; { Return pointer always back }

        if LPKeyWord^ = TControlCharacters.Null then
        begin
          if LCodeFoldingRangeIndexList.Count > 0 then
            LCodeFoldingRangeIndexList.Delete(LCodeFoldingRangeIndexList.Count - 1);
          if LCodeFoldingRangeIndexList.Count > 0 then
            LCurrentCodeFoldingRegion := Highlighter.CodeFoldingRegions[Integer(LCodeFoldingRangeIndexList.Last)]
          else
            LCurrentCodeFoldingRegion := Highlighter.CodeFoldingRegions[DEFAULT_CODE_FOLDING_RANGE_INDEX];

          Exit;
        end
      end;
    end;
  end;

  procedure AddTagFolds;
  var
    LPText: PChar;
    LTokenName, LTokenAttributes: string;
    LAdded: Boolean;
    LOpenToken, LCloseToken: string;
    LRegionItem: TTextEditorCodeFoldingRegionItem;
    LDefaultRegion: TTextEditorCodeFoldingRegion;
    LMultilineTag: Boolean;
  begin
    LDefaultRegion := FHighlighter.CodeFoldingRegions[0];

    LPText := PChar(FLines.Text);
    LAdded := False;
    while LPText^ <> TControlCharacters.Null do
    begin
      if LPText^ = '<' then
      begin
        Inc(LPText);
        if not (LPText^ in ['?', '!', '/']) then
        begin
          LTokenName := '';
          LMultilineTag := False;
          while (LPText^ <> TControlCharacters.Null) and not (LPText^ in [' ', '>']) do
          begin
            if LPText^ in [TControlCharacters.CarriageReturn, TControlCharacters.Linefeed] then
            begin
              LMultilineTag := True;
              Break;
            end;

            LTokenName := LTokenName + CaseUpper(LPText^);
            Inc(LPText);
          end;

          LTokenAttributes := '';
          if LPText^ = ' ' then
          while (LPText^ <> TControlCharacters.Null) and not (LPText^ in ['/', '>']) do
          begin
            if LPText^ in [TControlCharacters.CarriageReturn, TControlCharacters.Linefeed] then
            begin
              LMultilineTag := True;
              Break;
            end;
            LTokenAttributes := LTokenAttributes + CaseUpper(LPText^);
            Inc(LPText);
            if (LPText^ in ['"', '''']) then
            begin
              LTokenAttributes := LTokenAttributes + CaseUpper(LPText^);
              Inc(LPText);
              while (LPText^ <> TControlCharacters.Null) and not (LPText^ in ['"', '''']) do
              begin
                LTokenAttributes := LTokenAttributes + CaseUpper(LPText^);
                Inc(LPText);
              end;
            end;
          end;

          LOpenToken := '<' + LTokenName + LTokenAttributes + LPText^;
          LOpenToken := LOpenToken.Trim;
          LCloseToken := '</' + LTokenName + '>';

          if LMultilineTag or (LPText^ = '>') and ((LPText - 1)^ <> '/') then
            if not LDefaultRegion.Contains(LOpenToken, LCloseToken) then
            begin
              LRegionItem := LDefaultRegion.Add(LOpenToken, LCloseToken);
              LRegionItem.BreakCharFollows := False;
              LAdded := True;
            end;
        end;
      end;
      Inc(LPText);
    end;
    if LAdded then
    begin
      FHighlighter.AddKeyChar(ctFoldOpen, '<');
      FHighlighter.AddKeyChar(ctFoldClose, '<');
    end;
  end;

  procedure ScanCodeFolds;
  var
    LIndex, LPreviousLine: Integer;
    LCodeFoldingRange: TTextEditorCodeFoldingRange;
    LProgressPosition, LProgress, LProgressInc: Int64;
  begin
    LFoldCount := 0;
    LOpenTokenSkipFoldRangeList := TList.Create;
    LOpenTokenFoldRangeList := TList.Create;
    LCodeFoldingRangeIndexList := TList.Create;
    try
      if FHighlighter.FoldTags then
        AddTagFolds;

      { Go through the text line by line, character by character }
      LPreviousLine := -1;

      LCodeFoldingRangeIndexList.Add(Pointer(DEFAULT_CODE_FOLDING_RANGE_INDEX));

      if Highlighter.CodeFoldingRangeCount > 0 then
        LCurrentCodeFoldingRegion := Highlighter.CodeFoldingRegions[DEFAULT_CODE_FOLDING_RANGE_INDEX];

      LProgress := 0;
      LProgressPosition := 0;
      LProgressInc := 0;
      if FLines.ShowProgress then
      begin
        FLines.ProgressPosition := 0;
        FLines.ProgressType := ptProcessing;
        LProgressInc := (Length(FLineNumbers.Cache) - 1) div 100;
      end;

      for LIndex := 1 to Length(FLineNumbers.Cache) - 1 do
      begin
        LLine := FLineNumbers.Cache[LIndex];
        LCodeFoldingRange := nil;
        if LLine < Length(FCodeFoldings.RangeFromLine) then
          LCodeFoldingRange := FCodeFoldings.RangeFromLine[LLine];
        if Assigned(LCodeFoldingRange) and LCodeFoldingRange.Collapsed then
        begin
          LPreviousLine := LLine;
          Continue;
        end;

        if LPreviousLine <> LLine then
        begin
          LPText := PChar(FLines[LLine - 1]); { 0-based }
          LBeginningOfLine := True;
          while LPText^ <> TControlCharacters.Null do
          begin
            { SkipEmptySpace }
            while (LPText^ <> TControlCharacters.Null) and (LPText^ < TCharacters.ExclamationMark) do
              Inc(LPText);
            if LPText^ = TControlCharacters.Null then
              Break;

            if hoMultiHighlighter in Highlighter.Options then
              if not MultiHighlighterOpen then
                MultiHighlighterClose;

            if SkipRegionsClose then
              Continue; { while LPText^ <> TControlCharacters.Null do }
            if SkipRegionsOpen then
              Break; { Line comment breaks }

            { SkipEmptySpace }
            while (LPText^ <> TControlCharacters.Null) and (LPText^ < TCharacters.ExclamationMark) do
              Inc(LPText);
            if LPText^ = TControlCharacters.Null then
              Break;

            if LOpenTokenSkipFoldRangeList.Count = 0 then
            begin
              RegionItemsClose;
              if RegionItemsOpen then
                Break; { OpenTokenBreaksLine region item option breaks }
            end;

            if LPText^ <> TControlCharacters.Null then
              Inc(LPText);

            { Skip rest of the word }
            while (LPText^ <> TControlCharacters.Null) and (LPText^ in TCharacterSets.CharactersAndNumbers) do
              Inc(LPText);

            LBeginningOfLine := False; { Not in the beginning of the line anymore }
          end;
        end;
        LPreviousLine := LLine;

        if FLines.ShowProgress then
        begin
          Inc(LProgressPosition);
          if LProgressPosition > LProgress then
          begin
            FLines.ProgressPosition := FLines.ProgressPosition + 1;
            if Assigned(FEvents.OnLoadingProgress) then
              FEvents.OnLoadingProgress(Self)
            else
              Paint;
            Inc(LProgress, LProgressInc);
          end;
        end;
      end;
      { Check the last not empty line }
      LLine := FLines.Count - 1;
      while (LLine >= 0) and (System.SysUtils.Trim(FLines[LLine]) = '') do
        Dec(LLine);
      if LLine >= 0 then
      begin
        LPText := PChar(FLines[LLine]);
        while LOpenTokenFoldRangeList.Count > 0 do
        begin
          LLastFoldRange := LOpenTokenFoldRangeList.Last;
          if Assigned(LLastFoldRange) then
          begin
            Inc(LLine);
            LLine := Min(LLine, FLines.Count);
            if LLastFoldRange.RegionItem.OpenIsClose then
              LLastFoldRange.ToLine := LLine;
            LOpenTokenFoldRangeList.Remove(LLastFoldRange);
            Dec(LFoldCount);
            RegionItemsClose;
          end;
        end;
      end;
    finally
      LCodeFoldingRangeIndexList.Free;
      LOpenTokenSkipFoldRangeList.Free;
      LOpenTokenFoldRangeList.Free;
    end;
  end;

  procedure ScanTextFolds;
  var
    LIndex, LPreviousLine: Integer;
    LCodeFoldingRange: TTextEditorCodeFoldingRange;
    LCharCount, LPreviousCharCount: Integer;
    LFoldRangeList: TList;
    LFoldRange: TTextEditorCodeFoldingRange;
    LTextLine: string;
    LCommentIndex, LBlockCommentIndex, LLength: Integer;
    LCommentFound, LInsideBlockComment: Boolean;
    LProgressPosition, LProgress, LProgressInc: Int64;

    function LeftCharCount(const ALine: string; const AChar: Char): Integer;
    var
      LIndex: Integer;
    begin
      Result := 0;

      for LIndex := 1 to Length(ALine) do
      if ALine[LIndex] = AChar then
        Inc(result)
      else
        Break;
    end;

  begin
    LPreviousLine := -1;
    LPreviousCharCount := -1;
    LBlockCommentIndex := 0;
    LInsideBlockComment := False;
    LFoldRangeList := TList.Create;
    try
      LProgress := 0;
      LProgressPosition := 0;
      LProgressInc := 0;
      if FLines.ShowProgress then
      begin
        FLines.ProgressPosition := 0;
        FLines.ProgressType := ptProcessing;
        LProgressInc := (Length(FLineNumbers.Cache) - 1) div 100;
      end;

      for LIndex := 1 to Length(FLineNumbers.Cache) - 1 do
      begin
        LLine := FLineNumbers.Cache[LIndex];
        LCodeFoldingRange := nil;
        if LLine < Length(FCodeFoldings.RangeFromLine) then
          LCodeFoldingRange := FCodeFoldings.RangeFromLine[LLine];
        if Assigned(LCodeFoldingRange) and LCodeFoldingRange.Collapsed then
        begin
          LPreviousLine := LLine;
          Continue;
        end;

        LTextLine := TextEditor.Utils.Trim(FLines[LLine - 1]);

        if FCodeFolding.Outlining then
          if LTextLine <> '' then
          begin
            if LInsideBlockComment then
            begin
              LInsideBlockComment := FastPos(FHighlighter.Comments.BlockComments[LBlockCommentIndex], LTextLine) = 0;
              if LInsideBlockComment then
                Continue;
            end
            else
            begin
              LCommentFound := False;
              LCommentIndex := 0;
              LLength := Length(FHighlighter.Comments.LineComments);
              while LCommentIndex < LLength do
              begin
                if FastPos(FHighlighter.Comments.LineComments[LCommentIndex], LTextLine) = 1 then
                begin
                  LCommentFound := True;
                  Break;
                end;
                Inc(LCommentIndex);
              end;
              if LCommentFound then
                Continue;

              if not (cfoFoldMultilineComments in FCodeFolding.Options) then
              begin
                LInsideBlockComment := False;
                LCommentIndex := 0;
                LLength := Length(FHighlighter.Comments.BlockComments);
                while LCommentIndex < LLength do
                begin
                  if (FastPos(FHighlighter.Comments.BlockComments[LCommentIndex], LTextLine) <> 0) and
                    (FastPos(FHighlighter.Comments.BlockComments[LCommentIndex + 1], LTextLine) = 0)then
                  begin
                    LInsideBlockComment := True;
                    LBlockCommentIndex := LCommentIndex + 1;
                    Break;
                  end;
                  Inc(LCommentIndex, 2);
                end;
                if LInsideBlockComment then
                  Continue;
              end;
            end;
          end;

        if LPreviousLine <> LLine then
        begin
          LTextLine := FLines[LLine - 1];

          if FCodeFolding.TextFolding.OutlinedBySpacesAndTabs then
            LCharCount := LeftSpaceCount(LTextLine, True)
          else
            LCharCount := LeftCharCount(LTextLine, FCodeFolding.TextFolding.OutlineCharacter);

          if LFoldRangeList.Count > 0 then
          begin
            LLastFoldRange := TTextEditorCodeFoldingRange(LFoldRangeList.Last);
            LFoldRanges := LLastFoldRange.SubCodeFoldingRanges
          end
          else
          begin
            LLastFoldRange := nil;
            LFoldRanges := FCodeFoldings.AllRanges;
          end;

          if TextEditor.Utils.Trim(LTextLine) = '' then
          while LFoldRangeList.Count > 0 do
          begin
            LLastFoldRange.ToLine := LLine - 1;
            LFoldRangeList.Remove(LLastFoldRange);
            if LFoldRangeList.Count > 0 then
              LLastFoldRange := TTextEditorCodeFoldingRange(LFoldRangeList.Last);
          end
          else
          if LCharCount > LPreviousCharCount then
            LFoldRangeList.Add(LFoldRanges.Add(FCodeFoldings.AllRanges, LLine, 0, LCharCount, nil, LLine))
          else
          if (LCharCount < LPreviousCharCount) and (LFoldRangeList.Count > 0) then
          begin
            while (LFoldRangeList.Count > 0) and (LLastFoldRange.FoldRangeLevel > LCharCount) do
            begin
              LLastFoldRange.ToLine := LLine - 1;
              LFoldRangeList.Remove(LLastFoldRange);
              if LFoldRangeList.Count > 0 then
                LLastFoldRange := TTextEditorCodeFoldingRange(LFoldRangeList.Last);
            end;
            if (LFoldRangeList.Count = 0) or (TTextEditorCodeFoldingRange(LFoldRangeList.Last).FoldRangeLevel <> LCharCount) then
              LFoldRangeList.Add(LFoldRanges.Add(FCodeFoldings.AllRanges, LLine, 0, LCharCount, nil, LLine));
          end
          else
          if (TextEditor.Utils.Trim(LTextLine) <> '') and (LFoldRangeList.Count = 0) then
            LFoldRangeList.Add(LFoldRanges.Add(FCodeFoldings.AllRanges, LLine, 0, LCharCount, nil, LLine));

          LPreviousCharCount := LCharCount;
        end;
        LPreviousLine := LLine;

        if FLines.ShowProgress then
        begin
          Inc(LProgressPosition);
          if LProgressPosition > LProgress then
          begin
            FLines.ProgressPosition := FLines.ProgressPosition + 1;
            if Assigned(FEvents.OnLoadingProgress) then
              FEvents.OnLoadingProgress(Self)
            else
              Paint;
            Inc(LProgress, LProgressInc);
          end;
        end;
      end;

      LLine := FLines.Count - 1;
      while (LLine >= 0) and (TextEditor.Utils.Trim(FLines[LLine]) = '') do
        Dec(LLine);

      if LLine >= 0 then
      while LFoldRangeList.Count > 0 do
      begin
        LFoldRange := TTextEditorCodeFoldingRange(LFoldRangeList.First);
        if Assigned(LFoldRange) then
        begin
          Inc(LLine);
          LLine := Min(LLine, FLines.Count);
          LFoldRange.ToLine := LLine;
          LFoldRangeList.Remove(LFoldRange);
        end;
      end;
    finally
      LFoldRangeList.Free;
    end;
  end;

begin
  if not Assigned(FLineNumbers.Cache) or not FCodeFolding.Visible then
    Exit;

  if FCodeFolding.TextFolding.Active then
    ScanTextFolds
  else
    ScanCodeFolds;
end;

procedure TCustomTextEditor.InitializeScrollShadow;
var
  LIndex: Integer;
begin
  FScrollHelper.Shadow.BlendFunction.SourceConstantAlpha := FScroll.Shadow.AlphaBlending;

  if not Assigned(FScrollHelper.Shadow.Bitmap) then
  begin
    FScrollHelper.Shadow.Bitmap := Vcl.Graphics.TBitmap.Create;
    FScrollHelper.Shadow.Bitmap.PixelFormat := pf32Bit;
  end;

  FScrollHelper.Shadow.Bitmap.Canvas.Brush.Color := FScroll.Shadow.Color;
  FScrollHelper.Shadow.Bitmap.Width := Max(FScroll.Shadow.Width, 1);

  SetLength(FScrollHelper.Shadow.AlphaArray, FScrollHelper.Shadow.Bitmap.Width);
  if FScrollHelper.Shadow.AlphaByteArrayLength <> FScrollHelper.Shadow.Bitmap.Width then
  begin
    FScrollHelper.Shadow.AlphaByteArrayLength := FScrollHelper.Shadow.Bitmap.Width;
    ReallocMem(FScrollHelper.Shadow.AlphaByteArray, FScrollHelper.Shadow.AlphaByteArrayLength * SizeOf(Byte));
  end;

  for LIndex := 0 to FScrollHelper.Shadow.Bitmap.Width - 1 do
  begin
    FScrollHelper.Shadow.AlphaArray[LIndex] := (FScrollHelper.Shadow.Bitmap.Width - LIndex) / FScrollHelper.Shadow.Bitmap.Width;
    FScrollHelper.Shadow.AlphaByteArray[LIndex] := Min(Round(Power(FScrollHelper.Shadow.AlphaArray[LIndex], 4) * 255.0), 255);
  end;
end;

procedure TCustomTextEditor.ScrollingChanged(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  if FScroll.Shadow.Visible then
    InitializeScrollShadow
  else
    FreeScrollShadowBitmap;

  UpdateScrollBars;
end;

procedure TCustomTextEditor.ScrollTimerHandler(ASender: TObject); //FI:O804 Method parameter is declared but never used
var
  LLine: Integer;
  LCursorPoint: TPoint;
  LViewPosition: TTextEditorViewPosition;
  LTextPosition: TTextEditorTextPosition;
begin
  IncPaintLock;
  try
    Winapi.Windows.GetCursorPos(LCursorPoint);
    LCursorPoint := ScreenToClient(LCursorPoint);
    LViewPosition := PixelsToViewPosition(LCursorPoint.X, LCursorPoint.Y);

    LViewPosition.Row := EnsureRange(LViewPosition.Row, 1, Max(FLineNumbers.Count, 1));
    if LCursorPoint.Y > ClientRect.Height then
      LViewPosition.Column := FLines.Items^[LViewPosition.Row - 1].ExpandedLength + 1;
    if FScrollHelper.Delta.X <> 0 then
      SetHorizontalScrollPosition(FScrollHelper.HorizontalPosition + FScrollHelper.Delta.X);
    if FScrollHelper.Delta.Y <> 0 then
    begin
      if GetKeyState(vkShift) < 0 then
        TopLine := TopLine + FScrollHelper.Delta.Y * VisibleLineCount
      else
        TopLine := TopLine + FScrollHelper.Delta.Y;
      LLine := TopLine;
      if FScrollHelper.Delta.Y > 0 then
        Inc(LLine, VisibleLineCount - 1);
      LViewPosition.Row := EnsureRange(LLine, 1, Max(FLineNumbers.Count, 1));
    end;

    if not FMouse.IsScrolling then
    begin
      LTextPosition := ViewToTextPosition(LViewPosition);
      if not IsSamePosition(TextPosition, LTextPosition) then
      begin
        TextPosition := LTextPosition;
        if MouseCapture then
          SetSelectionEndPosition(LTextPosition);
      end;
    end;
  finally
    DecPaintLock;
  end;
  ComputeScroll(LCursorPoint);
end;

function TCustomTextEditor.GetPreviousBreakPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition;
var
  LPLine: PChar;
begin
  Result := ATextPosition;

  LPLine := PChar(FLines.Items^[ATextPosition.Line].TextLine);
  Inc(LPLine, ATextPosition.Char - 1);

  if not IsWordBreakChar(LPLine^) then
  begin
    while not IsWordBreakChar(LPLine^) and (Result.Char > 0) do
    begin
      Dec(LPLine);
      Dec(Result.Char);
    end;

    Inc(Result.Char);
  end;
end;

function TCustomTextEditor.GetNextBreakPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition;
var
  LPLine: PChar;
  LTextLine: string;
  LLength: Integer;
begin
  Result := ATextPosition;

  LTextLine := FLines.Items^[ATextPosition.Line].TextLine;
  LLength := Length(LTextLine);
  LPLine := PChar(LTextLine);
  Inc(LPLine, ATextPosition.Char - 1);

  if (ATextPosition.Char > 1) and not IsWordBreakChar((LPLine - 1)^) then
  begin
    while not IsWordBreakChar(LPLine^) and (Result.Char < LLength) do
    begin
      Inc(LPLine);
      Inc(Result.Char);
    end;
    Dec(Result.Char);
  end;
end;

procedure TCustomTextEditor.SearchChanged(const AEvent: TTextEditorSearchChanges);
begin
  case AEvent of
    scEngineUpdate:
      begin
        AssignSearchEngine(FSearch.Engine);

        SearchAll;

        if Assigned(FEvents.OnSearchEngineChanged) then
          FEvents.OnSearchEngineChanged(Self);
      end;
    scSearch:
      if FSearch.Enabled then
      begin
        SearchAll;

        if not Assigned(Parent) then
          Exit;

        if FSearch.InSelection.Active and
          not IsSamePosition(FSearch.InSelection.SelectionBeginPosition, FSearch.InSelection.SelectionEndPosition) then
          TextPosition := FSearch.InSelection.SelectionBeginPosition
        else
        if soEntireScope in FSearch.Options then
          TextPosition := GetPosition(1, 0);

        if SelectionAvailable then
          TextPosition := SelectionBeginPosition;

        FindNext;
      end;
    scInSelectionActive:
      begin
        if FSearch.InSelection.Active then
        begin
          FSearch.InSelection.SelectionBeginPosition := GetPreviousBreakPosition(SelectionBeginPosition);
          FSearch.InSelection.SelectionEndPosition := GetNextBreakPosition(SelectionEndPosition);
          FPosition.BeginSelection := TextPosition;
          FPosition.EndSelection := FPosition.BeginSelection;
        end;

        SearchAll;
      end;
    scVisible:
      SizeOrFontChanged(False);
  end;

  FLeftMarginWidth := GetLeftMarginWidth;
  ClearMinimapBuffer;

  Invalidate;
end;

procedure TCustomTextEditor.SelectionChanged(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  Invalidate;
end;

procedure TCustomTextEditor.SetActiveLine(const AValue: TTextEditorActiveLine);
begin
  FActiveLine.Assign(AValue);
end;

procedure TCustomTextEditor.SetBorderStyle(const AValue: TBorderStyle);
begin
  if FBorderStyle <> AValue then
  begin
    FBorderStyle := AValue;

    RecreateWnd;
  end;
end;

procedure TCustomTextEditor.SetCaretIndex(const AValue: Integer);
var
  LPText: PChar;
  LIndex: Integer;
  LLineFeed: Boolean;
  LTextPosition: TTextEditorTextPosition;
begin
  LPText := PChar(Text);
  LIndex := 0;
  LTextPosition.Char := 1;
  LTextPosition.Line := 0;
  while (LPText^ <> TControlCharacters.Null) and (LIndex < AValue) do
  begin
    LLineFeed := LPText^ in [TControlCharacters.CarriageReturn, TControlCharacters.Linefeed];

    if LPText^ = TControlCharacters.CarriageReturn then
    begin
      Inc(LIndex);
      Inc(LPText);
    end;

    if LPText^ = TControlCharacters.Linefeed then
    begin
      Inc(LIndex);
      Inc(LPText);
    end;

    if LLineFeed then
    begin
      LTextPosition.Char := 1;
      LTextPosition.Line := LTextPosition.Line + 1;
    end
    else
    begin
      LTextPosition.Char := LTextPosition.Char + 1;
      Inc(LIndex);
      Inc(LPText);
    end;
  end;

  TextPosition := LTextPosition;
end;

procedure TCustomTextEditor.SetCodeFolding(const AValue: TTextEditorCodeFolding);
begin
  FCodeFolding.Assign(AValue);

  if AValue.Visible then
    InitCodeFolding;
end;

procedure TCustomTextEditor.SetDefaultKeyCommands;
begin
  FKeyCommands.ResetDefaults;
end;

procedure TCustomTextEditor.SetOvertypeMode(const AValue: TTextEditorOvertypeMode);
begin
  if FOvertypeMode <> AValue then
  begin
    FOvertypeMode := AValue;

    if not (csDesigning in ComponentState) then
    begin
      ResetCaret;
      ShowCaret;
    end;
  end;
end;

procedure TCustomTextEditor.SetTextCaretX(const AValue: Integer);
var
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition.Char := AValue;
  LTextPosition.Line := TextPosition.Line;
  TextPosition := LTextPosition;
end;

procedure TCustomTextEditor.SetTextCaretY(const AValue: Integer);
var
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition.Char := TextPosition.Char;
  LTextPosition.Line := AValue;
  TextPosition := LTextPosition;
end;

procedure TCustomTextEditor.SetHorizontalScrollPosition(const AValue: Integer);
var
  LValue: Integer;
begin
  if Assigned(Parent) then
    if GetWindowLong(Handle, GWL_STYLE) and WS_HSCROLL = 0 then
      Exit;

  LValue := AValue;
  if FWordWrap.Active or (LValue < 0) then
    LValue := 0;

  if FScrollHelper.HorizontalPosition <> LValue then
  begin
    FScrollHelper.HorizontalPosition := LValue;
    UpdateScrollBars;
  end;
end;

procedure TCustomTextEditor.SetKeyCommands(const AValue: TTextEditorKeyCommands);
begin
  if Assigned(AValue) then
    FKeyCommands.Assign(AValue)
  else
    FKeyCommands.Clear;
end;

procedure TCustomTextEditor.SetLeftMargin(const AValue: TTextEditorLeftMargin);
begin
  FLeftMargin.Assign(AValue);
end;

procedure TCustomTextEditor.SetLines(const AValue: TTextEditorLines);
begin
  ClearBookmarks;
  ClearCodeFolding;

  FLines.Assign(AValue);

  CreateLineNumbersCache(True);
  SizeOrFontChanged;
  InitCodeFolding;
end;

procedure TCustomTextEditor.SetModified(const AValue: Boolean);
var
  LIndex: Integer;
begin
  if FState.Modified <> AValue then
  begin
    FState.Modified := AValue;

    if AValue and Assigned(FEvents.OnModified) then
      FEvents.OnModified(Self);

    if (uoGroupUndo in FUndo.Options) and UndoList.CanUndo and not AValue then
      FUndoList.AddGroupBreak;

    if not FState.Modified then
    begin
      for LIndex := 0 to FLines.Count - 1 do
      if FLines.LineState[LIndex] = lsModified then
        FLines.LineState[LIndex] := lsNormal;

      Invalidate;
    end;
  end;
end;

procedure TCustomTextEditor.SetMouseScrollCursors(const AIndex: Integer; const AValue: HCursor);
begin
  if (AIndex >= Low(FMouse.ScrollCursors)) and (AIndex <= High(FMouse.ScrollCursors)) then
    FMouse.ScrollCursors[AIndex] := AValue;
end;

procedure TCustomTextEditor.SetOptions(const AValue: TTextEditorOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;

    if (eoDropFiles in FOptions) <> (eoDropFiles in AValue) and not (csDesigning in ComponentState) and HandleAllocated then
      DragAcceptFiles(Handle, eoDropFiles in FOptions);

    Invalidate;
  end;
end;

procedure TCustomTextEditor.SetTextPosition(const AValue: TTextEditorTextPosition);
begin
  SetViewPosition(TextToViewPosition(AValue));
end;

procedure TCustomTextEditor.SetRightMargin(const AValue: TTextEditorRightMargin);
begin
  FRightMargin.Assign(AValue);
end;

procedure TCustomTextEditor.SetScroll(const AValue: TTextEditorScroll);
begin
  FScroll.Assign(AValue);
end;

procedure TCustomTextEditor.SetSearch(const AValue: TTextEditorSearch);
begin
  FSearch.Assign(AValue);
end;

procedure TCustomTextEditor.SetSelectedText(const AValue: string);
var
  LTextPosition, LBlockStartPosition, LBlockEndPosition: TTextEditorTextPosition;
begin
  ClearCodeFolding;
  try
    LTextPosition := TextPosition;

    LBlockStartPosition := SelectionBeginPosition;
    LBlockEndPosition := SelectionEndPosition;

    if GetSelectionAvailable then
      FUndoList.AddChange(crDelete, LTextPosition, LBlockStartPosition, LBlockEndPosition, GetSelectedText,
        FSelection.ActiveMode)
    else
      FSelection.ActiveMode := FSelection.Mode;

    DoSelectedText(AValue);

    if (AValue <> '') and (FSelection.ActiveMode <> smColumn) then
      FUndoList.AddChange(crInsert, TextPosition, SelectionBeginPosition, SelectionEndPosition, '',
        FSelection.ActiveMode);
  finally
    InitCodeFolding;
  end;
end;

procedure TCustomTextEditor.SetSelectedWord;
begin
  SetWordBlock(TextPosition);
end;

procedure TCustomTextEditor.SetSelection(const AValue: TTextEditorSelection);
begin
  FSelection.Assign(AValue);
end;

procedure TCustomTextEditor.SetSelectionBeginPosition(const AValue: TTextEditorTextPosition);
var
  LValue: TTextEditorTextPosition;
begin
  FSelection.ActiveMode := Selection.Mode;
  LValue := AValue;

  LValue.Line := EnsureRange(LValue.Line, 0, Max(FLines.Count - 1, 0));
  if FSelection.Mode = smNormal then
    LValue.Char := EnsureRange(LValue.Char, 1, FLines.StringLength(LValue.Line) + 1)
  else
    LValue.Char := Max(LValue.Char, 1);

  FPosition.BeginSelection := LValue;
  FPosition.EndSelection := LValue;

  Invalidate;
end;

procedure TCustomTextEditor.SetSelectionEndPosition(const AValue: TTextEditorTextPosition);
var
  LValue: TTextEditorTextPosition;
  LSelectionBeginPosition, LSelectionEndPosition: TTextEditorTextPosition;
begin
  FSelection.ActiveMode := Selection.Mode;
  LValue := AValue;

  if FSelection.Visible then
  begin
    if LValue.Line < 0 then
      LValue.Line := 0;

    if (FLines.Count > 0) and (LValue.Line > FLines.Count - 1) then
    begin
      LValue.Line := FLines.Count - 1;
      LValue.Char := FLines.StringLength(LValue.Line) + 1;
    end;

    if FSelection.Mode = smNormal then
      LValue.Char := EnsureRange(LValue.Char, 1, FLines.StringLength(LValue.Line) + 1)
    else
      LValue.Char := Max(LValue.Char, 1);

    if not IsSamePosition(LValue, FPosition.EndSelection) then
    begin
      FPosition.EndSelection := LValue;

      Invalidate;
    end;

    if Assigned(FEvents.OnSelectionChanged) then
      FEvents.OnSelectionChanged(Self);

    if FState.ExecutingSelectionCommand and (soAutoCopyToClipboard in FSelection.Options) then
    begin
      LSelectionBeginPosition := FPosition.BeginSelection;
      LSelectionEndPosition := FPosition.EndSelection;
      CopyToClipboard;
      FPosition.BeginSelection := LSelectionBeginPosition;
      FPosition.EndSelection := LSelectionEndPosition;
    end;
  end;
end;

procedure TCustomTextEditor.SetSelectionLength(const AValue: Integer);
begin
  SelectionEndPosition := CharIndexToTextPosition(AValue, SelectionBeginPosition, False);
end;

procedure TCustomTextEditor.SetSelectionStart(const AValue: Integer);
begin
  SelectionBeginPosition := CharIndexToTextPosition(AValue);
end;

procedure TCustomTextEditor.SetSpecialChars(const AValue: TTextEditorSpecialChars);
begin
  FSpecialChars.Assign(AValue);
end;

procedure TCustomTextEditor.SetSyncEdit(const AValue: TTextEditorSyncEdit);
begin
  FSyncEdit.Assign(AValue);
end;

procedure TCustomTextEditor.SetTabs(const AValue: TTextEditorTabs);
begin
  FTabs.Assign(AValue);
end;

procedure TCustomTextEditor.SetText(const AValue: string);
begin
  FLines.Text := AValue;
  TopLine := 1;
  MoveCaretToBeginning;
  FPosition.EndSelection := FPosition.BeginSelection;
  ClearUndo;
end;

procedure TCustomTextEditor.SetTextBetween(const ATextBeginPosition: TTextEditorTextPosition;
  const ATextEndPosition: TTextEditorTextPosition; const AValue: string);
var
  LSelectionMode: TTextEditorSelectionMode;
begin
  LSelectionMode := FSelection.Mode;
  FSelection.Mode := smNormal;
  FUndoList.BeginBlock;
  FUndoList.AddChange(crCaret, TextPosition, FPosition.BeginSelection, FPosition.BeginSelection, '',
    FSelection.ActiveMode);
  FPosition.BeginSelection := ATextBeginPosition;
  FPosition.EndSelection := ATextEndPosition;
  SelectedText := AValue;
  FUndoList.EndBlock;
  FSelection.Mode := LSelectionMode;
end;

procedure TCustomTextEditor.SetTopLine(const AValue: Integer);
var
  LViewLineCount: Integer;
  LValue: Integer;
  LInSelection: Boolean;
begin
  LViewLineCount := Max(FLineNumbers.Count, 1);
  LValue := AValue;

  LInSelection := sfInSelection in FState.Flags;

  if (soPastEndOfFileMarker in FScroll.Options) and
    (not LInSelection or LInSelection and (LValue = FLineNumbers.TopLine)) then
    LValue := Min(LValue, LViewLineCount)
  else
    LValue := Min(LValue, LViewLineCount - VisibleLineCount + 1);

  LValue := Max(LValue, 1);
  if FLineNumbers.TopLine <> LValue then
  begin
    FLineNumbers.TopLine := LValue;
    if FMinimap.Visible and not FMinimap.Dragging then
      FMinimap.TopLine := Max(FLineNumbers.TopLine - Abs(Trunc((FMinimap.VisibleLineCount - VisibleLineCount) *
        (FLineNumbers.TopLine / Max(LViewLineCount - VisibleLineCount, 1)))), 1);
    UpdateScrollBars;
  end;
end;

procedure TCustomTextEditor.SetUndo(const AValue: TTextEditorUndo);
begin
  FUndo.Assign(AValue);
end;

procedure TCustomTextEditor.SetUnknownChars(const AValue: TTextEditorUnknownChars);
begin
  FUnknownChars.Assign(AValue);
end;

procedure TCustomTextEditor.SetWordBlock(const ATextPosition: TTextEditorTextPosition);
var
  LTextPosition: TTextEditorTextPosition;
  LBlockBeginPosition: TTextEditorTextPosition;
  LBlockEndPosition: TTextEditorTextPosition;
  LTempString: string;
  LLength: Integer;

  procedure CharScan;
  var
    LIndex: Integer;
  begin
    LBlockEndPosition.Char := LLength;
    for LIndex := LTextPosition.Char to LLength do
    if IsWordBreakChar(LTempString[LIndex]) then
    begin
      LBlockEndPosition.Char := LIndex;
      Break;
    end;

    LBlockBeginPosition.Char := 1;
    for LIndex := LTextPosition.Char - 1 downto 1 do
    if IsWordBreakChar(LTempString[LIndex]) then
    begin
      LBlockBeginPosition.Char := LIndex + 1;
      Break;
    end;

    if soExpandRealNumbers in FSelection.Options then
      if LTempString[LBlockBeginPosition.Char] in TCharacterSets.Numbers then
      begin
        LIndex := LTextPosition.Char;
        while (LIndex > 0) and (LTempString[LIndex] in TCharacterSets.RealNumbers) do
          Dec(LIndex);
        LBlockBeginPosition.Char := LIndex + 1;
        LIndex := LTextPosition.Char;
        while (LIndex < LLength) and (LTempString[LIndex] in TCharacterSets.RealNumbers) do
          Inc(LIndex);
        LBlockEndPosition.Char := LIndex;
      end;

    if soExpandPrefix in FSelection.Options then
    begin
      LIndex := LBlockBeginPosition.Char - 1;
      while (LIndex > 0) and CharInString(LTempString[LIndex], FSelection.PrefixCharacters) do
        Dec(LIndex);
      LBlockBeginPosition.Char := LIndex + 1;
    end;
  end;

begin
  LTextPosition.Char := Max(ATextPosition.Char, 1);
  LTextPosition.Line := EnsureRange(ATextPosition.Line, 0, Max(FLines.Count - 1, 0));
  LTempString := FLines.Items^[LTextPosition.Line].TextLine + TControlCharacters.Null;
  LLength := Length(LTempString);

  if LTextPosition.Char > LLength then
  begin
    TextPosition := GetPosition(Length(LTempString), LTextPosition.Line);
    Exit;
  end;

  FState.ExecutingSelectionCommand := True;

  CharScan;

  LBlockBeginPosition.Line := LTextPosition.Line;
  LBlockEndPosition.Line := LTextPosition.Line;
  SetCaretAndSelection(LBlockEndPosition, LBlockBeginPosition, LBlockEndPosition);

  Invalidate;
end;

procedure TCustomTextEditor.SetWordWrap(const AValue: TTextEditorWordWrap);
begin
  FWordWrap.Assign(AValue);
end;

procedure TCustomTextEditor.SizeOrFontChanged(const AFontChanged: Boolean);
var
  LOldTextPosition: TTextEditorTextPosition;
  LScrollPageWidth, LVisibleLineCount: Integer;
  LWidthChanged: Boolean;
begin
  if not Assigned(FHighlighter) or Assigned(FHighlighter) and FHighlighter.Loading then
    Exit;

  if Visible and HandleAllocated and (FPaintHelper.CharWidth <> 0) and FState.CanChangeSize then
  begin
    FPaintHelper.SetBaseFont(Font);
    LScrollPageWidth := GetScrollPageWidth;

    LVisibleLineCount := ClientHeight div GetLineHeight;
    if FRuler.Visible then
      Dec(LVisibleLineCount);
    LWidthChanged := LScrollPageWidth <> FScrollHelper.PageWidth;

    GetMinimapLeftRight(FMinimapHelper.Left, FMinimapHelper.Right);

    FillChar(FItalic.OffsetCache, SizeOf(FItalic.OffsetCache), 0);

    if not FHighlighter.Changed then
      if not LWidthChanged and (LVisibleLineCount = VisibleLineCount) then
        Exit;

    FScrollHelper.PageWidth := LScrollPageWidth;
    FLineNumbers.VisibleCount := LVisibleLineCount;

    if FMinimap.Visible then
    begin
      FPaintHelper.SetBaseFont(FMinimap.Font);
      FMinimap.CharHeight := FPaintHelper.CharHeight - 1;
      FMinimap.VisibleLineCount := ClientHeight div FMinimap.CharHeight;
      FMinimap.TopLine := Max(FLineNumbers.TopLine - Abs(Trunc((FMinimap.VisibleLineCount - VisibleLineCount) *
        (FLineNumbers.TopLine / Max(FLineNumbers.Count - VisibleLineCount, 1)))), 1);
      FPaintHelper.SetBaseFont(Font);
    end;

    if FWordWrap.Active and LWidthChanged then
    begin
      LOldTextPosition := TextPosition;
      CreateLineNumbersCache(True);
      TextPosition := LOldTextPosition;
    end;

    if AFontChanged then
    begin
      if LeftMargin.LineNumbers.Visible then
        LeftMarginChanged(Self);
      ResetCaret;
      Exclude(FState.Flags, sfCaretChanged);
    end;

    if cfoAutoWidth in FCodeFolding.Options then
    begin
      FCodeFolding.Width := FPaintHelper.CharHeight;
      if Odd(FCodeFolding.Width) then
        FCodeFolding.Width := FCodeFolding.Width - 1;
    end;
    if cfoAutoPadding in FCodeFolding.Options then
      FCodeFolding.Padding := 2;

    DoLeftMarginAutoSize;

    UpdateScrollBars;
  end;
end;

procedure TCustomTextEditor.SpecialCharsChanged(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  Invalidate;
end;

procedure TCustomTextEditor.UnknownCharsChanged(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  FLines.UnknownCharsVisible := FUnknownChars.Visible;
end;

procedure TCustomTextEditor.SyncEditChanged(ASender: TObject); //FI:O804 Method parameter is declared but never used
var
  LIndex: Integer;
  LTextPosition: TTextEditorTextPosition;
  LIsWordSelected: Boolean;
  LSelectionAvailable: Boolean;
begin
  FSyncEdit.ClearSyncItems;
  if FSyncEdit.Visible then
  begin
    FWordWrap.Active := False;
    LSelectionAvailable := GetSelectionAvailable;
    LIsWordSelected := IsWordSelected;
    if LSelectionAvailable and LIsWordSelected then
    begin
      FUndoList.BeginBlock;
      FSyncEdit.InEditor := True;
      FSyncEdit.EditBeginPosition := SelectionBeginPosition;
      FSyncEdit.EditEndPosition := SelectionEndPosition;
      FSyncEdit.EditWidth := FSyncEdit.EditEndPosition.Char - FSyncEdit.EditBeginPosition.Char;
      FindWords(SelectedText, FSyncEdit.SyncItems, seCaseSensitive in FSyncEdit.Options, True);
      LIndex := 0;
      while LIndex < FSyncEdit.SyncItems.Count do
      begin
        LTextPosition := PTextEditorTextPosition(FSyncEdit.SyncItems.Items[LIndex])^;
        if IsSamePosition(LTextPosition, FSyncEdit.EditBeginPosition) or
          FSyncEdit.BlockSelected and not FSyncEdit.IsTextPositionInBlock(LTextPosition) then
        begin
          Dispose(PTextEditorTextPosition(FSyncEdit.SyncItems.Items[LIndex]));
          FSyncEdit.SyncItems.Delete(LIndex);
        end
        else
          Inc(LIndex);
      end;
    end
    else
    if LSelectionAvailable and not LIsWordSelected then
    begin
      FSyncEdit.BlockSelected := True;
      FSyncEdit.BlockBeginPosition := SelectionBeginPosition;
      FSyncEdit.BlockEndPosition := SelectionEndPosition;
      FSyncEdit.Abort;
      FPosition.BeginSelection := TextPosition;
      FPosition.EndSelection := FPosition.BeginSelection;
    end
    else
      FSyncEdit.Abort;
  end
  else
  begin
    FSyncEdit.BlockSelected := False;
    if FSyncEdit.InEditor then
    begin
      FSyncEdit.InEditor := False;
      FUndoList.EndBlock;
    end;
  end;

  Invalidate;
end;

procedure TCustomTextEditor.SwapInt(var ALeft: Integer; var ARight: Integer);
var
  LTemp: Integer;
begin
  LTemp := ARight;
  ARight := ALeft;
  ALeft := LTemp;
end;

procedure TCustomTextEditor.TabsChanged(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  FLines.TabWidth := FTabs.Width;
  FLines.Columns := toColumns in FTabs.Options;

  if FWordWrap.Active then
    FLineNumbers.ResetCache := True;

  Invalidate;
end;

procedure TCustomTextEditor.UndoRedoAdded(ASender: TObject);
var
  LUndoItem: TTextEditorUndoItem;
begin
  LUndoItem := nil;
  if ASender = FUndoList then
    LUndoItem := FUndoList.PeekItem;

  if UndoList.Changed then
    SetModified(True);

  if not FUndoList.InsideRedo and Assigned(LUndoItem) and not (LUndoItem.ChangeReason in [crCaret, crGroupBreak]) then
    FRedoList.Clear;
end;

procedure TCustomTextEditor.UpdateFoldingRanges(const ACurrentLine: Integer; const ALineCount: Integer);
var
  LIndex: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  for LIndex := 0 to FCodeFoldings.AllRanges.AllCount - 1 do
  begin
    LCodeFoldingRange := FCodeFoldings.AllRanges[LIndex];
    if not LCodeFoldingRange.ParentCollapsed then
    begin
      if LCodeFoldingRange.FromLine > ACurrentLine then
      begin
        LCodeFoldingRange.MoveBy(ALineCount);

        if LCodeFoldingRange.Collapsed then
          UpdateFoldingRanges(LCodeFoldingRange.SubCodeFoldingRanges, ALineCount);

        Continue;
      end
      else
      if LCodeFoldingRange.FromLine = ACurrentLine then
      begin
        LCodeFoldingRange.MoveBy(ALineCount);
        Continue;
      end;

      if not LCodeFoldingRange.Collapsed then
        if LCodeFoldingRange.ToLine >= ACurrentLine then
          LCodeFoldingRange.Widen(ALineCount)
    end;
  end;
end;

procedure TCustomTextEditor.UpdateFoldingRanges(const AFoldRanges: TTextEditorCodeFoldingRanges; const ALineCount: Integer);
var
  LIndex: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  if Assigned(AFoldRanges) then
  for LIndex := 0 to AFoldRanges.Count - 1 do
  begin
    LCodeFoldingRange := AFoldRanges[LIndex];
    UpdateFoldingRanges(LCodeFoldingRange.SubCodeFoldingRanges, ALineCount);
    LCodeFoldingRange.MoveBy(ALineCount);
  end;
end;

procedure TCustomTextEditor.UpdateScrollBars;
var
  LScrollInfo: TScrollInfo;
  LVerticalMaxScroll: Integer;
  LHorizontalScrollMax: Integer;
  LShowScrollBar: Boolean;
begin
  if FLines.Streaming or FHighlighter.Loading then
    Exit;

  if not HandleAllocated or (PaintLock <> 0) then
    Exit;

  if (FScroll.Bars <> ssNone) and (FLines.Count > 0) then
  begin
    LScrollInfo.cbSize := SizeOf(ScrollInfo);
    LScrollInfo.fMask := SIF_ALL;
    LScrollInfo.fMask := LScrollInfo.fMask or SIF_DISABLENOSCROLL;

    if (FScroll.Bars in [ssBoth, ssHorizontal]) and not FWordWrap.Active then
    begin
      LHorizontalScrollMax := Max(GetHorizontalScrollMax - 1, 0);

      LScrollInfo.nMin := 0;
      if LHorizontalScrollMax <= TMaxValues.ScrollRange then
      begin
        LScrollInfo.nMax := LHorizontalScrollMax;
        LScrollInfo.nPage := FScrollHelper.PageWidth;
        LScrollInfo.nPos := FScrollHelper.HorizontalPosition;
      end
      else
      begin
        LScrollInfo.nMax := TMaxValues.ScrollRange;
        LScrollInfo.nPage := MulDiv(TMaxValues.ScrollRange, FScrollHelper.PageWidth, LHorizontalScrollMax);
        LScrollInfo.nPos := MulDiv(TMaxValues.ScrollRange, FScrollHelper.HorizontalPosition, LHorizontalScrollMax);
      end;

      LShowScrollBar := LHorizontalScrollMax > FScrollHelper.PageWidth;
      if not LShowScrollBar then
        FScrollHelper.HorizontalPosition := 0;

      if not FMinimap.Dragging then
        ShowScrollBar(Handle, SB_HORZ, LShowScrollBar);

      SetScrollInfo(Handle, SB_HORZ, LScrollInfo, True);

      if not FMinimap.Dragging then
        EnableScrollBar(Handle, SB_HORZ, ESB_ENABLE_BOTH);
    end
    else
    begin
      FScrollHelper.HorizontalPosition := 0;
      ShowScrollBar(Handle, SB_HORZ, False);
    end;

    if FScroll.Bars in [ssBoth, ssVertical] then
    begin
      LVerticalMaxScroll := FLineNumbers.Count;

      if soPastEndOfFileMarker in FScroll.Options then
        Inc(LVerticalMaxScroll, VisibleLineCount - 1);

      LScrollInfo.nMin := 0;
      if LVerticalMaxScroll <= TMaxValues.ScrollRange then
      begin
        LScrollInfo.nMax := Max(0, LVerticalMaxScroll) - 1;
        LScrollInfo.nPage := VisibleLineCount;
        LScrollInfo.nPos := TopLine - 1;
      end
      else
      begin
        LScrollInfo.nMax := TMaxValues.ScrollRange;
        LScrollInfo.nPage := MulDiv(TMaxValues.ScrollRange, VisibleLineCount, LVerticalMaxScroll);
        LScrollInfo.nPos := MulDiv(TMaxValues.ScrollRange, TopLine, LVerticalMaxScroll);
      end;

      LShowScrollBar := LScrollInfo.nMax > VisibleLineCount;
      if not LShowScrollBar then
        TopLine := 1;

      if not FMinimap.Dragging then
        ShowScrollBar(Handle, SB_VERT, LShowScrollBar);

      SetScrollInfo(Handle, SB_VERT, LScrollInfo, True);

      if not FMinimap.Dragging then
        EnableScrollBar(Handle, SB_VERT, ESB_ENABLE_BOTH);
    end
    else
      ShowScrollBar(Handle, SB_VERT, False);
  end
  else
    ShowScrollBar(Handle, SB_BOTH, False);
end;

procedure TCustomTextEditor.UpdateWordWrap(const AValue: Boolean);
var
  LOldTopLine: Integer;
  LShowCaret: Boolean;
begin
  if FWordWrap.Active <> AValue then
  begin
    LShowCaret := CaretInView;

    LOldTopLine := TopLine;
    if AValue then
    begin
      SetHorizontalScrollPosition(0);
      if FWordWrap.Width = wwwRightMargin then
        FRightMargin.Visible := True;
    end;
    TopLine := LOldTopLine;

    if soPastEndOfLine in FScroll.Options then
    begin
      SetSelectionBeginPosition(SelectionBeginPosition);
      SetSelectionEndPosition(SelectionEndPosition);
    end;

    if LShowCaret then
      EnsureCursorPositionVisible;
  end;
end;

procedure TCustomTextEditor.WMCaptureChanged(var AMessage: TMessage);
begin
  FScrollHelper.Timer.Enabled := False;

  inherited;
end;

procedure TCustomTextEditor.WMChar(var AMessage: TWMChar);
begin
  DoKeyPressW(AMessage);
end;

procedure TCustomTextEditor.WMClear(var AMessage: TMessage);
begin
  if not ReadOnly then
    SelectedText := '';
end;

procedure TCustomTextEditor.WMCopy(var AMessage: TMessage);
begin
  CopyToClipboard;

  AMessage.Result := Ord(True);
end;

procedure TCustomTextEditor.WMCut(var AMessage: TMessage);
begin
  if not ReadOnly then
    CutToClipboard;

  AMessage.Result := Ord(True);
end;

procedure TCustomTextEditor.WMDropFiles(var AMessage: TMessage);
var
  LIndex, LNumberDropped: Integer;
  LFilename: array [0 .. MAX_PATH - 1] of Char;
  LPoint: TPoint;
  LFilesList: TStringList;
begin
  try
    if Assigned(FEvents.OnDropFiles) then
    begin
      LFilesList := TStringList.Create;
      try
        LNumberDropped := DragQueryFile(THandle(AMessage.wParam), Cardinal(-1), nil, 0);
        DragQueryPoint(THandle(AMessage.wParam), LPoint);
        for LIndex := 0 to LNumberDropped - 1 do
        begin
          DragQueryFileW(THandle(AMessage.wParam), LIndex, LFilename, SizeOf(LFilename) div 2);
          LFilesList.Add(LFilename)
        end;
        FEvents.OnDropFiles(Self, LPoint, LFilesList);
      finally
        LFilesList.Free;
      end;
    end;
  finally
    AMessage.Result := 0;
    DragFinish(THandle(AMessage.wParam));
  end;
end;

procedure TCustomTextEditor.WMEraseBkgnd(var AMessage: TWMEraseBkgnd);
begin
  AMessage.Result := 1;
end;

procedure TCustomTextEditor.WMGetDlgCode(var AMessage: TWMGetDlgCode);
begin
  inherited;

  AMessage.Result := AMessage.Result or DLGC_WANTARROWS or DLGC_WANTCHARS;

  if FTabs.WantTabs then
    AMessage.Result := AMessage.Result or DLGC_WANTTAB;

  if FState.WantReturns then
    AMessage.Result := AMessage.Result or DLGC_WANTALLKEYS;
end;

procedure TCustomTextEditor.WMGetText(var AMessage: TWMGetText);
begin
  StrLCopy(PChar(AMessage.Text), PChar(Text), AMessage.TextMax - 1);
  AMessage.Result := StrLen(PChar(AMessage.Text));
end;

procedure TCustomTextEditor.WMGetTextLength(var AMessage: TWMGetTextLength);
begin
  if (csDocking in ControlState) or (csDestroying in ComponentState) then
    AMessage.Result := 0
  else
    AMessage.Result := FLines.GetTextLength;
end;

procedure TCustomTextEditor.WMHScroll(var AMessage: TWMScroll);
var
  LHorizontalScrollMax: Integer;
begin
  AMessage.Result := 0;

  FreeCompletionProposalPopupWindow;

  inherited;

  case AMessage.ScrollCode of
    SB_LEFT:
      SetHorizontalScrollPosition(0);
    SB_RIGHT:
      SetHorizontalScrollPosition(FLines.GetLengthOfLongestLine);
    SB_LINERIGHT:
      SetHorizontalScrollPosition(FScrollHelper.HorizontalPosition + FPaintHelper.CharWidth);
    SB_LINELEFT:
      SetHorizontalScrollPosition(FScrollHelper.HorizontalPosition - FPaintHelper.CharWidth);
    SB_PAGERIGHT:
      SetHorizontalScrollPosition(FScrollHelper.HorizontalPosition + GetVisibleChars(FViewPosition.Row));
    SB_PAGELEFT:
      SetHorizontalScrollPosition(FScrollHelper.HorizontalPosition - GetVisibleChars(FViewPosition.Row));
    SB_THUMBPOSITION, SB_THUMBTRACK:
      try
        FScrollHelper.IsScrolling := True;
        LHorizontalScrollMax := GetHorizontalScrollMax;
        if LHorizontalScrollMax > TMaxValues.ScrollRange then
          SetHorizontalScrollPosition(MulDiv(LHorizontalScrollMax, AMessage.Pos, TMaxValues.ScrollRange))
        else
          SetHorizontalScrollPosition(AMessage.Pos);
      finally
        Repaint;
      end;
    SB_ENDSCROLL:
      FScrollHelper.IsScrolling := False;
  end;

  case AMessage.ScrollCode of
    SB_LEFT, SB_RIGHT, SB_LINERIGHT, SB_LINELEFT, SB_PAGERIGHT, SB_PAGELEFT:
      Invalidate;
  end;

  if Assigned(OnScroll) then
    OnScroll(Self, sbHorizontal);
end;

procedure TCustomTextEditor.WMIMEChar(var AMessage: TMessage);
begin //FI:W519 Method is empty
  { Do nothing here, the IME string is retrieved in WMIMEComposition.
    Handling the WM_IME_CHAR message stops Windows from sending WM_CHAR messages while using the IME. }
end;

procedure TCustomTextEditor.WMIMEComposition(var AMessage: TMessage);
var
  LImc: HIMC;
  LPBuffer: PChar;
  LImeCount: Integer;
begin
  if AMessage.LParam and GCS_RESULTSTR <> 0 then
  begin
    LImc := ImmGetContext(Handle);
    try
      LImeCount := ImmGetCompositionStringW(LImc, GCS_RESULTSTR, nil, 0);
      { ImeCount is always the size in bytes, also for Unicode }
      GetMem(LPBuffer, LImeCount + SizeOf(Char));
      try
        ImmGetCompositionStringW(LImc, GCS_RESULTSTR, LPBuffer, LImeCount);
        LPBuffer[LImeCount div SizeOf(Char)] := TControlCharacters.Null;
        CommandProcessor(TKeyCommands.ImeStr, TControlCharacters.Null, LPBuffer);
      finally
        FreeMem(LPBuffer);
      end;
    finally
      ImmReleaseContext(Handle, LImc);
    end;
  end;
  inherited;
end;

procedure TCustomTextEditor.WMIMENotify(var AMessage: TMessage);
var
  LIMCHandle: HIMC;
  LLogFontW: TLogFontW;
begin
  with AMessage do
  if wParam = IMN_SETOPENSTATUS then
  begin
    LIMCHandle := ImmGetContext(Handle);
    if LIMCHandle <> 0 then
    begin
      GetObjectW(Font.Handle, SizeOf(TLogFontW), @LLogFontW);
      ImmSetCompositionFontW(LIMCHandle, @LLogFontW);
      ImmReleaseContext(Handle, LIMCHandle);
    end;
  end;

  inherited;
end;

procedure TCustomTextEditor.WMKillFocus(var AMessage: TWMKillFocus);
begin
  inherited;

  FreeCompletionProposalPopupWindow;

  if FMultiCaret.Position.Row <> -1 then
  begin
    FMultiCaret.Position.Row := -1;

    Invalidate;
  end;

  if Focused or FCaretHelper.ShowAlways then
    Exit;

  HideCaret;
  Winapi.Windows.DestroyCaret;

  Invalidate;
end;

procedure TCustomTextEditor.WMPaint(var AMessage: TWMPaint);
var
  LDC, LCompatibleDC: HDC;
  LCompatibleBitmap, LOldBitmap: HBITMAP;
  LPaintStruct: TPaintStruct;
  LBeginPaint: Boolean;
begin
  if (FPaintLock <> 0) or FHighlighter.Loading then
    Exit;

  LBeginPaint := False;

  LDC := AMessage.DC;
  if LDC = 0 then
  begin
    LDC := BeginPaint(Handle, LPaintStruct);
    LBeginPaint := True;
  end;

  LCompatibleDC := CreateCompatibleDC(Canvas.Handle);
  LCompatibleBitmap := CreateCompatibleBitmap(Canvas.Handle, Width, Height);
  LOldBitmap := SelectObject(LCompatibleDC, LCompatibleBitmap);
  try
    AMessage.DC := LCompatibleDC;

    inherited;

    BitBlt(LDC, 0, 0, ClientWidth, ClientHeight, LCompatibleDC, 0, 0, SRCCOPY);
  finally
    SelectObject(LCompatibleDC, LOldBitmap);
    DeleteObject(LCompatibleBitmap);
    DeleteDC(LCompatibleDC);

    if LBeginPaint then
      EndPaint(Handle, LPaintStruct);
  end;
end;

procedure TCustomTextEditor.WMPaste(var AMessage: TMessage);
begin
  if not ReadOnly then
    PasteFromClipboard;

  AMessage.Result := Ord(True);
end;

procedure TCustomTextEditor.WMSetCursor(var AMessage: TWMSetCursor);
begin
  if (AMessage.HitTest = HTCLIENT) and (AMessage.CursorWnd = Handle) and not (csDesigning in ComponentState) then
    UpdateMouseCursor
  else
    inherited;
end;

procedure TCustomTextEditor.WMSetFocus(var AMessage: TWMSetFocus);
begin
  ResetCaret;

  if not Selection.Visible and GetSelectionAvailable then
    Invalidate;
end;

procedure TCustomTextEditor.WMSetText(var AMessage: TWMSetText);
begin
  AMessage.Result := 1;
  try
    if HandleAllocated and IsWindowUnicode(Handle) then
      Text := PChar(AMessage.Text)
    else
      Text := string(PAnsiChar(AMessage.Text));
  except
    AMessage.Result := 0;
    raise
  end
end;

procedure TCustomTextEditor.WMSize(var AMessage: TWMSize);
begin
  inherited;

  SizeOrFontChanged(False);
end;

procedure TCustomTextEditor.WMUndo(var AMessage: TMessage);
begin
  DoUndo;
end;

procedure TCustomTextEditor.WMVScroll(var AMessage: TWMScroll);
var
  LScrollHint: string;
  LScrollHintRect: TRect;
  LScrollHintPoint: TPoint;
  LScrollHintWindow: THintWindow;
  LScrollButtonHeight: Integer;
  LScrollInfo: TScrollInfo;
  LVerticalMaxScroll: Integer;
begin
  AMessage.Result := 0;

  FreeCompletionProposalPopupWindow;

  case AMessage.ScrollCode of
    SB_TOP:
      TopLine := 1;
    SB_BOTTOM:
      TopLine := FLineNumbers.Count;
    SB_LINEDOWN:
      TopLine := TopLine + 1;
    SB_LINEUP:
      TopLine := TopLine - 1;
    SB_PAGEDOWN:
      TopLine := TopLine + VisibleLineCount;
    SB_PAGEUP:
      TopLine := TopLine - VisibleLineCount;
    SB_THUMBPOSITION, SB_THUMBTRACK:
      begin
        try
          FScrollHelper.IsScrolling := True;

          LVerticalMaxScroll := FLineNumbers.Count;

          if soPastEndOfFileMarker in FScroll.Options then
            Inc(LVerticalMaxScroll, VisibleLineCount - 1);

          if LVerticalMaxScroll <= TMaxValues.ScrollRange then
            TopLine := AMessage.Pos
          else
            TopLine := MulDiv(LVerticalMaxScroll, Min(Abs(AMessage.Pos), TMaxValues.ScrollRange), TMaxValues.ScrollRange);

          if soShowVerticalScrollHint in FScroll.Options then
          begin
            LScrollHintWindow := GetHintWindow;
            if FScroll.Hint.Format = shfTopLineOnly then
              LScrollHint := Format(STextEditorScrollInfoTopLine, [TopLine])
            else
              LScrollHint := Format(STextEditorScrollInfo,
                [TopLine, TopLine + Min(VisibleLineCount, FLineNumbers.Count - TopLine)]);

            LScrollHintRect := LScrollHintWindow.CalcHintRect(200, LScrollHint, nil);

            if soHintFollows in FScroll.Options then
            begin
              LScrollButtonHeight := FSystemMetrics.VerticalScroll;

              FillChar(LScrollInfo, SizeOf(LScrollInfo), 0);
              LScrollInfo.cbSize := SizeOf(LScrollInfo);
              LScrollInfo.fMask := SIF_ALL;
              GetScrollInfo(Handle, SB_VERT, LScrollInfo);

              LScrollHintPoint := ClientToScreen(Point(ClientRect.Right - LScrollHintRect.Right - 4,
                ((LScrollHintRect.Bottom - LScrollHintRect.Top) shr 1) +
                Round((LScrollInfo.nTrackPos / LScrollInfo.nMax) * (ClientHeight - LScrollButtonHeight * 2)) - 2));
            end
            else
              LScrollHintPoint := ClientToScreen(Point(ClientRect.Right - LScrollHintRect.Right - 4, 4));

            OffsetRect(LScrollHintRect, LScrollHintPoint.X, LScrollHintPoint.Y);
            LScrollHintWindow.ActivateHint(LScrollHintRect, LScrollHint);
            LScrollHintWindow.Update;
          end;
        finally
          Repaint;
        end;
      end;
    SB_ENDSCROLL:
      begin
        FScrollHelper.IsScrolling := False;
        if soShowVerticalScrollHint in FScroll.Options then
          ShowWindow(GetHintWindow.Handle, SW_HIDE);
      end;
  end;

  case AMessage.ScrollCode of
    SB_TOP, SB_BOTTOM, SB_LINEDOWN, SB_LINEUP, SB_PAGEDOWN, SB_PAGEUP:
      Invalidate;
  end;

  if Assigned(OnScroll) then
    OnScroll(Self, sbVertical);
end;

procedure TCustomTextEditor.SetCompletionProposalPopupWindowLocation;
var
  LPoint: TPoint;
begin
  if Assigned(FCompletionProposalPopupWindow) then
  begin
    LPoint := ClientToScreen(ViewPositionToPixels(FPosition.CompletionProposal));
    Inc(LPoint.Y, GetLineHeight);
    FCompletionProposalPopupWindow.Left := LPoint.X;
    FCompletionProposalPopupWindow.Top := LPoint.Y;
  end;
end;

procedure TCustomTextEditor.WordWrapChanged(ASender: TObject); //FI:O804 Method parameter is declared but never used
var
  LOldTextPosition: TTextEditorTextPosition;
begin
  if not Visible or not Assigned(Parent) then
    Exit;

  FScrollHelper.PageWidth := GetScrollPageWidth;
  LOldTextPosition := TextPosition;
  CreateLineNumbersCache(True);
  TextPosition := LOldTextPosition;

  if not (csLoading in ComponentState) then
    Invalidate;
end;

{ Protected declarations }

function TCustomTextEditor.DoMouseWheel(AShift: TShiftState; AWheelDelta: Integer; AMousePos: TPoint): Boolean;
var
  LWheelClicks: Integer;
  LLinesToScroll: Integer;
begin
  if Assigned(FCompletionProposalPopupWindow) then
  begin
    FCompletionProposalPopupWindow.MouseWheel(AShift, AWheelDelta);
    Exit(False);
  end;

  Result := inherited DoMouseWheel(AShift, AWheelDelta, AMousePos);
  if Result then
    Exit;

  if ssCtrl in aShift then
    LLinesToScroll := VisibleLineCount shr Ord(soHalfPage in FScroll.Options)
  else
    LLinesToScroll := 3;
  Inc(FMouse.WheelAccumulator, AWheelDelta);
  LWheelClicks := FMouse.WheelAccumulator div TMouseWheel.Divisor;
  FMouse.WheelAccumulator := FMouse.WheelAccumulator mod TMouseWheel.Divisor;
  TopLine := TopLine - LWheelClicks * LLinesToScroll;

  if Assigned(OnScroll) then
    OnScroll(Self, sbVertical);

  Invalidate;

  Result := True;
end;

function TCustomTextEditor.DoOnReplaceText(const ASearch, AReplace: string; const ALine, AColumn: Integer; const ADeleteLine: Boolean): TTextEditorReplaceAction;
begin
  Result := raCancel;
  if Assigned(FEvents.OnReplaceText) then
    FEvents.OnReplaceText(Self, ASearch, AReplace, ALine, AColumn, ADeleteLine, Result);
end;

function TCustomTextEditor.DoSearchMatchNotFoundWraparoundDialog: Boolean;
begin
  Result := MessageDialog(Format(STextEditorSearchMatchNotFound, [sLineBreak + sLineBreak]), mtConfirmation, //FI:W510 Values on both sides of the operator are equal (bug)
    [mbYes, mbNo], mbYes) = mrYes;
end;

function TCustomTextEditor.GetReadOnly: Boolean;
begin
  Result := FState.ReadOnly;
end;

function TCustomTextEditor.GetSelectionLength: Integer;
begin
  if GetSelectionAvailable then
    Result := TextPositionToCharIndex(SelectionEndPosition) - TextPositionToCharIndex(SelectionBeginPosition)
  else
    Result := 0;
end;

function TCustomTextEditor.GetSelectionLineCount: Integer;
begin
  if GetSelectionAvailable then
    Result := SelectionEndPosition.Line - SelectionBeginPosition.Line + 1
  else
    Result := 0;
end;

function TCustomTextEditor.TranslateKeyCode(const ACode: Word; const AShift: TShiftState): TTextEditorCommand;
var
  LIndex: Integer;
begin
  LIndex := KeyCommands.FindKeycodes(FLast.Key, FLast.ShiftState, ACode, AShift);
  if LIndex >= 0 then
    Result := KeyCommands[LIndex].Command
  else
  begin
    LIndex := KeyCommands.FindKeycode(ACode, AShift);
    if LIndex >= 0 then
      Result := KeyCommands[LIndex].Command
    else
      Result := TKeyCommands.None;
  end;

  if (Result = TKeyCommands.None) and (ACode >= vkAccept) and (ACode <= vkScroll) then
  begin
    FLast.Key := ACode;
    FLast.ShiftState := AShift;
  end
  else
  begin
    FLast.Key := 0;
    FLast.ShiftState := [];
  end;
end;

procedure TCustomTextEditor.ChainLinesChanged(ASender: TObject);
begin
  if Assigned(FEvents.OnChainLinesChanged) then
    FEvents.OnChainLinesChanged(ASender);
  FOriginal.Lines.OnChange(ASender);
end;

procedure TCustomTextEditor.ChainLinesChanging(ASender: TObject);
begin
  if Assigned(FEvents.OnChainLinesChanging) then
    FEvents.OnChainLinesChanging(ASender);
  FOriginal.Lines.OnChanging(ASender);
end;

procedure TCustomTextEditor.ChainLinesCleared(ASender: TObject);
begin
  if Assigned(FEvents.OnChainLinesCleared) then
    FEvents.OnChainLinesCleared(ASender);
  FOriginal.Lines.OnCleared(ASender);
end;

procedure TCustomTextEditor.ChainLinesDeleted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
begin
  if Assigned(FEvents.OnChainLinesDeleted) then
    FEvents.OnChainLinesDeleted(ASender, AIndex, ACount);
  FOriginal.Lines.OnDeleted(ASender, AIndex, ACount);
end;

procedure TCustomTextEditor.ChainLinesInserted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
begin
  if Assigned(FEvents.OnChainLinesInserted) then
    FEvents.OnChainLinesInserted(ASender, AIndex, ACount);
  FOriginal.Lines.OnInserted(ASender, AIndex, ACount);
end;

procedure TCustomTextEditor.ChainLinesPutted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
begin
  if Assigned(FEvents.OnChainLinesPutted) then
    FEvents.OnChainLinesPutted(ASender, AIndex, ACount);
  FOriginal.Lines.OnPutted(ASender, AIndex, ACount);
end;

procedure TCustomTextEditor.ChainUndoRedoAdded(ASender: TObject);
var
  LUndoList: TTextEditorUndoList;
  LNotifyEvent: TNotifyEvent;
begin
  if ASender = FUndoList then
  begin
    LUndoList := FOriginal.UndoList;
    LNotifyEvent := FEvents.OnChainUndoAdded;
  end
  else
  begin
    LUndoList := FOriginal.RedoList;
    LNotifyEvent := FEvents.OnChainRedoAdded;
  end;

  if Assigned(LNotifyEvent) then
    LNotifyEvent(ASender);

  LUndoList.OnAddedUndo(ASender);
end;

procedure TCustomTextEditor.ChangeObjectScale(const AMultiplier, ADivider: Integer);
begin
  if Assigned(FLeftMargin) then
    FLeftMargin.ChangeScale(AMultiplier, ADivider);

  if Assigned(FActiveLine) then
    FActiveLine.Indicator.ChangeScale(AMultiplier, ADivider);

  if Assigned(FScroll) then
    FScroll.Indicator.ChangeScale(AMultiplier, ADivider);

  if Assigned(FSyncEdit) then
    FSyncEdit.Activator.ChangeScale(AMultiplier, ADivider);

  if Assigned(FWordWrap) then
    FWordWrap.Indicator.ChangeScale(AMultiplier, ADivider);

  if Assigned(FRuler) then
    FRuler.ChangeScale(AMultiplier, ADivider);

  if Assigned(FCodeFolding) then
    FCodeFolding.ChangeScale(AMultiplier, ADivider);

  if Assigned(FCompletionProposal) then
    FCompletionProposal.ChangeScale(AMultiplier, ADivider);

  if Assigned(FMinimap) then
    FMinimap.ChangeScale(AMultiplier, ADivider);

  if Assigned(FSearch.Map) then
    FSearch.Map.ChangeScale(AMultiplier, ADivider);
end;

procedure TCustomTextEditor.ChangeScale(AMultiplier, ADivider: Integer; AIsDpiChange: Boolean);
begin
  if csDesigning in ComponentState then
    Exit;

{$IF DEFINED(ALPHASKINS)}
  if SkinData.SkinManager.Options.ScaleMode = smCustomPPI then
  begin
{$ENDIF}
    if AIsDpiChange or (AMultiplier <> ADivider) then
      ChangeObjectScale(AMultiplier, ADivider);

    inherited ChangeScale(AMultiplier, ADivider, AIsDpiChange);
{$IF DEFINED(ALPHASKINS)}
  end;
{$ENDIF}
end;

procedure TCustomTextEditor.CreateParams(var AParams: TCreateParams);
begin
  StrDispose(WindowText);
  WindowText := nil;

  inherited CreateParams(AParams);

  with AParams do
  begin
    WindowClass.Style := WindowClass.Style and not (CS_VREDRAW or CS_HREDRAW);

    if (FBorderStyle = bsNone) or (FBorderStyle = bsSingle) and Ctl3D then
      Style := Style and not WS_BORDER
    else
      Style := Style or WS_BORDER;

    if (FBorderStyle = bsSingle) and Ctl3D then
      ExStyle := ExStyle or WS_EX_CLIENTEDGE;
  end;
end;

procedure TCustomTextEditor.CreateWnd;
begin
  inherited;

  if (eoDropFiles in FOptions) and not (csDesigning in ComponentState) then
    DragAcceptFiles(Handle, True);
end;

procedure TCustomTextEditor.DblClick;
var
  LCursorPoint: TPoint;
  LTextLinesLeft, LTextLinesRight: Integer;
begin
  Winapi.Windows.GetCursorPos(LCursorPoint);
  LCursorPoint := ScreenToClient(LCursorPoint);

  LTextLinesLeft := FLeftMargin.GetWidth + FCodeFolding.GetWidth;
  LTextLinesRight := Width;

  if FMinimap.Align = maLeft then
    Inc(LTextLinesLeft, FMinimap.GetWidth)
  else
    Dec(LTextLinesRight, FMinimap.GetWidth);

  if FSearch.Map.Align = saLeft then
    Inc(LTextLinesLeft, FSearch.Map.GetWidth)
  else
    Dec(LTextLinesRight, FSearch.Map.GetWidth);

  if (LCursorPoint.X >= LTextLinesLeft) and (LCursorPoint.X < LTextLinesRight) then
  begin
    if FSelection.Visible and FMouse.DownInText then
      SetWordBlock(TextPosition);

    inherited;

    Include(FState.Flags, sfDblClicked);
    MouseCapture := False;
  end
  else
    inherited;
end;

procedure TCustomTextEditor.DecPaintLock;
begin
  Assert(FPaintLock > 0);
  Dec(FPaintLock);

  if FPaintLock = 0 then
  begin
    UpdateScrollBars;

    Invalidate;
  end;
end;

procedure TCustomTextEditor.DestroyWnd;
begin
  if (eoDropFiles in FOptions) and not (csDesigning in ComponentState) then
    DragAcceptFiles(Handle, False);

  inherited;
end;

procedure TCustomTextEditor.DoBlockIndent;
var
  LOldCaretPosition: TTextEditorTextPosition;
  LBlockBeginPosition, LBlockEndPosition: TTextEditorTextPosition;
  LStringToInsert: string;
  LEndOfLine, LCaretPositionX, LIndex: Integer;
  LSpaces: string;
  LOldSelectionMode: TTextEditorSelectionMode;
  LInsertionPosition: TTextEditorTextPosition;
begin
  LOldSelectionMode := FSelection.ActiveMode;
  LOldCaretPosition := TextPosition;

  LStringToInsert := '';
  if GetSelectionAvailable then
  try
    LBlockBeginPosition := SelectionBeginPosition;
    LBlockEndPosition := SelectionEndPosition;

    LEndOfLine := LBlockEndPosition.Line;
    if LBlockEndPosition.Char = 1 then
    begin
      LCaretPositionX := 1;
      Dec(LEndOfLine);
    end
    else
    if toTabsToSpaces in FTabs.Options then
      LCaretPositionX := LOldCaretPosition.Char + FTabs.Width
    else
      LCaretPositionX := LOldCaretPosition.Char + 1;

    if toTabsToSpaces in FTabs.Options then
      LSpaces := StringOfChar(TCharacters.Space, FTabs.Width)
    else
      LSpaces := TControlCharacters.Tab;

    for LIndex := LBlockBeginPosition.Line to LEndOfLine - 1 do //FI:W528 Variable not used in FOR-loop
      LStringToInsert := LStringToInsert + LSpaces + FLines.DefaultLineBreak;
    LStringToInsert := LStringToInsert + LSpaces;

    FUndoList.BeginBlock(1);
    try
      FUndoList.AddChange(crSelection, LOldCaretPosition, LBlockBeginPosition, LBlockEndPosition, '',
        LOldSelectionMode);

      LInsertionPosition.Line := LBlockBeginPosition.Line;
      if FSelection.ActiveMode = smColumn then
        LInsertionPosition.Char := LBlockBeginPosition.Char
      else
        LInsertionPosition.Char := 1;

      InsertBlock(LInsertionPosition, LInsertionPosition, PChar(LStringToInsert), True);
      FUndoList.AddChange(crIndent, LOldCaretPosition, LBlockBeginPosition, LBlockEndPosition, '', smColumn);
    finally
      FUndoList.EndBlock;
    end;

    LOldCaretPosition.Char := LCaretPositionX;
    if LCaretPositionX <> 1 then
      LBlockEndPosition := GetPosition(LBlockEndPosition.Char + Length(LSpaces), LBlockEndPosition.Line);
  finally
    SetCaretAndSelection(LOldCaretPosition, GetPosition(LBlockBeginPosition.Char + Length(LSpaces),
      LBlockBeginPosition.Line), LBlockEndPosition);
    FSelection.ActiveMode := LOldSelectionMode;
  end;
end;

procedure TCustomTextEditor.DoBlockUnindent;
var
  LOldCaretPosition: TTextEditorTextPosition;
  LBlockBeginPosition, LBlockEndPosition: TTextEditorTextPosition;
  LLine: PChar;
  LFullStringToDelete: string;
  LStringToDelete: TTextEditorArrayOfString;
  LIndex, LStringToDeleteIndex: Integer;
  LLength, LCaretPositionX, LDeleteIndex, LDeletionLength, LFirstIndent, LLastIndent, LLastLine: Integer;
  LLineText: string;
  LOldSelectionMode: TTextEditorSelectionMode;
  LSomethingToDelete: Boolean;

  function GetDeletionLength: Integer;
  var
    Run: PChar;
  begin
    Result := 0;
    Run := LLine;
    if Run[0] = TControlCharacters.Tab then
    begin
      Result := 1;
      LSomethingToDelete := True;
      Exit;
    end;

    while (Run[0] = TCharacters.Space) and (Result < FTabs.Width) do
    begin
      Inc(Result);
      Inc(Run);
      LSomethingToDelete := True;
    end;

    if (Run[0] = TControlCharacters.Tab) and (Result < FTabs.Width) then
      Inc(Result);
  end;

begin
  LOldSelectionMode := FSelection.ActiveMode;
  LLength := 0;
  LLastIndent := 0;
  if GetSelectionAvailable then
  begin
    LBlockBeginPosition := SelectionBeginPosition;
    LBlockEndPosition := SelectionEndPosition;

    LOldCaretPosition := TextPosition;
    LCaretPositionX := LOldCaretPosition.Char;

    if SelectionEndPosition.Char = 1 then
      LLastLine := LBlockEndPosition.Line - 1
    else
      LLastLine := LBlockEndPosition.Line;

    LSomethingToDelete := False;
    LStringToDeleteIndex := 0;
    SetLength(LStringToDelete, LLastLine - LBlockBeginPosition.Line + 1);
    for LIndex := LBlockBeginPosition.Line to LLastLine do
    begin
      LLine := PChar(FLines[LIndex]);

      if FSelection.ActiveMode = smColumn then
        Inc(LLine, MinIntValue([LBlockBeginPosition.Char - 1, LBlockEndPosition.Char - 1, Length(FLines[LIndex])]));

      LDeletionLength := GetDeletionLength;
      LStringToDelete[LStringToDeleteIndex] := Copy(LLine, 1, LDeletionLength);
      Inc(LStringToDeleteIndex);

      if (LOldCaretPosition.Line = LIndex) and (LCaretPositionX <> 1) then
        LCaretPositionX := LCaretPositionX - LDeletionLength;
    end;
    LFirstIndent := -1;
    LFullStringToDelete := '';
    if LSomethingToDelete then
    begin
      for LIndex := 0 to Length(LStringToDelete) - 2 do
        LFullStringToDelete := LFullStringToDelete + LStringToDelete[LIndex] + FLines.DefaultLineBreak;

      LFullStringToDelete := LFullStringToDelete + LStringToDelete[Length(LStringToDelete) - 1];
      SetTextCaretY(LBlockBeginPosition.Line);

      if FSelection.ActiveMode = smColumn then
        LDeleteIndex := Min(LBlockBeginPosition.Char, LBlockEndPosition.Char)
      else
        LDeleteIndex := 1;

      LStringToDeleteIndex := 0;
      for LIndex := LBlockBeginPosition.Line to LLastLine do
      begin
        LLength := Length(LStringToDelete[LStringToDeleteIndex]);
        Inc(LStringToDeleteIndex);
        if LFirstIndent = -1 then
          LFirstIndent := LLength;
        LLineText := FLines.Items^[LIndex].TextLine;
        Delete(LLineText, LDeleteIndex, LLength);
        FLines[LIndex] := LLineText;
      end;

      LLastIndent := LLength;
      FUndoList.BeginBlock(2);
      try
        FUndoList.AddChange(crSelection, LOldCaretPosition, LBlockBeginPosition, LBlockEndPosition, '',
          LOldSelectionMode);
        FUndoList.AddChange(crUnindent, LOldCaretPosition, LBlockBeginPosition, LBlockEndPosition, LFullStringToDelete,
          FSelection.ActiveMode);
      finally
        FUndoList.EndBlock;
      end;
    end;

    if LFirstIndent = -1 then
      LFirstIndent := 0;

    if FSelection.ActiveMode = smColumn then
      SetCaretAndSelection(LOldCaretPosition, LBlockBeginPosition, LBlockEndPosition)
    else
    begin
      LOldCaretPosition.Char := LCaretPositionX;
      Dec(LBlockBeginPosition.Char, LFirstIndent);
      Dec(LBlockEndPosition.Char, LLastIndent);
      SetCaretAndSelection(LOldCaretPosition, LBlockBeginPosition, LBlockEndPosition);
    end;

    FSelection.ActiveMode := LOldSelectionMode;
  end;
end;

procedure TCustomTextEditor.DoChange;
begin
  FUndoList.Changed := False;
  FRedoList.Changed := False;

  if Assigned(FEvents.OnChange) then
    FEvents.OnChange(Self);
end;

procedure TCustomTextEditor.DoCopyToClipboard(const AText: string);
begin
  if AText = '' then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    SetClipboardText(AText);
  finally
    Screen.Cursor := crDefault;
  end;
end;

function TCustomTextEditor.GetLastWordFromCursor: string;
var
  LTextPosition: TTextEditorTextPosition;
  LLineText: string;
begin
  Result := '';

  LTextPosition := TextPosition;
  LLineText := FLines[LTextPosition.Line];
  Dec(LTextPosition.Char);
  if LTextPosition.Char <= Length(LLineText) then
  begin
    while (LTextPosition.Char > 0) and IsWordBreakChar(LLineText[LTextPosition.Char]) do
      Dec(LTextPosition.Char);

    Result := WordAtTextPosition(LTextPosition);
  end;
end;

procedure TCustomTextEditor.DoExecuteCompletionProposal(const ATriggered: Boolean = False);
var
  LPoint: TPoint;
  LParams: TCompletionProposalParams;
begin
  LPoint := ClientToScreen(ViewPositionToPixels(ViewPosition));
  Inc(LPoint.Y, GetLineHeight);

  FreeCompletionProposalPopupWindow;

  FCompletionProposalPopupWindow := TTextEditorCompletionProposalPopupWindow.Create(Self);
  with FCompletionProposalPopupWindow do
  begin
    Assign(FCompletionProposal);
    Lines := FLines;

    LParams.Options.Triggered := ATriggered;
    LParams.Options.ParseItemsFromText := True;
    LParams.Options.AddHighlighterKeywords := True;
    LParams.Options.AddSnippets := FCompletionProposal.Snippets.Active;
    LParams.Options.ShowDescription := LParams.Options.AddSnippets and (FCompletionProposal.Snippets.Items.Count > 0);
    LParams.Options.SortByKeyword := True;
    LParams.Options.SortByDescription := False;
    LParams.Options.CodeInsight := False;

    Items.Clear;

    LParams.Items := Items;
    LParams.LastWord := GetLastWordFromCursor;
    LParams.PreviousCharAtCursor := PreviousCharAtCursor;

    if Assigned(FEvents.OnCompletionProposalExecute) then
      FEvents.OnCompletionProposalExecute(Self, LParams);

    ShowDescription := LParams.Options.ShowDescription;
    CodeInsight := LParams.Options.CodeInsight;

    if LParams.Options.ParseItemsFromText and (cpoParseItemsFromText in FCompletionProposal.Options) then
      SplitTextIntoWords(Items, ShowDescription);

    if LParams.Options.AddHighlighterKeywords and (cpoAddHighlighterKeywords in FCompletionProposal.Options) then
      AddHighlighterKeywords(Items, ShowDescription);

    if LParams.Options.AddSnippets then
      AddSnippets(Items, ShowDescription);

    FPosition.CompletionProposal := ViewPosition;

    if Items.Count > 0 then
      Execute(GetCurrentInput, LPoint, LParams.Options)
    else
      FreeCompletionProposalPopupWindow;
  end;
end;

procedure TCustomTextEditor.DoUndo;

  procedure RemoveGroupBreak;
  var
    LUndoItem: TTextEditorUndoItem;
  begin
    if FUndoList.LastChangeReason = crGroupBreak then
    begin
      LUndoItem := FUndoList.PopItem;
      LUndoItem.Free;
      FRedoList.AddGroupBreak;
    end;
  end;

var
  LUndoItem: TTextEditorUndoItem;
  LLastChangeBlockNumber: Integer;
  LLastChangeReason: TTextEditorChangeReason;
  LLastChangeString: string;
  LIsPasteAction: Boolean;
  LIsKeepGoing: Boolean;
  LChangeTrim: Boolean;
begin
  if ReadOnly then
    Exit;

  LChangeTrim := eoTrimTrailingSpaces in Options;
  if LChangeTrim then
    Exclude(FOptions, eoTrimTrailingSpaces);

  Screen.Cursor := crHourGlass;
  try
    FState.UndoRedo := True;

    RemoveGroupBreak;

    LLastChangeBlockNumber := FUndoList.LastChangeBlockNumber;
    LLastChangeReason := FUndoList.LastChangeReason;
    LLastChangeString := FUndoList.LastChangeString;
    LIsPasteAction := LLastChangeReason = crPaste;

    LUndoItem := FUndoList.PeekItem;
    if Assigned(LUndoItem) then
    repeat
      UndoItem;
      LUndoItem := FUndoList.PeekItem;
      LIsKeepGoing := False;
      if Assigned(LUndoItem) then
      begin
        if uoGroupUndo in FUndo.Options then
          LIsKeepGoing := LIsPasteAction and (FUndoList.LastChangeString = LLastChangeString) or
            (LLastChangeReason = LUndoItem.ChangeReason) and (LUndoItem.ChangeBlockNumber = LLastChangeBlockNumber) or
            (LUndoItem.ChangeBlockNumber <> 0) and (LUndoItem.ChangeBlockNumber = LLastChangeBlockNumber);

        LLastChangeReason := LUndoItem.ChangeReason;
        LIsPasteAction := LLastChangeReason = crPaste;
      end;
    until not LIsKeepGoing;

    FState.UndoRedo := False;

    CodeFoldingResetCaches;
    SearchAll;
    RescanCodeFoldingRanges;
  finally
    if LChangeTrim then
      Include(FOptions, eoTrimTrailingSpaces);

    Screen.Cursor := crDefault;
  end;
end;

procedure TCustomTextEditor.DoKeyPressW(var AMessage: TWMKey);
var
  LForm: TCustomForm;
  LKey: Char;
begin
  LKey := Char(AMessage.CharCode);

  if FCompletionProposal.Active and FCompletionProposal.Trigger.Active then
  begin
    if FastPos(LKey, FCompletionProposal.Trigger.Chars) > 0 then
    begin
      FCompletionProposalTimer.Interval := FCompletionProposal.Trigger.Interval;
      FCompletionProposalTimer.Enabled := True;
    end
    else
      FCompletionProposalTimer.Enabled := False;
  end;

  LForm := GetParentForm(Self);
  if Assigned(LForm) and (LForm <> TWinControl(Self)) and LForm.KeyPreview and (LKey <= High(AnsiChar)) and
    TTextEditorAccessWinControl(LForm).DoKeyPress(AMessage) then
    Exit;

  if csNoStdEvents in ControlStyle then
    Exit;

  if Assigned(FEvents.OnKeyPressW) then
    FEvents.OnKeyPressW(Self, LKey);

  if LKey <> TControlCharacters.Null then
    KeyPressW(LKey);
end;

procedure TCustomTextEditor.DoOnCommandProcessed(ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);
var
  LTextPosition: TTextEditorTextPosition;

  function IsPreviousFoldTokenEndPreviousLine(const ALine: Integer): Boolean;
  var
    LIndex: Integer;
    LFoldingRange: TTextEditorCodeFoldingRange;
    LRegionItem: TTextEditorCodeFoldingRegionItem;
  begin
    LIndex := ALine;

    while (LIndex > 0) and not Assigned(FCodeFoldings.RangeToLine[LIndex]) do
    begin
      if Assigned(FCodeFoldings.RangeFromLine[LIndex]) then
        Exit(False);

      Dec(LIndex);
    end;

    LFoldingRange := FCodeFoldings.RangeToLine[LIndex];
    if Assigned(LFoldingRange) and Assigned(LFoldingRange.RegionItem) then
      LRegionItem := LFoldingRange.RegionItem
    else
      LRegionItem := nil;

    Result := Assigned(LRegionItem) and LRegionItem.TokenEndIsPreviousLine;
  end;

begin
  if FCodeFolding.Visible then
  begin
    LTextPosition := FPosition.Text;
    if ((ACommand = TKeyCommands.Char) or (ACommand = TKeyCommands.Backspace) or (ACommand = TKeyCommands.DeleteChar) or
      (ACommand = TKeyCommands.LineBreak)) and IsKeywordAtCaretPositionOrAfter(TextPosition) or
      FHighlighter.FoldTags and (ACommand = TKeyCommands.Char) and (AChar = '>') then
      FCodeFoldings.Rescan := True;
  end;

  if FMatchingPairs.Active and not FSyncEdit.Visible then
  case ACommand of
    TKeyCommands.Paste, TKeyCommands.Undo, TKeyCommands.Redo, TKeyCommands.Backspace, TKeyCommands.Tab, TKeyCommands.Left,
      TKeyCommands.Right, TKeyCommands.Up, TKeyCommands.Down, TKeyCommands.PageUp, TKeyCommands.PageDown,
      TKeyCommands.PageTop, TKeyCommands.PageBottom, TKeyCommands.EditorTop, TKeyCommands.EditorBottom, TKeyCommands.GoToXY,
      TKeyCommands.BlockIndent, TKeyCommands.BlockUnindent, TKeyCommands.ShiftTab, TKeyCommands.InsertLine,
      TKeyCommands.Char, TKeyCommands.Text, TKeyCommands.LineBreak, TKeyCommands.DeleteChar, TKeyCommands.DeleteWord,
      TKeyCommands.DeleteWordForward, TKeyCommands.DeleteWordBackward, TKeyCommands.DeleteBeginningOfLine,
      TKeyCommands.DeleteEndOfLine, TKeyCommands.DeleteLine, TKeyCommands.Clear, TKeyCommands.WordLeft, TKeyCommands.WordRight:
      ScanMatchingPair;
  end;

  if cfoShowIndentGuides in CodeFolding.Options then
  case ACommand of
    TKeyCommands.Cut, TKeyCommands.Paste, TKeyCommands.Undo, TKeyCommands.Redo, TKeyCommands.Backspace, TKeyCommands.DeleteChar:
      CheckIfAtMatchingKeywords;
  end;

  if Assigned(FEvents.OnCommandProcessed) then
    FEvents.OnCommandProcessed(Self, ACommand, AChar, AData);

  if FCodeFolding.Visible and not FCodeFolding.TextFolding.Active then
    if ((ACommand = TKeyCommands.Char) or (ACommand = TKeyCommands.LineBreak)) and IsPreviousFoldTokenEndPreviousLine(LTextPosition.Line) then
      FCodeFoldings.Rescan := True;

  if FCodeFolding.Visible and FCodeFolding.TextFolding.Active then
  case ACommand of
    TKeyCommands.Backspace, TKeyCommands.DeleteChar, TKeyCommands.DeleteWord, TKeyCommands.DeleteWordForward,
      TKeyCommands.DeleteWordBackward, TKeyCommands.DeleteLine, TKeyCommands.Clear, TKeyCommands.LineBreak,
      TKeyCommands.Char, TKeyCommands.Text, TKeyCommands.ImeStr, TKeyCommands.Cut, TKeyCommands.Paste,
      TKeyCommands.BlockIndent, TKeyCommands.BlockUnindent, TKeyCommands.Tab:
      FCodeFoldings.Rescan := True;
  end;
end;

procedure TCustomTextEditor.DoOnBookmarkPopup(Sender: TObject);
begin
  if Sender is TMenuItem then
    DoToggleBookmark(TMenuItem(Sender).Tag);
end;

procedure TCustomTextEditor.DoOnLeftMarginClick(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer);
var
  LIndex: Integer;
  LLine: Integer;
  LMark: TTextEditorMark;
  LFoldRange: TTextEditorCodeFoldingRange;
  LCodeFoldingRegion: Boolean;
  LTextPosition: TTextEditorTextPosition;
  LSelectedRow: Integer;

  procedure ShowBookmarkColorsPopup;
  var
    LIndex: Integer;
    LPopupMenu: TPopupMenu;
    LBookmarkColors: TTextEditorArrayOfString;
    LMenuItem: TMenuItem;
    LPoint: TPoint;
    LBitmap: Vcl.Graphics.TBitmap;
  begin
    CreateBookmarkImages;

    LPopupMenu := TPopupMenu.Create(Self);
    LPopupMenu.Images := TImageList.Create(LPopupMenu);
    with LPopupMenu.Images do
    begin
      ColorDepth := cd8Bit;
      Height := FImagesBookmark.Height;
      Width := FImagesBookmark.Width;
    end;

    for LIndex := 9 to 13 do
    begin
      LBitmap := FImagesBookmark.GetBitmap(LIndex, LeftMargin.Colors.Background);
      try
        LPopupMenu.Images.Add(LBitmap, nil);
      finally
        FreeAndNil(LBitmap);
      end;
    end;

    LBookmarkColors := [STextEditorBookmarkYellow, STextEditorBookmarkRed, STextEditorBookmarkGreen,
      STextEditorBookmarkBlue, STextEditorBookmarkPurple];

    for LIndex := 0 to Length(LBookmarkColors) - 1 do
    begin
      LMenuItem := TMenuItem.Create(LPopupMenu);
      LMenuItem.Caption := LBookmarkColors[LIndex];
      LMenuItem.ImageIndex := LIndex;
      LMenuItem.Tag := 9 + LIndex;
      LMenuItem.OnClick := DoOnBookmarkPopup;
      LPopupMenu.Items.Add(LMenuItem);
    end;
{$IFDEF ALPHASKINS}
    if Assigned(SkinData.SkinManager) then
      SkinData.SkinManager.SkinableMenus.HookPopupMenu(LPopupMenu, SkinData.SkinManager.IsActive);
{$ENDIF}
    LPoint := ClientToScreen(Point(X, Y));
    LPopupMenu.Popup(LPoint.X, LPoint.Y);
  end;

begin
  LSelectedRow := GetSelectedRow(Y);
  LLine := GetViewTextLineNumber(LSelectedRow);
  LTextPosition := ViewToTextPosition(GetViewPosition(1, LSelectedRow));
  TextPosition := LTextPosition;

  if ssShift in AShift then
    SelectionEndPosition := LTextPosition
  else
  begin
    SelectionBeginPosition := LTextPosition;
    SelectionEndPosition := FPosition.BeginSelection;
  end;

  if LeftMargin.Bookmarks.Visible and (X < LeftMargin.MarksPanel.Width) and (GetRowCountFromPixel(Y) <= FViewPosition.Row - TopLine) then
  case AButton of
    mbLeft:
      if bpoToggleBookmarkByClick in LeftMargin.MarksPanel.Options then
        DoToggleBookmark
      else
      if bpoToggleMarkByClick in LeftMargin.MarksPanel.Options then
        DoToggleMark;
    mbRight:
      if bpoShowBookmarkColorsPopup in LeftMargin.MarksPanel.Options then
        ShowBookmarkColorsPopup;
  end;

  LCodeFoldingRegion := (X >= FLeftMarginWidth - FCodeFolding.GetWidth) and (X <= FLeftMarginWidth);

  if FCodeFolding.Visible and LCodeFoldingRegion and (FLines.Count > 0) then
  begin
    LFoldRange := CodeFoldingCollapsableFoldRangeForLine(LLine);
    if cfoShowCollapseMarkAtTheEnd in FCodeFolding.Options then
      if not Assigned(LFoldRange) then
      begin
        LFoldRange := CodeFoldingFoldRangeForLineTo(LLine);
        if Assigned(LFoldRange) then
        begin
          LTextPosition := GetPosition(1, LFoldRange.FromLine - 1);
          SelectionBeginPosition := LTextPosition;
          SelectionEndPosition := FPosition.BeginSelection;
          TextPosition := LTextPosition;
          Include(FState.Flags, sfCodeFoldingCollapseMarkClicked);
        end;
      end;

    if Assigned(LFoldRange) then
    begin
      if LFoldRange.Collapsed then
        CodeFoldingExpand(LFoldRange)
      else
        CodeFoldingCollapse(LFoldRange);

      Invalidate;
      Exit;
    end;
  end;

  if Assigned(FEvents.OnLeftMarginClick) and (LLine - 1 < FLines.Count) then
  begin
    LMark := nil;

    for LIndex := 0 to FMarkList.Count - 1 do
    begin
      LMark := FMarkList.Items[LIndex];
      if LMark.Line = LLine - 1 then
        Break
      else
        LMark := nil;
    end;

    FEvents.OnLeftMarginClick(Self, AButton, X, Y, LLine - 1, LMark);
  end;
end;

procedure TCustomTextEditor.DoOnMinimapClick(const Y: Integer);
var
  LNewLine, LPreviousLine, LStep: Integer;
begin
  FMinimap.Clicked := True;
  LPreviousLine := -1;
  LNewLine := Max(1, FMinimap.TopLine + Y div FMinimap.CharHeight);

  if (LNewLine >= TopLine) and (LNewLine <= TopLine + VisibleLineCount) then
    FViewPosition.Row := LNewLine
  else
  begin
    LNewLine := LNewLine - VisibleLineCount div 2;
    LStep := Abs(LNewLine - TopLine) div 5;
    if LNewLine < TopLine then
    while LNewLine < TopLine - LStep do
    begin
      TopLine := TopLine - LStep;
      if TopLine = LPreviousLine then
        Break
      else
        LPreviousLine := TopLine;

      Invalidate;
    end
    else
    while LNewLine > TopLine + LStep do
    begin
      TopLine := TopLine + LStep;
      if TopLine = LPreviousLine then
        Break
      else
        LPreviousLine := TopLine;

      Invalidate;
    end;
    TopLine := LNewLine;
  end;
  FMinimapHelper.ClickOffsetY := LNewLine - TopLine;
end;

procedure TCustomTextEditor.DoOnSearchMapClick(const Y: Integer);
var
  LHeight: Double;
begin
  LHeight := ClientHeight / Max(FLines.Count, 1);
  GoToLineAndCenter(Round(Y / LHeight));
end;

procedure TCustomTextEditor.DoOnPaint;
begin
  if Assigned(FEvents.OnPaint) then
  begin
    Canvas.Font.Assign(Font);
    Canvas.Brush.Color := FColors.Background;

    FEvents.OnPaint(Self, Canvas);
  end;
end;

procedure TCustomTextEditor.DoOnProcessCommand(var ACommand: TTextEditorCommand; var AChar: Char; const AData: Pointer);
begin
  if ACommand < TKeyCommands.UserFirst then
  begin
    if Assigned(FEvents.OnProcessCommand) then
      FEvents.OnProcessCommand(Self, ACommand, AChar, AData);
  end
  else
  if Assigned(FEvents.OnProcessUserCommand) then
    FEvents.OnProcessUserCommand(Self, ACommand, AChar, AData);

  if Assigned(FMacroRecorder) then
    if FMacroRecorder.State = msRecording then
      FMacroRecorder.AddEvent(ACommand, AChar, AData);
end;

procedure TCustomTextEditor.DoSearchStringNotFoundDialog;
begin
  MessageDialog(Format(STextEditorSearchStringNotFound, [FSearch.SearchText]), mtInformation, [mbOK], mbOK);
end;

procedure TCustomTextEditor.DoTripleClick;
begin
  SelectionBeginPosition := GetPosition(1, FPosition.Text.Line);
  SelectionEndPosition := GetPosition(Length(FLines.Items^[FPosition.Text.Line].TextLine) + 1, FPosition.Text.Line);
  FLast.DblClick := 0;

  if Assigned(FEvents.OnCaretChanged) then
    FEvents.OnCaretChanged(Self, FPosition.Text.Char, FPosition.Text.Line, 0);
end;

procedure TCustomTextEditor.DragCanceled;
begin
  FScrollHelper.Timer.Enabled := False;
  Exclude(FState.Flags, sfDragging);

  inherited;
end;

procedure TCustomTextEditor.DragOver(ASource: TObject; X, Y: Integer; AState: TDragState; var AAccept: Boolean);
var
  LOldTextPosition: TTextEditorTextPosition;
begin
  inherited;

  if (ASource is TCustomTextEditor) and not ReadOnly then
  begin
    AAccept := True;

    if Dragging then
    begin
      if AState = dsDragLeave then
        TextPosition := PixelsToTextPosition(FMouse.Down.X, FMouse.Down.Y)
      else
      begin
        LOldTextPosition := TextPosition;
        TextPosition := PixelsToTextPosition(X, Y);
        ComputeScroll(Point(X, Y));

        if FCaret.NonBlinking.Active then
          Invalidate
        else
          UpdateCaret;
      end;
    end
    else
      TextPosition := PixelsToTextPosition(X, Y);
  end;
end;

procedure TCustomTextEditor.FreeHintForm;
begin
  if Assigned(FCodeFoldings.HintForm) then
  with FCodeFoldings do
  begin
    HintForm.Hide;
    HintForm.ItemList.Clear;
    HintForm.Free;
    HintForm := nil;
  end;

  FCodeFolding.MouseOverHint := False;
  UpdateMouseCursor;
end;

procedure TCustomTextEditor.FreeCompletionProposalPopupWindow;
var
  LCompletionProposalPopupWindow: TTextEditorCompletionProposalPopupWindow;
begin
  if Assigned(FCompletionProposalPopupWindow) then
  begin
    LCompletionProposalPopupWindow := FCompletionProposalPopupWindow;
    FCompletionProposalPopupWindow := nil; { Prevent WMKillFocus to free it again }
    LCompletionProposalPopupWindow.Hide;
    LCompletionProposalPopupWindow.Free;
  end;
end;

procedure TCustomTextEditor.HideCaret;
begin
  if (sfCaretVisible in FState.Flags) and Winapi.Windows.HideCaret(Handle) then
    Exclude(FState.Flags, sfCaretVisible);
end;

procedure TCustomTextEditor.IncPaintLock;
begin
  Inc(FPaintLock);
end;

procedure TCustomTextEditor.KeyDown(var AKey: Word; AShift: TShiftState);
var
  LData: Pointer;
  LChar: Char;
  LEditorCommand: TTextEditorCommand;
  LRangeType: TTextEditorRangeType;
  LStart: Integer;
  LToken: string;
  LHighlighterAttribute: TTextEditorHighlighterAttribute;
  LCursorPoint: TPoint;
  LTextPosition: TTextEditorTextPosition;
  LShortCutKey: Word;
  LShortCutShift: TShiftState;

  function ExecuteCompletionProposal: Boolean;
  begin
    Result := False;

    if (AShift = LShortCutShift) and (AKey = LShortCutKey) or (AKey <> LShortCutKey) and not (ssAlt in AShift) and
      not (ssCtrl in AShift) and (cpoAutoInvoke in FCompletionProposal.Options) and Chr(AKey).IsLetter then
    begin
      DoExecuteCompletionProposal;

      if not (cpoAutoInvoke in FCompletionProposal.Options) then
      begin
        AKey := 0;
        Include(FState.Flags, sfIgnoreNextChar);
        Result := True;
      end;
    end;
  end;

  function ExecuteCompletionProposalSnippet: Boolean;
  var
    LIndex: Integer;
    LSnippetItem: TTextEditorCompletionProposalSnippetItem;
  begin
    Result := False;

    for LIndex := 0 to FCompletionProposal.Snippets.Items.Count - 1 do
    begin
      LSnippetItem := FCompletionProposal.Snippets.Item[LIndex];
      if LSnippetItem.ShortCut <> scNone then
      begin
        ShortCutToKey(LSnippetItem.ShortCut, LShortCutKey, LShortCutShift);
        if (AShift = LShortCutShift) and (AKey = LShortCutKey) then
          InsertSnippet(LSnippetItem, TextPosition);
      end;
    end;
  end;

begin
  inherited;

  if soALTSetsColumnMode in FSelection.Options then
    if (ssAlt in AShift) and not FState.AltDown then
    begin
      FSaveSelectionMode := FSelection.Mode;
      FSaveScrollOption := soPastEndOfLine in FScroll.Options;
      FScroll.SetOption(soPastEndOfLine, True);
      FSelection.Mode := smColumn;
      FState.AltDown := True;
      SelectionBeginPosition := TextPosition;
    end;

  if AKey = 0 then
  begin
    Include(FState.Flags, sfIgnoreNextChar);
    Exit;
  end;

  if FCaret.MultiEdit.Active and Assigned(FMultiCaret.Carets) and (FMultiCaret.Carets.Count > 0) then
    if AKey in [TControlCharacters.Keys.CarriageReturn, TControlCharacters.Keys.Escape] then
    begin
      FreeMultiCarets;

      Invalidate;
      Exit;
    end;

  if FSyncEdit.Active then
  begin
    if FSyncEdit.Visible and (AKey in [TControlCharacters.Keys.CarriageReturn, TControlCharacters.Keys.Escape]) then
    begin
      FSyncEdit.Visible := False;
      AKey := 0;
      Exit;
    end;

    ShortCutToKey(FSyncEdit.ShortCut, LShortCutKey, LShortCutShift);

    if (AShift = LShortCutShift) and (AKey = LShortCutKey) then
    begin
      FSyncEdit.Visible := not FSyncEdit.Visible;
      AKey := 0;
      Exit;
    end;
  end;

  FKeyboardHandler.ExecuteKeyDown(Self, AKey, AShift);

  { URI mouse over }
  if (ssCtrl in AShift) and URIOpener then
  begin
    Winapi.Windows.GetCursorPos(LCursorPoint);
    LCursorPoint := ScreenToClient(LCursorPoint);
    LTextPosition := PixelsToTextPosition(LCursorPoint.X, LCursorPoint.Y);
    GetHighlighterAttributeAtRowColumn(LTextPosition, LToken, LRangeType, LStart, LHighlighterAttribute);
    FMouse.OverURI := LRangeType in [ttWebLink, ttMailtoLink];
  end;

  LData := nil;
  LChar := TControlCharacters.Null;
  try
    LEditorCommand := TranslateKeyCode(AKey, AShift);

    if FSyncEdit.Visible then
    case LEditorCommand of
      TKeyCommands.Char, TKeyCommands.Backspace, TKeyCommands.Copy, TKeyCommands.Cut, TKeyCommands.Left,
        TKeyCommands.SelectionLeft, TKeyCommands.Right, TKeyCommands.SelectionRight:
        ;
      TKeyCommands.Paste:
        if FastPos(TControlCharacters.CarriageReturn, GetClipboardText) <> 0 then
          LEditorCommand := TKeyCommands.None;
      TKeyCommands.LineBreak:
        FSyncEdit.Visible := False;
    else
      LEditorCommand := TKeyCommands.None;
    end;

    if LEditorCommand <> TKeyCommands.None then
    begin
      AKey := 0;
      Include(FState.Flags, sfIgnoreNextChar);
      CommandProcessor(LEditorCommand, LChar, LData);
    end
    else
      Exclude(FState.Flags, sfIgnoreNextChar);
  finally
    if Assigned(LData) then
      FreeMem(LData);
  end;

  if soALTSetsColumnMode in FSelection.Options then
    if not (ssAlt in AShift) and not (ssCtrl in AShift) and FState.AltDown then
    begin
      FSelection.Mode := FSaveSelectionMode;
      FScroll.SetOption(soPastEndOfLine, FSaveScrollOption);
      FState.AltDown := False;
    end;

  if Assigned(FCompletionProposalPopupWindow) and not FCompletionProposalPopupWindow.Visible then
    FreeCompletionProposalPopupWindow;

  if not ReadOnly and FCompletionProposal.Active and not Assigned(FCompletionProposalPopupWindow) then
  begin
    ShortCutToKey(FCompletionProposal.ShortCut, LShortCutKey, LShortCutShift);

    if ExecuteCompletionProposal then
      Exit;

    if ExecuteCompletionProposalSnippet then
      Exit;
  end;

  if FCodeFolding.Visible and FCodeFoldings.Rescan then
    FCodeFoldings.DelayTimer.Restart;
end;

procedure TCustomTextEditor.KeyPressW(var AKey: Char);
begin
  if sfIgnoreNextChar in FState.Flags then
    Exclude(FState.Flags, sfIgnoreNextChar)
  else
  begin
    FKeyboardHandler.ExecuteKeyPress(Self, AKey);
    CommandProcessor(TKeyCommands.Char, AKey, nil);
  end
end;

procedure TCustomTextEditor.KeyUp(var AKey: Word; AShift: TShiftState);
begin
  inherited;

  if FMouse.OverURI then
    FMouse.OverURI := False;

  if FCodeFolding.Visible then
    CheckIfAtMatchingKeywords;

  FKeyboardHandler.ExecuteKeyUp(Self, AKey, AShift);

  if FMultiCaret.Position.Row <> -1 then
  begin
    FMultiCaret.Position.Row := -1;

    Invalidate;
  end;

  if FCodeFolding.Visible and FCodeFoldings.Rescan then
    FCodeFoldings.DelayTimer.Restart;
end;

procedure TCustomTextEditor.LinesChanged(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  Exclude(FState.Flags, sfLinesChanging);

  if Visible and HandleAllocated then
  begin
    if FLeftMargin.LineNumbers.Visible and FLeftMargin.Autosize then
      FLeftMargin.AutosizeDigitCount(FLines.Count);
    UpdateScrollBars;
  end;
end;

procedure TCustomTextEditor.LinesHookChanged;
begin
  SetHorizontalScrollPosition(FScrollHelper.HorizontalPosition);
  UpdateScrollBars;
end;

procedure TCustomTextEditor.LinesBeforeDeleted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
begin  //FI:W519 Method is empty
  { Do nothing }
end;

procedure TCustomTextEditor.LinesBeforeInserted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
begin  //FI:W519 Method is empty
  { Do nothing }
end;

procedure TCustomTextEditor.LinesBeforePutted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
begin  //FI:W519 Method is empty
  { Do nothing }
end;

procedure TCustomTextEditor.LinesCleared(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  MoveCaretToBeginning;
  ClearCodeFolding;
  ClearMatchingPair;
  ClearSelection;
  FBookmarkList.Clear;
  FMarkList.Clear;
  FUndoList.Clear;
  FRedoList.Clear;
  FLineNumbers.ResetCache := True;
  SetModified(False);
end;

function CompareLines(AItem1, AItem2: Pointer): Integer;
var
  LTextPosition1, LTextPosition2: TTextEditorTextPosition;
begin
  LTextPosition1 := PTextEditorTextPosition(AItem1)^;
  LTextPosition2 := PTextEditorTextPosition(AItem2)^;

  Result := LTextPosition1.Line - LTextPosition2.Line;
  if Result = 0 then
    Result := LTextPosition1.Char - LTextPosition2.Char;
end;

{$IFDEF TEXT_EDITOR_SPELL_CHECK}
procedure TCustomTextEditor.DeleteSpellCheckItems(const AFromLine: Integer; const AToLine: Integer);
var
  LIndex: Integer;
begin
  LIndex := FSpellCheck.Items.Count - 1;
  while (LIndex >= 0) and (PTextEditorTextPosition(FSpellCheck.Items[LIndex]).Line <> AToLine) do
    Dec(LIndex);
  while (LIndex >= 0) and (PTextEditorTextPosition(FSpellCheck.Items[LIndex]).Line >= AFromLine) do
  begin
    Dispose(PTextEditorTextPosition(FSpellCheck.Items[LIndex]));
    FSpellCheck.Items.Delete(LIndex);
    Dec(LIndex);
  end;
end;

procedure TCustomTextEditor.MoveSpellCheckItems(const ALine: Integer; const ACount: Integer);
var
  LIndex: Integer;
  LPTextPosition: PTextEditorTextPosition;
begin
  LIndex := FSpellCheck.Items.Count - 1;
  while (LIndex >= 0) and (PTextEditorTextPosition(FSpellCheck.Items[LIndex]).Line >= ALine) do
  begin
    LPTextPosition := PTextEditorTextPosition(FSpellCheck.Items[LIndex]);
    LPTextPosition^.Line := LPTextPosition^.Line + ACount;
    Dec(LIndex);
  end;
end;

procedure TCustomTextEditor.UpdateSpellCheckItems(const ALine: Integer; const ACount: Integer);
begin
  if ACount = 0 then
  begin
    DeleteSpellCheckItems(ALine, ALine);
    ScanSpellCheck(ALine, ALine);
  end
  else
  if ACount > 0 then
  begin
    MoveSpellCheckItems(ALine, ACount);
    ScanSpellCheck(ALine, ALine + ACount - 1);
  end
  else
  begin
    DeleteSpellCheckItems(ALine, ALine - ACount - 1);
    MoveSpellCheckItems(ALine, ACount);
  end;

  if ACount >= 0 then
    FSpellCheck.Items.Sort(CompareLines);
end;

procedure TCustomTextEditor.ScanSpellCheck(const AFromLine: Integer; const AToLine: Integer);
var
  LPWord: PChar;
  LWord: string;
  LIsWord: Boolean;
  LCommentsFound: Boolean;
  LLine: Integer;
  LPTextPosition: PTextEditorTextPosition;
begin
  LCommentsFound := FHighlighter.Comments.BlockCommentsFound or FHighlighter.Comments.LineCommentsFound;

  for LLine := AFromLine to AToLine do
  begin
    if LLine = 0 then
      FHighlighter.ResetRange
    else
      FHighlighter.SetRange(FLines.Ranges[LLine - 1]);
    FHighlighter.SetLine(FLines.Items^[LLine].TextLine);
    while not FHighlighter.EndOfLine do
    begin
      FHighlighter.GetToken(LWord);

      if Length(LWord) > 1 then
        if LCommentsFound and (FHighlighter.TokenType in [ttBlockComment, ttLineComment, ttString]) or not
          LCommentsFound then
        begin
          LIsWord := True;
          LPWord := PChar(LWord);
          while LPWord^ <> TControlCharacters.Null do
          begin
            if not LPWord^.IsLetter then
            begin
              LIsWord := False;
              Break;
            end;
            Inc(LPWord);
          end;

          if LIsWord and not FSpellCheck.IsCorrectlyWritten(LWord) then
          begin
            New(LPTextPosition);
            LPTextPosition^.Line := LLine;
            LPTextPosition^.Char := FHighlighter.TokenPosition + 1;
            FSpellCheck.Items.Add(LPTextPosition);
          end;
        end;
      FHighlighter.Next;
    end;
  end;
end;

procedure TCustomTextEditor.DoSpellCheck;
var
  LWord: string;
  LTextPosition: TTextEditorTextPosition;
begin
  if not Assigned(FSpellCheck) then
    Exit;

  FSpellCheck.ClearItems;
  try
    if not (eoSpellCheck in FOptions) then
      Exit;

    ScanSpellCheck(0, FLines.Count - 1);

    if FSpellCheck.Items.Count > 0 then
    begin
      LTextPosition := PTextEditorTextPosition(FSpellCheck.Items[0])^;
      LWord := WordAtTextPosition(LTextPosition);
      TextPosition := GetPosition(LTextPosition.Char + Length(LWord), LTextPosition.Line);
    end;
  finally
    ClearMinimapBuffer;

    Invalidate;
  end;
end;
{$ENDIF}

procedure TCustomTextEditor.LinesDeleted(ASender: TObject; const AIndex: Integer; const ACount: Integer); //FI:O804 Method parameter is declared but never used
var
  LIndex: Integer;

  procedure UpdateMarks(AMarkList: TTextEditorMarkList);
  var
    LMarkIndex: Integer;
    LMark: TTextEditorMark;
  begin
    for LMarkIndex := 0 to AMarkList.Count - 1 do
    begin
      LMark := AMarkList[LMarkIndex];
      if InRange(LMark.Line, LIndex, LIndex + ACount) then
        LMark.Line := LIndex
      else
      if LMark.Line > LIndex then
        LMark.Line := LMark.Line - ACount
    end;
  end;

begin
  LIndex := AIndex;

  UpdateMarks(FBookmarkList);
  UpdateMarks(FMarkList);

  if FCodeFolding.Visible then
    CodeFoldingLinesDeleted(LIndex + 1, ACount);

  if Assigned(FEvents.OnLinesDeleted) then
    FEvents.OnLinesDeleted(Self, LIndex, ACount);

  if Assigned(FHighlighter) then
  begin
    LIndex := Max(LIndex, 1);
    if FLines.Count > 0 then
      ScanHighlighterRangesFrom(LIndex);
  end;

  CreateLineNumbersCache(True);
  CodeFoldingResetCaches;

  if not FState.ReplaceLock then
    SearchAll;

{$IFDEF TEXT_EDITOR_SPELL_CHECK}
  if eoSpellCheck in FOptions then
    UpdateSpellCheckItems(AIndex, -ACount);
{$ENDIF}

  Invalidate;
end;

procedure TCustomTextEditor.LinesInserted(ASender: TObject; const AIndex: Integer; const ACount: Integer); //FI:O804 Method parameter is declared but never used
var
  LLastScan: Integer;

  procedure UpdateMarks(const AMarkList: TTextEditorMarkList);
  var
    LIndex: Integer;
    LMark: TTextEditorMark;
  begin
    for LIndex := 0 to AMarkList.Count - 1 do
    begin
      LMark := AMarkList[LIndex];
      if LMark.Line >= AIndex then
        LMark.Line := LMark.Line + ACount;
    end;
  end;

begin
  if not FLines.Streaming then
  begin
    UpdateMarks(FBookmarkList);
    UpdateMarks(FMarkList);

    if FCodeFolding.Visible then
      UpdateFoldingRanges(AIndex + 1, ACount);

{$IFDEF TEXT_EDITOR_SPELL_CHECK}
    if eoSpellCheck in FOptions then
      UpdateSpellCheckItems(AIndex, ACount);
{$ENDIF}

    if Assigned(FHighlighter.BeforePrepare) then
      FHighlighter.SetOption(hoExecuteBeforePrepare, True);
  end;

  if Assigned(Parent) then
    if Assigned(FHighlighter) and (FLines.Count > 0) then
    begin
      LLastScan := AIndex;
      repeat
        LLastScan := ScanHighlighterRangesFrom(LLastScan);
        Inc(LLastScan);
      until LLastScan >= AIndex + ACount;
    end;
  CreateLineNumbersCache(True);

  if not FState.UndoRedo then
  begin
    CodeFoldingResetCaches;
    SearchAll;
  end;
end;

procedure TCustomTextEditor.LinesPutted(ASender: TObject; const AIndex: Integer; const ACount: Integer); //FI:O804 Method parameter is declared but never used
var
  LIndex: Integer;
begin
  if not FState.ReplaceLock then
    SearchAll;

{$IFDEF TEXT_EDITOR_SPELL_CHECK}
  if eoSpellCheck in FOptions then
    UpdateSpellCheckItems(AIndex, 0);
{$ENDIF}

  if Assigned(Parent) then
    if Assigned(FHighlighter) and (FLines.Count > 0) then
    begin
      LIndex := AIndex;
      repeat
        LIndex := ScanHighlighterRangesFrom(LIndex);
        Inc(LIndex);
      until LIndex >= AIndex + ACount;
    end;

  if Assigned(FEvents.OnLinesPutted) then
    FEvents.OnLinesPutted(Self, AIndex, ACount);

  if Assigned(FHighlighter.BeforePrepare) then
    FHighlighter.SetOption(hoExecuteBeforePrepare, True);

  Invalidate;
end;

procedure TCustomTextEditor.AfterConstruction;
begin
  inherited AfterConstruction;

{$IFDEF ALPHASKINS}
  if HandleAllocated then
    RefreshEditScrolls(SkinData, FScrollHelper.Wnd);

  UpdateData(FSkinData);
{$ENDIF}
end;

procedure TCustomTextEditor.Loaded;
begin
  inherited Loaded;

  DoLeftMarginAutoSize;
{$IFDEF ALPHASKINS}
  FSkinData.Loaded(False);
{$ENDIF}
end;

procedure TCustomTextEditor.MarkListChange(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  Invalidate;
end;

procedure TCustomTextEditor.MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer);
var
  LSelectionAvailable: Boolean;
  LViewPosition: TTextEditorViewPosition;
  LTextPosition: TTextEditorTextPosition;
  LRow, LRowCount: Integer;
  LMinimapLeft, LMinimapRight: Integer;
  LSelectedRow: Integer;
begin
  LSelectionAvailable := GetSelectionAvailable;
  LSelectedRow := GetSelectedRow(Y);

  if AButton = mbLeft then
  begin
    FMouse.Down.X := X;
    if not FRuler.Visible or FRuler.Visible and (Y > FRuler.Height) then
      FMouse.Down.Y := Y;

    if FMinimap.Visible then
      ClearMinimapBuffer;

    FreeCompletionProposalPopupWindow;

    if not ReadOnly and FCaret.MultiEdit.Active and not FMouse.OverURI then
    begin
      if ssCtrl in AShift then
      begin
        LViewPosition := PixelsToViewPosition(X, Y);
        if ssShift in AShift then
          AddMultipleCarets(LViewPosition)
        else
          AddCaret(LViewPosition);

        Invalidate;
        Exit;
      end
      else
        FreeMultiCarets;
    end;
  end;

  if FSearch.Map.Visible then
    if (FSearch.Map.Align = saRight) and (X > Width - FSearch.Map.GetWidth) or
      (FSearch.Map.Align = saLeft) and (X <= FSearch.Map.GetWidth) then
    begin
      DoOnSearchMapClick(Y);
      Exit;
    end;

  if not ReadOnly and FSyncEdit.Active and FSyncEdit.Activator.Visible and not FSyncEdit.Visible and LSelectionAvailable then
  begin
    LViewPosition := TextToViewPosition(SelectionEndPosition);

    if X < LeftMargin.MarksPanel.Width then
    begin
      LRowCount := GetRowCountFromPixel(Y);
      LRow := LViewPosition.Row - TopLine;
      if (LRowCount <= LRow) and (LRowCount > LRow - 1) then
      begin
        FSyncEdit.Visible := True;
        Exit;
      end;
    end;
  end;

  if not ReadOnly and FSyncEdit.Active then
  begin
    LTextPosition := PixelsToTextPosition(X, Y);
    if FSyncEdit.BlockSelected and not FSyncEdit.IsTextPositionInBlock(LTextPosition) then
      FSyncEdit.Visible := False;

    if FSyncEdit.Visible then
      if FSyncEdit.IsTextPositionInEdit(LTextPosition) then
      begin
        TextPosition := LTextPosition;
        SelectionBeginPosition := TextPosition;
        Exit;
      end
      else
        FSyncEdit.Visible := False
  end;

  if FMinimap.Visible and not FMinimap.Dragging then
  begin
    GetMinimapLeftRight(LMinimapLeft, LMinimapRight);

    if InRange(X, LMinimapLeft, LMinimapRight) then
    begin
      DoOnMinimapClick(Y);

      Invalidate;
      Exit;
    end;
  end;

  inherited MouseDown(AButton, AShift, X, Y);

  if FRightMargin.Visible and (rmoMouseMove in FRightMargin.Options) then
    if (AButton = mbLeft) and
      (Abs(FRightMargin.Position * FPaintHelper.CharWidth + FLeftMarginWidth - X - FScrollHelper.HorizontalPosition) < 3) then
    begin
      FRightMargin.Moving := True;
      FRightMarginMovePosition := FRightMargin.Position * FPaintHelper.CharWidth + FLeftMarginWidth;
      Exit;
    end;

  if FCodeFolding.Visible and (AButton = mbLeft) and FCodeFolding.Hint.Indicator.Visible and
    (cfoExpandByHintClick in FCodeFolding.Options) and (FLines.Count > 0) then
    if DoOnCodeFoldingHintClick(Point(X, Y)) then
    begin
      Include(FState.Flags, sfCodeFoldingCollapseMarkClicked);
      FCodeFolding.MouseOverHint := False;
      UpdateMouseCursor;

      Invalidate;
      Exit;
    end;

  if X + 4 > FLeftMarginWidth then
  begin
    if (AButton = mbLeft) or (AButton = mbRight) then
      LTextPosition := PixelsToTextPosition(X, Y);

    if not FRuler.Visible or FRuler.Visible and (Y > FRuler.Height) then
    begin
      FMouse.DownInText := TopLine + GetRowCountFromPixel(Y) <= FLineNumbers.Count;

      if FMouse.DownInText then
      begin
        FKeyboardHandler.ExecuteMouseDown(Self, AButton, AShift, X, Y);

        if (AButton = mbLeft) and (ssDouble in AShift) then
        begin
          FLast.DblClick := GetTickCount;
          FLast.Row := LSelectedRow;
          Exit;
        end
        else
        if (soTripleClickRowSelect in FSelection.Options) and (AShift = [ssLeft]) and (FLast.DblClick > 0) then
        begin
          if (GetTickCount - FLast.DblClick < FDoubleClickTime) and (FLast.Row = LSelectedRow) then
          begin
            DoTripleClick;

            Invalidate;
            Exit;
          end;
          FLast.DblClick := 0;
        end;

        if AButton = mbLeft then
        begin
          if (FLast.Row > 0) and (FLast.Row <= FLines.Count) then
            DoTrimTrailingSpaces(FLast.Row - 1);

          FLast.Row := LSelectedRow;

          FUndoList.AddChange(crCaret, TextPosition, SelectionBeginPosition, SelectionEndPosition, '', FSelection.ActiveMode);
          TextPosition := LTextPosition;

          MouseCapture := True;

          Exclude(FState.Flags, sfWaitForDragging);
          if LSelectionAvailable and (eoDragDropEditing in FOptions) and (X > FLeftMarginWidth) and
            (FSelection.Mode = smNormal) and IsTextPositionInSelection(LTextPosition) then
            Include(FState.Flags, sfWaitForDragging);
        end
        else
        if AButton = mbRight then
        begin
          if (coRightMouseClickMove in FCaret.Options) and
            (LSelectionAvailable and not IsTextPositionInSelection(LTextPosition) or not LSelectionAvailable) then
          begin
            Invalidate;

            FPosition.EndSelection := FPosition.BeginSelection;
            TextPosition := LTextPosition;
          end
          else
            Exit;
        end;

        if FState.Flags * [sfWaitForDragging, sfDblClicked] = [] then
        begin
          if ssShift in AShift then
            SetSelectionEndPosition(TextPosition)
          else
          begin
            if soALTSetsColumnMode in FSelection.Options then
              if not (ssAlt in AShift) and FState.AltDown then
              begin
                FSelection.Mode := FSaveSelectionMode;
                FScroll.SetOption(soPastEndOfLine, FSaveScrollOption);
                FState.AltDown := False;
              end;

            SelectionBeginPosition := TextPosition;
          end;
        end;
      end
      else
      begin
        LTextPosition := GetPosition(Length(FLines[LTextPosition.Line]) + 1, FLines.Count - 1);
        TextPosition := LTextPosition;
        SelectionBeginPosition := LTextPosition;
        SelectionEndPosition := LTextPosition;
      end;
    end
    else
    if FRuler.Visible and (Y <= FRuler.Height) then
    begin
      LTextPosition.Line := FPosition.Text.Line;
      TextPosition := LTextPosition;

      FRulerMovePosition := -1;
      FRuler.Moving := True;
      Exit;
    end;
  end;

  if soWheelClickMove in FScroll.Options then
    if (AButton = mbMiddle) and not FMouse.IsScrolling then
    begin
      FMouse.IsScrolling := True;
      FMouse.ScrollingPoint := Point(X, Y);

      Invalidate;
      Exit;
    end
    else
    if FMouse.IsScrolling then
    begin
      FMouse.IsScrolling := False;

      Invalidate;
      Exit;
    end;

  if (X + 4 < FLeftMarginWidth) and (not FRuler.Visible or FRuler.Visible and (Y > FRuler.Height)) then
    DoOnLeftMarginClick(AButton, AShift, X, Y);

  if FMatchingPairs.Active then
    ScanMatchingPair;

  SetFocus;
end;

function TCustomTextEditor.ShortCutPressed: Boolean;
var
  LIndex: Integer;
  LKeyCommand: TTextEditorKeyCommand;
begin
  Result := False;

  for LIndex := 0 to FKeyCommands.Count - 1 do
  begin
    LKeyCommand := FKeyCommands[LIndex];
    if (LKeyCommand.ShiftState = [ssCtrl, ssShift]) or (LKeyCommand.ShiftState = [ssCtrl]) then
      if GetKeyState(LKeyCommand.Key) < 0 then
        Exit(True);
  end;
end;

procedure TCustomTextEditor.MouseMove(AShift: TShiftState; X, Y: Integer);
var
  LIndex: Integer;
  LViewPosition: TTextEditorViewPosition;
  LFoldRange: TTextEditorCodeFoldingRange;
  LPoint: TPoint;
  LRect: TRect;
  LHintWindow: THintWindow;
  LPositionText: string;
  LLine: Integer;
  LTextPosition: TTextEditorTextPosition;
  LMultiCaretPosition: TTextEditorViewPosition;
  LRow, LRowCount: Integer;
begin
  if Dragging then
    Exit;

  if FCaret.MultiEdit.Active and Focused then
  begin
    if (AShift = [ssCtrl, ssShift]) or (AShift = [ssCtrl]) then
      if not ShortCutPressed then
      begin
        LMultiCaretPosition := PixelsToViewPosition(X, Y);

        if not FMouse.OverURI and (meoShowGhost in FCaret.MultiEdit.Options) and (LMultiCaretPosition.Row <= FLines.Count) then
          if (FMultiCaret.Position.Row <> LMultiCaretPosition.Row) or
            (FMultiCaret.Position.Row = LMultiCaretPosition.Row) and (FMultiCaret.Position.Column <> LMultiCaretPosition.Column) then
          begin
            FMultiCaret.Position := LMultiCaretPosition;

            Invalidate;
          end;
      end;

    if Assigned(FMultiCaret.Carets) and (FMultiCaret.Carets.Count > 0) then
      Exit;
  end;

  if FMouse.IsScrolling then
  begin
    ComputeScroll(Point(X, Y));
    Exit;
  end;

  if FMinimap.Visible and FMinimap.Clicked then
  begin
    if (X > FMinimapHelper.Left) and (X < FMinimapHelper.Right) then
    begin
      if FMinimap.Dragging then
        DragMinimap(Y);

      if not FMinimap.Dragging and (ssLeft in AShift) and MouseCapture and (Abs(FMouse.Down.Y - Y) >= FSystemMetrics.VerticalDrag) then
        FMinimap.Dragging := True;
    end;
    Exit;
  end;

  if FSearch.Map.Visible then
    if (FSearch.Map.Align = saRight) and (X > Width - FSearch.Map.GetWidth) or
      (FSearch.Map.Align = saLeft) and (X <= FSearch.Map.GetWidth) then
      Exit;

  inherited MouseMove(AShift, X, Y);

  if FMouse.OverURI and not (ssCtrl in AShift) then
    FMouse.OverURI := False;

  if FRightMargin.Visible and (rmoMouseMove in FRightMargin.Options) then
  begin
    FRightMargin.MouseOver := Abs(FRightMargin.Position * FPaintHelper.CharWidth + FLeftMarginWidth - X -
      FScrollHelper.HorizontalPosition) < 3;

    if FRightMargin.Moving then
    begin
      if X > FLeftMarginWidth then
        FRightMarginMovePosition := X;

      if rmoShowMovingHint in FRightMargin.Options then
      begin
        LHintWindow := GetHintWindow;

        LPositionText := Format(STextEditorRightMarginPosition,
          [(FRightMarginMovePosition - FLeftMarginWidth + FScrollHelper.HorizontalPosition) div FPaintHelper.CharWidth]);

        LRect := LHintWindow.CalcHintRect(200, LPositionText, nil);
        LPoint := ClientToScreen(Point(ClientRect.Right - LRect.Right - 4, 4));

        OffsetRect(LRect, LPoint.X, LPoint.Y);
        LHintWindow.ActivateHint(LRect, LPositionText);
        LHintWindow.Invalidate;
      end;

      Invalidate;
      Exit;
    end;
  end;

  if FRuler.Moving and (X > FLeftMarginWidth) then
  begin
    LTextPosition := PixelsToTextPosition(X, Y);

    FRulerMovePosition := FLeftMarginWidth + (LTextPosition.Char - 1) * FPaintHelper.CharWidth - FScrollHelper.HorizontalPosition;

    LHintWindow := GetHintWindow;
    LPositionText := Format(STextEditorRightMarginPosition, [LTextPosition.Char - 1]);
    LRect := LHintWindow.CalcHintRect(200, LPositionText, nil);
    LPoint := ClientToScreen(Point(ClientRect.Right - LRect.Right - 4, FRuler.Height + 4));
    OffsetRect(LRect, LPoint.X, LPoint.Y);
    LHintWindow.ActivateHint(LRect, LPositionText);
    LHintWindow.Invalidate;

    Invalidate;
    Exit;
  end;

  if (AShift = []) and FCodeFolding.Visible and FCodeFolding.Hint.Indicator.Visible and FCodeFolding.Hint.Visible then
  begin
    LLine := GetViewTextLineNumber(GetSelectedRow(Y));

    LFoldRange := CodeFoldingCollapsableFoldRangeForLine(LLine);

    if Assigned(LFoldRange) and LFoldRange.Collapsed and not LFoldRange.ParentCollapsed then
    begin
      LPoint := Point(X, Y);
      LRect := LFoldRange.CollapseMarkRect;
      OffsetRect(LRect, -FLeftMarginWidth, 0);

      if LRect.Right > FLeftMarginWidth then
      begin
        FCodeFolding.MouseOverHint := False;
        if PtInRect(LRect, LPoint) then
        begin
          FCodeFolding.MouseOverHint := True;

          if not Assigned(FCodeFoldings.HintForm) then
          begin
            FCodeFoldings.HintForm := TTextEditorCodeFoldingHintForm.Create(Self);
            with FCodeFoldings.HintForm do
            begin
              BackgroundColor := FCodeFolding.Hint.Colors.Background;
              BorderColor := FCodeFolding.Hint.Colors.Border;
              Font.Assign(FCodeFolding.Hint.Font);
            end;

            LLine := LFoldRange.ToLine - LFoldRange.FromLine - 1;
            if LLine > FCodeFolding.Hint.RowCount then
              LLine := FCodeFolding.Hint.RowCount;

            for LIndex := LFoldRange.FromLine - 1 to LFoldRange.FromLine + LLine do
              FCodeFoldings.HintForm.ItemList.Add(FLines.ExpandedStrings[LIndex]);

            if LLine = FCodeFolding.Hint.RowCount then
              FCodeFoldings.HintForm.ItemList.Add(TCharacters.ThreeDots);

            LPoint.X := FLeftMarginWidth;
            LPoint.Y := LRect.Bottom + 2;
            LPoint := ClientToScreen(LPoint);

            FCodeFoldings.HintForm.Execute(LPoint.X, LPoint.Y);
          end;
        end
        else
          FreeHintForm;
      end
      else
        FreeHintForm;
    end
    else
      FreeHintForm;
  end;

  if MouseCapture then
    if sfWaitForDragging in FState.Flags then
    begin
      if (Abs(FMouse.Down.X - X) >= FSystemMetrics.HorizontalDrag) or (Abs(FMouse.Down.Y - Y) >= FSystemMetrics.VerticalDrag) then
      begin
        Exclude(FState.Flags, sfWaitForDragging);
        BeginDrag(False);
        Include(FState.Flags, sfDragging);
      end;
    end
    else
    if (ssLeft in AShift) and ((X <> FLast.MouseMovePoint.X) or (Y <> FLast.MouseMovePoint.Y)) then
    begin
      if not FRuler.Visible or FRuler.Visible and (Y > FRuler.Height) then
      begin
        FLast.MouseMovePoint.X := X;
        FLast.MouseMovePoint.Y := Y;

        LViewPosition := PixelsToViewPosition(X, Y);
        LViewPosition.Row := EnsureRange(LViewPosition.Row, 1, Max(FLineNumbers.Count, 1));

        if FScrollHelper.Delta.X <> 0 then
          LViewPosition.Column := FViewPosition.Column;

        if FScrollHelper.Delta.Y <> 0 then
          LViewPosition.Row := FViewPosition.Row;

        if not (sfCodeFoldingCollapseMarkClicked in FState.Flags) then { No selection when info clicked }
        begin
          LRowCount := GetRowCountFromPixel(Y);
          LRow := LViewPosition.Row - TopLine;
          LTextPosition := ViewToTextPosition(LViewPosition);
          if LRowCount <= LRow then
          begin
            if not IsSamePosition(FPosition.Text, LTextPosition) then
            begin
              TextPosition := LTextPosition;
              if (uoGroupUndo in FUndo.Options) and UndoList.CanUndo then
                FUndoList.AddGroupBreak;
            end;

            FState.ExecutingSelectionCommand := False;

            if not IsSamePosition(FPosition.EndSelection, LTextPosition) then
            begin
              FState.ExecutingSelectionCommand := True;
              SelectionEndPosition := LTextPosition;
            end;
          end
          else
          if PtInRect(ClientRect, Point(X, Y)) then
          begin
            if Assigned(FLines.Items) then
              LTextPosition := GetPosition(Length(FLines.Items^[LTextPosition.Line].TextLine) + 1, LTextPosition.Line)
            else
              LTextPosition := GetPosition(1, 0);

            if not IsSamePosition(FPosition.Text, LTextPosition) then
              TextPosition := LTextPosition;

            if not IsSamePosition(FPosition.EndSelection, LTextPosition) then
              SelectionEndPosition := LTextPosition;
          end;
        end;

        ComputeScroll(FLast.MouseMovePoint);

        FLast.SortOrder := soDesc;
        Include(FState.Flags, sfInSelection);
        Exclude(FState.Flags, sfCodeFoldingCollapseMarkClicked);

        Invalidate;
      end;
    end;
end;

procedure TCustomTextEditor.MouseUp(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer);
var
  LRangeType: TTextEditorRangeType;
  LStart: Integer;
  LToken: string;
  LHighlighterAttribute: TTextEditorHighlighterAttribute;
  LCursorPoint: TPoint;
  LTextPosition: TTextEditorTextPosition;
begin
  FMinimap.Clicked := False;
  FMinimap.Dragging := False;

  Exclude(FState.Flags, sfInSelection);

  inherited MouseUp(AButton, AShift, X, Y);

  FKeyboardHandler.ExecuteMouseUp(Self, AButton, AShift, X, Y);

  if FCodeFolding.Visible then
    CheckIfAtMatchingKeywords;

  if FMouse.OverURI and (AButton = mbLeft) and (X > FLeftMarginWidth) then
  begin
    Winapi.Windows.GetCursorPos(LCursorPoint);
    LCursorPoint := ScreenToClient(LCursorPoint);
    LTextPosition := PixelsToTextPosition(LCursorPoint.X, LCursorPoint.Y);
    GetHighlighterAttributeAtRowColumn(LTextPosition, LToken, LRangeType, LStart, LHighlighterAttribute);
    OpenLink(LToken);

    Exit;
  end;

  if FRightMargin.Visible and FRightMargin.Moving and (rmoMouseMove in FRightMargin.Options) then
  begin
    FRightMargin.Moving := False;

    if rmoShowMovingHint in FRightMargin.Options then
      ShowWindow(GetHintWindow.Handle, SW_HIDE);

    FRightMargin.Position := (FRightMarginMovePosition - FLeftMarginWidth + FScrollHelper.HorizontalPosition) div FPaintHelper.CharWidth;

    if Assigned(FEvents.OnRightMarginMouseUp) then
      FEvents.OnRightMarginMouseUp(Self);

    Invalidate;
    Exit;
  end;

  if FRuler.Visible and FRuler.Moving then
  begin
    LTextPosition := PixelsToTextPosition(X, Y);
    LTextPosition.Line := FPosition.Text.Line;
    TextPosition := LTextPosition;
    ShowWindow(GetHintWindow.Handle, SW_HIDE);
    FRuler.Moving := False;

    Invalidate;
    Exit;
  end;

  FMouse.ScrollTimer.Enabled := False;
  FScrollHelper.Timer.Enabled := False;

  if Assigned(PopupMenu) and (AButton = mbRight) and (AShift = [ssRight]) then
    Exit;

  MouseCapture := False;

  if FState.Flags * [sfDblClicked, sfWaitForDragging] = [sfWaitForDragging] then
  begin
    LTextPosition := PixelsToTextPosition(X, Y);

    TextPosition := LTextPosition;
    if not (ssShift in AShift) then
      SetSelectionBeginPosition(LTextPosition);
    SetSelectionEndPosition(LTextPosition);

    ClearMinimapBuffer;

    Exclude(FState.Flags, sfWaitForDragging);
  end;
  Exclude(FState.Flags, sfDblClicked);
end;

procedure TCustomTextEditor.NotifyHookedCommandHandlers(const AAfterProcessing: Boolean; var ACommand: TTextEditorCommand;
  var AChar: Char; const AData: Pointer);
var
  LHandled: Boolean;
  LIndex: Integer;
begin
  LHandled := False;

  for LIndex := 0 to GetHookedCommandHandlersCount - 1 do
    TTextEditorHookedCommandHandler(FHookedCommandHandlers[LIndex]).Event(Self, AAfterProcessing, LHandled, ACommand, AChar, AData);

  if LHandled then
    ACommand := TKeyCommands.None;
end;

procedure TCustomTextEditor.Paint;
var
  LClipRect, LDrawRect: TRect;
  LLine1, LLine2, LLine3, LTemp, LLineHeight: Integer;
  LSelectionAvailable: Boolean;
begin
  if FLines.ShowProgress then
  begin
    if Assigned(FEvents.OnLoadingProgress) then
      FEvents.OnLoadingProgress(Self)
    else
      PaintProgressBar;

    Exit;
  end;

  LClipRect := ClientRect;
  LLineHeight := GetLineHeight;
  LLine1 := FLineNumbers.TopLine;
  LTemp := (LClipRect.Bottom + LLineHeight - 1) div LLineHeight;
  LLine2 := EnsureRange(FLineNumbers.TopLine + LTemp - 1, 1, Max(FLineNumbers.Count, 1));
  LLine3 := FLineNumbers.TopLine + LTemp;

  if FCaret.NonBlinking.Active then
    HideCaret;

  FPaintHelper.BeginDrawing(Canvas.Handle);
  try
    Canvas.Brush.Color := FColors.Background;

    if FRuler.Visible then
      PaintRuler;

    FPaintHelper.SetBaseFont(Font);

    { Text lines }
    LDrawRect.Top := 0;
    if FRuler.Visible then
      Inc(LDrawRect.Top, FRuler.Height);
    LDrawRect.Left := FLeftMarginWidth - FScrollHelper.HorizontalPosition;
    LDrawRect.Right := Width;
    LDrawRect.Bottom := LClipRect.Height;

    PaintTextLines(LDrawRect, LLine1, LLine2, False);

    PaintRightMargin(LDrawRect);

    if FCodeFolding.Visible and not FCodeFolding.TextFolding.Active and (cfoShowIndentGuides in CodeFolding.Options) then
      PaintGuides(FLineNumbers.TopLine, Min(FLineNumbers.TopLine + VisibleLineCount, FLineNumbers.Count), False);

    if not (csDesigning in ComponentState) then
    begin
      if FSyncEdit.Active and FSyncEdit.Visible then
        PaintSyncItems;

      if FCaret.Visible then
      begin
        if FCaret.NonBlinking.Active or Assigned(FMultiCaret.Carets) and (FMultiCaret.Carets.Count > 0) and FMultiCaret.Draw then
          PaintCaret;

        if Dragging then
          PaintCaretBlock(FViewPosition);

        if not Assigned(FCompletionProposalPopupWindow) and FCaret.MultiEdit.Active and (FMultiCaret.Position.Row <> -1) then
          PaintCaretBlock(FMultiCaret.Position);
      end;

      if FRightMargin.Moving then
        PaintRightMarginMove;

      if FRuler.Moving then
        PaintRulerMove;

      if FMouse.IsScrolling then
        PaintMouseScrollPoint;
    end;

    { Left margin and code folding }
    LDrawRect := LClipRect;

    if FRuler.Visible then
      Inc(LDrawRect.Top, FRuler.Height);

    LDrawRect.Left := 0;

    if FMinimap.Align = maLeft then
      Inc(LDrawRect.Left, FMinimap.GetWidth);

    if FSearch.Map.Align = saLeft then
      Inc(LDrawRect.Left, FSearch.Map.GetWidth);

    if FLeftMargin.Visible then
    begin
      LDrawRect.Right := LDrawRect.Left + FLeftMargin.GetWidth;

      PaintLeftMargin(LDrawRect, LLine1, LLine2, LLine3);
    end;

    if FCodeFolding.Visible then
    begin
      Inc(LDrawRect.Left, FLeftMargin.GetWidth);
      LDrawRect.Right := LDrawRect.Left + FCodeFolding.GetWidth;

      PaintCodeFolding(LDrawRect, LLine1, LLine2);
    end;

    { Minimap }
    if FMinimap.Visible then
    begin
      LDrawRect := LClipRect;

      if FMinimap.Align = maRight then
      begin
        LDrawRect.Left := Width - FMinimap.GetWidth - FSearch.Map.GetWidth - 2;
        LDrawRect.Right := Width;

        if FSearch.Map.Align = saRight then
          Dec(LDrawRect.Right, FSearch.Map.GetWidth);
      end
      else
      begin
        LDrawRect.Left := 0;
        LDrawRect.Right := FMinimap.GetWidth;

        if FSearch.Map.Align = saLeft then
        begin
          Inc(LDrawRect.Left, FSearch.Map.GetWidth);
          Inc(LDrawRect.Right, FSearch.Map.GetWidth);
        end;
      end;

      FPaintHelper.SetBaseFont(FMinimap.Font);

      LSelectionAvailable := GetSelectionAvailable;

      if not FMinimap.Dragging and (LDrawRect.Height = FMinimapHelper.BufferBitmap.Height) and (FLast.TopLine = FLineNumbers.TopLine) and
        (FLast.LineNumberCount = FLineNumbers.Count) and
        (not LSelectionAvailable or LSelectionAvailable and (FPosition.BeginSelection.Line >= FLineNumbers.TopLine) and
        (FPosition.EndSelection.Line <= FLineNumbers.TopLine + VisibleLineCount)) then
      begin
        LLine1 := FLineNumbers.TopLine;
        LLine2 := Min(FLineNumbers.Count, FLineNumbers.TopLine + VisibleLineCount);
        BitBlt(Canvas.Handle, LDrawRect.Left, LDrawRect.Top, LDrawRect.Width, LDrawRect.Height,
          FMinimapHelper.BufferBitmap.Canvas.Handle, 0, 0, SRCCOPY);
        LDrawRect.Top := (FLineNumbers.TopLine - FMinimap.TopLine) * FMinimap.CharHeight;

        if FRuler.Visible then
          Inc(LDrawRect.Top, FRuler.Height);
      end
      else
      begin
        LLine1 := Max(FMinimap.TopLine, 1);
        LLine2 := Min(FLineNumbers.Count, LLine1 + LClipRect.Height div Max(FMinimap.CharHeight - 1, 1));
      end;

      PaintTextLines(LDrawRect, LLine1, LLine2, True);

      if FCodeFolding.Visible and (moShowIndentGuides in FMinimap.Options) then
        PaintGuides(LLine1, LLine2, True);

      if ioUseBlending in FMinimap.Indicator.Options then
        PaintMinimapIndicator(LDrawRect);

      FMinimapHelper.BufferBitmap.Width := LDrawRect.Width;
      FMinimapHelper.BufferBitmap.Height := LDrawRect.Height;
      BitBlt(FMinimapHelper.BufferBitmap.Canvas.Handle, 0, 0, LDrawRect.Width, LDrawRect.Height, Canvas.Handle,
        LDrawRect.Left, LDrawRect.Top, SRCCOPY);

      FPaintHelper.SetBaseFont(Font);
    end;

    { Search map }
    if FSearch.Map.Visible then
    begin
      LDrawRect := LClipRect;
      if FSearch.Map.Align = saRight then
        LDrawRect.Left := LDrawRect.Width - FSearch.Map.GetWidth
      else
      begin
        LDrawRect.Left := 0;
        LDrawRect.Right := FSearch.Map.GetWidth;
      end;

      PaintSearchMap(LDrawRect);
    end;

    if FMinimap.Visible then
      if FMinimap.Shadow.Visible then
      begin
        LDrawRect := LClipRect;
        LDrawRect.Left := FLeftMarginWidth - FLeftMargin.GetWidth - FCodeFolding.GetWidth;
        LDrawRect.Right := Width - FMinimap.GetWidth - FSearch.Map.GetWidth - 2;

        PaintMinimapShadow(Canvas, LDrawRect);
      end;

    if FScroll.Shadow.Visible and (FScrollHelper.HorizontalPosition <> 0) then
    begin
      LDrawRect := LClipRect;
      if FRuler.Visible then
        Inc(LDrawRect.Top, FRuler.Height);
      LDrawRect.Left := FLeftMarginWidth;
      LDrawRect.Right := LDrawRect.Left + FScrollHelper.PageWidth;

      PaintScrollShadow(Canvas, LDrawRect);
    end;

    DoOnPaint;
  finally
    FLast.TopLine := FLineNumbers.TopLine;
    FLast.LineNumberCount := FLineNumbers.Count;
    if not FCaret.NonBlinking.Active and not Assigned(FMultiCaret.Carets) then
      UpdateCaret;

    FPaintHelper.EndDrawing;
  end;
end;

procedure TCustomTextEditor.PaintCodeFolding(const AClipRect: TRect; const AFirstRow, ALastRow: Integer);
var
  LIndex, LLine, LLineHeight: Integer;
  LFoldRange: TTextEditorCodeFoldingRange;
  LOldBrushColor, LOldPenColor, LBackground: TColor;
  LRect: TRect;
begin
  LRect := AClipRect;
  LOldBrushColor := Canvas.Brush.Color;
  LOldPenColor := Canvas.Pen.Color;
  LLineHeight := GetLineHeight;

  Canvas.Brush.Color := FCodeFolding.Colors.Background;
  FillRect(LRect);
  Canvas.Pen.Style := psSolid;
  Canvas.Brush.Color := FCodeFolding.Colors.FoldingLine;

  LFoldRange := nil;
  if cfoHighlightFoldingLine in FCodeFolding.Options then
    LFoldRange := CodeFoldingLineInsideRange(FViewPosition.Row);

  for LIndex := AFirstRow to ALastRow do
  begin
    LLine := GetViewTextLineNumber(LIndex);

    LRect.Top := (LIndex - FLineNumbers.TopLine) * LLineHeight;
    if FRuler.Visible then
      Inc(LRect.Top, FRuler.Height);
    LRect.Bottom := LRect.Top + LLineHeight;
    if FActiveLine.Visible and (not Assigned(FMultiCaret.Carets) and (FPosition.Text.Line + 1 = LLine) or
      Assigned(FMultiCaret.CArets) and
      IsMultiEditCaretFound(LLine)) and (FCodeFolding.Colors.ActiveLineBackground <> TColors.SysNone) then
    begin
      if Focused then
        Canvas.Brush.Color := FCodeFolding.Colors.ActiveLineBackground
      else
        Canvas.Brush.Color := FCodeFolding.Colors.ActiveLineBackgroundUnfocused;

      FillRect(LRect);
    end
    else
    begin
      LBackground := GetMarkBackgroundColor(LIndex);
      if LBackground <> TColors.SysNone then
      begin
        Canvas.Brush.Color := LBackground;

        FillRect(LRect);
      end
    end;
    if Assigned(LFoldRange) and (LLine >= LFoldRange.FromLine) and (LLine <= LFoldRange.ToLine) then
    begin
      Canvas.Brush.Color := CodeFolding.Colors.FoldingLineHighlight;
      Canvas.Pen.Color := CodeFolding.Colors.FoldingLineHighlight;
    end
    else
    begin
      Canvas.Brush.Color := CodeFolding.Colors.FoldingLine;
      Canvas.Pen.Color := CodeFolding.Colors.FoldingLine;
    end;

    PaintCodeFoldingLine(LRect, LLine);
  end;

  Canvas.Brush.Color := LOldBrushColor;
  Canvas.Pen.Color := LOldPenColor;
end;

procedure TCustomTextEditor.PaintCodeFoldingLine(const AClipRect: TRect; const ALine: Integer);
var
  LRect: TRect;
  LX, LY: Integer;
  LFoldRange: TTextEditorCodeFoldingRange;
  LEndForLine: Boolean;
  LShowCollapseMarkAtTheEnd: Boolean;

  procedure PaintMark(const AEndMark: Boolean = False);
  var
    LHeight: Integer;
    LPoints: array [0..2] of TPoint;
    LTempY: Integer;
  begin
    LHeight := LRect.Right - LRect.Left;
    LRect.Top := LRect.Top + (GetLineHeight - LHeight) div 2 + 1;
    LRect.Bottom := LRect.Top + LHeight - 1;
    LRect.Right := LRect.Right - 1;

    if CodeFolding.MarkStyle = msTriangle then
    begin
      if LFoldRange.Collapsed then
      begin
        LPoints[0] := Point(LRect.Left, LRect.Top);
        LPoints[1] := Point(LRect.Left, LRect.Bottom - 1);
        LPoints[2] := Point(LRect.Right - (FCodeFolding.Width + 1) mod 2, LRect.Top + LRect.Height div 2);

        Canvas.Polygon(LPoints);
      end
      else
      if AEndMark then
      begin
        LPoints[0] := Point(LRect.Left, LRect.Bottom - 1);
        LPoints[1] := Point(LRect.Right - (FCodeFolding.Width + 1) mod 2, LRect.Bottom - 1);
        LPoints[2] := Point(LRect.Left + LRect.Width div 2, LRect.Top + 1);

        Canvas.Polygon(LPoints);
      end
      else
      begin
        LPoints[0] := Point(LRect.Left, LRect.Top + 1);
        LPoints[1] := Point(LRect.Right - (FCodeFolding.Width + 1) mod 2, LRect.Top + 1);
        LPoints[2] := Point(LRect.Left + LRect.Width div 2, LRect.Bottom - 1);

        Canvas.Polygon(LPoints);
      end;
    end
    else
    begin
      if CodeFolding.MarkStyle = msSquare then
        Canvas.FrameRect(LRect)
      else
      if CodeFolding.MarkStyle = msCircle then
      begin
        Canvas.Brush.Color := FCodeFolding.Colors.Background;
        Canvas.Ellipse(LRect);
      end;
      { - }
      LTempY := LRect.Top + ((LRect.Bottom - LRect.Top) div 2);
      Canvas.MoveTo(LRect.Left + LRect.Width div 4, LTempY);
      Canvas.LineTo(LRect.Right - LRect.Width div 4, LTempY);

      if LFoldRange.Collapsed then
      begin
        { + }
        LTempY := (LRect.Right - LRect.Left) div 2;
        Canvas.MoveTo(LRect.Left + LTempY, LRect.Top + LRect.Width div 4);
        Canvas.LineTo(LRect.Left + LTempY, LRect.Bottom - LRect.Width div 4);
      end;
    end;

    if LShowCollapseMarkAtTheEnd and (CodeFolding.MarkStyle <> msTriangle) then
    begin
      if AEndMark then
      begin
        LRect.Bottom := LRect.Top;
        LRect.Top := AClipRect.Top;

        Canvas.MoveTo(LRect.Left, LRect.Bottom);
        Canvas.LineTo(LRect.Left + LRect.Width div 2, LRect.Top);
        Canvas.LineTo(LRect.Right - (FCodeFolding.Width + 1) mod 2, LRect.Bottom);
      end
      else
      if not LFoldRange.Collapsed then
      begin
        LRect.Top := LRect.Bottom - 1;
        LRect.Bottom := AClipRect.Bottom;

        Canvas.MoveTo(LRect.Left, LRect.Top);
        Canvas.LineTo(LRect.Left + LRect.Width div 2, LRect.Bottom);
        Canvas.LineTo(LRect.Right - (FCodeFolding.Width + 1) mod 2, LRect.Top);
      end
    end;
  end;

begin
  LRect := AClipRect;
  if CodeFolding.Padding > 0 then
    InflateRect(LRect, -CodeFolding.Padding, 0);

  LFoldRange := CodeFoldingCollapsableFoldRangeForLine(ALine);
  LShowCollapseMarkAtTheEnd := cfoShowCollapseMarkAtTheEnd in FCodeFolding.Options;

  if not Assigned(LFoldRange) then
  begin
    if cfoShowTreeLine in FCodeFolding.Options then
    begin
      LEndForLine := CodeFoldingTreeEndForLine(ALine);
      if CodeFoldingTreeLineForLine(ALine) and not (LShowCollapseMarkAtTheEnd and LEndForLine) then
      begin
        LX := LRect.Left + ((LRect.Right - LRect.Left) div 2) - 1;
        Canvas.MoveTo(LX, LRect.Top);
        Canvas.LineTo(LX, LRect.Bottom);
      end;
      if LEndForLine then
      begin
        if LShowCollapseMarkAtTheEnd then
        begin
          LFoldRange := FCodeFoldings.RangeToLine[ALine];
          PaintMark(True);
        end
        else
        begin
          LX := LRect.Left + ((LRect.Right - LRect.Left) div 2) - 1;
          Canvas.MoveTo(LX, LRect.Top);
          LY := LRect.Top + ((LRect.Bottom - LRect.Top) - 4);
          Canvas.LineTo(LX, LY);
          Canvas.LineTo(LRect.Right - 1, LY);
        end;
      end;
    end;
  end
  else
  if LFoldRange.Collapsable then
    PaintMark;
end;

procedure TCustomTextEditor.PaintCodeFoldingCollapsedLine(const AFoldRange: TTextEditorCodeFoldingRange; const ALineRect: TRect);
var
  LOldPenColor: TColor;
begin
  if FCodeFolding.Visible and (cfoShowCollapsedLine in CodeFolding.Options) and Assigned(AFoldRange) and
    AFoldRange.Collapsed and not AFoldRange.ParentCollapsed then
  begin
    LOldPenColor := Canvas.Pen.Color;

    Canvas.Pen.Color := CodeFolding.Colors.CollapsedLine;
    Canvas.MoveTo(ALineRect.Left, ALineRect.Bottom - 1);
    Canvas.LineTo(Width, ALineRect.Bottom - 1);

    Canvas.Pen.Color := LOldPenColor;
  end;
end;

procedure TCustomTextEditor.PaintCodeFoldingCollapseMark(const AFoldRange: TTextEditorCodeFoldingRange;
  const ACurrentLineText: string; const ATokenPosition, ATokenLength, ALine: Integer; const ALineRect: TRect);
var
  LOldPenColor, LOldBrushColor: TColor;
  LCollapseMarkRect: TRect;
  LIndex, LX, LY: Integer;
  LBrush: TBrush;
  LViewPosition: TTextEditorViewPosition;
  LPoints: array [0..2] of TPoint;
  LDotSpace: Integer;
begin
  LOldPenColor := Canvas.Pen.Color;
  LOldBrushColor := Canvas.Brush.Color;
  if FCodeFolding.Visible and FCodeFolding.Hint.Indicator.Visible and Assigned(AFoldRange) and
    AFoldRange.Collapsed and not AFoldRange.ParentCollapsed then
  begin
    LViewPosition.Row := ALine + 1;
    LViewPosition.Column := ATokenPosition + ATokenLength + 2;
    if FSpecialChars.Visible and (ALine <> FLines.Count) and (ALine <> FLineNumbers.Count) then
      Inc(LViewPosition.Column);
    LCollapseMarkRect.Left := ViewPositionToPixels(LViewPosition, ACurrentLineText).X -
      FCodeFolding.Hint.Indicator.Padding.Left;
    LCollapseMarkRect.Right := FCodeFolding.Hint.Indicator.Padding.Right + LCollapseMarkRect.Left +
      FCodeFolding.Hint.Indicator.Width;
    LCollapseMarkRect.Top := FCodeFolding.Hint.Indicator.Padding.Top + ALineRect.Top;
    LCollapseMarkRect.Bottom := ALineRect.Bottom - FCodeFolding.Hint.Indicator.Padding.Bottom;

    if LCollapseMarkRect.Right > FLeftMarginWidth then
    begin
      if FCodeFolding.Hint.Indicator.Glyph.Visible then
        FCodeFolding.Hint.Indicator.Glyph.Draw(Canvas, LCollapseMarkRect.Left, ALineRect.Top, ALineRect.Height)
      else
      begin
        if FColors.Background <> FCodeFolding.Hint.Indicator.Colors.Background then
        begin
          Canvas.Brush.Color := FCodeFolding.Hint.Indicator.Colors.Background;
          FillRect(LCollapseMarkRect);
        end;

        if hioShowBorder in FCodeFolding.Hint.Indicator.Options then
        begin
          LBrush := TBrush.Create;
          try
            LBrush.Color := FCodeFolding.Hint.Indicator.Colors.Border;
            Winapi.Windows.FrameRect(Canvas.Handle, LCollapseMarkRect, LBrush.Handle);
          finally
            LBrush.Free;
          end;
        end;

        if hioShowMark in FCodeFolding.Hint.Indicator.Options then
        begin
          Canvas.Pen.Color := FCodeFolding.Hint.Indicator.Colors.Mark;
          Canvas.Brush.Color := FCodeFolding.Hint.Indicator.Colors.Mark;

          case FCodeFolding.Hint.Indicator.MarkStyle of
            imsThreeDots:
              begin
                { [...] }
                LDotSpace := (LCollapseMarkRect.Width - 8) div 4;
                LY := LCollapseMarkRect.Top + (LCollapseMarkRect.Bottom - LCollapseMarkRect.Top) div 2;
                LX := LCollapseMarkRect.Left + LDotSpace + (LCollapseMarkRect.Width - LDotSpace * 4 - 6) div 2;

                for LIndex := 1 to 3 do //FI:W528 Variable not used in FOR-loop
                begin
                  Canvas.Rectangle(LX, LY, LX + 2, LY + 2);
                  LX := LX + LDotSpace + 2;
                end;
              end;
            imsTriangle:
              begin
                LX := (LCollapseMarkRect.Width - LCollapseMarkRect.Height) div 2;
                LY := (LCollapseMarkRect.Width + 1) mod 2;
                LPoints[0] := Point(LCollapseMarkRect.Left + LX + 2, LCollapseMarkRect.Top + 2);
                LPoints[1] := Point(LCollapseMarkRect.Right - LX - 3 - LY, LCollapseMarkRect.Top + 2);
                LPoints[2] := Point(LCollapseMarkRect.Left + LCollapseMarkRect.Width div 2 - LY, LCollapseMarkRect.Bottom - 3);

                Canvas.Polygon(LPoints);
              end;
          end;
        end;
      end;
    end;
    Inc(LCollapseMarkRect.Left, FLeftMarginWidth);
    LCollapseMarkRect.Right := LCollapseMarkRect.Left + FCodeFolding.Hint.Indicator.Width;
    AFoldRange.CollapseMarkRect := LCollapseMarkRect;
  end;
  Canvas.Pen.Color := LOldPenColor;
  Canvas.Brush.Color := LOldBrushColor;
end;

procedure TCustomTextEditor.PaintGuides(const AFirstRow, ALastRow: Integer; const AMinimap: Boolean);
var
  LIndex, LRow, LRangeIndex: Integer;
  LX, LY, LZ: Integer;
  LLine, LCurrentLine: Integer;
  LOldColor: TColor;
  LDeepestLevel: Integer;
  LCodeFoldingRange, LCodeFoldingRangeTo: TTextEditorCodeFoldingRange;
  LIncY: Boolean;
  LTopLine, LBottomLine, LLineHeight: Integer;
  LCodeFoldingRanges: array of TTextEditorCodeFoldingRange;

  function GetDeepestLevel: Integer;
  var
    LTempLine: Integer;
  begin
    Result := 0;
    LTempLine := LCurrentLine;
    if LTempLine < Length(FCodeFoldings.RangeFromLine) then
    begin
      while LTempLine > 0 do
      begin
        LCodeFoldingRange := FCodeFoldings.RangeFromLine[LTempLine];
        LCodeFoldingRangeTo := FCodeFoldings.RangeToLine[LTempLine];

        if not Assigned(LCodeFoldingRange) and not Assigned(LCodeFoldingRangeTo) then
          Dec(LTempLine)
        else
        if Assigned(LCodeFoldingRange) and (LCurrentLine >= LCodeFoldingRange.FromLine) and
          (LCurrentLine <= LCodeFoldingRange.ToLine) then
          Break
        else
        if Assigned(LCodeFoldingRangeTo) and (LCurrentLine >= LCodeFoldingRangeTo.FromLine) and
          (LCurrentLine <= LCodeFoldingRangeTo.ToLine) then
        begin
          LCodeFoldingRange := LCodeFoldingRangeTo;

          Break
        end
        else
          Dec(LTempLine)
      end;
      if Assigned(LCodeFoldingRange) then
        Result := LCodeFoldingRange.IndentLevel;
    end;
  end;

begin
  LOldColor := Canvas.Pen.Color;

  LLineHeight := GetLineHeight;
  LY := 0;
  if FRuler.Visible then
    Inc(LY, FRuler.Height);

  LCurrentLine := GetViewTextLineNumber(FViewPosition.Row);
  LCodeFoldingRange := nil;

  LDeepestLevel := 0;
  if not FMinimap.Dragging then
    LDeepestLevel := GetDeepestLevel;

  LTopLine := GetViewTextLineNumber(AFirstRow);
  LBottomLine := GetViewTextLineNumber(ALastRow);

  SetLength(LCodeFoldingRanges, FCodeFoldings.AllRanges.AllCount);
  LRangeIndex := 0;
  for LIndex := 0 to FCodeFoldings.AllRanges.AllCount - 1 do
  begin
    LCodeFoldingRange := FCodeFoldings.AllRanges[LIndex];
    if Assigned(LCodeFoldingRange) then
    begin
      if (LCodeFoldingRange.ToLine < LTopLine) or (LCodeFoldingRange.FromLine > LBottomLine) then
        Continue;

      for LRow := AFirstRow to ALastRow do
      begin
        LLine := GetViewTextLineNumber(LRow);

        if not LCodeFoldingRange.Collapsed and not LCodeFoldingRange.ParentCollapsed and
          (LCodeFoldingRange.FromLine < LLine) and (LCodeFoldingRange.ToLine > LLine) then
        begin
          LCodeFoldingRanges[LRangeIndex] := LCodeFoldingRange;
          Inc(LRangeIndex);

          Break;
        end
      end;
    end;
  end;

  for LRow := AFirstRow to ALastRow do
  begin
    LLine := GetViewTextLineNumber(LRow);
    LIncY := Odd(LLineHeight) and not Odd(LRow);
    for LIndex := 0 to LRangeIndex - 1 do
    begin
      LCodeFoldingRange := LCodeFoldingRanges[LIndex];
      if Assigned(LCodeFoldingRange) then
        if not LCodeFoldingRange.Collapsed and not LCodeFoldingRange.ParentCollapsed and
          (LCodeFoldingRange.FromLine < LLine) and (LCodeFoldingRange.ToLine > LLine) then
        begin
          if Assigned(LCodeFoldingRange.RegionItem) and not LCodeFoldingRange.RegionItem.ShowGuideLine then
            Continue;

          LX := FLeftMarginWidth + GetLineIndentLevel(LCodeFoldingRange.ToLine - 1) * FPaintHelper.CharWidth;

          if not AMinimap then
            Dec(LX, FScrollHelper.HorizontalPosition);

          if not AMinimap and (LX - FLeftMarginWidth > 0) or AMinimap and (LX > 0) then
          begin
            if (LDeepestLevel = LCodeFoldingRange.IndentLevel) and (LCurrentLine >= LCodeFoldingRange.FromLine) and
              (LCurrentLine <= LCodeFoldingRange.ToLine) and (cfoHighlightIndentGuides in FCodeFolding.Options) then
            begin
              Canvas.Pen.Color := FCodeFolding.Colors.IndentHighlight;
              Canvas.MoveTo(LX, LY);
              Canvas.LineTo(LX, LY + LLineHeight);
            end
            else
            begin
              Canvas.Pen.Color := FCodeFolding.Colors.Indent;

              LZ := LY;
              case FCodeFolding.GuideLineStyle of
                lsDash:
                  begin
                    Inc(LZ, 3);
                    Canvas.MoveTo(LX, LZ);
                    Canvas.LineTo(LX, LZ + LLineHeight - 7);
                  end;
                lsDot:
                  begin
                    if LIncY then
                      Inc(LZ);
                    while LZ < LY + LLineHeight do
                    begin
                      Canvas.MoveTo(LX, LZ);
                      Inc(LZ);
                      Canvas.LineTo(LX, LZ);
                      Inc(LZ);
                    end;
                  end;
                lsSolid:
                  begin
                    Canvas.MoveTo(LX, LY);
                    Canvas.LineTo(LX, LY + LLineHeight);
                  end;
              end;
            end;
          end;
        end;
    end;
    Inc(LY, LLineHeight);
  end;
  SetLength(LCodeFoldingRanges, 0);

  Canvas.Pen.Color := LOldColor;
end;

procedure TCustomTextEditor.CreateBookmarkImages;
begin
  if not Assigned(FImagesBookmark) then
  begin
    FImagesBookmark := TTextEditorInternalImage.Create(HInstance, TResourceBitmap.BookmarkImages, TResourceBitmap.BookmarkImageCount);
{$IFDEF ALPHASKINS}
    FImagesBookmark.ChangeScale(SkinData.CommonSkinData.PPI, 96);
{$ENDIF}
  end;
end;

procedure TCustomTextEditor.PaintLeftMargin(const AClipRect: TRect; const AFirstLine, ALastTextLine, ALastLine: Integer);
var
  LLine, LPreviousLine: Integer;
  LLineRect: TRect;
  LLineHeight: Integer;

  procedure DrawBookmark(const ABookmark: TTextEditorMark; var AOverlappingOffset: Integer; const AMarkRow: Integer);
  var
    LY: Integer;
  begin
    CreateBookmarkImages;

    LY := (AMarkRow - TopLine) * LLineHeight;
    if FRuler.Visible then
      Inc(LY, FRuler.Height);

    FImagesBookmark.Draw(Canvas, ABookmark.ImageIndex, AClipRect.Left + FLeftMargin.Bookmarks.LeftMargin,
      LY, LLineHeight, clFuchsia);

    Inc(AOverlappingOffset, FLeftMargin.Marks.OverlappingOffset);
  end;

  procedure DrawMark(const AMark: TTextEditorMark; const AOverlappingOffset: Integer; const AMarkRow: Integer);
  var
    LY: Integer;
  begin
    if Assigned(FLeftMargin.Marks.Images) then
      if AMark.ImageIndex <= FLeftMargin.Marks.Images.Count then
      begin
        if LLineHeight > FLeftMargin.Marks.Images.Height then
          LY := LLineHeight shr 1 - FLeftMargin.Marks.Images.Height shr 1
        else
          LY := 0;

        if FRuler.Visible then
          Inc(LY, FRuler.Height);

        FLeftMargin.Marks.Images.Draw(Canvas, AClipRect.Left + FLeftMargin.Marks.LeftMargin + AOverlappingOffset,
          (AMarkRow - TopLine) * LLineHeight + LY, AMark.ImageIndex);
      end;
  end;

  procedure PaintLineNumbers;
  var
    LIndex, LTop: Integer;
    LLineNumber: string;
    LTextSize: TSize;
    LLeftMarginWidth: Integer;
    LOldColor, LBackground: TColor;
    LLastTextLine: Integer;
    LCaretY: Integer;
    LCompareMode, LCompareEmptyLine: Boolean;
    LLength: Integer;
    LPLineNumber: PChar;
    LMargin: Integer;
    LLongLineWidth, LShortLineWith: Integer;
  begin
    FPaintHelper.SetBaseFont(FLeftMargin.Font);
    try
      LLineRect := AClipRect;

      LLastTextLine := ALastTextLine;
      if lnoAfterLastLine in FLeftMargin.LineNumbers.Options then
        LLastTextLine := ALastLine;

      LCaretY := FPosition.Text.Line + 1;
      LCompareMode := lnoCompareMode in FLeftMargin.LineNumbers.Options;
      LCompareEmptyLine := False;
      LLeftMarginWidth := LLineRect.Left + FLeftMargin.GetWidth - FLeftMargin.LineState.Width - 1;
      LLongLineWidth := 0;
      LShortLineWith := 0;

      if lnoIntens in LeftMargin.LineNumbers.Options then
      begin
        LLongLineWidth := (FLeftMarginCharWidth - 9) div 2;
        LShortLineWith := (FLeftMarginCharWidth - 1) div 2;
      end;

      for LIndex := AFirstLine to LLastTextLine do
      begin
        LLine := GetViewTextLineNumber(LIndex);
        if LCompareMode and (FLines.Count > 0) then
          LCompareEmptyLine := sfEmptyLine in FLines.Items^[LIndex - 1].Flags;

        LLineRect.Top := (LIndex - TopLine) * LLineHeight;
        if FRuler.Visible then
          Inc(LLineRect.Top, FRuler.Height);
        LLineRect.Bottom := LLineRect.Top + LLineHeight;

        LLineNumber := '';

        FPaintHelper.SetBackgroundColor(FLeftMargin.Colors.Background);

        if FActiveLine.Visible and (not Assigned(FMultiCaret.Carets) and (LLine = LCaretY) or
          Assigned(FMultiCaret.Carets) and IsMultiEditCaretFound(LLine)) and (FLeftMargin.Colors.ActiveLineBackground <> TColors.SysNone) then
        begin
          if Focused then
          begin
            FPaintHelper.SetBackgroundColor(FLeftMargin.Colors.ActiveLineBackground);
            Canvas.Brush.Color := FLeftMargin.Colors.ActiveLineBackground;
          end
          else
          begin
            FPaintHelper.SetBackgroundColor(FLeftMargin.Colors.ActiveLineBackgroundUnfocused);
            Canvas.Brush.Color := FLeftMargin.Colors.ActiveLineBackgroundUnfocused;
          end;
          if Assigned(FMultiCaret.Carets) then
            FillRect(LLineRect);
        end
        else
        begin
          LBackground := GetMarkBackgroundColor(LIndex);
          if LBackground <> TColors.SysNone then
          begin
            FPaintHelper.SetBackgroundColor(LBackground);
            Canvas.Brush.Color := LBackground;
            FillRect(LLineRect);
          end
        end;

        if (LLine = LCaretY) and FActiveLine.Visible and (FActiveLine.Colors.Foreground <> TColors.SysNone) then
        begin
          if Focused then
          begin
            if FLeftMargin.Colors.ActiveLineNumber = TColors.SysNone then
              FPaintHelper.SetForegroundColor(FActiveLine.Colors.Foreground)
            else
              FPaintHelper.SetForegroundColor(FLeftMargin.Colors.ActiveLineNumber)
          end
          else
            FPaintHelper.SetForegroundColor(FActiveLine.Colors.ForegroundUnfocused)
        end
        else
        if (LLine = LCaretY) and (FLeftMargin.Colors.ActiveLineNumber <> TColors.SysNone) then
          FPaintHelper.SetForegroundColor(FLeftMargin.Colors.ActiveLineNumber)
        else
          FPaintHelper.SetForegroundColor(FLeftMargin.Font.Color);

        LPreviousLine := LLine;
        if FWordWrap.Active then
          LPreviousLine := GetViewTextLineNumber(LIndex - 1);

        LMargin := IfThen(FCodeFolding.Visible, 0, 2);

        if FLeftMargin.LineNumbers.Visible and not FWordWrap.Active and not LCompareEmptyLine or
          FWordWrap.Active and (LPreviousLine <> LLine) then
        begin
          LLineNumber := FLeftMargin.FormatLineNumber(LLine);
          if LCaretY <> LLine then
            if (lnoIntens in LeftMargin.LineNumbers.Options) and (LLineNumber[Length(LLineNumber)] <> '0') and
              (LIndex <> LeftMargin.LineNumbers.StartFrom) then
            begin
              LOldColor := Canvas.Pen.Color;
              Canvas.Pen.Color := LeftMargin.Colors.LineNumberLine;
              LTop := LLineRect.Top + (LLineHeight div 2);
              if LLine mod 5 = 0 then
                Canvas.MoveTo(LLeftMarginWidth - FLeftMarginCharWidth + LLongLineWidth - LMargin, LTop)
              else
                Canvas.MoveTo(LLeftMarginWidth - FLeftMarginCharWidth + LShortLineWith - LMargin, LTop);
              Canvas.LineTo(LLeftMarginWidth - LShortLineWith - LMargin, LTop);
              Canvas.Pen.Color := LOldColor;

              Continue;
            end;
        end;

        if not FLeftMargin.LineNumbers.Visible or LCompareEmptyLine then
          LLineNumber := ''
        else
        if LCompareMode then
          LLineNumber := FLeftMargin.FormatLineNumber(LLine - FCompareLineNumberOffsetCache[LIndex]);

        LLength := Length(LLineNumber);
        LPLineNumber := PChar(LLineNumber);
        GetTextExtentPoint32(Canvas.Handle, LPLineNumber, LLength, LTextSize);
        Winapi.Windows.ExtTextOut(Canvas.Handle, LLeftMarginWidth - 1 - LMargin - LTextSize.cx,
          LLineRect.Top + ((LLineHeight - Integer(LTextSize.cy)) div 2), ETO_OPAQUE, @LLineRect, LPLineNumber, LLength, nil);
      end;
      FPaintHelper.SetBackgroundColor(FLeftMargin.Colors.Background);
      { Erase the remaining area }
      if AClipRect.Bottom > LLineRect.Bottom then
      begin
        LLineRect.Top := LLineRect.Bottom;
        LLineRect.Bottom := AClipRect.Bottom;
        Winapi.Windows.ExtTextOut(Canvas.Handle, LLineRect.Left, LLineRect.Top, ETO_OPAQUE, @LLineRect, '', 0, nil);
      end;
    finally
      FPaintHelper.SetBaseFont(Font);
    end;
  end;

  procedure PaintBookmarkPanel;
  var
    LIndex: Integer;
    LPanelRect: TRect;
    LPanelActiveLineRect: TRect;
    LOldColor, LBackground: TColor;

    procedure SetPanelActiveLineRect;
    var
      LTop: Integer;
    begin
      LTop := (LIndex - TopLine) * LLineHeight;
      LPanelActiveLineRect := System.Types.Rect(AClipRect.Left, LTop, AClipRect.Left + FLeftMargin.MarksPanel.Width,
        LTop + LLineHeight);

      if FRuler.Visible then
      begin
        Inc(LPanelActiveLineRect.Top, FRuler.Height);
        Inc(LPanelActiveLineRect.Bottom, FRuler.Height);
      end;
    end;

  begin
    LOldColor := Canvas.Brush.Color;
    if FLeftMargin.MarksPanel.Visible then
    begin
      LPanelRect := System.Types.Rect(AClipRect.Left, 0, AClipRect.Left + FLeftMargin.MarksPanel.Width, ClientHeight);

      if FRuler.Visible then
        Inc(LPanelRect.Top, FRuler.Height);

      if FLeftMargin.Colors.BookmarkPanelBackground <> TColors.SysNone then
      begin
        Canvas.Brush.Color := FLeftMargin.Colors.BookmarkPanelBackground;
        FillRect(LPanelRect);
      end;

      for LIndex := AFirstLine to ALastTextLine do
      begin
        LLine := GetViewTextLineNumber(LIndex);

        if FActiveLine.Visible and (FLeftMargin.Colors.ActiveLineBackground <> TColors.SysNone) and
          not Assigned(FMultiCaret.Carets) and (LLine = FPosition.Text.Line + 1) or
          Assigned(FMultiCaret.Carets) and IsMultiEditCaretFound(LLine) then
        begin
          SetPanelActiveLineRect;

          if Focused then
            Canvas.Brush.Color := FLeftMargin.Colors.ActiveLineBackground
          else
            Canvas.Brush.Color := FLeftMargin.Colors.ActiveLineBackgroundUnfocused;

          FillRect(LPanelActiveLineRect);
        end
        else
        begin
          LBackground := GetMarkBackgroundColor(LIndex);
          if LBackground <> TColors.SysNone then
          begin
            SetPanelActiveLineRect;
            Canvas.Brush.Color := LBackground;
            FillRect(LPanelActiveLineRect);
          end
        end;
      end;
      if Assigned(FEvents.OnBeforeMarkPanelPaint) then
        FEvents.OnBeforeMarkPanelPaint(Self, Canvas, LPanelRect, AFirstLine, ALastLine);
    end;
    Canvas.Brush.Color := LOldColor;
  end;

  procedure PaintWordWrapIndicator;
  var
    LIndex, LY: Integer;
  begin
    if FWordWrap.Active and FWordWrap.Indicator.Visible then
    for LIndex := AFirstLine to ALastLine do
    begin
      LLine := GetViewTextLineNumber(LIndex);
      LPreviousLine := GetViewTextLineNumber(LIndex - 1);
      if LLine = LPreviousLine then
      begin
        LY := (LIndex - TopLine) * LLineHeight;
        if FRuler.Visible then
          Inc(LY, FRuler.Height);
        FWordWrap.Indicator.Draw(Canvas, AClipRect.Left + FWordWrap.Indicator.Left, LY, LLineHeight);
      end;
    end;
  end;

  procedure PaintBorder;
  var
    LRightPosition: Integer;
  begin
    LRightPosition := AClipRect.Left + FLeftMargin.GetWidth - 2;
    if (FLeftMargin.Border.Style <> mbsNone) and (AClipRect.Right >= LRightPosition) then
    with Canvas do
    begin
      Pen.Color := FLeftMargin.Colors.Border;
      Pen.Width := 1;
      if FLeftMargin.Border.Style = mbsMiddle then
      begin
        MoveTo(LRightPosition, AClipRect.Top);
        LineTo(LRightPosition, AClipRect.Bottom);
        Pen.Color := FLeftMargin.Colors.Background;
      end;
      MoveTo(LRightPosition + 1, AClipRect.Top);
      LineTo(LRightPosition + 1, AClipRect.Bottom);
    end;
  end;

  procedure PaintMarks;
  var
    LLine, LIndex: Integer;
    LOverlappingOffsets: PIntegerArray;
    LMark: TTextEditorMark;
    LMarkLine: Integer;
  begin
    if FLeftMargin.Bookmarks.Visible and FLeftMargin.Bookmarks.Visible and
      ((FBookmarkList.Count > 0) or (FMarkList.Count > 0)) and (ALastLine >= AFirstLine) then
    begin
      LOverlappingOffsets := AllocMem((ALastLine - AFirstLine + 1) * SizeOf(Integer));
      try
        for LLine := AFirstLine to ALastLine do
        begin
          LMarkLine := GetViewTextLineNumber(LLine);
          { Bookmarks }
          for LIndex := FBookmarkList.Count - 1 downto 0 do
          begin
            LMark := FBookmarkList.Items[LIndex];
            if LMark.Visible and (LMark.Line + 1 = LMarkLine) then
              DrawBookmark(LMark, LOverlappingOffsets[ALastLine - LLine], LMarkLine);
          end;
          { Custom marks }
          for LIndex := FMarkList.Count - 1 downto 0 do
          begin
            LMark := FMarkList.Items[LIndex];
            if LMark.Visible and (LMark.Line + 1 = LMarkLine) then
              DrawMark(LMark, LOverlappingOffsets[ALastLine - LLine], LMarkLine);
          end;
        end;
      finally
        FreeMem(LOverlappingOffsets);
      end;
    end;
  end;

  procedure PaintActiveLineIndicator;
  var
    LY: Integer;
  begin
    if FActiveLine.Visible and FActiveLine.Indicator.Visible then
    begin
      LY := (FViewPosition.Row - TopLine) * LLineHeight;
      if FRuler.Visible then
        Inc(LY, FRuler.Height);

      FActiveLine.Indicator.Draw(Canvas, AClipRect.Left + FActiveLine.Indicator.Left, LY, LLineHeight);
    end;
  end;

  procedure PaintSyncEditIndicator;
  var
    LViewPosition: TTextEditorViewPosition;
    LY: Integer;
  begin
    if not ReadOnly and FSyncEdit.Active and not FSyncEdit.Visible and FSyncEdit.Activator.Visible and GetSelectionAvailable then
    begin
      LViewPosition := TextToViewPosition(SelectionEndPosition);
      LY := (LViewPosition.Row - TopLine) * LLineHeight;

      if FRuler.Visible then
        Inc(LY, FRuler.Height);

      FSyncEdit.Activator.Draw(Canvas, AClipRect.Left + FActiveLine.Indicator.Left, LY, LLineHeight);
    end;
  end;

  procedure PaintLineState;
  var
    LLine, LTextLine: Integer;
    LLineStateRect: TRect;
    LOldColor: TColor;
    LLineState: TTextEditorLineState;
  begin
    if FLeftMargin.LineState.Visible then
    begin
      LOldColor := Canvas.Brush.Color;

      LLineStateRect.Left := AClipRect.Right - FLeftMargin.LineState.Width - 1;
      LLineStateRect.Right := AClipRect.Right - 1;
      for LLine := AFirstLine to ALastTextLine do
      begin
        LTextLine := GetViewTextLineNumber(LLine);
        LLineState := FLines.LineState[LTextLine - 1];
        if LLineState <> lsNone then
        begin
          LLineStateRect.Top := (LLine - TopLine) * LLineHeight;
          if FRuler.Visible then
            Inc(LLineStateRect.Top, FRuler.Height);
          LLineStateRect.Bottom := LLineStateRect.Top + LLineHeight;
          if LLineState = lsNormal then
            Canvas.Brush.Color := FLeftMargin.Colors.LineStateNormal
          else
            Canvas.Brush.Color := FLeftMargin.Colors.LineStateModified;
          FillRect(LLineStateRect);
        end;
      end;
      Canvas.Brush.Color := LOldColor;
    end;
  end;

  procedure PaintBookmarkPanelLine;
  var
    LLine, LTextLine: Integer;
    LPanelRect: TRect;
  begin
    if FLeftMargin.MarksPanel.Visible then
    begin
      if Assigned(FEvents.OnMarkPanelLinePaint) then
      begin
        LPanelRect.Left := AClipRect.Left;
        if FRuler.Visible then
          LPanelRect.Top := FRuler.Height;
        LPanelRect.Right := FLeftMargin.MarksPanel.Width;
        LPanelRect.Bottom := AClipRect.Bottom;
        for LLine := AFirstLine to ALastLine do
        begin
          LTextLine := LLine;
          if FCodeFolding.Visible then
            LTextLine := GetViewTextLineNumber(LLine);
          LLineRect.Left := LPanelRect.Left;
          LLineRect.Right := LPanelRect.Right;
          LLineRect.Top := (LLine - TopLine) * LLineHeight;
          if FRuler.Visible then
            Inc(LLineRect.Top, FRuler.Height);
          LLineRect.Bottom := LLineRect.Top + LLineHeight;
          FEvents.OnMarkPanelLinePaint(Self, Canvas, LLineRect, LTextLine);
        end;
      end;
      if Assigned(FEvents.OnAfterMarkPanelPaint) then
        FEvents.OnAfterMarkPanelPaint(Self, Canvas, LPanelRect, AFirstLine, ALastLine);
    end;
  end;

begin
  FPaintHelper.SetBackgroundColor(FLeftMargin.Colors.Background);
  Canvas.Brush.Color := FLeftMargin.Colors.Background;
  FillRect(AClipRect);

  LLineHeight := GetLineHeight;
  PaintLineNumbers;
  PaintBookmarkPanel;
  PaintBorder;
  PaintActiveLineIndicator;

  if not (csDesigning in ComponentState) then
  begin
    PaintWordWrapIndicator;
    PaintMarks;
    PaintSyncEditIndicator;
    PaintLineState;
  end;

  PaintBookmarkPanelLine;
end;

procedure TCustomTextEditor.PaintMinimapIndicator(const AClipRect: TRect);
var
  LTop: Integer;
begin
  with FMinimapHelper.Indicator.Bitmap do
  begin
    Height := 0;
    Canvas.Brush.Color := FMinimap.Colors.VisibleLines;
    Width := AClipRect.Width;
    Height := VisibleLineCount * FMinimap.CharHeight;
  end;

  FMinimapHelper.Indicator.BlendFunction.SourceConstantAlpha := FMinimap.Indicator.AlphaBlending;

  LTop := (FLineNumbers.TopLine - FMinimap.TopLine) * FMinimap.CharHeight;

  if ioInvertBlending in FMinimap.Indicator.Options then
  begin
    if LTop > 0 then
    with FMinimapHelper.Indicator.Bitmap do
    AlphaBlend(Self.Canvas.Handle, AClipRect.Left, 0, Width, LTop, Canvas.Handle, 0, 0, Width, Height,
      FMinimapHelper.Indicator.BlendFunction);

    with FMinimapHelper.Indicator.Bitmap do
    AlphaBlend(Self.Canvas.Handle, AClipRect.Left, LTop + Height, Width, AClipRect.Bottom, Canvas.Handle, 0, 0, Width,
      Height, FMinimapHelper.Indicator.BlendFunction);
  end
  else
  with FMinimapHelper.Indicator.Bitmap do
  AlphaBlend(Self.Canvas.Handle, AClipRect.Left, LTop, Width, Height, Canvas.Handle, 0, 0, Width, Height,
    FMinimapHelper.Indicator.BlendFunction);

  if ioShowBorder in FMinimap.Indicator.Options then
  begin
    Canvas.Pen.Color := FMinimap.Colors.VisibleLines;
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(Rect(AClipRect.Left, LTop, AClipRect.Right, LTop + FMinimapHelper.Indicator.Bitmap.Height));
  end;
end;

procedure TCustomTextEditor.PaintMinimapShadow(const ACanvas: TCanvas; const AClipRect: TRect);
var
  LLeft: Integer;
begin
  if FMinimapHelper.Shadow.Bitmap.Height <> AClipRect.Height then
    CreateShadowBitmap(AClipRect, FMinimapHelper.Shadow.Bitmap, FMinimapHelper.Shadow.AlphaArray,
      FMinimapHelper.Shadow.AlphaByteArray);

  LLeft := IfThen(FMinimap.Align = maLeft, AClipRect.Left, AClipRect.Right - FMinimapHelper.Shadow.Bitmap.Width);

  with FMinimapHelper.Shadow.Bitmap do
  AlphaBlend(ACanvas.Handle, LLeft, 0, Width, Height, Canvas.Handle, 0, 0, Width, Height, FMinimapHelper.Shadow.BlendFunction);
end;

procedure TCustomTextEditor.PaintMouseScrollPoint;
var
  LHalfWidth: Integer;
begin
  LHalfWidth := FScroll.Indicator.Width div 2;

  FScroll.Indicator.Draw(Canvas, FMouse.ScrollingPoint.X - LHalfWidth, FMouse.ScrollingPoint.Y - LHalfWidth);
end;

procedure TCustomTextEditor.PaintProgress(Sender: TObject);
begin
  Paint;
end;

procedure  TCustomTextEditor.PaintProgressBar;
var
  LTop, LRight: Integer;
begin
  Canvas.Brush.Color := FLeftMargin.Font.Color;
  Canvas.Pen.Color := FLeftMargin.Font.Color;
  LTop := ClientRect.Bottom - 14;
  LRight := Round((FLines.ProgressPosition / 100) * ClientRect.Width) - 8;
  Canvas.Rectangle(Rect(4, LTop, LRight, LTop + 8));
end;

procedure TCustomTextEditor.PaintRuler;
var
  LIndex: Integer;
  LCharWidth, LCharsInView: Integer;
  LNumbers: string;
  LLeft, LLineY, LLongLineY, LShortLineY: Integer;
  LClipRect, LRect: TRect;
  LOldColor, LOldPenColor: TColor;
  LRulerCaretPosition: Integer;
  LWidth: Integer;
begin
  LClipRect := ClientRect;
  LClipRect.Bottom := FRuler.Height - 1;

  LCharWidth := FPaintHelper.CharWidth;

  LOldColor := Canvas.Brush.Color;
  LOldPenColor := Canvas.Pen.Color;
  Canvas.Brush.Color := FRuler.Colors.Background;

  FPaintHelper.SetBaseFont(FRuler.Font);
  FPaintHelper.SetBackgroundColor(Canvas.Brush.Color);
  FPaintHelper.SetForegroundColor(FRuler.Font.Color);

  LRulerCaretPosition := FLeftMarginWidth + (FViewPosition.Column - 1) * LCharWidth - FScrollHelper.HorizontalPosition;
  try
    FillRect(LClipRect);
    with Canvas do
    begin
      Pen.Color := FRuler.Colors.Border;
      Pen.Width := 1;
      MoveTo(0, LClipRect.Bottom);
      LineTo(LClipRect.Right, LClipRect.Bottom);

      LCharsInView := FScrollHelper.HorizontalPosition div LCharWidth;

      if (roShowSelection in FRuler.Options) and SelectionAvailable then
      begin
        LRect := LClipRect;
        LRect.Left := FLeftMarginWidth + (FPosition.BeginSelection.Char - 1) * LCharWidth - FScrollHelper.HorizontalPosition;
        LRect.Right := LRulerCaretPosition;
        Canvas.Brush.Color := FRuler.Colors.Selection;
        FPaintHelper.SetBackgroundColor(Canvas.Brush.Color);
        FillRect(LRect);
        Canvas.Brush.Color := FRuler.Colors.Background;
        FPaintHelper.SetBackgroundColor(Canvas.Brush.Color);
        Pen.Color := FSelection.Colors.Background;
        MoveTo(LRect.Left, 0);
        LineTo(LRect.Left, LClipRect.Bottom);
      end;

      LLeft := FLeftMarginWidth - FScrollHelper.HorizontalPosition mod LCharWidth;
      LLongLineY := LClipRect.Bottom - 4;
      LShortLineY := LClipRect.Bottom - 2;
      LRect := LClipRect;
      Dec(LRect.Bottom, 4);

      SetBkMode(Canvas.Handle, TRANSPARENT);

      Pen.Color := FRuler.Colors.Lines;

      for LIndex := LCharsInView to FScrollHelper.PageWidth div LCharWidth + LCharsInView + 10 do
      begin
        if LIndex mod 10 = 0 then
        begin
          LLineY := LLongLineY;

          LNumbers := IntToStr(LIndex);
          LRect.Left := LLeft;
          LRect.Right := LLeft + Length(LNumbers) * FPaintHelper.CharWidth;
          LWidth := LRect.Width div 2;
          Dec(LRect.Left, LWidth);
          Dec(LRect.Right, LWidth);

          Winapi.Windows.ExtTextOut(Handle, LLeft - LWidth, LRect.Top, 0, @LRect, PChar(LNumbers),
            Length(LNumbers), nil);
        end
        else
          LLineY := LShortLineY;

        MoveTo(LLeft, LLineY);
        LineTo(LLeft, LClipRect.Bottom);

        Inc(LLeft, LCharWidth);
      end;

      MoveTo(LRulerCaretPosition, 0);
      LineTo(LRulerCaretPosition, LClipRect.Bottom);
    end;
  finally
    Canvas.Brush.Color := LOldColor;
    Canvas.Pen.Color := LOldPenColor;
    FPaintHelper.SetBaseFont(Font);
  end;
end;

procedure TCustomTextEditor.PaintRightMargin(const AClipRect: TRect);
var
  LRightMarginPosition, LY: Integer;
begin
  if FRightMargin.Visible then
  begin
    LRightMarginPosition := FLeftMarginWidth + FRightMargin.Position * FPaintHelper.CharWidth -
      FScrollHelper.HorizontalPosition;
    if (LRightMarginPosition >= AClipRect.Left) and (LRightMarginPosition <= AClipRect.Right) then
    begin
      Canvas.Pen.Color := FRightMargin.Colors.Margin;
      LY := 0;
      if FRuler.Visible then
        Inc(LY, FRuler.Height);
      Canvas.MoveTo(LRightMarginPosition, LY);
      Canvas.LineTo(LRightMarginPosition, ClientHeight);
    end;
  end;
end;

procedure TCustomTextEditor.PaintRightMarginMove;
var
  LOldPenStyle: TPenStyle;
  LOldStyle: TBrushStyle;
  LY: Integer;
begin
  with Canvas do
  begin
    Pen.Width := 1;
    LOldPenStyle := Pen.Style;
    Pen.Style := psDot;
    Pen.Color := FRightMargin.Colors.MovingEdge;
    LOldStyle := Brush.Style;
    Brush.Style := bsClear;
    LY := 0;
    if FRuler.Visible then
      Inc(LY, FRuler.Height);
    MoveTo(FRightMarginMovePosition, LY);
    LineTo(FRightMarginMovePosition, ClientHeight);
    Brush.Style := LOldStyle;
    Pen.Style := LOldPenStyle;
  end;
end;

procedure TCustomTextEditor.PaintRulerMove;
var
  LOldPenStyle: TPenStyle;
  LOldStyle: TBrushStyle;
  LY: Integer;
begin
  with Canvas do
  begin
    Pen.Width := 1;
    LOldPenStyle := Pen.Style;
    Pen.Style := psDot;
    Pen.Color := FRuler.Colors.MovingEdge;
    LOldStyle := Brush.Style;
    Brush.Style := bsClear;
    LY := 0;
    if FRuler.Visible then
      Inc(LY, FRuler.Height);
    MoveTo(FRulerMovePosition, LY);
    LineTo(FRulerMovePosition, ClientHeight);
    Brush.Style := LOldStyle;
    Pen.Style := LOldPenStyle;
  end;
end;

procedure TCustomTextEditor.PaintScrollShadow(const ACanvas: TCanvas; const AClipRect: TRect);
begin
  if FScrollHelper.Shadow.Bitmap.Height <> AClipRect.Height then
    CreateShadowBitmap(AClipRect, FScrollHelper.Shadow.Bitmap, FScrollHelper.Shadow.AlphaArray, FScrollHelper.Shadow.AlphaByteArray);

  with FScrollHelper.Shadow.Bitmap do
  AlphaBlend(ACanvas.Handle, AClipRect.Left, AClipRect.Top, Width, Height, Canvas.Handle, 0, 0, Width, Height,
    FScrollHelper.Shadow.BlendFunction);
end;

procedure TCustomTextEditor.PaintSearchMap(const AClipRect: TRect);
var
  LIndex, LLine: Integer;
  LHeight: Double;
  LRect: TRect;
begin
  if not Assigned(FSearch.Items) or not Assigned(FSearchEngine) or
   (FSearchEngine.ResultCount = 0) and not (soHighlightSimilarTerms in FSelection.Options) then
    Exit;

  LRect := AClipRect;

  { Background }
  if FSearch.Map.Colors.Background <> TColors.SysNone then
    Canvas.Brush.Color := FSearch.Map.Colors.Background
  else
    Canvas.Brush.Color := FColors.Background;
  FillRect(LRect);
  { Lines in window }
  LHeight := ClientHeight / Max(FLines.Count, 1);
  LRect.Top := Round((TopLine - 1) * LHeight);
  LRect.Bottom := Max(Round((TopLine - 1 + VisibleLineCount) * LHeight), LRect.Top + 1);
  Canvas.Brush.Color := FColors.Background;
  FillRect(LRect);
  { Draw lines }
  if FSearch.Map.Colors.Foreground <> TColors.SysNone then
    Canvas.Pen.Color := FSearch.Map.Colors.Foreground
  else
    Canvas.Pen.Color := clHighlight;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Style := psSolid;
  for LIndex := 0 to FSearch.Items.Count - 1 do
  begin
    LLine := Round(PTextEditorSearchItem(FSearch.Items.Items[LIndex])^.BeginTextPosition.Line * LHeight);
    Canvas.MoveTo(LRect.Left, LLine);
    Canvas.LineTo(LRect.Right, LLine);
    Canvas.MoveTo(LRect.Left, LLine + 1);
    Canvas.LineTo(LRect.Right, LLine + 1);
  end;
  { Draw active line }
  if moShowActiveLine in FSearch.Map.Options then
  begin
    if FSearch.Map.Colors.ActiveLine <> TColors.SysNone then
      Canvas.Pen.Color := FSearch.Map.Colors.ActiveLine
    else
      Canvas.Pen.Color := FActiveLine.Colors.Background;
    LLine := Round((FViewPosition.Row - 1) * LHeight);
    Canvas.MoveTo(LRect.Left, LLine);
    Canvas.LineTo(LRect.Right, LLine);
    Canvas.MoveTo(LRect.Left, LLine + 1);
    Canvas.LineTo(LRect.Right, LLine + 1);
  end;
end;

procedure TCustomTextEditor.SetOppositeColors;
begin
  FPaintHelper.SetBackgroundColor(Canvas.Pen.Color);
  FPaintHelper.SetForegroundColor(Canvas.Brush.Color);
  FPaintHelper.SetStyle([]);
end;

procedure TCustomTextEditor.PaintSpecialCharsEndOfLine(const ALine: Integer; const ALineEndRect: TRect;
  const ALineEndInsideSelection: Boolean);
var
  LY: Integer;
  LCharRect: TRect;
  LPilcrow: string;
  LPenColor: TColor;
begin
  if FSpecialChars.Visible then
  begin
    if (ALineEndRect.Left < 0) or (ALineEndRect.Left > ClientRect.Right) then
      Exit;

    if FSpecialChars.Selection.Visible and ALineEndInsideSelection or
      not ALineEndInsideSelection and not (scoShowOnlyInSelection in FSpecialChars.Options) then
    begin
      if FSpecialChars.Selection.Visible and ALineEndInsideSelection then
        LPenColor := FSpecialChars.Selection.Color
      else
      if FSpecialChars.LineBreak.Color <> TColors.SysNone then
        LPenColor := FSpecialChars.LineBreak.Color
      else
      if scoMiddleColor in FSpecialChars.Options then
        LPenColor := MiddleColor(FHighlighter.MainRules.Attribute.Background,
          FHighlighter.MainRules.Attribute.Foreground)
      else
      if scoTextColor in FSpecialChars.Options then
        LPenColor := FHighlighter.MainRules.Attribute.Foreground
      else
        LPenColor := FSpecialChars.Color;

      Canvas.Pen.Color := LPenColor;

      if FSpecialChars.LineBreak.Visible and ((eoTrailingLineBreak in FOptions) or (ALine < FLines.Count)) then
      with Canvas do
      begin
        Pen.Color := LPenColor;

        LCharRect.Top := ALineEndRect.Top;
        if (FSpecialChars.LineBreak.Style = eolPilcrow) or (FSpecialChars.LineBreak.Style = eolCRLF) then
          LCharRect.Bottom := ALineEndRect.Bottom
        else
          LCharRect.Bottom := ALineEndRect.Bottom - 3;
        LCharRect.Left := ALineEndRect.Left;

        if FSpecialChars.LineBreak.Style = eolEnter then
          LCharRect.Left := LCharRect.Left + 4;

        if (FSpecialChars.LineBreak.Style = eolPilcrow) or (FSpecialChars.LineBreak.Style = eolCRLF) then
        begin
          LCharRect.Left := LCharRect.Left + 2;
          LCharRect.Right := LCharRect.Left + FPaintHelper.CharWidth
        end
        else
          LCharRect.Right := LCharRect.Left + FTabs.Width * FPaintHelper.CharWidth - 3;

        if FSpecialChars.LineBreak.Style = eolCRLF then
        begin
          SetOppositeColors;

          LPilcrow := '';

          with FLines.Items^[ALine - 1] do
          begin
            if sfLineBreakCR in Flags then
              LPilcrow := TControlCharacters.Names.CarriageReturn;

            if sfLineBreakLF in Flags then
              LPilcrow := LPilcrow + TControlCharacters.Names.LineFeed;
          end;

          if LPilcrow = '' then
            if FLines.LineBreak = lbCRLF then
              LPilcrow := TControlCharacters.Names.CarriageReturn + TControlCharacters.Names.LineFeed
            else
            if FLines.LineBreak = lbLF then
              LPilcrow := TControlCharacters.Names.LineFeed
            else
              LPilcrow := TControlCharacters.Names.CarriageReturn;

          LCharRect.Width := LCharRect.Width * Length(LPilcrow) + 2;
          LCharRect.Top := LCharRect.Top + 2;
          LCharRect.Bottom := LCharRect.Bottom - 2;

          SetBkMode(Canvas.Handle, TRANSPARENT);
          Winapi.Windows.ExtTextOut(Canvas.Handle, LCharRect.Left + 1, LCharRect.Top - 2, ETO_OPAQUE or ETO_CLIPPED,
            @LCharRect, PChar(LPilcrow), Length(LPilcrow), nil);
        end
        else
        if FSpecialChars.LineBreak.Style = eolPilcrow then
        begin
          FPaintHelper.SetForegroundColor(Canvas.Pen.Color);
          FPaintHelper.SetStyle([]);
          LPilcrow := TCharacters.Pilcrow;
          SetBkMode(Canvas.Handle, TRANSPARENT);
          Winapi.Windows.ExtTextOut(Canvas.Handle, LCharRect.Left, LCharRect.Top, ETO_OPAQUE or ETO_CLIPPED,
            @LCharRect, PChar(LPilcrow), 1, nil);
        end
        else
        if FSpecialChars.LineBreak.Style = eolArrow then
        begin
          LY := LCharRect.Top + 2;
          if FSpecialChars.Style = scsDot then
          while LY < LCharRect.Bottom do
          begin
            MoveTo(LCharRect.Left + 6, LY);
            LineTo(LCharRect.Left + 6, LY + 1);
            Inc(LY, 2);
          end;
          { Solid }
          if FSpecialChars.Style = scsSolid then
          begin
            MoveTo(LCharRect.Left + 6, LY);
            LY := LCharRect.Bottom;
            LineTo(LCharRect.Left + 6, LY + 1);
          end;
          MoveTo(LCharRect.Left + 6, LY);
          LineTo(LCharRect.Left + 3, LY - 3);
          MoveTo(LCharRect.Left + 6, LY);
          LineTo(LCharRect.Left + 9, LY - 3);
        end
        else
        begin
          LY := LCharRect.Top + GetLineHeight div 2;
          MoveTo(LCharRect.Left, LY);
          LineTo(LCharRect.Left + 11, LY);
          MoveTo(LCharRect.Left + 1, LY - 1);
          LineTo(LCharRect.Left + 1, LY + 2);
          MoveTo(LCharRect.Left + 2, LY - 2);
          LineTo(LCharRect.Left + 2, LY + 3);
          MoveTo(LCharRect.Left + 3, LY - 3);
          LineTo(LCharRect.Left + 3, LY + 4);
          MoveTo(LCharRect.Left + 10, LY - 3);
          LineTo(LCharRect.Left + 10, LY);
        end;
      end;
    end;
  end;
end;

procedure TCustomTextEditor.PaintSyncItems;
var
  LIndex: Integer;
  LTextPosition: TTextEditorTextPosition;
  LLength: Integer;
  LOldPenColor: TColor;
  LOldBrushStyle: TBrushStyle;

  procedure DrawRectangle(const ATextPosition: TTextEditorTextPosition);
  var
    LRect: TRect;
    LViewPosition: TTextEditorViewPosition;
  begin
    LRect.Top := (ATextPosition.Line - TopLine + 1) * LineHeight;
    if FRuler.Visible then
      Inc(LRect.Top, FRuler.Height);
    LRect.Bottom := LRect.Top + LineHeight;
    LViewPosition := TextToViewPosition(ATextPosition);
    LRect.Left := ViewPositionToPixels(LViewPosition).X;
    Inc(LViewPosition.Column, LLength);
    LRect.Right := ViewPositionToPixels(LViewPosition).X;
    Canvas.Rectangle(LRect);
  end;

begin
  if not Assigned(FSyncEdit.SyncItems) then
    Exit;

  LLength := FSyncEdit.EditEndPosition.Char - FSyncEdit.EditBeginPosition.Char;

  LOldPenColor := Canvas.Pen.Color;
  LOldBrushStyle := Canvas.Brush.Style;
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := FSyncEdit.Colors.EditBorder;
  DrawRectangle(FSyncEdit.EditBeginPosition);

  for LIndex := 0 to FSyncEdit.SyncItems.Count - 1 do
  begin
    LTextPosition := PTextEditorTextPosition(FSyncEdit.SyncItems.Items[LIndex])^;

    if LTextPosition.Line + 1 > TopLine + VisibleLineCount then
      Exit
    else
    if LTextPosition.Line + 1 >= TopLine then
    begin
      Canvas.Pen.Color := FSyncEdit.Colors.WordBorder;
      DrawRectangle(LTextPosition);
    end;
  end;
  Canvas.Pen.Color := LOldPenColor;
  Canvas.Brush.Style := LOldBrushStyle;
end;

procedure TCustomTextEditor.PaintTextLines(const AClipRect: TRect; const AFirstLine, ALastLine: Integer; const AMinimap: Boolean);
var
  LAnySelection: Boolean;
  LViewLine, LCurrentLine: Integer;
  LForegroundColor, LBackgroundColor, LBorderColor: TColor;
  LIsSelectionInsideLine: Boolean;
  LIsLineSelected, LIsCurrentLine, LIsSyncEditBlock, LIsSearchInSelectionBlock: Boolean;
  LLineRect, LTokenRect: TRect;
  LLineSelectionStart, LLineSelectionEnd: Integer;
  LSelectionEndPosition: TTextEditorTextPosition;
  LSelectionBeginPosition: TTextEditorTextPosition;
  LTokenHelper: TTextEditorTokenHelper;
  LCustomLineColors: Boolean;
  LCustomForegroundColor: TColor;
  LCustomBackgroundColor: TColor;
  LBookmarkOnCurrentLine: Boolean;
  LCurrentLineText: string;
  LCurrentLineLength: Integer;
  LPaintedColumn: Integer;
  LPaintedWidth: Integer;
  LBackgroundColorRed, LBackgroundColorGreen, LBackgroundColorBlue: Byte;
  LLineEndRect: TRect;
  LCurrentSearchIndex: Integer;
  LTextPosition: TTextEditorTextPosition;
  LWrappedRowCount: Integer;
  LExpandedCharsBefore: Integer;
  LAddWrappedCount: Boolean;
  LMarkColor: TColor;
  LLineHeight: Integer;
  LSelectedRect: TRect;
{$IFDEF TEXT_EDITOR_SPELL_CHECK}
  LCurrentSpellCheckIndex: Integer;
  LSpellCheckTextPosition: TTextEditorTextPosition;
{$ENDIF}

  function IsBookmarkOnCurrentLine: Boolean;
  var
    LIndex: Integer;
  begin
    Result := True;

    for LIndex := 0 to FBookmarkList.Count - 1 do
    if FBookmarkList.Items[LIndex].Line = LCurrentLine then
      Exit;

    Result := False;
  end;

  function GetBackgroundColor: TColor;
  var
    LHighlighterAttribute: TTextEditorHighlighterAttribute;
  begin
    if AMinimap and (moShowBookmarks in FMinimap.Options) and LBookmarkOnCurrentLine then
      Result := FMinimap.Colors.Bookmark
    else
    if LIsCurrentLine and FActiveLine.Visible and Focused and (FActiveLine.Colors.Background <> TColors.SysNone) then
      Result := FActiveLine.Colors.Background
    else
    if LIsCurrentLine and FActiveLine.Visible and not Focused and (FActiveLine.Colors.BackgroundUnfocused <> TColors.SysNone) then
      Result := FActiveLine.Colors.BackgroundUnfocused
    else
    if LMarkColor <> TColors.SysNone then
      Result := LMarkColor
    else
    if LIsSyncEditBlock then
      Result := FSyncEdit.Colors.Background
    else
    if LIsSearchInSelectionBlock then
      Result := FSearch.InSelection.Background
    else
    if AMinimap and (FMinimap.Colors.Background <> TColors.SysNone) then
      Result := FMinimap.Colors.Background
    else
    begin
      Result := FColors.Background;
      if Assigned(FHighlighter) then
      begin
        LHighlighterAttribute := FHighlighter.RangeAttribute;
        if Assigned(LHighlighterAttribute) and (LHighlighterAttribute.Background <> TColors.SysNone) then
          Result := LHighlighterAttribute.Background;
      end;
    end;
  end;

  procedure SetDrawingColors(const ASelected: Boolean);
  var
    LColor: TColor;
  begin
    { Selection colors }
    if AMinimap and (moShowBookmarks in FMinimap.Options) and LBookmarkOnCurrentLine then
      LColor := FMinimap.Colors.Bookmark
    else
    if ASelected then
    begin
      if FSelection.Colors.Foreground <> TColors.SysNone then
        FPaintHelper.SetForegroundColor(FSelection.Colors.Foreground)
      else
        FPaintHelper.SetForegroundColor(LForegroundColor);
      LColor := FSelection.Colors.Background;
    end
    { Normal colors }
    else
    begin
      FPaintHelper.SetForegroundColor(LForegroundColor);
      LColor := LBackgroundColor;
    end;

    FPaintHelper.SetBackgroundColor(LColor); { Text }
    Canvas.Brush.Color := LColor; { Rest of the line }
    LBackgroundColorRed := LColor and $FF;
    LBackgroundColorGreen := (LColor shr 8) and $FF;
    LBackgroundColorBlue := (LColor shr 16) and $FF;
  end;

  procedure PaintSearchResults(const AText: string; const ATextRect: TRect);
  var
    LSearchRect: TRect;
    LOldColor, LOldBackgroundColor: TColor;
    LIsTextPositionInSelection: Boolean;
    LSearchItem: TTextEditorSearchItem;
    LToken: string;
    LSearchTextLength, LCharCount, LBeginTextPositionChar: Integer;

    function GetSearchTextLength: Integer;
    begin
      if (LCurrentLine = LSearchItem.BeginTextPosition.Line) and
        (LSearchItem.BeginTextPosition.Line = LSearchItem.EndTextPosition.Line) then
        Result := LSearchItem.EndTextPosition.Char - LSearchItem.BeginTextPosition.Char
      else
      if (LCurrentLine > LSearchItem.BeginTextPosition.Line) and (LCurrentLine < LSearchItem.EndTextPosition.Line) then
        Result := LCurrentLineLength
      else
      if (LCurrentLine = LSearchItem.BeginTextPosition.Line) and (LCurrentLine < LSearchItem.EndTextPosition.Line) then
        Result := LCurrentLineLength - LSearchItem.BeginTextPosition.Char + 1
      else
      if (LCurrentLine > LSearchItem.BeginTextPosition.Line) and (LCurrentLine = LSearchItem.EndTextPosition.Line) then
        Result := LSearchItem.EndTextPosition.Char - 1
      else
        Result := 0;
    end;

    function NextItem: Boolean;
    begin
      Result := True;
      Inc(LCurrentSearchIndex);
      if LCurrentSearchIndex < FSearch.Items.Count then
        LSearchItem := PTextEditorSearchItem(FSearch.Items.Items[LCurrentSearchIndex])^
      else
      begin
        LCurrentSearchIndex := -1;
        Result := False;
      end;
    end;

  begin
    if soHighlightResults in FSearch.Options then
      if LCurrentSearchIndex <> -1 then
      begin
        LSearchItem := PTextEditorSearchItem(FSearch.Items.Items[LCurrentSearchIndex])^;

        while (LCurrentSearchIndex < FSearch.Items.Count) and (LSearchItem.EndTextPosition.Line < LCurrentLine) do
        begin
          Inc(LCurrentSearchIndex);
          if LCurrentSearchIndex < FSearch.Items.Count then
            LSearchItem := PTextEditorSearchItem(FSearch.Items.Items[LCurrentSearchIndex])^;
        end;

        if LCurrentSearchIndex = FSearch.Items.Count then
        begin
          LCurrentSearchIndex := -1;
          Exit;
        end;

        if LCurrentLine < LSearchItem.BeginTextPosition.Line then
          Exit;

        LOldColor := FPaintHelper.Color;
        LOldBackgroundColor := FPaintHelper.BackgroundColor;

        if FSearch.Highlighter.Colors.Foreground <> TColors.SysNone then
          FPaintHelper.SetForegroundColor(FSearch.Highlighter.Colors.Foreground);
        FPaintHelper.SetBackgroundColor(FSearch.Highlighter.Colors.Background);

        while True do
        begin
          LSearchTextLength := GetSearchTextLength;
          if LSearchTextLength = 0 then
            Break;

          if FSearch.InSelection.Active then
          begin
            LIsTextPositionInSelection := IsTextPositionInSearchBlock(LSearchItem.BeginTextPosition);
            if LIsTextPositionInSelection then
              LIsTextPositionInSelection := not IsTextPositionInSelection(LSearchItem.BeginTextPosition);
          end
          else
            LIsTextPositionInSelection := IsTextPositionInSelection(LSearchItem.BeginTextPosition) and
              IsTextPositionInSelection(LSearchItem.EndTextPosition);

          if not FSearch.InSelection.Active and LIsTextPositionInSelection or
            FSearch.InSelection.Active and not LIsTextPositionInSelection then
          begin
            if not NextItem then
              Break;
            Continue;
          end;

          LToken := AText;
          LSearchRect := ATextRect;

          if LSearchItem.BeginTextPosition.Line < LCurrentLine then
            LBeginTextPositionChar := 1
          else
            LBeginTextPositionChar := LSearchItem.BeginTextPosition.Char;

          LCharCount := LBeginTextPositionChar - LTokenHelper.CharsBefore - 1;

          if LCharCount > 0 then
          begin
            LToken := Copy(AText, 1, LCharCount);
            Inc(LSearchRect.Left, GetTokenWidth(LToken, LCharCount, LPaintedColumn, AMinimap));
            LToken := Copy(AText, LCharCount + 1, Length(AText));
          end
          else
            LCharCount := LTokenHelper.Length - Length(AText);

          LToken := Copy(LToken, 1, Min(LSearchTextLength, LBeginTextPositionChar + LSearchTextLength -
            LTokenHelper.CharsBefore - LCharCount - 1));
          LSearchRect.Right := LSearchRect.Left + GetTokenWidth(LToken, Length(LToken), LPaintedColumn, AMinimap);
          if SameText(AText, LToken) then
            Inc(LSearchRect.Right, FItalic.Offset);

          if LToken <> '' then
            Winapi.Windows.ExtTextOut(Canvas.Handle, LSearchRect.Left, LSearchRect.Top, ETO_OPAQUE or ETO_CLIPPED,
              @LSearchRect, PChar(LToken), Length(LToken), nil);

          if LBeginTextPositionChar + LSearchTextLength > LCurrentLineLength then
            Break
          else
          if LBeginTextPositionChar + LSearchTextLength > LTokenHelper.CharsBefore + Length(LToken) + LCharCount + 1 then
            Break
          else
          if LBeginTextPositionChar + LSearchTextLength - 1 <= LCurrentLineLength then
          begin
            if not NextItem then
              Break;
          end
          else
            Break;
        end;

        FPaintHelper.SetForegroundColor(LOldColor);
        FPaintHelper.SetBackgroundColor(LOldBackgroundColor);
      end;
  end;

  procedure PaintToken(const AToken: string; const ATokenLength: Integer; const ASelectedRectPaint: Boolean = False);
  var
    LText: string;
    LPChar: PChar;
    LOldPenColor: TColor;
    LTextRect: TRect;
    LLeft, LTop, LBottom, LMaxX, LOrigMaxX: Integer;
    LTokenLength: Integer;
    LLastColumn: Integer;
    LStep: Integer;
    LLastChar: Char;
    LAnsiChar: AnsiChar;
    LPixels: PRGBTripleArray;
    LTriple: TRGBTriple;
    LLeftStart: Byte;
    LTempBitmap: Vcl.Graphics.TBitmap;
    LTempRect: TRect;

    procedure PaintControlCharacters;
    var
      LIndex: Integer;
      LRect: TRect;
      LCharWidth: Integer;
      LName: string;
    begin
      if (LTokenLength = 0) or (Length(AToken) = 0) then
        Exit;

      SetOppositeColors;

      LRect := LTokenRect;
      LRect.Left := LRect.Left + 1;
      LRect.Top := LRect.Top + 1;
      LRect.Bottom := LRect.Bottom - 1;
      LCharWidth := LTextRect.Width div LTokenLength;
      LRect.Right := LRect.Left + LCharWidth - 1;
      SetBkMode(Canvas.Handle, TRANSPARENT);

      LName := ControlCharacterToName(AToken[1]);

      for LIndex := 0 to LTokenLength - 1 do //FI:W528 Variable not used in FOR-loop
      begin
        Winapi.Windows.ExtTextOut(Canvas.Handle, LRect.Left + 1, LRect.Top - 1, ETO_OPAQUE or ETO_CLIPPED, @LRect, PChar(LName),
          Length(LName), nil);

        Inc(LRect.Left, LCharWidth);
        LRect.Right := LRect.Left + LCharWidth - 1;
      end;
    end;

    procedure PaintSpecialCharSpace;
    var
      LIndex: Integer;
      LSpaceWidth: Integer;
      LRect: TRect;
    begin
      if LTokenLength = 0 then
        Exit;

      LSpaceWidth := LTextRect.Width div LTokenLength;
      LRect.Top := LTokenRect.Top + LTokenRect.Height div 2;
      LRect.Bottom := LRect.Top + 2;
      LRect.Left := LTextRect.Left + LSpaceWidth div 2;

      for LIndex := 0 to LTokenLength - 1 do //FI:W528 Variable not used in FOR-loop
      begin
        LRect.Right := LRect.Left + 2;
        Canvas.Rectangle(LRect);
        Inc(LRect.Left, LSpaceWidth);
      end;
    end;

    procedure PaintSpecialCharSpaceTab;
    var
      LLeft, LTop, LTopShr1: Integer;
      LRect: TRect;
      LTabWidth: Integer;
    begin
      LTabWidth := FTabs.Width * FPaintHelper.CharWidth;
      LRect := LTokenRect;
      LRect.Right := LTextRect.Left;

      Inc(LRect.Right, LTabWidth);
      if FLines.Columns then
        Dec(LRect.Right, FPaintHelper.CharWidth * (LTokenHelper.ExpandedCharsBefore mod FTabs.Width));

      while LRect.Right <= LTokenRect.Right do
      with Canvas do
      begin
        LTop := (LRect.Bottom - LRect.Top) shr 1;
        { Line }
        if FSpecialChars.Style = scsDot then
        begin
          LLeft := LRect.Left;
          Inc(LLeft);
          if Odd(LLeft) then
            Inc(LLeft);

          while LLeft < LRect.Right - 2 do
          begin
            MoveTo(LLeft, LRect.Top + LTop);
            LineTo(LLeft + 1, LRect.Top + LTop);
            Inc(LLeft, 2);
          end;
        end
        else
        if FSpecialChars.Style = scsSolid then
        begin
          MoveTo(LRect.Left + 2, LRect.Top + LTop);
          LineTo(LRect.Right - 2, LRect.Top + LTop);
        end;
        { Arrow }
        LLeft := LRect.Right - 2;
        LTopShr1 := LTop shr 1;

        MoveTo(LLeft, LRect.Top + LTop);
        LineTo(LLeft - LTopShr1, LRect.Top + LTop - LTopShr1);
        MoveTo(LLeft, LRect.Top + LTop);
        LineTo(LLeft - LTopShr1, LRect.Top + LTop + LTopShr1);

        LRect.Left := LRect.Right;
        Inc(LRect.Right, LTabWidth);
      end;
    end;

  begin
    LLastColumn := LTokenHelper.CharsBefore + Length(LTokenHelper.Text) + 1;

    if not AMinimap and (LTokenRect.Right > FLeftMarginWidth) or
      AMinimap and ((FMinimap.Align = maRight) and (LTokenRect.Left < Width) or
      (FMinimap.Align = maLeft) and (LTokenRect.Left < FMinimap.Width)) then
    begin
      LTokenLength := ATokenLength;

      if LTokenHelper.EmptySpace = esTab then
      begin
        LTokenLength := LTokenLength * FTabs.Width;
        LText := StringOfChar(TCharacters.Space, LTokenLength);
      end
      else
        LText := AToken;

      LPChar := PChar(LText);
      LTextRect := LTokenRect;

      if AMinimap and (FMinimap.Align = maLeft) then
        LTextRect.Right := Min(LTextRect.Right, FMinimap.Width);

      if not AMinimap then
      begin
        if LTokenHelper.IsItalic and (LPChar^ <> TCharacters.Space) and (ATokenLength = Length(AToken)) then
          Inc(LTextRect.Right, FPaintHelper.CharWidth);

        if (FItalic.Offset <> 0) and (not LTokenHelper.IsItalic or (LPChar^ = TCharacters.Space)) then
        begin
          Inc(LTextRect.Left, FItalic.Offset);
          Inc(LTextRect.Right, FItalic.Offset);

          if not LTokenHelper.IsItalic then
            Dec(LTextRect.Left);

          if LPChar^ = TCharacters.Space then
            FItalic.Offset := 0;
        end;
      end;

      if LTokenHelper.EmptySpace in [esNull, esControlCharacter, esZeroWidthSpace] then
      begin
        FillRect(LTextRect);
        PaintControlCharacters;
      end
      else
      if FSpecialChars.Visible and (LTokenHelper.EmptySpace <> esNone) and
        (not (scoShowOnlyInSelection in FSpecialChars.Options) or
        (scoShowOnlyInSelection in FSpecialChars.Options) and (Canvas.Brush.Color = FSelection.Colors.Background)) and
        (not AMinimap or AMinimap and (moShowSpecialChars in FMinimap.Options)) then
      begin
        if FSpecialChars.Selection.Visible and (Canvas.Brush.Color = FSelection.Colors.Background) then
          Canvas.Pen.Color := FSpecialChars.Selection.Color
        else
          Canvas.Pen.Color := LTokenHelper.Foreground;

        FillRect(LTextRect);

        if (FSpecialChars.Selection.Visible and (Canvas.Brush.Color = FSelection.Colors.Background) or
          (Canvas.Brush.Color <> FSelection.Colors.Background)) then
        begin
          if LTokenHelper.EmptySpace = esSpace then
            PaintSpecialCharSpace;

          if LTokenHelper.EmptySpace = esTab then
            PaintSpecialCharSpaceTab;
        end;
      end
      else
      begin
        if ASelectedRectPaint then
        begin
          LTempBitmap := Vcl.Graphics.TBitmap.Create;
          try
            { Background }
            LTempBitmap.Canvas.Brush.Color := Canvas.Brush.Color;
            { Size }
            LTempBitmap.Width := Width;
            LTempBitmap.Height := 0; // To avoid FillRect
            LTempBitmap.Height := LTextRect.Height; //FI:W508 Variable is assigned twice successively
            { Character }
            LTempBitmap.Canvas.Font.Assign(Font);

            LTempRect := LTextRect;
            LTempRect.Top := 0;
            LTempRect.Height := LTextRect.Height;

            Winapi.Windows.ExtTextOut(LTempBitmap.Canvas.Handle, LTextRect.Left, 0, ETO_OPAQUE or ETO_CLIPPED, @LTempRect,
              LPChar, LTokenLength, nil);

            BitBlt(Canvas.Handle, LSelectedRect.Left, LSelectedRect.Top, LSelectedRect.Width, LSelectedRect.Height,
              LTempBitmap.Canvas.Handle, LSelectedRect.Left, 0, SRCCOPY);
          finally
            LTempBitmap.Free
          end;
        end
        else
          Winapi.Windows.ExtTextOut(Canvas.Handle, LTextRect.Left, LTextRect.Top, ETO_OPAQUE or ETO_CLIPPED, @LTextRect,
            LPChar, LTokenLength, nil);

        if not AMinimap and LTokenHelper.IsItalic and (LPChar^ <> TCharacters.Space) and (ATokenLength <> 0) and
          (ATokenLength = Length(AToken)) then
        begin
          LLastChar := AToken[ATokenLength];
          LAnsiChar := TControlCharacters.Null;
          if Word(LLastChar) < TCharacters.AnsiCharCount then
            LAnsiChar := AnsiChar(LLastChar);

          if FItalic.OffsetCache[LAnsiChar] <> 0 then
            FItalic.Offset := FItalic.OffsetCache[LAnsiChar]
          else
          begin
            FItalic.Offset := 0;
            LBottom := Min(LTokenRect.Bottom, Canvas.ClipRect.Bottom);

            LMaxX := LTokenRect.Right;
            LOrigMaxX := LMaxX;
            FItalic.Bitmap.Height := LBottom - LTokenRect.Top;
            FItalic.Bitmap.Width := 3;
            BitBlt(FItalic.Bitmap.Canvas.Handle, 0, 0, FItalic.Bitmap.Width, FItalic.Bitmap.Height, Canvas.Handle, LMaxX,
              LTokenRect.Top, SRCCOPY);
            LLeftStart := 0;
            for LTop := 0 to FItalic.Bitmap.Height - 1 do
            begin
              LPixels := FItalic.Bitmap.ScanLine[LTop];
              for LLeft := LLeftStart to FItalic.Bitmap.Width - 1 do
              begin
                LTriple := LPixels[LLeft];
                if (LTriple.Red <> LBackgroundColorRed) and (LTriple.Green <> LBackgroundColorGreen) and
                  (LTriple.Blue <> LBackgroundColorBlue) then
                  if LOrigMaxX + LLeft > LMaxX then
                  begin
                    LMaxX := LOrigMaxX + LLeft;
                    LLeftStart := LLeft;
                  end;
              end;
            end;

            FItalic.Offset := Max(LMaxX - LTokenRect.Right + 1, 0);

            if LAnsiChar <> TControlCharacters.Null then
              FItalic.OffsetCache[LAnsiChar] := FItalic.Offset;
          end;

          if LLastColumn = LCurrentLineLength + 1 then
            Inc(LTokenRect.Right, FItalic.Offset);

          if LAddWrappedCount then
            Inc(LTokenRect.Right, FItalic.Offset);
        end;
      end;

      if LTokenHelper.Border <> TColors.SysNone then
      begin
        LOldPenColor := Canvas.Pen.Color;
        Canvas.Pen.Color := LTokenHelper.Border;
        Canvas.MoveTo(LTextRect.Left, LTextRect.Bottom - 1);
        Canvas.LineTo(LTokenRect.Right + FItalic.Offset - 1, LTextRect.Bottom - 1);
        Canvas.LineTo(LTokenRect.Right + FItalic.Offset - 1, LTextRect.Top);
        Canvas.LineTo(LTextRect.Left, LTextRect.Top);
        Canvas.LineTo(LTextRect.Left, LTextRect.Bottom - 1);
        Canvas.Pen.Color := LOldPenColor;
      end;

      if LTokenHelper.Underline <> ulNone then
      begin
        LOldPenColor := Canvas.Pen.Color;
        Canvas.Pen.Color := LTokenHelper.UnderlineColor;

        case LTokenHelper.Underline of
          ulDoubleUnderline, ulUnderline:
            begin
              if LTokenHelper.Underline = ulDoubleUnderline then
              begin
                Canvas.MoveTo(LTextRect.Left, LTextRect.Bottom - 3);
                Canvas.LineTo(LTokenRect.Right, LTextRect.Bottom - 3);
              end;
              Canvas.MoveTo(LTextRect.Left, LTextRect.Bottom - 1);
              Canvas.LineTo(LTokenRect.Right, LTextRect.Bottom - 1);
            end;
          ulWavyZigzag:
            begin
              LStep := 0;
              while LStep < LTokenRect.Right - 4 do
              begin
                LLeft := LTextRect.Left + LStep;
                Canvas.MoveTo(LLeft, LTextRect.Bottom - 3);
                Canvas.LineTo(LLeft + 2, LTextRect.Bottom - 1);
                Canvas.LineTo(LLeft + 4, LTextRect.Bottom - 3);
                Inc(LStep, 4);
              end;
            end;
          ulWaveLine:
            begin
              LLeft := LTextRect.Left;
              while LLeft < LTokenRect.Right do
              begin
                Canvas.MoveTo(LLeft, LTextRect.Bottom - 3);
                Canvas.LineTo(LLeft + 3, LTextRect.Bottom - 3);
                Inc(LLeft, 6);
              end;
              LLeft := LTextRect.Left;
              Canvas.MoveTo(LLeft, LTextRect.Bottom - 2);
              Inc(LLeft);
              Canvas.LineTo(LLeft, LTextRect.Bottom - 2);
              while LLeft < LTokenRect.Right do
              begin
                Canvas.MoveTo(LLeft + 1, LTextRect.Bottom - 2);
                Canvas.LineTo(LLeft + 3, LTextRect.Bottom - 2);
                Inc(LLeft, 3);
              end;
              LLeft := LTextRect.Left;
              while LLeft < LTokenRect.Right do
              begin
                Canvas.MoveTo(LLeft + 3, LTextRect.Bottom - 1);
                Canvas.LineTo(LLeft + 6, LTextRect.Bottom - 1);
                Inc(LLeft, 6);
              end;
            end;
        end;
        Canvas.Pen.Color := LOldPenColor;
      end;
    end;

    LTokenRect.Left := LTokenRect.Right;
  end;

  procedure PaintHighlightToken(const AFillToEndOfLine: Boolean);
  var
    LIsPartOfTokenSelected: Boolean;
    LFirstColumn, LLastColumn: Integer;
    LFirstUnselectedPartOfToken, LSelected, LSecondUnselectedPartOfToken: Boolean;
    LText, LSelectedText: string;
    LTokenLength, LSelectedTokenLength: Integer;
    LSearchTokenRect, LTempRect: TRect;
    LOldColor: TColor;
    LTempText: string;
  begin
    LOldColor := FPaintHelper.Color;

    LFirstColumn := LTokenHelper.CharsBefore + 1;
    LLastColumn := LFirstColumn + LTokenHelper.Length;

    LFirstUnselectedPartOfToken := False;
    LSecondUnselectedPartOfToken := False;
    LIsPartOfTokenSelected := False;

    if LIsSelectionInsideLine then
    begin
      LSelected := (LFirstColumn >= LLineSelectionStart) and (LFirstColumn < LLineSelectionEnd) or
        (LLastColumn >= LLineSelectionStart) and (LLastColumn <= LLineSelectionEnd) or
        (LLineSelectionStart > LFirstColumn) and (LLineSelectionEnd < LLastColumn);
      if LSelected then
      begin
        LFirstUnselectedPartOfToken := LFirstColumn < LLineSelectionStart;
        LSecondUnselectedPartOfToken := LLastColumn > LLineSelectionEnd;
        LIsPartOfTokenSelected := LFirstUnselectedPartOfToken or LSecondUnselectedPartOfToken;
      end;
    end
    else
      LSelected := LIsLineSelected;

    LBackgroundColor := LTokenHelper.Background;
    LForegroundColor := LTokenHelper.Foreground;

    FPaintHelper.SetStyle(LTokenHelper.FontStyle);

    if AMinimap and not (ioUseBlending in FMinimap.Indicator.Options) then
      if (LViewLine >= TopLine) and (LViewLine < TopLine + VisibleLineCount) then
        if (LBackgroundColor <> FSearch.Highlighter.Colors.Background) and (LBackgroundColor <> clRed) then
          LBackgroundColor := FMinimap.Colors.VisibleLines;

    if LCustomLineColors and (LCustomForegroundColor <> TColors.SysNone) then
      LForegroundColor := LCustomForegroundColor;
    if LCustomLineColors and (LCustomBackgroundColor <> TColors.SysNone) then
      LBackgroundColor := LCustomBackgroundColor;

    LText := LTokenHelper.Text;

    LTokenLength := 0;
    LSelectedTokenLength := 0;
    LSearchTokenRect := LTokenRect;

    if LIsPartOfTokenSelected then
    begin
      if LTokenHelper.RightToLeftToken then
      begin
        LSelectedRect := LTokenRect;

        LTempText := LText;

        SetDrawingColors(False);
        LTokenLength := Length(LText);
        LTokenRect.Right := LTokenRect.Left + GetTokenWidth(LText, LTokenLength, LTokenHelper.ExpandedCharsBefore,
          AMinimap, True);
        LTempRect := LTokenRect;
        PaintToken(LText, LTokenLength);

        { Selected part of the token }
        if (LLastColumn >= LLineSelectionEnd) or not LSecondUnselectedPartOfToken then
        begin
          { Get the unselected part from the end of the text }
          LText := Copy(LTempText, LTokenLength - (LLastColumn - LLineSelectionEnd) + 1);
          { Set left of the rect }
          LTokenRect.Left := LSelectedRect.Left + GetTokenWidth(LText, Length(LText), LTokenHelper.ExpandedCharsBefore,
            AMinimap, True);
          { Delete the unselected part from the end of the text }
          LText := LTempText;
          Delete(LText, LTokenLength - (LLastColumn - LLineSelectionEnd) + 1, LLineSelectionEnd - LLineSelectionStart);
        end
        else
        if LFirstUnselectedPartOfToken then
        begin
          { Get the unselected part from the start of the text }
          LText := Copy(LTempText, (LLineSelectionStart - LFirstColumn) + 1);
          { Set left of the rect }
          LTokenRect.Left := LSelectedRect.Left + GetTokenWidth(LText, Length(LText), LTokenHelper.ExpandedCharsBefore,
            AMinimap, True);
          { Delete the unselected part from the end of the text }
          LText := LTempText;
          Delete(LText, (LLineSelectionStart - LFirstColumn) + 1, LLineSelectionEnd - LLineSelectionStart);
        end
        else
          LTokenRect.Left := LSelectedRect.Left;

        if (LLineSelectionEnd <= LLastColumn) or not LSecondUnselectedPartOfToken then
        begin
          { Copy selected text part from the end of the text }
          LText := Copy(LText, (LLineSelectionStart - LFirstColumn) + 1);

          if LSecondUnselectedPartOfToken then
            LTokenLength := LLineSelectionEnd - LLineSelectionStart
          else
            LTokenLength := Length(LText);

          { Set right of the rect }
          LTokenRect.Right := LTokenRect.Left + GetTokenWidth(LText, LTokenLength, LTokenHelper.ExpandedCharsBefore,
            AMinimap, True);
        end;

        LSelectedRect := LTokenRect;

        { Paint selected rect }
        SetDrawingColors(True);
        LText := LTempText;
        LTokenLength := Length(LText);
        LTokenRect := LTempRect;

        PaintToken(LText, LTokenLength, True);
      end
      else
      begin
        if LFirstUnselectedPartOfToken then
        begin
          SetDrawingColors(False);
          LTokenLength := LLineSelectionStart - LFirstColumn;
          LTokenRect.Right := LTokenRect.Left + GetTokenWidth(LText, LTokenLength, LTokenHelper.ExpandedCharsBefore, AMinimap);
          PaintToken(LText, LTokenLength);
          Delete(LText, 1, LTokenLength);
        end;
        { Selected part of the token }
        LTokenLength := Min(LLineSelectionEnd, LLastColumn) - LFirstColumn - LTokenLength;
        LTokenRect.Right := LTokenRect.Left + GetTokenWidth(LText, LTokenLength, LTokenHelper.ExpandedCharsBefore, AMinimap);
        LSelectedRect := LTokenRect;
        LSelectedTokenLength := LTokenLength;
        LSelectedText := LText;
        LTokenRect.Left := LTokenRect.Right;
        if LSecondUnselectedPartOfToken then
        begin
          Delete(LText, 1, LTokenLength);
          SetDrawingColors(False);
          LTokenRect.Right := LTokenRect.Left + GetTokenWidth(LText, Length(LText), LTokenHelper.ExpandedCharsBefore, AMinimap);
          PaintToken(LText, Length(LText));
        end;
      end;
    end
    else
    if LText <> '' then
    begin
      SetDrawingColors(LSelected);
      LTokenLength := Length(LText);
      LTokenRect.Right := LTokenRect.Left + GetTokenWidth(LText, LTokenLength, LTokenHelper.ExpandedCharsBefore, AMinimap);
      PaintToken(LText, LTokenLength)
    end;

    if FSpecialChars.Visible and (LLastColumn >= LCurrentLineLength) then
      LLineEndRect := LTokenRect;

    if (not LSelected or LIsPartOfTokenSelected) and not AMinimap or AMinimap and (moShowSearchResults in FMinimap.Options) then
    begin
      LSearchTokenRect.Right := LTokenRect.Right;
      PaintSearchResults(LTokenHelper.Text, LSearchTokenRect);
    end;

    if LIsPartOfTokenSelected and not LTokenHelper.RightToLeftToken then
    begin
      SetDrawingColors(True);
      LTempRect := LTokenRect;
      LTokenRect := LSelectedRect;
      PaintToken(LSelectedText, LSelectedTokenLength);
      LTokenRect := LTempRect;
    end;

    if AFillToEndOfLine and (LTokenRect.Left < LLineRect.Right) then
    begin
      LBackgroundColor := GetBackgroundColor;

      if AMinimap and not (ioUseBlending in FMinimap.Indicator.Options) then
        if (LViewLine >= TopLine) and (LViewLine < TopLine + VisibleLineCount) then
          LBackgroundColor := FMinimap.Colors.VisibleLines;

      if LCustomLineColors and (LCustomForegroundColor <> TColors.SysNone) then
        LForegroundColor := LCustomForegroundColor;
      if LCustomLineColors and (LCustomBackgroundColor <> TColors.SysNone) then
        LBackgroundColor := LCustomBackgroundColor;

      if FSelection.Mode = smNormal then
      begin
        SetDrawingColors(not (soToEndOfLine in FSelection.Options) and (LIsLineSelected or LSelected and
          (LLineSelectionEnd > LLastColumn)));
        LTokenRect.Right := LLineRect.Right;
        FillRect(LTokenRect);
      end
      else
      begin
        if LLineSelectionStart > LLastColumn then
        begin
          SetDrawingColors(False);
          LTokenRect.Right := Min(LTokenRect.Left + (LLineSelectionStart - LLastColumn) * FPaintHelper.CharWidth, LLineRect.Right);
          FillRect(LTokenRect);
        end;

        if (LTokenRect.Right < LLineRect.Right) and (LLineSelectionEnd > LLastColumn) then
        begin
          SetDrawingColors(True);
          LTokenRect.Left := LTokenRect.Right;
          if LLineSelectionStart > LLastColumn then
            LTokenLength := LLineSelectionEnd - LLineSelectionStart
          else
            LTokenLength := LLineSelectionEnd - LLastColumn;
          LTokenRect.Right := Min(LTokenRect.Left + LTokenLength * FPaintHelper.CharWidth, LLineRect.Right);
          FillRect(LTokenRect);
        end;

        if LTokenRect.Right < LLineRect.Right then
        begin
          SetDrawingColors(False);
          LTokenRect.Left := LTokenRect.Right;
          LTokenRect.Right := LLineRect.Right;
          FillRect(LTokenRect);
        end;

        if LTokenRect.Right = LLineRect.Right then
        begin
          SetDrawingColors(False);
          FillRect(LTokenRect);
        end;
      end;
    end;

    FPaintHelper.SetForegroundColor(LOldColor);
  end;

  procedure PrepareTokenHelper(const AToken: string; const ACharsBefore, ATokenLength: Integer;
    const AForeground, ABackground: TColor; const ABorder: TColor; const AFontStyle: TFontStyles;
    const AUnderline: TTextEditorUnderline; const AUnderlineColor: TColor; const ACustomBackgroundColor: Boolean);
  var
    LCanAppend, LAnsiEncoding: Boolean;
    LEmptySpace: TTextEditorEmptySpace;
    LToken: string;
    LTokenLength: Integer;
    LPToken: PChar;
    LAppendAnsiChars, LAppendTabs, LAppendEmptySpace: Boolean;
    LForeground, LBackground: TColor;

    function IsAnsiUnicodeChar(const AChar: Char): Boolean;
    begin
      case AChar of
        '™', '€', 'ƒ', '„', '†', '‡', 'ˆ', '‰', 'Š', '‹', 'Œ', 'Ž', '‘', '’', '“', '”', '•', '–', '—', '˜', 'š', '›',
        'œ', 'ž', 'Ÿ':
          Result := True
      else
        Result := False;
      end;
    end;

  begin
    LForeground := AForeground;
    LBackground := ABackground;
    if (LBackground = TColors.SysNone) or
      ((FActiveLine.Colors.Background <> TColors.SysNone) and LIsCurrentLine and not ACustomBackgroundColor) then
      LBackground := GetBackgroundColor;
    if AForeground = TColors.SysNone then
      LForeground := FColors.Foreground;

    LCanAppend := False;

    LToken := AToken;
    LTokenLength := ATokenLength;
    LPToken := PChar(LToken);

    if eoShowNonBreakingSpaceAsSpace in Options then
      if LPToken^ = TCharacters.NonBreakingSpace then
        LPToken^ := TCharacters.Space;

    if LPToken^ = TCharacters.Space then
      LEmptySpace := esSpace
    else
    if LPToken^ = TControlCharacters.Tab then
      LEmptySpace := esTab
    else
    if LPToken^ = TControlCharacters.Substitute then
      LEmptySpace := esNull
    else
    if (LPToken^ < TCharacters.Space) and (LPToken^ in TControlCharacters.AsSet) then
      LEmptySpace := esControlCharacter
    else
    if LPToken^ = TCharacters.ZeroWidthSpace then
      LEmptySpace := esZeroWidthSpace
    else
      LEmptySpace := esNone;

    if (LEmptySpace <> esNone) and FSpecialChars.Visible then
    begin
      if scoMiddleColor in FSpecialChars.Options then
        LForeground := MiddleColor(FHighlighter.MainRules.Attribute.Background, FHighlighter.MainRules.Attribute.Foreground)
      else
      if scoTextColor in FSpecialChars.Options then
        LForeground := FHighlighter.MainRules.Attribute.Foreground
      else
        LForeground := FSpecialChars.Color;
    end;

    if LTokenHelper.Length > 0 then { Can we append the token? }
    begin
      { This fixes the minor painting issue with closing tags. E.g. /script. This is hard to fix otherwise because
        in the case closing tag must be /script. }
      if (LToken.Length > 2) and (LPToken^ = TCharacters.Slash) and ((LPToken + 1)^ <> TCharacters.Slash) then
      begin
        Inc(LTokenHelper.Length);
        LTokenHelper.Text := LTokenHelper.Text + TCharacters.Slash;
        Delete(LToken, 1, 1);
        Dec(LTokenLength);
      end;

      LCanAppend := (LTokenHelper.Length < TMaxValues.TokenLength) and
        (LTokenHelper.Background = LBackground) and (LTokenHelper.Foreground = LForeground);

      if AMinimap then
        LCanAppend := LCanAppend and (LTokenHelper.FontStyle = AFontStyle)
      else
      begin
        LAppendAnsiChars := (LTokenHelper.Length > 0) and (Ord(LTokenHelper.Text[1]) < TCharacters.AnsiCharCount) and
          (Ord(LPToken^) < TCharacters.AnsiCharCount);
        LAppendTabs := not FLines.Columns or FLines.Columns and (LEmptySpace <> esTab);
        LAppendEmptySpace := (LEmptySpace = LTokenHelper.EmptySpace) and (LEmptySpace <> esControlCharacter);

        LCanAppend := LCanAppend and
          ((LTokenHelper.FontStyle = AFontStyle) or ((LEmptySpace <> esNone) and not (fsUnderline in AFontStyle) and
          not (fsUnderline in LTokenHelper.FontStyle))) and
          (LTokenHelper.Underline = AUnderline) and LAppendEmptySpace and LAppendAnsiChars and LAppendTabs;
      end;

      if not LCanAppend then
      begin
        PaintHighlightToken(False);
        LTokenHelper.EmptySpace := esNone;
      end;
    end;

    LTokenHelper.EmptySpace := LEmptySpace;

    if FUnknownChars.Visible and (FLines.UnknownCharHigh > 0) then
    while LPToken^ <> TControlCharacters.Null do
    begin
      LAnsiEncoding := FLines.Encoding = System.SysUtils.TEncoding.ANSI;
      if (not LAnsiEncoding or LAnsiEncoding and not IsAnsiUnicodeChar(LPToken^)) and (Ord(LPToken^) > FLines.UnknownCharHigh) then
        LPToken^ := Char(FUnknownChars.ReplaceChar);
      Inc(LPToken);
    end;

    if LCanAppend then
    begin
      Insert(LToken, LTokenHelper.Text, LTokenHelper.Length + 1);
      Inc(LTokenHelper.Length, LTokenLength);
    end
    else
    begin
      LTokenHelper.Length := LTokenLength;
      LTokenHelper.Text := LToken;
      LTokenHelper.CharsBefore := ACharsBefore;
      LTokenHelper.ExpandedCharsBefore := LExpandedCharsBefore;
      LTokenHelper.Foreground := LForeground;
      LTokenHelper.Background := LBackground;
      LTokenHelper.Border := ABorder;
      LTokenHelper.FontStyle := AFontStyle;
      LTokenHelper.IsItalic := not AMinimap and (fsItalic in AFontStyle);
      LTokenHelper.Underline := AUnderline;
      LTokenHelper.UnderlineColor := AUnderlineColor;
      LTokenHelper.RightToLeftToken := FHighlighter.RightToLeftToken;
    end;

    LPToken := PChar(LToken);

    if LPToken^ = TControlCharacters.Tab then
    begin
      Inc(LExpandedCharsBefore, FTabs.Width);
      if FLines.Columns then
        Dec(LExpandedCharsBefore, LExpandedCharsBefore mod FTabs.Width)
    end
    else
      Inc(LExpandedCharsBefore, LTokenLength);
  end;

  procedure PaintLines;
  var
    LLine, LFirstColumn, LLastColumn: Integer;
    LFromLineText, LToLineText: string;
    LCurrentRow: Integer;
    LFoldRange: TTextEditorCodeFoldingRange;
    LHighlighterAttribute: TTextEditorHighlighterAttribute;
    LTokenText, LNextTokenText: string;
    LTokenPosition, LWordWrapTokenPosition, LTokenLength: Integer;
    LFontStyles: TFontStyles;
    LKeyword, LWordAtSelection, LSelectedText: string;
    LUnderline: TTextEditorUnderline;
    LUnderlineColor: TColor;
    LOpenTokenEndPos, LOpenTokenEndLen: Integer;
    LElement: string;
    LIsCustomBackgroundColor: Boolean;
    LTextPosition: TTextEditorTextPosition;
    LTextCaretY: Integer;
    LLinePosition: Integer;

    procedure GetWordAtSelection;
    var
      LTempTextPosition: TTextEditorTextPosition;
      LSelectionBeginChar, LSelectionEndChar: Integer;
    begin
      LTempTextPosition := FPosition.EndSelection;
      LSelectionBeginChar := FPosition.BeginSelection.Char;
      LSelectionEndChar := FPosition.EndSelection.Char;
      if LSelectionBeginChar > LSelectionEndChar then
        SwapInt(LSelectionBeginChar, LSelectionEndChar);
      LTempTextPosition.Char := LSelectionEndChar - 1;
      LSelectedText := Copy(FLines[FPosition.BeginSelection.Line], LSelectionBeginChar,
        LSelectionEndChar - LSelectionBeginChar);

      if FPosition.BeginSelection.Line = FPosition.EndSelection.Line then
        LWordAtSelection := WordAtTextPosition(LTempTextPosition)
      else
        LWordAtSelection := '';
    end;

    procedure PrepareToken;
    var
      LPToken, LPWord: PChar;
    begin
      LBorderColor := TColors.SysNone;
      LHighlighterAttribute := FHighlighter.TokenAttribute;
      if not (csDesigning in ComponentState) and Assigned(LHighlighterAttribute) then
      begin
        if LHighlighterAttribute.Foreground = TColors.SysNone then
          LForegroundColor := Colors.Foreground
        else
          LForegroundColor := LHighlighterAttribute.Foreground;

        if not AMinimap and LIsCurrentLine and FActiveLine.Visible and (FActiveLine.Colors.Foreground <> TColors.SysNone) then
          LForegroundColor := FActiveLine.Colors.Foreground;

        if AMinimap and (FMinimap.Colors.Background <> TColors.SysNone) then
          LBackgroundColor := FMinimap.Colors.Background
        else
          LBackgroundColor := LHighlighterAttribute.Background;

        LFontStyles := LHighlighterAttribute.FontStyles;

        LIsCustomBackgroundColor := False;
        LUnderline := ulNone;
        LUnderlineColor := TColors.SysNone;

        if Assigned(FEvents.OnCustomTokenAttribute) then
          FEvents.OnCustomTokenAttribute(Self, LTokenText, LCurrentLine, LTokenPosition, LForegroundColor,
            LBackgroundColor, LFontStyles, LUnderline, LUnderlineColor);

        if FMatchingPairs.Active and not FSyncEdit.Visible and (FMatchingPair.Current <> trNotFound) then
          if (LCurrentLine = FMatchingPair.CurrentMatch.OpenTokenPos.Line) and
            (LTokenPosition = FMatchingPair.CurrentMatch.OpenTokenPos.Char - 1) or
            (LCurrentLine = FMatchingPair.CurrentMatch.CloseTokenPos.Line) and
            (LTokenPosition = FMatchingPair.CurrentMatch.CloseTokenPos.Char - 1) then
          begin
            LIsCustomBackgroundColor := (mpoUseMatchedColor in FMatchingPairs.Options) and
              not (mpoUnderline in FMatchingPairs.Options);
            if (FMatchingPair.Current = trOpenAndCloseTokenFound) or (FMatchingPair.Current = trCloseAndOpenTokenFound) then
            begin
              if LIsCustomBackgroundColor then
              begin
                if LForegroundColor = FMatchingPairs.Colors.Matched then
                  LForegroundColor := FColors.Background;

                if not AMinimap and (FActiveLine.Colors.Foreground <> TColors.SysNone) then
                  LForegroundColor := FActiveLine.Colors.Foreground;

                if not (mpoUnderline in FMatchingPairs.Options) then
                  LBackgroundColor := FMatchingPairs.Colors.Matched;
              end;

              if mpoUnderline in FMatchingPairs.Options then
              begin
                LUnderline := ulUnderline;
                LUnderlineColor := FMatchingPairs.Colors.Underline;
              end;
            end
            else
            if mpoHighlightUnmatched in FMatchingPairs.Options then
            begin
              if LIsCustomBackgroundColor then
              begin
                if LForegroundColor = FMatchingPairs.Colors.Unmatched then
                  LForegroundColor := FColors.Background;
                LBackgroundColor := FMatchingPairs.Colors.Unmatched;
              end;

              if mpoUnderline in FMatchingPairs.Options then
              begin
                LUnderline := ulUnderline;
                LUnderlineColor := FMatchingPairs.Colors.Underline;
              end;
            end;
          end;

        if FSyncEdit.BlockSelected and LIsSyncEditBlock then
          LBackgroundColor := FSyncEdit.Colors.Background;

        if FSearch.InSelection.Active and LIsSearchInSelectionBlock then
          LBackgroundColor := FSearch.InSelection.Background;

        if not FSyncEdit.Visible and LAnySelection and (soHighlightSimilarTerms in FSelection.Options) and
          not FSearch.InSelection.Active then
        begin
          LKeyword := '';

          if LSelectedText.Trim <> '' then
          begin
            if soTermsCaseSensitive in FSelection.Options then
            begin
              if LTokenText = LWordAtSelection then
                LKeyword := LSelectedText;

              LIsCustomBackgroundColor := (LKeyword <> '') and (LKeyword = LTokenText);
            end
            else
            begin
              LPToken := PChar(LTokenText);
              LPWord := PChar(LSelectedText);
              while (LPToken^ <> TControlCharacters.Null) and (LPWord^ <> TControlCharacters.Null) and
                (CaseUpper(LPToken^) = CaseUpper(LPWord^)) do
              begin
                Inc(LPToken);
                Inc(LPWord);
              end;
              LIsCustomBackgroundColor := (LPToken^ = TControlCharacters.Null) and (LPWord^ = TControlCharacters.Null);
              if LIsCustomBackgroundColor then
                LKeyword := LSelectedText;
            end;
          end;

          if LIsCustomBackgroundColor then
          begin
            if FSearch.Highlighter.Colors.Foreground <> TColors.SysNone then
              LForegroundColor := FSearch.Highlighter.Colors.Foreground;
            LBackgroundColor := FSearch.Highlighter.Colors.Background;
            LBorderColor := FSearch.Highlighter.Colors.Border;
          end;
        end;

        if (LMarkColor <> TColors.SysNone) and not (LIsCurrentLine and FActiveLine.Visible and
          (FActiveLine.Colors.Background <> TColors.SysNone)) then
        begin
          LIsCustomBackgroundColor := True;
          LBackgroundColor := LMarkColor;
        end;

{$IFDEF TEXT_EDITOR_SPELL_CHECK}
        if (eoSpellCheck in FOptions) and Assigned(FSpellCheck) and (FSpellCheck.Items.Count > 0) then
          if (LCurrentLine = LSpellCheckTextPosition.Line) and (LTokenPosition = LSpellCheckTextPosition.Char - 1) then
          begin
            if AMinimap then
            begin
              LIsCustomBackgroundColor := True;
              LBackgroundColor := TColors.Red;
            end
            else
            begin
              LUnderline := FSpellCheck.Underline;
              LUnderlineColor := FSpellCheck.UnderlineColor;
            end;

            Inc(LCurrentSpellCheckIndex);

            if LCurrentSpellCheckIndex < FSpellCheck.Items.Count then
              LSpellCheckTextPosition := PTextEditorTextPosition(FSpellCheck.Items.Items[LCurrentSpellCheckIndex])^;
          end;
{$ENDIF}

        PrepareTokenHelper(LTokenText, LTokenPosition, LTokenLength, LForegroundColor, LBackgroundColor, LBorderColor,
          LFontStyles, LUnderline, LUnderlineColor, LIsCustomBackgroundColor)
      end
      else
        PrepareTokenHelper(LTokenText, LTokenPosition, LTokenLength, LForegroundColor, LBackgroundColor, LBorderColor,
          Font.Style, ulNone, TColors.SysNone, False);
    end;

    procedure SetSelectionVariables;
    begin
      if not AMinimap or AMinimap and (moShowSelection in FMinimap.Options) then
      begin
        LAnySelection := GetSelectionAvailable;

        if LAnySelection then
        begin
          GetWordAtSelection;

          LSelectionBeginPosition := GetSelectionBeginPosition;
          LSelectionEndPosition := GetSelectionEndPosition;

          if FSelection.Mode = smColumn then
            if LSelectionBeginPosition.Char > LSelectionEndPosition.Char then
              SwapInt(LSelectionBeginPosition.Char, LSelectionEndPosition.Char);
        end
        else
          LWordAtSelection := '';
      end
      else
      begin
        LWordAtSelection := '';
        LAnySelection := False;
      end;
    end;

    procedure SetLineSelectionVariables;
    begin
      LIsSelectionInsideLine := False;
      LLineSelectionStart := 0;
      LLineSelectionEnd := 0;

      if LAnySelection and (LCurrentLine >= LSelectionBeginPosition.Line) and (LCurrentLine <= LSelectionEndPosition.Line) then
      begin
        LLineSelectionStart := 1;
        LLineSelectionEnd := LLastColumn + 1;

        if (FSelection.ActiveMode = smColumn) or
          ((FSelection.ActiveMode = smNormal) and (LCurrentLine = LSelectionBeginPosition.Line)) then
        begin
          if LSelectionBeginPosition.Char > LLastColumn then
          begin
            LLineSelectionStart := 0;
            LLineSelectionEnd := 0;
          end
          else
          if LSelectionBeginPosition.Char > LTokenPosition then
          begin
            LLineSelectionStart := LSelectionBeginPosition.Char;
            LIsSelectionInsideLine := True;
          end;
        end;

        if (FSelection.ActiveMode = smColumn) or
          ((FSelection.ActiveMode = smNormal) and (LCurrentLine = LSelectionEndPosition.Line)) then
        begin
          if LSelectionEndPosition.Char < 1 then
          begin
            LLineSelectionStart := 0;
            LLineSelectionEnd := 0;
          end
          else
          if LSelectionEndPosition.Char < LLastColumn then
          begin
            LLineSelectionEnd := LSelectionEndPosition.Char;
            LIsSelectionInsideLine := True;
          end;
        end;
      end;

      LIsLineSelected := not LIsSelectionInsideLine and (LLineSelectionStart > 0);
    end;

  begin
    LLineRect := AClipRect;
    if AMinimap then
      LLineRect.Bottom := (AFirstLine - FMinimap.TopLine + 1) * FMinimap.CharHeight
    else
    begin
      LLineRect.Bottom := LLineHeight;
      if FRuler.Visible then
        Inc(LLineRect.Bottom, FRuler.Height);
    end;

    LCurrentLineText := '';
    SetSelectionVariables;

    LViewLine := AFirstLine;
    LBookmarkOnCurrentLine := False;

    while LViewLine <= ALastLine do
    begin
      LCurrentLine := GetViewTextLineNumber(LViewLine) - 1;

      if AMinimap then
        LMarkColor := TColors.SysNone
      else
        LMarkColor := GetMarkBackgroundColor(LCurrentLine + 1);

      if AMinimap and (moShowBookmarks in FMinimap.Options) then
        LBookmarkOnCurrentLine := IsBookmarkOnCurrentLine;

      LCurrentLineText := FLines[LCurrentLine];

      LPaintedColumn := 1;

      LIsCurrentLine := False;
      LCurrentLineLength := Length(LCurrentLineText);

      LTokenPosition := 0;
      LTokenLength := 0;
      LNextTokenText := '';
      LExpandedCharsBefore := 0;
      LCurrentRow := LCurrentLine + 1;
      LTextCaretY := FPosition.Text.Line;

      LFirstColumn := 1;
      LWrappedRowCount := 0;

      if FWordWrap.Active and (LViewLine < Length(FWordWrapLine.ViewLength)) then
      begin
        LLastColumn := LCurrentLineLength;
        LLine := LViewLine - 1;
        if LLine > 0 then
        while (LLine > 0) and (GetViewTextLineNumber(LLine) = LCurrentLine + 1) do
        begin
          Inc(LFirstColumn, FWordWrapLine.ViewLength[LLine]);
          Dec(LLine);
          Inc(LWrappedRowCount);
        end;
        if LFirstColumn > 1 then
        begin
          LCurrentLineText := Copy(LCurrentLineText, LFirstColumn, LCurrentLineLength);
          LFirstColumn := 1;
        end;
      end
      else
        LLastColumn := GetVisibleChars(LCurrentLine + 1, LCurrentLineText);

      SetLineSelectionVariables;

      LFoldRange := nil;
      if not AMinimap and FCodeFolding.Visible then
      begin
        LFoldRange := CodeFoldingCollapsableFoldRangeForLine(LCurrentLine + 1);
        if Assigned(LFoldRange) and LFoldRange.Collapsed then
        begin
          if FCodeFolding.TextFolding.Active then
          begin
            if Length(LCurrentLineText) > FCodeFolding.CollapsedRowCharacterCount then
              LCurrentLineText := Copy(LCurrentLineText, 1, FCodeFolding.CollapsedRowCharacterCount)  + TCharacters.ThreeDots;
          end
          else
          begin
            LOpenTokenEndLen := 0;
            LFromLineText := FLines.Items^[LFoldRange.FromLine - 1].TextLine;
            LToLineText := FLines.Items^[LFoldRange.ToLine - 1].TextLine;
            LOpenTokenEndPos := 0;
            if Assigned(LFoldRange.RegionItem) then
              LOpenTokenEndPos := FastPos(LFoldRange.RegionItem.OpenTokenEnd, AnsiUpperCase(LFromLineText));

            if LOpenTokenEndPos > 0 then
            begin
              if LCurrentLine = 0 then
                FHighlighter.ResetRange
              else
                FHighlighter.SetRange(FLines.Ranges[LCurrentLine - 1]);
              FHighlighter.SetLine(LFromLineText);

              repeat
                while not FHighlighter.EndOfLine and
                  (LOpenTokenEndPos > FHighlighter.TokenPosition + FHighlighter.TokenLength) do
                  FHighlighter.Next;
                LElement := FHighlighter.RangeAttribute.Element;
                if (LElement <> THighlighterAttribute.ElementComment) and (LElement <> THighlighterAttribute.ElementString) then
                  Break;
                LOpenTokenEndPos := 0;
                if Assigned(LFoldRange.RegionItem) then
                  LOpenTokenEndPos := FastPos(LFoldRange.RegionItem.OpenTokenEnd, AnsiUpperCase(LFromLineText),
                    LOpenTokenEndPos + 1);
              until LOpenTokenEndPos = 0;
            end;

            if Assigned(LFoldRange.RegionItem) then
            begin
              if (LFoldRange.RegionItem.OpenTokenEnd <> '') and (LOpenTokenEndPos > 0) then
              begin
                LOpenTokenEndLen := Length(LFoldRange.RegionItem.OpenTokenEnd);
                LCurrentLineText := Copy(LFromLineText, 1, LOpenTokenEndPos + LOpenTokenEndLen - 1);
              end
              else
                LCurrentLineText := Copy(LFromLineText, 1, Length(LFoldRange.RegionItem.OpenToken) +
                  FastPos(LFoldRange.RegionItem.OpenToken, AnsiUpperCase(LFromLineText)) - 1);

              if LFoldRange.RegionItem.CloseToken <> '' then
                if FastPos(LFoldRange.RegionItem.CloseToken, AnsiUpperCase(LToLineText)) <> 0 then
                begin
                  LCurrentLineText := LCurrentLineText + '..' + TextEditor.Utils.TrimLeft(LToLineText);
                  if LIsSelectionInsideLine then
                    LLineSelectionEnd := Length(LCurrentLineText);
                end;

              if LCurrentLine = FMatchingPair.CurrentMatch.OpenTokenPos.Line then
              begin
                if (LFoldRange.RegionItem.OpenTokenEnd <> '') and (LOpenTokenEndPos > 0) then
                  FMatchingPair.CurrentMatch.CloseTokenPos.Char := LOpenTokenEndPos + LOpenTokenEndLen + 2 { +2 = '..' }
                else
                  FMatchingPair.CurrentMatch.CloseTokenPos.Char := FMatchingPair.CurrentMatch.OpenTokenPos.Char +
                    Length(FMatchingPair.CurrentMatch.OpenToken) + 2 { +2 = '..' };
                FMatchingPair.CurrentMatch.CloseTokenPos.Line := FMatchingPair.CurrentMatch.OpenTokenPos.Line;
              end;
            end;
          end;
        end;
      end;

      if LCurrentLine = 0 then
        FHighlighter.ResetRange
      else
        FHighlighter.SetRange(FLines.Ranges[LCurrentLine - 1]);

      FHighlighter.SetLine(LCurrentLineText);
      LWordWrapTokenPosition := 0;

      while LCurrentRow = LCurrentLine + 1 do
      begin
        LPaintedWidth := 0;
        FItalic.Offset := 0;

        if Assigned(FMultiCaret.Carets) then
          LIsCurrentLine := IsMultiEditCaretFound(LCurrentLine + 1)
        else
          LIsCurrentLine := LTextCaretY = LCurrentLine;

        LForegroundColor := FColors.Foreground;
        LBackgroundColor := GetBackgroundColor;

        LCustomLineColors := False;
        if Assigned(FEvents.OnCustomLineColors) then
          FEvents.OnCustomLineColors(Self, LCurrentLine, LCustomLineColors, LCustomForegroundColor, LCustomBackgroundColor);

        LTokenRect := LLineRect;
        LLineEndRect := LLineRect;
        if LCurrentLineText <> '' then
          LLineEndRect.Left := -100;
        LTokenHelper.Length := 0;
        LTokenHelper.EmptySpace := esNone;
        LAddWrappedCount := False;
        LLinePosition := 0;

        if FWordWrap.Active then
          LLastColumn := FWordWrapLine.Length[LViewLine];

        while not FHighlighter.EndOfLine do
        begin
          LTokenPosition := FHighlighter.TokenPosition;

          if LNextTokenText = '' then
          begin
            FHighlighter.GetToken(LTokenText);
            LWordWrapTokenPosition := 0;
          end
          else
          begin
            LTokenText := LNextTokenText;
            Inc(LTokenPosition, LWordWrapTokenPosition);
          end;

          LNextTokenText := '';
          LTokenLength := Length(LTokenText);

          if (LTokenPosition + LTokenLength >= LFirstColumn) or (LTokenLength = 0) then
          begin
            LIsSyncEditBlock := False;
            if FSyncEdit.BlockSelected then
            begin
              LTextPosition := GetPosition(LTokenPosition + 1, LCurrentLine);
              if FSyncEdit.IsTextPositionInBlock(LTextPosition) then
                LIsSyncEditBlock := True;
            end;

            LIsSearchInSelectionBlock := False;
            if FSearch.InSelection.Active then
            begin
              LTextPosition := GetPosition(LTokenPosition + 1, LCurrentLine);
              if IsTextPositionInSearchBlock(LTextPosition) then
                LIsSearchInSelectionBlock := True;
            end;

            if FWordWrap.Active then
            begin
              if LTokenLength > LLastColumn then
              begin
                LNextTokenText := Copy(LTokenText, LLastColumn - LLinePosition + 1, LTokenLength);
                LTokenText := Copy(LTokenText, 1, LLastColumn - LLinePosition);
                LTokenLength := Length(LTokenText);
                Inc(LWordWrapTokenPosition, LTokenLength);
                PrepareToken;
                LFirstColumn := 1;
                LAddWrappedCount := True;
                Break;
              end;

              if LLinePosition + LTokenLength > LLastColumn then
              begin
                LFirstColumn := 1;
                Break;
              end;
            end
            else
            if LTokenPosition > LLastColumn then
              Break;

            PrepareToken;
          end;
          Inc(LLinePosition, LTokenLength);
          FHighlighter.Next;
        end;

        PaintHighlightToken(True);

        if LAddWrappedCount then
          Inc(LWrappedRowCount);

        if not AMinimap then
        begin
          PaintCodeFoldingCollapseMark(LFoldRange, LCurrentLineText, LTokenPosition, LTokenLength, LCurrentLine, LLineRect);
          PaintSpecialCharsEndOfLine(LCurrentLine + 1, LLineEndRect, (LCurrentLineLength + 1 >= LLineSelectionStart) and
            (LCurrentLineLength + 1 < LLineSelectionEnd));
          PaintCodeFoldingCollapsedLine(LFoldRange, LLineRect);
        end;

        if Assigned(FEvents.OnAfterLinePaint) then
          FEvents.OnAfterLinePaint(Self, Canvas, LLineRect, LCurrentLine, AMinimap);

        LLineRect.Top := LLineRect.Bottom;
        Inc(LLineRect.Bottom, IfThen(AMinimap, FMinimap.CharHeight, LLineHeight));
        Inc(LViewLine);
        LCurrentRow := GetViewTextLineNumber(LViewLine);

        if LWrappedRowCount > VisibleLineCount then
          Break;
      end;
    end;
    LIsCurrentLine := False;
  end;

begin
  LCurrentSearchIndex := -1;
  LLineHeight := GetLineHeight;

  if Assigned(FSearch.Items) and (FSearch.Items.Count > 0) then
  begin
    LCurrentSearchIndex := 0;
    while LCurrentSearchIndex < FSearch.Items.Count do
    begin
      LTextPosition := PTextEditorSearchItem(FSearch.Items.Items[LCurrentSearchIndex])^.EndTextPosition;
      if LTextPosition.Line + 1 >= TopLine then
        Break
      else
        Inc(LCurrentSearchIndex);
    end;

    if LCurrentSearchIndex = FSearch.Items.Count then
      LCurrentSearchIndex := -1;
  end;

{$IFDEF TEXT_EDITOR_SPELL_CHECK}
  LCurrentSpellCheckIndex := -1;
  if Assigned(FSpellCheck) and Assigned(FSpellCheck.Items) and (FSpellCheck.Items.Count > 0) then
  begin
    LCurrentSpellCheckIndex := 0;
    while LCurrentSpellCheckIndex < FSpellCheck.Items.Count do
    begin
      LSpellCheckTextPosition := PTextEditorTextPosition(FSpellCheck.Items.Items[LCurrentSpellCheckIndex])^;
      if LSpellCheckTextPosition.Line + 1 >= TopLine then
        Break
      else
        Inc(LCurrentSpellCheckIndex);
    end;

    if LCurrentSpellCheckIndex = FSpellCheck.Items.Count then
      LCurrentSpellCheckIndex := -1;
  end;
{$ENDIF}

  if ALastLine >= AFirstLine then
    PaintLines;

  LBookmarkOnCurrentLine := False;

  { Fill below the last line }
  LTokenRect := AClipRect;
  if AMinimap then
    LTokenRect.Top := Min(FMinimap.VisibleLineCount, FLineNumbers.Count) * FMinimap.CharHeight
  else
  begin
    LTokenRect.Top := (ALastLine - TopLine + 1) * LLineHeight;

    if FRuler.Visible then
      Inc(LTokenRect.Top, FRuler.Height);
  end;

  if LTokenRect.Top < LTokenRect.Bottom then
  begin
    LBackgroundColor := FColors.Background;
    SetDrawingColors(False);
    FillRect(LTokenRect);
  end;
end;

procedure TCustomTextEditor.RedoItem;
var
  LUndoItem: TTextEditorUndoItem;
  LRun, LStrToDelete: PChar;
  LLength: Integer;
  LTempString: string;
  LChangeScrollPastEndOfLine: Boolean;
  LBeginX: Integer;
  LTextPosition, LSelectionBeginPosition, LSelectionEndPosition: TTextEditorTextPosition;
begin
  LChangeScrollPastEndOfLine := not (soPastEndOfLine in FScroll.Options);
  LUndoItem := FRedoList.PopItem;
  if Assigned(LUndoItem) then
    try
      FSelection.ActiveMode := LUndoItem.ChangeSelectionMode;
      IncPaintLock;

      if LChangeScrollPastEndOfLine then
        FScroll.SetOption(soPastEndOfLine, True);

      FUndoList.InsideRedo := True;
      case LUndoItem.ChangeReason of
        crCaret:
          begin
            FUndoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
              LUndoItem.ChangeEndPosition, '', FSelection.ActiveMode, LUndoItem.ChangeBlockNumber);
            TextPosition := LUndoItem.ChangeCaretPosition;
            SelectionBeginPosition := LUndoItem.ChangeBeginPosition;
            SelectionEndPosition := LUndoItem.ChangeEndPosition;
          end;
        crSelection:
          begin
            FUndoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
              LUndoItem.ChangeEndPosition, '', LUndoItem.ChangeSelectionMode, LUndoItem.ChangeBlockNumber);
            SetCaretAndSelection(LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
              LUndoItem.ChangeEndPosition);
          end;
        crInsert, crPaste, crDragDropInsert:
          begin
            LTextPosition := TextPosition;
            LSelectionBeginPosition := SelectionBeginPosition;
            LSelectionEndPosition := SelectionEndPosition;

            SetCaretAndSelection(LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
              LUndoItem.ChangeBeginPosition);
            DoSelectedText(LUndoItem.ChangeSelectionMode, PChar(LUndoItem.ChangeString), False,
              LUndoItem.ChangeBeginPosition, LUndoItem.ChangeBlockNumber);
            FUndoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
              LUndoItem.ChangeEndPosition, '', LUndoItem.ChangeSelectionMode, LUndoItem.ChangeBlockNumber);
            TextPosition := LTextPosition;
            SelectionBeginPosition := LSelectionBeginPosition;
            SelectionEndPosition := LSelectionEndPosition;
          end;
        crDelete:
          begin
            LTextPosition := TextPosition;
            LSelectionBeginPosition := SelectionBeginPosition;
            LSelectionEndPosition := SelectionEndPosition;

            SetCaretAndSelection(LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
              LUndoItem.ChangeEndPosition);
            LTempString := SelectedText;

            DoSelectedText(LUndoItem.ChangeSelectionMode, PChar(LUndoItem.ChangeString), False,
              LUndoItem.ChangeBeginPosition, LUndoItem.ChangeBlockNumber);

            FPosition.EndSelection := LUndoItem.ChangeEndPosition;

            FUndoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
              LUndoItem.ChangeEndPosition, LTempString, LUndoItem.ChangeSelectionMode, LUndoItem.ChangeBlockNumber);

            TextPosition := LUndoItem.ChangeCaretPosition;
            SelectionBeginPosition := LSelectionBeginPosition;
            SelectionEndPosition := LSelectionEndPosition;
          end;
        crLineBreak:
          begin
            LTextPosition := LUndoItem.ChangeBeginPosition;
            SetCaretAndSelection(LTextPosition, LTextPosition, LTextPosition);
            DoLineBreak(False);
          end;
        crIndent:
          begin
            SetCaretAndSelection(LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
              LUndoItem.ChangeEndPosition);
            FUndoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
              LUndoItem.ChangeEndPosition, LUndoItem.ChangeString, LUndoItem.ChangeSelectionMode,
              LUndoItem.ChangeBlockNumber);
          end;
        crUnindent:
          begin
            LStrToDelete := PChar(LUndoItem.ChangeString);
            SetTextCaretY(LUndoItem.ChangeBeginPosition.Line);
            if LUndoItem.ChangeSelectionMode = smColumn then
              LBeginX := Min(LUndoItem.ChangeBeginPosition.Char, LUndoItem.ChangeEndPosition.Char)
            else
              LBeginX := 1;
            repeat
              LRun := GetEndOfLine(LStrToDelete);
              if LRun <> LStrToDelete then
              begin
                LLength := LRun - LStrToDelete;
                if LLength > 0 then
                begin
                  LTempString := FLines.Items^[FPosition.Text.Line].TextLine;
                  Delete(LTempString, LBeginX, LLength);
                  FLines[FPosition.Text.Line] := LTempString;
                end;
              end
              else
                LLength := 0;
              if LRun^ = TControlCharacters.CarriageReturn then
              begin
                Inc(LRun);
                if LRun^ = TControlCharacters.Linefeed then
                  Inc(LRun);
                Inc(FViewPosition.Row);
              end;
              LStrToDelete := LRun;
            until LRun^ = TControlCharacters.Null;
            if LUndoItem.ChangeSelectionMode = smColumn then
              SetCaretAndSelection(LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
                LUndoItem.ChangeEndPosition)
            else
            begin
              LTextPosition.Char := LUndoItem.ChangeBeginPosition.Char - FTabs.Width;
              LTextPosition.Line := LUndoItem.ChangeBeginPosition.Line;
              SetCaretAndSelection(LTextPosition, LTextPosition,
                GetPosition(LUndoItem.ChangeEndPosition.Char - LLength, LUndoItem.ChangeEndPosition.Line));
            end;
            FUndoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
              LUndoItem.ChangeEndPosition, LUndoItem.ChangeString, LUndoItem.ChangeSelectionMode,
              LUndoItem.ChangeBlockNumber);
          end;
      end;
    finally
      FUndoList.InsideRedo := False;
      if LChangeScrollPastEndOfLine then
        FScroll.SetOption(soPastEndOfLine, False);
      LUndoItem.Free;
      DecPaintLock;
    end;
end;

procedure TCustomTextEditor.ResetCaret;
var
  LCaretStyle: TTextEditorCaretStyle;
  LWidth, LHeight: Integer;
begin
  if FOvertypeMode = omInsert then
    LCaretStyle := FCaret.Styles.Insert
  else
    LCaretStyle := FCaret.Styles.Overwrite;
  LHeight := 1;
  LWidth := 1;
  FCaretHelper.Offset := Point(FCaret.Offsets.Left, FCaret.Offsets.Top);
  case LCaretStyle of
    csHorizontalLine, csThinHorizontalLine:
      begin
        LWidth := FPaintHelper.CharWidth;
        if LCaretStyle = csHorizontalLine then
          LHeight := 2;
        FCaretHelper.Offset.Y := FCaretHelper.Offset.Y + GetLineHeight;
      end;
    csHalfBlock:
      begin
        LWidth := FPaintHelper.CharWidth;
        LHeight := GetLineHeight div 2;
        FCaretHelper.Offset.Y := FCaretHelper.Offset.Y + LHeight;
      end;
    csBlock:
      begin
        LWidth := FPaintHelper.CharWidth;
        LHeight := GetLineHeight;
      end;
    csVerticalLine, csThinVerticalLine:
      begin
        if LCaretStyle = csVerticalLine then
          LWidth := 2;
        LHeight := GetLineHeight;
      end;
  end;

  Exclude(FState.Flags, sfCaretVisible);

  if Focused or FCaretHelper.ShowAlways then
  begin
    CreateCaret(Handle, 0, LWidth, LHeight);
    UpdateCaret;
  end;
end;

procedure TCustomTextEditor.ScanMatchingPair;
var
  LOpenLineText: string;
  LLine, LTempPosition: Integer;
  LViewPosition: TTextEditorViewPosition;
  LFoldRange: TTextEditorCodeFoldingRange;
  LLineText: string;
begin
  if not FHighlighter.MatchingPairHighlight then
    Exit;

  LViewPosition := ViewPosition;
  FMatchingPair.Current := GetMatchingToken(LViewPosition, FMatchingPair.CurrentMatch);
  if mpoHighlightAfterToken in FMatchingPairs.Options then
    if (FMatchingPair.Current = trNotFound) and (LViewPosition.Column > 1) then
    begin
      Dec(LViewPosition.Column);
      FMatchingPair.Current := GetMatchingToken(LViewPosition, FMatchingPair.CurrentMatch);
    end;

  if (FMatchingPair.Current = trNotFound) and FHighlighter.MatchingPairHighlight and
    (cfoHighlightMatchingPair in FCodeFolding.Options) then
  begin
    LLine := GetViewTextLineNumber(LViewPosition.Row);
    LFoldRange := CodeFoldingCollapsableFoldRangeForLine(LLine);
    if not Assigned(LFoldRange) then
      LFoldRange := CodeFoldingFoldRangeForLineTo(LLine);

    if Assigned(LFoldRange) and Assigned(LFoldRange.RegionItem) then
      if IsKeywordAtCaretPosition then
      begin
        FMatchingPair.Current := trOpenAndCloseTokenFound;

        LLineText := FLines.ExpandedStrings[LFoldRange.FromLine - 1];

        LOpenLineText := AnsiUpperCase(LLineText);
        LTempPosition := FastPos(LFoldRange.RegionItem.OpenToken, LOpenLineText);

        FMatchingPair.CurrentMatch.OpenToken := System.Copy(LLineText, LTempPosition,
          Length(LFoldRange.RegionItem.OpenToken + LFoldRange.RegionItem.OpenTokenCanBeFollowedBy));
        FMatchingPair.CurrentMatch.OpenTokenPos := GetPosition(LTempPosition, LFoldRange.FromLine - 1);

        LLine := LFoldRange.ToLine;
        LLineText := FLines.ExpandedStrings[LLine - 1];
        LTempPosition := FastPos(LFoldRange.RegionItem.CloseToken, AnsiUpperCase(LLineText));
        FMatchingPair.CurrentMatch.CloseToken := System.Copy(LLineText, LTempPosition,
          Length(LFoldRange.RegionItem.CloseToken));

        if LFoldRange.Collapsed then
          FMatchingPair.CurrentMatch.CloseTokenPos :=
            GetPosition(FMatchingPair.CurrentMatch.OpenTokenPos.Char + Length(FMatchingPair.CurrentMatch.OpenToken) +
            2 { +2 = '..' }, LFoldRange.FromLine - 1)
        else
          FMatchingPair.CurrentMatch.CloseTokenPos := GetPosition(LTempPosition, LLine - 1)
      end;
  end;
end;

procedure TCustomTextEditor.SetAlwaysShowCaret(const AValue: Boolean);
begin
  if FCaretHelper.ShowAlways <> AValue then
  begin
    FCaretHelper.ShowAlways := AValue;
    if not (csDestroying in ComponentState) and not Focused then
    begin
      if AValue then
        ResetCaret
      else
      begin
        HideCaret;
        Winapi.Windows.DestroyCaret;
      end;
    end;
  end;
end;

procedure TCustomTextEditor.SetViewPosition(const AValue: TTextEditorViewPosition);
var
  LLength: Integer;
  LTextPosition: TTextEditorTextPosition;
  LValue: TTextEditorViewPosition;
begin
  LValue := AValue;

  if LValue.Row < 1 then
    LValue.Row := 1
  else
  if LValue.Row > FLineNumbers.Count then
  begin
    LValue.Row := Max(FLineNumbers.Count, 1);
    LValue.Column := Length(FLines[GetViewTextLineNumber(LValue.Row) - 1]) + 1;
  end;

  if LValue.Column < 1 then
    LValue.Column := 1
  else
  if not (soPastEndOfLine in FScroll.Options) then
  begin
    LLength := Length(FLines[GetViewTextLineNumber(LValue.Row) - 1]);
    LTextPosition := ViewToTextPosition(LValue);
    if LTextPosition.Char > LLength then
    begin
      LTextPosition.Char := LLength + 1;
      LValue.Column := TextToViewPosition(LTextPosition).Column;
    end;
  end;

  IncPaintLock;
  try
    FViewPosition.Column := LValue.Column;
    FViewPosition.Row := LValue.Row;

    EnsureCursorPositionVisible;

    Include(FState.Flags, sfCaretChanged);
  finally
    DecPaintLock;
  end;

  if FWordWrap.Active then
    FPosition.Text := TextPosition
  else
  begin
    FPosition.Text.Char := LValue.Column;
    FPosition.Text.Line := LValue.Row - 1;
  end;
end;

procedure TCustomTextEditor.SetName(const AValue: TComponentName);
var
  LTextToName: Boolean;
begin
  LTextToName := (ComponentState * [csDesigning, csLoading] = [csDesigning]) and (TextEditor.Utils.TrimRight(Text) = Name);

  inherited SetName(AValue);

  if LTextToName then
    Text := AValue;
end;

procedure TCustomTextEditor.SetReadOnly(const AValue: Boolean);
begin
  if FState.ReadOnly <> AValue then
    FState.ReadOnly := AValue;
end;

procedure TCustomTextEditor.SetSelectedTextEmpty(const AChangeString: string = '');
var
  LSelectionBeginPosition: TTextEditorTextPosition;
  LTextPosition: TTextEditorTextPosition;
begin
  LSelectionBeginPosition := SelectionBeginPosition;

  FUndoList.AddChange(crDelete, TextPosition, LSelectionBeginPosition, SelectionEndPosition, GetSelectedText,
    FSelection.ActiveMode);

  DoSelectedText(AChangeString);

  LTextPosition := TextPosition;

  if AChangeString <> '' then
    FUndoList.AddChange(crInsert, LSelectionBeginPosition, LSelectionBeginPosition, LTextPosition, '', smNormal);

  FPosition.BeginSelection := LTextPosition;
  FPosition.EndSelection := LTextPosition;

  EnsureCursorPositionVisible;
end;

procedure TCustomTextEditor.DoSelectedText(const AValue: string);
begin
  DoSelectedText(FSelection.ActiveMode, PChar(AValue), True, TextPosition);
end;

procedure TCustomTextEditor.DoSelectedText(const APasteMode: TTextEditorSelectionMode; const AValue: PChar;
  const AAddToUndoList: Boolean; const ATextPosition: TTextEditorTextPosition; const AChangeBlockNumber: Integer = 0);
var
  LBeginTextPosition, LEndTextPosition: TTextEditorTextPosition;
  LTextPosition: TTextEditorTextPosition;
  LTempString: string;
  LDeleteSelection: Boolean;

  procedure DeleteSelection;
  var
    LLine: Integer;
    LFirstLine, LLastLine, LCurrentLine: Integer;
    LDeletePosition, LViewDeletePosition, LDeletePositionEnd, LViewDeletePositionEnd: Integer;
  begin
    FLines.BeginUpdate;
    case FSelection.ActiveMode of
      smNormal:
        begin
          if FLines.Count > 0 then
          begin
            LTempString := Copy(FLines[LBeginTextPosition.Line], 1, LBeginTextPosition.Char - 1) +
              Copy(FLines[LEndTextPosition.Line], LEndTextPosition.Char, MaxInt);
            FLines.DeleteLines(LBeginTextPosition.Line, Min(LEndTextPosition.Line - LBeginTextPosition.Line,
              FLines.Count - LBeginTextPosition.Line));
            FLines[LBeginTextPosition.Line]  := LTempString;
          end;
        end;
      smColumn:
        begin
          if LBeginTextPosition.Char > LEndTextPosition.Char then
            SwapInt(LBeginTextPosition.Char, LEndTextPosition.Char);

          with TextToViewPosition(LBeginTextPosition) do
          begin
            LFirstLine := Row;
            LViewDeletePosition := Column;
          end;

          with TextToViewPosition(LEndTextPosition) do
          begin
            LLastLine := Row;
            LViewDeletePositionEnd := Column;
          end;

          for LLine := LFirstLine to LLastLine do
          begin
            with ViewToTextPosition(GetViewPosition(LViewDeletePosition, LLine)) do
            begin
              LDeletePosition := Char;
              LCurrentLine := Line;
            end;

            LDeletePositionEnd := ViewToTextPosition(GetViewPosition(LViewDeletePositionEnd, LLine)).Char;
            LTempString := FLines[LCurrentLine];
            Delete(LTempString, LDeletePosition, LDeletePositionEnd - LDeletePosition);
            FLines[LCurrentLine] := LTempString;
          end;
        end;
    end;
    FLines.EndUpdate;
  end;

  procedure InsertText;

    function CountLines(const APText: PChar): Integer;
    var
      LPText: PChar;
    begin
      Result := 0;

      LPText := APText;
      while LPText^ <> TControlCharacters.Null do
      begin
        if LPText^ = TControlCharacters.CarriageReturn then
          Inc(LPText);
        if LPText^ = TControlCharacters.Linefeed then
          Inc(LPText);
        Inc(Result);
        LPText := GetEndOfLine(LPText);
      end;
    end;

    function InsertNormal: Integer;
    var
      LTextLine, LTextLineStart: Integer;
      LLeftSide: string;
      LRightSide: string;
      LLine: string;
      LPStart: PChar;
      LPText: PChar;
      LLength, LCharCount: Integer;
      LSpaces: string;
      LBeginPosition, LEndPosition: TTextEditorTextPosition;
      LLineText: string;
    begin
      Result := 0;

      LLeftSide := Copy(FLines[LTextPosition.Line], 1, LTextPosition.Char - 1);
      LLength := Length(LLeftSide);

      if LTextPosition.Char > LLength + 1 then
      begin
        LCharCount := LTextPosition.Char - LLength - 1;
        if toTabsToSpaces in FTabs.Options then
          LSpaces := StringOfChar(TCharacters.Space, LCharCount)
        else
        if AllWhiteUpToTextPosition(LTextPosition, LLeftSide, LLength) then
          LSpaces := StringOfChar(TControlCharacters.Tab, LCharCount div FTabs.Width) +
            StringOfChar(TCharacters.Space, LCharCount mod FTabs.Width)
        else
          LSpaces := StringOfChar(TCharacters.Space, LCharCount);
        LLeftSide := LLeftSide + LSpaces;

        LEndPosition := LTextPosition;
        LBeginPosition := LEndPosition;
        Dec(LBeginPosition.Char);
        Dec(LBeginPosition.Char, Length(LSpaces) - 1);
        FUndoList.AddChange(crInsert, LTextPosition, LBeginPosition, LEndPosition, '', smNormal);
      end;
      LLineText := FLines[LTextPosition.Line];
      LRightSide := Copy(LLineText, LTextPosition.Char, Length(LLineText) - (LTextPosition.Char - 1));

      FLines.BeginUpdate;

      { Insert the first line of Value into current line }
      LPStart := PChar(AValue);
      LPText := GetEndOfLine(LPStart);
      if LPText^ <> TControlCharacters.Null then
      begin
        LLine := LLeftSide + Copy(AValue, 1, LPText - LPStart);
        FLines[LTextPosition.Line] := LLine;
        FLines.InsertLines(LTextPosition.Line + 1, CountLines(LPText), True);
      end
      else
      begin
        LLine := LLeftSide + AValue + LRightSide;
        FLines[LTextPosition.Line] := LLine;
      end;

      { Insert left lines of Value }
      LTextLineStart := LTextPosition.Line;
      LTextLine := LTextLineStart + 1;
      while LPText^ <> TControlCharacters.Null do
      begin
        if LPText^ = TControlCharacters.CarriageReturn then
          Inc(LPText);
        if LPText^ = TControlCharacters.Linefeed then
          Inc(LPText);

        LPStart := LPText;
        LPText := GetEndOfLine(LPStart);
        if LPText = LPStart then
        begin
          if LPText^ = TControlCharacters.Null then
            LLine := LRightSide
          else
            LLine := ''
        end
        else
        begin
          SetString(LLine, LPStart, LPText - LPStart);
          if LPText^ = TControlCharacters.Null then
            LLine := LLine + LRightSide
        end;

        FLines[LTextLine] := LLine;

        Inc(Result);
        Inc(LTextLine);
      end;

      FLines.EndUpdate;

      LTextPosition := GetPosition(Length(FLines[LTextLine - 1]) - Length(LRightSide) + 1, LTextLine - 1);

      SelectionBeginPosition := GetPosition(Length(LLeftSide) + 1, LTextLineStart);
      SelectionEndPosition := LTextPosition;
    end;

    function InsertColumn: Integer;
    var
      LStr: string;
      LPStart: PChar;
      LPText: PChar;
      LLength: Integer;
      LCurrentLine: Integer;
      LInsertPosition: Integer;
      LLineBreakPosition: TTextEditorTextPosition;
    begin
      Result := 0;

      LCurrentLine := LTextPosition.Line;

      FLines.BeginUpdate;

      LPStart := PChar(AValue);
      repeat
        LInsertPosition := LTextPosition.Char;

        LPText := GetEndOfLine(LPStart);
        if LPText <> LPStart then
        begin
          SetLength(LStr, LPText - LPStart);
          Move(LPStart^, LStr[1], (LPText - LPStart) * SizeOf(Char));

          if LCurrentLine > FLines.Count then
          begin
            Inc(Result);

            if LPText - LPStart > 0 then
            begin
              LLength := LInsertPosition - 1;

              if toTabsToSpaces in FTabs.Options then
                LTempString := StringOfChar(TCharacters.Space, LLength)
              else
                LTempString := StringOfChar(TControlCharacters.Tab, LLength div FTabs.Width) +
                  StringOfChar(TCharacters.Space, LLength mod FTabs.Width);

              LTempString := LTempString + LStr;
            end
            else
              LTempString := '';

            FLines.Add('');

            { Reflect changes in undo list }
            if AAddToUndoList then
            begin
              with LLineBreakPosition do
              begin
                Line := LCurrentLine;
                Char := Length(FLines[LCurrentLine - 1]) + 1;
              end;
              FUndoList.AddChange(crLineBreak, LLineBreakPosition, LLineBreakPosition, LLineBreakPosition, '', smNormal,
                AChangeBlockNumber);
            end;
          end
          else
          begin
            LTempString := FLines[LCurrentLine];
            LLength := Length(LTempString);

            if (LLength > 0) and (LLength < LInsertPosition) and (LPText - LPStart > 0) then
              LTempString := LTempString + StringOfChar(TCharacters.Space, LInsertPosition - LLength - 1) + LStr
            else
              Insert(LStr, LTempString, LInsertPosition);
          end;

          FLines[LCurrentLine] := LTempString;

          if AAddToUndoList then
            FUndoList.AddChange(crInsert, LTextPosition, GetPosition(LTextPosition.Char, LCurrentLine),
              GetPosition(LTextPosition.Char + (LPText - LPStart), LCurrentLine), '', FSelection.ActiveMode,
              AChangeBlockNumber);
        end;

        if (LPText^ = TControlCharacters.CarriageReturn) or (LPText^ = TControlCharacters.Linefeed) then
        begin
          Inc(LPText);

          if LPText^ = TControlCharacters.Linefeed then
            Inc(LPText);

          Inc(LCurrentLine);
          Inc(LTextPosition.Line);
        end;
        LPStart := LPText;
      until LPText^ = TControlCharacters.Null;

      FLines.EndUpdate;

      Inc(LTextPosition.Char, Length(LStr));
    end;

  var
    LLine, LBeginLine: Integer;
    LInsertedLines: Integer;
  begin
    try
      if Length(AValue) = 0 then
      begin
        LTextPosition := LBeginTextPosition;
        Exit;
      end;

      if GetSelectionAvailable then
        LTextPosition := LBeginTextPosition;

      LBeginLine := LTextPosition.Line;
      case APasteMode of
        smNormal:
          LInsertedLines := InsertNormal;
        smColumn:
          LInsertedLines := InsertColumn;
      else
        LInsertedLines := 0;
      end;

      if (LInsertedLines > 0) and (eoTrimTrailingSpaces in Options) then
      for LLine := LBeginLine to LBeginLine + LInsertedLines do
        DoTrimTrailingSpaces(LLine);

      if FWordWrap.Active then
        CreateLineNumbersCache(True);
    finally
      { Force caret reset }
      TextPosition := LTextPosition;
    end;
  end;

begin
  IncPaintLock;
  try
    LTextPosition := ATextPosition;
    LBeginTextPosition := SelectionBeginPosition;
    LEndTextPosition := SelectionEndPosition;
    LDeleteSelection := not IsSamePosition(LBeginTextPosition, LEndTextPosition);

    if LDeleteSelection then
    begin
      DeleteSelection;
      if AValue <> '' then
        LTextPosition := LBeginTextPosition
      else
        TextPosition := LBeginTextPosition;
    end;

    if AValue <> '' then
      InsertText;
  finally
    DecPaintLock;
  end;
end;

procedure TCustomTextEditor.SetWantReturns(const AValue: Boolean);
begin
  FState.WantReturns := AValue;
end;

procedure TCustomTextEditor.ShowCaret;
begin
  if FCaret.Visible and not FCaret.NonBlinking.Active and not (sfCaretVisible in FState.Flags) then
    if Winapi.Windows.ShowCaret(Handle) then
      Include(FState.Flags, sfCaretVisible);
end;

procedure TCustomTextEditor.UndoItem;
var
  LUndoItem: TTextEditorUndoItem;
  LTempPosition: TTextEditorTextPosition;
  LTempText: string;
  LChangeScrollPastEndOfLine: Boolean;
  LBeginX: Integer;
begin
  LChangeScrollPastEndOfLine := not (soPastEndOfLine in FScroll.Options);
  LUndoItem := FUndoList.PopItem;
  if Assigned(LUndoItem) then
  try
    FSelection.ActiveMode := LUndoItem.ChangeSelectionMode;
    IncPaintLock;

    if LChangeScrollPastEndOfLine then
      FScroll.SetOption(soPastEndOfLine, True);

    case LUndoItem.ChangeReason of
      crCaret:
        begin
          FRedoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition, '', FSelection.ActiveMode, LUndoItem.ChangeBlockNumber);
          TextPosition := LUndoItem.ChangeCaretPosition;
          SelectionBeginPosition := LUndoItem.ChangeBeginPosition;
          SelectionEndPosition := LUndoItem.ChangeEndPosition;
        end;
      crSelection:
        begin
          FRedoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition, '', LUndoItem.ChangeSelectionMode, LUndoItem.ChangeBlockNumber);
          SetCaretAndSelection(LUndoItem.ChangeBeginPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeBeginPosition);
        end;
      crInsert, crPaste, crDragDropInsert:
        begin
          SetCaretAndSelection(LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition, LUndoItem.ChangeEndPosition);
          LTempText := SelectedText;
          DoSelectedText(LUndoItem.ChangeSelectionMode, PChar(LUndoItem.ChangeString), False,
            LUndoItem.ChangeBeginPosition, LUndoItem.ChangeBlockNumber);
          FRedoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition, LTempText, LUndoItem.ChangeSelectionMode, LUndoItem.ChangeBlockNumber);
        end;
      crDelete:
        begin
          LTempPosition := LUndoItem.ChangeBeginPosition;

          while LTempPosition.Line > FLines.Count do
          begin
            LTempPosition := GetPosition(1, FLines.Count);
            FLines.Add('');
          end;

          FPosition.BeginSelection := LUndoItem.ChangeBeginPosition;
          FPosition.EndSelection := FPosition.BeginSelection;

          DoSelectedText(LUndoItem.ChangeSelectionMode, PChar(LUndoItem.ChangeString), False,
            LUndoItem.ChangeBeginPosition, LUndoItem.ChangeBlockNumber);

          FRedoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition, '', LUndoItem.ChangeSelectionMode, LUndoItem.ChangeBlockNumber);

          SetCaretAndSelection(LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition, LUndoItem.ChangeEndPosition);

          EnsureCursorPositionVisible;
        end;
      crLineBreak:
        begin
          TextPosition := LUndoItem.ChangeCaretPosition;

          LTempText := FLines.Strings[LUndoItem.ChangeBeginPosition.Line];
          if (LUndoItem.ChangeBeginPosition.Char - 1 > Length(LTempText)) and
            (LeftSpaceCount(LUndoItem.ChangeString) = 0) then
            LTempText := LTempText + StringOfChar(TCharacters.Space, LUndoItem.ChangeBeginPosition.Char - 1 -
              Length(LTempText));
          SetLine(LUndoItem.ChangeBeginPosition.Line, LTempText + LUndoItem.ChangeString);
          FLines.Delete(LUndoItem.ChangeEndPosition.Line);

          FRedoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition, '', LUndoItem.ChangeSelectionMode, LUndoItem.ChangeBlockNumber);
        end;
      crIndent:
        begin
          SetCaretAndSelection(LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition);
          FRedoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition, LUndoItem.ChangeString, LUndoItem.ChangeSelectionMode,
            LUndoItem.ChangeBlockNumber);
        end;
      crUnindent:
        begin
          if LUndoItem.ChangeSelectionMode = smColumn then
          begin
            LBeginX := Min(LUndoItem.ChangeBeginPosition.Char, LUndoItem.ChangeEndPosition.Char);
            InsertBlock(GetPosition(LBeginX, LUndoItem.ChangeBeginPosition.Line),
              GetPosition(LBeginX, LUndoItem.ChangeEndPosition.Line), PChar(LUndoItem.ChangeString), False);
          end
          else
            InsertBlock(GetPosition(1, LUndoItem.ChangeBeginPosition.Line),
              GetPosition(1, LUndoItem.ChangeEndPosition.Line), PChar(LUndoItem.ChangeString), False);
          FRedoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition, LUndoItem.ChangeString, LUndoItem.ChangeSelectionMode,
            LUndoItem.ChangeBlockNumber);
        end;
    end;
  finally
    if LChangeScrollPastEndOfLine then
      FScroll.SetOption(soPastEndOfLine, False);
    LUndoItem.Free;
    DecPaintLock;
  end;
end;

procedure TCustomTextEditor.UpdateMouseCursor;
var
  LCursorPoint: TPoint;
  LTextPosition: TTextEditorTextPosition;
  LNewCursor: TCursor;
  LWidth: Integer;
  LCursorIndex: Integer;
  LMinimapLeft, LMinimapRight: Integer;
  LSelectionAvailable: Boolean;
begin
  Winapi.Windows.GetCursorPos(LCursorPoint);
  LCursorPoint := ScreenToClient(LCursorPoint);

  Inc(LCursorPoint.X, 4);

  LWidth := 0;
  if FMinimap.Align = maLeft then
    Inc(LWidth, FMinimap.GetWidth);
  if FSearch.Map.Align = saLeft then
    Inc(LWidth, FSearch.Map.GetWidth);

  GetMinimapLeftRight(LMinimapLeft, LMinimapRight);

  if FMouse.IsScrolling then
  begin
    LCursorIndex := GetMouseScrollCursorIndex;
    if LCursorIndex = -1 then
      SetCursor(0)
    else
      SetCursor(FMouse.ScrollCursors[LCursorIndex])
  end
  else
  if (LCursorPoint.X > LWidth) and (LCursorPoint.X < LWidth + FLeftMargin.GetWidth + FCodeFolding.GetWidth) then
    SetCursor(Screen.Cursors[FLeftMargin.Cursor])
  else
  if FMinimap.Visible and (LCursorPoint.X > LMinimapLeft) and (LCursorPoint.X < LMinimapRight) then
    SetCursor(Screen.Cursors[FMinimap.Cursor])
  else
  if FSearch.Map.Visible and ((FSearch.Map.Align = saRight) and
    (LCursorPoint.X > Width - FSearch.Map.GetWidth) or (FSearch.Map.Align = saLeft) and
    (LCursorPoint.X <= FSearch.Map.GetWidth)) then
    SetCursor(Screen.Cursors[FSearch.Map.Cursor])
  else
  begin
    LSelectionAvailable := GetSelectionAvailable;
    if LSelectionAvailable then
      LTextPosition := PixelsToTextPosition(LCursorPoint.X, LCursorPoint.Y);
    if (eoDragDropEditing in FOptions) and not MouseCapture and LSelectionAvailable and
      IsTextPositionInSelection(LTextPosition) then
      LNewCursor := crArrow
    else
    if FRightMargin.Moving or FRightMargin.MouseOver then
      LNewCursor := FRightMargin.Cursor
    else
    if FRuler.Visible and (LCursorPoint.Y < FRuler.Height) then
      LNewCursor := FRuler.Cursor
    else
    if FMouse.OverURI then
      LNewCursor := crHandPoint
    else
    if FCodeFolding.MouseOverHint then
      LNewCursor := FCodeFolding.Hint.Cursor
    else
      LNewCursor := Cursor;
    FKeyboardHandler.ExecuteMouseCursor(Self, LTextPosition, LNewCursor);
    SetCursor(Screen.Cursors[LNewCursor]);
  end;
end;

{ Public declarations }

function TCustomTextEditor.CanFocus: Boolean;
begin
  if csDesigning in ComponentState then
    Result := False
  else
    Result := inherited CanFocus;
end;

function TCustomTextEditor.CaretInView: Boolean;
var
  LCaretPoint: TPoint;
begin
  LCaretPoint := ViewPositionToPixels(ViewPosition);
  Result := PtInRect(ClientRect, LCaretPoint);
end;

function TCustomTextEditor.CreateHighlighterStream(const AName: string): TStream;
begin
  Result := nil;
  if Assigned(FEvents.OnCreateHighlighterStream) then
    FEvents.OnCreateHighlighterStream(Self, AName, Result)
end;

function TCustomTextEditor.ViewToTextPosition(const AViewPosition: TTextEditorViewPosition): TTextEditorTextPosition;
var
  LResultChar, LChar, LPreviousLine, LRow, LCharsBefore: Integer;
  LIsWrapped: Boolean;
  LPLine: PChar;
begin
  Result := TTextEditorTextPosition(AViewPosition);
  Result.Line := GetViewTextLineNumber(Result.Line);

  LIsWrapped := False;

  if FWordWrap.Active then
  begin
    LRow := AViewPosition.Row - 1;
    LPreviousLine := GetViewTextLineNumber(LRow);
    while LPreviousLine = Result.Line do
    begin
      LIsWrapped := True;
      Result.Char := Result.Char + FWordWrapLine.ViewLength[LRow];
      Dec(LRow);
      LPreviousLine := GetViewTextLineNumber(LRow);
    end;

    Result.Char := Min(Result.Char, FLines.ExpandedStringLengths[GetViewTextLineNumber(AViewPosition.Row) - 1] + 1);

    if LIsWrapped then
    begin
      LResultChar := 1;
      LCharsBefore := 0;
      LPLine := PChar(FLines.Items^[Result.Line - 1].TextLine);
      while (LPLine^ <> TControlCharacters.Null) and (LResultChar < Result.Char) do
      begin
        if LPLine^ = TControlCharacters.Tab then
        begin
          if FLines.Columns then
            Dec(Result.Char, FTabs.Width - 1 - LCharsBefore mod FTabs.Width)
          else
            Dec(Result.Char, FTabs.Width - 1);

          if FLines.Columns then
            Inc(LCharsBefore, FTabs.Width - LCharsBefore mod FTabs.Width)
          else
            Inc(LCharsBefore, FTabs.Width)
        end
        else
          Inc(LCharsBefore);

        Inc(LResultChar);
        Inc(LPLine);
      end;
    end;
  end;

  Dec(Result.Line);

  if not LIsWrapped then
  begin
    LPLine := PChar(FLines[Result.Line]);
    LChar := 1;
    LResultChar := 1;
    while LChar < Result.Char do
    begin
      if LPLine^ = TControlCharacters.Null then
        Inc(LChar)
      else
      begin
        if LPLine^ = TControlCharacters.Tab then
        begin
          if FLines.Columns then
            Inc(LChar, FTabs.Width - (LChar - 1) mod FTabs.Width)
          else
            Inc(LChar, FTabs.Width)
        end
        else
          Inc(LChar);

        Inc(LPLine);
      end;
      Inc(LResultChar);
    end;

    while (LPLine^ <> TControlCharacters.Null) and IsCombiningCharacter(LPLine) do
    begin
      Inc(LResultChar);
      Inc(LPLine);
    end;

    Result.Char := LResultChar;
  end;
end;

function TCustomTextEditor.FindPrevious(const AHandleNotFound: Boolean = True): Boolean;
var
  LItemIndex: Integer;
  LSearchItem: PTextEditorSearchItem;
begin
  Result := False;

  LItemIndex := FSearch.GetPreviousSearchItemIndex(TextPosition);
  if LItemIndex = -1 then
  begin
    if not AHandleNotFound or AHandleNotFound and (FSearch.SearchText = '') then
      Exit;

    if soBeepIfStringNotFound in FSearch.Options then
      Beep;

    if FSearch.Items.Count = 0 then
    begin
      if soShowSearchStringNotFound in FSearch.Options then
        DoSearchStringNotFoundDialog;
    end
    else
    if soWrapAround in FSearch.Options then
    begin
      MoveCaretToEnd;
      Result := FindPrevious;
    end
  end
  else
  begin
    LSearchItem := PTextEditorSearchItem(FSearch.Items.Items[LItemIndex]);

    if LSearchItem.BeginTextPosition.Line < FLineNumbers.TopLine then
      GoToLineAndCenter(LSearchItem.BeginTextPosition.Line, LSearchItem.BeginTextPosition.Char)
    else
      TextPosition := LSearchItem.BeginTextPosition;

    SelectionBeginPosition := LSearchItem.BeginTextPosition;
    SelectionEndPosition := LSearchItem.EndTextPosition;

    Result := True;
  end;
end;

function TCustomTextEditor.FindNext(const AHandleNotFound: Boolean = True): Boolean;
var
  LItemIndex: Integer;
  LSearchItem: PTextEditorSearchItem;
begin
  Result := False;

  LItemIndex := FSearch.GetNextSearchItemIndex(TextPosition);
  if LItemIndex = -1 then
  begin
    if not AHandleNotFound or AHandleNotFound and (FSearch.SearchText = '') then
      Exit;

    if (soBeepIfStringNotFound in FSearch.Options) and not (soWrapAround in FSearch.Options) then
      Beep;

    if FSearch.Items.Count = 0 then
    begin
      if soShowSearchStringNotFound in FSearch.Options then
        DoSearchStringNotFoundDialog;
    end
    else
    if (soWrapAround in FSearch.Options) or
      (soShowSearchMatchNotFound in FSearch.Options) and DoSearchMatchNotFoundWraparoundDialog then
    begin
      MoveCaretToBeginning;
      Result := FindNext;
    end
  end
  else
  begin
    LSearchItem := PTextEditorSearchItem(FSearch.Items.Items[LItemIndex]);

    if LSearchItem.BeginTextPosition.Line >= FLineNumbers.TopLine + VisibleLineCount - 1 then
      GoToLineAndCenter(LSearchItem.EndTextPosition.Line, LSearchItem.EndTextPosition.Char)
    else
      TextPosition := LSearchItem.EndTextPosition;

    SelectionBeginPosition := LSearchItem.BeginTextPosition;
    SelectionEndPosition := LSearchItem.EndTextPosition;

    Result := True;
  end;
end;

{$IFDEF TEXT_EDITOR_SPELL_CHECK}
procedure TCustomTextEditor.SpellCheckFindNextError;
var
  LItemIndex: Integer;
  LTextPosition: TTextEditorTextPosition;
  LWord: string;
begin
  LItemIndex := FSpellCheck.GetNextErrorItemIndex(TextPosition);
  if LItemIndex <> -1 then
  begin
    LTextPosition := PTextEditorTextPosition(FSpellCheck.Items[LItemIndex])^;
    LWord := WordAtTextPosition(LTextPosition);
    TextPosition := GetPosition(LTextPosition.Char + Length(LWord), LTextPosition.Line);

    Invalidate;
    SetFocus;
  end;
end;

procedure TCustomTextEditor.SpellCheckFindPreviousError;
var
  LItemIndex: Integer;
  LTextPosition: TTextEditorTextPosition;
  LWord: string;
begin
  LTextPosition := TextPosition;
  Dec(LTextPosition.Char);
  LWord := WordAtTextPosition(LTextPosition);
  Dec(LTextPosition.Char, Length(LWord));
  LItemIndex := FSpellCheck.GetPreviousErrorItemIndex(LTextPosition);
  if LItemIndex <> -1 then
  begin
    LTextPosition := PTextEditorTextPosition(FSpellCheck.Items[LItemIndex])^;
    LWord := WordAtTextPosition(LTextPosition);
    TextPosition := GetPosition(LTextPosition.Char + Length(LWord), LTextPosition.Line);

    Invalidate;
    SetFocus;
  end;
end;
{$ENDIF}

function TCustomTextEditor.GetCompareLineNumberOffsetCache(const ALine: Integer): Integer;
begin
  Result := 0;
  if (lnoCompareMode in FLeftMargin.LineNumbers.Options) and (ALine >= 1) and (ALine <= Length(FCompareLineNumberOffsetCache)) then
    Result := FCompareLineNumberOffsetCache[ALine];
end;

function TCustomTextEditor.GetBookmark(const AIndex: Integer; var ATextPosition: TTextEditorTextPosition): Boolean;
var
  LBookmark: TTextEditorMark;
begin
  Result := False;

  LBookmark := FBookmarkList.Find(AIndex);
  if Assigned(LBookmark) then
  begin
    ATextPosition.Char := LBookmark.Char;
    ATextPosition.Line := LBookmark.Line;
    Result := True;
  end;
end;

function TCustomTextEditor.GetTextPositionOfMouse(out ATextPosition: TTextEditorTextPosition): Boolean;
var
  LCursorPoint: TPoint;
begin
  Result := False;

  Winapi.Windows.GetCursorPos(LCursorPoint);
  LCursorPoint := ScreenToClient(LCursorPoint);
  if (LCursorPoint.X < 0) or (LCursorPoint.Y < 0) or (LCursorPoint.X > Self.Width) or (LCursorPoint.Y > Self.Height) then
    Exit;
  ATextPosition := PixelsToTextPosition(LCursorPoint.X, LCursorPoint.Y);

  if (ATextPosition.Line = FLines.Count - 1) and (ATextPosition.Char > Length(FLines.Items^[FLines.Count - 1].TextLine)) then
    Exit;

  Result := True;
end;

function TCustomTextEditor.GetWordAtPixels(const X, Y: Integer): string;
begin
  Result := WordAtTextPosition(PixelsToTextPosition(X, Y));
end;

function TCustomTextEditor.IsCommentChar(const AChar: Char): Boolean;
begin
  Result := Assigned(FHighlighter) and (AChar in FHighlighter.Comments.Chars);
end;

function TCustomTextEditor.IsTextPositionInSelection(const ATextPosition: TTextEditorTextPosition): Boolean;
var
  LBeginTextPosition, LEndTextPosition: TTextEditorTextPosition;
begin
  LBeginTextPosition := SelectionBeginPosition;
  LEndTextPosition := SelectionEndPosition;

  if (ATextPosition.Line >= LBeginTextPosition.Line) and (ATextPosition.Line <= LEndTextPosition.Line) and
    not IsSamePosition(LBeginTextPosition, LEndTextPosition) then
  begin
    if FSelection.ActiveMode = smColumn then
    begin
      if LBeginTextPosition.Char > LEndTextPosition.Char then
        Result := (ATextPosition.Char >= LEndTextPosition.Char) and (ATextPosition.Char < LBeginTextPosition.Char)
      else
      if LBeginTextPosition.Char < LEndTextPosition.Char then
        Result := (ATextPosition.Char >= LBeginTextPosition.Char) and (ATextPosition.Char < LEndTextPosition.Char)
      else
        Result := False;
    end
    else
      Result := ((ATextPosition.Line > LBeginTextPosition.Line) or (ATextPosition.Line = LBeginTextPosition.Line) and
        (ATextPosition.Char >= LBeginTextPosition.Char)) and
        ((ATextPosition.Line < LEndTextPosition.Line) or (ATextPosition.Line = LEndTextPosition.Line) and
        (ATextPosition.Char < LEndTextPosition.Char));
  end
  else
    Result := False;
end;

function TCustomTextEditor.ReplaceSelectedText(const AReplaceText: string; const ASearchText: string; const ADeleteLine: Boolean): Boolean;
var
  LOptions: TRegExOptions;
  LReplaceText: string;
begin
  Result := False;

  if not SelectionAvailable then
    Exit;

  LReplaceText := AReplaceText;
  if ADeleteLine then
  begin
    SelectedText := '';
    ExecuteCommand(TKeyCommands.DeleteLine, 'Y', nil);
  end
  else
  case FReplace.Engine of
    seNormal:
      SelectedText := LReplaceText;
    seExtended:
      begin
        LReplaceText := StringReplace(LReplaceText, '\n', FLines.DefaultLineBreak, [rfReplaceAll]);
        LReplaceText := StringReplace(LReplaceText, '\' + FLines.DefaultLineBreak, '\n', [rfReplaceAll]);
        LReplaceText := StringReplace(LReplaceText, '\t', TControlCharacters.Tab, [rfReplaceAll]);
        LReplaceText := StringReplace(LReplaceText, '\' + TControlCharacters.Tab, '\t', [rfReplaceAll]);
        LReplaceText := StringReplace(LReplaceText, '\0', TControlCharacters.Null, [rfReplaceAll]);
        LReplaceText := StringReplace(LReplaceText, '\' + TControlCharacters.Null, '\0', [rfReplaceAll]);
        SelectedText := LReplaceText;
      end
    else
      LOptions := [roMultiLine, roNotEmpty];
      if not (roCaseSensitive in FReplace.Options) then
        Include(LOptions, roIgnoreCase);

      SelectedText := TRegEx.Replace(SelectedText, ASearchText, LReplaceText, LOptions);
  end;

  Result := True;
end;

function TCustomTextEditor.ReplaceText(const ASearchText: string; const AReplaceText: string;
  const APageIndex: Integer = -1): Integer;
var
  LPaintLocked: Boolean;
  LPrompt, LReplaceAll, LDeleteLine: Boolean;
  LFound: Boolean;
  LActionReplace: TTextEditorReplaceAction;
  LTextPosition: TTextEditorTextPosition;
  LOriginalTextPosition: TTextEditorTextPosition;
  LItemIndex: Integer;
  LSearchItem: PTextEditorSearchItem;
  LIsWrapAround: Boolean;
  LBackwards: Boolean;

  procedure LockPainting;
  begin
    if not LPaintLocked and LReplaceAll and not LPrompt then
    begin
      IncPaintLock;
      LPaintLocked := True;
    end;
  end;

begin
  if not Assigned(FSearchEngine) then
    raise ETextEditorBaseException.Create(STextEditorSearchEngineNotAssigned);

  Result := 0;
  if Length(ASearchText) = 0 then
    Exit;

  LOriginalTextPosition := TextPosition;

  LBackwards := roBackwards in FReplace.Options;
  LPrompt := roPrompt in FReplace.Options;
  LReplaceAll := roReplaceAll in FReplace.Options;
  LDeleteLine := eraDeleteLine = FReplace.Action;
  LIsWrapAround := soWrapAround in FSearch.Options;

  if LIsWrapAround then
    FSearch.SetOption(soWrapAround, False);

  ClearCodeFolding;
  FState.ReplaceLock := True;

  SearchAll(ASearchText);
  Result := FSearch.Items.Count - 1;

  if Assigned(FEvents.OnReplaceSearchCount) then
    FEvents.OnReplaceSearchCount(Self, Result, APageIndex);

  FUndoList.BeginBlock;
  try
    if roEntireScope in FReplace.Options then
    begin
      if LBackwards then
        MoveCaretToEnd
      else
        MoveCaretToBeginning;
    end;

    if SelectionAvailable then
      TextPosition := SelectionBeginPosition;

    LPaintLocked := False;
    LockPainting;

    LActionReplace := raReplaceAll;
    LFound := True;
    while LFound do
    begin
      if LBackwards then
        LFound := FindPrevious(False)
      else
        LFound := FindNext(False);

      if not LFound then
        Exit;

      if LPrompt and Assigned(FEvents.OnReplaceText) then
      begin
        LTextPosition := TextPosition;
        LActionReplace := DoOnReplaceText(ASearchText, AReplaceText, LTextPosition.Line, LTextPosition.Char, LDeleteLine);

        if LActionReplace = raCancel then
          Exit(-9);

        if LActionReplace = raReplaceAll then
        begin
          SearchAll(ASearchText);

          LOriginalTextPosition := LTextPosition;
          Dec(LOriginalTextPosition.Char);
          LOriginalTextPosition.Char := Max(LOriginalTextPosition.Char, 1);
        end;
      end;

      if LActionReplace = raSkip then
      begin
        Dec(Result);
        Continue
      end
      else
      if LActionReplace = raReplaceAll then
      begin
        LockPainting;

        FLast.DeletedLine := -1;
        for LItemIndex := FSearch.Items.Count - 1 downto 0 do
        begin
          LSearchItem := PTextEditorSearchItem(FSearch.Items.Items[LItemIndex]);

          if not (roEntireScope in FReplace.Options) or LPrompt then
            if LBackwards and (
              (LSearchItem.BeginTextPosition.Line > LOriginalTextPosition.Line) or
              (LSearchItem.BeginTextPosition.Line = LOriginalTextPosition.Line) and
              (LSearchItem.BeginTextPosition.Char > LOriginalTextPosition.Char)
              )
              or
              not LBackwards and (
             (LSearchItem.BeginTextPosition.Line < LOriginalTextPosition.Line) or
              (LSearchItem.BeginTextPosition.Line = LOriginalTextPosition.Line) and
              (LSearchItem.BeginTextPosition.Char < LOriginalTextPosition.Char)
              ) then
              Continue;

          SelectionBeginPosition := LSearchItem.BeginTextPosition;
          SelectionEndPosition := LSearchItem.EndTextPosition;

          if not LDeleteLine or LDeleteLine and (FLast.DeletedLine <> LSearchItem.BeginTextPosition.Line) then
            ReplaceSelectedText(AReplaceText, ASearchText, LDeleteLine);

          FLast.DeletedLine := LSearchItem.BeginTextPosition.Line;
        end;

        Exit;
      end;

      ReplaceSelectedText(AReplaceText, ASearchText, LDeleteLine);

      if (LActionReplace = raReplace) and LPrompt then
        SearchAll(ASearchText);

      if (LActionReplace = raReplace) and not LPrompt then
        Exit;
    end;
  finally
    FSearch.ClearItems;
    if LIsWrapAround then
      FSearch.SetOption(soWrapAround, True);
    FUndoList.EndBlock;
    FState.ReplaceLock := False;
    if LPaintLocked then
      DecPaintLock;

    InitCodeFolding;

    SelectionEndPosition := SelectionBeginPosition;

    EnsureCursorPositionVisible;

    Invalidate;
    SetFocus;
  end;
end;

function TCustomTextEditor.SearchStatus: string;
begin
  Result := FSearchEngine.Status;
end;

procedure TCustomTextEditor.SplitTextIntoWords(const AItems: TTextEditorCompletionProposalItems; const AAddDescription: Boolean = False);
var
  LIndex, Line: Integer;
  LWord: string;
  LPText, LPKeyWord, LPBookmarkText: PChar;
  LOpenTokenSkipFoldRangeList: TList;
  LSkipOpenKeyChars, LSkipCloseKeyChars: TTextEditorCharSet;
  LSkipRegionItem: TTextEditorSkipRegionItem;

  procedure AddKeyChars;
  var
    LIndex: Integer;

    procedure Add(var AKeyChars: TTextEditorCharSet; APKey: PChar);
    begin
      while APKey^ <> TControlCharacters.Null do
      begin
        AKeyChars := AKeyChars + [APKey^];
        Inc(APKey);
      end;
    end;

  begin
    LSkipOpenKeyChars := [];
    LSkipCloseKeyChars := [];

    for LIndex := 0 to FHighlighter.CompletionProposalSkipRegions.Count - 1 do
    begin
      LSkipRegionItem := FHighlighter.CompletionProposalSkipRegions[LIndex];
      Add(LSkipOpenKeyChars, PChar(LSkipRegionItem.OpenToken));
      Add(LSkipCloseKeyChars, PChar(LSkipRegionItem.CloseToken));
    end;
  end;

  procedure AddKeyword(const AKeyword: string);
  var
    LItem: TTextEditorCompletionProposalItem;
  begin
    LItem.Keyword := AKeyword;
    if AAddDescription then
      LItem.Description := STextEditorText
    else
      LItem.Description := '';
    LItem.SnippetIndex := -1;

    if not CompletionProposalItemFound(AItems, LItem) then
      AItems.Add(LItem);
  end;

begin
  AddKeyChars;
  LOpenTokenSkipFoldRangeList := TList.Create;
  try
    for Line := 0 to FLines.Count - 1 do
    begin
      LPText := PChar(FLines.Items^[Line].TextLine);
      LWord := '';
      while LPText^ <> TControlCharacters.Null do
      begin
        { Skip regions - Close }
        if (LOpenTokenSkipFoldRangeList.Count > 0) and (LPText^ in LSkipCloseKeyChars) then
        begin
          LPKeyWord := PChar(TTextEditorSkipRegionItem(LOpenTokenSkipFoldRangeList.Last).CloseToken);
          LPBookmarkText := LPText;
          { Check if the close keyword found }
          while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and
            (LPText^ = LPKeyWord^) do
          begin
            Inc(LPText);
            Inc(LPKeyWord);
          end;

          if LPKeyWord^ = TControlCharacters.Null then { If found, pop skip region from the list }
          begin
            LOpenTokenSkipFoldRangeList.Delete(LOpenTokenSkipFoldRangeList.Count - 1);
            Continue; { while LPText^ <> TControlCharacters.Null do }
          end
          else
            LPText := LPBookmarkText; { Skip region close not found, return pointer back }
        end;

        { Skip regions - Open }
        if LPText^ in LSkipOpenKeyChars then
        for LIndex := 0 to FHighlighter.CompletionProposalSkipRegions.Count - 1 do
        begin
          LSkipRegionItem := FHighlighter.CompletionProposalSkipRegions[LIndex];
          if LPText^ = PChar(LSkipRegionItem.OpenToken)^ then { If the first character is a match }
          begin
            LPKeyWord := PChar(LSkipRegionItem.OpenToken);
            LPBookmarkText := LPText;
            { Check if the open keyword found }
            while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and
              (LPText^ = LPKeyWord^) do
            begin
              Inc(LPText);
              Inc(LPKeyWord);
            end;

            if LPKeyWord^ = TControlCharacters.Null then { If found, skip single line comment or push skip region into stack }
            begin
              if LSkipRegionItem.RegionType = ritSingleLineComment then
              { Single line comment skip until next line }
              while LPText^ <> TControlCharacters.Null do
                Inc(LPText)
              else
                LOpenTokenSkipFoldRangeList.Add(LSkipRegionItem);
              Dec(LPText); { The end of the while loop will increase }
              Break; { for LIndex := 0 to TextEditor.Highlighter.CompletionProposalSkipRegions... }
            end
            else
              LPText := LPBookmarkText; { Skip region open not found, return pointer back }
          end;
        end;

        if LOpenTokenSkipFoldRangeList.Count = 0 then
        begin
          if (LWord = '') and (LPText^ in TCharacterSets.Characters + [TCharacters.Underscore]) or
            (LWord <> '') and (LPText^ in TCharacterSets.CharactersandNumbers + [TCharacters.Underscore]) then
            LWord := LWord + LPText^
          else
          begin
            if (LWord <> '') and (Length(LWord) > 1) then
              AddKeyword(LWord);
            LWord := ''
          end;
        end;

        if LPText^ <> TControlCharacters.Null then
          Inc(LPText);
      end;

      if (LWord <> '') and (Length(LWord) > 1) then
        AddKeyword(LWord);
    end;
  finally
    LOpenTokenSkipFoldRangeList.Free;
  end;
end;

procedure TCustomTextEditor.AddHighlighterKeywords(const AItems: TTextEditorCompletionProposalItems; const AAddDescription: Boolean = False);
var
  LIndex: Integer;
  LKeywordStringList: TStringList;
  LKeyword: string;
  LChar: Char;
  LDescription: string;
  LItem: TTextEditorCompletionProposalItem;
begin
  LKeywordStringList := TStringList.Create;
  try
    LDescription := '';
    if AAddDescription then
      LDescription := STextEditorKeyword;

    FHighlighter.GetKeywords(LKeywordStringList);
    for LIndex := 0 to LKeywordStringList.Count - 1 do
    begin
      LKeyword := LKeywordStringList.Strings[LIndex];
      if Length(LKeyword) > 1 then
      begin
        LChar := LKeyword[1];
        if LChar in TCharacterSets.Characters + [TCharacters.Underscore] then
        begin
          case FCompletionProposal.KeywordCase of
            kcUpperCase:
              LKeyword := AnsiUpperCase(LKeyword);
            kcLowerCase:
              LKeyword := AnsiLowerCase(LKeyword);
            kcSentenceCase:
              LKeyword := AnsiUpperCase(LKeyword[1]) + AnsiLowerCase(Copy(LKeyword, 2));
          end;

          LItem.Keyword := LKeyword;
          LItem.Description := LDescription;
          LItem.SnippetIndex := -1;
          if not CompletionProposalItemFound(AItems, LItem) then
            AItems.Add(LItem);
        end;
      end;
    end;
  finally
    LKeywordStringList.Free;
  end;
end;

procedure TCustomTextEditor.AddSnippets(const AItems: TTextEditorCompletionProposalItems; const AAddDescription: Boolean = False);
var
  LIndex: Integer;
  LSnippetItem: TTextEditorCompletionProposalSnippetItem;
  LItem: TTextEditorCompletionProposalItem;
begin
  for LIndex := 0 to FCompletionProposal.Snippets.Items.Count - 1 do
  begin
    LSnippetItem := FCompletionProposal.Snippets.Item[LIndex];
    LItem.Keyword := LSnippetItem.Keyword;
    if AAddDescription then
    begin
      if LSnippetItem.Description = '' then
        LItem.Description := STextEditorSnippet
      else
        LItem.Description := LSnippetItem.Description;
    end
    else
      LItem.Description := '';
    LItem.SnippetIndex := LIndex;
    if not CompletionProposalItemFound(AItems, LItem) then
      AItems.Add(LItem);
  end;
end;

function TCustomTextEditor.TextToViewPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorViewPosition;
var
  LChar: Integer;
  LResultChar, LCurrentChar: Integer;
  LIsWrapped: Boolean;
  LPChar: PChar;
  LWordWrapLineLength: Integer;
  LCharsBefore: Integer;

  function GetWrapLineLength(const ARow: Integer): Integer;
  begin
    if FWordWrapLine.ViewLength[ARow] <> 0 then
      Result := FWordWrapLine.ViewLength[ARow]
    else
      Result := GetVisibleChars(ARow);
  end;

begin
  Result.Column := ATextPosition.Char;
  Result.Row := GetViewLineNumber(ATextPosition.Line + 1);

  LIsWrapped := False;

  if Visible and FWordWrap.Active then
  begin
    LChar := 1;

    LPChar := PChar(FLines[ATextPosition.Line]);
    LCurrentChar := Result.Column;
    LCharsBefore := 0;

    while (LPChar^ <> TControlCharacters.Null) and (LChar < LCurrentChar) do
    begin
      if LPChar^ = TControlCharacters.Tab then
      begin
        if FLines.Columns then
        begin
          Inc(Result.Column, FTabs.Width - 1 - LCharsBefore mod FTabs.Width);
          Inc(LCharsBefore, FTabs.Width - LCharsBefore mod FTabs.Width);
        end
        else
        begin
          Inc(Result.Column, FTabs.Width - 1);
          Inc(LCharsBefore, FTabs.Width);
        end;
      end
      else
        Inc(LCharsBefore);

      Inc(LChar);
      Inc(LPChar);
    end;

    if FScrollHelper.PageWidth > 0 then
    begin
      LWordWrapLineLength := Length(FWordWrapLine.Length);

      if Result.Row >= LWordWrapLineLength then
        Result.Row := LWordWrapLineLength - 1;

      while (Result.Row < LWordWrapLineLength) and (Result.Column - 1 > GetWrapLineLength(Result.Row)) do
      begin
        LIsWrapped := True;
        if FWordWrapLine.ViewLength[Result.Row] <> 0 then
          Dec(Result.Column, FWordWrapLine.ViewLength[Result.Row])
        else
          Result.Column := 1;
        Inc(Result.Row);
      end;
    end;
  end;

  if not LIsWrapped then
  begin
    LPChar := PChar(FLines[ATextPosition.Line]);
    LResultChar := 1;
    LChar := 1;
    while LChar < ATextPosition.Char do
    begin
      if LPChar^ <> TControlCharacters.Null then
      begin
        if LPChar^ = TControlCharacters.Tab then
        begin
          if FLines.Columns then
            Inc(LResultChar, FTabs.Width - (LResultChar - 1) mod FTabs.Width)
          else
            Inc(LResultChar, FTabs.Width)
        end
        else
          Inc(LResultChar);
        Inc(LPChar);
      end
      else
        Inc(LResultChar);
      Inc(LChar);
    end;

    Result.Column := LResultChar;
  end;
end;

function TCustomTextEditor.WordEnd: TTextEditorTextPosition;
begin
  Result := WordEnd(TextPosition);
end;

function TCustomTextEditor.StringWordEnd(const ALine: string; var AStart: Integer): Integer;
var
  LPChar: PChar;
begin
  if (AStart > 0) and (AStart <= Length(ALine)) then
  begin
    LPChar := PChar(@ALine[AStart]);
    repeat
      if IsWordBreakChar((LPChar + 1)^) and not IsWordBreakChar(LPChar^) then
        Exit(AStart + 1);
      Inc(LPChar);
      Inc(AStart);
    until LPChar^ = TControlCharacters.Null;
  end;
  Result := 0;
end;

function TCustomTextEditor.StringWordStart(const ALine: string; var AStart: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  if (AStart > 0) and (AStart <= Length(ALine)) then
  for LIndex := AStart downto 1 do
  if (LIndex - 1 > 0) and IsWordBreakChar(ALine[LIndex - 1]) and not IsWordBreakChar(ALine[LIndex]) then
    Exit(LIndex);
end;

function TCustomTextEditor.WordEnd(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition;
var
  LLine: string;
begin
  Result := ATextPosition;

  if (Result.Char >= 1) and (Result.Line < FLines.Count) then
  begin
    LLine := FLines.Items^[Result.Line].TextLine;
    if Result.Char <= Length(LLine) then
    begin
      Result.Char := StringWordEnd(LLine, Result.Char);
      if Result.Char = 0 then
        Result.Char := Length(LLine) + 1;
    end;
  end;
end;

function TCustomTextEditor.WordStart: TTextEditorTextPosition;
begin
  Result := WordStart(TextPosition);
end;

function TCustomTextEditor.WordStart(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition;
var
  LLine: string;
begin
  Result := ATextPosition;

  if (Result.Line >= 0) and (Result.Line < FLines.Count) then
  begin
    LLine := FLines.Items^[Result.Line].TextLine;
    Result.Char := Min(Result.Char, Length(LLine));
    Result.Char := StringWordStart(LLine, Result.Char);
    if Result.Char = 0 then
      Result.Char := 1;
  end;
end;

procedure TCustomTextEditor.AddCaret(const AViewPosition: TTextEditorViewPosition);

  procedure Add(AViewPosition: TTextEditorViewPosition);
  var
    LIndex: Integer;
    LPViewPosition: PTextEditorViewPosition;
  begin
    for LIndex := 0 to FMultiCaret.Carets.Count - 1 do
    begin
      LPViewPosition := PTextEditorViewPosition(FMultiCaret.Carets[LIndex]);
      if (LPViewPosition^.Row = AViewPosition.Row) and
        (LPViewPosition^.Column = AViewPosition.Column) then
        Exit;
    end;
    New(LPViewPosition);
    LPViewPosition^.Column := AViewPosition.Column;
    LPViewPosition^.Row := AViewPosition.Row;
    FMultiCaret.Carets.Add(LPViewPosition);
  end;

begin
  if AViewPosition.Row > FLineNumbers.Count then
    Exit;

  if not Assigned(FMultiCaret.Carets) then
  begin
    FMultiCaret.Draw := True;
    FMultiCaret.Carets := TList.Create;
    FMultiCaret.Timer := TTextEditorTimer.Create(Self);
    FMultiCaret.Timer.Interval := GetCaretBlinkTime;
    FMultiCaret.Timer.OnTimer := MultiCaretTimerHandler;
    FMultiCaret.Timer.Enabled := True;
  end;

  Add(AViewPosition);
end;

procedure TCustomTextEditor.AddKeyCommand(const ACommand: TTextEditorCommand; const AShift: TShiftState;
  const AKey: Word; const ASecondaryShift: TShiftState = []; const ASecondaryKey: Word = 0);
var
  LKeyCommand: TTextEditorKeyCommand;
begin
  LKeyCommand := KeyCommands.NewItem;
  with LKeyCommand do
  begin
    Command := ACommand;
    Key := AKey;
    SecondaryKey := ASecondaryKey;
    ShiftState := AShift;
    SecondaryShiftState := ASecondaryShift;
  end;
end;

procedure TCustomTextEditor.AddKeyDownHandler(AHandler: TKeyEvent);
begin
  FKeyboardHandler.AddKeyDownHandler(AHandler);
end;

procedure TCustomTextEditor.AddKeyPressHandler(AHandler: TTextEditorKeyPressWEvent);
begin
  FKeyboardHandler.AddKeyPressHandler(AHandler);
end;

procedure TCustomTextEditor.AddKeyUpHandler(AHandler: TKeyEvent);
begin
  FKeyboardHandler.AddKeyUpHandler(AHandler);
end;

procedure TCustomTextEditor.AddMouseCursorHandler(AHandler: TTextEditorMouseCursorEvent);
begin
  FKeyboardHandler.AddMouseCursorHandler(AHandler);
end;

procedure TCustomTextEditor.AddMouseDownHandler(AHandler: TMouseEvent);
begin
  FKeyboardHandler.AddMouseDownHandler(AHandler);
end;

procedure TCustomTextEditor.AddMouseUpHandler(AHandler: TMouseEvent);
begin
  FKeyboardHandler.AddMouseUpHandler(AHandler);
end;

procedure TCustomTextEditor.AddMultipleCarets(const AViewPosition: TTextEditorViewPosition);
var
  LBeginRow, LEndRow, LRow: Integer;
  LViewPosition: TTextEditorViewPosition;
  LPLastCaretPosition: PTextEditorViewPosition;
begin
  LViewPosition := ViewPosition;

  if LViewPosition.Row > FLineNumbers.Count then
    Exit;

  if Assigned(FMultiCaret.Carets) and (FMultiCaret.Carets.Count > 0) then
  begin
    LPLastCaretPosition := PTextEditorViewPosition(FMultiCaret.Carets.Last);
    LBeginRow := LPLastCaretPosition^.Row;
    LViewPosition.Column := LPLastCaretPosition^.Column;
  end
  else
    LBeginRow := LViewPosition.Row;

  LEndRow := AViewPosition.Row;
  if LBeginRow > LEndRow then
    SwapInt(LBeginRow, LEndRow);

  for LRow := LBeginRow to LEndRow do
  begin
    LViewPosition.Row := LRow;
    AddCaret(LViewPosition);
  end;
end;

procedure TCustomTextEditor.BeginUndoBlock;
begin
  FUndoList.BeginBlock;
end;

procedure TCustomTextEditor.BeginUpdate;
begin
  IncPaintLock;
  FLines.BeginUpdate;
end;

procedure TCustomTextEditor.MoveCaretToBeginning;
var
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := GetPosition(1, 0);
  TextPosition := LTextPosition;
  SelectionBeginPosition := LTextPosition;
  SelectionEndPosition := LTextPosition;
end;

procedure TCustomTextEditor.MoveCaretToEnd;
var
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := GetPosition(Length(FLines[LTextPosition.Line]), FLines.Count - 1);
  TextPosition := LTextPosition;
  SelectionBeginPosition := LTextPosition;
  SelectionEndPosition := LTextPosition;
end;

procedure TCustomTextEditor.MoveSelection(const ADirection: TTextEditorMoveDirection);
var
  LIndex: Integer;
  LText, LUndoText, LEmptyText: string;
  LSelectionBeginPosition, LSelectionEndPosition: TTextEditorTextPosition;
  LEmptyBeginPosition, LEmptyEndPosition: TTextEditorTextPosition;
  LTrimTrailingSpaces: Boolean;
  LStringList: TStringList;
  LLength: Integer;
begin
  LSelectionBeginPosition := SelectionBeginPosition;

  if (LSelectionBeginPosition.Line = 0) and (ADirection = mdUp) or
    (LSelectionBeginPosition.Char = 1) and (ADirection = mdLeft) then
    Exit;

  LSelectionEndPosition := SelectionEndPosition;
  LLength := LSelectionEndPosition.Char - LSelectionBeginPosition.Char;

  if LLength < 1 then
    Exit;

  LTrimTrailingSpaces := eoTrimTrailingSpaces in FOptions;
  if LTrimTrailingSpaces then
    FOptions := FOptions - [eoTrimTrailingSpaces];

  LStringList := TStringList.Create;
  try
    LStringList.Text := SelectedText;
    for LIndex := 0 to LStringList.Count - 1 do
    if Length(LStringList[LIndex]) < LLength then
      LStringList[LIndex] := LStringList[LIndex] + StringOfChar(' ', LLength - Length(LStringList[LIndex]));
  finally
    LText := LStringList.Text;
    LStringList.Free;
  end;

  FUndoList.BeginBlock(6);

  FUndoList.AddChange(crCaret, TextPosition, LSelectionBeginPosition, LSelectionEndPosition, '', smColumn);

  case ADirection of
    mdUp:
      begin
        LEmptyBeginPosition := GetPosition(LSelectionBeginPosition.Char, LSelectionEndPosition.Line);
        LEmptyEndPosition := LSelectionEndPosition;
        LEmptyText := StringOfChar(' ', LEmptyEndPosition.Char - LEmptyBeginPosition.Char);
        Dec(LSelectionBeginPosition.Line);
        SelectionBeginPosition := LSelectionBeginPosition;
        SelectionEndPosition := LSelectionEndPosition;
        LUndoText := SelectedText;
        FUndoList.AddChange(crDelete, TextPosition, LSelectionBeginPosition, LSelectionEndPosition, LUndoText, smColumn);
        Dec(LSelectionEndPosition.Line);
      end;
    mdDown:
      begin
        LEmptyBeginPosition := LSelectionBeginPosition;
        LEmptyEndPosition := GetPosition(LSelectionEndPosition.Char, LEmptyBeginPosition.Line);
        LEmptyText := StringOfChar(' ', LEmptyEndPosition.Char - LEmptyBeginPosition.Char);
        Inc(LSelectionEndPosition.Line);
        SelectionBeginPosition := LSelectionBeginPosition;
        SelectionEndPosition := LSelectionEndPosition;
        LUndoText := SelectedText;
        FUndoList.AddChange(crDelete, TextPosition, LSelectionBeginPosition, LSelectionEndPosition, LUndoText, smColumn);
        Inc(LSelectionBeginPosition.Line);
      end;
    mdLeft:
      begin
        LEmptyBeginPosition := GetPosition(LSelectionEndPosition.Char - 1, LSelectionBeginPosition.Line);
        LEmptyEndPosition := LSelectionEndPosition;
        for LIndex := 0 to LEmptyEndPosition.Line - LEmptyBeginPosition.Line - 1 do //FI:W528 Variable not used in FOR-loop
          LEmptyText := ' ' + FLines.DefaultLineBreak;
        LEmptyText := LEmptyText + ' ';
        Dec(LSelectionBeginPosition.Char);
        SelectionBeginPosition := LSelectionBeginPosition;
        SelectionEndPosition := LSelectionEndPosition;
        LUndoText := SelectedText;
        FUndoList.AddChange(crDelete, TextPosition, LSelectionBeginPosition, LSelectionEndPosition, LUndoText, smColumn);
        Dec(LSelectionEndPosition.Char);
      end;
    mdRight:
      begin
        LEmptyBeginPosition := LSelectionBeginPosition;
        LEmptyEndPosition := GetPosition(LSelectionBeginPosition.Char + 1, LSelectionEndPosition.Line);
        for LIndex := 0 to LEmptyEndPosition.Line - LEmptyBeginPosition.Line - 1 do //FI:W528 Variable not used in FOR-loop
          LEmptyText := ' ' + FLines.DefaultLineBreak;
        LEmptyText := LEmptyText + ' ';
        Inc(LSelectionEndPosition.Char);
        SelectionBeginPosition := LSelectionBeginPosition;
        SelectionEndPosition := LSelectionEndPosition;
        LUndoText := SelectedText;
        FUndoList.AddChange(crDelete, TextPosition, LSelectionBeginPosition, LSelectionEndPosition, LUndoText, smColumn);
        Inc(LSelectionBeginPosition.Char);
      end;
  end;
  FUndoList.AddChange(crInsert, TextPosition, LEmptyBeginPosition, LEmptyEndPosition, '', smColumn);
  InsertBlock(LEmptyBeginPosition, LEmptyEndPosition, PChar(LEmptyText), False);

  FUndoList.AddChange(crInsert, TextPosition, LSelectionBeginPosition, LSelectionEndPosition, '', smColumn);
  InsertBlock(LSelectionBeginPosition, LSelectionEndPosition, PChar(LText), False);

  SelectionBeginPosition := LSelectionBeginPosition;
  SelectionEndPosition := LSelectionEndPosition;

  FUndoList.EndBlock;

  if LTrimTrailingSpaces then
    FOptions := FOptions + [eoTrimTrailingSpaces];
end;

procedure TCustomTextEditor.ChainEditor(const AEditor: TCustomTextEditor);
begin
  HookEditorLines(AEditor.FLines, AEditor.UndoList, AEditor.RedoList);
  InitCodeFolding;
  FChainedEditor := AEditor;
  AEditor.FreeNotification(Self);
  UpdateScrollBars;
end;

procedure TCustomTextEditor.Clear;
begin
  FLines.Clear;
  SetHorizontalScrollPosition(0);
  CreateLineNumbersCache(True);
  UpdateScrollBars;
end;

procedure TCustomTextEditor.DeleteBookmark(ABookmark: TTextEditorMark);
begin
  if Assigned(ABookmark) then
  begin
    FBookmarkList.Remove(ABookmark);
    if Assigned(FEvents.OnAfterDeleteBookmark) then
      FEvents.OnAfterDeleteBookmark(Self, ABookmark);
  end;
end;

function TCustomTextEditor.DeleteBookmark(const ALine: Integer; const AIndex: Integer): Boolean;
var
  LIndex: Integer;
  LBookmark: TTextEditorMark;
begin
  Result := False;

  LIndex := 0;
  while LIndex < FBookmarkList.Count do
  begin
    LBookmark := FBookmarkList.Items[LIndex];
    if LBookmark.Line = ALine then
    begin
      if LBookmark.Index = AIndex then
        Result := True;
      DeleteBookmark(LBookmark);
    end
    else
      Inc(LIndex);
  end;
end;

procedure TCustomTextEditor.DeleteMark(AMark: TTextEditorMark);
begin
  if Assigned(AMark) then
  begin
    if Assigned(FEvents.OnBeforeDeleteMark) then
      FEvents.OnBeforeDeleteMark(Self, AMark);

    FMarkList.Remove(AMark);

    if Assigned(FEvents.OnAfterDeleteMark) then
      FEvents.OnAfterDeleteMark(Self);
  end
end;

procedure TCustomTextEditor.ClearBookmarks;
begin
  while FBookmarkList.Count > 0 do
    DeleteBookmark(FBookmarkList[0]);
end;

procedure TCustomTextEditor.ClearMarks;
begin
  while FMarkList.Count > 0 do
    DeleteMark(FMarkList[0]);
end;

procedure TCustomTextEditor.ClearCodeFolding;
begin
  if FState.ReplaceLock then
    Exit;

  FCodeFoldings.AllRanges.ClearAll;

  SetLength(FCodeFoldings.TreeLine, 0);
  SetLength(FCodeFoldings.RangeFromLine, 0);
  SetLength(FCodeFoldings.RangeToLine, 0);
end;

procedure TCustomTextEditor.ClearMatchingPair;
begin
  FMatchingPair.Current := trNotFound;
end;

procedure TCustomTextEditor.ClearSelection;
begin
  if GetSelectionAvailable then
    FPosition.EndSelection := FPosition.BeginSelection
end;

procedure TCustomTextEditor.DeleteSelection;
begin
  if GetSelectionAvailable then
    SelectedText := '';
end;

procedure TCustomTextEditor.ClearUndo;
begin
  FUndoList.Clear;
  FRedoList.Clear;
end;

procedure TCustomTextEditor.FindAll;
var
  LIndex: Integer;
begin
  if not FCaret.MultiEdit.Active then
    Exit;

  for LIndex := 0 to FSearch.Items.Count - 1 do
    AddCaret(TextToViewPosition(PTextEditorSearchItem(FSearch.Items.Items[LIndex])^.EndTextPosition));

  FPosition.EndSelection := FPosition.BeginSelection;

  Invalidate;
  SetFocus;
end;

procedure TCustomTextEditor.CollapseAll(const AFromLineNumber: Integer = -1; const AToLineNumber: Integer = -1);
var
  LIndex: Integer;
  LFromLine, LToLine: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
  LTextPosition: TTextEditorTextPosition;
begin
  if AFromLineNumber = -1 then
    LFromLine := 1
  else
    LFromLine := AFromLineNumber;

  if AToLineNumber = -1 then
    LToLine := FLines.Count
  else
    LToLine := AToLineNumber;

  LTextPosition := TextPosition;
  ClearMatchingPair;
  FLineNumbers.ResetCache := True;

  for LIndex := LFromLine to LToLine do
  begin
    LCodeFoldingRange := FCodeFoldings.RangeFromLine[LIndex];
    if Assigned(LCodeFoldingRange) then
      if not LCodeFoldingRange.Collapsed and LCodeFoldingRange.Collapsable then
      with LCodeFoldingRange do
      begin
        Collapsed := True;
        SetParentCollapsedOfSubCodeFoldingRanges(True, FoldRangeLevel);
      end;
  end;

  CheckIfAtMatchingKeywords;
  UpdateScrollBars;

  if LTextPosition.Line > FLines.Count - 1 then
    LTextPosition.Line := FLines.Count - 1;
  TextPosition := LTextPosition;
end;

procedure TCustomTextEditor.CollapseAllByLevel(const AFromLevel: Integer; const AToLevel: Integer);
var
  LIndex: Integer;
  LLevel, LRangeLevel, LFromLine, LToLine: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
  LTextPosition: TTextEditorTextPosition;
begin
  if SelectionAvailable then
  begin
    LFromLine := SelectionBeginPosition.Line;
    LToLine := SelectionEndPosition.Line;
  end
  else
  begin
    LFromLine := 1;
    LToLine := FLines.Count;
  end;

  LTextPosition := TextPosition;
  ClearMatchingPair;
  FLineNumbers.ResetCache := True;
  LLevel := -1;

  for LIndex := LFromLine to LToLine do
  begin
    LCodeFoldingRange := FCodeFoldings.RangeFromLine[LIndex];
    if Assigned(LCodeFoldingRange) then
    begin
      if LLevel = -1 then
        LLevel := LCodeFoldingRange.FoldRangeLevel;

      LRangeLevel := LCodeFoldingRange.FoldRangeLevel - LLevel;

      if (LRangeLevel >= AFromLevel) and (LRangeLevel <= AToLevel) and not LCodeFoldingRange.Collapsed and
        LCodeFoldingRange.Collapsable then
      with LCodeFoldingRange do
      begin
        Collapsed := True;
        SetParentCollapsedOfSubCodeFoldingRanges(True, FoldRangeLevel);
      end;
    end;
  end;

  CheckIfAtMatchingKeywords;
  UpdateScrollBars;

  if LTextPosition.Line > FLines.Count - 1 then
    LTextPosition.Line := FLines.Count - 1;

  TextPosition := LTextPosition;
end;

procedure TCustomTextEditor.Trim(const ATrimStyle: TTextEditorTrimStyle);
var
  LBeginPosition, LEndPosition: TTextEditorTextPosition;
  LText: string;
  LSelectionAvailable: Boolean;
  LTextPosition, LTempTextPosition: TTextEditorTextPosition;
  LLines: TTextEditorLines;
begin
  LTextPosition := TextPosition;
  LBeginPosition.Line := 0;
  LEndPosition.Line := FLines.Count - 1;
  LText := FLines.Text;
  LSelectionAvailable := GetSelectionAvailable;
  if LSelectionAvailable then
  begin
    LBeginPosition.Line := GetSelectionBeginPosition.Line;
    LEndPosition := GetSelectionEndPosition;
    if LEndPosition.Char = 1 then
      Dec(LEndPosition.Line);
    LText := SelectedText;
  end;
  LBeginPosition.Char := 1;
  LEndPosition.Char := FLines.StringLength(LEndPosition.Line) + 1;

  FUndoList.BeginBlock;

  if FSelection.ActiveMode = smNormal then
  begin
    if not LSelectionAvailable then
      FUndoList.AddChange(crSelection, LTextPosition, LTextPosition, LTextPosition, '', FSelection.ActiveMode);
    FUndoList.AddChange(crDelete, LTextPosition, LBeginPosition, LEndPosition, LText, FSelection.ActiveMode);
    FLines.Trim(ATrimStyle, LBeginPosition.Line, LEndPosition.Line)
  end
  else
  begin
    if not LSelectionAvailable then
      SelectAll;

    LLines := TTextEditorLines.Create(nil);
    try
      LLines.Text := SelectedText;
      LLines.Trim(ATrimStyle, 0, LLines.Count - 1);
      SelectedText := LLines.Text;
    finally
      LLines.Free;
    end;
  end;

  LEndPosition.Char := FLines.StringLength(LEndPosition.Line) + 1;

  if FSelection.ActiveMode = smNormal then
  begin
    FUndoList.AddChange(crInsert, LTextPosition, LBeginPosition, LEndPosition, '', FSelection.ActiveMode);

    if LSelectionAvailable then
    begin
      LTempTextPosition := GetSelectionBeginPosition;
      LTempTextPosition.Char := 1;
      SelectionBeginPosition := LTempTextPosition;
      SelectionEndPosition := LEndPosition;
    end;
  end;

  FUndoList.EndBlock;

  DoChange;

  Invalidate;
end;

procedure TCustomTextEditor.TrimBeginning;
begin
  while FLines.Count > 0 do
  if FLines[0].Trim = '' then
    FLines.Delete(0)
end;

procedure TCustomTextEditor.TrimEnd;
var
  LIndex: Integer;
begin
  for LIndex := FLines.Count - 1 downto 0 do
  if FLines[LIndex].Trim = '' then
    FLines.Delete(LIndex)
  else
    Break;
end;

procedure TCustomTextEditor.ExpandAll(const AFromLineNumber: Integer = -1; const AToLineNumber: Integer = -1);
var
  LIndex: Integer;
  LFromLine, LToLine: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  if AFromLineNumber = -1 then
    LFromLine := 0
  else
    LFromLine := AFromLineNumber;

  if AToLineNumber = -1 then
    LToLine := FLines.Count
  else
    LToLine := AToLineNumber;

  ClearMatchingPair;
  FLineNumbers.ResetCache := True;

  for LIndex := LFromLine to LToLine do
  begin
    LCodeFoldingRange := FCodeFoldings.RangeFromLine[LIndex];
    if Assigned(LCodeFoldingRange) then
      if LCodeFoldingRange.Collapsed and LCodeFoldingRange.Collapsable then
      with LCodeFoldingRange do
      begin
        Collapsed := False;
        SetParentCollapsedOfSubCodeFoldingRanges(False, FoldRangeLevel);
      end;
  end;

  CreateLineNumbersCache(True);

  UpdateScrollBars;
  Invalidate;
end;

procedure TCustomTextEditor.ExpandAllByLevel(const AFromLevel: Integer; const AToLevel: Integer);
var
  LIndex: Integer;
  LLevel, LRangeLevel: Integer;
  LFromLine, LToLine: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  if SelectionAvailable then
  begin
    LFromLine := SelectionBeginPosition.Line;
    LToLine := SelectionEndPosition.Line;
  end
  else
  begin
    LFromLine := 1;
    LToLine := FLines.Count;
  end;

  ClearMatchingPair;
  FLineNumbers.ResetCache := True;
  LLevel := -1;

  for LIndex := LFromLine to LToLine do
  begin
    LCodeFoldingRange := FCodeFoldings.RangeFromLine[LIndex];
    if Assigned(LCodeFoldingRange) then
    begin
      if LLevel = -1 then
        LLevel := LCodeFoldingRange.FoldRangeLevel;

      LRangeLevel := LCodeFoldingRange.FoldRangeLevel - LLevel;

      if (LRangeLevel >= AFromLevel) and (LRangeLevel <= AToLevel) and LCodeFoldingRange.Collapsed and
        LCodeFoldingRange.Collapsable then
      with LCodeFoldingRange do
      begin
        Collapsed := False;
        SetParentCollapsedOfSubCodeFoldingRanges(False, FoldRangeLevel);
      end;
    end;
  end;

  CreateLineNumbersCache(True);

  UpdateScrollBars;
  Invalidate;
end;

procedure TCustomTextEditor.CommandProcessor(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);
var
  LLine, LIndex1, LIndex2, LCollapsedCount: Integer;
  LOldSelectionBeginPosition, LOldSelectionEndPosition: TTextEditorTextPosition;
  LViewPosition: TTextEditorViewPosition;
  LPViewPosition: PTextEditorViewPosition;
  LCommand: TTextEditorCommand;
  LChar: Char;
  LLength: Integer;

  function CodeFoldingExpandLine(const ALine: Integer): Integer;
  var
    LCodeFoldingRange: TTextEditorCodeFoldingRange;
  begin
    Result := 0;

    if ALine < Length(FCodeFoldings.RangeFromLine) then
    begin
      LCodeFoldingRange := FCodeFoldings.RangeFromLine[ALine];

      if Assigned(LCodeFoldingRange) and LCodeFoldingRange.Collapsed then
      begin
        Result := LCodeFoldingRange.ToLine - LCodeFoldingRange.FromLine;
        CodeFoldingExpand(LCodeFoldingRange);
      end;
    end;
  end;

begin
  LCommand := ACommand;
  LChar := AChar;

  { First the program event handler gets a chance to process the command }
  DoOnProcessCommand(LCommand, LChar, AData);

  if LCommand <> TKeyCommands.None then
  begin
    { Notify hooked command handlers before the command is executed inside of the class }
    NotifyHookedCommandHandlers(False, LCommand, LChar, AData);

    if FCodeFolding.Visible then
    begin
      FCodeFoldings.Rescan := (LCommand = TKeyCommands.Cut) or (LCommand = TKeyCommands.Paste) or (LCommand = TKeyCommands.DeleteLine) or
        GetSelectionAvailable and ((LCommand = TKeyCommands.LineBreak) or (LCommand = TKeyCommands.Backspace) or (LCommand = TKeyCommands.Char)) or
        ((LCommand = TKeyCommands.Char) or (LCommand = TKeyCommands.Backspace) or (LCommand = TKeyCommands.Tab) or (LCommand = TKeyCommands.DeleteChar) or
        (LCommand = TKeyCommands.LineBreak)) and IsKeywordAtCaretPosition or
        (LCommand = TKeyCommands.Backspace) and IsCommentAtCaretPosition or
        ((LCommand = TKeyCommands.Char) and (AChar in FHighlighter.SkipOpenKeyChars + FHighlighter.SkipCloseKeyChars));

      case LCommand of
        TKeyCommands.Backspace, TKeyCommands.DeleteChar, TKeyCommands.DeleteWord, TKeyCommands.DeleteWordForward,
          TKeyCommands.DeleteWordBackward, TKeyCommands.DeleteLine, TKeyCommands.Clear, TKeyCommands.LineBreak,
          TKeyCommands.Char, TKeyCommands.Text, TKeyCommands.ImeStr, TKeyCommands.Cut, TKeyCommands.Paste,
          TKeyCommands.BlockIndent, TKeyCommands.BlockUnindent, TKeyCommands.Tab:
          if GetSelectionAvailable then
          begin
            LOldSelectionBeginPosition := GetSelectionBeginPosition;
            LOldSelectionEndPosition := GetSelectionEndPosition;
            LCollapsedCount := 0;
            for LLine := LOldSelectionBeginPosition.Line to LOldSelectionEndPosition.Line do
              LCollapsedCount := CodeFoldingExpandLine(LLine + 1);
            FPosition.BeginSelection := LOldSelectionBeginPosition;
            FPosition.EndSelection := LOldSelectionEndPosition;
            if LCollapsedCount <> 0 then
            begin
              Inc(FPosition.EndSelection.Line, LCollapsedCount);
              FPosition.EndSelection.Char := Length(FLines[FPosition.EndSelection.Line]) + 1;
            end;
          end
          else
            CodeFoldingExpandLine(FPosition.Text.Line + 1);
      end;
    end;

    if Assigned(FMultiCaret.Carets) and (FMultiCaret.Carets.Count > 0) then
    begin
      case LCommand of
        TKeyCommands.Char, TKeyCommands.Backspace, TKeyCommands.LineBegin, TKeyCommands.LineEnd, TKeyCommands.Paste:
          begin
            LLength := 1;
            if (LCommand = TKeyCommands.Paste) and CanPaste then
              LLength := GetClipboardText.Length;

            for LIndex1 := 0 to FMultiCaret.Carets.Count - 1 do
            begin
              case LCommand of
                TKeyCommands.Char, TKeyCommands.Backspace, TKeyCommands.Paste:
                  begin
                    LViewPosition := PTextEditorViewPosition(FMultiCaret.Carets[LIndex1])^;
                    ViewPosition := LViewPosition;
                    ExecuteCommand(LCommand, LChar, AData);
                  end
              end;

              for LIndex2 := 0 to FMultiCaret.Carets.Count - 1 do
              begin
                LPViewPosition := PTextEditorViewPosition(FMultiCaret.Carets[LIndex2]);
                if (LPViewPosition^.Row = LViewPosition.Row) and
                  (LPViewPosition^.Column >= LViewPosition.Column) then
                case LCommand of
                  TKeyCommands.Char, TKeyCommands.Paste:
                    Inc(LPViewPosition^.Column, LLength);
                  TKeyCommands.Backspace:
                    Dec(LPViewPosition^.Column);
                end
                else
                case LCommand of
                  TKeyCommands.LineBegin:
                    LPViewPosition^.Column := 1;
                  TKeyCommands.LineEnd:
                    LPViewPosition^.Column := FLines.ExpandedStringLengths[LPViewPosition^.Row - 1] + 1;
                end;
              end;
            end;
          end;
        TKeyCommands.Undo:
          begin
            FreeMultiCarets;
            ExecuteCommand(LCommand, LChar, AData);
          end;
      end;
      RemoveDuplicateMultiCarets;
    end
    else
    if LCommand < TKeyCommands.UserFirst then
      ExecuteCommand(LCommand, LChar, AData);

    { Notify hooked command handlers after the command was executed inside of the class }
    NotifyHookedCommandHandlers(True, LCommand, LChar, AData);
  end;

  DoOnCommandProcessed(LCommand, LChar, AData);

  case LCommand of
    TKeyCommands.Backspace, TKeyCommands.DeleteChar, TKeyCommands.DeleteWord, TKeyCommands.DeleteWordForward,
    TKeyCommands.DeleteWordBackward, TKeyCommands.DeleteBeginningOfLine, TKeyCommands.DeleteEndOfLine,
    TKeyCommands.DeleteLine, TKeyCommands.Clear, TKeyCommands.LineBreak, TKeyCommands.InsertLine, TKeyCommands.Char,
    TKeyCommands.Text, TKeyCommands.ImeStr, TKeyCommands.Undo, TKeyCommands.Redo, TKeyCommands.Cut, TKeyCommands.Paste,
    TKeyCommands.BlockIndent, TKeyCommands.BlockUnindent, TKeyCommands.Tab, TKeyCommands.ShiftTab, TKeyCommands.UpperCase,
    TKeyCommands.LowerCase, TKeyCommands.AlternatingCase, TKeyCommands.SentenceCase, TKeyCommands.TitleCase,
    TKeyCommands.UpperCaseBlock, TKeyCommands.LowerCaseBlock, TKeyCommands.AlternatingCaseBlock, TKeyCommands.MoveLineUp,
    TKeyCommands.MoveLineDown, TKeyCommands.LineComment, TKeyCommands.BlockComment:
      DoChange;
  end;
end;

procedure TCustomTextEditor.CopyToClipboard(const AWithLineNumbers: Boolean = False);
var
  LText: string;
  LChangeTrim: Boolean;
  LOldSelectionEndPosition: TTextEditorTextPosition;
  LSelectionBeginPosition, LSelectionEndPosition: TTextEditorTextPosition;
  LStringList: TStringList;
  LLineBreak: string;
  LIndex: Integer;
  LLineNumber: Integer;

  procedure SetEndPosition(const ACodeFoldingRange: TTextEditorCodeFoldingRange);
  begin
    if Assigned(ACodeFoldingRange) then
      if ACodeFoldingRange.Collapsed then
        FPosition.EndSelection := ViewToTextPosition(GetViewPosition(1, SelectionEndPosition.Line + 2));
  end;

begin
  if GetSelectionAvailable then
  begin
    Screen.Cursor := crHourGlass;
    LChangeTrim := (FSelection.ActiveMode = smColumn) and (eoTrimTrailingSpaces in Options);
    LSelectionBeginPosition := SelectionBeginPosition;
    LSelectionEndPosition := SelectionEndPosition;
    try
      if LChangeTrim then
        Exclude(FOptions, eoTrimTrailingSpaces);

      LOldSelectionEndPosition := LSelectionEndPosition;
      if FCodeFolding.Visible then
      begin
        if LSelectionBeginPosition.Line = LSelectionEndPosition.Line then
          SetEndPosition(FCodeFoldings.RangeFromLine[LSelectionBeginPosition.Line + 1])
        else
          SetEndPosition(FCodeFoldings.RangeFromLine[LSelectionEndPosition.Line + 1]);
        LSelectionEndPosition := FPosition.EndSelection;
      end;

      if (LSelectionBeginPosition.Line = 0) and (LSelectionBeginPosition.Char = 1) and
        (LSelectionEndPosition.Line = FLines.Count - 1) and (LSelectionEndPosition.Char = Length(FLines[LSelectionEndPosition.Line]) + 1) then
        LText := FLines.Text
      else
        LText := SelectedText;

      if AWithLineNumbers then
      begin
        LStringList := TStringList.Create;
        try
          LStringList.Text := LText;
          LLineBreak := FLines.DefaultLineBreak;
          LText := '';
          LLineNumber := LSelectionBeginPosition.Line + FLeftMargin.LineNumbers.StartFrom;
          for LIndex := 0 to LStringList.Count - 1 do
          begin
            LText := LText + IntToStr(LLineNumber).PadLeft(Length(LSelectionEndPosition.Line.ToString)) + ': ' +
              LStringList[LIndex];
            if (LIndex < LStringList.Count - 1) or
              (LIndex = LStringList.Count - 1) and (LSelectionEndPosition.Char = 1) then
              LText := LText + LLineBreak;
            Inc(LLineNumber);
          end;
        finally
          LStringList.Free;
        end;
      end;

      FPosition.BeginSelection := LSelectionBeginPosition;
      FPosition.EndSelection := LOldSelectionEndPosition;
    finally
      if LChangeTrim then
        Include(FOptions, eoTrimTrailingSpaces);
      Screen.Cursor := crDefault;
    end;

    DoCopyToClipboard(LText);
  end;
end;

procedure TCustomTextEditor.CutToClipboard;
begin
  CommandProcessor(TKeyCommands.Cut, TControlCharacters.Null, nil);
end;

procedure TCustomTextEditor.DeleteLines(const ALineNumber: Integer; const ACount: Integer);
begin
  if ALineNumber + ACount - 1 < FLines.Count then
  begin
    FPosition.BeginSelection := GetPosition(1, ALineNumber - 1);
    FPosition.EndSelection := GetPosition(1, ALineNumber + ACount - 1);
  end
  else
  begin
    FPosition.BeginSelection := GetPosition(FLines.StringLength(ALineNumber - 2) + 1, ALineNumber - 2);
    FPosition.EndSelection := GetPosition(FLines.StringLength(FLines.Count - 1) + 1, FLines.Count - 1);
  end;

  SetSelectedTextEmpty;

  RescanCodeFoldingRanges;
  ScanMatchingPair;
end;

procedure TCustomTextEditor.DeleteWhitespace;
var
  LTextPosition: TTextEditorTextPosition;
begin
  if ReadOnly then
    Exit;

  FUndoList.BeginBlock;
  try
    LTextPosition := TextPosition;
    FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);

    if GetSelectionAvailable then
      SelectedText := TextEditor.Utils.DeleteWhitespace(SelectedText)
    else
    begin
      SelectAll;
      SelectedText := TextEditor.Utils.DeleteWhitespace(Text);
    end;

    MoveCaretToBeginning;
  finally
    FUndoList.EndBlock;
    DoChange;
  end;
end;

procedure TCustomTextEditor.DragDrop(ASource: TObject; X, Y: Integer);
var
  LNewCaretPosition: TTextEditorTextPosition;
  LDoDrop, LDropAfter, LDropMove: Boolean;
  LSelectionBeginPosition, LSelectionEndPosition: TTextEditorTextPosition;
  LDragDropText: string;
  LChangeScrollPastEndOfLine: Boolean;
  LTextPosition: TTextEditorTextPosition;
  LLinesDeleted: Integer;
begin
  if not ReadOnly and (ASource is TCustomTextEditor) and TCustomTextEditor(ASource).SelectionAvailable then
  begin
    IncPaintLock;
    try
      inherited;
      LNewCaretPosition := PixelsToTextPosition(X, Y);

      if ASource = Self then
      begin
        LDropMove := GetKeyState(vkControl) >= 0;
        LSelectionBeginPosition := SelectionBeginPosition;
        LSelectionEndPosition := SelectionEndPosition;
        LDropAfter := (LNewCaretPosition.Line > LSelectionEndPosition.Line) or
          ((LNewCaretPosition.Line = LSelectionEndPosition.Line) and
          ((LNewCaretPosition.Char > LSelectionEndPosition.Char) or
          (not LDropMove and (LNewCaretPosition.Char = LSelectionEndPosition.Char))));
        LDoDrop := LDropAfter or (LNewCaretPosition.Line < LSelectionBeginPosition.Line) or
          ((LNewCaretPosition.Line = LSelectionBeginPosition.Line) and
          ((LNewCaretPosition.Char < LSelectionBeginPosition.Char) or
          (not LDropMove and (LNewCaretPosition.Char = LSelectionBeginPosition.Char))));
      end
      else
      begin
        LDropMove := GetKeyState(vkShift) < 0;
        LDoDrop := True;
        LDropAfter := False;
      end;

      if LDoDrop then
      begin
        FUndoList.BeginBlock;
        try
          LTextPosition := TextPosition;
          FUndoList.AddChange(crCaret, LSelectionBeginPosition, LSelectionBeginPosition, LSelectionEndPosition, '',
            FSelection.ActiveMode);

          LDragDropText := TCustomTextEditor(ASource).SelectedText;

          if LDropMove then
          begin
            LLinesDeleted := LSelectionEndPosition.Line - LSelectionBeginPosition.Line;

            if ASource = Self then
              SetSelectedTextEmpty
            else
            if ASource is TCustomTextEditor then
              TCustomTextEditor(ASource).SetSelectedTextEmpty;

            if LDropAfter then
              LNewCaretPosition.Line := LNewCaretPosition.Line - LLinesDeleted;
          end;

          LChangeScrollPastEndOfLine := not (soPastEndOfLine in FScroll.Options);
          try
            if LChangeScrollPastEndOfLine then
              FScroll.SetOption(soPastEndOfLine, True);
            TextPosition := LNewCaretPosition;

            DoInsertText(LDragDropText);

            FPosition.BeginSelection := LNewCaretPosition;
            if LSelectionBeginPosition.Line = LSelectionEndPosition.Line  then
              FPosition.EndSelection.Char := LNewCaretPosition.Char + LSelectionEndPosition.Char - LSelectionBeginPosition.Char
            else
              FPosition.EndSelection.Char := LSelectionEndPosition.Char;
            FPosition.EndSelection.Line := LNewCaretPosition.Line + LSelectionEndPosition.Line - LSelectionBeginPosition.Line;
          finally
            if LChangeScrollPastEndOfLine then
              FScroll.SetOption(soPastEndOfLine, False);
          end;
        finally
          FUndoList.EndBlock;
        end;
      end;
    finally
      DecPaintLock;
      Exclude(FState.Flags, sfDragging);
    end;
  end
  else
    inherited;
end;

procedure TCustomTextEditor.EndUndoBlock;
begin
  FUndoList.EndBlock;
end;

procedure TCustomTextEditor.EndUpdate;
begin
  FLines.EndUpdate;
  DecPaintLock;
end;

procedure TCustomTextEditor.EnsureCursorPositionVisible(const AForceToMiddle: Boolean = False; const AEvenIfVisible: Boolean = False);
var
  LMiddle: Integer;
  LCaretRow: Integer;
  LPoint: TPoint;
  LLeftMarginWidth: Integer;
begin
  if FScrollHelper.PageWidth <= 0 then
    Exit;

  HandleNeeded;
  IncPaintLock;
  try
    LPoint := ViewPositionToPixels(ViewPosition);
    LLeftMarginWidth := GetLeftMarginWidth;
    FScrollHelper.PageWidth := GetScrollPageWidth;

    if (LPoint.X < LLeftMarginWidth) or (LPoint.X >= LLeftMarginWidth + FScrollHelper.PageWidth) then
      SetHorizontalScrollPosition(LPoint.X + FScrollHelper.HorizontalPosition - FLeftMarginWidth - FScrollHelper.PageWidth div 2)
    else
    if LPoint.X = LLeftMarginWidth then
      SetHorizontalScrollPosition(0)
    else
      SetHorizontalScrollPosition(FScrollHelper.HorizontalPosition);

    LCaretRow := FViewPosition.Row;
    if AForceToMiddle then
    begin
      if LCaretRow < TopLine - 1 then
      begin
        LMiddle := VisibleLineCount div 2;
        if LCaretRow - LMiddle < 0 then
          TopLine := 1
        else
          TopLine := LCaretRow - LMiddle + 1;
      end
      else
      if LCaretRow > TopLine + VisibleLineCount - 2 then
      begin
        LMiddle := VisibleLineCount div 2;
        TopLine := LCaretRow - VisibleLineCount - 1 + LMiddle;
      end
      else
      if AEvenIfVisible then
      begin
        LMiddle := VisibleLineCount div 2;
        TopLine := LCaretRow - LMiddle + 1;
      end;
    end
    else
    begin
      if LCaretRow < TopLine then
        TopLine := LCaretRow
      else
      if LCaretRow > TopLine + Max(1, VisibleLineCount) - 1 then
        TopLine := LCaretRow - (VisibleLineCount - 1);
    end;
  finally
    DecPaintLock;
  end;
end;

procedure TCustomTextEditor.ExecuteCommand(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);
begin
  IncPaintLock;
  try
    FState.ExecutingSelectionCommand := ACommand in [TKeyCommands.Selection..TKeyCommands.SelectAll];
    case ACommand of
      TKeyCommands.Left, TKeyCommands.SelectionLeft:
        if not FSyncEdit.Visible or FSyncEdit.Visible and (TextPosition.Char > FSyncEdit.EditBeginPosition.Char) then
          MoveCaretHorizontally(-1, ACommand = TKeyCommands.SelectionLeft);
      TKeyCommands.Right, TKeyCommands.SelectionRight:
        if not FSyncEdit.Visible or FSyncEdit.Visible and (TextPosition.Char < FSyncEdit.EditEndPosition.Char) then
          MoveCaretHorizontally(1, ACommand = TKeyCommands.SelectionRight);
      TKeyCommands.PageLeft, TKeyCommands.SelectionPageLeft:
        DoPageLeftOrRight(ACommand);
      TKeyCommands.LineBegin, TKeyCommands.SelectionLineBegin:
        DoHomeKey(ACommand = TKeyCommands.SelectionLineBegin);
      TKeyCommands.LineEnd, TKeyCommands.SelectionLineEnd:
        DoEndKey(ACommand = TKeyCommands.SelectionLineEnd);
      TKeyCommands.Up, TKeyCommands.SelectionUp:
        MoveCaretVertically(-1, ACommand = TKeyCommands.SelectionUp);
      TKeyCommands.Down, TKeyCommands.SelectionDown:
        MoveCaretVertically(1, ACommand = TKeyCommands.SelectionDown);
      TKeyCommands.PageUp, TKeyCommands.SelectionPageUp, TKeyCommands.PageDown, TKeyCommands.SelectionPageDown:
        DoPageUpOrDown(ACommand);
      TKeyCommands.PageTop, TKeyCommands.SelectionPageTop, TKeyCommands.PageBottom, TKeyCommands.SelectionPageBottom:
        DoPageTopOrBottom(ACommand);
      TKeyCommands.EditorTop, TKeyCommands.SelectionEditorTop:
        DoEditorTop(ACommand);
      TKeyCommands.EditorBottom, TKeyCommands.SelectionEditorBottom:
        DoEditorBottom(ACommand);
      TKeyCommands.GoToXY, TKeyCommands.SelectionGoToXY:
        if Assigned(AData) then
          MoveCaretAndSelection(TextPosition, TTextEditorTextPosition(AData^), ACommand = TKeyCommands.SelectionGoToXY);
      TKeyCommands.ToggleBookmark:
        DoToggleBookmark;
      TKeyCommands.GoToNextBookmark:
        GoToNextBookmark;
      TKeyCommands.GoToPreviousBookmark:
        GoToPreviousBookmark;
      TKeyCommands.GoToBookmark1 .. TKeyCommands.GoToBookmark9:
        if FLeftMargin.Bookmarks.ShortCuts then
          GoToBookmark(ACommand - TKeyCommands.GoToBookmark1);
      TKeyCommands.SetBookmark1 .. TKeyCommands.SetBookmark9:
        if FLeftMargin.Bookmarks.ShortCuts then
          DoSetBookmark(ACommand, AData);
      TKeyCommands.WordLeft, TKeyCommands.SelectionWordLeft:
        DoWordLeft(ACommand);
      TKeyCommands.WordRight, TKeyCommands.SelectionWordRight:
        DoWordRight(ACommand);
      TKeyCommands.SelectionWord:
        SetSelectedWord;
      TKeyCommands.SelectAll:
        SelectAll;
      TKeyCommands.Backspace:
        if not ReadOnly then
          DoBackspace;
      TKeyCommands.DeleteChar:
        if not ReadOnly then
          DeleteChar;
      TKeyCommands.DeleteWord, TKeyCommands.DeleteWordBackward, TKeyCommands.DeleteWordForward,
        TKeyCommands.DeleteBeginningOfLine, TKeyCommands.DeleteEndOfLine:
        if not ReadOnly then
          DeleteText(ACommand);
      TKeyCommands.DeleteLine:
        if not ReadOnly and (FLines.Count > 0) then
          DeleteLine;
      TKeyCommands.MoveLineUp:
        MoveLineUp;
      TKeyCommands.MoveLineDown:
        MoveLineDown;
      TKeyCommands.SearchNext:
        FindNext;
      TKeyCommands.SearchPrevious:
        FindPrevious;
      TKeyCommands.Clear:
        if not ReadOnly then
          Clear;
      TKeyCommands.InsertLine:
        if not ReadOnly then
          InsertLine;
      TKeyCommands.LineBreak:
        if not ReadOnly then
          DoLineBreak;
      TKeyCommands.Tab:
        if not ReadOnly then
          DoTabKey;
      TKeyCommands.ShiftTab:
        if not ReadOnly then
          DoShiftTabKey;
      TKeyCommands.Char:
        if not ReadOnly and (AChar >= TCharacters.Space) and (AChar <> TCharacters.CtrlBackspace) then
          DoChar(AChar);
      TKeyCommands.UpperCase, TKeyCommands.LowerCase, TKeyCommands.AlternatingCase, TKeyCommands.SentenceCase,
        TKeyCommands.TitleCase, TKeyCommands.UpperCaseBlock, TKeyCommands.LowerCaseBlock, TKeyCommands.AlternatingCaseBlock:
        if not ReadOnly then
          DoToggleSelectedCase(ACommand);
      TKeyCommands.Undo:
        if not ReadOnly then
          DoUndo;
      TKeyCommands.Redo:
        if not ReadOnly then
          DoRedo;
      TKeyCommands.Cut:
        if not ReadOnly and GetSelectionAvailable then
          DoCutToClipboard;
      TKeyCommands.Copy:
        CopyToClipboard;
      TKeyCommands.Paste:
        if not ReadOnly then
          DoPasteFromClipboard;
      TKeyCommands.ScrollUp, TKeyCommands.ScrollDown:
        DoScroll(ACommand);
      TKeyCommands.ScrollLeft:
        begin
          SetHorizontalScrollPosition(FScrollHelper.HorizontalPosition - 1);
          Update;
        end;
      TKeyCommands.ScrollRight:
        begin
          SetHorizontalScrollPosition(FScrollHelper.HorizontalPosition + 1);
          Update;
        end;
      TKeyCommands.InsertMode:
        OvertypeMode := omInsert;
      TKeyCommands.OverwriteMode:
        OvertypeMode := omOverwrite;
      TKeyCommands.ToggleMode:
        if FOvertypeMode = omInsert then
          OvertypeMode := omOverwrite
        else
          OvertypeMode := omInsert;
      TKeyCommands.BlockIndent:
        if not ReadOnly then
          DoBlockIndent;
      TKeyCommands.BlockUnindent:
        if not ReadOnly then
          DoBlockUnindent;
      TKeyCommands.BlockComment:
        if not ReadOnly then
          DoBlockComment;
      TKeyCommands.LineComment:
        if not ReadOnly then
          DoLineComment;
      TKeyCommands.ImeStr:
        if not ReadOnly then
          DoImeStr(AData);
      TKeyCommands.FoldingCollapseLine:
        FoldingCollapseLine;
      TKeyCommands.FoldingExpandLine:
        FoldingExpandLine;
      TKeyCommands.FoldingGoToNext:
        FoldingGoToNext;
      TKeyCommands.FoldingGoToPrevious:
        FoldingGoToPrevious;
    end;
  finally
    DecPaintLock;
  end;
end;

procedure TCustomTextEditor.FoldingCollapseLine;
var
  LFoldRange: TTextEditorCodeFoldingRange;
begin
  if not FCodeFolding.Visible then
    Exit;

  if FLines.Count > 0 then
  begin
    LFoldRange := CodeFoldingCollapsableFoldRangeForLine(TextPosition.Line + 1);

    if Assigned(LFoldRange) then
    begin
      if not LFoldRange.Collapsed then
        CodeFoldingCollapse(LFoldRange);

      Invalidate;
    end;
  end;
end;

procedure TCustomTextEditor.FoldingExpandLine;
var
  LFoldRange: TTextEditorCodeFoldingRange;
begin
  if not FCodeFolding.Visible then
    Exit;

  if FLines.Count > 0 then
  begin
    LFoldRange := CodeFoldingCollapsableFoldRangeForLine(TextPosition.Line + 1);

    if Assigned(LFoldRange) then
    begin
      if LFoldRange.Collapsed then
        CodeFoldingExpand(LFoldRange);

      Invalidate;
    end;
  end;
end;

procedure TCustomTextEditor.FoldingGoToNext;
var
  LTextPosition: TTextEditorTextPosition;
begin
  if not FCodeFolding.Visible then
    Exit;

  LTextPosition := TextPosition;
  LTextPosition.Line := LTextPosition.Line + 1;
  while (LTextPosition.Line < FLines.Count) and Assigned(FCodeFoldings.RangeFromLine) and
    not Assigned(FCodeFoldings.RangeFromLine[LTextPosition.Line + 1]) do
    LTextPosition.Line := LTextPosition.Line + 1;
  TextPosition := LTextPosition;

  Invalidate;
end;

procedure TCustomTextEditor.FoldingGoToPrevious;
var
  LTextPosition: TTextEditorTextPosition;
begin
  if not FCodeFolding.Visible then
    Exit;

  LTextPosition := TextPosition;
  LTextPosition.Line := LTextPosition.Line - 1;
  while (LTextPosition.Line < FLines.Count) and Assigned(FCodeFoldings.RangeFromLine) and
    not Assigned(FCodeFoldings.RangeFromLine[LTextPosition.Line + 1]) do
    LTextPosition.Line := LTextPosition.Line - 1;
  TextPosition := LTextPosition;

  Invalidate;
end;

procedure TCustomTextEditor.ExportToHTML(const AFilename: string; const ACharSet: string = ''; const AEncoding: System.SysUtils.TEncoding = nil);
var
  LFileStream: TFileStream;
begin
  LFileStream := TFileStream.Create(AFilename, fmCreate);
  try
    ExportToHTML(LFileStream, ACharSet, AEncoding);
  finally
    LFileStream.Free;
  end;
end;

procedure TCustomTextEditor.ExportToHTML(const AStream: TStream; const ACharSet: string = ''; const AEncoding: System.SysUtils.TEncoding = nil);
begin
  with TTextEditorExportHTML.Create(FLines, FHighlighter, Font, ACharSet) do
  try
    SaveToStream(AStream, AEncoding);
  finally
    Free;
  end;
end;

procedure TCustomTextEditor.GoToBookmark(const AIndex: Integer);
var
  LTextPosition: TTextEditorTextPosition;
  LBookmark: TTextEditorMark;
begin
  LBookmark := FBookmarkList.Find(AIndex);
  if Assigned(LBookmark) then
  begin
    LTextPosition.Char := LBookmark.Char;
    LTextPosition.Line := LBookmark.Line;

    GoToLineAndCenter(LTextPosition.Line, LTextPosition.Char);

    FPosition.BeginSelection := TextPosition;
    FPosition.EndSelection := FPosition.BeginSelection;

    Invalidate;
  end;
end;

procedure TCustomTextEditor.GoToLine(const ALine: Integer);
var
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := GetPosition(1, ALine - 1);
  SetTextPosition(LTextPosition);
  FPosition.BeginSelection := LTextPosition;
  FPosition.EndSelection := FPosition.BeginSelection;

  Invalidate;
end;

procedure TCustomTextEditor.GoToLineAndCenter(const ALine: Integer; const AChar: Integer = 1);
var
  LIndex: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
  LTextPosition: TTextEditorTextPosition;
begin
  if FCodeFolding.Visible then
  for LIndex := 0 to FCodeFoldings.AllRanges.AllCount - 1 do
  begin
    LCodeFoldingRange := FCodeFoldings.AllRanges[LIndex];
    if LCodeFoldingRange.FromLine > ALine then
      Break
    else
    if (LCodeFoldingRange.FromLine <= ALine) and LCodeFoldingRange.Collapsed then
      CodeFoldingExpand(LCodeFoldingRange);
  end;

  LTextPosition := GetPosition(AChar, ALine);
  SetTextPosition(LTextPosition);
  TopLine := Max(LTextPosition.Line - VisibleLineCount div 2 + 1, 1);
  FPosition.BeginSelection := LTextPosition;
  FPosition.EndSelection := FPosition.BeginSelection;

  Invalidate;
end;

procedure TCustomTextEditor.HookEditorLines(const ALines: TTextEditorLines; const AUndo, ARedo: TTextEditorUndoList);
var
  LOldWrap: Boolean;
begin
  Assert(not Assigned(FChainedEditor));
  Assert(FLines = FOriginal.Lines);

  LOldWrap := FWordWrap.Active;
  UpdateWordWrap(False);

  if Assigned(FChainedEditor) then
    RemoveChainedEditor
  else
  if FLines <> FOriginal.Lines then
    UnhookEditorLines;

  FEvents.OnChainLinesCleared := ALines.OnCleared;
  ALines.OnCleared := ChainLinesCleared;
  FEvents.OnChainLinesDeleted := ALines.OnDeleted;
  ALines.OnDeleted := ChainLinesDeleted;
  FEvents.OnChainLinesInserted := ALines.OnInserted;
  ALines.OnInserted := ChainLinesInserted;
  FEvents.OnChainLinesPutted := ALines.OnPutted;
  ALines.OnPutted := ChainLinesPutted;
  FEvents.OnChainLinesChanging := ALines.OnChanging;
  ALines.OnChanging := ChainLinesChanging;
  FEvents.OnChainLinesChanged := ALines.OnChange;
  ALines.OnChange := ChainLinesChanged;

  FEvents.OnChainUndoAdded := AUndo.OnAddedUndo;
  AUndo.OnAddedUndo := ChainUndoRedoAdded;
  FEvents.OnChainRedoAdded := ARedo.OnAddedUndo;
  ARedo.OnAddedUndo := ChainUndoRedoAdded;

  FLines := ALines;
  FUndoList := AUndo;
  FRedoList := ARedo;

  UpdateWordWrap(LOldWrap);

  LinesHookChanged;
end;

procedure TCustomTextEditor.InsertLine(const ALineNumber: Integer; const AValue: string);
var
  LLineNumber: Integer;
  LTextPosition, LTextEndPosition: TTextEditorTextPosition;
begin
  LLineNumber := ALineNumber;
  if LLineNumber > FLines.Count + 1 then
    LLineNumber := FLines.Count + 1;

  FUndoList.BeginBlock;
  FUndoList.AddChange(crCaret, TextPosition, SelectionBeginPosition, SelectionEndPosition, '', smNormal);

  LTextPosition.Char := 1;
  LTextPosition.Line := LLineNumber - 1;

  FLines.BeginUpdate;
  FLines.Insert(LTextPosition.Line, AValue);
  FLines.EndUpdate;

  if LLineNumber < FLines.Count then
    LTextEndPosition := GetPosition(1, LTextPosition.Line + 1)
  else
  begin
    LTextEndPosition := GetPosition(Length(AValue) + 1, LTextPosition.Line);
    LTextPosition := GetPosition(FLines.StringLength(LTextPosition.Line - 1) + 1, LTextPosition.Line - 1);
  end;

  FUndoList.AddChange(crInsert, LTextPosition, LTextPosition, LTextEndPosition, '', smNormal);

  FUndoList.EndBlock;

  RescanCodeFoldingRanges;
  ScanMatchingPair;
end;

procedure TCustomTextEditor.InsertBlock(const ABlockBeginPosition, ABlockEndPosition: TTextEditorTextPosition;
  const AChangeStr: PChar; const AAddToUndoList: Boolean);
var
  LSelectionMode: TTextEditorSelectionMode;
begin
  LSelectionMode := FSelection.ActiveMode;
  SetCaretAndSelection(ABlockBeginPosition, ABlockBeginPosition, ABlockEndPosition);
  FSelection.ActiveMode := smColumn;
  DoSelectedText(smColumn, AChangeStr, AAddToUndoList, TextPosition);
  FSelection.ActiveMode := LSelectionMode;
end;

procedure TCustomTextEditor.LeftMarginChanged(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  if not (csLoading in ComponentState) and Assigned(FHighlighter) and not FHighlighter.Loading then
    DoLeftMarginAutoSize
end;

procedure TCustomTextEditor.LoadFromFile(const AFilename: string; const AEncoding: System.SysUtils.TEncoding = nil);
var
  LFileStream: TFileStream;
begin
  LFileStream := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyNone);
  try
    LoadFromStream(LFileStream, AEncoding);
  finally
    LFileStream.Free;
  end;
end;

procedure TCustomTextEditor.LoadFromStream(const AStream: TStream; const AEncoding: System.SysUtils.TEncoding = nil);
var
  LWordWrapEnabled: Boolean;
begin
  FLines.ShowProgress := AStream.Size > TMaxValues.BufferSize;
  if FLines.ShowProgress then
    FLines.FileSize := AStream.Size;

  try
    LWordWrapEnabled := FWordWrap.Active;
    FWordWrap.Active := False;
    FLines.TrailingLineBreak := eoTrailingLineBreak in FOptions;

    if Assigned(Parent) then
    begin
      ClearMatchingPair;
      ClearCodeFolding;
      ClearBookmarks;
    end;

    FLines.LoadFromStream(AStream, AEncoding);
    if FLines.Count = 0 then
      FLines.Add(EmptyStr);

    if not Assigned(Parent) then
      Exit;

    InitCodeFolding;

    if LWordWrapEnabled then
      FWordWrap.Active := LWordWrapEnabled;

    SizeOrFontChanged;

    if Assigned(FHighlighter.BeforePrepare) then
      FHighlighter.SetOption(hoExecuteBeforePrepare, True);

    FFile.Loaded := True;
  finally
    FLines.ShowProgress := False;
  end;
end;

procedure TCustomTextEditor.LockUndo;
begin
  FUndoList.Lock;
  FRedoList.Lock;
end;

procedure TCustomTextEditor.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited Notification(AComponent, AOperation);

  if AOperation = opRemove then
  begin
    if AComponent = FChainedEditor then
      RemoveChainedEditor;

    if Assigned(FLeftMargin) and Assigned(FLeftMargin.Bookmarks) and Assigned(FLeftMargin.Bookmarks.Images) then
      if (AComponent = FLeftMargin.Bookmarks.Images) then
      begin
        FLeftMargin.Bookmarks.Images := nil;

        Invalidate;
      end;
  end;
end;

procedure TCustomTextEditor.PasteFromClipboard;
begin
  CommandProcessor(TKeyCommands.Paste, TControlCharacters.Null, nil);
end;

procedure TCustomTextEditor.DoRedo;

  procedure RemoveGroupBreak;
  var
    LRedoItem: TTextEditorUndoItem;
  begin
    if FRedoList.LastChangeReason = crGroupBreak then
    begin
      LRedoItem := FRedoList.PopItem;
      try
        FUndoList.AddGroupBreak;
      finally
        LRedoItem.Free;
      end;
    end;
  end;

var
  LRedoItem: TTextEditorUndoItem;
  LLastChangeBlockNumber: Integer;
  LLastChangeReason: TTextEditorChangeReason;
  LLastChangeString: string;
  LPasteAction: Boolean;
  LKeepGoing: Boolean;
  LChangeTrim: Boolean;
begin
  if ReadOnly then
    Exit;

  LChangeTrim := eoTrimTrailingSpaces in Options;
  if LChangeTrim then
    Exclude(FOptions, eoTrimTrailingSpaces);

  Screen.Cursor := crHourGlass;
  try
    FState.UndoRedo := True;

    LLastChangeBlockNumber := FRedoList.LastChangeBlockNumber;
    LLastChangeReason := FRedoList.LastChangeReason;
    LLastChangeString := FRedoList.LastChangeString;
    LPasteAction := LLastChangeReason = crPaste;

    LRedoItem := FRedoList.PeekItem;
    if Assigned(LRedoItem) then
    begin
      repeat
        RedoItem;
        LRedoItem := FRedoList.PeekItem;
        LKeepGoing := False;
        if Assigned(LRedoItem) then
        begin
          if uoGroupUndo in FUndo.Options then
            LKeepGoing := LPasteAction and (FRedoList.LastChangeString = LLastChangeString) or
              (LLastChangeReason = LRedoItem.ChangeReason) and (LRedoItem.ChangeBlockNumber = LLastChangeBlockNumber) or
              (LRedoItem.ChangeBlockNumber <> 0) and (LRedoItem.ChangeBlockNumber = LLastChangeBlockNumber);
          LLastChangeReason := LRedoItem.ChangeReason;
          LPasteAction := LLastChangeReason = crPaste;
        end;
      until not LKeepGoing;

      RemoveGroupBreak;
    end;

    FState.UndoRedo := False;

    CodeFoldingResetCaches;
    SearchAll;
    RescanCodeFoldingRanges;
  finally
    Screen.Cursor := crDefault;

    if LChangeTrim then
      Include(FOptions, eoTrimTrailingSpaces);
  end;
end;

procedure TCustomTextEditor.RegisterCommandHandler(const AHookedCommandEvent: TTextEditorHookedCommandEvent;
  const AHandlerData: Pointer);
begin
  if not Assigned(AHookedCommandEvent) then
    Exit;

  if not Assigned(FHookedCommandHandlers) then
    FHookedCommandHandlers := TObjectList.Create;

  if FindHookedCommandEvent(AHookedCommandEvent) = -1 then
    FHookedCommandHandlers.Add(TTextEditorHookedCommandHandler.Create(AHookedCommandEvent, AHandlerData))
end;

procedure TCustomTextEditor.RemoveChainedEditor;
begin
  if Assigned(FChainedEditor) then
    RemoveFreeNotification(FChainedEditor);

  FChainedEditor := nil;

  UnhookEditorLines;
end;

procedure TCustomTextEditor.RemoveKeyDownHandler(AHandler: TKeyEvent);
begin
  FKeyboardHandler.RemoveKeyDownHandler(AHandler);
end;

procedure TCustomTextEditor.RemoveKeyPressHandler(AHandler: TTextEditorKeyPressWEvent);
begin
  FKeyboardHandler.RemoveKeyPressHandler(AHandler);
end;

procedure TCustomTextEditor.RemoveKeyUpHandler(AHandler: TKeyEvent);
begin
  FKeyboardHandler.RemoveKeyUpHandler(AHandler);
end;

procedure TCustomTextEditor.RemoveMouseCursorHandler(AHandler: TTextEditorMouseCursorEvent);
begin
  FKeyboardHandler.RemoveMouseCursorHandler(AHandler);
end;

procedure TCustomTextEditor.RemoveMouseDownHandler(AHandler: TMouseEvent);
begin
  FKeyboardHandler.RemoveMouseDownHandler(AHandler);
end;

procedure TCustomTextEditor.RemoveMouseUpHandler(AHandler: TMouseEvent);
begin
  FKeyboardHandler.RemoveMouseUpHandler(AHandler);
end;

procedure TCustomTextEditor.ReplaceLine(const ALineNumber: Integer; const AValue: string; const AFlags: TTextEditorStringFlags);
var
  LTextPosition: TTextEditorTextPosition;
  LLineBreak: string;
begin
  LTextPosition := GetPosition(1, ALineNumber - 1);

  LLineBreak := '';
  if sfEmptyLine in AFlags then
    LLineBreak := FLines.DefaultLineBreak;

  FUndoList.AddChange(crPaste, LTextPosition, GetPosition(1, ALineNumber - 1),
    GetPosition(Length(AValue) + 1, ALineNumber - 1), FLines.Strings[ALineNumber - 1] + LLineBreak, FSelection.ActiveMode);

  FLines.BeginUpdate;
  FLines.Strings[ALineNumber - 1] := AValue;
  if sfEmptyLine in AFlags then
    FLines.IncludeFlag(ALineNumber - 1, sfEmptyLine)
  else
    FLines.ExcludeFlag(ALineNumber - 1, sfEmptyLine);
  FLines.EndUpdate;

  RescanCodeFoldingRanges;
  ScanMatchingPair;
end;

procedure TCustomTextEditor.RescanCodeFoldingRanges;
var
  LIndex: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
  LLengthCodeFoldingRangeFromLine, LLengthCodeFoldingRangeToLine: Integer;
begin
  FCodeFoldings.Rescan := False;

  LLengthCodeFoldingRangeFromLine := Length(FCodeFoldings.RangeFromLine);
  LLengthCodeFoldingRangeToLine := Length(FCodeFoldings.RangeToLine);

  { Delete all expanded folds }
  for LIndex := FCodeFoldings.AllRanges.AllCount - 1 downto 0 do
  begin
    LCodeFoldingRange := FCodeFoldings.AllRanges[LIndex];
    if Assigned(LCodeFoldingRange) then
    begin
      if not LCodeFoldingRange.Collapsed and not LCodeFoldingRange.ParentCollapsed then
      begin
        if (LCodeFoldingRange.FromLine > 0) and (LCodeFoldingRange.FromLine <= LLengthCodeFoldingRangeFromLine) then
          FCodeFoldings.RangeFromLine[LCodeFoldingRange.FromLine] := nil;

        if (LCodeFoldingRange.ToLine > 0) and (LCodeFoldingRange.ToLine <= LLengthCodeFoldingRangeToLine) then
          FCodeFoldings.RangeToLine[LCodeFoldingRange.ToLine] := nil;

        FreeAndNil(LCodeFoldingRange);
        FCodeFoldings.AllRanges.List.Delete(LIndex);
      end
    end;
  end;

  ScanCodeFoldingRanges;
  CodeFoldingResetCaches;

  Invalidate;
end;

procedure TCustomTextEditor.SaveToFile(const AFilename: string; const AEncoding: System.SysUtils.TEncoding = nil);
var
  LFileStream: TFileStream;
begin
  LFileStream := TFileStream.Create(AFilename, fmCreate);
  try
    SaveToStream(LFileStream, AEncoding);
  finally
    LFileStream.Free;
  end;
end;

procedure TCustomTextEditor.SaveToStream(const AStream: TStream; const AEncoding: System.SysUtils.TEncoding = nil);
begin
  Screen.Cursor := crHourGlass;
  try
    FLines.TrailingLineBreak := eoTrailingLineBreak in FOptions;
    FLines.TrimTrailingSpaces := eoTrimTrailingSpaces in FOptions;
    FLines.SaveToStream(AStream, AEncoding);
    SetModified(False);
    if not (uoUndoAfterSave in FUndo.Options) then
      UndoList.Clear;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TCustomTextEditor.SelectAll;
var
  LOldCaretPosition, LLastTextPosition: TTextEditorTextPosition;
begin
  LOldCaretPosition := TextPosition;
  LLastTextPosition := GetPosition(1, Max(FLines.Count - 1, 0));
  if LLastTextPosition.Line >= 0 then
  begin
    if FSelection.Mode = smNormal then
      Inc(LLastTextPosition.Char, Length(FLines[LLastTextPosition.Line]))
    else
      Inc(LLastTextPosition.Char, FLines.GetLengthOfLongestLine);
  end;
  SetCaretAndSelection(LOldCaretPosition, GetPosition(1, 0), LLastTextPosition);
  FLast.SortOrder := soDesc;
  FreeMultiCarets;
  TextPosition := LLastTextPosition;

  Invalidate;
end;

function CompareBookmarkLines(AItem1, AItem2: Pointer): Integer;
begin
  Result := TTextEditorMark(AItem1).Line - TTextEditorMark(AItem2).Line;
end;

procedure TCustomTextEditor.SetBookmark(const AIndex: Integer; const ATextPosition: TTextEditorTextPosition; const AImageIndex: Integer = -1);
var
  LBookmark: TTextEditorMark;
begin
  if (ATextPosition.Line >= 0) and (ATextPosition.Line <= Max(0, FLines.Count - 1)) then
  begin
    LBookmark := FBookmarkList.Find(AIndex);
    if Assigned(LBookmark) then
      DeleteBookmark(LBookmark);

    LBookmark := TTextEditorMark.Create(Self);
    with LBookmark do
    begin
      Line := ATextPosition.Line;
      Char := ATextPosition.Char;
      if AImageIndex = -1 then
        ImageIndex := Min(AIndex, 9)
      else
        ImageIndex := AImageIndex;
      Index := AIndex;
      Visible := True;
    end;

    FBookmarkList.Add(LBookmark);
    FBookmarkList.Sort(CompareBookmarkLines);

    if Assigned(FEvents.OnAfterBookmarkPlaced) then
      FEvents.OnAfterBookmarkPlaced(Self, AIndex, ATextPosition);
  end;
end;

procedure TCustomTextEditor.SetCaretAndSelection(const ATextPosition, ABlockBeginPosition, ABlockEndPosition: TTextEditorTextPosition);
var
  LOldSelectionMode: TTextEditorSelectionMode;
begin
  LOldSelectionMode := FSelection.ActiveMode;
  IncPaintLock;
  try
    TextPosition := ATextPosition;
    SetSelectionBeginPosition(ABlockBeginPosition);
    SetSelectionEndPosition(ABlockEndPosition);
  finally
    FSelection.ActiveMode := LOldSelectionMode;
    DecPaintLock;
  end;
end;

procedure TCustomTextEditor.SetFocus;
begin
  if CanFocus then
  begin
    Winapi.Windows.SetFocus(Handle);

    inherited;
  end;
end;

procedure TCustomTextEditor.SetMark(const AIndex: Integer; const ATextPosition: TTextEditorTextPosition;
  const AImageIndex: Integer; const AColor: TColor = TColors.SysNone);
var
  LMark: TTextEditorMark;
begin
  if (ATextPosition.Line >= 0) and (ATextPosition.Line <= Max(0, FLines.Count - 1)) then
  begin
    LMark := FMarkList.Find(AIndex);
    if Assigned(LMark) then
      DeleteMark(LMark);

    LMark := TTextEditorMark.Create(Self);
    with LMark do
    begin
      Line := ATextPosition.Line;
      Char := ATextPosition.Char;
      if AColor = TColors.SysNone then
        Background := FLeftMargin.Colors.MarkDefaultBackground
      else
        Background := AColor;
      ImageIndex := AImageIndex;
      Index := AIndex;
      Visible := True;
    end;

    if Assigned(FEvents.OnBeforeMarkPlaced) then
      FEvents.OnBeforeMarkPlaced(Self, LMark);

    FMarkList.Add(LMark);
    FMarkList.Sort(CompareBookmarkLines);

    if Assigned(FEvents.OnAfterMarkPlaced) then
      FEvents.OnAfterMarkPlaced(Self);
  end;
end;

procedure TCustomTextEditor.SetOption(const AOption: TTextEditorOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

procedure TCustomTextEditor.Sort(const ASortOrder: TTextEditorSortOrder = soAsc; const ACaseSensitive: Boolean = False);
var
  LBeginPosition, LEndPosition: TTextEditorTextPosition;
  LText: string;
  LSelectionAvailable: Boolean;
  LTextPosition, LTempTextPosition: TTextEditorTextPosition;
  LLines: TTextEditorLines;
  LIndex: Integer;
begin
  LTextPosition := TextPosition;
  FLines.CaseSensitive := ACaseSensitive;
  FLines.SortOrder := ASortOrder;

  if ASortOrder = soRandom then
    Randomize;

  LBeginPosition.Line := 0;
  LEndPosition.Line := FLines.Count - 1;
  LText := FLines.Text;
  LSelectionAvailable := GetSelectionAvailable;
  if LSelectionAvailable then
  begin
    LBeginPosition.Line := GetSelectionBeginPosition.Line;
    LEndPosition := GetSelectionEndPosition;

    if LEndPosition.Char = 1 then
      Dec(LEndPosition.Line);

    LText := SelectedText;
  end;
  LBeginPosition.Char := 1;
  LEndPosition.Char := FLines.StringLength(LEndPosition.Line) + 1;

  FUndoList.BeginBlock;

  if FSelection.ActiveMode = smNormal then
  begin
    if not LSelectionAvailable then
      FUndoList.AddChange(crSelection, LTextPosition, LTextPosition, LTextPosition, '', FSelection.ActiveMode);

    FUndoList.AddChange(crDelete, LTextPosition, LBeginPosition, LEndPosition, LText, FSelection.ActiveMode);
    FLines.Sort(LBeginPosition.Line, LEndPosition.Line)
  end
  else
  begin
    if not LSelectionAvailable then
      SelectAll;

    LLines := TTextEditorLines.Create(nil);
    try
      LLines.CaseSensitive := ACaseSensitive;
      LLines.SortOrder := ASortOrder;
      LLines.Text := SelectedText;
      LLines.Sort(0, LLines.Count - 1);
      SelectedText := LLines.Text;
    finally
      LLines.Free;
    end;
  end;

  LEndPosition.Char := FLines.StringLength(LEndPosition.Line) + 1;

  if FSelection.ActiveMode = smNormal then
  begin
    FUndoList.AddChange(crInsert, LTextPosition, LBeginPosition, LEndPosition, '', FSelection.ActiveMode);

    if LSelectionAvailable then
    begin
      LTempTextPosition := GetSelectionBeginPosition;
      LTempTextPosition.Char := 1;
      SelectionBeginPosition := LTempTextPosition;
      SelectionEndPosition := LEndPosition;
    end;
  end;

  FUndoList.EndBlock;

  for LIndex := LBeginPosition.Line to LEndPosition.Line do
    FLines.LineState[LIndex] := lsModified;

  if FCodeFolding.Visible then
    RescanCodeFoldingRanges;

  DoChange;

  Invalidate;
end;

procedure TCustomTextEditor.DeleteComments;
var
  LBeginPosition, LEndPosition: TTextEditorTextPosition;
  LText: string;
  LTextPosition: TTextEditorTextPosition;
  LLine: Integer;
  LWord: string;
  LTokenType, LPreviousTokenType: TTextEditorRangeType;
begin
  LTextPosition := TextPosition;
  LBeginPosition.Char := 1;
  LBeginPosition.Line := 0;
  LEndPosition.Line := FLines.Count - 1;
  LEndPosition.Char := FLines.StringLength(LEndPosition.Line) + 1;

  FUndoList.BeginBlock;

  FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', FSelection.ActiveMode);

  LText := '';
  for LLine := LBeginPosition.Line to LEndPosition.Line do
  begin
    if LLine = 0 then
      FHighlighter.ResetRange
    else
      FHighlighter.SetRange(FLines.Ranges[LLine - 1]);

    FHighlighter.SetLine(FLines.Items^[LLine].TextLine);
    LPreviousTokenType := ttUnspecified;

    while not FHighlighter.EndOfLine do
    begin
      FHighlighter.GetToken(LWord);

      LTokenType := FHighlighter.TokenType;
      if not (LTokenType in [ttBlockComment, ttLineComment]) and not (LPreviousTokenType in [ttBlockComment, ttLineComment]) then
        LText := LText + LWord;

      FHighlighter.Next;

      LPreviousTokenType := LTokenType;
    end;

    LText := LText + FLines.DefaultLineBreak;
  end;

  SelectAll;
  SelectedText := LText;
  SelectAll;

  LEndPosition.Char := FLines.StringLength(LEndPosition.Line) + 1;
  LEndPosition.Line := FLines.Count - 1;

  FUndoList.AddChange(crInsert, LTextPosition, LBeginPosition, LEndPosition, '', FSelection.ActiveMode);
  MoveCaretToBeginning;
  FUndoList.EndBlock;

  if FCodeFolding.Visible then
    RescanCodeFoldingRanges;

  DoChange;

  Invalidate;
end;

procedure TCustomTextEditor.ToggleBookmark(const AIndex: Integer = -1);
var
  LTextPosition: TTextEditorTextPosition;
begin
  if AIndex = -1 then
    DoToggleBookmark
  else
  begin
    LTextPosition := TextPosition;
    if not DeleteBookmark(LTextPosition.Line, AIndex) then
      SetBookmark(AIndex, LTextPosition)
  end
end;

procedure TCustomTextEditor.UnhookEditorLines;
var
  LOldWrap: Boolean;
begin
  Assert(not Assigned(FChainedEditor));
  if FLines = FOriginal.Lines then
    Exit;

  LOldWrap := FWordWrap.Active;
  UpdateWordWrap(False);

  FLines.OnCleared := FEvents.OnChainLinesCleared;
  FLines.OnDeleted := FEvents.OnChainLinesDeleted;
  FLines.OnInserted := FEvents.OnChainLinesInserted;
  FLines.OnPutted := FEvents.OnChainLinesPutted;
  FLines.OnChanging := FEvents.OnChainLinesChanging;
  FLines.OnChange := FEvents.OnChainLinesChanged;

  FUndoList.OnAddedUndo := FEvents.OnChainUndoAdded;
  FRedoList.OnAddedUndo := FEvents.OnChainRedoAdded;

  FEvents.OnChainLinesCleared := nil;
  FEvents.OnChainLinesDeleted := nil;
  FEvents.OnChainLinesInserted := nil;
  FEvents.OnChainLinesPutted := nil;
  FEvents.OnChainLinesChanging := nil;
  FEvents.OnChainLinesChanged := nil;
  FEvents.OnChainUndoAdded := nil;
  FEvents.OnChainRedoAdded := nil;

  FLines := FOriginal.Lines;
  FUndoList := FOriginal.UndoList;
  FRedoList := FOriginal.RedoList;

  UpdateWordWrap(LOldWrap);

  LinesHookChanged;
end;

procedure TCustomTextEditor.ToggleSelectedCase(const ACase: TTextEditorCase = cNone);
var
  LSelectionStart, LSelectionEnd: TTextEditorTextPosition;
  LCommand: TTextEditorCommand;
begin
  if AnsiUpperCase(SelectedText) <> AnsiUpperCase(FToggleCase.Text) then
  begin
    FToggleCase.Cycle := cUpper;
    FToggleCase.Text := SelectedText;
  end;

  if ACase <> cNone then
    FToggleCase.Cycle := ACase;

  BeginUpdate;
  LSelectionStart := SelectionBeginPosition;
  LSelectionEnd := SelectionEndPosition;
  LCommand := TKeyCommands.None;
  SelectedText := FToggleCase.Text;
  case FToggleCase.Cycle of
    cUpper:
      if FSelection.ActiveMode = smColumn then
        LCommand := TKeyCommands.UpperCaseBlock
      else
        LCommand := TKeyCommands.UpperCase;
    cLower:
      if FSelection.ActiveMode = smColumn then
        LCommand := TKeyCommands.LowerCaseBlock
      else
        LCommand := TKeyCommands.LowerCase;
    cAlternating:
      if FSelection.ActiveMode = smColumn then
        LCommand := TKeyCommands.AlternatingCaseBlock
      else
        LCommand := TKeyCommands.AlternatingCase;
    cSentence:
      LCommand := TKeyCommands.SentenceCase;
    cTitle:
      LCommand := TKeyCommands.TitleCase;
  end;
  if FToggleCase.Cycle <> cOriginal then
    CommandProcessor(LCommand, TControlCharacters.Null, nil);
  SelectionBeginPosition := LSelectionStart;
  SelectionEndPosition := LSelectionEnd;
  EndUpdate;

  Inc(FToggleCase.Cycle);
  if FToggleCase.Cycle > cOriginal then
    FToggleCase.Cycle := cUpper;
end;

procedure TCustomTextEditor.UnlockUndo;
begin
  FUndoList.Unlock;
  FRedoList.Unlock;
end;

procedure TCustomTextEditor.UnregisterCommandHandler(AHookedCommandEvent: TTextEditorHookedCommandEvent);
var
  LIndex: Integer;
begin
  if not Assigned(AHookedCommandEvent) then
    Exit;

  LIndex := FindHookedCommandEvent(AHookedCommandEvent);
  if LIndex > -1 then
    FHookedCommandHandlers.Delete(LIndex)
end;

procedure TCustomTextEditor.UpdateCaret;
var
  LRect: TRect;
  LViewPosition: TTextEditorViewPosition;
  LCaretPoint: TPoint;
  LCompositionForm: TCompositionForm;
  LCaretStyle: TTextEditorCaretStyle;
  LVisibleChars: Integer;
  LLine, LOffset: Integer;
begin
  if (PaintLock <> 0) or not (Focused or FCaretHelper.ShowAlways) then
    Include(FState.Flags, sfCaretChanged)
  else
  begin
    Exclude(FState.Flags, sfCaretChanged);

    LViewPosition := ViewPosition;

    if FWordWrap.Active and (LViewPosition.Row < Length(FWordWrapLine.ViewLength)) then
    begin
      if FWordWrapLine.ViewLength[LViewPosition.Row] = 0 then
      begin
        LVisibleChars := GetVisibleChars(LViewPosition.Row);
        if LViewPosition.Column > LVisibleChars + 1 then
          LViewPosition.Column := LVisibleChars + 1;
      end
      else
      if LViewPosition.Column > FWordWrapLine.ViewLength[LViewPosition.Row] + 1 then
      begin
        LViewPosition.Column := LViewPosition.Column - FWordWrapLine.ViewLength[LViewPosition.Row];
        LViewPosition.Row := LViewPosition.Row + 1;
      end;
    end;

    if FOvertypeMode = omInsert then
      LCaretStyle := FCaret.Styles.Insert
    else
      LCaretStyle := FCaret.Styles.Overwrite;

    LCaretPoint := ViewPositionToPixels(LViewPosition);

    LCaretPoint.X := LCaretPoint.X + FCaretHelper.Offset.X;
    if LCaretStyle in [csHorizontalLine, csThinHorizontalLine, csHalfBlock, csBlock] then
      LCaretPoint.X := LCaretPoint.X + 1;
    LCaretPoint.Y := LCaretPoint.Y + FCaretHelper.Offset.Y;

    LRect := ClientRect;
    DeflateMinimapAndSearchMapRect(LRect);
    Inc(LRect.Left, FLeftMargin.GetWidth + FCodeFolding.GetWidth);

    SetCaretPos(LCaretPoint.X, LCaretPoint.Y);
    if LRect.Contains(LCaretPoint) then
      ShowCaret
    else
      HideCaret;

    LCompositionForm.dwStyle := CFS_POINT;
    LCompositionForm.ptCurrentPos := LCaretPoint;
    ImmSetCompositionWindow(ImmGetContext(Handle), @LCompositionForm);

    if (FLast.ViewPosition.Row = LViewPosition.Row) and
       (FLast.ViewPosition.Column = LViewPosition.Column) then
      Exit;

    if Assigned(FEvents.OnCaretChanged) then
    begin
      LLine := FPosition.Text.Line + FLeftMargin.LineNumbers.StartFrom;
      LOffset := 0;
      if lnoCompareMode in FLeftMargin.LineNumbers.Options then
        LOffset := FCompareLineNumberOffsetCache[LLine];
      FEvents.OnCaretChanged(Self, FPosition.Text.Char, LLine, LOffset);
    end;

    FLast.ViewPosition := LViewPosition;
  end;
end;

procedure TCustomTextEditor.WndProc(var AMessage: TMessage);
const
  ALT_KEY_DOWN = $20000000;
{$IFDEF ALPHASKINS}
var
  LPaintStruct: TPaintStruct;
{$ENDIF}
begin
  { Prevent Alt-Backspace from beeping }
  if (AMessage.Msg = WM_SYSCHAR) and (AMessage.wParam = vkBack) and (AMessage.LParam and ALT_KEY_DOWN <> 0) then
    AMessage.Msg := 0;

{$IFDEF ALPHASKINS}
  if AMessage.Msg = SM_ALPHACMD then
    case AMessage.WParamHi of
      AC_CTRLHANDLED:
        begin
          AMessage.Result := 1;
          Exit;
        end;
      AC_SETNEWSKIN:
        if ACUInt(AMessage.LParam) = ACUInt(SkinData.SkinManager) then
        begin
          CommonMessage(AMessage, FSkinData);
          Exit;
        end;
      AC_REMOVESKIN:
        if ACUInt(AMessage.LParam) = ACUInt(SkinData.SkinManager) then
        begin
          if Assigned(FScrollHelper.Wnd) then
          begin
            FreeAndNil(FScrollHelper.Wnd);
            RecreateWnd;
          end;
          Exit;
        end;
      AC_REFRESH:
        if RefreshNeeded(SkinData, AMessage) then
        begin
          RefreshEditScrolls(SkinData, FScrollHelper.Wnd);
          CommonMessage(AMessage, FSkinData);
          if HandleAllocated and Visible then
            RedrawWindow(Handle, nil, 0, RDWA_REPAINT);
          Exit;
        end;
      AC_GETDEFSECTION:
        begin
          AMessage.Result := 1;
          Exit;
        end;
      AC_GETDEFINDEX:
        begin
          if Assigned(FSkinData.SkinManager) then
            AMessage.Result := FSkinData.SkinManager.SkinCommonInfo.Sections[ssEdit] + 1;
          Exit;
        end;
      AC_SETGLASSMODE:
        begin
          CommonMessage(AMessage, FSkinData);
          Exit;
        end;
    end;

  if not ControlIsReady(Self) or not Assigned(FSkinData) or not FSkinData.Skinned then
    inherited
  else
  begin
    case AMessage.Msg of
      WM_ERASEBKGND:
        if (SkinData.SkinIndex >= 0) and InUpdating(FSkinData) then
          Exit;
      WM_PAINT:
        begin
          if InUpdating(FSkinData) then
          begin
            BeginPaint(Handle, LPaintStruct);
            EndPaint(Handle, LPaintStruct);
          end
          else
            inherited;

          Exit;
        end;
    end;

    if CommonWndProc(AMessage, FSkinData) then
      Exit;
{$ENDIF}
    inherited;

    if (AMessage.Msg = WM_IME_NOTIFY) and Assigned(FCompletionProposalPopupWindow) then
      SetCompletionProposalPopupWindowLocation;

{$IFDEF ALPHASKINS}
    case AMessage.Msg of
      CM_SHOWINGCHANGED:
        RefreshEditScrolls(SkinData, FScrollHelper.Wnd);
      CM_VISIBLECHANGED, CM_ENABLEDCHANGED, WM_SETFONT:
        FSkinData.Invalidate;
      CM_TEXTCHANGED, CM_CHANGED:
        if Assigned(FScrollHelper.Wnd) then
          UpdateScrolls(FScrollHelper.Wnd, True);
    end;
  end;

  if Assigned(FBoundLabel) then
    FBoundLabel.HandleOwnerMsg(AMessage, Self);
{$ENDIF}
end;

procedure TCustomTextEditor.SetFullFilename(const AName: string);
begin
  FFile.FullName := AName;
  FFile.Path := ExtractFilePath(AName);
  FFile.Name := ExtractFilename(AName);
end;

procedure TCustomTextEditor.GoToOriginalLineAndCenter(const ALine: Integer; const AChar: Integer; const AText: string = '');
var
  LIndex: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
  LTextPosition: TTextEditorTextPosition;
  LLine: Integer;

  function GetOriginalLineNumber(const ALine: Integer): Integer;
  var
    LLow, LHigh, LMiddle, LLine: Integer;
  begin
    LLow := 0;
    LHigh := FLines.Count - 1;
    while LLow <= LHigh do
    begin
      LMiddle := (LLow + LHigh) div 2;
      LLine := FLines.Items^[LMiddle].OriginalLineNumber;
      if LLine > ALine then
        LHigh := LMiddle - 1
      else
      if LLine < ALine then
        LLow := LMiddle + 1
      else
        Exit(LMiddle);
    end;
    Result := -1;
  end;

begin
  LLine := GetOriginalLineNumber(ALine);

  if LLine = -1 then
    Exit;

  if (AText <> '') and not Modified then
    if CompareText(FLines[LLine], AText) <> 0 then
    begin
      LoadFromFile(FullFilename);
      LLine := GetOriginalLineNumber(ALine);
    end;

  if CodeFolding.Visible then
  for LIndex := 0 to FCodeFoldings.AllRanges.AllCount - 1 do
  begin
    LCodeFoldingRange := FCodeFoldings.AllRanges[LIndex];
    if LCodeFoldingRange.FromLine > LLine then
      Break
    else
    if (LCodeFoldingRange.FromLine <= LLine) and LCodeFoldingRange.Collapsed then
      CodeFoldingExpand(LCodeFoldingRange);
  end;

  LTextPosition := GetPosition(AChar, LLine);
  TextPosition := LTextPosition;

  TopLine := Max(GetViewLineNumber(LTextPosition.Line + 1) - (ClientHeight div LineHeight) div 2, 1);

  FPosition.BeginSelection := LTextPosition;
  FPosition.EndSelection := LTextPosition;

  Invalidate;
end;

function TCustomTextEditor.WordCount(const ASelected: Boolean = False): Integer;
var
  LPText: PChar;
  LIsWord: Boolean;
begin
  Result := 0;

  if ASelected then
    LPText := PChar(SelectedText)
  else
    LPText := PChar(Text);

  while LPText^ <> TControlCharacters.Null do
  begin
    while ((LPText^ < TCharacters.ExclamationMark) or IsWordBreakChar(LPText^)) and
      (LPText^ <> TControlCharacters.Null) do
      Inc(LPText);

    if LPText^ = TControlCharacters.Null then
      Exit;

    LIsWord := True;
    while (LPText^ >= TCharacters.ExclamationMark) and (LPText^ <> TControlCharacters.Null) and
      not IsWordBreakChar(LPText^) do
    begin
      if not LPText^.IsLetter then
        LIsWord := False;
      Inc(LPText);
    end;

    if LIsWord then
      Inc(Result);
  end;
end;

function TCustomTextEditor.CharacterCount(const ASelected: Boolean = False): Integer;
var
  LIndex: Integer;
  LText: string;
begin
  Result := 0;

  if ASelected then
    LText := SelectedText
  else
    LText := Text;

  for LIndex := 1 to Length(LText) do
  if Ord(LText[LIndex]) > 32 then
    Inc(Result);
end;

{ TCustomDBTextEditor }

constructor TCustomDBTextEditor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FDataLink := TFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := DataChange;
  FDataLink.OnEditingChange := EditingChange;
  FDataLink.OnUpdateData := UpdateData;
end;

destructor TCustomDBTextEditor.Destroy;
begin
  FDataLink.Free;
  FDataLink := nil;

  inherited Destroy;
end;

procedure TCustomDBTextEditor.CMEnter(var AMessage: TCMEnter);
begin
  SetEditing(True);

  inherited;
end;

procedure TCustomDBTextEditor.CMExit(var AMessage: TCMExit);
begin
  try
    FDataLink.UpdateRecord;
  except
    SetFocus;
    raise;
  end;

  SetEditing(False);

  inherited;
end;

procedure TCustomDBTextEditor.CMGetDataLink(var AMessage: TMessage);
begin
  AMessage.Result := Integer(FDataLink);
end;

procedure TCustomDBTextEditor.DataChange(Sender: TObject);
begin
  if Assigned(FDataLink.Field) then
  begin
    if FBeginEdit then
    begin
      FBeginEdit := False;
      Exit;
    end;

    if FDataLink.Field.IsBlob then
      LoadMemo
    else
      Text := FDataLink.Field.Text;

    if Assigned(FLoadData) then
      FLoadData(Self);
  end
  else
  begin
    if csDesigning in ComponentState then
      Text := Name
    else
      Text := '';
  end;
end;

procedure TCustomDBTextEditor.DragDrop(ASource: TObject; X, Y: Integer);
begin
  FDataLink.Edit;

  inherited;
end;

procedure TCustomDBTextEditor.EditingChange(Sender: TObject);
begin
  if FDataLink.Editing then
    if Assigned(FDataLink.DataSource) and (FDataLink.DataSource.State <> dsInsert) then
      FBeginEdit := True;
end;

procedure TCustomDBTextEditor.ExecuteCommand(const ACommand: TTextEditorCommand; const AChar: Char; const AData: pointer);
begin
  if (ACommand = TKeyCommands.Char) and (AChar = TControlCharacters.Escape) then
    FDataLink.Reset
  else
  if (ACommand <> TKeyCommands.Copy) and (ACommand >= TKeyCommands.EditCommandFirst) and (ACommand <= TKeyCommands.EditCommandLast) then
    if not FDataLink.Edit then
      Exit;

  inherited;
end;

function TCustomDBTextEditor.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

function TCustomDBTextEditor.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

function TCustomDBTextEditor.GetField: TField;
begin
  Result := FDataLink.Field;
end;

function TCustomDBTextEditor.GetReadOnly: Boolean;
begin
  Result := FDataLink.ReadOnly;
end;

procedure TCustomDBTextEditor.Loaded;
begin
  inherited Loaded;

  if csDesigning in ComponentState then
    DataChange(Self);
end;

procedure TCustomDBTextEditor.LoadMemo;
var
  LStream: TStream;
begin
  LStream := FDataLink.DataSet.CreateBlobStream(FDataLink.Field, bmRead);
  try
    LoadFromStream(LStream);
  finally
    LStream.Free;
  end;
end;

procedure TCustomDBTextEditor.DoChange;
begin
  FDataLink.Modified;

  inherited;
end;

procedure TCustomDBTextEditor.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited Notification(AComponent, AOperation);

  if (AOperation = opRemove) and Assigned(FDataLink) and (AComponent = DataSource) then
    DataSource := nil;
end;

procedure TCustomDBTextEditor.SetDataField(const AValue: string);
begin
  FDataLink.FieldName := AValue;
end;

procedure TCustomDBTextEditor.SetDataSource(const AValue: TDataSource);
begin
  if not (FDataLink.DataSourceFixed and (csLoading in ComponentState)) then
    FDataLink.DataSource := AValue;

  if Assigned(AValue) then
    AValue.FreeNotification(Self);
end;

procedure TCustomDBTextEditor.SetEditing(const AValue: Boolean);
begin
  if FEditing <> AValue then
  begin
    FEditing := AValue;

    if not Assigned(FDataLink.Field) or not FDataLink.Field.IsBlob then
      FDataLink.Reset;
  end;
end;

procedure TCustomDBTextEditor.SetReadOnly(const AValue: Boolean);
begin
  FDataLink.ReadOnly := AValue;
end;

procedure TCustomDBTextEditor.UpdateData(Sender: TObject);
var
  LStream: TStream;
  LBlobField: TBlobField;
begin
  if FDataLink.ReadOnly then
    Exit;

  FDataLink.Edit;

  if FDataLink.Field.IsBlob then
  begin
    LBlobField := FDataLink.Field as TBlobField;

    LStream := TMemoryStream.Create;
    try
      SaveToStream(LStream);

      LBlobField.ReadOnly := False;
      LBlobField.LoadFromStream(LStream);
    finally
      LStream.Free;
    end;
  end
  else
    FDataLink.Field.AsString := Text;
end;

end.
