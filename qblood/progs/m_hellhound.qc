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
    
    flame looks like it's coming out of neck, needs to come from mouth
    head - Kick hell hounds head around!
    need to get real health and damage values
    immunity to fire attacks - in T_Damage - combat.qc
    instant death by water    
*/


#include "common.qh"


$base base        
$skin skin

// idle

$frame idle1 idle2 idle3 idle4 idle5 idle6 idle7 idle8 idle9 idle10 idle11 idle12

// run

$frame run1 run2 run3 run4 run5 run6
$frame run7 run8 run9 run10 run11 run12

//attack1

$frame attacka1 attacka2 attacka3 attacka4 attacka5 attacka6

//attack2

$frame attackb1 attackb2 attackb3

//pain

$frame pain1 pain2 pain3

//death

$frame death1 death2 death3 death4 death5 death6 death7 death8


// Prototypes
void () hellhound_stand1;
void () hellhound_bite;
void () hellhound_breath;
void() hellhound_flameSpawn;

void (float dist) hellhound_ai =
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

void () hellhound_walk1 = [$run1, hellhound_walk2] {hellhound_ai (10);};
void () hellhound_walk2 = [$run2, hellhound_walk3] {hellhound_ai (10);};
void () hellhound_walk3 = [$run3, hellhound_walk4] {hellhound_ai (10);};
void () hellhound_walk4 = [$run4, hellhound_walk5] {hellhound_ai (10);};
void () hellhound_walk5 = [$run5, hellhound_walk6] {hellhound_ai (10);};
void () hellhound_walk6 = [$run6, hellhound_walk7] {hellhound_ai (10);};
void () hellhound_walk7 = [$run7, hellhound_walk8] {hellhound_ai (10);};
void () hellhound_walk8 = [$run8, hellhound_walk9] {hellhound_ai (10);};
void () hellhound_walk9 = [$run9, hellhound_walk10] {hellhound_ai (10);};
void () hellhound_walk10 = [$run10, hellhound_walk11] {hellhound_ai (10);};
void () hellhound_walk11 = [$run11, hellhound_walk12] {hellhound_ai (10);};
void () hellhound_walk12 = [$run12, hellhound_walk1] {hellhound_ai (10);};


void () hellhound_stand = 
{
    if (random () < 0.05)
        sound (self, CHAN_VOICE, "hellhound/smalwoof.wav", 1, ATTN_IDLE);
        
    self.style = 1;
    hellhound_stand1();    
};

// idle
void () hellhound_stand1 = [$idle1, hellhound_stand2] {ai_stand();};
void () hellhound_stand2 = [$idle2, hellhound_stand3] {ai_stand();};
void () hellhound_stand3 = [$idle3, hellhound_stand4] {ai_stand();};
void () hellhound_stand4 = [$idle4, hellhound_stand5] {ai_stand();};
void () hellhound_stand5 = [$idle5, hellhound_stand6] {ai_stand();};
void () hellhound_stand6 = [$idle6, hellhound_stand7] {ai_stand();};
void () hellhound_stand7 = [$idle7, hellhound_stand8] {ai_stand();};
void () hellhound_stand8 = [$idle8, hellhound_stand9] {ai_stand();};
void () hellhound_stand9 = [$idle9, hellhound_stand10] {ai_stand();};
void () hellhound_stand10 = [$idle10, hellhound_stand11] {ai_stand();};
void () hellhound_stand11 = [$idle11, hellhound_stand12] {ai_stand();};
void () hellhound_stand12 = [$idle12, hellhound_stand] {};


void () hellhound_walk =
{
    self.style = 2;
    hellhound_walk1 ();
};

void () hellhound_run =
{
    self.style = 3;
    hellhound_walk1 ();
};

// --- Bite sequence
 
