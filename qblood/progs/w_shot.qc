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

void() Shotgun_Fire;
void() Shotgun_SpawnShell;
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

#define	SHOTGUN_AKIMBO_FIRE_START		4
#define	SHOTGUN_AKIMBO_FIRE_END			6
#define	SHOTGUN_AKIMBO_ALTFIRE_START	7
#define	SHOTGUN_AKIMBO_ALTFIRE_END		10

// times may need adjusting
#define SHOTGUN_IDLE_TIME				0.01
#define SHOTGUN_DRAW_TIME				0.4
#define SHOTGUN_FIRE_TIME				0.2
#define SHOTGUN_ALTFIRE_TIME			0.34
#define SHOTGUN_RELOAD_TIME				0.6
#define SHOTGUN_HOLSTER_TIME			0.4

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
	shell = spawn ();
	shell.owner = self;
	shell.mdl   = "models/weapons/objects/shotshell.md3";
	shell.noise = "weapons/shtshl2.wav";

	setorigin (shell, self.origin + v_forward * 15);
	shell.velocity = (crandom () + 1) * v_forward * 30 + v_up * (220 + crandom () * 10) - v_right * crandom () * 30;
	DropShell (shell);

	// 2nd shell
	shell2 = spawn ();
	shell2.owner = self;
	shell2.mdl   = shell.mdl;
	shell2.noise = shell.noise;

	setorigin (shell2, shell.origin);
	shell2.velocity = (crandom () + 1) * v_forward * 30 + v_up * (220 + crandom () * 10) - v_right * crandom () * 30;
	DropShell (shell2);

	sound (shell, CHAN_WEAPON, "weapons/shotgun/shotcock.wav", 1, ATTN_NORM);
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
	local vector dir;
	local vector spread;

	if (! self.ammo_shells)
		return;

	if (self.player_state == PS_ALTFIRE)
	{
		nbshots = 2;
		spread = '0.14 0.08 0';
	}
	else
	{
		nbshots = 1;
		spread = '0.1 0.03 0';
	}

	makevectors (self.v_angle);

	self.punchangle_x = -2 * nbshots;

	self.currentammo = self.ammo_shells = self.ammo_shells - nbshots;

	if (nbshots == 1)
		sound (self, CHAN_AUTO, "weapons/shotgun/shotfire.wav", 1, ATTN_NORM);
	else
		sound (self ,CHAN_AUTO, "weapons/shotgun/shotfir2.wav", 1, ATTN_NORM);

	dir = aim (self, 100000);

	// Total damage from an alt-fire is about 3 times normal damage (1*8*8=64, 2*8*12=192)
	if (nbshots == 1)
	{
		FireBullets (self.origin + v_up * 20, dir, 8 * nbshots, 8, spread);  // 8 "shot pellets" per shell
	}
	else if (nbshots == 2)
	{
		FireBullets (self.origin + v_up * 20, dir, 8 * nbshots, 12, spread);  // 8 "shot pellets" per shell
	}
};

/*
============
Shotgun_Attack

Attack code for the sawed-off
============
*/
void() Shotgun_Attack =
{
	if (self.attack_finished < time)
	{
	// If it's an altfire shot
	if (self.button3)
	{
		self.attack_finished = time + SHOTGUN_ALTFIRE_TIME;
		self.player_state = PS_ALTFIRE;
		self.weapon_anim_type = "altfire";
	}
	else
	{
		self.attack_finished = time + SHOTGUN_FIRE_TIME;
		self.player_state = PS_FIRE;
		self.weapon_anim_type = "fire";
	}

	shotgun_animate();
	}
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
	self.items = (self.items - (self.items & (IT_NAILS | IT_CELLS | IT_ROCKETS))) | IT_SHELLS;

	if (self.currentammo > 1)
		self.shotgun_loaded_ammo = 2;
	else
		self.shotgun_loaded_ammo = 1;

	Shotgun_UpdateView ();

	self.attack_finished = time + 0.3;

	self.weapon_anim_type = "draw";
	self.weaponframe == SHOTGUN_DRAW_START;
	shotgun_animate();
};

/*
============
Shot_Holster

Holster code for the sawed-off
============
*/
void() Shotgun_Holster =
{
	self.attack_finished = time + 0.3;
	self.weapon_anim_type = "holster";
	shotgun_animate();
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
		self.weaponmodel = "models/weapons/ga_shot.md3";
		self.items = self.items | IT_GUNS_AKIMBO;
	}
	else
	{
		self.weaponmodel = "models/weapons/v_shot.psk";
		self.items = self.items - (self.items & IT_GUNS_AKIMBO);
	}
};

void() Shotgun_Idle =
{
	self.weapon_anim_type = "idle";
	self.player_state = PS_IDLE;
	self.weaponframe = SHOTGUN_IDLE;
	shotgun_animate();
};

