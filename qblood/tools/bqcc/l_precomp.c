/*
    Copyright (C) 1999-2000  Id Software, Inc.

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
*/


//Notes:			fix: PC_StringizeTokens

#include <time.h>
#include <math.h>
#include "qcc.h"
#include "l_script.h"
#include "l_precomp.h"


//#define DEBUG_EVAL

#define MAX_DEFINEPARMS			128

//directive name with parse function
typedef struct directive_s
{
	char *name;
	int (*func)(source_t *source);
} directive_t;

#define DEFINEHASHSIZE		1024


//list with global defines added to every source loaded
define_t *globaldefines;

//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
void SourceError(source_t *source, char *str, ...)
{
	char text[1024];
	va_list ap;

	va_start(ap, str);
	vsprintf(text, str, ap);
	va_end(ap);
	printf("error: file %s, line %d: %s\n", source->scriptstack->filename, source->scriptstack->line, text);
} //end of the function SourceError
//===========================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//===========================================================================
void SourceWarning(source_t *source, char *str, ...)
{
	char text[1024];
	va_list ap;

	va_start(ap, str);
	vsprintf(text, str, ap);
	va_end(ap);
	printf("warning: file %s, line %d: %s\n", source->scriptstack->filename, source->scriptstack->line, text);
} //end of the function ScriptWarning
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
void PC_PushIndent(source_t *source, int type, int skip)
{
	indent_t *indent;

	indent = (indent_t *) GetMemory(sizeof(indent_t));
	indent->type = type;
	indent->script = source->scriptstack;
	indent->skip = (skip != 0);
	source->skip += indent->skip;
	indent->next = source->indentstack;
	source->indentstack = indent;
} //end of the function PC_PushIndent
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
void PC_PopIndent(source_t *source, int *type, int *skip)
{
	indent_t *indent;

	*type = 0;
	*skip = 0;

	indent = source->indentstack;
	if (!indent) return;

	//must be an indent from the current script
	if (source->indentstack->script != source->scriptstack) return;

	*type = indent->type;
	*skip = indent->skip;
	source->indentstack = source->indentstack->next;
	source->skip -= indent->skip;
	FreeMemory(indent);
} //end of the function PC_PopIndent
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
void PC_PushScript(source_t *source, script_t *script)
{
	script_t *s;

	for (s = source->scriptstack; s; s = s->next)
	{
		if (!stricmp(s->filename, script->filename))
		{
			SourceError(source, "%s recursively included", script->filename);
			return;
		} //end if
	} //end for
	//push the script on the script stack
	script->next = source->scriptstack;
	source->scriptstack = script;
} //end of the function PC_PushScript


token_t *PC_CopyToken(token_t *token)
{
	token_t *t;

	t = (token_t *) GetMemory(sizeof(token_t));
	if (!t)
	{
		Error("out of token space\n");
		return NULL;
	} //end if
	memcpy(t, token, sizeof(token_t));
	t->next = NULL;
	return t;
}


void PC_FreeToken(token_t *token)
{
	FreeMemory(token);
}


int PC_ReadSourceToken(source_t *source, token_t *token)
{
	token_t *t;
	script_t *script;
	int type, skip;

	//if there's no token already available
	while(!source->tokens)
	{
		//if there's a token to read from the script
		if (PS_ReadToken(source->scriptstack, token)) return true;
		//if at the end of the script
		if (EndOfScript(source->scriptstack))
		{
			//remove all indents of the script
			while(source->indentstack &&
					source->indentstack->script == source->scriptstack)
			{
				SourceWarning(source, "missing #endif");
				PC_PopIndent(source, &type, &skip);
			} //end if
		} //end if
		//if this was the initial script
		if (!source->scriptstack->next) return false;
		//remove the script and return to the last one
		script = source->scriptstack;
		source->scriptstack = source->scriptstack->next;
		FreeScript(script);
	} //end while
	//copy the already available token
	memcpy(token, source->tokens, sizeof(token_t));
	//free the read token
	t = source->tokens;
	source->tokens = source->tokens->next;
	PC_FreeToken(t);
	return true;
} //end of the function PC_ReadSourceToken


void PC_UnreadSourceToken (source_t *source, token_t *token)
{
	token_t *t;

	t = PC_CopyToken(token);
	t->next = source->tokens;
	source->tokens = t;
}


int PC_ReadDefineParms(source_t *source, define_t *define, token_t **parms, int maxparms)
{
	token_t token, *t, *last;
	int i, done, lastcomma, numparms, indent;

	if (!PC_ReadSourceToken(source, &token))
	{
		SourceError(source, "define %s missing parms", define->name);
		return false;
	} //end if

	if (define->numparms > maxparms)
	{
		SourceError(source, "define with more than %d parameters", maxparms);
		return false;
	} //end if

	for (i = 0; i < define->numparms; i++)
		parms[i] = NULL;
	//if no leading "("
	if (strcmp(token.string, "("))
	{
		PC_UnreadSourceToken(source, &token);
		SourceError(source, "define %s missing parms", define->name);
		return false;
	} //end if
	//read the define parameters
	for (done = 0, numparms = 0, indent = 0; !done;)
	{
		if (numparms >= maxparms)
		{
			SourceError(source, "define %s with too many parms", define->name);
			return false;
		} //end if
		if (numparms >= define->numparms)
		{
			SourceWarning(source, "define %s has too many parms", define->name);
			return false;
		} //end if
		parms[numparms] = NULL;
		lastcomma = 1;
		last = NULL;
		while(!done)
		{
			//
			if (!PC_ReadSourceToken(source, &token))
			{
				SourceError(source, "define %s incomplete", define->name);
				return false;
			} //end if
			//
			if (!strcmp(token.string, ","))
			{
				if (indent <= 0)
				{
					if (lastcomma) SourceWarning(source, "too many comma's");
					lastcomma = 1;
					break;
				} //end if
			} //end if
			lastcomma = 0;
			//
			if (!strcmp(token.string, "("))
			{
				indent++;
			} //end if
			else if (!strcmp(token.string, ")"))
			{
				if (--indent < 0)
				{
					if (!parms[define->numparms-1])
					{
						SourceWarning(source, "too few define parms");
					} //end if
					done = 1;
					break;
				} //end if
			} //end if
			//
			if (numparms < define->numparms)
			{
				//
				t = PC_CopyToken(&token);
				t->next = NULL;
				if (last) last->next = t;
				else parms[numparms] = t;
				last = t;
			} //end if
		} //end while
		numparms++;
	} //end for
	return true;
} //end of the function PC_ReadDefineParms
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_StringizeTokens(token_t *tokens, token_t *token)
{
	token_t *t;

	token->type = TT_STRING;
	token->whitespace_p = NULL;
	token->endwhitespace_p = NULL;
	token->string[0] = '\0';
	strcat(token->string, "\"");
	for (t = tokens; t; t = t->next)
	{
		strncat(token->string, t->string, MAX_TOKEN - strlen(token->string));
	} //end for
	strncat(token->string, "\"", MAX_TOKEN - strlen(token->string));
	return true;
} //end of the function PC_StringizeTokens
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_MergeTokens(token_t *t1, token_t *t2)
{
	//merging of a name with a name or number
	if (t1->type == TT_NAME && (t2->type == TT_NAME || t2->type == TT_NUMBER))
	{
		strcat(t1->string, t2->string);
		return true;
	} //end if
	//merging of two strings
	if (t1->type == TT_STRING && t2->type == TT_STRING)
	{
		//remove trailing double quote
		t1->string[strlen(t1->string)-1] = '\0';
		//concat without leading double quote
		strcat(t1->string, &t2->string[1]);
		return true;
	} //end if
	//FIXME: merging of two number of the same sub type
	return false;
} //end of the function PC_MergeTokens


int PC_NameHash(char *name)
{
	int register hash, i;

	hash = 0;
	for (i = 0; name[i] != '\0'; i++)
		hash += name[i] * (119 + i);

	hash = (hash ^ (hash >> 10) ^ (hash >> 20)) & (DEFINEHASHSIZE-1);
	return hash;
}


