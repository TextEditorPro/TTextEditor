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
  object StatusBar: TStatusBar
    Left = 0
    Top = 764
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
    AlignWithMargins = True
    Left = 3
    Top = 5
    Width = 68
    Height = 756
    Align = alLeft
    BevelOuter = bvNone
    Caption = 'PanelSidebar'
    ParentColor = True
    ShowCaption = False
    TabOrder = 1
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
      Top = 695
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
    Left = 74
    Top = 2
    Width = 1155
    Height = 762
    Align = alClient
    BevelOuter = bvNone
    ParentColor = True
    ShowCaption = False
    TabOrder = 2
    object ActionMainMenuBar: TActionMainMenuBar
      Left = 0
      Top = 0
      Width = 1155
      Height = 25
      ActionManager = ActionManager
      Caption = 'ActionMainMenuBar'
      Color = clMenuBar
      ColorMap.DisabledFontColor = 10461087
      ColorMap.HighlightColor = clWhite
      ColorMap.BtnSelectedFont = clBlack
      ColorMap.UnusedColor = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentBackground = True
      Spacing = 0
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
              00097048597300000EC300000EC301C76FA8640000001974455874536F667477
              617265005061696E742E4E455420352E312E313213014774000000B865584966
              49492A000800000005001A010500010000004A0000001B010500010000005200
              000028010300010000000200000031010200110000005A000000698704000100
              00006C00000000000000600000000100000060000000010000005061696E742E
              4E455420352E312E31320000030000900700040000003032333001A003000100
              00000100000005A0040001000000960000000000000002000100020004000000
              5239380002000700040000003031303000000000D9A79A95C9B70B5F000001FA
              494441545847ED97BF8A14411087BF9E3F78981CF8028289A11C1899DC238891
              208286971A19D42C6CD0B51BF8001718FB02223E808891A08991989D78894667
              E2EC4C1B6CCDB1DB33B337BB7797CD074DCFD6165DBFAA9A816AC706BCF78973
              2E365F441091101BB7C27BEF66B3591ADB87A2AA89AA26B1BD8B567ADE7B5714
              45B0E7DBCEB97DA08EFD7A48811311F9CD52482A2255ECB44A4B4083AA1E0347
              B17D03359000CF8177C05D11F9A4AAB98894B173C35A9954356399F991050FB6
              86D054A904F6810FAA7A2022A5AAE691EF399D7D72CE1DDAE36253957A4881BF
              B67F54D57B26228B1DE910D064DB64B36DF0861BB6DF04BEAAEA031159A86AEB
              C58E05EC1A70950A38037E013F8053E0B5AADE11912AFE3AD602AA6A664ADF00
              4FAC059DA5EBA0B2B2BF159187F19F7D5CA500AC850EF80C7C03726B670E9C00
              2FE3CF326EC1657116F03EF0CC92780A3CB6DF8E65A2E7895FB500ECCCDAAAB7
              00FE99FD4FE407D724003B375B59D8FBD1E2BA040C6614300A18058C024601A3
              803E014327E16DE89CB0FB046C33050D250D21B4E2B50CC677DB9BA1E232AB19
              487E164551CEE7F364F5EEB82620845001D475FD0AF802EC4583C52E6B0F380B
              21BCB0B3D7E6D0D618EEBD4F8AA2A8A7D3699E65D923E7DC2D9B785BBE037040
              59D7F5FBC96472AAAA89885C7CCFF4DEF7B56667BA2E2500FF01A1C9B7C70D87
              58BB0000000049454E44AE426082}
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
              52393800020007000400000030313030000000005D22B254A9C21AD800000436
              494441545847C5975D685C4514C77F33E9B68D31A26D6C0B566B1F4AD5F65554
              34BE08268222082258D0073F40102120F830B30AD93B8680E4412A42FB624A11
              94A0A2E4C1AA0F824410158D89B534D44685D6368942B38564B3333EE4CC32B9
              B9BBD9E043FF30CCDEFF9973EE99F331735739E7A680438007349B43D4396F8C
              D9EF9C7B18F85C64C78D312F3AE78E012F08D7678C39E59C3B07EC07A6B4BCBC
              9E18DCEC887A79B492451C8E3BEE909D6C766C11FDEB133B11DB733389BC2B12
              1A98FE1FE327E037E067B1B708CC00B332487ECF881C597F16F8459EAF1D9473
              EEA93CD90694E4F633797E4CB82073DB50CEB990273781BD32FF95E3DB86960E
              C88F15D94D442D27F3C052C22D09B7226B8BB05CF09EBA96CA4C47ACEE2A700C
              B80094844FD77448B855AE8B4AC0640861D87BFF7608E12830056C4DD6364651
              0A56C4818A31E6F52CCB8E28A54E267CCC731DB85574FE1483714D9F31E6546A
              D439F709F0B8E835DA55A78BC4F816A01E4238011042F814B898BCBC1562012A
              802CCB469D73D1CEAB224BCF8A750EC453EB0B6BEDCCE0E06057B95CBE028C09
              1F4FCC8D101D7D047832CBB21D2184AB5207A97C9D0381556F4701B4D66F5A6B
              5508E13D91AFF1BE0534C0E2E2E25E634CA7B5764129758FD4413D6DD5D48118
              FE4BD56AF5C32CCB0E2AA55EE9ECEC7CD45AFB033099F4FF460800DDDDDD879C
              73F7552A95EDD6DA8F81AF65138D48A60E44726C6868C82BA5E6800743083F0A
              7F42E6761CF0AC46F24B60426BFD91F01FC85C98820E56954ECA7300BE534A5D
              157E4C72584A749A21A6EA92CC1764BE4EE606A203312FDF5B6BBFCDB2AC5794
              2F020B59963D63AD9D05C665FD4651A80228A5EE564ADD608C794EF8E7656E6C
              3C9E035EC873DEFB27B4D6C3405FD2D793DEFB235AEBE3C0BD129D3A709BD8F9
              23B6AFECFE2DEFFD51A02B84B0A2B5DEA7947A03B83FB1B9C601122736425C57
              7410C5436A2334D6450722F1BB182BC973E4839CF1BB803BC4C84A410400CE48
              FA4A49B1F9A4836E91CFB10028E59C8BC285F9F9F95D2323232D0F1BE7DCAFC0
              9D5290B70B7D5E7AFCB431E6AE9CCA1A0C0C0CE89E9E9ECBC00E20E453302C5F
              38DBD25611076BC01EC0C827585104AA4026C59B4620DA589208BE16D35D7419
              B58BA21AD834F20EBC2FDF6ADB72ADA664C77B806725DC45115806469B5C5E5A
              227000783A92690DCC1B637A12854224FF238A6A60DA187338A7B20ECEB93960
              67BE0600BE914ED85A90BF1AB01B7848765314010F7C05FCDDA40696A5031E68
              90D7B006D6B5610D781938DDA20B7603EF4A0BD5807D229F951D2F002FB58840
              EC8277A23C75E05FEFFD8172B93C9728AD416F6FAFEAEFEF3F238554E4C0D989
              898983E3E3E34DA35AA954766AAD67801BA303F12252C015E07272AC462809F9
              4D326891827F6434B37133D02DB24611C6852A5168867817342BC276EE93C6FB
              B4FCC753D12331D26C84C4C9D4D9946BC746B433FD1FE5E8E115FE3F2DD40000
              000049454E44AE426082}
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
              52393800020007000400000030313030000000004F7059EA8E9783C800000495
              494441545847AD574D685D4514FECEBCBC97AA1825858AF5077F2848B6BAB016
              62DD99859B76115D15A4D0A081B48636F0CE14A199F320A5D6046B5A74212822
              484B16A575578D45BBAA0B09E21F9A45452295802098F7DEBDC745CE3C2737EF
              2669F083C3DC3B73FEE6CC39F343D80244A4424450552D8E6D0466CE4584ECFB
              8E643B101157ECDB0EA2234574ED8C1011C7CC7908E12011BD06A00640379153
              A37B001C01B0002063E676D49732972A12910A336766FC62717C8BD8678E8C30
              F34124938A0CA5E1255AF5CD660E002B00DAD6AE00681AC5EF2CA196C9E400FE
              02704044DEC77F79D1B15BEA409270B5A4BB0740AF51CD287E572CF49544AF4B
              BE0F179CA0A87033B4ADED05B00CE0B2AACE13D1EF66F8290043009E377D5922
              DBB22588382C22FD00862D27A8340209EEB5F61833F733F3210057B22CFB2DCF
              F31FB22C9B61E6FDAAFA0880CB4924A0AA03CCFC058017003C07E05900178C07
              D828092344E423559DF2DE2F88C8090023001E4F585A00BE52D5BAF7FE86888C
              0198B6B13F55759C88BE0350B59C70005698F9263673208450F3DE3727272777
              3AE76E00D8930CE7269FEA9861E6A30527BAE126333F2322AE74094208CE7BDF
              0C21DCEF9CFBD68C37CD306C2664E16E1B8D89C83433CFD872C0AA242F54C7DF
              D6965781738EB05A86E701EC3645B52E3294F4B5018C8510F6AA6A2CDF5EE349
              ABA313B5A232C0665FAFD7B310C20080976D96BD453E839A9E9EA898881ADEFB
              5B00E68D67CDEEB7A903449DEA18B2362DAD14310F3E57D5D124BBF79D3A756A
              0780CFECBFF420EAEA4004110D14FB0AC8B15A6E8BDEFB7701FC62FD55227A0C
              C0F76BD9D763430736087B440CF913F6DF492E55AD59D276F8BA6133076E153B
              0A88A1BD383131E1003C19079C734BAAFA60816F1DBA3A10CF0155BD5E1C4B90
              59E27DC3CCE7FAFAFA4E02B8DBC67EF5DE2F11D16041661DBA3A104F42EFFD15
              003F77D9E391C8EE12917700BC999C1B17AC7DC9DACED65BC49AC328844044E4
              9839139163AAFA89AABE4A445F9AC12C511637A187018CDA7AD700FCC4CCA745
              641C40BF39557AE8752260C62B66FC2880B344F481F7FEBAAABE9E6C2671D76B
              27BB5BCB8CFF91E7F9D3218447014C99EAD2D92375C066DE36CFDF36A52F8AC8
              79EFFDACAA0E26CB9152D5E853667E40552B44F4B519CE36AA004407E2F54B44
              DE0070C6EA3BAEFB88885C05F02333EF51D5FD0026017C08E03D551D55D5DDCC
              3C1C4218AA542A8B001E2A2C57295C7AF703F056E19473168921227AC5646EB7
              5A2D61E643CC7C44553F06B05744E689E82A80FBB66A1C005C97BB5F7420DE6E
              AB00C699793A84709A8816AAD5EAB2882C89C86DE7DC32115D023068B2F9568D
              A3A40C334BB078C81C67E6B3218429223A6E06EE02B00BC04E938909E94A7416
              D1D9985CBC7BAAEA39EBEBB5F58FC6CF98F1134952C5E844EAB99359A789E998
              396B341ACE7B3FA7AA07005C03704D5587CDF84933FE8FC9C430A714AFE39B51
              DCA89A585D76EA01807ABD9E371A0D57AFD7E700CC45EF0C8BD6EE28F46F0715
              AC467BD6DAB5351A1FA17110806EE369D60D51A6A9AAB3DEFB4BC5175229FEAF
              C7698A54E79666B2DDE779114444AA0A66CE62DFBF3D9E141A363EB52C000000
              0049454E44AE426082}
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
              52393800020007000400000030313030000000004F7059EA8E9783C8000003DD
              494441545847C557CF8B1C4514FE5ED5CC2CEC4A347A9478F0E2516421B088B9
              081E7491087A513C48FE815C7618A6ABA7EDEDD7C3B073F11F1095E0C9831272
              123C98200B8125E0CD8B8239EB829B44EC99AEE7A15F0D3DBFD6C9EEC47CD054
              77D7EBFEBE7A55AFDE2BC21991651919630000DE7BC4712CB336AB80665F9C06
              66B64444D6DAB2D3E94C110E06032ACBD28A8838E7CA7ADF695849409EE7B6D9
              6CFA76BB3D214DD374D35ABB050065593E4892E4EFD0371C0EA9280A1345D17F
              0A395500339331C674BBDD529FAF10D155003B005E02F08C9A3E00F01B804311
              B9E99CBB0300FD7EDF7AEFBD736EE9F42C15C0CC36B89299DF21A214C0F6ACDD
              12DC1591CC39770B33FF9AC54201E1835EAFD7D8D8D8F812C047DAE5F522BD0C
              801311791BC07344B40BE07D002FA8FD8DA228AEA5693ACAF3DC2E9A92390181
              7C7F7FFF82B5F6368057018CD5D6D64C45DF9D9465F962AFD73B41151D178D31
              D701381578CF7BFF661CC7C78B3C51C5918299C939572649D2AC9117001A33E4
              5320A22D548BB515C7F171144589885C06701FC06BC6981F9224693AE74A669E
              1AF49400A381DD6AB5BEA891B7EA364BE001404446CC4C799EB79C734722F27A
              10D16AB53E478D2360F290E7B9ED76BB2533EFEA9C8F57249F82734EA2282A54
              C47D11794F057ECCCCBBDD6EB7CCF37CE2CD898066B3E951B9F3537D35B73E1E
              073511470018D5BF63541EF6C1CE40175EBBDD1666BEA2A1E64F9BF355212223
              545BF56700FE00709999DFD8DBDB1366B608028888B4BDAADF4E149E07CE39C9
              F3BC11C7F131806F5071BCAB2D2108B0D686D0D8D1F65CEE5F0411F95E6F7750
              E334599651A7D391344D37757BC56C749C072212BCF98BB62FA769BAD9E97444
              336AC5A58925ECED6B838808AA75F027807F005C0849CC18B3BE919E15C6FBCA
              4365593ED4ACB6564C169B31CF03D800F09772C17B0F13C7B10C06034A92E411
              80DFF5BBB544012A01C1CBAF68FB6B92248F068301C5712C06D5E843CC1F6ABB
              347F9F1544F496DE1EA2C669505B2822F29D1AAD656D3033455134CEB2EC2280
              0F5071DCD45610889C73E5C1C10139E76E0338D2F773B9FB7141444D54F37F5D
              6B84BBCEB93BC3E190425A9E8C74341A056F845C70AE69C8F3BC154551C1CCDB
              5A1B40443200288A62C23BB989A2A8ECF7FB56CBA8AFB5062842FFAA08E958C9
              2F11D1B7CA73C33977ABDFEF4F55465373ED35268BA2F804C0CF9A8E571161A0
              2E0FE99899B789E827009700DC2B8AE21A6A1C01737B7EAD247BD65AFBE3932E
              C9E60460BE28FD0AC087DAF5E48BD28099B27C570B95FFA72C0F78AA07933A96
              1DCD1A8DC616008CC7E387BA9503EB3C9ACDE2A91D4E17615DC7F37F01F6562A
              50DD98E71D0000000049454E44AE426082}
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
  end
end
