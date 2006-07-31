/*  Copyright (C) 2001-2002  Dave Turner

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

void() leech_animate;

#define LEECH_IDLE				0
#define LEECH_DRAW_START		1
#define LEECH_DRAW_END			3
#define LEECH_FIRE_START		4
#define LEECH_FIRE_END			28
#define LEECH_HOLSTER_START		29
#define LEECH_HOLSTER_END		31

#define LEECH_IDLE_TIME			0.1
#define LEECH_DRAW_TIME			0.3
#define LEECH_FIRE_TIME			2.6
#define LEECH_HOLSTER_TIME		0.3

//=======================================================================

/*
================
Leech_BallTouch

Touch function for the leech missile
================
*/
void() Leech_BallTouch =
{
	if (other == self.owner)
		return;     // don't explode on owner

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	self.deathtype = "leech";  // Done for the fire code.
	if (other.takedamage)
	{
		other.deathtype = "leech";
		BurnDamage(other, self, self.dmg, DF_SPIRIT, self.dmg * 0.1, 5);
	}

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
=========================
Leech_BallFire

Fire a Life Leech ball
=========================
*/
void() Leech_BallFire =
{
	local vector spread;

	self.punchangle_x = -2;
	muzzleflash();

	newmis = spawn();

	makevectors(self.v_angle);
	newmis.velocity = aim(self, 1000);  // base velocity

	// If aim() hasn't found any interesting target, add some spread
	traceline(self.origin, self.origin + newmis.velocity*2048, FALSE, self);
	if (trace_ent == world)
		spread = crandom() * 0.18 * v_right + crandom() * 0.08 * v_up;
	else
		spread = '0 0 0';
	newmis.velocity = 1500 * (newmis.velocity + spread);

	newmis.owner = self;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "missile";
	newmis.angles = vectoangles(newmis.velocity);
	newmis.movetype = MOVETYPE_FLYMISSILE;

	// If we don't have enough ammo, use HP
	if (self.ammo_leech < 2)
	{
		T_Damage(self, world, self, 2 - self.ammo_leech, DF_SPIRIT, "leech");
		self.ammo_leech = 0;
	}
	else
		self.ammo_leech = self.ammo_leech - 2;
	self.currentammo = self.ammo_leech;

	newmis.touch = Leech_BallTouch;
	setmodel(newmis, "progs/leechball.spr");
	newmis.skin = 1;
	setsize(newmis, '0 0 0', '0 0 0');
	setorigin(newmis, self.origin + self.view_ofs + VEC_WEAPON_OFS + v_forward * 8);

	newmis.dmg = 40;

	// set newmis duration
	newmis.nextthink = time + 5;
	newmis.think = SUB_Remove;
	newmis.reset = SUB_Remove;
};

/*
================
Leech_AltBallTouch

Touch function for the leech altfire missile
================
*/
void() Leech_AltBallTouch =
{
	// Don't explode on owner (the Life Leech)
	if (other == self.owner)
		return;

	// Switch ownership from the Life Leech itself to the LL owner
	self.owner = self.owner.leech_sentry;

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	// If we can damage the entity we touch
	if (other.takedamage)
		T_Damage(other, self, self.owner, self.dmg, DF_SPIRIT, "leech");

	sound(self, CHAN_AUTO, "weapons/napalm/explodfs.wav", 1, ATTN_NORM);
	remove(self);
};

/*
==================
Leech_Think

Dropped LL think function
==================
*/
void() Leech_Think =
{
	local float diff, bestdiff;
	local entity ent, bestent;
	local vector ballorigin;

	self.owner = world;  // the LL must be able to touch its owner
	self.nextthink = time + 0.75;
	ballorigin = self.origin + '0 0 45';

	// Look for a target (the closer, the better)
	bestdiff = 10000;
	bestent = world;
	ent = findradius (self.origin, 500);
	while (ent != world)
	{
		if (ent.takedamage)
			// If it's a player
			if (ent.classname == "player" || (ent.flags & FL_MONSTER))
				// If he's a valid target (not the owner or a player from the same team)
				if (ent != self.leech_sentry && 
					(gametype == GT_BLOODBATH || gametype == GT_COOPERATIVE || gametype == GT_SINGLE_PLAYER || ent.team != self.team))
				{
					// If he's closer than our current choice
					diff = vlen(ent.origin - ballorigin);
					if (diff < bestdiff)
					{
						// If he's visible
						traceline(ballorigin, ent.origin, FALSE, self);
						if (trace_ent == ent)
						{
							bestent = ent;
							bestdiff = diff;
						}
					}
				}

				ent = ent.chain;
	}

	// If we haven't find a target, there's nothing to do
	if (bestent == world)
		return;

	// Fire a ball of energy on the target
	newmis = spawn();
	newmis.owner = self;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "missile";
	newmis.velocity = 1500 * normalize(bestent.origin - ballorigin);
	newmis.angles = vectoangles(newmis.velocity);
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.touch = Leech_AltBallTouch;
	setmodel(newmis, "progs/teslaball.spr");  // the tesla ball is closer to the original look
	setsize(newmis, '0 0 0', '0 0 0');
	setorigin(newmis, ballorigin);
	newmis.dmg = 15;
	newmis.alpha  = 0.5;
	newmis.reset = SUB_Remove;
};

/*
==================
Leech_FadeOut

Used when a LL sentry fades out (when dying)
==================
*/
void() Leech_FadeOut =
{
	if (self.alpha > 0.1)  // Warning: alpha = 0.0 means opaque
	{
		self.alpha = self.alpha - 0.1;
		self.nextthink = time + 0.1;
	}
	else
		remove(self);
};

/*
==================
Leech_Reset

Reset function for a LL sentry
==================
*/
void() Leech_Reset =
{
	self.leech_sentry.leech_sentry = world;
	remove(self);
};

/*
==================
Leech_Die

Die function for a LL sentry
==================
*/
void() Leech_Die =
{
	self.leech_sentry.leech_sentry = world;
	sound(self, CHAN_VOICE, "weapons/lifelech/llaltht.wav", 1, ATTN_NORM);

	KillBurner(self);

	// If the engine supports the QC extension DP_ENT_ALPHA, make it fade out
	if (checkextension ("DP_ENT_ALPHA"))
	{
		self.solid = SOLID_NOT;
		self.takedamage = DAMAGE_NO;
		self.movetype = MOVETYPE_NONE;
		self.effects = 0;
		self.alpha = 1;

		self.touch = SUB_Null;
		self.th_die = SUB_Remove;
		self.think = Leech_FadeOut;
		self.nextthink = time + 0.1;
	}
	else
		remove(self);
};

/*
==================
Leech_Use

Use function for a LL sentry
==================
*/
void() Leech_Use =
{
	// If it's the owner, he takes back his Life Leech
	if (self.leech_sentry == other)
	{
		other.items = other.items + IT_LIFE_LEECH;
		other.leech_sentry = world;
		other.ammo_leech = other.ammo_leech + self.ammo_leech;
		sound(other, CHAN_ITEM, "items/weaponup.wav", 1, ATTN_NORM);
		remove(self);
	}

	SUB_SolidTouch();
};

/*
==================
Leech_Drop

Drop the Life Leech as a solid staff (altfire)
==================
*/
void() Leech_Drop =
{
	local entity item;

	makevectors(self.v_angle);

	// Drop the Life Leech
	item = spawn();
	setmodel(item, "models/weapons/g_leech.md3");
	setsize(item, '-6 -6 0', '6 8 60');

	item.classname = "sentry";
	item.owner = self;             // we don't want to trigger the touch function yet
	item.leech_sentry = self;      // we can't use "owner" because the owner of an entity is never clipped against it
	item.team = self.team;
	item.solid = SOLID_SLIDEBOX;
	item.takedamage = DAMAGE_AIM;
	item.health = 300;

	item.origin = self.origin + '0 0 12' + v_forward * 8;
	item.velocity = aim(self, 1000) * 50;
	item.velocity_z = 150;
	item.movetype = MOVETYPE_TOSS;

	if (cvar("g_flashyEffects"))
		item.effects = item.effects | EF_FLAME;

	// Sentry mode
	item.spawnflags = item.spawnflags | SF_USABLE;
	item.nextthink = time + 1.5;
	item.think = Leech_Think;
	item.use = Leech_Use;
	item.th_die = Leech_Die;
	item.reset = Leech_Reset;

	/* TIM- Tested this against SP blood, and this wasn't how SP blood handled LL sentry.

	// Dropping it requires 25 ammo/HP
	if (self.ammo_leech < 25)
	{
		T_Damage(self, world, self, 25 - self.ammo_leech, DF_SPIRIT, "leech");
		item.ammo_leech = 0;
	}
	else
		item.ammo_leech = self.ammo_leech - 25;
	*/
	self.currentammo = self.ammo_leech = 0;
	self.items = self.items - self.weapon;
	self.leech_sentry = item;

	// If we're still alive
	if (!self.deadflag)
	{
		remove(self.weaponentity);
		self.newweapon = W_BestWeapon();
		W_DrawWeapon(self.newweapon);
	}
};

/*
======================
Leech_Attack

Life Leech Attack Code
======================
*/
void() Leech_Attack =
{
	if (self.weaponentity.attack_finished < time)
	{
		if (self.button3) //Altfire
		{
			self.player_state = PS_ALTFIRE;
			Leech_Drop();
			self.attack_finished = time + 0.1;
		}
		else // Normal fire
		{
			self.player_state = PS_FIRE;
			self.weaponentity.attack_finished = time + LEECH_FIRE_TIME;
			self.weaponentity.anim_type = FIRE;
			leech_animate();
		}
	}
};

/*
============
Leech_Draw

Draw code for the life leech
============
*/
void() Leech_Draw =
{
	self.weapon = IT_LIFE_LEECH;
	self.currentammo = self.ammo_leech;
	self.weaponentity = spawn();
	self.weaponentity.solid = SOLID_NOT;
	self.weaponentity.owner = self;
	self.weaponentity.weaponentity = self.weaponentity;
	self.weaponentity.origin = '0 0 0';
	self.weaponentity.angles = '0 0 0';
	self.weaponentity.viewmodelforclient = self;

	Leech_UpdateView();
	self.weaponentity.attack_finished = time + LEECH_DRAW_TIME;
	self.weaponentity.anim_type = DRAW;
	leech_animate();
};

/*
============
Leech_Holster

Holster code for the life leech
============
*/
void() Leech_Holster =
{
	self.attack_finished = time + LEECH_HOLSTER_TIME;
	self.weaponentity.anim_type = HOLSTER;
	leech_animate();
};

/*
============
Leech_UpdateView

Choose the right life leech model to display
============
*/
void() Leech_UpdateView =
{
	setmodel(self.weaponentity, "models/weapons/v_leech.md3");
	self.items = self.items - (self.items & IT_GUNS_AKIMBO);
};

void() Leech_Idle =
{
	self.weaponentity.anim_type = IDLE;
	self.player_state = PS_IDLE;
	self.weaponentity.frame = LEECH_IDLE;
	leech_animate();
};

/*
============
leech_animate

Animation and frame based code for the Life Leech
============
*/
void() leech_animate =
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
			self.weaponentity.anim_end = LEECH_IDLE;
			self.weaponentity.anim_end_num = LEECH_IDLE + 1;
			self.weaponentity.anim_time = LEECH_IDLE_TIME;
			self.weaponentity.frame = LEECH_IDLE;
		}
		else if (self.weaponentity.anim_type == DRAW)
		{
			self.weaponentity.anim_end = LEECH_DRAW_END;
			self.weaponentity.anim_end_num = LEECH_DRAW_END - LEECH_DRAW_START + 1;
			self.weaponentity.anim_time = LEECH_DRAW_TIME;
			self.weaponentity.frame = LEECH_DRAW_START;
		}
		else if (self.weaponentity.anim_type == FIRE)
		{
			self.weaponentity.anim_end = LEECH_FIRE_END;
			self.weaponentity.anim_end_num = LEECH_FIRE_END - LEECH_FIRE_START + 1;
			self.weaponentity.anim_time = LEECH_FIRE_TIME;
			self.weaponentity.frame = LEECH_FIRE_START;
		}
		else if (self.weaponentity.anim_type == HOLSTER)
		{
			self.weaponentity.anim_end = LEECH_HOLSTER_END;
			self.weaponentity.anim_end_num = LEECH_HOLSTER_END - LEECH_HOLSTER_START + 1;
			self.weaponentity.anim_time = LEECH_HOLSTER_TIME;
			self.weaponentity.frame = LEECH_HOLSTER_START;
		}
		self.weaponentity.last_action = self.weaponentity.anim_type;
	}
	if (self.weaponentity.anim_type != IDLE)
	{
		self.nextthink = time + (self.weaponentity.anim_time / self.weaponentity.anim_end_num);
		self.think = leech_animate;
	}

	if (self.weaponentity.anim_type == FIRE)
	{
		if (self.weaponentity.frame == LEECH_FIRE_START)
			sound(self, CHAN_WEAPON, "weapons/lifelech/laltfr1.wav", 1, ATTN_NORM);
		else if (self.weaponentity.frame == LEECH_FIRE_START + 4 ||
			self.weaponentity.frame == LEECH_FIRE_START + 7 ||
			self.weaponentity.frame == LEECH_FIRE_START + 10 ||
			self.weaponentity.frame == LEECH_FIRE_START + 13 ||
			self.weaponentity.frame == LEECH_FIRE_START + 15 ||
			self.weaponentity.frame == LEECH_FIRE_START + 18 ||
			self.weaponentity.frame == LEECH_FIRE_START + 21)
			Leech_BallFire();
		else if (self.weaponentity.frame == LEECH_FIRE_END)
			Leech_Idle();
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && (self.weaponentity.anim_type == DRAW))
	{
		self.nextthink = time + LEECH_DRAW_TIME;
		self.think = Leech_Idle;
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && (self.weaponentity.anim_type == HOLSTER))
	{
		remove(self.weaponentity);
		W_DrawWeapon(self.newweapon);
		return;
	}
};