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


void() Napalm_Fire;


//============================================================================

// ----- Napalm launcher models ----- //

// Normal model
$modelname v_rock2

// fire (0 -> 5)
$frame napalm_fire1 napalm_fire2 napalm_fire3 napalm_fire4 napalm_fire5
$frame napalm_fire6

// altfire (6 -> 11)
$frame napalm_alt1 napalm_alt2 napalm_alt3 napalm_alt4 napalm_alt5
$frame napalm_alt6


// Akimbo model
$modelname v_arock2

// idle (0)
$frame anapalm_idle1

// fire (1 -> 8)
$frame anapalm_fire1 anapalm_fire2 anapalm_fire3 anapalm_fire4 anapalm_fire5
$frame anapalm_fire6 anapalm_fire7 anapalm_fire8

// altfire (9 -> 16)
$frame anapalm_alt1  anapalm_alt2  anapalm_alt3  anapalm_alt4  anapalm_alt5
$frame anapalm_alt6  anapalm_alt7  anapalm_alt8

// draw (17 -> 19)
$frame anapalm_draw1 anapalm_draw2 anapalm_draw3

// holster (20 -> 22)
$frame anapalm_holstr1 anapalm_holstr2 anapalm_holstr3


// ----- Player related code ----- //

// Normal fire
void() player_napalm1 = [$rockatt1, player_napalm2] { self.weaponframe = $napalm_fire2; muzzleflash (); };
void() player_napalm2 = [$rockatt2, player_napalm3] { self.weaponframe = $napalm_fire3; };
void() player_napalm3 = [$rockatt3, player_napalm4] { self.weaponframe = $napalm_fire4; };
void() player_napalm4 = [$rockatt4, player_napalm5] { self.weaponframe = $napalm_fire5; };
void() player_napalm5 = [$rockatt5, player_run    ] { self.weaponframe = $napalm_fire6; };

// Akimbo mode
void() player_aknapalm1 = [$rockatt1, player_aknapalm2] { self.weaponframe = $anapalm_fire2; muzzleflash (); };
void() player_aknapalm2 = [$rockatt2, player_aknapalm3] { self.weaponframe = $anapalm_fire3; };
void() player_aknapalm3 = [$rockatt1, player_aknapalm4] { self.weaponframe = $anapalm_fire4; Napalm_Fire (); };
void() player_aknapalm4 = [$rockatt2, player_aknapalm5] { self.weaponframe = $anapalm_fire5; };
void() player_aknapalm5 = [$rockatt3, player_aknapalm6] { self.weaponframe = $anapalm_fire6; };
void() player_aknapalm6 = [$rockatt5, player_run      ]
{
    // If we don't have enough ammo anymore, drop the guns akimbo
    if ((self.items & IT_GUNS_AKIMBO) && self.currentammo < 2)
    {
        W_SetCurrentAmmo (FALSE, 0);
        self.weaponframe = $anapalm_fire1;
    }
    else
        self.weaponframe = $anapalm_fire7;
};


//============================================================================

void() Napalm_BallTouch;

/*
================
Napalm_ThrowBouncingBall

Activate the split function of a napalm ball

NOTE: we must do that because we spawn them just besides walls,
      so they explode as soon as they spawn.
================
*/
void() Napalm_ActivateBall =
{
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

    newball.angles = vectoangles(newball.velocity);

    newball.netname = "Napalm Ball";
    newball.dmg = 120;

    newball.nextthink = time + 0.1;
    newball.think = Napalm_ActivateBall;

    setmodel (newball, "progs/naltball.mdl");
    setsize (newball, '-2 -2 -2', '2 2 2');
};


/*
================
T_MissileTouch

Touch function for the rockets

NOTE: also used by the "boss" monster
================
*/
void() T_MissileTouch =
{
    local float damg;
    local float ind;

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

    damg = 75 + random()*50;

    self.deathtype = "rocket";  // Done for the fire code.
    if (other.health)
    {
        other.deathtype = "rocket";
        if (other.classname == "monster_shambler")
            damg = damg * 0.5;  // mostly immune
        PM_BurnDamage (other, self, damg*0.75, damg*0.25);
    }

    // don't do radius damage to the other, because all the damage
    // was done in the impact
    BurnRadius (self, 90, 30, other);

    ThrowEmbers (8);
    MakeBlastDamage (self, 160, 20, 10);
    PsychoCaleb (self.owner);

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

        newmis = spawn ();
        newmis.cnt = floor (self.cnt / 2);
        self.cnt = self.cnt - newmis.cnt;
        newmis.velocity = v_forward * 500 + v_right * 100;
/*        newmis.velocity_x = random() * 150 + 150;
        newmis.velocity_y = random() * 150 + 150;*/
        newmis.velocity_z = random() * 150 + 150;
        Napalm_ThrowBouncingBall (newmis);
        setorigin (newmis, self.origin - 8 * v_forward);

        newball = spawn ();
        newball.cnt = self.cnt;
        newball.velocity = v_forward * 500 - v_right * 100;
/*        newball.velocity_x = random() * 150 + 150;
        newball.velocity_y = random() * 150 + 150;*/
        newball.velocity_z = random() * 150 + 150;
        Napalm_ThrowBouncingBall (newball);
        setorigin (newball, self.origin - 8 * v_forward);
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

    // set newmis speed
    makevectors (self.v_angle);
    newmis.velocity = aim(self, 1000);

    if (self.impulse == 12 || self.button1)
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
        newmis.classname = "rocket";
        #ifdef QUAKEWORLD
        newmis.voided = 0;
        #endif
        newmis.angles = vectoangles(newmis.velocity);

        newmis.movetype = MOVETYPE_FLYMISSILE;
        newmis.velocity = newmis.velocity * 1500;
        self.ammo_rockets = self.ammo_rockets - 1;

        newmis.touch = T_MissileTouch;
        setmodel (newmis, "progs/missile.mdl");
        setsize (newmis, '-2 -2 -2', '2 2 2');

        // set newmis duration
        newmis.nextthink = time + 5;
        newmis.think = SUB_Remove;
    }
    self.currentammo = self.ammo_rockets;

    // If we do our 2nd shot with guns akimbo, fire from the left side
    setorigin (newmis, self.origin + v_forward * 20 + '0 0 10' + v_right * 10);
    if (self.weaponframe == $anapalm_fire4)
        setorigin (newmis, newmis.origin - v_right * 20);
};


/*
============
Napalm_Attack

Attack code for the napalm launcher
============
*/
void() Napalm_Attack =
{
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

    self.impulse = 0;
};
