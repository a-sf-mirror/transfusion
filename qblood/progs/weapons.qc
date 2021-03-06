/*  Copyright (C) 1996-1997  Id Software, Inc.

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

void(entity bomb, entity attacker, float rad, float dflags, entity ignore, string dtype) T_RadiusDamage;

//============================================================================

void() PrecacheWeapons =
{
	precache_pitchfork();
	precache_flaregun();
	precache_sawedoff();
	precache_tommygun();
	precache_napalmlauncher();
	precache_tnt();
	precache_remote();
	precache_proximity();
	precache_spraycan();
	precache_teslacannon();
	precache_lifeleech();
	precache_voodoodoll();
};

/*
============
W_Origin

Updates the origin with adjusted offset for crouched and uncrouched.
============
*/
vector() W_Origin =
{
	if (self.owner.crouch)
		return self.owner.origin + PL_CROUCH_VIEW_OFS;
	else
		return self.owner.origin + PL_VIEW_OFS;
};

/*
================
muzzleflash_animate

runs the animation and removal of completed muzzle flashes
================
*/
void() muzzle_remove = { remove(self); };
void() muzzle_animate =
{
	if (self.frame == self.anim_end)
		muzzle_remove();
	else
	{
		self.frame = self.frame + 1;
		self.nextthink = time + 0.1;
		self.think = muzzle_animate;
	}
};

/*
================
muzzleflash

creates the muzzle flash for weapons
================
*/
void(float hand) muzzleflash =
{
	local float has_akimbo;
	local entity muzzle;
	has_akimbo = self.owner.akimbo_finished;
	muzzle = spawn();
	muzzle.owner = self;
	muzzle.viewmodelforclient = self.owner;
	
	muzzle.solid = SOLID_NOT;
	if (has_akimbo)
	{
		if (hand == LEFT)
			setattachment(muzzle, self.weaponentity, "LMuzzle");
		else
			setattachment(muzzle, self.weaponentity, "RMuzzle");
	}
	else
		setattachment(muzzle, self.weaponentity, "Muzzle");

	local string sprite;

	if (self.owner.weapon == IT_FLAREGUN)
	{

	}
	else if (self.owner.weapon == IT_SAWED_OFF)
	{
		if (has_akimbo)
		{
			sprite = "models/weapons/objects/muzzle_shotgun.spr32";
			setmodel(muzzle, sprite);
			muzzle.scale = 0.45;
			muzzle.frame = 0;
			muzzle.anim_end = 1;
			muzzle.nextthink = time + 0.1;
			muzzle.think = muzzle_animate;
			muzzle.th_die = muzzle_remove;
		}
		else
		{
			if ((self.owner.player_state == PS_ALTFIRE) && (self.weaponentity.ammo_in_chamber == 2))
			{
				muzzle.scale = 0.65;
				setattachment(muzzle, self.weaponentity, "Muzzle_L");
				setorigin(muzzle, self.weaponentity.origin + v_right * -13 + v_up * -4);
			}
			else
			{
				if (self.weaponentity.ammo_in_chamber == 2)
				{
					setattachment(muzzle, self.weaponentity, "Muzzle_L");
					setorigin(muzzle, '0 0 0' + v_right * -10.6);
				}
				else
				{
					setattachment(muzzle, self.weaponentity, "Muzzle_R");
					setorigin(muzzle, '0 0 0' + v_right * -10.4);
				}
				muzzle.scale = 0.45;
			}
		}
		sprite = "models/weapons/objects/muzzle_shotgun.spr32";
		setmodel(muzzle, sprite);
		muzzle.frame = 0;
		muzzle.anim_end = 1;
		muzzle.nextthink = time + 0.1;
		muzzle.think = muzzle_animate;
		muzzle.th_die = muzzle_remove;
	}
	else if (self.owner.weapon == IT_TOMMYGUN)
	{
		sprite = "models/weapons/objects/muzzle_tommy.spr32";
		setmodel(muzzle, sprite);
		muzzle.alpha = 0.5;
		if (!has_akimbo)
			muzzle.scale = 0.6;
		else
			muzzle.scale = 0.4;
		muzzle.frame = floor((random() * 10) / 2.5);
		muzzle.nextthink = time + 0.1;
		muzzle.think = muzzle_remove;
	}
	else if (self.owner.weapon == IT_NAPALM_LAUNCHER)
	{
		sprite = "models/weapons/objects/muzzle_napalm_2.spr32";
		setmodel(muzzle, sprite);
		//muzzle.scale = 0.65;
		muzzle.frame = 0;
		muzzle.anim_end = 1;
		muzzle.nextthink = time + 0.1;
		muzzle.think = muzzle_animate;
		muzzle.th_die = muzzle_remove;
	}
	//FIXME - add other weapons, and fix shotgun
};

