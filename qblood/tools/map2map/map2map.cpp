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

 printf("Build map version 7 to Quake map format Converter [Map Convert Utility]\n");
 printf("=======================================================================\n");

 if (argc < 3) 
 {
	printf("\nmap2map.exe in.map out.map\n");
	printf("            in.map  Build map version 7 file\n");
	printf("            out.map Quake map file\n");
	return 1;
 }

 ReadMap(argv[1]);  
 CalcAll();
 // This should be part of a switch (i.e. rr.grp, sw.grp, rr2.grp) 
 I_Sizes("notgroup"); //"data/duke3d.grp"
 newmap = fopen(argv[2], "wb");
 DrawMapBegin(newmap);
 DrawSectors(newmap);
 WriteWalls(newmap);
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
