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
//Frame Definiations
#define CULTIST_REFERENCE       0
#define	CULTIST_STAND_START		1	//stand = idle
#define	CULTIST_STAND_END		30
#define	CULTIST_WALK_START		31
#define	CULTIST_WALK_END		60
#define	CULTIST_ATTACK_START	61
#define	CULTIST_ATTACK_END		65
#define	CULTIST_ATTACK2_START	66	// throwing TNT for brown cultist
#define	CULTIST_ATTACK2_END		90
#define	CULTIST_PAIN_START		91
#define	CULTIST_PAIN_END		100
#define	CULTIST_DEATH_START		101
#define	CULTIST_DEATH_END		140

//Frames to be added in future
/*
#define CULTIST_CRAWL_START         0
#define CULTIST_CRAWL_END           0
#define CULTIST_CRAWL_FIRE_START    0
#define CULTIST_CRAWL_FIRE_END      0
#define CULTIST_SWIM_START          0
#define CULTIST_SWIM_END            0
#define CULTIST_SWIM_FIRE_START     0
#define CULTIST_SWIM_FIRE_END       0
#define CULTIST_BURN_START          0
#define CULTIST_BURN_END            0
#define CULTIST_VARIOUS_DEATHS      *
*/

//Animation Timing Configuration in seconds
//FIXME: all values need to be changed here
#define CULTIST_STAND_TIME		1.0
#define	CULTIST_RUN_TIME		0.6
#define	CULTIST_WALK_TIME		1.2
#define	CULTIST_PAIN_TIME		0.75
#define	CULTIST_ATTACK_TIME		0.85
#define	CULTIST_ATTACK2_TIME	0.85
#define	CULTIST_DEATH_TIME		1.2

void () cultist_animate;

// Shared cultist functions
void () cultist_die;         // Brown, Black, Blue, Green
void () cultist_fireShotgun; // Brown, Red
void () cultist_pain;        // all
void () cultist_stand;       // all
void () cultist_throw_TNT;   // Brown, Green

void () browncultist_attack;
void () blackcultist_attack;
void () bluecultist_attack;
void () greencultist_attack;
void () redcultist_attack;

void () cultist_taunt =
{
	if (self.pain_finished < time && self.voice_finished < time)// To avoid several sounds at once
	{
		local float r;
		r = random();

		if (r <= 0.05)
		{
			sound (self, CHAN_AUTO, "cultist/cultglo1.wav", 1, ATTN_NORM);
			self.voice_finished = time + 3.46;
		}
		else if (r <= 0.1)
		{
			sound (self, CHAN_AUTO, "cultist/cultglo2.wav", 1, ATTN_NORM);
			self.voice_finished = time + 3.21;
		}
		else if (r <= 0.15)
		{
			sound (self, CHAN_AUTO, "cultist/cultglo3.wav", 1, ATTN_NORM);
			self.voice_finished = time + 2.27;
		}
		else if (r <= 0.2)
		{
			sound (self, CHAN_AUTO, "cultist/cultglo4.wav", 1, ATTN_NORM);
			self.voice_finished = time + 2.27;
		}

		// Give it a half second break so he's not too annoying
		if (r <= 0.2)
			self.voice_finished = self.voice_finished + 0.5;
	}
};

//--- Death sequence
void () cultist_die =
{
    monster_death();
	
	if (self.classname != "monster_redcultist")
	{
		if (self.health < -40)
        {
			sound (self, CHAN_VOICE, "cultist/cultdie3.wav", 1, ATTN_NORM);
			// Very large blood splat!
			te_bloodshower (self.origin, self.origin + self.size, 100, 100);
			RandomHumanGibs ();
			remove (self);
			return;
		}
		else if (random () < 0.5)
		{
			// Unique tommygun cultist sound
			if (self.classname == "monster_blackcultist")
				sound (self, CHAN_VOICE, "cultist/tcltdie1.wav", 1, ATTN_NORM);
			else
				sound (self, CHAN_VOICE, "cultist/cultdie1.wav", 1, ATTN_NORM);
		}
		else
			sound (self, CHAN_VOICE, "cultist/cultdie2.wav", 1, ATTN_NORM);
	}
	else // It is a red cultist (priest)
	{
		sound (self,2,"cultist/cultmorp.wav",1,1);
	/*
		do morph (from cultist to beast) animation sequence
		remove self here
		spawn a beast at same facing / coordinates
	*/
	}

	// This will have to move this into the if != "monster_redcultist" when we get some morph frames
	self.anim_type = "death";
	cultist_animate();
};

