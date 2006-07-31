/*  Copyright (C) 2001-2006  Transfusion Code Team

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

void() tnt_animate;

/*
============
TNT_Attack

Attack code for the TNT
============
*/
void() TNT_Attack =
{
	if (self.weaponentity.attack_finished < time)
	{
		if (self.button0)
			self.player_state = PS_FIRE;
		else
			self.player_state = PS_ALTFIRE;
		self.weaponentity.attack_finished = self.weaponentity.tnt_time = time + FUSE_TIME;
		self.weaponentity.anim_type = LIGHT_FUSE;
		self.weaponentity.charge = 0;
		self.think = tnt_animate;
	}
};

/*
============
TNT_Draw

Draw code for the TNT
============
*/
void() TNT_Draw =
{
	self.currentammo = self.ammo_tnt_bundle;
	self.weaponentity = spawn();
	self.weaponentity.solid = SOLID_NOT;
	self.weaponentity.owner = self;
	self.weaponentity.weaponentity = self.weaponentity;
	self.weaponentity.viewmodelforclient = self;
	TNT_UpdateView();
	// If we need to pop up the lighter
	if (self.weapon != IT_SPRAY_CAN)
	{
		sound(self, CHAN_WEAPON, "weapons/tnt/lighter.wav", 1, ATTN_NORM);
		self.weaponentity.attack_finished = time + TNT_DRAW_TIME;
		self.weaponentity.anim_type = DRAW;
	}
	else
	{
		self.weaponentity.attack_finished = time + TNT_DRAW_TIME;
		self.weaponentity.anim_type = HALF_DRAW;
	}
	self.weapon = IT_TNT;
	tnt_animate();
};

/*
============
TNT_Holster

Holster code for the TNT
============
*/
void() TNT_Holster =
{
	self.weaponentity.attack_finished = time + TNT_HOLSTER_TIME;

	// If we need to close the lighter
	if (self.newweapon != IT_SPRAY_CAN)
	{
		sound(self, CHAN_WEAPON, "weapons/tnt/zipclose.wav", 1, ATTN_NORM);
		self.weaponentity.anim_type = HOLSTER;
	}
	else
		self.weaponentity.anim_type = HALF_HOLSTER;
	tnt_animate();
};

/*
============
TNT_UpdateView

Choose the right TNT model to display
============
*/
void() TNT_UpdateView =
{
	setmodel(self.weaponentity, "models/weapons/v_tnt.md3");
	self.items = self.items - (self.items & IT_GUNS_AKIMBO);
};

