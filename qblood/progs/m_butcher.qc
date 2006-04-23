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
$frame idle1 idle2 idle3 idle4 idle5 idle6 idle7 idle8 idle9 idle10 idle11 idle12 idle13 idle14 idle15 idle16

// special idle
$frame idlea1 idlea2 idlea3 idlea4 idlea5 idlea6 idlea7 idlea8 idlea9 idlea10 idlea11 idlea12 idlea13 idlea14 idlea15
$frame idlea16 idlea17 idlea18 idlea19 idlea20 idlea21 idlea22 idlea23 idlea24 idlea25 idlea26 idlea27 idlea28 idlea29 idlea30

// walk
$frame walk1 walk2 walk3 walk4 walk5 walk6
$frame walk7 walk8 walk9 walk10 walk11 walk12

//attack1
$frame attacka1 attacka2 attacka3 attacka4 attacka5 attacka6
$frame attacka7 attacka8 attacka9 attacka10 attacka11 attacka12

//attack2
$frame attackb1 attackb2 attackb3 attackb4 attackb5 attackb6 attackb7 attackb8

//pain
$frame pain1 pain2 pain3 pain4

//death
$frame death1 death2 death3 death4 death5 death6 death7
$frame death8 death9 death10 death11 death12 death13

// Prototypes
void () butcher_launch_cleaver;     // Throw butcher's cleaver
void () butcher_launch_vomit;       // Throw up on player
void () butcher_stand1;             // Minor shoulder shrugging and undead breathing
void () butcher_standa1;            // Bad habits... kids- don't pick your nose!
void () butcher_VomitTouch;         // When struck by vomit
void () butcher_CleaverTouch;       // When struck by cleaver
void () butcher_CleaverChop;        // Melee cleaver whack

//--- Walking around
void () butcher_walk1 = [$walk1, butcher_walk2] {basic_ai (3);};
void () butcher_walk2 = [$walk2, butcher_walk3] {basic_ai (3);};
void () butcher_walk3 = [$walk3, butcher_walk4] {basic_ai (3);};
void () butcher_walk4 = [$walk4, butcher_walk5] {basic_ai (3);};
void () butcher_walk5 = [$walk5, butcher_walk6] {basic_ai (3);};
void () butcher_walk6 = [$walk6, butcher_walk7] {basic_ai (3);};
void () butcher_walk7 = [$walk7, butcher_walk8] {basic_ai (3);};
void () butcher_walk8 = [$walk8, butcher_walk9] {basic_ai (3);};
void () butcher_walk9 = [$walk9, butcher_walk10] {basic_ai (3);};
void () butcher_walk10 = [$walk10, butcher_walk11] {basic_ai (3);};
void () butcher_walk11 = [$walk11, butcher_walk12] {basic_ai (3);};
void () butcher_walk12 = [$walk12, butcher_walk1] {basic_ai (3);};

//--- Decide which idle to do
void () butcher_stand =
{
	if (random () < 0.1)
	sound (self, CHAN_WEAPON, "butcher/fzomroam.wav", 1, ATTN_NORM);

	if (random () < 0.05)
		butcher_standa1();
	else
		butcher_stand1();
};

//--- Huff and puff sequence
void () butcher_stand1 = [$idle1, butcher_stand2] {ai_stand();};
void () butcher_stand2 = [$idle2, butcher_stand3] {ai_stand();};
void () butcher_stand3 = [$idle3, butcher_stand4] {ai_stand();};
void () butcher_stand4 = [$idle4, butcher_stand5] {ai_stand();};
void () butcher_stand5 = [$idle5, butcher_stand6] {ai_stand();};
void () butcher_stand6 = [$idle6, butcher_stand7] {ai_stand();};
void () butcher_stand7 = [$idle7, butcher_stand8] {ai_stand();};
void () butcher_stand8 = [$idle8, butcher_stand9] {ai_stand();};
void () butcher_stand9 = [$idle9, butcher_stand10] {ai_stand();};
void () butcher_stand10 = [$idle10, butcher_stand11] {ai_stand();};
void () butcher_stand11 = [$idle11, butcher_stand12] {ai_stand();};
void () butcher_stand12 = [$idle12, butcher_stand13] {ai_stand();};
void () butcher_stand13 = [$idle13, butcher_stand14] {ai_stand();};
void () butcher_stand14 = [$idle14, butcher_stand15] {ai_stand();};
void () butcher_stand15 = [$idle15, butcher_stand16] {ai_stand();};
void () butcher_stand16 = [$idle16, butcher_stand] {};

