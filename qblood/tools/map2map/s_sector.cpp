#include "global.h"

// Validates the number of walls in a sector
long FindWall(long SectorNumber);
void WriteFloor  (FILE *f, long SectorNumber, long Plus);
void WriteCeiling(FILE *f, long SectorNumber, long Plus);
void DrawSectorWalls(FILE *f, long i);
long FindWalls(long SectorNumber);


// Manually finds the number of walls in a sector
long FindWalls(long SectorNumber)
{
 int  j;
 long wallpointer, walls = 1;

 wallpointer = sector[SectorNumber].wallptr;
 j = wall[wallpointer].point2;

 do 
 {
     j = wall[j].point2;
     walls++;

 } while (j != wallpointer);

 return walls;
}


short Draw_Sector_II(FILE *f, long i)
{

 int  j;
 long Dn = -15, Up = 1, wallpointer, SectorFloor, SectorCeiling, count = 0;

 SectorFloor  = sector[i].floorz;
 SectorCeiling  = sector[i].ceilingz;
 wallpointer = sector[i].wallptr;
 j   = sector[i].wallptr;
 
 do 
 {
     if (wall[j].nextsector != -1) // Doesn't touch any other sectors
         {
         if (sector[wall[j].nextsector].floorz - SectorFloor < Dn)
             {
                 Dn = sector[wall[j].nextsector].floorz - SectorFloor;
             } 
         if (sector[wall[j].nextsector].ceilingz - SectorCeiling > Up)
             {
                 Up = sector[wall[j].nextsector].ceilingz - SectorCeiling;
             }
         M_Wall[j] = M_Wall[wall[j].nextwall] = 1;
         }
    
     j = wall[j].point2;
    count++;

 } while ((j != wallpointer) & (count < 1000));

 if (count < 1000)
 {
  WriteFloor  (f, numsectors, Dn); // Write the temp sector
  WriteCeiling(f, numsectors, Up); // Write the temp sector
 } 
 else printf("Error in Draw_Sector_II\n");

 return count;
}


void DrawBrush_II(FILE *f, long WallN, long SectorFloor, long SectorCeiling)
{
 TPoint p1, p2;
 char   Texture[256]="";
 long   j = WallN; 
 if (wall[WallN].nextwall != -1) return;
 p1.x   = wall[j].x;
 p1.y   = wall[j].y;
 p1.zt  = SectorFloor;
 p2.x   = wall[j].x;
 p2.y   = wall[j].y;
 p2.zt  = SectorFloor;
 p2.zt = SectorFloor;
 p2.zb = SectorCeiling;

 fprintf(f, " {\n");
#ifdef QUAKE2
 sprintf(Texture, "e1u1/skip"); // Good for quake 2, but not 1
#elif defined HALFLIFE
 sprintf(Texture, "sky");
#elif defined QUAKE1
 sprintf(Texture, "sky1");
#endif

 fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p1.x, p1.y, SectorFloor, p1.x, p1.y+100, SectorFloor, p2.x+100, p2.y, SectorFloor, Texture); 
 do 
 {
  p1.x = wall[j].x;
  p1.y = wall[j].y;
  p2.x = wall[wall[j].point2].x;
  p2.y = wall[wall[j].point2].y;
  
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

 fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0, SectorCeiling, 500, 0, SectorCeiling, 0, 500, SectorCeiling, Texture);  fprintf(f, " }\n"); 
 
 // or

 j   = WallN; 

 p1.x   = wall[j].x;
 p1.y   = wall[j].y;
 p1.zt  = SectorFloor;
 p2.x   = wall[j].x;
 p2.y   = wall[j].y;
 p2.zt  = SectorFloor;
 p2.zt = SectorFloor;
 p2.zb = SectorCeiling;

 fprintf(f, " {\n");
#ifdef QUAKE2
 sprintf(Texture, "e1u1/skip"); // Good for quake 2, but not 1
#elif defined HALFLIFE
 sprintf(Texture, "sky");
#elif defined QUAKE1
 sprintf(Texture, "sky1");
#endif

 fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p1.x, p1.y, SectorFloor, p1.x, p1.y+100, SectorFloor, p2.x+100, p2.y, SectorFloor, Texture); 
 do 
 {
  p1.x = wall[j].x;
  p1.y = wall[j].y;
  p2.x = wall[wall[j].point2].x;
  p2.y = wall[wall[j].point2].y;
  
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

 fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0, SectorCeiling, 500, 0, p2.zb, 0, 500, SectorCeiling, Texture); 
 fprintf(f, " }\n"); 
}

void W_Sector_II(FILE *f, long SectorNumber, long Up, long Dn)
{
 long Sn      = FindWall(SectorNumber);
 sector[numsectors] = sector[SectorNumber]; // Storing to the temp sector

 if (Sn != -1) 
 {
  sector[numsectors].wallptr = Sn; //wall[sector[i].wallptr].nextwall;
  if (Draw_Sector_II(f, numsectors) < 1000) // Storing to the temp sector
  {
   DrawSectorWalls(f, numsectors);
   DrawBrush_II(f, sector[SectorNumber].wallptr, sector[SectorNumber].ceilingz+16, sector[SectorNumber].floorz-16); 
  }
 }
 WriteFloor  (f, SectorNumber, Dn);
 WriteCeiling(f, SectorNumber, Up);
 DrawSectorWalls(f, SectorNumber);
}