//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
void PC_AddDefineToHash(define_t *define, define_t **definehash)
{
	int hash;

	hash = PC_NameHash(define->name);
	define->hashnext = definehash[hash];
	definehash[hash] = define;
} //end of the function PC_AddDefineToHash
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
define_t *PC_FindHashedDefine(define_t **definehash, char *name)
{
	define_t *d;
	int hash;

	hash = PC_NameHash(name);
	for (d = definehash[hash]; d; d = d->hashnext)
	{
		if (!strcmp(d->name, name)) return d;
	} //end for
	return NULL;
} //end of the function PC_FindHashedDefine

//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
define_t *PC_FindDefine(define_t *defines, char *name)
{
	define_t *d;

	for (d = defines; d; d = d->next)
	{
		if (!strcmp(d->name, name)) return d;
	} //end for
	return NULL;
} //end of the function PC_FindDefine
//============================================================================
//
// Parameter:				-
// Returns:					number of the parm
//								if no parm found with the given name -1 is returned
// Changes Globals:		-
//============================================================================
int PC_FindDefineParm(define_t *define, char *name)
{
	token_t *p;
	int i;

	i = 0;
	for (p = define->parms; p; p = p->next)
	{
		if (!strcmp(p->string, name)) return i;
		i++;
	} //end for
	return -1;
} //end of the function PC_FindDefineParm
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
void PC_FreeDefine(define_t *define)
{
	token_t *t, *next;

	//free the define parameters
	for (t = define->parms; t; t = next)
	{
		next = t->next;
		PC_FreeToken(t);
	} //end for
	//free the define tokens
	for (t = define->tokens; t; t = next)
	{
		next = t->next;
		PC_FreeToken(t);
	} //end for
	//free the define
	FreeMemory(define);
} //end of the function PC_FreeDefine
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
void PC_AddBuiltinDefines(source_t *source)
{
	int i;
	define_t *define;
	struct builtin
	{
		char *string;
		int builtin;
	} builtin[] = {
		{"__LINE__",	BUILTIN_LINE},
		{"__FILE__",	BUILTIN_FILE},
		{"__DATE__",	BUILTIN_DATE},
		{"__TIME__",	BUILTIN_TIME},
		{NULL, 0}
	};

	for (i = 0; builtin[i].string; i++)
	{
		define = (define_t *) GetMemory(sizeof(define_t) + strlen(builtin[i].string) + 1);
		memset(define, 0, sizeof(define_t));
		define->name = (char *) define + sizeof(define_t);
		strcpy(define->name, builtin[i].string);
		define->flags |= DEFINE_FIXED;
		define->builtin = builtin[i].builtin;
		//add the define to the source
		PC_AddDefineToHash(define, source->definehash);
	} //end for
} //end of the function PC_AddBuiltinDefines
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_ExpandBuiltinDefine(source_t *source, token_t *deftoken, define_t *define,
										token_t **firsttoken, token_t **lasttoken)
{
	token_t *token;
	time_t t;
	char *curtime;

	token = PC_CopyToken(deftoken);
	switch(define->builtin)
	{
		case BUILTIN_LINE:
		{
			sprintf(token->string, "%d", deftoken->line);
			token->intvalue = deftoken->line;
			token->floatvalue = deftoken->line;
			token->type = TT_NUMBER;
			token->subtype = TT_DECIMAL | TT_INTEGER;
			*firsttoken = token;
			*lasttoken = token;
			break;
		} //end case
		case BUILTIN_FILE:
		{
			strcpy(token->string, source->scriptstack->filename);
			token->type = TT_NAME;
			token->subtype = strlen(token->string);
			*firsttoken = token;
			*lasttoken = token;
			break;
		} //end case
		case BUILTIN_DATE:
		{
			t = time(NULL);
			curtime = ctime(&t);
			strcpy(token->string, "\"");
			strncat(token->string, curtime+4, 7);
			strncat(token->string+7, curtime+20, 4);
			strcat(token->string, "\"");
			free(curtime);
			token->type = TT_NAME;
			token->subtype = strlen(token->string);
			*firsttoken = token;
			*lasttoken = token;
			break;
		} //end case
		case BUILTIN_TIME:
		{
			t = time(NULL);
			curtime = ctime(&t);
			strcpy(token->string, "\"");
			strncat(token->string, curtime+11, 8);
			strcat(token->string, "\"");
			free(curtime);
			token->type = TT_NAME;
			token->subtype = strlen(token->string);
			*firsttoken = token;
			*lasttoken = token;
			break;
		} //end case
		default:
		{
			*firsttoken = NULL;
			*lasttoken = NULL;
		} //end case
	} //end switch
	return true;
} //end of the function PC_ExpandBuiltinDefine
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_ExpandDefine(source_t *source, token_t *deftoken, define_t *define,
										token_t **firsttoken, token_t **lasttoken)
{
	token_t *parms[MAX_DEFINEPARMS], *dt, *pt, *t;
	token_t *t1, *t2, *first, *last, *nextpt, token;
	int parmnum, i;

	//if it is a builtin define
	if (define->builtin)
	{
		return PC_ExpandBuiltinDefine(source, deftoken, define, firsttoken, lasttoken);
	} //end if
	//if the define has parameters
	if (define->numparms)
	{
		if (!PC_ReadDefineParms(source, define, parms, MAX_DEFINEPARMS)) return false;
#ifdef DEBUG_EVAL
		for (i = 0; i < define->numparms; i++)
		{
			Log_Write("define parms %d:", i);
			for (pt = parms[i]; pt; pt = pt->next)
			{
				Log_Write("%s\n", pt->string);
			} //end for
		} //end for
		Log_Write("\n");
#endif //DEBUG_EVAL
	} //end if
	//empty list at first
	first = NULL;
	last = NULL;
	//create a list with tokens of the expanded define
	for (dt = define->tokens; dt; dt = dt->next)
	{
		parmnum = -1;
		//if the token is a name, it could be a define parameter
		if (dt->type == TT_NAME)
		{
			parmnum = PC_FindDefineParm(define, dt->string);
		} //end if
		//if it is a define parameter
		if (parmnum >= 0)
		{
			for (pt = parms[parmnum]; pt; pt = pt->next)
			{
				t = PC_CopyToken(pt);
				//add the token to the list
				t->next = NULL;
				if (last) last->next = t;
				else first = t;
				last = t;
			} //end for
		} //end if
		else
		{
			//if stringizing operator
			if (dt->string[0] == '#' && dt->string[1] == '\0')
			{
				//the stringizing operator must be followed by a define parameter
				if (dt->next) parmnum = PC_FindDefineParm(define, dt->next->string);
				else parmnum = -1;
				//
				if (parmnum >= 0)
				{
					//step over the stringizing operator
					dt = dt->next;
					//stringize the define parameter tokens
					if (!PC_StringizeTokens(parms[parmnum], &token))
					{
						SourceError(source, "can't stringize tokens");
						return false;
					} //end if
					t = PC_CopyToken(&token);
				} //end if
				else
				{
					SourceWarning(source, "stringizing operator without define parameter");
					continue;
				} //end if
			} //end if
			else
			{
				t = PC_CopyToken(dt);
			} //end else
			//add the token to the list
			t->next = NULL;
			if (last) last->next = t;
			else first = t;
			last = t;
		} //end else
	} //end for
	//check for the merging operator
	for (t = first; t; )
	{
		if (t->next)
		{
			//if the merging operator
			if (t->next->string[0] == '#' && t->next->string[1] == '#')
			{
				t1 = t;
				t2 = t->next->next;
				if (t2)
				{
					if (!PC_MergeTokens(t1, t2))
					{
						SourceError(source, "can't merge %s with %s", t1->string, t2->string);
						return false;
					} //end if
					PC_FreeToken(t1->next);
					t1->next = t2->next;
					if (t2 == last) last = t1;
					PC_FreeToken(t2);
					continue;
				} //end if
			} //end if
		} //end if
		t = t->next;
	} //end for

	// Copy the deftoken infos about whitespaces into the first token
	first->endwhitespace_p = deftoken->endwhitespace_p;
	first->whitespace_p = deftoken->whitespace_p;

	//store the first and last token of the list
	*firsttoken = first;
	*lasttoken = last;
	//free all the parameter tokens
	for (i = 0; i < define->numparms; i++)
	{
		for (pt = parms[i]; pt; pt = nextpt)
		{
			nextpt = pt->next;
			PC_FreeToken(pt);
		} //end for
	} //end for
	//
	return true;
} //end of the function PC_ExpandDefine
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_ExpandDefineIntoSource(source_t *source, token_t *deftoken, define_t *define)
{
	token_t *firsttoken, *lasttoken;

	if (!PC_ExpandDefine(source, deftoken, define, &firsttoken, &lasttoken)) return false;

	if (firsttoken && lasttoken)
	{
		lasttoken->next = source->tokens;
		source->tokens = firsttoken;
		return true;
	} //end if
	return false;
} //end of the function PC_ExpandDefineIntoSource
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
void PC_ConvertPath(char *path)
{
	char *ptr;

	//remove double path seperators
	for (ptr = path; *ptr;)
	{
		if ((*ptr == '\\' || *ptr == '/') &&
				(*(ptr+1) == '\\' || *(ptr+1) == '/'))
		{
			strcpy(ptr, ptr+1);
		} //end if
		else
		{
			ptr++;
		} //end else
	} //end while
	//set OS dependent path seperators
	for (ptr = path; *ptr;)
	{
		if (*ptr == '/' || *ptr == '\\') *ptr = PATHSEPARATOR_CHAR;
		ptr++;
	} //end while
} //end of the function PC_ConvertPath
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_Directive_include(source_t *source)
{
	script_t *script;
	token_t token;
	char path[MAX_PATH];

	if (source->skip > 0) return true;
	//
	if (!PC_ReadSourceToken(source, &token))
	{
		SourceError(source, "#include without file name");
		return false;
	} //end if
	if (token.linescrossed > 0)
	{
		SourceError(source, "#include without file name");
		return false;
	} //end if

	if (token.type == TT_STRING)
	{
		StripDoubleQuotes(token.string);
		PC_ConvertPath(token.string);
		script = LoadScriptFile(token.string);
	}
	// FIXME: what is this case supposed to do exactly?
	else if (token.type == TT_PUNCTUATION && *token.string == '<')
	{
		path[0] = '\0';
		while(PC_ReadSourceToken(source, &token))
		{
			if (token.linescrossed > 0)
			{
				PC_UnreadSourceToken(source, &token);
				break;
			} //end if
			if (token.type == TT_PUNCTUATION && *token.string == '>') break;
			strncat(path, token.string, MAX_PATH);
		} //end while
		if (*token.string != '>')
		{
			SourceWarning(source, "#include missing trailing >");
		} //end if
		if (!strlen(path))
		{
			SourceError(source, "#include without file name between < >");
			return false;
		} //end if
		PC_ConvertPath(path);
		script = LoadScriptFile(path);
	}
	else
	{
		SourceError(source, "#include without file name");
		return false;
	}

	if (!script)
	{
		SourceError(source, "file %s not found", path);
		return false;
	} //end if
	PC_PushScript(source, script);

	return true;
}