void () hellhound_attacka1 = [$attacka1, hellhound_attacka2] {ai_face ();};
void () hellhound_attacka2 = [$attacka2, hellhound_attacka3] {ai_face ();};
void () hellhound_attacka3 = [$attacka3, hellhound_attacka4] {ai_face ();};
void () hellhound_attacka4 = [$attacka4, hellhound_attacka5] {ai_face ();};
void () hellhound_attacka5 = [$attacka5, hellhound_attacka6] {hellhound_bite(); ai_face ();};
void () hellhound_attacka6 = [$attacka6, hellhound_run] {ai_face ();};

//--- Flame sequence

void () hellhound_attackb1 = [$attackb1, hellhound_attackb2] {ai_face ();};
void () hellhound_attackb2 = [$attackb2, hellhound_attackb3] 
{
    self.attack_finished = time + 2;
    hellhound_breath(); 
    ai_face ();
};
void () hellhound_attackb3 = [$attackb3, hellhound_run] {ai_face ();};

//--- Decide whether to flame or bite an enemy

void () hellhound_attack =
{
    local vector delta;

    delta = (self.enemy.origin - self.origin);

    if (vlen (delta) <= 90)      
        hellhound_attacka1 ();    // If the player is near bite them
    else if (vlen (delta) <= 340)
        hellhound_attackb1 ();    // Otherwise flame them when in range
    else
        return;
};

//--- Flaming breath attack

void() hellhound_breath =
{
    local float     dist;    
        
    dist = vlen(self.enemy.origin - self.origin);        // Get distance from player
    
    if ((self.attack_finished > time) && (dist <=340))  // 340 is approximate max distance of flame
    {
        ai_face();                        // Face player
        hellhound_flameSpawn();            // Spawn a flame missile
    }
    else
    {
        self.think = hellhound_run;     // Turn basic "I have an enemy" AI back on
        self.nextthink = time + 0.1;    // Turn that AI back on in 1/10 of a second
    }
    
};

//--- Launches the flame sprite at player

void() hellhound_flameSpawn =
{
    local vector    dir;    

    makevectors (self.v_angle);    

    dir = (self.enemy.origin - self.origin);
    dir = normalize (dir);

    newmis = spawn ();
    newmis.owner = self;
    newmis.movetype = MOVETYPE_FLYMISSILE;
    newmis.solid = SOLID_BBOX;
    newmis.alpha = 0.6;
    newmis.effects = EF_ADDITIVE;

    newmis.angles = vectoangles(dir);

    newmis.touch = flame_touch;
    newmis.classname = "spike";
    newmis.reset = SUB_Remove;
    newmis.think = SUB_Remove;
    newmis.nextthink = time + 0.6;
    setmodel (newmis, "progs/sprayfir.spr");
    setsize (newmis, '-1 -1 -1', '1 1 1');
    setorigin (newmis, self.origin + '0 -35 10');

    newmis.velocity = dir * 550;

    newmis.frame = floor (random () * 3);
    
    self.think = hellhound_breath;
    self.nextthink = time + 0.1;        
};



//--- Munch attack

void() hellhound_bite =
{
    local vector    delta;
    local float     ldmg;
    local float     r;

    if (self.enemy.classname != "player") // To avoid hurting monster buddies
        return;

    ai_charge(10);

    if (!CanDamage (self.enemy, self))
        return;

    delta = self.enemy.origin - self.origin;

    if (vlen(delta) > 100)
        return;
        
    ldmg = (random() + random() + random()) * 8;
    T_Damage (self.enemy, self, self, ldmg, DF_BODY, string_null);
    
    r = random ();
    
    if (r < 0.33)
        sound (self, CHAN_VOICE, "hellhound/houndbit.wav", 1, ATTN_NORM);
    else if (r < 0.66)
        sound (self, CHAN_VOICE, "hellhound/houndbt2.wav", 1, ATTN_NORM); // Does this sound work?
    else
        sound (self, CHAN_VOICE, "hellhound/houndbt3.wav", 1, ATTN_NORM); // Does this sound work?
    
};

//--- Pain sequence

