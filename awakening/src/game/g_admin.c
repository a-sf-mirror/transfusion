/*
Copyright (C) 1997-2001 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#include "g_local.h"

// Election
typedef enum
{
	ELECT_NONE,
	ELECT_ADMIN,
	ELECT_MAP
} elect_t;

typedef struct
{
	// Common to all elections
	elect_t		type;			// election type
	int			votes;			// votes so far
	int			needvotes;		// votes needed
	float		time;			// remaining time until election times out
	char		msg[256];		// election name

	// Specific to each election
	edict_t		*target;		// for admin election, who's being elected
	char		level[32];		// for map election, target level
} election_t;

election_t	election;


void Admin_CheckElection(void)
{
	if (election.type != ELECT_NONE && election.time <= level.time)
	{
		gi.bprintf(PRINT_CHAT, "Election timed out and has been cancelled.\n");
		election.type = ELECT_NONE;
	}
}

void Admin_WinElection(void)
{
	switch (election.type)
	{
		case ELECT_ADMIN :
			election.target->client->resp.admin = true;
			gi.bprintf(PRINT_HIGH, "%s has become an admin.\n", election.target->client->pers.netname);
			gi.cprintf(election.target, PRINT_HIGH, "Type 'admin' to access the adminstration menu.\n");
			break;

		case ELECT_MAP :
			gi.bprintf(PRINT_HIGH, "%s is warping to level %s.\n",
				election.target->client->pers.netname, election.level);
			strncpy(level.forcemap, election.level, sizeof(level.forcemap) - 1);
			EndDMLevel();
			break;
		default:
			break;
	}
	election.type = ELECT_NONE;
}

qboolean Admin_BeginElection(edict_t *ent, elect_t type, char *msg)
{
	int i;
	int count;
	edict_t *e;

	if (electpercentage->value == 0) {
		gi.cprintf(ent, PRINT_HIGH, "Elections are disabled, only an admin can process this action.\n");
		return false;
	}


	if (election.type != ELECT_NONE) {
		gi.cprintf(ent, PRINT_HIGH, "Election already in progress.\n");
		return false;
	}

	// clear votes
	count = 0;
	for (i = 1; i <= maxclients->value; i++) {
		e = g_edicts + i;
		e->client->resp.voted = false;
		if (e->inuse)
			count++;
	}

	if (count < 2) {
		gi.cprintf(ent, PRINT_HIGH, "Not enough players for election.\n");
		return false;
	}

	election.target = ent;
	election.type = type;
	election.votes = 0;
	election.needvotes = (count * electpercentage->value) / 100;
	election.time = level.time + 20; // twenty seconds for election
	strncpy(election.msg, msg, sizeof(election.msg) - 1);

	// tell everyone
	gi.bprintf(PRINT_CHAT, "%s\n", election.msg);
	gi.bprintf(PRINT_HIGH, "Type YES or NO to vote on this request.\n");
	gi.bprintf(PRINT_HIGH, "Votes: %d  Needed: %d  Time left: %ds\n", election.votes, election.needvotes,
		(int)(election.time - level.time));

	return true;
}

void Admin_VoteYes(edict_t *ent)
{
	if (election.type == ELECT_NONE)
	{
		gi.cprintf(ent, PRINT_HIGH, "No election is in progress.\n");
		return;
	}
	if (ent->client->resp.voted)
	{
		gi.cprintf(ent, PRINT_HIGH, "You already voted.\n");
		return;
	}
	if (election.target == ent)
	{
		gi.cprintf(ent, PRINT_HIGH, "You can't vote for yourself.\n");
		return;
	}

	ent->client->resp.voted = true;

	election.votes++;
	if (election.votes == election.needvotes)
	{
		// the election has been won
		Admin_WinElection();
		return;
	}
	gi.bprintf(PRINT_HIGH, "%s\n", election.msg);
	gi.bprintf(PRINT_CHAT, "Votes: %d  Needed: %d  Time left: %ds\n", election.votes, election.needvotes,
		(int)(election.time - level.time));
}

void Admin_VoteNo(edict_t *ent)
{
	if (election.type == ELECT_NONE)
	{
		gi.cprintf(ent, PRINT_HIGH, "No election is in progress.\n");
		return;
	}
	if (ent->client->resp.voted)
	{
		gi.cprintf(ent, PRINT_HIGH, "You already voted.\n");
		return;
	}
	if (election.target == ent)
	{
		gi.cprintf(ent, PRINT_HIGH, "You can't vote for yourself.\n");
		return;
	}

	ent->client->resp.voted = true;

	gi.bprintf(PRINT_HIGH, "%s\n", election.msg);
	gi.bprintf(PRINT_CHAT, "Votes: %d  Needed: %d  Time left: %ds\n", election.votes, election.needvotes,
		(int)(election.time - level.time));
}


void Admin_Warp(edict_t *ent)
{
	char text[1024];
	char *mlist, *token;
	static const char *seps = " \t\n\r";

	if (gi.argc() < 2)
	{
		gi.cprintf(ent, PRINT_HIGH, "Where do you want to warp to?\n");
		gi.cprintf(ent, PRINT_HIGH, "Available levels are: %s\n", sv_maplist->string);
		return;
	}

	mlist = strdup(sv_maplist->string);

	token = strtok(mlist, seps);
	while (token != NULL)
	{
		if (Q_strcasecmp(token, gi.argv(1)) == 0)
			break;
		token = strtok(NULL, seps);
	}

	if (token == NULL)
	{
		gi.cprintf(ent, PRINT_HIGH, "Unknown level.\n");
		gi.cprintf(ent, PRINT_HIGH, "Available levels are: %s\n", sv_maplist->string);
		free(mlist);
		return;
	}

	free(mlist);


	if (ent->client->resp.admin)
	{
		gi.bprintf(PRINT_HIGH, "%s is warping to level %s.\n",
			ent->client->pers.netname, gi.argv(1));
		strncpy(level.forcemap, gi.argv(1), sizeof(level.forcemap) - 1);
		EndDMLevel();
		return;
	}

	sprintf(text, "%s has requested warping to level %s.",
			ent->client->pers.netname, gi.argv(1));
	if (Admin_BeginElection(ent, ELECT_MAP, text))
		strncpy(election.level, gi.argv(1), sizeof(election.level) - 1);
}

void Admin_Boot(edict_t *ent)
{
	int i;
	edict_t *targ;
	char text[80];

	if (!ent->client->resp.admin)
	{
		gi.cprintf(ent, PRINT_HIGH, "You are not an admin.\n");
		return;
	}

	if (gi.argc() < 2)
	{
		gi.cprintf(ent, PRINT_HIGH, "Who do you want to kick?\n");
		return;
	}

	if (*gi.argv(1) < '0' && *gi.argv(1) > '9')
	{
		gi.cprintf(ent, PRINT_HIGH, "Specify the player number to kick.\n");
		return;
	}

	i = atoi(gi.argv(1));
	if (i < 1 || i > maxclients->value)
	{
		gi.cprintf(ent, PRINT_HIGH, "Invalid player number.\n");
		return;
	}

	targ = g_edicts + i;
	if (!targ->inuse)
	{
		gi.cprintf(ent, PRINT_HIGH, "That player number is not connected.\n");
		return;
	}

	sprintf(text, "kick %d\n", i - 1);
	gi.AddCommandString(text);
}

/*----------------------------------------------------------------------------------*/
/* MENU */

