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


void() W_SetCurrentAmmo;
void(float newWeapon) W_SwitchToWeapon;
void() FireAmbient;

/* ALL LIGHTS SHOULD BE 0 1 0 IN COLOR ALL OTHER ITEMS SHOULD
BE .8 .3 .4 IN COLOR */


void() SUB_regen =
{
    self.model = self.mdl;      // restore original model
    self.solid = SOLID_TRIGGER; // allow it to be touched again
    sound (self, CHAN_VOICE, "bludbath/reappear.wav", 1, ATTN_NORM);    // item respawn sound
    setorigin (self, self.origin);

    // Don't call it back later
    if (self.think == SUB_regen)
        self.nextthink = 0;
    self.reset = SUB_Null;
};


void() Akimbo_Touch =
{
    local entity    stemp;
    local float     best;
    local string    s;

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
    SUB_UseTargets();                               // fire all targets / killtargets
};

void(float timeleft) Akimbo_Drop =
{
    local entity    item;

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
    item.nextthink = time + timeleft;    // remove it with the time left on it
    item.think = SUB_Remove;
    item.reset = SUB_Remove;
};

void() Invisibility_Touch =
{
    local float     best;
    local string    s;

    if (other.classname != "player")
        return;
    if (other.health <= 0)
        return;

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
    local entity    item;

    item = spawn();
    item.origin = self.origin;

    item.velocity_z = 300;
    item.velocity_x = -100 + (random() * 200);
    item.velocity_y = -100 + (random() * 200);

    item.flags = FL_ITEM;
    item.solid = SOLID_TRIGGER;
    item.movetype = MOVETYPE_TOSS;
    item.noise = "bludbath/powerup.wav";
    setmodel (item, "progs/invisibl.mdl");
    setsize (item, '-3 -6 -2', '6 7 23');
    item.cnt = time + timeleft;
    item.touch = Invisibility_Touch;
    item.nextthink = time + timeleft;    // remove after 30 seconds
    item.think = SUB_Remove;
    item.reset = SUB_Remove;
};


/*
============
PlaceItem

plants the item on the floor
============
*/
void() PlaceItem =
{
    self.mdl = self.model;      // so it can be restored on respawn
    self.flags = FL_ITEM;       // make extra wide
    self.solid = SOLID_TRIGGER;
    self.movetype = MOVETYPE_TOSS;
    self.velocity = '0 0 0';
    self.origin_z = self.origin_z + 2;
    if (!droptofloor())
    {
        dprint ("Bonus item \"");
        dprint (self.classname);
        dprint ("\" fell out of level at ");
        dprint (vtos(self.origin));
        dprint ("\n");
        remove(self);
        return;
    }

    // If the item has an animation loop
    if (self.think1)
    {
        self.nextthink = time + 0.1;
        self.think = self.think1;
    }
};

/*
============
StartItem

Sets the clipping size and plants the items on the floor
============
*/
void() StartItem =
{
    self.nextthink = time + 0.3;    // items start after other solids
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
    self.solid = SOLID_BBOX;
    self.movetype = MOVETYPE_TOSS;
    self.velocity = '0 0 0';
    self.origin_z = self.origin_z + 2;
    if (!droptofloor())
    {
        dprint ("Object \"");
        dprint (self.classname);
        dprint ("\" fell out of level at ");
        dprint (vtos(self.origin));
        dprint ("\n");
        remove(self);
        return;
    }

    // If there's no spawn flag and no animation, make the object static
    // (changes or interactions are then impossible, but as a consequence
    // the object has virtually no cost from the server point of view)
    if (!self.spawnflags && !self.think1)
    {
        makestatic (self);
        return;
    }

    self.touch = SUB_SolidTouch;

    // If the object has an animation loop
    if (self.think1)
    {
        self.nextthink = time + 0.1;
        self.think = self.think1;
    }
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

    self.nextthink = time + 0.2;    // objects start after other solids, but before items
    self.think = PlaceObject;
};


// small tome or book, closed
void() obj_tome =
{
    StartObject ("progs/a_tome.mdl", '-10 -4 -10', '10 4 11');
};

// small potion vial
void() obj_boost =
{
    StartObject ("progs/a_boost.mdl", '-5 -6 -9', '5 6 10');
};

// large potion goblet

void() obj_mboost =
{
    StartObject ("progs/a_mboost.mdl", '-9 -10 -9', '9 10 10');
};

// a slab of beef, found in restaraunt freezers
void() obj_beefslab =
{
    StartObject ("progs/beefslab.mdl", '-14 -14 1', '22 14 89');
};

// pile of bones
void() obj_bonepile =
{
    StartObject ("progs/bonepile.mdl", '-16 -15 -3', '16 16 14');
};

// another book, closed
void() obj_bookclos =
{
    StartObject ("progs/bookclos.mdl", '-9 -7 -1', '9 7 6');
};

// another book, open
void() obj_bookopen =
{
    StartObject ("progs/bookopen.mdl", '-8 -14 -1', '9 14 5');
};

// small bush
void() obj_bush1 =
{
    StartObject ("progs/bush1.mdl", '-31 -34 -1', '31 32 39');
};

// chrome flaming torch
void() obj_cflmtrch =
{
    FireAmbient ();
    StartObject ("progs/cflmtrch.mdl", '-9 -6 -29', '8 6 27');
};

// Corpse, Face up
void() obj_corps2 =
{
    StartObject ("progs/corps2.mdl", '-37 -17 -2', '39 17 13');
};

// a rusty metal cross with a tilted cross beam
void() obj_cross =
{
    StartObject ("progs/cross.mdl", '-3 -12 -19', '3 12 21');
};

// an egyptian looking torch
void() obj_eflmtrch =
{
    FireAmbient ();
    StartObject ("progs/eflmtrch.mdl", '-12 -5 -21', '14 5 34');
};

