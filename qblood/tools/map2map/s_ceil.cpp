#include <stdio.h>
#include <math.h>
#include "global.h"

short G_2va(long x1, long y1, long x2, long y2, long *x, long *y);
long GetZ(double p1x, double p1y, double p2x, double p2y, double p3x, double p3y, double Z, double ang);

void WriteCeiling(FILE *f, long SecN, long Plus)
{
 char Texture[256]=""; // s[256]
 int  Ti;
 long SBot, STop, j, StW; //i
 TPoint p1, p2;
 TPoint v1, v2, v3;
 short ret;

 short Stat = sector[SecN].ceilingstat;

 SBot = sector[SecN].ceilingz      ;
 STop = sector[SecN].ceilingz +Plus;

 StW = sector[SecN].wallptr;
 j   = StW; 

 p1.x  = wall[j].x;
 p1.y  = wall[j].y;
 p1.zt = STop;
 p2.x  = wall[j].x;
 p2.y  = wall[j].y;

 fputs(" {\n", f);

/* TWEAKME: Put more dummy textures here */
#ifdef QUAKE2
 sprintf(Texture, "e1u1/skip 0 0 0 1.00 1.00 1 0 0");
#elif defined HALFLIFE
sprintf(Texture, "sky 0 0 0 1.00 1.00 1 0 0");
#elif defined QUAKE1
sprintf(Texture, "sky1 0 0 0 1.00 1.00 1 0 0");
#endif

/*
 sprintf(Texture, "e1u1/skip");
 if (sector[SecN].ceilingheinum != 0) p2.zt = STop - 100* tan( -1*(sector[SecN].ceilingheinum)*PI/4/4096) +10;
 else p2.zt = STop+10;
 if (p2.zt > STop) STop = p2.zt +10;
 fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p1.x, p1.y, STop, p1.x, p1.y+100, STop, p2.x+100, p2.y, STop, Texture); 
 fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s 0 0 0 1 1 1 0 0\n", 0, 0, STop, 0, 500, STop, 500, 0, STop, Texture); 
*/

 if (sector[SecN].ceilingheinum != 0) 
 {
  v1.x  = wall[j].x;
  v1.y  = wall[j].y;
  v1.zt = STop;
  v1.zb = STop;
  v2.x  = wall[wall[j].point2].x;
  v2.y  = wall[wall[j].point2].y;
  v2.zt = STop;
  v2.zb = STop;
  ret = G_2va(v1.x, v1.y, v2.x, v2.y, &v3.x, &v3.y);
  v3.zt = STop;
  v3.zb = STop;
  v3.zt = GetZ(v1.x, v1.y, v2.x, v2.y, v3.x, v3.y, STop, (-1 * sector[SecN].ceilingheinum) * PI/4/4096);
  v3.zb = v3.zt-10;

  if (v3.zt < STop) v3.zt = STop;

  //fputs("// lubos\n", f);
  if (ret == 0)
// fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1.00 1.00 1 0 0\n", v1.x, v1.y, v1.zt, v2.x, v2.y, v2.zt, v3.x, v3.y, v3.zt, Texture); 
   fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s\n", v1.x, v1.y, v1.zt, v2.x, v2.y, v2.zt, v3.x, v3.y, v3.zt, Texture); 
  else
   fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 0, 0, STop, 0, 500, STop, 500, 0, STop, Texture); 
   
  
 } else
   fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 0, 0, STop, 0, 500, STop, 500, 0, STop, Texture); 

 do 
 {
  p1.x = wall[j].x;
  p1.y = wall[j].y;
  p2.x = wall[wall[j].point2].x;
  p2.y = wall[wall[j].point2].y;
  for (Ti = 0; Ti < 256; Ti++) Texture[Ti] = '\0';

  if (wall[j].nextwall != -1) sprintf(Texture, "tile%.4d", wall[wall[j].nextwall].picnum);
     else sprintf(Texture, "tile%.4d", wall[j].picnum);

 if (Stat % 2 == 1) // This indicates paralaxxing
  fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) sky1 0 0 0 1.00 1.00 0 133 1\n", p2.x, p2.y, 500, p1.x, p1.y, 500, p1.x, p1.y, 0); 
 else
  fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s 0 0 0 1 1 1 0 0\n", p2.x, p2.y, 500, p1.x, p1.y, 500, p1.x, p1.y, 0, Texture); 

  j = wall[j].point2;
 } while (j != StW);

// for (Ti = 0; Ti < 256; Ti++) Texture[Ti] = '\0';
// sprintf(Texture, "tile%.4d", sector[SecN].ceilingpicnum);


 if (Stat % 2 == 1) sprintf(Texture, "sky1 0 0 0 1.00 1.00 0 133 1"); 
               else sprintf(Texture, "tile%.4d 0 0 0 0.50 0.50 1 0 0", sector[SecN].ceilingpicnum);

 if (sector[SecN].ceilingheinum != 0) 
 {
  v1.x  = wall[j].x;
  v1.y  = wall[j].y;
  v1.zt = STop;
  v1.zb = SBot;
  v2.x  = wall[wall[j].point2].x;
  v2.y  = wall[wall[j].point2].y;
  v2.zt = STop;
  v2.zb = SBot;
  ret = G_2va(v1.x, v1.y, v2.x, v2.y, &v3.x, &v3.y);
  v3.zt = STop;
  v3.zb = SBot;
  v3.zt = GetZ(v1.x, v1.y, v2.x, v2.y, v3.x, v3.y, STop, (-1 * sector[SecN].ceilingheinum) * PI/4/4096);
  v3.zb = v3.zt-10;
  if (ret == 0)
  {
// fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1.00 1.00 1 0 0\n", v1.x, v1.y, v1.zb, v3.x, v3.y, v3.zb, v2.x, v2.y, v2.zb, Texture); 
   fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s\n", v1.x, v1.y, v1.zb, v3.x, v3.y, v3.zb, v2.x, v2.y, v2.zb, Texture); 
  } else
  {
// fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s 0 0 0 1.00 1.00 1 0 0\n", 0, 0, SBot, 500, 0, SBot, 0, 500, SBot, Texture); 
   fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 0, 0, SBot, 500, 0, SBot, 0, 500, SBot, Texture); 
   
  }
 } else
 {
//fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s 0 0 0 1.00 1.00 1 0 0\n", 0, 0, SBot, 500, 0, SBot, 0, 500, SBot, Texture); 
  fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 0, 0, SBot, 500, 0, SBot, 0, 500, SBot, Texture); 
  
 }

/*
 if (sector[SecN].ceilingheinum != 0) 
 {
  p2.zb = SBot - 100 * tan( (-1 * sector[SecN].floorheinum) * PI / 4 / 4096     );
  if (p2.zb < SBot) p2.zb = SBot;
//  fputs("// heheh \n", f);
 }
 else
 {
  p2.zt = STop;
  p2.zb = SBot;
 }

 if (Stat % 2 == 1) 
 {
//  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) sky1 0 0 0 1.00 1.00 0 133 1\n", 0, 0, SBot, 500, 0, SBot, 0, 500, p2.zb); 
  fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) sky1 0 0 0 1.00 1.00 0 133 1\n", 0, 0, SBot, 500, 0, SBot, 0, 500, SBot); 
 } else
 {
  sprintf(Texture, "tile%.4d", sector[SecN].ceilingpicnum);
  fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s 0 0 0 1 1 1 0 0\n", 0, 0, SBot, 500, 0, SBot, 0, 500, SBot, Texture); 
 }
*/
 fputs(" }\n", f); 
}