//============================================================================
// reads a token from the current line, continues reading on the next
// line only if a backslash '\' is encountered.
//============================================================================
int PC_ReadLine(source_t *source, token_t *token)
{
	int crossline;

	crossline = 0;
	do
	{
		if (!PC_ReadSourceToken(source, token)) return false;

		if (token->linescrossed > crossline)
		{
			PC_UnreadSourceToken(source, token);
			return false;
		} //end if
		crossline = 1;
	} while(!strcmp(token->string, "\\"));
	return true;
} //end of the function PC_ReadLine



int PC_WhiteSpaceBeforeToken(token_t *token)
{
	return token->endwhitespace_p - token->whitespace_p > 0;
}


//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
void PC_ClearTokenWhiteSpace(token_t *token)
{
	token->whitespace_p = NULL;
	token->endwhitespace_p = NULL;
	token->linescrossed = 0;
} //end of the function PC_ClearTokenWhiteSpace
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_Directive_undef(source_t *source)
{
	token_t token;
	define_t *define, *lastdefine;
	int hash;

	if (source->skip > 0) return true;
	//
	if (!PC_ReadLine(source, &token))
	{
		SourceError(source, "undef without name");
		return false;
	} //end if
	if (token.type != TT_NAME)
	{
		PC_UnreadSourceToken(source, &token);
		SourceError(source, "expected name, found %s", token.string);
		return false;
	} //end if

	hash = PC_NameHash(token.string);
	for (lastdefine = NULL, define = source->definehash[hash]; define; define = define->hashnext)
	{
		if (!strcmp(define->name, token.string))
		{
			if (define->flags & DEFINE_FIXED)
			{
				SourceWarning(source, "can't undef %s", token.string);
			} //end if
			else
			{
				if (lastdefine) lastdefine->hashnext = define->hashnext;
				else source->definehash[hash] = define->hashnext;
				PC_FreeDefine(define);
			} //end else
			break;
		} //end if
		lastdefine = define;
	} //end for
	return true;
} //end of the function PC_Directive_undef
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_Directive_define(source_t *source)
{
	token_t token, *t, *last;
	define_t *define;

	if (source->skip > 0) return true;
	//
	if (!PC_ReadLine(source, &token))
	{
		SourceError(source, "#define without name");
		return false;
	} //end if
	if (token.type != TT_NAME)
	{
		PC_UnreadSourceToken(source, &token);
		SourceError(source, "expected name after #define, found %s", token.string);
		return false;
	} //end if
	//check if the define already exists
	define = PC_FindHashedDefine(source->definehash, token.string);
	if (define)
	{
		if (define->flags & DEFINE_FIXED)
		{
			SourceError(source, "can't redefine %s", token.string);
			return false;
		} //end if
		SourceWarning(source, "redefinition of %s", token.string);
		//unread the define name before executing the #undef directive
		PC_UnreadSourceToken(source, &token);
		if (!PC_Directive_undef(source)) return false;
		//if the define was not removed (define->flags & DEFINE_FIXED)
		define = PC_FindHashedDefine(source->definehash, token.string);
	} //end if
	//allocate define
	define = (define_t *) GetMemory(sizeof(define_t) + strlen(token.string) + 1);
	memset(define, 0, sizeof(define_t));
	define->name = (char *) define + sizeof(define_t);
	strcpy(define->name, token.string);
	//add the define to the source
	PC_AddDefineToHash(define, source->definehash);
	//if nothing is defined, just return
	if (!PC_ReadLine(source, &token)) return true;
	//if it is a define with parameters
	if (!PC_WhiteSpaceBeforeToken(&token) && !strcmp(token.string, "("))
	{
		//read the define parameters
		last = NULL;
		if (!PC_CheckTokenString(source, ")"))
		{
			while(1)
			{
				if (!PC_ReadLine(source, &token))
				{
					SourceError(source, "expected define parameter");
					return false;
				} //end if
				//if it isn't a name
				if (token.type != TT_NAME)
				{
					SourceError(source, "invalid define parameter");
					return false;
				} //end if
				//
				if (PC_FindDefineParm(define, token.string) >= 0)
				{
					SourceError(source, "two the same define parameters");
					return false;
				} //end if
				//add the define parm
				t = PC_CopyToken(&token);
				PC_ClearTokenWhiteSpace(t);
				t->next = NULL;
				if (last) last->next = t;
				else define->parms = t;
				last = t;
				define->numparms++;
				//read next token
				if (!PC_ReadLine(source, &token))
				{
					SourceError(source, "define parameters not terminated");
					return false;
				} //end if
				//
				if (!strcmp(token.string, ")")) break;
				//then it must be a comma
				if (strcmp(token.string, ","))
				{
					SourceError(source, "define not terminated");
					return false;
				} //end if
			} //end while
		} //end if
		if (!PC_ReadLine(source, &token)) return true;
	} //end if
	//read the defined stuff
	last = NULL;
	do
	{
		t = PC_CopyToken(&token);
		if (t->type == TT_NAME && !strcmp(t->string, define->name))
		{
			SourceError(source, "recursive define (removed recursion)");
			continue;
		} //end if
		PC_ClearTokenWhiteSpace(t);
		t->next = NULL;
		if (last) last->next = t;
		else define->tokens = t;
		last = t;
	} while(PC_ReadLine(source, &token));
	//
	if (last)
	{
		//check for merge operators at the beginning or end
		if (!strcmp(define->tokens->string, "##") ||
				!strcmp(last->string, "##"))
		{
			SourceError(source, "define with misplaced ##");
			return false;
		} //end if
	} //end if
	return true;
} //end of the function PC_Directive_define
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
define_t *PC_DefineFromString(char *string)
{
	script_t *script;
	source_t src;
	token_t *t;
	int res, i;
	define_t *def;

	script = LoadScriptMemory(string, strlen(string), "*extern");
	//create a new source
	memset(&src, 0, sizeof(source_t));
	strncpy(src.filename, "*extern", MAX_PATH);
	src.scriptstack = script;
	src.definehash = GetClearedMemory(DEFINEHASHSIZE * sizeof(define_t *));
	//create a define from the source
	res = PC_Directive_define(&src);
	//free any tokens if left
	for (t = src.tokens; t; t = src.tokens)
	{
		src.tokens = src.tokens->next;
		PC_FreeToken(t);
	} //end for

	def = NULL;
	for (i = 0; i < DEFINEHASHSIZE; i++)
	{
		if (src.definehash[i])
		{
			def = src.definehash[i];
			break;
		} //end if
	} //end for
	//
	FreeMemory(src.definehash);
	//
	FreeScript(script);
	//if the define was created succesfully
	if (res > 0) return def;
	//free the define is created
	if (src.defines) PC_FreeDefine(def);
	//
	return NULL;
} //end of the function PC_DefineFromString
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_AddDefine(source_t *source, char *string)
{
	define_t *define;

	define = PC_DefineFromString(string);
	if (!define) return false;
	PC_AddDefineToHash(define, source->definehash);
	return true;
} //end of the function PC_AddDefine
//============================================================================
// add a globals define that will be added to all opened sources
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_AddGlobalDefine(char *string)
{
	define_t *define;

	define = PC_DefineFromString(string);
	if (!define) return false;
	define->next = globaldefines;
	globaldefines = define;
	return true;
} //end of the function PC_AddGlobalDefine
//============================================================================
// remove the given global define
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_RemoveGlobalDefine(char *name)
{
	define_t *define;

	define = PC_FindDefine(globaldefines, name);
	if (define)
	{
		PC_FreeDefine(define);
		return true;
	} //end if
	return false;
} //end of the function PC_RemoveGlobalDefine
//============================================================================
// remove all globals defines
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
void PC_RemoveAllGlobalDefines(void)
{
	define_t *define;

	for (define = globaldefines; define; define = globaldefines)
	{
		globaldefines = globaldefines->next;
		PC_FreeDefine(define);
	} //end for
} //end of the function PC_RemoveAllGlobalDefines
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
define_t *PC_CopyDefine(source_t *source, define_t *define)
{
	define_t *newdefine;
	token_t *token, *newtoken, *lasttoken;

	newdefine = (define_t *) GetMemory(sizeof(define_t) + strlen(define->name) + 1);
	//copy the define name
	newdefine->name = (char *) newdefine + sizeof(define_t);
	strcpy(newdefine->name, define->name);
	newdefine->flags = define->flags;
	newdefine->builtin = define->builtin;
	newdefine->numparms = define->numparms;
	//the define is not linked
	newdefine->next = NULL;
	newdefine->hashnext = NULL;
	//copy the define tokens
	newdefine->tokens = NULL;
	for (lasttoken = NULL, token = define->tokens; token; token = token->next)
	{
		newtoken = PC_CopyToken(token);
		newtoken->next = NULL;
		if (lasttoken) lasttoken->next = newtoken;
		else newdefine->tokens = newtoken;
		lasttoken = newtoken;
	} //end for
	//copy the define parameters
	newdefine->parms = NULL;
	for (lasttoken = NULL, token = define->parms; token; token = token->next)
	{
		newtoken = PC_CopyToken(token);
		newtoken->next = NULL;
		if (lasttoken) lasttoken->next = newtoken;
		else newdefine->parms = newtoken;
		lasttoken = newtoken;
	} //end for
	return newdefine;
} //end of the function PC_CopyDefine
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
void PC_AddGlobalDefinesToSource(source_t *source)
{
	define_t *define, *newdefine;

	for (define = globaldefines; define; define = define->next)
	{
		newdefine = PC_CopyDefine(source, define);
		PC_AddDefineToHash(newdefine, source->definehash);
	} //end for
} //end of the function PC_AddGlobalDefinesToSource
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_Directive_if_def(source_t *source, int type)
{
	token_t token;
	define_t *d;
	int skip;

	if (!PC_ReadLine(source, &token))
	{
		SourceError(source, "#ifdef without name");
		return false;
	} //end if
	if (token.type != TT_NAME)
	{
		PC_UnreadSourceToken(source, &token);
		SourceError(source, "expected name after #ifdef, found %s", token.string);
		return false;
	} //end if
	d = PC_FindHashedDefine(source->definehash, token.string);
	skip = (type == INDENT_IFDEF) == (d == NULL);
	PC_PushIndent(source, type, skip);
	return true;
} //end of the function PC_Directiveif_def
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_Directive_ifdef(source_t *source)
{
	return PC_Directive_if_def(source, INDENT_IFDEF);
} //end of the function PC_Directive_ifdef
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_Directive_ifndef(source_t *source)
{
	return PC_Directive_if_def(source, INDENT_IFNDEF);
} //end of the function PC_Directive_ifndef
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_Directive_else(source_t *source)
{
	int type, skip;

	PC_PopIndent(source, &type, &skip);
	if (!type)
	{
		SourceError(source, "misplaced #else");
		return false;
	} //end if
	if (type == INDENT_ELSE)
	{
		SourceError(source, "#else after #else");
		return false;
	} //end if
	PC_PushIndent(source, INDENT_ELSE, !skip);
	return true;
} //end of the function PC_Directive_else
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_Directive_endif(source_t *source)
{
	int type, skip;

	PC_PopIndent(source, &type, &skip);
	if (!type)
	{
		SourceError(source, "misplaced #endif");
		return false;
	} //end if
	return true;
} //end of the function PC_Directive_endif
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
typedef struct operator_s
{
	int operator;
	int priority;
	int parentheses;
	struct operator_s *prev, *next;
} operator_t;

