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


//==========================================================================
//  Frame Data

//  Frame Macros for modified 'flame2.mdl'.
$modelname flame2

// These are grouped scenes.
$frame flame
$frame flameb

// These scenes are not grouped.
$frame ember1 ember2 ember3 ember4 ember5 ember6


//==========================================================================
//  General Fire Code

//==========================================================================

//------------------------------------------------------------------------//
//  This checks if a given point in space is in water.
//------------------------------------------------------------------------//
float(vector vec) VecInWater =
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


//==========================================================================
//  Fire Damage

void(entity victim, entity attacker, float burn, float dmgtype) Ignite;

void(entity ent) RemoveFlares;
void() muzzleflash;

//------------------------------------------------------------------------//
//  This inflicts standard fire damage like in Blood.
//------------------------------------------------------------------------//
void(entity targ, entity inflictor, entity attacker, float dmgtype) FireDamage =
{
    T_Damage (targ, inflictor, attacker, 0.75, dmgtype | DF_MIN_PAIN, "fire");
};

//------------------------------------------------------------------------//
//  This damages a single entity and possibly sets it on fire.
//------------------------------------------------------------------------//
void(entity victim, entity fire, float damage, float dmgtype, float burn) BurnDamage =
{
    // Set victim on fire first.
    if (burn > 0)
        Ignite (victim, fire.owner, burn, dmgtype);

    // Apply damage next immediately.
    if (damage > 0)
        T_Damage (victim, fire, fire.owner, damage, dmgtype, fire.deathtype);
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
                BurnDamage (head, fire, damage * dist, DF_FIRE, burn * dist);
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
void(entity fire) MakeSmoke =
{
    #ifndef QUAKEWORLD
    particle (fire.origin, '0 0 100', 6, 50);
    #endif
};

//------------------------------------------------------------------------//
//  This make some steam.
//------------------------------------------------------------------------//
void(entity fire) MakeSteam =
{
    sound (fire, CHAN_AUTO, "player/slimbrn2.wav", 1, ATTN_NORM);
    MakeSmoke (fire);
};


//==========================================================================
//  Burn Control

//------------------------------------------------------------------------//
//  This extinguishes the fire burning on a player (or other entity).
//  This function should be called whenever the fire burning on an
//  entity must be removed immediately.
//
//  Examples who and when this should be called for:
//  * All players (and their surrogates) when the level ends.
//  * Anytime a player respawns after dying (from the 'kill' command).
//------------------------------------------------------------------------//
void(entity ent) KillBurner =
{
    // Check if the entity is linked to a burning flame.
    if (ent.burner)
    {
        // Unlink and remove the burning flame.
        remove (ent.burner);
        ent.burner = world;
    }

    // Remove the flares too.
    RemoveFlares (ent);
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
//  MakeEmbers makes flaming embers rise from a burning victim.
//
//  NOTE: It assumes 'self' == flame generator!
//------------------------------------------------------------------------//
void() FlameThink =
{
    self.nextthink  = time + 0.1;

    self.alpha = self.alpha - 0.15;
    if (self.alpha <= 0.15)
    {
        self.think = SUB_Remove;
        self.velocity = '0 0 0';
    }
};

void() MakeEmbers =
{
    local   entity  fire;       // The new fire that will be created.
    local   vector  spot;       // The spot where the new fire will appear.
    local   float   r;

    // No flames on each 4th frame.
    if ((floor(time * 10) & 3) == 0)
        return;

    spot   = self.enemy.size * 0.5;
    spot_x = spot_x * (random() - 0.5);
    spot_y = spot_y * (random() - 0.5);
    spot_z = spot_z * (random() - 0.5);
    spot   = spot + self.enemy.origin +
        (self.enemy.mins + self.enemy.maxs) * 0.5;

    // Create the fire.
    fire = spawn();
    setmodel (fire, "progs/flame.spr");
    setsize (fire, '0 0 0', '0 0 0');
    setorigin (fire, spot);

    fire.solid      = SOLID_NOT;
    fire.takedamage = DAMAGE_NO;
    fire.owner      = self.enemy;
    fire.movetype   = MOVETYPE_FLY;
    fire.velocity   = '0 0 100';

    // Animate the flame.
    fire.alpha      = 0.9 - rint (0.4 * random ());
    fire.think      = FlameThink;
    fire.nextthink  = time + 0.1;
};

//------------------------------------------------------------------------//
//  This keeps the fire on an entity burning.
//------------------------------------------------------------------------//
void() Burn =
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

    if (VecInWater (spot))
    {
        // Victim is submerged under some liquid.
        setorigin (self, spot);     // So steam comes from enemy.

        // Put out the fire and make some steam.
        self.enemy.burner = world;
        MakeSteam (self);
        remove (self);
        return;
    }

    // Don't let victim burn for more than 10 seconds (default).
    if (self.dmg > 100)
        self.dmg = 100;

    // Keep on burning.
    MakeEmbers ();

    self.dmg = self.dmg - 1;    // Update the burn damage limit.
    FireDamage (self.enemy, self, self.owner, self.style);

    self.nextthink  = time + 0.1;
};

//------------------------------------------------------------------------//
//  This sets the victim on fire.
//------------------------------------------------------------------------//
void(entity victim, entity attacker, float burn, float dmgtype) Ignite =
{
    // Check for fire immunity.
    if (!victim.takedamage)
        return;     // Immune to damage.

    // If it's a door, a plat or a wall, don't burn
    if (victim.classname == "door")
        return;
    if (victim.classname == "plat")
        return;
    if (victim.classname == "exploding_wall")  // the other types of walls can't burn anyway
        return;

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
    fire.style      = dmgtype;  // DF_FIRE or DF_MIND
    fire.nextthink  = 0.1;      // ASAP
    fire.think      = Burn;
    fire.reset      = SUB_Remove;

    victim.burner   = fire;     // Link entity to fire.
};


////////////////////////////////////////////////////////////////////////////
//  Flame weapons (flares and napalm)
////////////////////////////////////////////////////////////////////////////


//==========================================================================
//  Embers

// FIXME:  Embers can be done much more efficiently with a TE -- use
//         a custom engine.

//------------------------------------------------------------------------//
//  This enforces air resistance on embers and updates their angles.
//------------------------------------------------------------------------//
void() EmberThink =
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
    #ifndef QUAKEWORLD
    local   entity  fire;
    local   vector  dir;
    local   float   loop;

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

            fire.pausetime = time + random();

            fire.touch = SUB_Remove;
            fire.nextthink = time + 0.1;
            fire.think = EmberThink;
            fire.reset = SUB_Remove;

            ents = ents - 1;
            if (ents <= 0)
                return;
        }

        loop = loop - 1;
    }
    #endif
};


//==========================================================================
//  Standard Flares

//------------------------------------------------------------------------//
//  This removes all flares from a single entity.
//  This should be called when a player disconnects from the server.
//------------------------------------------------------------------------//
void(entity ent) RemoveFlares =
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
void() OldExThink =
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
void() BecomeOldExplosion =
{
    self.movetype   = MOVETYPE_NONE;
    self.velocity   = '0 0 0';
    self.touch      = SUB_Null;
    self.frame      = 0;
    self.skin       = 0;
    setmodel (self, "progs/s_oldexp.spr");
    self.solid      = SOLID_NOT;

    self.nextthink  = time + 0.1;
    self.think      = OldExThink;
};
