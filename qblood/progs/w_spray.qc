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


void() Spray_Fire;


//============================================================================

// ----- Spray Can model ----- //

$modelname v_aerosol

// idle
$frame spray_idle1 spray_idle2 spray_idle3

// draw
$frame spray_draw1 spray_draw2 spray_draw3 spray_draw4 spray_draw5
$frame spray_draw6 spray_draw7 spray_draw8

// draw_half
$frame spray_drawhlf1 spray_drawhlf2 spray_drawhlf3

// alt
$frame spray_alt1 spray_alt2 spray_alt3 spray_alt4 spray_alt5
$frame spray_alt6 spray_alt7 spray_alt8 spray_alt9

// throw
$frame spray_throw1 spray_throw2 spray_throw3 spray_throw4 spray_throw5
$frame spray_throw6 spray_throw7

// holster
$frame spray_holster1 spray_holster2 spray_holster3

// holster_half
$frame spray_holsthlf1 spray_holsthlf2 spray_holsthlf3

// fire
$frame spray_fire1 spray_fire2 spray_fire3


// ----- Player related code ----- //

void() player_spray =
{
    if (!self.button0 || intermission_running || self.ammo_spray < 1)
    {
        // Stop the fire sound
        sound (self, CHAN_WEAPON, "misc/null.wav", 0, ATTN_NORM);
        self.t_width = 0;

        player_run ();
        return;
    }

    // Start the fire sound if necessary
    if (self.t_width <= time)
    {
        sound (self, CHAN_WEAPON, "weapons/spraycan/sprayfir.wav", 0.5, ATTN_NORM);
        self.t_width = time + 2.5;
    }

    muzzleflash ();

    self.weaponframe = self.weaponframe + 1;
    if (self.weaponframe > $spray_fire3)
        self.weaponframe = $spray_fire1;

    Spray_Fire ();
    self.attack_finished = time + 0.2;
};

void() player_spray1 = [$attack1, player_spray2] { player_spray (); };
void() player_spray2 = [$attack1, player_spray1] { player_spray (); };

void() player_lightcan1 = [$attack2, player_lightcan2] { self.weaponframe = $spray_alt1; };
void() player_lightcan2 = [$attack2, player_lightcan3] { self.weaponframe = $spray_alt2; };
void() player_lightcan3 = [$attack2, player_lightcan4] { self.weaponframe = $spray_alt3; };
void() player_lightcan4 = [$attack2, player_lightcan5] { self.weaponframe = $spray_alt4; };
void() player_lightcan5 = [$attack2, player_lightcan6] { self.weaponframe = $spray_alt5; };
void() player_lightcan6 = [$attack1, player_lightcan7] { self.weaponframe = $spray_alt6; };
void() player_lightcan7 = [$attack1, player_lightcan8] { self.weaponframe = $spray_alt7; };
void() player_lightcan8 = [$attack1, player_lightcan9] { self.weaponframe = $spray_alt8; };
void() player_lightcan9 = [$attack1, player_lightcan7] { self.weaponframe = $spray_alt9; };

void() player_altspray1 = [$attack2, player_altspray2] { self.weaponframe = $spray_throw1; };
void() player_altspray2 = [$attack2, player_altspray3] { self.weaponframe = $spray_throw2; };
void() player_altspray3 = [$attack2, player_altspray4] { self.weaponframe = $spray_throw3; };
void() player_altspray4 = [$attack2, player_altspray5] { self.weaponframe = $spray_throw4; };
void() player_altspray5 = [$attack2, player_altspray6] { self.weaponframe = $spray_throw5; };
void() player_altspray6 = [$attack2, player_altspray7]
{
    self.weaponframe = $spray_throw6;
    Bomb_Fire ();
    Bomb_Uncharge ();
    ShowThrowMeter ();
};
void() player_altspray7 = [$attack2, player_run] { self.weaponframe = $spray_throw7; };

// Half draw
void() player_sprayhalfdraw1 = [$attack2, player_sprayhalfdraw2] { self.weaponframe = $spray_drawhlf1; };
void() player_sprayhalfdraw2 = [$attack2, player_sprayhalfdraw3] { self.weaponframe = $spray_drawhlf2; };
void() player_sprayhalfdraw3 = [$attack2, player_run           ] { self.weaponframe = $spray_drawhlf3; };

