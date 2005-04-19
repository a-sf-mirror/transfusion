#include "global.h"

// What is this for? 
short G_2va(long x1, long y1, long x2, long y2, long *x, long *y)
{
 double x_1, y_1, x_2, y_2, vertex1x, vertex1y, vertex2x, vertex2y, k, sinq;

 vertex1x = x2 - x1;
 vertex1y = y2 - y1;

 if (vertex1x == 0) // Horizontal line
	 vertex1x = 1;

 y_1 = 0.5/(vertex1y * vertex1y + vertex1x * vertex1x) *
     (2.0 * y1 * vertex1x * vertex1x + 2.0 * vertex1y * vertex1y * y1 + 200.0 *
     sqrt(vertex1y * vertex1y * vertex1x * vertex1x + vertex1x * vertex1x * vertex1x * vertex1x));

 x_1 = (vertex1x * x1 - vertex1y * y_1 + vertex1y * y1) / vertex1x;

 y_2 = 0.5/(vertex1y * vertex1y + vertex1x * vertex1x) *
     (2.0 * y1 * vertex1x * vertex1x + 2.0 * vertex1y * vertex1y * y1-200.0 *
     sqrt(vertex1y * vertex1y * vertex1x * vertex1x + vertex1x * vertex1x * vertex1x * vertex1x));

 x_2 = (vertex1x * x1 - vertex1y * y_2 + vertex1y * y1) / vertex1x;

 vertex2x  = x_1 - x1;
 vertex2y  = y_1 - y1;                    
 k = vertex1x * vertex2y - vertex1y * vertex2x;

              // Pythagorean theorem 
 sinq = k / (sqrt(vertex1x * vertex1x + vertex1y * vertex1y) * 
             sqrt(vertex2x * vertex2x + vertex2y * vertex2y));

 if (sinq == -1)
 {
  *x = x_1;
  *y = y_1; 
 } else
 {
  *x = x_2;
  *y = y_2; 
 }

 if (vertex1x == 0) 
	 return 1; 
 
 else return 0;
}

// Gets the Z for a sloped floor. Use it to fix nearby walls
long GetZ(double point1x, double point1y, double point3x, double point3y, double Z, double angle)
{
 long h = tan(angle) * sqrt((point3x - point1x) * (point3x - point1x) + 
                            (point3y - point1y) * (point3y - point1y));
 return Z + h; 
}

// This will test how complicated a sector is (i.e. "fakey curves")
short TestAngles(const unsigned short SectorNumber)
{
 double TotalAngle, TestAngle, radian;
 TPoint vertex1, vertex2;
 long walls = 0, j, wallpointer;
 short TimeOut = 1000;
 
 j = wallpointer = sector[SectorNumber].wallptr;
   
 do 
 {
  j = wall[j].point2;
  walls++; TimeOut--; // Manually get the number of walls
 } while ( (j != wallpointer) && (TimeOut > 0) );

 if (walls < 3) // You're not going to have complicated angles with 2 walls.
     return 0;

 TotalAngle = 180 * (walls-2);
 TestAngle = 0;
 j = wallpointer = sector[SectorNumber].wallptr;
 TimeOut = 1000;

 do 
 {
  vertex1.x = wall[j].x - wall[wall[j].point2].x; // X Line 1 length 
  vertex1.y = wall[j].y - wall[wall[j].point2].y; // Y Line 1 length
  vertex2.x = wall[wall[wall[j].point2].point2].x - wall[wall[j].point2].x; // X Line 2 length 
  vertex2.y = wall[wall[wall[j].point2].point2].y - wall[wall[j].point2].y; // Y Line 2 length

  // There has got to be a smarter way to do this
  radian = acos((vertex1.x * vertex2.x + vertex1.y * vertex2.y) / 
      ((sqrt(vertex1.x * vertex1.x + vertex1.y * vertex1.y) * // Hypotenuse
      sqrt(vertex2.x * vertex2.x + vertex2.y * vertex2.y)))); // Hypotenuse
  
  TestAngle += radian;
  
  j = wall[j].point2; TimeOut--;
 } while ( (j != wallpointer) && (TimeOut > 0) );
 
 TestAngle = TestAngle * 180 / PI;

 if ((TotalAngle - TestAngle > -1) && (TotalAngle - TestAngle < 1)) 
     return 0;
 
 
 else 
 {
#ifdef _DEBUG
     FILE * log;
     log = fopen("log.txt", "a");
     fprintf(log, "magic number = %7g    number of walls = %d\n", 
             TotalAngle - TestAngle, sector[SectorNumber].wallnum);
     fclose(log);
#endif
     return 1;
 }

}

