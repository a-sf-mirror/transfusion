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


#include "qcc.h"
#include "l_script.h"


//longer punctuations first
punctuation_t default_punctuations[] =
{
	//binary operators
	{">>=",P_RSHIFT_ASSIGN, NULL},
	{"<<=",P_LSHIFT_ASSIGN, NULL},
	//
	{"...",P_PARMS, NULL},
	//define merge operator
	{"##",P_PRECOMPMERGE, NULL},
	//logic operators
	{"&&",P_LOGIC_AND, NULL},
	{"||",P_LOGIC_OR, NULL},
	{">=",P_LOGIC_GEQ, NULL},
	{"<=",P_LOGIC_LEQ, NULL},
	{"==",P_LOGIC_EQ, NULL},
	{"!=",P_LOGIC_UNEQ, NULL},
	//arithmatic operators
	{"*=",P_MUL_ASSIGN, NULL},
	{"/=",P_DIV_ASSIGN, NULL},
	{"%=",P_MOD_ASSIGN, NULL},
	{"+=",P_ADD_ASSIGN, NULL},
	{"-=",P_SUB_ASSIGN, NULL},
	{"++",P_INC, NULL},
	{"--",P_DEC, NULL},
	//binary operators
	{"&=",P_BIN_AND_ASSIGN, NULL},
	{"|=",P_BIN_OR_ASSIGN, NULL},
	{"^=",P_BIN_XOR_ASSIGN, NULL},
	{">>",P_RSHIFT, NULL},
	{"<<",P_LSHIFT, NULL},
	//reference operators
	{"->",P_POINTERREF, NULL},
	//C++
	{"::",P_CPP1, NULL},
	{".*",P_CPP2, NULL},
	//arithmatic operators
	{"*",P_MUL, NULL},
	{"/",P_DIV, NULL},
	{"%",P_MOD, NULL},
	{"+",P_ADD, NULL},
	{"-",P_SUB, NULL},
	{"=",P_ASSIGN, NULL},
	//binary operators
	{"&",P_BIN_AND, NULL},
	{"|",P_BIN_OR, NULL},
	{"^",P_BIN_XOR, NULL},
	{"~",P_BIN_NOT, NULL},
	//logic operators
	{"!",P_LOGIC_NOT, NULL},
	{">",P_LOGIC_GREATER, NULL},
	{"<",P_LOGIC_LESS, NULL},
	//reference operator
	{".",P_REF, NULL},
	//seperators
	{",",P_COMMA, NULL},
	{";",P_SEMICOLON, NULL},
	//label indication
	{":",P_COLON, NULL},
	//if statement
	{"?",P_QUESTIONMARK, NULL},
	//embracements
	{"(",P_PARENTHESESOPEN, NULL},
	{")",P_PARENTHESESCLOSE, NULL},
	{"{",P_BRACEOPEN, NULL},
	{"}",P_BRACECLOSE, NULL},
	{"[",P_SQBRACKETOPEN, NULL},
	{"]",P_SQBRACKETCLOSE, NULL},
	//
	{"\\",P_BACKSLASH, NULL},
	//precompiler operator
	{"#",P_PRECOMP, NULL},
	{"$",P_DOLLAR, NULL},
	{NULL, 0}
};

//===========================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//===========================================================================
void PS_CreatePunctuationTable(script_t *script, punctuation_t *punctuations)
{
	int i;
	punctuation_t *p, *lastp, *newp;

	//get memory for the table
	if (!script->punctuationtable) script->punctuationtable = (punctuation_t **)
												GetMemory(256 * sizeof(punctuation_t *));
	memset(script->punctuationtable, 0, 256 * sizeof(punctuation_t *));
	//add the punctuations in the list to the punctuation table
	for (i = 0; punctuations[i].p; i++)
	{
		newp = &punctuations[i];
		lastp = NULL;
		//sort the punctuations in this table entry on length (longer punctuations first)
		for (p = script->punctuationtable[(unsigned int) newp->p[0]]; p; p = p->next)
		{
			if (strlen(p->p) < strlen(newp->p))
			{
				newp->next = p;
				if (lastp) lastp->next = newp;
				else script->punctuationtable[(unsigned int) newp->p[0]] = newp;
				break;
			} //end if
			lastp = p;
		} //end for
		if (!p)
		{
			newp->next = NULL;
			if (lastp) lastp->next = newp;
			else script->punctuationtable[(unsigned int) newp->p[0]] = newp;
		} //end if
	} //end for
} //end of the function PS_CreatePunctuationTable


