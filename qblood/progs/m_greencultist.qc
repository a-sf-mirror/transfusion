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

//--- Throwing TNT

/*
void() greencultist_attack1 = [$idle1, greencultist_attack2] {cultist_throw_TNT(); ai_face();};
void() greencultist_attack2 = [$idle1, cultist_run] {ai_face();};
*/

void() greencultist_attack =
{
	local vector delta;

	if (!infront(self.enemy)) // If there's something blocking the shot
		return;

	cultist_taunt();

	delta = (self.enemy.origin - self.origin);

	if (vlen(delta) <= 300)
		ai_back(100);
	else
	{
		//greencultist_attack1();    // Throw TNT at enemy
		self.anim_type = ATTACK1;
		cultist_animate();
	}

};

void() monster_greencultist =
{
	// Precache files needed for TNT tossing
	precache_model("models/weapons/grenades/gr_tnt.md3");// TNT Projectile
	precache_sound("cultist/culttoss.wav");              // TNT toss sound
	precache_sound("weapons/r_exp3.wav");                // TNT explosion sound

	// Setup all green cultists unique attributes
	self.skin = CULTIST_GREEN;
	self.health = 50;
	self.th_missile = greencultist_attack;
	self.resist_burn = 4; 	// TODO: test in Blood and modify value!
	self.netname = "monster_greencultist";

	cultist_spawn();
};
