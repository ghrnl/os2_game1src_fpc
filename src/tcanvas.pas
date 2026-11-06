unit tcanvas;

{ 2026 port to FPC 3.2.4 G.H. Renkema                                }

interface

type
  SHORT  = integer;
  USHORT = word;
  LONG   = longint;
  ULONG  = longint;
  BOOL   = boolean;

// enum ERRORSTATUS
  {
  ES_NO_ERROR = 0,
  ES_ERROR,
  ES_FATAL_ERROR
  }

type
  ERRORSTATUS = cardinal; // word;
  
const
  ES_NO_ERROR    = 0;
  ES_ERROR       = 1;
  ES_FATAL_ERROR = 2;

{ min and max macros }
//#ifndef max
//#define max(a,b)  (((a) > (b)) ? (a) : (b))
//#endif
//#ifndef min
//#define min(a,b)  (((a) < (b)) ? (a) : (b))
//#endif

{ min and max functions }

function max(a,b: longint): longint;
function min(a,b: longint): longint;

// ***********************************************************************
// CANVAS.HPP
// ***********************************************************************
//
// Written by Michael T. Duffy
//
// Canvas Graphics Object for 256 color modes.
//
// ***********************************************************************

{$IFNDEF CANVAS_HPP}
{$DEFINE CANVAS_HPP}

// ***********************************************************************
//  Error Processing
// ***********************************************************************

const
  ERR_CNV =  100;
  ERR_CNV_CREATE = (ERR_CNV + 1);


// ***********************************************************************
//  Constant Definitions
// ***********************************************************************

// These color definitions are for the first 16 colors in a standard VGA
//  palette.  Later we will move them to our palette module

{$IFNDEF COLOR_DEFS}
{$DEFINE COLOR_DEFS}
const {BYTE}
  BLACK        = 0;
  BLUE         = 1;
  GREEN        = 2;
  CYAN         = 3;
  RED          = 4;
  MAGENTA      = 5;
  BROWN        = 6;
  LIGHTGRAY    = 7;
  DARKGRAY     = 8;
  LIGHTBLUE    = 9;
  LIGHTGREEN   = 10;
  LIGHTCYAN    = 11;
  LIGHTRED     = 12;
  LIGHTMAGENTA = 13;
  YELLOW       = 14;
  WHITE        = 15;
{$ENDIF} // COLOR_DEFS

{$ENDIF} // CANVAS_HPP


procedure canvas_SetDrawColor(byColor: byte);
function canvas_QueryLastErrorCode: USHORT;
function canvas_QuerySurface: PBYTE;
function canvas_QueryWidth: SHORT;

function canvas_New(usWidthIn, usHeightIn: USHORT; bTopDownIn: BOOL): pointer;

procedure canvas_Delete;
procedure canvas_Clear(byColor: byte);
procedure canvas_PutPixel(sXPos,sYPos: SHORT);
procedure canvas_HorizLine(sX1,sX2,sY: SHORT);
procedure canvas_VertLine(sX,sY1,sY2: SHORT);
procedure canvas_Rectangle(sX1,sY1,sX2,sY2: SHORT);
procedure canvas_XORHorizLine(sX1,sX2,sY: SHORT);
procedure canvas_XORVertLine(sX,sY1,sY2: SHORT);
procedure canvas_XORRectangle(sX1,sY1,sX2,sY2: SHORT);

implementation

{ min and max functions }

function max(a,b: longint): longint;
begin
  if a>b then max:=a else max:=b
end;

function min(a,b: longint): longint;
begin
  if a<b then min:=a else min:=b
end;

{$IFDEF CANVAS_HPP}

// ***********************************************************************
//  Class Definitions
// ***********************************************************************

//class Canvas
//  
//  private:
  
var
  // Internal data
  usLastErrorCode: USHORT;
  
  // Canvas structure
  usWidth: USHORT;
  usHeight: USHORT;
  ulSize: ULONG;
  pbySurface: PBYTE;
  // PBYTE *          apbyRowStart;
  apbyRowStart: array of PBYTE; // not byte;
  lRowChange: LONG;
  
  // lDwordWidth: LONG;
  bTopDown: BOOL;

  // Drawing parameters
  byDrawColor: BYTE;

