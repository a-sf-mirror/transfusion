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

// Scales a map, and Recenters it. Also fixes the angles format.
void CalcAll()
{
 long MinX = 9999, MinY = 9999, MaxX = -9999, MaxY = -9999, wallpointer, j, k;
 short i, Xadjust, Yadjust; 

 printf("Scaling and recentering the coordinates\n");
  
 for (i = 0; i < numsectors; i++)
 {
  sector[i].ceilingz /= ZSCALE; //SCALE; - Build uses units of 128/256/512/1024
  sector[i].floorz   /= ZSCALE; //SCALE;
  /*
  if (sector[i].ceilingz > MaxH) 
	  MaxH = sector[i].ceilingz;
      */
 }

 for (i = 0; i < numwalls; i++)
 {
  if (wall[i].x > MaxX) MaxX = wall[i].x;
  if (wall[i].y > MaxY) MaxY = wall[i].y;
  if (wall[i].x < MinX) MinX = wall[i].x;
  if (wall[i].y < MinY) MinY = wall[i].y;
 }

 /*
 for (i = 0; i < numsectors; i++)
 {
  sector[i].ceilingz = (MaxH - sector[i].ceilingz) / ZADJUST/MAPSCALE; // ZADJUST was 14.5 
  sector[i].floorz   = (MaxH - sector[i].floorz  ) / ZADJUST/MAPSCALE; // while testing E6M8
 }
*/

 for (i = 0; i < numwalls; i++)
 {
  if (MinX < 0) 
  wall[i].x = -4000+(wall[i].x - MinX) / SCALE/MAPSCALE; 
  else
  wall[i].x = -4000+(wall[i].x)        / SCALE/MAPSCALE;

  wall[i].y = -4000+(MaxY - wall[i].y) / SCALE/MAPSCALE;
 }

 for (i = 0; i < numsprites; i++)
 {
  if (MinX < 0) 
  sprite[i].x = -4000+(sprite[i].x - MinX) / SCALE/MAPSCALE; 
  else
  sprite[i].x = -4000+(sprite[i].x)        / SCALE/MAPSCALE;

  sprite[i].y = -4000+(MaxY - sprite[i].y) / SCALE/MAPSCALE;
  sprite[i].z /= ZSCALE; // SCALE;
  //sprite[i].z = (MaxH - sprite[i].z) / ZADJUST/MAPSCALE;

 
  sprite[i].ang /= ANGLESCALE;
 // Angle fixing
 if (sprite[i].ang < 0 || sprite[i].ang > 360)
	 sprite[i].ang = 0;
 }

  if (MinX < 0) 
  startx = -4000+(startx - MinX) / SCALE/MAPSCALE; 
  else
  startx = -4000+(startx)        / SCALE/MAPSCALE;

  starty = -4000+(MaxY - starty) / SCALE/MAPSCALE;
  startz /= ZSCALE; //(MaxH - startz / SCALE) / SCALE/MAPSCALE;


 for (i = 0; i < numsectors; i++)
 {
     j = wallpointer  = sector[i].wallptr;

     // Redundant wall reduction starts here
 if (sector[i].wallnum > 2)
 do 
 {
     wall_t Wall1, Wall2, Wall3;
     unsigned short Protect1 = 1, Protect2 = 1; // Protects from divison by zero

     Wall1 = wall[j];
     Wall2 = wall[wall[j].point2];
     Wall3 = wall[wall[wall[j].point2].point2];

     
     if (Wall1.point2 == wallpointer || // No further optimizing to be done
         Wall2.point2 == wallpointer)
         break;

     if (Wall1.x - Wall2.x == 0) // No dividing by zero
         Protect1 = 1;
     else Protect1 = 0;

     if (Wall2.x - Wall3.x == 0) // No dividing by zero
         Protect2 = 1;
     else Protect2 = 0;
         
      /* This next chunk is some magic, so here's my explanation:
        The first if segment checks the walls to see if they're connected to another sector
        it would be bad to smooth a wall out that had a window or step nearby.
        The second chunk is checking for a redundant point between wall 1 and 3
        The third chunk is a rise/run check for redundant points in a diagonal wall
        many thanks to Chad Smith (math teacher) for helping my memory on this one
        The fourth chunk is to make sure if the extra wall is merely added for a special texture.
      */
  
     if ( 
         (Wall1.nextsector == -1 && Wall1.nextwall == -1  &&      // Connected
          Wall2.nextsector == -1 && Wall2.nextwall == -1) &&      // Connected
        (
         (Wall1.x == Wall2.x  && Wall1.x == Wall3.x) ||           // Redundant point horizontal
         (Wall1.y == Wall2.y  && Wall1.y == Wall3.y) ||           // Redundant point vertical
         (Wall1.y - Wall2.y) / (Wall1.x - Wall2.x+Protect1) ==    // Redundant point diagonal
         (Wall2.y - Wall3.y) / (Wall2.x - Wall3.x+Protect2) ) &&  // Redundant point diagonal pt 2
          (Wall1.picnum == Wall2.picnum && Wall2.picnum == Wall3.picnum)
          ) // Different art
          
     {
         // Before any numbers are changed, count this as an eliminated wall
         M_Wall[wall[j].point2] = 2;

        // Nuke all references to the wall we're replacing
         for (k = 0; k < numwalls; k++)
            if (wall[k].nextwall == wall[j].point2)
            {
                wall[k].nextwall = wall[wall[j].point2].point2;
                break;
            }
        
            // This should clear up any crazy wandering points in the level
        wall[wall[j].point2].x = wall[wall[wall[j].point2].point2].x;
        wall[wall[j].point2].y = wall[wall[wall[j].point2].point2].y;
       
        
            // Make Wall 1 point to wall 3 to save from drawing a redundant wall
         wall[j].point2 = wall[wall[j].point2].point2;

     }
     else j = wall[j].point2; // Nothing can be tweaked, go to next wall
 } while (j != wallpointer);
 // End wall reduction code
 } // for


// Now to recenter everything that just got scaled 
  MaxX = MinX = wall[0].x;
  MaxY = MinY = wall[0].y;

  for (i = 0; i < numwalls; i++)
	{
		if (wall[i].x > MaxX) MaxX = wall[i].x;
		if (wall[i].y > MaxY) MaxY = wall[i].y;
		if (wall[i].x < MinX) MinX = wall[i].x;
		if (wall[i].y < MinY) MinY = wall[i].y;
	}
	Xadjust = (MaxX + MinX)/2;
	Yadjust = (MaxY + MinY)/2;
  
	for (i = 0; i < numwalls; i++)
	{
		wall[i].x -= Xadjust;
		wall[i].y -= Yadjust;
	}

	for (i = 0; i < numsprites; i++)
	{
		sprite[i].x -= Xadjust;
		sprite[i].y -= Yadjust;
	}
	
	startx -= Xadjust;
	starty -= Yadjust;
    ang /= ANGLESCALE;
    if (ang < 0 || ang > 360)
	    ang = 0;
}
 
