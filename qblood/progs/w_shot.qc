/*  Copyright (C) 2001-2002  Mathieu Olivier

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

// alt
$frame shot_alt1 shot_alt2 shot_alt3

// reload
$frame shot_reload1 shot_reload2 shot_reload3 shot_reload4 shot_reload5

// draw
$frame shot_draw1 shot_draw2 shot_draw3 shot_draw4

// holster
$frame shot_holster1 shot_holster2 shot_holster3 shot_holster4


// Akimbo model
$modelname v_ashot2

// idle
$frame ashot_idle1

// fire
$frame ashot_fire1 ashot_fire2 ashot_fire3

// altfire
$frame ashot_alt1 ashot_alt2 ashot_alt3 ashot_alt4

// draw
$frame ashot_draw1 ashot_draw2 ashot_draw3 ashot_draw4

// holster
$frame ashot_holster1 ashot_holster2 ashot_holster3 ashot_holster4


// ----- Player related code ----- //

// Reload
void() player_reloadshot1  = [$attack2, player_reloadshot2 ] { self.weaponframe = $shot_reload1; };
void() player_reloadshot2  = [$attack2, player_reloadshot3 ] { self.weaponframe = $shot_reload2; };
void() player_reloadshot3  = [$attack2, player_reloadshot4 ] { self.weaponframe = $shot_reload3; Shot_SpawnShell (); };
void() player_reloadshot4  = [$attack2, player_reloadshot5 ] { self.weaponframe = $shot_reload4; };
void() player_reloadshot5  = [$attack2, player_run         ] { self.weaponframe = $shot_reload5; };

// Normal shot
void() player_shot1 = [$attack1, player_shot2] { self.weaponframe = $shot_fire1; muzzleflash (); };
void() player_shot2 = [$attack2, player_run  ]
{
    self.weaponframe = $shot_fire2;
    if ((self.currentammo & 1) == 0)
    {
        self.think = player_reloadshot1;
        self.attack_finished = time + 0.6;
    }
};

// Akimbo normal shot
void() player_akshot1 = [$attack1, player_akshot2] { self.weaponframe = $ashot_fire1; muzzleflash (); Shot_Fire (); };
void() player_akshot2 = [$attack1, player_akshot3] { self.weaponframe = $ashot_fire2; muzzleflash (); Shot_Fire (); };
void() player_akshot3 = [$attack2, player_akshot4] { self.weaponframe = $ashot_fire3; };
void() player_akshot4 = [$attack2, player_run    ]
{
    // If we don't have enough ammo anymore, drop the akimbo mode for now
    if (self.ammo_shells < 2)
    {
        Shot_UpdateView ();
        self.weaponframe = 0;
    }
};

// Akimbo altfire shot
void() player_altshot1 = [$attack1, player_altshot2]
{
    self.weaponframe = $ashot_alt1;
    muzzleflash ();
    Shot_Fire ();
    Shot_Fire ();
};
void() player_altshot2 = [$attack1, player_altshot3] { self.weaponframe = $ashot_alt2; };
void() player_altshot3 = [$attack2, player_altshot4] { self.weaponframe = $ashot_alt3; };
void() player_altshot4 = [$attack2, player_altshot5] { self.weaponframe = $ashot_alt4; };
void() player_altshot5 = [$attack2, player_run    ]
{
    // If we don't have enough ammo anymore, drop the akimbo mode for now
    if (self.ammo_shells < 2)
    {
        Shot_UpdateView ();
        self.weaponframe = 0;
    }
};

// Normal draw
void() player_shotdraw1 = [$attack2, player_shotdraw2] { self.weaponframe = $shot_draw1; };
void() player_shotdraw2 = [$attack2, player_shotdraw3] { self.weaponframe = $shot_draw2; };
void() player_shotdraw3 = [$attack2, player_shotdraw4] { self.weaponframe = $shot_draw3; };
void() player_shotdraw4 = [$attack2, player_run      ] { self.weaponframe = $shot_draw4; };

// Normal holster
void() player_shotholster1 = [$attack2, player_shotholster2] { self.weaponframe = $shot_holster1; };
void() player_shotholster2 = [$attack2, player_shotholster3] { self.weaponframe = $shot_holster2; };
void() player_shotholster3 = [$attack2, player_shotholster4] { self.weaponframe = $shot_holster3; };
void() player_shotholster4 = [$attack2, player_shotholster5] { self.weaponframe = $shot_holster4; };
void() player_shotholster5 = [$attack2, player_run         ] { W_DrawWeapon (self.newweapon); };

// Akimbo draw
void() player_akshotdraw1 = [$attack2, player_akshotdraw2] { self.weaponframe = $ashot_draw1; };
void() player_akshotdraw2 = [$attack2, player_akshotdraw3] { self.weaponframe = $ashot_draw2; };
void() player_akshotdraw3 = [$attack2, player_akshotdraw4] { self.weaponframe = $ashot_draw3; };
void() player_akshotdraw4 = [$attack2, player_run        ] { self.weaponframe = $ashot_draw4; };

// Akimbo holster
void() player_akshotholster1 = [$attack2, player_akshotholster2] { self.weaponframe = $ashot_holster1; };
void() player_akshotholster2 = [$attack2, player_akshotholster3] { self.weaponframe = $ashot_holster2; };
void() player_akshotholster3 = [$attack2, player_akshotholster4] { self.weaponframe = $ashot_holster3; };
void() player_akshotholster4 = [$attack2, player_akshotholster5] { self.weaponframe = $ashot_holster4; };
void() player_akshotholster5 = [$attack2, player_run           ] { W_DrawWeapon (self.newweapon); };


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
    local vector spread;

    if (! self.ammo_shells)
        return;

    if (self.player_state == PS_ALTFIRE && (self.currentammo & 1) != 1)
    {
        nbshots = 2;
        spread = '0.14 0.08 0';
    }
    else
    {
        nbshots = 1;
        spread = '0.1 0.03 0';
    }

    makevectors (self.v_angle);

    #ifndef QUAKEWORLD
    self.punchangle_x = -2 * nbshots;
    #else
    msg_entity = self;
    WriteByte (MSG_ONE, SVC_SMALLKICK + nbshots - 1);
    #endif

    self.currentammo = self.ammo_shells = self.ammo_shells - nbshots;

    if (nbshots == 1)
        sound (self, CHAN_AUTO, "weapons/shotgun/shotfire.wav", 1, ATTN_NORM);
    else
        sound (self ,CHAN_AUTO, "weapons/shotgun/shotfir2.wav", 1, ATTN_NORM);

    dir = aim (self, 100000);
    FireBullets (self.origin + v_up * 20, dir, 8 * nbshots, 8, spread);  // 8 "shot pellets" per shell
};


/*
============
Shot_Attack

Attack code for the sawed-off
============
*/
void() Shot_Attack =
{
    self.attack_finished = time + 0.4;

    // If it's an altfire shot
    if (self.button3 || self.impulse == 12)
        self.player_state = PS_ALTFIRE;
    else
        self.player_state = PS_FIRE;

    // If we have guns akimbo
    if (self.items & IT_GUNS_AKIMBO)
    {
        if (self.player_state == PS_ALTFIRE)
            player_altshot1 ();
        else
            player_akshot1 ();
    }
    else
    {
        player_shot1 ();
        Shot_Fire ();
    }
};


