#include "global.h"

// Writes a wall like in b2q
void AlternateWriteWall(FILE *f, const unsigned short WallNumber, const unsigned short SectorNumber, const short Down)
{
 char Texture[10] = "";
 double radian = 0;
 wall_t Wall1, Wall2;
 int ceiling, floor, MinZ;
 unsigned short i;

 Wall1 = wall[WallNumber];
 Wall2 = wall[Wall1.point2];
 

 // -15 will probably cause issues...     
 
/* if (Down < 0 && Down != -15 && wall[WallNumber].nextsector != 1 && wall[WallNumber].nextwall == -1) 
      {
          floor = sector[SectorNumber].floorz +Down; // Floor going down
          ceiling = sector[SectorNumber].floorz;
      }
      else  
         if (Down >= 0)
      { */

if (wall[WallNumber].nextsector != 1 && 
    (sector[SectorNumber].ceilingz - sector[wall[WallNumber].nextsector].ceilingz != 0 ||
    sector[SectorNumber].floorz - sector[wall[WallNumber].nextsector].floorz != 0 )
    )
{ // Only good for certain things (i.e.
    MinZ = sector[wall[WallNumber].nextsector].floorz;
    for (i = 0; i < sector[SectorNumber].wallnum; i++)
    {
        if (MinZ > sector[wall[i + sector[SectorNumber].wallptr].nextsector].floorz)
            MinZ = sector[wall[i + sector[SectorNumber].wallptr].nextsector].floorz;
    }

    ceiling = sector[SectorNumber].floorz;
    floor = MinZ;
}





//          ceiling = sector[SectorNumber].floorz +Down; // Floor going up - steps, small objects, etc
//          floor = sector[wall[WallNumber].nextsector].floorz;
              //sector[SectorNumber].floorz;
      //}
      else
      {
          ceiling = sector[SectorNumber].ceilingz;
          floor = sector[SectorNumber].floorz;
      }
//*/
      if (SectorNumber == 111 || SectorNumber == 140 || SectorNumber == 141)
      {
          FILE* log =NULL;
          log = fopen ("log.txt","a");
          fprintf(log, "Sector Number: %d    Ceiling z: %d    Floor z: %d\n", 
                   SectorNumber, sector[SectorNumber].ceilingz, sector[SectorNumber].floorz); 
          if (wall[WallNumber].nextsector != 1)
              fprintf(log, "Next Sector Number: %d    Ceiling z: %d    Floor z: %d\n",
              wall[WallNumber].nextsector, sector[wall[WallNumber].nextsector].ceilingz,
              sector[wall[WallNumber].nextsector].floorz);
          fprintf(log, "Down = %d\n\n", Down); 

      }


 

 // This should be tweaked per "to" game
sprintf(Texture, TEXTUREPREFIX "tile%.4d", wall[WallNumber].picnum);

 if ((Wall1.x == Wall2.x) && (Wall1.y == Wall2.y))
 	 return; //No line to draw for wall
 
 if (ceiling <= floor)
 {
	 printf("The ceiling <= the floor %d\n", WallNumber);
	 return;
 }
 
 // Chunk #1 - The magic that draws valid brushes
 if ((Wall2.x != Wall1.x) && (Wall2.y != Wall1.y))
 {
  radian = 180 * atan2(Wall2.y-Wall1.y, Wall2.x-Wall1.x) / PI;
  
  if (radian < 0)
	  radian += 360;

 } 
 // Chunk #2
 else
 {
  if (Wall1.x == Wall2.x) 
  { 
   if (Wall1.y > Wall2.y)
	   radian = 270; 
   else radian = 90;
  }

  if (Wall1.y == Wall2.y) 
  { 
   if (Wall1.x > Wall2.x) 
	   radian = 180; 
   else radian = 0;
  }
 }

 fprintf(f, "// x1 = %d y1 = %d x2 = %d y2 = %d\n", Wall1.x, Wall1.y, Wall2.x, Wall2.y);

 if (((radian >= 0) && (radian < 45)) || (radian > 315))
 {
  fprintf(f, " {\n");
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0, ceiling, 0, 500, ceiling, 500,  0,      ceiling, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", Wall1.x, Wall1.y-THICK, ceiling,   Wall2.x,   Wall2.y-THICK, ceiling,   Wall2.x, Wall2.y-THICK, floor, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", Wall2.x, Wall2.y-THICK, ceiling,   Wall2.x,   Wall2.y,   ceiling,   Wall2.x, Wall2.y,   floor, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", Wall2.x, Wall2.y,   ceiling,   Wall1.x,   Wall1.y, ceiling,   Wall1.x, Wall1.y,   floor, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", Wall1.x, Wall1.y, ceiling,   Wall1.x,   Wall1.y-THICK, ceiling,   Wall1.x, Wall1.y-THICK, floor, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0,     floor, 500, 0,     floor, 0, 500,  floor, Texture);
  fprintf(f, " }\n");
 }
  
 if ((radian >= 45) && (radian <= 135))
 {
  fprintf(f, " {\n");
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0, ceiling, 0, 500, ceiling, 500, 0,    ceiling, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", Wall1.x+THICK, Wall1.y, ceiling, Wall2.x+THICK, Wall2.y,  ceiling, Wall2.x+THICK, Wall2.y, floor, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", Wall2.x+THICK, Wall2.y,  ceiling, Wall2.x,   Wall2.y,  ceiling, Wall2.x,   Wall2.y, floor, Texture);   
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", Wall2.x,   Wall2.y,  ceiling, Wall1.x,   Wall1.y, ceiling, Wall1.x,   Wall1.y, floor, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", Wall1.x,   Wall1.y, ceiling, Wall1.x+THICK, Wall1.y, ceiling, Wall1.x+THICK, Wall1.y, floor, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0,     floor, 500, 0,     floor, 0, 500,  floor, Texture); 
  fprintf(f, " }\n");
 }

 if ((radian > 135) && (radian <= 225))
 {
  fprintf(f, " {\n");
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0, ceiling, 0, 500, ceiling, 500,  0,      ceiling, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", Wall2.x, Wall2.y-THICK, ceiling, Wall1.x, Wall1.y-THICK, ceiling, Wall1.x, Wall1.y-THICK, floor, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", Wall1.x, Wall1.y-THICK, ceiling, Wall1.x, Wall1.y, ceiling, Wall1.x, Wall1.y,   floor, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", Wall1.x, Wall1.y, ceiling, Wall2.x, Wall2.y,   ceiling, Wall2.x, Wall2.y,   floor, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", Wall2.x, Wall2.y,   ceiling, Wall2.x, Wall2.y-THICK, ceiling, Wall2.x, Wall2.y-THICK, floor, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0,      floor, 500,  0,      floor, 0, 500,    floor, Texture); 
  fprintf(f, " }\n");
 } 

 if ((radian > 225) && (radian <= 315))
 {
  fprintf(f, " {\n");
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0, ceiling, 0, 500, ceiling, 500,  0,      ceiling, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n",  Wall2.x+THICK, Wall2.y, ceiling, Wall1.x+THICK, Wall1.y, ceiling,  Wall1.x+THICK, Wall1.y, floor, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n",  Wall1.x+THICK, Wall1.y, ceiling, Wall1.x, Wall1.y, ceiling, Wall1.x, Wall1.y, floor, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n",  Wall1.x, Wall1.y, ceiling, Wall2.x, Wall2.y, ceiling, Wall2.x, Wall2.y, floor, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n",  Wall2.x, Wall2.y, ceiling, Wall2.x+THICK, Wall2.y, ceiling, Wall2.x+THICK, Wall2.y, floor, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0,      floor, 500,  0,      floor, 0, 500,    floor, Texture); 
  fprintf(f, " }\n");
 }

}
