// Copyright (C) 1999-2000 Id Software, Inc.
//

// qcc.c

#include "qcc.h"

#include <time.h>
#include <stdio.h>
#if defined(WIN32)|defined(_WIN32)|defined(__NT__)|defined(__WINDOWS__)|defined(__WINDOWS_386__)
#include <direct.h> //mkdir
#include <io.h> //lseek, close, filelength
#endif

#include "l_log.h"
#include "l_script.h"
#include "l_precomp.h"

char			destfile[1024];

float			pr_globals[MAX_REGS];
int				numpr_globals;

int				pr_globals_isstring[MAX_REGS]; //MrE

char			strings[MAX_STRINGS];
int				strofs;

dstatement_t	statements[MAX_STATEMENTS];
int				numstatements;
int				statement_linenums[MAX_STATEMENTS];

dfunction_t		functions[MAX_FUNCTIONS];
char			unusedfunctionname[MAX_FUNCTIONS]; //MrE
int				numfunctions;

ddef_t			globals[MAX_GLOBALS];
int				numglobaldefs;

ddef_t			fields[MAX_FIELDS];
int				numfielddefs;

char			precache_sounds[MAX_SOUNDS][MAX_DATA_PATH];
int				precache_sounds_block[MAX_SOUNDS];
int				numsounds;

char			precache_models[MAX_MODELS][MAX_DATA_PATH];
int				precache_models_block[MAX_SOUNDS];
int				nummodels;

char			precache_files[MAX_FILES][MAX_DATA_PATH];
int				precache_files_block[MAX_SOUNDS];
int				numfiles;

//undecompilable data flag
int undecompilabledata = 0;


/*
=================
NewCheckParm
=================
*/
int NewCheckParm(char *check)
{
	int i;

	for (i = 1; i < myargc; i++)
	{
		if (myargv[i][0] == '-' || myargv[i][0] == '/')
		{
			if (!strcmpi(check, &myargv[i][1])) return i;
		} //end if
	} //end for
	return 0;
} //end of the function NewCheckParm

/*
=================
CopyString returns an offset from the string heap
=================
*/
int CopyString (char *str)
{
	int      old;

	old = strofs;
	strcpy (strings+strofs, str);
	strofs += strlen(str)+1;
	CHECK_STRINGS_BUFFER;
	return old;
} //end of the function CopyString

/*
=================
PrintStrings
=================
*/
void PrintStrings (void)
{
	int      i, l, j;

	for (i=0 ; i<strofs ; i += l)
	{
		l = strlen(strings+i) + 1;
		printf ("%5i : ",i);
		for (j=0 ; j<l ; j++)
		{
			if (strings[i+j] == '\n')
			{
				putchar ('\\');
				putchar ('n');
			} //end if
			else
			{
				putchar (strings[i+j]);
			} //end else
		} //end for
		printf ("\n");
	} //end for
} //end of the function PrintStrings

/*
=================
PrintFunctions
=================
*/
void PrintFunctions (void)
{
	int      i,j;
	dfunction_t *d;

	for (i=0 ; i<numfunctions ; i++)
	{
		d = &functions[i];
		printf ("%s : %s : %i %i (", strings + d->s_file, strings + d->s_name, d->first_statement, d->parm_start);
		for (j=0 ; j<d->numparms ; j++)
			printf ("%i ",d->parm_size[j]);
		printf (")\n");
	} //end for
} //end of the function PrintFunctions

/*
=================
PrintFields
=================
*/
void PrintFields (void)
{
	int      i;
	ddef_t   *d;

	for (i=0 ; i<numfielddefs ; i++)
	{
		d = &fields[i];
		printf ("%5i : (%i) %s\n", d->ofs, d->type, strings + d->s_name);
	} //end for
} //end of the function PrintFields

/*
=================
PrintGlobals
=================
*/
void PrintGlobals (void)
{
	int      i;
	ddef_t   *d;

	for (i=0 ; i<numglobaldefs ; i++)
	{
		d = &globals[i];
		printf ("%5i : (%i) %s\n", d->ofs, d->type, strings + d->s_name);
	} //end for
} //end of the function PrintGlobals

/*
=================
InitData
=================
*/
void InitData (void)
{
	int      i;

	numstatements = 1;
	strofs = 1;
	numfunctions = 1;
	numglobaldefs = 1;
	numfielddefs = 1;

	def_ret.ofs = OFS_RETURN;
	for (i=0 ; i<MAX_PARMS ; i++)
	{
		def_parms[i].ofs = OFS_PARM0 + 3*i;
	} //end for
} //end of the function InitData

/*
=================
ClearString
=================
*/
void ClearString(char *name)
{
	int len;
	len = strlen(name);
	memset(name, 0, len);
} //end of the function ClearString

/*
=================
RemoveAllFieldsNamed
=================
*/
void RemoveAllFieldsNamed(char *name)
{
	int i;
	char *fname;
	for (i = 0; i < numfielddefs; i++)
	{
		fname = strings + fields[i].s_name;
		if (!strcmpi(fname, name))
		{
			ClearString(fname);
//			memset(fname, 0, strlen(fname));
			fields[i].s_name = 0;
		} //end if
	} //end for
} //end of the function RemoveAllFieldsNamed

