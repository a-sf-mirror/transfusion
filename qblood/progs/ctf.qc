/*  Copyright (C) 1996-1997  Id Software, Inc.

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


.float items2;

// Team colors
#ifdef QUAKEWORLD
# define TEAM_COLOR1 4
# define TEAM_COLOR2 13
#else
# define TEAM_COLOR1 5
# define TEAM_COLOR2 14
#endif

#define ITEM_ENEMY_FLAG 1

// flag status used in cnt field of flag
#define FLAG_AT_BASE 0
#define FLAG_CARRIED 1
#define FLAG_DROPPED 2

#define TEAM_CAPTURE_CAPTURE_BONUS  15  // what you get for capture
#define TEAM_CAPTURE_RECOVERY_BONUS 1   // what you get for recovery
#define TEAM_CAPTURE_FLAG_BONUS     0   // what you get for picking up enemy flag

#define TEAM_CAPTURE_FLAG_RETURN_TIME 40  // seconds until auto return


$cd id1/models/flag
$base base
$skin skin


void(entity flg) RegenFlag =
{
    flg.movetype = MOVETYPE_TOSS;
    flg.solid = SOLID_TRIGGER;
    #ifdef QUAKEWORLD
    setmodel(flg, flg.mdl);
    #endif
    setorigin(flg, flg.oldorigin);
    flg.angles = flg.mangle;
    flg.cnt = FLAG_AT_BASE; // it's at home base
    flg.owner = world;
    #ifdef QUAKEWORLD
    flg.velocity = '0 0 0';
    #endif
    sound (flg, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM); // play respawn sound
};


void(entity flg) TeamCaptureReturnFlag =
{
    local entity p;

    RegenFlag(flg);

    p = find(world, classname, "player");
    while (p != world) {
        if (p.team != flg.team)
            centerprint (p, "Enemy flag has been returned to base!");
        else if (p.team == flg.team)
            centerprint (p, "Your flag has been returned to base!");
        p = find(p, classname, "player");
    }
};


void () TeamCaptureRegenFlags =
{
    local entity f;

    f = find(world, classname, "item_flag_team1");
    if (f != world)
        RegenFlag(f);
    f = find(world, classname, "item_flag_team2");
    if (f != world)
        RegenFlag(f);
};


// possum: 3 loops in one.  Hopefully this will help prevent an
// occasional server lockup when a player picks up and then captures the
// flag in rapid succession
/*void() LoopThroughPlayersAfterCapture =
{
    local entity p;

    // count up teamscr
    lastteamscrtime = time + TEAMSCRTIME;
    teamscr1 = teamscr2 = 0;

    // Ok, let's do the player loop, hand out the bonuses, add up
    // the scores, and inform the players about the capture

    p = find(world, classname, "player");
    while (p != world) {

        // Ok, let's do the player loop, hand out the bonuses
        self = p;
        self.killed = 0;
        if (self.steam == other.steam && self != other)
            self.frags = self.frags + TEAM_CAPTURE_TEAM_BONUS;
        if (self.steam != other.steam) {
            // *XXX* EXPERT CTF
            // reset the last_hurt_carrier variable in all enemy
            // players, so that you don't get bonuses for defending
            // the flag carrier if the flag carrier has already
            // completed a capture
            self.last_hurt_carrier = -5;
        } else if (self.steam == other.steam) {
            // done to all players on the capturing team
            // *XXX* EXPERT CTF
            // award extra points for capture assists
            if (self.last_returned_flag + TEAM_CAPTURE_RETURN_FLAG_ASSIST_TIMEOUT > time) {
                bprint(PRINT_HIGH, self.netname);
                bprint(PRINT_HIGH, " gets an assist for returning his flag!\n");
                self.frags = self.frags + TEAM_CAPTURE_RETURN_FLAG_ASSIST_BONUS;
            }
            if (self.last_fragged_carrier + TEAM_CAPTURE_FRAG_CARRIER_ASSIST_TIMEOUT > time) {
                bprint(PRINT_HIGH, self.netname);
                bprint(PRINT_HIGH, " gets an assist for fragging the flag carrier!\n");
                self.frags = self.frags + TEAM_CAPTURE_FRAG_CARRIER_ASSIST_BONUS;
            }
        }
        self.player_flag = self.player_flag - (self.player_flag & ITEM_ENEMY_FLAG);

        // count up teamscr
        if (p.steam == TEAM_COLOR1)
            teamscr1 = teamscr1 + p.frags;
        else if (p.steam == TEAM_COLOR2)
            teamscr2 = teamscr2 + p.frags;

        // inform players about capture
        if ((p.steam == TEAM_COLOR1 && other.steam == TEAM_COLOR2) ||
            (p.steam == TEAM_COLOR2 && other.steam == TEAM_COLOR1))
            TeamPlayerUpdate(p, "Your flag was captured!");
        else if (p.steam == other.steam)
            TeamPlayerUpdate(p, "Your team captured the flag!");

        // remove any flags
        p.effects = p.effects - (p.effects & (EF_FLAG1 | EF_FLAG2));

        p = find(p, classname, "player");
    }
};*/