char *PunctuationFromNum(script_t *script, int num)
{
	int i;

	for (i = 0; script->punctuations[i].p; i++)
		if (script->punctuations[i].n == num)
			return script->punctuations[i].p;

	return "unknown punctuation";
}


//===========================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//===========================================================================
void ScriptError(script_t *script, char *str, ...)
{
	char text[1024];
	va_list ap;

	va_start(ap, str);
	vsprintf(text, str, ap);
	va_end(ap);
	printf("error: file %s, line %d: %s\n", script->filename, script->line, text);
} //end of the function ScriptError
//===========================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//===========================================================================
void ScriptWarning(script_t *script, char *str, ...)
{
	char text[1024];
	va_list ap;

	va_start(ap, str);
	vsprintf(text, str, ap);
	va_end(ap);
	printf("warning: file %s, line %d: %s\n", script->filename, script->line, text);
} //end of the function ScriptWarning


void SetScriptPunctuations (script_t *script)
{
	PS_CreatePunctuationTable (script, default_punctuations);
}


//============================================================================
// Reads spaces, tabs, C-like comments etc.
// When a newline character is found the scripts line counter is increased.
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PS_ReadWhiteSpace(script_t *script)
{
	while(1)
	{
		//skip white space
		while(*script->script_p <= ' ')
		{
			if (!*script->script_p) return 0;
			if (*script->script_p == '\n') script->line++;
			script->script_p++;
		} //end while
		//skip comments
		if (*script->script_p == '/')
		{
			//comments //
			if (*(script->script_p+1) == '/')
			{
				script->script_p++;
				do
				{
					script->script_p++;
					if (!*script->script_p) return 0;
				} //end do
				while(*script->script_p != '\n');
				script->line++;
				script->script_p++;
				if (!*script->script_p) return 0;
				continue;
			} //end if
			//comments /* */
			else if (*(script->script_p+1) == '*')
			{
				script->script_p++;
				do
				{
					script->script_p++;
					if (!*script->script_p) return 0;
					if (*script->script_p == '\n') script->line++;
				} //end do
				while(!(*script->script_p == '*' && *(script->script_p+1) == '/'));
				script->script_p++;
				if (!*script->script_p) return 0;
				script->script_p++;
				if (!*script->script_p) return 0;
				continue;
			} //end if
		} //end if
		break;
	} //end while
	return 1;
} //end of the function PS_ReadWhiteSpace
//============================================================================
// Reads an escape character.
//
// Parameter:				script		: script to read from
//								ch				: place to store the read escape character
// Returns:					-
// Changes Globals:		-
//============================================================================
int PS_ReadEscapeCharacter(script_t *script, char *ch)
{
	int c, val, i;

	//step over the leading '\\'
	script->script_p++;
	//determine the escape character
	switch(*script->script_p)
	{
		case '\\': c = '\\'; break;
		case 'n': c = '\n'; break;
		case 'r': c = '\r'; break;
		case 't': c = '\t'; break;
		case 'v': c = '\v'; break;
		case 'b': c = '\b'; break;
		case 'f': c = '\f'; break;
		case 'a': c = '\a'; break;
		case '\'': c = '\''; break;
		case '\"': c = '\"'; break;
		case '\?': c = '\?'; break;
		case 'x':
		{
			script->script_p++;
			for (i = 0, val = 0; ; i++, script->script_p++)
			{
				c = *script->script_p;
				if (c >= '0' && c <= '9') c = c - '0';
				else if (c >= 'A' && c <= 'Z') c = c - 'A' + 10;
				else if (c >= 'a' && c <= 'z') c = c - 'a' + 10;
				else break;
				val = (val << 4) + c;
			} //end for
			script->script_p--;
			if (val > 0xFF)
			{
				ScriptWarning(script, "too large value in escape character");
				val = 0xFF;
			} //end if
			c = val;
			break;
		} //end case
		default: //NOTE: decimal ASCII code, NOT octal
		{
			if (*script->script_p < '0' || *script->script_p > '9') ScriptError(script, "unknown escape char");
			for (i = 0, val = 0; ; i++, script->script_p++)
			{
				c = *script->script_p;
				if (c >= '0' && c <= '9') c = c - '0';
				else break;
				val = val * 10 + c;
			} //end for
			script->script_p--;
			if (val > 0xFF)
			{
				ScriptWarning(script, "too large value in escape character");
				val = 0xFF;
			} //end if
			c = val;
			break;
		} //end default
	} //end switch
	//step over the escape character or the last digit of the number
	script->script_p++;
	//store the escape character
	*ch = c;
	//succesfully read escape character
	return 1;
} //end of the function PS_ReadEscapeCharacter
//============================================================================
// Reads C-like string. Escape characters are interpretted.
// Quotes are included with the string.
// Reads two strings with a white space between them as one string.
//
// Parameter:				script		: script to read from
//								token			: buffer to store the string
// Returns:					true when a string was read succesfully
// Changes Globals:		-
//============================================================================
int PS_ReadString(script_t *script, token_t *token, int quote)
{
	int len, tmpline;
	char *tmpscript_p;

	if (quote == '\"') token->type = TT_STRING;
	else token->type = TT_LITERAL;

	len = 0;
	//leading quote
	token->string[len++] = *script->script_p++;
	//
	while(1)
	{
		//minus 2 because trailing double quote and zero have to be appended
		if (len >= MAX_TOKEN - 2)
		{
			ScriptError(script, "string longer than MAX_TOKEN = %d", MAX_TOKEN);
			return 0;
		} //end if
		//if there is an escape character
		if (*script->script_p == '\\')
		{
			if (!PS_ReadEscapeCharacter(script, &token->string[len]))
			{
				token->string[len] = 0;
				return 0;
			} //end if
			len++;
		} //end if
		//if a trailing quote
		else if (*script->script_p == quote)
		{
			//step over the double quote
			script->script_p++;

			tmpscript_p = script->script_p;
			tmpline = script->line;
			//read unusefull stuff between possible two following strings
			if (!PS_ReadWhiteSpace(script))
			{
				script->script_p = tmpscript_p;
				script->line = tmpline;
				break;
			} //end if
			//if there's no leading double qoute
			if (*script->script_p != quote)
			{
				script->script_p = tmpscript_p;
				script->line = tmpline;
				break;
			} //end if
			//step over the new leading double quote
			script->script_p++;
		} //end if
		else
		{
			if (*script->script_p == '\0')
			{
				token->string[len] = 0;
				ScriptError(script, "missing trailing quote");
				return 0;
			} //end if
			if (*script->script_p == '\n')
			{
				token->string[len] = 0;
				ScriptError(script, "newline inside string %s", token->string);
				return 0;
			} //end if
			token->string[len++] = *script->script_p++;
		} //end else
	} //end while
	//trailing quote
	token->string[len++] = quote;
	//end string with a zero
	token->string[len] = '\0';
	//the sub type is the length of the string
	token->subtype = len;
	return 1;
} //end of the function PS_ReadString
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PS_ReadName(script_t *script, token_t *token)
{
	int len = 0;
	char c;

	token->type = TT_NAME;
	do
	{
		token->string[len++] = *script->script_p++;
		if (len >= MAX_TOKEN)
		{
			ScriptError(script, "name longer than MAX_TOKEN = %d", MAX_TOKEN);
			return 0;
		} //end if
		c = *script->script_p;
   } while ((c >= 'a' && c <= 'z') ||
				(c >= 'A' && c <= 'Z') ||
				(c >= '0' && c <= '9') ||
				c == '_');
	token->string[len] = '\0';
	//the sub type is the length of the name
	token->subtype = len;
	return 1;
} //end of the function PS_ReadName
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
void NumberValue(char *string, int subtype, unsigned long int *intvalue,
															double *floatvalue)
{
	unsigned long int dotfound = 0;

	*intvalue = 0;
	*floatvalue = 0;
	//floating point number
	if (subtype & TT_FLOAT)
	{
		while(*string)
		{
			if (*string == '.')
			{
				if (dotfound) return;
				dotfound = 10;
				string++;
			} //end if
			if (dotfound)
			{
				*floatvalue = *floatvalue + (double) (*string - '0') /
																	(double) dotfound;
				dotfound *= 10;
			} //end if
			else
			{
				*floatvalue = *floatvalue * 10.0 + (double) (*string - '0');
			} //end else
			string++;
		} //end while
		*intvalue = (unsigned long) *floatvalue;
	} //end if
	else if (subtype & TT_DECIMAL)
	{
		while(*string) *intvalue = *intvalue * 10 + (*string++ - '0');
		*floatvalue = *intvalue;
	} //end else if
	else if (subtype & TT_HEX)
	{
		//step over the leading 0x or 0X
		string += 2;
		while(*string)
		{
			*intvalue <<= 4;
			if (*string >= 'a' && *string <= 'f') *intvalue += *string - 'a' + 10;
			else if (*string >= 'A' && *string <= 'F') *intvalue += *string - 'A' + 10;
			else *intvalue += *string - '0';
			string++;
		} //end while
		*floatvalue = *intvalue;
	} //end else if
	else if (subtype & TT_OCTAL)
	{
		//step over the first zero
		string += 1;
		while(*string) *intvalue = (*intvalue << 3) + (*string++ - '0');
		*floatvalue = *intvalue;
	} //end else if
	else if (subtype & TT_BINARY)
	{
		//step over the leading 0b or 0B
		string += 2;
		while(*string) *intvalue = (*intvalue << 1) + (*string++ - '0');
		*floatvalue = *intvalue;
	} //end else if
} //end of the function NumberValue
//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
int PS_ReadNumber(script_t *script, token_t *token)
{
	int len = 0, i;
	int octal, dot;
	char c;
//	unsigned long int intvalue = 0;
//	double floatvalue = 0;

	token->type = TT_NUMBER;
	//check for a hexadecimal number
	if (*script->script_p == '0' &&
		(*(script->script_p + 1) == 'x' ||
		*(script->script_p + 1) == 'X'))
	{
		token->string[len++] = *script->script_p++;
		token->string[len++] = *script->script_p++;
		c = *script->script_p;
		//hexadecimal
		while((c >= '0' && c <= '9') ||
					(c >= 'a' && c <= 'f') ||
					(c >= 'A' && c <= 'A'))
		{
			token->string[len++] = *script->script_p++;
			if (len >= MAX_TOKEN)
			{
				ScriptError(script, "hexadecimal number longer than MAX_TOKEN = %d", MAX_TOKEN);
				return 0;
			} //end if
			c = *script->script_p;
		} //end while
		token->subtype |= TT_HEX;
	} //end if
	//check for a binary number
	else if (*script->script_p == '0' &&
		(*(script->script_p + 1) == 'b' ||
		*(script->script_p + 1) == 'B'))
	{
		token->string[len++] = *script->script_p++;
		token->string[len++] = *script->script_p++;
		c = *script->script_p;
		//binary
		while(c == '0' || c == '1')
		{
			token->string[len++] = *script->script_p++;
			if (len >= MAX_TOKEN)
			{
				ScriptError(script, "binary number longer than MAX_TOKEN = %d", MAX_TOKEN);
				return 0;
			} //end if
			c = *script->script_p;
		} //end while
		token->subtype |= TT_BINARY;
	} //end if
	else //decimal or octal integer or floating point number
	{
		octal = false;
		dot = false;
		if (*script->script_p == '0') octal = true;
		while(1)
		{
			token->string[len++] = *script->script_p++;
			if (len >= MAX_TOKEN)
			{
				ScriptError(script, "number longer than MAX_TOKEN = %d", MAX_TOKEN);
				return 0;
			} //end if
			c = *script->script_p;
			if (c == '.') dot = true;
			else if (c == '8' || c == '9') octal = false;
			else if (c < '0' || c > '9') break;
	   } //end while
		if (octal) token->subtype |= TT_OCTAL;
		else token->subtype |= TT_DECIMAL;
		if (dot) token->subtype |= TT_FLOAT;
	} //end else
	for (i = 0; i < 2; i++)
	{
		c = *script->script_p;
		//check for a LONG number
		if ((c == 'l' || c == 'L') && !(token->subtype & TT_LONG))
		{
			script->script_p++;
			token->subtype |= TT_LONG;
		} //end if
		//check for an UNSIGNED number
		else if ((c == 'u' || c == 'U') && !(token->subtype & (TT_UNSIGNED | TT_FLOAT)))
		{
			script->script_p++;
			token->subtype |= TT_UNSIGNED;
		} //end if
	} //end for
	token->string[len] = '\0';

	NumberValue(token->string, token->subtype, &token->intvalue, &token->floatvalue);

	if (!(token->subtype & TT_FLOAT)) token->subtype |= TT_INTEGER;
	return 1;
} //end of the function PS_ReadNumber


