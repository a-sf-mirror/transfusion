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
Vote_ChangeGametype

Used when the vote for a gametype is passed
====================
*/
void(float newGametype) Vote_ChangeGametype =
{
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
    Bprint (PRINT_HIGH, Vote_GametypeToString (self.impulse));
    Bprint (PRINT_HIGH, " Ý\n");  // " ]\n"
};


/*
====================
Vote_GametypeToString

Give the string describing the
====================
*/
string(float gtNumber) Vote_GametypeToString =
{
    if (gtNumber == 1)
        return "Âlood Âath";
    else if (gtNumber == 2)
        return "Ôeam Âlood Âath";
    else if (gtNumber == 3)
        return "Ôeam Âlood Âath with friendly fire";
    else if (gtNumber == 4)
        return "Ãapture Ôhe Ælag";
    else if (gtNumber == 5)
        return "Ãapture Ôhe Ælag with friendly fire";
    else
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
        return;
    }

    // Select the next menu to draw
    if (self.impulse == 1)
        self.menu_index = MENU_VOTE_MAP;
    else if (self.impulse == 2)
        self.menu_index = MENU_VOTE_GAMETYPE;
    else
        Sprint (self, PRINT_HIGH, "\n===== INVALID COMMAND =====\n\n");

    Menu_Draw ();
};


/*
====================
Menu_HandleVoteGametype

Handles the impulses when the client is in the game type menu
====================
*/
void() Menu_HandleVoteGametype =
{
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
    Bprint (PRINT_HIGH, Vote_GametypeToString (self.impulse));
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

    self.impulse = 0;
};