typedef struct value_s
{
	signed long int intvalue;
	double floatvalue;
	int parentheses;
	struct value_s *prev, *next;
} value_t;

int PC_OperatorPriority(int op)
{
	switch(op)
	{
		case P_MUL: return 15;
		case P_DIV: return 15;
		case P_MOD: return 15;
		case P_ADD: return 14;
		case P_SUB: return 14;

		case P_LOGIC_AND: return 7;
		case P_LOGIC_OR: return 6;
		case P_LOGIC_GEQ: return 12;
		case P_LOGIC_LEQ: return 12;
		case P_LOGIC_EQ: return 11;
		case P_LOGIC_UNEQ: return 11;

		case P_LOGIC_NOT: return 16;
		case P_LOGIC_GREATER: return 12;
		case P_LOGIC_LESS: return 12;

		case P_RSHIFT: return 13;
		case P_LSHIFT: return 13;

		case P_BIN_AND: return 10;
		case P_BIN_OR: return 8;
		case P_BIN_XOR: return 9;
		case P_BIN_NOT: return 16;

		case P_COLON: return 5;
		case P_QUESTIONMARK: return 5;
	} //end switch
	return false;
} //end of the function PC_OperatorPriority


#define MAX_VALUES		64
#define MAX_OPERATORS	64
#define AllocValue(val)									\
	if (numvalues >= MAX_VALUES) {						\
		SourceError(source, "out of value space\n");		\
		error = 1;										\
		break;											\
	}													\
	else												\
		val = &value_heap[numvalues++];
