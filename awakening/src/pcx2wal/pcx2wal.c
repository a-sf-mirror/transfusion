/*
==================================
PCX2WAL

An utility to convert PCX files to Quake2 .wal files.

Copyright (C) 1997-1998 Iikka Keranen 
              2002-2003 Mathieu Olivier

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
==================================
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <math.h>

#define VERSION "2.4"

#define FLIST_LEN 2000		/* max of textures to be converted at once */

/* ======== GLOBAL VARS ========== */

unsigned char *srcpic, *dstpic, *palette, *srcpal, *hicolor;
long width, height;

/*
=======================================
Quick Zsoft PCX load func
only supports 256 colours
======================================
*/

short pcxload(char *name, char *pal)
{
	unsigned long p;
	short tavu1, tavu2;
	unsigned long w, h, n;

	FILE *pcx = fopen(name, "rb");
	if (!pcx) {
		printf("Can't find file %s\n", name);
		return (1);
	}
	fseek(pcx, 8, SEEK_SET);
	w = fgetc(pcx);
	w += (fgetc(pcx) << 8) + 1;
	h = fgetc(pcx);
	h += (fgetc(pcx) << 8) + 1;
	width = w;
	height = h;
#if DEBUG
	printf("Allocing mem for pictures...\n");
#endif
	srcpic = (char *) malloc(w * h);
	dstpic = (char *) malloc(w * h);

	fseek(pcx, 66, SEEK_SET);	/* Bytes per line */
	n = fgetc(pcx);

	fseek(pcx, 128, SEEK_SET);	/* Load image */

	for (p = 0; p < w * h;) {
		tavu1 = fgetc(pcx);
		if (tavu1 > 192) {
			tavu2 = fgetc(pcx);
			for (; tavu1 > 192; tavu1--)
				srcpic[p++] = tavu2;
		} else
			srcpic[p++] = tavu1;
		if ((width < n) && (p % width == 0))
			fgetc (pcx);
	}


	if (pal) {
		fseek(pcx, -768, SEEK_END);	/* Load palette */

		fread(pal, 1, 768, pcx);
	}
#if DEBUG
	printf("PCX loaded successfully...\n");
#endif
	fclose(pcx);
	return 0;
}

/*
====================
Mip-mapping routines
====================
*/

short findcol(int r, int g, int b, int beg, int end)
{				/* FIND RGB COLOR */
	int c1, c = 0, e, ee = 768;

	if (!hicolor)
		for (c1 = beg; c1 < end; c1++) {
			e = abs(palette[c1 + c1 + c1] - r) +
			    abs(palette[c1 + c1 + c1 + 1] - g) +
			    abs(palette[c1 + c1 + c1 + 2] - b);
			if (e < ee) {
				c = c1;
				ee = e;
			}
	} else
		c = hicolor[((b >> 3) << 11) + ((g >> 2) << 5) + (r >> 3)];

	return c;
}

short mip(char fac)
{
	long x, y, x1, y1, xs, ys, c, n;
	long r, g, b, vx, vy;
	unsigned int po, po1;
	long w = width, h = height;

#if DEBUG
	printf("Mip-mapping... ");
#endif
	xs = w >> fac;
	ys = h >> fac;

	// For each pixel in the final image...
	for (y = 0; y < ys; y++)
	{
		for (x = 0; x < xs; x++)
		{
			x1 = x << fac;
			y1 = y << fac;
			r = 0;
			g = 0;
			b = 0;
			n = 0;

			// Compute the average value of all corresponding pixels in the source image
			for (vy = y1; vy < y1 + (1 << fac); vy++)
			{
				po1 = vy * w + x1;
				for (vx = x1; vx < x1 + (1 << fac); vx++)
				{
					c = srcpic[po1];
					if (c != 255)
					{
						r += srcpal[c * 3];
						g += srcpal[c * 3 + 1];
						b += srcpal[c * 3 + 2];
						n++;
					}
					po1++;
				}
			}

			// If there were enough non-transparent pixels
			if (n > (1 << fac) * (1 << fac) / 2)
			{
				r = r * 1.0 / n + .5;
				g = g * 1.0 / n + .5;
				b = b * 1.0 / n + .5;
				c = findcol (r, g, b, 0, 255);
			}
			// Else, just make it transparent
			else
				c = 255;

			po = y * xs + x;
			dstpic[po] = c;
		}
	}

#if DEBUG
	printf("Done.\n");
#endif
	return 0;
}