void() CTF_FlagTouch =
{
    local entity p, oself;

    if (other.classname != "player")
        return;
    if (other.health <= 0)
        return;

    if (self.team == other.team)
    {
        // same team, if the flag is *not* at the base, return
        // it to base.  we overload the 'cnt' field for this
        if (self.cnt == FLAG_AT_BASE)
        {
            // the player doesn't have the enemy flag. Nothing to do...
            if (! (other.items2 & ITEM_ENEMY_FLAG))
                return;

            // the flag is at home base.  if the player has the enemy
            // flag, he's just won!
            Bprint (PRINT_HIGH, other.netname);
            if (other.team == TEAM_COLOR1)
                Bprint (PRINT_HIGH, " ãáðôõòåä the ÂÌÕÅ flag!\n"); // blue
            else
                Bprint (PRINT_HIGH, " ãáðôõòåä the ÒÅÄ flag!\n"); // red
            other.items = other.items - (other.items & (IT_KEY1 | IT_KEY2));

            sound (other, CHAN_VOICE, "misc/flagcap.wav", 1, ATTN_NONE);

            // other gets another 10 frag bonus
            other.frags = other.frags + TEAM_CAPTURE_CAPTURE_BONUS;

            // possum: 3 loops in one
            //LoopThroughPlayersAfterCapture();  // <<=== TODO

            // respawn flags
            TeamCaptureRegenFlags();
            return;  // its at home base already
        }

        // hey, its not home.  return it by teleporting it back
        Bprint (PRINT_HIGH, other.netname);
        if (other.team == TEAM_COLOR1)
            Bprint (PRINT_HIGH, " òåôõòîåä the ÒÅÄ flag!\n"); // red
        else
            Bprint (PRINT_HIGH, " òåôõòîåä the ÂÌÕÅ flag!\n"); // blue
        other.frags = other.frags + TEAM_CAPTURE_RECOVERY_BONUS;
        sound (other, CHAN_ITEM, self.noise1, 1, ATTN_NORM);
        TeamCaptureReturnFlag(self);
        return;
    }

    // hey, its not our flag, pick it up
    Bprint (PRINT_HIGH, other.netname);
    if (other.team == TEAM_COLOR1)
        Bprint (PRINT_HIGH, " çïô the ÂÌÕÅ flag!\n"); // blue
    else
        Bprint (PRINT_HIGH, " çïô the ÒÅÄ flag!\n"); // red
    if (TEAM_CAPTURE_FLAG_BONUS)
        other.frags = other.frags + TEAM_CAPTURE_FLAG_BONUS;
    centerprint (other, "ÙÏÕ ÇÏÔ ÔÈÅ ÅÎÅÍÙ ÆÌÁÇ\n\nÒÅÔÕÒÎ ÔÏ ÂÁÓÅ");  // == "YOU GOT THE ENEMY FLAG!\n\nRETURN TO BASE!"
    sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);

    other.items2 = other.items2 + ITEM_ENEMY_FLAG;
    other.items = other.items | self.items;

    // pick up the flag
    self.cnt = FLAG_CARRIED;
    #ifndef QUAKEWORLD
    self.movetype = MOVETYPE_NOCLIP;
    #endif
    self.solid = SOLID_NOT;
    self.owner = other;

    #ifdef QUAKEWORLD
    if (self.team == TEAM_COLOR1)
        self.owner.effects = self.owner.effects | EF_FLAG1;
    else // must be other team
        self.owner.effects = self.owner.effects | EF_FLAG2;
    setmodel(self, "");
    #endif

    p = find(world, classname, "player");
    while (p != world) {
        if (p != other) {
            if ((p.team == TEAM_COLOR1 && other.team == TEAM_COLOR2) ||
                (p.team == TEAM_COLOR2 && other.team == TEAM_COLOR1))
                centerprint (p, "Your flag has been taken!");
            else if (p.team == other.team)
                centerprint (p, "Your team has the enemy flag!");
        }
        p = find(p, classname, "player");
    }
};


