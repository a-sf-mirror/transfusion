#include "global.h"

// Alternate
void W_Wall(TPoint point1, TPoint point2, FILE *f, TWall wall)
{

 double rad = 0;
 char Texture[10] = ""; 

 if ((point1.x == point2.x) && (point1.y == point2.y)) 
     return; // No line to draw

 if (point1.zt == point1.zb) 
     return; // The ceiling is the floor - very bad
 
 if (point2.zt == point2.zb) 
     return; // The ceiling is the floor - very bad 

 sprintf(Texture, "tile%.4d", wall.texture);

 if ((point2.x != point1.x) && (point2.y != point1.y))
 {
  rad = 180 * atan2(point2.y-point1.y, point2.x-point1.x) / PI;
  
  if (rad < 0) 
      rad += 360;
 }
 
 else
 { 
  
  // Fragile, but functional. Caused a big logic bug when I messed with it.
  if (point1.x == point2.x) 
      if (point1.y > point2.y) 
          rad = 270; 
      else rad = 90;

  if (point1.y == point2.y) 
      if (point1.x > point2.x) 
          rad = 180; 
      else rad = 0;
 }

// um, why -1+1 ??? 0 and 500 again, why???
 if (((rad >= 0) && (rad < 45)) || (rad > 315))
 {
  fprintf(f, " {\n");                                                        
  WriteLine( 0, 0, point1.zt, 0, 500, point1.zt, 500, 0, point2.zt, Texture, wall, f); 
  WriteLine( point1.x, point1.y-1+1, point1.zt, point2.x, point2.y-1+1, point2.zt, point2.x, point2.y-1+1, point2.zb, Texture, wall, f);
  WriteLine( point2.x, point2.y-1+1, point2.zt, point2.x, point2.y+1, point2.zt, point2.x, point2.y+1, point2.zb, Texture, wall, f);
  WriteLine( point2.x, point2.y+1, point2.zt, point1.x, point1.y+1, point1.zt, point1.x, point1.y+1, point1.zb, Texture, wall, f);
  WriteLine( point1.x, point1.y+1, point1.zt, point1.x, point1.y-1+1, point1.zt,  point1.x, point1.y-1+1, point1.zb, Texture, wall, f);
  WriteLine( 0, 0, point1.zb, 500, 0, point1.zb, 0, 500, point2.zb, Texture, wall, f);
  fprintf(f, " }\n");
 }

 if ((rad >= 45) && (rad <= 135))
 {
  fprintf(f, " {\n");
  WriteLine( 0, 0, point1.zt, 0, 500, point1.zt, 500, 0, point2.zt, Texture, wall, f);
  WriteLine( point1.x+1-1, point1.y, point1.zt, point2.x+1-1, point2.y, point2.zt, point2.x+1-1, point2.y, point2.zb, Texture, wall, f);
  WriteLine( point2.x+1-1, point2.y, point2.zt, point2.x-1, point2.y, point2.zt, point2.x-1, point2.y, point2.zb, Texture, wall, f);  
  WriteLine( point2.x-1, point2.y, point2.zt, point1.x-1,   point1.y, point1.zt, point1.x-1,   point1.y, point1.zb, Texture, wall, f);
  WriteLine( point1.x-1,   point1.y, point1.zt, point1.x+1-1, point1.y, point1.zt, point1.x+1-1, point1.y, point1.zb, Texture, wall, f);
  WriteLine( 0, 0,     point1.zb, 500, 0,     point1.zb, 0, 500,  point2.zb, Texture, wall, f);
  fprintf(f, " }\n");
 }

 if ((rad > 135) && (rad <= 225))
 {
  fprintf(f, " {\n");
  WriteLine( 0, 0, point1.zt, 0,    500, point1.zt, 500,  0,  point2.zt, Texture, wall, f);
  WriteLine( point2.x, point2.y-1, point2.zt, point1.x, point1.y-1, point1.zt, point1.x, point1.y-1, point1.zb, Texture, wall, f);
  WriteLine( point1.x, point1.y-1, point1.zt, point1.x, point1.y, point1.zt, point1.x, point1.y,   point1.zb, Texture, wall, f);
  WriteLine( point1.x, point1.y, point1.zt, point2.x, point2.y,  point2.zt, point2.x, point2.y,   point2.zb, Texture, wall, f);
  WriteLine( point2.x, point2.y,  point2.zt, point2.x, point2.y-1, point2.zt, point2.x, point2.y-1, point2.zb, Texture, wall, f);
  WriteLine( 0, 0,      point1.zb, 500,  0,      point1.zb, 0,    500,    point2.zb, Texture, wall, f);
  fprintf(f, " }\n");
 } 

 if ((rad > 225) && (rad <= 315))
 {
  fprintf(f, " {\n");
  WriteLine( 0, 0, point1.zt, 0,    500, point1.zt, 500,  0,  point2.zt, Texture, wall, f);
  WriteLine(  point2.x+1, point2.y, point2.zt, point1.x+1, point1.y, point1.zt,  point1.x+1, point1.y, point1.zb, Texture, wall, f);
  WriteLine(  point1.x+1, point1.y, point1.zt, point1.x, point1.y, point1.zt, point1.x, point1.y, point1.zb, Texture, wall, f);
  WriteLine(  point1.x, point1.y, point1.zt, point2.x, point2.y, point2.zt, point2.x, point2.y, point2.zb, Texture, wall, f);
  WriteLine(  point2.x, point2.y, point2.zt, point2.x+1, point2.y, point2.zt, point2.x+1, point2.y, point2.zb, Texture, wall, f);
  WriteLine( 0, 0,      point1.zb, 500,  0,      point1.zb, 0,    500,    point2.zb, Texture, wall, f);
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
  wall.rot_angle, /* w.x_scale, w.y_scale,*/ wall.content_a, wall.surface_a, wall.light_v);
}

