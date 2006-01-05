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

void() plat_center_touch;
//void() plat_outside_touch;
void() plat_trigger_use;
void() plat_go_up;
void() plat_go_down;
void() plat_crush;

void() plat_spawn_inside_trigger =
{
	local entity    trigger;
	local vector    tmin, tmax;

	//
	// middle trigger
	//
	trigger = spawn();
	trigger.touch = plat_center_touch;
	trigger.movetype = MOVETYPE_NONE;
	trigger.solid = SOLID_TRIGGER;
	trigger.enemy = self;

	tmin = self.mins + '25 25 0';
	tmax = self.maxs - '25 25 -8';
	tmin_z = tmax_z - (self.pos1_z - self.pos2_z + 8);
	if (self.spawnflags & PLAT_LOW_TRIGGER)
		tmax_z = tmin_z + 8;

	if (self.size_x <= 50)
	{
		tmin_x = (self.mins_x + self.maxs_x) / 2;
		tmax_x = tmin_x + 1;
	}
	if (self.size_y <= 50)
	{
		tmin_y = (self.mins_y + self.maxs_y) / 2;
		tmax_y = tmin_y + 1;
	}

	setsize (trigger, tmin, tmax);
};

void() plat_hit_top =
{
	if (self.sounds)
	sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);

	self.state = STATE_TOP;

	if (self.style) // Automated platform
		plat_go_down();
	else
	{
		self.think = plat_go_down;
		self.nextthink = self.ltime + 3;
	}
};

void() plat_hit_bottom =
{
	if (self.sounds)
	sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);

	self.state = STATE_BOTTOM;

	if (self.style) // Automated platform
		plat_go_up();
};

void() plat_go_down =
{
	if (self.sounds)
	sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);

	self.state = STATE_DOWN;
	SUB_CalcMove (self.pos2, self.speed, plat_hit_bottom);
};

void() plat_go_up =
{
	if (self.sounds)
	sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);

	self.state = STATE_UP;
	SUB_CalcMove (self.pos1, self.speed, plat_hit_top);
};

void() plat_center_touch =
{
	if (other.classname != "player" ||  // Monster
	other.health <= 0           ||  // Dead player
	self.style > 0)                 // Automated platform
		return;

	self = self.enemy;
	if (self.state == STATE_BOTTOM)
	{
		if (self.cnt > time)
			return; // delay until going up again
		plat_go_up ();
	}
	self.cnt = time + 2;
};

/*
void() plat_outside_touch =
{
	if (other.classname != "player" ||  // Monster
	other.health <= 0           ||  // Dead player
	self.style > 0)                 // Automated platform
		return;

	self = self.enemy;
	if (self.state == STATE_TOP)
		plat_go_down ();
};
*/

void() plat_trigger_use =
{
	if (self.think)
		return;     // already activated
	plat_go_down();
};

void() plat_crush =
{
	// Don't hurt players
	if (other.classname == "player")
		return;

	other.deathtype = "squish";
	T_Damage (other, self, self, 999/*self.dmg*/, DF_CRUSH, "squish");

	if (self.state == STATE_UP)
		plat_go_down ();
	else if (self.state == STATE_DOWN)
		plat_go_up ();
	else
		objerror ("plat_crush: bad self.state\n");
};

void() plat_use =
{
	self.use = SUB_Null;
	if (self.state != STATE_UP)
		objerror ("plat_use: not in up state");
	plat_go_down();
};

