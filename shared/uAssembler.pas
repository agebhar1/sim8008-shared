unit uAssembler;

interface

uses
  Windows, SysUtils, Classes;

const
  _maxSymbolLength = 15;

type

  TrippleByte = record
    V0: Byte;
    V1: Byte;
    V2: Byte;
  end;

  TASMStartEvent = procedure(Sender: TObject) of object;
  TASMProgressEvent = procedure(Sender: TObject; Errors: Integer; Warnings: Integer;
                                                 Hints: Integer; Line: Integer;
                                                 genCode: Boolean) of object;
  TASMStopEvent = procedure(Sender: TObject; Size: Integer; Errors: Boolean) of object;
  TItemInsertEvent = procedure(Sender: TObject; Index: Integer) of object;
  TItemDeleteEvent = procedure(Sender: TObject; Index: Integer) of object;
  TItemUpdateEvent = procedure(Sender: TObject; Index: Integer) of object;

  TSymbolItem = class(TObject)
  private
    _Line: Integer;
    _Name: String;
    _Value: Integer;
    _Defined: Boolean;
    procedure setValue(Value: Integer);
  public
    constructor Create(Name: String; Line: Integer); overload;
    constructor Create(Name: String; Value: Integer; Line: Integer); overload;
    property Name: String read _Name;
    property Value: Integer read _Value write setValue;
    property Defined: Boolean read _Defined;
    property Line: Integer read _Line;
  end;

  TSymbolList = class(TList)
  private
    _CaseSensitive: Boolean;
    _OnItemInsert: TItemInsertEvent;
    _OnItemDelete: TItemDeleteEvent;
    function getItem(Index: Integer): TSymbolItem;
  public
    constructor Create;overload;
    constructor Create(isCaseSensitive: Boolean);overload;
    function Add(Item: TSymbolItem): Integer;
    function Insert(Index: Integer; Item: TSymbolItem): Integer;
    procedure Delete(Index: Integer);
    procedure Clear; override;
    function Find(Name: String; var found: Boolean): Integer;
    function FindItem(Name: String): TSymbolItem;
    function AllItemsDefined: Boolean;
    property CaseSensitive: Boolean read _CaseSensitive;
    property Items[Index: Integer]: TSymbolItem read getItem;
    property OnItemInsert: TItemInsertEvent read _OnItemInsert write _OnItemInsert;
    property OnItemDelete: TItemDeleteEvent read _OnItemDelete write _OnItemDelete;
  end;

  TErrorItemState = (isError, isHint, isWarning, isFatalError, isUndefined);

  TErrorItem = class(TObject)
  private
    _State: TErrorItemState;
    _Line: Integer;
    _Text: String;
  public
    constructor Create(Text: String; Line: Integer; State: TErrorItemState);
    property Text: String read _Text;
    property Line: Integer read _Line;
    property State: TErrorItemState read _State;
  end;

  TErrorList = class(TList)
  private
    _FatalErrors: Integer;
    _Errors: Integer;
    _Hints: Integer;
    _Warnings: Integer;
    _OnItemInsert: TItemInsertEvent;
    _OnItemDelete: TItemDeleteEvent;
    procedure setItem(Index: Integer; Value: TErrorItem);
    function getItem(Index: Integer): TErrorItem;
  public
    constructor Create;
    function Add(Item: TErrorItem): Integer;
    function Insert(Index: Integer; Item: TErrorItem): Integer;
    procedure Delete(Index: Integer);
    procedure Clear; override;
    property FatalErrors: Integer read _FatalErrors;
    property Errors: Integer read _Errors;
    property Warnings: Integer read _Warnings;
    property Hints: Integer read _Hints;
    property Items[Index: Integer]: TErrorItem read getItem write setItem;
    property OnItemInsert: TItemInsertEvent read _OnItemInsert write _OnItemInsert;
    property OnItemDelete: TItemDeleteEvent read _OnItemDelete write _OnItemDelete;
  end;

  TProgramItem = class(TObject)
  private
    _Address: Word;
    _Value: Byte;
    _Link: Integer;
    constructor Create; overload;
  public
    constructor Create(Address: Word; Value: Byte; Link: Integer); overload;
    function LoadFromStream(AStream: TStream): Boolean;
    function SaveToStream(AStream: TStream): Boolean;
    property Address: Word read _Address;
    property Value: Byte read _Value write _Value;
    property Link: Integer read _Link write _Link;
  end;

  TProgram = class(TList)
  private
    _FOnItemInsert: TItemInsertEvent;
    _FOnItemDelete: TItemDeleteEvent;
    _FOnItemUpdate: TItemUpdateEvent;
    function getItem(Index: Integer): TProgramItem;
  public
    function Add(Item: TProgramItem): Integer;
    function Insert(Index: Integer; Item: TProgramItem): Integer;
    procedure Delete(Index: Integer);
    procedure Clear; override;
    function Find(Address: Integer; var found: Boolean): Integer;
    function FindItem(Address: Integer): TProgramItem;
    function LoadFromStream(AStream: TStream): Boolean;
    function SaveToStream(AStream: TStream): Boolean;
    property Items[Index: Integer]: TProgramItem read getItem;
    property OnItemInsert: TItemInsertEvent read _FOnItemInsert write _FOnItemInsert;
    property OnItemDelete: TItemDeleteEvent read _FOnItemDelete write _FOnItemDelete;
    property OnItemUpdate: TItemUpdateEvent read _FOnItemUpdate write _FOnItemUpdate;
  end;

  TScanner = class(TObject)
  protected
    _Sourcecode: String;
    _LexemStr: String;
    _SymbolList: TSymbolList;
    _Position: Integer;
    _LexemLine: Integer;
    _LexemValue: Integer;
  public
    constructor Create(SymbolList: TSymbolList); virtual;
    procedure Initialize(Sourcecode: String); virtual;
    procedure Reset;virtual;
    function Lexem: Integer;virtual;
    property Line: Integer read _LexemLine;
    property Position: Integer read _Position;
    property Value: Integer read _LexemValue;
    property SubStr: String read _LexemStr;
  end;

  Ti8008Scanner = class(TScanner)
  public
    function Lexem: Integer;override;
  end;

  TParser = class(TObject)
  protected
    _Program: TProgram;
    _Scanner: TScanner;
    _SymbolList: TSymbolList;
    _ErrorList: TErrorList;
    _genCode: Boolean;                     // generate Code
    _ILC: LongWord;                        // Instruction Location Counter
    _Line: Integer;
    _Lookahead: Integer;
    _Value: Integer;
    _OnItemUpdate: TItemUpdateEvent;
    _ASMStart: TASMStartEvent;
    _ASMProgress: TASMProgressEvent;
    _ASMStop: TASMStopEvent;
    procedure Init(genCode: Boolean);
    procedure addFatalError(FatalError: String);
    procedure addError(Error: String);
    procedure addHint(Hint: String);
    procedure addUndefined(Undifined: String);overload;
    procedure addUndefined(Undifined: String; Line: Integer);overload;
    procedure addWarning(Warning: String); overload;
    procedure addWarning(Warning: String; Line: Integer); overload;
    procedure ItemUpdateEvent(Sender: TObject; Index: Integer);
  public
    constructor Create(SymbolList: TSymbolList; Scanner: TScanner;
                       ErrorList: TErrorList);virtual;
    function Parse(theProgram: TProgram): Boolean;virtual;
    function MaxILC: Integer;virtual;
    property OnASMStart: TASMStartEvent read _ASMStart write _ASMStart;
    property OnASMProgress: TASMProgressEvent read _ASMProgress write _ASMProgress;
    property OnASMStop: TASMStopEvent read _ASMStop write _ASMStop;
  end;

  Ti8008Parser = class(TParser)
  protected
    function generateCode(var Check: Boolean; Oc, Op1, Op2: Integer): TrippleByte;
    function i8008Program: Boolean;
    procedure i8008Stmt;
    function i8008Instruction(var ILCtmp: LongWord): Boolean;
    procedure i8008Optional_instruction(var ILCtmp: LongWord);
    function Opcode_Type_0_0: Boolean;
    function Opcode_Type_1_0: Boolean;
    function Opcode_Type_1_1: Boolean;
    function Opcode_Type_1_2: Boolean;
    function Opcode_Type_1_3: Boolean;
    function Opcode_Type_1_4: Boolean;
    function Opcode_Type_1_5: Boolean;
    function Opcode_Type_1_6(var ILCtmp: LongWord): Boolean;
    function Opcode_Type_2_0: Boolean;
    function Opcode_Type_2_1: Boolean;
  public
    function Parse(theProgram: TProgram): Boolean;override;
    function MaxILC: Integer;override;
  end;

  TAssembler = class(TObject)
  private
    _Scanner: TScanner;
    _Parser: TParser;
    _Error: TErrorList;
    _Symbol: TSymbolList;
    _ShowProgress: Boolean;
  public
    constructor Create;overload;
    constructor Create(CaseSensitive: Boolean);overload;
    destructor Destroy; override;
    function Assemble(Source: String; theProgram: TProgram; Project: String): Boolean;
    property ErrorList: TErrorList read _Error;
    property ShowProgress: Boolean read _ShowProgress write _ShowProgress;
    property SymbolList: TSymbolList read _Symbol;
  end;

  Ti8008Assembler = class(TAssembler)
  public
    constructor Create;overload;
    constructor Create(CaseSensitive: Boolean);overload;
  end;

  function IntToInt(Value: String; var Check: Integer): Integer;
  function OctToInt(Value: String; var Check: Integer): Integer;
  function HexToInt(Value: String; var Check: Integer): Integer;
  function BinToInt(Value: String; var Check: Integer): Integer;

const  
  CODE_RNC = 3;
  CODE_RC  = 35;
  CODE_RM  = 51;
  CODE_RP  = 19;
  CODE_RPO = 27;
  CODE_RPE = 59;
  CODE_RZ  = 43;
  CODE_RNZ = 11;
  CODE_RLC = 2;
  CODE_RAR = 26;
  CODE_RRC = 10;
  CODE_RAL = 18;
  CODE_IN  = 65;
  CODE_OUT = 65;
  CODE_ADC = 136;
  CODE_XRA = 168;
  CODE_CMP = 184;
  CODE_SBB = 152;
  CODE_SUB = 144;
  CODE_ORA = 176;
  CODE_ANA = 160;
  CODE_ADD = 128;
  CODE_MOV = 192;
  CODE_RST = 5;
  CODE_ADI = 4;
  CODE_ANI = 36;
  CODE_ORI = 52;
  CODE_SUI = 20;
  CODE_SBI = 28;
  CODE_CPI = 60;
  CODE_XRI = 44;
  CODE_ACI = 12;
  CODE_MVI = 6;
  CODE_CNC = 66;
  CODE_CC  = 98;
  CODE_CM  = 114;
  CODE_CP  = 82;
  CODE_CPO = 90;
  CODE_CPE = 122;
  CODE_CZ  = 106;
  CODE_CNZ = 74;
  CODE_JNC = 64;
  CODE_JC  = 96;
  CODE_JM  = 112;
  CODE_JP  = 80;
  CODE_JPO = 88;
  CODE_JPE = 120;
  CODE_JZ  = 104;
  CODE_JNZ = 72;

  CODE_INR = [8,16,24,32,40,48];
  CODE_DCR = [9,17,25,33,41,49];
  CODE_HLT = [0,1,34,42,50,56,57,58,255];
  CODE_RET = [7,15,23,31,39,47,55,63];
  CODE_CALL= [70,78,86,94,102,110,118,126];
  CODE_JMP = [68,76,84,92,100,108,116,124];

implementation

uses
  uResourceStrings, uASMProgress;