void(entity flg) TeamDropFlag =
{
    local entity item, f, oself;
    local entity p;

    p = flg.owner;

    Bprint (PRINT_HIGH, p.netname);
    if (p.team == TEAM_COLOR1)
        Bprint (PRINT_HIGH, " ìïóô the ÂÌÕÅ flag!\n"); // blue
    else
        Bprint (PRINT_HIGH, " ìïóô the ÒÅÄ flag!\n"); // red
    #ifdef QUAKEWORLD
    p.effects = p.effects - (p.effects & (EF_FLAG1 | EF_FLAG2));
    #endif

    flg.origin = p.origin - '0 0 24';
    flg.cnt = FLAG_DROPPED;
    //NOTE! We check lastteam here instead of team--this is because
    //in the mode where we change colors, we get killed
    flg.velocity_z = 300;
    flg.velocity_x = 0;
    flg.velocity_y = 0;
    flg.flags = FL_ITEM;
    flg.solid = SOLID_TRIGGER;
    flg.movetype = MOVETYPE_TOSS;
    #ifdef QUAKEWORLD
    setmodel(flg, flg.mdl);
    #endif
    setsize(flg, '-16 -16 0', '16 16 74');

    // return it after so long
    flg.super_time = time + TEAM_CAPTURE_FLAG_RETURN_TIME;
};


void() CTF_FlagThink =
{
    local entity e;
    local vector v;
    local float f;
    local string s;

    self.nextthink = time + 0.1;

    if (self.cnt == FLAG_AT_BASE)
        return; // just sitting around waiting to be picked up

    if (self.cnt == FLAG_DROPPED) {
        if (time - self.ltime > TEAM_CAPTURE_FLAG_RETURN_TIME)
            //TeamCaptureReturnFlag(self);  // <===================== TODO
        return;
    }

    if (self.cnt != FLAG_CARRIED)
        objerror("Flag in invalid state\n");

    #ifndef QUAKEWORLD
    e = self.owner;
    if ((e.classname != "player") || (e.deadflag)) {
        TeamDropFlag(self);
        return;
    }
    makevectors (e.angles);
    v = v_forward;
    v_z = (-1) * v_z; // reverse z component

    f = 14;
    if (self.owner.frame >= 29 && self.owner.frame <= 40) {
        if (self.owner.frame >= 29 && self.owner.frame <= 34) { //axpain
            if      (self.owner.frame == 29) f = f + 2;
            else if (self.owner.frame == 30) f = f + 8;
            else if (self.owner.frame == 31) f = f + 12;
            else if (self.owner.frame == 32) f = f + 11;
            else if (self.owner.frame == 33) f = f + 10;
            else if (self.owner.frame == 34) f = f + 4;
        } else if (self.owner.frame >= 35 && self.owner.frame <= 40) { // pain
            if      (self.owner.frame == 35) f = f + 2;
            else if (self.owner.frame == 36) f = f + 10;
            else if (self.owner.frame == 37) f = f + 10;
            else if (self.owner.frame == 38) f = f + 8;
            else if (self.owner.frame == 39) f = f + 4;
            else if (self.owner.frame == 40) f = f + 2;
        }
    } else if (self.owner.frame >= 103 && self.owner.frame <= 118) {
        if      (self.owner.frame >= 103 && self.owner.frame <= 104) f = f + 6;  //nailattack
        else if (self.owner.frame >= 105 && self.owner.frame <= 106) f = f + 6;  //light
        else if (self.owner.frame >= 107 && self.owner.frame <= 112) f = f + 7;  //rocketattack
        else if (self.owner.frame >= 112 && self.owner.frame <= 118) f = f + 7;  //shotattack
    }
    self.origin = e.origin + '0 0 -16' - f*v + v_right * 22;
    self.angles = e.angles + '0 0 -45';
    setorigin (self, self.origin);
    self.nextthink = time + 0.01;
    #endif
};


