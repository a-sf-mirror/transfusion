/*  Copyright (C) 2001-2002  Mathieu Olivier

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

void() napalm_animate;
void() Napalm_BallTouch;

#define NAPALM_IDLE					0
#define NAPALM_DRAW_START			1
#define NAPALM_DRAW_END				4
#define NAPALM_FIRE_START			5
#define NAPALM_FIRE_END				8
#define NAPALM_HOLSTER_START		9
#define NAPALM_HOLSTER_END			12
#define	NAPALM_AKIMBO_IDLE			0
#define	NAPALM_AKIMBO_DRAW_START	1
#define	NAPALM_AKIMBO_DRAW_END		4
#define NAPALM_AKIMBO_FIRE_START	5
#define	NAPALM_AKIMBO_FIRE_END		10
#define	NAPALM_AKIMBO_HOLSTER_START	11
#define	NAPALM_AKIMBO_HOLSTER_END	14

#define NAPALM_IDLE_TIME			0.08
#define NAPALM_DRAW_TIME			0.3
#define NAPALM_FIRE_TIME			0.5
#define	NAPALM_AKIMBO_FIRE_TIME		0.7
#define NAPALM_HOLSTER_TIME			0.3

//============================================================================

/*
================
Napalm_ActivateBall

Activate the split function of a napalm ball

NOTE: we must do that because the balls are spawned at the same position
      and near walls or floor, so they would explode as soon as they spawn.
================
*/
void() Napalm_ActivateBall =
{
	// We "save" the velocity in the "angles" field
	// right after the bounce
	self.angles = vectoangles (self.velocity);

	self.touch = Napalm_BallTouch;
};

/*
================
Napalm_ThrowBouncingBall

Throw a bouncing napalm ball

NOTE: a few fields ("velocity", "origin" and "cnt") must be set by the caller
================
*/
void(entity newball) Napalm_ThrowBouncingBall =
{
	// Remember who really owns the ball.
	if (self.owner)
		newball.owner = newball.enemy = self.owner;
	else
		newball.owner = newball.enemy = self;



	newball.effects = newball.effects | EF_FLAME;
	newball.movetype = MOVETYPE_BOUNCE;
	newball.solid = SOLID_BBOX;
	newball.classname = "grenade";

	newball.netname = "Napalm Ball";
	newball.dmg = 100;

	newball.nextthink = time + 0.1;
	newball.think = Napalm_ActivateBall;

	newball.reset = SUB_Remove;

	setmodel(newball, "models/weapons/objects/naltball.md3");
	setsize(newball, '0 0 0', '0 0 0');
};

/*
================
T_MissileTouch

Touch function for the rockets
================
*/
void() T_MissileTouch =
{
	if (other == self.owner)
	return;     // don't explode on owner

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	self.deathtype = "missile";  // Done for the fire code.
	self.effects = 0;

	if (other.health)
	{
		other.deathtype = "missile";
		BurnDamage(other, self, self.dmg * 0.75, DF_BURN, 10, (self.dmg * 0.25) / 10);
	}

	// don't do radius damage to "other", because all the damage
	// was done in the impact
	BurnRadius(self, 160, self.dmg * 0.75, self.dmg * 0.5, other);

	// Make detonation sound
	sound(self, CHAN_AUTO, "weapons/napalm/explodcl.wav", 1, ATTN_NORM);

	PsychoCaleb(self.owner);

	self.origin = self.origin - 8 * normalize(self.velocity);

	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord(MSG_BROADCAST, self.origin_x);
	WriteCoord(MSG_BROADCAST, self.origin_y);
	WriteCoord(MSG_BROADCAST, self.origin_z);

	BecomeExplosion();
};

