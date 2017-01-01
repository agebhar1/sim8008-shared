unit uFileVersion;

interface

uses
  Windows, SysUtils;

function GetFileVersion(pFile: PChar; var wMajor, wMinor,
                        wRelease, wBuild: Word): Boolean;
function GetProductVersion(pFile: PChar; var wMajor, wMinor,
                           wRelease, wBuild: Word): Boolean;

implementation

function GetFileVersion(pFile: PChar; var wMajor, wMinor,
                        wRelease, wBuild: Word): Boolean;
var
  puLength, pHandle, InfoLength: Cardinal;
  MoreData, Data: Pointer;
  FileInfo: VS_FIXEDFILEINFO;

begin
  Result:= False;
  wMajor:= 0;
  wMinor:= 0;
  wRelease:= 0;
  wBuild:= 0;
  InfoLength:= GetFileVersionInfoSize(pFile,pHandle);
  GetMem(Data,InfoLength);
  if GetFileVersionInfo(pFile,0,InfoLength,Data) then
    if VerQueryValue(Data,'\',MoreData,puLength) then
      try
        Move(MoreData^,FileInfo,SizeOf(FileInfo));
        wMajor:= HiWord(FileInfo.dwFileVersionMS);
        wMinor:= LoWord(FileInfo.dwFileVersionMS);
        wRelease:= HiWord(FileInfo.dwFileVersionLS);
        wBuild:= LoWord(FileInfo.dwFileVersionLS);
        Result:= True;
      except
        FreeMem(Data);
        Exit;
      end;
  FreeMem(Data);
end;

function GetProductVersion(pFile: PChar; var wMajor, wMinor,
                           wRelease, wBuild: Word): Boolean;
var
  puLength, pHandle, InfoLength: Cardinal;
  MoreData, Data: Pointer;
  FileInfo: VS_FIXEDFILEINFO;

begin
  Result:= False;
  wMajor:= 0;
  wMinor:= 0;
  wRelease:= 0;
  wBuild:= 0;
  InfoLength:= GetFileVersionInfoSize(pFile,pHandle);
  GetMem(Data,InfoLength);
  if GetFileVersionInfo(pFile,0,InfoLength,Data) then
    if VerQueryValue(Data,'\',MoreData,puLength) then
      try
        Move(MoreData^,FileInfo,SizeOf(FileInfo));
        wMajor:= HiWord(FileInfo.dwProductVersionMS);
        wMinor:= LoWord(FileInfo.dwProductVersionMS);
        wRelease:= HiWord(FileInfo.dwProductVersionLS);
        wBuild:= LoWord(FileInfo.dwProductVersionLS);
        Result:= True;
      except
        FreeMem(Data);
        Exit;
      end;
  FreeMem(Data);
end;

end.
