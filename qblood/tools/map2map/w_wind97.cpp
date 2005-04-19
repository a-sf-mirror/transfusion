#include "global.h"

/* Writeline circumvents having to use fprintf and it's formating in the text repetatively 
   This is the file for the flat sprites	 
*/
inline void WriteLine(long x1, long y1, long z1, long x2, long y2, long z2, long x3, long y3, long z3, char *Texture, TWall w, FILE *f);

void W_Wall(TPoint p1, TPoint p2, FILE *f, TWall w)
{
// printf("Writing Wall:");
 long   Ti;
 double rad;
 char Texture[256] = ""; // s[256]

 if ((p1.x == p2.x) & (p1.y == p2.y)) return;
 if (p1.zt == p1.zb) return; //p1.zb--;
 if (p2.zt == p2.zb) return; //p2.zb--;

 for (Ti = 0; Ti < 256; Ti++) Texture[Ti] = '\0';
 sprintf(Texture, "tile%.4d", w.texture);

 if ((p2.x != p1.x) & (p2.y != p1.y))
 {
  rad = 180 * atan2(p2.y-p1.y, p2.x-p1.x) / PI;
  if (rad < 0) rad += 360;
 } else
 {
  if (p1.x == p2.x) if (p1.y > p2.y) rad = 270; else rad = 90;
  if (p1.y == p2.y) if (p1.x > p2.x) rad = 180; else rad = 0;
 }

// w.x_off, w.y_off, w.rot_angle, w.x_scale, w.y_scale, w.content_a, w.surface_a, w.light_v,

/*
 if (((rad >= 0) & (rad < 45)) ^ (rad > 315))
 {
  fprintf(f, " {\n");                                                        

  WriteLine(0, 0, p1.zt, 0, 500, p1.zt, 500, 0, p2.zt, Texture, w, f); 
  WriteLine( p1.x, p1.y-1, p1.zt,   p2.x,   p2.y-1, p2.zt,   p2.x, p2.y-1, p2.zb, Texture, w, f);
  WriteLine( p2.x, p2.y-1, p2.zt,   p2.x,   p2.y,   p2.zt,   p2.x, p2.y,   p2.zb, Texture, w, f);
  WriteLine( p2.x, p2.y,   p2.zt,   p1.x,   p1.y,   p1.zt,   p1.x, p1.y,   p1.zb, Texture, w, f);
  WriteLine( p1.x, p1.y,   p1.zt,   p1.x,   p1.y-1, p1.zt,   p1.x, p1.y-1, p1.zb, Texture, w, f);
  WriteLine( 0,    0,      p1.zb,   500,    0,      p1.zb,   0,    500,    p2.zb, Texture, w, f);
  fprintf(f, " }\n");
 }
*/

 if (((rad >= 0) & (rad < 45)) ^ (rad > 315))
 {
  fprintf(f, " {\n");                                                        

  WriteLine(0, 0, p1.zt, 0, 500, p1.zt, 500, 0, p2.zt, Texture, w, f); 
  WriteLine( p1.x, p1.y-1+1, p1.zt,   p2.x,   p2.y-1+1, p2.zt,   p2.x, p2.y-1+1, p2.zb, Texture, w, f);
  WriteLine( p2.x, p2.y-1+1, p2.zt,   p2.x,   p2.y+1,   p2.zt,   p2.x, p2.y+1,   p2.zb, Texture, w, f);
  WriteLine( p2.x, p2.y+1,   p2.zt,   p1.x,   p1.y+1,   p1.zt,   p1.x, p1.y+1,   p1.zb, Texture, w, f);
  WriteLine( p1.x, p1.y+1,   p1.zt,   p1.x,   p1.y-1+1, p1.zt,   p1.x, p1.y-1+1, p1.zb, Texture, w, f);
  WriteLine( 0,    0,      p1.zb,   500,    0,      p1.zb,   0,    500,    p2.zb, Texture, w, f);
  fprintf(f, " }\n");
 }

/*  Nezinau Kada Reminau
 if ((rad >= 45) & (rad <= 135))
 {
  fprintf(f, " {\n");
  WriteLine( 0,      0,     p1.zt, 0,      500,   p1.zt, 500,    0,    p2.zt, Texture, w, f);
  WriteLine( p1.x+1, p1.y,  p1.zt, p2.x+1, p2.y,  p2.zt, p2.x+1, p2.y, p2.zb, Texture, w, f);
  WriteLine( p2.x+1, p2.y,  p2.zt, p2.x,   p2.y,  p2.zt, p2.x,   p2.y, p2.zb, Texture, w, f);  
  WriteLine( p2.x,   p2.y,  p2.zt, p1.x,   p1.y,  p1.zt, p1.x,   p1.y, p1.zb, Texture, w, f);
  WriteLine( p1.x,   p1.y,  p1.zt, p1.x+1, p1.y,  p1.zt, p1.x+1, p1.y, p1.zb, Texture, w, f);
  WriteLine( 0,      0,     p1.zb, 500,    0,     p1.zb, 0,      500,  p2.zb, Texture, w, f);
  fprintf(f, " }\n");
 }
*/

 if ((rad >= 45) & (rad <= 135))
 {
  fprintf(f, " {\n");
  WriteLine( 0,      0,     p1.zt, 0,      500,   p1.zt, 500,    0,    p2.zt, Texture, w, f);
  WriteLine( p1.x+1-1, p1.y,  p1.zt, p2.x+1-1, p2.y,  p2.zt, p2.x+1-1, p2.y, p2.zb, Texture, w, f);
  WriteLine( p2.x+1-1, p2.y,  p2.zt, p2.x-1,   p2.y,  p2.zt, p2.x-1,   p2.y, p2.zb, Texture, w, f);  
  WriteLine( p2.x-1,   p2.y,  p2.zt, p1.x-1,   p1.y,  p1.zt, p1.x-1,   p1.y, p1.zb, Texture, w, f);
  WriteLine( p1.x-1,   p1.y,  p1.zt, p1.x+1-1, p1.y,  p1.zt, p1.x+1-1, p1.y, p1.zb, Texture, w, f);
  WriteLine( 0,      0,     p1.zb, 500,    0,     p1.zb, 0,      500,  p2.zb, Texture, w, f);
  fprintf(f, " }\n");
 }

 if ((rad > 135) & (rad <= 225))
 {
  fprintf(f, " {\n");
  WriteLine( 0,    0,      p1.zt, 0,    500,    p1.zt, 500,  0,      p2.zt, Texture, w, f);
  WriteLine( p2.x, p2.y-1, p2.zt, p1.x, p1.y-1, p1.zt, p1.x, p1.y-1, p1.zb, Texture, w, f);
  WriteLine( p1.x, p1.y-1, p1.zt, p1.x, p1.y,   p1.zt, p1.x, p1.y,   p1.zb, Texture, w, f);
  WriteLine( p1.x, p1.y,   p1.zt, p2.x, p2.y,   p2.zt, p2.x, p2.y,   p2.zb, Texture, w, f);
  WriteLine( p2.x, p2.y,   p2.zt, p2.x, p2.y-1, p2.zt, p2.x, p2.y-1, p2.zb, Texture, w, f);
  WriteLine( 0,    0,      p1.zb, 500,  0,      p1.zb, 0,    500,    p2.zb, Texture, w, f);
  fprintf(f, " }\n");
 } 

 if ((rad > 225) & (rad <= 315))
 {
  fprintf(f, " {\n");
  WriteLine( 0,    0,      p1.zt, 0,    500,    p1.zt, 500,  0,      p2.zt, Texture, w, f);
  WriteLine(  p2.x+1, p2.y, p2.zt, p1.x+1, p1.y, p1.zt,  p1.x+1, p1.y, p1.zb, Texture, w, f);
  WriteLine(  p1.x+1, p1.y, p1.zt, p1.x, p1.y, p1.zt, p1.x, p1.y, p1.zb, Texture, w, f);
  WriteLine(  p1.x, p1.y, p1.zt, p2.x, p2.y, p2.zt, p2.x, p2.y, p2.zb, Texture, w, f);
  WriteLine(  p2.x, p2.y, p2.zt, p2.x+1, p2.y, p2.zt, p2.x+1, p2.y, p2.zb, Texture, w, f);
  WriteLine( 0,    0,      p1.zb, 500,  0,      p1.zb, 0,    500,    p2.zb, Texture, w, f);
  fprintf(f, " }\n");
 }

}