//--- Pick nose
void () butcher_standa1 = [$idlea1, butcher_standa2] {ai_stand();};
void () butcher_standa2 = [$idlea2, butcher_standa3] {ai_stand();};
void () butcher_standa3 = [$idlea3, butcher_standa4] {ai_stand();};
void () butcher_standa4 = [$idlea4, butcher_standa5] {ai_stand();};
void () butcher_standa5 = [$idlea5, butcher_standa6] {ai_stand();};
void () butcher_standa6 = [$idlea6, butcher_standa7] {ai_stand();};
void () butcher_standa7 = [$idlea7, butcher_standa8] {ai_stand();};
void () butcher_standa8 = [$idlea8, butcher_standa9] {ai_stand();};
void () butcher_standa9 = [$idlea9, butcher_standa10] {ai_stand();};
void () butcher_standa10 = [$idlea10, butcher_standa11] {ai_stand();};
void () butcher_standa11 = [$idlea11, butcher_standa12] {ai_stand();};
void () butcher_standa12 = [$idlea12, butcher_standa13] {ai_stand();};
void () butcher_standa13 = [$idlea13, butcher_standa14] {ai_stand();};
void () butcher_standa14 = [$idlea14, butcher_standa15] {ai_stand();};
void () butcher_standa15 = [$idlea15, butcher_standa16] {ai_stand();};
void () butcher_standa16 = [$idlea16, butcher_standa17] {ai_stand();};
void () butcher_standa17 = [$idlea17, butcher_standa18] {ai_stand();};
void () butcher_standa18 = [$idlea18, butcher_standa19] {ai_stand();};
void () butcher_standa19 = [$idlea19, butcher_standa20] {ai_stand();};
void () butcher_standa20 = [$idlea20, butcher_standa21] {ai_stand();};
void () butcher_standa21 = [$idlea21, butcher_standa22] {ai_stand();};
void () butcher_standa22 = [$idlea22, butcher_standa23] {ai_stand();};
void () butcher_standa23 = [$idlea23, butcher_standa24] {ai_stand();};
void () butcher_standa24 = [$idlea24, butcher_standa25] {ai_stand();};
void () butcher_standa25 = [$idlea25, butcher_standa26] {ai_stand();};
void () butcher_standa26 = [$idlea26, butcher_standa27] {ai_stand();};
void () butcher_standa27 = [$idlea27, butcher_standa28] {ai_stand();};
void () butcher_standa28 = [$idlea28, butcher_standa29] {ai_stand();};
void () butcher_standa29 = [$idlea29, butcher_standa30] {ai_stand();};
void () butcher_standa30 = [$idlea30, butcher_stand] {};

void () butcher_walk =
{
	self.style = 2;
	butcher_walk1 ();
};

void () butcher_run =
{
	self.style = 3;
	butcher_walk1 ();
};

