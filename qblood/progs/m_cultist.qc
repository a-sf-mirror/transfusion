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
#define CULTIST_REFERENCE			0
#define	CULTIST_STAND_START			1	//stand = idle
#define	CULTIST_STAND_END			30
#define	CULTIST_WALK_START			31
#define	CULTIST_WALK_END			60
#define	CULTIST_ATTACK_START		61
#define	CULTIST_ATTACK_END			65
#define	CULTIST_ATTACK2_START		66	// throwing TNT for brown cultist
#define	CULTIST_ATTACK2_END			115
#define	CULTIST_PAIN_START			116
#define	CULTIST_PAIN_END			125
#define	CULTIST_DEATH_START			126
#define	CULTIST_DEATH_END			170
#define CULTIST_SWIM_START          171
#define CULTIST_SWIM_END            190
#define CULTIST_CRAWL_START         191
#define CULTIST_CRAWL_END           215
#define CULTIST_CRAWL_FIRE_START    216
#define CULTIST_CRAWL_FIRE_END      219
#define CULTIST_SWIM_FIRE_START     220
#define CULTIST_SWIM_FIRE_END       223
//Frames to be added in future
#define CULTIST_BURN_START          0
#define CULTIST_BURN_END            0
#define CULTIST_VARIOUS_DEATHS      0

//Animation Timing Configuration in seconds
//FIXME: all values need to be changed here
#define CULTIST_STAND_TIME			5.0
#define	CULTIST_RUN_TIME			0.6
#define	CULTIST_WALK_TIME			1.2
#define	CULTIST_PAIN_TIME			0.75
#define	CULTIST_ATTACK_TIME			0.85
#define	CULTIST_ATTACK2_TIME		0.85
#define	CULTIST_DEATH_TIME			1.2
#define CULTIST_SWIM_TIME			1.0
#define CULTIST_CRAWL_TIME			1.0
#define CULTIST_CRAWL_FIRE_TIME		0.85
#define CULTIST_SWIM_FIRE_TIME		0.85
//Times to be added in the future
#define CULTIST_BURN_TIME			0
#define CULTIST_VARIOUS_DEATHS_TIME	0

void() cultist_animate;

// Shared cultist functions
void() cultist_die;         // Brown, Black, Blue, Green
void() cultist_fireShotgun; // Brown, Red
void() cultist_pain;        // all
void() cultist_stand;       // all
void() cultist_throw_TNT;   // Brown, Green

void() browncultist_attack;
void() blackcultist_attack;
void() bluecultist_attack;
void() greencultist_attack;
void() redcultist_attack;

void() cultist_taunt =
{
	if (self.pain_finished < time && self.voice_finished < time)// To avoid several sounds at once
	{
		local float r;
		r = random();

		if (r <= 0.05)
		{
			sound(self, CHAN_AUTO, "cultist/cultglo1.wav", 1, ATTN_NORM);
			self.voice_finished = time + 3.46;
		}
		else if (r <= 0.1)
		{
			sound(self, CHAN_AUTO, "cultist/cultglo2.wav", 1, ATTN_NORM);
			self.voice_finished = time + 3.21;
		}
		else if (r <= 0.15)
		{
			sound(self, CHAN_AUTO, "cultist/cultglo3.wav", 1, ATTN_NORM);
			self.voice_finished = time + 2.27;
		}
		else if (r <= 0.2)
		{
			sound(self, CHAN_AUTO, "cultist/cultglo4.wav", 1, ATTN_NORM);
			self.voice_finished = time + 2.27;
		}

		// Give it a half second break so he's not too annoying
		if (r <= 0.2)
			self.voice_finished = self.voice_finished + 0.5;
	}
};

//--- Death sequence
void() cultist_die =
{
	self.anim_type = DEATH;
	cultist_animate();
};