void() place_flag = {
    self.noise = "misc/flagtk.wav";
    self.noise1 = "doors/runetry.wav";

    setmodel (self, "progs/flag.mdl");
    setsize(self, '-16 -16 0', '16 16 74');

    self.mdl = self.model;      // so it can be restored on respawn
    self.flags = FL_ITEM;       // make extra wide
    self.solid = SOLID_TRIGGER;
    self.movetype = MOVETYPE_TOSS;
    self.velocity = '0 0 0';
    self.origin_z = self.origin_z + 6;
    self.think = CTF_FlagThink;
    self.touch = CTF_FlagTouch;
    self.nextthink = time + 0.1;
    self.cnt = FLAG_AT_BASE;
    self.mangle = self.angles;
    self.effects = self.effects | EF_DIMLIGHT;
    if (!droptofloor()) {
        dprint ("Flag fell out of level at ");
        dprint (vtos(self.origin));
        dprint ("\n");
        remove(self);
        return;
    }
    self.oldorigin = self.origin; // save for flag return
};


// ZOID Capture the flag
void() item_flag_team1 =
{
    // If CTF is not the current mode
    if (deathmatch != 2)
    {
        remove(self);
        return;
    }

    precache_sound ("misc/flagcap.wav");  // flag capture
    precache_sound ("misc/flagtk.wav");         // flag taken
    precache_sound ("doors/runetry.wav");

    precache_model ("progs/flag.mdl");

    self.team = TEAM_COLOR1;
    self.items = IT_KEY1;
    self.skin = 0;
    self.nextthink = time + 0.2;    // items start after other solids
    self.think = place_flag;
};

void() item_flag_team2 =
{
    // If CTF is not the current mode
    if (deathmatch != 2)
    {
        remove(self);
        return;
    }

    precache_sound ("misc/flagcap.wav");  // flag capture
    precache_sound ("misc/flagtk.wav");         // flag taken
    precache_sound ("doors/runetry.wav");

    precache_model ("progs/flag.mdl");

    self.team = TEAM_COLOR2;
    self.items = IT_KEY2;
    self.skin = 1;
    self.nextthink = time + 0.2;    // items start after other solids
    self.think = place_flag;
};


// Team base starting locations
void() info_player_team1 =
{
};

void() info_player_team2 =
{
};


/*QUAKED func_ctf_wall (0 .5 .8) ?
This is just a solid wall if not inhibitted
Only appears in CTF teamplay
*/
void() func_ctf_wall =
{
    if (deathmatch != 2)
    {
        remove(self);
        return;
    }

    self.angles = '0 0 0';
    self.movetype = MOVETYPE_PUSH;  // so it doesn't get pushed by anything
    self.solid = SOLID_BSP;
    setmodel (self, self.model);
};
