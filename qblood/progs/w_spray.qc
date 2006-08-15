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

void() spray_animate;

/*
============
Spray_Fire

Send a fire cloud
============
*/
void() Spray_Fire =
{
	local vector    dir;

	if (self.ammo_spray < 1)
		return;

	makevectors(self.v_angle);

	self.weaponentity.attack_finished = time + SPRAY_HOLDFIRE_TIME;
	if (!(self.flags & FL_INFINATE_AMMO))
		self.currentammo = self.ammo_spray = self.ammo_spray - 1;
	dir = aim(self, 1000);

	newmis = spawn();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;
	newmis.alpha = 0.6;
	newmis.effects = EF_ADDITIVE;

	newmis.angles = vectoangles(dir);

	newmis.touch = flame_touch;
	newmis.classname = "spike";
	newmis.reset = SUB_Remove;
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 0.6;
	setmodel(newmis, "progs/sprayfir.spr");
	setsize(newmis, '-1 -1 -1', '1 1 1');
	setorigin(newmis, W_Origin() + v_forward * 50 + v_right * 2 + v_up * -5);

	newmis.velocity = dir * 550;
	newmis.owner = self;
	newmis.frame = floor(random() * 3);
};

/*
============
Spray_Attack

Attack code for the spray can
============
*/
void() Spray_Attack =
{
	if (self.button3) // New Altfire
	{
		self.player_state = PS_ALTFIRE;
		self.weaponentity.anim_type = LIGHT_FUSE;
		self.weaponentity.attack_finished = self.weaponentity.tnt_time = time + FUSE_TIME;
		self.weaponentity.charge = 0;
		//We'll set a more accurate attack_finished when actually throwing the bomb		
	}
	else if (self.button0 && !self.weaponentity.tnt_time)// Normal fire
	{
		self.player_state = PS_FIRE;
		self.weaponentity.attack_finished = time + SPRAY_FIRE_TIME;
		self.weaponentity.anim_type = FIRE;
	}
	spray_animate();
};

/*
============
Spray_Draw

Draw code for the spray can
============
*/
void() Spray_Draw =
{
	self.currentammo = self.ammo_spray;
	self.weaponentity = spawn();
	self.weaponentity.solid = SOLID_NOT;
	self.weaponentity.owner = self;
	self.weaponentity.weaponentity = self.weaponentity;
	self.weaponentity.viewmodelforclient = self;
	Spray_UpdateView();
	// If we need to pop up the lighter
	if (self.weapon != IT_TNT)
	{
		sound(self, CHAN_WEAPON, "weapons/tnt/lighter.wav", 1, ATTN_NORM);
		self.weaponentity.anim_type = DRAW;
	}
	else
		self.weaponentity.anim_type = HALF_DRAW;
	self.weapon = IT_SPRAY_CAN;
	self.weaponentity.attack_finished = time + SPRAY_DRAW_TIME; // possibly divide by 2 when halfdraw?
	spray_animate();
};

/*
============
Spray_Holster

Holster code for the spray can
============
*/
void() Spray_Holster =
{
	self.weaponentity.attack_finished = time + SPRAY_HOLSTER_TIME;

	// If we need to close the lighter
	if (self.newweapon != IT_TNT)
	{
		sound(self, CHAN_WEAPON, "weapons/tnt/zipclose.wav", 1, ATTN_NORM);
		self.weaponentity.anim_type = HOLSTER;
	}
	else
		self.weaponentity.anim_type = HALF_HOLSTER;
	spray_animate();
};

/*
============
Spray_UpdateView

Choose the right Hairspray Can model to display
============
*/
void() Spray_UpdateView =
{
	setmodel(self.weaponentity, "models/weapons/v_aerosol.md3");
	self.items = self.items - (self.items & IT_GUNS_AKIMBO);
};

