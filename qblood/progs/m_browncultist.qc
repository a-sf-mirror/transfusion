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
    Too many sounds at once - I need the sound lengths.  Set attackfinished to end when taunt sound ends
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

void () browncultist_stand1;
void () browncultist_attackDecide;
void () browncultist_fireShotgun;


void (float dist) browncultist_ai =
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
void () browncultist_walk1 = [$idle1, browncultist_walk1] {browncultist_ai (3);};


//--- Decide what to say
void () browncultist_stand = 
{
    cultist_stand();
    
    // FIXME: Whenever the model is finished I can probably redo this
    browncultist_stand1();    
};

//--- Basic idle
void () browncultist_stand1 = [$idle1, browncultist_stand1] {ai_stand();};


void () browncultist_walk =
{
    self.style = 2;
    browncultist_walk1 ();
};

void () browncultist_run =
{
    self.style = 3;
    browncultist_walk1 ();
};

//--- Shooting gun
 
void () browncultist_attacka1 = [$idle1, browncultist_attacka2] {browncultist_fireShotgun (); ai_face (); ai_run_slide();};
void () browncultist_attacka2 = [$idle1, browncultist_run] {ai_face (); ai_run_slide();};

//--- Throwing TNT 

void () browncultist_attackb1 = [$idle1, browncultist_attackb2] {cultist_throw_TNT (); ai_face (); ai_run_slide();};
void () browncultist_attackb2 = [$idle1, browncultist_run] {ai_face (); ai_run_slide();};


void () browncultist_attack =
{
    if (!infront(self.enemy)) // If there's something blocking the shot
        return;
        
    cultist_attack(); // Talk some smack!
    
    browncultist_attackDecide();    
};

void () browncultist_attackDecide =
{
    if (self.attack_finished > time)
    {
        ai_face();                        // Face player
        
        if (range(self.enemy) == RANGE_NEAR) // If the player is near shoot them
            browncultist_attacka1 ();    
        else
            browncultist_attackb1 ();    // Otherwise TNT them    
    }
    else
    {
        self.think = browncultist_run;     // Turn basic "I have an enemy" AI back on
        self.nextthink = time + 0.1;    // Turn that AI back on in 1/10 of a second
    }

};

//--- Shoot the player

void () browncultist_fireShotgun =
{
    ai_face();
    cultist_fireShotgun();
    self.think = browncultist_attackDecide;
    self.nextthink = time + 0.5;
};

void () browncultist_pain =
{
    cultist_pain();
    
//    browncultist_pain1 (); // FIXME: Need pain frames - luke
    
    if (self.deathtype != "fire") // FIXME: This is here until I can spread it through pain frames
        ai_pain(15);
};

//--- Death sequence

void () browncultist_death1 = [$idle1, browncultist_death1]
{
    // In the last frame, remove self 15 seconds after death
    self.nextthink = time + 15;
    self.think = SUB_Remove;
};

void () browncultist_die =
{
    cultist_die();
    browncultist_death1 ();
};

void () monster_browncultist =
{
// Disable for testing the model

    if (deathmatch)
    {
        remove (self);
        return ;
    }

    precache_model ("models/enemies/cultist-brown.md3");
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
    precache_sound ("cultist/culttoss.wav");
    precache_sound ("weapons/r_exp3.wav");    // TNT explosion sound
    
    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_STEP;
    setmodel (self, "models/enemies/cultist-brown.md3");
    setsize (self,'-6 -14 0', '34 14 62');
    self.health = 200;
    self.th_stand = browncultist_stand;
    self.th_walk = browncultist_walk;
    self.th_run = browncultist_run;
    self.th_die = browncultist_die;
    self.th_pain = browncultist_pain;
    self.th_missile = browncultist_attack;
    walkmonster_start ();
};
