unit uProcessor;

interface

uses
  Windows, Classes, SysUtils, uAssembler, uTimer;

type

  IRefresh = interface(IInterface)
    procedure RefreshObject(Sender: TObject);
    procedure Reset(Sender: TObject);
  end;

  IStack = interface(IRefresh)
    procedure SPChanged(Sender: TObject; SP: Byte);
    procedure Change(Sender: TObject; Index: Byte; Value: Word);
    procedure Push(Sender: TObject; Index: Byte; Value: Word);
    procedure Pop(Sender: TObject; Index: Byte; Value: Word);
  end;

  IRAM = interface(IRefresh)
    procedure RAMUpdate(Sender: TObject; Address: Word; Value: Byte);
  end;

  IRegister = interface(IRefresh)
    procedure RegisterUpdate(Sender: TObject; Index: Byte; Value: Byte);
    procedure RegisterReset(Sender: TObject; Index: Byte);
  end;

  IFlags = interface(IRefresh)
    procedure CarryFlagUpdate(Sender: TObject; Value: Boolean);
    procedure SignFlagUpdate(Sender: TObject; Value: Boolean);
    procedure ZeroFlagUpdate(Sender: TObject; Value: Boolean);
    procedure ParityFlagUpdate(Sender: TObject; Value: Boolean);
  end;

  IProgramCounter = interface(IRefresh)
    procedure PCUpdate(Sender: TObject; Value: Word);
  end;

  IIOPorts = interface(IRefresh)
    procedure PortUpdate(Sender: TObject; Index: Byte; Value: Byte);
    procedure PortAction(Sender: TObject; Active: Boolean);
  end;

  IProcessor = interface(IInterface)
    procedure BeforeCycle(Sender: TObject);
    procedure AfterCycle(Sender: TObject);
    procedure StateChange(Sender: TObject; Halt: Boolean);
  end;

  Ti8008Stack = class(TObject)
  private
    _SP: Byte;
    _Count: Byte;
    _Items: array of Word;
    _StackListenerList: TInterfaceList;
    _PCListenerList: TInterfaceList;
    procedure IPCUpdate;
    procedure ISPChanged;
    procedure IChange(Index: Byte);
    procedure IPush(Index: Byte);
    procedure IPop(Index: Byte);
    procedure IReset;
    procedure IRefresh;
    procedure setItem(Index: Byte; Value: Word);
    function getItem(Index: Byte): Word;
    procedure setStackPointer(Value: Byte);
    function getProgramCounter: Word;
    procedure setProgramCounter(Value: Word);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Push(Value: Word);
    function Pop: Word;
    function LoadFromStream(Value: TStream): Boolean;
    function SaveToStream(Value: TStream): Boolean;
    procedure ResetStackPointer;
    procedure ResetProgramCounter;
    procedure Reset;
    procedure RefreshObject;
    procedure AddStackListener(Listener: IStack);
    procedure DelStackListeners;
    procedure AddProgramCounterListener(Listener: IProgramCounter);
    procedure DelProgramCounterListeners;
    procedure IncProgramCounter;
    class function Size: Byte;
    property Count: Byte read _Count;
    property Items[Index: Byte]: Word read getItem write setItem;
    property StackPointer: Byte read _SP write setStackPointer;
    property ProgramCounter: Word read getProgramCounter write setProgramCounter;
  end;

  TRAMUpdateEvent = procedure(Sender: TObject; Address: Word; Value: Byte) of object;

  TRAMResetEvent = procedure(Sender: TObject) of object;

  Ti8008RAM = class(TObject)
  private
    _Size: Word;
    _RAM: array of Byte;
    _OnRAMUpdate: TRAMUpdateEvent;
    _OnRAMReset: TRAMResetEvent;
    _ListenerList: TInterfaceList;
    procedure IRefresh;
    procedure IRAMUpdate(Address: Word; Value: Byte);
    procedure IReset;
    function getRAM(Address: Word): Byte;
    procedure setRAM(Address: Word; Value: Byte);
    property OnRAMUpdate: TRAMUpdateEvent read _OnRAMUpdate write _OnRAMUpdate;
    property OnRAMReset: TRAMResetEvent read _OnRAMReset write _OnRAMReset;
  public
    constructor Create;
    destructor Destroy; override;
    function LoadFromStream(Value: TStream): Boolean;
    function SaveToStream(Value: TStream): Boolean;
    procedure Reset;
    procedure RefreshObject;
    procedure AddListener(Listener: IRAM);
    procedure DelListeners;
    procedure Load(AProgram: TProgram);
    property Size: Word read _Size;
    property RAM[Address: Word]: Byte read getRAM write setRAM;
  end;

  Ti8008Register = class(TObject)
  private
    _Values: array [0..6] of Byte;
    _RAM: Ti8008RAM;
    _ListenerList: TInterfaceList;
    function getHL: Word;
    function getName(Index: Byte): String;
    function getValue(Index: Byte): Byte;
    procedure setValue(Index: Byte; Value: Byte);
    procedure IRegisterUpdate(Index: Byte; Value: Byte);
    procedure IRegisterReset(Index: Byte);    
    procedure IReset;
    procedure IRefresh;
    procedure OnRAMUpdate(Sender: TObject; Address: Word; Value: Byte);
    procedure OnRAMReset(Sender: TObject);
  public
    constructor Create(RAM: Ti8008RAM); overload;
    constructor Create; overload;
    destructor Destroy; override;
    function LoadFromStream(Value: TStream): Boolean;
    function SaveToStream(Value: TStream): Boolean;
    procedure Reset;
    procedure RefreshObject;
    procedure AddListener(Listener: IRegister);
    procedure DelListeners;
    function Count: Byte;
    property Name[Index: Byte]: String read getName;
    property Value[Index: Byte]: Byte read getValue write setValue;
  end;

  TFlag = (fCarry, fSign, fParity, fZero);

  Ti8008Flags = class(TObject)
  private
    _Carry: Boolean;
    _Sign: Boolean;
    _Zero: Boolean;
    _Parity: Boolean;
    _ListenerList: TInterfaceList;    
    procedure setCarry(Value: Boolean);
    procedure setSign(Value: Boolean);
    procedure setZero(Value: Boolean);
    procedure setParity(Value: Boolean);
    procedure ICarryFlagUpdate;
    procedure ISignFlagUpdate;
    procedure IZeroFlagUpdate;
    procedure IParityFlagUpdate;
    procedure IReset;
    procedure IRefresh;
  public
    constructor Create;
    destructor Destroy; override;
    function LoadFromStream(Value: TStream): Boolean;
    function SaveToStream(Value: TStream): Boolean;
    procedure Reset;
    procedure RefreshObject;
    procedure AddListener(Listener: IFlags);
    procedure DelListeners;
    property Carry: Boolean read _Carry write setCarry;
    property Sign: Boolean read _Sign write setSign;
    property Zero: Boolean read _Zero write setZero;
    property Parity: Boolean read _Parity write setParity;
  end;

  TPortType = (ptUnknown, ptIN, ptOUT);

  TIOPorts = class(TObject)
  private
    _Ports: array of Byte;
    _ListenerList: TInterfaceList;
    _PortFile: TFilename;
    _PortStream: TStream;
    _PortFileActive: Boolean;
    procedure IPortUpdate(Index, Value: Byte);
    procedure IPortAction;
    procedure IReset;
    procedure IRefresh;
    function getValue(Index: Byte): Byte;
    procedure setValue(Index: Byte; Value: Byte);
    procedure setPortFile(Value: TFilename);
    function getPortFileActive: Boolean;
    procedure setPortFileActive(Value: Boolean);
    procedure OnPortRead(Sender: TObject);
    procedure OnPortWrite(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
    function LoadFromStream(Value: TStream): Boolean;
    function SaveToStream(Value: TStream): Boolean;
    procedure Reset;
    procedure ResetPortFile;
    procedure RefreshObject;
    procedure AddListener(Listener: IIOPorts);
    procedure DelListeners;
    class function FirstPortNo: Byte; virtual; abstract;
    class function Count: Byte; virtual; abstract;
    class function PortType: TPortType; virtual; abstract;
    property Value[Index: Byte]: Byte read getValue write setValue;
    property PortFile: TFilename read _PortFile write setPortFile;
    property PortFileActive: Boolean read getPortFileActive write setPortFileActive;
  end;

  Ti8008IPorts = class(TIOPorts)
  public
    class function FirstPortNo: Byte; override;
    class function Count: Byte; override;
    class function PortType: TPortType; override;
  end;

  Ti8008OPorts = class(TIOPorts)
  public
    class function FirstPortNo: Byte; override;
    class function Count: Byte; override;
    class function PortType: TPortType; override;
  end;

  TPortDataChange = (pdcAfterCycle, pdcAfterInstruction);

  Ti8008Processor = class(TObject)
  private
    _Halt: Boolean;
    _Stack: Ti8008Stack;
    _RAM: Ti8008RAM;
    _Register: Ti8008Register;
    _Flags: Ti8008Flags;
    _IPorts: Ti8008IPorts;
    _OPorts: Ti8008OPorts;
    _PortDataChange: TPortDataChange;
    _ListenerList: TInterfaceList;
    _OnPortRead: TNotifyEvent;
    _OnPortWrite: TNotifyEvent;
    procedure setHalt(Value: Boolean);
    procedure setFlags(Value: Byte);
    function getStack(Address: Byte): Word;
    function getStackPointer: Byte;
    function getStackSize: Byte;
    function getRAM(Address: Word): Byte;
    function getRAMSize: Word;
    function getRegister(Index: Byte): Byte;
    function getRegisterName(Index: Byte): String;
    function getRegisterCount: Byte;
    procedure setCarry(Value: Boolean);
    function getCarry: Boolean;
    procedure setSign(Value: Boolean);
    function getSign: Boolean;
    procedure setZero(Value: Boolean);
    function getZero: Boolean;
    procedure setParity(Value: Boolean);
    function getParity: Boolean;
    function getProgramCounter: Word;
    function getIPorts(Index: Byte): Byte;
    function getFirstIPortNo: Byte;
    function getIPortCount: Byte;
    procedure setOPorts(Index: Byte; Value: Byte);
    function getOPorts(Index: Byte): Byte;
    function getFirstOPortNo: Byte;
    function getOPortCount: Byte;
    procedure IBeforeCycle;
    procedure IAfterCycle;
    procedure IStateChange;
    { i8008 Instructions }
    procedure _INR(RegisterNo: Byte);
    procedure _ADI(Value: Byte);
    procedure _ANI(Value: Byte);
    procedure _ORI(Value: Byte);
    procedure _SUI(Value: Byte);
    procedure _SBI(Value: Byte);
    procedure _CPI(Value: Byte);
    procedure _XRI(Value: Byte);
    procedure _ACI(Value: Byte);
    procedure _MVI(RegisterNo: Byte; Value: Byte);
    procedure _RLC;
    procedure _RAL;
    procedure _RAR;
    procedure _RRC;
    procedure _RNC;
    procedure _RC;
    procedure _RM;
    procedure _RP;
    procedure _RPO;
    procedure _RPE;
    procedure _RZ;
    procedure _RNZ;
    procedure _RET;
    procedure _RST(Address: Byte);
    procedure _DCR(RegisterNo: Byte);
    procedure _IN(PortNo: Byte);
    procedure _OUT(PortNo: Byte);
    procedure _CNC(Address: Word);
    procedure _CC(Address: Word);
    procedure _CM(Address: Word);
    procedure _CP(Address: Word);
    procedure _CPO(Address: Word);
    procedure _CPE(Address: Word);
    procedure _CZ(Address: Word);
    procedure _CNZ(Address: Word);
    procedure _CALL(Address: Word);
    procedure _JMP(Address: Word);
    procedure _JNC(Address: Word);
    procedure _JC(Address: Word);
    procedure _JM(Address: Word);
    procedure _JP(Address: Word);
    procedure _JPO(Address: Word);
    procedure _JPE(Address: Word);
    procedure _JZ(Address: Word);
    procedure _JNZ(Address: Word);
    procedure _ADC(RegisterNo: Byte);
    procedure _XRA(RegisterNo: Byte);
    procedure _CMP(RegisterNo: Byte);
    procedure _SBB(RegisterNo: Byte);
    procedure _SUB(RegisterNo: Byte);
    procedure _ORA(RegisterNo: Byte);
    procedure _ANA(RegisterNo: Byte);
    procedure _ADD(RegisterNo: Byte);
    procedure _MOV(RegisterNo1: Byte; RegisterNo2: Byte);
    property OnPortRead: TNotifyEvent read _OnPortRead write _OnPortRead;
    property OnPortWrite: TNotifyEvent read _OnPortWrite write _OnPortWrite;
    property Halt: Boolean read _Halt write setHalt;
  public
    constructor Create;
    destructor Destroy; override;
    function LoadFromStream(Stream: TStream): Boolean;
    function LoadFromFile(Filename: TFilename): Boolean;
    function SaveToStream(Stream: TStream): Boolean;
    function SaveToFile(Filename: TFilename): Boolean;
    procedure Load(AProgram: TProgram);
    procedure Tick;
    procedure setStackPointer(Value: Byte);
    procedure setStack(Address: Byte; Value: Word);
    procedure setRegister(Index: Byte; Value: Byte);
    procedure setFlag(Flag: TFlag; Value: Boolean);
    procedure setRAM(Address: Word; Value: Byte);
    procedure setIPorts(Index: Byte; Value: Byte);
    procedure setIPortActive(Active: Boolean);
    procedure setOPortActive(Active: Boolean);
    procedure setIPortFile(Filename: TFilename);
    procedure setOPortFile(Filename: TFilename);
    procedure setProgramCounter(Value: Word);
    procedure ReturnFromHLT;
    procedure ResetAll;
    procedure ResetStack;
    procedure ResetStackPointer;
    procedure ResetRAM;
    procedure RefreshRAM(Listener: IRAM);
    procedure ResetRegister;
    procedure ResetFlags;
    procedure ResetProgramCounter;
    procedure RefreshProgramCounter(Listener: IProgramCounter);
    procedure ResetIPortFile;
    procedure ResetIPorts;
    procedure RefreshIPorts(Listener: IIOPorts);
    procedure ResetOPorts;
    procedure RefreshOPorts(Listener: IIOPorts);
    procedure RefreshAllObjects;
    procedure AddStackListener(Listener: IStack);
    procedure AddRAMListener(Listener: IRAM);
    procedure AddRegisterListener(Listener: IRegister);
    procedure AddFlagsListener(Listener: IFlags);
    procedure AddProgramCounterListener(Listener: IProgramCounter);
    procedure AddIPortListener(Listener: IIOPorts);
    procedure AddOPortListener(Listener: IIOPorts);
    procedure AddProcessorListener(Listener: IProcessor);
    procedure DelListeners;
    property Stack[Address: Byte]: Word read getStack write setStack;
    property StackPointer: Byte read getStackPointer write setStackPointer;
    property StackSize: Byte read getStackSize;
    property RAM[Address: Word]: Byte read getRAM write setRAM;
    property RAMSize: Word read getRAMSize;
    property Register[Index: Byte]: Byte read getRegister write setRegister;
    property RegisterName[Index: Byte]: String read getRegisterName;
    property RegisterCount: Byte read getRegisterCount;
    property CarryFlag: Boolean read getCarry write setCarry;
    property SignFlag: Boolean read getSign write setSign;
    property ZeroFlag: Boolean read getZero write setZero;
    property ParityFlag: Boolean read getParity write setParity;
    property ProgramCounter: Word read getProgramCounter write setProgramCounter;
    property IPorts[Index: Byte]: Byte read getIPorts write setIPorts;
    property FirstIPortNo: Byte read getFirstIPortNo;
    property IPortCount: Byte read getIPortCount;
    property OPorts[Index: Byte]: Byte read getOPorts write setOPorts;
    property FirstOPortNo: Byte read getFirstOPortNo;
    property OPortCount: Byte read getOPortCount;
    property PortDataChange: TPortDataChange read _PortDataChange;    
  end;

implementation

type

  TSection = (sStart,sStack,sRAM,sRegister,sFlags,sProgramCounter,sIOPorts);

  TFileVersion = (i8008);

  TSectionHeader = packed record
    Version: TFileVersion;
    Count: Word;
    Kind: TSection;
  end;

const
  _FileVersion = i8008;

  Bits: array [0..7] of Byte = (1,2,4,8,16,32,64,128);

{ ********* Ti8008Stack ********* }
procedure Ti8008Stack.IPCUpdate;
var
  i: Integer;
  Listener: IProgramCounter;
begin
  for i:= 0 to _PCListenerList.Count-1 do
    begin
      Listener:= IProgramCounter(_PCListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.PCUpdate(Self,ProgramCounter);
    end;
end;

procedure Ti8008Stack.ISPChanged;
var
  i: Integer;
  Listener: IStack;
begin
  for i:= 0 to _StackListenerList.Count-1 do
    begin
      Listener:= IStack(_StackListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.SPChanged(Self,_SP);
    end;
  IPCUpdate;  
end;

procedure Ti8008Stack.IChange(Index: Byte);
var
  i: Integer;
  Listener: IStack;
begin
  for i:= 0 to _StackListenerList.Count-1 do
    begin
      Listener:= IStack(_StackListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.Change(Self,Index,Items[Index]);
    end;
  IPCUpdate;  
end;

procedure Ti8008Stack.IPush(Index: Byte);
var
  i: Integer;
  Listener: IStack;
begin
  for i:= 0 to _StackListenerList.Count-1 do
    begin
      Listener:= IStack(_StackListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.Push(Self,Index,Items[Index]);
    end;
  IPCUpdate;
end;

procedure Ti8008Stack.IPop(Index: Byte);
var
  i: Integer;
  Listener: IStack;
begin
  for i:= 0 to _StackListenerList.Count-1 do
    begin
      Listener:= IStack(_StackListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.Push(Self,Index,Items[Index]);
    end;
  IPCUpdate;    
end;

procedure Ti8008Stack.IReset;
var
  i: Integer;
  Listener: IStack;
begin
  for i:= 0 to _StackListenerList.Count-1 do
    begin
      Listener:= IStack(_StackListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.Reset(Self);
    end;
  IPCUpdate;
end;

procedure Ti8008Stack.IRefresh;
var
  i: Integer;
  Listener: IStack;
begin
  for i:= 0 to _StackListenerList.Count-1 do
    begin
      Listener:= IStack(_StackListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.RefreshObject(Self);
    end;
  IPCUpdate;
end;

procedure Ti8008Stack.setItem(Index: Byte; Value: Word);
begin
  if Index < Size then
    begin
      _Items[Index]:= Value mod 16384;
      IChange(Index);
    end;
end;

function Ti8008Stack.getItem(Index: Byte): Word;
begin
  if Index < Size then
    result:= _Items[Index]
  else
    result:= 0;
end;

procedure Ti8008Stack.setStackPointer(Value: Byte);
begin
  _SP:= Value mod Size;
  ISPChanged;  
end;

function Ti8008Stack.getProgramCounter: Word;
begin
  result:= Items[StackPointer];
end;

procedure Ti8008Stack.setProgramCounter(Value: Word);
begin
  Items[StackPointer]:= Value;
end;

constructor Ti8008Stack.Create;
begin
  inherited Create;
  SetLength(_Items,Size);
  _StackListenerList:= TInterfaceList.Create;
  _PCListenerList:= TInterfaceList.Create;
  Reset;
end;

destructor Ti8008Stack.Destroy;
begin
  SetLength(_Items,0);
  _PCListenerList.Free;
  _StackListenerList.Free;
  inherited Destroy;
end;

procedure Ti8008Stack.Push(Value: Word);
begin
  if Size > 0 then
    begin
      Inc(_Count);
      Inc(_SP);
      _SP:= _SP mod Size;
      ISPChanged;
      _Items[_SP]:= Value;
      IPush(_SP);
    end;
end;

function Ti8008Stack.Pop: Word;
begin
  if Size > 0 then
    begin
      Dec(_SP);
      if _SP >= Size then
        _SP:= Size-1;
      ISPChanged;
      result:= _Items[_SP];
      Dec(_Count);
      IPop(_SP);
    end
  else
    result:= 0;
end;

function Ti8008Stack.LoadFromStream(Value: TStream): Boolean;
var
  Header: TSectionHeader;
  i: Word;
begin
  if Assigned(Value) then
    begin
      if (Value.Read(Header,SizeOf(TSectionHeader)) = SizeOf(TSectionHeader)) and
         (Header.Version = _FileVersion) and (Header.Kind = sStack) and
         (Header.Count = High(_Items)+2) then
        begin
          i:= 0;
          while (i < Header.Count-1) and
                (Value.Read(_Items[i],SizeOf(_Items[i])) = SizeOf(_Items[i])) do
            inc(i);
          if Value.Read(_SP,SizeOf(_SP)) = SizeOf(_SP) then
            inc(i);
          result:= i = Header.Count;
          RefreshObject;              
        end
      else
        result:= false;
    end
  else
    result:= false;
end;

function Ti8008Stack.SaveToStream(Value: TStream): Boolean;
var
  Header: TSectionHeader;
  i: Word;
begin
  if Assigned(Value) then
    begin
      Header.Version:= _FileVersion;
      Header.Count:= Size+1;
      Header.Kind:= sStack;
      if Value.Write(Header,SizeOf(TSectionHeader)) = SizeOf(TSectionHeader) then
        begin
          i:= 0;
          while (i < Header.Count-1) and // 'Size' Items 
                (Value.Write(_Items[i],SizeOf(_Items[i])) = SizeOf(_Items[i])) do
            inc(i);
          if Value.Write(_SP,SizeOf(_SP)) = SizeOf(_SP) then
            inc(i);            
          result:= i = Header.Count;
        end
      else
        result:= false;
    end
  else
    result:= false;
end;

procedure Ti8008Stack.AddStackListener(Listener: IStack);
begin
  if Assigned(Listener) then
    begin
      _StackListenerList.Add(Listener);
      Listener.RefreshObject(Self);
    end;
end;

procedure Ti8008Stack.DelStackListeners;
begin
  _StackListenerList.Clear;
end;

procedure Ti8008Stack.AddProgramCounterListener(Listener: IProgramCounter);
begin
  if Assigned(Listener) then
    begin
      _PCListenerList.Add(Listener);
      Listener.RefreshObject(Self);
    end;
end;

procedure Ti8008Stack.DelProgramCounterListeners;
begin
  _PCListenerList.Clear;
end;

procedure Ti8008Stack.IncProgramCounter;
begin
  ProgramCounter:= ProgramCounter+1;
end;

procedure Ti8008Stack.ResetStackPointer;
begin
  StackPointer:= 0;
end;

procedure Ti8008Stack.ResetProgramCounter;
begin
  ProgramCounter:= 0;
end;

procedure Ti8008Stack.Reset;
var
  i: Integer;
begin
  for i:= 0 to Size-1 do
    _Items[i]:= 0;
  _SP:= 0;
  ISPChanged;
  IPCUpdate;
  _Count:= 0;
  IReset;
end;

procedure Ti8008Stack.RefreshObject;
begin
  IRefresh;
end;

class function Ti8008Stack.Size: Byte;
begin
  result:= 8; 
end;
{ ********* Ti8008Stack ********* }
{ ********** Ti8008RAM ********** }
procedure Ti8008RAM.IRefresh;
var
  i: Integer;
  Listener: IRAM;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IRAM(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.RefreshObject(Self);
    end;
end;

procedure Ti8008RAM.IRAMUpdate(Address: Word; Value: Byte);
var
  i: Integer;
  Listener: IRAM;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IRAM(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.RAMUpdate(Self,Address,Value);
    end;
  if Assigned(OnRAMUpdate) then
    OnRAMUpdate(Self,Address,Value);
end;

procedure Ti8008RAM.IReset;
var
  i: Integer;
  Listener: IRAM;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IRAM(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.Reset(Self);
    end;
  if Assigned(OnRAMReset) then
    OnRAMReset(Self);    
end;

function Ti8008RAM.getRAM(Address: Word): Byte;
begin
  if Address < _Size then
    result:= _RAM[Address]
  else
    result:= 0;
end;

procedure Ti8008RAM.setRAM(Address: Word; Value: Byte);
begin
  if Address < _Size then
    begin
      _RAM[Address]:= Value;
      IRAMUpdate(Address,Value);
    end;
end;

constructor Ti8008RAM.Create;
begin
  inherited Create;
  _Size:= 16384;
  SetLength(_RAM,_Size);
  _ListenerList:= TInterfaceList.Create;
  _OnRAMUpdate:= nil;
  _OnRAMReset:= nil;
  Reset;
end;

destructor Ti8008RAM.Destroy;
begin
  SetLength(_RAM,0);
  _ListenerList.Free;
  inherited Destroy;
end;

function Ti8008RAM.LoadFromStream(Value: TStream): Boolean;
var
  Header: TSectionHeader;
  i: Word;
begin
  if Assigned(Value) then
    begin
      if (Value.Read(Header,SizeOf(TSectionHeader)) = SizeOf(TSectionHeader)) and
         (Header.Version = _FileVersion) and (Header.Kind = sRAM) and
         (Header.Count = High(_RAM)+1) then
        begin
          i:= 0;
          while (i < Header.Count) and
                (Value.Read(_RAM[i],SizeOf(_RAM[i])) = SizeOf(_RAM[i])) do
            inc(i);
          result:= i = Header.Count;
          RefreshObject;
        end
      else
        result:= false;
    end
  else
    result:= false;
end;

function Ti8008RAM.SaveToStream(Value: TStream): Boolean;
var
  Header: TSectionHeader;
  i: Word;
begin
  if Assigned(Value) then
    begin
      Header.Version:= _FileVersion;
      Header.Count:= Size;
      Header.Kind:= sRAM;
      if Value.Write(Header,SizeOf(TSectionHeader)) = SizeOf(TSectionHeader) then
        begin
          i:= 0;
          while (i < Header.Count) and
                (Value.Write(_RAM[i],SizeOf(_RAM[i])) = SizeOf(_RAM[i])) do
            inc(i);
          result:= i = Header.Count;
        end
      else
        result:= false;
    end
  else
    result:= false;
end;

procedure Ti8008RAM.Reset;
var
  i: Integer;
begin
  for i:= 0 to _Size-1 do
    _RAM[i]:= 0;
  IReset;
end;

procedure Ti8008RAM.RefreshObject;
begin
  IRefresh;
end;

procedure Ti8008RAM.AddListener(Listener: IRAM);
begin
  if Assigned(Listener) then
    begin
      _ListenerList.Add(Listener);
      Listener.RefreshObject(Self);
    end;
end;

procedure Ti8008RAM.DelListeners;
begin
  _ListenerList.Clear;
end;

procedure Ti8008RAM.Load(AProgram: TProgram);
var
  i: Integer;
begin
  if Assigned(AProgram) then
    for i:= 0 to AProgram.Count-1 do
      RAM[AProgram.Items[i].Address]:= AProgram.Items[i].Value;
end;
{ ********** Ti8008RAM ********** }
{ ******** Ti8008Register ******* }
function Ti8008Register.getHL: Word;
begin
  result:= Value[5] shl 8 +// H
           Value[6];       // L
  result:= result mod _RAM.Size;         
end;

function Ti8008Register.getName(Index: Byte): String;
begin
  case Index of
    0: result:= 'A';
    1: result:= 'B';
    2: result:= 'C';
    3: result:= 'D';
    4: result:= 'E';
    5: result:= 'H';
    6: result:= 'L';
    else if Index < Count then
           result:= 'M(HL)'
         else  
           result:= '';
  end;
end;

function Ti8008Register.getValue(Index: Byte): Byte;
begin
  if Index < Count then
    if (Index = Count-1) and Assigned(_RAM) then
      result:= _RAM.RAM[getHL] // M(HL) -> RAM
    else
      result:= _Values[Index]
  else
    result:= 0;
end;

procedure Ti8008Register.setValue(Index: Byte; Value: Byte);
begin
  if Index < Count then
    begin
      if (Index = Count-1) and Assigned(_RAM) then
        _RAM.RAM[getHL]:= Value  // M(HL) -> RAM
      else
        _Values[Index]:= Value;
      IRegisterUpdate(Index,Value);
      if (Index in [5,6]) and (Count = 8) and Assigned(_RAM) then
        IRegisterUpdate(7,_RAM.RAM[getHL]);
    end;
end;

procedure Ti8008Register.IRegisterUpdate(Index: Byte; Value: Byte);
var
  i: Integer;
  Listener: IRegister;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IRegister(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.RegisterUpdate(Self,Index,Value);
    end;
end;

procedure Ti8008Register.IRegisterReset(Index: Byte);
var
  i: Integer;
  Listener: IRegister;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IRegister(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.RegisterReset(Self,Index);
    end;
end;

procedure Ti8008Register.IReset;
var
  i: Integer;
  Listener: IRegister;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IRegister(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.Reset(Self);
    end;
end;

procedure Ti8008Register.IRefresh;
var
  i: Integer;
  Listener: IRegister;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IRegister(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.RefreshObject(Self);
    end;
end;

procedure Ti8008Register.OnRAMUpdate(Sender: TObject; Address: Word; Value: Byte);
begin
  if getHL = Address then
    IRegisterUpdate(7,Value);
end;

procedure Ti8008Register.OnRAMReset(Sender: TObject);
begin
  IRegisterReset(7);
end;

constructor Ti8008Register.Create(RAM: Ti8008RAM);
begin
  inherited Create;
  _ListenerList:= TInterfaceList.Create;
  _RAM:= RAM;
  _RAM.OnRAMUpdate:= OnRAMUpdate;
  _RAM.OnRAMReset:= OnRAMReset;
  Reset;
end;

constructor Ti8008Register.Create;
begin
  inherited Create;
  _ListenerList:= TInterfaceList.Create;
  _RAM:= nil;
  Reset;
end;

destructor Ti8008Register.Destroy;
begin
  _ListenerList.Free;
  inherited Destroy;
end;

function Ti8008Register.LoadFromStream(Value: TStream): Boolean;
var
  Header: TSectionHeader;
  i: Word;
begin
  if Assigned(Value) then
    begin
      if (Value.Read(Header,SizeOf(TSectionHeader)) = SizeOf(TSectionHeader)) and
         (Header.Version = _FileVersion) and (Header.Kind = sRegister) and
         (Header.Count = High(_Values)+1) then
        begin
          i:= 0;
          while (i < Header.Count) and
                (Value.Read(_Values[i],SizeOf(_Values[i])) = SizeOf(_Values[i])) do
            inc(i);
          result:= i = Header.Count;
          RefreshObject;
        end
      else
        result:= false;
    end
  else
    result:= false;
end;

function Ti8008Register.SaveToStream(Value: TStream): Boolean;
var
  Header: TSectionHeader;
  i: Word;
begin
  if Assigned(Value) then
    begin
      Header.Version:= _FileVersion;
      Header.Count:= High(_Values)+1;
      Header.Kind:= sRegister;
      if (Value.Write(Header,SizeOf(TSectionHeader)) = SizeOf(TSectionHeader)) then
        begin
          i:= 0;
          while (i < Header.Count) and
                (Value.Write(_Values[i],SizeOf(_Values[i])) = SizeOf(_Values[i])) do
            inc(i);
          result:= i = Header.Count;
        end
      else
        result:= false;
    end
  else
    result:= false;
end;

procedure Ti8008Register.Reset;
var
  i: Byte;
begin
  for i:= 0 to Count-1 do
    _Values[i]:= 0;
  IReset;
end;

procedure Ti8008Register.RefreshObject;
begin
  IRefresh;
end;

procedure Ti8008Register.AddListener(Listener: IRegister);
begin
  if Assigned(Listener) then
    begin
      _ListenerList.Add(Listener);
      Listener.RefreshObject(Self);
    end;
end;

procedure Ti8008Register.DelListeners;
begin
  _ListenerList.Clear;
end;

function Ti8008Register.Count: Byte;
begin
  if Assigned(_RAM) then
    result:= High(_Values)+2  // 0..7
  else
    result:= High(_Values)+1; // 0..6
end;
{ ******** Ti8008Register ******* }
{ ********* Ti8008Flags ********* }
procedure Ti8008Flags.setCarry(Value: Boolean);
begin
  _Carry:= Value;
  ICarryFlagUpdate;
end;

procedure Ti8008Flags.setSign(Value: Boolean);
begin
  _Sign:= Value;
  ISignFlagUpdate;
end;

procedure Ti8008Flags.setZero(Value: Boolean);
begin
  _Zero:= Value;
  IZeroFlagUpdate;
end;

procedure Ti8008Flags.setParity(Value: Boolean);
begin
  _Parity:= Value;
  IParityFlagUpdate;
end;

procedure Ti8008Flags.ICarryFlagUpdate;
var
  i: Integer;
  Listener: IFlags;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IFlags(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.CarryFlagUpdate(Self,Carry);
    end;
end;

procedure Ti8008Flags.ISignFlagUpdate;
var
  i: Integer;
  Listener: IFlags;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IFlags(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.SignFlagUpdate(Self,Sign);
    end;
end;

procedure Ti8008Flags.IZeroFlagUpdate;
var
  i: Integer;
  Listener: IFlags;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IFlags(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.ZeroFlagUpdate(Self,Zero);
    end;
end;

procedure Ti8008Flags.IParityFlagUpdate;
var
  i: Integer;
  Listener: IFlags;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IFlags(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.ParityFlagUpdate(Self,Parity);
    end;
end;

procedure Ti8008Flags.IReset;
var
  i: Integer;
  Listener: IFlags;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IFlags(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.Reset(Self);
    end;
end;

procedure Ti8008Flags.IRefresh;
var
  i: Integer;
  Listener: IFlags;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IFlags(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.RefreshObject(Self);
    end;
end;

constructor Ti8008Flags.Create;
begin
  inherited Create;
  _ListenerList:= TInterfaceList.Create;
  Reset;
end;

destructor Ti8008Flags.Destroy;
begin
  _ListenerList.Free;
  inherited Destroy;
end;

function Ti8008Flags.LoadFromStream(Value: TStream): Boolean;
var
  Header: TSectionHeader;
begin
  if Assigned(Value) then
    begin
      if (Value.Read(Header,SizeOf(TSectionHeader)) = SizeOf(TSectionHeader)) and
         (Header.Version = _FileVersion) and (Header.Kind = sFlags) and
         (Header.Count = 4) then
        begin
          result:= (Value.Read(_Carry,SizeOf(_Carry)) = SizeOf(_Carry)) and
                   (Value.Read(_Sign,SizeOf(_Sign)) = SizeOf(_Sign)) and
                   (Value.Read(_Zero,SizeOf(_Zero)) = SizeOf(_Zero)) and
                   (Value.Read(_Parity,SizeOf(_Parity)) = SizeOf(_Parity));
          RefreshObject;
        end
      else
        result:= false;
    end
  else
    result:= false;
end;

function Ti8008Flags.SaveToStream(Value: TStream): Boolean;
var
  Header: TSectionHeader;
begin
  if Assigned(Value) then
    begin
      Header.Version:= _FileVersion;
      Header.Count:= 4;
      Header.Kind:= sFlags;
      result:= (Value.Write(Header,SizeOf(TSectionHeader)) = SizeOf(TSectionHeader)) and
               (Value.Write(_Carry,SizeOf(_Carry)) = SizeOf(_Carry)) and
               (Value.Write(_Sign,SizeOf(_Sign)) = SizeOf(_Sign)) and
               (Value.Write(_Zero,SizeOf(_Zero)) = SizeOf(_Zero)) and
               (Value.Write(_Parity,SizeOf(_Parity)) = SizeOf(_Parity));
    end
  else
    result:= false;
end;

procedure Ti8008Flags.Reset;
begin
  _Carry:= false;
  _Sign:= false;
  _Zero:= false;
  _Parity:= false;
  IReset;
end;  

procedure Ti8008Flags.RefreshObject;
begin
  IRefresh;
end;
  
procedure Ti8008Flags.AddListener(Listener: IFlags);
begin
  if Assigned(Listener) then
    begin
      _ListenerList.Add(Listener);
      Listener.RefreshObject(Self);
    end;
end;

procedure Ti8008Flags.DelListeners;
begin
  _ListenerList.Clear;
end;
{ ********* Ti8008Flags ********* }
{ ********** TIOPorts *********** }
procedure TIOPorts.IPortUpdate(Index, Value: Byte);
var
  i: Integer;
  Listener: IIOPorts;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IIOPorts(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.PortUpdate(Self,Index,Value);
    end;
end;

procedure TIOPorts.IPortAction;
var
  i: Integer;
  Listener: IIOPorts;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IIOPorts(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.PortAction(Self,PortFileActive);
    end;
end;

procedure TIOPorts.IReset;
var
  i: Integer;
  Listener: IIOPorts;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IIOPorts(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.Reset(Self);
    end;
end;

procedure TIOPorts.IRefresh;
var
  i: Integer;
  Listener: IIOPorts;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IIOPorts(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.RefreshObject(Self);
    end;
end;

function TIOPorts.getValue(Index: Byte): Byte;
begin
  if (Index >= FirstPortNo) and (Index < (FirstPortNo+Count)) then
    result:= _Ports[Index-FirstPortNo]
  else
    result:= 0;
end;

procedure TIOPorts.setValue(Index: Byte; Value: Byte);
begin
  if (Index >= FirstPortNo) and (Index < (FirstPortNo+Count)) then
    begin
      _Ports[Index-FirstPortNo]:= Value;
      IPortUpdate(Index,Value);
    end;
end;

procedure TIOPorts.setPortFile(Value: TFilename);
begin
  if Value = '' then
    begin
      if Assigned(_PortStream) then
        _PortStream.Free;
      _PortStream:= nil;
      _PortFile:= Value;
      PortFileActive:= false;
    end
  else
    begin
      _PortFile:= Value;
      if Assigned(_PortStream) then
        _PortStream.Free;
      _PortStream:= nil;
      try
        case PortType of
          ptIN  : _PortStream:= TFileStream.Create(PortFile,fmOpenRead,fmShareDenyWrite);
          ptOUT : _PortStream:= TFileStream.Create(PortFile,fmCreate,fmShareExclusive);
        end;  
      except
        _PortFile:= '';
        _PortStream:= nil;
      end;
      PortFileActive:= Assigned(_PortStream);
      // Load Data
      if PortFileActive and (PortType = ptIN) then
        OnPortRead(Self);
    end;
end;

function TIOPorts.getPortFileActive: Boolean;
begin
  result:= _PortFileActive and Assigned(_PortStream);
end;

procedure TIOPorts.setPortFileActive(Value: Boolean);
begin
  _PortFileActive:= Value;
  IPortAction;
end;

procedure TIOPorts.OnPortRead(Sender: TObject);
var
  i: Integer;
begin
  if PortFileActive then
    begin
      i:= 0;
      while (i < Count) and (_PortStream.Read(_Ports[i],SizeOf(_Ports[i])) = SizeOf(_Ports[i])) do
        begin
          // Update all Listeners
          IPortUpdate(i+FirstPortNo,_Ports[i]);
          inc(i);
        end;
      // Rewind
      if _PortStream.Position = _PortStream.Size then
        _PortStream.Position:= 0
      else
        if i <> Count then
          PortFileActive:= false;
    end;
end;

procedure TIOPorts.OnPortWrite(Sender: TObject);
var
  i: Integer;
begin
  if PortFileActive then
    begin
      i:= 0;
      while (i < Count) and (_PortStream.Write(_Ports[i],SizeOf(_Ports[i])) = SizeOf(_Ports[i])) do
        inc(i);
      if i <> Count then
        PortFileActive:= false;
    end
end;

constructor TIOPorts.Create;
begin
  inherited Create;
  setLength(_Ports,Count);
  _ListenerList:= TInterfaceList.Create;
  PortFile:= '';
  PortFileActive:= false;
  Reset;
end;

destructor TIOPorts.Destroy;
begin
  PortFile:= '';
  setLength(_Ports,0);
  _ListenerList.Free;
  inherited Destroy;
end;

function TIOPorts.LoadFromStream(Value: TStream): Boolean;
var
  Header: TSectionHeader;
  i: Word;
begin
  if Assigned(Value) then
    begin
      if (Value.Read(Header,SizeOf(TSectionHeader)) = SizeOf(TSectionHeader)) and
         (Header.Version = _FileVersion) and (Header.Kind = sIOPorts) and
         (Header.Count = Count) then
        begin
          i:= 0;
          while (i < Header.Count) and
                (Value.Read(_Ports[i],SizeOf(_Ports[i])) = SizeOf(_Ports[i])) do
            inc(i);
          result:= i = Header.Count;
          RefreshObject;
        end
      else
        result:= false;
    end
  else
    result:= false;
end;

function TIOPorts.SaveToStream(Value: TStream): Boolean;
var
  Header: TSectionHeader;
  i: Word;
begin
  if Assigned(Value) then
    begin
      Header.Version:= _FileVersion;
      Header.Count:= Count;
      Header.Kind:= sIOPorts;
      if Value.Write(Header,SizeOf(TSectionHeader)) = SizeOf(TSectionHeader) then
        begin
          i:= 0;
          while (i < Header.Count) and
                (Value.Write(_Ports[i],SizeOf(_Ports[i])) = SizeOf(_Ports[i])) do
            inc(i);
          result:= i = Header.Count;
        end
      else
        result:= false;
    end
  else
    result:= false;
end;

procedure TIOPorts.Reset;
var
  i: Integer;
begin
  for i:= 0 to Count-1 do
    _Ports[i]:= 0;
  IReset;
end;

procedure TIOPorts.ResetPortFile;
begin
  if Assigned(_PortStream) then
    begin
      _PortStream.Position:= 0;
      // Load Data
      if PortFileActive and (PortType = ptIN) then
        OnPortRead(Self);
    end;
end;

procedure TIOPorts.RefreshObject;
begin
  IRefresh;
end;

procedure TIOPorts.AddListener(Listener: IIOPorts);
begin
  if Assigned(Listener) then
    begin
      _ListenerList.Add(Listener);
      Listener.RefreshObject(Self);
    end;
end;

procedure TIOPorts.DelListeners;
begin
  _ListenerList.Clear;
end;
{ ********** TIOPorts *********** }
{ ******** Ti8008IPorts ********* }
class function Ti8008IPorts.FirstPortNo: Byte;
begin
  result:= 0;
end;

class function Ti8008IPorts.Count: Byte;
begin
  result:= 8;
end;

class function Ti8008IPorts.PortType: TPortType;
begin
  result:= ptIN;
end;
{ ******** Ti8008IPorts ********* }
{ ******** Ti8008OPorts ********* }
class function Ti8008OPorts.FirstPortNo: Byte;
begin
  result:= 8;
end;

class function Ti8008OPorts.Count: Byte;
begin
  result:= 24;
end;

class function Ti8008OPorts.PortType: TPortType;
begin
  result:= ptOUT;
end;
{ ******** Ti8008OPorts ********* }
{ ******* Ti8008Processor ******* }
procedure Ti8008Processor.setHalt(Value: Boolean);
begin
  _Halt:= Value;
  IStateChange;
end;

procedure Ti8008Processor.setFlags(Value: Byte);
var
  i: Byte;
  _Parity: Byte;
begin
  _Flags.Sign:= (Value and Bits[7]) = Bits[7];
  _Flags.Zero:= Value = 0;
  _Parity:= 0;
  for i:= 0 to High(Bits) do
    if (Bits[i] and Value) = Bits[i] then
      inc(_Parity);
  _Flags.Parity:= (_Parity mod 2) = 0;
end;

function Ti8008Processor.getStack(Address: Byte): Word;
begin
  result:= _Stack.Items[Address];
end;

function Ti8008Processor.getStackPointer: Byte;
begin
  result:= _Stack.StackPointer;
end;

function Ti8008Processor.getStackSize: Byte;
begin
  result:= _Stack.Size;
end;

function Ti8008Processor.getRAM(Address: Word): Byte;
begin
  result:= _RAM.RAM[Address];
end;

function Ti8008Processor.getRAMSize: Word;
begin
  result:= _RAM.Size;
end;

function Ti8008Processor.getRegister(Index: Byte): Byte;
begin
  result:= _Register.Value[Index];
end;

function Ti8008Processor.getRegisterName(Index: Byte): String;
begin
  result:= _Register.Name[Index];
end;

function Ti8008Processor.getRegisterCount: Byte;
begin
  result:= _Register.Count;
end;

procedure Ti8008Processor.setCarry(Value: Boolean);
begin
  _Flags.Carry:= Value;
end;

function Ti8008Processor.getCarry: Boolean;
begin
  result:= _Flags.Carry
end;

procedure Ti8008Processor.setSign(Value: Boolean);
begin
  _Flags.Sign:= Value;
end;

function Ti8008Processor.getSign: Boolean;
begin
  result:= _Flags.Sign;
end;

procedure Ti8008Processor.setZero(Value: Boolean);
begin
  _Flags.Zero:= Value;
end;

function Ti8008Processor.getZero: Boolean;
begin
  result:= _Flags.Zero;
end;

procedure Ti8008Processor.setParity(Value: Boolean);
begin
  _Flags.Parity:= Value;
end;

function Ti8008Processor.getParity: Boolean;
begin
  result:= _Flags.Parity;
end;

function Ti8008Processor.getProgramCounter: Word;
begin
  result:= _Stack.ProgramCounter;
end;

function Ti8008Processor.getIPorts(Index: Byte): Byte;
begin
  result:= _IPorts.Value[Index]
end;

function Ti8008Processor.getFirstIPortNo: Byte;
begin
  result:= _IPorts.FirstPortNo;
end;

function Ti8008Processor.getIPortCount: Byte;
begin
  result:= _IPorts.Count;
end;

procedure Ti8008Processor.setOPorts(Index: Byte; Value: Byte);
begin
  _OPorts.Value[Index]:= Value;
end;

function Ti8008Processor.getOPorts(Index: Byte): Byte;
begin
  result:= _OPorts.Value[Index]
end;

function Ti8008Processor.getFirstOPortNo: Byte;
begin
  result:= _OPorts.FirstPortNo;
end;

function Ti8008Processor.getOPortCount: Byte;
begin
  result:= _OPorts.Count;
end;

procedure Ti8008Processor.IBeforeCycle;
var
  i: Integer;
  Listener: IProcessor;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IProcessor(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.BeforeCycle(Self);
    end;
end;

procedure Ti8008Processor.IAfterCycle;
var
  i: Integer;
  Listener: IProcessor;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IProcessor(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.AfterCycle(Self);
    end;
  if Assigned(OnPortRead) and (PortDataChange = pdcAfterCycle) then
    OnPortRead(Self);
  if Assigned(OnPortWrite) and (PortDataChange = pdcAfterCycle) then
    OnPortWrite(Self);
end;

procedure Ti8008Processor.IStateChange;
var
  i: Integer;
  Listener: IProcessor;
begin
  for i:= 0 to _ListenerList.Count-1 do
    begin
      Listener:= IProcessor(_ListenerList.Items[i]);
      if Assigned(Listener) then
        Listener.StateChange(Self,Halt);
    end;
end;

procedure Ti8008Processor._INR(RegisterNo: Byte);
begin
  Register[RegisterNo]:= Register[RegisterNo] + 1;
  setFlags(Register[RegisterNo]);
end;

procedure Ti8008Processor._ADI(Value: Byte);
begin
  Register[0]:= Register[0] + Value;
  _Flags.Carry:= Register[0] < Value;
  setFlags(Register[0]);
end;

procedure Ti8008Processor._ANI(Value: Byte);
begin
  Register[0]:= Register[0] and Value;
  _Flags.Carry:= false;
  setFlags(Register[0]);
end;

procedure Ti8008Processor._ORI(Value: Byte);
begin
  Register[0]:= Register[0] or Value;
  _Flags.Carry:= false;
  setFlags(Register[0]);
end;

procedure Ti8008Processor._SUI(Value: Byte);
begin
  _Flags.Carry:= Register[0] < Value;
  Register[0]:= Register[0] - Value;
  setFlags(Register[0]);
end;

procedure Ti8008Processor._SBI(Value: Byte);
begin
  if _Flags.Carry then
    begin
      _Flags.Carry:= Register[0] < Value + 1;
      Register[0]:= Register[0] - Value - 1;
    end
  else
    begin
      _Flags.Carry:= Register[0] < Value;
      Register[0]:= Register[0] - Value;
    end;
  setFlags(Register[0]);
end;

procedure Ti8008Processor._CPI(Value: Byte);
var
  Accumulator: Byte;
begin
  _Flags.Carry:= Register[0] < Value;
  Accumulator:= Register[0] - Value;
  setFlags(Accumulator);
end;

procedure Ti8008Processor._XRI(Value: Byte);
begin
  Register[0]:= Register[0] xor Value;
  _Flags.Carry:= false;
  setFlags(Register[0]);
end;

procedure Ti8008Processor._ACI(Value: Byte);
begin
  if _Flags.Carry then
    begin
      Register[0]:= Register[0] + Value + 1;
      _Flags.Carry:= Register[0] < Value + 1;
    end
  else
    begin
      Register[0]:= Register[0] + Value;
      _Flags.Carry:= Register[0] < Value;
    end;
  setFlags(Register[0]);
end;

procedure Ti8008Processor._MVI(RegisterNo: Byte; Value: Byte);
begin
  _Register.Value[RegisterNo]:= Value;
end;

procedure Ti8008Processor._RLC;
var
  Bit: Boolean;
begin
  Bit:= (_Register.Value[0] and Bits[7]) = Bits[7];
  _Register.Value[0]:= _Register.Value[0] shl 1;
  if Bit then
    _Register.Value[0]:= _Register.Value[0] or 1;
  _Flags.Carry:= Bit;
end;

procedure Ti8008Processor._RAL;
var
  Bit: Boolean;
begin
  Bit:= (_Register.Value[0] and Bits[7]) = Bits[7];
  _Register.Value[0]:= _Register.Value[0] shl 1;
  if _Flags.Carry then
    _Register.Value[0]:= _Register.Value[0] or 1;
  _Flags.Carry:= Bit;
end;

procedure Ti8008Processor._RAR;
var
  Bit: Boolean;
begin
  Bit:= (_Register.Value[0] and Bits[0]) = Bits[0];
  _Register.Value[0]:= _Register.Value[0] shr 1;
  if _Flags.Carry then
    _Register.Value[0]:= _Register.Value[0] or Bits[7];
  _Flags.Carry:= Bit;
end;

procedure Ti8008Processor._RRC;
var
  Bit: Boolean;
begin
  Bit:= (_Register.Value[0] and Bits[0]) = Bits[0];
  _Register.Value[0]:= _Register.Value[0] shr 1;
  if Bit then
    _Register.Value[0]:= _Register.Value[0] or 128;
  _Flags.Carry:= Bit;
end;

procedure Ti8008Processor._RNC;
begin
  if not _Flags.Carry then
    _Stack.Pop;
end;

procedure Ti8008Processor._RC;
begin
  if _Flags.Carry then
    _Stack.Pop;
end;

procedure Ti8008Processor._RM;
begin
  if _Flags.Sign then
    _Stack.Pop;
end;

procedure Ti8008Processor._RP;
begin
  if not _Flags.Sign then
    _Stack.Pop;
end;

procedure Ti8008Processor._RPO;
begin
  if not _Flags.Parity then
    _Stack.Pop;
end;

procedure Ti8008Processor._RPE;
begin
  if _Flags.Parity then
    _Stack.Pop;
end;

procedure Ti8008Processor._RZ;
begin
  if _Flags.Zero then
    _Stack.Pop;
end;

procedure Ti8008Processor._RNZ;
begin
  if not _Flags.Zero then
    _Stack.Pop;
end;

procedure Ti8008Processor._RET;
begin
  _Stack.Pop;
end;

procedure Ti8008Processor._RST(Address: Byte);
begin
  _Stack.Push(Address);
end;

procedure Ti8008Processor._DCR(RegisterNo: Byte);
begin
  Register[RegisterNo]:= Register[RegisterNo] - 1;
  setFlags(Register[RegisterNo]);
end;

procedure Ti8008Processor._IN(PortNo: Byte);
begin
  _Register.Value[0]:= _IPorts.Value[PortNo];
  if Assigned(OnPortRead) and (PortDataChange = pdcAfterInstruction) then
    OnPortRead(Self);
end;

procedure Ti8008Processor._OUT(PortNo: Byte);
begin
  _OPorts.Value[PortNo]:= _Register.Value[0];
  if Assigned(OnPortWrite) and (PortDataChange = pdcAfterInstruction) then
    OnPortWrite(Self);
end;

procedure Ti8008Processor._CNC(Address: Word);
begin
  if not _Flags.Carry then
    _Stack.Push(Address);
end;

procedure Ti8008Processor._CC(Address: Word);
begin
  if _Flags.Carry then
    _Stack.Push(Address);
end;

procedure Ti8008Processor._CM(Address: Word);
begin
  if _Flags.Sign then
    _Stack.Push(Address);
end;

procedure Ti8008Processor._CP(Address: Word);
begin
  if not _Flags.Sign then
    _Stack.Push(Address);
end;

procedure Ti8008Processor._CPO(Address: Word);
begin
  if not _Flags.Parity then
    _Stack.Push(Address);
end;

procedure Ti8008Processor._CPE(Address: Word);
begin
  if _Flags.Parity then
    _Stack.Push(Address);
end;

procedure Ti8008Processor._CZ(Address: Word);
begin
  if _Flags.Zero then
    _Stack.Push(Address);
end;

procedure Ti8008Processor._CNZ(Address: Word);
begin
  if not _Flags.Zero then
    _Stack.Push(Address);
end;

procedure Ti8008Processor._CALL(Address: Word);
begin
  _Stack.Push(Address);
end;

procedure Ti8008Processor._JMP(Address: Word);
begin
  _Stack.ProgramCounter:= Address;
end;

procedure Ti8008Processor._JNC(Address: Word);
begin
  if not _Flags.Carry then
    _Stack.ProgramCounter:= Address;
end;

procedure Ti8008Processor._JC(Address: Word);
begin
  if _Flags.Carry then
    _Stack.ProgramCounter:= Address;
end;

procedure Ti8008Processor._JM(Address: Word);
begin
  if _Flags.Sign then
    _Stack.ProgramCounter:= Address;
end;

procedure Ti8008Processor._JP(Address: Word);
begin
  if not _Flags.Sign then
    _Stack.ProgramCounter:= Address;
end;

procedure Ti8008Processor._JPO(Address: Word);
begin
  if not _Flags.Parity then
    _Stack.ProgramCounter:= Address;
end;

procedure Ti8008Processor._JPE(Address: Word);
begin
  if _Flags.Parity then
    _Stack.ProgramCounter:= Address;
end;

procedure Ti8008Processor._JZ(Address: Word);
begin
  if _Flags.Zero then
    _Stack.ProgramCounter:= Address;
end;

procedure Ti8008Processor._JNZ(Address: Word);
begin
  if not _Flags.Zero then
    _Stack.ProgramCounter:= Address;
end;

procedure Ti8008Processor._ADC(RegisterNo: Byte);
begin
  if _Flags.Carry then
    begin
      _Flags.Carry:= Integer(Register[0]) + Integer(Register[RegisterNo]) + 1 > 255;
      Register[0]:= Register[0] + Register[RegisterNo] + 1;
    end
  else
    begin
      _Flags.Carry:= Integer(Register[0]) + Integer(Register[RegisterNo]) > 255;
      Register[0]:= Register[0] + Register[RegisterNo];
    end;
  setFlags(Register[0]);
end;

procedure Ti8008Processor._XRA(RegisterNo: Byte);
begin
  Register[0]:= Register[0] xor Register[RegisterNo];
  _Flags.Carry:= false;
  setFlags(Register[0]);
end;

procedure Ti8008Processor._CMP(RegisterNo: Byte);
var
  Accumulator: Byte;
begin
  _Flags.Carry:= Register[0] < Register[RegisterNo];
  Accumulator:= Register[0] - Register[RegisterNo];
  setFlags(Accumulator);
end;

procedure Ti8008Processor._SBB(RegisterNo: Byte);
begin
  if _Flags.Carry then
    begin
      _Flags.Carry:= Register[0] < Register[RegisterNo] + 1;
      Register[0]:= Register[0] - Register[RegisterNo] - 1;
    end
  else
    begin
      _Flags.Carry:= Register[0] < Register[RegisterNo];
      Register[0]:= Register[0] - Register[RegisterNo];
    end;
  setFlags(Register[0]);
end;

procedure Ti8008Processor._SUB(RegisterNo: Byte);
begin
  _Flags.Carry:= Register[0] < Register[RegisterNo];
  Register[0]:= Register[0] - Register[RegisterNo];
  setFlags(Register[0]);
end;

procedure Ti8008Processor._ORA(RegisterNo: Byte);
begin
  Register[0]:= Register[0] or Register[RegisterNo];
  _Flags.Carry:= false;
  setFlags(Register[0]);
end;

procedure Ti8008Processor._ANA(RegisterNo: Byte);
begin
  Register[0]:= Register[0] and Register[RegisterNo];
  _Flags.Carry:= false;
  setFlags(Register[0]);
end;

procedure Ti8008Processor._ADD(RegisterNo: Byte);
begin
  _Flags.Carry:= Integer(Register[0]) + Integer(Register[RegisterNo]) > 255;
  Register[0]:= Register[0] + Register[RegisterNo];
  setFlags(Register[0]);
end;

procedure Ti8008Processor._MOV(RegisterNo1: Byte; RegisterNo2: Byte);
begin
  _Register.Value[RegisterNo1]:= _Register.Value[RegisterNo2];
end;

constructor Ti8008Processor.Create;
begin
  _ListenerList:= TInterfaceList.Create;
  _Stack:= Ti8008Stack.Create;
  _RAM:= Ti8008RAM.Create;
  _Register:= Ti8008Register.Create(_RAM);
  _Flags:= Ti8008Flags.Create;
  _IPorts:= Ti8008IPorts.Create;
  OnPortRead:= _IPorts.OnPortRead;
  _OPorts:= Ti8008OPorts.Create;
  OnPortWrite:= _OPorts.OnPortWrite;
  _PortDataChange:= pdcAfterInstruction;
  Halt:= false;
end;

destructor Ti8008Processor.Destroy;
begin
  _OPorts.Free;
  _IPorts.Free;
  _Flags.Free;
  _Register.Free;
  _RAM.Free;
  _Stack.Free;
  _ListenerList.Free;
  inherited Destroy;
end;

function Ti8008Processor.LoadFromStream(Stream: TStream): Boolean;
var
  Header: TSectionHeader;
  tmpHalt: Boolean;
begin
  if (Stream.Read(Header,SizeOf(TSectionHeader)) = SizeOf(TSectionHeader)) and
     (Header.Version = _FileVersion) and (Header.Kind = sStart) and
     (Header.Count = 7) then
    begin
      result:= (Stream.Read(tmpHalt,SizeOf(tmpHalt)) = SizeOf(tmpHalt)) and
               _Stack.LoadFromStream(Stream) and
               _RAM.LoadFromStream(Stream) and
               _Register.LoadFromStream(Stream) and
               _Flags.LoadFromStream(Stream) and
               _IPorts.LoadFromStream(Stream) and
               _OPorts.LoadFromStream(Stream);
       Halt:= tmpHalt;        
    end
  else
    result:= false;
end;

function Ti8008Processor.LoadFromFile(Filename: TFilename): Boolean;
var
  FStream: TFileStream;
begin
  if FileExists(Filename) then
    try
      FStream:= TFileStream.Create(Filename,fmOpenRead,fmShareDenyWrite);
      result:= LoadFromStream(FStream);
      FStream.Free;
    except
      result:= false;
    end
  else
    result:= false;
end;

function Ti8008Processor.SaveToStream(Stream: TStream): Boolean;
var
  Header: TSectionHeader;
begin
  Header.Version:= _FileVersion;
  Header.Count:= 7;
  Header.Kind:= sStart;
  result:= (Stream.Write(Header,SizeOf(TSectionHeader)) = SizeOf(TSectionHeader)) and
           (Stream.Write(Halt,SizeOf(_Halt)) = SizeOf(_Halt)) and
           _Stack.SaveToStream(Stream) and
           _RAM.SaveToStream(Stream) and
           _Register.SaveToStream(Stream) and
           _Flags.SaveToStream(Stream) and
           _IPorts.SaveToStream(Stream) and
           _OPorts.SaveToStream(Stream);
end;

function Ti8008Processor.SaveToFile(Filename: TFilename): Boolean;
var
  FStream: TFileStream;
begin
  try
    FStream:= TFileStream.Create(Filename,fmCreate,fmShareExclusive);
    result:= SaveToStream(FStream);
    FStream.Free;
  except
    result:= false;
  end;
end;

procedure Ti8008Processor.Load(AProgram: TProgram);
var
  RAMItem: TProgramItem;
  i: Integer;
begin
  if Assigned(AProgram) then
    for i:= 0 to AProgram.Count-1 do
      begin
        RAMItem:= AProgram.Items[i];
        if Assigned(RAMItem) then
          RAM[RAMItem.Address]:= RAMItem.Value;
      end;
end;

procedure Ti8008Processor.Tick;
var
  Instruction: Byte;
  bValue: Byte;
  wValue: Word;
begin
  { Update all Listener }
  IBeforeCycle;
  if not Halt then
    begin
      { Fetch Instruction }
      Instruction:= RAM[ProgramCounter];
      { Interprete & Execute }
      Halt:= Instruction in CODE_HLT;                           { HLT }
      if not Halt then
        begin
          _Stack.IncProgramCounter;
          if Instruction < 64 then      { [000,100) }
            begin
              { INR }
              if Instruction in CODE_INR then                   { INR }
                _INR((Instruction div 8) mod 8)
              else
                if Instruction in CODE_DCR then                 { DCR }
                  _DCR(((Instruction - 1) div 8) mod 8)
                else
                  if (Instruction mod 8) = 3 then
                    begin
                      case (Instruction div 8) mod 8 of
                        0: _RNC;                                { RNC }
                        1: _RNZ;                                { RNZ }
                        2: _RP;                                 { RP  }
                        3: _RPO;                                { RPO }
                        4: _RC;                                 { RC  }
                        5: _RZ;                                 { RZ  }
                        6: _RM;                                 { RM  }
                        7: _RPE;                                { RPE }
                      end;
                    end
                  else
                    if (Instruction mod 8) = 2 then
                      begin
                        case (Instruction div 8) mod 8 of
                          0: _RLC;                              { RLC }
                          1: _RRC;                              { RRC }
                          2: _RAL;                              { RAL }
                          3: _RAR;                              { RAR }
                        end;
                      end
                    else
                      if (Instruction mod 8) = 4 then
                        begin
                          bValue:= RAM[ProgramCounter];
                          _Stack.IncProgramCounter;
                          case (Instruction div 8) mod 8 of
                            0: _ADI(bValue);                    { ADI }
                            1: _ACI(bValue);                    { ACI }
                            2: _SUI(bValue);                    { SUI }
                            3: _SBI(bValue);                    { SBI }
                            4: _ANI(bValue);                    { ANI }
                            5: _XRI(bValue);                    { XRI }
                            6: _ORI(bValue);                    { ORI }
                            7: _CPI(bValue);                    { CPI }
                          end;
                        end
                      else
                        if (Instruction mod 8) = 5 then
                          _RST(Instruction-5)                   { RST }
                        else
                          if (Instruction mod 8) = 6 then       { MVI }
                            begin
                              bValue:= RAM[ProgramCounter];
                              _Stack.IncProgramCounter;
                              _MVI((Instruction-6) div 8,bValue);
                            end
                          else
                            if (Instruction mod 8) = 7 then
                              _RET;                             { RET }
            end                         { [000,100) }
          else
            if Instruction < 128 then   { [100,200) }
              begin
                if Instruction in CODE_JMP then
                  begin
                    wValue:= RAM[ProgramCounter];
                    _Stack.IncProgramCounter;
                    wValue:= RAM[ProgramCounter] * 256 + wValue;
                    _Stack.IncProgramCounter;
                    _JMP(wValue);                               { JMP }
                  end
                else
                  if Instruction in CODE_CALL then
                    begin
                      wValue:= RAM[ProgramCounter];
                      _Stack.IncProgramCounter;
                      wValue:= RAM[ProgramCounter] * 256 + wValue;
                      _Stack.IncProgramCounter;
                      _CALL(wValue);                            { CALL }
                    end
                  else
                    begin
                      Instruction:= Instruction and 63;
                      if (Instruction mod 8) in [1,3,5,7] then
                        begin
                          bValue:= (Instruction - 1) div 2;
                          if bValue < 8 then
                            _IN(bValue)                         { IN  }
                          else
                            _OUT(bValue);                       { OUT }
                        end
                      else
                        if (Instruction mod 8) = 0 then
                          begin
                            wValue:= RAM[ProgramCounter];
                            _Stack.IncProgramCounter;
                            wValue:= RAM[ProgramCounter] * 256 + wValue;
                            _Stack.IncProgramCounter;
                            case (Instruction div 8) mod 8 of
                              0: _JNC(wValue);                  { JNC }
                              1: _JNZ(wValue);                  { JNZ }
                              2: _JP(wValue);                   { JP  }
                              3: _JPO(wValue);                  { JPO }
                              4: _JC(wValue);                   { JC  }
                              5: _JZ(wValue);                   { JZ  }
                              6: _JM(wValue);                   { JM  }
                              7: _JPE(wValue);                  { JPE }
                            end;
                          end
                        else
                          if (Instruction mod 8) = 2 then
                            begin
                              wValue:= RAM[ProgramCounter];
                              _Stack.IncProgramCounter;
                              wValue:= RAM[ProgramCounter] * 256 + wValue;
                              _Stack.IncProgramCounter;
                              case (Instruction div 8) mod 8 of
                                0: _CNC(wValue);                { CNC }
                                1: _CNZ(wValue);                { CNZ }
                                2: _CP(wValue);                 { CP  }
                                3: _CPO(wValue);                { CPO }
                                4: _CC(wValue);                 { CC  }
                                5: _CZ(wValue);                 { CZ  }
                                6: _CM(wValue);                 { CM  }
                                7: _CPE(wValue);                { CPE }
                              end;
                            end;
                    end;
              end                       { [100,200) }
            else
              if Instruction < 192 then { [200,300) }
                begin
                  Instruction:= Instruction and 63;
                  case (Instruction div 8) mod 8 of
                    0: _ADD(Instruction mod 8);                 { ADD }
                    1: _ADC(Instruction mod 8);                 { ADC }
                    2: _SUB(Instruction mod 8);                 { SUB }
                    3: _SBB(Instruction mod 8);                 { SBB }
                    4: _ANA(Instruction mod 8);                 { ANA }
                    5: _XRA(Instruction mod 8);                 { XRA }
                    6: _ORA(Instruction mod 8);                 { ORA }
                    7: _CMP(Instruction mod 8);                 { CMP }
                  end;
                end                     { [200,300) }
              else
                begin                   { [300,377] }           { MOV }
                  Instruction:= Instruction and 63;
                  _MOV((Instruction div 8) mod 8,Instruction mod 8);
                end;
          end; { if not Halt then }
    end;
  { Update all Listener }
  IAfterCycle;
end;

procedure Ti8008Processor.setStack(Address: Byte; Value: Word);
begin
  _Stack.Items[Address]:= Value;
end;

procedure Ti8008Processor.setStackPointer(Value: Byte);
begin
  _Stack.StackPointer:= Value;
end;

procedure Ti8008Processor.setRegister(Index: Byte; Value: Byte);
begin
  _Register.Value[Index]:= Value;
end;

procedure Ti8008Processor.setFlag(Flag: TFlag; Value: Boolean);
begin
  case Flag of
    fCarry  : _Flags.Carry:= Value;
    fSign   : _Flags.Sign:= Value;
    fParity : _Flags.Parity:= Value;
    fZero   : _Flags.Zero:= Value;
  end;
end;

procedure Ti8008Processor.setRAM(Address: Word; Value: Byte);
begin
  _RAM.RAM[Address]:= Value;
end;

procedure Ti8008Processor.setIPorts(Index: Byte; Value: Byte);
begin
  _IPorts.Value[Index]:= Value;
end;

procedure Ti8008Processor.setIPortActive(Active: Boolean);
begin
  _IPorts.PortFileActive:= Active;
end;

procedure Ti8008Processor.setOPortActive(Active: Boolean);
begin
  _OPorts.PortFileActive:= Active;
end;

procedure Ti8008Processor.setIPortFile(Filename: TFilename);
begin
  _IPorts.PortFile:= Filename;
end;

procedure Ti8008Processor.setOPortFile(Filename: TFilename);
begin
  _OPorts.PortFile:= Filename;
end;

procedure Ti8008Processor.setProgramCounter(Value: Word);
begin
  _Stack.ProgramCounter:= Value;
end;

procedure Ti8008Processor.ReturnFromHLT;
begin
  Halt:= false;
end;

procedure Ti8008Processor.ResetAll;
begin
  ResetStack;
  ResetRAM;
  ResetRegister;
  ResetFlags;
  ResetProgramCounter;
  ResetIPorts;
  ResetOPorts;
  Halt:= false;
end;

procedure Ti8008Processor.ResetStack;
begin
  _Stack.Reset;
end;

procedure Ti8008Processor.ResetStackPointer;
begin
  _Stack.ResetStackPointer;
end;

procedure Ti8008Processor.ResetRAM;
begin
  _RAM.Reset;
end;

procedure Ti8008Processor.RefreshRAM(Listener: IRAM);
begin
  if Assigned(Listener) then
    Listener.RefreshObject(_RAM);
end;

procedure Ti8008Processor.ResetRegister;
begin
  _Register.Reset;
end;

procedure Ti8008Processor.ResetFlags;
begin
  _Flags.Reset;
end;

procedure Ti8008Processor.ResetProgramCounter;
begin
  _Stack.ResetProgramCounter;
  Halt:= false;
end;

procedure Ti8008Processor.RefreshProgramCounter(Listener: IProgramCounter);
begin
  if Assigned(Listener) then
    Listener.RefreshObject(_Stack);
end;

procedure Ti8008Processor.ResetIPortFile;
begin
  _IPorts.ResetPortFile;
end;

procedure Ti8008Processor.ResetIPorts;
begin
  _IPorts.Reset;
end;

procedure Ti8008Processor.RefreshIPorts(Listener: IIOPorts);
begin
  if Assigned(Listener) then
    Listener.RefreshObject(_IPorts);
end;

procedure Ti8008Processor.ResetOPorts;
begin
  _OPorts.Reset;
end;

procedure Ti8008Processor.RefreshOPorts(Listener: IIOPorts);
begin
  if Assigned(Listener) then
    Listener.RefreshObject(_OPorts);
end;

procedure Ti8008Processor.RefreshAllObjects;
begin
  IStateChange;
  _Stack.RefreshObject;
  _RAM.RefreshObject;
  _Register.RefreshObject;
  _Flags.RefreshObject;
  _IPorts.RefreshObject;
  _OPorts.RefreshObject;
end;

procedure Ti8008Processor.AddStackListener(Listener: IStack);
begin
  _Stack.AddStackListener(Listener);
end;

procedure Ti8008Processor.AddRAMListener(Listener: IRAM);
begin
  _RAM.AddListener(Listener);
end;

procedure Ti8008Processor.AddRegisterListener(Listener: IRegister);
begin
  _Register.AddListener(Listener);
end;

procedure Ti8008Processor.AddFlagsListener(Listener: IFlags);
begin
  _Flags.AddListener(Listener);
end;

procedure Ti8008Processor.AddProgramCounterListener(Listener: IProgramCounter);
begin
  _Stack.AddProgramCounterListener(Listener);
end;

procedure Ti8008Processor.AddIPortListener(Listener: IIOPorts);
begin
  _IPorts.AddListener(Listener);
end;

procedure Ti8008Processor.AddOPortListener(Listener: IIOPorts);
begin
  _OPorts.AddListener(Listener);
end;

procedure Ti8008Processor.AddProcessorListener(Listener: IProcessor);
begin
  if Assigned(Listener) then
    _ListenerList.Add(Listener);
end;

procedure Ti8008Processor.DelListeners;
begin
  _Stack.DelStackListeners;
  _RAM.DelListeners;
  _Register.DelListeners;
  _Flags.DelListeners;
  _Stack.DelProgramCounterListeners;
  _IPorts.DelListeners;
  _OPorts.DelListeners;
  _ListenerList.Clear;
end;
{ ******* Ti8008Processor ******* }
end.
