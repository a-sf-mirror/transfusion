/*  Copyright (C) 2001-2003  Mathieu Olivier

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

void() shotgun_animate;

#define SHOTGUN_IDLE					0
#define SHOTGUN_DRAW_START				1
#define SHOTGUN_DRAW_END				4
#define SHOTGUN_FIREL_START				5
#define SHOTGUN_FIREL_END				6
#define SHOTGUN_FIRER_START				7
#define SHOTGUN_FIRER_END				8
#define SHOTGUN_ALTFIRE_START			9
#define SHOTGUN_ALTFIRE_END				12
#define SHOTGUN_RELOAD_START			13
#define SHOTGUN_RELOAD_END				32
#define SHOTGUN_HOLSTER_START			33
#define SHOTGUN_HOLSTER_END				36
#define SHOTGUN_AKIMBO_IDLE             0
#define	SHOTGUN_AKIMBO_DRAW_START		1
#define	SHOTGUN_AKIMBO_DRAW_END 		4
#define	SHOTGUN_AKIMBO_FIRE_START		5
#define	SHOTGUN_AKIMBO_FIRE_END			10
#define	SHOTGUN_AKIMBO_ALTFIRE_START	11
#define	SHOTGUN_AKIMBO_ALTFIRE_END		14
#define	SHOTGUN_AKIMBO_HOLSTER_START	15
#define	SHOTGUN_AKIMBO_HOLSTER_END		18

#define SHOTGUN_IDLE_TIME				0.1
#define SHOTGUN_DRAW_TIME				0.3
#define SHOTGUN_FIRE_TIME				0.35
#define SHOTGUN_ALTFIRE_TIME			0.3
#define SHOTGUN_RELOAD_TIME				0.7
#define SHOTGUN_HOLSTER_TIME			0.3

//============================================================================

/*
================
Shot_SpawnShell

Spawns the shotgun shells if necessary
================
*/
void() Shotgun_SpawnShell =
{
	local entity shell;
	local entity shell2;

	// 1st shell
	shell = spawn();
	shell.owner = self;
	shell.solid = SOLID_NOT;
	shell.mdl   = "models/weapons/objects/shotgunshell.md3";
	shell.noise = "weapons/shtshl2.wav";

	setorigin(shell, W_Origin() + v_forward * 25);
	shell.velocity = (random() - 1) * v_forward * 30 + v_up * (160 + random() * 10) + v_right * (random() + 1) * 40;
	DropShell(shell);

	// 2nd shell
	shell2 = spawn();
	shell2.owner = self;
	shell2.solid = SOLID_NOT;
	shell2.mdl   = shell.mdl;
	shell2.noise = shell.noise;

	setorigin(shell2, shell.origin);
	shell2.velocity = (random() - 1) * v_forward * 30 + v_up * (160 + random() * 10) + v_right * (random() + 1) * 40;
	DropShell(shell2);

	sound(shell, CHAN_WEAPON, "weapons/shotgun/shotguncock.wav", 1, ATTN_NORM);
};

/*
================
Shotgun_Fire

Shot with the sawed-off
================
*/
void() Shotgun_Fire =
{
	local float nbshots;
	local vector dir, spread, orig;

	if (!self.owner.ammo_shells)
		return;

	if (self.owner.player_state == PS_ALTFIRE)
	{
		nbshots = 2;
		spread = '0.14 0.08 0';
	}
	else
	{
		nbshots = 1;
		spread = '0.1 0.03 0';
	}

	makevectors (self.owner.v_angle);

	self.owner.punchangle_x = -2 * nbshots;

	if (!(self.owner.flags & FL_INFINATE_AMMO))
		self.owner.currentammo = self.owner.ammo_shells = self.owner.ammo_shells - nbshots;

	if (nbshots == 1)
		sound(self.owner, CHAN_AUTO, "weapons/shotgun/shotgunfire.wav", 1, ATTN_NORM);
	else
		sound(self.owner ,CHAN_AUTO, "weapons/shotgun/shotgunfir2.wav", 1, ATTN_NORM);

	dir = aim(self.owner, 100000);

	orig = W_Origin();
	// Total damage from an alt-fire is about 3 times normal damage (1*8*8=64, 2*8*12=192)
	if (nbshots == 1)
		FireBullets(orig, dir, 8 * nbshots, 8, spread);  // 8 "shot pellets" per shell
	else if (nbshots == 2)
		FireBullets(orig, dir, 8 * nbshots, 12, spread);  // 8 "shot pellets" per shell
};

/*
============
Shotgun_Attack

Attack code for the sawed-off
============
*/
void() Shotgun_Attack =
{
	if (self.button3) // If it's an altfire shot
	{
		self.weaponentity.attack_finished = time + SHOTGUN_ALTFIRE_TIME;
		self.player_state = PS_ALTFIRE;
		self.weaponentity.anim_type = ALTFIRE;
	}
	else if (self.button0) // Regular fire
	{
		self.weaponentity.attack_finished = time + SHOTGUN_FIRE_TIME;
		self.player_state = PS_FIRE;
		self.weaponentity.anim_type = FIRE;
	}
	self.weaponentity.nextthink = time;
	self.weaponentity.think = shotgun_animate;
};

