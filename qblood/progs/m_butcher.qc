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
#include "player.qh"

// Prototypes

void () butcher_launch_cleaver;  	// Throw butcher's cleaver
void () butcher_launch_vomit;		// Throw up on player
void () butcher_push;				// Touch the player

// First

void (float dist) butcher_ai =
{
	if (self.style == 1)
		ai_stand ();
	else
	{
		if (self.style == 2)
			ai_walk (dist);
		else
		{
			if (self.style == 3)
			{
				ai_run (dist * 2);
				ai_face ();
			}
		}
	}
};

// Second

void () butcher_walk1 = [19, butcher_walk2]
{
	self.effects = 0;
	if (random () < 0.2)
		sound (self, CHAN_VOICE, "boss2/idle.wav", 1, ATTN_IDLE);
	butcher_ai (6);
};

void () butcher_walk2 = [20, butcher_walk3] {butcher_ai (4);};
void () butcher_walk3 = [21, butcher_walk4] {butcher_ai (3);};
void () butcher_walk4 = [22, butcher_walk5] {butcher_ai (5);};
void () butcher_walk5 = [23, butcher_walk6] {butcher_ai (6);};
void () butcher_walk6 = [24, butcher_walk7] {butcher_ai (4);};
void () butcher_walk7 = [25, butcher_walk8] {butcher_ai (3);};
void () butcher_walk8 = [26, butcher_walk9] {butcher_ai (3);};
void () butcher_walk9 = [27, butcher_walk10] {butcher_ai (3);};
void () butcher_walk10 = [28, butcher_walk11] {butcher_ai (3);};
void () butcher_walk11 = [29, butcher_walk12] {butcher_ai (3);};
void () butcher_walk12 = [30, butcher_walk1] {butcher_ai (3);};


void () butcher_stand =
{
	self.style = 1;
	butcher_walk1 ();
};

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


// Third

//--- Cleaver Throw
 
void () butcher_attacka1 = [31, butcher_attacka2] {ai_face ();};
void () butcher_attacka2 = [32, butcher_attacka3] {ai_face ();};
void () butcher_attacka3 = [33, butcher_attacka4] {ai_face ();};
void () butcher_attacka4 = [34, butcher_attacka5] {ai_face ();};
void () butcher_attacka5 = [35, butcher_attacka6] {ai_face ();};
void () butcher_attacka6 = [36, butcher_attacka7] {ai_face ();};
void () butcher_attacka7 = [37, butcher_attacka8] {ai_face ();};
void () butcher_attacka8 = [38, butcher_attacka9] {ai_face ();};
void () butcher_attacka9 = [39, butcher_attacka10] {ai_face ();};
void () butcher_attacka10 = [40, butcher_attacka11] {ai_face ();};
void () butcher_attacka11 = [41, butcher_attacka12] {butcher_launch_cleaver ();ai_face ();};
void () butcher_attacka12 = [42, butcher_run] {ai_face ();};

//--- Vomiting 

void () butcher_attackb1 = [43, butcher_attackb2] {ai_face ();};
void () butcher_attackb2 = [44, butcher_attackb3] {ai_face ();};
void () butcher_attackb3 = [45, butcher_attackb4] {ai_face ();};
void () butcher_attackb4 = [46, butcher_attackb5] {ai_face ();};
void () butcher_attackb5 = [47, butcher_attackb6] {ai_face ();};
void () butcher_attackb6 = [48, butcher_attackb7] {ai_face ();};
void () butcher_attackb7 = [49, butcher_attackb8] {butcher_launch_vomit ();ai_face ();};
void () butcher_attackb8 = [50, butcher_run] {ai_face ();};

//--- "Touch" attack

void () butcher_attackc1 = [26, butcher_run] {ai_face ();butcher_push ();};


void () butcher_attack =
{
	local vector delta;

	delta = (self.enemy.origin - self.origin);
	if (vlen (delta) <= 90)  	// If the player is near nudge them
		butcher_attackc1 ();
	else
	{
		if ((vlen (delta) <= 300) && (random () < 0.5))
			butcher_attackb1 ();
		else
			butcher_attacka1 ();
	}
};



void () butcher_MissileTouch =
{
	local float damg;

	if (other == self.owner)
		return;
	if (pointcontents (self.origin) == CONTENT_SKY)
	{
		remove (self);
		return;
	}
	damg = (50+ (random () * 20));
	if (other.health)
		T_Damage (other,self,self.owner,damg, DF_BODY, string_null);

	T_RadiusDamage (self, self.owner, 120, other, string_null);
	self.origin = (self.origin - (8* normalize (self.velocity)));
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	BecomeExplosion ();
};

// Throw butcher's cleaver