/*
=================
MandatoryFunction

returns true if the function name is mandatory
=================
*/
char *mandatoryfunctions[] =
{
	"main",
	"StartFrame",
	"PlayerPreThink",
	"PlayerPostThink",
	"ClientKill",
	"ClientConnect",
	"PutClientInServer",
	"ClientDisconnect",
	"SetNewParms",
	"SetChangeParms",
	""
};

int MandatoryFunction(char *name)
{
	int i;
	for (i = 0; strlen(mandatoryfunctions[i]); i++)
	{
		if (!strcmpi(mandatoryfunctions[i], name)) return 1;
	} //end if
	return 0;
} //end of the function MandatoryFunction

/*
=================
FunctionUsedIntern

  returns true if the function is called from somewhere in the QuakeC code
=================
*/
int FunctionUsedIntern(char *name)
{
	def_t *def;
	for (def = pr.def_head.next; def; def = def->next)
	{
		if (def->internuse)
		{
			if (def->type->type == ev_function)
			{
				if (!strcmpi(def->name, name))
				{
					return 1;
				} //end if
			} //end if
		} //end if
	} //end for
	return 0;
} //end of the function FunctionUsedIntern

/*
=================
UnusedFunctionName

returns true if the function can be renamed
=================
*/
int UnusedFunctionName(dfunction_t *f)
{
	//if it is a builtin function
//	if (f->first_statement < 0) return 0;
	//if the function is one of the mandatory ones
	if (MandatoryFunction(strings + f->s_name)) return 0;
	//if the function is not used inside the QuakeC code it is assumed
	//to be a spawn function and may not be renamed
	if (!FunctionUsedIntern(strings + f->s_name)) return 0;
	return 1;
} //end of the function UnusedFunctionName

/*
=================
PrintStatus
=================
*/
void PrintStatus(int cur, int total)
{
	printf("\b\b\b\b% 3d%%", cur * 100 / total);
} //end of the function PrintStatus

/*
=================
WriteUndecFile
=================
*/
void WriteUndecFile(void)
{
	int cur, total, i;
	int deletefields;
	def_t *d;
	FILE *fp;

	total = numfunctions << 1;
	cur = 0;
	fp = fopen("undec.txt", "w");
	if (!fp) Error("Error creating undec.txt\n");
	printf("\nWriting undec.txt     ");
	fprintf(fp, "//The following functions were called from inside\n"
				"//the QuakeC code, used in an assignment or used\n"
				"//in a state function.\n\n");
	for (i = 0; i < numfunctions; i++)
	{
		if (unusedfunctionname[i])
		{
			fprintf(fp, "%-50s %s\n", strings + functions[i].s_name,
							strings + functions[i].s_file);
		} //end if
		PrintStatus(++cur, total);
	} //end for
	fprintf(fp, "\n//The following functions were not used anywhere\n"
				"//inside the Quake C code or are builtin functions.\n\n");
	for (i = 0; i < numfunctions; i++)
	{
		if (!unusedfunctionname[i])
		{
			fprintf(fp, "%-50s %s\n", strings + functions[i].s_name,
						strings + functions[i].s_file);
		} //end if
		PrintStatus(++cur, total);
	} //end for
	fprintf(fp, "\n//removed the following entity fields:\n\n");
	deletefields = 0;
	for (d = pr.def_head.next; d; d = d->next)
	{
		if (!deletefields)
		{
			if (strstr(d->name, "start_remove_fieldnames"))
			{
				deletefields = 1;
			} //end if
		} //end if
		else
		{
			if (strstr(d->name, "end_remove_fieldnames"))
			{
				deletefields = 0;
			} //end if
			else
			{
				if (d->type->type == ev_field)
				{
					fprintf(fp, "%s\n", d->name);
				} //end if
			} //end else
		} //end else
	} //end for
	fclose(fp);
} //end of the function WriteUndecFile

