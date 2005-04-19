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

// This will test how complicated a sector is
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

 if (walls > 18) // Anything above this is going to look crazy
     return 1; // TESTME


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
     return 1;
}

// Writes a sectors floor
void WriteFloor(FILE *f, const unsigned short SectorNumber, const long Plus)
{
 char Texture[40];
 long SectorBottom, SectorTop, j, wallpointer; 
 TPoint point1, point2, vertex1, vertex2, vertex3;
 short ret, Stat, k;

 Stat = sector[SectorNumber].floorstat;

 if (Plus < 0)
 {  
  SectorBottom = sector[SectorNumber].floorz +Plus; // Floor going down
  SectorTop = sector[SectorNumber].floorz;
 }
 else// Plus >= 0
 {
  SectorTop = sector[SectorNumber].floorz +Plus; // Floor going up - steps, small objects, etc
  SectorBottom = sector[SectorNumber].floorz;
 }

// SectorTop = SectorBottom;
// SectorBottom -= THICK;

 // Sanity checks...
 if (SectorTop > sector[SectorNumber].ceilingz)
     SectorTop = sector[SectorNumber].ceilingz - THICK;
 
 if (SectorTop < SectorBottom)
     SWAP (SectorTop, SectorBottom);

 if (SectorTop == SectorBottom)
     SectorBottom -= THICK;

 j = wallpointer = sector[SectorNumber].wallptr;
 
 point1.x = point2.x = wall[j].x;
 point1.y = point2.y = wall[j].y;
 point1.zt = SectorTop;
 
 sprintf(Texture, "tile%.4d 0 0 0 1.00 1.00 1 0 0", sector[SectorNumber].floorpicnum);
 
 fprintf(f, "{\n");

 // This chunk starts the floor drawing, it draws the top of the floor
 if (sector[SectorNumber].floorheinum != 0) // Sloped floor
 {
 vertex1.x  = wall[j].x;
 vertex1.y  = wall[j].y;
 vertex2.x  = wall[wall[j].point2].x;
 vertex2.y  = wall[wall[j].point2].y;
 vertex1.zt = vertex1.zb = vertex2.zt = vertex2.zb = vertex3.zt = vertex3.zb = SectorTop;
   
 ret = G_2va(vertex1.x, vertex1.y, vertex2.x, vertex2.y, &vertex3.x, &vertex3.y);

     vertex3.zt = SectorTop + (sector[SectorNumber].floorheinum / -41) -1;
     vertex3.zb = vertex3.zt-10;
     
     if (SectorBottom > vertex3.zb)
         SectorBottom = vertex3.zb -10;

 if (ret == 0)
 fprintf(f, "(%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1.00 1.00 1 0 0\n", 
              vertex1.x, vertex1.y, vertex1.zt,
              vertex2.x, vertex2.y, vertex2.zt, 
              vertex3.x, vertex3.y, vertex3.zt, Texture); // Line 1
 
 else // ret == 1
 fprintf(f, "( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 
               0, 0, SectorTop, 0, 500, SectorTop, 500, 0, SectorTop, Texture); //Line 1
 
 } // if (sector[SectorNumber].floorheinum != 0) 
 
 else // No slope
 fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 
                 0, 0, SectorTop, 0, 500, SectorTop, 500, 0, SectorTop, Texture); //Line 1
 
 // Write all the floors sides
 for (k = 0; k < sector[SectorNumber].wallnum; k++)
 {
  point1.x = wall[j].x;
  point1.y = wall[j].y;
  point2.x = wall[wall[j].point2].x;
  point2.y = wall[wall[j].point2].y;

  if (wall[j].nextwall != -1) 
      sprintf(Texture, TEXTUREPREFIX "tile%.4d", wall[wall[j].nextwall].picnum);
     
  else sprintf(Texture, TEXTUREPREFIX "tile%.4d", wall[j].picnum);

  if (Stat % 2 == 1) // Parallaxxing, highly unlikely for a floor
        fprintf(f, "( %d %d %d ) ( %d %d %d ) ( %d %d %d ) e1u2/sky1 0 0 0 1.00 1.00 0 133 1\n", 
          point2.x, point2.y, 500, point1.x, point1.y, 500, point1.x, point1.y, 0, Texture);   
  
  else
  fprintf(f, "( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s 0 0 0 1.00 1.00 1 0 0\n", 
          point2.x, point2.y, 500, point1.x, point1.y, 500, point1.x, point1.y, 0, Texture);
  
  j = wall[j].point2;
 }

/* TWEAKME: Put more dummy textures here and a switch*/
// skip = not drawn because it's never seen by the player
#ifdef QUAKE2
 sprintf(Texture, "e1u1/skip"); // Good for quake 2, but not 1
#elif defined QUAKE1
 sprintf(Texture, TEXTUREPREFIX "tile%.4d", sector[SectorNumber].floorpicnum);
#endif

 // This chunk ends the floor drawing, it draws the bottom of the floor
 if (sector[SectorNumber].floorheinum != 0) 
 {
  point2.zb = SectorTop - 100 * tan( (-1 * sector[SectorNumber].floorheinum) * PI / 4 / 4096) + 5;  
  
 vertex1.x  = wall[j].x;
 vertex1.y  = wall[j].y;
 vertex2.x  = wall[wall[j].point2].x;
 vertex2.y  = wall[wall[j].point2].y;
 vertex1.zt = vertex2.zt = vertex3.zt = SectorTop;
 vertex1.zb = vertex2.zb = vertex3.zb = SectorBottom;

 ret = G_2va(vertex1.x, vertex1.y, vertex2.x, vertex2.y, &vertex3.x, &vertex3.y);
 
 vertex3.zb = vertex3.zt-10;

 if (vertex3.zb > SectorBottom) 
     vertex3.zb = SectorBottom;

 if (point2.zb > SectorBottom) 
     point2.zb = SectorBottom;

 if (ret == 0)
 fprintf(f, "(%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1.00 1.00 1 0 0\n", 
 vertex1.x, vertex1.y, vertex1.zb, vertex3.x, vertex3.y, vertex3.zb, vertex2.x, vertex2.y, 
 vertex2.zb, Texture); // Last line
 
 else // Last line
 fprintf(f, "( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s 0 0 0 1.00 1.00 1 0 0\n", 
 0, 0, SectorBottom, 500, 0, SectorBottom, 0, 500, SectorBottom, Texture); 
 
 } // if
 
 else // Last line, no slope
 fprintf(f, "( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s 0 0 0 1.00 1.00 1 0 0\n", 
 0, 0, SectorBottom, 500, 0, SectorBottom, 0, 500, SectorBottom, Texture); 

 fprintf(f, "}\n");
}


// Finds a wall whose nextsector = SectorNumber
short FindWall(const unsigned short SectorNumber)
{
 short i, j, r, wallpointer;
 
 // The first wall in the sector to be searched
 wallpointer = sector[SectorNumber].wallptr;

 for (i = 0; i < numwalls; i++)
 {
     // Searching for a wall in a neighboring sector
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

   } while (j != wallpointer && r != 1);
   
   if (r == 0)
       return i; // Return the index to the wall if the wall is not in the sector searched
  
  }// if
 }// for
 return -1; // Not found
}