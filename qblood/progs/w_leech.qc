/*  Copyright (C) 2001-2002  Dave Turner

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
void() player_leech1  = [$attack1, player_leech2 ]
{
    sound (self, CHAN_WEAPON, "weapons/lifelech/laltfr1.wav", 1, ATTN_NORM);
    self.weaponframe = $leech_fire1;
};
void() player_leech2  = [$attack1, player_leech3 ] { self.weaponframe = $leech_fire2;  };
void() player_leech3  = [$attack1, player_leech4 ] { self.weaponframe = $leech_fire3;  };
void() player_leech4  = [$attack1, player_leech5 ] { self.weaponframe = $leech_fire4;  };
void() player_leech5  = [$attack2, player_leech6 ] { self.weaponframe = $leech_fire5;  Leech_BallFire (); };
void() player_leech6  = [$attack2, player_leech7 ] { self.weaponframe = $leech_fire6;  };
void() player_leech7  = [$attack2, player_leech8 ] { self.weaponframe = $leech_fire7;  };
void() player_leech8  = [$attack1, player_leech9 ] { self.weaponframe = $leech_fire8;  Leech_BallFire (); };
void() player_leech9  = [$attack1, player_leech10] { self.weaponframe = $leech_fire9;  };
void() player_leech10 = [$attack1, player_leech11] { self.weaponframe = $leech_fire10; };
void() player_leech11 = [$attack2, player_leech12] { self.weaponframe = $leech_fire11; Leech_BallFire (); };
void() player_leech12 = [$attack2, player_leech13] { self.weaponframe = $leech_fire12; };
void() player_leech13 = [$attack2, player_leech14] { self.weaponframe = $leech_fire13; };
void() player_leech14 = [$attack1, player_leech15] { self.weaponframe = $leech_fire14; Leech_BallFire (); };
void() player_leech15 = [$attack1, player_leech16] { self.weaponframe = $leech_fire15; };
void() player_leech16 = [$attack2, player_leech17] { self.weaponframe = $leech_fire16; Leech_BallFire (); };
void() player_leech17 = [$attack2, player_leech18] { self.weaponframe = $leech_fire17; };
void() player_leech18 = [$attack2, player_leech19] { self.weaponframe = $leech_fire18; };
void() player_leech19 = [$attack1, player_leech20] { self.weaponframe = $leech_fire19; Leech_BallFire (); };
void() player_leech20 = [$attack1, player_leech21] { self.weaponframe = $leech_fire20; };
void() player_leech21 = [$attack1, player_leech22] { self.weaponframe = $leech_fire21; };
void() player_leech22 = [$attack2, player_leech23] { self.weaponframe = $leech_fire22; Leech_BallFire (); };
void() player_leech23 = [$attack2, player_leech24] { self.weaponframe = $leech_fire23; };
void() player_leech24 = [$attack2, player_leech25] { self.weaponframe = $leech_fire24; };
void() player_leech25 = [$attack2, player_run    ] { self.weaponframe = $leech_fire25; };

// Normal draw
void() player_leechdraw1 = [$attack2, player_leechdraw2] { self.weaponframe = $leech_draw1; };
void() player_leechdraw2 = [$attack2, player_leechdraw3] { self.weaponframe = $leech_draw2; };
void() player_leechdraw3 = [$attack2, player_run       ] { self.weaponframe = $leech_draw3; };

// Normal holster
void() player_leechholster1 = [$attack2, player_leechholster2] { self.weaponframe = $leech_holster1; };
void() player_leechholster2 = [$attack2, player_leechholster3] { self.weaponframe = $leech_holster2; };
void() player_leechholster3 = [$attack2, player_leechholster4] { self.weaponframe = $leech_holster3; };
void() player_leechholster4 = [$attack2, player_run          ] { W_DrawWeapon (self.newweapon); };


//=================================================================

/*
================
Leech_BallTouch

Touch function for the leech missile
================
*/
void() Leech_BallTouch =
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

    self.deathtype = "leech";  // Done for the fire code.
    if (other.takedamage)
    {
        other.deathtype = "leech";
        BurnDamage (other, self, self.dmg, DF_MIND, self.dmg * 0.1, 5);
    }

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
=========================
Leech_BallFire

