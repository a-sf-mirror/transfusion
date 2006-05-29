/*	Copyright (C) 1996-1997  Id Software, Inc.

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

void() W_SetCurrentAmmo;
void(float newWeapon) W_SwitchToWeapon;
void() FireAmbient;
void() ambient_water1;
void() Bomb_Explode;
void() wall_killed;

/* ALL LIGHTS SHOULD BE 0 1 0 IN COLOR ALL OTHER ITEMS SHOULD
BE .8 .3 .4 IN COLOR */

/*
============
RotateItem

Rotates an item
============
*/
void() RotateItem =
{
	local float t;
	t = time - self.ltime;
	self.ltime = time;
	self.angles = self.angles + ( self.rotate * t );
	self.angles = SUB_NormalizeAngles( self.angles );
	self.nextthink = time + 0.02;
};

void() SUB_regen =
{
	// Items only respawn in deathmatch/ctf/team deathmatch
	if (gametype == GT_COOPERATIVE || gametype == GT_SINGLE_PLAYER)
	{
		remove(self);
		return;
	}		 

	self.model = self.mdl;		// restore original model
	self.solid = SOLID_TRIGGER; // allow it to be touched again
	sound (self, CHAN_VOICE, "bludbath/reappear.wav", 1, ATTN_NORM);	// item respawn sound
	setorigin (self, self.origin);

	// Turn pretty glowing auras back on
	if (self.classname == "item_artifact_deathmask")
		self.effects = self.effects | EF_RED;
	else if (self.classname == "item_artifact_reflect")
		self.effects = self.effects | EF_BLUE;


	// Don't call it back later
	if (self.think == SUB_regen)
		self.nextthink = 0;
	self.reset = SUB_Null;

	// Add back the animation callback
	if (self.think1)
	{
		self.nextthink = time + 0.1;
		self.think = self.think1;
	}
	else 
	{
		// If there's no animation, check for rotation:
		if (self.rotate == ITEM_ROTATION)
		{
			self.nextthink = time + 0.02;
			self.think = RotateItem;
		}	
	}
};