// Called in item.c, to write a flat sprite
void W_FlatSprite(long x, long y, long z, long angle, long width, long height, TWall wall, FILE *f)
{
 
 long x1, x2, x3, x4, y1, y2, y3, y4, nx1, nx2, nx3, nx4, ny1, ny2, ny3, ny4;
 char Texture[10] = "";
  
 sprintf(Texture, "tile%.4d", wall.texture);
 x4 = width / 2;
 x3 = width / 2;
 x2 = -1 * (width / 2);
 x1 = -1 * (width / 2);
 y1 = height / 2;
 y4 = height / 2;
 y2 = -1 * (height / 2);
 y3 = -1 * (height / 2);
 // ==> px fer lag <== //
 nx1 = x + x1*cos(angle*(PI*2)/2048)-y1*sin(angle*(PI*2)/2048);
 ny1 = y + x1*sin(angle*(PI*2)/2048)+y1*cos(angle*(PI*2)/2048);
 nx2 = x + x2*cos(angle*(PI*2)/2048)-y2*sin(angle*(PI*2)/2048);
 ny2 = y + x2*sin(angle*(PI*2)/2048)+y2*cos(angle*(PI*2)/2048);
 nx3 = x + x3*cos(angle*(PI*2)/2048)-y3*sin(angle*(PI*2)/2048);
 ny3 = y + x3*sin(angle*(PI*2)/2048)+y3*cos(angle*(PI*2)/2048);
 nx4 = x + x4*cos(angle*(PI*2)/2048)-y4*sin(angle*(PI*2)/2048);
 ny4 = y + x4*sin(angle*(PI*2)/2048)+y4*cos(angle*(PI*2)/2048);
 fprintf(f, "{\n");                                                        
 WriteLine(0, 0, z+1, 0, 500, z+1, 500, 0, z+1, Texture, wall, f); 
 WriteLine( nx1, ny1, z+1,  nx2, ny2, z+1,  nx2, ny2, z, "sfx/blackness", wall, f);
 WriteLine( nx2, ny2, z+1,  nx3, ny3, z+1,  nx3, ny3, z, "sfx/blackness", wall, f);
 WriteLine( nx3, ny3, z+1,  nx4, ny4, z+1,  nx4, ny4, z, "sfx/blackness", wall, f);
 WriteLine( nx4, ny4, z+1,  nx1, ny1, z+1,  nx1, ny1, z, "sfx/blackness", wall, f);
 WriteLine(0, 0, z, 500, 0, z, 0, 500, z, Texture, wall, f);
 fprintf(f, "}\n");
}
