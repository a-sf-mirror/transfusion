/*  Copyright (C) 1996-1997  Id Software, Inc.

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
================
monster_use

Using a monster makes it angry at the current activator
================
*/
void() monster_use =
{
    if (self.enemy)
        return;
    if (self.health <= 0)
        return;
    if (activator.items & IT_INVISIBILITY)
        return;
    if (activator.flags & FL_NOTARGET)
        return;
    if (activator.classname != "player")
        return;

	// delay reaction so if the monster is teleported, its sound is still heard
    self.enemy = activator;
    self.nextthink = time + 0.1;
    self.think = FoundTarget;
};

//============================================================================

void() walkmonster_start_go =
{
    self.origin_z = self.origin_z + 1;  // raise off floor a bit
    droptofloor();

    if (!walkmove(0,0))
    {
	    bprint (self.classname);
        bprint (" stuck at: ");
        bprint (vtos(self.origin));
        bprint ("\n");		
    }

    self.takedamage = DAMAGE_AIM;

    self.ideal_yaw = self.angles * '0 1 0';
    if (!self.yaw_speed)
        self.yaw_speed = 20;
    self.view_ofs = '0 0 25';
    self.use = monster_use;

    self.flags = self.flags | FL_MONSTER;

    if (self.target)
    {
        self.goalentity = self.movetarget = find(world, targetname, self.target);
        self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
        if (!self.movetarget)
        {
            dprint ("Monster can't find target at ");
            dprint (vtos(self.origin));
            dprint ("\n");
        }
		// this used to be an objerror
        if (self.movetarget.classname == "path_corner")
            self.th_walk ();
        else
            self.pausetime = 99999999;
            self.th_stand ();
    }
    else
    {
        self.pausetime = 99999999;
        self.th_stand ();
    }

	// spread think times so they don't all happen at same time
    self.nextthink = self.nextthink + random()*0.5;
};


void() walkmonster_start =
{
	// delay drop to floor to make sure all doors have been spawned
	// spread think times so they don't all happen at same time
    self.nextthink = self.nextthink + random()*0.5;
    self.think = walkmonster_start_go;
    total_monsters = total_monsters + 1;

	// Needed for random health drop
	precache_model ("models/items/i_essence.md3");
	precache_sound ("items/pickheal.wav");
	
	// Needed for random weapon / ammo drops	
	if (self.classname == "monster_browncultist")
	{
	    precache_model ("models/ammo/a_fewshell.md3");		
		precache_sawedoff();	 
	}
	else if (self.classname == "monster_blackcultist")
	{
	    precache_model ("models/ammo/a_fewbullet.md3");		
	    precache_tommygun();
	}
	else if (self.classname == "monster_greencultist")
	{
		precache_model ("models/ammo/a_tnt.md3");
	    precache_tnt();
	}
	else if (self.classname == "monster_bluecultist")
	{
	    precache_model ("models/ammo/a_battery.md3");
		precache_teslacannon();
	}
	else if (self.classname == "monster_gargoyle" ||
		     self.classname == "monster_hellhound"||
		     self.classname == "monster_phantasm")
    {
	    precache_model ("models/items/i_seed.md3");
	}	
};



void() flymonster_start_go =
{
    self.takedamage = DAMAGE_AIM;

    self.ideal_yaw = self.angles * '0 1 0';
    if (!self.yaw_speed)
        self.yaw_speed = 10;
    self.view_ofs = '0 0 25';
    self.use = monster_use;

    self.flags = self.flags | FL_FLY;
    self.flags = self.flags | FL_MONSTER;

    if (!walkmove(0,0))
    {
        dprint ("flymonster in wall at: ");
        dprint (vtos(self.origin));
        dprint ("\n");
    }

    if (self.target)
    {
        self.goalentity = self.movetarget = find(world, targetname, self.target);
        if (!self.movetarget)
        {
            dprint ("Monster can't find target at ");
            dprint (vtos(self.origin));
            dprint ("\n");
        }
// this used to be an objerror
        if (self.movetarget.classname == "path_corner")
            self.th_walk ();
        else
            self.pausetime = 99999999;
            self.th_stand ();
    }
    else
    {
        self.pausetime = 99999999;
        self.th_stand ();
    }
};

