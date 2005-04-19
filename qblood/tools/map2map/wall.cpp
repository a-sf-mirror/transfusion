#include "global.h"
#define XTHICK 2
#define YTHICK -2

void WriteWall(TPoint p1, TPoint p2, FILE *f, long i)
{
 return;

 char Texture[10] = "";
 double rad;

 sprintf(Texture, "tile%.4d", wall[i].picnum);

 printf("XRepeat : %ld, YRepeat : %ld\n", wall[i].xrepeat, wall[i].yrepeat);

 if ((p1.x == p2.x) & (p1.y == p2.y)) return;

 if (p1.zt == p1.zb) return; //p1.zb--;
 if (p2.zt == p2.zb) return; //p2.zb--;


 if ((p2.x != p1.x) & (p2.y != p1.y))
 {
  rad = 180 * atan2(p2.y-p1.y, p2.x-p1.x) / PI;
  if (rad < 0) rad += 360;
 } else
 {
  if (p1.x == p2.x) 
  { 
   if (p1.y > p2.y) rad = 270; else rad = 90;
  }
  if (p1.y == p2.y) 
  { 
   if (p1.x > p2.x) rad = 180; else rad = 0;
  }
 }

 fprintf(f, "// x1 = %d y1 = %d x2 = %d y2 = %d\n", p1.x, p1.y, p2.x, p2.y);

 if (((rad >= 0) & (rad < 45)) ^ (rad > 315))
 {
  fprintf(f, " {\n");                                                           //  if (p1.y-1 ==)
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0,    0,      p1.zt,   0,      500,    p1.zt,   500,  0,      p2.zt, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p1.x, p1.y+ YTHICK, p1.zt,   p2.x,   p2.y+ YTHICK, p2.zt,   p2.x, p2.y+ YTHICK, p2.zb, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p2.x, p2.y+ YTHICK, p2.zt,   p2.x,   p2.y,   p2.zt,   p2.x, p2.y,   p2.zb, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p2.x, p2.y,   p2.zt,   p1.x,   p1.y,   p1.zt,   p1.x, p1.y,   p1.zb, Texture);
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p1.x, p1.y,   p1.zt,   p1.x,   p1.y+ YTHICK, p1.zt,   p1.x, p1.y+ YTHICK, p1.zb, Texture);
/* 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p1.x, p1.x,   p1.zt, p2.x,    p2.y,   p2.zt, p2.x,    p2.y,   p2.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p2.x, p2.y,   p2.zt, p2.x,    p2.y+1, p2.zt, p2.x,    p2.y+1, p2.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p2.x, p2.y+1, p2.zt, p1.x,    p1.y+1, p1.zt, p1.x,    p1.y+1, p1.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p1.x, p1.y+1, p1.zt, p1.x,    p1.y,   p1.zt, p1.x,    p1.y,   p1.zb, Texture); 
*/
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0,      0,     p1.zb, 500,    0,     p1.zb, 0,      500,  p2.zb, Texture);
  fprintf(f, " }\n");
 }
  
 if ((rad >= 45) & (rad <= 135))
 {
  fprintf(f, " {\n");
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0,      0,     p1.zt, 0,      500,   p1.zt, 500,    0,    p2.zt, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p1.x+ XTHICK, p1.y,  p1.zt, p2.x+ XTHICK, p2.y,  p2.zt, p2.x+ XTHICK, p2.y, p2.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p2.x+ XTHICK, p2.y,  p2.zt, p2.x,   p2.y,  p2.zt, p2.x,   p2.y, p2.zb, Texture);   
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p2.x,   p2.y,  p2.zt, p1.x,   p1.y,  p1.zt, p1.x,   p1.y, p1.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p1.x,   p1.y,  p1.zt, p1.x+ XTHICK, p1.y,  p1.zt, p1.x+ XTHICK, p1.y, p1.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0,      0,     p1.zb, 500,    0,     p1.zb, 0,      500,  p2.zb, Texture); 
  fprintf(f, " }\n");
 }

 if ((rad > 135) & (rad <= 225))
 {
  fprintf(f, " {\n");
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0,    0,      p1.zt, 0,    500,    p1.zt, 500,  0,      p2.zt, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p2.x, p2.y+ YTHICK, p2.zt, p1.x, p1.y+ YTHICK, p1.zt, p1.x, p1.y+ YTHICK, p1.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p1.x, p1.y+ YTHICK, p1.zt, p1.x, p1.y,   p1.zt, p1.x, p1.y,   p1.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p1.x, p1.y,   p1.zt, p2.x, p2.y,   p2.zt, p2.x, p2.y,   p2.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", p2.x, p2.y,   p2.zt, p2.x, p2.y+ YTHICK, p2.zt, p2.x, p2.y+ YTHICK, p2.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0,    0,      p1.zb, 500,  0,      p1.zb, 0,    500,    p2.zb, Texture); 
  fprintf(f, " }\n");
 } 

 if ((rad > 225) & (rad <= 315))
 {
  fprintf(f, " {\n");
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0,    0,      p1.zt, 0,    500,    p1.zt, 500,  0,      p2.zt, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n",  p2.x+ XTHICK, p2.y, p2.zt, p1.x+ XTHICK, p1.y, p1.zt,  p1.x+ XTHICK, p1.y, p1.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n",  p1.x+ XTHICK, p1.y, p1.zt, p1.x, p1.y, p1.zt, p1.x, p1.y, p1.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n",  p1.x, p1.y, p1.zt, p2.x, p2.y, p2.zt, p2.x, p2.y, p2.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n",  p2.x, p2.y, p2.zt, p2.x+ XTHICK, p2.y, p2.zt, p2.x+ XTHICK, p2.y, p2.zb, Texture); 
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1 1 1 0 0\n", 0,    0,      p1.zb, 500,  0,      p1.zb, 0,    500,    p2.zb, Texture); 
  fprintf(f, " }\n");
 }
