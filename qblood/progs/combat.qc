/*  Copyright (C) 1996-1997  Id Software, Inc.

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


//--------------------//
//  NEW EDICT FIELDS  //
//--------------------//
.float      armor_fire;
.float      armor_body;
.float      armor_mind;

.float      remain_arm;
.float      remain_dmg;

.float      reflect_finished;

void() T_MissileTouch;
void() info_player_start;
void(entity attacker) ClientObituary;
void(entity inflictor, entity attacker, float damage, entity ignore, string dtype) T_RadiusDamage;
#ifndef QUAKEWORLD
void() monster_death_use;
#endif


//============================================================================

/*
============
CanDamage

Returns true if the inflictor can directly damage the target.  Used for
explosions and melee attacks.
============
*/
float(entity targ, entity inflictor) CanDamage =
{
// bmodels need special checking because their origin is 0,0,0
    if (targ.movetype == MOVETYPE_PUSH)
    {
        traceline(inflictor.origin, 0.5 * (targ.absmin + targ.absmax), TRUE, self);
        if (trace_fraction == 1)
            return TRUE;
        if (trace_ent == targ)
            return TRUE;
        return FALSE;
    }

    traceline(inflictor.origin, targ.origin, TRUE, self);
    if (trace_fraction == 1)
        return TRUE;
    traceline(inflictor.origin, targ.origin + '15 15 0', TRUE, self);
    if (trace_fraction == 1)
        return TRUE;
    traceline(inflictor.origin, targ.origin + '-15 -15 0', TRUE, self);
    if (trace_fraction == 1)
        return TRUE;
    traceline(inflictor.origin, targ.origin + '-15 15 0', TRUE, self);
    if (trace_fraction == 1)
        return TRUE;
    traceline(inflictor.origin, targ.origin + '15 -15 0', TRUE, self);
    if (trace_fraction == 1)
        return TRUE;

    return FALSE;
};


/*
============
Killed
============
*/
void(entity targ, entity attacker) Killed =
{
    local entity oself;

    oself = self;
    self = targ;

    if (self.health < -99)
        self.health = -99;      // don't let sbar look bad if a player

    if (self.movetype == MOVETYPE_PUSH || self.movetype == MOVETYPE_NONE)
    {   // doors, triggers, etc
        self.th_die ();
        self = oself;
        return;
    }

    self.enemy = attacker;

// bump the monster counter
    if (self.flags & FL_MONSTER)
    {
        killed_monsters = killed_monsters + 1;
        WriteByte (MSG_ALL, SVC_KILLEDMONSTER);
    }

    ClientObituary (attacker);

    self.takedamage = DAMAGE_NO;
    self.touch = SUB_Null;
    self.effects = 0;

    #ifndef QUAKEWORLD
    monster_death_use();
    #endif

    self.th_die ();

    self = oself;
};


#define MAX_RECURSION_COUNT 6

/*
============
T_Damage

The damage is coming from inflictor, but get mad at attacker
This should be the only function that ever reduces health.
============
*/
#ifndef QUAKEWORLD
// PM:  Support function that checks if both sides are friendly enough.
float(entity victim, entity attacker) PM_MonsterAlly =
{
    // Check if target should fight back.
    if (victim == attacker.enemy)
        if (attacker.flags & FL_MONSTER)
            return FALSE;   // Always defend against deliberate attack.
    if (victim.classname == "monster_army")
        return FALSE;   // Standard -- Grunts attack anything.
    if (victim.classname != attacker.classname)
        return FALSE;   // Standard -- Different species don't get along.

    // No reason to get angry.
    return TRUE;
};

// PM:  Support function to check if target should fight the attacker.
float(entity victim, entity attacker) PM_GetMad =
{
    // Check if fighting back is even possible.
    if (victim == attacker)
        return FALSE;   // Don't attack itself.
    if (victim.enemy == attacker)
        return FALSE;   // Already mad at attacker.
    if (attacker.health <= 0)
        return FALSE;   // Attacker is already dead.
    if (attacker.classname == "monster_boss")
        return FALSE;   // Chthon is immune to normal damage.
    if (PM_MonsterAlly (victim, attacker))
        return FALSE;   // Both sides are friendly.

    // Fight back!
    return TRUE;
};
#endif