/*
============
tnt_animate

Animation and frame based code for TNT
============
*/
void() tnt_animate =
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
			self.player_state = PS_IDLE;
			self.weaponentity.anim_end = TNT_IDLE_END;
			self.weaponentity.anim_end_num = TNT_IDLE_END - TNT_IDLE_START + 1;
			self.weaponentity.anim_time = TNT_IDLE_TIME;
			self.weaponentity.frame = TNT_IDLE_START;
		}
		else if (self.weaponentity.anim_type == DRAW)
		{
			self.weaponentity.anim_end = TNT_DRAW_END;
			self.weaponentity.anim_end_num = TNT_DRAW_END - TNT_DRAW_START + 1;
			self.weaponentity.anim_time = TNT_DRAW_TIME;
			self.weaponentity.frame = TNT_DRAW_START;
		}
		else if (self.weaponentity.anim_type == HALF_DRAW)
		{
			self.weaponentity.anim_end = TNT_HALF_DRAW_END;
			self.weaponentity.anim_end_num = TNT_HALF_DRAW_END - TNT_HALF_DRAW_START + 1;
			self.weaponentity.anim_time = TNT_DRAW_TIME; //possibly divide by 2?
			self.weaponentity.frame = TNT_HALF_DRAW_START;
		}
		else if (self.weaponentity.anim_type == LIGHT_FUSE)
		{
			self.weaponentity.anim_end = TNT_LIGHT_FUSE_END;
			self.weaponentity.anim_end_num = TNT_LIGHT_FUSE_END - TNT_LIGHT_FUSE_START + 1;
			self.weaponentity.anim_time = TNT_LIGHT_FUSE_TIME;
			self.weaponentity.frame = TNT_LIGHT_FUSE_START;
		}
		else if (self.weaponentity.anim_type == THROW)
		{
			self.weaponentity.anim_end = TNT_THROW_END;
			self.weaponentity.anim_end_num = TNT_THROW_END - TNT_THROW_START + 1;
			self.weaponentity.anim_time = TNT_THROW_TIME;
			self.weaponentity.frame = TNT_THROW_START;
		}
		else if (self.weaponentity.anim_type == HOLSTER)
		{
			self.weaponentity.anim_end = TNT_HOLSTER_END;
			self.weaponentity.anim_end_num = TNT_HOLSTER_END - TNT_HOLSTER_START + 1;
			self.weaponentity.anim_time = TNT_HOLSTER_TIME;
			self.weaponentity.frame = TNT_HOLSTER_START;
		}
		else if (self.weaponentity.anim_type == HALF_HOLSTER)
		{
			self.weaponentity.anim_end = TNT_HALF_HOLSTER_END;
			self.weaponentity.anim_end_num = TNT_HALF_HOLSTER_END - TNT_HALF_HOLSTER_START + 1;
			self.weaponentity.anim_time = TNT_HOLSTER_TIME; // possibly divide by 2?
			self.weaponentity.frame = TNT_HALF_HOLSTER_START;
		}
		self.weaponentity.last_action = self.weaponentity.anim_type;
	}
	self.nextthink = time + (self.weaponentity.anim_time / self.weaponentity.anim_end_num);
	self.think = tnt_animate;
	if (self.weaponentity.anim_type == LIGHT_FUSE)
	{
		if (self.weaponentity.frame == TNT_LIGHT_FUSE_START)
		{
			if (self.player_state == PS_FIRE)
				self.weaponentity.tnt_type = TNT_TYPE_NORMAL;
			else //Altfire
				self.weaponentity.tnt_type = TNT_TYPE_ALTFIRE;
		}
		ShowThrowMeter();
		if (self.weaponentity.frame >= TNT_LIGHT_FUSE_END - 2)
		{
			if (self.weaponentity.t_width <= time)
			{
				sound(self, CHAN_WEAPON, "weapons/tnt/tntfuse.wav", 0.5, ATTN_NORM);
				self.weaponentity.t_width = time + 3.2;
			}
			if (self.button0 && self.weaponentity.tnt_time && !self.weaponentity.charge)
			{
				self.player_state = PS_CHARGE;
				self.weaponentity.charge = 1;
			}
			else if (self.button0 && self.weaponentity.charge < 20)
				self.weaponentity.charge = self.weaponentity.charge + 1;
			if (self.weaponentity.charge && !self.button0)
			{
				self.weaponentity.anim_type = THROW;
				self.weaponentity.attack_finished = time + TNT_THROW_TIME;
				self.player_state = PS_FIRE;
				ShowThrowMeter();
				tnt_animate();
			}
			else if (self.button3)
			{
				self.weaponentity.charge = 0;
				self.weaponentity.attack_finished = time + TNT_DROP_TIME;
				Bomb_Fire();
				Bomb_Uncharge();
				self.weaponentity.anim_type = IDLE;
			}
			else if (self.weaponentity.attack_finished <= time)
			{
				//FIXME - animation for blowing hand up if attack_finished expires?
				//possibly just an animated sprite with flames included
				self.weaponentity.charge = 0;
				self.weaponentity.tnt_type = TNT_TYPE_NORMAL;
				self.weaponentity.attack_finished = time + TNT_DROP_TIME;
				Bomb_Fire();
				Bomb_Uncharge();
				remove(self.weaponentity);
				self.weapon = 0;
			}
			if (self.weaponentity.frame == TNT_LIGHT_FUSE_END)
				self.weaponentity.frame = TNT_LIGHT_FUSE_END - 2;
		}
	}
	else if (self.weaponentity.anim_type == THROW)
	{
		if (self.weaponentity.frame == TNT_THROW_END - 1)
		{
			Bomb_Fire();
			Bomb_Uncharge();
		}
		else if (self.weaponentity.frame == TNT_THROW_END)
			self.weaponentity.anim_type = IDLE;
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && ((self.weaponentity.anim_type == DRAW) || (self.weaponentity.anim_type == HALF_DRAW)))
	{
		self.weaponentity.anim_type = IDLE;
		tnt_animate();
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && ((self.weaponentity.anim_type == HOLSTER) || (self.weaponentity.anim_type == HALF_HOLSTER)))
	{
		remove(self.weaponentity);
		W_DrawWeapon(self.newweapon);
		return;
	}
};
