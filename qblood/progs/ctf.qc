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
    setorigin(flg, flg.oldorigin);
    flg.angles = flg.mangle;
    flg.cnt = FLAG_AT_BASE; // it's at home base
    flg.owner = world;
    flg.velocity = '0 0 0';
    sound (flg, CHAN_VOICE, "bludbath/respawn2.wav", 1, ATTN_NORM); // play respawn sound
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
            if (! (other.items & IT_ENEMY_FLAG))
                return;

            other.items = other.items - IT_ENEMY_FLAG;

            if (self.team == TEAM_COLOR1)
                team1score = team1score + 1;
            else
                team2score = team2score + 1;

            // the flag is at home base.  if the player has the enemy
            // flag, he's just won!
            Bprint (PRINT_HIGH, other.netname);
            if (other.team == TEAM_COLOR1)
                Bprint (PRINT_HIGH, " ãáðôõòåä the ÂÌÕÅ flag!\n"); // blue
            else
                Bprint (PRINT_HIGH, " ãáðôõòåä the ÒÅÄ flag!\n"); // red

            Bprint (PRINT_HIGH, "RED: ");
            Bprint (PRINT_HIGH, ftos (team1score));
            Bprint (PRINT_HIGH, " / BLUE: ");
            Bprint (PRINT_HIGH, ftos (team2score));
            Bprint (PRINT_HIGH, "\n");

            sound (other, CHAN_VOICE, self.noise2, 1, ATTN_NONE);

            // other gets another 10 frag bonus
            other.frags = other.frags + TEAM_CAPTURE_CAPTURE_BONUS;

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

    other.items = other.items + IT_ENEMY_FLAG;

    // pick up the flag
    self.cnt = FLAG_CARRIED;
    self.movetype = MOVETYPE_NOCLIP;
    self.solid = SOLID_NOT;
    self.owner = other;

    #ifdef QUAKEWORLD
    if (self.team == TEAM_COLOR1)
        self.owner.effects = self.owner.effects | EF_FLAG1;
    else // must be other team
        self.owner.effects = self.owner.effects | EF_FLAG2;
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
    setsize(flg, '-16 -16 0', '16 16 74');

    // return it after so long
    flg.super_time = time + TEAM_CAPTURE_FLAG_RETURN_TIME;
};


void() CTF_PlayerDropFlag =
{
    local string kn;
    local entity e;

    if (!(self.items & IT_ENEMY_FLAG))
        return;
    if (self.team == TEAM_COLOR1)
        kn = "item_flag_team2";
    else
        kn = "item_flag_team1";
    self.items = self.items - IT_ENEMY_FLAG;
    e = find(world, classname, kn);
    if (e != world)
        TeamDropFlag (e);
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
        if (time - self.super_time > TEAM_CAPTURE_FLAG_RETURN_TIME)
            TeamCaptureReturnFlag(self);
        return;
    }

    if (self.cnt != FLAG_CARRIED)
        objerror("Flag in invalid state\n");

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
};


void() place_flag = {
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

    precache_model ("progs/flag.mdl");

    precache_sound ("thevoice/8000.wav");  // "Red captures the flag"
    precache_sound ("thevoice/8002.wav");  // "Red returns the flag"
    precache_sound ("thevoice/8006.wav");  // "Red flag stolen"

    precache_sound ("bludbath/respawn2.wav");  // Respawn sound

    self.noise = "thevoice/8006.wav";
    self.noise1 = "thevoice/8002.wav";
    self.noise2 = "thevoice/8000.wav";

    self.team = TEAM_COLOR1;
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

    precache_model ("progs/flag.mdl");

    precache_sound ("thevoice/8001.wav");  // "Blue captures the flag"
    precache_sound ("thevoice/8003.wav");  // "Blue returns the flag"
    precache_sound ("thevoice/8007.wav");  // "Blue flag stolen"

    precache_sound ("bludbath/respawn2.wav");  // Respawn sound

    self.noise = "thevoice/8007.wav";
    self.noise1 = "thevoice/8003.wav";
    self.noise2 = "thevoice/8001.wav";

    self.team = TEAM_COLOR2;
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


// self is player
entity() CTF_Spawn =
{
    local entity spawnpoint;

    if (self.team == TEAM_COLOR1)
    {
        team1_lastspawn = find(team1_lastspawn, classname, "info_player_team1");
        if (team1_lastspawn == world)
            team1_lastspawn = find(team1_lastspawn, classname, "info_player_team1");
        return team1_lastspawn;

    }
    else if (self.team == TEAM_COLOR2)
    {
        team2_lastspawn = find(team2_lastspawn, classname, "info_player_team2");
        if (team2_lastspawn == world)
            team2_lastspawn = find(team2_lastspawn, classname, "info_player_team2");
        return team2_lastspawn;
    }
    return world;
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