void() cultist_fireShotgun =
{
	local float r;
	local vector dir;
	local vector org;

	self.effects = self.effects | EF_MUZZLEFLASH;

	r = random();

	if (r < 0.5)
		sound(self, CHAN_AUTO, "cultist/cultatt1.wav", 1, ATTN_NORM);
	else
		sound(self ,CHAN_AUTO, "cultist/cultatt2.wav", 1, ATTN_NORM);

	dir = (self.enemy.origin - self.origin);	
	dir = normalize(dir);	
	org = self.origin;

	/* 
		There has to be a smarter way to do this...
		This adjust the angle that the shotgun pellets come from
		I.E. So you can't walk right into a cultist "blind spot" 
	*/
	if (self.angles_y >= 315 || self.angles_y <= 45)
	{
		org_x = org_x + 10;
		org_y = org_y + 0;
	}
	else if (self.angles_y >= 225)
	{
		org_x = org_x + 0;
		org_y = org_y - 10;
	}
	else if (self.angles_y >= 135)
	{
		org_x = org_x - 10;
		org_y = org_y + 0;
	}
	else // self.angles_y > 45)
	{
		org_x = org_x + 0;
		org_y = org_y + 10;
	}
	
	org_z = org_z + 35;	
	
	FireBullets(org, dir, 8, 8, '0.1 0.1 0');  // 8 "shot pellets" per shell
};

void() cultist_pain =
{
	local float r;

	// don't make multiple pain sounds right after each other
	if (self.pain_finished > time)
		return;

	r = random();

	if (self.deathtype == "fire" && (self.health / self.max_health) <= 0.35)
	{
		if (r < 0.33)
		{
			sound(self,2,"cultist/cultfir1.wav",1,1);
			self.pain_finished = (time + 3.2);
		}
		else if (r < 0.66)
		{
			sound(self,2,"cultist/cultfir2.wav",1,1);
			self.pain_finished = (time + 4.62);
		}
		else
		{
			sound(self,2,"cultist/cultfir3.wav",1,1);
			self.pain_finished = (time + 3.62);
		}
	}
	else if (r < 0.25)
	{
		sound(self,2,"cultist/cultpan1.wav",1,1);
		self.pain_finished = (time + 1.38);
	}
	else if (r < 0.5)
	{
		// Unique tommygun cultist sound
		if (self.netname == "monster_blackcultist")
		{
			sound(self,2,"cultist/tcltpan2.wav",1,1);
			self.pain_finished = (time + 1.28);
		}
		else
		{
			sound(self,2,"cultist/cultpan2.wav",1,1);
			self.pain_finished = (time + 1.35);
		}
	}
	else if (r < 0.75)
	{
		// Unique tommygun cultist sound
		if (self.netname == "monster_blackcultist")
		{
			sound(self,2,"cultist/tcltpan3.wav",1,1);
			self.pain_finished = (time + 1.21);
		}
		else
		{
			sound(self,2,"cultist/cultpan3.wav",1,1);
			self.pain_finished = (time + 1.4);
		}
	}
	else
	{
		sound(self,2,"cultist/cultpan4.wav",1,1);
		self.pain_finished = (time + 1.29);
	}

	/* da_weezle: knockback handled via T_Damage, this is deprecated		
	if (self.deathtype != "fire") // FIXME: This is here until I can spread it through pain frames
		ai_pain(15);
	*/	
};

//--- Function used by brown, black and green cultists

void() cultist_throw_TNT =
{
	local    entity missile;
	local    vector delta;
	local     float dist;

	sound(self, CHAN_WEAPON, "cultist/culttoss.wav", 1, ATTN_NORM);

	missile = spawn();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;

	// set missile speed
	makevectors(self.angles);
	delta = (self.enemy.origin - self.origin);
	dist = vlen(delta);
	missile.velocity = normalize(self.enemy.origin - self.origin);
	missile.velocity = missile.velocity * dist;
	missile.velocity_z = 425;
	missile.avelocity = '300 300 300';
	missile.angles = vectoangles(missile.velocity);
	missile.dmg = DMG_TNT;
	missile.netname = "TNT";
	missile.think = BombThink;
	missile.nextthink = time + 0.1;
	missile.touch = Bomb_Trigger;
// todo: make cultist release TNT at ~frame 20 of CULTIST_ATTACK2

	setmodel(missile, "models/weapons/grenades/gr_tnt.md3");
	setsize(missile, '0 0 0', '0 0 0');
	setorigin(missile, self.origin);
};