//--- Cleaver Throw
void () butcher_attacka1 = [$attacka1, butcher_attacka2] {ai_face ();};
void () butcher_attacka2 = [$attacka2, butcher_attacka3] {ai_face ();};
void () butcher_attacka3 = [$attacka3, butcher_attacka4] {ai_face ();};
void () butcher_attacka4 = [$attacka4, butcher_attacka5] {ai_face ();};
void () butcher_attacka5 = [$attacka5, butcher_attacka6] {ai_face ();};
void () butcher_attacka6 = [$attacka6, butcher_attacka7] {ai_face ();};
void () butcher_attacka7 = [$attacka7, butcher_attacka8] {ai_face ();};
void () butcher_attacka8 = [$attacka8, butcher_attacka9] {ai_face ();};
void () butcher_attacka9 = [$attacka9, butcher_attacka10] {butcher_launch_cleaver (); ai_face ();};
void () butcher_attacka10 = [$attacka10, butcher_attacka11] {ai_face ();};
void () butcher_attacka11 = [$attacka11, butcher_attacka12] {ai_face ();};
void () butcher_attacka12 = [$attacka12, butcher_run] {ai_face ();};

//--- Vomiting
void () butcher_attackb1 = [$attackb1, butcher_attackb2] {ai_face ();};
void () butcher_attackb2 = [$attackb2, butcher_attackb3] {ai_face ();};
void () butcher_attackb3 = [$attackb3, butcher_attackb4] {ai_face ();};
void () butcher_attackb4 = [$attackb4, butcher_attackb5] {ai_face ();};
void () butcher_attackb5 = [$attackb5, butcher_attackb6] {ai_face ();};
void () butcher_attackb6 = [$attackb6, butcher_attackb7] {ai_face ();};
void () butcher_attackb7 = [$attackb7, butcher_attackb8] {butcher_launch_vomit ();ai_face ();};
void () butcher_attackb8 = [$attackb8, butcher_run] {ai_face ();};

//--- Cleaver chop
void () butcher_attackc1 = [$attacka1, butcher_attackc2] {ai_face ();};
void () butcher_attackc2 = [$attacka2, butcher_attackc3] {ai_face ();};
void () butcher_attackc3 = [$attacka3, butcher_attackc4] {ai_face ();};
void () butcher_attackc4 = [$attacka4, butcher_attackc5] {ai_face ();};
void () butcher_attackc5 = [$attacka5, butcher_attackc6] {ai_face ();};
void () butcher_attackc6 = [$attacka6, butcher_attackc7] {ai_face ();};
void () butcher_attackc7 = [$attacka7, butcher_attackc8] {ai_face ();};
void () butcher_attackc8 = [$attacka8, butcher_attackc9] {ai_face ();};
void () butcher_attackc9 = [$attacka9, butcher_attackc10] {butcher_CleaverChop(); ai_face ();};
void () butcher_attackc10 = [$attacka10, butcher_attackc11] {ai_face ();};
void () butcher_attackc11 = [$attacka11, butcher_attackc12] {ai_face ();};
void () butcher_attackc12 = [$attacka12, butcher_run] {ai_face ();};

void () butcher_attack =
{
	local float dist;

	dist = vlen(self.enemy.origin - self.origin);

	if (dist < 90)// chop player with cleaver
		butcher_attackc1 ();

	else if (dist < 500)
	{
		// Vomit acid ball
		self.attack_state = AS_MISSILE;
		butcher_attackb1 ();
	}

	else
	{
		// Throw cleaver
		self.attack_state = AS_MISSILE;
		butcher_attacka1 ();
	}
};

//--- Throw butcher's cleaver
void () butcher_launch_cleaver =
{
	local vector vec;

	sound (self, CHAN_WEAPON, "butcher/cleaver.wav", 1, ATTN_NORM);
	vec = (self.enemy.origin - self.origin);
	vec = normalize (vec);

	newmis = spawn ();
	newmis.owner = self;

	newmis.solid = SOLID_BBOX;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	setmodel (newmis, "models/enemies/butcher_cleaver.md3");
	setsize (newmis, '0 0 0', '0 0 0');
	newmis.origin = self.origin + '0 -8 20';
	newmis.velocity = vec * 600;
	newmis.avelocity = '500 500 500';
	newmis.touch = butcher_CleaverTouch;    
};

