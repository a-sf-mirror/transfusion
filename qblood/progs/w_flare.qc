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


void() Flare_Fire;


//============================================================================

// ----- Flaregun model ----- //

// Normal model
$modelname v_shot

// idle
$frame flare_idle1

// fire
$frame flare_fire1 flare_fire2 flare_fire3 flare_fire4

// draw
$frame flare_draw1 flare_draw2 flare_draw3 flare_draw4

// holster
$frame flare_holster1 flare_holster2 flare_holster3 flare_holster4


// Akimbo model
$modelname v_aflare

// fire
$frame aflare_fire1 aflare_fire2 aflare_fire3 aflare_fire4 aflare_fire5

// draw
$frame aflare_draw1 aflare_draw2 aflare_draw3 aflare_draw4 aflare_draw5
$frame aflare_draw6

// holster
$frame aflare_holster1 aflare_holster2 aflare_holster3 aflare_holster4 aflare_holster5
$frame aflare_holster6


// ----- Player related code ----- //

// Normal fire
void() player_flare1 = [$attack1, player_flare2] { self.weaponframe = $flare_fire1; };
void() player_flare2 = [$attack1, player_flare3] { self.weaponframe = $flare_fire2; muzzleflash(); Flare_Fire (); };
void() player_flare3 = [$attack2, player_flare4] { self.weaponframe = $flare_fire3; };
void() player_flare4 = [$attack2, player_run   ] { self.weaponframe = $flare_fire4; };

// Akimbo fire
void() player_akflare1 = [$attack1, player_akflare2] { self.weaponframe = $aflare_fire2; muzzleflash (); Flare_Fire (); };
void() player_akflare2 = [$attack2, player_akflare3] { self.weaponframe = $aflare_fire3; };
void() player_akflare3 = [$attack1, player_akflare4] { self.weaponframe = $aflare_fire4; muzzleflash (); Flare_Fire (); };
void() player_akflare4 = [$attack2, player_run     ]
{
    // If we don't have enough ammo anymore, drop the guns akimbo
    if ((self.items & IT_GUNS_AKIMBO) && self.currentammo < 2)
    {
        Flare_UpdateView ();
        self.weaponframe = $aflare_fire1;
    }
    else
        self.weaponframe = $aflare_fire5;
};

// Normal draw
void() player_flaredraw1 = [$attack1, player_flaredraw2] { self.weaponframe = $flare_draw1; };
void() player_flaredraw2 = [$attack1, player_flaredraw3] { self.weaponframe = $flare_draw2; };
void() player_flaredraw3 = [$attack1, player_flaredraw4] { self.weaponframe = $flare_draw3; };
void() player_flaredraw4 = [$attack1, player_run       ] { self.weaponframe = $flare_draw4; };

// Normal holster
void() player_flareholster1 = [$attack1, player_flareholster2] { self.weaponframe = $flare_holster1; };
void() player_flareholster2 = [$attack1, player_flareholster3] { self.weaponframe = $flare_holster2; };
void() player_flareholster3 = [$attack1, player_flareholster4] { self.weaponframe = $flare_holster3; };
void() player_flareholster4 = [$attack1, player_flareholster5] { self.weaponframe = $flare_holster4; };
void() player_flareholster5 = [$attack1, player_run          ] { W_DrawWeapon (self.newweapon); };

// Akimbo draw
void() player_akflaredraw1 = [$attack1, player_akflaredraw2] { self.weaponframe = $aflare_draw1; };
void() player_akflaredraw2 = [$attack1, player_akflaredraw3] { self.weaponframe = $aflare_draw3; };
void() player_akflaredraw3 = [$attack1, player_run         ] { self.weaponframe = $aflare_draw5; };

// Akimbo holster
void() player_akflareholst1 = [$attack1, player_akflareholst2] { self.weaponframe = $aflare_holster1; };
void() player_akflareholst2 = [$attack1, player_akflareholst3] { self.weaponframe = $aflare_holster3; };
void() player_akflareholst3 = [$attack1, player_akflareholst4] { self.weaponframe = $aflare_holster5; };
void() player_akflareholst4 = [$attack1, player_run          ] { W_DrawWeapon (self.newweapon); };


//============================================================================

/*
================
FlareSpark

This causes the flare to emit sparks
================
*/
void() FlareSpark =
{
    // FIXME:  Use better particle effects -- custom source port recommended.

    // FIXME(2): Currently, this does NOTHING in QW.  Without a particle
    //           function, the only way to produce a spawn shower is to create an
    //           entity for each spark, and that is bad for netplay.

    #ifndef QUAKEWORLD
    particle (self.origin, '0 0 50', 151, 32);
    #endif
};


