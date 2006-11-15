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

void() voodoo_animate;

#define VOODOO_IDLE					0
#define VOODOO_DRAW_START			1
#define VOODOO_DRAW_END				3
#define VOODOO_FIRE_STOMACH_START	4 // Stomach
#define VOODOO_FIRE_STOMACH_END		7
#define VOODOO_FIRE_EYE_START		8 // Eye
#define VOODOO_FIRE_EYE_END			11
#define VOODOO_FIRE_SHOULDER_START	12 // Shoulder
#define VOODOO_FIRE_SHOULDER_END	15
#define VOODOO_FIRE_GROIN_START		16 // Groin
#define VOODOO_FIRE_GROIN_END		21
#define VOODOO_FIRE_THUMB_START		22 // Thumb
#define VOODOO_FIRE_THUMB_END		25
#define VOODOO_SITUP_START			26
#define VOODOO_SITUP_END			27
#define VOODOO_ALTFIRE_START		28
#define VOODOO_ALTFIRE_END			37
#define VOODOO_HOLSTER_START		38
#define VOODOO_HOLSTER_END			40

#define VOODOO_IDLE_TIME			0.1
#define VOODOO_DRAW_TIME			0.3
#define VOODOO_FIRE_TIME			0.5	//This is only for attack_finished
#define VOODOO_FIRE_STOMACH_TIME	0.4	//used in combination with FIRE_TIME keeps animation at
#define VOODOO_FIRE_EYE_TIME		0.4 //the correct speed and all fire modes at the same pace
#define VOODOO_FIRE_SHOULDER_TIME	0.4
#define VOODOO_FIRE_GROIN_TIME		0.6
#define VOODOO_FIRE_THUMB_TIME		0.4
#define VOODOO_ALTFIRE_TIME			1.5
#define VOODOO_HOLSTER_TIME			0.3

#define	STAB_STOMACH				1
#define	STAB_EYE					2
#define	STAB_SHOULDER				3
#define	STAB_GROIN					4
#define STAB_THUMB					5

//============================================================================

/*
================
Voodoo_ApplyDamage

Apply the spiritual damage of the voodoo doll
================
*/
void() Voodoo_ApplyDamage =
{
	local entity targ;
	local string death_type;
	local string targ_class;

	death_type = "voodoo";

	if (gametype == GT_COOPERATIVE || gametype == GT_SINGLE_PLAYER)
		targ_class = "monster";
	else
		targ_class = "player";
	targ = SUB_GetPointedClass(targ_class, 0.15);

	// If we had a target that can be damaged and seems alive
	if (targ != world && targ.takedamage)
		SpawnBlood(targ.origin, '0 0 0', self.weaponentity.stab_damage);
	else // Else, WE take the damage
	{
		targ = self.owner;
		self.weaponentity.stab_damage = 1;
	}

	// We don't consume ammo if we don't hit a target (except for altfire)
	if (self.owner.player_state == PS_ALTFIRE)
	{
		self.owner.ammo_voodoo = 0;
		death_type = "alt-voodoo";
	}	
	else if (targ != self.owner && !(self.owner.flags & FL_INFINATE_AMMO))
		self.owner.ammo_voodoo = self.owner.ammo_voodoo - self.owner.weaponentity.stab_damage / 4;
	self.owner.currentammo = self.owner.ammo_voodoo;

	T_Damage(targ, self.owner, self.owner, self.weaponentity.stab_damage, DF_VOODOO, death_type);
};

/*
================
Voodoo_Stab

Do a normal attack with the voodoo doll
================
*/
void() Voodoo_Stab =
{
	local float random_stab_type;

	random_stab_type = random()*4;
	self.weaponentity.stab_damage = random();
	if (random_stab_type >= 3) // Stab Groin
	{
		self.weaponentity.stab_type = STAB_GROIN;
		self.weaponentity.stab_damage = self.weaponentity.stab_damage*49 + 4;
	}
	else if (random_stab_type >= 2) // Stab Shoulder (supposed to make player lower weapon in MP mode)
	{
		self.weaponentity.stab_type = STAB_SHOULDER;
		self.weaponentity.stab_damage = self.weaponentity.stab_damage*9 + 4;
	}
	else if (random_stab_type >= 1) // Stab Stomach
	{
		self.weaponentity.stab_type = STAB_STOMACH;
		self.weaponentity.stab_damage = self.weaponentity.stab_damage*17 + 4;
	}
	else if (random_stab_type < 1) // Stab Eye (supposed to blind player in MP mode)
	{
		self.weaponentity.stab_type = STAB_EYE;
		self.weaponentity.stab_damage = self.weaponentity.stab_damage*11 + 4;
	}
	else
		sprint(self, "There's a problem with the voodoo doll code\n");

	local entity targ;
	local string targ_class;

	if (gametype == GT_COOPERATIVE || gametype == GT_SINGLE_PLAYER)
		targ_class = "monster";
	else
		targ_class = "player";
	targ = SUB_GetPointedClass(targ_class, 0.15);

	// If we had a target that can be damaged and seems alive
	if (targ == world)
	{
		self.weaponentity.stab_type = STAB_THUMB;
		self.weaponentity.stab_damage = 1;
	}
};