/*
=================
CreateUndecompilableData
=================
*/
void CreateUnDecompilableData(void)
{
	int i, cur, total;
	int deletefields;
	char *name;
	char tmpname[1024];
	def_t *d;

	Log_Print("\nCreating undecompilable data...");
	Log_Print("\nMarking all unused function names:     ");
	total = numfunctions;
	cur = 0;
	//mark all the unused function names
	for (i = 0; i < numfunctions; i++)
	{
		//clear the name of the function if possible
		if (UnusedFunctionName(&functions[i]))
		{
			unusedfunctionname[i] = 1;
		} //end if
		PrintStatus(++cur, total);
	} //end for
	//dump a undec.txt if wanted
	if (undecompilabledata == 2) WriteUndecFile();
	//remove all function names
	Log_Print("\nRemoving all unused function names:     ");
	total = numfunctions;
	cur = 0;
	for (i = 0; i < numfunctions; i++)
	{
		//offset into the string heap of the name of the .QC file
		//the function was defined in
		name = strings + functions[i].s_file;
		memset(name, 0, strlen(name));
		functions[i].s_file = -1;//0;
		//clear the function name if unused
		if (unusedfunctionname[i])
		{
			name = strings + functions[i].s_name;
			ClearString(name);
			functions[i].s_name = 0;
		} //end if
		PrintStatus(++cur, total);
	} //end for
	Log_Print("\nRemoving all global names:     ");
	total = numglobaldefs;
	cur = 0;
	//clear all the all the variable names
	for (i = 0; i < numglobaldefs; i++)
	{
		name = strings + globals[i].s_name;
		ClearString(name);
		globals[i].s_name = 0;
		PrintStatus(++cur, total);
	} //end for
	Log_Print("\nRemoving all removable entity field names...");
	deletefields = 0;
	for (d = pr.def_head.next; d; d = d->next)
	{
		if (!deletefields)
		{
			if (strstr(d->name, "start_remove_fieldnames"))
			{
				deletefields = 1;
				//remove the start_remove_fieldnames
				strcpy(tmpname, d->name);
				RemoveAllFieldsNamed(tmpname);
			} //end if
		} //end if
		else
		{
			if (strstr(d->name, "end_remove_fieldnames"))
			{
				deletefields = 0;
				//remove the end_remove_fieldnames
				strcpy(tmpname, d->name);
				RemoveAllFieldsNamed(tmpname);
			} //end if
			else
			{
				if (d->type->type == ev_field)
				{
					strcpy(tmpname, d->name);
					RemoveAllFieldsNamed(tmpname);
				} //end if
			} //end if
		} //end else
	} //end for
	Log_Print("\n\n");
} //end of the function CreateUnDecompilableData

/*
=================
OptimizeStringHeap
=================
*/
void OptimizeStringHeap(void)
{
	char *oldstrings, *name;
	int i, oldstrofs, ofs;

	Log_Print("optimizing string heap...\n");
	//
	oldstrings = GetMemory(MAX_STRINGS * sizeof(char));
	oldstrofs = strofs;
	//
	memcpy(oldstrings, strings, strofs + 1);
	strofs = 0;
	//copy empty string at start of string heap
	CopyString("\0");
	//do function names
	for (i = 0; i < numfunctions; i++)
	{
		name = oldstrings + functions[i].s_name;
		if (strlen(name))
		{
			functions[i].s_name = CopyString(name);
		} //end if
		else functions[i].s_name = 0;
	} //end for
	for (i = 0; i < numfielddefs; i++)
	{
     	name = oldstrings + fields[i].s_name;
		//remove all the field names ending on _x, _y or _z
		if (name[strlen(name)-2] == '_')
		{
			if (name[strlen(name)-1] == 'x' ||
					name[strlen(name)-1] == 'y' ||
						name[strlen(name)-1] == 'z')
			{
				name[0] = 0;
			} //end if
		} //end if
		if (strlen(name))
		{
			fields[i].s_name = CopyString(name);;
		} //end if
		else fields[i].s_name = 0;
	} //end for
	for (i = 0; i < numglobaldefs; i++)
	{
		name = oldstrings + globals[i].s_name;
		if (strlen(name))
		{
			globals[i].s_name = CopyString(name);
		} //end if
		else globals[i].s_name = 0;
	} //end for
	//
	for (i = 0; i < numpr_globals; i++)
	{
		if (pr_globals_isstring[i])
		{
			ofs = ((int *)pr_globals)[i];
			if (ofs < 0) Error("((int *)pr_globals)[i] < 0");
			if (ofs > oldstrofs) Error("((int *)pr_globals)[i] > oldstrofs");
			name = oldstrings + ofs;
			((int *)pr_globals)[i] = CopyString(name);
		} //end if
	} //end for
	free(oldstrings);
} //end of the function OptimizeStringHeap

