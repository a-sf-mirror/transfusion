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

void() proxy_animate;

/*
============
Proxy_Attack

Attack code for the proximity bomb
============
*/
void() Proxy_Attack =
{
	if (self.weaponentity.attack_finished < time)
	{
		if (self.button0)
		{
			//Hack so that we can hold it as long as we want, its set properly when we throw it
			self.weaponentity.attack_finished = time + 99999999999999;
			self.weaponentity.anim_type = IDLE;
			self.weaponentity.charge = 1;
			self.player_state = PS_CHARGE;
			ShowThrowMeter();
		}
		else // Altfire
		{
			self.weaponentity.charge = 0;
			self.weaponentity.attack_finished = time + PROXY_DROP_TIME;
			Bomb_Fire();
			Bomb_Uncharge();
			self.weaponentity.anim_type = IDLE;
		}
		proxy_animate();
	}
};

/*
============
Proxy_Draw

Draw code for the proximity bomb
============
*/
void() Proxy_Draw =
{
	self.weapon = IT_PROXIMITY_BOMB;
	self.currentammo = self.ammo_tnt_proxy;
	self.weaponentity = spawn();
	self.weaponentity.solid = SOLID_NOT;
	self.weaponentity.owner = self;
	self.weaponentity.weaponentity = self.weaponentity;
	self.weaponentity.origin = '0 0 0';
	self.weaponentity.angles = '0 0 0';
	self.weaponentity.viewmodelforclient = self;

	Proxy_UpdateView();

	self.weaponentity.attack_finished = time + PROXY_DRAW_TIME;
	self.weaponentity.anim_type = DRAW;
	proxy_animate();
};

/*
============
Proxy_Holster

Holster code for the proximity bomb
============
*/
void() Proxy_Holster =
{
	self.weaponentity.attack_finished = time + PROXY_HOLSTER_TIME;
	self.weaponentity.anim_type = HOLSTER;
	proxy_animate();
};

/*
============
Proxy_UpdateView

Choose the right proximity bomb model to display
============
*/
void() Proxy_UpdateView =
{
	setmodel(self.weaponentity, "models/weapons/v_proxy.md3");
	self.items = self.items - (self.items & IT_GUNS_AKIMBO);
};

/*
============
proxy_animate

Animation and frame based code for the Proximity Mine
============
*/
void() proxy_animate =
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
			self.weaponentity.anim_end = PROXY_IDLE;
			self.weaponentity.anim_end_num = PROXY_IDLE + 1;
			self.weaponentity.anim_time = PROXY_IDLE_TIME;
			self.weaponentity.frame = PROXY_IDLE;
		}
		else if (self.weaponentity.anim_type == DRAW)
		{
			self.weaponentity.anim_end = PROXY_DRAW_END;
			self.weaponentity.anim_end_num = PROXY_DRAW_END - PROXY_DRAW_START + 1;
			self.weaponentity.anim_time = PROXY_DRAW_TIME;
			self.weaponentity.frame = PROXY_DRAW_START;
		}
		else if (self.weaponentity.anim_type == THROW)
		{
			self.weaponentity.anim_end = PROXY_THROW_END;
			self.weaponentity.anim_end_num = PROXY_THROW_END - PROXY_THROW_START + 1;
			self.weaponentity.anim_time = PROXY_THROW_TIME;
			self.weaponentity.frame = PROXY_THROW_START;
		}
		else if (self.weaponentity.anim_type == HOLSTER)
		{
			self.weaponentity.anim_end = PROXY_HOLSTER_END;
			self.weaponentity.anim_end_num = PROXY_HOLSTER_END - PROXY_HOLSTER_START + 1;
			self.weaponentity.anim_time = PROXY_HOLSTER_TIME;
			self.weaponentity.frame = PROXY_HOLSTER_START;
		}
		self.weaponentity.last_action = self.weaponentity.anim_type;
	}
	self.nextthink = time + (self.weaponentity.anim_time / self.weaponentity.anim_end_num);
	self.think = proxy_animate;
	if (self.button0)
	{
		if (self.weaponentity.charge < 20)
			self.weaponentity.charge = self.weaponentity.charge + 1;
		ShowThrowMeter();
	}
	else if (self.weaponentity.charge)
	{
		self.weaponentity.anim_type = THROW;
		self.weaponentity.attack_finished = PROXY_THROW_TIME;
		self.player_state = PS_FIRE;
		ShowThrowMeter();
		self.nextthink = time;
	}
	if (self.weaponentity.anim_type == THROW)
	{
		if (self.weaponentity.frame == PROXY_THROW_END - 1)
		{
			Bomb_Fire();
			Bomb_Uncharge();
		}
		else if (self.weaponentity.frame == PROXY_THROW_END)
			self.weaponentity.anim_type = IDLE;
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && (self.weaponentity.anim_type == DRAW))
	{
		self.weaponentity.anim_type = IDLE;
		proxy_animate();
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && (self.weaponentity.anim_type == HOLSTER))
	{
		remove(self.weaponentity);
		W_DrawWeapon(self.newweapon);
		return;
	}
};
