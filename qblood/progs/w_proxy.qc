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
================
ProxyBombCheck

The proximity bomb checks its neighborhood and explodes if a living being is nearby
================
*/
void() ProxyBombCheck =
{
	local entity thing;

	// Try to find something interesting nearby
	// Note: in T_RadiusDamage, an explosion can damage someone up to a distance of its damage + 40
	thing = findradius(self.origin, self.dmg + 20);
	while (thing)
	{
		// If it's a player or a monster, explode in 400 msec
		if (thing.classname == "player" || (thing.flags & FL_MONSTER))
		{
			sound(self, CHAN_WEAPON, "weapons/tnt/proxdet.wav", 1, ATTN_NORM);
			self.pausetime = time + 0.4;
			self.think1 = SUB_Null;
			return;
		}

		// Next one
		thing = thing.chain;
	}

	// Retry in a moment
	self.pausetime = time + 0.25;
};

/*
================
ProxyBombArmed

The proximity bomb becomes armed, ready to explode as soon as someone is nearby
================
*/
void() ProxyBombArmed =
{
	sound(self, CHAN_WEAPON, "weapons/tnt/proxarm.wav", 1, ATTN_NORM);

	self.pausetime = time;
	self.think1 = ProxyBombCheck;
};

/*
================
ProxyBombThink

The proximity bomb does a generic think, then is checked against the world
================
*/
void() ProxyBombThink =
{
	if (self.pausetime <= time)
	{
		if (self.think1 == SUB_Null)
		{
			Bomb_Explode();
			return;
		}
		self.think1();
	}

	// Do the standard bomb thinking
	BombThink();
};

/*
====================
proximity_mine

Spawn function for proximity mines (BB6 map)
====================
*/
void() proximity_mine =
{
	precache_sound("weapons/tnt/proxdet.wav");  // proximity bomb triggered

	self.owner      = world;
	self.solid      = SOLID_BBOX;
	self.takedamage = DAMAGE_AIM;
	self.health     = 1;
	self.th_die     = Bomb_Trigger;
	self.nextthink  = 0.1;
	self.pausetime  = time;
	self.think1     = ProxyBombCheck;
	self.think      = ProxyBombThink;
	self.dmg        = DMG_PROXIMITY_BOMB;
	setsize(self, '-1 -1 -1', '1 1 1');	
};

/*
============
Proxy_Attack

Attack code for the proximity bomb
============
*/
void() Proxy_Attack =
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
	self.weaponentity.nextthink = time;
	self.weaponentity.think = proxy_animate;
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
	Proxy_UpdateView();
	self.weaponentity.attack_finished = time + PROXY_DRAW_TIME;
	self.weaponentity.anim_type = DRAW;
	self.weaponentity.frame = PROXY_DRAW_START;
	self.weaponentity.skin = 0;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = proxy_animate;
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
	self.weaponentity.nextthink = time;
	self.weaponentity.think = proxy_animate;
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
Proxy_Idle
============
*/
void() Proxy_Idle =
{
	self.weaponentity.anim_type = IDLE;
	self.weaponentity.frame = PROXY_IDLE;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = proxy_animate;
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
			if (self.weaponentity.last_action == DRAW)
			{
				self.weaponentity.anim_end = PROXY_HOLSTER_END;
				self.weaponentity.anim_end_num = PROXY_HOLSTER_END - PROXY_HOLSTER_START + 1;
				self.weaponentity.anim_time = (PROXY_HOLSTER_TIME / (PROXY_HOLSTER_END - PROXY_HOLSTER_START + 1)) * (self.weaponentity.frame - PROXY_DRAW_START + 1);
				self.weaponentity.attack_finished = time + self.weaponentity.anim_time;
				self.weaponentity.frame = PROXY_HOLSTER_END - (self.weaponentity.frame - PROXY_DRAW_START + 1) + 1;
			}
			else
			{
				self.weaponentity.anim_end = PROXY_HOLSTER_END;
				self.weaponentity.anim_end_num = PROXY_HOLSTER_END - PROXY_HOLSTER_START + 1;
				self.weaponentity.anim_time = PROXY_HOLSTER_TIME;
				self.weaponentity.frame = PROXY_HOLSTER_START;
			}
		}
		self.weaponentity.last_action = self.weaponentity.anim_type;
	}
	self.weaponentity.nextthink = time + (self.weaponentity.anim_time / self.weaponentity.anim_end_num);
	self.weaponentity.think = proxy_animate;

	if (self.weaponentity.skin == 3)
		self.weaponentity.skin = 0;
	else
		self.weaponentity.skin = self.weaponentity.skin + 1;

	if (self.owner.button0)
	{
		if (self.weaponentity.charge < 20)
			self.weaponentity.charge = self.weaponentity.charge + 1;
		ShowThrowMeter();
	}
	else if (self.weaponentity.charge && self.weaponentity.anim_type != THROW)
	{
		self.weaponentity.anim_type = THROW;
		self.weaponentity.attack_finished = time + PROXY_THROW_TIME;
		self.owner.player_state = PS_FIRE;
		ShowThrowMeter();
		self.weaponentity.nextthink = time;
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
		self.owner.player_state = PS_IDLE;
		Proxy_Idle();
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && (self.weaponentity.anim_type == HOLSTER))
	{
		setmodel(self.weaponentity, "");
		W_DrawWeapon(self.owner.newweapon);
		return;
	}
};
