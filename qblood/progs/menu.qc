/*  Copyright (C) 2001-2002  Mathieu Olivier

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
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    See file, 'COPYING', for details.
*/

#include "common.qh"

void(float forcemap) Cl_ChangeLevel;
string(float gtNumber) Vote_GametypeToString;


/*
====================
Vote_ChangeMap

Used when the vote for a map is passed
====================
*/
void(string newmap) Vote_ChangeMap =
{
    nextmap = newmap;
    Cl_ChangeLevel (TRUE);

    Bprint (PRINT_HIGH, "Û Vote passed. Switching to map ");  // "[ Vote passed ..."
    Bprint (PRINT_HIGH, newmap);
    Bprint (PRINT_HIGH, " Ý\n");  // " ]\n"
};


/*
====================
Vote_ChangeFraglimit

Used when the vote for a frag limit is passed
====================
*/
void(string newFraglimit) Vote_ChangeFraglimit =
{
    Bprint (PRINT_HIGH, "Û Vote passed. New frag limit: ");  // "[ Vote passed ..."
    Bprint (PRINT_HIGH, newFraglimit);
    Bprint (PRINT_HIGH, " Ý\n");  // " ]\n"

    if (newFraglimit == "unlimited")
        cvar_set ("fraglimit", "0");
    else
        cvar_set ("fraglimit", newFraglimit);
};


/*
====================
Vote_ChangeGametype

Used when the vote for a gametype is passed
====================
*/
void(float newGametype) Vote_ChangeGametype =
{
    local string gt;

    // If it's a CTF game
    if (newGametype >= 4)
        cvar_set ("deathmatch", "2");
    else
        cvar_set ("deathmatch", "1");

    // If it's a Blood Bath
    if (newGametype == 1)
        cvar_set ("teamplay", "0");
    // Else, if the friendly fire must be activated
    else if (newGametype == 3 || newGametype == 5)
        cvar_set ("teamplay", "2");
    else
        cvar_set ("teamplay", "1");

    Bprint (PRINT_HIGH, "Û Vote passed. Next game type: ");  // "[ Vote passed ..."
    gt = Vote_GametypeToString (newGametype);
    Bprint (PRINT_HIGH, gt);
    Bprint (PRINT_HIGH, " Ý\n");  // " ]\n"
};


/*
====================
Vote_ChangeTimelimit

Used when the vote for a time limit is passed
====================
*/
void(string newTimelimit) Vote_ChangeTimelimit =
{
    Bprint (PRINT_HIGH, "Û Vote passed. New time limit: ");  // "[ Vote passed ..."
    Bprint (PRINT_HIGH, newTimelimit);
    Bprint (PRINT_HIGH, " Ý\n");  // " ]\n"

    if (newTimelimit == "unlimited")
        cvar_set ("timelimit", "0");
    else
        cvar_set ("timelimit", newTimelimit);
};


/*
====================
Vote_ChangeWarmup

Used when the vote for a warmup duration is passed
====================
*/
void(string newDuration) Vote_ChangeWarmup =
{
    Bprint (PRINT_HIGH, "Û Vote passed. New warmup duration: ");  // "[ Vote passed ..."
    Bprint (PRINT_HIGH, newDuration);
    Bprint (PRINT_HIGH, " secondes Ý\n");  // " secondes ]\n"

    cvar_set ("g_warmup", newDuration);

    // Test if the engine support creation of new cvars by progs
    if (newDuration != "0")
        if (cvar ("g_warmup") == 0)
            Bprint (PRINT_HIGH, "×ÁÒÎÉÎÇº the engine doesn't support dynamic cvar creation. Can't change warmup duration\n");  // "WARNING ..."
};


/*
====================
Vote_ChangeOption

Used when the vote for toggling an option is passed
====================
*/
void(string cvarName) Vote_ChangeOption =
{
    local string newValue;

    newValue = ftos (! cvar (cvarName));
    Bprint (PRINT_HIGH, "Û Vote passed. New option: \"");  // "[ Vote passed ..."
    Bprint (PRINT_HIGH, cvarName);
    Bprint (PRINT_HIGH, "\" = ");
    Bprint (PRINT_HIGH, newValue);
    Bprint (PRINT_HIGH, " Ý\n");  // " ]\n"

    cvar_set (cvarName, newValue);

    // Test if the engine support creation of new cvars by progs
    if (newValue == "1")
        if (cvar (cvarName) != 1)
            Bprint (PRINT_HIGH, "×ÁÒÎÉÎÇº the engine doesn't support dynamic cvar creation. Can't change option\n");  // "WARNING ..."
};


