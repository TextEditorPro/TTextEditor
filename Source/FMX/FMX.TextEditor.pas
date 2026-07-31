{$WARN WIDECHAR_REDUCED OFF} // CharInSet is slow in loops
unit FMX.TextEditor;

{$MESSAGE WARN 'THIS IS A DEVELOPMENT VERSION. DO NOT USE UNTIL THIS WARNING IS REMOVED.'}

{$I FMX.TextEditor.Defines.inc}

interface

uses
  System.Classes, System.Contnrs, System.Generics.Collections, System.Math, System.Math.Vectors, System.SysUtils, System.Types,
  System.UITypes, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.TextEditor.ActiveLine, FMX.TextEditor.Border,
  FMX.TextEditor.Caret, FMX.TextEditor.CodeFolding, FMX.TextEditor.CodeFolding.Hint.Form, FMX.TextEditor.CodeFolding.Ranges,
  FMX.TextEditor.CodeFolding.Regions, FMX.TextEditor.Colors, FMX.TextEditor.CompletionProposal,
  FMX.TextEditor.CompletionProposal.PopupWindow, FMX.TextEditor.CompletionProposal.Snippets, FMX.TextEditor.Consts, FMX.TextEditor.Fonts,
  FMX.TextEditor.Glyph, FMX.TextEditor.Highlighter, FMX.TextEditor.Highlighter.Attributes, FMX.TextEditor.HighlightLine,
  FMX.TextEditor.InternalImage, FMX.TextEditor.KeyboardHandler, FMX.TextEditor.KeyCommands, FMX.TextEditor.LeftMargin,
  FMX.TextEditor.Lines, FMX.TextEditor.MacroRecorder, FMX.TextEditor.Marks, FMX.TextEditor.MatchingPairs, FMX.TextEditor.Minimap,
  FMX.TextEditor.PaintHelper, FMX.TextEditor.PartialLoad, FMX.TextEditor.Replace, FMX.TextEditor.RightMargin, FMX.TextEditor.Ruler,
  FMX.TextEditor.Scroll, FMX.TextEditor.Search, FMX.TextEditor.Search.Base, FMX.TextEditor.Selection, FMX.TextEditor.SkipRegions,
  FMX.TextEditor.SpecialChars, FMX.TextEditor.SyncEdit, FMX.TextEditor.Tabs, FMX.TextEditor.Types, FMX.TextEditor.Undo,
  FMX.TextEditor.Undo.List, FMX.TextEditor.UnknownChars, FMX.TextEditor.Utils, FMX.TextEditor.WordWrap, FMX.TextLayout, FMX.Types;

type
  TTextEditorDefaults = record
  const
    CanChangeSize = True;
    Cursor = crIBeam;
    FileMaxReadBufferSize = 524288;
    FileMinShowProgressSize = 4194304;
    Height = 150;
    LineSpacing = 0;
    MaxLength = 0;
    Options = [eoAutoIndent, eoDragDropEditing, eoLoadColors, eoLoadFontNames, eoLoadFontSizes, eoLoadFontStyles, eoShowNullCharacters, eoShowControlCharacters];
    OvertypeMode = omInsert;
    ParentColor = False;
    ParentFont = False;
    ReadOnly = False;
    TabStop = True;
    WantReturns = True;
    Width = 200;
    ZoomDivider = 0;
    ZoomPercentage = 100;
  end;

  TTextEditorCaretDisplay = class(TControl)
  strict private
    FBackgroundColor: TAlphaColor;
    FBlinkTimer: TTextEditorTimer;
    FBlinking: Boolean;
    FCaretChar: Char;
    FChanged: Boolean;
    FCharRect: TRectF;
    FFont: TFont;
    FForegroundColor: TAlphaColor;
    procedure BlinkTimerHandler(ASender: TObject);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure HideCaret;
    procedure SetCaretInfo(const ABoundsRect: TRectF; const ACaretChar: Char; const ACharRect: TRectF; const ABackgroundColor, AForegroundColor: TAlphaColor; const AFont: TFont);
    procedure ShowCaret(const ABlinking: Boolean; const ABlinkingInterval: Integer);
  end;

  TCustomTextEditor = class abstract(TControl)
  strict private type
    TTextEditorCaretHelper = record
      ShowAlways: Boolean;
      Offset: TPointF;
    end;

    TTextEditorCharacterCount = record
      Calculate: Boolean;
      Value: Integer;
    end;

    TTextEditorCodeFoldings = record
      AllRanges: TTextEditorAllCodeFoldingRanges;
      AnyCollapsed: Boolean;
      CollapsedBackup: TList<Integer>;
      DelayTimer: TTextEditorTimer;
      Exists: Boolean;
      HintForm: TTextEditorCodeFoldingHintForm;
      MouseOverGutter: Boolean;
      RangeFromLine: array of TTextEditorCodeFoldingRange;
      RangeToLine: array of TTextEditorCodeFoldingRange;
      Rescan: Boolean;
      TreeLine: array of Boolean;
    end;

    TTextEditorEvents = record
      OnAdditionalKeywords: TTextEditorAdditionalKeywordsEvent;
      OnAfterBookmarkPlaced: TTextEditorBookmarkPlacedEvent;
      OnAfterLoadFromStream: TTextEditorLoadFromStreamEvent;
      OnAfterDeleteBookmark: TTextEditorBookmarkDeletedEvent;
      OnAfterDeleteLine: TNotifyEvent;
      OnAfterDeleteMark: TNotifyEvent;
      OnAfterDeleteSelection: TNotifyEvent;
      OnAfterLineBreak: TNotifyEvent;
      OnAfterLinePaint: TTextEditorLinePaintEvent;
      OnAfterMarkPanelPaint: TTextEditorMarkPanelPaintEvent;
      OnAfterMarkPlaced: TNotifyEvent;
      OnBeforeDeleteMark: TTextEditorMarkEvent;
      OnBeforeMarkPanelPaint: TTextEditorMarkPanelPaintEvent;
      OnBeforeMarkPlaced: TTextEditorMarkEvent;
      OnBeforeSaveToFile: TTextEditorSaveToFileEvent;
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
      OnChangeScale: TTexteditorChangeScaleEvent;
      OnCommandProcessed: TTextEditorProcessCommandEvent;
      OnCompletionProposalCanceled: TNotifyEvent;
      OnCompletionProposalExecute: TOnCompletionProposalExecute;
      OnCreateHighlighterStream: TTextEditorCreateHighlighterStreamEvent;
      OnCustomLineColors: TTextEditorCustomLineColorsEvent;
      OnCustomTokenAttribute: TTextEditorCustomTokenAttributeEvent;
      OnDropFiles: TTextEditorDropFilesEvent;
      OnHideProgressDialog: TNotifyEvent;
      OnKeyPressW: TTextEditorKeyPressWEvent;
      OnLeftMarginClick: TLeftMarginClickEvent;
      OnLinesDeleted: TStringListChangeEvent;
      OnLinesInserted: TStringListChangeEvent;
      OnLinesPutted: TStringListChangeEvent;
      OnLinkClick: TTextEditorLinkClickEvent;
      OnLoadingProgress: TTextEditorLoadingProgressEvent;
      OnMarkPanelLinePaint: TTextEditorMarkPanelLinePaintEvent;
      OnModified: TNotifyEvent;
      OnMultiCaretChanged: TNotifyEvent;
      OnPaint: TTextEditorPaintEvent;
      OnProcessCommand: TTextEditorProcessCommandEvent;
      OnProcessUserCommand: TTextEditorProcessCommandEvent;
      OnReplaceSearchCount: TTextEditorReplaceSearchCountEvent;
      OnReplaceText: TTextEditorReplaceTextEvent;
      OnRightMarginMouseUp: TNotifyEvent;
      OnScroll: TTextEditorScrollEvent;
      OnSearchEngineChanged: TNotifyEvent;
      OnSelectionChanged: TNotifyEvent;
      OnShowProgressDialog: TNotifyEvent;
    end;

    TTextEditorFile = record
      DateTime: TDateTime;
      FullName: string;
      HotName: string;
      Loaded: Boolean;
      MaxReadBufferSize: Integer;
      MinShowProgressSize: Int64;
      Name: string;
      Path: string;
      Saved: Boolean;
    end;

    TTextEditorItalic = record
      Bitmap: TBitmap;
      Offset: Byte;
      OffsetCache: array [AnsiChar] of Byte;
    end;

    TTextEditorLast = record
      DblClick: Cardinal;
      DeletedLine: Integer;
      Key: Word;
      LineNumberCount: Integer;
      MouseMovePoint: TPointF;
      Row: Integer;
      ShiftState: TShiftState;
      TopLine: Integer;
      ViewPosition: TTextEditorViewPosition;
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
      Bitmap: TBitmap;
    end;

    TTextEditorMinimapIndicatorHelper = record
      Bitmap: TBitmap;
    end;

    TTextEditorMinimapHelper = record
      BufferBitmap: TBitmap;
      ClickOffsetY: Single;
      Indicator: TTextEditorMinimapIndicatorHelper;
      Left: Single;
      Right: Single;
      Shadow: TTextEditorMinimapShadowHelper;
    end;

    TTextEditorMouse = record
      Down: TPointF;
      DownInText: Boolean;
      IsScrolling: Boolean;
      OverURI: Boolean;
      ScrollCursors: array [0 .. 7] of TCursor;
      ScrollingPoint: TPointF;
      ScrollTimer: TTextEditorTimer;
      WheelAccumulator: Integer;
    end;

    TTextEditorMultiEdit = record
      Carets: TList<PTextEditorMultiCaretRecord>;
      Draw: Boolean;
      Position: TTextEditorViewPosition;
      SelectionAvailable: Boolean;
      Timer: TTextEditorTimer;
    end;

    TTextEditorOriginal = record
      Lines: TTextEditorLines;
      RedoList: TTextEditorUndoList;
      UndoList: TTextEditorUndoList;
    end;

    TTextEditorPosition = record
      CompletionProposal: TTextEditorViewPosition;
      SelectionStart: TTextEditorTextPosition;
      SelectionEnd: TTextEditorTextPosition;
      Text: TTextEditorTextPosition;
    end;

    TTextEditorScrollShadowHelper = record
      AlphaArray: TTextEditorArrayOfSingle;
      AlphaByteArray: PByteArray;
      AlphaByteArrayLength: Integer;
      Bitmap: TBitmap;
    end;

    TTextEditorScrollHelper = record
      Delta: TPointF;
      HintTimer: TTextEditorTimer;
      HorizontalPosition: Single;
      HorizontalScrollMax: Single;
      HorizontalVisible: Boolean;
      IsScrolling: Boolean;
      LastHorizontalMax: Single;
      LastHorizontalPosition: Single;
      LastVerticalMax: Single;
      LastVerticalPosition: Single;
      PageWidth: Integer;
      Shadow: TTextEditorScrollShadowHelper;
      Timer: TTextEditorTimer;
      VerticalVisible: Boolean;
    end;

    TTextEditorState = record
      AltDown: Boolean;
      CanChangeSize: Boolean;
      ExecutingSelectionCommand: Boolean;
      Flags: TTextEditorStateFlags;
      Modified: Boolean;
      ReadOnly: Boolean;
      ReplaceCanceled: Boolean;
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
      Background: TAlphaColor;
      Border: TAlphaColor;
      CharsBefore: Integer;
      CustomBackgroundColor: Boolean;
      EmptySpace: TTextEditorEmptySpace;
      ExpandedCharsBefore: Integer;
      FontStyle: TFontStyles;
      Foreground: TAlphaColor;
      Length: Integer;
      Overhang: Boolean;
      RightToLeftToken: Boolean;
      Text: string;
      Underline: TTextEditorUnderline;
      UnderlineColor: TAlphaColor;
    end;

    TTextEditorZoom = record
      Divider: Integer;
      Percentage: Integer;
      Return: Boolean;
    end;

    TTextEditorWordWrapLine = record
      ViewLength: array of Integer;
      Length: array of Integer;
      Width: array of Single;
    end;

  strict private
    FActiveLine: TTextEditorActiveLine;
    FBookmarkList: TTextEditorMarkList;
    FBookmarkPopupMenu: TComponent;
    FCaretBookmarkList: TTextEditorMarkList;
    FBorder: TTextEditorBorder;
    FCaret: TTextEditorCaret;
    FCaretDisplay: TTextEditorCaretDisplay;
    FCaretHelper: TTextEditorCaretHelper;
    FChainedEditor: TCustomTextEditor;
    FCharacterCount: TTextEditorCharacterCount;
    FCodeFolding: TTextEditorCodeFolding;
    FCodeFoldings: TTextEditorCodeFoldings;
    FColors: TTextEditorColors;
    FCompareLineNumberOffsetCache: array of Integer;
    FCompletionProposal: TTextEditorCompletionProposal;
    FCompletionProposalPopupWindow: TTextEditorCompletionProposalPopupWindow;
    FCompletionProposalTimer: TTextEditorTimer;
    FEvents: TTextEditorEvents;
    FFile: TTextEditorFile;
    FFontStyles: TTextEditorFontStyles;
    FFonts: TTextEditorFonts;
    FGhostCaretDisplay: TTextEditorCaretDisplay;
    FHighlightLine: TTextEditorHighlightLine;
    FHighlightedFoldRange: TTextEditorCodeFoldingRange;
    FHighlighter: TTextEditorHighlighter;
    FHookedCommandHandlers: TObjectList;
    FHorizontalScrollBar: TScrollBar;
    FImagesBookmark: TTextEditorInternalImage;
    FItalic: TTextEditorItalic;
    FKeyCommands: TTextEditorKeyCommands;
    FKeyboardHandler: TTextEditorKeyboardHandler;
    FLast: TTextEditorLast;
    FLeftMargin: TTextEditorLeftMargin;
    FLeftMarginCharWidth: Single;
    FLeftMarginWidth: Single;
    FLineNumbers: TTextEditorLineNumbers;
    FLineSpacing: Integer;
    FLines: TTextEditorLines;
    FMacroRecorder: TTextEditorMacroRecorder;
    FMarkList: TTextEditorMarkList;
    FMatchingPair: TTextEditorMatchingPair;
    FMatchingPairs: TTextEditorMatchingPairs;
    FMaxLength: Integer;
    FMinimap: TTextEditorMinimap;
    FMinimapHelper: TTextEditorMinimapHelper;
    FMouse: TTextEditorMouse;
    FMouseCapture: Boolean;
    FMultiCaretDisplays: TList<TTextEditorCaretDisplay>;
    FMultiEdit: TTextEditorMultiEdit;
    FOptions: TTextEditorOptions;
    FOriginal: TTextEditorOriginal;
    FOvertypeMode: TTextEditorOvertypeMode;
    FPaintHelper: TTextEditorPaintHelper;
    FPaintLock: Integer;
    FPartialLoad: TTextEditorPartialLoad;
    FPixelsPerInch: Integer;
    FPosition: TTextEditorPosition;
    FRedoList: TTextEditorUndoList;
    FReplace: TTextEditorReplace;
    FRightMargin: TTextEditorRightMargin;
    FRightMarginMovePosition: Single;
    FRuler: TTextEditorRuler;
    FRulerMovePosition: Single;
    FSaveScrollOption: Boolean;
    FSaveSelectionMode: TTextEditorSelectionMode;
    FScroll: TTextEditorScroll;
    FScrollHelper: TTextEditorScrollHelper;
    FSearch: TTextEditorSearch;
    FSearchEngine: TTextEditorSearchBase;
    FSearchString: string;
    FSelection: TTextEditorSelection;
    FSimpleMode: Boolean;
    FSpecialChars: TTextEditorSpecialChars;
    FState: TTextEditorState;
    FSyncEdit: TTextEditorSyncEdit;
    FSystemMetrics: TTextEditorSystemMetrics;
    FTabs: TTextEditorTabs;
    FTextLayout: TTextLayout;
    FTheme: TTextEditorTheme;
    FToggleCase: TTextEditorToggleCase;
    FTripleClickInterval: Cardinal;
    FUndo: TTextEditorUndo;
    FUndoList: TTextEditorUndoList;
    FUnknownChars: TTextEditorUnknownChars;
    FUpdatingScrollBars: Boolean;
    FVerticalScrollBar: TScrollBar;
    FViewPosition: TTextEditorViewPosition;
    FWordWrap: TTextEditorWordWrap;
    FWordWrapLine: TTextEditorWordWrapLine;
    FZoom: TTextEditorZoom;
    function AddSnippet(const AExecuteWith: TTextEditorSnippetExecuteWith; const ATextPosition: TTextEditorTextPosition): Boolean;
    function AllWhiteUpToTextPosition(const ATextPosition: TTextEditorTextPosition; const ALine: string; const ALength: Integer): Boolean;
    function AreTextPositionsEqual(const ATextPosition1: TTextEditorTextPosition; const ATextPosition2: TTextEditorTextPosition): Boolean; inline;
    function CharIndexToTextPosition(const ACharIndex: Integer): TTextEditorTextPosition; overload;
    function CharIndexToTextPosition(const ACharIndex: Integer; const ATextBeginPosition: TTextEditorTextPosition; const ACountLineBreak: Boolean = True): TTextEditorTextPosition; overload;
    function CodeFoldingCollapsableFoldRangeForLine(const ALine: Integer): TTextEditorCodeFoldingRange;
    function CodeFoldingFoldRangeForLineTo(const ALine: Integer): TTextEditorCodeFoldingRange; inline;
    function CodeFoldingLineInsideRange(const ALine: Integer): TTextEditorCodeFoldingRange; inline;
    function CodeFoldingRangeForLine(const ALine: Integer): TTextEditorCodeFoldingRange; inline;
    function CodeFoldingTreeEndForLine(const ALine: Integer): Boolean; inline;
    function CodeFoldingTreeLineForLine(const ALine: Integer): Boolean; inline;
    function DoOnCodeFoldingHintClick(const APoint: TPointF): Boolean;
    function FindHookedCommandEvent(const AHookedCommandEvent: TTextEditorHookedCommandEvent): Integer;
    function FreeMinimapBitmaps: Boolean;
    function GetCanPaste: Boolean;
    function GetCanRedo: Boolean;
    function GetCanUndo: Boolean;
    function GetCaretIndex: Integer;
    function GetCharAtCursor: Char;
    function GetCharAtTextPosition(const ATextPosition: TTextEditorTextPosition; const ASelect: Boolean = False): Char;
    function GetCharWidth: Single;
    function GetEndOfLine(const ALine: PChar): PChar;
    function GetFirstSearchIndex(const AMinimap: Boolean): Integer;
    function GetFoldingOnCurrentLine: Boolean;
    function GetHighlighterAttributeAtRowColumn(const ATextPosition: TTextEditorTextPosition; var AToken: string; var ATokenType: TTextEditorRangeType; var AStart: Integer; var AHighlighterAttribute: TTextEditorHighlighterAttribute): Boolean;
    function GetHookedCommandHandlersCount: Integer;
    function GetHorizontalScrollMax: Single;
    function GetInlineSelectionAvailable: Boolean;
    function GetItalicOffset(const AChar: Char): Byte;
    function GetLastWordFromCursor: string;
    function GetLeadingExpandedLength(const AText: string; const ABorder: Integer = 0): Integer;
    function GetLeftMarginWidth: Integer;
    function GetLineHeight: Single; inline;
    function GetLineIndentLevel(const ALine: Integer): Integer; inline;
    function GetMarkBackgroundColor(const ALine: Integer): TAlphaColor;
    function GetMatchingToken(const AViewPosition: TTextEditorViewPosition; var AMatch: TTextEditorMatchingPairMatch): TTextEditorMatchingTokenResult;
    function GetMouseScrollCursorIndex: Integer;
    function GetMouseScrollCursors(const AIndex: Integer): TCursor;
    function GetMultiCaretSelectedText: string;
    function GetPreviousCharAtCursor: Char;
    function GetRowCountFromPixel(const AY: Single): Integer;
    function GetScrollPageWidth: Integer;
    function GetSelectedRow(const AY: Single): Integer;
    function GetSelectedText: string;
    function GetSelectionAvailable: Boolean;
    function GetSelectionEndPosition: TTextEditorTextPosition;
    function GetSelectionLength: Integer;
    function GetSelectionLineCount: Integer;
    function GetSelectionStart: Integer;
    function GetSelectionStartPosition: TTextEditorTextPosition;
    function GetTabText(var ATextPosition: TTextEditorTextPosition): string;
    function GetText: string;
    function GetTextBetween(const ATextBeginPosition: TTextEditorTextPosition; const ATextEndPosition: TTextEditorTextPosition): string;
    function GetTokenCharCount(const AToken: string; const ACharsBefore: Integer): Integer; inline;
    function GetTokenWidth(const AToken: string; const ALength: Integer; const ACharsBefore: Integer; const AMinimap: Boolean = False; const ARTLReading: Boolean = False): Single;
    function GetViewLineNumber(const AViewLineNumber: Integer): Integer;
    function GetViewTextLineNumber(const AViewLineNumber: Integer): Integer;
    function GetVisibleChars(const ARow: Integer; const ALineText: string = ''): Integer;
    function GetVerticalScrollBarThumb: TThumb;
    function IsAnyFoldingCollapsed: Boolean;
    function IsCodeFoldingVisible: Boolean; inline;
    function IsRectInUpdateRegion(const ARect: TRectF): Boolean;
    function IsRulerVisible: Boolean; inline;
    function IsTextPositionInSearchBlock(const ATextPosition: TTextEditorTextPosition): Boolean;
    function IsVerticalScrollBarTracking: Boolean;
    function LeftSpaceCount(const ALine: string): Integer;
    function NextWordPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition; overload;
    function NextWordPosition: TTextEditorTextPosition; overload;
    function PaintLocked: Boolean; inline;
    function PreviousWordPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition; overload;
    function PreviousWordPosition: TTextEditorTextPosition; overload;
    function ScanHighlighterRangesFrom(const AIndex: Integer): Integer;
    function SelectSearchItem(const AIndex: Integer): Boolean;
    function ShortCutPressed: Boolean;
    function StringWordEnd(const ALine: string; var AStart: Integer): Integer;
    function StringWordStart(const ALine: string; var AStart: Integer): Integer;
    function WordWrapWidth: Integer;
    procedure ActiveLineChanged(ASender: TObject);
    procedure AddHighlighterKeywords(const AItems: TTextEditorCompletionProposalItems; const AAddDescription: Boolean = False);
    procedure AddSnippets(const AItems: TTextEditorCompletionProposalItems; const AAddDescription: Boolean = False);
    procedure AddUndoDelete(const ACaretPosition: TTextEditorTextPosition; const ASelectionStartPosition, ASelectionEndPosition: TTextEditorTextPosition; const AChangeText: string; SelectionMode: TTextEditorSelectionMode; AChangeBlockNumber: Integer = 0);
    procedure AddUndoInsert(const ACaretPosition: TTextEditorTextPosition; const ASelectionStartPosition, ASelectionEndPosition: TTextEditorTextPosition; const AChangeText: string; SelectionMode: TTextEditorSelectionMode; AChangeBlockNumber: Integer = 0);
    procedure AddUndoPaste(const ACaretPosition: TTextEditorTextPosition; const ASelectionStartPosition, ASelectionEndPosition: TTextEditorTextPosition; const AChangeText: string; SelectionMode: TTextEditorSelectionMode; AChangeBlockNumber: Integer = 0);
    procedure AfterSetText(ASender: TObject);
    procedure AssignSearchEngine(const AEngine: TTextEditorSearchEngine);
    procedure BeforeSetText(ASender: TObject);
    procedure BookmarkListChanged(ASender: TObject);
    procedure BorderChanged(ASender: TObject);
    procedure BorderStyleChanged(ASender: TObject);
    procedure CaretChanged(ASender: TObject);
    procedure ChainLinesChanged(ASender: TObject);
    procedure ChainLinesChanging(ASender: TObject);
    procedure ChainLinesCleared(ASender: TObject);
    procedure ChainLinesDeleted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
    procedure ChainLinesInserted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
    procedure ChainLinesPutted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
    procedure ChainUndoRedoAdded(ASender: TObject);
    procedure CheckIfAtMatchingKeywords;
    procedure CodeFoldingCollapse(const AFoldRange: TTextEditorCodeFoldingRange);
    procedure CodeFoldingExpand(const AFoldRange: TTextEditorCodeFoldingRange);
    procedure CodeFoldingLinesDeleted(const AFirstLine: Integer; const ACount: Integer);
    procedure CodeFoldingOnChange(const AEvent: TTextEditorCodeFoldingChanges);
    procedure CodeFoldingResetCaches;
    procedure ColorsChanged(ASender: TObject);
    procedure CompletionProposalTimerHandler(ASender: TObject);
    procedure ComputeScroll(const APoint: TPointF);
    procedure CreateBookmarkImages;
    procedure CreateCollapsedBackup;
    procedure CreateLineNumbersCache(const AReset: Boolean = False);
    procedure DecCharacterCount(const AText: string);
    procedure DeflateMinimapAndSearchMapRect(var ARect: TRectF);
    procedure DeleteChar;
    procedure DeleteLine;
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
    procedure DoToggleBookmark(const AImageIndex: Integer = -1; const AAutoNumber: Boolean = False);
    procedure DoToggleMark;
    procedure DoToggleSelectedCase(const ACommand: TTextEditorCommand);
    procedure DoTrimTrailingSpaces(const ATextLine: Integer; const AForceTrim: Boolean = False);
    procedure DoWordLeft(const ACommand: TTextEditorCommand);
    procedure DoWordRight(const ACommand: TTextEditorCommand);
    procedure DragMinimap(const AY: Single);
    procedure EnsureCaretPositionInsideLines(const ATextPosition: TTextEditorTextPosition);
    procedure FindWords(const AWord: string; const AList: TList; const ACaseSensitive: Boolean; const AWholeWordsOnly: Boolean);
    procedure FontChanged(ASender: TObject);
    procedure FreeMultiCarets;
    procedure FreeScrollShadowBitmap;
    procedure GetCommentAtTextPosition(const ATextPosition: TTextEditorTextPosition; var AComment: string);
    procedure GetMinimapLeftRight(var ALeft: Single; var ARight: Single);
    procedure IncCharacterCount(const AText: string);
    procedure InitializeScrollShadow;
    procedure InsertLine; overload;
    procedure LinesChanged(ASender: TObject);
    procedure LinesChanging(ASender: TObject);
    procedure LinesCleared(ASender: TObject);
    procedure LinesDeleted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
    procedure LinesHookChanged;
    procedure LinesInserted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
    procedure LinesPutted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
    procedure MinimapChanged(ASender: TObject);
    procedure MouseScrollTimerHandler(ASender: TObject);
    procedure MoveCaretAndSelection(const ABeforeTextPosition, AAfterTextPosition: TTextEditorTextPosition; const ASelectionCommand: Boolean);
    procedure MoveCaretHorizontally(const X: Integer; const ASelectionCommand: Boolean);
    procedure MoveCaretVertically(const Y: Integer; const ASelectionCommand: Boolean);
    procedure MoveLinesDown;
    procedure MoveLinesUp;
    procedure MultiCaretTimerHandler(ASender: TObject);
    procedure OnCodeFoldingDelayTimer(ASender: TObject);
    procedure ReplaceChanged(const AEvent: TTextEditorReplaceChanges);
    procedure RestoreCollapsedBackup;
    procedure RightMarginChanged(ASender: TObject);
    procedure RulerChanged(ASender: TObject);
    procedure ScanCodeFoldingMatchingPair;
    procedure ScanMatchingPair;
    procedure ScanTagMatchingPair;
    procedure ScrollBarChange(ASender: TObject);
    procedure ScrollBarMouseDown(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; X, Y: Single);
    procedure ScrollBarMouseMove(ASender: TObject; AShift: TShiftState; X, Y: Single);
    procedure ScrollBarMouseUp(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; X, Y: Single);
    procedure ScrollHintTimerHandler(ASender: TObject);
    procedure ScrollTimerHandler(ASender: TObject);
    procedure ScrollingChanged(ASender: TObject);
    procedure SearchChanged(const AEvent: TTextEditorSearchChanges);
    procedure SelectionChanged(ASender: TObject);
    procedure SetActiveLine(const AValue: TTextEditorActiveLine);
    procedure SetCaretIndex(const AValue: Integer);
    procedure SetCodeFolding(const AValue: TTextEditorCodeFolding);
    procedure SetDefaultKeyCommands;
    procedure SetFileMaxReadBufferSize(const AValue: Integer);
    procedure SetFileMinShowProgressSize(const AValue: Int64);
    procedure SetFullFilename(const AName: string);
    procedure SetHighlightLine(const AValue: TTextEditorHighlightLine);
    procedure SetHorizontalScrollPosition(const AValue: Single);
    procedure SetKeyCommands(const AValue: TTextEditorKeyCommands);
    procedure SetLeftMargin(const AValue: TTextEditorLeftMargin);
    procedure SetLine(const ALine: Integer; const ALineText: string); inline;
    procedure SetModified(const AValue: Boolean);
    procedure SetMouseScrollCursors(const AIndex: Integer; const AValue: TCursor);
    procedure SetOppositeColors;
    procedure SetOptions(const AValue: TTextEditorOptions);
    procedure SetOvertypeMode(const AValue: TTextEditorOvertypeMode);
    procedure SetRightMargin(const AValue: TTextEditorRightMargin);
    procedure SetScroll(const AValue: TTextEditorScroll);
    procedure SetSearch(const AValue: TTextEditorSearch);
    procedure SetSelectedText(const AValue: string);
    procedure SetSelectedWord;
    procedure SetSelection(const AValue: TTextEditorSelection);
    procedure SetSelectionEndPosition(const AValue: TTextEditorTextPosition);
    procedure SetSelectionLength(const AValue: Integer);
    procedure SetSelectionStart(const AValue: Integer);
    procedure SetSelectionStartPosition(const AValue: TTextEditorTextPosition);
    procedure SetSimpleMode(const AValue: Boolean);
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
    procedure SetZoomPercentage(const AValue: Integer);
    procedure ShowCodeFoldingHint(const X, Y: Single);
    procedure ShowRulerLegerLine(const X, Y: Single);
    procedure SpecialCharsChanged(ASender: TObject);
    procedure SplitTextIntoWords(const AItems: TTextEditorCompletionProposalItems; const AAddDescription: Boolean = False);
    procedure SwapInt(var ALeft: Integer; var ARight: Integer); inline;
    procedure SyncEditChanged(ASender: TObject);
    procedure TabsChanged(ASender: TObject);
    procedure UndoRedoAdded(ASender: TObject);
    procedure UnknownCharsChanged(ASender: TObject);
    procedure UpdateCollapsedBackup(const AIndex: Integer; const ACount: Integer);
    procedure UpdateFoldingRanges(const ACurrentLine: Integer; const ALineCount: Integer); overload;
    procedure UpdateFoldingRanges(const AFoldRanges: TTextEditorCodeFoldingRanges; const ALineCount: Integer); overload;
    procedure UpdateScrollBars;
    procedure UpdateWordWrap(const AValue: Boolean);
    procedure ValidateMultiCarets;
    procedure WordWrapChanged(ASender: TObject);
  protected
    function BorderWidth: Integer;
    function ClientHeight: Integer;
    function ClientRect: TRect;
    function ClientWidth: Integer;
    function DoOnReplaceText(const AParams: TTextEditorReplaceTextParams): TTextEditorReplaceAction;
    function DoSearchMatchNotFoundWraparoundDialog: Boolean; virtual;
    function Dragging: Boolean;
    function Focused: Boolean;
    function GetReadOnly: Boolean; virtual;
    function HandleAllocated: Boolean;
    function PixelAndRowToViewPosition(const X: Single; const ARow: Integer; const ALineText: string = ''): TTextEditorViewPosition;
    function PixelsToViewPosition(const X, Y: Single): TTextEditorViewPosition;
    function SearchAll(const ASearchText: string = ''): Boolean;
    function TextPositionToCharIndex(const ATextPosition: TTextEditorTextPosition): Integer;
    procedure BeginDrag(AImmediate: Boolean);
    procedure DblClick; override;
    procedure DoBlockIndent;
    procedure DoBlockUnindent;
    procedure DoChange; virtual;
    procedure DoCopyToClipboard(const AText: string);
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure DoOnCommandProcessed(ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);
    procedure DoOnLeftMarginClick(AButton: TMouseButton; AShift: TShiftState; X, Y: Single);
    procedure DoOnMinimapClick(const Y: Single);
    procedure DoOnPaint;
    procedure DoOnProcessCommand(var ACommand: TTextEditorCommand; var AChar: Char; const AData: Pointer); virtual;
    procedure DoOnSearchMapClick(const Y: Single);
    procedure DoSearchStringNotFoundDialog; virtual;
    procedure DoTripleClick;
    procedure DoMouseLeave; override;
    procedure DragOver(const AData: TDragObject; const APoint: TPointF; var AOperation: TDragOperation); override;
    procedure DrawPixelLine(const AX1, AY1, AX2, AY2: Single; const AOpacity: Single = 1; const AThickness: Integer = 1);
    procedure DialogKey(var Key: Word; Shift: TShiftState); override;
    procedure DrawText(const ARect: TRectF; const AText: string; const AHorizontalAlign: TTextAlign = TTextAlign.Leading; const AVerticalAlign: TTextAlign = TTextAlign.Center);
    procedure FreeCompletionProposalPopupWindow;
    procedure FreeHintForm;
    procedure HideCaret;
    procedure KeyDown(var AKey: Word; var AKeyChar: WideChar; AShift: TShiftState); override;
    procedure KeyPressW(var AKey: Char);
    procedure KeyUp(var AKey: Word; var AKeyChar: WideChar; AShift: TShiftState); override;
    procedure Loaded; override;
    procedure MarkListChange(ASender: TObject);
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Single); override;
    procedure MouseMove(AShift: TShiftState; X, Y: Single); override;
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; X, Y: Single); override;
    procedure MouseWheel(AShift: TShiftState; AWheelDelta: Integer; var AHandled: Boolean); override;
    procedure NotifyHookedCommandHandlers(const AAfterProcessing: Boolean; var ACommand: TTextEditorCommand; var AChar: Char; const AData: Pointer);
    procedure UpdateCodeFoldingGutterHover(const AX: Single);
    procedure Paint; override;
    procedure PaintBorder;
    function GetCaretBounds(const AViewPosition: TTextEditorViewPosition; const AMultiEdit: Boolean;
      out ACharRect: TRectF; out ABackgroundColor, AForegroundColor: TAlphaColor): TRectF;
    procedure ApplyCaretDisplay(const ADisplay: TTextEditorCaretDisplay;
      const AViewPosition: TTextEditorViewPosition; const AMultiEdit, ABlinking: Boolean);
    procedure UpdateMultiCaretDisplays;
    procedure PaintCodeFolding(const AClipRect: TRectF; const AFirstRow, ALastRow: Integer);
    procedure PaintCodeFoldingCollapseMark(const AFoldRange: TTextEditorCodeFoldingRange; const ACurrentLineText: string; const ATokenPosition, ATokenLength, ALine: Integer; const ALineRect: TRectF);
    procedure PaintCodeFoldingCollapsedLine(const AFoldRange: TTextEditorCodeFoldingRange; const ALineRect: TRectF);
    procedure PaintCodeFoldingGuides(const AFirstRow, ALastRow: Integer);
    procedure PaintCodeFoldingLine(const AClipRect: TRectF; const ALine: Integer);
    procedure PaintHint(const AHint: string; const ATop: Single);
    procedure PaintLeftMargin(const AClipRect: TRectF; const AFirstLine, ALastTextLine, ALastLine: Integer);
    procedure PaintMinimap(const AClipRect: TRectF; const AFirstLine, ALastLine: Integer);
    procedure PaintMinimapIndicator(const AClipRect: TRectF);
    procedure PaintMinimapShadow(const ACanvas: TCanvas; const AClipRect: TRectF);
    procedure PaintMouseScrollPoint;
    procedure PaintProgress(Sender: TObject);
    procedure PaintProgressBar;
    procedure PaintRightMargin(const AClipRect: TRectF);
    procedure PaintRightMarginMove;
    procedure PaintRightMarginMoveHint;
    procedure PaintRuler;
    procedure PaintRulerMove;
    procedure PaintRulerMoveHint;
    procedure PaintScrollHint;
    procedure PaintScrollShadow(const ACanvas: TCanvas; const AClipRect: TRectF);
    procedure PaintSearchMap(const AClipRect: TRectF);
    procedure PaintSimpleTextLines(const AClipRect: TRectF; const AFirstLine, ALastLine: Integer; const AMinimap: Boolean);
    procedure PaintSpecialCharsEndOfLine(const ALine: Integer; const ALineEndRect: TRectF; const ALineEndInsideSelection: Boolean);
    procedure PaintSyncItems;
    procedure PaintTextLines(const AClipRect: TRectF; const AFirstLine, ALastLine: Integer; const AMinimap: Boolean);
    procedure RedoItem;
    procedure ResetCaret;
    procedure Resize; override;
    procedure ScanCodeFoldingRanges; virtual;
    procedure SetAlwaysShowCaret(const AValue: Boolean);
    procedure SetName(const AValue: TComponentName); override;
    procedure SetReadOnly(const AValue: Boolean); virtual;
    procedure SetViewPosition(const AValue: TTextEditorViewPosition);
    procedure ShowCaret;
    procedure UndoItem;
    procedure UpdateMouseCursor;
    property MouseCapture: Boolean read FMouseCapture write FMouseCapture;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CaretInView: Boolean;
    function CharacterCount(const ASelected: Boolean = False): Integer;
    function CreateHighlighterStream(const AName: string): TStream; virtual;
    function DeleteBookmark(const ALine: Integer; const AIndex: Integer): Boolean; overload;
    function FindFirst: Boolean;
    function FindLast: Boolean;
    function FindNext(const AHandleNotFound: Boolean = True): Boolean;
    function FindPrevious(const AHandleNotFound: Boolean = True): Boolean;
    function GetBookmark(const AIndex: Integer; var ATextPosition: TTextEditorTextPosition): Boolean;
    function GetCanFocus: Boolean; override;
    function GetClipboardText: string;
    function GetCompareLineNumberOffsetCache(const ALine: Integer): Integer;
    function GetNextBreakPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition;
    function GetPreviousBreakPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition;
    function GetTextPosition: TTextEditorTextPosition;
    function GetTextPositionOfMouse(out ATextPosition: TTextEditorTextPosition): Boolean;
    function GetWordAtPixels(const X, Y: Integer): string;
    function IsCaretOnFirstLine: Boolean;
    function IsCaretOnLastLine: Boolean;
    function IsCommentAtCaretPosition: Boolean;
    function IsCommentChar(const AChar: Char): Boolean;
    function IsEmpty: Boolean;
    function IsKeywordAtCaretPosition(const APOpenKeyWord: PBoolean = nil): Boolean;
    function IsKeywordAtCaretPositionOrAfter(const ATextPosition: TTextEditorTextPosition): Boolean;
    function IsMultiEditCaretFound(const ALine: Integer): Boolean;
    function IsTextPositionInSelection(const ATextPosition: TTextEditorTextPosition): Boolean;
    function IsWordBreakChar(const AChar: Char): Boolean; inline;
    function IsWordSelected: Boolean;
    function PixelsToTextPosition(const X, Y: Single): TTextEditorTextPosition;
    function ReplaceSelectedText(const AReplaceText: string; const ASearchText: string; const AAction: TTextEditorReplaceTextAction = rtaReplace): Boolean;
    function ReplaceText(const ASearchText: string; const AReplaceText: string; const AReplaceAll: Boolean = True; const APageIndex: Integer = -1): Integer;
    function SaveToFile(const AFilename: string; const AEncoding: System.SysUtils.TEncoding = nil): Boolean;
    function SearchStatus: string;
    function TextToHTML(const AClipboardFormat: Boolean = False): string;
    function TextToViewPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorViewPosition;
    function TranslateKeyCode(const ACode: Word; const AShift: TShiftState): TTextEditorCommand;
    function ViewPositionToPixels(const AViewPosition: TTextEditorViewPosition; const ALineText: string = ''): TPointF;
    function ViewToTextPosition(const AViewPosition: TTextEditorViewPosition): TTextEditorTextPosition;
    function WordAtCursor: string;
    function WordAtMouse(const ASelect: Boolean = False): string;
    function WordAtTextPosition(const ATextPosition: TTextEditorTextPosition; const ASelect: Boolean = False; const AAllowedBreakChars: TSysCharSet = []): string;
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
    procedure Assign(ASource: TPersistent); override;
    procedure BeginUndoBlock;
    procedure BeginUpdate; reintroduce;
    procedure ChainEditor(const AEditor: TCustomTextEditor);
    procedure ChangeObjectScale(const AMultiplier: Integer; const ADivider: Integer; const AIsDpiChange: Boolean);
    procedure Clear;
    procedure ClearBookmarks;
    procedure ClearCodeFolding;
    procedure ClearHighlightLine;
    procedure ClearMarks;
    procedure ClearMatchingPair;
    procedure ClearMinimapBuffer;
    procedure ClearSelection;
    procedure ClearUndo;
    procedure CollapseAll(const AFromLineNumber: Integer = -1; const AToLineNumber: Integer = -1);
    procedure CollapseAllByLevel(const AFromLevel: Integer; const AToLevel: Integer);
    procedure CommandProcessor(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);
    procedure CopyToClipboard(const AWithLineNumbers: Boolean = False);
    procedure CutToClipboard;
    procedure DecPaintLock;
    procedure DeleteBookmark(ABookmark: TTextEditorMark); overload;
    procedure DropCaretBookmark;
    procedure DeleteComments;
    procedure DeleteEmptyLines;
    procedure DeleteLines(const ALineNumber: Integer; const ACount: Integer);
    procedure DeleteMark(AMark: TTextEditorMark);
    procedure DeleteSelection;
    procedure DeleteWhitespace;
    procedure DoRedo;
    procedure DoUndo;
    procedure DragDrop(const AData: TDragObject; const APoint: TPointF); override;
    procedure EndUndoBlock;
    procedure EndUpdate; reintroduce;
    procedure EnsureCursorPositionVisible(const AForceToMiddle: Boolean = False; const AEvenIfVisible: Boolean = False);
    procedure ExecuteCommand(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer); virtual;
    procedure ExpandAll(const AFromLineNumber: Integer = -1; const AToLineNumber: Integer = -1);
    procedure ExpandAllByLevel(const AFromLevel: Integer; const AToLevel: Integer);
    procedure ExportToHTML(const AFilename: string; const ACharSet: string = ''; const AEncoding: System.SysUtils.TEncoding = nil); overload;
    procedure ExportToHTML(const AStream: TStream; const ACharSet: string = ''; const AEncoding: System.SysUtils.TEncoding = nil); overload;
    procedure FillRect(const ARect: TRectF);
    procedure FindAll;
    procedure FoldingCollapseLine;
    procedure FoldingExpandLine;
    procedure FoldingGoToNext;
    procedure FoldingGoToPrevious;
    procedure FreeBookmarkImages;
    procedure GoToBookmark(const AIndex: Integer);
    procedure GoToLine(const ALine: Integer);
    procedure GoToLineAndSetPosition(const ALine: Integer; const AChar: Integer = 1; const AResultPosition: TTextEditorResultPosition = rpMiddle);
    procedure GoToMatchingPair;
    procedure GoToNextBookmark;
    procedure GoToOriginalLineAndSetPosition(const ALine: Integer; const AChar: Integer; const AText: string = ''; const AResultPosition: TTextEditorResultPosition = rpMiddle);
    procedure GoToPreviousBookmark;
    procedure HookEditorLines(const ALines: TTextEditorLines; const AUndo, ARedo: TTextEditorUndoList);
    procedure IncPaintLock;
    procedure InitCodeFolding;
    procedure InsertBlock(const ABlockBeginPosition, ABlockEndPosition: TTextEditorTextPosition; const AChangeStr: PChar; const AAddToUndoList: Boolean);
    procedure InsertLine(const ALineNumber: Integer; const AValue: string); overload;
    procedure InsertSnippet(const AItem: TTextEditorCompletionProposalSnippetItem; const ATextPosition: TTextEditorTextPosition);
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
    procedure RescanHighlighterRanges;
    procedure ResetCharacterCount;
    procedure ReturnToCaretBookmark;
    procedure SaveToStream(const AStream: TStream; const AEncoding: System.SysUtils.TEncoding = nil; const AChangeModified: Boolean = True);
    procedure SelectAll;
    procedure SetBookmark(const AIndex: Integer; const ATextPosition: TTextEditorTextPosition; const AImageIndex: Integer = -1);
    procedure SetClipboardText(const AText: string; const AHTML: string = '');
    procedure SetFocus;
    procedure SetMark(const AIndex: Integer; const ATextPosition: TTextEditorTextPosition; const AImageIndex: Integer; const AColor: TAlphaColor = TAlphaColors.Null);
    procedure SetOption(const AOption: TTextEditorOption; const AEnabled: Boolean);
    procedure SetSelectedTextEmpty(const AChangeString: string = '');
    procedure SetTextPositionAndSelection(const ATextPosition, ABlockBeginPosition, ABlockEndPosition: TTextEditorTextPosition);
    procedure SizeOrFontChanged(const AFontChanged: Boolean = True);
    procedure Sort(const AOptions: TTextEditorSortOptions); reintroduce;
    procedure SwapCaretBookmark;
    procedure ToggleBookmark(const AIndex: Integer = -1);
    procedure ToggleSelectedCase(const ACase: TTextEditorCase = cNone);
    procedure TrimBeginning;
    procedure TrimEnd;
    procedure TrimText(const ATrimStyle: TTextEditorTrimStyle);
    procedure TrimTrailingSpaces;
    procedure UnhookEditorLines;
    procedure UnlockUndo;
    procedure UnregisterCommandHandler(AHookedCommandEvent: TTextEditorHookedCommandEvent);
    procedure UpdateCaret;
    property Action;
    property ActiveLine: TTextEditorActiveLine read FActiveLine write SetActiveLine;
    property AllCodeFoldingRanges: TTextEditorAllCodeFoldingRanges read FCodeFoldings.AllRanges;
    property AlwaysShowCaret: Boolean read FCaretHelper.ShowAlways write SetAlwaysShowCaret;
    property Bookmarks: TTextEditorMarkList read FBookmarkList;
    property CaretBookmarks: TTextEditorMarkList read FCaretBookmarkList;
    property Border: TTextEditorBorder read FBorder write FBorder;
    property CanChangeSize: Boolean read FState.CanChangeSize write FState.CanChangeSize default TTextEditorDefaults.CanChangeSize;
    property CanPaste: Boolean read GetCanPaste;
    property CanRedo: Boolean read GetCanRedo;
    property CanUndo: Boolean read GetCanUndo;
    property Canvas;
    property Caret: TTextEditorCaret read FCaret write FCaret;
    property CaretIndex: Integer read GetCaretIndex write SetCaretIndex;
    property CharAtCursor: Char read GetCharAtCursor;
    property CharWidth: Single read GetCharWidth;
    property CodeFolding: TTextEditorCodeFolding read FCodeFolding write SetCodeFolding;
    property Colors: TTextEditorColors read FColors write FColors;
    property CompletionProposal: TTextEditorCompletionProposal read FCompletionProposal write FCompletionProposal;
    property Cursor default TTextEditorDefaults.Cursor;
    property FileDateTime: TDateTime read FFile.DateTime write FFile.DateTime;
    property FileMaxReadBufferSize: Integer read FFile.MaxReadBufferSize write SetFileMaxReadBufferSize default TTextEditorDefaults.FileMaxReadBufferSize;
    property FileMinShowProgressSize: Int64 read FFile.MinShowProgressSize write SetFileMinShowProgressSize default TTextEditorDefaults.FileMinShowProgressSize;
    property FilePath: string read FFile.Path write FFile.Path;
    property Filename: string read FFile.Name write FFile.Name;
    property FoldingExists: Boolean read FCodeFoldings.Exists;
    property FoldingOnCurrentLine: Boolean read GetFoldingOnCurrentLine;
    property FontStyles: TTextEditorFontStyles read FFontStyles write FFontStyles;
    property Fonts: TTextEditorFonts read FFonts write FFonts;
    property FullFilename: string read FFile.FullName write SetFullFilename;
    property HighlightLine: TTextEditorHighlightLine read FHighlightLine write SetHighlightLine;
    property Highlighter: TTextEditorHighlighter read FHighlighter write FHighlighter;
    property HorizontalScrollPosition: Single read FScrollHelper.HorizontalPosition write SetHorizontalScrollPosition;
    property HotFilename: string read FFile.HotName write FFile.HotName;
    property InlineSelectionAvailable: Boolean read GetInlineSelectionAvailable;
    property IsScrolling: Boolean read FScrollHelper.IsScrolling;
    property KeyCommands: TTextEditorKeyCommands read FKeyCommands write SetKeyCommands stored False;
    property LeftMargin: TTextEditorLeftMargin read FLeftMargin write SetLeftMargin;
    property LineHeight: Single read GetLineHeight;
    property LineNumbersCount: Integer read FLineNumbers.Count;
    property LineSpacing: Integer read FLineSpacing write FLineSpacing default TTextEditorDefaults.LineSpacing;
    property Lines: TTextEditorLines read FLines;
    property MacroRecorder: TTextEditorMacroRecorder read FMacroRecorder write FMacroRecorder;
    property Marks: TTextEditorMarkList read FMarkList;
    property MatchingPairs: TTextEditorMatchingPairs read FMatchingPairs write FMatchingPairs;
    property MaxLength: Integer read FMaxLength write FMaxLength default TTextEditorDefaults.MaxLength;
    property Minimap: TTextEditorMinimap read FMinimap write FMinimap;
    property Modified: Boolean read FState.Modified write SetModified;
    property MouseScrollCursors[const AIndex: Integer]: TCursor read GetMouseScrollCursors write SetMouseScrollCursors;
    property OnAdditionalKeywords: TTextEditorAdditionalKeywordsEvent read FEvents.OnAdditionalKeywords write FEvents.OnAdditionalKeywords;
    property OnAfterBookmarkPlaced: TTextEditorBookmarkPlacedEvent read FEvents.OnAfterBookmarkPlaced write FEvents.OnAfterBookmarkPlaced;
    property OnAfterDeleteBookmark: TTextEditorBookmarkDeletedEvent read FEvents.OnAfterDeleteBookmark write FEvents.OnAfterDeleteBookmark;
    property OnAfterDeleteLine: TNotifyEvent read FEvents.OnAfterDeleteLine write FEvents.OnAfterDeleteLine;
    property OnAfterDeleteMark: TNotifyEvent read FEvents.OnAfterDeleteMark write FEvents.OnAfterDeleteMark;
    property OnAfterDeleteSelection: TNotifyEvent read FEvents.OnAfterDeleteSelection write FEvents.OnAfterDeleteSelection;
    property OnAfterLineBreak: TNotifyEvent read FEvents.OnAfterLineBreak write FEvents.OnAfterLineBreak;
    property OnAfterLinePaint: TTextEditorLinePaintEvent read FEvents.OnAfterLinePaint write FEvents.OnAfterLinePaint;
    property OnAfterLoadFromStream: TTextEditorLoadFromStreamEvent read FEvents.OnAfterLoadFromStream write FEvents.OnAfterLoadFromStream;
    property OnAfterMarkPanelPaint: TTextEditorMarkPanelPaintEvent read FEvents.OnAfterMarkPanelPaint write FEvents.OnAfterMarkPanelPaint;
    property OnAfterMarkPlaced: TNotifyEvent read FEvents.OnAfterMarkPlaced write FEvents.OnAfterMarkPlaced;
    property OnBeforeDeleteMark: TTextEditorMarkEvent read FEvents.OnBeforeDeleteMark write FEvents.OnBeforeDeleteMark;
    property OnBeforeMarkPanelPaint: TTextEditorMarkPanelPaintEvent read FEvents.OnBeforeMarkPanelPaint write FEvents.OnBeforeMarkPanelPaint;
    property OnBeforeMarkPlaced: TTextEditorMarkEvent read FEvents.OnBeforeMarkPlaced write FEvents.OnBeforeMarkPlaced;
    property OnBeforeSaveToFile: TTextEditorSaveToFileEvent read FEvents.OnBeforeSaveToFile write FEvents.OnBeforeSaveToFile;
    property OnCaretChanged: TTextEditorCaretChangedEvent read FEvents.OnCaretChanged write FEvents.OnCaretChanged;
    property OnChange: TNotifyEvent read FEvents.OnChange write FEvents.OnChange;
    property OnCommandProcessed: TTextEditorProcessCommandEvent read FEvents.OnCommandProcessed write FEvents.OnCommandProcessed;
    property OnCompletionProposalCanceled: TNotifyEvent read FEvents.OnCompletionProposalCanceled write FEvents.OnCompletionProposalCanceled;
    property OnCompletionProposalExecute: TOnCompletionProposalExecute read FEvents.OnCompletionProposalExecute write FEvents.OnCompletionProposalExecute;
    property OnCreateHighlighterStream: TTextEditorCreateHighlighterStreamEvent read FEvents.OnCreateHighlighterStream write FEvents.OnCreateHighlighterStream;
    property OnCustomLineColors: TTextEditorCustomLineColorsEvent read FEvents.OnCustomLineColors write FEvents.OnCustomLineColors;
    property OnCustomTokenAttribute: TTextEditorCustomTokenAttributeEvent read FEvents.OnCustomTokenAttribute write FEvents.OnCustomTokenAttribute;
    property OnDropFiles: TTextEditorDropFilesEvent read FEvents.OnDropFiles write FEvents.OnDropFiles;
    property OnHideProgressDialog: TNotifyEvent read FEvents.OnHideProgressDialog write FEvents.OnHideProgressDialog;
    property OnKeyDown;
    property OnKeyPress: TTextEditorKeyPressWEvent read FEvents.OnKeyPressW write FEvents.OnKeyPressW;
    property OnLeftMarginClick: TLeftMarginClickEvent read FEvents.OnLeftMarginClick write FEvents.OnLeftMarginClick;
    property OnLinesDeleted: TStringListChangeEvent read FEvents.OnLinesDeleted write FEvents.OnLinesDeleted;
    property OnLinesInserted: TStringListChangeEvent read FEvents.OnLinesInserted write FEvents.OnLinesInserted;
    property OnLinesPutted: TStringListChangeEvent read FEvents.OnLinesPutted write FEvents.OnLinesPutted;
    property OnLinkClick: TTextEditorLinkClickEvent read FEvents.OnLinkClick write FEvents.OnLinkClick;
    property OnLoadingProgress: TTextEditorLoadingProgressEvent read FEvents.OnLoadingProgress write FEvents.OnLoadingProgress;
    property OnMarkPanelLinePaint: TTextEditorMarkPanelLinePaintEvent read FEvents.OnMarkPanelLinePaint write FEvents.OnMarkPanelLinePaint;
    property OnModified: TNotifyEvent read FEvents.OnModified write FEvents.OnModified;
    property OnMultiCaretChanged: TNotifyEvent read FEvents.OnMultiCaretChanged write FEvents.OnMultiCaretChanged;
    property OnPaint: TTextEditorPaintEvent read FEvents.OnPaint write FEvents.OnPaint;
    property OnProcessCommand: TTextEditorProcessCommandEvent read FEvents.OnProcessCommand write FEvents.OnProcessCommand;
    property OnProcessUserCommand: TTextEditorProcessCommandEvent read FEvents.OnProcessUserCommand write FEvents.OnProcessUserCommand;
    property OnReplaceSearchCount: TTextEditorReplaceSearchCountEvent read FEvents.OnReplaceSearchCount write FEvents.OnReplaceSearchCount;
    property OnReplaceText: TTextEditorReplaceTextEvent read FEvents.OnReplaceText write FEvents.OnReplaceText;
    property OnRightMarginMouseUp: TNotifyEvent read FEvents.OnRightMarginMouseUp write FEvents.OnRightMarginMouseUp;
    property OnScroll: TTextEditorScrollEvent read FEvents.OnScroll write FEvents.OnScroll;
    property OnSearchEngineChanged: TNotifyEvent read FEvents.OnSearchEngineChanged write FEvents.OnSearchEngineChanged;
    property OnSelectionChanged: TNotifyEvent read FEvents.OnSelectionChanged write FEvents.OnSelectionChanged;
    property OnShowProgressDialog: TNotifyEvent read FEvents.OnShowProgressDialog write FEvents.OnShowProgressDialog;
    property Options: TTextEditorOptions read FOptions write SetOptions default TTextEditorDefaults.Options;
    property OvertypeMode: TTextEditorOvertypeMode read FOvertypeMode write SetOvertypeMode default TTextEditorDefaults.OvertypeMode;
    property PaintLock: Integer read FPaintLock write FPaintLock;
    property PartialLoad: TTextEditorPartialLoad read FPartialLoad write FPartialLoad;
    property PreviousCharAtCursor: Char read GetPreviousCharAtCursor;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default TTextEditorDefaults.ReadOnly;
    property RedoList: TTextEditorUndoList read FRedoList;
    property Replace: TTextEditorReplace read FReplace write FReplace;
    property ReplaceCanceled: Boolean read FState.ReplaceCanceled;
    property RightMargin: TTextEditorRightMargin read FRightMargin write SetRightMargin;
    property Ruler: TTextEditorRuler read FRuler write FRuler;
    property Scroll: TTextEditorScroll read FScroll write SetScroll;
    property Search: TTextEditorSearch read FSearch write SetSearch;
    property SearchString: string read FSearchString write FSearchString;
    property SelectedText: string read GetSelectedText write SetSelectedText;
    property Selection: TTextEditorSelection read FSelection write SetSelection;
    property SelectionAvailable: Boolean read GetSelectionAvailable;
    property SelectionEndPosition: TTextEditorTextPosition read GetSelectionEndPosition write SetSelectionEndPosition;
    property SelectionLength: Integer read GetSelectionLength write SetSelectionLength;
    property SelectionLineCount: Integer read GetSelectionLineCount;
    property SelectionStart: Integer read GetSelectionStart write SetSelectionStart;
    property SelectionStartPosition: TTextEditorTextPosition read GetSelectionStartPosition write SetSelectionStartPosition;
    property SimpleMode: Boolean read FSimpleMode write SetSimpleMode default False;
    property SpecialChars: TTextEditorSpecialChars read FSpecialChars write SetSpecialChars;
    property SyncEdit: TTextEditorSyncEdit read FSyncEdit write SetSyncEdit;
    property TabStop default TTextEditorDefaults.TabStop;
    property Tabs: TTextEditorTabs read FTabs write SetTabs;
    property Text: string read GetText write SetText;
    property TextBetween[const ATextBeginPosition: TTextEditorTextPosition; const ATextEndPosition: TTextEditorTextPosition]: string read GetTextBetween write SetTextBetween;
    property TextPosition: TTextEditorTextPosition read GetTextPosition write SetTextPosition;
    property Theme: TTextEditorTheme read FTheme write FTheme;
    property TopLine: Integer read FLineNumbers.TopLine write SetTopLine;
    property TripleClickInterval: Cardinal read FTripleClickInterval write FTripleClickInterval default 500;
    property URIOpener: Boolean read FState.URIOpener write FState.URIOpener;
    property Undo: TTextEditorUndo read FUndo write SetUndo;
    property UndoList: TTextEditorUndoList read FUndoList;
    property UnknownChars: TTextEditorUnknownChars read FUnknownChars write SetUnknownChars;
    property ViewPosition: TTextEditorViewPosition read FViewPosition write SetViewPosition;
    property VisibleLineCount: Integer read FLineNumbers.VisibleCount;
    property WantReturns: Boolean read FState.WantReturns write FState.WantReturns default TTextEditorDefaults.WantReturns;
    property WordWrap: TTextEditorWordWrap read FWordWrap write SetWordWrap;
    property ZoomDivider: Integer read FZoom.Divider write FZoom.Divider default TTextEditorDefaults.ZoomDivider;
    property ZoomPercentage: Integer read FZoom.Percentage write SetZoomPercentage default TTextEditorDefaults.ZoomPercentage;
  end;

  [ComponentPlatformsAttribute(pidWin32 or pidWin64 or pidOSX64 or pidOSXArm64 or pidiOSDevice64 or pidiOSSimulatorArm64 or pidAndroidArm32 or pidAndroidArm64 or pidLinux64)]
  TTextEditor = class(TCustomTextEditor)
  published
    property ActiveLine;
    property Align;
    property Anchors;
    property Border;
    property Caret;
    property CodeFolding;
    property Colors;
    property CompletionProposal;
    property Cursor;
    property Enabled;
    property FileMaxReadBufferSize;
    property FileMinShowProgressSize;
    property FontStyles;
    property Fonts;
    property Height;
    property HighlightLine;
    property Highlighter;
    property KeyCommands;
    property LeftMargin;
    property LineSpacing;
    property MatchingPairs;
    property MaxLength;
    property Minimap;
    property Name;
    property OnAdditionalKeywords;
    property OnAfterBookmarkPlaced;
    property OnAfterDeleteBookmark;
    property OnAfterDeleteMark;
    property OnAfterLinePaint;
    property OnAfterLoadFromStream;
    property OnAfterMarkPanelPaint;
    property OnAfterMarkPlaced;
    property OnBeforeDeleteMark;
    property OnBeforeMarkPanelPaint;
    property OnBeforeMarkPlaced;
    property OnBeforeSaveToFile;
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
    property OnEnter;
    property OnExit;
    property OnHideProgressDialog;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnLeftMarginClick;
    property OnLinkClick;
    property OnLoadingProgress;
    property OnMarkPanelLinePaint;
    property OnModified;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnPaint;
    property OnProcessCommand;
    property OnProcessUserCommand;
    property OnReplaceSearchCount;
    property OnReplaceText;
    property OnRightMarginMouseUp;
    property OnScroll;
    property OnSearchEngineChanged;
    property OnSelectionChanged;
    property OnShowProgressDialog;
    property Options;
    property OvertypeMode;
    property ParentShowHint;
    property PartialLoad;
    property Margins;
    property Position;
    property Size;
    property PopupMenu;
    property ReadOnly;
    property Replace;
    property RightMargin;
    property Ruler;
    property Scroll;
    property Search;
    property Selection;
    property ShowHint;
    property SimpleMode;
    property SpecialChars;
    property SyncEdit;
    property TabOrder;
    property TabStop;
    property Tabs;
    property Tag;
    property Theme;
    property Touch;
    property TripleClickInterval;
    property Undo;
    property UnknownChars;
    property Visible;
    property WantReturns;
    property Width;
    property WordWrap;
    property ZoomPercentage;
  end;

  ETextEditorBaseException = class(Exception);
  ETextEditorOpenClipboardException = class(Exception);

implementation

uses
  System.Character, System.Generics.Defaults, System.RegularExpressions, System.Rtti, System.UIConsts, FMX.DialogService.Sync, FMX.Menus,
  FMX.Platform, FMX.TextEditor.Export.HTML, FMX.TextEditor.Highlighter.Rules, FMX.TextEditor.Language, FMX.TextEditor.LeftMargin.Border,
  FMX.TextEditor.LeftMargin.LineNumbers, FMX.TextEditor.Search.Map, FMX.TextEditor.Search.Normal, FMX.TextEditor.Search.RegularExpressions,
  FMX.TextEditor.Search.WildCard, FMX.TextEditor.Undo.Item;

type
  TTextEditorScrollBarAccess = class(TScrollBar);

{ TTextEditorCaretDisplay }

constructor TTextEditorCaretDisplay.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  HitTest := False;
  Stored := False;
  Visible := False;

  FFont := TFont.Create;

  FBlinkTimer := TTextEditorTimer.Create(Self);
  FBlinkTimer.Enabled := False;
  FBlinkTimer.OnTimer := BlinkTimerHandler;
end;

destructor TTextEditorCaretDisplay.Destroy;
begin
  FFont.Free;

  inherited Destroy;
end;

procedure TTextEditorCaretDisplay.BlinkTimerHandler(ASender: TObject);
begin
  Opacity := if Opacity = 0 then 1 else 0;
end;

procedure TTextEditorCaretDisplay.SetCaretInfo(const ABoundsRect: TRectF; const ACaretChar: Char; const ACharRect: TRectF;
  const ABackgroundColor, AForegroundColor: TAlphaColor; const AFont: TFont);
begin
  FChanged := FChanged or not BoundsRect.EqualsTo(ABoundsRect) or (FCaretChar <> ACaretChar);

  FCaretChar := ACaretChar;
  FCharRect := ACharRect;
  FBackgroundColor := ABackgroundColor;
  FForegroundColor := AForegroundColor;
  FFont.Assign(AFont);

  SetBounds(ABoundsRect.Left, ABoundsRect.Top, ABoundsRect.Width, ABoundsRect.Height);
end;

procedure TTextEditorCaretDisplay.ShowCaret(const ABlinking: Boolean; const ABlinkingInterval: Integer);
begin
  if Visible and not FChanged and (ABlinking = FBlinking) then
    Exit;

  FChanged := False;
  FBlinking := ABlinking;

  FBlinkTimer.Enabled := False;
  Opacity := 1;
  Visible := True;
  BringToFront;

  if ABlinking and (ABlinkingInterval > 0) then
  begin
    FBlinkTimer.Interval := ABlinkingInterval;
    FBlinkTimer.Enabled := True;
  end;
end;

procedure TTextEditorCaretDisplay.HideCaret;
begin
  FBlinkTimer.Enabled := False;
  Visible := False;
end;

procedure TTextEditorCaretDisplay.Paint;
begin
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := FBackgroundColor;
  Canvas.FillRect(LocalRect, 0, 0, [], AbsoluteOpacity);

  if FCaretChar <> TControlCharacters.Null then
  begin
    Canvas.Font.Assign(FFont);
    Canvas.Fill.Color := FForegroundColor;
    Canvas.FillText(FCharRect, FCaretChar, False, AbsoluteOpacity, [], TTextAlign.Leading, TTextAlign.Leading);
  end;
end;

function TextEditorAlignToPixelCenter(const AValue: Single; const AScale: Single = 1): Single;
var
  LScale: Single;
begin
  LScale := AScale;

  if LScale <= 0 then
    LScale := 1;

  Result := (Floor(AValue * LScale) + 0.5) / LScale;
end;

procedure TextEditorShortCutToKey(const AShortCut: TShortCut; var AKey: Word; var AShiftState: TShiftState);
const
  SC_SHIFT = $2000;
  SC_CTRL = $4000;
  SC_ALT = $8000;
begin
  AKey := AShortCut and not (SC_SHIFT or SC_CTRL or SC_ALT);
  AShiftState := [];

  if AShortCut and SC_SHIFT <> 0 then
    Include(AShiftState, ssShift);

  if AShortCut and SC_CTRL <> 0 then
    Include(AShiftState, ssCtrl);

  if AShortCut and SC_ALT <> 0 then
    Include(AShiftState, ssAlt);
end;

{ TCustomEditor }

constructor TCustomTextEditor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Height := TTextEditorDefaults.Height;
  Width := TTextEditorDefaults.Width;
  Cursor := TTextEditorDefaults.Cursor;
  CanFocus := True;
  HitTest := True;
  TabStop := True;

  FState.CanChangeSize := TTextEditorDefaults.CanChangeSize;
  FFile.Loaded := False;
  FFile.Saved := False;
  FFile.MaxReadBufferSize := TTextEditorDefaults.FileMaxReadBufferSize;
  FFile.MinShowProgressSize := TTextEditorDefaults.FileMinShowProgressSize;

  FSystemMetrics.HorizontalDrag := 4;
  FSystemMetrics.VerticalDrag := 4;

  FTripleClickInterval := 500;

  FLineNumbers.ResetCache := True;
  FMaxLength := TTextEditorDefaults.MaxLength;
  FToggleCase.Text := '';
  FState.URIOpener := False;
  FState.ReadOnly := TTextEditorDefaults.ReadOnly;
  FMultiEdit.Position.Row := -1;
  FSimpleMode := False;
  { Zoom scale in DIP space - screen DPI is handled by the canvas scale }
  FPixelsPerInch := 96;
  { Zoom }
  FZoom.Divider := TTextEditorDefaults.ZoomDivider;
  FZoom.Percentage := TTextEditorDefaults.ZoomPercentage;
  FZoom.Return := False;
  { Border }
  FBorder := TTextEditorBorder.Create;
  FBorder.OnChange := BorderChanged;
  FBorder.OnStyleChange := BorderStyleChanged;
  { Character count }
  ResetCharacterCount;
  { Code folding }
  FCodeFolding := TTextEditorCodeFolding.Create;
  FCodeFolding.OnChange := CodeFoldingOnChange;

  FCodeFoldings.AllRanges := TTextEditorAllCodeFoldingRanges.Create;
  FCodeFoldings.AnyCollapsed := False;
  FCodeFoldings.DelayTimer := TTextEditorTimer.Create(Self);
  FCodeFoldings.DelayTimer.OnTimer := OnCodeFoldingDelayTimer;
  { Colors }
  FColors := TTextEditorColors.Create;
  FColors.OnChange := ColorsChanged;
  FColors.InDesign := csDesigning in ComponentState;
  { Matching pair }
  FMatchingPairs := TTextEditorMatchingPairs.Create;
  { Line spacing }
  FLineSpacing := TTextEditorDefaults.LineSpacing;
  { Special chars }
  FSpecialChars := TTextEditorSpecialChars.Create;
  FSpecialChars.OnChange := SpecialCharsChanged;
  { Caret }
  FCaret := TTextEditorCaret.Create;
  FCaret.OnChange := CaretChanged;

  FCaretDisplay := TTextEditorCaretDisplay.Create(Self);
  FCaretDisplay.Parent := Self;

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
  end;

  { Partial load }
  FPartialLoad := TTextEditorPartialLoad.Create;
  { Unknown chars }
  FUnknownChars := TTextEditorUnknownChars.Create;
  FUnknownChars.OnChange := UnknownCharsChanged;
  { Fonts }
  FFonts := TTextEditorFonts.Create;

  FFonts.CodeFoldingHint.OnChanged := FontChanged;
  FFonts.CompletionProposal.OnChanged := FontChanged;
  FFonts.LineNumbers.OnChanged := FontChanged;
  FFonts.Minimap.OnChanged := FontChanged;
  FFonts.Ruler.OnChanged := FontChanged;
  FFonts.Text.OnChanged := FontChanged;

  FFontStyles := TTextEditorFontStyles.Create;
  { Painting }
  FPaintHelper := TTextEditorPaintHelper.Create([], FFonts.Text);
  FItalic.Bitmap := TBitmap.Create;
  FItalic.Offset := 0;

  { Undo & Redo }
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
  FBookmarkList.OnChange := BookmarkListChanged;
  FCaretBookmarkList := TTextEditorMarkList.Create(Self);
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
  TabStop := TTextEditorDefaults.TabStop;
  FTabs := TTextEditorTabs.Create;
  FTabs.OnChange := TabsChanged;
  { Text }
  FOvertypeMode := TTextEditorDefaults.OvertypeMode;
  FKeyboardHandler := TTextEditorKeyboardHandler.Create;
  FKeyCommands := TTextEditorKeyCommands.Create(Self);
  SetDefaultKeyCommands;
  FState.WantReturns := TTextEditorDefaults.WantReturns;
  FLineNumbers.TopLine := 1;
  FViewPosition.Column := 1;
  FViewPosition.Row := 1;
  FPosition.SelectionStart.Char := 1;
  FPosition.SelectionStart.Line := 1;
  FPosition.SelectionEnd := FPosition.SelectionStart;
  FOptions := TTextEditorDefaults.Options;
  { Scroll }
  FScrollHelper.HorizontalPosition := 0;
  FScrollHelper.LastHorizontalPosition := -1;
  FScrollHelper.LastVerticalPosition := -1;
  FScrollHelper.Timer := TTextEditorTimer.Create(Self);
  FScrollHelper.Timer.Enabled := False;
  FScrollHelper.Timer.Interval := 100;
  FScrollHelper.Timer.OnTimer := ScrollTimerHandler;
  FScrollHelper.HintTimer := TTextEditorTimer.Create(Self);
  FScrollHelper.HintTimer.Enabled := False;
  FScrollHelper.HintTimer.Interval := 100;
  FScrollHelper.HintTimer.OnTimer := ScrollHintTimerHandler;
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

  FVerticalScrollBar := TScrollBar.Create(nil);
  FVerticalScrollBar.Stored := False;
  FVerticalScrollBar.Parent := Self;
  FVerticalScrollBar.Orientation := TOrientation.Vertical;
  FVerticalScrollBar.Cursor := crArrow;
  FVerticalScrollBar.Width := 16;
  FVerticalScrollBar.SmallChange := 1;
  FVerticalScrollBar.Visible := False;
  FVerticalScrollBar.OnChange := ScrollBarChange;
  FVerticalScrollBar.OnMouseDown := ScrollBarMouseDown;
  FVerticalScrollBar.OnMouseMove := ScrollBarMouseMove;
  FVerticalScrollBar.OnMouseUp := ScrollBarMouseUp;

  FHorizontalScrollBar := TScrollBar.Create(nil);
  FHorizontalScrollBar.Stored := False;
  FHorizontalScrollBar.Parent := Self;
  FHorizontalScrollBar.Orientation := TOrientation.Horizontal;
  FHorizontalScrollBar.Cursor := crArrow;
  FHorizontalScrollBar.Height := 16;
  FHorizontalScrollBar.SmallChange := FPaintHelper.CharWidth;
  FHorizontalScrollBar.Visible := False;
  FHorizontalScrollBar.OnChange := ScrollBarChange;
  FHorizontalScrollBar.OnMouseDown := ScrollBarMouseDown;
  FHorizontalScrollBar.OnMouseMove := ScrollBarMouseMove;
  FHorizontalScrollBar.OnMouseUp := ScrollBarMouseUp;

  { Minimap }
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
  { Highlight line }
  FHighlightLine := TTextEditorHighlightLine.Create(Self);
  { Highlighter }
  FHighlighter := TTextEditorHighlighter.Create(Self);
  FHighlighter.Lines := FLines;

  { Theme }
  if csDesigning in ComponentState then
    FTheme := TTextEditorTheme.Create(FHighlighter);

  { Mouse wheel scroll cursors }
  FMouse.ScrollCursors[TMouseWheelScrollCursors.North] := crSizeNS;
  FMouse.ScrollCursors[TMouseWheelScrollCursors.NorthEast] := crSizeNESW;
  FMouse.ScrollCursors[TMouseWheelScrollCursors.East] := crSizeWE;
  FMouse.ScrollCursors[TMouseWheelScrollCursors.SouthEast] := crSizeNWSE;
  FMouse.ScrollCursors[TMouseWheelScrollCursors.South] := crSizeNS;
  FMouse.ScrollCursors[TMouseWheelScrollCursors.SouthWest] := crSizeNESW;
  FMouse.ScrollCursors[TMouseWheelScrollCursors.West] := crSizeWE;
  FMouse.ScrollCursors[TMouseWheelScrollCursors.NorthWest] := crSizeNWSE;

  { Update character constraints }
  SizeOrFontChanged;
  TabsChanged(nil);
end;

destructor TCustomTextEditor.Destroy;
begin
  if Assigned(FChainedEditor) then
    RemoveChainedEditor;

  FreeCompletionProposalPopupWindow;
  { The display controls themselves are owned components; only the list is freed here. }
  FMultiCaretDisplays.Free;
  FTextLayout.Free;

  FBorder.Free;

  ClearCodeFolding;

  FCodeFolding.Free;
  FCodeFoldings.DelayTimer.Free;
  FColors.Free;
  FCodeFoldings.AllRanges.Free;
  FFonts.Free;
  FFontStyles.Free;
  FHighlightLine.Free;
  FHighlightLine := nil;
  FHighlighter.Free;

  if Assigned(FTheme) then
    FTheme.Free;

  FreeCompletionProposalPopupWindow;

  { Do not use FreeAndNil, it first nils and then frees causing problems with code accessing FHookedCommandHandlers while destruction }
  FHookedCommandHandlers.Free;
  FHookedCommandHandlers := nil;

  FBookmarkList.Free;
  FCaretBookmarkList.Free;
  FMarkList.Free;
  FKeyCommands.Free;
  FKeyboardHandler.Free;
  FSelection.Free;
  FOriginal.UndoList.Free;
  FOriginal.RedoList.Free;

  FLeftMargin.Free;
  FLeftMargin := nil; { Notification has a check }

  FMinimap.Free;
  FRuler.Free;
  FWordWrap.Free;
  FOriginal.Lines.Free;
  FreeScrollShadowBitmap;
  FreeMinimapBitmaps;
  FActiveLine.Free;
  FRightMargin.Free;

  if Assigned(FHorizontalScrollBar) then
  begin
    FHorizontalScrollBar.OnChange := nil;
    FHorizontalScrollBar.Parent := nil;
    FHorizontalScrollBar.Free;
  end;

  if Assigned(FVerticalScrollBar) then
  begin
    FVerticalScrollBar.OnChange := nil;
    FVerticalScrollBar.Parent := nil;
    FVerticalScrollBar.Free;
  end;

  FScroll.Free;
  FSearch.Free;
  FReplace.Free;
  FTabs.Free;
  FUndo.Free;
  FSpecialChars.Free;
  FPartialLoad.Free;
  FUnknownChars.Free;
  FCaret.Free;
  FreeMultiCarets;
  FMatchingPairs.Free;
  FCompletionProposal.Free;
  FSyncEdit.Free;
  FItalic.Bitmap.Free;

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
    FSearchEngine.Free;

  if Assigned(FCodeFoldings.HintForm) then
    FCodeFoldings.HintForm.Free;

  if Length(FWordWrapLine.Length) > 0 then
    SetLength(FWordWrapLine.Length, 0);

  if Length(FWordWrapLine.ViewLength) > 0 then
    SetLength(FWordWrapLine.ViewLength, 0);

  if Length(FWordWrapLine.Width) > 0 then
    SetLength(FWordWrapLine.Width, 0);

  FPaintHelper.Free;
  FPaintHelper := nil;

  FreeBookmarkImages;

  inherited Destroy;
end;

procedure TCustomTextEditor.FreeBookmarkImages;
begin
  if Assigned(FImagesBookmark) then
  begin
    FImagesBookmark.Free;
    FImagesBookmark := nil;
  end;
end;

{ Private declarations }

function TCustomTextEditor.AddSnippet(const AExecuteWith: TTextEditorSnippetExecuteWith; const ATextPosition: TTextEditorTextPosition): Boolean;
var
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

  if LKeyword.IsEmpty then
    LKeyword := GetCharAtTextPosition(LTextPosition);

  if LKeyword.IsEmpty then
    Exit;

  for var LIndex := 0 to FCompletionProposal.Snippets.Items.Count - 1 do
  begin
    LSnippetItem := FCompletionProposal.Snippets.Item[LIndex];

    if (LSnippetItem.ExecuteWith = AExecuteWith) and (LSnippetItem.Keyword.Trim = LKeyword) then
    begin
      InsertSnippet(LSnippetItem, LTextPosition);
      Exit(True);
    end;
  end;
end;

function TCustomTextEditor.AllWhiteUpToTextPosition(const ATextPosition: TTextEditorTextPosition; const ALine: string; const ALength: Integer): Boolean;
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
  Result := CharIndexToTextPosition(ACharIndex, GetBOFPosition);
end;

function TCustomTextEditor.CharIndexToTextPosition(const ACharIndex: Integer;
  const ATextBeginPosition: TTextEditorTextPosition; const ACountLineBreak: Boolean = True): TTextEditorTextPosition;
var
  LBeginChar, LCharIndex: Integer;
  LLineLength: Integer;
begin
  Result.Line := ATextBeginPosition.Line;

  LBeginChar := ATextBeginPosition.Char;
  LCharIndex := ACharIndex;

  for var LIndex := ATextBeginPosition.Line to FLines.Count - 1 do
  begin
    LLineLength := FLines.TextLines[LIndex].Length - LBeginChar + 1;

    if ACountLineBreak then
      Inc(LLineLength, FLines.LineBreakLength(LIndex));

    if LCharIndex <= LLineLength then
    begin
      Result.Char := LBeginChar + LCharIndex;

      Break;
    end
    else
    begin
      Inc(Result.Line);
      Dec(LCharIndex, LLineLength - 1);
    end;

    LBeginChar := 0;
  end;
end;

function TCustomTextEditor.CodeFoldingRangeForLine(const ALine: Integer): TTextEditorCodeFoldingRange;
begin
  Result := nil;

  if (ALine > 0) and (ALine < Length(FCodeFoldings.RangeFromLine)) then
    Result := FCodeFoldings.RangeFromLine[ALine];
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

    if Assigned(LCodeFoldingRange) and (LCodeFoldingRange.ToLine = ALine) and not LCodeFoldingRange.ParentCollapsed then
      Result := LCodeFoldingRange;
  end;
end;

function TCustomTextEditor.CodeFoldingLineInsideRange(const ALine: Integer): TTextEditorCodeFoldingRange;
var
  LLine: Integer;
  LLength: Integer;
begin
  Result := nil;

  LLine := ALine;
  LLength := Length(FCodeFoldings.RangeFromLine) - 1;

  if LLine > LLength then
    LLine := LLength;

  while (LLine > 0) and not Assigned(FCodeFoldings.RangeFromLine[LLine]) do
    Dec(LLine);

  if (LLine > 0) and Assigned(FCodeFoldings.RangeFromLine[LLine]) then
    Result := FCodeFoldings.RangeFromLine[LLine];
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
    Result := FCodeFoldings.TreeLine[ALine];
end;

function TCustomTextEditor.DoOnCodeFoldingHintClick(const APoint: TPointF): Boolean;
var
  LFoldRange: TTextEditorCodeFoldingRange;
  LCollapseMarkRect: TRectF;
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
  LHandler: TTextEditorHookedCommandHandler;
begin
  Result := GetHookedCommandHandlersCount - 1;

  while Result >= 0 do
  begin
    LHandler := TTextEditorHookedCommandHandler(FHookedCommandHandlers[Result]);

    if LHandler.Equals(AHookedCommandEvent) then
      Break;

    Dec(Result);
  end;
end;

procedure TCustomTextEditor.DoTrimTrailingSpaces(const ATextLine: Integer; const AForceTrim: Boolean = False);
begin
  if (eoTrimTrailingSpaces in FOptions) or AForceTrim then
    FLines.DoTrimTrailingSpaces(ATextLine);
end;

function TCustomTextEditor.BorderWidth: Integer;
begin
  Result := IfThen(FBorder.Style = bsSingle, 1, 0);
end;

function TCustomTextEditor.ClientHeight: Integer;
begin
  Result := Round(Height);

  if Assigned(FHorizontalScrollBar) and FHorizontalScrollBar.Visible then
    Result := Result - Round(FHorizontalScrollBar.Height) - BorderWidth;
end;

function TCustomTextEditor.ClientRect: TRect;
begin
  Result := TRect.Create(0, 0, ClientWidth, ClientHeight);
end;

function TCustomTextEditor.ClientWidth: Integer;
begin
  Result := Round(Width);

  if Assigned(FVerticalScrollBar) and FVerticalScrollBar.Visible then
    Result := Result - Round(FVerticalScrollBar.Width) - BorderWidth;
end;

function TCustomTextEditor.Dragging: Boolean;
begin
  Result := sfDragging in FState.Flags;
end;

function TCustomTextEditor.Focused: Boolean;
begin
  Result := IsFocused;
end;

function TCustomTextEditor.HandleAllocated: Boolean;
begin
  Result := True;
end;

procedure TCustomTextEditor.BeginDrag(AImmediate: Boolean);
begin
  if Assigned(Root) then
    Root.BeginInternalDrag(Self, nil);
end;

procedure TCustomTextEditor.TrimTrailingSpaces;
begin
  for var LLine := 0 to FLines.Count - 1 do
    DoTrimTrailingSpaces(LLine, True);

  Repaint;
end;

procedure TCustomTextEditor.DoWordLeft(const ACommand: TTextEditorCommand);
var
  LTextPosition, LCaretNewPosition: TTextEditorTextPosition;
begin
  LTextPosition := TextPosition;

  FUndoList.BeginBlock;
  try
    FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);

    LCaretNewPosition := WordStart;

    if AreTextPositionsEqual(LCaretNewPosition, LTextPosition) or (ACommand = TKeyCommands.WordLeft) then
      LCaretNewPosition := PreviousWordPosition;

    MoveCaretAndSelection(LTextPosition, LCaretNewPosition, ACommand = TKeyCommands.SelectionWordLeft);
  finally
    FUndoList.EndBlock;
  end;
end;

procedure TCustomTextEditor.DoWordRight(const ACommand: TTextEditorCommand);
var
  LTextPosition, LCaretNewPosition: TTextEditorTextPosition;
begin
  LTextPosition := TextPosition;

  FUndoList.BeginBlock;
  try
    FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);

    LCaretNewPosition := WordEnd;

    if AreTextPositionsEqual(LCaretNewPosition, LTextPosition) or (ACommand = TKeyCommands.WordRight) then
      LCaretNewPosition := NextWordPosition;

    MoveCaretAndSelection(LTextPosition, LCaretNewPosition, ACommand = TKeyCommands.SelectionWordRight);
  finally
    FUndoList.EndBlock;
  end;
end;

procedure TCustomTextEditor.DragMinimap(const AY: Single);
var
  LTemp, LTemp2: Single;
  LTopLine: Integer;
begin
  LTemp := FLineNumbers.Count - FMinimap.VisibleLineCount;
  LTemp2 := AY / FMinimap.CharHeight - FMinimapHelper.ClickOffsetY;

  if LTemp2 < 0 then
    LTemp2 := 0;

  FMinimap.TopLine := Max(1, Trunc((LTemp / Max(FMinimap.VisibleLineCount - FLineNumbers.VisibleCount, 1)) * LTemp2));

  if (LTemp > 0) and (FMinimap.TopLine > LTemp) then
    FMinimap.TopLine := Round(LTemp);

  LTopLine := Max(1, FMinimap.TopLine + Round(LTemp2));

  if TopLine <> LTopLine then
  begin
    TopLine := LTopLine;

    FMinimap.TopLine := Max(FLineNumbers.TopLine - Abs(Trunc((FMinimap.VisibleLineCount - FLineNumbers.VisibleCount) *
      (FLineNumbers.TopLine / Max(Max(FLineNumbers.Count, 1) - FLineNumbers.VisibleCount, 1)))), 1);

    Repaint;
  end;
end;

procedure TCustomTextEditor.PaintBorder;
var
  LOldStrokeColor: TAlphaColor;
begin
  if FBorder.Style = bsSingle then
  begin
    LOldStrokeColor := Canvas.Stroke.Color;

    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Color := FBorder.Color;
    Canvas.Stroke.Thickness := 1;

    if FBorder.ColoredEdges = [] then
      Canvas.DrawRect(RectF(0.5, 0.5, Width - 0.5, Height - 0.5), 0, 0, [], 1)
    else
    begin
      if ebLeft in FBorder.ColoredEdges then
        DrawPixelLine(0, Height - 1, 0, 0);

      if ebTop in FBorder.ColoredEdges then
        DrawPixelLine(0, 0, Width, 0);

      if ebRight in FBorder.ColoredEdges then
        DrawPixelLine(Width - 1, 0, Width - 1, Height);

      if ebBottom in FBorder.ColoredEdges then
        DrawPixelLine(Width - 1, Height - 1, 0, Height - 1);
    end;

    Canvas.Stroke.Color := LOldStrokeColor;
  end;
end;

procedure TCustomTextEditor.FillRect(const ARect: TRectF);
var
  LScale: Single;
  LRect: TRectF;
begin
  LScale := if Assigned(Scene) then Scene.GetSceneScale else 1;

  if LScale <= 0 then
    LScale := 1;

  LRect.Left := Round(ARect.Left * LScale) / LScale;
  LRect.Top := Round(ARect.Top * LScale) / LScale;
  LRect.Right := Round(ARect.Right * LScale) / LScale;
  LRect.Bottom := Round(ARect.Bottom * LScale) / LScale;

  if (LRect.Right <= LRect.Left) and (ARect.Right > ARect.Left) then
    LRect.Right := LRect.Left + 1 / LScale;

  if (LRect.Bottom <= LRect.Top) and (ARect.Bottom > ARect.Top) then
    LRect.Bottom := LRect.Top + 1 / LScale;

  Canvas.FillRect(LRect, 0, 0, [], 1);
end;

function TCustomTextEditor.GetCanPaste: Boolean;
var
  LClipboardService: IFMXClipboardService;
  LValue: TValue;
begin
  Result := False;

  if not ReadOnly and TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LClipboardService) then
  begin
    LValue := LClipboardService.GetClipboard;
    Result := LValue.IsType<string> and not LValue.AsString.IsEmpty;
  end;
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
  LLineBreak: Boolean;
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

    LLineBreak := IsLineTerminatorCharacter(LPText^);

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

    if LLineBreak then
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

function TCustomTextEditor.GetCharAtTextPosition(const ATextPosition: TTextEditorTextPosition; const ASelect: Boolean = False): Char;
var
  LTextLine: string;
  LLength: Integer;
begin
  Result := TControlCharacters.Null;

  LTextLine := FLines[ATextPosition.Line];
  LLength := LTextLine.Length;

  if LLength = 0 then
    Exit;

  if ATextPosition.Char <= LLength then
    Result := LTextLine[ATextPosition.Char];

  if ASelect then
  begin
    FPosition.SelectionStart := ATextPosition;
    FPosition.SelectionEnd := ATextPosition;

    Inc(FPosition.SelectionEnd.Char);
  end;
end;

function TCustomTextEditor.GetPreviousCharAtCursor: Char;
var
  LTextPosition: TTextEditorTextPosition;
  LTextLine: string;
  LPosition, LLength: Integer;
begin
  Result := TControlCharacters.Null;

  LTextPosition := TextPosition;
  LTextLine := FLines[LTextPosition.Line];
  LLength := LTextLine.Length;

  if LLength = 0 then
    Exit;

  LPosition := LTextPosition.Char - 1;

  if (LPosition > 0) and (LPosition <= LLength) then
    Result := LTextLine[LPosition];
end;

procedure TCustomTextEditor.GetCommentAtTextPosition(const ATextPosition: TTextEditorTextPosition; var AComment: string);
var
  LTextPosition: TTextEditorTextPosition;
  LTextLine: string;
  LPosition, LLength: Integer;
begin
  AComment := '';

  LTextPosition := ATextPosition;
  LTextLine := FLines[LTextPosition.Line];
  LLength := LTextLine.Length;

  if LLength = 0 then
    Exit;

  if (LTextPosition.Char >= 1) and (LTextPosition.Char <= LLength) and IsCommentChar(LTextLine[LTextPosition.Char]) then
  begin
    LPosition := LTextPosition.Char;

    while (LPosition <= LLength) and IsCommentChar(LTextLine[LPosition]) do
      Inc(LPosition);

    while (LTextPosition.Char > 1) and IsCommentChar(LTextLine[LTextPosition.Char - 1]) do
      Dec(LTextPosition.Char);

    if LPosition > LTextPosition.Char then
      AComment := Copy(LTextLine, LTextPosition.Char, LPosition - LTextPosition.Char);
  end;
end;

function TCustomTextEditor.GetCharWidth: Single;
begin
  Result := FPaintHelper.CharWidth;
end;

function TCustomTextEditor.GetViewLineNumber(const AViewLineNumber: Integer): Integer;
var
  LLength: Integer;
  LFirst, LLast, LPivot: Integer;
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
      LPivot := (LFirst + LLast) shr 1;

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
      end;
    end;
  end;
end;

function TCustomTextEditor.GetEndOfLine(const ALine: PChar): PChar;
begin
  Result := ALine;

  while Result^ <> TControlCharacters.Null do
  if IsLineTerminatorCharacter(Result^) then
    Break
  else
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
  LPositionX, LPositionY, LEnd: Integer;
  LTextLine: string;
  LTokenType: TTextEditorRangeType;
  LToken: string;
begin
  Result := False;

  if FSimpleMode then
    Exit;

  LPositionY := ATextPosition.Line;

  if (LPositionY >= 0) and (LPositionY < FLines.Count) then
  begin
    LTextLine := FLines.TextLines[LPositionY];

    if LPositionY = 0 then
      FHighlighter.ResetRange
    else
      FHighlighter.SetRange(FLines.Ranges[LPositionY - 1]);

    FHighlighter.SetLine(LTextLine);

    LPositionX := ATextPosition.Char;

    if (LPositionX > 0) and (LPositionX <= LTextLine.Length) then
    begin
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

          Inc(LEnd, LToken.Length);
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
  end;

  AToken := '';
  AHighlighterAttribute := nil;
end;

function TCustomTextEditor.GetHookedCommandHandlersCount: Integer;
begin
  Result := if Assigned(FHookedCommandHandlers) then FHookedCommandHandlers.Count else 0;
end;

function TCustomTextEditor.GetHorizontalScrollMax: Single;
begin
  Result := Max(FLines.GetLengthOfLongestLine * FPaintHelper.CharWidth, FScrollHelper.PageWidth);

  if soPastEndOfLine in FScroll.Options then
    Result := Result + FScrollHelper.PageWidth;
end;

function TCustomTextEditor.GetInlineSelectionAvailable: Boolean;
begin
  Result := FSelection.Visible and (FPosition.SelectionStart.Char <> FPosition.SelectionEnd.Char) and (FPosition.SelectionStart.Line = FPosition.SelectionEnd.Line);
end;

function TCustomTextEditor.GetItalicOffset(const AChar: Char): Byte;
var
  LBitmapData: TBitmapData;
  LAdvance, LWidth, LHeight: Integer;
  LX, LY, LMaxX: Integer;
begin
  Result := 0;

  LAdvance := Floor(FPaintHelper.CharWidth);

  if LAdvance <= 0 then
    Exit;

  LWidth := LAdvance * 2 + 4;
  LHeight := Ceil(GetLineHeight);

  if (FItalic.Bitmap.Width <> LWidth) or (FItalic.Bitmap.Height <> LHeight) then
    FItalic.Bitmap.SetSize(LWidth, LHeight);

  if FItalic.Bitmap.Canvas.BeginScene then
  try
    FItalic.Bitmap.Canvas.Clear(TAlphaColors.Null);
    FItalic.Bitmap.Canvas.Font.Assign(Canvas.Font);
    FItalic.Bitmap.Canvas.Fill.Kind := TBrushKind.Solid;
    FItalic.Bitmap.Canvas.Fill.Color := TAlphaColors.White;
    FItalic.Bitmap.Canvas.FillText(RectF(0, 0, LWidth, LHeight), AChar, False, 1, [], TTextAlign.Leading,
      TTextAlign.Leading);
  finally
    FItalic.Bitmap.Canvas.EndScene;
  end;

  LMaxX := -1;

  if FItalic.Bitmap.Map(TMapAccess.Read, LBitmapData) then
  try
    LX := FItalic.Bitmap.Width - 1;

    while (LX >= LAdvance) and (LMaxX = -1) do
    begin
      for LY := 0 to FItalic.Bitmap.Height - 1 do
      if TAlphaColorRec(LBitmapData.GetPixel(LX, LY)).A <> 0 then
      begin
        LMaxX := LX;
        Break;
      end;

      Dec(LX);
    end;
  finally
    FItalic.Bitmap.Unmap(LBitmapData);
  end;

  if LMaxX >= 0 then
    Result := EnsureRange(Ceil(LMaxX + 1 - FPaintHelper.CharWidth), 0, High(Byte));
end;

function TCustomTextEditor.GetLeadingExpandedLength(const AText: string; const ABorder: Integer = 0): Integer;
var
  LChar: PChar;
  LLength: Integer;
begin
  Result := 0;

  LChar := PChar(AText);
  LLength := if ABorder > 0 then Min(PInteger(LChar - 2)^, ABorder) else PInteger(LChar - 2)^;

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
  Result := FLeftMargin.GetWidth;

  if not FSimpleMode then
    Inc(Result, FCodeFolding.GetWidth);

  if FMinimap.Align = maLeft then
    Inc(Result, FMinimap.GetWidth);

  if FSearch.Map.Align = saLeft then
    Inc(Result, FSearch.Map.GetWidth);
end;

function TCustomTextEditor.GetLineHeight: Single;
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

  LPLine := PChar(FLines.TextLines[ALine]);

  while (LPLine^ <> TControlCharacters.Null) and (LPLine^ in [TControlCharacters.Tab, TCharacters.Space, TControlCharacters.Substitute]) do
  begin
    if LPLine^ = TControlCharacters.Tab then
      Inc(Result, if FLines.Columns then FTabs.Width - Result mod FTabs.Width else FTabs.Width)
    else
      Inc(Result);

    Inc(LPLine);
  end;
end;

function TCustomTextEditor.GetMarkBackgroundColor(const ALine: Integer): TAlphaColor;
var
  LMark: TTextEditorMark;
begin
  Result := TAlphaColors.Null;

  { Bookmarks }
  if FColors.BookmarkLineBackground <> TAlphaColors.Null then
  for var LIndex := 0 to FBookmarkList.Count - 1 do
  begin
    LMark := FBookmarkList.Items[LIndex];

    if LMark.Line + 1 = ALine then
    begin
      Result := FColors.BookmarkLineBackground;
      Break;
    end;
  end;

  { Custom marks }
  for var LIndex := 0 to FMarkList.Count - 1 do
  begin
    LMark := FMarkList.Items[LIndex];

    if (LMark.Line + 1 = ALine) and (LMark.Background <> TAlphaColors.Null) then
    begin
      Result := LMark.Background;
      Break;
    end;
  end;
end;

function TCustomTextEditor.GetMatchingToken(const AViewPosition: TTextEditorViewPosition;
  var AMatch: TTextEditorMatchingPairMatch): TTextEditorMatchingTokenResult;
var
  LToken: string;
  LOpenDuplicateLength, LCloseDuplicateLength: Integer;

  function IsOpenToken: Boolean;
  begin
    Result := True;

    for var LIndex := 0 to LOpenDuplicateLength - 1 do
    if LToken = PTextEditorMatchingPairToken(FHighlighter.MatchingPairs[FMatchingPair.OpenDuplicate[LIndex]])^.OpenToken then
      Exit;

    Result := False;
  end;

  function IsCloseToken: Boolean;
  begin
    Result := True;

    for var LIndex := 0 to LCloseDuplicateLength - 1 do
    if LToken = PTextEditorMatchingPairToken(FHighlighter.MatchingPairs[FMatchingPair.CloseDuplicate[LIndex]])^.CloseToken then
      Exit;

    Result := False;
  end;

  var
    LLevel: Integer;
    LTextPosition: TTextEditorTextPosition;
    LIsBlockComment: Boolean;
    LTokenType: TTextEditorRangeType;

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
    end;
  end;

  var
    LMatchStackID: Integer;

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

    FHighlighter.SetLine(FLines[LTextPosition.Line]);
  end;

  function CheckComment(const AToken: string; const AComment: string): Boolean; inline;
  var
    LPComment, LPCommentAtCursor: PChar;
  begin
    LPComment := PChar(AComment);
    LPCommentAtCursor := PChar(AToken);

    while (LPComment^ <> TControlCharacters.Null) and (LPCommentAtCursor^ <> TControlCharacters.Null) and (LPCommentAtCursor^ = LPComment^) do
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
  LIndex: Integer;
  LCheckOnlyOneLine: Boolean;
  LCount: Integer;
  LOriginalToken: string;
  LMatchingPairToken: TTextEditorMatchingPairToken;
  LTempToken: string;
  LTokenCount: Integer;
  LTokenMatch: PTextEditorMatchingPairToken;
  LDeltaLevel: Integer;
begin
  Result := trNotFound;

  if not FHighlighter.Loaded then
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
    LToken := FMX.TextEditor.Utils.Trim(LowerCase(LOriginalToken));

    if LToken.IsEmpty then
      Exit;

    LTokenType := TokenType;
    LIsBlockComment := IsBlockComment(LToken);

    if not (LTokenType in [ttReservedWord, ttSymbol]) and not (LIsBlockComment and (LTokenType = ttBlockComment)) then
      Exit;

    while LIndex < LCount do
    begin
      LMatchingPairToken := PTextEditorMatchingPairToken(FHighlighter.MatchingPairs[LIndex])^;

      if (LToken = LMatchingPairToken.OpenToken) and (LToken = LMatchingPairToken.CloseToken) then
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
      if LToken = LMatchingPairToken.OpenToken then
      begin
        Result := trOpenTokenFound;

        AMatch.OpenToken := LOriginalToken;
        AMatch.OpenTokenPos.Line := LTextPosition.Line;
        AMatch.OpenTokenPos.Char := TokenPosition + 1;

        Break;
      end
      else
      if LToken = LMatchingPairToken.CloseToken then
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
      LMatchingPairToken := PTextEditorMatchingPairToken(FHighlighter.MatchingPairs[LIndex])^;

      if LTokenMatch^.OpenToken = LMatchingPairToken.OpenToken then
      begin
        FMatchingPair.CloseDuplicate[LCloseDuplicateLength] := LIndex;
        Inc(LCloseDuplicateLength);
      end;

      if LTokenMatch^.CloseToken = LMatchingPairToken.CloseToken then
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
      begin
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
end;

function TCustomTextEditor.GetMouseScrollCursors(const AIndex: Integer): TCursor;
begin
  Result := 0;

  if (AIndex >= Low(FMouse.ScrollCursors)) and (AIndex <= High(FMouse.ScrollCursors)) then
    Result := FMouse.ScrollCursors[AIndex];
end;

function TCustomTextEditor.GetMouseScrollCursorIndex: Integer;
var
  LCursorPoint: TPointF;
  LLeftX, LRightX, LTopY, LBottomY: Single;
begin
  Result := scNone;

  LCursorPoint := ScreenToLocal(Screen.MousePos);

  LLeftX := FMouse.ScrollingPoint.X - FScroll.Indicator.Width;
  LRightX := FMouse.ScrollingPoint.X + 4;
  LTopY := FMouse.ScrollingPoint.Y - FScroll.Indicator.Height;
  LBottomY := FMouse.ScrollingPoint.Y + 4;

  if LCursorPoint.Y < LTopY then
  begin
    if LCursorPoint.X < LLeftX then
      Exit(TMouseWheelScrollCursors.NorthWest)
    else
    if (LCursorPoint.X >= LLeftX) and (LCursorPoint.X <= LRightX) then
      Exit(TMouseWheelScrollCursors.North)
    else
      Exit(TMouseWheelScrollCursors.NorthEast);
  end;

  if LCursorPoint.Y > LBottomY then
  begin
    if LCursorPoint.X < LLeftX then
      Exit(TMouseWheelScrollCursors.SouthWest)
    else
    if (LCursorPoint.X >= LLeftX) and (LCursorPoint.X <= LRightX) then
      Exit(TMouseWheelScrollCursors.South)
    else
      Exit(TMouseWheelScrollCursors.SouthEast);
  end;

  if LCursorPoint.X < LLeftX then
    Exit(TMouseWheelScrollCursors.West);

  if LCursorPoint.X > LRightX then
    Exit(TMouseWheelScrollCursors.East);
end;

function TCustomTextEditor.GetScrollPageWidth: Integer;
begin
  Result := Max(ClientWidth - FLeftMargin.GetWidth - FCodeFolding.GetWidth - 2 - FMinimap.GetWidth - FSearch.Map.GetWidth, 0);
end;

function TCustomTextEditor.GetSelectionAvailable: Boolean;
begin
  Result := FSelection.Visible and ((FPosition.SelectionStart.Char <> FPosition.SelectionEnd.Char) or
    ((FPosition.SelectionStart.Line <> FPosition.SelectionEnd.Line) and (FSelection.ActiveMode <> smColumn)));
end;

procedure TCustomTextEditor.SwapInt(var ALeft: Integer; var ARight: Integer);
var
  LTemp: Integer;
begin
  LTemp := ARight;

  ARight := ALeft;
  ALeft := LTemp;
end;

function TCustomTextEditor.GetSelectedText: string;

  function CopyPadded(const AValue: string; const AIndex: Integer; const ACount: Integer): string;
  var
    LSourceLength, LDestinationLength: Integer;
    LPResult: PChar;
  begin
    LSourceLength := AValue.Length;
    LDestinationLength := AIndex + ACount;

    if LSourceLength >= LDestinationLength then
      Result := Copy(AValue, AIndex, ACount)
    else
    begin
      SetLength(Result, LDestinationLength);

      LPResult := PChar(Result);

      StrCopy(LPResult, PChar(Copy(AValue, AIndex, ACount)));

      Inc(LPResult, AValue.Length);

      for var LIndex := 0 to LDestinationLength - LSourceLength - 1 do
        LPResult[LIndex] := TCharacters.Space;
    end;
  end;

  procedure CopyAndForward(const AValue: string; AIndex: Integer; const ACount: Integer; var APResult: PChar);
  var
    LSourceLength: Integer;
    LPSource: PChar;
    LDestinationLength: Integer;
  begin
    LSourceLength := AValue.Length;

    if (AIndex <= LSourceLength) and (ACount > 0) then
    begin
      Dec(AIndex);

      LPSource := PChar(AValue) + AIndex;
      LDestinationLength := Min(LSourceLength - AIndex, ACount);

      System.Move(LPSource^, APResult^, LDestinationLength * SizeOf(Char));
      Inc(APResult, LDestinationLength);
      APResult^ := TControlCharacters.Null;
    end;
  end;

  function CopyPaddedAndForward(const AValue: string; const AIndex: Integer; const ACount: Integer; var APResult: PChar): Integer;
  var
    LPResult: PChar;
    LLength: Integer;
  begin
    Result := 0;

    LPResult := APResult;

    CopyAndForward(AValue, AIndex, ACount, APResult);

    LLength := ACount - (APResult - LPResult);

    if not (eoTrimTrailingSpaces in Options) and (APResult - LPResult > 0) then
    begin
      for var LIndex := 0 to LLength - 1 do
        APResult[LIndex] := TCharacters.Space;

      Inc(APResult, LLength);
    end
    else
      Result := LLength;
  end;

  function DoGetSelectedText: string;
  var
    LColumnFrom, LFirstLine, LColumnTo, LLastLine: Integer;
    LTotalLength: Integer;
    LItem: TTextEditorStringRecord;
    LPResult: PChar;
    LLeftCharPosition, LRightCharPosition: Integer;
    LLineText: string;
    LTextPosition: TTextEditorTextPosition;
    LViewPosition: TTextEditorViewPosition;
    LTrimCount: Integer;
  begin
    LColumnFrom := SelectionStartPosition.Char;
    LFirstLine := SelectionStartPosition.Line;
    LColumnTo := SelectionEndPosition.Char;
    LLastLine := SelectionEndPosition.Line;

    case FSelection.ActiveMode of
      smNormal:
        begin
          if LFirstLine = LLastLine then
            Result := Copy(FLines[LFirstLine], LColumnFrom, LColumnTo - LColumnFrom)
          else
          begin
            LTotalLength := Max(0, FLines[LFirstLine].Length - LColumnFrom + 1);

            Inc(LTotalLength, FLines.LineBreakLength(LFirstLine));

            for var LLine := LFirstLine + 1 to LLastLine - 1 do
            begin
              LItem := FLines.Items^[LLine];

              Inc(LTotalLength, LItem.TextLine.Length);

              if not (sfEmptyLine in LItem.Flags) then
                Inc(LTotalLength, FLines.LineBreakLength(LLine));
            end;

            Inc(LTotalLength, LColumnTo - 1);

            SetLength(Result, LTotalLength);

            LPResult := PChar(Result);

            CopyAndForward(FLines[LFirstLine], LColumnFrom, LTotalLength, LPResult);
            CopyAndForward(FLines.GetLineBreak(LFirstLine), 1, LTotalLength, LPResult);

            for var LLine := LFirstLine + 1 to LLastLine - 1 do
            begin
              LItem := FLines.Items^[LLine];

              CopyAndForward(LItem.TextLine, 1, LTotalLength, LPResult);

              if not (sfEmptyLine in LItem.Flags) then
                CopyAndForward(FLines.GetLineBreak(LLine), 1, LTotalLength, LPResult);
            end;

            CopyAndForward(FLines[LLastLine], 1, LColumnTo - 1, LPResult);
          end;
        end;
      smColumn:
        begin
          with TextToViewPosition(SelectionStartPosition) do
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

          for var LRow := LFirstLine to LLastLine do
          begin
            LViewPosition.Row := LRow;
            LViewPosition.Column := LColumnFrom;
            LTextPosition := ViewToTextPosition(LViewPosition);

            LLeftCharPosition := LTextPosition.Char;

            LLineText := FLines.TextLines[LTextPosition.Line];

            LViewPosition.Column := LColumnTo;
            LRightCharPosition := ViewToTextPosition(LViewPosition).Char;

            LTrimCount := CopyPaddedAndForward(LLineText, LLeftCharPosition, LRightCharPosition - LLeftCharPosition, LPResult);

            LTotalLength := LTotalLength + (LRightCharPosition - LLeftCharPosition) - LTrimCount + FLines.LineBreakLength(LTextPosition.Line);

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

function TCustomTextEditor.GetSelectionStartPosition: TTextEditorTextPosition;
var
  LLineLength: Integer;
begin
  Result :=
    if (FPosition.SelectionEnd.Line < FPosition.SelectionStart.Line) or
      ((FPosition.SelectionEnd.Line = FPosition.SelectionStart.Line) and
       (FPosition.SelectionEnd.Char < FPosition.SelectionStart.Char)) then
      FPosition.SelectionEnd
    else
      FPosition.SelectionStart;

  if FSelection.Mode = smNormal then
  begin
    LLineLength := FLines[Result.Line].Length;

    if Result.Char > LLineLength then
      Result.Char := LLineLength + 1;
  end;
end;

function TCustomTextEditor.GetSelectionEndPosition: TTextEditorTextPosition;
var
  LLineLength: Integer;
begin
  Result :=
    if (FPosition.SelectionEnd.Line < FPosition.SelectionStart.Line) or
      ((FPosition.SelectionEnd.Line = FPosition.SelectionStart.Line) and
       (FPosition.SelectionEnd.Char < FPosition.SelectionStart.Char)) then
      FPosition.SelectionStart
    else
      FPosition.SelectionEnd;

  if FSelection.Mode = smNormal then
  begin
    LLineLength := FLines[Result.Line].Length;

    if Result.Char > LLineLength then
      Result.Char := LLineLength + 1;
  end;
end;

function TCustomTextEditor.IsRulerVisible: Boolean;
begin
  Result := FRuler.Visible and not FSimpleMode;
end;

function TCustomTextEditor.IsRectInUpdateRegion(const ARect: TRectF): Boolean;
begin
  Result := True;

  if not Assigned(Scene) or (Scene.GetUpdateRectsCount = 0) then
    Exit;

  var LAbsoluteRect: TRectF := TRectF.Create(LocalToAbsolute(ARect.TopLeft), LocalToAbsolute(ARect.BottomRight));

  for var LIndex := 0 to Scene.GetUpdateRectsCount - 1 do
  if LAbsoluteRect.IntersectsWith(Scene.GetUpdateRect(LIndex)) then
    Exit;

  Result := False;
end;

function TCustomTextEditor.GetRowCountFromPixel(const AY: Single): Integer;
var
  LY: Single;
begin
  LY := AY;

  if IsRulerVisible then
    LY := LY - FRuler.Height;

  Result := Trunc(LY / GetLineHeight);
end;

function TCustomTextEditor.GetSelectedRow(const AY: Single): Integer;
begin
  Result := Max(1, Min(TopLine + GetRowCountFromPixel(AY), FLineNumbers.Count));
end;

function TCustomTextEditor.GetSelectionStart: Integer;
begin
  Result := TextPositionToCharIndex(SelectionStartPosition);
end;

function TCustomTextEditor.GetText: string;
begin
  Result := if csDestroying in ComponentState then '' else FLines.Text;
end;

function TCustomTextEditor.GetTextBetween(const ATextBeginPosition: TTextEditorTextPosition; const ATextEndPosition: TTextEditorTextPosition): string;
var
  LSelectionMode: TTextEditorSelectionMode;
begin
  LSelectionMode := FSelection.Mode;

  FSelection.Mode := smNormal;
  FPosition.SelectionStart := ATextBeginPosition;
  FPosition.SelectionEnd := ATextEndPosition;

  Result := SelectedText;

  FSelection.Mode := LSelectionMode;
end;

function TCustomTextEditor.WordWrapWidth: Integer;
begin
  case FWordWrap.Width of
    wwwPage:
      Result := FScrollHelper.PageWidth;
    wwwRightMargin:
      Result := Round(FRightMargin.Position * FPaintHelper.CharWidth);
  else
    Result := 0;
  end;
end;

function TCustomTextEditor.GetTokenCharCount(const AToken: string; const ACharsBefore: Integer): Integer;
var
  LPToken: PChar;
begin
  LPToken := PChar(AToken);

  if LPToken^ = TControlCharacters.Tab then
    Result := if FLines.Columns then FTabs.Width - ACharsBefore mod FTabs.Width else FTabs.Width
  else
    Result := AToken.Length;
end;

function TCustomTextEditor.GetTokenWidth(const AToken: string; const ALength: Integer; const ACharsBefore: Integer; const AMinimap: Boolean = False; const ARTLReading: Boolean = False): Single;

  function GetTokenWidth(const AToken: string; const ATokenLength: Integer = -1): Single;
  var
    LLength: Integer;
  begin
    LLength := if ATokenLength = -1 then ALength else ATokenLength;

    Result := 0;

    if FPaintHelper.StockBitmap.Canvas.BeginScene then
    try
      Result := FMX.TextEditor.Utils.TextWidth(FPaintHelper.StockBitmap.Canvas, Copy(AToken, 1, LLength));
    finally
      FPaintHelper.StockBitmap.Canvas.EndScene;
    end;
  end;

  var
    LChar: Char;
    LToken: string;
    LIsFixedSizeFont: Boolean;
    LCharWidth: Single;

  function GetControlCharacterWidth: Single;
  var
    LLength: Integer;
  begin
    LToken := ControlCharacterToName(LChar);

    LLength := LToken.Length;

    Result := if LIsFixedSizeFont or AMinimap then LCharWidth * LLength else GetTokenWidth(LToken, LLength);
    Result := (Result + 3) * ALength;
  end;

  function IsASCII(const AValue: string): Boolean;
  var
    LPChar: PChar;
  begin
    Result := False;

    LPChar := PChar(AValue);

    while LPChar^ <> TControlCharacters.Null do
    begin
      if Ord(LPChar^) > TCharacters.AnsiCharHigh then
        Exit;

      Inc(LPChar);
    end;

    Result := True;
  end;

begin
  Result := 0;

  if AToken.IsEmpty or (ALength = 0) then
    Exit;

  LChar := AToken[1];
  LCharWidth := FPaintHelper.FontStock.CharWidth;
  LIsFixedSizeFont := FPaintHelper.FixedSizeFont and (Ord(LChar) <= TCharacters.AnsiCharHigh);

  if ARTLReading then
  begin
    Result := if IsASCII(AToken) then LCharWidth * ALength else GetTokenWidth(AToken);
    Exit;
  end;

  case LChar of
    TControlCharacters.NonBreakingSpace:
      if eoShowNonBreakingSpaces in Options then
        Exit(GetControlCharacterWidth);
    TCharacters.Space:
      Exit(LCharWidth * ALength);
    TControlCharacters.Substitute:
      if eoShowNullCharacters in Options then
        Exit(GetControlCharacterWidth);
    TControlCharacters.Tab:
      begin
        Result := if FLines.Columns then FTabs.Width - ACharsBefore mod FTabs.Width else FTabs.Width;
        Exit(Result * LCharWidth + (ALength - 1) * LCharWidth * FTabs.Width);
      end;
    TControlCharacters.ZeroWidthSpace:
      if eoShowZeroWidthSpaces in Options then
        Exit(GetControlCharacterWidth);
  else
    if (eoShowControlCharacters in Options) and (LChar in TControlCharacters.AsSet) then
      Exit(GetControlCharacterWidth);
  end;

  if LIsFixedSizeFont or AMinimap then
    Exit(LCharWidth * ALength);

  if not FPaintHelper.FixedSizeFont then
    Exit(GetTokenWidth(AToken));

  Result := if IsASCII(AToken) then LCharWidth * ALength else GetTokenWidth(AToken);
end;

procedure TCustomTextEditor.CreateLineNumbersCache(const AReset: Boolean = False);
var
  LCacheLength: Integer;
  LLineNumbersCacheLength: Int64;

  procedure ResizeCacheArray;
  begin
    if FWordWrap.Active and (LCacheLength >= LLineNumbersCacheLength) then
    begin
      Inc(LLineNumbersCacheLength, Max(LLineNumbersCacheLength * 2, LLineNumbersCacheLength + 256));

      SetLength(FLineNumbers.Cache, LLineNumbersCacheLength);
      SetLength(FWordWrapLine.Length, LLineNumbersCacheLength);
      SetLength(FWordWrapLine.ViewLength, LLineNumbersCacheLength);
      SetLength(FWordWrapLine.Width, LLineNumbersCacheLength);
    end;
  end;

  var
    LCurrentLine: Integer;

  procedure AddLineNumberIntoCache;
  begin
    FLineNumbers.Cache[LCacheLength] := LCurrentLine;

    Inc(LCacheLength);

    ResizeCacheArray;
  end;

  procedure AddWrappedLineNumberIntoCache;
  var
    LMaxWidth: Integer;
    LTextLine: string;
    LWidth: Single;
    LLength, LViewLength, LCharsBefore: Integer;
    LTokenLength: Integer;
    LTokenWidth: Single;
    LToken, LTokenText, LNextTokenText, LFirstPartOfToken, LSecondPartOfToken: string;
    LHighlighterAttribute: TTextEditorHighlighterAttribute;
    LPToken: PChar;
  begin
    if not Visible or FSimpleMode then
      Exit;

    LMaxWidth := WordWrapWidth;

    if LCurrentLine = 1 then
      FHighlighter.ResetRange
    else
      FHighlighter.SetRange(FLines.Ranges[LCurrentLine - 2]);

    LTextLine := FLines.TextLines[LCurrentLine - 1];

    FHighlighter.SetLine(LTextLine);

    LWidth := 0;
    LLength := 0;
    LViewLength := 0;
    LCharsBefore := 0;

    while not FHighlighter.EndOfLine do
    begin
      if LNextTokenText.IsEmpty then
        FHighlighter.GetToken(LTokenText)
      else
        LTokenText := LNextTokenText;

      LNextTokenText := '';
      LTokenLength := LTokenText.Length;
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

          LToken := LFirstPartOfToken + LSecondPartOfToken;

          LTokenWidth := GetTokenWidth(LToken, LToken.Length, LCharsBefore);

          if LWidth + LTokenWidth < LMaxWidth then
            LFirstPartOfToken := LToken;
        end;

        if (LLength = 0) and LFirstPartOfToken.IsEmpty then
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
        LNextTokenText := Copy(LTokenText, LFirstPartOfToken.Length + 1);

        if LNextTokenText.IsEmpty then
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
      LWidth := LWidth + LTokenWidth;

      FHighlighter.Next;
    end;

    if (LLength > 0) or LTextLine.IsEmpty then
    begin
      FWordWrapLine.Length[LCacheLength] := LLength;
      FWordWrapLine.ViewLength[LCacheLength] := LViewLength;
      FWordWrapLine.Width[LCacheLength] := LWidth;

      AddLineNumberIntoCache;
    end;
  end;

var
  LCollapsedCodeFolding: array of Boolean;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
  LCompareMode: Boolean;
  LCompareOffset: Integer;
begin
  if not Assigned(Parent) or FLines.Streaming or FHighlighter.Loading then
    Exit;

  if FLineNumbers.ResetCache or AReset then
  begin
    FLineNumbers.ResetCache := False;

    if FCodeFolding.Visible then
    begin
      SetLength(LCollapsedCodeFolding, FLines.Count + 1);

      for var LIndex := 0 to FCodeFoldings.AllRanges.AllCount - 1 do
      begin
        LCodeFoldingRange := FCodeFoldings.AllRanges[LIndex];

        if Assigned(LCodeFoldingRange) and LCodeFoldingRange.Collapsed then
        for var LLine := LCodeFoldingRange.FromLine + 1 to LCodeFoldingRange.ToLine do
          LCollapsedCodeFolding[LLine] := True;
      end;
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

    for var LIndex := 1 to FLines.Count do
    begin
      if FCodeFolding.Visible then
      while (LCurrentLine <= FLines.Count) and LCollapsedCodeFolding[LCurrentLine] do { Skip collapsed lines }
        Inc(LCurrentLine);

      if LCurrentLine > FLines.Count then
        Break;

      if FWordWrap.Active then
      begin
        FHighlighter.BreakTokenOnCharsetChange := False;
        AddWrappedLineNumberIntoCache;
        FHighlighter.BreakTokenOnCharsetChange := True;
      end
      else
        AddLineNumberIntoCache;

      Inc(LCurrentLine);

      if LCompareMode then
      begin
        if sfEmptyLine in FLines.Flags[LIndex - 1] then
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

    if FCodeFolding.Visible then
      SetLength(LCollapsedCodeFolding, 0);

    FLineNumbers.Count := Length(FLineNumbers.Cache) - 1;
  end;
end;

procedure TCustomTextEditor.DecCharacterCount(const AText: string);
var
  LPText: PChar;
begin
  LPText := PChar(AText);

  while LPText^ <> TControlCharacters.Null do
  begin
    if LPText^ > TCharacters.Space then
      Dec(FCharacterCount.Value);

    Inc(LPText);
  end;
end;

function TCustomTextEditor.ViewPositionToPixels(const AViewPosition: TTextEditorViewPosition; const ALineText: string = ''): TPointF;
var
  LRow: Integer;
  LPositionY: Integer;
  LLineText: string;
  LCurrentRow: Integer;
  LLength, LCharsBefore: Integer;
  LFontStyles, LPreviousFontStyles: TFontStyles;
  LToken, LNextTokenText: string;
  LHighlighterAttribute: TTextEditorHighlighterAttribute;
  LTokenLength: Integer;

  function MeasureSimpleTextWidth(const AText: string): Single;
  begin
    Result := 0;

    if AText.IsEmpty then
      Exit;

    FPaintHelper.SetStyle([]);

    if FPaintHelper.StockBitmap.Canvas.BeginScene then
    try
      Result := FMX.TextEditor.Utils.TextWidth(FPaintHelper.StockBitmap.Canvas, AText);
    finally
      FPaintHelper.StockBitmap.Canvas.EndScene;
    end;
  end;

begin
  LRow := AViewPosition.Row;
  LPositionY := LRow - FLineNumbers.TopLine;

  Result.Y := LPositionY * GetLineHeight;

  if FWordWrap.Active then
    LRow := GetViewTextLineNumber(LRow);

  LLineText := if ALineText.IsEmpty then FLines.ExpandedStrings[LRow - 1] else ALineText;

  if FSimpleMode then
  begin
    Result.X := FLeftMarginWidth + MeasureSimpleTextWidth(Copy(LLineText, 1, AViewPosition.Column - 1)) - FScrollHelper.HorizontalPosition;
    Exit;
  end;

  if IsRulerVisible then
    Result.Y := Result.Y + FRuler.Height;

  Result.X := 0;

  if LRow = 1 then
    FHighlighter.ResetRange
  else
    FHighlighter.SetRange(FLines.Ranges[LRow - 2]);

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
    if LNextTokenText.IsEmpty then
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

    LTokenLength := LToken.Length;

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
          Result.X := Result.X + GetTokenWidth(LToken, LTokenLength, LCharsBefore, False, True);
          Result.X := Result.X - GetTokenWidth(LToken, AViewPosition.Column - LLength - 1, LCharsBefore, False, True);
        end
        else
          Result.X := Result.X + GetTokenWidth(LToken, AViewPosition.Column - LLength - 1, LCharsBefore);

        Inc(LLength, LTokenLength);

        Break;
      end;

      Result.X := Result.X + GetTokenWidth(LToken, LToken.Length, LCharsBefore);
    end;

    Inc(LLength, LTokenLength);
    Inc(LCharsBefore, GetTokenCharCount(LToken, LCharsBefore));

    FHighlighter.Next;
  end;

  if LLength < AViewPosition.Column then
    Result.X := Result.X + (AViewPosition.Column - LLength - 1) * FPaintHelper.CharWidth;

  if not FWordWrap.Active then
    Result.X := MeasureSimpleTextWidth(Copy(LLineText, 1, AViewPosition.Column - 1));

  Result.X := Result.X + FLeftMarginWidth - FScrollHelper.HorizontalPosition;
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
  Result := AChar in TCharacterSets.WordBreak - FHighlighter.ExcludedWordBreakCharacters;
end;

function TCustomTextEditor.WordAtTextPosition(const ATextPosition: TTextEditorTextPosition; const ASelect: Boolean = False; const AAllowedBreakChars: TSysCharSet = []): string;
var
  LTextPosition: TTextEditorTextPosition;
  LTextLine: string;
  LLength: Integer;
  LChar: Integer;
begin
  Result := '';

  LTextPosition := ATextPosition;
  LTextLine := FLines[LTextPosition.Line];
  LLength := LTextLine.Length;

  if LLength = 0 then
    Exit;

  if (LTextPosition.Char >= 1) and (LTextPosition.Char <= LLength) and not IsWordBreakChar(LTextLine[LTextPosition.Char]) then
  begin
    LChar := LTextPosition.Char;

    while (LChar <= LLength) and (not IsWordBreakChar(LTextLine[LChar]) or (LTextLine[LChar] in AAllowedBreakChars)) do
      Inc(LChar);

    while (LTextPosition.Char > 1) and (not IsWordBreakChar(LTextLine[LTextPosition.Char - 1]) or
      (LTextLine[LTextPosition.Char - 1] in AAllowedBreakChars)) do
      Dec(LTextPosition.Char);

    if soExpandRealNumbers in FSelection.Options then
    while (LTextPosition.Char > 0) and (LTextLine[LTextPosition.Char] in TCharacterSets.RealNumbers) do
      Dec(LTextPosition.Char);

    if soExpandPrefix in FSelection.Options then
    while (LTextPosition.Char > 0) and CharInString(LTextLine[LTextPosition.Char - 1], FSelection.PrefixCharacters) do
      Dec(LTextPosition.Char);

    if LChar > LTextPosition.Char then
      Result := Copy(LTextLine, LTextPosition.Char, LChar - LTextPosition.Char);

    if ASelect then
    begin
      FPosition.SelectionStart := GetPosition(LTextPosition.Char, LTextPosition.Line);
      FPosition.SelectionEnd := GetPosition(LChar, LTextPosition.Line);
    end;
  end;
end;

function TCustomTextEditor.IsCodeFoldingVisible: Boolean;
begin
  Result := not FSimpleMode and FCodeFolding.Visible;
end;

function TCustomTextEditor.GetVisibleChars(const ARow: Integer; const ALineText: string = ''): Integer;
var
  LRect: TRectF;
begin
  LRect := ClientRect;

  DeflateMinimapAndSearchMapRect(LRect);

  Result := PixelAndRowToViewPosition(LRect.Right, ARow, ALineText).Column;

  if FWordWrap.Active and (FWordWrap.Width = wwwRightMargin) then
    Result := FRightMargin.Position;
end;

function TCustomTextEditor.IsCaretOnFirstLine: Boolean;
begin
  Result := TextPosition.Line = 0;
end;

function TCustomTextEditor.IsCaretOnLastLine: Boolean;
begin
  Result := TextPosition.Line = FLines.Count - 1;
end;

function TCustomTextEditor.IsCommentAtCaretPosition: Boolean;
var
  LCommentAtCursor: string;

  function CheckComment(const AComment: string): Boolean;
  var
    LPComment, LPCommentAtCursor: PChar;
  begin
    LPComment := PChar(AComment);
    LPCommentAtCursor := PChar(LCommentAtCursor);

    while (LPComment^ <> TControlCharacters.Null) and (LPCommentAtCursor^ <> TControlCharacters.Null) and (LPCommentAtCursor^ = LPComment^) do
    begin
      Inc(LPComment);
      Inc(LPCommentAtCursor);
    end;

    Result := LPComment^ = TControlCharacters.Null;
  end;

var
  LTextPosition: TTextEditorTextPosition;
  LIndex: Integer;
begin
  Result := False;

  if not IsCodeFoldingVisible or FCodeFolding.TextFolding.Active then
    Exit;

  if (Length(FHighlighter.Comments.BlockComments) = 0) and (Length(FHighlighter.Comments.LineComments) = 0) then
    Exit;

  if FHighlighter.Loaded then
  begin
    LTextPosition := FPosition.Text;

    Dec(LTextPosition.Char);
    GetCommentAtTextPosition(LTextPosition, LCommentAtCursor);

    if not LCommentAtCursor.IsEmpty then
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
  LPLine, LPLineStart: PChar;

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

    if ABeginWithBreakChar and (LPWordAtCursor > LPLineStart) then
      Dec(LPWordAtCursor);

    if AreKeywordsSame(PChar(AKeyword)) then
      Result := True;

    if Result and Assigned(APOpenKeyWord) then
      APOpenKeyWord^ := True;
  end;

var
  LCaretPosition: TTextEditorTextPosition;
  LLineText: string;
  LIndex1, LIndex2: Integer;
  LFoldRegion: TTextEditorCodeFoldingRegion;
  LFoldRegionItem: TTextEditorCodeFoldingRegionItem;
  LLength: Integer;
begin
  Result := False;

  if not IsCodeFoldingVisible or FCodeFolding.TextFolding.Active or (Length(FHighlighter.CodeFoldingRegions) = 0) then
    Exit;

  if FHighlighter.Loaded then
  begin
    LCaretPosition := FPosition.Text;
    LLineText := FLines[LCaretPosition.Line];

    if FMX.TextEditor.Utils.Trim(LLineText).IsEmpty then
      Exit;

    LPLine := PChar(LLineText);
    LPLineStart := LPLine;

    Inc(LPLine, LCaretPosition.Char - 2);

    if FHighlighter.FoldTags then
    while (LCaretPosition.Char > 0) and not (LPLine^ in [TCharacters.TagClose, TCharacters.TagOpen]) do
    begin
      Dec(LPLine);
      Dec(LCaretPosition.Char);
    end
    else
    if not IsWordBreakChar(LPLine^) then
    begin
      while not IsWordBreakChar(LPLine^) and (LCaretPosition.Char > 0) do
      begin
        Dec(LPLine);
        Dec(LCaretPosition.Char);
      end;

      Inc(LPLine);
    end;

    LIndex1 := 0;
    LLength := Length(FHighlighter.CodeFoldingRegions);

    while LIndex1 < LLength do
    begin
      LFoldRegion := FHighlighter.CodeFoldingRegions[LIndex1];

      LIndex2 := 0;

      while LIndex2 < LFoldRegion.Count do
      begin
        LFoldRegionItem := LFoldRegion.Items[LIndex2];

        if CheckToken(LFoldRegionItem.OpenToken, LFoldRegionItem.BeginWithBreakChar) then
          Exit(True);

        if not LFoldRegionItem.OpenTokenCanBeFollowedBy.IsEmpty then
          if CheckToken(LFoldRegionItem.OpenTokenCanBeFollowedBy, LFoldRegionItem.BeginWithBreakChar) then
            Exit(True);

        if CheckToken(LFoldRegionItem.CloseToken, LFoldRegionItem.BeginWithBreakChar) then
          Exit(True);

        Inc(LIndex2);
      end;

      Inc(LIndex1);
    end;
  end;
end;

function TCustomTextEditor.IsKeywordAtCaretPositionOrAfter(const ATextPosition: TTextEditorTextPosition): Boolean;

  function IsWholeWord(const AFirstChar: PChar; const ALastChar: PChar): Boolean; inline;
  begin
    Result := not (AFirstChar^ in TCharacterSets.ValidKeyword) and not (ALastChar^ in TCharacterSets.ValidKeyword);
  end;

var
  LCaretPosition: TTextEditorTextPosition;
  LLineText: string;
  LPLine: PChar;
  LLength: Integer;
  LIndex1, LIndex2: Integer;
  LFoldRegion: TTextEditorCodeFoldingRegion;
  LFoldRegionItem: TTextEditorCodeFoldingRegionItem;
  LPKeyWord, LPBookmarkText, LPText: PChar;
begin
  Result := False;

  if not IsCodeFoldingVisible or FCodeFolding.TextFolding.Active or (Length(FHighlighter.CodeFoldingRegions) = 0) then
    Exit;

  LCaretPosition := ATextPosition;
  LLineText := FLines[LCaretPosition.Line];

  if FMX.TextEditor.Utils.Trim(LLineText).IsEmpty then
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

  if FHighlighter.Loaded then
  begin
    LLength := Length(FHighlighter.CodeFoldingRegions);
    LIndex1 := 0;

    while LIndex1 < LLength do
    begin
      LFoldRegion := FHighlighter.CodeFoldingRegions[LIndex1];
      LIndex2 := 0;

      while LIndex2 < LFoldRegion.Count do
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

        Inc(LIndex2);
      end;

      Inc(LIndex1);
    end;
  end;
end;

function TCustomTextEditor.IsMultiEditCaretFound(const ALine: Integer): Boolean;
var
  LIndex: Integer;
begin
  Result := False;

  if (meoShowActiveLine in FCaret.MultiEdit.Options) and Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) then
  begin
    LIndex := 0;

    while LIndex < FMultiEdit.Carets.Count do
    begin
      if FMultiEdit.Carets[LIndex].ViewPosition.Row = ALine then
        Exit(True);

      Inc(LIndex);
    end;
  end;
end;

function TCustomTextEditor.IsWordSelected: Boolean;
var
  LLineText: string;
  LPText: PChar;
  LIndex: Integer;
begin
  Result := False;

  if FPosition.SelectionStart.Line <> FPosition.SelectionEnd.Line then
    Exit;

  LLineText := FLines[FPosition.SelectionStart.Line];

  if LLineText.IsEmpty then
    Exit;

  LPText := PChar(LLineText);
  LIndex := FPosition.SelectionStart.Char;

  Inc(LPText, LIndex - 1);

  while (LPText^ <> TControlCharacters.Null) and (LIndex < FPosition.SelectionEnd.Char) do
  begin
    if IsWordBreakChar(LPText^) then
      Exit;

    Inc(LPText);
    Inc(LIndex);
  end;

  Result := True;
end;

function TCustomTextEditor.LeftSpaceCount(const ALine: string): Integer;
var
  LPLine: PChar;
begin
  Result := 0;

  if ALine.IsEmpty then
    Exit;

  LPLine := PChar(ALine);

  while (LPLine^ > TControlCharacters.Null) and (LPLine^ <= TCharacters.Space) do
  begin
    if LPLine^ = TControlCharacters.Tab then
      Inc(Result, if FLines.Columns then FTabs.Width - Result mod FTabs.Width else FTabs.Width)
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

  function NextWord(var ATextPosition: TTextEditorTextPosition): Boolean;
  begin
    Inc(ATextPosition.Line);
    ATextPosition.Char := 1;

    LLine := FLines[ATextPosition.Line];

    Result := LLine.IsEmpty or IsWordBreakChar(LLine[ATextPosition.Char]);
  end;

var
  LLength: Integer;
begin
  Result := ATextPosition;

  if (Result.Line >= 0) and (Result.Line < FLines.Count) then
  begin
    LLine := FLines.TextLines[Result.Line];

    LLength := LLine.Length;

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
    Result := GetPosition(1, 0);
end;

function TCustomTextEditor.PixelsToViewPosition(const X, Y: Single): TTextEditorViewPosition;
begin
  Result := PixelAndRowToViewPosition(X, GetSelectedRow(Y));
end;

function TCustomTextEditor.PixelAndRowToViewPosition(const X: Single; const ARow: Integer; const ALineText: string = ''): TTextEditorViewPosition;
var
  LRow, LCurrentRow: Integer;
  LXInEditor: Single;
  LLineText: string;
  LFontStyles, LPreviousFontStyles: TFontStyles;
  LTextWidth: Single;
  LCharsBefore, LLength: Integer;
  LHighlighterAttribute: TTextEditorHighlighterAttribute;
  LToken, LNextTokenText: string;
  LTokenWidth: Single;
  LTokenLength: Integer;
  LPToken: PChar;
  LPreviousCharCount, LCharCount: Integer;
begin
  Result.Row := ARow;
  Result.Column := 1;

  if (FScrollHelper.HorizontalPosition = 0) and (X < FLeftMarginWidth) then
    Exit;

  LRow := ARow;
  LXInEditor := X + FScrollHelper.HorizontalPosition - FLeftMarginWidth + (FPaintHelper.CharWidth / 2) + 1;

  if FSimpleMode then
  begin
    Result.Column := Trunc(LXInEditor / FPaintHelper.CharWidth) + 1;
    Result.Row := ARow;
    Exit;
  end;

  if FWordWrap.Active then
    LRow := GetViewTextLineNumber(LRow);

  LLineText := if ALineText.IsEmpty then FLines.ExpandedStrings[LRow - 1] else ALineText;

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
  LLength := 0;
  LHighlighterAttribute := FHighlighter.TokenAttribute;

  if Assigned(LHighlighterAttribute) then
    LPreviousFontStyles := LHighlighterAttribute.FontStyles;

  FPaintHelper.SetStyle(LPreviousFontStyles);

  while not FHighlighter.EndOfLine do
  begin
    if LNextTokenText.IsEmpty then
      FHighlighter.GetToken(LToken)
    else
      LToken := LNextTokenText;

    LNextTokenText := '';
    LTokenLength := LToken.Length;

    LHighlighterAttribute := FHighlighter.TokenAttribute;

    if Assigned(LHighlighterAttribute) then
      LFontStyles := LHighlighterAttribute.FontStyles;

    if LFontStyles <> LPreviousFontStyles then
    begin
      FPaintHelper.SetStyle(LFontStyles);
      LPreviousFontStyles := LFontStyles;
    end;

    if FWordWrap.Active and (LCurrentRow < ARow) and (LLength + LTokenLength > FWordWrapLine.Length[LCurrentRow]) then
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
    Result.Column := Result.Column + Round((X + FScrollHelper.HorizontalPosition - FLeftMarginWidth - LTextWidth) / FPaintHelper.CharWidth);
end;

function TCustomTextEditor.PixelsToTextPosition(const X, Y: Single): TTextEditorTextPosition;
var
  LViewPosition: TTextEditorViewPosition;
  LWordWrapLineLength: Integer;
begin
  LViewPosition := PixelsToViewPosition(X, Y);

  LViewPosition.Row := EnsureRange(LViewPosition.Row, 1, Max(FLineNumbers.Count, 1));

  if FWordWrap.Active and (Length(FWordWrapLine.ViewLength) > LViewPosition.Row) then
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
  LTextLine: string;
begin
  Result := ATextPosition;

  if (Result.Line >= 0) and (Result.Line < FLines.Count) then
  begin
    LTextLine := FLines.TextLines[Result.Line];

    Result.Char := Min(Result.Char, LTextLine.Length) - 1;

    if Result.Char <= 1 then
    begin
      if Result.Line > 0 then
        Dec(Result.Line)
      else
      if not GetSelectionAvailable then
        Result.Line := FLines.Count - 1;

      Result.Char := FLines.TextLines[Result.Line].Length + 1;
    end
    else
    begin
      while (Result.Char > 0) and IsWordBreakChar(LTextLine[Result.Char]) do
        Dec(Result.Char);

      if (Result.Char = 0) and (Result.Line > 0) then
      begin
        Dec(Result.Line);

        Result.Char := FLines.TextLines[Result.Line].Length;
        Result := PreviousWordPosition(Result);
      end
      else
      begin
        while (Result.Char > 1) and not IsWordBreakChar(LTextLine[Result.Char]) do
          Dec(Result.Char);

        if Result.Char > 1 then
          Inc(Result.Char);
      end;
    end;
  end;
end;

function TCustomTextEditor.ScanHighlighterRangesFrom(const AIndex: Integer): Integer;
var
  LProgress, LProgressInc: Int64;
  LProgressPositionInc: Integer;
  LCancelled: Boolean;
  LRange: TTextEditorRange;
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
  LProgressPositionInc := 1;
  LCancelled := False;

  if FLines.ShowProgress then
  begin
    FLines.ProgressPosition := 0;
    FLines.ProgressType := ptProcessing;

    LProgressInc := Max(FLines.Count div 100, 1);
    LProgressPositionInc := Max(Round(100 / FLines.Count), 1);
  end;

  if FLines.Count > 0 then
  begin
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

      if FLines.ShowProgress and (Result > LProgress) then
      begin
        FLines.ProgressPosition := FLines.ProgressPosition + LProgressPositionInc;

        if Assigned(FEvents.OnLoadingProgress) then
          FEvents.OnLoadingProgress(Self, LCancelled)
        else
          Paint;

        if LCancelled then
          Exit;

        Inc(LProgress, LProgressInc);
      end;
    until Result >= FLines.Count;
  end;

  Dec(Result);
end;

procedure TCustomTextEditor.RescanHighlighterRanges;
var
  LLastScan: Integer;
begin
  if FSimpleMode then
    Exit;

  LLastScan := 0;

  repeat
    LLastScan := ScanHighlighterRangesFrom(LLastScan);

    Inc(LLastScan);
  until LLastScan >= FLines.Count;
end;

function TCustomTextEditor.TextPositionToCharIndex(const ATextPosition: TTextEditorTextPosition): Integer;
var
  LLineCount, LIndex: Integer;
  LItem: TTextEditorStringRecord;
begin
  Result := 0;

  LLineCount := Min(FLines.Count, ATextPosition.Line);
  LIndex := 0;

  while LIndex < LLineCount do
  begin
    LItem := FLines.Items^[LIndex];

    Inc(Result, LItem.TextLine.Length);

    if sfLineBreakCR in LItem.Flags then
      Inc(Result);

    if sfLineBreakLF in LItem.Flags then
      Inc(Result);

    Inc(LIndex);
  end;

  Inc(Result, ATextPosition.Char - 1);
end;

procedure TCustomTextEditor.ActiveLineChanged(ASender: TObject);
begin
  if not (csLoading in ComponentState) then
    if (ASender is TTextEditorActiveLine) or (ASender is TTextEditorGlyph) then
      Repaint;
end;

procedure TCustomTextEditor.AssignSearchEngine(const AEngine: TTextEditorSearchEngine);
begin
  if Assigned(FSearchEngine) and (FSearchEngine.Engine = AEngine) then
    Exit;

  if Assigned(FSearchEngine) then
  begin
    FSearchEngine.Free;
    FSearchEngine := nil;
  end;

  case AEngine of
    seNormal, seExtended:
      FSearchEngine := TTextEditorNormalSearch.Create(AEngine = seExtended);
    seRegularExpression:
      FSearchEngine := TTextEditorRegexSearch.Create;
    seWildCard:
      FSearchEngine := TTextEditorWildCardSearch.Create;
  end;

  FSearchEngine.Engine := AEngine;
end;

procedure TCustomTextEditor.AfterSetText(ASender: TObject);
var
  LTextPosition: TTextEditorTextPosition;

  function NormalizeTextPosition(const APosition: TTextEditorTextPosition): TTextEditorTextPosition;
  begin
    Result := APosition;

    if FLines.Count = 0 then
    begin
      Result := GetBOFPosition;
      Exit;
    end;

    Result.Line := Max(0, Min(Result.Line, FLines.Count - 1));

    if Result.Char < 1 then
      Result.Char := 1;

    Result.Char := Min(Result.Char, FLines[Result.Line].Length + 1);
  end;

  procedure ResetTransientState;
  begin
    FMouse.IsScrolling := False;
    FMouse.DownInText := False;
    FMouse.ScrollTimer.Enabled := False;
    FScrollHelper.Timer.Enabled := False;
    FScrollHelper.Delta.X := 0;
    FScrollHelper.Delta.Y := 0;
    FMinimap.Clicked := False;
    FScroll.Dragging := False;
    MouseCapture := False;
    Exclude(FState.Flags, sfCodeFoldingCollapseMarkClicked);
    Exclude(FState.Flags, sfInSelection);
    Exclude(FState.Flags, sfWaitForDragging);
    Exclude(FState.Flags, sfDragging);
  end;

begin
  FLineNumbers.ResetCache := True;
  CreateLineNumbersCache(True);
  InitCodeFolding;

  ResetTransientState;
  LTextPosition := NormalizeTextPosition(TextPosition);
  TextPosition := LTextPosition;
  FPosition.SelectionStart := LTextPosition;
  FPosition.SelectionEnd := LTextPosition;

  if HandleAllocated then
    EnsureCursorPositionVisible(False, True);

  Repaint;
end;

procedure TCustomTextEditor.BeforeSetText(ASender: TObject);
begin
  ClearCodeFolding;
end;

procedure TCustomTextEditor.BookmarkListChanged(ASender: TObject);
begin
  Repaint;
end;

procedure TCustomTextEditor.BorderStyleChanged(ASender: TObject);
begin
  Repaint;
end;

procedure TCustomTextEditor.BorderChanged(ASender: TObject);
begin
  Repaint;
end;

procedure TCustomTextEditor.CaretChanged(ASender: TObject);
begin
  FreeMultiCarets;
  ResetCaret;
end;

procedure TCustomTextEditor.CheckIfAtMatchingKeywords;
var
  LOpenKeyWord: Boolean;
  LIsKeyWord: Boolean;
  LNewFoldRange: TTextEditorCodeFoldingRange;
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

  FCodeFoldings.AnyCollapsed := True;

  CheckIfAtMatchingKeywords;
  UpdateScrollBars;
  Repaint;
end;

function TCustomTextEditor.IsAnyFoldingCollapsed: Boolean;
var
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  Result := False;

  for var LIndex := 0 to Length(FCodeFoldings.RangeFromLine) - 1 do
  begin
    LCodeFoldingRange := FCodeFoldings.RangeFromLine[LIndex];

    if Assigned(LCodeFoldingRange) and LCodeFoldingRange.Collapsed then
      Exit(True);
  end;
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

  FCodeFoldings.AnyCollapsed := IsAnyFoldingCollapsed;

  CheckIfAtMatchingKeywords;
  UpdateScrollBars;
  Repaint;
end;

procedure TCustomTextEditor.CodeFoldingLinesDeleted(const AFirstLine: Integer; const ACount: Integer);
var
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  if ACount > 0 then
  begin
    for var LIndex := AFirstLine + ACount - 1 downto AFirstLine do
    begin
      LCodeFoldingRange := CodeFoldingRangeForLine(LIndex);

      if Assigned(LCodeFoldingRange) then
        FCodeFoldings.AllRanges.Delete(LCodeFoldingRange);
    end;

    UpdateFoldingRanges(AFirstLine, -ACount);
    LeftMarginChanged(Self);
  end;
end;

procedure TCustomTextEditor.ColorsChanged(ASender: TObject);
begin
  Repaint;
end;

procedure TCustomTextEditor.CodeFoldingResetCaches;
var
  LLength: Integer;
  LShowTreeLine: Boolean;
  LIndex: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  if not IsCodeFoldingVisible then
    Exit;

  FCodeFoldings.Exists := False;

  LLength := FLines.Count + 1;

  SetLength(FCodeFoldings.TreeLine, 0);

  LShowTreeLine := cfoShowTreeLine in FCodeFolding.Options;

  if LShowTreeLine then
    SetLength(FCodeFoldings.TreeLine, LLength);

  SetLength(FCodeFoldings.RangeFromLine, 0);
  SetLength(FCodeFoldings.RangeFromLine, LLength);
  SetLength(FCodeFoldings.RangeToLine, 0);
  SetLength(FCodeFoldings.RangeToLine, LLength);

  LIndex := FCodeFoldings.AllRanges.AllCount - 1;

  while LIndex >= 0 do
  begin
    LCodeFoldingRange := FCodeFoldings.AllRanges[LIndex];

    if Assigned(LCodeFoldingRange) and not LCodeFoldingRange.ParentCollapsed and (LCodeFoldingRange.FromLine <> LCodeFoldingRange.ToLine) and
      (LCodeFoldingRange.FromLine > 0) and (LCodeFoldingRange.FromLine < LLength) then
    begin
      FCodeFoldings.RangeFromLine[LCodeFoldingRange.FromLine] := LCodeFoldingRange;
      FCodeFoldings.Exists := True;

      if LCodeFoldingRange.Collapsable and (LCodeFoldingRange.ToLine > 0) and (LCodeFoldingRange.ToLine < LLength) then
        FCodeFoldings.RangeToLine[LCodeFoldingRange.ToLine] := LCodeFoldingRange;
    end;

    Dec(LIndex);
  end;

  if LShowTreeLine then
  begin
    LIndex := 1;

    while LIndex < LLength do
    begin
      LCodeFoldingRange := FCodeFoldings.RangeFromLine[LIndex];

      Inc(LIndex);

      if Assigned(LCodeFoldingRange) then
      while (LIndex < LLength) and (FCodeFoldings.RangeToLine[LIndex] <> LCodeFoldingRange) do
      begin
        FCodeFoldings.TreeLine[LIndex] := True;
        Inc(LIndex);
      end;
    end;
  end;
end;

procedure TCustomTextEditor.CodeFoldingOnChange(const AEvent: TTextEditorCodeFoldingChanges);
begin
  if AEvent = fcVisible then
  begin
    if IsCodeFoldingVisible then
      InitCodeFolding
    else
      ExpandAll;
  end;

  FLeftMarginWidth := GetLeftMarginWidth;
  FCodeFoldings.DelayTimer.Interval := FCodeFolding.DelayInterval;

  Repaint;
end;

procedure TCustomTextEditor.CompletionProposalTimerHandler(ASender: TObject);
begin
  FCompletionProposalTimer.Enabled := False;

  DoExecuteCompletionProposal(True);
end;

procedure TCustomTextEditor.ComputeScroll(const APoint: TPointF);
var
  LCursorIndex: Integer;
  LScrollBoundsLeft, LScrollBoundsRight: Single;
  LScrollBounds: TRectF;
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
      TMouseWheelScrollCursors.NorthWest, TMouseWheelScrollCursors.West, TMouseWheelScrollCursors.SouthWest:
        FScrollHelper.Delta.X := (APoint.X - FMouse.ScrollingPoint.X) / FPaintHelper.CharWidth - 1;
      TMouseWheelScrollCursors.NorthEast, TMouseWheelScrollCursors.East, TMouseWheelScrollCursors.SouthEast:
        FScrollHelper.Delta.X := (APoint.X - FMouse.ScrollingPoint.X) / FPaintHelper.CharWidth + 1;
    else
      FScrollHelper.Delta.X := 0;
    end;

    case LCursorIndex of
      TMouseWheelScrollCursors.NorthWest, TMouseWheelScrollCursors.North, TMouseWheelScrollCursors.NorthEast:
        FScrollHelper.Delta.Y := (APoint.Y - FMouse.ScrollingPoint.Y) / GetLineHeight - 1;
      TMouseWheelScrollCursors.SouthWest, TMouseWheelScrollCursors.South, TMouseWheelScrollCursors.SouthEast:
        FScrollHelper.Delta.Y := (APoint.Y - FMouse.ScrollingPoint.Y) / GetLineHeight + 1;
    else
      FScrollHelper.Delta.Y := 0;
    end;

    FMouse.ScrollTimer.Enabled := (FScrollHelper.Delta.X <> 0) or (FScrollHelper.Delta.Y <> 0);
  end
  else
  begin
    if not (MouseCapture and Pressed) and not Dragging then
    begin
      FScrollHelper.Delta.X := 0;
      FScrollHelper.Delta.Y := 0;
      FScrollHelper.Timer.Enabled := False;
      Exit;
    end;

    LScrollBoundsLeft := FLeftMarginWidth;
    LScrollBoundsRight := LScrollBoundsLeft + FScrollHelper.PageWidth + 4;
    LScrollBounds := RectF(LScrollBoundsLeft, 0, LScrollBoundsRight, FLineNumbers.VisibleCount * GetLineHeight);

    DeflateMinimapAndSearchMapRect(LScrollBounds);

    if APoint.X < LScrollBounds.Left then
      FScrollHelper.Delta.X := (APoint.X - LScrollBounds.Left) / FPaintHelper.CharWidth - 1
    else
      FScrollHelper.Delta.X := if APoint.X >= LScrollBounds.Right then (APoint.X - LScrollBounds.Right) / FPaintHelper.CharWidth + 1 else 0;

    if APoint.Y < LScrollBounds.Top then
      FScrollHelper.Delta.Y := (APoint.Y - LScrollBounds.Top) / GetLineHeight - 1
    else
      FScrollHelper.Delta.Y := if APoint.Y >= LScrollBounds.Bottom then (APoint.Y - LScrollBounds.Bottom) / GetLineHeight + 1 else 0;

    FScrollHelper.Timer.Enabled := (FScrollHelper.Delta.X <> 0) or (FScrollHelper.Delta.Y <> 0);
  end;
end;

procedure TCustomTextEditor.DeflateMinimapAndSearchMapRect(var ARect: TRectF);
begin
  if FMinimap.Align = maRight then
    ARect.Right := Round(Width) - FMinimap.GetWidth
  else
    ARect.Left := FMinimap.GetWidth;

  if FSearch.Map.Align = saRight then
    ARect.Right := ARect.Right - FSearch.Map.GetWidth
  else
    ARect.Left := ARect.Left + FSearch.Map.GetWidth;
end;

procedure TCustomTextEditor.SetLine(const ALine: Integer; const ALineText: string);
begin
  FLines[ALine] := if eoTrimTrailingSpaces in Options then FMX.TextEditor.Utils.TrimRight(ALineText) else ALineText;
end;

procedure TCustomTextEditor.AddUndoDelete(const ACaretPosition: TTextEditorTextPosition;
  const ASelectionStartPosition, ASelectionEndPosition: TTextEditorTextPosition;
  const AChangeText: string; SelectionMode: TTextEditorSelectionMode; AChangeBlockNumber: Integer = 0);
begin
  DecCharacterCount(AChangeText);

  FUndoList.AddChange(crDelete, ACaretPosition, ASelectionStartPosition, ASelectionEndPosition, AChangeText,
    SelectionMode, AChangeBlockNumber);
end;

procedure TCustomTextEditor.AddUndoInsert(const ACaretPosition: TTextEditorTextPosition;
  const ASelectionStartPosition, ASelectionEndPosition: TTextEditorTextPosition;
  const AChangeText: string; SelectionMode: TTextEditorSelectionMode; AChangeBlockNumber: Integer = 0);
begin
  IncCharacterCount(AChangeText);

  FUndoList.AddChange(crInsert, ACaretPosition, ASelectionStartPosition, ASelectionEndPosition, AChangeText,
    SelectionMode, AChangeBlockNumber);
end;

procedure TCustomTextEditor.AddUndoPaste(const ACaretPosition: TTextEditorTextPosition;
  const ASelectionStartPosition, ASelectionEndPosition: TTextEditorTextPosition;
  const AChangeText: string; SelectionMode: TTextEditorSelectionMode; AChangeBlockNumber: Integer = 0);
begin
  IncCharacterCount(AChangeText);

  FUndoList.AddChange(crPaste, ACaretPosition, ASelectionStartPosition, ASelectionEndPosition, AChangeText,
    SelectionMode, AChangeBlockNumber);
end;

procedure TCustomTextEditor.DeleteChar;
var
  LTextPosition: TTextEditorTextPosition;
  LCharAtCursor: Char;
  LLineText, LOriginalLineText, LHelper, LSpaceBuffer: string;
  LLength, LSpaceCount: Integer;
  LWidth: Single;
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
    LLineText := FLines[LTextPosition.Line];
    LOriginalLineText := LLineText;
    LLength := LLineText.Length;

    if LTextPosition.Char <= LLength then
    begin
      LHelper := Copy(LLineText, LTextPosition.Char, 1);

      Delete(LLineText, LTextPosition.Char, 1);
      SetLine(LTextPosition.Line, LLineText);

      AddUndoDelete(LTextPosition, LTextPosition, GetPosition(LTextPosition.Char + 1, LTextPosition.Line), LHelper, smNormal);

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
      try
        LSpaceCount := LTextPosition.Char - 1 - LLength;
        LSpaceBuffer := StringOfChar(TCharacters.Space, LSpaceCount);

        if LSpaceCount > 0 then
          AddUndoInsert(LTextPosition, GetPosition(LTextPosition.Char - LSpaceCount, LTextPosition.Line),
            GetPosition(LTextPosition.Char, LTextPosition.Line), '', smNormal);

        with LTextPosition do
        begin
          Char := 1;
          Line := Line + 1;
        end;

        AddUndoDelete(LTextPosition, TextPosition, LTextPosition, FLines.GetLineBreak(LTextPosition.Line), smNormal);

        FLines[LTextPosition.Line - 1] := LLineText + LSpaceBuffer + FLines[LTextPosition.Line];
        FLines.LineState[LTextPosition.Line - 1] := lsModified;
        FLines.Delete(LTextPosition.Line);
      finally
        FUndoList.EndBlock;
      end;

      FLineNumbers.ResetCache := True;
    end;

    if FSearch.Enabled and not FSearch.SearchText.IsEmpty and
      ((Pos(FSearch.SearchText, LOriginalLineText) > 0) or (Pos(FSearch.SearchText, LLineText) > 0)) then
      SearchAll;
  end;
end;

procedure TCustomTextEditor.DeleteLine;
var
  LTextPosition: TTextEditorTextPosition;
  LTextLine: string;
  LTextBeginPosition, LTextEndPosition: TTextEditorTextPosition;
begin
  BeginUpdate;
  try
    LTextPosition := TextPosition;

    FUndoList.BeginBlock;
    try
      FUndoList.AddChange(crCaret, LTextPosition, SelectionStartPosition, SelectionEndPosition, '', smNormal);

      LTextLine := FLines[LTextPosition.Line];

      if FLines.Count = 1 then
      begin
        LTextBeginPosition := GetPosition(1, LTextPosition.Line);
        LTextEndPosition := GetPosition(LTextLine.Length + 1, LTextPosition.Line);
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
        LTextEndPosition := GetPosition(LTextLine.Length + 1, LTextPosition.Line);
        LTextLine := FLines.DefaultLineBreak + LTextLine;
      end;

      FLines.Delete(LTextPosition.Line);

      LTextPosition.Line := Min(Max(LTextPosition.Line, 0), FLines.Count - 1);
      LTextPosition.Char := FLines[LTextPosition.Line].Length + 1;

      TextPosition := LTextPosition;

      AddUndoDelete(LTextPosition, LTextBeginPosition, LTextEndPosition, LTextLine, smNormal);

      SetSelectionStartPosition(LTextPosition);
    finally
      FUndoList.EndBlock;
    end;

    if Assigned(FEvents.OnAfterDeleteLine) then
      FEvents.OnAfterDeleteLine(Self);
  finally
    EndUpdate;
  end;
end;

procedure TCustomTextEditor.DeleteText(const ACommand: TTextEditorCommand);

  function DeleteWord(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition;
  var
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

  var
    LTextLine: string;
  begin
    Result := ATextPosition;

    if (Result.Char >= 1) and (Result.Line < FLines.Count) then
    begin
      LTextLine := FLines[Result.Line];

      if Result.Char > LTextLine.Length then
        Exit;

      LPChar := @LTextLine[Result.Char];

      if SelectNextLine(Result) then
        Exit;

      if IsWordBreakChar(LPChar^) then
      begin
        while (LPChar^ <> TControlCharacters.Null) and IsWordBreakChar(LPChar^) do
        begin
          Inc(LPChar);
          Inc(Result.Char);
        end;

        SelectNextLine(Result);
      end
      else
      while (LPChar^ <> TControlCharacters.Null) and not IsWordBreakChar(LPChar^) do
      begin
        Inc(LPChar);
        Inc(Result.Char);
      end;
    end;
  end;

var
  LTextPosition: TTextEditorTextPosition;
  LBeginCaretPosition, LEndCaretPosition: TTextEditorTextPosition;
  LSelectionStartPosition, LSelectionEndPosition: TTextEditorTextPosition;
  LLineText, LHelper: string;
  LIndex: Integer;
begin
  LTextPosition := TextPosition;
  LBeginCaretPosition := LTextPosition;
  LSelectionStartPosition := SelectionStartPosition;
  LSelectionEndPosition := SelectionEndPosition;
  LLineText := FLines[LBeginCaretPosition.Line];

  case ACommand of
    TKeyCommands.DeleteWord:
      begin
        LBeginCaretPosition := LTextPosition;
        LEndCaretPosition := DeleteWord(LTextPosition);
      end;
    TKeyCommands.DeleteWordBackward:
      begin
        LBeginCaretPosition := WordStart(LTextPosition);
        LEndCaretPosition := LTextPosition;
      end;
    TKeyCommands.DeleteWordForward:
      begin
        LBeginCaretPosition := LTextPosition;
        LEndCaretPosition := WordEnd(LTextPosition);
      end;
    TKeyCommands.DeleteWhitespaceBackward:
      begin
        LBeginCaretPosition := LTextPosition;
        LIndex := LBeginCaretPosition.Char - 1;

        while (LIndex > 0) and LLineText[LIndex].IsWhiteSpace do
        begin
          Dec(LBeginCaretPosition.Char);
          Dec(LIndex);
        end;

        LEndCaretPosition := LTextPosition;
      end;
    TKeyCommands.DeleteWhitespaceForward:
      begin
        LBeginCaretPosition := LTextPosition;
        LEndCaretPosition := LTextPosition;
        LIndex := LEndCaretPosition.Char;

        while (LIndex <= LLineText.Length) and LLineText[LIndex].IsWhiteSpace do
        begin
          Inc(LEndCaretPosition.Char);
          Inc(LIndex);
        end;
      end;
    TKeyCommands.DeleteBeginningOfLine:
      begin
        LBeginCaretPosition.Char := 1;
        LEndCaretPosition := LTextPosition;
      end;
  else
    LEndCaretPosition.Char := LLineText.Length + 1;
    LEndCaretPosition.Line := LBeginCaretPosition.Line;
  end;

  if not IsSamePosition(LBeginCaretPosition, LEndCaretPosition) then
  begin
    FUndoList.BeginBlock;
    try
      SetSelectionStartPosition(LBeginCaretPosition);
      SetSelectionEndPosition(LEndCaretPosition);
      FSelection.ActiveMode := smNormal;

      LHelper := SelectedText;

      DoSelectedText('');

      FUndoList.AddChange(crSelection, LTextPosition, LSelectionStartPosition, LSelectionEndPosition, '', smNormal);
      AddUndoDelete(LBeginCaretPosition, LBeginCaretPosition, LEndCaretPosition, LHelper, smNormal);
    finally
      FUndoList.EndBlock;

      SelectionEndPosition := SelectionStartPosition;
    end;
  end;
end;

procedure TCustomTextEditor.DoBackspace;
var
  LTextPosition, LCaretNewPosition: TTextEditorTextPosition;
  LLineText, LOriginalLineText: string;
  LLength: Integer;
  LSpaceCount1, LSpaceCount2: Integer;
  LBackCounterLine: Integer;
  LViewPosition: TTextEditorViewPosition;
  LFoldRange: TTextEditorCodeFoldingRange;
  LVisualSpaceCount1, LVisualSpaceCount2: Integer;
  LText, LSpaceBuffer: string;
  LCharPosition: Integer;
  LChar, LCharAtCursor: Char;
  LWidth: Single;
begin
  BeginUpdate;
  try
    LTextPosition := TextPosition;

    FUndoList.BeginBlock;
    try
      FUndoList.AddChange(crCaret, LTextPosition, SelectionStartPosition, SelectionEndPosition, '', smNormal);

      if GetSelectionAvailable or FMultiEdit.SelectionAvailable then
      begin
        if FSyncEdit.Visible then
        begin
          if LTextPosition.Char < FSyncEdit.EditBeginPosition.Char then
            Exit;

          FSyncEdit.MoveEndPositionChar(-FPosition.SelectionEnd.Char + FPosition.SelectionStart.Char);
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
        LOriginalLineText := LLineText;
        LLength := LLineText.Length;

        if LTextPosition.Char > LLength + 1 then
        begin
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
                LSpaceCount2 := LeftSpaceCount(FLines[LBackCounterLine]);

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
            FLineNumbers.ResetCache := True;
          end;
        end
        else
        if LTextPosition.Char = 1 then
        begin
          if LTextPosition.Line > 0 then
          begin
            LCaretNewPosition.Line := LTextPosition.Line - 1;
            LCaretNewPosition.Char := FLines[LTextPosition.Line - 1].Length + 1;

            AddUndoDelete(LTextPosition, LCaretNewPosition, LTextPosition, FLines.GetLineBreak(LTextPosition.Line), smNormal);

            if eoTrimTrailingSpaces in Options then
              LLineText := FMX.TextEditor.Utils.TrimRight(LLineText);

            FLines[LCaretNewPosition.Line] := FLines[LCaretNewPosition.Line] + LLineText;
            FLines.Delete(LTextPosition.Line);

            LViewPosition := TextToViewPosition(LCaretNewPosition);
            LFoldRange := CodeFoldingFoldRangeForLineTo(LViewPosition.Row);

            if Assigned(LFoldRange) and LFoldRange.Collapsed then
            begin
              LCaretNewPosition.Line := LFoldRange.FromLine - 1;

              Inc(LCaretNewPosition.Char, FLines[LCaretNewPosition.Line].Length + 1);
            end;

            TextPosition := LCaretNewPosition;
            FLineNumbers.ResetCache := True;
          end;
        end
        else
        begin
          LSpaceCount1 := LeftSpaceCount(LLineText);
          LSpaceCount2 := 0;

          if (LLineText[LTextPosition.Char - 1] <= TCharacters.Space) and (LSpaceCount1 = LTextPosition.Char - 1) then
          begin
            LVisualSpaceCount1 := GetLeadingExpandedLength(LLineText);
            LVisualSpaceCount2 := 0;
            LBackCounterLine := LTextPosition.Line - 1;

            while LBackCounterLine >= 0 do
            begin
              LText := FLines.TextLines[LBackCounterLine];
              LVisualSpaceCount2 := GetLeadingExpandedLength(LText);

              if LVisualSpaceCount2 < LVisualSpaceCount1 then
              begin
                LSpaceCount2 := LeftSpaceCount(LText);
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

              LText := Copy(LLineText, LCharPosition + 1, LSpaceCount1 - LCharPosition);

              Delete(LLineText, LCharPosition + 1, LSpaceCount1 - LCharPosition);

              AddUndoDelete(LTextPosition, GetPosition(LCharPosition + 1, LTextPosition.Line), LTextPosition, LText, smNormal);

              LSpaceBuffer := '';

              if LVisualSpaceCount2 - LLength > 0 then
                LSpaceBuffer := StringOfChar(TCharacters.Space, LVisualSpaceCount2 - LLength);

              Insert(LSpaceBuffer, LLineText, LCharPosition + 1);

              FLines[LTextPosition.Line] := LLineText;

              SetTextCaretX(LCharPosition + LSpaceBuffer.Length + 1);
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

              LText := Copy(LLineText, LCharPosition + 1, LSpaceCount1 - LCharPosition);
              Delete(LLineText, LCharPosition + 1, LSpaceCount1 - LCharPosition);

              AddUndoDelete(LTextPosition, GetPosition(LCharPosition + 1, LTextPosition.Line), LTextPosition, LText, smNormal);

              FLines[LTextPosition.Line] := LLineText;

              SetTextCaretX(LCharPosition + 1);
            end;

            FLineNumbers.ResetCache := True;
          end
          else
          begin
            LChar := LLineText[LTextPosition.Char - 1];
            LCharPosition := 1;

            if LChar.IsSurrogate then
              LCharPosition := 2;

            LText := Copy(LLineText, LTextPosition.Char - LCharPosition, LCharPosition);

            AddUndoDelete(LTextPosition, GetPosition(LTextPosition.Char - LCharPosition, LTextPosition.Line), LTextPosition,
              LText, smNormal);

            Delete(LLineText, LTextPosition.Char - LCharPosition, LCharPosition);
            FLines[LTextPosition.Line] := LLineText;

            if FWordWrap.Active then
            begin
              LWidth := GetTokenWidth(LText, 1, 0);

              FWordWrapLine.Length[FViewPosition.Row] := FWordWrapLine.Length[FViewPosition.Row] - 1;
              FWordWrapLine.ViewLength[FViewPosition.Row] := FWordWrapLine.ViewLength[FViewPosition.Row] -
                GetTokenCharCount(LChar, FViewPosition.Row);
              FWordWrapLine.Width[FViewPosition.Row] := FWordWrapLine.Width[FViewPosition.Row] - LWidth;

              LCharAtCursor := GetCharAtTextPosition(GetPosition(LTextPosition.Char, LTextPosition.Line));

              if (LCharAtCursor = TControlCharacters.Tab) or (FWordWrapLine.Length[FViewPosition.Row] <= 0) then
                CreateLineNumbersCache(True);
            end;

            if not (ssShift in FLast.ShiftState) then
            begin
              Dec(LTextPosition.Char, LCharPosition);
              TextPosition := LTextPosition;
            end;
          end;
        end;

        if FSearch.Enabled and not FSearch.SearchText.IsEmpty and
          ((Pos(FSearch.SearchText, LOriginalLineText) > 0) or (Pos(FSearch.SearchText, LLineText) > 0)) then
          SearchAll;
      end;

      if FSyncEdit.Visible then
        DoSyncEdit;
    finally
      FUndoList.EndBlock;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TCustomTextEditor.DoBlockComment;
var
  LLength: Integer;
  LTextPosition: TTextEditorTextPosition;
  LSelectionStartPosition, LSelectionEndPosition: TTextEditorTextPosition;
  LBeginLine, LEndLine: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
  LIndex, LCommentIndex: Integer;
  LLineText, LSpaces: string;
  LSpaceCount: Integer;
  LDeleteComment: Boolean;
  LComment: string;
  LPosition: Integer;
begin
  LLength := Length(FHighlighter.Comments.BlockComments);

  if LLength > 0 then
  begin
    BeginUpdate;
    try
      LTextPosition := TextPosition;
      LSelectionStartPosition := SelectionStartPosition;
      LSelectionEndPosition := SelectionEndPosition;

      if GetSelectionAvailable then
      begin
        LBeginLine := LSelectionStartPosition.Line;
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
      LLineText := FLines.TextLines[LBeginLine];
      LSpaceCount := LeftSpaceCount(LLineText);
      LSpaces := Copy(LLineText, 1, LSpaceCount);

      LLineText := FMX.TextEditor.Utils.TrimLeft(LLineText);

      if not LLineText.IsEmpty then
      while LIndex < LLength - 1 do
      begin
        if Pos(FHighlighter.Comments.BlockComments[LIndex], LLineText) = 1 then
        begin
          LCommentIndex := LIndex;
          Break;
        end;

        Inc(LIndex, 2);
      end;

      FUndoList.BeginBlock;
      try
        FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);

        LDeleteComment := False;

        if LCommentIndex <> -2 then
        begin
          LDeleteComment := True;
          LComment := FHighlighter.Comments.BlockComments[LCommentIndex];

          AddUndoDelete(LTextPosition, GetPosition(LSpaceCount + 1, LBeginLine),
            GetPosition(LSpaceCount + LComment.Length + 1, LBeginLine), LComment, FSelection.ActiveMode);

          LLineText := Copy(LLineText, LComment.Length + 1, LLineText.Length);
        end;

        Inc(LCommentIndex, 2);

        LComment := '';

        if LCommentIndex < LLength - 1 then
          LComment := FHighlighter.Comments.BlockComments[LCommentIndex];

        LLineText := LSpaces + LComment + LLineText;

        FLines.Strings[LBeginLine] := LLineText;

        AddUndoInsert(LTextPosition, GetPosition(1 + LSpaceCount, LBeginLine), GetPosition(1 + LSpaceCount + LComment.Length, LBeginLine), '', FSelection.ActiveMode);

        Inc(LCommentIndex);

        LLineText := FLines.TextLines[LEndLine];
        LSpaceCount := LeftSpaceCount(LLineText);
        LSpaces := Copy(LLineText, 1, LSpaceCount);
        LLineText := FMX.TextEditor.Utils.TrimLeft(LLineText);

        if LDeleteComment and not LLineText.IsEmpty then
        begin
          LComment := FHighlighter.Comments.BlockComments[LCommentIndex - 2];

          LPosition := LLineText.Length - LComment.Length + 1;

          if (LPosition > 0) and (Pos(LComment, LLineText) = LPosition) then
          begin
            AddUndoDelete(LTextPosition, GetPosition(LSpaceCount + LLineText.Length - LComment.Length + 1, LEndLine),
              GetPosition(LSpaceCount + LLineText.Length + 1, LEndLine), LComment, FSelection.ActiveMode);

            LLineText := Copy(LLineText, 1, LLineText.Length - LComment.Length);
          end;
        end;

        LComment := if (LCommentIndex > 0) and (LCommentIndex < LLength) then FHighlighter.Comments.BlockComments[LCommentIndex] else '';

        LLineText := LSpaces + LLineText + LComment;
        FLines.Strings[LEndLine] := LLineText;

        AddUndoInsert(LTextPosition, GetPosition(LLineText.Length - LComment.Length + 1, LEndLine),
          GetPosition(LLineText.Length + LComment.Length + 1, LEndLine), '', FSelection.ActiveMode);
      finally
        FUndoList.EndBlock;
      end;

      TextPosition := LTextPosition;
      FPosition.SelectionStart := LSelectionStartPosition;
      FPosition.SelectionEnd := LSelectionEndPosition;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TCustomTextEditor.DoChar(const AChar: Char);
var
  LTextPosition: TTextEditorTextPosition;

  procedure InitializeCurrentLine;
  begin
    if LTextPosition.Line = 0 then
      FHighlighter.ResetRange
    else
      FHighlighter.SetRange(FLines.Ranges[LTextPosition.Line - 1]);

    FHighlighter.SetLine(FLines[LTextPosition.Line]);
  end;

var
  LCharAtCursor: Char;
  LSelectionAvailable: Boolean;
  LLineText: string;
  LLength, LSpaceCount1: Integer;
  LSpaceBuffer: string;
  LCharCount: Integer;
  LBlockStartPosition: TTextEditorTextPosition;
  LCloseToken: string;
  LMatchingPairToken: TTextEditorMatchingPairToken;
  LTokenCount: Integer;
  LToken, LHelper: string;
  LWidth: Single;
begin
  LTextPosition := TextPosition;

  if (AChar = TCharacters.Space) and AddSnippet(seSpace, LTextPosition) then
    Exit;

  if AChar > TCharacters.Space then
    Inc(FCharacterCount.Value);

  LCharAtCursor := GetCharAtTextPosition(LTextPosition);
  LSelectionAvailable := GetSelectionAvailable or FMultiEdit.SelectionAvailable;

  if LSelectionAvailable then
    BeginUpdate;

  FUndoList.BeginBlock(3);
  try
    if LSelectionAvailable then
    begin
      if FSyncEdit.Visible then
        FSyncEdit.MoveEndPositionChar(-FPosition.SelectionEnd.Char + FPosition.SelectionStart.Char + 1);

      SetSelectedTextEmpty(AChar);
    end
    else
    begin
      if (rmoAutoLineBreak in FRightMargin.Options) and (FViewPosition.Column > FRightMargin.Position) then
      begin
        DoLineBreak;
        LTextPosition.Char := 1;
        Inc(LTextPosition.Line);
      end;

      if FSyncEdit.Visible then
        FSyncEdit.MoveEndPositionChar(1);

      LLineText := FLines[LTextPosition.Line];
      LLength := LLineText.Length;
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

        LSpaceCount1 := LSpaceBuffer.Length;
      end;

      LBlockStartPosition := LTextPosition;

      if FOvertypeMode = omInsert then
      begin
        LCloseToken := '';

        if FMatchingPairs.AutoComplete then
        begin
          for var LIndex := 0 to FHighlighter.MatchingPairs.Count - 1 do
          begin
            LMatchingPairToken := PTextEditorMatchingPairToken(FHighlighter.MatchingPairs[LIndex])^;

            if (LMatchingPairToken.OpenToken = AChar) and (LMatchingPairToken.CloseToken = AChar) then
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
                LCloseToken := LMatchingPairToken.CloseToken;
                Break;
              end;
            end
            else
            if LMatchingPairToken.OpenToken = AChar then
            begin
              LCloseToken := LMatchingPairToken.CloseToken;
              Break;
            end
            else
            if (LMatchingPairToken.OpenToken.Length > 1) and
              (LMatchingPairToken.OpenToken[LMatchingPairToken.OpenToken.Length] = AChar) and
              (WordAtTextPosition(GetPosition(LTextPosition.Char - 1, LTextPosition.Line)) + AChar = LMatchingPairToken.OpenToken) then
            begin
              LCloseToken := LMatchingPairToken.CloseToken;
              Break;
            end;
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
          AddUndoInsert(GetPosition(LLength + 1, LTextPosition.Line), GetPosition(LLength + 1, LTextPosition.Line),
            GetPosition(LLength + LSpaceCount1 + 2  + LCloseToken.Length, LTextPosition.Line), '', smNormal);
          FLines.LineState[LTextPosition.Line] := lsModified;
        end
        else
        begin
          LTextPosition.Char := LTextPosition.Char + 1;
          AddUndoInsert(LBlockStartPosition, LBlockStartPosition,
            GetPosition(LTextPosition.Char + LCloseToken.Length, LTextPosition.Line), '', smNormal);
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

          AddUndoInsert(LTextPosition, GetPosition(LLength + 1, LTextPosition.Line),
            GetPosition(LLength + LSpaceCount1 + 1, LTextPosition.Line), '', smNormal);

          FLines.LineState[LTextPosition.Line] := lsModified;
        end
        else
        begin
          LTextPosition.Char := LTextPosition.Char + 1;

          AddUndoInsert(LTextPosition, LBlockStartPosition, LTextPosition, LHelper, smNormal);

          FLines.LineState[LTextPosition.Line] := lsModified;
        end;
      end;

      if FWordWrap.Active then
      begin
        if FViewPosition.Row < Length(FWordWrapLine.ViewLength) then
        begin
          LWidth := GetTokenWidth(LSpaceBuffer, LSpaceBuffer.Length, 0) + GetTokenWidth(AChar, 1, 0);

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
      end;

      TextPosition := LTextPosition;
    end;
  finally
    FUndoList.EndBlock;

    if LSelectionAvailable then
    begin

      if FSyncEdit.Visible then
        DoSyncEdit;

      EndUpdate;
    end
    else
    begin
      if FSearch.Enabled and not FSearch.SearchText.IsEmpty and (Pos(FSearch.SearchText, LLineText) > 0) then
        SearchAll;

      if FSyncEdit.Visible then
        DoSyncEdit;
    end;
  end;
end;

procedure TCustomTextEditor.DoCutToClipboard;
var
  LText: string;
begin
  if not ReadOnly and (GetSelectionAvailable or FMultiEdit.SelectionAvailable) then
  begin
    AutoCursor;

    BeginUpdate;
    FUndoList.BeginBlock;
    try
      LText := if FMultiEdit.SelectionAvailable then GetMultiCaretSelectedText else SelectedText;

      if FSyncEdit.Visible and GetSelectionAvailable then
        FSyncEdit.MoveEndPositionChar(-FPosition.SelectionEnd.Char + FPosition.SelectionStart.Char);

      DoCopyToClipboard(LText);
      SetSelectedTextEmpty;
    finally
      FUndoList.EndBlock;

      if FSyncEdit.Visible then
        DoSyncEdit;

      EndUpdate;
    end;
  end;
end;

procedure TCustomTextEditor.DoEditorBottom(const ACommand: TTextEditorCommand);
var
  LTextPosition, LCaretNewPosition: TTextEditorTextPosition;
begin
  LTextPosition := TextPosition;

  with LCaretNewPosition do
  begin
    Char := 1;
    Line := FLines.Count - 1;

    if Line > 0 then
      Char := FLines.TextLines[Line].Length + 1;
  end;

  MoveCaretAndSelection(LTextPosition, LCaretNewPosition, ACommand = TKeyCommands.SelectionEditorBottom);
end;

procedure TCustomTextEditor.DoEditorTop(const ACommand: TTextEditorCommand);
var
  LTextPosition, LCaretNewPosition: TTextEditorTextPosition;
begin
  LCaretNewPosition := GetPosition(1, 0);

  MoveCaretAndSelection(LTextPosition, LCaretNewPosition, ACommand = TKeyCommands.SelectionEditorTop);
end;

procedure TCustomTextEditor.DoToggleSelectedCase(const ACommand: TTextEditorCommand);

  procedure AnsiKeywordsCase(const AValue: string; const ACommand: TTextEditorCommand);
  var
    LStringList: TStringList;
    LOldPattern, LNewPattern: string;
    LSearchItem: PTextEditorSearchItem;
  begin
    FReplace.Options := [roReplaceAll, roWholeWordsOnly];
    FReplace.Engine := seNormal;

    FUndoList.BeginBlock(7);

    LStringList := TStringList.Create;
    try
      FHighlighter.GetKeywords(LStringList);

      for var LIndex := LStringList.Count - 1 downto 0 do
      begin
        LOldPattern := LStringList[LIndex];

        case ACommand of
          TKeyCommands.KeywordsUpperCase:
            LNewPattern := AnsiUpperCase(LOldPattern);
          TKeyCommands.KeywordsLowerCase:
            LNewPattern := AnsiLowerCase(LOldPattern);
          TKeyCommands.KeywordsTitleCase:
            LNewPattern := TitleCase(LOldPattern);
        end;

        SearchAll(LOldPattern);

        for var LItemIndex := FSearch.Items.Count - 1 downto 0 do
        begin
          LSearchItem := PTextEditorSearchItem(FSearch.Items.Items[LItemIndex]);

          SelectionStartPosition := LSearchItem.BeginTextPosition;
          SelectionEndPosition := LSearchItem.EndTextPosition;

          ReplaceSelectedText(LNewPattern, LOldPattern);
        end;
      end;
    finally
      LStringList.Free;

      FSearch.ClearItems;
      FUndoList.EndBlock;
    end;
  end;

var
  LOldBlockBeginPosition, LOldBlockEndPosition, LOldCaretPosition: TTextEditorTextPosition;
  LSelectedText: string;
begin
  Assert((ACommand >= TKeyCommands.UpperCase) and (ACommand <= TKeyCommands.KeywordsTitleCase));

  LOldBlockBeginPosition := SelectionStartPosition;
  LOldBlockEndPosition := SelectionEndPosition;
  LOldCaretPosition := TextPosition;
  try
    LSelectedText := SelectedText;

    if not LSelectedText.IsEmpty then
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
        TKeyCommands.KeywordsUpperCase, TKeyCommands.KeywordsLowerCase, TKeyCommands.KeywordsTitleCase:
          AnsiKeywordsCase(LSelectedText, ACommand);
      end;

      if ACommand <= TKeyCommands.TitleCase then
      begin
        FUndoList.BeginBlock;
        try
          SetSelectedTextEmpty(LSelectedText);
        finally
          FUndoList.EndBlock;
        end;
      end;
    end;
  finally
    SelectionStartPosition := LOldBlockBeginPosition;
    SelectionEndPosition := LOldBlockEndPosition;
    TextPosition := LOldCaretPosition;
  end;
end;

procedure TCustomTextEditor.DoEndKey(const ASelection: Boolean);
var
  LTextPosition, LEndOfLineCaretPosition: TTextEditorTextPosition;
  LLineText: string;
  LPLine: PChar;
  LChar: Integer;
begin
  LTextPosition := TextPosition;
  LLineText := FLines[LTextPosition.Line];
  LEndOfLineCaretPosition := GetPosition(LLineText.Length + 1, LTextPosition.Line);
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

procedure TCustomTextEditor.GoToMatchingPair;
begin
  if not FMatchingPairs.Active or FSyncEdit.Visible or FMatchingPairs.Active and (FMatchingPair.Current = trNotFound) then
    Exit;

  TextPosition :=
    if IsSamePosition(FMatchingPair.CurrentMatch.OpenTokenPos, TextPosition) then
      FMatchingPair.CurrentMatch.CloseTokenPos
    else
      FMatchingPair.CurrentMatch.OpenTokenPos;
end;

procedure TCustomTextEditor.GoToNextBookmark;
var
  LTextPosition: TTextEditorTextPosition;
  LMark: TTextEditorMark;
begin
  LTextPosition := TextPosition;

  for var LIndex := 0 to FBookmarkList.Count - 1 do
  begin
    LMark := FBookmarkList.Items[LIndex];

    if (LMark.Line > LTextPosition.Line) or (LMark.Line = LTextPosition.Line) and (LMark.Char > LTextPosition.Char) then
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
  LTextPosition: TTextEditorTextPosition;
  LMark: TTextEditorMark;
begin
  LTextPosition := TextPosition;

  for var LIndex := FBookmarkList.Count - 1 downto 0 do
  begin
    LMark := FBookmarkList.Items[LIndex];

    if (LMark.Line < LTextPosition.Line) or (LMark.Line = LTextPosition.Line) and (LMark.Char < LTextPosition.Char) then
    begin
      GoToBookmark(LMark.Index);
      Exit;
    end;
  end;

  if FBookmarkList.Count > 0 then
  begin
    LMark := TTextEditorMark(FBookmarkList.Items[FBookmarkList.Count - 1]);
    GoToBookmark(LMark.Index);
  end;
end;

procedure TCustomTextEditor.DoHomeKey(const ASelection: Boolean);
var
  LAfterTextPosition, LBeforeTextPosition: TTextEditorTextPosition;
  LViewPosition: TTextEditorViewPosition;
  LLineText: string;
  LChar: Integer;
begin
  LBeforeTextPosition := TextPosition;

  if FWordWrap.Active then
  begin
    LViewPosition := ViewPosition;
    LViewPosition.Column := 1;

    LAfterTextPosition := ViewToTextPosition(LViewPosition);
  end
  else
  begin
    LLineText := FLines[LBeforeTextPosition.Line];

    LChar := 1;

    while (LChar <= LLineText.Length) and LLineText[LChar].IsWhiteSpace do
      Inc(LChar);

    if LBeforeTextPosition.Char <= LChar then
      LChar := 1;

    LAfterTextPosition := GetPosition(LChar, LBeforeTextPosition.Line);
  end;

  MoveCaretAndSelection(LBeforeTextPosition, LAfterTextPosition, ASelection);
end;

procedure TCustomTextEditor.DoImeStr(const AData: Pointer);
var
  LLength: Integer;
  LValue: string;
begin
  LLength := StrLen(PChar(AData));

  SetString(LValue, PChar(AData), LLength);

  InsertText(LValue);
end;

procedure TCustomTextEditor.DoLeftMarginAutoSize;
var
  LWidth: Single;
begin
  if not Assigned(Parent) then
    Exit;

  if FLeftMargin.Autosize then
  begin
    if FLeftMargin.LineNumbers.Visible then
      FLeftMargin.AutosizeDigitCount(FLines.Count);

    FPaintHelper.SetBaseFont(FFonts.LineNumbers);

    LWidth := FLeftMargin.RealLeftMarginWidth(FPaintHelper.CharWidth);

    FLeftMarginCharWidth := FPaintHelper.CharWidth;

    FPaintHelper.SetBaseFont(FFonts.Text);

    if FLeftMargin.Width <> LWidth then
    begin
      FLeftMargin.OnChange := nil;
      FLeftMargin.Width := Round(LWidth);
      FLeftMargin.OnChange := LeftMarginChanged;

      FScrollHelper.PageWidth := GetScrollPageWidth;

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

  function GetSpaceBuffer(const ASpaceCount: Integer): string;
  begin
    Result := '';

    if eoAutoIndent in FOptions then
      Result :=
        if toTabsToSpaces in FTabs.Options then
          StringOfChar(TCharacters.Space, ASpaceCount)
        else
          StringOfChar(TControlCharacters.Tab, ASpaceCount div FTabs.Width) + StringOfChar(TCharacters.Space, ASpaceCount mod FTabs.Width);
  end;

var
  LTextPosition: TTextEditorTextPosition;
  LLineText: string;
  LLength: Integer;
  LSpaceCount1: Integer;
  LSpaceBuffer: string;
begin
  LTextPosition := TextPosition;

  if AddSnippet(seEnter, LTextPosition) then
    Exit;

  FUndoList.BeginBlock(4);
  try
    if GetSelectionAvailable then
    begin
      SetSelectedTextEmpty;
      LTextPosition := TextPosition;
    end;

    FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);

    LLineText := FLines[LTextPosition.Line];
    LLength := LLineText.Length;

    DoTrimTrailingSpaces(LTextPosition.Line);

    if LLength > 0 then
    begin
      with FLines.Items^[LTextPosition.Line] do
      begin
        if FLines.LineBreak in [lbCRLF, lbCR] then
          Include(Flags, sfLineBreakCR);

        if FLines.LineBreak in [lbCRLF, lbLF] then
          Include(Flags, sfLineBreakLF);
      end;

      if LLength >= LTextPosition.Char then
      begin
        if LTextPosition.Char > 1 then
        begin
          { A line break after the first char and before the end of the line. }
          LSpaceCount1 := LeftSpaceCount(LLineText);
          LSpaceBuffer := if AAddSpaceBuffer then GetSpaceBuffer(LSpaceCount1) else '';

          FLines[LTextPosition.Line] := Copy(LLineText, 1, LTextPosition.Char - 1);

          LLineText := Copy(LLineText, LTextPosition.Char, MaxInt);

          AddUndoDelete(LTextPosition, LTextPosition, GetPosition(LTextPosition.Char + LLineText.Length, LTextPosition.Line), LLineText, smNormal);

          if (eoAutoIndent in FOptions) and (LSpaceCount1 > 0) then
            LLineText := LSpaceBuffer + LLineText;

          FLines.Insert(LTextPosition.Line + 1, LLineText);

          FUndoList.AddChange(crLineBreak, GetPosition(1, LTextPosition.Line + 1), LTextPosition, GetPosition(1, LTextPosition.Line + 1), '', smNormal);

          AddUndoInsert(GetPosition(LSpaceBuffer.Length + 1, LTextPosition.Line + 1), GetPosition(1, LTextPosition.Line + 1),
            GetPosition(LLineText.Length + 1, LTextPosition.Line + 1), LLineText, smNormal);

          with FLines do
          begin
            LineState[LTextPosition.Line] := lsModified;
            LineState[LTextPosition.Line + 1] := lsModified;
          end;

          LTextPosition.Char := LSpaceBuffer.Length + 1;
          Inc(LTextPosition.Line);
          FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);
        end
        else
        begin
          { A line break at the first char. }
          FLines.Insert(LTextPosition.Line, '');
          FUndoList.AddChange(crLineBreak, LTextPosition, LTextPosition, LTextPosition, '', smNormal);
          Inc(LTextPosition.Line);
          FLines.LineState[LTextPosition.Line] := lsModified;
        end;
      end
      else
      begin
        { A line break after the end of the line. }
        LSpaceCount1 := if eoAutoIndent in FOptions then LeftSpaceCount(LLineText) else 0;
        LSpaceBuffer := '';

        if AAddSpaceBuffer then
          LSpaceBuffer := GetSpaceBuffer(LSpaceCount1);

        FLines.Insert(LTextPosition.Line + 1, LSpaceBuffer);

        if LTextPosition.Char > LLength + 1 then
          LTextPosition.Char := LLength + 1;

        FUndoList.AddChange(crLineBreak, LTextPosition, LTextPosition, GetPosition(1, LTextPosition.Line + 1), '', smNormal);

        LTextPosition.Char := LSpaceBuffer.Length + 1;
        Inc(LTextPosition.Line);

        AddUndoInsert(GetPosition(LSpaceBuffer.Length + 1, LTextPosition.Line), GetPosition(1, LTextPosition.Line),
          GetPosition(LSpaceBuffer.Length + 1, LTextPosition.Line), LSpaceBuffer, smNormal);

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
      FLines.LineState[LTextPosition.Line] := lsModified;

      LTextPosition.Line := Min(LTextPosition.Line + 1, FLines.Count);
      LTextPosition.Char := 1;

      FUndoList.AddChange(crLineBreak, LTextPosition, LTextPosition, GetPosition(1, LTextPosition.Line), '', smNormal);
      FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);
    end;

    SelectionStartPosition := LTextPosition;
    SelectionEndPosition := LTextPosition;
    TextPosition := LTextPosition;

    EnsureCursorPositionVisible;

    if Assigned(FEvents.OnAfterLineBreak) then
      FEvents.OnAfterLineBreak(Self);
  finally
    UndoList.EndBlock;
  end;
end;

procedure TCustomTextEditor.DoLineComment;
var
  LLength: Integer;
  LTextPosition: TTextEditorTextPosition;
  LSelectionStartPosition, LSelectionEndPosition: TTextEditorTextPosition;
  LStartLine, LEndLine: Integer;
  LIndex2: Integer;
  LCommentIndex: Integer;
  LSpaceCount: Integer;
  LSpaces: string;
  LLineText: string;
  LComment: string;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  LLength := Length(FHighlighter.Comments.LineComments);

  if LLength > 0 then
  begin
    BeginUpdate;
    try
      LTextPosition := TextPosition;
      LSelectionStartPosition := SelectionStartPosition;
      LSelectionEndPosition := SelectionEndPosition;

      if GetSelectionAvailable then
      begin
        LStartLine := LSelectionStartPosition.Line;
        LEndLine := LSelectionEndPosition.Line;
      end
      else
      begin
        LStartLine := LTextPosition.Line;
        LEndLine := LStartLine;
      end;

      FUndoList.BeginBlock;
      try
        for var LIndex1 := LStartLine to LEndLine do
        begin
          LCodeFoldingRange := CodeFoldingRangeForLine(LIndex1 + 1);

          if Assigned(LCodeFoldingRange) and LCodeFoldingRange.Collapsed then
            CodeFoldingExpand(LCodeFoldingRange);

          LIndex2 := 0;
          LCommentIndex := -1;
          LLineText := FLines.TextLines[LIndex1];
          LSpaceCount := LeftSpaceCount(LLineText);
          LSpaces := Copy(LLineText, 1, LSpaceCount);
          LLineText := FMX.TextEditor.Utils.TrimLeft(LLineText);

          if not LLineText.IsEmpty then
          while LIndex2 < LLength do
          begin
            if Pos(FHighlighter.Comments.LineComments[LIndex2], LLineText) = 1 then
            begin
              LCommentIndex := LIndex2;
              Break;
            end;

            Inc(LIndex2);
          end;

          if LCommentIndex <> -1 then
          begin
            LComment := FHighlighter.Comments.LineComments[LCommentIndex];

            AddUndoDelete(LTextPosition, GetPosition(1 + LSpaceCount, LIndex1), GetPosition(LComment.Length + 1 + LSpaceCount, LIndex1), LComment, smNormal);

            LLineText := Copy(LLineText, Length(FHighlighter.Comments.LineComments[LCommentIndex]) + 1, LLineText.Length);
          end;

          Inc(LCommentIndex);
          LComment := '';

          if LCommentIndex < LLength then
            LComment := FHighlighter.Comments.LineComments[LCommentIndex];

          LLineText := LComment + LSpaces + LLineText;

          FLines.Strings[LIndex1] := LLineText;

          AddUndoInsert(LTextPosition, GetPosition(1, LIndex1), GetPosition(LComment.Length + 1, LIndex1), '', smNormal);

          if not GetSelectionAvailable then
          begin
            Inc(LTextPosition.Line);
            TextPosition := LTextPosition;
          end;
        end;
      finally
        FUndoList.EndBlock;
      end;

      FPosition.SelectionStart := LSelectionStartPosition;
      FPosition.SelectionEnd := LSelectionEndPosition;

      if GetSelectionAvailable then
        TextPosition := LTextPosition;
    finally
      EndUpdate;
    end;
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
  LTextPosition, LCaretNewPosition: TTextEditorTextPosition;
  LLineCount: Integer;
begin
  LTextPosition := TextPosition;
  LLineCount := if ACommand in [TKeyCommands.PageBottom, TKeyCommands.SelectionPageBottom] then FLineNumbers.VisibleCount - 1 else 0;
  LCaretNewPosition := ViewToTextPosition(GetViewPosition(FViewPosition.Column, TopLine + LLineCount));

  MoveCaretAndSelection(LTextPosition, LCaretNewPosition, ACommand in [TKeyCommands.SelectionPageTop, TKeyCommands.SelectionPageBottom]);
end;

procedure TCustomTextEditor.DoPageUpOrDown(const ACommand: TTextEditorCommand);
var
  LLineCount: Integer;
begin
  LLineCount := FLineNumbers.VisibleCount shr Ord(soHalfPage in FScroll.Options);

  if ACommand in [TKeyCommands.PageUp, TKeyCommands.SelectionPageUp] then
    LLineCount := -LLineCount;

  TopLine := TopLine + LLineCount;

  MoveCaretVertically(LLineCount, ACommand in [TKeyCommands.SelectionPageUp, TKeyCommands.SelectionPageDown]);
end;

procedure TCustomTextEditor.DoPasteFromClipboard;
begin
  if not ReadOnly then
  begin
    AutoCursor;
    DoInsertText(GetClipboardText);
  end;
end;

procedure TCustomTextEditor.DoInsertText(const AText: string);
var
  LTextPosition: TTextEditorTextPosition;
  LSelectionStartPosition, LSelectionEndPosition: TTextEditorTextPosition;
  LPasteMode: TTextEditorSelectionMode;
begin
  if FMultiEdit.SelectionAvailable then
  begin
    SetSelectedTextEmpty(AText);
    Exit;
  end;

  LTextPosition := TextPosition;
  LSelectionStartPosition := SelectionStartPosition;
  LSelectionEndPosition := SelectionEndPosition;
  LPasteMode := FSelection.Mode;

  BeginUpdate;
  FUndoList.BeginBlock;
  try
    FUndoList.AddChange(crCaret, LTextPosition, LSelectionStartPosition, SelectionEndPosition, '', smNormal);

    if GetSelectionAvailable then
    begin
      AddUndoDelete(LTextPosition, SelectionStartPosition, SelectionEndPosition, GetSelectedText, FSelection.ActiveMode);

      FPosition.SelectionStart := LSelectionStartPosition;
      FPosition.SelectionEnd := LSelectionEndPosition;

      if FSyncEdit.Visible then
        FSyncEdit.MoveEndPositionChar(-FPosition.SelectionEnd.Char + FPosition.SelectionStart.Char + AText.Length);
    end
    else
    begin
      FSelection.ActiveMode := Selection.Mode;

      LSelectionStartPosition := LTextPosition;

      if FSyncEdit.Visible then
        FSyncEdit.MoveEndPositionChar(AText.Length);
    end;

    DoSelectedText(LPasteMode, PChar(AText), True, TextPosition);

    FPosition.SelectionStart := FPosition.SelectionEnd;

    IncCharacterCount(AText);

    AddUndoPaste(LTextPosition, LSelectionStartPosition, TextPosition, '', LPasteMode);
  finally
    FUndoList.EndBlock;

    if FSyncEdit.Visible then
      DoSyncEdit;

    EndUpdate;
  end;
end;

procedure TCustomTextEditor.DoScroll(const ACommand: TTextEditorCommand);
var
  LCaretRow: Integer;
begin
  LCaretRow := FViewPosition.Row;

  if (LCaretRow >= TopLine) and (LCaretRow < TopLine + FLineNumbers.VisibleCount) then
  begin
    if ACommand = TKeyCommands.ScrollUp then
    begin
      TopLine := TopLine - 1;

      if LCaretRow > TopLine + FLineNumbers.VisibleCount - 1 then
        MoveCaretVertically((TopLine + FLineNumbers.VisibleCount - 1) - LCaretRow, False);
    end
    else
    begin
      TopLine := TopLine + 1;

      if LCaretRow < TopLine then
        MoveCaretVertically(TopLine - LCaretRow, False);
    end;
  end;

  EnsureCursorPositionVisible;
end;

procedure TCustomTextEditor.DoSetBookmark(const ACommand: TTextEditorCommand; const AData: Pointer);
var
  LTextPosition: TTextEditorTextPosition;
  LIndex: Integer;
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
  LTextPosition: TTextEditorTextPosition;
  LTabWidth: Integer;
  LNewX: Integer;
  LOldSelectedText: string;
  LTextLine: string;
  LChangeScrollPastEndOfLine: Boolean;
begin
  if (toSelectedBlockIndent in FTabs.Options) and GetSelectionAvailable then
  begin
    DoBlockUnindent;
    Exit;
  end;

  LTextPosition := TextPosition;

  if (toTabsToSpaces in FTabs.Options) and ((LTextPosition.Char - 1) mod FTabs.Width <> 0) then
    Exit;

  LTabWidth := if toTabsToSpaces in FTabs.Options then FTabs.Width else 1;
  LNewX := TextPosition.Char - LTabWidth;

  if LNewX < 1 then
    LNewX := 1;

  if LNewX <> TextPosition.Char then
  begin
    LOldSelectedText := Copy(FLines[LTextPosition.Line], LNewX, LTabWidth);

    if toTabsToSpaces in FTabs.Options then
    begin
      if LOldSelectedText <> StringOfChar(TCharacters.Space, FTabs.Width) then
        Exit;
    end
    else
    if LOldSelectedText <> TControlCharacters.Tab then
      Exit;

    LTextLine := FLines[LTextPosition.Line];

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

    AddUndoDelete(LTextPosition, TextPosition, LTextPosition, LOldSelectedText, smNormal, 2);
  end;
end;

procedure TCustomTextEditor.DoSyncEdit;
var
  LTextPosition: TTextEditorTextPosition;
  LEditText: string;
  LDifference: Integer;
  LIndex2: Integer;
  LOldText: string;
  LTextBeginPosition, LTextEndPosition, LTextSameLinePosition: TTextEditorTextPosition;
  LLine: string;
begin
  LTextPosition := TextPosition;
  LEditText := Copy(FLines[FSyncEdit.EditBeginPosition.Line], FSyncEdit.EditBeginPosition.Char,
    FSyncEdit.EditEndPosition.Char - FSyncEdit.EditBeginPosition.Char);
  LDifference := LEditText.Length - FSyncEdit.EditWidth;

  FLines.BeginUpdate;
  try
    for var LIndex1 := 0 to FSyncEdit.SyncItems.Count - 1 do
    begin
      LTextBeginPosition := PTextEditorTextPosition(FSyncEdit.SyncItems.Items[LIndex1])^;

      if (LTextBeginPosition.Line = FSyncEdit.EditBeginPosition.Line) and (LTextBeginPosition.Char < FSyncEdit.EditBeginPosition.Char) then
      begin
        FSyncEdit.MoveBeginPositionChar(LDifference);
        FSyncEdit.MoveEndPositionChar(LDifference);
        Inc(LTextPosition.Char, LDifference);
      end;

      if (LTextBeginPosition.Line = FSyncEdit.EditBeginPosition.Line) and (LTextBeginPosition.Char > FSyncEdit.EditBeginPosition.Char) then
      begin
        Inc(LTextBeginPosition.Char, LDifference);
        PTextEditorTextPosition(FSyncEdit.SyncItems.Items[LIndex1])^.Char := LTextBeginPosition.Char;
      end;

      LTextEndPosition := LTextBeginPosition;
      Inc(LTextEndPosition.Char, FSyncEdit.EditWidth);
      LOldText := Copy(FLines[LTextBeginPosition.Line], LTextBeginPosition.Char, FSyncEdit.EditWidth);

      AddUndoDelete(LTextPosition, LTextBeginPosition, LTextEndPosition, '', FSelection.ActiveMode);

      LTextEndPosition := LTextBeginPosition;
      Inc(LTextEndPosition.Char, LEditText.Length);

      AddUndoInsert(LTextPosition, LTextBeginPosition, LTextEndPosition, LOldText, FSelection.ActiveMode);

      LLine := FLines[LTextBeginPosition.Line];

      FLines[LTextBeginPosition.Line] := Copy(LLine, 1, LTextBeginPosition.Char - 1) + LEditText + Copy(LLine, LTextBeginPosition.Char + FSyncEdit.EditWidth);

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
  finally
    FLines.EndUpdate;
  end;

  FSyncEdit.EditWidth := FSyncEdit.EditEndPosition.Char - FSyncEdit.EditBeginPosition.Char;
  TextPosition := LTextPosition;
end;

function TCustomTextEditor.GetTabText(var ATextPosition: TTextEditorTextPosition): string;
var
  LViewPosition: TTextEditorViewPosition;
  LLengthAfterLine: Integer;
  LCharCount: Integer;
  LPreviousLine, LPreviousLineCharCount: Integer;
begin
  LViewPosition := ViewPosition;
  LLengthAfterLine := Max(LViewPosition.Column - FLines.ExpandedStringLengths[ATextPosition.Line], 1);
  LCharCount := if LLengthAfterLine > 1 then LLengthAfterLine else FTabs.Width;

  if toPreviousLineIndent in FTabs.Options then
    if FMX.TextEditor.Utils.Trim(FLines[ATextPosition.Line]).IsEmpty then
    begin
      LPreviousLine := ATextPosition.Line - 1;

      while (LPreviousLine >= 0) and FLines.TextLines[LPreviousLine].IsEmpty do
        Dec(LPreviousLine);

      LPreviousLineCharCount := LeftSpaceCount(FLines[LPreviousLine]);

      if LPreviousLineCharCount > ATextPosition.Char then
        LCharCount := LPreviousLineCharCount - LeftSpaceCount(FLines.TextLines[ATextPosition.Line]);
    end;

  if LLengthAfterLine > 1 then
    ATextPosition.Char := FLines[ATextPosition.Line].Length + 1;

  if toTabsToSpaces in FTabs.Options then
  begin
    if FLines.Columns then
      Dec(LCharCount, (LViewPosition.Column - 1) mod FTabs.Width);

    Result := StringOfChar(TCharacters.Space, LCharCount);
  end
  else
    Result := StringOfChar(TControlCharacters.Tab, LCharCount div FTabs.Width) + StringOfChar(TCharacters.Space, LCharCount mod FTabs.Width);
end;

procedure TCustomTextEditor.DoTabKey;
var
  LTextPosition, LNewTextPosition: TTextEditorTextPosition;
  LTextLine, LTabText: string;
  LWidth: Single;
  LLength: Integer;
  LChangeScrollPastEndOfLine: Boolean;
begin
  if GetSelectionAvailable and (FPosition.SelectionStart.Line <> FPosition.SelectionEnd.Line) and (toSelectedBlockIndent in FTabs.Options) then
  begin
    DoBlockIndent;
    Exit;
  end;

  FUndoList.BeginBlock(1);
  try
    LTextPosition := TextPosition;

    if GetSelectionAvailable then
    begin
      AddUndoDelete(LTextPosition, SelectionStartPosition, SelectionEndPosition, GetSelectedText, FSelection.ActiveMode);
      DoSelectedText('');
      LTextPosition := SelectionStartPosition;
    end;

    LTextLine := FLines[LTextPosition.Line];
    LTabText := GetTabText(LTextPosition);

    Insert(LTabText, LTextLine, LTextPosition.Char);
    FLines[LTextPosition.Line] := LTextLine;

    if FWordWrap.Active then
    begin
      if FViewPosition.Row < Length(FWordWrapLine.ViewLength) then
      begin
        LWidth := GetTokenWidth(LTabText, 1, 0);

        if (FWordWrapLine.Width[FViewPosition.Row] + LWidth > FScrollHelper.PageWidth) or (FViewPosition.Column > FWordWrapLine.ViewLength[FViewPosition.Row]) then
          CreateLineNumbersCache(True)
        else
        begin
          LLength := if toTabsToSpaces in Tabs.Options then Tabs.Width else 1;

          FWordWrapLine.Length[FViewPosition.Row] := FWordWrapLine.Length[FViewPosition.Row] + LLength;
          FWordWrapLine.ViewLength[FViewPosition.Row] := FWordWrapLine.ViewLength[FViewPosition.Row] + GetTokenCharCount(LTabText, FViewPosition.Column - 1);
          FWordWrapLine.Width[FViewPosition.Row] := FWordWrapLine.Width[FViewPosition.Row] + LWidth;
        end;
      end;
    end;

    LChangeScrollPastEndOfLine := soPastEndOfLine in FScroll.Options;

    if LChangeScrollPastEndOfLine then
      FScroll.SetOption(soPastEndOfLine, False);

    SetTextCaretX(LTextPosition.Char + LTabText.Length);

    if LChangeScrollPastEndOfLine then
      FScroll.SetOption(soPastEndOfLine, True);

    EnsureCursorPositionVisible;

    if GetSelectionAvailable then
    begin
      LNewTextPosition := SelectionStartPosition;
      Inc(LNewTextPosition.Char);
      SetTextPositionAndSelection(LNewTextPosition, LNewTextPosition, LNewTextPosition);
    end
    else
      LNewTextPosition := TextPosition;

    AddUndoInsert(LTextPosition, LTextPosition, LNewTextPosition, '', FSelection.ActiveMode);
    FUndoList.AddChange(crSelection, LNewTextPosition, LNewTextPosition, LNewTextPosition, '', FSelection.ActiveMode);
  finally
    FUndoList.EndBlock;
  end;
end;

procedure TCustomTextEditor.DoToggleBookmark(const AImageIndex: Integer = -1; const AAutoNumber: Boolean = False);
var
  LTextPosition: TTextEditorTextPosition;
  LMarkIndex: Integer;
  LMark: TTextEditorMark;
begin
  LTextPosition := TextPosition;
  LMarkIndex := 0;

  for var LIndex := 0 to FBookmarkList.Count - 1 do
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

  if (AImageIndex = -1) and (AAutoNumber or FLeftMargin.Bookmarks.AutoNumber) then
  for var LIndex := 0 to 8 do
  if not Assigned(FBookmarkList.Find(LIndex)) then
  begin
    SetBookmark(LIndex, LTextPosition);
    Exit;
  end;

  LMarkIndex := Max(10, LMarkIndex + 1);
  SetBookmark(LMarkIndex, LTextPosition, AImageIndex);
end;

procedure TCustomTextEditor.DoToggleMark;
var
  LTextPosition: TTextEditorTextPosition;
  LMarkIndex: Integer;
  LMark: TTextEditorMark;
begin
  LTextPosition := TextPosition;
  LMarkIndex := 0;

  for var LIndex := 0 to FMarkList.Count - 1 do
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

function TCustomTextEditor.IsTextPositionInSearchBlock(const ATextPosition: TTextEditorTextPosition): Boolean;
var
  LSelectionStartPosition, LSelectionEndPosition: TTextEditorTextPosition;
begin
  Result := False;

  LSelectionStartPosition := FSearch.InSelection.SelectionStartPosition;
  LSelectionEndPosition := FSearch.InSelection.SelectionEndPosition;

  if FSelection.ActiveMode = smNormal then
    Result :=
      ((ATextPosition.Line > LSelectionStartPosition.Line) or
       (ATextPosition.Line = LSelectionStartPosition.Line) and (ATextPosition.Char >= LSelectionStartPosition.Char))
      and
      ((ATextPosition.Line < LSelectionEndPosition.Line) or
       (ATextPosition.Line = LSelectionEndPosition.Line) and (ATextPosition.Char < LSelectionEndPosition.Char))
  else
  if FSelection.ActiveMode = smColumn then
    Result := ((ATextPosition.Line >= LSelectionStartPosition.Line) and (ATextPosition.Char >= LSelectionStartPosition.Char))
      and ((ATextPosition.Line <= LSelectionEndPosition.Line) and (ATextPosition.Char < LSelectionEndPosition.Char));
end;

function TCustomTextEditor.SearchAll(const ASearchText: string = ''): Boolean;
type
  TCommentPositionsRec = record
    BeginTextPosition: TTextEditorTextPosition;
    EndTextPosition: TTextEditorTextPosition;
  end;
var
  LLine: Integer;
  LSelectionStartPosition, LSelectionEndPosition:  TTextEditorTextPosition;
  LSelectedOnly: Boolean;
  LBeginTextPosition, LEndTextPosition: TTextEditorTextPosition;
  LCommentPositions: TList<TCommentPositionsRec>;

  function IsLineInSearch: Boolean;
  begin
    Result := not FSearch.InSelection.Active
      or
      LSelectedOnly and IsTextPositionInSelection(LSelectionStartPosition) and IsTextPositionInSelection(LSelectionEndPosition)
      or
      FSearch.InSelection.Active and
      (FSearch.InSelection.SelectionStartPosition.Line <= LLine) and
      (FSearch.InSelection.SelectionEndPosition.Line >= LLine);
  end;

  procedure GetCommentPositions;
  var
    LInBlockComment: Boolean;
    LText: string;
    LCommentPosition, LBlockCommentPosition: TCommentPositionsRec;
  begin
    if not FHighlighter.Loaded or FSimpleMode then
      Exit;

    LInBlockComment := False;

    for var LLine := 0 to FLines.Count - 1 do
    begin
      if LLine = 0 then
        FHighlighter.ResetRange
      else
        FHighlighter.SetRange(FLines.Ranges[LLine - 1]);

      LText := FLines.TextLines[LLine];

      FHighlighter.SetLine(LText);

      while not FHighlighter.EndOfLine do
      begin
        if FHighlighter.TokenType = ttLineComment then
        begin
          LCommentPosition.BeginTextPosition.Line := LLine;
          LCommentPosition.BeginTextPosition.Char := FHighlighter.TokenPosition + 1;
          LCommentPosition.EndTextPosition.Line := LLine;
          LCommentPosition.EndTextPosition.Char := LText.Length;

          LCommentPositions.Add(LCommentPosition);

          Break;
        end
        else
        if not LInBlockComment and (FHighlighter.TokenType = ttBlockComment) then
        begin
          LBlockCommentPosition.BeginTextPosition.Line := LLine;
          LBlockCommentPosition.BeginTextPosition.Char := FHighlighter.TokenPosition + 1;

          LInBlockComment := True;
        end
        else
        if LInBlockComment and (FHighlighter.TokenType <> ttBlockComment) then
        begin
          LBlockCommentPosition.EndTextPosition.Line := LLine;
          LBlockCommentPosition.EndTextPosition.Char := FHighlighter.TokenPosition + FHighlighter.TokenLength + 1;

          LCommentPositions.Add(LBlockCommentPosition);

          LInBlockComment := False;
        end;

        FHighlighter.Next;
      end;
    end;

    if LInBlockComment then
    begin
      LBlockCommentPosition.EndTextPosition.Line := FLines.Count - 1;
      LBlockCommentPosition.EndTextPosition.Char := FLines.TextLines[FLines.Count - 1].Length;

      LCommentPositions.Add(LBlockCommentPosition);
    end;
  end;

  function IsTextPositionInComment: Boolean;
  var
    LIndex: Integer;
    LCommentPosition: TCommentPositionsRec;
  begin
    Result := False;

    LIndex := 0;

    while LIndex < LCommentPositions.Count do
    begin
      LCommentPosition := LCommentPositions[LIndex];

      Result := ((LBeginTextPosition.Line > LCommentPosition.BeginTextPosition.Line) or
        (LBeginTextPosition.Line = LCommentPosition.BeginTextPosition.Line) and (LBeginTextPosition.Char >= LCommentPosition.BeginTextPosition.Char))
        and
        ((LBeginTextPosition.Line < LCommentPosition.EndTextPosition.Line) or
        (LBeginTextPosition.Line = LCommentPosition.EndTextPosition.Line) and (LBeginTextPosition.Char < LCommentPosition.EndTextPosition.Char));

      if Result then
        Exit;

      Inc(LIndex);
    end;
  end;

  function CanAddResult: Boolean;
  begin
    Result := not FSearch.InSelection.Active
      or
      LSelectedOnly and IsTextPositionInSelection(LSelectionStartPosition) and IsTextPositionInSelection(LSelectionEndPosition)
      or
      FSearch.InSelection.Active and
      ((FSearch.InSelection.SelectionStartPosition.Line < LLine) and (FSearch.InSelection.SelectionEndPosition.Line > LLine) or
      IsTextPositionInSearchBlock(LBeginTextPosition) and IsTextPositionInSearchBlock(LEndTextPosition));

    if soIgnoreComments in FSearch.Options then
      Result := Result and not IsTextPositionInComment;
  end;

var
  LSearchText: string;
  LSearchTextUpper: string;
  LWords: TArray<string>;
  LPosition: Integer;
  LMaxDistance: Integer;
  LResultIndex: Integer;
  LSearchAllCount: Integer;
  LCurrentLineLength: Integer;
  LTextPosition: Integer;
  LPSearchItem: PTextEditorSearchItem;
  LSearchLength: Integer;
begin
  Result := False;

  FSearch.ClearItems;

  if not FSearch.Enabled then
    Exit;

  LSearchText := if ASearchText.IsEmpty then FSearch.SearchText else ASearchText;

  if LSearchText.IsEmpty then
    Exit;

  if FSearch.NearOperator.Enabled then
  begin
    LSearchTextUpper := LSearchText.ToUpperInvariant;

    if (Pos(' NEAR ', LSearchTextUpper) > 0) or (Pos(' NEAR:', LSearchTextUpper) > 0) then
    begin
      LWords := LSearchText.Split([' '], TStringSplitOptions.ExcludeEmpty);

      if Length(LWords) = 3 then
      begin
        LPosition := Pos(':', LWords[1]);
        LMaxDistance :=
          if LPosition > 0 then
            StrToIntDef(Copy(LWords[1], LPosition + 1), FSearch.NearOperator.MaxDistance)
          else
            FSearch.NearOperator.MaxDistance;

        LSearchText := Format('\b(?:%s(?:\W+\w+){%d,%d}?\W+%s|%s(?:\W+\w+){%d,%d}?\W+%s)\b', [LWords[0],
          FSearch.NearOperator.MinDistance, LMaxDistance, LWords[2], LWords[2], FSearch.NearOperator.MinDistance,
          LMaxDistance, LWords[0]]);

        AssignSearchEngine(seRegularExpression);
      end
      else
        AssignSearchEngine(FSearch.Engine);
    end
    else
      AssignSearchEngine(FSearch.Engine);
  end;

  LSelectedOnly := False;

  FSearchEngine.Pattern := LSearchText;

  if ASearchText.IsEmpty then
  begin
    FSearchEngine.CaseSensitive := soCaseSensitive in FSearch.Options;
    FSearchEngine.WholeWordsOnly := soWholeWordsOnly in FSearch.Options;

    FPosition.SelectionStart := FPosition.SelectionEnd;
  end
  else
  begin
    FSearchEngine.CaseSensitive := roCaseSensitive in FReplace.Options;
    FSearchEngine.WholeWordsOnly := roWholeWordsOnly in FReplace.Options;

    LSelectionStartPosition := SelectionStartPosition;
    LSelectionEndPosition := SelectionEndPosition;
    LSelectedOnly := roSelectedOnly in FReplace.Options;
  end;

  LResultIndex := 0;
  LSearchAllCount := FSearchEngine.SearchAll(FLines);

  if LSearchAllCount > 0 then
  begin
    LLine := 0;

    LCurrentLineLength := FLines.TextLines[LLine].Length + FLines.LineBreakLength(LLine);
    LTextPosition := 0;

    LCommentPositions := nil;

    if soIgnoreComments in FSearch.Options then
    begin
      LCommentPositions := TList<TCommentPositionsRec>.Create;
      GetCommentPositions;
    end;

    while (LLine < FLines.Count) and (LResultIndex < LSearchAllCount) do
    begin
      if IsLineInSearch then
      begin
        while (LLine < FLines.Count) and (LResultIndex < LSearchAllCount) and
          (FSearchEngine.Results[LResultIndex] <= LTextPosition + LCurrentLineLength) do
        begin
          LBeginTextPosition.Char := FSearchEngine.Results[LResultIndex] - LTextPosition;
          LBeginTextPosition.Line := LLine;

          LSearchLength := FSearchEngine.Lengths[LResultIndex] + LBeginTextPosition.Char;

          while (LLine < FLines.Count) and (LSearchLength > LCurrentLineLength) do
          begin
            Dec(LSearchLength, LCurrentLineLength);
            Inc(LLine);
            Inc(LTextPosition, LCurrentLineLength);

            LCurrentLineLength := FLines.StringLength(LLine) + FLines.LineBreakLength(LLine);
          end;

          LEndTextPosition.Char := LSearchLength;
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

    if soIgnoreComments in FSearch.Options then
      LCommentPositions.Free;
  end;

  Result := True;
end;

procedure TCustomTextEditor.FindWords(const AWord: string; const AList: TList; const ACaseSensitive: Boolean;
  const AWholeWordsOnly: Boolean);

  function AreCharsSame(const APChar1, APChar2: PChar): Boolean;
  begin
    Result := if ACaseSensitive then APChar1^ = APChar2^ else CaseUpper(APChar1^) = CaseUpper(APChar2^);
  end;

  function IsWholeWord(const AFirstChar, ALastChar: PChar): Boolean;
  begin
    Result := IsWordBreakChar(AFirstChar^) and IsWordBreakChar(ALastChar^);
  end;

var
  LFirstLine, LFirstChar, LLastLine, LLastChar: Integer;
  LLineText: string;
  LPText, LPTextBegin, LPKeyword, LPBookmarkText: PChar;
  LPTextPosition: PTextEditorTextPosition;
begin
  if FSearch.InSelection.Active then
  begin
    LFirstLine := FSearch.InSelection.SelectionStartPosition.Line;
    LFirstChar := FSearch.InSelection.SelectionStartPosition.Char - 1;
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

  for var LLine := LFirstLine to LLastLine do
  begin
    LLineText := FLines.TextLines[LLine];
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
begin
  FMultiEdit.SelectionAvailable := False;

  if Assigned(FMultiEdit.Carets) then
  begin
    FMultiEdit.Timer.Enabled := False;
    FreeAndNil(FMultiEdit.Timer);

    for var LCaret in FMultiEdit.Carets do
      Dispose(LCaret);

    FMultiEdit.Carets.Clear;
    FreeAndNil(FMultiEdit.Carets);
  end;

  UpdateMultiCaretDisplays;
  ResetCaret;
end;

procedure TCustomTextEditor.FontChanged(ASender: TObject);
begin
  Repaint;
end;

procedure TCustomTextEditor.GetMinimapLeftRight(var ALeft: Single; var ARight: Single);
begin
  if FMinimap.Align = maRight then
  begin
    ALeft := ClientWidth - FMinimap.GetWidth;
    ARight := ClientWidth;
  end
  else
  begin
    ALeft := 0;
    ARight := FMinimap.GetWidth;
  end;

  if FSearch.Map.Align = saRight then
  begin
    ALeft := ALeft - FSearch.Map.GetWidth;
    ARight := ARight - FSearch.Map.GetWidth;
  end
  else
  begin
    ALeft := ALeft + FSearch.Map.GetWidth;
    ARight := ARight + FSearch.Map.GetWidth;
  end;
end;

procedure TCustomTextEditor.InitCodeFolding;
begin
  if FLines.Updating then
    Exit;

  ClearCodeFolding;

  if Visible then
    CreateLineNumbersCache(True);

  if IsCodeFoldingVisible then
  begin
    ScanCodeFoldingRanges;
    CodeFoldingResetCaches;
  end;
end;

procedure TCustomTextEditor.IncCharacterCount(const AText: string);
var
  LPText: PChar;
begin
  LPText := PChar(AText);

  while LPText^ <> TControlCharacters.Null do
  begin
    if LPText^ > TCharacters.Space then
      Inc(FCharacterCount.Value);

    Inc(LPText);
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

    LLineText := FLines[LTextPosition.Line];
    LLength := LLineText.Length;

    FLines.Insert(LTextPosition.Line + 1, '');

    AddUndoInsert(LTextPosition, GetPosition(LLength + 1, LTextPosition.Line), GetPosition(1, LTextPosition.Line + 1), '', smNormal);

    FLines.LineState[LTextPosition.Line + 1] := lsModified;
  finally
    FUndoList.EndBlock;

    Repaint;
  end;
end;

procedure TCustomTextEditor.InsertText(const AText: string);
begin
  DoInsertText(AText);
end;

procedure TCustomTextEditor.LinesChanging(ASender: TObject);
begin
  Include(FState.Flags, sfLinesChanging);
end;

procedure TCustomTextEditor.ClearMinimapBuffer;
begin
  if Assigned(FMinimapHelper.BufferBitmap) then
    FMinimapHelper.BufferBitmap.Height := 0;
end;

procedure TCustomTextEditor.MinimapChanged(ASender: TObject);

  procedure Validate;
  begin
    FLeftMarginWidth := GetLeftMarginWidth;
    SizeOrFontChanged;

    Repaint;
  end;

var
  LIndex: Integer;
begin
  if FMinimap.Visible then
  begin
    if not Assigned(FMinimapHelper.BufferBitmap) then
      FMinimapHelper.BufferBitmap := TBitmap.Create;

    ClearMinimapBuffer;

    if (ioUseBlending in FMinimap.Indicator.Options) and not Assigned(FMinimapHelper.Indicator.Bitmap) then
      FMinimapHelper.Indicator.Bitmap := TBitmap.Create;

    if FMinimap.Shadow.Visible then
    begin
      if not Assigned(FMinimapHelper.Shadow.Bitmap) then
        FMinimapHelper.Shadow.Bitmap := TBitmap.Create;

      if FMinimapHelper.Shadow.Bitmap.Canvas.BeginScene then
      try
        FMinimapHelper.Shadow.Bitmap.Canvas.Clear(FMinimap.Shadow.Color);
      finally
        FMinimapHelper.Shadow.Bitmap.Canvas.EndScene;
      end;

      FMinimapHelper.Shadow.Bitmap.Height := 0;
      FMinimapHelper.Shadow.Bitmap.Width := Max(FMinimap.Shadow.Width, 1);

      SetLength(FMinimapHelper.Shadow.AlphaArray, FMinimapHelper.Shadow.Bitmap.Width);

      if FMinimapHelper.Shadow.AlphaByteArrayLength <> FMinimapHelper.Shadow.Bitmap.Width then
      begin
        FMinimapHelper.Shadow.AlphaByteArrayLength := FMinimapHelper.Shadow.Bitmap.Width;
        ReallocMem(FMinimapHelper.Shadow.AlphaByteArray, FMinimapHelper.Shadow.AlphaByteArrayLength * SizeOf(Byte));
      end;

      LIndex := 0;

      while LIndex < FMinimapHelper.Shadow.Bitmap.Width do
      begin
        FMinimapHelper.Shadow.AlphaArray[LIndex] :=
          if FMinimap.Align = maLeft then
            (FMinimapHelper.Shadow.Bitmap.Width - LIndex) / FMinimapHelper.Shadow.Bitmap.Width
          else
            LIndex / FMinimapHelper.Shadow.Bitmap.Width;

        FMinimapHelper.Shadow.AlphaByteArray[LIndex] := Min(Round(Power(FMinimapHelper.Shadow.AlphaArray[LIndex], 4) * 255.0), 255);

        Inc(LIndex);
      end;
    end;

    Validate;
  end
  else
  if FreeMinimapBitmaps then
    Validate;
end;

procedure TCustomTextEditor.MouseScrollTimerHandler(ASender: TObject);
var
  LCursorPoint: TPointF;
begin
  if not FMouse.IsScrolling then
  begin
    FMouse.ScrollTimer.Enabled := False;
    FScrollHelper.Delta.X := 0;
    FScrollHelper.Delta.Y := 0;
    Exit;
  end;

  IncPaintLock;
  try
    LCursorPoint := ScreenToLocal(Screen.MousePos);

    if FScrollHelper.Delta.X <> 0 then
      SetHorizontalScrollPosition(FScrollHelper.HorizontalPosition + FScrollHelper.Delta.X);

    if FScrollHelper.Delta.Y <> 0 then
      TopLine := TopLine + if ssShift in FLast.ShiftState then Round(FScrollHelper.Delta.Y * FLineNumbers.VisibleCount) else Round(FScrollHelper.Delta.Y);

    ComputeScroll(LCursorPoint);
  finally
    DecPaintLock;
  end;
end;

procedure TCustomTextEditor.MoveCaretAndSelection(const ABeforeTextPosition, AAfterTextPosition: TTextEditorTextPosition; const ASelectionCommand: Boolean);
var
  LReason: TTextEditorChangeReason;
  LSelectionAvailable: Boolean;
begin
  IncPaintLock;

  if not (uoGroupUndo in FUndo.Options) and UndoList.CanUndo then
    FUndoList.AddGroupBreak;

  FUndoList.BeginBlock(5);
  try
    LReason := if GetSelectionAvailable then crSelection else crCaret;

    FUndoList.AddChange(LReason, FPosition.Text, SelectionStartPosition, SelectionEndPosition, '', FSelection.ActiveMode);

    LSelectionAvailable := GetSelectionAvailable;

    if ASelectionCommand then
    begin
      if not LSelectionAvailable then
        SetSelectionStartPosition(ABeforeTextPosition);

      SetSelectionEndPosition(AAfterTextPosition);
    end
    else
    begin
      SetSelectionStartPosition(AAfterTextPosition);

      if LSelectionAvailable then
        SetSelectionEndPosition(AAfterTextPosition);
    end;

    TextPosition := AAfterTextPosition;
  finally
    FUndoList.EndBlock;

    DecPaintLock;
  end;
end;

procedure TCustomTextEditor.MoveCaretHorizontally(const X: Integer; const ASelectionCommand: Boolean);
var
  LTextPosition, LDestinationPosition: TTextEditorTextPosition;
  LCurrentLineLength: Integer;
  LChangeY: Boolean;
  LPLine: PChar;
begin
  LTextPosition := TextPosition;

  if not GetSelectionAvailable then
  begin
    FPosition.SelectionStart := LTextPosition;
    FPosition.SelectionEnd := LTextPosition;
  end;

  if not (uoGroupUndo in FUndo.Options) and UndoList.CanUndo then
    FUndoList.AddGroupBreak;

  LDestinationPosition := LTextPosition;
  LCurrentLineLength := FLines[LTextPosition.Line].Length;
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
      LPLine := PChar(FLines.TextLines[LDestinationPosition.Line]);

      Inc(LPLine, LDestinationPosition.Char - 1);

      while (LPLine^ <> TControlCharacters.Null) and (IsCombiningCharacter(LPLine) or
        not (eoShowNullCharacters in Options) and (LPLine^ = TControlCharacters.Substitute) or
        not (eoShowControlCharacters in Options) and (LPLine^ < TCharacters.Space) and (LPLine^ in TControlCharacters.AsSet) or
        not (eoShowZeroWidthSpaces in Options) and (LPLine^ = TControlCharacters.ZeroWidthSpace) or
        not (eoShowNonBreakingSpaces in Options) and (LPLine^ = TControlCharacters.NonBreakingSpace)) do
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

  MoveCaretAndSelection(FPosition.SelectionStart, LDestinationPosition, ASelectionCommand);
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

  if not ASelectionCommand and (LDestinationLineChar.Line <> FPosition.SelectionStart.Line) then
  begin
    DoTrimTrailingSpaces(FPosition.SelectionStart.Line);
    DoTrimTrailingSpaces(LDestinationLineChar.Line);
  end;

  MoveCaretAndSelection(FPosition.SelectionStart, LDestinationLineChar, ASelectionCommand);
end;

procedure TCustomTextEditor.MoveLinesDown;
var
  LTextPosition: TTextEditorTextPosition;
  LSelectionAvailable: Boolean;
  LSelectionStartPosition, LSelectionEndPosition: TTextEditorTextPosition;
begin
  LTextPosition := TextPosition;
  LSelectionAvailable := SelectionAvailable;

  BeginUpdate;
  try
    if LSelectionAvailable then
    begin
      LSelectionStartPosition := SelectionStartPosition;
      LSelectionEndPosition := SelectionEndPosition;

      SelectionStartPosition := GetPosition(1, LSelectionStartPosition.Line);
      SelectionEndPosition := GetPosition(FLines[LSelectionEndPosition.Line + 1].Length + 1, LSelectionEndPosition.Line + 1);
    end
    else
    begin
      LSelectionStartPosition := LTextPosition;
      LSelectionEndPosition := LTextPosition;

      SelectionStartPosition := GetPosition(1, LTextPosition.Line);
      SelectionEndPosition := GetPosition(FLines[LTextPosition.Line + 1].Length + 1, LTextPosition.Line + 1);
    end;

    if LSelectionEndPosition.Line + 1 < FLines.Count  then
    begin
      FUndoList.BeginBlock;
      try
        FUndoList.AddChange(crSelection, LTextPosition, LTextPosition, LTextPosition, '', FSelection.ActiveMode);
        FUndoList.AddChange(crDelete, LTextPosition, SelectionStartPosition, SelectionEndPosition, SelectedText, FSelection.ActiveMode);

        for var LLine := SelectionEndPosition.Line - 1 downto SelectionStartPosition.Line do
          FLines.SwapLines(LLine, LLine + 1);

        SelectionEndPosition := GetPosition(FLines[LSelectionEndPosition.Line + 1].Length + 1, LSelectionEndPosition.Line + 1);

        FUndoList.AddChange(crInsert, LTextPosition, SelectionStartPosition, SelectionEndPosition, '', FSelection.ActiveMode);

        FLines.SetLineStates(SelectionStartPosition.Line, SelectionEndPosition.Line, lsModified);
      finally
        FUndoList.EndBlock;
      end;
    end;
  finally
    EndUpdate;

    if LSelectionAvailable then
    begin
      SelectionStartPosition := GetPosition(1, LSelectionStartPosition.Line + 1);
      SelectionEndPosition := GetPosition(FLines[LSelectionEndPosition.Line + 1].Length + 1, LSelectionEndPosition.Line + 1);
    end
    else
      ClearSelection;

    Inc(LTextPosition.Line);
    TextPosition := LTextPosition;
  end;
end;

procedure TCustomTextEditor.MoveLinesUp;
var
  LTextPosition: TTextEditorTextPosition;
  LSelectionAvailable: Boolean;
  LSelectionStartPosition, LSelectionEndPosition: TTextEditorTextPosition;
begin
  LTextPosition := TextPosition;
  LSelectionAvailable := SelectionAvailable;

  BeginUpdate;
  try
    if LSelectionAvailable then
    begin
      LSelectionStartPosition := SelectionStartPosition;
      LSelectionEndPosition := SelectionEndPosition;
      SelectionStartPosition := GetPosition(1, LSelectionStartPosition.Line - 1);
      SelectionEndPosition := GetPosition(FLines[LSelectionEndPosition.Line].Length + 1, LSelectionEndPosition.Line);
    end
    else
    begin
      LSelectionStartPosition := LTextPosition;
      LSelectionEndPosition := LTextPosition;
      SelectionStartPosition := GetPosition(1, LTextPosition.Line - 1);
      SelectionEndPosition := GetPosition(FLines[LTextPosition.Line].Length + 1, LTextPosition.Line);
    end;

    if LSelectionStartPosition.Line - 1 >= 0 then
    begin
      FUndoList.BeginBlock;
      try
        FUndoList.AddChange(crSelection, LTextPosition, LTextPosition, LTextPosition, '', FSelection.ActiveMode);
        FUndoList.AddChange(crDelete, LTextPosition, SelectionStartPosition, SelectionEndPosition, SelectedText, FSelection.ActiveMode);

        for var LLine := SelectionStartPosition.Line to SelectionEndPosition.Line - 1 do
          FLines.SwapLines(LLine, LLine + 1);

        SelectionEndPosition := GetPosition(FLines[LSelectionEndPosition.Line].Length + 1, LSelectionEndPosition.Line);

        FUndoList.AddChange(crInsert, LTextPosition, SelectionStartPosition, SelectionEndPosition, '', FSelection.ActiveMode);

        FLines.SetLineStates(SelectionStartPosition.Line, SelectionEndPosition.Line, lsModified);
      finally
        FUndoList.EndBlock;
      end;
    end;
  finally
    EndUpdate;

    if LSelectionAvailable then
    begin
      SelectionStartPosition := GetPosition(1, LSelectionStartPosition.Line - 1);
      SelectionEndPosition := GetPosition(FLines[LSelectionEndPosition.Line - 1].Length + 1, LSelectionEndPosition.Line - 1);
    end
    else
      ClearSelection;

    Dec(LTextPosition.Line);
    TextPosition := LTextPosition;
  end;
end;

procedure TCustomTextEditor.MultiCaretTimerHandler(ASender: TObject);
var
  LIndex: Integer;
begin
  FMultiEdit.Draw := not FMultiEdit.Draw;

  if Assigned(FMultiCaretDisplays) then
  for LIndex := 0 to FMultiCaretDisplays.Count - 1 do
    FMultiCaretDisplays[LIndex].Opacity := if FMultiEdit.Draw then 1 else 0;
end;

procedure TCustomTextEditor.OnCodeFoldingDelayTimer(ASender: TObject);
begin
  FCodeFoldings.DelayTimer.Enabled := False;

  if FCodeFoldings.Rescan then
    RescanCodeFoldingRanges;
end;

procedure TCustomTextEditor.ValidateMultiCarets;
var
  LPMultiCaretRecord1, LPMultiCaretRecord2: PTextEditorMultiCaretRecord;
begin
  if Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) then
  begin
    { Remove duplicate multi carets }
    for var LIndex1 := 0 to FMultiEdit.Carets.Count - 1 do
      for var LIndex2 := FMultiEdit.Carets.Count - 1 downto LIndex1 + 1 do
      begin
        LPMultiCaretRecord1 := FMultiEdit.Carets[LIndex1];
        LPMultiCaretRecord2 := FMultiEdit.Carets[LIndex2];

        if (LPMultiCaretRecord1^.ViewPosition.Row = LPMultiCaretRecord2^.ViewPosition.Row) and
          (LPMultiCaretRecord1^.ViewPosition.Column = LPMultiCaretRecord2^.ViewPosition.Column) then
        begin
          Dispose(LPMultiCaretRecord2);
          FMultiEdit.Carets.Delete(LIndex2);
        end;
      end;

    { Remove carets after line count }
    for var LIndex1 := FMultiEdit.Carets.Count - 1 downto 0 do
    begin
      LPMultiCaretRecord1 := FMultiEdit.Carets[LIndex1];

      if LPMultiCaretRecord1^.ViewPosition.Row > FLineNumbers.Count then
      begin
        Dispose(LPMultiCaretRecord1);
        FMultiEdit.Carets.Delete(LIndex1);
      end;
    end;

    if FMultiEdit.Carets.Count <= 1 then
      FreeMultiCarets;
  end;
end;

procedure TCustomTextEditor.ReplaceChanged(const AEvent: TTextEditorReplaceChanges);
begin
  if AEvent = rcEngineUpdate then
    AssignSearchEngine(FReplace.Engine);
end;

procedure TCustomTextEditor.RestoreCollapsedBackup;
var
  LLength: Integer;
  LLineNumber: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  if not IsCodeFoldingVisible or not FCodeFoldings.AnyCollapsed then
    Exit;

  if Assigned(FCodeFoldings.CollapsedBackup) then
  begin
    LLength := Length(FCodeFoldings.RangeFromLine);

    for var LIndex := 0 to FCodeFoldings.CollapsedBackup.Count - 1 do
    begin
      LLineNumber := FCodeFoldings.CollapsedBackup[LIndex];

      if LLineNumber < LLength then
      begin
        LCodeFoldingRange := FCodeFoldings.RangeFromLine[LLineNumber];

        if Assigned(LCodeFoldingRange) then
          CodeFoldingCollapse(LCodeFoldingRange);
      end;
    end;

    FCodeFoldings.CollapsedBackup.Free;
    FCodeFoldings.CollapsedBackup := nil;
  end;
end;

procedure TCustomTextEditor.RightMarginChanged(ASender: TObject);
begin
  if FWordWrap.Active and (FWordWrap.Width = wwwRightMargin) then
    FLineNumbers.ResetCache := True;

  if not (csLoading in ComponentState) then
    Repaint;
end;

procedure TCustomTextEditor.RulerChanged(ASender: TObject);
begin
  if not (csLoading in ComponentState) and FFile.Loaded then
    SizeOrFontChanged(False);

  if not (csLoading in ComponentState) then
    Repaint;
end;

procedure TCustomTextEditor.ScanCodeFoldingRanges;
const
  DEFAULT_CODE_FOLDING_RANGE_INDEX = 0;

  function IsWholeWord(const AFirstChar, ALastChar: PChar): Boolean; inline;
  begin
    Result := not (AFirstChar^ in TCharacterSets.ValidFoldingWord) and not (ALastChar^ in TCharacterSets.ValidFoldingWord);
  end;

  function CountCharsBefore(const APText: PChar; const ACharacter: Char): Integer;
  var
    LPText: PChar;
  begin
    Result := 0;

    LPText := APText - 1;

    while LPText^ = ACharacter do
    begin
      Inc(Result);
      Dec(LPText);
    end;
  end;

  var
    LCurrentCodeFoldingRegion: TTextEditorCodeFoldingRegion;

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

  function IsNextSkipChar(const APText: PChar; const ASkipRegionItem: TTextEditorSkipRegionItem): Boolean; inline;
  begin
    Result := False;

    if ASkipRegionItem.SkipIfNextCharIsNot <> TControlCharacters.Null then
      Result := APText^ = ASkipRegionItem.SkipIfNextCharIsNot;
  end;

  var
    LPText, LPKeyWord, LPBookmarkText: PChar;
    LOpenTokenSkipFoldRangeList: TList;

  function SkipRegionsClose: Boolean;
  var
    LSkipRegionItem: TTextEditorSkipRegionItem;
  begin
    Result := False;

    { Note! Check Close before Open because close and open keys might be same. }
    if (LOpenTokenSkipFoldRangeList.Count > 0) and (LPText^ in FHighlighter.SkipCloseKeyChars) and not OddCountOfStringEscapeChars(LPText) then
    begin
      LSkipRegionItem := LOpenTokenSkipFoldRangeList.Last;

      LPKeyWord := PChar(LSkipRegionItem.CloseToken);
      LPBookmarkText := LPText;

      { Check if the close keyword found }
      while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and
        ((LPText^ = LPKeyWord^) or (LSkipRegionItem.SkipEmptyChars and (LPText^ < TCharacters.ExclamationMark))) do
      begin
        if not (LPText^ in [TCharacters.Space, TControlCharacters.Tab, TControlCharacters.Substitute]) then
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
    LIndex: Integer;
    LSkipRegionItem: TTextEditorSkipRegionItem;
  begin
    Result := False;

    if (LPText^ in FHighlighter.SkipOpenKeyChars) and (LOpenTokenSkipFoldRangeList.Count = 0) then
    begin
      LIndex := 0;

      while LIndex < LCurrentCodeFoldingRegion.SkipRegions.Count do
      begin
        LSkipRegionItem := LCurrentCodeFoldingRegion.SkipRegions[LIndex];

        if (LPText^ = PChar(LSkipRegionItem.OpenToken)^) and not OddCountOfStringEscapeChars(LPText) and
          not IsNextSkipChar(LPText + LSkipRegionItem.OpenToken.Length, LSkipRegionItem) then
        begin
          LPKeyWord := PChar(LSkipRegionItem.OpenToken);
          LPBookmarkText := LPText;

          { Check, if the open keyword found }
          while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and
            ((LPText^ = LPKeyWord^) or (LSkipRegionItem.SkipEmptyChars and (LPText^ < TCharacters.ExclamationMark))) do
          begin
            if not LSkipRegionItem.SkipEmptyChars or
              (LSkipRegionItem.SkipEmptyChars and not (LPText^ in [TCharacters.Space, TControlCharacters.Tab, TControlCharacters.Substitute])) then
              Inc(LPKeyWord);

            Inc(LPText);
          end;

          if LPKeyWord^ = TControlCharacters.Null then { If found, skip single line comment or push skip region into stack }
          begin
            if LSkipRegionItem.RegionType = ritSingleLineString then
            begin
              LPKeyWord := PChar(LSkipRegionItem.CloseToken);

              while (LPText^ <> TControlCharacters.Null) and
                ((LPText^ <> LPKeyWord^) or (LPText^ = LPKeyWord^) and OddCountOfStringEscapeChars(LPText)) do
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

        Inc(LIndex);
      end;
    end;
  end;

  var
    LLine, LFoldCount: Integer;
    LBeginningOfLine: Boolean;
    LOpenTokenFoldRangeList: TList;

  procedure RegionItemsClose;

    procedure SetCodeFoldingRangeToLine(const ACodeFoldingRange: TTextEditorCodeFoldingRange);
    var
      LIndex: Integer;
    begin
      if ACodeFoldingRange.RegionItem.TokenEndIsPreviousLine then
      begin
        LIndex := LLine - 1;

        while (LIndex > 0) and FLines[LIndex - 1].IsEmpty do
          Dec(LIndex);

        ACodeFoldingRange.ToLine := LIndex
      end
      else
        ACodeFoldingRange.ToLine := LLine;
    end;

  var
    LIndexDecrease: Integer;
    LIndex: Integer;
    LCodeFoldingRange, LCodeFoldingRangeLast: TTextEditorCodeFoldingRange;

    function CheckCloseRegion(const ACloseToken: string): Boolean;
    begin
      Result := False;

      LPKeyWord := PChar(ACloseToken);
      LPBookmarkText := LPText;

      { Check if the close keyword found }
      while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and (CaseUpper(LPText^) = LPKeyWord^) do
      begin
        Inc(LPText);
        Inc(LPKeyWord);
      end;

      if LPKeyWord^ = TControlCharacters.Null then { If found, pop skip region from the stack }
      begin
        if not LCodeFoldingRange.RegionItem.BreakCharFollows or
          LCodeFoldingRange.RegionItem.BreakCharFollows and IsWholeWord(LPBookmarkText - 1, LPText) then
        begin
          LOpenTokenFoldRangeList.RemoveItem(LCodeFoldingRange, TList.TDirection.FromEnd);

          Dec(LFoldCount);

          if not LCodeFoldingRange.IsExtraTokenFound and not LCodeFoldingRange.RegionItem.BreakIfNotFoundBeforeNextRegion.IsEmpty then
          begin
            LPText := LPBookmarkText;
            Result := True;
          end;

          SetCodeFoldingRangeToLine(LCodeFoldingRange);

          { Check if the code folding ranges have shared close }
          if FHighlighter.IsSharedCloseFound and (LOpenTokenFoldRangeList.Count > 0) then
          for var LItemIndex := LOpenTokenFoldRangeList.Count - 1 downto 0 do
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
                LOpenTokenFoldRangeList.RemoveItem(LCodeFoldingRangeLast, TList.TDirection.FromEnd);
                Dec(LFoldCount);
              end;
            end;
          end;

          if LCodeFoldingRange.RegionItem.SharedClose or LCodeFoldingRange.RegionItem.OpenIsClose then
            LPText := LPBookmarkText; { Go back where we were }
        end
        else
          LPText := LPBookmarkText; { Region close not found, return pointer back }
      end
      else
        LPText := LPBookmarkText; { Region close not found, return pointer back }
    end;

  begin
    if (LOpenTokenSkipFoldRangeList.Count <> 0) or (LOpenTokenFoldRangeList.Count <= 0) then
      Exit;

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

        if CheckCloseRegion(LCodeFoldingRange.RegionItem.CloseToken) then
          Exit;

        if (LPText = LPBookmarkText) and not LCodeFoldingRange.RegionItem.AlternativeCloseToken.IsEmpty then
          if CheckCloseRegion(LCodeFoldingRange.RegionItem.AlternativeCloseToken) then
            Exit;

        Inc(LIndexDecrease);
      until Assigned(LCodeFoldingRange) and (LCodeFoldingRange.RegionItem.BreakIfNotFoundBeforeNextRegion.IsEmpty or
        (LOpenTokenFoldRangeList.Count - LIndexDecrease < 0));
    end;
  end;

  function RegionItemsOpen: Boolean;
  var
    LCodeFoldingRange: TTextEditorCodeFoldingRange;
    LRegionItem: TTextEditorCodeFoldingRegionItem;
    LPTempText, LPTempKeyWord: PChar;
    LTemp: string;
    LLength, LPosition: Integer;
    LSkipIfFoundAfterOpenToken: Boolean;
    LPBookmarkText2: PChar;
    LFoldRanges: TTextEditorCodeFoldingRanges;
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

      for var LIndex := 0 to LCurrentCodeFoldingRegion.Count - 1 do
      begin
        LRegionItem := LCurrentCodeFoldingRegion[LIndex];

        if LRegionItem.SingleInstance and LRegionItem.Processed then
          Continue;

        if (LRegionItem.OpenTokenBeginningOfLine and LBeginningOfLine) or not LRegionItem.OpenTokenBeginningOfLine then
        begin
          { Check if extra token found }
          if Assigned(LCodeFoldingRange) then
          begin
            if not LCodeFoldingRange.RegionItem.BreakIfNotFoundBeforeNextRegion.IsEmpty then
              if LPText^ = PChar(LCodeFoldingRange.RegionItem.BreakIfNotFoundBeforeNextRegion)^ then { If first character match }
              begin
                LPKeyWord := PChar(LCodeFoldingRange.RegionItem.BreakIfNotFoundBeforeNextRegion);
                LPBookmarkText := LPText;

                { Check if open keyword found }
                while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and
                  ((CaseUpper(LPText^) = LPKeyWord^) or (LPText^ in [TCharacters.Space,  TControlCharacters.Tab, TControlCharacters.Substitute])) do
                begin
                  if (LPKeyWord^ in [TCharacters.Space, TControlCharacters.Tab, TControlCharacters.Substitute]) or
                    not (LPText^ in [TCharacters.Space, TControlCharacters.Tab, TControlCharacters.Substitute]) then
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
            while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and (CaseUpper(LPText^) = LPKeyWord^) do
            begin
              Inc(LPText);
              Inc(LPKeyWord);
            end;

            if not LRegionItem.OpenTokenCanBeFollowedBy.IsEmpty then
              if CaseUpper(LPText^) = PChar(LRegionItem.OpenTokenCanBeFollowedBy)^ then
              begin
                LPTempText := LPText;
                LPTempKeyWord := PChar(LRegionItem.OpenTokenCanBeFollowedBy);

                while (LPTempText^ <> TControlCharacters.Null) and (LPTempKeyWord^ <> TControlCharacters.Null) and (CaseUpper(LPTempText^) = LPTempKeyWord^) do
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

                if FHighlighter.FoldTags then
                begin
                  LPTempText := LPText;

                  while LPTempText^ <> TControlCharacters.Null do
                  begin
                    if LPTempText^ = TCharacters.TagClose then
                      Break
                    else
                    if (LPTempText^ = TCharacters.Slash) and ((LPTempText + 1)^ = TCharacters.TagClose) then
                    begin
                      LSkipIfFoundAfterOpenToken := True;
                      Break;
                    end;

                    Inc(LPTempText);
                  end;
                end;

                if LSkipIfFoundAfterOpenToken then
                begin
                  LPText := LPBookmarkText; { Skip found, return pointer back }
                  Continue;
                end;

                if LRegionItem.SkipIfFoundAfterOpenTokenArrayCount > 0 then
                begin
                  LPBookmarkText := LPText;

                  while (LPText^ <> TControlCharacters.Null) and not LSkipIfFoundAfterOpenToken do
                  begin
                    if not LPText^.IsWhiteSpace then
                    for var LArrayIndex := 0 to LRegionItem.SkipIfFoundAfterOpenTokenArrayCount - 1 do
                    begin
                      LPKeyWord := PChar(LRegionItem.SkipIfFoundAfterOpenTokenArray[LArrayIndex]);

                      LPBookmarkText2 := LPText;

                      if CaseUpper(LPText^) = LPKeyWord^ then { If first character match }
                      begin
                        while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and (CaseUpper(LPText^) = LPKeyWord^) do
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

                    Inc(LPText);
                  end;

                  if LSkipIfFoundAfterOpenToken then
                    Continue
                  else
                    LPText := LPBookmarkText;
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
                  LTemp := FMX.TextEditor.Utils.Trim(LTemp);
                  LPosition := Pos('THEN', UpperCase(LTemp));

                  if (LPosition > 0) and (LPosition + 4 < LTemp.Length) then
                  begin
                    LPText := LPBookmarkText; { Skip found, return pointer back }
                    Continue;
                  end;
                end;

                if Assigned(LCodeFoldingRange) and not LCodeFoldingRange.RegionItem.BreakIfNotFoundBeforeNextRegion.IsEmpty and
                  not LCodeFoldingRange.IsExtraTokenFound and not LRegionItem.RemoveRange then
                begin
                  LOpenTokenFoldRangeList.RemoveItem(LCodeFoldingRange, TList.TDirection.FromEnd);
                  Dec(LFoldCount);
                end;

                if LOpenTokenFoldRangeList.Count > 0 then
                  LFoldRanges := TTextEditorCodeFoldingRange(LOpenTokenFoldRangeList.Last).SubCodeFoldingRanges
                else
                  LFoldRanges := FCodeFoldings.AllRanges;

                LCodeFoldingRange := LFoldRanges.Add(FCodeFoldings.AllRanges, LLine, GetLineIndentLevel(LLine - 1), LFoldCount, LRegionItem, LLine);

                { Open keyword found }
                LRegionItem.Processed := True;
                LOpenTokenFoldRangeList.Add(LCodeFoldingRange);
                Inc(LFoldCount);
                Dec(LPText); { The end of the while loop will increase }

                Result := LRegionItem.OpenTokenBreaksLine;

                if LRegionItem.OpenTokenBreaksLine and LRegionItem.RemoveRange then
                begin
                  LOpenTokenFoldRangeList.RemoveItem(LCodeFoldingRange, TList.TDirection.FromEnd);
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

  var
    LCodeFoldingRangeIndexList: TList;

  function MultiHighlighterOpen: Boolean;
  var
    LChar: Char;
    LCodeFoldingRegion: TTextEditorCodeFoldingRegion;
  begin
    Result := False;

    if LOpenTokenSkipFoldRangeList.Count <> 0 then
      Exit;

    LChar := CaseUpper(LPText^);
    LPBookmarkText := LPText;

    for var LIndex := 1 to Highlighter.CodeFoldingRangeCount - 1 do { First (0) is the default range }
    begin
      LCodeFoldingRegion := Highlighter.CodeFoldingRegions[LIndex];

      if LChar = PChar(LCodeFoldingRegion.OpenToken)^ then { If first character match }
      begin
        LPKeyWord := PChar(LCodeFoldingRegion.OpenToken);

        { Check if open keyword found }
        while (LPText^ <> TControlCharacters.Null) and (LPKeyWord^ <> TControlCharacters.Null) and (CaseUpper(LPText^) = LPKeyWord^) do
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
        end;
      end;
    end;
  end;

  procedure MultiHighlighterClose;
  var
    LChar: Char;
    LCodeFoldingRegion: TTextEditorCodeFoldingRegion;
  begin
    if LOpenTokenSkipFoldRangeList.Count <> 0 then
      Exit;

    LChar := CaseUpper(LPText^);
    LPBookmarkText := LPText;

    for var LIndex := 1 to Highlighter.CodeFoldingRangeCount - 1 do { First (0) is the default range }
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
        end;
      end;
    end;
  end;

  procedure AddTagFolds;
  var
    LDefaultRegion: TTextEditorCodeFoldingRegion;
    LPText: PChar;
    LAdded: Boolean;
    LTokenName: string;
    LOpenToken, LCloseToken: string;
    LRegionItem: TTextEditorCodeFoldingRegionItem;
    LOpenTokenEndChar: Char;
  begin
    LDefaultRegion := FHighlighter.CodeFoldingRegions[DEFAULT_CODE_FOLDING_RANGE_INDEX];
    LPText := PChar(FLines.Text);
    LAdded := False;

    while LPText^ <> TControlCharacters.Null do
    begin
      if LPText^ = TCharacters.TagOpen then
      begin
        Inc(LPText);

        if not (LPText^ in [TCharacters.QuestionMark, TCharacters.ExclamationMark, TCharacters.Slash]) then
        begin
          LTokenName := '';

          while (LPText^ <> TControlCharacters.Null) and not (LPText^ in [TControlCharacters.Tab, TCharacters.Space, TCharacters.TagClose]) do
          begin
            if IsLineTerminatorCharacter(LPText^) then
              Break;

            LTokenName := LTokenName + CaseUpper(LPText^);

            Inc(LPText);
          end;

          LOpenTokenEndChar := LPText^;

          if not Highlighter.InCodeFoldingVoidElements(LTokenname) then
          begin
            if LPText^ in [TCharacters.Space, TControlCharacters.Tab] then
            while (LPText^ <> TControlCharacters.Null) and not (LPText^ in [TCharacters.Slash, TCharacters.TagClose]) do
            begin
              if IsLineTerminatorCharacter(LPText^) then
                Break;

              Inc(LPText);

              if LPText^ in ['"', ''''] then
              begin
                Inc(LPText);

                while (LPText^ <> TControlCharacters.Null) and not (LPText^ in ['"', '''']) do
                  Inc(LPText);
              end;
            end;

            if not LTokenName.IsEmpty and (LPText^ = TCharacters.TagClose) and ((LPText - 1)^ <> TCharacters.Slash) then
            begin
              LOpenToken := TCharacters.TagOpen + LTokenName;

              if not LDefaultRegion.Contains(LOpenToken) then
              begin
                LOpenToken := LOpenToken.Trim + LOpenTokenEndChar;
                LCloseToken := TCharacters.CloseTagOpen + LTokenName + TCharacters.TagClose;

                LRegionItem := LDefaultRegion.Add(LOpenToken, LCloseToken);
                LRegionItem.BreakCharFollows := False;
                LRegionItem.ShowGuideLine := FCodeFolding.GuideLines.Visible;

                LAdded := True;
              end;
            end;
          end;
        end;
      end;

      Inc(LPText);
    end;

    if LAdded then
    begin
      FHighlighter.AddKeyChar(ctFoldOpen, TCharacters.TagOpen);
      FHighlighter.AddKeyChar(ctFoldClose, TCharacters.TagOpen);
    end;
  end;

  var
    LLastFoldRange: TTextEditorCodeFoldingRange;

  procedure ScanCodeFolds;
  var
    LPreviousLine: Integer;
    LProgress: Int64;
    LProgressPosition: Int64;
    LProgressInc: Int64;
    LLength: Int64;
    LProgressPositionInc: Integer;
    LCancelled: Boolean;
    LCodeFoldingRange: TTextEditorCodeFoldingRange;
    LCharSet: TTextEditorCharSet;
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

      for var LIndex := 0 to LCurrentCodeFoldingRegion.Count - 1 do
        LCurrentCodeFoldingRegion[LIndex].Processed := False;

      LProgress := 0;
      LProgressPosition := 0;
      LProgressInc := 0;
      LProgressPositionInc := 1;
      LCancelled := False;

      if FLines.ShowProgress then
      begin
        FLines.ProgressPosition := 0;
        FLines.ProgressType := ptProcessing;

        LLength := Length(FLineNumbers.Cache) - 1;
        LProgressInc := Max(LLength div 100, 1);
        LProgressPositionInc := Max(Round(100 / LLength), 1);
      end;

      LCharSet := FHighlighter.FoldCloseKeyChars + FHighlighter.FoldOpenKeyChars;

      for var LIndex := 1 to Length(FLineNumbers.Cache) - 1 do
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
            while (LPText^ <> TControlCharacters.Null) and not IsWordBreakChar(LPText^) do
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
            FLines.ProgressPosition := FLines.ProgressPosition + LProgressPositionInc;

            if Assigned(FEvents.OnLoadingProgress) then
              FEvents.OnLoadingProgress(Self, LCancelled)
            else
              Paint;

            if LCancelled then
              Exit;

            Inc(LProgress, LProgressInc);
          end;
        end;
      end;

      { Check the last not empty line }
      LLine := FLines.Count - 1;

      while (LLine >= 0) and FLines[LLine].Trim.IsEmpty do
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

            LOpenTokenFoldRangeList.RemoveItem(LLastFoldRange, TList.TDirection.FromEnd);
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

    function LeftCharCount(const ALine: string; const AChar: Char): Integer;
    begin
      Result := 0;

      for var LIndex := 1 to ALine.Length do
      if ALine[LIndex] = AChar then
        Inc(Result)
      else
        Break;
    end;

  var
    LPreviousLine, LPreviousCharCount, LBlockCommentIndex: Integer;
    LInsideBlockComment, LCancelled: Boolean;
    LFoldRangeList: TList;
    LProgress, LProgressPosition, LProgressInc: Int64;
    LCodeFoldingRange: TTextEditorCodeFoldingRange;
    LTextLine: string;
    LCharCount: Integer;
    LFoldRange: TTextEditorCodeFoldingRange;
    LCommentIndex, LLength: Integer;
    LCommentFound: Boolean;
    LFoldRanges: TTextEditorCodeFoldingRanges;
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
      LCancelled := False;

      if FLines.ShowProgress then
      begin
        FLines.ProgressPosition := 0;
        FLines.ProgressType := ptProcessing;
        LProgressInc := (Length(FLineNumbers.Cache) - 1) div 100;
      end;

      for var LIndex := 1 to Length(FLineNumbers.Cache) - 1 do
      begin
        LLine := FLineNumbers.Cache[LIndex];

        if LLine < Length(FCodeFoldings.RangeFromLine) then
          LCodeFoldingRange := FCodeFoldings.RangeFromLine[LLine]
        else
          Break;

        if Assigned(LCodeFoldingRange) and LCodeFoldingRange.Collapsed then
        begin
          LPreviousLine := LLine;
          Continue;
        end;

        LTextLine := FMX.TextEditor.Utils.Trim(FLines[LLine - 1]);

        if FCodeFolding.Outlining and not LTextLine.IsEmpty then
        begin
          if LInsideBlockComment then
          begin
            LInsideBlockComment := Pos(FHighlighter.Comments.BlockComments[LBlockCommentIndex], LTextLine) = 0;

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
              if Pos(FHighlighter.Comments.LineComments[LCommentIndex], LTextLine) = 1 then
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
                if (Pos(FHighlighter.Comments.BlockComments[LCommentIndex], LTextLine) <> 0) and
                  (Pos(FHighlighter.Comments.BlockComments[LCommentIndex + 1], LTextLine) = 0)then
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
          LCharCount :=
            if FCodeFolding.TextFolding.OutlinedBySpacesAndTabs then
              LeftSpaceCount(LTextLine)
            else
              LeftCharCount(LTextLine, FCodeFolding.TextFolding.OutlineCharacter);

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

          if FMX.TextEditor.Utils.Trim(LTextLine).IsEmpty then
          while LFoldRangeList.Count > 0 do
          begin
            LLastFoldRange.ToLine := LLine - 1;
            LFoldRangeList.RemoveItem(LLastFoldRange, TList.TDirection.FromEnd);

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
              LFoldRangeList.RemoveItem(LLastFoldRange, TList.TDirection.FromEnd);

              if LFoldRangeList.Count > 0 then
                LLastFoldRange := TTextEditorCodeFoldingRange(LFoldRangeList.Last);
            end;

            if (LFoldRangeList.Count = 0) or (TTextEditorCodeFoldingRange(LFoldRangeList.Last).FoldRangeLevel <> LCharCount) then
              LFoldRangeList.Add(LFoldRanges.Add(FCodeFoldings.AllRanges, LLine, 0, LCharCount, nil, LLine));
          end
          else
          if not FMX.TextEditor.Utils.Trim(LTextLine).IsEmpty and (LFoldRangeList.Count = 0) then
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
              FEvents.OnLoadingProgress(Self, LCancelled)
            else
              Paint;

            if LCancelled then
              Exit;

            Inc(LProgress, LProgressInc);
          end;
        end;
      end;

      LLine := FLines.Count - 1;

      while (LLine >= 0) and FMX.TextEditor.Utils.Trim(FLines[LLine]).IsEmpty do
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
          LFoldRangeList.RemoveItem(LFoldRange, TList.TDirection.FromEnd);
        end;
      end;
    finally
      LFoldRangeList.Free;
    end;
  end;

begin
  if FSimpleMode or not Assigned(FLineNumbers.Cache) or not IsCodeFoldingVisible or (FLines.Count <= 1) or FHighlighter.Loading then
    Exit;

  if FCodeFolding.TextFolding.Active then
    ScanTextFolds
  else
    ScanCodeFolds;
end;

procedure TCustomTextEditor.InitializeScrollShadow;
begin
  with FScrollHelper.Shadow do
  begin
    if not Assigned(Bitmap) then
      Bitmap := TBitmap.Create;

    if Bitmap.Canvas.BeginScene then
    try
      Bitmap.Canvas.Clear(FScroll.Shadow.Color);
    finally
      Bitmap.Canvas.EndScene;
    end;

    Bitmap.Width := Max(FScroll.Shadow.Width, 1);

    SetLength(AlphaArray, Bitmap.Width);

    if AlphaByteArrayLength <> Bitmap.Width then
    begin
      AlphaByteArrayLength := Bitmap.Width;
      ReallocMem(AlphaByteArray, AlphaByteArrayLength * SizeOf(Byte));
    end;

    for var LIndex := 0 to Bitmap.Width - 1 do
    begin
      AlphaArray[LIndex] := (Bitmap.Width - LIndex) / Bitmap.Width;
      AlphaByteArray[LIndex] := Min(Round(Power(AlphaArray[LIndex], 4) * 255.0), 255);
    end;
  end;
end;

procedure TCustomTextEditor.ScrollingChanged(ASender: TObject);
begin
  if FScroll.Shadow.Visible then
    InitializeScrollShadow
  else
    FreeScrollShadowBitmap;

  UpdateScrollBars;
end;

procedure TCustomTextEditor.ScrollTimerHandler(ASender: TObject);
var
  LCursorPoint: TPointF;
  LViewPosition: TTextEditorViewPosition;
  LTextPosition: TTextEditorTextPosition;
  LLine: Integer;
begin
  if not FMouse.IsScrolling and not (MouseCapture and Pressed) and not Dragging then
  begin
    FScrollHelper.Delta.X := 0;
    FScrollHelper.Delta.Y := 0;
    FScrollHelper.Timer.Enabled := False;
    Exit;
  end;

  IncPaintLock;
  try
    LCursorPoint := ScreenToLocal(Screen.MousePos);

    LViewPosition := PixelsToViewPosition(LCursorPoint.X, LCursorPoint.Y);

    LViewPosition.Row := EnsureRange(LViewPosition.Row, 1, Max(FLineNumbers.Count, 1));

    if LCursorPoint.Y > ClientRect.Height then
      LViewPosition.Column := FLines.ExpandedStringLengths[LViewPosition.Row - 1] + 1;

    if FScrollHelper.Delta.X <> 0 then
      SetHorizontalScrollPosition(FScrollHelper.HorizontalPosition + FScrollHelper.Delta.X);

    if FScrollHelper.Delta.Y <> 0 then
    begin
      TopLine := TopLine + if ssShift in FLast.ShiftState then Round(FScrollHelper.Delta.Y * FLineNumbers.VisibleCount) else Round(FScrollHelper.Delta.Y);

      LLine := TopLine;

      if FScrollHelper.Delta.Y > 0 then
        Inc(LLine, FLineNumbers.VisibleCount - 1);

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

    ComputeScroll(LCursorPoint);
  finally
    DecPaintLock;
  end;
end;

function TCustomTextEditor.GetPreviousBreakPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition;
var
  LPLine: PChar;
begin
  Result := ATextPosition;

  LPLine := PChar(FLines.TextLines[ATextPosition.Line]);

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
  LTextLine: string;
  LLength: Integer;
  LPLine: PChar;
begin
  Result := ATextPosition;

  LTextLine := FLines.TextLines[ATextPosition.Line];
  LLength := LTextLine.Length;
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
      if FSearch.Enabled and SearchAll then
      begin
        if not Assigned(Parent) then
          Exit;

        TextPosition :=
          if FSearch.InSelection.Active and
            not IsSamePosition(FSearch.InSelection.SelectionStartPosition, FSearch.InSelection.SelectionEndPosition) then
            FSearch.InSelection.SelectionStartPosition
          else
            GetBOFPosition;

        if SelectionAvailable then
          TextPosition := SelectionStartPosition;

        FindNext;
      end;
    scInSelectionActive:
      begin
        if FSearch.InSelection.Active then
        begin
          FSearch.InSelection.SelectionStartPosition := GetPreviousBreakPosition(SelectionStartPosition);
          FSearch.InSelection.SelectionEndPosition := GetNextBreakPosition(SelectionEndPosition);
          FPosition.SelectionStart := TextPosition;
          FPosition.SelectionEnd := FPosition.SelectionStart;
        end;

        SearchAll;
      end;
    scVisible:
      SizeOrFontChanged(False);
  end;

  FLeftMarginWidth := GetLeftMarginWidth;
  ClearMinimapBuffer;

  Repaint;
end;

procedure TCustomTextEditor.SelectionChanged(ASender: TObject);
begin
  Repaint;
end;

procedure TCustomTextEditor.SetActiveLine(const AValue: TTextEditorActiveLine);
begin
  FActiveLine.Assign(AValue);
end;

procedure TCustomTextEditor.SetCaretIndex(const AValue: Integer);
var
  LPText: PChar;
  LIndex: Integer;
  LTextPosition: TTextEditorTextPosition;
  LLineBreak: Boolean;
begin
  LPText := PChar(Text);
  LIndex := 0;
  LTextPosition := GetPosition(1, 0);

  while (LPText^ <> TControlCharacters.Null) and (LIndex < AValue) do
  begin
    LLineBreak := IsLineTerminatorCharacter(LPText^);

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

    if LLineBreak then
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

procedure TCustomTextEditor.SetFileMaxReadBufferSize(const AValue: Integer);
begin
  FFile.MaxReadBufferSize := if AValue > TMinValues.FileReadBufferSize then AValue else TMinValues.FileReadBufferSize;
end;

procedure TCustomTextEditor.SetFileMinShowProgressSize(const AValue: Int64);
begin
  FFile.MinShowProgressSize := if AValue > TMinValues.FileShowProgressSize then AValue else TMinValues.FileShowProgressSize;
end;

procedure TCustomTextEditor.SetOvertypeMode(const AValue: TTextEditorOvertypeMode);
begin
  if FOvertypeMode <> AValue then
  begin
    FOvertypeMode := AValue;

    ResetCaret;
    ShowCaret;
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

procedure TCustomTextEditor.SetHorizontalScrollPosition(const AValue: Single);
var
  LValue: Single;
begin
  if AValue > FScrollHelper.HorizontalScrollMax then
    Exit;

  LValue := AValue;

  if FWordWrap.Active or (LValue < 0) then
    LValue := 0;

  if FScrollHelper.HorizontalPosition <> LValue then
  begin
    FScrollHelper.HorizontalPosition := LValue;

    UpdateScrollBars;
    UpdateCaret;
    Repaint;
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

procedure TCustomTextEditor.SetModified(const AValue: Boolean);
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
      FLines.SetLineStates(0, FLines.Count - 1, lsNormal);

      Repaint;
    end;
  end;
end;

procedure TCustomTextEditor.SetMouseScrollCursors(const AIndex: Integer; const AValue: TCursor);
begin
  if (AIndex >= Low(FMouse.ScrollCursors)) and (AIndex <= High(FMouse.ScrollCursors)) then
    FMouse.ScrollCursors[AIndex] := AValue;
end;

procedure TCustomTextEditor.SetOptions(const AValue: TTextEditorOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;

    Repaint;
  end;
end;

procedure TCustomTextEditor.SetTextPosition(const AValue: TTextEditorTextPosition);
var
  LOldLine: Integer;
begin
  LOldLine := FPosition.Text.Line;

  if not FState.ExecutingSelectionCommand and (AValue.Line <> LOldLine) and (LOldLine >= 0) and (LOldLine < FLines.Count) then
    DoTrimTrailingSpaces(LOldLine);

  FPosition.Text := AValue;

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
  LUpdating: Boolean;
  LTextPosition: TTextEditorTextPosition;
begin
  LUpdating := FLines.Updating or FUndoList.InsideUndoBlock;

  if not LUpdating then
    ClearCodeFolding;

  LTextPosition := TextPosition;

  if GetSelectionAvailable then
    AddUndoDelete(LTextPosition, SelectionStartPosition, SelectionEndPosition, GetSelectedText, FSelection.ActiveMode)
  else
    FSelection.ActiveMode := FSelection.Mode;

  DoSelectedText(AValue);

  if not AValue.IsEmpty and (FSelection.ActiveMode <> smColumn) then
    AddUndoInsert(TextPosition, SelectionStartPosition, SelectionEndPosition, '', FSelection.ActiveMode);

  if not LUpdating then
  begin
    InitCodeFolding;
    SearchAll;
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

procedure TCustomTextEditor.SetSelectionStartPosition(const AValue: TTextEditorTextPosition);
var
  LValue: TTextEditorTextPosition;
begin
  FSelection.ActiveMode := Selection.Mode;

  LValue := AValue;

  LValue.Line := EnsureRange(LValue.Line, 0, Max(FLines.Count - 1, 0));
  LValue.Char := if FSelection.Mode = smNormal then EnsureRange(LValue.Char, 1, FLines.StringLength(LValue.Line) + 1) else Max(LValue.Char, 1);

  FPosition.SelectionStart := LValue;
  FPosition.SelectionEnd := LValue;

  Repaint;
end;

procedure TCustomTextEditor.SetSimpleMode(const AValue: Boolean);
begin
  if FSimpleMode <> AValue then
  begin
    FSimpleMode := AValue;

    if FFile.Loaded then
    begin
      if FSimpleMode then
        ClearCodeFolding
      else
      if FHighlighter.Loaded then
      begin
        RescanHighlighterRanges;
        InitCodeFolding;
      end;
    end;

    Repaint;
  end;
end;

procedure TCustomTextEditor.SetSelectionEndPosition(const AValue: TTextEditorTextPosition);
var
  LValue: TTextEditorTextPosition;
  LSelectionStartPosition, LSelectionEndPosition: TTextEditorTextPosition;
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

    LValue.Char := if FSelection.Mode = smNormal then EnsureRange(LValue.Char, 1, FLines.StringLength(LValue.Line) + 1) else Max(LValue.Char, 1);

    if not IsSamePosition(LValue, FPosition.SelectionEnd) then
    begin
      FPosition.SelectionEnd := LValue;

      Repaint;
    end;

    if Assigned(FEvents.OnSelectionChanged) then
      FEvents.OnSelectionChanged(Self);

    if FState.ExecutingSelectionCommand and (soAutoCopyToClipboard in FSelection.Options) then
    begin
      LSelectionStartPosition := FPosition.SelectionStart;
      LSelectionEndPosition := FPosition.SelectionEnd;

      CopyToClipboard;

      FPosition.SelectionStart := LSelectionStartPosition;
      FPosition.SelectionEnd := LSelectionEndPosition;
    end;
  end;
end;

procedure TCustomTextEditor.SetSelectionLength(const AValue: Integer);
begin
  SelectionEndPosition := CharIndexToTextPosition(AValue, SelectionStartPosition, False);
end;

procedure TCustomTextEditor.SetSelectionStart(const AValue: Integer);
begin
  SelectionStartPosition := CharIndexToTextPosition(AValue);
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
  ClearUndo;
end;

procedure TCustomTextEditor.SetTextBetween(const ATextBeginPosition: TTextEditorTextPosition; const ATextEndPosition: TTextEditorTextPosition; const AValue: string);
var
  LSelectionMode: TTextEditorSelectionMode;
begin
  LSelectionMode := FSelection.Mode;

  FSelection.Mode := smNormal;

  FUndoList.BeginBlock;
  try
    FUndoList.AddChange(crCaret, TextPosition, FPosition.SelectionStart, FPosition.SelectionStart, '', FSelection.ActiveMode);
    FPosition.SelectionStart := ATextBeginPosition;
    FPosition.SelectionEnd := ATextEndPosition;

    SelectedText := AValue;
  finally
    FUndoList.EndBlock;
    FSelection.Mode := LSelectionMode;
  end;
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

  LValue :=
    if (soPastEndOfFileMarker in FScroll.Options) and (not LInSelection or LInSelection and (LValue = FLineNumbers.TopLine)) then
      Min(LValue, LViewLineCount)
    else
      Min(LValue, LViewLineCount - FLineNumbers.VisibleCount + 1);

  LValue := Max(LValue, 1);

  if FLineNumbers.TopLine <> LValue then
  begin
    FLineNumbers.TopLine := LValue;

    if FMinimap.Visible and not FScroll.Dragging then
      FMinimap.TopLine := Max(FLineNumbers.TopLine - Abs(Trunc((FMinimap.VisibleLineCount - FLineNumbers.VisibleCount) *
        (FLineNumbers.TopLine / Max(LViewLineCount - FLineNumbers.VisibleCount, 1)))), 1);

    UpdateScrollBars;
    UpdateCaret;
    Repaint;
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
  LTempString := FLines[LTextPosition.Line] + TControlCharacters.Null;
  LLength := LTempString.Length;

  if LTextPosition.Char > LLength then
  begin
    TextPosition := GetPosition(LLength, LTextPosition.Line);
    Exit;
  end;

  FState.ExecutingSelectionCommand := True;

  CharScan;

  LBlockBeginPosition.Line := LTextPosition.Line;
  LBlockEndPosition.Line := LTextPosition.Line;
  SetTextPositionAndSelection(LBlockEndPosition, LBlockBeginPosition, LBlockEndPosition);

  Repaint;
end;

procedure TCustomTextEditor.SetWordWrap(const AValue: TTextEditorWordWrap);
begin
  FWordWrap.Assign(AValue);
end;

procedure TCustomTextEditor.SizeOrFontChanged(const AFontChanged: Boolean);
var
  LScrollPageWidth, LVisibleLineCount: Integer;
  LWidthChanged: Boolean;
  LOldTextPosition: TTextEditorTextPosition;
begin
  if FHighlighter.Loading then
    Exit;

  if Visible and (FPaintHelper.CharWidth <> 0) and FState.CanChangeSize then
  begin
    FPaintHelper.SetBaseFont(FFonts.Text);

    LScrollPageWidth := GetScrollPageWidth;
    LVisibleLineCount := Round(ClientHeight / GetLineHeight);

    if IsRulerVisible then
      Dec(LVisibleLineCount);

    LWidthChanged := LScrollPageWidth <> FScrollHelper.PageWidth;

    if not FHighlighter.Changed and not LWidthChanged and (LVisibleLineCount = FLineNumbers.VisibleCount) then
      Exit;

    GetMinimapLeftRight(FMinimapHelper.Left, FMinimapHelper.Right);
    FillChar(FItalic.OffsetCache, SizeOf(FItalic.OffsetCache), 0);
    FScrollHelper.PageWidth := LScrollPageWidth;
    FLineNumbers.VisibleCount := LVisibleLineCount;

    if FMinimap.Visible then
    begin
      FPaintHelper.SetBaseFont(FFonts.Minimap);

      FMinimap.CharHeight := Max(FPaintHelper.CharHeight - 1, 2);
      FMinimap.VisibleLineCount := Round(ClientHeight / FMinimap.CharHeight);
      FMinimap.TopLine := Max(FLineNumbers.TopLine - Abs(Trunc((FMinimap.VisibleLineCount - FLineNumbers.VisibleCount) *
        (FLineNumbers.TopLine / Max(FLineNumbers.Count - FLineNumbers.VisibleCount, 1)))), 1);

      FPaintHelper.SetBaseFont(FFonts.Text);
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
      FCodeFolding.Width := Trunc(FPaintHelper.CharHeight);

      if Odd(FCodeFolding.Width) then
        FCodeFolding.Width := FCodeFolding.Width - 1;
    end;

    DoLeftMarginAutoSize;

    FScrollHelper.LastHorizontalPosition := -1;
    FScrollHelper.LastVerticalPosition := -1;
    UpdateScrollBars;
  end;
end;

procedure TCustomTextEditor.SpecialCharsChanged(ASender: TObject);
begin
  Repaint;
end;

procedure TCustomTextEditor.UnknownCharsChanged(ASender: TObject);
begin
  FLines.UnknownCharsVisible := FUnknownChars.Visible;
end;

procedure TCustomTextEditor.SyncEditChanged(ASender: TObject);
var
  LTextPosition: TTextEditorTextPosition;
  LSelectionAvailable, LIsWordSelected: Boolean;
  LIndex: Integer;
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
      FSyncEdit.EditBeginPosition := SelectionStartPosition;
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
      FSyncEdit.BlockBeginPosition := SelectionStartPosition;
      FSyncEdit.BlockEndPosition := SelectionEndPosition;
      FSyncEdit.Abort;

      FPosition.SelectionStart := TextPosition;
      FPosition.SelectionEnd := FPosition.SelectionStart;
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

  Repaint;
end;

procedure TCustomTextEditor.TabsChanged(ASender: TObject);
begin
  FLines.TabWidth := FTabs.Width;
  FLines.Columns := toColumns in FTabs.Options;

  if FWordWrap.Active then
    FLineNumbers.ResetCache := True;

  Repaint;
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

procedure TCustomTextEditor.UpdateCollapsedBackup(const AIndex: Integer; const ACount: Integer);
begin
  if not IsCodeFoldingVisible or not FCodeFoldings.AnyCollapsed then
    Exit;

  if Assigned(FCodeFoldings.CollapsedBackup) then
  for var LIndex := 0 to FCodeFoldings.CollapsedBackup.Count - 1 do
  if FCodeFoldings.CollapsedBackup[LIndex] >= AIndex then
    FCodeFoldings.CollapsedBackup[LIndex] := FCodeFoldings.CollapsedBackup[LIndex] + ACount;
end;

procedure TCustomTextEditor.UpdateFoldingRanges(const ACurrentLine: Integer; const ALineCount: Integer);
var
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  for var LIndex := 0 to FCodeFoldings.AllRanges.AllCount - 1 do
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

      if not LCodeFoldingRange.Collapsed and (LCodeFoldingRange.ToLine >= ACurrentLine) then
        LCodeFoldingRange.Widen(ALineCount);
    end;
  end;
end;

procedure TCustomTextEditor.UpdateFoldingRanges(const AFoldRanges: TTextEditorCodeFoldingRanges; const ALineCount: Integer);
var
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  if Assigned(AFoldRanges) then
  for var LIndex := 0 to AFoldRanges.Count - 1 do
  begin
    LCodeFoldingRange := AFoldRanges[LIndex];

    UpdateFoldingRanges(LCodeFoldingRange.SubCodeFoldingRanges, ALineCount);
    LCodeFoldingRange.MoveBy(ALineCount);
  end;
end;

function TCustomTextEditor.PaintLocked: Boolean;
begin
  Result := FPaintLock > 0;
end;

procedure TCustomTextEditor.Resize;
var
  LLineHeight: Single;
begin
  inherited;

  if not Assigned(FPaintHelper) or not Assigned(FHighlighter) or not Assigned(FLines) then
    Exit;

  SizeOrFontChanged(False);

  LLineHeight := GetLineHeight;

  if LLineHeight > 0 then
  begin
    FScrollHelper.PageWidth := GetScrollPageWidth;
    FLineNumbers.VisibleCount := Max(1, Round(Height / LLineHeight));

    if FWordWrap.Active then
      CreateLineNumbersCache(True);
  end;

  UpdateScrollBars;
  Repaint;
end;

procedure TCustomTextEditor.DrawPixelLine(const AX1, AY1, AX2, AY2: Single; const AOpacity: Single = 1; const AThickness: Integer = 1);
var
  LOldStrokeThickness: Single;
  LScale: Single;

  function Align(const AValue: Single): Single;
  begin
    { Odd device pixel thickness centers on a pixel, even thickness sits on a pixel edge }
    Result := if Odd(AThickness) then TextEditorAlignToPixelCenter(AValue, LScale) else Round(AValue * LScale) / LScale;
  end;

begin
  LScale := 1;

  if Assigned(Scene) then
    LScale := Scene.GetSceneScale;

  if LScale <= 0 then
    LScale := 1;

  LOldStrokeThickness := Canvas.Stroke.Thickness;
  Canvas.Stroke.Thickness := Max(1, AThickness) / LScale;
  try
    Canvas.DrawLine(PointF(Align(AX1), Align(AY1)), PointF(Align(AX2), Align(AY2)), AOpacity);
  finally
    Canvas.Stroke.Thickness := LOldStrokeThickness;
  end;
end;

procedure TCustomTextEditor.DrawText(const ARect: TRectF; const AText: string; const AHorizontalAlign: TTextAlign = TTextAlign.Leading; const AVerticalAlign: TTextAlign = TTextAlign.Center);
begin
  if not Assigned(FTextLayout) then
    FTextLayout := TTextLayoutManager.TextLayoutByCanvas(Canvas.ClassType).Create(Canvas);

  FTextLayout.BeginUpdate;
  try
    FTextLayout.Font := Canvas.Font;
    FTextLayout.Color := Canvas.Fill.Color;
    FTextLayout.HorizontalAlign := AHorizontalAlign;
    FTextLayout.VerticalAlign := AVerticalAlign;
    FTextLayout.WordWrap := False;
    FTextLayout.Text := AText;
    FTextLayout.TopLeft := ARect.TopLeft;
    FTextLayout.MaxSize := PointF(Max(ARect.Width, 1), Max(ARect.Height, 1));
  finally
    FTextLayout.EndUpdate;
  end;

  FTextLayout.RenderLayout(Canvas);
end;

procedure TCustomTextEditor.ScrollBarChange(ASender: TObject);
begin
  if FUpdatingScrollBars then
    Exit;

  if ASender = FVerticalScrollBar then
  begin
    TopLine := Round(FVerticalScrollBar.Value) + 1;

    if (soShowVerticalScrollHint in FScroll.Options) and IsVerticalScrollBarTracking then
    begin
      FScrollHelper.IsScrolling := True;
      FScrollHelper.HintTimer.Enabled := True;

      Repaint;
    end;
  end
  else
  if ASender = FHorizontalScrollBar then
    SetHorizontalScrollPosition(Round(FHorizontalScrollBar.Value));
end;

function TCustomTextEditor.GetVerticalScrollBarThumb: TThumb;
var
  LTrack: TCustomTrack;
begin
  Result := nil;

  if not Assigned(FVerticalScrollBar) then
    Exit;

  LTrack := TTextEditorScrollBarAccess(FVerticalScrollBar).Track;

  if Assigned(LTrack) then
    Result := LTrack.Thumb;
end;

function TCustomTextEditor.IsVerticalScrollBarTracking: Boolean;
var
  LThumb: TThumb;
begin
  LThumb := GetVerticalScrollBarThumb;

  Result := Assigned(LThumb) and LThumb.IsPressed;
end;

procedure TCustomTextEditor.ScrollHintTimerHandler(ASender: TObject);
begin
  if IsVerticalScrollBarTracking then
    Exit;

  FScrollHelper.HintTimer.Enabled := False;
  FScrollHelper.IsScrolling := False;

  Repaint;
end;

procedure TCustomTextEditor.ScrollBarMouseDown(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; X, Y: Single);
begin
  ScrollBarMouseMove(ASender, AShift, X, Y);
end;

procedure TCustomTextEditor.ScrollBarMouseMove(ASender: TObject; AShift: TShiftState; X, Y: Single);
begin
  if ASender is TControl then
    TControl(ASender).Cursor := crArrow;

  Cursor := crArrow;
end;

procedure TCustomTextEditor.ScrollBarMouseUp(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; X, Y: Single);
begin
  ScrollBarMouseMove(ASender, AShift, X, Y);
end;

procedure TCustomTextEditor.UpdateScrollBars;
const
  LScrollBarSize = 16;
var
  LBorderWidth: Integer;
  LHorizontalVisible: Boolean;
  LLineHeight: Single;
  LPass: Integer;
  LVerticalMaxScroll: Integer;
  LVerticalVisible: Boolean;
begin
  if PaintLocked or FLines.Streaming or FHighlighter.Loading or FScroll.Dragging and
    not (moMinimapDragsScrollBar in FMinimap.Options) then
    Exit;

  if not Assigned(FVerticalScrollBar) or not Assigned(FHorizontalScrollBar) then
    Exit;

  if (FLines.Count > 0) and (FLineNumbers.ResetCache or not FWordWrap.Active and (FLineNumbers.Count <> FLines.Count)) then
    CreateLineNumbersCache(True);

  LLineHeight := GetLineHeight;

  FUpdatingScrollBars := True;
  try
    LVerticalMaxScroll := 0;

    if FLines.Count > 0 then
    begin
      { The bars are child controls inside the client area, so showing one shrinks the space and can make the other
        one necessary - recompute until visibility settles. }
      for LPass := 1 to 2 do
      begin
        if LLineHeight > 0 then
          FLineNumbers.VisibleCount := Max(1, Round(ClientHeight / LLineHeight));

        if FWordWrap.Active then
        begin
          FScrollHelper.HorizontalPosition := 0;
          FScrollHelper.HorizontalVisible := False;
        end
        else
        begin
          FScrollHelper.PageWidth := GetScrollPageWidth;
          FScrollHelper.HorizontalScrollMax := Max(GetHorizontalScrollMax - 1, 0);
          FScrollHelper.HorizontalVisible := FScrollHelper.HorizontalScrollMax > FScrollHelper.PageWidth;
        end;

        LVerticalMaxScroll := FLineNumbers.Count;

        if soPastEndOfFileMarker in FScroll.Options then
          Inc(LVerticalMaxScroll, FLineNumbers.VisibleCount - 1);

        FScrollHelper.VerticalVisible := LVerticalMaxScroll > FLineNumbers.VisibleCount;

        LHorizontalVisible := FScrollHelper.HorizontalVisible and (FScroll.Bars in [System.UITypes.TScrollStyle.ssBoth, System.UITypes.TScrollStyle.ssHorizontal]);
        LVerticalVisible := FScrollHelper.VerticalVisible and (FScroll.Bars in [System.UITypes.TScrollStyle.ssBoth, System.UITypes.TScrollStyle.ssVertical]);

        if (FHorizontalScrollBar.Visible = LHorizontalVisible) and (FVerticalScrollBar.Visible = LVerticalVisible) then
          Break;

        FHorizontalScrollBar.Visible := LHorizontalVisible;
        FVerticalScrollBar.Visible := LVerticalVisible;
      end;

      if not FScrollHelper.HorizontalVisible then
        FScrollHelper.HorizontalPosition := 0
      else
        FScrollHelper.HorizontalPosition := EnsureRange(FScrollHelper.HorizontalPosition, 0, FScrollHelper.HorizontalScrollMax);

      if not FScrollHelper.VerticalVisible then
        FLineNumbers.TopLine := 1
      else
        FLineNumbers.TopLine := EnsureRange(FLineNumbers.TopLine, 1, Max(1, LVerticalMaxScroll - FLineNumbers.VisibleCount + 1));
    end
    else
    begin
      FScrollHelper.HorizontalVisible := False;
      FScrollHelper.VerticalVisible := False;
      FHorizontalScrollBar.Visible := False;
      FVerticalScrollBar.Visible := False;
    end;

    LHorizontalVisible := FHorizontalScrollBar.Visible;
    LVerticalVisible := FVerticalScrollBar.Visible;
    LBorderWidth := BorderWidth;

    FVerticalScrollBar.Position.X := Max(0, Width - LScrollBarSize - LBorderWidth);
    FVerticalScrollBar.Position.Y := LBorderWidth;
    FVerticalScrollBar.Width := LScrollBarSize;
    FVerticalScrollBar.Height := Height - 2 * LBorderWidth - IfThen(LHorizontalVisible, LScrollBarSize, 0);
    FVerticalScrollBar.Min := 0;
    FVerticalScrollBar.Max := Max(0, LVerticalMaxScroll);
    FVerticalScrollBar.ViewportSize := Max(1, FLineNumbers.VisibleCount);
    FVerticalScrollBar.Value := EnsureRange(TopLine - 1, 0, Max(0, LVerticalMaxScroll - FLineNumbers.VisibleCount));

    FHorizontalScrollBar.Position.X := LBorderWidth;
    FHorizontalScrollBar.Position.Y := Max(0, Height - LScrollBarSize - LBorderWidth);
    FHorizontalScrollBar.Width := Width - 2 * LBorderWidth - IfThen(LVerticalVisible, LScrollBarSize, 0);
    FHorizontalScrollBar.Height := LScrollBarSize;
    FHorizontalScrollBar.Min := 0;
    FHorizontalScrollBar.Max := Max(0, FScrollHelper.HorizontalScrollMax);
    FHorizontalScrollBar.SmallChange := Max(1, FPaintHelper.CharWidth);
    FHorizontalScrollBar.ViewportSize := Max(1, FScrollHelper.PageWidth);
    FHorizontalScrollBar.Value := EnsureRange(FScrollHelper.HorizontalPosition, 0, Round(FHorizontalScrollBar.Max));
  finally
    FUpdatingScrollBars := False;
  end;
end;

procedure TCustomTextEditor.UpdateWordWrap(const AValue: Boolean);
var
  LShowCaret: Boolean;
  LOldTopLine: Integer;
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
      SetSelectionStartPosition(SelectionStartPosition);
      SetSelectionEndPosition(SelectionEndPosition);
    end;

    if LShowCaret then
      EnsureCursorPositionVisible;
  end;
end;

procedure TCustomTextEditor.DoEnter;
begin
  inherited;

  ResetCaret;

  if not Selection.Visible and GetSelectionAvailable then
    Repaint;
end;

procedure TCustomTextEditor.DoExit;
begin
  inherited;

  FreeCompletionProposalPopupWindow;

  if FMultiEdit.Position.Row <> -1 then
  begin
    FMultiEdit.Position.Row := -1;

    UpdateMultiCaretDisplays;
  end;

  if Focused or FCaretHelper.ShowAlways then
    Exit;

  HideCaret;

  Repaint;
end;

procedure TCustomTextEditor.WordWrapChanged(ASender: TObject);
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
    Repaint;
end;

{ Protected declarations }

procedure TCustomTextEditor.MouseWheel(AShift: TShiftState; AWheelDelta: Integer; var AHandled: Boolean);
var
  LLinesToScroll: Integer;
  LWheelClicks: Integer;
begin
  inherited;

  if Assigned(FCompletionProposalPopupWindow) then
  begin
    FCompletionProposalPopupWindow.MouseWheel(AShift, AWheelDelta);
    AHandled := True;
    Exit;
  end;

  if AHandled then
    Exit;

  Inc(FMouse.WheelAccumulator, AWheelDelta);

  LWheelClicks := FMouse.WheelAccumulator div TMouseWheel.Divisor;
  FMouse.WheelAccumulator := FMouse.WheelAccumulator mod TMouseWheel.Divisor;

  LLinesToScroll := 3;

  if LLinesToScroll = -1 then
    LLinesToScroll := FLineNumbers.VisibleCount;

  TopLine := TopLine - LWheelClicks * LLinesToScroll;

  if Assigned(OnScroll) then
    OnScroll(Self, sbVertical);

  Repaint;

  AHandled := True;
end;

function TCustomTextEditor.DoOnReplaceText(const AParams: TTextEditorReplaceTextParams): TTextEditorReplaceAction;
begin
  Result := raCancel;

  if Assigned(FEvents.OnReplaceText) then
    FEvents.OnReplaceText(Self, AParams, Result);
end;

function TCustomTextEditor.DoSearchMatchNotFoundWraparoundDialog: Boolean;
begin
  Result := TDialogServiceSync.MessageDialog(Format(STextEditorSearchMatchNotFound, [sDoubleLineBreak]),
    TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbYes, 0) = mrYes;
end;

function TCustomTextEditor.GetReadOnly: Boolean;
begin
  Result := FState.ReadOnly or FPartialLoad.Enabled;
end;

function TCustomTextEditor.GetSelectionLength: Integer;
begin
  Result := if GetSelectionAvailable then TextPositionToCharIndex(SelectionEndPosition) - TextPositionToCharIndex(SelectionStartPosition) else 0;
end;

function TCustomTextEditor.GetSelectionLineCount: Integer;
begin
  Result := if GetSelectionAvailable then SelectionEndPosition.Line - SelectionStartPosition.Line + 1 else 0;
end;

function TCustomTextEditor.TranslateKeyCode(const ACode: Word; const AShift: TShiftState): TTextEditorCommand;
var
  LIndex: Integer;
begin
  LIndex := KeyCommands.FindKeyCodes(FLast.Key, FLast.ShiftState, ACode, AShift);

  if LIndex >= 0 then
    Result := KeyCommands[LIndex].Command
  else
  begin
    LIndex := KeyCommands.FindKeycode(ACode, AShift);

    Result := if LIndex >= 0 then KeyCommands[LIndex].Command else TKeyCommands.None;
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

procedure TCustomTextEditor.DblClick;
var
  LCursorPoint: TPointF;
  LTextLinesLeft, LTextLinesRight: Integer;
begin
  LCursorPoint := FLast.MouseMovePoint;

  LTextLinesLeft := FLeftMargin.GetWidth + FCodeFolding.GetWidth;
  LTextLinesRight := ClientWidth;

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

    if sfCaretChanged in FState.Flags then
      UpdateCaret;

    Repaint;
  end;
end;

procedure TCustomTextEditor.DoBlockIndent;
var
  LOldSelectionMode: TTextEditorSelectionMode;
  LOldCaretPosition: TTextEditorTextPosition;
  LStringToInsert: string;
  LTab: string;
  LBlockBeginPosition, LBlockEndPosition: TTextEditorTextPosition;
  LEndOfLine, LIndex: Integer;
  LInsertionPosition: TTextEditorTextPosition;
begin
  LOldSelectionMode := FSelection.ActiveMode;
  LOldCaretPosition := TextPosition;
  LStringToInsert := '';
  try
    if GetSelectionAvailable then
    begin
      LBlockBeginPosition := SelectionStartPosition;
      LBlockEndPosition := SelectionEndPosition;
    end
    else
    begin
      LBlockBeginPosition := LOldCaretPosition;
      LBlockEndPosition := LOldCaretPosition;
    end;

    LEndOfLine := LBlockEndPosition.Line;

    if LBlockEndPosition.Char = 1 then
      Dec(LEndOfLine);

    LTab := if toTabsToSpaces in FTabs.Options then StringOfChar(TCharacters.Space, FTabs.Width) else TControlCharacters.Tab;

    LIndex := LBlockBeginPosition.Line;

    while LIndex < LEndOfLine do
    begin
      LStringToInsert := LStringToInsert + LTab + FLines.DefaultLineBreak;

      Inc(LIndex);
    end;

    LStringToInsert := LStringToInsert + LTab;

    FUndoList.BeginBlock(1);
    try
      FUndoList.AddChange(crSelection, LOldCaretPosition, LBlockBeginPosition, LBlockEndPosition, '',
        LOldSelectionMode);

      LInsertionPosition.Line := LBlockBeginPosition.Line;
      LInsertionPosition.Char := if FSelection.ActiveMode = smColumn then LBlockBeginPosition.Char else 1;

      InsertBlock(LInsertionPosition, LInsertionPosition, PChar(LStringToInsert), True);

      FUndoList.AddChange(crIndent, LOldCaretPosition, LBlockBeginPosition, LBlockEndPosition, '', smColumn);
    finally
      FUndoList.EndBlock;
    end;
  finally
    LBlockBeginPosition := GetPosition(LBlockBeginPosition.Char + LTab.Length, LBlockBeginPosition.Line);
    LBlockEndPosition := GetPosition(LBlockEndPosition.Char + LTab.Length, LBlockEndPosition.Line);
    SetTextPositionAndSelection(LBlockEndPosition, LBlockBeginPosition, LBlockEndPosition);
    FSelection.ActiveMode := LOldSelectionMode;

    if FWordWrap.Active then
      CreateLineNumbersCache(True);
  end;
end;

procedure TCustomTextEditor.DoBlockUnindent;
var
  LLine: PChar;
  LSomethingToDelete: Boolean;

  function GetDeletionLength: Integer;
  var
    LRun: PChar;
  begin
    Result := 0;

    LRun := LLine;

    if LRun[0] = TControlCharacters.Tab then
    begin
      Result := 1;
      LSomethingToDelete := True;
      Exit;
    end;

    while (LRun[0] = TCharacters.Space) and (Result < FTabs.Width) do
    begin
      Inc(Result);
      Inc(LRun);

      LSomethingToDelete := True;
    end;

    if (LRun[0] = TControlCharacters.Tab) and (Result < FTabs.Width) then
      Inc(Result);
  end;

var
  LOldSelectionMode: TTextEditorSelectionMode;
  LLength: Integer;
  LLastIndent: Integer;
  LBlockBeginPosition, LBlockEndPosition, LOldCaretPosition: TTextEditorTextPosition;
  LCaretPositionX: Integer;
  LLastLine: Integer;
  LStringToDeleteIndex: Integer;
  LStringToDelete: TTextEditorArrayOfString;
  LDeletionLength: Integer;
  LFirstIndent: Integer;
  LFullStringToDelete: string;
  LDeleteIndex: Integer;
  LLineText: string;
begin
  LOldSelectionMode := FSelection.ActiveMode;
  LLength := 0;
  LLastIndent := 0;

  if GetSelectionAvailable then
  begin
    LBlockBeginPosition := SelectionStartPosition;
    LBlockEndPosition := SelectionEndPosition;
    LOldCaretPosition := TextPosition;
    LCaretPositionX := LOldCaretPosition.Char;
    LLastLine := if SelectionEndPosition.Char = 1 then LBlockEndPosition.Line - 1 else LBlockEndPosition.Line;
    LSomethingToDelete := False;
    LStringToDeleteIndex := 0;

    SetLength(LStringToDelete, LLastLine - LBlockBeginPosition.Line + 1);

    for var LIndex := LBlockBeginPosition.Line to LLastLine do
    begin
      LLine := PChar(FLines[LIndex]);

      if FSelection.ActiveMode = smColumn then
        Inc(LLine, MinIntValue([LBlockBeginPosition.Char - 1, LBlockEndPosition.Char - 1, FLines[LIndex].Length]));

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
      for var LIndex := 0 to Length(LStringToDelete) - 2 do
        LFullStringToDelete := LFullStringToDelete + LStringToDelete[LIndex] + FLines.DefaultLineBreak;

      LFullStringToDelete := LFullStringToDelete + LStringToDelete[Length(LStringToDelete) - 1];
      SetTextCaretY(LBlockBeginPosition.Line);

      LDeleteIndex := if FSelection.ActiveMode = smColumn then Min(LBlockBeginPosition.Char, LBlockEndPosition.Char) else 1;

      LStringToDeleteIndex := 0;

      for var LIndex := LBlockBeginPosition.Line to LLastLine do
      begin
        LLength := Length(LStringToDelete[LStringToDeleteIndex]);
        Inc(LStringToDeleteIndex);

        if LFirstIndent = -1 then
          LFirstIndent := LLength;

        LLineText := FLines.TextLines[LIndex];

        Delete(LLineText, LDeleteIndex, LLength);

        FLines[LIndex] := LLineText;
      end;

      LLastIndent := LLength;

      FUndoList.BeginBlock(2);
      try
        FUndoList.AddChange(crSelection, LOldCaretPosition, LBlockBeginPosition, LBlockEndPosition, '', LOldSelectionMode);
        FUndoList.AddChange(crUnindent, LOldCaretPosition, LBlockBeginPosition, LBlockEndPosition, LFullStringToDelete, FSelection.ActiveMode);
      finally
        FUndoList.EndBlock;
      end;
    end;

    if LFirstIndent = -1 then
      LFirstIndent := 0;

    if FSelection.ActiveMode = smColumn then
      SetTextPositionAndSelection(LOldCaretPosition, LBlockBeginPosition, LBlockEndPosition)
    else
    begin
      LOldCaretPosition.Char := LCaretPositionX;
      Dec(LBlockBeginPosition.Char, LFirstIndent);
      Dec(LBlockEndPosition.Char, LLastIndent);

      SetTextPositionAndSelection(LOldCaretPosition, LBlockBeginPosition, LBlockEndPosition);
    end;

    FSelection.ActiveMode := LOldSelectionMode;
  end;

  if FWordWrap.Active then
    CreateLineNumbersCache(True);
end;

procedure TCustomTextEditor.DoChange;
begin
  FUndoList.Changed := False;
  FRedoList.Changed := False;

  if Assigned(FEvents.OnChange) then
    FEvents.OnChange(Self);
end;

procedure TCustomTextEditor.DoCopyToClipboard(const AText: string);
var
  LHTML: string;
begin
  if AText.IsEmpty then
    Exit;

  AutoCursor;

  LHTML := '';

  if (eoAddHTMLCodeToClipboard in FOptions) and not FMultiEdit.SelectionAvailable and (SelectionStartPosition.Line <> SelectionEndPosition.Line) then
    LHTML := TextToHTML(True);

  SetClipboardText(AText, LHTML);
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

  if LTextPosition.Char <= LLineText.Length then
  begin
    while (LTextPosition.Char > 0) and IsWordBreakChar(LLineText[LTextPosition.Char]) do
      Dec(LTextPosition.Char);

    Result := WordAtTextPosition(LTextPosition);
  end;
end;

procedure TCustomTextEditor.DoExecuteCompletionProposal(const ATriggered: Boolean = False);
var
  LPoint: TPointF;
  LParams: TCompletionProposalParams;
begin
  LPoint := ViewPositionToPixels(ViewPosition);

  LPoint.Y := LPoint.Y + GetLineHeight;

  FreeCompletionProposalPopupWindow;

  FCompletionProposalPopupWindow := TTextEditorCompletionProposalPopupWindow.Create(Self);
  FCompletionProposalPopupWindow.FreeNotification(Self);

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
    begin
      FCompletionProposal.Visible := True;
      Execute(GetCurrentInput, LPoint, LParams.Options);
    end
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
  LChangeTrim: Boolean;
  LLastChangeBlockNumber: Integer;
  LLastChangeReason: TTextEditorChangeReason;
  LLastChangeString: string;
  LIsPasteAction: Boolean;
  LUndoItem: TTextEditorUndoItem;
  LIsKeepGoing: Boolean;
begin
  if ReadOnly then
    Exit;

  if FSyncEdit.Visible then
    FSyncEdit.Visible := False;

  LChangeTrim := eoTrimTrailingSpaces in Options;

  if LChangeTrim then
    Exclude(FOptions, eoTrimTrailingSpaces);

  BeginUpdate;
  try
    RemoveGroupBreak;

    LLastChangeBlockNumber := FUndoList.LastChangeBlockNumber;
    LLastChangeReason := FUndoList.LastChangeReason;
    LLastChangeString := FUndoList.LastChangeString;
    LIsPasteAction := LLastChangeReason = crPaste;
    LUndoItem := FUndoList.PeekItem;

    if Assigned(LUndoItem) then
    begin
      AutoCursor;

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
    end;
  finally
    if LChangeTrim then
      Include(FOptions, eoTrimTrailingSpaces);

    EndUpdate;
  end;
end;

procedure TCustomTextEditor.DoOnCommandProcessed(ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);

  function IsPreviousFoldTokenEndPreviousLine(const ALine: Integer): Boolean;
  var
    LIndex: Integer;
    LFoldingRange: TTextEditorCodeFoldingRange;
    LRegionItem:TTextEditorCodeFoldingRegionItem;
  begin
    Result := False;

    if Length(FCodeFoldings.RangeToLine) = 0 then
      Exit;

    LIndex := ALine;

    while (LIndex > 0) and not Assigned(FCodeFoldings.RangeToLine[LIndex]) do
    begin
      if Assigned(FCodeFoldings.RangeFromLine[LIndex]) then
        Exit(False);

      Dec(LIndex);
    end;

    LFoldingRange := FCodeFoldings.RangeToLine[LIndex];
    LRegionItem := if Assigned(LFoldingRange) and Assigned(LFoldingRange.RegionItem) then LFoldingRange.RegionItem else nil;

    Result := Assigned(LRegionItem) and LRegionItem.TokenEndIsPreviousLine;
  end;

var
  LTextPosition: TTextEditorTextPosition;
begin
  if IsCodeFoldingVisible then
  begin
    LTextPosition := FPosition.Text;

    if ((ACommand = TKeyCommands.Char) or (ACommand = TKeyCommands.DeleteChar) or
      (ACommand = TKeyCommands.LineBreak)) and IsKeywordAtCaretPositionOrAfter(TextPosition) or
      FHighlighter.FoldTags and (ACommand = TKeyCommands.Char) and (AChar = '>') then
      FCodeFoldings.Rescan := True;
  end;

  if FMatchingPairs.Active and not FSyncEdit.Visible then
  case ACommand of
    TKeyCommands.Paste, TKeyCommands.Undo, TKeyCommands.Redo, TKeyCommands.Backspace, TKeyCommands.Tab,
      TKeyCommands.Left, TKeyCommands.Right, TKeyCommands.Up, TKeyCommands.Down, TKeyCommands.PageUp,
      TKeyCommands.PageDown, TKeyCommands.PageTop, TKeyCommands.PageBottom, TKeyCommands.EditorTop,
      TKeyCommands.EditorBottom, TKeyCommands.GoToXY, TKeyCommands.BlockIndent, TKeyCommands.BlockUnindent,
      TKeyCommands.ShiftTab, TKeyCommands.InsertLine, TKeyCommands.Char, TKeyCommands.Text, TKeyCommands.LineBreak,
      TKeyCommands.DeleteChar, TKeyCommands.DeleteWord, TKeyCommands.DeleteWordForward, TKeyCommands.DeleteWordBackward,
      TKeyCommands.DeleteBeginningOfLine, TKeyCommands.DeleteEndOfLine, TKeyCommands.DeleteLine, TKeyCommands.Clear,
      TKeyCommands.WordLeft, TKeyCommands.WordRight:
      ScanMatchingPair;
  end;

  if FCodeFolding.GuideLines.Visible then
  case ACommand of
    TKeyCommands.Cut, TKeyCommands.Paste, TKeyCommands.Undo, TKeyCommands.Redo, TKeyCommands.Backspace, TKeyCommands.DeleteChar:
      CheckIfAtMatchingKeywords;
  end;

  if Assigned(FEvents.OnCommandProcessed) then
    FEvents.OnCommandProcessed(Self, ACommand, AChar, AData);

  if IsCodeFoldingVisible then
  begin
    if FCodeFolding.TextFolding.Active then
    case ACommand of
      TKeyCommands.DeleteChar, TKeyCommands.DeleteWord, TKeyCommands.DeleteWordForward,
        TKeyCommands.DeleteWordBackward, TKeyCommands.DeleteLine, TKeyCommands.Clear, TKeyCommands.LineBreak,
        TKeyCommands.Char, TKeyCommands.Text, TKeyCommands.ImeStr, TKeyCommands.Cut, TKeyCommands.Paste,
        TKeyCommands.BlockIndent, TKeyCommands.BlockUnindent, TKeyCommands.Tab:
        FCodeFoldings.Rescan := True;
    end
    else
    if ((ACommand = TKeyCommands.Char) or (ACommand = TKeyCommands.LineBreak)) and IsPreviousFoldTokenEndPreviousLine(LTextPosition.Line) then
      FCodeFoldings.Rescan := True;
  end;
end;

procedure TCustomTextEditor.DoOnBookmarkPopup(Sender: TObject);
begin
  if Sender is TMenuItem then
    DoToggleBookmark(TMenuItem(Sender).Tag);
end;

procedure TCustomTextEditor.DoOnLeftMarginClick(AButton: TMouseButton; AShift: TShiftState; X, Y: Single);

  procedure ShowBookmarkColorsPopup;
  var
    LPopupMenu: TPopupMenu;
    LMenuItem: TMenuItem;
    LBitmap: TBitmap;
    LBookmarkColors: TTextEditorArrayOfString;
    LPoint: TPointF;
    LScale: Single;
  begin
    CreateBookmarkImages;

    FreeAndNil(FBookmarkPopupMenu);

    LPopupMenu := TPopupMenu.Create(Self);
    FBookmarkPopupMenu := LPopupMenu;
    LPopupMenu.PopupComponent := Self;

    LScale := if Assigned(Scene) then Scene.GetSceneScale else 1;

    LBookmarkColors := [STextEditorBookmarkYellow, STextEditorBookmarkRed, STextEditorBookmarkGreen,
      STextEditorBookmarkBlue, STextEditorBookmarkPurple];

    for var LIndex := 0 to Length(LBookmarkColors) - 1 do
    begin
      LMenuItem := TMenuItem.Create(LPopupMenu);
      LMenuItem.Parent := LPopupMenu;
      LMenuItem.Text := LBookmarkColors[LIndex];
      LMenuItem.Tag := 9 + LIndex;
      LMenuItem.OnClick := DoOnBookmarkPopup;

      LBitmap := FImagesBookmark.GetBitmap(9 + LIndex, TAlphaColors.Null, LScale);
      try
        LMenuItem.Bitmap := LBitmap;
      finally
        LBitmap.Free;
      end;
    end;

    LPoint := LocalToScreen(PointF(X, Y));
    LPopupMenu.Popup(LPoint.X, LPoint.Y);
  end;

var
  LSelectedRow, LLine: Integer;
  LTextPosition: TTextEditorTextPosition;
  LCodeFoldingRegion: Boolean;
  LFoldRange: TTextEditorCodeFoldingRange;
  LMark: TTextEditorMark;
begin
  LSelectedRow := GetSelectedRow(Y);
  LLine := GetViewTextLineNumber(LSelectedRow);
  LTextPosition := ViewToTextPosition(GetViewPosition(1, LSelectedRow));

  TextPosition := LTextPosition;

  if ssShift in AShift then
    SelectionEndPosition := LTextPosition
  else
  begin
    SelectionStartPosition := LTextPosition;
    SelectionEndPosition := FPosition.SelectionStart;
  end;

  if LeftMargin.Bookmarks.Visible and (X < LeftMargin.MarksPanel.Width) and (GetRowCountFromPixel(Y) <= FViewPosition.Row - TopLine) then
  case AButton of
    TMouseButton.mbLeft:
      if bpoToggleBookmarkByClick in LeftMargin.MarksPanel.Options then
        DoToggleBookmark
      else
      if bpoToggleMarkByClick in LeftMargin.MarksPanel.Options then
        DoToggleMark;
    TMouseButton.mbRight:
      if bpoShowBookmarkColorsPopup in LeftMargin.MarksPanel.Options then
        ShowBookmarkColorsPopup;
  end;

  LCodeFoldingRegion := (X >= FLeftMarginWidth - FCodeFolding.GetWidth) and (X <= FLeftMarginWidth);

  if IsCodeFoldingVisible and LCodeFoldingRegion and (FLines.Count > 0) then
  begin
    LFoldRange := CodeFoldingCollapsableFoldRangeForLine(LLine);

    if (cfoShowCollapseMarkAtTheEnd in FCodeFolding.Options) and not Assigned(LFoldRange) then
    begin
      LFoldRange := CodeFoldingFoldRangeForLineTo(LLine);

      if Assigned(LFoldRange) then
      begin
        LTextPosition := GetPosition(1, LFoldRange.FromLine - 1);
        SelectionStartPosition := LTextPosition;
        SelectionEndPosition := FPosition.SelectionStart;
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

      Repaint;
      Exit;
    end;
  end;

  if Assigned(FEvents.OnLeftMarginClick) and (LLine - 1 < FLines.Count) then
  begin
    LMark := nil;

    for var LIndex := 0 to FMarkList.Count - 1 do
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

procedure TCustomTextEditor.DoOnMinimapClick(const Y: Single);
var
  LPreviousLine: Integer;
  LNewLine: Integer;
  LStep: Integer;
begin
  FMinimap.Clicked := True;

  LPreviousLine := -1;
  LNewLine := Max(1, FMinimap.TopLine + Round(Y / FMinimap.CharHeight));

  if (LNewLine >= TopLine) and (LNewLine <= TopLine + FLineNumbers.VisibleCount) then
    FViewPosition.Row := LNewLine
  else
  begin
    LNewLine := LNewLine - FLineNumbers.VisibleCount shr 1;
    LStep := Abs(LNewLine - TopLine) div 5;

    if LNewLine < TopLine then
    while LNewLine < TopLine - LStep do
    begin
      TopLine := TopLine - LStep;

      if TopLine = LPreviousLine then
        Break
      else
        LPreviousLine := TopLine;

      Repaint;
    end
    else
    while LNewLine > TopLine + LStep do
    begin
      TopLine := TopLine + LStep;

      if TopLine = LPreviousLine then
        Break
      else
        LPreviousLine := TopLine;

      Repaint;
    end;

    TopLine := LNewLine;
  end;

  FMinimapHelper.ClickOffsetY := LNewLine - TopLine;
end;

procedure TCustomTextEditor.DoOnSearchMapClick(const Y: Single);
var
  LHeight: Double;
begin
  LHeight := ClientHeight / Max(FLines.Count, 1);

  GoToLineAndSetPosition(Round(Y / LHeight));
end;

procedure TCustomTextEditor.DoOnPaint;
begin
  if Assigned(FEvents.OnPaint) then
  begin
    Canvas.Font.Assign(FFonts.Text);

    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := FColors.EditorBackground;

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

  if Assigned(FMacroRecorder) and (FMacroRecorder.State = msRecording) then
    FMacroRecorder.AddEvent(ACommand, AChar, AData);
end;

procedure TCustomTextEditor.DoSearchStringNotFoundDialog;
begin
  TDialogServiceSync.MessageDialog(Format(STextEditorSearchStringNotFound, [FSearch.SearchText]), TMsgDlgType.mtInformation, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0)
end;

procedure TCustomTextEditor.DoTripleClick;
begin
  SelectionStartPosition := GetPosition(1, FPosition.Text.Line);
  SelectionEndPosition := GetPosition(FLines[FPosition.Text.Line].Length + 1, FPosition.Text.Line);

  FLast.DblClick := 0;

  if Assigned(FEvents.OnCaretChanged) then
    FEvents.OnCaretChanged(Self, FPosition.Text.Char, FPosition.Text.Line, 0);
end;

procedure TCustomTextEditor.DragOver(const AData: TDragObject; const APoint: TPointF; var AOperation: TDragOperation);
begin
  inherited;

  if (AData.Source is TCustomTextEditor) and not ReadOnly then
  begin
    AOperation := TDragOperation.Move;

    if Dragging then
    begin
      TextPosition := PixelsToTextPosition(Round(APoint.X), Round(APoint.Y));
      ComputeScroll(Point(Round(APoint.X), Round(APoint.Y)));

      if FCaret.NonBlinking.Active then
        Repaint
      else
        UpdateCaret;
    end
    else
      TextPosition := PixelsToTextPosition(Round(APoint.X), Round(APoint.Y));
  end;
end;

procedure TCustomTextEditor.FreeHintForm;
begin
  if Assigned(FCodeFoldings.HintForm) then
  with FCodeFoldings do
  begin
    HintForm.Hide;
    HintForm.ItemList.Clear;
    FreeAndNil(HintForm);
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

    FCompletionProposalPopupWindow := nil;

    LCompletionProposalPopupWindow.RemoveFreeNotification(Self);
    LCompletionProposalPopupWindow.Visible := False;
    LCompletionProposalPopupWindow.Parent := nil;

    LCompletionProposalPopupWindow.Free;

    FCompletionProposal.Visible := False;
  end;
end;

procedure TCustomTextEditor.HideCaret;
begin
  Exclude(FState.Flags, sfCaretVisible);

  if Assigned(FCaretDisplay) then
    FCaretDisplay.HideCaret;
end;

procedure TCustomTextEditor.IncPaintLock;
begin
  Inc(FPaintLock);
end;

procedure TCustomTextEditor.DialogKey(var Key: Word; Shift: TShiftState);
var
  LEditorCommand: TTextEditorCommand;
begin
  if (Key = vkTab) and IsFocused and not ReadOnly then
  begin
    LEditorCommand := TranslateKeyCode(Key, Shift);

    if LEditorCommand <> TKeyCommands.None then
    begin
      CommandProcessor(LEditorCommand, TControlCharacters.Null, nil);
      Key := 0;
      Exit;
    end;
  end;

  inherited;
end;

procedure TCustomTextEditor.KeyDown(var AKey: Word; var AKeyChar: WideChar; AShift: TShiftState);
var
  LShortCutKey: Word;
  LShortCutShift: TShiftState;

  function ExecuteCompletionProposal: Boolean;
  begin
    Result := False;

    if (AShift = LShortCutShift) and (AKey = LShortCutKey) then
    begin
      DoExecuteCompletionProposal;

      if not (cpoAutoInvoke in FCompletionProposal.Options) then
      begin
        AKey := 0;

        Result := True;
      end;
    end;
  end;

  function ExecuteCompletionProposalSnippet: Boolean;
  var
    LSnippetItem: TTextEditorCompletionProposalSnippetItem;
  begin
    Result := False;

    for var LIndex := 0 to FCompletionProposal.Snippets.Items.Count - 1 do
    begin
      LSnippetItem := FCompletionProposal.Snippets.Item[LIndex];

      if LSnippetItem.ShortCut <> scNone then
      begin
        TextEditorShortCutToKey(LSnippetItem.ShortCut, LShortCutKey, LShortCutShift);

        if (AShift = LShortCutShift) and (AKey = LShortCutKey) then
          InsertSnippet(LSnippetItem, TextPosition);
      end;
    end;
  end;

var
  LTextPosition: TTextEditorTextPosition;
  LCursorPoint: TPointF;
  LToken: string;
  LRangeType: TTextEditorRangeType;
  LStart: Integer;
  LHighlighterAttribute: TTextEditorHighlighterAttribute;
  LData: Pointer;
  LChar: Char;
  LEditorCommand: TTextEditorCommand;
begin
  inherited;

  if (AKey = 0) and (AKeyChar <> TControlCharacters.Null) then
  begin
    if (FMaxLength > 0) and (FLines.GetTextLength > FMaxLength) then
    begin
      AKeyChar := TControlCharacters.Null;
      Exit;
    end;

    LChar := AKeyChar;

    if FCompletionProposal.Active and FCompletionProposal.Trigger.Active then
      if Pos(LChar, FCompletionProposal.Trigger.Chars) > 0 then
      begin
        FCompletionProposalTimer.Interval := FCompletionProposal.Trigger.Interval;
        FCompletionProposalTimer.Enabled := True;
      end
      else
        FCompletionProposalTimer.Enabled := False;

    if Assigned(FEvents.OnKeyPressW) then
      FEvents.OnKeyPressW(Self, LChar);

    if LChar <> TControlCharacters.Null then
      KeyPressW(LChar);

    if not ReadOnly and FCompletionProposal.Active and not Assigned(FCompletionProposalPopupWindow) and
      (cpoAutoInvoke in FCompletionProposal.Options) and LChar.IsLetter then
      DoExecuteCompletionProposal;

    AKeyChar := TControlCharacters.Null;

    if IsCodeFoldingVisible and FCodeFoldings.Rescan then
      FCodeFoldings.DelayTimer.Restart;

    Exit;
  end;

  if (soALTSetsColumnMode in FSelection.Options) and (ssAlt in AShift) and not (ssCtrl in AShift) and not FState.AltDown then
  begin
    FSaveSelectionMode := FSelection.Mode;
    FSaveScrollOption := soPastEndOfLine in FScroll.Options;
    FScroll.SetOption(soPastEndOfLine, True);
    FSelection.Mode := smColumn;
    FState.AltDown := True;
    SelectionStartPosition := TextPosition;
  end;

  if AKey = 0 then
    Exit;

  if FCaret.MultiEdit.Active and Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) and
    (AKey in [TControlCharacterKeys.CarriageReturn, TControlCharacterKeys.Escape]) then
  begin
    FreeMultiCarets;

    Repaint;
    Exit;
  end;

  if FSyncEdit.Active then
  begin
    if FSyncEdit.Visible and (AKey in [TControlCharacterKeys.CarriageReturn, TControlCharacterKeys.Escape]) then
    begin
      FSyncEdit.Visible := False;
      AKey := 0;
      Exit;
    end;

    TextEditorShortCutToKey(FSyncEdit.ShortCut, LShortCutKey, LShortCutShift);

    if (AShift = LShortCutShift) and (AKey = LShortCutKey) then
    begin
      FSyncEdit.Visible := not FSyncEdit.Visible;
      AKey := 0;
      Exit;
    end;
  end;

  FKeyboardHandler.ExecuteKeyDown(Self, AKey, AKeyChar, AShift);

  { URI mouse over }
  if (ssCtrl in AShift) and not (ssAlt in AShift) and URIOpener then
  begin
    LCursorPoint := ScreenToLocal(Screen.MousePos);
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
        TKeyCommands.SelectionLeft, TKeyCommands.Right, TKeyCommands.SelectionRight, TKeyCommands.Undo:
        ;
      TKeyCommands.Paste:
        if Pos(TControlCharacters.CarriageReturn, GetClipboardText) <> 0 then
          LEditorCommand := TKeyCommands.None;
      TKeyCommands.LineBreak:
        FSyncEdit.Visible := False;
    else
      LEditorCommand := TKeyCommands.None;
    end;

    if LEditorCommand <> TKeyCommands.None then
    begin
      AKey := 0;
      CommandProcessor(LEditorCommand, LChar, LData);
    end;
  finally
    if Assigned(LData) then
      FreeMem(LData);
  end;

  if not ReadOnly and FCaret.MultiEdit.Active and not FMouse.OverURI and (ssCtrl in AShift) and (ssShift in AShift) and
    not (ssAlt in AShift) and (AKey in [vkUp, vkDown]) then
  begin
    AddCaret(ViewPosition);
    MoveCaretVertically(IfThen(AKey = vkDown, 1, -1), False);
    AddCaret(ViewPosition);
    Repaint;
    Exit;
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
    TextEditorShortCutToKey(FCompletionProposal.ShortCut, LShortCutKey, LShortCutShift);

    if ExecuteCompletionProposalSnippet then
      Exit;

    if ExecuteCompletionProposal then
      Exit;
  end;

  if IsCodeFoldingVisible and FCodeFoldings.Rescan then
    FCodeFoldings.DelayTimer.Restart;
end;

procedure TCustomTextEditor.KeyPressW(var AKey: Char);
begin
  FKeyboardHandler.ExecuteKeyPress(Self, AKey);
  CommandProcessor(TKeyCommands.Char, AKey, nil);
end;

procedure TCustomTextEditor.KeyUp(var AKey: Word; var AKeyChar: WideChar; AShift: TShiftState);
begin
  inherited;

  if FMouse.OverURI then
    FMouse.OverURI := False;

  if IsCodeFoldingVisible then
    CheckIfAtMatchingKeywords;

  FKeyboardHandler.ExecuteKeyUp(Self, AKey, AKeyChar, AShift);

  if FMultiEdit.Position.Row <> -1 then
  begin
    FMultiEdit.Position.Row := -1;

    UpdateMultiCaretDisplays;
  end;

  if IsCodeFoldingVisible and FCodeFoldings.Rescan then
    FCodeFoldings.DelayTimer.Restart;
end;

procedure TCustomTextEditor.LinesChanged(ASender: TObject);
begin
  Exclude(FState.Flags, sfLinesChanging);
  FSearch.ClearItems;

  if Visible then
  begin
    if FLeftMargin.LineNumbers.Visible and FLeftMargin.Autosize then
      FLeftMargin.AutosizeDigitCount(FLines.Count);

    UpdateScrollBars;
    Repaint;
  end;
end;

procedure TCustomTextEditor.LinesHookChanged;
begin
  SetHorizontalScrollPosition(FScrollHelper.HorizontalPosition);
  UpdateScrollBars;
end;

procedure TCustomTextEditor.LinesCleared(ASender: TObject);
begin
  MoveCaretToBeginning;
  ClearCodeFolding;
  ClearMatchingPair;
  FBookmarkList.Clear;
  FCaretBookmarkList.Clear;
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

procedure TCustomTextEditor.LinesDeleted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
var
  LIndex: Integer;

  procedure UpdateMarks(AMarkList: TTextEditorMarkList);
  var
    LMark: TTextEditorMark;
  begin
    for var LMarkIndex := 0 to AMarkList.Count - 1 do
    begin
      LMark := AMarkList[LMarkIndex];

      if InRange(LMark.Line, LIndex, LIndex + ACount) then
        LMark.Line := LIndex
      else
      if LMark.Line > LIndex then
        LMark.Line := LMark.Line - ACount;

      LMark.Line := Min(LMark.Line, FLines.Count - 1);
    end;
  end;

begin
  LIndex := AIndex;

  if Assigned(FEvents.OnLinesDeleted) then
    FEvents.OnLinesDeleted(Self, LIndex, ACount);

  if IsCodeFoldingVisible then
    CodeFoldingLinesDeleted(LIndex + 1, ACount);

  UpdateMarks(FBookmarkList);
  UpdateMarks(FCaretBookmarkList);
  UpdateMarks(FMarkList);

  if FLines.Updating then
  begin
    FLineNumbers.ResetCache := True;
    UpdateCollapsedBackup(AIndex, -ACount);
    Exit;
  end;

  if FHighlighter.Loaded then
    RescanHighlighterRanges;

  CreateLineNumbersCache(True);
  CodeFoldingResetCaches;
  EnsureCursorPositionVisible;
  SearchAll;

  Repaint;
end;

procedure TCustomTextEditor.LinesInserted(ASender: TObject; const AIndex: Integer; const ACount: Integer);

  procedure UpdateMarks(const AMarkList: TTextEditorMarkList);
  var
    LMark: TTextEditorMark;
  begin
    for var LIndex := 0 to AMarkList.Count - 1 do
    begin
      LMark := AMarkList[LIndex];

      if LMark.Line >= AIndex then
        LMark.Line := LMark.Line + ACount;

      LMark.Line := Min(LMark.Line, FLines.Count - 1);
    end;
  end;

var
  LLastScan: Integer;
begin
  if not FLines.Streaming then
  begin
    UpdateMarks(FBookmarkList);
    UpdateMarks(FCaretBookmarkList);
    UpdateMarks(FMarkList);
  end;

  if FLines.Updating then
  begin
    FLineNumbers.ResetCache := True;
    UpdateCollapsedBackup(AIndex, ACount);
    Exit;
  end;

  if not FLines.Streaming then
  begin
    if IsCodeFoldingVisible then
      UpdateFoldingRanges(AIndex + 1, ACount);

    if Assigned(FHighlighter.BeforePrepare) then
      FHighlighter.SetOption(hoExecuteBeforePrepare, True);
  end;

  if not FSimpleMode and FHighlighter.Loaded and (FLines.Count > 0) then
  begin
    LLastScan := AIndex;

    repeat
      LLastScan := ScanHighlighterRangesFrom(LLastScan);

      Inc(LLastScan);
    until LLastScan >= AIndex + ACount;
  end;

  CreateLineNumbersCache(True);
  CodeFoldingResetCaches;
  SearchAll;

  Repaint;
end;

procedure TCustomTextEditor.LinesPutted(ASender: TObject; const AIndex: Integer; const ACount: Integer);
var
  LIndex: Integer;
begin
  if FLines.Updating then
  begin
    FLineNumbers.ResetCache := True;
    Exit;
  end;

  if not FSimpleMode and FHighlighter.Loaded and (FLines.Count > 0) then
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

  Repaint;
end;

procedure TCustomTextEditor.AfterConstruction;
begin
  inherited AfterConstruction;

end;

procedure TCustomTextEditor.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TCustomTextEditor) then
  with ASource as TCustomTextEditor do
  begin
    Self.FActiveLine.Assign(FActiveLine);
    Self.Align := Align;
    Self.Anchors := Anchors;
    Self.FBorder.Assign(FBorder);
    Self.FCaret.Assign(FCaret);
    Self.FCodeFolding.Assign(FCodeFolding);
    Self.FColors.Assign(FColors);
    Self.FCompletionProposal.Assign(FCompletionProposal);
    Self.Cursor := Cursor;
    Self.Enabled := Enabled;
    Self.FFonts.Assign(FFonts);
    Self.FFontStyles.Assign(FFontStyles);
    Self.FHighlightLine.Assign(FHighlightLine);
    Self.FLeftMargin.Assign(FLeftMargin);
    Self.LineSpacing := LineSpacing;
    Self.Margins.Assign(Margins);
    Self.FMatchingPairs.Assign(FMatchingPairs);
    Self.FMinimap.Assign(FMinimap);
    Self.FOptions := FOptions;
    Self.OvertypeMode := OvertypeMode;
    Self.ParentShowHint := ParentShowHint;
    Self.PopupMenu := PopupMenu;
    Self.ReadOnly := ReadOnly;
    Self.FReplace.Assign(FReplace);
    Self.FRightMargin.Assign(FRightMargin);
    Self.FRuler.Assign(FRuler);
    Self.FScroll.Assign(FScroll);
    Self.FSearch.Assign(FSearch);
    Self.FSelection.Assign(FSelection);
    Self.ShowHint := ShowHint;
    Self.FSpecialChars.Assign(FSpecialChars);
    Self.FSyncEdit.Assign(FSyncEdit);
    Self.FTabs.Assign(FTabs);
    Self.TabStop := TabStop;
    Self.Touch.Assign(Touch);
    Self.FUndo.Assign(FUndo);
    Self.FUnknownChars.Assign(FUnknownChars);
    Self.Visible := Visible;
    Self.WantReturns := WantReturns;
    Self.FWordWrap.Assign(FWordWrap);
  end
  else
    inherited Assign(ASource);
end;

procedure TCustomTextEditor.Loaded;
begin
  inherited Loaded;

  if not (csDesigning in ComponentState) then
    FHighlighter.LoadFromJSON;

  DoLeftMarginAutoSize;
end;

procedure TCustomTextEditor.MarkListChange(ASender: TObject);
begin
  Repaint;
end;

procedure TCustomTextEditor.MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Single);
var
  LSelectionAvailable: Boolean;
  LSelectedRow: Integer;
  LViewPosition: TTextEditorViewPosition;
  LTextPosition: TTextEditorTextPosition;
  LRowCount, LRow: Integer;
  LMinimapLeft, LMinimapRight: Single;
begin
  FLast.MouseMovePoint := PointF(X, Y);
  FMouse.Down := FLast.MouseMovePoint;

  inherited;

  if Assigned(FCompletionProposalPopupWindow) then
    FreeCompletionProposalPopupWindow;

  LSelectionAvailable := GetSelectionAvailable;
  LSelectedRow := GetSelectedRow(Y);

  if AButton = TMouseButton.mbLeft then
  begin
    FMouse.Down.X := X;

    if not FRuler.Visible or IsRulerVisible and (Y > FRuler.Height) then
      FMouse.Down.Y := Y;

    if FMinimap.Visible then
      ClearMinimapBuffer;

    if not ReadOnly and FCaret.MultiEdit.Active and not FMouse.OverURI then
    begin
      if (ssCtrl in AShift) and not (ssAlt in AShift) then
      begin
        LViewPosition := PixelsToViewPosition(X, Y);

        if ssShift in AShift then
          AddMultipleCarets(LViewPosition)
        else
        begin
          if not Assigned(FMultiEdit.Carets) then
            AddCaret(TextToViewPosition(TextPosition));

          AddCaret(LViewPosition);
        end;

        Repaint;
        Exit;
      end
      else
        FreeMultiCarets;
    end;
  end;

  if FSearch.Map.Visible then
    if (FSearch.Map.Align = saRight) and (X > Width - FSearch.Map.GetWidth) or (FSearch.Map.Align = saLeft) and (X <= FSearch.Map.GetWidth) then
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

  if not FSimpleMode and not ReadOnly and FSyncEdit.Active or (X + 4 > FLeftMarginWidth) and ((AButton = TMouseButton.mbLeft) or (AButton = TMouseButton.mbRight)) then
    LTextPosition := PixelsToTextPosition(X, Y);

  if not FSimpleMode and not ReadOnly and FSyncEdit.Active then
  begin
    if FSyncEdit.BlockSelected and not FSyncEdit.IsTextPositionInBlock(LTextPosition) then
      FSyncEdit.Visible := False;

    if FSyncEdit.Visible then
      if FSyncEdit.IsTextPositionInEdit(LTextPosition) then
      begin
        TextPosition := LTextPosition;
        SelectionStartPosition := TextPosition;
        Exit;
      end
      else
        FSyncEdit.Visible := False;
  end;

  if FMinimap.Visible and not FScroll.Dragging then
  begin
    GetMinimapLeftRight(LMinimapLeft, LMinimapRight);

    if InRange(X, LMinimapLeft, LMinimapRight) then
    begin
      MouseCapture := True;

      DoOnMinimapClick(Y);

      Repaint;
      Exit;
    end;
  end;

  inherited MouseDown(AButton, AShift, X, Y);

  if FRightMargin.Visible and (rmoMouseMove in FRightMargin.Options) then
    if (AButton = TMouseButton.mbLeft) and (Abs(FRightMargin.Position * FPaintHelper.CharWidth + FLeftMarginWidth - X - FScrollHelper.HorizontalPosition) < 3) then
    begin
      FRightMargin.Moving := True;
      FRightMarginMovePosition := FRightMargin.Position * FPaintHelper.CharWidth + FLeftMarginWidth;

      Exit;
    end;

  if IsCodeFoldingVisible and (AButton = TMouseButton.mbLeft) and FCodeFolding.Hint.Indicator.Visible and (cfoExpandByHintClick in FCodeFolding.Options) and (FLines.Count > 0) then
    if DoOnCodeFoldingHintClick(PointF(X, Y)) then
    begin
      Include(FState.Flags, sfCodeFoldingCollapseMarkClicked);
      FCodeFolding.MouseOverHint := False;
      UpdateMouseCursor;

      Repaint;
      Exit;
    end;

  SetFocus;

  if X + 4 > FLeftMarginWidth then
  begin
    if not FRuler.Visible or IsRulerVisible and (Y > FRuler.Height) then
    begin
      FMouse.DownInText := TopLine + GetRowCountFromPixel(Y) <= FLineNumbers.Count;

      if FMouse.DownInText then
      begin
        IncPaintLock;
        try
          FKeyboardHandler.ExecuteMouseDown(Self, AButton, AShift, X, Y);

          if (AButton = TMouseButton.mbLeft) and (ssDouble in AShift) then
          begin
            FLast.DblClick := TThread.GetTickCount;
            FLast.Row := LSelectedRow;
            Exit;
          end
          else
          if (soTripleClickRowSelect in FSelection.Options) and (AShift = [ssLeft]) and (FLast.DblClick > 0) then
          begin
            if (TThread.GetTickCount - FLast.DblClick < FTripleClickInterval) and (FLast.Row = LSelectedRow) then
            begin
              DoTripleClick;

              Repaint;
              Exit;
            end;
            FLast.DblClick := 0;
          end;

          if AButton = TMouseButton.mbLeft then
          begin
            if (FLast.Row > 0) and (FLast.Row <= FLines.Count) then
              DoTrimTrailingSpaces(FLast.Row - 1);

            FLast.Row := LSelectedRow;

            FUndoList.AddChange(crCaret, TextPosition, SelectionStartPosition, SelectionEndPosition, '', FSelection.ActiveMode);
            TextPosition := LTextPosition;

            MouseCapture := True;
            Exclude(FState.Flags, sfWaitForDragging);

            if LSelectionAvailable and (eoDragDropEditing in FOptions) and (X > FLeftMarginWidth) and
              (FSelection.Mode = smNormal) and IsTextPositionInSelection(LTextPosition) then
              Include(FState.Flags, sfWaitForDragging);
          end
          else
          if AButton = TMouseButton.mbRight then
          begin
            if (coRightMouseClickMove in FCaret.Options) and
              (LSelectionAvailable and not IsTextPositionInSelection(LTextPosition) or not LSelectionAvailable) then
            begin
              Repaint;

              FPosition.SelectionEnd := FPosition.SelectionStart;
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
                if not (ssAlt in AShift) and not (ssCtrl in AShift) and FState.AltDown then
                begin
                  FSelection.Mode := FSaveSelectionMode;
                  FScroll.SetOption(soPastEndOfLine, FSaveScrollOption);
                  FState.AltDown := False;
                end;

              TextPosition := LTextPosition;
              SelectionStartPosition := LTextPosition;

              if LSelectionAvailable then
                SelectionEndPosition := LTextPosition;
            end;
          end;
        finally
          DecPaintLock;
        end;
      end
      else
      begin
        LTextPosition := GetPosition(FLines[LTextPosition.Line].Length + 1, FLines.Count - 1);
        TextPosition := LTextPosition;
        SelectionStartPosition := LTextPosition;
        SelectionEndPosition := LTextPosition;
      end;
    end
    else
    if IsRulerVisible and (Y <= FRuler.Height) then
    begin
      LTextPosition.Line := FPosition.Text.Line;
      TextPosition := LTextPosition;

      FRulerMovePosition := -1;
      FRuler.Moving := roShowGuideLine in FRuler.Options;

      ShowRulerLegerLine(X, Y);
      Exit;
    end;
  end;

  if soWheelClickMove in FScroll.Options then
    if (AButton = TMouseButton.mbMiddle) and not FMouse.IsScrolling then
    begin
      FMouse.IsScrolling := True;
      FMouse.ScrollingPoint := PointF(X, Y);

      Repaint;
      Exit;
    end
    else
    if FMouse.IsScrolling then
    begin
      FMouse.IsScrolling := False;

      Repaint;
      Exit;
    end;

  if (X + 4 < FLeftMarginWidth) and (not FRuler.Visible or IsRulerVisible and (Y > FRuler.Height)) then
    DoOnLeftMarginClick(AButton, AShift, X, Y);

  if FMatchingPairs.Active then
    ScanMatchingPair;
end;

function TCustomTextEditor.ShortCutPressed: Boolean;
var
  LKeyCommand: TTextEditorKeyCommand;
begin
  Result := False;

  for var LIndex := 0 to FKeyCommands.Count - 1 do
  begin
    LKeyCommand := FKeyCommands[LIndex];

    if (LKeyCommand.ShiftState = [ssCtrl, ssShift]) or (LKeyCommand.ShiftState = [ssCtrl]) then
      if ssShift in FLast.ShiftState then
        Exit(True);
  end;
end;

procedure TCustomTextEditor.ShowRulerLegerLine(const X, Y: Single);
var
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := PixelsToTextPosition(X, Y);

  FRulerMovePosition := FLeftMarginWidth + (LTextPosition.Char - 1) * FPaintHelper.CharWidth - FScrollHelper.HorizontalPosition;

  Repaint;
end;

procedure TCustomTextEditor.ShowCodeFoldingHint(const X, Y: Single);
var
  LLine: Integer;
  LFoldRange: TTextEditorCodeFoldingRange;
  LPoint: TPointF;
  LRect: TRectF;
begin
  LLine := GetViewTextLineNumber(GetSelectedRow(Y));
  LFoldRange := CodeFoldingCollapsableFoldRangeForLine(LLine);

  if Assigned(LFoldRange) and LFoldRange.Collapsed and not LFoldRange.ParentCollapsed then
  begin
    LPoint := PointF(X, Y);
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
            BackgroundColor := FColors.CodeFoldingHintBackground;
            BorderColor := FColors.CodeFoldingHintBorder;
            TextColor := FColors.CodeFoldingHintText;
            { Assign through the property - the setter recalculates the item height for the zoom-scaled font }
            Font := FFonts.CodeFoldingHint;
          end;

          LLine := LFoldRange.ToLine - LFoldRange.FromLine - 1;

          if LLine > FCodeFolding.Hint.RowCount then
            LLine := FCodeFolding.Hint.RowCount;

          for var LIndex := LFoldRange.FromLine - 1 to LFoldRange.FromLine + LLine do
            FCodeFoldings.HintForm.ItemList.Add(FLines.ExpandedStrings[LIndex]);

          if LLine = FCodeFolding.Hint.RowCount then
            FCodeFoldings.HintForm.ItemList.Add(TCharacters.ThreeDots);

          LPoint.X := FLeftMarginWidth;
          LPoint.Y := LRect.Bottom + 2;

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

procedure TCustomTextEditor.MouseMove(AShift: TShiftState; X, Y: Single);
var
  LMouseMovePoint: TPoint;
  LTextPosition: TTextEditorTextPosition;
  LMultiCaretPosition: TTextEditorViewPosition;
  LViewPosition: TTextEditorViewPosition;
  LRowCount, LRow: Integer;
begin
  LMouseMovePoint := Point(Round(X), Round(Y));

  if FCodeFolding.Visible and FCodeFolding.AutoHide then
    UpdateCodeFoldingGutterHover(X);

  inherited;

  if Dragging then
    Exit;

  if FCaret.MultiEdit.Active and Focused then
  begin
    if (AShift = [ssCtrl, ssShift]) or (AShift = [ssCtrl]) and not ShortCutPressed then
    begin
      LMultiCaretPosition := PixelsToViewPosition(X, Y);

      if not FMouse.OverURI and (meoShowGhost in FCaret.MultiEdit.Options) and (LMultiCaretPosition.Row <= FLines.Count) then
        if (FMultiEdit.Position.Row <> LMultiCaretPosition.Row) or
          (FMultiEdit.Position.Row = LMultiCaretPosition.Row) and (FMultiEdit.Position.Column <> LMultiCaretPosition.Column) then
        begin
          FMultiEdit.Position := LMultiCaretPosition;

          UpdateMultiCaretDisplays;
        end;
    end;

    if Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) then
      Exit;
  end;

  if FMouse.IsScrolling then
  begin
    FLast.MouseMovePoint := LMouseMovePoint;

    ComputeScroll(PointF(X, Y));
    UpdateMouseCursor;
    Exit;
  end;

  if FMinimap.Visible and FMinimap.Clicked then
  begin
    if (X > FMinimapHelper.Left) and (X < FMinimapHelper.Right) then
    begin
      if FScroll.Dragging then
        DragMinimap(Y);

      if not FScroll.Dragging and (ssLeft in AShift) and MouseCapture and (Abs(FMouse.Down.Y - Y) >= FSystemMetrics.VerticalDrag) then
        FScroll.Dragging := True;
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

      Repaint;
      Exit;
    end;
  end;

  if FRuler.Moving and (X > FLeftMarginWidth) and (Y <= FRuler.Height) then
  begin
    ShowRulerLegerLine(X, Y);
    Exit;
  end;

  FRulerMovePosition := -1;

  if (AShift = []) and IsCodeFoldingVisible and FCodeFolding.Hint.Indicator.Visible and FCodeFolding.Hint.Visible then
    ShowCodeFoldingHint(X, Y);

  if MouseCapture then
  begin
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
      if not FRuler.Visible or IsRulerVisible and (Y > FRuler.Height) then
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

            if not IsSamePosition(FPosition.SelectionEnd, LTextPosition) then
            begin
              FState.ExecutingSelectionCommand := True;
              SelectionEndPosition := LTextPosition;
            end;
          end
          else
          if PtInRect(ClientRect, PointF(X, Y)) then
          begin
            LTextPosition := if Assigned(FLines.Items) then GetPosition(FLines.TextLines[LTextPosition.Line].Length + 1, LTextPosition.Line) else GetBOFPosition;

            if not IsSamePosition(FPosition.Text, LTextPosition) then
              TextPosition := LTextPosition;

            if not IsSamePosition(FPosition.SelectionEnd, LTextPosition) then
              SelectionEndPosition := LTextPosition;
          end;
        end;

        ComputeScroll(FLast.MouseMovePoint);

        Include(FState.Flags, sfInSelection);
        Exclude(FState.Flags, sfCodeFoldingCollapseMarkClicked);

        Repaint;
      end;
    end;
  end;

  FLast.MouseMovePoint := LMouseMovePoint;
  UpdateMouseCursor;
end;

procedure TCustomTextEditor.MouseUp(AButton: TMouseButton; AShift: TShiftState; X, Y: Single);
var
  LTextPosition: TTextEditorTextPosition;
  LCursorPoint: TPointF;
  LToken: string;
  LRangeType: TTextEditorRangeType;
  LStart: Integer;
  LHighlighterAttribute: TTextEditorHighlighterAttribute;
begin
  FLast.MouseMovePoint := Point(Round(X), Round(Y));

  inherited;

  FMinimap.Clicked := False;
  FScroll.Dragging := False;

  Exclude(FState.Flags, sfInSelection);

  FKeyboardHandler.ExecuteMouseUp(Self, AButton, AShift, X, Y);

  if IsCodeFoldingVisible then
    CheckIfAtMatchingKeywords;

  if FMouse.OverURI and (AButton = TMouseButton.mbLeft) and (X > FLeftMarginWidth) then
  begin
    LCursorPoint := FLast.MouseMovePoint;

    LTextPosition := PixelsToTextPosition(LCursorPoint.X, LCursorPoint.Y);

    GetHighlighterAttributeAtRowColumn(LTextPosition, LToken, LRangeType, LStart, LHighlighterAttribute);

    if Assigned(FEvents.OnLinkClick) then
      FEvents.OnLinkClick(Self, LToken);

    Exit;
  end;

  if FRightMargin.Visible and FRightMargin.Moving and (rmoMouseMove in FRightMargin.Options) then
  begin
    FRightMargin.Moving := False;

    FRightMargin.Position := Round((FRightMarginMovePosition - FLeftMarginWidth + FScrollHelper.HorizontalPosition) / FPaintHelper.CharWidth);

    if Assigned(FEvents.OnRightMarginMouseUp) then
      FEvents.OnRightMarginMouseUp(Self);

    Repaint;
    Exit;
  end;

  if FRuler.Moving and IsRulerVisible then
  begin
    LTextPosition := PixelsToTextPosition(X, Y);

    LTextPosition.Line := FPosition.Text.Line;
    TextPosition := LTextPosition;
    FRuler.Moving := False;

    Repaint;
    Exit;
  end;

  FMouse.ScrollTimer.Enabled := False;
  FScrollHelper.Timer.Enabled := False;

  FScrollHelper.Delta.X := 0;
  FScrollHelper.Delta.Y := 0;

  if Assigned(PopupMenu) and (AButton = TMouseButton.mbRight) and (AShift = [ssRight]) then
    Exit;

  MouseCapture := False;

  if FState.Flags * [sfDblClicked, sfWaitForDragging] = [sfWaitForDragging] then
  begin
    LTextPosition := PixelsToTextPosition(X, Y);

    TextPosition := LTextPosition;

    if not (ssShift in AShift) then
      SetSelectionStartPosition(LTextPosition);

    SetSelectionEndPosition(LTextPosition);
    ClearMinimapBuffer;

    Exclude(FState.Flags, sfWaitForDragging);
  end;

  Exclude(FState.Flags, sfDblClicked);
end;

procedure TCustomTextEditor.NotifyHookedCommandHandlers(const AAfterProcessing: Boolean; var ACommand: TTextEditorCommand; var AChar: Char; const AData: Pointer);
var
  LHandled: Boolean;
begin
  LHandled := False;

  for var LIndex := 0 to GetHookedCommandHandlersCount - 1 do
    TTextEditorHookedCommandHandler(FHookedCommandHandlers[LIndex]).Event(Self, AAfterProcessing, LHandled, ACommand, AChar, AData);

  if LHandled then
    ACommand := TKeyCommands.None;
end;

procedure TCustomTextEditor.Paint;
var
  LCanvasState: TCanvasSaveState;
  LLeftOffset: Single;
  LMinimapFirstLine: Integer;
  LMinimapLastLine: Integer;
  LMinimapRect: TRectF;
  LTextCanvasState: TCanvasSaveState;
  LTextTopOffset: Single;

begin
  LCanvasState := Canvas.SaveState;
  try
    Canvas.IntersectClipRect(LocalRect);
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := FColors.EditorBackground;
    Canvas.FillRect(LocalRect, 0, 0, [], 1);

    FPaintHelper.SetBaseFont(FFonts.Text);
    Canvas.Font.Assign(FFonts.Text);
    LTextTopOffset := 0;

    if IsRulerVisible then
    begin
      PaintRuler;
      LTextTopOffset := FRuler.Height;
    end;

    LLeftOffset := 0;

    if FMinimap.Align = maLeft then
      LLeftOffset := LLeftOffset + FMinimap.GetWidth;

    if FSearch.Map.Align = saLeft then
      LLeftOffset := LLeftOffset + FSearch.Map.GetWidth;

    if FLeftMargin.Visible then
      PaintLeftMargin(RectF(LLeftOffset, LTextTopOffset, LLeftOffset + FLeftMargin.GetWidth, Height), FLineNumbers.TopLine,
        Min(FLineNumbers.Count, FLineNumbers.TopLine + FLineNumbers.VisibleCount - 1),
        Min(FLineNumbers.Count, FLineNumbers.TopLine + FLineNumbers.VisibleCount - 1));

    if IsCodeFoldingVisible then
      PaintCodeFolding(RectF(LLeftOffset + FLeftMargin.GetWidth, LTextTopOffset,
        LLeftOffset + FLeftMargin.GetWidth + FCodeFolding.GetWidth, Height),
        FLineNumbers.TopLine, Min(FLineNumbers.Count, FLineNumbers.TopLine + FLineNumbers.VisibleCount - 1));

    LTextCanvasState := Canvas.SaveState;
    try
      Canvas.IntersectClipRect(RectF(FLeftMarginWidth, LTextTopOffset, ClientWidth, ClientHeight));
      PaintTextLines(RectF(FLeftMarginWidth - FScrollHelper.HorizontalPosition, LTextTopOffset, Width, Height),
        FLineNumbers.TopLine, Min(FLineNumbers.Count, FLineNumbers.TopLine + FLineNumbers.VisibleCount - 1), False);
    finally
      Canvas.RestoreState(LTextCanvasState);
    end;

    PaintRightMargin(RectF(FLeftMarginWidth, LTextTopOffset, Width, Height));

    if IsCodeFoldingVisible and not FCodeFolding.TextFolding.Active and FCodeFolding.GuideLines.Visible then
      PaintCodeFoldingGuides(FLineNumbers.TopLine, Min(FLineNumbers.TopLine + FLineNumbers.VisibleCount, FLineNumbers.Count));

    if not (csDesigning in ComponentState) and FSyncEdit.Active and FSyncEdit.Visible then
    begin
      LTextCanvasState := Canvas.SaveState;
      try
        Canvas.IntersectClipRect(RectF(FLeftMarginWidth, LTextTopOffset, ClientWidth, ClientHeight));
        PaintSyncItems;
      finally
        Canvas.RestoreState(LTextCanvasState);
      end;
    end;

    if FMinimap.Visible then
    begin
      if FMinimap.Align = maRight then
      begin
        LMinimapRect := RectF(ClientWidth - FMinimap.GetWidth - FSearch.Map.GetWidth - 2, 0, ClientWidth, ClientHeight);

        if FSearch.Map.Align = saRight then
          LMinimapRect.Right := LMinimapRect.Right - FSearch.Map.GetWidth;
      end
      else
      begin
        LMinimapRect := RectF(0, 0, FMinimap.GetWidth, ClientHeight);

        if FSearch.Map.Align = saLeft then
        begin
          LMinimapRect.Left := LMinimapRect.Left + FSearch.Map.GetWidth;
          LMinimapRect.Right := LMinimapRect.Right + FSearch.Map.GetWidth;
        end;
      end;

      if IsRectInUpdateRegion(LMinimapRect) then
      begin
        FPaintHelper.SetBaseFont(FFonts.Minimap);

        LMinimapFirstLine := Max(FMinimap.TopLine, 1);
        LMinimapLastLine := Min(FLineNumbers.Count, LMinimapFirstLine + Trunc(ClientHeight / Max(FMinimap.CharHeight, 1)) + 1);

        LTextCanvasState := Canvas.SaveState;
        try
          Canvas.IntersectClipRect(LMinimapRect);

          if FSimpleMode then
            PaintSimpleTextLines(LMinimapRect, LMinimapFirstLine, LMinimapLastLine, True)
          else
            PaintMinimap(LMinimapRect, LMinimapFirstLine, LMinimapLastLine);

          if ioUseBlending in FMinimap.Indicator.Options then
            PaintMinimapIndicator(LMinimapRect);
        finally
          Canvas.RestoreState(LTextCanvasState);
        end;

        FPaintHelper.SetBaseFont(FFonts.Text);
        Canvas.Font.Assign(FFonts.Text);
      end;

      if FMinimap.Shadow.Visible then
        PaintMinimapShadow(Canvas, RectF(FLeftMarginWidth - FLeftMargin.GetWidth - FCodeFolding.GetWidth, 0,
          ClientWidth - FMinimap.GetWidth - FSearch.Map.GetWidth - 2, ClientHeight));
    end;

    if FSearch.Map.Visible then
    begin
      if FSearch.Map.Align = saRight then
        PaintSearchMap(System.Types.Rect(Round(Width) - FSearch.Map.GetWidth, 0, Round(Width), Round(Height)))
      else
        PaintSearchMap(System.Types.Rect(0, 0, FSearch.Map.GetWidth, Round(Height)));
    end;

    if FScroll.Shadow.Visible and (FScrollHelper.HorizontalPosition <> 0) then
      PaintScrollShadow(Canvas, RectF(FLeftMarginWidth, LTextTopOffset, FLeftMarginWidth + FScrollHelper.PageWidth, Height));

    if FRightMargin.Moving then
    begin
      PaintRightMarginMove;

      if rmoShowMovingHint in FRightMargin.Options then
        PaintRightMarginMoveHint;
    end;

    if FRuler.Moving and not FSimpleMode then
    begin
      PaintRulerMove;

      if FRulerMovePosition >= 0 then
        PaintRulerMoveHint;
    end;

    if FMouse.IsScrolling then
      PaintMouseScrollPoint;

    if FScrollHelper.IsScrolling and (soShowVerticalScrollHint in FScroll.Options) then
      PaintScrollHint;

    PaintBorder;
    DoOnPaint;
  finally
    Canvas.RestoreState(LCanvasState);
  end;
end;

procedure TCustomTextEditor.PaintCodeFolding(const AClipRect: TRectF; const AFirstRow, ALastRow: Integer);
var
  LBackground: TAlphaColor;
  LFoldRange: TTextEditorCodeFoldingRange;
  LLine: Integer;
  LLineHeight: Single;
  LRect: TRectF;
begin
  if AClipRect.Right <= AClipRect.Left then
    Exit;

  LLineHeight := Max(GetLineHeight, 1);
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := FColors.CodeFoldingBackground;
  Canvas.FillRect(RectF(AClipRect.Left, AClipRect.Top, AClipRect.Right, AClipRect.Bottom), 0, 0, [], 1);

  LFoldRange := nil;

  if cfoHighlightFoldingLine in FCodeFolding.Options then
    LFoldRange := CodeFoldingLineInsideRange(FViewPosition.Row);

  for var LIndex := AFirstRow to ALastRow do
  begin
    LLine := GetViewTextLineNumber(LIndex);

    LRect := AClipRect;
    LRect.Top := (LIndex - FLineNumbers.TopLine) * LLineHeight;

    if IsRulerVisible then
      LRect.Top := LRect.Top + FRuler.Height;

    LRect.Bottom := LRect.Top + LLineHeight;

    if FActiveLine.Visible and (FColors.CodeFoldingActiveLineBackground <> TAlphaColors.Null) and
      (not Assigned(FMultiEdit.Carets) and (FPosition.Text.Line + 1 = LLine) or Assigned(FMultiEdit.Carets) and IsMultiEditCaretFound(LLine)) then
    begin
      LBackground := if Focused then FColors.CodeFoldingActiveLineBackground else FColors.CodeFoldingActiveLineBackgroundUnfocused;
      Canvas.Fill.Color := LBackground;
      Canvas.FillRect(RectF(LRect.Left, LRect.Top, LRect.Right, LRect.Bottom), 0, 0, [], 1);
    end
    else
    begin
      LBackground := GetMarkBackgroundColor(LIndex);

      if LBackground <> TAlphaColors.Null then
      begin
        Canvas.Fill.Color := LBackground;
        Canvas.FillRect(RectF(LRect.Left, LRect.Top, LRect.Right, LRect.Bottom), 0, 0, [], 1);
      end;
    end;

    if Assigned(LFoldRange) and (LLine >= LFoldRange.FromLine) and (LLine <= LFoldRange.ToLine) then
      Canvas.Stroke.Color := FColors.CodeFoldingFoldingLineHighlight
    else
      Canvas.Stroke.Color := FColors.CodeFoldingFoldingLine;

    Canvas.Stroke.Kind := TBrushKind.Solid;
    PaintCodeFoldingLine(LRect, LLine);
  end;
end;

procedure TCustomTextEditor.PaintCodeFoldingLine(const AClipRect: TRectF; const ALine: Integer);
var
  LRect: TRectF;
  LX, LY: Single;
  LFoldRange: TTextEditorCodeFoldingRange;
  LEndForLine: Boolean;
  LShowCollapseMarkAtTheEnd: Boolean;
  LSceneScale: Single;
  LThickness: Integer;

  procedure PaintMark(const AEndMark: Boolean = False);
  var
    LPoints: TPolygon;
    LHeight, LTempX, LTempY: Single;
  begin
    LRect.Left :=  LRect.Left + 1;
    LRect.Right := LRect.Right - 1;

    LHeight := LRect.Width;

    if Odd(Round(LHeight)) then
    begin
      LRect.Right := LRect.Right - 1;
      LHeight := LRect.Width;
    end;

    LRect.Top := LRect.Top + (GetLineHeight - LHeight) / 2;
    LRect.Bottom := LRect.Top + LHeight;


    if CodeFolding.MarkStyle = msTriangle then
    begin
      Canvas.Fill.Kind := TBrushKind.Solid;
      Canvas.Fill.Color := Canvas.Stroke.Color;
      SetLength(LPoints, 3);

      if LFoldRange.Collapsed then
      begin
        LPoints[0] := PointF(LRect.Left, LRect.Top);
        LPoints[1] := PointF(LRect.Left, LRect.Bottom);
        LPoints[2] := PointF(LRect.Right, LRect.Top + (LRect.Bottom - LRect.Top) / 2);
      end
      else
      if AEndMark then
      begin
        LPoints[0] := PointF(LRect.Left, LRect.Bottom);
        LPoints[1] := PointF(LRect.Right, LRect.Bottom);
        LPoints[2] := PointF(LRect.Left + (LRect.Right - LRect.Left) / 2, LRect.Top);
      end
      else
      begin
        LPoints[0] := PointF(LRect.Left, LRect.Top);
        LPoints[1] := PointF(LRect.Right, LRect.Top);
        LPoints[2] := PointF(LRect.Left + (LRect.Right - LRect.Left) / 2, LRect.Bottom);
      end;

      Canvas.FillPolygon(LPoints, 1);
    end
    else
    begin
      case CodeFolding.MarkStyle of
        msSquare:
          begin
            DrawPixelLine(LRect.Left, LRect.Top, LRect.Right, LRect.Top, 1, LThickness);
            DrawPixelLine(LRect.Right, LRect.Top, LRect.Right, LRect.Bottom, 1, LThickness);
            DrawPixelLine(LRect.Right, LRect.Bottom, LRect.Left, LRect.Bottom, 1, LThickness);
            DrawPixelLine(LRect.Left, LRect.Bottom, LRect.Left, LRect.Top, 1, LThickness);
          end;
        msCircle:
          begin
            Canvas.Fill.Kind := TBrushKind.Solid;
            Canvas.Fill.Color := FColors.CodeFoldingBackground;
            Canvas.FillEllipse(LRect, 1);
            Canvas.Stroke.Thickness := LThickness / LSceneScale;
            Canvas.DrawEllipse(LRect, 1);
          end;
      end;

      { - }
      LTempX := Round(LRect.Width / 4);
      LTempY := LRect.Top + LRect.Height / 2;

      DrawPixelLine(LRect.Left + LTempX, LTempY, LRect.Right - LTempX, LTempY, 1, LThickness);

      if LFoldRange.Collapsed then
      begin
        { + }
        LTempX := LRect.Left + LRect.Width / 2;
        LTempY := Round(LRect.Height / 4);

        DrawPixelLine(LTempX, LRect.Top + LTempY, LTempX, LRect.Bottom - LTempY, 1, LThickness);
      end;
    end;

    if LShowCollapseMarkAtTheEnd and (CodeFolding.MarkStyle <> msTriangle) then
    begin
      LTempX := LRect.Left + (LRect.Right - LRect.Left) / 2;

      if AEndMark then
      begin
        DrawPixelLine(LRect.Left, LRect.Top, LTempX, AClipRect.Top, 1, LThickness);
        DrawPixelLine(LTempX, AClipRect.Top, LRect.Right, LRect.Top, 1, LThickness);
      end
      else
      if not LFoldRange.Collapsed then
      begin
        DrawPixelLine(LRect.Left, LRect.Bottom, LTempX, AClipRect.Bottom, 1, LThickness);
        DrawPixelLine(LTempX, AClipRect.Bottom, LRect.Right, LRect.Bottom, 1, LThickness);
      end;
    end;
  end;

begin
  LFoldRange := CodeFoldingCollapsableFoldRangeForLine(ALine);

  if FCodeFolding.AutoHide and not FCodeFoldings.MouseOverGutter and not (Assigned(LFoldRange) and LFoldRange.Collapsable and LFoldRange.Collapsed) then
    Exit;

  LSceneScale := 1;

  if Assigned(Scene) then
    LSceneScale := Scene.GetSceneScale;

  if LSceneScale <= 0 then
    LSceneScale := 1;

  LThickness := Max(1, Trunc(FPixelsPerInch / 96 * LSceneScale));

  LRect := AClipRect;
  LRect.Inflate(Trunc(FPixelsPerInch / 96 * -2), 0);

  LShowCollapseMarkAtTheEnd := cfoShowCollapseMarkAtTheEnd in FCodeFolding.Options;

  if not Assigned(LFoldRange) then
  begin
    if cfoShowTreeLine in FCodeFolding.Options then
    begin
      LEndForLine := CodeFoldingTreeEndForLine(ALine);

      if CodeFoldingTreeLineForLine(ALine) and not (LShowCollapseMarkAtTheEnd and LEndForLine) then
      begin
        LX := LRect.Left + (LRect.Right - LRect.Left) / 2;
        DrawPixelLine(LX, LRect.Top, LX, LRect.Bottom, 1, LThickness);
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
          LX := LRect.Left + (LRect.Right - LRect.Left) / 2;
          LY := LRect.Top + (LRect.Bottom - LRect.Top) - 4;

          DrawPixelLine(LX, LRect.Top, LX, LY, 1, LThickness);
          DrawPixelLine(LX, LY, LRect.Right - 1, LY, 1, LThickness);
        end;
      end;
    end;
  end
  else
  if LFoldRange.Collapsable then
    PaintMark;
end;

procedure TCustomTextEditor.PaintCodeFoldingCollapsedLine(const AFoldRange: TTextEditorCodeFoldingRange; const ALineRect: TRectF);
var
  LOldStrokeColor: TAlphaColor;
begin
  if IsCodeFoldingVisible and (cfoShowCollapsedLine in CodeFolding.Options) and Assigned(AFoldRange) and
    AFoldRange.Collapsed and not AFoldRange.ParentCollapsed then
  begin
    LOldStrokeColor := Canvas.Stroke.Color;

    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Color := FColors.CodeFoldingCollapsedLine;
    DrawPixelLine(ALineRect.Left, ALineRect.Bottom - 1, Width, ALineRect.Bottom - 1);
    Canvas.Stroke.Color := LOldStrokeColor;
  end;
end;

procedure TCustomTextEditor.PaintCodeFoldingCollapseMark(const AFoldRange: TTextEditorCodeFoldingRange; const ACurrentLineText: string; const ATokenPosition, ATokenLength, ALine: Integer; const ALineRect: TRectF);
var
  LOldFillColor: TAlphaColor;
  LOldStrokeColor: TAlphaColor;
  LViewPosition: TTextEditorViewPosition;
  LCollapseMarkRect: TRectF;
  LDrawRect: TRectF;
  LIndex: Integer;
  LX, LY: Single;
  LDotSize: Single;
  LBoxHeight: Single;
  LPoints: TPolygon;
  LScale: Single;

  function AlignToPixel(const AValue: Single): Single;
  begin
    Result := Round(AValue * LScale) / LScale;
  end;

begin
  LScale := 1;

  if Assigned(Scene) then
    LScale := Scene.GetSceneScale;

  if LScale <= 0 then
    LScale := 1;

  LOldFillColor := Canvas.Fill.Color;
  LOldStrokeColor := Canvas.Stroke.Color;
  try
    if IsCodeFoldingVisible and FCodeFolding.Hint.Indicator.Visible and Assigned(AFoldRange) and
      AFoldRange.Collapsed and not AFoldRange.ParentCollapsed then
    begin
      LViewPosition.Row := ALine + 1;
      LViewPosition.Column := ATokenPosition + ATokenLength + 2;

      if FSpecialChars.Visible and (ALine <> FLines.Count) and (ALine <> FLineNumbers.Count) then
        Inc(LViewPosition.Column);

      LDotSize := 2 * FPixelsPerInch / 96;

      if LDotSize < 2 then
        LDotSize := 2;

      LBoxHeight := ALineRect.Height * 0.7;

      LCollapseMarkRect.Left := ViewPositionToPixels(LViewPosition, ACurrentLineText).X - FCodeFolding.Hint.Indicator.Padding.Left;
      LCollapseMarkRect.Right := LCollapseMarkRect.Left + 9 * LDotSize;
      LCollapseMarkRect.Top := ALineRect.Top + (ALineRect.Height - LBoxHeight) / 2;
      LCollapseMarkRect.Bottom := LCollapseMarkRect.Top + LBoxHeight;

      if LCollapseMarkRect.Right > FLeftMarginWidth then
      begin
        LDrawRect := RectF(AlignToPixel(LCollapseMarkRect.Left), AlignToPixel(LCollapseMarkRect.Top),
          AlignToPixel(LCollapseMarkRect.Right), AlignToPixel(LCollapseMarkRect.Bottom));

        if FColors.EditorBackground <> FColors.CodeFoldingHintIndicatorBackground then
        begin
          Canvas.Fill.Kind := TBrushKind.Solid;
          Canvas.Fill.Color := FColors.CodeFoldingHintIndicatorBackground;
          Canvas.FillRect(LDrawRect, 0, 0, [], 1);
        end;

        if hioShowBorder in FCodeFolding.Hint.Indicator.Options then
        begin
          Canvas.Stroke.Kind := TBrushKind.Solid;
          Canvas.Stroke.Color := FColors.CodeFoldingHintIndicatorBorder;

          DrawPixelLine(LDrawRect.Left, LDrawRect.Top, LDrawRect.Right - 1 / LScale, LDrawRect.Top);
          DrawPixelLine(LDrawRect.Right - 1 / LScale, LDrawRect.Top, LDrawRect.Right - 1 / LScale, LDrawRect.Bottom - 1 / LScale);
          DrawPixelLine(LDrawRect.Right - 1 / LScale, LDrawRect.Bottom - 1 / LScale, LDrawRect.Left, LDrawRect.Bottom - 1 / LScale);
          DrawPixelLine(LDrawRect.Left, LDrawRect.Bottom - 1 / LScale, LDrawRect.Left, LDrawRect.Top);
        end;

        if hioShowMark in FCodeFolding.Hint.Indicator.Options then
        begin
          Canvas.Stroke.Kind := TBrushKind.Solid;
          Canvas.Stroke.Color := FColors.CodeFoldingHintIndicatorMark;
          Canvas.Fill.Kind := TBrushKind.Solid;
          Canvas.Fill.Color := FColors.CodeFoldingHintIndicatorMark;

          case FCodeFolding.Hint.Indicator.MarkStyle of
            imsThreeDots:
              begin
                { [...] }
                LY := AlignToPixel(LDrawRect.Top + (LDrawRect.Height - LDotSize) / 2);
                LX := LDrawRect.Left + (LDrawRect.Width - 5 * LDotSize) / 2;
                LIndex := 1;

                while LIndex <= 3 do
                begin
                  Canvas.FillRect(RectF(AlignToPixel(LX), LY, AlignToPixel(LX) + LDotSize, LY + LDotSize), 0, 0, [], 1);
                  LX := LX + 2 * LDotSize;
                  Inc(LIndex);
                end;
              end;
            imsTriangle:
              begin
                LX := (LDrawRect.Width - LDrawRect.Height) / 2;

                SetLength(LPoints, 3);
                LPoints[0] := PointF(AlignToPixel(LDrawRect.Left + LX + 2), AlignToPixel(LDrawRect.Top + 2));
                LPoints[1] := PointF(AlignToPixel(LDrawRect.Right - LX - 3), LPoints[0].Y);
                LPoints[2] := PointF(AlignToPixel(LDrawRect.Left + LDrawRect.Width / 2), AlignToPixel(LDrawRect.Bottom - 3));

                Canvas.FillPolygon(LPoints, 1);
              end;
          end;
        end;
      end;

      OffsetRect(LCollapseMarkRect, FLeftMarginWidth, 0);
      AFoldRange.CollapseMarkRect := LCollapseMarkRect;
    end;
  finally
    Canvas.Fill.Color := LOldFillColor;
    Canvas.Stroke.Color := LOldStrokeColor;
  end;
end;

procedure TCustomTextEditor.PaintCodeFoldingGuides(const AFirstRow, ALastRow: Integer);
var
  LCodeFoldingRange, LCodeFoldingRangeTo: TTextEditorCodeFoldingRange;
  LCodeFoldingRanges: array of TTextEditorCodeFoldingRange;
  LCurrentLine, LTopLine, LBottomLine, LLine, LRangeIndex: Integer;
  LLineHeight: Single;
  LDeepestLevel: Integer;
  LX, LY, LHeight: Single;
  LGuideLineColumn: Integer;
  LLineText: string;
  LHideAtFirstColumn, LHideInActiveRow, LHideOverText, LHighlightIndentGuides: Boolean;
  LOldStrokeColor: TAlphaColor;
  LOldStrokeThickness: Single;
  LStyle: TTextEditorCodeFoldingGuideLineStyle;

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
          Break;
        end
        else
          Dec(LTempLine);
      end;

      if Assigned(LCodeFoldingRange) then
        Result := LCodeFoldingRange.IndentLevel;
    end;
  end;

  procedure GetCodeFoldingRanges;
  begin
    SetLength(LCodeFoldingRanges, FCodeFoldings.AllRanges.AllCount);
    LRangeIndex := 0;

    for var LIndex := 0 to FCodeFoldings.AllRanges.AllCount - 1 do
    begin
      LCodeFoldingRange := FCodeFoldings.AllRanges[LIndex];

      if Assigned(LCodeFoldingRange) then
      begin
        if (LCodeFoldingRange.ToLine < LTopLine) or (LCodeFoldingRange.FromLine > LBottomLine) then
          Continue;

        for var LRow := AFirstRow to ALastRow do
        begin
          LLine := GetViewTextLineNumber(LRow);

          if not LCodeFoldingRange.Collapsed and not LCodeFoldingRange.ParentCollapsed and
            (LCodeFoldingRange.FromLine < LLine) and (LCodeFoldingRange.ToLine > LLine) then
          begin
            LCodeFoldingRanges[LRangeIndex] := LCodeFoldingRange;
            Inc(LRangeIndex);
            Break;
          end;
        end;
      end;
    end;

    SetLength(LCodeFoldingRanges, LRangeIndex);
  end;

  procedure DrawGuideLine(const AX: Single; const AY1, AY2: Single; const AStyle: TTextEditorCodeFoldingGuideLineStyle);
  var
    LDashLength, LPeriod: Integer;
    LSegmentStart, LSegmentEnd: Single;
  begin
    if AStyle = lsSolid then
      DrawPixelLine(AX, AY1, AX, AY2)
    else
    begin
      LDashLength := if AStyle = lsDash then 3 else 1;
      LPeriod := LDashLength shl 1;
      LSegmentStart := 1 + Floor((AY1 - 1) / LPeriod) * LPeriod;

      while LSegmentStart < AY2 do
      begin
        LSegmentEnd := LSegmentStart + LDashLength;

        if LSegmentEnd > AY1 then
          DrawPixelLine(AX, Max(LSegmentStart, AY1), AX, Min(LSegmentEnd, AY2));

        LSegmentStart := LSegmentStart + LPeriod;
      end;
    end;
  end;

begin
  if not FCodeFolding.GuideLines.Visible then
    Exit;

  LOldStrokeColor := Canvas.Stroke.Color;
  LOldStrokeThickness := Canvas.Stroke.Thickness;
  try
    LLineHeight := GetLineHeight;
    LY := 0;

    if IsRulerVisible then
      LY := FRuler.Height;

    LCurrentLine := GetViewTextLineNumber(FViewPosition.Row);
    LCodeFoldingRange := nil;
    LDeepestLevel := 0;

    if not FScroll.Dragging then
      LDeepestLevel := GetDeepestLevel;

    LTopLine := GetViewTextLineNumber(AFirstRow);
    LBottomLine := GetViewTextLineNumber(ALastRow);
    LHideAtFirstColumn := cfgHideAtFirstColumn in FCodeFolding.GuideLines.Options;
    LHideInActiveRow := cgfHideInActiveRow in FCodeFolding.GuideLines.Options;
    LHideOverText := cfgHideOverText in FCodeFolding.GuideLines.Options;
    LHighlightIndentGuides := cfgHighlightIndentGuides in FCodeFolding.GuideLines.Options;

    GetCodeFoldingRanges;

    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Thickness := 1;

    for var LRow := AFirstRow to ALastRow do
    begin
      LLine := GetViewTextLineNumber(LRow);
      LHeight := LY + LLineHeight;

      for var LIndex := 0 to LRangeIndex - 1 do
      begin
        LCodeFoldingRange := LCodeFoldingRanges[LIndex];

        if Assigned(LCodeFoldingRange) and not LCodeFoldingRange.Collapsed and not LCodeFoldingRange.ParentCollapsed and
          (LCodeFoldingRange.FromLine < LLine) and (LCodeFoldingRange.ToLine > LLine) then
        begin
          if Assigned(LCodeFoldingRange.RegionItem) and not LCodeFoldingRange.RegionItem.ShowGuideLine then
            Continue;

          LX := FLeftMarginWidth + GetLineIndentLevel(LCodeFoldingRange.ToLine - 1) * FPaintHelper.CharWidth + FCodeFolding.GuideLines.Padding;

          if LHideAtFirstColumn and (LX < FLeftMarginWidth + FPaintHelper.CharWidth) or
            LHideInActiveRow and (LRow = FViewPosition.Row) then
            Continue;

          if LHideOverText then
          begin
            LGuideLineColumn := GetLineIndentLevel(LCodeFoldingRange.ToLine - 1) + 1;
            LLineText := FLines.ExpandedStrings[LLine - 1];

            if (Length(LLineText) >= LGuideLineColumn) and (LLineText[LGuideLineColumn] <> TCharacters.Space) then
              Continue;
          end;

          LX := LX - FScrollHelper.HorizontalPosition;

          if LX - FLeftMarginWidth > 0 then
          begin
            if LHighlightIndentGuides and (LDeepestLevel = LCodeFoldingRange.IndentLevel) and
              (LCurrentLine >= LCodeFoldingRange.FromLine) and (LCurrentLine <= LCodeFoldingRange.ToLine) then
            begin
              Canvas.Stroke.Color := FColors.CodeFoldingIndentHighlight;
              LStyle := FCodeFolding.GuideLines.HighlightStyle;
            end
            else
            begin
              Canvas.Stroke.Color := FColors.CodeFoldingIndent;
              LStyle := FCodeFolding.GuideLines.Style;
            end;

            DrawGuideLine(LX, LY + 1, LHeight + 1, LStyle);
          end;
        end;
      end;

      LY := LY + LLineHeight;
    end;
  finally
    SetLength(LCodeFoldingRanges, 0);
    Canvas.Stroke.Color := LOldStrokeColor;
    Canvas.Stroke.Thickness := LOldStrokeThickness;
  end;
end;

procedure TCustomTextEditor.CreateBookmarkImages;
var
  LPixelsPerInch: Integer;
  LBookmarkColors: TTextEditorBookmarkColors;
begin
  if not Assigned(FImagesBookmark) then
  begin
    LPixelsPerInch := if FLeftMargin.Bookmarks.Scaled then FPixelsPerInch else 96;

    FImagesBookmark :=
      if Assigned(FLeftMargin.Bookmarks.Images) then
        TTextEditorInternalImage.Create(FLeftMargin.Bookmarks.Images, LPixelsPerInch)
      else
        TTextEditorInternalImage.Create(TTextEditorInternalImage.DefaultImageCount, LPixelsPerInch);
  end;

  LBookmarkColors.Yellow := FColors.BookmarkYellow;
  LBookmarkColors.Red := FColors.BookmarkRed;
  LBookmarkColors.Green := FColors.BookmarkGreen;
  LBookmarkColors.Blue := FColors.BookmarkBlue;
  LBookmarkColors.Purple := FColors.BookmarkPurple;
  FImagesBookmark.SetColors(LBookmarkColors);
end;

procedure TCustomTextEditor.CreateCollapsedBackup;
var
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  if not IsCodeFoldingVisible or not FCodeFoldings.AnyCollapsed then
    Exit;

  FCodeFoldings.CollapsedBackup := TList<Integer>.Create;

  for var LIndex := 0 to Length(FCodeFoldings.RangeFromLine) - 1 do
  begin
    LCodeFoldingRange := FCodeFoldings.RangeFromLine[LIndex];

    if Assigned(LCodeFoldingRange) and LCodeFoldingRange.Collapsed then
      FCodeFoldings.CollapsedBackup.Add(LCodeFoldingRange.FromLine);
  end;
end;

procedure TCustomTextEditor.PaintLeftMargin(const AClipRect: TRectF; const AFirstLine, ALastTextLine, ALastLine: Integer);
var
  LLineHeight: Single;

  procedure DrawBookmark(const ABookmark: TTextEditorMark; var AOverlappingOffset: Integer; const AMarkRow: Integer);
  var
    LRow: Integer;
    LY: Single;
  begin
    CreateBookmarkImages;

    LRow := AMarkRow;

    if FWordWrap.Active then
      LRow := GetViewLineNumber(LRow);

    LY := (LRow - TopLine) * LLineHeight;

    if IsRulerVisible then
      LY := LY + FRuler.Height;

    FImagesBookmark.Draw(Canvas, ABookmark.ImageIndex, AClipRect.Left + FLeftMargin.Bookmarks.LeftMargin,
      LY, LLineHeight, TAlphaColors.Fuchsia);

    Inc(AOverlappingOffset, FLeftMargin.Marks.OverlappingOffset);
  end;

  procedure DrawMark(const AMark: TTextEditorMark; const AOverlappingOffset: Integer; const AMarkRow: Integer);
  var
    LRow: Integer;
    LY: Single;
  begin
    if Assigned(FLeftMargin.Marks.Images) then
      if AMark.ImageIndex <= FLeftMargin.Marks.Images.Count then
      begin
        var LRect := FLeftMargin.Marks.Images.Destination[AMark.ImageIndex].Layers[0].SourceRect.Rect;

        LY := if LLineHeight > LRect.Height then LLineHeight / 2 - LRect.Height / 2 else 0;

        if IsRulerVisible then
          LY := LY + FRuler.Height;

        LRow := AMarkRow;

        if FWordWrap.Active then
          LRow := GetViewLineNumber(LRow);

        var LImageRect: TRectF;

        LImageRect.Left := AClipRect.Left + FLeftMargin.Marks.LeftMargin + AOverlappingOffset;
        LImageRect.Top := (LRow - TopLine) * LLineHeight + LY;
        LImageRect.Width := LRect.Width;
        LImageRect.Height := LRect.Height;

        FLeftMargin.Marks.Images.Draw(Canvas, LImageRect, AMark.ImageIndex);
      end;
  end;

  var
    LLineRect: TRectF;
    LLine, LPreviousLine, LCompareLine: Integer;

  procedure PaintLineNumbers;
  var
    LLastTextLine, LCaretY: Integer;
    LCompareMode, LCompareEmptyLine: Boolean;
    LLongLineWidth: Single;
    LLineNumber: string;
    LCenterX, LCenterY, LScale: Single;
    LMarkWidth, LMarkHeight: Single;
    LMarkRect: TRectF;
    LBackground: TAlphaColor;
    LDrawLine: Boolean;
    LMargin: Integer;

    function Snap(const AValue: Single): Single;
    begin
      Result := Round(AValue * LScale) / LScale;
    end;

  begin
    LScale := 1;

    if Assigned(Scene) then
      LScale := Scene.GetSceneScale;

    if LScale <= 0 then
      LScale := 1;

    FPaintHelper.SetBaseFont(FFonts.LineNumbers);
    try
      LLineRect := AClipRect;

      LLastTextLine := ALastTextLine;

      if lnoAfterLastLine in FLeftMargin.LineNumbers.Options then
        LLastTextLine := ALastLine;

      LCaretY := FPosition.Text.Line + 1;
      LCompareMode := lnoCompareMode in FLeftMargin.LineNumbers.Options;
      LCompareEmptyLine := False;
      LLongLineWidth := FLeftMarginCharWidth * 0.75; { Delphi IDE dash is about 3/4 of a digit wide }
      LMargin := if IsCodeFoldingVisible then 0 else 2;

      for var LIndex := AFirstLine to LLastTextLine do
      begin
        LLine := GetViewTextLineNumber(LIndex);

        if LCompareMode and (FLines.Count > 0) then
          LCompareEmptyLine := sfEmptyLine in FLines.Flags[LIndex - 1];

        LLineRect.Top := (LIndex - TopLine) * LLineHeight;

        if IsRulerVisible then
          LLineRect.Top := LLineRect.Top + FRuler.Height;

        LLineRect.Bottom := LLineRect.Top + LLineHeight;
        LLineNumber := '';

        FPaintHelper.SetBackgroundColor(FColors.LeftMarginBackground);

        if FActiveLine.Visible and (not Assigned(FMultiEdit.Carets) and (LLine = LCaretY) or
          Assigned(FMultiEdit.Carets) and IsMultiEditCaretFound(LLine)) and (FColors.LeftMarginActiveLineBackground <> TAlphaColors.Null) then
        begin
          if Focused then
            Canvas.Fill.Color := FColors.LeftMarginActiveLineBackground
          else
            Canvas.Fill.Color := FColors.LeftMarginActiveLineBackgroundUnfocused;

          FillRect(LLineRect);
        end
        else
        begin
          LBackground := GetMarkBackgroundColor(LIndex);

          if LBackground <> TAlphaColors.Null then
          begin
            Canvas.Fill.Color := LBackground;
            FillRect(LLineRect);
          end;
        end;

        if FActiveLine.Visible and (LLine = LCaretY) and (FColors.ActiveLineForeground <> TAlphaColors.Null) then
        begin
          if Focused then
          begin
            if FColors.LeftMarginActiveLineNumber = TAlphaColors.Null then
              FPaintHelper.SetForegroundColor(FColors.ActiveLineForeground)
            else
              FPaintHelper.SetForegroundColor(FColors.LeftMarginActiveLineNumber)
          end
          else
            FPaintHelper.SetForegroundColor(FColors.ActiveLineForegroundUnfocused)
        end
        else
        if (LLine = LCaretY) and (FColors.LeftMarginActiveLineNumber <> TAlphaColors.Null) then
          FPaintHelper.SetForegroundColor(FColors.LeftMarginActiveLineNumber)
        else
          FPaintHelper.SetForegroundColor(FColors.LeftMarginLineNumbers);

        LPreviousLine := LLine;

        if FWordWrap.Active then
          LPreviousLine := GetViewTextLineNumber(LIndex - 1);

        if FLeftMargin.LineNumbers.Visible and not FWordWrap.Active and not LCompareEmptyLine or FWordWrap.Active and (LPreviousLine <> LLine) then
        begin
          LLineNumber := FLeftMargin.FormatLineNumber(LLine);

          if (LCaretY <> LLine) and (lnoIntens in LeftMargin.LineNumbers.Options) and (LLineNumber[LLineNumber.Length] <> '0') and (LIndex <> LeftMargin.LineNumbers.StartFrom) then
          begin
            LCenterX := AClipRect.Right - 7 - LMargin - (FLeftMarginCharWidth / 2) + 0.5;
            LCenterY := LLineRect.Top + (LLineHeight / 2);

            if LLine mod 5 = 0 then
            begin
              LMarkWidth := Snap(LLongLineWidth);
              LMarkHeight := Snap(Max(2, FLeftMarginCharWidth / 4));
            end
            else
            begin
              LMarkWidth := Snap(Max(2, FLeftMarginCharWidth * 0.3));
              LMarkHeight := LMarkWidth;
            end;

            LMarkRect.Left := Snap(LCenterX - (LMarkWidth / 2)) + 1;
            LMarkRect.Top := Snap(LCenterY - (LMarkHeight / 2));
            LMarkRect.Right := LMarkRect.Left + LMarkWidth;
            LMarkRect.Bottom := LMarkRect.Top + LMarkHeight;

            Canvas.Fill.Kind := TBrushKind.Solid;
            Canvas.Fill.Color := FColors.LeftMarginLineNumberLine;

            LDrawLine := LLine mod 5 = 0;

            if LDrawLine or (LMarkWidth * LScale < 4) then
            begin
              if LDrawLine then
                LMarkRect.Top := LMarkRect.Top + 1;

              FillRect(LMarkRect);
            end
            else
              Canvas.FillEllipse(LMarkRect, 1);

            Continue;
          end;
        end;

        if not FLeftMargin.LineNumbers.Visible or LCompareEmptyLine then
          LLineNumber := ''
        else
        if LCompareMode then
        begin
          LCompareLine := if LIndex < Length(FCompareLineNumberOffsetCache) then FCompareLineNumberOffsetCache[LIndex] else 0;
          LLineNumber := FLeftMargin.FormatLineNumber(LLine - LCompareLine);
        end;

        Canvas.Fill.Color := FColors.LeftMarginLineNumbers;
        DrawText(RectF(AClipRect.Left, LLineRect.Top, AClipRect.Right - 6 - LMargin, LLineRect.Bottom), LLineNumber,
          TTextAlign.Trailing, TTextAlign.Center);
      end;

      FPaintHelper.SetBackgroundColor(FColors.LeftMarginBackground);
    finally
      FPaintHelper.SetBaseFont(FFonts.Text);
    end;
  end;

  procedure PaintBookmarkPanel;
  var
    LPanelActiveLineRect: TRectF;
    LIndex: Integer;

    procedure SetPanelActiveLineRect;
    var
      LTop: Single;
    begin
      LTop := (LIndex - TopLine) * LLineHeight;

      LPanelActiveLineRect := RectF(AClipRect.Left, LTop, AClipRect.Left + FLeftMargin.MarksPanel.Width, LTop + LLineHeight);

      if IsRulerVisible then
      begin
        LPanelActiveLineRect.Top := LPanelActiveLineRect.Top + FRuler.Height;
        LPanelActiveLineRect.Bottom := LPanelActiveLineRect.Bottom + FRuler.Height;
      end;
    end;

  var
    LOldColor: TAlphaColor;
    LPanelRect: TRectF;
    LBackground: TAlphaColor;
  begin
    LOldColor := Canvas.Fill.Color;

    if FLeftMargin.MarksPanel.Visible then
    begin
      LPanelRect := RectF(AClipRect.Left, 0, AClipRect.Left + FLeftMargin.MarksPanel.Width, ClientHeight);

      if IsRulerVisible then
        LPanelRect.Top := LPanelRect.Top + FRuler.Height;

      if FColors.LeftMarginBookmarkPanelBackground <> TAlphaColors.Null then
      begin
        Canvas.Fill.Color := FColors.LeftMarginBookmarkPanelBackground;
        FillRect(LPanelRect);
      end;

      for LIndex := AFirstLine to ALastTextLine do
      begin
        LLine := GetViewTextLineNumber(LIndex);

        if FActiveLine.Visible and (FColors.LeftMarginActiveLineBackground <> TAlphaColors.Null) and
          not Assigned(FMultiEdit.Carets) and (LLine = FPosition.Text.Line + 1) or
          Assigned(FMultiEdit.Carets) and IsMultiEditCaretFound(LLine) then
        begin
          SetPanelActiveLineRect;

          Canvas.Fill.Color := if Focused then FColors.LeftMarginActiveLineBackground else FColors.LeftMarginActiveLineBackgroundUnfocused;

          FillRect(LPanelActiveLineRect);
        end
        else
        begin
          LBackground := GetMarkBackgroundColor(LIndex);

          if LBackground <> TAlphaColors.Null then
          begin
            SetPanelActiveLineRect;
            Canvas.Fill.Color := LBackground;
            FillRect(LPanelActiveLineRect);
          end;
        end;
      end;

      if Assigned(FEvents.OnBeforeMarkPanelPaint) then
        FEvents.OnBeforeMarkPanelPaint(Self, Canvas, LPanelRect, AFirstLine, ALastLine);
    end;

    Canvas.Fill.Color := LOldColor;
  end;

  procedure PaintWordWrapIndicator;
  var
    LY: Single;
  begin
    if FWordWrap.Active and FWordWrap.Indicator.Visible then
    begin
      FWordWrap.Indicator.Color := FColors.WordWrapIndicatorArrow;

      for var LIndex := AFirstLine to ALastLine do
      begin
        LLine := GetViewTextLineNumber(LIndex);
        LPreviousLine := GetViewTextLineNumber(LIndex - 1);

        if LLine = LPreviousLine then
        begin
          LY := (LIndex - TopLine) * LLineHeight;

          if IsRulerVisible then
            LY := LY + FRuler.Height;

          FWordWrap.Indicator.Draw(Canvas, AClipRect.Left + FWordWrap.Indicator.Left, LY, LLineHeight);
        end;
      end;
    end;
  end;

  procedure PaintBorder;
  var
    LRightPosition: Single;
  begin
    LRightPosition := AClipRect.Left + FLeftMargin.GetWidth - 2;

    if (FLeftMargin.Border.Style <> mbsNone) and (AClipRect.Right >= LRightPosition) then
    with Canvas do
    begin
      Canvas.Stroke.Kind := TBrushKind.Solid;
      Canvas.Stroke.Color := FColors.LeftMarginBorder;
      Canvas.Stroke.Thickness := 1;

      if FLeftMargin.Border.Style = mbsMiddle then
      begin
        DrawPixelLine(LRightPosition, AClipRect.Top, LRightPosition, AClipRect.Bottom);

        Canvas.Stroke.Color := FColors.LeftMarginBackground;
      end;

      DrawPixelLine(LRightPosition + 1, AClipRect.Top, LRightPosition + 1, AClipRect.Bottom);
    end;
  end;

  procedure PaintMarks;
  var
    LOverlappingOffsets: PIntegerArray;
    LMark: TTextEditorMark;
    LMarkLine: Integer;
  begin
    if FLeftMargin.Bookmarks.Visible and FLeftMargin.Bookmarks.Visible and ((FBookmarkList.Count > 0) or (FMarkList.Count > 0)) and (ALastLine >= AFirstLine) then
    begin
      LOverlappingOffsets := AllocMem((ALastLine - AFirstLine + 1) * SizeOf(Integer));
      try
        for var LLine := AFirstLine to ALastLine do
        begin
          LMarkLine := GetViewTextLineNumber(LLine);

          { Bookmarks }
          for var LIndex := FBookmarkList.Count - 1 downto 0 do
          begin
            LMark := FBookmarkList.Items[LIndex];

            if LMark.Visible and (LMark.Line + 1 = LMarkLine) then
              DrawBookmark(LMark, LOverlappingOffsets[ALastLine - LLine], LMarkLine);
          end;

          { Custom marks }
          for var LIndex := FMarkList.Count - 1 downto 0 do
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
    LY: Single;
  begin
    if FActiveLine.Visible and FActiveLine.Indicator.Visible then
    begin
      if not ReadOnly and FSyncEdit.Active and not FSyncEdit.Visible and FSyncEdit.Activator.Visible and
        GetSelectionAvailable and (TextToViewPosition(SelectionEndPosition).Row = FViewPosition.Row) then
        Exit;

      LY := (FViewPosition.Row - TopLine) * LLineHeight;

      if IsRulerVisible then
        LY := LY + FRuler.Height;

      FActiveLine.Indicator.Draw(Canvas, AClipRect.Left + FActiveLine.Indicator.Left, LY, LLineHeight);
    end;
  end;

  procedure PaintSyncEditIndicator;
  var
    LViewPosition: TTextEditorViewPosition;
    LY: Single;
  begin
    if not ReadOnly and FSyncEdit.Active and not FSyncEdit.Visible and FSyncEdit.Activator.Visible and GetSelectionAvailable then
    begin
      LViewPosition := TextToViewPosition(SelectionEndPosition);
      LY := (LViewPosition.Row - TopLine) * LLineHeight;

      if IsRulerVisible then
        LY := LY + FRuler.Height;

      FSyncEdit.Activator.Draw(Canvas, AClipRect.Left + FActiveLine.Indicator.Left, LY, LLineHeight);
    end;
  end;

  procedure PaintLineState;
  var
    LOldColor: TAlphaColor;
    LLineStateRect: TRectF;
    LTextLine: Integer;
    LLineState: TTextEditorLineState;
    LRightOffset: Integer;
  begin
    if FLeftMargin.LineState.Visible then
    begin
      LOldColor := Canvas.Fill.Color;

      if FLeftMargin.LineState.Align = lsLeft then
      begin
        LLineStateRect.Left := FLeftMargin.LineState.Offset;
        LLineStateRect.Right := FLeftMargin.LineState.Width + FLeftMargin.LineState.Offset;
      end
      else
      begin
        LRightOffset := if IsCodeFoldingVisible then 1 else 3;

        LLineStateRect.Left := AClipRect.Right - FLeftMargin.LineState.Width - LRightOffset;
        LLineStateRect.Right := AClipRect.Right - LRightOffset;
      end;

      for var LLine := AFirstLine to ALastTextLine do
      begin
        LTextLine := GetViewTextLineNumber(LLine);
        LLineState := FLines.LineState[LTextLine - 1];

        if FLeftMargin.LineState.ShowOnlyModified and (LLineState = lsModified) or not FLeftMargin.LineState.ShowOnlyModified and (LLineState <> lsNone) then
        begin
          LLineStateRect.Top := (LLine - TopLine) * LLineHeight;

          if IsRulerVisible then
            LLineStateRect.Top := LLineStateRect.Top + FRuler.Height;

          LLineStateRect.Bottom := LLineStateRect.Top + LLineHeight;

          Canvas.Fill.Color := if LLineState = lsNormal then FColors.LeftMarginLineStateNormal else FColors.LeftMarginLineStateModified;

          FillRect(LLineStateRect);
        end;
      end;

      Canvas.Fill.Color := LOldColor;
    end;
  end;

  procedure PaintBookmarkPanelLine;
  var
    LPanelRect: TRectF;
    LTextLine: Integer;
  begin
    if FLeftMargin.MarksPanel.Visible then
    begin
      if Assigned(FEvents.OnMarkPanelLinePaint) then
      begin
        LPanelRect.Left := AClipRect.Left;

        if IsRulerVisible then
          LPanelRect.Top := FRuler.Height;

        LPanelRect.Right := FLeftMargin.MarksPanel.Width;
        LPanelRect.Bottom := AClipRect.Bottom;

        for var LLine := AFirstLine to ALastLine do
        begin
          LTextLine := LLine;

          if IsCodeFoldingVisible then
            LTextLine := GetViewTextLineNumber(LLine);

          LLineRect.Left := LPanelRect.Left;
          LLineRect.Right := LPanelRect.Right;
          LLineRect.Top := (LLine - TopLine) * LLineHeight;

          if IsRulerVisible then
            LLineRect.Top := LLineRect.Top + FRuler.Height;

          LLineRect.Bottom := LLineRect.Top + LLineHeight;
          FEvents.OnMarkPanelLinePaint(Self, Canvas, LLineRect, LTextLine);
        end;
      end;

      if Assigned(FEvents.OnAfterMarkPanelPaint) then
        FEvents.OnAfterMarkPanelPaint(Self, Canvas, LPanelRect, AFirstLine, ALastLine);
    end;
  end;

begin
  if AClipRect.Right <= AClipRect.Left then
    Exit;

  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := FColors.LeftMarginBackground;
  Canvas.FillRect(RectF(AClipRect.Left, AClipRect.Top, AClipRect.Right, AClipRect.Bottom), 0, 0, [], 1);

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

procedure TCustomTextEditor.PaintMinimap(const AClipRect: TRectF; const AFirstLine, ALastLine: Integer);
var
  LRow, LTextLine, LIndex: Integer;
  LCharWidth, LCharHeight, LTop, LLeft: Single;
  LRowRect: TRectF;
  LSelectionStartPosition, LSelectionEndPosition: TTextEditorTextPosition;
  LSearchItem: TTextEditorSearchItem;
  LShowBookmarks: Boolean;
  LMaxColumns: Integer;

  procedure PaintRowBars(const AText: string; const ATop: Single);
  var
    LColumn, LRunStartColumn: Integer;
    LBottom: Single;

    procedure PaintRun;
    begin
      if LRunStartColumn >= 0 then
        Canvas.FillRect(RectF(LLeft + LRunStartColumn * LCharWidth, ATop, Min(LLeft + LColumn * LCharWidth, AClipRect.Right - 2), LBottom), 0, 0, [], 1);

      LRunStartColumn := -1;
    end;

  begin
    LBottom := ATop + Max(LCharHeight - 1, 1);
    LColumn := 0;
    LRunStartColumn := -1;

    for var LCharIndex := 1 to AText.Length do
    begin
      case AText[LCharIndex] of
        TControlCharacters.Tab:
          begin
            PaintRun;
            LColumn := (LColumn div FTabs.Width + 1) * FTabs.Width;
          end;
        TCharacters.Space:
          begin
            PaintRun;
            Inc(LColumn);
          end;
      else
        if LRunStartColumn < 0 then
          LRunStartColumn := LColumn;

        Inc(LColumn);
      end;

      if LColumn > LMaxColumns then
        Break;
    end;

    PaintRun;
  end;

begin
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := if FColors.MinimapBackground <> TAlphaColors.Null then FColors.MinimapBackground else FColors.EditorBackground;
  Canvas.FillRect(AClipRect, 0, 0, [], 1);

  LCharWidth := Max(FPaintHelper.CharWidth, 0.5);
  LCharHeight := Max(FMinimap.CharHeight, 1);
  LLeft := AClipRect.Left + 2;
  LMaxColumns := Trunc((AClipRect.Width - 4) / LCharWidth);
  LShowBookmarks := (moShowBookmarks in FMinimap.Options) and (FBookmarkList.Count > 0);

  if not (ioUseBlending in FMinimap.Indicator.Options) and (FColors.MinimapVisibleRows <> TAlphaColors.Null) then
  begin
    LTop := AClipRect.Top + (FLineNumbers.TopLine - AFirstLine) * LCharHeight;

    Canvas.Fill.Color := FColors.MinimapVisibleRows;
    Canvas.FillRect(RectF(AClipRect.Left, LTop, AClipRect.Right, LTop + FLineNumbers.VisibleCount * LCharHeight), 0, 0, [], 1);
  end;

  if GetSelectionAvailable then
  begin
    LSelectionStartPosition := GetSelectionStartPosition;
    LSelectionEndPosition := GetSelectionEndPosition;

    LTop := AClipRect.Top + (LSelectionStartPosition.Line + 1 - AFirstLine) * LCharHeight;

    Canvas.Fill.Color := if Focused then FColors.SelectionBackground else FColors.SelectionBackgroundUnfocused;
    Canvas.FillRect(RectF(AClipRect.Left, Max(LTop, AClipRect.Top), AClipRect.Right,
      Min(AClipRect.Top + (LSelectionEndPosition.Line + 2 - AFirstLine) * LCharHeight, AClipRect.Bottom)), 0, 0, [], 1);
  end;

  for LRow := AFirstLine to ALastLine do
  begin
    LTextLine := GetViewTextLineNumber(LRow);
    LTop := AClipRect.Top + (LRow - AFirstLine) * LCharHeight;

    if LShowBookmarks then
    for LIndex := 0 to FBookmarkList.Count - 1 do
    if FBookmarkList.Items[LIndex].Line = LTextLine - 1 then
    begin
      LRowRect := RectF(AClipRect.Left, LTop, AClipRect.Right, LTop + LCharHeight);

      Canvas.Fill.Color := FColors.MinimapBookmark;
      Canvas.FillRect(LRowRect, 0, 0, [], 1);

      Break;
    end;

    Canvas.Fill.Color := FColors.EditorForeground;

    PaintRowBars(FLines[LTextLine - 1], LTop);
  end;

  if (FSearch.Items.Count > 0) and (FColors.SearchHighlighterBackground <> TAlphaColors.Null) then
  begin
    Canvas.Fill.Color := FColors.SearchHighlighterBackground;

    for LIndex := 0 to FSearch.Items.Count - 1 do
    begin
      LSearchItem := PTextEditorSearchItem(FSearch.Items.Items[LIndex])^;

      if LSearchItem.BeginTextPosition.Line + 1 > ALastLine then
        Break;

      if LSearchItem.BeginTextPosition.Line + 1 >= AFirstLine then
      begin
        LTop := AClipRect.Top + (LSearchItem.BeginTextPosition.Line + 1 - AFirstLine) * LCharHeight;

        Canvas.FillRect(RectF(LLeft + (LSearchItem.BeginTextPosition.Char - 1) * LCharWidth, LTop,
          Min(LLeft + (LSearchItem.EndTextPosition.Char - 1) * LCharWidth, AClipRect.Right - 2), LTop + Max(LCharHeight - 1, 1)),
          0, 0, [], 0.8);
      end;
    end;
  end;
end;

procedure TCustomTextEditor.PaintMinimapIndicator(const AClipRect: TRectF);
var
  LAlpha: Single;
  LIndicatorBottom: Single;
  LIndicatorRect: TRectF;
  LIndicatorTop: Single;
begin
  if FColors.MinimapVisibleRows = TAlphaColors.Null then
    Exit;

  LAlpha := FMinimap.Indicator.AlphaBlending / High(Byte);
  LIndicatorTop := AClipRect.Top + (FLineNumbers.TopLine - Max(FMinimap.TopLine, 1)) * Max(FMinimap.CharHeight, 1);
  LIndicatorBottom := LIndicatorTop + FLineNumbers.VisibleCount * Max(FMinimap.CharHeight, 1);
  LIndicatorRect := RectF(AClipRect.Left, LIndicatorTop, AClipRect.Right, LIndicatorBottom);

  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := FColors.MinimapVisibleRows;

  if ioInvertBlending in FMinimap.Indicator.Options then
  begin
    if LIndicatorTop > AClipRect.Top then
      Canvas.FillRect(RectF(AClipRect.Left, AClipRect.Top, AClipRect.Right, LIndicatorTop), 0, 0, [], LAlpha);

    if LIndicatorBottom < AClipRect.Bottom then
      Canvas.FillRect(RectF(AClipRect.Left, LIndicatorBottom, AClipRect.Right, AClipRect.Bottom), 0, 0, [], LAlpha);
  end
  else
    Canvas.FillRect(LIndicatorRect, 0, 0, [], LAlpha);

  if ioShowBorder in FMinimap.Indicator.Options then
  begin
    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Color := FColors.MinimapVisibleRows;
    Canvas.DrawRect(LIndicatorRect, 0, 0, [], 1);
  end;
end;

procedure TCustomTextEditor.PaintMinimapShadow(const ACanvas: TCanvas; const AClipRect: TRectF);
var
  LAlpha: Single;
  LIndex: Integer;
  LLeft: Single;
  LWidth: Integer;
begin
  LWidth := Max(FMinimap.Shadow.Width, 1);
  LLeft := if FMinimap.Align = maLeft then AClipRect.Left else AClipRect.Right - LWidth;

  ACanvas.Fill.Kind := TBrushKind.Solid;
  ACanvas.Fill.Color := FMinimap.Shadow.Color;

  // TODO
  for LIndex := 0 to LWidth - 1 do
  begin
    LAlpha := Power(
      if FMinimap.Align = maLeft then
        (LWidth - LIndex) / LWidth
      else
        LIndex / LWidth,
      4) * (FMinimap.Shadow.AlphaBlending / High(Byte));

    ACanvas.FillRect(RectF(LLeft + LIndex, AClipRect.Top, LLeft + LIndex + 1, AClipRect.Bottom), 0, 0, [], LAlpha);
  end;
end;

procedure TCustomTextEditor.PaintMouseScrollPoint;
var
  LHalfWidth: Integer;
begin
  LHalfWidth := FScroll.Indicator.Width shr 1;

  FScroll.Indicator.Draw(Canvas, FMouse.ScrollingPoint.X - LHalfWidth, FMouse.ScrollingPoint.Y - LHalfWidth);
end;

procedure TCustomTextEditor.PaintProgress(Sender: TObject);
begin
  Repaint;
end;

procedure  TCustomTextEditor.PaintProgressBar;
var
  LRight: Single;
  LTop: Single;
begin
  LTop := ClientRect.Bottom - 14;
  LRight := Round((FLines.ProgressPosition / 100) * ClientRect.Width) - 8;

  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := FColors.LeftMarginLineNumbers;
  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Color := FColors.LeftMarginLineNumbers;
  Canvas.FillRect(RectF(4, LTop, LRight, LTop + 8), 0, 0, [], 1);
  Canvas.DrawRect(RectF(4, LTop, LRight, LTop + 8), 0, 0, [], 1);
end;

procedure TCustomTextEditor.PaintRuler;
var
  LCharWidth: Single;
  LCharsBeforeView: Integer;
  LLeft: Single;
  LLineY: Single;
  LLongLineY: Single;
  LNumbers: string;
  LRulerCaretPosition: Single;
  LShortLineY: Single;
  LTextWidth: Single;
begin
  LCharWidth := Max(FPaintHelper.CharWidth, 1);
  LRulerCaretPosition := FLeftMarginWidth + (FViewPosition.Column - 1) * LCharWidth - FScrollHelper.HorizontalPosition;

  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := FColors.RulerBackground;
  Canvas.FillRect(RectF(0, 0, Width, FRuler.Height), 0, 0, [], 1);

  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Color := FColors.RulerBorder;
  DrawPixelLine(0, FRuler.Height - 1, Width, FRuler.Height - 1);

  Canvas.Font.Assign(FFonts.Ruler);

  if (roShowSelection in FRuler.Options) and SelectionAvailable then
  begin
    LLeft := FLeftMarginWidth + (FPosition.SelectionStart.Char - 1) * LCharWidth - FScrollHelper.HorizontalPosition;
    Canvas.Fill.Color := FColors.RulerSelection;
    Canvas.FillRect(RectF(LLeft, 0, LRulerCaretPosition, FRuler.Height - 1), 0, 0, [], 1);
    Canvas.Stroke.Color := FColors.SelectionBackground;
    DrawPixelLine(LLeft, 0, LLeft, FRuler.Height - 1);
  end;

  LLeft := FLeftMarginWidth {- FScrollHelper.HorizontalPosition mod LCharWidth}; // TODO
  LLongLineY := FRuler.Height - 5;
  LShortLineY := FRuler.Height - 3;
  LCharsBeforeView := Round(FScrollHelper.HorizontalPosition / LCharWidth);
  Canvas.Stroke.Color := FColors.RulerLines;

  for var LIndex := LCharsBeforeView to FScrollHelper.PageWidth div Round(LCharWidth) + LCharsBeforeView + 10 do
  begin
    if LIndex mod 10 = 0 then
    begin
      LLineY := LLongLineY;
      LNumbers := LIndex.ToString;
      Canvas.Fill.Color := FColors.RulerNumbers;
      LTextWidth := FMX.TextEditor.Utils.TextWidth(Canvas, LNumbers);
      Canvas.FillText(RectF(LLeft - LTextWidth / 2, 0, LLeft + LTextWidth / 2, FRuler.Height - 5), LNumbers,
        False, 1, [], TTextAlign.Center, TTextAlign.Leading);
    end
    else
      LLineY := LShortLineY;

    DrawPixelLine(LLeft, LLineY, LLeft, FRuler.Height - 1);
    LLeft := LLeft + LCharWidth;
  end;

  DrawPixelLine(LRulerCaretPosition, 0, LRulerCaretPosition, FRuler.Height - 1);
  Canvas.Font.Assign(FFonts.Text);
end;

procedure TCustomTextEditor.PaintRightMargin(const AClipRect: TRectF);
var
  LRightMarginPosition: Single;
begin
  if FRightMargin.Visible then
  begin
    LRightMarginPosition := FLeftMarginWidth + FRightMargin.Position * FPaintHelper.CharWidth - FScrollHelper.HorizontalPosition;

    if (LRightMarginPosition >= AClipRect.Left) and (LRightMarginPosition <= AClipRect.Right) then
    begin
      Canvas.Stroke.Kind := TBrushKind.Solid;
      Canvas.Stroke.Color := FColors.RightMargin;
      DrawPixelLine(LRightMarginPosition, AClipRect.Top, LRightMarginPosition, AClipRect.Bottom);
    end;
  end;
end;

procedure TCustomTextEditor.PaintRightMarginMove;
var
  LY: Single;
begin
  LY := 0;

  if IsRulerVisible then
    LY := FRuler.Height;

  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Dash := TStrokeDash.Dot;
  Canvas.Stroke.Color := FColors.RightMovingEdge;
  DrawPixelLine(FRightMarginMovePosition, LY, FRightMarginMovePosition, ClientHeight);
  Canvas.Stroke.Dash := TStrokeDash.Solid;
end;

procedure TCustomTextEditor.PaintRulerMove;
var
  LY: Single;
begin
  LY := 0;

  if IsRulerVisible then
    LY := FRuler.Height;

  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Dash := TStrokeDash.Dot;
  Canvas.Stroke.Color := FColors.RulerMovingEdge;
  DrawPixelLine(FRulerMovePosition, LY, FRulerMovePosition, ClientHeight);
  Canvas.Stroke.Dash := TStrokeDash.Solid;
end;

procedure TCustomTextEditor.PaintHint(const AHint: string; const ATop: Single);
const
  LMargin = 4.0;
  LPadding = 3.0;
var
  LHeight: Single;
  LRect: TRectF;
  LWidth: Single;
begin
  Canvas.Font.Assign(FFonts.Hint);

  LWidth := FMX.TextEditor.Utils.TextWidth(Canvas, AHint) + 2 * LPadding + 2;
  LHeight := FMX.TextEditor.Utils.TextHeight(Canvas, AHint) + 2 * LPadding;

  LRect.Left := Max(0.0, ClientWidth - LWidth - LMargin);
  LRect.Right := LRect.Left + LWidth;
  LRect.Top := ATop;
  LRect.Bottom := LRect.Top + LHeight;

  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := FColors.HintBackground;
  Canvas.FillRect(LRect, 0, 0, [], 1);

  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Color := FColors.HintBorder;
  Canvas.DrawRect(RectF(LRect.Left + 0.5, LRect.Top + 0.5, LRect.Right - 0.5, LRect.Bottom - 0.5), 0, 0, [], 1);

  Canvas.Fill.Color := FColors.HintText;
  Canvas.FillText(RectF(LRect.Left + LPadding, LRect.Top + LPadding, LRect.Right - LPadding, LRect.Bottom - LPadding),
    AHint, False, 1, [], TTextAlign.Center, TTextAlign.Center);

  Canvas.Font.Assign(FFonts.Text);
end;

procedure TCustomTextEditor.PaintRightMarginMoveHint;
const
  LMargin = 4.0;
begin
  PaintHint(Format(STextEditorRightMarginPosition,
    [Round((FRightMarginMovePosition - FLeftMarginWidth + FScrollHelper.HorizontalPosition) / FPaintHelper.CharWidth)]),
    LMargin);
end;

procedure TCustomTextEditor.PaintRulerMoveHint;
const
  LMargin = 4.0;
begin
  PaintHint(Format(STextEditorRightMarginPosition,
    [Round((FRulerMovePosition - FLeftMarginWidth + FScrollHelper.HorizontalPosition) / FPaintHelper.CharWidth)]),
    FRuler.Height + LMargin);
end;

procedure TCustomTextEditor.PaintScrollHint;
const
  LMargin = 4.0;
  LPadding = 3.0;
var
  LHeight: Single;
  LHint: string;
  LMaxTop: Single;
  LThumb: TThumb;
  LThumbTop: Single;
  LTop: Single;
begin
  LHint :=
    if FScroll.Hint.Format = shfTopLineOnly then
      Format(STextEditorScrollInfoTopLine, [TopLine])
    else
      Format(STextEditorScrollInfo, [TopLine, TopLine + Min(FLineNumbers.VisibleCount, FLineNumbers.Count - TopLine)]);

  LTop := LMargin;

  if soHintFollows in FScroll.Options then
  begin
    LThumb := GetVerticalScrollBarThumb;

    if Assigned(LThumb) then
    begin
      Canvas.Font.Assign(FFonts.Hint);
      LHeight := FMX.TextEditor.Utils.TextHeight(Canvas, LHint) + 2 * LPadding;
      LThumbTop := AbsoluteToLocal(LThumb.LocalToAbsolute(TPointF.Zero)).Y + (LThumb.Height - LHeight) / 2;
      LMaxTop := Max(LMargin, ClientHeight - LHeight - LMargin);
      LTop := Min(Max(LThumbTop, LMargin), LMaxTop);
    end;
  end;

  PaintHint(LHint, LTop);
end;

procedure TCustomTextEditor.PaintScrollShadow(const ACanvas: TCanvas; const AClipRect: TRectF);
var
  LAlpha: Single;
  LIndex: Integer;
  LWidth: Integer;
begin
  LWidth := Max(FScroll.Shadow.Width, 1);

  ACanvas.Fill.Kind := TBrushKind.Solid;
  ACanvas.Fill.Color := FScroll.Shadow.Color;

  for LIndex := 0 to LWidth - 1 do
  begin
    LAlpha := Power((LWidth - LIndex) / LWidth, 4) * (FScroll.Shadow.AlphaBlending / High(Byte));
    ACanvas.FillRect(RectF(AClipRect.Left + LIndex, AClipRect.Top, AClipRect.Left + LIndex + 1, AClipRect.Bottom),
      0, 0, [], LAlpha);
  end;
end;

procedure TCustomTextEditor.PaintSearchMap(const AClipRect: TRectF);
var
  LHeight: Single;
  LLine: Single;
  LRect: TRectF;
begin
  if not Assigned(FSearch.Items) or not Assigned(FSearchEngine) or (FSearchEngine.ResultCount = 0) and not (soHighlightSimilarTerms in FSelection.Options) then
    Exit;

  LRect := RectF(AClipRect.Left, AClipRect.Top, AClipRect.Right, AClipRect.Bottom);
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := if FColors.SearchMapBackground <> TAlphaColors.Null then FColors.SearchMapBackground else FColors.EditorBackground;
  Canvas.FillRect(LRect, 0, 0, [], 1);

  LHeight := Max(1, AClipRect.Height) / Max(FLines.Count, 1);
  LRect.Top := AClipRect.Top + (TopLine - 1) * LHeight;
  LRect.Bottom := Max(AClipRect.Top + (TopLine - 1 + FLineNumbers.VisibleCount) * LHeight, LRect.Top + 1);

  Canvas.Fill.Color := FColors.EditorBackground;
  Canvas.FillRect(LRect, 0, 0, [], 1);

  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Color := if FColors.SearchMapForeground <> TAlphaColors.Null then FColors.SearchMapForeground else TDefaultColors.SysHighlight;

  for var LIndex := 0 to FSearch.Items.Count - 1 do
  begin
    LLine := AClipRect.Top + PTextEditorSearchItem(FSearch.Items.Items[LIndex])^.BeginTextPosition.Line * LHeight;
    DrawPixelLine(AClipRect.Left, LLine, AClipRect.Right, LLine);
    DrawPixelLine(AClipRect.Left, LLine + 1, AClipRect.Right, LLine + 1);
  end;

  if moShowActiveLine in FSearch.Map.Options then
  begin
    Canvas.Stroke.Color := if FColors.SearchMapActiveLine <> TAlphaColors.Null then FColors.SearchMapActiveLine else FColors.ActiveLineBackground;
    LLine := AClipRect.Top + (FViewPosition.Row - 1) * LHeight;
    DrawPixelLine(AClipRect.Left, LLine, AClipRect.Right, LLine);
    DrawPixelLine(AClipRect.Left, LLine + 1, AClipRect.Right, LLine + 1);
  end;
end;

procedure TCustomTextEditor.SetOppositeColors;
begin
  FPaintHelper.SetBackgroundColor(Colors.EditorForeground);
  FPaintHelper.SetForegroundColor(Colors.EditorBackground);
  FPaintHelper.SetStyle([]);
end;

procedure TCustomTextEditor.PaintSpecialCharsEndOfLine(const ALine: Integer; const ALineEndRect: TRectF; const ALineEndInsideSelection: Boolean);
var
  LPenColor: TAlphaColor;
  LCharRect: TRectF;
  LPilcrow: string;
  LY: Single;

  procedure DrawPixelLine(const AX1, AY1, AX2, AY2: Single);
  begin
    Self.DrawPixelLine(AX1, AY1, AX2, AY2);
  end;

begin
  if FSpecialChars.Visible then
  begin
    if (ALineEndRect.Left < 0) or (ALineEndRect.Left > Round(Width)) then
      Exit;

    if ALineEndInsideSelection and (FSpecialChars.Selection.Visible or (FSearch.Items.Count > 0)) or
      not ALineEndInsideSelection and not (scoShowOnlyInSelection in FSpecialChars.Options) then
    begin
      if FSpecialChars.Selection.Visible and ALineEndInsideSelection then
        LPenColor := FSpecialChars.Selection.Color
      else
      if FSpecialChars.LineBreak.Color <> TAlphaColors.Null then
        LPenColor := FSpecialChars.LineBreak.Color
      else
      if scoMiddleColor in FSpecialChars.Options then
        LPenColor := MiddleColor(FHighlighter.MainRules.Attribute.Background, FHighlighter.MainRules.Attribute.Foreground)
      else
        LPenColor := if scoTextColor in FSpecialChars.Options then FHighlighter.MainRules.Attribute.Foreground else FSpecialChars.Color;

      Canvas.Stroke.Kind := TBrushKind.Solid;
      Canvas.Stroke.Color := LPenColor;
      Canvas.Fill.Kind := TBrushKind.Solid;
      Canvas.Fill.Color := LPenColor;

      if FSpecialChars.LineBreak.Visible and ((eoTrailingLineBreak in FOptions) or (ALine < FLines.Count)) then
      begin
        LCharRect.Top := ALineEndRect.Top;

        LCharRect.Bottom :=
          if (FSpecialChars.LineBreak.Style = eolPilcrow) or (FSpecialChars.LineBreak.Style = eolCRLF) then
            ALineEndRect.Bottom
          else
            ALineEndRect.Bottom - 3;

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

        case FSpecialChars.LineBreak.Style of
          eolCRLF:
            begin
              LPilcrow := '';

              with FLines.Items^[ALine - 1] do
              begin
                if sfLineBreakCR in Flags then
                  LPilcrow := TControlCharacterNames.CarriageReturn;

                if sfLineBreakLF in Flags then
                  LPilcrow := LPilcrow + TControlCharacterNames.LineFeed;
              end;

              if LPilcrow.IsEmpty then
              begin
                if FLines.LineBreak = lbCRLF then
                  LPilcrow := TControlCharacterNames.CarriageReturn + TControlCharacterNames.LineFeed
                else
                  LPilcrow := if FLines.LineBreak = lbLF then TControlCharacterNames.LineFeed else TControlCharacterNames.CarriageReturn;
              end;

              LCharRect.Right := LCharRect.Left + FPaintHelper.CharWidth * LPilcrow.Length + 2;
              LCharRect.Top := LCharRect.Top + 2;
              LCharRect.Bottom := LCharRect.Bottom - 2;
              Canvas.FillText(LCharRect, LPilcrow, False, 1, [], TTextAlign.Leading, TTextAlign.Leading);
            end;
          eolPilcrow:
            Canvas.FillText(LCharRect, TCharacters.Pilcrow, False, 1, [], TTextAlign.Leading, TTextAlign.Leading);
          eolArrow:
            begin
              LY := LCharRect.Top + 2;

              if FSpecialChars.Style = scsDot then
              begin
                while LY < LCharRect.Bottom - 2 do
                begin
                  DrawPixelLine(LCharRect.Left + 6, LY, LCharRect.Left + 6, LY + 1);
                  LY := LY + 4;
                end;
                LY := LCharRect.Bottom;
              end;

              if FSpecialChars.Style = scsSolid then
              begin
                DrawPixelLine(LCharRect.Left + 6, LY, LCharRect.Left + 6, LCharRect.Bottom + 1);
                LY := LCharRect.Bottom;
              end;

              DrawPixelLine(LCharRect.Left + 6, LY, LCharRect.Left + 3, LY - 3);
              DrawPixelLine(LCharRect.Left + 6, LY, LCharRect.Left + 9, LY - 3);
            end;
        else
          LY := LCharRect.Top + GetLineHeight / 2;

          DrawPixelLine(LCharRect.Left, LY, LCharRect.Left + 11, LY);
          DrawPixelLine(LCharRect.Left + 1, LY - 1, LCharRect.Left + 1, LY + 2);
          DrawPixelLine(LCharRect.Left + 2, LY - 2, LCharRect.Left + 2, LY + 3);
          DrawPixelLine(LCharRect.Left + 3, LY - 3, LCharRect.Left + 3, LY + 4);
          DrawPixelLine(LCharRect.Left + 10, LY - 3, LCharRect.Left + 10, LY);
        end;
      end;
    end;
  end;
end;

procedure TCustomTextEditor.PaintSyncItems;
var
  LLength: Integer;

  procedure DrawRectangle(const ATextPosition: TTextEditorTextPosition);
  var
    LRect: TRectF;
    LViewPosition: TTextEditorViewPosition;
  begin
    LRect.Top := (ATextPosition.Line - TopLine + 1) * LineHeight;

    if IsRulerVisible then
      LRect.Top := LRect.Top + FRuler.Height;

    LRect.Bottom := LRect.Top + LineHeight;

    LViewPosition := TextToViewPosition(ATextPosition);

    LRect.Left := ViewPositionToPixels(LViewPosition).X;
    Inc(LViewPosition.Column, LLength);
    LRect.Right := ViewPositionToPixels(LViewPosition).X;
    Canvas.DrawRect(RectF(LRect.Left, LRect.Top, LRect.Right, LRect.Bottom), 0, 0, [], 1);
  end;

var
  LTextPosition: TTextEditorTextPosition;
  LOldStrokeColor: TAlphaColor;
begin
  if not Assigned(FSyncEdit.SyncItems) then
    Exit;

  LLength := FSyncEdit.EditEndPosition.Char - FSyncEdit.EditBeginPosition.Char;

  LOldStrokeColor := Canvas.Stroke.Color;
  try
    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Thickness := 1;
    Canvas.Stroke.Color := FColors.SyncEditEditBorder;
    DrawRectangle(FSyncEdit.EditBeginPosition);

    for var LIndex := 0 to FSyncEdit.SyncItems.Count - 1 do
    begin
      LTextPosition := PTextEditorTextPosition(FSyncEdit.SyncItems.Items[LIndex])^;

      if LTextPosition.Line + 1 > TopLine + FLineNumbers.VisibleCount then
        Exit
      else
      if LTextPosition.Line + 1 >= TopLine then
      begin
        Canvas.Stroke.Color := FColors.SyncEditWordBorder;
        DrawRectangle(LTextPosition);
      end;
    end;
  finally
    Canvas.Stroke.Color := LOldStrokeColor;
  end;
end;

function TCustomTextEditor.GetFirstSearchIndex(const AMinimap: Boolean): Integer;
var
  LTextPosition: TTextEditorTextPosition;
begin
  Result := -1;

  if not AMinimap and Assigned(FSearch.Items) and (FSearch.Items.Count > 0) then
  begin
    Result := 0;

    while Result < FSearch.Items.Count do
    begin
      LTextPosition := PTextEditorSearchItem(FSearch.Items.Items[Result])^.EndTextPosition;

      if LTextPosition.Line + 1 >= FLineNumbers.TopLine then
        Break
      else
        Inc(Result);
    end;

    if Result = FSearch.Items.Count then
      Result := -1;
  end;
end;

procedure TCustomTextEditor.PaintTextLines(const AClipRect: TRectF; const AFirstLine, ALastLine: Integer; const AMinimap: Boolean);
var
  LCurrentLine: Integer;

  function IsBookmarkOnCurrentLine: Boolean;
  begin
    Result := True;

    for var LIndex := 0 to FBookmarkList.Count - 1 do
    if FBookmarkList.Items[LIndex].Line = LCurrentLine then
      Exit;

    Result := False;
  end;

var
  LBookmarkOnCurrentLine, LIsCurrentLine, LIsSyncEditBlock, LIsSearchInSelectionBlock: Boolean;
  LMarkColor: TAlphaColor;

  function GetBackgroundColor: TAlphaColor;
  var
    LHighlighterAttribute: TTextEditorHighlighterAttribute;
  begin
    if AMinimap and (moShowBookmarks in FMinimap.Options) and LBookmarkOnCurrentLine then
      Result := FColors.MinimapBookmark
    else
    if LIsCurrentLine and FActiveLine.Visible and Focused and (FColors.ActiveLineBackground <> TAlphaColors.Null) then
      Result := FColors.ActiveLineBackground
    else
    if LIsCurrentLine and FActiveLine.Visible and not Focused and (FColors.ActiveLineBackgroundUnfocused <> TAlphaColors.Null) then
      Result := FColors.ActiveLineBackgroundUnfocused
    else
    if LMarkColor <> TAlphaColors.Null then
      Result := LMarkColor
    else
    if LIsSyncEditBlock then
      Result := FColors.SyncEditBackground
    else
    if LIsSearchInSelectionBlock then
      Result := FColors.SearchInSelectionBackground
    else
    if AMinimap and (FColors.MinimapBackground <> TAlphaColors.Null) then
      Result := FColors.MinimapBackground
    else
    begin
      Result := FColors.EditorBackground;

      LHighlighterAttribute := FHighlighter.RangeAttribute;

      if Assigned(LHighlighterAttribute) and (LHighlighterAttribute.Background <> TAlphaColors.Null) then
        Result := LHighlighterAttribute.Background;
    end;
  end;

var
  LForegroundColor, LBackgroundColor: TAlphaColor;

  procedure SetDrawingColors(const ASelected: Boolean; const AFocused: Boolean = False);
  var
    LColor: TAlphaColor;
  begin
    { Selection colors }
    if AMinimap and (moShowBookmarks in FMinimap.Options) and LBookmarkOnCurrentLine then
      LColor := FColors.MinimapBookmark
    else
    if ASelected then
    begin
      FPaintHelper.SetForegroundColor(if FColors.SelectionForeground <> TAlphaColors.Null then FColors.SelectionForeground else LForegroundColor);

      LColor := if Focused or AFocused then FColors.SelectionBackground else FColors.SelectionBackgroundUnfocused
    end
    { Normal colors }
    else
    begin
      FPaintHelper.SetForegroundColor(LForegroundColor);
      LColor := LBackgroundColor;
    end;

    FPaintHelper.SetBackgroundColor(LColor); { Text }

    Canvas.Fill.Color := LColor; { Rest of the line }
  end;

  procedure PaintOpaqueText(const ARect: TRectF; const AText: string);
  begin
    Canvas.Fill.Color := FPaintHelper.BackgroundColor;
    FillRect(ARect);
    Canvas.Fill.Color := FPaintHelper.Color;
    DrawText(ARect, AText);
  end;

var
  LCurrentLineLength: Integer;
  LCurrentSearchIndex: Integer;
  LPaintedColumn: Integer;
  LTokenHelper: TTextEditorTokenHelper;

  procedure PaintSearchResults(const AText: string; const ATextRect: TRectF);
  var
    LSearchItem: TTextEditorSearchItem;

    function GetSearchTextLength: Integer;
    begin
      if (LCurrentLine = LSearchItem.BeginTextPosition.Line) and (LSearchItem.BeginTextPosition.Line = LSearchItem.EndTextPosition.Line) then
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

  var
    LOldColor, LOldBackgroundColor: TAlphaColor;
    LIsTextPositionInSelection: Boolean;
    LSearchTextLength, LCharCount, LBeginTextPositionChar, LLength: Integer;
    LToken: string;
    LSearchRect: TRectF;
  begin
    if (LCurrentSearchIndex <> -1) and (soHighlightResults in FSearch.Options) then
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

      if FColors.SearchHighlighterForeground <> TAlphaColors.Null then
        FPaintHelper.SetForegroundColor(FColors.SearchHighlighterForeground);

      FPaintHelper.SetBackgroundColor(FColors.SearchHighlighterBackground);

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

        if not FSearch.InSelection.Active and LIsTextPositionInSelection or FSearch.InSelection.Active and not LIsTextPositionInSelection then
        begin
          if not NextItem then
            Break;

          Continue;
        end;

        LToken := AText;
        LSearchRect := ATextRect;

        LBeginTextPositionChar := if LSearchItem.BeginTextPosition.Line < LCurrentLine then 1 else LSearchItem.BeginTextPosition.Char;
        LCharCount := LBeginTextPositionChar - LTokenHelper.CharsBefore - 1;

        if LCharCount > 0 then
        begin
          LToken := Copy(AText, 1, LCharCount);
          LSearchRect.Left := LSearchRect.Left + GetTokenWidth(LToken, LCharCount, LPaintedColumn, AMinimap);
          LToken := Copy(AText, LCharCount + 1, AText.Length);
        end
        else
          LCharCount := LTokenHelper.Length - AText.Length;

        LLength := LBeginTextPositionChar + LSearchTextLength;

        LToken := Copy(LToken, 1, Min(LSearchTextLength, LLength - LTokenHelper.CharsBefore - LCharCount - 1));
        LSearchRect.Right := LSearchRect.Left + GetTokenWidth(LToken, LToken.Length, LPaintedColumn, AMinimap);

        if SameText(AText, LToken) then
          LSearchRect.Right := LSearchRect.Right + FItalic.Offset;

        if not LToken.IsEmpty then
          PaintOpaqueText(LSearchRect, LToken);

        if LLength > LCurrentLineLength then
          Break
        else
        if LLength > LTokenHelper.CharsBefore + LToken.Length + LCharCount + 1 then
          Break
        else
        if LLength - 1 <= LCurrentLineLength then
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

var
  LAddWrappedCount: Boolean;
  LTokenRect, LSelectedRect: TRectF;

  procedure PaintToken(const AToken: string; const ATokenLength: Integer; const ASelectedRectPaint: Boolean = False);
  var
    LTokenLength: Integer;
    LTextRect: TRectF;

    procedure PaintControlCharacters;
    var
      LRect: TRectF;
      LCharWidth: Single;
      LName: string;
      LLength: Integer;
    begin
      if (LTokenLength = 0) or (AToken.Length = 0) then
        Exit;

      if FPaintHelper.BackgroundColor <> Colors.SelectionBackground then
        SetOppositeColors;

      LRect := LTokenRect;

      LRect.Left := LRect.Left + 1;
      LRect.Top := LRect.Top + 1;
      LRect.Bottom := LRect.Bottom - 1;

      LCharWidth := LTextRect.Width / LTokenLength;

      LRect.Right := LRect.Left + LCharWidth - 1;

      LName := ControlCharacterToName(AToken[1]);

      case AToken[1] of
        TControlCharacters.ZeroWidthSpace:
          LLength := LTokenLength div 2;
      else
        LLength := LTokenLength;
      end;

      for var LIndex := 0 to LLength - 1 do
      begin
        Canvas.Fill.Color := FPaintHelper.BackgroundColor;
        Canvas.FillRect(LRect, 0, 0, [], 1);
        Canvas.Fill.Color := FPaintHelper.Color;
        DrawText(RectF(LRect.Left + 1, LRect.Top - 1, LRect.Right, LRect.Bottom), LName);

        LRect.Left := LRect.Left + LCharWidth;
        LRect.Right := LRect.Left + LCharWidth - 1;
      end;
    end;

    procedure PaintSpecialCharSpace;
    var
      LSpaceWidth: Single;
      LRect: TRectF;
    begin
      if LTokenLength = 0 then
        Exit;

      LSpaceWidth := LTextRect.Width / LTokenLength;

      LRect.Top := LTokenRect.Top + LTokenRect.Height / 2;
      LRect.Bottom := LRect.Top + 2;
      LRect.Left := LTextRect.Left + LSpaceWidth / 2;

      Canvas.Fill.Color := Canvas.Stroke.Color;

      for var LIndex := 0 to LTokenLength - 1 do
      begin
        LRect.Right := LRect.Left + 2;

        Canvas.FillRect(LRect, 0, 0, [], 1);

        LRect.Left := LRect.Left + LSpaceWidth;
      end;
    end;

    procedure PaintSpecialCharSpaceTab;
    var
      LTabWidth: Single;
      LRect: TRectF;
      LLeft, LTop, LTopShr1: Single;
    begin
      LTabWidth := FTabs.Width * FPaintHelper.CharWidth;
      LRect := LTokenRect;

      LRect.Right := LTextRect.Left;

      LRect.Right := LRect.Right + LTabWidth;

      if FLines.Columns then
        LRect.Right := LRect.Right - FPaintHelper.CharWidth * (LTokenHelper.ExpandedCharsBefore mod FTabs.Width);

      while LRect.Right <= LTokenRect.Right do
      begin
        LTop := (LRect.Bottom - LRect.Top) / 2;

        { Line }
        if FSpecialChars.Style = scsDot then
        begin
          LLeft := LRect.Left + 1;

          //if Odd(LLeft) then TODO
          //  Inc(LLeft);

          while LLeft < LRect.Right - 2 do
          begin
            DrawPixelLine(LLeft, LRect.Top + LTop, LLeft + 1, LRect.Top + LTop);

            LLeft := LLeft + 2;
          end;
        end
        else
        if FSpecialChars.Style = scsSolid then
          DrawPixelLine(LRect.Left + 2, LRect.Top + LTop, LRect.Right - 2, LRect.Top + LTop);

        { Arrow }
        LLeft := LRect.Right - 2;
        LTopShr1 := LTop / 2;

        DrawPixelLine(LLeft, LRect.Top + LTop, LLeft - LTopShr1, LRect.Top + LTop - LTopShr1);
        DrawPixelLine(LLeft, LRect.Top + LTop, LLeft - LTopShr1, LRect.Top + LTop + LTopShr1);

        LRect.Left := LRect.Right;

        LRect.Right := LRect.Right + LTabWidth;
      end;
    end;

  var
    LText: string;
    LPChar: PChar;
    LCanvasState: TCanvasSaveState;
    LOldPenColor: TAlphaColor;
    LStep, LLeft: Single;
    LLastChar: Char;
    LAnsiChar: AnsiChar;
    LLastColumn: Integer;
  begin
    if not AMinimap and (LTokenRect.Right > FLeftMarginWidth) or AMinimap and
      ((FMinimap.Align = maRight) and (LTokenRect.Left < Width) or (FMinimap.Align = maLeft) and (LTokenRect.Left < FMinimap.Width)) then
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
        if LTokenHelper.Overhang and (LPChar^ <> TCharacters.Space) and (ATokenLength = AToken.Length) then
          LTextRect.Right := LTextRect.Right + FPaintHelper.CharWidth;

        if (FItalic.Offset <> 0) and (not LTokenHelper.Overhang or (LPChar^ = TCharacters.Space)) then
        begin
          LTextRect.Left := LTextRect.Left + FItalic.Offset;
          LTextRect.Right := LTextRect.Right + FItalic.Offset;

          if not LTokenHelper.Overhang then
            LTextRect.Left := LTextRect.Left - 1;

          if LPChar^ = TCharacters.Space then
            FItalic.Offset := 0;
        end;
      end;

      if LTokenHelper.EmptySpace in [esNull, esControlCharacter, esNonBreakingSpace, esZeroWidthSpace] then
      begin
        Canvas.Fill.Color := FPaintHelper.BackgroundColor;
        FillRect(LTextRect);
        PaintControlCharacters;
      end
      else
      if FSpecialChars.Visible and (LTokenHelper.EmptySpace <> TTextEditorEmptySpace.esNone) and (not (scoShowOnlyInSelection in FSpecialChars.Options) or
        (scoShowOnlyInSelection in FSpecialChars.Options) and (FPaintHelper.BackgroundColor = FColors.SelectionBackground)) and
        (not AMinimap or AMinimap and (moShowSpecialChars in FMinimap.Options)) then
      begin
        Canvas.Stroke.Color := if FSpecialChars.Selection.Visible and (FPaintHelper.BackgroundColor = FColors.SelectionBackground) then FSpecialChars.Selection.Color else LTokenHelper.Foreground;

        Canvas.Fill.Color := FPaintHelper.BackgroundColor;
        FillRect(LTextRect);

        if (FSpecialChars.Selection.Visible and (FPaintHelper.BackgroundColor = FColors.SelectionBackground) or (FPaintHelper.BackgroundColor <> FColors.SelectionBackground)) then
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
          LCanvasState := Canvas.SaveState;
          try
            Canvas.IntersectClipRect(LSelectedRect);
            PaintOpaqueText(LTextRect, Copy(LText, 1, LTokenLength));
          finally
            Canvas.RestoreState(LCanvasState);
          end;
        end
        else
          PaintOpaqueText(LTextRect, Copy(LText, 1, LTokenLength));

        if not AMinimap and LTokenHelper.Overhang and (LPChar^ <> TCharacters.Space) and (ATokenLength <> 0) and (ATokenLength = AToken.Length) then
        begin
          LLastChar := AToken[ATokenLength];
          LAnsiChar := TControlCharacters.Null;

          if Word(LLastChar) <= TCharacters.AnsiCharHigh then
            LAnsiChar := AnsiChar(LLastChar);

          if FItalic.OffsetCache[LAnsiChar] <> 0 then
            FItalic.Offset := FItalic.OffsetCache[LAnsiChar] - 1
          else
          begin
            FItalic.Offset := GetItalicOffset(LLastChar);

            if LAnsiChar <> TControlCharacters.Null then
              FItalic.OffsetCache[LAnsiChar] := Min(FItalic.Offset + 1, High(Byte));
          end;

          LLastColumn := LTokenHelper.CharsBefore + LTokenHelper.Text.Length + 1;

          if LLastColumn = LCurrentLineLength + 1 then
            LTokenRect.Right := LTokenRect.Right + FItalic.Offset;

          if LAddWrappedCount then
            LTokenRect.Right := LTokenRect.Right + FItalic.Offset;
        end;
      end;

      if LTokenHelper.Border <> TAlphaColors.Null then
      begin
        LOldPenColor := Canvas.Stroke.Color;

        Canvas.Stroke.Color := LTokenHelper.Border;
        DrawPixelLine(LTextRect.Left, LTextRect.Bottom - 1, LTokenRect.Right + FItalic.Offset - 1, LTextRect.Bottom - 1);
        DrawPixelLine(LTokenRect.Right + FItalic.Offset - 1, LTextRect.Bottom - 1, LTokenRect.Right + FItalic.Offset - 1, LTextRect.Top);
        DrawPixelLine(LTokenRect.Right + FItalic.Offset - 1, LTextRect.Top, LTextRect.Left, LTextRect.Top);
        DrawPixelLine(LTextRect.Left, LTextRect.Top, LTextRect.Left, LTextRect.Bottom - 1);

        Canvas.Stroke.Color := LOldPenColor;
      end;

      if LTokenHelper.Underline <> ulNone then
      begin
        LOldPenColor := Canvas.Stroke.Color;
        Canvas.Stroke.Color := LTokenHelper.UnderlineColor;

        case LTokenHelper.Underline of
          ulDoubleUnderline, ulUnderline:
            begin
              if LTokenHelper.Underline = ulDoubleUnderline then
                DrawPixelLine(LTextRect.Left, LTextRect.Bottom - 3, LTokenRect.Right, LTextRect.Bottom - 3);

              DrawPixelLine(LTextRect.Left, LTextRect.Bottom - 1, LTokenRect.Right, LTextRect.Bottom - 1);
            end;
          ulWavyZigzag:
            begin
              LStep := 0;

              while LStep < LTokenRect.Right - 4 do
              begin
                LLeft := LTextRect.Left + LStep;

                DrawPixelLine(LLeft, LTextRect.Bottom - 3, LLeft + 2, LTextRect.Bottom - 1);
                DrawPixelLine(LLeft + 2, LTextRect.Bottom - 1, LLeft + 4, LTextRect.Bottom - 3);

                LStep := LStep + 4;
              end;
            end;
          ulWaveLine:
            begin
              LLeft := LTextRect.Left;
              LStep := 0;

              while LLeft < LTokenRect.Right do
              begin
                DrawPixelLine(LLeft, LTextRect.Bottom - 3, LLeft + 3, LTextRect.Bottom - 3);

                LStep := LStep + 6;
              end;

              LLeft := LTextRect.Left;
              DrawPixelLine(LLeft, LTextRect.Bottom - 2, LLeft + 1, LTextRect.Bottom - 2);
              LLeft := LLeft + 1;

              while LLeft < LTokenRect.Right do
              begin
                DrawPixelLine(LLeft + 1, LTextRect.Bottom - 2, LLeft + 3, LTextRect.Bottom - 2);

                LStep := LStep + 3;
              end;

              LLeft := LTextRect.Left;

              while LLeft < LTokenRect.Right do
              begin
                DrawPixelLine(LLeft + 3, LTextRect.Bottom - 1, LLeft + 6, LTextRect.Bottom - 1);

                LStep := LStep + 6;
              end;
            end;
        end;
        Canvas.Stroke.Color := LOldPenColor;
      end;
    end;

    LTokenRect.Left := LTokenRect.Right;
  end;

var
  LCustomBackgroundColor, LCustomForegroundColor: TAlphaColor;
  LCustomLineColors, LIsLineSelected, LIsSelectionInsideLine: Boolean;
  LLineEndRect, LLineRect: TRectF;
  LLineSelectionStart, LLineSelectionEnd: Integer;
  LSelectionStartPosition: TTextEditorTextPosition;
  LSelectionEndPosition: TTextEditorTextPosition;
  LViewLine: Integer;

  procedure PaintHighlightToken(const AFillToEndOfLine: Boolean);
  var
    LOldColor: TAlphaColor;
    LFirstColumn, LLastColumn: Integer;
    LFirstUnselectedPartOfToken, LSecondUnselectedPartOfToken, LIsPartOfTokenSelected, LSelected: Boolean;
    LMultiCaretRecord: TTextEditorMultiCaretRecord;
    LText: string;
    LTokenLength, LSelectedTokenLength: Integer;
    LSearchTokenRect, LTempRect: TRectF;
    LSelectedText, LTempText: string;
  begin
    LOldColor := FPaintHelper.Color;
    LFirstColumn := LTokenHelper.CharsBefore + 1;
    LLastColumn := LFirstColumn + LTokenHelper.Length;
    LFirstUnselectedPartOfToken := False;
    LSecondUnselectedPartOfToken := False;
    LIsPartOfTokenSelected := False;

    if FMultiEdit.SelectionAvailable then
    begin
      LSelected := False;

      if Assigned(FMultiEdit.Carets) then
      begin
        for var LIndex := 0 to FMultiEdit.Carets.Count - 1 do
        begin
          LMultiCaretRecord := FMultiEdit.Carets[LIndex]^;

          if LMultiCaretRecord.SelectionStart.Line = LCurrentLine then
          begin
            LLineSelectionStart := LMultiCaretRecord.SelectionStart.Char;
            LLineSelectionEnd := LMultiCaretRecord.ViewPosition.Column;

            if LLineSelectionStart > LLineSelectionEnd then
              SwapInt(LLineSelectionStart, LLineSelectionEnd);

            LSelectionStartPosition := GetPosition(LLineSelectionStart, LCurrentLine);
            LSelectionEndPosition := GetPosition(LLineSelectionEnd, LCurrentLine);

            LSelected := (LFirstColumn >= LLineSelectionStart) and (LFirstColumn < LLineSelectionEnd) or
              (LLastColumn >= LLineSelectionStart) and (LLastColumn <= LLineSelectionEnd) or
              (LLineSelectionStart > LFirstColumn) and (LLineSelectionEnd < LLastColumn);

            if LSelected then
            begin
              LFirstUnselectedPartOfToken := LFirstColumn < LLineSelectionStart;
              LSecondUnselectedPartOfToken := LLastColumn > LLineSelectionEnd;
              LIsPartOfTokenSelected := LFirstUnselectedPartOfToken or LSecondUnselectedPartOfToken;

              Break;
            end;
          end;
        end;
      end;
    end
    else
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
    Canvas.Font.Style := LTokenHelper.FontStyle;

    if AMinimap and not (ioUseBlending in FMinimap.Indicator.Options) and (LViewLine >= TopLine) and
      (LViewLine < TopLine + FLineNumbers.VisibleCount) and (LBackgroundColor <> FColors.SearchHighlighterBackground) and
      (LBackgroundColor <> TAlphaColors.Red) then
      LBackgroundColor := FColors.MinimapVisibleRows;

    if LCustomLineColors then
    begin
      if LCustomForegroundColor <> TAlphaColors.Null then
        LForegroundColor := LCustomForegroundColor;

      if (LCustomBackgroundColor <> TAlphaColors.Null) and not LTokenHelper.CustomBackgroundColor then
        LBackgroundColor := LCustomBackgroundColor;
    end;

    LText := LTokenHelper.Text;
    LTokenLength := 0;
    LSelectedTokenLength := 0;
    LSearchTokenRect := LTokenRect;
    LSelectedText := '';

    if LIsPartOfTokenSelected then
    begin
      if LTokenHelper.RightToLeftToken then
      begin
        LSelectedRect := LTokenRect;
        LTempText := LText;

        SetDrawingColors(False);

        LTokenLength := LText.Length;
        LTokenRect.Right := LTokenRect.Left + GetTokenWidth(LText, LTokenLength, LTokenHelper.ExpandedCharsBefore, AMinimap, True);

        LTempRect := LTokenRect;

        PaintToken(LText, LTokenLength);

        { Selected part of the token }
        if (LLastColumn >= LLineSelectionEnd) or not LSecondUnselectedPartOfToken then
        begin
          { Get the unselected part from the end of the text }
          LText := Copy(LTempText, LTokenLength - (LLastColumn - LLineSelectionEnd) + 1);
          { Set left of the rect }
          LTokenRect.Left := LSelectedRect.Left + GetTokenWidth(LText, LText.Length, LTokenHelper.ExpandedCharsBefore, AMinimap, True);
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
          LTokenRect.Left := LSelectedRect.Left + GetTokenWidth(LText, LText.Length, LTokenHelper.ExpandedCharsBefore, AMinimap, True);
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
          LTokenLength := if LSecondUnselectedPartOfToken then LLineSelectionEnd - LLineSelectionStart else LText.Length;
          { Set right of the rect }
          LTokenRect.Right := LTokenRect.Left + GetTokenWidth(LText, LTokenLength, LTokenHelper.ExpandedCharsBefore, AMinimap, True);
        end;

        LSelectedRect := LTokenRect;

        { Paint selected rect }
        SetDrawingColors(True);
        LText := LTempText;
        LTokenLength := LText.Length;
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

          LTokenRect.Right := LTokenRect.Left + GetTokenWidth(LText, LText.Length, LTokenHelper.ExpandedCharsBefore, AMinimap);

          PaintToken(LText, LText.Length);
        end;
      end;
    end
    else
    if not LText.IsEmpty then
    begin
      SetDrawingColors(LSelected);

      LTokenLength := LText.Length;
      LTokenRect.Right := LTokenRect.Left + GetTokenWidth(LText, LTokenLength, LTokenHelper.ExpandedCharsBefore, AMinimap);

      PaintToken(LText, LTokenLength);
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
      SetDrawingColors(True, True);

      LTempRect := LTokenRect;
      LTokenRect := LSelectedRect;

      PaintToken(LSelectedText, LSelectedTokenLength);

      LTokenRect := LTempRect;
    end;

    if AFillToEndOfLine and (LTokenRect.Left < LLineRect.Right) then
    begin
      LBackgroundColor := GetBackgroundColor;

      if AMinimap and not (ioUseBlending in FMinimap.Indicator.Options) and (LViewLine >= TopLine) and
        (LViewLine < TopLine + FLineNumbers.VisibleCount) then
        LBackgroundColor := FColors.MinimapVisibleRows;

      if LCustomLineColors then
      begin
        if LCustomForegroundColor <> TAlphaColors.Null then
          LForegroundColor := LCustomForegroundColor;

        if LCustomBackgroundColor <> TAlphaColors.Null then
          LBackgroundColor := LCustomBackgroundColor;
      end;

      if FSelection.Mode = smNormal then
      begin
        SetDrawingColors(not (soToEndOfLine in FSelection.Options) and not FMultiEdit.SelectionAvailable and
          (LIsLineSelected or LSelected and (LLineSelectionEnd > LLastColumn)));

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
          LTokenLength := if LLineSelectionStart > LLastColumn then LLineSelectionEnd - LLineSelectionStart else LLineSelectionEnd - LLastColumn;
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

var
  LExpandedCharsBefore: Integer;

  procedure PrepareTokenHelper(const AToken: string; const ACharsBefore, ATokenLength: Integer;
    const AForeground, ABackground: TAlphaColor; const ABorder: TAlphaColor; const AFontStyle: TFontStyles;
    const AUnderline: TTextEditorUnderline; const AUnderlineColor: TAlphaColor; const ACustomBackgroundColor: Boolean);
  var
    LForeground, LBackground: TAlphaColor;
    LCanAppend, LAppendAnsiChars, LAppendTabs, LAppendEmptySpace, LAnsiEncoding: Boolean;
    LToken: string;
    LTokenLength: Integer;
    LPToken: PChar;
    LEmptySpace: TTextEditorEmptySpace;
  begin
    LForeground := AForeground;
    LBackground := ABackground;

    if (LBackground = TAlphaColors.Null) or
      ((FColors.ActiveLineBackground <> TAlphaColors.Null) and LIsCurrentLine and not ACustomBackgroundColor) then
      LBackground := GetBackgroundColor;

    if AForeground = TAlphaColors.Null then
      LForeground := FColors.EditorForeground;

    LCanAppend := False;
    LToken := AToken;
    LTokenLength := ATokenLength;
    LPToken := PChar(LToken);

    if not (eoShowNonBreakingSpaces in Options) and (LPToken^ = TControlCharacters.NonBreakingSpace) then
      LPToken^ := TCharacters.Space;

    LEmptySpace := TTextEditorEmptySpace.esNone;

    case LPToken^ of
      TControlCharacters.NonBreakingSpace:
        LEmptySpace := esNonBreakingSpace;
      TCharacters.Space:
        LEmptySpace := esSpace;
      TControlCharacters.Substitute:
        LEmptySpace := esNull;
      TControlCharacters.Tab:
        LEmptySpace := esTab;
      TControlCharacters.ZeroWidthSpace:
        LEmptySpace := esZeroWidthSpace;
    else
      if LPToken^ in TControlCharacters.AsSet then
        LEmptySpace := esControlCharacter;
    end;

    if (LEmptySpace <> TTextEditorEmptySpace.esNone) and FSpecialChars.Visible then
    begin
      if scoMiddleColor in FSpecialChars.Options then
        LForeground := MiddleColor(FHighlighter.MainRules.Attribute.Background, FHighlighter.MainRules.Attribute.Foreground)
      else
        LForeground := if scoTextColor in FSpecialChars.Options then FHighlighter.MainRules.Attribute.Foreground else FSpecialChars.Color;
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
        LAppendAnsiChars := (LTokenHelper.Length > 0) and (Ord(LTokenHelper.Text[1]) <= TCharacters.AnsiCharHigh) and (Ord(LPToken^) <= TCharacters.AnsiCharHigh);
        LAppendTabs := not FLines.Columns or FLines.Columns and (LEmptySpace <> esTab);
        LAppendEmptySpace := (LEmptySpace = LTokenHelper.EmptySpace) and not (LEmptySpace in [esNonBreakingSpace, esZeroWidthSpace]);

        LCanAppend := LCanAppend and
          ((LTokenHelper.FontStyle = AFontStyle) or ((LEmptySpace <> TTextEditorEmptySpace.esNone) and not (TFontStyle.fsUnderline in AFontStyle) and
          not (TFontStyle.fsUnderline in LTokenHelper.FontStyle))) and
          (LTokenHelper.Underline = AUnderline) and LAppendEmptySpace and LAppendAnsiChars and LAppendTabs;
      end;

      if not LCanAppend then
      begin
        PaintHighlightToken(False);
        LTokenHelper.EmptySpace := TTextEditorEmptySpace.esNone;
      end;
    end;

    LTokenHelper.EmptySpace := LEmptySpace;

    if FUnknownChars.Visible and (FLines.UnknownCharHigh > 0) then
    begin
      while LPToken^ <> TControlCharacters.Null do
      begin
        LAnsiEncoding := FLines.Encoding = System.SysUtils.TEncoding.ANSI;

        if (not LAnsiEncoding or LAnsiEncoding and not IsAnsiUnicodeChar(LPToken^)) and (Ord(LPToken^) > FLines.UnknownCharHigh) then
          LPToken^ := Char(FUnknownChars.ReplaceChar);

        Inc(LPToken);
      end;
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
      LTokenHelper.CustomBackgroundColor := ACustomBackgroundColor;
      LTokenHelper.ExpandedCharsBefore := LExpandedCharsBefore;
      LTokenHelper.Foreground := LForeground;
      LTokenHelper.Background := LBackground;
      LTokenHelper.Border := ABorder;
      LTokenHelper.FontStyle := AFontStyle;
      LTokenHelper.Overhang := not AMinimap and ((TFontStyle.fsItalic in AFontStyle) or not FPaintHelper.FixedSizeFont);
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

var
  LAnySelection: Boolean;
  LLineHeight: Single;
  LPaintedWidth: Single;
  LWrappedRowCount, LWrappedUnvisibleLength: Integer;

  procedure PaintLines;
  var
    LWordAtSelection, LSelectedText: string;

    procedure GetWordAtSelection;
    var
      LTempTextPosition: TTextEditorTextPosition;
      LSelectionStartChar, LSelectionEndChar: Integer;
    begin
      LTempTextPosition := FPosition.SelectionEnd;
      LSelectionStartChar := FPosition.SelectionStart.Char;
      LSelectionEndChar := FPosition.SelectionEnd.Char;

      if LSelectionStartChar > LSelectionEndChar then
        SwapInt(LSelectionStartChar, LSelectionEndChar);

      LTempTextPosition.Char := LSelectionEndChar - 1;
      LSelectedText := Copy(FLines[FPosition.SelectionStart.Line], LSelectionStartChar, LSelectionEndChar - LSelectionStartChar);
      LWordAtSelection := if FPosition.SelectionStart.Line = FPosition.SelectionEnd.Line then WordAtTextPosition(LTempTextPosition) else '';
    end;

var
  LHighlighterAttribute: TTextEditorHighlighterAttribute;
  LTokenPosition: Integer;
  LTokenLength: Integer;
  LTokenText: string;

    procedure PrepareToken;
    var
      LBorderColor, LUnderlineColor: TAlphaColor;
      LFontStyles: TFontStyles;
      LIsCustomBackgroundColor: Boolean;
      LUnderline: TTextEditorUnderline;
      LKeyword: string;
      LPToken, LPWord: PChar;
    begin
      LBorderColor := TAlphaColors.Null;

      LHighlighterAttribute := FHighlighter.TokenAttribute;

      if not (csDesigning in ComponentState) and Assigned(LHighlighterAttribute) then
      begin
        LForegroundColor := if LHighlighterAttribute.Foreground = TAlphaColors.Null then Colors.EditorForeground else LHighlighterAttribute.Foreground;

        if not AMinimap and LIsCurrentLine and FActiveLine.Visible and (FColors.ActiveLineForeground <> TAlphaColors.Null) then
          LForegroundColor := FColors.ActiveLineForeground;

        LBackgroundColor := if AMinimap and (FColors.MinimapBackground <> TAlphaColors.Null) then FColors.MinimapBackground else LHighlighterAttribute.Background;

        LFontStyles := LHighlighterAttribute.FontStyles;
        LIsCustomBackgroundColor := False;
        LUnderline := ulNone;
        LUnderlineColor := TAlphaColors.Null;

        if Assigned(FEvents.OnCustomTokenAttribute) then
          FEvents.OnCustomTokenAttribute(Self, LTokenText, LCurrentLine, LTokenPosition, LForegroundColor, LBackgroundColor, LFontStyles, LUnderline, LUnderlineColor);

        if FMatchingPairs.Active and not FSyncEdit.Visible and (FMatchingPair.Current <> trNotFound) and
          ((LCurrentLine = FMatchingPair.CurrentMatch.OpenTokenPos.Line) and (LTokenPosition = FMatchingPair.CurrentMatch.OpenTokenPos.Char - 1) or
           (LCurrentLine = FMatchingPair.CurrentMatch.CloseTokenPos.Line) and (LTokenPosition = FMatchingPair.CurrentMatch.CloseTokenPos.Char - 1)) then
        begin
          LIsCustomBackgroundColor := (mpoUseMatchedColor in FMatchingPairs.Options) and not (mpoUnderline in FMatchingPairs.Options);

          if (FMatchingPair.Current = trOpenAndCloseTokenFound) or (FMatchingPair.Current = trCloseAndOpenTokenFound) then
          begin
            if LIsCustomBackgroundColor then
            begin
              if LForegroundColor = FColors.MatchingPairMatched then
                LForegroundColor := FColors.EditorBackground;

              if not AMinimap and (FColors.ActiveLineForeground <> TAlphaColors.Null) then
                LForegroundColor := FColors.ActiveLineForeground;

              if not (mpoUnderline in FMatchingPairs.Options) then
                LBackgroundColor := FColors.MatchingPairMatched;
            end;

            if mpoUnderline in FMatchingPairs.Options then
            begin
              LUnderline := ulUnderline;
              LUnderlineColor := FColors.MatchingPairUnderline;
            end;
          end
          else
          if mpoHighlightUnmatched in FMatchingPairs.Options then
          begin
            if LIsCustomBackgroundColor then
            begin
              if LForegroundColor = FColors.MatchingPairUnmatched then
                LForegroundColor := FColors.EditorBackground;

              LBackgroundColor := FColors.MatchingPairUnmatched;
            end;

            if mpoUnderline in FMatchingPairs.Options then
            begin
              LUnderline := ulUnderline;
              LUnderlineColor := FColors.MatchingPairUnderline;
            end;
          end;
        end;

        if FSyncEdit.BlockSelected and LIsSyncEditBlock then
          LBackgroundColor := FColors.SyncEditBackground;

        if FSearch.InSelection.Active and LIsSearchInSelectionBlock then
          LBackgroundColor := FColors.SearchInSelectionBackground;

        if not FSyncEdit.Visible and LAnySelection and (soHighlightSimilarTerms in FSelection.Options) then
        begin
          LKeyword := '';

          if not LSelectedText.Trim.IsEmpty then
          begin
            if soTermsCaseSensitive in FSelection.Options then
            begin
              if LTokenText = LWordAtSelection then
                LKeyword := LSelectedText;

              LIsCustomBackgroundColor := not LKeyword.IsEmpty and (LKeyword = LTokenText);
            end
            else
            begin
              LPToken := PChar(LTokenText);
              LPWord := PChar(LSelectedText);

              while (LPToken^ <> TControlCharacters.Null) and (LPWord^ <> TControlCharacters.Null) and (CaseUpper(LPToken^) = CaseUpper(LPWord^)) do
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
            if FColors.SearchHighlighterForeground <> TAlphaColors.Null then
              LForegroundColor := FColors.SearchHighlighterForeground;

            LBackgroundColor := FColors.SearchHighlighterBackground;
            LBorderColor := FColors.SearchHighlighterBorder;
          end;
        end;

        if (LMarkColor <> TAlphaColors.Null) and not (LIsCurrentLine and FActiveLine.Visible and
          (FColors.ActiveLineBackground <> TAlphaColors.Null)) then
        begin
          LIsCustomBackgroundColor := True;
          LBackgroundColor := LMarkColor;
        end;

        PrepareTokenHelper(LTokenText, LTokenPosition, LTokenLength, LForegroundColor, LBackgroundColor, LBorderColor,
          LFontStyles, LUnderline, LUnderlineColor, LIsCustomBackgroundColor)
      end
      else
        PrepareTokenHelper(LTokenText, LTokenPosition, LTokenLength, LForegroundColor, LBackgroundColor, LBorderColor,
          FFonts.Text.Style, ulNone, TAlphaColors.Null, False);
    end;

    procedure SetSelectionVariables;
    begin
      if not AMinimap or AMinimap and (moShowSelection in FMinimap.Options) then
      begin
        LWordAtSelection := '';
        LAnySelection := GetSelectionAvailable or FMultiEdit.SelectionAvailable;

        if LAnySelection then
        begin
          GetWordAtSelection;

          LSelectionStartPosition := GetSelectionStartPosition;
          LSelectionEndPosition := GetSelectionEndPosition;

          if (FSelection.Mode = smColumn) and (LSelectionStartPosition.Char > LSelectionEndPosition.Char) then
            SwapInt(LSelectionStartPosition.Char, LSelectionEndPosition.Char);
        end
      end
      else
        LAnySelection := False;
    end;

var
  LLastColumn: Integer;

    procedure SetLineSelectionVariables;
    begin
      LIsSelectionInsideLine := False;
      LLineSelectionStart := 0;
      LLineSelectionEnd := 0;

      if LAnySelection and (LCurrentLine >= LSelectionStartPosition.Line) and (LCurrentLine <= LSelectionEndPosition.Line) then
      begin
        LLineSelectionStart := 1;
        LLineSelectionEnd := LLastColumn + 1;

        if (FSelection.ActiveMode = smColumn) or ((FSelection.ActiveMode = smNormal) and (LCurrentLine = LSelectionStartPosition.Line)) then
        begin
          if LSelectionStartPosition.Char > LLastColumn then
          begin
            LLineSelectionStart := 0;
            LLineSelectionEnd := 0;
          end
          else
          if LSelectionStartPosition.Char > LTokenPosition then
          begin
            LLineSelectionStart := LSelectionStartPosition.Char;
            LIsSelectionInsideLine := True;
          end;
        end;

        if (FSelection.ActiveMode = smColumn) or ((FSelection.ActiveMode = smNormal) and (LCurrentLine = LSelectionEndPosition.Line)) then
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

        if FWordWrap.Active and (LWrappedUnvisibleLength > 0) then
        begin
          Dec(LLineSelectionStart, LWrappedUnvisibleLength);
          Dec(LLineSelectionEnd, LWrappedUnvisibleLength);
        end;
      end;

      LIsLineSelected := not LIsSelectionInsideLine and (LLineSelectionStart > 0);
    end;

  var
    LTextPosition: TTextEditorTextPosition;
    LCurrentLineText: string;
    LWordWrapViewLength: Integer;
    LCurrentRow, LTextCaretY, LFirstColumn, LLine: Integer;
    LNextTokenText, LFromLineText, LToLineText: string;
    LFoldRange: TTextEditorCodeFoldingRange;
    LOpenTokenEndLen, LOpenTokenEndPos, LWordWrapTokenPosition, LLinePosition: Integer;
    LElement: string;
    LItem: TTextEditorHighlightLineItem;
    LRegEx: TRegEx;
    LRegExOptions: TRegExOptions;
  begin
    LLineRect := AClipRect;
    LLineRect.Bottom := if AMinimap then (AFirstLine - FMinimap.TopLine + 1) * FMinimap.CharHeight else LLineHeight;

    if not AMinimap and IsRulerVisible then
      LLineRect.Bottom := LLineRect.Bottom + FRuler.Height;

    LCurrentLineText := '';

    SetSelectionVariables;

    LViewLine := AFirstLine;
    LBookmarkOnCurrentLine := False;

    LWordWrapViewLength := Length(FWordWrapLine.ViewLength);

    while LViewLine <= ALastLine do
    begin
      LCurrentLine := GetViewTextLineNumber(LViewLine) - 1;

      LMarkColor := if AMinimap then TAlphaColors.Null else GetMarkBackgroundColor(LCurrentLine + 1);

      if AMinimap and (moShowBookmarks in FMinimap.Options) then
        LBookmarkOnCurrentLine := IsBookmarkOnCurrentLine;

      LCurrentLineText := FLines[LCurrentLine];

      LPaintedColumn := 1;

      LIsCurrentLine := False;
      LCurrentLineLength := LCurrentLineText.Length;

      LTokenPosition := 0;
      LTokenLength := 0;
      LExpandedCharsBefore := 0;
      LCurrentRow := LCurrentLine + 1;

      LNextTokenText := '';
      LTextCaretY := FPosition.Text.Line;
      LFirstColumn := 1;

      LWrappedRowCount := 0;
      LWrappedUnvisibleLength := 0;

      if FWordWrap.Active and (LViewLine < LWordWrapViewLength) then
      begin
        LLastColumn := LCurrentLineLength;

        LLine := LViewLine - 1;

        while (LLine > 0) and (GetViewTextLineNumber(LLine) = LCurrentLine + 1) do
        begin
          Inc(LFirstColumn, FWordWrapLine.ViewLength[LLine]);
          Dec(LLine);
          Inc(LWrappedRowCount);
        end;

        if LFirstColumn > 1 then
        begin
          LCurrentLineText := Copy(LCurrentLineText, LFirstColumn, LCurrentLineLength);
          LWrappedUnvisibleLength := LFirstColumn - 1;
          LFirstColumn := 1;
        end;
      end
      else
        LLastColumn := GetVisibleChars(LCurrentLine + 1, LCurrentLineText);

      SetLineSelectionVariables;

      LFoldRange := nil;

      if not AMinimap and IsCodeFoldingVisible then
      begin
        LFoldRange := CodeFoldingCollapsableFoldRangeForLine(LCurrentLine + 1);

        if Assigned(LFoldRange) and LFoldRange.Collapsed then
        begin
          if FCodeFolding.TextFolding.Active then
          begin
            if LCurrentLineText.Length > FCodeFolding.CollapsedRowCharacterCount then
              LCurrentLineText := Copy(LCurrentLineText, 1, FCodeFolding.CollapsedRowCharacterCount)  + TCharacters.ThreeDots;
          end
          else
          begin
            LFromLineText := FLines.TextLines[LFoldRange.FromLine - 1];
            LToLineText := FLines.TextLines[LFoldRange.ToLine - 1];
            LOpenTokenEndLen := 0;
            LOpenTokenEndPos := 0;

            if Assigned(LFoldRange.RegionItem) then
              LOpenTokenEndPos := Pos(LFoldRange.RegionItem.OpenTokenEnd, AnsiUpperCase(LFromLineText));

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
                  LOpenTokenEndPos := Pos(LFoldRange.RegionItem.OpenTokenEnd, AnsiUpperCase(LFromLineText), LOpenTokenEndPos + 1);
              until LOpenTokenEndPos = 0;
            end;

            if Assigned(LFoldRange.RegionItem) then
            begin
              if not LFoldRange.RegionItem.OpenTokenEnd.IsEmpty and (LOpenTokenEndPos > 0) then
              begin
                LOpenTokenEndLen := LFoldRange.RegionItem.OpenTokenEnd.Length;
                LCurrentLineText := Copy(LFromLineText, 1, LOpenTokenEndPos + LOpenTokenEndLen - 1);
              end
              else
                LCurrentLineText := Copy(LFromLineText, 1, LFoldRange.RegionItem.OpenToken.Length + Pos(LFoldRange.RegionItem.OpenToken, AnsiUpperCase(LFromLineText)) - 1);

              if (LFoldRange.RegionItem.OpenToken.Length > 0) and (LFoldRange.RegionItem.OpenToken[1] = '<') then
                LCurrentLineText := LCurrentLineText + '>';

              if not LFoldRange.RegionItem.CloseToken.IsEmpty then
                if Pos(LFoldRange.RegionItem.CloseToken, AnsiUpperCase(LToLineText)) <> 0 then
                begin
                  LCurrentLineText := LCurrentLineText + '..' + FMX.TextEditor.Utils.TrimLeft(LToLineText);

                  if LIsSelectionInsideLine then
                    LLineSelectionEnd := LCurrentLineText.Length + 1;
                end;

              if LCurrentLine = FMatchingPair.CurrentMatch.OpenTokenPos.Line then
              begin
                FMatchingPair.CurrentMatch.CloseTokenPos.Char :=
                  if not LFoldRange.RegionItem.OpenTokenEnd.IsEmpty and (LOpenTokenEndPos > 0) then
                    LOpenTokenEndPos + LOpenTokenEndLen + 2 { +2 = '..' }
                  else
                    FMatchingPair.CurrentMatch.OpenTokenPos.Char + FMatchingPair.CurrentMatch.OpenToken.Length + 2 { +2 = '..' };

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

      LIsSyncEditBlock := False;
      LIsSearchInSelectionBlock := False;

      while LCurrentRow = LCurrentLine + 1 do
      begin
        LPaintedWidth := 0;
        FItalic.Offset := 0;
        LIsCurrentLine := if Assigned(FMultiEdit.Carets) then IsMultiEditCaretFound(LCurrentLine + 1) else LTextCaretY = LCurrentLine;

        LForegroundColor := FColors.EditorForeground;
        LBackgroundColor := GetBackgroundColor;
        LCustomLineColors := False;

        if FHighlightLine.Active and not LCurrentLineText.IsEmpty then
        for var LIndex := FHighlightLine.Items.Count - 1 downto 0 do
        begin
          LItem := FHighlightLine.Item[LIndex];

          LRegExOptions := [];

          { Multiline mode. Changes the meaning of ^ and $ so they match at the beginning and end. }
          if hlMultiline in LItem.Options then
            LRegExOptions := [roMultiline];

          if hlIgnoreCase in LItem.Options then
            LRegExOptions := LRegExOptions + [roIgnoreCase];

          LRegEx := TRegex.Create(LItem.Pattern, LRegExOptions);

          if LRegEx.Match(Copy(LCurrentLineText, 1, FHighlightLine.MaxLineLength)).Success then
          begin
            LCustomForegroundColor := LItem.Foreground;
            LCustomBackgroundColor := LItem.Background;
            LCustomLineColors := True;

            Break;
          end;
        end;

        if Assigned(FEvents.OnCustomLineColors) then
          FEvents.OnCustomLineColors(Self, LCurrentLine, LCustomLineColors, LCustomForegroundColor, LCustomBackgroundColor);

        LTokenRect := LLineRect;
        LLineEndRect := LLineRect;

        if not LCurrentLineText.IsEmpty then
          LLineEndRect.Left := -100;

        LTokenHelper.Length := 0;
        LTokenHelper.EmptySpace := TTextEditorEmptySpace.esNone;
        LAddWrappedCount := False;

        LLinePosition := 0;

        if FWordWrap.Active and (LViewLine < LWordWrapViewLength) then
          LLastColumn := FWordWrapLine.Length[LViewLine];

        while not FHighlighter.EndOfLine do
        begin
          LTokenPosition := FHighlighter.TokenPosition;

          if LNextTokenText.IsEmpty then
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
          LTokenLength := LTokenText.Length;

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
                LTokenLength := LTokenText.Length;
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
          PaintSpecialCharsEndOfLine(LCurrentLine + 1, LLineEndRect, (LCurrentLineLength + 1 >= LLineSelectionStart) and (LCurrentLineLength + 1 < LLineSelectionEnd));
          PaintCodeFoldingCollapsedLine(LFoldRange, LLineRect);
        end;

        if Assigned(FEvents.OnAfterLinePaint) then
          FEvents.OnAfterLinePaint(Self, Canvas, LLineRect, LCurrentLine, AMinimap);

        LLineRect.Top := LLineRect.Bottom;
        LLineRect.Bottom := LLineRect.Bottom + if AMinimap then FMinimap.CharHeight else LLineHeight;
        Inc(LViewLine);
        LCurrentRow := GetViewTextLineNumber(LViewLine);

        if LWrappedRowCount > FLineNumbers.VisibleCount then
          Break;
      end;
    end;

    LIsCurrentLine := False;
  end;

begin
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Font.Assign(if AMinimap then FFonts.Minimap else FFonts.Text);

  LLineHeight := GetLineHeight;

  LCurrentSearchIndex := GetFirstSearchIndex(AMinimap);

  if ALastLine >= AFirstLine then
    PaintLines;

  LBookmarkOnCurrentLine := False;

  { Fill below the last line }
  LTokenRect := AClipRect;
  LTokenRect.Top := if AMinimap then Min(FMinimap.VisibleLineCount, FLineNumbers.Count) * FMinimap.CharHeight else (ALastLine - FLineNumbers.TopLine + 1) * LLineHeight;

  if not AMinimap and IsRulerVisible then
   LTokenRect.Top := LTokenRect.Top + FRuler.Height;

  if LTokenRect.Top < LTokenRect.Bottom then
  begin
    LBackgroundColor := FColors.EditorBackground;
    SetDrawingColors(False);
    FillRect(LTokenRect);
  end;
end;

procedure TCustomTextEditor.PaintSimpleTextLines(const AClipRect: TRectF; const AFirstLine, ALastLine: Integer; const AMinimap: Boolean);
var
  LLineRect: TRectF;

  procedure PaintActiveLineBackground;
  var
    LColor: TAlphaColor;
  begin
    if FActiveLine.Visible then
    begin
      if Focused then
      begin
        if FColors.ActiveLineBackground <> TAlphaColors.Null then
          LColor := FColors.ActiveLineBackground
        else
          Exit;
      end
      else
      if FColors.ActiveLineBackgroundUnfocused <> TAlphaColors.Null then
        LColor := FColors.ActiveLineBackgroundUnfocused
      else
        Exit;

      Canvas.Fill.Color := LColor;

      FillRect(LLineRect);

      Canvas.Fill.Color := FColors.EditorBackground;
    end;
  end;

var
  LLine: Integer;

  procedure PaintVisibleTextBackground;
  begin
    if (LLine >= TopLine - 1) and (LLine <= TopLine + VisibleLineCount - 1) then
    begin
      Canvas.Fill.Color := FColors.MinimapVisibleRows;

      FillRect(LLineRect);

      Canvas.Fill.Color := FColors.EditorBackground;
    end;
  end;

var
  LStartChar, LEndChar: Integer;

  function GetVisiblePartOfLine: string;
  begin
    Result := FLines[LLine];
    Result := if Result.Length >= LStartChar then Copy(Result, LStartChar, LEndChar - LStartChar + 1) else '';
  end;

var
  LCharsBefore: Integer;
  LIsSelectionAvailable: Boolean;
  LSelectionStartPosition, LSelectionEndPosition: TTextEditorTextPosition;

  function GetLineSelectionBounds(var ASelectionStart, ASelectionEnd: Integer): Boolean;
  var
    LSearchItem: TTextEditorSearchItem;
  begin
    Result := LIsSelectionAvailable;

    if Result then
    begin
      Result := True;

      if LSelectionStartPosition.Line = LLine then
      begin
        ASelectionStart := Max(LSelectionStartPosition.Char - LCharsBefore, 1);
        ASelectionEnd := if LSelectionEndPosition.Line = LLine then LSelectionEndPosition.Char - LCharsBefore else ASelectionStart + SelectionLength - LCharsBefore;

        Exit;
      end
      else
      if LSelectionEndPosition.Line = LLine then
      begin
        ASelectionStart := 1;
        ASelectionEnd := LSelectionEndPosition.Char - LCharsBefore;

        Exit;
      end
      else
      if (LSelectionStartPosition.Line < LLine) and (LSelectionEndPosition.Line > LLine) then
      begin
        ASelectionStart := 1;
        ASelectionEnd := SelectionLength;

        Exit;
      end;

      Result := False;
    end
    else
    if (FSearch.Items.Count > 0) and (FPosition.Text.Line = LLine) then
    begin
      for var LIndex := 0 to FSearch.Items.Count - 1 do
      begin
        LSearchItem := PTextEditorSearchItem(FSearch.Items.Items[LIndex])^;

        if LSearchItem.BeginTextPosition.Line = LLine then
        begin
          if (LSearchItem.BeginTextPosition.Char <= FPosition.Text.Char) and
            (LSearchItem.EndTextPosition.Char >= FPosition.Text.Char) then
          begin
            ASelectionStart := Max(LSearchItem.BeginTextPosition.Char - LCharsBefore, 1);
            ASelectionEnd := LSearchItem.EndTextPosition.Char - LCharsBefore;

            Exit(True);
          end;
        end
        else
        if LSearchItem.BeginTextPosition.Line > TopLine + VisibleLineCount then
          Break;
      end;
    end;
  end;

var
  LTabSpace: string;

  procedure TabsToSpaces(var AText: string);
  begin
    if sfHasNoTabs in FLines.Flags[LLine] then
      Exit;

    AText := StringReplace(AText, TControlCharacters.Tab, LTabSpace, [rfReplaceAll]);
  end;

  procedure PaintLine;
  var
    LText: string;
    LSelectionStart, LSelectionEnd: Integer;
    LUnselectedTextBefore, LSelectedText, LUnselectedTextAfter: string;
    LTextRect: TRectF;
  begin
    LText := GetVisiblePartOfLine;

    if LText.IsEmpty then
      Exit;

    if not AMinimap and GetLineSelectionBounds(LSelectionStart, LSelectionEnd) then
    begin
      LUnselectedTextBefore := Copy(LText, 1, LSelectionStart - 1);
      LSelectedText := Copy(LText, LSelectionStart, LSelectionEnd - LSelectionStart);
      LUnselectedTextAfter := Copy(LText, LSelectionEnd);

      TabsToSpaces(LUnselectedTextBefore);
      TabsToSpaces(LSelectedText);
      TabsToSpaces(LUnselectedTextAfter);

      LTextRect := LLineRect;

      if not LUnselectedTextBefore.IsEmpty then
      begin
        FPaintHelper.SetForegroundColor(FColors.EditorForeground);

        Canvas.Fill.Color := FColors.EditorForeground;
        DrawText(LTextRect, LUnselectedTextBefore);

        LTextRect.Left := LTextRect.Left + LUnselectedTextBefore.Length * FPaintHelper.CharWidth;
      end;

      if not LSelectedText.IsEmpty then
      begin
        FPaintHelper.SetForegroundColor(FColors.SelectionForeground);

        LTextRect.Right := LTextRect.Left + LSelectedText.Length * FPaintHelper.CharWidth;

        Canvas.Fill.Color := FColors.SelectionBackground;
        FillRect(LTextRect);
        Canvas.Fill.Color := FColors.SelectionForeground;
        DrawText(LTextRect, LSelectedText);

        LTextRect.Right := LLineRect.Right;
        LTextRect.Left := LTextRect.Left + LSelectedText.Length * FPaintHelper.CharWidth;
      end;

      if LUnselectedTextAfter.IsEmpty then
        Canvas.Fill.Color := FColors.EditorBackground
      else
      begin
        FPaintHelper.SetForegroundColor(FColors.EditorForeground);

        Canvas.Fill.Color := FColors.ActiveLineBackground;
        FillRect(LTextRect);
        Canvas.Fill.Color := FColors.EditorForeground;
        DrawText(LTextRect, LUnselectedTextAfter);
      end;
    end
    else
    begin
      TabsToSpaces(LText);

      FPaintHelper.SetForegroundColor(FColors.EditorForeground);

      Canvas.Fill.Color := FColors.EditorForeground;
      DrawText(LLineRect, LText);
    end;
  end;

var
  LLineHeight: Single;
begin
  FLines.Columns := False;

  LLineHeight := if AMinimap then FMinimap.CharHeight else GetLineHeight;

  LCharsBefore := Round(FScrollHelper.HorizontalPosition / FPaintHelper.CharWidth);
  LStartChar := Max(1, LCharsBefore);

  if FScrollHelper.HorizontalPosition <> 0 then
    Inc(LStartChar);

  LEndChar := LStartChar + Round((Width - FLeftMarginWidth) / FPaintHelper.CharWidth);
  LTabSpace := StringOfChar(TCharacters.Space, FTabs.Width);

  LIsSelectionAvailable := SelectionAvailable;
  LSelectionStartPosition := SelectionStartPosition;
  LSelectionEndPosition := SelectionEndPosition;

  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := FColors.EditorBackground;
  FillRect(AClipRect);

  for LLine := AFirstLine - 1 to ALastLine - 1 do
  begin
    LLineRect := AClipRect;
    LLineRect.Top := (LLine - AFirstLine + 1) * LLineHeight;
    LLineRect.Bottom := LLineRect.Top + LLineHeight;

    if AMinimap then
      PaintVisibleTextBackground
    else
    if FPosition.Text.Line = LLine then
      PaintActiveLineBackground;

    PaintLine;
  end; 
end;

procedure TCustomTextEditor.RedoItem;
var
  LChangeScrollPastEndOfLine: Boolean;
  LUndoItem: TTextEditorUndoItem;
  LMultiCaretRecord: TTextEditorMultiCaretRecord;
  LTextPosition: TTextEditorTextPosition;
  LCharChange, LLineChange: Integer;
  LSelectionStartPosition, LSelectionEndPosition: TTextEditorTextPosition;
  LTempText: string;
  LStrToDelete: PChar;
  LBeginX: Integer;
  LRun: PChar;
  LLength: Integer;
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
          SelectionStartPosition := LUndoItem.ChangeBeginPosition;
          SelectionEndPosition := LUndoItem.ChangeEndPosition;
        end;
      crMultiCaret:
        if Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) then
        begin
          LMultiCaretRecord := FMultiEdit.Carets[0]^;
          LTextPosition := ViewToTextPosition(LMultiCaretRecord.ViewPosition);

          FUndoList.AddChange(LUndoItem.ChangeReason, LTextPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition, '', FSelection.ActiveMode, LUndoItem.ChangeBlockNumber);

          LCharChange := LUndoItem.ChangeCaretPosition.Char - LTextPosition.Char;
          LLineChange := LUndoItem.ChangeCaretPosition.Line - LTextPosition.Line;

          for var LIndex := 0 to FMultiEdit.Carets.Count - 1 do
          begin
            LMultiCaretRecord := FMultiEdit.Carets[LIndex]^;

            LTextPosition := ViewToTextPosition(LMultiCaretRecord.ViewPosition);
            Inc(LTextPosition.Char, LCharChange);
            Inc(LTextPosition.Line, LLineChange);
            LMultiCaretRecord.ViewPosition := TextToViewPosition(LTextPosition);
          end;
        end;
      crSelection:
        begin
          FUndoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition, '', LUndoItem.ChangeSelectionMode, LUndoItem.ChangeBlockNumber);

          SetTextPositionAndSelection(LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition);
        end;
      crInsert, crPaste, crDragDropInsert:
        begin
          LTextPosition := TextPosition;
          LSelectionStartPosition := SelectionStartPosition;
          LSelectionEndPosition := SelectionEndPosition;

          SetTextPositionAndSelection(LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeBeginPosition);

          DoSelectedText(LUndoItem.ChangeSelectionMode, PChar(LUndoItem.ChangeString), False,
            LUndoItem.ChangeBeginPosition, LUndoItem.ChangeBlockNumber);

          IncCharacterCount(LUndoItem.ChangeString);

          FUndoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition, '', LUndoItem.ChangeSelectionMode, LUndoItem.ChangeBlockNumber);

          TextPosition := LTextPosition;
          SelectionStartPosition := LSelectionStartPosition;
          SelectionEndPosition := LSelectionEndPosition;
        end;
      crDelete:
        begin
          LTextPosition := TextPosition;
          LSelectionStartPosition := SelectionStartPosition;
          LSelectionEndPosition := SelectionEndPosition;

          SetTextPositionAndSelection(LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition);

          LTempText := SelectedText;

          DoSelectedText(LUndoItem.ChangeSelectionMode, PChar(LUndoItem.ChangeString), False,
            LUndoItem.ChangeBeginPosition, LUndoItem.ChangeBlockNumber);

          FPosition.SelectionEnd := LUndoItem.ChangeEndPosition;

          DecCharacterCount(LTempText);

          FUndoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition, LTempText, LUndoItem.ChangeSelectionMode, LUndoItem.ChangeBlockNumber);

          TextPosition := LUndoItem.ChangeCaretPosition;
          SelectionStartPosition := LSelectionStartPosition;
          SelectionEndPosition := LSelectionEndPosition;
        end;
      crLineBreak:
        begin
          LTextPosition := LUndoItem.ChangeBeginPosition;

          SetTextPositionAndSelection(LTextPosition, LTextPosition, LTextPosition);
          DoLineBreak(False);
        end;
      crIndent:
        begin
          SetTextPositionAndSelection(LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition);

          FUndoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition, LUndoItem.ChangeString, LUndoItem.ChangeSelectionMode,
            LUndoItem.ChangeBlockNumber);
        end;
      crUnindent:
        begin
          LStrToDelete := PChar(LUndoItem.ChangeString);

          SetTextCaretY(LUndoItem.ChangeBeginPosition.Line);

          LBeginX := if LUndoItem.ChangeSelectionMode = smColumn then Min(LUndoItem.ChangeBeginPosition.Char, LUndoItem.ChangeEndPosition.Char) else 1;

          repeat
            LRun := GetEndOfLine(LStrToDelete);

            if LRun <> LStrToDelete then
            begin
              LLength := LRun - LStrToDelete;

              if LLength > 0 then
              begin
                LTempText := FLines.TextLines[FPosition.Text.Line];

                Delete(LTempText, LBeginX, LLength);

                FLines[FPosition.Text.Line] := LTempText;
              end;
            end
            else
              LLength := 0;

            if IsLineTerminatorCharacter(LRun^) then
            begin
              Inc(LRun);

              if LRun^ = TControlCharacters.Linefeed then
                Inc(LRun);

              Inc(FPosition.Text.Line);
            end;

            LStrToDelete := LRun;
          until LRun^ = TControlCharacters.Null;

          if LUndoItem.ChangeSelectionMode = smColumn then
            SetTextPositionAndSelection(LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
              LUndoItem.ChangeEndPosition)
          else
          begin
            LTextPosition.Char := Max(LUndoItem.ChangeBeginPosition.Char - FTabs.Width, 1);
            LTextPosition.Line := LUndoItem.ChangeBeginPosition.Line;

            SetTextPositionAndSelection(LTextPosition, LTextPosition,
              GetPosition(LUndoItem.ChangeEndPosition.Char - LLength, LUndoItem.ChangeEndPosition.Line));
          end;

          FUndoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition, LUndoItem.ChangeString, LUndoItem.ChangeSelectionMode,
            LUndoItem.ChangeBlockNumber);
        end;
    end;
  finally
    if Assigned(FEvents.OnChange) then
      FEvents.OnChange(Self);

    FUndoList.InsideRedo := False;

    if LChangeScrollPastEndOfLine then
      FScroll.SetOption(soPastEndOfLine, False);

    LUndoItem.Free;
    DecPaintLock;
  end;
end;

// TODO Caret needs refactoring
procedure TCustomTextEditor.ResetCaret;
var
  LCaretStyle: TTextEditorCaretStyle;
begin
  if (csDesigning in ComponentState) or (csDestroying in ComponentState) then
    Exit;

  if Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) then
    Exit;

  LCaretStyle := if FOvertypeMode = omInsert then FCaret.Styles.Insert else FCaret.Styles.Overwrite;

  FCaretHelper.Offset := Point(FCaret.Offsets.Left, FCaret.Offsets.Top);

  case LCaretStyle of
    csHorizontalLine, csThinHorizontalLine:
      FCaretHelper.Offset.Y := FCaretHelper.Offset.Y + GetLineHeight;
    csHalfBlock:
      FCaretHelper.Offset.Y := FCaretHelper.Offset.Y + (GetLineHeight / 2);
    csBlock:
      ; // TODO
    csVerticalLine, csThinVerticalLine:
      ; // TODO
  end;

  Exclude(FState.Flags, sfCaretVisible);

  if Focused or FCaretHelper.ShowAlways then
    UpdateCaret;
end;

procedure TCustomTextEditor.ScanTagMatchingPair;
type
  TTagInfo = record
    Char: Integer;
    Length: Integer;
    Line: Integer;
    Name: string;
  end;
var
  LPChar: PChar;
  LLine: Integer;
  LChar: Integer;

  function LineChange: Boolean;
  begin
    Result := IsLineTerminatorCharacter(LPChar^);

    if Result then
    begin
      if LPChar^ = TControlCharacters.CarriageReturn then
        Inc(LPChar);

      if LPChar^ = TControlCharacters.Linefeed then
        Inc(LPChar);

      Inc(LLine);
      LChar := 1;
    end;
  end;

  procedure SkipComment;
  begin
    Inc(LPChar, 3);
    Inc(LChar, 3);

    while LPChar^ <> TControlCharacters.Null do
    begin
      if (LPChar^ = TCharacters.Hyphen) and ((LPChar + 1)^ = TCharacters.Hyphen) and ((LPChar + 2)^ = TCharacters.TagClose) then
      begin
        Inc(LPChar, 3);
        Inc(LChar, 3);
        Break;
      end;

      LineChange;

      Inc(LPChar);
      Inc(LChar);
    end;
  end;

  procedure SkipCData;
  begin
    Inc(LPChar, 3);
    Inc(LChar, 3);

    while LPChar^ <> TControlCharacters.Null do
    begin
      if (LPChar^ = TCharacters.SquareBracketClose) and ((LPChar + 1)^ = TCharacters.SquareBracketClose) and
        ((LPChar + 2)^ = TCharacters.TagClose) then
      begin
        Inc(LPChar, 3);
        Inc(LChar, 3);
        Break;
      end;

      LineChange;

      Inc(LPChar);
      Inc(LChar);
    end;
  end;

var
  LTextPosition: TTextEditorTextPosition;
  LLineText: string;
  LPStart: PChar;
  LCurrentTagName: string;
  LLength: Integer;
  LTagStack: TStack<TTagInfo>;
  LIsEndTag, LIsSelfClosing: Boolean;
  LTagName: string;
  LTagInfo: TTagInfo;
begin
  LTextPosition := TextPosition;
  LLineText := FLines[LTextPosition.Line];

  LPChar := PChar(LLineText);
  Inc(LPChar, LTextPosition.Char - 1);

  if LPChar^ = TCharacters.TagOpen then
    Exit;

  if LPChar^ = TCharacters.TagClose then
    Dec(LPChar);

  while LPChar^ <> TControlCharacters.Null do
  begin
    if LPChar^ = TCharacters.TagClose then
      Exit;

    if LPChar^ = TCharacters.TagOpen then
      Break;

    Dec(LPChar);
  end;

  if LPChar^ = TCharacters.TagOpen then
  begin
    Inc(LPChar);

    if LPChar^ = TCharacters.Slash then
      Inc(LPChar);
  end
  else
    Exit;

  LPStart := LPChar;

  while not (LPChar^ in [TCharacters.TagClose, TControlCharacters.Null, TControlCharacters.Tab, TCharacters.Space, TCharacters.Slash]) do
    Inc(LPChar);

  SetString(LCurrentTagName, LPStart, LPChar - LPStart);

  LLength := LCurrentTagName.Length;

  if LCurrentTagName.IsEmpty then
    Exit;

  LPChar := PChar(Text);
  LLine := 0;
  LChar := 1;

  LTagStack := TStack<TTagInfo>.Create;
  try
    while LPChar^ <> TControlCharacters.Null do
    begin
      if LPChar^ = TCharacters.TagOpen then
      begin
        if ((LPChar + 1)^ = TCharacters.ExclamationMark) and ((LPChar + 2)^ = TCharacters.SquareBracketOpen) and ((LPChar + 3)^ = 'C') then
        begin
          SkipCData;
          Continue;
        end;

        if ((LPChar + 1)^ = TCharacters.ExclamationMark) and ((LPChar + 2)^ = TCharacters.Hyphen) and ((LPChar + 3)^ = TCharacters.Hyphen) then
        begin
          SkipComment;
          Continue;
        end;

        LPStart := LPChar;

        Inc(LPChar);
        Inc(LChar);

        LIsEndTag := LPChar^ = TCharacters.Slash;

        if LIsEndTag then
        begin
          Inc(LPChar);
          Inc(LChar);
        end;

        while not (LPChar^ in [TCharacters.TagClose, TControlCharacters.Null, TControlCharacters.Tab, TCharacters.Space, TCharacters.Slash]) do
        begin
          Inc(LPChar);
          Inc(LChar);
        end;

        SetString(LTagName, LPStart + 1 + Ord(LIsEndTag), LPChar - LPStart - 1 - Ord(LIsEndTag));

        LIsSelfClosing := False;

        while not (LPChar^ in [TCharacters.TagClose, TControlCharacters.Null]) do
        begin
          if LPChar^ in ['"', ''''] then
          begin
            Inc(LPChar);
            Inc(LChar);

            while (LPChar^ <> TControlCharacters.Null) and not (LPChar^ in ['"', '''']) do
            begin
              LineChange;

              Inc(LPChar);
              Inc(LChar);
            end;
          end;

          if LPChar^ = TCharacters.Slash then
            LIsSelfClosing := True;

          Inc(LPChar);
          Inc(LChar);
        end;

        if LPChar^ = TCharacters.TagClose then
        begin
          Inc(LPChar);
          Inc(LChar);

          if LIsEndTag then
          begin
            if (LTagStack.Count > 0) and (LCurrentTagName = LTagName) then
            begin
              LTagInfo := LTagStack.Pop;

              if (LTextPosition.Line = LTagInfo.Line) and (LTextPosition.Char >= LTagInfo.Char) and
                (LTextPosition.Char <= LTagInfo.Char + LLength + LTagInfo.Length + 1) or
                (LTextPosition.Line = LLine) and (LTextPosition.Char >= LChar - LLength - 1) and
                (LTextPosition.Char <= LChar) then
              begin
                FMatchingPair.CurrentMatch.OpenToken := TCharacters.TagOpen + LTagInfo.Name;
                FMatchingPair.CurrentMatch.OpenTokenPos := GetPosition(LTagInfo.Char + 1, LTagInfo.Line);
                FMatchingPair.CurrentMatch.CloseToken := TCharacters.CloseTagOpen + LTagName;
                FMatchingPair.CurrentMatch.CloseTokenPos := GetPosition(LChar - (LPChar - LPStart) + 2, LLine);
                FMatchingPair.Current := trOpenAndCloseTokenFound;
                Exit;
              end;
            end;
          end
          else
          if not LIsSelfClosing and (LCurrentTagName = LTagName) then
          begin
            LTagInfo.Name := LTagName;
            LTagInfo.Line := LLine;
            LTagInfo.Char := LChar - (LPChar - LPStart);
            LTagInfo.Length := LChar;

            LTagStack.Push(LTagInfo);
          end;
        end;
      end
      else
      if not LineChange then
      begin
        Inc(LPChar);
        Inc(LChar);
      end;
    end;
  finally
    LTagStack.Free;
  end;
end;

procedure TCustomTextEditor.ScanCodeFoldingMatchingPair;
var
  LViewPosition: TTextEditorViewPosition;
  LLine: Integer;
  LFoldRange: TTextEditorCodeFoldingRange;
  LLineText, LOpenLineText: string;
  LTempPosition: Integer;
begin
  if cfoHighlightMatchingPair in FCodeFolding.Options then
  begin
    LViewPosition := ViewPosition;
    LLine := GetViewTextLineNumber(LViewPosition.Row);
    LFoldRange := CodeFoldingCollapsableFoldRangeForLine(LLine);

    if not Assigned(LFoldRange) then
      LFoldRange := CodeFoldingFoldRangeForLineTo(LLine);

    if Assigned(LFoldRange) and Assigned(LFoldRange.RegionItem) and IsKeywordAtCaretPosition then
    begin
      FMatchingPair.Current := trOpenAndCloseTokenFound;

      LLineText := FLines[LFoldRange.FromLine - 1];
      LOpenLineText := AnsiUpperCase(LLineText);
      LTempPosition := Pos(LFoldRange.RegionItem.OpenToken, LOpenLineText);

      FMatchingPair.CurrentMatch.OpenToken := System.Copy(LLineText, LTempPosition,
        Length(LFoldRange.RegionItem.OpenToken + LFoldRange.RegionItem.OpenTokenCanBeFollowedBy));

      if FHighlighter.FoldTags then
        Inc(LTempPosition); { +1 = < }

      FMatchingPair.CurrentMatch.OpenTokenPos := GetPosition(LTempPosition, LFoldRange.FromLine - 1);

      LLine := LFoldRange.ToLine;
      LLineText := FLines[LLine - 1];
      LTempPosition := Pos(LFoldRange.RegionItem.CloseToken, AnsiUpperCase(LLineText));

      if FHighlighter.FoldTags then
        Inc(LTempPosition, 2); { +2 = </ }

      FMatchingPair.CurrentMatch.CloseToken := System.Copy(LLineText, LTempPosition,
        LFoldRange.RegionItem.CloseToken.Length);

      if LFoldRange.Collapsed then
        FMatchingPair.CurrentMatch.CloseTokenPos :=
          GetPosition(FMatchingPair.CurrentMatch.OpenTokenPos.Char + FMatchingPair.CurrentMatch.OpenToken.Length +
          2 { +2 = '..' }, LFoldRange.FromLine - 1)
      else
        FMatchingPair.CurrentMatch.CloseTokenPos := GetPosition(LTempPosition, LLine - 1);
    end;
  end;
end;

procedure TCustomTextEditor.ScanMatchingPair;
var
  LViewPosition: TTextEditorViewPosition;
begin
  if not FHighlighter.MatchingPairHighlight or FSimpleMode then
    Exit;

  LViewPosition := ViewPosition;

  FMatchingPair.Current := GetMatchingToken(LViewPosition, FMatchingPair.CurrentMatch);

  if (mpoHighlightAfterToken in FMatchingPairs.Options) and (FMatchingPair.Current = trNotFound) and (LViewPosition.Column > 1) then
  begin
    Dec(LViewPosition.Column);
    FMatchingPair.Current := GetMatchingToken(LViewPosition, FMatchingPair.CurrentMatch);
  end;

  if FMatchingPair.Current <> trNotFound then
    Exit;

  if FHighlighter.FoldTags then
    ScanTagMatchingPair
  else
    ScanCodeFoldingMatchingPair;
end;

procedure TCustomTextEditor.SetAlwaysShowCaret(const AValue: Boolean);
begin
  if FCaretHelper.ShowAlways <> AValue then
  begin
    FCaretHelper.ShowAlways := AValue;

    if not (csDestroying in ComponentState) and not Focused then
      if AValue then
        ResetCaret
      else
        HideCaret;
  end;
end;

procedure TCustomTextEditor.SetViewPosition(const AValue: TTextEditorViewPosition);
var
  LValue: TTextEditorViewPosition;
  LTextPosition: TTextEditorTextPosition;
  LLength: Integer;
begin
  LValue := AValue;

  IncPaintLock;
  try
    if LValue.Row < 1 then
      LValue.Row := 1
    else
    if LValue.Row > FLineNumbers.Count then
    begin
      LValue.Row := Max(FLineNumbers.Count, 1);
      LValue.Column := FLines[GetViewTextLineNumber(LValue.Row) - 1].Length + 1;
    end;

    if LValue.Column < 1 then
      LValue.Column := 1
    else
    if not (soPastEndOfLine in FScroll.Options) then
    begin
      LLength := FLines[GetViewTextLineNumber(LValue.Row) - 1].Length;
      LTextPosition := ViewToTextPosition(LValue);

      if LTextPosition.Char > LLength then
      begin
        LTextPosition.Char := LLength + 1;
        LValue.Column := TextToViewPosition(LTextPosition).Column;
      end;
    end;

    FViewPosition.Column := LValue.Column;
    FViewPosition.Row := LValue.Row;

    EnsureCursorPositionVisible;

    Include(FState.Flags, sfCaretChanged);
  finally
    DecPaintLock;
  end;
end;

procedure TCustomTextEditor.SetName(const AValue: TComponentName);
var
  LTextToName: Boolean;
begin
  LTextToName := (ComponentState * [csDesigning, csLoading] = [csDesigning]) and (FMX.TextEditor.Utils.TrimRight(Text) = Name);

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

  procedure SetSelectedText;
  var
    LTextPosition, LSelectionStartPosition: TTextEditorTextPosition;
    LSelectedText: string;
  begin
    LSelectionStartPosition := SelectionStartPosition;
    LSelectedText := GetSelectedText;

    AddUndoDelete(TextPosition, LSelectionStartPosition, SelectionEndPosition, LSelectedText, FSelection.ActiveMode);

    DoSelectedText(AChangeString);

    LTextPosition := TextPosition;

    if not AChangeString.IsEmpty then
      AddUndoInsert(LSelectionStartPosition, LSelectionStartPosition, LTextPosition, '', smNormal);

    FPosition.SelectionStart := LTextPosition;
    FPosition.SelectionEnd := LTextPosition;
  end;

  procedure SetMultiSelectedText;
  var
    LMultiCaretRecord: TTextEditorMultiCaretRecord;
    LLineSelectionStart, LLineSelectionEnd: Integer;
  begin
    if Assigned(FMultiEdit.Carets) then
    begin
      for var LIndex := FMultiEdit.Carets.Count - 1 downto 0 do
      begin
        LMultiCaretRecord := FMultiEdit.Carets[LIndex]^;

        LLineSelectionStart := LMultiCaretRecord.SelectionStart.Char;
        LLineSelectionEnd := LMultiCaretRecord.ViewPosition.Column;

        if LLineSelectionStart > LLineSelectionEnd then
          SwapInt(LLineSelectionStart, LLineSelectionEnd);

        SelectionStartPosition := GetPosition(LLineSelectionStart, LMultiCaretRecord.SelectionStart.Line);
        SelectionEndPosition := GetPosition(LLineSelectionEnd, LMultiCaretRecord.SelectionStart.Line);
        TextPosition := SelectionEndPosition;

        SetSelectedText;
      end;
    end;
  end;

begin
  if FMultiEdit.SelectionAvailable then
    SetMultiSelectedText
  else
    SetSelectedText;

  if Assigned(FEvents.OnAfterDeleteSelection) then
    FEvents.OnAfterDeleteSelection(Self);

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

  procedure DeleteSelection;
  var
    LTempString: string;
    LFirstLine, LLastLine, LCurrentLine: Integer;
    LDeletePosition, LViewDeletePosition, LDeletePositionEnd, LViewDeletePositionEnd: Integer;
  begin
    case FSelection.ActiveMode of
      smNormal:
        if FLines.Count > 0 then
        begin
          LTempString := Copy(FLines[LBeginTextPosition.Line], 1, LBeginTextPosition.Char - 1) +
            Copy(FLines[LEndTextPosition.Line], LEndTextPosition.Char);

          FLines.DeleteLines(LBeginTextPosition.Line, Min(LEndTextPosition.Line - LBeginTextPosition.Line,
            FLines.Count - LBeginTextPosition.Line));

          FLines[LBeginTextPosition.Line] := LTempString;

          if Assigned(FEvents.OnAfterDeleteSelection) then
            FEvents.OnAfterDeleteSelection(Self);
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

          for var LLine := LFirstLine to LLastLine do
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
  end;

var
  LTextPosition: TTextEditorTextPosition;

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
      LLeftSide, LSpaces, LLineText, LRightSide, LLine: string;
      LLength, LCharCount: Integer;
      LBeginPosition, LEndPosition: TTextEditorTextPosition;
      LPStart, LPText: PChar;
      LTextLine, LTextLineStart: Integer;
    begin
      Result := 0;

      LLeftSide := Copy(FLines[LTextPosition.Line], 1, LTextPosition.Char - 1);
      LLength := LLeftSide.Length;

      if LTextPosition.Char > LLength + 1 then
      begin
        LCharCount := LTextPosition.Char - LLength - 1;

        if toTabsToSpaces in FTabs.Options then
          LSpaces := StringOfChar(TCharacters.Space, LCharCount)
        else
        if AllWhiteUpToTextPosition(LTextPosition, LLeftSide, LLength) then
          LSpaces := StringOfChar(TControlCharacters.Tab, LCharCount div FTabs.Width) + StringOfChar(TCharacters.Space, LCharCount mod FTabs.Width)
        else
          LSpaces := StringOfChar(TCharacters.Space, LCharCount);

        LLeftSide := LLeftSide + LSpaces;

        LEndPosition := LTextPosition;
        LBeginPosition := LEndPosition;

        Dec(LBeginPosition.Char);
        Dec(LBeginPosition.Char, LSpaces.Length - 1);

        AddUndoInsert(LTextPosition, LBeginPosition, LEndPosition, '', smNormal);
      end;

      LLineText := FLines[LTextPosition.Line];
      LRightSide := Copy(LLineText, LTextPosition.Char, LLineText.Length - (LTextPosition.Char - 1));

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

      if FWordWrap.Active then
        FWordWrapLine.ViewLength[LTextPosition.Line + 1] := LLine.Length;

      { Insert left lines of Value }
      LTextLineStart := LTextPosition.Line;
      LTextLine := LTextLineStart + 1;

      while LPText^ <> TControlCharacters.Null do
      begin
        if LPText^ = TControlCharacters.CarriageReturn then
        begin
          Include(FLines.Items^[LTextLine - 1].Flags, sfLineBreakCR);
          Inc(LPText);
        end;

        if LPText^ = TControlCharacters.Linefeed then
        begin
          Include(FLines.Items^[LTextLine - 1].Flags, sfLineBreakLF);
          Inc(LPText);
        end;

        LPStart := LPText;
        LPText := GetEndOfLine(LPStart);

        if LPText = LPStart then
          LLine := if LPText^ = TControlCharacters.Null then LRightSide else ''
        else
        begin
          SetString(LLine, LPStart, LPText - LPStart);

          if LPText^ = TControlCharacters.Null then
            LLine := LLine + LRightSide;
        end;

        FLines[LTextLine] := LLine;

        Inc(Result);
        Inc(LTextLine);
      end;

      LTextPosition := GetPosition(FLines[LTextLine - 1].Length - LRightSide.Length + 1, LTextLine - 1);

      SelectionStartPosition := GetPosition(LLeftSide.Length + 1, LTextLineStart);
      SelectionEndPosition := LTextPosition;
    end;

    function InsertColumn: Integer;
    var
      LStr: string;
      LPText: PChar;
      LLength: Integer;
      LCurrentLine: Integer;
      LPStart: PChar;
      LInsertPosition: Integer;
      LTempString: string;
      LLineBreakPosition: TTextEditorTextPosition;
    begin
      Result := 0;

      LCurrentLine := LTextPosition.Line;
      LPStart := PChar(AValue);

      repeat
        LInsertPosition := LTextPosition.Char;

        LPText := GetEndOfLine(LPStart);

        if LPText <> LPStart then
        begin
          SetLength(LStr, LPText - LPStart);
          System.Move(LPStart^, LStr[1], (LPText - LPStart) * SizeOf(Char));

          if LCurrentLine > FLines.Count then
          begin
            Inc(Result);

            if LPText - LPStart > 0 then
            begin
              LLength := LInsertPosition - 1;

              LTempString :=
                if toTabsToSpaces in FTabs.Options then
                  StringOfChar(TCharacters.Space, LLength)
                else
                  StringOfChar(TControlCharacters.Tab, LLength div FTabs.Width) + StringOfChar(TCharacters.Space, LLength mod FTabs.Width);

              LTempString := LTempString + LStr;
            end
            else
              LTempString := '';

            FLines.Add('');

            { Reflect changes in undo list }
            if AAddToUndoList then
            begin
              LLineBreakPosition := GetPosition(FLines[LCurrentLine - 1].Length + 1, LCurrentLine);

              FUndoList.AddChange(crLineBreak, LLineBreakPosition, LLineBreakPosition, LLineBreakPosition, '', smNormal, AChangeBlockNumber);
            end;
          end
          else
          begin
            LTempString := FLines[LCurrentLine];
            LLength := LTempString.Length;

            if (LLength > 0) and (LLength < LInsertPosition) and (LPText - LPStart > 0) then
              LTempString := LTempString + StringOfChar(TCharacters.Space, LInsertPosition - LLength - 1) + LStr
            else
              Insert(LStr, LTempString, LInsertPosition);
          end;

          FLines[LCurrentLine] := LTempString;

          if FWordWrap.Active then
            FWordWrapLine.ViewLength[LCurrentLine + 1] := LTempString.Length;

          if AAddToUndoList then
            AddUndoInsert(LTextPosition, GetPosition(LTextPosition.Char, LCurrentLine),
              GetPosition(LTextPosition.Char + (LPText - LPStart), LCurrentLine), '', FSelection.ActiveMode,
              AChangeBlockNumber);
        end;

        if IsLineTerminatorCharacter(LPText^) then
        begin
          if LPText^ = TControlCharacters.CarriageReturn then
            Inc(LPText);

          if LPText^ = TControlCharacters.Linefeed then
            Inc(LPText);

          Inc(LCurrentLine);
          Inc(LTextPosition.Line);
        end;

        LPStart := LPText;
      until LPText^ = TControlCharacters.Null;

      Inc(LTextPosition.Char, LStr.Length);
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
    finally
      { Force caret reset }
      TextPosition := LTextPosition;
    end;
  end;

begin
  BeginUpdate;
  try
    LTextPosition := ATextPosition;
    LBeginTextPosition := SelectionStartPosition;
    LEndTextPosition := SelectionEndPosition;

    if not IsSamePosition(LBeginTextPosition, LEndTextPosition) then
    begin
      DeleteSelection;

      if AValue <> '' then
        LTextPosition := LBeginTextPosition
      else
        TextPosition := LBeginTextPosition;
    end;

    if AValue = '' then
      ClearSelection
    else
      InsertText;
  finally
    EndUpdate;
  end;
end;

function TCustomTextEditor.GetCaretBounds(const AViewPosition: TTextEditorViewPosition; const AMultiEdit: Boolean;
  out ACharRect: TRectF; out ABackgroundColor, AForegroundColor: TAlphaColor): TRectF;
var
  LPoint: TPointF;
  X, Y: Single;
  LCaretHeight, LCaretWidth: Single;
  LCaretStyle: TTextEditorCaretStyle;
begin
  LPoint := ViewPositionToPixels(AViewPosition);
  X := 0;
  Y := 0;
  LCaretHeight := 1;
  LCaretWidth := FPaintHelper.CharWidth;

  if AMultiEdit then
  begin
    ABackgroundColor := FColors.CaretMultiEditBackground;
    AForegroundColor := FColors.CaretMultiEditForeground;
    LCaretStyle := FCaret.MultiEdit.Style;
  end
  else
  begin
    if FCaret.NonBlinking.Active then
    begin
      ABackgroundColor := FColors.CaretNonBlinkingBackground;
      AForegroundColor := FColors.CaretNonBlinkingForeground;
    end
    else
    begin
      ABackgroundColor := FColors.EditorForeground;
      AForegroundColor := FColors.EditorBackground;
    end;

    LCaretStyle := if FOvertypeMode = omInsert then FCaret.Styles.Insert else FCaret.Styles.Overwrite;
  end;

  case LCaretStyle of
    csHorizontalLine, csThinHorizontalLine:
      begin
        if LCaretStyle = csHorizontalLine then
          LCaretHeight := 2;

        Y := GetLineHeight - LCaretHeight;

        LPoint.Y := LPoint.Y + Y;
        LPoint.X := LPoint.X + 1;
      end;
    csHalfBlock:
      begin
        LCaretHeight := GetLineHeight / 2;

        Y := GetLineHeight / 2;

        LPoint.Y := LPoint.Y + Y;
        LPoint.X := LPoint.X + 1;
      end;
    csBlock:
      begin
        LCaretHeight := GetLineHeight;

        LPoint.X := LPoint.X + 1;
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

  LPoint.X := LPoint.X + FCaret.Offsets.Left;
  LPoint.Y := LPoint.Y + FCaret.Offsets.Top;

  Result := RectF(LPoint.X, LPoint.Y, LPoint.X + LCaretWidth, LPoint.Y + LCaretHeight);

  if LCaretStyle in [csBlock, csHalfBlock] then
    ACharRect := RectF(-X, -Y, -X + FPaintHelper.CharWidth, -Y + GetLineHeight)
  else
    ACharRect := TRectF.Empty;
end;

procedure TCustomTextEditor.ApplyCaretDisplay(const ADisplay: TTextEditorCaretDisplay;
  const AViewPosition: TTextEditorViewPosition; const AMultiEdit, ABlinking: Boolean);
var
  LRect, LCharRect: TRectF;
  LBackgroundColor, LForegroundColor: TAlphaColor;
  LCaretChar: Char;
  LLineText: string;
begin
  LRect := GetCaretBounds(AViewPosition, AMultiEdit, LCharRect, LBackgroundColor, LForegroundColor);

  LCaretChar := TControlCharacters.Null;

  if not LCharRect.IsEmpty and (AViewPosition.Row >= 1) and (AViewPosition.Row <= FLines.Count) then
  begin
    LLineText := FLines[AViewPosition.Row - 1];

    if (AViewPosition.Column > 0) and (AViewPosition.Column <= LLineText.Length) then
      LCaretChar := LLineText[AViewPosition.Column];
  end;

  ADisplay.SetCaretInfo(LRect, LCaretChar, LCharRect, LBackgroundColor, LForegroundColor, FFonts.Text);
  ADisplay.ShowCaret(ABlinking, FCaret.BlinkingInterval);
end;

procedure TCustomTextEditor.UpdateMultiCaretDisplays;
var
  LIndex, LVisibleCount: Integer;
  LMultiCaretRecord: TTextEditorMultiCaretRecord;
  LDisplay: TTextEditorCaretDisplay;
begin
  LVisibleCount := 0;

  if FCaret.Visible and not (csDesigning in ComponentState) and Assigned(FMultiEdit.Carets) then
    for LIndex := 0 to FMultiEdit.Carets.Count - 1 do
    begin
      LMultiCaretRecord := FMultiEdit.Carets[LIndex]^;

      if (LMultiCaretRecord.ViewPosition.Row < FLineNumbers.TopLine) or
        (LMultiCaretRecord.ViewPosition.Row > FLineNumbers.TopLine + FLineNumbers.VisibleCount) then
        Continue;

      if not Assigned(FMultiCaretDisplays) then
        FMultiCaretDisplays := TList<TTextEditorCaretDisplay>.Create;

      if LVisibleCount < FMultiCaretDisplays.Count then
        LDisplay := FMultiCaretDisplays[LVisibleCount]
      else
      begin
        LDisplay := TTextEditorCaretDisplay.Create(Self);
        LDisplay.Parent := Self;
        FMultiCaretDisplays.Add(LDisplay);
      end;

      ApplyCaretDisplay(LDisplay, LMultiCaretRecord.ViewPosition, True, False);

      Inc(LVisibleCount);
    end;

  if Assigned(FMultiCaretDisplays) then
    for LIndex := LVisibleCount to FMultiCaretDisplays.Count - 1 do
      FMultiCaretDisplays[LIndex].HideCaret;

  if FCaret.Visible and not (csDesigning in ComponentState) and FCaret.MultiEdit.Active and
    (FMultiEdit.Position.Row <> -1) and not Assigned(FCompletionProposalPopupWindow) then
  begin
    if not Assigned(FGhostCaretDisplay) then
    begin
      FGhostCaretDisplay := TTextEditorCaretDisplay.Create(Self);
      FGhostCaretDisplay.Parent := Self;
    end;

    ApplyCaretDisplay(FGhostCaretDisplay, FMultiEdit.Position, True, False);
  end
  else
  if Assigned(FGhostCaretDisplay) then
    FGhostCaretDisplay.HideCaret;
end;

procedure TCustomTextEditor.ShowCaret;
begin
  if csDesigning in ComponentState then
    Exit;

  if not FCaret.Visible or GetSelectionAvailable or not (Focused or FCaretHelper.ShowAlways) or
    Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) then
  begin
    HideCaret;
    Exit;
  end;

  Include(FState.Flags, sfCaretVisible);

  ApplyCaretDisplay(FCaretDisplay, FViewPosition, False, not FCaret.NonBlinking.Active);
end;

procedure TCustomTextEditor.UndoItem;
var
  LTextPosition, LTempPosition: TTextEditorTextPosition;
  LChangeScrollPastEndOfLine: Boolean;
  LUndoItem: TTextEditorUndoItem;
  LMultiCaretRecord: TTextEditorMultiCaretRecord;
  LCharChange, LLineChange, LBeginX: Integer;
  LTempText: string;
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
          SelectionStartPosition := LUndoItem.ChangeBeginPosition;
          SelectionEndPosition := LUndoItem.ChangeEndPosition;
        end;
      crMultiCaret:
        if Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) then
        begin
          LMultiCaretRecord := FMultiEdit.Carets[0]^;
          LTextPosition := ViewToTextPosition(LMultiCaretRecord.ViewPosition);

          FRedoList.AddChange(LUndoItem.ChangeReason, LTextPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition, '', FSelection.ActiveMode, LUndoItem.ChangeBlockNumber);

          LCharChange := LUndoItem.ChangeCaretPosition.Char - LTextPosition.Char;
          LLineChange := LUndoItem.ChangeCaretPosition.Line - LTextPosition.Line;

          for var LIndex := 0 to FMultiEdit.Carets.Count - 1 do
          begin
            LMultiCaretRecord := FMultiEdit.Carets[LIndex]^;

            LTextPosition := ViewToTextPosition(LMultiCaretRecord.ViewPosition);
            Inc(LTextPosition.Char, LCharChange);
            Inc(LTextPosition.Line, LLineChange);
            LMultiCaretRecord.ViewPosition := TextToViewPosition(LTextPosition);
          end;
        end;
      crSelection:
        begin
          FRedoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition, '', LUndoItem.ChangeSelectionMode, LUndoItem.ChangeBlockNumber);

          SetTextPositionAndSelection(LUndoItem.ChangeBeginPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeBeginPosition);
        end;
      crInsert, crPaste, crDragDropInsert:
        begin
          SetTextPositionAndSelection(LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition, LUndoItem.ChangeEndPosition);

          LTempText := SelectedText;

          DoSelectedText(LUndoItem.ChangeSelectionMode, PChar(LUndoItem.ChangeString), False,
            LUndoItem.ChangeBeginPosition, LUndoItem.ChangeBlockNumber);

          DecCharacterCount(LTempText);

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

          FPosition.SelectionStart := LUndoItem.ChangeBeginPosition;
          FPosition.SelectionEnd := FPosition.SelectionStart;

          DoSelectedText(LUndoItem.ChangeSelectionMode, PChar(LUndoItem.ChangeString), False,
            LUndoItem.ChangeBeginPosition, LUndoItem.ChangeBlockNumber);

          IncCharacterCount(LUndoItem.ChangeString);

          FRedoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition, '', LUndoItem.ChangeSelectionMode, LUndoItem.ChangeBlockNumber);

          SetTextPositionAndSelection(LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition, LUndoItem.ChangeEndPosition);
          EnsureCursorPositionVisible;
        end;
      crLineBreak:
        begin
          TextPosition := LUndoItem.ChangeCaretPosition;

          LTempText := FLines.Strings[LUndoItem.ChangeBeginPosition.Line];

          if (LUndoItem.ChangeBeginPosition.Char - 1 > LTempText.Length) and (LeftSpaceCount(LUndoItem.ChangeString) = 0) then
            LTempText := LTempText + StringOfChar(TCharacters.Space, LUndoItem.ChangeBeginPosition.Char - 1 -
              LTempText.Length);

          SetLine(LUndoItem.ChangeBeginPosition.Line, LTempText + LUndoItem.ChangeString);
          FLines.Delete(LUndoItem.ChangeEndPosition.Line);

          FRedoList.AddChange(LUndoItem.ChangeReason, LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition, '', LUndoItem.ChangeSelectionMode, LUndoItem.ChangeBlockNumber);
        end;
      crIndent:
        begin
          SetTextPositionAndSelection(LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
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
    if Assigned(FEvents.OnChange) then
      FEvents.OnChange(Self);

    if LChangeScrollPastEndOfLine then
      FScroll.SetOption(soPastEndOfLine, False);

    if not FFile.Saved and (FUndoList.ChangeCount = 0) then
      SetModified(False);

    LUndoItem.Free;
    DecPaintLock;
  end;
end;

procedure TCustomTextEditor.UpdateCodeFoldingGutterHover(const AX: Single);
var
  LMouseOver: Boolean;
begin
  LMouseOver := (AX >= 0) and (AX < FLeftMarginWidth);

  if LMouseOver <> FCodeFoldings.MouseOverGutter then
  begin
    FCodeFoldings.MouseOverGutter := LMouseOver;

    Repaint;
  end;
end;

procedure TCustomTextEditor.DoMouseLeave;
begin
  inherited;

  if FCodeFoldings.MouseOverGutter then
  begin
    FCodeFoldings.MouseOverGutter := False;

    if FCodeFolding.Visible and FCodeFolding.AutoHide then
      Repaint;
  end;
end;

procedure TCustomTextEditor.UpdateMouseCursor;
var
  LCursorPoint: TPointF;
  LWidth: Integer;
  LMinimapLeft, LMinimapRight: Single;
  LTextPosition: TTextEditorTextPosition;
  LCursorIndex: Integer;
  LSelectionAvailable: Boolean;
  LNewCursor: TCursor;
begin
  LCursorPoint := ScreenToLocal(Screen.MousePos);

  LWidth := 0;

  if FMinimap.Align = maLeft then
    Inc(LWidth, FMinimap.GetWidth);

  if FSearch.Map.Align = saLeft then
    Inc(LWidth, FSearch.Map.GetWidth);

  GetMinimapLeftRight(LMinimapLeft, LMinimapRight);

  if (LCursorPoint.X < 0) or (LCursorPoint.Y < 0) or (LCursorPoint.X >= Width) or (LCursorPoint.Y >= Height) then
  begin
    Cursor := crDefault;
    Exit;
  end;

  if (FVerticalScrollBar.Visible and FVerticalScrollBar.BoundsRect.Contains(TPointF.Create(LCursorPoint.X, LCursorPoint.Y))) or
    (FHorizontalScrollBar.Visible and FHorizontalScrollBar.BoundsRect.Contains(TPointF.Create(LCursorPoint.X, LCursorPoint.Y))) then
  begin
    Cursor := crArrow;
    Exit;
  end;

  if FMouse.IsScrolling then
  begin
    LCursorIndex := GetMouseScrollCursorIndex;

    Cursor := if LCursorIndex = -1 then crDefault else FMouse.ScrollCursors[LCursorIndex];
  end
  else
  if (LCursorPoint.X >= LWidth) and (LCursorPoint.X < LWidth + FLeftMargin.GetWidth + FCodeFolding.GetWidth) then
    Cursor := FLeftMargin.Cursor
  else
  if FMinimap.Visible and (LCursorPoint.X > LMinimapLeft) and (LCursorPoint.X < LMinimapRight) then
    Cursor := FMinimap.Cursor
  else
  if FSearch.Map.Visible and ((FSearch.Map.Align = saRight) and
    (LCursorPoint.X > Width - FSearch.Map.GetWidth) or (FSearch.Map.Align = saLeft) and (LCursorPoint.X <= FSearch.Map.GetWidth)) then
    Cursor := FSearch.Map.Cursor
  else
  begin
    LSelectionAvailable := GetSelectionAvailable;

    if LSelectionAvailable then
      LTextPosition := PixelsToTextPosition(LCursorPoint.X, LCursorPoint.Y);

    if (eoDragDropEditing in FOptions) and not Pressed and LSelectionAvailable and IsTextPositionInSelection(LTextPosition) then
      LNewCursor := crArrow
    else
    if FRightMargin.Moving or FRightMargin.MouseOver then
      LNewCursor := FRightMargin.Cursor
    else
    if IsRulerVisible and (LCursorPoint.Y < FRuler.Height) then
      LNewCursor := FRuler.Cursor
    else
    if FMouse.OverURI then
      LNewCursor := crHandPoint
    else
    if FCodeFolding.MouseOverHint then
      LNewCursor := FCodeFolding.Hint.Cursor
    else
      LNewCursor := crIBeam;

    FKeyboardHandler.ExecuteMouseCursor(Self, LTextPosition, LNewCursor);
    Cursor := LNewCursor;
  end;
end;

{ Public declarations }

function TCustomTextEditor.GetCanFocus: Boolean;
begin
  Result := if csDesigning in ComponentState then False else inherited CanFocus;
end;

function TCustomTextEditor.CaretInView: Boolean;
var
  LCaretPoint: TPointF;
begin
  LCaretPoint := ViewPositionToPixels(ViewPosition);

  Result := PtInRect(ClientRect, LCaretPoint);
end;

function TCustomTextEditor.CreateHighlighterStream(const AName: string): TStream;
begin
  Result := nil;

  if Assigned(FEvents.OnCreateHighlighterStream) then
    FEvents.OnCreateHighlighterStream(Self, AName, Result);
end;

function TCustomTextEditor.ViewToTextPosition(const AViewPosition: TTextEditorViewPosition): TTextEditorTextPosition;
var
  LIsWrapped: Boolean;
  LRow, LPreviousLine, LResultChar, LCharsBefore, LChar: Integer;
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
      LPLine := PChar(FLines.TextLines[Result.Line - 1]);

      while (LPLine^ <> TControlCharacters.Null) and (LResultChar < Result.Char) do
      begin
        if LPLine^ = TControlCharacters.Tab then
        begin
          Dec(Result.Char, if FLines.Columns then FTabs.Width - 1 - LCharsBefore mod FTabs.Width else FTabs.Width - 1);
          Inc(LCharsBefore, if FLines.Columns then FTabs.Width - LCharsBefore mod FTabs.Width else FTabs.Width)
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
          Inc(LChar, if FLines.Columns then FTabs.Width - (LChar - 1) mod FTabs.Width else FTabs.Width)
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

function TCustomTextEditor.SelectSearchItem(const AIndex: Integer): Boolean;
var
  LSearchItem: PTextEditorSearchItem;
begin
  Result := False;

  if (FSearch.Items.Count > 0) and (AIndex >= 0) and (AIndex < FSearch.Items.Count) then
  begin
    LSearchItem := PTextEditorSearchItem(FSearch.Items.Items[AIndex]);

    GoToLineAndSetPosition(LSearchItem.BeginTextPosition.Line, LSearchItem.BeginTextPosition.Char, FSearch.ResultPosition);

    FPosition.SelectionStart := LSearchItem.BeginTextPosition;
    FPosition.SelectionEnd := LSearchItem.EndTextPosition;
    UpdateCaret;
    Repaint;

    Result := True;
  end;
end;

function TCustomTextEditor.FindFirst: Boolean;
begin
  Result := SelectSearchItem(0);
end;

function TCustomTextEditor.FindLast: Boolean;
begin
  Result := SelectSearchItem(FSearch.Items.Count - 1);
end;

function TCustomTextEditor.FindPrevious(const AHandleNotFound: Boolean = True): Boolean;
var
  LSearchItem: PTextEditorSearchItem;
begin
  Result := False;

  FSearch.ItemIndex := FSearch.GetPreviousSearchItemIndex(TextPosition);

  if FSearch.ItemIndex = -1 then
  begin
    if not AHandleNotFound or AHandleNotFound and FSearch.SearchText.IsEmpty then
      Exit;

    if soBeepIfStringNotFound in FSearch.Options then
      TextEditorBeep;

    if FSearch.Items.Count = 0 then
    begin
      if soShowSearchStringNotFound in FSearch.Options then
        DoSearchStringNotFoundDialog;
    end
    else
    if FSearch.Items.Count = 1 then
    begin
      Result := SelectSearchItem(0);
      if Result then
      begin
        TextPosition := PTextEditorSearchItem(FSearch.Items.Items[0]).BeginTextPosition;
        UpdateCaret;
      end;
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
    LSearchItem := PTextEditorSearchItem(FSearch.Items.Items[FSearch.ItemIndex]);

    GoToLineAndSetPosition(LSearchItem.BeginTextPosition.Line, LSearchItem.BeginTextPosition.Char, FSearch.ResultPosition);

    FPosition.SelectionStart := LSearchItem.BeginTextPosition;
    FPosition.SelectionEnd := LSearchItem.EndTextPosition;
    TextPosition := LSearchItem.BeginTextPosition;
    UpdateCaret;
    Repaint;

    Result := True;
  end;
end;

function TCustomTextEditor.FindNext(const AHandleNotFound: Boolean = True): Boolean;
var
  LSearchItem: PTextEditorSearchItem;
begin
  Result := False;

  FSearch.ItemIndex := FSearch.GetNextSearchItemIndex(TextPosition);

  if FSearch.ItemIndex = -1 then
  begin
    if not AHandleNotFound or AHandleNotFound and FSearch.SearchText.IsEmpty then
      Exit;

    if (soBeepIfStringNotFound in FSearch.Options) and not (soWrapAround in FSearch.Options) then
      TextEditorBeep;

    if FSearch.Items.Count = 0 then
    begin
      if soShowSearchStringNotFound in FSearch.Options then
        DoSearchStringNotFoundDialog;
    end
    else
    if FSearch.Items.Count = 1 then
    begin
      Result := SelectSearchItem(0);
      if Result then
      begin
        TextPosition := PTextEditorSearchItem(FSearch.Items.Items[0]).EndTextPosition;
        UpdateCaret;
      end;
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
    LSearchItem := PTextEditorSearchItem(FSearch.Items.Items[FSearch.ItemIndex]);

    GoToLineAndSetPosition(LSearchItem.EndTextPosition.Line, LSearchItem.EndTextPosition.Char, FSearch.ResultPosition);

    FPosition.SelectionStart := LSearchItem.BeginTextPosition;
    FPosition.SelectionEnd := LSearchItem.EndTextPosition;
    TextPosition := LSearchItem.EndTextPosition;
    UpdateCaret;
    Repaint;

    Result := True;
  end;
end;

function TCustomTextEditor.GetCompareLineNumberOffsetCache(const ALine: Integer): Integer;
begin
  Result := 0;

  if (lnoCompareMode in FLeftMargin.LineNumbers.Options) and
    (ALine >= 1) and (ALine <= Length(FCompareLineNumberOffsetCache)) then
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

function TCustomTextEditor.GetClipboardText: string;
var
  LClipboardService: IFMXClipboardService;
begin
  Result := '';

  if TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LClipboardService) then
  begin
    var LValue := LClipboardService.GetClipboard;

    if LValue.IsType<string> then
      Result := LValue.AsString;
  end;
end;

function TCustomTextEditor.GetTextPosition: TTextEditorTextPosition;
begin
  Result := ViewToTextPosition(ViewPosition);

  FPosition.Text := Result;
end;

function TCustomTextEditor.GetTextPositionOfMouse(out ATextPosition: TTextEditorTextPosition): Boolean;
var
  LCursorPoint: TPointF;
begin
  Result := False;

  LCursorPoint := ScreenToLocal(Screen.MousePos);

  if (LCursorPoint.X < 0) or (LCursorPoint.Y < 0) or (LCursorPoint.X > Self.Width) or (LCursorPoint.Y > Self.Height) then
    Exit;

  ATextPosition := PixelsToTextPosition(LCursorPoint.X, LCursorPoint.Y);

  if (ATextPosition.Line = FLines.Count - 1) and (ATextPosition.Char > FLines.TextLines[FLines.Count - 1].Length + 1) then
    Exit;

  Result := True;
end;

function TCustomTextEditor.GetWordAtPixels(const X, Y: Integer): string;
begin
  Result := WordAtTextPosition(PixelsToTextPosition(X, Y));
end;

function TCustomTextEditor.IsCommentChar(const AChar: Char): Boolean;
begin
  Result := FHighlighter.Loaded and (AChar in FHighlighter.Comments.Chars);
end;

function TCustomTextEditor.IsEmpty: Boolean;
begin
  Result := (FLines.Count = 0) or (FLines.Count = 1) and FLines[0].Trim.IsEmpty;
end;

function TCustomTextEditor.IsTextPositionInSelection(const ATextPosition: TTextEditorTextPosition): Boolean;
var
  LBeginTextPosition, LEndTextPosition: TTextEditorTextPosition;
begin
  LBeginTextPosition := SelectionStartPosition;
  LEndTextPosition := SelectionEndPosition;

  if IsSamePosition(LBeginTextPosition, LEndTextPosition) then
    Result := False
  else
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
    Result :=
      ((ATextPosition.Line > LBeginTextPosition.Line) or (ATextPosition.Line = LBeginTextPosition.Line) and (ATextPosition.Char >= LBeginTextPosition.Char)) and
      ((ATextPosition.Line < LEndTextPosition.Line) or (ATextPosition.Line = LEndTextPosition.Line) and (ATextPosition.Char < LEndTextPosition.Char));
end;

function TCustomTextEditor.ReplaceSelectedText(const AReplaceText: string; const ASearchText: string; const AAction: TTextEditorReplaceTextAction = rtaReplace): Boolean;
var
  LReplaceText: string;
  LOptions: TRegExOptions;
begin
  Result := False;

  if not SelectionAvailable then
    Exit;

  LReplaceText := AReplaceText;

  BeginUndoBlock;

  case AAction of
    rtaAddLineBreak:
      begin
        SelectedText := '';
        ExecuteCommand(TKeyCommands.LineBreak, TControlCharacters.Null, nil);
      end;
    rtaDeleteLine:
      begin
        SelectedText := '';
        ExecuteCommand(TKeyCommands.DeleteLine, 'Y', nil);
      end;
    rtaReplace:
      case FReplace.Engine of
        seNormal, seWildcard:
          SelectedText := LReplaceText;
        seExtended:
          begin
            LReplaceText := StringReplace(LReplaceText, '\r', TControlCharacters.CarriageReturn, [rfReplaceAll]);
            LReplaceText := StringReplace(LReplaceText, '\' + TControlCharacters.CarriageReturn, '\r', [rfReplaceAll]);
            LReplaceText := StringReplace(LReplaceText, '\n', TControlCharacters.LineFeed, [rfReplaceAll]);
            LReplaceText := StringReplace(LReplaceText, '\' + TControlCharacters.LineFeed, '\n', [rfReplaceAll]);
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
  end;

  EndUndoBlock;
  ResetCharacterCount;

  Result := True;
end;

function TCustomTextEditor.ReplaceText(const ASearchText: string; const AReplaceText: string; const AReplaceAll: Boolean = True; const APageIndex: Integer = -1): Integer;
var
  LTextPosition, LOriginalTextPosition: TTextEditorTextPosition;
  LIsWrapAround, LWrapAroundDisabled: Boolean;
  LReplaceTextParams: TTextEditorReplaceTextParams;
  LActionReplace: TTextEditorReplaceAction;
  LFound: Boolean;
  LSearchItem: PTextEditorSearchItem;

  function SelectionMatchesSearchItem: Boolean;
  var
    LIndex: Integer;
    LItem: PTextEditorSearchItem;
  begin
    Result := False;

    if not SelectionAvailable then
      Exit;

    if not ((TextPosition.Line = SelectionStartPosition.Line) and (TextPosition.Char = SelectionStartPosition.Char)) and
      not ((TextPosition.Line = SelectionEndPosition.Line) and (TextPosition.Char = SelectionEndPosition.Char)) then
      Exit;

    for LIndex := 0 to FSearch.Items.Count - 1 do
    begin
      LItem := PTextEditorSearchItem(FSearch.Items.Items[LIndex]);
      if (LItem.BeginTextPosition.Line = SelectionStartPosition.Line) and
        (LItem.BeginTextPosition.Char = SelectionStartPosition.Char) and
        (LItem.EndTextPosition.Line = SelectionEndPosition.Line) and
        (LItem.EndTextPosition.Char = SelectionEndPosition.Char) then
        Exit(True);
    end;
  end;
begin  if not Assigned(FSearchEngine) then
    raise ETextEditorBaseException.Create(STextEditorSearchEngineNotAssigned);

  Result := 0;

  FState.ReplaceCanceled := False;

  if ASearchText.Length = 0 then
    Exit;

  LOriginalTextPosition := TextPosition;
  LIsWrapAround := soWrapAround in FSearch.Options;
  LWrapAroundDisabled := False;

  with LReplaceTextParams do
  begin
    AddLineBreak := rtaAddLineBreak = FReplace.Action;
    Backwards := roBackwards in FReplace.Options;
    DeleteLine := rtaDeleteLine = FReplace.Action;
    Prompt := (roPrompt in FReplace.Options) and Assigned(FEvents.OnReplaceText);
    ReplaceAll := roReplaceAll in FReplace.Options;
    ReplaceText := AReplaceText;
    SearchText := ASearchText;

    if AddLineBreak then
      ReplaceTextAction := rtaAddLineBreak
    else
      ReplaceTextAction := if DeleteLine then rtaDeleteLine else rtaReplace;
  end;

  if LIsWrapAround and AReplaceAll then
  begin
    FSearch.SetOption(soWrapAround, False);
    LWrapAroundDisabled := True;
  end;

  ClearCodeFolding;

  SearchAll(ASearchText);

  if AReplaceAll then
    Result := FSearch.Items.Count
  else
    Result := 0;

  if Assigned(FEvents.OnReplaceSearchCount) then
    FEvents.OnReplaceSearchCount(Self, Result, APageIndex);

  FUndoList.BeginBlock;
  try
    if roEntireScope in FReplace.Options then
    begin
      if LReplaceTextParams.Backwards then
        MoveCaretToEnd
      else
        MoveCaretToBeginning;
    end;

    if not AReplaceAll and SelectionMatchesSearchItem then
      TextPosition := SelectionStartPosition;

    if not LReplaceTextParams.Prompt then
      BeginUpdate;

    LActionReplace := if AReplaceAll then raReplaceAll else raReplace;
    LFound := True;

    if LReplaceTextParams.Prompt then
      Result := 0;

    while LFound do
    begin
      LFound := if LReplaceTextParams.Backwards then FindPrevious(not AReplaceAll) else FindNext(not AReplaceAll);

      if not LFound then
        Exit;

      if LReplaceTextParams.Prompt and Assigned(FEvents.OnReplaceText) then
      begin
        LTextPosition := TextPosition;

        with LReplaceTextParams do
        begin
          Char := LTextPosition.Char;
          Line := LTextPosition.Line;
        end;

        LActionReplace := DoOnReplaceText(LReplaceTextParams);

        case LActionReplace of
          raCancel:
            begin
              FState.ReplaceCanceled := True;
              Exit;
            end;
          raReplaceAll:
            begin
              SearchAll(ASearchText);

              LOriginalTextPosition := LTextPosition;
              Dec(LOriginalTextPosition.Char);
              LOriginalTextPosition.Char := Max(LOriginalTextPosition.Char, 1);
            end;
        end;
      end;

      case LActionReplace of
        raSkip:
          begin
            Dec(Result);
            Continue;
          end;
        raReplaceAll:
          begin
            FLast.DeletedLine := -1;

            for var LItemIndex := FSearch.Items.Count - 1 downto 0 do
            begin
              LSearchItem := PTextEditorSearchItem(FSearch.Items.Items[LItemIndex]);

              if not (roReplaceAll in FReplace.Options) then
                if not (roEntireScope in FReplace.Options) or LReplaceTextParams.Prompt then
                  if LReplaceTextParams.Backwards and
                    ((LSearchItem.BeginTextPosition.Line > LOriginalTextPosition.Line) or
                     (LSearchItem.BeginTextPosition.Line = LOriginalTextPosition.Line) and
                     (LSearchItem.BeginTextPosition.Char > LOriginalTextPosition.Char))
                    or not LReplaceTextParams.Backwards and
                    ((LSearchItem.BeginTextPosition.Line < LOriginalTextPosition.Line) or
                     (LSearchItem.BeginTextPosition.Line = LOriginalTextPosition.Line) and
                     (LSearchItem.BeginTextPosition.Char < LOriginalTextPosition.Char)) then
                    Continue;

              SelectionStartPosition := LSearchItem.BeginTextPosition;
              SelectionEndPosition := LSearchItem.EndTextPosition;

              if not LReplaceTextParams.DeleteLine or
                LReplaceTextParams.DeleteLine and (FLast.DeletedLine <> LSearchItem.BeginTextPosition.Line) then
                ReplaceSelectedText(AReplaceText, ASearchText, LReplaceTextParams.ReplaceTextAction);

              FLast.DeletedLine := LSearchItem.BeginTextPosition.Line;
            end;

            if FReplace.Engine = seExtended then
            begin
              if AReplaceText = '\r\n' then
                FLines.SetLineBreakFlags(lbCRLF)
              else
              if AReplaceText = '\n' then
                FLines.SetLineBreakFlags(lbLF)
              else
              if AReplaceText = '\r' then
                FLines.SetLineBreakFlags(lbCR);
            end;

            Exit;
          end;
      end;

      ReplaceSelectedText(AReplaceText, ASearchText, LReplaceTextParams.ReplaceTextAction);
      Inc(Result);

      if (LActionReplace = raReplace) and LReplaceTextParams.Prompt then
      begin
        SearchAll(ASearchText);
      end;

      if (LActionReplace = raReplace) and not LReplaceTextParams.Prompt then
        Exit;
    end;
  finally
    FSearch.ClearItems;

    if LWrapAroundDisabled then
      FSearch.SetOption(soWrapAround, True);

    FUndoList.EndBlock;

    ResetCharacterCount;
    SelectionEndPosition := SelectionStartPosition;

    if LReplaceTextParams.Prompt then
    begin
      CreateLineNumbersCache(True);

      if FSyncEdit.Visible then
        DoSyncEdit;

      CodeFoldingResetCaches;
      EnsureCursorPositionVisible;
      ScanMatchingPair;
      SearchAll;

      DoChange;

      Repaint;
    end
    else
      EndUpdate;
  end;
end;

function TCustomTextEditor.SearchStatus: string;
begin
  Result := FSearchEngine.Status;
end;

procedure TCustomTextEditor.SplitTextIntoWords(const AItems: TTextEditorCompletionProposalItems; const AAddDescription: Boolean = False);
var
  LCurrentTextPosition: TTextEditorTextPosition;
  LSkipOpenKeyChars, LSkipCloseKeyChars: TTextEditorCharSet;

  procedure AddKeyChars;

    procedure Add(var AKeyChars: TTextEditorCharSet; APKey: PChar);
    begin
      while APKey^ <> TControlCharacters.Null do
      begin
        AKeyChars := AKeyChars + [APKey^];
        Inc(APKey);
      end;
    end;

  var
    LSkipRegionItem: TTextEditorSkipRegionItem;
  begin
    LSkipOpenKeyChars := [];
    LSkipCloseKeyChars := [];

    for var LIndex := 0 to FHighlighter.CompletionProposalSkipRegions.Count - 1 do
    begin
      LSkipRegionItem := FHighlighter.CompletionProposalSkipRegions[LIndex];
      Add(LSkipOpenKeyChars, PChar(LSkipRegionItem.OpenToken));
      Add(LSkipCloseKeyChars, PChar(LSkipRegionItem.CloseToken));
    end;
  end;

  procedure AddKeyword(const AKeyword: string; const ALine, AStartChar, AEndChar: Integer);
  var
    LItem: TTextEditorCompletionProposalItem;
  begin
    if (ALine = LCurrentTextPosition.Line) and (LCurrentTextPosition.Char >= AStartChar) and
      (LCurrentTextPosition.Char <= AEndChar) then
      Exit;

    LItem.Keyword := AKeyword;
    LItem.Description := if AAddDescription then STextEditorText else '';
    LItem.SnippetIndex := -1;

    if not CompletionProposalItemFound(AItems, LItem) then
      AItems.Add(LItem);
  end;

var
  LOpenTokenSkipFoldRangeList: TList;
  LTextLine: string;
  LWord: string;
  LWordStartChar: Integer;
  LPText, LPTextLineBase, LPKeyWord, LPBookmarkText: PChar;
  LSkipRegionItem: TTextEditorSkipRegionItem;
begin
  LCurrentTextPosition := TextPosition;

  AddKeyChars;

  LOpenTokenSkipFoldRangeList := TList.Create;
  try
    for var Line := 0 to FLines.Count - 1 do
    begin
      LTextLine := FLines.TextLines[Line];
      LPTextLineBase := PChar(LTextLine);
      LPText := LPTextLineBase;

      LWord := '';
      LWordStartChar := 0;

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
        for var LIndex := 0 to FHighlighter.CompletionProposalSkipRegions.Count - 1 do
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
          if LWord.IsEmpty and (LPText^ in TCharacterSets.Characters + [TCharacters.Underscore]) or
            not LWord.IsEmpty and (LPText^ in TCharacterSets.CharactersandNumbers + [TCharacters.Underscore]) then
          begin
            if LWord.IsEmpty then
              LWordStartChar := (NativeInt(LPText) - NativeInt(LPTextLineBase)) div SizeOf(Char) + 1;

            LWord := LWord + LPText^;
          end
          else
          begin
            if not LWord.IsEmpty and (LWord.Length > 1) then
              AddKeyword(LWord, Line, LWordStartChar, LWordStartChar + LWord.Length);

            LWord := '';
            LWordStartChar := 0;
          end;
        end;

        if LPText^ <> TControlCharacters.Null then
          Inc(LPText);
      end;

      if not LWord.IsEmpty and (LWord.Length > 1) then
        AddKeyword(LWord, Line, LWordStartChar, LWordStartChar + LWord.Length);
    end;
  finally
    LOpenTokenSkipFoldRangeList.Free;
  end;
end;

procedure TCustomTextEditor.AddHighlighterKeywords(const AItems: TTextEditorCompletionProposalItems; const AAddDescription: Boolean = False);
var
  LKeywordStringList: TStringList;
  LDescription: string;
  LKeyword: string;
  LChar: Char;
  LItem: TTextEditorCompletionProposalItem;
begin
  LKeywordStringList := TStringList.Create;
  try
    LDescription := '';

    if AAddDescription then
      LDescription := STextEditorKeyword;

    FHighlighter.GetKeywords(LKeywordStringList);

    for var LIndex := 0 to LKeywordStringList.Count - 1 do
    begin
      LKeyword := LKeywordStringList.Strings[LIndex];

      if LKeyword.Length > 1 then
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
  LSnippetItem: TTextEditorCompletionProposalSnippetItem;
  LItem: TTextEditorCompletionProposalItem;
begin
  for var LIndex := 0 to FCompletionProposal.Snippets.Items.Count - 1 do
  begin
    LSnippetItem := FCompletionProposal.Snippets.Item[LIndex];
    LItem.Keyword := LSnippetItem.Keyword;

    if AAddDescription then
      LItem.Description := if LSnippetItem.Description.IsEmpty then STextEditorSnippet else LSnippetItem.Description
    else
      LItem.Description := '';

    LItem.SnippetIndex := LIndex;

    if not CompletionProposalItemFound(AItems, LItem) then
      AItems.Add(LItem);
  end;
end;

function TCustomTextEditor.TextToViewPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorViewPosition;

  function GetWrapLineLength(const ARow: Integer): Integer;
  begin
    Result := if FWordWrapLine.ViewLength[ARow] <> 0 then FWordWrapLine.ViewLength[ARow] else GetVisibleChars(ARow);
  end;

var
  LIsWrapped: Boolean;
  LChar, LCurrentChar, LCharsBefore, LWordWrapLineLength, LResultChar: Integer;
  LPChar: PChar;
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
  if (AStart > 0) and (AStart <= ALine.Length) then
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
begin
  Result := 0;

  if (AStart > 0) and (AStart <= ALine.Length) then
  for var LIndex := AStart downto 2 do
  if IsWordBreakChar(ALine[LIndex - 1]) and not IsWordBreakChar(ALine[LIndex]) then
    Exit(LIndex);
end;

function TCustomTextEditor.WordEnd(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition;
var
  LTextLine: string;
begin
  Result := ATextPosition;

  if (Result.Char >= 1) and (Result.Line < FLines.Count) then
  begin
    LTextLine := FLines.TextLines[Result.Line];

    if Result.Char <= LTextLine.Length then
    begin
      Result.Char := StringWordEnd(LTextLine, Result.Char);

      if Result.Char = 0 then
        Result.Char := LTextLine.Length + 1;
    end;
  end;
end;

function TCustomTextEditor.WordStart: TTextEditorTextPosition;
begin
  Result := WordStart(TextPosition);
end;

function TCustomTextEditor.WordStart(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition;
var
  LTextLine: string;
begin
  Result := ATextPosition;

  if (Result.Line >= 0) and (Result.Line < FLines.Count) then
  begin
    LTextLine := FLines.TextLines[Result.Line];

    Result.Char := Min(Result.Char, LTextLine.Length);
    Result.Char := StringWordStart(LTextLine, Result.Char);

    if Result.Char = 0 then
      Result.Char := 1;
  end;
end;

function CompareCaretRecords(const AItem1, AItem2: PTextEditorMultiCaretRecord): Integer;
begin
  Result := AItem1^.ViewPosition.Row - AItem2^.ViewPosition.Row;

  if Result = 0 then
    Result := AItem1^.ViewPosition.Column - AItem2^.ViewPosition.Column;
end;

procedure TCustomTextEditor.AddCaret(const AViewPosition: TTextEditorViewPosition);
var
  LTextPosition: TTextEditorTextPosition;
  LNewCaret: PTextEditorMultiCaretRecord;
  LColumn, LLength: Integer;
  LInterval: Integer;
begin
  if AViewPosition.Row > FLineNumbers.Count then
    Exit;

  if not Assigned(FMultiEdit.Carets) then
  begin
    FMultiEdit.Draw := True;
    FMultiEdit.Carets := TList<PTextEditorMultiCaretRecord>.Create;
    FMultiEdit.SelectionAvailable := False;
    FMultiEdit.Timer := TTextEditorTimer.Create(Self);
    FMultiEdit.Timer.OnTimer := MultiCaretTimerHandler;

    LInterval := FCaret.BlinkingInterval;

    if LInterval > 0 then
    begin
      FMultiEdit.Timer.Interval := LInterval;
      FMultiEdit.Timer.Enabled := True;
    end;
  end;

  for var LMultiCaretRecord in FMultiEdit.Carets do
  if (LMultiCaretRecord^.ViewPosition.Row = AViewPosition.Row) and (LMultiCaretRecord^.ViewPosition.Column = AViewPosition.Column) then
    Exit;

  New(LNewCaret);

  LColumn := AViewPosition.Column;

  if not (soPastEndOfLine in FScroll.Options) then
  begin
    LTextPosition := ViewToTextPosition(AViewPosition);
    LLength := FLines.ExpandedStringLengths[LTextPosition.Line] + 1;

    if LColumn > LLength then
      LColumn := LLength;
  end;

  LNewCaret^.ViewPosition.Column := LColumn;
  LNewCaret^.ViewPosition.Row := AViewPosition.Row;

  FMultiEdit.Carets.Add(LNewCaret);
  FMultiEdit.Carets.Sort(TComparer<PTextEditorMultiCaretRecord>.Construct(CompareCaretRecords));

  HideCaret;
  UpdateMultiCaretDisplays;
end;

procedure TCustomTextEditor.AddKeyCommand(const ACommand: TTextEditorCommand; const AShift: TShiftState; const AKey: Word; const ASecondaryShift: TShiftState = []; const ASecondaryKey: Word = 0);
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
  LViewPosition: TTextEditorViewPosition;
  LBeginRow, LEndRow: Integer;
  LMultiCaretRecord: TTextEditorMultiCaretRecord;
begin
  LViewPosition := ViewPosition;

  if LViewPosition.Row > FLineNumbers.Count then
    Exit;

  if Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) then
  begin
    LMultiCaretRecord := FMultiEdit.Carets.Last^;

    LBeginRow := LMultiCaretRecord.ViewPosition.Row;
    LViewPosition.Column := LMultiCaretRecord.ViewPosition.Column;
  end
  else
    LBeginRow := LViewPosition.Row;

  LEndRow := AViewPosition.Row;

  if LBeginRow > LEndRow then
    SwapInt(LBeginRow, LEndRow);

  for var LRow := LBeginRow to LEndRow do
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

  if not FLines.Updating and not FUndoList.InsideUndoBlock then
  begin
    CreateCollapsedBackup;
    ClearCodeFolding;
  end;

  FLines.BeginUpdate;
end;

procedure TCustomTextEditor.MoveCaretToBeginning;
var
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := GetBOFPosition;

  FPosition.SelectionStart := LTextPosition;
  FPosition.SelectionEnd := LTextPosition;

  TextPosition := LTextPosition;
end;

procedure TCustomTextEditor.MoveCaretToEnd;
var
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := GetPosition(FLines[TextPosition.Line].Length + 1, FLines.Count - 1);

  FPosition.SelectionStart := LTextPosition;
  FPosition.SelectionEnd := LTextPosition;

  TextPosition := LTextPosition;
end;

procedure TCustomTextEditor.MoveSelection(const ADirection: TTextEditorMoveDirection);
var
  LSelectionStartPosition, LSelectionEndPosition: TTextEditorTextPosition;
  LIndex, LLength: Integer;
  LTrimTrailingSpaces: Boolean;
  LText: string;
  LStringList: TStringList;
  LEmptyBeginPosition, LEmptyEndPosition: TTextEditorTextPosition;
  LEmptyText, LUndoText: string;
begin
  LSelectionStartPosition := SelectionStartPosition;

  if (ADirection = mdUp) and (LSelectionStartPosition.Line = 0) or
    (ADirection = mdLeft) and (LSelectionStartPosition.Char = 1) then
    Exit;

  LSelectionEndPosition := SelectionEndPosition;
  LLength := LSelectionEndPosition.Char - LSelectionStartPosition.Char;

  if LLength < 1 then
    Exit;

  LTrimTrailingSpaces := eoTrimTrailingSpaces in FOptions;

  if LTrimTrailingSpaces then
    FOptions := FOptions - [eoTrimTrailingSpaces];

  LStringList := TStringList.Create;
  try
    LStringList.Text := SelectedText;

    for LIndex := 0 to LStringList.Count - 1 do
    begin
      LText := LStringList[LIndex];

      if LText.Length < LLength then
        LStringList[LIndex] := LText + StringOfChar(' ', LLength - LText.Length);
    end;
  finally
    LText := LStringList.Text;
    LStringList.Free;
  end;

  FUndoList.BeginBlock(6);
  try
    FUndoList.AddChange(crCaret, TextPosition, LSelectionStartPosition, LSelectionEndPosition, '', smColumn);

    case ADirection of
      mdUp:
        begin
          LEmptyBeginPosition := GetPosition(LSelectionStartPosition.Char, LSelectionEndPosition.Line);
          LEmptyEndPosition := LSelectionEndPosition;
          LEmptyText := StringOfChar(' ', LEmptyEndPosition.Char - LEmptyBeginPosition.Char);
          Dec(LSelectionStartPosition.Line);
          SelectionStartPosition := LSelectionStartPosition;
          SelectionEndPosition := LSelectionEndPosition;
          LUndoText := SelectedText;
          AddUndoDelete(TextPosition, LSelectionStartPosition, LSelectionEndPosition, LUndoText, smColumn);
          Dec(LSelectionEndPosition.Line);
        end;
      mdDown:
        begin
          LEmptyBeginPosition := LSelectionStartPosition;
          LEmptyEndPosition := GetPosition(LSelectionEndPosition.Char, LEmptyBeginPosition.Line);
          LEmptyText := StringOfChar(' ', LEmptyEndPosition.Char - LEmptyBeginPosition.Char);
          Inc(LSelectionEndPosition.Line);
          SelectionStartPosition := LSelectionStartPosition;
          SelectionEndPosition := LSelectionEndPosition;
          LUndoText := SelectedText;
          AddUndoDelete(TextPosition, LSelectionStartPosition, LSelectionEndPosition, LUndoText, smColumn);
          Inc(LSelectionStartPosition.Line);
        end;
      mdLeft:
        begin
          LEmptyBeginPosition := GetPosition(LSelectionEndPosition.Char - 1, LSelectionStartPosition.Line);
          LEmptyEndPosition := LSelectionEndPosition;

          LIndex := 0;

          while LIndex < LEmptyEndPosition.Line - LEmptyBeginPosition.Line do
          begin
            LEmptyText := ' ' + FLines.DefaultLineBreak;
            Inc(LIndex);
          end;

          LEmptyText := LEmptyText + ' ';
          Dec(LSelectionStartPosition.Char);
          SelectionStartPosition := LSelectionStartPosition;
          SelectionEndPosition := LSelectionEndPosition;
          LUndoText := SelectedText;
          AddUndoDelete(TextPosition, LSelectionStartPosition, LSelectionEndPosition, LUndoText, smColumn);
          Dec(LSelectionEndPosition.Char);
        end;
      mdRight:
        begin
          LEmptyBeginPosition := LSelectionStartPosition;
          LEmptyEndPosition := GetPosition(LSelectionStartPosition.Char + 1, LSelectionEndPosition.Line);

          LIndex := 0;

          while LIndex < LEmptyEndPosition.Line - LEmptyBeginPosition.Line do
          begin
            LEmptyText := ' ' + FLines.DefaultLineBreak;
            Inc(LIndex);
          end;

          LEmptyText := LEmptyText + ' ';
          Inc(LSelectionEndPosition.Char);
          SelectionStartPosition := LSelectionStartPosition;
          SelectionEndPosition := LSelectionEndPosition;
          LUndoText := SelectedText;
          AddUndoDelete(TextPosition, LSelectionStartPosition, LSelectionEndPosition, LUndoText, smColumn);
          Inc(LSelectionStartPosition.Char);
        end;
    end;

    AddUndoInsert(TextPosition, LEmptyBeginPosition, LEmptyEndPosition, '', smColumn);
    InsertBlock(LEmptyBeginPosition, LEmptyEndPosition, PChar(LEmptyText), False);

    AddUndoInsert(TextPosition, LSelectionStartPosition, LSelectionEndPosition, '', smColumn);
    InsertBlock(LSelectionStartPosition, LSelectionEndPosition, PChar(LText), False);

    SelectionStartPosition := LSelectionStartPosition;
    SelectionEndPosition := LSelectionEndPosition;
  finally
    FUndoList.EndBlock;
  end;

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
  end;
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
  if FLines.Updating then
    Exit;

  FCodeFoldings.AllRanges.ClearAll;

  SetLength(FCodeFoldings.TreeLine, 0);
  SetLength(FCodeFoldings.RangeFromLine, 0);
  SetLength(FCodeFoldings.RangeToLine, 0);
end;

procedure TCustomTextEditor.ClearHighlightLine;
begin
  if Assigned(FHighlightLine) then
  for var LIndex := FHighlightLine.Items.Count - 1 downto 0 do
  if hlDeleteOnHighlighterLoad in FHighlightLine.Item[LIndex].Options then
    FHighlightLine.Items.Delete(LIndex);
end;

procedure TCustomTextEditor.ClearMatchingPair;
begin
  FMatchingPair.Current := trNotFound;
end;

procedure TCustomTextEditor.ClearSelection;
begin
  if GetSelectionAvailable then
    FPosition.SelectionEnd := FPosition.SelectionStart;
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
begin
  if not FCaret.MultiEdit.Active then
    Exit;

  for var LIndex := 0 to FSearch.Items.Count - 1 do
    AddCaret(TextToViewPosition(PTextEditorSearchItem(FSearch.Items.Items[LIndex])^.EndTextPosition));

  FPosition.SelectionEnd := FPosition.SelectionStart;

  Repaint;
  SetFocus;
end;

procedure TCustomTextEditor.EnsureCaretPositionInsideLines(const ATextPosition: TTextEditorTextPosition);
var
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := ATextPosition;

  if LTextPosition.Line > FLines.Count - 1 then
    LTextPosition.Line := FLines.Count - 1;

  TextPosition := LTextPosition;
end;

procedure TCustomTextEditor.CollapseAll(const AFromLineNumber: Integer = -1; const AToLineNumber: Integer = -1);
var
  LTextPosition: TTextEditorTextPosition;
  LFromLine, LToLine: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  LFromLine := if AFromLineNumber = -1 then 1 else AFromLineNumber;
  LToLine := if AToLineNumber = -1 then FLines.Count else AToLineNumber;
  LTextPosition := TextPosition;

  ClearMatchingPair;
  FLineNumbers.ResetCache := True;

  for var LIndex := LFromLine to LToLine do
  begin
    LCodeFoldingRange := FCodeFoldings.RangeFromLine[LIndex];

    if Assigned(LCodeFoldingRange) and not LCodeFoldingRange.Collapsed and LCodeFoldingRange.Collapsable then
    begin
      LCodeFoldingRange.Collapsed := True;
      LCodeFoldingRange.SetParentCollapsedOfSubCodeFoldingRanges(True, LCodeFoldingRange.FoldRangeLevel);

      FCodeFoldings.AnyCollapsed := True;
    end;
  end;

  CheckIfAtMatchingKeywords;
  UpdateScrollBars;
  EnsureCaretPositionInsideLines(LTextPosition);
end;

procedure TCustomTextEditor.CollapseAllByLevel(const AFromLevel: Integer; const AToLevel: Integer);
var
  LTextPosition: TTextEditorTextPosition;
  LFromLine, LToLine: Integer;
  LLevel: Integer;
  LRangeLevel: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  if SelectionAvailable then
  begin
    LFromLine := SelectionStartPosition.Line;
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

  for var LIndex := LFromLine to LToLine do
  begin
    LCodeFoldingRange := FCodeFoldings.RangeFromLine[LIndex];

    if Assigned(LCodeFoldingRange) then
    begin
      if LLevel = -1 then
        LLevel := LCodeFoldingRange.FoldRangeLevel;

      LRangeLevel := LCodeFoldingRange.FoldRangeLevel - LLevel;

      if (LRangeLevel >= AFromLevel) and (LRangeLevel <= AToLevel) and not LCodeFoldingRange.Collapsed and
        LCodeFoldingRange.Collapsable then
      begin
        LCodeFoldingRange.Collapsed := True;
        LCodeFoldingRange.SetParentCollapsedOfSubCodeFoldingRanges(True, LCodeFoldingRange.FoldRangeLevel);

        FCodeFoldings.AnyCollapsed := True;
      end;
    end;
  end;

  CheckIfAtMatchingKeywords;
  UpdateScrollBars;
  EnsureCaretPositionInsideLines(LTextPosition);
end;

procedure TCustomTextEditor.TrimText(const ATrimStyle: TTextEditorTrimStyle);
var
  LTextPosition: TTextEditorTextPosition;
  LBeginPosition, LEndPosition: TTextEditorTextPosition;
  LText: string;
  LSelectionAvailable: Boolean;
  LLines: TTextEditorLines;
  LTempTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := TextPosition;

  LBeginPosition.Line := 0;
  LEndPosition.Line := FLines.Count - 1;

  LText := FLines.Text;
  LSelectionAvailable := GetSelectionAvailable;

  if LSelectionAvailable then
  begin
    LBeginPosition.Line := GetSelectionStartPosition.Line;
    LEndPosition := GetSelectionEndPosition;

    if LEndPosition.Char = 1 then
      Dec(LEndPosition.Line);

    LText := SelectedText;
  end;

  LBeginPosition.Char := 1;
  LEndPosition.Char := FLines.StringLength(LEndPosition.Line) + 1;

  FUndoList.BeginBlock;
  try
    if FSelection.ActiveMode = smNormal then
    begin
      if not LSelectionAvailable then
        FUndoList.AddChange(crSelection, LTextPosition, LTextPosition, LTextPosition, '', FSelection.ActiveMode);

      AddUndoDelete(LTextPosition, LBeginPosition, LEndPosition, LText, FSelection.ActiveMode);

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
      AddUndoInsert(LTextPosition, LBeginPosition, LEndPosition, '', FSelection.ActiveMode);

      if LSelectionAvailable then
      begin
        LTempTextPosition := GetSelectionStartPosition;

        LTempTextPosition.Char := 1;
        SelectionStartPosition := LTempTextPosition;
        SelectionEndPosition := LEndPosition;
      end;
    end;
  finally
    FUndoList.EndBlock;
  end;

  DoChange;
  Repaint;
end;

procedure TCustomTextEditor.TrimBeginning;
begin
  while FLines.Count > 0 do
  if FLines[0].Trim.IsEmpty then
    FLines.Delete(0);
end;

procedure TCustomTextEditor.TrimEnd;
begin
  for var LIndex := FLines.Count - 1 downto 0 do
  if FLines[LIndex].Trim.IsEmpty then
    FLines.Delete(LIndex)
  else
    Break;
end;

procedure TCustomTextEditor.ExpandAll(const AFromLineNumber: Integer = -1; const AToLineNumber: Integer = -1);
var
  LFromLine, LToLine: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  LFromLine := if AFromLineNumber = -1 then 0 else AFromLineNumber;
  LToLine := if AToLineNumber = -1 then FLines.Count else AToLineNumber;

  ClearMatchingPair;
  FLineNumbers.ResetCache := True;

  if Length(FCodeFoldings.RangeFromLine) > 0 then
  for var LIndex := LFromLine to LToLine do
  begin
    LCodeFoldingRange := FCodeFoldings.RangeFromLine[LIndex];

    if Assigned(LCodeFoldingRange) then
      if LCodeFoldingRange.Collapsed and LCodeFoldingRange.Collapsable then
      begin
        LCodeFoldingRange.Collapsed := False;
        LCodeFoldingRange.SetParentCollapsedOfSubCodeFoldingRanges(False, LCodeFoldingRange.FoldRangeLevel);
      end;
  end;

  FCodeFoldings.AnyCollapsed := False;

  CreateLineNumbersCache(True);

  UpdateScrollBars;
  Repaint;
end;

procedure TCustomTextEditor.ExpandAllByLevel(const AFromLevel: Integer; const AToLevel: Integer);
var
  LFromLine, LToLine: Integer;
  LLevel, LRangeLevel: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  if SelectionAvailable then
  begin
    LFromLine := SelectionStartPosition.Line;
    LToLine := SelectionEndPosition.Line;
  end
  else
  begin
    LFromLine := 1;
    LToLine := FLines.Count;
  end;

  ClearMatchingPair;
  FLineNumbers.ResetCache := True;

  if Length(FCodeFoldings.RangeFromLine) > 0 then
  begin
    LLevel := -1;

    for var LIndex := LFromLine to LToLine do
    begin
      LCodeFoldingRange := FCodeFoldings.RangeFromLine[LIndex];

      if Assigned(LCodeFoldingRange) then
      begin
        if LLevel = -1 then
          LLevel := LCodeFoldingRange.FoldRangeLevel;

        LRangeLevel := LCodeFoldingRange.FoldRangeLevel - LLevel;

        if LCodeFoldingRange.Collapsed and LCodeFoldingRange.Collapsable and
          (LRangeLevel >= AFromLevel) and (LRangeLevel <= AToLevel) then
        begin
          LCodeFoldingRange.Collapsed := False;
          LCodeFoldingRange.SetParentCollapsedOfSubCodeFoldingRanges(False, LCodeFoldingRange.FoldRangeLevel);
        end;
      end;
    end;
  end;

  FCodeFoldings.AnyCollapsed := IsAnyFoldingCollapsed;

  CreateLineNumbersCache(True);

  UpdateScrollBars;
  Repaint;
end;

procedure TCustomTextEditor.CommandProcessor(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);

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

var
  LCommand: TTextEditorCommand;
  LChar: Char;
  LSelectionAvailable, LUndo: Boolean;
  LBackspaceCount, LCollapsedCount: Integer;
  LTextPosition: TTextEditorTextPosition;
  LViewPosition: TTextEditorViewPosition;
  LOldSelectionStartPosition, LOldSelectionEndPosition: TTextEditorTextPosition;
  LMultiCaretRecord: PTextEditorMultiCaretRecord;
  LLength, LRows, LPasteRows, LSpaceCount: Integer;
  LStringList: TStringList;
  LLineSelectionStart, LLineSelectionEnd: Integer;
  LLineText: string;
begin
  LCommand := ACommand;
  LChar := AChar;
  LSelectionAvailable := False;
  LBackspaceCount := 1;

  { First the program event handler gets a chance to process the command }
  DoOnProcessCommand(LCommand, LChar, AData);

  if LCommand <> TKeyCommands.None then
  begin
    { Notify hooked command handlers before the command is executed inside of the class }
    NotifyHookedCommandHandlers(False, LCommand, LChar, AData);

    if IsCodeFoldingVisible then
    begin
      FCodeFoldings.Rescan := (LCommand = TKeyCommands.Cut) or (LCommand = TKeyCommands.Paste) or (LCommand = TKeyCommands.DeleteLine) or
        GetSelectionAvailable and (LCommand = TKeyCommands.LineBreak) or
        IsKeywordAtCaretPosition and ((LCommand = TKeyCommands.Char) or (LCommand = TKeyCommands.Tab) or (LCommand = TKeyCommands.DeleteChar) or
        (LCommand = TKeyCommands.LineBreak)) or
        ((LCommand = TKeyCommands.Char) and (AChar in FHighlighter.SkipOpenKeyChars + FHighlighter.SkipCloseKeyChars));

      case LCommand of
        TKeyCommands.Backspace, TKeyCommands.DeleteChar, TKeyCommands.DeleteWord, TKeyCommands.DeleteWordForward,
        TKeyCommands.DeleteWordBackward, TKeyCommands.DeleteLine, TKeyCommands.Clear, TKeyCommands.LineBreak,
        TKeyCommands.Char, TKeyCommands.Text, TKeyCommands.ImeStr, TKeyCommands.Cut, TKeyCommands.Paste,
        TKeyCommands.BlockIndent, TKeyCommands.BlockUnindent, TKeyCommands.Tab:
          if GetSelectionAvailable then
          begin
            LOldSelectionStartPosition := GetSelectionStartPosition;
            LOldSelectionEndPosition := GetSelectionEndPosition;
            LCollapsedCount := 0;

            for var LLine := LOldSelectionStartPosition.Line to LOldSelectionEndPosition.Line do
              LCollapsedCount := CodeFoldingExpandLine(LLine + 1);

            FPosition.SelectionStart := LOldSelectionStartPosition;
            FPosition.SelectionEnd := LOldSelectionEndPosition;

            if LCollapsedCount <> 0 then
            begin
              Inc(FPosition.SelectionEnd.Line, LCollapsedCount);
              FPosition.SelectionEnd.Char := FLines[FPosition.SelectionEnd.Line].Length + 1;
            end;
          end
          else
            CodeFoldingExpandLine(FPosition.Text.Line + 1);
      end;
    end;

    if Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) then
    begin
      LUndo := False;

      FUndoList.BeginBlock(8);
      try
        LMultiCaretRecord := FMultiEdit.Carets[0];
        LTextPosition := ViewToTextPosition(LMultiCaretRecord^.ViewPosition);

        FUndoList.AddChange(crMultiCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);

        if FMultiEdit.SelectionAvailable then
        case LCommand of
          TKeyCommands.Tab:
            Exit;
          TKeyCommands.Copy:
            begin
              ExecuteCommand(LCommand, LChar, AData);
              Exit;
            end;
        end;

        case LCommand of
          TKeyCommands.Char, TKeyCommands.Backspace, TKeyCommands.Tab, TKeyCommands.LineBegin, TKeyCommands.LineEnd,
          TKeyCommands.Cut, TKeyCommands.Paste, TKeyCommands.Left, TKeyCommands.SelectionLeft, TKeyCommands.Right,
          TKeyCommands.SelectionRight, TKeyCommands.SelectionLineBegin, TKeyCommands.SelectionLineEnd:
            begin
              LLength := if FMultiEdit.SelectionAvailable then 0 else 1;
              LRows := 0;

              if (LCommand = TKeyCommands.Paste) and CanPaste then
              begin
                LStringList := TStringList.Create;
                try
                  LStringList.Text := GetClipboardText;

                  if not Trim(LStringList.Text).IsEmpty then
                  begin
                    LRows := LStringList.Count - 1;
                    LLength := LStringList[LStringList.Count - 1].Length;
                  end;
                finally
                  LStringList.Free;
                end;
              end;

              LPasteRows := LRows;

              if (LCommand in [TKeyCommands.SelectionLeft, TKeyCommands.SelectionRight, TKeyCommands.SelectionLineBegin,
                TKeyCommands.SelectionLineEnd]) and not FMultiEdit.SelectionAvailable then
              begin
                FMultiEdit.SelectionAvailable := True;

                for var LIndex := 0 to FMultiEdit.Carets.Count - 1 do
                begin
                  LMultiCaretRecord := FMultiEdit.Carets[LIndex];

                  LTextPosition := ViewToTextPosition(LMultiCaretRecord^.ViewPosition);

                  LMultiCaretRecord^.SelectionStart.Char := LTextPosition.Char;
                  LMultiCaretRecord^.SelectionStart.Line := LTextPosition.Line;
                end;
              end
              else
              if LCommand in [TKeyCommands.Left, TKeyCommands.Right] then
                FMultiEdit.SelectionAvailable := False;

              for var LIndex1 := FMultiEdit.Carets.Count - 1 downto 0 do
              case LCommand of
                TKeyCommands.Char, TKeyCommands.Cut, TKeyCommands.Tab, TKeyCommands.Backspace, TKeyCommands.Paste:
                  begin
                    LMultiCaretRecord := FMultiEdit.Carets[LIndex1];

                    LViewPosition := LMultiCaretRecord^.ViewPosition;

                    ViewPosition := LViewPosition;
                    LBackspaceCount := LViewPosition.Column;

                    if LCommand = TKeyCommands.Tab then
                    begin
                      LTextPosition := ViewToTextPosition(LMultiCaretRecord^.ViewPosition);
                      LLength := GetTabText(LTextPosition).Length;
                    end;

                    ExecuteCommand(LCommand, LChar, AData);

                    Dec(LBackspaceCount, ViewPosition.Column);
                    LSelectionAvailable := FMultiEdit.SelectionAvailable;

                    if LSelectionAvailable then
                    begin
                      for var LIndex2 := FMultiEdit.Carets.Count - 1 downto 0 do
                      begin
                        LMultiCaretRecord := FMultiEdit.Carets[LIndex2];

                        LLineSelectionStart := LMultiCaretRecord^.SelectionStart.Char;
                        LLineSelectionEnd := LMultiCaretRecord^.ViewPosition.Column;

                        if LLineSelectionStart > LLineSelectionEnd then
                          SwapInt(LLineSelectionStart, LLineSelectionEnd);

                        LMultiCaretRecord^.ViewPosition := GetViewPosition(LLineSelectionStart, LMultiCaretRecord^.ViewPosition.Row);

                        case LCommand of
                          TKeyCommands.Paste:
                            Inc(LMultiCaretRecord^.ViewPosition.Column, LLength);
                          TKeyCommands.Char, TKeyCommands.Tab:
                            Inc(LMultiCaretRecord^.ViewPosition.Column);
                        end;
                      end;

                      FMultiEdit.SelectionAvailable := False;
                      Break;
                    end;
                  end;
                TKeyCommands.Right, TKeyCommands.SelectionRight:
                  begin
                    LMultiCaretRecord := FMultiEdit.Carets[LIndex1];
                    Inc(LMultiCaretRecord^.ViewPosition.Column);
                  end;
                TKeyCommands.Left, TKeyCommands.SelectionLeft:
                  begin
                    LMultiCaretRecord := FMultiEdit.Carets[LIndex1];

                    if LMultiCaretRecord^.ViewPosition.Column > 1 then
                      Dec(LMultiCaretRecord^.ViewPosition.Column);
                  end;
              end;

              if FMultiEdit.Carets.Count > 0 then
              case LCommand of
                TKeyCommands.Char, TKeyCommands.Paste, TKeyCommands.Backspace, TKeyCommands.Tab, TKeyCommands.LineBegin,
                TKeyCommands.LineEnd, TKeyCommands.SelectionLineBegin, TKeyCommands.SelectionLineEnd:
                  begin
                    for var LIndex2 := 0 to FMultiEdit.Carets.Count - 1 do
                    begin
                      LMultiCaretRecord := FMultiEdit.Carets[LIndex2];

                      case LCommand of
                        TKeyCommands.Char, TKeyCommands.Tab, TKeyCommands.Paste, TKeyCommands.Backspace:
                          case LCommand of
                            TKeyCommands.Char, TKeyCommands.Tab:
                              Inc(LMultiCaretRecord^.ViewPosition.Column, LLength);
                            TKeyCommands.Backspace:
                              if not LSelectionAvailable and (LMultiCaretRecord^.ViewPosition.Column > 1) then
                                Dec(LMultiCaretRecord^.ViewPosition.Column, LBackspaceCount);
                            TKeyCommands.Paste:
                              begin
                                LMultiCaretRecord^.ViewPosition.Column := LLength + 1;
                                Inc(LMultiCaretRecord^.ViewPosition.Row, LRows);
                                Inc(LRows, LPasteRows);
                              end;
                          end;
                        TKeyCommands.LineBegin:
                          begin
                            LTextPosition := ViewToTextPosition(LMultiCaretRecord^.ViewPosition);

                            LLineText := FLines[LTextPosition.Line];
                            LSpaceCount := LeftSpaceCount(LLineText) + 1;

                            if LTextPosition.Char <= LSpaceCount then
                              LSpaceCount := 1;

                            LMultiCaretRecord^.ViewPosition.Column := LSpaceCount;
                          end;
                        TKeyCommands.SelectionLineBegin:
                          LMultiCaretRecord^.ViewPosition.Column := 1;
                        TKeyCommands.LineEnd, TKeyCommands.SelectionLineEnd:
                          LMultiCaretRecord^.ViewPosition.Column := FLines.ExpandedStringLengths[LMultiCaretRecord^.ViewPosition.Row - 1] + 1;
                      end;
                    end;

                    if Assigned(FEvents.OnMultiCaretChanged) then
                      FEvents.OnMultiCaretChanged(Self);
                  end;
              end;
            end;
          TKeyCommands.Undo:
            begin
              FreeMultiCarets;
              ExecuteCommand(LCommand, LChar, AData);
              LUndo := True;
            end;
        end;
      finally
        FUndoList.EndBlock;

        if LUndo then
        begin
          if FHighlighter.Loaded then
            RescanHighlighterRanges;

          InitCodeFolding;
        end;
      end;

      ValidateMultiCarets;
      UpdateMultiCaretDisplays;
      Repaint;
    end
    else
    if LCommand < TKeyCommands.UserFirst then
      ExecuteCommand(LCommand, LChar, AData);

    { Notify hooked command handlers after the command was executed inside of the class }
    NotifyHookedCommandHandlers(True, LCommand, LChar, AData);
  end;

  DoOnCommandProcessed(LCommand, LChar, AData);

  case LCommand of
    TKeyCommands.Backspace, TKeyCommands.DeleteChar, TKeyCommands.DeleteWord, TKeyCommands.DeleteWhitespaceForward,
    TKeyCommands.DeleteWhitespaceBackward, TKeyCommands.DeleteWordForward, TKeyCommands.DeleteWordBackward,
    TKeyCommands.DeleteBeginningOfLine, TKeyCommands.DeleteEndOfLine, TKeyCommands.DeleteLine, TKeyCommands.Clear,
    TKeyCommands.LineBreak, TKeyCommands.InsertLine, TKeyCommands.Char, TKeyCommands.Text, TKeyCommands.ImeStr,
    TKeyCommands.Undo, TKeyCommands.Redo, TKeyCommands.Cut, TKeyCommands.Paste, TKeyCommands.BlockIndent,
    TKeyCommands.BlockUnindent, TKeyCommands.Tab, TKeyCommands.ShiftTab, TKeyCommands.UpperCase, TKeyCommands.LowerCase,
    TKeyCommands.AlternatingCase, TKeyCommands.SentenceCase, TKeyCommands.TitleCase, TKeyCommands.KeywordsUpperCase,
    TKeyCommands.KeywordsLowerCase, TKeyCommands.KeywordsTitleCase, TKeyCommands.UpperCaseBlock,
    TKeyCommands.LowerCaseBlock, TKeyCommands.AlternatingCaseBlock, TKeyCommands.MoveLinesUp, TKeyCommands.MoveLinesDown,
    TKeyCommands.LineComment, TKeyCommands.BlockComment:
      DoChange;
  end;
end;

function TCustomTextEditor.GetMultiCaretSelectedText: string;
var
  LLastLine, LIndex: Integer;
  LMultiCaretRecord: TTextEditorMultiCaretRecord;
  LLine, LChar: Integer;
begin
  Result := '';

  if Assigned(FMultiEdit.Carets) and FMultiEdit.SelectionAvailable and (FMultiEdit.Carets.Count > 0) then
  begin
    LLastLine := -1;
    LIndex := 0;

    while LIndex < FMultiEdit.Carets.Count do
    begin
      LMultiCaretRecord := FMultiEdit.Carets[LIndex]^;

      LLine := LMultiCaretRecord.SelectionStart.Line;
      LChar := LMultiCaretRecord.SelectionStart.Char;

      if LLastLine = -1 then
        LLastLine := LLine
      else
      if LLastLine <> LLine then
      begin
        Result := Result + sLineBreak;

        LLastLine := LLine;
      end;

      Result := Result + Copy(FLines[LLine], LChar, Abs(LChar - LMultiCaretRecord.ViewPosition.Column));

      Inc(LIndex);
    end;
  end;
end;

procedure TCustomTextEditor.CopyToClipboard(const AWithLineNumbers: Boolean = False);
var
  LText: string;
  LChangeTrim: Boolean;
  LSelectionStartPosition, LSelectionEndPosition, LOldSelectionEndPosition: TTextEditorTextPosition;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
  LStringList: TStringList;
  LLineBreak: string;
  LLineNumber: Integer;
begin
  if FMultiEdit.SelectionAvailable then
  begin
    LText := GetMultiCaretSelectedText;

    DoCopyToClipboard(LText);
  end
  else
  if GetSelectionAvailable then
  begin
    AutoCursor;

    LChangeTrim := (FSelection.ActiveMode = smColumn) and (eoTrimTrailingSpaces in Options);
    LSelectionStartPosition := SelectionStartPosition;
    LSelectionEndPosition := SelectionEndPosition;
    try
      if LChangeTrim then
        Exclude(FOptions, eoTrimTrailingSpaces);

      LOldSelectionEndPosition := LSelectionEndPosition;

      if IsCodeFoldingVisible then
      begin
        LCodeFoldingRange := FCodeFoldings.RangeFromLine[LSelectionEndPosition.Line + 1];

        if Assigned(LCodeFoldingRange) and LCodeFoldingRange.Collapsed then
          FPosition.SelectionEnd := GetPosition(FLines[LCodeFoldingRange.ToLine - 1].Length + 1, LCodeFoldingRange.ToLine - 1);

        LSelectionEndPosition := FPosition.SelectionEnd;
      end;

      LText :=
        if (LSelectionStartPosition.Line = 0) and (LSelectionStartPosition.Char = 1) and
          (LSelectionEndPosition.Line = FLines.Count - 1) and (LSelectionEndPosition.Char = FLines[LSelectionEndPosition.Line].Length + 1) and
          not FLines.ContainsFlag(sfEmptyLine) then
          FLines.Text
        else
          SelectedText;

      LText := StringReplace(LText, TControlCharacters.Substitute, TControlCharacters.Null, [rfReplaceAll]);

      if AWithLineNumbers then
      begin
        LStringList := TStringList.Create;
        try
          LStringList.Text := LText;
          LText := '';

          LLineBreak := FLines.DefaultLineBreak;
          LLineNumber := LSelectionStartPosition.Line + FLeftMargin.LineNumbers.StartFrom;

          for var LIndex := 0 to LStringList.Count - 1 do
          begin
            LText := LText + IntToStr(LLineNumber).PadLeft(LSelectionEndPosition.Line.ToString.Length) + ': ' +
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

      FPosition.SelectionStart := LSelectionStartPosition;
      FPosition.SelectionEnd := LOldSelectionEndPosition;
    finally
      if LChangeTrim then
        Include(FOptions, eoTrimTrailingSpaces);
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
    FPosition.SelectionStart := GetPosition(1, ALineNumber - 1);
    FPosition.SelectionEnd := GetPosition(1, ALineNumber + ACount - 1);
  end
  else
  begin
    FPosition.SelectionStart := GetPosition(FLines.StringLength(ALineNumber - 2) + 1, ALineNumber - 2);
    FPosition.SelectionEnd := GetPosition(FLines.StringLength(FLines.Count - 1) + 1, FLines.Count - 1);
  end;

  BeginUpdate;
  try
    SetSelectedTextEmpty;
  finally
    EndUpdate;
  end;
end;

procedure TCustomTextEditor.DeleteWhitespace;
begin
  if ReadOnly then
    Exit;

  FUndoList.BeginBlock;
  try
    if GetSelectionAvailable then
      SelectedText := FMX.TextEditor.Utils.DeleteWhitespace(SelectedText)
    else
    begin
      SelectAll;
      SelectedText := FMX.TextEditor.Utils.DeleteWhitespace(Text);
    end;

    MoveCaretToBeginning;
  finally
    FUndoList.EndBlock;
    DoChange;
  end;
end;

// TODO
procedure TCustomTextEditor.DragDrop(const AData: TDragObject; const APoint: TPointF);
var
  ASource: TObject;
  X, Y: Integer;
  LTextPosition, LNewCaretPosition: TTextEditorTextPosition;
  LDoDrop, LDropAfter, LDropMove: Boolean;
  LSelectionStartPosition, LSelectionEndPosition: TTextEditorTextPosition;
  LDragDropText: string;
  LLinesDeleted: Integer;
  LChangeScrollPastEndOfLine: Boolean;
begin
  ASource := AData.Source;
  X := Round(APoint.X);
  Y := Round(APoint.Y);

  if not ReadOnly and (ASource is TCustomTextEditor) and TCustomTextEditor(ASource).SelectionAvailable then
  begin
    IncPaintLock;
    try
      inherited;

      LNewCaretPosition := PixelsToTextPosition(X, Y);

      if ASource = Self then
      begin
        LDropMove := True;

        LSelectionStartPosition := SelectionStartPosition;
        LSelectionEndPosition := SelectionEndPosition;
        LDropAfter := (LNewCaretPosition.Line > LSelectionEndPosition.Line) or
          ((LNewCaretPosition.Line = LSelectionEndPosition.Line) and
          ((LNewCaretPosition.Char > LSelectionEndPosition.Char) or
          (not LDropMove and (LNewCaretPosition.Char = LSelectionEndPosition.Char))));
        LDoDrop := LDropAfter or (LNewCaretPosition.Line < LSelectionStartPosition.Line) or
          ((LNewCaretPosition.Line = LSelectionStartPosition.Line) and
          ((LNewCaretPosition.Char < LSelectionStartPosition.Char) or
          (not LDropMove and (LNewCaretPosition.Char = LSelectionStartPosition.Char))));
      end
      else
      begin
        LDropMove := False;

        LDoDrop := True;
        LDropAfter := False;
      end;

      if LDoDrop then
      begin
        FUndoList.BeginBlock;
        try
          LTextPosition := TextPosition;

          FUndoList.AddChange(crCaret, LSelectionStartPosition, LSelectionStartPosition, LSelectionEndPosition, '',
            FSelection.ActiveMode);

          LDragDropText := TCustomTextEditor(ASource).SelectedText;

          if LDropMove then
          begin
            LLinesDeleted := LSelectionEndPosition.Line - LSelectionStartPosition.Line;

            if ASource = Self then
              SetSelectedTextEmpty
            else
            if ASource is TCustomTextEditor then
              TCustomTextEditor(ASource).SetSelectedTextEmpty;

            if LDropAfter then
            begin
              LNewCaretPosition.Line := LNewCaretPosition.Line - LLinesDeleted;

              if LSelectionStartPosition.Line = LSelectionEndPosition.Line then
                LNewCaretPosition.Char := LNewCaretPosition.Char - LDragDropText.Length;
            end;
          end;

          LChangeScrollPastEndOfLine := not (soPastEndOfLine in FScroll.Options);
          try
            if LChangeScrollPastEndOfLine then
              FScroll.SetOption(soPastEndOfLine, True);

            TextPosition := LNewCaretPosition;

            DoInsertText(LDragDropText);

            FPosition.SelectionStart := LNewCaretPosition;

            FPosition.SelectionEnd.Char :=
              if LSelectionStartPosition.Line = LSelectionEndPosition.Line then
                LNewCaretPosition.Char + LSelectionEndPosition.Char - LSelectionStartPosition.Char
              else
                LSelectionEndPosition.Char;

            FPosition.SelectionEnd.Line := LNewCaretPosition.Line + LSelectionEndPosition.Line - LSelectionStartPosition.Line;
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

  if not FLines.Updating and not FUndoList.InsideUndoBlock then
  begin
    if FSyncEdit.Visible then
      DoSyncEdit;

    if FHighlighter.Loaded then
      RescanHighlighterRanges;

    InitCodeFolding;
    RestoreCollapsedBackup;
    CreateLineNumbersCache(True);
    UpdateScrollBars;

    EnsureCursorPositionVisible;
    ScanMatchingPair;
    SearchAll;

    DoChange;

    Repaint;
  end;
end;

procedure TCustomTextEditor.EnsureCursorPositionVisible(const AForceToMiddle: Boolean = False; const AEvenIfVisible: Boolean = False);
var
  LPoint: TPointF;
  LLeftMarginWidth, LCaretRow, LMiddle: Integer;
begin
  if csDesigning in ComponentState then
    Exit;

  if (FScrollHelper.PageWidth <= 0) or not HandleAllocated then
    Exit;

  IncPaintLock;
  try
    LPoint := ViewPositionToPixels(ViewPosition);
    LLeftMarginWidth := GetLeftMarginWidth;
    LCaretRow := FViewPosition.Row;

    FScrollHelper.PageWidth := GetScrollPageWidth;

    if AForceToMiddle then
    begin
      if LCaretRow < TopLine - 1 then
      begin
        LMiddle := FLineNumbers.VisibleCount shr 1;

        TopLine := if LCaretRow - LMiddle < 0 then 1 else LCaretRow - LMiddle + 1;
      end
      else
      if LCaretRow > TopLine + FLineNumbers.VisibleCount - 2 then
      begin
        LMiddle := FLineNumbers.VisibleCount shr 1;
        TopLine := LCaretRow - FLineNumbers.VisibleCount - 1 + LMiddle;
      end
      else
      if AEvenIfVisible then
      begin
        LMiddle := FLineNumbers.VisibleCount shr 1;
        TopLine := LCaretRow - LMiddle + 1;
      end;
    end
    else
    if LCaretRow < TopLine then
      TopLine := LCaretRow
    else
    if LCaretRow > TopLine + Max(1, FLineNumbers.VisibleCount) - 1 then
      TopLine := LCaretRow - (FLineNumbers.VisibleCount - 1);

    if (LPoint.X < LLeftMarginWidth) or (LPoint.X >= LLeftMarginWidth + FScrollHelper.PageWidth) then
      SetHorizontalScrollPosition(LPoint.X + FScrollHelper.HorizontalPosition - FLeftMarginWidth - FScrollHelper.PageWidth shr 1)
    else
    if LPoint.X = LLeftMarginWidth then
      SetHorizontalScrollPosition(0)
    else
      SetHorizontalScrollPosition(FScrollHelper.HorizontalPosition);
  finally
    DecPaintLock;
  end;
end;

procedure TCustomTextEditor.ExecuteCommand(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);
begin
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
    TKeyCommands.ToggleNumberBookmark:
      DoToggleBookmark(-1, True);
    TKeyCommands.GoToMatchingPair:
      GoToMatchingPair;
    TKeyCommands.GoToNextBookmark:
      GoToNextBookmark;
    TKeyCommands.GoToPreviousBookmark:
      GoToPreviousBookmark;
    TKeyCommands.DropCaretBookmark:
      DropCaretBookmark;
    TKeyCommands.ReturnToCaretBookmark:
      ReturnToCaretBookmark;
    TKeyCommands.SwapCaretBookmark:
      SwapCaretBookmark;
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
    TKeyCommands.DeleteWord, TKeyCommands.DeleteWhitespaceBackward, TKeyCommands.DeleteWhitespaceForward,
    TKeyCommands.DeleteWordBackward, TKeyCommands.DeleteWordForward, TKeyCommands.DeleteBeginningOfLine,
    TKeyCommands.DeleteEndOfLine:
      if not ReadOnly then
        DeleteText(ACommand);
    TKeyCommands.DeleteLine:
      if not ReadOnly and (FLines.Count > 0) then
        DeleteLine;
    TKeyCommands.MoveLinesUp:
      MoveLinesUp;
    TKeyCommands.MoveLinesDown:
      MoveLinesDown;
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
    TKeyCommands.TitleCase, TKeyCommands.UpperCaseBlock, TKeyCommands.LowerCaseBlock, TKeyCommands.AlternatingCaseBlock,
    TKeyCommands.KeywordsUpperCase, TKeyCommands.KeywordsLowerCase, TKeyCommands.KeywordsTitleCase:
      if not ReadOnly then
        DoToggleSelectedCase(ACommand);
    TKeyCommands.Undo:
      if not ReadOnly then
        DoUndo;
    TKeyCommands.Redo:
      if not ReadOnly then
        DoRedo;
    TKeyCommands.Cut:
      DoCutToClipboard;
    TKeyCommands.Copy:
      CopyToClipboard;
    TKeyCommands.Paste:
      DoPasteFromClipboard;
    TKeyCommands.ScrollUp, TKeyCommands.ScrollDown:
      DoScroll(ACommand);
    TKeyCommands.ScrollLeft:
      begin
        SetHorizontalScrollPosition(FScrollHelper.HorizontalPosition - 1);
        Repaint;
      end;
    TKeyCommands.ScrollRight:
      begin
        SetHorizontalScrollPosition(FScrollHelper.HorizontalPosition + 1);
        Repaint;
      end;
    TKeyCommands.InsertMode:
      OvertypeMode := omInsert;
    TKeyCommands.OverwriteMode:
      OvertypeMode := omOverwrite;
    TKeyCommands.ToggleMode:
      OvertypeMode := if FOvertypeMode = omInsert then omOverwrite else omInsert;
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

  Repaint;
end;

procedure TCustomTextEditor.FoldingCollapseLine;
var
  LFoldRange: TTextEditorCodeFoldingRange;
begin
  if not IsCodeFoldingVisible then
    Exit;

  if FLines.Count > 0 then
  begin
    LFoldRange := CodeFoldingCollapsableFoldRangeForLine(TextPosition.Line + 1);

    if Assigned(LFoldRange) then
    begin
      if not LFoldRange.Collapsed then
        CodeFoldingCollapse(LFoldRange);

      Repaint;
    end;
  end;
end;

procedure TCustomTextEditor.FoldingExpandLine;
var
  LFoldRange: TTextEditorCodeFoldingRange;
begin
  if not IsCodeFoldingVisible then
    Exit;

  if FLines.Count > 0 then
  begin
    LFoldRange := CodeFoldingCollapsableFoldRangeForLine(TextPosition.Line + 1);

    if Assigned(LFoldRange) then
    begin
      if LFoldRange.Collapsed then
        CodeFoldingExpand(LFoldRange);

      Repaint;
    end;
  end;
end;

procedure TCustomTextEditor.FoldingGoToNext;
var
  LTextPosition: TTextEditorTextPosition;
begin
  if not IsCodeFoldingVisible then
    Exit;

  LTextPosition := TextPosition;

  LTextPosition.Line := LTextPosition.Line + 1;

  while (LTextPosition.Line < FLines.Count) and Assigned(FCodeFoldings.RangeFromLine) and
    not Assigned(FCodeFoldings.RangeFromLine[LTextPosition.Line + 1]) do
    LTextPosition.Line := LTextPosition.Line + 1;

  TextPosition := LTextPosition;

  Repaint;
end;

procedure TCustomTextEditor.FoldingGoToPrevious;
var
  LTextPosition: TTextEditorTextPosition;
begin
  if not IsCodeFoldingVisible then
    Exit;

  LTextPosition := TextPosition;

  LTextPosition.Line := LTextPosition.Line - 1;

  while (LTextPosition.Line < FLines.Count) and Assigned(FCodeFoldings.RangeFromLine) and
    not Assigned(FCodeFoldings.RangeFromLine[LTextPosition.Line + 1]) do
    LTextPosition.Line := LTextPosition.Line - 1;

  TextPosition := LTextPosition;

  Repaint;
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
  with TTextEditorExportHTML.Create(Self, FFonts.Text, ACharSet) do
  try
    SaveToStream(AStream, AEncoding);
  finally
    Free;
  end;
end;

function TCustomTextEditor.TextToHTML(const AClipboardFormat: Boolean = False): string;
begin
  with TTextEditorExportHTML.Create(Self, FFonts.Text, '') do
  try
    Result := AsText(AClipboardFormat);
  finally
    Free;
  end;
end;

procedure TCustomTextEditor.DropCaretBookmark;
var
  LMark: TTextEditorMark;
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := TextPosition;

  LMark := TTextEditorMark.Create(Self);
  LMark.Line := LTextPosition.Line;
  LMark.Char := LTextPosition.Char;
  LMark.Index := FCaretBookmarkList.Count;
  LMark.Visible := False;

  FCaretBookmarkList.Add(LMark);

  { Keep the stack bounded }
  while FCaretBookmarkList.Count > 50 do
    FCaretBookmarkList.Delete(0);
end;

procedure TCustomTextEditor.ReturnToCaretBookmark;
var
  LMark: TTextEditorMark;
  LTextPosition: TTextEditorTextPosition;
begin
  if FCaretBookmarkList.Count = 0 then
    Exit;

  LMark := FCaretBookmarkList.Last;
  LTextPosition := GetPosition(LMark.Char, LMark.Line);

  FCaretBookmarkList.Delete(FCaretBookmarkList.Count - 1);

  GoToLineAndSetPosition(LTextPosition.Line, LTextPosition.Char);

  FPosition.SelectionStart := TextPosition;
  FPosition.SelectionEnd := FPosition.SelectionStart;

  Repaint;
end;

procedure TCustomTextEditor.SwapCaretBookmark;
var
  LMark: TTextEditorMark;
  LTextPosition, LTargetPosition: TTextEditorTextPosition;
begin
  if FCaretBookmarkList.Count = 0 then
    Exit;

  { The topmost caret bookmark and the caret trade places - toggles between two locations }
  LMark := FCaretBookmarkList.Last;
  LTargetPosition := GetPosition(LMark.Char, LMark.Line);

  LTextPosition := TextPosition;
  LMark.Line := LTextPosition.Line;
  LMark.Char := LTextPosition.Char;

  GoToLineAndSetPosition(LTargetPosition.Line, LTargetPosition.Char);

  FPosition.SelectionStart := TextPosition;
  FPosition.SelectionEnd := FPosition.SelectionStart;

  Repaint;
end;

procedure TCustomTextEditor.GoToBookmark(const AIndex: Integer);
var
  LTextPosition: TTextEditorTextPosition;
  LBookmark: TTextEditorMark;
begin
  LBookmark := FBookmarkList.Find(AIndex);

  if Assigned(LBookmark) then
  begin
    LTextPosition := GetPosition(LBookmark.Char, LBookmark.Line);

    GoToLineAndSetPosition(LTextPosition.Line, LTextPosition.Char);

    FPosition.SelectionStart := TextPosition;
    FPosition.SelectionEnd := FPosition.SelectionStart;

    Repaint;
  end;
end;

procedure TCustomTextEditor.GoToLine(const ALine: Integer);
var
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := GetPosition(1, ALine - 1);

  SetTextPosition(LTextPosition);

  FPosition.SelectionStart := LTextPosition;
  FPosition.SelectionEnd := FPosition.SelectionStart;

  Repaint;
end;

procedure TCustomTextEditor.GoToLineAndSetPosition(const ALine: Integer; const AChar: Integer = 1; const AResultPosition: TTextEditorResultPosition = rpMiddle);
var
  LTextPosition: TTextEditorTextPosition;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
  LViewPosition: TTextEditorViewPosition;
begin
  if IsCodeFoldingVisible then
  begin
    for var LIndex := 0 to FCodeFoldings.AllRanges.AllCount - 1 do
    begin
      LCodeFoldingRange := FCodeFoldings.AllRanges[LIndex];

      if LCodeFoldingRange.FromLine > ALine then
        Break
      else
      if LCodeFoldingRange.Collapsed and (LCodeFoldingRange.FromLine <= ALine) then
        CodeFoldingExpand(LCodeFoldingRange);
    end;
  end;

  LTextPosition := GetPosition(AChar, ALine);

  SetTextPosition(LTextPosition);

  LViewPosition := TextToViewPosition(LTextPosition);

  if FLineNumbers.VisibleCount = 0 then
  begin
    FLineNumbers.VisibleCount := Round(ClientHeight / GetLineHeight);

    if IsRulerVisible then
      Dec(FLineNumbers.VisibleCount);
  end;

  case AResultPosition of
    rpTop:
      TopLine := LViewPosition.Row;
    rpMiddle:
      TopLine := Max(LViewPosition.Row - FLineNumbers.VisibleCount shr 1 + 1, 1);
    rpBottom:
      TopLine := Max(LViewPosition.Row - FLineNumbers.VisibleCount + 1, 1);
  end;

  FPosition.SelectionStart := LTextPosition;
  FPosition.SelectionEnd := FPosition.SelectionStart;

  Repaint;
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
  BeginUpdate;
  try
    LLineNumber := ALineNumber;

    if LLineNumber > FLines.Count + 1 then
      LLineNumber := FLines.Count + 1;

    FUndoList.BeginBlock;
    try
      FUndoList.AddChange(crCaret, TextPosition, SelectionStartPosition, SelectionEndPosition, '', smNormal);

      LTextPosition := GetPosition(1, LLineNumber - 1);

      FLines.Insert(LTextPosition.Line, AValue);

      if LLineNumber < FLines.Count then
        LTextEndPosition := GetPosition(1, LTextPosition.Line + 1)
      else
      begin
        LTextEndPosition := GetPosition(AValue.Length + 1, LTextPosition.Line);
        LTextPosition := GetPosition(FLines.StringLength(LTextPosition.Line - 1) + 1, LTextPosition.Line - 1);
      end;

      AddUndoInsert(LTextPosition, LTextPosition, LTextEndPosition, '', smNormal);
    finally
      FUndoList.EndBlock;
    end;
  finally
    RescanHighlighterRanges;
    EndUpdate;
  end;
end;

procedure TCustomTextEditor.InsertSnippet(const AItem: TTextEditorCompletionProposalSnippetItem; const ATextPosition: TTextEditorTextPosition);
var
  LCharCount: Integer;

  function GetBeginChar(const ARow: Integer): Integer;
  begin
    Result := if ARow = 1 then SelectionStartPosition.Char else LCharCount + 1;
  end;

var
  LStringList: TStringList;
  LText, LLineText: string;
  LPLineText: PChar;
  LIndex: Integer;
  LSpaces: string;
  LBeginChar: Integer;
  LSnippetPosition, LSnippetSelectionStartPosition, LSnippetSelectionEndPosition: TTextEditorTextPosition;
  LScrollPastEndOfLine: Boolean;
begin
  BeginUpdate;
  BeginUndoBlock;
  try
    WordAtTextPosition(ATextPosition, True);

    if not SelectionAvailable then
      GetCharAtTextPosition(ATextPosition, True);

    LStringList := TStringList.Create;
    try
      LStringList.TrailingLineBreak := False;

      LText := AItem.Snippet.Text;

      LText := StringReplace(LText, TSnippetReplaceTags.CurrentWord, WordAtCursor, [rfReplaceAll]);
      LText := StringReplace(LText, TSnippetReplaceTags.SelectedText, SelectedText, [rfReplaceAll]);
      LText := StringReplace(LText, TSnippetReplaceTags.Text, Text, [rfReplaceAll]);

      LStringList.Text := LText;

      LLineText := FLines[ATextPosition.Line];
      LCharCount := 0;

      LPLineText := PChar(LLineText);
      LIndex := 0;

      while LIndex < SelectionStartPosition.Char do
      begin
        Inc(LCharCount, if LPLineText^ = TControlCharacters.Tab then Tabs.Width else 1);

        if LPLineText^ <> TControlCharacters.Null then
          Inc(LPLineText);

        Inc(LIndex);
      end;

      Dec(LCharCount);

      LSpaces :=
        if toTabsToSpaces in Tabs.Options then
          StringOfChar(TCharacters.Space, LCharCount)
        else
          StringOfChar(TControlCharacters.Tab, LCharCount div Tabs.Width) + StringOfChar(TCharacters.Space, LCharCount mod Tabs.Width);

      for LIndex := 1 to LStringList.Count - 1 do
        LStringList[LIndex] := LSpaces + LStringList[LIndex];

      if AItem.Position.Active then
      begin
        LBeginChar := GetBeginChar(AItem.Position.Row);
        LSnippetPosition := GetPosition(LBeginChar + AItem.Position.Column - 1, SelectionStartPosition.Line +
          AItem.Position.Row - 1);
      end;

      if AItem.Selection.Active then
      begin
        LBeginChar := GetBeginChar(AItem.Selection.FromRow);
        LSnippetSelectionStartPosition := GetPosition(LBeginChar + AItem.Selection.FromColumn - 1,
          SelectionStartPosition.Line + AItem.Selection.FromRow - 1);
        LBeginChar := GetBeginChar(AItem.Selection.ToRow);
        LSnippetSelectionEndPosition := GetPosition(LBeginChar + AItem.Selection.ToColumn - 1,
          SelectionStartPosition.Line + AItem.Selection.ToRow - 1);
      end;

      SelectedText := LStringList.Text;

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
        SelectionStartPosition := LSnippetSelectionStartPosition;
        SelectionEndPosition := LSnippetSelectionEndPosition;
      end
      else
      begin
        SelectionStartPosition := TextPosition;
        SelectionEndPosition := SelectionStartPosition;
      end;

      if LScrollPastEndOfLine then
        FScroll.SetOption(soPastEndOfLine, False);
    finally
      LStringList.Free;
    end;
  finally
    EndUndoBlock;
    EndUpdate;
  end;
end;

procedure TCustomTextEditor.InsertBlock(const ABlockBeginPosition, ABlockEndPosition: TTextEditorTextPosition; const AChangeStr: PChar; const AAddToUndoList: Boolean);
var
  LSelectionMode: TTextEditorSelectionMode;
begin
  LSelectionMode := FSelection.ActiveMode;

  SetTextPositionAndSelection(ABlockBeginPosition, ABlockBeginPosition, ABlockEndPosition);
  FSelection.ActiveMode := smColumn;
  DoSelectedText(smColumn, AChangeStr, AAddToUndoList, TextPosition);
  FSelection.ActiveMode := LSelectionMode;
end;

procedure TCustomTextEditor.LeftMarginChanged(ASender: TObject);
begin
  if not (csLoading in ComponentState) and Assigned(Parent) and not FHighlighter.Loading then
  begin
    DoLeftMarginAutoSize;

    if Assigned(Parent) then
    begin
      FLeftMarginWidth := GetLeftMarginWidth;
      FScrollHelper.PageWidth := GetScrollPageWidth;

      UpdateScrollBars;
      Repaint;
    end;
  end;
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
  ResetCharacterCount;
  try
    FFile.Loaded := False;

    LWordWrapEnabled := FWordWrap.Active;

    FWordWrap.Active := False;

    if Assigned(Parent) then
    begin
      ClearMatchingPair;
      ClearCodeFolding;
      ClearBookmarks;
    end;

    FLines.BufferSize := FFile.MaxReadBufferSize;
    FLines.ShowProgress := AStream.Size > FFile.MinShowProgressSize;

    if FLines.ShowProgress then
    begin
      FLines.ProgressPosition := 0;
      FLines.ProgressType := ptLoading;
      FLines.ProgressStep := AStream.Size div 100;

      if Assigned(FEvents.OnShowProgressDialog) then
        FEvents.OnShowProgressDialog(Self);
    end;

    FLines.TrailingLineBreak := eoTrailingLineBreak in FOptions;

    if FPartialLoad.Enabled then
      FLines.LoadPartFromStream(AStream, FPartialLoad.From, FPartialLoad.Rows, AEncoding)
    else
      FLines.LoadFromStream(AStream, AEncoding);

    if FLines.LoadingCancelled then
      Exit;

    if Assigned(FEvents.OnAfterLoadFromStream) then
      FEvents.OnAfterLoadFromStream(Self, AStream, AEncoding);

    if Assigned(FLines.OnInserted) then
      FLines.OnInserted(Self, 0, FLines.Count);

    if Assigned(FLines.OnChange) then
      FLines.OnChange(Self);

    if FLines.Count = 0 then
      FLines.Add(EmptyStr);

    if not Assigned(Parent) then
      Exit;

    InitCodeFolding;

    if LWordWrapEnabled and not FLines.ShowProgress and not FSimpleMode then
      FWordWrap.Active := LWordWrapEnabled;

    SizeOrFontChanged;

    if Assigned(FHighlighter.BeforePrepare) then
      FHighlighter.SetOption(hoExecuteBeforePrepare, True);

    FFile.Loaded := True;
  finally
    if FLines.ShowProgress and Assigned(FEvents.OnHideProgressDialog) then
      FEvents.OnHideProgressDialog(Self);

    FLines.ShowProgress := False;
    UpdateScrollBars;
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

    if AComponent = FCompletionProposalPopupWindow then
      FCompletionProposalPopupWindow := nil;

    if Assigned(FLeftMargin) and Assigned(FLeftMargin.Bookmarks) and Assigned(FLeftMargin.Bookmarks.Images) then
      if (AComponent = FLeftMargin.Bookmarks.Images) then
      begin
        FLeftMargin.Bookmarks.Images := nil;

        Repaint;
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
  LChangeTrim, LPasteAction, LKeepGoing: Boolean;
  LLastChangeBlockNumber: Integer;
  LLastChangeReason: TTextEditorChangeReason;
  LLastChangeString: string;
  LRedoItem: TTextEditorUndoItem;
begin
  if ReadOnly then
    Exit;

  BeginUpdate;

  LChangeTrim := eoTrimTrailingSpaces in Options;

  if LChangeTrim then
    Exclude(FOptions, eoTrimTrailingSpaces);

  try
    LLastChangeBlockNumber := FRedoList.LastChangeBlockNumber;
    LLastChangeReason := FRedoList.LastChangeReason;
    LLastChangeString := FRedoList.LastChangeString;
    LPasteAction := LLastChangeReason = crPaste;
    LRedoItem := FRedoList.PeekItem;

    if Assigned(LRedoItem) then
    begin
      AutoCursor;

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
  finally
    if LChangeTrim then
      Include(FOptions, eoTrimTrailingSpaces);

    EndUpdate;
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
    FHookedCommandHandlers.Add(TTextEditorHookedCommandHandler.Create(AHookedCommandEvent, AHandlerData));
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
  BeginUpdate;
  try
    LTextPosition := GetPosition(1, ALineNumber - 1);
    LLineBreak := '';

    if sfEmptyLine in AFlags then
      LLineBreak := FLines.DefaultLineBreak;

    AddUndoPaste(LTextPosition, GetPosition(1, ALineNumber - 1), GetPosition(AValue.Length + 1, ALineNumber - 1),
      FLines.Strings[ALineNumber - 1] + LLineBreak, FSelection.ActiveMode);

    FLines.Strings[ALineNumber - 1] := AValue;

    if sfEmptyLine in AFlags then
      FLines.IncludeFlag(ALineNumber - 1, sfEmptyLine)
    else
      FLines.ExcludeFlag(ALineNumber - 1, sfEmptyLine);
  finally
    EndUpdate;
  end;
end;

procedure TCustomTextEditor.RescanCodeFoldingRanges;
var
  LLengthCodeFoldingRangeFromLine, LLengthCodeFoldingRangeToLine: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
begin
  if not IsCodeFoldingVisible then
    Exit;

  FCodeFoldings.Rescan := False;

  LLengthCodeFoldingRangeFromLine := Length(FCodeFoldings.RangeFromLine);
  LLengthCodeFoldingRangeToLine := Length(FCodeFoldings.RangeToLine);

  { Delete all expanded folds }
  for var LIndex := FCodeFoldings.AllRanges.AllCount - 1 downto 0 do
  begin
    LCodeFoldingRange := FCodeFoldings.AllRanges[LIndex];

    if Assigned(LCodeFoldingRange) then
    begin
      if not LCodeFoldingRange.Collapsed and not LCodeFoldingRange.ParentCollapsed then
      begin
        if (LCodeFoldingRange.FromLine > 0) and (LCodeFoldingRange.FromLine < LLengthCodeFoldingRangeFromLine) then
          FCodeFoldings.RangeFromLine[LCodeFoldingRange.FromLine] := nil;

        if (LCodeFoldingRange.ToLine > 0) and (LCodeFoldingRange.ToLine < LLengthCodeFoldingRangeToLine) then
          FCodeFoldings.RangeToLine[LCodeFoldingRange.ToLine] := nil;

        FreeAndNil(LCodeFoldingRange);
        FCodeFoldings.AllRanges.List.Delete(LIndex);
      end;
    end;
  end;

  ScanCodeFoldingRanges;
  CodeFoldingResetCaches;

  Repaint;
end;

procedure TCustomTextEditor.ResetCharacterCount;
begin
  FCharacterCount.Calculate := True;
  FCharacterCount.Value := 0;
end;

function TCustomTextEditor.SaveToFile(const AFilename: string; const AEncoding: System.SysUtils.TEncoding = nil): Boolean;
var
  LCancel: Boolean;
  LEncoding: System.SysUtils.TEncoding;
  LFileStream: TFileStream;
begin
  Result := False;

  LCancel := False;
  LEncoding := AEncoding;

  if Assigned(FEvents.OnBeforeSaveToFile) then
    FEvents.OnBeforeSaveToFile(Self, AFilename, LEncoding, LCancel);

  if LCancel then
    Exit;

  LFileStream := TFileStream.Create(AFilename, fmCreate);
  try
    SaveToStream(LFileStream, LEncoding);
  finally
    LFileStream.Free;
  end;

  Result := True;
end;

procedure TCustomTextEditor.SaveToStream(const AStream: TStream; const AEncoding: System.SysUtils.TEncoding = nil;
  const AChangeModified: Boolean = True);
begin
  AutoCursor;

  FLines.TrailingLineBreak := eoTrailingLineBreak in FOptions;
  FLines.TrimTrailingSpaces := eoTrimTrailingSpaces in FOptions;
  FLines.SaveToStream(AStream, AEncoding);

  if AChangeModified then
  begin
    SetModified(False);

    UndoList.Changed := False;

    if not (uoUndoAfterSave in FUndo.Options) then
      UndoList.Clear;

    FFile.Saved := True;
  end;
end;

procedure TCustomTextEditor.SelectAll;
var
  LOldCaretPosition, LLastTextPosition: TTextEditorTextPosition;
begin
  LOldCaretPosition := TextPosition;
  LLastTextPosition := GetPosition(1, Max(FLines.Count - 1, 0));

  if LLastTextPosition.Line >= 0 then
    Inc(LLastTextPosition.Char, if FSelection.Mode = smNormal then FLines[LLastTextPosition.Line].Length else FLines.GetLengthOfLongestLine);

  SetTextPositionAndSelection(LOldCaretPosition, GetBOFPosition, LLastTextPosition);
  FreeMultiCarets;
  TextPosition := LLastTextPosition;

  Repaint;
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
      ImageIndex := if AImageIndex = -1 then Min(AIndex, 9) else AImageIndex;
      Index := AIndex;
      Visible := True;
    end;

    FBookmarkList.Add(LBookmark);
    FBookmarkList.Sort(CompareBookmarkLines);

    if Assigned(FEvents.OnAfterBookmarkPlaced) then
      FEvents.OnAfterBookmarkPlaced(Self, AIndex, AImageIndex, ATextPosition);
  end;
end;

procedure TCustomTextEditor.SetClipboardText(const AText: string; const AHTML: string);
var
  LClipboardService: IFMXClipboardService;
  LText: string;
begin
  if AText.IsEmpty then
    Exit;

  LText := StringReplace(AText, TControlCharacters.Null, '', [rfReplaceAll]);

{$IFDEF MSWINDOWS}
  { The FMX clipboard service supports plain text only - eoAddHTMLCodeToClipboard needs the HTML clipboard
    format written with the Windows clipboard API }
  if not AHTML.IsEmpty and TrySetClipboardTextWithHTML(LText, AHTML) then
    Exit;
{$ENDIF}

  if TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LClipboardService) then
    LClipboardService.SetClipboard(LText);
end;

procedure TCustomTextEditor.SetTextPositionAndSelection(const ATextPosition, ABlockBeginPosition, ABlockEndPosition: TTextEditorTextPosition);
var
  LOldSelectionMode: TTextEditorSelectionMode;
begin
  LOldSelectionMode := FSelection.ActiveMode;

  IncPaintLock;
  try
    TextPosition := ATextPosition;

    SetSelectionStartPosition(ABlockBeginPosition);
    SetSelectionEndPosition(ABlockEndPosition);
  finally
    FSelection.ActiveMode := LOldSelectionMode;
    DecPaintLock;
  end;
end;

procedure TCustomTextEditor.SetFocus;
begin
  if not (csDesigning in ComponentState) then
    inherited SetFocus;
end;

procedure TCustomTextEditor.SetMark(const AIndex: Integer; const ATextPosition: TTextEditorTextPosition;
  const AImageIndex: Integer; const AColor: TAlphaColor = TAlphaColors.Null);
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

procedure TCustomTextEditor.Sort(const AOptions: TTextEditorSortOptions);
var
  LTextPosition: TTextEditorTextPosition;
  LBeginPosition, LEndPosition, LTempTextPosition: TTextEditorTextPosition;
  LText: string;
  LSelectionAvailable: Boolean;
  LLines: TTextEditorLines;
begin
  BeginUpdate;
  try
    LTextPosition := TextPosition;

    FLines.SortOptions := AOptions;

    if soRandom in AOptions then
      Randomize;

    LBeginPosition.Line := 0;
    LEndPosition.Line := FLines.Count - 1;

    LText := FLines.Text;
    LSelectionAvailable := GetSelectionAvailable;

    if LSelectionAvailable then
    begin
      LBeginPosition.Line := GetSelectionStartPosition.Line;
      LEndPosition := GetSelectionEndPosition;

      if LEndPosition.Char = 1 then
        Dec(LEndPosition.Line);

      LText := SelectedText;
    end;

    LBeginPosition.Char := 1;
    LEndPosition.Char := FLines.StringLength(LEndPosition.Line) + 1;

    FUndoList.BeginBlock;
    try
      if FSelection.ActiveMode = smNormal then
      begin
        if not LSelectionAvailable then
          FUndoList.AddChange(crSelection, LTextPosition, LTextPosition, LTextPosition, '', FSelection.ActiveMode);

        AddUndoDelete(LTextPosition, LBeginPosition, LEndPosition, LText, FSelection.ActiveMode);

        FLines.Sort(LBeginPosition.Line, LEndPosition.Line)
      end
      else
      begin
        if not LSelectionAvailable then
          SelectAll;

        LLines := TTextEditorLines.Create(nil);
        try
          LLines.SortOptions := AOptions;
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
        AddUndoInsert(LTextPosition, LBeginPosition, LEndPosition, '', FSelection.ActiveMode);

        if LSelectionAvailable then
        begin
          LTempTextPosition := GetSelectionStartPosition;

          LTempTextPosition.Char := 1;
          SelectionStartPosition := LTempTextPosition;
          SelectionEndPosition := LEndPosition;
        end;
      end;
    finally
      FUndoList.EndBlock;
    end;

    FLines.SetLineStates(LBeginPosition.Line, LEndPosition.Line, lsModified);
  finally
    EndUpdate;
  end;
end;

procedure TCustomTextEditor.DeleteComments;
var
  LTextPosition, LBeginPosition, LEndPosition: TTextEditorTextPosition;
  LText, LWord: string;
  LTokenType, LPreviousTokenType: TTextEditorRangeType;
begin
  LTextPosition := TextPosition;
  LBeginPosition := GetPosition(1, 0);

  LEndPosition.Line := FLines.Count - 1;
  LEndPosition.Char := FLines.StringLength(LEndPosition.Line) + 1;

  BeginUpdate;
  try
    FUndoList.BeginBlock;
    try
      FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', FSelection.ActiveMode);

      LText := '';

      for var LLine := LBeginPosition.Line to LEndPosition.Line do
      begin
        if LLine = 0 then
          FHighlighter.ResetRange
        else
          FHighlighter.SetRange(FLines.Ranges[LLine - 1]);

        FHighlighter.SetLine(FLines.TextLines[LLine]);

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

      AddUndoInsert(LTextPosition, LBeginPosition, LEndPosition, '', FSelection.ActiveMode);

      MoveCaretToBeginning;
    finally
      FUndoList.EndBlock;
    end;

    DoChange;
  finally
    EndUpdate;
  end;
end;

procedure TCustomTextEditor.DeleteEmptyLines;
var
  LTextPosition: TTextEditorTextPosition;
begin
  if ReadOnly then
    Exit;

  BeginUpdate;
  try
    FUndoList.BeginBlock;
    try
      LTextPosition := TextPosition;

      FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);

      LTextPosition.Char := 1;

      for var LIndex := FLines.Count - 1 downto 0 do
      if FLines[LIndex].Trim.IsEmpty then
      begin
        FLines.Delete(LIndex);
        LTextPosition.Line := LIndex;

        FUndoList.AddChange(crDelete, LTextPosition, LTextPosition, LTextPosition, FLines.GetLineBreak(LIndex), smNormal);
      end;
    finally
      FUndoList.EndBlock;
    end;
  finally
    EndUpdate;
  end;
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
      SetBookmark(AIndex, LTextPosition);
  end;
end;

procedure TCustomTextEditor.UnhookEditorLines;
var
  LOldWrap: Boolean;
begin
  Assert(not Assigned(FChainedEditor));

  if FLines = FOriginal.Lines then
    Exit;

  LOldWrap := FWordWrap.Active;

  if not (csDestroying in ComponentState) then
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
  BeginUpdate;
  try
    if AnsiUpperCase(SelectedText) <> AnsiUpperCase(FToggleCase.Text) then
    begin
      FToggleCase.Cycle := cUpper;
      FToggleCase.Text := SelectedText;
    end;

    if ACase <> cNone then
      FToggleCase.Cycle := ACase;

    LSelectionStart := SelectionStartPosition;
    LSelectionEnd := SelectionEndPosition;
    LCommand := TKeyCommands.None;

    case FToggleCase.Cycle of
      cUpper:
        LCommand := if FSelection.ActiveMode = smColumn then TKeyCommands.UpperCaseBlock else TKeyCommands.UpperCase;
      cLower:
        LCommand := if FSelection.ActiveMode = smColumn then TKeyCommands.LowerCaseBlock else TKeyCommands.LowerCase;
      cAlternating:
        LCommand := if FSelection.ActiveMode = smColumn then TKeyCommands.AlternatingCaseBlock else TKeyCommands.AlternatingCase;
      cSentence:
        LCommand := TKeyCommands.SentenceCase;
      cTitle:
        LCommand := TKeyCommands.TitleCase;
      cKeywordsUpper:
        LCommand := TKeyCommands.KeywordsUpperCase;
      cKeywordsLower:
        LCommand := TKeyCommands.KeywordsLowerCase;
      cKeywordsTitle:
        LCommand := TKeyCommands.KeywordsTitleCase;
    end;

    if FToggleCase.Cycle <> cOriginal then
      CommandProcessor(LCommand, TControlCharacters.Null, nil);

    SelectionStartPosition := LSelectionStart;
    SelectionEndPosition := LSelectionEnd;

    Inc(FToggleCase.Cycle);

    if FToggleCase.Cycle > cOriginal then
      FToggleCase.Cycle := cUpper;
  finally
    EndUpdate;
  end;
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
    FHookedCommandHandlers.Delete(LIndex);
end;

procedure TCustomTextEditor.UpdateCaret;
var
  LLine, LOffset: Integer;
  LViewPosition: TTextEditorViewPosition;
  LVisibleChars: Integer;
  LCaretPoint: TPointF;
  LRect: TRectF;
  LSameViewPosition: Boolean;
begin
  if Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) then
  begin
    HideCaret;
    Exit;
  end;

  if PaintLock <> 0 then
  begin
    Include(FState.Flags, sfCaretChanged);
    Exit;
  end;

  if not (Focused or FCaretHelper.ShowAlways) then
  begin
    Include(FState.Flags, sfCaretChanged);
    HideCaret;
    Exit;
  end;

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
    if LViewPosition.Column > FWordWrapLine.ViewLength[LViewPosition.Row] then
    begin
      LViewPosition.Column := LViewPosition.Column - FWordWrapLine.ViewLength[LViewPosition.Row];
      LViewPosition.Row := LViewPosition.Row + 1;

      if TextPosition.Line <> ViewToTextPosition(LViewPosition).Line then
      begin
        LViewPosition.Row := LViewPosition.Row - 1;
        LViewPosition.Column := LViewPosition.Column + FWordWrapLine.ViewLength[LViewPosition.Row];
      end;
    end;
  end;

  LSameViewPosition := (FLast.ViewPosition.Row = LViewPosition.Row) and
    (FLast.ViewPosition.Column = LViewPosition.Column);

  LCaretPoint := ViewPositionToPixels(LViewPosition);
  LCaretPoint.X := LCaretPoint.X + FCaretHelper.Offset.X;
  LCaretPoint.Y := LCaretPoint.Y + FCaretHelper.Offset.Y;

  LRect := ClientRect;
  DeflateMinimapAndSearchMapRect(LRect);
  LRect.Left := LRect.Left + FLeftMargin.GetWidth;

  if not FSimpleMode then
    LRect.Left := LRect.Left + FCodeFolding.GetWidth;

  if LRect.Contains(LCaretPoint) then
    ShowCaret
  else
    HideCaret;

  UpdateMultiCaretDisplays;

  if LSameViewPosition then
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

procedure TCustomTextEditor.ChangeObjectScale(const AMultiplier: Integer; const ADivider: Integer; const AIsDpiChange: Boolean);
begin
  if (AMultiplier = ADivider) and not AIsDpiChange then
    Exit;

  FPixelsPerInch := AMultiplier;

  if Assigned(FEvents.OnChangeScale) and not FZoom.Return then
    FEvents.OnChangeScale(Self, AMultiplier, ADivider, AIsDpiChange);

  if Assigned(FFonts) then
    FFonts.ChangeScale(AMultiplier, ADivider, AIsDpiChange);

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

  FreeBookmarkImages;
end;

procedure TCustomTextEditor.SetZoomPercentage(const AValue: Integer);
var
  LPixelsPerInch, LMultiplier: Integer;
begin
  if FZoom.Percentage <> AValue then
  begin
    FZoom.Percentage := AValue;

    HideCaret;
    IncPaintLock;
    try
      LPixelsPerInch := 96;

      if FZoom.Divider = 0 then
        FZoom.Divider := LPixelsPerInch;

      LMultiplier := Round((FZoom.Percentage / 100) * LPixelsPerInch);

      FZoom.Return := True;
      ChangeObjectScale(LPixelsPerInch, FZoom.Divider, True);
      FZoom.Return := False;

      ChangeObjectScale(LMultiplier, LPixelsPerInch, True);

      FZoom.Divider := LMultiplier;
    finally
      if FWordWrap.Active then
        CreateLineNumbersCache(True);

      DecPaintLock;
      ShowCaret;
    end;
  end;
end;

procedure TCustomTextEditor.SetFullFilename(const AName: string);
begin
  FFile.FullName := AName;
  FFile.Path := ExtractFilePath(AName);
  FFile.Name := ExtractFileName(AName);
end;

procedure TCustomTextEditor.SetHighlightLine(const AValue: TTextEditorHighlightLine);
begin
  FHighlightLine.Assign(AValue);
end;

procedure TCustomTextEditor.GoToOriginalLineAndSetPosition(const ALine: Integer; const AChar: Integer;
  const AText: string = ''; const AResultPosition: TTextEditorResultPosition = rpMiddle);

  function GetOriginalLineNumber(const ALine: Integer): Integer;
  var
    LLow, LHigh, LMiddle, LLine: Integer;
  begin
    LLow := 0;
    LHigh := FLines.Count - 1;

    while LLow <= LHigh do
    begin
      LMiddle := (LLow + LHigh) shr 1;
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

var
  LLine: Integer;
begin
  LLine := GetOriginalLineNumber(ALine);

  if LLine = -1 then
    Exit;

  if not AText.IsEmpty and not Modified then
    if CompareText(FLines[LLine], AText) <> 0 then
    begin
      LoadFromFile(FullFilename);
      LLine := GetOriginalLineNumber(ALine);
    end;

  GoToLineAndSetPosition(LLine, AChar, AResultPosition);
end;

function TCustomTextEditor.WordCount(const ASelected: Boolean = False): Integer;
var
  LPText: PChar;
  LIsWord: Boolean;
begin
  Result := 0;

  LPText := if ASelected then PChar(SelectedText) else PChar(Text);

  while LPText^ <> TControlCharacters.Null do
  begin
    while (LPText^ <> TControlCharacters.Null) and ((LPText^ < TCharacters.ExclamationMark) or IsWordBreakChar(LPText^)) do
      Inc(LPText);

    if LPText^ = TControlCharacters.Null then
      Exit;

    LIsWord := True;

    while (LPText^ >= TCharacters.ExclamationMark) and (LPText^ <> TControlCharacters.Null) and not IsWordBreakChar(LPText^) do
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
  LPText: PChar;
begin
  if FCharacterCount.Calculate or ASelected then
  begin
    Result := 0;

    LPText := if ASelected then PChar(SelectedText) else PChar(FLines.Text);

    while LPText^ <> TControlCharacters.Null do
    begin
      if LPText^ > TCharacters.Space then
        Inc(Result);

      Inc(LPText);
    end;

    if not ASelected then
    begin
      FCharacterCount.Calculate := False;
      FCharacterCount.Value := Result;
    end;
  end
  else
    Result := FCharacterCount.Value;
end;

initialization

  RegisterIntegerConsts(TypeInfo(TAlphaColor), System.UIConsts.IdentToAlphaColor, System.UIConsts.AlphaColorToIdent);

end.
