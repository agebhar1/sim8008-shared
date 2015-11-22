object ASMProgressForm: TASMProgressForm
  Left = 292
  Top = 289
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Assemblieren'
  ClientHeight = 178
  ClientWidth = 420
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pMain: TPanel
    Left = 0
    Top = 0
    Width = 420
    Height = 137
    Align = alClient
    TabOrder = 0
    object Panel1: TPanel
      Left = 8
      Top = 8
      Width = 401
      Height = 24
      BevelOuter = bvLowered
      TabOrder = 0
      DesignSize = (
        401
        24)
      object LblrsProject: TLabel
        Left = 7
        Top = 6
        Width = 36
        Height = 13
        Caption = 'Projekt:'
      end
      object LblProject: TFilenameLabel
        Left = 81
        Top = 6
        Width = 317
        Height = 13
        Anchors = [akLeft, akTop, akRight]
        AutoSize = False
        Caption = 'LblProject'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
        MinimizeCaption = True
      end
    end
    object Panel2: TPanel
      Left = 8
      Top = 40
      Width = 401
      Height = 24
      BevelOuter = bvLowered
      TabOrder = 1
      object LblrsState: TLabel
        Left = 7
        Top = 6
        Width = 33
        Height = 13
        Caption = 'Status:'
      end
      object LblState: TLabel
        Left = 81
        Top = 6
        Width = 48
        Height = 13
        Caption = 'LblState'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
    end
    object Panel3: TPanel
      Left = 8
      Top = 72
      Width = 198
      Height = 24
      BevelOuter = bvLowered
      TabOrder = 2
      object LblrsLine: TLabel
        Left = 7
        Top = 6
        Width = 66
        Height = 13
        Caption = 'aktuelle Zeile:'
      end
      object LblLine: TLabel
        Left = 149
        Top = 6
        Width = 42
        Height = 13
        Alignment = taRightJustify
        Caption = 'LblLine'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
    end
    object Panel4: TPanel
      Left = 8
      Top = 104
      Width = 129
      Height = 24
      BevelOuter = bvLowered
      TabOrder = 3
      object LblrsErrors: TLabel
        Left = 7
        Top = 6
        Width = 32
        Height = 13
        Caption = 'Fehler:'
      end
      object LblErrors: TLabel
        Left = 72
        Top = 6
        Width = 51
        Height = 13
        Alignment = taRightJustify
        Caption = 'LblErrors'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
    end
    object Panel5: TPanel
      Left = 144
      Top = 104
      Width = 129
      Height = 24
      BevelOuter = bvLowered
      TabOrder = 4
      object LblrsWarnings: TLabel
        Left = 7
        Top = 6
        Width = 59
        Height = 13
        Caption = 'Warnungen:'
      end
      object LblWarnings: TLabel
        Left = 52
        Top = 6
        Width = 71
        Height = 13
        Alignment = taRightJustify
        Caption = 'LblWarnings'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
    end
    object Panel6: TPanel
      Left = 280
      Top = 104
      Width = 129
      Height = 24
      BevelOuter = bvLowered
      TabOrder = 5
      object LblrsHints: TLabel
        Left = 7
        Top = 6
        Width = 46
        Height = 13
        Caption = 'Hinweise:'
      end
      object LblHints: TLabel
        Left = 76
        Top = 6
        Width = 47
        Height = 13
        Alignment = taRightJustify
        Caption = 'LblHints'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
    end
    object Panel7: TPanel
      Left = 210
      Top = 72
      Width = 198
      Height = 24
      BevelOuter = bvLowered
      TabOrder = 6
      object LblrsSize: TLabel
        Left = 7
        Top = 6
        Width = 105
        Height = 13
        Caption = 'Speicherbedarf (Byte):'
      end
      object LblSize: TLabel
        Left = 151
        Top = 6
        Width = 42
        Height = 13
        Alignment = taRightJustify
        Caption = 'LblSize'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
    end
  end
  object BottomPanel: TPanel
    Left = 0
    Top = 137
    Width = 420
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object BtnOk: TButton
      Left = 176
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Ok'
      TabOrder = 0
      OnClick = BtnOkClick
    end
  end
  object Timer: TTimer
    Enabled = False
    Interval = 10
    OnTimer = TimerTimer
    Left = 8
    Top = 145
  end
end
