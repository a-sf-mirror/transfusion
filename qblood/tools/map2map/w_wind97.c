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

// Primary wall writing function 
void WriteWall(const TPoint point1, const TPoint point2, FILE *f, const TWall wall)
{

 double radian = 0;
 char Texture[10] = ""; 

 if ((point1.x == point2.x) && (point1.y == point2.y))
 {
//     printf("No line to draw\n");
     return; // No line to draw
 }

 if (point1.zt == point1.zb || point2.zt == point2.zb)
     return; // The ceiling is the floor

 sprintf(Texture, TEXTUREPREFIX "tile%.4d", wall.texture);

 if ((point2.x != point1.x) && (point2.y != point1.y))
 {
  radian = 180 * atan2(point2.y - point1.y, point2.x - point1.x) / PI;
  
  if (radian < 0) 
      radian += 360;
 }
 
 else
 { 
  
  if (point1.x == point2.x) 
      if (point1.y > point2.y) 
          radian = 270; 
      else radian = 90;

  if (point1.y == point2.y) 
      if (point1.x > point2.x) 
          radian = 180; 
      else radian = 0;
 }


 if (((radian >= 0) && (radian < 45)) || (radian > 315))
 {
  fprintf(f, " {\n");                                                        
  WriteLine( 0, 0, point1.zt, 0, 500, point1.zt, 500, 0, point2.zt, Texture, wall, f); 
  WriteLine( point1.x, point1.y, point1.zt, point2.x, point2.y, point2.zt, point2.x, point2.y, point2.zb, Texture, wall, f);
  WriteLine( point2.x, point2.y, point2.zt, point2.x, point2.y+THICK, point2.zt, point2.x, point2.y+THICK, point2.zb, Texture, wall, f);
  WriteLine( point2.x, point2.y+THICK, point2.zt, point1.x, point1.y+THICK, point1.zt, point1.x, point1.y+THICK, point1.zb, Texture, wall, f);
  WriteLine( point1.x, point1.y+THICK, point1.zt, point1.x, point1.y, point1.zt,  point1.x, point1.y, point1.zb, Texture, wall, f);
  WriteLine( 0, 0, point1.zb, 500, 0, point1.zb, 0, 500, point2.zb, Texture, wall, f);
  fprintf(f, " }\n");
 }

 if ((radian >= 45) && (radian <= 135))
 {
  fprintf(f, " {\n");
  WriteLine( 0, 0, point1.zt, 0, 500, point1.zt, 500, 0, point2.zt, Texture, wall, f);
  WriteLine( point1.x, point1.y, point1.zt, point2.x, point2.y, point2.zt, point2.x, point2.y, point2.zb, Texture, wall, f);
  WriteLine( point2.x, point2.y, point2.zt, point2.x-THICK, point2.y, point2.zt, point2.x-THICK, point2.y, point2.zb, Texture, wall, f);  
  WriteLine( point2.x-THICK, point2.y, point2.zt, point1.x-THICK,   point1.y, point1.zt, point1.x-THICK,   point1.y, point1.zb, Texture, wall, f);
  WriteLine( point1.x-THICK,   point1.y, point1.zt, point1.x, point1.y, point1.zt, point1.x, point1.y, point1.zb, Texture, wall, f);
  WriteLine( 0, 0, point1.zb, 500, 0, point1.zb, 0, 500,  point2.zb, Texture, wall, f);
  fprintf(f, " }\n");
 }

 if ((radian > 135) && (radian <= 225))
 {
  fprintf(f, " {\n");
  WriteLine( 0, 0, point1.zt, 0, 500, point1.zt, 500, 0,  point2.zt, Texture, wall, f);
  WriteLine( point2.x, point2.y-THICK, point2.zt, point1.x, point1.y-THICK, point1.zt, point1.x, point1.y-THICK, point1.zb, Texture, wall, f);
  WriteLine( point1.x, point1.y-THICK, point1.zt, point1.x, point1.y, point1.zt, point1.x, point1.y,   point1.zb, Texture, wall, f);
  WriteLine( point1.x, point1.y, point1.zt, point2.x, point2.y,  point2.zt, point2.x, point2.y,   point2.zb, Texture, wall, f);
  WriteLine( point2.x, point2.y,  point2.zt, point2.x, point2.y-THICK, point2.zt, point2.x, point2.y-THICK, point2.zb, Texture, wall, f);
  WriteLine( 0, 0,  point1.zb, 500, 0,  point1.zb, 0, 500, point2.zb, Texture, wall, f);
  fprintf(f, " }\n");
 } 

 if ((radian > 225) && (radian <= 315))
 {
  fprintf(f, " {\n");
  WriteLine( 0, 0, point1.zt, 0, 500, point1.zt, 500, 0,  point2.zt, Texture, wall, f);
  WriteLine(  point2.x+THICK, point2.y, point2.zt, point1.x+THICK, point1.y, point1.zt,  point1.x+THICK, point1.y, point1.zb, Texture, wall, f);
  WriteLine(  point1.x+THICK, point1.y, point1.zt, point1.x, point1.y, point1.zt, point1.x, point1.y, point1.zb, Texture, wall, f);
  WriteLine(  point1.x, point1.y, point1.zt, point2.x, point2.y, point2.zt, point2.x, point2.y, point2.zb, Texture, wall, f);
  WriteLine(  point2.x, point2.y, point2.zt, point2.x+THICK, point2.y, point2.zt, point2.x+THICK, point2.y, point2.zb, Texture, wall, f);
  WriteLine( 0, 0,  point1.zb, 500, 0,  point1.zb, 0, 500, point2.zb, Texture, wall, f);
  fprintf(f, " }\n");
 }

}

