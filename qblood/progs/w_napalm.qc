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


void() Napalm_Fire;


//============================================================================

// ----- Napalm launcher models ----- //

// Normal model
$modelname v_rock2

// idle
$frame napalm_idle1

// fire
$frame napalm_fire1 napalm_fire2 napalm_fire3 napalm_fire4 napalm_fire5
$frame napalm_fire6

// altfire
$frame napalm_alt1 napalm_alt2 napalm_alt3 napalm_alt4 napalm_alt5
$frame napalm_alt6

// draw
$frame napalm_draw1 napalm_draw2 napalm_draw3 napalm_draw4

// holster
$frame napalm_holster1 napalm_holster2 napalm_holster3 napalm_holster4


// Akimbo model
$modelname v_arock2

// idle
$frame anapalm_idle1

// fire
$frame anapalm_fire1 anapalm_fire2 anapalm_fire3 anapalm_fire4 anapalm_fire5
$frame anapalm_fire6 anapalm_fire7 anapalm_fire8

// altfire
$frame anapalm_alt1  anapalm_alt2  anapalm_alt3  anapalm_alt4  anapalm_alt5
$frame anapalm_alt6  anapalm_alt7  anapalm_alt8

// draw
$frame anapalm_draw1 anapalm_draw2 anapalm_draw3

// holster
$frame anapalm_holstr1 anapalm_holstr2 anapalm_holstr3


// ----- Player related code ----- //

// Normal fire
void() player_napalm1 = [$attack1, player_napalm2] { self.weaponframe = $napalm_fire2; muzzleflash (); };
void() player_napalm2 = [$attack1, player_napalm3] { self.weaponframe = $napalm_fire3; };
void() player_napalm3 = [$attack1, player_napalm4] { self.weaponframe = $napalm_fire4; };
void() player_napalm4 = [$attack2, player_napalm5] { self.weaponframe = $napalm_fire5; };
void() player_napalm5 = [$attack2, player_run    ] { self.weaponframe = $napalm_fire6; };

// Akimbo fire
void() player_aknapalm1 = [$attack1, player_aknapalm2] { self.weaponframe = $anapalm_fire2; muzzleflash (); };
void() player_aknapalm2 = [$attack2, player_aknapalm3] { self.weaponframe = $anapalm_fire3; };
void() player_aknapalm3 = [$attack1, player_aknapalm4] { self.weaponframe = $anapalm_fire4; muzzleflash ();  Napalm_Fire (); };
void() player_aknapalm4 = [$attack1, player_aknapalm5] { self.weaponframe = $anapalm_fire5; };
void() player_aknapalm5 = [$attack2, player_aknapalm6] { self.weaponframe = $anapalm_fire6; };
void() player_aknapalm6 = [$attack2, player_run      ]
{
    // If we don't have enough ammo anymore, drop the guns akimbo
    if ((self.items & IT_GUNS_AKIMBO) && self.currentammo < 2)
    {
        Napalm_UpdateView ();
        self.weaponframe = $anapalm_fire1;
    }
    else
        self.weaponframe = $anapalm_fire7;
};

// Normal draw
void() player_napalmdraw1 = [$attack2, player_napalmdraw2] { self.weaponframe = $napalm_draw1; };
void() player_napalmdraw2 = [$attack2, player_napalmdraw3] { self.weaponframe = $napalm_draw2; };
void() player_napalmdraw3 = [$attack2, player_napalmdraw4] { self.weaponframe = $napalm_draw3; };
void() player_napalmdraw4 = [$attack2, player_run        ] { self.weaponframe = $napalm_draw4; };

// Normal holster
void() player_napalmholst1 = [$attack2, player_napalmholst2] { self.weaponframe = $napalm_holster1; };
void() player_napalmholst2 = [$attack2, player_napalmholst3] { self.weaponframe = $napalm_holster2; };
void() player_napalmholst3 = [$attack2, player_napalmholst4] { self.weaponframe = $napalm_holster3; };
void() player_napalmholst4 = [$attack2, player_napalmholst5] { self.weaponframe = $napalm_holster4; };
void() player_napalmholst5 = [$attack2, player_run         ] { W_DrawWeapon (self.newweapon); };

// Akimbo draw
void() player_aknapalmdraw1 = [$attack2, player_aknapalmdraw2] { self.weaponframe = $anapalm_draw1; };
void() player_aknapalmdraw2 = [$attack2, player_aknapalmdraw3] { self.weaponframe = $anapalm_draw2; };
void() player_aknapalmdraw3 = [$attack2, player_run          ] { self.weaponframe = $anapalm_draw3; };

