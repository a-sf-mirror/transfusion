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


// idle

$frame idle1

// run

$frame run1 run2 run3 run4 run5 run6

//attack1

$frame attack1 attack2 attack3 attack4 attack5 attack6 attack7 attack8


// Prototypes
void () zombie_stand1;
void () zombie_axeAttack;

void () zombie_walk1 = [$run1, zombie_walk2] {basic_ai (4);};
void () zombie_walk2 = [$run2, zombie_walk3] {basic_ai (4);};
void () zombie_walk3 = [$run3, zombie_walk4] {basic_ai (4);};
void () zombie_walk4 = [$run4, zombie_walk5] {basic_ai (4);};
void () zombie_walk5 = [$run5, zombie_walk6] {basic_ai (4);};
void () zombie_walk6 = [$run6, zombie_walk1] {basic_ai (4);};

void () zombie_stand =
{
    if (random () < 0.05)
        sound (self, CHAN_VOICE, "axezombie/azomroam.wav", 1, ATTN_IDLE);

    self.style = 1;
    zombie_stand1();
};

// idle
void () zombie_stand1 = [$idle1, zombie_stand1] {ai_stand();};

void () zombie_walk =
{
    self.style = 2;
    zombie_walk1 ();
};

void () zombie_run =
{
    self.style = 3;
    zombie_walk1 ();
};

// --- axeAttack sequence

void () zombie_attack1 = [$attack1, zombie_attack2]
{
    sound (self, CHAN_VOICE, "axezombie/azomswip.wav", 1, ATTN_NORM);
    ai_face ();
};

void () zombie_attack2 = [$attack2, zombie_attack3] {ai_face ();};
void () zombie_attack3 = [$attack3, zombie_attack4] {ai_face ();};
void () zombie_attack4 = [$attack4, zombie_attack5] {ai_face ();};
void () zombie_attack5 = [$attack5, zombie_attack6] {ai_face ();};
void () zombie_attack6 = [$attack6, zombie_attack7] {ai_face ();};
void () zombie_attack7 = [$attack7, zombie_attack8] {zombie_axeAttack(); ai_face ();};
void () zombie_attack8 = [$attack8, zombie_run] {ai_face ();};

//--- Decide when to axeAttack an enemy

void () zombie_attack =
{
    local vector delta;

    delta = (self.enemy.origin - self.origin);

    if (vlen (delta) <= 90)
        zombie_attack1 ();    // If the player is near axeAttack them

};


//--- Munch attack

void() zombie_axeAttack =
{
    local vector    delta;
    local float     ldmg;

    if (self.enemy.classname != "player") // To avoid hurting monster buddies on purpose
        return;

    ai_charge(10);

    if (!CanDamage (self.enemy, self))
        return;

    delta = self.enemy.origin - self.origin;

    if (vlen(delta) > 100)
        return;

    ldmg = (random() + random() + random()) * 8;

    SpawnBlood (self.origin, '0 0 0', ldmg);
       SpawnBloodSpray (trace_ent, self.origin);
       sound (self, CHAN_WEAPON, "weapons/pitchfrk/pflesh.wav", 1, ATTN_NORM);
    T_Damage (self.enemy, self, self, ldmg, DF_BODY, string_null);
};

//--- Moan and show pain

void () zombie_pain =
{

    local float r;

    // don't make multiple pain sounds right after each other
    if (self.pain_finished > time)
        return;

    r = random();

    if (r < 0.5)
        {sound (self, CHAN_VOICE, "axezombie/azompain.wav", 1, ATTN_NORM); self.pain_finished = (time + 1.17);}
    else
        {sound (self, CHAN_VOICE, "axezombie/azommoan.wav", 1, ATTN_NORM); self.pain_finished = (time + 1.48);}

//    zombie_pain1 (); // FIXME: Needs pain frames please luke 8)

};

// --- Death sequence

void () zombie_death1 = [$idle1, zombie_death1]
{
    monster_become_corpse();
};

void () zombie_die =
{
    monster_death();
	
    if (self.health < -40)
    {
        // Very large blood splat!
        te_bloodshower (self.origin, self.origin + self.size, 100, 100);

		sound (self, CHAN_VOICE, "axezombie/azomdie3.wav", 1, ATTN_NORM);
        RandomHumanGibs();
        remove (self);
        return;
    }

    if (random () < 0.5)
        sound (self, CHAN_VOICE, "axezombie/azomdie1.wav", 1, ATTN_NORM);
    else
        sound (self, CHAN_VOICE, "axezombie/azomdie2.wav", 1, ATTN_NORM);

    zombie_death1 ();    
};

//--- The spawn

void () monster_zombie =
{
    //  Disable for testing
    monster_check();

    precache_model ("models/enemies/zombie.md3");

    precache_sound ("axezombie/azomdie1.wav");
    precache_sound ("axezombie/azomdie2.wav");
    precache_sound ("axezombie/azomdie3.wav");
    precache_sound ("axezombie/azommoan.wav");
    precache_sound ("axezombie/azompain.wav");
    precache_sound ("axezombie/azomrise.wav");// ADDME - Need rising frames first
    precache_sound ("axezombie/azomroam.wav");
    precache_sound ("axezombie/azomspot.wav");
    precache_sound ("axezombie/azomstnd.wav");// ADDME - Need rising frames first
    precache_sound ("axezombie/azomswip.wav");


    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_TOSS;
    setmodel (self, "models/enemies/zombie.md3");
    setsize (self,'-5 -15 0', '11 15 62');
    self.health = 100;
    self.max_health = self.health;
    self.th_stand = zombie_stand;
    self.th_walk = zombie_walk;
    self.th_run = zombie_run;
    self.th_die = zombie_die;
    self.th_pain = zombie_pain;
    self.th_missile = zombie_attack;
	self.touch = monster_stepped_on;
    walkmonster_start ();
};