/*
====================
Vote_GametypeToString

Give the string describing the game type
====================
*/
string(float gtNumber) Vote_GametypeToString =
{
    if (gtNumber == 1)
        return "Âlood Âath";
    if (gtNumber == 2)
        return "Ôeam Âlood Âath";
    if (gtNumber == 3)
        return "Ôeam Âlood Âath with friendly fire";
    if (gtNumber == 4)
        return "Ãapture Ôhe Ælag";
    if (gtNumber == 5)
        return "Ãapture Ôhe Ælag with friendly fire";

    return "Invalid game type";
};


/*
====================
Vote_IsPassed

Check if a vote is passed
====================
*/
float(.float vote_field, float bitmask, float value) Vote_IsPassed =
{
    local entity player;
    local float VoteTotal;
    local float VoteCount;

    VoteCount = 0;
    VoteTotal = 0;

    player = nextent (world);
    while (player != world)
    {
        // If it's a (real) player
        #ifndef NO_FRIKBOT
        if (player.ishuman == TRUE && player.b_clientno != -1)
        #else
        if (player.classname == "player")
        #endif
        {
            VoteTotal = VoteTotal + 1;
            if ((player.vote_field & bitmask) == value)
                VoteCount = VoteCount + 1;
        }

        player = nextent (player);
    }

    // more than 50% is requiered to pass a vote
    VoteCount = ceil ((VoteTotal + 1) / 2) - VoteCount;
    if (VoteCount > 0)
    {
        local string tmpString;

        Bprint (PRINT_HIGH, "Û ");  // "[ "
        tmpString = ftos (VoteCount);
        Bprint (PRINT_HIGH, tmpString);
        Bprint (PRINT_HIGH, " votes missing Ý\n");  // " ]\n"

        return FALSE;
    }

    return TRUE;
};


/*
====================
Vote_AddMapVote

Add one vote to the map
====================
*/
void(float vote, string newmap) Vote_AddMapVote =
{
    self.vote_map = vote;
    Bprint (PRINT_HIGH, "Û ");  // "[ "
    Bprint (PRINT_HIGH, self.netname);
    Bprint (PRINT_HIGH, " votes for map ");
    Bprint (PRINT_HIGH, newmap);
    Bprint (PRINT_HIGH, " Ý\n");  // " ]\n"

    // If the vote is passed
    if (Vote_IsPassed (vote_map, 255, vote))
        Vote_ChangeMap (newmap);
};


//=========================================================================

// The menus
#define MENU_MAIN           0
#define MENU_VOTE_MAP       1
#define MENU_VOTE_GAMETYPE  2
#define MENU_VOTE_FRAGLIMIT 3
#define MENU_VOTE_TIMELIMIT 4
#define MENU_VOTE_WARMUP    5
#define MENU_VOTE_OPTIONS   6

#define MENU_VOTE_MAP_BLOOD         10
#define MENU_VOTE_MAP_BLOOD_SP      11
#define MENU_VOTE_MAP_BLOODPACKS    12  // Plasma Pack + Cryptic Passage
#define MENU_VOTE_MAP_BLOOD2        13
#define MENU_VOTE_MAP_TRANSFUSION   14
#define MENU_VOTE_MAP_CONVERSIONS   15

// The groups of maps
#define MAPS_BLOOD          0
#define MAPS_BLOOD_SP       10
#define MAPS_BLOODPACKS     40  // Plasma Pack + Cryptic Passage
#define MAPS_BLOOD2         60
#define MAPS_TRANSFUSION    80
#define MAPS_CONVERSIONS    100

// Options
// All values must be powers of 2
#define OPTION_WEAPONS_STAY    1
#define OPTION_LOCK_TEAMS      2
#define OPTION_FLASHY_EFFECTS  4


