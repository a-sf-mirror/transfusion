#include "global.h"

void WriteFlatSprites(FILE *f)
{

 TPoint vertex1, vertex2;
 TWall  pwall;
 double d1, d2, sizex, sizey;

unsigned short i = 0, Stat = 0, width = 0, height = 0;

printf("Adding Flat sprites...\t\t\t\t\t ");

// Scale tile sizes
 for (i = 0; i < numsprites; i++)
 {
    if (Stat % 4 != 2) // A regular face sprite
         continue;

  sizex = tilesizx[sprite[i].picnum] * sprite[i].xrepeat / 64;
  sizey = tilesizy[sprite[i].picnum] * sprite[i].yrepeat / 64;

  vertex1.x  = sprite[i].x + sizex * sin(sprite[i].ang * (PI*2) / 2048) / 2 ;
  vertex1.y  = sprite[i].y + sizex * cos(sprite[i].ang * (PI*2) / 2048) / 2 ;
  vertex1.zt = sprite[i].z + sizey / 2 + (sizey/2);
  vertex1.zb = sprite[i].z - sizey / 2 + (sizey/2);

  vertex2.x  = sprite[i].x - sizex * sin(sprite[i].ang * (PI*2) / 2048) / 2;
  vertex2.y  = sprite[i].y - sizex * cos(sprite[i].ang * (PI*2) / 2048) / 2;
  vertex2.zt = sprite[i].z + sizey / 2 + (sizey/2);
  vertex2.zb = sprite[i].z - sizey / 2 + (sizey/2);

    pwall.x_off     = 0;
    pwall.y_off     = 0;
    pwall.rot_angle = 0;

    d1 = sizex;
    d2 = tilesizx[sprite[i].picnum];
    pwall.x_scale   = d1 / d2;
    d1 = sizey;
    d2 = tilesizy[sprite[i].picnum];
    pwall.y_scale   = d1 / d2; 
    pwall.content_a = 0; 
    pwall.surface_a = 0;
    pwall.light_v   = 2000;
    pwall.texture = sprite[i].picnum;
  
  Stat = sprite[i].cstat;
  Stat = Stat >> 4;
  
  if (Stat % 4 == 2) // Not a face sprite /  This can probably be nuked because of above code
  W_FlatSprite(sprite[i].x, sprite[i].y, sprite[i].z, sprite[i].ang, width, height, pwall, f);

 }
 printf("[ Ok ]\n");
}

// Change to ambient sound - fix this for qBlood? Can I use noise to play a wave?
void W_MusicanDSFX(const unsigned short i, char *Name, FILE *f)
{
 long sp = 1;
 if (sector[sprite[i].sectnum].lotag) sp = 0;
 fprintf(f, " {\n");
 fprintf(f, "  \"classname\"     \"%s\"\n", Name);
 fprintf(f, "  \"origin\"        \"%d %d %d\"\n", sprite[i].x, sprite[i].y, sprite[i].z+10);
 fprintf(f, "  \"spawnflags\"    \"%d\"\n", sp);
 fprintf(f, "  \"noise\"         \"%d\"\n", sprite[i].lotag);
 fprintf(f, " }\n");
}

// Writes a simple item
void WriteSimpleItem(const unsigned short i, char *Name, FILE *f)
{
 fprintf(f, "{\n");
 fprintf(f, "  \"classname\"     \"%s\"\n", Name);
 fprintf(f, "  \"origin\"        \"%d %d %d\"\n", sprite[i].x, sprite[i].y, sprite[i].z+35);  
 fprintf(f, "  \"angle\"         \"%d\"\n", sprite[i].ang); 
 fprintf(f, "}\n"); 
}

// Writes an item with a special spawn flag
void WriteFlaggedItem(const unsigned short i, char *Name, FILE *f, short SpawnFlag)
{
 fprintf(f, " {\n"
			"  \"classname\"     \"%s\"\n", Name);              
 fprintf(f, "  \"origin\"        \"%d %d %d\"\n", sprite[i].x, sprite[i].y, sprite[i].z+35);  
 fprintf(f, "  \"angle\"         \"%d\"\n", sprite[i].ang); 
 fprintf(f, "  \"spawnflags\"    \"%d\"\n", SpawnFlag);               
 fprintf(f, "}\n");
}