/*QUAKED func_plat (0 .5 .8) ? PLAT_LOW_TRIGGER
speed   default 150

Plats are always drawn in the extended position, so they will light correctly.

If the plat is the target of another trigger or button, it will start out disabled in the extended position until it is trigger, when it will lower and become a normal plat.

If the "height" key is set, that will determine the amount the plat moves, instead of being implicitly determined by the model's height.
Set "sounds" to one of the following:
1) base fast
2) chain slow
*/
void() func_plat =
{
	local entity t;

	if (!self.t_length)
		self.t_length = 80;
	if (!self.t_width)
		self.t_width = 10;

	precache_sound ("thevoice/squash.wav");

	if (self.noise)
		if (self.noise1) // If mapper set the sounds manually in the map
			self.sounds == 3;          // Arbitary, but will work unless we add more sound groups

	if (self.sounds == 1)
	{
		precache_sound ("plats/plat1.wav");
		precache_sound ("plats/plat2.wav");
		self.noise = "plats/plat1.wav";       // Up
		self.noise1 = "plats/plat2.wav";      // Down
	}
	else if (self.sounds == 2)
	{
		precache_sound ("doors/qdoormv1.wav");
		precache_sound ("doors/qdrclos4.wav");
		self.noise = "doors/qdoormv1.wav";    // Up
		self.noise1 = "doors/qdrclos4.wav";   // Down
	}

	self.mangle = self.angles;
	self.angles = '0 0 0';

	self.classname = "plat";
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	setorigin (self, self.origin);
	setmodel (self, self.model);
	setsize (self, self.mins , self.maxs);

	self.blocked = plat_crush;

	if (!self.speed)
		self.speed = 150;

	if (!self.dmg)
		self.dmg = 1;

	// pos1 is the top position, pos2 is the bottom
	self.pos1 = self.origin;
	self.pos2 = self.origin;
	if (self.height)
		self.pos2_z = self.origin_z - self.height;
	else
		self.pos2_z = self.origin_z - self.size_z + 8;

	self.use = plat_trigger_use;

	plat_spawn_inside_trigger ();   // the "start moving" trigger

	if (self.targetname)
	{
		self.state = STATE_UP;
		self.use = plat_use;
	}
	else
	{
		setorigin (self, self.pos2);
		self.state = STATE_BOTTOM;

		if (self.style)         // Automated
			if (!self.wait)
				plat_go_up();
			else
			{   // The mapper has set the automated platform to wait before going
				self.think = plat_go_up;
				self.nextthink = time + self.wait;
			}
	}
};

//============================================================================
void() train_next;
void() func_train_find;

void() train_blocked =
{
	if (time < self.attack_finished)
		return;
	self.attack_finished = time + 0.5;
	// FIXME:  PM -- Are there trains in Blood?  If so, is it instant death?
	other.deathtype = "squish";
	T_Damage (other, self, self, self.dmg, DF_CRUSH, "squish");
};

void() train_use =
{
	if (self.think != func_train_find)
		return;     // already activated
	train_next();
};

void() train_wait =
{
	if (self.wait)
	{
		self.nextthink = self.ltime + self.wait;
		sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	}
	else
		self.nextthink = self.ltime + 0.1;

	self.think = train_next;
};

void() train_next =
{
	local entity    targ;

	targ = find (world, targetname, self.target);
	self.target = targ.target;
	if (!self.target)
		objerror ("train_next: no next target");
	if (targ.wait)
		self.wait = targ.wait;
	else
		self.wait = 0;
	sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
	SUB_CalcMove (targ.origin - self.mins, self.speed, train_wait);
};

void() func_train_find =

{
	local entity    targ;

	targ = find (world, targetname, self.target);
	self.target = targ.target;
	setorigin (self, targ.origin - self.mins);
	if (!self.targetname)
	{   // not triggered, so start immediately
		self.nextthink = self.ltime + 0.1;
		self.think = train_next;
	}
};

/*QUAKED func_train (0 .5 .8) ?
Trains are moving platforms that players can ride.
The targets origin specifies the min point of the train at each corner.
The train spawns at the first target it is pointing at.
If the train is the target of a button or trigger, it will not begin moving until activated.
speed   default 100
dmg     default 2
sounds
1) ratchet metal

*/
void() func_train =
{
	if (!self.speed)
	self.speed = 100;
	if (!self.target)
		objerror ("func_train without a target");
	if (!self.dmg)
		self.dmg = 2;

	precache_sound ("thevoice/squash.wav");

	if (self.sounds == 0)
	{
		self.noise = "misc/null.wav";
		self.noise1 = "misc/null.wav";
	}

	if (self.sounds == 1)
	{
		self.noise = ("ambience/gearhalt.wav");
		precache_sound ("ambience/gearhalt.wav");
		self.noise1 = ("ambience/gearstar.wav");
		precache_sound ("ambience/gearstar.wav");
	}

	self.cnt = 1;
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	self.blocked = train_blocked;
	self.use = train_use;
	self.classname = "train";

	setmodel (self, self.model);
	setsize (self, self.mins , self.maxs);
	setorigin (self, self.origin);

	// start trains on the second frame, to make sure their targets have had
	// a chance to spawn
	self.nextthink = self.ltime + 0.1;
	self.think = func_train_find;
};
