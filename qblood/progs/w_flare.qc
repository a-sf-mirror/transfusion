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

void() FlareThink;
void() flare_animate;

#define FLARE_IDLE					0
#define FLARE_DRAW_START			1
#define FLARE_DRAW_END				4
#define FLARE_FIRE_START			5
#define FLARE_FIRE_END				16
#define FLARE_HOLSTER_START			17
#define FLARE_HOLSTER_END			20
#define FLARE_AKIMBO_REFERENCE		0
#define FLARE_AKIMBO_IDLE			1
#define FLARE_AKIMBO_DRAW_START		2
#define FLARE_AKIMBO_DRAW_END		5
#define FLARE_AKIMBO_FIRE_START		6
#define FLARE_AKIMBO_FIRE_END		20
#define FLARE_AKIMBO_HOLSTER_START	21
#define FLARE_AKIMBO_HOLSTER_END	24

#define FLARE_IDLE_TIME				0.1
#define FLARE_DRAW_TIME				0.3
#define FLARE_FIRE_TIME				0.5
#define FLARE_HOLSTER_TIME			0.3

//============================================================================

/*
================
FlareSpark

This causes the flare to emit sparks
================
*/
void() FlareSpark =
{
	// FIXME:  Use better particle effects -- custom source port recommended.
	particle (self.origin, '0 0 50', 195, 32);
};

/*
================
FlareTouch

Called when flare impacts.
================
*/
void() FlareTouch =
{
	if (pointcontents(self.origin) == CONTENT_SKY || other.solid == SOLID_TRIGGER)
	{
		remove(self);
		return;
	}

	if (other.takedamage && !(other.flags & FL_MONSTER))
		BurnDamage(other, self, self.dmg, DF_BURN, self.charge, self.dmgtime);

	FlareSpark();   // Throw a few sparks.

	if (other.classname == "player" || (other.flags & FL_MONSTER))
	{
		self.alpha = 0.1;
		self.solid = SOLID_NOT;
		self.enemy = other;
		self.movetype = MOVETYPE_NONE;
		self.v_angle = self.enemy.origin - self.origin;
		self.effects = EF_STARDUST;

		// Flares stick for max of 6 seconds
		self.attack_finished = time + 6;
		FlareThink();
	}
	else
		remove(self);
};

void() FlareThink =
{
	if (self.attack_finished < time ||  // flare is burnt out
		self.enemy.health <=0)          // enemy is dead
		remove(self);

	if (!VecInWater(self.origin) && self.enemy.flags & FL_MONSTER)
	{
		Ignite(self.enemy, self, DF_BURN, 10, 1);
		T_Damage(self.enemy, self, self.owner, 1, DF_BURN, "fire");
	}

	if ((self.enemy.origin - self.origin) != self.v_angle)
		self.origin = self.enemy.origin + self.v_angle;

	self.nextthink = time + 0.1;
	self.think = FlareThink;
};

/*
================
NewFlare

Spawns and returns a brand new flare
================
*/
entity(entity attacker, vector spot) NewFlare =
{
	local   entity  fire;

	fire = spawn();

	setmodel(fire, "models/weapons/objects/flare.md3");
	setsize(fire, '0 0 0', '0 0 0');
	setorigin(fire, spot);

	fire.solid      = SOLID_NOT;
	fire.takedamage = DAMAGE_NO;
	fire.frame      = 0;
	fire.skin       = 1;  // use purplish skin
	fire.owner      = attacker;
	fire.classname  = "flare";
	fire.netname    = "flare";

	fire.effects    = EF_LOWPRECISION;
	fire.effects    = fire.effects | EF_STARDUST;
	fire.effects    = fire.effects | EF_DIMLIGHT;
	fire.movetype   = MOVETYPE_FLYMISSILE;
	fire.solid      = SOLID_BBOX;
	fire.reset      = SUB_Remove;

	return fire;
};