/*
=================
WriteData
=================
*/
void WriteData(int crc)
{
	def_t *def;
	ddef_t *dd;
	dprograms_t progs;
	int h;
	int i;

	//create the fields and globaldefs (ddef_t) out of the def_t
	for (def = pr.def_head.next; def; def = def->next)
	{
		if (def->type->type == ev_function)
		{
//			df = &functions[numfunctions];
//			numfunctions++;
		} //end if
		else if (def->type->type == ev_field)
		{
			 dd = &fields[numfielddefs];
			 numfielddefs++;
			 dd->type = def->type->aux_type->type;
			 dd->s_name = CopyString (def->name);
			 dd->ofs = G_INT(def->ofs);
		} //end else if
		dd = &globals[numglobaldefs];
		numglobaldefs++;
		dd->type = def->type->type;
		if ( !def->initialized
		&& def->type->type != ev_function
		&& def->type->type != ev_field
		&& def->scope == NULL)
		 dd->type |= DEF_SAVEGLOBGAL;
		dd->s_name = CopyString (def->name);
		dd->ofs = def->ofs;
	} //end for

	//PrintStrings ();
	//PrintFunctions ();
	//PrintFields ();
	//PrintGlobals ();

	if (undecompilabledata)
	{
		CreateUnDecompilableData();
		OptimizeStringHeap();
	} //end if

	strofs = (strofs+3)&~3;

	Log_Print("-------------------------------------------------\n");
	Log_Print("strofs        = %6i, max = %i\n", strofs, MAX_STRINGS);
	Log_Print("numstatements = %6i, max = %i\n", numstatements, MAX_STATEMENTS);
	Log_Print("numfunctions  = %6i, max = %i\n", numfunctions, MAX_FUNCTIONS);
	Log_Print("numglobaldefs = %6i, max = %i\n", numglobaldefs, MAX_GLOBALS);
	Log_Print("numfielddefs  = %6i, max = %i\n", numfielddefs, MAX_FIELDS);
	Log_Print("numpr_globals = %6i, max = %i\n", numpr_globals, MAX_REGS);
	Log_Print("nummodels     = %6i, max = %i\n", nummodels, MAX_MODELS);
	Log_Print("numsounds     = %6i, max = %i\n", numsounds, MAX_SOUNDS);
	Log_Print("numfiles      = %6i, max = %i\n", numfiles, MAX_FILES);

	h = SafeOpenWrite (destfile);
	SafeWrite(h, &progs, sizeof(progs));

	progs.ofs_strings = lseek(h, 0, SEEK_CUR);
	progs.numstrings = strofs;
	//write out the string heap
	SafeWrite(h, strings, strofs);

	progs.ofs_statements = lseek(h, 0, SEEK_CUR);
	progs.numstatements = numstatements;
	for (i = 0; i < numstatements; i++)
	{
		statements[i].op = LittleShort(statements[i].op);
		statements[i].a = LittleShort(statements[i].a);
		statements[i].b = LittleShort(statements[i].b);
		statements[i].c = LittleShort(statements[i].c);
	} //end for
	SafeWrite (h, statements, numstatements*sizeof(dstatement_t));

	progs.ofs_functions = lseek(h, 0, SEEK_CUR);
	progs.numfunctions = numfunctions;
	for (i = 0; i < numfunctions; i++)
	{
		functions[i].first_statement = LittleLong (functions[i].first_statement);
		functions[i].parm_start = LittleLong (functions[i].parm_start);
		functions[i].s_name = LittleLong (functions[i].s_name);
		functions[i].s_file = LittleLong (functions[i].s_file);
		functions[i].numparms = LittleLong (functions[i].numparms);
		functions[i].locals = LittleLong (functions[i].locals);
	} //end for
	SafeWrite (h, functions, numfunctions*sizeof(dfunction_t));

	progs.ofs_globaldefs = lseek (h, 0, SEEK_CUR);
	progs.numglobaldefs = numglobaldefs;
	for (i = 0; i < numglobaldefs; i++)
	{
		globals[i].type = LittleShort (globals[i].type);
		globals[i].ofs = LittleShort (globals[i].ofs);
		globals[i].s_name = LittleLong (globals[i].s_name);
	} //end for
	SafeWrite (h, globals, numglobaldefs*sizeof(ddef_t));

	progs.ofs_fielddefs = lseek (h, 0, SEEK_CUR);
	progs.numfielddefs = numfielddefs;
	for (i = 0; i < numfielddefs; i++)
	{
		fields[i].type = LittleShort (fields[i].type);
		fields[i].ofs = LittleShort (fields[i].ofs);
		fields[i].s_name = LittleLong (fields[i].s_name);
	} //end for
	SafeWrite (h, fields, numfielddefs*sizeof(ddef_t));

	progs.ofs_globals = lseek (h, 0, SEEK_CUR);
	progs.numglobals = numpr_globals;
	for (i=0 ; i<numpr_globals ; i++)
			((int *)pr_globals)[i] = LittleLong (((int *)pr_globals)[i]);
	SafeWrite (h, pr_globals, numpr_globals*4);

	Log_Print("total size    = %6i\n", (int) lseek(h, 0, SEEK_CUR));
	Log_Print("-------------------------------------------------\n");

	progs.entityfields = pr.size_fields;

	progs.version = PROG_VERSION;
	progs.crc = crc;

	//byte swap the header and write it out
	for (i=0 ; i<sizeof(progs)/4 ; i++)
	  ((int *)&progs)[i] = LittleLong ( ((int *)&progs)[i] );
	lseek (h, 0, SEEK_SET);
	SafeWrite (h, &progs, sizeof(progs));
	close (h);
} //end of the function WriteData

/*
===============
PR_String

Returns a string suitable for printing (no newlines, max 60 chars length)
===============
*/
char *PR_String (char *string)
{
	static char buf[80];
	char  *s;

	s = buf;
	*s++ = '"';
	while (string && *string)
	{
		if (s == buf + sizeof(buf) - 2)
			break;
		if (*string == '\n')
		{
			*s++ = '\\';
			*s++ = 'n';
		}
		else if (*string == '"')
		{
			*s++ = '\\';
			*s++ = '"';
		}
		else
			*s++ = *string;
		string++;
		if (s - buf > 60)
		{
			*s++ = '.';
			*s++ = '.';
			*s++ = '.';
			break;
		} //end if
	} //end while
	*s++ = '"';
	*s++ = 0;
	return buf;
} //end of the function PR_String

