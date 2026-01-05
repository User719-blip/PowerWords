; Inno Setup script for PowerWords

#define MyAppId "{{B5C77702-7E94-4F8F-B4A6-A2C4E9AB5F1B}}"
#define MyAppName "PowerWords"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "User719-blip"
#define MyAppURL "https://github.com/User719-blip/PowerWords"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=no
UninstallDisplayIcon={app}\bin\launcher.exe
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin
Compression=lzma2
SolidCompression=yes
OutputDir=.
OutputBaseFilename={#MyAppName}Installer
WizardStyle=modern
RestartIfNeededByRun=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked
Name: "addtopath"; Description: "Add launcher directory to &system PATH"; GroupDescription: "Environment:"; Flags: checkedonce

[Files]
Source: "..\bin\launcher.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "..\bin\*.dll"; DestDir: "{app}\bin"; Flags: ignoreversion recursesubdirs createallsubdirs skipifsourcedoesntexist
Source: "..\scripts\win\*"; DestDir: "{app}\scripts\win"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\scripts\mac\*"; DestDir: "{app}\scripts\mac"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\config\*"; DestDir: "{app}\config"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\src\*"; DestDir: "{app}\src"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion isreadme
Source: "..\version.txt"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName} Launcher"; Filename: "{app}\bin\launcher.exe"; WorkingDir: "{app}"
Name: "{commondesktop}\{#MyAppName} Launcher"; Filename: "{app}\bin\launcher.exe"; Tasks: desktopicon; WorkingDir: "{app}"

[Run]
Filename: "{app}\bin\launcher.exe"; Description: "Launch {#MyAppName} now"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\src"
Type: filesandordirs; Name: "{app}\scripts"
Type: filesandordirs; Name: "{app}\config"
Type: filesandordirs; Name: "{app}"

[Code]
type
  WPARAM = LongWord;
  LPARAM = LongInt;
  LRESULT = LongInt;

function IsOnPath(const CurrentValue, Dir: string): Boolean;
begin
  Result := Pos(';' + UpperCase(Dir) + ';', ';' + UpperCase(CurrentValue) + ';') > 0;
end;

function AddToSystemPath(const Dir: string): Boolean;
var
  ExistingValue, NewValue, CleanDir: string;
begin
  Result := False;
  CleanDir := Trim(Dir);
  if CleanDir = '' then
    Exit;
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE,
     'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
     'Path', ExistingValue) then
    Exit;

  if IsOnPath(ExistingValue, CleanDir) then
  begin
    Result := True;
    Exit;
  end;

  NewValue := ExistingValue;
  if NewValue <> '' then
  begin
    if NewValue[Length(NewValue)] <> ';' then
      NewValue := NewValue + ';';
  end;
  NewValue := NewValue + CleanDir;

  if RegWriteStringValue(HKEY_LOCAL_MACHINE,
     'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
     'Path', NewValue) then
  begin
    Result := True;
  end;
end;

function RemoveFromSystemPath(const Dir: string): Boolean;
var
  ExistingValue, NewValue, TargetDir: string;
  Items: TStringList;
  I: Integer;
begin
  Result := False;
  TargetDir := Trim(Dir);
  if TargetDir = '' then
    Exit;
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE,
     'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
     'Path', ExistingValue) then
    Exit;

  Items := TStringList.Create;
  try
    Items.StrictDelimiter := True;
    Items.Delimiter := ';';
    Items.DelimitedText := ExistingValue;

    for I := Items.Count - 1 downto 0 do
    begin
      if UpperCase(Trim(Items[I])) = UpperCase(TargetDir) then
        Items.Delete(I)
      else
        Items[I] := Trim(Items[I]);
    end;

    NewValue := '';
    for I := 0 to Items.Count - 1 do
    begin
      if Items[I] = '' then
        Continue;
      if NewValue <> '' then
        NewValue := NewValue + ';';
      NewValue := NewValue + Items[I];
    end;

    if RegWriteStringValue(HKEY_LOCAL_MACHINE,
       'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
       'Path', NewValue) then
    begin
      Result := True;
    end;
  finally
    Items.Free;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  InstallDir: string;
begin
  if CurStep = ssPostInstall then
  begin
    InstallDir := ExpandConstant('{app}\bin');
    if WizardIsTaskSelected('addtopath') then
    begin
      if AddToSystemPath(InstallDir) then
      begin
        MsgBox('{#MyAppName} has been installed.' + #13#10 +
               'The launcher directory was added to the system PATH. A logoff may be required in some shells.',
               mbInformation, MB_OK);
      end
      else
      begin
        MsgBox('{#MyAppName} has been installed, but the PATH update failed. You may need to adjust PATH manually.',
               mbError, MB_OK);
      end;
    end
    else
    begin
      MsgBox('{#MyAppName} has been installed.' + #13#10 +
             'Use the Start Menu shortcut or add {app}\bin to PATH manually if required.',
             mbInformation, MB_OK);
    end;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
  begin
    if RemoveFromSystemPath(ExpandConstant('{app}\bin')) then
    begin
      MsgBox('{#MyAppName} has been removed and the launcher directory was taken off PATH.',
             mbInformation, MB_OK);
    end;
  end;
end;