void() Akimbo_Touch =
{
	local entity	stemp;
	local float 	best;
	local string	s;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	self.mdl = self.model;

	sound (other, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	self.solid = SOLID_NOT;
	self.model = string_null;

	// do the apropriate action
	other.akimbo_finished = self.nextthink;
	stemp = self;
	self = other;
	W_SetCurrentAmmo ();
	self = stemp;

	s=ftos(rint(other.akimbo_finished - time));

	bprint4 (other.netname, " picked up a guns akimbo with ", s, " seconds remaining!\n");

	activator = other;
	SUB_UseTargets();	// fire all targets / killtargets
};

void(float timeleft) Akimbo_Drop =
{
	local entity	item;

	item = spawn();
	item.origin = self.origin;

	item.velocity_z = 300;
	item.velocity_x = -100 + (random() * 200);
	item.velocity_y = -100 + (random() * 200);

	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	item.noise = "bludbath/powerup.wav";
	setmodel (item, "models/items/i_akimbo.md3");
	setsize (item, '-16 -16 -2', '16 16 54');
	item.touch = Akimbo_Touch;
	item.nextthink = time + timeleft;	 // remove it with the time left on it
	item.think = SUB_Remove;
	item.reset = SUB_Remove;
};

void() Invisibility_Touch =
{
	local float 	best;
	local string	s;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	// FIXME: need to set alpha for each v_weapon
	other.alpha = 0.2;
	self.mdl = self.model;

	sound (other, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	self.solid = SOLID_NOT;
	other.items = other.items | IT_INVISIBILITY;
	self.model = string_null;

	// do the apropriate action
	other.invisible_time = 1;
	other.invisible_finished = self.cnt;
	s=ftos(rint(other.invisible_finished - time));
	bprint4 (other.netname, " picked up a cloak with ", s, " seconds remaining!\n");


	activator = other;
	SUB_UseTargets();  // fire all targets / killtargets
};

void(float timeleft) Invisibility_Drop =
{
	local entity	item;

	item = spawn();
	item.origin = self.origin;

	item.velocity_z = 300;
	item.velocity_x = -100 + (random() * 200);
	item.velocity_y = -100 + (random() * 200);

	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	item.noise = "bludbath/powerup.wav";
	setmodel (item, "models/items/i_invisible.md3");
	setsize (item, '-3 -6 -2', '6 7 23');
	item.cnt = time + timeleft;
	item.touch = Invisibility_Touch;
	item.nextthink = time + timeleft;	 // remove after 30 seconds
	item.think = SUB_Remove;
	item.reset = SUB_Remove;
};

/*
============
PlaceItemOrObject

Plants the item / object on the floor
============
*/
void(float isAnObject) PlaceItemOrObject =
{
	// Make coordinates low precision to save net bandwidth
	self.effects = self.effects | EF_LOWPRECISION;
	self.velocity = '0 0 0';

	if (!isAnObject)
	{
		self.mdl = self.model;		// so it can be restored on respawn
		self.flags = FL_ITEM;		// make extra wide
		self.solid = SOLID_TRIGGER;
		self.movetype = MOVETYPE_TOSS;
	}

	if (self.movetype) //MOVETYPE_NONE does not fall
	{
		//we're going to drop it anyway, lets make sure its not stuck in the floor
		self.origin_z = self.origin_z + 8;
		if (!droptofloor())
		{
			if (isAnObject)
				dprint ("Object ");
			else
				dprint ("Bonus item ");
			dprint (self.classname);
			dprint (" fell out of level at ");
			dprint (vtos(self.origin));
			dprint ("\n");
			local entity	dummy;

			dummy = spawn();
			dummy.origin = self.origin;
			setmodel(dummy, "null");
			//remove(self);
			//return;
		}
	}

	if (isAnObject)
	{
		// If there's no spawn flag and no animation, make the object static
		// (changes or interactions are then impossible, but as a consequence
		// the object has virtually no cost from the server point of view)
		if (!self.spawnflags && !self.think1)
		{
			makestatic (self);
			return;
		}

		self.touch = SUB_SolidTouch;
	}

	// If the item/object has an animation loop
	if (self.think1)
	{
		self.nextthink = time + 0.1;
		self.think = self.think1;
	}
	else 
	{
		// If there's no animation, check for rotation:
		if (self.rotate == ITEM_ROTATION)
		{
			self.nextthink = time + 0.02;
			self.think = RotateItem;
		}	
	}
};

/*
============
PlaceItem

Plants the item on the floor
============
*/
void() PlaceItem =
{
	PlaceItemOrObject (FALSE);
};

/*
============
StartItem

Sets the clipping size and plants the items on the floor
============
*/
void() StartItem =
{

	/*if (cvar("nomonsters") || skillbit & self.spawnflags || 
	   (self.spawntype && !(gametype & self.spawntype)) || gametype > 3) //gametype above 3 is Bloodbath
    {
	    remove(self);
		return 1;
	}*/


	if (self.weapon)
	{
		if (self.spawntype && !(gametype & self.spawntype))
		{
			remove(self);
			return 1;
		}
	}

	self.nextthink = time + 0.3;	// items start after other solids
	self.think = PlaceItem;
};


/*
==========================================================

MISCELLANEOUS OBJECTS

==========================================================
*/

/*
====================
PlaceObject

Plants the object on the floor.
====================
*/
void() PlaceObject =
{
	PlaceItemOrObject (TRUE);
};

/*
============
StartObject

Sets the clipping size and plants the object on the floor
============
*/
void(string objmodel, vector bbox_min, vector bbox_max) StartObject =
{
	precache_model (objmodel);
	setmodel (self, objmodel);
	setsize (self, bbox_min, bbox_max);

	self.solid = SOLID_BBOX;
	self.movetype = MOVETYPE_PUSH;
	self.health = 1;
	self.takedamage = DAMAGE_AIM;
	self.dmg = 2;
	self.th_die = wall_killed;

	self.nextthink = time + 0.2;	// objects start after other solids, but before items
	self.think = PlaceObject;
};


// Boulder (tile804)
void() obj_world_boulder =
{
	StartObject ("models/world/boulder.md3", '-18.3 -13 0', '18.3 13 10.5');
	self.takedamage = DAMAGE_NO;
};

// Clump of Grass (tile0608)
void() obj_world_grass2 =
{
	StartObject ("models/world/grass2.md3", '-4.8 -6.3 -0.1', '4.8 6.3 16.4');
};

// Potted Plant (tile1009)
void() obj_world_plant1 =
{
	StartObject ("models/world/plant1.md3", '-17.1 -17.1 0', '17.1 17.1 30.6');
};

// Dead Tree (tile0540)
void() obj_world_tree =
{
	StartObject ("models/world/tree.md3", '-37.4 -56.6 0', '29.4 58 179.1');
};

// Live Tree (tile0541)
void() obj_world_tree2 =
{
	StartObject ("models/world/tree2.md3", '-32 -41 0', '52 45 174');
};




// Axe (tile1709)
void() obj_axe = 
{
    StartObject ("models/world/axe.md3", '-1.3 -5.6 -10.7', '1.3 2 16.8');
};

// Wooden Barrel (tile0907)
// NOTE: the model has 2 static frames (0- standing on end, 1- lying on side)
void() obj_barrel =
{
	StartObject ("models/world/barrel.md3", '-15 -15 0', '15 15 43.5');
};

// Dead innocent sitting
void() obj_body_sitting =
{
	StartObject ("models/world/innocent_sitting.md3", '-9.8 -12.8 0.2', '30.4 9.8 29.8');
};

// Dead innocent spread out
void() obj_body_spread =
{
	StartObject ("models/world/innocent_hanging.md3", '-2.6 -30.7 -4.3', '6.9 30.9 55.9');
};

// Dead body (tile2333)
void() obj_body1 =
{
	StartObject ("models/world/body1.md3", '-22.5 -10.1 -0.1', '26.4 27.6 21.9');
};

// Dead body in E1M1 (tile0895)
void() obj_body2 =
{
	StartObject ("models/world/body2.md3", '-0.3 -24.8 -26.7', '9.2 24.1 26.7');
};

// Bottle (tile0759)
void() obj_bottle2 =
{
	StartObject ("models/world/bottle2.md3", '-2.2 -2.5 -0.1', '2.2 2.5 15.9');
};

// Waste bucket (tile0505)
void() obj_bucket1 =
{
	StartObject ("models/world/bucket1.md3", '-5.8 -5.8 0', '5.8 6.1 24.5');
};

// Calipers (tile1715)
void() obj_calipers =
{
	StartObject ("models/world/calipers.md3", '0 -5.4 -9.3', '2.2 5.4 9.5');
};

// Short Candelabra (tile0584)
void() obj_candlbr1 =
{
	// Set animation loop
	self.anim_len = 4;
	self.think1 = SUB_AutoAnimation;

	StartObject ("models/world/candlbr1.md3", '-3.3 -10.4 0', '3.3 10.4 38.6');
};

// Tall Candelabra (tile0580)
void() obj_candlbr2 =
{
	// Set animation loop
	self.anim_len = 4;
	self.think1 = SUB_AutoAnimation;

	StartObject ("models/world/candlbr2.md3", '-4.9 -7.4 0', '4.8 7.4 53.8');
};

// Candle in Skull (tile0601)
void() obj_candleskull =
{
	StartObject ("models/world/candleskull.md3", '-7.6 -5.2 0', '7.6 5.2 14.6');
};

// Chair (tile0758)
void() obj_chair1 =
{
	StartObject ("models/world/chair.md3", '-9 -9.3 0', '9 9.3 42.6');
};

// Clippers (tile1708)
void() obj_clippers =
{
	StartObject ("models/world/clippers.md3", '-0.9 -4.7 -12.1', '0.9 4.7 12.1');
};

// Clock (tile1165)
void() obj_clock =
{
	StartObject ("models/world/clock.md3", '0 -18.1 -18.1', '3.2 18.1 18.1');
	self.movetype = MOVETYPE_NONE;
};

// Cup (tile0803)
void() obj_cup3 =
{
	StartObject ("models/world/cup3.md3", '-1.4 -1.6 0', '1.4 1.6 5.1');
};

// Draven Tombstone (tile1159)
void() obj_draven =
{
	// FIXME: Needs self.spawnflags = SF_USABLE; self.use = play sound
	StartObject ("models/world/draven.md3", '-5.8 -18.1 0', '5.9 18.1 46.8');
};

// Fire Extinguisher (tile0658)
void() obj_extngsh =
{
	StartObject ("models/world/extngsh.md3", '0 -12.2 0', '7.8 12.8 44.8');
	self.health = 1;
	self.takedamage = DAMAGE_AIM;
	self.dmg = DMG_TNT;
	self.th_die = Bomb_Explode;
	self.spawnflags = 1;
	self.movetype = MOVETYPE_NONE;
};

// Fence (tile0330)
void() obj_fence =
{
	StartObject ("models/world/fence.md3", '-2.6 -10.5 0', '2.6 10.5 84.2');
};

// Fence (tile1044)
void() obj_fence2 =
{
	StartObject ("models/world/fence2.md3", '-2.5 -39.9 -0.1', '2.5 39.9 80.2');
};

// Soccer Goal
void() obj_goal =
{
	StartObject ("models/world/goalposts.md3", '-40.1 -51.8 -0.4', '44 51.8 90');
	self.takedamage = DAMAGE_NO;
};

// Hanging Body (tile0906) NOTE: model needs changing
void() obj_hanging8 =
{
	StartObject ("models/world/hanging8.md3", '-5.6 -11.7 -20.5', '7.8 11.4 53');
};

// IV Drip (tile0962)
void() obj_ivdrip =
{
	StartObject ("models/world/ivdrip.md3", '-10.6 -10.6 0', '10.6 10.6 55.4');
};

// Glass Jar w/brain (tile0075)
void() obj_jar1 =
{
	StartObject ("models/world/jar1.md3", '-8.4 -8.4 0', '8.5 8.4 18.4');
};

// Stone Jar (tile0802)
void() obj_jar2 =
{
	StartObject ("models/world/jar2.md3", '-2.6 -3 0', '2.6 3 9');
};

// Garden Lantern (tile0640)
void() obj_lantern1 =
{
	StartObject ("models/world/lantern1.md3", '-6.8 -7.7 0', '6.8 7.7 62.9');
};

// Severed Leg (tile0682)
void() obj_leg1 =
{
	StartObject ("models/world/leg1.md3", '-8.1 -2.8 0', '8.6 4 7.4');
};

// Ceiling Light (tile0468)
void() obj_light1 =
{
	StartObject ("models/world/light1.md3", '-5.4 -5.6 -13.2', '5.4 5.6 13.2');
	self.movetype = MOVETYPE_NONE;
};

// Metal Barrel (tile0201)
void() obj_metbarrel =
{
	StartObject ("models/world/metbarrel.md3", '-13.6 -13.6 0', '13.6 13.6 36');
};

// Metal Body Barrel (tile0563)
void() obj_metbarrel2 =
{
	StartObject ("models/world/metbarrel2.md3", '-13.6 -13.6 0', '13.6 13.6 36');
};

// Poker (tile1716) (needs rescaling)
void() obj_poker =
{
	StartObject ("models/world/poker.md3", '-0.8 -0.8 7.6', '0.8 2.9 35.6');
	self.movetype = MOVETYPE_NONE;
};

// Large Vase (tile0537)
void() obj_pot1 =
{
	StartObject ("models/world/pot1.md3", '-9 -9 0', '9 9 38.5');
};

// Large Urn (tile1063)
void() obj_pot2 =
{
	StartObject ("models/world/pot2.md3", '-17.4 -17.7 0', '18 17.7 41.2');
};
// Stone Pot (tile0550)
void() obj_pot4 =
{
	StartObject ("models/world/pot4.md3", '-7.8 -7.8 0', '7.8 7.8 13');
};
// Small Pot (tile0604)
void() obj_pot5 =
{
	StartObject ("models/world/pot5.md3", '-7.1 -7 0', '6.9 7 15.3');
};

// Pram (tile0183)
void() obj_pram =
{
	StartObject ("models/world/pram.md3", '-17.1 -32.5 -0.3', '17.1 35.2 43');
};

// Rake (tile1711)
void() obj_rake =
{
	StartObject ("models/world/rake.md3", '0 -8.8 -29', '4.9 8.8 29');
};

// Saw (tile1714)
void() obj_saw =
{
	StartObject ("models/world/saw.md3", '-1.1 -4.9 -15.6', '1.1 5 15.6');
	self.movetype = MOVETYPE_NONE;
};

// Shovel (tile1713)
void() obj_shovel =
{
	StartObject ("models/world/shovel.md3", '-0.2 -6.6 -27.2', '3.4 6.6 26.2');
};

// Sink taps (tile0485)
void() obj_sinktaps =
{
	StartObject ("models/world/sinktaps.md3", '-1.9 -9.2 0', '10.8 9.2 7.6');
};

// Stake w/ 1 skull (tile0257)
void() obj_skllstk1 =
{
	StartObject ("models/world/skllstk1.md3", '-6.2 -4.5 -0.2', '4.5 4.6 51.7');
};

// Stake w/ 3 skulls (tile0258)
void() obj_skllstk2 =
{
	StartObject ("models/world/skllstk2.md3", '-6.4 -4.4 -0.2', '4.6 5.7 54.9');
};

// Impaled Skull (tile0685)
void() obj_skllstk3 =
{
	StartObject ("models/world/skllstk3.md3", '-5.7 -4.6 -0.2', '5.5 4.9 18.8');
};

// Skull (tile807)
void() obj_skull1 =
{
	StartObject ("models/world/skull1.md3", '-5.5 -4.5 -0.1', '5.5 4.5 8.1');
};

// Skull on stake w/rags (tile0607)
void() obj_skullrag =
{
	StartObject ("models/world/skullrag.md3", '-4.9 -19.5 0', '3.3 19.5 63.6');
};

// Spade (tile1712)
void() obj_spade =
{
	StartObject ("models/world/spade.md3", '-1.3 -4.9 -18.3', '1.3 4.9 18.3');
	self.movetype = MOVETYPE_NONE;
};

// Stone Statue (tile0679)
void() obj_statue4 =
{
	StartObject ("models/world/statue4.md3", '-15 -17.1 0', '15 17.1 111.8');
};

// Tombstone w/cross (tile0706)
void() obj_tombstn1 =
{
	StartObject ("models/world/tombstn1.md3", '-7.5 -22 -0.5', '7.5 22 71.9');
};

// Broken Tombstone (tile0705)
void() obj_tombstn2 =
{
	StartObject ("models/world/tombstn2.md3", '-7.5 -22 -0.5', '7.5 22 57.5');
};

// RIP Tombstone (tile0701)
void() obj_tombstn3 =
{
	StartObject ("models/world/tombstn3.md3", '-17.7 -6.1 0', '18.1 6 47.5');
};

// Old Tombstone (tile0704)
void() obj_tombstn4 =
{
	StartObject ("models/world/tombstn4.md3", '-10.2 -19.5 0', '10.2 19.5 44.9');
};

// Large Cross Tombstone (tile0678)
void() obj_tombstn5 =
{
	StartObject ("models/world/tombstn5.md3", '-10.4 -23.6 -0.3', '10.3 23.8 62.4');
};

// Wooden Cross Tombstone (tile0703)
void() obj_tombstn6 =
{
	StartObject ("models/world/tombstn6.md3", '-8.1 -16.3 0', '8.3 13.6 47');
};

// Wall torch (tile0570)
void() obj_torch =
{
	StartObject ("models/world/torch1.md3", '-6.4 -6.4 -16', '6.4 6.4 0');
	self.movetype = MOVETYPE_NONE;
};

// Wall torch (tile0506)
void() obj_torch2 =
{
	StartObject ("models/world/torch2.md3", '-6 -5 -29.3', '6 5 2.5');
	self.movetype = MOVETYPE_NONE;
};


// Wreath (tile0575)
void() obj_wreath1 =
{
	StartObject ("models/world/wreath1.md3", '-10.9 -16 0', '10.9 16 58.5');
};

// Big Wreath (tile0633)
void() obj_wreath2 =
{
	StartObject ("models/world/wreath2.md3", '0.1 -49.4 -41.7', '11.1 50.2 47.1');
	self.movetype = MOVETYPE_NONE;
};

/*
===================================

INVENTORY ITEMS

===================================
*/
void() powerup_touch =
{
	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;
		
	self.effects = 0;

	// do the appropriate action (listed in alphabetical order)
	if (self.classname == "item_artifact_bag")
	{
		if (InvenMax (other, INV_FIRST_AID))
			return;
		InvenSet (other, INV_FIRST_AID, 100);
	}
	else if (self.classname == "item_artifact_boots")
	{
		if (InvenMax (other, INV_JUMP_BOOTS))
			return;
		InvenSet (other, INV_JUMP_BOOTS, 100);
	}
	else if (self.classname == "item_artifact_crystal")
	{
		if (InvenMax (other, INV_CRYSTAL_BALL))
			return;
		InvenSet (other, INV_CRYSTAL_BALL, 100);
	}
	else if (self.classname == "item_artifact_divingsuit")
	{
		if (InvenMax (other, INV_DIVING_SUIT))
			return;
		InvenSet (other, INV_DIVING_SUIT, 100);
	}
	else if (self.classname == "item_artifact_invisibility")
	{
		other.invisible_time = 1;
		other.invisible_finished = time + 30;
	}
	else if (self.classname == "item_artifact_deathmask")
	{
		other.invincible_time = 1;
		other.invincible_finished = time + 30;
	}
	else if (self.classname == "item_artifact_reflect")
	{
		other.reflect_finished = time + 30;
	}
	else if (self.classname == "item_artifact_akimbo")
	{
		local entity stemp;

		other.akimbo_finished = time + 30;

		stemp = self;
		self = other;
		W_SetCurrentAmmo ();
		self = stemp;
	}
	else if (self.classname == "item_artifact_vision")
	{
		if (InvenMax (other, INV_BEAST_VISION))
			return;
		InvenSet (other, INV_BEAST_VISION, 100);
	}

	sprint3 (other, "Picked up ", self.netname, "\n");

	self.mdl = self.model;
	if ((self.classname == "item_artifact_deathmask") ||
		(self.classname == "item_artifact_invisibility"))
		self.nextthink = time + 60*5;
	else
		self.nextthink = time + 60;
	self.think = SUB_regen;
	self.reset = SUB_regen;

	sound (other, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	self.solid = SOLID_NOT;
	other.items = other.items | self.items;
	self.model = string_null;

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};

void() item_powerup =
{
	if (self.noise == string_null)
		self.noise = "items/pickup.wav";

	self.touch = powerup_touch;

	precache_model (self.model);
	precache_sound (self.noise);
	setmodel (self, self.model);

	StartItem ();
};


/*
=========================================================================

HEALTH BOX

=========================================================================
*/
//
// T_Heal: add health to an entity, limiting health to max_health
// "ignore" will ignore max_health limit
//
float (entity e, float healpoints, float ignore) T_Heal =
{
	if (e.health <= 0)
		return FALSE;
	if ((!ignore) && (e.health >= other.max_health))
		return FALSE;

	e.health = e.health + ceil(healpoints);
	if ((!ignore) && (e.health >= other.max_health))
		e.health = other.max_health;

	// In Blood, life seed and cheats maxed out health at 200
	if (e.health > 200)
		e.health = 200;
	return TRUE;
};

/*QUAKED item_health (.3 .3 1) (-16 -16 0) (16 16 56) rotten megahealth
Health box. Normally gives 50 points.
Rotten box heals 20 points,
megahealth will add 100 health.
*/
void() health_touch =
{
	local	float amount;
	local	string	s;

	if (other.classname != "player")
		return;

	if (self.healtype == 2) // Megahealth?	Ignore max_health...
	{
		if (other.health >= 200)
			return;
		if (!T_Heal(other, self.healamount, 1))
			return;
	}
	else
	{
		if (!T_Heal(other, self.healamount, 0))
			return;
	}

	s = ftos(self.healamount);
	sprint3 (other, "Picked up ", self.netname, " \n");

	// health touch sound
	sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);

	stuffcmd (other, "bf\n");
	
	self.model = string_null;
	self.solid = SOLID_NOT;

	self.nextthink = time + 20;
	self.think = SUB_regen;
	self.reset = SUB_regen;

	activator = other;
	SUB_UseTargets();		// fire all targets / killtargets
};

void() item_health =
{
	self.touch = health_touch;

	if (self.spawnflags & H_LIFE_ESSENCE)
	{
		self.model = "models/items/i_essence.md3";
		self.healamount = 20;
		self.netname = "Life Essence";
		self.healtype = 1;

		// Set animation loop
		self.anim_len = 8;	// 8 frames in the animation
		self.think1 = SUB_AutoAnimation;

		// If flashy effects are allowed, make it glow
		if (cvar ("g_flashyEffects"))
		{
			// Only available if the engine supports the DP_ENT_GLOW extension
			if (checkextension ("DP_ENT_GLOW"))
			{
				self.glow_color = 250;	// 250 = red in Quake palette
				self.glow_size = 50;
			}
		}
	}
	else if (self.spawnflags & H_LIFE_SEED)
	{
		self.model = "models/items/i_seed.md3";
		self.healamount = 100;
		self.netname = "Life Seed";
		self.healtype = 2;

		// Set animation loop
		self.anim_len = 42;  // 42 frames in the animation
		self.think1 = SUB_AutoAnimation;
	}
	else
	{
		self.model = "models/items/i_pouch.md3";
		self.healamount = 50;
		self.netname = "Medicine Patch";
		self.healtype = 1;
	}

	// already precached, and you can't precache in the middle of a game
	if (self.classname != "drop_item")
		precache_model (self.model);
		
	setmodel(self, self.model);
	setsize (self, '-16 -16 0', '16 16 56');

	self.noise = "items/pickheal.wav";
	
	// already precached, and you can't precache in the middle of a game
	if (self.classname != "drop_item")
		precache_sound (self.noise);

	StartItem ();
};


/*
===============================================================================

ARMOR

===============================================================================
*/

void() armor_touch =
{
	local	float	type, value, bit;

	if (other.health <= 0)
		return;
	if (other.classname != "player")
		return;

	if (self.classname == "item_armor_body")
	{
		// Body armor
		if (other.armor_body >= 100)
			return;
		value = other.armor_body = 100;
		bit = IT_ARMOR_BODY;
	}
	else if (self.classname == "item_armor_fire")
	{
		// Fire armor
		if (other.armor_fire >= 100)
			return;
		value = other.armor_fire = 100;
		bit = IT_ARMOR_FIRE;
	}
	else if (self.classname == "item_armor_super")
	{
		// Super armor (200 of all three armors).
		if (other.armor_body >= 200)
			if (other.armor_fire >= 200)
				if (other.armor_spirit >= 200)
					return;

		other.armor_body = other.armor_fire = other.armor_spirit = 200;

		bit = other.items & IT_ARMOR_ALL;
		if (bit == IT_ARMOR_BODY)
			value = other.armor_body;
		else if (bit == IT_ARMOR_FIRE)
			value = other.armor_fire;
		else
		{
			bit = IT_ARMOR_SPIRIT;
			value = other.armor_spirit;
		}
	}
	else if (self.classname == "item_armor_basic")
	{
		// Basic armor
		if (other.armor_body >= 100)
			if (other.armor_fire >= 100)
				if (other.armor_spirit >= 100)
					return;

		other.armor_body = other.armor_body + 50;
		if (other.armor_body > 100)
			other.armor_body = 100;
		other.armor_fire = other.armor_fire + 50;
		if (other.armor_fire > 100)
			other.armor_fire = 100;
		other.armor_spirit = other.armor_spirit + 50;
		if (other.armor_spirit > 100)
			other.armor_spirit = 100;

		bit = other.items & IT_ARMOR_ALL;
		if (bit == IT_ARMOR_SPIRIT)
			value = other.armor_spirit;
		else if (bit == IT_ARMOR_FIRE)
			value = other.armor_fire;
		else
		{
			bit = IT_ARMOR_BODY;
			value = other.armor_body;
		}
	}
	else if (self.classname == "item_armor_spirit")
	{
		// Spirit armor
		if (other.armor_spirit >= 100)
			return;
		value = other.armor_spirit = 100;
		bit = IT_ARMOR_SPIRIT;
	}
	else
		sprint(other, "Tried to pickup illegal armor.\n");

	other.armorvalue = value;
	if (bit)
		other.items = other.items - (other.items & IT_ARMOR_ALL) + bit;

	self.solid = SOLID_NOT;
	self.model = string_null;
	self.nextthink = time + 20;
	self.think = SUB_regen;
	self.reset = SUB_regen;

	sprint3 (other, "Picked up ", self.netname, "\n");
	sound (other, CHAN_ITEM, "items/pickarmr.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};

// Intialize common armor attributes
void() InitArmor = 
{
	self.touch = armor_touch;
	self.rotate = ITEM_ROTATION;
};

// Basic Armor
void() item_armor_basic =
{
	self.model = "models/items/armor/i_arm_basic.md3";
	self.netname = "Basic Armor";
	precache_model (self.model);
	setmodel (self, self.model);
	setsize (self, '-7 -18 0', '10 18 38');
	InitArmor();
	StartItem ();
};

// Spirit Armor
void() item_armor_spirit =
{
	self.model = "models/items/armor/i_arm_spirit.md3";
	self.netname = "Spirit Armor";
	precache_model (self.model);
	setmodel (self, self.model);
	setsize (self, '-2 -17 0', '4 19 37');
	InitArmor();
	StartItem ();
};

// Body Armor
void() item_armor_body =
{
	self.model = "models/items/armor/i_arm_body.md3";
	self.netname = "Body Armor";
	precache_model (self.model);
	setmodel (self, self.model);
	setsize (self, '-1 -18 0', '6 19 45');
	InitArmor();
	StartItem ();
};

// Fire Armor
void() item_armor_fire =
{
	self.model = "models/items/armor/i_arm_fire.md3";
	self.netname = "Fire Armor";
	precache_model (self.model);
	setmodel (self, self.model);
	setsize (self, '-7 -12 0', '7 10 37');
	InitArmor();
	StartItem ();
};

// Super Armor
void() item_armor_super =
{
	self.model = "models/items/armor/i_arm_super.md3";
	self.netname = "Super Armor";
	precache_model (self.model);
	setmodel (self, self.model);
	setsize (self, '-16 -16 0', '16 16 56');
	InitArmor();
	StartItem ();
};


/*
===============================================================================

WEAPONS

===============================================================================
*/

void() PsychoCaleb_Precache =
{
	// Player quips (when playing with explosives)
	// Only used by flaregun, napalm laucher, and any grenade type
	precache_sound ("player/play1109.wav");
	precache_sound ("player/play1110.wav");
	precache_sound ("player/play1111.wav");
	precache_sound ("player/play1112.wav");
	precache_sound ("player/play1113.wav");
	precache_sound ("player/play1114.wav");
	precache_sound ("player/play1115.wav");
	precache_sound ("player/play1116.wav");
	precache_sound ("player/quips/1039.wav");	// SOB must pay !
	precache_sound ("player/quips/1050.wav");	// That's all folks !
	precache_sound ("player/quips/1057.wav");	// Rest in pieces
};


void() bound_other_ammo =
{
	if (other.ammo_shells > MAX_SHELLS)
		other.ammo_shells = MAX_SHELLS;
	if (other.ammo_nails > MAX_NAILS)
		other.ammo_nails = MAX_NAILS;
	if (other.ammo_rockets > MAX_ROCKETS)
		other.ammo_rockets = MAX_ROCKETS;
	if (other.ammo_cells > MAX_CELLS)
		other.ammo_cells = MAX_CELLS;

	// Custom ammo.
	if (other.ammo_flare > MAX_FLARES)
		other.ammo_flare = MAX_FLARES;
	if (other.ammo_tnt_bundle > MAX_TNT)
		other.ammo_tnt_bundle = MAX_TNT;
	if (other.ammo_tnt_proxy > MAX_PROXY)
		other.ammo_tnt_proxy = MAX_PROXY;
	if (other.ammo_tnt_remote > MAX_REMOTE)
		other.ammo_tnt_remote = MAX_REMOTE;
	if (other.ammo_spray > MAX_SPRAY)
		other.ammo_spray = MAX_SPRAY;
	if (other.ammo_voodoo > MAX_VOODOO)
		other.ammo_voodoo = MAX_VOODOO;
	if (other.ammo_leech > MAX_LEECH)
		other.ammo_leech = MAX_LEECH;
};


float() W_BestWeapon;

/*
=============
weapon_touch
=============
*/
void() weapon_touch =
{
	local	float	new;
	local	float	leave;
	local	entity	temp;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	if (cvar ("g_weaponStay"))
		leave = 1;
	else
		leave = 0;

	// tell us how much ammo each weapon has upon picking it up

	if (self.classname == "weapon_flaregun")
	{
		if (leave && (other.items & IT_FLAREGUN) )
			return;
		new = IT_FLAREGUN;
		other.ammo_flare = other.ammo_flare + 9;
	}
	else if (self.classname == "weapon_tommygun")
	{
		if (leave && (other.items & IT_TOMMYGUN) )
			return;
		new = IT_TOMMYGUN;
		other.ammo_nails = other.ammo_nails + 50;
	}
	else if (self.classname == "weapon_spraycan")
	{
		if (leave && (other.items & IT_SPRAY_CAN) )
			return;
		new = IT_SPRAY_CAN;
		other.ammo_spray = other.ammo_spray + 48;
	}
	else if (self.classname == "weapon_sawedoff")
	{
		if (leave && (other.items & IT_SAWED_OFF) )
			return;
		new = IT_SAWED_OFF;
		other.ammo_shells = other.ammo_shells + 8;
	}
	else if (self.classname == "weapon_napalmlauncher")
	{
		if (leave && (other.items & IT_NAPALM_LAUNCHER) )
			return;
		new = IT_NAPALM_LAUNCHER;
		other.ammo_rockets = other.ammo_rockets + 6;
	}
	else if (self.classname == "weapon_tnt")
	{
		if (leave && (other.items & IT_TNT))
			return;
		new = IT_TNT;

		// Is it a full case of TNT?
		if (self.spawnflags)
			other.ammo_tnt_bundle = other.ammo_tnt_bundle + 5;
		else
			other.ammo_tnt_bundle = other.ammo_tnt_bundle + 1;
	}
	else if (self.classname == "weapon_proximity")
	{
		new = IT_PROXIMITY_BOMB;
		other.ammo_tnt_proxy = other.ammo_tnt_proxy + 1;
		leave = 0;
	}
	else if (self.classname == "weapon_remote")
	{
		new = IT_REMOTE_DETONATOR;
		other.ammo_tnt_remote = other.ammo_tnt_remote + 1;
		leave = 0;
	}
	else if (self.classname == "weapon_teslacannon")
	{
		if (leave && (other.items & IT_TESLA_CANNON) )
			return;
		new = IT_TESLA_CANNON;
		other.ammo_cells = other.ammo_cells + 64;
	}
	else if (self.classname == "weapon_voodoodoll")
	{
		if (leave && (other.items & IT_VOODOO_DOLL) )
			return;
		new = IT_VOODOO_DOLL;
		other.ammo_voodoo = other.ammo_voodoo + 100;
	}

	else if (self.classname == "weapon_lifeleech")
	{
		// If we own a Life Leech in sentry mode
		if (other.leech_sentry)
			return;

		if (leave && (other.items & IT_LIFE_LEECH) )
			return;
		new = IT_LIFE_LEECH;
		other.ammo_leech = other.ammo_leech + 35;
	}

	else
		objerror ("weapon_touch: unknown classname");

	bound_other_ammo ();

	sprint3 (other, "Picked up ", self.netname, "\n");

	// weapon touch sound
	sound (other, CHAN_ITEM, "items/weaponup.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

	// add the weapon to the player's equipment
	other.items = other.items | new;

	temp = self;
	self = other;
	W_SetCurrentAmmo ();

	// If the player has a fork, switch to the new weapon
	if (self.weapon == IT_PITCHFORK && self.player_state != PS_HOLSTER)
	{
		 if (self.player_state == PS_IDLE)
			W_SwitchToWeapon (new);
		 else
			self.newweapon = new;
	}

	self = temp;

	if (leave)
		return;

	// remove it in single player, or setup for respawning in deathmatch
	self.model = string_null;
	self.solid = SOLID_NOT;
	self.nextthink = time + 30;
	self.think = SUB_regen;
	self.reset = SUB_regen;

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};

// Intialize common weapon attributes
void() InitWeapon = 
{
	self.touch = weapon_touch;
	// Exception for rotation: If it's not a TNT bundle but a TNT-box, don't rotate:
	if (self.classname != "weapon_tnt" || !self.spawnflags)
	{
		self.rotate = ITEM_ROTATION;
	}
};

// Flaregun
void() weapon_flaregun =
{
	precache_model ("models/weapons/v_flare.psk");
	precache_model ("models/weapons/g_flare.md3");
	precache_model ("models/weapons/ga_flare.md3");  // akimbo model

	setmodel (self, "models/weapons/g_flare.md3");
	self.weapon = IT_FLAREGUN;
	self.netname = "Flare Gun";
	setsize (self, '-16 -16 0', '16 16 56');

	// precache the necessary sounds
	PsychoCaleb_Precache ();
	precache_model ("models/weapons/objects/flare.md3");
	precache_sound ("weapons/flaregun/flaref.wav");
	precache_sound ("weapons/napalm/explodfs.wav");  // For alt-flares

	available_weapons = available_weapons | IT_FLAREGUN;
	
	InitWeapon();
	StartItem ();
};

void() precache_sawedoff =
{
	precache_model ("models/weapons/v_shot.psk");
	precache_model ("models/weapons/ga_shot.md3");				// akimbo model
	precache_model ("models/weapons/g_shot.md3");
	precache_model ("models/weapons/objects/shotshell.md3");	// shotgun shell
		
	// Precache the necessary sounds
	precache_sound ("weapons/shotgun/shotcock.wav");  // shell ejection
	precache_sound ("weapons/shotgun/shotfir2.wav");  // shotgun alt-fire
	precache_sound ("weapons/shotgun/shotfire.wav");  // shotgun fired
	precache_sound ("weapons/shotgun/shotload.wav");  // reload sound
	precache_sound ("weapons/shtshl2.wav");  // shell hitting ground
};

// Sawed-off
void() weapon_sawedoff =
{
	// already precached, and you can't precache in the middle of a game
	if (self.classname != "drop_item")
		precache_sawedoff();
	else
		self.classname = "weapon_sawedoff"; // For monster weapon drop

	setmodel (self, "models/weapons/g_shot.md3");
	self.weapon = IT_SAWED_OFF;
	self.netname = "Sawed-off";
	
	setsize (self, '-16 -16 0', '16 16 56');

	
	available_weapons = available_weapons | IT_SAWED_OFF;

	InitWeapon();
	StartItem ();
};

void() precache_tommygun =
{
	precache_model ("models/weapons/v_tommy.md3");
	precache_model ("models/weapons/ga_tommy.md3"); 			// akimbo model
	precache_model ("models/weapons/g_tommy.md3");
	precache_model ("models/weapons/objects/bulletshell.md3");	// tommy gun shell
		
	// Precache the necessary sounds
	precache_sound ("weapons/tommygun/_tom.wav");	  // Fire
	precache_sound ("weapons/tommygun/tomcock.wav");  // Out of bullet noise
	precache_sound ("weapons/shtshl.wav");			  // shell hitting ground
	precache_sound ("weapons/shtshl3.wav"); 		  // shell hitting ground (2nd)
};


// Tommy Gun
void() weapon_tommygun =
{
	// already precached, and you can't precache in the middle of a game
	if (self.classname != "drop_item")
		precache_tommygun();
	else
		self.classname = "weapon_tommygun";

	setmodel (self, "models/weapons/g_tommy.md3");
	self.weapon = IT_TOMMYGUN;
	self.netname = "Tommy Gun";
	setsize (self, '-16 -16 0', '16 16 56');		

	available_weapons = available_weapons | IT_TOMMYGUN;

	InitWeapon();
	StartItem ();
};

// Spray Can
void() weapon_spraycan =
{
	precache_model ("models/weapons/v_aerosol.md3");
	precache_model ("models/ammo/g_aerosol.md3");
	precache_model ("models/weapons/grenades/gr_aerosol.md3");

	setmodel (self, "models/ammo/g_aerosol.md3");
	self.weapon = IT_SPRAY_CAN;
	self.netname = "Spray Can";
	setsize (self, '-8 -8 0', '8 8 32');

	// Precache the necessary sounds
	precache_sound ("weapons/spraycan/spraycan.wav");  // lighted spray can
	precache_sound ("weapons/spraycan/sprayfir.wav");  // fire
	precache_sound ("weapons/tnt/lighter.wav"); 	   // = zipopen.wav + ziplight.wav
	precache_sound ("weapons/tnt/zipclose.wav");
	precache_sound ("weapons/napalm/explodcl.wav");    // alt-fire detonation

	precache_model ("progs/sprayfir.spr");

	available_weapons = available_weapons | IT_SPRAY_CAN;

	InitWeapon();
	StartItem ();
};

void() precache_tnt =
{
	precache_model ("models/weapons/v_tnt.md3");
	precache_model ("models/weapons/grenades/gr_tnt.md3");	
	precache_model (self.model);
	
	// Precache the necessary sounds
	PsychoCaleb_Precache ();
	precache_sound ("weapons/tnt/lighter.wav"); 	 // = zipopen.wav + ziplight.wav
	precache_sound ("weapons/tnt/tntfuse.wav"); 	 // tnt lit
	precache_sound ("weapons/tnt/tnttoss.wav"); 	 // throw sound
	precache_sound ("weapons/tnt/zipclose.wav");
	precache_sound ("weapons/napalm/explodcl.wav");  // detonation

};

// TNT (bundle or case)
void() weapon_tnt =
{
	local vector minSize, maxSize;

	// If we want a case of TNT instead of a bundle
	if (self.spawnflags)
	{
		self.model = "models/weapons/g_tnt.md3";
		self.netname = "Case of TNT";
		minSize = '-16 -16 0';
		maxSize = '16 16 56';
	}
	else
	{
		self.model = "models/ammo/a_tnt.md3";
		self.netname = "Bundle of TNT";
		minSize = '-8 -8 0';
		maxSize = '8 8 32';
	}

	// already precached, and you can't precache in the middle of a game
	if (self.classname != "drop_item")
		precache_tnt();
	else
		self.classname = "weapon_tnt";

	
	setmodel (self, self.model);
	setsize (self, minSize, maxSize);

	self.weapon = IT_TNT;

	available_weapons = available_weapons | IT_TNT;

	InitWeapon();
	StartItem ();
};


// Proximity bombs
void() weapon_proximity =
{
	precache_model ("models/weapons/v_proxy.md3");
	precache_model ("models/weapons/g_proxy.md3");
	precache_model ("models/weapons/grenades/gr_proxy.md3");

	setmodel (self, "models/weapons/g_proxy.md3");
	self.weapon = IT_PROXIMITY_BOMB;
	self.netname = "Proximity Bomb";
	setsize (self, '-8 -8 0', '8 8 32');

	// Precache the necessary sounds
	PsychoCaleb_Precache ();
	precache_sound ("weapons/tnt/proxarm.wav"); 	 // proximity bomb armed
	precache_sound ("weapons/tnt/proxdet.wav"); 	 // proximity bomb triggered
	precache_sound ("weapons/tnt/tnttoss.wav"); 	 // throw sound
	precache_sound ("weapons/napalm/explodcl.wav");  // detonation

	available_weapons = available_weapons | IT_PROXIMITY_BOMB;

	InitWeapon();
	StartItem ();
};

// Remote detonators
void() weapon_remote =
{
	precache_model ("models/weapons/v_remote.md3");
	precache_model ("models/weapons/grenades/gr_remote.md3");
	precache_model ("models/weapons/g_remote.md3");

	setmodel (self, "models/weapons/g_remote.md3");
	self.weapon = IT_REMOTE_DETONATOR;
	self.netname = "Remote Detonator";
	setsize (self, '-8 -8 0', '8 8 32');

	// Precache the necessary sounds
	PsychoCaleb_Precache ();
	precache_sound ("weapons/tnt/remdet.wav");		 // bomb triggered
	precache_sound ("weapons/tnt/remfire.wav"); 	 // remote triggered
	precache_sound ("weapons/tnt/tnttoss.wav"); 	 // throw sound
	precache_sound ("weapons/napalm/explodcl.wav");  // detonation / impact
	available_weapons = available_weapons | IT_REMOTE_DETONATOR;

	InitWeapon();
	StartItem ();
};

// Napalm Launcher
void() weapon_napalmlauncher =
{
	precache_model ("models/weapons/v_napalm.md3");
	precache_model ("models/weapons/ga_napalm.md3");
	precache_model ("models/weapons/g_napalm.md3");

	setmodel (self, "models/weapons/g_napalm.md3");
	self.weapon = IT_NAPALM_LAUNCHER;
	self.netname = "Napalm Launcher";
	setsize (self, '-16 -16 0', '16 16 56');

	precache_model ("models/weapons/objects/napalm.md3");  // napalm regular fire
	precache_model ("models/weapons/objects/naltball.md3"); // napalm alt fire model

	// Precache the necessary sounds
	PsychoCaleb_Precache ();
	precache_sound ("weapons/napalm/blaster.wav");	 // Shot
	precache_sound ("weapons/napalm/explodcl.wav");  // Impact

	available_weapons = available_weapons | IT_NAPALM_LAUNCHER;

	InitWeapon();
	StartItem ();
};

void() precache_teslacannon =
{
	precache_model ("models/weapons/v_tesla.psk");
	precache_model ("models/weapons/ga_tesla.psk");  // Akimbo model
	precache_model ("models/weapons/g_tesla.md3");
	precache_model ("progs/teslaball.spr");
	precache_model ("models/weapons/objects/alttesla.md3");
		
	// Precache the necessary sounds
	precache_sound ("weapons/tesla/tessngfr.wav");	// normal fire
	precache_sound ("weapons/tesla/tessnght.wav");	// normal hit
	precache_sound ("weapons/tesla/tesaltht.wav");	// altfire hit
	precache_sound ("weapons/tesla/tessuper.wav");	// alt fire charge up + fire
	precache_sound ("weapons/tesla/tesakima.wav");	// alt fire charge up + fire (Akimbo)

};

// Tesla Cannon
void() weapon_teslacannon =
{
	// already precached, and you can't precache in the middle of a game
	if (self.classname != "drop_item")
		precache_teslacannon();
	else
		self.classname = "weapon_teslacannon";
	
	setmodel (self, "models/weapons/g_tesla.md3");
	self.weapon = IT_TESLA_CANNON;
	self.netname = "Tesla Cannon";
	setsize (self, '-16 -16 0', '16 16 56');	

	available_weapons = available_weapons | IT_TESLA_CANNON;

	InitWeapon();
	StartItem ();
};

// Voodoo Doll
void() weapon_voodoodoll =
{
	precache_model ("models/weapons/v_voodoo.md3");
	precache_model ("models/weapons/g_voodoo.md3");

	setmodel (self, "models/weapons/g_voodoo.md3");
	self.weapon = IT_VOODOO_DOLL;
	self.netname = "Voodoo Doll";
	setsize (self, '-16 -16 0', '16 16 56');

	// Precache the necessary sounds
	precache_sound ("weapons/voodoodl/voolaugh.wav");
	precache_sound ("weapons/voodoodl/voostab.wav");
	precache_sound ("weapons/voodoodl/voochant.wav");

	available_weapons = available_weapons | IT_VOODOO_DOLL;

	InitWeapon();
	StartItem ();
};

// Life Leech
void() weapon_lifeleech =
{
	precache_model ("models/weapons/v_leech.md3");
	precache_model ("models/weapons/g_leech.md3");
	precache_model ("progs/leechball.spr");

	setmodel (self, "models/weapons/g_leech.md3");
	self.weapon = IT_LIFE_LEECH;
	self.netname = "Life Leech";
	setsize (self, '-16 -16 0', '16 16 56');

	// precache the necessary sounds
	precache_sound ("weapons/lifelech/laltfr1.wav");
	precache_sound ("weapons/lifelech/llaltht.wav");	// LL sentry destroyed
	precache_sound ("weapons/napalm/explodfs.wav"); 	// altfire missile touch

	available_weapons = available_weapons | IT_LIFE_LEECH;

	InitWeapon();
	StartItem ();
};


/*
===============================================================================

AMMO

===============================================================================
*/

void() ammo_touch =
{
	local entity temp;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	// shotgun
	if (self.weapon == 1)
	{
		if (other.ammo_shells >= MAX_SHELLS)
			return;
		other.ammo_shells = other.ammo_shells + self.aflag;
	}
	// spikes
	else if (self.weapon == 2)
	{
		if (other.ammo_nails >= MAX_NAILS)
			return;
		other.ammo_nails = other.ammo_nails + self.aflag;
	}
	// rockets
	else if (self.weapon == 3)
	{
		if (other.ammo_rockets >= MAX_ROCKETS)
			return;
		other.ammo_rockets = other.ammo_rockets + self.aflag;
	}
	// cells
	else if (self.weapon == 4)
	{
		if (other.ammo_cells >= MAX_CELLS)
			return;
		other.ammo_cells = other.ammo_cells + self.aflag;
	}

	// Custom ammo below...
	// flares
	else if (self.weapon == 5)
	{
		if (other.ammo_flare >= MAX_FLARES)
			return;
		other.ammo_flare = other.ammo_flare + self.aflag;
	}
	// tnt bundle
	else if (self.weapon == 6)
	{
		if (other.ammo_tnt_bundle >= MAX_TNT)
			return;
		other.ammo_tnt_bundle = other.ammo_tnt_bundle + self.aflag;
	}
	// tnt proxy
	else if (self.weapon == 7)
	{
		if (other.ammo_tnt_proxy >= MAX_PROXY)
			return;
		other.ammo_tnt_proxy = other.ammo_tnt_proxy + self.aflag;
	}
	// tnt remote
	else if (self.weapon == 8)
	{
		if (other.ammo_tnt_remote >= MAX_REMOTE)
			return;
		other.ammo_tnt_remote = other.ammo_tnt_remote + self.aflag;
	}
	// spray can
	else if (self.weapon == 9)
	{
		if (other.ammo_spray >= MAX_SPRAY)
			return;
		other.ammo_spray = other.ammo_spray + self.aflag;
	}
	// voodoo doll
	else if (self.weapon == 10)
	{
		if (other.ammo_voodoo >= MAX_VOODOO)
			return;
		other.ammo_voodoo = other.ammo_voodoo + self.aflag;
	}
	// life leech
	else if (self.weapon == 11)
	{
		if (other.ammo_leech >= MAX_LEECH)
			return;
		other.ammo_leech = other.ammo_leech + self.aflag;
	}

	bound_other_ammo ();

	sprint3 (other, "Picked up ", self.netname, "\n");

	// ammo touch sound
	sound (other, CHAN_ITEM, "items/ammo.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

	temp = self;
	self = other;
	W_SetCurrentAmmo ();
	self = temp;

	// setup for respawning
	self.model = string_null;
	self.solid = SOLID_NOT;
	self.nextthink = time + 30;

	self.think = SUB_regen;
	self.reset = SUB_regen;

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};


// Flares
void() ammo_flares =
{
	self.touch = ammo_touch;

	self.model = "models/ammo/a_flares.md3";
	precache_model (self.model);
	setmodel (self, self.model);

	self.netname = "box of flares";
	self.aflag = 8;
	self.weapon = 5;

	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

// Shells
void() ammo_shell =
{
	self.touch = ammo_touch;

	if (self.spawnflags & AMMO_BIG)
	{
		self.model = "models/ammo/a_boxshell.md3";
		self.netname = "box of shotgun shells";
		self.aflag = 15;
	}
	else
	{
		self.model = "models/ammo/a_fewshell.md3";
		self.netname = "4 shotgun shells";
		self.aflag = 4;
	}
	
	// already precached, and you can't precache in the middle of a game
	if (self.classname != "drop_item")
		precache_model (self.model);
	else
		self.classname = "ammo_shell";
	
	setmodel (self, self.model);
	self.weapon = 1;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

// Bullets
void() ammo_bullets =
{
	self.touch = ammo_touch;

	if (self.spawnflags & AMMO_BIG)
	{
		self.model = "models/ammo/a_drum.md3";
		self.netname = "full drum of bullets";
		self.aflag = 100;
	}
	else
	{
		self.model = "models/ammo/a_fewbullet.md3";
		self.netname = "a few bullets";
		self.aflag = 15;
	}
	
	// already precached, and you can't precache in the middle of a game
	if (self.classname != "drop_item")
		precache_model (self.model);
	else
		self.classname = "ammo_bullets";
		
	setmodel (self, self.model);
	self.weapon = 2;
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

// Gasoline cans
void() ammo_gas =
{
	self.touch = ammo_touch;

	self.model = "models/ammo/a_gascan.md3";
	precache_model (self.model);
	setmodel (self, self.model);
	self.aflag = 6;

	self.weapon = 3;
	self.netname = "gasoline cans";
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

// Batteries
void() ammo_batteries =
{
	self.touch = ammo_touch;

	self.model = "models/ammo/a_battery.md3";
	
	// already precached, and you can't precache in the middle of a game
	if (self.classname != "drop_item")
		precache_model (self.model);
	else
		self.classname = "ammo_batteries";

	setmodel (self, self.model);
	self.aflag = 32;

	self.weapon = 4;
	self.netname = "batteries";
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


// Trapped soul
void() ammo_soul =
{
	self.touch = ammo_touch;

	self.model = "models/ammo/a_soul.md3";
	precache_model (self.model);
	setmodel (self, self.model);
	self.aflag = 10;

	self.weapon = 11;
	self.netname = "trapped soul";
	setsize (self, '0 0 0', '32 32 56');

	// Set animation loop
	self.anim_len = 12;  // 12 frames for the soul animation
	self.think1 = SUB_AutoAnimation;

	StartItem ();
};

/*
===============================================================================
KEYS
===============================================================================
*/
void() key_touch =
{
	local entity	stemp;
	local float 	best;

	if (other.classname != "player" || // if it's a player
		other.health <= 0			|| // if player is alive
		other.items2 & self.items2)    // if player already has the key
		return;
	
	sprint3 (other, "Picked up ", self.netname, "\n");

	sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

	// Changed to .items2 since that is where key bits are stored.
	other.items2 = other.items2 | self.items2;

	if (gametype == GT_COOPERATIVE)  // So others can pick up the key
	{
		self.think = SUB_regen;
		self.nextthink = time + 15;
	}
	else
	{
		self.solid = SOLID_NOT;
		self.model = string_null;
	}

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};

/*QUAKED item_key (0 .5 .8) (-16 -16 -24) (16 16 32)
one of six keys in Blood
the following keys need to exist in single player:
Skull, Eye, Fire, Dagger, Spider, Moon
*/
void() item_key =
{
	// Keys don't exist in multiplayer
	if (gametype != GT_COOPERATIVE && gametype != GT_SINGLE_PLAYER)
	{
		remove(self);
		return;
	}

	//for monster dropped keys
	self.classname = "item_key";
	
	if ((self.spawnflags & 63) == 0)
	{
		// Convert to skull key.
		dprint ("No key type -- converted to skull type.\n");
		self.spawnflags = self.spawnflags | 1;
	}

	if (self.spawnflags & IT2_KEY_SKULL)
	{
		self.skin		= 0;
		self.netname	= "Skull Key";
		self.items2 	= IT2_KEY_SKULL;
	}
	else if (self.spawnflags & IT2_KEY_EYE)
	{
		self.skin		= 1;
		self.netname	= "Eye Key";
		self.items2 	= IT2_KEY_EYE;
	}
	else if (self.spawnflags & IT2_KEY_FIRE)
	{
		self.skin		= 2;
		self.netname	= "Fire Key";
		self.items2 	= IT2_KEY_FIRE;
	}
	else if (self.spawnflags & IT2_KEY_DAGGER)
	{
		self.skin		= 3;
		self.netname	= "Dagger Key";
		self.items2 	= IT2_KEY_DAGGER;
	}
	else if (self.spawnflags & IT2_KEY_SPIDER)
	{
		self.skin		= 4;
		self.netname	= "Spider Key";
		self.items2 	= IT2_KEY_SPIDER;
	}
	else if (self.spawnflags & IT2_KEY_MOON)
	{
		self.skin		= 5;
		self.netname	= "Moon Key";
		self.items2 	= IT2_KEY_MOON;
	}

	precache_model ("models/items/i_key.md3");
	setmodel (self, "models/items/i_key.md3");
	//setsize (self, '-16 -16 -24', '16 16 32');
	setsize (self, '-16 -16 0', '16 16 56');

	if (!self.noise)
		self.noise	= "items/pickkey.wav";

	precache_sound (self.noise);
	self.touch	= key_touch;
	self.rotate = ITEM_ROTATION;
	StartItem ();
};

/*
===============================================================================
POWERUPS
===============================================================================
*/
// Doctor's Bag
void() item_artifact_bag =
{
	self.netname = "Doctor's Bag";
	self.model	 = "models/items/i_docbag.md3";
	item_powerup ();
	setsize (self, '-7 -11 0', '7 11 20');
};

// Boots of Jumping
void() item_artifact_boots =
{
	precache_sound ("bludbath/powerup.wav");

	self.netname = "Boots of Jumping";
	self.model	 = "models/items/i_boots.md3";
	item_powerup ();
	setsize (self, '-11 -10 0', '4 10 20');
};

// Crystal Ball
void() item_artifact_crystal =
{
	precache_sound ("bludbath/powerup.wav");

	self.netname = "Crystal Ball";
	self.model	 = "models/items/i_crystal.md3";
	item_powerup ();
	setsize (self, '-7 -7 0', '7 7 15');
};

// Diving Suit
void() item_artifact_divingsuit =
{
	precache_sound ("foley/swimuw.wav"); // diving suit engage sound

	self.netname = "Diving Suit";
	self.model	 = "models/items/i_diving.md3";
	item_powerup ();
	setsize (self, '-9 -13 0', '8 13 77');
};

// Cloak of Invisibility
void() item_artifact_invisibility =
{
	self.items = IT_INVISIBILITY;

	self.netname = "Cloak of Invisibility";
	self.model	 = "models/items/i_invisible.md3";
	self.noise	 = "bludbath/powerup.wav";
	item_powerup ();
	setsize (self, '-16 -16 0', '16 16 56');

	// Set animation loop
	self.anim_len = 11;  // 11 frames in the animation
	self.think1 = SUB_AutoAnimation;
};

// Death Mask
void() item_artifact_deathmask =
{
	self.effects = self.effects | EF_RED;
	self.items = IT_INVULNERABILITY;

	self.netname = "Death mask";
	self.model	 = "models/items/i_mask.md3";
	self.noise	 = "bludbath/powerup.wav";
	item_powerup ();
	setsize (self, '-4 -12 0', '2 12 30');
	// DeathMask rotates in Blood:
	self.rotate = ITEM_ROTATION;
};

// Reflective Shots
void() item_artifact_reflect =
{
	self.effects = self.effects | EF_BLUE;

	self.netname = "Reflective Shots";
	self.model	 = "models/items/i_reflect.md3";
	self.noise	 = "bludbath/powerup.wav";
	item_powerup ();
	setsize (self, '-7 -7 0', '7 11 16');

	// Set animation loop
	self.anim_len = 6;	// 6 frames in the animation
	self.think1 = SUB_AutoAnimation;
};

// Guns Akimbo
void() item_artifact_akimbo =
{
	self.netname = "Guns Akimbo";
	self.model	 = "models/items/i_akimbo.md3";
	self.noise	 = "bludbath/powerup.wav";
	item_powerup ();
	setsize (self, '-16 -16 0', '16 16 56');
};

// Beast Vision
void() item_artifact_vision =
{
	precache_sound ("bludbath/powerup.wav");

	self.netname = "Beast Vision";
	self.model	 = "models/items/i_vision.md3";
	item_powerup ();
	setsize (self, '-10 -9 0', '11 9 9');
	// Beast Vision rotates in Blood:
	self.rotate = ITEM_ROTATION;
};
