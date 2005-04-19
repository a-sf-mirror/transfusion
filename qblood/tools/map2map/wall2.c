/*
Copyright (C) 2001-2002 BlackB, Some1, Timothy Hale

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#include "global.h"

// Writes a wall like in b2q
void AlternateWriteWall(FILE *f, const unsigned short WallNumber, const unsigned short SectorNumber, const short Plus)
{
 char Texture[10] = "";
 double radian = 0;
 wall_t Wall1, Wall2;
 int ceiling = 0, floor = 0;

 Wall1 = wall[WallNumber];
 Wall2 = wall[Wall1.point2];

 assert(Plus != 0);

 if (Plus < 0)
 {
     ceiling = sector[SectorNumber].floorz;
     floor = sector[SectorNumber].floorz + Plus;
 }
 else if (Plus > 0)
 {
     ceiling = sector[SectorNumber].ceilingz + Plus;
     floor = sector[SectorNumber].ceilingz;
 }
 else printf("Awwwwwww  FREAK OUT!\n");

if (ceiling == floor && wall[WallNumber].nextsector != -1)
{
    ceiling = sector[wall[WallNumber].nextsector].ceilingz;
    floor = sector[wall[WallNumber].nextsector].floorz;
}

 // This should be tweaked per "to" game
sprintf(Texture, TEXTUREPREFIX "tile%.4d", wall[WallNumber].picnum);

 if ((Wall1.x == Wall2.x) && (Wall1.y == Wall2.y))
 	 return; //No line to draw for wall
 
 if (ceiling == floor && wall[WallNumber].nextsector == -1)
 {
	 printf("The ceiling == the floor %d and not conected to another sector\n", WallNumber, Plus);
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
