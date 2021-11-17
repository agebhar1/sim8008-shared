unit uResourceStrings;

interface

uses
  Windows, Classes;

type
  { Interface for loading strings }
  ILanguage = interface(IInterface)
    procedure LoadLanguage;
  end;

  { supported Languages      }
  TLanguage = (lGerman, lEnglish);

  TLanguageList = class(TObject)
  private
    _List: TInterfaceList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddListener(Listener: ILanguage);
    procedure DelListeners;
    procedure Update;
  end;

  function getString(ID: Integer): String;
  function getLanguage: TLanguage;
  procedure setLanguage(Language: TLanguage);

const
  { Assembler Resources        }
  rsNewLine               = $00;
  rsOneStatement          = $01;
  rsUnknownStatement      = $02;
  rsUnknownIdentifier     = $03;
  rsUnknownLabel          = $04;
  rsRAMOverflow           = $05;
  rsOverrideIdentifier    = $06;
  rsOverrideLabel         = $07;
  rsOverrideRAM           = $08;
  rsUndefinedIdentifier   = $09;
  rsMissingEnd            = $0A;
  rsMissingStatement      = $0B;
  rsMissingOperand        = $0C;
  rsInvalidRegister       = $0D;
  rsInvalidOperand        = $0E;
  rsInvalidNumber         = $0F;
  rsInvalidCharacter      = $10;
  rsOperandOverflow       = $11;
  rsMOV2HLTWarning        = $12;
  { ASMProgress Resources      }
  rsProject               = $13;
  rsSize                  = $14;
  rsState                 = $15;
  rsLine                  = $16;
  rsErrors                = $17;
  rsWarnings              = $18;
  rsHints                 = $19;
  rsAssemble              = $1A;
  rsCodeCheck             = $1B;
  rsCodeBuild             = $1C;
  rsDone                  = $1D;
  { Editor Resources           }
  rsError                 = $1E;
  rsFatalError            = $1F;
  rsWarning               = $20;
  rsHint                  = $21;
  rsSaveChanges           = $22;
  rsSingleStep            = $23;
  rsRunning               = $24;
  { Stack Resources            }
  rsAddress               = $25;
  rsValue                 = $26;
  rsClose                 = $27;
  rsStayOnTop             = $28;
  rsNotANumber            = $29;
  { RAM Resources              }
  rsPage                  = $2A;
  { Watch Resources            }
  rsWatch                 = $2B;
  rsAddWatchRAM           = $2C;
  rsAddWatchIPORT         = $2D;
  rsAddWatchOPORT         = $2E;
  rsDelWatch              = $2F;
  rsDelAll                = $30;
  rsExistingAddress       = $31;
  rsInvalidPortAddress    = $32;
  { IO Ports Resources         }
  rsPortAddress           = $33;
  { Disassembler               }
  rsSourcecode            = $34;
  { Menu - File                }
  rs_m_File               = $35;
  rs_m_New                = $36;
  rs_m_SourceCode         = $37;
  rs_m_Open               = $38;
  rs_m_Save               = $39;
  rs_m_SaveAs             = $3A;
  rs_m_ProjectSaveAs      = $3B;
  rs_m_ProjectOpen        = $3C;
  rs_m_Print              = $3D;
  rs_m_Close              = $3E;
  { Menu - View                }
  rs_m_View               = $3F;
  rs_m_Watch              = $40;
  { Menu - Setup               }
  rs_m_Setup              = $41;
  rs_m_Radix              = $42;
  rs_m_Octal              = $43;
  rs_m_Decimal            = $44;
  rs_m_Hexadecimal        = $45;
  rs_m_Binary             = $46;
  rs_m_Split              = $47;
  rs_m_ASMProgress        = $48;
  rs_m_Language           = $49;
  rs_m_UseRegistry        = $4A;
  { Menu - Project             }
  rs_m_Project            = $4B;
  rs_m_Assemble           = $4C;
  rs_m_ResetRAM           = $4D;
  rs_m_ResetStack         = $4E;
  rs_m_ResetRegisterFlags = $4F;
  rs_m_ResetIPort         = $50;
  rs_m_ResetOPort         = $51;
  rs_m_ReturnFromHLT      = $52;
  rs_m_ResetAll           = $53;
  { Menu - Start               }
  rs_m_Start              = $54;
  rs_m_Singlestep         = $55;
  { Menu - Help                }
  rs_m_Help               = $56;
  { Toolbar                    }
  rs_m_Timer              = $57;
  { Messages                   }
  rs_msg_SaveError        = $58;
  rs_msg_OpenError        = $59;
  { Dialog File Filter         }
  rs_filter_Project       = $5A;
  rs_filter_File          = $5B;
  {                            }
  rsProcessorState        = $5C;
  { Port                       }
  rs_p_File               = $5D;
  rs_p_Active             = $5E;
  rs_p_Close              = $5F;
  rs_p_Open               = $60;
  rs_p_Save               = $61;
  rs_p_OpenDialog         = $62;
  rs_p_SaveDialog         = $63;
  rs_p_OpenFilter         = $64;
  rs_p_SaveFilter         = $65;
  rs_p_ResetFile          = $66;
  { I/O Editor                 }
  rs_io_SaveAs            = $67;
  rs_io_CloseFile         = $68;
  rs_io_Create_Error      = $69;
  rs_io_Open_Error        = $6A;
  rs_io_Save_Error        = $6B;
  rs_io_Row               = $6C;
  rs_io_Port              = $6D;
  rs_io_IN_Portfile       = $6E;
  rs_io_OUT_Portfile      = $6F;
  rs_io_AllPortFilter     = $70;
  rs_io_SaveCreateDialog  = $71;
  rs_io_Add               = $72;
  rs_io_Insert            = $73;
  rs_io_Replicate         = $74;
  rs_io_Delete            = $75;
  { Message                    }
  rs_msg_Execute          = $76;

implementation

{$R shared\resource\ResourceStrings.res}

uses
  SysUtils;

var
  _LangOffset: Integer;  

{ ********* TLanguageList ********* }
constructor TLanguageList.Create;
begin
  inherited Create;
  _List:= TInterfaceList.Create;
end;

destructor TLanguageList.Destroy;
begin
  DelListeners;
  _List.Free;
  inherited Destroy;
end;

procedure TLanguageList.AddListener(Listener: ILanguage);
begin
  if Assigned(Listener) then
    begin
      _List.Add(Listener);
      Listener.LoadLanguage;
    end;
end;

procedure TLanguageList.DelListeners;
begin
  _List.Clear;
end;

procedure TLanguageList.Update;
var
  i: Integer;
  Listener: ILanguage;
begin
  for i:= 0 to _List.Count-1 do
    begin
      Listener:= ILanguage(_List.Items[i]);
      if Assigned(Listener) then
        Listener.LoadLanguage;
    end;
end;
{ ********* TLanguageList ********* }

function getString(ID: Integer): String;
begin
  result:= LoadStr(_LangOffset+ID);
end;

function getLanguage: TLanguage;
begin
  case _LangOffset div 1000 of
    0: result:= lGerman;
  else result:= lEnglish;
  end;
end;

procedure setLanguage(Language: TLanguage);
begin
  case Language of
    lGerman  : _LangOffset:= 0;
    lEnglish : _LangOffset:= 1000;
  end;
end;

initialization
  setLanguage(lGerman);
end.
