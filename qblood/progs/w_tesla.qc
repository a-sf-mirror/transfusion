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


void() Tesla_Fire;


//============================================================================

// ----- Tesla Cannon models ----- //

// Normal model
$modelname v_light

// idle
$frame tesla_idle1 tesla_idle2

// fire
$frame tesla_fire1 tesla_fire2 tesla_fire3 tesla_fire4

// altfire
$frame tesla_alt1  tesla_alt2  tesla_alt3  tesla_alt4  tesla_alt5
$frame tesla_alt6  tesla_alt7  tesla_alt8  tesla_alt9  tesla_alt10
$frame tesla_alt11 tesla_alt12 tesla_alt13 tesla_alt14 tesla_alt15
$frame tesla_alt16 tesla_alt17 tesla_alt18 tesla_alt19 tesla_alt20

// draw
$frame tesla_draw1 tesla_draw2 tesla_draw3

// holster
$frame tesla_holster1 tesla_holster2 tesla_holster3


// Akimbo model
$modelname v_alight

// idle
$frame atesla_idle1 atesla_idle2

// fire
$frame atesla_fire1 atesla_fire2 atesla_fire3 atesla_fire4

// altfire
$frame atesla_alt1  atesla_alt2  atesla_alt3  atesla_alt4  atesla_alt5
$frame atesla_alt6  atesla_alt7  atesla_alt8  atesla_alt9  atesla_alt10
$frame atesla_alt11 atesla_alt12 atesla_alt13 atesla_alt14 atesla_alt15
$frame atesla_alt16 atesla_alt17 atesla_alt18 atesla_alt19 atesla_alt20

// draw
$frame atesla_draw1 atesla_draw2 atesla_draw3

// holster
$frame atesla_holster1 atesla_holster2 atesla_holster3


// ----- Player related code ----- //

// Normal fire
void() player_tesla =
{
    // If we must stop
    if ((!self.button0 && !self.button1 && self.impulse != 12) || intermission_running || self.ammo_cells < 1)
    {
        player_run ();
        return;
    }

    // Fire
    self.weaponframe = self.weaponframe + 1;
    if (self.weaponframe > $atesla_fire4)
        self.weaponframe = $atesla_fire1;

    Tesla_Fire ();
};

void() player_tesla1 = [$light1, player_tesla2]
{
    self.player_state = PS_FIRE;

    self.weaponframe = $tesla_fire1;
    Tesla_Fire ();
};
void() player_tesla2 = [$light2, player_tesla3] { self.weaponframe = $tesla_fire2; Tesla_Fire (); };
void() player_tesla3 = [$light1, player_tesla4] { self.weaponframe = $tesla_fire3; Tesla_Fire (); };
void() player_tesla4 = [$light2, player_tesla5] { self.weaponframe = $tesla_fire4; Tesla_Fire (); };
void() player_tesla5 = [$light1, player_tesla6] { self.weaponframe = $tesla_fire1; Tesla_Fire (); };
void() player_tesla6 = [$light2, player_tesla7] { player_tesla (); };
void() player_tesla7 = [$light1, player_tesla6] { player_tesla (); };

// Altfire
void()  player_alttesla1  = [$shotatt1, player_alttesla2 ]
{
    self.player_state = PS_ALTFIRE;

    // Select the right sound
    if (self.items & IT_GUNS_AKIMBO)
        sound (self, CHAN_WEAPON, "weapons/tesla/tesakima.wav", 1, ATTN_NORM);
    else
        sound (self, CHAN_WEAPON, "weapons/tesla/tessuper.wav", 1, ATTN_NORM);

    self.weaponframe = $atesla_alt1;
};

