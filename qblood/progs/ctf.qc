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
#include "player.qh"


// flag status used in cnt field of flag
#define FLAG_AT_BASE 0
#define FLAG_CARRIED 1
#define FLAG_DROPPED 2

#define TEAM_CAPTURE_CAPTURE_BONUS  15  // what you get for capture
#define TEAM_CAPTURE_RECOVERY_BONUS 1   // what you get for recovery

#define TEAM_CAPTURE_FLAG_RETURN_TIME 40  // seconds until auto return


$cd id1/models/flag
$base base
$skin skin


void(entity flg) RegenFlag =
{
    flg.movetype = MOVETYPE_TOSS;
    flg.solid = SOLID_TRIGGER;
    if (flg.owner)
    #ifdef QUAKEWORLD
        flg.owner.effects = flg.owner.effects - (flg.owner.effects & (EF_FLAG1 | EF_FLAG2));
    setmodel(flg, flg.mdl);
    #else
        flg.owner.effects = flg.owner.effects - (flg.owner.effects & EF_DIMLIGHT);
    flg.effects = flg.effects | EF_DIMLIGHT;
    if (flg.team == TEAM_COLOR1)
        flg.effects = flg.effects | EF_RED;
    else
        flg.effects = flg.effects | EF_BLUE;
    #endif
    setorigin(flg, flg.oldorigin);
    flg.angles = flg.mangle;
    flg.cnt = FLAG_AT_BASE; // it's at home base
    flg.owner = world;
    flg.velocity = '0 0 0';
    sound (flg, CHAN_ITEM, "bludbath/respawn2.wav", 1, ATTN_NORM); // play respawn sound
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


void() CTF_FlagReset =
{
    RegenFlag (self);
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
            if (! (other.items2 & IT2_ENEMY_FLAG))
                return;

            other.items2 = other.items2 - IT2_ENEMY_FLAG;

            // The score stays 0/0 until the warmup is finished
            if (warmup_done)
            {
                if (self.team == TEAM_COLOR1)
                    team1score = team1score + 1;
                else
                    team2score = team2score + 1;
            }

            // the flag is at home base.  if the player has the enemy
            // flag, he's just won!
            Bprint (PRINT_HIGH, other.netname);
            if (other.team == TEAM_COLOR1)
                Bprint (PRINT_HIGH, " ãáðôõòåä the ÂÌÕÅ flag!\n"); // blue
            else
                Bprint (PRINT_HIGH, " ãáðôõòåä the ÒÅÄ flag!\n"); // red

            Cl_PrintTeamScores ();

            sound (self, CHAN_VOICE, self.noise2, 1, ATTN_NONE);

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
        sound (self, CHAN_ITEM, self.noise1, 1, ATTN_NONE);
        TeamCaptureReturnFlag(self);
        return;
    }

    // hey, its not our flag, pick it up
    Bprint (PRINT_HIGH, other.netname);
    if (other.team == TEAM_COLOR1)
        Bprint (PRINT_HIGH, " çïô the ÂÌÕÅ flag!\n"); // blue
    else
        Bprint (PRINT_HIGH, " çïô the ÒÅÄ flag!\n"); // red
    centerprint (other, "ÙÏÕ ÇÏÔ ÔÈÅ ÅÎÅÍÙ ÆÌÁÇ\n\nÒÅÔÕÒÎ ÔÏ ÂÁÓÅ");  // == "YOU GOT THE ENEMY FLAG!\n\nRETURN TO BASE!"
    sound (self, CHAN_ITEM, self.noise, 1, ATTN_NONE);

    other.items2 = other.items2 + IT2_ENEMY_FLAG;

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
    setmodel (self, string_null);  // Make the flag desappear. The EF_FLAG? effect will show it on the client
    #else
    // We remove the glow on the flag and transfers the EF_DIMLIGHT effect to the player
    self.effects = self.effects - (self.effects & (EF_DIMLIGHT | EF_RED | EF_BLUE));
    self.owner.effects = self.owner.effects | EF_DIMLIGHT;
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
    #else
    p.effects = p.effects - (p.effects & EF_DIMLIGHT);
    #endif

    flg.origin = p.origin - '0 0 24';
    flg.cnt = FLAG_DROPPED;
    flg.velocity_z = 300;
    flg.velocity_x = 0;
    flg.velocity_y = 0;
    flg.flags = FL_ITEM;
    flg.solid = SOLID_TRIGGER;
    flg.movetype = MOVETYPE_TOSS;
    #ifdef QUAKEWORLD
    setmodel(flg, flg.mdl);
    #else
    flg.effects = flg.effects | EF_DIMLIGHT;
    if (flg.team == TEAM_COLOR1)
        flg.effects = flg.effects | EF_RED;
    else
        flg.effects = flg.effects | EF_BLUE;
    #endif
    setsize(flg, '-16 -16 0', '16 16 74');

    // return it after so long
    flg.search_time = time + TEAM_CAPTURE_FLAG_RETURN_TIME;
};


