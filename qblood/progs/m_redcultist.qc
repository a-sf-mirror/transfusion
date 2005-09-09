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

void () redcultist_fireShotgun;
void () redcultist_attackDecide;

//--- Shooting gun

void () redcultist_attack1 = [$attack1, redcultist_attack2] {ai_face ();};
void () redcultist_attack2 = [$attack2, redcultist_attack3] {redcultist_fireShotgun (); ai_face ();};
void () redcultist_attack3 = [$idle1, cultist_run] {ai_face ();};

void () redcultist_attack =
{
    if (!visible(self.enemy)) // If there's something blocking the shot
        return;

    cultist_taunt(); // Talk some smack!

    redcultist_attackDecide();

};

void () redcultist_attackDecide =
{
    local float vis;
	
	vis = visible(self.enemy);
	
    if (self.attack_finished < time && vis)
    {
        ai_face();                        // Face player
        redcultist_attack1 ();
    }
    else
    {
        self.think = cultist_run;     // Turn basic "I have an enemy" AI back on
        self.nextthink = time + 0.1;    // Turn that AI back on in 1/10 of a second
    }

};

//--- Shoot the player

void () redcultist_fireShotgun =
{
    ai_face();
    cultist_fireShotgun();

    self.think = redcultist_attackDecide;
    self.nextthink = time + 0.5;
};

void () monster_redcultist =
{
    //  Disable for testing
    if(monster_check())
	    return;

    cultist_spawn();
};
