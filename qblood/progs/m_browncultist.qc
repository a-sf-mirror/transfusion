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

void () browncultist_attackDecide;
void () browncultist_fireShotgun;

//--- Shooting shotgun
/*
void () browncultist_attacka1 = [$attack1, browncultist_attacka2] {ai_face ();};
void () browncultist_attacka2 = [$attack2, browncultist_attacka3] {browncultist_fireShotgun (); ai_face ();};
void () browncultist_attacka3 = [$idle1, cultist_run] {ai_face ();};

//--- Throwing TNT

void () browncultist_attackb1 = [$idle1, browncultist_attackb2] {cultist_throw_TNT (); ai_face ();};
void () browncultist_attackb2 = [$idle1, cultist_run] {ai_face ();};
*/

void () browncultist_attack =
{
	if (!visible(self.enemy)) // If there's something blocking the shot
		return;

	cultist_taunt(); // Talk some smack!

	browncultist_attackDecide();
};

void () browncultist_attackDecide =
{
	local float vis;

	vis = visible(self.enemy);

	if (self.attack_finished < time && vis)
	{
		local float dist;		
		ai_face();                           // Face player

		dist = range(self.enemy);

		if (dist == RANGE_NEAR || dist == RANGE_MELEE)// If the player is near shoot them		      
		{
			//browncultist_attacka1 ();
			self.anim_type = "attack";
			cultist_animate();
		}
		else
		{
			//browncultist_attackb1 ();        // Otherwise TNT them
			self.anim_type = "attack2";
			cultist_animate();
		}
	}
	else
	{
		self.think = cultist_run;            // Turn basic "I have an enemy" AI back on
		self.nextthink = time + 0.1;         // Turn that AI back on in 1/10 of a second
	}
};

//--- Shoot the player

void () browncultist_fireShotgun =
{
	ai_face();
	cultist_fireShotgun();
	self.think = browncultist_attackDecide;
	self.nextthink = time + 0.5;
};

void () monster_browncultist =
{
	// Precache files needed for TNT tossing
	precache_model ("models/weapons/grenades/gr_tnt.md3");// TNT Projectile
	precache_sound ("cultist/culttoss.wav");              // TNT toss sound
	precache_sound ("weapons/r_exp3.wav");                // TNT explosion sound
	
	// Precache files needed for the shotgun
	precache_sawedoff();

	// Precache files needed for shooting shotgun
	precache_sound ("cultist/cultatt1.wav"); // Shotgun boom
	precache_sound ("cultist/cultatt2.wav"); // Shotgun boom

	// Setup all brown cultists unique attributes
	self.skin = CULTIST_BROWN;
	self.health = 50;
	self.th_missile = browncultist_attack;
	self.netname = "monster_browncultist";

	cultist_spawn();

	AttachObject("Weapon_Right");
	self.attachedobject.scale = 0.5;
	self.attachedobject.origin = '0 0 0' + v_forward * 4; // FIXME: adjust the weapon bone?
	setmodel(self.attachedobject, "models/weapons/g_shotgun.md3");
	
};
