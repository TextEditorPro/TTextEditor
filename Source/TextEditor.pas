{$WARN WIDECHAR_REDUCED OFF} // CharInSet is slow in loops
unit TextEditor;

{$I TextEditor.Defines.inc}

interface

{$IF CompilerVersion < 23}
  {$MESSAGE FATAL 'Only RAD Studio XE2 and later supported.'}
{$IFEND}

uses
  Winapi.Messages, Winapi.Windows, System.Classes, System.Contnrs, System.Math, System.SysUtils, System.UITypes,
  Vcl.Controls, Vcl.DBCtrls, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, Data.DB,
  TextEditor.ActiveLine, TextEditor.Caret, TextEditor.CodeFolding, TextEditor.CodeFolding.Hint.Form,
  TextEditor.CodeFolding.Ranges, TextEditor.CodeFolding.Regions, TextEditor.Colors, TextEditor.CompletionProposal,
  TextEditor.CompletionProposal.PopupWindow, TextEditor.CompletionProposal.Snippets, TextEditor.Consts,
  TextEditor.Fonts, TextEditor.Glyph, TextEditor.Highlighter, TextEditor.Highlighter.Attributes,
  TextEditor.HighlightLine, TextEditor.InternalImage, TextEditor.KeyboardHandler, TextEditor.KeyCommands,
  TextEditor.LeftMargin, TextEditor.Lines, TextEditor.MacroRecorder, TextEditor.Marks, TextEditor.MatchingPairs,
  TextEditor.Minimap, TextEditor.PaintHelper, TextEditor.Replace, TextEditor.RightMargin, TextEditor.Ruler,
  TextEditor.Scroll, TextEditor.Search, TextEditor.Search.Base, TextEditor.Selection, TextEditor.SkipRegions,
  TextEditor.SpecialChars, TextEditor.SyncEdit, TextEditor.Tabs, TextEditor.Types, TextEditor.Undo,
  TextEditor.Undo.List, TextEditor.UnknownChars, TextEditor.Utils, TextEditor.WordWrap
{$IFDEF TEXT_EDITOR_SPELL_CHECK}
  , TextEditor.SpellCheck
{$ENDIF}
{$IFDEF ALPHASKINS}
  , acSBUtils, sCommonData
{$ENDIF};

type
  TTextEditorDefaults = record
  const
    BorderStyle = bsSingle;
    CanChangeSize = True;
    Cursor = crIBeam;
    FileMaxReadBufferSize = 524288;
    FileMinShowProgressSize = 4194304;
    Height = 150;
    LineSpacing = 0;
    MaxLength = 0;
    Options = [eoAutoIndent, eoDragDropEditing, eoLoadColors, eoLoadFontNames, eoLoadFontSizes, eoLoadFontStyles,
      eoShowNullCharacters, eoShowControlCharacters];
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

  TCustomTextEditor = class abstract(TCustomControl)
  strict private type
    TTextEditorCaretHelper = record
      ShowAlways: Boolean;
      Offset: TPoint;
    end;

    TTextEditorCharacterCount = record
      Calculate: Boolean;
      Value: Integer;
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
      OnAdditionalKeywords: TTextEditorAdditionalKeywordsEvent;
      OnAfterBookmarkPlaced: TTextEditorBookmarkPlacedEvent;
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
      OnKeyPressW: TTextEditorKeyPressWEvent;
      OnLeftMarginClick: TLeftMarginClickEvent;
      OnLinesDeleted: TStringListChangeEvent;
      OnLinesInserted: TStringListChangeEvent;
      OnLinesPutted: TStringListChangeEvent;
      OnLinkClick: TTextEditorLinkClickEvent;
      OnLoadingProgress: TNotifyEvent;
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
      MouseMovePoint: TPoint;
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

    TTextEditorMultiEdit = record
      Carets: TList;
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
      SelectionBegin: TTextEditorTextPosition;
      SelectionEnd: TTextEditorTextPosition;
      Text: TTextEditorTextPosition;
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
      HorizontalVisible: Boolean;
      IsScrolling: Boolean;
      PageWidth: Integer;
      Shadow: TTextEditorScrollShadowHelper;
      Timer: TTextEditorTimer;
      VerticalVisible: Boolean;
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
      Background: TColor;
      Border: TColor;
      CharsBefore: Integer;
      CustomBackgroundColor: Boolean;
      EmptySpace: TTextEditorEmptySpace;
      ExpandedCharsBefore: Integer;
      FontStyle: TFontStyles;
      Foreground: TColor;
      Length: Integer;
      Overhang: Boolean;
      RightToLeftToken: Boolean;
      Text: string;
      Underline: TTextEditorUnderline;
      UnderlineColor: TColor;
    end;

    TTextEditorZoom = record
      Divider: Integer;
      Percentage: Integer;
      Return: Boolean;
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
    FCharacterCount: TTextEditorCharacterCount;
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
    FFonts: TTextEditorFonts;
    FFontStyles: TTextEditorFontStyles;
    FHighlightedFoldRange: TTextEditorCodeFoldingRange;
    FHighlighter: TTextEditorHighlighter;
    FHighlightLine: TTextEditorHighlightLine;
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
    FMaxLength: Integer;
    FMinimap: TTextEditorMinimap;
    FMinimapHelper: TTextEditorMinimapHelper;
    FMouse: TTextEditorMouse;
    FMultiEdit: TTextEditorMultiEdit;
    FOptions: TTextEditorOptions;
    FOriginal: TTextEditorOriginal;
    FOvertypeMode: TTextEditorOvertypeMode;
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
    FSpecialChars: TTextEditorSpecialChars;
{$IFDEF TEXT_EDITOR_SPELL_CHECK}
    FSpellCheck: TTextEditorSpellCheck;
{$ENDIF}
    FState: TTextEditorState;
    FSyncEdit: TTextEditorSyncEdit;
    FSystemMetrics: TTextEditorSystemMetrics;
    FTabs: TTextEditorTabs;
    FTheme: TTextEditorTheme;
    FToggleCase: TTextEditorToggleCase;
    FUndo: TTextEditorUndo;
    FUndoList: TTextEditorUndoList;
    FUnknownChars: TTextEditorUnknownChars;
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
    function DoOnCodeFoldingHintClick(const APoint: TPoint): Boolean;
    function FindHookedCommandEvent(const AHookedCommandEvent: TTextEditorHookedCommandEvent): Integer;
    function FreeMinimapBitmaps: Boolean;
    function GetCanPaste: Boolean;
    function GetCanRedo: Boolean;
    function GetCanUndo: Boolean;
    function GetCaretIndex: Integer;
    function GetCharAtCursor: Char;
    function GetCharAtTextPosition(const ATextPosition: TTextEditorTextPosition; const ASelect: Boolean = False): Char;
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
    function GetMultiCaretSelectedText: string;
    function GetPreviousCharAtCursor: Char;
    function GetRowCountFromPixel(const AY: Integer): Integer;
    function GetScrollPageWidth: Integer;
    function GetSelectedRow(const AY: Integer): Integer;
    function GetSelectedText: string;
    function GetSelectionAvailable: Boolean;
    function GetSelectionBeginPosition: TTextEditorTextPosition;
    function GetSelectionEndPosition: TTextEditorTextPosition;
    function GetSelectionLength: Integer;
    function GetSelectionLineCount: Integer;
    function GetSelectionStart: Integer;
    function GetTabText(var ATextPosition: TTextEditorTextPosition): string;
    function GetText: string;
    function GetTextBetween(const ATextBeginPosition: TTextEditorTextPosition; const ATextEndPosition: TTextEditorTextPosition): string;
    function GetTextPosition: TTextEditorTextPosition;
    function GetTokenCharCount(const AToken: string; const ACharsBefore: Integer): Integer; inline;
    function GetTokenWidth(const AToken: string; const ALength: Integer; const ACharsBefore: Integer; const AMinimap: Boolean = False; const ARTLReading: Boolean = False): Integer;
    function GetViewLineNumber(const AViewLineNumber: Integer): Integer;
    function GetViewTextLineNumber(const AViewLineNumber: Integer): Integer;
    function GetVisibleChars(const ARow: Integer; const ALineText: string = ''): Integer;
    function IsTextPositionInSearchBlock(const ATextPosition: TTextEditorTextPosition): Boolean;
    function LeftSpaceCount(const ALine: string): Integer;
    function NextWordPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition; overload;
    function NextWordPosition: TTextEditorTextPosition; overload;
    function OpenClipboard: Boolean;
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
    procedure AddUndoDelete(const ACaretPosition: TTextEditorTextPosition;
      const ASelectionBeginPosition, ASelectionEndPosition: TTextEditorTextPosition;
      const AChangeText: string; SelectionMode: TTextEditorSelectionMode; AChangeBlockNumber: Integer = 0);
    procedure AddUndoInsert(const ACaretPosition: TTextEditorTextPosition;
      const ASelectionBeginPosition, ASelectionEndPosition: TTextEditorTextPosition;
      const AChangeText: string; SelectionMode: TTextEditorSelectionMode; AChangeBlockNumber: Integer = 0);
    procedure AddUndoPaste(const ACaretPosition: TTextEditorTextPosition;
      const ASelectionBeginPosition, ASelectionEndPosition: TTextEditorTextPosition;
      const AChangeText: string; SelectionMode: TTextEditorSelectionMode; AChangeBlockNumber: Integer = 0);
    procedure AddSnippets(const AItems: TTextEditorCompletionProposalItems; const AAddDescription: Boolean = False);
    procedure AfterSetText(ASender: TObject);
    procedure AssignSearchEngine(const AEngine: TTextEditorSearchEngine);
    procedure BeforeSetText(ASender: TObject);
    procedure BookmarkListChange(ASender: TObject);
    procedure CMGestureManagerChanged(var Message: TMessage); message CM_GESTUREMANAGERCHANGED;
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
    procedure CodeFoldingLinesDeleted(const AFirstLine: Integer; const ACount: Integer);
    procedure CodeFoldingOnChange(const AEvent: TTextEditorCodeFoldingChanges);
    procedure CodeFoldingResetCaches;
    procedure ColorsChanged(ASender: TObject);
    procedure CompletionProposalTimerHandler(ASender: TObject);
    procedure ComputeScroll(const APoint: TPoint);
    procedure CreateBookmarkImages;
    procedure CreateLineNumbersCache(const AReset: Boolean = False);
    procedure CreateShadowBitmap(const AClipRect: TRect; const ABitmap: Vcl.Graphics.TBitmap; const AShadowAlphaArray: TTextEditorArrayOfSingle; const AShadowAlphaByteArray: PByteArray);
    procedure DecCharacterCount(const AText: string);
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
    procedure EnsureCaretPositionInsideLines(const ATextPosition: TTextEditorTextPosition);
    procedure FindWords(const AWord: string; const AList: TList; const ACaseSensitive: Boolean; const AWholeWordsOnly: Boolean);
    procedure FontChanged(ASender: TObject);
    procedure FreeMultiCarets;
    procedure FreeScrollShadowBitmap;
    procedure GetCommentAtTextPosition(const ATextPosition: TTextEditorTextPosition; var AComment: string);
    procedure GetMinimapLeftRight(var ALeft: Integer; var ARight: Integer);
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
    procedure MoveLineDown;
    procedure MoveLineUp;
{$IFDEF TEXT_EDITOR_SPELL_CHECK}
    procedure MoveSpellCheckItems(const ALine: Integer; const ACount: Integer);
{$ENDIF}
    procedure MultiCaretTimerHandler(ASender: TObject);
    procedure OnCodeFoldingDelayTimer(ASender: TObject);
    procedure OpenLink(const AURI: string);
    procedure ReplaceChanged(const AEvent: TTextEditorReplaceChanges);
    procedure RightMarginChanged(ASender: TObject);
    procedure RulerChanged(ASender: TObject);
    procedure ScanCodeFoldingMatchingPair;
{$IFDEF TEXT_EDITOR_SPELL_CHECK}
    procedure ScanSpellCheck(const AFromLine: Integer; const AToLine: Integer);
{$ENDIF}
    procedure ScanMatchingPair;
    procedure ScanTagMatchingPair;
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
    procedure SetFileMaxReadBufferSize(const AValue: Integer);
    procedure SetFileMinShowProgressSize(const AValue: Int64);
    procedure SetFullFilename(const AName: string);
    procedure SetHighlightLine(const AValue: TTextEditorHighlightLine);
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
    procedure ShowCodeFoldingHint(const X, Y: Integer);
    procedure ShowMovingHint;
    procedure ShowRulerLegerLine(const X, Y: Integer);
    procedure SpecialCharsChanged(ASender: TObject);
    procedure SplitTextIntoWords(const AItems: TTextEditorCompletionProposalItems; const AAddDescription: Boolean = False);
    procedure SwapInt(var ALeft: Integer; var ARight: Integer); inline;
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
    procedure ValidateMultiCarets;
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
    function DoOnReplaceText(const AParams: TTextEditorReplaceTextParams): TTextEditorReplaceAction;
    function DoSearchMatchNotFoundWraparoundDialog: Boolean; virtual;
    function GetReadOnly: Boolean; virtual;
    function PixelAndRowToViewPosition(const X, ARow: Integer; const ALineText: string = ''): TTextEditorViewPosition;
    function PixelsToViewPosition(const X, Y: Integer): TTextEditorViewPosition;
    function TextPositionToCharIndex(const ATextPosition: TTextEditorTextPosition): Integer;
    procedure ChangeScale(AMultiplier, ADivider: Integer{$IF CompilerVersion >= 35}; AIsDpiChange: Boolean{$IFEND}); override;
    procedure CodeFoldingExpand(const AFoldRange: TTextEditorCodeFoldingRange);
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure CreateWnd; override;
    procedure DblClick; override;
    procedure DestroyWnd; override;
    procedure DoBlockIndent;
    procedure DoBlockUnindent;
    procedure DoChange; virtual;
    procedure DoCopyToClipboard(const AText: string);
    procedure DoGetGestureOptions(var Gestures: TInteractiveGestures; var Options: TInteractiveGestureOptions); override;
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
    procedure PaintCodeFoldingCollapseMark(const AFoldRange: TTextEditorCodeFoldingRange; const ACurrentLineText: string; const ATokenPosition, ATokenLength, ALine: Integer; const ALineRect: TRect);
    procedure PaintCodeFoldingCollapsedLine(const AFoldRange: TTextEditorCodeFoldingRange; const ALineRect: TRect);
    procedure PaintCodeFoldingGuides(const AFirstRow, ALastRow: Integer);
    procedure PaintCodeFoldingLine(const AClipRect: TRect; const ALine: Integer);
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
    procedure SetAlwaysShowCaret(const AValue: Boolean);
    procedure SetName(const AValue: TComponentName); override;
    procedure SetReadOnly(const AValue: Boolean); virtual;
    procedure SetViewPosition(const AValue: TTextEditorViewPosition);
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
    function FindFirst: Boolean;
    function FindLast: Boolean;
    function FindNext(const AHandleNotFound: Boolean = True): Boolean;
    function FindPrevious(const AHandleNotFound: Boolean = True): Boolean;
    function GetBookmark(const AIndex: Integer; var ATextPosition: TTextEditorTextPosition): Boolean;
    function GetClipboardText: string;
    function GetCompareLineNumberOffsetCache(const ALine: Integer): Integer;
    function GetNextBreakPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition;
    function GetPreviousBreakPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorTextPosition;
    function GetTextPositionOfMouse(out ATextPosition: TTextEditorTextPosition): Boolean;
    function GetWordAtPixels(const X, Y: Integer): string;
    function IsCommentAtCaretPosition: Boolean;
    function IsCommentChar(const AChar: Char): Boolean;
    function IsKeywordAtCaretPosition(const APOpenKeyWord: PBoolean = nil): Boolean;
    function IsKeywordAtCaretPositionOrAfter(const ATextPosition: TTextEditorTextPosition): Boolean;
    function IsMultiEditCaretFound(const ALine: Integer): Boolean;
    function IsTextPositionInSelection(const ATextPosition: TTextEditorTextPosition): Boolean;
    function IsWordBreakChar(const AChar: Char): Boolean; inline;
    function IsWordSelected: Boolean;
    function PixelsToTextPosition(const X, Y: Integer): TTextEditorTextPosition;
    function ReplaceSelectedText(const AReplaceText: string; const ASearchText: string; const AAction: TTextEditorReplaceTextAction = rtaReplace): Boolean;
    function ReplaceText(const ASearchText: string; const AReplaceText: string; const AReplaceAll: Boolean = True; const APageIndex: Integer = -1): Integer;
    function SaveToFile(const AFilename: string; const AEncoding: System.SysUtils.TEncoding = nil): Boolean;
    function SearchStatus: string;
    function TextToHTML(const AClipboardFormat: Boolean = False): string;
    function TextToViewPosition(const ATextPosition: TTextEditorTextPosition): TTextEditorViewPosition;
    function TranslateKeyCode(const ACode: Word; const AShift: TShiftState): TTextEditorCommand;
    function ViewPositionToPixels(const AViewPosition: TTextEditorViewPosition; const ALineText: string = ''): TPoint;
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
    procedure BeginUpdate;
    procedure ChainEditor(const AEditor: TCustomTextEditor);
    procedure ChangeObjectScale(const AMultiplier: Integer; const ADivider: Integer{$IF CompilerVersion >= 35}; const AIsDpiChange: Boolean{$IFEND});
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
{$IFDEF BASENCODING}
    procedure Decode(const ACoding: TTextEditorCoding);
{$ENDIF}
    procedure DecPaintLock;
    procedure DeleteBookmark(ABookmark: TTextEditorMark); overload;
    procedure DeleteComments;
    procedure DeleteEmptyLines;
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
    procedure FreeBookmarkImages;
    procedure GoToBookmark(const AIndex: Integer);
    procedure GoToLine(const ALine: Integer);
    procedure GoToLineAndSetPosition(const ALine: Integer; const AChar: Integer = 1; const AResultPosition: TTextEditorResultPosition = rpMiddle);
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
    procedure SaveToStream(const AStream: TStream; const AEncoding: System.SysUtils.TEncoding = nil; const AChangeModified: Boolean = True);
    procedure SelectAll;
    procedure SetBookmark(const AIndex: Integer; const ATextPosition: TTextEditorTextPosition; const AImageIndex: Integer = -1);
    procedure SetClipboardText(const AText: string; const AHTML: string = '');
    procedure SetFocus; override;
    procedure SetMark(const AIndex: Integer; const ATextPosition: TTextEditorTextPosition; const AImageIndex: Integer; const AColor: TColor = TColors.SysNone);
    procedure SetOption(const AOption: TTextEditorOption; const AEnabled: Boolean);
    procedure SetSelectedTextEmpty(const AChangeString: string = '');
    procedure SetTextPositionAndSelection(const ATextPosition, ABlockBeginPosition, ABlockEndPosition: TTextEditorTextPosition);
    procedure SizeOrFontChanged(const AFontChanged: Boolean = True);
    procedure Sort(const AOptions: TTextEditorSortOptions);
{$IFDEF TEXT_EDITOR_SPELL_CHECK}
    procedure SpellCheckFindNextError;
    procedure SpellCheckFindPreviousError;
{$ENDIF}
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
    procedure UpdateColors;
    procedure WndProc(var AMessage: TMessage); override;
    procedure Zoom(const APercentage: Integer);
    property Action;
    property ActiveLine: TTextEditorActiveLine read FActiveLine write SetActiveLine;
    property AllCodeFoldingRanges: TTextEditorAllCodeFoldingRanges read FCodeFoldings.AllRanges;
    property AlwaysShowCaret: Boolean read FCaretHelper.ShowAlways write SetAlwaysShowCaret;
    property Bookmarks: TTextEditorMarkList read FBookmarkList;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default TTextEditorDefaults.BorderStyle;
{$IFDEF ALPHASKINS}
    property BoundLabel: TsBoundLabel read FBoundLabel write FBoundLabel;
{$ENDIF}
    property CanChangeSize: Boolean read FState.CanChangeSize write FState.CanChangeSize default TTextEditorDefaults.CanChangeSize;
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
    property Cursor default TTextEditorDefaults.Cursor;
    property FileDateTime: TDateTime read FFile.DateTime write FFile.DateTime;
    property FileMaxReadBufferSize: Integer Read FFile.MaxReadBufferSize write SetFileMaxReadBufferSize default TTextEditorDefaults.FileMaxReadBufferSize;
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
    property HorizontalScrollPosition: Integer read FScrollHelper.HorizontalPosition write SetHorizontalScrollPosition;
    property HotFilename: string read FFile.HotName write FFile.HotName;
    property IsScrolling: Boolean read FScrollHelper.IsScrolling;
    property KeyCommands: TTextEditorKeyCommands read FKeyCommands write SetKeyCommands stored False;
    property LeftMargin: TTextEditorLeftMargin read FLeftMargin write SetLeftMargin;
    property LineHeight: Integer read GetLineHeight;
    property LineNumbersCount: Integer read FLineNumbers.Count;
    property LineSpacing: Integer read FLineSpacing write FLineSpacing default TTextEditorDefaults.LineSpacing;
    property Lines: TTextEditorLines read FLines write SetLines;
    property MacroRecorder: TTextEditorMacroRecorder read FMacroRecorder write FMacroRecorder;
    property Marks: TTextEditorMarkList read FMarkList;
    property MatchingPairs: TTextEditorMatchingPairs read FMatchingPairs write FMatchingPairs;
    property MaxLength: Integer read FMaxLength write FMaxLength default TTextEditorDefaults.MaxLength;
    property Minimap: TTextEditorMinimap read FMinimap write FMinimap;
    property Modified: Boolean read FState.Modified write SetModified;
    property MouseScrollCursors[const AIndex: Integer]: HCursor read GetMouseScrollCursors write SetMouseScrollCursors;
    property OnAdditionalKeywords: TTextEditorAdditionalKeywordsEvent read FEvents.OnAdditionalKeywords write FEvents.OnAdditionalKeywords;
    property OnAfterBookmarkPlaced: TTextEditorBookmarkPlacedEvent read FEvents.OnAfterBookmarkPlaced write FEvents.OnAfterBookmarkPlaced;
    property OnAfterDeleteBookmark: TTextEditorBookmarkDeletedEvent read FEvents.OnAfterDeleteBookmark write FEvents.OnAfterDeleteBookmark;
    property OnAfterDeleteLine: TNotifyEvent read FEvents.OnAfterDeleteLine write FEvents.OnAfterDeleteLine;
    property OnAfterDeleteMark: TNotifyEvent read FEvents.OnAfterDeleteMark write FEvents.OnAfterDeleteMark;
    property OnAfterDeleteSelection: TNotifyEvent read FEvents.OnAfterDeleteSelection write FEvents.OnAfterDeleteSelection;
    property OnAfterLineBreak: TNotifyEvent read FEvents.OnAfterLineBreak write FEvents.OnAfterLineBreak;
    property OnAfterLinePaint: TTextEditorLinePaintEvent read FEvents.OnAfterLinePaint write FEvents.OnAfterLinePaint;
    property OnAfterMarkPanelPaint: TTextEditorMarkPanelPaintEvent read FEvents.OnAfterMarkPanelPaint write FEvents.OnAfterMarkPanelPaint;
    property OnAfterMarkPlaced: TNotifyEvent read FEvents.OnAfterMarkPlaced write FEvents.OnAfterMarkPlaced;
    property OnBeforeDeleteMark: TTextEditorMarkEvent read FEvents.OnBeforeDeleteMark write FEvents.OnBeforeDeleteMark;
    property OnBeforeMarkPanelPaint: TTextEditorMarkPanelPaintEvent read FEvents.OnBeforeMarkPanelPaint write FEvents.OnBeforeMarkPanelPaint;
    property OnBeforeMarkPlaced: TTextEditorMarkEvent read FEvents.OnBeforeMarkPlaced write FEvents.OnBeforeMarkPlaced;
    property OnBeforeSaveToFile: TTextEditorSaveToFileEvent read FEvents.OnBeforeSaveToFile write FEvents.OnBeforeSaveToFile;
    property OnCaretChanged: TTextEditorCaretChangedEvent read FEvents.OnCaretChanged write FEvents.OnCaretChanged;
    property OnChange: TNotifyEvent read FEvents.OnChange write FEvents.OnChange;
    property OnChangeScale: TTexteditorChangeScaleEvent read FEvents.OnChangeScale write FEvents.OnChangeScale;
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
    property OnLinkClick: TTextEditorLinkClickEvent read FEvents.OnLinkClick write FEvents.OnLinkClick;
    property OnLoadingProgress: TNotifyEvent read FEvents.OnLoadingProgress write FEvents.OnLoadingProgress;
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
    property Options: TTextEditorOptions read FOptions write SetOptions default TTextEditorDefaults.Options;
    property PaintLock: Integer read FPaintLock write FPaintLock;
    property ParentColor default TTextEditorDefaults.ParentColor;
    property ParentFont default TTextEditorDefaults.ParentFont;
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
    property OvertypeMode: TTextEditorOvertypeMode read FOvertypeMode write SetOvertypeMode default TTextEditorDefaults.OvertypeMode;
    property Tabs: TTextEditorTabs read FTabs write SetTabs;
    property TabStop default TTextEditorDefaults.TabStop;
    property Text: string read GetText write SetText;
    property TextBetween[const ATextBeginPosition: TTextEditorTextPosition; const ATextEndPosition: TTextEditorTextPosition]: string read GetTextBetween write SetTextBetween;
    property TextPosition: TTextEditorTextPosition read GetTextPosition write SetTextPosition;
    property Theme: TTextEditorTheme read FTheme write FTheme;
    property TopLine: Integer read FLineNumbers.TopLine write SetTopLine;
    property Undo: TTextEditorUndo read FUndo write SetUndo;
    property UndoList: TTextEditorUndoList read FUndoList;
    property UnknownChars: TTextEditorUnknownChars read FUnknownChars write SetUnknownChars;
    property URIOpener: Boolean read FState.URIOpener write FState.URIOpener;
    property ViewPosition: TTextEditorViewPosition read FViewPosition write SetViewPosition;
    property VisibleLineCount: Integer read FLineNumbers.VisibleCount;
    property WantReturns: Boolean read FState.WantReturns write FState.WantReturns default TTextEditorDefaults.WantReturns;
    property WordWrap: TTextEditorWordWrap read FWordWrap write SetWordWrap;
    property ZoomDivider: Integer read FZoom.Divider write FZoom.Divider default TTextEditorDefaults.ZoomDivider;
    property ZoomPercentage: Integer read FZoom.Percentage write FZoom.Percentage default TTextEditorDefaults.ZoomPercentage;
  end;

  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
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
    property Colors;
    property CompletionProposal;
    property Constraints;
    property Ctl3D;
    property Cursor;
    property Enabled;
    property FileMaxReadBufferSize;
    property FileMinShowProgressSize;
    property FontStyles;
    property Fonts;
    property Height;
    property HighlightLine;
    property Highlighter;
    property ImeMode;
    property ImeName;
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
    property OnAfterMarkPanelPaint;
    property OnAfterMarkPlaced;
    property OnBeforeDeleteMark;
    property OnBeforeMarkPanelPaint;
    property OnBeforeMarkPlaced;
    property OnBeforeSaveToFile;
    property OnCaretChanged;
    property OnChange;
    property OnChangeScale;
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
    property OnLinkClick;
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
    property StyleElements;
    property SyncEdit;
    property TabOrder;
    property Tabs;
    property TabStop;
    property Tag;
    property Theme;
    property Touch;
    property Undo;
    property UnknownChars;
    property Visible;
    property WantReturns;
    property Width;
    property WordWrap;
    property ZoomPercentage;
  end;

  TCustomDBTextEditor = class abstract(TCustomTextEditor)
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
    procedure ExecuteCommand(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer); override;
    procedure LoadBlob;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  end;

  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
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
    property Colors;
    property CompletionProposal;
    property Constraints;
    property Ctl3D;
    property Cursor;
    property DataField;
    property DataSource;
    property Enabled;
    property Field;
    property FileMaxReadBufferSize;
    property FileMinShowProgressSize;
    property FontStyles;
    property Fonts;
    property Height;
    property HighlightLine;
    property Highlighter;
    property ImeMode;
    property ImeName;
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
    property OnAfterMarkPanelPaint;
    property OnAfterMarkPlaced;
    property OnBeforeDeleteMark;
    property OnBeforeMarkPanelPaint;
    property OnBeforeMarkPlaced;
    property OnBeforeSaveToFile;
    property OnCaretChanged;
    property OnChange;
    property OnChangeScale;
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
    property OnLinkClick;
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
    property StyleElements;
    property SyncEdit;
    property TabOrder;
    property Tabs;
    property TabStop;
    property Tag;
    property Theme;
    property Touch;
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

{$R TextEditor.res}

uses
  Winapi.Imm, Winapi.ShellAPI, System.Character, System.Generics.Collections, System.RegularExpressions,
  System.StrUtils, System.Types, Vcl.Clipbrd, Vcl.ImgList, Vcl.Menus, TextEditor.Export.HTML,
  TextEditor.Highlighter.Rules, TextEditor.Language, TextEditor.LeftMargin.Border, TextEditor.LeftMargin.LineNumbers,
  TextEditor.Scroll.Hint, TextEditor.Search.Map, TextEditor.Search.Normal, TextEditor.Search.RegularExpressions,
  TextEditor.Search.WildCard, TextEditor.Undo.Item
{$IFDEF ALPHASKINS}
  , acGlow, sConst, sMessages, sSkinManager, sStyleSimply, sVCLUtils
{$ENDIF}
{$IFDEF BASENCODING}
  , TextEditor.Encoding
{$ENDIF}
{$IFDEF VCL_STYLES}
  , TextEditor.StyleHooks
{$ENDIF};

