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

void() T_MissileTouch;
void(entity attacker) ClientObituary;
void(entity inflictor, entity attacker, float damage, float dflags, entity ignore, string dtype) T_RadiusDamage;
void(entity player, entity attacker) Player_BrinkOfDeath;

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

	if (self.health < 0)
		self.health = 0;      // Blood had no negative sign, so nothing below 0

#ifndef NO_FRIKBOT

	if (!self.ishuman && self.classname == "player")
	{
		bot_start_topic(6);
		self.b_chattime = time - 0.1;
		bot_chat();
	}
#endif

	// doors, triggers, etc
	if (self.movetype == MOVETYPE_PUSH || self.movetype == MOVETYPE_NONE)
	{
		self.th_die();
		self = oself;
		return;
	}

	self.enemy = attacker;

	// bump the monster counter
	if (self.flags & FL_MONSTER)
	{
		killed_monsters = killed_monsters + 1;
		WriteByte(MSG_ALL, SVC_KILLEDMONSTER);
	}

	ClientObituary(attacker);

	self.takedamage = DAMAGE_NO;
	self.touch = SUB_Null;
	self.effects = 0;

	// fall to ground
	if (self.flags & FL_FLY)
		self.flags = self.flags - FL_FLY;
	if (self.flags & FL_SWIM)
		self.flags = self.flags - FL_SWIM;

	if (self.target)
	{
		activator = self.enemy;
		SUB_UseTargets();
	}

	self.th_die();

	self = oself;
};

// PM:  Blood's armor damage protection algorithm, or close to it.
float(entity targ, float armor, float damage) ArmorSave =
{
	local   float   hi, lo, save, add;

	hi = armor;
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
	if (save >= armor)
	{
		// Lost all armor.
		save = armor;
		targ.remain_arm = 0;
	}

	return save;
};

/*
============
T_Damage

The damage is coming from inflictor, but get mad at attacker
This should be the only function that ever reduces health.
============
*/

