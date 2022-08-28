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
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 13
  object SplitterVertical: TSplitter
    Left = 207
    Top = 0
    Height = 744
  end
  object PanelLeft: TPanel
    Left = 0
    Top = 0
    Width = 207
    Height = 744
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
    object SplitterHorizontal: TSplitter
      Left = 0
      Top = 441
      Width = 207
      Height = 3
      Cursor = crVSplit
      Align = alBottom
    end
    object PanelThemes: TPanel
      Left = 0
      Top = 444
      Width = 207
      Height = 300
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 0
      object ListBoxThemes: TListBox
        AlignWithMargins = True
        Left = 3
        Top = 23
        Width = 204
        Height = 274
        Margins.Top = 0
        Margins.Right = 0
        Align = alClient
        BevelOuter = bvNone
        ItemHeight = 13
        TabOrder = 0
        OnClick = ListBoxThemesClick
      end
      object CheckBoxUseDefaultTheme: TCheckBox
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 201
        Height = 17
        Action = ActionUseDefaultTheme
        Align = alTop
        TabOrder = 1
      end
    end
    object ListBoxHighlighters: TListBox
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 204
      Height = 438
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alClient
      ItemHeight = 13
      TabOrder = 1
      OnClick = ListBoxHighlightersClick
    end
  end
  object TextEditor: TTextEditor
    AlignWithMargins = True
    Left = 210
    Top = 3
    Width = 705
    Height = 738
    Margins.Left = 0
    Align = alClient
    CodeFolding.Visible = True
    HighlightLine.Active = True
    LeftMargin.Width = 55
    OnCompletionProposalExecute = TextEditorCompletionProposalExecute
    OnCreateHighlighterStream = TextEditorCreateHighlighterStream
    TabOrder = 1
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 744
    Width = 918
    Height = 22
    Panels = <
      item
        Alignment = taCenter
        Text = 'Zoom: 100 %'
        Width = 100
      end>
    PopupMenu = PopupMenuZoom
    OnClick = StatusBarClick
  end
  object PopupMenuZoom: TPopupMenu
    AutoHotkeys = maManual
    Left = 444
    Top = 658
    object MenuItemZoom100: TMenuItem
      Action = ActionZoom100
      AutoCheck = True
    end
    object MenuItemZoom125: TMenuItem
      Action = ActionZoom125
      AutoCheck = True
    end
    object MenuItemZoom150: TMenuItem
      Action = ActionZoom150
      AutoCheck = True
    end
    object MenuItemZoom200: TMenuItem
      Action = ActionZoom200
      AutoCheck = True
    end
    object MenuItemZoom300: TMenuItem
      Action = ActionZoom300
      AutoCheck = True
    end
  end
  object ActionList: TActionList
    Left = 440
    Top = 584
    object ActionZoom100: TAction
      Tag = 100
      AutoCheck = True
      Caption = '100 %'
      Checked = True
      GroupIndex = 1
      OnExecute = ActionZoomExecute
    end
    object ActionZoom125: TAction
      Tag = 125
      AutoCheck = True
      Caption = '125 %'
      GroupIndex = 1
      OnExecute = ActionZoomExecute
    end
    object ActionZoom150: TAction
      Tag = 150
      AutoCheck = True
      Caption = '150 %'
      GroupIndex = 1
      OnExecute = ActionZoomExecute
    end
    object ActionZoom200: TAction
      Tag = 200
      AutoCheck = True
      Caption = '200 %'
      GroupIndex = 1
      OnExecute = ActionZoomExecute
    end
    object ActionZoom300: TAction
      Tag = 300
      AutoCheck = True
      Caption = '300 %'
      GroupIndex = 1
      OnExecute = ActionZoomExecute
    end
    object ActionUseDefaultTheme: TAction
      Caption = ' Use default theme'
      OnExecute = ActionUseDefaultThemeExecute
    end
  end
end
