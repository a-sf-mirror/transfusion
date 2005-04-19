#include "global.h"

void WriteWall(TPoint p1, TPoint p2, FILE *f, long i);
void W_Wall(TPoint p1, TPoint p2, FILE *f, TWall w);

void DrawSectorWalls(FILE *f, long i)
{
 long   wallpointer, SectorCeiling, SectorFloor, j, TimeOut = 1000;
 TPoint v1, v2;
 TWall  pwall;

 wallpointer  = sector[i].wallptr;
 SectorCeiling = sector[i].ceilingz;
 SectorFloor = sector[i].floorz;
 j = sector[i].wallptr;
  
 do 
 {
  v1.x  = wall[j].x;
  v1.y  = wall[j].y;
  v1.zt = SectorCeiling;
  v1.zb = SectorFloor;
  v2.x  = wall[wall[j].point2].x;
  v2.y  = wall[wall[j].point2].y;
  v2.zt = SectorCeiling;
  v2.zb = SectorFloor;

  if ((wall[j].nextwall == -1) & (M_Wall[j] == 0))
  {
   pwall.x_off     = 0;
   pwall.y_off     = SectorCeiling;
   pwall.rot_angle = 0;
   pwall.content_a = 0;                                                                                                                                 
   pwall.surface_a = 0;
   pwall.light_v   = 2000;
   pwall.texture   = wall[j].picnum;
   W_Wall(v1, v2, f, pwall);
   M_Wall[j] = 1;
  }
  j = wall[j].point2; TimeOut--; // Why would something time out?
 } while ( (j != wallpointer) && (TimeOut > 0) );
}

void WriteWalls(FILE *f)
{
 TPoint v1, v2;
 long i, Sn1 = -1, Sn2;

 printf("Writing 2 sided walls...\t\t\t\t\t ");

 for (i = 0; i < numwalls; i++)
 {
  v1.x  = wall[i].x;
  v1.y  = wall[i].y;
  v2.x  = wall[wall[i].point2].x;
  v2.y  = wall[wall[i].point2].y;
  
  Sn2 = wall[i].nextsector;
  if (wall[i].nextwall != -1) Sn1 = wall[wall[i].nextwall].nextsector;
  if ((Sn1 != -1) & (Sn2 != -1) & (M_Wall[i] == 0))
  {

   if (sector[Sn1].floorz > sector[Sn2].floorz)
   {
    v1.zt = sector[Sn1].floorz;
    v1.zb = sector[Sn2].floorz;
    v2.zt = sector[Sn1].floorz;
    v2.zb = sector[Sn2].floorz;
    WriteWall(v1, v2, f, i);
   }

   if (sector[Sn1].floorz < sector[Sn2].floorz)
   {
    v1.zt = sector[Sn2].floorz;
    v1.zb = sector[Sn1].floorz;
    v2.zt = sector[Sn2].floorz;
    v2.zb = sector[Sn1].floorz;
    WriteWall(v1, v2, f, i);
   }

   if (sector[Sn1].ceilingz > sector[Sn2].ceilingz)
   {
    v1.zt = sector[Sn1].ceilingz;
    v1.zb = sector[Sn2].ceilingz;
    v2.zt = sector[Sn1].ceilingz;
    v2.zb = sector[Sn2].ceilingz;
    WriteWall(v1, v2, f, i);
   }

   if (sector[Sn1].ceilingz < sector[Sn2].ceilingz)
   {
    v1.zt = sector[Sn2].ceilingz;
    v1.zb = sector[Sn1].ceilingz;
    v2.zt = sector[Sn2].ceilingz;
    v2.zb = sector[Sn1].ceilingz;
    WriteWall(v1, v2, f, i);
   }

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
 TPoint v1, v2;
 unsigned short i;
 char *ExplosionType = "exploding_wall";

// TWEAKME: This should be set per game with a switch
#ifdef QUAKE2 
 ExplosionType = "func_explosive";
#endif

 printf("Writing masking walls/windows...\t\t\t\t ");

 for (i = 0; i < numwalls; i++)
 {
  long Sn1 = -1;
  long Sn2 = wall[i].nextsector;

  if (wall[i].nextwall != -1) 
      Sn1 = wall[wall[i].nextwall].nextsector;

  if ((Sn1 != -1) && (Sn2 != -1))
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
    v1.x  = wall[i].x;
    v1.y  = wall[i].y;
    v1.zt = sector[Sn1].ceilingz;
    v1.zb = sector[Sn1].floorz;
    v2.x  = wall[wall[i].point2].x;
    v2.y  = wall[wall[i].point2].y;
    v2.zt = sector[Sn1].ceilingz;
    v2.zb = sector[Sn1].floorz;

//  make this a function DrawExplosion() or something, exploding_wall for qBlood
    fprintf(f, " {\n");
    fprintf(f, " \"classname\"     \"%s\"\n", ExplosionType);
    fprintf(f, " \"health\"        \"16\"\n");
    fprintf(f, " \"mass\"          \"75\"\n");
    fprintf(f, " \"target\"        \"langas%ld\"\n", i); 
    W_Wall(v1, v2, f, pwall);
    fprintf(f, " }\n");

//  make this a function too!
    fprintf(f, " {\n");
    fprintf(f, "  \"classname\"     \"target_speaker\"\n", f);
    fprintf(f, "  \"origin\"        \"%ld %ld %ld\"\n", v1.x, v1.y, v1.zt); 
    fprintf(f, "  \"attenuation\"   \"0\"\n", f);
    fprintf(f, "  \"noise\"         \"world/brkglas.wav\"\n", f);
    fprintf(f, " \"targetname\"     \"langas%ld\"\n", i); 
    fprintf(f, " }\n");

   }
  }
 }
 printf("[ Ok ]\n");
}
