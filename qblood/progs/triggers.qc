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

void() shake_screen;

void() trigger_reactivate =
{
	self.solid = SOLID_TRIGGER;
};

//=============================================================================

// the wait time has passed, so set back up for another activation
void() multi_wait =
{
	if (self.max_health)
	{
		self.health = self.max_health;
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
	}
};

// the trigger was just touched/killed/used
// self.enemy should be set to the activator so it can be held through a delay
// so wait for the delay time before firing
void() multi_trigger =
{
	if (self.nextthink > time)
	{
		return;     // allready been triggered
	}

	if (self.classname == "trigger_secret")
	{
		if (self.enemy.classname != "player")
			return;
		found_secrets = found_secrets + 1;
		WriteByte(MSG_ALL, SVC_FOUNDSECRET);
	}

	if (self.noise)
		sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM);

	// don't trigger again until reset
	self.takedamage = DAMAGE_NO;

	activator = self.enemy;

	SUB_UseTargets();

	if (self.wait > 0)
	{
		self.think = multi_wait;
		self.nextthink = time + self.wait;
	}
	else
	{   // we can't just remove (self) here, because this is a touch function
		// called while C code is looping through area links...
		self.touch = SUB_Null;
		self.nextthink = time + 0.1;
		self.think = SUB_Remove;
	}
};

void() multi_killed =
{
	self.enemy = damage_attacker;
	multi_trigger();
};

void() multi_use =
{
	self.enemy = activator;
	multi_trigger();
};

void() multi_touch =
{
	if (other.classname != "player")
		return;

	// if the trigger has an angles field, check player's facing direction
	if (self.movedir != '0 0 0')
	{
		makevectors(other.angles);
		if (v_forward * self.movedir < 0)
			return;     // not facing the right way
	}

	self.enemy = other;
	multi_trigger();
};

/*QUAKED trigger_multiple (.5 .5 .5) ? notouch
Variable sized repeatable trigger.  Must be targeted at one or more entities.  If "health" is set, the trigger must be killed to activate each time.
If "delay" is set, the trigger waits some time after activating before firing.
"wait" : Seconds between triggerings. (.2 default)
If notouch is set, the trigger is only fired by other entities, not by touching.
NOTOUCH has been obsoleted by trigger_relay!
sounds
1)  secret
2)  beep beep
3)  large switch
4)
set "message" to text string
*/
void() trigger_multiple =
{
	/*if (self.sounds == 1)
	{
		precache_sound("bludbath/powerup.wav");
		self.noise = "bludbath/powerup.wav";
	}
		else if (self.sounds == 2)
		self.noise = "bludbath/message.wav";
	else if (self.sounds == 3)
	{
		precache_sound("locks/baseuse.wav");
		self.noise = "locks/baseuse.wav";
	}*/

	if (!self.wait)
	self.wait = 0.2;
	self.use = multi_use;

	InitTrigger();

	if (self.health)
	{
		if (self.spawnflags & SPAWNFLAG_NOTOUCH)
			objerror("health and notouch don't make sense\n");
		self.max_health = self.health;
		self.th_die = multi_killed;
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
		setorigin(self, self.origin);  // make sure it links into the world
	}
	else
	{
		if (!(self.spawnflags & SPAWNFLAG_NOTOUCH))
			self.touch = multi_touch;
	}
};

/*QUAKED trigger_once (.5 .5 .5) ? notouch
Variable sized trigger. Triggers once, then removes itself.  You must set the key "target" to the name of another object in the level that has a matching
"targetname".  If "health" is set, the trigger must be killed to activate.
If notouch is set, the trigger is only fired by other entities, not by touching.
if "killtarget" is set, any objects that have a matching "target" will be removed when the trigger is fired.
if "angle" is set, the trigger will only fire when someone is facing the direction of the angle.  Use "360" for an angle of 0.
sounds
1)  secret
2)  beep beep
3)  large switch
4)
set "message" to text string
*/
void() trigger_once =
{
	self.wait = -1;
	trigger_multiple();
};

//=============================================================================
/*QUAKED trigger_relay (.5 .5 .5) (-8 -8 -8) (8 8 8)
This fixed size trigger cannot be touched, it can only be fired by other events.  It can contain killtargets, targets, delays, and messages.
*/
void() trigger_relay =
{
	self.use = SUB_UseTargets;
};

//=============================================================================
/*QUAKED trigger_secret (.5 .5 .5) ?
secret counter trigger
sounds
1)  secret
2)  beep beep
3)
4)
set "message" to text string
*/
void() trigger_secret =
{
	total_secrets = total_secrets + 1;
	self.wait = -1;
	//if (!self.message)
	self.message = "You found a secret!\n";
	/*if (!self.sounds)
		self.sounds = 1;

	if (self.sounds == 1)
	{
		precache_sound("bludbath/powerup.wav");
		self.noise = "bludbath/powerup.wav";
	}
	else if (self.sounds == 2)
		self.noise = "bludbath/message.wav";*/

	trigger_multiple();
};