Fire a Life Leech ball
=========================
*/
void() Leech_BallFire =
{
    local vector spread;

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

    // If aim() hasn't found any interesting target, add some spread
    traceline (self.origin, self.origin + newmis.velocity*2048, FALSE, self);
    if (trace_ent == world)
        spread = crandom () * 0.18 * v_right + crandom () * 0.08 * v_up;
    else
        spread = '0 0 0';
    newmis.velocity = 1500 * (newmis.velocity + spread);

    newmis.owner = self;
    newmis.solid = SOLID_BBOX;
    newmis.classname = "missile";
    #ifdef QUAKEWORLD
    newmis.voided = 0;
    #endif
    newmis.angles = vectoangles(newmis.velocity);
    newmis.movetype = MOVETYPE_FLYMISSILE;

    // If we don't have enough ammo, use HP
    if (self.ammo_leech < 2)
    {
        T_Damage (self, world, self, 2 - self.ammo_leech, DF_MIND, "leech");
        self.ammo_leech = 0;
    }
    else
        self.ammo_leech = self.ammo_leech - 2;
    self.currentammo = self.ammo_leech;

    newmis.touch = Leech_BallTouch;
    setmodel (newmis, "progs/bolt.mdl");
    newmis.skin = 1;
    setsize (newmis, '0 0 0', '0 0 0');
    setorigin (newmis, self.origin + v_forward * 8 + '0 0 24');

    newmis.dmg = 40;

    // set newmis duration
    newmis.nextthink = time + 5;
    newmis.think = SUB_Remove;
    newmis.reset = SUB_Remove;
};


/*
================
Leech_AltBallTouch

Touch function for the leech altfire missile
================
*/
void() Leech_AltBallTouch =
{
    // Don't explode on owner (the Life Leech)
    if (other == self.owner)
        return;

    #ifdef QUAKEWORLD
    if (self.voided) {
        return;
    }
    self.voided = 1;
    #endif

    // Switch ownership from the Life Leech itself to the LL owner
    self.owner = self.owner.leech_sentry;

    if (pointcontents(self.origin) == CONTENT_SKY)
    {
        remove (self);
        return;
    }

    // If we can damage the entity we touch
    if (other.takedamage)
        T_Damage (other, self, self.owner, self.dmg, DF_MIND, "leech");

    sound (self, CHAN_AUTO, "weapons/napalm/explodfs.wav", 1, ATTN_NORM);
    remove (self);
};


/*
==================
Leech_Think

Dropped LL think function
==================
*/
void() Leech_Think =
{
    local float diff, bestdiff;
    local entity ent, bestent;
    local vector ballorigin;

    self.owner = world;  // the LL must be able to touch its owner
    self.nextthink = time + 0.75;
    ballorigin = self.origin + '0 0 45';

    // Look for a target (the closer, the better)
    bestdiff = 10000;
    bestent = world;
    ent = findradius (self.origin, 500);
    while (ent != world)
    {
        if (ent.takedamage)
            // If it's a player
            if (ent.classname == "player")
                // If he's a valid target (not the owner or a player from the same team)
                if (ent != self.leech_sentry && (gametype == GT_BLOODBATH || ent.team != self.team))
                {
                    // If he's closer than our current choice
                    diff = vlen (ent.origin - ballorigin);
                    if (diff < bestdiff)
                    {
                        // If he's visible
                        traceline (ballorigin, ent.origin, FALSE, self);
                        if (trace_ent == ent)
                        {
                            bestent = ent;
                            bestdiff = diff;
                        }
                    }
                }

        ent = ent.chain;
    }

    // If we haven't find a target, there's nothing to do
    if (bestent == world)
        return;

    // Fire a ball of energy on the target
    newmis = spawn ();
    newmis.owner = self;
    newmis.solid = SOLID_BBOX;
    newmis.classname = "missile";
    #ifdef QUAKEWORLD
    newmis.voided = 0;
    #endif
    newmis.velocity = 1500 * normalize (bestent.origin - ballorigin);
    newmis.angles = vectoangles (newmis.velocity);
    newmis.movetype = MOVETYPE_FLYMISSILE;
    newmis.touch = Leech_AltBallTouch;
    setmodel (newmis, "progs/teslaball.spr");  // the tesla ball is closer to the original look
    setsize (newmis, '0 0 0', '0 0 0');
    setorigin (newmis, ballorigin);
    newmis.dmg = 15;
    newmis.alpha  = 0.5;
    newmis.reset = SUB_Remove;
};