/*
=================
PR_DefForFieldOfs
=================
*/
def_t *PR_DefForFieldOfs (gofs_t ofs)
{
	def_t *d;

	for (d = pr.def_head.next; d; d = d->next)
	{
		if (d->type->type != ev_field) continue;
		if (*((int *)&pr_globals[d->ofs]) == ofs) return d;
	} //end for
	Error ("PR_DefForFieldOfs: couldn't find %i",ofs);
	return NULL;
} //end of the function PR_DefForFieldOfs

/*
============
PR_ValueString

Returns a string describing *data in a type specific manner
=============
*/
char *PR_ValueString (etype_t type, void *val)
{
	static char line[256];
	def_t    *def;
	dfunction_t *f;

	switch (type)
	{
		case ev_string:
			sprintf (line, "%s", PR_String(strings + *(int *)val));
			break;
		case ev_entity:
			sprintf (line, "entity %i", *(int *)val);
			break;
		case ev_function:
			f = functions + *(int *)val;
			if (!f)
				sprintf (line, "undefined function");
			else
				sprintf (line, "%s()", strings + f->s_name);
			break;
		case ev_field:
			def = PR_DefForFieldOfs ( *(int *)val );
			sprintf (line, ".%s", def->name);
			break;
		case ev_void:
			sprintf (line, "void");
			break;
		case ev_float:
			sprintf (line, "%5.1f", *(float *)val);
			break;
		case ev_vector:
			sprintf (line, "'%5.1f %5.1f %5.1f'", ((float *)val)[0], ((float *)val)[1], ((float *)val)[2]);
			break;
		case ev_pointer:
			sprintf (line, "pointer");
			break;
		default:
			sprintf (line, "bad type %i", type);
			break;
	}

	return line;
}

/*
============
PR_GlobalString

Returns a string with a description and the contents of a global,
padded to 20 field width
============
*/
char *PR_GlobalStringNoContents (gofs_t ofs)
{
	int      i;
	def_t *def;
	void  *val;
	static char line[128];

	val = (void *)&pr_globals[ofs];
	def = pr_global_defs[ofs];
	if (!def)
//		Error ("PR_GlobalString: no def for %i", ofs);
		sprintf (line,"%i(\??\?)", ofs);  // \??\? removes a trigraph warning
	else
		sprintf (line,"%i(%s)", ofs, def->name);

	i = strlen(line);
	for ( ; i<16 ; i++)
		strcat (line," ");
	strcat (line," ");

	return line;
}

/*
=================
PR_GlobalString
=================
*/
char *PR_GlobalString (gofs_t ofs)
{
	char  *s;
	int      i;
	def_t *def;
	void  *val;
	static char line[128];

	val = (void *)&pr_globals[ofs];
	def = pr_global_defs[ofs];
	if (!def)
		return PR_GlobalStringNoContents(ofs);
	if (def->initialized && def->type->type != ev_function)
	{
		s = PR_ValueString (def->type->type, &pr_globals[ofs]);
		sprintf (line,"%i(%s)", ofs, s);
	}
	else
		sprintf (line,"%i(%s)", ofs, def->name);

	i = strlen(line);
	for ( ; i<16 ; i++)
		strcat (line," ");
	strcat (line," ");

	return line;
}

/*
============
PR_PrintOfs
============
*/
void PR_PrintOfs (gofs_t ofs)
{
	printf ("%s\n",PR_GlobalString(ofs));
}

/*
=================
PR_PrintStatement
=================
*/
void PR_PrintStatement (dstatement_t *s)
{
	int      i;

	printf ("%4i : %4i : %s ", (int)(s - statements), statement_linenums[s-statements], pr_opcodes[s->op].opname);
	i = strlen(pr_opcodes[s->op].opname);
	for ( ; i<10 ; i++)
		printf (" ");

	if (s->op == OP_IF || s->op == OP_IFNOT)
		printf ("%sbranch %i",PR_GlobalString(s->a),s->b);
	else if (s->op == OP_GOTO)
	{
		printf ("branch %i",s->a);
	}
	else if ( (unsigned)(s->op - OP_STORE_F) < 6)
	{
		printf ("%s",PR_GlobalString(s->a));
		printf ("%s", PR_GlobalStringNoContents(s->b));
	}
	else
	{
		if (s->a)
			printf ("%s",PR_GlobalString(s->a));
		if (s->b)
			printf ("%s",PR_GlobalString(s->b));
		if (s->c)
			printf ("%s", PR_GlobalStringNoContents(s->c));
	}
	printf ("\n");
}

/*
============
PR_PrintDefs
============
*/
void PR_PrintDefs (void)
{
	def_t *d;

	for (d=pr.def_head.next ; d ; d=d->next)
		PR_PrintOfs (d->ofs);
}

