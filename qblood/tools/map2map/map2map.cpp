#include "global.h"

/* Prototypes */
void DrawFloor(FILE *f, long i);
void WriteWall(TPoint p1, TPoint p2, FILE *f, long i);
void WriteFloor(FILE *f, long SectorNumber, long Plus);
void CalcAll();
void DrawSectorWalls(FILE *f, long i);
void WriteWalls(FILE *f);
void W_MWalls(FILE *f);
void I_Sprites(FILE *f);
void WriteItems(FILE *f);
void I_Sizes(char *FName);
void D_Sector(FILE *f, long i);

void ReadMap(char *FName)
{
 long mapversion;
 int  cursectnum, i;
 FILE *buildmap;
 
 printf("Reading map file %s\n", FName);
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
 
 // Sectors
 fread(&numsectors, 2, 1, buildmap);
 sector = (sector_t *) malloc((numsectors+1) * sizeof(sector_t)); // +1 for temp sector
 fread(sector, sizeof(sector_t), numsectors, buildmap);
 
 // Walls
 fread(&numwalls, 2, 1, buildmap);
 wall = (wall_t *) malloc((numwalls+4) * sizeof(wall_t)); // +4 for the temp sector
 M_Wall = (short *) malloc((numwalls+4) * sizeof(short)); // used in divandwrite
 for (i = 0; i < numwalls; i++) 
        M_Wall[i] = 0;
 fread(wall, sizeof(wall_t), numwalls, buildmap);
 
 // Sprites
 fread(&numsprites, 2, 1, buildmap);
 sprite = (sprite_t *) malloc(numwalls * sizeof(sprite_t));
 fread(sprite, sizeof(sprite_t), numsprites, buildmap);
 
 fclose(buildmap);

    printf("         Staring point : %d %d %d\n", posx, posy, posz);
    printf("         Total Sectors : %d\n", numsectors);
    printf("         Total Walls   : %d\n", numwalls);
    printf("         Total Sprites : %d\n", numsprites);
}


// Good old main
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

 // Seed the random number generator so we can have a random cd track
 srand((unsigned)time(NULL));

 ReadMap(argv[1]);  
 CalcAll();
 // This should be part of a switch (i.e. rr.grp, sw.grp, rr2.grp) 
 I_Sizes("notgroup"); //"data/duke3d.grp"
 newmap = fopen(argv[2], "wb");
 
 // Write map header
 fprintf(newmap, "{\n"
                 "\"classname\"\"worldspawn\"\n"
                 "\"sounds\"   \"%d\"\n", (rand()%10)+1); // random cd track

 // Draw the sectors
 for (i = 0; i < numsectors; i++) 
	 D_Sector(newmap, i);

 WriteWalls(newmap);
 I_Sprites(newmap);
 
 // Write the closing bracket for the geometry section
 fprintf(newmap, "}\n");

 W_MWalls(newmap);
 WriteItems(newmap);
 fclose(newmap);
 free(sector);
 free(wall);
 free(sprite);
 
 for (i = 0; i < numwalls; i++) 
	 if (M_Wall[i] == 0) 
		 badwalls++;
 
 printf("Walls not written: %d\n", badwalls);

 return 0;
}