// egytpian torch, unlit
void() obj_egtorch =
{
    StartObject ("progs/egtorch.mdl", '-12 -5 -21', '12 5 9');
};

// Iron Fence Gateway
void() obj_fence =
{
    StartObject ("progs/fence.mdl", '-3 -25 0', '3 29 53');
};

// large 2 tier fountain
void() obj_fountain =
{
    // TODO: Water sound here?
    StartObject ("progs/fountain.mdl", '-31 -27 -1', '31 27 95');
};

// Soccer Goal
void() obj_goal =
{
    StartObject ("progs/goalpost.mdl", '-51 -65 -3', '55 65 111');
};

// tall triangular hedge
void() obj_hedge1 =
{
    StartObject ("progs/hedge1.mdl", '-27 -27 -1', '26 26 92');
};

// tall square hedge
void() obj_hedge2 =
{
    StartObject ("progs/hedge2.mdl", '-19 -28 0', '18 29 89');
};

// tall rounded hedge
void() obj_hedge3 =
{
    StartObject ("progs/hedge3.mdl", '-27 -27 -1', '27 27 127');
};

// cross with fluer de lis
void() obj_holycrss =
{
    StartObject ("progs/holycrss.mdl", '-6 -13 -19', '6 13 21');
};

// small plant
void() obj_plantgen =
{
    StartObject ("progs/plantgen.mdl", '-30 -29 -1', '29 30 30');
};

// potted plant
void() obj_plantmez =
{
    StartObject ("progs/plantmez.mdl", '-30 -29 -1', '29 30 39');
};

// plant in vase
void() obj_plantrom =
{
    StartObject ("progs/plantrom.mdl", '-39 -38 -1', '39 39 95');
};

// large 2 handled jug, 4 skins
void() obj_pot1 =
{
    StartObject ("progs/pot1.mdl", '-19 -32 -1', '19 32 58');
};

// large vase, 4 skins
void() obj_pot2 =
{
    StartObject ("progs/pot2.mdl", '-12 -14 0', '12 14 42');
};

// large vase, 4 skins
void() obj_pot3 =
{
    StartObject ("progs/pot3.mdl", '-17 -19 -1', '17 20 48');
};

// roman style flaming torch
void() obj_rflmtrch =
{
    FireAmbient ();
    StartObject ("progs/rflmtrch.mdl", '-10 -10 -15', '2 10 27');
};

// seaweed
void() obj_seaweed =
{
    StartObject ("progs/seaweed.mdl", '-4 -5 0', '4 5 72');
};

// 1 skull on a stick
void() obj_skllstk1 =
{
    StartObject ("progs/skllstk1.mdl", '-5 -5 -1', '5 3 55');
};

// 2 skulls on a stick
void() obj_skllstk2 =
{
    StartObject ("progs/skllstk2.mdl", '-5 -2 -1', '6 8 57');
};

//  cross tombstone
void() obj_tombstn1 =
{
    StartObject ("progs/tombstn1.mdl", '-8 -25 -1', '8 25 72');
};

// oval tombstone
void() obj_tombstn2 =
{
    StartObject ("progs/tombstn2.mdl", '-5 -16 -1', '5 16 44');
};

// R. I. P. tombstone
void() obj_tombstn3 =
{
    StartObject ("progs/tombstn3.mdl", '-7 -19 -1', '7 18 48');
};

// dead tree
void() obj_tree =
{
    StartObject ("progs/tree.mdl", '-16 -16 0', '16 16 32');
};

// leafy tree
void() obj_tree2 =
{
    StartObject ("progs/tree2.mdl", '-16 -16 0', '16 16 32');
};

// small spider webs
// TODO: Accept a spawn flag differentiating between the skins
void() obj_webs =
{
    StartObject ("progs/webs.mdl", '-1 -23 -28', '4 23 26');
    // TODO: set skin ...
};

// Brown skull
void() obj_skull =
{
    StartObject ("progs/skull.mdl", '-6 -4 0', '6 4 11');
};

// book with skull on it
void() obj_skulbook =
{
    StartObject ("progs/skulbook.mdl", '-7 -6 -1', '7 6 2');
};

// bar stool
void() obj_stool =
{
    StartObject ("progs/stool.mdl", '-7 -7 0', '7 7 18');
};

// another scroll
void() obj_hbook =
{
    StartObject ("progs/h-book.mdl", '-5 -9 -13', '5 9 14');
};

// White skull
void() obj_m2 =
{
    StartObject ("progs/m2.mdl", '-12 -8 -11', '12 8 11');
};

// Green skull
void() obj_m3 =
{
    StartObject ("progs/m3.mdl", '-12 -8 -11', '12 8 11');
};

// another book
void() obj_mage =
{
    StartObject ("progs/mage.mdl", '-8 -11 -11', '7 11 12');
};

// shovel
void() obj_shovel =
{
    StartObject ("progs/shovl.mdl", '-16 -16 -16', '16 16 16');
};

// a boiling cauldron
void() obj_cauldron =
{
    StartObject ("progs/cauldron.mdl", '-32 -21 0', '24 20 34');
};

// barrels -
// skin0 = tnt (don't use), skin1 = wine barrel,
// skin2 = zombie head barrel, skin3 = "waste" barrel
void() obj_barrel =
{
    StartObject ("progs/barrel.mdl", '-16 -16 -14', '16 16 42');
};

// jar with a brain in it
// skin0 is green fluid
// skin1 is red fluid
void() obj_brainjar =
{
    StartObject ("progs/jar.mdl", '-11 -7 -1', '14 8 28');
};

// drum-type barrel
// skin0 is zombie head with blood,  "Caution Toxic Waste"
// skin1 is green slime, "Caution - Toxic"
void() obj_drum =
{
    StartObject ("progs/drum.mdl", '-14 -14 -1', '14 14 36');
};


