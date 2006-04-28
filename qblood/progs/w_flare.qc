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

void() Flare_Fire;
void () FlareThink;

//============================================================================
// ----- Flaregun model ----- //
// Normal model
$modelname v_flare

/*
#define FLARE_IDLE              0
#define FLARE_DRAW_START        1
#define FLARE_DRAW_END          4
#define FLARE_FIRE_START        5
#define FLARE_FIRE_END          10
#define FLARE_HOLSTER_START     11
#define FLARE_HOLSTER_END       14

#define FLARE_IDLE_TIME         0.1
#define FLARE_DRAW_TIME         0.4
#define FLARE_FIRE_TIME         1.0
#define FLARE_HOLSTER_TIME      0.4
*/


// idle
$frame flare_idle1

// draw
$frame flare_draw1 flare_draw2 flare_draw3

// fire
$frame flare_fire1 flare_fire2 flare_fire3 flare_fire4

// holster
$frame flare_holster1 flare_holster2 flare_holster3


// Akimbo model
$modelname ga_flare

// idle
$frame aflare_idle1

// draw
$frame aflare_draw1 aflare_draw2 aflare_draw3

// fire
$frame aflare_fire1 aflare_fire2 aflare_fire3 aflare_fire4 aflare_fire5

// holster
$frame aflare_holster1 aflare_holster2 aflare_holster3

// ----- Player related code ----- //

// Normal fire
void() player_flare1 = [$attack1, player_flare2] { self.weaponframe = $flare_fire1; };
void() player_flare2 = [$attack1, player_flare3] { self.weaponframe = $flare_fire2; muzzleflash(); Flare_Fire (); };
void() player_flare3 = [$attack2, player_flare4] { self.weaponframe = $flare_fire3; };
void() player_flare4 = [$attack2, player_run   ] { self.weaponframe = $flare_fire4; };

// Akimbo fire
void() player_akflare1 = [$attack1, player_akflare2] { self.weaponframe = $aflare_fire2; muzzleflash (); Flare_Fire (); };
void() player_akflare2 = [$attack2, player_akflare3] { self.weaponframe = $aflare_fire3; };
void() player_akflare3 = [$attack1, player_akflare4] { self.weaponframe = $aflare_fire4; muzzleflash (); Flare_Fire (); };
void() player_akflare4 = [$attack2, player_run     ]
{
	// If we don't have enough ammo anymore, drop the guns akimbo
	if ((self.items & IT_GUNS_AKIMBO) && self.currentammo < 2)
	{
		Flare_UpdateView ();
		self.weaponframe = $aflare_fire1;
	}
	else
		self.weaponframe = $aflare_fire5;
};

// Normal draw
void() player_flaredraw1 = [$attack2, player_flaredraw2] { self.weaponframe = $flare_draw1; };
void() player_flaredraw2 = [$attack2, player_flaredraw3] { self.weaponframe = $flare_draw2; };
void() player_flaredraw3 = [$attack2, player_run       ] { self.weaponframe = $flare_draw3; };

// Normal holster
void() player_flareholster1 = [$attack2, player_flareholster2] { self.weaponframe = $flare_holster1; };
void() player_flareholster2 = [$attack2, player_flareholster3] { self.weaponframe = $flare_holster2; };
void() player_flareholster3 = [$attack2, player_flareholster4] { self.weaponframe = $flare_holster3; };
void() player_flareholster4 = [$attack2, player_run          ] { W_DrawWeapon (self.newweapon); };

// Akimbo draw
void() player_akflaredraw1 = [$attack2, player_akflaredraw2] { self.weaponframe = $aflare_draw1; };
void() player_akflaredraw2 = [$attack2, player_akflaredraw3] { self.weaponframe = $aflare_draw2; };
void() player_akflaredraw3 = [$attack2, player_run         ] { self.weaponframe = $aflare_draw3; };

// Akimbo holster
void() player_akflareholst1 = [$attack2, player_akflareholst2] { self.weaponframe = $aflare_holster1; };
void() player_akflareholst2 = [$attack2, player_akflareholst3] { self.weaponframe = $aflare_holster2; };
void() player_akflareholst3 = [$attack2, player_akflareholst4] { self.weaponframe = $aflare_holster3; };
void() player_akflareholst4 = [$attack2, player_run          ] { W_DrawWeapon (self.newweapon); };

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
		BurnDamage (other, self, self.dmg, DF_BURN, self.charge, self.dmgtime);

	FlareSpark ();   // Throw a few sparks.

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
		remove (self);
};