/*
================
AltFlareTouch

Called when flare impacts
================
*/
void() AltFlareTouch =
{
	if (other.solid == SOLID_TRIGGER)
	return;

	// If the flare hasn't been splitted yet, act as a big normal flare
	if (self.think != SUB_Remove)
	{
		self.dmg = 1;
		self.charge = 18;
		self.dmgtime = 5;
		FlareTouch();
		return;
	}

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	// Explode!
	muzzleflash();

	// Do the damage.
	BurnRadius(self, 120, self.dmg, self.cnt, other);
	self.origin = self.origin - 8*normalize(self.velocity);
	if (other.takedamage)
		BurnDamage(other, self, self.dmg, DF_BURN, self.cnt, self.dmgtime);

	// Make some fire.
	self.solid = SOLID_NOT;     // So embers can't touch 'self'.
	PsychoCaleb(self.owner);
	sound(self, CHAN_AUTO, "weapons/napalm/explodfs.wav", 1, ATTN_NORM);
	BecomeOldExplosion();
};

/*
================
AltFlareSplit

This causes the flare to change its path in mid-flight
================
*/
void() AltFlareSplit =
{
	local   entity  fire;
	local   vector  dir, spread;
	local   float   loop;

	dir = normalize(self.velocity);
	dir = vectoangles(dir);
	dir_x = 0 - dir_x;
	makevectors(dir);

	// Create eight new flares.
	loop = 8;
	while (loop > 0)
	{
		if (loop == 8)
			spread = '1 0 0.15';
		else if (loop == 7)
			spread = '1 0.15 0';
		else if (loop == 6)
			spread = '1 0 -0.15';
		else if (loop == 5)
			spread = '1 -0.15 0';
		else if (loop == 4)
			spread = '1 0.05 0.05';
		else if (loop == 3)
			spread = '1 -0.05 0.05';
		else if (loop == 2)
			spread = '1 -0.05 -0.05';
		else if (loop == 1)
			spread = '1 0.05 -0.05';
		else
			spread = '1 0 0';   // This shouldn't happen.

		dir = (v_forward * spread_x) + (v_right * spread_y) + (v_up * spread_z);
		dir = normalize(dir);

		fire = NewFlare (self.owner, self.origin);
		fire.angles     = vectoangles(dir) + '90 0 0';
		fire.velocity   = dir * self.speed;
		fire.touch      = AltFlareTouch;
		fire.nextthink  = self.pausetime;
		fire.think      = SUB_Remove;
		fire.cnt        = self.cnt;
		fire.dmg        = self.dmg;
		fire.dmgtime    = self.dmgtime;
		fire.speed      = self.speed;
		fire.distance   = self.distance;

		loop = loop - 1;
	}

	// Remove the old flare.
	remove(self);
};

/*
================
FireAltFlares

Create and launch a small fireball
================
*/
void(entity attacker, vector org, vector dir, float sped, float damage, float burn, float burntime) FireAltFlares =
{
	local   entity  fire;

	fire = NewFlare(attacker, org);
	fire.angles     = vectoangles(dir) + '90 0 0';
	fire.velocity   = dir * sped;
	fire.touch      = AltFlareTouch;
	fire.nextthink  = time + 0.4;   // Approximate time alt-flares split.
	fire.think      = AltFlareSplit;
	fire.pausetime  = time + (8000 / sped);
	fire.cnt        = burn;
	fire.dmgtime    = burntime;
	fire.dmg        = damage;
	fire.speed      = sped;
	fire.distance   = 0.8;  // Damage is 80% at max radius.
};

/*
================
FireFlare

Create and launch a normal flare
================
*/
void(entity attacker, vector org, vector dir, float sped) FireFlare =
{
	local   entity  fire;

	fire = NewFlare(attacker, org);
	fire.angles     = vectoangles(dir) + '90 0 0';
	fire.velocity   = dir * sped;
	fire.touch      = FlareTouch;
	fire.nextthink  = time + (8000 / sped);
	fire.think      = SUB_Remove;
	fire.dmg        = 1;        // So players can use it to trigger things
	fire.charge     = 15;       // 15 points of damage per second
	fire.dmgtime    = 4;        // ... for 4 seconds
};