/*
============
Shot_Draw

Draw code for the sawed-off
============
*/
void() Shot_Draw =
{
    self.weapon = IT_SAWED_OFF;
    self.currentammo = self.ammo_shells;
    self.items = (self.items - (self.items & (IT_NAILS | IT_CELLS | IT_ROCKETS))) | IT_SHELLS;

    Shot_UpdateView ();

    self.attack_finished = time + 0.5;
    if (self.items & IT_GUNS_AKIMBO)
        player_akshotdraw1 ();
    else
        player_shotdraw1 ();
};


/*
============
Shot_Holster

Holster code for the sawed-off
============
*/
void() Shot_Holster =
{
    self.attack_finished = time + 0.5;
    if (self.items & IT_GUNS_AKIMBO)
        player_akshotholster1 ();
    else
        player_shotholster1 ();
};


/*
============
Shot_UpdateView

Choose the right sawed-off model to display
============
*/
void() Shot_UpdateView =
{
    if (self.akimbo_finished > time && self.currentammo >= 2)
    {
        self.weaponmodel = "progs/v_ashot2.mdl";
        self.items = self.items | IT_GUNS_AKIMBO;
    }
    else
    {
        self.weaponmodel = "progs/v_shot2.mdl";
        self.items = self.items - (self.items & IT_GUNS_AKIMBO);
    }
};
