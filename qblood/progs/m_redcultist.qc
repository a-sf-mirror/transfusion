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

void () redcultist_stand1;
void () redcultist_fireShotgun;
void () redcultist_attackDecide;

void (float dist) redcultist_ai =
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

void () redcultist_walk1 = [$idle1, redcultist_walk1] {redcultist_ai (3);};

//--- Decide which idle to do

void () redcultist_stand =
{
    cultist_stand();
    redcultist_stand1();
};

//--- Basic idle

void () redcultist_stand1 = [$idle1, redcultist_stand1] {ai_stand();};

void () redcultist_walk =
{
    self.style = 2;
    redcultist_walk1 ();
};

void () redcultist_run =
{
    self.style = 3;
    redcultist_walk1 ();
};

//--- Shooting gun

void () redcultist_attack1 = [$idle1, redcultist_attack2] {redcultist_fireShotgun (); ai_face ();};
void () redcultist_attack2 = [$idle1, redcultist_run] {ai_face ();};

void () redcultist_attack =
{
    if (!infront(self.enemy)) // If there's something blocking the shot
        return;

    cultist_attack(); // Talk some smack!

    redcultist_attackDecide();

};

void () redcultist_attackDecide =
{
    if (self.attack_finished > time)
    {
        ai_face();                        // Face player
        redcultist_attack1 ();
    }
    else
    {
        self.think = redcultist_run;     // Turn basic "I have an enemy" AI back on
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


void () redcultist_pain =
{
      cultist_pain();

//    redcultist_pain1 (); // FIXME: Need pain frames - luke

};

//--- Death sequence

void () redcultist_death1 = [$idle1, redcultist_death1]
{
    // In the last frame, remove self 15 seconds after death
    self.nextthink = time + 15;
    self.think = SUB_Remove;
};

void () redcultist_die =
{
    redcultist_death1 ();
    sound (self,2,"cultist/cultmorp.wav",1,1);
    /*
        Need to remove self here, and spawn a beast at same facing / coordinates
    */

    self.solid = SOLID_NOT;
};

void () monster_redcultist =
{

/* Disable for testing the model

    if (deathmatch)
    {
        remove (self);
        return ;
    }
*/
    precache_model ("models/enemies/cultist-red.md3");
    precache_model ("models/weapons/grenades/gr_tnt.md3");

    precache_sound ("cultist/cultatt1.wav");
    precache_sound ("cultist/cultatt2.wav");
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
    precache_sound ("cultist/cultmorp.wav");

    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_STEP;
    setmodel (self, "models/enemies/cultist-red.md3");
    setsize (self,'-6 -14 0', '34 14 62');
    self.health = 200;
    self.max_health = self.health;
    self.th_stand = redcultist_stand;
    self.th_walk = redcultist_walk;
    self.th_run = redcultist_run;
    self.th_die = redcultist_die;
    self.th_pain = redcultist_pain;
    self.th_missile = redcultist_attack;
    walkmonster_start ();
};