int PS_ReadPunctuation(script_t *script, token_t *token)
{
	int len;
	char *p;
	punctuation_t *punc;

	for (punc = script->punctuationtable[(unsigned int)*script->script_p]; punc; punc = punc->next)
	{
		p = punc->p;
		len = strlen(p);
		//if the script contains at least as much characters as the punctuation
		if (script->script_p + len <= script->end_p)
		{
			//if the script contains the punctuation
			if (!strncmp(script->script_p, p, len))
			{
				strncpy(token->string, p, MAX_TOKEN);
				script->script_p += len;
				token->type = TT_PUNCTUATION;
				//sub type is the number of the punctuation
				token->subtype = punc->n;
				return 1;
			} //end if
		} //end if
	} //end for
	return 0;
} //end of the function PS_ReadPunctuation


int PS_ReadToken(script_t *script, token_t *token)
{
	//if there is a token available (from UnreadToken)
	if (script->tokenavailable)
	{
		script->tokenavailable = 0;
		memcpy(token, &script->token, sizeof(token_t));
		return 1;
	} //end if
	//save script pointer
	script->lastscript_p = script->script_p;
	//save line counter
	script->lastline = script->line;
	//clear the token stuff
	memset(token, 0, sizeof(token_t));
	//start of the white space
	script->whitespace_p = script->script_p;
	token->whitespace_p = script->script_p;
	//read unusefull stuff
	if (!PS_ReadWhiteSpace(script)) return 0;
	//end of the white space
	script->endwhitespace_p = script->script_p;
	token->endwhitespace_p = script->script_p;
	//line the token is on
	token->line = script->line;
	//number of lines crossed before token
	token->linescrossed = script->line - script->lastline;
	//if there is a leading double quote
	if (*script->script_p == '\"')
	{
		if (!PS_ReadString(script, token, '\"')) return 0;
	} //end if
	//if an literal
	else if (*script->script_p == '\'')
	{
		if (!PS_ReadString(script, token, '\'')) return 0;
	} //end if
	//if there is a number
	else if ((*script->script_p >= '0' && *script->script_p <= '9') ||
				(*script->script_p == '.' &&
				(*(script->script_p + 1) >= '0' && *(script->script_p + 1) <= '9')))
	{
		if (!PS_ReadNumber(script, token)) return 0;
	} //end if
	//if there is a name
	else if ((*script->script_p >= 'a' && *script->script_p <= 'z') ||
		(*script->script_p >= 'A' && *script->script_p <= 'Z') ||
		*script->script_p == '_')
	{
		if (!PS_ReadName(script, token)) return 0;
	} //end if
	//check for punctuations
	else if (!PS_ReadPunctuation(script, token))
	{
		ScriptError(script, "can't read token");
		return 0;
	} //end if
	//copy the token into the script structure
	memcpy(&script->token, token, sizeof(token_t));
	//succesfully read a token
	return 1;
} //end of the function PS_ReadToken