/*
====================
Menu_Draw

Draw the current view of a client's menu
====================
*/
void() Menu_Draw =
{
    if (self.menu_index == MENU_MAIN)
    {
        Sprint (self, PRINT_HIGH,
                "1) Vote for a map\n"
                "2) Vote for a game type\n"
                "3) Vote for the frag limit\n"
                "4) Vote for the time limit\n"
                "5) Vote for the warmup duration\n"
                "6) Vote for an option\n"
                "\n"
                "10) Exit menu\n");
    }
    else if (self.menu_index == MENU_VOTE_MAP)
    {
        Sprint (self, PRINT_HIGH,
                "Choose a map group:\n"
                "1) Blood maps\n"
                "2) Blood Single Player maps\n"
                "3) Blood Add-ons maps\n"
                "4) Blood 2 maps\n"
                "5) Transfusion maps\n"
                "6) Converted maps\n"
                "\n"
                "10) Go back to main menu\n");
    }
    else if (self.menu_index == MENU_VOTE_GAMETYPE)
    {
        Sprint (self, PRINT_HIGH,
                "Vote for a game type:\n"
                "1) BloodBath\n"
                "2) Team BloodBath\n"
                "3) Team BloodBath with friendly fire\n"
                "4) Capture The Flag\n"
                "5) Capture The Flag with friendly fire\n"
                "\n"
                "10) Go back to main menu\n");
    }
    else if (self.menu_index == MENU_VOTE_FRAGLIMIT)
    {
        Sprint (self, PRINT_HIGH,
                "Vote for the frag limit:\n"
                "1) 10\n"
                "2) 20\n"
                "3) 30\n"
                "4) 50\n"
                "5) 75\n"
                "6) 100\n"
                "7) 150\n"
                "8) 200\n"
                "9) Unlimited\n"
                "\n"
                "10) Go back to main menu\n");
    }
    else if (self.menu_index == MENU_VOTE_TIMELIMIT)
    {
        Sprint (self, PRINT_HIGH,
                "Vote for the time limit:\n"
                "1) 5 minutes\n"
                "2) 10 minutes\n"
                "3) 15 minutes\n"
                "4) 20 minutes\n"
                "5) 25 minutes\n"
                "6) 30 minutes\n"
                "7) 40 minutes\n"
                "8) 60 minutes\n"
                "9) Unlimited\n"
                "\n"
                "10) Go back to main menu\n");
    }
    else if (self.menu_index == MENU_VOTE_WARMUP)
    {
        Sprint (self, PRINT_HIGH,
                "Vote for the warmup duration:\n"
                "1) 0 secondes (no warmup)\n"
                "2) 10 secondes\n"
                "3) 20 secondes\n"
                "4) 30 secondes\n"
                "5) 45 secondes\n"
                "6) 60 secondes\n"
                "7) 90 secondes\n"
                "8) 120 secondes\n"
                "9) 180 secondes\n"
                "\n"
                "10) Go back to main menu\n");
    }
    else if (self.menu_index == MENU_VOTE_OPTIONS)
    {
        Sprint (self, PRINT_HIGH,
                "Vote for an option:\n"
                "1) Toggle \"weapons stay\"\n"
                "2) Toggle \"lock teams\"\n"
                "3) Toggle \"flashy effects\"\n"
                "\n"
                "10) Go back to main menu\n");
    }
    else if (self.menu_index == MENU_VOTE_MAP_BLOOD)
    {
        Sprint (self, PRINT_HIGH,
                "Vote for a map:\n"
                "1) bb1  The Stronghold  | 2) bb2  Winter Wonderland\n"
                "3) bb3  Bodies          | 4) bb4  The Tower\n"
                "5) bb5  Click!          | 6) bb6  Twin Fortress\n"
                "7) bb7  Midgard         | 8) bb8  Fun With Heads\n"
                "\n"
                "10) Go back to map menu\n");
    }
    else if (self.menu_index == MENU_VOTE_MAP_BLOOD_SP)
    {
        Sprint (self, PRINT_HIGH,
                "Vote for a map:\n"
                "1) e1m1  Cradle to Grave  | 2) e1m2  Wrong Side of the Tracks\n"
                "3) e1m7  Altar of Stone   | 4) e4m8  The Hall Of Epiphany\n"
                "\n"
                "10) Go back to map menu\n");
    }
    else if (self.menu_index == MENU_VOTE_MAP_BLOODPACKS)
    {
        Sprint (self, PRINT_HIGH,
                "Vote for a map:\n"
                "1) dm1     Monolith Building 11  | 2) dm2     Power!\n"
                "3) dm3     Area 15               | 4) e6m8    Beauty and the Beast\n"
                "5) cpbb01  Crypt of Despair      | 6) cpbb03  Unholy Cathedral\n"
                "\n"
                "10) Go back to map menu\n");
    }
    else if (self.menu_index == MENU_VOTE_MAP_BLOOD2)
    {
        Sprint (self, PRINT_HIGH,
                "Vote for a map:\n"
                "1) b2a15  Area 15 (B2)  | 2) barena  Blood Arena\n"
                "3) bkeep  Blood Keep    | 4) bstar   Brown Star\n"
                "5) crypt  The Crypt\n"
                "\n"
                "10) Go back to map menu\n");
    }
    else if (self.menu_index == MENU_VOTE_MAP_TRANSFUSION)
    {
        Sprint (self, PRINT_HIGH,
                "Vote for a map:\n"
                "1) bb3_2k1   Bodies Infusion  | 2) dcamp  DeathCamp\n"
                "3) highnoon  HighNoon         | 4) qbb1   The Confluence\n"
                "5) qbb2      KathartiK        | 6) qbb3   Caleb's Woodland Retreat\n"
                "\n"
                "10) Go back to map menu\n");
    }
    else if (self.menu_index == MENU_VOTE_MAP_CONVERSIONS)
    {
        Sprint (self, PRINT_HIGH,
                "Vote for a map:\n"
                "1) dranzbb6  Black Coffee  | 2) fragm  Frag'M\n"
                "3) maim      Maim          | 4) qe1m7  The House of Chthon\n"
                "5) simple    Dead Simple\n"
                "\n"
                "10) Go back to map menu\n");
    }
};