/*
==============
PR_BeginCompilation

called before compiling a batch of files, clears the pr struct
==============
*/
void  PR_BeginCompilation (void *memory, int memsize)
{
	int      i;

	pr.memory = memory;
	pr.max_memory = memsize;

	numpr_globals = RESERVED_OFS;
	pr.def_tail = &pr.def_head;

	for (i=0 ; i<RESERVED_OFS ; i++)
		pr_global_defs[i] = &def_void;

	// link the function type in so state forward declarations match proper type
	pr.types = &type_function;
	type_function.next = NULL;
	pr_error_count = 0;
} //end of the function PR_BeginCompilation

/*
==============
PR_FinishCompilation

called after all files are compiled to check for errors
Returns false if errors were detected.
==============
*/
boolean  PR_FinishCompilation (void)
{
	def_t    *d;
	boolean  errors;

	errors = false;

	// check to make sure all functions prototyped have code
	for (d = pr.def_head.next; d; d = d->next)
	{
		if (d->type->type == ev_function && !d->scope)// function parms are ok
		{
//			f = G_FUNCTION(d->ofs);
//			if (!f || (!f->code && !f->builtin) )
			if (!d->initialized)
			{
				printf ("function %s was not defined\n",d->name);
				errors = true;
			} //end if
		} //end if
	} //end for
	return !errors;
} //end of the function PR_FinishCompilation

//=============================================================================

// FIXME: byte swap?

// this is a 16 bit, non-reflected CRC using the polynomial 0x1021
// and the initial and final xor values shown below...  in other words, the
// CCITT standard CRC used by XMODEM

#define CRC_INIT_VALUE  0xffff
#define CRC_XOR_VALUE   0x0000

static unsigned short crctable[256] =
{
   0x0000,  0x1021,  0x2042,  0x3063,  0x4084,  0x50a5,  0x60c6,  0x70e7,
   0x8108,  0x9129,  0xa14a,  0xb16b,  0xc18c,  0xd1ad,  0xe1ce,  0xf1ef,
   0x1231,  0x0210,  0x3273,  0x2252,  0x52b5,  0x4294,  0x72f7,  0x62d6,
   0x9339,  0x8318,  0xb37b,  0xa35a,  0xd3bd,  0xc39c,  0xf3ff,  0xe3de,
   0x2462,  0x3443,  0x0420,  0x1401,  0x64e6,  0x74c7,  0x44a4,  0x5485,
   0xa56a,  0xb54b,  0x8528,  0x9509,  0xe5ee,  0xf5cf,  0xc5ac,  0xd58d,
   0x3653,  0x2672,  0x1611,  0x0630,  0x76d7,  0x66f6,  0x5695,  0x46b4,
   0xb75b,  0xa77a,  0x9719,  0x8738,  0xf7df,  0xe7fe,  0xd79d,  0xc7bc,
   0x48c4,  0x58e5,  0x6886,  0x78a7,  0x0840,  0x1861,  0x2802,  0x3823,
   0xc9cc,  0xd9ed,  0xe98e,  0xf9af,  0x8948,  0x9969,  0xa90a,  0xb92b,
   0x5af5,  0x4ad4,  0x7ab7,  0x6a96,  0x1a71,  0x0a50,  0x3a33,  0x2a12,
   0xdbfd,  0xcbdc,  0xfbbf,  0xeb9e,  0x9b79,  0x8b58,  0xbb3b,  0xab1a,
   0x6ca6,  0x7c87,  0x4ce4,  0x5cc5,  0x2c22,  0x3c03,  0x0c60,  0x1c41,
   0xedae,  0xfd8f,  0xcdec,  0xddcd,  0xad2a,  0xbd0b,  0x8d68,  0x9d49,
   0x7e97,  0x6eb6,  0x5ed5,  0x4ef4,  0x3e13,  0x2e32,  0x1e51,  0x0e70,
   0xff9f,  0xefbe,  0xdfdd,  0xcffc,  0xbf1b,  0xaf3a,  0x9f59,  0x8f78,
   0x9188,  0x81a9,  0xb1ca,  0xa1eb,  0xd10c,  0xc12d,  0xf14e,  0xe16f,
   0x1080,  0x00a1,  0x30c2,  0x20e3,  0x5004,  0x4025,  0x7046,  0x6067,
   0x83b9,  0x9398,  0xa3fb,  0xb3da,  0xc33d,  0xd31c,  0xe37f,  0xf35e,
   0x02b1,  0x1290,  0x22f3,  0x32d2,  0x4235,  0x5214,  0x6277,  0x7256,
   0xb5ea,  0xa5cb,  0x95a8,  0x8589,  0xf56e,  0xe54f,  0xd52c,  0xc50d,
   0x34e2,  0x24c3,  0x14a0,  0x0481,  0x7466,  0x6447,  0x5424,  0x4405,
   0xa7db,  0xb7fa,  0x8799,  0x97b8,  0xe75f,  0xf77e,  0xc71d,  0xd73c,
   0x26d3,  0x36f2,  0x0691,  0x16b0,  0x6657,  0x7676,  0x4615,  0x5634,
   0xd94c,  0xc96d,  0xf90e,  0xe92f,  0x99c8,  0x89e9,  0xb98a,  0xa9ab,
   0x5844,  0x4865,  0x7806,  0x6827,  0x18c0,  0x08e1,  0x3882,  0x28a3,
   0xcb7d,  0xdb5c,  0xeb3f,  0xfb1e,  0x8bf9,  0x9bd8,  0xabbb,  0xbb9a,
   0x4a75,  0x5a54,  0x6a37,  0x7a16,  0x0af1,  0x1ad0,  0x2ab3,  0x3a92,
   0xfd2e,  0xed0f,  0xdd6c,  0xcd4d,  0xbdaa,  0xad8b,  0x9de8,  0x8dc9,
   0x7c26,  0x6c07,  0x5c64,  0x4c45,  0x3ca2,  0x2c83,  0x1ce0,  0x0cc1,
   0xef1f,  0xff3e,  0xcf5d,  0xdf7c,  0xaf9b,  0xbfba,  0x8fd9,  0x9ff8,
   0x6e17,  0x7e36,  0x4e55,  0x5e74,  0x2e93,  0x3eb2,  0x0ed1,  0x1ef0
};