/*
============
Shot_Draw

Draw code for the sawed-off
============
*/
void() Shotgun_Draw =
{
	self.weapon = IT_SAWED_OFF;
	self.currentammo = self.ammo_shells;
	if (self.currentammo > 1)
		self.weaponentity.ammo_in_chamber = 2;
	else
		self.weaponentity.ammo_in_chamber = 1;
	Shotgun_UpdateView();
	self.weaponentity.attack_finished = time + SHOTGUN_DRAW_TIME;
	self.weaponentity.frame = SHOTGUN_DRAW_START;
	self.weaponentity.anim_type = DRAW;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = shotgun_animate;
};

/*
============
Shot_Holster

Holster code for the sawed-off
============
*/
void() Shotgun_Holster =
{
	self.weaponentity.attack_finished = time + SHOTGUN_HOLSTER_TIME;
	self.weaponentity.anim_type = HOLSTER;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = shotgun_animate;
};

/*
============
Shot_UpdateView

Choose the right sawed-off model to display
============
*/
void() Shotgun_UpdateView =
{
	if (self.akimbo_finished > time && self.currentammo >= 2)
	{
		setmodel(self.weaponentity, "models/weapons/ga_shotgun.psk");
		self.items = self.items | IT_GUNS_AKIMBO;
	}
	else
	{
		setmodel(self.weaponentity, "models/weapons/v_shotgun.psk");
		self.items = self.items - (self.items & IT_GUNS_AKIMBO);
	}
};

void() Shotgun_Idle =
{
	self.weaponentity.anim_type = IDLE;
	self.owner.player_state = PS_IDLE;
	self.weaponentity.frame = SHOTGUN_IDLE;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = shotgun_animate;
};

