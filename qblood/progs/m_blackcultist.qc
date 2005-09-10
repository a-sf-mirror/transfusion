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

// Prototypes

void () blackcultist_fireTommygun;

//--- Shooting gun

/*
void () blackcultist_attack1 = [$attack1, blackcultist_attack2] {ai_face ();};
void () blackcultist_attack2 = [$attack2, blackcultist_attack3] {blackcultist_fireTommygun (); ai_face ();};
void () blackcultist_attack3 = [$idle1, cultist_run] {ai_face ();};
*/

void () blackcultist_attack =
{
    local vector delta;

    cultist_taunt();

    delta = (self.enemy.origin - self.origin);

    if (vlen (delta) <= 1200)
	{
		//blackcultist_attack1 ();    // If the player is near shoot them
		self.anim_type = "attack1";
		cultist_animate();
	}
        
};

//--- Shoot the player

void () blackcultist_fireTommygun =
{
    local vector    dir;
    local entity    old;
    local vector    orig;
    local vector    spread;
	local vector    org;
    local float     damage;

    makevectors (self.v_angle);

    self.effects = self.effects | EF_MUZZLEFLASH;

    sound (self, CHAN_WEAPON, "weapons/tommygun/_tom.wav", 1, ATTN_NORM);
    self.attack_finished = time + 0.1;

    // set the bullet direction according to the weapon real direction
    dir = (self.enemy.origin - self.origin);
    dir = normalize (dir);

    orig = self.origin + v_forward * 15 + v_up * 12 + v_right * 4;

    // Spawn 1 shell every 2 shots
    Tommy_SpawnShell (orig);

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
	
	FireBullets (org, dir, 1, 10, '0.1 0.1 0');

	// Keep attacking until enemy is out of range or dead
	if(visible(self.enemy) && self.enemy.health > 1)
	    self.think = blackcultist_attack;
	
	else
	    self.think = self.th_run;
		
	self.nextthink = time + 0.1;
	
};

void () monster_blackcultist =
{
    //  Disable for testing
    if(monster_check())
	    return;

	cultist_spawn();
};
