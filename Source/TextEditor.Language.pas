unit TextEditor.Language;

{$I TextEditor.Defines.inc}

interface

resourcestring
  { TextEditor }
  STextEditorHighlighterLoadFromFile = 'Load highlighter from file';
  STextEditorRightMarginPosition = 'Position: %d';
  STextEditorScrollInfo = '%d - %d';
  STextEditorScrollInfoTopLine = 'Top line: %d';
  STextEditorSearchEngineNotAssigned = 'Search engine has not been assigned';
  STextEditorSearchMatchNotFound = 'Search match not found.%sRestart search from the beginning of the file?';
  STextEditorSearchStringNotFound = 'Search string ''%s'' not found';
  STextEditorThemeLoadFromFile = 'Load theme from file';
  STextEditorThemeSaveToFile = 'Save theme to file';

  { TextEditor.CompletionProposal }
  STextEditorKeyword = 'Keyword';
  STextEditorSnippet = 'Snippet';
  STextEditorText = 'Text';

  { TextEditor.CompletionProposal.Snippet }
  STextEditorCompletionProposalSnippetItemUnnamed = '(unnamed)';

  { TextEditor.HighlightLine }
  STextEditorHighlightLineItemUnnamed = '(unnamed)';

  { TextEditor.KeyCommands }
  STextEditorDuplicateShortcut = 'Shortcut already exists';

  { TextEditor.MacroRecorder }
  STextEditorCannotPause = 'Can only pause when recording';
  STextEditorCannotPlay = 'Cannot playback macro; already playing or recording';
  STextEditorCannotRecord = 'Cannot record macro; already recording or playing';
  STextEditorCannotResume = 'Can only resume when paused';
  STextEditorMacroNameUnnamed = 'unnamed';
  STextEditorShortcutAlreadyExists = 'Shortcut already exists';

  { TextEditor.Lines }
{$IFDEF TEXTEDITOR_RANGE_CHECKS}
  STextEditorListIndexOutOfBounds = 'Invalid list index %d';
{$ENDIF}
  STextEditorInvalidCapacity = 'List capacity cannot be smaller than count';

  { TextEditor.Highlighter.Import.JSON }
  STextEditorErrorInHighlighterImport = 'Error in highlighter import: %s';
  STextEditorErrorInHighlighterParse = 'JSON parse error on line %d column %d: %s';

  { TextEditor.Search }
  STextEditorPatternIsEmpty = 'Pattern is empty';

  { TextEditor.PaintHelper }
  STextEditorValueMustBeSpecified = 'SetBaseFont: ''Value'' must be specified.';

{$IFDEF TEXT_EDITOR_SPELL_CHECK}
  { Spell check }
  STextEditorContainsInvalidChars = 'Invalid word: ''%s'' contains characters that cannot be represented in the loaded dictionary''s codepage';
  STextEditorHunspellHandleNeeded = 'Operation requires a dictionary to be loaded first';
  STextEditorSpellCheckEngineCantInitialize = 'Can''t initialize spell check engine.';
  STextEditorSpellCheckEngineCantLoadLibrary = 'Can''t load spell check dynamic link library (DLL).' + sLineBreak + sLineBreak +
    'Check the DLL version - 32-bit application can''t work with 64-bit version and vice versa.';
{$ENDIF}

  { JSON parser }
  STextEditorInvalidJSONPath = 'Invalid JSON path "%s"';
  STextEditorJSONPathContainsNullValue = 'JSON path contains null value ("%s")';
  STextEditorJSONPathIndexError = 'JSON path index out of bounds (%d) "%s"';
  STextEditorTypeCastError = 'Cannot cast %s into %s';
  STextEditorUnsupportedFileEncoding = 'File encoding is not supported';

  { Bookmark colors }
  STextEditorBookmarkBlue = 'Blue';
  STextEditorBookmarkGreen = 'Green';
  STextEditorBookmarkPurple = 'Purple';
  STextEditorBookmarkRed = 'Red';
  STextEditorBookmarkYellow = 'Yellow';

implementation

end.
