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

/* Tim's to-do list

    Shotgun does not hit up close - jump back hack implemented. real fix???
    Test the idle smack talk
    Too many sounds at once
    need more than one frame - luke
    need to get real health and damage values
    head - make use of cultist head with ThrowHead().  Kick cultist head around!
    damage to player if you touch cultist - in player.qc, for all monsters?
*/


#include "common.qh"


$base base
$skin skin

// idle

$frame idle1


// Prototypes

void () greencultist_stand1;


void (float dist) greencultist_ai =
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

//--- Walking around

void () greencultist_walk1 = [$idle1, greencultist_walk1] {greencultist_ai (3);};

//--- stand around and speak gibberish

void () greencultist_stand =
{
    cultist_stand();
    greencultist_stand1();
};

//--- Basic idle

void () greencultist_stand1 = [$idle1, greencultist_stand1] {ai_stand();};

void () greencultist_walk =
{
    self.style = 2;
    greencultist_walk1 ();
};

void () greencultist_run =
{
    self.style = 3;
    greencultist_walk1();
};


//--- Throwing TNT

void () greencultist_attack1 = [$idle1, greencultist_attack2] {cultist_throw_TNT (); ai_face ();};
void () greencultist_attack2 = [$idle1, greencultist_run] {ai_face ();};


void () greencultist_attack =
{
    local vector delta;

    if (!infront(self.enemy)) // If there's something blocking the shot
        return;

    cultist_attack();

    delta = (self.enemy.origin - self.origin);

    if (vlen (delta) <= 300)
        ai_back(100);
    else
        greencultist_attack1 ();    // Throw TNT at enemy

};

void () greencultist_pain =
{
    cultist_pain();

//    greencultist_pain1 (); // FIXME: Need pain frames - luke

};

//--- Death sequence

void () greencultist_death1 = [$idle1, greencultist_death1]
{
    // In the last frame, remove self 15 seconds after death
    self.nextthink = time + 15;
    self.think = SUB_Remove;
};

void () greencultist_die =
{
    cultist_die();
    greencultist_death1 ();
};

void () monster_greencultist =
{
/* Disable for testing the model

    if (deathmatch)
    {
        remove (self);
        return ;
    }
*/
    precache_model ("models/enemies/cultist-green.md3");
    precache_model ("models/weapons/grenades/gr_tnt.md3");

    precache_sound ("cultist/cultdie1.wav");
    precache_sound ("cultist/cultdie2.wav");
    precache_sound ("cultist/cultdie3.wav");
    precache_sound ("cultist/cultfir1.wav");
    precache_sound ("cultist/cultfir2.wav");
    precache_sound ("cultist/cultfir3.wav");
    precache_sound ("cultist/cultglo1.wav");
    precache_sound ("cultist/cultglo2.wav");
    precache_sound ("cultist/cultglo3.wav");
    precache_sound ("cultist/cultglo4.wav");
    precache_sound ("cultist/cultpan1.wav");
    precache_sound ("cultist/cultpan2.wav");
    precache_sound ("cultist/cultpan3.wav");
    precache_sound ("cultist/cultpan4.wav");
    precache_sound ("cultist/cultspt1.wav");
    precache_sound ("cultist/cultspt2.wav");
    precache_sound ("cultist/cultspt3.wav");
    precache_sound ("cultist/cultspt4.wav");
    precache_sound ("cultist/cultspt5.wav");
    precache_sound ("cultist/culttoss.wav");
    precache_sound ("weapons/r_exp3.wav");    // TNT explosion sound

    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_STEP;
    setmodel (self, "models/enemies/cultist-green.md3");
    setsize (self,'-6 -14 0', '34 14 62');
    self.health = 200;
    self.max_health = self.health;
    self.th_stand = greencultist_stand;
    self.th_walk = greencultist_walk;
    self.th_run = greencultist_run;
    self.th_die = greencultist_die;
    self.th_pain = greencultist_pain;
    self.th_missile = greencultist_attack;
    walkmonster_start ();
};
