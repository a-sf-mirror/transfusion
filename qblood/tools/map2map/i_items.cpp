#include "global.h"
#include "names.h"
/*
class Items
{
 private :
  char  Name[5000][80]; // was 9999*256, the max text on a line is 80
  short T[5000];		// was 9999
  long Max;
 public :
  void  Init();
  short GetItem(long Num, char **Name1);
};

void Items::Init()
{
 FILE *f;
 char E[256], NrS[10], Name1[256];
 long Nr;
 unsigned short i;
 
 Max = 0;

 for (i = 0; i <= 9999; i++) T[i] = 0;
 f = fopen("i_items.txt", "rb");
 while (!feof(f))
 {
  fgets(E, 250, f);
  strncpy(NrS, E, 5);
  Nr = atol(NrS);
  
  for (i = 0; i < 256; i++) 
	  Name1[i] = 0;
  
  for (i = 6; (((i < strlen(E)) & (E[i] != '"'))); i++) 
	  Name1[i-6] = E[i];

  if (Nr > Max) Max = Nr;
  strcpy(Name[Nr], Name1);
  T[Nr] = 1;
  //printf("[%s]\n", Name1);
 }
 fclose(f);
}

short Items::GetItem(long Num, char **Name1)
{
 if (T[Num] == 0) return 0;
 else
 {
  strcpy(*Name1, Name[Num]);
  return 1;
 }
}

Items Item;

void W_Wall(TPoint p1, TPoint p2, FILE *f, TWall w);
void I_Sizes(char *FName);
short M_Sprites[4096];

*/
void I_Sprites(FILE *f)
{
/*
return;
Item.Init();
E = (char *) malloc(256);


 TPoint v1, v2;
 TWall  pwall;
 char   *E;
 double d1, d2;
 
unsigned short i = 0, Stat = 0, width = 0, height = 0;

printf("I_Spr1 : Adding sprites...\t\t\t\t\t\t ");
// for (i = 0; i < numsprites; i++) M_Sprites[i] = 0;
 for (i = 0; i < numsprites; i++)
 {
/*
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
*/

/*  
  
  Stat = sprite[i].cstat;
  Stat = Stat >> 4;
  
  if (Stat % 4 == 2)
  W_FlatSprite(sprite[i].x, sprite[i].y, sprite[i].z, sprite[i].ang, width, height, pwall, f);

	FIXME: This should be per game
  else if ((Item.GetItem(sprite[i].picnum, &E) == 0) & (sprite[i].picnum > 10)) 
  W_Wall(v1, v2, f, pwall);
*/

 //}
 printf("[ Ok ]\n");
}

/* Change to ambient sound
void W_MusicanDSFX(long i, char *Name, FILE *f)
{
 long sp = 1;
 fprintf(f, " {\n");
 if (sector[sprite[i].sectnum].lotag) sp = 0;
 fprintf(f, "  \"classname\"     \"%s\"\n", Name);
 fprintf(f, "  \"origin\"        \"%d %d %d\"\n", sprite[i].x, sprite[i].y, sprite[i].z+10);
 fprintf(f, "  \"spawnflags\"    \"%d\"\n", sp);
 fprintf(f, "  \"noise\"         \"%d\"\n", sprite[i].lotag);
 fprintf(f, " }\n");
}
*/

void W_OtherItems(long i, char *Name, FILE *f)
{
 char s[256];
 long sp = 0;
 short angle = 0;
 if (sprite[i].ang > 0 && sprite[i].ang < 360)
	 angle = sprite[i].ang / ANGLESCALE;
 else angle = 0;
 
 if (sprite[i].lotag == 3) sp =  768;
 if (sprite[i].lotag == 2) sp =  256;
 if (sprite[i].lotag == 1) sp =    0;
 if (sprite[i].pal   == 1) sp = 1792;

 fprintf(f, " {\n");

 if ((sprite[i].picnum == 1400) ^ (sprite[i].picnum == 1405) ^ (sprite[i].picnum == 1420))
 {
  if (sprite[i].lotag == 1)  sprintf(s, "  \"classname\"     \"info_player_coop\"\n");
  else  sprintf(s, "  \"classname\"     \"info_player_deathmatch\"\n");
 } else sprintf(s, "  \"classname\"     \"%s\"\n", Name);              
 fprintf(f, s);
 fprintf(f, "  \"origin\"        \"%d %d %d\"\n", sprite[i].x, sprite[i].y, sprite[i].z+50);  
 fprintf(f, "  \"angle\"         \"%d\"\n", angle); 
 fprintf(f, "  \"spawnflags\"    \"%d\"\n", sp);               
 fprintf(f, "}\n"); // close the entity
}

/* This is totally game specific 
void W_Item(char *Name, FILE *f, long i)
{
 switch (sprite[i].picnum)
 {
  case MUSICANDSFX : W_MusicanDSFX(i, Name, f);
  default          : W_OtherItems (i, Name, f);
 }
}
*/