//--- Decide what to say
void() cultist_stand =
{
	local float     r;
	r = random();

	if (r <= 0.02)
		sound(self, CHAN_WEAPON, "cultist/cultspt1.wav", 1, ATTN_NORM);
	else if (r <= 0.04)
		sound(self, CHAN_WEAPON, "cultist/cultspt2.wav", 1, ATTN_NORM);
	else if (r <= 0.06)
		sound(self, CHAN_WEAPON, "cultist/cultspt3.wav", 1, ATTN_NORM);
	else if (r <= 0.08)
		sound(self, CHAN_WEAPON, "cultist/cultspt4.wav", 1, ATTN_NORM);
	else if (r <= 0.1)
		sound(self, CHAN_WEAPON, "cultist/cultspt5.wav", 1, ATTN_NORM);

	self.style = 1;
	self.anim_type = STAND;
	cultist_animate();
};

void() cultist_walk =
{
	self.style = 2;
	self.anim_type = WALK;
	cultist_animate();
};

void() cultist_run =
{    
	self.style = 3;
	self.anim_type = RUN;
	cultist_animate();
};

// primary attack
void() cultist_attack = 
{
	self.anim_type = ATTACK;
	cultist_animate();
};

// secondary attack
void() cultist_attack2 =
{
	self.anim_type = ATTACK2;
	cultist_animate();
};

// crawl
void() cultist_crawl =
{
	//self.style = 1; //FIXME style for crawling?
	self.anim_type = CRAWL;
	cultist_animate();
};

// fire while crawling
void() cultist_crawl_fire =
{
	//self.style = 1; //FIXME style for crawling?
	self.anim_type = CRAWL_FIRE;
	cultist_animate();
};

// swim
void() cultist_swim =
{
	//self.style = 1; //FIXME style for swimming?
	self.anim_type = SWIM;
	cultist_animate();
};

// fire while swimming
void() cultist_swim_fire =
{
	//self.style = 1; //FIXME style for swimming?
	self.anim_type = CRAWL_FIRE;
	cultist_animate();
};