type
  TTextEditorAccessWinControl = class(TWinControl);

const
  ETO_OPTIONS = ETO_OPAQUE or ETO_CLIPPED;

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
begin
{$IFDEF ALPHASKINS}
  FSkinData := TsScrollWndData.Create(Self, True);
  FSkinData.COC := COC_TsMemo;
  FSkinData.CustomColor := True;
  FSkinData.CustomFont := True;
  StyleElements := [seBorder];
{$ENDIF}

  inherited Create(AOwner);

  Height := TTextEditorDefaults.Height;
  Width := TTextEditorDefaults.Width;
  Cursor := TTextEditorDefaults.Cursor;
  Color := TColors.SysWindow;
  DoubleBuffered := False;
  ControlStyle := ControlStyle + [csOpaque, csSetCaption, csNeedsBorderPaint];

  FState.CanChangeSize := TTextEditorDefaults.CanChangeSize;
  FFile.Loaded := False;
  FFile.Saved := False;
  FFile.MaxReadBufferSize := TTextEditorDefaults.FileMaxReadBufferSize;
  FFile.MinShowProgressSize := TTextEditorDefaults.FileMinShowProgressSize;

  FSystemMetrics.HorizontalDrag := GetSystemMetrics(SM_CXDRAG);
  FSystemMetrics.VerticalDrag := GetSystemMetrics(SM_CYDRAG);
  FSystemMetrics.VerticalScroll := GetSystemMetrics(SM_CYVSCROLL);

  FBorderStyle := TTextEditorDefaults.BorderStyle;
  FDoubleClickTime := GetDoubleClickTime;
  FLineNumbers.ResetCache := True;
  FMaxLength := TTextEditorDefaults.MaxLength;
  FToggleCase.Text := '';
  FState.URIOpener := False;
  FState.ReadOnly := TTextEditorDefaults.ReadOnly;
  FMultiEdit.Position.Row := -1;
  { Zoom }
  FZoom.Divider := TTextEditorDefaults.ZoomDivider;
  FZoom.Percentage := TTextEditorDefaults.ZoomPercentage;
  FZoom.Return := False;
  { Character count }
  ResetCharacterCount;
  { Code folding }
  FCodeFoldings.AllRanges := TTextEditorAllCodeFoldingRanges.Create;
  FCodeFolding := TTextEditorCodeFolding.Create;
  FCodeFolding.OnChange := CodeFoldingOnChange;
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

  { Unknown chars }
  FUnknownChars := TTextEditorUnknownChars.Create;
  FUnknownChars.OnChange := UnknownCharsChanged;
  { Fonts }
  FFonts := TTextEditorFonts.Create;
  FFonts.CodeFoldingHint.OnChange := FontChanged;
  FFonts.CompletionProposal.OnChange := FontChanged;
  FFonts.LineNumbers.OnChange := FontChanged;
  FFonts.Minimap.OnChange := FontChanged;
  FFonts.Ruler.OnChange := FontChanged;
  FFonts.Text.OnChange := FontChanged;
  FFontStyles := TTextEditorFontStyles.Create;
  { Painting }
  FPaintHelper := TTextEditorPaintHelper.Create([], FFonts.Text);
  FItalic.Bitmap := TBitmap.Create;
  FItalic.Offset := 0;
  ParentColor := TTextEditorDefaults.ParentColor;
  ParentFont := TTextEditorDefaults.ParentFont;
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
  TabStop := TTextEditorDefaults.TabStop;
  FTabs := TTextEditorTabs.Create;
  FTabs.OnChange := TabsChanged;
  { Text }
  FOvertypeMode := TTextEditorDefaults.OvertypeMode;
  FKeyboardHandler := TTextEditorKeyboardHandler.Create;
  FKeyCommands := TTextEditorKeyCommands.Create(Self);
  SetDefaultKeyCommands;
  FState.WantReturns := TTextEditorDefaults.WantReturns;
  FScrollHelper.HorizontalPosition := 0;
  FLineNumbers.TopLine := 1;
  FViewPosition.Column := 1;
  FViewPosition.Row := 1;
  FPosition.SelectionBegin.Char := 1;
  FPosition.SelectionBegin.Line := 1;
  FPosition.SelectionEnd := FPosition.SelectionBegin;
  FOptions := TTextEditorDefaults.Options;

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
  { Highlight line }
  FHighlightLine := TTextEditorHighlightLine.Create(Self);
  { Highlighter }
  FHighlighter := TTextEditorHighlighter.Create(Self);
  FHighlighter.Lines := FLines;

  { Theme }
  if csDesigning in ComponentState then
    FTheme := TTextEditorTheme.Create(FHighlighter);

  { Mouse wheel scroll cursors }
  for LIndex := 0 to 7 do
    FMouse.ScrollCursors[LIndex] := LoadCursor(HInstance, PChar(TResourceBitmap.MouseMoveScroll + IntToStr(LIndex)));

  { Update character constraints }
  SizeOrFontChanged;
  TabsChanged(nil);
{$IFDEF ALPHASKINS}
  FBoundLabel := TsBoundLabel.Create(Self, FSkinData);
{$ENDIF}
end;

destructor TCustomTextEditor.Destroy;
begin
{$IFDEF ALPHASKINS}
  if Assigned(FScrollHelper.Wnd) then
    FScrollHelper.Wnd.Free;

  if Assigned(FSkinData) then
    FSkinData.Free;
{$ENDIF}

  if Assigned(FChainedEditor) then
    RemoveChainedEditor;

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

  { Do not use FreeAndNil, it first nils and then frees causing problems with code accessing FHookedCommandHandlers
    while destruction }
  FHookedCommandHandlers.Free;
  FHookedCommandHandlers := nil;

  FBookmarkList.Free;
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
  FScroll.Free;
  FSearch.Free;
  FReplace.Free;
  FTabs.Free;
  FUndo.Free;
  FSpecialChars.Free;
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

{$IFDEF ALPHASKINS}
  FBoundLabel.Free;
{$ENDIF}

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

  if LKeyword.IsEmpty then
    LKeyword := GetCharAtTextPosition(LTextPosition);

  if LKeyword.IsEmpty then
    Exit;

  for LIndex := 0 to FCompletionProposal.Snippets.Items.Count - 1 do
  begin
    LSnippetItem := FCompletionProposal.Snippets.Item[LIndex];

    if (LSnippetItem.ExecuteWith = AExecuteWith) and (LSnippetItem.Keyword.Trim = LKeyword) then
    begin
      InsertSnippet(LSnippetItem, LTextPosition);
      Exit(True);
    end;
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
  Result := CharIndexToTextPosition(ACharIndex, GetBOFPosition);
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

  for LIndex := ATextBeginPosition.Line to FLines.Count - 1 do
  begin
    LLineLength := Length(FLines.Items^[LIndex].TextLine) - LBeginChar + 1;

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
    Result := FCodeFoldings.RangeFromLine[ALine]
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

  FMinimap.TopLine := Max(1, Trunc((LTemp / Max(FMinimap.VisibleLineCount - FLineNumbers.VisibleCount, 1)) * LTemp2));

  if (LTemp > 0) and (FMinimap.TopLine > LTemp) then
    FMinimap.TopLine := LTemp;

  LTopLine := Max(1, FMinimap.TopLine + LTemp2);

  if TopLine <> LTopLine then
  begin
    TopLine := LTopLine;

    FMinimap.TopLine := Max(FLineNumbers.TopLine - Abs(Trunc((FMinimap.VisibleLineCount - FLineNumbers.VisibleCount) *
      (FLineNumbers.TopLine / Max(Max(FLineNumbers.Count, 1) - FLineNumbers.VisibleCount, 1)))), 1);

    Repaint;
  end;
end;

procedure TCustomTextEditor.PaintCaret;
var
  LIndex: Integer;
  LMultiCaretRecord: TTextEditorMultiCaretRecord;
begin
  if GetSelectionAvailable then
    Exit;

  if Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) then
  begin
    LIndex := 0;

    while LIndex < FMultiEdit.Carets.Count do
    begin
      LMultiCaretRecord := PTextEditorMultiCaretRecord(FMultiEdit.Carets[LIndex])^;

      if (LMultiCaretRecord.ViewPosition.Row >= FLineNumbers.TopLine) and
        (LMultiCaretRecord.ViewPosition.Row <= FLineNumbers.TopLine + FLineNumbers.VisibleCount) then
        PaintCaretBlock(LMultiCaretRecord.ViewPosition);

      Inc(LIndex);
    end
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

  if (ATextPosition.Line >= 0) and (ATextPosition.Line < FLines.Count) then
  begin
    LTextLine := FLines.Items^[ATextPosition.Line].TextLine;
    LLength := Length(LTextLine);

    if LLength = 0 then
      Exit;

    if ATextPosition.Char <= LLength then
      Result := LTextLine[ATextPosition.Char];

    if ASelect then
    begin
      FPosition.SelectionBegin.Char := ATextPosition.Char;
      FPosition.SelectionBegin.Line := ATextPosition.Line;
      FPosition.SelectionEnd.Char := ATextPosition.Char + 1;
      FPosition.SelectionEnd.Line := ATextPosition.Line;
    end;
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
      end
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
  LPositionX, LPositionY: Integer;
  LLine: string;
  LTokenType: TTextEditorRangeType;
  LToken: string;
  LEnd: Integer;
begin
  LPositionY := ATextPosition.Line;

  if (LPositionY >= 0) and (LPositionY < FLines.Count) then
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
  if FColors.BookmarkLineBackground <> TColors.SysNone then
  for LIndex := 0 to FBookmarkList.Count - 1 do
  begin
    LMark := FBookmarkList.Items[LIndex];

    if LMark.Line + 1 = ALine then
    begin
      Result := FColors.BookmarkLineBackground;
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
    LToken := TextEditor.Utils.Trim(LowerCase(LOriginalToken));

    if LToken.IsEmpty then
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
      Exit(TMouseWheelScrollCursors.NorthWest)
    else
    if (LCursorPoint.X >= LLeftX) and (LCursorPoint.X <= LRightX) then
      Exit(TMouseWheelScrollCursors.North)
    else
      Exit(TMouseWheelScrollCursors.NorthEast)
  end;

  if LCursorPoint.Y > LBottomY then
  begin
    if LCursorPoint.X < LLeftX then
      Exit(TMouseWheelScrollCursors.SouthWest)
    else
    if (LCursorPoint.X >= LLeftX) and (LCursorPoint.X <= LRightX) then
      Exit(TMouseWheelScrollCursors.South)
    else
      Exit(TMouseWheelScrollCursors.SouthEast)
  end;

  if LCursorPoint.X < LLeftX then
    Exit(TMouseWheelScrollCursors.West);

  if LCursorPoint.X > LRightX then
    Exit(TMouseWheelScrollCursors.East);
end;

function TCustomTextEditor.GetScrollPageWidth: Integer;
begin
  Result := Max(ClientRect.Right - FLeftMargin.GetWidth - FCodeFolding.GetWidth - 2 - FMinimap.GetWidth - FSearch.Map.GetWidth, 0);
end;

function TCustomTextEditor.GetSelectionAvailable: Boolean;
begin
  Result := FSelection.Visible and ((FPosition.SelectionBegin.Char <> FPosition.SelectionEnd.Char) or
    ((FPosition.SelectionBegin.Line <> FPosition.SelectionEnd.Line) and (FSelection.ActiveMode <> smColumn)));
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

  function CopyPaddedAndForward(const AValue: string; const AIndex: Integer; const ACount: Integer; var APResult: PChar): Integer;
  var
    LPResult: PChar;
    LIndex, LLength: Integer;
  begin
    Result := 0;

    LPResult := APResult;
    CopyAndForward(AValue, AIndex, ACount, APResult);
    LLength := ACount - (APResult - LPResult);

    if not (eoTrimTrailingSpaces in Options) and (APResult - LPResult > 0) then
    begin
      for LIndex := 0 to LLength - 1 do
        APResult[LIndex] := TCharacters.Space;

      Inc(APResult, LLength);
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

function TCustomTextEditor.GetSelectionBeginPosition: TTextEditorTextPosition;
var
  LLineLength: Integer;
begin
  if (FPosition.SelectionEnd.Line < FPosition.SelectionBegin.Line) or
    ((FPosition.SelectionEnd.Line = FPosition.SelectionBegin.Line) and
     (FPosition.SelectionEnd.Char < FPosition.SelectionBegin.Char)) then
    Result := FPosition.SelectionEnd
  else
    Result := FPosition.SelectionBegin;

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
  if (FPosition.SelectionEnd.Line < FPosition.SelectionBegin.Line) or
    ((FPosition.SelectionEnd.Line = FPosition.SelectionBegin.Line) and
     (FPosition.SelectionEnd.Char < FPosition.SelectionBegin.Char)) then
    Result := FPosition.SelectionBegin
  else
    Result := FPosition.SelectionEnd;

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
  FPosition.SelectionBegin := ATextBeginPosition;
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
  LIsFixedSizeFont: Boolean;

  function GetTokenWidth(const AToken: string; const ATokenLength: Integer = -1): Integer;
  var
    LLength: Integer;
    LFormat: Cardinal;
  begin
    if ATokenLength = -1 then
      LLength := ALength
    else
      LLength := ATokenLength;

    LFormat := DT_LEFT or DT_CALCRECT or DT_NOCLIP or DT_NOPREFIX or DT_SINGLELINE;

    if ARTLReading then
      LFormat := LFormat or DT_RTLREADING;

    DrawText(FPaintHelper.StockBitmap.Canvas.Handle, AToken, LLength, LRect, LFormat);

    Result := LRect.Width;
  end;

  function GetControlCharacterWidth: Integer;
  var
    LLength: Integer;
  begin
    LToken := ControlCharacterToName(LChar);
    LLength := Length(LToken);

    if LIsFixedSizeFont or AMinimap then
      Result := FPaintHelper.FontStock.CharWidth * LLength
    else
      Result := GetTokenWidth(LToken, LLength);

    Result := (Result + 3) * ALength;
  end;

begin
  Result := 0;

  if AToken.IsEmpty or (ALength = 0) then
    Exit;

  LChar := AToken[1];

  LIsFixedSizeFont := FPaintHelper.FixedSizeFont and (Ord(LChar) <= 255);

  if ARTLReading then
  begin
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
  if LChar <= TCharacters.Space then
  case LChar of
    TCharacters.Space:
      Result := FPaintHelper.FontStock.CharWidth * ALength;
    TControlCharacters.Substitute:
      if eoShowNullCharacters in Options then
        Result := GetControlCharacterWidth
      else
        Result := 0;
    TControlCharacters.Tab:
      begin
        if FLines.Columns then
          Result := FTabs.Width - ACharsBefore mod FTabs.Width
        else
          Result := FTabs.Width;

        Result := Result * FPaintHelper.FontStock.CharWidth + (ALength - 1) * FPaintHelper.FontStock.CharWidth * FTabs.Width;
      end;
    TCharacters.ZeroWidthSpace:
      if eoShowZeroWidthSpaces in Options then
        Result := GetControlCharacterWidth
      else
        Result := 0;
  else
    if (eoShowControlCharacters in Options) and (LChar in TControlCharacters.AsSet) then
      Result := GetControlCharacterWidth
    else
      Result := 0;
  end
  else
  if LIsFixedSizeFont or AMinimap then
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
      if LNextTokenText.IsEmpty then
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
        LNextTokenText := Copy(LTokenText, Length(LFirstPartOfToken) + 1, Length(LTokenText));

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

      Inc(LWidth, LTokenWidth);
      FHighlighter.Next;
    end;

    if (LLength > 0) or LLine.IsEmpty then
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
  ABitmap.Height := AClipRect.Height;

  LRow := 0;

  while LRow < ABitmap.Height do
  begin
    LPixel := ABitmap.Scanline[LRow];

    LColumn := 0;

    while LColumn < ABitmap.Width do
    begin
      LAlpha := AShadowAlphaArray[LColumn];

      LPixel.Alpha := AShadowAlphaByteArray[LColumn];
      LPixel.Red := Round(LPixel.Red * LAlpha);
      LPixel.Green := Round(LPixel.Green * LAlpha);
      LPixel.Blue := Round(LPixel.Blue * LAlpha);

      Inc(LPixel);
      Inc(LColumn);
    end;

    Inc(LRow);
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

  if ALineText.IsEmpty then
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
  const ASelect: Boolean = False; const AAllowedBreakChars: TSysCharSet = []): string;
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
        FPosition.SelectionBegin := GetPosition(LTextPosition.Char, LTextPosition.Line);
        FPosition.SelectionEnd := GetPosition(LChar, LTextPosition.Line);
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
  LIndex1, LIndex2: Integer;
  LFoldRegion: TTextEditorCodeFoldingRegion;
  LFoldRegionItem: TTextEditorCodeFoldingRegionItem;
  LCaretPosition: TTextEditorTextPosition;
  LLineText: string;
  LPLine: PChar;
  LLength: Integer;

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

  if not FCodeFolding.Visible or FCodeFolding.TextFolding.Active or (Length(FHighlighter.CodeFoldingRegions) = 0) then
    Exit;

  if FHighlighter.Loaded then
  begin
    LCaretPosition := FPosition.Text;
    LLineText := FLines[LCaretPosition.Line];

    if TextEditor.Utils.Trim(LLineText).IsEmpty then
      Exit;

    LPLine := PChar(LLineText);
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
var
  LIndex1, LIndex2: Integer;
  LLineText: string;
  LFoldRegion: TTextEditorCodeFoldingRegion;
  LFoldRegionItem: TTextEditorCodeFoldingRegionItem;
  LPKeyWord, LPBookmarkText, LPText, LPLine: PChar;
  LCaretPosition: TTextEditorTextPosition;
  LLength: Integer;

  function IsWholeWord(const AFirstChar: PChar; const ALastChar: PChar): Boolean; inline;
  begin
    Result := not (AFirstChar^ in TCharacterSets.ValidKeyword) and not (ALastChar^ in TCharacterSets.ValidKeyword);
  end;

begin
  Result := False;

  if not FCodeFolding.Visible or FCodeFolding.TextFolding.Active or (Length(FHighlighter.CodeFoldingRegions) = 0) then
    Exit;

  LCaretPosition := ATextPosition;
  LLineText := FLines[LCaretPosition.Line];

  if TextEditor.Utils.Trim(LLineText).IsEmpty then
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
      if PTextEditorMultiCaretRecord(FMultiEdit.Carets[LIndex])^.ViewPosition.Row = ALine then
        Exit(True);

      Inc(LIndex);
    end;
  end;
end;

function TCustomTextEditor.IsWordSelected: Boolean;
var
  LIndex: Integer;
  LLineText: string;
  LPText: PChar;
begin
  Result := False;

  if FPosition.SelectionBegin.Line <> FPosition.SelectionEnd.Line then
    Exit;

  LLineText := FLines[FPosition.SelectionBegin.Line];

  if LLineText.IsEmpty then
    Exit;

  LPText := PChar(LLineText);
  LIndex := FPosition.SelectionBegin.Char;
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

function TCustomTextEditor.OpenClipboard: Boolean;
var
  LRetryCount: Integer;
  LDelayStepMs: Integer;
begin
  Result := False;

  LDelayStepMs := TClipboardDefaults.DelayStepMs;

  for LRetryCount := 1 to TClipboardDefaults.MaxRetries do
  try
    Clipboard.Open;
    Exit(True);
  except
    on Exception do
    if LRetryCount = TClipboardDefaults.MaxRetries then
      raise ETextEditorOpenClipboardException.Create(STextEditorCannotOpenClipboard + sDoubleLineBreak + SysErrorMessage(GetLastError))
    else
    begin
      Sleep(LDelayStepMs);
      Inc(LDelayStepMs, TClipboardDefaults.DelayStepMs);
    end;
  end;
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

    Result := LLine.IsEmpty or IsWordBreakChar(LLine[ATextPosition.Char]);
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
    Result := GetPosition(1, 0);
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

  if ALineText.IsEmpty then
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
    if LNextTokenText.IsEmpty then
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
    Inc(Result.Column, (X + FScrollHelper.HorizontalPosition - FLeftMarginWidth - LTextWidth) div FPaintHelper.CharWidth);
end;

function TCustomTextEditor.PixelsToTextPosition(const X, Y: Integer): TTextEditorTextPosition;
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
  LProgressPositionInc: Integer;
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

  if FLines.ShowProgress then
  begin
    FLines.ProgressPosition := 0;
    FLines.ProgressType := ptProcessing;

    LProgressInc := Max(FLines.Count div 100, 1);
    LProgressPositionInc := Max(Round(100 / FLines.Count), 1);
  end;

  if FLines.Count > 0 then
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
        FLines.ProgressPosition := FLines.ProgressPosition + LProgressPositionInc;

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

procedure TCustomTextEditor.RescanHighlighterRanges;
var
  LLastScan: Integer;
begin
  LLastScan := 0;

  repeat
    LLastScan := ScanHighlighterRangesFrom(LLastScan);
    Inc(LLastScan);
  until LLastScan >= FLines.Count;
end;

function TCustomTextEditor.TextPositionToCharIndex(const ATextPosition: TTextEditorTextPosition): Integer;
var
  LIndex: Integer;
  LLineCount: Integer;
  LItem: TTextEditorStringRecord;
begin
  Result := 0;

  LLineCount := Min(FLines.Count, ATextPosition.Line);
  LIndex := 0;

  while LIndex < LLineCount do
  begin
    LItem := FLines.Items^[LIndex];

    Inc(Result, Length(LItem.TextLine));

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
      Invalidate;
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
      FSearchEngine := TTextEditorNormalSearch.Create(AEngine = seExtended, FLines.DefaultLineBreak);
    seRegularExpression:
      FSearchEngine := TTextEditorRegexSearch.Create;
    seWildCard:
      FSearchEngine := TTextEditorWildCardSearch.Create;
  end;

  FSearchEngine.Engine := AEngine;
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

procedure TCustomTextEditor.UpdateColors;
begin
  Color := FColors.EditorBackground;

  FFonts.CodeFoldingHint.Color := FColors.CodeFoldingHintText;
  FFonts.CompletionProposal.Color := FColors.CompletionProposalForeground;
  FFonts.LineNumbers.Color := FColors.LeftMarginLineNumbers;
  FFonts.Ruler.Color := FColors.RulerNumbers;
  FFonts.Text.Color := FColors.EditorForeground;
end;

procedure TCustomTextEditor.ColorsChanged(ASender: TObject); //FI:O804: Method parameter 'ASender' is declared but never used
begin
  UpdateColors;

  Invalidate;
end;

procedure TCustomTextEditor.CodeFoldingResetCaches;
var
  LIndex, LLength: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
  LShowTreeLine: Boolean;
begin
  if not FCodeFolding.Visible then
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

    if Assigned(LCodeFoldingRange) then
    begin
      if not LCodeFoldingRange.ParentCollapsed and
        ((LCodeFoldingRange.FromLine <> LCodeFoldingRange.ToLine) or
        Assigned(LCodeFoldingRange.RegionItem) and LCodeFoldingRange.RegionItem.TokenEndIsPreviousLine and
        (LCodeFoldingRange.FromLine = LCodeFoldingRange.ToLine)) then
      begin
        if (LCodeFoldingRange.FromLine > 0) and (LCodeFoldingRange.FromLine <= LLength) then
        begin
          FCodeFoldings.RangeFromLine[LCodeFoldingRange.FromLine] := LCodeFoldingRange;
          FCodeFoldings.Exists := True;

          if LCodeFoldingRange.Collapsable then
            FCodeFoldings.RangeToLine[LCodeFoldingRange.ToLine] := LCodeFoldingRange;
        end;
      end;
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
      TMouseWheelScrollCursors.NorthWest, TMouseWheelScrollCursors.West, TMouseWheelScrollCursors.SouthWest:
        FScrollHelper.Delta.X := (APoint.X - FMouse.ScrollingPoint.X) div FPaintHelper.CharWidth - 1;
      TMouseWheelScrollCursors.NorthEast, TMouseWheelScrollCursors.East, TMouseWheelScrollCursors.SouthEast:
        FScrollHelper.Delta.X := (APoint.X - FMouse.ScrollingPoint.X) div FPaintHelper.CharWidth + 1;
    else
      FScrollHelper.Delta.X := 0;
    end;

    case LCursorIndex of
      TMouseWheelScrollCursors.NorthWest, TMouseWheelScrollCursors.North, TMouseWheelScrollCursors.NorthEast:
        FScrollHelper.Delta.Y := (APoint.Y - FMouse.ScrollingPoint.Y) div GetLineHeight - 1;
      TMouseWheelScrollCursors.SouthWest, TMouseWheelScrollCursors.South, TMouseWheelScrollCursors.SouthEast:
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

    LScrollBounds := Bounds(LScrollBoundsLeft, 0, LScrollBoundsRight, FLineNumbers.VisibleCount * GetLineHeight);

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

procedure TCustomTextEditor.AddUndoDelete(const ACaretPosition: TTextEditorTextPosition;
  const ASelectionBeginPosition, ASelectionEndPosition: TTextEditorTextPosition;
  const AChangeText: string; SelectionMode: TTextEditorSelectionMode; AChangeBlockNumber: Integer = 0);
begin
  DecCharacterCount(AChangeText);

  FUndoList.AddChange(crDelete, ACaretPosition, ASelectionBeginPosition, ASelectionEndPosition, AChangeText,
    SelectionMode, AChangeBlockNumber);
end;

procedure TCustomTextEditor.AddUndoInsert(const ACaretPosition: TTextEditorTextPosition;
  const ASelectionBeginPosition, ASelectionEndPosition: TTextEditorTextPosition;
  const AChangeText: string; SelectionMode: TTextEditorSelectionMode; AChangeBlockNumber: Integer = 0);
begin
  IncCharacterCount(AChangeText);

  FUndoList.AddChange(crInsert, ACaretPosition, ASelectionBeginPosition, ASelectionEndPosition, AChangeText,
    SelectionMode, AChangeBlockNumber);
end;

procedure TCustomTextEditor.AddUndoPaste(const ACaretPosition: TTextEditorTextPosition;
  const ASelectionBeginPosition, ASelectionEndPosition: TTextEditorTextPosition;
  const AChangeText: string; SelectionMode: TTextEditorSelectionMode; AChangeBlockNumber: Integer = 0);
begin
  IncCharacterCount(AChangeText);

  FUndoList.AddChange(crPaste, ACaretPosition, ASelectionBeginPosition, ASelectionEndPosition, AChangeText,
    SelectionMode, AChangeBlockNumber);
end;

procedure TCustomTextEditor.DeleteChar;
var
  LLineText, LOriginalLineText: string;
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
    LOriginalLineText := LLineText;
    LLength := Length(LLineText);

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

      FUndoList.EndBlock;

      FLineNumbers.ResetCache := True;
    end;

    if FSearch.Enabled and not FSearch.SearchText.IsEmpty and
      ((Pos(FSearch.SearchText, LOriginalLineText) > 0) or (Pos(FSearch.SearchText, LLineText) > 0)) then
      SearchAll;
  end;
end;

procedure TCustomTextEditor.DeleteLine;
var
  LTextPosition, LTextBeginPosition, LTextEndPosition: TTextEditorTextPosition;
  LTextLine: string;
begin
  BeginUpdate;

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

    FLines.Delete(LTextPosition.Line);

    LTextPosition.Line := Min(Max(LTextPosition.Line, 0), FLines.Count - 1);
    LTextPosition.Char := FLines[LTextPosition.Line].Length + 1;

    TextPosition := LTextPosition;

    AddUndoDelete(LTextPosition, LTextBeginPosition, LTextEndPosition, LTextLine, smNormal);

    SetSelectionBeginPosition(LTextPosition);
  finally
    FUndoList.EndBlock;
  end;

  if Assigned(FEvents.OnAfterDeleteLine) then
    FEvents.OnAfterDeleteLine(Self);

  EndUpdate;
end;

procedure TCustomTextEditor.DeleteText(const ACommand: TTextEditorCommand);
var
  LLineText: string;
  LTextPosition, LSelectionBeginPosition, LSelectionEndPosition: TTextEditorTextPosition;
  LBeginCaretPosition: TTextEditorTextPosition;
  LEndCaretPosition: TTextEditorTextPosition;
  LHelper: string;
  LIndex: Integer;

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
      LLine := FLines[Result.Line];

      if Result.Char > Length(LLine) then
        Exit;

      LPChar := @LLine[Result.Char];

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
        while (LIndex <= Length(LLineText)) and LLineText[LIndex].IsWhiteSpace do
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
      AddUndoDelete(LBeginCaretPosition, LBeginCaretPosition, LEndCaretPosition, LHelper, smNormal);
    finally
      FUndoList.EndBlock;
      SelectionEndPosition := SelectionBeginPosition;
    end;
  end;
end;