/*
====================
Menu_HandleMain

Handles the impulses when the client is in the main menu
====================
*/
void() Menu_HandleMain =
{
    // If he wants to exit the menu
    if (self.impulse == 10)
    {
        self.player_state = PS_IDLE;
        Sprint (self, PRINT_HIGH, "\nExited from menu\n");
        return;
    }

    // Select the next menu to draw
    if (self.impulse == MENU_VOTE_MAP)
    {
        // If map voting is disabled
        if (cvar ("sv_disable") & SV_DISABLE_VOTE_MAP)
            Sprint (self, PRINT_HIGH, "\n===== Map voting is disabled on this server =====\n\n");
        else
            self.menu_index = MENU_VOTE_MAP;
    }
    else if (self.impulse == MENU_VOTE_GAMETYPE)
    {
        // If game type voting is disabled
        if (cvar ("sv_disable") & SV_DISABLE_VOTE_GAME)
            Sprint (self, PRINT_HIGH, "\n===== Game type voting is disabled on this server =====\n\n");
        else
            self.menu_index = MENU_VOTE_GAMETYPE;
    }
    else if (self.impulse == MENU_VOTE_FRAGLIMIT)
    {
        // If frag limit voting is disabled
        if (cvar ("sv_disable") & SV_DISABLE_VOTE_FRAG)
            Sprint (self, PRINT_HIGH, "\n===== Frag limit voting is disabled on this server =====\n\n");
        else
            self.menu_index = MENU_VOTE_FRAGLIMIT;
    }
    else if (self.impulse == MENU_VOTE_TIMELIMIT)
    {
        // If time limit voting is disabled
        if (cvar ("sv_disable") & SV_DISABLE_VOTE_TIME)
            Sprint (self, PRINT_HIGH, "\n===== Time limit voting is disabled on this server =====\n\n");
        else
            self.menu_index = MENU_VOTE_TIMELIMIT;
    }
    else if (self.impulse == MENU_VOTE_WARMUP)
    {
        // If warmup limit voting is disabled
        if (cvar ("sv_disable") & SV_DISABLE_VOTE_WARMUP)
            Sprint (self, PRINT_HIGH, "\n===== Warmup duration voting is disabled on this server =====\n\n");
        else
            self.menu_index = MENU_VOTE_WARMUP;
    }
    else if (self.impulse == MENU_VOTE_OPTIONS)
    {
        // If time limit voting is disabled
        if (cvar ("sv_disable") & SV_DISABLE_VOTE_OPTIONS)
            Sprint (self, PRINT_HIGH, "\n===== Options voting is disabled on this server =====\n\n");
        else
            self.menu_index = MENU_VOTE_OPTIONS;
    }
    else
        Sprint (self, PRINT_HIGH, "\n===== INVALID COMMAND =====\n\n");

    Menu_Draw ();
};


