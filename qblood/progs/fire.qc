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

// Fire acts like poison.  When a target is infected, it burns.
// The target loses one hit point for each frame it burns.
// The flames can be snuffed by diving under the surface of
// water or other liquid.

#include "common.qh"

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

void(entity victim, entity attacker, float dmgtype, float burn, float burntime) Ignite;

void() muzzleflash;

//------------------------------------------------------------------------//
//  This inflicts standard fire damage like in Blood.
//------------------------------------------------------------------------//
void(entity targ, entity inflictor, entity attacker, float dmgtype, float damage) FireDamage =
{
	T_Damage (targ, inflictor, attacker, damage, dmgtype | DF_MIN_PAIN, "fire");
};

//------------------------------------------------------------------------//
//  This damages a single entity and possibly sets it on fire.
//------------------------------------------------------------------------//
void(entity victim, entity fire, float damage, float dmgtype, float burn, float burntime) BurnDamage =
{
	// Set victim on fire first.
	if (burn > 0)
		Ignite (victim, fire.owner, dmgtype, burn, burntime);

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
void(entity fire, float radius, float damage, float burn, entity ignore) BurnRadius =
{
	local   float   fade;       // Distance multiplier.

	if (radius > 0)
	{
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
				BurnDamage (head, fire, damage * dist, DF_BURN, 10, burn * dist / 10);  // 10 points per sec
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
	particle (fire.origin, '0 0 100', 6, 50);
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
		if (ent.effects & EF_FLAME)
			ent.effects = ent.effects - (ent.effects | EF_FLAME);

		remove (ent.burner);
		ent.burner = world;
	}
};

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
	spot   = spot + self.enemy.origin + (self.enemy.mins + self.enemy.maxs) * 0.5;

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
	fire.effects    = EF_ADDITIVE | EF_LOWPRECISION;
	fire.reset      = SUB_Remove;

	// Animate the flame
	fire.alpha      = 0.9 - (0.4 * random ());
	fire.scale      = 0.4 + (0.6 * random ());
	fire.think      = FlameThink;
	fire.nextthink  = time + 0.1;
};

//------------------------------------------------------------------------//
//  This keeps the fire on an entity burning.
//------------------------------------------------------------------------//
void() Burn =
{
	// Check for removal.
	if (time > self.dmgtime)
	{
		if (self.enemy.effects & EF_FLAME)
			self.enemy.effects = self.enemy.effects - (self.enemy.effects | EF_FLAME);

		// Fuel is all gone.
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
		if (self.enemy.effects & EF_FLAME)
			self.enemy.effects = self.enemy.effects - (self.enemy.effects | EF_FLAME);

		// Victim is submerged under some liquid.
		setorigin (self, spot);     // So steam comes from enemy.

		// Put out the fire and make some steam.
		self.enemy.burner = world;
		MakeSteam (self);
		remove (self);
		return;
	}

	// Keep on burning.
	MakeEmbers ();

	FireDamage (self.enemy, self, self.owner, self.style, self.dmg);

	self.nextthink  = time + 0.1;
};

//------------------------------------------------------------------------//
//  This sets the victim on fire.
//------------------------------------------------------------------------//
void(entity victim, entity attacker, float dmgtype, float burn, float burntime) Ignite =
{
	// Check for fire immunity.
	if (!victim.takedamage)
	return;

	if (victim.classname == "door"              || // If it's a door, a plat or a wall, don't burn
		victim.classname == "plat"              ||
		victim.classname == "func_button"       ||
		victim.classname == "exploding_wall"    ||  // the other types of walls can't burn anyway
		victim.classname == "monster_hellhound" ||
		victim.classname == "monster_cerebrus"  ||
		victim.classname == "sentry"            ||
		victim.classname == "corpse"            ||
		victim.classname == "head")
		return;

	if (victim.flags & FL_MONSTER) 
		if (victim.health / victim.max_health > 0.33) // Not every entity should have max_health, so only check monsters
			return;

	// Check if the entity is linked to a burning flame.
	if (victim.burner)
	{
		local entity victim_burner;
		local float oldburn;

		victim_burner = victim.burner;

		// How much damage remains to be apply by the current burner?
		oldburn = victim_burner.dmg * 10 * (victim_burner.dmgtime - time);

		// The damage per 1/10th sec is set to the new value
		victim_burner.dmg = burn / 10;

		// We add some time to the new burn time to make sure the remaining points
		// will be apply nevertheless. Warning: the burner is always owned by
		// the last attacker; he always "steals the fire" from its former owner
		victim_burner.dmgtime = time + burntime + (oldburn / burn);
		victim_burner.owner   = attacker;
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
	fire.dmg        = burn / 10;        // points of damage per 1/10th sec
	fire.dmgtime    = time + burntime;
	fire.style      = dmgtype;			// damage-flag (DF_BURN or DF_SPIRIT)
	fire.nextthink  = 0.1;
	fire.think      = Burn;
	fire.reset      = SUB_Remove;

	if (!victim.effects & EF_FLAME)
		victim.effects = victim.effects | EF_FLAME;

	victim.burner   = fire;     // Link entity to fire.
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
