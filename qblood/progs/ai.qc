/*  Copyright (C) 1996-1997  Id Software, Inc.

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


float movedist;

void() movetarget_f;
void() t_movetarget;

/*

.enemy
Will be world if not currently angry at anyone.

.movetarget
The next path spot to walk toward.  If .enemy, ignore .movetarget.
When an enemy is killed, the monster will try to return to it's path.

.huntt_ime
Set to time + something when the player is in sight, but movement straight for
him is blocked.  This causes the monster to use wall following code for
movement direction instead of sighting on the player.

.ideal_yaw
A yaw angle of the intended direction, which will be turned towards at up
to 45 deg / state.  If the enemy is in view and hunt_time is not active,
this will be the exact line towards the enemy.

.pausetime
A monster will leave it's stand state and head towards it's .movetarget when
time > .pausetime.

walkmove(angle, speed) primitive is all or nothing
*/


//
// globals
//
float   current_yaw;

//
// when a monster becomes angry at a player, that monster will be used
// as the sight target the next frame so that monsters near that one
// will wake up even if they wouldn't have noticed the player
//
entity  sight_entity;
float   sight_entity_time;

float(float v) anglemod =
{
    while (v >= 360)
        v = v - 360;
    while (v < 0)
        v = v + 360;
    return v;
};

/*
==============================================================================

MOVETARGET CODE

The angle of the movetarget effects standing and bowing direction, but has no effect on movement, which allways heads to the next target.

targetname
must be present.  The name of this movetarget.

target
the next spot to move to.  If not present, stop here for good.

pausetime
The number of seconds to spend standing or bowing for path_stand or path_bow

==============================================================================
*/


void() movetarget_f =
{
    if (!self.targetname)
        objerror ("monster_movetarget: no targetname");

    self.solid = SOLID_TRIGGER;
    self.touch = t_movetarget;
    setsize (self, '-8 -8 -8', '8 8 8');

};

/*QUAKED path_corner (0.5 0.3 0) (-8 -8 -8) (8 8 8)
Monsters will continue walking towards the next target corner.
*/
void() path_corner =
{
    movetarget_f ();
};


/*
=============
t_movetarget

Something has bumped into a movetarget.  If it is a monster
moving towards it, change the next destination and continue.
==============
*/
void() t_movetarget =
{
local entity    temp;

    if (other.movetarget != self)
        return;

    if (other.enemy)
        return;     // fighting, not following a path

    temp = self;
    self = other;
    other = temp;

    self.goalentity = self.movetarget = find (world, targetname, other.target);
    self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
    if (!self.movetarget)
    {
        self.pausetime = time + 999999;
        self.th_stand ();
        return;
    }
};



//============================================================================

/*
=============
range

returns the range catagorization of an entity reletive to self
0   melee range, will become hostile even if back is turned
1   visibility and infront, or visibility and show hostile
2   infront and show hostile
3   only triggered by damage
=============
*/
float(entity targ) range =
{
local vector    spot1, spot2;
local float     r;
    spot1 = self.origin + self.view_ofs;
    spot2 = targ.origin + targ.view_ofs;

    r = vlen (spot1 - spot2);
    if (r < 120)
        return RANGE_MELEE;
    if (r < 500)
        return RANGE_NEAR;
    if (r < 1000)
        return RANGE_MID;
    return RANGE_FAR;
};

/*
=============
visible

returns 1 if the entity is visible to self, even if not infront ()
=============
*/
float (entity targ) visible =
{
    local vector    spot1, spot2;

    spot1 = self.origin + self.view_ofs;
    spot2 = targ.origin + targ.view_ofs;
    traceline (spot1, spot2, TRUE, self);   // see through other monsters

    if (trace_inopen && trace_inwater)
        return FALSE;           // sight line crossed contents

    if (trace_fraction == 1)
        return TRUE;
    return FALSE;
};


/*
=============
infront

returns 1 if the entity is in front (in sight) of self
=============
*/
float(entity targ) infront =
{
    local vector    vec;
    local float     dot;

    makevectors (self.angles);
    vec = normalize (targ.origin - self.origin);
    dot = vec * v_forward;

    if ( dot > 0.3)
    {
        return TRUE;
    }
    return FALSE;
};


//============================================================================

/*
============
HuntTarget

gets monster to attack mode
============
*/
void() HuntTarget =
{
    local float vis;

    vis = infront (self.enemy);

    self.goalentity = self.enemy;
    self.think = self.th_run;
    if (!vis) // don't forget the melee guys
        self.ideal_yaw = vectoyaw(self.enemy.origin - self.origin);

    self.nextthink = time + 0.1;
    AI_AttackFinished (1); // wait a while before first attack
};

