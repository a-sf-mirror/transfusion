/*  Copyright (C) 2001  Patrick Martin

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

//==========================================================================
//  fire.qc -- by Patrick Martin                Last updated:  8-20-2001
//--------------------------------------------------------------------------
//  Fire acts like poison.  When a target is infected, it burns.
//  The target loses one hit point for each frame it burns.
//  The flames can be snuffed by diving under the surface of
//  water or other liquid.
//==========================================================================

#include "common.qh"

//--------------------//
//  NEW EDICT FIELDS  //
//--------------------//
.entity burner;         // The flame generator linked on an entity.


//==========================================================================
//  Frame Data

//  Frame Macros for modified 'flame2.mdl'.
$cd id1/models/flame2
$origin 0 0 12
$base base
$skin skin

// These are grouped scenes.
$frame  flame
$frame  flameb

// These scenes are not grouped.
$frame  ember1 ember2 ember3 ember4 ember5 ember6


//==========================================================================
//  General Fire Code

//==========================================================================

//------------------------------------------------------------------------//
//  This makes an entity do a think function right now.
//------------------------------------------------------------------------//
void(entity ent, void() thinkst) PM_Think =
{
    local   entity  oself;

    oself = self;
    self = ent;
    thinkst ();
    self = oself;
};

//------------------------------------------------------------------------//
//  This checks if a given point in space is in water.
//------------------------------------------------------------------------//
float(vector vec) PM_VecInWater =
{
    local   float   content;

    content = pointcontents (vec);

    if (content == CONTENT_WATER)
        return TRUE;
    if (content == CONTENT_SLIME)
        return TRUE;
    if (content == CONTENT_LAVA)
        return TRUE;

    // Not in water.
    return FALSE;
};

//------------------------------------------------------------------------//
//  This returns the water level of an entity.
//------------------------------------------------------------------------//
float(entity ent) PM_WaterLevel =
{
    local   vector  spot;

    spot = ent.origin;
    spot_z = ent.origin_z + ent.view_ofs_z;
    if (PM_VecInWater (spot))
        return 3;
    spot_z = ent.origin_z + (ent.mins_z + ent.maxs_z) * 0.5;
    if (PM_VecInWater (spot))
        return 2;
    spot_z = ent.origin_z + ent.mins_z + 1;
    if (PM_VecInWater (spot))
        return 1;
    return 0;
};


//==========================================================================
//  Fire Damage

void(entity victim, entity attacker, float burn) PM_Ignite;

void(entity ent) PM_RemoveFlares;
void() muzzleflash;

//------------------------------------------------------------------------//
//  This checks if entity resists fire.
//------------------------------------------------------------------------//
float(entity ent) PM_FireResistant =
{
    if (ent.classname == "monster_shambler")
        return TRUE;

    // Everything not listed takes normal damage from fire.
    return FALSE;
};

//------------------------------------------------------------------------//
//  This inflicts standard fire damage like in Blood.
//------------------------------------------------------------------------//
void(entity targ, entity inflictor, entity attacker) PM_FireDamage =
{
    if (!PM_FireResistant (targ))
        T_Damage (targ, inflictor, attacker, 0.75, DF_FIRE | DF_MIN_PAIN, "fire");
};

//------------------------------------------------------------------------//
//  This damages a single entity and possibly sets it on fire.
//------------------------------------------------------------------------//
void(entity victim, entity fire, float damage, float burn) PM_BurnDamage =
{
    // Set victim on fire first.
    if (burn > 0)
        PM_Ignite (victim, fire.owner, burn);

    // Apply damage next immediately.
    if (damage > 0)
        T_Damage (victim, fire, fire.owner, damage, DF_FIRE, fire.deathtype);
};

//------------------------------------------------------------------------//
//  This damages and ignites entities within a certain radius.
//
//  NOTE:  Targets take damage multipled by a fraction equal to
//         one minus the distance divided by the radius.  At the
//         point of fire's origin, damage is 100%.  At maximum
//         distance (i.e, equal to radius), damage is 0%.
//------------------------------------------------------------------------//
void(entity fire, float damage, float burn, entity ignore) BurnRadius =
{
    local   float   fade;       // Distance multiplier.
    local   float   radius;

    if (fire.height > 0)
    {
        radius = fire.height;
        fade = 1 - fire.distance;
        if (fade < 0)
            fade = 0;   // Do constant damage.
    }
    else
    {
        // Emulate default radius damage.
        fade = floor(damage + burn);
        if (fade <= 0)
            return;     // Too weak to damage.

        radius = fade + 40;
        fade = radius * 0.5 / fade;
    }

    local   entity  head;

    head = findradius(fire.origin, radius);

    // General case -- radius damage decreases linearly from the center.
    local   vector  org;
    local   float   dist;

    while (head)
    {
        if (head != ignore)
            if (CanDamage (head, fire))
            {
                org = head.origin + (head.mins + head.maxs)*0.5;
                dist = vlen (fire.origin - org);
                dist = 1 - (dist * fade / radius);
                PM_BurnDamage (head, fire, damage * dist, burn * dist);
            }

        head = head.chain;
    }
};


//==========================================================================
//  Custom Explosions

//------------------------------------------------------------------------//
//  This makes some smoke.
//
//  FIXME:  Useless in QW.
//------------------------------------------------------------------------//
void(entity fire) PM_MakeSmoke =
{
    #ifndef QUAKEWORLD
    particle (fire.origin, '0 0 100', 6, 50);
    #endif
};

//------------------------------------------------------------------------//
//  This make some steam.
//------------------------------------------------------------------------//
void(entity fire) PM_MakeSteam =
{
    sound (fire, CHAN_AUTO, "player/slimbrn2.wav", 1, ATTN_NORM);
    PM_MakeSmoke (fire);
};


//==========================================================================
//  Burn Control

//----------------------------------------------------/ New Code /--------//
//  This extinguishes the fire burning on a player (or other entity).
//  This function should be called whenever the fire burning on an
//  entity must be removed immediately.
//
//  Examples who and when this should be called for:
//  * All players (and their surrogates) when the level ends.
//  * Anytime a player respawns after dying (from the 'kill' command).
//------------------------------------------------------------------------//
void(entity ent) PM_KillBurner =
{
    // Check if the entity is linked to a burning flame.
    if (ent.burner)
    {
        // Unlink and remove the burning flame.
        remove (ent.burner);
        ent.burner = world;
    }

    // Remove the flares too.
    PM_RemoveFlares (ent);
};

//------------------------------------------------------------------------//
//  This checks if 'ent' is on fire and burning.
//------------------------------------------------------------------------//
float(entity ent) PM_IsBurning =
{
    return ent.burner;
};

//------------------------------------------------------------------------//
//  These animate the embers that rise from a burning entity.
//------------------------------------------------------------------------//
void()  m_ember1 =[   $ember1,    m_ember2] {};
void()  m_ember2 =[   $ember2,    m_ember3] {};
void()  m_ember3 =[   $ember3,    m_ember4] {};
void()  m_ember4 =[   $ember4,    m_ember5] {};
void()  m_ember5 =[   $ember5,    m_ember6] {};
void()  m_ember6 =[   $ember6,    SUB_Remove] {};

//------------------------------------------------------------------------//
//  This makes flaming embers rise from a burning victim.
//
//  NOTE:  Assumes 'self' == flame generator!
//------------------------------------------------------------------------//
void() PM_MakeEmbers =
{
    local   entity  fire;       // The new fire that will be created.
    local   vector  spot;       // The spot where the new fire will appear.
    local   float   loop, r;

    if (gametype != GAME_SINGLE_PLAYER)
    {
        // In netgames, keep flames down to a minimum.
        if ((floor(time * 10) & 3) == 0)
            return;     // No flames on each 4th frame.
        loop = 1;
    }
    else if (self.dmg > 100)
        loop = 2;
    else if (self.dmg > 50)
    {
        if (floor(time * 10) & 1)
            loop = 2;
        else
            loop = 1;
    }
    else
        loop = 1;

    while (loop > 0)
    {
        spot   = self.enemy.size * 0.5;
        spot_x = spot_x * (random() - 0.5);
        spot_y = spot_y * (random() - 0.5);
        spot_z = spot_z * (random() - 0.5);
        spot   = spot + self.enemy.origin +
            (self.enemy.mins + self.enemy.maxs) * 0.5;

        // Create the fire.
        fire = spawn();
        setmodel (fire, "progs/flame2.mdl");
        setsize (fire, '0 0 0', '0 0 0');
        setorigin (fire, spot);

        fire.solid      = SOLID_NOT;
        fire.takedamage = DAMAGE_NO;
        fire.frame      = $ember1;
        fire.owner      = self.enemy;
        fire.movetype   = MOVETYPE_FLY;
        fire.velocity   = '0 0 100';

        // Animate the flame.
        r = random() * 3;
        if (r > 2)
            PM_Think (fire, m_ember3);
        else if (r > 1)
            PM_Think (fire, m_ember2);
        else
            PM_Think (fire, m_ember1);

        // Advance the loop.
        loop = loop - 1;
    }
};

//------------------------------------------------------------------------//
//  This keeps the fire on an entity burning.
//------------------------------------------------------------------------//
void() PM_Burn =
{
    // Check for removal.
    if (self.dmg <= 0)
    {
        // Fuel is all gone.
        self.enemy.burner = world;
        remove (self);
        return;
    }
    if (self.enemy.think == SUB_Remove)
        if (self.enemy.nextthink + 1 < time)
        {
            // Enemy will be removed from the game.
            self.enemy.burner = world;
            remove (self);
            return;
        }

    // Check if victim is deep enough in water.
    local   vector  spot;

    if (self.enemy.view_ofs == '0 0 0')
        spot = self.enemy.origin + (self.enemy.mins + self.enemy.maxs) * 0.5;
    else
        spot = self.enemy.origin + self.enemy.view_ofs;

    if (PM_VecInWater (spot))
    {
        // Victim is submerged under some liquid.
        setorigin (self, spot);     // So steam comes from enemy.

        // Put out the fire and make some steam.
        self.enemy.burner = world;
        PM_MakeSteam (self);
        remove (self);
        return;
    }

    // Don't let victim burn for more than 20 seconds (default).
    // 200 * 0.1 sec. = 20 sec.
    if (self.dmg > 200)
        self.dmg = 200;

    // Keep on burning.
    PM_MakeEmbers ();

    self.dmg = self.dmg - 1;    // Update the burn damage limit.
    PM_FireDamage (self.enemy, self.enemy, self.owner);

    self.nextthink  = time + 0.1;
};

//------------------------------------------------------------------------//
//  This sets the victim on fire.
//------------------------------------------------------------------------//
void(entity victim, entity attacker, float burn) PM_Ignite =
{
    // Check for fire immunity.
    if (!victim.takedamage)
        return;     // Immune to damage.

    // FIXME:  If not a creature, don't burn.

    // Check if the entity is linked to a burning flame.
    if (victim.burner)
    {
        // Add fuel to fire.  Yes, fire can be stolen by another attacker.
        victim.burner.dmg   = victim.burner.dmg + burn;
        victim.burner.owner = attacker;
        return;
    }

    // Spawn the burner (flame generator).
    local   entity  fire;

    fire = spawn();
    setmodel (fire, string_null);
    setsize (fire, '0 0 0', '0 0 0');
    setorigin (fire, VEC_ORIGIN);       // Doesn't matter where it is.
    fire.solid      = SOLID_NOT;
    fire.takedamage = DAMAGE_NO;
    fire.frame      = 0;
    fire.owner      = attacker;
    fire.enemy      = victim;
    fire.classname  = "burner";
    fire.deathtype  = "fire";
    fire.wait       = time;
    fire.dmg        = burn;
    fire.nextthink  = 0.1;      // ASAP
    fire.think      = PM_Burn;

    victim.burner   = fire;     // Link entity to fire.
};


//==========================================================================
//  Flaming Death

// NOTE:  Used by monsters only.

void() PM_BecomeOldExplosion;
//------------------------------------------------------------------------//
//  The creates an explosion entity from scratch.
//------------------------------------------------------------------------//
void(vector spot) PM_MakeExplosion =
{
    local   entity  e;

    e = spawn();
    setmodel (e, "progs/s_explod.spr");
    setsize (e, '0 0 0', '0 0 0');
    setorigin (e, spot);

    PM_Think (e, PM_BecomeOldExplosion);
};

//------------------------------------------------------------------------//
//  This makes the death flame produce a little smoke and embers
//  before it disappears.
//------------------------------------------------------------------------//
void() PM_DeathFlameDying =
{
    if (self.wait <= time)
    {
        // Done burning.
        remove (self);
        return;
    }

    local   vector  spot;

    makevectors (self.enemy.angles);
    spot = self.enemy.origin + (v_forward * self.dest_x) +
        (v_right * self.dest_y) + (v_up * self.dest_z);
    setorigin (self, spot);

    // Make a thin trail of smoke above the flame, plus a few embers.
    local   float   ftime;
    ftime = floor(time * 10);
    if (ftime & 1)
    {
        #ifndef QUAKEWORLD
        particle (spot, '0 0 100', 6, 5);
        #endif
        if (!PM_VecInWater (spot))
            if ((ftime & 2) || (random() < 0.5))
                PM_MakeEmbers ();
    }

    self.nextthink = time + 0.1;
};

//------------------------------------------------------------------------//
//  This checks if the death flame should stop burning.
//------------------------------------------------------------------------//
float() PM_EndDeathFlame =
{
    // Stop burning once the enemy is really dead.
    if (self.enemy.deadflag == DEAD_DEAD)
        return TRUE;

    // If solid-only burn is on, then stop once enemy becomes non-solid.
    if (self.style)
        if (self.enemy.solid == SOLID_NOT)
            return TRUE;

    // Keep on burning.
    return FALSE;
};

//------------------------------------------------------------------------//
//  This makes the death flame burn.
//------------------------------------------------------------------------//
void() PM_DeathFlameThink =
{
    if (PM_EndDeathFlame ())
    {
        // Done burning.
        if (self.model == self.mdl)
        {
            PM_MakeExplosion (self.origin);
            setmodel (self, string_null);
        }
        self.think = PM_DeathFlameDying;
        self.wait = time + 1 + random() * 2;
        PM_DeathFlameDying ();
        return;
    }

    // Make the flame stick to its target.
    local   vector  spot;

    makevectors (self.enemy.angles);
    spot = self.enemy.origin + (v_forward * self.dest_x) +
        (v_right * self.dest_y) + (v_up * self.dest_z);
    setorigin (self, spot);

    // Make a thin trail of smoke above the flame, plus a few embers.
    #ifndef QUAKEWORLD
    particle (spot + '0 0 24', '0 0 100', 6, 5);
    #endif
    if (floor(time * 10) & 1)
        PM_MakeEmbers ();

    // In case enemy is not dead, do some damage.
    if (self.enemy.takedamage)
        T_Damage (self.enemy, self, self.owner, 1, DF_FIRE, "fire");

    // Flame has different effects depending on its contents.
    if (PM_VecInWater (spot))
    {
        // Hide the flame and make more steam in its place.
        if (self.model == self.mdl)
        {
            setmodel (self, string_null);
            sound (self, CHAN_AUTO, "player/slimbrn2.wav", 1, ATTN_NORM);
        }
        #ifndef QUAKEWORLD
        particle (spot, '0 0 100', 6, 50);
        #endif
    }
    else
    {
        if (self.model != self.mdl)
        {
            PM_MakeExplosion (spot);
            setmodel (self, self.mdl);
        }

        // Burn nearby enemies.
        local   entity  head;

        head = findradius(self.origin, 60);
        while (head)
        {
            if (head != self.enemy)
                if (CanDamage (head, self))
                    PM_FireDamage (head, self, self.owner);

            head = head.chain;
        }
    }

    self.nextthink = time + 0.1;
};

//------------------------------------------------------------------------//
//  This spawns a large burning flame on a dying target.  This should
//  be called ONLY from the target's 'th_die()' function.
//
//  NOTE:  Assumes 'self' == dying victim to be burned!
//------------------------------------------------------------------------//
void(vector offset) PM_DeathFlame =
{
    // Make some fire!
    local   entity  fire;       // The new fire that will be created.
    local   vector  spot;       // The spot where the new fire will appear.

    // Get the spot where the fire will erupt.
    spot = self.origin + offset;

    // Make a small flaming explosion.
    PM_MakeExplosion (spot);

    // Remove flame generator if any... since this is a bigger fire.
    PM_KillBurner (self);

    // Create the fire.
    fire = spawn();
    setmodel (fire, "progs/flame2.mdl");
    setsize (fire, '0 0 0', '0 0 0');
    setorigin (fire, spot);
    fire.frame      = $flameb;  // Use a *big* flame.
    fire.solid      = SOLID_NOT;
    fire.takedamage = DAMAGE_NO;
    fire.effects    = fire.effects | EF_DIMLIGHT;
    fire.owner      = self.enemy;
    fire.enemy      = self;
    fire.mdl        = fire.model;
    fire.dest       = offset;
    fire.nextthink  = 0.1;  // ASAP
    fire.think      = PM_DeathFlameThink;
    fire.classname  = "fire";

    // HACK:  Zombie...
    if (self.classname != "monster_zombie")
        fire.style = TRUE;
    else
        fire.style = FALSE;

    // Play some sound.
    sound (fire, CHAN_AUTO, "weapons/flaregun/burstflm.wav", 1, ATTN_NORM);
};


////////////////////////////////////////////////////////////////////////////
//  Flame weapons (flares and napalm)
////////////////////////////////////////////////////////////////////////////

.float  flare_time;     // Used so only one flare can burn per frame.


//==========================================================================
//  Embers

// FIXME:  Embers can be done much more efficiently with a TE -- use
//         a custom engine.

//------------------------------------------------------------------------//
//  This enforces air resistance on embers and updates their angles.
//------------------------------------------------------------------------//
void() PM_EmberThink =
{
    if (self.pausetime <= time)
    {
        m_ember4 ();
        return;
    }

    local   vector  dir;

    dir = normalize (self.velocity);

    // Cheap hack -- apply air resistance by reducing velocity.
    self.velocity = self.velocity * 0.75;

    // Update angles to its current direction.
    self.angles = vectoangles(dir) + '90 0 0';

    // Think again next frame.
    self.nextthink = time + 0.1;
};

//------------------------------------------------------------------------//
//  This throws a shower of embers.
//------------------------------------------------------------------------//
void(float ents) ThrowEmbers =
{
    // Not in QuakeWorld!
    #ifdef QUAKEWORLD
    return;
    #endif

    local   entity  fire;
    local   vector  dir;
    local   float   loop;

    // Make fewer embers in netgames.
    if (gametype != GAME_SINGLE_PLAYER)
        ents = floor(ents * 0.5);

    loop = ents * 6;
    while (loop > 0)
    {
        // Get initial direction.
        dir_x = (random() - 0.5) * 180;
        dir_y = random() * 360;
        dir_z = 0;
        makevectors (dir);
        dir = v_forward;

        traceline (self.origin, self.origin + dir*64, FALSE, other);
        if (trace_fraction == 1.0)
        {
            // Ember will not impact the wall immediately.
            fire = spawn();
            setmodel (fire, "progs/flame2.mdl");
            setsize (fire, '0 0 0', '0 0 0');
            setorigin (fire, self.origin);

            fire.frame    = $ember4;
            fire.solid    = SOLID_BBOX;
            fire.movetype = MOVETYPE_TOSS;
            fire.owner    = other;

            fire.velocity = dir * (200 + random() * 800);
            fire.angles = vectoangles(dir) + '90 0 0';

            // Make embers disappear faster in netgames.
            if (gametype != GAME_SINGLE_PLAYER)
                fire.pausetime = time + random();
            else
                fire.pausetime = time + 3 + random() * 2;

            fire.touch = SUB_Remove;
            fire.nextthink = time + 0.1;
            fire.think = PM_EmberThink;

            ents = ents - 1;
            if (ents <= 0)
                return;
        }

        loop = loop - 1;
    }
};


//==========================================================================
//  Standard Flares

//------------------------------------------------------------------------//
//  This removes all flares from a single entity.
//  This should be called when a player disconnects from the server.
//------------------------------------------------------------------------//
void(entity ent) PM_RemoveFlares =
{
    local   entity  head;

    head = find (world, classname, "flare");
    while (head)
    {
        if (head.enemy == ent)
        {
            // Can't remove now, we need head for finding more flares.
            head.nextthink  = time + 0.1;
            head.think      = SUB_Remove;
        }
        head = find (head, classname, "flare");
    }
};


//==========================================================================
//  Alt-mode Flares

void(entity client) PsychoCaleb;

//------------------------------------------------------------------------//
//  This animates the napalm cloud, and makes it burn things around it.
//------------------------------------------------------------------------//
void() PM_OldExThink =
{
    if (self.frame >= 5)
    {
        remove (self);
        return;
    }
    self.frame = self.frame + 1;

    // Think again next frame.
    self.nextthink = time + 0.1;
};

//------------------------------------------------------------------------//
//  Turns entity into a flaming napalm cloud.
//------------------------------------------------------------------------//
void() PM_BecomeOldExplosion =
{
    self.movetype   = MOVETYPE_NONE;
    self.velocity   = '0 0 0';
    self.touch      = SUB_Null;
    self.frame      = 0;
    setmodel (self, "progs/s_oldexp.spr");
    self.solid      = SOLID_NOT;

    self.nextthink  = time + 0.1;
    self.think      = PM_OldExThink;
};


//==========================================================================
//  Burn Trigger

.float  burn_time;

void() burn_touch =
{
    if (other.burn_time <= time)
    {
        other.burn_time = time + 0.1;
        if (other.takedamage)
            PM_FireDamage (other, self, self);
    }

    // Once an object moves into the field, make sure it takes more hits
    // if it stops moving inside the field.
    force_retouch = 2;
};

/*QUAKED trigger_burn (.5 .5 .5) ?
This variable-sized trigger is similar to 'trigger_hurt'.
Any object touching this will suffer burn damage for each
frame the object stays in the triggers.  Fire-resistant
monsters like stone gargoyles are immune to this effect.
This should be placed above stoves, grills, and the like.
(e.g., the rat burgers stand in e1m4 -- Dark Carnival.)
*/
void() trigger_burn =
{
    InitTrigger ();
    self.touch = burn_touch;
};


//===========================/  END OF FILE  /===========================//