/*
============
cultist_animate

Animation and frame based code for the Cultist
============
*/
void() cultist_animate =
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
			self.anim_end = CULTIST_STAND_END;
			self.anim_end_num = CULTIST_STAND_END - CULTIST_STAND_START + 1;
			self.anim_time = CULTIST_STAND_TIME;
			self.frame = CULTIST_STAND_START;
		}
		else if (self.anim_type == WALK)
		{
			self.anim_end = CULTIST_WALK_END;
			self.anim_end_num = CULTIST_WALK_END - CULTIST_WALK_START + 1;
			self.anim_time = CULTIST_WALK_TIME;
			self.frame = CULTIST_WALK_START;
		}
		else if (self.anim_type == RUN)
		{
			//FIXME? walking animation with changed timings
			self.anim_end = CULTIST_WALK_END;
			self.anim_end_num = CULTIST_WALK_END - CULTIST_WALK_START + 1;
			self.anim_time = CULTIST_RUN_TIME;
			self.frame = CULTIST_WALK_START;
		}
		else if (self.anim_type == ATTACK)
		{
			self.anim_end = CULTIST_ATTACK_END;
			self.anim_end_num = CULTIST_ATTACK_END - CULTIST_ATTACK_START + 1;
			self.anim_time = CULTIST_ATTACK_TIME;
			self.frame = CULTIST_ATTACK_START;
		}
		else if (self.anim_type == ATTACK2)
		{
			self.anim_end = CULTIST_ATTACK2_END;
			self.anim_end_num = CULTIST_ATTACK2_END - CULTIST_ATTACK2_START + 1;
			self.anim_time = CULTIST_ATTACK2_TIME;
			self.frame = CULTIST_ATTACK2_START;
		}
		else if (self.anim_type == PAIN)
		{
			self.anim_end = CULTIST_PAIN_END;
			self.anim_end_num = CULTIST_PAIN_END - CULTIST_PAIN_START + 1;
			self.anim_time = CULTIST_PAIN_TIME;
			self.frame = CULTIST_PAIN_START;
		}
		else if (self.anim_type == CRAWL)
		{
			self.anim_end = CULTIST_CRAWL_END;
			self.anim_end_num = CULTIST_CRAWL_END - CULTIST_CRAWL_START + 1;
			self.anim_time = CULTIST_CRAWL_TIME;
			self.frame = CULTIST_CRAWL_START;
		}
		else if (self.anim_type == CRAWL_FIRE)
		{
			self.anim_end = CULTIST_CRAWL_FIRE_END;
			self.anim_end_num = CULTIST_CRAWL_FIRE_END - CULTIST_CRAWL_FIRE_START + 1;
			self.anim_time = CULTIST_CRAWL_FIRE_TIME;
			self.frame = CULTIST_CRAWL_FIRE_START;
		}
		else if (self.anim_type == SWIM)
		{
			self.anim_end = CULTIST_SWIM_END;
			self.anim_end_num = CULTIST_SWIM_END - CULTIST_SWIM_START + 1;
			self.anim_time = CULTIST_SWIM_TIME;
			self.frame = CULTIST_SWIM_START;
		}
		else if (self.anim_type == SWIM_FIRE)
		{
			self.anim_end = CULTIST_SWIM_FIRE_END;
			self.anim_end_num = CULTIST_SWIM_FIRE_END - CULTIST_SWIM_FIRE_START + 1;
			self.anim_time = CULTIST_SWIM_FIRE_TIME;
			self.frame = CULTIST_SWIM_FIRE_START;
		}
		else if (self.anim_type == DEATH)
		{
			self.anim_end = CULTIST_DEATH_END;
			self.anim_end_num = CULTIST_DEATH_END - CULTIST_DEATH_START + 1;
			self.anim_time = CULTIST_DEATH_TIME;
			self.frame = CULTIST_DEATH_START;
		}
		self.last_action = self.anim_type;
	}
	self.nextthink = time + (self.anim_time / self.anim_end_num);
	self.think = cultist_animate;

	if (self.anim_type == DEATH)
	{
		if (self.netname != "monster_redcultist")
		{
			if (self.health < -40)
			{
				sound(self, CHAN_VOICE, "cultist/cultdie3.wav", 1, ATTN_NORM);
				// Very large blood splat!
				te_bloodshower(self.origin, self.origin + self.size, 100, 100);
				RandomHumanGibs();
				remove(self);
				return;
			}
			else if (random() < 0.5)
			{
				// Unique tommygun cultist sound
				if (self.netname == "monster_blackcultist")
					sound(self, CHAN_VOICE, "cultist/tcltdie1.wav", 1, ATTN_NORM);
				else
					sound(self, CHAN_VOICE, "cultist/cultdie1.wav", 1, ATTN_NORM);
			}
			else
				sound(self, CHAN_VOICE, "cultist/cultdie2.wav", 1, ATTN_NORM);
			if (self.frame == self.anim_end)
			{
				local entity drop_weapon;

				drop_weapon = spawn();
				drop_weapon.origin = self.origin;
				drop_weapon.velocity = '0 0 0';
				drop_weapon.think = weapon_sawedoff;

				drop_weapon.nextthink = time + 0.01;
				remove(self.attachedobject);
				self.nextthink = 0;
				monster_death();
				monster_become_corpse();
				return;
			}
		}
		else // It is a red cultist (priest)
		{
			sound(self,2,"cultist/cultmorp.wav",1,1);
			/*
			do morph (from cultist to beast) animation sequence
			remove self here
			spawn a beast at same facing / coordinates
			*/
		}
	}

	//AI control
	ai_main();
	
	if (self.anim_type == ATTACK)
	{
		if (self.netname == "monster_browncultist")
		{
			if (range(self.enemy) == RANGE_NEAR)
				cultist_fireShotgun();
			else if (range(self.enemy) == RANGE_MID)
				cultist_throw_TNT();
		}
		
	}
	else if (self.anim_type == ATTACK2)
	{
		if (self.frame == CULTIST_ATTACK2_START + 30)
			cultist_throw_TNT();
	}

	if (self.anim_type == STAND) basic_ai(3);
	else if (self.anim_type == WALK) basic_ai(3);
	else if (self.anim_type == RUN) basic_ai(6);
	else if (self.anim_type == ATTACK) ai_face();
	else if (self.anim_type == ATTACK2) ai_face();

	//insert sounds or attack damage here with if statements
};


