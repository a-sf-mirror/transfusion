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


void(float damage) Voodoo_ApplyDamage;


//============================================================================

// ----- Voodoo Doll model ----- //

$modelname v_voodoo

// stab stomach (0 -> 3)
$frame voodoo_stomach1 voodoo_stomach2 voodoo_stomach3 voodoo_stomach4

// stab eye (4 -> 7)
$frame voodoo_eye1 voodoo_eye2 voodoo_eye3 voodoo_eye4

// stab shoulder (8 -> 11)
$frame voodoo_shlder1 voodoo_shlder2 voodoo_shlder3 voodoo_shlder4

// stab groin (12 -> 15)
$frame voodoo_groin1 voodoo_groin2 voodoo_groin3 voodoo_groin4

// sit-up animation (16 -> 18)
$frame voodoo_situp1 voodoo_situp2 voodoo_situp3

// alt-fire mode (19 -> 26)
$frame voodoo_altfire1 voodoo_altfire2 voodoo_altfire3 voodoo_altfire4 voodoo_altfire5
$frame voodoo_altfire6 voodoo_altfire7 voodoo_altfire8


// ----- Player related code ----- //

void() player_voodoo =
{
    self.weaponframe = self.weaponframe + 1;
    if (self.weaponframe == $voodoo_situp1 ||
        self.weaponframe == $voodoo_groin1 ||
        self.weaponframe == $voodoo_eye1   ||
        self.weaponframe == $voodoo_shlder1 )
    {
        player_run ();
        self.weaponframe = $voodoo_stomach1;
    }
};

void() player_voodoo1 = [$light1, player_voodoo2] { player_voodoo (); };
void() player_voodoo2 = [$light2, player_voodoo1] { player_voodoo (); };

void() player_altvoodoo1 = [$light1, player_altvoodoo2] { self.weaponframe = $voodoo_altfire1; };
void() player_altvoodoo2 = [$light2, player_altvoodoo3] { self.weaponframe = $voodoo_altfire2; };
void() player_altvoodoo3 = [$light1, player_altvoodoo4] { self.weaponframe = $voodoo_altfire3; };
void() player_altvoodoo4 = [$light2, player_altvoodoo5] { self.weaponframe = $voodoo_altfire4; };
void() player_altvoodoo5 = [$light1, player_altvoodoo6]
{
    local float damage;

    self.weaponframe = $voodoo_altfire5;
    damage = self.ammo_voodoo;
    self.ammo_voodoo = 0;
    Voodoo_ApplyDamage (damage);
};
void() player_altvoodoo6 = [$light2, player_altvoodoo7] { self.weaponframe = $voodoo_altfire6; };
void() player_altvoodoo7 = [$light1, player_altvoodoo8] { self.weaponframe = $voodoo_altfire7; };
void() player_altvoodoo8 = [$light2, player_run       ] { self.weaponframe = $voodoo_altfire8; };


//============================================================================

/*
================
Voodoo_ApplyDamage

Apply the spiritual damage of the voodoo doll
================
*/
void(float damage) Voodoo_ApplyDamage =
{
    local vector dir;
    local vector src;
    local vector vel, org;
    local entity targ;

    self.currentammo = self.ammo_voodoo;

    dir = aim (self, 100000);

    makevectors(self.v_angle);

    src = self.origin + v_forward * 10;
    src_z = self.absmin_z + self.size_z * 0.7;

    traceline (src, src + dir * 2048, FALSE, self);

    // If we had a target that can be damaged and seems alive
    if (trace_fraction != 1.0 && trace_ent.takedamage && ((trace_ent.flags & FL_MONSTER) || trace_ent.classname == "player"))
    {
        org = trace_endpos - dir*4;

        vel = normalize (dir + v_up * crandom() + v_right * crandom ());
        vel = vel + 2 * trace_plane_normal;
        vel = vel * 200;

        #ifdef QUAKEWORLD
        WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
        WriteByte (MSG_MULTICAST, TE_BLOOD);
        WriteByte (MSG_MULTICAST, 1);
        WriteCoord (MSG_MULTICAST, org_x);
        WriteCoord (MSG_MULTICAST, org_y);
        WriteCoord (MSG_MULTICAST, org_z);
        multicast (puff_org, MULTICAST_PVS);
        #else
        SpawnBlood (org, vel * 0.2, damage);
        #endif

        targ = trace_ent;
    }
    // Else, WE take the damage
    else
        targ = self;

    T_Damage (targ, self, self, damage, DF_MIND, "voodoo");
};


/*
================
Voodoo_Stab

Do a normal attack with the voodoo doll
================
*/
float() Voodoo_Stab =
{
    local float damage;
    local float stab_type;

    stab_type = random()*4;
    damage = random();
    if (stab_type >= 3) // Stab Groin
    {
        self.weaponframe = $voodoo_groin1;
        damage = damage*49 + 4;
    }
    else if (stab_type >= 2) // Stab Shoulder (supposed to make player lower weapon in MP mode)
    {
        self.weaponframe = $voodoo_shlder1;
        damage = damage*9 + 4;
    }
    else if (stab_type >= 1) // Stab Chest
    {
        self.weaponframe = $voodoo_stomach1;
        damage = damage*17 + 4;
    }
    else if (stab_type < 1) // Stab Eye (supposed to blind player in MP mode)
    {
        self.weaponframe = $voodoo_eye1;
        damage = damage*11 + 4;
    }
    else
        Sprint (self, PRINT_MEDIUM, "There's a problem with the voodoo doll code\n");

    // Play the appropriate sound
    if (stab_type >= 3)  // Stab Groin
        sound (self, CHAN_WEAPON, "weapons/voodoodl/voolaugh.wav", 1, ATTN_NORM);
    else
        sound (self, CHAN_WEAPON, "weapons/voodoodl/voostab.wav", 1, ATTN_NORM);

    self.ammo_voodoo = self.ammo_voodoo - damage / 4;

    return damage;
};


/*
============
Voodoo_Attack

Attack code for the voodoo doll
============
*/
void() Voodoo_Attack =
{
    local float damage;

    muzzleflash ();

    // Alt-fire mode
    if ((self.impulse == 12 || self.button1) && self.ammo_voodoo >= 1)
    {
        self.player_state = PS_ALTFIRE;

        sound (self, CHAN_WEAPON, "weapons/voodoodl/voochant.wav", 1, ATTN_NORM);
        player_altvoodoo1 ();

        self.attack_finished = time + 1.5;
    }

    // Normal fire mode
    else
    {
        self.player_state = PS_FIRE;

        damage = Voodoo_Stab ();
        player_voodoo1 ();
        Voodoo_ApplyDamage (damage);

        self.attack_finished = time + 0.5;
    }
};
