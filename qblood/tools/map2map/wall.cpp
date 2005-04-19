#include "global.h"
/* It is highly likely that this function will never be called? */

void WriteWall(TPoint point1, TPoint point2, FILE *f, long i)
{
 char Texture[10] = "";
 double rad = 0;

 // This should be tweaked per "to" game
 sprintf(Texture, "tile%.4d", wall[i].picnum);

 printf("XRepeat : %ld, YRepeat : %ld\n", wall[i].xrepeat, wall[i].yrepeat);

 if ((point1.x == point2.x) && (point1.y == point2.y))
 {
	 printf("No line to draw for wall %d\n", i);
	 return;
 }
 
 if (point1.zt == point1.zb || point2.zt == point2.zb)
 {
	 printf("Illegal slope to draw for wall %d\n", i);
	 return;
 }
 
 // Chunk #1 - The magic that draws valid brushes
 if ((point2.x != point1.x) && (point2.y != point1.y))
 {
  rad = 180 * atan2(point2.y-point1.y, point2.x-point1.x) / PI;
  
  if (rad < 0)
	  rad += 360;

 } 
 // Chunk #2
 else
 {
  if (point1.x == point2.x) 
  { 
   if (point1.y > point2.y)
	   rad = 270; 
   else rad = 90;
  }

  if (point1.y == point2.y) 
  { 
   if (point1.x > point2.x) 
	   rad = 180; 
   else rad = 0;
  }
 }

 fprintf(f, "// x1 = %d y1 = %d x2 = %d y2 = %d\n", point1.x, point1.y, point2.x, point2.y);

 if (((rad >= 0) && (rad < 45)) || (rad > 315))
 {
  fprintf(f, " {\n");                                                           //  if (point1.y-1 ==)
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0, point1.zt, 0, 500, point1.zt, 500,  0,      point2.zt, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point1.x, point1.y-1, point1.zt,   point2.x,   point2.y-1, point2.zt,   point2.x, point2.y-1, point2.zb, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point2.x, point2.y-1, point2.zt,   point2.x,   point2.y,   point2.zt,   point2.x, point2.y,   point2.zb, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point2.x, point2.y,   point2.zt,   point1.x,   point1.y, point1.zt,   point1.x, point1.y,   point1.zb, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point1.x, point1.y, point1.zt,   point1.x,   point1.y-1, point1.zt,   point1.x, point1.y-1, point1.zb, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0,     point1.zb, 500, 0,     point1.zb, 0, 500,  point2.zb, Texture);
  fprintf(f, " }\n");
 }
  
 if ((rad >= 45) & (rad <= 135))
 {
  fprintf(f, " {\n");
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0, point1.zt, 0, 500, point1.zt, 500, 0,    point2.zt, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point1.x+1, point1.y, point1.zt, point2.x+1, point2.y,  point2.zt, point2.x+1, point2.y, point2.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point2.x+1, point2.y,  point2.zt, point2.x,   point2.y,  point2.zt, point2.x,   point2.y, point2.zb, Texture);   
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point2.x,   point2.y,  point2.zt, point1.x,   point1.y, point1.zt, point1.x,   point1.y, point1.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point1.x,   point1.y, point1.zt, point1.x+1, point1.y, point1.zt, point1.x+1, point1.y, point1.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0,     point1.zb, 500, 0,     point1.zb, 0, 500,  point2.zb, Texture); 
  fprintf(f, " }\n");
 }

 if ((rad > 135) & (rad <= 225))
 {
  fprintf(f, " {\n");
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0, point1.zt, 0, 500, point1.zt, 500,  0,      point2.zt, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point2.x, point2.y-1, point2.zt, point1.x, point1.y-1, point1.zt, point1.x, point1.y-1, point1.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point1.x, point1.y-1, point1.zt, point1.x, point1.y, point1.zt, point1.x, point1.y,   point1.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point1.x, point1.y, point1.zt, point2.x, point2.y,   point2.zt, point2.x, point2.y,   point2.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point2.x, point2.y,   point2.zt, point2.x, point2.y-1, point2.zt, point2.x, point2.y-1, point2.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0,      point1.zb, 500,  0,      point1.zb, 0, 500,    point2.zb, Texture); 
  fprintf(f, " }\n");
 } 

 if ((rad > 225) & (rad <= 315))
 {
  fprintf(f, " {\n");
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0, point1.zt, 0, 500, point1.zt, 500,  0,      point2.zt, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n",  point2.x+1, point2.y, point2.zt, point1.x+1, point1.y, point1.zt,  point1.x+1, point1.y, point1.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n",  point1.x+1, point1.y, point1.zt, point1.x, point1.y, point1.zt, point1.x, point1.y, point1.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n",  point1.x, point1.y, point1.zt, point2.x, point2.y, point2.zt, point2.x, point2.y, point2.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n",  point2.x, point2.y, point2.zt, point2.x+1, point2.y, point2.zt, point2.x+1, point2.y, point2.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0,      point1.zb, 500,  0,      point1.zb, 0, 500,    point2.zb, Texture); 
  fprintf(f, " }\n");
 }
 
} // Writewall
