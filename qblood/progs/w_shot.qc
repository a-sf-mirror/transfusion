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


void() Shot_Fire;
void() Shot_SpawnShell;


//============================================================================

// ----- Sawed-off models ----- //

// Normal model
$modelname v_shot2

// idle
$frame shot_idle1

// fire
$frame shot_fire1 shot_fire2

// reload
$frame shot_reload1 shot_reload2 shot_reload3 shot_reload4 shot_reload5
$frame shot_reload6 shot_reload7 shot_reload8 shot_reload9 shot_reload10

// draw
$frame shot_draw1 shot_draw2 shot_draw3 shot_draw4

// holster
$frame shot_holster1 shot_holster2 shot_holster3 shot_holster4


// Akimbo model
$modelname v_ashot2

// fire
$frame ashot_fire1 ashot_fire2 ashot_fire3 ashot_fire4 ashot_fire5

// draw
$frame ashot_draw1 ashot_draw2 ashot_draw3 ashot_draw4

// holster
$frame ashot_holster1 ashot_holster2 ashot_holster3 ashot_holster4 ashot_holster5
$frame ashot_holster6 ashot_holster7


// ----- Player related code ----- //

void() player_shot1 = [$supatt1, player_shot2] { self.weaponframe = $shot_fire1; muzzleflash (); };
void() player_shot2 = [$supatt2, player_run  ] { self.weaponframe = $shot_fire2; Shot_SpawnShell (); };

void() player_reloadshot1  = [$supatt1, player_reloadshot2 ] { self.weaponframe = $shot_reload1; };
void() player_reloadshot2  = [$supatt1, player_reloadshot3 ] { self.weaponframe = $shot_reload2; };
void() player_reloadshot3  = [$supatt1, player_reloadshot4 ] { self.weaponframe = $shot_reload3; };
void() player_reloadshot4  = [$supatt1, player_reloadshot5 ] { self.weaponframe = $shot_reload4; };
void() player_reloadshot5  = [$supatt1, player_reloadshot6 ] { self.weaponframe = $shot_reload5; };
void() player_reloadshot6  = [$supatt1, player_reloadshot7 ] { self.weaponframe = $shot_reload6; };
void() player_reloadshot7  = [$supatt1, player_reloadshot8 ] { self.weaponframe = $shot_reload7; };
void() player_reloadshot8  = [$supatt1, player_reloadshot9 ] { self.weaponframe = $shot_reload8; };
void() player_reloadshot9  = [$supatt1, player_reloadshot10] { self.weaponframe = $shot_reload9; };
void() player_reloadshot10 = [$supatt1, player_run         ] { self.weaponframe = $shot_reload10; };

void() player_akshot1 = [$supatt1, player_akshot2] { self.weaponframe = $ashot_fire1; };
void() player_akshot2 = [$supatt2, player_akshot3] { self.weaponframe = $ashot_fire2; muzzleflash (); Shot_Fire (); };
void() player_akshot3 = [$supatt1, player_akshot4] { self.weaponframe = $ashot_fire3; };
void() player_akshot4 = [$supatt2, player_akshot5] { self.weaponframe = $ashot_fire4; muzzleflash (); Shot_Fire (); };
void() player_akshot5 = [$supatt1, player_run    ]
{
    self.weaponframe = $ashot_fire5;

    // If we don't have enough ammo anymore, drop the akimbo mode for now
    if (self.ammo_shells < 2)
        W_SetCurrentAmmo (FALSE, 0);
};


//============================================================================

/*
================
Shot_SpawnShell

Spawns the shotgun shells if necessary
================
*/
void() Shot_SpawnShell =
{
    // Shotgun shells (2 shells dropped at a time, or nothing)
    if ((self.currentammo & 1) == 0)
    {
        local entity shell;
        local entity shell2;

        // 1st shell
        shell = spawn ();
        shell.owner = self;
        shell.mdl   = "progs/shotshl.mdl";
        shell.noise = "weapons/shtshl2.wav";

        setorigin (shell, self.origin + v_forward * 15);
        shell.velocity = (crandom () + 1) * v_forward * 30 + v_up * (220 + crandom () * 10) - v_right * crandom () * 30;
        DropShell (shell);

        // 2nd shell
        shell2 = spawn ();
        shell2.owner = self;
        shell2.mdl   = shell.mdl;
        shell2.noise = shell.noise;

        setorigin (shell2, shell.origin);
        shell2.velocity = (crandom () + 1) * v_forward * 30 + v_up * (220 + crandom () * 10) - v_right * crandom () * 30;
        DropShell (shell2);

        // play the reload scene at the next frame
        self.think = player_reloadshot1;
        self.attack_finished = time + 1.2;
        sound (shell, CHAN_WEAPON, "weapons/shotgun/shotcock.wav", 1, ATTN_NORM);
    }
};


/*
================
Shot_Fire

Shot with the sawed-off
================
*/
void() Shot_Fire =
{
    local float nbshots;
    local vector dir;

    if (self.player_state == PS_ALTFIRE && (self.currentammo & 1) != 1)
        nbshots = 2;
    else
        nbshots = 1;

    #ifndef QUAKEWORLD
    self.punchangle_x = -2 * nbshots;
    #else
    msg_entity = self;
    WriteByte (MSG_ONE, SVC_SMALLKICK + nbshots - 1);
    #endif

    self.currentammo = self.ammo_shells = self.ammo_shells - nbshots;

    if (nbshots == 1)
        sound (self, CHAN_WEAPON, "weapons/shotgun/shotfire.wav", 1, ATTN_NORM);
    else
        sound (self ,CHAN_WEAPON, "weapons/shotgun/shotfir2.wav", 1, ATTN_NORM);

    dir = aim (self, 100000);
    FireBullets (self.origin, dir, 11 * nbshots, 4, '0.08 0.08 0');  // 9 "shot pellets" per shell
};


/*
============
Shot_Attack

Attack code for the sawed-off
============
*/
void() Shot_Attack =
{
    self.attack_finished = time + 0.7;

    // If it's an altfire shot
    if (self.button1 || self.impulse == 12)
        self.player_state = PS_ALTFIRE;
    else
        self.player_state = PS_FIRE;

    // if we have guns akimbo
    if (self.items & IT_GUNS_AKIMBO)
        player_akshot1 ();
    else
    {
        player_shot1 ();
        Shot_Fire ();
    }
};