/*
================
SpawnBlood
================
*/
void(vector org, vector vel, float damage) SpawnBlood =
{
	damage = ceil(damage / 2);
	//te_particlecube(org, org + '0 0 32', vel, damage, 73, TRUE, 250);

	vel_x = crandom() * 300;
	vel_y = crandom() * 300;
	vel_z = crandom() * 300 + 200;

	te_blood(org, vel, damage);
};

/*
================
MeatSprayTouch

Bleeds when generic meat spray touches something
================
*/
void() MeatSprayTouch =
{
	SpawnBlood(self.origin, '0 0 50', 16);

	if (other.classname == "player")
		remove(self);
};

/*
================
BloodMeatSpray

Modified to behave more like Blood's blood spray
================
*/
void(vector org, vector vel, entity ignore) BloodMeatSpray =
{
	local   entity  missile;

	missile = spawn();
	missile.owner       = ignore;
	missile.movetype    = MOVETYPE_TOSS;    // Was *_BOUNCE
	missile.solid       = SOLID_BBOX;       // Was *_NOT

	missile.velocity    = vel;
	missile.avelocity   = '3000 1000 2000';

	// set missile duration
	missile.nextthink   = time + 1;
	missile.think       = SUB_Remove;
	missile.touch       = MeatSprayTouch;

	setmodel(missile, "models/objects/gib4.md3");
	setsize(missile, '0 0 0', '0 0 0');
	setorigin(missile, org);

	te_blood(org, vel, 8);
};

/*
================
SpawnBloodSpray
================
*/
void(entity targ, vector org) SpawnBloodSpray =
{
	if (random() < 0.25)    // 25% chance per call of spawning blood.
	{
		local   vector  vel;

		vel_x = crandom() * 300;
		vel_y = crandom() * 300;
		vel_z = random() * 300 + 200;
		BloodMeatSpray(org, vel, targ);
	}
};

float(entity targ) Reflected =
{
	if (!targ)
		return FALSE;
	return (targ.reflect_finished >= time);
};

/*
==============================================================================

MULTI-DAMAGE

Collects multiple small damages into a single damage

==============================================================================
*/
entity  multi_ent;
float   multi_damage;

void() ClearMultiDamage =
{
	multi_ent = world;
	multi_damage = 0;
};

void(float dflags) ApplyMultiDamage =
{
	if (!multi_ent)
		return;
	T_Damage(multi_ent, self.owner, self.owner, multi_damage, dflags, string_null);
};

void(entity hit, float damage) AddMultiDamage =
{
	if (!hit)
		return;

	if (hit != multi_ent)
	{
		ApplyMultiDamage(DF_NONE);
		multi_damage = damage;
		multi_ent = hit;
	}
	else
		multi_damage = multi_damage + damage;
};

/*
==============================================================================
BULLETS
==============================================================================
*/

