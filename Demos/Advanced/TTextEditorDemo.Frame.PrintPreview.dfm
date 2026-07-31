object FramePrintPreview: TFramePrintPreview
  Left = 0
  Top = 0
  Width = 844
  Height = 586
  Align = alClient
  TabOrder = 0
  object PrintPreview: TTextEditorPrintPreview
    Left = 0
    Top = 31
    Width = 844
    Height = 555
    OnPreviewPage = PrintPreviewPreviewPage
    TabOrder = 0
  end
  object PanelPreviewBar: TPanel
    Left = 0
    Top = 0
    Width = 844
    Height = 31
    Align = alTop
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 1
    object LabelPage: TLabel
      Left = 70
      Top = 7
      Width = 100
      Height = 13
      Alignment = taCenter
      AutoSize = False
      Caption = 'Page 1 / 1'
    end
    object LabelPreviewScale: TLabel
      Left = 253
      Top = 7
      Width = 27
      Height = 15
      Caption = 'Scale'
    end
    object ButtonPageFirst: TButton
      Left = 8
      Top = 4
      Width = 28
      Height = 23
      Caption = '|<'
      TabOrder = 0
      OnClick = ButtonPageFirstClick
    end
    object ButtonPagePrevious: TButton
      Left = 38
      Top = 4
      Width = 28
      Height = 23
      Caption = '<'
      TabOrder = 1
      OnClick = ButtonPagePreviousClick
    end
    object ButtonPageNext: TButton
      Left = 174
      Top = 4
      Width = 28
      Height = 23
      Caption = '>'
      TabOrder = 2
      OnClick = ButtonPageNextClick
    end
    object ButtonPageLast: TButton
      Left = 204
      Top = 4
      Width = 28
      Height = 23
      Caption = '>|'
      TabOrder = 3
      OnClick = ButtonPageLastClick
    end
    object ComboBoxPreviewScale: TComboBox
      Left = 286
      Top = 4
      Width = 130
      Height = 23
      Style = csDropDownList
      DropDownCount = 12
      ItemIndex = 1
      TabOrder = 4
      Text = 'Page width'
      OnChange = ComboBoxPreviewScaleChange
      Items.Strings = (
        'Whole page'
        'Page width'
        '50 %'
        '75 %'
        '100 %'
        '150 %'
        '200 %')
    end
    object CheckBoxColors: TCheckBox
      Left = 436
      Top = 7
      Width = 56
      Height = 17
      Caption = 'Colors'
      TabOrder = 5
      OnClick = CheckBoxPreviewOptionClick
    end
    object CheckBoxLineNumbers: TCheckBox
      Left = 498
      Top = 7
      Width = 90
      Height = 17
      Caption = 'Line numbers'
      TabOrder = 6
      OnClick = CheckBoxPreviewOptionClick
    end
    object CheckBoxWordWrap: TCheckBox
      Left = 594
      Top = 7
      Width = 80
      Height = 17
      Caption = 'Word wrap'
      Checked = True
      State = cbChecked
      TabOrder = 7
      OnClick = CheckBoxPreviewOptionClick
    end
    object CheckBoxHighlight: TCheckBox
      Left = 680
      Top = 7
      Width = 70
      Height = 17
      Caption = 'Highlight'
      Checked = True
      State = cbChecked
      TabOrder = 8
      OnClick = CheckBoxPreviewOptionClick
    end
  end
end
