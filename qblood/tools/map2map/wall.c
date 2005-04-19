#include "global.h"

// Secondary wall writing function, rarely called
void WriteWall(TPoint point1, TPoint point2, FILE *f, const unsigned short i)
{
 char Texture[10] = "";
 double radian = 0;

 // This should be tweaked per "to" game
sprintf(Texture, "tile%.4d", wall[i].picnum);


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
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point1.x, point1.y-1, point1.zt,   point2.x,   point2.y-1, point2.zt,   point2.x, point2.y-1, point2.zb, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point2.x, point2.y-1, point2.zt,   point2.x,   point2.y,   point2.zt,   point2.x, point2.y,   point2.zb, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point2.x, point2.y,   point2.zt,   point1.x,   point1.y, point1.zt,   point1.x, point1.y,   point1.zb, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", point1.x, point1.y, point1.zt,   point1.x,   point1.y-1, point1.zt,   point1.x, point1.y-1, point1.zb, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0, 0,     point1.zb, 500, 0,     point1.zb, 0, 500,  point2.zb, Texture);
  fprintf(f, " }\n");
 }
  
 if ((radian >= 45) & (radian <= 135))
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

 if ((radian > 135) & (radian <= 225))
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

 if ((radian > 225) & (radian <= 315))
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