// ***********************************************************************
//  Class Definitions
// ***********************************************************************

{
    USHORT QueryLastErrorCode
      (
      VOID
      ) /return (usLastErrorCode);/;

  // End of Canvas definition
  ;
}

function canvas_QueryLastErrorCode: USHORT;
begin
  canvas_QueryLastErrorCode := usLastErrorCode
end;

// typedef Canvas *   PCANVAS;


// ***********************************************************************
//  Inline Functions
// ***********************************************************************

//........................................................................
// inline VOID Canvas::SetDrawColor
procedure canvas_SetDrawColor(byColor: byte);
//........................................................................
begin
  byDrawColor := byColor
end;

//........................................................................
// inline BYTE Canvas::QueryDrawColor
function canvas_QueryDrawColor: byte;
//........................................................................
begin
  canvas_QueryDrawColor := byDrawColor
end;

//........................................................................
// inline SHORT Canvas::QueryWidth
function canvas_QueryWidth: SHORT;
//........................................................................
begin
  canvas_QueryWidth := usWidth
end;

//........................................................................
// inline SHORT Canvas::QueryHeight
function canvas_QueryHeight: SHORT;
//........................................................................
begin
  canvas_QueryHeight := usHeight
end;

//........................................................................
// inline PBYTE Canvas::QuerySurface
function canvas_QuerySurface: PBYTE;
//........................................................................
begin
  canvas_QuerySurface := pbySurface
end;

//........................................................................
// inline PBYTE Canvas::QueryRowAddress
function canvas_QueryRowAddress(ulIndex: ULONG): PBYTE;
//........................................................................
begin
  canvas_QueryRowAddress := apbyRowStart [ulIndex]
end;

//........................................................................
// inline PBYTE * Canvas::QueryRowAddressArray
function canvas_QueryRowAddressArray: PBYTE;
//........................................................................
begin
  // ??? @apbyRowStart or apbyRowStart[0] ??? but both will compile
  // NOT CALLED
  canvas_QueryRowAddressArray := @apbyRowStart
  // canvas_QueryRowAddressArray := apbyRowStart[0]
end;

//........................................................................
// inline LONG Canvas::QueryRowIncrement
function canvas_QueryRowIncrement: LONG;
//........................................................................
begin
  canvas_QueryRowIncrement := lRowChange
end;

//........................................................................
// inline BOOL Canvas::Validate
function canvas_Validate: boolean;
//........................................................................
begin
  // This routine simply makes sure the canvas exists with valid data
  if ((pbySurface = nil) or
      (usWidth  = 0) or
      (usHeight = 0) or
      (ulSize  = 0)) then
  begin
    canvas_Validate := FALSE
  end
  else
  begin
    canvas_Validate := TRUE
  end;
end; {canvas_Validate}

{$ENDIF} // CANVAS_HPP
{ -----------------------------------------------------------------
                             CANVAS.CPP
     This module is for linear 256 color bitmaps under OS/2.  It is
  designed so that it can handle top-down or bottom-up bitmaps, yet
  still have all canvases approached as if they were top-down.

  Author: Michael T. Duffy
  Date: May 21st, 1995


  Copyright 1995 Michael T. Duffy. All Rights Reserved.

   ----------------------------------------------------------------- }

{ Useage Notes:

   * Canvases accessed with the following routines can be considered to be
      top down bitmaps, bitmaps with the origin in the top left corner.

}

// ***********************************************************************
//  Compile Directives
// ***********************************************************************

// #pragma pack (1);

// ***********************************************************************
//  Header Files
// ***********************************************************************

// Note: The __IBMC__ define is needed to get the Warp Toolkit to work with
//  Watcom compilers.


// OS/2 API functions


// include "newtypes.hpp"
// include "canvas.hpp"

// Note: Inline assembly written for Watcom compilers.
// #define INLINE_ASSEMBLY

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

procedure dbgwriteln1(s: string; n: ULONG);
begin
  // writeln(s,n)
end;

//........................................................................
// Canvas::Canvas aka Constructor
function canvas_New(usWidthIn, usHeightIn: USHORT; bTopDownIn: BOOL): pointer;
//........................................................................

var
  ulCanvasSize: ULONG;
  ulOffset: ULONG;
  lRowSize: LONG; // not U
  ulIndex: ULONG;