/*
================
FlareStick

This makes the flare stick to its target
================
*/
void() FlareStick =
{
    local   vector  spot;
    local   float   dist, least;

    // Find maximum distance from origin the flare is allowed to go.
    dist = self.enemy.maxs_x - self.enemy.mins_x;
    least = self.enemy.maxs_y - self.enemy.mins_y;
    if (least < dist)
        dist = least;
    least = self.enemy.maxs_z - self.enemy.mins_z;
    if (least < dist)
        dist = least;
    dist = dist / 4;

    // Get the proper angles.
    spot_x = self.enemy.angles_x - self.dest_x;
    spot_y = self.enemy.angles_y + self.dest_y;
    spot_z = 0;

    // Place the flare.
    makevectors (spot);
    spot = (self.enemy.origin + (self.enemy.mins + self.enemy.maxs)*0.5) +
        (v_forward * dist);
    setorigin (self, spot);
};


/*
================
FlareThink

The flare sticks and burns its target
================
*/
void() FlareThink =
{
    if (self.dmg <= 0)
    {
        // Flare burnt out.
        remove (self);
        return;
    }
    if ((self.enemy.health <= 0) || (self.enemy.deadflag))
    {
        // Dead.
        remove (self);
        return;
    }

    // Make the flame stick to its target.
    FlareStick ();
    FlareSpark ();
    self.dmg = self.dmg - 1;    // Update the burn damage limit.

    local   float   nextframe;

    nextframe = time + 0.1;
    if (self.enemy.flare_time <= time)
    {
        // Only one flare can damage at any given frame.
        self.enemy.flare_time = nextframe;

        // Do burn damage if not already burning.
        if (!self.enemy.burner)
            FireDamage (self.enemy, self, self.owner, DF_FIRE);
    }

    self.nextthink = nextframe;
};


/*
================
FlareTouch

Called when flare impacts.
================
*/
void() FlareTouch =
{
    if (other.solid == SOLID_TRIGGER)
        return; // trigger field, do nothing

    #ifdef QUAKEWORLD
    if (self.voided)
        return;
    self.voided = 1;
    #endif

    if (pointcontents(self.origin) == CONTENT_SKY)
    {
        remove(self);
        return;
    }

    // hit something that bleeds
    if (other.takedamage)
    {
        // Just set the target on fire.
        BurnDamage (other, self, 0, DF_FIRE, self.dmg);
    }

    FlareSpark ();   // Throw a few sparks.
    remove (self);
};


/*
================
NewFlare

Spawns and returns a brand new flare
================
*/
entity(entity attacker, vector spot) NewFlare =
{
    local   entity  fire;

    fire = spawn();

    #ifdef QUAKEWORLD
    fire.voided     = 0;
    #endif

    setmodel (fire, "progs/flame2.mdl");
    setsize (fire, '0 0 0', '0 0 0');
    setorigin (fire, spot);

    fire.solid      = SOLID_NOT;
    fire.takedamage = DAMAGE_NO;
    fire.frame      = 0;
    fire.skin       = 1;  // use purplish skin
    fire.owner      = attacker;
    fire.classname  = "flare";
    fire.netname    = "flare";

    fire.effects    = EF_DIMLIGHT;
    fire.movetype   = MOVETYPE_FLYMISSILE;
    fire.solid      = SOLID_BBOX;

    return fire;
};


/*
================
AltFlareTouch

Called when flare impacts
================
*/
void() AltFlareTouch =
{
    if (other.solid == SOLID_TRIGGER)
        return; // trigger field, do nothing

    #ifdef QUAKEWORLD
    if (self.voided)
        return;
    self.voided = 1;
    #endif

    if (pointcontents(self.origin) == CONTENT_SKY)
    {
        remove(self);
        return;
    }

    // Explode!
    muzzleflash ();

    // Do the damage.
    self.height = 120;
    BurnRadius (self, self.dmg, self.cnt, other);
    self.origin = self.origin - 8*normalize(self.velocity);
    if (other.takedamage)
        BurnDamage (other, self, self.dmg, DF_FIRE, self.cnt);

    // Make some fire.
    self.solid = SOLID_NOT;     // So embers can't touch 'self'.
    ThrowEmbers (floor (self.count * 0.5));
    PsychoCaleb (self.owner);
    sound (self, CHAN_AUTO, "weapons/napalm/explodfs.wav", 1, ATTN_NORM);
    BecomeOldExplosion ();
};


/*
================
AltFlareSplit

This causes the flare to change its path in mid-flight
================
*/
void() AltFlareSplit =
{
    local   entity  fire;
    local   vector  dir, spread;
    local   float   loop;

    dir = normalize (self.velocity);
    dir = vectoangles (dir);
    dir_x = 0 - dir_x;
    makevectors (dir);

    // Create eight new flares.
    loop = 8;
    while (loop > 0)
    {
        if (loop == 8)
            spread = '1 0 0.15';
        else if (loop == 7)
            spread = '1 0.15 0';
        else if (loop == 6)
            spread = '1 0 -0.15';
        else if (loop == 5)
            spread = '1 -0.15 0';
        else if (loop == 4)
            spread = '1 0.05 0.05';
        else if (loop == 3)
            spread = '1 -0.05 0.05';
        else if (loop == 2)
            spread = '1 -0.05 -0.05';
        else if (loop == 1)
            spread = '1 0.05 -0.05';
        else
            spread = '1 0 0';   // This shouldn't happen.

        dir = (v_forward * spread_x) + (v_right * spread_y) + (v_up * spread_z);
        dir = normalize (dir);

        fire = NewFlare (self.owner, self.origin);
        fire.angles     = vectoangles(dir) + '90 0 0';
        fire.velocity   = dir * self.speed;
        fire.touch      = AltFlareTouch;
        fire.nextthink  = self.pausetime;
        fire.think      = SUB_Remove;
        fire.cnt        = self.cnt;
        fire.dmg        = self.dmg;
        fire.speed      = self.speed;
        fire.distance   = self.distance;
        fire.count      = 2;    // Number of embers.

        loop = loop - 1;
    }

    // Remove the old flare.
    remove (self);
};


