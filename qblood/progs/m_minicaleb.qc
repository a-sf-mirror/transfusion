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

    Need to get sound lengths for pain/taunts
    Fix bounding box
    Fix rate of shotgun fire
    Need real attack / health values
*/


#include "common.qh"
#include "player.qh"    // For player.mdl frames


$base base
$skin skin

// idle

$frame idle1


// Prototypes

void () minicaleb_stand1;
void () minicaleb_fireShotgun;
void () minicaleb_attackDecide;

void (float dist) minicaleb_ai =
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

void () minicaleb_walk1 = [$stand1, minicaleb_walk1] {minicaleb_ai (3);};

//--- Decide which idle to do

void () minicaleb_stand =
{
    cultist_stand();
    minicaleb_stand1();
};

//--- Basic idle

void () minicaleb_stand1 = [$stand1, minicaleb_stand1] {ai_stand();};

void () minicaleb_walk =
{
    self.style = 2;
    minicaleb_walk1 ();
};

void () minicaleb_run =
{
    self.style = 3;
    minicaleb_walk1 ();
};

//--- Shooting gun

void () minicaleb_attack1 = [$attack1, minicaleb_attack2] {minicaleb_fireShotgun (); ai_face ();};
void () minicaleb_attack2 = [$attack2, minicaleb_run] {ai_face ();};

void () minicaleb_attack =
{
    local float r;

    if (!infront(self.enemy)) // If there's something blocking the shot
        return;

    r = random();

    if (self.pain_finished < time && self.attack_finished < time)// To avoid several sounds at once
    if (r <= 0.20)
        sound (self, CHAN_AUTO, "player/taunts/t1002.wav", 1, ATTN_NORM); // FIXME: Need real sound lengths
    else if (r <= 0.40)
        sound (self, CHAN_AUTO, "player/taunts/t1005.wav", 1, ATTN_NORM);
    else if (r <= 0.60)
        sound (self, CHAN_AUTO, "player/taunts/t1006.wav", 1, ATTN_NORM);
    else if (r <= 0.80)
        sound (self, CHAN_AUTO, "player/taunts/t1010.wav", 1, ATTN_NORM);


    self.attack_finished = time + 2; // FIXME: Put this per sound once I have the lengths

    minicaleb_attackDecide();

};

void () minicaleb_attackDecide =
{
    if (self.attack_finished > time)
    {
        ai_face();                        // Face player
        minicaleb_attack1 ();
    }
    else
    {
        self.think = minicaleb_run;     // Turn basic "I have an enemy" AI back on
        self.nextthink = time + 0.3;    // Turn that AI back on in 3/10 of a second
    }

};

//--- Shoot the player

void () minicaleb_fireShotgun =
{
    ai_face();
    cultist_fireShotgun();

    self.think = minicaleb_attackDecide;
    self.nextthink = time + 0.5;
};


void () minicaleb_pain1 = [$pain1, minicaleb_pain2]
{
    if (self.pain_finished > time)
        return;

    sound (self,2,"player/pain/play1106.wav",1,1);
    self.pain_finished = time + 2;  // FIXME: Need real sound length here
    ai_pain(1);
};
void () minicaleb_pain2 = [$pain2, minicaleb_pain3]{};
void () minicaleb_pain3 = [$pain3, minicaleb_pain4]{};
void () minicaleb_pain4 = [$pain4, minicaleb_pain5]{};
void () minicaleb_pain5 = [$pain5, minicaleb_run]{};

//--- Death sequence

void () minicaleb_death1 = [$deatha1, minicaleb_death2]{};
void () minicaleb_death2 = [$deatha2, minicaleb_death3]{};
void () minicaleb_death3 = [$deatha3, minicaleb_death4]{};
void () minicaleb_death4 = [$deatha4, minicaleb_death5]{};
void () minicaleb_death5 = [$deatha5, minicaleb_death6]{};
void () minicaleb_death6 = [$deatha6, minicaleb_death6]
{
    // In the last frame, remove self 15 seconds after death
   self.nextthink = time + 15;
   self.think = SUB_Remove;
};

void () minicaleb_die =
{
    minicaleb_death1 ();
    sound (self,2,"player/die3.wav",1,1);
    /*
        Need to add "splat" here
    */


   self.solid = SOLID_NOT;
};

void () monster_minicaleb =
{

/* Disable for testing the model

    if (deathmatch)
    {
        remove (self);
        return ;
    }
*/
    precache_model ("progs/player.mdl");

    precache_sound ("cultist/cultatt1.wav");// Shotgun
    precache_sound ("cultist/cultatt2.wav");// Shotgun
    precache_sound ("player/taunts/t1002.wav"); // "this is my boom stick"
    precache_sound ("player/taunts/t1005.wav"); // "all I want's a friend"
    precache_sound ("player/taunts/t1006.wav"); // "noone wants to play with me"
    precache_sound ("player/taunts/t1010.wav"); // "i live again"
    precache_sound ("player/pain/play1106.wav");// pain
    precache_sound ("player/die3.wav");         // death

    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_STEP;
    setmodel (self, "progs/player.mdl");
    self.scale = 0.5;
    self.frame = $run1;
    setsize (self,'16 -14 -10', '32 14 32'); // FIXME: Need real values
    self.health = 100;
    self.max_health = self.health;
    self.th_stand = minicaleb_stand;
    self.th_walk = minicaleb_walk;
    self.th_run = minicaleb_run;
    self.th_die = minicaleb_die;
    self.th_pain = minicaleb_pain1;
    self.th_missile = minicaleb_attack;
    self.touch = monster_stepped_on;
    walkmonster_start ();
};