begin
  usLastErrorCode := 0;
  
  // Determine canvas size with width taken to the nearest dword.  Knowing that
  //  the width is always on a dword boundary allows us to use dword copies.
  usWidthIn := {(USHORT)} (((usWidthIn + 3) div {/} 4) * 4);
  ulCanvasSize := usWidthIn * usHeightIn;
  
  // Allocate a buffer for the bitmap which we will call the surface
  // pbySurface        := (PBYTE) malloc (ulCanvasSize);
  getmem(pbySurface,ulCanvasSize);
  
  // If you have a buffer (given or allocation was successful)
  if (pbySurface <> nil) then
  begin
    dbgwriteln('getmem [1] OK');
    dbgwriteln1('ulCanvasSize        = ',ulCanvasSize);
    dbgwriteln1('memsize(pbySurface) = ',memsize(pbySurface));
    dbgwriteln1('sizeof(pbySurface)  = ',sizeof(pbySurface));
    // halt; // OK
    // Clear the buffer to 0
    // memset (pbySurface, 0, ulCanvasSize);
    fillchar(pbySurface^, ulCanvasSize, 0);
    dbgwriteln('fillchar [1] OK');
    // halt;
    
    // Allocate memory for a list of row offsets
    setlength(apbyRowStart,usHeightIn);
    if (apbyRowStart <> nil) then
    begin
      dbgwriteln('getmem [2] OK');
      // halt;
      // Calculate row offsets
  
      lRowSize := usWidthIn;

      if (bTopDownIn) then
      begin
        // Top Down: Start the offset list at the beginning of the buffer
        ulOffset := 0;
      end
      else
      begin
        // Bottom Up: Start the offset list at the end of the buffer
        ulOffset :=  lRowSize * (usHeightIn - 1);
        lRowSize := -lRowSize;
      end;

      // loop through all the rows
      // for (ulIndex := 0; ulIndex < usHeightIn; ++ulIndex) do
      for ulIndex := 0 to usHeightIn-1 do
      begin
        // Calculate and store the offset into the buffer of that row.
        apbyRowStart [ulIndex] := pbySurface + ulOffset;
        ulOffset := ulOffset + lRowSize;
      end; {for}

      usWidth  := usWidthIn;
      usHeight := usHeightIn;
      ulSize   := ulCanvasSize;

      // The row change variable is for incrementing from one row to the next.
      //  For top down bitmaps, this value will be positive and adding it to your
      //  current position will move you forward one row int the buffer.  Bottom
      //  up bitmaps have a negative row change, so adding it will move you back
      //  in the buffer.
      lRowChange := usWidthIn;

      bTopDown := bTopDownIn;
      if (not bTopDown) then
      begin
        lRowChange := -lRowChange;
      end;
    end
    else
    begin
      dbgwriteln('getmem [2] NOT OK');
      // Error in allocating memory for row list.
      // Deallocate surface
      freemem (pbySurface);

      pbySurface := PBYTE(nil);
      usWidth  := 0;
      usHeight := 0;

      usLastErrorCode := ERR_CNV_CREATE;
      canvas_New := nil;
      exit; // return;
    end;
  end
  else
  begin
    usLastErrorCode := ERR_CNV_CREATE;
    canvas_New := nil;
    exit; // return;
  end;

  // The dword (32 bit word) value will be of use later, so we calculate it now.
  // lDwordWidth    := abs (lRowChange div {/} 4);
  
  canvas_New := pbySurface
end; {canvas_New}

//........................................................................
// Canvas::~Canvas aka Destructor
procedure canvas_Delete;
//........................................................................

begin
  // Release the memory used for
  // freemem (apbyRowStart);
  
  // Release the memory for the canvas if the canvas object allocated it.
  if (pbySurface <> nil) then
  begin
    freemem (pbySurface);
  end;
end; {canvas_Delete}