// Writes a sectors floor
void WriteFloor(FILE *f, const unsigned short SectorNumber, const long Plus)
{
 char Texture[40];
 long SBot, STop, j, wallpointer; 
 TPoint point1, point2, vertex1, vertex2, vertex3;
 short ret, Stat, PreviousSector, NextSector;
 double Angle;

 fprintf(f, "{\n");
 Stat = sector[SectorNumber].floorstat;

 if (Plus < 0)
 {  
  SBot = sector[SectorNumber].floorz +Plus; // Floor going down
  STop = sector[SectorNumber].floorz;
 }
 else// Plus >= 0
 {
  STop = sector[SectorNumber].floorz +Plus; // Floor going up - step?
  SBot = sector[SectorNumber].floorz;
 }

 wallpointer = sector[SectorNumber].wallptr;
 j   = wallpointer; 

 point1.x = point2.x = wall[j].x;
 point1.y = point2.y = wall[j].y;
 point1.zt = STop;

 /* Disabled: floors aren't paralaxxed
 if (Stat % 2 == 1) // this indicates paralaxxing 
 sprintf(Texture, "sky1 0 0 0 1.00 1.00 0 133 1"); // Why 133?
 else 
 */
 sprintf(Texture, "tile%.4d 0 0 0 1.00 1.00 1 0 0", sector[SectorNumber].floorpicnum);

 if (sector[SectorNumber].floorheinum != 0) // Sloped floor
 {
 vertex1.x  = wall[j].x;
 vertex1.y  = wall[j].y;
 vertex2.x  = wall[wall[j].point2].x;
 vertex2.y  = wall[wall[j].point2].y;
 vertex1.zt = vertex1.zb = vertex2.zt = vertex2.zb = STop;
   
 ret = G_2va(vertex1.x, vertex1.y, vertex2.x, vertex2.y, &vertex3.x, &vertex3.y);

 vertex3.zt = vertex3.zb = STop;
  
 if (sector[SectorNumber].floorheinum < 0) // Slope
    Angle = (-1 * (sector[SectorNumber].floorheinum-512)) * PI/4/4096;
 
 else Angle = (-1 * (sector[SectorNumber].floorheinum+512)) * PI/4/4096;

 /* This should be tested...
  NextSector = wall[sector[SectorNumber].wallptr].nextsector;
  PreviousSector = FindSector(SectorNumber);

  if (NextSector != -1 && PreviousSector != -1 && sector[NextSector].floorheinum == 0)
  vertex3.zt = 
  abs (sector[NextSector].floorz - sector[PreviousSector].floorz) + sector[PreviousSector].floorz;
  
  else */
  vertex3.zt = GetZ(vertex1.x, vertex1.y, vertex3.x, vertex3.y, STop, Angle);

  vertex3.zb = vertex3.zt-10;

 if (ret == 0)
 fprintf(f, "(%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1.00 1.00 1 0 0\n", 
              vertex1.x, vertex1.y, vertex1.zt,
              vertex2.x, vertex2.y, vertex2.zt, 
              vertex3.x, vertex3.y, vertex3.zt, Texture);
 else
 fprintf(f, "( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 
               0, 0, STop, 0, 500, STop, 500, 0, STop, Texture); // Why 0 and 500?
 
 } // if (sector[SectorNumber].floorheinum != 0) 
 
 else // No slope
 fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 
                 0, 0, STop, 0, 500, STop, 500, 0, STop, Texture); // Why 0 and 500?
 
 do 
 {
  point1.x = wall[j].x;
  point1.y = wall[j].y;
  point2.x = wall[wall[j].point2].x;
  point2.y = wall[wall[j].point2].y;

  if (wall[j].nextwall != -1) 
      sprintf(Texture, "tile%.4d", wall[wall[j].nextwall].picnum);
     
  else sprintf(Texture, "tile%.4d", wall[j].picnum);

  if (Stat % 2 == 1) // Parallaxxing, highly unlikely for a floor
        fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) e1u2/sky1 0 0 0 1.00 1.00 0 133 1\n", 
          point2.x, point2.y, 500, point1.x, point1.y, 500, point1.x, point1.y, 0, Texture);  
  
  // Why 0 and 500?
  else 
  fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s 0 0 0 1.00 1.00 1 0 0\n", 
          point2.x, point2.y, 500, point1.x, point1.y, 500, point1.x, point1.y, 0, Texture);
  
  j = wall[j].point2;
 } while (j != wallpointer);