/*
============
spray_animate

Animation and frame based code for the Hairspray Can
============
*/
void() spray_animate =
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
			self.weaponentity.anim_end = SPRAY_IDLE_END;
			self.weaponentity.anim_end_num = SPRAY_IDLE_END - SPRAY_IDLE_START + 1;
			self.weaponentity.anim_time = SPRAY_IDLE_TIME;
			self.weaponentity.frame = SPRAY_IDLE_START;
		}
		else if (self.weaponentity.anim_type == DRAW)
		{
			self.weaponentity.anim_end = SPRAY_DRAW_END;
			self.weaponentity.anim_end_num = SPRAY_DRAW_END - SPRAY_DRAW_START + 1;
			self.weaponentity.anim_time = SPRAY_DRAW_TIME;
			self.weaponentity.frame = SPRAY_DRAW_START;
		}
		else if (self.weaponentity.anim_type == HALF_DRAW)
		{
			self.weaponentity.anim_end = SPRAY_HALF_DRAW_END;
			self.weaponentity.anim_end_num = SPRAY_HALF_DRAW_END - SPRAY_HALF_DRAW_START + 1;
			self.weaponentity.anim_time = SPRAY_DRAW_TIME; //possibly divide by 2?
			self.weaponentity.frame = SPRAY_HALF_DRAW_START;
		}
		else if (self.weaponentity.anim_type == FIRE)
		{
			self.weaponentity.anim_end = SPRAY_FIRE_END;
			self.weaponentity.anim_end_num = SPRAY_FIRE_END - SPRAY_FIRE_START + 1;
			self.weaponentity.anim_time = SPRAY_FIRE_TIME;
			self.weaponentity.frame = SPRAY_FIRE_START;
		}
		else if (self.weaponentity.anim_type == LIGHT_FUSE)
		{
			self.weaponentity.anim_end = SPRAY_LIGHT_FUSE_END;
			self.weaponentity.anim_end_num = SPRAY_LIGHT_FUSE_END - SPRAY_LIGHT_FUSE_START + 1;
			self.weaponentity.anim_time = SPRAY_LIGHT_FUSE_TIME;
			self.weaponentity.frame = SPRAY_LIGHT_FUSE_START;
		}
		else if (self.weaponentity.anim_type == THROW)
		{
			self.weaponentity.anim_end = SPRAY_THROW_END;
			self.weaponentity.anim_end_num = SPRAY_THROW_END - SPRAY_THROW_START + 1;
			self.weaponentity.anim_time = SPRAY_THROW_TIME;
			self.weaponentity.frame = SPRAY_THROW_START;
		}
		else if (self.weaponentity.anim_type == HOLSTER)
		{
			self.weaponentity.anim_end = SPRAY_HOLSTER_END;
			self.weaponentity.anim_end_num = SPRAY_HOLSTER_END - SPRAY_HOLSTER_START + 1;
			self.weaponentity.anim_time = SPRAY_HOLSTER_TIME;
			self.weaponentity.frame = SPRAY_HOLSTER_START;
		}
		else if (self.weaponentity.anim_type == HALF_HOLSTER)
		{
			self.weaponentity.anim_end = SPRAY_HALF_HOLSTER_END;
			self.weaponentity.anim_end_num = SPRAY_HALF_HOLSTER_END - SPRAY_HALF_HOLSTER_START + 1;
			self.weaponentity.anim_time = SPRAY_HOLSTER_TIME; // possibly divide by 2?
			self.weaponentity.frame = SPRAY_HALF_HOLSTER_START;
		}
		self.weaponentity.last_action = self.weaponentity.anim_type;
	}
	self.nextthink = time + (self.weaponentity.anim_time / self.weaponentity.anim_end_num);
	self.think = spray_animate;
	if (self.weaponentity.anim_type == FIRE)
	{
		// Start the fire sound if necessary
		if (self.weaponentity.t_width <= time)
		{
			sound(self, CHAN_WEAPON, "weapons/spraycan/sprayfir.wav", 0.5, ATTN_NORM);
			self.weaponentity.t_width = time + 2.5;
		}
		if (!self.button0 || intermission_running || self.ammo_spray < 1)
		{
			// Stop the fire sound
			sound(self, CHAN_WEAPON, "misc/null.wav", 0, ATTN_NORM);
			self.weaponentity.t_width = 0;
			self.weaponentity.anim_type = IDLE;
		}
		else
			Spray_Fire();
	}
	else if (self.weaponentity.anim_type == LIGHT_FUSE)
	{
		if (self.weaponentity.frame >= SPRAY_LIGHT_FUSE_END - 2)
		{
			if (self.weaponentity.t_width <= time)
			{
				sound(self, CHAN_WEAPON, "weapons/spraycan/spraycan.wav", 1, ATTN_NORM);
				self.weaponentity.t_width = time + 2.5;
			}
			if (self.button0 && self.weaponentity.tnt_time && !self.weaponentity.charge)
			{
				self.player_state = PS_CHARGE;
				self.weaponentity.charge = 1;
			}
			else if (self.button0 && self.weaponentity.charge < 20)
				self.weaponentity.charge = self.weaponentity.charge + 1;
			if (self.button3)
			{
				self.weaponentity.charge = 0;
				self.weaponentity.tnt_type = TNT_TYPE_ALTFIRE;
				self.weaponentity.attack_finished = time + SPRAY_DROP_TIME;
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
				self.weaponentity.attack_finished = time + SPRAY_DROP_TIME;
				Bomb_Fire();
				Bomb_Uncharge();
				remove(self.weaponentity);
				self.weapon = 0;
			}
			if (self.weaponentity.charge && !self.button0)
			{
				self.weaponentity.anim_type = THROW;
				self.weaponentity.attack_finished = time + SPRAY_THROW_TIME;
				self.player_state = PS_FIRE;
				spray_animate();
			}
			if (self.weaponentity.frame == SPRAY_LIGHT_FUSE_END)
				self.weaponentity.frame = SPRAY_LIGHT_FUSE_END - 2;
		}
		ResetIdle(self);
		ShowThrowMeter();
	}
	else if (self.weaponentity.anim_type == THROW)
	{
		if (self.weaponentity.frame == SPRAY_THROW_END - 1)
		{
			self.weaponentity.tnt_type = TNT_TYPE_NORMAL;
			Bomb_Fire();
			Bomb_Uncharge();
		}
		else if (self.weaponentity.frame == SPRAY_THROW_END)
			self.weaponentity.anim_type = IDLE;
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && ((self.weaponentity.anim_type == DRAW) || (self.weaponentity.anim_type == HALF_DRAW)))
	{
		self.weaponentity.anim_type = IDLE;
		spray_animate();
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && ((self.weaponentity.anim_type == HOLSTER) || (self.weaponentity.anim_type == HALF_HOLSTER)))
	{
		remove(self.weaponentity);
		W_DrawWeapon(self.newweapon);
		return;
	}
};