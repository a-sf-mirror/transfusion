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
#include "m_cultist.qh"

// Shared cultist functions
void () cultist_die;         // Brown, Black, Blue, Green
void () cultist_fireShotgun; // Brown, Red
void () cultist_pain;        // all
void () cultist_stand;       // all
void () cultist_throw_TNT;   // Brown, Green
void () cultist_TNT_touch;   // Brown, Green

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

void () cultist_death1 = [$idle1, cultist_death1]
{
    CloneCorpse (self);

    // In the last frame, spawn corpse, remove self 1 second after death
    self.nextthink = time + 1;
    self.think = SUB_Remove;
};

void () cultist_die =
{
    monster_death();
	
	if (self.classname != "monster_redcultist")
	{
    
	    if (self.health < -40)
        {
            sound (self, CHAN_VOICE, "cultist/cultdie3.wav", 1, ATTN_NORM);
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
	cultist_death1 ();
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
		
	if (self.deathtype != "fire") // FIXME: This is here until I can spread it through pain frames
        ai_pain(15);
		
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
    missile.velocity = missile.velocity * dist; // instead of distance, was 600
    missile.velocity_z = 425;

    missile.avelocity = '300 300 300';

    missile.angles = vectoangles(missile.velocity);

    missile.touch = cultist_TNT_touch;

    setmodel (missile, "models/weapons/grenades/gr_tnt.md3");
    setsize (missile, '0 0 0', '0 0 0');
    setorigin (missile, self.origin);

};

void () cultist_TNT_touch =
{
    sound (self, CHAN_WEAPON, "weapons/r_exp3.wav", 1, ATTN_NORM);
    T_RadiusDamage (self, self.owner, 130, world, "grenade"); // FIXME: Make w_bomb.qc defines global?
    BecomeExplosion ();
};

void (float dist) cultist_ai =
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

//--- Basic idle
void () cultist_stand1 = [$idle1, cultist_stand1] {cultist_ai(3);};

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
    cultist_stand1();
};

void () cultist_walk1 = [$walk1, cultist_walk2] {cultist_ai (3);};
void () cultist_walk2 = [$walk2, cultist_walk3] {cultist_ai (3);};
void () cultist_walk3 = [$walk3, cultist_walk4] {cultist_ai (3);};
void () cultist_walk4 = [$walk4, cultist_walk5] {cultist_ai (3);};
void () cultist_walk5 = [$walk5, cultist_walk6] {cultist_ai (3);};
void () cultist_walk6 = [$walk6, cultist_walk7] {cultist_ai (3);};
void () cultist_walk7 = [$walk7, cultist_walk8] {cultist_ai (3);};
void () cultist_walk8 = [$walk8, cultist_walk9] {cultist_ai (3);};
void () cultist_walk9 = [$walk9, cultist_walk10] {cultist_ai (3);};
void () cultist_walk10 = [$walk10, cultist_walk11] {cultist_ai (3);};
void () cultist_walk11 = [$walk11, cultist_walk12] {cultist_ai (3);};
void () cultist_walk12 = [$walk12, cultist_walk1] {cultist_ai (3);};

void () cultist_walk =
{
    self.style = 2;
    cultist_walk1 ();
};

void () cultist_run =
{
    self.style = 3;
    cultist_walk1 ();
};

void () cultist_spawn =
{    
	// Precache files needed for TNT tossing
	
	if (self.classname == "monster_browncultist" ||
	    self.classname == "monster_greencultist" )
	{
	precache_model ("models/weapons/grenades/gr_tnt.md3");// TNT Projectile
	precache_sound ("cultist/culttoss.wav");              // TNT toss sound
    precache_sound ("weapons/r_exp3.wav");                // TNT explosion sound
	}	
	
	// Precache files needed for shooting shotgun
	
	if (self.classname == "monster_browncultist" ||
	    self.classname == "monster_redcultist" )
	{	
	precache_sound ("cultist/cultatt1.wav"); // Shotgun boom
    precache_sound ("cultist/cultatt2.wav"); // Shotgun boom
	}
	
	// Setup all brown cultists unique attributes
	
	if (self.classname == "monster_browncultist")
	{
	self.skin = CULTIST_BROWN;
	self.health = 175;
	self.th_missile = browncultist_attack;
	}
	
	// Setup all red cultists unique attributes
	
	if (self.classname == "monster_redcultist")
	{
	self.skin = CULTIST_RED;
    self.health = 200;
	self.th_missile = redcultist_attack;
	precache_sound ("cultist/cultmorp.wav");
	}

   	// Setup all green cultists unique attributes
	
	if (self.classname == "monster_greencultist")
	{
	self.skin = CULTIST_GREEN;
    self.health = 200;
    self.th_missile = greencultist_attack;
	self.armor_fire = 100; 
	}
	
	// Setup all blue cultists unique attributes
	
	if (self.classname == "monster_bluecultist")
	{
	self.skin = CULTIST_BLUE;
	self.health = 300;
	self.th_missile = bluecultist_attack;
	self.armor_body = 100;
	precache_model ("progs/teslaball.spr");
    precache_sound ("weapons/tesla/tessngfr.wav");
	}
	
	// Setup all black cultists unique attributes
	
	if (self.classname == "monster_blackcultist")
	{
	self.skin = CULTIST_BLACK;
	self.health = 200;
	self.th_missile = blackcultist_attack;	
	precache_sound ("weapons/tommygun/_tom.wav");
	precache_sound ("cultist/tcltdie1.wav"); // Unique Tommy gun cultist sounds
    precache_sound ("cultist/tcltpan2.wav");
    precache_sound ("cultist/tcltpan3.wav");
	}
		
	// Don't precache sounds that won't be used by black cultist
	
	if (self.classname != "monster_blackcultist")
	{
	precache_sound ("cultist/cultdie1.wav"); // Death
    precache_sound ("cultist/cultpan2.wav"); // Pain
    precache_sound ("cultist/cultpan3.wav"); // Pain
	}
	
	precache_model ("models/enemies/cultist.md3");    
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
    self.movetype = MOVETYPE_TOSS;
	setmodel (self, "models/enemies/cultist.md3");
    setsize (self,'-6 -14 0', '34 14 62');    
    self.max_health = self.health;
    self.th_stand = cultist_stand;
    self.th_walk = cultist_walk;
    self.th_run = cultist_run;
    self.th_die = cultist_die;
    self.th_pain = cultist_pain;
	self.attack_state == AS_MISSILE;
	walkmonster_start ();    
};
