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


void() Tommy_Fire;


//============================================================================

// ----- Tesla Cannon model ----- //

// Normal model
$modelname v_nail

// fire
$frame tommy_fire1 tommy_fire2 tommy_fire3 tommy_fire4 tommy_fire5
$frame tommy_fire6 tommy_fire7 tommy_fire8

// altfire
$frame tommy_alt1 tommy_alt2 tommy_alt3 tommy_alt4 tommy_alt5
$frame tommy_alt6 tommy_alt7


// Akimbo model
$modelname v_anail

// fire
$frame atommy_fire1 atommy_fire2 atommy_fire3 atommy_fire4 atommy_fire5
$frame atommy_fire6 atommy_fire7 atommy_fire8

// altfire
// NOTE: "atommy_alt7" is the same as "atommy_alt1", so we skip it
$frame atommy_alt1 atommy_alt2 tommy_alt3 atommy_alt4 atommy_alt5
$frame atommy_alt6 atommy_alt7


// ----- Player related code ----- //

// WARNING: The code below assumes that both models have the exact same frame types

void() player_tommy =
{
    if ((!self.button0 && !self.button1 && self.impulse != 12)  || intermission_running || self.ammo_nails < 1)
    {
        player_run ();
        return;
    }

    muzzleflash ();

    self.weaponframe = self.weaponframe + 1;
    if (self.weaponframe > $tommy_fire8)
        self.weaponframe = $tommy_fire1;

    Tommy_Fire ();
    self.attack_finished = time + 0.1;

    self.impulse = 0;
};

void() player_tommy1 = [$nailatt1, player_tommy2] { player_tommy (); };
void() player_tommy2 = [$nailatt2, player_tommy1] { player_tommy (); };

void() player_alttommy =
{
    if ((!self.button1 && self.impulse != 12 && self.weaponframe == $atommy_alt6) || intermission_running ||
        self.ammo_nails < 1 || (self.ammo_nails < 2 && (self.items & IT_GUNS_AKIMBO)))
    {
        player_run ();
        return;
    }

    muzzleflash ();

    // $tommy_alt7 is skipped (see above)
    self.weaponframe = self.weaponframe + 1;
    if (self.weaponframe > $tommy_alt6 || self.weaponframe < $tommy_alt1)
        self.weaponframe = $tommy_alt1;
    Tommy_Fire ();
    self.attack_finished = time + 0.1;

    self.impulse = 0;
};
void() player_alttommy1 = [$nailatt1, player_alttommy2] { player_alttommy (); };
void() player_alttommy2 = [$nailatt2, player_alttommy1] { player_alttommy (); };

// Normal draw
// NOTE: no animation to play for now
void() player_tommydraw1 = [$nailatt1, player_run] { self.weaponframe = 0; };

// Normal holster
// NOTE: no animation to play for now
void() player_tommyholster1 = [$nailatt1, player_run] { W_DrawWeapon (self.newweapon); };


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
        dir = dir - v_right * (1 / 8);
    else if (self.weaponframe == $tommy_alt3)
        dir = dir - v_right * (1 / 4);
    else if (self.weaponframe == $tommy_alt6)
        dir = dir + v_right * (1 / 8);

    // If we're in akimbo mode
    orig = self.origin + v_forward * 15 + v_up * 12 + v_right * 4;
    if (akimboFactor == 2)
    {
        local float damage;

        // Spawn the shells
        orig = orig + v_right * 4;
        Tommy_SpawnShell (orig);
        orig = orig - v_right * 8;
        Tommy_SpawnShell (orig);

        // If we are in altfire mode
        if (self.weaponframe >= $tommy_alt1)
            damage = 15;
        else
            damage = 5;

        orig = self.origin + v_right * 4;
        FireBullets (orig, dir, 1, damage, '0.04 0.04 0');
        orig = self.origin - v_right * 4;
        FireBullets (orig, dir, 1, damage, '0.04 0.04 0');

        // If we don't have enough ammo anymore, drop the akimbo mode for now
        if (self.currentammo < 2)
            W_SetCurrentAmmo ();
    }
    else
    {
        // Spawn the shell
        Tommy_SpawnShell (orig);

        // If we are in altfire mode
        if (self.weaponframe >= $tommy_alt1)
            FireBullets (self.origin, dir, 1, 15, '0.04 0.04 0');
        else
            FireBullets (self.origin, dir, 1, 5, '0.04 0.04 0');
    }

    #ifdef QUAKEWORLD
    msg_entity = self;
    WriteByte (MSG_ONE, SVC_SMALLKICK + akimboFactor - 1);
    #else
    self.punchangle_x = -2 * akimboFactor;
    #endif
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
    if ((self.impulse == 12 || self.button1) &&
        (! (self.items & IT_GUNS_AKIMBO) || self.ammo_cells >= 2))
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

    self.attack_finished = time + 0.1;
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
    self.attack_finished = time + 0.1;
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
        self.weaponmodel = "progs/v_nail.mdl";
        self.items = self.items - (self.items & IT_GUNS_AKIMBO);
    }
};