procedure TCustomTextEditor.DoBackspace;
var
  LLineText, LOriginalLineText: string;
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
  BeginUpdate;

  LTextPosition := TextPosition;

  FUndoList.BeginBlock;
  FUndoList.AddChange(crCaret, LTextPosition, SelectionBeginPosition, SelectionEndPosition, '', smNormal);

  if GetSelectionAvailable or FMultiEdit.SelectionAvailable then
  begin
    if FSyncEdit.Visible then
    begin
      if LTextPosition.Char < FSyncEdit.EditBeginPosition.Char then
        Exit;

      FSyncEdit.MoveEndPositionChar(-FPosition.SelectionEnd.Char + FPosition.SelectionBegin.Char);
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
        LCaretNewPosition.Char := Length(FLines[LTextPosition.Line - 1]) + 1;

        AddUndoDelete(LTextPosition, LCaretNewPosition, LTextPosition, FLines.GetLineBreak(LTextPosition.Line), smNormal);

        if eoTrimTrailingSpaces in Options then
          LLineText := TextEditor.Utils.TrimRight(LLineText);

        FLines[LCaretNewPosition.Line] := FLines.Items^[LCaretNewPosition.Line].TextLine + LLineText;
        FLines.Delete(LTextPosition.Line);

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

          AddUndoDelete(LTextPosition, GetPosition(LCharPosition + 1, LTextPosition.Line), LTextPosition, LHelper, smNormal);

          LSpaceBuffer := '';

          if LVisualSpaceCount2 - LLength > 0 then
            LSpaceBuffer := StringOfChar(TCharacters.Space, LVisualSpaceCount2 - LLength);

          Insert(LSpaceBuffer, LLineText, LCharPosition + 1);

          FLines[LTextPosition.Line] := LLineText;

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

          AddUndoDelete(LTextPosition, GetPosition(LCharPosition + 1, LTextPosition.Line), LTextPosition, LHelper, smNormal);

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

        LHelper := Copy(LLineText, LTextPosition.Char - LCharPosition, LCharPosition);

        AddUndoDelete(LTextPosition, GetPosition(LTextPosition.Char - LCharPosition, LTextPosition.Line), LTextPosition,
          LHelper, smNormal);

        Delete(LLineText, LTextPosition.Char - LCharPosition, LCharPosition);
        FLines[LTextPosition.Line] := LLineText;

        if FWordWrap.Active then
        begin
          LWidth := GetTokenWidth(LHelper, 1, 0);

          FWordWrapLine.Length[FViewPosition.Row] := FWordWrapLine.Length[FViewPosition.Row] - 1;
          FWordWrapLine.ViewLength[FViewPosition.Row] := FWordWrapLine.ViewLength[FViewPosition.Row] -
            GetTokenCharCount(LChar, FViewPosition.Row);
          FWordWrapLine.Width[FViewPosition.Row] := FWordWrapLine.Width[FViewPosition.Row] - LWidth;

          LCharAtCursor := GetCharAtTextPosition(GetPosition(LTextPosition.Char, LTextPosition.Line));

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

    if FSearch.Enabled and not FSearch.SearchText.IsEmpty and
      ((Pos(FSearch.SearchText, LOriginalLineText) > 0) or (Pos(FSearch.SearchText, LLineText) > 0)) then
      SearchAll;
  end;

  if FSyncEdit.Visible then
    DoSyncEdit;

  FUndoList.EndBlock;

  EndUpdate;
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
    BeginUpdate;

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
    LSpaceCount := LeftSpaceCount(LLineText);
    LSpaces := Copy(LLineText, 1, LSpaceCount);
    LLineText := TextEditor.Utils.TrimLeft(LLineText);

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

    FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);

    LDeleteComment := False;

    if LCommentIndex <> -2 then
    begin
      LDeleteComment := True;
      LComment := FHighlighter.Comments.BlockComments[LCommentIndex];

      AddUndoDelete(LTextPosition, GetPosition(LSpaceCount + 1, LBeginLine),
        GetPosition(LSpaceCount + Length(LComment) + 1, LBeginLine), LComment, FSelection.ActiveMode);

      LLineText := Copy(LLineText, Length(LComment) + 1, Length(LLineText));
    end;

    Inc(LCommentIndex, 2);
    LComment := '';

    if LCommentIndex < LLength - 1 then
      LComment := FHighlighter.Comments.BlockComments[LCommentIndex];

    LLineText := LSpaces + LComment + LLineText;

    FLines.Strings[LBeginLine] := LLineText;

    AddUndoInsert(LTextPosition, GetPosition(1 + LSpaceCount, LBeginLine),
      GetPosition(1 + LSpaceCount + Length(LComment), LBeginLine), '', FSelection.ActiveMode);

    Inc(LCommentIndex);
    LLineText := FLines.Items^[LEndLine].TextLine;
    LSpaceCount := LeftSpaceCount(LLineText);
    LSpaces := Copy(LLineText, 1, LSpaceCount);
    LLineText := TextEditor.Utils.TrimLeft(LLineText);

    if LDeleteComment and not LLineText.IsEmpty then
    begin
      LComment := FHighlighter.Comments.BlockComments[LCommentIndex - 2];
      LPosition := Length(LLineText) - Length(LComment) + 1;

      if (LPosition > 0) and (Pos(LComment, LLineText) = LPosition) then
      begin
        AddUndoDelete(LTextPosition,
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

    AddUndoInsert(LTextPosition, GetPosition(Length(LLineText) - Length(LComment) + 1, LEndLine),
      GetPosition(Length(LLineText) + Length(LComment) + 1, LEndLine), '', FSelection.ActiveMode);

    FUndoList.EndBlock;

    TextPosition := LTextPosition;
    FPosition.SelectionBegin := LSelectionBeginPosition;
    FPosition.SelectionEnd := LSelectionEndPosition;

    EndUpdate;
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

  if AChar > TCharacters.Space then
    Inc(FCharacterCount.Value);

  LCharAtCursor := GetCharAtTextPosition(LTextPosition);

  FUndoList.BeginBlock(3);

  if GetSelectionAvailable or FMultiEdit.SelectionAvailable then
  begin
    if FSyncEdit.Visible then
      FSyncEdit.MoveEndPositionChar(-FPosition.SelectionEnd.Char + FPosition.SelectionBegin.Char + 1);

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
          (WordAtTextPosition(GetPosition(LTextPosition.Char - 1, LTextPosition.Line)) + AChar = LMathingPairToken.OpenToken) then
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
        AddUndoInsert(GetPosition(LLength + 1, LTextPosition.Line), GetPosition(LLength + 1, LTextPosition.Line),
          GetPosition(LLength + LSpaceCount1 + 2  + Length(LCloseToken), LTextPosition.Line), '', smNormal);
        FLines.LineState[LTextPosition.Line] := lsModified;
      end
      else
      begin
        LTextPosition.Char := LTextPosition.Char + 1;
        AddUndoInsert(LBlockStartPosition, LBlockStartPosition,
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

  if FSearch.Enabled and not FSearch.SearchText.IsEmpty and (Pos(FSearch.SearchText, LLineText) > 0) then
    SearchAll;

  if FSyncEdit.Visible then
    DoSyncEdit;
end;

procedure TCustomTextEditor.DoCutToClipboard;
var
  LText: string;
begin
  if not ReadOnly and (GetSelectionAvailable or FMultiEdit.SelectionAvailable) then
  begin
    AutoCursor;

    FUndoList.BeginBlock;

    if FMultiEdit.SelectionAvailable then
      LText := GetMultiCaretSelectedText
    else
      LText := SelectedText;

    DoCopyToClipboard(LText);
    SetSelectedTextEmpty;

    FUndoList.EndBlock;
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
  LStringList: TStringList;

  procedure AnsiKeywordsCase(const AValue: string; const ACommand: TTextEditorCommand);
  var
    LIndex: Integer;
    LOldPattern, LNewPattern: string;
    LItemIndex: Integer;
    LSearchItem: PTextEditorSearchItem;
  begin
    FReplace.Options := [roReplaceAll, roWholeWordsOnly];
    FReplace.Engine := seNormal;

    IncPaintLock;
    FUndoList.BeginBlock(7);

    LStringList := TStringList.Create;
    try
      FHighlighter.GetKeywords(LStringList);

      for LIndex := LStringList.Count - 1 downto 0 do
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

        BeginUpdate;

        for LItemIndex := FSearch.Items.Count - 1 downto 0 do
        begin
          LSearchItem := PTextEditorSearchItem(FSearch.Items.Items[LItemIndex]);

          SelectionBeginPosition := LSearchItem.BeginTextPosition;
          SelectionEndPosition := LSearchItem.EndTextPosition;

          ReplaceSelectedText(LNewPattern, LOldPattern);
        end;

        EndUpdate;
      end;
    finally
      LStringList.Free;

      FSearch.ClearItems;
      FUndoList.EndBlock;
      DecPaintLock;
    end;
  end;

begin
  Assert((ACommand >= TKeyCommands.UpperCase) and (ACommand <= TKeyCommands.KeywordsTitleCase));

  LOldBlockBeginPosition := SelectionBeginPosition;
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
      eASCIIDecimal:
        LText := TNetEncoding.ASCIIDecimal.Decode(SelectedText);
      eBase32:
        LText := TNetEncoding.Base32.Decode(SelectedText);
      eBase64:
        LText := TNetEncoding.Base64NoLineBreaks.Decode(SelectedText);
      eBase64WithLineBreaks:
        LBytes := TNetEncoding.Base64.Decode(FLines.Encoding.GetBytes(SelectedText));
      eBase85:
        LText := TNetEncoding.Base85.Decode(SelectedText);
      eBase91:
        LText := TNetEncoding.Base91.Decode(SelectedText);
      eBase128:
        LText := TNetEncoding.Base128.Decode(SelectedText);
      eBase256:
        LText := TNetEncoding.Base256.Decode(SelectedText);
      eBase1024:
        LText := TNetEncoding.Base1024.Decode(SelectedText);
      eBase4096:
        LText := TNetEncoding.Base4096.Decode(SelectedText);
      eBinary:
        LText := TNetEncoding.Binary.Decode(SelectedText);
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
      eHTML:
        LBytes := TNetEncoding.HTML.Decode(FLines.Encoding.GetBytes(SelectedText));
      eOctal:
        LText := TNetEncoding.Octal.Decode(SelectedText);
      eRotate5:
        LText := TNetEncoding.Rotate5.Decode(SelectedText);
      eRotate13:
        LText := TNetEncoding.Rotate13.Decode(SelectedText);
      eRotate18:
        LText := TNetEncoding.Rotate18.Decode(SelectedText);
      eRotate47:
        LText := TNetEncoding.Rotate47.Decode(SelectedText);
      eURL:
        LBytes := TNetEncoding.URL.Decode(FLines.Encoding.GetBytes(SelectedText));
    end;

    case ACoding of
      eBase64WithLineBreaks, eHTML, eURL:
        LText := FLines.Encoding.GetString(LBytes);
    end;

    if not LText.IsEmpty then
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
      eASCIIDecimal:
        LText := TNetEncoding.ASCIIDecimal.Encode(SelectedText);
      eBase32:
        LText := TNetEncoding.Base32.Encode(SelectedText);
      eBase64:
        LText := TNetEncoding.Base64NoLineBreaks.Encode(SelectedText);
      eBase64WithLineBreaks:
        LBytes := TNetEncoding.Base64.Encode(FLines.Encoding.GetBytes(SelectedText));
      eBase85:
        LText := TNetEncoding.Base85.Encode(SelectedText);
      eBase91:
        LText := TNetEncoding.Base91.Encode(SelectedText);
      eBase128:
        LText := TNetEncoding.Base128.Encode(SelectedText);
      eBase256:
        LText := TNetEncoding.Base256.Encode(SelectedText);
      eBase1024:
        LText := TNetEncoding.Base1024.Encode(SelectedText);
      eBase4096:
        LText := TNetEncoding.Base4096.Encode(SelectedText);
      eBinary:
        LText := TNetEncoding.Binary.Encode(SelectedText);
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
      eHTML:
        LBytes := TNetEncoding.HTML.Encode(FLines.Encoding.GetBytes(SelectedText));
      eOctal:
        LText := TNetEncoding.Octal.Encode(SelectedText);
      eRotate5:
        LText := TNetEncoding.Rotate5.Encode(SelectedText);
      eRotate13:
        LText := TNetEncoding.Rotate13.Encode(SelectedText);
      eRotate18:
        LText := TNetEncoding.Rotate18.Encode(SelectedText);
      eRotate47:
        LText := TNetEncoding.Rotate47.Encode(SelectedText);
      eURL:
        LBytes := TNetEncoding.URL.Encode(FLines.Encoding.GetBytes(SelectedText));
    end;

    case ACoding of
      eBase64WithLineBreaks, eHTML, eURL:
        LText := FLines.Encoding.GetString(LBytes);
    end;

    if not LText.IsEmpty then
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
  begin
    LMark := TTextEditorMark(FBookmarkList.Items[FBookmarkList.Count - 1]);
    GoToBookmark(LMark.Index);
  end;
end;

procedure TCustomTextEditor.DoHomeKey(const ASelection: Boolean);
var
  LLineText: string;
  LBeforeTextPosition, LAfterTextPosition: TTextEditorTextPosition;
  LViewPosition: TTextEditorViewPosition;
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
  LValue: string;
  LLength: Integer;
begin
  LLength := StrLen(PChar(AData));
  SetString(LValue, PChar(AData), LLength);

  InsertText(LValue);
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

    FPaintHelper.SetBaseFont(FFonts.LineNumbers);

    LWidth := FLeftMargin.RealLeftMarginWidth(FPaintHelper.CharWidth);
    FLeftMarginCharWidth := FPaintHelper.CharWidth;

    FPaintHelper.SetBaseFont(FFonts.Text);

    if FLeftMargin.Width <> LWidth then
    begin
      FLeftMargin.OnChange := nil;
      FLeftMargin.Width := LWidth;
      FLeftMargin.OnChange := LeftMarginChanged;

      FScrollHelper.PageWidth := GetScrollPageWidth;

      if HandleAllocated and FWordWrap.Active then
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
          LSpaceBuffer := '';

          if AAddSpaceBuffer then
            LSpaceBuffer := GetSpaceBuffer(LSpaceCount1);

          FLines[LTextPosition.Line] := Copy(LLineText, 1, LTextPosition.Char - 1);

          LLineText := Copy(LLineText, LTextPosition.Char, MaxInt);

          AddUndoDelete(LTextPosition, LTextPosition, GetPosition(LTextPosition.Char + Length(LLineText),
            LTextPosition.Line), LLineText, smNormal);

          if (eoAutoIndent in FOptions) and (LSpaceCount1 > 0) then
            LLineText := LSpaceBuffer + LLineText;

          FLines.Insert(LTextPosition.Line + 1, LLineText);

          FUndoList.AddChange(crLineBreak, GetPosition(1, LTextPosition.Line + 1), LTextPosition,
            GetPosition(1, LTextPosition.Line + 1), '', smNormal);

          AddUndoInsert(GetPosition(Length(LSpaceBuffer) + 1, LTextPosition.Line + 1),
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
          FLines.LineState[LTextPosition.Line] := lsModified;
        end;
      end
      else
      begin
        { A line break after the end of the line. }
        LSpaceCount1 := 0;

        if eoAutoIndent in FOptions then
          LSpaceCount1 := LeftSpaceCount(LLineText);

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

        AddUndoInsert(GetPosition(Length(LSpaceBuffer) + 1, LTextPosition.Line),
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
      FLines.LineState[LTextPosition.Line] := lsModified;

      LTextPosition.Line := Min(LTextPosition.Line + 1, FLines.Count);
      LTextPosition.Char := 1;

      FUndoList.AddChange(crLineBreak, LTextPosition, LTextPosition,
        GetPosition(1, LTextPosition.Line), '', smNormal);

      FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);
    end;

    SelectionBeginPosition := LTextPosition;
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
    BeginUpdate;

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

    FUndoList.BeginBlock;

    for LLine := LLine to LEndLine do
    begin
      LCodeFoldingRange := CodeFoldingRangeForLine(LLine + 1);

      if Assigned(LCodeFoldingRange) and LCodeFoldingRange.Collapsed then
        CodeFoldingExpand(LCodeFoldingRange);

      LIndex := 0;
      LCommentIndex := -1;
      LLineText := FLines.Items^[LLine].TextLine;
      LSpaceCount := LeftSpaceCount(LLineText);
      LSpaces := Copy(LLineText, 1, LSpaceCount);
      LLineText := TextEditor.Utils.TrimLeft(LLineText);

      if not LLineText.IsEmpty then
      while LIndex < LLength do
      begin
        if Pos(FHighlighter.Comments.LineComments[LIndex], LLineText) = 1 then
        begin
          LCommentIndex := LIndex;
          Break;
        end;

        Inc(LIndex);
      end;

      if LCommentIndex <> -1 then
      begin
        LComment := FHighlighter.Comments.LineComments[LCommentIndex];

        AddUndoDelete(LTextPosition, GetPosition(1 + LSpaceCount, LLine),
          GetPosition(Length(LComment) + 1 + LSpaceCount, LLine), LComment, smNormal);
        LLineText := Copy(LLineText, Length(FHighlighter.Comments.LineComments[LCommentIndex]) + 1, Length(LLineText));
      end;

      Inc(LCommentIndex);
      LComment := '';

      if LCommentIndex < LLength then
        LComment := FHighlighter.Comments.LineComments[LCommentIndex];

      LLineText := LComment + LSpaces + LLineText;

      FLines.Strings[LLine] := LLineText;

      AddUndoInsert(LTextPosition, GetPosition(1, LLine), GetPosition(Length(LComment) + 1, LLine), '', smNormal);

      if not GetSelectionAvailable then
      begin
        Inc(LTextPosition.Line);
        TextPosition := LTextPosition;
      end;
    end;

    FUndoList.EndBlock;

    FPosition.SelectionBegin := LSelectionBeginPosition;
    FPosition.SelectionEnd := LSelectionEndPosition;

    if GetSelectionAvailable then
      TextPosition := LTextPosition;

    EndUpdate;
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
    LLineCount := FLineNumbers.VisibleCount - 1;

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
  LSelectionBeginPosition: TTextEditorTextPosition;
  LSelectionEndPosition: TTextEditorTextPosition;
  LPasteMode: TTextEditorSelectionMode;
  LLength, LCharCount: Integer;
  LSpaces: string;
begin
  if FMultiEdit.SelectionAvailable then
  begin
    SetSelectedTextEmpty(AText);
    Exit;
  end;

  LTextPosition := TextPosition;
  LSelectionBeginPosition := SelectionBeginPosition;
  LSelectionEndPosition := SelectionEndPosition;
  LPasteMode := FSelection.Mode;

  BeginUpdate;
  FUndoList.BeginBlock;
  try
    FUndoList.AddChange(crCaret, LTextPosition, LSelectionBeginPosition, SelectionEndPosition, '', smNormal);

    LLength := Length(FLines[LTextPosition.Line]);

    if GetSelectionAvailable then
      AddUndoDelete(LTextPosition, SelectionBeginPosition, SelectionEndPosition, GetSelectedText, FSelection.ActiveMode)
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
      FPosition.SelectionBegin := LSelectionBeginPosition;
      FPosition.SelectionEnd := LSelectionEndPosition;

      if FSyncEdit.Visible then
        FSyncEdit.MoveEndPositionChar(-FPosition.SelectionEnd.Char + FPosition.SelectionBegin.Char + Length(AText));
    end
    else
    begin
      LSelectionBeginPosition := LTextPosition;

      if FSyncEdit.Visible then
        FSyncEdit.MoveEndPositionChar(Length(AText));
    end;

    DoSelectedText(LPasteMode, PChar(AText), True, TextPosition);

    FPosition.SelectionBegin := FPosition.SelectionEnd;

    IncCharacterCount(AText);

    AddUndoPaste(LTextPosition, LSelectionBeginPosition, TextPosition, '', LPasteMode);
  finally
    FUndoList.EndBlock;
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

  if (toTabsToSpaces in FTabs.Options) and ((LTextPosition.Char - 1) mod FTabs.Width <> 0) then
    Exit;

  if toTabsToSpaces in FTabs.Options then
    LTabWidth := FTabs.Width
  else
    LTabWidth := 1;

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

  FLines.BeginUpdate;

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

    AddUndoDelete(LTextPosition, LTextBeginPosition, LTextEndPosition, '', FSelection.ActiveMode);

    LTextEndPosition := LTextBeginPosition;
    Inc(LTextEndPosition.Char, Length(LEditText));

    AddUndoInsert(LTextPosition, LTextBeginPosition, LTextEndPosition, LOldText, FSelection.ActiveMode);

    LLine := FLines.Items^[LTextBeginPosition.Line].TextLine;
    FLines[LTextBeginPosition.Line] := Copy(LLine, 1, LTextBeginPosition.Char - 1) + LEditText +
      Copy(LLine, LTextBeginPosition.Char + FSyncEdit.EditWidth, Length(LLine));

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

  FLines.EndUpdate;

  FSyncEdit.EditWidth := FSyncEdit.EditEndPosition.Char - FSyncEdit.EditBeginPosition.Char;
  TextPosition := LTextPosition;
end;

function TCustomTextEditor.GetTabText(var ATextPosition: TTextEditorTextPosition): string;
var
  LViewPosition: TTextEditorViewPosition;
  LLengthAfterLine: Integer;
  LCharCount: Integer;
  LPreviousLine: Integer;
  LPreviousLineCharCount: Integer;
begin
  LViewPosition := ViewPosition;
  LLengthAfterLine := Max(LViewPosition.Column - FLines.ExpandedStringLengths[ATextPosition.Line], 1);

  if LLengthAfterLine > 1 then
    LCharCount := LLengthAfterLine
  else
    LCharCount := FTabs.Width;

  if toPreviousLineIndent in FTabs.Options then
    if TextEditor.Utils.Trim(FLines[ATextPosition.Line]).IsEmpty then
    begin
      LPreviousLine := ATextPosition.Line - 1;

      while (LPreviousLine >= 0) and FLines.Items^[LPreviousLine].TextLine.IsEmpty do
        Dec(LPreviousLine);

      LPreviousLineCharCount := LeftSpaceCount(FLines[LPreviousLine]);

      if LPreviousLineCharCount > ATextPosition.Char then
        LCharCount := LPreviousLineCharCount - LeftSpaceCount(FLines.Items^[ATextPosition.Line].TextLine);
    end;

  if LLengthAfterLine > 1 then
    ATextPosition.Char := Length(FLines[ATextPosition.Line]) + 1;

  if toTabsToSpaces in FTabs.Options then
  begin
    if FLines.Columns then
      Dec(LCharCount, (LViewPosition.Column - 1) mod FTabs.Width);

    Result := StringOfChar(TCharacters.Space, LCharCount);
  end
  else
  begin
    Result := StringOfChar(TControlCharacters.Tab, LCharCount div FTabs.Width);
    Result := Result + StringOfChar(TCharacters.Space, LCharCount mod FTabs.Width);
  end;
end;

procedure TCustomTextEditor.DoTabKey;
var
  LTextPosition, LNewTextPosition: TTextEditorTextPosition;
  LTabText, LTextLine: string;
  LChangeScrollPastEndOfLine: Boolean;
  LWidth: Integer;
  LLength: Integer;
begin
  if GetSelectionAvailable and (FPosition.SelectionBegin.Line <> FPosition.SelectionEnd.Line) and
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
      AddUndoDelete(LTextPosition, SelectionBeginPosition, SelectionEndPosition, GetSelectedText, FSelection.ActiveMode);
      DoSelectedText('');
      LTextPosition := SelectionBeginPosition;
    end;

    LTextLine := FLines[LTextPosition.Line];
    LTabText := GetTabText(LTextPosition);

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
          if toTabsToSpaces in Tabs.Options then
            LLength := Tabs.Width
          else
            LLength := 1;

          FWordWrapLine.Length[FViewPosition.Row] := FWordWrapLine.Length[FViewPosition.Row] + LLength;
          FWordWrapLine.ViewLength[FViewPosition.Row] := FWordWrapLine.ViewLength[FViewPosition.Row] +
            GetTokenCharCount(LTabText, FViewPosition.Column - 1);
          FWordWrapLine.Width[FViewPosition.Row] := FWordWrapLine.Width[FViewPosition.Row] + LWidth;
        end;
      end;

    LChangeScrollPastEndOfLine := not (soPastEndOfLine in FScroll.Options);

    if LChangeScrollPastEndOfLine then
      FScroll.SetOption(soPastEndOfLine, True);

    SetTextCaretX(LTextPosition.Char + Length(LTabText));

    if LChangeScrollPastEndOfLine then
      FScroll.SetOption(soPastEndOfLine, False);

    EnsureCursorPositionVisible;

    if GetSelectionAvailable then
    begin
      LNewTextPosition := SelectionBeginPosition;
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
  LBitmap: Vcl.Graphics.TBitmap;
  LBackgroundColor, LForegroundColor: TColor;
  LLineText: string;
begin
  LPoint := ViewPositionToPixels(AViewPosition);
  Y := 0;
  X := 0;
  LCaretHeight := 1;
  LCaretWidth := FPaintHelper.CharWidth;

  if Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) or (FMultiEdit.Position.Row <> -1) then
  begin
    LBackgroundColor := FColors.CaretMultiEditBackground;
    LForegroundColor := FColors.CaretMultiEditForeground;
    LCaretStyle := FCaret.MultiEdit.Style
  end
  else
  begin
    LBackgroundColor := FColors.CaretNonBlinkingBackground;
    LForegroundColor := FColors.CaretNonBlinkingForeground;

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
        LCaretHeight := GetLineHeight shr 1;
        Y := GetLineHeight shr 1;
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

  LBitmap := Vcl.Graphics.TBitmap.Create;
  try
    { Background }
    LBitmap.Canvas.Pen.Color := LBackgroundColor;
    LBitmap.Canvas.Brush.Color := LBackgroundColor;
    { Size }
    LBitmap.Width := FPaintHelper.CharWidth;
    LBitmap.Height := GetLineHeight;

    { Character }
    with LBitmap.Canvas do
    begin
      Brush.Style := bsClear;
      Font.Name := FFonts.Text.Name;
      Font.Color := LForegroundColor;
      Font.Style := FFonts.Text.Style;
      Font.Size := FFonts.Text.Size;
    end;

    LLineText := FLines[AViewPosition.Row - 1];

    if (AViewPosition.Column > 0) and (AViewPosition.Column <= Length(LLineText)) then
      LBitmap.Canvas.TextOut(X, 0, LLineText[AViewPosition.Column]);

    Canvas.CopyRect(Rect(LPoint.X + FCaret.Offsets.Left, LPoint.Y + FCaret.Offsets.Top,
      LPoint.X + FCaret.Offsets.Left + LCaretWidth, LPoint.Y + FCaret.Offsets.Top + LCaretHeight), LBitmap.Canvas,
      Rect(0, Y, LCaretWidth, Y + LCaretHeight));
  finally
    LBitmap.Free
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
type
  TCommentPositionsRec = record
    BeginTextPosition: TTextEditorTextPosition;
    EndTextPosition: TTextEditorTextPosition;
  end;
var
  LLine, LResultIndex, LSearchAllCount, LTextPosition, LSearchLength, LCurrentLineLength: Integer;
  LSearchText, LSearchTextUpper: string;
  LPSearchItem: PTextEditorSearchItem;
  LBeginTextPosition, LEndTextPosition: TTextEditorTextPosition;
  LSelectionBeginPosition, LSelectionEndPosition:  TTextEditorTextPosition;
  LSelectedOnly: Boolean;
  LCommentPositions: TList<TCommentPositionsRec>;

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

  procedure GetCommentPositions;
  var
    LLine: Integer;
    LCommentPosition, LBlockCommentPosition: TCommentPositionsRec;
    LInBlockComment: Boolean;
  begin
    LInBlockComment := False;

    if not FHighlighter.Loaded then
      Exit;

    for LLine := 0 to FLines.Count - 1 do
    begin
      if LLine = 0 then
        FHighlighter.ResetRange
      else
        FHighlighter.SetRange(FLines.Ranges[LLine - 1]);

      FHighlighter.SetLine(FLines.Items^[LLine].TextLine);

      while not FHighlighter.EndOfLine do
      begin
        if FHighlighter.TokenType = ttLineComment then
        begin
          LCommentPosition.BeginTextPosition.Line := LLine;
          LCommentPosition.BeginTextPosition.Char := FHighlighter.TokenPosition + 1;
          LCommentPosition.EndTextPosition.Line := LLine;
          LCommentPosition.EndTextPosition.Char := Length(FLines.Items^[LLine].TextLine);

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
      LBlockCommentPosition.EndTextPosition.Char := Length(FLines.Items^[FLines.Count - 1].TextLine);

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
      LSelectedOnly and IsTextPositionInSelection(LSelectionBeginPosition) and IsTextPositionInSelection(LSelectionEndPosition)
      or
      FSearch.InSelection.Active and
      ((FSearch.InSelection.SelectionBeginPosition.Line < LLine) and (FSearch.InSelection.SelectionEndPosition.Line > LLine) or
      IsTextPositionInSearchBlock(LBeginTextPosition) and IsTextPositionInSearchBlock(LEndTextPosition));

    if soIgnoreComments in FSearch.Options then
      Result := Result and not IsTextPositionInComment;
  end;

var
  LWords: TArray<string>;
  LPosition: Integer;
  LMaxDistance: Integer;
begin
  FSearch.ClearItems;

  if not FSearch.Enabled then
    Exit;

  if ASearchText.IsEmpty then
    LSearchText := FSearch.SearchText
  else
    LSearchText := ASearchText;

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

        if LPosition > 0 then
          LMaxDistance := StrToIntDef(Copy(LWords[1], LPosition + 1), FSearch.NearOperator.MaxDistance)
        else
          LMaxDistance := FSearch.NearOperator.MaxDistance;

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

    FPosition.SelectionBegin := FPosition.SelectionEnd;
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
  FMultiEdit.SelectionAvailable := False;

  if Assigned(FMultiEdit.Carets) then
  begin
    FMultiEdit.Timer.Enabled := False;
    FreeAndNil(FMultiEdit.Timer);

    LIndex := FMultiEdit.Carets.Count - 1;

    while LIndex >= 0 do
    begin
      Dispose(PTextEditorMultiCaretRecord(FMultiEdit.Carets.Items[LIndex]));
      Dec(LIndex);
    end;

    FMultiEdit.Carets.Clear;
    FreeAndNil(FMultiEdit.Carets);
  end;

  ResetCaret;
end;

procedure TCustomTextEditor.FontChanged(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  Invalidate;
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
  if FLines.Updating then
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
    LLineText := FLines.Items^[LTextPosition.Line].TextLine;
    LLength := Length(LLineText);
    FLines.Insert(LTextPosition.Line + 1, '');
    AddUndoInsert(LTextPosition, GetPosition(LLength + 1, LTextPosition.Line), GetPosition(1, LTextPosition.Line + 1),
      '', smNormal);

    FLines.LineState[LTextPosition.Line + 1] := lsModified;
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

procedure TCustomTextEditor.CMGestureManagerChanged(var Message: TMessage);
begin
  if not (csDestroying in ComponentState) then
  begin
    if Assigned(Touch.GestureManager) then
      ControlStyle := ControlStyle + [csGestures]
    else
      ControlStyle := ControlStyle - [csGestures];

    if HandleAllocated then
      RecreateWnd;
  end;
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

      LIndex := 0;
      while LIndex < FMinimapHelper.Shadow.Bitmap.Width do
      begin
        if FMinimap.Align = maLeft then
          FMinimapHelper.Shadow.AlphaArray[LIndex] := (FMinimapHelper.Shadow.Bitmap.Width - LIndex) /
            FMinimapHelper.Shadow.Bitmap.Width
        else
          FMinimapHelper.Shadow.AlphaArray[LIndex] := LIndex / FMinimapHelper.Shadow.Bitmap.Width;

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
        TopLine := TopLine + FScrollHelper.Delta.Y * FLineNumbers.VisibleCount
      else
        TopLine := TopLine + FScrollHelper.Delta.Y;
    end;
  finally
    DecPaintLock;
  end;

  ComputeScroll(LCursorPoint);
end;

procedure TCustomTextEditor.MoveCaretAndSelection(const ABeforeTextPosition, AAfterTextPosition: TTextEditorTextPosition;
  const ASelectionCommand: Boolean);
var
  LReason: TTextEditorChangeReason;
  LSelectionAvailable: Boolean;
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

  LSelectionAvailable := GetSelectionAvailable;

  if ASelectionCommand then
  begin
    if not LSelectionAvailable then
      SetSelectionBeginPosition(ABeforeTextPosition);

    SetSelectionEndPosition(AAfterTextPosition);
  end
  else
  begin
    SetSelectionBeginPosition(AAfterTextPosition);

    if LSelectionAvailable then
      SetSelectionEndPosition(AAfterTextPosition);
  end;

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
    FPosition.SelectionBegin := LTextPosition;
    FPosition.SelectionEnd := LTextPosition;
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

  MoveCaretAndSelection(FPosition.SelectionBegin, LDestinationPosition, ASelectionCommand);
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

  if not ASelectionCommand and (LDestinationLineChar.Line <> FPosition.SelectionBegin.Line) then
  begin
    DoTrimTrailingSpaces(FPosition.SelectionBegin.Line);
    DoTrimTrailingSpaces(LDestinationLineChar.Line);
  end;

  MoveCaretAndSelection(FPosition.SelectionBegin, LDestinationLineChar, ASelectionCommand);
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

    SetTextPositionAndSelection(LTextPosition, LSelectionBeginPosition, LSelectionEndPosition);
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

    SetTextPositionAndSelection(LTextPosition, LSelectionBeginPosition, LSelectionEndPosition);
    FUndoList.EndBlock;
  end;
end;

procedure TCustomTextEditor.MultiCaretTimerHandler(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  FMultiEdit.Draw := not FMultiEdit.Draw;

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

procedure TCustomTextEditor.ValidateMultiCarets;
var
  LIndex1, LIndex2: Integer;
  LPMultiCaretRecord1, LPMultiCaretRecord2: PTextEditorMultiCaretRecord;
begin
  if Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) then
  begin
    { Remove duplicate multi carets }
    for LIndex1 := 0 to FMultiEdit.Carets.Count - 1 do
      for LIndex2 := FMultiEdit.Carets.Count - 1 downto LIndex1 + 1 do
      begin
        LPMultiCaretRecord1 := PTextEditorMultiCaretRecord(FMultiEdit.Carets[LIndex1]);
        LPMultiCaretRecord2 := PTextEditorMultiCaretRecord(FMultiEdit.Carets[LIndex2]);

        if (LPMultiCaretRecord1^.ViewPosition.Row = LPMultiCaretRecord2^.ViewPosition.Row) and
          (LPMultiCaretRecord1^.ViewPosition.Column = LPMultiCaretRecord2^.ViewPosition.Column) then
        begin
          Dispose(LPMultiCaretRecord2);
          FMultiEdit.Carets.Delete(LIndex2);
        end;
      end;

    { Remove carets after line count }
    for LIndex1 := FMultiEdit.Carets.Count - 1 downto 0 do
    begin
      LPMultiCaretRecord1 := PTextEditorMultiCaretRecord(FMultiEdit.Carets[LIndex1]);

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

  if not (csLoading in ComponentState) then
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

  function IsNextSkipChar(const APText: PChar; const ASkipRegionItem: TTextEditorSkipRegionItem): Boolean; inline;
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

        Inc(LIndex);
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

        while (LIndex > 0) and FLines[LIndex - 1].IsEmpty do
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
              LOpenTokenFoldRangeList.RemoveItem(LCodeFoldingRange, TList.TDirection.FromEnd);
              Dec(LFoldCount);

              if not LCodeFoldingRange.IsExtraTokenFound and
                not LCodeFoldingRange.RegionItem.BreakIfNotFoundBeforeNextRegion.IsEmpty then
              begin
                LPText := LPBookmarkText;
                Exit;
              end;

              SetCodeFoldingRangeToLine(LCodeFoldingRange);

              { Check if the code folding ranges have shared close }
              if FHighlighter.IsSharedCloseFound and (LOpenTokenFoldRangeList.Count > 0) then
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
                    LOpenTokenFoldRangeList.RemoveItem(LCodeFoldingRangeLast, TList.TDirection.FromEnd);
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
        until Assigned(LCodeFoldingRange) and (LCodeFoldingRange.RegionItem.BreakIfNotFoundBeforeNextRegion.IsEmpty or
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
            if not LCodeFoldingRange.RegionItem.BreakIfNotFoundBeforeNextRegion.IsEmpty then
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

            if not LRegionItem.OpenTokenCanBeFollowedBy.IsEmpty then
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
                while (LPText^ <> TControlCharacters.Null) and not LSkipIfFoundAfterOpenToken do
                begin
                  if not LPText^.IsWhiteSpace then
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

                  Inc(LPText);
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

                  if (LPosition > 0) and (LPosition + 4 < Length(LTemp)) then
                  begin
                    LPText := LPBookmarkText; { Skip found, return pointer back }
                    Continue;
                  end;
                end;

                if Assigned(LCodeFoldingRange) and
                  not LCodeFoldingRange.RegionItem.BreakIfNotFoundBeforeNextRegion.IsEmpty and
                  not LCodeFoldingRange.IsExtraTokenFound and not LRegionItem.RemoveRange then
                begin
                  LOpenTokenFoldRangeList.RemoveItem(LCodeFoldingRange, TList.TDirection.FromEnd);
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
    LTokenName: string;
    LAdded: Boolean;
    LOpenToken, LCloseToken: string;
    LRegionItem: TTextEditorCodeFoldingRegionItem;
    LDefaultRegion: TTextEditorCodeFoldingRegion;
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

          while (LPText^ <> TControlCharacters.Null) and not (LPText^ in [TCharacters.Space, TCharacters.TagClose]) do
          begin
            if IsLineTerminatorCharacter(LPText^) then
              Break;

            LTokenName := LTokenName + CaseUpper(LPText^);

            Inc(LPText);
          end;

          if not Highlighter.InCodeFoldingVoidElements(LTokenname) then
          begin
            if LPText^ = TCharacters.Space then
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
              LOpenToken := LOpenToken.Trim;
              LCloseToken := TCharacters.CloseTagOpen + LTokenName + TCharacters.TagClose;

              if not LDefaultRegion.Contains(LOpenToken, LCloseToken) then
              begin
                LRegionItem := LDefaultRegion.Add(LOpenToken, LCloseToken);
                LRegionItem.BreakCharFollows := False;

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

  procedure ScanCodeFolds;
  var
    LIndex, LPreviousLine: Integer;
    LCodeFoldingRange: TTextEditorCodeFoldingRange;
    LProgressPosition, LProgress, LProgressInc, LLength: Int64;
    LProgressPositionInc: Integer;
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
      LProgressPositionInc := 1;

      if FLines.ShowProgress then
      begin
        FLines.ProgressPosition := 0;
        FLines.ProgressType := ptProcessing;

        LLength := Length(FLineNumbers.Cache) - 1;
        LProgressInc := Max(LLength div 100, 1);
        LProgressPositionInc := Max(Round(100 / LLength), 1);
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
            FLines.ProgressPosition := FLines.ProgressPosition + LProgressPositionInc;

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

      while (LLine >= 0) and System.SysUtils.Trim(FLines[LLine]).IsEmpty do
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

        if LLine < Length(FCodeFoldings.RangeFromLine) then
          LCodeFoldingRange := FCodeFoldings.RangeFromLine[LLine]
        else
          Break;

        if Assigned(LCodeFoldingRange) and LCodeFoldingRange.Collapsed then
        begin
          LPreviousLine := LLine;
          Continue;
        end;

        LTextLine := TextEditor.Utils.Trim(FLines[LLine - 1]);

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

          if FCodeFolding.TextFolding.OutlinedBySpacesAndTabs then
            LCharCount := LeftSpaceCount(LTextLine)
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

          if TextEditor.Utils.Trim(LTextLine).IsEmpty then
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
          if not TextEditor.Utils.Trim(LTextLine).IsEmpty and (LFoldRangeList.Count = 0) then
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

      while (LLine >= 0) and TextEditor.Utils.Trim(FLines[LLine]).IsEmpty do
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
  if not Assigned(FLineNumbers.Cache) or not FCodeFolding.Visible or (FLines.Count <= 1) or FHighlighter.Loading then
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
        TopLine := TopLine + FScrollHelper.Delta.Y * FLineNumbers.VisibleCount
      else
        TopLine := TopLine + FScrollHelper.Delta.Y;

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
          TextPosition := GetBOFPosition;

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
          FPosition.SelectionBegin := TextPosition;
          FPosition.SelectionEnd := FPosition.SelectionBegin;
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
  LLineBreak: Boolean;
  LTextPosition: TTextEditorTextPosition;
begin
  LPText := PChar(Text);
  LIndex := 0;
  LTextPosition.Char := 1;
  LTextPosition.Line := 0;

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
  if AValue > TMinValues.FileReadBufferSize then
    FFile.MaxReadBufferSize := AValue
  else
    FFile.MaxReadBufferSize := TMinValues.FileReadBufferSize;
end;

procedure TCustomTextEditor.SetFileMinShowProgressSize(const AValue: Int64);
begin
  if AValue > TMinValues.FileShowProgressSize then
    FFile.MinShowProgressSize := AValue
  else
    FFile.MinShowProgressSize := TMinValues.FileShowProgressSize;
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

procedure TCustomTextEditor.SetHorizontalScrollPosition(const AValue: Integer);
var
  LValue: Integer;
begin
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

  BeginUpdate;
  FLines.Assign(AValue);
  EndUpdate;

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
  LTextPosition, LBlockStartPosition, LBlockEndPosition: TTextEditorTextPosition;
begin
  ClearCodeFolding;
  try
    LTextPosition := TextPosition;

    LBlockStartPosition := SelectionBeginPosition;
    LBlockEndPosition := SelectionEndPosition;

    if GetSelectionAvailable then
      AddUndoDelete(LTextPosition, LBlockStartPosition, LBlockEndPosition, GetSelectedText, FSelection.ActiveMode)
    else
      FSelection.ActiveMode := FSelection.Mode;

    DoSelectedText(AValue);

    if not AValue.IsEmpty and (FSelection.ActiveMode <> smColumn) then
      AddUndoInsert(TextPosition, SelectionBeginPosition, SelectionEndPosition, '', FSelection.ActiveMode);

    if not FLines.Updating then
      SearchAll;
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

  FPosition.SelectionBegin := LValue;
  FPosition.SelectionEnd := LValue;

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

    if not IsSamePosition(LValue, FPosition.SelectionEnd) then
    begin
      FPosition.SelectionEnd := LValue;

      Invalidate;
    end;

    if Assigned(FEvents.OnSelectionChanged) then
      FEvents.OnSelectionChanged(Self);

    if FState.ExecutingSelectionCommand and (soAutoCopyToClipboard in FSelection.Options) then
    begin
      LSelectionBeginPosition := FPosition.SelectionBegin;
      LSelectionEndPosition := FPosition.SelectionEnd;
      CopyToClipboard;
      FPosition.SelectionBegin := LSelectionBeginPosition;
      FPosition.SelectionEnd := LSelectionEndPosition;
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
  FUndoList.AddChange(crCaret, TextPosition, FPosition.SelectionBegin, FPosition.SelectionBegin, '', FSelection.ActiveMode);
  FPosition.SelectionBegin := ATextBeginPosition;
  FPosition.SelectionEnd := ATextEndPosition;
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
    LValue := Min(LValue, LViewLineCount - FLineNumbers.VisibleCount + 1);

  LValue := Max(LValue, 1);

  if FLineNumbers.TopLine <> LValue then
  begin
    FLineNumbers.TopLine := LValue;

    if FMinimap.Visible and not FScroll.Dragging then
      FMinimap.TopLine := Max(FLineNumbers.TopLine - Abs(Trunc((FMinimap.VisibleLineCount - FLineNumbers.VisibleCount) *
        (FLineNumbers.TopLine / Max(LViewLineCount - FLineNumbers.VisibleCount, 1)))), 1);

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
  LTempString := FLines[LTextPosition.Line] + TControlCharacters.Null;
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
  SetTextPositionAndSelection(LBlockEndPosition, LBlockBeginPosition, LBlockEndPosition);

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
  if FHighlighter.Loading then
    Exit;

  if Visible and HandleAllocated and (FPaintHelper.CharWidth <> 0) and FState.CanChangeSize then
  begin
    FPaintHelper.SetBaseFont(FFonts.Text);
    LScrollPageWidth := GetScrollPageWidth;

    LVisibleLineCount := ClientHeight div GetLineHeight;

    if FRuler.Visible then
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

      FMinimap.CharHeight := FPaintHelper.CharHeight - 1;
      FMinimap.VisibleLineCount := ClientHeight div FMinimap.CharHeight;
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
      FCodeFolding.Width := FPaintHelper.CharHeight;

      if Odd(FCodeFolding.Width) then
        FCodeFolding.Width := FCodeFolding.Width - 1;
    end;

    if cfoAutoPadding in FCodeFolding.Options then
      FCodeFolding.Padding := 2; // TODO: Scaling?

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

      FPosition.SelectionBegin := TextPosition;
      FPosition.SelectionEnd := FPosition.SelectionBegin;
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

      if not LCodeFoldingRange.Collapsed and (LCodeFoldingRange.ToLine >= ACurrentLine) then
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

function TCustomTextEditor.PaintLocked: Boolean;
begin
  Result := FPaintLock > 0;
end;

procedure TCustomTextEditor.UpdateScrollBars;
var
  LScrollInfo: TScrollInfo;
  LVerticalMaxScroll: Integer;
  LHorizontalScrollMax: Integer;
begin
  if not HandleAllocated or PaintLocked or FLines.Streaming or FHighlighter.Loading or FScroll.Dragging then
    Exit;

  if FLines.Count > 0 then
  begin
    LScrollInfo.cbSize := SizeOf(ScrollInfo);
    LScrollInfo.fMask := SIF_DISABLENOSCROLL;

    if FWordWrap.Active then
    begin
      FScrollHelper.HorizontalPosition := 0;
      ShowScrollBar(Handle, SB_HORZ, False);
    end
    else
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

      FScrollHelper.HorizontalVisible := LHorizontalScrollMax > FScrollHelper.PageWidth;

      if FScrollHelper.HorizontalVisible then
        LScrollInfo.fMask := SIF_ALL
      else
      begin
        FScrollHelper.HorizontalPosition := 0;
        LScrollInfo.fMask := SIF_DISABLENOSCROLL;
      end;

      ShowScrollBar(Handle, SB_HORZ, (FScroll.Bars in [ssBoth, ssHorizontal]) and FScrollHelper.HorizontalVisible);
      SetScrollInfo(Handle, SB_HORZ, LScrollInfo, True);
      EnableScrollBar(Handle, SB_HORZ, ESB_ENABLE_BOTH);
    end;

    LVerticalMaxScroll := FLineNumbers.Count;

    if soPastEndOfFileMarker in FScroll.Options then
      Inc(LVerticalMaxScroll, FLineNumbers.VisibleCount - 1);

    LScrollInfo.nMin := 0;

    if LVerticalMaxScroll <= TMaxValues.ScrollRange then
    begin
      LScrollInfo.nMax := Max(0, LVerticalMaxScroll);
      LScrollInfo.nPage := FLineNumbers.VisibleCount;
      LScrollInfo.nPos := TopLine - 1;
    end
    else
    begin
      LScrollInfo.nMax := TMaxValues.ScrollRange;
      LScrollInfo.nPage := MulDiv(TMaxValues.ScrollRange, FLineNumbers.VisibleCount, LVerticalMaxScroll);
      LScrollInfo.nPos := MulDiv(TMaxValues.ScrollRange, TopLine, LVerticalMaxScroll);
    end;

    FScrollHelper.VerticalVisible := LScrollInfo.nMax > FLineNumbers.VisibleCount;

    if FScrollHelper.VerticalVisible then
      LScrollInfo.fMask := SIF_ALL
    else
    begin
      TopLine := 1;
      LScrollInfo.fMask := SIF_DISABLENOSCROLL;
    end;

    ShowScrollBar(Handle, SB_VERT, (FScroll.Bars in [ssBoth, ssVertical]) and FScrollHelper.VerticalVisible);
    SetScrollInfo(Handle, SB_VERT, LScrollInfo, True);
    EnableScrollBar(Handle, SB_VERT, ESB_ENABLE_BOTH);
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
          DragQueryFileW(THandle(AMessage.wParam), LIndex, LFilename, SizeOf(LFilename) shr 1);
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
      GetObjectW(FFonts.Text.Handle, SizeOf(TLogFontW), @LLogFontW);
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

  if FMultiEdit.Position.Row <> -1 then
  begin
    FMultiEdit.Position.Row := -1;

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
  if PaintLocked or FHighlighter.Loading then
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
      TopLine := TopLine + FLineNumbers.VisibleCount;
    SB_PAGEUP:
      TopLine := TopLine - FLineNumbers.VisibleCount;
    SB_THUMBPOSITION, SB_THUMBTRACK:
      begin
        try
          FScrollHelper.IsScrolling := True;

          LVerticalMaxScroll := FLineNumbers.Count;

          if soPastEndOfFileMarker in FScroll.Options then
            Inc(LVerticalMaxScroll, FLineNumbers.VisibleCount - 1);

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
              LScrollHint := Format(STextEditorScrollInfo, [TopLine, TopLine + Min(FLineNumbers.VisibleCount,
                FLineNumbers.Count - TopLine)]);

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

  if (ssCtrl in AShift) and not (ssAlt in AShift)  then
    LLinesToScroll := FLineNumbers.VisibleCount shr Ord(soHalfPage in FScroll.Options)
  else
  if not SystemParametersInfo(SPI_GETWHEELSCROLLLINES, 0, @LLinesToScroll, 0) then
    LLinesToScroll := 3;

  { Roll the mouse wheel to scroll: One screen at a time }
  if LLinesToScroll = -1 then
    LLinesToScroll := FLineNumbers.VisibleCount;

  Inc(FMouse.WheelAccumulator, AWheelDelta);
  LWheelClicks := FMouse.WheelAccumulator div TMouseWheel.Divisor;
  FMouse.WheelAccumulator := FMouse.WheelAccumulator mod TMouseWheel.Divisor;
  TopLine := TopLine - LWheelClicks * LLinesToScroll;

  if Assigned(OnScroll) then
    OnScroll(Self, sbVertical);

  Invalidate;

  Result := True;
end;

function TCustomTextEditor.DoOnReplaceText(const AParams: TTextEditorReplaceTextParams): TTextEditorReplaceAction;
begin
  Result := raCancel;

  if Assigned(FEvents.OnReplaceText) then
    FEvents.OnReplaceText(Self, AParams, Result);
end;

function TCustomTextEditor.DoSearchMatchNotFoundWraparoundDialog: Boolean;
begin
  Result := MessageDialog(Format(STextEditorSearchMatchNotFound, [sDoubleLineBreak]), mtConfirmation,
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

procedure TCustomTextEditor.ChangeObjectScale(const AMultiplier: Integer; const ADivider: Integer{$IF CompilerVersion >= 35}; const AIsDpiChange: Boolean{$IFEND});
begin
  if AMultiplier = ADivider then
    Exit;

{$IF CompilerVersion >= 35}
  FPixelsPerInch := AMultiplier;
{$IFEND}

  if Assigned(FEvents.OnChangeScale) and not FZoom.Return then
    FEvents.OnChangeScale(Self, AMultiplier, ADivider{$IF CompilerVersion >= 35}, AIsDpiChange{$IFEND});

  if Assigned(FFonts) then
    FFonts.ChangeScale(AMultiplier, ADivider{$IF CompilerVersion >= 35}, AIsDpiChange{$IFEND});

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

  SizeOrFontChanged;
end;

procedure TCustomTextEditor.ChangeScale(AMultiplier, ADivider: Integer{$IF CompilerVersion >= 35}; AIsDpiChange: Boolean{$IFEND});
begin
  if csDesigning in ComponentState then
    Exit;

  if {$IF CompilerVersion >= 35}AIsDpiChange or{$IFEND} (AMultiplier <> ADivider) then
    ChangeObjectScale(AMultiplier, ADivider{$IF CompilerVersion >= 35}, AIsDpiChange{$IFEND});

  inherited ChangeScale(AMultiplier, ADivider{$IF CompilerVersion >= 35}, AIsDpiChange{$IFEND});
end;

procedure TCustomTextEditor.CreateParams(var AParams: TCreateParams);
const
  BorderStyles: array[TBorderStyle] of DWORD = (0, WS_BORDER);
begin
  StrDispose(WindowText);
  WindowText := nil;

  inherited CreateParams(AParams);

  with AParams do
  begin
    Style := Style or BorderStyles[FBorderStyle];

    if NewStyleControls and Ctl3D and (FBorderStyle = bsSingle) then
    begin
      Style := Style and not WS_BORDER;
      ExStyle := ExStyle or WS_EX_CLIENTEDGE;
    end;
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
  LEndOfLine, LIndex: Integer;
  LTab: string;
  LOldSelectionMode: TTextEditorSelectionMode;
  LInsertionPosition: TTextEditorTextPosition;
begin
  LOldSelectionMode := FSelection.ActiveMode;
  LOldCaretPosition := TextPosition;

  LStringToInsert := '';
  try
    if GetSelectionAvailable then
    begin
      LBlockBeginPosition := SelectionBeginPosition;
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

    if toTabsToSpaces in FTabs.Options then
      LTab := StringOfChar(TCharacters.Space, FTabs.Width)
    else
      LTab := TControlCharacters.Tab;

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

      if FSelection.ActiveMode = smColumn then
        LInsertionPosition.Char := LBlockBeginPosition.Char
      else
        LInsertionPosition.Char := 1;

      InsertBlock(LInsertionPosition, LInsertionPosition, PChar(LStringToInsert), True);

      FUndoList.AddChange(crIndent, LOldCaretPosition, LBlockBeginPosition, LBlockEndPosition, '', smColumn);
    finally
      FUndoList.EndBlock;
    end;
  finally
    LBlockBeginPosition := GetPosition(LBlockBeginPosition.Char + Length(LTab), LBlockBeginPosition.Line);
    LBlockEndPosition := GetPosition(LBlockEndPosition.Char + Length(LTab), LBlockEndPosition.Line);
    SetTextPositionAndSelection(LBlockEndPosition, LBlockBeginPosition, LBlockEndPosition);
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

  if (eoAddHTMLCodeToClipboard in FOptions) and not FMultiEdit.SelectionAvailable and
    (SelectionBeginPosition.Line <> SelectionEndPosition.Line) then
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

  if LTextPosition.Char <= Length(LLineText) then
  begin
    while (LTextPosition.Char > 0) and IsWordBreakChar(LLineText[LTextPosition.Char]) do
      Dec(LTextPosition.Char);

    Result := WordAtTextPosition(LTextPosition);
  end;
end;

procedure TCustomTextEditor.DoGetGestureOptions(var Gestures: TInteractiveGestures;
  var Options: TInteractiveGestureOptions);
begin
  inherited DoGetGestureOptions(Gestures, Options);

  if (igPan in Gestures) and ((FScroll.Bars = ssNone) or (FScroll.Bars = ssHorizontal)) then
    Gestures := Gestures - [igPan];
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

procedure TCustomTextEditor.DoKeyPressW(var AMessage: TWMKey);
var
  LForm: TCustomForm;
  LKey: Char;
begin
  LKey := Char(AMessage.CharCode);

  if FCompletionProposal.Active and FCompletionProposal.Trigger.Active then
  begin
    if Pos(LKey, FCompletionProposal.Trigger.Chars) > 0 then
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

  if CodeFolding.GuideLines.Visible then
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
      ColorDepth := cd32Bit;
      Height := FImagesBookmark.Height;
      Width := FImagesBookmark.Width;
    end;

    for LIndex := 9 to 13 do
    begin
      LBitmap := FImagesBookmark.GetBitmap(LIndex, TColors.Fuchsia);
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
    SelectionEndPosition := FPosition.SelectionBegin;
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
          SelectionEndPosition := FPosition.SelectionBegin;
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
  GoToLineAndSetPosition(Round(Y / LHeight));
end;

procedure TCustomTextEditor.DoOnPaint;
begin
  if Assigned(FEvents.OnPaint) then
  begin
    Canvas.Font.Assign(FFonts.Text);
    Canvas.Brush.Color := FColors.EditorBackground;

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
    FCompletionProposalPopupWindow := nil; { Prevent WMKillFocus to free it again }
    LCompletionProposalPopupWindow.Hide;
    LCompletionProposalPopupWindow.Free;

    FCompletionProposal.Visible := False;
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

  if (FMaxLength > 0) and (AKey <> TControlCharacterKeys.Backspace) and not (AKey in TCharacters.Arrows) and
    (FLines.GetTextLength > FMaxLength) then
  begin
    Include(FState.Flags, sfIgnoreNextChar);
    AKey := 0;
    Exit;
  end;

  if (soALTSetsColumnMode in FSelection.Options) and (ssAlt in AShift) and not (ssCtrl in AShift) and not FState.AltDown then
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

  if FCaret.MultiEdit.Active and Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) and
    (AKey in [TControlCharacterKeys.CarriageReturn, TControlCharacterKeys.Escape]) then
  begin
    FreeMultiCarets;

    Invalidate;
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
  if (ssCtrl in AShift) and not (ssAlt in AShift) and URIOpener then
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
      Include(FState.Flags, sfIgnoreNextChar);
      CommandProcessor(LEditorCommand, LChar, LData);
    end
    else
      Exclude(FState.Flags, sfIgnoreNextChar);
  finally
    if Assigned(LData) then
      FreeMem(LData);
  end;

  if not ReadOnly and FCaret.MultiEdit.Active and not FMouse.OverURI and (ssCtrl in AShift) and (ssShift in AShift) and
    not (ssAlt in AShift) and (AKey in [VK_UP, VK_DOWN]) then
  begin
    AddCaret(ViewPosition);
    MoveCaretVertically(IfThen(AKey = VK_DOWN, 1, -1), False);
    AddCaret(ViewPosition);
    Invalidate;
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

  if FMultiEdit.Position.Row <> -1 then
  begin
    FMultiEdit.Position.Row := -1;

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
    Invalidate;
  end;
end;

procedure TCustomTextEditor.LinesHookChanged;
begin
  SetHorizontalScrollPosition(FScrollHelper.HorizontalPosition);
  UpdateScrollBars;
end;

procedure TCustomTextEditor.LinesCleared(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  MoveCaretToBeginning;
  ClearCodeFolding;
  ClearMatchingPair;
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
        LMark.Line := LMark.Line - ACount;

      LMark.Line := Min(LMark.Line, FLines.Count - 1);
    end;
  end;

begin
  LIndex := AIndex;

  if Assigned(FEvents.OnLinesDeleted) then
    FEvents.OnLinesDeleted(Self, LIndex, ACount);

  if FCodeFolding.Visible then
    CodeFoldingLinesDeleted(LIndex + 1, ACount);

  UpdateMarks(FBookmarkList);
  UpdateMarks(FMarkList);

  if FLines.Updating then
    Exit;

  if FHighlighter.Loaded then
    RescanHighlighterRanges;

  CreateLineNumbersCache(True);
  CodeFoldingResetCaches;
  EnsureCursorPositionVisible;
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

      LMark.Line := Min(LMark.Line, FLines.Count - 1);
    end;
  end;

begin
  if not FLines.Streaming then
  begin
    UpdateMarks(FBookmarkList);
    UpdateMarks(FMarkList);
  end;

  if FLines.Updating then
    Exit;

  if not FLines.Streaming then
  begin
    if FCodeFolding.Visible then
      UpdateFoldingRanges(AIndex + 1, ACount);

    if Assigned(FHighlighter.BeforePrepare) then
      FHighlighter.SetOption(hoExecuteBeforePrepare, True);
  end;

  if FHighlighter.Loaded and (FLines.Count > 0) then
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

{$IFDEF TEXT_EDITOR_SPELL_CHECK}
  if eoSpellCheck in FOptions then
    UpdateSpellCheckItems(AIndex, ACount);
{$ENDIF}

  Invalidate;
end;

procedure TCustomTextEditor.LinesPutted(ASender: TObject; const AIndex: Integer; const ACount: Integer); //FI:O804 Method parameter is declared but never used
var
  LIndex: Integer;
begin
  if FLines.Updating then
    Exit;

  if FHighlighter.Loaded and (FLines.Count > 0) then
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

{$IFDEF TEXT_EDITOR_SPELL_CHECK}
  if eoSpellCheck in FOptions then
    UpdateSpellCheckItems(AIndex, 0);
{$ENDIF}

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

procedure TCustomTextEditor.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TCustomTextEditor) then
  with ASource as TCustomTextEditor do
  begin
    Self.FActiveLine.Assign(FActiveLine);
    Self.Align := Align;
    Self.AlignWithMargins := AlignWithMargins;
    Self.Anchors := Anchors;
    Self.BorderStyle := BorderStyle;
    Self.BorderWidth := BorderWidth;
    Self.FCaret.Assign(FCaret);
    Self.FCodeFolding.Assign(FCodeFolding);
    Self.FColors.Assign(FColors);
    Self.FCompletionProposal.Assign(FCompletionProposal);
    Self.Constraints.Assign(Constraints);
    Self.Ctl3d := Ctl3d;
    Self.Cursor := Cursor;
    Self.CustomHint := CustomHint;
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
    Self.ParentColor := ParentColor;
    Self.ParentCtl3D := ParentCtl3D;
    Self.ParentFont := ParentFont;
    Self.ParentCustomHint := ParentCustomHint;
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
{$IFDEF TEXT_EDITOR_SPELL_CHECK}
    Self.SpellCheck := SpellCheck;
{$ENDIF}
    Self.StyleElements := StyleElements;
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

  if FMinimap.Visible and not FScroll.Dragging then
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

  SetFocus;

  if X + 4 > FLeftMarginWidth then
  begin
    if (AButton = mbLeft) or (AButton = mbRight) then
      LTextPosition := PixelsToTextPosition(X, Y);

    if not FRuler.Visible or FRuler.Visible and (Y > FRuler.Height) then
    begin
      FMouse.DownInText := TopLine + GetRowCountFromPixel(Y) <= FLineNumbers.Count;

      if FMouse.DownInText then
      begin
        IncPaintLock;
        try
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

              FPosition.SelectionEnd := FPosition.SelectionBegin;
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
              SelectionBeginPosition := LTextPosition;

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
      FRuler.Moving := roShowGuideLine in FRuler.Options;

      ShowRulerLegerLine(X, Y);
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

procedure TCustomTextEditor.ShowRulerLegerLine(const X, Y: Integer);
var
  LTextPosition: TTextEditorTextPosition;
  LHintWindow: THintWindow;
  LPositionText: string;
  LRect: TRect;
  LPoint: TPoint;
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
end;

procedure TCustomTextEditor.ShowMovingHint;
var
  LHintWindow: THintWindow;
  LPositionText: string;
  LRect: TRect;
  LPoint: TPoint;
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

procedure TCustomTextEditor.ShowCodeFoldingHint(const X, Y: Integer);
var
  LLine: Integer;
  LFoldRange: TTextEditorCodeFoldingRange;
  LPoint: TPoint;
  LRect: TRect;
  LIndex: Integer;
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
            BackgroundColor := FColors.CodeFoldingHintBackground;
            BorderColor := FColors.CodeFoldingHintBorder;
            Font.Assign(FFonts.CodeFoldingHint);
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

procedure TCustomTextEditor.MouseMove(AShift: TShiftState; X, Y: Integer);
var
  LViewPosition: TTextEditorViewPosition;
  LTextPosition: TTextEditorTextPosition;
  LMultiCaretPosition: TTextEditorViewPosition;
  LRow, LRowCount: Integer;
begin
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

          Invalidate;
        end;
    end;

    if Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) then
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

      if rmoShowMovingHint in FRightMargin.Options then
        ShowMovingHint;

      Invalidate;
      Exit;
    end;
  end;

  if FRuler.Moving and (X > FLeftMarginWidth) and (Y <= FRuler.Height) then
  begin
    ShowRulerLegerLine(X, Y);
    Exit;
  end;

  FRulerMovePosition := -1;

  if (AShift = []) and FCodeFolding.Visible and FCodeFolding.Hint.Indicator.Visible and FCodeFolding.Hint.Visible then
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

            if not IsSamePosition(FPosition.SelectionEnd, LTextPosition) then
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
              LTextPosition := GetBOFPosition;

            if not IsSamePosition(FPosition.Text, LTextPosition) then
              TextPosition := LTextPosition;

            if not IsSamePosition(FPosition.SelectionEnd, LTextPosition) then
              SelectionEndPosition := LTextPosition;
          end;
        end;

        ComputeScroll(FLast.MouseMovePoint);

        Include(FState.Flags, sfInSelection);
        Exclude(FState.Flags, sfCodeFoldingCollapseMarkClicked);

        Invalidate;
      end;
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
  FScroll.Dragging := False;

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

    if Assigned(FEvents.OnLinkClick) then
      FEvents.OnLinkClick(Self, LToken)
    else
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
  LDrawRect: TRect;
  LLine1, LLine2, LLine3: Integer;
  LSelectionAvailable: Boolean;
begin
  if FLines.ShowProgress then
  begin
    if Assigned(FEvents.OnLoadingProgress) then
      FEvents.OnLoadingProgress(Self)
    else
    if Assigned(Parent) then
      PaintProgressBar;

    Exit;
  end;

  LLine1 := FLineNumbers.TopLine;
  LLine2 := EnsureRange(FLineNumbers.TopLine + FLineNumbers.VisibleCount, 1, Max(FLineNumbers.Count, 1));
  LLine3 := FLineNumbers.TopLine + FLineNumbers.VisibleCount;

  if FCaret.NonBlinking.Active then
    HideCaret;

  FPaintHelper.BeginDrawing(Canvas.Handle);
  try
    Canvas.Brush.Color := FColors.EditorBackground;

    if FRuler.Visible then
      PaintRuler;

    FPaintHelper.SetBaseFont(FFonts.Text);

    { Text lines }
    LDrawRect.Top := 0;

    if FRuler.Visible then
      Inc(LDrawRect.Top, FRuler.Height);

    LDrawRect.Left := FLeftMarginWidth - FScrollHelper.HorizontalPosition;
    LDrawRect.Right := Width;
    LDrawRect.Bottom := ClientRect.Height;

    PaintTextLines(LDrawRect, LLine1, LLine2, False);
    PaintRightMargin(LDrawRect);

    if FCodeFolding.Visible and not FCodeFolding.TextFolding.Active and CodeFolding.GuideLines.Visible then
      PaintCodeFoldingGuides(FLineNumbers.TopLine, Min(FLineNumbers.TopLine + FLineNumbers.VisibleCount, FLineNumbers.Count));

    if not (csDesigning in ComponentState) then
    begin
      if FSyncEdit.Active and FSyncEdit.Visible then
        PaintSyncItems;

      if FCaret.Visible then
      begin
        if FCaret.NonBlinking.Active or Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) and FMultiEdit.Draw then
          PaintCaret;

        if Dragging then
          PaintCaretBlock(FViewPosition);

        if not Assigned(FCompletionProposalPopupWindow) and FCaret.MultiEdit.Active and (FMultiEdit.Position.Row <> -1) then
          PaintCaretBlock(FMultiEdit.Position);
      end;

      if FRightMargin.Moving then
        PaintRightMarginMove;

      if FRuler.Moving then
        PaintRulerMove;

      if FMouse.IsScrolling then
        PaintMouseScrollPoint;
    end;

    { Left margin and code folding }
    LDrawRect := ClientRect;

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
      LDrawRect := ClientRect;

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

      FPaintHelper.SetBaseFont(FFonts.Minimap);

      LSelectionAvailable := GetSelectionAvailable;

      if not FScroll.Dragging and (LDrawRect.Height = FMinimapHelper.BufferBitmap.Height) and (FLast.TopLine = FLineNumbers.TopLine) and
        (FLast.LineNumberCount = FLineNumbers.Count) and
        (not LSelectionAvailable or LSelectionAvailable and (FPosition.SelectionBegin.Line >= FLineNumbers.TopLine) and
        (FPosition.SelectionEnd.Line <= FLineNumbers.TopLine + FLineNumbers.VisibleCount)) then
      begin
        LLine1 := FLineNumbers.TopLine;
        LLine2 := Min(FLineNumbers.Count, FLineNumbers.TopLine + FLineNumbers.VisibleCount);

        BitBlt(Canvas.Handle, LDrawRect.Left, LDrawRect.Top, LDrawRect.Width, LDrawRect.Height,
          FMinimapHelper.BufferBitmap.Canvas.Handle, 0, 0, SRCCOPY);

        LDrawRect.Top := (FLineNumbers.TopLine - FMinimap.TopLine) * FMinimap.CharHeight;

        if FRuler.Visible then
          Inc(LDrawRect.Top, FRuler.Height);
      end
      else
      begin
        LLine1 := Max(FMinimap.TopLine, 1);
        LLine2 := Min(FLineNumbers.Count, LLine1 + ClientRect.Height div Max(FMinimap.CharHeight - 1, 1));
      end;

      PaintTextLines(LDrawRect, LLine1, LLine2, True);

      if ioUseBlending in FMinimap.Indicator.Options then
        PaintMinimapIndicator(LDrawRect);

      FMinimapHelper.BufferBitmap.Width := LDrawRect.Width;
      FMinimapHelper.BufferBitmap.Height := LDrawRect.Height;

      BitBlt(FMinimapHelper.BufferBitmap.Canvas.Handle, 0, 0, LDrawRect.Width, LDrawRect.Height, Canvas.Handle,
        LDrawRect.Left, LDrawRect.Top, SRCCOPY);

      FPaintHelper.SetBaseFont(FFonts.Text);
    end;

    { Search map }
    if FSearch.Map.Visible then
    begin
      LDrawRect := ClientRect;

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
        LDrawRect := ClientRect;

        LDrawRect.Left := FLeftMarginWidth - FLeftMargin.GetWidth - FCodeFolding.GetWidth;
        LDrawRect.Right := Width - FMinimap.GetWidth - FSearch.Map.GetWidth - 2;

        PaintMinimapShadow(Canvas, LDrawRect);
      end;

    if FScroll.Shadow.Visible and (FScrollHelper.HorizontalPosition <> 0) then
    begin
      LDrawRect := ClientRect;

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

    if not FCaret.NonBlinking.Active and not Assigned(FMultiEdit.Carets) then
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

  Canvas.Brush.Color := FColors.CodeFoldingBackground;
  FillRect(LRect);
  Canvas.Pen.Style := psSolid;
  Canvas.Brush.Color := FColors.CodeFoldingFoldingLine;

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

    if FActiveLine.Visible and (FColors.CodeFoldingActiveLineBackground <> TColors.SysNone) and
      (not Assigned(FMultiEdit.Carets) and (FPosition.Text.Line + 1 = LLine) or
       Assigned(FMultiEdit.Carets) and IsMultiEditCaretFound(LLine)) then
    begin
      if Focused then
        Canvas.Brush.Color := FColors.CodeFoldingActiveLineBackground
      else
        Canvas.Brush.Color := FColors.CodeFoldingActiveLineBackgroundUnfocused;

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
      Canvas.Brush.Color := FColors.CodeFoldingFoldingLineHighlight;
      Canvas.Pen.Color := FColors.CodeFoldingFoldingLineHighlight;
    end
    else
    begin
      Canvas.Brush.Color := FColors.CodeFoldingFoldingLine;
      Canvas.Pen.Color := FColors.CodeFoldingFoldingLine;
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
    LRect.Top := LRect.Top + (GetLineHeight - LHeight) shr 1 + 1;
    LRect.Bottom := LRect.Top + LHeight - 1;
    LRect.Right := LRect.Right - 1;

    if CodeFolding.MarkStyle = msTriangle then
    begin
      if LFoldRange.Collapsed then
      begin
        LPoints[0] := Point(LRect.Left, LRect.Top);
        LPoints[1] := Point(LRect.Left, LRect.Bottom - 1);
        LPoints[2] := Point(LRect.Right - (FCodeFolding.Width + 1) mod 2, LRect.Top + LRect.Height shr 1);

        Canvas.Polygon(LPoints);
      end
      else
      if AEndMark then
      begin
        LPoints[0] := Point(LRect.Left, LRect.Bottom - 1);
        LPoints[1] := Point(LRect.Right - (FCodeFolding.Width + 1) mod 2, LRect.Bottom - 1);
        LPoints[2] := Point(LRect.Left + LRect.Width shr 1, LRect.Top + 1);

        Canvas.Polygon(LPoints);
      end
      else
      begin
        LPoints[0] := Point(LRect.Left, LRect.Top + 1);
        LPoints[1] := Point(LRect.Right - (FCodeFolding.Width + 1) mod 2, LRect.Top + 1);
        LPoints[2] := Point(LRect.Left + LRect.Width shr 1, LRect.Bottom - 1);

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
        Canvas.Brush.Color := FColors.CodeFoldingBackground;
        Canvas.Ellipse(LRect);
      end;

      { - }
      LTempY := LRect.Top + ((LRect.Bottom - LRect.Top) shr 1);
      Canvas.MoveTo(LRect.Left + LRect.Width div 4, LTempY);
      Canvas.LineTo(LRect.Right - LRect.Width div 4, LTempY);

      if LFoldRange.Collapsed then
      begin
        { + }
        LTempY := (LRect.Right - LRect.Left) shr 1;
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
        Canvas.LineTo(LRect.Left + LRect.Width shr 1, LRect.Top);
        Canvas.LineTo(LRect.Right - (FCodeFolding.Width + 1) mod 2, LRect.Bottom);
      end
      else
      if not LFoldRange.Collapsed then
      begin
        LRect.Top := LRect.Bottom - 1;
        LRect.Bottom := AClipRect.Bottom;

        Canvas.MoveTo(LRect.Left, LRect.Top);
        Canvas.LineTo(LRect.Left + LRect.Width shr 1, LRect.Bottom);
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
        LX := LRect.Left + ((LRect.Right - LRect.Left) shr 1) - 1;

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
          LX := LRect.Left + ((LRect.Right - LRect.Left) shr 1) - 1;

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

    Canvas.Pen.Color := FColors.CodeFoldingCollapsedLine;
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
        if FColors.EditorBackground <> FColors.CodeFoldingHintIndicatorBackground then
        begin
          Canvas.Brush.Color := FColors.CodeFoldingHintIndicatorBackground;
          FillRect(LCollapseMarkRect);
        end;

        if hioShowBorder in FCodeFolding.Hint.Indicator.Options then
        begin
          LBrush := TBrush.Create;
          try
            LBrush.Color := FColors.CodeFoldingHintIndicatorBorder;
            Winapi.Windows.FrameRect(Canvas.Handle, LCollapseMarkRect, LBrush.Handle);
          finally
            LBrush.Free;
          end;
        end;

        if hioShowMark in FCodeFolding.Hint.Indicator.Options then
        begin
          Canvas.Pen.Color := FColors.CodeFoldingHintIndicatorMark;
          Canvas.Brush.Color := FColors.CodeFoldingHintIndicatorMark;

          case FCodeFolding.Hint.Indicator.MarkStyle of
            imsThreeDots:
              begin
                { [...] }
                LDotSpace := (LCollapseMarkRect.Width - 8) div 4;

                LY := LCollapseMarkRect.Top + (LCollapseMarkRect.Bottom - LCollapseMarkRect.Top) shr 1;
                LX := LCollapseMarkRect.Left + LDotSpace + (LCollapseMarkRect.Width - LDotSpace * 4 - 6) shr 1;

                LIndex := 1;

                while LIndex <= 3 do
                begin
                  Canvas.Rectangle(LX, LY, LX + 2, LY + 2);
                  LX := LX + LDotSpace + 2;
                  Inc(LIndex);
                end;
              end;
            imsTriangle:
              begin
                LX := (LCollapseMarkRect.Width - LCollapseMarkRect.Height) shr 1;
                LY := (LCollapseMarkRect.Width + 1) mod 2;
                LPoints[0] := Point(LCollapseMarkRect.Left + LX + 2, LCollapseMarkRect.Top + 2);
                LPoints[1] := Point(LCollapseMarkRect.Right - LX - 3 - LY, LCollapseMarkRect.Top + 2);
                LPoints[2] := Point(LCollapseMarkRect.Left + LCollapseMarkRect.Width shr 1 - LY, LCollapseMarkRect.Bottom - 3);

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

procedure TCustomTextEditor.PaintCodeFoldingGuides(const AFirstRow, ALastRow: Integer);
var
  LCurrentLine: Integer;
  LCodeFoldingRange, LCodeFoldingRangeTo: TTextEditorCodeFoldingRange;
  LCodeFoldingRanges: array of TTextEditorCodeFoldingRange;
  LRangeIndex: Integer;
  LTopLine, LBottomLine: Integer;
  LLine: Integer;

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

  procedure GetCodeFoldingRanges;
  var
    LIndex, LRow: Integer;
  begin
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
            LCodeFoldingRange.GuideLineOffset := 0;
            Inc(LRangeIndex);

            Break;
          end
        end;
      end;
    end;

    SetLength(LCodeFoldingRanges, LRangeIndex);
  end;

  function CreateBitmap(const AHighlightGuide: Boolean): Vcl.Graphics.TBitmap;
  var
    LN: Integer;
    LY: Integer;
    LStyle: TTextEditorCodeFoldingGuideLineStyle;
  begin
    Result := nil;

    if not AHighlightGuide and (FCodeFolding.GuideLines.Style = lsSolid) or
      AHighlightGuide and (FCodeFolding.GuideLines.HighlightStyle = lsSolid) then
      Exit;

    Result := Vcl.Graphics.TBitmap.Create;

    if AHighlightGuide then
      Result.Canvas.Pen.Color := FColors.CodeFoldingIndentHighlight
    else
      Result.Canvas.Pen.Color := FColors.CodeFoldingIndent;

    Result.Canvas.Brush.Color := TColors.Fuchsia;
    Result.Width := 1;
    Result.Height := 0; { background color }
    Result.Height := Height;

    LY := 1;

    if AHighlightGuide then
      LStyle := FCodeFolding.GuideLines.HighlightStyle
    else
      LStyle := FCodeFolding.GuideLines.Style;

    LN := IfThen(LStyle = lsDash, 3, 1);

    while LY < Result.Height do
    begin
      Result.Canvas.MoveTo(0, LY);
      Inc(LY, LN);
      Result.Canvas.LineTo(0, LY);
      Inc(LY, LN);
    end;
  end;

var
  LIndex, LRow: Integer;
  LX, LX1, LY, LZ: Integer;
  LOldColor: TColor;
  LDeepestLevel: Integer;
  LLineHeight, LBltLineHeight: Integer;
  LHighlightIndentGuides, LHideAtFirstColumn, LHideOverText, LHideInActiveRow: Boolean;
  LColor, LPixelColor: TColor;
  LSkip: Boolean;
  LHeight: Integer;
  LBitmap, LBitmapGuide, LBitmapHighlightGuide: Vcl.Graphics.TBitmap;
  LStyle: TTextEditorCodeFoldingGuideLineStyle;
begin
  LOldColor := Canvas.Pen.Color;

  LLineHeight := GetLineHeight;
  LY := 0;

  if FRuler.Visible then
    Inc(LY, FRuler.Height);

  LCurrentLine := GetViewTextLineNumber(FViewPosition.Row);
  LCodeFoldingRange := nil;

  LDeepestLevel := 0;

  if FCodeFolding.GuideLines.Visible and not FScroll.Dragging then
    LDeepestLevel := GetDeepestLevel;

  LTopLine := GetViewTextLineNumber(AFirstRow);
  LBottomLine := GetViewTextLineNumber(ALastRow);

  LHideAtFirstColumn := cfgHideAtFirstColumn in FCodeFolding.GuideLines.Options;
  LHideOverText := cfgHideOverText in FCodeFolding.GuideLines.Options;
  LHideInActiveRow := cgfHideInActiveRow in FCodeFolding.GuideLines.Options;
  LHighlightIndentGuides := cfgHighlightIndentGuides in FCodeFolding.GuideLines.Options;

  GetCodeFoldingRanges;

  LBitmapGuide := CreateBitmap(False);
  LBitmapHighlightGuide := CreateBitmap(True);
  try
    for LRow := AFirstRow to ALastRow do
    begin
      LLine := GetViewTextLineNumber(LRow);

      for LIndex := 0 to LRangeIndex - 1 do
      begin
        LCodeFoldingRange := LCodeFoldingRanges[LIndex];

        LHeight := LY + LLineHeight;

        if Assigned(LCodeFoldingRange) and not LCodeFoldingRange.Collapsed and not LCodeFoldingRange.ParentCollapsed and
          (LCodeFoldingRange.FromLine < LLine) and (LCodeFoldingRange.ToLine > LLine) then
        begin
          if Assigned(LCodeFoldingRange.RegionItem) and not LCodeFoldingRange.RegionItem.ShowGuideLine then
            Continue;

          LX := FLeftMarginWidth + GetLineIndentLevel(LCodeFoldingRange.ToLine - 1) * FPaintHelper.CharWidth +
            FCodeFolding.GuideLines.Padding;

          if LHideAtFirstColumn and (LX < FLeftMarginWidth + FPaintHelper.CharWidth) or
            LHideInActiveRow and (LRow = FViewPosition.Row) then
            Continue;

          if LHideOverText then
          begin
            LX1 := LX;
            LColor := Canvas.Pixels[LX1 + 1, LY];
            LZ := LY + 2;
            LSkip := False;

            while LZ < LHeight do
            begin
              LPixelColor := Canvas.Pixels[LX1, LZ];

              if LPixelColor = -1 then
                Break;

              if LPixelColor <> LColor then
              begin
                LSkip := True;
                Break;
              end;

              Inc(LZ);
            end;

            if LSkip then
            begin
              LCodeFoldingRange.GuideLineOffset := 0;
              Continue;
            end;
          end;

          Dec(LX, FScrollHelper.HorizontalPosition);

          if LX - FLeftMarginWidth > 0 then
          begin
            if LHighlightIndentGuides and FCodeFolding.GuideLines.Visible and
              (LDeepestLevel = LCodeFoldingRange.IndentLevel) and
              (LCurrentLine >= LCodeFoldingRange.FromLine) and (LCurrentLine <= LCodeFoldingRange.ToLine) then
            begin
              LBitmap := LBitmapHighlightGuide;
              Canvas.Pen.Color := FColors.CodeFoldingIndentHighlight;
              LStyle := FCodeFolding.GuideLines.HighlightStyle;
            end
            else
            begin
              LBitmap := LBitmapGuide;
              Canvas.Pen.Color := FColors.CodeFoldingIndent;
              LStyle := FCodeFolding.GuideLines.Style;
            end;

            if LStyle = lsSolid then
            begin
              Canvas.MoveTo(LX, LY + 1);
              Canvas.LineTo(LX, LHeight + 1);
            end
            else
            if Assigned(LBitmap) then
            begin
              LBltLineHeight := LLineHeight + 1;

              if LCodeFoldingRange.GuideLineOffset + LBltLineHeight > Height then
                LBltLineHeight := Height - LCodeFoldingRange.GuideLineOffset;

              TransparentBlt(Canvas.Handle, LX, LY, 1, LBltLineHeight, LBitmap.Canvas.Handle, 0,
                LCodeFoldingRange.GuideLineOffset, 1, LBltLineHeight, TColors.Fuchsia);

              LCodeFoldingRange.GuideLineOffset := LCodeFoldingRange.GuideLineOffset + LLineHeight;
            end;
          end;
        end;
      end;

      Inc(LY, LLineHeight);
    end;

    SetLength(LCodeFoldingRanges, 0);
  finally
    if Assigned(LBitmapGuide) then
      LBitmapGuide.Free;

    if Assigned(LBitmapHighlightGuide) then
      LBitmapHighlightGuide.Free;

    Canvas.Pen.Color := LOldColor;
  end;
end;

procedure TCustomTextEditor.CreateBookmarkImages;
var
  LPixelsPerInch: Integer;
begin
  if not Assigned(FImagesBookmark) then
  begin
{$IF CompilerVersion >= 35}
    if FLeftMargin.Bookmarks.Scaled then
      LPixelsPerInch := FPixelsPerInch
    else
{$ENDIF}
      LPixelsPerInch := 96;

    if Assigned(FLeftMargin.Bookmarks.Images) then
      FImagesBookmark := TTextEditorInternalImage.Create(FLeftMargin.Bookmarks.Images, TResourceBitmap.BookmarkImages,
        LPixelsPerInch)
    else
      FImagesBookmark := TTextEditorInternalImage.Create(HInstance, TResourceBitmap.BookmarkImages,
        TResourceBitmap.BookmarkImageCount, LPixelsPerInch);
  end;
end;

procedure TCustomTextEditor.PaintLeftMargin(const AClipRect: TRect; const AFirstLine, ALastTextLine, ALastLine: Integer);
var
  LLine, LPreviousLine, LCompareLine: Integer;
  LLineRect: TRect;
  LLineHeight: Integer;

  procedure DrawBookmark(const ABookmark: TTextEditorMark; var AOverlappingOffset: Integer; const AMarkRow: Integer);
  var
    LY: Integer;
    LRow: Integer;
  begin
    CreateBookmarkImages;

    LRow := AMarkRow;

    if FWordWrap.Active then
      LRow := GetViewLineNumber(LRow);

    LY := (LRow - TopLine) * LLineHeight;

    if FRuler.Visible then
      Inc(LY, FRuler.Height);

    FImagesBookmark.Draw(Canvas, ABookmark.ImageIndex, AClipRect.Left + FLeftMargin.Bookmarks.LeftMargin,
      LY, LLineHeight, TColors.Fuchsia);

    Inc(AOverlappingOffset, FLeftMargin.Marks.OverlappingOffset);
  end;

  procedure DrawMark(const AMark: TTextEditorMark; const AOverlappingOffset: Integer; const AMarkRow: Integer);
  var
    LY: Integer;
    LRow: Integer;
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

        LRow := AMarkRow;

        if FWordWrap.Active then
          LRow := GetViewLineNumber(LRow);

        FLeftMargin.Marks.Images.Draw(Canvas, AClipRect.Left + FLeftMargin.Marks.LeftMargin + AOverlappingOffset,
          (LRow - TopLine) * LLineHeight + LY, AMark.ImageIndex);
      end;
  end;

  procedure PaintLineNumbers;
  var
    LIndex, LTop, LLeft, LRight: Integer;
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
    FPaintHelper.SetBaseFont(FFonts.LineNumbers);
    try
      LLineRect := AClipRect;

      LLastTextLine := ALastTextLine;

      if lnoAfterLastLine in FLeftMargin.LineNumbers.Options then
        LLastTextLine := ALastLine;

      LCaretY := FPosition.Text.Line + 1;
      LCompareMode := lnoCompareMode in FLeftMargin.LineNumbers.Options;
      LCompareEmptyLine := False;
      LLeftMarginWidth := LLineRect.Left + FLeftMargin.GetWidth - FLeftMargin.LineState.Width - 1;
      LLongLineWidth := FLeftMarginCharWidth shr 1;
      LShortLineWith := 1;

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

        FPaintHelper.SetBackgroundColor(FColors.LeftMarginBackground);

        if FActiveLine.Visible and (not Assigned(FMultiEdit.Carets) and (LLine = LCaretY) or
          Assigned(FMultiEdit.Carets) and IsMultiEditCaretFound(LLine)) and (FColors.LeftMarginActiveLineBackground <> TColors.SysNone) then
        begin
          if Focused then
          begin
            FPaintHelper.SetBackgroundColor(FColors.LeftMarginActiveLineBackground);
            Canvas.Brush.Color := FColors.LeftMarginActiveLineBackground;
          end
          else
          begin
            FPaintHelper.SetBackgroundColor(FColors.LeftMarginActiveLineBackgroundUnfocused);
            Canvas.Brush.Color := FColors.LeftMarginActiveLineBackgroundUnfocused;
          end;

          if Assigned(FMultiEdit.Carets) then
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

        if FActiveLine.Visible and (LLine = LCaretY) and (FColors.ActiveLineForeground <> TColors.SysNone) then
        begin
          if Focused then
          begin
            if FColors.LeftMarginActiveLineNumber = TColors.SysNone then
              FPaintHelper.SetForegroundColor(FColors.ActiveLineForeground)
            else
              FPaintHelper.SetForegroundColor(FColors.LeftMarginActiveLineNumber)
          end
          else
            FPaintHelper.SetForegroundColor(FColors.ActiveLineForegroundUnfocused)
        end
        else
        if (LLine = LCaretY) and (FColors.LeftMarginActiveLineNumber <> TColors.SysNone) then
          FPaintHelper.SetForegroundColor(FColors.LeftMarginActiveLineNumber)
        else
          FPaintHelper.SetForegroundColor(FColors.LeftMarginLineNumbers);

        LPreviousLine := LLine;

        if FWordWrap.Active then
          LPreviousLine := GetViewTextLineNumber(LIndex - 1);

        LMargin := IfThen(FCodeFolding.Visible, 0, 2);

        if FLeftMargin.LineNumbers.Visible and not FWordWrap.Active and not LCompareEmptyLine or
          FWordWrap.Active and (LPreviousLine <> LLine) then
        begin
          LLineNumber := FLeftMargin.FormatLineNumber(LLine);

          if (LCaretY <> LLine) and (lnoIntens in LeftMargin.LineNumbers.Options) and
            (LLineNumber[Length(LLineNumber)] <> '0') and (LIndex <> LeftMargin.LineNumbers.StartFrom) then
          begin
            LOldColor := Canvas.Pen.Color;

            Canvas.Pen.Color := FColors.LeftMarginLineNumberLine;

            LTop := LLineRect.Top + (LLineHeight shr 1);
            LLeft := LLeftMarginWidth - LMargin - LLongLineWidth;
            LRight := LLeft;

            if LLine mod 5 = 0 then
              Dec(LLeft, LLongLineWidth)
            else
              Dec(LLeft, LShortLineWith);

            Canvas.MoveTo(LLeft, LTop);
            Canvas.LineTo(LRight, LTop);
            Canvas.Pen.Color := LOldColor;

            Continue;
          end;
        end;

        if not FLeftMargin.LineNumbers.Visible or LCompareEmptyLine then
          LLineNumber := ''
        else
        if LCompareMode then
        begin
          if LIndex < Length(FCompareLineNumberOffsetCache) then
            LCompareLine := FCompareLineNumberOffsetCache[LIndex]
          else
            LCompareLine := 0;

          LLineNumber := FLeftMargin.FormatLineNumber(LLine - LCompareLine);
        end;

        LLength := Length(LLineNumber);
        LPLineNumber := PChar(LLineNumber);

        GetTextExtentPoint32(Canvas.Handle, LPLineNumber, LLength, LTextSize);
        Winapi.Windows.ExtTextOut(Canvas.Handle, LLeftMarginWidth - LMargin - LTextSize.cx - 1,
          LLineRect.Top + ((LLineHeight - Integer(LTextSize.cy)) shr 1), ETO_OPAQUE, @LLineRect, LPLineNumber, LLength, nil);
      end;

      FPaintHelper.SetBackgroundColor(FColors.LeftMarginBackground);

      { Erase the remaining area }
      if AClipRect.Bottom > LLineRect.Bottom then
      begin
        LLineRect.Top := LLineRect.Bottom;
        LLineRect.Bottom := AClipRect.Bottom;

        Winapi.Windows.ExtTextOut(Canvas.Handle, LLineRect.Left, LLineRect.Top, ETO_OPAQUE, @LLineRect, '', 0, nil);
      end;
    finally
      FPaintHelper.SetBaseFont(FFonts.Text);
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

      if FColors.LeftMarginBookmarkPanelBackground <> TColors.SysNone then
      begin
        Canvas.Brush.Color := FColors.LeftMarginBookmarkPanelBackground;
        FillRect(LPanelRect);
      end;

      for LIndex := AFirstLine to ALastTextLine do
      begin
        LLine := GetViewTextLineNumber(LIndex);

        if FActiveLine.Visible and (FColors.LeftMarginActiveLineBackground <> TColors.SysNone) and
          not Assigned(FMultiEdit.Carets) and (LLine = FPosition.Text.Line + 1) or
          Assigned(FMultiEdit.Carets) and IsMultiEditCaretFound(LLine) then
        begin
          SetPanelActiveLineRect;

          if Focused then
            Canvas.Brush.Color := FColors.LeftMarginActiveLineBackground
          else
            Canvas.Brush.Color := FColors.LeftMarginActiveLineBackgroundUnfocused;

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
    begin
      FWordWrap.CreateIndicatorBitmap(FColors.WordWrapIndicatorArrow, FColors.WordWrapIndicatorLines);

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
  end;

  procedure PaintBorder;
  var
    LRightPosition: Integer;
  begin
    LRightPosition := AClipRect.Left + FLeftMargin.GetWidth - 2;

    if (FLeftMargin.Border.Style <> mbsNone) and (AClipRect.Right >= LRightPosition) then
    with Canvas do
    begin
      Pen.Color := FColors.LeftMarginBorder;
      Pen.Width := 1;

      if FLeftMargin.Border.Style = mbsMiddle then
      begin
        MoveTo(LRightPosition, AClipRect.Top);
        LineTo(LRightPosition, AClipRect.Bottom);
        Pen.Color := FColors.LeftMarginBackground;
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

      if FLeftMargin.LineState.Align = lsLeft then
      begin
        LLineStateRect.Left := FLeftMargin.LineState.Offset;
        LLineStateRect.Right := FLeftMargin.LineState.Width + FLeftMargin.LineState.Offset;
      end
      else
      begin
        LLineStateRect.Left := AClipRect.Right - FLeftMargin.LineState.Width - 1;
        LLineStateRect.Right := AClipRect.Right - 1;
      end;

      for LLine := AFirstLine to ALastTextLine do
      begin
        LTextLine := GetViewTextLineNumber(LLine);
        LLineState := FLines.LineState[LTextLine - 1];

        if FLeftMargin.LineState.ShowOnlyModified and (LLineState = lsModified) or
          not FLeftMargin.LineState.ShowOnlyModified and (LLineState <> lsNone) then
        begin
          LLineStateRect.Top := (LLine - TopLine) * LLineHeight;

          if FRuler.Visible then
            Inc(LLineStateRect.Top, FRuler.Height);

          LLineStateRect.Bottom := LLineStateRect.Top + LLineHeight;

          if LLineState = lsNormal then
            Canvas.Brush.Color := FColors.LeftMarginLineStateNormal
          else
            Canvas.Brush.Color := FColors.LeftMarginLineStateModified;

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
  FPaintHelper.SetBackgroundColor(FColors.LeftMarginBackground);
  Canvas.Brush.Color := FColors.LeftMarginBackground;
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
    Canvas.Brush.Color := FColors.MinimapVisibleRows;
    Width := AClipRect.Width;
    Height := FLineNumbers.VisibleCount * FMinimap.CharHeight;
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
    Canvas.Pen.Color := FColors.MinimapVisibleRows;
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
  LHalfWidth := FScroll.Indicator.Width shr 1;

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
  Canvas.Brush.Color := FColors.LeftMarginLineNumbers;
  Canvas.Pen.Color := FColors.LeftMarginLineNumbers;

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
  Canvas.Brush.Color := FColors.RulerBackground;

  FPaintHelper.SetBaseFont(FFonts.Ruler);
  FPaintHelper.SetBackgroundColor(Canvas.Brush.Color);
  FPaintHelper.SetForegroundColor(FColors.RulerNumbers);

  LRulerCaretPosition := FLeftMarginWidth + (FViewPosition.Column - 1) * LCharWidth - FScrollHelper.HorizontalPosition;
  try
    FillRect(LClipRect);

    with Canvas do
    begin
      Pen.Color := FColors.RulerBorder;
      Pen.Width := 1;
      MoveTo(0, LClipRect.Bottom);
      LineTo(LClipRect.Right, LClipRect.Bottom);

      LCharsInView := FScrollHelper.HorizontalPosition div LCharWidth;

      if (roShowSelection in FRuler.Options) and SelectionAvailable then
      begin
        LRect := LClipRect;
        LRect.Left := FLeftMarginWidth + (FPosition.SelectionBegin.Char - 1) * LCharWidth - FScrollHelper.HorizontalPosition;
        LRect.Right := LRulerCaretPosition;
        Canvas.Brush.Color := FColors.RulerSelection;
        FPaintHelper.SetBackgroundColor(Canvas.Brush.Color);
        FillRect(LRect);
        Canvas.Brush.Color := FColors.RulerBackground;
        FPaintHelper.SetBackgroundColor(Canvas.Brush.Color);
        Pen.Color := FColors.SelectionBackground;
        MoveTo(LRect.Left, 0);
        LineTo(LRect.Left, LClipRect.Bottom);
      end;

      LLeft := FLeftMarginWidth - FScrollHelper.HorizontalPosition mod LCharWidth;
      LLongLineY := LClipRect.Bottom - 4;
      LShortLineY := LClipRect.Bottom - 2;
      LRect := LClipRect;
      Dec(LRect.Bottom, 4);

      SetBkMode(Canvas.Handle, TRANSPARENT);

      Pen.Color := FColors.RulerLines;

      for LIndex := LCharsInView to FScrollHelper.PageWidth div LCharWidth + LCharsInView + 10 do
      begin
        if LIndex mod 10 = 0 then
        begin
          LLineY := LLongLineY;

          LNumbers := LIndex.ToString;;
          LRect.Left := LLeft;
          LRect.Right := LLeft + LNumbers.Length * FPaintHelper.CharWidth;
          LWidth := LRect.Width shr 1;
          Dec(LRect.Left, LWidth);
          Dec(LRect.Right, LWidth);

          Winapi.Windows.ExtTextOut(Handle, LLeft - LWidth, LRect.Top, 0, @LRect, PChar(LNumbers),
            LNumbers.Length, nil);
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
    FPaintHelper.SetBaseFont(FFonts.Text);
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
      Canvas.Pen.Color := FColors.RightMargin;

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
    LOldPenStyle := Pen.Style;
    LOldStyle := Brush.Style;

    Pen.Width := 1;
    Pen.Style := psDot;
    Pen.Color := FColors.RightMovingEdge;
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
    LOldPenStyle := Pen.Style;
    LOldStyle := Brush.Style;

    Pen.Width := 1;
    Pen.Style := psDot;
    Pen.Color := FColors.RulerMovingEdge;
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
  if FColors.SearchMapBackground <> TColors.SysNone then
    Canvas.Brush.Color := FColors.SearchMapBackground
  else
    Canvas.Brush.Color := FColors.EditorBackground;

  FillRect(LRect);

  { Lines in window }
  LHeight := ClientHeight / Max(FLines.Count, 1);
  LRect.Top := Round((TopLine - 1) * LHeight);
  LRect.Bottom := Max(Round((TopLine - 1 + FLineNumbers.VisibleCount) * LHeight), LRect.Top + 1);
  Canvas.Brush.Color := FColors.EditorBackground;
  FillRect(LRect);

  { Draw lines }
  if FColors.SearchMapForeground <> TColors.SysNone then
    Canvas.Pen.Color := FColors.SearchMapForeground
  else
    Canvas.Pen.Color := TColors.SysHighlight;

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
    if FColors.SearchMapActiveLine <> TColors.SysNone then
      Canvas.Pen.Color := FColors.SearchMapActiveLine
    else
      Canvas.Pen.Color := FColors.ActiveLineBackground;

    LLine := Round((FViewPosition.Row - 1) * LHeight);

    Canvas.MoveTo(LRect.Left, LLine);
    Canvas.LineTo(LRect.Right, LLine);
    Canvas.MoveTo(LRect.Left, LLine + 1);
    Canvas.LineTo(LRect.Right, LLine + 1);
  end;
end;

procedure TCustomTextEditor.SetOppositeColors;
begin
  FPaintHelper.SetBackgroundColor(Colors.EditorForeground);
  FPaintHelper.SetForegroundColor(Colors.EditorBackground);
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
              LPilcrow := TControlCharacterNames.CarriageReturn;

            if sfLineBreakLF in Flags then
              LPilcrow := LPilcrow + TControlCharacterNames.LineFeed;
          end;

          if LPilcrow.IsEmpty then
            if FLines.LineBreak = lbCRLF then
              LPilcrow := TControlCharacterNames.CarriageReturn + TControlCharacterNames.LineFeed
            else
            if FLines.LineBreak = lbLF then
              LPilcrow := TControlCharacterNames.LineFeed
            else
              LPilcrow := TControlCharacterNames.CarriageReturn;

          LCharRect.Width := LCharRect.Width * Length(LPilcrow) + 2;
          LCharRect.Top := LCharRect.Top + 2;
          LCharRect.Bottom := LCharRect.Bottom - 2;

          SetBkMode(Canvas.Handle, TRANSPARENT);
          Winapi.Windows.ExtTextOut(Canvas.Handle, LCharRect.Left + 1, LCharRect.Top - 2, ETO_OPTIONS, @LCharRect,
            PChar(LPilcrow), Length(LPilcrow), nil);
        end
        else
        if FSpecialChars.LineBreak.Style = eolPilcrow then
        begin
          FPaintHelper.SetForegroundColor(Canvas.Pen.Color);
          FPaintHelper.SetStyle([]);
          LPilcrow := TCharacters.Pilcrow;

          SetBkMode(Canvas.Handle, TRANSPARENT);
          Winapi.Windows.ExtTextOut(Canvas.Handle, LCharRect.Left, LCharRect.Top, ETO_OPTIONS, @LCharRect,
            PChar(LPilcrow), 1, nil);
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
          LY := LCharRect.Top + GetLineHeight shr 1;

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
  try
    Canvas.Brush.Style := bsClear;
    Canvas.Pen.Color := FColors.SyncEditEditBorder;
    DrawRectangle(FSyncEdit.EditBeginPosition);

    for LIndex := 0 to FSyncEdit.SyncItems.Count - 1 do
    begin
      LTextPosition := PTextEditorTextPosition(FSyncEdit.SyncItems.Items[LIndex])^;

      if LTextPosition.Line + 1 > TopLine + FLineNumbers.VisibleCount then
        Exit
      else
      if LTextPosition.Line + 1 >= TopLine then
      begin
        Canvas.Pen.Color := FColors.SyncEditWordBorder;
        DrawRectangle(LTextPosition);
      end;
    end;
  finally
    Canvas.Pen.Color := LOldPenColor;
    Canvas.Brush.Style := LOldBrushStyle;
  end;
end;

procedure TCustomTextEditor.PaintTextLines(const AClipRect: TRect; const AFirstLine, ALastLine: Integer; const AMinimap: Boolean);
var
  LAddWrappedCount: Boolean;
  LAnySelection: Boolean;
  LBackgroundColorRed, LBackgroundColorGreen, LBackgroundColorBlue: Byte;
  LBookmarkOnCurrentLine: Boolean;
  LCurrentLineLength: Integer;
  LCurrentLineText: string;
  LCurrentSearchIndex: Integer;
  LCustomBackgroundColor: TColor;
  LCustomForegroundColor: TColor;
  LCustomLineColors: Boolean;
  LExpandedCharsBefore: Integer;
  LForegroundColor, LBackgroundColor, LBorderColor: TColor;
  LIsLineSelected, LIsCurrentLine, LIsSyncEditBlock, LIsSearchInSelectionBlock: Boolean;
  LIsSelectionInsideLine: Boolean;
  LLineEndRect: TRect;
  LLineHeight: Integer;
  LLineRect, LTokenRect: TRect;
  LLineSelectionStart, LLineSelectionEnd: Integer;
  LMarkColor: TColor;
  LPaintedColumn: Integer;
  LPaintedWidth: Integer;
  LSelectedRect: TRect;
  LSelectionBeginPosition: TTextEditorTextPosition;
  LSelectionEndPosition: TTextEditorTextPosition;
  LTextPosition: TTextEditorTextPosition;
  LTokenHelper: TTextEditorTokenHelper;
  LViewLine, LCurrentLine: Integer;
  LWrappedRowCount, LWrappedUnvisibleLength: Integer;
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
      Result := FColors.MinimapBookmark
    else
    if LIsCurrentLine and FActiveLine.Visible and Focused and (FColors.ActiveLineBackground <> TColors.SysNone) then
      Result := FColors.ActiveLineBackground
    else
    if LIsCurrentLine and FActiveLine.Visible and not Focused and (FColors.ActiveLineBackgroundUnfocused <> TColors.SysNone) then
      Result := FColors.ActiveLineBackgroundUnfocused
    else
    if LMarkColor <> TColors.SysNone then
      Result := LMarkColor
    else
    if LIsSyncEditBlock then
      Result := FColors.SyncEditBackground
    else
    if LIsSearchInSelectionBlock then
      Result := FColors.SearchInSelectionBackground
    else
    if AMinimap and (FColors.MinimapBackground <> TColors.SysNone) then
      Result := FColors.MinimapBackground
    else
    begin
      Result := FColors.EditorBackground;

      LHighlighterAttribute := FHighlighter.RangeAttribute;

      if Assigned(LHighlighterAttribute) and (LHighlighterAttribute.Background <> TColors.SysNone) then
        Result := LHighlighterAttribute.Background;
    end;
  end;

  procedure SetDrawingColors(const ASelected: Boolean; const AFocused: Boolean = False);
  var
    LColor: TColor;
  begin
    { Selection colors }
    if AMinimap and (moShowBookmarks in FMinimap.Options) and LBookmarkOnCurrentLine then
      LColor := FColors.MinimapBookmark
    else
    if ASelected then
    begin
      if FColors.SelectionForeground <> TColors.SysNone then
        FPaintHelper.SetForegroundColor(FColors.SelectionForeground)
      else
        FPaintHelper.SetForegroundColor(LForegroundColor);

      if Focused or AFocused then
        LColor := FColors.SelectionBackground
      else
        LColor := FColors.SelectionBackgroundUnfocused
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
    LSearchTextLength, LCharCount, LBeginTextPositionChar, LLength: Integer;

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
    if (soHighlightResults in FSearch.Options) and (LCurrentSearchIndex <> -1) then
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

      if FColors.SearchHighlighterForeground <> TColors.SysNone then
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

        LLength := LBeginTextPositionChar + LSearchTextLength;

        LToken := Copy(LToken, 1, Min(LSearchTextLength, LLength - LTokenHelper.CharsBefore - LCharCount - 1));
        LSearchRect.Right := LSearchRect.Left + GetTokenWidth(LToken, Length(LToken), LPaintedColumn, AMinimap);

        if SameText(AText, LToken) then
          Inc(LSearchRect.Right, FItalic.Offset);

        if not LToken.IsEmpty then
          Winapi.Windows.ExtTextOut(Canvas.Handle, LSearchRect.Left, LSearchRect.Top, ETO_OPTIONS, @LSearchRect,
            PChar(LToken), Length(LToken), nil);

        if LLength > LCurrentLineLength then
          Break
        else
        if LLength > LTokenHelper.CharsBefore + Length(LToken) + LCharCount + 1 then
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
      if (LTokenLength = 0) or (AToken.Length = 0) then
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

      LIndex := 0;

      while LIndex < LTokenLength do
      begin
        Winapi.Windows.ExtTextOut(Canvas.Handle, LRect.Left + 1, LRect.Top - 1, ETO_OPTIONS, @LRect, PChar(LName),
          Length(LName), nil);

        Inc(LRect.Left, LCharWidth);
        LRect.Right := LRect.Left + LCharWidth - 1;

        Inc(LIndex);
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
      LRect.Top := LTokenRect.Top + LTokenRect.Height shr 1;
      LRect.Bottom := LRect.Top + 2;
      LRect.Left := LTextRect.Left + LSpaceWidth shr 1;

      LIndex := 0;

      while LIndex < LTokenLength do
      begin
        LRect.Right := LRect.Left + 2;

        Canvas.Rectangle(LRect);

        Inc(LRect.Left, LSpaceWidth);
        Inc(LIndex);
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
        if LTokenHelper.Overhang and (LPChar^ <> TCharacters.Space) and (ATokenLength = Length(AToken)) then
          Inc(LTextRect.Right, FPaintHelper.CharWidth);

        if (FItalic.Offset <> 0) and (not LTokenHelper.Overhang or (LPChar^ = TCharacters.Space)) then
        begin
          Inc(LTextRect.Left, FItalic.Offset);
          Inc(LTextRect.Right, FItalic.Offset);

          if not LTokenHelper.Overhang then
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
        (scoShowOnlyInSelection in FSpecialChars.Options) and (Canvas.Brush.Color = FColors.SelectionBackground)) and
        (not AMinimap or AMinimap and (moShowSpecialChars in FMinimap.Options)) then
      begin
        if FSpecialChars.Selection.Visible and (Canvas.Brush.Color = FColors.SelectionBackground) then
          Canvas.Pen.Color := FSpecialChars.Selection.Color
        else
          Canvas.Pen.Color := LTokenHelper.Foreground;

        FillRect(LTextRect);

        if (FSpecialChars.Selection.Visible and (Canvas.Brush.Color = FColors.SelectionBackground) or
          (Canvas.Brush.Color <> FColors.SelectionBackground)) then
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
            LTempBitmap.Height := LTextRect.Height;
            { Character }
            LTempBitmap.Canvas.Font.Assign(FFonts.Text);

            LTempRect := LTextRect;
            LTempRect.Top := 0;
            LTempRect.Height := LTextRect.Height;

            Winapi.Windows.ExtTextOut(LTempBitmap.Canvas.Handle, LTextRect.Left, 0, ETO_OPTIONS, @LTempRect, LPChar,
              LTokenLength, nil);

            BitBlt(Canvas.Handle, LSelectedRect.Left, LSelectedRect.Top, LSelectedRect.Width, LSelectedRect.Height,
              LTempBitmap.Canvas.Handle, LSelectedRect.Left, 0, SRCCOPY);
          finally
            LTempBitmap.Free
          end;
        end
        else
          Winapi.Windows.ExtTextOut(Canvas.Handle, LTextRect.Left, LTextRect.Top, ETO_OPTIONS, @LTextRect, LPChar,
            LTokenLength, nil);

        if not AMinimap and LTokenHelper.Overhang and (LPChar^ <> TCharacters.Space) and (ATokenLength <> 0) and
          (ATokenLength = AToken.Length) then
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
                  (LTriple.Blue <> LBackgroundColorBlue) and (LOrigMaxX + LLeft > LMaxX) then
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
    LIndex: Integer;
    LMultiCaretRecord: TTextEditorMultiCaretRecord;
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
      for LIndex := 0 to FMultiEdit.Carets.Count - 1 do
      begin
        LMultiCaretRecord := PTextEditorMultiCaretRecord(FMultiEdit.Carets[LIndex])^;

        if LMultiCaretRecord.SelectionBegin.Line = LCurrentLine then
        begin
          LLineSelectionStart := LMultiCaretRecord.SelectionBegin.Char;
          LLineSelectionEnd := LMultiCaretRecord.ViewPosition.Column;

          if LLineSelectionStart > LLineSelectionEnd then
            SwapInt(LLineSelectionStart, LLineSelectionEnd);

          LSelectionBeginPosition := GetPosition(LLineSelectionStart, LCurrentLine);
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

    if AMinimap and not (ioUseBlending in FMinimap.Indicator.Options) and (LViewLine >= TopLine) and
      (LViewLine < TopLine + FLineNumbers.VisibleCount) and (LBackgroundColor <> FColors.SearchHighlighterBackground) and
      (LBackgroundColor <> TColors.Red) then
      LBackgroundColor := FColors.MinimapVisibleRows;

    if LCustomLineColors then
    begin
      if LCustomForegroundColor <> TColors.SysNone then
        LForegroundColor := LCustomForegroundColor;

      if (LCustomBackgroundColor <> TColors.SysNone) and not LTokenHelper.CustomBackgroundColor then
        LBackgroundColor := LCustomBackgroundColor;
    end;

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
        LTokenRect.Right := LTokenRect.Left + GetTokenWidth(LText, LTokenLength, LTokenHelper.ExpandedCharsBefore, AMinimap, True);
        LTempRect := LTokenRect;

        PaintToken(LText, LTokenLength);

        { Selected part of the token }
        if (LLastColumn >= LLineSelectionEnd) or not LSecondUnselectedPartOfToken then
        begin
          { Get the unselected part from the end of the text }
          LText := Copy(LTempText, LTokenLength - (LLastColumn - LLineSelectionEnd) + 1);
          { Set left of the rect }
          LTokenRect.Left := LSelectedRect.Left + GetTokenWidth(LText, Length(LText), LTokenHelper.ExpandedCharsBefore, AMinimap, True);
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
          LTokenRect.Left := LSelectedRect.Left + GetTokenWidth(LText, Length(LText), LTokenHelper.ExpandedCharsBefore, AMinimap, True);
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
    if not LText.IsEmpty then
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
        if LCustomForegroundColor <> TColors.SysNone then
          LForegroundColor := LCustomForegroundColor;

        if LCustomBackgroundColor <> TColors.SysNone then
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
  begin
    LForeground := AForeground;
    LBackground := ABackground;

    if (LBackground = TColors.SysNone) or
      ((FColors.ActiveLineBackground <> TColors.SysNone) and LIsCurrentLine and not ACustomBackgroundColor) then
      LBackground := GetBackgroundColor;

    if AForeground = TColors.SysNone then
      LForeground := FColors.EditorForeground;

    LCanAppend := False;

    LToken := AToken;
    LTokenLength := ATokenLength;
    LPToken := PChar(LToken);

    if (eoShowNonBreakingSpaceAsSpace in Options) and (LPToken^ = TCharacters.NonBreakingSpace) then
      LPToken^ := TCharacters.Space;

    LEmptySpace := esNone;

    if LPToken^ <= TCharacters.Space then
    case LPToken^ of
      TCharacters.Space:
        LEmptySpace := esSpace;
      TControlCharacters.Substitute:
        LEmptySpace := esNull;
      TControlCharacters.Tab:
        LEmptySpace := esTab;
      TCharacters.ZeroWidthSpace:
        LEmptySpace := esZeroWidthSpace;
    else
      if LPToken^ in TControlCharacters.AsSet then
        LEmptySpace := esControlCharacter;
    end;

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
      LTokenHelper.CustomBackgroundColor := ACustomBackgroundColor;
      LTokenHelper.ExpandedCharsBefore := LExpandedCharsBefore;
      LTokenHelper.Foreground := LForeground;
      LTokenHelper.Background := LBackground;
      LTokenHelper.Border := ABorder;
      LTokenHelper.FontStyle := AFontStyle;
      LTokenHelper.Overhang := not AMinimap and ((fsItalic in AFontStyle) or not FPaintHelper.FixedSizeFont);
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
    LCurrentRow: Integer;
    LElement: string;
    LFoldRange: TTextEditorCodeFoldingRange;
    LFontStyles: TFontStyles;
    LFromLineText, LToLineText: string;
    LHighlighterAttribute: TTextEditorHighlighterAttribute;
    LIndex: Integer;
    LIsCustomBackgroundColor: Boolean;
    LItem: TTextEditorHighlightLineItem;
    LKeyword, LWordAtSelection, LSelectedText: string;
    LLine, LFirstColumn, LLastColumn: Integer;
    LLinePosition: Integer;
    LOpenTokenEndPos, LOpenTokenEndLen: Integer;
    LRegEx: TRegEx;
    LRegExOptions: TRegExOptions;
    LTextCaretY: Integer;
    LTextPosition: TTextEditorTextPosition;
    LTokenPosition, LWordWrapTokenPosition, LTokenLength: Integer;
    LTokenText, LNextTokenText: string;
    LUnderline: TTextEditorUnderline;
    LUnderlineColor: TColor;
    LWordWrapViewLength: Integer;

    procedure GetWordAtSelection;
    var
      LTempTextPosition: TTextEditorTextPosition;
      LSelectionBeginChar, LSelectionEndChar: Integer;
    begin
      LTempTextPosition := FPosition.SelectionEnd;
      LSelectionBeginChar := FPosition.SelectionBegin.Char;
      LSelectionEndChar := FPosition.SelectionEnd.Char;

      if LSelectionBeginChar > LSelectionEndChar then
        SwapInt(LSelectionBeginChar, LSelectionEndChar);

      LTempTextPosition.Char := LSelectionEndChar - 1;
      LSelectedText := Copy(FLines[FPosition.SelectionBegin.Line], LSelectionBeginChar,
        LSelectionEndChar - LSelectionBeginChar);

      if FPosition.SelectionBegin.Line = FPosition.SelectionEnd.Line then
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
          LForegroundColor := Colors.EditorForeground
        else
          LForegroundColor := LHighlighterAttribute.Foreground;

        if not AMinimap and LIsCurrentLine and FActiveLine.Visible and (FColors.ActiveLineForeground <> TColors.SysNone) then
          LForegroundColor := FColors.ActiveLineForeground;

        if AMinimap and (FColors.MinimapBackground <> TColors.SysNone) then
          LBackgroundColor := FColors.MinimapBackground
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
            LIsCustomBackgroundColor := (mpoUseMatchedColor in FMatchingPairs.Options) and not (mpoUnderline in FMatchingPairs.Options);

            if (FMatchingPair.Current = trOpenAndCloseTokenFound) or (FMatchingPair.Current = trCloseAndOpenTokenFound) then
            begin
              if LIsCustomBackgroundColor then
              begin
                if LForegroundColor = FColors.MatchingPairMatched then
                  LForegroundColor := FColors.EditorBackground;

                if not AMinimap and (FColors.ActiveLineForeground <> TColors.SysNone) then
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
            if FColors.SearchHighlighterForeground <> TColors.SysNone then
              LForegroundColor := FColors.SearchHighlighterForeground;

            LBackgroundColor := FColors.SearchHighlighterBackground;
            LBorderColor := FColors.SearchHighlighterBorder;
          end;
        end;

        if (LMarkColor <> TColors.SysNone) and not (LIsCurrentLine and FActiveLine.Visible and
          (FColors.ActiveLineBackground <> TColors.SysNone)) then
        begin
          LIsCustomBackgroundColor := True;
          LBackgroundColor := LMarkColor;
        end;

{$IFDEF TEXT_EDITOR_SPELL_CHECK}
        if (eoSpellCheck in FOptions) and Assigned(FSpellCheck) and (FSpellCheck.Items.Count > 0) and
          (LCurrentLine = LSpellCheckTextPosition.Line) and (LTokenPosition = LSpellCheckTextPosition.Char - 1) then
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
          FFonts.Text.Style, ulNone, TColors.SysNone, False);
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

          LSelectionBeginPosition := GetSelectionBeginPosition;
          LSelectionEndPosition := GetSelectionEndPosition;

          if FSelection.Mode = smColumn then
            if LSelectionBeginPosition.Char > LSelectionEndPosition.Char then
              SwapInt(LSelectionBeginPosition.Char, LSelectionEndPosition.Char);
        end
      end
      else
        LAnySelection := False;
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

        if FWordWrap.Active and (LWrappedUnvisibleLength > 0) then
        begin
          Dec(LLineSelectionStart, LWrappedUnvisibleLength);
          Dec(LLineSelectionEnd, LWrappedUnvisibleLength);
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
    LWordWrapViewLength := Length(FWordWrapLine.ViewLength);

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
                LOpenTokenEndLen := Length(LFoldRange.RegionItem.OpenTokenEnd);
                LCurrentLineText := Copy(LFromLineText, 1, LOpenTokenEndPos + LOpenTokenEndLen - 1);
              end
              else
                LCurrentLineText := Copy(LFromLineText, 1, Length(LFoldRange.RegionItem.OpenToken) +
                  Pos(LFoldRange.RegionItem.OpenToken, AnsiUpperCase(LFromLineText)) - 1);

              if not LFoldRange.RegionItem.CloseToken.IsEmpty then
                if Pos(LFoldRange.RegionItem.CloseToken, AnsiUpperCase(LToLineText)) <> 0 then
                begin
                  LCurrentLineText := LCurrentLineText + '..' + TextEditor.Utils.TrimLeft(LToLineText);

                  if LIsSelectionInsideLine then
                    LLineSelectionEnd := Length(LCurrentLineText);
                end;

              if LCurrentLine = FMatchingPair.CurrentMatch.OpenTokenPos.Line then
              begin
                if not LFoldRange.RegionItem.OpenTokenEnd.IsEmpty and (LOpenTokenEndPos > 0) then
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
      LIsSyncEditBlock := False;
      LIsSearchInSelectionBlock := False;

      while LCurrentRow = LCurrentLine + 1 do
      begin
        LPaintedWidth := 0;
        FItalic.Offset := 0;

        if Assigned(FMultiEdit.Carets) then
          LIsCurrentLine := IsMultiEditCaretFound(LCurrentLine + 1)
        else
          LIsCurrentLine := LTextCaretY = LCurrentLine;

        LForegroundColor := FColors.EditorForeground;
        LBackgroundColor := GetBackgroundColor;
        LCustomLineColors := False;

        if FHighlightLine.Active and not LCurrentLineText.IsEmpty then
        for LIndex := FHighlightLine.Items.Count - 1 downto 0 do
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
        LTokenHelper.EmptySpace := esNone;
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

        if LWrappedRowCount > FLineNumbers.VisibleCount then
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
    LBackgroundColor := FColors.EditorBackground;
    SetDrawingColors(False);
    FillRect(LTokenRect);
  end;