#define FreeValue(val)
//
#define AllocOperator(op)								\
	if (numoperators >= MAX_OPERATORS) {				\
		SourceError(source, "out of operator space\n");	\
		error = 1;										\
		break;											\
	}													\
	else												\
		op = &operator_heap[numoperators++];
#define FreeOperator(op)

int PC_EvaluateTokens(source_t *source, token_t *tokens, signed long int *intvalue,
																	double *floatvalue, int integer)
{
	operator_t *o, *firstoperator, *lastoperator;
	value_t *v, *firstvalue, *lastvalue, *v1, *v2;
	token_t *t;
	int brace = 0;
	int parentheses = 0;
	int error = 0;
	int lastwasvalue = 0;
	int negativevalue = 0;
	int questmarkintvalue = 0;
	double questmarkfloatvalue = 0;
	int gotquestmarkvalue = false;
	int lastoperatortype = 0;
	//
	operator_t operator_heap[MAX_OPERATORS];
	int numoperators = 0;
	value_t value_heap[MAX_VALUES];
	int numvalues = 0;

	firstoperator = lastoperator = NULL;
	firstvalue = lastvalue = NULL;
	if (intvalue) *intvalue = 0;
	if (floatvalue) *floatvalue = 0;
	for (t = tokens; t; t = t->next)
	{
		switch(t->type)
		{
			case TT_NAME:
			{
				if (lastwasvalue || negativevalue)
				{
					SourceError(source, "syntax error in #if/#elif");
					error = 1;
					break;
				} //end if
				if (strcmp(t->string, "defined"))
				{
					SourceError(source, "undefined name %s in #if/#elif", t->string);
					error = 1;
					break;
				} //end if
				t = t->next;
				if (!strcmp(t->string, "("))
				{
					brace = true;
					t = t->next;
				} //end if
				if (!t || t->type != TT_NAME)
				{
					SourceError(source, "defined without name in #if/#elif");
					error = 1;
					break;
				} //end if
				//v = (value_t *) GetClearedMemory(sizeof(value_t));
				AllocValue(v);
				if (PC_FindHashedDefine(source->definehash, t->string))
				{
					v->intvalue = 1;
					v->floatvalue = 1;
				} //end if
				else
				{
					v->intvalue = 0;
					v->floatvalue = 0;
				} //end else
				v->parentheses = parentheses;
				v->next = NULL;
				v->prev = lastvalue;
				if (lastvalue) lastvalue->next = v;
				else firstvalue = v;
				lastvalue = v;
				if (brace)
				{
					t = t->next;
					if (!t || strcmp(t->string, ")"))
					{
						SourceError(source, "defined without ) in #if/#elif");
						error = 1;
						break;
					} //end if
				} //end if
				brace = false;
				// defined() creates a value
				lastwasvalue = 1;
				break;
			} //end case
			case TT_NUMBER:
			{
				if (lastwasvalue)
				{
					SourceError(source, "syntax error in #if/#elif");
					error = 1;
					break;
				} //end if
				//v = (value_t *) GetClearedMemory(sizeof(value_t));
				AllocValue(v);
				if (negativevalue)
				{
					v->intvalue = - (signed int) t->intvalue;
					v->floatvalue = - t->floatvalue;
				} //end if
				else
				{
					v->intvalue = t->intvalue;
					v->floatvalue = t->floatvalue;
				} //end else
				v->parentheses = parentheses;
				v->next = NULL;
				v->prev = lastvalue;
				if (lastvalue) lastvalue->next = v;
				else firstvalue = v;
				lastvalue = v;
				//last token was a value
				lastwasvalue = 1;
				//
				negativevalue = 0;
				break;
			} //end case
			case TT_PUNCTUATION:
			{
				if (negativevalue)
				{
					SourceError(source, "misplaced minus sign in #if/#elif");
					error = 1;
					break;
				} //end if
				if (t->subtype == P_PARENTHESESOPEN)
				{
					parentheses++;
					break;
				} //end if
				else if (t->subtype == P_PARENTHESESCLOSE)
				{
					parentheses--;
					if (parentheses < 0)
					{
						SourceError(source, "too many ) in #if/#elsif");
						error = 1;
					} //end if
					break;
				} //end else if
				//check for invalid operators on floating point values
				if (!integer)
				{
					if (t->subtype == P_BIN_NOT || t->subtype == P_MOD ||
						t->subtype == P_RSHIFT || t->subtype == P_LSHIFT ||
						t->subtype == P_BIN_AND || t->subtype == P_BIN_OR ||
						t->subtype == P_BIN_XOR)
					{
						SourceError(source, "illigal operator %s on floating point operands\n", t->string);
						error = 1;
						break;
					} //end if
				} //end if
				switch(t->subtype)
				{
					case P_LOGIC_NOT:
					case P_BIN_NOT:
					{
						if (lastwasvalue)
						{
							SourceError(source, "! or ~ after value in #if/#elif");
							error = 1;
							break;
						} //end if
						break;
					} //end case
					case P_SUB:
					{
						if (!lastwasvalue)
						{
							negativevalue = 1;
							break;
						} //end if
					} //end case

					case P_MUL:
					case P_DIV:
					case P_MOD:
					case P_ADD:

					case P_LOGIC_AND:
					case P_LOGIC_OR:
					case P_LOGIC_GEQ:
					case P_LOGIC_LEQ:
					case P_LOGIC_EQ:
					case P_LOGIC_UNEQ:

					case P_LOGIC_GREATER:
					case P_LOGIC_LESS:

					case P_RSHIFT:
					case P_LSHIFT:

					case P_BIN_AND:
					case P_BIN_OR:
					case P_BIN_XOR:

					case P_COLON:
					case P_QUESTIONMARK:
					{
						if (!lastwasvalue)
						{
							SourceError(source, "operator %s after operator in #if/#elif", t->string);
							error = 1;
							break;
						} //end if
						break;
					} //end case
					default:
					{
						SourceError(source, "invalid operator %s in #if/#elif", t->string);
						error = 1;
						break;
					} //end default
				} //end switch
				if (!error && !negativevalue)
				{
					//o = (operator_t *) GetClearedMemory(sizeof(operator_t));
					AllocOperator(o);
					o->operator = t->subtype;
					o->priority = PC_OperatorPriority(t->subtype);
					o->parentheses = parentheses;
					o->next = NULL;
					o->prev = lastoperator;
					if (lastoperator) lastoperator->next = o;
					else firstoperator = o;
					lastoperator = o;
					lastwasvalue = 0;
				} //end if
				break;
			} //end case
			default:
			{
				SourceError(source, "unknown %s in #if/#elif", t->string);
				error = 1;
				break;
			} //end default
		} //end switch
		if (error) break;
	} //end for
	if (!error)
	{
		if (!lastwasvalue)
		{
			SourceError(source, "trailing operator in #if/#elif");
			error = 1;
		} //end if
		else if (parentheses)
		{
			SourceError(source, "too many ( in #if/#elif");
			error = 1;
		} //end else if
	} //end if
	//
	gotquestmarkvalue = false;
	questmarkintvalue = 0;
	questmarkfloatvalue = 0;
	//while there are operators
	while(!error && firstoperator)
	{
		v = firstvalue;
		for (o = firstoperator; o->next; o = o->next)
		{
			//if the current operator is nested deeper in parentheses
			//than the next operator
			if (o->parentheses > o->next->parentheses) break;
			//if the current and next operator are nested equally deep in parentheses
			if (o->parentheses == o->next->parentheses)
			{
				//if the priority of the current operator is equal or higher
				//than the priority of the next operator
				if (o->priority >= o->next->priority) break;
			} //end if
			//if the arity of the operator isn't equal to 1
			if (o->operator != P_LOGIC_NOT
					&& o->operator != P_BIN_NOT) v = v->next;
			//if there's no value or no next value
			if (!v)
			{
				SourceError(source, "mising values in #if/#elif");
				error = 1;
				break;
			} //end if
		} //end for
		if (error) break;
		v1 = v;
		v2 = v->next;
#ifdef DEBUG_EVAL
		if (integer)
		{
			Log_Write("operator %s, value1 = %d", PunctuationFromNum(source->scriptstack, o->operator), v1->intvalue);
			if (v2) Log_Write("value2 = %d", v2->intvalue);
		} //end if
		else
		{
			Log_Write("operator %s, value1 = %f", PunctuationFromNum(source->scriptstack, o->operator), v1->floatvalue);
			if (v2) Log_Write("value2 = %f", v2->floatvalue);
		} //end else
#endif //DEBUG_EVAL
		switch(o->operator)
		{
			case P_LOGIC_NOT:		v1->intvalue = !v1->intvalue;
									v1->floatvalue = !v1->floatvalue; break;
			case P_BIN_NOT:			v1->intvalue = ~v1->intvalue;
									break;
			case P_MUL:				v1->intvalue *= v2->intvalue;
									v1->floatvalue *= v2->floatvalue; break;
			case P_DIV:				if (!v2->intvalue || !v2->floatvalue)
									{
										SourceError(source, "divide by zero in #if/#elif\n");
										error = 1;
										break;
									}
									v1->intvalue /= v2->intvalue;
									v1->floatvalue /= v2->floatvalue; break;
			case P_MOD:				if (!v2->intvalue)
									{
										SourceError(source, "divide by zero in #if/#elif\n");
										error = 1;
										break;
									}
									v1->intvalue %= v2->intvalue; break;
			case P_ADD:				v1->intvalue += v2->intvalue;
									v1->floatvalue += v2->floatvalue; break;
			case P_SUB:				v1->intvalue -= v2->intvalue;
									v1->floatvalue -= v2->floatvalue; break;
			case P_LOGIC_AND:		v1->intvalue = v1->intvalue && v2->intvalue;
									v1->floatvalue = v1->floatvalue && v2->floatvalue; break;
			case P_LOGIC_OR:		v1->intvalue = v1->intvalue || v2->intvalue;
									v1->floatvalue = v1->floatvalue || v2->floatvalue; break;
			case P_LOGIC_GEQ:		v1->intvalue = v1->intvalue >= v2->intvalue;
									v1->floatvalue = v1->floatvalue >= v2->floatvalue; break;
			case P_LOGIC_LEQ:		v1->intvalue = v1->intvalue <= v2->intvalue;
									v1->floatvalue = v1->floatvalue <= v2->floatvalue; break;
			case P_LOGIC_EQ:		v1->intvalue = v1->intvalue == v2->intvalue;
									v1->floatvalue = v1->floatvalue == v2->floatvalue; break;
			case P_LOGIC_UNEQ:		v1->intvalue = v1->intvalue != v2->intvalue;
									v1->floatvalue = v1->floatvalue != v2->floatvalue; break;
			case P_LOGIC_GREATER:	v1->intvalue = v1->intvalue > v2->intvalue;
									v1->floatvalue = v1->floatvalue > v2->floatvalue; break;
			case P_LOGIC_LESS:		v1->intvalue = v1->intvalue < v2->intvalue;
									v1->floatvalue = v1->floatvalue < v2->floatvalue; break;
			case P_RSHIFT:			v1->intvalue >>= v2->intvalue;
									break;
			case P_LSHIFT:			v1->intvalue <<= v2->intvalue;
									break;
			case P_BIN_AND:			v1->intvalue &= v2->intvalue;
									break;
			case P_BIN_OR:			v1->intvalue |= v2->intvalue;
									break;
			case P_BIN_XOR:			v1->intvalue ^= v2->intvalue;
									break;
			case P_COLON:
			{
				if (!gotquestmarkvalue)
				{
					SourceError(source, ": without ? in #if/#elif");
					error = 1;
					break;
				} //end if
				if (integer)
				{
					if (!questmarkintvalue) v1->intvalue = v2->intvalue;
				} //end if
				else
				{
					if (!questmarkfloatvalue) v1->floatvalue = v2->floatvalue;
				} //end else
				gotquestmarkvalue = false;
				break;
			} //end case
			case P_QUESTIONMARK:
			{
				if (gotquestmarkvalue)
				{
					SourceError(source, "? after ? in #if/#elif");
					error = 1;
					break;
				} //end if
				questmarkintvalue = v1->intvalue;
				questmarkfloatvalue = v1->floatvalue;
				gotquestmarkvalue = true;
				break;
			} //end if
		} //end switch
#ifdef DEBUG_EVAL
		if (integer) Log_Write("result value = %d", v1->intvalue);
		else Log_Write("result value = %f", v1->floatvalue);
#endif //DEBUG_EVAL
		if (error) break;
		lastoperatortype = o->operator;
		//if not an operator with arity 1
		if (o->operator != P_LOGIC_NOT
				&& o->operator != P_BIN_NOT)
		{
			//remove the second value if not question mark operator
			if (o->operator != P_QUESTIONMARK) v = v->next;
			//
			if (v->prev) v->prev->next = v->next;
			else firstvalue = v->next;
			if (v->next) v->next->prev = v->prev;
			else lastvalue = v->prev;
			//FreeMemory(v);
			FreeValue(v);
		} //end if
		//remove the operator
		if (o->prev) o->prev->next = o->next;
		else firstoperator = o->next;
		if (o->next) o->next->prev = o->prev;
		else lastoperator = o->prev;
		//FreeMemory(o);
		FreeOperator(o);
	} //end while
	if (firstvalue)
	{
		if (intvalue) *intvalue = firstvalue->intvalue;
		if (floatvalue) *floatvalue = firstvalue->floatvalue;
	} //end if
	for (o = firstoperator; o; o = lastoperator)
	{
		lastoperator = o->next;
		//FreeMemory(o);
		FreeOperator(o);
	} //end for
	for (v = firstvalue; v; v = lastvalue)
	{
		lastvalue = v->next;
		//FreeMemory(v);
		FreeValue(v);
	} //end for
	if (!error) return true;
	if (intvalue) *intvalue = 0;
	if (floatvalue) *floatvalue = 0;
	return false;
} //end of the function PC_EvaluateTokens
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_Evaluate(source_t *source, signed long int *intvalue,
												double *floatvalue, int integer)
{
	token_t token, *firsttoken, *lasttoken;
	token_t *t, *nexttoken;
	define_t *define;
	int defined = false;

	if (intvalue) *intvalue = 0;
	if (floatvalue) *floatvalue = 0;
	//
	if (!PC_ReadLine(source, &token))
	{
		SourceError(source, "no value after #if/#elif");
		return false;
	} //end if
	firsttoken = NULL;
	lasttoken = NULL;
	do
	{
		//if the token is a name
		if (token.type == TT_NAME)
		{
			if (defined)
			{
				defined = false;
				t = PC_CopyToken(&token);
				t->next = NULL;
				if (lasttoken) lasttoken->next = t;
				else firsttoken = t;
				lasttoken = t;
			} //end if
			else if (!strcmp(token.string, "defined"))
			{
				defined = true;
				t = PC_CopyToken(&token);
				t->next = NULL;
				if (lasttoken) lasttoken->next = t;
				else firsttoken = t;
				lasttoken = t;
			} //end if
			else
			{
				//then it must be a define
				define = PC_FindHashedDefine(source->definehash, token.string);
				if (!define)
				{
					SourceError(source, "can't evaluate %s, not defined", token.string);
					return false;
				} //end if
				if (!PC_ExpandDefineIntoSource(source, &token, define)) return false;
			} //end else
		} //end if
		//if the token is a number or a punctuation
		else if (token.type == TT_NUMBER || token.type == TT_PUNCTUATION)
		{
			t = PC_CopyToken(&token);
			t->next = NULL;
			if (lasttoken) lasttoken->next = t;
			else firsttoken = t;
			lasttoken = t;
		} //end else
		else //can't evaluate the token
		{
			SourceError(source, "can't evaluate %s", token.string);
			return false;
		} //end else
	} while(PC_ReadLine(source, &token));
	//
	if (!PC_EvaluateTokens(source, firsttoken, intvalue, floatvalue, integer)) return false;
	//
#ifdef DEBUG_EVAL
	Log_Write("eval:");
#endif //DEBUG_EVAL
	for (t = firsttoken; t; t = nexttoken)
	{
#ifdef DEBUG_EVAL
		Log_Write(" %s", t->string);
#endif //DEBUG_EVAL
		nexttoken = t->next;
		PC_FreeToken(t);
	} //end for
#ifdef DEBUG_EVAL
	if (integer) Log_Write("eval result: %d", *intvalue);
	else Log_Write("eval result: %f", *floatvalue);
#endif //DEBUG_EVAL
	//
	return true;
} //end of the function PC_Evaluate
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_DollarEvaluate(source_t *source, signed long int *intvalue,
												double *floatvalue, int integer)
{
	int indent, defined = false;
	token_t token, *firsttoken, *lasttoken;
	token_t *t, *nexttoken;
	define_t *define;

	if (intvalue) *intvalue = 0;
	if (floatvalue) *floatvalue = 0;
	//
	if (!PC_ReadSourceToken(source, &token))
	{
		SourceError(source, "no leading ( after $evalint/$evalfloat");
		return false;
	} //end if
	if (!PC_ReadSourceToken(source, &token))
	{
		SourceError(source, "nothing to evaluate");
		return false;
	} //end if
	indent = 1;
	firsttoken = NULL;
	lasttoken = NULL;
	do
	{
		//if the token is a name
		if (token.type == TT_NAME)
		{
			if (defined)
			{
				defined = false;
				t = PC_CopyToken(&token);
				t->next = NULL;
				if (lasttoken) lasttoken->next = t;
				else firsttoken = t;
				lasttoken = t;
			} //end if
			else if (!strcmp(token.string, "defined"))
			{
				defined = true;
				t = PC_CopyToken(&token);
				t->next = NULL;
				if (lasttoken) lasttoken->next = t;
				else firsttoken = t;
				lasttoken = t;
			} //end if
			else
			{
				//then it must be a define
				define = PC_FindHashedDefine(source->definehash, token.string);
				if (!define)
				{
					SourceError(source, "can't evaluate %s, not defined", token.string);
					return false;
				} //end if
				if (!PC_ExpandDefineIntoSource(source, &token, define)) return false;
			} //end else
		} //end if
		//if the token is a number or a punctuation
		else if (token.type == TT_NUMBER || token.type == TT_PUNCTUATION)
		{
			if (*token.string == '(') indent++;
			else if (*token.string == ')') indent--;
			if (indent <= 0) break;
			t = PC_CopyToken(&token);
			t->next = NULL;
			if (lasttoken) lasttoken->next = t;
			else firsttoken = t;
			lasttoken = t;
		} //end else
		else //can't evaluate the token
		{
			SourceError(source, "can't evaluate %s", token.string);
			return false;
		} //end else
	} while(PC_ReadSourceToken(source, &token));
	//
	if (!PC_EvaluateTokens(source, firsttoken, intvalue, floatvalue, integer)) return false;
	//
#ifdef DEBUG_EVAL
	Log_Write("$eval:");
#endif //DEBUG_EVAL
	for (t = firsttoken; t; t = nexttoken)
	{
#ifdef DEBUG_EVAL
		Log_Write(" %s", t->string);
#endif //DEBUG_EVAL
		nexttoken = t->next;
		PC_FreeToken(t);
	} //end for
#ifdef DEBUG_EVAL
	if (integer) Log_Write("$eval result: %d", *intvalue);
	else Log_Write("$eval result: %f", *floatvalue);
#endif //DEBUG_EVAL
	//
	return true;
} //end of the function PC_DollarEvaluate
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_Directive_elif(source_t *source)
{
	signed long int value;
	int type, skip;

	PC_PopIndent(source, &type, &skip);
	if (!type || type == INDENT_ELSE)
	{
		SourceError(source, "misplaced #elif");
		return false;
	} //end if
	if (!PC_Evaluate(source, &value, NULL, true)) return false;
	skip = (value == 0);
	PC_PushIndent(source, INDENT_ELIF, skip);
	return true;
} //end of the function PC_Directive_elif
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_Directive_if(source_t *source)
{
	signed long int value;
	int skip;

	if (!PC_Evaluate(source, &value, NULL, true)) return false;
	skip = (value == 0);
	PC_PushIndent(source, INDENT_IF, skip);
	return true;
} //end of the function PC_Directive
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_Directive_line(source_t *source)
{
	SourceError(source, "#line directive not supported");
	return false;
} //end of the function PC_Directive_line
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_Directive_error(source_t *source)
{
	token_t token;

	strcpy(token.string, "");
	PC_ReadSourceToken(source, &token);
	SourceError(source, "#error directive: %s", token.string);
	return false;
} //end of the function PC_Directive_error
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_Directive_pragma(source_t *source)
{
	token_t token;

	SourceWarning(source, "#pragma directive not supported");
	while(PC_ReadLine(source, &token)) ;
	return true;
} //end of the function PC_Directive_pragma
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
void UnreadSignToken(source_t *source)
{
	token_t token;

	token.line = source->scriptstack->line;
	token.whitespace_p = source->scriptstack->script_p;
	token.endwhitespace_p = source->scriptstack->script_p;
	token.linescrossed = 0;
	strcpy(token.string, "-");
	token.type = TT_PUNCTUATION;
	token.subtype = P_SUB;
	PC_UnreadSourceToken(source, &token);
} //end of the function UnreadSignToken
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_Directive_eval(source_t *source)
{
	signed long int value;
	token_t token;

	if (!PC_Evaluate(source, &value, NULL, true)) return false;
	//
	token.line = source->scriptstack->line;
	token.whitespace_p = source->scriptstack->script_p;
	token.endwhitespace_p = source->scriptstack->script_p;
	token.linescrossed = 0;
	sprintf(token.string, "%d", abs(value));
	token.type = TT_NUMBER;
	token.subtype = TT_INTEGER|TT_LONG|TT_DECIMAL;
	PC_UnreadSourceToken(source, &token);
	if (value < 0) UnreadSignToken(source);
	return true;
} //end of the function PC_Directive_eval
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_Directive_evalfloat(source_t *source)
{
	double value;
	token_t token;

	if (!PC_Evaluate(source, NULL, &value, false)) return false;
	token.line = source->scriptstack->line;
	token.whitespace_p = source->scriptstack->script_p;
	token.endwhitespace_p = source->scriptstack->script_p;
	token.linescrossed = 0;
	sprintf(token.string, "%1.2f", fabs(value));
	token.type = TT_NUMBER;
	token.subtype = TT_FLOAT|TT_LONG|TT_DECIMAL;
	PC_UnreadSourceToken(source, &token);
	if (value < 0) UnreadSignToken(source);
	return true;
} //end of the function PC_Directive_evalfloat
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
directive_t directives[20] =
{
	{"if", PC_Directive_if},
	{"ifdef", PC_Directive_ifdef},
	{"ifndef", PC_Directive_ifndef},
	{"elif", PC_Directive_elif},
	{"else", PC_Directive_else},
	{"endif", PC_Directive_endif},
	{"include", PC_Directive_include},
	{"define", PC_Directive_define},
	{"undef", PC_Directive_undef},
	{"line", PC_Directive_line},
	{"error", PC_Directive_error},
	{"pragma", PC_Directive_pragma},
	{"eval", PC_Directive_eval},
	{"evalfloat", PC_Directive_evalfloat},
	{NULL, NULL}
};

