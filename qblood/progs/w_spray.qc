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


void() Spray_Fire;


//============================================================================

// ----- Spray Can model ----- //

$modelname v_nail2

// idle (animation; 3 frames)
$frame spray_idle1 /* idle2 idle3 */

// fire
$frame spray_fire1

// alt
$frame spray_alt1  spray_alt2 spray_alt3 spray_alt4 spray_alt5
$frame spray_alt6  spray_alt7 spray_alt8 spray_alt9 spray_alt10
$frame spray_alt11

// draw
$frame spray_draw1 spray_draw2 spray_draw3 spray_draw4 spray_draw5
$frame spray_draw6 spray_draw7 spray_draw8

// draw_half
$frame spray_drawhlf1 spray_drawhlf2 spray_drawhlf3 spray_drawhlf4

// holster
$frame spray_holster1 spray_holster2 spray_holster3 spray_holster4

// holster_half
$frame spray_holsthlf1 spray_holsthlf2 spray_holsthlf3 spray_holsthlf4


// ----- Player related code ----- //

void() player_supernail =
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

    self.weaponframe = $spray_fire1;

    Spray_Fire ();
    self.attack_finished = time + 0.2;
};

void() player_supernail1 = [$nailatt1, player_supernail2] { player_supernail (); };
void() player_supernail2 = [$nailatt2, player_supernail1] { player_supernail (); };

void() player_lightcan1 = [$shotatt1, player_lightcan2] { self.weaponframe = $spray_alt1; self.player_state = PS_HOLD_FIRE; };
void() player_lightcan2 = [$shotatt1, player_lightcan3] { self.weaponframe = $spray_alt2; };
void() player_lightcan3 = [$shotatt1, player_lightcan4] { self.weaponframe = $spray_alt3; };
void() player_lightcan4 = [$shotatt1, player_lightcan5] { self.weaponframe = $spray_alt4; };
void() player_lightcan5 = [$shotatt1, player_lightcan6] { self.weaponframe = $spray_alt5; };
void() player_lightcan6 = [$shotatt1, player_lightcan4] { self.weaponframe = $spray_alt6; };

void() player_altsupernail1 = [$shotatt1, player_altsupernail2] { self.weaponframe = $spray_alt7; };
void() player_altsupernail2 = [$shotatt1, player_altsupernail3] { self.weaponframe = $spray_alt8; };
void() player_altsupernail3 = [$shotatt1, player_altsupernail4] { self.weaponframe = $spray_alt9; };
void() player_altsupernail4 = [$shotatt1, player_altsupernail5]
{
    self.weaponframe = $spray_alt10;
    W_FireGrenade ();
    W_Uncharge ();
    ShowThrowMeter ();
};
void() player_altsupernail5 = [$shotatt1, player_run] { self.weaponframe = $spray_alt11; };


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

    self.attack_finished = time + 0.2;
    self.currentammo = self.ammo_spray = self.ammo_spray - 1;
    dir = aim (self, 1000);

    newmis = spawn ();
    #ifdef QUAKEWORLD
    newmis.voided=0;
    #endif
    newmis.owner = self;
    newmis.movetype = MOVETYPE_FLYMISSILE;  // use MOVETYPE_NOCLIP for free move
    newmis.solid = SOLID_BBOX;

    newmis.angles = vectoangles(dir);

    newmis.touch = flame_touch;
    newmis.classname = "spike";
    newmis.think = SUB_Remove;
    newmis.nextthink = time + 0.6;
    setmodel (newmis, "progs/sprayfir.spr");
    setsize (newmis, '-5 -5 -7', '5 5 7');
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
    // Altfire
    if (self.tnt_time)
    {
        self.attack_finished = time + 0.6;
        player_altsupernail1 ();
    }
    else
    {
        self.player_state = PS_FIRE;
        player_supernail1 ();
    }
};