/*
================
Napalm_BallTouch

Touch function for the bouncing ball
================
*/
void() Napalm_BallTouch =
{
	if (self.cnt > 1)
	{
		local entity newball;
		local vector neworig;

		// "self.angles" allows us to recover the original direction
		makevectors(self.angles);

		neworig = self.origin - 8 * normalize(self.velocity);

		newmis = spawn();
		newmis.cnt = floor(self.cnt / 2);
		self.cnt = self.cnt - newmis.cnt;
		newmis.velocity = v_forward * 300 + v_right * 100;
		newmis.velocity_z = random() * 150 + 350;
		Napalm_ThrowBouncingBall(newmis);
		setorigin(newmis, neworig);

		newball = spawn();
		newball.cnt = self.cnt;
		newball.velocity = v_forward * 300 - v_right * 100;
		newball.velocity_z = random() * 150 + 350;
		Napalm_ThrowBouncingBall(newball);
		setorigin(newball, neworig);
	}

	T_MissileTouch();
};

/*
================
Napalm_Fire

Shot a napalm ball
================
*/
void() Napalm_Fire =
{
	sound(self.owner, CHAN_WEAPON, "weapons/napalm/blaster.wav", 1, ATTN_NORM);

	self.owner.punchangle_x = -2;

	newmis = spawn();

	makevectors(self.owner.v_angle);
	newmis.velocity = aim(self.owner, 1000);  // base velocity

	if (self.owner.player_state == PS_ALTFIRE)
	{
		// set the number of bouncing balls
		if (self.owner.ammo_rockets > 12)
			newmis.cnt = 12;
		else
			newmis.cnt = self.owner.ammo_rockets;
		if (!(self.owner.flags & FL_INFINATE_AMMO))
			self.owner.ammo_rockets = self.owner.ammo_rockets - newmis.cnt;
		newmis.velocity = newmis.velocity * 400 + '0 0 200';

		Napalm_ThrowBouncingBall(newmis);
	}
	else
	{        
		newmis.effects = newmis.effects | EF_FLAME;
		newmis.owner = self.owner;
		newmis.solid = SOLID_BBOX;
		newmis.classname = "missile";
		newmis.angles = vectoangles(newmis.velocity);

		newmis.movetype = MOVETYPE_FLYMISSILE;
		newmis.velocity = newmis.velocity * 1500;
		if (!(self.owner.flags & FL_INFINATE_AMMO))
			self.owner.ammo_rockets = self.owner.ammo_rockets - 1;

		newmis.touch = T_MissileTouch;
		setmodel(newmis, "models/weapons/objects/napalm.md3");
		setsize(newmis, '0 0 0', '0 0 0');

		newmis.dmg = 100 + rint(random() * 40);

		// set newmis duration
		newmis.nextthink = time + 5;
		newmis.think = SUB_Remove;
		newmis.reset = SUB_Remove;
	}
	muzzleflash();
	if (!(self.owner.flags & FL_INFINATE_AMMO))
		self.owner.currentammo = self.owner.ammo_rockets;
	setorigin(newmis, W_Origin() + v_forward * 20 + v_right * 3 + v_up * -8);
};

/*
============
Napalm_Attack

Attack code for the napalm launcher
============
*/
void() Napalm_Attack =
{
	// Normal fire or altfire?
	if (self.button3)
		self.player_state = PS_ALTFIRE;
	else if (self.button0)
		self.player_state = PS_FIRE;

	// If we have guns akimbo
	if (self.items & IT_GUNS_AKIMBO)
	{
		self.weaponentity.attack_finished = time + NAPALM_AKIMBO_FIRE_TIME;
		self.weaponentity.anim_type = AKIMBO_FIRE;
	}
	else
	{
		self.weaponentity.attack_finished = time + NAPALM_FIRE_TIME;
		self.weaponentity.anim_type = FIRE;
	}
	self.weaponentity.skin = 0;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = napalm_animate;
};

/*
============
Napalm_Draw

Draw code for the napalm launcher
============
*/
void() Napalm_Draw =
{
	self.weaponentity.attack_finished = time + NAPALM_DRAW_TIME;
	self.weapon = IT_NAPALM_LAUNCHER;
	self.currentammo = self.ammo_rockets;
	Napalm_UpdateView();
	if (self.akimbo_finished > time && self.currentammo >= 2)
	{
		self.weaponentity.anim_type = AKIMBO_DRAW;
		self.weaponentity.frame = NAPALM_AKIMBO_DRAW_START;
	}
	else //normal draw
	{
		self.weaponentity.anim_type = DRAW;
		self.weaponentity.frame = NAPALM_DRAW_START;
	}
	self.weaponentity.skin = 1;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = napalm_animate;
};