void E_Item(char *Name, FILE *f, long i)
{
 char s[256];
 long sp;
 
 fprintf(f, " {\n");

 if (sprite[i].lotag == 3) sp =  768;
 if (sprite[i].lotag == 2) sp =  256;
 if (sprite[i].lotag == 1) sp =    0;
 if (sprite[i].pal   == 1) sp = 1792;


 if ((sprite[i].picnum == 1400) ^ (sprite[i].picnum == 1405) ^ (sprite[i].picnum == 1420))
 {
  if (sprite[i].lotag == 1)  sprintf(s, "  \"classname\"     \"info_player_coop\"\n");
  else  sprintf(s, "  \"classname\"     \"info_player_deathmatch\"\n");
 } else sprintf(s, "  \"classname\"     \"%s\"\n", Name);              
 fprintf(f, s);
 fprintf(f, "  \"origin\"        \"%d %d %d\"\n", sprite[i].x, sprite[i].y, sprite[i].z+50);  
 fprintf(f, "  \"angle\"         \"%d\"\n", sprite[i].ang / ANGLESCALE); 
 fprintf(f, "  \"spawnflags\"    \"%d\"\n", sp);               
 fprintf(f, "  \"mass\"          \"100\"\n");
 fprintf(f, "  \"health\"        \"80\"\n");
 fprintf(f, "  \"dmg\"           \"150\"\n");
 fprintf(f,"}\n");
}

void I_Item(FILE *f)
{
// Item.Init();
 long i;
 char *Name;
 short angle = 0;
 if (ang > 0 && ang < 360)
	 angle = ang / ANGLESCALE;
 else angle = 0;
 
 printf("I_Item : Adding items...");

 Name = (char *) malloc(256);
 
/* FIXME: This is getting butchered! */
 fprintf(f, " {\n");
 fprintf(f, " \"classname\"     \"info_player_start\"\n");
 fprintf(f, "  \"origin\"        \"%d %d %d\"\n", posx, posy, posz);
 fprintf(f, "  \"angle\"         \"%d\"\n", angle);
 fprintf(f, " }\n");
 fprintf(f, " {\n");
 fprintf(f, " \"classname\"     \"info_player_deathmatch\"\n");
 fprintf(f, "  \"origin\"        \"%d %d %d\"\n", posx, posy, posz);
 fprintf(f, "  \"angle\"         \"%d\"\n", angle);
 fprintf(f, " }\n");
 fprintf(f, "\n");

// return;
/* The heart of the sprite writing code? */
 for (i = 0; i < numsprites; i++)
 {
/* FIXME: This should be per game
	 if (Item.GetItem(sprite[i].picnum, &Name) == 1) 
  { 
   //if ((i != 1247) & (i != 1079)) W_Item(Name, f, i);
   //else 
	  E_Item(Name, f, i);
  }
*/
 }
 free(Name);
 printf("Done\n");
}

void I_Light(FILE* f, short x, short y, short z, short brightness)

{
 fprintf(f, " {\n"
			"  \"classname\"     \"light\"\n"
			"  \"origin\"        \"%d %d %d\"\n"
			"  \"target\"        \"t1\"\n"
			"  \"light\"         \"%d\"\n"
			" }\n",
			x, y, z, brightness);
}

void GetSizes(char *FName, long pos, long size)
{

 FILE *f;

 long  i, artversion, numtiles, localtilestart, localtileend;

 if ((f = fopen(FName, "rb")) == NULL)
 {
  printf("Error : Cannot open %s file\n", FName);
  exit(14);
 }

 fseek(f, pos, SEEK_SET);
 fread(&artversion,     4, 1, f); if (artversion != 1) { printf("Error : Invalid art version number %d\n", artversion); exit(13); }
 fread(&numtiles,       4, 1, f);
 fread(&localtilestart, 4, 1, f);
 fread(&localtileend,   4, 1, f);
 for (i = localtilestart; i <= localtileend; i++) fread(&tilesizx[i], 2, 1, f);
 for (i = localtilestart; i <= localtileend; i++) fread(&tilesizy[i], 2, 1, f);

}

void I_Sizes(char *FName)
{
 
 long TotalFiles = 0;
 long i, pos, size;
 char FileName[13];
 FILE *f;

 for (i = 0; i < 100000; i++) tilesizx[i] = 0;
 for (i = 0; i < 100000; i++) tilesizy[i] = 0;
 if ((f = fopen(FName, "rb")) == NULL)
 {
  printf("Error : Cannot open %s file\n", FName);
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
  if ((FileName[0] == 'T') & (FileName[1] == 'I') & (FileName[2] == 'L') & (FileName[3] == 'E') & (FileName[4] == 'S') & (FileName[8] == '.') & (FileName[9] == 'A') & (FileName[10] == 'R') & (FileName[11] == 'T'))
  {
   GetSizes(FName, pos, size);
  }
  pos += size;
 }
 fclose(f);
 
}