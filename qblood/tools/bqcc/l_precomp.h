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


#ifndef MAX_PATH
	#define MAX_PATH			MAX_QPATH
#endif

#ifdef WIN32
	#define PATHSEPARATOR_CHAR	'\\'
#else
	#define PATHSEPARATOR_CHAR	'/'
#endif


#define DEFINE_FIXED			0x0001

#define BUILTIN_LINE			1
#define BUILTIN_FILE			2
#define BUILTIN_DATE			3
#define BUILTIN_TIME			4
#define BUILTIN_STDC			5

#define INDENT_IF				0x0001
#define INDENT_ELSE				0x0002
#define INDENT_ELIF				0x0004
#define INDENT_IFDEF			0x0008
#define INDENT_IFNDEF			0x0010

//macro definitions
typedef struct define_s
{
	char *name;							//define name
	int flags;							//define flags
	int builtin;						// > 0 if builtin define
	int numparms;						//number of define parameters
	token_t *parms;						//define parameters
	token_t *tokens;					//macro tokens (possibly containing parm tokens)
	struct define_s *next;				//next defined macro in a list
	struct define_s *hashnext;			//next define in the hash chain
} define_t;

//indents
//used for conditional compilation directives:
//#if, #else, #elif, #ifdef, #ifndef
typedef struct indent_s
{
	int type;								//indent type
	int skip;								//true if skipping current indent
	script_t *script;						//script the indent was in
	struct indent_s *next;					//next indent on the indent stack
} indent_t;

//source file
typedef struct source_s
{
	char filename[1024];					//file name of the script
	punctuation_t *punctuations;			//punctuations to use
	script_t *scriptstack;					//stack with scripts of the source
	token_t *tokens;						//tokens to read first
	define_t *defines;						//list with macro definitions
	define_t **definehash;					//hash chain with defines
	indent_t *indentstack;					//stack with indents
	int skip;								// > 0 if skipping conditional code
	token_t token;							//last read token
} source_t;


//read a token from the source
int PC_ReadToken(source_t *source, token_t *token);
//returns true when the token is available
int PC_CheckTokenString(source_t *source, char *string);
//unread the given token
void PC_UnreadSourceToken(source_t *source, token_t *token);
//read a token only if on the same line, lines are concatenated with a slash
int PC_ReadLine(source_t *source, token_t *token);
//returns true if there was a white space in front of the token
int PC_WhiteSpaceBeforeToken(token_t *token);
//add a define to the source
int PC_AddDefine(source_t *source, char *string);
//add a globals define that will be added to all opened sources
int PC_AddGlobalDefine(char *string);
//remove the given global define
int PC_RemoveGlobalDefine(char *name);
//remove all globals defines
void PC_RemoveAllGlobalDefines(void);
//add builtin defines
void PC_AddBuiltinDefines(source_t *source);
//set the punction set
void PC_SetPunctuations(source_t *source, punctuation_t *p);
//load a source file
source_t *LoadSourceFile(char *filename);
//load a source from memory
source_t *LoadSourceMemory(char *ptr, int length, char *name);
//free the given source
void FreeSource(source_t *source);
//print a source error
void SourceError(source_t *source, char *str, ...);
//print a source warning
void SourceWarning(source_t *source, char *str, ...);
