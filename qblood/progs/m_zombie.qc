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

//Frame definitions
#define ZOMBIE_REFERENCE        0
#define	ZOMBIE_STAND_START		1		//Stand = frames 0-59
#define	ZOMBIE_STAND_END		60
#define	ZOMBIE_RUN_START		61		//Run (and walk) = frames 60-89
#define	ZOMBIE_RUN_END			90
#define	ZOMBIE_PAIN_START		91		//Pain = frames 90-114
#define	ZOMBIE_PAIN_END			115
#define	ZOMBIE_DEATH1_START		116		//Death1 = frames 115-144
#define	ZOMBIE_DEATH1_END		145		//Death1 has a head, Death2 does not
#define	ZOMBIE_ATTACK_START		146		//Attack = frames 145-174
#define	ZOMBIE_ATTACK_END		175
#define	ZOMBIE_ARISE_START		176		//Arise = frames 175-219
#define	ZOMBIE_ARISE_END		220
#define ZOMBIE_FALLBACK_START	221		//FallBack = frames 220 - 239
#define	ZOMBIE_FALLBACK_END		240
#define ZOMBIE_STANDUP_START	241		//StandUp = frames 240 - 274
#define ZOMBIE_STANDUP_END		270
#define	ZOMBIE_HIDE_START		176		//really just the first arise frame
#define	ZOMBIE_HIDE_END			176		//single frame only
#define ZOMBIE_DEATH2_START		1		//Death2 animation is a seperate model
#define ZOMBIE_DEATH2_END		30
#define ZOMBIE_EXPLODE_START	0		//Explode animation is also a seperate model
#define ZOMBIE_EXPLODE_END		15

//Animation Timing Configuration in seconds
#define	ZOMBIE_STAND_TIME		2.5
#define	ZOMBIE_RUN_TIME			1.2
#define	ZOMBIE_WALK_TIME		1.2
#define	ZOMBIE_PAIN_TIME		0.75
#define	ZOMBIE_FALLBACK_TIME	1.0
#define ZOMBIE_STANDUP_TIME		1.25
#define	ZOMBIE_ATTACK_TIME		0.85
#define	ZOMBIE_ARISE_TIME		1.5
#define ZOMBIE_HIDE_TIME		0.1
#define	ZOMBIE_DEATH1_TIME		1.2
#define ZOMBIE_DEATH2_TIME		1.2
#define ZOMBIE_EXPLODE_TIME		1.2

void () zombie_animate;

void () zombie_fallback =
{
	self.anim_type = FALLBACK;
	zombie_animate();
};

void () zombie_standup =
{
	if (self.anim_type == FALLBACK)
		self.nextthink = time + 1.5;
	self.anim_type = STANDUP;
	self.think = zombie_animate;
};

void () zombie_arise =
{
	sound(self, CHAN_VOICE, "axezombie/azomrise.wav", 1, ATTN_NORM);
	self.anim_type = ARISE;
	self.spawnposition = 1; //once it has arisen, it stays standing
	zombie_animate();
};

void () zombie_hide =
{
    self.style = 1;
	self.anim_type = HIDE;
	zombie_animate();
};

void () zombie_stand =
{
    if (random () < 0.05)
        sound (self, CHAN_VOICE, "axezombie/azomroam.wav", 1, ATTN_IDLE);
    self.style = 1;
	self.anim_type = STAND;
	zombie_animate();
};


void () zombie_walk =
{
    self.style = 2;
	self.anim_type = WALK;
	zombie_animate();
};

void () zombie_run =
{
    self.style = 3;
	self.anim_type = RUN;
	zombie_animate();
};

//--- Decide when to axeAttack an enemy
void () zombie_attack =
{
    local vector delta;
    delta = (self.enemy.origin - self.origin);
    if (vlen (delta) <= 60)
	{
		self.anim_type = ATTACK;
		zombie_animate();
	}
};

//--- Munch attack
void() zombie_axeAttack =
{
    local vector    delta;
    local float     ldmg;
    if (self.enemy.classname != "player") // To avoid hurting monster buddies on purpose
        return;
    ai_charge(10);
    if (!CanDamage (self.enemy, self))
        return;
    delta = self.enemy.origin - self.origin;
    if (vlen(delta) > 100)
        return;
    //ldmg = (random() + random() + random()) * 8;
	ldmg = 18;
    SpawnBlood (self.origin, '0 0 0', ldmg);
	SpawnBloodSpray (trace_ent, self.origin);
	sound (self, CHAN_WEAPON, "weapons/pitchfrk/pflesh.wav", 1, ATTN_NORM);
    T_Damage (self.enemy, self, self, ldmg, DF_STAB, string_null);
};

