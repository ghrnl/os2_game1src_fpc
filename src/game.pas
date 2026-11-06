{ --------------------------------------------------------------------
      This is the main OS/2 shell from which the game will be h_ung.
   Almost all other modules should be OS inspecific, with the exception
   of the input modules.

                              Michael T. Duffy
-------------------------------------------------------------------- }

{ 2026 port to FPC 3.2.4 G.H. Renkema                                }

program game;

{$APPTYPE GUI}
{$R GAME1.RES}  // rc -r GAME1.RC

uses os2def, pmwin, pmgpi, pmbitmap, mmbase, dive, divext, tcanvas;

{$i pmgpi.inc}
{ i dive.inc}


{ Global Variables                 }
// ***********************************************************************
//  Variables
// ***********************************************************************

const
  NULLHANDLE=0;
  
type
  HDC     = cardinal;
  LONG    = longint;
  ULONG   = cardinal; // needed ???
  HPAL    = longint; // cardinal?
  SHORT   = integer;
  PCANVAS = pointer; // ???

// OS/2 environment variables.
var
  h_ab: HAB;
  h_wndFrame, h_wndClient: HWND;
  
  szTitle: pChar = 'Gearing up for Games.  Sample 1';
  h_dcClientHDC: HDC = NULLHANDLE;

const
  szClientClass: pChar = 'CLIENT'; // CHAR

var
  // Dive variables
  DiveCaps  : TDIVE_CAPS; // = {0};
  fccFormats: array [0..100-1] of FOURCC; // = {0};
  h_Dive    : HDIVE = NULLHANDLE;
  bDiveHaveBuffer   : boolean = FALSE;
  ulDiveBufferNumber: ULONG = 0;
  
  // Canvas variables
  pcnvMainCanvas: PCANVAS = nil;
  
  // Palette variables
  h_palMain: HPAL;
  
const
  ulIMAGE_WIDTH  = 320; // ULONG
  ulIMAGE_HEIGHT = 200; // ULONG

var
  lTotalWidth : LONG  = 320;
  lTotalHeight: LONG  = 200;

var
  abyVGADefault16Palette: array[0..63] of byte = (
     0,   0,   0, PC_RESERVED,   171,   0,   0, PC_RESERVED,
     0, 171,   0, PC_RESERVED,   171, 171,   0, PC_RESERVED,
     0,   0, 171, PC_RESERVED,   171,   0, 171, PC_RESERVED,
     0,  85, 171, PC_RESERVED,   171, 171, 171, PC_RESERVED,
    85,  85,  85, PC_RESERVED,   255,  85,  85, PC_RESERVED,
    85, 255,  85, PC_RESERVED,   255, 255,  85, PC_RESERVED,
    85,  85, 255, PC_RESERVED,   255,  85, 255, PC_RESERVED,
    85, 255, 255, PC_RESERVED,   255, 255, 255, PC_RESERVED);
    
  // abyVGADefault16Palette: array[0..63] of byte;

//........................................................................
// USHORT APIENTRY PostError
function PostError(h_ab:HAB; h_wnd: HWND; usErrorID: USHORT): USHORT; cdecl; export;
//........................................................................

const
  MAX_BUFF =  128;

var
  // static char        szMsgBuffer[MAX_BUFF];
  // both are OK here: // pChar; // array [0..MAX_BUFF-1] of char;
  // but where does its value come from ? from usErrorID I guess; OK, so we can ignore static here
  szMsgBuffer  : array [0..MAX_BUFF-1] of char; 
  h_wndSavedWin: HWND;
  usResult     : USHORT;
  
begin
  h_wndSavedWin := WinQueryCapture (HWND_DESKTOP);
  WinSetCapture (HWND_DESKTOP, NULLHANDLE);
  WinLoadString (h_ab, 0, usErrorID, MAX_BUFF, szMsgBuffer);
  usResult := WinMessageBox (HWND_DESKTOP, h_wnd, szMsgBuffer,
                                     'Error!', 0, MB_OK or MB_WARNING or
                                   MB_APPLMODAL);
  WinSetCapture (HWND_DESKTOP, h_wndSavedWin);
  PostError := usResult;