// -------------------- MD3 models -------------------- //

// Glass Jar w/brain (tile0075)
void() obj_world_jar1 =
{
    StartObject ("models/world/jar1.md3", '-8 -8 0', '9 9 18');
};

// Pram (tile0183)
void() obj_world_pram =
{
    StartObject ("models/world/pram.md3", '-17 -32 0', '17 35 43');
};

// Stake w/ 1 skull (tile0257)
void() obj_world_skllstk1 =
{
    StartObject ("models/world/skllstk1.md3", '-6 -5 0', '5 5 52');
};

// Stake w/ 3 skulls (tile0258)
void() obj_world_skllstk2 =
{
    StartObject ("models/world/skllstk2.md3", '-6 -4 0', '5 6 55');
};

// Ceiling Light (tile0468)
void() obj_world_light1 =
{
    StartObject ("models/world/light1.md3", '-5 -6 -13', '5 6 13');
};

// Sink taps (tile0485)
void() obj_world_sinktaps =
{
    StartObject ("models/world/sinktaps.md3", '-3 -11 0', '12 11 9');
};

// Waste bucket (tile0505)
void() obj_world_bucket1 =
{
    StartObject ("models/world/bucket1.md3", '-6 -6 0', '6 6 24');
};

// Large Vase (tile0537)
void() obj_world_pot1 =
{
    StartObject ("models/world/pot1.md3", '-8 -9 0', '8 9 38');
};

// Wall torch (tile0570)
void() obj_world_torch =
{
    StartObject ("models/world/torch.md3", '-5 -5 -6', '5 5 6');
};

// Wreath (tile0575)
void() obj_world_wreath1 =
{
    StartObject ("models/world/wreath1.md3", '-11 -16 0', '11 16 58');
};

// Short Candelabra (tile0584)
void() obj_world_candlbr1 =
{
    // Set animation loop
    self.anim_len = 4;
    self.think1 = SUB_AutoAnimation;

    StartObject ("models/world/candlbr1.md3", '-3 -10 0', '3 10 38');
};

// Tall Candelabra (tile0580)
void() obj_world_candlbr2 =
{
    // Set animation loop
    self.anim_len = 4;
    self.think1 = SUB_AutoAnimation;

    StartObject ("models/world/candlbr2.md3", '-5 -7 0', '5 7 54');
};

// Small Pot (tile0604)
void() obj_world_pot5 =
{
    StartObject ("models/world/pot5.md3", '-7 -7 0', '7 7 15');
};

// Skull on stake w/rags (tile0607)
void() obj_world_skullrag =
{
    StartObject ("models/world/skullrag.md3", '-6 -19 0', '5 20 71');
};

// Big Wreath (tile0633)
void() obj_world_wreath2 =
{
    StartObject ("models/world/wreath2.md3", '0 -49 -42', '11 50 47');
};

// Garden Lantern (tile0640)
void() obj_world_lantern1 =
{
    StartObject ("models/world/lantern1.md3", '-6 -8 0', '8 8 63');
};

// Fire Extinguisher (tile0658)
void() obj_world_extngsh =
{
    StartObject ("models/world/extngsh.md3", '-4 -12 16', '4 13 61');
};

// Stone Statue (tile0679)
void() obj_world_statue4 =
{
    StartObject ("models/world/statue4.md3", '-15 -17 0', '15 17 112');
};

// Severed Leg (tile0682)
void() obj_world_leg1 =
{
    StartObject ("models/world/leg1.md3", '-8 -3 0', '9 4 7');
};

// Impaled Skull (tile0685)
void() obj_world_skllstk3 =
{
    StartObject ("models/world/skllstk3.md3", '-6 -5 0', '5 5 19');
};

// Wooden Cross Tombstone (tile0703)
void() obj_world_tombstn6 =
{
    StartObject ("models/world/tombstn6.md3", '-8 -16 0', '8 14 47');
};

// Large Cross Tombstone (tile0678)
void() obj_world_tombstn5 =
{
    StartObject ("models/world/tombstn5.md3", '-10 -24 0', '10 24 62');
};

// Old Tombstone (tile0704)
void() obj_world_tombstn4 =
{
    StartObject ("models/world/tombstn4.md3", '-14 -21 -6', '7 18 45');
};

// RIP Tombstone (tile0701)
void() obj_world_tombstn3 =
{
    StartObject ("models/world/tombstn3.md3", '-18 -6 0', '18 6 47');
};

// Broken Tombstone (tile0705)
void() obj_world_tombstn2 =
{
    StartObject ("models/world/tombstn2.md3", '-7 -22 0', '7 22 57');
};

// Tombstone w/cross (tile0706)
void() obj_world_tombstn1 =
{
    StartObject ("models/world/tombstn1.md3", '-7 -22 0', '7 22 72');
};

// Bottle (tile0759)
void() obj_world_bottle2 =
{
    StartObject ("models/world/bottle2.md3", '-2 -2 0', '2 2 16');
};

// Stone Jar (tile0802)
void() obj_world_jar2 =
{
    StartObject ("models/world/jar2.md3", '-3 -3 0', '3 3 9');
};

// Boulder (tile804)
void() obj_world_boulder =
{
    StartObject ("models/world/boulder.md3", '-18 -13 0', '18 13 10');
};

// Skull (tile807)
void() obj_world_skull1 =
{
    StartObject ("models/world/skull1.md3", '-5 -5 0', '5 5 8');
};

// Wooden Barrel (tile0907)
// NOTE: the model has 2 static frames (0- standing on end, 1- lying on side)
void() obj_world_barrel =
{
    StartObject ("models/world/barrel.md3", '-15 -15 0', '15 15 43');
};

// IV Drip (tile0962)
void() obj_world_ivdrip =
{
    StartObject ("models/world/ivdrip.md3", '-11 -11 0', '11 11 55');
};

