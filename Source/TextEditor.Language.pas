unit TextEditor.Language;

interface

resourcestring
  { TextEditor }
  STextEditorScrollInfoTopLine = 'Top line: %d';
  STextEditorScrollInfo = '%d - %d';
  STextEditorSearchStringNotFound = 'Search string ''%s'' not found';
  STextEditorSearchMatchNotFound = 'Search match not found.%sRestart search from the beginning of the file?';
  STextEditorRightMarginPosition = 'Position: %d';
  STextEditorSearchEngineNotAssigned = 'Search engine has not been assigned';

  { TextEditor.CompletionProposal }
  STextEditorSnippet = 'Snippet';
  STextEditorKeyword = 'Keyword';
  STextEditorText = 'Text';

  { TextEditor.KeyCommands }
  STextEditorDuplicateShortcut = 'Shortcut already exists';

  { TextEditor.MacroRecorder }
  STextEditorCannotRecord = 'Cannot record macro; already recording or playing';
  STextEditorCannotPlay = 'Cannot playback macro; already playing or recording';
  STextEditorCannotPause = 'Can only pause when recording';
  STextEditorCannotResume = 'Can only resume when paused';
  STextEditorShortcutAlreadyExists = 'Shortcut already exists';

  { TextEditor.Lines }
{$IFDEF TEXTEDITOR_RANGE_CHECKS}
  STextEditorListIndexOutOfBounds = 'Invalid list index %d';
{$ENDIF}
  STextEditorInvalidCapacity = 'List capacity cannot be smaller than count';

  { TextEditor.Highlighter.Import.JSON }
  STextEditorErrorInHighlighterParse = 'JSON parse error on line %d column %d: %s';
  STextEditorErrorInHighlighterImport = 'Error in highlighter import: %s';

  { TextEditor.Search }
  STextEditorPatternIsEmpty = 'Pattern is empty';

  { TextEditor.PaintHelper }
  STextEditorValueMustBeSpecified = 'SetBaseFont: ''Value'' must be specified.';

{$IFDEF TEXT_EDITOR_SPELL_CHECK}
  { Spell check }
  STextEditorSpellCheckEngineCantLoadLibrary = 'Can''t load spell check dynamic link library (DLL).' + sLineBreak + sLineBreak +
    'Check the DLL version - 32-bit application can''t work with 64-bit version and vice versa.';
  STextEditorSpellCheckEngineCantInitialize = 'Can''t initialize spell check engine.';
  STextEditorHunspellHandleNeeded = 'Operation requires a dictionary to be loaded first';
  STextEditorContainsInvalidChars = 'Invalid word: ''%s'' contains characters that cannot be represented in the loaded dictionary''s codepage';
{$ENDIF}

  { JSON parser }
  STextEditorUnsupportedFileEncoding = 'File encoding is not supported';
  STextEditorUnexpectedEndOfFile = 'Unexpected end of file where %s was expected';
  STextEditorUnexpectedToken = 'Expected %s but found %s';
  STextEditorInvalidStringCharacter = 'Invalid character in string';
  STextEditorStringNotClosed = 'String not closed';
  STextEditorTypeCastError = 'Cannot cast %s into %s';
  STextEditorInvalidJSONPath = 'Invalid JSON path "%s"';
  STextEditorJSONPathContainsNullValue = 'JSON path contains null value ("%s")';
  STextEditorJSONPathIndexError = 'JSON path index out of bounds (%d) "%s"';

implementation

end.
