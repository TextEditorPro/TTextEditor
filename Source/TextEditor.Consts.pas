{$WARN WIDECHAR_REDUCED OFF} // CharInSet is slow in loops
unit TextEditor.Consts;

interface

uses
  System.UITypes;

type
  TTextEditorCharSet = set of AnsiChar;

  TCharacterSets = record
  const
    AbsoluteDelimiters: TTextEditorCharSet = [#0, #9, #10, #13, #32, #26];
    LowerCharacters = ['a'..'z'];
    UpperCharacters = ['A'..'Z'];
    Characters = LowerCharacters + UpperCharacters;
    DefaultDelimiters = ['''', '-', '!', '"', '#', '$', '%', '&', '(', ')', '*', ',', '.', '/', ':', ';', '?', '@', '[',
      '\', ']', '^', '`', '{', '|', '}', '~', '+', '<', '=', '>'];
    DefaultSelectionPrefix = '$%:@';
    DefaultCompletionProposalCloseChars = '()[]. ';
    Numbers = ['0'..'9'];
    RealNumbers = Numbers + ['.', 'e', 'E'];
    ValidFoldingWord = Numbers + Characters + ['@', '\', '_'];
    ValidKeyword = UpperCharacters + Numbers;
    WordBreak = DefaultDelimiters + [' ', '´', '§', '°'];
    CharactersAndNumbers = Characters + Numbers;
  end;

  TCharacters = record
  const
    AnsiCharCount = 256;
    Arrows = [37..40];
    CloseTagOpen = '</';
    CtrlBackspace = #127;
    Dot = '.';
    ExclamationMark = #33;
    Hyphen = '-';
    LineSeparator = Char($2028); // TODO: move to control character
    LowLine = #95;
    NonBreakingSpace = #160;
    ParagraphSeparator = Char($2029); // TODO: move to control character
    Pilcrow = Char($00B6);
    QuestionMark = '?';
    Slash = '/';
    Space = #32;
    TagClose = '>';
    TagOpen = '<';
    ThreeDots = '...';
    Underscore = '_';
    ZeroWidthSpace = Char($200B); // TODO: move to control character
  end;

  TClipboardDefaults = record
  const
    DelayStepMs = 200;
    MaxRetries = 5;
  end;

  TControlCharacterKeys = record
  const
    Backspace = 8;
    CarriageReturn = 13;
    Escape = 27;
  end;

  TControlCharacterNames = record
  const
    Acknowledge = 'ACK';
    Backspace = 'BS';
    Bell = 'BEL';
    Cancel = 'CAN';
    CarriageReturn = 'CR';
    DataLinkEscape = 'DLE';
    DeviceControl1 = 'DC1';
    DeviceControl2 = 'DC2';
    DeviceControl3 = 'DC3';
    DeviceControl4 = 'DC4';
    EndOfMedium = 'EM';
    EndOfText = 'ETX';
    EndOfTransmission = 'EOT';
    EndOfTransmissionBlock = 'ETB';
    Enquiry = 'ENQ';
    Escape = 'ESC';
    FileSeparator = 'FS';
    FormFeed = 'FF';
    GroupSeparator = 'GS';
    LineFeed = 'LF';
    LineSeparator = 'LS';
    NegativeAcknowledge = 'NAK';
    NextLine = 'NEL';
    Null = 'NUL';
    ParagraphSeparator = 'PS';
    RecordSeparator = 'RS';
    ShiftIn = 'SI';
    ShiftOut = 'SO';
    StartOfHeading = 'SOH';
    StartOfText = 'STX';
    SynchronousIdle = 'SYN';
    UnitSeparator = 'US';
    VerticalTab = 'VT';
    ZeroWidthSpace = 'ZWSP';
  end;

  TControlCharacters = record
  const
    Acknowledge = #6;
    Backspace = #8;
    Bell = #7;
    Cancel = #24;
    CarriageReturn = #13;
    CarriageReturnLineFeed = #13#10;
    DataLinkEscape = #16;
    DeviceControl1 = #17;
    DeviceControl2 = #18;
    DeviceControl3 = #19;
    DeviceControl4 = #20;
    EndOfMedium = #25;
    EndOfText = #3;
    EndOfTransmission = #4;
    EndOfTransmissionBlock = #23;
    Enquiry = #5;
    Escape = #27;
    FileSeparator = #28;
    FormFeed = #12;
    GroupSeparator = #29;
    Linefeed = #10;
    NegativeAcknowledge = #21;
    NextLine = #133;
    Null = #0;
    RecordSeparator = #30;
    ShiftIn = #15;
    ShiftOut = #14;
    StartOfHeading = #1;
    StartOfText = #2;
    Substitute = #26; { Used to substitute null characters - null character terminates strings in Delphi. }
    SynchronousIdle = #22;
    Tab = #9;
    UnitSeparator = #31;
    VerticalTab = #11;
    AsSet = [#1..#31] - [CarriageReturn, Linefeed, Null, Substitute, Tab];
  end;

  TDefaultColors = record
  const
    ActiveLineBackground = $00E6FAFF;
    ActiveLineBackgroundUnfocused = $00F0F0F0;
    ActiveLineForeground = TColors.SysNone;
    ActiveLineForegroundUnfocused = TColors.SysNone;
    BlockBackground = $00EEFFFF;
    LeftMarginBackground = $00FFFFFF;
    LineNumbers = $00CC9999;
    MatchingPairUnderline = TColors.Black;
    MinimapBookmark = TColors.Green;
    PaleRed = $00E6E6FC;
    Red = $006B6BFF;
    SearchHighlighter = $0078AAFF;
    SearchInSelectionBackground = $00FAFFE6;
    Selection = $00A56D53;
    SelectionUnfocused = $006B6B6B;
    WordWrapIndicatorArrow = TColors.Navy;
    WordWrapIndicatorLines = TColors.Black;
  end;

  THighlighterAttribute = record
  const
    ElementComment = 'Comment';
    ElementString = 'String';
  end;

  TMinValues = record
  const
    FileReadBufferSize = 1024;
    FileShowProgressSize = 1024;
  end;

  TMaxValues = record
  const
    ScrollRange = High(Smallint);
    TextLength = (MaxInt div SizeOf(WideChar)) div 4;
    TokenLength = 128;
  end;

  TMouseWheelScrollCursors = record
  const
    None = -1;
    North = 0;
    NorthEast = 1;
    East = 2;
    SouthEast = 3;
    South = 4;
    SouthWest = 5;
    West = 6;
    NorthWest = 7;
  end;

  TMouseWheel = record
  const
    Divisor = 120;
  end;

  TResourceBitmap = record
  const
    ActiveLine = 'TEXTEDITORACTIVELINE';
    BookmarkImages = 'TEXTEDITORBOOKMARKIMAGES';
    BookmarkImageCount = 14;
    MouseMoveScroll = 'TEXTEDITORMOUSEMOVESCROLL';
    SyncEdit = 'TEXTEDITORSYNCEDIT';
  end;

  TSearchEngine = record
  const
    Normal = 'Normal';
    Extended = 'Extended';
    RegularExpression = 'RegularExpression';
    Wildcard = 'Wildcard';
  end;

  TFontStyleNames = record
  const
    Bold = 'Bold';
    Italic = 'Italic';
    Underline = 'Underline';
    StrikeOut = 'StrikeOut';
  end;

  TBreakType = record
  const
    Any = 'Any';
    Term = 'Term';
  end;

  TRegionType = record
  const
    SingleLine = 'SingleLine';
    MultiLine = 'MultiLine';
    SingleLineString = 'SingleLineString';
  end;

  TSnippetReplaceTags = record
  const
    CurrentWord = '{CurrentWord}';
    SelectedText = '{SelectedText}';
    Text = '{Text}';
  end;

function ControlCharacterToName(const AChar: Char): string; inline;
function IsLineTerminatorCharacter(const AChar: Char): Boolean; inline;

implementation

function ControlCharacterToName(const AChar: Char): string;
begin
  case AChar of
    TControlCharacters.Acknowledge:
      Result := TControlCharacterNames.Acknowledge;
    TControlCharacters.Backspace:
      Result := TControlCharacterNames.Backspace;
    TControlCharacters.Bell:
      Result := TControlCharacterNames.Bell;
    TControlCharacters.Cancel:
      Result := TControlCharacterNames.Cancel;
    TControlCharacters.CarriageReturn:
      Result := TControlCharacterNames.CarriageReturn;
    TControlCharacters.DataLinkEscape:
      Result := TControlCharacterNames.DataLinkEscape;
    TControlCharacters.DeviceControl1:
      Result := TControlCharacterNames.DeviceControl1;
    TControlCharacters.DeviceControl2:
      Result := TControlCharacterNames.DeviceControl2;
    TControlCharacters.DeviceControl3:
      Result := TControlCharacterNames.DeviceControl3;
    TControlCharacters.DeviceControl4:
      Result := TControlCharacterNames.DeviceControl4;
    TControlCharacters.EndOfMedium:
      Result := TControlCharacterNames.EndOfMedium;
    TControlCharacters.EndOfText:
      Result := TControlCharacterNames.EndOfText;
    TControlCharacters.EndOfTransmission:
      Result := TControlCharacterNames.EndOfTransmission;
    TControlCharacters.EndOfTransmissionBlock:
      Result := TControlCharacterNames.EndOfTransmissionBlock;
    TControlCharacters.Enquiry:
      Result := TControlCharacterNames.Enquiry;
    TControlCharacters.Escape:
      Result := TControlCharacterNames.Escape;
    TControlCharacters.FileSeparator:
      Result := TControlCharacterNames.FileSeparator;
    TControlCharacters.FormFeed:
      Result := TControlCharacterNames.FormFeed;
    TControlCharacters.GroupSeparator:
      Result := TControlCharacterNames.GroupSeparator;
    TControlCharacters.LineFeed:
      Result := TControlCharacterNames.LineFeed;
    TCharacters.LineSeparator:
      Result := TControlCharacterNames.LineSeparator;
    TControlCharacters.NegativeAcknowledge:
      Result := TControlCharacterNames.NegativeAcknowledge;
    TControlCharacters.NextLine:
      Result := TControlCharacterNames.NextLine;
    TCharacters.ParagraphSeparator:
      Result := TControlCharacterNames.ParagraphSeparator;
    TControlCharacters.Substitute:
      Result := TControlCharacterNames.Null;
    TControlCharacters.RecordSeparator:
      Result := TControlCharacterNames.RecordSeparator;
    TControlCharacters.ShiftIn:
      Result := TControlCharacterNames.ShiftIn;
    TControlCharacters.ShiftOut:
      Result := TControlCharacterNames.ShiftOut;
    TControlCharacters.StartOfHeading:
      Result := TControlCharacterNames.StartOfHeading;
    TControlCharacters.StartOfText:
      Result := TControlCharacterNames.StartOfText;
    TControlCharacters.SynchronousIdle:
      Result := TControlCharacterNames.SynchronousIdle;
    TControlCharacters.UnitSeparator:
      Result := TControlCharacterNames.UnitSeparator;
    TControlCharacters.VerticalTab:
      Result := TControlCharacterNames.VerticalTab;
    TCharacters.ZeroWidthSpace:
      Result := TControlCharacterNames.ZeroWidthSpace;
  else
    Result := '';
  end;
end;

{ "The Unicode standard defines a number of characters that conforming applications should recognize as line terminators:

  LF:    Line Feed, U+000A
  VT:    Vertical Tab, U+000B
  FF:    Form Feed, U+000C
  CR:    Carriage Return, U+000D
  CR+LF: CR (U+000D) followed by LF (U+000A)
  NEL:   Next Line, U+0085
  LS:    Line Separator, U+2028
  PS:    Paragraph Separator, U+2029

  Recognizing and using the newline codes greater than 0x7F (NEL, LS and PS) is not often done.",
  https://en.wikipedia.org/wiki/Newline }
function IsLineTerminatorCharacter(const AChar: Char): Boolean;
begin
  Result := AChar in [TControlCharacters.CarriageReturn, TControlCharacters.Linefeed];
end;

end.
