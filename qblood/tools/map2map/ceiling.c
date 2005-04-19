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

// Write a sector's ceiling
void WriteCeiling(FILE *f, const unsigned short SectorNumber, short Plus)
{
 char Texture[256]="";
 
 long CeilingBottom, CeilingTop, j, wallpointer; 
 TPoint point1, point2, vertex1, vertex2, vertex3;
 short ret, k;

 short Stat = sector[SectorNumber].ceilingstat;
  
 // To avoid compiler gripes, initializing vertex3
 vertex3.x = vertex3.y = vertex3.zb = vertex3.zt = 0;

 // To help avoid microbrushes, there's probably a smarter way to do this
 if (Plus == 1)
     Plus = THICK;
 
 if (Plus == -1)
     Plus = -THICK;

 CeilingBottom = sector[SectorNumber].ceilingz;
 CeilingTop = sector[SectorNumber].ceilingz +Plus;
 
 if (CeilingTop == CeilingBottom)
     CeilingBottom -=THICK;
     //return; // Nothing to do

 // Just in case...
 if (CeilingTop < CeilingBottom)
     SWAP(CeilingTop, CeilingBottom);

 j = wallpointer = sector[SectorNumber].wallptr;
 
 point1.zt = CeilingTop;
   
 fprintf(f, "{\n");

    if (Stat % 2 == 1) // This indicates paralaxxing
    {

/* TWEAKME: Put more dummy textures here and a switch*/
// skip = not drawn because it's never seen by the player
#ifdef QUAKE2
 sprintf(Texture, "e1u1/skip 0 0 0 1.00 1.00 1 0 0");
#elif defined QUAKE1
sprintf(Texture, TEXTUREPREFIX "sky1 0 0 0 1.00 1.00 1 0 0"); 
#endif
    }

    else
        sprintf(Texture, "tile%.4d 0 0 0 1.00 1.00 1 0 0", sector[SectorNumber].ceilingpicnum); 
     

    // This chunk starts the ceiling drawing
 if (sector[SectorNumber].ceilingheinum != 0) // Slope
 {
  vertex1.x  = wall[j].x;
  vertex1.y  = wall[j].y;
  vertex2.x  = wall[wall[j].point2].x;
  vertex2.y  = wall[wall[j].point2].y;
  vertex1.zt = vertex1.zb = vertex2.zt = vertex2.zb = CeilingTop;

  ret = G_2va(vertex1.x, vertex1.y, vertex2.x, vertex2.y, &vertex3.x, &vertex3.y); // vertex3 is getting worked on
    
  // This will probably have to be tweaked for a larger scale
  vertex3.zt = CeilingTop - (sector[SectorNumber].ceilingheinum / 41) + 1;
  vertex3.zb = vertex3.zt-10;

  // Make sure there's no crazy slopes
  if (vertex3.zt < CeilingTop)
  {
      vertex3.zt = CeilingTop;
      vertex3.zb = vertex3.zt-10;
  }


  if (ret == 0)
   fprintf(f, "(%d %d %d) (%d %d %d) (%d %d %d) %s\n", 
               vertex1.x, vertex1.y, vertex1.zt, 
               vertex2.x, vertex2.y, vertex2.zt, 
               vertex3.x, vertex3.y, vertex3.zt, Texture); 
 
  else // ret == 1
   fprintf(f, "( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 
               0, 0, CeilingTop, 0, 500, CeilingTop, 500, 0, CeilingTop, Texture); 

 } else // No slope
   fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 
                   0, 0, CeilingTop, 0, 500, CeilingTop, 500, 0, CeilingTop, Texture); 

 
 // Write all the ceilings sides
 for (k = 0; k < sector[SectorNumber].wallnum; k++)
 {
  point1.x = wall[j].x;
  point1.y = wall[j].y;
  point2.x = wall[wall[j].point2].x;
  point2.y = wall[wall[j].point2].y;
  
  if (wall[j].nextwall != -1) // If there's another wall connected
      sprintf(Texture, TEXTUREPREFIX "tile%.4d", wall[wall[j].nextwall].picnum);
  else // No conecting wall
      sprintf(Texture, TEXTUREPREFIX "tile%.4d", wall[j].picnum);

 if (Stat % 2 == 1) // This indicates paralaxxing
  fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) sky1 0 0 0 1.00 1.00 0 133 1\n", 
  point2.x, point2.y, 500, point1.x, point1.y, 500, point1.x, point1.y, 0);
 
 else
  fprintf(f, "( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s 0 0 0 1 1 1 0 0\n", 
  point2.x, point2.y, 500, point1.x, point1.y, 500, point1.x, point1.y, 0, Texture); 

  j = wall[j].point2;
 }

 Texture[0] = '\0';
 
 if (Stat % 2 == 1) // This indicates paralaxxing
	 sprintf(Texture, TEXTUREPREFIX "sky1 0 0 0 1.00 1.00 0 133 1");

 else sprintf(Texture, TEXTUREPREFIX "tile%.4d 0 0 0 0.50 0.50 1 0 0", sector[SectorNumber].ceilingpicnum);
 
 // This chunk ends the ceiling drawing, it draws the closing points
 if (sector[SectorNumber].ceilingheinum != 0) // Slope
 {
  vertex1.x  = wall[j].x;
  vertex1.y  = wall[j].y;
  vertex1.zt = vertex2.zt = vertex3.zt = CeilingTop;
  vertex1.zb = vertex2.zb = vertex3.zb = CeilingBottom;
  vertex2.x  = wall[wall[j].point2].x;
  vertex2.y  = wall[wall[j].point2].y;
  
  ret = G_2va(vertex1.x, vertex1.y, vertex2.x, vertex2.y, &vertex3.x, &vertex3.y); // vertex3 is getting worked on
  
  // This will probably have to be tweaked for a larger scale
  vertex3.zt = CeilingBottom - (sector[SectorNumber].ceilingheinum / 41);
  vertex3.zb = vertex3.zt-10;

  if (ret == 0)
  fprintf(f, "  (%d %d %d) (%d %d %d) (%d %d %d) %s\n", 
  vertex1.x, vertex1.y, vertex1.zb, vertex3.x, vertex3.y, vertex3.zb, 
  vertex2.x, vertex2.y, vertex2.zb, Texture); 
  
  else
  fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 
  0, 0, CeilingBottom, 500, 0, CeilingBottom, 0, 500, CeilingBottom, Texture);
   
  }
  else // No slope
  fprintf(f, "  ( %d %d %d ) ( %d %d %d ) ( %d %d %d ) %s\n", 
  0, 0, CeilingBottom, 500, 0, CeilingBottom, 0, 500, CeilingBottom, Texture);

  fprintf(f, "}\n"); 
}