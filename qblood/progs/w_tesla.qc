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
#include "player.qh"

void() Tesla_Fire;
void() tesla_animate;

//============================================================================
// ----- Tesla Cannon models ----- //
// Normal model
$modelname v_tesla

#define TESLA_IDLE				0
#define TESLA_DRAW_START		1
#define TESLA_DRAW_END			5
#define TESLA_FIRE_START		6
#define TESLA_FIRE_END			10
#define TESLA_ALTFIRE_START		11
#define TESLA_ALTFIRE_END		50
#define TESLA_HOLSTER_START		51
#define TESLA_HOLSTER_END		55

#define TESLA_IDLE_TIME			0.1
#define TESLA_DRAW_TIME			0.4
#define	TESLA_FIRE_TIME			0.5
#define TESLA_ALTFIRE_TIME		2.1
#define TESLA_HOLSTER_TIME		0.4

$modelname ga_tesla

// ----- Player related code ----- //
// WARNING:
// the code assumes that the normal and akimbo models have the same frame layout

/*
============
Tesla_JoltTouch

Touch function for the tesla projectile
============
*/
void() Tesla_JoltTouch =
{
	// Don't explode on owner
	if (other == self.owner)
	return;

	// If we go out of the map
	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	// If we can damage the entity we touch
	if (other.takedamage)
		T_Damage (other, self, self.owner, self.dmg, DF_SHOCK, "tesla");

	// Alt-fire touch.
	if (self.style == TESLA_BIGJOLT)
	{
		T_RadiusDamage (self, self.owner, self.dmg / 2, DF_SHOCK, other, "tesla");

		self.origin = self.origin - 8 * normalize (self.velocity);
		sound (self, CHAN_AUTO, "weapons/tesla/tesaltht.wav", 1, ATTN_NORM);

		WriteByte  (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte  (MSG_BROADCAST, TE_EXPLOSION2);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
		WriteByte  (MSG_BROADCAST, 244);
		WriteByte  (MSG_BROADCAST, 3);
	}
	// Normal touch
	else
		sound (self, CHAN_AUTO, "weapons/tesla/tessnght.wav", 1, ATTN_NORM);

	remove (self);
};

/*
============
Tesla_LaunchJolt

Spawn the tesla projectile
============
*/
void(vector org, vector dir, float mspeed) Tesla_LaunchJolt =
{
	local entity jolt;

	jolt = spawn();

	jolt.owner = self;
	jolt.movetype = MOVETYPE_FLYMISSILE;
	jolt.solid = SOLID_BBOX;
	jolt.classname = "tesla ball";
	jolt.velocity = dir * mspeed;
	jolt.angles = vectoangles (jolt.velocity);
	if (self.player_state == PS_ALTFIRE)
	{
		jolt.dmg = 180;
		jolt.model = "models/weapons/objects/alttesla.md3";
		jolt.glow_color = 244;
		jolt.glow_size = 1;
		jolt.glow_trail = 1;
		jolt.style = TESLA_BIGJOLT;
		setorigin (jolt, org);
	}
	else
	{
		jolt.dmg = 24;
		jolt.model = "progs/teslaball.spr";
		jolt.style = TESLA_NORMALJOLT;
		jolt.effects = EF_ADDITIVE;
		jolt.alpha = 0.6;
		setorigin (jolt, org + '0 0 4');
	}
	jolt.touch = Tesla_JoltTouch;
	jolt.nextthink = time + (8000 / mspeed);
	jolt.think = SUB_Remove;
	jolt.reset = SUB_Remove;

	setmodel (jolt, jolt.model);
	setsize (jolt, '0 0 0', '0 0 0');
};

/*
============
Tesla_Fire

Shot with a tesla cannon
============
*/
void() Tesla_Fire =
{
	local   vector  org;
	local   vector  dir;
	local   float   mspeed;
	local   float   akimboFactor;  // 2 if guns akimbo, else 1

	if (self.items & IT_GUNS_AKIMBO)
		akimboFactor = 2;
	else
		akimboFactor = 1;

	// If we don't have enough ammo
	if (self.ammo_cells < akimboFactor)
		return;

	muzzleflash ();

	self.punchangle_x = -2;

	// If we want an altfire shot (we've already checked the ammo count in Tesla_Attack)
	if (self.player_state == PS_ALTFIRE)
	{
		// NOTE: we have already started the sound in "player_alttesla1"

		self.ammo_cells = self.ammo_cells - 35 * akimboFactor;
		mspeed = 2000;
	}
	else
	{
		sound (self, CHAN_WEAPON, "weapons/tesla/tessngfr.wav", 1, ATTN_NORM);

		self.ammo_cells = self.ammo_cells - akimboFactor;
		mspeed = 1500;
	}
	self.currentammo = self.ammo_cells;

	makevectors (self.v_angle);
	dir = aim(self, mspeed);
	org = self.origin + v_forward * 8 + '0 0 16';

	// Akimbo mode
	if (akimboFactor == 2)
	{
		Tesla_LaunchJolt (org + v_right * 14, dir, mspeed);
		Tesla_LaunchJolt (org - v_right * 14, dir, mspeed);

		// If we don't have enough ammo anymore, drop the akimbo mode for now
		if (self.ammo_cells < 2)
			W_SetCurrentAmmo ();
	}
	else if (self.player_state == PS_ALTFIRE)
		Tesla_LaunchJolt (org + v_right * 6.25 + v_forward * 24, dir, mspeed);
	else
		Tesla_LaunchJolt (org, dir, mspeed);
};

/*
============
Tesla_Attack

Attack code for the tesla cannon
============
*/
void() Tesla_Attack =
{
	if (self.button0 || self.ammo_cells < 35 || ((self.items & IT_GUNS_AKIMBO) && self.ammo_cells < 70))
	{
		self.player_state = PS_FIRE;
		self.attack_finished = time + TESLA_FIRE_TIME - 0.01;
		self.weapon_anim_type = "fire";
		tesla_animate();
	}
	else
	{
		self.player_state = PS_ALTFIRE;
		self.attack_finished = time + TESLA_ALTFIRE_TIME;
		self.weapon_anim_type = "altfire";
		if (self.items & IT_GUNS_AKIMBO)
			sound (self, CHAN_WEAPON, "weapons/tesla/tesakima.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_WEAPON, "weapons/tesla/tessuper.wav", 1, ATTN_NORM);
		tesla_animate();
	}
};

/*
============
Tesla_Draw

Draw code for the tesla cannon
============
*/
void() Tesla_Draw =
{
	self.weapon = IT_TESLA_CANNON;
	self.currentammo = self.ammo_cells;
	self.items = (self.items - (self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS))) | IT_CELLS;

	Tesla_UpdateView ();

	self.attack_finished = time + TESLA_DRAW_TIME;
	self.weapon_anim_type = "draw";
	tesla_animate ();
};

/*
============
Tesla_Holster

Holster code for the tesla cannon
============
*/
void() Tesla_Holster =
{
	self.attack_finished = time + TESLA_HOLSTER_TIME;
	self.weapon_anim_type = "holster";
	tesla_animate ();
};

/*
============
Tesla_UpdateView

Choose the right tesla cannon model to display
============
*/
void() Tesla_UpdateView =
{
	if (self.akimbo_finished > time && self.currentammo >= 2)
	{
		self.weaponmodel = "models/weapons/ga_tesla.md3";
		self.items = self.items | IT_GUNS_AKIMBO;
	}
	else
	{
		self.weaponmodel = "models/weapons/v_tesla.psk";
		self.items = self.items - (self.items & IT_GUNS_AKIMBO);
	}
};

void() Tesla_Idle =
{
	self.weapon_anim_type = "idle";
	self.player_state = PS_IDLE;
	self.weaponframe = TESLA_IDLE;
	tesla_animate();
	//player_run();
};

void () tesla_animate =
{
	if ((self.weapon_anim_type == self.weapon_last_action) && (self.weaponframe <= self.weapon_anim_end))
	{
		if (self.weaponframe != self.weapon_anim_end)
			self.weaponframe = self.weaponframe + 1; //if its a new animation type, it will be set to the proper frame next
		else
			self.weaponframe = self.weapon_anim_end - self.weapon_anim_end_num + 1;
	}
	if ((self.weapon_anim_type != self.weapon_last_action) || (self.weaponframe > self.weapon_anim_end))
	{
		if (self.weapon_anim_type == "idle")
		{
			self.weapon_anim_end = TESLA_IDLE;
			self.weapon_anim_end_num = TESLA_IDLE + 1;
			self.weapon_anim_time = TESLA_IDLE_TIME;
			self.weaponframe = TESLA_IDLE;
		}
		else if (self.weapon_anim_type == "draw")
		{
			self.weapon_anim_end = TESLA_DRAW_END;
			self.weapon_anim_end_num = TESLA_DRAW_END - TESLA_DRAW_START + 1;
			self.weapon_anim_time = TESLA_DRAW_TIME;
			self.weaponframe = TESLA_DRAW_START;
		}
		else if (self.weapon_anim_type == "fire")
		{
			self.weapon_anim_end = TESLA_FIRE_END;
			self.weapon_anim_end_num = TESLA_FIRE_END - TESLA_FIRE_START + 1;
			self.weapon_anim_time = TESLA_FIRE_TIME;
			self.weaponframe = TESLA_FIRE_START;
		}
		else if (self.weapon_anim_type == "altfire")
		{
			self.weapon_anim_end = TESLA_ALTFIRE_END;
			self.weapon_anim_end_num = TESLA_ALTFIRE_END - TESLA_ALTFIRE_START + 1;
			self.weapon_anim_time = TESLA_ALTFIRE_TIME;
			self.weaponframe = TESLA_ALTFIRE_START;
		}
		else if (self.weapon_anim_type == "holster")
		{
			self.weapon_anim_end = TESLA_HOLSTER_END;
			self.weapon_anim_end_num = TESLA_HOLSTER_END - TESLA_HOLSTER_START + 1;
			self.weapon_anim_time = TESLA_HOLSTER_TIME;
			self.weaponframe = TESLA_HOLSTER_START;
		}
		self.weapon_last_action = self.weapon_anim_type;
	}

	self.nextthink = time + (self.weapon_anim_time / self.weapon_anim_end_num);
	self.think = tesla_animate;

	if (self.weapon_anim_type == "fire")
	{
		if (self.frame == $attack1) //update player's 2 frame fire animation.
			self.frame = $attack2;
		else
			self.frame = $attack1;

		if (time > self.attack_finished)
		{
			// Check to see if we are supposed to stop shooting.
			if ((!self.button0 && !self.button3) || (intermission_running) || (self.ammo_cells < 1))
			{
				self.nextthink = time + 0.01;
				self.think = Tesla_Idle;
			}
			else
				Tesla_Fire();
		}
		else
		// Keep on firing...
		Tesla_Fire();
	}

	if (self.weapon_anim_type == "altfire")
	{
		if ((self.weaponframe == 11) || ((self.weaponframe > 42) && (self.weaponframe <= 48))) //update player's 2 frame fire animation.
			self.frame = $attack1;
		else
			self.frame = $attack2;

		if (self.weaponframe == 42)
			Tesla_Fire();
		else if (self.weaponframe == 50)
		{
			self.nextthink = time + TESLA_IDLE_TIME;
			self.think = Tesla_Idle;
		}
	}

	if ((self.weaponframe == self.weapon_anim_end) && (self.weapon_anim_type == "draw"))
	{
		Tesla_Idle();
	}
	if ((self.weaponframe == self.weapon_anim_end) && (self.weapon_anim_type == "holster"))
	{
		self.nextthink = time + 0.01;
		W_DrawWeapon (self.newweapon);
		self.think = player_run;
		return;
	}
	if (self.weapon_anim_type == "idle")
	{
		self.nextthink = time + TESLA_IDLE_TIME;
		self.think = Tesla_Idle;
	}
};