// Potted Plant (tile1009)
void() obj_world_plant1 =
{
    StartObject ("models/world/plant1.md3", '-4 -4 0', '4 4 8');
};

// Large Urn (tile1063)
void() obj_world_pot2 =
{
    StartObject ("models/world/pot2.md3", '-17 -18 0', '18 18 41');
};

// Draven Tombstone (tile1159)
void() obj_world_draven =
{
    StartObject ("models/world/draven.md3", '-6 -18 0', '6 18 47');
};

// Spade (tile1712)
void() obj_world_spade =
{
    StartObject ("models/world/spade.md3", '-1 -5 -18', '1 5 18');
};

// Shovel (tile1713)
void() obj_world_shovel =
{
    StartObject ("models/world/shovel.md3", '-0 -7 -27', '3 7 26');
};

// Saw (tile1714)
void() obj_world_saw =
{
    StartObject ("models/world/saw.md3", '-1 -4 -9', '1 6 15');
};

// Calipers (tile1715)
void() obj_world_calipers =
{
    StartObject ("models/world/calipers.md3", '-0 -5 -9', '2 5 10');
};

// Poker (tile1716)
void() obj_world_poker =
{
    StartObject ("models/world/poker.md3", '-1 -1 8', '1 3 36');
};

// Dead body (tile2333)
void() obj_world_body1 =
{
    StartObject ("models/world/body1.md3", '-21 -12 -1', '27 23 19');
};

// Dead Tree (tile0540)
void() obj_world_tree =
{
    StartObject ("models/world/tree.md3", '-32 -41 0', '52 45 174');
};

// Live Tree (tile0541)
void() obj_world_tree2 =
{
    StartObject ("models/world/tree2.md3", '-32 -41 0', '52 45 174');
};

// Clock (tile1165)
void() obj_world_clock =
{
    StartObject ("models/world/clock.md3", '0 -10 -10', '2 10 10');
};


// Metal Barrel (tile0201)
void() obj_world_metbarrel =
{
    StartObject ("models/world/metbarrel.md3", '-14 -14 0', '14 14 36');
};


// Metal Body Barrel (tile0563)
void() obj_world_metbarrel2 =
{
    StartObject ("models/world/metbarrel2.md3", '-14 -14 0', '14 14 36');
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
    else if (self.classname == "item_artifact_envirosuit")
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
    else if (self.classname == "item_artifact_invulnerability")
    {
        other.invincible_time = 1;
        other.invincible_finished = time + 30;
    }
    else if (self.classname == "item_artifact_reflect")
    {
        other.reflect_finished = time + 30;
    }
    else if (self.classname == "item_artifact_super_damage")
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
    if ((self.classname == "item_artifact_invulnerability") ||
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
    SUB_UseTargets();               // fire all targets / killtargets
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
    local   float amount;
    local   string  s;

    if (other.classname != "player")
        return;

    if (self.healtype == 2) // Megahealth?  Ignore max_health...
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
    SUB_UseTargets();       // fire all targets / killtargets
};


#define H_LIFE_ESSENCE  1
#define H_LIFE_SEED     2

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
        self.anim_len = 8;  // 8 frames in the animation
        self.think1 = SUB_AutoAnimation;

        // If flashy effects are allowed, make it glow
        if (cvar ("g_flashyEffects"))
        {
            // Only available if the engine supports the DP_ENT_GLOW extension
            if (checkextension ("DP_ENT_GLOW"))
            {
                self.glow_color = 250;  // 250 = red in Quake palette
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
        self.anim_len = 9;  // 9 frames in the animation
        self.think1 = SUB_AutoAnimation;
    }
    else
    {
        self.model = "models/items/i_pouch.md3";
        self.healamount = 50;
        self.netname = "Medicine Patch";
        self.healtype = 1;
    }

    precache_model (self.model);
    setmodel(self, self.model);
    setsize (self, '-16 -16 0', '16 16 56');

    self.noise = "items/pickheal.wav";
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
    local   float   type, value, bit;

    if (other.health <= 0)
        return;
    if (other.classname != "player")
        return;

    if (self.classname == "item_armor1")
    {
        // Body armor
        if (other.armor_body >= 100)
            return;
        value = other.armor_body = 100;
        bit = IT_ARMOR1;
    }
    else if (self.classname == "item_armor2")
    {
        // Fire armor
        if (other.armor_fire >= 100)
            return;
        value = other.armor_fire = 100;
        bit = IT_ARMOR2;
    }
    else if (self.classname == "item_armorInv")
    {
        // Super armor (200 of all three armors).
        if (other.armor_body >= 200)
            if (other.armor_fire >= 200)
                if (other.armor_mind >= 200)
                    return;

        other.armor_body = other.armor_fire = other.armor_mind = 200;

        bit = other.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3);
        if (bit == IT_ARMOR1)
            value = other.armor_body;
        else if (bit == IT_ARMOR2)
            value = other.armor_fire;
        else
        {
            bit = IT_ARMOR3;
            value = other.armor_mind;
        }
    }
    else if (self.classname == "item_armor0")
    {
        // Basic armor
        if (other.armor_body >= 100)
            if (other.armor_fire >= 100)
                if (other.armor_mind >= 100)
                    return;

        other.armor_body = other.armor_body + 50;
        if (other.armor_body > 100)
            other.armor_body = 100;
        other.armor_fire = other.armor_fire + 50;
        if (other.armor_fire > 100)
            other.armor_fire = 100;
        other.armor_mind = other.armor_mind + 50;
        if (other.armor_mind > 100)
            other.armor_mind = 100;

        bit = other.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3);
        if (bit == IT_ARMOR3)
            value = other.armor_mind;
        else if (bit == IT_ARMOR2)
            value = other.armor_fire;
        else
        {
            bit = IT_ARMOR1;
            value = other.armor_body;
        }
    }
    else if (self.classname == "item_armor4")
    {
        // Spirit armor
        if (other.armor_mind >= 100)
            return;
        value = other.armor_mind = 100;
        bit = IT_ARMOR3;
    }
    else
        sprint(other, "Tried to pickup illegal armor.\n");

    other.armorvalue = value;
    if (bit)
        other.items = other.items - (other.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + bit;

    self.solid = SOLID_NOT;
    self.model = string_null;
    self.nextthink = time + 20;
    self.think = SUB_regen;
    self.reset = SUB_regen;

    sprint3 (other, "Picked up ", self.netname, "\n");
    sound (other, CHAN_ITEM, "items/pickarmr.wav", 1, ATTN_NORM);
    stuffcmd (other, "bf\n");

    activator = other;
    SUB_UseTargets();               // fire all targets / killtargets
};