void () shotgun_animate =
{
	if (self.weapon_anim_type == self.weapon_last_action)
	{
		if (self.weaponframe < self.weapon_anim_end)
			self.weaponframe = self.weaponframe + 1; //if its a new animation type, it will be set to the proper frame next
		else if (self.weapon_anim_type != "reload")
			self.weaponframe = self.weapon_anim_end - self.weapon_anim_end_num + 1;
	}
	else
	{
		if (self.weapon_anim_type == "idle")
		{
			self.weapon_anim_end = SHOTGUN_IDLE;
			self.weapon_anim_end_num = SHOTGUN_IDLE + 1;
			self.weapon_anim_time = SHOTGUN_IDLE_TIME;
			self.weaponframe = SHOTGUN_IDLE;
		}
		else if (self.weapon_anim_type == "draw")
		{
			self.weapon_anim_end = SHOTGUN_DRAW_END;
			self.weapon_anim_end_num = SHOTGUN_DRAW_END - SHOTGUN_DRAW_START + 1;
			self.weapon_anim_time = SHOTGUN_DRAW_TIME;
			self.weaponframe = SHOTGUN_DRAW_START;
		}
		else if (self.weapon_anim_type == "fire")
		{
			if (self.shotgun_loaded_ammo == 2)
			{
				self.weapon_anim_end = SHOTGUN_FIREL_END;
				self.weapon_anim_end_num = SHOTGUN_FIREL_END - SHOTGUN_FIREL_START + 1;
				self.weapon_anim_time = SHOTGUN_FIRE_TIME;
				self.weaponframe = SHOTGUN_FIREL_START;
			}
			else if (self.shotgun_loaded_ammo == 1)
			{
				self.weapon_anim_end = SHOTGUN_FIRER_END;
				self.weapon_anim_end_num = SHOTGUN_FIRER_END - SHOTGUN_FIRER_START + 1;
				self.weapon_anim_time = SHOTGUN_FIRE_TIME;
				self.weaponframe = SHOTGUN_FIRER_START;
			}
		}
		else if (self.weapon_anim_type == "altfire")
		{
			self.weapon_anim_end = SHOTGUN_ALTFIRE_END;
			self.weapon_anim_end_num = SHOTGUN_ALTFIRE_END - SHOTGUN_ALTFIRE_START + 1;
			self.weapon_anim_time = SHOTGUN_ALTFIRE_TIME;
			self.weaponframe = SHOTGUN_ALTFIRE_START;
		}
		else if (self.weapon_anim_type == "reload")
		{
			self.weapon_anim_end = SHOTGUN_RELOAD_END;
			self.weapon_anim_end_num = SHOTGUN_RELOAD_END - SHOTGUN_RELOAD_START + 1;
			self.weapon_anim_time = SHOTGUN_RELOAD_TIME;
			self.weaponframe = SHOTGUN_RELOAD_START;
		}
		else if (self.weapon_anim_type == "holster")
		{
			self.weapon_anim_end = SHOTGUN_HOLSTER_END;
			self.weapon_anim_end_num = SHOTGUN_HOLSTER_END - SHOTGUN_HOLSTER_START + 1;
			self.weapon_anim_time = SHOTGUN_HOLSTER_TIME;
			self.weaponframe = SHOTGUN_HOLSTER_START;
		}
		self.weapon_last_action = self.weapon_anim_type;
	}

	self.nextthink = time + (self.weapon_anim_time / self.weapon_anim_end_num);
	self.think = shotgun_animate;

	if (self.weapon_anim_type == "idle")
	{
		self.nextthink = time + SHOTGUN_IDLE_TIME;
		self.think = Shotgun_Idle;
	}
	else if (self.weapon_anim_type == "fire")
	{
		if ((self.weaponframe == SHOTGUN_FIRER_START) || (self.weaponframe == SHOTGUN_FIREL_START))
		{
			muzzleflash();
			Shotgun_Fire ();
			self.shotgun_loaded_ammo = self.shotgun_loaded_ammo - 1;
			if (self.items & IT_GUNS_AKIMBO)
				Shotgun_Fire ();
		}
		if ((self.weaponframe == SHOTGUN_FIRER_END) || (self.weaponframe == SHOTGUN_FIREL_END))
		{
			Shotgun_UpdateView();
			if (self.shotgun_loaded_ammo <= 0)
			{
				self.weapon_anim_type = "reload";
				self.attack_finished = time + SHOTGUN_RELOAD_TIME;
				shotgun_animate();
			}
			else if (!self.button0)
				Shotgun_Idle();
		}
	}
	else if (self.weapon_anim_type == "altfire")
	{
		if (self.weaponframe == SHOTGUN_ALTFIRE_START)
		{
			if (self.shotgun_loaded_ammo < 2)
				self.player_state = PS_FIRE;
			muzzleflash ();
			Shotgun_Fire ();
			self.shotgun_loaded_ammo = self.shotgun_loaded_ammo - 2;
			if (self.items & IT_GUNS_AKIMBO)
				Shotgun_Fire ();
		}
		else if (self.weaponframe == SHOTGUN_ALTFIRE_END)
		{
			Shotgun_UpdateView();
			if (self.shotgun_loaded_ammo <= 0)
			{
				self.weapon_anim_type = "reload";
				self.attack_finished = time + SHOTGUN_RELOAD_TIME;
				shotgun_animate();
			}
			else if (!self.button3)
				Shotgun_Idle();
		}
	}
	else if (self.weapon_anim_type == "reload")
	{
		if (self.weaponframe == SHOTGUN_RELOAD_START + 11)
			Shotgun_SpawnShell ();
		if ((self.weaponframe == SHOTGUN_RELOAD_END) && ((!self.button0) || (!self.button3)))
		{
			self.shotgun_loaded_ammo = 2;
			Shotgun_Idle();
		}
		

	}
	else if ((self.weaponframe == self.weapon_anim_end) && (self.weapon_anim_type == "draw"))
	{
		self.nextthink = time + SHOTGUN_IDLE_TIME;
		self.think = Shotgun_Idle;
	}
	else if ((self.weaponframe == self.weapon_anim_end) && (self.weapon_anim_type == "holster"))
	{
		self.nextthink = time + SHOTGUN_IDLE_TIME;
		W_DrawWeapon (self.newweapon);
		self.think = player_run;
		return;
	}

};