/*
====================
Menu_HandleVoteFraglimit

Handles the impulses when the client is in the frag limit menu
====================
*/
void() Menu_HandleVoteFraglimit =
{
    local string fl;

    // If we want to go back to main menu
    if (self.impulse == 10)
    {
        self.menu_index = MENU_MAIN;
        Menu_Draw ();
        return;
    }

    if (self.impulse == 1)
        fl = "10";
    else if (self.impulse == 2)
        fl = "20";
    else if (self.impulse == 3)
        fl = "30";
    else if (self.impulse == 4)
        fl = "50";
    else if (self.impulse == 5)
        fl = "75";
    else if (self.impulse == 6)
        fl = "100";
    else if (self.impulse == 7)
        fl = "150";
    else if (self.impulse == 8)
        fl = "200";
    else if (self.impulse == 9)
        fl = "unlimited";
    else
    {
        Sprint (self, PRINT_HIGH, "\n===== INVALID COMMAND =====\n\n");
        Menu_Draw ();
        return;
    }

    self.vote_fraglimit = self.impulse;
    Bprint (PRINT_HIGH, "Û ");  // "[ "
    Bprint (PRINT_HIGH, self.netname);
    Bprint (PRINT_HIGH, " votes for a new frag limit: ");
    Bprint (PRINT_HIGH, fl);
    Bprint (PRINT_HIGH, " Ý\n");  // " ]\n"

    // If the vote is passed
    if (Vote_IsPassed (vote_fraglimit, 255, self.impulse))
        Vote_ChangeFraglimit (fl);

    self.player_state = PS_IDLE;  // exit the menu
};


/*
====================
Menu_HandleVoteGametype

Handles the impulses when the client is in the game type menu
====================
*/
void() Menu_HandleVoteGametype =
{
    local string gt;

    // If we want to go back to main menu
    if (self.impulse == 10)
    {
        self.menu_index = MENU_MAIN;
        Menu_Draw ();
        return;
    }

    // If the command is invalid
    if (self.impulse > 5 )
    {
        Sprint (self, PRINT_HIGH, "\n===== INVALID COMMAND =====\n\n");
        Menu_Draw ();
        return;
    }

    self.vote_gametype = self.impulse;
    Bprint (PRINT_HIGH, "Û ");  // "[ "
    Bprint (PRINT_HIGH, self.netname);
    Bprint (PRINT_HIGH, " votes for ");
    gt = Vote_GametypeToString (self.impulse);
    Bprint (PRINT_HIGH, gt);
    Bprint (PRINT_HIGH, " Ý\n");  // " ]\n"

    // If the vote is passed
    if (Vote_IsPassed (vote_gametype, 255, self.impulse))
        Vote_ChangeGametype (self.vote_gametype);

    self.player_state = PS_IDLE;  // exit the menu
};


/*
====================
Menu_HandleVoteMapBlood

Handles the impulses when the client is in the Blood maps menu
====================
*/
void() Menu_HandleVoteMapBlood =
{
    local string newmap;

    // If we want to go back to map menu
    if (self.impulse == 10)
    {
        self.menu_index = MENU_VOTE_MAP;
        Menu_Draw ();
        return;
    }

    if (self.impulse == 1)
        newmap = "bb1";
    else if (self.impulse == 2)
        newmap = "bb2";
    else if (self.impulse == 3)
        newmap = "bb3";
    else if (self.impulse == 4)
        newmap = "bb4";
    else if (self.impulse == 5)
        newmap = "bb5";
    else if (self.impulse == 6)
        newmap = "bb6";
    else if (self.impulse == 7)
        newmap = "bb7";
    else if (self.impulse == 8)
        newmap = "bb8";
    else
    {
        Sprint (self, PRINT_HIGH, "\n===== INVALID COMMAND =====\n\n");
        Menu_Draw ();
        return;
    }

    // Validate the vote
    Vote_AddMapVote (MAPS_BLOOD + self.impulse, newmap);

    self.player_state = PS_IDLE;  // exit the menu
};


