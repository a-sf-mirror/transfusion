#include "global.h"

void DrawSectorWalls(FILE *f, long i)
{
 long   wallpointer, SectorCeiling, SectorFloor, j;
 short TimeOut = 1000;
 TPoint vertex1, vertex2;
 TWall  pwall;

 wallpointer  = sector[i].wallptr;
 SectorCeiling = sector[i].ceilingz;
 SectorFloor = sector[i].floorz;
 j = sector[i].wallptr;
  
 do 
 {
  vertex1.x  = wall[j].x;
  vertex1.y  = wall[j].y;
  vertex1.zt = SectorCeiling;
  vertex1.zb = SectorFloor;
  vertex2.x  = wall[wall[j].point2].x;
  vertex2.y  = wall[wall[j].point2].y;
  vertex2.zt = SectorCeiling;
  vertex2.zb = SectorFloor;

  if ((wall[j].nextwall == -1) && (M_Wall[j] == 0))
  {
   pwall.x_off     = 0;
   pwall.y_off     = SectorCeiling;
   pwall.rot_angle = 0;
   pwall.content_a = 0;                                                                                                                                 
   pwall.surface_a = 0;
   pwall.light_v   = 2000;
   pwall.texture   = wall[j].picnum;
   W_Wall(vertex1, vertex2, f, pwall);
   M_Wall[j] = 1;
  }
  j = wall[j].point2; TimeOut--; // Why would something time out?
 } while ( (j != wallpointer) && (TimeOut > 0) );
}

// Draws two sided walls
void WriteWalls(FILE *f)
{
 TPoint vertex1, vertex2;
 long i, NextSector1 = -1, NextSector2;

 printf("Writing 2 sided walls...\t\t\t\t\t ");

 for (i = 0; i < numwalls; i++)
 {
  vertex1.x  = wall[i].x;
  vertex1.y  = wall[i].y;
  vertex2.x  = wall[wall[i].point2].x;
  vertex2.y  = wall[wall[i].point2].y;
  
  NextSector2 = wall[i].nextsector;

  if (wall[i].nextwall != -1) // Connected to another sector
      NextSector1 = wall[wall[i].nextwall].nextsector;

  if ((NextSector1 != -1) && (NextSector2 != -1) && (M_Wall[i] == 0))
  {

   if (sector[NextSector1].floorz > sector[NextSector2].floorz)
   {
    vertex1.zt = sector[NextSector1].floorz;
    vertex1.zb = sector[NextSector2].floorz;
    vertex2.zt = sector[NextSector1].floorz;
    vertex2.zb = sector[NextSector2].floorz;
   }

   if (sector[NextSector1].floorz < sector[NextSector2].floorz)
   {
    vertex1.zt = sector[NextSector2].floorz;
    vertex1.zb = sector[NextSector1].floorz;
    vertex2.zt = sector[NextSector2].floorz;
    vertex2.zb = sector[NextSector1].floorz;
   }

   if (sector[NextSector1].ceilingz > sector[NextSector2].ceilingz)
   {
    vertex1.zt = sector[NextSector1].ceilingz;
    vertex1.zb = sector[NextSector2].ceilingz;
    vertex2.zt = sector[NextSector1].ceilingz;
    vertex2.zb = sector[NextSector2].ceilingz;
   }

   if (sector[NextSector1].ceilingz < sector[NextSector2].ceilingz)
   {
    vertex1.zt = sector[NextSector2].ceilingz;
    vertex1.zb = sector[NextSector1].ceilingz;
    vertex2.zt = sector[NextSector2].ceilingz;
    vertex2.zb = sector[NextSector1].ceilingz;
   }

   WriteWall(vertex1, vertex2, f, i);
   M_Wall[i] = 1;
   M_Wall[wall[i].nextwall] = 1;

  }
 }

 printf("[ Ok ]\n");
}


// Masked walls & windows code
void W_MWalls(FILE *f)
{
 short  Stat;
 TWall  pwall;
 TPoint vertex1, vertex2;
 unsigned short i;
 char *ExplosionType = "exploding_wall";

// TWEAKME: This should be set per game with a switch
#ifdef QUAKE2 
 ExplosionType = "func_explosive";
#endif

 printf("Writing masking walls/windows...\t\t\t\t ");

 for (i = 0; i < numwalls; i++)
 {
  long NextSector1 = -1;
  long NextSector2 = wall[i].nextsector;

  if (wall[i].nextwall != -1) 
      NextSector1 = wall[wall[i].nextwall].nextsector;


  if ((NextSector1 != -1) && (NextSector2 != -1))
  {
   Stat = wall[i].cstat;
   Stat = Stat >> 4;
   if (Stat % 2 == 1)
   {
    pwall.x_off = pwall.y_off = pwall.rot_angle = 0;
    pwall.x_scale = pwall.y_scale = 1.0;
    pwall.content_a = 2; 
    pwall.surface_a = 33;
    pwall.light_v   = 2000;
    pwall.texture = wall[i].overpicnum;
    vertex1.x  = wall[i].x;
    vertex1.y  = wall[i].y;
    vertex1.zt = sector[NextSector1].ceilingz;
    vertex1.zb = sector[NextSector1].floorz;
    vertex2.x  = wall[wall[i].point2].x;
    vertex2.y  = wall[wall[i].point2].y;
    vertex2.zt = sector[NextSector1].ceilingz;
    vertex2.zb = sector[NextSector1].floorz;

//  make this a function DrawExplosion() or something, exploding_wall for qBlood
    fprintf(f, " {\n");
    fprintf(f, " \"classname\"     \"%s\"\n", ExplosionType);
    fprintf(f, " \"health\"        \"15\"\n");
    fprintf(f, " \"skin\"          \"5\"\n");
    fprintf(f, " \"target\"        \"langas%d\"\n", i);
    W_Wall(vertex1, vertex2, f, pwall);
    fprintf(f, " }\n");

//  make this a function too!
#ifndef BLOOD
    fprintf(f, " {\n");
    fprintf(f, "  \"classname\"     \"target_speaker\"\n");
    fprintf(f, "  \"origin\"        \"%d %d %d\"\n", vertex1.x, vertex1.y, vertex1.zt);
    fprintf(f, "  \"attenuation\"   \"0\"\n");
    fprintf(f, "  \"noise\"         \"world/brkglas.wav\"\n");
    fprintf(f, " \"targetname\"     \"langas%d\"\n", i);
    fprintf(f, " }\n");
#endif

   }
  }
 }
 printf("[ Ok ]\n");
}
