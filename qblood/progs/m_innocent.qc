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

#define INNOCENT_REFERENCE      0
#define INNOCENT_STAND_START    1
#define INNOCENT_STAND_END      60
#define INNOCENT_RUN_START      61
#define INNOCENT_RUN_END        90
#define INNOCENT_PAIN_START     91
#define INNOCENT_PAIN_END       110
#define INNOCENT_DEATH_START    111
#define INNOCENT_DEATH_END      150

#define INNOCENT_STAND_TIME     3.0
#define INNOCENT_RUN_TIME       1.0
#define INNOCENT_PAIN_TIME      1.0
#define INNOCENT_DEATH_TIME     2.0

void() innocent_animate;

void() innocent_stand =
{
	self.style = 1;
	self.anim_type = STAND;
	innocent_animate();
};

void() innocent_run =
{
	self.style = 3;
	self.anim_type = RUN;
	innocent_animate();
};

void() innocent_think =
{
	// See if there's something to run away from in area
	if (ai_search_area(100))
	{
		self.search_time = rint(time + 15 + rint(random()*5));
		self.show_hostile = time + 1;       // wake up other monsters
	}

	if (self.search_time >= time) //|| self.enemy != world)
		innocent_run();
	else 
		innocent_stand();
};	

void(entity attacker, float damage) innocent_pain =
{
	local float     r;

	self.search_time = rint(time + 15 + rint(random()*5));

	// don't make multiple pain sounds right after each other
	if (self.pain_finished > time)
		return;

	r = random();

	if (r <= 0.5)
		sound(self, CHAN_VOICE, "innocent/iscream1.wav", 1, ATTN_NORM);
	else
		sound(self, CHAN_VOICE, "innocent/iscream2.wav", 1, ATTN_NORM);

	r = random();
	if (r >= 0.5)
	{

		r = random();

		if (r <= 0.125)
		{
			sound(self, CHAN_VOICE, "innocent/icrying.wav", 1, ATTN_NORM);
			self.pain_finished = time + 1.82;
		}
		else if (r <= 0.25)
		{
			sound(self, CHAN_VOICE, "innocent/icrying2.wav", 1, ATTN_NORM);
			self.pain_finished = time + 1.46;
		}
		else if (r <= 0.375)
		{
			sound(self, CHAN_VOICE, "innocent/idonhme.wav", 1, ATTN_NORM);
			self.pain_finished = time + 0.63;
		}
		else if (r <= 0.5)
		{
			sound(self, CHAN_VOICE, "innocent/igoaway2.wav", 1, ATTN_NORM);
			self.pain_finished = time + 1.12;
		}
		else if (r <= 0.625)
		{
			sound(self, CHAN_VOICE, "innocent/igoaway3.wav", 1, ATTN_NORM);
			self.pain_finished = time + 1.23;
		}
		else if (r <= 0.75)
		{
			sound(self, CHAN_VOICE, "innocent/inoplace.wav", 1, ATTN_NORM);
			self.pain_finished = time + 1.1;
		}
		else if (r <= 0.875)
		{
			sound(self, CHAN_VOICE, "innocent/iplease.wav", 1, ATTN_NORM);
			self.pain_finished = time + 1.24;
		}
		else
		{
			sound(self, CHAN_VOICE, "innocent/sobbing.wav", 1, ATTN_NORM);
			self.pain_finished = time + 3.2;
		}
	}
	else
		self.pain_finished = time + 1;


	self.enemy = attacker;

	self.anim_type = PAIN;
	innocent_animate();
};

void() innocent_death =
{
	local float     r;

	monster_death();

	if (self.health < -40)
	{
		// Very large blood splat!
		te_bloodshower(self.origin, self.origin + self.size, 100, 100);

		sound(self, CHAN_VOICE, "innocent/iscream1.wav", 1, ATTN_NORM);
		RandomHumanGibs();
		remove(self);
		return;
	}

	r = random();

	if (r <= 0.125)
		sound(self, CHAN_VOICE, "innocent/icrying.wav", 1, ATTN_NORM);
	else if (r <= 0.25)
		sound(self, CHAN_VOICE, "innocent/icrying2.wav", 1, ATTN_NORM);
	else if (r <= 0.375)
		sound(self, CHAN_VOICE, "innocent/idonhme.wav", 1, ATTN_NORM);
	else if (r <= 0.5)
		sound(self, CHAN_VOICE, "innocent/igoaway2.wav", 1, ATTN_NORM);
	else if (r <= 0.625)
		sound(self, CHAN_VOICE, "innocent/igoaway3.wav", 1, ATTN_NORM);
	else if (r <= 0.75)
		sound(self, CHAN_VOICE, "innocent/inoplace.wav", 1, ATTN_NORM);
	else if (r <= 0.875)
		sound(self, CHAN_VOICE, "innocent/iplease.wav", 1, ATTN_NORM);
	else
		sound(self, CHAN_VOICE, "innocent/sobbing.wav", 1, ATTN_NORM);

	self.anim_type = DEATH;
	innocent_animate();
};

