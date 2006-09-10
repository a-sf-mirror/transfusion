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

//Frame Definitions
#define RAT_REFERENCE			0
#define	RAT_IDLE_START			1
#define	RAT_IDLE_END			1
#define	RAT_RUN_START			2
#define	RAT_RUN_END				9
#define	RAT_ATTACK_START		10
#define	RAT_ATTACK_END			13
#define RAT_DEATH1				0//no animation, just spawn blood spat
#define RAT_DEATH2_START		0//new model, probably single frame
#define RAT_DEATH2_END			0

//Time Definitions
#define RAT_IDLE_TIME			1.0
#define RAT_RUN_TIME			1.0
#define RAT_ATTACK_TIME			1.0
#define RAT_DEATH2_TIME			1.0

void() rat_animate;

void() rat_idle =
{
	if (random() < 0.05)
		sound(self, CHAN_VOICE, "rat/ratroam.wav", 1, ATTN_IDLE);

	self.style = 1;
	self.anim_type = IDLE;
	rat_animate();
};

void() rat_run =
{
	self.style = 3;
	self.anim_type = RUN;
	rat_animate();
};

//--- Decide when to bite an enemy
void() rat_attack =
{
	local vector delta;

	if (self.attack_finished > time)    // To avoid constant player chomping
		return;

	delta = (self.enemy.origin - self.origin);

	if (vlen(delta) <= 90)
	{
		self.anim_type = ATTACK;    // If the player is near bite them
		rat_animate();
	}

};

//--- Munch attack
void() rat_bite =
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

	ldmg = (random() + random() + random()) * 8;
	T_Damage(self.enemy, self, self, ldmg, DF_STAB, string_null);

	sound(self, CHAN_VOICE, "hellhound/houndbit.wav", 1, ATTN_NORM);  //FIXME: Verify this is correct biting sound

	self.attack_finished = time + 1;

};

//--- Show pain
void() rat_pain =
{
	// don't make multiple pain sounds right after each other
	if (self.pain_finished > time)
		return;

	sound(self, CHAN_VOICE, "rat/ratpain.wav", 1, ATTN_NORM);

	// FIXME?: No pain sequence for now, just requires sound?
	self.pain_finished = (time + 1); // is really 0.33 seconds long, but that really sounds crappy
};

void() rat_death1 =
{
	self.anim_type = DEATH1;
	rat_animate();
};

void() rat_death2 =
{
	//setmodel(self, "models/enemies/rat/rat_death2.psk");
	self.anim_type = DEATH2;
	rat_animate();
};

void() rat_death =
{
	//FIXME: add detection of weapon that causes death
	if (random() > 0.5)
		rat_death1();
	else
		rat_death2();
};

/*
============
rat_animate

Animation and frame based code for the Rat
============
*/
void() rat_animate =
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
		if (self.anim_type == IDLE)
		{
			self.anim_end = RAT_IDLE_END;
			self.anim_end_num = RAT_IDLE_END - RAT_IDLE_START + 1;
			self.anim_time = RAT_IDLE_TIME;
			self.frame = RAT_IDLE_START;
		}
		else if (self.anim_type == RUN)
		{
			self.anim_end = RAT_RUN_END;
			self.anim_end_num = RAT_RUN_END - RAT_RUN_START + 1;
			self.anim_time = RAT_RUN_TIME;
			self.frame = RAT_RUN_START;
		}
		else if (self.anim_type == ATTACK)
		{
			self.anim_end = RAT_ATTACK_END;
			self.anim_end_num = RAT_ATTACK_END - RAT_ATTACK_START + 1;
			self.anim_time = RAT_ATTACK_TIME;
			if (self.frame > self.anim_end)
				self.th_run();
			else
				self.frame = RAT_ATTACK_START;
		}
		else if (self.anim_type == DEATH2)
		{
			self.anim_end = RAT_DEATH2_END;
			self.anim_end_num = RAT_DEATH2_END - RAT_DEATH2_START + 1;
			self.anim_time = RAT_DEATH2_TIME;
			self.frame = RAT_DEATH2_START;
		}
		self.last_action = self.anim_type;
	}
	self.nextthink = time + (self.anim_time / self.anim_end_num);
	self.think = rat_animate;

	if (((self.anim_type == DEATH1) || (self.anim_type == DEATH2)) && (self.frame == self.anim_end))
	{
		//FIXME: add blood shower for rat death and final squeak?
		self.nextthink = 0;
		monster_death();

		if (self.health < -20)
		{
			// Very large blood splat!
			te_bloodshower(self.origin, self.origin + self.size, 100, 25);

			sound(self, CHAN_VOICE, "rat/ratdie3.wav", 1, ATTN_NORM);
			ThrowGib("models/objects/gib4.md3", self.health);
			remove(self);
			return;
		}

		if (random() < 0.5)
			sound(self, CHAN_VOICE, "rat/ratdie1.wav", 1, ATTN_NORM);
		else
			sound(self, CHAN_VOICE, "rat/ratdie2.wav", 1, ATTN_NORM);
	}

	if (self.frame == self.anim_end)
		self.frame = self.anim_end - self.anim_end_num + 1;

	ai_main();
	//insert sounds or attack damage here with if statements
	if (self.anim_type == IDLE) ai_stand();
	else if (self.anim_type == RUN) basic_ai (3);
	else if (self.anim_type == ATTACK)
	{
		if (self.frame == RAT_ATTACK_START + 1) rat_bite();
		ai_face();
	}
};

//--- The spawn
void() monster_rat =
{
	//  Disable for testing
	if (monster_check())
		return;

	precache_model("models/enemies/rat/rat.psk");
	//precache_model("models/enemies/rat/rat_death2.psk");

	precache_sound("rat/ratdie1.wav");
	precache_sound("rat/ratdie2.wav");
	precache_sound("rat/ratdie3.wav");
	precache_sound("rat/ratpain.wav");
	precache_sound("rat/ratroam.wav");
	precache_sound("rat/ratspot.wav");
	precache_sound("hellhound/houndbit.wav");

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_TOSS;
	setmodel(self, "models/enemies/rat/rat.psk");
	setsize(self,'-13 -3 0', '13 3 6');     // FIXME: Need real coordinates
	self.health = 40;
	self.resist_acid = 0;
	self.resist_shock = 0;
	self.resist_pummel = 0;
	self.resist_fall = 0;
	self.resist_burn = 0;
	self.resist_bullet = 0;
	self.resist_stab = 0;
	self.resist_explode = 0;
	self.resist_gas = 0;
	self.resist_drown = -1;	// cannot drown
	self.resist_spirit = 0;
	self.resist_voodoo = 0;    
	self.max_health = self.health;
	self.th_stand = rat_idle;
	self.th_walk = rat_run;
	self.th_run = rat_run;
	self.th_die = rat_death;
	self.th_pain = rat_pain;
	self.th_missile = rat_attack;
	self.touch = monster_stepped_on;
	self.attack_finished = 0;
	self.classname = "monster_rat";
	self.netname = "Rat";
	walkmonster_start();
};