/*
====================
Menu_HandleVoteMapBloodSP

Handles the impulses when the client is in the Blood Single-Player maps menu
====================
*/
void() Menu_HandleVoteMapBloodSP =
{
    local string newmap;

    // If we want to go back to map menu
    if (self.impulse == 10)
    {
        self.menu_index = MENU_VOTE_MAP;
        Menu_Draw ();
        return;
    }

    if (self.impulse == 1)
        newmap = "e1m1";
    else if (self.impulse == 2)
        newmap = "e1m2";
    else if (self.impulse == 3)
        newmap = "e1m7";
    else if (self.impulse == 4)
        newmap = "e4m8";
    else
    {
        Sprint (self, PRINT_HIGH, "\n===== INVALID COMMAND =====\n\n");
        Menu_Draw ();
        return;
    }

    // Validate the vote
    Vote_AddMapVote (MAPS_BLOOD_SP + self.impulse, newmap);

    self.player_state = PS_IDLE;  // exit the menu
};


/*
====================
Menu_HandleVoteMapBloodPacks

Handles the impulses when the client is in the Blood packs menu
====================
*/
void() Menu_HandleVoteMapBloodPacks =
{
    local string newmap;

    // If we want to go back to map menu
    if (self.impulse == 10)
    {
        self.menu_index = MENU_VOTE_MAP;
        Menu_Draw ();
        return;
    }

    else if (self.impulse == 1)
        newmap = "dm1";
    else if (self.impulse == 2)
        newmap = "dm2";
    else if (self.impulse == 3)
        newmap = "dm3";
    else if (self.impulse == 4)
        newmap = "e6m8";
    else if (self.impulse == 5)
        newmap = "cpbb01";
    else if (self.impulse == 6)
        newmap = "cpbb03";
    else
    {
        Sprint (self, PRINT_HIGH, "\n===== INVALID COMMAND =====\n\n");
        Menu_Draw ();
        return;
    }

    // Validate the vote
    Vote_AddMapVote (MAPS_BLOODPACKS + self.impulse, newmap);

    self.player_state = PS_IDLE;  // exit the menu
};


/*
====================
Menu_HandleVoteMapBlood2

Handles the impulses when the client is in the Blood 2 menu
====================
*/
void() Menu_HandleVoteMapBlood2 =
{
    local string newmap;

    // If we want to go back to map menu
    if (self.impulse == 10)
    {
        self.menu_index = MENU_VOTE_MAP;
        Menu_Draw ();
        return;
    }

    if (self.impulse == 1)
        newmap = "b2a15";
    else if (self.impulse == 2)
        newmap = "barena";
    else if (self.impulse == 3)
        newmap = "bkeep";
    else if (self.impulse == 4)
        newmap = "bstar";
    else if (self.impulse == 5)
        newmap = "crypt";
    else
    {
        Sprint (self, PRINT_HIGH, "\n===== INVALID COMMAND =====\n\n");
        Menu_Draw ();
        return;
    }

    // Validate the vote
    Vote_AddMapVote (MAPS_BLOOD2 + self.impulse, newmap);

    self.player_state = PS_IDLE;  // exit the menu
};


/*
====================
Menu_HandleVoteMapTransfusion

Handles the impulses when the client is in the Transfusion menu
====================
*/
void() Menu_HandleVoteMapTransfusion =
{
    local string newmap;

    // If we want to go back to map menu
    if (self.impulse == 10)
    {
        self.menu_index = MENU_VOTE_MAP;
        Menu_Draw ();
        return;
    }

    if (self.impulse == 1)
        newmap = "bb3_2k1";
    else if (self.impulse == 2)
        newmap = "dcamp";
    else if (self.impulse == 3)
        newmap = "highnoon";
    else if (self.impulse == 4)
        newmap = "qbb1";
    else if (self.impulse == 5)
        newmap = "qbb2";
    else if (self.impulse == 6)
        newmap = "qbb3";
    else
    {
        Sprint (self, PRINT_HIGH, "\n===== INVALID COMMAND =====\n\n");
        Menu_Draw ();
        return;
    }

    // Validate the vote
    Vote_AddMapVote (MAPS_TRANSFUSION + self.impulse, newmap);

    self.player_state = PS_IDLE;  // exit the menu
};


/*
====================
Menu_HandleVoteMapConversions

Handles the impulses when the client is in the Conversions menu
====================
*/
void() Menu_HandleVoteMapConversions =
{
    local string newmap;

    // If we want to go back to map menu
    if (self.impulse == 10)
    {
        self.menu_index = MENU_VOTE_MAP;
        Menu_Draw ();
        return;
    }

    if (self.impulse == 1)
        newmap = "dranzbb6";
    else if (self.impulse == 2)
        newmap = "fragm";
    else if (self.impulse == 3)
        newmap = "maim";
    else if (self.impulse == 4)
        newmap = "qe1m7";
    else if (self.impulse == 5)
        newmap = "simple";
    else
    {
        Sprint (self, PRINT_HIGH, "\n===== INVALID COMMAND =====\n\n");
        Menu_Draw ();
        return;
    }

    // Validate the vote
    Vote_AddMapVote (MAPS_CONVERSIONS + self.impulse, newmap);

    self.player_state = PS_IDLE;  // exit the menu
};