// PM:  Blood's armor damage protection algorithm, or close to it.
float(entity targ, float armour, float damage) PM_ArmorSave =
{
    local   float   hi, lo, save, add;

    hi = armour;
    if (hi > 200)
        hi = 200;
    lo = hi - damage;
    if (lo < 0)
        lo = 0;
    save = (hi + lo) * 0.5;

    save = 20 + (save * 0.4);
    if (save < 1)
        save = 1;
    add = save * 0.01 * damage;

    // Now adjust the armor.  Remember fractions for later use.
    save = floor (add);
    targ.remain_arm = targ.remain_arm + (add - save);
    if (targ.remain_arm >= 1)
    {
        add = floor(targ.remain_arm);
        save = save + add;
        targ.remain_arm = targ.remain_arm - add;
    }
    if (save >= armour)
    {
        // Lost all armor.
        save = armour;
        targ.remain_arm = 0;
    }

    return save;
};

// PM:  Below is the new damage function that replaces 'T_Damage'.
void(entity targ, entity inflictor, entity attacker, float damage, float dflags, string dtype) T_NewDamage =
{
    local   vector  dir;
    local   entity  oldself;
    local   float   save;
    local   float   take;
    local   float   protected;  // PM:  Boolean for invulnerability.

    #ifdef QUAKEWORLD
    local   string  attackerteam, targteam;
    #endif

    if (!targ.takedamage)
        return;

    // If we are at the maximum recursion deep supported, just return
    if (recursioncount >= MAX_RECURSION_COUNT)
        return;
    recursioncount = recursioncount + 1;

    // Used by buttons and triggers to set activator for target firing
    damage_attacker = attacker;
    damage_inflictor = inflictor;

// FIXME:  Remove quad damage.
    // Check for quad damage powerup on the attacker.
    if (attacker.super_damage_finished > time)
        if (inflictor.classname != "door")
            damage = damage * 4;

    #ifndef QUAKEWORLD
    if (dflags & DF_RADIUS)
    {
        // shambler takes half damage from all explosions
        if (targ.classname == "monster_shambler")
            damage = damage * 0.5;
    }

    // Players take more damage at higher skill levels.
    if (!deathmatch)
        if (targ.classname == "player")
            damage = damage * (1 + (cvar("skill") * 0.4));
    #endif

    // Save fractions for later use.
    take = damage + targ.remain_dmg;
    damage = floor (take);
    targ.remain_dmg = take - damage;

    // Figure momentum add
    if ( (inflictor != world) && (targ.movetype == MOVETYPE_WALK) )
    {
        dir = targ.origin - (inflictor.absmin + inflictor.absmax) * 0.5;
        dir = normalize(dir);
        targ.velocity = targ.velocity + dir*damage*8;
    }

    protected = FALSE;
    take = damage;
    save = 0;

    if (!(dflags & DF_NO_PROTECT))
    {
        // Save damage based on the target's armor level, but do not apply
        // the savings to the armor yet... in case target is invulnerable.
        if (dflags & DF_FIRE)
            save = PM_ArmorSave (targ, targ.armor_fire, damage);
        else if (dflags & DF_BODY)
            save = PM_ArmorSave (targ, targ.armor_body, damage);
        else if (dflags & DF_MIND)
            save = PM_ArmorSave (targ, targ.armor_mind, damage);
        take = ceil(damage-save);

        // Check for godmode or invincibility.
        if (targ.flags & FL_GODMODE)
        {
            protected = TRUE;
        }
        else if (targ.invincible_finished >= time)
        {
            if (self.invincible_sound < time)
            {
                sound (targ, CHAN_ITEM, "bludbath/powerup.wav", 1, ATTN_NORM);
                self.invincible_sound = time + 2;
            }
            protected = TRUE;
        }
        else
        {
            // Team play avoidance.
            #ifdef QUAKEWORLD
            //ZOID 12-13-96: self.team doesn't work in QW.  Use keys
            attackerteam = infokey(attacker, "team");
            targteam = infokey(targ, "team");

            if ((teamplay == 1 || (teamplay == 3 && targ != attacker)) &&
            attacker.classname == "player" && attackerteam != "" &&
            targteam == attackerteam       && inflictor.classname !="door"   )
            #else
            if ( (teamplay == 1) && (targ.team > 0)&&(targ.team == attacker.team) )
            #endif
                protected = TRUE;
        }
    }

    // If client, use damage values for hud effects.
    if (targ.flags & FL_CLIENT)
    {
        targ.dmg_take = targ.dmg_take + take;
        targ.dmg_save = targ.dmg_save + save;
        targ.dmg_inflictor = inflictor;

        // Leave the hud alone if nopain.
        if (dflags & DF_MIN_PAIN)
            if (protected || (targ.pain_finished > time))
            {
                // Negate above changes.
                targ.dmg_take = targ.dmg_take - take;
                targ.dmg_save = targ.dmg_save - save;
            }
    }

    if (protected)
    {
        // Decrease the recursion count.
        recursioncount = recursioncount - 1;
        return;     // Target is invulnerable to damage.
    }

    // Now check for armor damage.
    if (save)
    {
        if (dflags & DF_FIRE)
        {
            targ.armor_fire = targ.armor_fire - save;
            if (targ.armor_fire <= 0)
            {
                targ.armorvalue = targ.armor_fire = 0;
                targ.items = targ.items - (targ.items & IT_ARMOR2);
            }
            else
            {
                targ.armorvalue = targ.armor_fire;
                targ.items = targ.items - (targ.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR2;
            }
        }
        else if (dflags & DF_BODY)
        {
            targ.armor_body = targ.armor_body - save;
            if (targ.armor_body <= 0)
            {
                targ.armorvalue = targ.armor_body = 0;
                targ.items = targ.items - (targ.items & IT_ARMOR1);
            }
            else
            {
                targ.armorvalue = targ.armor_body;
                targ.items = targ.items - (targ.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR1;
            }
        }
        else if (dflags & DF_MIND)
        {
            targ.armor_mind = targ.armor_mind - save;
            if (targ.armor_mind <= 0)
            {
                targ.armorvalue = targ.armor_mind = 0;
                targ.items = targ.items - (targ.items & IT_ARMOR3);
            }
            else
            {
                targ.armorvalue = targ.armor_mind;
                targ.items = targ.items - (targ.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR3;
            }
        }
//        else
//            Bprint (PRINT_MEDIUM, "Unknown armor\n");
    }

    // Do the damage.
    targ.health = targ.health - take;
    if (targ.health <= 0)
    {
        // Target was slain!
        if (!targ.deadflag)
            targ.deathtype = dtype;
        Killed (targ, attacker);

        // Decrease the recursion count.
        recursioncount = recursioncount - 1;
        return;
    }

    // React to the damage.
    oldself = self;
    self = targ;

    #ifndef QUAKEWORLD
    if ( (self.flags & FL_MONSTER) && attacker != world)
        if (!(dflags & DF_MIN_PAIN) || !self.enemy)
            if (PM_GetMad (self, attacker))
            {
                if (self.enemy.classname == "player")
                    self.oldenemy = self.enemy;
                self.enemy = attacker;
                FoundTarget ();
            }
    #endif

    if (self.th_pain)
    {
        targ.deathtype = dtype;     // For player pain sounds.

        // Set value for monsters that support nopain.
        if (dflags & DF_MIN_PAIN)
            take = 0;

        self.th_pain (attacker, take);

        #ifndef QUAKEWORLD
        // nightmare mode monsters don't go into pain frames often
        if (skill == 3)
            self.pain_finished = time + 5;
        #endif
    }

    self = oldself;

    // Decrease the recursion count
    recursioncount = recursioncount - 1;
};


void(entity targ, entity inflictor, entity attacker, float damage) T_Damage=
{
    // PM:  Default to the new damage function.
    T_NewDamage (targ, inflictor, attacker, damage, DF_BODY, string_null);
};

/*
============
T_RadiusDamage
============
*/
void(entity inflictor, entity attacker, float damage, entity ignore, string dtype) T_RadiusDamage =
{
    local   float   dflags;
    if (dtype == "tesla")
        dflags = DF_RADIUS | DF_BODY;
    else
        dflags = DF_RADIUS | DF_FIRE;

    local   float   points;
    local   entity  head;
    local   vector  org;

    head = findradius(inflictor.origin, damage+40);

    while (head)
    {
        if (head != ignore)
        {
            if (head.takedamage)
            {
                org = head.origin + (head.mins + head.maxs)*0.5;
                points = 0.5*vlen (inflictor.origin - org);
                if (points < 0)
                    points = 0;
                points = damage - points;
// PM:  Attacker takes full damage in Blood AFAIK.
                if (points > 0)
                {
                    if (CanDamage (head, inflictor))
                    {
                        T_NewDamage (head, inflictor, attacker, points, dflags, dtype);
                    }
                }
            }
        }
        head = head.chain;
    }
};

/*
============
T_BeamDamage
============
*/
void(entity attacker, float damage) T_BeamDamage =
{
    // PM:  Default to another function.  Is 'T_BeamDamage()' ever used?
    T_RadiusDamage (attacker, attacker, damage, world, string_null);
};

