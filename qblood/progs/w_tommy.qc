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

void() tommy_animate;

#define TOMMY_IDLE				0
#define TOMMY_DRAW_START		1
#define TOMMY_DRAW_END			4
#define TOMMY_FIRE_START		5
#define TOMMY_FIRE_END			6
#define TOMMY_ALTFIRE_START		7
#define TOMMY_ALTFIRE_END		20
#define TOMMY_HOLSTER_START		21
#define TOMMY_HOLSTER_END		24

#define TOMMY_IDLE_TIME			0.1
#define TOMMY_DRAW_TIME			0.3
#define TOMMY_FIRE_TIME			0.064
#define TOMMY_ALTFIRE_TIME		1.0
#define TOMMY_HOLSTER_TIME		0.3

//============================================================================

/*
================
Tommy_SpawnShell

Spawns new shell entity but doesn't display it until reloadtime
================
*/
void(float hand) Tommy_SpawnShell =
{
	local entity shell;

	shell = spawn();
	shell.owner = self.owner;

	shell.mdl = "models/weapons/objects/bulletshell.md3";
	if (random() < 0.5)
		shell.noise = "weapons/shtshl.wav";
	else
		shell.noise = "weapons/shtshl3.wav";

	if (self.owner.player_state == PS_FIRE)
	{
		if (hand == RIGHT && self.owner.items & IT_GUNS_AKIMBO)
		{
			setorigin(shell, W_Origin() + v_forward * 15 + v_right * 8);
			shell.velocity = (crandom() + 1)*v_forward*40 + v_right*(80 + crandom()*10) + v_up*(110 + crandom()*10);
		}
		else if (hand == RIGHT)
		{
			setorigin(shell, W_Origin() + v_forward * 15 + v_right * -1);
			shell.velocity = (crandom() + 1)*v_forward*40 - v_right*(80 + crandom()*10) + v_up*(110 + crandom()*10);
		}
		else if (hand == LEFT)
		{
			setorigin(shell, W_Origin() + v_forward * 15 + v_right * -8);
			shell.velocity = (crandom() + 1)*v_forward*40 - v_right*(80 + crandom()*10) + v_up*(110 + crandom()*10);
		}
	}
	else //altfire
	{
		if (self.owner.items & IT_GUNS_AKIMBO)
		{
			if (hand == RIGHT)
			{
				setorigin(shell, W_Origin() + v_forward * 15 + v_right * (6 + crandom() * 2));
				if (crandom() > 0)
					shell.velocity = (crandom() + 1)*v_forward*40 - v_right*(65 + crandom()*10) + v_up*(75 + crandom()*10);
				else
					shell.velocity = (crandom() + 1)*v_forward*40 + v_right*(65 + crandom()*10) + v_up*(75 + crandom()*10);
			}
			else
			{
				setorigin(shell, W_Origin() + v_forward * 15 - v_right * (6 + crandom() * 2));
				if (crandom() > 0)
					shell.velocity = (crandom() + 1)*v_forward*40 - v_right*(65 + crandom()*10) + v_up*(75 + crandom()*10);
				else
					shell.velocity = (crandom() + 1)*v_forward*40 + v_right*(65 + crandom()*10) + v_up*(75 + crandom()*10);
			}
		}
		else
		{
			setorigin(shell, W_Origin() + v_forward * 15 + v_right * (crandom() * 2));
			if (crandom() > 0)
				shell.velocity = (crandom() + 1)*v_forward*40 - v_right*(65 + crandom()*10) + v_up*(75 + crandom()*10);
			else
				shell.velocity = (crandom() + 1)*v_forward*40 + v_right*(65 + crandom()*10) + v_up*(75 + crandom()*10);
		}
	}

	DropShell(shell);
};