end;

procedure TCustomTextEditor.RedoItem;
var
  LUndoItem: TTextEditorUndoItem;
  LRun, LStrToDelete: PChar;
  LLength: Integer;
  LTempText: string;
  LChangeScrollPastEndOfLine: Boolean;
  LBeginX: Integer;
  LTextPosition, LSelectionBeginPosition, LSelectionEndPosition: TTextEditorTextPosition;
  LPMultiCaretRecord: PTextEditorMultiCaretRecord;
  LIndex: Integer;
  LCharChange, LLineChange: Integer;
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
      crMultiCaret:
        if Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) then
        begin
          LPMultiCaretRecord := PTextEditorMultiCaretRecord(FMultiEdit.Carets[0]);
          LTextPosition := ViewToTextPosition(LPMultiCaretRecord^.ViewPosition);

          FUndoList.AddChange(LUndoItem.ChangeReason, LTextPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition, '', FSelection.ActiveMode, LUndoItem.ChangeBlockNumber);

          LCharChange := LUndoItem.ChangeCaretPosition.Char - LTextPosition.Char;
          LLineChange := LUndoItem.ChangeCaretPosition.Line - LTextPosition.Line;

          for LIndex := 0 to FMultiEdit.Carets.Count - 1 do
          begin
            LPMultiCaretRecord := PTextEditorMultiCaretRecord(FMultiEdit.Carets[LIndex]);

            LTextPosition := ViewToTextPosition(LPMultiCaretRecord^.ViewPosition);
            Inc(LTextPosition.Char, LCharChange);
            Inc(LTextPosition.Line, LLineChange);
            LPMultiCaretRecord^.ViewPosition := TextToViewPosition(LTextPosition);
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
          LSelectionBeginPosition := SelectionBeginPosition;
          LSelectionEndPosition := SelectionEndPosition;

          SetTextPositionAndSelection(LUndoItem.ChangeCaretPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeBeginPosition);

          DoSelectedText(LUndoItem.ChangeSelectionMode, PChar(LUndoItem.ChangeString), False,
            LUndoItem.ChangeBeginPosition, LUndoItem.ChangeBlockNumber);

          IncCharacterCount(LUndoItem.ChangeString);

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
          SelectionBeginPosition := LSelectionBeginPosition;
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
                LTempText := FLines.Items^[FPosition.Text.Line].TextLine;
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

