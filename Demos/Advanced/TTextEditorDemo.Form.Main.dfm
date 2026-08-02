object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'TTextEditor Advanced Demo'
  ClientHeight = 786
  ClientWidth = 1229
  Color = clWindow
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 13
  object PanelSidebar: TPanel
    Left = 0
    Top = 2
    Width = 68
    Height = 784
    Align = alLeft
    BevelOuter = bvNone
    Caption = 'PanelSidebar'
    ParentColor = True
    ShowCaption = False
    TabOrder = 0
    object SpeedButtonTextEditor: TSpeedButton
      Left = 0
      Top = 0
      Width = 68
      Height = 61
      Action = ActionViewTextEditor
      Align = alTop
      GroupIndex = 1
      Down = True
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
    object SpeedButtonDarkTheme: TSpeedButton
      Left = 0
      Top = 723
      Width = 68
      Height = 61
      Action = ActionViewDarkTheme
      Align = alBottom
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
    object SpeedButtonPrintPreview: TSpeedButton
      Left = 0
      Top = 122
      Width = 68
      Height = 61
      Action = ActionViewPrintPreview
      Align = alTop
      GroupIndex = 1
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
    object SpeedButtonTextCompare: TSpeedButton
      Left = 0
      Top = 61
      Width = 68
      Height = 61
      Action = ActionViewTextCompare
      Align = alTop
      GroupIndex = 1
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
  object PanelMain: TPanel
    Left = 68
    Top = 2
    Width = 1161
    Height = 784
    Align = alClient
    BevelOuter = bvNone
    Padding.Left = 3
    ParentColor = True
    ShowCaption = False
    TabOrder = 1
    object ActionMainMenuBar: TActionMainMenuBar
      Left = 3
      Top = 0
      Width = 1158
      Height = 25
      UseSystemFont = False
      ActionManager = ActionManager
      Caption = 'ActionMainMenuBar'
      Color = clMenuBar
      ColorMap.DisabledFontColor = 10461087
      ColorMap.HighlightColor = clWhite
      ColorMap.BtnSelectedFont = clBlack
      ColorMap.UnusedColor = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentBackground = True
      Spacing = 0
    end
    object StatusBar: TStatusBar
      AlignWithMargins = True
      Left = 6
      Top = 762
      Width = 1155
      Height = 22
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      Panels = <
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
  end
  object ActionToolBar1: TActionToolBar
    Left = 0
    Top = 0
    Width = 1229
    Height = 2
    ActionManager = ActionManager
    Caption = 'ActionToolBar1'
    Color = clMenuBar
    ColorMap.DisabledFontColor = 10461087
    ColorMap.HighlightColor = clWhite
    ColorMap.BtnSelectedFont = clBlack
    ColorMap.UnusedColor = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Spacing = 0
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
        CollectionName = '0'
        Name = 'icons8-page'
      end
      item
        CollectionIndex = 1
        CollectionName = '1'
        Name = 'icons8-compare'
      end
      item
        CollectionIndex = 2
        CollectionName = '2'
        Name = 'icons8-view'
      end
      item
        CollectionIndex = 3
        CollectionName = '3'
        Name = 'icons8-invert-colors'
      end>
    ImageCollection = ImageCollection
    Width = 32
    Height = 32
    Left = 35
    Top = 341
  end
  object ImageCollection: TImageCollection
    Images = <
      item
        Name = '0'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000017352474200AECE1CE90000000467414D410000B18F0BFC61050000
              00097048597300000EC200000EC20115284A800000001974455874536F667477
              617265005061696E742E4E455420352E312E313213014774000000B865584966
              49492A000800000005001A010500010000004A0000001B010500010000005200
              000028010300010000000200000031010200110000005A000000698704000100
              00006C00000000000000F2760100E8030000F2760100E80300005061696E742E
              4E455420352E312E31320000030000900700040000003032333001A003000100
              00000100000005A0040001000000960000000000000002000100020004000000
              5239380002000700040000003031303000000000837F2F1C72D0D3DF00000178
              494441545847ED96B14AE4501486BF7B5204B1B09A4614DF612DB4B3F4050441
              11415B5F604C6E31731906AC6C7C035B2B050BC1DACE52C5461017B6D9CA6545
              718E4D1CE2995C98615416361FDCE63F27C9971C0207FE779C0DCA8410E64464
              0A505B8B20C07D9665BF6D2146A580F73E49D374DF39B70DA4230824C056AFD7
              3B0666BDF797B6C122360048D374CB39B7034C143DC990074045A42122272184
              7973EB012A059C734B361B01059E816911390D21FCB00D652A0562A31981F7EB
              1B227216425830F53E318161673E80AA02FC01AE805BE05144F6DAEDF68CED25
              F6A69D4EE71058B7F930A8EA519EE72BE5ACDBED26CD66F3B59CBDF3E9020517
              C04DE90B27C04F6037CBB29772636C04E3B2086C021BC55903564B7F4A9FAF12
              A8E2C9067CB34025B5402D500BD402B5402D500BC40462F938B8625FFC40E583
              54F5DA66E3A2AA77799E0F2C2531818362AFFB2C7E01B90D892DA500AD566B32
              499265E75C03E8D9FA903855FDABAAE7DEFB075BFC27780348E35CDD867F14E0
              0000000049454E44AE426082}
          end>
      end
      item
        Name = '1'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000017352474200AECE1CE90000000467414D410000B18F0BFC61050000
              00097048597300000EC400000EC401952B0E1B0000001974455874536F667477
              617265005061696E742E4E455420352E312E313213014774000000B865584966
              49492A000800000005001A010500010000004A0000001B010500010000005200
              000028010300010000000200000031010200110000005A000000698704000100
              00006C000000000000000C770100E80300000C770100E80300005061696E742E
              4E455420352E312E31320000030000900700040000003032333001A003000100
              00000100000005A0040001000000960000000000000002000100020004000000
              52393800020007000400000030313030000000005D22B254A9C21AD800000403
              494441545847BD964F681C551CC7BFBFD9ECEA24A45051BA1EAA54317A684B11
              7B10AC3D69F116100F0D889E3CD4834A288DCC4C76333B0F16B18D1EF42278F0
              0F1505938368B57AF01AA9490C6A9B568D2D2196D8AADD904DB233F3F5E01B99
              BCEC6C32A9F88165F6FDDEF7CD7C66DECC9B9120082645E4006E8E8B8EE3F429
              A51E07F0B9AEBDE938CEF34AA937001CD3B5238EE37CA1949A05701FC929EB3F
              38F8B61191039659DC2645BD9554AD606C91EA4FF2B0004CDEE46F06C0B4DEDF
              5FBAFD2380395D9BD3ED19DD0F9D9FD1E3B78F524A9452E9B3CE8D28A59E328B
              5B4000B4009CD1ED27F465A5FEA573661BE99A28A5D2813CC400F6E8FFBFE8E9
              CCCDB60669565267BC62766E954E027F927C0BC015B3630B4CC671FC4A1CC7AF
              927CADD3CD962940F2A4EBBACF913C6EF66D461445273CCF3BE179DE71D7755F
              9A9F9F7F88E447660E1D049A243FC03F3BFB14C06533D00992AB00E0FBFE6810
              04A3E572D9225901109AD9B60224BFF23CEF92E338A54AA5D220396E663641FA
              FBFB0B227204C09322B293E412805533D85600C03B0060DBF688EFFBB70078CF
              0C6C82353E3E1E2D2F2F1F6C341AF77A9EB76859D63E003D1B826601C095288A
              3EA9D56AF70318149143AEEB7E0360C20C768000502A95EEEEEEEEDEE7FB7ECF
              D2D2D219005F9AC10D0224C72A954A338AA285300C1F09C3705AD74F9BD90E70
              6060A0502C163FEBEAEA3A6759D6DBF57A3D26F9A119340548F27D0068B55AD6
              EAEAEA0F6118B674C7C7006E18F94C9ACD2601FC01600DC0822E6F3A05139EE7
              4DD46AB543B66D5FEAE9E9F9C9B6ED5F832038EA79DE6592678D7C16D1D8D858
              2C228701945DD77DB15AADDA22F28C193497E28B711C3F6B5996ABD7F7846FE3
              383E6659D6288087756D19C003FAFF7900DD4998E429BD8815484244765B96F5
              328047934C822990874C813C9802E7015C353E2C1208602780FDBA9D25F01D80
              EBC68748728C184039356E9DC0D5B5B5B5BE9191918E379A526A06C0DE0C81EF
              1DC7D96B0C5947A552D9512A956601EC8221D022795244660174AD1F06008848
              96456408406F864083645D447E33AE404248B24F440693CF32730AF2D04E2037
              698198E46911F939C33EB9024F03B835436005C0BB00B2AE4044F21E11399A2C
              0169818546A3B1A75EAF6F7861A40982605A44F6B7132039E3BA6E7293B66568
              68A8D4DBDB3B07E04EB49982AFF5ABB7AD3D803B003CA6FB3708E8CC59008B1D
              F6711780C349C114C8433B81DCA4059A240745E44287A7609788BC0EE0F60C81
              6B245FD8C253700A800D43E0F7288A1E1C1E1ECEFC06AC56ABBDC56271421FB8
              9DC08556AB75B05AAD368CA1FFE2FBFEEE42A1704E4FE7862958D4AB98F99282
              5EC57624374F8600F49BEF46877DDC961C1C6D04F29025900B8BE49459FCBF20
              39F5376B01E293EEC2CBC40000000049454E44AE426082}
          end>
      end
      item
        Name = '2'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000017352474200AECE1CE90000000467414D410000B18F0BFC61050000
              0009704859730000EC370000EC370107E564220000001974455874536F667477
              617265005061696E742E4E455420352E312E313213014774000000B865584966
              49492A000800000005001A010500010000004A0000001B010500010000005200
              000028010300010000000200000031010200110000005A000000698704000100
              00006C00000000000000F46F1700E8030000F46F1700E80300005061696E742E
              4E455420352E312E31320000030000900700040000003032333001A003000100
              00000100000005A0040001000000960000000000000002000100020004000000
              52393800020007000400000030313030000000004F7059EA8E9783C8000003CB
              494441545847ED974D681C651CC69F676693550C6E412A7E140B62158A1E2CC4
              83225A3F51103F52446F6AFD3629358868F6BF2171DF217808298D482CF5EB22
              883597A2D068A5AD173114C5E2411B6D51F4A01030E9217677E7F1909975F7DD
              D9CDDA7AD31F2C3BF3FCFFEFBCBFD9F75D9801FEEBD00FB270CE0D907C1CC079
              00E4D7DB9003B0B352A91CAB542A95288A6A7E03BA114826DFE7E75D722B8040
              D236337BDA2F0240E0073EC99D9F29350055924F39E7A6FD22BA11487EF6B341
              58BD91C12C896E041AD7FC17496F4B7A02C0BD92B6497A59D21C80D30D7D2971
              E332271233232323619A75239007F0A7A4E75756562E37B3C724CDD56AB55F25
              2DD46AB51933BB338EE3AB257DD03850D215C562F11080AD006E06B095E4BEDE
              DEDE9EB4A7A3C0C4C404257D15C771BF99EDCAE7F38351147D1B04C1421886F3
              41107C9DCBE54E3AE73E267991993D28E9B9743C49E79C7B34D90B487ECDB8A7
              A7E79AB4A7A340B55AA5993D03E08F288A8E929C04B01940FD0E001448DE45F2
              8873EE55337BBD41E212926F013802E050F2390860573AB8A340A9548ACBE5F2
              FA20083E05B0C5AFFB907CB141A269393CAAE9414701AC5E7412C0263F6F4722
              71A3A4629B8DD944478172B9BC99E4437EDE052F954AA5E3920EFB059F8E0224
              EFF0D63B13498725ED0050C1EAB81BC6C7C7D701F8CCEFF5E928906CB86E3869
              66D3001692F34210041B011CF7FA5A584BE01C3F68C3FAE47B250D24F590ACFC
              DD92CD5A023FFB411BF68F8D8D9D0FE0B2E4FC3480DF245DE8F5B5B096C0E77E
              90C117663693CBE506015C90640BA3A3A33F01B8DEEB6DA1A3C0F2F2F22700BE
              F1738F0DCEB9DD244B6920696FA954EA4D367147DA0A38E7B6F7F5F55D2C69D8
              AF796C2039D4B05F8E9AD9543E9F7F16C0A55E6F0B9902CEB921927B494E9BD9
              4149990F13197C1FC7F13DE5727913C931BF98458B4032F96EACFE9FEF73CE4D
              99D91B926EEBB01C1549EF56ABD52D921804C17E0005BF298B2681C6C95348EE
              74CECD4AFA6E7171F15A49B7487A45D23B9266240DC6717CA5993D1286E14D61
              187E09E0AAC66B74A22EE09C7BC09F3C85E4FD4110DC3D3939194BFABD56AB4D
              CDCFCF6F5F5A5ADA11C7F12CC9EBA2289A23F95137EBDE485D80E493CDA52686
              8BC5E21EE75C1404C1B15C2E77A2BFBFFFC742A170220CC31F48BE0FE0767F50
              37B4EC810C868BC5E29473CE911C49B275243726777BAED7FF8FA80B48DAD35C
              02240D2593974916FDFA59507F4EAC0B98D9ACA4010007001C90346066AF39E7
              5E2069F5A1FF0EA7D2836E5E4C1E26F99E9F9F0DC98BCA87E8460067FE6AE643
              00A724BD994EFE3F00F017E7F78E807FD06F0A0000000049454E44AE426082}
          end>
      end
      item
        Name = '3'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000017352474200AECE1CE90000000467414D410000B18F0BFC61050000
              0009704859730000EC370000EC370107E564220000001974455874536F667477
              617265005061696E742E4E455420352E312E313213014774000000B865584966
              49492A000800000005001A010500010000004A0000001B010500010000005200
              000028010300010000000200000031010200110000005A000000698704000100
              00006C00000000000000F46F1700E8030000F46F1700E80300005061696E742E
              4E455420352E312E31320000030000900700040000003032333001A003000100
              00000100000005A0040001000000960000000000000002000100020004000000
              52393800020007000400000030313030000000004F7059EA8E9783C8000002DE
              494441545847ED97BF4F144114C7BF6FEE12128568831604128A0B26FE0187C9
              511923F1C7A9A505395B8AB3B4E1E66E6F77B1B02252D091A3B255B431C6C25C
              01C75F604120C110A362243920D1ECCEB3192EB3C39EECE11A0AFC54B3EFCDDE
              FBDEBCC9CC7781B30ED981A4388ED39FCD66CF03401004FB8EE3ECD973929058
              C0E4E424150A850280228071221A01D0AFD3FB00B6987915C0F2C6C646737171
              91AD9F88259100DFF76F13D10C806B76AE0BABCCFCB452A9BCB613367F1450AF
              D7073299CC73227A64E70C7695520F88E802805B44741FC0250060E625A554B9
              5AADB6ED970EE92AA05EAF5FCE6432AF88286FE72C7E28A57252CAEF00E0BAEE
              A010A24C444F00F431F35A1886C55AADF6C57E11DD04E87FFE2E4171680157A5
              949FCDA0E7797921C40B00A3CCDC524ADD885B09610700402F7B92E25D9152B6
              9452D7016C12515E08316FCF419C00DFF7EF1CD3F3C448293795520F01FC24A2
              92EFFB77ED391101A55289F46E4F0D29658B999F010011CD4C4F4F47DA1E1190
              CBE526008C9BB134504ACD03F80A203F34343461E6EC161C59A234A856ABDF98
              F9A57E2C9AB98800224A7AD09C84B788A9D111E038CE008061339926CCFC510F
              47742DC01490CD66CF19677BEA30F32E803D0003BA1660B7E034E8080882E040
              2BFC2710D145BDC26D5D0BB0F6401BC0A7CE1B29434457F4704BD702EC1630F3
              8AF99C32371153C3DE03C7DEDF27C175DD417D4D03C0B2998B08585F5F6F0258
              3563692084286B8FD0DADEDE6E4672E643A3D160669E35637F8BE77979ED0DC0
              CCB30B0B0B11AB66B700954AE50D3337ECF849F03C6F547B823E665E8AB36847
              04004018868F99B965C77B411B92F7DA90AC29A5CAF61C741350ABD5DA6118DE
              EB41C4AFC381EBBA83BEEFBB42880F46F1629C1B42374B76C8A99A5213ED9266
              7AF00A2D669E8DEBB94D220100303535456363630500457DA50E1B97D781FE30
              5901B0BCB3B3D39C9B9B4BEFC3240EC7713AB75A100407E6F1FA9F5EF80DB7C7
              2DC2E81653650000000049454E44AE426082}
          end>
      end>
    Left = 33
    Top = 273
  end
  object ActionList: TActionList
    Images = VirtualImageList
    Left = 139
    Top = 275
    object ActionViewTextEditor: TAction
      AutoCheck = True
      Caption = 'Text Editor'
      GroupIndex = 1
      ImageIndex = 0
      ImageName = 'icons8-page'
      OnExecute = ActionViewExecute
    end
    object ActionViewTextCompare: TAction
      Tag = 1
      AutoCheck = True
      Caption = 'Text Compare'
      GroupIndex = 1
      ImageIndex = 1
      ImageName = 'icons8-compare'
      OnExecute = ActionViewExecute
    end
    object ActionViewPrintPreview: TAction
      Tag = 2
      AutoCheck = True
      Caption = 'Print Preview'
      GroupIndex = 1
      ImageIndex = 2
      ImageName = 'icons8-view'
      OnExecute = ActionViewExecute
    end
    object ActionViewDarkTheme: TAction
      Tag = 3
      Caption = 'Dark Theme'
      ImageIndex = 3
      ImageName = 'icons8-invert-colors'
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
  object ActionManager: TActionManager
    ActionBars = <
      item
        Items = <
          item
            Items = <
              item
                Action = ActionFileOpen
                Caption = '&Open...'
                ShortCut = 16463
              end
              item
                Action = ActionFileSave
                Caption = '&Save'
                ShortCut = 16467
              end
              item
                Action = ActionFileSaveAs
                Caption = 'S&ave as...'
              end
              item
                Caption = '-'
              end
              item
                Action = ActionFilePrint
                Caption = '&Print...'
              end
              item
                Action = ActionFileExportToHTML
                Caption = '&Export to HTML...'
              end
              item
                Action = ActionFileLoadHighlighterSample
                Caption = '&Load highlighter sample'
              end
              item
                Caption = '-'
              end
              item
                Action = ActionFileExit
                Caption = 'E&xit'
              end>
            Caption = '&File'
          end
          item
            Items = <
              item
                Action = ActionSearchGoToLine
                Caption = '&Go to line...'
              end>
            Caption = '&Search'
          end
          item
            Items = <
              item
                Action = ActionBookmarksToggleBookmark
                Caption = '&Toggle bookmark'
              end
              item
                Action = ActionBookmarksNextBookmark
                Caption = '&Next bookmark'
              end
              item
                Action = ActionBookmarksPreviousBookmark
                Caption = '&Previous bookmark'
              end>
            Caption = '&Bookmarks'
          end
          item
            Items = <
              item
                Action = ActionMacroRecord
                Caption = '&Record'
                ShortCut = 24658
              end
              item
                Action = ActionMacroPause
                Caption = '&Pause'
                ShortCut = 49232
              end
              item
                Action = ActionMacroStop
                Caption = '&Stop'
                ShortCut = 49234
              end
              item
                Action = ActionMacroPlay
                Caption = 'P&lay'
                ShortCut = 24656
              end>
            Caption = '&Macro'
          end
          item
            Items = <
              item
                Action = ActionTestUndoRedo
                Caption = '&Test undo/redo'
              end
              item
                Action = ActionTestSelectionInvariants
                Caption = 'T&est selection invariants'
              end
              item
                Action = ActionTestSaveLoad
                Caption = 'Test &save/load round-trip'
              end
              item
                Action = ActionTestClipboardRoundTrip
                Caption = 'Test &clipboard round-trip'
              end
              item
                Action = ActionTestMacro
                Caption = 'Test &macro record/playback'
              end
              item
                Action = ActionTestHighlighterSweep
                Caption = 'Test &highlighters and themes'
              end>
            Caption = '&Test'
          end>
        ActionBar = ActionMainMenuBar
      end>
    Left = 240
    Top = 98
    StyleName = 'Platform Default'
    object ActionFileOpen: TAction
      Category = 'File'
      Caption = 'Open...'
      ShortCut = 16463
      OnExecute = ActionFileOpenExecute
    end
    object ActionFileSave: TAction
      Category = 'File'
      Caption = 'Save'
      ShortCut = 16467
      OnExecute = ActionFileSaveExecute
    end
    object ActionFileSaveAs: TAction
      Category = 'File'
      Caption = 'Save as...'
      OnExecute = ActionFileSaveAsExecute
    end
    object ActionFilePrint: TAction
      Category = 'File'
      Caption = 'Print...'
      OnExecute = ActionFilePrintExecute
    end
    object ActionFileExportToHTML: TAction
      Category = 'File'
      Caption = 'Export to HTML...'
      OnExecute = ActionFileExportToHTMLExecute
    end
    object ActionFileLoadHighlighterSample: TAction
      Category = 'File'
      Caption = 'Load highlighter sample'
      OnExecute = ActionFileLoadHighlighterSampleExecute
    end
    object ActionFileExit: TAction
      Category = 'File'
      Caption = 'Exit'
      OnExecute = ActionFileExitExecute
    end
    object ActionSearchGoToLine: TAction
      Category = 'Search'
      Caption = 'Go to line...'
      OnExecute = ActionSearchGoToLineExecute
    end
    object ActionBookmarksToggleBookmark: TAction
      Category = 'Bookmarks'
      Caption = 'Toggle bookmark'
      OnExecute = ActionBookmarksToggleBookmarkExecute
    end
    object ActionBookmarksNextBookmark: TAction
      Category = 'Bookmarks'
      Caption = 'Next bookmark'
      OnExecute = ActionBookmarksNextBookmarkExecute
    end
    object ActionBookmarksPreviousBookmark: TAction
      Category = 'Bookmarks'
      Caption = 'Previous bookmark'
      OnExecute = ActionBookmarksPreviousBookmarkExecute
    end
    object ActionMacroRecord: TAction
      Category = 'Macro'
      Caption = 'Record'
      ShortCut = 24658
      OnExecute = ActionMacroRecordExecute
    end
    object ActionMacroPause: TAction
      Category = 'Macro'
      Caption = 'Pause'
      ShortCut = 49232
      OnExecute = ActionMacroPauseExecute
    end
    object ActionMacroStop: TAction
      Category = 'Macro'
      Caption = 'Stop'
      ShortCut = 49234
      OnExecute = ActionMacroStopExecute
    end
    object ActionMacroPlay: TAction
      Category = 'Macro'
      Caption = 'Play'
      ShortCut = 24656
      OnExecute = ActionMacroPlayExecute
    end
    object ActionTestUndoRedo: TAction
      Category = 'Test'
      Caption = 'Test undo/redo'
      OnExecute = ActionTestUndoRedoExecute
    end
    object ActionTestSelectionInvariants: TAction
      Category = 'Test'
      Caption = 'Test selection invariants'
      OnExecute = ActionTestSelectionInvariantsExecute
    end
    object ActionTestSaveLoad: TAction
      Category = 'Test'
      Caption = 'Test save/load round-trip'
      OnExecute = ActionTestSaveLoadExecute
    end
    object ActionTestClipboardRoundTrip: TAction
      Category = 'Test'
      Caption = 'Test clipboard round-trip'
      OnExecute = ActionTestClipboardRoundTripExecute
    end
    object ActionTestMacro: TAction
      Category = 'Test'
      Caption = 'Test macro record/playback'
      OnExecute = ActionTestMacroExecute
    end
    object ActionTestHighlighterSweep: TAction
      Category = 'Test'
      Caption = 'Test highlighters and themes'
      OnExecute = ActionTestHighlighterSweepExecute
    end
  end
  object PrintDialog: TPrintDialog
    Left = 242
    Top = 238
  end
end