//--- Moan and show pain
void () zombie_pain =
{
    local float r;
    // don't make multiple pain sounds right after each other
    r = random();
    if (r < 0.5)
	{sound (self, CHAN_VOICE, "axezombie/azompain.wav", 1, ATTN_NORM); self.pain_finished = (time + 1.17);}
    else
	{sound (self, CHAN_VOICE, "axezombie/azommoan.wav", 1, ATTN_NORM); self.pain_finished = (time + 1.48);}
	if (self.health < 50 && r < 0.3)
	{
		zombie_fallback();
	}
	if (self.pain_finished > time)
        return;
	self.anim_type = PAIN;
	zombie_animate();
};

// --- Death sequence
void () zombie_die =
{
    monster_death();
	if (self.health < -40)
    {
        // Very large blood splat!
        te_bloodshower (self.origin, self.origin + self.size, 100, 100);
		sound (self, CHAN_VOICE, "axezombie/azomdie3.wav", 1, ATTN_NORM);
        RandomHumanGibs();
        remove (self);
        return;
    }
	if ((self.enemy.weapon == IT_VOODOO_DOLL) && (self.enemy.player_state == PS_ALTFIRE))
	{
		setmodel (self, "models/enemies/zombie/zombie_explode.psk");
		setsize (self,'-7 -21 0', '15 14 59');
		// FIXME: need to add dropped head spawn here as well
		self.frame = ZOMBIE_EXPLODE_START;
		self.anim_type = EXPLODE;
	}
    else if (random () < 0.75)
	{
		self.anim_type = DEATH1;
	}
    else
	{
		setmodel (self, "models/enemies/zombie/zombie_headless.psk");
		setsize (self,'-7 -21 0', '15 14 59');
		// FIXME: need to add dropped head spawn here as well
		self.frame = ZOMBIE_DEATH2_START;
		self.anim_type = DEATH2;
	}
	if (random() < 0.75)
		sound (self, CHAN_VOICE, "axezombie/azomdie1.wav", 1, ATTN_NORM);
	else
		sound (self, CHAN_VOICE, "axezombie/azomdie2.wav", 1, ATTN_NORM);

	zombie_animate();
};

void () zombie_animate =
{
	if (self.anim_type == self.last_action)
	{
		if (self.frame != self.anim_end)
			self.frame = self.frame + 1;
		else
			self.frame = self.anim_end -  self.anim_end_num + 1;
	}
	else
	{
		if (self.anim_type == STAND)
		{
			self.anim_end = ZOMBIE_STAND_END;
			self.anim_end_num = ZOMBIE_STAND_END - ZOMBIE_STAND_START + 1;
			self.anim_time = ZOMBIE_STAND_TIME;
			self.frame = ZOMBIE_STAND_START;
		}
		else if ((self.anim_type == WALK) || (self.anim_type == RUN))
		{
			self.anim_end = ZOMBIE_RUN_END;
			self.anim_end_num = ZOMBIE_RUN_END - ZOMBIE_RUN_START + 1;
			if (self.anim_type == WALK)
				self.anim_time = ZOMBIE_WALK_TIME;
			else
				self.anim_time = ZOMBIE_RUN_TIME;
			self.frame = ZOMBIE_RUN_START;
		}
		else if (self.anim_type == ATTACK)
		{
			self.anim_end = ZOMBIE_ATTACK_END;
			self.anim_end_num = ZOMBIE_ATTACK_END - ZOMBIE_ATTACK_START + 1;
			self.anim_time = ZOMBIE_ATTACK_TIME;
			self.frame = ZOMBIE_ATTACK_START;
		}
		else if (self.anim_type == PAIN)
		{
			self.anim_end = ZOMBIE_PAIN_END;
			self.anim_end_num = ZOMBIE_PAIN_END - ZOMBIE_PAIN_START + 1;
			self.anim_time = ZOMBIE_PAIN_TIME;
			self.frame = ZOMBIE_PAIN_START;
		}
		else if (self.anim_type == ARISE)
		{
			self.anim_end = ZOMBIE_ARISE_END;
			self.anim_end_num = ZOMBIE_ARISE_END - ZOMBIE_ARISE_START + 1;
			self.anim_time = ZOMBIE_ARISE_TIME;
			self.frame = ZOMBIE_ARISE_START;
		}
		else if (self.anim_type == STANDUP)
		{
			self.anim_end = ZOMBIE_STANDUP_END;
			self.anim_end_num = ZOMBIE_STANDUP_END - ZOMBIE_STANDUP_START + 1;
			self.anim_time = ZOMBIE_STANDUP_TIME;
			self.frame = ZOMBIE_STANDUP_START;
		}
		else if (self.anim_type == FALLBACK)
		{
			self.anim_end = ZOMBIE_FALLBACK_END;
			self.anim_end_num = ZOMBIE_FALLBACK_END - ZOMBIE_FALLBACK_START + 1;
			self.anim_time = ZOMBIE_FALLBACK_TIME;
			self.frame = ZOMBIE_FALLBACK_START;
		}
		else if (self.anim_type == DEATH1)
		{
			self.anim_end = ZOMBIE_DEATH1_END;
			self.anim_end_num = ZOMBIE_DEATH1_END - ZOMBIE_DEATH1_START + 1;
			self.anim_time = ZOMBIE_DEATH1_TIME;
			self.frame = ZOMBIE_DEATH1_START;
		}
		else if (self.anim_type == DEATH2)
		{
			self.anim_end = ZOMBIE_DEATH2_END;
			self.anim_end_num = ZOMBIE_DEATH2_END - ZOMBIE_DEATH2_START + 1;
			self.anim_time = ZOMBIE_DEATH2_TIME;
			self.frame = ZOMBIE_DEATH2_START;
		}
		else if (self.anim_type == EXPLODE)
		{
			self.anim_end = ZOMBIE_EXPLODE_END;
			self.anim_end_num = ZOMBIE_EXPLODE_END - ZOMBIE_EXPLODE_START + 1;
			self.anim_time = ZOMBIE_EXPLODE_TIME;
			self.frame = ZOMBIE_EXPLODE_START;
		}
		else if (self.anim_type == HIDE)
		{
			self.anim_end = ZOMBIE_HIDE_END;
			self.anim_end_num = ZOMBIE_HIDE_END - ZOMBIE_HIDE_START + 1;
			self.anim_time = ZOMBIE_HIDE_TIME;
			self.frame = ZOMBIE_HIDE_START;
		}
		self.last_action = self.anim_type;
	}
	self.nextthink = time + (self.anim_time / self.anim_end_num);
	self.think = zombie_animate;

	if ((self.anim_type == DEATH1) || (self.anim_type == DEATH2) || (self.anim_type == EXPLODE))
	{
		if (self.frame == self.anim_end)
		{
			self.nextthink = 0;
			monster_become_corpse();
			return;
		}
	}

	if ((self.frame == self.anim_end) && (self.anim_type != HIDE))
	{
		if (self.anim_type == FALLBACK)
			self.th_standup();
		else if ((self.anim_type == RUN) || (self.anim_type == WALK))
			self.frame = ZOMBIE_RUN_START;
		else
			self.th_run();
	}

	ai_main();
	//insert sounds or attack damage here with if statements
	if (self.frame == ZOMBIE_ATTACK_START + 7) sound (self, CHAN_VOICE, "axezombie/azomswip.wav", 1, ATTN_NORM);
	if (self.frame == ZOMBIE_ATTACK_START + 12) zombie_axeAttack();
	if ((self.anim_type == STAND) || (self.anim_type == HIDE)) ai_stand();
	else if ((self.anim_type == WALK) || (self.anim_type == RUN)) basic_ai (2);
	else if (self.anim_type == ATTACK) ai_face();
};