void () butcher_launch_cleaver =
{
	local vector vec;

	sound (self, CHAN_WEAPON, "shalrath/attack2.wav", 1, ATTN_NORM);
	vec = (self.enemy.origin - self.origin);
	vec = normalize (vec);

	newmis = spawn ();
	newmis.owner = self;

	newmis.solid = SOLID_BBOX;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	setmodel (newmis, "progs/cleaver.mdl");
	setsize (newmis, '0 0 0', '0 0 0');	
	newmis.origin = self.origin + '0 0 16';
	newmis.velocity = vec * 600;
	newmis.avelocity = '500 500 500';
	newmis.touch = butcher_MissileTouch;
	self.effects = 0;
};


// Throw up on player

void () butcher_launch_vomit =
{
	local vector vec;

	sound (self, CHAN_WEAPON, "shalrath/attack2.wav", 1, ATTN_NORM);
	vec = (self.enemy.origin - self.origin);
	vec = normalize (vec);

	newmis = spawn ();
	newmis.owner = self;

	newmis.solid = SOLID_BBOX;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	setmodel (newmis, "progs/vomit.mdl");
	setsize (newmis, '0 0 0', '0 0 0');	
	newmis.origin = self.origin + '0 0 16';
	newmis.velocity = vec * 600;
	newmis.avelocity = '500 500 500';
	newmis.touch = butcher_MissileTouch;
	self.effects = 0;
};

void () butcher_push =
{
	local vector delta;
	local float ldmg;

	if (self.enemy.classname != "player") // To avoid hurting monster buddies
		return;
		
	delta = (self.enemy.origin - self.origin);
	ldmg = (random () * 25);
	T_Damage (self.enemy, self, self, ldmg, DF_BODY, string_null);
	sound (self, CHAN_WEAPON, "wizard/wsight.wav", 1, ATTN_NORM);
	self.enemy.flags = self.enemy.flags - (self.enemy.flags & FL_ONGROUND);
	self.enemy.velocity = (delta * 10);
	self.enemy.velocity_z = 100;
};


// Fourth

/* 
The butcher_attack determines what attack to actually use. 
Take some time and study these functions. 
The butcher_Push will only affect players, 
if I remember correctly from when I originally created this, 
pushing monsters will cause some bug. Next is pain, death, and spawning:
*/

void () butcher_pain1 = [51, butcher_pain2] {};
void () butcher_pain2 = [52, butcher_pain3] {};
void () butcher_pain3 = [53, butcher_pain4] {};
void () butcher_pain4 = [54, butcher_run] {}; 


void () butcher_pain =
{
	if (self.pain_finished > time)
		return;
	sound (self,2,"wizard/wdeath.wav",1,1);
	butcher_pain1 ();
	self.pain_finished = (time + 3);
};

void () butcher_death1 = [55, butcher_death2] {};
void () butcher_death2 = [56, butcher_death3] {};
void () butcher_death3 = [57, butcher_death4] {};
void () butcher_death4 = [58, butcher_death5] {};
void () butcher_death5 = [59, butcher_death6] {};
void () butcher_death6 = [60, butcher_death7] {};
void () butcher_death7 = [61, butcher_death8] {};
void () butcher_death8 = [62, butcher_death9] {};
void () butcher_death9 = [63, butcher_death10] {};
void () butcher_death10 = [64, butcher_death11] {};
void () butcher_death11 = [65, butcher_death12] {};
void () butcher_death12 = [66, butcher_death13] {};
void () butcher_death13 = [67, butcher_death13] {};

void () butcher_die =
{
	self.effects = 0;
	if (self.health < -40)
	{
		sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
		ThrowHead (self.health);  // FIXME: At some point need to drop butcher head
		ThrowGib ("progs/gib1.mdl", self.health);
		ThrowGib ("progs/gib2.mdl", self.health);
		ThrowGib ("progs/gib3.mdl", self.health);
		return;
	}
	sound (self, CHAN_VOICE, "blob/death1.wav", 1, ATTN_NORM);
	butcher_death1 ();
	self.solid = SOLID_NOT;
};

void () monster_butcher =
{
	if (deathmatch)
	{
		remove (self);
		return ;
	}
	precache_model ("models/enemies/butcher.md3");
	precache_model ("progs/h_shal.mdl");
	precache_sound ("wizard/wdeath.wav");
	precache_sound ("wizard/wsight.wav");
	precache_sound ("blob/death1.wav");
	precache_sound ("boss2/idle.wav");
	precache_sound ("shalrath/attack2.wav");
	precache_sound ("shalrath/sight.wav");

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;
	setmodel (self, "models/enemies/butcher.md3");
	setsize (self,'-32 -32 -24','32 32 64');
	self.health = 500;
	self.th_stand = butcher_stand;
	self.th_walk = butcher_walk;
	self.th_run = butcher_run;
	self.th_die = butcher_die;
	self.th_pain = butcher_pain;
	self.th_missile = butcher_attack;
	walkmonster_start ();
};


