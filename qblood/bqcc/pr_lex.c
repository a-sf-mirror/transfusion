// Copyright (C) 1999-2000 Id Software, Inc.
//

// pr_lex.c

#include "qcc.h"

#ifdef PRECOMP
#include "l_script.h"
#include "l_precomp.h"
#include "l_log.h"
#endif //PRECOMP

int pr_source_line;					//current source line
char *pr_file_buf;					//buffer with the file
char *pr_file_p;					//pointer in file buffer
char *pr_line_start;				//start of current source line
int pr_bracelevel;					//level of braces
char pr_token[2048];				//current token
token_type_t pr_token_type;			//current token type
type_t *pr_immediate_type;			//immediate type
eval_t pr_immediate;				//immediate
char pr_immediate_string[2048];		//contains an immediate string if the token is a string
int pr_error_count;					//number of errors
char *pr_punctuation[] =
// longer symbols must be before a shorter partial match
{"&&", "||", "<=", ">=","==", "!=", ";", ",", "!", "*", "/",
 "(", ")", "-", "+", "=", "[", "]", "{", "}", "...", ".", "<",
 ">" , "#" , "&" , "|" , NULL};

// simple types.  function types are dynamically allocated
type_t   type_void = {ev_void, &def_void};
type_t   type_string = {ev_string, &def_string};
type_t   type_float = {ev_float, &def_float};
type_t   type_vector = {ev_vector, &def_vector};
type_t   type_entity = {ev_entity, &def_entity};
type_t   type_field = {ev_field, &def_field};
type_t   type_function = {ev_function, &def_function,NULL,&type_void};
// type_function is a void() function used for state defs
type_t   type_pointer = {ev_pointer, &def_pointer};

type_t   type_floatfield = {ev_field, &def_field, NULL, &type_float};

int      type_size[8] = {1,1,1,3,1,1,1,1};

def_t def_void = {&type_void, "temp"};
def_t def_string = {&type_string, "temp"};
def_t def_float = {&type_float, "temp"};
def_t def_vector = {&type_vector, "temp"};
def_t def_entity = {&type_entity, "temp"};
def_t def_field = {&type_field, "temp"};
def_t def_function = {&type_function, "temp"};
def_t def_pointer = {&type_pointer, "temp"};

def_t def_ret, def_parms[MAX_PARMS];

def_t *def_for_type[8] = {&def_void, &def_string, &def_float, &def_vector, &def_entity, &def_field, &def_function, &def_pointer};

void PR_LexWhitespace (void);

#ifdef PRECOMP
source_t *pr_source;
#endif //PRECOMP


/*
==============
PR_PrintNextLine
==============
*/
void PR_PrintNextLine (void)
{
	char  *t;

	printf ("%3i:",pr_source_line);
	for (t=pr_line_start ; *t && *t != '\n' ; t++)
		printf ("%c",*t);
	printf ("\n");
}

/*
==============
PR_NewLine

Call at start of file and when *pr_file_p == '\n'
==============
*/
void PR_NewLine (void)
{
	boolean  m;
   
	if (*pr_file_p == '\n')
	{
		pr_file_p++;
		m = true;
	}
	else
		m = false;

	pr_source_line++;
	pr_line_start = pr_file_p;

//	if (pr_dumpasm)
//		PR_PrintNextLine ();
	if (m)
		pr_file_p--;
}

/*
============
PR_LoadSource
============
*/
void PR_LoadSource(char *filename)
{
	pr_source_line = 0;
#ifdef PRECOMP
	pr_source = LoadSourceFile(filename);
	if (!pr_source)
		Error("couldn't load the file %s\n", filename);
#else
	LoadFile(filename, (void *)&pr_file_buf);
	pr_file_p = pr_file_buf;
	PR_NewLine();
#endif //PRECOMP
} //end of the function PR_LoadSource

/*
============
PR_FreeSource
============
*/
void PR_FreeSource(void)
{
#ifdef PRECOMP
	if (pr_source)
		FreeSource(pr_source);
#else //PRECOMP
	if (pr_file_buf)
		free(pr_file_buf);
#endif //PRECOMP
} //end of the function PR_FreeSource