/*
============
Napalm_Holster

Holster code for the napalm launcher
============
*/
void() Napalm_Holster =
{
	if (self.akimbo_finished > time && self.currentammo >= 2)
		self.weaponentity.anim_type = AKIMBO_HOLSTER;
	else
		self.weaponentity.anim_type = HOLSTER;
	self.weaponentity.attack_finished = time + NAPALM_HOLSTER_TIME;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = napalm_animate;
};

/*
============
Napalm_UpdateView

Choose the right napalm launcher model to display
============
*/
void() Napalm_UpdateView =
{
	if (self.akimbo_finished > time && self.currentammo >= 2)
	{
		setmodel(self.weaponentity, "models/weapons/ga_napalm.psk");
		self.items = self.items | IT_GUNS_AKIMBO;
	}
	else
	{
		setmodel(self.weaponentity, "models/weapons/v_napalm.psk");
		self.items = self.items - (self.items & IT_GUNS_AKIMBO);
	}
};

void() Napalm_Idle =
{
	if (self.weaponentity.skin == 5)
		self.weaponentity.skin = 1;
	else
		self.weaponentity.skin = self.weaponentity.skin + 1;
	self.weaponentity.anim_type = IDLE;
	self.weaponentity.frame = NAPALM_IDLE;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = napalm_animate;
};

