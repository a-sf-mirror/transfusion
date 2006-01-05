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

/*

Doors are similar to buttons, but can spawn a fat trigger field around them
to open without a touch, and they link together to form simultanious
double/quad doors.

Door.owner is the master door.  If there is only one door, it points to itself.
If multiple doors, all will point to a single one.

Door.enemy chains from the master door through all doors linked in the chain.

*/

/*
=============================================================================

THINK FUNCTIONS

=============================================================================
*/

void() door_go_down;
void() door_go_up;

void() door_blocked =
{
	// Don't hurt players
	if (other.classname == "player")
	return;

	// Used to do self.dmg for damage.
	T_Damage (other, self, self, 999/*other.health + 10*/, DF_NO_PROTECT, "squish");

	// if a door has a negative wait, it would never come back if blocked,
	// so let it just squash the object to death real fast
	if (self.wait >= 0)
	{
		if (self.state == STATE_DOWN)
			door_go_up ();
		else
			door_go_down ();
	}
};


void() door_hit_top =
{
	sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
	self.state = STATE_TOP;

	if (self.spawnflags & DOOR_TOGGLE)
		return;     // don't come down automatically
	self.think = door_go_down;
	self.nextthink = self.ltime + self.wait;
};

void() door_hit_bottom =
{
	sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
	self.state = STATE_BOTTOM;
};

void() door_go_down =
{
	//dprint ("door_go_down\n");
	sound (self, CHAN_VOICE, self.noise2, 1, ATTN_NORM);
	if (self.max_health)
	{
		self.takedamage = DAMAGE_YES;
		self.health = self.max_health;
	}

	self.state = STATE_DOWN;
	SUB_CalcMove (self.pos1, self.speed, door_hit_bottom);
};

void() door_go_up =
{
	//dprint ("door_go_up\n");
	if (self.state == STATE_UP)
	return;     // already going up

	if (self.state == STATE_TOP)
	{   // reset top wait time
		self.nextthink = self.ltime + self.wait;
		return;
	}

	sound (self, CHAN_VOICE, self.noise2, 1, ATTN_NORM);
	self.state = STATE_UP;
	SUB_CalcMove (self.pos2, self.speed, door_hit_top);

	SUB_UseTargets();
};

/*
=============================================================================

ACTIVATION FUNCTIONS

=============================================================================
*/

void() door_fire =
{
	//dprint ("door_fire\n");
	local entity    oself;
	local entity    starte;

	if (self.owner != self)
		objerror ("door_fire: self.owner != self");

	// play use key sound

	if (self.items2)
		sound (self, CHAN_VOICE, self.noise4, 1, ATTN_NORM);

	self.message = string_null;     // no more message
	oself = self;

	if (self.spawnflags & DOOR_TOGGLE)
	{
		if (self.state == STATE_UP || self.state == STATE_TOP)
		{
			starte = self;
			do
			{
				door_go_down ();
				self = self.enemy;
			} while ( (self != starte) && (self != world) );
			self = oself;
			return;
		}
	}

	// trigger all paired doors
	starte = self;
	do
	{
		self.goalentity = activator;        // Who fired us
		door_go_up ();
		self = self.enemy;
	} while ( (self != starte) && (self != world) );
	self = oself;
};

