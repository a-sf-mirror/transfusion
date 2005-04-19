#include "global.h"

// What is this for? 
short G_2va(long x1, long y1, long x2, long y2, long &x, long &y)
{
 double x_1, y_1, x_2, y_2, v1x, v1y, v2x, v2y, k, sinq;

 v1x = x2 - x1;
 v1y = y2 - y1;

 if (v1x == 0) 
	 v1x = 1;

 y_1 = 0.5/(v1y*v1y+v1x*v1x)*
     (2.0*y1*v1x*v1x+2.0*v1y*v1y*y1+200.0*
     sqrt(v1y*v1y*v1x*v1x+v1x*v1x*v1x*v1x));

 x_1 = (v1x*x1-v1y*y_1+v1y*y1) / v1x;

 y_2 = 0.5/(v1y*v1y+v1x*v1x)*
     (2.0*y1*v1x*v1x+2.0*v1y*v1y*y1-200.0*
     sqrt(v1y*v1y*v1x*v1x+v1x*v1x*v1x*v1x));

 x_2 = (v1x*x1-v1y*y_2+v1y*y1) / v1x;

 v2x  = x_1 - x1;
 v2y  = y_1 - y1;                    
 k    = v1x*v2y - v1y*v2x;
 sinq = k / (sqrt(v1x*v1x + v1y*v1y) * sqrt(v2x*v2x + v2y*v2y));

 if (sinq == -1)
 {
  x = x_1;
  y = y_1; 
 } else
 {
  x = x_2;
  y = y_2; 
 }

 if (v1x == 0) 
	 return 1; 
 
 else return 0;
}

long GetZ(double p1x, double p1y, double p3x, double p3y, double Z, double angle)
{
 long h = tan(angle) * sqrt((p3x-p1x)*(p3x-p1x) + (p3y-p1y)*(p3y-p1y));
 return Z + h; 
}

// This will test how complicated a sector is
short TestAngles(long SectorNumber)
{
 double TotalA, Test_A, rad;
 TPoint vertex1, vertex2;
 long walls = 0, j, wallpointer, TimeOut = 1000;
 
 j = wallpointer = sector[SectorNumber].wallptr;
   
 do 
 {
  j = wall[j].point2;
  walls++; TimeOut--;
 } while ( (j != wallpointer) && (TimeOut > 0) );

 TotalA = 180 * (walls-2);
 Test_A = 0;
 wallpointer = sector[SectorNumber].wallptr;
 j   = wallpointer; TimeOut = 1000;
 do 
 {
  vertex1.x = wall[j].x - wall[wall[j].point2].x;
  vertex1.y = wall[j].y - wall[wall[j].point2].y;
  vertex2.x = wall[wall[wall[j].point2].point2].x - wall[wall[j].point2].x;
  vertex2.y = wall[wall[wall[j].point2].point2].y - wall[wall[j].point2].y;

  rad = acos((vertex1.x*vertex2.x + vertex1.y*vertex2.y) / 
      ((sqrt(vertex1.x*vertex1.x + vertex1.y*vertex1.y) * 
      sqrt(vertex2.x*vertex2.x + vertex2.y*vertex2.y))));
  
  Test_A += rad;
  
  j = wall[j].point2; TimeOut--;
 } while ( (j != wallpointer) && (TimeOut > 0) );
 
 Test_A = Test_A * 180 / PI;

 if ((TotalA - Test_A > -1) && (TotalA - Test_A < 1)) 
     return 0; 
 else return 1;

}

