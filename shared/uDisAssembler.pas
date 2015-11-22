unit uDisAssembler;

interface

uses
  Windows, SysUtils, Classes, uAssembler, uProcessor, uView;

type

  Ti8008DisAssembler = class(TObject)
  private
    _i8008: Ti8008Processor;
    _InstructionCount: Word;
    _ProgramCounter: Word;
    _Radix: TRadix;
    _View: TView;
    procedure IncProgramCounter;
  public
    constructor Create;
    procedure Disassemble(var SourceCode: TStringList);
    property Radix: TRadix read _Radix write _Radix;
    property View: TView read _View write _View;
    property Processor: Ti8008Processor read _i8008 write _i8008;
    property InstructionCount: Word read _InstructionCount write _InstructionCount;
  end;

implementation

{ ******** Ti8008DisAssembler ****** }
procedure Ti8008DisAssembler.IncProgramCounter;
begin
  Inc(_ProgramCounter);
  _ProgramCounter:= _ProgramCounter mod 16384;
end;

constructor Ti8008DisAssembler.Create;
begin
  inherited Create;
  _i8008:= nil;
  _InstructionCount:= 6;
  _ProgramCounter:= 0;
  _Radix:= rOctal;
  _View:= vShort;
end;

procedure Ti8008DisAssembler.Disassemble(var SourceCode: TStringList);
const
  RegisterStr: array [0..7] of String = ('A','B','C','D','E','H','L','M(HL)');

var
  Instruction: Byte;
  bValue: Byte;
  wValue: Word;
  Halt: Boolean;