/*
====================
Menu_HandleVoteMap

Handles the impulses when the client is in the map menu
====================
*/
void() Menu_HandleVoteMap =
{
    // If we want to go back to main menu
    if (self.impulse == 10)
    {
        self.menu_index = MENU_MAIN;
        Menu_Draw ();
        return;
    }

    // Select the next menu to draw
    if (self.impulse == 1)
        self.menu_index = MENU_VOTE_MAP_BLOOD;
    else if (self.impulse == 2)
        self.menu_index = MENU_VOTE_MAP_BLOOD_SP;
    else if (self.impulse == 3)
        self.menu_index = MENU_VOTE_MAP_BLOODPACKS;
    else if (self.impulse == 4)
        self.menu_index = MENU_VOTE_MAP_BLOOD2;
    else if (self.impulse == 5)
        self.menu_index = MENU_VOTE_MAP_TRANSFUSION;
    else if (self.impulse == 6)
        self.menu_index = MENU_VOTE_MAP_CONVERSIONS;
    else
        Sprint (self, PRINT_HIGH, "\n===== INVALID COMMAND =====\n\n");

    Menu_Draw ();
};


/*
====================
Menu_HandleVoteOptions

Handles the impulses when the client is in the option menu
====================
*/
void() Menu_HandleVoteOptions =
{
    local string cvarName;
    local float option;
    local float newValue;

    // If we want to go back to main menu
    if (self.impulse == 10)
    {
        self.menu_index = MENU_MAIN;
        Menu_Draw ();
        return;
    }

    if (self.impulse == 1)
    {
        cvarName = "g_weaponStay";
        option = OPTION_WEAPONS_STAY;
    }
    else if (self.impulse == 2)
    {
        cvarName = "g_lockTeams";
        option = OPTION_LOCK_TEAMS;
    }
    else if (self.impulse == 3)
    {
        cvarName = "g_flashyEffects";
        option = OPTION_FLASHY_EFFECTS;
    }
    else
    {
        Sprint (self, PRINT_HIGH, "\n===== INVALID COMMAND =====\n\n");
        Menu_Draw ();
        return;
    }

    newValue = ! cvar (cvarName);
    if (newValue)
        self.vote_options = self.vote_options | option;
    else
        self.vote_options = self.vote_options - (self.vote_options & option);

    Bprint (PRINT_HIGH, "Û ");  // "[ "
    Bprint (PRINT_HIGH, self.netname);
    Bprint (PRINT_HIGH, " votes for toggling \"");
    Bprint (PRINT_HIGH, cvarName);
    Bprint (PRINT_HIGH, "\" Ý\n");  // " ]\n"

    // If the vote is passed
    if (Vote_IsPassed (vote_options, option, option * newValue))
        Vote_ChangeOption (cvarName);

    self.player_state = PS_IDLE;  // exit the menu
};


/*
====================
Menu_HandleVoteTimelimit

Handles the impulses when the client is in the time limit menu
====================
*/
void() Menu_HandleVoteTimelimit =
{
    local string tl;

    // If we want to go back to main menu
    if (self.impulse == 10)
    {
        self.menu_index = MENU_MAIN;
        Menu_Draw ();
        return;
    }

    if (self.impulse == 1)
        tl = "5";
    else if (self.impulse == 2)
        tl = "10";
    else if (self.impulse == 3)
        tl = "15";
    else if (self.impulse == 4)
        tl = "20";
    else if (self.impulse == 5)
        tl = "25";
    else if (self.impulse == 6)
        tl = "30";
    else if (self.impulse == 7)
        tl = "40";
    else if (self.impulse == 8)
        tl = "60";
    else if (self.impulse == 9)
        tl = "unlimited";
    else
    {
        Sprint (self, PRINT_HIGH, "\n===== INVALID COMMAND =====\n\n");
        Menu_Draw ();
        return;
    }

    self.vote_timelimit = self.impulse;
    Bprint (PRINT_HIGH, "Û ");  // "[ "
    Bprint (PRINT_HIGH, self.netname);
    Bprint (PRINT_HIGH, " votes for a new time limit: ");
    Bprint (PRINT_HIGH, tl);
    Bprint (PRINT_HIGH, " Ý\n");  // " ]\n"

    // If the vote is passed
    if (Vote_IsPassed (vote_timelimit, 255, self.impulse))
        Vote_ChangeTimelimit (tl);

    self.player_state = PS_IDLE;  // exit the menu
};