void() SightSound =
{
    local float rsnd;

    if (self.classname == "monster_butcher")
        sound (self, CHAN_VOICE, "butcher/fzomspot.wav", 1, ATTN_NORM);
    else if (self.classname == "monster_hellhound")
        sound (self, CHAN_VOICE, "hellhound/cerbspot.wav", 1, ATTN_NORM);
    else if (self.classname == "monster_rat")
        sound (self, CHAN_VOICE, "rat/ratspot.wav", 1, ATTN_NORM);
    else if (self.classname == "monster_bat")
        sound (self, CHAN_VOICE, "bat/batspot.wav", 1, ATTN_NORM);
     else if (self.classname == "monster_zombie")
        sound (self, CHAN_VOICE, "axezombie/azomspot.wav", 1, ATTN_NORM);
    else if (self.classname == "monster_eel")
        sound (self, CHAN_VOICE, "eel/eelspot.wav", 1, ATTN_NORM);
    else if (self.classname == "monster_gargoyle")
        sound (self, CHAN_VOICE, "gargoyle/gargspot.wav", 1, ATTN_NORM);
    else if (self.classname == "monster_stonegargoyle")
        sound (self, CHAN_VOICE, "stonegargoyle/sargspot.wav", 1, ATTN_NORM);
    else if (self.classname == "monster_browncultist" ||
             self.classname == "monster_blackcultist" ||
             self.classname == "monster_redcultist"   ||
             self.classname == "monster_greencultist" ||
             self.classname == "monster_bluecultist")
    {
        rsnd = random();

        if (rsnd <= 0.2)
            sound (self, CHAN_VOICE, "cultist/cultspt1.wav", 1, ATTN_NORM);
        else if (rsnd <= 0.4)
            sound (self, CHAN_VOICE, "cultist/cultspt2.wav", 1, ATTN_NORM);
        else if (rsnd <= 0.6)
            sound (self, CHAN_VOICE, "cultist/cultspt3.wav", 1, ATTN_NORM);
        else if (rsnd <= 0.8)
            sound (self, CHAN_VOICE, "cultist/cultspt4.wav", 1, ATTN_NORM);
        else
            sound (self, CHAN_VOICE, "cultist/cultspt5.wav", 1, ATTN_NORM);
    }
};

void() FoundTarget =
{
    if (self.enemy.classname == "player")
    {   // let other monsters see this monster for a while
        sight_entity = self;
        sight_entity_time = time;
    }

    self.show_hostile = time + 1;       // wake up other monsters

    SightSound ();
    HuntTarget ();
};

/*
===========
FindTarget

Self is currently not attacking anything, so try to find a target

Returns TRUE if an enemy was sighted

When a player fires a missile, the point of impact becomes a fakeplayer so
that monsters that see the impact will respond as if they had seen the
player.

To avoid spending too much time, only a single client (or fakeclient) is
checked each frame.  This means multi player games will have slightly
slower noticing monsters.
============
*/
float() FindTarget =
{
    local entity    client;
    local float     r;

// if the first spawnflag bit is set, the monster will only wake up on
// really seeing the player, not another monster getting angry

// spawnflags & 3 is a big hack, because zombie crucified used the first
// spawn flag prior to the ambush flag, and I forgot about it, so the second
// spawn flag works as well
    if (sight_entity_time >= time - 0.1 && !(self.spawnflags & 3) )
    {
        client = sight_entity;
        if (client.enemy == self.enemy)
            return;
    }
    else
    {
        client = checkclient ();
        if (!client)
            return FALSE;   // current check entity isn't in PVS
    }

    if (client == self.enemy)
        return FALSE;

    if (client.flags & FL_NOTARGET)
        return FALSE;
    if (client.items & IT_INVISIBILITY)
        return FALSE;

    r = range (client);
//    if (r == RANGE_FAR)  // TESTME: Do all blood monsters respond to players as soon as they're spotted?
//        return FALSE;

    if (!visible (client))
        return FALSE;

    if (r == RANGE_NEAR)
    {
        if (client.show_hostile < time && !infront (client))
            return FALSE;
    }
    else if (r == RANGE_MID)
    {
        if ( /* client.show_hostile < time || */ !infront (client))
            return FALSE;
    }

//
// got one
//
    self.enemy = client;
    if (self.enemy.classname != "player")
    {
        self.enemy = self.enemy.enemy;
        if (self.enemy.classname != "player")
        {
            self.enemy = world;
            return FALSE;
        }
    }

    FoundTarget ();

    return TRUE;
};


//=============================================================================

void(float dist) ai_forward =
{
    walkmove (self.angles_y, dist);
};

void(float dist) ai_back =
{
    walkmove ( (self.angles_y+180), dist);
};


/*
=============
ai_pain

stagger back a bit
=============
*/
void(float dist) ai_pain =
{
    ai_back (dist);
/*
    local float away;

    away = anglemod (vectoyaw (self.origin - self.enemy.origin)
    + 180*(random()- 0.5) );

    walkmove (away, dist);
*/
};

/*
=============
ai_painforward

stagger back a bit
=============
*/
void(float dist) ai_painforward =
{
    walkmove (self.ideal_yaw, dist);
};

/*
=============
ai_walk

The monster is walking it's beat
=============
*/
void(float dist) ai_walk =
{
    local vector        mtemp;

    movedist = dist;

    // check for noticing a player
    if (FindTarget ())
        return;

    movetogoal (dist);
};


/*
=============
ai_stand

The monster is staying in one place for a while, with slight angle turns
=============
*/
void() ai_stand =
{
    if (FindTarget ())
        return;

    if (time > self.pausetime)
    {
        self.th_walk ();
        return;
    }

// change angle slightly

};