// Normal draw
void() player_spraydraw1 = [$attack2, player_spraydraw2] { self.weaponframe = $spray_draw1; };
void() player_spraydraw2 = [$attack2, player_spraydraw3] { self.weaponframe = $spray_draw2; };
void() player_spraydraw3 = [$attack2, player_run       ] { self.weaponframe = $spray_draw3; };

// Half holster
void() player_sprayhalfholster1 = [$attack2, player_sprayhalfholster2] { self.weaponframe = $spray_holsthlf1; };
void() player_sprayhalfholster2 = [$attack2, player_sprayhalfholster3] { self.weaponframe = $spray_holsthlf2; };
void() player_sprayhalfholster3 = [$attack2, player_sprayhalfholster4] { self.weaponframe = $spray_holsthlf3; };
void() player_sprayhalfholster4 = [$attack2, player_run              ] { W_DrawWeapon (self.newweapon); };

// Normal holster
void() player_sprayholster1 = [$attack2, player_sprayholster2] { self.weaponframe = $spray_holster1; };
void() player_sprayholster2 = [$attack2, player_sprayholster3] { self.weaponframe = $spray_holster2; };
void() player_sprayholster3 = [$attack2, player_sprayholster4] { self.weaponframe = $spray_holster3; };
void() player_sprayholster4 = [$attack2, player_run          ] { W_DrawWeapon (self.newweapon); };


//============================================================================

/*
============
Spray_Fire

Send a fire cloud
============
*/
void() Spray_Fire =
{
    local vector    dir;
    local entity    old;

    if (self.ammo_spray < 1)
        return;

    makevectors (self.v_angle);

    self.attack_finished = time + 0.2;
    self.currentammo = self.ammo_spray = self.ammo_spray - 1;
    dir = aim (self, 1000);

    newmis = spawn ();
    newmis.owner = self;
    newmis.movetype = MOVETYPE_FLYMISSILE;
    newmis.solid = SOLID_BBOX;
    newmis.alpha = 0.6;
    newmis.effects = EF_ADDITIVE;

    newmis.angles = vectoangles(dir);

    newmis.touch = flame_touch;
    newmis.classname = "spike";
    newmis.reset = SUB_Remove;
    newmis.think = SUB_Remove;
    newmis.nextthink = time + 0.6;
    setmodel (newmis, "progs/sprayfir.spr");
    setsize (newmis, '-1 -1 -1', '1 1 1');
    setorigin (newmis, self.origin + '0 0 10' + v_forward * 50 + v_right * 8);

    newmis.velocity = dir * 550;

    newmis.frame = floor (random () * 3);
};


/*
============
Spray_Attack

Attack code for the spray can
============
*/
void() Spray_Attack =
{
    self.player_state = PS_FIRE;

    // Altfire
    if (self.tnt_time)
    {
        self.attack_finished = time + 1.0;
        player_altspray1 ();
    }
    else
    {
        self.weaponframe = $spray_fire1 - 1;
        player_spray1 ();
    }
};


/*
============
Spray_Draw

Draw code for the spray can
============
*/
void() Spray_Draw =
{
    self.currentammo = self.ammo_spray;
    self.items = (self.items - (self.items & (IT_NAILS | IT_SHELLS | IT_CELLS | IT_ROCKETS)));

    Spray_UpdateView ();

    self.attack_finished = time + 0.9;

    // If we need to pop up the lighter
    if (self.weapon != IT_TNT)
    {
        sound (self, CHAN_WEAPON, "weapons/tnt/lighter.wav", 1, ATTN_NORM);
        player_spraydraw1 ();
    }
    else
        player_sprayhalfdraw1 ();

    self.weapon = IT_SPRAY_CAN;
};


/*
============
Spray_Holster

Holster code for the spray can
============
*/
void() Spray_Holster =
{
    self.attack_finished = time + 0.4;

    // If we need to close the lighter
    if (self.newweapon != IT_TNT)
    {
        sound (self, CHAN_WEAPON, "weapons/tnt/zipclose.wav", 1, ATTN_NORM);
        player_sprayholster1 ();
    }
    else
        player_sprayhalfholster1 ();
};


/*
============
Spray_UpdateView

Choose the right spray can model to display
============
*/
void() Spray_UpdateView =
{
    self.weaponmodel = "models/weapons/v_aerosol.md3";
    self.items = self.items - (self.items & IT_GUNS_AKIMBO);
};