void () cultist_fireShotgun =
{
	local float r;
	local vector dir;
	local vector org;
	local vector spread;

	self.effects = self.effects | EF_MUZZLEFLASH;

	r = random();

	if (r < 0.5)
		sound (self, CHAN_AUTO, "cultist/cultatt1.wav", 1, ATTN_NORM);
	else
		sound (self ,CHAN_AUTO, "cultist/cultatt2.wav", 1, ATTN_NORM);

	dir = (self.enemy.origin - self.origin);	
	dir = normalize (dir);	
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
	
	FireBullets (org, dir, 8, 8, '0.1 0.1 0');  // 8 "shot pellets" per shell
};

void () cultist_pain =
{
	local float r;

	// don't make multiple pain sounds right after each other
	if (self.pain_finished > time)
		return;

	r = random();

	if (self.deathtype == "fire" && (self.health / self.max_health) <= 0.35)
	{
		if (r < 0.33)
			{sound (self,2,"cultist/cultfir1.wav",1,1); self.pain_finished = (time + 3.2);}
		else if (r < 0.66)
			{sound (self,2,"cultist/cultfir2.wav",1,1);    self.pain_finished = (time + 4.62);}
		else
			{sound (self,2,"cultist/cultfir3.wav",1,1);    self.pain_finished = (time + 3.62);}
	}
	else if (r < 0.25)
		{sound (self,2,"cultist/cultpan1.wav",1,1);    self.pain_finished = (time + 1.38);}
	else if (r < 0.5)
	{
		// Unique tommygun cultist sound
		if (self.classname == "monster_blackcultist")
			{sound (self,2,"cultist/tcltpan2.wav",1,1);    self.pain_finished = (time + 1.28);}
		else
			{sound (self,2,"cultist/cultpan2.wav",1,1);    self.pain_finished = (time + 1.35);}
	}
	else if (r < 0.75)
	{
		// Unique tommygun cultist sound
		if (self.classname == "monster_blackcultist")
			{sound (self,2,"cultist/tcltpan3.wav",1,1);    self.pain_finished = (time + 1.21);}
		else
			{sound (self,2,"cultist/cultpan3.wav",1,1);    self.pain_finished = (time + 1.4);}		
	}
	else
		{sound (self,2,"cultist/cultpan4.wav",1,1);    self.pain_finished = (time + 1.29);}

	/* da_weezle: knockback handled via T_Damage, this is deprecated		
	if (self.deathtype != "fire") // FIXME: This is here until I can spread it through pain frames
		ai_pain(15);
	*/	
};

//--- Function used by brown, black and green cultists

void () cultist_throw_TNT =
{
	local    entity missile;
	local    vector delta;
	local     float dist;

	sound (self, CHAN_WEAPON, "cultist/culttoss.wav", 1, ATTN_NORM);

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;

	// set missile speed
	makevectors (self.angles);
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

	setmodel (missile, "models/weapons/grenades/gr_tnt.md3");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin);
};

//--- Decide what to say
void () cultist_stand =
{
	local float     r;
	r = random();

	if (r <= 0.02)
		sound (self, CHAN_WEAPON, "cultist/cultspt1.wav", 1, ATTN_NORM);
	else if (r <= 0.04)
		sound (self, CHAN_WEAPON, "cultist/cultspt2.wav", 1, ATTN_NORM);
	else if (r <= 0.06)
		sound (self, CHAN_WEAPON, "cultist/cultspt3.wav", 1, ATTN_NORM);
	else if (r <= 0.08)
		sound (self, CHAN_WEAPON, "cultist/cultspt4.wav", 1, ATTN_NORM);
	else if (r <= 0.1)
		sound (self, CHAN_WEAPON, "cultist/cultspt5.wav", 1, ATTN_NORM);

	self.style = 1;
	self.anim_type = "stand";
	cultist_animate();
};

void () cultist_walk =
{
	self.style = 2;
	self.anim_type = "walk";
	cultist_animate();
};

void () cultist_run =
{    
	self.style = 3;
	self.anim_type = "run";
	cultist_animate();
};

// primary attack
void () cultist_attack = 
{
	// TODO: add attacks for other cultists
	if (self.classname == "monster_browncultist")
	{
		cultist_fireShotgun();
	}
};

// secondary attack
void () cultist_attack2 =
{
	// TODO: add attacks for other cultists
	if (self.classname == "monster_browncultist")
	{
		cultist_throw_TNT();
	}
};

