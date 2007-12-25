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

void() remote_animate;

/*
================
ActivateRemoteBombs

Make all remote bombs owned by "self" explode
================
*/
void() ActivateRemoteBombs =
{
	local entity grenadeEnt;
	local entity tempEnt;

	grenadeEnt = find(world, classname, "grenade");
	while (grenadeEnt)
	{
		if (grenadeEnt.enemy == self)
			if (grenadeEnt.netname == "Remote Detonator")
			{
				sound(grenadeEnt, CHAN_BODY, "weapons/tnt/remdet.wav", 1, ATTN_NORM);
				tempEnt = self;
				self = grenadeEnt;
				Bomb_Trigger();
				self = tempEnt;
			}
			grenadeEnt = find(grenadeEnt, classname, "grenade");
	}
};

/*
============
Remote_Attack

Attack code for the remote detonator
============
*/
void() Remote_Attack =
{
	if (self.button0)
	{
		if (self.weaponentity.tnt_type) // We only have the remote
		{
			self.button0 = 0;
			sound(self, CHAN_WEAPON, "weapons/tnt/remfire.wav", 1, ATTN_NORM);
			ActivateRemoteBombs();
			self.weaponentity.attack_finished = time + REMOTE_DRAW_TIME;
			self.weaponentity.anim_type = HALF_DRAW;
			self.player_state = PS_DRAW;
			if (self.currentammo <= 0)
			{
				self.items = self.items - self.weapon;
				setmodel(self.weaponentity, "");
				W_DrawWeapon(W_BestWeapon());
			}
		}
		else
		{
			//Hack so that we can hold it as long as we want, its set properly when we throw it
			self.weaponentity.attack_finished = time + 99999;
			self.weaponentity.anim_type = IDLE;
			self.weaponentity.charge = 1;
			self.player_state = PS_CHARGE;
			ShowThrowMeter();
		}
	}
	else if (self.button3)// Altfire
	{
		if (self.weaponentity.tnt_type) // If we only have a remote, draw another bomb
		{
			self.weaponentity.anim_type = HALF_DRAW;
			self.weaponentity.attack_finished = time + REMOTE_DRAW_TIME;
			self.player_state = PS_DRAW;
		}
		else
		{
			self.weaponentity.charge = 0;
			self.weaponentity.attack_finished = time + REMOTE_DROP_TIME;
			self.weaponentity.anim_type = IDLE_WITH_REMOTE;
			self.weaponentity.tnt_type = REMOTE_ONLY;
			self.player_state = PS_FIRE;
			Bomb_Fire();
			Bomb_Uncharge();
		}
	}
	self.weaponentity.nextthink = time;
	self.weaponentity.think = remote_animate;
};

/*
============
Remote_Draw

Draw code for the remote detonator
============
*/
void() Remote_Draw =
{
	self.weapon = IT_REMOTE_DETONATOR;
	self.currentammo = self.ammo_tnt_remote;
	Remote_UpdateView();
	self.weaponentity.attack_finished = time + REMOTE_DRAW_TIME;
	self.player_state = PS_DRAW;
	self.weaponentity.tnt_type = REMOTE_AND_BOMB;
	self.weaponentity.anim_type = DRAW;
	self.weaponentity.frame = REMOTE_DRAW_START;
	self.weaponentity.skin = 1;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = remote_animate;
};

/*
============
Remote_Holster

Holster code for the remote detonator
============
*/
void() Remote_Holster =
{
	self.weaponentity.attack_finished = time + REMOTE_HOLSTER_TIME;
	if (self.weaponentity.tnt_type) //Only holding a remote
		self.weaponentity.anim_type = HALF_HOLSTER;
	else
		self.weaponentity.anim_type = HOLSTER;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = remote_animate;
};

/*
============
Remote_UpdateView

Choose the right remote detonator model to display
============
*/
void() Remote_UpdateView =
{
	setmodel(self.weaponentity, "models/weapons/v_remote.md3");
	self.items = self.items - (self.items & IT_GUNS_AKIMBO);
};

