/*  Copyright (C) 2001  Mathieu Olivier

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
#include "player.qh"


void() Fork_Fire;


//============================================================================

// ----- Pitchfork model ----- //

$modelname v_axe

// idle
$frame fork_idle1

// fire
$frame fork_fire1 fork_fire2 fork_fire3


// ----- Player related code ----- //

void() player_fork4 =
{
    self.frame = self.frame + 1;
    self.nextthink = time + 0.1;
    self.think = player_run;

    self.weaponframe = $fork_idle1;
};
void() player_fork3 =
{
    self.frame = self.frame + 1;
    self.nextthink = time + 0.1;
    self.think = player_fork4;

    self.weaponframe = $fork_fire3;
    Fork_Fire ();
};
void() player_fork2 =
{
    self.frame = self.frame + 1;
    self.nextthink = time + 0.1;
    self.think = player_fork3;

    self.weaponframe = $fork_fire2;
};
void() player_fork1 =
{
    self.nextthink = time + 0.1;
    self.think = player_fork2;

    self.weaponframe = $fork_fire1;
};


//============================================================================

/*
============
TineHit

Handle one tine hit with the pitchfork
============
*/
void(entity targ, vector org, float damage) TineHit =
{
    if (targ.takedamage)
    {
        if (Reflected (targ))
        {
            if (Reflected (self))
                return;     // Both have reflection, so negate attack.

            // Hit attacker instead.
            targ = self;
            org = self.origin;
        }
        targ.axhitme = 1;
        if ((targ.flags & FL_MONSTER) || targ.classname == "player")
            SpawnBlood (org, '0 0 0', damage);
        AddMultiDamage (targ, damage);
        SpawnBloodSpray (trace_ent, org);  // NOTE: doesn't spawn blood spray on non-living entities
        sound (self, CHAN_WEAPON, "weapons/pitchfrk/pflesh.wav", 1, ATTN_NORM);
    }
    else
    {
        // hit wall
        sound (self, CHAN_WEAPON, "weapons/pitchfrk/pstone.wav", 1, ATTN_NORM);

        #ifdef QUAKEWORLD
        WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
        WriteByte (MSG_MULTICAST, TE_GUNSHOT);
        WriteByte (MSG_MULTICAST, 3);
        WriteCoord (MSG_MULTICAST, org_x);
        WriteCoord (MSG_MULTICAST, org_y);
        WriteCoord (MSG_MULTICAST, org_z);
        multicast (org, MULTICAST_PVS);
        #else
        WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte (MSG_BROADCAST, TE_GUNSHOT);
        WriteCoord (MSG_BROADCAST, org_x);
        WriteCoord (MSG_BROADCAST, org_y);
        WriteCoord (MSG_BROADCAST, org_z);
        #endif
    }
};


/*
============
Fork_Fire

Try to hit something with the pitchfork
============
*/
void() Fork_Fire =
{
    local   vector  source;
    local   vector  start, end;     // Endpoints per tine.
    local   vector  vx, vy, vz;     // forward, right, up unit vectors.
    local   float   damage;         // Damage per tine.
    local   float   loop;           // Number of tines.

    makevectors (self.v_angle);
    vx = v_forward;
    vy = v_right;
    vz = v_up;
    source = self.origin + '0 0 16';
    damage = 17;
    loop = 4;

    // Tines attacks start at the right, and end at the left.
    ClearMultiDamage ();
    while (loop > 0)
    {
        start = source + vy * ((loop - 2) * 4 - 2);
        end = start + vx * 64;
        traceline (start, end, FALSE, self);
        if (trace_fraction < 1)
        {
            end = trace_endpos - vx * 4;
            TineHit (trace_ent, end, damage);
        }
        loop = loop - 1;
    }
    ApplyMultiDamage ();
};


/*
============
Fork_Attack

Attack code for the pitchfork
============
*/
void() Fork_Attack =
{
    local float r;

    r = random ();
    if (r < 0.25)
        self.frame = $axatt1;
    else if (r < 0.5)
        self.frame = $axattb1;
    else if (r < 0.75)
        self.frame = $axattc1;
    else
        self.frame = $axattd1;

    player_fork1 ();
    self.attack_finished = time + 0.5;
    self.impulse = 0;
};