/*
================
FireAltFlares

Create and launch a small fireball
================
*/
void(entity attacker, vector org, vector dir, float sped, float damage, float burn) FireAltFlares =
{
    local   entity  fire;

    fire = NewFlare (attacker, org);
    fire.angles     = vectoangles(dir) + '90 0 0';
    fire.velocity   = dir * sped;
    fire.touch      = AltFlareTouch;
    fire.nextthink  = time + 0.4;   // Approximate time alt-flares split.
    fire.think      = AltFlareSplit;
    fire.pausetime  = time + (8000 / sped);
    fire.cnt        = burn;
    fire.dmg        = damage;
    fire.speed      = sped;
    fire.distance   = 0.8;  // Damage is 80% at max radius.
    fire.count      = 6;    // Number of embers.
};


/*
================
FireFlare

Create and launch a normal flare
================
*/
void(entity attacker, vector org, vector dir, float sped) FireFlare =
{
    local   entity  fire;

    fire = NewFlare (attacker, org);
    fire.angles     = vectoangles(dir) + '90 0 0';
    fire.velocity   = dir * sped;
    fire.touch      = FlareTouch;
    fire.nextthink  = time + (8000 / sped);
    fire.think      = SUB_Remove;
    fire.dmg        = 50;       // Flares last five seconds.
};


/*
================
Flare_Fire

Launch a flare
================
*/
void() Flare_Fire =
{
    local vector dir;
    local float  mspeed;

    sound (self, CHAN_WEAPON, "weapons/flaregun/flaref.wav", 1, ATTN_NORM);

    #ifndef QUAKEWORLD
    self.punchangle_x = -2;
    #else
    msg_entity = self;
    WriteByte (MSG_ONE, SVC_SMALLKICK);
    #endif

    mspeed = 1000;
    dir = aim (self, mspeed);

    // Spawn the flare a little ahead of the player
    local vector orig;
    makevectors(self.v_angle);
    orig = self.origin + v_forward * 8 + '0 0 16';

    // If we want to (and can) launch alt-flares
    if (self.player_state == PS_ALTFIRE && self.ammo_flares >= 8)
    {
        self.currentammo = self.ammo_flares = self.ammo_flares - 8;
        FireAltFlares (self, orig, dir, mspeed, 10, 50);
        return;
    }

    self.currentammo = self.ammo_flares = self.ammo_flares - 1;
    FireFlare (self, orig, dir, mspeed);
};


/*
============
Flare_Attack

Attack code for the flaregun
============
*/
void() Flare_Attack =
{
    // Normal fire or altfire?
    if (self.impulse == 12 || self.button1)
        self.player_state = PS_ALTFIRE;
    else
        self.player_state = PS_FIRE;

    // If we have guns akimbo
    if (self.items & IT_GUNS_AKIMBO)
    {
        player_akflare1 ();
        self.attack_finished = time + 0.6;
    }
    else
    {
        player_flare1 ();
        self.attack_finished = time + 0.5;
    }
};


/*
============
Flare_Draw

Draw code for the flaregun
============
*/
void() Flare_Draw =
{
    self.weapon = IT_FLAREGUN;
    self.currentammo = self.ammo_flares;
    self.items = self.items - (self.items & (IT_SHELLS | IT_NAILS | IT_CELLS | IT_ROCKETS));

    Flare_UpdateView ();

    if (self.items & IT_GUNS_AKIMBO)
    {
        self.attack_finished = time + 0.4;
        player_akflaredraw1 ();
    }
    else
    {
        self.attack_finished = time + 0.5;
        player_flaredraw1 ();
    }
};


/*
============
Flare_Holster

Holster code for the flaregun
============
*/
void() Flare_Holster =
{
    if (self.items & IT_GUNS_AKIMBO)
    {
        self.attack_finished = time + 0.4;
        player_akflareholst1 ();
    }
    else
    {
        self.attack_finished = time + 0.5;
        player_flareholster1 ();
    }
};


/*
============
Flare_UpdateView

Choose the right flaregun model to display
============
*/
void() Flare_UpdateView =
{
    if (self.akimbo_finished > time && self.currentammo >= 2)
    {
        self.weaponmodel = "progs/v_aflare.mdl";
        self.items = self.items | IT_GUNS_AKIMBO;
    }
    else
    {
        self.weaponmodel = "progs/v_shot.mdl";
        self.items = self.items - (self.items & IT_GUNS_AKIMBO);
    }
};