// Writeline circumvents having to use fprintf and it's formating in the text repetatively
void WriteLine(long x1, long y1, long z1, long x2, long y2, long z2, long x3, long y3, long z3, char *Texture, TWall wall, FILE *f)
{
// Testing- the w.x_scale and w.y_scale are borked, probably from me...
//  fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s %d %d %d %1.2f %1.2f %d %d %d\n",

 fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s %d %d %d 1.0 1.0 %d %d %d\n", 
  x1, y1, z1, x2, y2, z2, x3, y3, z3, Texture,  wall.x_off, wall.y_off, 
  wall.rot_angle, /* wall.x_scale, wall.y_scale,*/ wall.content_a, wall.surface_a, wall.light_v);
}

// Writes a flat sprite (i.e. Painting, Switch, etc)
void WriteFlatSprite(const unsigned short i, const long width, const long height, 
                     TWall wall, FILE *f)
{
 
 long x1, x2, y1, y2, nx1, nx2, nx3, nx4, ny1, ny2, ny3, ny4, z;
 char Texture[10] = "";
 
 z = sprite[i].z;

 sprintf(Texture, TEXTUREPREFIX "tile%.4d", wall.texture);

 x1 = -1 * (width / 2); // Divide height + width by 2 to spread the shape evenly
 x2 = width / 2;

 y1 = height / 2;
 y2 = -1 * (height / 2);
 
 // ==> px fer lag <== //
 nx1 = sprite[i].x + x1;
 ny1 = sprite[i].y + y1;
 nx2 = sprite[i].x + x1;
 ny2 = sprite[i].y + y2;
 nx3 = sprite[i].x + x2;
 ny3 = sprite[i].y + y2;
 nx4 = sprite[i].x + x2;
 ny4 = sprite[i].y + y1;

 wall.x_off = z + 10;


 // "sfx/blackness" in lines 2, 3, 4, 5 was replaced with Texture. Lotsa testing needed still
 fprintf(f, "{\n");                                                        
 WriteLine(0, 0, z+10, 0, 500, z+10, 500, 0, z+10, Texture, wall, f); 
 WriteLine( nx1, ny1, z+10,  nx2, ny2, z+10,  nx2, ny2, z-10, Texture, wall, f);
 WriteLine( nx2, ny2, z+10,  nx3, ny3, z+10,  nx3, ny3, z-10, Texture, wall, f);
 WriteLine( nx3, ny3, z+10,  nx4, ny4, z+10,  nx4, ny4, z-10, Texture, wall, f);
 WriteLine( nx4, ny4, z+10,  nx1, ny1, z+10,  nx1, ny1, z-10, Texture, wall, f);
 WriteLine(0, 0, z-10, 500, 0, z-10, 0, 500, z-10, Texture, wall, f);
 fprintf(f, "}\n");
 
}