void () cultist_animate =
{
	if (self.frame <= self.anim_end)
	{
		/*
		Death does not go above the last frame since it doesn't reset
		Otherwise, increase the frame number, if it goes past the end, it will reset
		*/
		if (!(((self.anim_type == "death1") || (self.anim_type == "death2")) && (self.frame == self.anim_end)))
			self.frame = self.frame + 1; //if its a new animation type, it will be set to the proper frame next
	}
	if ((self.anim_type != self.last_action) || (self.frame > self.anim_end))
	{
		if (self.anim_type == "stand")
		{
			self.anim_end = CULTIST_STAND_END;
			self.anim_end_num = CULTIST_STAND_END - CULTIST_STAND_START + 1; //add one to compensate for the first frame not being counted
			self.anim_time = CULTIST_STAND_TIME; // one idle animation lasts 2.5 seconds
			self.last_action = "stand";
			self.frame = CULTIST_STAND_START;
		}
		else if (self.anim_type == "walk")
		{
			self.anim_end = CULTIST_WALK_END;
			self.anim_end_num = CULTIST_WALK_END - CULTIST_WALK_START + 1;
			self.anim_time = CULTIST_WALK_TIME;
			self.last_action = "walk";
			self.frame = CULTIST_WALK_START;
		}
		else if (self.anim_type == "run")
		{
			//FIXME? walking animation with changed timings
			self.anim_end = CULTIST_WALK_END;
			self.anim_end_num = CULTIST_WALK_END - CULTIST_WALK_START + 1;
			self.anim_time = CULTIST_RUN_TIME;
			self.last_action = "run";
			self.frame = CULTIST_WALK_START;
		}
		else if (self.anim_type == "attack")
		{
			self.anim_end = CULTIST_ATTACK_END;
			self.anim_end_num = CULTIST_ATTACK_END - CULTIST_ATTACK_START + 1;
			self.anim_time = CULTIST_ATTACK_TIME;
			self.last_action = "attack";
			if (self.frame > self.anim_end)
				cultist_run();
			else
				self.frame = CULTIST_ATTACK_START;
		}
		else if (self.anim_type == "attack2")
		{
			self.anim_end = CULTIST_ATTACK2_END;
			self.anim_end_num = CULTIST_ATTACK2_END - CULTIST_ATTACK2_START + 1;
			self.anim_time = CULTIST_ATTACK2_TIME;
			self.last_action = "attack2";
			if (self.frame > self.anim_end)
				cultist_run();
			else
				self.frame = CULTIST_ATTACK2_START;
		}
		else if (self.anim_type == "pain")
		{
			self.anim_end = CULTIST_PAIN_END;
			self.anim_end_num = CULTIST_PAIN_END - CULTIST_PAIN_START + 1;
			self.anim_time = CULTIST_PAIN_TIME;
			self.last_action = "pain";
			if (self.frame > self.anim_end)
				cultist_run();
			else
				self.frame = CULTIST_PAIN_START;
		}
		else if (self.anim_type == "death")
		{
			self.anim_end = CULTIST_DEATH_END;
			self.anim_end_num = CULTIST_DEATH_END - CULTIST_DEATH_START + 1;
			self.anim_time = CULTIST_DEATH_TIME;
			self.last_action = "death";
			self.frame = CULTIST_DEATH_START;
		}
	}
	if (!((self.anim_type == "death") && (self.frame == self.anim_end))) 
	{
		self.nextthink = time + (self.anim_time / self.anim_end_num);
		self.think = cultist_animate;
	}
	
	//AI control
	ai_main();
	
	if (self.frame == CULTIST_ATTACK_START && self.anim_type == "attack")
	{
		cultist_attack();
	}
	else if (self.frame == CULTIST_ATTACK2_START && self.anim_type == "attack2")
	{
		cultist_attack2();
	}
	
	if (self.anim_type == "stand") basic_ai(3);
	else if (self.anim_type == "walk") basic_ai(3);
	else if (self.anim_type == "run") basic_ai(6);
	else if (self.anim_type == "attack") ai_face();
	else if (self.anim_type == "attack2") ai_face();
	else if ((self.anim_type == "death") && (self.frame == self.anim_end)) monster_become_corpse();

	//insert sounds or attack damage here with if statements
};

/*
========================================

	Individual Cultist Configurations	

========================================
*/

//	Brown Cultist Configuration
void () brown_cultist_config =
{
	// Precache files needed for TNT tossing
	precache_model ("models/weapons/grenades/gr_tnt.md3");// TNT Projectile
	precache_sound ("cultist/culttoss.wav");              // TNT toss sound
	precache_sound ("weapons/r_exp3.wav");                // TNT explosion sound
	
	// Precache files needed for shooting shotgun
	precache_sound ("cultist/cultatt1.wav"); // Shotgun boom
	precache_sound ("cultist/cultatt2.wav"); // Shotgun boom

	// Setup all brown cultists unique attributes
	self.skin = CULTIST_BROWN;
	self.health = 50;
	self.th_missile = browncultist_attack;
};

