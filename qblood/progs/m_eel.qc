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

/*
#define EEL_REFERENCE		0
#define EEL_IDLE				1
#define EEL_SWIM_START		2
#define EEL_SWIM_END		9
#define EEL_BITE_START		10
#define EEL_BITE_END			14
#define EEL_DEATH_START		15
#define EEL_DEATH_END		19

*/


$base base
$skin skin

$frame idle1

$frame swim1 swim2 swim3 swim4 swim5 swim6 swim7 swim8

$frame attack1 attack2 attack3

$frame death1 death2 death3 death4 death5 death6 death7 death8

void() swimmonster_start;

void() eel_stand1  =[      $idle1, eel_stand1 ]
{
	if (random() < 0.05)
		sound(self, CHAN_VOICE, "eel/eelroam.wav", 1, ATTN_NORM);

	ai_stand();
};

void() eel_walk1  =[      $swim1, eel_walk2 ] {ai_walk();};
void() eel_walk2  =[      $swim2, eel_walk3 ] {ai_walk();};
void() eel_walk3  =[      $swim3, eel_walk4 ] {ai_walk();};
void() eel_walk4  =[      $swim4, eel_walk5 ] {ai_walk();};
void() eel_walk5  =[      $swim5, eel_walk6 ] {ai_walk();};
void() eel_walk6  =[      $swim6, eel_walk7 ] {ai_walk();};
void() eel_walk7  =[      $swim7, eel_walk8 ] {ai_walk();};
void() eel_walk8  =[      $swim8, eel_walk1 ] {ai_walk();};

void() eel_run1  =[      $swim1, eel_run2 ] {ai_run();};
void() eel_run2  =[      $swim2, eel_run3 ] {ai_run();};
void() eel_run3  =[      $swim3, eel_run4 ] {ai_run();};
void() eel_run4  =[      $swim4, eel_run5 ] {ai_run();};
void() eel_run5  =[      $swim5, eel_run6 ] {ai_run();};
void() eel_run6  =[      $swim6, eel_run7 ] {ai_run();};
void() eel_run7  =[      $swim7, eel_run8 ] {ai_run();};
void() eel_run8  =[      $swim8, eel_run1 ] {ai_run();};

void() eel_melee =
{
	local vector    delta;
	local float     ldmg;

	if (!self.enemy)
		return;        // removed before stroke

	delta = self.enemy.origin - self.origin;

	if (vlen(delta) > 60)
		return;

	//sound(self, CHAN_VOICE, "eel/bite.wav", 1, ATTN_NORM); // FIXME: I need eel biting sound
	ldmg = (random() + random()) * 3;
	T_Damage(self.enemy, self, self, ldmg, DF_STAB, string_null);
};

void() eel_attack1 =[      $attack1,       eel_attack2 ] {ai_charge(10);};
void() eel_attack2 =[      $attack2,       eel_attack3 ] {eel_melee();};
void() eel_attack3 =[      $attack3,       eel_attack1 ] {ai_charge(10);};

void() eel_death1 =[      $death1,        eel_death2        ] {};
void() eel_death2 =[      $death2,        eel_death3        ] {};
void() eel_death3 =[      $death3,        eel_death4        ] {};
void() eel_death4 =[      $death4,        eel_death5        ] {};
void() eel_death5 =[      $death5,        eel_death6        ] {};
void() eel_death6 =[      $death6,        eel_death7        ] {};
void() eel_death7 =[      $death7,        eel_death8        ] {};
void() eel_death8 =[      $death8,        eel_death8         ]
{    
	// In the last frame, remove self 15 seconds after death
	self.nextthink = time + 15;
	self.think = SUB_Remove;
};

void() eel_death =
{
	local float     r;

	monster_death();

	r = random();

	if (r <= 0.33)
		sound(self, CHAN_VOICE, "eel/eeldie1.wav", 1, ATTN_NORM);
	else if (r <= 0.66)
		sound(self, CHAN_VOICE, "eel/eeldie2.wav", 1, ATTN_NORM);
	else
		sound(self, CHAN_VOICE, "eel/eeldie3.wav", 1, ATTN_NORM);

	if (self.health < -20)
	{        
		if (random() < 0.5)
			ThrowGib("models/objects/gib4.md3", self.health);
		else
			ThrowGib("models/objects/gib5.md3", self.health);

		remove(self);
		return;
	}
	else
		eel_death1();
};

void(entity attacker, float damage) eel_pain =
{

	// don't make multiple pain sounds right after each other
	if (self.pain_finished > time)
		return;

	sound(self, CHAN_VOICE, "eel/eelpain.wav", 1, ATTN_NORM);

	self.pain_finished = time + 1;
	//    ai_pain(12);	// deprecated
};

void() monster_eel =
{
	//  Disable for testing
	if(monster_check())
		return;

	precache_model("models/enemies/eel/bone_eel.psk");

	precache_sound("eel/eeldie1.wav");
	precache_sound("eel/eeldie2.wav");
	precache_sound("eel/eeldie3.wav");
	precache_sound("eel/eelpain.wav");
	precache_sound("eel/eelroam.wav");
	precache_sound("eel/eelspot.wav");

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel(self, "models/enemies/eel/bone_eel.psk");

	setsize(self, '-9 -1 -2', '6 1 2');
	self.health = 25;
	self.max_health = self.health;
	self.th_stand = eel_stand1;
	self.th_walk = eel_walk1;
	self.th_run = eel_run1;
	self.th_die = eel_death;
	self.th_pain = eel_pain;
	self.th_melee = eel_attack1;
	self.touch = monster_stepped_on;
	self.classname = "monster";
	self.netname = "monster_eel";
	swimmonster_start();
};
