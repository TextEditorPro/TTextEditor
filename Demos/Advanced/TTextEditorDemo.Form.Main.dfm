object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'TTextEditor Advanced Demo'
  ClientHeight = 766
  ClientWidth = 1229
  Color = clWindow
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 13
  object StatusBar: TStatusBar
    Left = 0
    Top = 744
    Width = 1229
    Height = 22
    Panels = <
      item
        Width = 74
      end
      item
        Text = 'Ln 1 : Col 1'
        Width = 150
      end
      item
        Width = 120
      end
      item
        Text = 'Zoom: 100%'
        Width = 120
      end
      item
        Text = 'Object Pascal'
        Width = 120
      end
      item
        Text = 'Visual Studio Dark'
        Width = 120
      end>
    OnClick = StatusBarClick
  end
  object PanelSidebar: TPanel
    Left = 0
    Top = 0
    Width = 74
    Height = 744
    Align = alLeft
    BevelOuter = bvNone
    Caption = 'PanelSidebar'
    Padding.Right = 3
    ParentColor = True
    ShowCaption = False
    TabOrder = 1
    object SpeedButtonTextEditor: TSpeedButton
      Left = 0
      Top = 0
      Width = 71
      Height = 74
      Action = ActionViewTextEditor
      Align = alTop
      GroupIndex = 1
      Down = True
      ImageName = 'icons8-page'
      Images = VirtualImageList
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Tahoma'
      Font.Style = []
      Layout = blGlyphTop
      ParentFont = False
    end
    object SpeedButton1: TSpeedButton
      Left = 0
      Top = 670
      Width = 71
      Height = 74
      Action = ActionViewDarkTheme
      Align = alBottom
      ImageName = 'icons8-invert-colors'
      Images = VirtualImageList
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Tahoma'
      Font.Style = []
      Layout = blGlyphTop
      ParentFont = False
    end
    object SpeedButton2: TSpeedButton
      Left = 0
      Top = 148
      Width = 71
      Height = 74
      Action = ActionViewPrintPreview
      Align = alTop
      GroupIndex = 1
      ImageName = 'icons8-view'
      Images = VirtualImageList
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Tahoma'
      Font.Style = []
      Layout = blGlyphTop
      ParentFont = False
    end
    object SpeedButton3: TSpeedButton
      Left = 0
      Top = 74
      Width = 71
      Height = 74
      Action = ActionViewTextCompare
      Align = alTop
      GroupIndex = 1
      ImageName = 'icons8-compare'
      Images = VirtualImageList
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Tahoma'
      Font.Style = []
      Layout = blGlyphTop
      ParentFont = False
    end
  end
  object MainMenu: TMainMenu
    Left = 144
    Top = 14
    object MenuItemFile: TMenuItem
      Caption = 'File'
      object MenuItemOpen: TMenuItem
        Caption = 'Open...'
        ShortCut = 16463
        OnClick = MenuItemOpenClick
      end
      object MenuItemSave: TMenuItem
        Caption = 'Save'
        ShortCut = 16467
        OnClick = MenuItemSaveClick
      end
      object MenuItemSaveAs: TMenuItem
        Caption = 'Save as...'
        OnClick = MenuItemSaveAsClick
      end
      object MenuItemExportToHTML: TMenuItem
        Caption = 'Export to HTML...'
        OnClick = MenuItemExportToHTMLClick
      end
      object MenuItemSample: TMenuItem
        Caption = 'Load highlighter sample'
        OnClick = MenuItemSampleClick
      end
      object MenuItemFileSeparator: TMenuItem
        Caption = '-'
      end
      object MenuItemExit: TMenuItem
        Caption = 'Exit'
        OnClick = MenuItemExitClick
      end
    end
    object MenuItemSearch: TMenuItem
      Caption = 'Search'
      object MenuItemGoToLine: TMenuItem
        Caption = 'Go to line...'
        OnClick = MenuItemGoToLineClick
      end
    end
    object MenuItemBookmarks: TMenuItem
      Caption = 'Bookmarks'
      object MenuItemBookmarkToggle: TMenuItem
        Caption = 'Toggle bookmark'
        OnClick = MenuItemBookmarkToggleClick
      end
      object MenuItemBookmarkNext: TMenuItem
        Caption = 'Next bookmark'
        OnClick = MenuItemBookmarkNextClick
      end
      object MenuItemBookmarkPrevious: TMenuItem
        Caption = 'Previous bookmark'
        OnClick = MenuItemBookmarkPreviousClick
      end
    end
  end
  object PopupMenuZoom: TPopupMenu
    AutoHotkeys = maManual
    Left = 142
    Top = 452
    object MenuItemZoom100: TMenuItem
      Tag = 100
      AutoCheck = True
      Caption = '100%'
      Checked = True
      GroupIndex = 1
      RadioItem = True
      OnClick = MenuItemZoomClick
    end
    object MenuItemZoom125: TMenuItem
      Tag = 125
      AutoCheck = True
      Caption = '125%'
      GroupIndex = 1
      RadioItem = True
      OnClick = MenuItemZoomClick
    end
    object MenuItemZoom150: TMenuItem
      Tag = 150
      AutoCheck = True
      Caption = '150%'
      GroupIndex = 1
      RadioItem = True
      OnClick = MenuItemZoomClick
    end
    object MenuItemZoom200: TMenuItem
      Tag = 200
      AutoCheck = True
      Caption = '200%'
      GroupIndex = 1
      RadioItem = True
      OnClick = MenuItemZoomClick
    end
    object MenuItemZoom300: TMenuItem
      Tag = 300
      AutoCheck = True
      Caption = '300%'
      GroupIndex = 1
      RadioItem = True
      OnClick = MenuItemZoomClick
    end
  end
  object OpenDialog: TOpenDialog
    Filter = 'All files (*.*)|*.*'
    Left = 240
    Top = 14
  end
  object SaveDialog: TSaveDialog
    Filter = 'All files (*.*)|*.*'
    Left = 336
    Top = 14
  end
  object SaveDialogHTML: TSaveDialog
    DefaultExt = 'html'
    Filter = 'HTML files (*.htm;*.html)|*.htm;*.html'
    Left = 442
    Top = 18
  end
  object VirtualImageList: TVirtualImageList
    Images = <
      item
        CollectionIndex = 0
        CollectionName = 'icons8-page'
        Name = 'icons8-page'
      end
      item
        CollectionIndex = 1
        CollectionName = 'icons8-compare'
        Name = 'icons8-compare'
      end
      item
        CollectionIndex = 2
        CollectionName = 'icons8-view'
        Name = 'icons8-view'
      end
      item
        CollectionIndex = 3
        CollectionName = 'icons8-invert-colors'
        Name = 'icons8-invert-colors'
      end>
    ImageCollection = ImageCollection
    Width = 48
    Height = 48
    Left = 35
    Top = 339
  end
  object ImageCollection: TImageCollection
    Images = <
      item
        Name = 'icons8-page'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000300000003008060000005702F9
              87000000097048597300000B1300000B1301009A9C18000000D149444154789C
              EDD93F0AC2600C86F1EF3CFE1D44AFA0E2D0F43AADABB750F03085EEDA4E0ED5
              2AF1001E205274979210ABBC0FBC7B7E73424008FD7FF15D56C4722316D16EBA
              AD327740C472B538BE596F7DF04790D1F1CDFAE9F185D89DF39F05B823C81030
              480B7F0419028649E18F2063803B820C01A3A4F4479021609C94FE0832044C36
              A78F88D9FE92751630CF1FFE083204B45900E01D000C802E0018005D003000BA
              0060007401C000E8028001D0050003A00B00FE3220327C31B5586D062096A533
              A28E591666008450E86C4F451B61E0AAEDABE50000000049454E44AE426082}
          end>
      end
      item
        Name = 'icons8-compare'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000300000003008060000005702F9
              87000000097048597300000B1300000B1301009A9C180000020049444154789C
              EDD83B4BC3501806E08297C5D1C1E41F88D758F1063A7B1B8C833FC1D6526CA7
              22A88B82D7C92A08B60A6EFE06EF4989A45671B075B1156DABD57A5B9CD4E193
              580D22356D8E273191F3C20B25CBF99E1C4E0ED462212121F93FE9BD866E3605
              976C0A404D1B96CF058B11D29382A4DAE1A5568C868D81601186975A3912CE20
              562E445302AA4622C640B08880EAE18831102C22A066F8C418081611503F719A
              15D1B81A174C0168179F8C81601101B94A007F0D28F31E03ED4FE4DD128F2098
              1A503CB08E86503BD8A6E7011C87AFD801458EAD0C62684FD414B0DF7F0B9CEB
              161C072F580185CE5D34040A20684B03E74A2B225403060368886C8BF3AE7B79
              D0A0EDE6A3D720DA5320DAAFE4E79C3B0DF6A3172C8002B78086C8FE96EFF202
              48CF56E71FF19C014FE82784F2C1CEB638F7073B503A17454318E50CD0398A15
              C06BF015A2F5026C68740FD07A01F2EDBF055827A230DECA9B13C04CC660B699
              076FEDB6F900B553519869E1619ED9311F80998AC1AC347CDD0E2C5877DF2BFD
              96CB64EA65B661BA89530740FD634BA95DB167A0BC117971675F481E762107E0
              A7DD51DA814E9C0869F8F2B533A01663FAEC00EE486FFEEBF09A9F01DC511AE2
              1DD1CC9B17F0790F8CB505CC0BA071DFC404F02D04E02780DF85F2C793B887A7
              7CF1847E80A564274E04E58B27287FA243370009098945F3BC01805BB4894FEB
              7FB60000000049454E44AE426082}
          end>
      end
      item
        Name = 'icons8-view'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000300000003008060000005702F9
              87000000097048597300000B1300000B1301009A9C18000002A949444154789C
              EDD94F4FD3601C07F09D7C0786E13B90E1BF1878036E3033603544EF9ED4444D
              A644745B42A2311A0362108C6C43D09B47E3150F442207A309FB8B3AD9D66EDD
              221D5B5B64ED5CF99A67E84D9175B51DDA6FF2DCBF9FEDF73CBF25B358CC9831
              F3EFE7541E2E8A45966281664F5728B5A83BC0CD82D1A23C391DFEB0FE084AA3
              F2E4D87C916DC44C7A69CF027447501A023A7D51FD1194868043DEA8FE084A63
              80EE084A43C0616F4C7F04A521E08837A63F82D21070FCF6A73F22BAE7328B2D
              0BE85D12F547501A021A391613F02326803501CDC504B026A0B99800F63F010C
              300A06981ADCB9ADBD0370AD4A70AE087044D7615FE6706299832352446F826F
              6D407FBA8ADE781983090ED77202C6051981AA826959C1282FC343F37824A3B3
              25017D29093D91226E14443C55803905985580273560E61B109081C71230B989
              DAC4062647807D2D03E8CF54EBE5EF962B78B6F5FBF2531560E22BF0600318E3
              F1AA2984960032DBDE82B8FBF202708F07EE14F1D07000199DC14471C7B199FA
              55F975E0E61A6AFE3C6C86029C1FC4FA856DB4FC2D0E18F902F8F2B86F28A027
              56C2B828AB2AEF2F00C339440C0390E5640F1711AC2AAACA5F6781AB0C04E300
              D96D0079E7D5941FCA021E1ABC6100721CD11246C9C252571E1753068E50FD12
              AF08B8C208AACA5F4A01E793183314407EF750318E6CD886CB5F48A276F6233A
              0C05D45FA2781997334263E53F03A7DF092F2DADF017535F5A8623CC6138B7B9
              EBF2EE376B38F83C2E752FF02EB5DFC0492D11AED50AEC610EE79202D9B03B8E
              CD99F7C20B52BE6B81C7B1F9D2625B28AD0EF1B7E2CFC346362C5952430C444F
              0622796DC885FD39F3E4933F3A5F7A6D0D31923540CB07A6330396BD166B9076
              5A0374A53D48C3441899B650DA650DD21241B407E8B78696511B8220E5F7CFA6
              ACDF01CD23A7074995818E0000000049454E44AE426082}
          end>
      end
      item
        Name = 'icons8-invert-colors'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000300000003008060000005702F9
              87000000097048597300000B1300000B1301009A9C180000043349444154789C
              ED986D6C136500C79F0E440392184D40A35DF7D6EEA5EDDA8D2F8A888989068C
              892C30C342CA708C0E9D40B72923979823312626EA48FC30435CC0726BB77574
              D0AE7B6937231064C8622241CCCA0709AED7EBCBB58B8B1901591F73EB6EBDB6
              77EDF572DDBA64FFE4F7FDF77BFADCB529006B5B5B6E6EFBF5E0E6EA9F666EA8
              5AAFCC1AF4D84B60550D4249D558D852353E0301E286AF1D771128FAF37AB05A
              A61D0F7D5135168614540045CDC7D62B6035ACDA3953A3758522DAB130D43202
              24C8143CD4D47D06E4F2AAC6C3955A57F85FAD2B0C69E8008A4DED772227F45D
              7B402EAED2496CD238C37F52D21A1A677C00457EDBC46383FE6CEE3DD41A67C8
              A8718660228901146F7D62BF07726995A3E4C125E9D128958BB00550E8F45827
              C8856906C997D523E40C2D1CC70877C0E6F6DB9196FAF3AFAEAC3D8412F52839
              4ACB26A21E21390328AA8F8D875080E6AD98BF6624D414158DCA2E311C235500
              40DCB0AED1746145E4D5C3E42BEA617296299B888A47C0B3276F478ED7776E5B
              F600D510D913273BC44EBA0080B8E1CE66C7FD6595570E855E573982112E6995
              8322B8009F00093205F50D5DC79645BED602D7A986C8DF1365951CF00900881B
              2A0C57E7D05ACB86AC07281D81C35CB2CAC164F80600C40D0F3418BBB27EFA4A
              47F01E976C05137B944C02A4AD371E67F553500E06F627893264630496C82400
              206E587FE85C47D6022A6CC1DF52C99653D8E2C934406EB83697952FB7329BEF
              ED38591B0F2E671E0010373C72F0ECA7A207945FF69B5389D29425202460E751
              FB5FA2CA6FB3E31BCB6D81B974B20B5CF2C721246063FB1DD852FBEDF3A20594
              0D04DEE3234B534A33202C00206EF8A1EE87CF450B281DF077A4145D94654368
              C0AEC6BE4911037C57D38932515863080DD036BBC2A20528AC3E9C8FACC2EA4B
              4268C096B65B4F440B281DF03F8C176597555C8C215F4468C0D3ED7F40D102E4
              56DFA374A249F447111AB0E1D45DF10214177D01451AD1444A16111AF042DBE4
              BC6801F27E6222BD2C014B2CC9080D50368FFD235A40493FF10DF354B964E3E8
              2360719FF080DD0D3D37450B90F7E36FA492A544B9101A70A4EEBB26D1028005
              AE2BE9F3FAE9534D492F13AFB0FBDF3A398FBE898AFB777C512F71925B948045
              BDDE647A8405D4E87EB403B1273B7FFF99E21EE2413187281799CA6F6DBDF9A4
              E51D117FC8315768F6EE2B32E3112ED9421A738C4CE425C814D4EDFFFE2B90CD
              1599BD5FB28926832F9049C0BBBA0BD740D687C2BC4293B73749D684C30216F8
              CA6F3F6C7D20FA83CB39082532137EBAA0DB1361932EE88EC1E7DAECD6992696
              4F9EB17C9377AF0CC3FF660ACB124825FFA261E23FDD079DD9BDF37CDE4EF998
              E7B37CCCE39361388CE25982FD3D7F6BBEA6EEDCE089F7CF3C07726628CC931A
              F11D526CFA6B2936FD8BD438ED931A3D8F9E3A757741B8E223E7EC2E1DF66BE3
              9E8EA32B725DD6B636C0BAFF0158BFF2AACA80850A0000000049454E44AE4260
              82}
          end>
      end>
    Left = 35
    Top = 273
  end
  object ActionList: TActionList
    Images = VirtualImageList
    Left = 139
    Top = 107
    object ActionViewTextEditor: TAction
      AutoCheck = True
      Caption = 'Text Editor'
      GroupIndex = 1
      ImageIndex = 0
      OnExecute = ActionViewExecute
    end
    object ActionViewTextCompare: TAction
      Tag = 1
      AutoCheck = True
      Caption = 'Text Compare'
      GroupIndex = 1
      ImageIndex = 1
      OnExecute = ActionViewExecute
    end
    object ActionViewPrintPreview: TAction
      Tag = 2
      AutoCheck = True
      Caption = 'Print Preview'
      GroupIndex = 1
      ImageIndex = 2
      OnExecute = ActionViewExecute
    end
    object ActionViewDarkTheme: TAction
      Tag = 3
      Caption = 'Dark Theme'
      ImageIndex = 3
      OnExecute = ActionViewDarkThemeExecute
    end
  end
  object PopupMenuHighlighters: TPopupMenu
    Left = 142
    Top = 520
  end
  object PopupMenuThemes: TPopupMenu
    Left = 142
    Top = 588
  end
end