/*
============
Voodoo_Attack

Attack code for the voodoo doll
============
*/
void() Voodoo_Attack =
{
	if (self.weaponentity.attack_finished < time)
	{
		if (self.button3 && self.ammo_voodoo >= 1) // Alt-fire mode
		{
			self.player_state = PS_ALTFIRE;
			sound(self, CHAN_WEAPON, "weapons/voodoodl/voochant.wav", 1, ATTN_NORM);
			self.weaponentity.stab_damage = self.ammo_voodoo;

			self.weaponentity.attack_finished = time + VOODOO_ALTFIRE_TIME;
			self.weaponentity.anim_type = ALTFIRE;
		}
		else // Normal fire mode
		{
			self.player_state = PS_FIRE;

			Voodoo_Stab();
			self.weaponentity.attack_finished = time + VOODOO_FIRE_TIME;
			self.weaponentity.anim_type = FIRE;
		}
		self.weaponentity.nextthink = time;
		self.weaponentity.think = voodoo_animate;
	}
};

/*
============
Voodoo_Draw

Draw code for the voodoo doll
============
*/
void() Voodoo_Draw =
{
	self.weapon = IT_VOODOO_DOLL;
	self.currentammo = self.ammo_voodoo;
	Voodoo_UpdateView();
	self.weaponentity.frame = VOODOO_DRAW_START;
	self.weaponentity.attack_finished = time + VOODOO_DRAW_TIME;
	self.weaponentity.anim_type = DRAW;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = voodoo_animate;
};

/*
============
Voodoo_Holster

Holster code for the voodoo doll
============
*/
void() Voodoo_Holster =
{
	self.weaponentity.attack_finished = time + VOODOO_HOLSTER_TIME;
	self.weaponentity.anim_type = HOLSTER;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = voodoo_animate;
};

/*
============
Voodoo_UpdateView

Choose the right voodoo doll model to display
============
*/
void() Voodoo_UpdateView =
{
	setmodel(self.weaponentity, "models/weapons/v_voodoo.md3");
	self.items = self.items - (self.items & IT_GUNS_AKIMBO);
};

void() Voodoo_Idle =
{
	self.weaponentity.anim_type = IDLE;
	self.owner.player_state = PS_IDLE;
	self.weaponentity.frame = VOODOO_IDLE;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = voodoo_animate;
};