int PC_ReadDirective(source_t *source)
{
	token_t token;
	int i;

	//read the directive name
	if (!PC_ReadSourceToken(source, &token))
	{
		SourceError(source, "found # without name");
		return false;
	} //end if
	//directive name must be on the same line
	if (token.linescrossed > 0)
	{
		PC_UnreadSourceToken(source, &token);
		SourceError(source, "found # at end of line");
		return false;
	} //end if
	//if if is a name
	if (token.type == TT_NAME)
	{
		//find the precompiler directive
		for (i = 0; directives[i].name; i++)
		{
			if (!strcmp(directives[i].name, token.string))
			{
				return directives[i].func(source);
			} //end if
		} //end for
	} //end if
	SourceError(source, "unknown precompiler directive %s", token.string);
	return false;
} //end of the function PC_ReadDirective
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_DollarDirective_evalint(source_t *source)
{
	signed long int value;
	token_t token;

	if (!PC_DollarEvaluate(source, &value, NULL, true)) return false;
	//
	token.line = source->scriptstack->line;
	token.whitespace_p = source->scriptstack->script_p;
	token.endwhitespace_p = source->scriptstack->script_p;
	token.linescrossed = 0;
	sprintf(token.string, "%d", abs(value));
	token.type = TT_NUMBER;
	token.subtype = TT_INTEGER|TT_LONG|TT_DECIMAL;
	token.intvalue = value;
	token.floatvalue = value;

	PC_UnreadSourceToken(source, &token);
	if (value < 0) UnreadSignToken(source);
	return true;
} //end of the function PC_DollarDirective_evalint
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_DollarDirective_evalfloat(source_t *source)
{
	double value;
	token_t token;

	if (!PC_DollarEvaluate(source, NULL, &value, false)) return false;
	token.line = source->scriptstack->line;
	token.whitespace_p = source->scriptstack->script_p;
	token.endwhitespace_p = source->scriptstack->script_p;
	token.linescrossed = 0;
	sprintf(token.string, "%1.2f", fabs(value));
	token.type = TT_NUMBER;
	token.subtype = TT_FLOAT|TT_LONG|TT_DECIMAL;
	token.intvalue = (unsigned long) value;
	token.floatvalue = value;

	PC_UnreadSourceToken(source, &token);
	if (value < 0) UnreadSignToken(source);
	return true;
} //end of the function PC_DollarDirective_evalfloat
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
directive_t dollardirectives[20] =
{
	{"evalint", PC_DollarDirective_evalint},
	{"evalfloat", PC_DollarDirective_evalfloat},
	{NULL, NULL}
};