//--- Cleaver hit something solid, now what?
void () butcher_CleaverTouch =
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

		T_Damage (other,self,self.owner,damg, DF_STAB, string_null);
	}

	self.origin = (self.origin - (8* normalize (self.velocity)));
	remove (self);
};

//--- Throw up on player
void () butcher_launch_vomit =
{
	local vector vec;

	sound (self, CHAN_WEAPON, "butcher/fzompuke.wav", 1, ATTN_NORM);
	vec = (self.enemy.origin - self.origin);
	vec = normalize (vec);

	newmis = spawn ();
	newmis.owner = self;

	newmis.solid = SOLID_BBOX;
	newmis.movetype = MOVETYPE_FLY;
	setmodel (newmis, "models/enemies/vomit.md3"); // FIXME: Switch to vomit once model is made
	setsize (newmis, '0 0 0', '0 0 0');
	newmis.origin = self.origin + '0 0 28';
	newmis.velocity = vec * 600;
	newmis.avelocity = '500 500 500';
	newmis.touch = butcher_VomitTouch;    
};

//--- Vomit hit something solid, now what?
void () butcher_VomitTouch =
{
	local float damg;

	if (other == self.owner)
		return;

	if (pointcontents (self.origin) == CONTENT_SKY)
	{
		remove (self);
		return;
	}

	if (other.health)  // If it's a hurtable object (i.e. non-wall)
	{
		damg = (10+ (random () * 40));    // FIXME: I need the "real" values

		if (damg > 25)
			sound (self, CHAN_WEAPON, "butcher/acidhit1.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_WEAPON, "butcher/acidhit2.wav", 1, ATTN_NORM);

		T_Damage (other,self,self.owner,damg, DF_ACID, string_null);	// Correct damagetype?
	}

	self.origin = (self.origin - (8* normalize (self.velocity)));
	remove (self);
};

void () butcher_CleaverChop =
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
	sound (self, CHAN_WEAPON, "weapons/pitchfrk/pflesh.wav", 1, ATTN_NORM);
};

//--- Pain sequence
void () butcher_pain1 = [$pain1, butcher_pain2] {};	//if (self.deathtype != "fire") ai_pain(3);};
void () butcher_pain2 = [$pain2, butcher_pain3] {};	//if (self.deathtype != "fire") ai_pain(3);};
void () butcher_pain3 = [$pain3, butcher_pain4] {};	//if (self.deathtype != "fire") ai_pain(3);};
void () butcher_pain4 = [$pain4, butcher_run] {}; 	//if (self.deathtype != "fire") ai_pain(3);};

void () butcher_pain =
{
	// don't make multiple pain sounds right after each other
	if (self.pain_finished > time)
		return;

	sound (self,2,"butcher/fzompain.wav",1,1);
	butcher_pain1 ();
	self.pain_finished = (time + 1.01);
};

//--- Death sequence
void () butcher_death1 = [$death1, butcher_death2] {};
void () butcher_death2 = [$death2, butcher_death3] {};
void () butcher_death3 = [$death3, butcher_death4] {};
void () butcher_death4 = [$death4, butcher_death5] {};
void () butcher_death5 = [$death5, butcher_death6] {};
void () butcher_death6 = [$death6, butcher_death7] {};
void () butcher_death7 = [$death7, butcher_death8] {};
void () butcher_death8 = [$death8, butcher_death9] {};
void () butcher_death9 = [$death9, butcher_death10] {};
void () butcher_death10 = [$death10, butcher_death11] {};
void () butcher_death11 = [$death11, butcher_death12] {};
void () butcher_death12 = [$death12, butcher_death13] {};
void () butcher_death13 = [$death13, butcher_death13] {monster_become_corpse();};