/*

 long x1, y1, x2, y2, STop, SBot, T;

 STop = p2.zt;
 SBot = p2.zb;

 if (p1.y < p2.y)
 {
  x1 = p1.x;
  x2 = p2.x;
  y1 = p1.y;
  y2 = p2.y;
 } else
 {
  x1 = p2.x;
  x2 = p1.x;
  y1 = p2.y;
  y2 = p1.y;
 }

 if (y1 != y2)
 {
  fprintf(f, " {\n");
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1, y1, STop, x2, y2, STop, x1 +1, y1, STop);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1 +1, y1, SBot, x1 +1, y1, STop, x2 +1, y2, SBot);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1, y1, SBot, x1, y1, STop, x1+1, y1, SBot);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1, y1, SBot, x2, y2, SBot, x1, y1, STop);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x2, y2, SBot, x2 +1, y2, SBot, x2, y2, STop);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1, y1, SBot, x1 +1, y1, SBot, x2, y2, SBot);
  fprintf(f, " }\n");
 } else
 {
  if (x1 < x2)
  {
   T = x2;
   x2 = x1;
   x1 = T;
  }
  fprintf(f, " {\n");
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1, y1, STop, x2, y2, STop, x1, y1+1, STop);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1 , y1+1, SBot, x1, y1+1, STop, x2 , y2+1, SBot);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1, y1, SBot, x1, y1, STop, x1, y1+1, SBot);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1, y1, SBot, x2, y2, SBot, x1, y1, STop);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x2, y2, SBot, x2, y2+1, SBot, x2, y2, STop);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1, y1, SBot, x1, y1+1, SBot, x2, y2, SBot);
  fprintf(f, " }\n");
 }
 */ 
}

/*
void WriteWall(TPoint p1, TPoint p2, FILE *f)
{
 long x1, y1, x2, y2, STop, SBot, T;

 STop = p2.zt;
 SBot = p2.zb;

 if (p1.y < p2.y)
 {
  x1 = p1.x;
  x2 = p2.x;
  y1 = p1.y;
  y2 = p2.y;
 } else
 {
  x1 = p2.x;
  x2 = p1.x;
  y1 = p2.y;
  y2 = p1.y;
 }

 if (y1 != y2)
 {
  fprintf(f, " {\n");
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1, y1, STop, x2, y2, STop, x1 +1, y1, STop);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1 +1, y1, SBot, x1 +1, y1, STop, x2 +1, y2, SBot);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1, y1, SBot, x1, y1, STop, x1+1, y1, SBot);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1, y1, SBot, x2, y2, SBot, x1, y1, STop);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x2, y2, SBot, x2 +1, y2, SBot, x2, y2, STop);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1, y1, SBot, x1 +1, y1, SBot, x2, y2, SBot);
  fprintf(f, " }\n");
 } else
 {
  if (x1 < x2)
  {
   T = x2;
   x2 = x1;
   x1 = T;
  }
  fprintf(f, " {\n");
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1, y1, STop, x2, y2, STop, x1, y1+1, STop);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1 , y1+1, SBot, x1, y1+1, STop, x2 , y2+1, SBot);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1, y1, SBot, x1, y1, STop, x1, y1+1, SBot);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1, y1, SBot, x2, y2, SBot, x1, y1, STop);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x2, y2, SBot, x2, y2+1, SBot, x2, y2, STop);
  fprintf(f, "  ( %d  %d  %d ) ( %d  %d  %d ) ( %d  %d  %d ) e2u3/blume7_2 0 0 0 1 1 1 0 0\n", x1, y1, SBot, x1, y1+1, SBot, x2, y2, SBot);
  fprintf(f, " }\n");
 } 
} 
*/