/*
==============
PR_LexString

Parses a quoted string
==============
*/
void PR_LexString (void)
{
   int c, i, asciicode;
   int len;
   
   len = 0;
   //first character after the double quote
   pr_file_p++;
   //now read the string
   do
   {
      c = *pr_file_p++;
      if (!c) PR_ParseError ("EOF inside quote");
      if (c=='\n') PR_ParseError ("newline inside quote");
      if (c=='\\')
      {  // escape char
         c = *pr_file_p++;
         if (!c) PR_ParseError ("EOF inside quote");
         if (c == 'n')
         {
            c = '\n';
         } //end if
         else if (c == '"')
         {
            c = '"';
         } //end else if
//#if NEW_FEATURE
         else if (c >= '0' && c <= '9')
         {
            asciicode = c - '0';
            for (i = 0; i < 2; i++)
            {
               c = *pr_file_p++;
               if (!c) PR_ParseError ("EOF inside quote");
               if (c < '0' || c > '9')
               {
                  PR_ParseError("invalid character in ASCII code");
               } //end if
               asciicode *= 10;
               asciicode += c - '0';
            } //end for
            if (asciicode < 0x01 || asciicode > 0xFF)
            {
               PR_ParseError("invalid ASCII code");
            } //end if
            c = asciicode;
         } //end else
//#endif
         else
         {
            PR_ParseError ("Unknown escape char");
         } //end else
      } //end if
      else if (c=='\"')
      {
         pr_token[len] = 0;
         pr_token_type = tt_immediate;
         pr_immediate_type = &type_string;
         strcpy (pr_immediate_string, pr_token);
         return;
      } //end else if
      pr_token[len] = c;
      len++;
   } while(1);
} //end of the function PR_LexString

/*
==============
PR_LexNumber
==============
*/
float PR_LexNumber (void)
{
   int      c;
   int      len;
   
   len = 0;
   c = *pr_file_p;
   do
   {
      pr_token[len] = c;
      len++;
      pr_file_p++;
      c = *pr_file_p;
   } while ((c >= '0' && c<= '9') || c == '.');
   pr_token[len] = 0;
   return (float) atof (pr_token);
}

/*
==============
PR_LexVector

Parses a single quoted vector
==============
*/
void PR_LexVector (void)
{
   int      i;
   
   pr_file_p++;
   pr_token_type = tt_immediate;
   pr_immediate_type = &type_vector;
   for (i=0 ; i<3 ; i++)
   {
      pr_immediate.vector[i] = PR_LexNumber ();
      PR_LexWhitespace ();
   }
   if (*pr_file_p != '\'')
      PR_ParseError ("Bad vector");
   pr_file_p++;
}