//	Red Cultist Configuration
void () red_cultist_config =
{
	// Precache files needed for shooting shotgun
	precache_sound ("cultist/cultatt1.wav"); // Shotgun boom
	precache_sound ("cultist/cultatt2.wav"); // Shotgun boom

	// Setup all red cultists unique attributes
	self.skin = CULTIST_RED;
	self.health = 100;
	self.th_missile = redcultist_attack;
	precache_sound ("cultist/cultmorp.wav");
};

//	Green Cultist Configuration
void () green_cultist_config =
{
	// Precache files needed for TNT tossing
	precache_model ("models/weapons/grenades/gr_tnt.md3");// TNT Projectile
	precache_sound ("cultist/culttoss.wav");              // TNT toss sound
	precache_sound ("weapons/r_exp3.wav");                // TNT explosion sound

	// Setup all green cultists unique attributes
	self.skin = CULTIST_GREEN;
	self.health = 50;
	self.th_missile = greencultist_attack;
	self.resist_burn = 4; 	// TODO: test in Blood and modify value!
};

//	Blue Cultist Configuration
void () blue_cultist_config =
{
	// Setup all blue cultists unique attributes
	self.skin = CULTIST_BLUE;
	self.health = 50;
	self.th_missile = bluecultist_attack;
	precache_model ("progs/teslaball.spr");
	precache_sound ("weapons/tesla/tessngfr.wav");
};

//	Black Cultist Configuration
void () black_cultist_config =
{
	// Setup all black cultists unique attributes
	self.skin = CULTIST_BLACK;
	self.health = 50;
	self.th_missile = blackcultist_attack;	
	precache_sound ("weapons/tommygun/_tom.wav");
	precache_sound ("cultist/tcltdie1.wav"); // Unique Tommy gun cultist sounds
	precache_sound ("cultist/tcltpan2.wav");
	precache_sound ("cultist/tcltpan3.wav");
};

//	Generic Cultist settings that apply to all go in here
void () cultist_spawn =
{    
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
	
	//Call color specific config settings
	if (self.classname == "monster_browncultist")
		brown_cultist_config();
	else if (self.classname == "monster_redcultist")
		red_cultist_config();
	else if (self.classname == "monster_greencultist")
		green_cultist_config();
	else if (self.classname == "monster_bluecultist")
		blue_cultist_config();
	else if (self.classname == "monster_blackcultist")
		black_cultist_config();
	
	// Don't precache sounds that won't be used by black cultist
	if (self.classname != "monster_blackcultist")
	{
		precache_sound ("cultist/cultdie1.wav"); // Death
		precache_sound ("cultist/cultpan2.wav"); // Pain
		precache_sound ("cultist/cultpan3.wav"); // Pain
	}
	
	precache_model ("models/enemies/cultist/cultist.psk");    
	precache_sound ("cultist/cultdie2.wav"); // Death
	precache_sound ("cultist/cultdie3.wav"); // Death
	precache_sound ("cultist/cultfir1.wav"); // On fire
	precache_sound ("cultist/cultfir2.wav"); // On fire
	precache_sound ("cultist/cultfir3.wav"); // On fire
	precache_sound ("cultist/cultglo1.wav"); // Gloating
	precache_sound ("cultist/cultglo2.wav"); // Gloating
	precache_sound ("cultist/cultglo3.wav"); // Gloating
	precache_sound ("cultist/cultglo4.wav"); // Gloating
	precache_sound ("cultist/cultpan1.wav"); // Pain
	precache_sound ("cultist/cultpan4.wav"); // Pain
	precache_sound ("cultist/cultspt1.wav"); // Spotted
	precache_sound ("cultist/cultspt2.wav"); // Spotted
	precache_sound ("cultist/cultspt3.wav"); // Spotted
	precache_sound ("cultist/cultspt4.wav"); // Spotted
	precache_sound ("cultist/cultspt5.wav"); // Spotted

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_WALK;
	setmodel (self, "models/enemies/cultist/cultist.psk");
	setsize (self,'-9.9 -18.6 -0.2', '21.6 18.6 63.7');    
	self.speed = 50;	// walkspeed
	self.max_health = self.health;
	self.th_stand = cultist_stand;
	self.th_walk = cultist_walk;
	self.th_run = cultist_run;
	self.th_die = cultist_die;
	self.th_pain = cultist_pain;
	self.touch = monster_stepped_on;
	self.attack_state = AS_MISSILE;
	walkmonster_start ();    
};
