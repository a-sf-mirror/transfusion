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

    Need to make run for 15 + rint(random()*5)

*/


#include "common.qh"


void () innocent_pain1;

$base base
$skin skin

$frame idle1 idle2 idle3
$frame run1 run2 run3 run4 run5 run6
$frame pain
$frame death1 death2 death3 death4 death5 death6 death7 death8
$frame pain1 // repeat
$frame sitting
$frame spread

void() innocent_stand1  =[      $idle1, innocent_stand2 ] { ai_stand();};
void() innocent_stand2  =[      $idle2, innocent_stand3 ] { ai_stand();};
void() innocent_stand3  =[      $idle3, innocent_stand1 ] { ai_stand();};

void() innocent_run1  =[      $run1, innocent_run2 ] {ai_run_away(12);};
void() innocent_run2  =[      $run2, innocent_run3 ] {ai_run_away(12);};
void() innocent_run3  =[      $run3, innocent_run4 ] {ai_run_away(12);};
void() innocent_run4  =[      $run4, innocent_run5 ] {ai_run_away(12);};
void() innocent_run5  =[      $run5, innocent_run6 ] {ai_run_away(12);};
void() innocent_run6  =[      $run6, innocent_run1 ] {ai_run_away(12);};


void() innocent_death1 =[      $death1,        innocent_death2        ]
{
    // FIXME: Need gibs here

    local float     r;

    r = random();

    if (r <= 0.125)
        sound (self, CHAN_VOICE, "innocent/icrying.wav", 1, ATTN_NORM);
    else if (r <= 0.25)
        sound (self, CHAN_VOICE, "innocent/icrying2.wav", 1, ATTN_NORM);
    else if (r <= 0.375)
        sound (self, CHAN_VOICE, "innocent/idonhme.wav", 1, ATTN_NORM);
    else if (r <= 0.5)
        sound (self, CHAN_VOICE, "innocent/igoaway2.wav", 1, ATTN_NORM);
    else if (r <= 0.625)
        sound (self, CHAN_VOICE, "innocent/igoaway3.wav", 1, ATTN_NORM);
    else if (r <= 0.75)
        sound (self, CHAN_VOICE, "innocent/inoplace.wav", 1, ATTN_NORM);
    else if (r <= 0.875)
        sound (self, CHAN_VOICE, "innocent/iplease.wav", 1, ATTN_NORM);
    else
        sound (self, CHAN_VOICE, "innocent/sobbing.wav", 1, ATTN_NORM);
};

void() innocent_death2 =[      $death2,        innocent_death3        ] {};
void() innocent_death3 =[      $death3,        innocent_death4        ] {};
void() innocent_death4 =[      $death4,        innocent_death5        ] {};
void() innocent_death5 =[      $death5,        innocent_death6        ] {};
void() innocent_death6 =[      $death6,        innocent_death7        ] {};
void() innocent_death7 =[      $death7,        innocent_death8        ] {};
void() innocent_death8 =[      $death8,        innocent_death8        ]
{
    self.solid = SOLID_NOT;     // In the last frame, remove self 15 seconds after death
    self.nextthink = time + 15;
    self.think = SUB_Remove;
};


void(entity attacker, float damage)    innocent_pain =
{
    local float     r;

// don't make multiple pain sounds right after each other
    if (self.pain_finished > time)
        return;

    r = random();

    if (r <= 0.5)
        sound (self, CHAN_VOICE, "innocent/iscream1.wav", 1, ATTN_NORM);
    else
        sound (self, CHAN_VOICE, "innocent/iscream2.wav", 1, ATTN_NORM);

    r = random();
    if (r >= 0.5)
    {

    r = random();

    if (r <= 0.125)
        {
        sound (self, CHAN_VOICE, "innocent/icrying.wav", 1, ATTN_NORM);
        self.pain_finished = time + 1.82;
        }
    else if (r <= 0.25)
        {
        sound (self, CHAN_VOICE, "innocent/icrying2.wav", 1, ATTN_NORM);
        self.pain_finished = time + 1.46;
        }
    else if (r <= 0.375)
        {
        sound (self, CHAN_VOICE, "innocent/idonhme.wav", 1, ATTN_NORM);
        self.pain_finished = time + 0.63;
        }
    else if (r <= 0.5)
        {
        sound (self, CHAN_VOICE, "innocent/igoaway2.wav", 1, ATTN_NORM);
        self.pain_finished = time + 1.12;
        }
    else if (r <= 0.625)
        {
        sound (self, CHAN_VOICE, "innocent/igoaway3.wav", 1, ATTN_NORM);
        self.pain_finished = time + 1.23;
        }
    else if (r <= 0.75)
        {
        sound (self, CHAN_VOICE, "innocent/inoplace.wav", 1, ATTN_NORM);
        self.pain_finished = time + 1.1;
        }
    else if (r <= 0.875)
        {
        sound (self, CHAN_VOICE, "innocent/iplease.wav", 1, ATTN_NORM);
        self.pain_finished = time + 1.24;
        }
    else
        {
        sound (self, CHAN_VOICE, "innocent/sobbing.wav", 1, ATTN_NORM);
        self.pain_finished = time + 3.2;
        }
    }
    else
        self.pain_finished = time + 1;

    innocent_pain1();
};

void() innocent_pain1 =[ $pain, innocent_run1]{ai_pain(12);};

void() monster_innocent =
{
/*  Disabled for testing

    if (deathmatch)
    {
        remove(self);
        return;
    }
*/
    precache_model ("models/enemies/innocent.md3");

    precache_sound ("innocent/icrying.wav");
    precache_sound ("innocent/icrying2.wav");
    precache_sound ("innocent/idonhme.wav");
    precache_sound ("innocent/igoaway2.wav");
    precache_sound ("innocent/igoaway3.wav");
    precache_sound ("innocent/inoplace.wav"); // There's no place like home!
    precache_sound ("innocent/iplease.wav");
    precache_sound ("innocent/iscream1.wav"); // Pain
    precache_sound ("innocent/iscream2.wav"); // Pain
    precache_sound ("innocent/sobbing.wav");

    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_STEP;

    setmodel (self, "models/enemies/innocent.md3");

    setsize (self, '-6 -14 0', '15 10 55');  // Need real values
    self.health = 25;
    self.max_health = self.health;
    self.th_stand = innocent_stand1;
    self.th_run = innocent_run1;
    self.th_die = innocent_death1;
    self.th_pain = innocent_pain;
    self.oldorigin = self.origin;

    walkmonster_start ();
};