/*
================
Flare_Fire

Launch a flare
================
*/
void(float hand) Flare_Fire =
{
	local vector dir;
	local float  mspeed;

	sound(self.owner, CHAN_WEAPON, "weapons/flaregun/flaref.wav", 1, ATTN_NORM);

	self.owner.punchangle_x = -2;

	// Spawn the flare a little ahead of the player
	local vector orig;
	makevectors(self.owner.v_angle);

	mspeed = 1000;
	dir = aim(self.owner, mspeed);

	if (self.owner.items & IT_GUNS_AKIMBO)
	{
		if (hand == RIGHT)
			orig = W_Origin() + v_right * 10 + v_up * -5;
		else
			orig = W_Origin() + v_right * -16 + v_up * -5;
	}
	else
		orig = W_Origin() + v_right * 5 + v_up * -5;

	// If we want to (and can) launch alt-flares
	if (self.owner.player_state == PS_ALTFIRE && self.owner.ammo_flare >= 8)
	{
		if (!(self.owner.flags & FL_INFINATE_AMMO))
			self.owner.currentammo = self.owner.ammo_flare = self.owner.ammo_flare - 8;
		FireAltFlares(self.owner, orig, dir, mspeed, 1, 20, 3);
		return;
	}

	if (!(self.owner.flags & FL_INFINATE_AMMO))
		self.owner.currentammo = self.owner.ammo_flare = self.owner.ammo_flare - 1;
	FireFlare(self.owner, orig, dir, mspeed);
};

/*
============
Flare_Attack

Attack code for the flaregun
============
*/
void() Flare_Attack =
{
	if (self.button3) // Altfire
		self.player_state = PS_ALTFIRE;
	else if (self.button0)
		self.player_state = PS_FIRE;

	if (self.items & IT_GUNS_AKIMBO)
		self.weaponentity.anim_type = AKIMBO_FIRE;
	else
		self.weaponentity.anim_type = FIRE;

	self.weaponentity.attack_finished = time + FLARE_FIRE_TIME;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = flare_animate;
};

/*
============
Flare_Draw

Draw code for the flaregun
============
*/
void() Flare_Draw =
{
	self.weaponentity.attack_finished = time + FLARE_DRAW_TIME;
	self.weapon = IT_FLAREGUN;
	self.currentammo = self.ammo_flare;
	Flare_UpdateView();
	self.weaponentity.skin = 0;
	if (self.akimbo_finished > time && self.currentammo >= 2) //akimbo draw
	{
		self.weaponentity.anim_type = AKIMBO_DRAW;
		self.weaponentity.frame = FLARE_AKIMBO_DRAW_START;
	}
	else //normal draw
	{
		self.weaponentity.anim_type = DRAW;
		self.weaponentity.frame = FLARE_DRAW_START;
	}
	self.weaponentity.nextthink = time;
	self.weaponentity.think = flare_animate;
};

/*
============
Flare_Holster

Holster code for the flaregun
============
*/
void() Flare_Holster =
{
	if (self.akimbo_finished > time && self.currentammo >= 2)
		self.weaponentity.anim_type = AKIMBO_HOLSTER;
	else //normal holster
		self.weaponentity.anim_type = HOLSTER;
	self.weaponentity.attack_finished = time + FLARE_HOLSTER_TIME;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = flare_animate;
};

/*
============
Flare_UpdateView

Choose the right flaregun model to display
============
*/
void() Flare_UpdateView =
{
	if (self.akimbo_finished > time && self.currentammo >= 2)
	{
		setmodel(self.weaponentity, "models/weapons/ga_flare.psk");
		self.items = self.items | IT_GUNS_AKIMBO;
	}
	else
	{
		setmodel(self.weaponentity, "models/weapons/v_flare.psk");
		self.items = self.items - (self.items & IT_GUNS_AKIMBO);
	}
};

void() Flare_Idle =
{
	self.weaponentity.anim_type = IDLE;
	self.weaponentity.frame = FLARE_IDLE;
	self.weaponentity.nextthink = time;
	self.weaponentity.think = flare_animate;
};

