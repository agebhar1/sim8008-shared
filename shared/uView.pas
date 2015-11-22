unit uView;

interface

uses
  Windows, SysUtils, Classes, Math;

type

  TRadix = (rDecimal, rDecimalNeg, rOctal, rHexadecimal, rBinary);
  TView = (vLong, vShort);

  IRadixView = interface(IInterface)
    procedure RadixChange(Radix: TRadix; View: TView);
  end;

  TViewList = class(TObject)
  private
    _List: TInterfaceList;
    _Radix: TRadix;
    _View: TView;
    procedure setRadix(Value: TRadix);
    procedure setView(Value: TView);
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddListener(Listener: IRadixView);
    procedure DelListeners;
    procedure Update;
    property Radix: TRadix read _Radix write setRadix;
    property View: TView read _View write setView; 
  end;  

  function WordToRadix(Value: Word; Radix: TRadix; View: TView; Bits: Byte): String;
  function RadixToWord(Value: String; Radix: TRadix; View: TView; var C: Boolean): Word;

implementation

uses
  uAssembler;
{ ********* TViewList ******** }
procedure TViewList.setRadix(Value: TRadix);
begin
  _Radix:= Value;
  Update;
end;

procedure TViewList.setView(Value: TView);
begin
  _View:= Value;
  Update;
end;

constructor TViewList.Create;
begin
  inherited Create;
  _List:= TInterfaceList.Create;
  _Radix:= rOctal;
  _View:= vShort;
end;

destructor TViewList.Destroy;
begin
  DelListeners;
  _List.Free;
  inherited Destroy;
end;

procedure TViewList.AddListener(Listener: IRadixView);
begin
  if Assigned(Listener) then
    begin
      _List.Add(Listener);
      Listener.RadixChange(Radix,View);
    end;
end;

procedure TViewList.DelListeners;
begin
  if Assigned(_List) then
    _List.Clear;
end;

procedure TViewList.Update;
var
  i: Integer;
  Listener: IRadixView;
begin
  for i:= 0 to _List.Count-1 do
    begin
      Listener:= IRadixView(_List.Items[i]);
      if Assigned(Listener) then
        Listener.RadixChange(Radix,View);
    end;
end;
{ ********* TViewList ******** }

function WordToRadix(Value: Word; Radix: TRadix; View: TView; Bits: Byte): String;
const
  Dec: array [0.. 9] of Char = ('0','1','2','3','4','5','6','7','8','9');
  Oct: array [0.. 7] of Char = ('0','1','2','3','4','5','6','7');
  Hex: array [0..15] of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
  Bin: array [0..1]  of Char = ('0','1');

var
  Max, Maske: Word;
  Negative: Boolean;

  function getMax(Radix: TRadix; Bits: Byte): Byte;
  begin
    case Radix of
      rDecimal     : result:= Ceil(Log10(Power(2,Bits)));
      rDecimalNeg  : result:= Ceil(Log10(Power(2,Bits-1)));
      rOctal       : result:= Ceil(Log10(Power(2,Bits))/Log10(8));
      rHexadecimal : result:= Ceil(Log10(Power(2,Bits))/Log10(16));
      else           result:= Bits;
    end;
  end;

begin
  if View = vShort then
    begin
      // 'Low'
      result:= WordToRadix(Value and 255,Radix,vLong,8);
      // 'High'
      Value:= Value shr 8;
      if (Bits-8) > 0 then
        result:= WordToRadix(Value and 255,Radix,vLong,Bits-8) +
                 '-' + result;
    end
  else
    case Radix of
      rDecimal     : begin
                       Max:= getMax(Radix,Bits);
                       result:= '';
                       repeat
                         result:= Dec[Value mod 10] + result;
                         Value:= Value div 10;
                       until Value = 0;
                       while Length(result) < Max do
                         result:= '0' + result;
                     end;
      rDecimalNeg  : begin
                       Max:= getMax(Radix,Bits);
                       Maske:= Round(Power(2, Bits-1));
                       Negative:= (Value and Maske) = Maske;
                       if Negative then begin
                         Value:= (not Value) and (Maske-1);
                         Value:= Value + 1;
                       end;
                       result:= '';
                       repeat
                         result:= Dec[Value mod 10] + result;
                         Value:= Value div 10;
                       until Value = 0;
                       while Length(result) < Max do result:= '0' + result;
                       if Negative then result:= '-' + result;
                     end;
      rOctal       : begin
                       Max:= getMax(Radix,Bits);
                       result:= '';
                       repeat
                         result:= Oct[Value mod 8] + result;
                         Value:= Value div 8;
                       until Value = 0;
                       while Length(result) < Max do
                         result:= '0' + result;
                     end;
      rHexadecimal : begin
                       Max:= getMax(Radix,Bits);
                       result:= '';
                       repeat
                         result:= Hex[Value mod 16] + result;
                         Value:= Value div 16;
                       until Value = 0;
                       while Length(result) < Max do
                         result:= '0' + result;
                     end;
      rBinary      : begin
                       Max:= getMax(Radix,Bits);
                       result:= '';
                       repeat
                         result:= Bin[Value mod 2] + result;
                         Value:= Value div 2;
                       until Value = 0;
                       while Length(result) < Max do
                         result:= '0' + result;
                     end;
    end;
end;

function RadixToWord(Value: String; Radix: TRadix; View: TView; var C: Boolean): Word;
var
  iPos, iC: Integer;
  C1, C2, Negative: Boolean;
begin
  C:= false;
  if View = vShort then begin
    iPos:= Pos('-',Value);
    if iPos >= 0 then begin
      // 'High'
      result:= RadixToWord(Copy(Value,1,iPos-1),Radix,vLong,C1);
      // 'Low'
      result:= result * 256 +
               RadixToWord(Copy(Value,iPos+1,Length(Value)),Radix,vLong,C2);
      C:= C1 and C2;
    end else result:= RadixToWord(Value,Radix,vLong,C);
  end else case Radix of
    rDecimal     : begin
                     result:= IntToInt(Value,iC);
                     C:= iC = 0;
                   end;
    rDecimalNeg  : begin
                     iPos:= Pos('-',Value);
                     Negative:= iPos = 1;
                     if Negative then Delete(Value, 1, 1);
                     result:= IntToInt(Value,iC);
                     if Negative then result:= (not result) + 1;
                     C:= iC = 0;
                   end;
    rOctal       : begin
                     result:= OctToInt(Value,iC);
                     C:= iC = 0;
                   end;
    rHexadecimal : begin
                     result:= HexToInt(Value,iC);
                     C:= iC = 0;
                   end;
    else           begin
                     result:= BinToInt(Value,iC);
                     C:= iC = 0;
                   end
  end;
end;

end.