void() CTF_PlayerDropFlag =
{
    local string kn;
    local entity e;

    if (!(self.items2 & IT2_ENEMY_FLAG))
        return;
    if (self.team == TEAM_COLOR1)
        kn = "item_flag_team2";
    else
        kn = "item_flag_team1";
    self.items2 = self.items2 - IT2_ENEMY_FLAG;
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
        if (time - self.search_time > TEAM_CAPTURE_FLAG_RETURN_TIME)
            TeamCaptureReturnFlag(self);
        return;
    }

    if (self.cnt != FLAG_CARRIED)
        objerror("Flag in invalid state\n");

    // If we're not in QW, we must manage the flag ourselves
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
    if (self.owner.frame >= $pitchpain1 && self.owner.frame <= $pain5) {
        if (self.owner.frame >= $pitchpain1 && self.owner.frame <= $pitchpain5) {
            if      (self.owner.frame == $pitchpain1) f = f + 2;
            else if (self.owner.frame == $pitchpain2) f = f + 8;
            else if (self.owner.frame == $pitchpain3) f = f + 12;
            else if (self.owner.frame == $pitchpain4) f = f + 10;
            else if (self.owner.frame == $pitchpain5) f = f + 4;
        } else if (self.owner.frame >= $pain1 && self.owner.frame <= $pain5) {
            if      (self.owner.frame == $pain1) f = f + 2;
            else if (self.owner.frame == $pain2) f = f + 10;
            else if (self.owner.frame == $pain3) f = f + 10;
            else if (self.owner.frame == $pain4) f = f + 8;
            else if (self.owner.frame == $pain5) f = f + 2;
        }
    }
    else if (self.owner.frame >= $attack1 && self.owner.frame <= $attack2) f = f + 6;

    self.origin = e.origin + '0 0 -16' - f*v + v_right * 22;
    self.angles = e.angles + '0 0 -45';
    setorigin (self, self.origin);
    self.nextthink = time + 0.01;
    #endif
};


void() place_flag = {
    setmodel (self, "progs/flag.mdl");
    setsize(self, '-6 -7 -1', '6 49 75');

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
    #ifndef QUAKEWORLD
    if (self.team == TEAM_COLOR1)
        self.effects = self.effects | EF_RED;
    else
        self.effects = self.effects | EF_BLUE;
    #endif
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
    if (gametype != GT_CAPTURE_THE_FLAG)
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
    self.reset = CTF_FlagReset;
};

void() item_flag_team2 =
{
    // If CTF is not the current mode
    if (gametype != GT_CAPTURE_THE_FLAG)
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
    self.reset = CTF_FlagReset;
};


/*QUAKED func_ctf_wall (0 .5 .8) ?
This is just a solid wall if not inhibitted
Only appears in CTF teamplay
*/
void() func_ctf_wall =
{
    if (gametype != GT_CAPTURE_THE_FLAG)
    {
        remove(self);
        return;
    }

    self.angles = '0 0 0';
    self.movetype = MOVETYPE_PUSH;  // so it doesn't get pushed by anything
    self.solid = SOLID_BSP;
    setmodel (self, self.model);
};
