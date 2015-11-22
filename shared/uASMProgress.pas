unit uASMProgress;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, uAssembler, EnhCtrls;

type
  TASMProgressForm = class(TForm)
    pMain: TPanel;
    BottomPanel: TPanel;
    BtnOk: TButton;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    LblrsProject: TLabel;
    LblrsState: TLabel;
    LblrsLine: TLabel;
    LblrsErrors: TLabel;
    LblrsWarnings: TLabel;
    LblrsHints: TLabel;
    LblState: TLabel;
    LblLine: TLabel;
    LblErrors: TLabel;
    LblWarnings: TLabel;
    LblHints: TLabel;
    Panel7: TPanel;
    LblrsSize: TLabel;
    LblSize: TLabel;
    Timer: TTimer;
    LblProject: TFilenameLabel;
    procedure BtnOkClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    _Project: String;
    _Parser: TParser;
    _Program: TProgram;
    _parseresult: Boolean;
  public
    procedure ASMStart(Sender: TObject);
    procedure ASMProgress(Sender: TObject; Errors: Integer; Warnings: Integer;
                                           Hints: Integer; Line: Integer;
                                           genCode: Boolean);
    procedure ASMStop(Sender: TObject; Size: Integer; Error: Boolean);
    procedure LoadLanguage;
    function Execute(Parser: TParser; theProgram: TProgram): Boolean;
    property Project: String read _Project write _Project;
  end;

implementation

{$R *.dfm}

uses
  uResourceStrings;

{ ********** TASMProgressForm ********** }
procedure TASMProgressForm.FormCreate(Sender: TObject);
begin
  Timer.Enabled:= false;
  LoadLanguage;
end;

procedure TASMProgressForm.ASMStart(Sender: TObject);
begin
  BtnOk.Enabled:= false;
  LblSize.Caption:= '?';
  LblState.Caption:= '';
  LblLine.Caption:= '0';
  LblErrors.Caption:= '0';
  LblWarnings.Caption:= '0';
  LblHints.Caption:= '0';
  Application.ProcessMessages;
end;

procedure TASMProgressForm.ASMProgress(Sender: TObject; Errors: Integer; Warnings: Integer;
                                       Hints: Integer; Line: Integer; genCode: Boolean);
begin
  if genCode then
    LblState.Caption:= getString(rsCodeBuild)
  else
    LblState.Caption:= getString(rsCodeCheck);
  LblLine.Caption:= IntToStr(Line);
  LblErrors.Caption:= IntToStr(Errors);
  LblWarnings.Caption:= IntToStr(Warnings);
  LblHints.Caption:= IntToStr(Hints);
  if Visible then
    SetFocus;
  Application.ProcessMessages;
end;

procedure TASMProgressForm.ASMStop(Sender: TObject; Size: Integer; Error: Boolean);
begin
  if not Error then
    begin
      LblState.Caption:= getString(rsDone);
      LblSize.Caption:= IntToStr(Size);
    end;
  BtnOk.Enabled:= true;
  if Visible then
    BtnOk.SetFocus;
  Application.ProcessMessages;
end;

procedure TASMProgressForm.LoadLanguage;
begin
  Caption:= getString(rsAssemble);
  LblrsProject.Caption:= getString(rsProject)+':';
  LblrsSize.Caption:= getString(rsSize)+':';
  LblrsState.Caption:= getString(rsState)+':';
  LblrsLine.Caption:= getString(rsLine)+':';
  LblrsErrors.Caption:= getString(rsErrors)+':';
  LblrsWarnings.Caption:= getString(rsWarnings)+':';
  LblrsHints.Caption:= getString(rsHints)+':';
end;

function TASMProgressForm.Execute(Parser: TParser; theProgram: TProgram): Boolean;
begin
  LblProject.Caption:= _Project;
  LblSize.Caption:= '?';
  LblState.Caption:= '';
  LblLine.Caption:= '0';
  LblErrors.Caption:= '0';
  LblWarnings.Caption:= '0';
  LblHints.Caption:= '0';
  BtnOk.Enabled:= true;
  Top:= (Screen.Height-Height) div 2;
  Left:= (Screen.Width-Width) div 2;
  _parseresult:= false;
  _Parser:= Parser;
  _Program:= theProgram;
  inherited ShowModal;
  result:= _parseresult;
end;

procedure TASMProgressForm.BtnOkClick(Sender: TObject);
begin
  Close;
end;

procedure TASMProgressForm.FormShow(Sender: TObject);
begin
  Timer.Enabled:= true;
end;

procedure TASMProgressForm.TimerTimer(Sender: TObject);
begin
  Timer.Enabled:= false;
  if Assigned(_Parser) then
    _parseresult:= _Parser.Parse(_Program);
end;
{ ********** TASMProgressForm ********** }

end.
