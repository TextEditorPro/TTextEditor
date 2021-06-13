unit TextEditor.Consts;

interface

uses
  Vcl.Graphics;

type
  TTextEditorCharSet = set of AnsiChar;

const
  TEXT_EDITOR_BOOKMARK_IMAGE_COUNT = 10;
  TEXT_EDITOR_CLIPBOARD_MAX_RETRIES = 5;
  TEXT_EDITOR_CLIPBOARD_DELAY_STEP_MS = 200;
  TEXT_EDITOR_WHEEL_DIVISOR = 120;
  TEXT_EDITOR_TOKEN_MAX_LENGTH = 128;
  TEXT_EDITOR_ANSI_CHAR_COUNT = 256;
  TEXT_EDITOR_MAX_SCROLL_RANGE = High(Smallint);
  TEXT_EDITOR_MAX_BUFFER_SIZE = 10485760; // = 1024 * 1024 * 10;
  TEXT_EDITOR_MAX_TEXT_LENGTH = (MaxInt div SizeOf(WideChar)) div 4;
  { Characters }
  TEXT_EDITOR_UNDERSCORE = '_';
  TEXT_EDITOR_SLASH = '/';
  TEXT_EDITOR_THREE_DOTS = '...';
  TEXT_EDITOR_CODE_FOLDING_VALID_CHARACTERS = ['\', '@', '_'];
  TEXT_EDITOR_REAL_NUMBER_CHARS = ['0'..'9', 'e', 'E', '.'];
  TEXT_EDITOR_NONE_CHAR = #0;
  TEXT_EDITOR_BACKSPACE_CHAR = #8;
  TEXT_EDITOR_TAB_CHAR = #9;
  TEXT_EDITOR_LINEFEED = #10;
  TEXT_EDITOR_LINEFEED_KEY = 10;
  TEXT_EDITOR_CARRIAGE_RETURN = #13;
  TEXT_EDITOR_CARRIAGE_RETURN_LINEFEED = #13#10;
  TEXT_EDITOR_CARRIAGE_RETURN_KEY = 13;
  TEXT_EDITOR_SUBSTITUTE_CHAR = #26;
  TEXT_EDITOR_ESCAPE = #27;
  TEXT_EDITOR_ESCAPE_KEY = 27;
  TEXT_EDITOR_SPACE_CHAR = #32;
  TEXT_EDITOR_EXCLAMATION_MARK = #33;
  TEXT_EDITOR_LOW_LINE = #95;
  TEXT_EDITOR_CTRL_BACKSPACE = #127;
  TEXT_EDITOR_NON_BREAKING_SPACE_CHAR = #160;
  TEXT_EDITOR_PILCROW_CHAR = Char($00B6);
  TEXT_EDITOR_PILCROW_CR = 'CR';
  TEXT_EDITOR_PILCROW_LF = 'LF';
  TEXT_EDITOR_LINE_SEPARATOR = Char($2028);
  TEXT_EDITOR_WORD_BREAK_CHARACTERS = ['.', ',', ';', ':', '"', '''', '!', '?', '[', ']', '(', ')', '{', '}', '^',
    '=', '+', '-', '*', '/', '\', '|', ' '];
  TEXT_EDITOR_EXTRA_WORD_BREAK_CHARACTERS = ['´', '`', '°', '&', '$', '@', '§', '%', '#', '~', '<', '>'];
  TEXT_EDITOR_DEFAULT_DELIMITERS: TTextEditorCharSet = ['*', '/', '+', '-', '=', '\', '|', '&', '(', ')', '[', ']', '{', '}',
    '`', '~', '!', '@', ',', '$', '%', '^', '?', ':', ';', '''', '"', '.', '>', '<', '#'];
  TEXT_EDITOR_ABSOLUTE_DELIMITERS: TTextEditorCharSet = [TEXT_EDITOR_NONE_CHAR, TEXT_EDITOR_TAB_CHAR, TEXT_EDITOR_LINEFEED,
    TEXT_EDITOR_CARRIAGE_RETURN, TEXT_EDITOR_SPACE_CHAR, TEXT_EDITOR_SUBSTITUTE_CHAR];
  { Encoding }
  TEXT_EDITOR_UTF8_BOM: array [0 .. 2] of Byte = ($EF, $BB, $BF);
  { Highlighter attribute elements }
  TEXT_EDITOR_ATTRIBUTE_ELEMENT_COMMENT = 'Comment';
  // TEXT_EDITOR_ATTRIBUTE_ELEMENT_DIRECTIVE = 'Directive';
  TEXT_EDITOR_ATTRIBUTE_ELEMENT_STRING = 'String';
  { Default colors }
  clSelectionColor = $00A56D53;
  clSearchHighlighter = $0078AAFF;
  clSearchInSelectionBackground = $00FCFDCD;
  clActiveLineBackground = $00E6FAFF;
  clActiveLineForeground = clNone;
  clActiveLineBackgroundUnfocused = $00E6FAFF;
  clActiveLineForegroundUnfocused = clNone;
  clLeftMarginBackground = $00FFFFFF;
  clLeftMarginFontForeground = $00CC9999;
  clSearchMapActiveLine = $00F4F4F4;
  clIndentHighlight = $00CC9999;
  clIndent = $00CC9999;
  clMatchingPairUnderline = $00CC9999;
  clMinimapVisibleLines = $00E6FAFF;
  clMinimapBookmark = clGreen;
  clWordWrapIndicatorArrow = clNavy;
  clWordWrapIndicatorLines = clBlack;
  clSyncEditBackground = $00FCFDCD;
  { Undo }
  TEXT_EDITOR_UNDO_BLOCK_NUMBER_START = 10;
  { Resource file bitmaps }
  TEXT_EDITOR_ACTIVE_LINE = 'TEXTEDITORACTIVELINE';
  TEXT_EDITOR_BOOKMARK_IMAGES = 'TEXTEDITORBOOKMARKIMAGES';
  TEXT_EDITOR_MOUSE_MOVE_SCROLL = 'TEXTEDITORMOUSEMOVESCROLL';
  TEXT_EDITOR_NULL_IMAGE = 'TEXTEDITORNULLIMAGE';
  TEXT_EDITOR_SYNCEDIT = 'TEXTEDITORSYNCEDIT';
  TEXT_EDITOR_NULL_IMAGE_WIDTH = 16;
  { Mouse wheel scroll cursor indexes }
  scNone = -1;
  scNorth = 0;
  scNorthEast = 1;
  scEast = 2;
  scSouthEast = 3;
  scSouth = 4;
  scSouthWest = 5;
  scWest = 6;
  scNorthWest = 7;
  { Replace }
  TEXT_EDITOR_REPLACE_RESULT_CANCEL = -9;
  { Search engine }
  TEXT_EDITOR_SEARCH_ENGINE_NORMAL = 'Normal';
  TEXT_EDITOR_SEARCH_ENGINE_EXTENDED = 'Extended';
  TEXT_EDITOR_SEARCH_ENGINE_REGULAR_EXPRESSION = 'RegularExpression';
  TEXT_EDITOR_SEARCH_ENGINE_WILDCARD = 'Wildcard';

implementation

end.
