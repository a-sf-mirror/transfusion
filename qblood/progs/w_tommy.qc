/*  Copyright (C) 2001-2003  Mathieu Olivier

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


void() Tommy_Fire;


//============================================================================

// ----- Tommy Gun models ----- //

#ifndef NEW_MODELS
// Normal model
$modelname v_nail

// idle
$frame tommy_idle1

// fire
$frame tommy_fire1 tommy_fire2

// altfire
// tommy_alt1 = tommy_alt5 = center
// tommy_alt2 = tommy_alt4 = near left
// tommy_alt6 = tommy_alt8 = near right
$frame tommy_alt1 tommy_alt2 tommy_alt3 tommy_alt4 tommy_alt5
$frame tommy_alt6 tommy_alt7 tommy_alt8

// draw
$frame tommy_draw1 tommy_draw2 tommy_draw3

// holster
$frame tommy_holster1 tommy_holster2 tommy_holster3


#else
// Normal model
$modelname v_tommy

// idle
$frame tommy_idle1

// draw
$frame tommy_draw1 tommy_draw2 tommy_draw3

// fire
$frame tommy_fire1 tommy_fire2

// altfire
// tommy_alt1 = tommy_alt5 = center
// tommy_alt2 = tommy_alt4 = near left
// tommy_alt6 = tommy_alt8 = near right
$frame tommy_alt1 tommy_alt2 tommy_alt3 tommy_alt4 tommy_alt5
$frame tommy_alt6 tommy_alt7 tommy_alt8

// holster
$frame tommy_holster1 tommy_holster2 tommy_holster3
#endif


// Akimbo model
$modelname v_anail

// idle
$frame atommy_idle1

// fire
$frame atommy_fire1 atommy_fire2

// altfire
// atommy_alt1 = atommy_alt5 = center
// atommy_alt2 = atommy_alt4 = near left
// atommy_alt6 = atommy_alt8 = near right
$frame atommy_alt1 atommy_alt2 atommy_alt3 atommy_alt4 atommy_alt5
$frame atommy_alt6 atommy_alt7 atommy_alt8

// draw
$frame atommy_draw1 atommy_draw2 atommy_draw3

// holster
$frame atommy_holster1 atommy_holster2 atommy_holster3


// ----- Player related code ----- //

// WARNING: The code below assumes that both models have the exact same frame types

void() player_tommy =
{
    if (!self.button0 || intermission_running || self.ammo_nails < 1)
    {
        player_run ();
        return;
    }

    muzzleflash ();

    Tommy_Fire ();
    self.attack_finished = time + 0.1;

    self.impulse = 0;
};

void() player_tommy1 = [$attack1, player_tommy2] { player_tommy (); self.weaponframe = $tommy_fire1; };
void() player_tommy2 = [$attack2, player_tommy1] { player_tommy (); self.weaponframe = $tommy_fire2; };

void() player_alttommy =
{
    if ((!self.button3 && self.weaponframe == $atommy_alt8) || intermission_running ||
        self.ammo_nails < 1 || (self.ammo_nails < 2 && (self.items & IT_GUNS_AKIMBO)))
    {
        player_run ();
        return;
    }

    muzzleflash ();

    self.weaponframe = self.weaponframe + 1;
    if (self.weaponframe > $tommy_alt8 || self.weaponframe < $tommy_alt1)
        self.weaponframe = $tommy_alt1;
    Tommy_Fire ();
    self.attack_finished = time + 0.1;

    self.impulse = 0;
};
void() player_alttommy1 = [$attack1, player_alttommy2] { player_alttommy (); };
void() player_alttommy2 = [$attack2, player_alttommy1] { player_alttommy (); };

// Normal draw
void() player_tommydraw1 = [$attack2, player_tommydraw2] { self.weaponframe = $tommy_draw1; };
void() player_tommydraw2 = [$attack2, player_tommydraw3] { self.weaponframe = $tommy_draw2; };
void() player_tommydraw3 = [$attack2, player_run       ] { self.weaponframe = $tommy_draw3; };

// Normal holster
void() player_tommyholster1 = [$attack2, player_tommyholster2] { self.weaponframe = $tommy_holster1; };
void() player_tommyholster2 = [$attack2, player_tommyholster3] { self.weaponframe = $tommy_holster2; };
void() player_tommyholster3 = [$attack2, player_tommyholster4] { self.weaponframe = $tommy_holster3; };
void() player_tommyholster4 = [$attack2, player_run          ] { W_DrawWeapon (self.newweapon); };


//============================================================================

/*
================
Tommy_SpawnShell

Spawns new shell entity but doesn't display it until reloadtime
================
*/
void(vector orig) Tommy_SpawnShell =
{
    local entity shell;

    shell = spawn ();
    shell.owner = self;

    shell.mdl = "progs/tommyshl.mdl";
    if (random() < 0.5)
        shell.noise = "weapons/shtshl.wav";
    else
        shell.noise = "weapons/shtshl3.wav";

    setorigin (shell, orig);
    shell.velocity = (crandom() + 1)*v_forward*30 - v_right*(100 + crandom()*10) + v_up*(100 + crandom()*10);

    DropShell (shell);
};