// Akimbo holster
void() player_aknapalmholst1 = [$attack2, player_aknapalmholst2] { self.weaponframe = $anapalm_holstr1; };
void() player_aknapalmholst2 = [$attack2, player_aknapalmholst3] { self.weaponframe = $anapalm_holstr2; };
void() player_aknapalmholst3 = [$attack2, player_aknapalmholst4] { self.weaponframe = $anapalm_holstr3; };
void() player_aknapalmholst4 = [$attack2, player_run           ] { W_DrawWeapon (self.newweapon); };


//============================================================================

void() Napalm_BallTouch;

/*
================
Napalm_ThrowBouncingBall

Activate the split function of a napalm ball

NOTE: we must do that because the balls are spawned at the same position
      and near walls or floor, so they would explode as soon as they spawn.
================
*/
void() Napalm_ActivateBall =
{
    // We "save" the velocity in the "angles" field
    // right after the bounce
    self.angles = vectoangles (self.velocity);

    self.touch = Napalm_BallTouch;
};


/*
================
Napalm_ThrowBouncingBall

Throw a bouncing napalm ball

NOTE: a few fields ("velocity", "origin" and "cnt") must be set by the caller
================
*/
void(entity newball) Napalm_ThrowBouncingBall =
{
    #ifdef QUAKEWORLD
    newball.voided=0;
    #endif
    // Remember who really owns the ball.
    if (self.owner)
        newball.owner = self.owner;
    else
        newball.owner = self;
    newball.movetype = MOVETYPE_BOUNCE;
    newball.solid = SOLID_BBOX;
    newball.classname = "grenade";

    newball.netname = "Napalm Ball";
    newball.dmg = 120;

    newball.nextthink = time + 0.1;
    newball.think = Napalm_ActivateBall;

    setmodel (newball, "progs/naltball.mdl");
    setsize (newball, '0 0 0', '0 0 0');
};


/*
================
T_MissileTouch

Touch function for the rockets
================
*/
void() T_MissileTouch =
{
    if (other == self.owner)
        return;     // don't explode on owner

    #ifdef QUAKEWORLD
    if (self.voided) {
        return;
    }
    self.voided = 1;
    #endif

    if (pointcontents(self.origin) == CONTENT_SKY)
    {
        remove(self);
        return;
    }

    self.deathtype = "missile";  // Done for the fire code.
    if (other.health)
    {
        other.deathtype = "missile";
        BurnDamage (other, self, self.dmg*0.75, DF_FIRE, self.dmg*0.25);
    }

    // don't do radius damage to the other, because all the damage
    // was done in the impact
    BurnRadius (self, 90, 30, other);

    ThrowEmbers (4);
    MakeBlastDamage (self, 160, 20, 10);
    PsychoCaleb (self.owner);

    self.origin = self.origin - 8 * normalize (self.velocity);

    #ifdef QUAKEWORLD
    WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
    WriteByte (MSG_MULTICAST, TE_EXPLOSION);
    WriteCoord (MSG_MULTICAST, self.origin_x);
    WriteCoord (MSG_MULTICAST, self.origin_y);
    WriteCoord (MSG_MULTICAST, self.origin_z);
    multicast (self.origin, MULTICAST_PHS);
    remove(self);

    #else
    WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
    WriteByte (MSG_BROADCAST, TE_EXPLOSION);
    WriteCoord (MSG_BROADCAST, self.origin_x);
    WriteCoord (MSG_BROADCAST, self.origin_y);
    WriteCoord (MSG_BROADCAST, self.origin_z);
    BecomeExplosion ();
    #endif
};


/*
================
Napalm_BallTouch

Touch function for the bouncing ball
================
*/
void() Napalm_BallTouch =
{
    if (self.cnt > 1)
    {
        local entity newball;
        local vector neworigin;

        // "self.angles" allows us to recover the original direction
        makevectors (self.angles);

        neworigin = self.origin - 8 * normalize (self.velocity);

        newmis = spawn ();
        newmis.cnt = floor (self.cnt / 2);
        self.cnt = self.cnt - newmis.cnt;
        newmis.velocity = v_forward * 500 + v_right * 100;
        newmis.velocity_z = random() * 100 + 300;
        Napalm_ThrowBouncingBall (newmis);
        setorigin (newmis, neworigin);

        newball = spawn ();
        newball.cnt = self.cnt;
        newball.velocity = v_forward * 500 - v_right * 100;
        newball.velocity_z = random() * 100 + 300;
        Napalm_ThrowBouncingBall (newball);
        setorigin (newball, neworigin);
    }

    T_MissileTouch ();
};


