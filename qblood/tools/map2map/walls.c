#include "global.h"

void DrawSectorWalls(FILE *f, const unsigned short i, const short Down, const char SectorType)
{
 long wallpointer, SectorCeiling, SectorFloor, k;
 TPoint vertex1, vertex2;
 TWall  pwall;
 
 wallpointer = sector[i].wallptr;
 
  if (SectorType == NORMAL)
  {
      SectorCeiling = sector[i].ceilingz;
      
      if (Down < 0)
          SectorFloor = sector[i].floorz +Down; // Floor going down
      else // Down >= 0
          SectorFloor = sector[i].floorz;
  }

  else // SectorType == ALTERED
  {
      if (Down < 0)
      {
          SectorFloor = sector[i].floorz +Down; // Floor going down
          SectorCeiling = sector[i].floorz;
      }
      else// Down >= 0
      {
          SectorCeiling = sector[i].floorz +Down; // Floor going up - steps, small objects, etc
          SectorFloor = sector[i].floorz;
      }

  }

  if (sector[i].wallnum < 1)
  {
      printf("Invalid sector:%d\n",i);
      exit(0);
  }

  if (sector[i].wallnum > 1000)
  {
      printf("Crazy sector:%d\n"
             "Number of walls listed:%d\n", i, sector[i].wallnum);

      sector[i].wallnum = FindWalls(i);
      printf("New number of walls:%d\n", sector[i].wallnum);
      getch();
  }

 for (k = 0; k < sector[i].wallnum; k++)
 {
  vertex1.x  = wall[wallpointer + k].x;
  vertex1.y  = wall[wallpointer + k].y;
  vertex1.zt = vertex2.zt = SectorCeiling;
  
  // Sets all walls in a sector bottom z to that of the lowest possible point in a sector
  if (sector[i].floorheinum == 0) // No floor slope in this sector
      vertex1.zb = vertex2.zb = SectorFloor;

  else // Walls in a sloped sector
      vertex1.zb = vertex2.zb = SectorFloor - (sector[i].floorheinum / -1024) -1;
  
  vertex2.x  = wall[wall[wallpointer + k].point2].x;
  vertex2.y  = wall[wall[wallpointer + k].point2].y;
  
  if ((wall[wallpointer + k].nextwall == -1) && (M_Wall[wallpointer + k] == 0)) // Not connected & not written yet
  {
   pwall.x_off     = 0;
   pwall.y_off     = SectorCeiling;
   pwall.rot_angle = 0;
   pwall.content_a = 0;                                                                                                                                 
   pwall.surface_a = 0;
   pwall.light_v   = 2000;
   pwall.texture   = wall[wallpointer + k].picnum;
   WriteWall(vertex1, vertex2, f, pwall);
   M_Wall[wallpointer + k] = 1;
  }
  
 }
}

// Draws two sided walls
void WriteTwoSidedWalls(FILE *f)
{
 TPoint vertex1, vertex2;
 short i, NextSector1 = -1, NextSector2;

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

  if ((NextSector1 > -1) && (NextSector2 > -1) && (M_Wall[i] == 0))
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

   WriteTwoSidedWall(vertex1, vertex2, f, i);
   M_Wall[i] = 1;
   M_Wall[wall[i].nextwall] = 1;

  }
 }

 printf("[ Ok ]\n");
}


// Masked walls & windows code
void WriteMaskedWalls(FILE *f)
{
 short  Stat;
 TWall  pwall;
 TPoint vertex1, vertex2;
 unsigned short i;

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
    vertex1.zt = vertex2.zt = sector[NextSector1].ceilingz;
    vertex1.zb = vertex2.zb = sector[NextSector1].floorz;
    vertex2.x  = wall[wall[i].point2].x;
    vertex2.y  = wall[wall[i].point2].y;
        
#ifdef QUAKE1
    fprintf(f, " {\n");
    fprintf(f, " \"classname\"     \"exploding_wall\"\n");
    fprintf(f, " \"health\"        \"15\"\n");
    fprintf(f, " \"skin\"          \"6\"\n");
    WriteWall(vertex1, vertex2, f, pwall);
    fprintf(f, " }\n");
#endif

#ifdef QUAKE2
    fprintf(f, " {\n");
    fprintf(f, " \"classname\"     \"func_explosive\"\n");
    fprintf(f, " \"health\"        \"15\"\n");
    fprintf(f, " \"skin\"          \"5\"\n");
    fprintf(f, " \"target\"        \"langas%d\"\n", i);
    WriteWall(vertex1, vertex2, f, pwall);
    fprintf(f, " }\n");

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