procedure TCustomTextEditor.ResetCaret;
var
  LCaretStyle: TTextEditorCaretStyle;
  LWidth, LHeight: Integer;
begin
  if (csDesigning in ComponentState) or (csDestroying in ComponentState) then
    Exit;

  if Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) then
    Exit;

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
        LHeight := GetLineHeight shr 1;
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

procedure TCustomTextEditor.ScanTagMatchingPair;
type
  TTagInfo = record
    Char: Integer;
    Length: Integer;
    Line: Integer;
    Name: string;
  end;
var
  LTextPosition: TTextEditorTextPosition;
  LLineText, LCurrentTagName: string;
  LLength: Integer;
  LPChar, LPStart: PChar;
  LLine, LChar: Integer;
  LTagStack: TStack<TTagInfo>;
  LTagName: string;
  LTagInfo: TTagInfo;
  LIsEndTag, LIsSelfClosing: Boolean;

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

  while not (LPChar^ in [TCharacters.TagClose, TControlCharacters.Null, TCharacters.Space, TCharacters.Slash]) do
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

        while not (LPChar^ in [TCharacters.TagClose, TControlCharacters.Null, TCharacters.Space, TCharacters.Slash]) do
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
  LLine, LTempPosition: Integer;
  LViewPosition: TTextEditorViewPosition;
  LFoldRange: TTextEditorCodeFoldingRange;
  LOpenLineText: string;
  LLineText: string;
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
        Length(LFoldRange.RegionItem.CloseToken));

      if LFoldRange.Collapsed then
        FMatchingPair.CurrentMatch.CloseTokenPos :=
          GetPosition(FMatchingPair.CurrentMatch.OpenTokenPos.Char + Length(FMatchingPair.CurrentMatch.OpenToken) +
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
  if not FHighlighter.MatchingPairHighlight then
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
      begin
        HideCaret;
        Winapi.Windows.DestroyCaret;
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

  IncPaintLock;
  try
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

  procedure SetSelectedText;
  var
    LSelectedText: string;
  begin
    LSelectionBeginPosition := SelectionBeginPosition;

    LSelectedText := GetSelectedText;

    AddUndoDelete(TextPosition, LSelectionBeginPosition, SelectionEndPosition, LSelectedText, FSelection.ActiveMode);

    DoSelectedText(AChangeString);

    LTextPosition := TextPosition;

    if not AChangeString.IsEmpty then
      AddUndoInsert(LSelectionBeginPosition, LSelectionBeginPosition, LTextPosition, '', smNormal);

    FPosition.SelectionBegin := LTextPosition;
    FPosition.SelectionEnd := LTextPosition;
  end;

  procedure SetMultiSelectedText;
  var
    LIndex: Integer;
    LMultiCaretRecord: TTextEditorMultiCaretRecord;
    LLineSelectionStart, LLineSelectionEnd: Integer;
  begin
    if Assigned(FMultiEdit.Carets) then
    for LIndex := FMultiEdit.Carets.Count - 1 downto 0 do
    begin
      LMultiCaretRecord := PTextEditorMultiCaretRecord(FMultiEdit.Carets[LIndex])^;

      LLineSelectionStart := LMultiCaretRecord.SelectionBegin.Char;
      LLineSelectionEnd := LMultiCaretRecord.ViewPosition.Column;

      if LLineSelectionStart > LLineSelectionEnd then
        SwapInt(LLineSelectionStart, LLineSelectionEnd);

      SelectionBeginPosition := GetPosition(LLineSelectionStart, LMultiCaretRecord.SelectionBegin.Line);
      SelectionEndPosition := GetPosition(LLineSelectionEnd, LMultiCaretRecord.SelectionBegin.Line);
      TextPosition := SelectionEndPosition;

      SetSelectedText;
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
  LTextPosition: TTextEditorTextPosition;
  LTempString: string;
  LDeleteSelection: Boolean;

  procedure DeleteSelection;
  var
    LLine: Integer;
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

        AddUndoInsert(LTextPosition, LBeginPosition, LEndPosition, '', smNormal);
      end;

      LLineText := FLines[LTextPosition.Line];
      LRightSide := Copy(LLineText, LTextPosition.Char, Length(LLineText) - (LTextPosition.Char - 1));

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
    finally
      { Force caret reset }
      TextPosition := LTextPosition;
    end;
  end;

begin
  BeginUpdate;
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

    if AValue = '' then
      ClearSelection
    else
      InsertText;
  finally
    EndUpdate;
  end;
end;

procedure TCustomTextEditor.ShowCaret;
begin
  if csDesigning in ComponentState then
    Exit;

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
  LPMultiCaretRecord: PTextEditorMultiCaretRecord;
  LIndex: Integer;
  LCharChange, LLineChange: Integer;
  LTextPosition: TTextEditorTextPosition;
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
      crMultiCaret:
        if Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) then
        begin
          LPMultiCaretRecord := PTextEditorMultiCaretRecord(FMultiEdit.Carets[0]);
          LTextPosition := ViewToTextPosition(LPMultiCaretRecord^.ViewPosition);

          FRedoList.AddChange(LUndoItem.ChangeReason, LTextPosition, LUndoItem.ChangeBeginPosition,
            LUndoItem.ChangeEndPosition, '', FSelection.ActiveMode, LUndoItem.ChangeBlockNumber);

          LCharChange := LUndoItem.ChangeCaretPosition.Char - LTextPosition.Char;
          LLineChange := LUndoItem.ChangeCaretPosition.Line - LTextPosition.Line;

          for LIndex := 0 to FMultiEdit.Carets.Count - 1 do
          begin
            LPMultiCaretRecord := PTextEditorMultiCaretRecord(FMultiEdit.Carets[LIndex]);

            LTextPosition := ViewToTextPosition(LPMultiCaretRecord^.ViewPosition);
            Inc(LTextPosition.Char, LCharChange);
            Inc(LTextPosition.Line, LLineChange);
            LPMultiCaretRecord^.ViewPosition := TextToViewPosition(LTextPosition);
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

          FPosition.SelectionBegin := LUndoItem.ChangeBeginPosition;
          FPosition.SelectionEnd := FPosition.SelectionBegin;

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

          if (LUndoItem.ChangeBeginPosition.Char - 1 > Length(LTempText)) and (LeftSpaceCount(LUndoItem.ChangeString) = 0) then
            LTempText := LTempText + StringOfChar(TCharacters.Space, LUndoItem.ChangeBeginPosition.Char - 1 -
              Length(LTempText));

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