int PC_ReadDollarDirective(source_t *source)
{
	token_t token;
	int i;

	//read the directive name
	if (!PC_ReadSourceToken(source, &token))
	{
		SourceError(source, "found $ without name");
		return false;
	} //end if
	//directive name must be on the same line
	if (token.linescrossed > 0)
	{
		PC_UnreadSourceToken(source, &token);
		SourceError(source, "found $ at end of line");
		return false;
	} //end if
	//if if is a name
	if (token.type == TT_NAME)
	{
		//find the precompiler directive
		for (i = 0; dollardirectives[i].name; i++)
		{
			if (!strcmp(dollardirectives[i].name, token.string))
			{
				return dollardirectives[i].func(source);
			} //end if
		} //end for
	} //end if
	PC_UnreadSourceToken(source, &token);
	SourceError(source, "unknown precompiler directive %s", token.string);
	return false;
} //end of the function PC_ReadDirective

//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int BuiltinFunction(source_t *source)
{
	token_t token;

	if (!PC_ReadSourceToken(source, &token)) return false;
	if (token.type == TT_NUMBER)
	{
		PC_UnreadSourceToken(source, &token);
		return true;
	} //end if
	else
	{
		PC_UnreadSourceToken(source, &token);
		return false;
	} //end else
} //end of the function BuiltinFunction
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int QuakeCMacro(source_t *source)
{
	int i;
	token_t token;

	if (!PC_ReadSourceToken(source, &token)) return true;
	if (token.type != TT_NAME)
	{
		PC_UnreadSourceToken(source, &token);
		return true;
	} //end if
	//find the precompiler directive
	for (i = 0; dollardirectives[i].name; i++)
	{
		if (!strcmp(dollardirectives[i].name, token.string))
		{
			PC_UnreadSourceToken(source, &token);
			return false;
		} //end if
	} //end for
	PC_UnreadSourceToken(source, &token);
	return true;
} //end of the function QuakeCMacro

