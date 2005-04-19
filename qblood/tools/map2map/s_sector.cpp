#include <stdio.h>
#include <string.h>
#include "global.h"

long FindWall(long SecN);
void WriteFloor  (FILE *f, long SecN, long Plus);
void WriteCeiling(FILE *f, long SecN, long Plus);
void DrawSectorWalls(FILE *f, long i);

long FindWalls(long SecN)
{
 int  j;
 long StW;
 long c;

 c = 1;

 StW = sector[SecN].wallptr;
 j   = wall[StW].point2;
 do 
 {
  j = wall[j].point2;
  c++;
 } while (j != StW);
 return c;
}

short Draw_Sector_II(FILE *f, long i)
{
// printf("Writing Sector %ld\n", i);

 int  j;
 long Dn;
 long Up;
 long StW;
 long ST;
 long SB;

 long count = 0;

 Dn = -15;
 Up = +1;

 ST  = sector[i].floorz;
 SB  = sector[i].ceilingz;
 StW = sector[i].wallptr;
 j   = sector[i].wallptr;
 
 do 
 {
  if (wall[j].nextsector != -1)
  {
   if (sector[wall[j].nextsector].floorz - ST < Dn)
   {
    Dn = sector[wall[j].nextsector].floorz - ST;
   } 
   if (sector[wall[j].nextsector].ceilingz - SB > Up)
   {
    Up = sector[wall[j].nextsector].ceilingz - SB;
   }
   M_Wall[               j] = 1;
   M_Wall[wall[j].nextwall] = 1;
  }
  j = wall[j].point2;
  count++;
 } while ((j != StW) & (count < 1000));
 if (count < 1000)
 {
  WriteFloor  (f, 1025, Dn);
  WriteCeiling(f, 1025, Up);
 } else printf("Uzpiso\n");
 return count;
}

void DrawBrush_II(FILE *f, long WallN, long STop, long SBot)
{
 TPoint p1, p2;
 char   Texture[256];// s[256]
 long   Ti, j = WallN; 
 if (wall[WallN].nextwall != -1) return;
 p1.x   = wall[j].x;
 p1.y   = wall[j].y;
 p1.zt  = STop;
 p2.x   = wall[j].x;
 p2.y   = wall[j].y;
 p2.zt  = STop;
 p2.zt = STop;
 p2.zb = SBot;

 fprintf(f, " {\n");
#ifdef QUAKE2
 sprintf(Texture, "e1u1/skip"); // Good for quake 2, but not 1
#elif defined HALFLIFE
 sprintf(Texture, "sky");
#elif defined QUAKE1
 sprintf(Texture, "sky1");
#endif

 fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p1.x, p1.y, STop, p1.x, p1.y+100, STop, p2.x+100, p2.y, STop, Texture); 
 do 
 {
  p1.x = wall[j].x;
  p1.y = wall[j].y;
  p2.x = wall[wall[j].point2].x;
  p2.y = wall[wall[j].point2].y;
  for (Ti = 0; Ti < 256; Ti++) Texture[Ti] = '\0';
  sprintf(Texture, "tile%.4d", wall[j].picnum);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p1.x, p1.y, 500, p2.x, p2.y, 500, p2.x, p2.y, 0, Texture); 
  j = wall[j].point2;
 } while (j != WallN);

#ifdef QUAKE2
 strcpy(Texture, "e1u1/skip"); // Good for quake 2, but not 1
#elif defined HALFLIFE
 strcpy(Texture, "sky");
#elif defined QUAKE1
 strcpy(Texture, "sky1");
#endif 

 fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0, SBot, 500, 0, SBot, 0, 500, SBot, Texture);  fprintf(f, " }\n"); 
 
 // or

 j   = WallN; 

 p1.x   = wall[j].x;
 p1.y   = wall[j].y;
 p1.zt  = STop;
 p2.x   = wall[j].x;
 p2.y   = wall[j].y;
 p2.zt  = STop;
 p2.zt = STop;
 p2.zb = SBot;

 fprintf(f, " {\n");
#ifdef QUAKE2
 sprintf(Texture, "e1u1/skip"); // Good for quake 2, but not 1
#elif defined HALFLIFE
 sprintf(Texture, "sky");
#elif defined QUAKE1
 sprintf(Texture, "sky1");
#endif

 fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p1.x, p1.y, STop, p1.x, p1.y+100, STop, p2.x+100, p2.y, STop, Texture); 
 do 
 {
  p1.x = wall[j].x;
  p1.y = wall[j].y;
  p2.x = wall[wall[j].point2].x;
  p2.y = wall[wall[j].point2].y;
  for (Ti = 0; Ti < 256; Ti++) Texture[Ti] = '\0';
  sprintf(Texture, "tile%.4d", wall[j].picnum);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p2.x, p2.y, 500, p1.x, p1.y, 500, p1.x, p1.y, 0, Texture); 
  j = wall[j].point2;
 } while (j != WallN);

#ifdef QUAKE2
 sprintf(Texture, "e1u1/skip"); // Good for quake 2, but not 1
#elif defined HALFLIFE
 sprintf(Texture, "sky");
#elif defined QUAKE1
 sprintf(Texture, "sky1");
#endif

 fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0, SBot, 500, 0, p2.zb, 0, 500, SBot, Texture); 
 fprintf(f, " }\n"); 
}

void W_Sector_II(FILE *f, long SecN, long Up, long Dn)
{
 long Sn      = FindWall(SecN);
 sector[1025] = sector[SecN];

 if (Sn != -1) 
 {
  sector[1025].wallptr = Sn; //wall[sector[i].wallptr].nextwall;
  if (Draw_Sector_II(f, 1025) < 1000)
  {
   DrawSectorWalls(f, 1025);
   //  WriteFloor(f, 1025, Plus);
   //  WriteCeiling(f, 1025, Plus);
   DrawBrush_II(f, sector[SecN].wallptr, sector[SecN].ceilingz+16, sector[SecN].floorz-16); 
  }
 }
 WriteFloor  (f, SecN, Dn);
 WriteCeiling(f, SecN, Up);
 DrawSectorWalls(f, SecN);
}