void()  player_alttesla2  = [$shotatt1, player_alttesla3 ] { self.weaponframe = $atesla_alt2; };
void()  player_alttesla3  = [$shotatt2, player_alttesla4 ] { self.weaponframe = $atesla_alt3; };
void()  player_alttesla4  = [$shotatt1, player_alttesla5 ] { self.weaponframe = $atesla_alt4; };
void()  player_alttesla5  = [$shotatt2, player_alttesla6 ] { self.weaponframe = $atesla_alt5; };
void()  player_alttesla6  = [$shotatt1, player_alttesla7 ] { self.weaponframe = $atesla_alt6; };
void()  player_alttesla7  = [$shotatt2, player_alttesla8 ] { self.weaponframe = $atesla_alt7; };
void()  player_alttesla8  = [$shotatt1, player_alttesla9 ] { self.weaponframe = $atesla_alt8; };
void()  player_alttesla9  = [$shotatt2, player_alttesla10] { self.weaponframe = $atesla_alt9; };
void()  player_alttesla10 = [$shotatt1, player_alttesla11] { self.weaponframe = $atesla_alt10; };
void()  player_alttesla11 = [$shotatt2, player_alttesla12] { self.weaponframe = $atesla_alt11; };
void()  player_alttesla12 = [$shotatt1, player_alttesla13] { self.weaponframe = $atesla_alt12; };
void()  player_alttesla13 = [$shotatt2, player_alttesla14] { self.weaponframe = $atesla_alt13; };
void()  player_alttesla14 = [$shotatt1, player_alttesla15] { self.weaponframe = $atesla_alt14; };
void()  player_alttesla15 = [$shotatt2, player_alttesla16] { self.weaponframe = $atesla_alt15; Tesla_Fire (); };
void()  player_alttesla16 = [$shotatt1, player_alttesla17] { self.weaponframe = $atesla_alt16; };
void()  player_alttesla17 = [$shotatt2, player_alttesla18] { self.weaponframe = $atesla_alt17; };
void()  player_alttesla18 = [$shotatt1, player_alttesla19] { self.weaponframe = $atesla_alt18; };
void()  player_alttesla19 = [$shotatt2, player_alttesla20] { self.weaponframe = $atesla_alt19; };
void()  player_alttesla20 = [$shotatt1, player_alttesla21] { self.weaponframe = $atesla_alt20; };
void()  player_alttesla21 = [$shotatt2, player_run       ] {};


//============================================================================