// Basic Armor
void() item_armor0 =
{
    self.touch = armor_touch;
    self.model = "models/items/armour/i_arm_basic.md3";
    precache_model (self.model);
    setmodel (self, self.model);
    self.netname = "Basic Armor";

    setsize (self, '-7 -18 0', '10 18 38');
    StartItem ();
};

// Spirit Armor
void() item_armor4 =
{
    self.touch = armor_touch;
    self.model = "models/items/armour/i_arm_spirit.md3";
    precache_model (self.model);
    setmodel (self, self.model);
    self.netname = "Spirit Armor";

    setsize (self, '-2 -17 0', '4 19 37');
    StartItem ();
};

// Body Armor
void() item_armor1 =
{
    self.touch = armor_touch;
    self.model = "models/items/armour/i_arm_body.md3";
    precache_model (self.model);
    setmodel (self, self.model);
    self.netname = "Body Armor";

    setsize (self, '-1 -18 0', '6 19 45');
    StartItem ();
};

// Fire Armor
void() item_armor2 =
{
    self.touch = armor_touch;
    self.model = "models/items/armour/i_arm_fire.md3";
    precache_model (self.model);
    setmodel (self, self.model);
    self.netname = "Fire Armor";

    setsize (self, '-7 -12 0', '7 10 37');
    StartItem ();
};

// Super Armor
void() item_armorInv =
{
    self.touch = armor_touch;
    self.model = "models/items/armour/i_arm_super.md3";
    precache_model (self.model);
    setmodel (self, self.model);
    self.netname = "Super Armor";

    setsize (self, '-16 -16 0', '16 16 56');
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
    precache_sound ("player/quips/1039.wav");   // SOB must pay !
    precache_sound ("player/quips/1050.wav");   // That's all folks !
    precache_sound ("player/quips/1057.wav");   // Rest in pieces
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
    if (other.ammo_flares > MAX_FLARES)
        other.ammo_flares = MAX_FLARES;
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
    local   float   new;
    local   float   leave;
    local   entity  temp;

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
        other.ammo_flares = other.ammo_flares + 9;
    }
    else if (self.classname == "weapon_nailgun")
    {
        if (leave && (other.items & IT_TOMMYGUN) )
            return;
        new = IT_TOMMYGUN;
        other.ammo_nails = other.ammo_nails + 50;
    }
    else if (self.classname == "weapon_supernailgun")
    {
        if (leave && (other.items & IT_SPRAY_CAN) )
            return;
        new = IT_SPRAY_CAN;
        other.ammo_spray = other.ammo_spray + 48;
    }
    else if (self.classname == "weapon_supershotgun")
    {
        if (leave && (other.items & IT_SAWED_OFF) )
            return;
        new = IT_SAWED_OFF;
        other.ammo_shells = other.ammo_shells + 8;
    }
    else if (self.classname == "weapon_rocketlauncher")
    {
        if (leave && (other.items & IT_NAPALM_LAUNCHER) )
            return;
        new = IT_NAPALM_LAUNCHER;
        other.ammo_rockets = other.ammo_rockets + 6;
    }
    else if (self.classname == "weapon_grenadelauncher")
    {
        if (leave && (other.items & IT_TNT) )
            return;
        new = IT_TNT;
        other.ammo_tnt_bundle = other.ammo_tnt_bundle + 5;
    }
    else if (self.classname == "item_tnt")
    {
        new = IT_TNT;
        other.ammo_tnt_bundle = other.ammo_tnt_bundle + 1;
        leave = 0;
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
    else if (self.classname == "weapon_lightning")
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
    SUB_UseTargets();               // fire all targets / killtargets
};


// Flaregun
void() weapon_flaregun =
{
    precache_model ("models/weapons/v_flare.md3");
    precache_model ("models/weapons/g_flare.md3");
    precache_model ("models/weapons/ga_flare.md3");  // akimbo model

    setmodel (self, "models/weapons/g_flare.md3");
    self.weapon = IT_FLAREGUN;
    self.netname = "Flare Gun";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // precache the necessary sounds
    PsychoCaleb_Precache ();
    precache_model ("progs/flame2.mdl");
    precache_sound ("weapons/flaregun/flaref.wav");
    precache_sound ("weapons/napalm/explodfs.wav");  // For alt-flares

    available_weapons = available_weapons | IT_FLAREGUN;

    StartItem ();
};

// Sawed-off
void() weapon_supershotgun =
{
    precache_model ("models/weapons/v_shot.md3");
    precache_model ("models/weapons/ga_shot.md3");  // akimbo model
    precache_model ("models/weapons/g_shot.md3");
    precache_model ("progs/shotshl.mdl");   // shotgun shell

    setmodel (self, "models/weapons/g_shot.md3");
    self.weapon = IT_SAWED_OFF;
    self.netname = "Sawed-off";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // Precache the necessary sounds
    precache_sound ("weapons/shotgun/shotcock.wav");  // shell ejection
    precache_sound ("weapons/shotgun/shotfir2.wav");  // shotgun alt-fire
    precache_sound ("weapons/shotgun/shotfire.wav");  // shotgun fired
    precache_sound ("weapons/shotgun/shotload.wav");  // reload sound
    precache_sound ("weapons/shtshl2.wav");  // shell hitting ground

    available_weapons = available_weapons | IT_SAWED_OFF;

    StartItem ();
};

