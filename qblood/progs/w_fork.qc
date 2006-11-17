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

void() fork_animate;

#define FORK_IDLE			0
#define FORK_DRAW_START		1
#define FORK_DRAW_END		3
#define FORK_FIRE_START		4
#define FORK_FIRE_END		7
#define FORK_HOLSTER_START	8
#define FORK_HOLSTER_END	10

#define FORK_IDLE_TIME		0.1
#define FORK_DRAW_TIME		0.3
#define FORK_FIRE_TIME		0.45
#define FORK_HOLSTER_TIME	0.3

//============================================================================

/*
============
TineHit

Handle one tine hit with the pitchfork
============
*/
void(entity targ, vector org, float damage) TineHit =
{
	if (targ.takedamage)
	{
		if (Reflected(targ))
		{
			if (Reflected(self))
				return;     // Both have reflection, so negate attack.

			// Hit attacker instead.
			targ = self;
			org = W_Origin();
		}
		// If the target can bleed, spawn some blood
		if (targ.classname == "player" || (targ.flags & FL_MONSTER) ||
			targ.classname == "corpse" || targ.classname == "head")
		{
			SpawnBlood(org, '0 0 0', damage);
			SpawnBloodSpray(trace_ent, org);
			sound(self, CHAN_WEAPON, "weapons/pitchfrk/pflesh.wav", 1, ATTN_NORM);
		}
		else
			sound(self, CHAN_WEAPON, "weapons/pitchfrk/pstone.wav", 1, ATTN_NORM);
		AddMultiDamage(targ, damage);
	}
	else
	{
		// hit wall
		sound(self, CHAN_WEAPON, "weapons/pitchfrk/pstone.wav", 1, ATTN_NORM);

		WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte(MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord(MSG_BROADCAST, org_x);
		WriteCoord(MSG_BROADCAST, org_y);
		WriteCoord(MSG_BROADCAST, org_z);
	}
};

/*
============
Fork_Fire

Try to hit something with the pitchfork
============
*/
void() Fork_Fire =
{
	local   vector  source;
	local   vector  start, end;     // Endpoints per tine.
	local   float   damage;         // Damage per tine.
	local   float   loop;           // Number of tines.

	makevectors(self.owner.v_angle);
	source = W_Origin();
	damage = 17;
	loop = 4;

	// Tines attacks start at the right, and end at the left.
	ClearMultiDamage();
	while (loop > 0)
	{
		start = source + v_right * ((loop - 2) * 4 - 2);
		end = start + v_forward * 64;
		traceline(start, end, FALSE, self.owner);
		if (trace_fraction < 1)
		{
			end = trace_endpos - v_forward * 4;
			TineHit(trace_ent, end, damage);
		}
		loop = loop - 1;
	}
	ApplyMultiDamage(DF_STAB);
};

/*
============
Fork_Attack

Attack code for the pitchfork
============
*/
void() Fork_Attack =
{
	self.player_state = PS_FIRE;
	self.weaponentity.frame = FORK_FIRE_START;
	self.weaponentity.attack_finished = time + FORK_FIRE_TIME;
	self.weaponentity.anim_type = FIRE;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = fork_animate;
};

/*
============
Fork_Draw

Draw code for the pitchfork
============
*/
void() Fork_Draw =
{
	self.weapon = IT_PITCHFORK;
	self.currentammo = 0;
	Fork_UpdateView();
	self.weaponentity.attack_finished = time + FORK_DRAW_TIME;
	self.weaponentity.anim_type = DRAW;
	self.weaponentity.nextthink = time;
	self.weaponentity.frame = FORK_DRAW_START;
	self.weaponentity.skin = 0;
	self.weaponentity.think = fork_animate;
};

/*
============
Fork_Holster

Holster code for the pitchfork
============
*/
void() Fork_Holster =
{
	self.weaponentity.attack_finished = time + FORK_HOLSTER_TIME;
	self.weaponentity.anim_type = HOLSTER;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = fork_animate;
};

/*
============
Fork_UpdateView

Choose the right pitchfork model to display
============
*/
void() Fork_UpdateView =
{
	setmodel(self.weaponentity, "models/weapons/v_pitch.psk");
	self.items = self.items - (self.items & IT_GUNS_AKIMBO);
};

void() Fork_Idle =
{
	self.weaponentity.anim_type = IDLE;
	self.weaponentity.frame = FORK_IDLE;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = fork_animate;
};

/*
============
fork_animate

Animation and frame based code for the Pitchfork
============
*/
void() fork_animate =
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
			self.weaponentity.anim_end = FORK_IDLE;
			self.weaponentity.anim_end_num = FORK_IDLE + 1;
			self.weaponentity.anim_time = FORK_IDLE_TIME;
			self.weaponentity.frame = FORK_IDLE;
		}
		else if (self.weaponentity.anim_type == DRAW)
		{
			self.weaponentity.anim_end = FORK_DRAW_END;
			self.weaponentity.anim_end_num = FORK_DRAW_END - FORK_DRAW_START + 1;
			self.weaponentity.anim_time = FORK_DRAW_TIME;
			self.weaponentity.frame = FORK_DRAW_START;
		}
		else if (self.weaponentity.anim_type == FIRE)
		{
			self.weaponentity.anim_end = FORK_FIRE_END;
			self.weaponentity.anim_end_num = FORK_FIRE_END - FORK_FIRE_START + 1;
			self.weaponentity.anim_time = FORK_FIRE_TIME;
			self.weaponentity.frame = FORK_FIRE_START;
		}
		else if (self.weaponentity.anim_type == HOLSTER)
		{
			if (self.weaponentity.last_action == DRAW)
			{
				self.weaponentity.anim_end = FORK_HOLSTER_END;
				self.weaponentity.anim_end_num = FORK_HOLSTER_END - FORK_HOLSTER_START + 1;
				self.weaponentity.anim_time = (FORK_HOLSTER_TIME / (FORK_HOLSTER_END - FORK_HOLSTER_START + 1)) * (self.weaponentity.frame - FORK_DRAW_START + 1);
				self.weaponentity.attack_finished = time + self.weaponentity.anim_time;
				self.weaponentity.frame = FORK_HOLSTER_END - (self.weaponentity.frame - FORK_DRAW_START + 1) + 1;
			}
			else
			{
				self.weaponentity.anim_end = FORK_HOLSTER_END;
				self.weaponentity.anim_end_num = FORK_HOLSTER_END - FORK_HOLSTER_START + 1;
				self.weaponentity.anim_time = FORK_HOLSTER_TIME;
				self.weaponentity.frame = FORK_HOLSTER_START;
			}
		}
		self.weaponentity.last_action = self.weaponentity.anim_type;
	}
	self.weaponentity.nextthink = time + (self.weaponentity.anim_time / self.weaponentity.anim_end_num);
	self.weaponentity.think = fork_animate;

	if (self.weaponentity.anim_type == FIRE)
	{
		if (self.weaponentity.frame == FORK_FIRE_START + 2)
			Fork_Fire();
		if (self.weaponentity.frame == FORK_FIRE_END && (!self.button0 || !self.button3))
		{
			self.owner.player_state = PS_IDLE;
			Fork_Idle();
		}
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && (self.weaponentity.anim_type == DRAW))
	{
		self.owner.player_state = PS_IDLE;
		Fork_Idle();
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && (self.weaponentity.anim_type == HOLSTER))
	{
		setmodel(self.weaponentity, "");
		W_DrawWeapon(self.owner.newweapon);
		return;
	}
};