/*
==================
Leech_FadeOut

Used when a LL sentry fades out (when dying)
==================
*/
void() Leech_FadeOut =
{
    if (self.alpha > 0.1)  // Warning: alpha = 0.0 means opaque
    {
        self.alpha = self.alpha - 0.1;
        self.nextthink = time + 0.1;
    }
    else
        remove (self);
};


/*
==================
Leech_Reset

Reset function for a LL sentry
==================
*/
void() Leech_Reset =
{
    self.leech_sentry.leech_sentry = world;
    remove (self);
};


/*
==================
Leech_Die

Die function for a LL sentry
==================
*/
void() Leech_Die =
{
    self.leech_sentry.leech_sentry = world;
    sound (self, CHAN_VOICE, "weapons/lifelech/llaltht.wav", 1, ATTN_NORM);

    KillBurner (self);

    // If the engine supports the QC extension DP_ENT_ALPHA, make it fade out
    if (qcextensions)
        if (checkextension ("DP_ENT_ALPHA"))
        {
            self.solid = SOLID_NOT;
            self.takedamage = DAMAGE_NO;
            self.movetype = MOVETYPE_NONE;
            self.effects = 0;
            self.alpha = 1;

            self.touch = SUB_Null;
            self.th_die = SUB_Remove;
            self.think = Leech_FadeOut;
            self.nextthink = time + 0.1;

            return;
        }

    remove (self);
};


/*
==================
Leech_Touch

Touch function for a LL sentry
==================
*/
void() Leech_Touch =
{
    // If it's the owner, he takes back his Life Leech
    if (self.leech_sentry == other)
    {
        other.items = other.items + IT_LIFE_LEECH;
        other.leech_sentry = world;
        other.ammo_leech = other.ammo_leech + self.ammo_leech;
        sound (other, CHAN_ITEM, "items/weaponup.wav", 1, ATTN_NORM);
        remove (self);
    }

    SUB_SolidTouch ();
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
    setsize (item, '-6 -6 0', '6 8 60');

    item.classname = "sentry";
    item.owner = self;             // we don't want to trigger the touch function yet
    item.leech_sentry = self;      // we can't use "owner" because the owner of an entity is never clipped against it
    item.team = self.team;
    item.solid = SOLID_BBOX;
    item.takedamage = DAMAGE_AIM;
    item.health = 300;

    item.origin = self.origin + '0 0 12' + v_forward * 8;
    item.velocity = aim (self, 1000) * 50;
    item.velocity_z = 150;
    item.movetype = MOVETYPE_TOSS;

    if (cvar ("g_flashyEffects"))
        item.effects = item.effects | EF_FLAME;

    // Sentry mode
    item.nextthink = time + 1.5;
    item.think = Leech_Think;
    item.touch = Leech_Touch;
    item.th_die = Leech_Die;
    item.reset = Leech_Reset;

    // Dropping it requiers 25 ammo/HP
    if (self.ammo_leech < 25)
    {
        T_Damage (self, world, self, 25 - self.ammo_leech, DF_MIND, "leech");
        item.ammo_leech = 0;
    }
    else
        item.ammo_leech = self.ammo_leech - 25;
    self.currentammo = self.ammo_leech = 0;
    self.items = self.items - self.weapon;
    self.leech_sentry = item;

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
    if (self.button3)
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