end; {PostError}


const ID_APPMAIN                =    1;
const IDM_QUIT                  =    5;
const IDS_ERR_CREATE_DIVEBUFFER = 1001;

{ mousutil.pas}

function SHORT1FROMMP(MP: pointer): word;
{ map C name SHORT1... on fpc name integer1... }
{ pmwin.pas:    function Integer1FromMP (MP: pointer): word; cdecl; }
begin
  SHORT1FROMMP:=integer1frommp(mp)
end;

const
  FOURCC_SCRN = 0;

// ***********************************************************************
//  Code
// ***********************************************************************

//........................................................................
// dbg helper
//........................................................................

procedure dbgwriteln(s: string);
begin
  // writeln(s)
end;

//........................................................................
// ERRORSTATUS InitializeDive
function InitializeDive: ERRORSTATUS;
//........................................................................

var
  dummybuffer: pointer;
  
begin
  // Get the screen capabilities, and if the system supports only 16 colors
  //  the program should be terminated.
  
  DiveCaps.pFormatData    := @fccFormats;
  DiveCaps.ulFormatLength := 100;
  DiveCaps.ulStructLen    := sizeof(TDIVE_CAPS);
  
  if ( DiveQueryCaps ( @DiveCaps, DIVE_BUFFER_SCREEN ) >0 ) then
    begin
    WinMessageBox( HWND_DESKTOP, HWND_DESKTOP,
        'Error: DIVE routines cannot function in this system environment.',
        '   This program is unable to run.', 0, MB_OK or MB_INFORMATION );
    InitializeDive := ES_ERROR;
    end;
    
  if ( DiveCaps.ulDepth < 8 ) then
    begin
    WinMessageBox( HWND_DESKTOP, HWND_DESKTOP,
        'Error: Not enough screen colors to run DIVE.  Must be at least 256 colors.',
        '   This program is unable to run.', 0, MB_OK or MB_INFORMATION );
    InitializeDive := ES_ERROR;
    end;
    
  // Get an instance of DIVE APIs.
  dummybuffer := nil;
  // halt;
  if ( DiveOpen ( h_Dive, 0 {FALSE},  dummybuffer {nil} ) >0 ) then // (140,42) Error: Can't assign values to an address
    begin
    WinMessageBox( HWND_DESKTOP, HWND_DESKTOP,
        'Error: Unable to open an instance of DIVE.',
        '   This program is unable to run.', 0, MB_OK or MB_INFORMATION );
    InitializeDive := ES_ERROR;
    end;

  InitializeDive := ES_NO_ERROR;
end; {InitializeDive}


//........................................................................
procedure DrawTestPattern;
//........................................................................

begin
  // Draw Test pattern to canvas
  {
  pcnvMainCanvas->Clear (WHITE);
  pcnvMainCanvas->SetDrawColor (0);
  pcnvMainCanvas->Rectangle (40,40,80,80);
  pcnvMainCanvas->Rectangle (10,10,80,80);
  pcnvMainCanvas->SetDrawColor (RED);
  pcnvMainCanvas->Rectangle (30,30,60,60);
  }
  canvas_Clear (WHITE);
  canvas_SetDrawColor (BLACK); // 0);
  canvas_Rectangle (40,40,80,80);
  canvas_Rectangle (10,10,80,80);
  canvas_SetDrawColor (RED);
  canvas_Rectangle (30,30,60,60);
  // readln;
end; {DrawTestPattern}


//........................................................................
procedure Snap1_1;
//........................................................................

var
  lBorderWidth: LONG;
  lBorderHeight: LONG;
  lTitlebarHeight: LONG;
  lMenuHeight: LONG;