/*
================
TraceAttack
================
*/
void(float damage, vector dir) TraceAttack =
{
	if (Reflected(trace_ent))
	{
		if (Reflected(self))
			return;     // Both have reflection, so negate attack.

		// Hit attacker instead.
		trace_ent = self;
		trace_endpos = self.origin;
		dir = '0 0 0' - dir;
	}

	local   vector  vel, org;

	vel = normalize(dir + v_up*crandom() + v_right*crandom());
	vel = vel + 2*trace_plane_normal;
	vel = vel * 200;

	org = trace_endpos - dir*4;

	if (trace_ent.takedamage)
		AddMultiDamage(trace_ent, damage);

	// If the target can bleed, spawn some blood
	if (trace_ent.classname == "player" || (trace_ent.flags & FL_MONSTER) ||
		trace_ent.classname == "corpse" ||  trace_ent.classname == "head")
	{
		SpawnBlood(org, vel*0.2, damage);
		SpawnBloodSpray(trace_ent, org);
	}
	else
	{
		WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte(MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord(MSG_BROADCAST, org_x);
		WriteCoord(MSG_BROADCAST, org_y);
		WriteCoord(MSG_BROADCAST, org_z);
	}
};

/*
================
FireBullets

Used by shotgun, tommy gun, trap_tommy
Go to the trouble of combining multiple pellets into a single damage call.
================
*/
void(vector orig, vector dir, float shotcount, float damage, vector spread) FireBullets =
{
	local vector direction;
	local vector src;

	makevectors(self.owner.v_angle);

	src = orig + v_forward * 10;
	src_z = self.owner.absmin_z + self.owner.size_z * 0.7;

	ClearMultiDamage();

	while (shotcount > 0)
	{
		direction = dir + crandom() * spread_x * v_right + crandom() * spread_y * v_up;

		traceline(src, src + direction*2048, FALSE, self.owner);
		if (trace_fraction != 1.0)
			TraceAttack(damage, direction);

		shotcount = shotcount - 1;
	}
	ApplyMultiDamage(DF_BULLET);
};

/*
================
ShellHit

Plays hit sound when shell hits hard surface if not stuck inloop
================
*/
void() ShellHit =
{
	// prevent sound if last shellhit sound occured within last 2 frames
	if (self.ltime <= (time - 0.2))
		sound(self, CHAN_WEAPON, self.noise, 1,ATTN_NORM);

	self.ltime = time; // marks time of current touch triggeractivation
};


/*
================
DropShell

Displays shell and defines its dynamic manifestation
================
*/
void(entity shell) DropShell =
{
	shell.movetype = MOVETYPE_BOUNCE;
	shell.solid = SOLID_BBOX;
	setmodel(shell, shell.mdl);
	setsize(shell, PL_ORIGIN, PL_ORIGIN);
	makevectors(shell.owner.v_angle);

	shell.avelocity_x = crandom()*500;
	shell.avelocity_y = crandom()*500;
	shell.avelocity_z = crandom()*500;
	shell.touch = ShellHit;
	shell.nextthink = time + 1.2;
	shell.think = SUB_Remove;
	shell.reset = SUB_Remove;
	shell.ltime = time - 1;
	shell.effects = shell.effects | EF_LOWPRECISION;
};

/*
==============================================================================
ROCKETS
==============================================================================
*/
void(entity client) ResetIdle =
{
	client.idle_done = FALSE;
	client.idle_time = time + 5 + random() * 10;  // 5-15 sec.
};

// This makes the player rave.
void(entity client) BoredCaleb =
{
	// If we're already talking
	if (client.voice_finished >= time)
	return;

	if (client.health <= 0 || client.deadflag)
		return;
	if (client.classname != "player" || !client.takedamage)
		return;

	local   float   rs;
	local   string  playit;

	rs = floor(random() * 12);

	if (rs == 0)
		playit = "player/songs/1093.wav";   // "Strangers in the night..."
	else if (rs == 1)
		playit = "player/songs/1094.wav";   // "There's no business like..."
	else if (rs == 2)
		playit = "player/songs/1095.wav";   // "I did it... my way!"
	else if (rs == 3)
		playit = "player/songs/1097.wav";   // "...putting on the Ritz."
	else if (rs == 4)
		playit = "player/songs/vo3011.wav";   // "sun will come out . . ."
	else if (rs == 5)
		playit = "player/songs/vo3024.wav";   // "row row row your boat"
	else if (rs == 6)
		playit = "player/songs/vo3026.wav";   // "it's a long way ..."
	else if (rs == 7)
		playit = "player/songs/vo3030.wav";   // "somewhere over the rainbow."
	else if (rs == 8)
		playit = "player/songs/vo3033.wav";   // "sailing sailing ..."
	else if (rs == 9)
		playit = "player/songs/vo3034.wav";   // "on the good ship lollipop."
	else if (rs == 10)
		playit = "player/songs/vo3035.wav";   // "i get no kick from champagne...."
	else
		playit = "player/songs/vo3039.wav";   // "i've got you under my skin"

	client.voice_finished = time + 8;
	sound(client, CHAN_VOICE, playit, 1, ATTN_NORM);
};

// This makes the player laugh or utter one of Caleb's signature one-liners.
void(entity client) PsychoCaleb =
{
	// If we're already talking
	if (client.voice_finished >= time)
		return;
	if (random() > 0.15)
		return;     // Only 15% chance per call.
	if (client.health <= 0 || client.deadflag)
		return;
	if (client.classname != "player")
		return;

	local   float   rs;
	local   string  playit;

	rs = floor(random() * 3);

	if (rs == 0)
		playit = "player/quips/1039.wav";   // "Son of a bitch must pay!"
	else if (rs == 1)
		playit = "player/quips/1050.wav";   // "Tha, tha, that's all folks!"
	else if (rs == 2)
		playit = "player/quips/1057.wav";   // "Rest in pieces"
	else
	{
		// Laugh like a psycho.
		rs = floor(random() * 8);

		if (rs == 0)
			playit = "player/play1109.wav";
		else if (rs == 1)
			playit = "player/play1110.wav";
		else if (rs == 2)
			playit = "player/play1111.wav";
		else if (rs == 3)
			playit = "player/play1112.wav";
		else if (rs == 4)
			playit = "player/play1113.wav";
		else if (rs == 5)
			playit = "player/play1114.wav";
		else if (rs == 6)
			playit = "player/play1115.wav";
		else
			playit = "player/play1116.wav";
	}

	client.voice_finished = time + 5;
	sound(client, CHAN_VOICE, playit, 1, ATTN_NORM);
};

// 13 frames for Blood's explosion
void() s_explode1  = [0,  s_explode2]  {};
void() s_explode2  = [1,  s_explode3]  {};
void() s_explode3  = [2,  s_explode4]  {};
void() s_explode4  = [3,  s_explode5]  {};
void() s_explode5  = [4,  s_explode6]  {};
void() s_explode6  = [5,  s_explode7]  {};
void() s_explode7  = [6,  s_explode8]  {};
void() s_explode8  = [7,  s_explode9]  {};
void() s_explode9  = [8,  s_explode10] {};
void() s_explode10 = [9,  s_explode11] {};
void() s_explode11 = [10, s_explode12] {};
void() s_explode12 = [11, s_explode13] {};
void() s_explode13 = [12, SUB_Remove]  {};

void() BecomeExplosion =
{
	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel(self, "progs/s_explod.spr");
	self.solid = SOLID_NOT;
	self.alpha = 0.9;
	self.reset = SUB_Remove;
	s_explode1();
};

//=============================================================================
void() flame_touch =
{
	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		return; // trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	// hit something that bleeds
	if (other.takedamage)
	{
		BurnDamage(other, self, 5, DF_BURN, 10, 3);

		if (other.flags & FL_MONSTER)
			T_Damage(other, self, self.owner, 4, DF_BURN, "fire");
	}

	remove(self);

};

/*
===============================================================================
PLAYER WEAPON USE
===============================================================================
*/

// Functions defined later in weapon files (w_*.qc)
void() Fork_Attack;     void() Fork_Draw;   void() Fork_Holster;    void() Fork_UpdateView;
void() Flare_Attack;    void() Flare_Draw;  void() Flare_Holster;   void() Flare_UpdateView;
void() Shotgun_Attack;  void() Shotgun_Draw;void() Shotgun_Holster; void() Shotgun_UpdateView;
void() Tommy_Attack;    void() Tommy_Draw;  void() Tommy_Holster;   void() Tommy_UpdateView;
void() Spray_Attack;    void() Spray_Draw;  void() Spray_Holster;   void() Spray_UpdateView;
void() TNT_Attack;      void() TNT_Draw;    void() TNT_Holster;     void() TNT_UpdateView;
void() Proxy_Attack;    void() Proxy_Draw;  void() Proxy_Holster;   void() Proxy_UpdateView;
void() Remote_Attack;   void() Remote_Draw; void() Remote_Holster;  void() Remote_UpdateView;
void() Tesla_Attack;    void() Tesla_Draw;  void() Tesla_Holster;   void() Tesla_UpdateView;
void() Napalm_Attack;   void() Napalm_Draw; void() Napalm_Holster;  void() Napalm_UpdateView;
void() Voodoo_Attack;   void() Voodoo_Draw; void() Voodoo_Holster;  void() Voodoo_UpdateView;
void() Leech_Attack;    void() Leech_Draw;  void() Leech_Holster;   void() Leech_UpdateView;

/*
====================
W_DrawWeapon

Draw a new weapon
====================
*/
void(float weap) W_DrawWeapon =
{
	if (self == self.weaponentity)
		self = self.owner;

	if (weap && !(self.items & weap))
		return;

	if (!weap)
	{
		self.weapon = self.currentammo = 0;
		//return;
	}
	// Don't draw a fire based weapon under water
	if (self.waterlevel == 3)
	{
		if (weap == IT_TNT || weap == IT_SPRAY_CAN)
			return;
	}

	self.player_state = PS_DRAW;

	if (weap == IT_PITCHFORK)
		Fork_Draw();
	else if (weap == IT_FLAREGUN)
		Flare_Draw();
	else if (weap == IT_SAWED_OFF)
		Shotgun_Draw();
	else if (weap == IT_TOMMYGUN)
		Tommy_Draw();
	else if (weap == IT_SPRAY_CAN)
		Spray_Draw();
	else if (weap == IT_TNT)
		TNT_Draw();
	else if (weap == IT_PROXIMITY_BOMB)
		Proxy_Draw();
	else if (weap == IT_REMOTE_DETONATOR)
		Remote_Draw();
	else if (weap == IT_NAPALM_LAUNCHER)
		Napalm_Draw();
	else if (weap == IT_TESLA_CANNON)
		Tesla_Draw();
	else if (weap == IT_VOODOO_DOLL)
		Voodoo_Draw();
	else if (weap == IT_LIFE_LEECH)
		Leech_Draw();

	self.newweapon = 0;
};

/*
====================
W_SwitchToWeapon

Switch to another player's weapon
====================
*/
void(float newWeapon) W_SwitchToWeapon =
{
	self.newweapon = 0;

	// If we don't have that weapon
	if (newWeapon && !(self.items & newWeapon)) //if newWeapon = 0, we're forcing a holster
		return;

	// If the new weapon is already the current one
	if (self.weapon == newWeapon)
		return;

	self.newweapon = newWeapon;
	self.player_state = PS_HOLSTER;

	if (self.weapon == IT_PITCHFORK)
		Fork_Holster();
	else if (self.weapon == IT_FLAREGUN)
		Flare_Holster();
	else if (self.weapon == IT_SAWED_OFF)
		Shotgun_Holster();
	else if (self.weapon == IT_TOMMYGUN)
		Tommy_Holster();
	else if (self.weapon == IT_SPRAY_CAN)
		Spray_Holster();
	else if (self.weapon == IT_TNT)
		TNT_Holster();
	else if (self.weapon == IT_PROXIMITY_BOMB)
		Proxy_Holster();
	else if (self.weapon == IT_REMOTE_DETONATOR)
		Remote_Holster();
	else if (self.weapon == IT_NAPALM_LAUNCHER)
		Napalm_Holster();
	else if (self.weapon == IT_TESLA_CANNON)
		Tesla_Holster();
	else if (self.weapon == IT_VOODOO_DOLL)
		Voodoo_Holster();
	else if (self.weapon == IT_LIFE_LEECH)
		Leech_Holster();
};

void() W_SetCurrentAmmo =
{
	if (self.weapon == IT_PITCHFORK)
	{
		self.currentammo = 0;
		Fork_UpdateView();
	}
	else if (self.weapon == IT_FLAREGUN)
	{
		self.currentammo = self.ammo_flare;
		Flare_UpdateView();
		//self.items = self.items | IT_SHELLS;
	}
	else if (self.weapon == IT_SAWED_OFF)
	{
		self.currentammo = self.ammo_shells;
		Shotgun_UpdateView();
		self.items = self.items | IT_SHELLS;
	}
	else if (self.weapon == IT_TOMMYGUN)
	{
		self.currentammo = self.ammo_nails;
		Tommy_UpdateView();
		self.items = self.items | IT_NAILS;
	}
	else if (self.weapon == IT_SPRAY_CAN)
	{
		self.currentammo = self.ammo_spray;
		Spray_UpdateView();
		//self.items = self.items | IT_NAILS;
	}
	else if (self.weapon == IT_TNT)
	{
		self.currentammo = self.ammo_tnt_bundle;
		TNT_UpdateView();
		//self.items = self.items | IT_ROCKETS;
	}
	else if (self.weapon == IT_PROXIMITY_BOMB)
	{
		self.currentammo = self.ammo_tnt_proxy;
		Proxy_UpdateView();
		//self.items = self.items | IT_ROCKETS;
	}
	else if (self.weapon == IT_REMOTE_DETONATOR)
	{
		self.currentammo = self.ammo_tnt_remote;
		Remote_UpdateView();
		//self.items = self.items | IT_ROCKETS;
	}
	else if (self.weapon == IT_NAPALM_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
		Napalm_UpdateView();
		self.items = self.items | IT_ROCKETS;
	}
	else if (self.weapon == IT_TESLA_CANNON)
	{
		self.currentammo = self.ammo_cells;
		Tesla_UpdateView();
		self.items = self.items | IT_CELLS;
	}
	else if (self.weapon == IT_VOODOO_DOLL)
	{
		self.currentammo = self.ammo_voodoo;
		Voodoo_UpdateView();
		//self.items = self.items | IT_CELLS;
	}
	else if (self.weapon == IT_LIFE_LEECH)
	{
		self.currentammo = self.ammo_leech;
		Leech_UpdateView();
		//self.items = self.items | IT_CELLS;
	}
	else
		self.currentammo = 0;
};

/*
====================
W_BestWeapon

Autoswitch weapon list

Note (Elric): This list comes from my experiments with Blood.
I don't really agree with the order, but hey ... it's Blood.
====================
*/
float() W_BestWeapon =
{
	local   float   it;

	it = self.items;

	// 1- Sawed Off
	if (self.ammo_shells >= 1 && (it & IT_SAWED_OFF))
		return IT_SAWED_OFF;

	// 2- Tommy Gun
	if (self.ammo_nails >= 1 && (it & IT_TOMMYGUN))
		return IT_TOMMYGUN;

	// 3- Flare Gun
	if (self.ammo_flare >= 1 && (it & IT_FLAREGUN))
		return IT_FLAREGUN;

	// 4- Tesla Cannon
	if (self.ammo_cells >= 1 && (it & IT_TESLA_CANNON))
		return IT_TESLA_CANNON;

	// 5- Voodoo Doll
	if (self.ammo_voodoo >= 1 && (it & IT_VOODOO_DOLL))
		return IT_VOODOO_DOLL;

	// 6- Spray Can
	if (self.ammo_spray >= 1 && (it & IT_SPRAY_CAN) && self.waterlevel < 3)
		return IT_SPRAY_CAN;

	// 7- Life Leech
	if (it & IT_LIFE_LEECH)
		return IT_LIFE_LEECH;

	/* if you only have a pitchfork drawn, you can draw the Napalm Launcher
		otherwise it won't draw if you run out of ammo of any other weapon */
	if (self.weapon == IT_PITCHFORK && it & IT_NAPALM_LAUNCHER)
		return IT_NAPALM_LAUNCHER;

	// 8- Fork
	return IT_PITCHFORK;
};

float() W_AmmoAvailable =
{
	if (self.currentammo > 0)
		return TRUE;

	if (self.weapon == IT_PITCHFORK || self.weapon == IT_LIFE_LEECH)
		return TRUE;

	return FALSE;
};

/*
============
W_Attack

An attack impulse can be triggered now
============
*/
void() W_Attack =
{
	makevectors(self.v_angle);    // calculate forward angle for velocity

	if (self.weapon == IT_PITCHFORK)
		Fork_Attack();
	else if (self.weapon == IT_FLAREGUN)
		Flare_Attack();
	else if (self.weapon == IT_SAWED_OFF)
		Shotgun_Attack();
	else if (self.weapon == IT_TOMMYGUN)
		Tommy_Attack();
	else if (self.weapon == IT_SPRAY_CAN)
		Spray_Attack();
	else if (self.weapon == IT_TNT)
		TNT_Attack();
	else if (self.weapon == IT_PROXIMITY_BOMB)
		Proxy_Attack();
	else if (self.weapon == IT_REMOTE_DETONATOR)
		Remote_Attack();
	else if (self.weapon == IT_NAPALM_LAUNCHER)
		Napalm_Attack();
	else if (self.weapon == IT_TESLA_CANNON)
		Tesla_Attack();
	else if (self.weapon == IT_VOODOO_DOLL)
		Voodoo_Attack();
	else if (self.weapon == IT_LIFE_LEECH)
		Leech_Attack();

	self.impulse = IMP_NONE;
};

/*
============
W_ChangeWeapon

============
*/
void() W_ChangeWeapon =
{
	local float old, am, new;

	// Don't let player change weapons while holding lit dynamite.
	if (self.weaponentity.tnt_time)
		return;

	old = self.weapon;
	am = 0;

	if (self.impulse == IMP_PITCHFORK)
		new = IT_PITCHFORK;
	else if (self.impulse == IMP_FLAREGUN)
	{
		new = IT_FLAREGUN;
		if (self.ammo_flare < 1)
			am = 1;
	}
	else if (self.impulse == IMP_SAWED_OFF)
	{
		new = IT_SAWED_OFF;
		if (self.ammo_shells < 1)
			am = 1;
	}
	else if (self.impulse == IMP_TOMMYGUN)
	{
		new = IT_TOMMYGUN;
		if (self.ammo_nails < 1)
			am = 1;
	}
	else if (self.impulse == IMP_NAPALM_LAUNCHER)
	{
		new = IT_NAPALM_LAUNCHER;
		if (self.ammo_rockets < 1)
			am = 1;
	}
	else if (self.impulse == IMP_BOMBS)
	{
		new = 0;

		// If we don't have any type of dynamite
		if (self.ammo_tnt_bundle < 1 &&
			self.ammo_tnt_proxy  < 1 &&
			!(self.items & IT_REMOTE_DETONATOR))  // select at least the remote if we have it
			am = 1;

		else
		{
			// If the TNT was already selected
			if (self.weapon == IT_TNT)
			{
				if (self.ammo_tnt_proxy > 0)
					new = IT_PROXIMITY_BOMB;
				else if (self.items & IT_REMOTE_DETONATOR)
					new = IT_REMOTE_DETONATOR;
				else
					new = IT_TNT;
			}

			// Else, if the proximity bombs were already selected
			else if (self.weapon == IT_PROXIMITY_BOMB)
			{
				if (self.items & IT_REMOTE_DETONATOR)
					new = IT_REMOTE_DETONATOR;
				else if (self.ammo_tnt_bundle > 0 && self.waterlevel < 3)
					new = IT_TNT;
				else
					new = IT_PROXIMITY_BOMB;
			}

			// Else (if the previous weapon was the remote detonators or a non-dynamite weapon)
			else
			{
				if (self.ammo_tnt_bundle > 0 && self.waterlevel < 3)
					new = IT_TNT;
				else if (self.ammo_tnt_proxy > 0)
					new = IT_PROXIMITY_BOMB;
				else if (self.items & IT_REMOTE_DETONATOR)
					new = IT_REMOTE_DETONATOR;
				else
					new = IT_TNT; // Print can't use in water message
			}
		}
	}
	else if (self.impulse == IMP_PROXIMITY_BOMB)
		new = IT_PROXIMITY_BOMB;
	else if (self.impulse == IMP_REMOTE_DETONATOR)
		new = IT_REMOTE_DETONATOR;
	else if (self.impulse == IMP_SPRAY_CAN)
	{
		new = IT_SPRAY_CAN;
		if (self.ammo_spray < 1)
			am = 1;
	}
	else if (self.impulse == IMP_TESLA_CANNON)
	{
		new = IT_TESLA_CANNON;
		if (self.ammo_cells < 1)
			am = 1;
	}
	else if (self.impulse == IMP_LIFE_LEECH)
	{
		new = IT_LIFE_LEECH;
		// Life Leech doesn't need ammo
	}
	else if (self.impulse == IMP_VOODOO_DOLL)
	{
		new = IT_VOODOO_DOLL;
		if (self.ammo_voodoo < 1)
			am = 1;
	}

	self.impulse = IMP_NONE;

	// No TNT or spray can under water
	if (self.waterlevel == 3)
	{
		if (new == IT_SPRAY_CAN || new == IT_TNT)
		{
			sprint(self, "You can't select that weapon under water.\n");
			return;
		}
	}

	// don't have the weapon
	if (!(self.items & new))
	{
		sprint(self, "You don't have that weapon.\n");
		return;
	}

	// don't have the ammo
	if (am)
	{
		sprint(self, "You are out of ammo.\n");
		return;
	}

	// If the weapon has really changed
	if (old && new != old)
		W_SwitchToWeapon(new);
	else if (!old)
		W_DrawWeapon(new);
};

/*
============
CycleWeaponCommand

Go to the next/previous weapon with ammo
============
*/
void(float reverse) CycleWeaponCommand =
{
	local float am, newWeapon;

	newWeapon = self.weapon;

	// Don't let player change weapons while holding lit dynamite.
	if (self.weaponentity.tnt_time)
		return;

	while (1)
	{
		am = 0;

		// Get the next possible weapon
		if (reverse)
		{
			newWeapon = newWeapon / 2;
			if (newWeapon < IT_PITCHFORK)
				newWeapon = IT_VOODOO_DOLL;
		}
		else
		{
			newWeapon = newWeapon * 2;
			if (newWeapon > IT_VOODOO_DOLL)
				newWeapon = IT_PITCHFORK;
		}

		if (newWeapon == IT_FLAREGUN)
		{
			if (self.ammo_flare < 1)
				am = 1;
		}
		else if (newWeapon == IT_SAWED_OFF)
		{
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (newWeapon == IT_TOMMYGUN)
		{
			if (self.ammo_nails < 1)
				am = 1;
		}
		else if (newWeapon == IT_NAPALM_LAUNCHER)
		{
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (newWeapon == IT_TNT)
		{
			// No TNT under water
			if (self.waterlevel == 3)
				am = 1;
			// No need to check the ammo (it's removed as soon as there's no more ammo)
		}
		else if (newWeapon == IT_SPRAY_CAN)
		{
			// No spray can under water
			if (self.ammo_spray < 1 || self.waterlevel == 3)
				am = 1;
		}
		else if (newWeapon == IT_TESLA_CANNON)
		{
			if (self.ammo_cells < 1)
				am = 1;
		}
		else if (newWeapon == IT_VOODOO_DOLL)
		{
			if (self.ammo_voodoo < 1)
				am = 1;
		}

		if ((self.items & newWeapon) && am == 0)
		{
			W_SwitchToWeapon(newWeapon);
			return;
		}
	}

};

// PM:  Let's player change the armor shown if he has more than one armor.
void() ArmorTest =
{
	if (self.items & IT_ARMOR_FIRE)
	{
		if (self.armor_body)
		{
			self.armorvalue = self.armor_body;
			self.items = self.items - (self.items & IT_ARMOR_ALL) + IT_ARMOR_BODY;
		}
		else if (self.armor_spirit)
		{
			self.armorvalue = self.armor_spirit;
			self.items = self.items - (self.items & IT_ARMOR_ALL) + IT_ARMOR_SPIRIT;
		}
	}
	else if (self.items & IT_ARMOR_BODY)
	{
		if (self.armor_spirit)
		{
			self.armorvalue = self.armor_spirit;
			self.items = self.items - (self.items & IT_ARMOR_ALL) + IT_ARMOR_SPIRIT;
		}
		else if (self.armor_fire)
		{
			self.armorvalue = self.armor_fire;
			self.items = self.items - (self.items & IT_ARMOR_ALL) + IT_ARMOR_FIRE;
		}
	}
	else if (self.items & IT_ARMOR_SPIRIT)
	{
		if (self.armor_fire)
		{
			self.armorvalue = self.armor_fire;
			self.items = self.items - (self.items & IT_ARMOR_ALL) + IT_ARMOR_FIRE;
		}
		else if (self.armor_body)
		{
			self.armorvalue = self.armor_body;
			self.items = self.items - (self.items & IT_ARMOR_ALL) + IT_ARMOR_BODY;
		}
	}
};

/*
============
W_WeaponFrame

Called every frame so impulse events can be handled as well as possible
============
*/
void(float isAlive) Impulses_Player;
void() W_WeaponFrame =
{
	if (self.player_state == PS_BOD_FALL || self.player_state == PS_BOD_SWAY)
		return;

	if (!W_AmmoAvailable() && self.weapon) //self.weapon is a check for dropping your weapons such as TNT self-explosion.
	{
		if ((self.player_state != PS_HOLD_FIRE) && (self.weaponentity.tnt_type != REMOTE_ONLY))
		{
			W_SwitchToWeapon(W_BestWeapon());
			return;
		}
	}

	if ((self.weaponentity.attack_finished > time) && ((self.weaponentity.anim_type != DRAW) && (self.weaponentity.anim_type != HOLSTER)))
		return;

	//check for changeweapon before ammo incase we currently have no weapon drawn
	Impulses_Player(TRUE);

	if (self.akimbo_finished)
		W_SetCurrentAmmo();
	if (self.akimbo_finished <= time)
	{
		self.akimbo_finished = 0;
		W_SetCurrentAmmo();
	}

	// Check for attack
	if (((self.button0) || (self.button3)) && ((self.weaponentity.anim_type != DRAW) && (self.weaponentity.anim_type != HOLSTER)))
	{
		ResetIdle(self);
		W_Attack();
	}
};

void() SpawnWeaponentity =
{
	self.weaponentity = spawn();
	self.weaponentity.solid = SOLID_NOT;
	self.weaponentity.owner = self;
	self.weaponentity.weaponentity = self.weaponentity;
	self.weaponentity.viewmodelforclient = self;
};