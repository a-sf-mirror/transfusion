/*  Copyright (C) 2003  Timothy Hale

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

$base base
$skin skin

// idle
$frame idle1

// Prototypes
void () gargoyle_stand1;             // Minor shoulder shrugging and undead breathing
void () gargoyle_launch_Bone;
void () gargoyle_BoneTouch;       // When struck by bone
void () gargoyle_claw;

//--- Walking around
void () gargoyle_walk1 = [$idle1, gargoyle_walk1] {basic_ai (3);};

//--- Decide which idle to do
void () gargoyle_stand =
{
	if (random () < 0.05)
	sound (self, CHAN_WEAPON, "gargoyle/gargroam.wav", 1, ATTN_NORM);

	gargoyle_stand1();
};

void () gargoyle_stand1 = [$idle1, gargoyle_stand] {ai_stand();};

void () gargoyle_walk =
{
	self.style = 2;
	gargoyle_walk1 ();
};

void () gargoyle_run =
{
	self.style = 3;
	gargoyle_walk1 ();
};

//--- bone Throw
void () gargoyle_attacka1 = [$idle1, gargoyle_run] {gargoyle_launch_Bone (); ai_face ();};

//--- clawing
void () gargoyle_attackb1 = [$idle1, gargoyle_run] {gargoyle_claw(); ai_face ();};

void () gargoyle_attack =
{
	local float dist;

	dist = vlen(self.enemy.origin - self.origin);

	if (dist < 90)
		gargoyle_attackb1 ();
	else
		gargoyle_attacka1 ();
};

//--- Throw gargoyle's bone
void () gargoyle_launch_Bone =
{
	local vector vec;

	sound (self, CHAN_WEAPON, "gargoyle/gargthro.wav", 1, ATTN_NORM);
	vec = (self.enemy.origin - self.origin);
	vec = normalize (vec);

	newmis = spawn ();
	newmis.owner = self;

	newmis.solid = SOLID_BBOX;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	setmodel (newmis, "models/world/leg1.md3");
	setsize (newmis, '0 0 0', '0 0 0');        // FIXME
	newmis.origin = self.origin + '0 -8 20';
	newmis.velocity = vec * 600;
	newmis.avelocity = '500 500 500';
	newmis.touch = gargoyle_BoneTouch;
};

//--- bone hit something solid, now what?
void () gargoyle_BoneTouch =
{
	local float damg;

	if (other == self.owner)
		return;
	if (pointcontents (self.origin) == CONTENT_SKY)
	{
		remove (self);
		return;
	}

	if (other.health) // FIXME: I'll probably have to change this so world objects won't bleed
	{
		damg = (50+ (random () * 20));    // FIXME: I need the "real" values

		SpawnBlood (self.origin, '0 0 0', damg);
		SpawnBloodSpray (trace_ent, self.origin);
		sound (self, CHAN_WEAPON, "weapons/pitchfrk/pflesh.wav", 1, ATTN_NORM);

		T_Damage (other,self,self.owner,damg, DF_PUMMEL, string_null);
	}

	self.origin = (self.origin - (8* normalize (self.velocity)));
	remove (self);
};

void () gargoyle_claw =
{
	local vector    delta;
	local float     ldmg;

	if (!self.enemy)
		return;        // removed before stroke

	delta = self.enemy.origin - self.origin;

	if (vlen(delta) > 90)
		return;

	ldmg = (random() + random()) * 3;
	T_Damage (self.enemy, self, self, ldmg, DF_STAB, string_null);

	SpawnBlood (self.origin, '0 0 0', ldmg);
	SpawnBloodSpray (trace_ent, self.origin);
	sound (self, CHAN_WEAPON, "gargoyle/gargclaw.wav", 1, ATTN_NORM);
};

void () gargoyle_pain =
{
	// don't make multiple pain sounds right after each other
	if (self.pain_finished > time)
		return;

	sound (self,2,"gargoyle/gargpain.wav",1,1);
	//  gargoyle_pain1 ();  // FIXME: Need more than one frame for true pain
	self.pain_finished = (time + 1.14);
};

//--- Death sequence
void () gargoyle_death1 = [$idle1, gargoyle_death1]
{
	monster_become_corpse();
};

void () gargoyle_die =
{
	monster_death();
	droptofloor();

	if (self.health < -40)
	{
		// Very large blood splat!
		te_bloodshower (self.origin, self.origin + self.size, 100, 150);

		sound (self, CHAN_VOICE, "gargoyle/gargdie3.wav", 1, ATTN_NORM);
		remove (self);
		return;
	}    

	if (random () < 0.5)
		sound (self, CHAN_VOICE, "gargoyle/gargdie1.wav", 1, ATTN_NORM);
	else
		sound (self, CHAN_VOICE, "gargoyle/gargdie2.wav", 1, ATTN_NORM);    

	gargoyle_death1 ();
};

void () monster_gargoyle =
{
	//  Disable for testing
	if(monster_check())
		return;

	precache_model ("models/enemies/gargoyle.md3");
	precache_model ("models/world/leg1.md3");

	precache_sound ("gargoyle/gargclaw.wav");
	precache_sound ("gargoyle/gargdie1.wav");
	precache_sound ("gargoyle/gargdie2.wav");
	precache_sound ("gargoyle/gargdie3.wav");
	precache_sound ("gargoyle/gargpain.wav");
	precache_sound ("gargoyle/gargroam.wav");
	precache_sound ("gargoyle/gargspot.wav");
	precache_sound ("gargoyle/gargthro.wav");

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_FLY;
	setmodel (self, "models/enemies/gargoyle.md3");
	setsize (self,'-25 -31 0', '18 31 45');
	self.health = 200;
	self.max_health = self.health;
	self.th_stand = gargoyle_stand;
	self.th_walk = gargoyle_walk;
	self.th_run = gargoyle_run;
	self.th_die = gargoyle_die;
	self.th_pain = gargoyle_pain;
	self.th_missile = gargoyle_attack;
	flymonster_start ();
};
