unit uMisc;

interface

uses
  Windows, SysUtils, Registry, Classes, Forms;

type

  TRegistryList = class;
  IRegistry = interface(IInterface)
    procedure LoadData(RegistryList: TRegistryList);
    procedure SaveData(RegistryList: TRegistryList);
  end;

  TRegistryList = class(TObject)
  private
    _List: TInterfaceList;
    _Registry: TRegistry;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddListener(Listener: IRegistry);
    procedure DelListeners;
    procedure LoadData;
    procedure SaveData;
    procedure LoadFormSettings(Form: TForm; LoadSize: Boolean);
    procedure SaveFormSettings(Form: TForm; SaveSize: Boolean);
    property Registry: TRegistry read _Registry write _Registry;
  end;

  TWatchType = (wtRAM, wtIPort, wtOPort);

  TWatchItem = class(TObject)
  private
    _Address: Word;
    _Type: TWatchType;
  public
    constructor Create;
    property Address: Word read _Address write _Address;
    property WatchType: TWatchType read _Type write _Type;
  end;

  TWatchList = class(TObject)
  private
    _List: TList;
    function getItem(Index: Integer): TWatchItem;
  public
    constructor Create;
    destructor Destroy; override;
    function Add(Address: Word; WatchType: TWatchType): Integer;
    procedure Delete(Index: Integer);
    function FindAddress(Address: Word; WatchType: TWatchType): Integer;
    function AddressExists(Address: Word; WatchType: TWatchType): Boolean;
    procedure Clear;
    function Count: Integer;
    property Item[Index: Integer]: TWatchItem read getItem;
  end;

  TBreakpointItem = class(TObject)
  private
    _State: Boolean;
    _Line: Integer;
  public
    constructor Create;
    property Line: Integer read _Line write _Line;
    property State: Boolean read _State write _State;
  end;

  TBreakpointList = class(TObject)
  private
    _List: TList;
    function FindItem(Line: Integer; var found: Boolean): Integer;
    function getBreakpointState(Line: Integer): Boolean;
    procedure setBreakpointState(Line: Integer; State: Boolean);
    function getItem(Index: Integer): TBreakpointItem;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ClearAllBreakpoints;
    function Count: Integer;
    function ToggleBreakpoint(Line: Integer): Boolean;
    function Breakpoint(Line: Integer): Boolean;
    property BreakpointState[Line: Integer]: Boolean read GetBreakpointState write SetBreakpointState;
    property Items[Index: Integer]: TBreakpointItem read getItem;
  end;

const
  COMPANY_KEY          = 'Andreas Gebhardt';
  APPLICATION_KEY      = 'Sim 8008';
  VERSION_KEY          = 'V2';
  APPLICATION_MAIN_KEY = '\Software\'+COMPANY_KEY+'\'+APPLICATION_KEY+'\'+VERSION_KEY+'\';

implementation

{ ********* TRegistryList ********* }
constructor TRegistryList.Create;
begin
  inherited Create;
  _List:= TInterfaceList.Create;
end;

destructor TRegistryList.Destroy;
begin
  DelListeners;
  _List.Free;
  inherited Destroy;
end;

procedure TRegistryList.AddListener(Listener: IRegistry);
begin
  if Assigned(Listener) then
    _List.Add(Listener);
end;

procedure TRegistryList.DelListeners;
begin
  _List.Clear;
end;

procedure TRegistryList.LoadData;
var
  i: Integer;
  Listener: IRegistry;
begin
  Registry:= TRegistry.Create(KEY_READ);
  if Assigned(Registry) then
    begin
      Registry.RootKey:= HKEY_CURRENT_USER;
      for i:= 0 to _List.Count-1 do
        begin
          Listener:= IRegistry(_List.Items[i]);
          if Assigned(Listener) then
            Listener.LoadData(Self);
        end;
      Registry.Free;
    end;
end;

procedure TRegistryList.SaveData;
var
  i: Integer;
  Listener: IRegistry;
begin
  Registry:= TRegistry.Create(KEY_WRITE);
  if Assigned(Registry) then
    begin
      Registry.RootKey:= HKEY_CURRENT_USER;    
      for i:= 0 to _List.Count-1 do
        begin
          Listener:= IRegistry(_List.Items[i]);
          if Assigned(Listener) then
            Listener.SaveData(Self);
        end;
      Registry.Free;
    end;
