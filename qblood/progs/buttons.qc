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
// button and multiple button


#include "common.qh"


void() button_wait;
void() button_return;

void() button_wait =
{    
    self.state = STATE_TOP;

    if (self.wait)
    {
        self.nextthink = self.ltime + self.wait;
        self.think = button_return;
    }

    activator = self.enemy;
    SUB_UseTargets();
    self.frame = 1;         // use alternate textures
};

void() button_done =
{
    self.state = STATE_BOTTOM;
};

void() button_return =
{
    if (self.state == STATE_TOP && !self.style)
    {
        activator = self.enemy;
        sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
        SUB_UseTargets();
    }

    self.state = STATE_DOWN;

    if (self.style)
        SUB_CalcMove (self.pos1, self.speed, button_done);
    else
        button_done();

    self.frame = 0;         // use normal textures
    if (self.health)
        self.takedamage = DAMAGE_YES;   // can be shot again
};


void() button_blocked =
{   // do nothing, just don't come all the way back out
};


void() button_fire =
{
    if (self.state == STATE_UP || self.state == STATE_TOP)
        return;

    sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);

    self.state = STATE_UP;

    if (self.style)
        SUB_CalcMove (self.pos2, self.speed, button_wait);
    else
        button_wait();
};


void() button_use =
{
    self.enemy = activator;
    button_fire ();
};

void() button_touch =
{
    if (other.classname != "player")
        return;

    if (self.state == STATE_TOP && self.wait < 0)
	    return;

    // to avoid switching button 100 times a second  
	if (self.attack_finished > time)
        return;
    else
        self.attack_finished = time + 1;

    self.enemy = other;

    if (self.state == STATE_TOP && !self.style)
        button_return();
    else
        button_fire ();
};

void() button_killed =
{
    self.enemy = damage_attacker;
    self.health = self.max_health;
    self.takedamage = DAMAGE_NO;    // wil be reset upon return
    button_fire ();
};


/*QUAKED func_button (0 .5 .8) ?
When a button is touched, it moves some distance in the direction of it's angle, triggers all of it's targets, waits some time, then returns to it's original position where it can be triggered again.

"angle"     determines the opening direction
"target"    all entities with a matching targetname will be used
"speed"     override the default 40 speed
"wait"      override the default 1 second wait (-1 = never return)
"lip"       override the default 4 pixel lip remaining at end of move
"health"    if set, the button must be killed instead of touched
"sounds"
0) steam metal
1) wooden clunk
2) metallic click
3) in-out

FIXME 5/2/2001 - dturner - some sort of mapping needs to be made matching above
descriptions with something appropriate to Blood.  prolly have to make more maps
and see what the engine chooses to use from current, then make adjustments.

*/
void() func_button =
{
local float     gtemp, ftemp;

    if (self.noise)
	{
	    precache_sound (self.noise);
	}	
	else if (self.sounds == 0)
    {
        precache_sound ("locks/switch1.wav");
        self.noise = "locks/switch1.wav";
    }
    else if (self.sounds == 1)
    {
        precache_sound ("locks/runeuse.wav");
        self.noise = "locks/runeuse.wav";
    }
    else if (self.sounds == 2)
    {
        precache_sound ("locks/qlatch2.wav");
        self.noise = "locks/qlatch2.wav";
    }
    else if (self.sounds == 3)
    {
        precache_sound ("locks/qlatch2.wav");
        self.noise = "locks/qlatch2.wav";
    }
	else if (self.sounds == 4)
	{
	    precache_sound ("misc/null.wav");
        self.noise = "misc/null.wav";
	}
	
    SetMovedir ();

    self.movetype = MOVETYPE_PUSH;
    self.solid = SOLID_BSP;
    setmodel (self, self.model);

    self.blocked = button_blocked;
    self.use = button_use;

    if (self.health)
    {
        self.max_health = self.health;
        self.th_die = button_killed;
        self.takedamage = DAMAGE_YES;
    }
    else if (!self.style)
    {
        self.spawnflags = self.spawnflags | SF_USABLE;
        self.use = button_touch;
    }
    else
        self.touch = button_touch;

    if (!self.speed)
        self.speed = 40;
    if (!self.wait)
        self.wait = 1;
    if (!self.lip)
        self.lip = 4;

    self.state = STATE_BOTTOM;

    self.pos1 = self.origin;
    self.pos2 = self.pos1 + self.movedir*(fabs(self.movedir*self.size) - self.lip);
};

void() changelevel_use =
{
    local entity    pos;

    if (other.classname != "player")
        return;

    if ((cvar("noexit") == 1) || ((cvar("noexit") == 2) && (mapname != "start")))
    {
        T_Damage (other, self, self, 50000, DF_BODY, "exitkill");
        return;
    }

    if (gametype != GT_SINGLE_PLAYER)
    {
        bprint (other.netname);
        bprint (" exited the level\n");
    }

    nextmap = self.map;

    SUB_UseTargets ();

    self.frame = 1 - self.frame;

    if ( (self.spawnflags & 1) && gametype != GT_SINGLE_PLAYER)
    {    // NO_INTERMISSION
        GotoNextMap();
        return;
    }

    self.use = SUB_Null;

    execute_changelevel();
};

/*QUAKED func_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player uses this, he gets sent to the map listed in the "map" variable.  Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
*/
void() func_changelevel =
{
    if (!self.map)
        objerror ("changelevel func doesn't have map");

    if (gametype != GT_SINGLE_PLAYER && gametype != GT_COOPERATIVE)
    {
        remove(self);
        return;
    }

    self.spawnflags = self.spawnflags | SF_USABLE;
    self.solid = SOLID_BSP;
    self.movetype = MOVETYPE_PUSH;
    setmodel (self, self.model);
    self.use = changelevel_use;
};
