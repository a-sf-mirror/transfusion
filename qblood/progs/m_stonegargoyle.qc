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


$base base
$skin skin

// idle

$frame idle1

// Prototypes

void () stonegargoyle_stand1;
void (vector misorig) stonegargoyle_eye_shot;
//void () stonegargoyle_eye_shot_touch;       // When struck by eye projectiles
void () stonegargoyle_claw;

//--- Walking around

void () stonegargoyle_walk1 = [$idle1, stonegargoyle_walk1]
{
    local float dist;

    dist = vlen(self.enemy.origin - self.origin);

    if (dist < 300)
        basic_ai (10);
    else
        basic_ai (2);
};


//--- Decide which idle to do

void () stonegargoyle_stand =
{
    if (random () < 0.05)
    sound (self, CHAN_WEAPON, "stonegargoyle/sargroam.wav", 1, ATTN_NORM);

    stonegargoyle_stand1();
};

void () stonegargoyle_stand1 = [$idle1, stonegargoyle_stand] {ai_stand();};

void () stonegargoyle_walk =
{
    self.style = 2;
    stonegargoyle_walk1 ();
};

void () stonegargoyle_run =
{
    self.style = 3;
    stonegargoyle_walk1 ();
};

//--- Eye "zap"
void () stonegargoyle_attacka1 = [$idle1, stonegargoyle_run]
{
    stonegargoyle_eye_shot ('5 -32 64');
    stonegargoyle_eye_shot ('20 -32 64');
    ai_face ();

};

//--- clawing
void () stonegargoyle_attackb1 = [$idle1, stonegargoyle_run] {gargoyle_claw(); ai_face ();};


void () stonegargoyle_attack =
{
    local float dist;

    dist = vlen(self.enemy.origin - self.origin);

    if (dist < 90)
        stonegargoyle_attackb1 ();
    else
    {
        self.nextthink = 0.1;
        self.think = stonegargoyle_attacka1;
    }
};

//--- Shoot from stone gargoyle's eyes

void (vector misorig) stonegargoyle_eye_shot =
{
    local vector vec;

    sound (self, CHAN_WEAPON, "stonegargoyle/sargblst.wav", 1, ATTN_NORM);
    muzzleflash ();

    newmis = spawn ();
    vec = (self.enemy.origin - self.origin);
    vec = normalize (vec);
    newmis.velocity = vec * 1500;
    newmis.owner = self;
    newmis.solid = SOLID_BBOX;
    newmis.classname = "missile";
	newmis.effects = newmis.effects | EF_DIMLIGHT;
    newmis.angles = vectoangles(newmis.velocity);
    newmis.movetype = MOVETYPE_FLYMISSILE;
    newmis.touch = Leech_BallTouch;
    setmodel (newmis, "progs/teslaball.spr");
    newmis.skin = 0;
    setsize (newmis, '0 0 0', '0 0 0');
    newmis.origin = self.origin + misorig;

    newmis.dmg = 40;

    // set newmis duration
    newmis.nextthink = time + 5;
    newmis.think = SUB_Remove;
    newmis.reset = SUB_Remove;
};

void () stonegargoyle_claw =
{
    local vector    delta;
    local float     ldmg;

    if (!self.enemy)
        return;        // removed before stroke

    delta = self.enemy.origin - self.origin;

    if (vlen(delta) > 90)
        return;

    ldmg = (random() + random()) * 3;
    T_Damage (self.enemy, self, self, ldmg, DF_STAB, string_null);

    SpawnBlood (self.origin, '0 0 0', ldmg);
    SpawnBloodSpray (trace_ent, self.origin);
    sound (self, CHAN_WEAPON, "gargoyle/gargclaw.wav", 1, ATTN_NORM);
};

void () stonegargoyle_pain =
{
    // don't make multiple pain sounds right after each other
    if (self.pain_finished > time)
        return;

    sound (self,2,"stonegargoyle/sargpain.wav",1,1);
//  stonegargoyle_pain1 ();  // FIXME: Need more than one frame for true pain
    self.pain_finished = (time + 1.14);
};

//--- Death sequence

void () stonegargoyle_death1 = [$idle1, stonegargoyle_death1]
{
    monster_become_corpse();
};

void () stonegargoyle_die =
{
    monster_death();
	droptofloor();
	
    if (self.health < -40)
    {
        // Very large blood splat!
        te_bloodshower (self.origin, self.origin + self.size, 100, 500);
		
		sound (self, CHAN_VOICE, "stonegargoyle/sargdie3.wav", 1, ATTN_NORM);
        remove (self);
        return;
    }    

    if (random () < 0.5)
        sound (self, CHAN_VOICE, "stonegargoyle/sargdie1.wav", 1, ATTN_NORM);
    else
        sound (self, CHAN_VOICE, "stonegargoyle/sargdie2.wav", 1, ATTN_NORM);

    stonegargoyle_death1 ();

};

void () monster_stonegargoyle =
{
    //  Disable for testing
    if(monster_check())
	    return;

    precache_model ("models/enemies/gargoyle.md3");
    precache_model ("progs/teslaball.spr");

    precache_sound ("stonegargoyle/sargblst.wav");
    precache_sound ("gargoyle/gargclaw.wav");
    precache_sound ("stonegargoyle/sargdie1.wav");
    precache_sound ("stonegargoyle/sargdie2.wav");
    precache_sound ("stonegargoyle/sargdie3.wav");
    precache_sound ("stonegargoyle/sargpain.wav");
    precache_sound ("stonegargoyle/sargroam.wav");
    precache_sound ("stonegargoyle/sargspot.wav");

    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_FLY;
    setmodel (self, "models/enemies/gargoyle.md3");
    self.scale = 2;
    
	// Original "flesh" gargoyle model size
	setsize (self,'-25 -31 0', '18 31 45');
    
	// Set up new "stone" gargoyle bbox based upon scale
	self.mins = self.mins * self.scale;
	self.maxs = self.maxs * self.scale;	
	setsize (self, self.mins, self.maxs);
	
	self.health = 200;
	self.resist_acid = 0;
	self.resist_shock = 0;
	self.resist_pummel = 0;
	self.resist_fall = 0;
	self.resist_burn = 0;
	self.resist_bullet = 0;
	self.resist_stab = 0;
	self.resist_explode = 0;
	self.resist_gas = 0;
	self.resist_drown = -1;	// cannot drown
	self.resist_spirit = 0;
	self.resist_voodoo = 0;
	
    self.max_health = self.health;
    self.th_stand = stonegargoyle_stand;
    self.th_walk = stonegargoyle_walk;
    self.th_run = stonegargoyle_run;
    self.th_die = stonegargoyle_die;
    self.th_pain = stonegargoyle_pain;
    self.th_missile = stonegargoyle_attack;
    flymonster_start ();
};

void () monster_graygargoyle =
{
    monster_stonegargoyle();    
};