short pcx2wal(char *src, char *dst, char *next,
	      char *path, long flags, long contents, long value, char by)
{
	char texname[256];
	char texname2[256];
	FILE *wal;
	long x;
	char suf;

	if (strcmp(dst + strlen(dst) - 4, ".wal")) {	/* if no dst file set, get from src */
		strcpy(dst, src);
		dst[strlen(dst) - 4] = '.';
		dst[strlen(dst) - 3] = 'w';
		dst[strlen(dst) - 2] = 'a';
		dst[strlen(dst) - 1] = 'l';
	}
	if (strlen(path))
		memcpy(texname, path, strlen(path) + 1);
	else
		texname[0] = 0;
	memcpy(texname + strlen(texname), dst, strlen(dst) + 1);
	texname[strlen(texname) - 4] = 0;

	if (next) {
		memcpy(texname2, path, strlen(path) + 1);
		memcpy(texname2 + strlen(texname2), next, strlen(next) + 1);
		texname2[strlen(texname2) - 4] = 0;
	} else
		texname2[0] = 0;

	if (by & 1) {
		if (pcxload(src, NULL) == 1)
			return (1);
		memcpy(srcpal, palette, 768);
	} else if (pcxload(src, srcpal) == 1)
		return (1);
	wal = fopen(dst, "wb");
	if (!wal) {
		printf("Error: can't write file! Disk full?\n");
		return (1);
	}
	suf = 0;
	for (x = 0; x < 32; x++) {
		if (x < strlen(texname))
			if (texname[x] == '.')	/* cut off the suffix */
				suf = 1;
		if (x < strlen(texname) && suf == 0)
			fputc(texname[x], wal);
		else
			fputc(0, wal);
	}
	fwrite(&width, 1, 4, wal);
	fwrite(&height, 1, 4, wal);
	x = 100;
	fwrite(&x, 1, 4, wal);
	x += width * height;
	fwrite(&x, 1, 4, wal);
	x += (width / 2) * (height / 2);
	fwrite(&x, 1, 4, wal);
	x += (width / 4) * (height / 4);
	fwrite(&x, 1, 4, wal);
	for (x = 0; x < 32; x++) {
		if (next != NULL && x < strlen(next))
			fputc(next[x], wal);
		else
			fputc(0, wal);
	}
	fwrite(&flags, 1, 4, wal);
	fwrite(&contents, 1, 4, wal);
	fwrite(&value, 1, 4, wal);

	if (by & 1)
		memcpy(dstpic, srcpic, width * height);		/* copy as is. */

	else
		mip(0);
	fwrite(dstpic, 1, width * height, wal);
	mip(1);
	fwrite(dstpic, 1, width / 2 * height / 2, wal);
	mip(2);
	fwrite(dstpic, 1, width / 4 * height / 4, wal);
	mip(3);
	fwrite(dstpic, 1, width / 8 * height / 8, wal);

	fclose(wal);
	printf(" %s saved as %s", texname, dst);
	if (strlen(texname2))
		printf(" (->%s)", texname2);
	printf("\n");

	return 0;
}



/*
========
MISC
========
*/

long countval(char *str)
{
	long val = 0, n, l;

	l = strlen(str);
	for (n = 0; n < l; n++)
		if (str[n] > 47 && str[n] < 58)
			val = val * 10 + str[n] - 48;

	return val;
}

/*
======= MAIN =======
Allocates memory, loads files, calls mip-map routine, saves dest. file,
deallocates memory, and says goodbye.
*/