//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PC_ReadToken(source_t *source, token_t *token)
{
	define_t *define;

	while(1)
	{
		if (!PC_ReadSourceToken(source, token)) return false;
		//check for precompiler directives
		if (token->type == TT_PUNCTUATION && *token->string == '#')
		{
			if (!BuiltinFunction(source))
			{
				//read the precompiler directive
				if (!PC_ReadDirective(source)) return false;
				continue;
			} //end if
		} //end if
		if (token->type == TT_PUNCTUATION && *token->string == '$')
		{
			if (!QuakeCMacro(source))
			{
				//read the precompiler directive
				if (!PC_ReadDollarDirective(source)) return false;
				continue;
			} //end if
		} //end if
		//if skipping source because of conditional compilation
		if (source->skip) continue;
		//if the token is a name
		if (token->type == TT_NAME)
		{
			//check if the name is a define macro
			define = PC_FindHashedDefine(source->definehash, token->string);
			//if it is a define macro
			if (define)
			{
				//expand the defined macro
				if (!PC_ExpandDefineIntoSource(source, token, define)) return false;
				continue;
			} //end if
		} //end if
		//copy token for unreading
		memcpy(&source->token, token, sizeof(token_t));
		//found a token
		return true;
	} //end while
} //end of the function PC_ReadToken


int PC_CheckTokenString(source_t *source, char *string)
{
	token_t tok;

	if (!PC_ReadToken(source, &tok)) return false;
	//if the token is available
	if (!strcmp(tok.string, string)) return true;
	//
	PC_UnreadSourceToken(source, &tok);
	return false;
} //end of the function PC_CheckTokenString


source_t *LoadSourceFile(char *filename )
{
	source_t *source;
	script_t *script;

	script = LoadScriptFile(filename);
	if (!script) return NULL;

	script->next = NULL;

	source = (source_t *) GetMemory(sizeof(source_t));
	memset(source, 0, sizeof(source_t));

	strncpy(source->filename, filename, MAX_PATH);
	source->scriptstack = script;
	source->tokens = NULL;
	source->defines = NULL;
	source->indentstack = NULL;
	source->skip = 0;

	source->definehash = GetClearedMemory(DEFINEHASHSIZE * sizeof(define_t *));
	PC_AddGlobalDefinesToSource(source);
	return source;
} //end of the function LoadSourceFile


void FreeSource(source_t *source)
{
	script_t *script;
	token_t *token;
	define_t *define;
	indent_t *indent;
	int i;

	//free all the scripts
	while(source->scriptstack)
	{
		script = source->scriptstack;
		source->scriptstack = source->scriptstack->next;
		FreeScript(script);
	} //end for
	//free all the tokens
	while(source->tokens)
	{
		token = source->tokens;
		source->tokens = source->tokens->next;
		PC_FreeToken(token);
	} //end for
	for (i = 0; i < DEFINEHASHSIZE; i++)
	{
		while(source->definehash[i])
		{
			define = source->definehash[i];
			source->definehash[i] = source->definehash[i]->hashnext;
			PC_FreeDefine(define);
		} //end while
	} //end for
	//free all indents
	while(source->indentstack)
	{
		indent = source->indentstack;
		source->indentstack = source->indentstack->next;
		FreeMemory(indent);
	} //end for
	//
	if (source->definehash) FreeMemory(source->definehash);
	//free the source itself
	FreeMemory(source);
} //end of the function FreeSource