void () hellhound_pain1 = [$pain1, hellhound_pain2] {};
void () hellhound_pain2 = [$pain2, hellhound_pain3] {};
void () hellhound_pain3 = [$pain3, hellhound_run] {}; 

//--- Wimper and show pain

void () hellhound_pain =
{    
    if (self.pain_finished > time)
        return;
            
    if (random () < 0.5)
        {sound (self, CHAN_VOICE, "hellhound/cerbpain.wav", 1, ATTN_NORM);    self.pain_finished = (time + 0.87);}
    else
        {sound (self, CHAN_VOICE, "hellhound/smalpain.wav", 1, ATTN_NORM);    self.pain_finished = (time + 1.26);}
                
    hellhound_pain1 ();

};

// --- Death sequence

void () hellhound_death1 = [$death1, hellhound_death2] {};
void () hellhound_death2 = [$death2, hellhound_death3] {};
void () hellhound_death3 = [$death3, hellhound_death4] {};
void () hellhound_death4 = [$death4, hellhound_death5] {};
void () hellhound_death5 = [$death5, hellhound_death6] {};
void () hellhound_death6 = [$death6, hellhound_death7] {};
void () hellhound_death7 = [$death7, hellhound_death8] {};
void () hellhound_death8 = [$death8, hellhound_death8] 
{
    // In the last frame, remove self 15 seconds after death
    self.nextthink = time + 15;
    self.think = SUB_Remove;
};

void () hellhound_die =
{
    self.effects = 0;
    if (self.health < -40)
    {
        sound (self, CHAN_VOICE, "hellhound/cerbdie3.wav", 1, ATTN_NORM);

        // ThrowHead (self.health);  // FIXME: At some point need to drop hellhound head, and it be kickable
        ThrowGib ("progs/gib1.mdl", self.health);
        ThrowGib ("progs/gib1a.mdl", self.health);
        ThrowGib ("progs/gib2.mdl", self.health);
        ThrowGib ("progs/gib2a.mdl", self.health);
        ThrowGib ("progs/gib3.mdl", self.health);
        ThrowGib ("progs/gib3a.mdl", self.health);
        remove (self);
        return;
    }

    if (random () < 0.5)
        sound (self, CHAN_VOICE, "hellhound/cerbdie1.wav", 1, ATTN_NORM);
    else
        sound (self, CHAN_VOICE, "hellhound/cerbdie2.wav", 1, ATTN_NORM);
    
    hellhound_death1 ();
    self.solid = SOLID_NOT;
};

//--- The spawn

void () monster_hellhound =
{
// Disable for testing the model

    if (deathmatch)
    {
        remove (self);
        return ;
    }

    precache_model ("models/enemies/hellhound.md3");
    precache_model ("progs/gib1.mdl");
    precache_model ("progs/gib1a.mdl");
    precache_model ("progs/gib2.mdl");
    precache_model ("progs/gib2a.mdl");
    precache_model ("progs/gib3.mdl");
    precache_model ("progs/gib3a.mdl");
    precache_model ("progs/sprayfir.spr");    

    precache_sound ("hellhound/cerbdie1.wav");
    precache_sound ("hellhound/cerbdie2.wav");
    precache_sound ("hellhound/cerbdie3.wav");
    precache_sound ("hellhound/cerbpain.wav");
    precache_sound ("hellhound/cerbspot.wav");
    precache_sound ("hellhound/houndbit.wav");
    precache_sound ("hellhound/houndbt2.wav");
    precache_sound ("hellhound/houndbt3.wav");
    precache_sound ("hellhound/smalpain.wav");
    precache_sound ("hellhound/smalwoof.wav");
            
    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_STEP;
    setmodel (self, "models/enemies/hellhound.md3");
    setsize (self,'-39 -17 0', '38 17 35');
    self.health = 100;
    self.th_stand = hellhound_stand;
    self.th_walk = hellhound_walk;
    self.th_run = hellhound_run;
    self.th_die = hellhound_die;
    self.th_pain = hellhound_pain;
    self.th_missile = hellhound_attack;
    walkmonster_start ();
};