/*
====================
Menu_HandleVoteWarmup

Handles the impulses when the client is in the warmup menu
====================
*/
void() Menu_HandleVoteWarmup =
{
    local string duration;

    // If we want to go back to main menu
    if (self.impulse == 10)
    {
        self.menu_index = MENU_MAIN;
        Menu_Draw ();
        return;
    }

    if (self.impulse == 1)
        duration = "0";
    else if (self.impulse == 2)
        duration = "10";
    else if (self.impulse == 3)
        duration = "20";
    else if (self.impulse == 4)
        duration = "30";
    else if (self.impulse == 5)
        duration = "45";
    else if (self.impulse == 6)
        duration = "60";
    else if (self.impulse == 7)
        duration = "90";
    else if (self.impulse == 8)
        duration = "120";
    else if (self.impulse == 9)
        duration = "180";
    else
    {
        Sprint (self, PRINT_HIGH, "\n===== INVALID COMMAND =====\n\n");
        Menu_Draw ();
        return;
    }

    self.vote_warmup = self.impulse;
    Bprint (PRINT_HIGH, "Û ");  // "[ "
    Bprint (PRINT_HIGH, self.netname);
    Bprint (PRINT_HIGH, " votes for a new warmup duration: ");
    Bprint (PRINT_HIGH, duration);
    Bprint (PRINT_HIGH, " secondes Ý\n");  // " ]\n"

    // If the vote is passed
    if (Vote_IsPassed (vote_warmup, 255, self.impulse))
        Vote_ChangeWarmup (duration);

    self.player_state = PS_IDLE;  // exit the menu
};


/*
====================
Menu_Start

Initialize the menu for the current client and show it
====================
*/
void() Menu_Start =
{
    // We can only access the menu if we're idle
    if (self.player_state != PS_IDLE)
    {
        centerprint (self, "You can only access the menu when idle");
        return;
    }

    self.menu_index = MENU_MAIN;
    self.player_state = PS_MENU;

    Menu_Draw ();
};


/*
====================
Menu_Update

Handles the impulses when the client is in the menu
====================
*/
void() Menu_Update =
{
    // If there's no pending command or if we're going to change map
    if (self.impulse == 0 || gameover)
        return;

    // Select the appropriate menu context
    if (self.menu_index == MENU_MAIN)
        Menu_HandleMain ();
    else if (self.menu_index == MENU_VOTE_MAP)
        Menu_HandleVoteMap ();
    else if (self.menu_index == MENU_VOTE_GAMETYPE)
        Menu_HandleVoteGametype ();
    else if (self.menu_index == MENU_VOTE_FRAGLIMIT)
        Menu_HandleVoteFraglimit ();
    else if (self.menu_index == MENU_VOTE_TIMELIMIT)
        Menu_HandleVoteTimelimit ();
    else if (self.menu_index == MENU_VOTE_WARMUP)
        Menu_HandleVoteWarmup ();
    else if (self.menu_index == MENU_VOTE_OPTIONS)
        Menu_HandleVoteOptions ();
    else if (self.menu_index == MENU_VOTE_MAP_BLOOD)
        Menu_HandleVoteMapBlood ();
    else if (self.menu_index == MENU_VOTE_MAP_BLOOD_SP)
        Menu_HandleVoteMapBloodSP ();
    else if (self.menu_index == MENU_VOTE_MAP_BLOODPACKS)
        Menu_HandleVoteMapBloodPacks ();
    else if (self.menu_index == MENU_VOTE_MAP_BLOOD2)
        Menu_HandleVoteMapBlood2 ();
    else if (self.menu_index == MENU_VOTE_MAP_TRANSFUSION)
        Menu_HandleVoteMapTransfusion ();
    else if (self.menu_index == MENU_VOTE_MAP_CONVERSIONS)
        Menu_HandleVoteMapConversions ();

    self.impulse = 0;
};