/*
==============
PR_LexName

Parses an identifier
==============
*/
void PR_LexName (void)
{
   int      c;
   int      len;
   
   len = 0;
   c = *pr_file_p;
   do
   {
      pr_token[len] = c;
      len++;
      pr_file_p++;
      c = *pr_file_p;
   } while ( (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_' 
   || (c >= '0' && c <= '9'));
   pr_token[len] = 0;
   pr_token_type = tt_name;
}

/*
==============
PR_LexPunctuation
==============
*/
void PR_LexPunctuation (void)
{
   int      i;
   int      len;
   char  *p;
   
   pr_token_type = tt_punct;
   
   for (i=0 ; (p = pr_punctuation[i]) != NULL ; i++)
   {
      len = strlen(p);
      if (!strncmp(p, pr_file_p, len) )
      {
         strcpy (pr_token, p);
         if (p[0] == '{')
            pr_bracelevel++;
         else if (p[0] == '}')
            pr_bracelevel--;
         pr_file_p += len;
         return;
      }
   }
   
   PR_ParseError ("Unknown punctuation");
}

/*
==============
PR_LexWhitespace
==============
*/
void PR_LexWhitespace (void)
{
   int      c;

   while (1)
   {
   // skip whitespace
      while ( (c = *pr_file_p) <= ' ')
      {
         if (c=='\n')
            PR_NewLine ();
         if (c == 0)
            return;     // end of file
         pr_file_p++;
      }
      
   // skip // comments
      if (c=='/' && pr_file_p[1] == '/')
      {
         while (*pr_file_p && *pr_file_p != '\n')
            pr_file_p++;
         PR_NewLine();
         pr_file_p++;
         continue;
      }
      
   // skip /* */ comments
      if (c=='/' && pr_file_p[1] == '*')
      {
         do
         {
            pr_file_p++;
            if (pr_file_p[0]=='\n')
               PR_NewLine();
            if (pr_file_p[1] == 0)
               return;
         } while (pr_file_p[-1] != '*' || pr_file_p[0] != '/');
         pr_file_p++;
         continue;
      }
      
      break;      // a real character has been found
   }
}

//============================================================================
// frame macros

#define  MAX_FRAMES  256

char  pr_framemacros[MAX_FRAMES][16];
int      pr_nummacros;

/*
============
PR_ClearGrabMacros
============
*/
void PR_ClearGrabMacros (void)
{
   pr_nummacros = 0;
}

/*
============
PR_FindMacro
============
*/
void PR_FindMacro (void)
{
   int      i;
   
   for (i=0 ; i<pr_nummacros ; i++)
      if (!strcmp (pr_token, pr_framemacros[i]))
      {
         sprintf (pr_token,"%d", i);
         pr_token_type = tt_immediate;
         pr_immediate_type = &type_float;
         pr_immediate._float = (float) i;
         return;
      }
   PR_ParseError ("Unknown frame macro $%s", pr_token);
}

/*
============
PR_SimpeGetToken

  just parses text, returning false if an eol is reached
============
*/
#ifdef PRECOMP

boolean PR_SimpleGetToken(void)
{
	token_t token;

	if (!PC_ReadLine(pr_source, &token))
	{
		return false;
	} //end if
	strcpy(pr_token, token.string);
	return true;
} //end of the function PR_SimpeGetToken

#else //PRECOMP

boolean PR_SimpleGetToken (void)
{
   int      c;
   int      i;
   
// skip whitespace
   while ( (c = *pr_file_p) <= ' ')
   {
      if (c=='\n' || c == 0)
         return false;
      pr_file_p++;
   }
   
   i = 0;
   while ( (c = *pr_file_p) > ' ' && c != ',' && c != ';')
   {
      pr_token[i] = c;
      i++;
      pr_file_p++;
   }
   pr_token[i] = 0;
   return true;
}

#endif //PRECOMP

/*
============
PR_ParseFrame
============
*/
void PR_ParseFrame (void)
{
   while (PR_SimpleGetToken ())
   {
      strcpy (pr_framemacros[pr_nummacros], pr_token);
      pr_nummacros++;
   }
}

/*
==============
PR_LexGrab

Deals with counting sequence numbers and replacing frame macros
==============
*/
void PR_LexGrab (void)
{  
   pr_file_p++;   // skip the $
   if (!PR_SimpleGetToken ())
      PR_ParseError ("hanging $");
   
// check for $frame
   if (!strcmp (pr_token, "frame"))
   {
      PR_ParseFrame ();
      PR_Lex ();
   }
// ignore other known $commands
   else if (!strcmp (pr_token, "cd")
   || !strcmp (pr_token, "origin")
   || !strcmp (pr_token, "base")
   || !strcmp (pr_token, "flags")
   || !strcmp (pr_token, "scale")
   || !strcmp (pr_token, "skin") )
   {  // skip to end of line
      while (PR_SimpleGetToken ())
      ;
      PR_Lex ();
   }
// look for a frame name macro
   else
      PR_FindMacro ();
}

//============================================================================

/*
==============
PR_Lex

Sets pr_token, pr_token_type, and possibly pr_immediate and pr_immediate_type
==============
*/
#ifdef PRECOMP

void PR_Lex(void)
{
	token_t token, tmptoken;

	pr_token[0] = 0;

	if (!PC_ReadToken(pr_source, &token))
	{
		pr_token_type = tt_eof;
		return;
	} //end if

	pr_source_line = token.line;

	switch(token.type)
	{
		case TT_STRING: //string
		{
			StripDoubleQuotes(token.string);
			pr_token_type = tt_immediate;
			pr_immediate_type = &type_string;
			strcpy(pr_immediate_string, token.string);
			break;
		} //end case
		case TT_LITERAL: //vector
		{
			pr_token_type = tt_immediate;
			pr_immediate_type = &type_vector;
			sscanf(token.string, "'%f %f %f'",
					&pr_immediate.vector[0],
						&pr_immediate.vector[1],
							&pr_immediate.vector[2]);
			break;
		} //end case
		case TT_PUNCTUATION:
		{
			//QuakeC frame macros
			if (token.string[0] == '$')
			{
				PR_LexGrab();
				break;
			} //end if
			//special handling for negative numbers
			else if (token.string[0] == '-')
			{
				if (PC_ReadToken(pr_source, &tmptoken))
				{
					if (tmptoken.type == TT_NUMBER && !PC_WhiteSpaceBeforeToken(&tmptoken))
					{
						strcpy(pr_token, "-");
						strcat(pr_token, tmptoken.string);
						pr_token_type = tt_immediate;
						pr_immediate_type = &type_float;
						pr_immediate._float = (float) -tmptoken.floatvalue;
						break;
					} //end if
					else
					{
						PC_UnreadToken(pr_source, &tmptoken);
					} //end else
				} //end if
			} //end else if
			else if (token.string[0] == '{')
				pr_bracelevel++;
			else if (token.string[0] == '}')
				pr_bracelevel--;
			pr_token_type = tt_punct;
			strcpy(pr_token, token.string);
			break;
		} //end case
		case TT_NAME:
		{
			pr_token_type = tt_name;
			strcpy(pr_token, token.string);
			break;
		} //end case
		case TT_NUMBER:
		{
			strcat(pr_token, token.string);
			pr_token_type = tt_immediate;
			pr_immediate_type = &type_float;
			pr_immediate._float = (float) token.floatvalue;
			break;
		} //end case
	} //end switch
} //end of the function PR_Lex

#else

void PR_Lex (void)
{
   int      c;

   pr_token[0] = 0;
   
   if (!pr_file_p)
   {
      pr_token_type = tt_eof;
      return;
   }

   PR_LexWhitespace ();

   c = *pr_file_p;
      
   if (!c)
   {
      pr_token_type = tt_eof;
      return;
   }

// handle quoted strings as a unit
   if (c == '\"')
   {
      PR_LexString ();
      return;
   }

// handle quoted vectors as a unit
   if (c == '\'')
   {
      PR_LexVector ();
      return;
   }

// if the first character is a valid identifier, parse until a non-id
// character is reached
   if ( (c >= '0' && c <= '9') || ( c=='-' && pr_file_p[1]>='0' && pr_file_p[1] <='9') )
   {
      pr_token_type = tt_immediate;
      pr_immediate_type = &type_float;
      pr_immediate._float = PR_LexNumber ();
      return;
   }
   
   if ( (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_' )
   {
      PR_LexName ();
      return;
   }
   
   if (c == '$')
   {
      PR_LexGrab ();
      return;
   }
   
// parse symbol strings until a non-symbol is found
   PR_LexPunctuation ();
}
#endif

//=============================================================================

/*
============
PR_ParseError

Aborts the current file load
============
*/
void PR_ParseError (char *error, ...)
{
	va_list     argptr;
	char     string[1024];

	va_start (argptr,error);
	vsprintf (string,error,argptr);
	va_end (argptr);

	Log_Print("%s:%i:%s\n", strings + s_file, pr_source_line, string);

	longjmp (pr_parse_abort, 1);
}

/*
=============
PR_Expect

Issues an error if the current token isn't equal to string
Gets the next token
=============
*/
void PR_Expect (char *string)
{
	if (strcmp (string, pr_token))
		PR_ParseError ("expected %s, found %s",string, pr_token);
	PR_Lex ();
}

/*
=============
PR_Check

Returns true and gets the next token if the current token equals string
Returns false and does nothing otherwise
=============
*/
boolean PR_Check (char *string)
{
	if (strcmp (string, pr_token))
		return false;

	PR_Lex ();
	return true;
}

/*
============
PR_ParseName

Checks to see if the current token is a valid name
============
*/
char *PR_ParseName (void)
{
   static char ident[MAX_NAME];
   
   if (pr_token_type != tt_name)
      PR_ParseError ("not a name");
   if (strlen(pr_token) >= MAX_NAME-1)
      PR_ParseError ("name too long");
   strcpy (ident, pr_token);
   PR_Lex ();
   
   return ident;
}

/*
============
PR_FindType

Returns a preexisting complex type that matches the parm, or allocates
a new one and copies it out.
============
*/
type_t *PR_FindType (type_t *type)
{
   def_t *def;
   type_t   *check;
   int      i;
   
   for (check = pr.types ; check ; check = check->next)
   {
      if (check->type != type->type
      || check->aux_type != type->aux_type
      || check->num_parms != type->num_parms)
         continue;
   
      for (i=0 ; i< type->num_parms ; i++)
         if (check->parm_types[i] != type->parm_types[i])
            break;
         
      if (i == type->num_parms)
         return check;  
   }
   
// allocate a new one
   check = GetMemory (sizeof (*check));
   *check = *type;
   check->next = pr.types;
   pr.types = check;
   
// allocate a generic def for the type, so fields can reference it
   def = GetMemory (sizeof(def_t));
   def->name = "COMPLEX TYPE";
   def->type = check;
   check->def = def;
   return check;
}

/*
============
PR_SkipToSemicolon

For error recovery, also pops out of nested braces
============
*/
void PR_SkipToSemicolon (void)
{
   do
   {
      if (!pr_bracelevel && PR_Check (";"))
         return;
      PR_Lex ();
   } while (pr_token[0]);  // eof will return a null token
}

/*
============
PR_ParseType

Parses a variable type, including field and functions types
============
*/
char  pr_parm_names[MAX_PARMS][MAX_NAME];

type_t *PR_ParseType (void)
{
   type_t   new;
   type_t   *type;
   char  *name;
   
   if (PR_Check ("."))
   {
      memset (&new, 0, sizeof(new));
      new.type = ev_field;
      new.aux_type = PR_ParseType ();
      return PR_FindType (&new);
   }
   
   if (!strcmp (pr_token, "float") )
      type = &type_float;
   else if (!strcmp (pr_token, "vector") )
      type = &type_vector;
   else if (!strcmp (pr_token, "float") )
      type = &type_float;
   else if (!strcmp (pr_token, "entity") )
      type = &type_entity;
   else if (!strcmp (pr_token, "string") )
      type = &type_string;
   else if (!strcmp (pr_token, "void") )
      type = &type_void;
   else
   {
      PR_ParseError ("\"%s\" is not a type", pr_token);
      type = &type_float;  // shut up compiler warning
   }
   PR_Lex ();
   
   if (!PR_Check ("("))
      return type;
   
// function type
   memset (&new, 0, sizeof(new));
   new.type = ev_function;
   new.aux_type = type; // return type
   new.num_parms = 0;
   if (!PR_Check (")"))
   {
      if (PR_Check ("..."))
         new.num_parms = -1;  // variable args
      else
         do
         {
            type = PR_ParseType ();
            name = PR_ParseName ();
            strcpy (pr_parm_names[new.num_parms], name);
            new.parm_types[new.num_parms] = type;
            new.num_parms++;
         } while (PR_Check (","));
   
      PR_Expect (")");
   }
   
   return PR_FindType (&new);
}