/*
	Initilization of a new zombie
	Config values here
*/

void () monster_zombie =
{
	//  Disable for testing
	if(monster_check())
		return;
	precache_model ("models/enemies/zombie/zombie.psk");
	precache_model ("models/enemies/zombie/zombie_headless.psk");
	precache_model ("models/enemies/zombie/zombie_head.psk");
	precache_model ("models/enemies/zombie/zombie_explode.psk");
	precache_sound ("axezombie/azomdie1.wav");
	precache_sound ("axezombie/azomdie2.wav");
	precache_sound ("axezombie/azomdie3.wav");
	precache_sound ("axezombie/azommoan.wav");
	precache_sound ("axezombie/azompain.wav");
	precache_sound ("axezombie/azomrise.wav");
	precache_sound ("axezombie/azomroam.wav");
	precache_sound ("axezombie/azomspot.wav");
	precache_sound ("axezombie/azomstnd.wav");
	precache_sound ("axezombie/azomswip.wav");
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_WALK;
	setmodel (self, "models/enemies/zombie/zombie.psk");
	self.frame = 0;
	setsize (self,'-7 -21 0', '15 14 59');

	self.health = 50;
	self.max_health = self.health;
	self.resist_acid = 0;
	self.resist_shock = 0;
	self.resist_pummel = 0;
	self.resist_fall = 0;
	self.resist_burn = 0;
	self.resist_bullet = 3;
	self.resist_stab = 8;
	self.resist_explode = 0;
	self.resist_gas = 0;
	self.resist_drown = -1;	// cannot drown
	self.resist_spirit = 0;
	self.resist_voodoo = 0;

	/*if (skill <= 1)
	else if (skill == 2)
	else if (skill == 3)
	else if (skill == 4)
	else if (skill > 4)
	//not considering skill yet */

	self.speed = 50;	// walkspeed
	self.th_stand = zombie_stand;
	self.th_walk = zombie_walk;
	self.th_run = zombie_run;
	self.th_die = zombie_die;
	self.th_fall = zombie_fallback;
	self.th_standup = zombie_standup;
	self.th_pain = zombie_pain;
	self.th_arise = zombie_arise;
	self.th_hide = zombie_hide;
	self.th_melee = zombie_attack;
	self.touch = monster_stepped_on;
	self.anim_type = HIDE;
	self.classname = "monster";
	self.netname = "monster_zombie";
	walkmonster_start ();
};