// Tommy Gun
void() weapon_nailgun =
{
    precache_model ("models/weapons/v_tommy.md3");
    precache_model ("models/weapons/ga_tommy.md3");  // akimbo model
    precache_model ("models/weapons/g_tommy.md3");
    precache_model ("progs/tommyshl.mdl");  // tommy gun shell

    setmodel (self, "models/weapons/g_tommy.md3");
    self.weapon = IT_TOMMYGUN;
    self.netname = "Tommy Gun";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // Precache the necessary sounds
    precache_sound ("weapons/tommygun/_tom.wav");     // Fire
    precache_sound ("weapons/tommygun/tomcock.wav");  // Out of bullet noise
    precache_sound ("weapons/shtshl.wav");            // shell hitting ground
    precache_sound ("weapons/shtshl3.wav");           // shell hitting ground (2nd)

    available_weapons = available_weapons | IT_TOMMYGUN;

    StartItem ();
};

// Spray Can
void() weapon_supernailgun =
{
    #ifndef NEW_MODELS
    precache_model ("progs/v_nail2.mdl");
    precache_model ("progs/g_nail2.mdl");
    precache_model ("progs/grd_aero.mdl");
    #else
    precache_model ("models/weapons/v_aerosol.md3");
    precache_model ("models/ammo/g_aerosol.md3");
    precache_model ("models/weapons/grenades/gr_aerosol.md3");
    #endif

    #ifndef NEW_MODELS
    setmodel (self, "progs/g_nail2.mdl");
    #else
    setmodel (self, "models/ammo/g_aerosol.md3");
    #endif
    self.weapon = IT_SPRAY_CAN;
    self.netname = "Spray Can";
    self.touch = weapon_touch;
    setsize (self, '-8 -8 0', '8 8 32');

    // Precache the necessary sounds
    precache_sound ("weapons/spraycan/spraycan.wav");  // lighted spray can
    precache_sound ("weapons/spraycan/sprayfir.wav");  // fire
    precache_sound ("weapons/tnt/lighter.wav");  // = zipopen.wav + ziplight.wav
    precache_sound ("weapons/tnt/zipclose.wav");

    precache_model ("progs/sprayfir.spr");

    available_weapons = available_weapons | IT_SPRAY_CAN;

    StartItem ();
};


// TNT (case & bundle)
void() item_tnt_common =
{
    #ifndef NEW_MODELS
    precache_model ("progs/v_rock.mdl");
    precache_model ("progs/grd_bund.mdl");
    #else
    precache_model ("models/weapons/v_tnt.md3");
    precache_model ("models/weapons/grenades/gr_tnt.md3");
    #endif

    precache_model (self.model);
    setmodel (self, self.model);

    self.weapon = IT_TNT;
    self.touch = weapon_touch;

    // Precache the necessary sounds
    PsychoCaleb_Precache ();
    precache_sound ("weapons/tnt/lighter.wav");  // = zipopen.wav + ziplight.wav
    precache_sound ("weapons/tnt/tntfuse.wav");  // tnt lit
    precache_sound ("weapons/tnt/tnttoss.wav");  // throw sound
    precache_sound ("weapons/tnt/zipclose.wav");

    available_weapons = available_weapons | IT_TNT;

    StartItem ();
};

// Case of TNT
void() weapon_grenadelauncher =
{
    #ifndef NEW_MODELS
    self.model = "progs/g_rock.mdl";
    #else
    self.model = "models/weapons/g_tnt.md3";
    #endif
    self.netname = "Case of TNT";
    item_tnt_common ();
    setsize (self, '-16 -16 0', '16 16 56');
};

// TNT Bundle
void() item_tnt =
{
    #ifndef NEW_MODELS
    self.model = "progs/i_tnt.mdl";
    #else
    self.model = "models/ammo/a_tnt.md3";
    #endif
    self.netname = "Bundle of TNT";
    item_tnt_common ();
    setsize (self, '-8 -8 0', '8 8 32');
};

// Proximity bombs
void() weapon_proximity =
{
    #ifndef NEW_MODELS
    precache_model ("progs/v_proxy.mdl");
    precache_model ("progs/g_proxy.mdl");
    precache_model ("progs/grd_prox.mdl");
    #else
    precache_model ("models/weapons/v_proxy.md3");
    precache_model ("models/weapons/g_proxy.md3");
    precache_model ("models/weapons/grenades/gr_proxy.md3");
    #endif

    #ifndef NEW_MODELS
    setmodel (self, "progs/g_proxy.mdl");
    #else
    setmodel (self, "models/weapons/g_proxy.md3");
    #endif
    self.weapon = IT_PROXIMITY_BOMB;
    self.netname = "Proximity Bomb";
    self.touch = weapon_touch;
    setsize (self, '-8 -8 0', '8 8 32');

    // Precache the necessary sounds
    PsychoCaleb_Precache ();
    precache_sound ("weapons/tnt/proxarm.wav");  // proximity bomb armed
    precache_sound ("weapons/tnt/proxdet.wav");  // proximity bomb triggered
    precache_sound ("weapons/tnt/tnttoss.wav");  // throw sound

    available_weapons = available_weapons | IT_PROXIMITY_BOMB;

    StartItem ();
};

