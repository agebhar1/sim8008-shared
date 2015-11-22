unit uTimer;

interface

uses
  Windows, SysUtils, Messages, Classes;

type

  TTickEvent = procedure of object;

  TTimerEnabledRequestEvent = procedure(Enabled: Boolean) of object;
  
  TTimerEnabledEvent = procedure(Sender: TObject; Enabled: Boolean) of object;

  TProcessorTimer = class(TObject)
  private
    _TickTime: Cardinal;
    _Enabled: Boolean;
    _OnTick: TTickEvent;
    _OnEnabled: TTimerEnabledEvent;
    _WindowHandle: HWND;
    procedure setEnabled(Value: Boolean);
    procedure setTickTime(Value: Cardinal);
    procedure WndProc(var Msg: TMessage);
    procedure setOnTick(Value: TTickEvent);
    procedure setOnEnabled(Value: TTimerEnabledEvent);
  public
    constructor Create(TickTime: Cardinal); overload;
    constructor Create; overload;
    destructor Destroy; override;
    procedure Tick;
    procedure RemoteEnabled(Enabled: Boolean);
    property Enabled: Boolean read _Enabled write setEnabled;
    property TickTime: Cardinal read _TickTime write setTickTime;
    property OnTick: TTickEvent read _OnTick write setOnTick;
    property OnEnabled: TTimerEnabledEvent read _OnEnabled write setOnEnabled;
  end;

implementation

{ ********* TProcessorTimer ********* }
procedure TProcessorTimer.setEnabled(Value: Boolean);
begin
  if Enabled <> Value then
    begin
      if Value then
        _Enabled:= SetTimer(_WindowHandle,1,_TickTime,nil) <> 0
      else
        begin
          KillTimer(_WindowHandle,1);
          _Enabled:= false;
        end;
      if Assigned(OnEnabled) then
        OnEnabled(Self,Enabled);
    end;
end;

procedure TProcessorTimer.setTickTime(Value: Cardinal);
begin
  if (_TickTime <> Value) and (Value > 0) then
    begin
      _TickTime:= Value;
      if Enabled then
        begin
          Enabled:= false;
          Enabled:= true;
        end
    end;    
end;

procedure TProcessorTimer.WndProc(var Msg: TMessage);
begin
  if Msg.Msg = WM_TIMER then
    begin
      if Assigned(OnTick) then
        OnTick;
    end    
  else
    DefWindowProc(_WindowHandle,Msg.Msg,Msg.WParam,Msg.LParam);
end;

procedure TProcessorTimer.setOnTick(Value: TTickEvent);
begin
  _OnTick:= Value;
end;

procedure TProcessorTimer.setOnEnabled(Value: TTimerEnabledEvent);
begin
  _OnEnabled:= Value;
  if Assigned(OnEnabled) then
    OnEnabled(Self,Enabled);
end;

constructor TProcessorTimer.Create(TickTime: Cardinal);
begin
  inherited Create;
  _Enabled:= false;
  _TickTime:= TickTime;
  _WindowHandle:= AllocateHWnd(WndProc);
end;

constructor TProcessorTimer.Create;
begin
  inherited Create;
  _Enabled:= false;
  _TickTime:= 1000;
  _WindowHandle:= AllocateHWnd(WndProc);
end;

destructor TProcessorTimer.Destroy;
begin
  Enabled:= false;
  DeAllocateHWnd(_WindowHandle);
  inherited Destroy;
end;

procedure TProcessorTimer.Tick;
begin
  if not Enabled and Assigned(OnTick) then
    OnTick;
end;

procedure TProcessorTimer.RemoteEnabled(Enabled: Boolean);
begin
  Self.Enabled:= Enabled;
end;
{ ********* TProcessorTimer ********* }
end.