/*
============
flare_animate

Animation and frame based code for the Flare gun
============
*/
void() flare_animate =
{
	if (self.weaponentity.anim_type == self.weaponentity.last_action)
	{
		if (self.weaponentity.frame != self.weaponentity.anim_end)
			self.weaponentity.frame = self.weaponentity.frame + 1; //if its a new animation type, it will be set to the proper frame next
		else
			self.weaponentity.frame = self.weaponentity.anim_end - self.weaponentity.anim_end_num + 1;
	}
	else
	{
		if (self.weaponentity.anim_type == IDLE)
		{
			self.weaponentity.anim_end = FLARE_IDLE;
			self.weaponentity.anim_end_num = FLARE_IDLE + 1;
			self.weaponentity.anim_time = FLARE_IDLE_TIME;
			self.weaponentity.frame = FLARE_IDLE;
		}
		else if (self.weaponentity.anim_type == DRAW)
		{
			self.weaponentity.anim_end = FLARE_DRAW_END;
			self.weaponentity.anim_end_num = FLARE_DRAW_END - FLARE_DRAW_START + 1;
			self.weaponentity.anim_time = FLARE_DRAW_TIME;
			self.weaponentity.frame = FLARE_DRAW_START;
		}
		else if (self.weaponentity.anim_type == AKIMBO_DRAW)
		{
			self.weaponentity.anim_end = FLARE_AKIMBO_DRAW_END;
			self.weaponentity.anim_end_num = FLARE_AKIMBO_DRAW_END - FLARE_AKIMBO_DRAW_START + 1;
			self.weaponentity.anim_time = FLARE_DRAW_TIME;
			self.weaponentity.frame = FLARE_AKIMBO_DRAW_START;
		}
		else if (self.weaponentity.anim_type == FIRE)
		{
			self.weaponentity.anim_end = FLARE_FIRE_END;
			self.weaponentity.anim_end_num = FLARE_FIRE_END - FLARE_FIRE_START + 1;
			self.weaponentity.anim_time = FLARE_FIRE_TIME;
			self.weaponentity.frame = FLARE_FIRE_START;
		}
		else if (self.weaponentity.anim_type == AKIMBO_FIRE)
		{
			self.weaponentity.anim_end = FLARE_AKIMBO_FIRE_END;
			self.weaponentity.anim_end_num = FLARE_AKIMBO_FIRE_END - FLARE_AKIMBO_FIRE_START + 1;
			self.weaponentity.anim_time = FLARE_FIRE_TIME;
			self.weaponentity.frame = FLARE_AKIMBO_FIRE_START;
		}	
		else if (self.weaponentity.anim_type == HOLSTER)
		{
			if (self.weaponentity.last_action == DRAW)
			{
				self.weaponentity.anim_end = FLARE_HOLSTER_END;
				self.weaponentity.anim_end_num = FLARE_HOLSTER_END - FLARE_HOLSTER_START + 1;
				self.weaponentity.anim_time = (FLARE_HOLSTER_TIME / (FLARE_HOLSTER_END - FLARE_HOLSTER_START + 1)) * (self.weaponentity.frame - FLARE_DRAW_START + 1);
				self.weaponentity.attack_finished = time + self.weaponentity.anim_time;
				self.weaponentity.frame = FLARE_HOLSTER_END - (self.weaponentity.frame - FLARE_DRAW_START + 1) + 1;
			}
			else
			{
				self.weaponentity.anim_end = FLARE_HOLSTER_END;
				self.weaponentity.anim_end_num = FLARE_HOLSTER_END - FLARE_HOLSTER_START + 1;
				self.weaponentity.anim_time = FLARE_HOLSTER_TIME;
				self.weaponentity.frame = FLARE_HOLSTER_START;
			}
		}
		else if (self.weaponentity.anim_type == AKIMBO_HOLSTER)
		{
			if (self.weaponentity.last_action == AKIMBO_DRAW)
			{
				self.weaponentity.anim_end = FLARE_AKIMBO_HOLSTER_END;
				self.weaponentity.anim_end_num = FLARE_AKIMBO_HOLSTER_END - FLARE_AKIMBO_HOLSTER_START + 1;
				self.weaponentity.anim_time = (FLARE_HOLSTER_TIME / (FLARE_AKIMBO_HOLSTER_END - FLARE_AKIMBO_HOLSTER_START + 1)) * (self.weaponentity.frame - FLARE_DRAW_START + 1);
				self.weaponentity.attack_finished = time + self.weaponentity.anim_time;
				self.weaponentity.frame = FLARE_AKIMBO_HOLSTER_END - (self.weaponentity.frame - FLARE_AKIMBO_DRAW_START + 1) + 1;
			}
			else
			{
				self.weaponentity.anim_end = FLARE_AKIMBO_HOLSTER_END;
				self.weaponentity.anim_end_num = FLARE_AKIMBO_HOLSTER_END - FLARE_AKIMBO_HOLSTER_START + 1;
				self.weaponentity.anim_time = FLARE_HOLSTER_TIME;
				self.weaponentity.frame = FLARE_AKIMBO_HOLSTER_START;
			}
		}
		self.weaponentity.last_action = self.weaponentity.anim_type;
	}
	if (self.weaponentity.anim_type != IDLE)
	{
		self.weaponentity.nextthink = time + (self.weaponentity.anim_time / self.weaponentity.anim_end_num);
		self.weaponentity.think = flare_animate;
	}

	if (self.weaponentity.anim_type == FIRE)
	{
		if (self.weaponentity.frame <= FLARE_FIRE_START + 4)
			self.owner.frame = PLAYER_ATTACK_START;
		else
			self.owner.frame = PLAYER_ATTACK_END;
		if (self.weaponentity.frame == FLARE_FIRE_START)
		{
			muzzleflash();
			Flare_Fire(RIGHT);
		}
		if (self.weaponentity.frame == FLARE_FIRE_END)
		{
			if ((!self.button0) || (!self.button3))
			{
				self.owner.player_state = PS_IDLE;
				Flare_Idle();
			}
		}
	}
	else if (self.weaponentity.anim_type == AKIMBO_FIRE)
	{
		if (self.weaponentity.frame == FLARE_AKIMBO_FIRE_START || self.weaponentity.frame == FLARE_AKIMBO_FIRE_START + 2)
			self.owner.frame = PLAYER_ATTACK_START;
		else
			self.owner.frame = PLAYER_ATTACK_END;
		if (self.weaponentity.frame == FLARE_AKIMBO_FIRE_START)
		{
			muzzleflash();
			Flare_Fire(RIGHT);
		}			
		else if (self.weaponentity.frame == FLARE_AKIMBO_FIRE_START + 5)
		{
			muzzleflash();
			Flare_Fire(LEFT);
		}
		if (self.weaponentity.frame == FLARE_AKIMBO_FIRE_END)
		{
			// If we don't have enough ammo anymore, drop the guns akimbo
			if ((self.items & IT_GUNS_AKIMBO) && self.currentammo < 2)
				self.weaponentity.frame = FLARE_AKIMBO_FIRE_START;

			if ((!self.button0) || (!self.button3))
			{
				self.owner.player_state = PS_IDLE;
				Flare_Idle();
			}
		}
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && ((self.weaponentity.anim_type == DRAW) || (self.weaponentity.anim_type == AKIMBO_DRAW)))
	{
		self.owner.player_state = PS_IDLE;
		Flare_Idle();
	}
	else if ((self.weaponentity.frame == self.weaponentity.anim_end) && ((self.weaponentity.anim_type == HOLSTER) || (self.weaponentity.anim_type == AKIMBO_HOLSTER)))
	{
		setmodel(self.weaponentity, "");
		W_DrawWeapon(self.owner.newweapon);
		return;
	}
	else if (self.weaponentity.anim_type == IDLE)
		self.weaponentity.think = Flare_Idle;
};