function TCustomTextEditor.SelectSearchItem(const AIndex: Integer): Boolean;
var
  LSearchItem: PTextEditorSearchItem;
begin
  Result := False;

  if (FSearch.Items.Count > 0) and (AIndex >= 0) and (AIndex < FSearch.Items.Count) then
  begin
    LSearchItem := PTextEditorSearchItem(FSearch.Items.Items[AIndex]);

    GoToLineAndSetPosition(LSearchItem.BeginTextPosition.Line, LSearchItem.BeginTextPosition.Char, FSearch.ResultPosition);

    SelectionBeginPosition := LSearchItem.BeginTextPosition;
    SelectionEndPosition := LSearchItem.EndTextPosition;

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
      Beep;

    if FSearch.Items.Count = 0 then
    begin
      if soShowSearchStringNotFound in FSearch.Options then
        DoSearchStringNotFoundDialog;
    end
    else
    if FSearch.Items.Count = 1 then
      Result := True
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

    SelectionBeginPosition := LSearchItem.BeginTextPosition;
    SelectionEndPosition := LSearchItem.EndTextPosition;

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
      Beep;

    if FSearch.Items.Count = 0 then
    begin
      if soShowSearchStringNotFound in FSearch.Options then
        DoSearchStringNotFoundDialog;
    end
    else
    if FSearch.Items.Count = 1 then
      Result := True
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
  LGlobalMem: HGlobal;
  LLocaleID: LCID;
  LBytePointer: PByte;

  function AnsiStringToString(const AValue: AnsiString; const ACodePage: Word): string;
  var
    LInputLength, LOutputLength: Integer;
  begin
    LInputLength := Length(AValue);
    LOutputLength := MultiByteToWideChar(ACodePage, 0, PAnsiChar(AValue), LInputLength, nil, 0);
    SetLength(Result, LOutputLength);
    MultiByteToWideChar(ACodePage, 0, PAnsiChar(AValue), LInputLength, PChar(Result), LOutputLength);
  end;

  function CodePageFromLocale(const ALanguage: LCID): Integer;
  var
    LBuffer: array [0 .. 6] of Char;
  begin
    GetLocaleInfo(ALanguage, LOCALE_IDEFAULTANSICODEPAGE, LBuffer, 6);
    Result := StrToIntDef(LBuffer, GetACP);
  end;

