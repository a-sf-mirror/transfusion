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

// This finds the extreme points of a sector, and writes the floor and ceiling as rectangles.
void DivAndWrite(FILE *f, const unsigned short SectorNumber, const short Up, const short Down)
{
 long maxX = -5000000, maxY = -5000000, minX =  5000000, minY =  5000000, wallpointer, j, TimeOut = 1000;
 unsigned short i = 0;

 if (Down < 0)
     //sector[SectorNumber].ceilingz == sector[SectorNumber].floorz && Down != 0)
 {
     for (i = 0; i < sector[SectorNumber].wallnum; i++)
         AlternateWriteWall(f, sector[SectorNumber].wallptr + i, SectorNumber, Down);
     DrawBrush(f, sector[SectorNumber].wallptr, sector[SectorNumber].floorz, 
         sector[SectorNumber].floorz + Down);
     //DrawSectorWalls(f, SectorNumber, Down, ALTERED);
 }

 if (Up > 0)
 {
     for (i = 0; i < sector[SectorNumber].wallnum; i++)
         AlternateWriteWall(f, sector[SectorNumber].wallptr + i, SectorNumber, Up);
     DrawBrush(f, sector[SectorNumber].wallptr, sector[SectorNumber].ceilingz + Up, 
         sector[SectorNumber].ceilingz);
 }

  
 //else 
 DrawSectorWalls(f, SectorNumber, Down, NORMAL);

 // Initialize the temporary sector
 sector[numsectors] = sector[SectorNumber];        // numsectors is the value for temp sector
 sector[numsectors].wallnum = 4;
 sector[numsectors].wallptr = numwalls; // numwalls is the first value (of 4) for temp walls
 
 wallpointer = j = sector[SectorNumber].wallptr;

 do // Gather the extreme points
 {
  if (wall[j].x > maxX) 
      maxX = wall[j].x;

  if (wall[j].y > maxY) 
      maxY = wall[j].y;

  if (wall[j].x < minX) 
      minX = wall[j].x;

  if (wall[j].y < minY) 
      minY = wall[j].y;

  j = wall[j].point2; TimeOut--;

 } while ( (j != wallpointer) && (TimeOut > 0) );
 
// Initialize the values for the temp walls
 wall[numwalls]   = wall[wallpointer];
 wall[numwalls].x = minX;
 wall[numwalls].y = minY;
 wall[numwalls].point2 = numwalls+3;


 wall[numwalls+1]   = wall[wallpointer];
 wall[numwalls+1].x = maxX;
 wall[numwalls+1].y = minY;
 wall[numwalls+1].point2 = numwalls;
 

 wall[numwalls+2]   = wall[wallpointer];
 wall[numwalls+2].x = maxX;
 wall[numwalls+2].y = maxY;
 wall[numwalls+2].point2 = numwalls+1;


 wall[numwalls+3]   = wall[wallpointer];
 wall[numwalls+3].x = minX;
 wall[numwalls+3].y = maxY;
 wall[numwalls+3].point2 = numwalls+2;

   //if (Down == 0)
         WriteFloor  (f, numsectors, Down);
     
   //if (Up == 0)
         WriteCeiling(f, numsectors, Up);
}

// The main sector function. Essentially writes all the sectors
void DrawSector(FILE *f, const unsigned short SectorNumber)
{
 long SectorFloorZ, SectorCeilingZ; 
 short Down = 0, Up = 0, wallpointer, i = 0; // TESTME A LOT!
 //short Down = -15, Up = 1, wallpointer, i = 0;

 SectorFloorZ  = sector[SectorNumber].floorz;
 SectorCeilingZ  = sector[SectorNumber].ceilingz;
 wallpointer = sector[SectorNumber].wallptr;
  
 for (i = 0; i < sector[SectorNumber].wallnum; i++)
 {
  if (wall[wallpointer + i].nextsector  != -1) // Attached to another sector
  {
   if (sector[wall[wallpointer + i].nextsector ].floorz - SectorFloorZ < Down)
	   Down = sector[wall[wallpointer + i].nextsector ].floorz   - SectorFloorZ; // For steps, etc

   if ((sector[wall[wallpointer + i].nextsector ].ceilingz - SectorCeilingZ > Up)
	   && (sector[wall[wallpointer + i].nextsector ].ceilingz != sector[wall[wallpointer + i].nextsector].floorz)) 
	   Up = sector[wall[wallpointer + i].nextsector ].ceilingz - SectorCeilingZ;

   M_Wall[wallpointer + i] = M_Wall[wall[wallpointer + i].nextwall] = 1;
  }
 }  

  if (!TestAngles(SectorNumber))  // Checks if the sector is semi-circular
 {
	 // Validate the number of walls  
	 if (FindWalls(SectorNumber) != sector[SectorNumber].wallnum) 
		WriteSector(f, SectorNumber); // If walls are doing something freaky, use alternate method

        WriteFloor  (f, SectorNumber, Down);
        WriteCeiling(f, SectorNumber, Up);
        DrawSectorWalls(f, SectorNumber, Down, NORMAL);

 // Else, the ceiling & floor will have to be drawn rectangular.
 } else DivAndWrite(f, SectorNumber, Up, Down);        
 
}