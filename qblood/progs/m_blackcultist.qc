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
            
    fire until player is dead or unreachable
    jump back hack implemented. real fix???
    need more than one frame - luke
    need to get real health and damage values
    head - make use of cultist head with ThrowHead().  Kick cultist head around!    
    Need real lengths for the tommy cultist specific pain sounds
*/


#include "common.qh"


$base base        
$skin skin

// idle

$frame idle1


// Prototypes

void () blackcultist_stand1;
void () blackcultist_fireTommygun;

void (float dist) blackcultist_ai =
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

void () blackcultist_walk1 = [$idle1, blackcultist_walk1] {blackcultist_ai (3);};

//--- Decide what to say
void () blackcultist_stand = 
{
    cultist_stand();
    blackcultist_stand1();    
};

//--- Basic idle

void () blackcultist_stand1 = [$idle1, blackcultist_stand1] {ai_stand();};

void () blackcultist_walk =
{
    self.style = 2;
    blackcultist_walk1 ();
};

void () blackcultist_run =
{
    self.style = 3;
    blackcultist_walk1 ();
};

//--- Shooting gun
 
void () blackcultist_attacka1 = [$idle1, blackcultist_attacka2] {blackcultist_fireTommygun (); ai_face ();};
void () blackcultist_attacka2 = [$idle1, blackcultist_run] {ai_face ();};

void () blackcultist_attack =
{
    local vector delta;
    
    cultist_attack();

    delta = (self.enemy.origin - self.origin);

    if (vlen (delta) <= 1200)      
        blackcultist_attacka1 ();    // If the player is near shoot them    
};

//--- Shoot the player

void () blackcultist_fireTommygun =
{    
    local vector    dir;
    local entity    old;
    local vector    orig;    
    local vector    spread;
    local float     damage;
    
    makevectors (self.v_angle);
    
    self.effects = self.effects | EF_MUZZLEFLASH;

    sound (self, CHAN_WEAPON, "weapons/tommygun/_tom.wav", 1, ATTN_NORM);
    self.attack_finished = time + 0.1;

    // set the bullet direction according to the weapon real direction
    dir = (self.enemy.origin - self.origin);
    dir = normalize (dir);
 
    orig = self.origin + v_forward * 15 + v_up * 12 + v_right * 4;
 
    // Spawn 1 shell every 2 shots
    // Tommy_SpawnShell (orig); // FIXME: Disabled until mdl issue is fixed

    FireBullets (self.origin, dir, 1, 12, '0.1 0.1 0');
 
    self.punchangle_x = -2;    
};


void () blackcultist_pain =
{
    local float r;

    // don't make multiple pain sounds right after each other
    if (self.pain_finished > time)
        return;
        
    r = random();    
    
    if (self.deathtype == "fire")
    {
        if (r < 0.33)
            {sound (self,2,"cultist/cultfir1.wav",1,1); self.pain_finished = (time + 3.2);}
        else if (r < 0.66)
            {sound (self,2,"cultist/cultfir2.wav",1,1);    self.pain_finished = (time + 4.62);}
        else 
            {sound (self,2,"cultist/cultfir3.wav",1,1);    self.pain_finished = (time + 3.62);}
    }
        
    else if (r < 0.25)
        {sound (self,2,"cultist/cultpan1.wav",1,1);    self.pain_finished = (time + 0.38);}
    else if (r < 0.5)
        {sound (self,2,"cultist/tcltpan2.wav",1,1);    self.pain_finished = (time + 0.35);}  // FIXME: Need real length
    else if (r < 0.75)
        {sound (self,2,"cultist/tcltpan3.wav",1,1);    self.pain_finished = (time + 0.4);}   // FIXME: Need real length
    else
        {sound (self,2,"cultist/cultpan4.wav",1,1);    self.pain_finished = (time + 0.29);}    
    
//    blackcultist_pain1 (); // FIXME: Need pain frames - luke
    
};

//--- Death sequence

void () blackcultist_death1 = [$idle1, blackcultist_death1]
{
    // In the last frame, remove self 15 seconds after death
    self.nextthink = time + 15;
    self.think = SUB_Remove;
};

void () blackcultist_die =
{
    self.effects = 0;
    if (self.health < -40)
    {
        sound (self, CHAN_VOICE, "cultist/cultdie3.wav", 1, ATTN_NORM);

        // ThrowHead (self.health);  // FIXME: At some point need to drop blackcultist head, and it be kickable
        RandomHumanGibs ();
        remove (self);
        return;
    }
    
    if (random () < 0.5)
        sound (self, CHAN_VOICE, "cultist/tcltdie1.wav", 1, ATTN_NORM);
    else
        sound (self, CHAN_VOICE, "cultist/cultdie2.wav", 1, ATTN_NORM);
    
    blackcultist_death1 ();
    self.solid = SOLID_NOT;

};

void () monster_blackcultist =
{
// Disable for testing the model

    if (deathmatch)
    {
        remove (self);
        return ;
    }

    precache_model ("models/enemies/cultist-gray.md3");
        
    precache_sound ("weapons/tommygun/_tom.wav");
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
    precache_sound ("cultist/cultpan4.wav");
    precache_sound ("cultist/cultspt1.wav");
    precache_sound ("cultist/cultspt2.wav");
    precache_sound ("cultist/cultspt3.wav");
    precache_sound ("cultist/cultspt4.wav");
    precache_sound ("cultist/cultspt5.wav");
    precache_sound ("cultist/tcltdie1.wav");
    precache_sound ("cultist/tcltpan2.wav");
    precache_sound ("cultist/tcltpan3.wav");

    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_STEP;
    setmodel (self, "models/enemies/cultist-gray.md3");
    setsize (self,'-6 -14 0', '34 14 62');
    self.health = 200;
    self.th_stand = blackcultist_stand;
    self.th_walk = blackcultist_walk;
    self.th_run = blackcultist_run;
    self.th_die = blackcultist_die;
    self.th_pain = blackcultist_pain;
    self.th_missile = blackcultist_attack;
    self.attack_state = AS_MISSILE;
    walkmonster_start ();
};