begin
  Result := '';

  if OpenClipboard then
  try
    if Clipboard.HasFormat(CF_UNICODETEXT) then
    begin
      LGlobalMem := Clipboard.GetAsHandle(CF_UNICODETEXT);

      if LGlobalMem <> 0 then
      try
        Result := PChar(GlobalLock(LGlobalMem));
      finally
        GlobalUnlock(LGlobalMem);
      end;
    end
    else
    begin
      LLocaleID := 0;
      LGlobalMem := Clipboard.GetAsHandle(CF_LOCALE);

      if LGlobalMem <> 0 then
      try
        LLocaleID := PInteger(GlobalLock(LGlobalMem))^;
      finally
        GlobalUnlock(LGlobalMem);
      end;

      LGlobalMem := Clipboard.GetAsHandle(CF_TEXT);

      if LGlobalMem <> 0 then
      try
        LBytePointer := GlobalLock(LGlobalMem);
        Result := AnsiStringToString(PAnsiChar(LBytePointer), CodePageFromLocale(LLocaleID));
      finally
        GlobalUnlock(LGlobalMem);
      end;
    end;
  finally
    Clipboard.Close;
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
  Result := FHighlighter.Loaded and (AChar in FHighlighter.Comments.Chars);
end;

function TCustomTextEditor.IsTextPositionInSelection(const ATextPosition: TTextEditorTextPosition): Boolean;
var
  LBeginTextPosition, LEndTextPosition: TTextEditorTextPosition;
begin
  LBeginTextPosition := SelectionBeginPosition;
  LEndTextPosition := SelectionEndPosition;

  if IsSamePosition(LBeginTextPosition, LEndTextPosition) then
    Result := False
  else
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
      Result := ((ATextPosition.Line > LBeginTextPosition.Line) or
        (ATextPosition.Line = LBeginTextPosition.Line) and (ATextPosition.Char >= LBeginTextPosition.Char))
        and
        ((ATextPosition.Line < LEndTextPosition.Line) or
        (ATextPosition.Line = LEndTextPosition.Line) and (ATextPosition.Char < LEndTextPosition.Char));
  end;
end;

function TCustomTextEditor.ReplaceSelectedText(const AReplaceText: string; const ASearchText: string;
  const AAction: TTextEditorReplaceTextAction = rtaReplace): Boolean;
var
  LOptions: TRegExOptions;
  LReplaceText: string;
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
  end;

  EndUndoBlock;
  ResetCharacterCount;

  Result := True;
end;

function TCustomTextEditor.ReplaceText(const ASearchText: string; const AReplaceText: string;
  const AReplaceAll: Boolean = True; const APageIndex: Integer = -1): Integer;
var
  LFound: Boolean;
  LActionReplace: TTextEditorReplaceAction;
  LTextPosition: TTextEditorTextPosition;
  LOriginalTextPosition: TTextEditorTextPosition;
  LItemIndex: Integer;
  LSearchItem: PTextEditorSearchItem;
  LIsWrapAround: Boolean;
  LReplaceTextParams: TTextEditorReplaceTextParams;
begin
  if not Assigned(FSearchEngine) then
    raise ETextEditorBaseException.Create(STextEditorSearchEngineNotAssigned);

  Result := 0;

  FState.ReplaceCanceled := False;

  if Length(ASearchText) = 0 then
    Exit;

  LOriginalTextPosition := TextPosition;

  LIsWrapAround := soWrapAround in FSearch.Options;

  with LReplaceTextParams do
  begin
    AddLineBreak := rtaAddLineBreak = FReplace.Action;
    Backwards := roBackwards in FReplace.Options;
    DeleteLine := rtaDeleteLine = FReplace.Action;
    Prompt := roPrompt in FReplace.Options;
    ReplaceAll := roReplaceAll in FReplace.Options;
    ReplaceText := AReplaceText;
    SearchText := ASearchText;

    if AddLineBreak then
      ReplaceTextAction := rtaAddLineBreak
    else
    if DeleteLine then
      ReplaceTextAction := rtaDeleteLine
    else
      ReplaceTextAction := rtaReplace;
  end;

  if LIsWrapAround then
    FSearch.SetOption(soWrapAround, False);

  ClearCodeFolding;

  SearchAll(ASearchText);

  Result := FSearch.Items.Count;

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

    if SelectionAvailable then
      TextPosition := SelectionBeginPosition;

    if not LReplaceTextParams.Prompt then
      BeginUpdate;

    if AReplaceAll then
      LActionReplace := raReplaceAll
    else
      LActionReplace := raReplace;

    LFound := True;

    if LReplaceTextParams.Prompt then
      Result := 0;

    while LFound do
    begin
      if LReplaceTextParams.Backwards then
        LFound := FindPrevious(False)
      else
        LFound := FindNext(False);

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
            Continue
          end;
        raReplaceAll:
          begin
            FLast.DeletedLine := -1;

            for LItemIndex := FSearch.Items.Count - 1 downto 0 do
            begin
              LSearchItem := PTextEditorSearchItem(FSearch.Items.Items[LItemIndex]);

              if not (roEntireScope in FReplace.Options) or LReplaceTextParams.Prompt then
                if LReplaceTextParams.Backwards and
                  ( (LSearchItem.BeginTextPosition.Line > LOriginalTextPosition.Line) or
                    (LSearchItem.BeginTextPosition.Line = LOriginalTextPosition.Line) and
                    (LSearchItem.BeginTextPosition.Char > LOriginalTextPosition.Char) )
                  or not LReplaceTextParams.Backwards and
                  ( (LSearchItem.BeginTextPosition.Line < LOriginalTextPosition.Line) or
                    (LSearchItem.BeginTextPosition.Line = LOriginalTextPosition.Line) and
                    (LSearchItem.BeginTextPosition.Char < LOriginalTextPosition.Char) ) then
                  Continue;

              SelectionBeginPosition := LSearchItem.BeginTextPosition;
              SelectionEndPosition := LSearchItem.EndTextPosition;

              if not LReplaceTextParams.DeleteLine or
                LReplaceTextParams.DeleteLine and (FLast.DeletedLine <> LSearchItem.BeginTextPosition.Line) then
                ReplaceSelectedText(AReplaceText, ASearchText, LReplaceTextParams.ReplaceTextAction);

              FLast.DeletedLine := LSearchItem.BeginTextPosition.Line;
            end;

            Exit;
          end;
      end;

      ReplaceSelectedText(AReplaceText, ASearchText, LReplaceTextParams.ReplaceTextAction);

      if (LActionReplace = raReplace) and LReplaceTextParams.Prompt then
      begin
        Inc(Result);
        SearchAll(ASearchText);
      end;

      if (LActionReplace = raReplace) and not LReplaceTextParams.Prompt then
        Exit;
    end;
  finally
    FSearch.ClearItems;

    if LIsWrapAround then
      FSearch.SetOption(soWrapAround, True);

    FUndoList.EndBlock;

    ResetCharacterCount;
    SelectionEndPosition := SelectionBeginPosition;

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

      Invalidate;
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
          if LWord.IsEmpty and (LPText^ in TCharacterSets.Characters + [TCharacters.Underscore]) or
            not LWord.IsEmpty and (LPText^ in TCharacterSets.CharactersandNumbers + [TCharacters.Underscore]) then
            LWord := LWord + LPText^
          else
          begin
            if not LWord.IsEmpty and (Length(LWord) > 1) then
              AddKeyword(LWord);

            LWord := ''
          end;
        end;

        if LPText^ <> TControlCharacters.Null then
          Inc(LPText);
      end;

      if not LWord.IsEmpty and (Length(LWord) > 1) then
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
      if LSnippetItem.Description.IsEmpty then
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

function CompareCaretRecords(AItem1, AItem2: Pointer): Integer;
var
  LViewPosition1: TTextEditorViewPosition;
  LViewPosition2: TTextEditorViewPosition;
begin
  LViewPosition1 := PTextEditorMultiCaretRecord(AItem1)^.ViewPosition;
  LViewPosition2 := PTextEditorMultiCaretRecord(AItem2)^.ViewPosition;

  Result := LViewPosition1.Row - LViewPosition2.Row;

  if Result = 0 then
    Result := LViewPosition1.Column - LViewPosition2.Column;
end;

procedure TCustomTextEditor.AddCaret(const AViewPosition: TTextEditorViewPosition);
var
  LIndex: Integer;
  LPMultiCaretRecord: PTextEditorMultiCaretRecord;
begin
  if AViewPosition.Row > FLineNumbers.Count then
    Exit;

  if not Assigned(FMultiEdit.Carets) then
  begin
    FMultiEdit.Draw := True;
    FMultiEdit.Carets := TList.Create;
    FMultiEdit.SelectionAvailable := False;
    FMultiEdit.Timer := TTextEditorTimer.Create(Self);
    FMultiEdit.Timer.Interval := GetCaretBlinkTime;
    FMultiEdit.Timer.OnTimer := MultiCaretTimerHandler;
    FMultiEdit.Timer.Enabled := True;
  end;

  LIndex := 0;

  while LIndex < FMultiEdit.Carets.Count do
  begin
    LPMultiCaretRecord := PTextEditorMultiCaretRecord(FMultiEdit.Carets[LIndex]);

    if (LPMultiCaretRecord^.ViewPosition.Row = AViewPosition.Row) and
      (LPMultiCaretRecord^.ViewPosition.Column = AViewPosition.Column) then
      Exit;

    Inc(LIndex);
  end;

  New(LPMultiCaretRecord);
  LPMultiCaretRecord^.ViewPosition.Column := AViewPosition.Column;
  LPMultiCaretRecord^.ViewPosition.Row := AViewPosition.Row;

  FMultiEdit.Carets.Add(LPMultiCaretRecord);
  FMultiEdit.Carets.Sort(CompareCaretRecords);

  HideCaret;
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
  LPMultiCaretRecord: PTextEditorMultiCaretRecord;
begin
  LViewPosition := ViewPosition;

  if LViewPosition.Row > FLineNumbers.Count then
    Exit;

  if Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) then
  begin
    LPMultiCaretRecord := PTextEditorMultiCaretRecord(FMultiEdit.Carets.Last);
    LBeginRow := LPMultiCaretRecord^.ViewPosition.Row;
    LViewPosition.Column := LPMultiCaretRecord^.ViewPosition.Column;
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
  ClearCodeFolding;
end;

procedure TCustomTextEditor.MoveCaretToBeginning;
var
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := GetBOFPosition;

  FPosition.SelectionBegin := LTextPosition;
  FPosition.SelectionEnd := LTextPosition;

  TextPosition := LTextPosition;
end;

procedure TCustomTextEditor.MoveCaretToEnd;
var
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := GetPosition(Length(FLines[LTextPosition.Line]), FLines.Count - 1);

  FPosition.SelectionBegin := LTextPosition;
  FPosition.SelectionEnd := LTextPosition;

  TextPosition := LTextPosition;
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
        AddUndoDelete(TextPosition, LSelectionBeginPosition, LSelectionEndPosition, LUndoText, smColumn);
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
        AddUndoDelete(TextPosition, LSelectionBeginPosition, LSelectionEndPosition, LUndoText, smColumn);
        Inc(LSelectionBeginPosition.Line);
      end;
    mdLeft:
      begin
        LEmptyBeginPosition := GetPosition(LSelectionEndPosition.Char - 1, LSelectionBeginPosition.Line);
        LEmptyEndPosition := LSelectionEndPosition;
        LIndex := 0;

        while LIndex < LEmptyEndPosition.Line - LEmptyBeginPosition.Line do
        begin
          LEmptyText := ' ' + FLines.DefaultLineBreak;
          Inc(LIndex);
        end;

        LEmptyText := LEmptyText + ' ';
        Dec(LSelectionBeginPosition.Char);
        SelectionBeginPosition := LSelectionBeginPosition;
        SelectionEndPosition := LSelectionEndPosition;
        LUndoText := SelectedText;
        AddUndoDelete(TextPosition, LSelectionBeginPosition, LSelectionEndPosition, LUndoText, smColumn);
        Dec(LSelectionEndPosition.Char);
      end;
    mdRight:
      begin
        LEmptyBeginPosition := LSelectionBeginPosition;
        LEmptyEndPosition := GetPosition(LSelectionBeginPosition.Char + 1, LSelectionEndPosition.Line);
        LIndex := 0;

        while LIndex < LEmptyEndPosition.Line - LEmptyBeginPosition.Line do
        begin
          LEmptyText := ' ' + FLines.DefaultLineBreak;
          Inc(LIndex);
        end;

        LEmptyText := LEmptyText + ' ';
        Inc(LSelectionEndPosition.Char);
        SelectionBeginPosition := LSelectionBeginPosition;
        SelectionEndPosition := LSelectionEndPosition;
        LUndoText := SelectedText;
        AddUndoDelete(TextPosition, LSelectionBeginPosition, LSelectionEndPosition, LUndoText, smColumn);
        Inc(LSelectionBeginPosition.Char);
      end;
  end;

  AddUndoInsert(TextPosition, LEmptyBeginPosition, LEmptyEndPosition, '', smColumn);
  InsertBlock(LEmptyBeginPosition, LEmptyEndPosition, PChar(LEmptyText), False);

  AddUndoInsert(TextPosition, LSelectionBeginPosition, LSelectionEndPosition, '', smColumn);
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
  if FLines.Updating then
    Exit;

  FCodeFoldings.AllRanges.ClearAll;

  SetLength(FCodeFoldings.TreeLine, 0);
  SetLength(FCodeFoldings.RangeFromLine, 0);
  SetLength(FCodeFoldings.RangeToLine, 0);
end;

procedure TCustomTextEditor.ClearHighlightLine;
var
  LIndex: Integer;
begin
  if Assigned(FHighlightLine) then
  for LIndex := FHighlightLine.Items.Count - 1 downto 0 do
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
    FPosition.SelectionEnd := FPosition.SelectionBegin
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

  FPosition.SelectionEnd := FPosition.SelectionBegin;

  Invalidate;
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

    if Assigned(LCodeFoldingRange) and not LCodeFoldingRange.Collapsed and LCodeFoldingRange.Collapsable then
    begin
      LCodeFoldingRange.Collapsed := True;
      LCodeFoldingRange.SetParentCollapsedOfSubCodeFoldingRanges(True, LCodeFoldingRange.FoldRangeLevel);
    end;
  end;

  CheckIfAtMatchingKeywords;
  UpdateScrollBars;
  EnsureCaretPositionInsideLines(LTextPosition);
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
      begin
        LCodeFoldingRange.Collapsed := True;
        LCodeFoldingRange.SetParentCollapsedOfSubCodeFoldingRanges(True, LCodeFoldingRange.FoldRangeLevel);
      end;
    end;
  end;

  CheckIfAtMatchingKeywords;
  UpdateScrollBars;
  EnsureCaretPositionInsideLines(LTextPosition);
end;

procedure TCustomTextEditor.TrimText(const ATrimStyle: TTextEditorTrimStyle);
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
  if FLines[0].Trim.IsEmpty then
    FLines.Delete(0)
end;

procedure TCustomTextEditor.TrimEnd;
var
  LIndex: Integer;