int main(int argc, char *argv[])
{
	char *animname = NULL;
	char ofname[256];
	char *fname[FLIST_LEN];
	char pathname[256];
	long flags = 0, contents = 0, value = 0;
	long x, y, a, nf;
	unsigned char ignpal = 0, anim = 0;
	short opn = 0, pth = 0, numsrc = 0;
	FILE *palfile;

	printf("PCX2WAL v" VERSION ", by Iikka Keränen\n\n");
	if (argc < 2) {
		printf("Usage: PCX2WAL <source> [source2] [source3] ... [options]\n");
		printf("Options:\n");
		printf("-o output   -- output file (by default, foo.pcx -> foo.wal)\n");
		printf("-t texpath  -- texture path (e.g. e1u1/)\n");
		printf("-n next     -- next texture frame in animation loop\n");
		printf("-f flags    -- default surface flags (light, slick, warp..)\n");
		printf("-c contents -- default content flags (solid, water, currents..)\n");
		printf("-v value    -- default value (for lighting)\n");
		printf("-a          -- automatic animation (wildcard/multiple texs only)\n");
		printf("-p          -- assume source palette == final palette (speedup)\n");
		printf("-d          -- use 16to8.dat to find colours (faster but less precise)\n");
		printf("\nExamples:\n");
		printf("PCX2WAL coolwall.pcx coolwall.wal coolwall\n");
		printf("PCX2WAL animwal0.pcx animwal0.wal animwal0 -n animwal1 -f 1 -v 400\n");
		printf("PCX2WAL *.pcx -a -p -d\n");
		exit(1);
	}
	hicolor = NULL;
	pathname[0] = 0;	/* make a 0-long string */

	for (x = 1; x < argc; x++) {
		if (!strcmp(argv[x] + strlen(argv[x]) - 4, ".pcx")) {
			fname[numsrc] = argv[x];
			numsrc++;
		}
		if (x < argc - 1) {
			if (!strcmp(argv[x], "-o")) {
				strcpy(ofname, argv[x + 1]);
				opn = 1;
			}
			if (!strcmp(argv[x], "-t")) {
				strcpy(pathname, argv[x + 1]);
				pth = 1;
			}
			if (!strcmp(argv[x], "-n"))
				animname = argv[x + 1];
			if (!strcmp(argv[x], "-f"))
				flags = countval(argv[x + 1]);
			if (!strcmp(argv[x], "-c"))
				contents = countval(argv[x + 1]);
			if (!strcmp(argv[x], "-v"))
				value = countval(argv[x + 1]);
		}
		if (!strcmp(argv[x], "-a"))
			anim = 1;
		if (!strcmp(argv[x], "-p"))
			ignpal = 1;
		if (!strcmp(argv[x], "-d")) {
			hicolor = (char *) malloc(65536);
			palfile = fopen("16to8.dat", "rb");
			if (!palfile) {
				printf("Error: Can't find file 16to8.pal\n");
				exit(1);
			}
			fread(hicolor, 1, 65536, palfile);
			fclose(palfile);
		}
	}

#if DEBUG
	printf("Allocing mem for palette...\n");
#endif
	palette = (char *) malloc(768);
	srcpal = (char *) malloc(768);

	palfile = fopen("palette.pal", "rb");
	if (!palfile) {
		printf("Error: Can't find file palette.pal\n");
		exit(1);
	}
	fread(palette, 1, 768, palfile);
	fclose(palfile);

	printf("%d texture(s) to be converted...\n", numsrc);

	for (x = 0; x < numsrc; x++) {
		if (anim)
			animname = NULL;

		printf("%s ...", fname[x]);
		if (anim == 1 && fname[x][0] == '_') {	/* animated texs */
			a = fname[x][1] - '0';
			nf = -1;
			for (y = 0; y < numsrc; y++)
				if (y != x) {
					if (fname[y][0] == '_' && strcmp(fname[x] + 2, fname[y] + 2) == 0) {
						if (fname[y][1] == '0' && nf == -1)
							nf = y;
						if (fname[y][1] - '0' == a + 1)
							nf = y;
					}
				}
			if (nf == -1)
				nf = x;
			animname = fname[nf];
		}
		if (!opn)
			strcpy(ofname, fname[x]);
		pcx2wal(fname[x], ofname, animname, pathname, flags, contents, value, ignpal);
	}
	free(dstpic);
	free(srcpic);
	free(palette);

	return 0;
}