/*
================
Napalm_Fire

Shot a napalm ball
================
*/
void() Napalm_Fire =
{
    sound (self, CHAN_WEAPON, "weapons/napalm/blaster.wav", 1, ATTN_NORM);

    #ifdef QUAKEWORLD
    msg_entity = self;
    WriteByte (MSG_ONE, SVC_SMALLKICK);
    #else
    self.punchangle_x = -2;
    #endif

    newmis = spawn ();

    makevectors (self.v_angle);
    newmis.velocity = aim (self, 1000);  // base velocity

    if (self.player_state == PS_ALTFIRE)
    {
        // set the number of bouncing balls
        if (self.ammo_rockets > 12)
            newmis.cnt = 12;
        else
            newmis.cnt = self.ammo_rockets;
        self.ammo_rockets = self.ammo_rockets - newmis.cnt;
        newmis.velocity = newmis.velocity * 500 + '0 0 200';

        Napalm_ThrowBouncingBall (newmis);
    }
    else
    {
        newmis.owner = self;
        newmis.solid = SOLID_BBOX;
        newmis.classname = "missile";
        #ifdef QUAKEWORLD
        newmis.voided = 0;
        #endif
        newmis.angles = vectoangles(newmis.velocity);

        newmis.movetype = MOVETYPE_FLYMISSILE;
        newmis.velocity = newmis.velocity * 1500;
        self.ammo_rockets = self.ammo_rockets - 1;

        newmis.touch = T_MissileTouch;
        setmodel (newmis, "progs/missile.mdl");
        setsize (newmis, '0 0 0', '0 0 0');

        newmis.dmg = 75 + random () * 50;

        // set newmis duration
        newmis.nextthink = time + 5;
        newmis.think = SUB_Remove;
    }
    self.currentammo = self.ammo_rockets;
    setorigin (newmis, self.origin + v_forward * 8 + '0 0 16');
};


/*
============
Napalm_Attack

Attack code for the napalm launcher
============
*/
void() Napalm_Attack =
{
    // Normal fire or altfire?
    if (self.impulse == 12 || self.button3)
        self.player_state = PS_ALTFIRE;
    else
        self.player_state = PS_FIRE;

    // If we have guns akimbo
    if (self.items & IT_GUNS_AKIMBO)
    {
        player_aknapalm1 ();
        self.attack_finished = time + 0.6;
    }
    else
    {
        player_napalm1 ();
        self.attack_finished = time + 0.5;
    }

    Napalm_Fire ();
};


/*
============
Napalm_Draw

Draw code for the napalm launcher
============
*/
void() Napalm_Draw =
{
    self.weapon = IT_NAPALM_LAUNCHER;
    self.currentammo = self.ammo_rockets;
    self.items = (self.items - (self.items & (IT_SHELLS | IT_NAILS | IT_CELLS))) | IT_ROCKETS;

    Napalm_UpdateView ();

    if (self.items & IT_GUNS_AKIMBO)
    {
        self.attack_finished = time + 0.4;
        player_aknapalmdraw1 ();
    }
    else
    {
        self.attack_finished = time + 0.5;
        player_napalmdraw1 ();
    }
};


/*
============
Napalm_Holster

Holster code for the napalm launcher
============
*/
void() Napalm_Holster =
{
    if (self.items & IT_GUNS_AKIMBO)
    {
        self.attack_finished = time + 0.4;
        player_aknapalmholst1 ();
    }
    else
    {
        self.attack_finished = time + 0.5;
        player_napalmholst1 ();
    }
};


/*
============
Napalm_UpdateView

Choose the right napalm launcher model to display
============
*/
void() Napalm_UpdateView =
{
    if (self.akimbo_finished > time && self.currentammo >= 2)
    {
        self.weaponmodel = "progs/v_arock2.mdl";
        self.items = self.items | IT_GUNS_AKIMBO;
    }
    else
    {
        self.weaponmodel = "progs/v_rock2.mdl";
        self.items = self.items - (self.items & IT_GUNS_AKIMBO);
    }
};