/*
============
Tesla_JoltTouch

Touch function for the tesla projectile
============
*/
void() Tesla_JoltTouch =
{
    // Don't explode on owner
    if (other == self.owner)
        return;

    #ifdef QUAKEWORLD
    if (self.voided)
        return;
    self.voided = 1;
    #endif

    // If we go out of the map
    if (pointcontents(self.origin) == CONTENT_SKY)
    {
        remove(self);
        return;
    }

    // If we can damage the entity we touch
    if (other.takedamage)
        T_Damage (other, self, self.owner, self.dmg, DF_BODY, "tesla");

    if (self.style)
    {
        // Alt-fire touch.
        T_RadiusDamage (self, self.owner, self.dmg, other, "tesla");

        self.origin = self.origin - 8 * normalize (self.velocity);
        sound (self, CHAN_AUTO, "weapons/tesla/tesaltht.wav", 1, ATTN_NORM);

        #ifndef QUAKEWORLD
        WriteByte  (MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte  (MSG_BROADCAST, TE_EXPLOSION2);
        WriteCoord (MSG_BROADCAST, self.origin_x);
        WriteCoord (MSG_BROADCAST, self.origin_y);
        WriteCoord (MSG_BROADCAST, self.origin_z);
        WriteByte  (MSG_BROADCAST, 244);
        WriteByte  (MSG_BROADCAST, 3);

        // FIXME: the explosion used in QW is the classic one for now.
        //        because TE_EXPLOSION2 has no equivalent in QW
        #else
        WriteByte  (MSG_MULTICAST, SVC_TEMPENTITY);
        WriteByte  (MSG_MULTICAST, TE_EXPLOSION);
        WriteCoord (MSG_MULTICAST, self.origin_x);
        WriteCoord (MSG_MULTICAST, self.origin_y);
        WriteCoord (MSG_MULTICAST, self.origin_z);
        multicast  (self.origin, MULTICAST_PHS);
        #endif
    }
    else
    {
        // Normal touch
        self.origin = self.origin - 8 * normalize(self.velocity);
        sound (self, CHAN_AUTO, "weapons/tesla/tessnght.wav", 1, ATTN_NORM);
    }

    remove (self);
};


/*
============
Tesla_LaunchJolt

Spawn the tesla projectile
============
*/
void(vector org, vector dir, float mspeed) Tesla_LaunchJolt =
{
    local entity jolt;

    jolt = spawn();

    #ifdef QUAKEWORLD
    jolt.voided     = 0;
    #endif

    jolt.owner      = self;
    jolt.movetype   = MOVETYPE_FLYMISSILE;
    jolt.solid      = SOLID_BBOX;
    jolt.classname  = "tesla ball";
    jolt.velocity   = dir * mspeed;
    jolt.angles     = vectoangles(dir);
    if (self.player_state == PS_ALTFIRE)
    {
        jolt.dmg    = 170;
        jolt.model  = "progs/bolt2.mdl";
        jolt.style  = 1;
    }
    else
    {
        jolt.dmg       = 25;
        jolt.model     = "progs/bolt.mdl";
        jolt.avelocity = '300 300 300';
        jolt.style     = 0;
    }
    jolt.touch      = Tesla_JoltTouch;
    jolt.nextthink  = time + (8000 / mspeed);
    jolt.think      = SUB_Remove;

    setmodel (jolt, jolt.model);
    setsize (jolt, '-2 -2 -2', '2 2 2');
    setorigin (jolt, org);
};


/*
============
Tesla_Fire

Shot with a tesla cannon
============
*/
void() Tesla_Fire =
{
    local   vector  org;
    local   vector  dir;
    local   float   mspeed;
    local   float   akimboFactor;  // 2 if guns akimbo, else 1

    if (self.items & IT_GUNS_AKIMBO)
        akimboFactor = 2;
    else
        akimboFactor = 1;

    // If we don't have enough ammo
    if (self.ammo_cells < akimboFactor)
        return;

    muzzleflash ();

    #ifndef QUAKEWORLD
    self.punchangle_x = -2;
    #else
    msg_entity = self;
    WriteByte (MSG_ONE, SVC_SMALLKICK);
    #endif

    // If we want an altfire shot (we've already checked the ammo count in Tesla_Attack)
    if (self.player_state == PS_ALTFIRE)
    {
        // NOTE: we have already started the sound in "player_alttesla1"

        self.ammo_cells = self.ammo_cells - 35 * akimboFactor;
        mspeed = 2000;
    }
    else
    {
        sound (self, CHAN_WEAPON, "weapons/tesla/tessngfr.wav", 1, ATTN_NORM);

        self.ammo_cells = self.ammo_cells - akimboFactor;
        mspeed = 1500;
    }
    self.currentammo = self.ammo_cells;

    makevectors (self.v_angle);
    dir = aim(self, mspeed);

    // 1st shot
    org = self.origin + v_forward * 50 + '0 0 12' + v_right * 12;
    Tesla_LaunchJolt (org, dir, mspeed);

    // 2nd shot in akimbo mode
    if (akimboFactor == 2)
    {
        org = org - v_right * 24;  // Shot from the left side this time
        Tesla_LaunchJolt (org, dir, mspeed);

        // If we don't have enough ammo anymore, drop the akimbo mode for now
        if (self.ammo_cells < 2)
            W_SetCurrentAmmo (FALSE, 0);
    }
};


/*
============
Tesla_Attack

Attack code for the tesla cannon
============
*/
void() Tesla_Attack =
{
    if (self.button0 || self.ammo_cells < 35 || ((self.items & IT_GUNS_AKIMBO) && self.ammo_cells < 70))
    {
        player_tesla1();
        self.attack_finished = time + 0.1;
    }
    else
    {
        player_alttesla1();
        self.attack_finished = time + 2.1;
    }
};