void CRC_Init(unsigned short *crcvalue)
{
	*crcvalue = CRC_INIT_VALUE;
}

void CRC_ProcessByte(unsigned short *crcvalue, byte data)
{
	*crcvalue = (*crcvalue << 8) ^ crctable[(*crcvalue >> 8) ^ data];
}

unsigned short CRC_Value(unsigned short crcvalue)
{
	return crcvalue ^ CRC_XOR_VALUE;
}
//=============================================================================

/*
============
PR_WriteProgdefs

Writes the global and entity structures out
Returns a crc of the header, to be stored in the progs file for comparison
at load time.
============
*/
int PR_WriteProgdefs (char *filename)
{
	def_t *d;
	FILE  *f;
	unsigned short    crc;
	int      c;

	printf ("writing %s\n", filename);
	f = fopen (filename, "w");

	// print global vars until the first field is defined
	fprintf (f,"\n/* file generated by qcc, do not modify */\n\ntypedef struct\n{\tint\tpad[%i];\n", RESERVED_OFS);
	for (d=pr.def_head.next ; d ; d=d->next)
	{
		if (!strcmp (d->name, "end_sys_globals"))
			break;

		switch (d->type->type)
		{
			case ev_float:
				fprintf (f, "\tfloat\t%s;\n",d->name);
				break;
			case ev_vector:
				fprintf (f, "\tvec3_t\t%s;\n",d->name);
				d=d->next->next->next;  // skip the elements
				break;
			case ev_string:
				fprintf (f,"\tstring_t\t%s;\n",d->name);
				break;
			case ev_function:
				fprintf (f,"\tfunc_t\t%s;\n",d->name);
				break;
			case ev_entity:
				fprintf (f,"\tint\t%s;\n",d->name);
				break;
			default:
				fprintf (f,"\tint\t%s;\n",d->name);
				break;
		}
	}
	fprintf (f,"} globalvars_t;\n\n");

	// print all fields
	fprintf (f,"typedef struct\n{\n");
	for (d=pr.def_head.next ; d ; d=d->next)
	{
		if (!strcmp (d->name, "end_sys_fields"))
			break;

		if (d->type->type != ev_field)
			continue;

		switch (d->type->aux_type->type)
		{
			case ev_float:
				fprintf (f,"\tfloat\t%s;\n",d->name);
				break;
			case ev_vector:
				fprintf (f,"\tvec3_t\t%s;\n",d->name);
				d=d->next->next->next;  // skip the elements
				break;
			case ev_string:
				fprintf (f,"\tstring_t\t%s;\n",d->name);
				break;
			case ev_function:
				fprintf (f,"\tfunc_t\t%s;\n",d->name);
				break;
			case ev_entity:
				fprintf (f,"\tint\t%s;\n",d->name);
				break;
			default:
				fprintf (f,"\tint\t%s;\n",d->name);
				break;
		}
	}
	fprintf (f,"} entvars_t;\n\n");

	fclose (f);

	// do a crc of the file
	CRC_Init (&crc);
	f = fopen (filename, "r+");
	while ((c = fgetc(f)) != EOF)
		CRC_ProcessByte (&crc, (byte) c);

	fprintf (f,"#define PROGHEADER_CRC %i\n", crc);
	fclose (f);

	return crc;
}

/*
=================
PrintFunction
=================
*/
void PrintFunction(char *name)
{
	int      i;
	dstatement_t   *ds;
	dfunction_t    *df;

	for (i=0 ; i<numfunctions ; i++)
		if (!strcmp (name, strings + functions[i].s_name))
			break;
	if (i==numfunctions)
		Error ("No function names \"%s\"", name);
	df = functions + i;

	printf ("Statements for %s:\n", name);
	ds = statements + df->first_statement;
	while (1)
	{
		PR_PrintStatement (ds);
		if (!ds->op)
			break;
		ds++;
	} //end while
} //end of the function PrintFuncion