//=============================================================================
void() counter_use =
{
	self.count = self.count - 1;
	if (self.count < 0)
		return;

	if (self.count != 0)
	{
		if (activator.classname == "player"
			&& (self.spawnflags & SPAWNFLAG_NOMESSAGE) == 0)
		{
			if (self.count >= 4)
				centerprint(activator, "There are more to go...");
			else if (self.count == 3)
				centerprint(activator, "Only 3 more to go...");
			else if (self.count == 2)
				centerprint(activator, "Only 2 more to go...");
			else
				centerprint(activator, "Only 1 more to go...");
		}
		return;
	}

	if (activator.classname == "player"
		&& (self.spawnflags & SPAWNFLAG_NOMESSAGE) == 0)
		centerprint(activator, "Sequence completed!");
	self.enemy = activator;
	multi_trigger();
};

// Acts as an intermediary for an action that takes multiple inputs.
// If nomessage is not set, t will print "1 more.. " etc when triggered and "sequence complete" when finished.
// After the counter has been triggered "count" times (default 2), it will fire all of it's targets and remove itself.
void() trigger_counter =
{
	self.wait = -1;
	if (!self.count)
		self.count = 2;

	self.use = counter_use;
};

/*
==============================================================================
TELEPORT TRIGGERS
==============================================================================
*/
void() play_teleport =
{
	local   float v;
	local   string tmpstr;

	v = random() * 5;
	if (v < 1)
		tmpstr = "misc/r_tele1.wav";
	else if (v < 2)
		tmpstr = "misc/r_tele2.wav";
	else if (v < 3)
		tmpstr = "misc/r_tele3.wav";
	else if (v < 4)
		tmpstr = "misc/r_tele4.wav";
	else
		tmpstr = "misc/r_tele5.wav";

	sound(self, CHAN_VOICE, tmpstr, 1, ATTN_NORM);
	remove(self);
};

void(vector org) spawn_tfog =
{
	local entity ent;

	ent = spawn();
	ent.origin = org;
	ent.nextthink = time + 0.2;
	ent.think = play_teleport;

	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TE_TELEPORT);
	WriteCoord(MSG_BROADCAST, org_x);
	WriteCoord(MSG_BROADCAST, org_y);
	WriteCoord(MSG_BROADCAST, org_z);
};

void() tdeath_touch =
{
	local entity other2;

	if (other == self.owner)
		return;

	// Frag anyone who teleports in on top of an invincible player
	if (other.classname == "player")
	{
		if (other.invincible_finished > time && self.owner.invincible_finished > time) {
			self.classname = "teledeath3";
			other.invincible_finished = 0;
			self.owner.invincible_finished = 0;
			T_Damage(other, self, self, 50000, DF_NO_PROTECT, string_null);
			other2 = self.owner;
			self.owner = other;
			T_Damage(other2, self, self, 50000, DF_NO_PROTECT, string_null);
		}

		if (other.invincible_finished > time)
		{
			self.classname = "teledeath2";
			T_Damage(self.owner, self, self, 50000, DF_NO_PROTECT, string_null);
			return;
		}

		if (self.owner.classname != "player")
		{
			// Other monsters explode themselves
			T_Damage(self.owner, self, self, 50000, DF_NO_PROTECT, string_null);
			return;
		}
	}

	if (other.health)
	{
		T_Damage(other, self, self, 50000, DF_NO_PROTECT, string_null);
	}
};

void(vector org, entity death_owner) spawn_tdeath =
{
	local entity    death;

	death = spawn();
	death.classname = "teledeath";
	death.movetype = MOVETYPE_NONE;
	death.solid = SOLID_TRIGGER;
	death.angles = '0 0 0';
	setsize(death, death_owner.mins - '1 1 1', death_owner.maxs + '1 1 1');
	setorigin(death, org);
	death.touch = tdeath_touch;
	death.nextthink = time + 0.2;
	death.think = SUB_Remove;
	death.owner = death_owner;

	force_retouch = 2;      // make sure even still objects get hit
};

