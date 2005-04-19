#include "global.h"

// Write a sector's ceiling
void WriteCeiling(FILE *f, const long SectorNumber, const long Plus)
{
 char Texture[256]="";
 
 long CeilingBottom, CeilingTop, j, wallpointer; 
 TPoint point1, point2, vertex1, vertex2, vertex3;
 short ret;

 short Stat = sector[SectorNumber].ceilingstat;
 
 // To avoid compiler gripes, initializing vertex3
 vertex3.x = vertex3.y = vertex3.zb = vertex3.zt = 0;

 CeilingBottom = sector[SectorNumber].ceilingz;
 CeilingTop = sector[SectorNumber].ceilingz +Plus;

 j = wallpointer = sector[SectorNumber].wallptr;
 
 point1.x = point2.x = wall[j].x;
 point1.y = point2.y = wall[j].y;
 point1.zt = CeilingTop;
   
 fprintf(f, "{\n");

    if (Stat % 2 == 1) // This indicates paralaxxing
    {

/* TWEAKME: Put more dummy textures here and a switch*/
// skip = not drawn because it's never seen by the player
#ifdef QUAKE2
 sprintf(Texture, "e1u1/skip 0 0 0 1.00 1.00 1 0 0");
#elif defined QUAKE1
sprintf(Texture, TEXTUREPREFIX "sky1 0 0 0 1.00 1.00 1 0 0"); 
#endif
    }

    else
        sprintf(Texture, "tile%.4d 0 0 0 1.00 1.00 1 0 0", sector[SectorNumber].ceilingpicnum); 
     

    // This chunk starts the ceiling drawing, it draws ???
 if (sector[SectorNumber].ceilingheinum != 0) // Slope
 {
  vertex1.x  = wall[j].x;
  vertex1.y  = wall[j].y;
  vertex2.x  = wall[wall[j].point2].x;
  vertex2.y  = wall[wall[j].point2].y;
  vertex1.zt = vertex1.zb = vertex2.zt = vertex2.zb = CeilingTop;

  ret = G_2va(vertex1.x, vertex1.y, vertex2.x, vertex2.y, &vertex3.x, &vertex3.y); // vertex3 is getting worked on
  vertex3.zt = vertex3.zb = CeilingTop;
  
  vertex3.zt = CeilingTop - (sector[SectorNumber].ceilingheinum / 41) + 1;
     // GetZ(vertex1.x, vertex1.y, vertex3.x, vertex3.y, CeilingTop, (-1 * sector[SectorNumber].ceilingheinum) * PI/4/4096);
      
  vertex3.zb = vertex3.zt-10;

  if (vertex3.zt < CeilingTop) 
      vertex3.zt = CeilingTop;

  if (ret == 0)
   fprintf(f, "(%d %d %d) (%d %d %d) (%d %d %d) %s\n", 
               vertex1.x, vertex1.y, vertex1.zt, 
               vertex2.x, vertex2.y, vertex2.zt, 
               vertex3.x, vertex3.y, vertex3.zt, Texture); 
 
  else // ret == 1
   fprintf(f, "( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 
               0, 0, CeilingTop, 0, 500, CeilingTop, 500, 0, CeilingTop, Texture); 

 } else // No slope
   fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 
                   0, 0, CeilingTop, 0, 500, CeilingTop, 500, 0, CeilingTop, Texture); 

 do // Write all the ceilings sides
 {
  point1.x = wall[j].x;
  point1.y = wall[j].y;
  point2.x = wall[wall[j].point2].x;
  point2.y = wall[wall[j].point2].y;
  
  if (wall[j].nextwall != -1) // If there's another wall connected
      sprintf(Texture, TEXTUREPREFIX "tile%.4d", wall[wall[j].nextwall].picnum);
  else // No conecting wall
      sprintf(Texture, TEXTUREPREFIX "tile%.4d", wall[j].picnum);

 if (Stat % 2 == 1) // This indicates paralaxxing
  fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) sky1 0 0 0 1.00 1.00 0 133 1\n", 
  point2.x, point2.y, 500, point1.x, point1.y, 500, point1.x, point1.y, 0); // Why 133?
 
 else
  fprintf(f, "( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s 0 0 0 1 1 1 0 0\n", 
  point2.x, point2.y, 500, point1.x, point1.y, 500, point1.x, point1.y, 0, Texture); 

  j = wall[j].point2;
 } while (j != wallpointer);

 Texture[0] = '\0';
 
 if (Stat % 2 == 1) // This indicates paralaxxing
	 sprintf(Texture, TEXTUREPREFIX "sky1 0 0 0 1.00 1.00 0 133 1");

 else sprintf(Texture, TEXTUREPREFIX "tile%.4d 0 0 0 0.50 0.50 1 0 0", sector[SectorNumber].ceilingpicnum);
 
 // This chunk ends the ceiling drawing, it draws ???
 if (sector[SectorNumber].ceilingheinum != 0) // Slope
 {
  vertex1.x  = wall[j].x;
  vertex1.y  = wall[j].y;
  vertex1.zt = CeilingTop;
  vertex1.zb = CeilingBottom;
  vertex2.x  = wall[wall[j].point2].x;
  vertex2.y  = wall[wall[j].point2].y;
  vertex2.zt = CeilingTop;
  vertex2.zb = CeilingBottom;
  ret = G_2va(vertex1.x, vertex1.y, vertex2.x, vertex2.y, &vertex3.x, &vertex3.y); // vertex3 is getting worked on
  vertex3.zt = CeilingTop;
  vertex3.zb = CeilingBottom;
  
  vertex3.zt = CeilingBottom - (sector[SectorNumber].ceilingheinum / 41);
      //GetZ(vertex1.x, vertex1.y, vertex3.x, vertex3.y, CeilingTop, (-1 * sector[SectorNumber].ceilingheinum) * PI/4/4096);
     
  vertex3.zb = vertex3.zt-10;

  if (ret == 0)
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s\n", 
  vertex1.x, vertex1.y, vertex1.zb, vertex3.x, vertex3.y, vertex3.zb, 
  vertex2.x, vertex2.y, vertex2.zb, Texture); 
  
  else
  fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 
  0, 0, CeilingBottom, 500, 0, CeilingBottom, 0, 500, CeilingBottom, Texture);
   
  }
  else // No slope
  fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 
  0, 0, CeilingBottom, 500, 0, CeilingBottom, 0, 500, CeilingBottom, Texture);

  fprintf(f, "}\n"); 
}