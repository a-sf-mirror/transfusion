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

void () bluecultist_fireTesla;

//--- Shooting gun

/*
void () bluecultist_attack1 = [$attack1, bluecultist_attack2] {ai_face ();};
void () bluecultist_attack2 = [$attack2, bluecultist_attack3] {bluecultist_fireTesla (); ai_face ();};
void () bluecultist_attack3 = [$idle1, cultist_run] 
{
	ai_face ();
	self.cnt = self.cnt + 1;

	if (random() <= 0.5 && self.cnt < 3)
		bluecultist_attack1();
	else
		self.cnt = 0;
};
*/

void () bluecultist_attack =
{
	local vector delta;

	if (!infront(self.enemy)) // If there's something blocking the shot
		return;

	// Talk some smack!
	cultist_taunt();

	delta = (self.enemy.origin - self.origin);

	if (vlen (delta) <= 1200)
	{
		//bluecultist_attack1 ();    // If the player is near shoot them    
		self.anim_type = ATTACK1;
		cultist_animate();
	}
};

//--- Shoot the player
void () bluecultist_fireTesla =
{
	local   vector  org;
	local   vector  dir;

	muzzleflash ();

	sound (self, CHAN_WEAPON, "weapons/tesla/tessngfr.wav", 1, ATTN_NORM);

	dir = (self.enemy.origin - self.origin);
	org = self.origin + '0 0 16';

	Tesla_LaunchJolt (org, dir, 1500);
};

void () monster_bluecultist =
{
	// Setup all blue cultists unique attributes
	self.skin = CULTIST_BLUE;
	self.health = 50;
	self.th_missile = bluecultist_attack;
	precache_model ("progs/teslaball.spr");
	precache_sound ("weapons/tesla/tessngfr.wav");
	self.netname = "monster_bluecultist";

	cultist_spawn();
};