/*
=============
ai_turn

don't move, but turn towards ideal_yaw
=============
*/
void() ai_turn =
{
    if (FindTarget ())
        return;

    ChangeYaw ();
};

//=============================================================================

/*
=============
ChooseTurn
=============
*/
void(vector dest3) ChooseTurn =
{
    local vector    dir, newdir;

    dir = self.origin - dest3;

    newdir_x = trace_plane_normal_y;
    newdir_y = 0 - trace_plane_normal_x;
    newdir_z = 0;

    if (dir * newdir > 0)
    {
        dir_x = 0 - trace_plane_normal_y;
        dir_y = trace_plane_normal_x;
    }
    else
    {
        dir_x = trace_plane_normal_y;
        dir_y = 0 - trace_plane_normal_x;
    }

    dir_z = 0;
    self.ideal_yaw = vectoyaw(dir);
};

/*
============
FacingIdeal

============
*/
float() FacingIdeal =
{
    local   float   delta;

    delta = anglemod(self.angles_y - self.ideal_yaw);
    if (delta > 45 && delta < 315)
        return FALSE;
    return TRUE;
};


//=============================================================================

float() CheckAnyAttack =
{
    if (!enemy_vis)
        return;
    return CheckAttack ();
};


/*
=============
ai_run_melee

Turn and close until within an angle to launch a melee attack
=============
*/
void() ai_run_melee =
{
    self.ideal_yaw = enemy_yaw;
    ChangeYaw ();

    if (FacingIdeal())
    {
        self.th_melee ();
        self.attack_state = AS_STRAIGHT;
    }
};


/*
=============
ai_run_missile

Turn in place until within an angle to launch a missile attack
=============
*/
void() ai_run_missile =
{
    self.ideal_yaw = enemy_yaw;
    ChangeYaw ();
    if (FacingIdeal())
    {
        self.th_missile ();
        self.attack_state = AS_STRAIGHT;
    }
};


/*
=============
ai_run_slide

Strafe sideways, but stay at aproximately the same range
=============
*/
void() ai_run_slide =
{
    local float ofs;

    self.ideal_yaw = enemy_yaw;
    ChangeYaw ();
    if (self.lefty)
        ofs = 90;
    else
        ofs = -90;

    if (walkmove (self.ideal_yaw + ofs, movedist))
        return;

    self.lefty = 1 - self.lefty;

    walkmove (self.ideal_yaw - ofs, movedist);
};


/*
=============
ai_run

The monster has an enemy it is trying to kill
=============
*/
void(float dist) ai_run =
{
    local   vector  delta;
    local   float   axis;
    local   float   direct, ang_rint, ang_floor, ang_ceil;

    movedist = dist;
// see if the enemy is dead
    if (self.enemy.health <= 0)
    {
        self.enemy = world;
    // FIXME: look all around for other targets
        if (self.oldenemy.health > 0)
        {
            self.enemy = self.oldenemy;
            HuntTarget ();
        }
        else
        {
            if (self.movetarget)
                self.th_walk ();
            else
                self.th_stand ();
            return;
        }
    }

    self.show_hostile = time + 1;       // wake up other monsters

// check knowledge of enemy
    enemy_vis = visible(self.enemy);
    if (enemy_vis)
        self.search_time = time + 5;

    // look for other coop players
    if (gametype == GT_COOPERATIVE && self.search_time < time)
    {
        if (FindTarget ())
            return;
    }

    enemy_infront = infront(self.enemy);
    enemy_range = range(self.enemy);
    enemy_yaw = vectoyaw(self.enemy.origin - self.origin);

    if (self.attack_state == AS_MISSILE)
    {
        ai_run_missile ();
        return;
    }
    if (self.attack_state == AS_MELEE)
    {
        ai_run_melee ();
        return;
    }

    if (CheckAnyAttack ())
        return;                 // beginning an attack

    if (self.attack_state == AS_SLIDING)
    {
        ai_run_slide ();
        return;
    }

// head straight in
    movetogoal (dist);      // done in C code...
};

/*
=============
ai_run_away

The heart and soul of the innocent ai.  Runs around like a dummy.  If he hits a wall, turn a little and keep going.
=============
*/
void(float dist) ai_run_away =
{
// FIXME: This should be tweaked more
traceline(self.origin, self.origin + '-32 0 0', FALSE, self); // Detect if there is something solid in self's way

    if (self.attack_finished < time)
       {
         //    Thinking whether or not self is stuck
         if (self.oldorigin == self.origin || trace_fraction != 1)
         {
           // Self is stuck
           self.ideal_yaw = self.ideal_yaw - 22.5;   // Turn a little bit
           self.ideal_yaw = anglemod(self.ideal_yaw);// Get rid of crazy values
         }
         else                                        // Self is not stuck!
           self.oldorigin = self.origin;

         self.attack_finished = time + 0.1;          // Give self a little while to get unstuck
       }

    ChangeYaw ();// Change the way self is facing
    walkmove(self.ideal_yaw, dist);
};