// Inline assembly for the Watcom compiler.  This is faster than a memset
//  because of less overhead and 32-bit copies.  This is possible because
//  canvases are allocated so that the row size always evenly divides into
//  dwords.
{
#ifdef INLINE_ASSEMBLY

VOID CnvMemSet (PBYTE pbyDest, BYTE VALUE, ULONG ulNumOfBytes);

  #pragma aux CnvMemSet := \
    "and  ebx,0x000000ff", \
    "mov  bh,bl", \
    "mov  eax,ebx", \
    "shl  ebx,16", \
    "or   eax,ebx", \
    "shr  ecx,2", \
    "rep  stosd", \
    MODIFY [eax] \
    PARM [edi][ebx][ecx] ;

#endif
}

//........................................................................
// VOID Canvas::Clear
procedure canvas_Clear(byColor: byte);
//........................................................................

begin
  // Make sure the canvas has a surface.
  if (pbySurface <>nil) then
  begin
    {$IFDEF INLINE_ASSEMBLY}
    CnvMemSet(pbySurface, byColor, ulSize);
    {$ELSE}
    // memset (pbySurface, byColor, ulSize);
    fillchar(pbySurface^, ulSize, byColor);
    {$ENDIF}
  end;
end; {canvas_Clear}

//........................................................................
// VOID Canvas::PutPixel
procedure canvas_PutPixel(sXPos,sYPos: SHORT);
//........................................................................

var
  pbyTarget: PBYTE;
  
begin
  // bounds checking
  if ((sXPos < 0) or (sYPos >= usWidth)) then exit; //  return;
  if ((sYPos < 0) or (sYPos >= usHeight)) then exit; // return;
  
  // Calculate the pixel's location in the buffer
  pbyTarget := apbyRowStart [sYPos] + sXPos;
  
  // Write the pixel
  pbyTarget^ := byDrawColor; // remove ^ ??? NO
end; {canvas_PutPixel}


//........................................................................
// VOID Canvas::HorizLine
procedure canvas_HorizLine(sX1,sX2,sY: SHORT);
//........................................................................

var
  sOrderedX1: SHORT;
  sOrderedX2: SHORT;
  sLength   : SHORT;
  pbyTarget : PBYTE;

begin
  // Make sure X1 is to the left
  if (sX1 < sX2) then
  begin
    sOrderedX1 := sX1;
    sOrderedX2 := sX2;
  end
  else
  begin
    sOrderedX1 := sX2;
    sOrderedX2 := sX1;
  end;
  
  // Perform clipping
  sOrderedX1 := max (sOrderedX1, 0);
  sOrderedX2 := min (sOrderedX2, (usWidth - 1));
  if ((sY < 0) or (sY >= usHeight)) then exit; // return;
  
  // Calculate range and starting address
  sLength :=  (sOrderedX2 - sOrderedX1 + 1);
  pbyTarget := apbyRowStart [sY] + sOrderedX1;
  
  // memset (pbyTarget, byDrawColor, sLength);
  fillchar(pbyTarget^, sLength, byDrawColor);
end; {canvas_HorizLine}

//........................................................................
// VOID Canvas::VertLine
procedure canvas_VertLine(sX,sY1,sY2: SHORT);
//........................................................................

var
  sOrderedY1: SHORT;
  sOrderedY2: SHORT;
  sLength: SHORT;
  ulIndex: ULONG;
  pbyTarget: PBYTE;
  lRowIncrement: LONG;

begin
  // Make sure Y1 is to the top
  if (sY1 < sY2) then
  begin
    sOrderedY1 := sY1;
    sOrderedY2 := sY2;
  end
  else
  begin
   sOrderedY1 := sY2;
   sOrderedY2 := sY1;
  end;
  
  // Perform clipping
  sOrderedY1 := max (sOrderedY1, 0);
  sOrderedY2 := min (sOrderedY2, (usHeight - 1));
  if ((sX < 0) or (sX >= usWidth)) then exit; // return;
  
  // Calculate range and starting address
  sLength :=  (sOrderedY2 - sOrderedY1 + 1);
  pbyTarget := apbyRowStart [sOrderedY1] + sX;
  
  // Store lRowChange locally on the stack (as opposed to accessed with the
  //  "this" pointer)
  lRowIncrement := lRowChange;
  
  // for (ulIndex := 0; ulIndex < sLength; ++ulIndex) do
  for ulIndex := 0 to sLength-1 do
  begin
    pbyTarget^ := byDrawColor;
    pbyTarget := pbyTarget + lRowIncrement;
  end;