typedef struct admin_settings_s
{
	qboolean weaponsstay;
} admin_settings_t;

#define SETMENU_SIZE (7 + 5)

void AdminMenu_UpdateSettings (edict_t *ent, pmenuhnd_t *setmenu);
void AdminMenu_Open (edict_t *ent);

void AdminMenu_SettingsApply(edict_t *ent, pmenuhnd_t *p)
{
	admin_settings_t *settings = p->arg;
	char st[80];
	int i;

	if (settings->weaponsstay != (((int)dmflags->value & DF_WEAPONS_STAY) == DF_WEAPONS_STAY))
	{
		gi.bprintf(PRINT_HIGH, "%s turned %s weapons stay.\n",
			ent->client->pers.netname, settings->weaponsstay ? "on" : "off");
		i = (int)dmflags->value;
		if (settings->weaponsstay)
			i |= DF_WEAPONS_STAY;
		else
			i &= ~DF_WEAPONS_STAY;
		sprintf (st, "%d", i);
		gi.cvar_set ("dmflags", st);
	}

	PMenu_Close (ent);
	AdminMenu_Open (ent);
}

void AdminMenu_SettingsCancel(edict_t *ent, pmenuhnd_t *p)
{
	PMenu_Close (ent);
	AdminMenu_Open (ent);
}

