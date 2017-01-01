unit uEditForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, uResourceStrings, uView, EnhCtrls;

type
  TEditForm = class(TForm, ILanguage)
    pEdit: TPanel;
    sbOk: TSpeedButton;
    sbCancel: TSpeedButton;
    LblValue: TLabel;
    eeValue: TEnhancedEdit;
    procedure FormCreate(Sender: TObject);
    procedure sbOkClick(Sender: TObject);
    procedure sbCancelClick(Sender: TObject);
    procedure eValueKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure eeValueKeyPress(Sender: TObject; var Key: Char);
  private
    _Block: Boolean;
    _Radix: TRadix;
    _View: TView;
    _Bits: Byte;
    _Value: Word;
  public
    procedure LoadLanguage;
    function ShowModal(Radix: TRadix; View: TView; Bits: Byte): Integer; reintroduce; overload;
    function ShowModal(Radix: TRadix; View: TView; Bits: Byte; Position: TPoint): Integer; reintroduce; overload;
    property Value: Word read _Value write _Value;
  end;

var
  EditForm: TEditForm;

implementation

{$R *.dfm}

procedure TEditForm.FormCreate(Sender: TObject);
begin
  pEdit.Top:= 0;
  pEdit.Left:= 0;
  AutoSize:= true;
  _Block:= false;
  LoadLanguage;
end;

procedure TEditForm.sbOkClick(Sender: TObject);
var
  C: Boolean;
begin
  Value:= RadixToWord(eeValue.Text,_Radix,_View,C);
  if C then
    ModalResult:= mrOk
  else
    begin
      _Block:= true;
      MessageDlg(getString(rsNotANumber),mtError,[mbOk],0);
    end;  
end;

procedure TEditForm.sbCancelClick(Sender: TObject);
begin
  ModalResult:= mrCancel;
end;

procedure TEditForm.eeValueKeyPress(Sender: TObject; var Key: Char);
begin
  if (_Radix <> rDecimalNeg) and (_View = vLong) and (Key = '-') then Key:= #0;
  case _Radix of
    rOctal       : if not (Key in ['0'..'7','-',#8,#13,#27]) then Key:= #0;
    rDecimal     : if not (Key in ['0'..'9','-',#8,#13,#27]) then Key:= #0;
    rDecimalNeg  : if not (Key in ['0'..'9','-',#8,#13,#27]) then Key:= #0;
    rHexadecimal : if not (Key in ['0'..'9','A'..'F','a'..'f','-',#8,#13,#27]) then Key:= #0;
    rBinary      : if not (Key in ['0','1','-',#8,#13,#27]) then Key:= #0;
  end;                   
end;

procedure TEditForm.eValueKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if not _Block then
    begin
      if Key = VK_ESCAPE then
        begin
          sbCancelClick(Sender);
        end
      else
        if Key = VK_RETURN then
          begin
            sbOkClick(Sender);
          end;
    end
  else
    _Block:= false;
end;

procedure TEditForm.LoadLanguage;
begin
  LblValue.Caption:= ' '+getString(rsValue);
end;

function TEditForm.ShowModal(Radix: TRadix; View: TView; Bits: Byte): Integer;
var
  P: TPoint;
begin
  P.X:= (Screen.Width - Width) div 2;
  P.Y:= (Screen.Height - Height) div 2;
  result:= ShowModal(Radix,View,Bits,P);
end;

function TEditForm.ShowModal(Radix: TRadix; View: TView; Bits: Byte; Position: TPoint): Integer;
begin
  if Position.Y + Height > Screen.Height then
    Top:= Screen.Height - Height
  else
    Top:= Position.Y;
  if Position.X + Width > Screen.Width then
    Left:= Screen.Width - Width
  else
    Left:= Position.X;
  _Radix:= Radix;
  _View:= View;
  _Bits:= Bits;
  eeValue.Text:= WordToRadix(Value,_Radix,_View,_Bits);
  eeValue.SelectAll;
  result:= inherited ShowModal;
end;

end.
