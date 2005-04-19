#include "global.h"

void ReadMap(const char *FName)
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

 fread(&startx, 4, 1, buildmap);
 fread(&starty, 4, 1, buildmap);
 fread(&startz, 4, 1, buildmap);
 fread(&ang,  2, 1, buildmap);
 fread(&cursectnum, 2, 1, buildmap);
 
 // Sectors
 fread(&numsectors, 2, 1, buildmap);
 sector = (sector_t *) malloc((numsectors+1) * sizeof(sector_t)); // +1 for temp sector
 fread(sector, sizeof(sector_t), numsectors, buildmap);
 
 // Walls
 fread(&numwalls, 2, 1, buildmap);
 wall = (wall_t *) malloc((numwalls+4) * sizeof(wall_t)); // +4 for the temp sector
 M_Wall = (char *) malloc((numwalls+4) * sizeof(char)); // used in divandwrite
 for (i = 0; i < numwalls; i++) 
        M_Wall[i] = 0;
 fread(wall, sizeof(wall_t), numwalls, buildmap);
 
 // Sprites
 fread(&numsprites, 2, 1, buildmap);
 sprite = (sprite_t *) malloc(numwalls * sizeof(sprite_t));
 fread(sprite, sizeof(sprite_t), numsprites, buildmap);
 
 fclose(buildmap);

    printf("         Staring point : %d %d %d\n", startx, starty, startz);
    printf("         Total Sectors : %d\n", numsectors);
    printf("         Total Walls   : %d\n", numwalls);
    printf("         Total Sprites : %d\n", numsprites);
}


// Good old main
int main (int argc, char *argv[])
{
 FILE *newmap;
 unsigned short badwalls = 0, skippedwalls = 0, i = 0;
 SectorsRounded = 0;

 printf("Build map version 7 to Quake map format Converter [Map Convert Utility]\n");
 printf("=======================================================================\n");
 printf("Compiled at " __DATE__ " " __TIME__ "\n"); 
 if (argc < 3) 
 {
	printf("\nmap2map.exe input.map output.map\n");
	printf("            input.map  Build map version 7 file\n");
	printf("            output.map Quake map file\n");
	return 1;
 }

 // Seed the random number generator so we can have a random cd track
 srand((unsigned)time(NULL));

 ReadMap(argv[1]);  
 CalcAll();
 // This should be part of a switch (i.e. rr.grp, sw.grp, rr2.grp) 
 //I_Sizes("notgroup"); //"data/duke3d.grp"
 newmap = fopen(argv[2], "wb");
 if (newmap == NULL)
 {
     perror("Error creating new map");
     return -1;
 }
 
 // Write map header
 fprintf(newmap, "{\n"
                 "\"classname\"\"worldspawn\"\n"
                 "\"light\"\"100\"\n"
                 "\"sky\"\"blood1\"\n",
                 "\"sounds\"   \"%d\"\n", (rand()%10)+1); // random cd track

 printf("Processing sector #     ");
 // Draw the sectors
 for (i = 0; i < numsectors; i++) 
 {
     printf("\b\b\b\b\b%5d", i+1);
     DrawSector(newmap, i);
 }
     printf("\n");

 WriteTwoSidedWalls(newmap);
 WriteFlatSprites(newmap); // dependant on tile sizes, everything is defaulting to 32 x 32 now.
 
 // Write the closing bracket for the geometry section
 fprintf(newmap, "}\n");

 WriteMaskedWalls(newmap);
 WriteItems(newmap);
 fclose(newmap);
 free(sector);
 free(wall);
 free(sprite);
 
 for (i = 0; i < numwalls; i++) 
 {
	 if (M_Wall[i] == 0) 
		 badwalls++;

     if (M_Wall[i] == 2) 
		 skippedwalls++;
 }
 
 printf("Walls not written: %d\n"
        "Walls skipped due to smoothing algorithm: %d\n", badwalls, skippedwalls);

 return 0;
}