begin
  lBorderWidth    := WinQuerySysValue (HWND_DESKTOP, SV_CXDLGFRAME);
  lBorderHeight   := WinQuerySysValue (HWND_DESKTOP, SV_CYDLGFRAME);
  lTitlebarHeight := WinQuerySysValue (HWND_DESKTOP, SV_CYTITLEBAR);
  lMenuHeight     := WinQuerySysValue (HWND_DESKTOP, SV_CYMENU);
  
  lTotalWidth  := ulIMAGE_WIDTH + lBorderWidth * 2;
  lTotalHeight := ulIMAGE_HEIGHT + (lBorderHeight * 2) + lTitlebarHeight +
                 lMenuHeight;

  // Set the window size.
  WinSetWindowPos (h_wndFrame,
                 HWND_TOP,
                 0, 0, lTotalWidth, lTotalHeight,
                 SWP_SIZE or SWP_SHOW or SWP_ACTIVATE);
end; {Snap1_1}

//........................................................................
procedure CenterWindow;
//........................................................................

var
  lcxWindowPos: LONG;
  lcyWindowPos: LONG;
  
begin
  lcxWindowPos   := ( {(LONG)} WinQuerySysValue(HWND_DESKTOP, SV_CXSCREEN)
                       - lTotalWidth ) div {/} 2;
  lcyWindowPos   := ( {(LONG)} WinQuerySysValue(HWND_DESKTOP, SV_CYSCREEN)
                       - lTotalHeight ) div {/} 2;

  // Set the window position.
  WinSetWindowPos (h_wndFrame,
                   HWND_TOP,
                   lcxWindowPos, lcyWindowPos, 0, 0,
                   SWP_MOVE or SWP_SHOW or SWP_ACTIVATE);
end; {CenterWindow}


//........................................................................
function InitializeAppWindow: ERRORSTATUS;
//........................................................................

var
  pbySurface: PBYTE;
  ulWidth: ULONG;
  usLastError: USHORT;

begin
  
  ulDiveBufferNumber := 0;
  bDiveHaveBuffer := FALSE;
  
  // Create your display canvas.  Make it a bottom up canvas for use with DIVE
  if (pcnvMainCanvas <> nil) then begin canvas_Delete; pcnvMainCanvas:=nil; end;
  pcnvMainCanvas := Canvas_New (ulIMAGE_WIDTH,
                                ulIMAGE_HEIGHT,
                                FALSE);
  usLastError := {pcnvMainCanvas->} canvas_QueryLastErrorCode;
  if (usLastError <> 0) then
  begin
    PostError  (h_ab, h_wndFrame, usLastError);
    InitializeAppWindow := ES_ERROR;
  end;
  
  pbySurface := {pcnvMainCanvas->} canvas_QuerySurface;
  ulWidth    := {(ULONG)} {pcnvMainCanvas->} canvas_QueryWidth;
  
  // Associate the canvas with a DIVE h_andle
  if (DiveAllocImageBuffer (h_Dive, ulDiveBufferNumber, FOURCC_LUT8,
                            ulIMAGE_WIDTH, ulIMAGE_HEIGHT,
                            ulWidth,  pbySurface) = ES_ERROR) then
  begin
    // post error message here.
    PostError  (h_ab, h_wndFrame, IDS_ERR_CREATE_DIVEBUFFER);
    InitializeAppWindow := ES_ERROR;
  end;
  
  bDiveHaveBuffer := TRUE;
  
  // Turn on visible region notification.
  WinSetVisibleRegionNotify (h_wndClient, TRUE);
  
  // Send an invalidation message to the client.
  WinPostMsg (h_wndFrame, WM_VRNENABLED, nil, nil );
  
  InitializeAppWindow := ES_NO_ERROR;
end; {InitializeAppWindow}

var
  h_psMainHPS: HPS; // {static}

//........................................................................
// MRESULT EXPENTRY ClientWndProc
function ClientWndProc(h_wnd: cardinal {HWND}; msg: cardinal {ULONG}; mp1,mp2: pointer): pointer; cdecl; export;
//........................................................................

var
  h_ps   : HPS = 0;
  _pointl: POINTL;         // Point to offset from Desktop
  _swp   : SWP;            // Window position
  h_rgn  : HRGN;           // Region h_andle
  rcls   : array [0..50-1] of RECTL; // Rectangle coordinates
  rgnCtl : RGNRECT;        // Processing control structure
  SetupBlitter: TSETUP_BLITTER;      // structure for DiveSetupBlitter
  // h_psMainHPS: HPS; // {static}
  sizl   : SIZEL;
  ulcPaletteColors : ULONG = 256;
  
