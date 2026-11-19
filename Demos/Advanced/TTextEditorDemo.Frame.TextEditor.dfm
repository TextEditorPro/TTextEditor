object FrameTextEditor: TFrameTextEditor
  Left = 0
  Top = 0
  Width = 640
  Height = 480
  Align = alClient
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  object TextEditor: TTextEditor
    Left = 0
    Top = 0
    Width = 640
    Height = 319
    Align = alClient
    Border.Color = 9471874
    Border.ColoredEdges = [ebLeft, ebTop, ebRight, ebBottom]
    CodeFolding.Visible = True
    HighlightLine.Active = True
    LeftMargin.MarksPanel.Options = [bpoToggleBookmarkByClick, bpoShowBookmarkColorsPopup]
    OnCreateHighlighterStream = TextEditorCreateHighlighterStream
    PartialLoad.Rows = 100
    Selection.Options = [soALTSetsColumnMode, soHighlightSimilarTerms, soTermsCaseSensitive]
    TabOrder = 0
  end
  object PanelTests: TPanel
    Left = 0
    Top = 439
    Width = 640
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    Caption = 'PanelTests'
    ParentColor = True
    ShowCaption = False
    TabOrder = 1
    Visible = False
    object LabelTestRun: TLabel
      Left = 0
      Top = 6
      Width = 70
      Height = 15
      Caption = 'LabelTestRun'
    end
  end
  object PanelLanguageServer: TPanel
    Left = 0
    Top = 319
    Width = 640
    Height = 120
    Align = alBottom
    BevelOuter = bvNone
    ParentColor = True
    ShowCaption = False
    TabOrder = 2
    DesignSize = (
      640
      120)
    object LabelServerCommandLine: TLabel
      Left = 2
      Top = 8
      Width = 86
      Height = 15
      Caption = 'Language server'
    end
    object EditServerCommandLine: TEdit
      Left = 0
      Top = 26
      Width = 440
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      TextHint = 'Detected automatically from the opened file - edit to override'
    end
    object ButtonServerStart: TButton
      Left = 456
      Top = 25
      Width = 85
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Start'
      TabOrder = 1
      OnClick = ButtonServerStartClick
    end
    object ButtonServerStop: TButton
      Left = 547
      Top = 25
      Width = 85
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Stop'
      Enabled = False
      TabOrder = 2
      OnClick = ButtonServerStopClick
    end
    object MemoServerLog: TMemo
      Left = 0
      Top = 56
      Width = 640
      Height = 64
      Anchors = [akLeft, akTop, akRight, akBottom]
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 3
    end
  end
end