/* TWEAKME: Put more dummy textures here and a switch*/
// skip = not drawn because it's never seen by the player
#ifdef QUAKE2
 sprintf(Texture, "e1u1/skip"); // Good for quake 2, but not 1
#elif defined QUAKE1
 sprintf(Texture, "tile%.4d", sector[SectorNumber].floorpicnum);
#endif

 if (sector[SectorNumber].floorheinum != 0) 
 {
  point2.zb = STop - 100 * tan( (-1 * sector[SectorNumber].floorheinum) * PI / 4 / 4096) + 5;  
  
 vertex1.x  = wall[j].x;
 vertex1.y  = wall[j].y;
 vertex2.x  = wall[wall[j].point2].x;
 vertex2.y  = wall[wall[j].point2].y;
 vertex1.zt = vertex2.zt = STop;
 vertex1.zb = vertex2.zb = SBot;

 ret = G_2va(vertex1.x, vertex1.y, vertex2.x, vertex2.y, &vertex3.x, &vertex3.y);
 vertex3.zt = STop;
 vertex3.zb = SBot;

 vertex3.zt = GetZ(vertex1.x, vertex1.y, vertex3.x, vertex3.y, STop, (-1 * sector[SectorNumber].floorheinum) * PI/4/4096);
 vertex3.zb = vertex3.zt-10;

 if (vertex3.zb > SBot) 
     vertex3.zb = SBot;

 if (point2.zb > SBot) 
     point2.zb = SBot;

 if (ret == 0)
 fprintf(f, "(%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1.00 1.00 1 0 0\n", 
 vertex1.x, vertex1.y, vertex1.zb, vertex3.x, vertex3.y, vertex3.zb, vertex2.x, vertex2.y, 
 vertex2.zb, Texture);
 
 else // Why 0 and 500?
 fprintf(f, "( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s 0 0 0 1.00 1.00 1 0 0\n", 
 0, 0, SBot, 500, 0, SBot, 0, 500, SBot, Texture); 
 
 } // if (sector[SectorNumber].floorheinum != 0)
 else
 fprintf(f, "( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s 0 0 0 1.00 1.00 1 0 0\n", 
 0, 0, SBot, 500, 0, SBot, 0, 500, SBot, Texture); 

 fprintf(f, "}\n");
}


// Finds a specific wall within a sector
long FindWall(const long SectorNumber)
{
 short i, j, r, wallpointer;
 
 // The first wall in the sector to be searched
 wallpointer = sector[SectorNumber].wallptr;

 for (i = 0; i < numwalls; i++)
 {
     // Searching for a wall in a neighboring sector?
  if (wall[wall[i].nextwall].nextsector == SectorNumber) // The neighbor sector
  {
   r = 0;
   
   j = wallpointer; 
   
   // Search "SectorNumber" for the wall "i"
   do       
   {
	 if (i == j) 
         r = 1;

    j = wall[j].point2;

   } while (j != wallpointer);
   
   if (r == 0)
       return i;
  }//if
 }//for
 return -1; // Not found
}

// Locates the sector before the current sector for proper sloping 
short FindSector(const unsigned short SectorNumber)
{
    unsigned short i = 0, j = 0;

    for (i = 0; i < numsectors; i++)
    {
        for (j = 0; j < sector[i].wallnum; j++)
            if (wall[sector[i].wallptr + j].nextsector == SectorNumber)
                return i; // Sector found!
    }

    return -1; // Sector not found
}

