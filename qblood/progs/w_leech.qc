/*  Copyright (C) 2001 Dave Turner

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


void() Leech_BallFire;


//=======================================================================

// ------------ Life Leech models ---------- //

// Normal model
$modelname v_leech

// idle
$frame leech_idle1

// fire
$frame leech_fire1  leech_fire2  leech_fire3  leech_fire4  leech_fire5
$frame leech_fire6  leech_fire7  leech_fire8  leech_fire9  leech_fire10
$frame leech_fire11 leech_fire12 leech_fire13 leech_fire14 leech_fire15
$frame leech_fire16 leech_fire17 leech_fire18 leech_fire19 leech_fire20
$frame leech_fire21 leech_fire22 leech_fire23 leech_fire24 leech_fire25

// draw
$frame leech_draw1 leech_draw2 leech_draw3

// holster
$frame leech_holster1 leech_holster2 leech_holster3


// ------------ Player related code ---------- //

// Normal fire
void() player_leech1  = [$shotatt1, player_leech2 ]
{
    sound (self, CHAN_WEAPON, "weapons/lifelech/laltfr1.wav", 1, ATTN_NORM);
    self.weaponframe = $leech_fire1;
};
void() player_leech2  = [$rockatt2, player_leech3 ] { self.weaponframe = $leech_fire2;  };
void() player_leech3  = [$rockatt3, player_leech4 ] { self.weaponframe = $leech_fire3;  };
void() player_leech4  = [$rockatt4, player_leech5 ] { self.weaponframe = $leech_fire4;  };
void() player_leech5  = [$rockatt5, player_leech6 ] { self.weaponframe = $leech_fire5;  Leech_BallFire (); };
void() player_leech6  = [$rockatt1, player_leech7 ] { self.weaponframe = $leech_fire6;  };
void() player_leech7  = [$rockatt2, player_leech8 ] { self.weaponframe = $leech_fire7;  };
void() player_leech8  = [$rockatt3, player_leech9 ] { self.weaponframe = $leech_fire8;  Leech_BallFire (); };
void() player_leech9  = [$rockatt4, player_leech10] { self.weaponframe = $leech_fire9;  };
void() player_leech10 = [$rockatt5, player_leech11] { self.weaponframe = $leech_fire10; };
void() player_leech11 = [$rockatt1, player_leech12] { self.weaponframe = $leech_fire11; Leech_BallFire (); };
void() player_leech12 = [$rockatt2, player_leech13] { self.weaponframe = $leech_fire12; };
void() player_leech13 = [$rockatt3, player_leech14] { self.weaponframe = $leech_fire13; };
void() player_leech14 = [$rockatt4, player_leech15] { self.weaponframe = $leech_fire14; Leech_BallFire (); };
void() player_leech15 = [$rockatt5, player_leech16] { self.weaponframe = $leech_fire15; };
void() player_leech16 = [$rockatt1, player_leech17] { self.weaponframe = $leech_fire16; Leech_BallFire (); };
void() player_leech17 = [$rockatt2, player_leech18] { self.weaponframe = $leech_fire17; };
void() player_leech18 = [$rockatt3, player_leech19] { self.weaponframe = $leech_fire18; };
void() player_leech19 = [$rockatt4, player_leech20] { self.weaponframe = $leech_fire19; Leech_BallFire (); };
void() player_leech20 = [$rockatt5, player_leech21] { self.weaponframe = $leech_fire20; };
void() player_leech21 = [$rockatt1, player_leech22] { self.weaponframe = $leech_fire21; };
void() player_leech22 = [$rockatt2, player_leech23] { self.weaponframe = $leech_fire22; Leech_BallFire (); };
void() player_leech23 = [$rockatt3, player_leech24] { self.weaponframe = $leech_fire23; };
void() player_leech24 = [$rockatt4, player_leech25] { self.weaponframe = $leech_fire24; };
void() player_leech25 = [$rockatt5, player_run    ] { self.weaponframe = $leech_fire25; };

// Normal draw
void() player_leechdraw1 = [$rockatt1, player_leechdraw2] { self.weaponframe = $leech_draw1; };
void() player_leechdraw2 = [$rockatt1, player_leechdraw3] { self.weaponframe = $leech_draw2; };
void() player_leechdraw3 = [$rockatt1, player_run       ] { self.weaponframe = $leech_draw3; };

// Normal holster
void() player_leechholster1 = [$rockatt1, player_leechholster2] { self.weaponframe = $leech_holster1; };
void() player_leechholster2 = [$rockatt1, player_leechholster3] { self.weaponframe = $leech_holster2; };
void() player_leechholster3 = [$rockatt1, player_leechholster4] { self.weaponframe = $leech_holster3; };
void() player_leechholster4 = [$rockatt1, player_run          ] { W_DrawWeapon (self.newweapon); };


//=================================================================

/*
=========================
Leech_BallFire

Fire a Life Leech ball
=========================
*/
void() Leech_BallFire =
{
    #ifdef QUAKEWORLD
    msg_entity = self;
    WriteByte (MSG_ONE, SVC_SMALLKICK);
    #else
    self.punchangle_x = -2;
    #endif
    muzzleflash ();

    newmis = spawn ();

    makevectors (self.v_angle);
    newmis.velocity = aim (self, 1000);  // base velocity

    newmis.owner = self;
    newmis.solid = SOLID_BBOX;
    newmis.classname = "rocket";
    #ifdef QUAKEWORLD
    newmis.voided = 0;
    #endif
    newmis.angles = vectoangles(newmis.velocity);
    newmis.movetype = MOVETYPE_FLYMISSILE;
    newmis.velocity = 1500 * (newmis.velocity + crandom()*0.18*v_right + crandom()*0.08*v_up);

    // If we don't have enough ammo, use HP
    if (self.ammo_leech < 2)
    {
        T_Damage (self, world, world, 2 - self.ammo_leech, DF_MIND, "leech");
        self.ammo_leech = 0;
    }
    else
        self.ammo_leech = self.ammo_leech - 2;
    self.currentammo = self.ammo_leech;

    newmis.touch = T_MissileTouch;
    setmodel (newmis, "progs/lechball.mdl");
    setsize (newmis, '0 0 0', '0 0 0');
    setorigin (newmis, self.origin + v_forward * 8 + '0 0 16');

    self.dmg = 20;

    // set newmis duration
    newmis.nextthink = time + 5;
    newmis.think = SUB_Remove;
};


