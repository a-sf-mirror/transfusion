#include "global.h"

void WriteCeiling(FILE *f, long SectorNumber, long Plus)
{
 char Texture[256]="";
 int  Ti;
 long SBot, STop, j, wallpointer; 
 TPoint point1, point2, vertex1, vertex2, vertex3;
 short ret;

 short Stat = sector[SectorNumber].ceilingstat;

 // To avoid compiler gripes, initializing vertex3
 vertex3.x = vertex3.y = vertex3.zb = vertex3.zt = 0;

 SBot = sector[SectorNumber].ceilingz;
 STop = sector[SectorNumber].ceilingz +Plus;

 wallpointer = sector[SectorNumber].wallptr;
 j   = wallpointer; 

 point1.x  = wall[j].x;
 point1.y  = wall[j].y;
 point1.zt = STop;
 point2.x  = wall[j].x;
 point2.y  = wall[j].y;

 fprintf(f, "{\n");

/* TWEAKME: Put more dummy textures here */
#ifdef QUAKE2
 sprintf(Texture, "e1u1/skip 0 0 0 1.00 1.00 1 0 0");
#elif defined HALFLIFE
sprintf(Texture, "sky 0 0 0 1.00 1.00 1 0 0");
#elif defined QUAKE1
sprintf(Texture, "sky1 0 0 0 1.00 1.00 1 0 0");
#endif

 if (sector[SectorNumber].ceilingheinum != 0) // Slope
 {
  vertex1.x  = wall[j].x;
  vertex1.y  = wall[j].y;
  vertex1.zt = STop;
  vertex1.zb = STop;
  vertex2.x  = wall[wall[j].point2].x;
  vertex2.y  = wall[wall[j].point2].y;
  vertex2.zt = STop;
  vertex2.zb = STop;
  ret = G_2va(vertex1.x, vertex1.y, vertex2.x, vertex2.y, &vertex3.x, &vertex3.y); // vertex3 is getting worked on
  vertex3.zt = STop;
  vertex3.zb = STop;
  vertex3.zt = GetZ(vertex1.x, vertex1.y, vertex3.x, vertex3.y, STop, (-1 * sector[SectorNumber].ceilingheinum) * PI/4/4096);
  vertex3.zb = vertex3.zt-10;

  if (vertex3.zt < STop) vertex3.zt = STop;

  //fputs("// lubos\n", f);
  if (ret == 0)
   fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s\n", vertex1.x, vertex1.y, vertex1.zt, vertex2.x, vertex2.y, vertex2.zt, vertex3.x, vertex3.y, vertex3.zt, Texture); 
 
  else
   fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 0, 0, STop, 0, 500, STop, 500, 0, STop, Texture); 

 } else
   fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 0, 0, STop, 0, 500, STop, 500, 0, STop, Texture); 

 do 
 {
  point1.x = wall[j].x;
  point1.y = wall[j].y;
  point2.x = wall[wall[j].point2].x;
  point2.y = wall[wall[j].point2].y;
  for (Ti = 0; Ti < 256; Ti++) Texture[Ti] = '\0';

  if (wall[j].nextwall != -1) sprintf(Texture, "tile%.4d", wall[wall[j].nextwall].picnum);
     else sprintf(Texture, "tile%.4d", wall[j].picnum);

 if (Stat % 2 == 1) // This indicates paralaxxing
  fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) sky1 0 0 0 1.00 1.00 0 133 1\n", point2.x, point2.y, 500, point1.x, point1.y, 500, point1.x, point1.y, 0); 
 else
  fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s 0 0 0 1 1 1 0 0\n", point2.x, point2.y, 500, point1.x, point1.y, 500, point1.x, point1.y, 0, Texture); 

  j = wall[j].point2;
 } while (j != wallpointer);

 if (Stat % 2 == 1) // This indicates paralaxxing
	 sprintf(Texture, "sky1 0 0 0 1.00 1.00 0 133 1");

 else sprintf(Texture, "tile%.4d 0 0 0 0.50 0.50 1 0 0", sector[SectorNumber].ceilingpicnum);

 if (sector[SectorNumber].ceilingheinum != 0) // Slope
 {
  vertex1.x  = wall[j].x;
  vertex1.y  = wall[j].y;
  vertex1.zt = STop;
  vertex1.zb = SBot;
  vertex2.x  = wall[wall[j].point2].x;
  vertex2.y  = wall[wall[j].point2].y;
  vertex2.zt = STop;
  vertex2.zb = SBot;
  ret = G_2va(vertex1.x, vertex1.y, vertex2.x, vertex2.y, &vertex3.x, &vertex3.y); // vertex3 is getting worked on
  vertex3.zt = STop;
  vertex3.zb = SBot;
  vertex3.zt = GetZ(vertex1.x, vertex1.y, vertex3.x, vertex3.y, STop, (-1 * sector[SectorNumber].ceilingheinum) * PI/4/4096);
  vertex3.zb = vertex3.zt-10;

  if (ret == 0)
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s\n", vertex1.x, vertex1.y, vertex1.zb, vertex3.x, vertex3.y, vertex3.zb, vertex2.x, vertex2.y, vertex2.zb, Texture); 
  
  else
  fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 0, 0, SBot, 500, 0, SBot, 0, 500, SBot, Texture); 
   
  }
  else
  fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 0, 0, SBot, 500, 0, SBot, 0, 500, SBot, Texture); 

  fprintf(f, "}\n"); 
}