inline void WriteLine(long x1, long y1, long z1, long x2, long y2, long z2, long x3, long y3, long z3, char *Texture, TWall w, FILE *f)
{
// Testing- the w.x_scale and w.y_scale are borked, probably from me...
  //fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s %d %d %d %1.2f %1.2f %d %d %d\n",

  fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s %d %d %d 1.0 1.0 %d %d %d\n", 
  x1, y1, z1, x2, y2, z2, x3, y3, z3, Texture,  w.x_off, w.y_off, w.rot_angle, /* w.x_scale, w.y_scale, */ w.content_a, w.surface_a, w.light_v);
  

}

void W_FlatSprite(long x, long y, long z, long angle, long width, long height, TWall w, FILE *f)
{
 
 long x1, x2, x3, x4, y1, y2, y3, y4, nx1, nx2, nx3, nx4, ny1, ny2, ny3, ny4;
 char Texture[10] = ""; // s[256]
 
 //printf("Flat Sprites:");
 sprintf(Texture, "tile%.4d", w.texture);
 angle = (angle + 1024) % 2048;
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
 fprintf(f, " {\n");                                                        
 WriteLine(0, 0, z+1, 0, 500, z+1, 500, 0, z+1, Texture, w, f); 
 WriteLine( nx1, ny1, z+1,  nx2, ny2, z+1,  nx2, ny2, z, "sfx/blackness", w, f);
 WriteLine( nx2, ny2, z+1,  nx3, ny3, z+1,  nx3, ny3, z, "sfx/blackness", w, f);
 WriteLine( nx3, ny3, z+1,  nx4, ny4, z+1,  nx4, ny4, z, "sfx/blackness", w, f);
 WriteLine( nx4, ny4, z+1,  nx1, ny1, z+1,  nx1, ny1, z, "sfx/blackness", w, f);
 WriteLine(0, 0, z, 500, 0, z, 0, 500, z, Texture, w, f);
 fprintf(f, " }\n");
}