// PM:  Below is the new damage function that replaces 'T_Damage'.
void(entity targ, entity inflictor, entity attacker, float damage, float dflags, string dtype) T_Damage =
{
	local   vector  dir;
	local   entity  oldself;
	local   float   save;
	local   float   take;
	local   float   protected;  // PM:  Boolean for invulnerability.

	if (!targ.takedamage)
		return;

	// Some exploding_wall entities are only destroyable by explosives
	// FIXME: The damage code should really be rewritten to prevent these kinds of hack
	if (targ.spawnflags & 32                      &&
		targ.classname == "exploding_wall"        &&
		inflictor.classname != "exploding_barrel" &&  // TNT barrels
		inflictor.classname != "grenade"          &&  // All bombs, lighted Spray Can, Napalm Launcher (altfire)
		inflictor.classname != "missile")             // Napalm Launcher (normal), Life Leech
	{
		return;
	}

	// Hellhound / Cerebrus can't be hurt by fire, but can be hurt by the napalm launcher and TNT
	if ((targ.netname == "monster_hellhound" || targ.netname == "monster_cerebrus") && 
		(dflags & DF_BURN) &&
		inflictor.classname != "exploding_barrel" &&  // TNT barrels
		inflictor.classname != "grenade"          &&  // All bombs, lighted Spray Can, Napalm Launcher (altfire)
		inflictor.classname != "missile")             // Napalm Launcher (normal), Life Leech)
		return;	

	// If monsters are attacked while idling this gets their attack AI going
	if (targ.flags & FL_MONSTER && attacker.classname == "player" && targ.enemy.classname != "player")
		targ.enemy = attacker;

	// Used by buttons and triggers to set activator for target firing
	damage_attacker = attacker;
	damage_inflictor = inflictor;

	// NOTE: Players have armor, and no resist-values. -1 is invulnerable to that damage-type.
	// If the entity has resistance agains this damage-type, decrease the damage:
	if (!(dflags & DF_NO_PROTECT) && targ.classname != "player")
	{    
		if (dflags & DF_ACID && targ.resist_acid != 0)
		{
			if (targ.resist_acid < 0)
			{
				damage = 0;
			}
			else
			{
				damage = damage / targ.resist_acid;
			}
		}	    
		if (dflags & DF_SHOCK && targ.resist_shock != 0)
		{
			if (targ.resist_shock < 0)
			{
				damage = 0;
			}
			else
			{
				damage = damage / targ.resist_shock;
			}
		}
		if (dflags & DF_PUMMEL && targ.resist_pummel != 0)
		{
			if (targ.resist_pummel < 0)
			{
				damage = 0;
			}
			else
			{
				damage = damage / targ.resist_pummel;
			}
		}
		if (dflags & DF_FALL && targ.resist_fall != 0)
		{
			if (targ.resist_fall < 0)
			{
				damage = 0;
			}
			else
			{
				damage = damage / targ.resist_fall;
			}
		}
		if (dflags & DF_BURN && targ.resist_burn != 0)
		{
			if (targ.resist_burn < 0)
			{
				damage = 0;
			}
			else
			{
				damage = damage / targ.resist_burn;
			}
		}
		if (dflags & DF_BULLET && targ.resist_bullet != 0)
		{
			if (targ.resist_bullet < 0)
			{
				damage = 0;
			}
			else
			{
				damage = damage / targ.resist_bullet;
			}
		}
		if (dflags & DF_STAB && targ.resist_stab != 0)
		{
			if (targ.resist_stab < 0)
			{
				damage = 0;
			}
			else
			{
				damage = damage / targ.resist_stab;
			}
		}
		if (dflags & DF_EXPLODE && targ.resist_explode != 0)
		{
			if (targ.resist_explode < 0)
			{
				damage = 0;
			}
			else
			{
				damage = damage / targ.resist_explode;
			}
		}
		if (dflags & DF_GAS && targ.resist_gas != 0)
		{
			if (targ.resist_gas < 0)
			{
				damage = 0;
			}
			else
			{
				damage = damage / targ.resist_gas;
			}
		}
		if (dflags & DF_DROWN && targ.resist_drown != 0)
		{
			if (targ.resist_drown < 0)
			{
				damage = 0;
			}
			else
			{
				damage = damage / targ.resist_drown;
			}
		}
		if (dflags & DF_SPIRIT && targ.resist_spirit != 0)
		{
			if (targ.resist_spirit < 0)
			{
				damage = 0;
			}
			else
			{
				damage = damage / targ.resist_spirit;
			}
		}
		if (dflags & DF_VOODOO && targ.resist_voodoo != 0)
		{
			if (targ.resist_voodoo < 0)
			{
				damage = 0;
			}
			else
			{
				damage = damage / targ.resist_voodoo;
			}
		}
	}

	// Save fractions for later use.
	take = damage + targ.remain_dmg;
	damage = floor(take);
	targ.remain_dmg = take - damage;

	// Figure momentum add
	if (inflictor != world)
	{
		// Only knockback on these attack-types:
		if(dflags & (DF_PUMMEL | DF_BULLET | DF_EXPLODE | DF_STAB | DF_SPIRIT))
		{
			dir = (targ.absmin + targ.absmax) * 0.5 - (inflictor.absmin + inflictor.absmax) * 0.5;
			if (dflags & DF_RADIUS)
				dir = normalize(dir) * (damage * 8);    // Standard.
			else
				dir = normalize(dir) * (damage * 12);

			if (targ.classname == "player")
			{
				// for players:
				targ.velocity = targ.velocity + dir;
			}
			else if (targ.flags & FL_MONSTER)
			{
				// for monsters:
				targ.knockback = targ.knockback + dir * 5;
			}
		}
	}

	protected = FALSE;
	take = damage;
	save = 0;

	// Determine protection from armor (only applies to players):
	if (!(dflags & DF_NO_PROTECT) && targ.classname == "player")
	{
		// Save damage based on the target's armor level, but do not apply
		// the savings to the armor yet... in case target is invulnerable.
		if (dflags & DF_BURN)
			save = ArmorSave(targ, targ.armor_fire, damage);
		else if (dflags & DF_SPIRIT || dflags & DF_VOODOO)
			save = ArmorSave(targ, targ.armor_spirit, damage);
		else if (dflags & DF_BULLET || dflags & DF_STAB || dflags & DF_EXPLODE)
			save = ArmorSave(targ, targ.armor_body, damage);
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
				sound(targ, CHAN_ITEM, "bludbath/powerup.wav", 1, ATTN_NORM);
				self.invincible_sound = time + 2;
			}
			protected = TRUE;
		}
		// Team play avoidance.
		else if ((gametype == GT_TEAM_BLOODBATH || gametype == GT_CAPTURE_THE_FLAG) && ! friendlyfire &&
			targ != attacker && attacker.classname == "player" && inflictor.classname != "door")
		{
			if (targ.team == attacker.team)
				protected = TRUE;
		}
	}

	// If client, use damage values for hud effects.
	if (targ.flags & FL_CLIENT && targ != self)
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

	// FOR DAMAGE-TESTING:
	// ================================================
	if (cvar("show_damage"))
	{
		local string tempstring;
		local entity player;
		player = find(world,classname,"player");
		tempstring = ftos(take);
		sprint(player, "Damage to ");
		sprint(player, targ.classname);
		sprint(player, " = ");
		sprint(player, tempstring);
		sprint(player, " dflags = ");
		tempstring = ftos(dflags);
		sprint(player, tempstring);
		sprint(player, "\n");
	}
	// ================================================

	if (protected)
		return;     // Target is invulnerable to damage.

	// Now check for armor damage.
	if (save)
	{
		if (dflags & DF_BURN)
		{
			targ.armor_fire = targ.armor_fire - save;
			if (targ.armor_fire <= 0)
			{
				targ.armorvalue = targ.armor_fire = 0;
				targ.items = targ.items - (targ.items & IT_ARMOR_FIRE);
			}
			else
			{
				targ.armorvalue = targ.armor_fire;
				targ.items = targ.items - (targ.items & IT_ARMOR_ALL) + IT_ARMOR_FIRE;
			}
		}
		else if (dflags & DF_SPIRIT || dflags & DF_VOODOO)
		{
			targ.armor_spirit = targ.armor_spirit - save;
			if (targ.armor_spirit <= 0)
			{
				targ.armorvalue = targ.armor_spirit = 0;
				targ.items = targ.items - (targ.items & IT_ARMOR_SPIRIT);
			}
			else
			{
				targ.armorvalue = targ.armor_spirit;
				targ.items = targ.items - (targ.items & IT_ARMOR_ALL) + IT_ARMOR_SPIRIT;
			}
		}
		else if (dflags & DF_BULLET || dflags & DF_STAB || dflags & DF_EXPLODE)
		{
			targ.armor_body = targ.armor_body - save;
			if (targ.armor_body <= 0)
			{
				targ.armorvalue = targ.armor_body = 0;
				targ.items = targ.items - (targ.items & IT_ARMOR_BODY);
			}
			else
			{
				targ.armorvalue = targ.armor_body;
				targ.items = targ.items - (targ.items & IT_ARMOR_ALL) + IT_ARMOR_BODY;
			}
		}
	}

	// Any damage to glass will shatter it!
	if (targ.classname == "exploding_wall" && targ.skin > 4)
		take = 999;

	// Do the damage.
	targ.health = targ.health - take;

	if (targ.health >= -1                      && // If a player reaches between -1 and 1 HP (Brink Of Death)
		targ.health <= 1                       &&
		targ.classname == "player"             && // BOD can only be done player to player
		attacker.classname == "player"         &&
		targ.player_state != PS_BRINK_OF_DEATH && // If he wasn't already on the Brink Of Death
		targ != attacker                       && // and if he doesn't kill himself
		targ.burner == world)
	{
		Player_BrinkOfDeath(targ, attacker);
		return;
	}
	else if (targ.health <= 0)
	{
		// Target was slain!
		if (!targ.deadflag)
			targ.deathtype = dtype;

		// Set up obituaries for grenades, since owner has to be world for BBOX

		if (inflictor.classname == "grenade" && inflictor.enemy == targ)// Suicide via grenade
			attacker = targ;

		else if (inflictor.classname == "grenade")                      // Murder via grenade
			attacker = inflictor.enemy;

		Killed (targ, attacker);
		return;
	}        

	// React to the damage.
	oldself = self;
	self = targ;

	if (self.th_pain)
	{
		targ.deathtype = dtype;     // For player pain sounds.

		// Set value for monsters that support nopain.
		if (dflags & DF_MIN_PAIN)
			take = 0;

		self.th_pain(attacker, take);

		// nightmare mode monsters don't go into pain frames often
		if (skill == 3)
			self.pain_finished = time + 5;
	}
	self = oldself;
};

/*
============
T_RadiusDamage
============
*/
void(entity inflictor, entity attacker, float damage, float dflags, entity ignore, string dtype) T_RadiusDamage =
{
	dflags = dflags | DF_RADIUS;

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
				points = 0.5*vlen(inflictor.origin - org);
				if (points < 0)
					points = 0;
				points = damage - points;

				if (points > 0)
				{
					if (CanDamage(head, inflictor))
					{
						T_Damage(head, inflictor, attacker, points, dflags, dtype);
					}
				}
			}
		}
		head = head.chain;
	}
};