// Remote detonators
void() weapon_remote =
{
    #ifndef NEW_MODELS
    precache_model ("progs/v_remote.mdl");
    precache_model ("progs/grd_remo.mdl");
    precache_model ("progs/g_remote.mdl");
    setmodel (self, "progs/g_remote.mdl");
    #else
    precache_model ("models/weapons/v_remote.md3");
    precache_model ("models/weapons/grenades/gr_remote.md3");
    precache_model ("models/weapons/g_remote.md3");
    setmodel (self, "models/weapons/g_remote.md3");
    #endif

    self.weapon = IT_REMOTE_DETONATOR;
    self.netname = "Remote Detonator";
    self.touch = weapon_touch;
    setsize (self, '-8 -8 0', '8 8 32');

    // Precache the necessary sounds
    PsychoCaleb_Precache ();
    precache_sound ("weapons/tnt/remdet.wav");   // bomb triggered
    precache_sound ("weapons/tnt/remfire.wav");  // remote triggered
    precache_sound ("weapons/tnt/tnttoss.wav");  // throw sound

    available_weapons = available_weapons | IT_REMOTE_DETONATOR;

    StartItem ();
};

// Napalm Launcher
void() weapon_rocketlauncher =
{
    precache_model ("models/weapons/v_napalm.md3");
    precache_model ("models/weapons/ga_napalm.md3");
    precache_model ("models/weapons/g_napalm.md3");

    setmodel (self, "models/weapons/g_napalm.md3");
    self.weapon = IT_NAPALM_LAUNCHER;
    self.netname = "Napalm Launcher";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    precache_model ("progs/missile.mdl");  // napalm regular fire
    precache_model ("progs/naltball.mdl"); // napalm alt fire model

    // Precache the necessary sounds
    PsychoCaleb_Precache ();
    precache_sound ("weapons/napalm/blaster.wav");  // Shot

    available_weapons = available_weapons | IT_NAPALM_LAUNCHER;

    StartItem ();
};

// Telsa Cannon
void() weapon_lightning =
{
    precache_model ("models/weapons/v_tesla.md3");
    precache_model ("models/weapons/ga_tesla.md3");  // Akimbo model
    precache_model ("models/weapons/g_tesla.md3");
    precache_model ("progs/teslaball.spr");
    precache_model ("progs/bolt2.mdl");

    setmodel (self, "models/weapons/g_tesla.md3");
    self.weapon = IT_TESLA_CANNON;
    self.netname = "Tesla Cannon";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // Precache the necessary sounds
    precache_sound ("weapons/tesla/tessngfr.wav");  // normal fire
    precache_sound ("weapons/tesla/tessnght.wav");  // normal hit
    precache_sound ("weapons/tesla/tesaltht.wav");  // altfire hit
    precache_sound ("weapons/tesla/tessuper.wav");  // alt fire charge up + fire
    precache_sound ("weapons/tesla/tesakima.wav");  // alt fire charge up + fire (Akimbo)

    available_weapons = available_weapons | IT_TESLA_CANNON;

    StartItem ();
};

// Voodoo Doll
void() weapon_voodoodoll =
{
    #ifndef NEW_MODELS
    precache_model ("progs/v_voodoo.mdl");
    precache_model ("progs/g_voodoo.mdl");
    #else
    precache_model ("models/weapons/v_voodoo.md3");
    precache_model ("models/weapons/g_voodoo.md3");
    #endif

    #ifndef NEW_MODELS
    setmodel (self, "progs/g_voodoo.mdl");
    #else
    setmodel (self, "models/weapons/g_voodoo.md3");
    #endif
    self.weapon = IT_VOODOO_DOLL;
    self.netname = "Voodoo Doll";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // Precache the necessary sounds
    precache_sound ("weapons/voodoodl/voolaugh.wav");
    precache_sound ("weapons/voodoodl/voostab.wav");
    precache_sound ("weapons/voodoodl/voochant.wav");

    available_weapons = available_weapons | IT_VOODOO_DOLL;

    StartItem ();
};

// Life Leech
void() weapon_lifeleech =
{
    precache_model ("models/weapons/v_leech.md3");
    precache_model ("models/weapons/g_leech.md3");
    precache_model ("progs/bolt.mdl");
    precache_model ("progs/teslaball.spr");

    setmodel (self, "models/weapons/g_leech.md3");
    self.weapon = IT_LIFE_LEECH;
    self.netname = "Life Leech";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // precache the necessary sounds
    precache_sound ("weapons/lifelech/laltfr1.wav");
    precache_sound ("weapons/lifelech/llaltht.wav");    // LL sentry destroyed
    precache_sound ("weapons/napalm/explodfs.wav");     // altfire missile touch

    available_weapons = available_weapons | IT_LIFE_LEECH;

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
        if (other.ammo_flares >= MAX_FLARES)
            return;
        other.ammo_flares = other.ammo_flares + self.aflag;
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
    SUB_UseTargets();               // fire all targets / killtargets
};


#define AMMO_BIG 1

// Flares
void() item_flares =
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
void() item_shells =
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
    precache_model (self.model);
    setmodel (self, self.model);
    self.weapon = 1;
    setsize (self, '-16 -16 0', '16 16 56');
    StartItem ();
};

// Bullets
void() item_spikes =
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
    precache_model (self.model);
    setmodel (self, self.model);
    self.weapon = 2;
    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
};

// Gasoline cans
void() item_rockets =
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
void() item_cells =
{
    self.touch = ammo_touch;

    self.model = "models/ammo/a_battery.md3";
    precache_model (self.model);
    setmodel (self, self.model);
    self.aflag = 32;

    self.weapon = 4;
    self.netname = "batteries";
    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
};


// Trapped soul
void() item_soul =
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
local entity    stemp;
local float     best;

    if (other.classname != "player")
        return;
    if (other.health <= 0)
        return;

    // Changed to .items2 since that is where key bits are stored.
    if (other.items2 & self.items2)
        return;

    sprint3 (other, "Picked up ", self.netname, "\n");

    sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
    stuffcmd (other, "bf\n");

    // Changed to .items2 since that is where key bits are stored.
    other.items2 = other.items2 | self.items2;

    self.solid = SOLID_NOT;
    self.model = string_null;

    activator = other;
    SUB_UseTargets();               // fire all targets / killtargets
};