// Goes through all the sprites and tries to find acceptable conversions
void WriteItems(FILE *f)
{
 unsigned short i = 0, angle = 0;

 // Convert the angle format
 if (ang > 0 && ang < 360)
	 angle = ang / ANGLESCALE;
 else angle = 0;
 
 printf("Adding items...");

#ifndef BLOOD // If a game has a player 1 start this is bad actually
 fprintf(f, " {\n"
	        " \"classname\"     \"info_player_start\"\n");
 fprintf(f, "  \"origin\"        \"%d %d %d\"\n", startx, starty, startz);
 fprintf(f, "  \"angle\"         \"%d\"\n", angle);
 
 fprintf(f, " }\n" 
	        " {\n"
			" \"classname\"     \"info_player_deathmatch\"\n"
			"  \"origin\"        \"%d %d %d\"\n", startx, starty, startz);
 fprintf(f, "  \"angle\"         \"%d\"\n", angle);
 fprintf(f, " }\n");
#endif

// The heart of the sprite writing code
 for (i = 0; i < numsprites; i++)
 {
  // There should be a switch here
	 Blood_To_qBlood(i, f);
	 //Duke3D_To_Quake2(i, f);
 }
 
 printf("Done\n");
}

// Places a light entity in a map
void AddLight(FILE* newmap, const short i, const short brightness)
{
 fprintf(newmap, " {\n"
			     "  \"classname\"     \"light\"\n"
			     "  \"origin\"        \"%d %d %d\"\n"
			     "  \"target\"        \"t1\"\n"
			     "  \"light\"         \"%d\"\n"
			     " }\n",
			     sprite[i].x, sprite[i].y, sprite[i].z+35, brightness);
}

// Will get the tile sizes from a group or art file
void GetSizes(char *FName, const long pos)
{

 FILE *f;

 long  i, artversion, numtiles, localtilestart, localtileend;

 if ((f = fopen(FName, "rb")) == NULL)
 {
  printf("Error : Cannot open %s file\n", FName);
  perror(""); // perror will tell you exactly why
  exit(14);
 }

 fseek(f, pos, SEEK_SET);
 fread(&artversion,     4, 1, f); 
 if (artversion != 1) 
 { 
	 printf("Error : Invalid art version number %d\n", artversion); 
	 exit(13);
 }
 fread(&numtiles,       4, 1, f);
 fread(&localtilestart, 4, 1, f);
 fread(&localtileend,   4, 1, f);

 for (i = localtilestart; i <= localtileend; i++) 
	 fread(&tilesizx[i], 2, 1, f);

 for (i = localtilestart; i <= localtileend; i++) 
	 fread(&tilesizy[i], 2, 1, f);

}


// This expects a group file (.grp) or a directory of art files specifed by "notgroup"
void I_Sizes(char *FName)
{
 long TotalFiles = 0;
 unsigned short i, pos, size;
 char FileName[13];
 FILE *groupfile;

 printf("Getting tile sizes\n");
 // Set all the tile sizes to zero
 for (i = 0; i < MAXTILES; i++)
 {
     tilesizx[i] = 0;
     tilesizy[i] = 0;
 }

 if (strcmp (FName, "notgroup") == 0)
 {
	 char ArtName[13];
	 // This will cycle through all the defined games art files (non-grouped of course)
	 for (i = 0; i < ARTFILES; i++) 
	 {
		sprintf(ArtName,"tiles%.3d.art", i);
		GetSizes(ArtName, 0);
	 }
	 return;
 }

 // Scours a group file for art files
 else if ((groupfile = fopen(FName, "rb")) == NULL)
 {
  printf("Error : Cannot open %s file\n", FName);
  perror(""); // perror will tell you exactly why
  exit(14);
 }
 fread(&FileName,  12, 1, groupfile);
 fread(&TotalFiles, 4, 1, groupfile);
 FileName[12] = '\0';
 pos = 16 + 16 * TotalFiles;
 for (i = 0; i < TotalFiles; i++)
 {
  fread(&FileName, 12, 1, groupfile);
  fread(&size,      4, 1, groupfile);
  FileName[12] = '\0';
  if ((FileName[0] == 'T') &&
	  (FileName[1] == 'I') && 
	  (FileName[2] == 'L') && 
	  (FileName[3] == 'E') && 
	  (FileName[4] == 'S') && 
	  (FileName[8] == '.') && 
	  (FileName[9] == 'A') && 
	  (FileName[10] == 'R') && 
	  (FileName[11] == 'T'))
  {
   GetSizes(FName, pos);
  }
  else 
  {
      printf("No art files found in %s\n", FName);
      return;
  }

  pos += size;
 }
 fclose(groupfile);
 
}