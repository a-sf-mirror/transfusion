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
    
    Need more frames ??? (Luke)
  
*/


#include "common.qh"


$base base        
$skin skin

// idle

$frame idle1

// run

$frame run1 run2 run3 run4

//attack1

$frame attack1 attack2


// Prototypes
void () rat_stand1;
void () rat_bite;

void (float dist) rat_ai =
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

void () rat_walk1 = [$run1, rat_walk2] {rat_ai (3);};
void () rat_walk2 = [$run2, rat_walk3] {rat_ai (3);};
void () rat_walk3 = [$run3, rat_walk4] {rat_ai (3);};
void () rat_walk4 = [$run4, rat_walk1] {rat_ai (3);};


// FIXME: Unless more frames get added to the rat, we don't need two stand functions
void () rat_stand = 
{
    if (random () < 0.05)
        sound (self, CHAN_VOICE, "rat/ratroam.wav", 1, ATTN_IDLE);
        
    self.style = 1;
    rat_stand1();    
};

// idle
void () rat_stand1 = [$idle1, rat_stand1] {ai_stand();};

void () rat_walk =
{
    self.style = 2;
    rat_walk1 ();
};

void () rat_run =
{
    self.style = 3;
    rat_walk1 ();
};

// --- Bite sequence
 
void () rat_attack1 = [$attack1, rat_attack2] {rat_bite();ai_face ();};
void () rat_attack2 = [$attack2, rat_run] {ai_face ();};

//--- Decide when to bite an enemy

void () rat_attack =
{
    local vector delta;

    if (self.attack_finished > time)    // To avoid constant player chomping
        return;

    delta = (self.enemy.origin - self.origin);

    if (vlen (delta) <= 90)      
        rat_attack1 ();    // If the player is near bite them
    
};


//--- Munch attack

void() rat_bite =
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
    T_Damage (self.enemy, self, self, ldmg, DF_BODY, string_null);
        
    sound (self, CHAN_VOICE, "hellhound/houndbit.wav", 1, ATTN_NORM);  //FIXME: Verify this is correct biting sound
    
    self.attack_finished = time + 1;
    
};

//--- Show pain

void () rat_pain =
{    
    // don't make multiple pain sounds right after each other
    if (self.pain_finished > time)
        return;            
    
        sound (self, CHAN_VOICE, "rat/ratpain.wav", 1, ATTN_NORM);
                
//    rat_pain1 (); // FIXME: No pain sequence for now
    self.pain_finished = (time + 1); // is really 0.33 seconds long, but that really sounds crappy
};

// --- Death sequence

void () rat_death1 = [$idle1, rat_death1]
{
    // In the last frame, remove self 15 seconds after death
    self.nextthink = time + 15;self.think = SUB_Remove;

};

void () rat_die =
{
    self.effects = 0;
    if (self.health < -40) 
    {
        sound (self, CHAN_VOICE, "rat/ratdie3.wav", 1, ATTN_NORM);

        // FIXME: Throw really small gib or just make a big blood splat
        
        remove (self);
        return;
    }

    if (random () < 0.5)
        sound (self, CHAN_VOICE, "rat/ratdie1.wav", 1, ATTN_NORM);
    else
        sound (self, CHAN_VOICE, "rat/ratdie2.wav", 1, ATTN_NORM);
    
    rat_death1 ();
    self.solid = SOLID_NOT;
};

//--- The spawn

void () monster_rat =
{
// Disable for testing the model

    if (deathmatch)
    {
        remove (self);
        return ;
    }

    precache_model ("models/enemies/rat.md3");
    
    precache_sound ("rat/ratdie1.wav");
    precache_sound ("rat/ratdie2.wav");
    precache_sound ("rat/ratdie3.wav");
    precache_sound ("rat/ratpain.wav");
    precache_sound ("rat/ratroam.wav");
    precache_sound ("rat/ratspot.wav");
    precache_sound ("hellhound/houndbit.wav");
            
    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_STEP;
    setmodel (self, "models/enemies/rat.md3");
    setsize (self,'-13 -3 0', '13 3 6');     // FIXME: Need real coordinates
    self.health = 100;
    self.th_stand = rat_stand;
    self.th_walk = rat_walk;
    self.th_run = rat_run;
    self.th_die = rat_die;
    self.th_pain = rat_pain;
    self.th_missile = rat_attack;
    self.touch = monster_stepped_on;
    self.attack_finished = 0;
    walkmonster_start ();
};