/*QUAKED item_key (0 .5 .8) (-16 -16 -24) (16 16 32)
one of six keys in Blood
the following keys need to exist in single player:
Skull, Eye, Fire, Dagger, Spider, Moon
*/
void() item_key =
{
    self.classname = "item_key";
    if ((self.spawnflags & 63) == 0)
    {
        // Convert to skull key.
        dprint ("No key type -- converted to skull type.\n");
        self.spawnflags = self.spawnflags | 1;
    }

    if (self.spawnflags & 1)
    {
        self.model      = "progs/w_s_key.mdl";
        self.netname    = "Skull Key";
        self.items2     = IT2_KEY1;
    }
    else if (self.spawnflags & 2)
    {
        self.model      = "progs/w_g_key.mdl";
        self.netname    = "Eye Key";
        self.items2     = IT2_KEY2;
    }
    else if (self.spawnflags & 4)
    {
        self.model      = "progs/m_s_key.mdl";
        self.netname    = "Fire Key";
        self.items2     = IT2_KEY3;
    }
    else if (self.spawnflags & 8)
    {
        self.model      = "progs/m_g_key.mdl";
        self.netname    = "Dagger Key";
        self.items2     = IT2_KEY4;
    }
    else if (self.spawnflags & 16)
    {
        self.model      = "progs/b_s_key.mdl";
        self.netname    = "Spider Key";
        self.items2     = IT2_KEY5;
    }
    else if (self.spawnflags & 32)
    {
        self.model      = "progs/b_g_key.mdl";
        self.netname    = "Moon Key";
        self.items2     = IT2_KEY6;
    }

    precache_model (self.model);
    setmodel (self, self.model);
    setsize (self, '-16 -16 -24', '16 16 32');

    self.noise  = "items/pickkey.wav";
    precache_sound (self.noise);

    self.touch  = key_touch;
    StartItem ();
};

// Skull Key
void() item_key1 = { self.spawnflags = 1; item_key (); };

// Eye Key
void() item_key2 = { self.spawnflags = 2; item_key (); };

// Fire Key
void() item_key3 = { self.spawnflags = 4; item_key (); };

// Dagger Key
void() item_key4 = { self.spawnflags = 8; item_key (); };

// Spider Key
void() item_key5 = { self.spawnflags = 16; item_key (); };

// Moon Key
void() item_key6 = { self.spawnflags = 32; item_key (); };


/*
===============================================================================

POWERUPS

===============================================================================
*/

// Doctor's Bag
void() item_artifact_bag =
{
    self.netname = "Doctor's Bag";
    self.model   = "models/items/i_docbag.md3";
    item_powerup ();
    setsize (self, '-7 -11 -1', '7 11 19');
};

// Boots of Jumping
void() item_artifact_boots =
{
    precache_sound ("bludbath/powerup.wav");

    self.netname = "Boots of Jumping";
    self.model   = "models/items/i_boots.md3";
    item_powerup ();
    setsize (self, '-11 -10 -1', '4 10 19');
};

// Crystal Ball
void() item_artifact_crystal =
{
    precache_sound ("bludbath/powerup.wav");

    self.netname = "Crystal Ball";
    self.model   = "models/items/i_crystal.md3";
    item_powerup ();
    setsize (self, '-7 -7 -1', '7 7 14');
};

// Diving Suit
void() item_artifact_envirosuit =
{
    precache_sound ("foley/swimuw.wav"); // diving suit engage sound

    self.netname = "Diving Suit";
    self.model   = "models/items/i_diving.md3";
    item_powerup ();
    setsize (self, '-9 -13 -3', '8 13 74');
};

// Cloak of Invisibility
void() item_artifact_invisibility =
{
    self.items = IT_INVISIBILITY;

    self.netname = "Cloak of Invisibility";
    self.model   = "models/items/i_invisible.md3";
    self.noise   = "bludbath/powerup.wav";
    item_powerup ();
    setsize (self, '-16 -16 -2', '16 16 54');

    // Set animation loop
    self.anim_len = 11;  // 11 frames in the animation
    self.think1 = SUB_AutoAnimation;
};

// Death Mask
void() item_artifact_invulnerability =
{
    self.effects = self.effects | EF_RED;
    self.items = IT_INVULNERABILITY;

    self.netname = "Death mask";
    self.model   = "models/items/i_mask.md3";
    self.noise   = "bludbath/powerup.wav";
    item_powerup ();
    setsize (self, '-4 -12 0', '2 12 30');
};

// Reflective Shots
void() item_artifact_reflect =
{
    self.effects = self.effects | EF_BLUE;

    self.netname = "Reflective Shots";
    self.model   = "models/items/i_reflect.md3";
    self.noise   = "bludbath/powerup.wav";
    item_powerup ();
    setsize (self, '-7 -7 0', '7 11 16');

    // Set animation loop
    self.anim_len = 6;  // 6 frames in the animation
    self.think1 = SUB_AutoAnimation;
};

// Guns Akimbo
void() item_artifact_super_damage =
{
    self.netname = "Guns Akimbo";
    self.model   = "models/items/i_akimbo.md3";
    self.noise   = "bludbath/powerup.wav";
    item_powerup ();
    setsize (self, '-16 -16 -2', '16 16 54');
};

// Beast Vision
void() item_artifact_vision =
{
    precache_sound ("bludbath/powerup.wav");

    self.netname = "Beast Vision";
    self.model   = "models/items/i_vision.md3";
    item_powerup ();
    setsize (self, '-10 -9 0', '11 9 9');
};