/*
============
Tommy_Fire

Fire with the tommygun
============
*/
void() Tommy_Fire =
{
	local vector    dir;
	local vector    orig;
	local vector    spread;
	local float     damage;

	makevectors(self.owner.v_angle);

	sound(self.owner, CHAN_WEAPON, "weapons/tommygun/_tom.wav", 1, ATTN_NORM);
	if (!(self.owner.flags & FL_INFINATE_AMMO))
	{
		if (self.owner.items & IT_GUNS_AKIMBO)
			self.owner.currentammo = self.owner.ammo_nails = self.owner.ammo_nails - 2;
		else
			self.owner.currentammo = self.owner.ammo_nails = self.owner.ammo_nails - 1;
	}

	/* Set the bullet direction according to the weapon's real direction.
	   These are arbitrary values with a small bit of further horizontal spread. */
	dir = aim(self.owner, 1000);
	if (self.weaponentity.frame == TOMMY_ALTFIRE_START || self.weaponentity.frame == TOMMY_ALTFIRE_START + 6)
		dir = dir - v_right * (1/28);
	if (self.weaponentity.frame == TOMMY_ALTFIRE_START + 1 || self.weaponentity.frame == TOMMY_ALTFIRE_START + 5)
		dir = dir - v_right * (1/18);
	if (self.weaponentity.frame == TOMMY_ALTFIRE_START + 2 || self.weaponentity.frame == TOMMY_ALTFIRE_START + 4)
		dir = dir - v_right * (1/10);
	if (self.weaponentity.frame == TOMMY_ALTFIRE_START + 3)
		dir = dir - v_right * (1/6.5);
	if (self.weaponentity.frame == TOMMY_ALTFIRE_START + 7 || self.weaponentity.frame == TOMMY_ALTFIRE_START + 13)
		dir = dir + v_right * (1/28);
	if (self.weaponentity.frame == TOMMY_ALTFIRE_START + 8 || self.weaponentity.frame == TOMMY_ALTFIRE_START + 12)
		dir = dir + v_right * (1/18);
	if (self.weaponentity.frame == TOMMY_ALTFIRE_START + 9 || self.weaponentity.frame == TOMMY_ALTFIRE_START + 11)
		dir = dir + v_right * (1/10);
	if (self.weaponentity.frame == TOMMY_ALTFIRE_START + 10)
		dir = dir + v_right * (1/6.5);

	// If we are in altfire mode
	if (self.owner.player_state == PS_ALTFIRE)
	{
		damage = 20;
		spread = '0.03 0.001 0';
	}
	else
	{
		damage = 12;
		spread = '0.05 0.02 0';
	}

	if (self.owner.items & IT_GUNS_AKIMBO)
	{
		// Spawn 1 shell alternatively for each gun
		Tommy_SpawnShell(RIGHT);
		Tommy_SpawnShell(LEFT);

		orig = W_Origin() + v_right * 4;
		FireBullets(orig, dir, 1, damage, spread);
		muzzleflash(RIGHT);
		orig = W_Origin() - v_right * 4;
		FireBullets(orig, dir, 1, damage, spread);
		muzzleflash(LEFT);

		// If we don't have enough ammo anymore, drop the akimbo mode for now
		if (self.owner.currentammo < 2)
			W_SetCurrentAmmo();
	}
	else
	{
		Tommy_SpawnShell(RIGHT);
		orig = W_Origin() + v_right * 4;
		FireBullets(orig, dir, 1, damage, spread);
		muzzleflash(RIGHT);
	}
};

/*
============
Tommy_Attack

Attack code for the tommygun
============
*/
void() Tommy_Attack =
{
	// If it's a tommy gun altfire start and if we have enough ammo
	if (self.button3)
	{
		if (self.weaponentity.attack_finished < time)
		{
			self.player_state = PS_ALTFIRE;
			self.weaponentity.anim_type = ALTFIRE;
			self.weaponentity.attack_finished = time + TOMMY_ALTFIRE_TIME;
		}
	}
	else
	{
		self.player_state = PS_FIRE;
		self.weaponentity.anim_type = FIRE;
		self.weaponentity.attack_finished = time + TOMMY_FIRE_TIME;
	}
	self.weaponentity.nextthink = time;
	self.weaponentity.think = tommy_animate;
};

/*
============
Tommy_Draw

Draw code for the tommygun
============
*/
void() Tommy_Draw =
{
	self.weapon = IT_TOMMYGUN;
	self.currentammo = self.ammo_nails;
	Tommy_UpdateView();
	self.weaponentity.attack_finished = time + TOMMY_DRAW_TIME;
	self.weaponentity.frame = TOMMY_DRAW_START;
	self.weaponentity.skin = 0;
	self.weaponentity.anim_type = DRAW;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = tommy_animate;
};

/*
============
Tommy_Holster

Holster code for the tommygun
============
*/
void() Tommy_Holster =
{
	self.weaponentity.attack_finished = time + TOMMY_HOLSTER_TIME;
	self.weaponentity.anim_type = HOLSTER;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = tommy_animate;
};

/*
============
Tommy_UpdateView

Choose the right tommygun model to display
============
*/
void() Tommy_UpdateView =
{
	if (self.akimbo_finished > time && self.currentammo >= 2)
	{
		setmodel(self.weaponentity, "models/weapons/ga_tommy.psk");
		self.items = self.items | IT_GUNS_AKIMBO;
	}
	else
	{
		setmodel(self.weaponentity, "models/weapons/v_tommy.psk");
		self.items = self.items - (self.items & IT_GUNS_AKIMBO);
	}
};

void() Tommy_Idle =
{
	self.owner.player_state = PS_IDLE;
	self.weaponentity.anim_type = IDLE;
	self.weaponentity.frame = TOMMY_IDLE;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = tommy_animate;
};

