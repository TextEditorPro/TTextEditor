object FrameTextEditor: TFrameTextEditor
  Left = 0
  Top = 0
  Width = 640
  Height = 480
  Align = alClient
  TabOrder = 0
  object TextEditor: TTextEditor
    Left = 0
    Top = 0
    Width = 640
    Height = 439
    Align = alClient
    Border.Color = 9471874
    Border.ColoredEdges = [ebLeft, ebTop, ebRight, ebBottom]
    CodeFolding.Visible = True
    HighlightLine.Active = True
    LeftMargin.MarksPanel.Options = [bpoToggleBookmarkByClick, bpoShowBookmarkColorsPopup]
    LeftMargin.Width = 57
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
      Left = 12
      Top = 6
      Width = 70
      Height = 15
      Caption = 'LabelTestRun'
    end
  end
end