/*
============
shotgun_animate

Animation and frame based code for the Sawed-Off Shotgun
============
*/
void() shotgun_animate =
{
	if (self.weaponentity.anim_type == self.weaponentity.last_action)
	{
		if (self.weaponentity.frame < self.weaponentity.anim_end)
		{
			if (self.weaponentity.anim_end_num / self.weaponentity.anim_time > 1 / frametime)
				self.weaponentity.frame = self.weaponentity.frame + ((self.weaponentity.anim_end_num / self.weaponentity.anim_time) / (1 / frametime));
				/*This is a skip-frame system if all animation frames cannot be squeezed into the current sys_ticrate.
				Such animations should only rely on == START or >= END */
			else
			self.weaponentity.frame = self.weaponentity.frame + 1; //if its a new animation type, it will be set to the proper frame next
		}
		else if (self.weaponentity.anim_type != RELOAD)
			self.weaponentity.frame = self.weaponentity.anim_end - self.weaponentity.anim_end_num + 1;
	}
	else
	{
		if (self.weaponentity.anim_type == IDLE)
		{
			self.weaponentity.anim_end = SHOTGUN_IDLE;
			self.weaponentity.anim_end_num = SHOTGUN_IDLE + 1;
			self.weaponentity.anim_time = SHOTGUN_IDLE_TIME;
			self.weaponentity.frame = SHOTGUN_IDLE;
		}
		else if (self.weaponentity.anim_type == DRAW)
		{
			self.weaponentity.anim_end = SHOTGUN_DRAW_END;
			self.weaponentity.anim_end_num = SHOTGUN_DRAW_END - SHOTGUN_DRAW_START + 1;
			self.weaponentity.anim_time = SHOTGUN_DRAW_TIME;
			self.weaponentity.frame = SHOTGUN_DRAW_START;
		}
		else if (self.weaponentity.anim_type == FIRE)
		{
			if (self.weaponentity.ammo_in_chamber == 2)
			{
				self.weaponentity.anim_end = SHOTGUN_FIREL_END;
				self.weaponentity.anim_end_num = SHOTGUN_FIREL_END - SHOTGUN_FIREL_START + 1;
				self.weaponentity.anim_time = SHOTGUN_FIRE_TIME;
				self.weaponentity.frame = SHOTGUN_FIREL_START;
			}
			else if (self.weaponentity.ammo_in_chamber == 1)
			{
				self.weaponentity.anim_end = SHOTGUN_FIRER_END;
				self.weaponentity.anim_end_num = SHOTGUN_FIRER_END - SHOTGUN_FIRER_START + 1;
				self.weaponentity.anim_time = SHOTGUN_FIRE_TIME;
				self.weaponentity.frame = SHOTGUN_FIRER_START;
			}
		}
		else if (self.weaponentity.anim_type == ALTFIRE)
		{
			self.weaponentity.anim_end = SHOTGUN_ALTFIRE_END;
			self.weaponentity.anim_end_num = SHOTGUN_ALTFIRE_END - SHOTGUN_ALTFIRE_START + 1;
			self.weaponentity.anim_time = SHOTGUN_ALTFIRE_TIME;
			self.weaponentity.frame = SHOTGUN_ALTFIRE_START;
		}
		else if (self.weaponentity.anim_type == RELOAD)
		{
			self.weaponentity.anim_end = SHOTGUN_RELOAD_END;
			self.weaponentity.anim_end_num = SHOTGUN_RELOAD_END - SHOTGUN_RELOAD_START + 1;
			self.weaponentity.anim_time = SHOTGUN_RELOAD_TIME;
			self.weaponentity.frame = SHOTGUN_RELOAD_START;
		}
		else if (self.weaponentity.anim_type == HOLSTER)
		{
			if (self.weaponentity.last_action == DRAW)
			{
				self.weaponentity.anim_end = SHOTGUN_HOLSTER_END;
				self.weaponentity.anim_end_num = SHOTGUN_HOLSTER_END - SHOTGUN_HOLSTER_START + 1;
				self.weaponentity.anim_time = (SHOTGUN_HOLSTER_TIME / (SHOTGUN_HOLSTER_END - SHOTGUN_HOLSTER_START + 1)) * (self.weaponentity.frame - SHOTGUN_DRAW_START + 1);
				self.weaponentity.attack_finished = time + self.weaponentity.anim_time;
				self.weaponentity.frame = SHOTGUN_HOLSTER_END - (self.weaponentity.frame - SHOTGUN_DRAW_START + 1) + 1;
			}
			else
			{
				self.weaponentity.anim_end = SHOTGUN_HOLSTER_END;
				self.weaponentity.anim_end_num = SHOTGUN_HOLSTER_END - SHOTGUN_HOLSTER_START + 1;
				self.weaponentity.anim_time = SHOTGUN_HOLSTER_TIME;
				self.weaponentity.frame = SHOTGUN_HOLSTER_START;
			}
		}
		self.weaponentity.last_action = self.weaponentity.anim_type;
	}
	if (self.weaponentity.anim_type != IDLE)
	{
		self.weaponentity.nextthink = time + (self.weaponentity.anim_time / self.weaponentity.anim_end_num);
		self.weaponentity.think = shotgun_animate;
	}

	if (self.weaponentity.anim_type == FIRE)
	{
		if ((self.weaponentity.frame == SHOTGUN_FIRER_START) || (self.weaponentity.frame == SHOTGUN_FIREL_START))
		{
			muzzleflash();
			Shotgun_Fire();
			self.weaponentity.ammo_in_chamber = self.weaponentity.ammo_in_chamber - 1;
			if (self.items & IT_GUNS_AKIMBO)
				Shotgun_Fire();
		}
		else if ((self.weaponentity.frame == SHOTGUN_FIRER_END) || (self.weaponentity.frame == SHOTGUN_FIREL_END))
		{
			if (self.weaponentity.ammo_in_chamber <= 0)
			{
				self.weaponentity.anim_type = RELOAD;
				self.weaponentity.attack_finished = time + SHOTGUN_RELOAD_TIME;
				shotgun_animate();
			}
			else
				Shotgun_Idle();
		}
	}
	else if (self.weaponentity.anim_type == ALTFIRE)
	{
		if (self.weaponentity.frame == SHOTGUN_ALTFIRE_START)
		{
			if (self.weaponentity.ammo_in_chamber < 2)
				self.player_state = PS_FIRE;
			muzzleflash();
			Shotgun_Fire();
			self.weaponentity.ammo_in_chamber = self.weaponentity.ammo_in_chamber - self.owner.player_state;
			if (self.owner.items & IT_GUNS_AKIMBO)
				Shotgun_Fire();
		}
		else if (self.weaponentity.frame == SHOTGUN_ALTFIRE_END)
		{
			self.weaponentity.anim_type = RELOAD;
			self.weaponentity.attack_finished = time + SHOTGUN_RELOAD_TIME;
			shotgun_animate();
		}
	}
	else if (self.weaponentity.anim_type == RELOAD)
	{
		if ((ceil(self.weaponentity.frame) == SHOTGUN_RELOAD_START + 3) || (floor(self.weaponentity.frame) == SHOTGUN_RELOAD_START + 3))
			Shotgun_SpawnShell();
		if (self.weaponentity.frame >= SHOTGUN_RELOAD_END)
		{
			self.weaponentity.ammo_in_chamber = 2;
			self.weaponentity.think = Shotgun_Idle;
		}
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && (self.weaponentity.anim_type == DRAW))
	{
		self.weaponentity.nextthink = time;
		self.weaponentity.think = Shotgun_Idle;
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && (self.weaponentity.anim_type == HOLSTER))
	{
		setmodel(self.weaponentity, "");
		W_DrawWeapon(self.owner.newweapon);
		return;
	}
};