void() flymonster_start =
{
// spread think times so they don't all happen at same time
    self.nextthink = self.nextthink + random()*0.5;
    self.think = flymonster_start_go;
    total_monsters = total_monsters + 1;
};


void() swimmonster_start_go =
{
    self.takedamage = DAMAGE_AIM;
    total_monsters = total_monsters + 1;

    self.ideal_yaw = self.angles * '0 1 0';
    if (!self.yaw_speed)
        self.yaw_speed = 10;
    self.view_ofs = '0 0 10';
    self.use = monster_use;

    self.flags = self.flags | FL_SWIM;
    self.flags = self.flags | FL_MONSTER;

    if (self.target)
    {
        self.goalentity = self.movetarget = find(world, targetname, self.target);
        if (!self.movetarget)
        {
            dprint ("Monster can't find target at ");
            dprint (vtos(self.origin));
            dprint ("\n");
        }
// this used to be an objerror
        self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
        self.th_walk ();
    }
    else
    {
        self.pausetime = 99999999;
        self.th_stand ();
    }

// spread think times so they don't all happen at same time
    self.nextthink = self.nextthink + random()*0.5;
};

void() swimmonster_start =
{
// spread think times so they don't all happen at same time
    self.nextthink = self.nextthink + random()*0.5;
    self.think = swimmonster_start_go;
    total_monsters = total_monsters + 1;
};

/*
    monster_stepped_on
    For everything that can be stepped on and damaged (i.e. rats, spiders, minicaleb)

*/

void () monster_stepped_on =
{
    SUB_SolidTouch();

    // If we've gotten here an enemy is touching my bbox.  But is the enemy on TOP of me?
    if ((self.enemy.absmin_z <= self.absmax_z + 3) && 
	    (self.enemy.absmin_z >= self.absmax_z - 3))		
	    T_Damage (self, self.enemy, self.enemy, 1, DF_BODY, "squashing");		
	else 
	    return;

    if (self.health > 1)    // To avoid "undead" enemies.  Monsters shouldn't think after they're dead!
        self.th_pain(self.enemy, 0);
};

void () monster_drop_key =
{
	    local entity key;
		
		key = spawn();
		key.spawnflags = self.items2;		
		key.origin = self.origin;
		key.think = item_key;
		key.nextthink = time + 0.1;
};

float () monster_check =
{
    if (cvar("nomonsters")      && 
	    self.items2 >= IT2_KEY1 && 
		self.items2 <= IT2_KEY6 &&
		(gametype == GT_COOPERATIVE || gametype == GT_SINGLE_PLAYER))
    {
	    monster_drop_key();
	}

	if (cvar("nomonsters") || self.spawnflags > skill || 
	   (gametype != GT_COOPERATIVE && gametype != GT_SINGLE_PLAYER))
    {
	    remove(self);
		return 1;
	}
	
	self.netname = "monster";
};

