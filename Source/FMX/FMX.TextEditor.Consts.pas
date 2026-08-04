{$WARN WIDECHAR_REDUCED OFF} // CharInSet is slow in loops
unit FMX.TextEditor.Consts;

interface

uses
  System.UITypes;

type
  TTextEditorCharSet = set of AnsiChar;

  TCharacterSets = record
  const
    AbsoluteDelimiters: TTextEditorCharSet = [#0, #9, #10, #13, #32, #26, #160];
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
    WordBreak = DefaultDelimiters + [#0..' ', '´', '§', '°'];
    CharactersAndNumbers = Characters + Numbers;
  end;

  TCharacters = record
  const
    ASCIICharHigh = 127;
    ANSICharHigh = 255;
    Arrows = [37..40];
    CloseTagOpen = '</';
    CtrlBackspace = #127;
    Dot = '.';
    ExclamationMark = #33;
    Hyphen = '-';
    LowLine = #95;
    Pilcrow = Char($00B6);
    QuestionMark = '?';
    Slash = '/';
    Space = #32;
    SquareBracketClose = ']';
    SquareBracketOpen = '[';
    TagClose = '>';
    TagOpen = '<';
    ThreeDots = '...';
    Underscore = '_';
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
    NegativeAcknowledge = 'NAK';
    NextLine = 'NEL';
    NonBreakingSpace = 'NBSP';
    Null = 'NUL';
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
    NextLine = Char($0085);
    NonBreakingSpace = Char($00A0);
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
    ZeroWidthSpace = Char($200B);
    AsSet = [#1..#31] - [CarriageReturn, Linefeed, Null, Substitute, Tab];
  end;

  { All colors are TAlphaColor ($AARRGGBB). SysDefault is a sentinel meaning "use the property default" - it
    can never be produced by a real color because visible colors always carry a nonzero alpha. }
  TDefaultColors = record
  const
    SysDefault = TAlphaColor($00000001);
    ActiveLineBackground = TAlphaColor($FFFFFAE6);
    ActiveLineBackgroundUnfocused = TAlphaColor($FFF0F0F0);
    ActiveLineBorder = TAlphaColor($FFB4B4B4);
    ActiveLineForeground = TAlphaColors.Null;
    ActiveLineForegroundUnfocused = TAlphaColors.Null;
    BlockBackground = TAlphaColor($FFFFFFEE);
    BookmarkBlue = TAlphaColor($FF3398FE);
    BookmarkGreen = TAlphaColor($FF66CB66);
    BookmarkPurple = TAlphaColor($FF9898FE);
    BookmarkRed = TAlphaColor($FFF44336);
    BookmarkYellow = TAlphaColor($FFFECB00);
    HintBackground = TAlphaColor($FFFFFFE1); { FMX has no system colors - this is the classic clInfoBk }
    HintText = TAlphaColors.Black;
    LeftMarginBackground = TAlphaColor($FFFFFFFF);
    LineNumbers = TAlphaColor($FF9999CC);
    MatchingPairUnderline = TAlphaColors.Black;
    MinimapBookmark = TAlphaColors.Green;
    PaleRed = TAlphaColor($FFFCE6E6);
    Red = TAlphaColor($FFFF6B6B);
    SearchHighlighter = TAlphaColor($FFFFAA78);
    SearchInSelectionBackground = TAlphaColor($FFE6FFFA);
    Selection = TAlphaColor($FF536DA5);
    SelectionUnfocused = TAlphaColor($FF6B6B6B);
    SysHighlight = TAlphaColor($FF0078D7);
    SysHighlightText = TAlphaColors.White;
    WordWrapIndicatorArrow = TAlphaColors.Navy;
    WordWrapIndicatorLines = TAlphaColors.Black;
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
    ScrollRange = High(SmallInt);
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

const
  sDoubleLineBreak = sLineBreak + sLineBreak;

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
    TControlCharacters.NegativeAcknowledge:
      Result := TControlCharacterNames.NegativeAcknowledge;
    TControlCharacters.NextLine:
      Result := TControlCharacterNames.NextLine;
    TControlCharacters.NonBreakingSpace:
      Result := TControlCharacterNames.NonBreakingSpace;
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
    TControlCharacters.ZeroWidthSpace:
      Result := TControlCharacterNames.ZeroWidthSpace;
  else
    Result := '';
  end;
end;

function IsLineTerminatorCharacter(const AChar: Char): Boolean;
begin
  Result := AChar in [TControlCharacters.CarriageReturn, TControlCharacters.Linefeed];
end;

end.