end; {canvas_VertLine}

//........................................................................
// VOID Canvas::Rectangle
procedure canvas_Rectangle(sX1,sY1,sX2,sY2: SHORT);
//........................................................................

begin
  // Check for minimum Rectangle size (2x2)
  if ((sX1 = sX2) or (sY1 = sY2)) then
  begin
    exit; // return;
  end;
  
  canvas_HorizLine (sX1, sX2, sY1);
  canvas_HorizLine (sX1, sX2, sY2);
  
  canvas_VertLine (sX1, (sY1 + 1), (sY2 - 1));
  canvas_VertLine (sX2, (sY1 + 1), (sY2 - 1));
end; {canvas_Rectangle}

//........................................................................
// VOID Canvas::XORHorizLine
procedure canvas_XORHorizLine(sX1,sX2,sY: SHORT);
//........................................................................

var
  sOrderedX1: SHORT;
  sOrderedX2: SHORT;
  sLength: SHORT;
  pbyTarget: PBYTE;
  ulIndex: ULONG;

begin
  // Make sure X1 is to the left
  if (sX1 < sX2) then
  begin
    sOrderedX1 := sX1;
    sOrderedX2 := sX2;
  end
  else
  begin
    sOrderedX1 := sX2;
    sOrderedX2 := sX1;
  end;
  
  // Perform clipping
  sOrderedX1 := max (sOrderedX1, 0);
  sOrderedX2 := min (sOrderedX2, (usWidth - 1));
  if ((sY < 0) or (sY >= usHeight) or (sOrderedX1 >= usWidth) or (sOrderedX2 < 0)) then exit; // return;
  
  sLength := (sOrderedX2 - sOrderedX1 + 1);
  pbyTarget := apbyRowStart [sY] + sOrderedX1;
  
  // for (ulIndex := 0; ulIndex < sLength; ++ulIndex) do
  for ulIndex := 0 to sLength-1 do
  begin
    pbyTarget^ := byDrawColor;
    pbyTarget := pbyTarget+1;
  end;
end; {canvas_XORHorizLine}

//........................................................................
// VOID Canvas::XORVertLine
procedure canvas_XORVertLine(sX,sY1,sY2: SHORT);
//........................................................................

var
  sOrderedY1: SHORT;
  sOrderedY2: SHORT;
  sLength: SHORT;
  ulIndex: ULONG;
  pbyTarget: PBYTE;
  lRowIncrement: LONG;

begin
  // Make sure Y1 is to the left
  if (sY1 < sY2) then
  begin
    sOrderedY1 := sY1;
    sOrderedY2 := sY2;
  end
  else
  begin
    sOrderedY1 := sY2;
    sOrderedY2 := sY1;
  end;
  
  // Perform clipping
  sOrderedY1 := max (sOrderedY1, 0);
  sOrderedY2 := min (sOrderedY2, (usHeight - 1));
  if ((sX < 0) or (sX >= usWidth) or (sOrderedY1 >= usHeight) or (sOrderedY2 < 0)) then exit; // return;
  
  sLength :=  (sOrderedY2 - sOrderedY1 + 1);
  pbyTarget := apbyRowStart [sOrderedY1] + sX;
  lRowIncrement := lRowChange;
  // for (ulIndex := 0; ulIndex < sLength; ++ulIndex) do
  for ulIndex := 0 to sLength-1 do
  begin
    pbyTarget^ := byDrawColor;
    pbyTarget := pbyTarget + lRowIncrement;
  end;
end; {canvas_XORVertLine}

//........................................................................
// VOID Canvas::XORRectangle
procedure canvas_XORRectangle(sX1,sY1,sX2,sY2: SHORT);
//........................................................................

begin
  // Check for minimum Rectangle size (2x2)
  if ((sX1 = sX2) or (sY1 = sY2)) then
  begin
    exit; // return;
  end;
  
  canvas_XORHorizLine (sX1, sX2, sY1);
  canvas_XORHorizLine (sX1, sX2, sY2);
  
  canvas_XORVertLine (sX1, (sY1 + 1), (sY2 - 1));
  canvas_XORVertLine (sX2, (sY1 + 1), (sY2 - 1));
end; {canvas_XORRectangle}


end.