const
  { ** helpful Char - Sets ** }
  CONTROL_CHARS = [#0..#32];
  BREAK_CHAR = [#9,#32];
  NEWLINE_CHAR = [#10,#13];
  NEWLINE = #10;
  DIGITS = ['0'..'9'];
  HEX = ['A'..'F','a'..'f'] + DIGITS;
  OCT = ['0'..'7'];
  BIN = ['0','1'];
  ALPHA = ['A'..'Z','a'..'z'];
  ALPHAEX = ALPHA + ['_'];
  { ** Scanner Values ** }
  S_A = 1;         { Register A - 0 }
  S_ACI = 2;
  S_ADC = 3;
  S_ADD = 4;
  S_ADI = 5;
  S_ANA = 6;
  S_ANI = 7;
  S_B = 8;         { Register B - 1 }
  S_C = 9;         { Register C - 2 }
  S_CALL = 10;
  S_CC = 11;
  S_CM = 12;
  S_CMP = 13;
  S_CNC = 14;
  S_CNZ = 15;
  S_CP = 16;
  S_CPE = 17;
  S_CPI = 18;
  S_CPO = 19;
  S_CZ = 20;
  S_D = 21;        { Register D - 3 }
  S_DCR = 22;
  S_E = 23;        { Register E - 4 }
  S_END = 24;      { Assembler Option }
  S_EQU = 25;      { Assembler Option }
  S_H = 26;        { Register H - 5 }
  S_HLT = 27;
  S_IN = 28;
  S_INR = 29;
  S_JC = 30;
  S_JM = 31;
  S_JMP = 32;
  S_JNC = 33;
  S_JNZ = 34;
  S_JP = 35; 
  S_JPE = 36;
  S_JPO = 37;
  S_JZ = 38;
  S_L = 39;        { Register L - 6 }
  S_M = 40;        { Register M - 7 }
  S_MOV = 41;
  S_MVI = 42;
  S_MHL = 43;      { Register M - 7 }
  S_ORA = 44;
  S_ORG = 45;      { Assembler Option }
  S_ORI = 46;
  S_OUT = 47;
  S_RAL = 48;
  S_RAR = 49;
  S_RC = 50;
  S_RET = 51;
  S_RLC = 52;
  S_RM = 53;
  S_RNC = 54;
  S_RNZ = 55;
  S_RP = 56;
  S_RPE = 57;
  S_RPO = 58;
  S_RRC = 59;
  S_RST = 60;
  S_RZ = 61;
  S_SBB = 62;
  S_SBI = 63;
  S_SUB = 64;
  S_SUI = 65;
  S_XRA = 66;
  S_XRI = 67;
  S_ID = 68;       { Identifier }
  S_LBL = 69;      { Label }
  S_POINT = 70;    { ',' }
  S_DEC = 71;
  S_OCT = 72;
  S_BIN = 73;
  S_HEX = 74;
  { **  Scanner Sets  ** }
  S_NUMBER = [S_DEC,S_OCT,S_BIN,S_HEX];
  S_REGISTER = [S_A,S_B,S_C,S_D,S_E,S_H,S_L,S_M,S_MHL]; { Register }
  { **   Opcode Sets  ** }
  OC_TYPE_0_0 = [S_HLT,S_RLC,S_RAL,S_RAR,S_RRC,S_RNC,S_RC,
                 S_RM,S_RP,S_RPO,S_RPE,S_RZ,S_RNZ,S_RET];
  OC_TYPE_1_0 = [S_ADC,S_XRA,S_CMP,S_SBB,S_SUB,S_ORA,S_ANA,S_ADD];
  OC_TYPE_1_1 = [S_INR,S_DCR];
  OC_TYPE_1_2 = [S_ADI,S_ANI,S_ORI,S_SUI,S_SBI,S_CPI,S_XRI,S_ACI];
  OC_TYPE_1_3 = [S_RST];
  OC_TYPE_1_4 = [S_IN];
  OC_TYPE_1_5 = [S_OUT];
  OC_TYPE_1_6 = [S_CNC,S_CC,S_CM,S_CP,S_CPO,S_CPE,S_CZ,S_CNZ,S_CALL,
                 S_JNC,S_JC,S_JM,S_JP,S_JPO,S_JPE,S_JZ,S_JNZ,S_JMP,S_ORG];
  OC_TYPE_2_0 = [S_MVI];
  OC_TYPE_2_1 = [S_MOV];               
  { **     Control    ** }
  S_DONE = 128;
  S_INVALIDNUMBER = 254;
  S_ERROR = 255;   { No Valid Character }

{ ********** TSymbolItem ********** }
procedure TSymbolItem.setValue(Value: Integer);
begin
  _Value:= Value;
  _Defined:= true;
end;

constructor TSymbolItem.Create(Name: String; Line: Integer);
begin
  inherited Create;
  _Name:= Copy(Trim(Name),1,_maxSymbolLength);
  _Value:= Value;
  _Defined:= false;
  _Line:= Line;
end;

constructor TSymbolItem.Create(Name: String; Value: Integer; Line: Integer);
begin
  inherited Create;
  _Name:= Copy(Trim(Name),1,_maxSymbolLength);
  _Value:= Value;
  _Defined:= true;
  _Line:= Line;
end;
{ ********** TSymbolItem ********** }
{ ********** TSymbolList ********** }
function TSymbolList.getItem(Index: Integer): TSymbolItem;
begin
  if (Index >= 0) and (Index < Count) then
    result:= inherited Items[Index]
  else
    result:= nil;
end;

constructor TSymbolList.Create;
begin
  _CaseSensitive:= true;
  inherited Create;
end;

constructor TSymbolList.Create(isCaseSensitive: Boolean);
begin
  _CaseSensitive:= isCaseSensitive;
  inherited Create;
end;

function TSymbolList.Add(Item: TSymbolItem): Integer;
var
  found: Boolean;

begin
  result:= Find(Item.Name,found);
  if not found then
    begin
      result:= inherited Add(Item);
      if Assigned(OnItemInsert) then
        OnItemInsert(Self,result);
    end
  else
    if Assigned(Item) then
      Item.Free;
end;

function TSymbolList.Find(Name: String; var found: Boolean): Integer;
var
  sName: String;

begin
  if CaseSensitive then
    Name:= Copy(Trim(Name),1,_maxSymbolLength)
  else
    Name:= UpperCase(Copy(Trim(Name),1,_maxSymbolLength));
  found:= false;
  result:= 0;
  // Linear Search
  while (not found) and (result < Count) do
    begin
      sName:= Items[result].Name;
      if CaseSensitive then
        sName:= Copy(Trim(sName),1,_maxSymbolLength)
      else
        sName:= UpperCase(Copy(Trim(sName),1,_maxSymbolLength));
      found:= Name = sName;
      Inc(result);
    end;
  if found then
    Dec(result);
end;

function TSymbolList.FindItem(Name: String): TSymbolItem;
var
  found: Boolean;
  Position: Integer;

begin
  Position:= Find(Name,found);
  if found then
    result:= Items[Position]
  else
    result:= nil;
end;

function TSymbolList.AllItemsDefined: Boolean;
var
  i: Integer;
begin
  i:= 0;
  result:= true;
  while (i < Count) and result do
    begin
      if Assigned(Items[i]) then
        result:= Items[i].Defined;
      Inc(i);
    end;
end;

function TSymbolList.Insert(Index: Integer; Item: TSymbolItem): Integer;
begin
  result:= Add(Item);
end;

procedure TSymbolList.Delete(Index: Integer);
begin
  if (Index >= 0) and (Index < Count) then
    begin
      if Assigned(OnItemDelete) then
        OnItemDelete(Self,Index);
      if Assigned(Items[Index]) then
        Items[Index].Free;
      inherited Delete(Index);
    end;
end;

procedure TSymbolList.Clear;
var
  i: Integer;
begin
  for i:= Count-1 downto 0 do
    Delete(i);
  inherited Clear;
end;
{ ********** TSymbolList ********** }
{ *********** TErrorItem ********** }
constructor TErrorItem.Create(Text: String; Line: Integer; State: TErrorItemState);
begin
  inherited Create;
  _State:= State;
  _Text:= Text;
  _Line:= Line;
end;
{ *********** TErrorItem ********** }
{ *********** TErrorTable ********* }
procedure TErrorList.setItem(Index: Integer; Value: TErrorItem);
begin
  if Items[Index] <> Value then
    begin
      if Assigned(Items[Index]) then
        Items[Index].Free;
      if (Index >= 0) and (Index < Count) then
        inherited Items[Index]:= Value;
    end;
end;

function TErrorList.getItem(Index: Integer): TErrorItem;
begin
  if (Index >= 0) and (Index < Count) then
    result:= inherited Items[Index]
  else
    result:= nil;
end;

constructor TErrorList.Create;
begin
  _FatalErrors:= 0;
  _Errors:= 0;
  _Hints:= 0;
  _Warnings:= 0;
end;

function TErrorList.Add(Item: TErrorItem): Integer;
begin
  result:= inherited Add(Item);
  if Assigned(Item) then
    case Item.State of
     isFatalError: Inc(_FatalErrors);
     isError     : Inc(_Errors);
     isHint      : Inc(_Hints);
     isUndefined : Inc(_Errors);
     isWarning   : Inc(_Warnings);
    end;
  if Assigned(OnItemInsert) then
    OnItemInsert(Self,result);
end;

function TErrorList.Insert(Index: Integer; Item: TErrorItem): Integer;
begin
  result:= Add(Item);
  if Assigned(Item) then
    case Item.State of
     isFatalError: Inc(_FatalErrors);
     isError     : Inc(_Errors);
     isHint      : Inc(_Hints);
     isUndefined : Inc(_Errors);
     isWarning   : Inc(_Warnings);
    end;
  if Assigned(OnItemInsert) then
    OnItemInsert(Self,Index);
end;

procedure TErrorList.Delete(Index: Integer);
begin
  if (Index >= 0) and (Index < Count) then
    begin
      if Assigned(OnItemDelete) then
        OnItemDelete(Self,Index);
      if Assigned(Items[Index]) then
        begin
          case Items[Index].State of
           isFatalError: Dec(_FatalErrors);
           isError     : Dec(_Errors);
           isHint      : Dec(_Hints);
           isUndefined : Dec(_Errors);
           isWarning   : Dec(_Warnings);
          end;
          Items[Index].Free;
        end;
      inherited Delete(Index);
    end;
end;

procedure TErrorList.Clear;
var
  i: Integer;
begin
  for i:= Count-1 downto 0 do
    Delete(i);
  _FatalErrors:= 0;
  _Errors:= 0;
  _Hints:= 0;
  _Warnings:= 0;
  inherited Clear;
end;
{ *********** TErrorList ********** }
{ ********* TProgramItem ********** }
constructor TProgramItem.Create;
begin
  inherited Create;
  _Address:= 0;
  _Value:= 0;
  _Link:= 0;
end;

constructor TProgramItem.Create(Address: Word; Value: Byte; Link: Integer);
begin
  inherited Create;
  _Address:= Address;
  _Value:= Value;
  _Link:= Link;
end;

function TProgramItem.LoadFromStream(AStream: TStream): Boolean;
begin
  if Assigned(AStream) then
    begin
      result:= (AStream.Read(_Address,SizeOf(_Address)) = SizeOf(_Address)) and
               (AStream.Read(_Value,SizeOf(_Value)) = SizeOf(_Value)) and
               (AStream.Read(_Link,SizeOf(_Link)) = SizeOf(_Link));
    end
  else
    result:= false;
end;

function TProgramItem.SaveToStream(AStream: TStream): Boolean;
begin
  if Assigned(AStream) then
    begin
      result:= (AStream.Write(_Address,SizeOf(_Address)) = SizeOf(_Address)) and
               (AStream.Write(_Value,SizeOf(_Value)) = SizeOf(_Value)) and
               (AStream.Write(_Link,SizeOf(_Link)) = SizeOf(_Link));
    end
  else
    result:= false;
end;
{ ******** TProgramItem ********** }
{ *********** TProgram *********** }
function TProgram.getItem(Index: Integer): TProgramItem;
begin
  if (Index >= 0) and (Index < Count) then
    result:= inherited Items[Index]
  else
    result:= nil;
end;

function TProgram.Add(Item: TProgramItem): Integer;
var
  found: Boolean;

begin
  result:= Find(Item.Address,found);
  if not found then
    begin
      inherited Insert(result,Item);
      if Assigned(OnItemInsert) then
        OnItemInsert(Self,result);
    end
  else
    if Items[result] <> Item then
      begin
        if Assigned(Items[result]) then
          Items[result].Free;
        inherited Items[result]:= Item;
        if Assigned(OnItemUpdate) then
          OnItemUpdate(Self,result);
      end;
end;

function TProgram.Find(Address: Integer; var found: Boolean): Integer;
var
  left, right: Integer;
  dItem: TProgramItem;

begin
  found:= false;
  left:= 0;
  right:= Count-1;
  result:= 0;
  // Binary Search
  while (not found) and (left <= right) do
    begin
      result:= left + (right-left) div 2;
      dItem:= Items[result];
      found:= Address = dItem.Address;
      if not found then
        if Address > dItem.Address then
          left:= result + 1
        else
          right:= result - 1;
    end;
  if not found then
    result:= right + 1;
end;

function TProgram.FindItem(Address: Integer): TProgramItem;
var
  found: Boolean;
  Position: Integer;

begin
  Position:= Find(Address,found);
  if found then
    result:= Items[Position]
  else
    result:= nil;
end;

function TProgram.LoadFromStream(AStream: TStream): Boolean;
var
  ProgramItem: TProgramItem;
  i, Count: Integer;
begin
  Clear;
  if Assigned(AStream) then
    begin
      if AStream.Read(Count,SizeOf(Count)) = SizeOf(Count) then
        begin
          i:= 0;
          result:= true;
          while (i < Count) and result do
            begin
              ProgramItem:= TProgramItem.Create;
              if ProgramItem.LoadFromStream(AStream) then
                Add(ProgramItem)
              else
                begin
                  Clear;
                  ProgramItem.Free;
                  result:= false;
                end;
              inc(i)
            end
        end
      else
        result:= false;
    end
  else
    result:= false;
end;

function TProgram.SaveToStream(AStream: TStream): Boolean;
var
  ProgramItem: TProgramItem;
  i, Count: Integer;
begin
  if Assigned(AStream) then
    begin
      Count:= Self.Count;
      if AStream.Write(Count,SizeOf(Count)) = SizeOf(Count) then
        begin
          i:= 0;
          result:= true;
          while (i < Count) and result do
            begin
              ProgramItem:= Items[i];
              result:= result and ProgramItem.SaveToStream(AStream);
              inc(i)
            end
        end
      else
        result:= false;
    end
  else
    result:= false;
end;

function TProgram.Insert(Index: Integer; Item: TProgramItem): Integer;
begin
  result:= Add(Item);
end;

procedure TProgram.Delete(Index: Integer);
begin
  if (Index >= 0) and (Index < Count) then
    begin
      if Assigned(OnItemDelete) then
        OnItemDelete(Self,Index);
      if Assigned(Items[Index]) then
        Items[Index].Free;
      inherited Delete(Index);
    end;
end;

procedure TProgram.Clear;
var
  i: Integer;
begin
  for i:= Count-1 downto 0 do
    Delete(i);
  inherited Clear;
end;
{ ************ TProgram *********** }
{ ************ TScanner *********** }
constructor TScanner.Create(SymbolList: TSymbolList);
begin
  _SymbolList:= SymbolList;
  _Sourcecode:= '';
  Reset;
end;

procedure TScanner.Initialize(Sourcecode: String);
begin
  _Sourcecode:= Sourcecode;
  Reset;
end;

procedure TScanner.Reset;
begin
  _Position:= 1;
  _LexemValue:= 0;
  _LexemLine:= 0;
end;

function TScanner.Lexem: Integer;
begin
  result:= S_DONE;
end;
{ ************ TScanner *********** }
{ ********** Ti8008Scanner ******** }
function Ti8008Scanner.Lexem: Integer;
var
  Done: Boolean;
  State: Byte;
  Check: Integer;

  procedure handleOtherChars;
  begin
    if _Sourcecode[_Position] in (ALPHAEX+DIGITS) then
      begin
        State:= 68;
        _LexemStr:= _LexemStr + _Sourcecode[_Position];
      end
    else
      if _Sourcecode[_Position] in CONTROL_CHARS then
        begin
          Done:= _Sourcecode[_Position] in (BREAK_CHAR+NEWLINE_CHAR);
          if Done then
            Dec(_Position);
        end
      else
        begin
          _LexemStr:= _Sourcecode[_Position];
          State:= S_ERROR; { No Valid Character }
        end;
  end;

begin
  _LexemStr:= '';
  _LexemValue:= 0;
  State:= 0;
  result:= S_DONE;
  Done:= _Position > Length(_Sourcecode);
  while not Done do
    begin
      case State of
        { Start }
        0: case _Sourcecode[_Position] of
             'A','a' : begin
                         State:= 1;
                         _LexemStr:= _Sourcecode[_Position];
                       end;
             'B','b' : begin
                         State:= 8;
                         _LexemStr:= _Sourcecode[_Position];
                       end;
             'C','c' : begin
                         State:= 9;
                         _LexemStr:= _Sourcecode[_Position];
                       end;
             'D','d' : begin
                         State:= 21;
                         _LexemStr:= _Sourcecode[_Position];
                       end;
             'E','e' : begin
                         State:= 23;
                         _LexemStr:= _Sourcecode[_Position];
                       end;
             'H','h' : begin
                         State:= 26;
                         _LexemStr:= _Sourcecode[_Position];
                       end;
             'I','i' : begin
                         State:= 85;
                         _LexemStr:= _Sourcecode[_Position];
                       end;
             'J','j' : begin
                         State:= 86;
                         _LexemStr:= _Sourcecode[_Position];
                       end;
             'L','l' : begin
                         State:= 39;
                         _LexemStr:= _Sourcecode[_Position];
                       end;
             'M','m' : begin
                         State:= 40;
                         _LexemStr:= _Sourcecode[_Position];
                       end;
             'O','o' : begin
                         State:= 93;
                         _LexemStr:= _Sourcecode[_Position];
                       end;
             'Q','q' : begin
                         State:= 110;
                         _LexemStr:= _Sourcecode[_Position];
                       end;
             'R','r' : begin
                         State:= 96;
                         _LexemStr:= _Sourcecode[_Position];
                       end;
             'S','s' : begin
                         State:= 103;
                         _LexemStr:= _Sourcecode[_Position];
                       end;
             'X','x' : begin
                         State:= 106;
                         _LexemStr:= _Sourcecode[_Position];
                       end;
             ';' : State:= 108;
             ',' : begin
                     State:= 70;
                     Done:= true;
                   end;
             '.' : State:= 109;
           else
             begin
               if _Sourcecode[_Position] in ALPHA then
                 begin
                   State:= 68;
                   _LexemStr:= _Sourcecode[_Position];
                 end
               else
                 if _Sourcecode[_Position] in DIGITS then
                   begin
                     State:= 71;
                     _LexemStr:= _Sourcecode[_Position];
                   end
                 else
                   if _Sourcecode[_Position] in CONTROL_CHARS then
                     begin
                       if _Sourcecode[_Position] = NEWLINE then
                         Inc(_LexemLine);
                     end
                   else
                     begin
                       _LexemStr:= _Sourcecode[_Position];
                       State:= S_ERROR; { No Valid Character }
                     end;
             end;
           end; { case State 0: }
        { A }
        1: case _Sourcecode[_Position] of
             'C','c' : begin
                         State:= 75;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             'D','d' : begin
                         State:= 76;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             'N','n' : begin
                         State:= 77;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
           else
             handleOtherChars;
           end; { case _state 1: }
        { ACI, ADC, ADD, ADI, ANA, ANI, CALL, CC, CM, CMP, CNC, CNZ, CPE, CPI
          CPO, CZ, DCR, END, EQU, HLT, INR, JC, JMP, JNC, JNZ, JPE, JPO, JZ,
          L, MOV, MVI, ORA, ORG, ORI, OUT, RAL, RAR, RC, RET, RLC, RM, RNC, RNZ,
          RPE, RPO, RRC, RST, RZ, SBB, SBI, SUB, SUI, XRA, XRI }
        2..7,10,11,13..15,17..20,
        22,24,25,27,29..30,32,33,
        34,36,37,38,39,41,42,44..55,
        57..67: handleOtherChars;
           { case State 2..7,10,11,13..15,17..20,22,24,25,27,29..30,32,33,34,36,37,38,39,41,42,44..55,57..67: }
        { B }
        8: if _Sourcecode[_Position] in BIN then
             begin
               _LexemStr:= _Sourcecode[_Position];
               State:= 73;
             end
           else
             handleOtherChars;
           { case State 8: }
        { C }
        9: case _Sourcecode[_Position] of
             'A','a' : begin
                         State:= 78;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             'C','c' : begin
                         State:= 11;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             'M','m' : begin
                         State:= 12;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             'N','n' : begin
                         State:= 80;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             'P','p' : begin
                         State:= 16;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             'Z','z' : begin
                         State:= 20;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
           else
             handleOtherChars;
           end; { case State 9: }
        { CM }
        12: case _Sourcecode[_Position] of
             'P','p' : begin
                         State:= 13;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
            else
              handleOtherChars;
            end; { case State 12: }
        { CP }
        16: case _Sourcecode[_Position] of
             'E','e' : begin
                         State:= 17;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             'I','i' : begin
                         State:= 18;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             'O','o' : begin
                         State:= 19;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
            else
              handleOtherChars;
            end; { case State 16: }
        { D }
        21: case _Sourcecode[_Position] of
             'C','c' : begin
                         State:= 81;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
            else
              handleOtherChars;
            end; { case State 21: }
        { E }
        23: case _Sourcecode[_Position] of
             'N','n' : begin
                         State:= 82;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             'Q','q' : begin
                         State:= 83;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
            else
              handleOtherChars;
            end; { case State 23: }
        { H }
        26: case _Sourcecode[_Position] of
             'L','l' : begin
                         State:= 84;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
            else
              if _Sourcecode[_Position] in HEX then
                begin
                  _LexemStr:= _Sourcecode[_Position];
                  State:= 74;
                end
              else
                handleOtherChars;
            end; { case State 26: }
        { IN }
        28: case _Sourcecode[_Position] of
             'R','r' : begin
                         State:= 29;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
            else
              handleOtherChars;
            end; { case State 28: }
        { JM }
        31: case _Sourcecode[_Position] of
             'P','p' : begin
                         State:= 32;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
            else
              handleOtherChars;
            end; { case State 31: }
        { JP }
        35: case _Sourcecode[_Position] of
             'E','e' : begin
                         State:= 36;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             'O','o' : begin
                         State:= 37;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
            else
              handleOtherChars;
            end; { case State 35: }
        { M }
        40: case _Sourcecode[_Position] of
             'O','o' : begin
                         State:= 88;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             'V','v' : begin
                         State:= 89;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             '(' : begin
                     State:= 90;
                     _LexemStr:= _LexemStr + _Sourcecode[_Position];
                   end;
            else
              handleOtherChars;
            end; { case State 40: }
        { M(HL) }
        43: if _Sourcecode[_Position] in CONTROL_CHARS then
              begin
                if _Sourcecode[_Position] = NEWLINE then
                  Inc(_LexemLine);
                Done:= _Sourcecode[_Position] in (BREAK_CHAR+NEWLINE_CHAR);
              end
            else
              begin
                _LexemStr:= _Sourcecode[_Position];
                State:= S_ERROR; { No Valid Character }
              end;
           { case State 43: }
        { RP }
        56: case _Sourcecode[_Position] of
             'E','e' : begin
                         State:= 57;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             'O','o' : begin
                         State:= 58;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
            else
              handleOtherChars;
            end; { case State 56: }
        { Identifier }
        68: case _Sourcecode[_Position] of
             ':' : begin
                     State:= 69;
                     Done:= true;
                   end;
            else
              handleOtherChars;
            end; { case State 68: }
        { 70 handled by the transition }
        { Decimal }
        71: if _Sourcecode[_Position] in DIGITS then
              _LexemStr:= _LexemStr + _Sourcecode[_Position]
            else
              if _Sourcecode[_Position] in CONTROL_CHARS then
                begin
                  Done:= _Sourcecode[_Position] in (BREAK_CHAR+NEWLINE_CHAR);
                  if Done then
                    Dec(_Position);
                end
              else
                begin
                  _LexemStr:= _LexemStr + _Sourcecode[_Position];
                  State:= S_INVALIDNUMBER; { No Valid Character }
                end;
            { case State 71: }
        { Octal }
        72: if _Sourcecode[_Position] in OCT then
              _LexemStr:= _LexemStr + _Sourcecode[_Position]
            else
              if _Sourcecode[_Position] in CONTROL_CHARS then
                begin
                  Done:= _Sourcecode[_Position] in (BREAK_CHAR+NEWLINE_CHAR);
                  if Done then
                    Dec(_Position);
                end
              else
                begin
                  _LexemStr:= _LexemStr + _Sourcecode[_Position];
                  State:= S_INVALIDNUMBER; { No Valid Character }
                end;
            { case State 72: }
        { Binary }
        73: if _Sourcecode[_Position] in BIN then
              _LexemStr:= _LexemStr + _Sourcecode[_Position]
            else
              if _Sourcecode[_Position] in CONTROL_CHARS then
                begin
                  Done:= _Sourcecode[_Position] in (BREAK_CHAR+NEWLINE_CHAR);
                  if Done then
                    Dec(_Position);
                end
              else
                begin
                  _LexemStr:= _LexemStr + _Sourcecode[_Position];
                  State:= S_INVALIDNUMBER; { No Valid Character }
                end;
            { case State 73: }
        { Hexadecimal }
        74: if _Sourcecode[_Position] in HEX then
              _LexemStr:= _LexemStr + _Sourcecode[_Position]
            else
              if _Sourcecode[_Position] in CONTROL_CHARS then
                begin
                  Done:= _Sourcecode[_Position] in (BREAK_CHAR+NEWLINE_CHAR);
                  if Done then
                    Dec(_Position);
                end
              else
                begin
                  _LexemStr:= _LexemStr + _Sourcecode[_Position];
                  State:= S_INVALIDNUMBER; { No Valid Character }
                end;
            { case State 74: }
        { AC }
        75: case _Sourcecode[_Position] of
             'I','i': begin
                        State:= 2;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              handleOtherChars;
            end; { case State 75: }
        { AD }
        76: case _Sourcecode[_Position] of
             'C','c': begin
                        State:= 3;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'D','d': begin
                        State:= 4;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'I','i': begin
                        State:= 5;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              handleOtherChars;
            end; { case State 76: }
        { AN }
        77: case _Sourcecode[_Position] of
             'A','a': begin
                        State:= 6;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'I','i': begin
                        State:= 7;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              handleOtherChars;
            end; { case State 77: }
        { CA }
        78: case _Sourcecode[_Position] of
             'L','l': begin
                        State:= 79;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              handleOtherChars;
            end; { case State 78: }
        { CL }
        79: case _Sourcecode[_Position] of
             'L','l': begin
                        State:= 10;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              handleOtherChars;
            end; { case State 79: }
        { CN }
        80: case _Sourcecode[_Position] of
             'C','c': begin
                        State:= 14;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'Z','z': begin
                        State:= 15;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              handleOtherChars;
            end; { case State 80: }
        { DC }
        81: case _Sourcecode[_Position] of
             'R','r': begin
                        State:= 22;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              handleOtherChars;
            end; { case State 81: }
        { EN }
        82: case _Sourcecode[_Position] of
             'D','d': begin
                        State:= 24;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              handleOtherChars;
            end; { case State 82: }
        { EQ }
        83: case _Sourcecode[_Position] of
             'U','u': begin
                        State:= 25;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              handleOtherChars;
            end; { case State 83: }
        { HL }
        84: case _Sourcecode[_Position] of
             'T','t': begin
                        State:= 27;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              handleOtherChars;
            end; { case State 84: }
        { I }
        85: case _Sourcecode[_Position] of
             'N','n': begin
                        State:= 28;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              handleOtherChars;
            end; { case State 85: }
        { J }
        86: case _Sourcecode[_Position] of
             'C','c': begin
                        State:= 30;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'M','m': begin
                        State:= 31;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'N','n': begin
                        State:= 87;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'P','p': begin
                        State:= 35;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'Z','z': begin
                        State:= 38;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              handleOtherChars;
            end; { case State 86: }
        { JN }
        87: case _Sourcecode[_Position] of
             'C','c': begin
                        State:= 33;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'Z','z': begin
                        State:= 34;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
               handleOtherChars;
            end; { case State 87: }
        { MO }
        88: case _Sourcecode[_Position] of
             'V','v': begin
                        State:= 41;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              handleOtherChars;
            end; { case State 88: }
        { MV }
        89: case _Sourcecode[_Position] of
             'I','i': begin
                        State:= 42;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              handleOtherChars;
            end; { case State 89: }
        { M( }
        90: case _Sourcecode[_Position] of
             'H','h': begin
                        State:= 91;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              if _Sourcecode[_Position] in CONTROL_CHARS then
                begin
                  Done:= _Sourcecode[_Position] in (BREAK_CHAR+NEWLINE_CHAR);
                  if Done then
                    Dec(_Position);
                end
              else
                begin
                  _LexemStr:= _Sourcecode[_Position];
                  State:= S_ERROR; { No Valid Character }
                end;
            end; { case State 90: }
        { M(H }
        91: case _Sourcecode[_Position] of
             'L','l': begin
                        State:= 92;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              if _Sourcecode[_Position] in CONTROL_CHARS then
                begin
                  Done:= _Sourcecode[_Position] in (BREAK_CHAR+NEWLINE_CHAR);
                  if Done then
                    Dec(_Position);
                end
              else
                begin
                  _LexemStr:= _Sourcecode[_Position];
                  State:= S_ERROR; { No Valid Character }
                end;
            end; { case State 91: }
        { M(HL }
        92: case _Sourcecode[_Position] of
             ')': begin
                    State:= 43;
                    _LexemStr:= _LexemStr + _Sourcecode[_Position];
                  end;
            else
              if _Sourcecode[_Position] in CONTROL_CHARS then
                begin
                  Done:= _Sourcecode[_Position] in (BREAK_CHAR+NEWLINE_CHAR);
                  if Done then
                    Dec(_Position);
                end
              else
                begin
                  _LexemStr:= _Sourcecode[_Position];
                  State:= S_ERROR; { No Valid Character }
                end;
            end; { case State 92: }
        { O }
        93: case _Sourcecode[_Position] of
             'R','r': begin
                        State:= 94;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'U','u': begin
                        State:= 95;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              if _Sourcecode[_Position] in OCT then
                begin
                  _LexemStr:= _Sourcecode[_Position];
                  State:= 72;
                end
              else
                 handleOtherChars;
            end; { case State 93: }
        { OR }
        94: case _Sourcecode[_Position] of
             'A','a': begin
                        State:= 44;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'G','g': begin
                        State:= 45;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'I','i': begin
                        State:= 46;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             else
              handleOtherChars;
            end; { case State 94: }
        { OU }
        95: case _Sourcecode[_Position] of
             'T','t': begin
                        State:= 47;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              handleOtherChars;
            end; { case State 95: }
        { R }
        96: case _Sourcecode[_Position] of
             'A','a': begin
                        State:= 97;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'C','c': begin
                        State:= 50;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'E','e': begin
                        State:= 98;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'L','l': begin
                        State:= 99;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'M','m': begin
                        State:= 53;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'N','n': begin
                        State:= 100;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'P','p': begin
                        State:= 56;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'R','r': begin
                        State:= 101;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'S','s': begin
                        State:= 102;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'Z','z': begin
                        State:= 61;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              handleOtherChars;
            end; { case State 96: }
        { RA }
        97: case _Sourcecode[_Position] of
             'L','l': begin
                        State:= 48;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
             'R','r': begin
                        State:= 49;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              handleOtherChars;
            end; { case State 97: }
        { RE }
        98: case _Sourcecode[_Position] of
             'T','t': begin
                        State:= 51;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
               handleOtherChars;
            end; { case State 74: }
        { RL }
        99: case _Sourcecode[_Position] of
             'C','c': begin
                        State:= 52;
                        _LexemStr:= _LexemStr + _Sourcecode[_Position];
                      end;
            else
              handleOtherChars;
            end; { case State 99: }
        { RN }
        100: case _Sourcecode[_Position] of
              'C','c': begin
                         State:= 54;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
              'Z','z': begin
                         State:= 55;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             else
               handleOtherChars;
             end; { case State 100: }
        { RR }
        101: case _Sourcecode[_Position] of
              'C','c': begin
                         State:= 59;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             else
               handleOtherChars;
             end; { case State 101: }
        { RS }
        102: case _Sourcecode[_Position] of
              'T','t': begin
                         State:= 60;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             else
               handleOtherChars;
             end; { case State 102: }
        { S }
        103: case _Sourcecode[_Position] of
              'B','b': begin
                         State:= 104;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
              'U','u': begin
                         State:= 105;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             else
               handleOtherChars;
             end; { case State 103: }
        { SB }
        104: case _Sourcecode[_Position] of
              'B','b': begin
                         State:= 62;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
              'I','i': begin
                         State:= 63;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             else
               handleOtherChars;
             end; { case State 104: }
        { SU }
        105: case _Sourcecode[_Position] of
              'B','b': begin
                         State:= 64;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
              'I','i': begin
                         State:= 65;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             else
               handleOtherChars;
             end; { case State 105: }
        { X }
        106: case _Sourcecode[_Position] of
              'R','r': begin
                         State:= 107;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             else
               handleOtherChars;
             end; { case State 107: }
        { XR }
        107: case _Sourcecode[_Position] of
              'A','a': begin
                         State:= 66;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
              'I','i': begin
                         State:= 67;
                         _LexemStr:= _LexemStr + _Sourcecode[_Position];
                       end;
             else
               handleOtherChars;
             end; { case State 107: }
        { Comment }
        108: if _Sourcecode[_Position] in CONTROL_CHARS then
               begin
                 if _Sourcecode[_Position] = NEWLINE then
                   begin
                     Inc(_LexemLine);
                     State:= 0;
                   end;
               end; { case State 108: }
        { . }
        109: if _Sourcecode[_Position] in DIGITS then
               begin
                 State:= 71;
                 _LexemStr:= _Sourcecode[_Position];
               end
             else
               if _Sourcecode[_Position] in CONTROL_CHARS then
                 begin
                   Done:= _Sourcecode[_Position] in (BREAK_CHAR+NEWLINE_CHAR);
                   if Done then
                     Dec(_Position);
                 end
               else
                 begin
                   _LexemStr:= _LexemStr + _Sourcecode[_Position];
                   State:= S_INVALIDNUMBER; { No Valid Character }
                 end;
             { case State 109: }
        { Q }
        110: if _Sourcecode[_Position] in OCT then
               begin
                 State:= 72;
                 _LexemStr:= _Sourcecode[_Position];
               end
             else
               if _Sourcecode[_Position] in CONTROL_CHARS then
                 begin
                   Done:= _Sourcecode[_Position] in (BREAK_CHAR+NEWLINE_CHAR);
                   if Done then
                     Dec(_Position);
                 end
               else
                 begin
                   _LexemStr:= _LexemStr + _Sourcecode[_Position];
                   State:= S_INVALIDNUMBER; { No Valid Character }
                 end;
             { case State 110: }
      end;
      Inc(_Position);
      Done:= Done or
             (_Position > Length(_Sourcecode)) or
             (State = S_ERROR) or
             (State = S_INVALIDNUMBER) or
             ((State <> 108) and (State <> 0) and (_Sourcecode[_Position] = ',')) or
             ((State <> 108) and (State <> 0) and (_Sourcecode[_Position] = ';'));
    end;
  { Add Symbol to Symbollist }
  if (State in [68,69,75..89,93..107]) and Assigned(_SymbolList) then
    begin
      _LexemValue:= _SymbolList.Add(TSymbolItem.Create(_LexemStr,_LexemLine));
      if State <> 69 then
        State:= 68; // Identifier
    end;
  { Transform Values }
  case State of
    71: begin { DEC }
          _LexemValue:= IntToInt(_LexemStr,Check);
          if Check > 0 then
            State:= S_INVALIDNUMBER;
        end;
    72: begin { OCT }
          _LexemValue:= OctToInt(_LexemStr,Check);
          if Check > 0 then
            begin
              State:= S_INVALIDNUMBER;
              _LexemStr:= 'o' + _LexemStr;
            end;
        end;
    73: begin { BIN }
          _LexemValue:= BinToInt(_LexemStr,Check);
          if Check > 0 then
            begin
              State:= S_INVALIDNUMBER;
              _LexemStr:= 'b' + _LexemStr;
            end;
        end;
    74: begin { HEX }
          _LexemValue:= HexToInt(_LexemStr,Check);
          if Check > 0 then
            begin
              State:= S_INVALIDNUMBER;
              _LexemStr:= 'h' + _LexemStr;
            end;
        end;
     1: _LexemValue:= 0; { Register A }
     8: _LexemValue:= 1; { Register B }
     9: _LexemValue:= 2; { Register C }
    21: _LexemValue:= 3; { Register D }
    23: _LexemValue:= 4; { Register E }
    26: _LexemValue:= 5; { Register H }
    39: _LexemValue:= 6; { Register L }
    40,
    43: _LexemValue:= 7; { Register M(HL) }   
  end;
  if State <> 0 then
    result:= State;
end;
{ ********** Ti8008Scanner ******** }
{ ************* TParser *********** }
procedure TParser.Init(genCode: Boolean);
begin
  _genCode:= genCode;
  // Phase: 1
  if not genCode then
    begin
      if Assigned(_SymbolList) then
        _SymbolList.Clear;
      if Assigned(_ErrorList) then
        _ErrorList.Clear;
    end;
  // else Phase: 2
  _ILC:= 0;
  _Scanner.Reset;
  _Lookahead:= _Scanner.Lexem;
  _Value:= _Scanner.Value;
end;

procedure TParser.addFatalError(FatalError: String);
begin
  if Assigned(_ErrorList) then
    begin
      _ErrorList.Add(TErrorItem.Create(FatalError,_Line,isFatalError));
      if Assigned(OnASMProgress) then
        OnASMProgress(Self,_ErrorList.Errors+_ErrorList.FatalErrors,
                           _ErrorList.Warnings,_ErrorList.Hints,_Line,_genCode);
    end;
end;

procedure TParser.addError(Error: String);
begin
  if Assigned(_ErrorList) then
    begin
      if _Lookahead = S_ERROR then  // Invalid Character
        _ErrorList.Add(TErrorItem.Create(getString(rsInvalidCharacter),_Line,isError))
      else
        _ErrorList.Add(TErrorItem.Create(Error,_Line,isError));
      if Assigned(OnASMProgress) then
        OnASMProgress(Self,_ErrorList.Errors+_ErrorList.FatalErrors,
                           _ErrorList.Warnings,_ErrorList.Hints,_Line,_genCode);
    end;
  // search for next Line
  while (_Line = _Scanner.Line) and (_Lookahead <> S_DONE) do
    _Lookahead:= _Scanner.Lexem;
end;

procedure TParser.addHint(Hint: String);
begin
  if Assigned(_ErrorList) then
    begin
      _ErrorList.Add(TErrorItem.Create(Hint,_Line,isHint));
      if Assigned(OnASMProgress) then
        OnASMProgress(Self,_ErrorList.Errors+_ErrorList.FatalErrors,
                           _ErrorList.Warnings,_ErrorList.Hints,_Line,_genCode);
    end;
end;

procedure TParser.addUndefined(Undifined: String);
begin
  if Assigned(_ErrorList) then
    begin
      _ErrorList.Add(TErrorItem.Create(Undifined,_Line,isUndefined));
      if Assigned(OnASMProgress) then
        OnASMProgress(Self,_ErrorList.Errors+_ErrorList.FatalErrors,
                           _ErrorList.Warnings,_ErrorList.Hints,_Line,_genCode);
    end;
  // search for next Line
  while (_Line = _Scanner.Line) and (_Lookahead <> S_DONE) do
    _Lookahead:= _Scanner.Lexem;
end;

procedure TParser.addUndefined(Undifined: String; Line: Integer);
begin
  if Assigned(_ErrorList) then
    begin
      _ErrorList.Add(TErrorItem.Create(Undifined,Line,isUndefined));
      if Assigned(OnASMProgress) then
        OnASMProgress(Self,_ErrorList.Errors+_ErrorList.FatalErrors,
                           _ErrorList.Warnings,_ErrorList.Hints,Line,_genCode);
    end;
end;

procedure TParser.addWarning(Warning: String);
begin
  if Assigned(_ErrorList) then
    begin
      _ErrorList.Add(TErrorItem.Create(Warning,_Line,isWarning));
      if Assigned(OnASMProgress) then
        OnASMProgress(Self,_ErrorList.Errors+_ErrorList.FatalErrors,
                           _ErrorList.Warnings,_ErrorList.Hints,_Line,_genCode);
    end;
end;

procedure TParser.addWarning(Warning: String; Line: Integer);
begin
  if Assigned(_ErrorList) then
    begin
      _ErrorList.Add(TErrorItem.Create(Warning,Line,isWarning));
      if Assigned(OnASMProgress) then
        OnASMProgress(Self,_ErrorList.Errors+_ErrorList.FatalErrors,
                           _ErrorList.Warnings,_ErrorList.Hints,_Line,_genCode);
    end;
end;

procedure TParser.ItemUpdateEvent(Sender: TObject; Index: Integer);
begin
  if Assigned(_Program) then
    addHint(getString(rsOverrideRAM)+' '+IntToStr(_Program.Items[Index].Address))
  else
    addHint(getString(rsOverrideRAM));
  if Assigned(_OnItemUpdate) then
    _OnItemUpdate(Sender,Index);
end;

constructor TParser.Create(SymbolList: TSymbolList; Scanner: TScanner;
                           ErrorList: TErrorList);
begin
  _SymbolList:= SymbolList;
  _Scanner:= Scanner;
  _ErrorList:= ErrorList;
end;

function TParser.Parse(theProgram: TProgram): Boolean;
begin
  if Assigned(theProgram) then
    theProgram.Clear;
  result:= false;
end;

function TParser.MaxILC: Integer;
begin
  result:= 0;
end;
{ ************* TParser *********** }
{ ********** Ti8008Parser ********* }
function Ti8008Parser.generateCode(var Check: Boolean; Oc, Op1, Op2: Integer): TrippleByte;
begin
  Check:= true;
  result.V0:= 0;
  result.V1:= 0;
  result.V2:= 0;
  case Oc of
    { 1 Byte }
    S_RNC : result.V0:= CODE_RNC;
    S_RC  : result.V0:= CODE_RC;
    S_RM  : result.V0:= CODE_RM;
    S_RP  : result.V0:= CODE_RP;
    S_RPO : result.V0:= CODE_RPO;
    S_RPE : result.V0:= CODE_RPE;
    S_RZ  : result.V0:= CODE_RZ;
    S_RNZ : result.V0:= CODE_RNZ;
    S_HLT : result.V0:= 0;
    S_RET : result.V0:= 7;
    S_RLC : result.V0:= CODE_RLC;
    S_RAR : result.V0:= CODE_RAR;
    S_RRC : result.V0:= CODE_RRC;
    S_RAL : result.V0:= CODE_RAL;
    S_INR : result.V0:= Op1*8;
    S_DCR : result.V0:= Op1*8 + 1;
    S_IN  : result.V0:= CODE_IN + 2*Op1;
    S_OUT : result.V0:= CODE_OUT + 2*Op1;
    S_ADC : result.V0:= CODE_ADC + Op1;
    S_XRA : result.V0:= CODE_XRA + Op1;
    S_CMP : result.V0:= CODE_CMP + Op1;
    S_SBB : result.V0:= CODE_SBB + Op1;
    S_SUB : result.V0:= CODE_SUB + Op1;
    S_ORA : result.V0:= CODE_ORA + Op1;
    S_ANA : result.V0:= CODE_ANA + Op1;
    S_ADD : result.V0:= CODE_ADD + Op1;
    S_MOV : result.V0:= CODE_MOV + Op1*8 + Op2;
    S_RST : result.V0:= CODE_RST + Op1;
    { 2 Byte }
    S_ADI : begin
              result.V0:= CODE_ADI;
              result.V1:= Op1 and 255;
            end;
    S_ANI : begin
              result.V0:= CODE_ANI;
              result.V1:= Op1 and 255;
            end;
    S_ORI : begin
              result.V0:= CODE_ORI;
              result.V1:= Op1 and 255;
            end;
    S_SUI : begin
              result.V0:= CODE_SUI;
              result.V1:= Op1 and 255;
            end;
    S_SBI : begin
              result.V0:= CODE_SBI;
              result.V1:= Op1 and 255;
            end;
    S_CPI : begin
              result.V0:= CODE_CPI;
              result.V1:= Op1 and 255;
            end;
    S_XRI : begin
              result.V0:= CODE_XRI;
              result.V1:= Op1 and 255;
            end;
    S_ACI : begin
              result.V0:= CODE_ACI;
              result.V1:= Op1 and 255;
            end;
    S_MVI : begin
              result.V0:= CODE_MVI + Op1*8;
              result.V1:= Op2 and 255;
            end;
    { 3 Byte }        
    S_CNC : begin  // Little Endian
              result.V0:= CODE_CNC;
              result.V1:= Op1 and 255;
              result.V2:= (Op1 div 256) and 127;
            end;
    S_CC  : begin  // Little Endian
              result.V0:= CODE_CC;
              result.V1:= Op1 and 255;
              result.V2:= (Op1 div 256) and 127;
            end;
    S_CM  : begin  // Little Endian
              result.V0:= CODE_CM;
              result.V1:= Op1 and 255;
              result.V2:= (Op1 div 256) and 127;
            end;
    S_CP  : begin  // Little Endian
              result.V0:= CODE_CP;
              result.V1:= Op1 and 255;
              result.V2:= (Op1 div 256) and 127;
            end;
    S_CPO : begin  // Little Endian
              result.V0:= CODE_CPO;
              result.V1:= Op1 and 255;
              result.V2:= (Op1 div 256) and 127;
            end;
    S_CPE : begin  // Little Endian
              result.V0:= CODE_CPE;
              result.V1:= Op1 and 255;
              result.V2:= (Op1 div 256) and 127;
            end;
    S_CZ  : begin  // Little Endian
              result.V0:= CODE_CZ;
              result.V1:= Op1 and 255;
              result.V2:= (Op1 div 256) and 127;
            end;
    S_CNZ : begin  // Little Endian
              result.V0:= CODE_CNZ;
              result.V1:= Op1 and 255;
              result.V2:= (Op1 div 256) and 127;
            end;
    S_CALL: begin  // Little Endian
              result.V0:= 70;
              result.V1:= Op1 and 255;
              result.V2:= (Op1 div 256) and 127;
            end;
    S_JNC : begin  // Little Endian
              result.V0:= CODE_JNC;
              result.V1:= Op1 and 255;
              result.V2:= (Op1 div 256) and 127;
            end;
    S_JC  : begin  // Little Endian
              result.V0:= CODE_JC;
              result.V1:= Op1 and 255;
              result.V2:= (Op1 div 256) and 127;
            end;
    S_JM  : begin  // Little Endian
              result.V0:= CODE_JM;
              result.V1:= Op1 and 255;
              result.V2:= (Op1 div 256) and 127;
            end;
    S_JP  : begin  // Little Endian
              result.V0:= CODE_JP;
              result.V1:= Op1 and 255;
              result.V2:= (Op1 div 256) and 127;
            end;
    S_JPO : begin  // Little Endian
              result.V0:= CODE_JPO;
              result.V1:= Op1 and 255;
              result.V2:= (Op1 div 256) and 127;
            end;
    S_JPE : begin  // Little Endian
              result.V0:= CODE_JPE;
              result.V1:= Op1 and 255;
              result.V2:= (Op1 div 256) and 127;
            end;
    S_JZ  : begin  // Little Endian
              result.V0:= CODE_JZ;
              result.V1:= Op1 and 255;
              result.V2:= (Op1 div 256) and 127;
            end;
    S_JNZ : begin  // Little Endian
              result.V0:= CODE_JNZ;
              result.V1:= Op1 and 255;
              result.V2:= (Op1 div 256) and 127;
            end;
    S_JMP : begin  // Little Endian
              result.V0:= 68;
              result.V1:= Op1 and 255;
              result.V2:= (Op1 div 256) and 127;
            end;
    else Check:= false; // Internal Error: Instruction not found
  end;
end;

{ i8008Program ::= (i8008Stmt)* END }
function Ti8008Parser.i8008Program: Boolean;

  function ErrorLineFound(ELine: Integer): Boolean;
  var
    i: Integer;

  begin
    result:= false;
    i:= 0;
    while (i < _ErrorList.Count) and not result do
      begin
        result:= _ErrorList.Items[i].Line = ELine;
        Inc(i);
      end;
  end;

var
  i: Integer;
  Item: TSymbolItem;
begin
  _Line:= -1;
  while (_Lookahead <> S_DONE) and (_Lookahead <> S_END) and (_ErrorList.FatalErrors <= 0) do
    begin
      // _one_ Statement in _one_ Line
      if (_Line <> _Scanner.Line) or (_Lookahead = S_LBL) then
        begin
          _Line:= _Scanner.Line;
          _Value:= _Scanner.Value;
          i8008Stmt;
        end
      else { _Line <> _Scanner.Line }
        addError(getString(rsOneStatement));
    end;
  if (_Lookahead <> S_END) and (_ErrorList.FatalErrors <= 0) then
    addError(getString(rsMissingEnd));
  // some Identifier where called, but not initialized
  if not _SymbolList.AllItemsDefined then
    begin
      for i:= 0 to _SymbolList.Count-1 do
        begin
          Item:= _SymbolList.Items[i];
          if not Item.Defined and not ErrorLineFound(Item.Line) then
            addUndefined(getString(rsUndefinedIdentifier)+' : '+Item.Name,Item.Line);
        end;
    end;
  result:= (_ErrorList.Errors = 0);
end;

{ i8008Stmt ::=  ID EQU Number                  // all instruction in _one_ Line
                                                // Value <= 255
               | LBL i8008optional_instruction  // all instruction in _one_ Line
               | i8008instruction               // all instruction in _one_ Line
}
procedure Ti8008Parser.i8008Stmt;
var
  ILCtmp: LongWord;
  LineTmp: Integer;
  Lbl: Integer;

begin
  if Assigned(OnASMProgress) and Assigned(_ErrorList) then
    OnASMProgress(Self,_ErrorList.Errors+_ErrorList.FatalErrors,
                       _ErrorList.Warnings,_ErrorList.Hints,_Line,_genCode);
  { i8808Stmt ::= ID EQU NUMBER }
  if _Lookahead = S_ID then
    begin
      if _Scanner.Line = _Line then
        begin
          _Lookahead:= _Scanner.Lexem;
          if _Lookahead = S_EQU then
            begin
              if _Scanner.Line = _Line then
                begin
                  _Lookahead:= _Scanner.Lexem;
                  if _Lookahead in S_NUMBER then
                    begin
                      if _Value < _SymbolList.Count then
                        begin
                          if _SymbolList.Items[_Value].Defined and not _genCode then
                            addWarning(getString(rsOverrideIdentifier));
                          _SymbolList.Items[_Value].Value:= _Scanner.Value
                        end
                      else
                        addFatalError(getString(rsUnknownIdentifier));
                      _Lookahead:= _Scanner.Lexem;
                    end
                  else  { if _Lookahead in S_NUMBER then }
                    begin
                      if _Lookahead <> S_INVALIDNUMBER then
                        addUndefined(getString(rsUndefinedIdentifier))
                      else
                        addError(getString(rsInvalidNumber)+' '+_Scanner.SubStr);
                    end
                end
              else { if _Scanner.Line = _Line then }
                addError(getString(rsNewLine));
            end
          else { if _Lookahead = S_EQU then }
            addUndefined(getString(rsUndefinedIdentifier));
        end
      else { if _Scanner.Line = _Line then }
        addError(getString(rsNewLine));
    end
  else { if _Lookahead = S_ID then }
    { i8808Stmt ::= LBL i8008Optional_instruction }
    if _Lookahead = S_LBL then
      begin
        LineTmp:= _Scanner.Line;
        Lbl:= _Value;
        _Lookahead:= _Scanner.Lexem;
        _Line:= _Scanner.Line;
        i8008Optional_instruction(ILCtmp);
        if Lbl < _SymbolList.Count then
          begin
            if _SymbolList.Items[Lbl].Defined and not _genCode then
                addWarning(getString(rsOverrideLabel),LineTmp);
            _SymbolList.Items[Lbl].Value:= ILCtmp
          end
        else
          addFatalError(getString(rsUnknownLabel));
      end
    else
      { i8808Stmt ::= i8008Instruction }
      if not i8008Instruction(ILCtmp) then
        addError(getString(rsMissingStatement));
end;

{ i8008Instruction ::=  Opcode_Type_0_0
                      | Opcode_Type_1_0
                      | Opcode_Type_1_1
                      | Opcode_Type_1_2
                      | Opcode_Type_1_3
                      | Opcode_Type_1_4
                      | Opcode_Type_1_5
                      | Opcode_Type_1_6
                      | Opcode_Type_2_0 Register ',' Number // Value <= 255
                      | Opcode_Type_2_1 Register ',' Register
}
function Ti8008Parser.i8008Instruction(var ILCtmp: LongWord): Boolean;
begin
  ILCtmp:= _ILC;
  result:= true;
  if _Lookahead in OC_TYPE_0_0 then
    Opcode_Type_0_0
  else
    if _Lookahead in OC_TYPE_1_0 then
      Opcode_Type_1_0
    else
      if _Lookahead in OC_TYPE_1_1 then
        Opcode_Type_1_1
      else
        if _Lookahead in OC_TYPE_1_2 then
          Opcode_Type_1_2
        else
          if _Lookahead in OC_TYPE_1_3 then
            Opcode_Type_1_3
          else
            if _Lookahead in OC_TYPE_1_4 then
              Opcode_Type_1_4
            else
              if _Lookahead in OC_TYPE_1_5 then
                Opcode_Type_1_5
              else
                if _Lookahead in OC_TYPE_1_6 then
                  Opcode_Type_1_6(ILCtmp)
                else
                  if _Lookahead in OC_TYPE_2_0 then
                    Opcode_Type_2_0
                  else
                    if _Lookahead in OC_TYPE_2_1 then
                      Opcode_Type_2_1
                    else
                      result:= false;
end;

{ i8008OptionalInstruction ::=  i8008Instruction
                              | epsilon
}
procedure Ti8008Parser.i8008Optional_instruction(var ILCtmp: LongWord);
begin
  i8008Instruction(ILCtmp);
end;

{ Opcode_Type_0_0 ::= HLT | RLC | RAL | RAR | RRC | RNC | RC | RM | RP | RPO |
                      RPE | RZ | RNZ | RET
}
function Ti8008Parser.Opcode_Type_0_0: Boolean;
var
  Code: TrippleByte;

begin
  case _Lookahead of
    S_HLT: Code:= generateCode(result,S_HLT,0,0);
    S_RLC: Code:= generateCode(result,S_RLC,0,0);
    S_RAL: Code:= generateCode(result,S_RAL,0,0);
    S_RAR: Code:= generateCode(result,S_RAR,0,0);
    S_RRC: Code:= generateCode(result,S_RRC,0,0);
    S_RNC: Code:= generateCode(result,S_RNC,0,0);
    S_RC : Code:= generateCode(result,S_RC,0,0);
    S_RM : Code:= generateCode(result,S_RM,0,0);
    S_RP : Code:= generateCode(result,S_RP,0,0);
    S_RPO: Code:= generateCode(result,S_RPO,0,0);
    S_RPE: Code:= generateCode(result,S_RPE,0,0);
    S_RZ : Code:= generateCode(result,S_RZ,0,0);
    S_RNZ: Code:= generateCode(result,S_RNZ,0,0);
    S_RET: Code:= generateCode(result,S_RET,0,0);
    else result:= false;
  end;
  if result then
    begin
      if Int64(_ILC + 1) <= Int64(MaxILC) then
        begin
          if _genCode then
            _Program.Add(TProgramItem.Create(_ILC,Code.V0,_Line));
          Inc(_ILC);
          _Lookahead:= _Scanner.Lexem;
        end
      else
        addFatalError(getString(rsRAMOverflow));
    end
  else
    addFatalError(getString(rsUnknownStatement)); // Internal Error: Instruction not found
end;

{ Opcode_Type_1_0 ::= (ADC | XRA | CMP | SBB | SUB | ORA | ANA | ADD) Register 
}
function Ti8008Parser.Opcode_Type_1_0: Boolean;
var
  OpCode: Integer;
  Operand: Integer;
  Code: TrippleByte;

begin
  OpCode:= _Lookahead;
  if _Scanner.Line = _Line then
    begin
      _Lookahead:= _Scanner.Lexem;
      if _Lookahead in (S_NUMBER + S_REGISTER + [S_ID]) then
        begin
          Operand:= _Scanner.Value;
          // get the Value of Identifier
          if _Lookahead = S_ID then
            if _genCode then
              begin
                if Operand < _SymbolList.Count then
                  Operand:= _SymbolList.Items[Operand].Value
                else
                  addFatalError(getString(rsUnknownIdentifier));
              end
            else
              Operand:= 0;
          // Check Register
          if Operand in [0..7] then
            begin
              Code:= generateCode(result,OpCode,Operand,0);
              if result then
                begin
                  if Int64(_ILC + 1) <= Int64(MaxILC) then
                    begin
                      if _genCode then
                        _Program.Add(TProgramItem.Create(_ILC,Code.V0,_Line));
                      Inc(_ILC);
                      _Lookahead:= _Scanner.Lexem;
                    end
                  else { if Int64(_ILC + 1) <= Int64(MaxILC) then }
                    addFatalError(getString(rsRAMOverflow));
                end
              else { if result then }
                addError(getString(rsUnknownStatement));  // Internal Error: Instruction not found
            end
          else { Operand in [0..7] }
            addError(getString(rsInvalidRegister));
        end
      else  { if _Lookahead in (S_NUMBER + S_REGISTER + [S_ID]) then }
        begin
          if _Lookahead <> S_INVALIDNUMBER then
            addError(getString(rsMissingOperand))
          else
            addError(getString(rsInvalidNumber)+' '+_Scanner.SubStr);
        end;
    end
  else { if _Scanner.Line = _Line then }
    addError(getString(rsNewLine));
end;

{ Opcode_Type_1_1 ::= (INR | DCR) Subset_Register
}
function Ti8008Parser.Opcode_Type_1_1: Boolean;
var
  OpCode: Integer;
  Operand: Integer;
  Code: TrippleByte;

begin
  OpCode:= _Lookahead;
  if _Scanner.Line = _Line then
    begin
      _Lookahead:= _Scanner.Lexem;
      if _Lookahead in (S_NUMBER + S_REGISTER + [S_ID]) then
        begin
          Operand:= _Scanner.Value;
          // get the Value of Identifier
          if _Lookahead = S_ID then
            if _genCode then
              begin
                if Operand < _SymbolList.Count then
                  Operand:= _SymbolList.Items[Operand].Value
                else
                  addFatalError(getString(rsUnknownIdentifier));
              end
            else
              Operand:= 1;
          // Check Register
          if Operand in [1..6] then
            begin
              Code:= generateCode(result,OpCode,Operand,0);
              if result then
                begin
                  if Int64(_ILC + 1) <= Int64(MaxILC) then
                    begin
                      if _genCode then
                        _Program.Add(TProgramItem.Create(_ILC,Code.V0,_Line));
                      Inc(_ILC);
                      _Lookahead:= _Scanner.Lexem;
                    end
                  else { if Int64(_ILC + 1) <= Int64(MaxILC) then }
                    addFatalError(getString(rsRAMOverflow));
                end
              else { if result then }
                addError(getString(rsUnknownStatement));  // Internal Error: Instruction not found
            end
          else { if Operand in [1..6] then }
            addError(getString(rsInvalidRegister));
        end
      else  { if _Lookahead in (S_NUMBER + S_REGISTER + [S_ID]) then }
        begin
          if _Lookahead <> S_INVALIDNUMBER then
            addError(getString(rsMissingOperand))
          else
            addError(getString(rsInvalidNumber)+' '+_Scanner.SubStr);
        end;    
    end
  else { if _Scanner.Line = _Line then }
    addError(getString(rsNewLine));
end;

{ Opcode_Type_1_2 ::= (ADI | ANI | ORI | SUI | SBI | CPI | XRI | ACI)
                      (Number|ID)                               // Value <= 255
}
function Ti8008Parser.Opcode_Type_1_2: Boolean;
var
  OpCode: Integer;
  Operand: Integer;
  Code: TrippleByte;

begin
  OpCode:= _Lookahead;
  if _Scanner.Line = _Line then
    begin
      _Lookahead:= _Scanner.Lexem;
      if _Lookahead in (S_NUMBER + [S_ID]) then
        begin
          Operand:= _Scanner.Value;
          // get the Value of Identifier
          if _Lookahead = S_ID then
            if _genCode then
              begin
                if Operand < _SymbolList.Count then
                  Operand:= _SymbolList.Items[Operand].Value
                else
                  addFatalError(getString(rsUnknownIdentifier));
              end
            else
              Operand:= 0;
          // Check Operand
          if not (Operand in [0..255]) and not _genCode then
            addWarning(getString(rsOperandOverflow));
          Code:= generateCode(result,OpCode,Operand,0);
          if result then
            begin
              if Int64(_ILC + 2) <= Int64(MaxILC) then
                begin
                  if _genCode then
                    _Program.Add(TProgramItem.Create(_ILC,Code.V0,_Line));
                  Inc(_ILC);
                  if _genCode then
                    _Program.Add(TProgramItem.Create(_ILC,Code.V1,_Line));
                  Inc(_ILC);
                  _Lookahead:= _Scanner.Lexem;
                end
              else { if Int64(_ILC + 2) <= Int64(MaxILC) then }
                addFatalError(getString(rsRAMOverflow));
            end
          else { if result then }
            addError(getString(rsUnknownStatement)); // Internal Error: Instruction not found
        end
      else  { if _Lookahead in (S_NUMBER + [S_ID]) then }
        begin
          if _Lookahead <> S_INVALIDNUMBER then
            addError(getString(rsMissingOperand))
          else
            addError(getString(rsInvalidNumber)+' '+_Scanner.SubStr);
        end;    
    end
  else { if _Scanner.Line = _Line then }
    addError(getString(rsNewLine));
end;

{ Opcode_Type_1_3 ::= RST (NUMBER | ID)  // Value = [0|8|16|...|56]
}
function Ti8008Parser.Opcode_Type_1_3: Boolean;
var
  OpCode: Integer;
  Operand: Integer;
  Code: TrippleByte;

begin
  OpCode:= _Lookahead;
  if _Scanner.Line = _Line then
    begin
      _Lookahead:= _Scanner.Lexem;
      if _Lookahead in (S_NUMBER + [S_ID]) then
        begin
          Operand:= _Scanner.Value;
          // get the Value of Identifier
          if _Lookahead = S_ID then
            if _genCode then
              begin
                if Operand < _SymbolList.Count then
                  Operand:= _SymbolList.Items[Operand].Value
                else
                  addFatalError(getString(rsUnknownIdentifier));
              end
            else
              Operand:= 0;
          // Check Operand
          if Operand in [0,8,16,24,32,40,48,56] then
            begin
              Code:= generateCode(result,OpCode,Operand,0);
              if result then
                begin
                  if Int64(_ILC + 1) <= Int64(MaxILC) then
                    begin
                      if _genCode then
                        _Program.Add(TProgramItem.Create(_ILC,Code.V0,_Line));
                      Inc(_ILC);
                      _Lookahead:= _Scanner.Lexem;
                    end
                  else { if Int64(_ILC + 1) <= Int64(MaxILC) then }
                    addFatalError(getString(rsRAMOverflow));
                end
              else { if result then }
                addError(getString(rsUnknownStatement));  // Internal Error: Instruction not found
            end
          else { if Operand in [0,8,16,24,32,40,48,56] then }
            addError(getString(rsInvalidOperand));
        end
      else  { if _Lookahead in (S_NUMBER + [S_ID]) then }
        begin
          if _Lookahead <> S_INVALIDNUMBER then
            addError(getString(rsMissingOperand))
          else
            addError(getString(rsInvalidNumber)+' '+_Scanner.SubStr);
        end;    
    end
  else { if _Scanner.Line = _Line then }
    addError(getString(rsNewLine));
end;

{ Opcode-Type_1_4 ::= IN (NUMBER | ID)  // Value = [0..7]
}
function Ti8008Parser.Opcode_Type_1_4: Boolean;
var
  OpCode: Integer;
  Operand: Integer;
  Code: TrippleByte;

begin
  OpCode:= _Lookahead;
  if _Scanner.Line = _Line then
    begin
      _Lookahead:= _Scanner.Lexem;
      if _Lookahead in (S_NUMBER + [S_ID]) then
        begin
          Operand:= _Scanner.Value;
          // get the Value of Identifier
          if _Lookahead = S_ID then
            if _genCode then
              begin
                if Operand < _SymbolList.Count then
                  Operand:= _SymbolList.Items[Operand].Value
                else
                  addFatalError(getString(rsUnknownIdentifier));
              end
            else
              Operand:= 0;
          // Check Operand
          if Operand in [0..7] then
            begin
              Code:= generateCode(result,OpCode,Operand,0);
              if result then
                begin
                  if Int64(_ILC + 1) <= Int64(MaxILC) then
                    begin
                      if _genCode then
                        _Program.Add(TProgramItem.Create(_ILC,Code.V0,_Line));
                      Inc(_ILC);
                      _Lookahead:= _Scanner.Lexem;
                    end
                  else { if Int64(_ILC + 1) <= Int64(MaxILC) then }
                    addFatalError(getString(rsRAMOverflow));
                end
              else { if result then }
                addError(getString(rsUnknownStatement)); // Internal Error: Instruction not found
            end
          else { if Operand in [0..7] then }
            addError(getString(rsInvalidRegister));
        end
      else  { if _Lookahead in (S_NUMBER + [S_ID]) then }
        begin
          if _Lookahead <> S_INVALIDNUMBER then
            addError(getString(rsMissingOperand))
          else
            addError(getString(rsInvalidNumber)+' '+_Scanner.SubStr);
        end;    
    end
  else { if _Scanner.Line = _Line then }
    addError(getString(rsNewLine));
end;

{ Opcode-Type_1_4 ::= OUT (NUMBER | ID)  // Value = [8..31]
}
function Ti8008Parser.Opcode_Type_1_5: Boolean;
var
  OpCode: Integer;
  Operand: Integer;
  Code: TrippleByte;

begin
  OpCode:= _Lookahead;
  if _Scanner.Line = _Line then
    begin
      _Lookahead:= _Scanner.Lexem;
      if _Lookahead in (S_NUMBER + [S_ID]) then
        begin
          Operand:= _Scanner.Value;
          // get the Value of Identifier
          if _Lookahead = S_ID then
            if _genCode then
              begin
                if Operand < _SymbolList.Count then
                  Operand:= _SymbolList.Items[Operand].Value
                else
                  addFatalError(getString(rsUnknownIdentifier));
              end
            else
              Operand:= 8;
          // Check Operand
          if Operand in [8..31] then
            begin
              Code:= generateCode(result,OpCode,Operand,0);
              if result then
                begin
                  if Int64(_ILC + 1) <= Int64(MaxILC) then
                    begin
                      if _genCode then
                        _Program.Add(TProgramItem.Create(_ILC,Code.V0,_Line));
                      Inc(_ILC);
                      _Lookahead:= _Scanner.Lexem;
                    end
                  else { if Int64(_ILC + 1) <= Int64(MaxILC) then }
                    addFatalError(getString(rsRAMOverflow));
                end
              else { if result then }
                addError(getString(rsUnknownStatement)); // Internal Error: Instruction not found
            end
          else { if Operand in [8..31] then }
            addError(getString(rsInvalidOperand));
        end
      else  { if _Lookahead in (S_NUMBER + [S_ID]) then }
        begin
          if _Lookahead <> S_INVALIDNUMBER then
            addError(getString(rsMissingOperand))
          else
            addError(getString(rsInvalidNumber)+' '+_Scanner.SubStr);
        end;    
    end
  else { _Scanner.Line = _Line }
    addError(getString(rsNewLine));
end;

{ Opcode_Type_1_6 ::= (CNC | CC | CM | CP | CPO | CPE | CZ | CNZ |  CALL |
                       JNC | JC | JM | JP | JPO | JPE | JZ | JNZ |  JMP  | ORG)
                      (NUMBER | ID)   // Value <= 2^14-1
}
function Ti8008Parser.Opcode_Type_1_6(var ILCtmp: LongWord): Boolean;
var
  OpCode: Integer;
  Operand: Integer;
  Code: TrippleByte;

begin
  OpCode:= _Lookahead;
  if _Scanner.Line = _Line then
    begin
      _Lookahead:= _Scanner.Lexem;
      if _Lookahead in (S_NUMBER + [S_ID]) then
        begin
          Operand:= _Scanner.Value;
          // get the Value of Identifier
          if _Lookahead = S_ID then
            if _genCode then
              begin
                if Operand < _SymbolList.Count then
                  Operand:= _SymbolList.Items[Operand].Value
                else
                  addFatalError(getString(rsUnknownIdentifier));
              end
            else
              Operand:= 0;
          if opCode <> S_ORG then
            begin
              // Check Operand
              if ((Operand < 0) or (Operand > 16383)) and not _GenCode then
                addWarning(getString(rsOperandOverflow));
              Code:= generateCode(result,OpCode,Operand,0);
              if result then
                begin
                  if Int64(_ILC + 3) <= Int64(MaxILC) then
                    begin
                      if _genCode then
                        _Program.Add(TProgramItem.Create(_ILC,Code.V0,_Line));
                      Inc(_ILC);
                      if _genCode then
                        _Program.Add(TProgramItem.Create(_ILC,Code.V1,_Line));
                      Inc(_ILC);
                      if _genCode then
                        _Program.Add(TProgramItem.Create(_ILC,Code.V2,_Line));
                      Inc(_ILC);
                      _Lookahead:= _Scanner.Lexem;
                    end
                  else { if Int64(_ILC + 3) <= Int64(MaxILC) then }
                    addFatalError(getString(rsRAMOverflow));
                end
              else { if result then }
                addError(getString(rsUnknownStatement));  // Internal Error: Instruction not found
            end
          else { if opCode <> S_ORG then }
            begin
              if Int64(Operand) <= Int64(MaxILC) then
                begin
                  ILCtmp:= Operand mod 16383;
                  _ILC:= ILCtmp;
                  _Lookahead:= _Scanner.Lexem;
                end
              else { if Int64(_ILC + 3) <= Int64(MaxILC) then }
                addFatalError(getString(rsRAMOverflow));
            end;
        end
      else  { if _Lookahead in (S_NUMBER + [S_ID]) then }
        begin
          if _Lookahead <> S_INVALIDNUMBER then
            addError(getString(rsMissingOperand))
          else
            addError(getString(rsInvalidNumber)+' '+_Scanner.SubStr);
        end;    
    end
  else { if _Scanner.Line = _Line then }
    addError(getString(rsNewLine));
end;

{ Opcopde_Type_2_0 ::= MVI Register ',' NUMBER  // Value <= 255
}
function Ti8008Parser.Opcode_Type_2_0: Boolean;
var
  OpCode: Integer;
  Operand1: Integer;
  Operand2: Integer;
  Code: TrippleByte;

begin
  OpCode:= _Lookahead;
  if _Scanner.Line = _Line then
    begin
      _Lookahead:= _Scanner.Lexem;
      if _Lookahead in (S_NUMBER + S_REGISTER + [S_ID]) then
        begin
          Operand1:= _Scanner.Value;
          // get the Value of Identifier
          if _Lookahead = S_ID then
            if _genCode then
              begin
                if Operand1 < _SymbolList.Count then
                  Operand1:= _SymbolList.Items[Operand1].Value
                else
                  addFatalError(getString(rsUnknownIdentifier));
              end
            else
              Operand1:= 0;
          // Check Operand1
          if Operand1 in [0..7] then
            begin
              if _Scanner.Line = _Line then
                begin
                  if _Scanner.Lexem = S_POINT then
                    begin
                      if _Scanner.Line = _Line then
                        begin
                          _Lookahead:= _Scanner.Lexem;
                          if _Lookahead in (S_NUMBER + [S_ID]) then
                            begin
                              Operand2:= _Scanner.Value;
                              // get the Value of Identifier
                              if _Lookahead = S_ID then
                                if _genCode then
                                  begin
                                    if Operand2 < _SymbolList.Count then
                                      Operand2:= _SymbolList.Items[Operand2].Value
                                    else
                                      addFatalError(getString(rsUnknownIdentifier));
                                  end
                                else
                                  Operand2:= 0;
                              // Check Operand2
                              if not (Operand2 in [0..255]) and not _genCode then
                                addWarning(getString(rsOperandOverflow));
                              Code:= generateCode(result,OpCode,Operand1,Operand2);
                              if result then
                                begin
                                  if Int64(_ILC + 2) <= Int64(MaxILC) then
                                    begin
                                      if _genCode then
                                        _Program.Add(TProgramItem.Create(_ILC,Code.V0,_Line));
                                      Inc(_ILC);
                                      if _genCode then
                                        _Program.Add(TProgramItem.Create(_ILC,Code.V1,_Line));
                                      Inc(_ILC);
                                      _Lookahead:= _Scanner.Lexem;
                                    end
                                  else { if Int64(_ILC + 2) <= Int64(MaxILC) then }
                                    addFatalError(getString(rsRAMOverflow));
                                end
                              else { if result then }
                                addError(getString(rsUnknownStatement)); // Internal Error: Instruction not found
                            end
                          else { if _Lookahead in (S_NUMBER + [S_ID]) then }
                            begin
                              if _Lookahead <> S_INVALIDNUMBER then
                                addError(getString(rsMissingOperand))
                              else
                                addError(getString(rsInvalidNumber)+' '+_Scanner.SubStr);
                            end;
                        end
                      else { if _Scanner.Line = _Line then }
                        addError(getString(rsNewLine));
                    end
                  else { if _Scanner.Lexem = S_POINT then }
                    addError(getString(rsMissingOperand));
                end
              else { if _Scanner.Line = _Line then }
                addError(getString(rsNewLine));
            end
          else { if Operand1 in [0..7] then }
            addError(getString(rsInvalidRegister));
        end
      else { if _Lookahead in (S_NUMBER + S_REGISTER + [S_ID]) then }
        begin
          if _Lookahead <> S_INVALIDNUMBER then
            addError(getString(rsMissingOperand))
          else
            addError(getString(rsInvalidNumber)+' '+_Scanner.SubStr);
        end;
    end
  else { if _Scanner.Line = _Line then }
    addError(getString(rsNewLine));
end;

{ Opcopde_Type_2_1 ::= MOV Register ',' Register
}
function Ti8008Parser.Opcode_Type_2_1: Boolean;
var
  OpCode: Integer;
  Operand1: Integer;
  Operand2: Integer;
  Code: TrippleByte;

begin
  OpCode:= _Lookahead;
  if _Scanner.Line = _Line then
    begin
      _Lookahead:= _Scanner.Lexem;
      if _Lookahead in (S_NUMBER + S_REGISTER + [S_ID]) then
        begin
          Operand1:= _Scanner.Value;
          // get the Value of Identifier
          if _Lookahead = S_ID then
            if _genCode then
              begin
                if Operand1 < _SymbolList.Count then
                  Operand1:= _SymbolList.Items[Operand1].Value
                else
                  addFatalError(getString(rsUnknownIdentifier));
              end
            else
              Operand1:= 0;
          // Check Operand1
          if Operand1 in [0..7] then
            begin
              if _Scanner.Line = _Line then
                begin
                  if _Scanner.Lexem = S_POINT then
                    begin
                      if _Scanner.Line = _Line then
                        begin
                          _Lookahead:= _Scanner.Lexem;
                          if _Lookahead in (S_NUMBER + S_REGISTER + [S_ID]) then
                            begin
                              Operand2:= _Scanner.Value;
                              // get the Value of Identifier
                              if _Lookahead = S_ID then
                                if _genCode then
                                  begin
                                    if Operand2 < _SymbolList.Count then
                                      Operand2:= _SymbolList.Items[Operand2].Value
                                    else
                                      addFatalError(getString(rsUnknownIdentifier));
                                  end
                                else
                                  Operand2:= 0;
                              // Check Operand2
                              if Operand2 in [0..7] then
                                begin
                                  if (Operand1 = 7) and (Operand2 = 7) and not _genCode then // show warning only one time
                                    addWarning(getString(rsMOV2HLTWarning)); // MOV M, M -> HLT
                                  Code:= generateCode(result,OpCode,Operand1,Operand2);
                                  if result then
                                    begin
                                      if Int64(_ILC + 1) <= Int64(MaxILC) then
                                        begin
                                          if _genCode then
                                            _Program.Add(TProgramItem.Create(_ILC,Code.V0,_Line));
                                          Inc(_ILC);
                                          _Lookahead:= _Scanner.Lexem;
                                        end
                                      else { if Int64(_ILC + 1) <= Int64(MaxILC) then }
                                        addFatalError(getString(rsRAMOverflow));
                                    end
                                  else { if result then }
                                    addError(getString(rsUnknownStatement)); // Internal Error: Instruction not found
                                end
                              else { if Operand2 in [0..7] then }
                                addError(getString(rsInvalidRegister));
                            end
                          else { if _Lookahead in (S_NUMBER + S_REGISTER + [S_ID]) then }
                            begin
                              if _Lookahead <> S_INVALIDNUMBER then
                                addError(getString(rsMissingOperand))
                              else
                                addError(getString(rsInvalidNumber)+' '+_Scanner.SubStr);
                            end;
                        end
                      else { if _Scanner.Line = _Line then }
                        addError(getString(rsNewLine));
                    end
                  else { if _Scanner.Lexem = S_POINT then }
                    addError(getString(rsMissingOperand));
                end
              else { if _Scanner.Line = _Line then }
                addError(getString(rsNewLine));
            end
          else { if Operand1 in [0..7] then }
            addError(getString(rsInvalidRegister));
        end
      else { if _Lookahead in (S_NUMBER + S_REGISTER + [S_ID]) then }
        begin
          if _Lookahead <> S_INVALIDNUMBER then
            addError(getString(rsMissingOperand))
          else
            addError(getString(rsInvalidNumber)+' '+_Scanner.SubStr);
        end;
    end
  else { if _Scanner.Line = _Line then }
    addError(getString(rsNewLine));
end;

function Ti8008Parser.Parse(theProgram: TProgram): Boolean;
var
  Size: Integer;
begin
  Size:= 0;
  if Assigned(OnASMStart) then
    OnASMStart(Self);
  _Program:= theProgram;
  if Assigned(_Program) and Assigned(_Scanner) and
     Assigned(_ErrorList) and Assigned(_SymbolList) then
    begin
      _OnItemUpdate:= theProgram.OnItemUpdate;
      // set the 'ItemUpdateEvent' to prevent overrideing programcode
      theProgram.OnItemUpdate:= ItemUpdateEvent;
      // start Phase 1
      Init(false);
      result:= i8008Program;
      if result then
        begin
          // start Phase 2
          Init(true);
          result:= i8008Program;
          if result then
            Size:= _Program.Count;
        end
      else
        result:= false;
      theProgram.OnItemUpdate:= _OnItemUpdate;
    end
  else
    result:= false;
  if Assigned(OnASMStop) then
    OnASMStop(Self,Size,not result);
end;

function Ti8008Parser.MaxILC: Integer;
begin
  result:= 16383; // 2^14-1
end;
{ ********** Ti8008Parser ********* }
{ *********** TAssembler ********** }
constructor TAssembler.Create;
begin
  _Error:= nil;
  _Symbol:= nil;
  _Scanner:= nil;
  _Parser:= nil;
end;

constructor TAssembler.Create(CaseSensitive: Boolean);
begin
  _Error:= nil;
  _Symbol:= nil;
  _Scanner:= nil;
  _Parser:= nil;
end;

destructor TAssembler.Destroy;
begin
  if Assigned(_Parser) then
    _Parser.Free;
  if Assigned(_Scanner) then
    _Scanner.Free;
  if Assigned(_Symbol) then
    _Symbol.Free;
  if Assigned(_Error) then
    _Error.Free;
  inherited Destroy;
end;

function TAssembler.Assemble(Source: String; theProgram: TProgram; Project: String): Boolean;
var
  ASMProgress: TASMProgressForm;
begin
  if Assigned(_Scanner) and Assigned(_Parser) then
    begin
      _Scanner.Initialize(Source);
      if ShowProgress then
        begin
          ASMProgress:= TASMProgressForm.Create(nil);
          _Parser.OnASMStart:= ASMProgress.ASMStart;
          _Parser.OnASMProgress:= ASMProgress.ASMProgress;
          _Parser.OnASMStop:= ASMProgress.ASMStop;
          ASMProgress.Project:= Project;
          result:= ASMProgress.Execute(_Parser,theProgram);
          ASMProgress.Free;
        end
      else
        begin
          _Parser.OnASMStart:= nil;
          _Parser.OnASMProgress:= nil;
          _Parser.OnASMStop:= nil;
          result:= _Parser.Parse(theProgram);
        end;
    end
  else
    result:= false;    
end;
{ *********** TAssembler ********** }
{ ********* Ti8008Assembler ******* }
constructor Ti8008Assembler.Create;
begin
  inherited Create;
  _Error:= TErrorList.Create;
  _Symbol:= TSymbolList.Create;
  _Scanner:= Ti8008Scanner.Create(_Symbol);
  _Parser:= Ti8008Parser.Create(_Symbol,_Scanner,_Error);
end;

constructor Ti8008Assembler.Create(CaseSensitive: Boolean);
begin
  inherited Create(CaseSensitive);
  _Error:= TErrorList.Create;
  _Symbol:= TSymbolList.Create(CaseSensitive);
  _Scanner:= Ti8008Scanner.Create(_Symbol);
  _Parser:= Ti8008Parser.Create(_Symbol,_Scanner,_Error);
end;
{ ********* Ti8008Assembler ******* }

function IntToInt(Value: String; var Check: Integer): Integer;
var
  LengthStr, iPos: Integer;

begin
  LengthStr:= Length(Value);
  result:= 0;
  Check:= 0;
  iPos:= 1;
  // HORNER
  while (iPos <= LengthStr) and (Check = 0) do
    begin
      case Value[iPos] of
        '0': if result > MAXINT div 10 then
               Check:= iPos
             else
               result:= result * 10;
        '1': if result > (MAXINT-1) div 10 then
               Check:= iPos
             else
               result:= result * 10 + 1;
        '2': if result > (MAXINT-2) div 10 then
               Check:= iPos
             else
               result:= result * 10 + 2;
        '3': if result > (MAXINT-3) div 10 then
               Check:= iPos
             else
               result:= result * 10 + 3;
        '4': if result > (MAXINT-4) div 10 then
               Check:= iPos
             else
               result:= result * 10 + 4;
        '5': if result > (MAXINT-5) div 10 then
               Check:= iPos
             else
               result:= result * 10 + 5;
        '6': if result > (MAXINT-6) div 10 then
               Check:= iPos
             else
               result:= result * 10 + 6;
        '7': if result > (MAXINT-7) div 10 then
               Check:= iPos
             else
               result:= result * 10 + 7;
        '8': if result > (MAXINT-8) div 10 then
               Check:= iPos
             else
               result:= result * 10 + 8;
        '9': if result > (MAXINT-9) div 10 then
               Check:= iPos
             else
               result:= result * 10 + 9;
      else
        Check:= iPos;
      end;
      Inc(iPos);
    end;
end;

function OctToInt(Value: String; var Check: Integer): Integer;
var
  LengthStr, iPos: Integer;

begin
  LengthStr:= Length(Value);
  result:= 0;
  Check:= 0;
  iPos:= 1;
  // HORNER
  while (iPos <= LengthStr) and (Check = 0) do
    begin
      case Value[iPos] of
        '0': if result > MAXINT div 8 then
               Check:= iPos
             else
               result:= result * 8;
        '1': if result > (MAXINT-1) div 8 then
               Check:= iPos
             else
               result:= result * 8 + 1;
        '2': if result > (MAXINT-2) div 8 then
               Check:= iPos
             else
               result:= result * 8 + 2;
        '3': if result > (MAXINT-3) div 8 then
               Check:= iPos
             else
               result:= result * 8 + 3;
        '4': if result > (MAXINT-4) div 8 then
               Check:= iPos
             else
               result:= result * 8 + 4;
        '5': if result > (MAXINT-5) div 8 then
               Check:= iPos
             else
               result:= result * 8 + 5;
        '6': if result > (MAXINT-6) div 8 then
               Check:= iPos
             else
               result:= result * 8 + 6;
        '7': if result > (MAXINT-7) div 8 then
               Check:= iPos
             else
               result:= result * 8 + 7;
      else
        Check:= iPos;
      end;
      Inc(iPos);
    end;
end;

function HexToInt(Value: String; var Check: Integer): Integer;
var
  LengthStr, iPos: Integer;

begin
  LengthStr:= Length(Value);
  result:= 0;
  Check:= 0;
  iPos:= 1;
  // HORNER
  while (iPos <= LengthStr) and (Check = 0) do
    begin
      case Value[iPos] of
            '0': if result > MAXINT div 16 then
                   Check:= iPos
                 else
                   result:= result * 16;
            '1': if result > (MAXINT-1) div 16 then
                   Check:= iPos
                 else
                   result:= result * 16 + 1;
            '2': if result > (MAXINT-2) div 16 then
                   Check:= iPos
                 else
                   result:= result * 16 + 2;
            '3': if result > (MAXINT-3) div 16 then
                   Check:= iPos
                 else
                   result:= result * 16 + 3;
            '4': if result > (MAXINT-4) div 16 then
                   Check:= iPos
                 else
                   result:= result * 16 + 4;
            '5': if result > (MAXINT-5) div 16 then
                   Check:= iPos
                 else
                   result:= result * 16 + 5;
            '6': if result > (MAXINT-6) div 16 then
                   Check:= iPos
                 else
                   result:= result * 16 + 6;
            '7': if result > (MAXINT-7) div 16 then
                   Check:= iPos
                 else
                   result:= result * 16 + 7;
            '8': if result > (MAXINT-8) div 16 then
                   Check:= iPos
                 else
                   result:= result * 16 + 8;
            '9': if result > (MAXINT-9) div 16 then
                   Check:= iPos
                 else
                   result:= result * 16 + 9;
        'A','a': if result > (MAXINT-10) div 16 then
                   Check:= iPos
                 else
                   result:= result * 16 + 10;
        'B','b': if result > (MAXINT-11) div 16 then
                   Check:= iPos
                 else
                   result:= result * 16 + 11;
        'C','c': if result > (MAXINT-12) div 16 then
                   Check:= iPos
                 else
                   result:= result * 16 + 12;
        'D','d': if result > (MAXINT-13) div 16 then
                   Check:= iPos
                 else
                   result:= result * 16 + 13;
        'E','e': if result > (MAXINT-14) div 16 then
                   Check:= iPos
                 else
                   result:= result * 16 + 14;
        'F','f': if result > (MAXINT-15) div 16 then
                   Check:= iPos
                 else
                   result:= result * 16 + 15;
      else
        Check:= iPos;
      end;
      Inc(iPos);
    end;
end;

function BinToInt(Value: String; var Check: Integer): Integer;
var
  LengthStr, iPos: Integer;

begin
  LengthStr:= Length(Value);
  result:= 0;
  Check:= 0;
  iPos:= 1;
  // HORNER
  while (iPos <= LengthStr) and (Check = 0) do
    begin
      case Value[iPos] of
        '0': if result > MAXINT div 2 then
               Check:= iPos
             else
               result:= result * 2;
        '1': if result > (MAXINT-1) div 2 then
               Check:= iPos
             else
               result:= result * 2 + 1;
      else
        Check:= iPos;
      end;
      Inc(iPos);
    end;
end;

end.
