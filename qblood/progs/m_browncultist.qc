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

// Prototypes

void () browncultist_attackDecide;
void () browncultist_fireShotgun;

//--- Shooting shotgun

void () browncultist_attacka1 = [$attack1, browncultist_attacka2] {ai_face ();};
void () browncultist_attacka2 = [$attack2, browncultist_attacka3] {browncultist_fireShotgun (); ai_face ();};
void () browncultist_attacka3 = [$idle1, cultist_run] {ai_face ();};

//--- Throwing TNT

void () browncultist_attackb1 = [$idle1, browncultist_attackb2] {cultist_throw_TNT (); ai_face ();};
void () browncultist_attackb2 = [$idle1, cultist_run] {ai_face ();};


void () browncultist_attack =
{
    if (!infront(self.enemy)) // If there's something blocking the shot
        return;

    cultist_taunt(); // Talk some smack!

    browncultist_attackDecide();
};

void () browncultist_attackDecide =
{
    if (self.attack_finished > time)
    {
        ai_face();                           // Face player

        if (range(self.enemy) == RANGE_NEAR ||
            range(self.enemy) == RANGE_MELEE)// If the player is near shoot them
            browncultist_attacka1 ();
        else
            browncultist_attackb1 ();        // Otherwise TNT them
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
    //  Disable for testing
    monster_check();
    cultist_spawn();
};