/*
    monster_death
	
	clears monster effects and sets corpse non-solid
	drops random item based on monster class
	drops key if monster has key

*/
void () monster_death =
{
    local float r;
	local entity drop_item;
	
	self.effects = 0;
	KillBurner(self);
	self.solid = SOLID_NOT;
	self.deadflag = DEAD_DEAD;
	SUB_UseTargets();
	
	if (self.items2 >= IT2_KEY1 && self.items2 <= IT2_KEY6)
    {
	    monster_drop_key();
		return;
	}
	
	// These monsters never drop anything
	if (self.classname == "monster_bat"           ||
        self.classname == "monster_rat"           ||
		self.classname == "monster_eel"           ||
		self.classname == "monster_hand"          ||
		self.classname == "monster_redspider"     ||
		self.classname == "monster_greenspider"   ||
		self.classname == "monster_minicaleb"	  ||
		self.classname == "monster_chrysalid_pod" ||
		self.classname == "monster_fire_pod"      ||
		self.classname == "monster_mime"          ||
		self.classname == "monster_stonegargoyle" ||
		self.classname == "monster_shial"         ||
		self.classname == "monster_cerebrus"      ||
		self.classname == "monster_tchernobog"    ||
		self.classname == "monster_redcultist"    ||
		self.classname == "monster_beast")
		return;
	
	r = random();
	
	if (r <= 0.2)
	{
	    drop_item = spawn ();
        drop_item.classname = "drop_item";
	    drop_item.owner = self;
	    drop_item.origin = self.origin;
		drop_item.think = SUB_Remove;
		
	    if (r <= 0.05)
	    {
            // Cultist weapons
			if (self.classname == "monster_browncultist")
		        drop_item.think = weapon_sawedoff;
				
			else if (self.classname == "monster_blackcultist")
		        drop_item.think = weapon_tommygun;

			else if (self.classname == "monster_greencultist")
		        drop_item.think = weapon_tnt;
				
			else if (self.classname == "monster_bluecultist")
		        drop_item.think = weapon_teslacannon;	
	    }	
	    else if (r <= 0.1)
	    {
		    // Cultist ammos
			if (self.classname == "monster_browncultist")
		        drop_item.think = ammo_shell;
				
			else if (self.classname == "monster_blackcultist")
		        drop_item.think = ammo_bullets;			
				
			else if (self.classname == "monster_bluecultist")
		        drop_item.think = ammo_batteries;
			
			// Gargoyles, Hell hounds, Phantasms drop life seeds
			else if (self.classname == "monster_gargoyle" ||
			         self.classname == "monster_hellhound"||
					 self.classname == "monster_phantasm")
					 {
					     drop_item.spawnflags = 2;         // flag for life seed
						 drop_item.think = item_health;
					 }
	    }	
	    else if (r <= 0.2)
	    {
		    // Cultists, zombies, butchers, innocents, gill beasts, drop regular hearts
			if (self.classname == "monster_browncultist" ||
			    self.classname == "monster_blackcultist" ||
				self.classname == "monster_greencultist" ||
				self.classname == "monster_bluecultist"  ||
				self.classname == "monster_butcher"      ||
				self.classname == "monster_zombie"       ||
				self.classname == "monster_innocent"     ||
				self.classname == "monster_gillbeast")
				{
				    drop_item.spawnflags = 1;         // flag for basic heart
					drop_item.think = item_health;
				}
	    }
		drop_item.nextthink = time + 0.1;
	}
};

void () monster_become_corpse =
{
	local vector minBbox, maxBbox;
	
	self.th_stand = self.th_walk = self.th_run = self.th_pain = self.th_missile = SUB_Null;

	self.health = self.max_health / 2;

	// FIXME: need to set bounding box based on angular data and size of corpse model
    minBbox = '-32 -32 -20';
    maxBbox = '32 32 0';

    // Set corpse bbox min z based upon the monster's min z
    minBbox_z = self.mins_z;

    maxBbox_z = minBbox_z + 5;
    self.solid = SOLID_BBOX;
	setsize (self, minBbox, maxBbox);
    self.touch = SUB_SolidTouch;
	self.think = FadeAway;
	self.reset = SUB_Remove;
	self.oldorigin = self.origin;
	self.nextthink = time + 30;
	self.th_die = GibPlayerCorpse;
	self.classname = "corpse";
	self.flags = 0;
	self.movetype = MOVETYPE_TOSS;
	self.takedamage = DAMAGE_AIM;
};

void () mime_stand1 = [1, mime_stand2 ]{self.nextthink = time + 1;};
void () mime_stand2 = [2, mime_stand3 ]{self.nextthink = time + 1;};
void () mime_stand3 = [3, mime_stand4 ]{self.nextthink = time + 1;};
void () mime_stand4 = [0, mime_stand1 ]{self.nextthink = time + 1;};

void () mime_die = 
{
    if (self.sounds == 1)
        localcmd("play player/quips/1081.wav\n"); // I hate mimes!
    else if (self.sounds == 2)
        localcmd("play player/quips/1082.wav\n"); // Pathetic insects

    RandomHumanGibs();
    monster_death();
    remove(self);
};

void () monster_mime =
{
    precache_model ("mime.spr");
    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_TOSS;
    self.takedamage = DAMAGE_AIM;
    self.flags = self.flags | FL_MONSTER;
    setmodel (self, "mime.spr");
    setsize (self, '-10 -10 -30', '10 10 29');
    self.health = 50;
    self.th_die = mime_die;
    self.max_health = self.health;
	self.touch = monster_stepped_on;
    self.netname = "monster";
    self.nextthink = time + 1;
    self.think = mime_stand1;
};
