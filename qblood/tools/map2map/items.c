#include "global.h"

short M_Sprites[4096]; // What for?

void I_Sprites(FILE *f)
{

 TPoint v1, v2;
 TWall  pwall;
 double d1, d2, sx, sy;

unsigned short i = 0, Stat = 0, width = 0, height = 0;

printf("Adding sprites...\t\t\t\t\t\t ");

// Scale tile sizes
 for (i = 0; i < numsprites; i++)
 {
    M_Sprites[i] = 0; // Why?

  sx = tilesizx[sprite[i].picnum] * sprite[i].xrepeat / 64;
  sy = tilesizy[sprite[i].picnum] * sprite[i].yrepeat / 64;

  v1.x  = sprite[i].x + sx * sin(sprite[i].ang * (PI*2) / 2048) / 2 ;
  v1.y  = sprite[i].y + sx * cos(sprite[i].ang * (PI*2) / 2048) / 2 ;
  v1.zt = sprite[i].z + sy / 2 + (sy/2);
  v1.zb = sprite[i].z - sy / 2 + (sy/2);

  v2.x  = sprite[i].x - sx * sin(sprite[i].ang * (PI*2) / 2048) / 2;
  v2.y  = sprite[i].y - sx * cos(sprite[i].ang * (PI*2) / 2048) / 2;
  v2.zt = sprite[i].z + sy / 2 + (sy/2);
  v2.zb = sprite[i].z - sy / 2 + (sy/2);

    pwall.x_off     = 0;
    pwall.y_off     = 0;
    pwall.rot_angle = 0;

    d1 = sx;
    d2 = tilesizx[sprite[i].picnum];
    pwall.x_scale   = d1 / d2;
    d1 = sy;
    d2 = tilesizy[sprite[i].picnum];
    pwall.y_scale   = d1 / d2; 
    pwall.content_a = 0; 
    pwall.surface_a = 0;
    pwall.light_v   = 2000;
    pwall.texture = sprite[i].picnum;
  
  Stat = sprite[i].cstat;
  Stat = Stat >> 4;
  
  if (Stat % 4 == 2)
  W_FlatSprite(sprite[i].x, sprite[i].y, sprite[i].z, sprite[i].ang, width, height, pwall, f);

 }
 printf("[ Ok ]\n");
}

// Change to ambient sound
void W_MusicanDSFX(long i, char *Name, FILE *f)
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


void W_OtherItems(long i, char *Name, FILE *f)
{
 short SpawnFlag = 0, angle = 0;

 // Angle fixing
 if (sprite[i].ang > 0 && sprite[i].ang < 360)
	 angle = sprite[i].ang / ANGLESCALE;
 else angle = 0;

 // ??? This is Duke 3d specific, re-implement elsewhere ???
 if (sprite[i].lotag == 3) SpawnFlag =  768;
 if (sprite[i].lotag == 2) SpawnFlag =  256; // not in easy
 if (sprite[i].lotag == 1) SpawnFlag =    0;
 if (sprite[i].pal   == 1) SpawnFlag = 1792;

 fprintf(f, "{\n");
 fprintf(f, "  \"classname\"     \"%s\"\n", Name);
 fprintf(f, "  \"origin\"        \"%d %d %d\"\n", sprite[i].x, sprite[i].y, sprite[i].z+35);  
 fprintf(f, "  \"angle\"         \"%d\"\n", angle); 
 fprintf(f, "  \"spawnflags\"    \"%d\"\n", SpawnFlag);               
 fprintf(f, "}\n"); 
}

void E_Item(long i, char *Name, FILE *f, short SpawnFlag)
{
 short angle = 0;

 if (sprite[i].ang > 0 && sprite[i].ang < 360)
	 angle = sprite[i].ang / ANGLESCALE;
 else angle = 0;

 // ??? This is Duke 3d specific, re-implement elsewhere ???
 if (sprite[i].lotag == 3) SpawnFlag =  768;
 if (sprite[i].lotag == 2) SpawnFlag =  256;
 if (sprite[i].lotag == 1) SpawnFlag =    0;
 if (sprite[i].pal   == 1) SpawnFlag = 1792;

 fprintf(f, " {\n"
			"  \"classname\"     \"%s\"\n", Name);              
 fprintf(f, "  \"origin\"        \"%d %d %d\"\n", sprite[i].x, sprite[i].y, sprite[i].z+35);  
 fprintf(f, "  \"angle\"         \"%d\"\n", angle); 
 fprintf(f, "  \"spawnflags\"    \"%d\"\n", SpawnFlag);               
 fprintf(f, "  \"mass\"          \"100\"\n"
	        "  \"health\"        \"80\"\n"
			"  \"dmg\"           \"150\"\n"
			"}\n");
}

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
 fprintf(f, "  \"origin\"        \"%d %d %d\"\n", posx, posy, posz);
 fprintf(f, "  \"angle\"         \"%d\"\n", angle);
 
 fprintf(f, " }\n" 
	        " {\n"
			" \"classname\"     \"info_player_deathmatch\"\n"
			"  \"origin\"        \"%d %d %d\"\n", posx, posy, posz);
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


void W_AddLight(FILE* f, short i, short brightness)
{
 fprintf(f, " {\n"
			"  \"classname\"     \"light\"\n"
			"  \"origin\"        \"%d %d %d\"\n"
			"  \"target\"        \"t1\"\n"
			"  \"light\"         \"%d\"\n"
			" }\n",
			sprite[i].x, sprite[i].y, sprite[i].z+35, brightness);
}


void GetSizes(char *FName, long pos)
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
 long i, pos, size;
 char FileName[13];
 FILE *f;

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

 else if ((f = fopen(FName, "rb")) == NULL)
 {
  printf("Error : Cannot open %s file\n", FName);
  perror(""); // perror will tell you exactly why
  exit(14);
 }
 fread(&FileName,  12, 1, f);
 fread(&TotalFiles, 4, 1, f);
 FileName[12] = '\0';
 pos = 16 + 16 * TotalFiles;
 for (i = 0; i < TotalFiles; i++)
 {
  fread(&FileName, 12, 1, f);
  fread(&size,      4, 1, f);
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
  pos += size;
 }
 fclose(f);
 
}