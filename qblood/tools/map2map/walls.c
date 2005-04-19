#include "global.h"

void DrawSectorWalls(FILE *f, const unsigned short i)
{
 long   wallpointer, SectorCeiling, SectorFloor, j;
 short TimeOut = 1000;
 TPoint vertex1, vertex2;
 TWall  pwall;

 j = wallpointer  = sector[i].wallptr;
 
 
 do 
 {
     wall_t Wall1, Wall2, Wall3;

     Wall1 = wall[j];
     Wall2 = wall[wall[j].point2];
     Wall3 = wall[wall[wall[j].point2].point2];

     if (Wall1.point2 == wallpointer || // No further optimizing to be done
         Wall2.point2 == wallpointer ||
         Wall3.point2 == wallpointer )
         break;

     /* This next chunk is some magic, so here's my explanation:
        The first if segment checks the walls to see if they're connected to another sector
        it would be bad to smooth a wall out that had a window or step nearby.
        The second chunk is checking for a redundant point between wall 1 and 3
        The third chunk is to make sure if the extra wall is merely added for a special texture.
      */
  
     if ( ( (Wall1.nextsector == -1 && Wall1.nextwall == -1) &&         // Connected
            (Wall2.nextsector == -1 && Wall2.nextwall == -1) &&         // Connected
            (Wall3.nextsector == -1 && Wall3.nextwall == -1) ) &&       // Connected
        ((Wall1.x == Wall2.x && Wall1.x == Wall3.x) ||                  // Redundant point
         (Wall1.y == Wall2.y && Wall1.y == Wall3.y)) &&                 // Redundant point
        (Wall1.picnum == Wall2.picnum && Wall2.picnum == Wall3.picnum)) // Different art
          
     { // Make Wall 1 point to wall 3 to save from drawing a redundant wall
         wall[j].point2 = wall[wall[j].point2].point2;
     }
     else j = wall[j].point2; // Nothing can be tweaked, go to next wall
 } while ( (j != wallpointer) && (TimeOut > 0) );
 

 j = wallpointer = sector[i].wallptr;
 SectorCeiling = sector[i].ceilingz;
 SectorFloor = sector[i].floorz;
 TimeOut = 1000;
 
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
    vertex1.zt = sector[NextSector1].ceilingz;
    vertex1.zb = sector[NextSector1].floorz;
    vertex2.x  = wall[wall[i].point2].x;
    vertex2.y  = wall[wall[i].point2].y;
    vertex2.zt = sector[NextSector1].ceilingz;
    vertex2.zb = sector[NextSector1].floorz;

#ifdef QUAKE1
    fprintf(f, " {\n");
    fprintf(f, " \"classname\"     \"exploding_wall\"\n");
    fprintf(f, " \"health\"        \"15\"\n");
    fprintf(f, " \"skin\"          \"6\"\n");
    W_Wall(vertex1, vertex2, f, pwall);
    fprintf(f, " }\n");
#endif

#ifdef QUAKE2
    fprintf(f, " {\n");
    fprintf(f, " \"classname\"     \"func_explosive\"\n");
    fprintf(f, " \"health\"        \"15\"\n");
    fprintf(f, " \"skin\"          \"5\"\n");
    fprintf(f, " \"target\"        \"langas%d\"\n", i);
    W_Wall(vertex1, vertex2, f, pwall);
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
