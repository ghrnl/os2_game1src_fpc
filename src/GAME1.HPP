#ifndef GAME1_HPP
#define GAME1_HPP


#define ID_APPMAIN                1

#define IDM_QUIT                  5


#define IDS_ERR_CREATE_DIVEBUFFER 1001


ERRORSTATUS InitializeAppWindow
  (
  VOID
  );

VOID DrawTestPatten
  (
  VOID
  );

VOID Snap1_1
  (
  VOID
  );

VOID CenterWindow
  (
  VOID
  );

MRESULT EXPENTRY ClientWndProc
  (
  HWND             hwnd,
  ULONG            msg,
  MPARAM           mp1,
  MPARAM           mp2
  );

ERRORSTATUS InitializeDive
  (
  VOID
  );

#endif // GAME1_HPP

