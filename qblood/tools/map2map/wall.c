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

// Writes a two sided wall (connects two sectors)
void WriteTwoSidedWall(TPoint point1, TPoint point2, FILE *f, const unsigned short i)
{
 char Texture[10] = "";
 double radian = 0;
 
 // This should be tweaked per "to" game
sprintf(Texture, TEXTUREPREFIX "tile%.4d", wall[i].picnum);

 if ((point1.x == point2.x) && (point1.y == point2.y))
 {
	 printf("No line to draw for wall %d\n", i);
	 return;
 }
 
 if (point1.zt == point1.zb || point2.zt == point2.zb)
 {
	 printf("Illegal slope to draw for wall %d\n", i);
     getch(); // If I ever catch this, I'll add down to the function.
	 return;
 }
 
 // Chunk #1 - The magic that draws valid brushes
 if ((point2.x != point1.x) && (point2.y != point1.y))
 {
  radian = 180 * atan2(point2.y-point1.y, point2.x-point1.x) / PI;
  
  if (radian < 0)
	  radian += 360;

 } 
 // Chunk #2
 else
 {
  if (point1.x == point2.x) 
  { 
   if (point1.y > point2.y)
	   radian = 270; 
   else radian = 90;
  }

  if (point1.y == point2.y) 
  { 
   if (point1.x > point2.x) 
	   radian = 180; 
   else radian = 0;
  }
 }

 fprintf(f, "// x1 = %d y1 = %d x2 = %d y2 = %d\n", point1.x, point1.y, point2.x, point2.y);

 if (((radian >= 0) && (radian < 45)) || (radian > 315))
 {
  fprintf(f, " {\n");
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0, point1.zt, 0, 500, point1.zt, 500,  0,      point2.zt, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point1.x, point1.y-THICK, point1.zt,   point2.x,   point2.y-THICK, point2.zt,   point2.x, point2.y-THICK, point2.zb, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point2.x, point2.y-THICK, point2.zt,   point2.x,   point2.y,   point2.zt,   point2.x, point2.y,   point2.zb, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point2.x, point2.y,   point2.zt,   point1.x,   point1.y, point1.zt,   point1.x, point1.y,   point1.zb, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point1.x, point1.y, point1.zt,   point1.x,   point1.y-THICK, point1.zt,   point1.x, point1.y-THICK, point1.zb, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0,     point1.zb, 500, 0,     point1.zb, 0, 500,  point2.zb, Texture);
  fprintf(f, " }\n");
 }
  
 if ((radian >= 45) && (radian <= 135))
 {
  fprintf(f, " {\n");
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0, point1.zt, 0, 500, point1.zt, 500, 0,    point2.zt, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point1.x+THICK, point1.y, point1.zt, point2.x+THICK, point2.y,  point2.zt, point2.x+THICK, point2.y, point2.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point2.x+THICK, point2.y,  point2.zt, point2.x,   point2.y,  point2.zt, point2.x,   point2.y, point2.zb, Texture);   
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point2.x,   point2.y,  point2.zt, point1.x,   point1.y, point1.zt, point1.x,   point1.y, point1.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point1.x,   point1.y, point1.zt, point1.x+THICK, point1.y, point1.zt, point1.x+THICK, point1.y, point1.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0,     point1.zb, 500, 0,     point1.zb, 0, 500,  point2.zb, Texture); 
  fprintf(f, " }\n");
 }

 if ((radian > 135) && (radian <= 225))
 {
  fprintf(f, " {\n");
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0, point1.zt, 0, 500, point1.zt, 500,  0,      point2.zt, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point2.x, point2.y-THICK, point2.zt, point1.x, point1.y-THICK, point1.zt, point1.x, point1.y-THICK, point1.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point1.x, point1.y-THICK, point1.zt, point1.x, point1.y, point1.zt, point1.x, point1.y,   point1.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point1.x, point1.y, point1.zt, point2.x, point2.y,   point2.zt, point2.x, point2.y,   point2.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point2.x, point2.y,   point2.zt, point2.x, point2.y-THICK, point2.zt, point2.x, point2.y-THICK, point2.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0,      point1.zb, 500,  0,      point1.zb, 0, 500,    point2.zb, Texture); 
  fprintf(f, " }\n");
 } 

 if ((radian > 225) && (radian <= 315))
 {
  fprintf(f, " {\n");
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0, point1.zt, 0, 500, point1.zt, 500,  0,      point2.zt, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n",  point2.x+THICK, point2.y, point2.zt, point1.x+THICK, point1.y, point1.zt,  point1.x+THICK, point1.y, point1.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n",  point1.x+THICK, point1.y, point1.zt, point1.x, point1.y, point1.zt, point1.x, point1.y, point1.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n",  point1.x, point1.y, point1.zt, point2.x, point2.y, point2.zt, point2.x, point2.y, point2.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n",  point2.x, point2.y, point2.zt, point2.x+THICK, point2.y, point2.zt, point2.x+THICK, point2.y, point2.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0,      point1.zb, 500,  0,      point1.zb, 0, 500,    point2.zb, Texture); 
  fprintf(f, " }\n");
 }
 
} // WriteTwoSidedWall