/*
==================
Leech_Drop

Drop the Life Leech as a solid staff (altfire)
==================
*/
void() Leech_Drop =
{
    local entity item;

    makevectors (self.v_angle);

    // Drop the Life Leech
    item = spawn();
    setmodel (item, "progs/g_leech.mdl");
    setsize (item, '-5 -5 0', '5 7 41');

    item.solid = SOLID_BBOX;
    item.takedamage = DAMAGE_AIM;
    item.health = 500;

    item.origin = self.origin + '0 0 12';
    item.velocity = aim (self, 1000) * 50;
    item.velocity_z = 150;
    item.movetype = MOVETYPE_TOSS;

    // remove after 20 minutes
    item.nextthink = time + 1200;
    item.think = SUB_Remove;

    item.touch = SUB_SolidTouch;
    item.th_die = SUB_Remove;

    // Dropping it requiers 25 ammo/HP
    if (self.ammo_leech < 25)
        T_Damage (self, world, world, 25 - self.ammo_leech, DF_MIND, "leech");
    self.currentammo = self.ammo_leech = 0;
    self.items = self.items - self.weapon;

    // If we're still alive
    if (!self.deadflag)
    {
        self.newweapon = W_BestWeapon();
        W_DrawWeapon (self.newweapon);
    }
};


/*
======================
Leech_Attack

Life Leech Attack Code
======================
*/
void() Leech_Attack =
{
    // Normal fire or altfire?
    if (self.impulse == 12 || self.button1)
    {
        self.player_state = PS_ALTFIRE;

        Leech_Drop ();
        self.attack_finished = time + 0.1;
    }
    else
    {
        self.player_state = PS_FIRE;

        player_leech1 ();
        self.attack_finished = time + 2.6;
    }
};


/*
============
Leech_Draw

Draw code for the life leech
============
*/
void() Leech_Draw =
{
    self.weapon = IT_LIFE_LEECH;
    self.currentammo = self.ammo_leech;
    self.items = (self.items - (self.items & (IT_SHELLS | IT_NAILS | IT_CELLS | IT_ROCKETS)));

    Leech_UpdateView ();

    self.attack_finished = time + 0.1;
    player_leechdraw1 ();
};


/*
============
Leech_Holster

Holster code for the life leech
============
*/
void() Leech_Holster =
{
    self.attack_finished = time + 0.1;
    player_leechholster1 ();
};


/*
============
Leech_UpdateView

Choose the right life leech model to display
============
*/
void() Leech_UpdateView =
{
    self.weaponmodel = "progs/v_leech.mdl";
    self.items = self.items - (self.items & IT_GUNS_AKIMBO);
};