void() teleport_touch =
{
	local entity    t;
	local vector    org;

	if (self.targetname)
	{
		if (self.nextthink < time)
		{
			return;     // not fired yet
		}
	}

	if (self.spawnflags & PLAYER_ONLY)
	{
		if (other.classname != "player")
			return;
	}

	// only teleport living creatures
	if (other.health <= 0 || other.solid != SOLID_SLIDEBOX)
		return;

	SUB_UseTargets();

	// put a tfog where the player was
	if (!(self.spawnflags & SILENT))
		spawn_tfog(other.origin);

	t = find(world, targetname, self.target);
	if (!t)
		objerror("couldn't find target");

	// spawn a tfog flash in front of the destination
	makevectors(t.mangle);
	org = t.origin + 32 * v_forward;

	if (!(self.spawnflags & SILENT))
		spawn_tfog(org);
	spawn_tdeath(t.origin, other);

	// move the player and lock him down for a little while
	if (!other.health)
	{
		other.origin = t.origin;
		other.velocity = (v_forward * other.velocity_x) + (v_forward * other.velocity_y);
		return;
	}

	setorigin(other, t.origin);
	other.angles = t.mangle;
	if (other.classname == "player")
	{
		other.fixangle = 1;     // turn this way immediately
		other.teleport_time = time + 0.7;
		if (other.flags & FL_ONGROUND)
			other.flags = other.flags - FL_ONGROUND;
		other.velocity = v_forward * 300;
	}
	other.flags = other.flags - other.flags & FL_ONGROUND;
};

// Destination marker for a teleporter
// It should have a "targetname" field with the same value as a teleporter's "target" field.
void() info_teleport_destination =
{
	// this does nothing, just serves as a target spot
	self.mangle = self.angles;
	self.angles = '0 0 0';
	self.model = string_null;
	self.origin = self.origin + '0 0 27';
	if (!self.targetname)
		objerror("no targetname");
};

void() teleport_use =
{
	self.nextthink = time + 0.2;
	force_retouch = 2;      // make sure even still objects get hit
	self.think = SUB_Null;
};

// Teleporter
// Any object touching this will be transported to the corresponding info_teleport_destination entity.
// You must set the "target" field, and create an object with a "targetname" field that matches.
// If the trigger_teleport has a targetname, it will only teleport entities when it has been fired.
void() trigger_teleport =
{
	local vector o;

	InitTrigger();
	self.touch = teleport_touch;

	// Find the destination
	if (!self.target)
		objerror("no target");
	self.use = teleport_use;

	if (!(self.spawnflags & SILENT))
	{
		precache_sound("ambience/amb17.wav");
		o = (self.mins + self.maxs)*0.5;
		ambientsound(o, "ambience/amb17.wav",0.5 , ATTN_STATIC);
	}
};

//============================================================================
void() hurt_on =
{
	self.solid = SOLID_TRIGGER;
	self.nextthink = -1;
};

void() hurt_touch =
{
	if (other.takedamage)
	{
		self.solid = SOLID_NOT;
		T_Damage(other, self, self, self.dmg, DF_PUMMEL, string_null);
		self.think = hurt_on;
		self.nextthink = time + 1;
	}

	return;
};

/*QUAKED trigger_hurt (.5 .5 .5) ?
Any object touching this will be hurt
set dmg to damage amount
defalt dmg = 5
*/
void() trigger_hurt =
{
	InitTrigger();
	self.touch = hurt_touch;
	if (!self.dmg)
		self.dmg = 5;
};

//============================================================================
void() trigger_push_touch =
{
	if (other.classname == "grenade")
		other.velocity = self.speed * self.movedir * 10;
	else if (other.health > 0)
	{
		other.velocity = self.speed * self.movedir * 10;
		if (other.classname == "player")
		{
			if (other.fly_sound < time)
			{
				other.fly_sound = time + 1.5;
				sound(other, CHAN_AUTO, "misc/qwindfly.wav", 1, ATTN_NORM);
			}
		}
	}
	if (self.spawnflags & PUSH_ONCE)
		remove(self);
};

/*QUAKED trigger_push (.5 .5 .5) ? PUSH_ONCE
Pushes the player
*/
void() trigger_push =
{
	InitTrigger();
	precache_sound("misc/qwindfly.wav");
	self.touch = trigger_push_touch;
	if (!self.speed)
		self.speed = 1000;
};

void( entity ent, float amount ) hurt_setdamage =
{
	ent.dmg = amount;
	if (!amount)
		ent.solid = SOLID_NOT;
	else
		ent.solid = SOLID_TRIGGER;

	ent.nextthink = -1;
};

/*QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player touches this, he gets sent to the map listed in the "map" variable.  Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
*/
void() trigger_changelevel =
{
	if (!self.map)
		objerror("changelevel trigger doesn't have map");

	InitTrigger();
	self.use = changelevel_use;	
};

// So player has to be touching trigger AND hitting the use button
void() trigger_use_touch =
{
	if (other.button4 && !other.oldbutton4)
		SUB_UseTargets();
	other.oldbutton4 = other.button4;

};

/*
    trigger_use
	while the player is in the trigger brush, if he presses the "use" button the target is triggered
*/
void() trigger_use =
{    
	if (!self.target)
		objerror("trigger_use doesn't have a target");

	InitTrigger();

	self.touch = trigger_use_touch;
};