/*
============
innocent_animate

Animation and frame based code for the Innocent
============
*/
void() innocent_animate =
{
	if (self.anim_type == self.last_action)
	{
		if (self.frame < self.anim_end)
			self.frame = self.frame + 1;
		else
			self.frame = self.anim_end -  self.anim_end_num + 1;
	}
	else
	{
		if (self.anim_type == STAND)
		{
			self.anim_end = INNOCENT_STAND_END;
			self.anim_end_num = INNOCENT_STAND_END - INNOCENT_STAND_START + 1; //add one to compensate for the first frame not being counted
			self.anim_time = INNOCENT_STAND_TIME; // one idle animation lasts 2.5 seconds
			self.frame = INNOCENT_STAND_START;
		}
		else if (self.anim_type == RUN)
		{
			self.anim_end = INNOCENT_RUN_END;
			self.anim_end_num = INNOCENT_RUN_END - INNOCENT_RUN_START + 1;
			self.anim_time = INNOCENT_RUN_TIME;
			self.frame = INNOCENT_RUN_START;
		}
		else if (self.anim_type == PAIN)
		{
			self.anim_end = INNOCENT_PAIN_END;
			self.anim_end_num = INNOCENT_PAIN_END - INNOCENT_PAIN_START + 1;
			self.anim_time = INNOCENT_PAIN_TIME;
			if (self.frame > self.anim_end)
				self.th_run();
			else
				self.frame = INNOCENT_PAIN_START;
		}
		else if (self.anim_type == DEATH)
		{
			self.anim_end = INNOCENT_DEATH_END;
			self.anim_end_num = INNOCENT_DEATH_END - INNOCENT_DEATH_START + 1;
			self.anim_time = INNOCENT_DEATH_TIME;
			self.frame = INNOCENT_DEATH_START;
		}

		self.last_action = self.anim_type;
	}
	self.nextthink = time + (self.anim_time / self.anim_end_num);
	self.think = innocent_animate;

	if ((self.anim_type == DEATH) && (self.frame == self.anim_end))
	{
		self.nextthink = 0;
		monster_become_corpse();
	}

	/*ai_main();
	//insert sounds or attack damage here with if statements*/
	if (self.anim_type == STAND)
		self.think = innocent_think;
	if (self.anim_type == RUN)
		ai_run_away(4);
};

void() monster_innocent =
{
	//  Disable for testing
	if(monster_check())
		return;

	precache_model("models/enemies/innocent/innocent.psk");
	precache_sound("innocent/icrying.wav");
	precache_sound("innocent/icrying2.wav");
	precache_sound("innocent/idonhme.wav");
	precache_sound("innocent/igoaway2.wav");
	precache_sound("innocent/igoaway3.wav");
	precache_sound("innocent/inoplace.wav"); // There's no place like home!
	precache_sound("innocent/iplease.wav");
	precache_sound("innocent/iscream1.wav"); // Pain
	precache_sound("innocent/iscream2.wav"); // Pain
	precache_sound("innocent/sobbing.wav");

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_WALK;
	setmodel(self, "models/enemies/innocent/innocent.psk");
	setsize(self, '-6.7 -24.3 -0.2', '14.3 24.3 55.9');
	self.health = 40;
	self.resist_acid = 0;
	self.resist_shock = 0;
	self.resist_pummel = 0;
	self.resist_fall = 0;
	self.resist_burn = 0;
	self.resist_bullet = 0;
	self.resist_stab = 4;
	self.resist_explode = 0;
	self.resist_gas = 0;
	self.resist_drown = -1;	// cannot drown
	self.resist_spirit = 0;
	self.resist_voodoo = 0;    
	self.max_health = self.health;
	self.th_stand = innocent_think;
	self.th_walk = innocent_think;
	self.th_run = innocent_think;
	self.th_die = innocent_death;
	self.th_pain = innocent_pain;
	self.oldorigin = self.origin;
	self.touch = monster_stepped_on;
	self.classname = "monster_innocent";
	self.netname = "Innocent";
	walkmonster_start();
};