begin
  if Assigned(SourceCode) and Assigned(_i8008) then
    begin
      SourceCode.Clear;
      _ProgramCounter:= _i8008.ProgramCounter;
      while  SourceCode.Count < InstructionCount do
        begin
          Instruction:= _i8008.RAM[_ProgramCounter];
          Halt:= Instruction in CODE_HLT;                           { HLT }
          IncProgramCounter; // !! Disassamble all Instructions
          if not Halt then
            begin
              if Instruction < 64 then      { [000,100) }
                begin
                  { INR }
                  if Instruction in CODE_INR then                   { INR }
                    SourceCode.Add('INR '+RegisterStr[(Instruction div 8) mod 8])
                  else
                    if Instruction in CODE_DCR then                 { DCR }
                      SourceCode.Add('DCR '+RegisterStr[((Instruction - 1) div 8) mod 8])
                    else
                      if (Instruction mod 8) = 3 then
                        begin
                          case (Instruction div 8) mod 8 of
                            0: SourceCode.Add('RNC');               { RNC }
                            1: SourceCode.Add('RNZ');               { RNZ }
                            2: SourceCode.Add('RP');                { RP  }
                            3: SourceCode.Add('RPO');               { RPO }
                            4: SourceCode.Add('RC');                { RC  }
                            5: SourceCode.Add('RZ');                { RZ  }
                            6: SourceCode.Add('RM');                { RM  }
                            7: SourceCode.Add('RPE');               { RPE }
                          end;
                        end
                      else
                        if (Instruction mod 8) = 2 then
                          begin
                            case (Instruction div 8) mod 8 of
                              0: SourceCode.Add('RLC');             { RLC }
                              1: SourceCode.Add('RRC');             { RRC }
                              2: SourceCode.Add('RAL');             { RAL }
                              3: SourceCode.Add('RAR');             { RAR }
                            end;
                          end
                        else
                          if (Instruction mod 8) = 4 then
                            begin
                              bValue:= _i8008.RAM[_ProgramCounter];
                              IncProgramCounter;
                              case (Instruction div 8) mod 8 of
                                0: SourceCode.Add('ADI '+WordToRadix(bValue,_Radix,vLong,8)); { ADI }
                                1: SourceCode.Add('ACI '+WordToRadix(bValue,_Radix,vLong,8)); { ACI }
                                2: SourceCode.Add('SUI '+WordToRadix(bValue,_Radix,vLong,8)); { SUI }
                                3: SourceCode.Add('SBI '+WordToRadix(bValue,_Radix,vLong,8)); { SBI }
                                4: SourceCode.Add('ANI '+WordToRadix(bValue,_Radix,vLong,8)); { ANI }
                                5: SourceCode.Add('XRI '+WordToRadix(bValue,_Radix,vLong,8)); { XRI }
                                6: SourceCode.Add('ORI '+WordToRadix(bValue,_Radix,vLong,8)); { ORI }
                                7: SourceCode.Add('CPI '+WordToRadix(bValue,_Radix,vLong,8)); { CPI }
                              end;
                            end
                          else
                            if (Instruction mod 8) = 5 then
                              SourceCode.Add('RST '+WordToRadix(Instruction-5,_Radix,_View,14)){ RST }
                            else
                              if (Instruction mod 8) = 6 then       { MVI }
                                begin
                                  bValue:= _i8008.RAM[_ProgramCounter];
                                  IncProgramCounter;
                                  SourceCode.Add('MVI '+RegisterStr[(Instruction-6) div 8]+', '+WordToRadix(bValue,_Radix,vLong,8));
                                end
                              else
                                if (Instruction mod 8) = 7 then
                                  SourceCode.Add('RET');            { RET }
                end                         { [000,100) }
              else
                if Instruction < 128 then   { [100,200) }
                  begin
                    if Instruction in CODE_JMP then
                      begin
                        wValue:= _i8008.RAM[_ProgramCounter];
                        IncProgramCounter;
                        wValue:= _i8008.RAM[_ProgramCounter] * 256 + wValue;
                        IncProgramCounter;
                        SourceCode.Add('JMP '+WordToRadix(wValue,_Radix,_View,14));            { JMP }
                      end
                    else
                      if Instruction in CODE_CALL then
                        begin
                          wValue:= _i8008.RAM[_ProgramCounter];
                          IncProgramCounter;
                          wValue:= _i8008.RAM[_ProgramCounter] * 256 + wValue;
                          IncProgramCounter;
                          SourceCode.Add('CALL '+WordToRadix(wValue,_Radix,_View,14));         { CALL }
                        end
                      else
                        begin
                          Instruction:= Instruction and 63;
                          if (Instruction mod 8) in [1,3,5,7] then
                            begin
                              bValue:= (Instruction - 1) div 2;
                              if bValue < 8 then
                                SourceCode.Add('IN '+WordToRadix(bValue,_Radix,vLong,3))                         { IN  }
                              else
                                SourceCode.Add('OUT '+WordToRadix(bValue,_Radix,vLong,5));                       { OUT }
                            end
                          else
                            if (Instruction mod 8) = 0 then
                              begin
                                wValue:= _i8008.RAM[_ProgramCounter];
                                IncProgramCounter;
                                wValue:= _i8008.RAM[_ProgramCounter] * 256 + wValue;
                                IncProgramCounter;
                                case (Instruction div 8) mod 8 of
                                  0: SourceCode.Add('JNC '+WordToRadix(wValue,_Radix,_View,14));                 { JNC }
                                  1: SourceCode.Add('JNZ '+WordToRadix(wValue,_Radix,_View,14));                 { JNZ }
                                  2: SourceCode.Add('JP '+WordToRadix(wValue,_Radix,_View,14));                  { JP  }
                                  3: SourceCode.Add('JPO '+WordToRadix(wValue,_Radix,_View,14));                 { JPO }
                                  4: SourceCode.Add('JC '+WordToRadix(wValue,_Radix,_View,14));                  { JC  }
                                  5: SourceCode.Add('JZ '+WordToRadix(wValue,_Radix,_View,14));                  { JZ  }
                                  6: SourceCode.Add('JM '+WordToRadix(wValue,_Radix,_View,14));                  { JM  }
                                  7: SourceCode.Add('JPE '+WordToRadix(wValue,_Radix,_View,14));                 { JPE }
                                end;
                              end
                            else
                              if (Instruction mod 8) = 2 then
                                begin
                                  wValue:= _i8008.RAM[_ProgramCounter];
                                  IncProgramCounter;
                                  wValue:= _i8008.RAM[_ProgramCounter] * 256 + wValue;
                                  IncProgramCounter;
                                  case (Instruction div 8) mod 8 of
                                    0: SourceCode.Add('CNC '+WordToRadix(wValue,_Radix,_View,14));               { CNC }
                                    1: SourceCode.Add('CNZ '+WordToRadix(wValue,_Radix,_View,14));               { CNZ }
                                    2: SourceCode.Add('CP '+WordToRadix(wValue,_Radix,_View,14));                { CP  }
                                    3: SourceCode.Add('CPO '+WordToRadix(wValue,_Radix,_View,14));               { CPO }
                                    4: SourceCode.Add('CC '+WordToRadix(wValue,_Radix,_View,14));                { CC  }
                                    5: SourceCode.Add('CZ '+WordToRadix(wValue,_Radix,_View,14));                { CZ  }
                                    6: SourceCode.Add('CM '+WordToRadix(wValue,_Radix,_View,14));                { CM  }
                                    7: SourceCode.Add('CPE '+WordToRadix(wValue,_Radix,_View,14));               { CPE }
                                  end;
                                end;
                        end;
                  end                       { [100,200) }
                else
                  if Instruction < 192 then { [200,300) }
                    begin
                      Instruction:= Instruction and 63;
                      case (Instruction div 8) mod 8 of
                        0: SourceCode.Add('ADD '+RegisterStr[Instruction mod 8]);                                { ADD }
                        1: SourceCode.Add('ADC '+RegisterStr[Instruction mod 8]);                                { ADC }
                        2: SourceCode.Add('SUB '+RegisterStr[Instruction mod 8]);                                { SUB }
                        3: SourceCode.Add('SBB '+RegisterStr[Instruction mod 8]);                                { SBB }
                        4: SourceCode.Add('ANA '+RegisterStr[Instruction mod 8]);                                { ANA }
                        5: SourceCode.Add('XRA '+RegisterStr[Instruction mod 8]);                                { XRA }
                        6: SourceCode.Add('ORA '+RegisterStr[Instruction mod 8]);                                { ORA }
                        7: SourceCode.Add('CMP '+RegisterStr[Instruction mod 8]);                                { CMP }
                      end;
                    end                     { [200,300) }
                  else
                    begin                   { [300,377] }           { MOV }
                      Instruction:= Instruction and 63;
                      SourceCode.Add('MOV '+RegisterStr[(Instruction div 8) mod 8]+', '+RegisterStr[Instruction mod 8]);
                    end;
            end { if not HLT then }
          else
            SourceCode.Add('HLT');
        end;
    end;
end;
{ ******** Ti8008DisAssembler ****** }

end.