begin

  case (msg) of
  
  WM_CREATE: begin
       sizl.cx := 0;
       sizl.cy := 0;
       h_dcClientHDC := WinOpenWindowDC (h_wnd);
       h_psMainHPS := GpiCreatePS  (h_ab, h_dcClientHDC, sizl,
                           PU_PELS or GPIF_DEFAULT or GPIT_MICRO or GPIA_ASSOC);

       h_palMain := GpiCreatePalette  (h_ab,
                                    LCOL_PURECOLOR,
                                    LCOLF_CONSECRGB,
                                    ulcPaletteColors,
                                    {(PULONG)} abyVGADefault16Palette);

       GpiSelectPalette (h_psMainHPS, h_palMain);
       WinRealizePalette (h_wnd, h_ps, @ulcPaletteColors);
       
       DiveSetSourcePalette (h_Dive, 0, 256, PBYTE(abyVGADefault16Palette)); // OK
       // DiveSetSourcePalette (h_Dive, 0, 256, @abyVGADefault16Palette); // OK
       
       DiveSetDestinationPalette (h_Dive, 0, 256, nil );
       end;

  WM_DESTROY: begin
       if (h_psMainHPS  <> NULLHANDLE) then
         begin
         GpiSelectPalette (h_psMainHPS, NULLHANDLE);
         end;
       if (h_palMain <> NULLHANDLE) then
         begin
         GpiDeletePalette (h_palMain);
         end;
       if (h_psMainHPS <> NULLHANDLE) then GpiDestroyPS (h_psMainHPS);
       exit;
       end;

  WM_PAINT: begin
       h_ps := WinBeginPaint (h_wnd, NULLHANDLE, nil);

       // blit Dive buffer to screen.
       DiveBlitImage (h_Dive,
                      ulDiveBufferNumber,
                      DIVE_BUFFER_SCREEN );

       WinEndPaint (h_ps);
       // return (0);
       ClientWndProc:=nil;
       exit;
       end;

  WM_COMMAND: begin
       case (SHORT1FROMMP(mp1)) of
         
         IDM_QUIT:
           begin
           WinPostMsg(h_wndClient, WM_CLOSE, nil, nil);
           // return(0);
           ClientWndProc:=nil;
           exit;
           end;
         end; {case SHORT1FROMMP}
       end;

  WM_REALIZEPALETTE: begin
       // This tells DIVE that the physical palette may have changed.
       DiveSetDestinationPalette (h_Dive, 0, 256, nil );
       end;

  WM_VRNDISABLED: begin
       DiveSetupBlitter (h_Dive, nil);
       end;

  WM_VRNENABLED: begin
       if ( h_psMainHPS = 0 ) then
       begin
          // break;
          exit;
       end;
       h_rgn := GpiCreateRegion ( h_psMainHPS, 0, nil );
       if ( h_rgn>0 ) then
       // if not false then
       begin
          // NOTE: If mp1 is zero, then this was just a move message.
          // Illustrate the visible region on a WM_VRNENABLE.
          //
          WinQueryVisibleRegion ( h_wnd, h_rgn );
          rgnCtl.ircStart     := 0;
          rgnCtl.crc          := 50;
          rgnCtl.ulDirection  := 1;

          // Get the all ORed rectangles
          if ( GpiQueryRegionRects ( h_psMainHPS, h_rgn, nil, rgnCtl, rcls[0]) ) then
             begin
             // Now find the window position and size, relative to parent.
             WinQueryWindowPos (h_wndClient, _swp );

             // Convert the point to offset from desktop lower left.
             _pointl.x := _swp.x;
             _pointl.y := _swp.y;
             WinMapWindowPoints ( h_wndFrame, HWND_DESKTOP, _pointl, 1 );

             // Tell DIVE about the new settings.
             SetupBlitter.ulStructLen := sizeof ( TSETUP_BLITTER );
             SetupBlitter.fccSrcColorFormat := FOURCC_LUT8;
             SetupBlitter.ulSrcWidth   := ulIMAGE_WIDTH;
             SetupBlitter.ulSrcHeight  := ulIMAGE_HEIGHT;
             SetupBlitter.ulSrcPosX    := 0;
             SetupBlitter.ulSrcPosY    := 0;
             SetupBlitter.fInvert      := 1; // TRUE;
             SetupBlitter.ulDitherType := 1;

             SetupBlitter.fccDstColorFormat := FOURCC_SCRN;
             SetupBlitter.ulDstWidth        := _swp.cx;
             SetupBlitter.ulDstHeight       := _swp.cy;
             SetupBlitter.lDstPosX          := 0;
             SetupBlitter.lDstPosY          := 0;
             SetupBlitter.lScreenPosX       := _pointl.x;
             SetupBlitter.lScreenPosY       := _pointl.y;
             SetupBlitter.ulNumDstRects     := rgnCtl.crcReturned;
             SetupBlitter.pVisDstRects      := rcls;
             DiveSetupBlitter (h_Dive, @SetupBlitter);
             end
          else
             DiveSetupBlitter (h_Dive, nil);

          GpiDestroyRegion (h_psMainHPS, h_rgn);
          end
       end; {WM_VRNENABLED}

  end; // case switch (msg)

  ClientWndProc := WinDefWindowProc(h_wnd, msg, mp1, mp2);
