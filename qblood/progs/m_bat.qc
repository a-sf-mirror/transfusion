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

     Fix movement - If within certain radius, dive at players head. Buzz around player
     droptofloor() should be done elsewhere

*/


#include "common.qh"


$frame sleep

$frame wake1 wake2 wake3

$frame fly1 fly2 fly3 fly4 fly5 fly6 fly7


void() flymonster_start;
void() bat_wake1;
void() bat_idle;
void() bat_run;
void() bat_stand1;
void() bat_run1;

void() bat_idle =
{
    if (self.frame == $sleep && !self.enemy)    // If he's sleeping and nothing is nearby
       {
          ai_stand();             // Sleep lightly
          self.think = bat_idle;
          self.nextthink = time + 0.1;
       }
    else if (self.frame == $sleep)    // If he's sleeping
          bat_wake1();                   // Wake his ass up
    else
          bat_stand1();
};

void() bat_run =
{
    bat_run1();
};

void() bat_wake1  =[$wake1, bat_wake2 ] {};
void() bat_wake2  =[$wake2, bat_wake3 ] {};
void() bat_wake3  =[$wake3, bat_run1 ] {ai_face();};

void() bat_stand1  =[$fly1, bat_stand2 ]
{
    if (random() < 0.05)
        sound (self, CHAN_VOICE, "bat/batroam.wav", 1, ATTN_NORM);

    ai_stand();
};

void() bat_stand2  =[$fly2, bat_stand3 ] {ai_stand();};
void() bat_stand3  =[$fly3, bat_stand4 ] {ai_stand();};
void() bat_stand4  =[$fly4, bat_stand5 ] {ai_stand();};
void() bat_stand5  =[$fly5, bat_stand6 ] {ai_stand();};
void() bat_stand6  =[$fly6, bat_stand7 ] {ai_stand();};
void() bat_stand7  =[$fly7, bat_idle ] {ai_stand();};

void() bat_walk1  =[$fly1, bat_walk2 ] {ai_walk(8);};
void() bat_walk2  =[$fly2, bat_walk3 ] {ai_walk(8);};
void() bat_walk3  =[$fly3, bat_walk4 ] {ai_walk(8);};
void() bat_walk4  =[$fly4, bat_walk5 ] {ai_walk(8);};
void() bat_walk5  =[$fly5, bat_walk6 ] {ai_walk(8);};
void() bat_walk6  =[$fly6, bat_walk7 ] {ai_walk(8);};
void() bat_walk7  =[$fly7, bat_walk1 ] {ai_walk(8);};

void() bat_run1  =[$fly1, bat_run2 ] {ai_run(12);ai_face();};
void() bat_run2  =[$fly2, bat_run3 ] {ai_run(12);ai_face();};
void() bat_run3  =[$fly3, bat_run4 ] {ai_run(12);ai_face();};
void() bat_run4  =[$fly4, bat_run5 ] {ai_run(12);ai_face();};
void() bat_run5  =[$fly5, bat_run6 ] {ai_run(12);ai_face();};
void() bat_run6  =[$fly6, bat_run7 ] {ai_run(12);ai_face();};
void() bat_run7  =[$fly7, bat_run1 ] {ai_run(12);ai_charge(10);ai_face();};

void() bat_death1 =[$fly1, bat_death1]
{
    local float     r;

    droptofloor(); // FIXME: This is getting missed in killed()

    r = random();

    if (r <= 0.25)
        sound (self, CHAN_VOICE, "bat/batdie1.wav", 1, ATTN_NORM);
    else if (r <= 0.50)
        sound (self, CHAN_VOICE, "bat/batdie2.wav", 1, ATTN_NORM);
    else if (r <= 0.75)
        sound (self, CHAN_VOICE, "bat/batdie3.wav", 1, ATTN_NORM);
    else
        sound (self, CHAN_VOICE, "bat/bat.wav", 1, ATTN_NORM);

    self.solid = SOLID_NOT;     // In the last frame, remove self 15 seconds after death
    self.nextthink = time + 15;
    self.think = SUB_Remove;
};


void(entity attacker, float damage)    bat_pain =
{

// don't make multiple pain sounds right after each other
    if (self.pain_finished > time)
        return;

    sound (self, CHAN_VOICE, "bat/batpain.wav", 1, ATTN_NORM);
    self.pain_finished = time + 0.52;
    ai_pain(6);
};

void() monster_bat =
{
/*  Disabled for testing

    if (deathmatch)
    {
        remove(self);
        return;
    }
*/
    precache_model ("models/enemies/bat.md3");

    precache_sound ("bat/batdie1.wav");
    precache_sound ("bat/batdie2.wav");
    precache_sound ("bat/batdie3.wav");
    precache_sound ("bat/batpain.wav");
    precache_sound ("bat/batroam.wav");
    precache_sound ("bat/batspot.wav");
    precache_sound ("bat/bat.wav");

    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_FLY;

    setmodel (self, "models/enemies/bat.md3");

    setsize (self, '-4 -4 -5', '5 3 7');
    self.health = 25;
    self.max_health = self.health;
    self.th_stand = bat_idle;
    self.th_walk = bat_walk1;
    self.th_run = bat_run;
    self.th_die = bat_death1;
    self.th_pain = bat_pain;

    flymonster_start ();
};