/*
Copyright (C) 2001-2002 BlackB, Some1, Timothy Hale

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#include "global.h"

// Manually finds the number of walls in a sector
long FindWalls(const unsigned short SectorNumber)
{
 int  j;
 unsigned short wallpointer, walls = 1;

 wallpointer = sector[SectorNumber].wallptr;
 j = wall[wallpointer].point2;

 do 
 {
     j = wall[j].point2;
     walls++;

 } while (j != wallpointer);

 
 return walls;
}


// Alternate sector drawing function - why?
void AltDrawSector(FILE *f, const unsigned short SectorNumber)
{
// short Down = -15, Up = 1, wallpointer, count = 0;
 short Down = 0, Up = 0, wallpointer, count = 0;
 int k, SectorFloor, SectorCeiling;
 
 SectorFloor  = sector[SectorNumber].floorz;
 SectorCeiling  = sector[SectorNumber].ceilingz;
 wallpointer = sector[SectorNumber].wallptr;
 //j   = wallpointer;

 
 for (k = 0; k < sector[SectorNumber].wallnum; k++) 
 // Check for steps and windows
 {
     if (wall[wallpointer + k].nextsector != -1) // The wall touches another sector
         {
         if (sector[wall[wallpointer + k].nextsector].floorz - SectorFloor < Down)
             {
                 Down = sector[wall[wallpointer + k].nextsector].floorz - SectorFloor;
             } 
         if (sector[wall[wallpointer + k].nextsector].ceilingz - SectorCeiling > Up)
             {
                 Up = sector[wall[wallpointer + k].nextsector].ceilingz - SectorCeiling;
             }
         M_Wall[wallpointer + k] = M_Wall[wall[wallpointer + k].nextwall] = 1; // For two-sided wall
         }
    
     //j = wall[j].point2;
    count++;

 }
  WriteFloor  (f, SectorNumber, Down); 
  WriteCeiling(f, SectorNumber, Up);
  DrawSectorWalls(f, SectorNumber, Down, NORMAL); // Write the temp sectors walls
 
}

// Draws counting from a starting wall until the wall comes full circle
void DrawBrush(FILE *f, const unsigned short WallNumber, const long SectorFloor, const long SectorCeiling)
{
 TPoint point1, point2;
 char   Texture[256]="";
 long   j = WallNumber;
 
 // Sanity check? Why would this be bad if this was a two sided wall?
 if (wall[WallNumber].nextwall != -1) // Two sided wall
     return;

 point1.x = point2.x = wall[j].x;
 point1.y = point2.y = wall[j].y;
 
/* TWEAKME: Put more dummy textures here and a switch*/
// skip = not drawn because it's never seen by the player
#ifdef QUAKE2
 sprintf(Texture, "e1u1/skip"); // Good for quake 2, but not 1
#elif defined QUAKE1
 sprintf(Texture, "tile0000"); // The good old blood dummy texture
#endif

 fprintf(f, "{\n"); // Start the brush
 fprintf(f, "(%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 
     point1.x, point1.y, SectorFloor, point1.x, point1.y+100, SectorFloor, point2.x+100, point2.y, SectorFloor, Texture); 

 do 
 {
  point1.x = wall[j].x;
  point1.y = wall[j].y;
  point2.x = wall[wall[j].point2].x;
  point2.y = wall[wall[j].point2].y;
  
  sprintf(Texture, TEXTUREPREFIX "tile%.4d", wall[j].picnum);
  fprintf(f, "(%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 
      point1.x, point1.y, 500, point2.x, point2.y, 500, point2.x, point2.y, 0, Texture); // 500?

/* Alternate
  fprintf(f, "(%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 
      point2.x, point2.y, 500, point1.x, point1.y, 500, point1.x, point1.y, 0, Texture); 
*/

  j = wall[j].point2;
 } while (j != WallNumber);


/* TWEAKME: Put more dummy textures here and a switch*/
// skip = not drawn because it's never seen by the player
#ifdef QUAKE2
 strcpy(Texture, "e1u1/skip"); // Good for quake 2, but not 1
#elif defined QUAKE1
 strcpy(Texture, "tile0000"); // The good old blood dummy texture
#endif 

 // End the brush
 fprintf(f, "(%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n",
     0, 0, SectorCeiling, 500, 0, SectorCeiling, 0, 500, SectorCeiling, Texture);
 fprintf(f, "}\n"); 

}

// Writes sectors whose number of walls don't match the listed number of walls
void WriteSector(FILE *f, const unsigned short SectorNumber)
{
 short Sn = FindWall(SectorNumber); // Finds a specific wall within a sector
  
 sector[numsectors] = sector[SectorNumber]; // Storing to the temp sector

 if (Sn != -1) 
 { 
  sector[numsectors].wallptr = Sn; //wall[wallpointer].nextwall;
  AltDrawSector(f, numsectors);    // Writing to the temp sector
  DrawBrush(f, sector[SectorNumber].wallptr, sector[SectorNumber].ceilingz+16, sector[SectorNumber].floorz-16); 
 }

}