/*
============
voodoo_animate

Animation and frame based code for the Voodoo Doll
============
*/
void() voodoo_animate =
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
			self.weaponentity.anim_end = VOODOO_IDLE;
			self.weaponentity.anim_end_num = VOODOO_IDLE + 1;
			self.weaponentity.anim_time = VOODOO_IDLE_TIME;
			self.weaponentity.frame = VOODOO_IDLE;
		}
		else if (self.weaponentity.anim_type == DRAW)
		{
			self.weaponentity.anim_end = VOODOO_DRAW_END;
			self.weaponentity.anim_end_num = VOODOO_DRAW_END - VOODOO_DRAW_START + 1;
			self.weaponentity.anim_time = VOODOO_DRAW_TIME;
			self.weaponentity.frame = VOODOO_DRAW_START;
		}
		else if (self.weaponentity.anim_type == FIRE)
		{
			if (self.weaponentity.stab_type == STAB_STOMACH)
			{
				self.weaponentity.anim_end = VOODOO_FIRE_STOMACH_END;
				self.weaponentity.anim_end_num = VOODOO_FIRE_STOMACH_END - VOODOO_FIRE_STOMACH_START + 1;
				self.weaponentity.anim_time = VOODOO_FIRE_STOMACH_TIME;
				self.weaponentity.frame = VOODOO_FIRE_STOMACH_START;
			}
			if (self.weaponentity.stab_type == STAB_EYE)
			{
				self.weaponentity.anim_end = VOODOO_FIRE_EYE_END;
				self.weaponentity.anim_end_num = VOODOO_FIRE_EYE_END - VOODOO_FIRE_EYE_START + 1;
				self.weaponentity.anim_time = VOODOO_FIRE_EYE_TIME;
				self.weaponentity.frame = VOODOO_FIRE_EYE_START;
			}
			if (self.weaponentity.stab_type == STAB_SHOULDER)
			{
				self.weaponentity.anim_end = VOODOO_FIRE_SHOULDER_END;
				self.weaponentity.anim_end_num = VOODOO_FIRE_SHOULDER_END - VOODOO_FIRE_SHOULDER_START + 1;
				self.weaponentity.anim_time = VOODOO_FIRE_SHOULDER_TIME;
				self.weaponentity.frame = VOODOO_FIRE_SHOULDER_START;
			}
			if (self.weaponentity.stab_type == STAB_GROIN)
			{
				self.weaponentity.anim_end = VOODOO_FIRE_GROIN_END;
				self.weaponentity.anim_end_num = VOODOO_FIRE_GROIN_END - VOODOO_FIRE_GROIN_START + 1;
				self.weaponentity.anim_time = VOODOO_FIRE_GROIN_TIME;
				self.weaponentity.frame = VOODOO_FIRE_GROIN_START;
			}
			if (self.weaponentity.stab_type == STAB_THUMB)
			{
				self.weaponentity.anim_end = VOODOO_FIRE_THUMB_END;
				self.weaponentity.anim_end_num = VOODOO_FIRE_THUMB_END - VOODOO_FIRE_THUMB_START + 1;
				self.weaponentity.anim_time = VOODOO_FIRE_THUMB_TIME;
				self.weaponentity.frame = VOODOO_FIRE_THUMB_START;
			}
		}
		else if (self.weaponentity.anim_type == ALTFIRE)
		{
			self.weaponentity.anim_end = VOODOO_ALTFIRE_END;
			self.weaponentity.anim_end_num = VOODOO_ALTFIRE_END - VOODOO_ALTFIRE_START + 1;
			self.weaponentity.anim_time = VOODOO_ALTFIRE_TIME;
			self.weaponentity.frame = VOODOO_ALTFIRE_START;
		}
		else if (self.weaponentity.anim_type == HOLSTER)
		{
			if (self.weaponentity.last_action == DRAW)
			{
				self.weaponentity.anim_end = VOODOO_HOLSTER_END;
				self.weaponentity.anim_end_num = VOODOO_HOLSTER_END - VOODOO_HOLSTER_START + 1;
				self.weaponentity.anim_time = (VOODOO_HOLSTER_TIME / (VOODOO_HOLSTER_END - VOODOO_HOLSTER_START + 1)) * (self.weaponentity.frame - VOODOO_DRAW_START + 1);
				self.weaponentity.attack_finished = time + self.weaponentity.anim_time;
				self.weaponentity.frame = VOODOO_HOLSTER_END - (self.weaponentity.frame - VOODOO_DRAW_START + 1) + 1;
			}
			else
			{
				self.weaponentity.anim_end = VOODOO_HOLSTER_END;
				self.weaponentity.anim_end_num = VOODOO_HOLSTER_END - VOODOO_HOLSTER_START + 1;
				self.weaponentity.anim_time = VOODOO_HOLSTER_TIME;
				self.weaponentity.frame = VOODOO_HOLSTER_START;
			}
		}
		self.weaponentity.last_action = self.weaponentity.anim_type;
	}
	if (self.weaponentity.anim_type != IDLE)
	{
		self.weaponentity.nextthink = time + (self.weaponentity.anim_time / self.weaponentity.anim_end_num);
		self.weaponentity.think = voodoo_animate;
	}

	if (self.weaponentity.anim_type == FIRE)
	{
		local float fire_start_frame;
		fire_start_frame = self.weaponentity.anim_end - self.weaponentity.anim_end_num + 1;
		if (self.weaponentity.frame == fire_start_frame + 1)
		{
			if (self.weaponentity.stab_type == STAB_GROIN)  // Stab Groin
				sound(self.owner, CHAN_WEAPON, "weapons/voodoodl/voolaugh.wav", 1, ATTN_NORM);
			else
				sound(self.owner, CHAN_WEAPON, "weapons/voodoodl/voostab.wav", 1, ATTN_NORM);
		}
		if (self.weaponentity.frame == fire_start_frame + 2)
			Voodoo_ApplyDamage();

		if (self.weaponentity.frame == self.weaponentity.anim_end)
			Voodoo_Idle();
	}
	else if (self.weaponentity.anim_type == ALTFIRE)
	{
		if (self.weaponentity.frame == VOODOO_ALTFIRE_START + 6)
			Voodoo_ApplyDamage();
		if (self.weaponentity.frame == VOODOO_ALTFIRE_END)
			W_DrawWeapon(W_BestWeapon());
		return;
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && (self.weaponentity.anim_type == DRAW))
	{
		self.weaponentity.nextthink = time;
		self.weaponentity.think = Voodoo_Idle;
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && (self.weaponentity.anim_type == HOLSTER))
	{
		setmodel(self.weaponentity, "");
		W_DrawWeapon(self.owner.newweapon);
		return;
	}
};