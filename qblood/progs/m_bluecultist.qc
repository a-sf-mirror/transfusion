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
    immunity to fire attacks - in T_Damage - combat.qc
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

void () bluecultist_stand1;
void () bluecultist_fireTesla;

void (float dist) bluecultist_ai =
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

void () bluecultist_walk1 = [$idle1, bluecultist_walk1] {bluecultist_ai (3);};

//--- Decide which idle to do

void () bluecultist_stand = 
{
    cultist_stand();
    
    // FIXME: Whenever the model is finished I can probably redo this
    bluecultist_stand1();    
};

//--- Basic idle

void () bluecultist_stand1 = [$idle1, bluecultist_stand1] {ai_stand();};

void () bluecultist_walk =
{
    self.style = 2;
    bluecultist_walk1 ();
};

void () bluecultist_run =
{
    self.style = 3;
    bluecultist_walk1 ();
};

//--- Shooting gun
 
void () bluecultist_attacka1 = [$idle1, bluecultist_attacka2] {bluecultist_fireTesla (); ai_face ();};
void () bluecultist_attacka2 = [$idle1, bluecultist_run] {ai_face ();};

void () bluecultist_attack =
{
    local vector delta;

    if (!infront(self.enemy)) // If there's something blocking the shot
        return;

    cultist_attack(); // Talk some smack!
    
    delta = (self.enemy.origin - self.origin);

    if (vlen (delta) <= 1200)      
        bluecultist_attacka1 ();    // If the player is near shoot them    
    
    if (vlen (delta) <= 100) // A jump back hack
        ai_back(100);
};

//--- Shoot the player

void () bluecultist_fireTesla =
{    
    local   vector  org;
    local   vector  dir;

    muzzleflash ();

    self.punchangle_x = -2;
    
    sound (self, CHAN_WEAPON, "weapons/tesla/tessngfr.wav", 1, ATTN_NORM);

    makevectors (self.v_angle);
    dir = (self.enemy.origin - self.origin);
    org = self.origin + v_forward * 8 + '0 0 16';
   
    Tesla_LaunchJolt (org, dir, 1500);    
};


void () bluecultist_pain =
{
    cultist_pain();    
    
//    bluecultist_pain1 (); // FIXME: Need pain frames - luke
    
};

//--- Death sequence

void () bluecultist_death1 = [$idle1, bluecultist_death1]
{
    // In the last frame, remove self 15 seconds after death
    self.nextthink = time + 15;
    self.think = SUB_Remove;
};

void () bluecultist_die =
{
    cultist_die();
    
    bluecultist_death1 ();
};

void () monster_bluecultist =
{
// Disable for testing the model

    if (deathmatch)
    {
        remove (self);
        return ;
    }

    precache_model ("models/enemies/cultist-blue.md3");
        
    precache_sound ("weapons/tesla/tessngfr.wav");
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
    
    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_STEP;
    setmodel (self, "models/enemies/cultist-blue.md3");
    setsize (self,'-6 -14 0', '34 14 62');
    self.health = 200;
    self.th_stand = bluecultist_stand;
    self.th_walk = bluecultist_walk;
    self.th_run = bluecultist_run;
    self.th_die = bluecultist_die;
    self.th_pain = bluecultist_pain;
    self.th_missile = bluecultist_attack;
    self.attack_state == AS_MISSILE;
    walkmonster_start ();
};