end;

procedure TRegistryList.LoadFormSettings(Form: TForm; LoadSize: Boolean);
var
  sScreen: String;
begin
  if Assigned(Form) and Assigned(Registry) then
    begin
      if Registry.ValueExists(Form.Name+'_'+'Visible') then
        if Registry.ReadInteger(Form.Name+'_'+'Visible') = 1 then
          Form.Show;
      sScreen:= IntToStr(Screen.Width)+'x'+IntToStr(Screen.Height);
      if Registry.ValueExists(Form.Name+'_'+sScreen+'_Top') then
        Form.Top:= Registry.ReadInteger(Form.Name+'_'+sScreen+'_Top');
      if Registry.ValueExists(Form.Name+'_'+sScreen+'_Left') then
        Form.Left:= Registry.ReadInteger(Form.Name+'_'+sScreen+'_Left');
      if LoadSize then
        begin
          if Registry.ValueExists(Form.Name+'_'+sScreen+'_Width') then
            Form.Width:= Registry.ReadInteger(Form.Name+'_'+sScreen+'_Width');
          if Registry.ValueExists(Form.Name+'_'+sScreen+'_Height') then
            Form.Height:= Registry.ReadInteger(Form.Name+'_'+sScreen+'_Height');
          if Registry.ValueExists(Form.Name+'_'+'WindowState') then
            case Registry.ReadInteger(Form.Name+'_'+'WindowState') of
              0: Form.WindowState:= wsNormal;
              1: Form.WindowState:= wsMinimized;
              2: Form.WindowState:= wsMaximized;
            end;
        end;
    end;
end;

procedure TRegistryList.SaveFormSettings(Form: TForm; SaveSize: Boolean);
var
  sScreen: String;
begin
  if Assigned(Form) and Assigned(Registry) then
    begin
      if Form.Visible then
        Registry.WriteInteger(Form.Name+'_'+'Visible',1)
      else
        Registry.WriteInteger(Form.Name+'_'+'Visible',0);
      sScreen:= IntToStr(Screen.Width)+'x'+IntToStr(Screen.Height);
      Registry.WriteInteger(Form.Name+'_'+sScreen+'_Top',Form.Top);
      Registry.WriteInteger(Form.Name+'_'+sScreen+'_Left',Form.Left);
      if SaveSize then
        begin
          Registry.WriteInteger(Form.Name+'_'+sScreen+'_Width',Form.Width);
          Registry.WriteInteger(Form.Name+'_'+sScreen+'_Height',Form.Height);
            case Form.WindowState of
              wsNormal    : Registry.WriteInteger(Form.Name+'_'+'WindowState',0);
              wsMinimized : Registry.WriteInteger(Form.Name+'_'+'WindowState',1);
              wsMaximized : Registry.WriteInteger(Form.Name+'_'+'WindowState',2);
            end;
        end;
    end;
end;
{ ******* TRegistryList ******** }
{ ********* TWatchItem ********* }
constructor TWatchItem.Create;
begin
  _Address:= 0;
  _Type:= wtRAM;
end;
{ ********* TWatchItem ********* }
{ ********* TWatchList ********* }
function TWatchList.getItem(Index: Integer): TWatchItem;
begin
  if (Index >= 0) and (Index < Count) then
    result:= _List.Items[Index]
  else
    result:= nil;
end;

constructor TWatchList.Create;
begin
  inherited Create;
  _List:= TList.Create;
end;

destructor TWatchList.Destroy;
begin
  Clear;
  _List.Free;
  inherited Destroy;
end;

function TWatchList.Add(Address: Word; WatchType: TWatchType): Integer;
var
  Item: TWatchItem;
begin
  if not AddressExists(Address,WatchType) then
    begin
      Item:= TWatchItem.Create;
      Item.Address:= Address;
      Item.WatchType:= WatchType;
      result:= _List.Add(Item)
    end
  else
    result:= -1;
end;

procedure TWatchList.Delete(Index: Integer);
var
  Item: TWatchItem;
begin
  if (Index >= 0) and (Index < Count) then
    begin
      Item:= _List.Items[Index];
      if Assigned(Item) then
        Item.Free;
      _List.Delete(Index);
    end;
end;