/*
============
Tommy_Fire

Fire with the tommygun
============
*/
void() Tommy_Fire =
{
    local vector    dir;
    local entity    old;
    local vector    orig;
    local float     akimboFactor;  // 2 if guns akimbo, else 1
    local vector    spread;
    local float     damage;

    if (self.items & IT_GUNS_AKIMBO)
        akimboFactor = 2;
    else
        akimboFactor = 1;

    makevectors (self.v_angle);

    sound (self, CHAN_WEAPON, "weapons/tommygun/_tom.wav", 1, ATTN_NORM);
    self.attack_finished = time + 0.1;
    self.currentammo = self.ammo_nails = self.ammo_nails - akimboFactor;

    // set the bullet direction according to the weapon real direction
    dir = aim (self, 1000);
    if (self.weaponframe == $tommy_alt2 || self.weaponframe == $tommy_alt4)
        dir = dir - v_right * (1 / 6);
    else if (self.weaponframe == $tommy_alt3)
        dir = dir - v_right * (1 / 3);
    else if (self.weaponframe == $tommy_alt6 || self.weaponframe == $tommy_alt8)
        dir = dir + v_right * (1 / 6);
    else if (self.weaponframe == $tommy_alt7)
        dir = dir + v_right * (1 / 3);

    // If we are in altfire mode
    if (self.weaponframe >= $tommy_alt1)
        damage = 20;
    else
        damage = 12;

    orig = self.origin + v_forward * 15 + v_up * 12 + v_right * 4;
    spread = '0.05 0.02 0';

    // If we're in akimbo mode
    if (akimboFactor == 2)
    {
        // Spawn 1 shell alternatively for each gun
        if ((self.weaponframe - $atommy_fire1) & 1)
            orig = orig + v_right * 4;
        else
            orig = orig - v_right * 4;
        Tommy_SpawnShell (orig);

        orig = self.origin + v_right * 4 + v_up * 20;

        FireBullets (orig, dir, 1, damage, spread);
        orig = orig - v_right * 8;
        FireBullets (orig, dir, 1, damage, spread);

        // If we don't have enough ammo anymore, drop the akimbo mode for now
        if (self.currentammo < 2)
            W_SetCurrentAmmo ();
    }
    else
    {
        // Spawn 1 shell every 2 shots
        if ((self.weaponframe - $tommy_fire1) & 1)
            Tommy_SpawnShell (orig);

        FireBullets (self.origin + v_up * 20, dir, 1, damage, spread);
    }

    self.punchangle_x = -2 * akimboFactor;
};


/*
============
Tommy_Attack

Attack code for the tommygun
============
*/
void() Tommy_Attack =
{
    // If it's a tommy gun altfire start and if we have enough ammo
    if (self.button3 && (! (self.items & IT_GUNS_AKIMBO) || self.ammo_nails >= 2))
    {
        self.player_state = PS_ALTFIRE;
        player_alttommy1 ();
    }
    else
    {
        self.player_state = PS_FIRE;
        player_tommy1 ();
    }
};


/*
============
Tommy_Draw

Draw code for the tommygun
============
*/
void() Tommy_Draw =
{
    self.weapon = IT_TOMMYGUN;
    self.currentammo = self.ammo_nails;
    self.items = (self.items - (self.items & (IT_SHELLS | IT_CELLS | IT_ROCKETS))) | IT_NAILS;

    Tommy_UpdateView ();

    self.attack_finished = time + 0.4;
    player_tommydraw1 ();
};


/*
============
Tommy_Holster

Holster code for the tommygun
============
*/
void() Tommy_Holster =
{
    self.attack_finished = time + 0.4;
    player_tommyholster1 ();
};


/*
============
Tommy_UpdateView

Choose the right tommygun model to display
============
*/
void() Tommy_UpdateView =
{
    if (self.akimbo_finished > time && self.currentammo >= 2)
    {
        self.weaponmodel = "progs/v_anail.mdl";
        self.items = self.items | IT_GUNS_AKIMBO;
    }
    else
    {
        #ifndef NEW_MODELS
        self.weaponmodel = "progs/v_nail.mdl";
        #else
        self.weaponmodel = "models/weapons/v_tommy.md3";
        #endif
        self.items = self.items - (self.items & IT_GUNS_AKIMBO);
    }
};