void() door_use =
{
	local entity oself;

	self.message = string_null;          // door message are for touch only
	self.owner.message = string_null;
	self.enemy.message = string_null;

	oself = self;
	self = self.owner;

	// FIXME: blink key on player's status bar
	//was (self.items2 & other.items2)
	if ((self.items2 & other.items2) != self.items2 &&
		(gametype == GT_COOPERATIVE || gametype == GT_SINGLE_PLAYER))
		// So all doors are unlocked in deathmatch/ctf
	{
		if (self.owner.items2 == IT2_KEY_SKULL)
			centerprint (other, "You need the skull key");
		else if (self.owner.items2 == IT2_KEY_EYE)
			centerprint (other, "You need the eye key");
		else if (self.owner.items2 == IT2_KEY_FIRE)
			centerprint (other, "You need the fire key");
		else if (self.owner.items2 == IT2_KEY_DAGGER)
			centerprint (other, "You need the dagger key");
		else if (self.owner.items2 == IT2_KEY_SPIDER)
			centerprint (other, "You need the spider key");
		else if (self.owner.items2 == IT2_KEY_MOON)
			centerprint (other, "You need the moon key");
		else
			centerprint (other, "It's locked but the key doesn't exist!");

		// Play on two channels so the player can hear himself clearly.
		sound (other, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
		sound (other, CHAN_BODY, self.noise3, 1, ATTN_NORM);
		return;
	}    

	if (!self.cnt && self.classname == "func_door_secret")
	{
		found_secrets = found_secrets + 1;
		self.cnt = 1;
	}	

	door_fire ();
	self = oself;
};

void() door_trigger_touch =
{
	if (other.health <= 0)
		return;

	if (time < self.attack_finished)
		return;
	self.attack_finished = time + 1;

	activator = other;

	self = self.owner;
	door_use ();
};

void() door_killed =
{
	//dprint ("door_killed\n");
	local entity oself;

	oself = self;
	self = self.owner;
	self.health = self.max_health;
	self.takedamage = DAMAGE_NO;    // will be reset upon return
	door_use ();
	self = oself;
};

/*
================
door_touch

Prints messages and opens key doors
================
*/
void() door_touch =
{
	if (other.classname != "player")
	return;
	if (self.owner.attack_finished > time)
		return;

	self.owner.attack_finished = time + 2;

	if (self.owner.message != string_null)
	{
		centerprint (other, self.owner.message);
		sound (other, CHAN_VOICE, "bludbath/message.wav", 1, ATTN_NORM);
	}
	/*
	// key door stuff
	if (!self.items2)
		return;

	// FIXME: blink key on player's status bar
	//was (self.items2 & other.items2)
	if ((self.items2 & other.items2) != self.items2 &&
		(gametype == GT_COOPERATIVE || gametype == GT_SINGLE_PLAYER))
		// So all doors are unlocked in deathmatch/ctf
	{
		if (self.owner.items2 == IT2_KEY_SKULL)
			centerprint (other, "You need the skull key");
		else if (self.owner.items2 == IT2_KEY_EYE)
			centerprint (other, "You need the eye key");
		else if (self.owner.items2 == IT2_KEY_DAGGER)
			centerprint (other, "You need the fire key");
		else if (self.owner.items2 == IT2_KEY_SPIDER)
			centerprint (other, "You need the dagger key");
		else if (self.owner.items2 == IT2_KEY_MOON)
			centerprint (other, "You need the spider key");
		else if (self.owner.items2 == IT2_KEY_MOON)
			centerprint (other, "You need the moon key");
		else
			centerprint (other, "It's locked but the key doesn't exist!");

		// Play on two channels so the player can hear himself clearly.
		sound (other, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
		sound (other, CHAN_BODY, self.noise3, 1, ATTN_NORM);
		return;
	}    */
	self.touch = SUB_Null;
	if (self.enemy)
		self.enemy.touch = SUB_Null;    // get paired door
	door_use ();
};

/*
=============================================================================

SPAWNING FUNCTIONS

=============================================================================
*/

entity(vector fmins, vector fmaxs) spawn_field =
{
	local entity    trigger;
	local   vector  t1, t2;

	trigger = spawn();
	trigger.movetype = MOVETYPE_NONE;
	trigger.solid = SOLID_TRIGGER;
	trigger.owner = self;
	trigger.touch = door_trigger_touch;

	t1 = fmins;
	t2 = fmaxs;
	setsize (trigger, t1 - '60 60 8', t2 + '60 60 8');
	return (trigger);
};

float (entity e1, entity e2) EntitiesTouching =
{
	if (e1.mins_x > e2.maxs_x)
	return FALSE;
	if (e1.mins_y > e2.maxs_y)
		return FALSE;
	if (e1.mins_z > e2.maxs_z)
		return FALSE;
	if (e1.maxs_x < e2.mins_x)
		return FALSE;
	if (e1.maxs_y < e2.mins_y)
		return FALSE;
	if (e1.maxs_z < e2.mins_z)
		return FALSE;
	return TRUE;
};

/*
=============
LinkDoors
=============
*/
void() LinkDoors =
{
	local entity    t, starte;
	local vector    cmins, cmaxs;

	if (self.enemy)
		return;     // already linked by another door
	if (self.spawnflags & DOOR_DONT_LINK)
	{
		self.owner = self.enemy = self;
		return;     // don't want to link this door
	}

	cmins = self.mins;
	cmaxs = self.maxs;

	starte = self;
	t = self;

	do
	{
		self.owner = starte;            // master door

		if (self.health)
			starte.health = self.health;
		if (self.targetname)
			starte.targetname = self.targetname;
		if (self.message != string_null)
			starte.message = self.message;

		t = find (t, classname, self.classname);
		if (!t)
		{
			self.enemy = starte;        // make the chain a loop

			// shootable, fired, or key doors just needed the owner/enemy links,
			// they don't spawn a field

			self = self.owner;

			if (self.health)
				return;
			if (self.targetname)
				return;
			if (self.items2)
				return;
			if (self.spawnflags & SF_USABLE)
				return;

			self.owner.trigger_field = spawn_field(cmins, cmaxs);

			return;
		}

		if (EntitiesTouching(self,t))
		{
			if (t.enemy)
				objerror ("cross connected doors");

			self.enemy = t;
			self = t;

			if (t.mins_x < cmins_x)
				cmins_x = t.mins_x;
			if (t.mins_y < cmins_y)
				cmins_y = t.mins_y;
			if (t.mins_z < cmins_z)
				cmins_z = t.mins_z;
			if (t.maxs_x > cmaxs_x)
				cmaxs_x = t.maxs_x;
			if (t.maxs_y > cmaxs_y)
				cmaxs_y = t.maxs_y;
			if (t.maxs_z > cmaxs_z)
				cmaxs_z = t.maxs_z;
		}
	} while (1 );

};

/*QUAKED func_door (0 .5 .8) ? START_OPEN x DOOR_DONT_LINK GOLD_KEY SILVER_KEY TOGGLE
if two doors touch, they are assumed to be connected and operate as a unit.

TOGGLE causes the door to wait in both the start and end states for a trigger event.

START_OPEN causes the door to move to its destination when spawned, and operate in reverse.  It is used to temporarily or permanently close off an area when triggered (not usefull for touch or takedamage doors).

Key doors are allways wait -1.

"message"   is printed when the door is touched if it is a trigger door and it hasn't been fired yet
"angle"     determines the opening direction
"targetname" if set, no touch field will be spawned and a remote button or trigger field activates the door.
"health"    if set, door must be shot open
"speed"     movement speed (100 default)
"wait"      wait before returning (4 default, -1 = never return)
"lip"       lip remaining at end of move (8 default)
"dmg"       damage to inflict when blocked (2 default)
"sounds"
0)  no sound
1)  stone
2)  base
3)  stone chain
4)  screechy metal
*/

void() func_door =
{
	local string sound1, sound2;

	precache_sound ("thevoice/squash.wav");

	// REMOVEME: temporary hack
	// shootable, fired, or key doors can't get triggered manually
	if (!self.health && !self.targetname && !self.items2 && !self.flags)
		self.spawnflags = self.spawnflags | SF_USABLE;

	// All key doors make Caleb say "I need a key!"
	precache_sound ("player/hunt4.wav");
	self.noise3 = "player/hunt4.wav";

	// Worldtype for key doors
	if (world.worldtype == 0)
	{
		precache_sound ("locks/baseuse.wav");
		self.noise4 = "locks/baseuse.wav";
	}
	else if (world.worldtype == 1)
	{
		precache_sound ("locks/runeuse.wav");
		self.noise4 = "locks/runeuse.wav";
	}
	else if (world.worldtype == 2)
	{
		precache_sound ("locks/swtchwrk.wav");
		self.noise4 = "locks/swtchwrk.wav";
	}
	else
		dprint ("no worldtype set!\n");

	if (self.sounds == 0)
	{
		sound1 = "misc/null.wav";
		sound2 = "misc/null.wav";
	}
	else if (self.sounds == 1)
	{
		sound1 = "doors/qdrclos4.wav";
		sound2 = "doors/qairdoor.wav";
	}
	else if (self.sounds == 2)
	{
		sound1 = "ambience/hydro3.wav";
		sound2 = "ambience/qhydro1.wav";
	}
	else if (self.sounds == 3)
	{
		sound1 = "doors/qdrclos4.wav";
		sound2 = "ambience/qwinch2.wav";
	}
	else if (self.sounds == 4)
	{
		sound1 = "doors/dooropen.wav";
		sound2 = "doors/doorclos.wav";
	}
	if (self.noise1 == string_null)
		self.noise1 = sound1;
	if (self.noise2 == string_null)
		self.noise2 = sound2;
	precache_sound (self.noise1);
	precache_sound (self.noise2);

	SetMovedir ();

	self.max_health = self.health;
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	setorigin (self, self.origin);
	setmodel (self, self.model);
	self.classname = "door";

	self.blocked = door_blocked;
	self.use = door_use;

	if (self.spawnflags & DOOR_SKULL_KEY)
		self.items2 = IT2_KEY_SKULL;
	if (self.spawnflags & DOOR_EYE_KEY)
		self.items2 = IT2_KEY_EYE;
	if (self.spawnflags & DOOR_FIRE_KEY)
		self.items2 = IT2_KEY_FIRE;
	if (self.spawnflags & DOOR_DAGGER_KEY)
		self.items2 = IT2_KEY_DAGGER;
	if (self.spawnflags & DOOR_SPIDER_KEY)
		self.items2 = IT2_KEY_SPIDER;
	if (self.spawnflags & DOOR_MOON_KEY)
		self.items2 = IT2_KEY_MOON;

	if (!self.speed)
		self.speed = 100;
	if (!self.wait)
		self.wait = 4;
	if (!self.lip)
		self.lip = 8;
	if (!self.dmg)
		self.dmg = 2;

	self.pos1 = self.origin;
	self.pos2 = self.pos1 + self.movedir*(fabs(self.movedir*self.size) - self.lip);

	// DOOR_START_OPEN is to allow an entity to be lighted in the closed position
	// but spawn in the open position
	if (self.spawnflags & DOOR_START_OPEN)
	{
		setorigin (self, self.pos2);
		self.pos2 = self.pos1;
		self.pos1 = self.origin;
	}

	self.state = STATE_BOTTOM;

	if (self.health)
	{
		self.takedamage = DAMAGE_YES;
		self.th_die = door_killed;
	}

	// Once a key door is opened, it stays opened
	if (self.items2)
		self.wait = -1;

	// If the door can't be opened manually, it can be opened by touch
	if (! (self.spawnflags & SF_USABLE))
		self.touch = door_touch;

	// LinkDoors can't be done until all of the doors have been spawned, so
	// the sizes can be detected properly.
	self.think = LinkDoors;
	self.nextthink = self.ltime + 0.1;

};

void () func_door_secret =
{
	func_door();
};
