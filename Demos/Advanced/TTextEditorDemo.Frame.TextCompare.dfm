object FrameTextCompare: TFrameTextCompare
  Left = 0
  Top = 0
  Width = 1148
  Height = 860
  Align = alClient
  TabOrder = 0
  object GridPanel: TGridPanel
    Left = 0
    Top = 0
    Width = 1148
    Height = 860
    Align = alClient
    BevelOuter = bvNone
    Caption = 'GridPanel'
    ColumnCollection = <
      item
        Value = 50.000000000000000000
      end
      item
        SizeStyle = ssAbsolute
        Value = 60.000000000000000000
      end
      item
        Value = 50.000000000000000000
      end>
    ControlCollection = <
      item
        Column = 0
        Control = EditorCompareLeft
        Row = 0
      end
      item
        Column = 2
        Control = EditorCompareRight
        Row = 0
      end
      item
        Column = 1
        Control = CompareScrollBar
        Row = 0
      end>
    RowCollection = <
      item
        Value = 100.000000000000000000
      end>
    ShowCaption = False
    TabOrder = 0
    object EditorCompareLeft: TTextEditor
      Left = 0
      Top = 0
      Width = 543
      Height = 858
      Align = alClient
      Border.Color = 9471874
      Border.ColoredEdges = [ebLeft, ebTop, ebRight, ebBottom]
      LeftMargin.Width = 57
      OnAfterLinePaint = EditorCompareAfterLinePaint
      OnChange = EditorCompareChange
      OnCustomLineColors = EditorCompareCustomLineColors
      OnScroll = EditorCompareScroll
      PartialLoad.Rows = 100
      TabOrder = 0
    end
    object EditorCompareRight: TTextEditor
      Left = 603
      Top = 0
      Width = 543
      Height = 858
      Align = alClient
      Border.Color = 9471874
      Border.ColoredEdges = [ebLeft, ebTop, ebRight, ebBottom]
      LeftMargin.Width = 57
      OnAfterLinePaint = EditorCompareAfterLinePaint
      OnChange = EditorCompareChange
      OnCustomLineColors = EditorCompareCustomLineColors
      OnScroll = EditorCompareScroll
      PartialLoad.Rows = 100
      TabOrder = 1
    end
    object CompareScrollBar: TTextEditorCompareScrollBar
      Left = 543
      Top = 0
      Width = 60
      Height = 858
      Align = alClient
      EditorLeft = EditorCompareLeft
      EditorRight = EditorCompareRight
      ScrollBarVisible = True
    end
  end
end