/*
============
napalm_animate

Animation and frame based code for the Napalmn Launcher
============
*/
void() napalm_animate =
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
			self.weaponentity.anim_end = NAPALM_IDLE;
			self.weaponentity.anim_end_num = NAPALM_IDLE + 1;
			self.weaponentity.anim_time = NAPALM_IDLE_TIME;
			self.weaponentity.frame = NAPALM_IDLE;
		}
		else if (self.weaponentity.anim_type == DRAW)
		{
			self.weaponentity.anim_end = NAPALM_DRAW_END;
			self.weaponentity.anim_end_num = NAPALM_DRAW_END - NAPALM_DRAW_START + 1;
			self.weaponentity.anim_time = NAPALM_DRAW_TIME;
			self.weaponentity.frame = NAPALM_DRAW_START;
		}
		else if (self.weaponentity.anim_type == AKIMBO_DRAW)
		{
			self.weaponentity.anim_end = NAPALM_AKIMBO_DRAW_END;
			self.weaponentity.anim_end_num = NAPALM_AKIMBO_DRAW_END - NAPALM_AKIMBO_DRAW_START + 1;
			self.weaponentity.anim_time = NAPALM_DRAW_TIME;
			self.weaponentity.frame = NAPALM_AKIMBO_DRAW_START;
		}
		else if ((self.weaponentity.anim_type == FIRE) || (self.weaponentity.anim_type == ALTFIRE))
		{
			self.weaponentity.anim_end = NAPALM_FIRE_END;
			self.weaponentity.anim_end_num = NAPALM_FIRE_END - NAPALM_FIRE_START + 1;
			self.weaponentity.anim_time = NAPALM_FIRE_TIME;
			self.weaponentity.frame = NAPALM_FIRE_START;
		}
		else if (self.weaponentity.anim_type == AKIMBO_FIRE)
		{
			self.weaponentity.anim_end = NAPALM_AKIMBO_FIRE_END;
			self.weaponentity.anim_end_num = NAPALM_AKIMBO_FIRE_END - NAPALM_AKIMBO_FIRE_START + 1;
			self.weaponentity.anim_time = NAPALM_AKIMBO_FIRE_TIME;
			self.weaponentity.frame = NAPALM_AKIMBO_FIRE_START;
		}
		else if (self.weaponentity.anim_type == HOLSTER)
		{
			if (self.weaponentity.last_action == DRAW)
			{
				self.weaponentity.anim_end = NAPALM_HOLSTER_END;
				self.weaponentity.anim_end_num = NAPALM_HOLSTER_END - NAPALM_HOLSTER_START + 1;
				self.weaponentity.anim_time = (NAPALM_HOLSTER_TIME / (NAPALM_HOLSTER_END - NAPALM_HOLSTER_START + 1)) * (self.weaponentity.frame - NAPALM_DRAW_START + 1);
				self.weaponentity.attack_finished = time + self.weaponentity.anim_time;
				self.weaponentity.frame = NAPALM_HOLSTER_END - (self.weaponentity.frame - NAPALM_DRAW_START + 1) + 1;
			}
			else
			{
				self.weaponentity.anim_end = NAPALM_HOLSTER_END;
				self.weaponentity.anim_end_num = NAPALM_HOLSTER_END - NAPALM_HOLSTER_START + 1;
				self.weaponentity.anim_time = NAPALM_HOLSTER_TIME;
				self.weaponentity.frame = NAPALM_HOLSTER_START;
			}
		}
		else if (self.weaponentity.anim_type == AKIMBO_HOLSTER)
		{
			if (self.weaponentity.last_action == AKIMBO_DRAW)
			{
				self.weaponentity.anim_end = NAPALM_AKIMBO_HOLSTER_END;
				self.weaponentity.anim_end_num = NAPALM_AKIMBO_HOLSTER_END - NAPALM_AKIMBO_HOLSTER_START + 1;
				self.weaponentity.anim_time = (NAPALM_HOLSTER_TIME / (NAPALM_AKIMBO_HOLSTER_END - NAPALM_AKIMBO_HOLSTER_START + 1)) * (self.weaponentity.frame - NAPALM_AKIMBO_DRAW_START + 1);
				self.weaponentity.attack_finished = time + self.weaponentity.anim_time;
				self.weaponentity.frame = NAPALM_AKIMBO_HOLSTER_END - (self.weaponentity.frame - NAPALM_AKIMBO_DRAW_START + 1) + 1;
			}
			else
			{
				self.weaponentity.anim_end = NAPALM_AKIMBO_HOLSTER_END;
				self.weaponentity.anim_end_num = NAPALM_AKIMBO_HOLSTER_END - NAPALM_AKIMBO_HOLSTER_START + 1;
				self.weaponentity.anim_time = NAPALM_HOLSTER_TIME;
				self.weaponentity.frame = NAPALM_AKIMBO_HOLSTER_START;
			}
		}
		self.weaponentity.last_action = self.weaponentity.anim_type;
	}
	self.weaponentity.nextthink = time + (self.weaponentity.anim_time / self.weaponentity.anim_end_num);
	self.weaponentity.think = napalm_animate;

	if ((self.weaponentity.anim_type == FIRE) || (self.weaponentity.anim_type == ALTFIRE))
	{
		if (self.weaponentity.frame == NAPALM_FIRE_START)
			Napalm_Fire();
		else if (self.weaponentity.frame == NAPALM_FIRE_END)
		{
			self.owner.player_state = PS_IDLE;
			Napalm_Idle();
		}
	}
	else if (self.weaponentity.anim_type == AKIMBO_FIRE)
	{
		if ((self.weaponentity.frame == NAPALM_AKIMBO_FIRE_START) || (self.weaponentity.frame == NAPALM_AKIMBO_FIRE_START + 2))
			Napalm_Fire();
		else if (self.weaponentity.frame == NAPALM_AKIMBO_FIRE_END)
		{
			self.owner.player_state = PS_IDLE;
			Napalm_Idle();
		}
	}
	else if (self.weaponentity.anim_type == IDLE)
		self.weaponentity.think = Napalm_Idle;
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && ((self.weaponentity.anim_type == DRAW) || (self.weaponentity.anim_type == AKIMBO_DRAW)))
	{
		self.owner.player_state = PS_IDLE;
		Napalm_Idle();
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && ((self.weaponentity.anim_type == HOLSTER) || (self.weaponentity.anim_type == AKIMBO_HOLSTER)))
	{
		setmodel(self.weaponentity, "");
		W_DrawWeapon(self.owner.newweapon);
		return;
	}
};
