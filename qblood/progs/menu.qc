/*  Copyright (C) 2001  Mathieu Olivier

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

void() execute_changelevel;
string(float gtNumber) Vote_GametypeToString;


/*
====================
Vote_ChangeMap

Used when the vote for a map is passed
====================
*/
void(string newmap) Vote_ChangeMap =
{
    local entity warp;

    nextmap = newmap;

    // we can't move people right now, because touch functions are called
    // in the middle of C movement code, so set a think time to do it
    warp = spawn();
    warp.map = nextmap;
    warp.think = execute_changelevel;
    warp.nextthink = time + 0.1;

    gameover = TRUE;

    Bprint (PRINT_HIGH, "Û Vote passed. Switching to map ");  // "[ Vote passed ..."
    Bprint (PRINT_HIGH, nextmap);
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
float(.float vote_field, float value) Vote_IsPassed =
{
    local entity player;
    local float VoteTotal;
    local float VoteCount;

    VoteCount = 0;
    VoteTotal = 0;
    player = find (world, classname, "player");
    while (player != world)
    {
        // If it's a real player (not a bot)
        if (player.ishuman == 1)
        {
            VoteTotal = VoteTotal + 1;
            if (player.vote_field == value)
                VoteCount = VoteCount + 1;
        }

        player = find (player, classname, "player");
    }

    // more than 50% is requiered to pass a vote
    return (VoteCount >= ceil ((VoteTotal + 1) / 2));
};


//=========================================================================

// The menus
#define MENU_MAIN           0
#define MENU_VOTE_MAP       1
#define MENU_VOTE_GAMETYPE  2
#define MENU_VOTE_FRAGLIMIT 3
#define MENU_VOTE_TIMELIMIT 4

#define NB_MENUS            5


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
                "\n"
                "10) Exit menu\n");
    }
    else if (self.menu_index == MENU_VOTE_MAP)
    {
        Sprint (self, PRINT_HIGH,
                "Vote for a map:\n"
                "1) bb2      Winter Wonderland  | 2) bb3  Bodies\n"
                "3) bb3_2k1  Bodies Classic     | 4) bb4  The Tower\n"
                "5) bb5      Click!             | 6) bb7  Midgard\n"
                "7) bb8      Fun With Heads     | 8) dm2  Power!\n"
                "9) dm3      Area15\n"
                "\n"
                "10) Go back to main menu\n");
    }
    else if (self.menu_index == MENU_VOTE_GAMETYPE)
    {
        Sprint (self, PRINT_HIGH,
                "Vote for a game type:\n"
                "1) Blood Bath\n"
                "2) Team Blood Bath\n"
                "3) Team Blood Bath with friendly fire\n"
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

    // If the command is invalid
    if (self.impulse > 9 )
    {
        Sprint (self, PRINT_HIGH, "\n===== INVALID COMMAND =====\n\n");
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

    self.vote_fraglimit = self.impulse;
    Bprint (PRINT_HIGH, "Û ");  // "[ "
    Bprint (PRINT_HIGH, self.netname);
    Bprint (PRINT_HIGH, " votes for a new frag limit: ");
    Bprint (PRINT_HIGH, fl);
    Bprint (PRINT_HIGH, " Ý\n");  // " ]\n"

    // If the vote is passed
    if (Vote_IsPassed (vote_fraglimit, self.impulse))
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
    if (Vote_IsPassed (vote_gametype, self.impulse))
        Vote_ChangeGametype (self.vote_gametype);

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
    local string newmap;

    // If we want to go back to main menu
    if (self.impulse == 10)
    {
        self.menu_index = MENU_MAIN;
        Menu_Draw ();
        return;
    }

    // If the command is invalid
    if (self.impulse > 9)
    {
        Sprint (self, PRINT_HIGH, "\n===== INVALID COMMAND =====\n\n");
        Menu_Draw ();
        return;
    }

    if (self.impulse == 1)
        newmap = "bb2";
    else if (self.impulse == 2)
        newmap = "bb3";
    else if (self.impulse == 3)
        newmap = "bb3_2k1";
    else if (self.impulse == 4)
        newmap = "bb4";
    else if (self.impulse == 5)
        newmap = "bb5";
    else if (self.impulse == 6)
        newmap = "bb7";
    else if (self.impulse == 7)
        newmap = "bb8";
    else if (self.impulse == 8)
        newmap = "dm2";
    else if (self.impulse == 9)
        newmap = "dm3";

    self.vote_map = self.impulse;
    Bprint (PRINT_HIGH, "Û ");  // "[ "
    Bprint (PRINT_HIGH, self.netname);
    Bprint (PRINT_HIGH, " votes for map ");
    Bprint (PRINT_HIGH, newmap);
    Bprint (PRINT_HIGH, " Ý\n");  // " ]\n"

    // If the vote is passed
    if (Vote_IsPassed (vote_map, self.impulse))
        Vote_ChangeMap (newmap);

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

    // If the command is invalid
    if (self.impulse > 9 )
    {
        Sprint (self, PRINT_HIGH, "\n===== INVALID COMMAND =====\n\n");
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

    self.vote_timelimit = self.impulse;
    Bprint (PRINT_HIGH, "Û ");  // "[ "
    Bprint (PRINT_HIGH, self.netname);
    Bprint (PRINT_HIGH, " votes for a new time limit: ");
    Bprint (PRINT_HIGH, tl);
    Bprint (PRINT_HIGH, " Ý\n");  // " ]\n"

    // If the vote is passed
    if (Vote_IsPassed (vote_timelimit, self.impulse))
        Vote_ChangeTimelimit (tl);

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

    self.impulse = 0;
};