/*
==============================================================================

DIRECTORY COPYING / PACKFILE CREATION

==============================================================================
*/

typedef struct
{
	char  name[56];
	int      filepos, filelen;
} packfile_t;

typedef struct
{
	char  id[4];
	int      dirofs;
	int      dirlen;
} packheader_t;

packfile_t  pfiles[4096], *pf;
int         packhandle;
int         packbytes;

/*
=================
CMDPrecompilerDefinitions
=================
*/
void CMDPrecompilerDefinitions(void)
{
	int i;

	for (i = 0; i < myargc; i++)
	{
		if ((myargv[i][0] == '-' || myargv[i][0] == '/') && !stricmp(&myargv[i][1], "d"))
		{
			//if there's a next parameter and it isn't a command line option
			if (i + 1 < myargc && myargv[i+1][0] != '-' && myargv[i+1][0] != '/')
			{
				Log_Write("#define %s\n", myargv[i+1]);
				PC_AddGlobalDefine(myargv[i+1]);
			} //end if
		} //end if
	} //end for
} //end of the function CMDPrecompilerDefinitions

/*
=================
main
=================
*/
int main (int argc, char **argv)
{
	char *src;
	char filename[1024];
	int p, crc;
	char sourcedir[1024];
	clock_t start_time;

	myargc = argc;
	myargv = argv;

	Log_Open("bqcc.log");

	Log_Print("\nBloody QuakeC compiler v0.0.1, %s %s\n", __DATE__, __TIME__);
	Log_Print("BQCC is based on MrElusive's QuakeC compiler (v1.4)\n");
	Log_Print("This compiler is not supported by id Software.\n");
	Log_Print("bqcc -help for info.\n\n");

	if (NewCheckParm ("?") || NewCheckParm ("help") || NewCheckParm("h"))
	{
		Log_Print("bqcc looks for a progs.src in the current directory.\n");
		Log_Print("Command line options:\n");
        Log_Print("-qw               QuakeWorld mode (define QUAKEWORLD and use qwprogs.src)\n");
        Log_Print("-src <directory>  look for a progs.src in the specified directory\n");
		Log_Print("-undec            create progs.dat which cannot be decompiled\n");
		Log_Print("-undec+           \" and write out undec.txt\n");
		Log_Print("-asm <function>   output Quake ASM code of the specified function\n");
		Log_Print("-d <define>       add a precompiler definition\n");
		Log_Print("-?                display command line options\n");
		Log_Print("-h                \"\n");
		Log_Print("-help             \"\n");
		return EXIT_FAILURE;
	} //end if

	CMDPrecompilerDefinitions();

	p = NewCheckParm("src");
	if (p && p < argc-1 )
	{
		strcpy(sourcedir, argv[p+1]);
		if (sourcedir[strlen(sourcedir)-1] != '/' &&
			sourcedir[strlen(sourcedir)-1] != '\\')
#if defined(_WIN32) || defined(WIN32)
			strcat(sourcedir, "\\");
#else
			strcat(sourcedir, "/");
#endif
		printf("Source directory: %s\n", sourcedir);
	} //end if
	else
	{
		strcpy(sourcedir, "");
	} //end else

	InitData ();

	//check for undecompilable data
	if (NewCheckParm("undec")) undecompilabledata = 1;
	if (NewCheckParm("undec+")) undecompilabledata = 2;

    // QuakeWorld mode
    if (NewCheckParm("qw"))
    {
        PC_AddGlobalDefine ("QUAKEWORLD");
        sprintf(filename, "%sqwprogs.src", sourcedir);
    }
    else
        sprintf(filename, "%sprogs.src", sourcedir);

	LoadFile(filename, (void *)&src);

	//read the destination from the progs.src
	src = COM_Parse(src);
	if (!src)
		Error ("No destination filename.\n");
	strcpy(destfile, com_token);
	Log_Print("output file: %s\n", destfile);

	pr_dumpasm = false;

	//the time started
	start_time = clock();
	//begin the compilation
	PR_BeginCompilation(GetMemory(0x300000), 0x300000);
	//compile all the files
	do
	{
		//read next file from the progs.src
		src = COM_Parse(src);
		if (!src) break;
		sprintf(filename, "%s%s", sourcedir, com_token);
		Log_Print("%s\n", filename);
		//compile the file
		if (!PR_CompileFile(filename)) exit(1);
	} while(1);
	//finish the compilation
	if (!PR_FinishCompilation())
		Error("compilation errors");
	//
	Log_Print("compilation time was %1.2f seconds\n", ((double) clock() - start_time) / CLOCKS_PER_SEC);
	//check if a function is to be dumped in asm code
	p = NewCheckParm("asm");
	if (p)
	{
		for (p++ ; p<argc ; p++)
		{
			if (argv[p][0] == '-') break;
			PrintFunction (argv[p]);
		} //end for
	} //end if
	//write progdefs.h
	crc = PR_WriteProgdefs("progdefs.h");
	//write data file: progs.dat
	WriteData(crc);
	
	return EXIT_SUCCESS;
} //end of the function main
