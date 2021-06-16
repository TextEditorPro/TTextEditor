object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'TTextEditor Demo'
  ClientHeight = 766
  ClientWidth = 918
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object SplitterVertical: TSplitter
    Left = 207
    Top = 0
    Height = 766
  end
  object PanelLeft: TPanel
    Left = 0
    Top = 0
    Width = 207
    Height = 766
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
    object SplitterHorizontal: TSplitter
      Left = 0
      Top = 501
      Width = 207
      Height = 3
      Cursor = crVSplit
      Align = alBottom
    end
    object ListBoxThemes: TListBox
      AlignWithMargins = True
      Left = 3
      Top = 504
      Width = 204
      Height = 259
      Margins.Top = 0
      Margins.Right = 0
      Align = alBottom
      ItemHeight = 13
      TabOrder = 0
      OnClick = ListBoxThemesClick
    end
    object ListBoxHighlighters: TListBox
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 204
      Height = 498
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alClient
      ItemHeight = 13
      TabOrder = 1
      OnClick = ListBoxHighlightersClick
    end
  end
  object Editor: TTextEditor
    AlignWithMargins = True
    Left = 210
    Top = 3
    Width = 705
    Height = 760
    Cursor = crIBeam
    Margins.Left = 0
    ActiveLine.Indicator.Visible = False
    Align = alClient
    Caret.Options = []
    CodeFolding.Hint.Font.Charset = DEFAULT_CHARSET
    CodeFolding.Hint.Font.Color = clWindowText
    CodeFolding.Hint.Font.Height = -11
    CodeFolding.Hint.Font.Name = 'Courier New'
    CodeFolding.Hint.Font.Style = []
    CodeFolding.Hint.Indicator.Glyph.Visible = False
    CodeFolding.Visible = True
    CompletionProposal.CloseChars = '()[]. '
    CompletionProposal.Font.Charset = DEFAULT_CHARSET
    CompletionProposal.Font.Color = clWindowText
    CompletionProposal.Font.Height = -11
    CompletionProposal.Font.Name = 'Tahoma'
    CompletionProposal.Font.Style = []
    CompletionProposal.MinHeight = 0
    CompletionProposal.MinWidth = 0
    CompletionProposal.ShortCut = 16416
    CompletionProposal.Snippets.Items = <>
    CompletionProposal.Trigger.Chars = '.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Courier New'
    Font.Style = []
    LeftMargin.Font.Charset = DEFAULT_CHARSET
    LeftMargin.Font.Color = 13408665
    LeftMargin.Font.Height = -11
    LeftMargin.Font.Name = 'Courier New'
    LeftMargin.Font.Style = []
    LeftMargin.Width = 55
    LineSpacing = 0
    MatchingPairs.AutoComplete = False
    Minimap.Font.Charset = DEFAULT_CHARSET
    Minimap.Font.Color = clWindowText
    Minimap.Font.Height = -1
    Minimap.Font.Name = 'Courier New'
    Minimap.Font.Style = []
    OnCreateHighlighterStream = EditorCreateHighlighterStream
    Ruler.Font.Charset = DEFAULT_CHARSET
    Ruler.Font.Color = 13408665
    Ruler.Font.Height = -11
    Ruler.Font.Name = 'Courier New'
    Ruler.Font.Style = []
    SpecialChars.Style = scsDot
    SyncEdit.ShortCut = 24650
    TabOrder = 1
    WordWrap.Indicator.MaskColor = clFuchsia
  end
end
