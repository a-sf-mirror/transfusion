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


//============================================================================

// ----- Flaregun model ----- //

$modelname v_shot

// idle
$frame flare_idle1

// fire
$frame flare_fire1 flare_fire2 flare_fire3


// ----- Player related code ----- //

void() player_flare1 = [$shotatt1, player_flare2] { self.weaponframe = $flare_fire1; muzzleflash(); };
void() player_flare2 = [$shotatt2, player_flare3] { self.weaponframe = $flare_fire2; };
void() player_flare3 = [$shotatt3, player_flare4] { self.weaponframe = $flare_fire3; };
void() player_flare4 = [$shotatt4, player_run  ]  { self.weaponframe = $flare_idle1; };

// Normal draw
// NOTE: no animation to play for now
void() player_flaredraw1 = [$shotatt1, player_run] { self.weaponframe = 0; };

// Normal holster
// NOTE: no animation to play for now
void() player_flareholster1 = [$shotatt1, player_run] { W_DrawWeapon (self.newweapon); };


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
            PM_FireDamage (self.enemy, self, self.owner);
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
        if (other.flags & FL_MONSTER)
        {
            // Change flare properties so it can stick without interference.
            self.velocity   = '0 0 0';
            self.solid      = SOLID_NOT;
            self.movetype   = MOVETYPE_NONE;
            self.enemy      = other;
            self.angles     = '180 0 0';    // Turn flame upside-down.

            // Find difference of angles between the directions of the
            // enemy and the flare.
            self.dest   = other.origin + (other.mins + other.maxs)*0.5;
            self.dest   = normalize(self.origin - self.dest);
            self.dest   = vectoangles (self.dest);
            self.dest   = self.dest - other.angles;

            // Make the flame stick to its target.
            FlareStick ();
            self.nextthink  = 0.1;
            self.think      = FlareThink;

            return;
        }

        // Just set the target on fire.
        PM_BurnDamage (other, self, 0, self.dmg);
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
        PM_BurnDamage (other, self, self.dmg, self.cnt);

    // Make some fire.
    self.solid = SOLID_NOT;     // So embers can't touch 'self'.
    ThrowEmbers (self.count);
    PsychoCaleb (self.owner);
    sound (self, CHAN_AUTO, "weapons/napalm/explodfs.wav", 1, ATTN_NORM);
    PM_BecomeOldExplosion ();
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
    fire.nextthink  = time + 0.5;   // Approximate time alt-flares split.
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
    orig = self.origin + v_forward * 10 + v_right * 4;
    orig_z = self.absmin_z + self.size_z * 0.8;

    // If we want to (and can) launch alt-flares
    if ((self.impulse == 12 || self.button1) && self.ammo_flares >= 8)
    {
        self.player_state = PS_ALTFIRE;
        self.currentammo = self.ammo_flares = self.ammo_flares - 8;
        FireAltFlares (self, orig, dir, mspeed, 10, 50);
        return;
    }

    self.player_state = PS_FIRE;
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
    player_flare1 ();
    Flare_Fire ();
    self.attack_finished = time + 0.5;
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

    self.attack_finished = time + 0.1;
    player_flaredraw1 ();
};


/*
============
Flare_Holster

Holster code for the flaregun
============
*/
void() Flare_Holster =
{
    self.attack_finished = time + 0.1;
    player_flareholster1 ();
};


/*
============
Flare_UpdateView

Choose the right flaregun model to display
============
*/
void() Flare_UpdateView =
{
    self.weaponmodel = "progs/v_shot.mdl";
    self.items = self.items - (self.items & IT_GUNS_AKIMBO);
};