void() tommy_animate =
{
	if (self.weaponentity.anim_type == self.weaponentity.last_action)
	{
		if (self.weaponentity.frame < self.weaponentity.anim_end)
			self.weaponentity.frame = self.weaponentity.frame + 1; //if its a new animation type, it will be set to the proper frame next
		else
			self.weaponentity.frame = self.weaponentity.anim_end - self.weaponentity.anim_end_num + 1;
	}
	else
	{
		if (self.weaponentity.anim_type == IDLE)
		{
			self.weaponentity.anim_end = TOMMY_IDLE;
			self.weaponentity.anim_end_num = TOMMY_IDLE + 1;
			self.weaponentity.anim_time = TOMMY_IDLE_TIME;
			self.weaponentity.frame = TOMMY_IDLE;
		}
		else if (self.weaponentity.anim_type == DRAW)
		{
			self.weaponentity.anim_end = TOMMY_DRAW_END;
			self.weaponentity.anim_end_num = TOMMY_DRAW_END - TOMMY_DRAW_START + 1;
			self.weaponentity.anim_time = TOMMY_DRAW_TIME;
			self.weaponentity.frame = TOMMY_DRAW_START;
		}
		else if (self.weaponentity.anim_type == FIRE)
		{
			self.weaponentity.anim_end = TOMMY_FIRE_END;
			self.weaponentity.anim_end_num = TOMMY_FIRE_END - TOMMY_FIRE_START + 1;
			self.weaponentity.anim_time = TOMMY_FIRE_TIME;
			self.weaponentity.frame = TOMMY_FIRE_START;
		}
		else if (self.weaponentity.anim_type == ALTFIRE)
		{
			self.weaponentity.anim_end = TOMMY_ALTFIRE_END;
			self.weaponentity.anim_end_num = TOMMY_ALTFIRE_END - TOMMY_ALTFIRE_START + 1;
			self.weaponentity.anim_time = TOMMY_ALTFIRE_TIME;
			self.weaponentity.frame = TOMMY_ALTFIRE_START;
		}
		else if (self.weaponentity.anim_type == HOLSTER)
		{
			if (self.weaponentity.last_action == DRAW)
			{
				self.weaponentity.anim_end = TOMMY_HOLSTER_END;
				self.weaponentity.anim_end_num = TOMMY_HOLSTER_END - TOMMY_HOLSTER_START + 1;
				self.weaponentity.anim_time = (TOMMY_HOLSTER_TIME / (TOMMY_HOLSTER_END - TOMMY_HOLSTER_START + 1)) * (self.weaponentity.frame - TOMMY_DRAW_START + 1);
				self.weaponentity.attack_finished = time + self.weaponentity.anim_time;
				self.weaponentity.frame = TOMMY_HOLSTER_END - (self.weaponentity.frame - TOMMY_DRAW_START + 1) + 1;
			}
			else
			{
				self.weaponentity.anim_end = TOMMY_HOLSTER_END;
				self.weaponentity.anim_end_num = TOMMY_HOLSTER_END - TOMMY_HOLSTER_START + 1;
				self.weaponentity.anim_time = TOMMY_HOLSTER_TIME;
				self.weaponentity.frame = TOMMY_HOLSTER_START;
			}
		}
		self.weaponentity.last_action = self.weaponentity.anim_type;
	}
	if (self.weaponentity.anim_type != IDLE)
	{
		self.weaponentity.nextthink = time + (self.weaponentity.anim_time / self.weaponentity.anim_end_num);
		self.weaponentity.think = tommy_animate;
	}

	if (self.owner.player_state == PS_FIRE || self.owner.player_state == PS_ALTFIRE)
	{
		if (self.weaponentity.frame / 2 == floor(self.weaponentity.frame / 2))
			self.weaponentity.origin = '0 0 0';
		else
		{
			local float displacement;
			displacement = crandom() / 1.5;
			self.weaponentity.origin = '0 0 0' + v_forward * (displacement * 1.5) + v_up * (displacement * 2.25) - v_right * displacement;
		}
	}

	if (self.weaponentity.anim_type == FIRE)
	{
		if (!self.owner.button0 && self.weaponentity.attack_finished <= time)
			Tommy_Idle();
		if (self.weaponentity.frame == TOMMY_FIRE_START)
			Tommy_Fire();
		else
			Tommy_Idle();
	}
	else if (self.weaponentity.anim_type == ALTFIRE)
	{
		if (!self.owner.button3 && self.weaponentity.frame == TOMMY_ALTFIRE_END)
		{
			self.owner.player_state = PS_IDLE;
			Tommy_Idle();
		}
		else if (self.weaponentity.frame == TOMMY_ALTFIRE_END)
			self.weaponentity.attack_finished = time + TOMMY_ALTFIRE_TIME;
		Tommy_Fire();
		self.owner.impulse = IMP_NONE;
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && ((self.weaponentity.anim_type == DRAW) || (self.weaponentity.anim_type == AKIMBO_DRAW)))
	{
		self.owner.player_state = PS_IDLE;
		Tommy_Idle();
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && ((self.weaponentity.anim_type == HOLSTER) || (self.weaponentity.anim_type == AKIMBO_HOLSTER)))
	{
		setmodel(self.weaponentity, "");
		W_DrawWeapon(self.owner.newweapon);
		return;
	}
};