// Sequence for burn or voodoo death
void () butcher_explode1 = [0, butcher_explode2] {};
void () butcher_explode2 = [1, butcher_explode3] {};
void () butcher_explode3 = [2, butcher_explode4] {};
void () butcher_explode4 = [3, butcher_explode5] {};
void () butcher_explode5 = [4, butcher_explode6] {};
void () butcher_explode6 = [5, butcher_explode7] {};
void () butcher_explode7 = [6, butcher_explode8] {};
void () butcher_explode8 = [7, butcher_explode9] {};
void () butcher_explode9 = [8, butcher_explode10] {};
void () butcher_explode10 = [9, butcher_explode10]
{
	// In the last frame, remove self 15 seconds after death
	self.nextthink = time + 15;
	self.think = SUB_Remove;
};

void () butcher_die =
{
	monster_death();

	if (self.health < -40)
	{
		sound (self, CHAN_VOICE, "butcher/fzomdie3.wav", 1, ATTN_NORM);

		// Very large blood splat!
		te_bloodshower (self.origin, self.origin + self.size, 100, 150);

		ThrowHead ("models/enemies/butcher_head.md3", self.health);

		// Make new head 100% null
		self.think = self.th_stand = self.th_walk = self.th_run = self.th_pain = self.th_missile = SUB_Null;

		self.nextthink = time + 0.1;
		self.classname = "head";
		self.touch = HeadTouch;
		BecomeCorpse (80, HeadDie);

		RandomHumanGibs ();
		RandomHumanGibs (); // Many gibs!
		return;
	}

	if (random () < 0.5)
		sound (self, CHAN_VOICE, "butcher/fzomdie1.wav", 1, ATTN_NORM);
	else
		sound (self, CHAN_VOICE, "butcher/fzomdie2.wav", 1, ATTN_NORM);    

	if (self.deathtype == "fire" || self.deathtype == "alt-voodoo")
	{        
		setmodel (self, "models/enemies/butcher_explode.md3");
		setsize (self, '-7 -11 0', '4 8 51');
		butcher_explode1 ();
	}

	else
		butcher_death1 ();

};

void () monster_butcher =
{
	//  Disable for testing
	if(monster_check())
		return;

	precache_model ("models/enemies/butcher.md3");
	precache_model ("models/enemies/butcher_cleaver.md3");
	precache_model ("models/enemies/butcher_head.md3");
	precache_model ("models/enemies/butcher_explode.md3");
	precache_model ("models/enemies/vomit.md3");

	precache_sound ("butcher/acidhit1.wav");
	precache_sound ("butcher/acidhit2.wav");
	precache_sound ("butcher/cleaver.wav");
	precache_sound ("butcher/fzomdie1.wav");
	precache_sound ("butcher/fzomdie2.wav");
	precache_sound ("butcher/fzomdie3.wav");
	precache_sound ("butcher/fzompain.wav");
	precache_sound ("butcher/fzompuke.wav");
	precache_sound ("butcher/fzomroam.wav");
	precache_sound ("butcher/fzomspot.wav");


	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_TOSS;
	setmodel (self, "models/enemies/butcher.md3");
	setsize (self,'-8 -11 0', '11 11 50');
	self.health = 90;
	self.resist_acid = -1;	// immune probably
	self.resist_shock = 2;
	self.resist_pummel = 0;
	self.resist_fall = 0;
	self.resist_burn = 0;
	self.resist_bullet = 7;
	self.resist_stab = 16;
	self.resist_explode = 0;
	self.resist_gas = 0;
	self.resist_drown = -1;	// cannot drown
	self.resist_spirit = 0;
	self.resist_voodoo = 0;
	self.max_health = self.health;
	self.th_stand = butcher_stand;
	self.th_walk = butcher_walk;
	self.th_run = butcher_run;
	self.th_die = butcher_die;
	self.th_pain = butcher_pain;
	self.th_missile = butcher_attack;
	self.touch = monster_stepped_on;
	self.classname = "monster";
	self.classname = "monster_butcher";
	walkmonster_start ();
};