function TWatchList.FindAddress(Address: Word; WatchType: TWatchType): Integer;
var
  Item: TWatchItem;
  i: Integer;
  found: Boolean;
begin
  found:= false;
  i:= 0;
  while not found and (i < _List.Count) do begin
    Item:= _List.Items[i];
    found:= Assigned(Item) and (Item.Address = Address) and (Item.WatchType = WatchType);
    if not found then Inc(i);
  end;
  if found then result:= i
  else result:= -1;
end;

function TWatchList.AddressExists(Address: Word; WatchType: TWatchType): Boolean;
begin
  result:= FindAddress(Address,WatchType) >= 0;
end;

procedure TWatchList.Clear;
var
  Item: TWatchItem;
begin
  while _List.Count > 0 do
    begin
      Item:= _List.Items[_List.Count-1];
      if Assigned(Item) then
        Item.Free;
      _List.Delete(_List.Count-1);
    end;
end;

function TWatchList.Count: Integer;
begin
  result:= _List.Count;
end;
{ ********* TWatchList ********* }
{ ****** TBreakpointItem ******* }
constructor TBreakpointItem.Create;
begin
  inherited Create;
  _Line:= -1;
  _State:= false;
end;
{ ****** TBreakpointItem ******* }
{ ****** TBreakpointList ******* }
procedure TBreakpointList.ClearAllBreakpoints;
var
  Item: TBreakpointItem;
begin
  while _List.Count > 0 do begin
    Item:= _List[_List.Count-1];
    if Assigned(Item) then Item.Free;
    _List.Delete(_List.Count-1);
  end;
end;

constructor TBreakpointList.Create;
begin
  inherited Create;
  _List:= TList.Create;
end;

destructor TBreakpointList.Destroy;
begin
  ClearAllBreakpoints;
  FreeAndNil(_List);
  inherited;
end;

function TBreakpointList.FindItem(Line: Integer; var found: Boolean): Integer;
var
  left, right: Integer;
  Item: TBreakpointItem;
begin
  found:= false;
  left:= 0;
  right:= _List.Count-1;
  result:= 0;
  // Binary Search
  while (not found) and (left <= right) do begin
    result:= left + (right-left) div 2;
    Item:= _List[result];
    found:= Line = Item.Line;
    if not found then begin
      if Line > Item.Line then left:= result + 1
      else right:= result - 1;
    end;
  end;
  if not found then result:= right + 1;
end;

function TBreakpointList.Breakpoint(Line: Integer): Boolean;
var
  Index: Integer;
  found: Boolean;
  Item: TBreakpointItem;
begin
  Index:= FindItem(Line, found);
  if found then begin
    Item:= _List[Index];
    result:= Assigned(Item);
  end else result:= false;
end;

function TBreakpointList.ToggleBreakpoint(Line: Integer): Boolean;
var
  Index: Integer;
  found: Boolean;
  Item: TBreakpointItem;
begin
  Index:= FindItem(Line, found);
  if found then begin
    Item:= _List[Index];
    if Assigned(Item) then FreeAndNil(Item);
    _List.Delete(Index);
  end else begin
    Item:= TBreakpointItem.Create;
    Item.Line:= Line;
    Item.State:= true;
    _List.Insert(Index, Item);
  end;
  result:= not found;
end;

function TBreakpointList.getBreakpointState(Line: Integer): Boolean;
var
  Index: Integer;
  found: Boolean;
  Item: TBreakpointItem;
begin
  Index:= FindItem(Line, found);
  if found then begin
    Item:= _List[Index];
    if Assigned(Item) then result:= Item.State
    else result:= false;
  end else result:= false;
end;

procedure TBreakpointList.setBreakpointState(Line: Integer; State: Boolean);
var
  Index: Integer;
  found: Boolean;
  Item: TBreakpointItem;
begin
  Index:= FindItem(Line, found);
  if found then begin
    Item:= _List[Index];
    if Assigned(Item) then Item.State:= State;
  end;
end;

function TBreakpointList.Count: Integer;
begin
  result:= _List.Count;
end;

function TBreakpointList.getItem(Index: Integer): TBreakpointItem;
begin
  if (Index >=0) and (Index < Count) then result:= _List[Index]
  else result:= nil;
end;
{ ****** TBreakpointList ******* }

end.
