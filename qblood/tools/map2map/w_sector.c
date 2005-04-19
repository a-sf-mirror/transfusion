#include "global.h"

// This finds the extreme points of a sector, and writes the floor and ceiling as rectangles.
void DivAndWrite(FILE *f, const unsigned short SectorNumber, const short Up, const short Down)
{
 long maxX = -5000000, maxY = -5000000, minX =  5000000, minY =  5000000, wallpointer, j, TimeOut = 1000;
 unsigned short i = 0;

 DrawSectorWalls(f, SectorNumber, Down, NORMAL);
// for (i = 0; i < sector[SectorNumber].wallnum; i++)
// AlternateWriteWall(f, sector[SectorNumber].wallptr + i, SectorNumber, Down);
  
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

 // Write floor is the reason for the rectangles
 WriteFloor  (f, numsectors, Down);       // numsectors is the value for temp sector
 WriteCeiling(f, numsectors, Up);
}

// The main sector function. Essentially writes all the sectors
void DrawSector(FILE *f, const unsigned short SectorNumber)
{
 int  j;
 long SectorFloorZ, SectorCeilingZ; 
 short Down = -15, Up = 1, wallpointer, i = 0;

 SectorFloorZ  = sector[SectorNumber].floorz;
 SectorCeilingZ  = sector[SectorNumber].ceilingz;
 j = wallpointer = sector[SectorNumber].wallptr;
  
 for (i = 0; i < sector[SectorNumber].wallnum; i++)
 {
  if (wall[j].nextsector != -1) // Attached to another sector
  {
   if (sector[wall[j].nextsector].floorz - SectorFloorZ < Down)
	   Down = sector[wall[j].nextsector].floorz   - SectorFloorZ; // For steps, etc

   if ((sector[wall[j].nextsector].ceilingz - SectorCeilingZ > Up)
	   && (sector[wall[j].nextsector].ceilingz != sector[wall[j].nextsector].floorz)) 
	   Up = sector[wall[j].nextsector].ceilingz - SectorCeilingZ;

   M_Wall[j] = M_Wall[wall[j].nextwall] = 1;
  }
  j = wall[j].point2;
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