//	Generic Cultist settings that apply to all go in here
void() cultist_spawn =
{   
	//  Disable for testing
	if(monster_check())
		return;

	// Common attributes for cultists:
		// may have to go into individual config
	self.resist_acid = 0;
	self.resist_shock = 0;
	self.resist_pummel = 0;
	self.resist_fall = 0;
	self.resist_burn = 0;
	self.resist_bullet = 2;
	self.resist_stab = 4;
	self.resist_explode = 0;
	self.resist_gas = 0;
	self.resist_drown = -1;	// cannot drown
	self.resist_spirit = 0;
	self.resist_voodoo = 0;

	// Don't precache sounds that won't be used by black cultist
	if (self.netname != "monster_blackcultist")
	{
		precache_sound("cultist/cultdie1.wav"); // Death
		precache_sound("cultist/cultpan2.wav"); // Pain
		precache_sound("cultist/cultpan3.wav"); // Pain
	}
	
	precache_model("models/enemies/cultist/cultist.psk");    
	precache_sound("cultist/cultdie2.wav"); // Death
	precache_sound("cultist/cultdie3.wav"); // Death
	precache_sound("cultist/cultfir1.wav"); // On fire
	precache_sound("cultist/cultfir2.wav"); // On fire
	precache_sound("cultist/cultfir3.wav"); // On fire
	precache_sound("cultist/cultglo1.wav"); // Gloating
	precache_sound("cultist/cultglo2.wav"); // Gloating
	precache_sound("cultist/cultglo3.wav"); // Gloating
	precache_sound("cultist/cultglo4.wav"); // Gloating
	precache_sound("cultist/cultpan1.wav"); // Pain
	precache_sound("cultist/cultpan4.wav"); // Pain
	precache_sound("cultist/cultspt1.wav"); // Spotted
	precache_sound("cultist/cultspt2.wav"); // Spotted
	precache_sound("cultist/cultspt3.wav"); // Spotted
	precache_sound("cultist/cultspt4.wav"); // Spotted
	precache_sound("cultist/cultspt5.wav"); // Spotted

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;
	setmodel(self, "models/enemies/cultist/cultist.psk");
	setsize(self,'-9.9 -18.6 -0.2', '21.6 18.6 63.7');    
	self.speed = 50;	// walkspeed
	self.max_health = self.health;
	self.th_stand = cultist_stand;
	self.th_walk = cultist_walk;
	self.th_run = cultist_run;
	self.th_die = cultist_die;
	self.th_pain = cultist_pain;
	self.touch = monster_stepped_on;
	self.attack_state = AS_MISSILE;
	self.classname = "monster";

	cultist_animate();

	walkmonster_start();    
};
