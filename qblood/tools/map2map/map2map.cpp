#include "global.h"

/* Prototypes */
void DrawSky(FILE *f);
void DrawFloor(FILE *f, long i);
void WriteWall(TPoint p1, TPoint p2, FILE *f, long i);
void WriteFloor(FILE *f, long SecN, long Plus);
void CalcAll();
void DrawSectorWalls(FILE *f, long i);
void WriteWalls(FILE *f);
void W_MWalls(FILE *f);
void I_Sprites(FILE *f);
void I_Item(FILE *f);
void I_Sizes(char *FName);
void D_Sector(FILE *f, long i);

void ReadMap(char *FName)
{
 long mapversion;
 int  cursectnum, i;
 FILE *buildmap;

 printf("I_Map  : Reading map file %s\n", FName);
 buildmap = fopen(FName, "rb");
 if (buildmap == NULL)
 {
	 perror("Unable to open map");
	 exit(0);
 }
 

 fread(&mapversion, 1, 4, buildmap);
 if (mapversion != 7L) // 7 Long
 {
	if (mapversion == 4L || mapversion == 5L || mapversion == 6L)
		printf("%s is a version %d map. Please convert it with convmap%d\n", 
		FName, mapversion, mapversion+1);
	
	else printf("%s is not a build map\n", FName); 
	exit(0);
 }

 fread(&posx, 4, 1, buildmap);
 fread(&posy, 4, 1, buildmap);
 fread(&posz, 4, 1, buildmap);
 fread(&ang,  2, 1, buildmap);
 fread(&cursectnum, 2, 1, buildmap);
 fread(&numsectors, 2, 1, buildmap);
 printf("         Staring point : %d %d %d\n", posx, posy, posz);
 printf("         Total Sectors : %d\n", numsectors);
 fread(&sector[0], sizeof(sector_t), numsectors, buildmap);
 fread(&numwalls, 2, 1, buildmap);
 printf("         Total Walls   : %d\n", numwalls);
 for (i = 0; i < numwalls; i++) M_Wall[i] = 0;
 fread(&wall[0], sizeof(wall_t), numwalls, buildmap);
 fread(&numsprites, 2, 1, buildmap);
 printf("         Total Sprites : %d\n", numsprites);
 fread(&sprite[0], sizeof(sprite_t), numsprites, buildmap);
 fclose(buildmap);
}
               
void WriteMap(FILE *f)
{
// TPoint r2;
 int  i, j;
// long x1, y1, x2, y2;
 long Ox, Oy, wallpointer, STop, SBot;
 TPoint v1, v2;

// WriteWalls(f);

 for (i = 0; i < numsectors; i++)
 {

  wallpointer = sector[i].wallptr;
  STop = sector[i].ceilingz;
  SBot = sector[i].floorz;

  j = wall[wallpointer].point2;
  
  Ox = wall[wallpointer].x;
  Oy = wall[wallpointer].y;

  do 
  {

   v1.x  = wall[j].x;
   v1.y  = wall[j].y;
   v2.x  = wall[wall[j].point2].x;
   v2.y  = wall[wall[j].point2].y;
   v1.zt = STop;
   v1.zb = SBot;
   v2.zt = STop;
   v2.zb = SBot;

   if (M_Wall[j] == 0)
   {
    WriteWall(v1, v2, f, j);
    M_Wall[j] = 1;
   }

   /*   
   x2 = wall[j].x;
   y2 = wall[j].y;
   x1 = Ox;
   y1 = Oy;
   
   v1.x  = (x1 -posx) / Divider;
   v1.y  = (y1 -posy) / Divider;
   v1.zt = STop;
   v1.zb = SBot;

   v2.x  = (x2 -posx) / Divider;
   v2.y  = (y2 -posy) / Divider;
   v2.zt = STop;
   v2.zb = SBot;



   Ox = wall[j].x;
   Oy = wall[j].y; 
*/
   j = wall[j].point2;

  }   while (j != wallpointer);

/*
  x2 = wall[j].x;
  y2 = wall[j].y;
  x1 = Ox;
  y1 = Oy;
  
  v1.x  = (x1 -posx) / Divider;
  v1.y  = (y1 -posy) / Divider;
  v1.zt = STop;
  v1.zb = SBot;

  v2.x  = (x2 -posx) / Divider;
  v2.y  = (y2 -posy) / Divider;
  v2.zt = STop;
  v2.zb = SBot;


  if (M_Wall[j] == 0)
  {
   WriteWall(v1, v2, f, j);
   M_Wall[j] = 1;
  }  
*/

   v1.x  = wall[j].x;
   v1.y  = wall[j].y;
   v2.x  = wall[wall[j].point2].x;
   v2.y  = wall[wall[j].point2].y;
   v1.zt = STop;
   v1.zb = SBot;
   v2.zt = STop;
   v2.zb = SBot;

   if (M_Wall[j] == 0)
   {
    WriteWall(v1, v2, f, j);
    M_Wall[j] = 1;
   }

 } 


}

void DrawMapBegin(FILE *f)
{
 printf("I_Strt : ");
 fputs("{\n", f);
 fputs("  \"sky\" \"duke3d\"\n", f);
 fputs("  \"classname\"     \"worldspawn\"\n", f);
 printf("Map start written\n");
}

void DrawMapEnd(FILE *f)
{
 printf("I_End  : ");
 fputs("}\n", f);
 printf("Map End Written\n");
}

void DrawSectors(FILE *f)
{
	int i;
 for (i = 0; i < numsectors; i++) 
	 D_Sector(f, i);
}
 
int main (int argc, char *argv[])
{
 FILE *newmap;
 long badwalls = 0, i = 0; 

 printf("Duke Nukem 3D Converter to Q2 [Map Convert Utility]\n");
 printf("===================================================\n");

 if (argc < 3) 
 {
	printf("\nmap2map.exe in.map q2out.map\n");
	printf("            in.map    Duke Nukem 3D map file\n");
	printf("            q2out.map Quake II map file\n");
	return 1;
 }

 ReadMap(argv[1]);  
 CalcAll();
 //I_Sizes("data/duke3d.grp"); //Not yet tim
 newmap = fopen(argv[2], "wb");
 DrawMapBegin(newmap);

// DrawSky(newmap); // -> For Now;
 DrawSectors(newmap);
 WriteWalls(newmap);
// -> Lyg Nereikia // DrawFloor(newmap);
// -> Lyg Nereikia // WriteMap(newmap);
 I_Sprites(newmap); // ForNow
 DrawMapEnd (newmap);
 W_MWalls   (newmap);
 I_Item     (newmap);
 fclose     (newmap);
 
 for (i = 0; i < numwalls; i++) 
	 if (M_Wall[i] == 0) 
		 badwalls++;
 
	 printf("I_Wllz : Walls not written : %d\n", badwalls);

 return 0;
}