//============================================================================
//
// Parameter:				-
// Returns:					-
// Changes Globals:		-
//============================================================================
void StripDoubleQuotes(char *string)
{
	if (*string == '\"')
	{
		strcpy(string, string+1);
	} //end if
	if (string[strlen(string)-1] == '\"')
	{
		string[strlen(string)-1] = '\0';
	} //end if
} //end of the function StripDoubleQuotes


//============================================================================
// returns true if at the end of the script
//============================================================================
int EndOfScript (script_t *script)
{
	return script->script_p >= script->end_p;
}


script_t *LoadScript (size_t length, const char *name)
{
	script_t* script;

	script = GetMemory (sizeof (script_t) + length + 1);
	memset (script, 0, sizeof (script_t));

	strncpy (script->filename, name, sizeof (script->filename) - 1);
	script->buffer = (char*)script + sizeof (script_t);
	script->buffer[length] = 0;
	script->length = length;

	script->script_p = script->buffer;
	script->lastscript_p = script->buffer;
	script->end_p = &script->buffer[length];

	script->line = 1;
	script->lastline = 1;

	SetScriptPunctuations (script);

	return script;
}


script_t *LoadScriptFile (const char *filename)
{
	FILE *fp;
	size_t length;
	script_t *script;

	fp = fopen(filename, "rb");
	if (!fp)
		return NULL;

	length = FileLength (fp);
	script = LoadScript (length, filename);
	if (fread (script->buffer, 1, length, fp) != length)
	{
		FreeMemory (script);
		script = NULL;
	}
	fclose (fp);

	return script;
}


//============================================================================
//load a script from the given memory with the given length
//============================================================================
script_t *LoadScriptMemory (const char *ptr, size_t length, const char *name)
{
	script_t *script;

	script = LoadScript (length, name);
	memcpy (script->buffer, ptr, length);

	return script;
}


void FreeScript(script_t *script)
{
	if (script->punctuationtable)
		FreeMemory (script->punctuationtable);

	FreeMemory(script);
}