void () FlareThink =
{
	local float percent;

	if (self.attack_finished < time ||  // flare is burnt out
		self.enemy.health <=0)          // enemy is dead
		remove (self);

	if (!VecInWater(self.origin) && self.enemy.flags & FL_MONSTER)
	{
		Ignite(self.enemy, self, DF_BURN, 10, 1);
		T_Damage (self.enemy, self, self.owner, 1, DF_BURN, "fire");
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

	setmodel (fire, "models/weapons/objects/flare.md3");
	setsize (fire, '0 0 0', '0 0 0');
	setorigin (fire, spot);

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
	fire.owner      = self;
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
		FlareTouch ();
		return;
	}

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	// Explode!
	muzzleflash ();

	// Do the damage.
	BurnRadius (self, 120, self.dmg, self.cnt, other);
	self.origin = self.origin - 8*normalize(self.velocity);
	if (other.takedamage)
		BurnDamage (other, self, self.dmg, DF_BURN, self.cnt, self.dmgtime);

	// Make some fire.
	self.solid = SOLID_NOT;     // So embers can't touch 'self'.
	PsychoCaleb (self.owner);
	sound (self, CHAN_AUTO, "weapons/napalm/explodfs.wav", 1, ATTN_NORM);
	BecomeOldExplosion ();
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

	dir = normalize (self.velocity);
	dir = vectoangles (dir);
	dir_x = 0 - dir_x;
	makevectors (dir);

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
		dir = normalize (dir);

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
	remove (self);
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

	fire = NewFlare (attacker, org);
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

	fire = NewFlare (attacker, org);
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
void() Flare_Fire =
{
	local vector dir;
	local float  mspeed;

	sound (self, CHAN_WEAPON, "weapons/flaregun/flaref.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	mspeed = 1000;
	dir = aim (self, mspeed);

	// Spawn the flare a little ahead of the player
	local vector orig;
	makevectors(self.v_angle);
	orig = self.origin + v_forward * 8 + '0 0 16';

	// If we want to (and can) launch alt-flares
	if (self.player_state == PS_ALTFIRE && self.ammo_flare >= 8)
	{
		self.currentammo = self.ammo_flare = self.ammo_flare - 8;
		FireAltFlares (self, orig, dir, mspeed, 1, 20, 3);
		return;
	}

	self.currentammo = self.ammo_flare = self.ammo_flare - 1;
	FireFlare (self, orig, dir, mspeed);
};

/*
============
Flare_Attack

Attack code for the flaregun
============
*/
void() Flare_Attack =
{
	// Normal fire or altfire?
	if (self.button3)
		self.player_state = PS_ALTFIRE;
	else
		self.player_state = PS_FIRE;

	// If we have guns akimbo
	if (self.items & IT_GUNS_AKIMBO)
	{
		player_akflare1 ();
		self.attack_finished = time + 0.6;
	}
	else
	{
		player_flare1 ();
		self.attack_finished = time + 0.5;
	}
};

/*
============
Flare_Draw

Draw code for the flaregun
============
*/
void() Flare_Draw =
{
	self.weapon = IT_FLAREGUN;
	self.currentammo = self.ammo_flare;
	self.items = self.items - (self.items & (IT_SHELLS | IT_NAILS | IT_CELLS | IT_ROCKETS));

	Flare_UpdateView ();

	if (self.items & IT_GUNS_AKIMBO)
	{
		self.attack_finished = time + 0.4;
		player_akflaredraw1 ();
	}
	else
	{
		self.attack_finished = time + 0.4;
		player_flaredraw1 ();
	}
};

/*
============
Flare_Holster

Holster code for the flaregun
============
*/
void() Flare_Holster =
{
	if (self.items & IT_GUNS_AKIMBO)
	{
		self.attack_finished = time + 0.4;
		player_akflareholst1 ();
	}
	else
	{
		self.attack_finished = time + 0.4;
		player_flareholster1 ();
	}
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
		self.weaponmodel = "models/weapons/ga_flare.md3";
		self.items = self.items | IT_GUNS_AKIMBO;
	}
	else
	{
		self.weaponmodel = "models/weapons/v_flare.psk";
		self.items = self.items - (self.items & IT_GUNS_AKIMBO);
	}
};