end; {ClientWndProc}

//........................................................................
// int main
//........................................................................
var
  h_mq: HMQ;
  q_msg: QMSG;
  flFrameFlags: ULONG;

begin
  { some inits }
  fillchar(DiveCaps,sizeof(DiveCaps),0);
  fillchar(fccFormats,sizeof(fccFormats),0);
  
  { go }
  h_ab := WinInitialize (0);
  h_mq := WinCreateMsgQueue (h_ab, 0);
  
  WinRegisterClass (h_ab, szClientClass, @ClientWndProc, CS_SIZEREDRAW, 0);

  if (InitializeDive = NO_ERROR) then
    begin
    // Ready variables for main window creation.
    // WinLoadString  (h_ab, 0, ID_APPMAIN, sizeof(szTitle), szTitle);
    // writeln('[5] WinLoadString done');
    
    flFrameFlags := FCF_TITLEBAR      or FCF_DLGBORDER  or  FCF_MINBUTTON or
                   FCF_SHELLPOSITION or FCF_TASKLIST   or  FCF_ICON      or
                   FCF_SYSMENU       or FCF_MENU;// or FCF_NOBYTEALIGN;

    // Create the main window
    h_wndFrame := WinCreateStdWindow (HWND_DESKTOP, WS_VISIBLE,
                                    @flFrameFlags, szClientClass, szTitle,
                                    0, 0, ID_APPMAIN, @h_wndClient);
    
    if (InitializeAppWindow = ES_ERROR) then
      begin
      WinPostMsg(h_wndClient, WM_QUIT, nil, nil);
      end;
    DrawTestPattern;

    // Size the window here.
    Snap1_1;
    CenterWindow;

    WinShowWindow (h_wndFrame, TRUE);
    WinSetActiveWindow (HWND_DESKTOP, h_wndFrame);

    // Process messages while there are some.
    while (WinGetMsg  (h_ab, q_msg, 0, 0, 0)) do
        WinDispatchMsg  (h_ab, q_msg);
        
    WinSetVisibleRegionNotify (h_wndClient, FALSE);
    end
    else begin
      writeln('InitializeDive <> NO_ERROR');
    end;
    // halt;

  if (bDiveHaveBuffer) then
    begin
    DiveFreeImageBuffer (h_Dive, ulDiveBufferNumber);
    ulDiveBufferNumber := 0;
    bDiveHaveBuffer := FALSE;
    end;

  if (pcnvMainCanvas <> nil) then
    begin
    canvas_Delete; // (pcnvMainCanvas);
    pcnvMainCanvas := nil;
    end;

  if (h_Dive <> NULLHANDLE) then DiveClose (h_Dive);

  WinDestroyWindow (h_wndFrame);

  WinDestroyMsgQueue (h_mq);
  WinTerminate  (h_ab);
  
  halt (0);
end.