/*
============
Remote_Idle
============
*/
void() Remote_Idle =
{
	self.weaponentity.anim_type = IDLE;
	self.weaponentity.frame = REMOTE_IDLE;

	//self.weaponentity.attack_finished = time + 0.5; // don't throw instantly after detonating.
	self.owner.button0 = 0;
	self.weaponentity.tnt_type = REMOTE_AND_BOMB;
	self.weaponentity.charge = 0;

	self.weaponentity.nextthink = time;
	self.weaponentity.think = remote_animate;
};


/*
============
remote_animate

Animation and frame based code for Remote TNT
============
*/
void() remote_animate =
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
		local float last_action_start;
		if (self.weaponentity.anim_type == IDLE)
		{
			self.weaponentity.anim_end = REMOTE_IDLE;
			self.weaponentity.anim_end_num = REMOTE_IDLE + 1;
			self.weaponentity.anim_time = REMOTE_IDLE_TIME;
			self.weaponentity.frame = REMOTE_IDLE;
		}
		else if (self.weaponentity.anim_type == IDLE_WITH_REMOTE)
		{
			self.weaponentity.anim_end = REMOTE_THROW_END;
			self.weaponentity.anim_end_num = 1;
			self.weaponentity.anim_time = REMOTE_IDLE_TIME;
			self.weaponentity.frame = REMOTE_THROW_END;
		}
		else if (self.weaponentity.anim_type == DRAW)
		{
			self.weaponentity.anim_end = REMOTE_DRAW_END;
			self.weaponentity.anim_end_num = REMOTE_DRAW_END - REMOTE_DRAW_START + 1;
			self.weaponentity.anim_time = REMOTE_DRAW_TIME;
			self.weaponentity.frame = REMOTE_DRAW_START;
		}
		else if (self.weaponentity.anim_type == HALF_DRAW)
		{
			self.weaponentity.anim_end = REMOTE_HALF_DRAW_END;
			self.weaponentity.anim_end_num = REMOTE_HALF_DRAW_END - REMOTE_HALF_DRAW_START + 1;
			self.weaponentity.anim_time = REMOTE_DRAW_TIME; //possibly divide by 2?
			self.weaponentity.frame = REMOTE_HALF_DRAW_START;
		}
		else if (self.weaponentity.anim_type == FIRE)
		{
			self.weaponentity.anim_end = REMOTE_FIRE_END;
			self.weaponentity.anim_end_num = REMOTE_FIRE_END - REMOTE_FIRE_START + 1;
			self.weaponentity.anim_time = REMOTE_FIRE_TIME;
			self.weaponentity.frame = REMOTE_FIRE_START;
		}
		else if (self.weaponentity.anim_type == THROW)
		{
			self.weaponentity.anim_end = REMOTE_THROW_END;
			self.weaponentity.anim_end_num = REMOTE_THROW_END - REMOTE_THROW_START + 1;
			self.weaponentity.anim_time = REMOTE_THROW_TIME;
			self.weaponentity.frame = REMOTE_THROW_START;
		}
		else if (self.weaponentity.anim_type == HOLSTER)
		{
			if ((self.weaponentity.last_action == DRAW) || (self.weaponentity.last_action == HALF_DRAW))
			{
				if (self.weaponentity.last_action == DRAW)
					last_action_start = REMOTE_DRAW_START;
				else //if (self.weaponentity.last_action == HALF_DRAW)
					last_action_start = REMOTE_HALF_DRAW_START;
				self.weaponentity.anim_end = REMOTE_HOLSTER_END;
				self.weaponentity.anim_end_num = REMOTE_HOLSTER_END - REMOTE_HOLSTER_START + 1;
				self.weaponentity.anim_time = (REMOTE_HOLSTER_TIME / (REMOTE_HOLSTER_END - REMOTE_HOLSTER_START + 1)) * (self.weaponentity.frame - last_action_start + 1);
				self.weaponentity.attack_finished = time + self.weaponentity.anim_time;
				self.weaponentity.frame = REMOTE_HOLSTER_END - (self.weaponentity.frame - last_action_start + 1) + 1;
			}
			else
			{
				self.weaponentity.anim_end = REMOTE_HOLSTER_END;
				self.weaponentity.anim_end_num = REMOTE_HOLSTER_END - REMOTE_HOLSTER_START + 1;
				self.weaponentity.anim_time = REMOTE_HOLSTER_TIME;
				self.weaponentity.frame = REMOTE_HOLSTER_START;
			}
		}
		else if (self.weaponentity.anim_type == HALF_HOLSTER)
		{
			if ((self.weaponentity.last_action == DRAW) || (self.weaponentity.last_action == HALF_DRAW))
			{
				if (self.weaponentity.last_action == DRAW)
					last_action_start = REMOTE_DRAW_START;
				else //if (self.weaponentity.last_action == HALF_DRAW)
					last_action_start = REMOTE_HALF_DRAW_START;
				self.weaponentity.anim_end = REMOTE_HALF_HOLSTER_END;
				self.weaponentity.anim_end_num = REMOTE_HALF_HOLSTER_END - REMOTE_HALF_HOLSTER_START + 1;
				self.weaponentity.anim_time = (REMOTE_HOLSTER_TIME / (REMOTE_HALF_HOLSTER_END - REMOTE_HALF_HOLSTER_START + 1)) * (self.weaponentity.frame - last_action_start + 1);
				self.weaponentity.attack_finished = time + self.weaponentity.anim_time;
				self.weaponentity.frame = REMOTE_HALF_HOLSTER_END - (self.weaponentity.frame - last_action_start + 1) + 1;
			}
			else
			{
				self.weaponentity.anim_end = REMOTE_HALF_HOLSTER_END;
				self.weaponentity.anim_end_num = REMOTE_HALF_HOLSTER_END - REMOTE_HALF_HOLSTER_START + 1;
				self.weaponentity.anim_time = REMOTE_HOLSTER_TIME; // possibly divide by 2?
				self.weaponentity.frame = REMOTE_HALF_HOLSTER_START;
			}
		}
		self.weaponentity.last_action = self.weaponentity.anim_type;
	}
	self.weaponentity.nextthink = time + (self.weaponentity.anim_time / self.weaponentity.anim_end_num);
	self.weaponentity.think = remote_animate;

	if (self.weaponentity.skin == 4)
	{
		self.weaponentity.skin = 3;
		self.weaponentity.ammo_in_chamber = 1; //hack, using another weapons variable, indicating backwards animation
	}
	else if (self.weaponentity.skin == 1)
	{
		self.weaponentity.skin = 2;
		self.weaponentity.ammo_in_chamber = 0; //animation is going forward when 0
	}
	else if (!self.weaponentity.ammo_in_chamber)
		self.weaponentity.skin = self.weaponentity.skin + 1;
	else // ammo_in_chamber == 1
		self.weaponentity.skin = self.weaponentity.skin - 1;

	if (self.owner.button0 && !self.weaponentity.tnt_type) // we have a bomb in hand and holding fire
	{
		if (self.weaponentity.charge < 20)
			self.weaponentity.charge = self.weaponentity.charge + 1;
		ShowThrowMeter();
	}
	else if (self.weaponentity.charge && !self.weaponentity.tnt_type)
	{
		self.weaponentity.anim_type = THROW;
		self.weaponentity.attack_finished = time + REMOTE_THROW_TIME - 0.4; //- 0.4 so we can det it nearly quickly.
		self.owner.player_state = PS_FIRE;
		ShowThrowMeter();
		self.weaponentity.nextthink = time;
	}
	if (self.weaponentity.anim_type == THROW)
	{
		if (self.weaponentity.frame == REMOTE_THROW_END - 1)
		{
			Bomb_Fire();
			Bomb_Uncharge();
			self.weaponentity.tnt_type = REMOTE_ONLY;
		}
		else if (self.weaponentity.frame == REMOTE_THROW_END)
			self.weaponentity.anim_type = IDLE_WITH_REMOTE;
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && ((self.weaponentity.anim_type == DRAW) || (self.weaponentity.anim_type == HALF_DRAW)))
	{
		self.owner.player_state = PS_IDLE;
		Remote_Idle();
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && ((self.weaponentity.anim_type == HOLSTER) || (self.weaponentity.anim_type == HALF_HOLSTER)))
	{
		setmodel(self.weaponentity, "");
		W_DrawWeapon(self.owner.newweapon);
		return;
	}
};