begin
  for LIndex := FLines.Count - 1 downto 0 do
  if FLines[LIndex].Trim.IsEmpty then
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

  if Length(FCodeFoldings.RangeFromLine) > 0 then
  for LIndex := LFromLine to LToLine do
  begin
    LCodeFoldingRange := FCodeFoldings.RangeFromLine[LIndex];

    if Assigned(LCodeFoldingRange) then
      if LCodeFoldingRange.Collapsed and LCodeFoldingRange.Collapsable then
      begin
        LCodeFoldingRange.Collapsed := False;
        LCodeFoldingRange.SetParentCollapsedOfSubCodeFoldingRanges(False, LCodeFoldingRange.FoldRangeLevel);
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

  if Length(FCodeFoldings.RangeFromLine) > 0 then
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
      begin
        LCodeFoldingRange.Collapsed := False;
        LCodeFoldingRange.SetParentCollapsedOfSubCodeFoldingRanges(False, LCodeFoldingRange.FoldRangeLevel);
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
  LTextPosition: TTextEditorTextPosition;
  LPMultiCaretRecord: PTextEditorMultiCaretRecord;
  LCommand: TTextEditorCommand;
  LChar: Char;
  LRows, LPasteRows, LLength: Integer;
  LLineSelectionStart, LLineSelectionEnd: Integer;
  LStringList: TStringList;
  LSelectionAvailable: Boolean;
  LBackspaceCount, LSpaceCount: Integer;
  LLineText: string;

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
  LSelectionAvailable := False;
  LBackspaceCount := 1;

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

            FPosition.SelectionBegin := LOldSelectionBeginPosition;
            FPosition.SelectionEnd := LOldSelectionEndPosition;

            if LCollapsedCount <> 0 then
            begin
              Inc(FPosition.SelectionEnd.Line, LCollapsedCount);
              FPosition.SelectionEnd.Char := Length(FLines[FPosition.SelectionEnd.Line]) + 1;
            end;
          end
          else
            CodeFoldingExpandLine(FPosition.Text.Line + 1);
      end;
    end;

    if Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) then
    begin
      FUndoList.BeginBlock(8);

      LPMultiCaretRecord := PTextEditorMultiCaretRecord(FMultiEdit.Carets[0]);
      LTextPosition := ViewToTextPosition(LPMultiCaretRecord^.ViewPosition);

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
            if FMultiEdit.SelectionAvailable then
              LLength := 0
            else
              LLength := 1;

            LRows := 0;

            if (LCommand = TKeyCommands.Paste) and CanPaste then
            begin
              LStringList := TStringList.Create;
              try
                LStringList.Text := GetClipboardText;

                if not Trim(LStringList.Text).IsEmpty then
                begin
                  LRows := LStringList.Count - 1;
                  LLength := Length(LStringList[LStringList.Count - 1]);
                end;
              finally
                LStringList.Free;
              end;
            end;

            LPasteRows := LRows;

            if (LCommand in [TKeyCommands.SelectionLeft, TKeyCommands.SelectionRight, TKeyCommands.SelectionLineBegin,
              TKeyCommands.SelectionLineEnd]) and
              not FMultiEdit.SelectionAvailable then
            begin
              FMultiEdit.SelectionAvailable := True;

              for LIndex1 := 0 to FMultiEdit.Carets.Count - 1 do
              begin
                LPMultiCaretRecord := PTextEditorMultiCaretRecord(FMultiEdit.Carets[LIndex1]);

                LTextPosition := ViewToTextPosition(LPMultiCaretRecord^.ViewPosition);

                LPMultiCaretRecord^.SelectionBegin.Char := LTextPosition.Char;
                LPMultiCaretRecord^.SelectionBegin.Line := LTextPosition.Line;
              end;
            end
            else
            if LCommand in [TKeyCommands.Left, TKeyCommands.Right] then
              FMultiEdit.SelectionAvailable := False;

            for LIndex1 := FMultiEdit.Carets.Count - 1 downto 0 do
            case LCommand of
              TKeyCommands.Char, TKeyCommands.Cut, TKeyCommands.Tab, TKeyCommands.Backspace, TKeyCommands.Paste:
                begin
                  LPMultiCaretRecord := PTextEditorMultiCaretRecord(FMultiEdit.Carets[LIndex1]);
                  LViewPosition := LPMultiCaretRecord^.ViewPosition;
                  ViewPosition := LViewPosition;
                  LBackspaceCount := LViewPosition.Column;

                  if LCommand = TKeyCommands.Tab then
                  begin
                    LTextPosition := ViewToTextPosition(LPMultiCaretRecord^.ViewPosition);
                    LLength := Length(GetTabText(LTextPosition));
                  end;

                  ExecuteCommand(LCommand, LChar, AData);

                  Dec(LBackspaceCount, ViewPosition.Column);
                  LSelectionAvailable := FMultiEdit.SelectionAvailable;

                  if FMultiEdit.SelectionAvailable then
                  begin
                    for LIndex2 := FMultiEdit.Carets.Count - 1 downto 0 do
                    begin
                      LPMultiCaretRecord := PTextEditorMultiCaretRecord(FMultiEdit.Carets[LIndex2]);

                      LLineSelectionStart := LPMultiCaretRecord^.SelectionBegin.Char;
                      LLineSelectionEnd := LPMultiCaretRecord^.ViewPosition.Column;

                      if LLineSelectionStart > LLineSelectionEnd then
                        SwapInt(LLineSelectionStart, LLineSelectionEnd);

                      LPMultiCaretRecord^.ViewPosition := GetViewPosition(LLineSelectionStart, LPMultiCaretRecord^.ViewPosition.Row);

                      case LCommand of
                        TKeyCommands.Paste:
                          Inc(LPMultiCaretRecord^.ViewPosition.Column, LLength);
                        TKeyCommands.Char, TKeyCommands.Tab:
                          Inc(LPMultiCaretRecord^.ViewPosition.Column);
                      end;
                    end;

                    FMultiEdit.SelectionAvailable := False;
                    Break;
                  end;
                end;
              TKeyCommands.Right, TKeyCommands.SelectionRight:
                begin
                  LPMultiCaretRecord := PTextEditorMultiCaretRecord(FMultiEdit.Carets[LIndex1]);
                  Inc(LPMultiCaretRecord^.ViewPosition.Column);
                end;
              TKeyCommands.Left, TKeyCommands.SelectionLeft:
                begin
                  LPMultiCaretRecord := PTextEditorMultiCaretRecord(FMultiEdit.Carets[LIndex1]);

                  if LPMultiCaretRecord^.ViewPosition.Column > 1 then
                    Dec(LPMultiCaretRecord^.ViewPosition.Column);
                end;
            end;

            if FMultiEdit.Carets.Count > 0 then
            case LCommand of
              TKeyCommands.Char, TKeyCommands.Paste, TKeyCommands.Backspace, TKeyCommands.Tab, TKeyCommands.LineBegin,
              TKeyCommands.LineEnd, TKeyCommands.SelectionLineBegin, TKeyCommands.SelectionLineEnd:
                begin
                  for LIndex2 := 0 to FMultiEdit.Carets.Count - 1 do
                  begin
                    LPMultiCaretRecord := PTextEditorMultiCaretRecord(FMultiEdit.Carets[LIndex2]);

                    case LCommand of
                      TKeyCommands.Char, TKeyCommands.Tab, TKeyCommands.Paste, TKeyCommands.Backspace:
                        case LCommand of
                          TKeyCommands.Char, TKeyCommands.Tab:
                            Inc(LPMultiCaretRecord^.ViewPosition.Column, LLength);
                          TKeyCommands.Backspace:
                            if not LSelectionAvailable and (LPMultiCaretRecord^.ViewPosition.Column > 1) then
                              Dec(LPMultiCaretRecord^.ViewPosition.Column, LBackspaceCount);
                          TKeyCommands.Paste:
                            begin
                              LPMultiCaretRecord^.ViewPosition.Column := LLength + 1;
                              Inc(LPMultiCaretRecord^.ViewPosition.Row, LRows);
                              Inc(LRows, LPasteRows);
                            end;
                        end;
                      TKeyCommands.LineBegin:
                        begin
                          LTextPosition := ViewToTextPosition(LPMultiCaretRecord^.ViewPosition);
                          LLineText := FLines[LTextPosition.Line];
                          LSpaceCount := LeftSpaceCount(LLineText) + 1;

                          if LTextPosition.Char <= LSpaceCount then
                            LSpaceCount := 1;

                          LPMultiCaretRecord^.ViewPosition.Column := LSpaceCount;
                        end;
                      TKeyCommands.SelectionLineBegin:
                        LPMultiCaretRecord^.ViewPosition.Column := 1;
                      TKeyCommands.LineEnd, TKeyCommands.SelectionLineEnd:
                        LPMultiCaretRecord^.ViewPosition.Column := FLines.ExpandedStringLengths[LPMultiCaretRecord^.ViewPosition.Row - 1] + 1;
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
          end;
      end;

      FUndoList.EndBlock;
      ValidateMultiCarets;
      Invalidate;
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
    TKeyCommands.LowerCaseBlock, TKeyCommands.AlternatingCaseBlock, TKeyCommands.MoveLineUp, TKeyCommands.MoveLineDown,
    TKeyCommands.LineComment, TKeyCommands.BlockComment:
      DoChange;
  end;
end;

function TCustomTextEditor.GetMultiCaretSelectedText: string;
var
  LIndex: Integer;
  LPMultiCaretRecord: PTextEditorMultiCaretRecord;
  LLine, LChar, LLastLine: Integer;
begin
  Result := '';

  if Assigned(FMultiEdit.Carets) and FMultiEdit.SelectionAvailable and (FMultiEdit.Carets.Count > 0) then
  begin
    LLastLine := -1;
    LIndex := 0;

    while LIndex < FMultiEdit.Carets.Count do
    begin
      LPMultiCaretRecord := PTextEditorMultiCaretRecord(FMultiEdit.Carets[LIndex]);

      LLine := LPMultiCaretRecord^.SelectionBegin.Line;
      LChar := LPMultiCaretRecord^.SelectionBegin.Char;

      if LLastLine = -1 then
        LLastLine := LLine
      else
      if LLastLine <> LLine then
      begin
        Result := Result + sLineBreak;
        LLastLine := LLine;
      end;

      Result := Result + Copy(FLines[LLine], LChar, Abs(LChar - LPMultiCaretRecord^.ViewPosition.Column));

      Inc(LIndex);
    end;
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
    if Assigned(ACodeFoldingRange) and ACodeFoldingRange.Collapsed then
      FPosition.SelectionEnd := ViewToTextPosition(GetViewPosition(1, SelectionEndPosition.Line + 2));
  end;

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

        LSelectionEndPosition := FPosition.SelectionEnd;
      end;

      if (LSelectionBeginPosition.Line = 0) and (LSelectionBeginPosition.Char = 1) and
        (LSelectionEndPosition.Line = FLines.Count - 1) and (LSelectionEndPosition.Char = Length(FLines[LSelectionEndPosition.Line]) + 1) then
        LText := FLines.Text
      else
        LText := SelectedText;

      LText := StringReplace(LText, TControlCharacters.Substitute, TControlCharacters.Null, [rfReplaceAll]);

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

      FPosition.SelectionBegin := LSelectionBeginPosition;
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
    FPosition.SelectionBegin := GetPosition(1, ALineNumber - 1);
    FPosition.SelectionEnd := GetPosition(1, ALineNumber + ACount - 1);
  end
  else
  begin
    FPosition.SelectionBegin := GetPosition(FLines.StringLength(ALineNumber - 2) + 1, ALineNumber - 2);
    FPosition.SelectionEnd := GetPosition(FLines.StringLength(FLines.Count - 1) + 1, FLines.Count - 1);
  end;

  BeginUpdate;
  SetSelectedTextEmpty;
  EndUpdate;
end;

procedure TCustomTextEditor.DeleteWhitespace;
begin
  if ReadOnly then
    Exit;

  FUndoList.BeginBlock;
  try
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
            begin
              LNewCaretPosition.Line := LNewCaretPosition.Line - LLinesDeleted;

              if LSelectionBeginPosition.Line = LSelectionEndPosition.Line then
                LNewCaretPosition.Char := LNewCaretPosition.Char - LDragDropText.Length;
            end;
          end;

          LChangeScrollPastEndOfLine := not (soPastEndOfLine in FScroll.Options);
          try
            if LChangeScrollPastEndOfLine then
              FScroll.SetOption(soPastEndOfLine, True);

            TextPosition := LNewCaretPosition;

            DoInsertText(LDragDropText);

            FPosition.SelectionBegin := LNewCaretPosition;

            if LSelectionBeginPosition.Line = LSelectionEndPosition.Line then
              FPosition.SelectionEnd.Char := LNewCaretPosition.Char + LSelectionEndPosition.Char - LSelectionBeginPosition.Char
            else
              FPosition.SelectionEnd.Char := LSelectionEndPosition.Char;

            FPosition.SelectionEnd.Line := LNewCaretPosition.Line + LSelectionEndPosition.Line - LSelectionBeginPosition.Line;
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

  if not FLines.Updating then
  begin
    if FSyncEdit.Visible then
      DoSyncEdit;

    if FHighlighter.Loaded then
      RescanHighlighterRanges;

    InitCodeFolding;
    EnsureCursorPositionVisible;
    ScanMatchingPair;
    SearchAll;

    DoChange;

    Invalidate;
  end;
end;

procedure TCustomTextEditor.EnsureCursorPositionVisible(const AForceToMiddle: Boolean = False; const AEvenIfVisible: Boolean = False);
var
  LMiddle: Integer;
  LCaretRow: Integer;
  LPoint: TPoint;
  LLeftMarginWidth: Integer;
begin
  if (FScrollHelper.PageWidth <= 0) or not HandleAllocated then
    Exit;

  IncPaintLock;
  try
    LPoint := ViewPositionToPixels(ViewPosition);
    LLeftMarginWidth := GetLeftMarginWidth;
    FScrollHelper.PageWidth := GetScrollPageWidth;

    LCaretRow := FViewPosition.Row;

    if AForceToMiddle then
    begin
      if LCaretRow < TopLine - 1 then
      begin
        LMiddle := FLineNumbers.VisibleCount shr 1;

        if LCaretRow - LMiddle < 0 then
          TopLine := 1
        else
          TopLine := LCaretRow - LMiddle + 1;
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
    TKeyCommands.DeleteWord, TKeyCommands.DeleteWhitespaceBackward, TKeyCommands.DeleteWhitespaceForward,
      TKeyCommands.DeleteWordBackward, TKeyCommands.DeleteWordForward, TKeyCommands.DeleteBeginningOfLine,
      TKeyCommands.DeleteEndOfLine:
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

  Invalidate;
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

    GoToLineAndSetPosition(LTextPosition.Line, LTextPosition.Char);

    FPosition.SelectionBegin := TextPosition;
    FPosition.SelectionEnd := FPosition.SelectionBegin;

    Invalidate;
  end;
end;

procedure TCustomTextEditor.GoToLine(const ALine: Integer);
var
  LTextPosition: TTextEditorTextPosition;
begin
  LTextPosition := GetPosition(1, ALine - 1);
  SetTextPosition(LTextPosition);
  FPosition.SelectionBegin := LTextPosition;
  FPosition.SelectionEnd := FPosition.SelectionBegin;

  Invalidate;
end;

procedure TCustomTextEditor.GoToLineAndSetPosition(const ALine: Integer; const AChar: Integer = 1; const AResultPosition: TTextEditorResultPosition = rpMiddle);
var
  LIndex: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
  LTextPosition: TTextEditorTextPosition;
  LViewPosition: TTextEditorViewPosition;
begin
  if FCodeFolding.Visible then
  for LIndex := 0 to FCodeFoldings.AllRanges.AllCount - 1 do
  begin
    LCodeFoldingRange := FCodeFoldings.AllRanges[LIndex];

    if LCodeFoldingRange.FromLine > ALine then
      Break
    else
    if LCodeFoldingRange.Collapsed and (LCodeFoldingRange.FromLine <= ALine) then
      CodeFoldingExpand(LCodeFoldingRange);
  end;

  LTextPosition := GetPosition(AChar, ALine);
  SetTextPosition(LTextPosition);

  LViewPosition := TextToViewPosition(LTextPosition);

  if FLineNumbers.VisibleCount = 0 then
  begin
    FLineNumbers.VisibleCount := ClientHeight div GetLineHeight;

    if FRuler.Visible then
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

  FPosition.SelectionBegin := LTextPosition;
  FPosition.SelectionEnd := FPosition.SelectionBegin;

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
  BeginUpdate;

  LLineNumber := ALineNumber;

  if LLineNumber > FLines.Count + 1 then
    LLineNumber := FLines.Count + 1;

  FUndoList.BeginBlock;
  FUndoList.AddChange(crCaret, TextPosition, SelectionBeginPosition, SelectionEndPosition, '', smNormal);

  LTextPosition.Char := 1;
  LTextPosition.Line := LLineNumber - 1;

  FLines.Insert(LTextPosition.Line, AValue);

  if LLineNumber < FLines.Count then
    LTextEndPosition := GetPosition(1, LTextPosition.Line + 1)
  else
  begin
    LTextEndPosition := GetPosition(Length(AValue) + 1, LTextPosition.Line);
    LTextPosition := GetPosition(FLines.StringLength(LTextPosition.Line - 1) + 1, LTextPosition.Line - 1);
  end;

  AddUndoInsert(LTextPosition, LTextPosition, LTextEndPosition, '', smNormal);

  FUndoList.EndBlock;

  EndUpdate;
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

    if not SelectionAvailable then
      GetCharAtTextPosition(ATextPosition, True);

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
      LIndex := 0;

      while LIndex < SelectionBeginPosition.Char do
      begin
        if LPLineText^ = TControlCharacters.Tab then
          Inc(LCharCount, Tabs.Width)
        else
          Inc(LCharCount);

        if LPLineText^ <> TControlCharacters.Null then
          Inc(LPLineText);

        Inc(LIndex);
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
        LSnippetPosition := GetPosition(LBeginChar + AItem.Position.Column - 1, SelectionBeginPosition.Line +
          AItem.Position.Row - 1);
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

procedure TCustomTextEditor.InsertBlock(const ABlockBeginPosition, ABlockEndPosition: TTextEditorTextPosition;
  const AChangeStr: PChar; const AAddToUndoList: Boolean);
var
  LSelectionMode: TTextEditorSelectionMode;
begin
  LSelectionMode := FSelection.ActiveMode;
  SetTextPositionAndSelection(ABlockBeginPosition, ABlockBeginPosition, ABlockEndPosition);
  FSelection.ActiveMode := smColumn;
  DoSelectedText(smColumn, AChangeStr, AAddToUndoList, TextPosition);
  FSelection.ActiveMode := LSelectionMode;
end;

procedure TCustomTextEditor.LeftMarginChanged(ASender: TObject); //FI:O804 Method parameter is declared but never used
begin
  if not (csLoading in ComponentState) and not FHighlighter.Loading then
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
  ResetCharacterCount;

  try
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
    end;

    FLines.TrailingLineBreak := eoTrailingLineBreak in FOptions;
    FLines.LoadFromStream(AStream, AEncoding);

    if FLines.Count = 0 then
      FLines.Add(EmptyStr);

    if not Assigned(Parent) then
      Exit;

    InitCodeFolding;

    { TODO: Word wrap is too slow for large files. Optimize. }
    if LWordWrapEnabled and not FLines.ShowProgress then
      FWordWrap.Active := LWordWrapEnabled;

    SizeOrFontChanged;

    if Assigned(FHighlighter.BeforePrepare) then
      FHighlighter.SetOption(hoExecuteBeforePrepare, True);

    FFile.Loaded := True;
  finally
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
  BeginUpdate;

  LTextPosition := GetPosition(1, ALineNumber - 1);
  LLineBreak := '';

  if sfEmptyLine in AFlags then
    LLineBreak := FLines.DefaultLineBreak;

  AddUndoPaste(LTextPosition, GetPosition(1, ALineNumber - 1), GetPosition(Length(AValue) + 1, ALineNumber - 1),
    FLines.Strings[ALineNumber - 1] + LLineBreak, FSelection.ActiveMode);

  FLines.Strings[ALineNumber - 1] := AValue;

  if sfEmptyLine in AFlags then
    FLines.IncludeFlag(ALineNumber - 1, sfEmptyLine)
  else
    FLines.ExcludeFlag(ALineNumber - 1, sfEmptyLine);

  EndUpdate;
end;

procedure TCustomTextEditor.RescanCodeFoldingRanges;
var
  LIndex: Integer;
  LCodeFoldingRange: TTextEditorCodeFoldingRange;
  LLengthCodeFoldingRangeFromLine, LLengthCodeFoldingRangeToLine: Integer;
begin
  if not FCodeFolding.Visible then
    Exit;

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

procedure TCustomTextEditor.ResetCharacterCount;
begin
  FCharacterCount.Calculate := True;
  FCharacterCount.Value := 0;
end;

function TCustomTextEditor.SaveToFile(const AFilename: string; const AEncoding: System.SysUtils.TEncoding = nil): Boolean;
var
  LFileStream: TFileStream;
  LCancel: Boolean;
  LEncoding: System.SysUtils.TEncoding;
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
  begin
    if FSelection.Mode = smNormal then
      Inc(LLastTextPosition.Char, Length(FLines[LLastTextPosition.Line]))
    else
      Inc(LLastTextPosition.Char, FLines.GetLengthOfLongestLine);
  end;

  SetTextPositionAndSelection(LOldCaretPosition, GetBOFPosition, LLastTextPosition);
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
      FEvents.OnAfterBookmarkPlaced(Self, AIndex, AImageIndex, ATextPosition);
  end;
end;

procedure SetClipboardBuffer(const AFormat: UINT; var ABuffer; const ASize: NativeInt);
var
  LDataPtr: Pointer;
  LData: THandle;
begin
  LData := GlobalAlloc(GMEM_MOVEABLE or GMEM_DDESHARE, ASize);
  try
    LDataPtr := GlobalLock(LData);
    try
      Move(ABuffer, LDataPtr^, ASize);

      if SetClipboardData(AFormat, LData) = 0 then
        raise EOutOfResources.CreateRes(@STextEditorOutOfResources);
    finally
      GlobalUnlock(LData);
    end;
  except
    GlobalFree(LData);
    raise;
  end;
end;

procedure TCustomTextEditor.SetClipboardText(const AText: string; const AHTML: string);
var
  LHTML: UTF8String;
  LLength: Integer;
  LText: string;
begin
  if AText.IsEmpty then
    Exit;

  if OpenClipboard then
  try
    Clipboard.Clear;

    LText := StringReplace(AText, TControlCharacters.Null, '', [rfReplaceAll]);
    LLength := Length(LText);

    { Set ANSI text only on Win9X, WinNT automatically creates ANSI from Unicode }
    if Win32Platform <> VER_PLATFORM_WIN32_NT then
      SetClipboardBuffer(CF_TEXT, PAnsiChar(AnsiString(LText))^, LLength + 1);

    { Set unicode text, this also works on Win9X, even if the clipboard-viewer
      can't show it, Word 2000+ can paste it including the unicode only characters }
    SetClipboardBuffer(CF_UNICODETEXT, PChar(LText)^, (LLength + 1) * SizeOf(Char));

    if not AHTML.IsEmpty then
    begin
      LHTML := FormatForClipboard(AHTML) + #0;

      SetClipboardBuffer(GetHTMLClipboardFormat, PAnsiChar(LHTML)^, Length(LHTML));
    end;
  finally
    Clipboard.Close;
  end;
end;

procedure TCustomTextEditor.SetTextPositionAndSelection(const ATextPosition, ABlockBeginPosition, ABlockEndPosition: TTextEditorTextPosition);
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
  LBeginPosition, LEndPosition: TTextEditorTextPosition;
  LText: string;
  LSelectionAvailable: Boolean;
  LTextPosition, LTempTextPosition: TTextEditorTextPosition;
  LLines: TTextEditorLines;
  LIndex: Integer;
begin
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
      LTempTextPosition := GetSelectionBeginPosition;
      LTempTextPosition.Char := 1;
      SelectionBeginPosition := LTempTextPosition;
      SelectionEndPosition := LEndPosition;
    end;
  end;

  FUndoList.EndBlock;

  for LIndex := LBeginPosition.Line to LEndPosition.Line do
    FLines.LineState[LIndex] := lsModified;

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

  BeginUpdate;

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

  AddUndoInsert(LTextPosition, LBeginPosition, LEndPosition, '', FSelection.ActiveMode);

  MoveCaretToBeginning;
  FUndoList.EndBlock;

  DoChange;

  EndUpdate;
end;

procedure TCustomTextEditor.DeleteEmptyLines;
var
  LIndex: Integer;
  LTextPosition: TTextEditorTextPosition;
begin
  if ReadOnly then
    Exit;

  BeginUpdate;

  FUndoList.BeginBlock;

  LTextPosition := TextPosition;
  FUndoList.AddChange(crCaret, LTextPosition, LTextPosition, LTextPosition, '', smNormal);

  LTextPosition.Char := 1;

  for LIndex := FLines.Count - 1 downto 0 do
  if Trim(FLines[LIndex]).IsEmpty then
  begin
    FLines.Delete(LIndex);
    LTextPosition.Line := LIndex;

    FUndoList.AddChange(crDelete, LTextPosition, LTextPosition, LTextPosition, FLines.GetLineBreak(LIndex), smNormal);
  end;

  FUndoList.EndBlock;

  EndUpdate;
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

  if AnsiUpperCase(SelectedText) <> AnsiUpperCase(FToggleCase.Text) then
  begin
    FToggleCase.Cycle := cUpper;
    FToggleCase.Text := SelectedText;
  end;

  if ACase <> cNone then
    FToggleCase.Cycle := ACase;

  LSelectionStart := SelectionBeginPosition;
  LSelectionEnd := SelectionEndPosition;
  LCommand := TKeyCommands.None;

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
    cKeywordsUpper:
      LCommand := TKeyCommands.KeywordsUpperCase;
    cKeywordsLower:
      LCommand := TKeyCommands.KeywordsLowerCase;
    cKeywordsTitle:
      LCommand := TKeyCommands.KeywordsTitleCase;
  end;

  if FToggleCase.Cycle <> cOriginal then
    CommandProcessor(LCommand, TControlCharacters.Null, nil);

  SelectionBeginPosition := LSelectionStart;
  SelectionEndPosition := LSelectionEnd;

  Inc(FToggleCase.Cycle);

  if FToggleCase.Cycle > cOriginal then
    FToggleCase.Cycle := cUpper;

  EndUpdate;
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
  if Assigned(FMultiEdit.Carets) and (FMultiEdit.Carets.Count > 0) then
    HideCaret
  else
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

    case AMessage.Msg of
      WM_IME_NOTIFY:
        if Assigned(FCompletionProposalPopupWindow) then
          SetCompletionProposalPopupWindowLocation;
      WM_SIZE:
        Invalidate;
    end;

{$IFDEF ALPHASKINS}
    case AMessage.Msg of
      CM_SHOWINGCHANGED:
        RefreshEditScrolls(SkinData, FScrollHelper.Wnd);
      CM_VISIBLECHANGED, CM_ENABLEDCHANGED, WM_SETFONT:
        FSkinData.Invalidate;
    end;
  end;

  if Assigned(FBoundLabel) then
    FBoundLabel.HandleOwnerMsg(AMessage, Self);
{$ENDIF}
end;

procedure TCustomTextEditor.Zoom(const APercentage: Integer);
var
  LPixelsPerInch: Integer;
  LMultiplier: Integer;
begin
  FZoom.Percentage := APercentage;

  IncPaintLock;
  try
    LPixelsPerInch := {$IFDEF ALPHASKINS}GetPPI(SkinData){$ELSE}Screen.PixelsPerInch{$ENDIF};

    if FZoom.Divider = 0 then
      FZoom.Divider := LPixelsPerInch;

    LMultiplier := Round((FZoom.Percentage / 100) * LPixelsPerInch);

    FZoom.Return := True;
    ChangeObjectScale(LPixelsPerInch, FZoom.Divider{$IF CompilerVersion >= 35}, True{$ENDIF});
    FZoom.Return := False;

    ChangeObjectScale(LMultiplier, LPixelsPerInch{$IF CompilerVersion >= 35}, True{$ENDIF});

    FZoom.Divider := LMultiplier;
  finally
    DecPaintLock;
  end;
end;

procedure TCustomTextEditor.SetFullFilename(const AName: string);
begin
  FFile.FullName := AName;
  FFile.Path := ExtractFilePath(AName);
  FFile.Name := ExtractFilename(AName);
end;

procedure TCustomTextEditor.SetHighlightLine(const AValue: TTextEditorHighlightLine);
begin
  FHighlightLine.Assign(AValue);
end;

procedure TCustomTextEditor.GoToOriginalLineAndSetPosition(const ALine: Integer; const AChar: Integer;
  const AText: string = ''; const AResultPosition: TTextEditorResultPosition = rpMiddle);
var
  LLine: Integer;

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

  if ASelected then
    LPText := PChar(SelectedText)
  else
    LPText := PChar(Text);

  while LPText^ <> TControlCharacters.Null do
  begin
    while (LPText^ <> TControlCharacters.Null) and ((LPText^ < TCharacters.ExclamationMark) or IsWordBreakChar(LPText^)) do
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
  LPText: PChar;
begin
  if FCharacterCount.Calculate or ASelected then
  begin
    Result := 0;

    if ASelected then
      LPText := PChar(SelectedText)
    else
      LPText := PChar(FLines.Text);

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
  if not ReadOnly and FDataLink.CanModify then
    SetEditing(True);

  inherited;
end;

procedure TCustomDBTextEditor.CMExit(var AMessage: TCMExit);
begin
  if not ReadOnly and FDataLink.CanModify then
  begin
    try
      FDataLink.UpdateRecord;
    except
      SetFocus;
      raise;
    end;

    SetEditing(False);
  end;

  inherited;
end;

procedure TCustomDBTextEditor.CMGetDataLink(var AMessage: TMessage);
begin
  AMessage.Result := Winapi.Windows.LRESULT(FDataLink);
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
      LoadBlob
    else
      Text := FDataLink.Field.Text;

    if Assigned(FLoadData) then
      FLoadData(Self);
  end
  else
  if csDesigning in ComponentState then
    Text := Name
  else
    Text := '';
end;

procedure TCustomDBTextEditor.DragDrop(ASource: TObject; X, Y: Integer);
begin
  FDataLink.Edit;

  inherited;
end;

procedure TCustomDBTextEditor.EditingChange(Sender: TObject);
begin
  if FDataLink.Editing and Assigned(FDataLink.DataSource) and (FDataLink.DataSource.State <> dsInsert) then
    FBeginEdit := True;
end;

procedure TCustomDBTextEditor.ExecuteCommand(const ACommand: TTextEditorCommand; const AChar: Char; const AData: Pointer);
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

procedure TCustomDBTextEditor.LoadBlob;
var
  LStream: TStream;
begin
  LStream := FDataLink.DataSet.CreateBlobStream(FDataLink.Field, bmRead);
  try
    LoadFromStream(LStream, Lines.Encoding);
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
  if not FDataLink.CanModify then
    Exit;

  FDataLink.Edit;

  if FDataLink.Field.IsBlob then
  begin
    LBlobField := FDataLink.Field as TBlobField;

    LStream := TMemoryStream.Create;
    try
      SaveToStream(LStream, Lines.Encoding);

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