void AdminMenu_ChangeWeapStay(edict_t *ent, pmenuhnd_t *p)
{
	admin_settings_t *settings = p->arg;

	settings->weaponsstay = !settings->weaponsstay;
	AdminMenu_UpdateSettings (ent, p);
}

void AdminMenu_UpdateSettings(edict_t *ent, pmenuhnd_t *setmenu)
{
	int i = 2;
	char text[64];
	admin_settings_t *settings = setmenu->arg;

	sprintf(text, "Weapons Stay:    %s", settings->weaponsstay ? "Yes" : "No");
	PMenu_UpdateEntry(setmenu->entries + i, text, PMENU_ALIGN_LEFT, AdminMenu_ChangeWeapStay);
	i++;

	PMenu_Update(ent);
}

pmenu_t def_setmenu[] = {
	{ "*Settings Menu", PMENU_ALIGN_CENTER, NULL },
	{ NULL,				PMENU_ALIGN_CENTER, NULL },
	{ NULL,				PMENU_ALIGN_LEFT, NULL },	// qboolean weaponsstay;
	{ NULL,				PMENU_ALIGN_LEFT, NULL },
	{ "Apply",			PMENU_ALIGN_LEFT, AdminMenu_SettingsApply },
	{ "Cancel",			PMENU_ALIGN_LEFT, AdminMenu_SettingsCancel }
};

void AdminMenu_Settings(edict_t *ent, pmenuhnd_t *p)
{
	admin_settings_t *settings;
	pmenuhnd_t *menu;

	PMenu_Close(ent);

	settings = malloc(sizeof(*settings));

	settings->weaponsstay = !!((int)dmflags->value & DF_WEAPONS_STAY);

	menu = PMenu_Open(ent, def_setmenu, -1, sizeof(def_setmenu) / sizeof(pmenu_t), settings);
	AdminMenu_UpdateSettings(ent, menu);
}

void AdminMenu_Cancel(edict_t *ent, pmenuhnd_t *p)
{
	PMenu_Close(ent);
}


pmenu_t adminmenu[] = {
	{ "*Administration Menu",	PMENU_ALIGN_CENTER, NULL },
	{ NULL,						PMENU_ALIGN_CENTER, NULL }, // blank
	{ "Settings",				PMENU_ALIGN_LEFT, AdminMenu_Settings },
	{ NULL,						PMENU_ALIGN_LEFT, NULL },
	{ NULL,						PMENU_ALIGN_LEFT, NULL },
	{ "Cancel",					PMENU_ALIGN_LEFT, AdminMenu_Cancel },
	{ NULL,						PMENU_ALIGN_CENTER, NULL },
};

void AdminMenu_Open (edict_t *ent)
{
	adminmenu[3].text = NULL;
	adminmenu[3].SelectFunc = NULL;
	adminmenu[4].text = NULL;
	adminmenu[4].SelectFunc = NULL;

	// NOTE (Elric): there were some match / competition stuff on rows 3 & 4 previously

//	if (ent->client->menu)
//		PMenu_Close(ent->client->menu);

	PMenu_Open (ent, adminmenu, -1, sizeof(adminmenu) / sizeof(pmenu_t), NULL);
}

void Admin_Elect (edict_t *ent)
{
	char text[1024];

	if (!admin_password->string || !*admin_password->string)
	{
		gi.cprintf(ent, PRINT_HIGH, "Administration is disabled\n");
		return;
	}

	if (gi.argc() > 1 &&
		!ent->client->resp.admin && strcmp(admin_password->string, gi.argv(1)) == 0)
	{
		ent->client->resp.admin = true;
		gi.bprintf(PRINT_HIGH, "%s has become an admin.\n", ent->client->pers.netname);
		gi.cprintf(ent, PRINT_HIGH, "Type 'admin' to access the adminstration menu.\n");
	}

	if (!ent->client->resp.admin)
	{
		sprintf (text, "%s has requested admin rights.", ent->client->pers.netname);
		Admin_BeginElection (ent, ELECT_ADMIN, text);
		return;
	}

	if (ent->client->menu)
		PMenu_Close(ent);

	AdminMenu_Open(ent);
}