void WriteFloor(FILE *f, long SectorNumber, long Plus)
{
 char Texture[80];
 long SBot, STop, j, wallpointer; 
 TPoint p1, p2, vertex1, vertex2, v3;
 short ret, Stat;
 double Angle;

 fprintf(f, " {\n");
 Stat = sector[SectorNumber].floorstat;

 if (Plus < 0)
 {  
  SBot = sector[SectorNumber].floorz +Plus; // Floor going down
  STop = sector[SectorNumber].floorz;
 }
 else// (Plus > 0)
 {
  STop = sector[SectorNumber].floorz +Plus; // Floor going up
  SBot = sector[SectorNumber].floorz;
 }

 wallpointer = sector[SectorNumber].wallptr;
 j   = wallpointer; 

 p1.x  = wall[j].x;
 p1.y  = wall[j].y;
 p1.zt = STop;
 p2.x  = wall[j].x;
 p2.y  = wall[j].y;

 if (Stat % 2 == 1) // this indicates paralaxxing 
 sprintf(Texture, "sky1 0 0 0 1.00 1.00 0 133 1");
 else 
 sprintf(Texture, "tile%.4d 0 0 0 1.00 1.00 1 0 0", sector[SectorNumber].floorpicnum);

 if (sector[SectorNumber].floorheinum != 0) // Sloped floor
 {
 vertex1.x  = wall[j].x;
 vertex1.y  = wall[j].y;
 vertex1.zt = STop;
 vertex1.zb = STop;

 vertex2.x  = wall[wall[j].point2].x;
 vertex2.y  = wall[wall[j].point2].y;
 vertex2.zt = STop;
 vertex2.zb = STop;

 ret = G_2va(vertex1.x, vertex1.y, vertex2.x, vertex2.y, v3.x, v3.y);

 v3.zt = STop;
 v3.zb = STop;
 
 if (sector[SectorNumber].floorheinum < 0) 
	 Angle = (-1 * (sector[SectorNumber].floorheinum-512)) * PI/4/4096;
 
 else Angle = (-1 * (sector[SectorNumber].floorheinum+512)) * PI/4/4096;

 v3.zt = GetZ(vertex1.x, vertex1.y, /*vertex2.x, vertex2.y,*/ v3.x, v3.y, STop, Angle);
 v3.zb = v3.zt-10;

 if (ret == 0)
 fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1.00 1.00 1 0 0\n", vertex1.x, vertex1.y, vertex1.zt, vertex2.x, vertex2.y, vertex2.zt, v3.x, v3.y, v3.zt, Texture); 
 else
 fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 0, 0, STop, 0, 500, STop, 500, 0, STop, Texture); 
 
 } // if (sector[SectorNumber].floorheinum != 0) 
 else
 fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 0, 0, STop, 0, 500, STop, 500, 0, STop, Texture); 
 
 do 
 {
  p1.x = wall[j].x;
  p1.y = wall[j].y;
  p2.x = wall[wall[j].point2].x;
  p2.y = wall[wall[j].point2].y;
  if (wall[j].nextwall != -1) sprintf(Texture, "tile%.4d", wall[wall[j].nextwall].picnum);
   else sprintf(Texture, "tile%.4d", wall[j].picnum);
  if (Stat % 2 == 1) { fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) e1u2/sky1 0 0 0 1.00 1.00 0 133 1\n", p2.x, p2.y, 500, p1.x, p1.y, 500, p1.x, p1.y, 0, Texture);  }
     else { fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s 0 0 0 1.00 1.00 1 0 0\n", p2.x, p2.y, 500, p1.x, p1.y, 500, p1.x, p1.y, 0, Texture);  }
  j = wall[j].point2;
 } while (j != wallpointer);

#ifdef QUAKE2
 sprintf(Texture, "e1u1/skip"); // Good for quake 2, but not 1
#elif defined HALFLIFE
 sprintf(Texture, "sky"); // Should put a real dummy texture here
#elif defined QUAKE1
 sprintf(Texture, "tile0000"); // This is the qBlood dummy texture
#endif

 if (sector[SectorNumber].floorheinum != 0) 
 {
  p2.zb = STop - 100 * tan( (-1 * sector[SectorNumber].floorheinum) * PI / 4 / 4096     ) + 5;   //*PI / 91.2 )  /180)


 vertex1.x  = wall[j].x;
 vertex1.y  = wall[j].y;
 vertex1.zt = STop;
 vertex1.zb = SBot;

 vertex2.x  = wall[wall[j].point2].x;
 vertex2.y  = wall[wall[j].point2].y;
 vertex2.zt = STop;
 vertex2.zb = SBot;

 ret = G_2va(vertex1.x, vertex1.y, vertex2.x, vertex2.y, v3.x, v3.y);
 v3.zt = STop;
 v3.zb = SBot;

 v3.zt = GetZ(vertex1.x, vertex1.y, v3.x, v3.y, STop, (-1 * sector[SectorNumber].floorheinum) * PI/4/4096);
 v3.zb = v3.zt-10;

 if (v3.zb > SBot) v3.zb = SBot;
 if (p2.zb > SBot) p2.zb = SBot;

//  fprintf(f, "( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s 0 0 0 1.00 1.00 1 0 0\n", 0, 0, SBot, 500, 0, p2.zb, 0, 500, SBot, Texture); 

 if (ret == 0)
 fprintf(f, "(%d %d %d) (%d %d %d) (%d %d %d) %s 0 0 0 1.00 1.00 1 0 0\n", vertex1.x, vertex1.y, vertex1.zb, v3.x, v3.y, v3.zb, vertex2.x, vertex2.y, vertex2.zb, Texture); 
 else
 fprintf(f, "( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s 0 0 0 1.00 1.00 1 0 0\n", 0, 0, SBot, 500, 0, SBot, 0, 500, SBot, Texture); 
 
 } // if (sector[SectorNumber].floorheinum != 0)
 else
 fprintf(f, "( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s 0 0 0 1.00 1.00 1 0 0\n", 0, 0, SBot, 500, 0, SBot, 0, 500, SBot, Texture); 

 fprintf(f, "}\n");
}


// Finds a specific wall within a sector
long FindWall(long SectorNumber)
{
 long  i, j, s;
 short r;
 
 for (i = 0; i < numwalls; i++)
 {
  if (wall[wall[i].nextwall].nextsector == SectorNumber)
  {
   r = 0;
   s = sector[SectorNumber].wallptr;
   j = s; 
   do 
   {

	   if (i == j) r = 1;
    j = wall[j].point2;
   } while (j != s);
   if (r == 0) return i;
  }
 }
 return -1; // Not found
}