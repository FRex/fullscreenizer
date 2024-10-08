unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Windows, types;

type
  TWindowInfo = record
    Title: string;
    Handle: THandle;
    Icon: HIcon;
  end;

  { TMain }

  TMain = class(TForm)
    btFullscreenize: TButton;
    cbApplyStayOnTop: TCheckBox;
    lbWindows: TListBox;
    tmRefresh: TTimer;
    procedure btFullscreenizeClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lbWindowsDrawItem(Control: TWinControl; Index: integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure lbWindowsSelectionChange(Sender: TObject; User: boolean);
    procedure tmRefreshTimer(Sender: TObject);
  private
    { private declarations }
  public
    Wins: array of TWindowInfo;
    procedure DestroyWindowInfo;
    procedure RefreshWindows;
    procedure AddWindow(AHandle: THandle; ATitle: string; AIcon: HIcon);
  end;

var
  Main: TMain;

implementation

{$R *.lfm}

{ TMain }

function WindowsEnumerator(_para1: HWND; _para2: LPARAM): WINBOOL; stdcall;
var
  Title: array [0..1024] of unicodechar;
  TitStr: utf8string;
  Icon: HICON;
  ProcessId: DWORD;
begin
  if not IsWindowVisible(_para1) then Exit(True);
  GetWindowTextW(_para1, @Title, 1024);
  TitStr := Title;
  if Trim(TitStr) = '' then Exit(True);
  Icon := HICON(SendMessage(_para1, WM_GETICON, ICON_SMALL, 0));
  if Icon = 0 then Icon := HICON(GetClassLongPtr(_para1, GCL_HICONSM));
  if Icon = 0 then Icon := HICON(GetClassLongPtr(_para1, GCL_HICON));
  if Icon <> 0 then Icon := CopyIcon(Icon);

  // do not add windows that belong to our process
  ProcessId := 0;
  GetWindowThreadProcessId(_para1, @ProcessId);
  if ProcessId <> GetProcessId() then
    Main.AddWindow(_para1, TitStr, Icon);

  Result := True;
end;

procedure TMain.FormCreate(Sender: TObject);
begin
  RefreshWindows;
end;

procedure TMain.FormDestroy(Sender: TObject);
begin
  DestroyWindowInfo;
end;

procedure TMain.lbWindowsDrawItem(Control: TWinControl; Index: integer;
  ARect: TRect; State: TOwnerDrawState);
begin
  with lbWindows.Canvas do
  begin
    Pen.Color := Brush.Color;
    Rectangle(ARect);
    TextOut(ARect.Left + 18, ARect.Top + 1, lbWindows.Items[Index]);
    DrawIconEx(Handle, ARect.Left, ARect.Top, Wins[Index].Icon, 16, 16, 0, 0, DI_NORMAL);
  end;
end;

procedure TMain.lbWindowsSelectionChange(Sender: TObject; User: boolean);
begin
  btFullscreenize.Enabled := lbWindows.ItemIndex <> -1;
end;

procedure TMain.tmRefreshTimer(Sender: TObject);
begin
  RefreshWindows;
end;

procedure TMain.DestroyWindowInfo;
var
  I: integer;
begin
  for I := 0 to High(Wins) do
  begin
    if Wins[I].Icon <> 0 then DestroyIcon(Wins[I].Icon);
  end;
  SetLength(Wins, 0);
end;

procedure TMain.btFullscreenizeClick(Sender: TObject);
var
  FinalRect: TRect;
  Win: HWND;
begin
  if not ((0 <= lbWindows.ItemIndex) and (lbWindows.ItemIndex < Length(Wins))) then
    Exit;

  // use the monitor window is on, Screen.Width and Height is primary one
  Win := Wins[lbWindows.ItemIndex].Handle;
  FinalRect := Screen.MonitorFromWindow(Win).BoundsRect;

  SetWindowLong(Win, GWL_STYLE, LONG(WS_POPUP or WS_VISIBLE));
  AdjustWindowRect(FinalRect, GetWindowLong(Win, GWL_STYLE), False);
  if cbApplyStayOnTop.Checked then
    SetWindowLong(Win, GWL_EXSTYLE, GetWindowLong(Win, GWL_EXSTYLE) or WS_EX_TOPMOST);
  MoveWindow(Win, FinalRect.Left, FinalRect.Top, FinalRect.Right -
    FinalRect.Left, FinalRect.Bottom - FinalRect.Top, True);
end;

procedure TMain.FormActivate(Sender: TObject);
begin
  RefreshWindows;
end;

procedure TMain.RefreshWindows;
var
  I: integer;
  OldWindowHandle: THandle;
begin
  OldWindowHandle := 0;
  if (0 <= lbWindows.ItemIndex) and (lbWindows.ItemIndex < Length(Wins)) then
    OldWindowHandle := Wins[lbWindows.ItemIndex].Handle;

  DestroyWindowInfo;
  EnumWindows(@WindowsEnumerator, 0);
  lbWindows.Clear;
  for I := 0 to High(Wins) do
  begin
    lbWindows.Items.Add(Wins[I].Title);
  end;

  if OldWindowHandle <> 0 then
    for I := 0 to High(Wins) do
      if OldWindowHandle = Wins[I].Handle then
        lbWindows.ItemIndex := I;

  btFullscreenize.Enabled := lbWindows.ItemIndex <> -1;
end;

procedure TMain.AddWindow(AHandle: THandle; ATitle: string; AIcon: Hicon);
begin
  SetLength(Wins, Length(Wins) + 1);
  with Wins[High(Wins)] do
  begin
    Handle := AHandle;
    Title := ATitle;
    Icon := AIcon;
  end;
end;

end.
