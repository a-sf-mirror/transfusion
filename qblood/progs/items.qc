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
};



/*QUAKED noclass (0 0 0) (-8 -8 -8) (8 8 8)
prints a warning message when spawned
*/
void() noclass =
{
    dprint ("noclass spawned at");
    dprint (vtos(self.origin));
    dprint ("\n");
    remove (self);
};

void() q_touch =
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

    Bprint (PRINT_LOW, other.netname);
    Bprint (PRINT_LOW, " picked up a guns akimbo with ");
    Bprint (PRINT_LOW, s);
    Bprint (PRINT_LOW, " seconds remaining!\n");

    activator = other;
    SUB_UseTargets();                               // fire all targets / killtargets
};

void(float timeleft) DropQuad =
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
    setmodel (item, "progs/quaddama.mdl");
    setsize (item, '-16 -7 -2', '18 7 18');
    item.touch = q_touch;
    item.nextthink = time + timeleft;    // remove it with the time left on it
    item.think = SUB_Remove;
};

void() r_touch =
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
    Bprint (PRINT_LOW, other.netname);
    Bprint (PRINT_LOW, " picked up a cloak with ");
    Bprint (PRINT_LOW, s);
    Bprint (PRINT_LOW, " seconds remaining!\n");


    activator = other;
    SUB_UseTargets();                               // fire all targets / killtargets
};

void(float timeleft) DropRing =
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
    item.touch = r_touch;
    item.nextthink = time + timeleft;    // remove after 30 seconds
    item.think = SUB_Remove;
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
    self.origin_z = self.origin_z + 6;
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
============
lure_touch

Touch function for a proxy item (see below)

For test purpose only
============
*/
void() lure_touch =
{
    if (!(other.flags & FL_CLIENT))
        return;

    self.solid = SOLID_NOT;
    self.model = string_null;
    self.nextthink = time + 20;
    self.think = SUB_regen;

    Sprint (other, PRINT_LOW, "Picked up a LURE\n");
    sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
    stuffcmd (other, "bf\n");  // produces a little flash on the interface when you picked up the item
};

/*
============
item_lure

Proxy item. Used by mappers when a spawn function for an item doesn't yet exist

For test purpose only
============
*/
void() item_lure =
{
    // set pickup sound if it wasn't already done
    if (self.noise == "" || self.noise == string_null)
        self.noise = "items/pickup.wav";

    self.touch = lure_touch;

    precache_model (self.model);
    setmodel (self, self.model);
    precache_sound (self.noise);

    setsize (self, '0 0 0', '32 32 32');
    StartItem ();
};


/*
==========================================================

MISCELLANEOUS OBJECTS

==========================================================
*/

// misc. objects that exist in maps as decorations. some are breakable


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
    self.origin_z = self.origin_z + 6;
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

    // If there's no spawn flag, make the object static
    // (changes or interactions are then impossible, but as a consequence
    // the object has virtually no cost from the server point of view)
    if (!self.spawnflags)
        makestatic (self);
    else
        self.touch = SUB_SolidTouch;
};

/*
============
StartObject

Sets the clipping size and plants the object on the floor
============
*/
void() StartObject =
{
    self.nextthink = time + 0.2;    // objects start after other solids, but before items
    self.think = PlaceObject;
};


// small tome or book, closed
void() obj_tome =
{
    precache_model("progs/a_tome.mdl");
    setmodel(self, "progs/a_tome.mdl");

    setsize (self, '-10 -4 -10', '10 4 11');
    StartObject ();
};

// small potion vial
void() obj_boost =
{
    precache_model("progs/a_boost.mdl");
    setmodel(self, "progs/a_boost.mdl");

    setsize (self, '-5 -6 -9', '5 6 10');
    StartObject ();
};

// large potion goblet

void() obj_mboost =
{
    precache_model("progs/a_mboost.mdl");
    setmodel(self, "progs/a_mboost.mdl");

    setsize (self, '-9 -10 -9', '9 10 10');
    StartObject ();
};

// Huge Statue of Praying Angel
void() obj_anglstat =
{
    precache_model("progs/anglstat.mdl");
    setmodel(self, "progs/anglstat.mdl");

    setsize (self, '-50 -30 0', '44 29 132');
    StartObject ();
};

// a slab of beef, found in restaraunt freezers
void() obj_beefslab =
{
    precache_model("progs/beefslab.mdl");
    setmodel(self, "progs/beefslab.mdl");

    setsize (self, '-14 -14 1', '22 14 89');
    StartObject ();
};

// pile of bones
void() obj_bonepile =
{
    precache_model("progs/bonepile.mdl");
    setmodel(self, "progs/bonepile.mdl");

    setsize (self, '-16 -15 -3', '16 16 14');
    StartObject ();
};

// another book, closed
void() obj_bookclos =
{
    precache_model("progs/bookclos.mdl");
    setmodel(self, "progs/bookclos.mdl");

    setsize (self, '-9 -7 -1', '9 7 6');
    StartObject ();
};

// another book, open
void() obj_bookopen =
{
    precache_model("progs/bookopen.mdl");
    setmodel(self, "progs/bookopen.mdl");

    setsize (self, '-8 -14 -1', '9 14 5');
    StartObject ();
};

// small bush
void() obj_bush1 =
{
    precache_model("progs/bush1.mdl");
    setmodel(self, "progs/bush1.mdl");

    setsize (self, '-31 -34 -1', '31 32 39');
    StartObject ();
};

// chrome flaming torch
void() obj_cflmtrch =
{
    precache_model("progs/cflmtrch.mdl");
    setmodel(self, "progs/cflmtrch.mdl");

    setsize (self, '-9 -6 -29', '8 6 27');
    FireAmbient ();
    StartObject ();
};

// Locked chest
void() obj_chest1 =
{
    precache_model("progs/chest1.mdl");
    setmodel(self, "progs/chest1.mdl");

    setsize (self, '-12 -16 -1', '13 16 23');
    StartObject ();
};

// Rounded chest
void() obj_chest2 =
{
    precache_model("progs/chest2.mdl");
    setmodel(self, "progs/chest2.mdl");

    setsize (self, '-12 -15 0', '12 17 25');
    StartObject ();
};

// Squared chest
void() obj_chest3 =
{
    precache_model("progs/chest3.mdl");
    setmodel(self, "progs/chest3.mdl");

    setsize (self, '-12 -16 -1', '12 16 22');
    StartObject ();
};

// Nice book
void() obj_clueb =
{
    precache_model("progs/clueb.mdl");
    setmodel(self, "progs/clueb.mdl");

    setsize (self, '-8 -11 -11', '7 11 12');
    StartObject ();
};

// Corpse, Face up
void() obj_corps2 =
{
    precache_model("progs/corps2.mdl");
    setmodel(self, "progs/corps2.mdl");

    setsize (self, '-2 -2 -2', '2 2 2'); //modifed so JoeV can better place
    StartObject ();
};

// a rusty metal cross with a tilted cross beam
void() obj_cross =
{
    precache_model("progs/cross.mdl");
    setmodel(self, "progs/cross.mdl");

    setsize (self, '-3 -12 -19', '3 12 21');
    StartObject ();
};

// Chrome Skeleton Key
void() obj_cskey =
{
    precache_model("progs/cskey.mdl");
    setmodel(self, "progs/cskey.mdl");

    setsize (self, '-1 -4 -12', '1 3 12');
    StartObject ();
};

// an egyptian looking torch
void() obj_eflmtrch =
{
    precache_model("progs/eflmtrch.mdl");
    setmodel(self, "progs/eflmtrch.mdl");

    setsize (self, '-12 -5 -21', '14 5 34');
    FireAmbient ();
    StartObject ();
};

// egytpian torch, unlit
void() obj_egtorch =
{
    precache_model("progs/egtorch.mdl");
    setmodel(self, "progs/egtorch.mdl");

    setsize (self, '-12 -5 -21', '12 5 9');
    StartObject ();
};

// Iron Fence Gateway
void() obj_fence =
{
    precache_model("progs/fence.mdl");
    setmodel(self, "progs/fence.mdl");

    setsize (self, '-3 -25 0', '3 29 53');
    StartObject ();
};

// large 2 tier fountain
void() obj_fountain =
{
    precache_model("progs/fountain.mdl");
    setmodel(self, "progs/fountain.mdl");

    setsize (self, '-31 -27 -1', '31 27 95');
    // TODO: Water sound here?
    StartObject ();
};

// Soccer Goal
void() obj_goal =
{
    precache_model ("progs/goalpost.mdl");
    setmodel (self, "progs/goalpost.mdl");

    setsize (self, '-51 -65 -3', '55 65 111');
    StartObject ();
};

// Head of Fallen Angel
void() obj_hfangel =
{
    precache_model("progs/h_fangel.mdl");
    setmodel(self, "progs/h_fangel.mdl");

    setsize (self, '-9 -3 0', '5 3 14');
    StartObject ();
};

// tall triangular hedge
void() obj_hedge1 =
{
    precache_model("progs/hedge1.mdl");
    setmodel(self, "progs/hedge1.mdl");

    setsize (self, '-27 -27 -1', '26 26 92');
    StartObject ();
};

// tall square hedge
void() obj_hedge2 =
{
    precache_model("progs/hedge2.mdl");
    setmodel(self, "progs/hedge2.mdl");

    setsize (self, '-19 -28 0', '18 29 89');
    StartObject ();
};

// tall rounded hedge
void() obj_hedge3 =
{
    precache_model("progs/hedge3.mdl");
    setmodel(self, "progs/hedge3.mdl");

    setsize (self, '-27 -27 -1', '27 27 127');
    StartObject ();
};

// cross with fluer de lis
void() obj_holycrss =
{
    precache_model("progs/holycrss.mdl");
    setmodel(self, "progs/holycrss.mdl");

    setsize (self, '-6 -13 -19', '6 13 21');
    StartObject ();
};

// Huge Moving Spider Web
void() obj_megaweb =
{
    precache_model("progs/megaweb.mdl");
    setmodel(self, "progs/megaweb.mdl");

    setsize (self, '-1 -339 -411', '51 336 387');
    StartObject ();
};

// small plant
void() obj_plantgen =
{
    precache_model("progs/plantgen.mdl");
    setmodel(self, "progs/plantgen.mdl");

    setsize (self, '-30 -29 -1', '29 30 30');
    StartObject ();
};

// potted plant
void() obj_plantmez =
{
    precache_model("progs/plantmez.mdl");
    setmodel(self, "progs/plantmez.mdl");

    setsize (self, '-30 -29 -1', '29 30 39');
    StartObject ();
};

// plant in vase
void() obj_plantrom =
{
    precache_model("progs/plantrom.mdl");
    setmodel(self, "progs/plantrom.mdl");

    setsize (self, '-39 -38 -1', '39 39 95');
    StartObject ();
};

// large 2 handled jug, 4 skins
void() obj_pot1 =
{
    precache_model("progs/pot1.mdl");
    setmodel(self, "progs/pot1.mdl");

    setsize (self, '-19 -32 -1', '19 32 58');
    StartObject ();
};

// large vase, 4 skins
void() obj_pot2 =
{
    precache_model("progs/pot2.mdl");
    setmodel(self, "progs/pot2.mdl");

    setsize (self, '-12 -14 0', '12 14 42');
    StartObject ();
};

// large vase, 4 skins
void() obj_pot3 =
{
    precache_model("progs/pot3.mdl");
    setmodel(self, "progs/pot3.mdl");

    setsize (self, '-17 -19 -1', '17 20 48');
    StartObject ();
};

// roman style flaming torch
void() obj_rflmtrch =
{
    precache_model("progs/rflmtrch.mdl");
    setmodel(self, "progs/rflmtrch.mdl");

    setsize (self, '-10 -10 -15', '2 10 27');
    FireAmbient ();
    StartObject ();
};

// seaweed
void() obj_seaweed =
{
    precache_model("progs/seaweed.mdl");
    setmodel(self, "progs/seaweed.mdl");

    setsize (self, '-4 -5 0', '4 5 72');
    StartObject ();
};

// 1 skull on a stick
void() obj_skllstk1 =
{
    precache_model("progs/skllstk1.mdl");
    setmodel(self, "progs/skllstk1.mdl");

    setsize (self, '-5 -5 -1', '5 3 55');
    StartObject ();
};

// 2 skulls on a stick
void() obj_skllstk2 =
{
    precache_model("progs/skllstk2.mdl");
    setmodel(self, "progs/skllstk2.mdl");

    setsize (self, '-5 -2 -1', '6 8 57');
    StartObject ();
};

//  cross tombstone
void() obj_tombstn1 =
{
    precache_model("progs/tombstn1.mdl");
    setmodel(self, "progs/tombstn1.mdl");

    setsize (self, '-8 -25 -1', '8 25 72');
    StartObject ();
};

// oval tombstone
void() obj_tombstn2 =
{
    precache_model("progs/tombstn2.mdl");
    setmodel(self, "progs/tombstn2.mdl");

    setsize (self, '-5 -16 -1', '5 16 44');
    StartObject ();
};

// R. I. P. tombstone
void() obj_tombstn3 =
{
    precache_model("progs/tombstn3.mdl");
    setmodel(self, "progs/tombstn3.mdl");

    setsize (self, '-7 -19 -1', '7 18 48');
    StartObject ();
};

// dead tree
void() obj_tree =
{
    precache_model("progs/tree.mdl");
    setmodel(self, "progs/tree.mdl");

    setsize (self, '-44 -74 0', '89 45 208');
    StartObject ();
};

// leafy tree
void() obj_tree2 =
{
    precache_model("progs/tree2.mdl");
    setmodel(self, "progs/tree2.mdl");

    setsize (self, '-138 -131 -20', '118 106 224');
    StartObject ();
};

// small spider webs
// TODO: Accept a spawn flag differentiating between the skins
void() obj_webs =
{
    precache_model("progs/webs.mdl");
    setmodel(self, "progs/webs.mdl");

    // set skin ...
    setsize (self, '-1 -23 -28', '4 23 26');
    StartObject ();
};

// Brown skull
void() obj_skull =
{
    precache_model("progs/skull.mdl");
    setmodel(self, "progs/skull.mdl");

    setsize (self, '-6 -4 0', '6 4 11');
    StartObject ();
};

// book with skull on it
void() obj_skulbook =
{
    precache_model("progs/skulbook.mdl");
    setmodel(self, "progs/skulbook.mdl");

    setsize (self, '-7 -6 -1', '7 6 2');
    StartObject ();
};

// bar stool
void() obj_stool =
{
    precache_model("progs/stool.mdl");
    setmodel(self, "progs/stool.mdl");

    setsize (self, '-7 -7 0', '7 7 18');
    StartObject ();
};

// another scroll
void() obj_hbook =
{
    precache_model("progs/h-book.mdl");
    setmodel(self, "progs/h-book.mdl");

    setsize (self, '-5 -9 -13', '5 9 14');
    StartObject ();
};

// White skull
void() obj_m2 =
{
    precache_model("progs/m2.mdl");
    setmodel(self, "progs/m2.mdl");

    setsize (self, '-12 -8 -11', '12 8 11');
    StartObject ();
};

// Green skull
void() obj_m3 =
{
    precache_model("progs/m3.mdl");
    setmodel(self, "progs/m3.mdl");

    setsize (self, '-12 -8 -11', '12 8 11');
    StartObject ();
};

// another book
void() obj_mage =
{
    precache_model("progs/mage.mdl");
    setmodel(self, "progs/mage.mdl");

    setsize (self, '-8 -11 -11', '7 11 12');
    StartObject ();
};

// shovel
void() obj_shovel =
{
    precache_model("progs/shovl.mdl");
    setmodel(self, "progs/shovl.mdl");

    setsize (self, '-3 -7 -26', '3 7 27');
    StartObject ();
};

// a boiling cauldron
void() obj_cauldron =
{
    precache_model("progs/cauldron.mdl");
    setmodel(self, "progs/cauldron.mdl");

    setsize (self, '-32 -21 0', '24 20 34');
    StartObject ();
};

// barrels -
//skin0 = tnt (don't use), skin1 = wine barrel,
//skin2 = zombie head barrel, skin3 = "waste" barrel
void() obj_barrel =
{
    precache_model("progs/barrel.mdl");
    setmodel(self, "progs/barrel.mdl");

    setsize (self, '-14 -20 -14', '14 20 39');
    StartObject ();
};

// jar with a brain in it
// skin0 is green fluid
//skin1 is red fluid
void() obj_brainjar =
{
    precache_model("progs/jar.mdl");
    setmodel(self, "progs/jar.mdl");

    setsize (self, '-11 -7 -1', '14 8 28');
    StartObject ();
};

// drum-type barrell
// skin0 is zombie head with blood,  "Caution Toxic Waste"
// skin1 is green slime, "Caution - Toxic"
void() obj_drum =
{
    precache_model("progs/drum.mdl");
    setmodel(self, "progs/drum.mdl");
    
    setsize (self, '-14 -14 -1', '14 14 36');
    StartObject ();
};


/*
===================================

POWERUPS

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
        if (InvenMax (other, S_FIRST_AID))
            return;
        InvenSet (other, S_FIRST_AID, 100);
    }
    else if (self.classname == "item_artifact_boots")
    {
        if (InvenMax (other, S_JUMP_BOOTS))
            return;
        InvenSet (other, S_JUMP_BOOTS, 100);
    }
    else if (self.classname == "item_artifact_crystal")
    {
        if (InvenMax (other, S_CRYSTAL_BALL))
            return;
        InvenSet (other, S_CRYSTAL_BALL, 100);
    }
    else if (self.classname == "item_artifact_envirosuit")
    {
        if (InvenMax (other, S_DIVING_SUIT))
            return;
        InvenSet (other, S_DIVING_SUIT, 100);
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
        if (InvenMax (other, S_BEAST_VISION))
            return;
        InvenSet (other, S_BEAST_VISION, 100);
    }

    Sprint (other, PRINT_LOW, "Picked up ");
    Sprint (other, PRINT_LOW,  self.netname);
    Sprint (other, PRINT_LOW, "\n");

    self.mdl = self.model;
    if ((self.classname == "item_artifact_invulnerability") ||
        (self.classname == "item_artifact_invisibility"))
        self.nextthink = time + 60*5;
    else
        self.nextthink = time + 60;
    self.think = SUB_regen;

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
    if (self.noise == "" || self.noise == string_null)
        self.noise = "items/pickup.wav";

    self.touch = powerup_touch;

    precache_model (self.model);
    precache_sound (self.noise);
    setmodel (self, self.model);

    StartItem ();
};

//various powerups that aren't in other sections already

// Doctor's Bag
void() item_artifact_bag =
{
    self.netname = "Doctor's Bag";
    self.model   = "progs/i_docbag.mdl";
    self.noise   = "items/pickup.wav";
    setsize (self, '-7 -11 -1', '7 11 19');
    item_powerup ();
};

// Boots of Jumping
void() item_artifact_boots =
{
    self.netname = "Boots of Jumping";
    self.model   = "progs/i_boots.mdl";
    self.noise   = "items/pickup.wav";
    setsize (self, '-11 -10 -1', '4 10 19');
    item_powerup ();
};

// Crystal Ball
void() item_artifact_crystal =
{
    self.netname = "Crystal Ball";
    self.model   = "progs/i_crysbl.mdl";
    self.noise   = "items/pickup.wav";
    setsize (self, '-7 -7 -1', '7 7 14');
    item_powerup ();
};

// Reflective Shots
void() item_artifact_reflect =
{
    self.netname = "Reflective Shots";
    self.model   = "progs/i_reflct.mdl";
    self.noise   = "bludbath/powerup.wav";

    self.effects = self.effects | EF_BLUE;

    setsize (self, '-7 -7 0', '7 11 16');
    item_powerup ();
};

// Beast Vision
void() item_artifact_vision =
{
    self.netname = "Beast Vision";
    self.model   = "progs/i_vision.mdl";
    self.noise   = "items/pickup.wav";
    setsize (self, '-10 -9 1', '11 9 9');
    item_powerup ();
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

/*QUAKED item_health (.3 .3 1) (0 0 0) (32 32 32) rotten megahealth
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

    Sprint(other, PRINT_LOW, "Picked up ");
    s = ftos(self.healamount);
    Sprint(other, PRINT_LOW, self.netname);
    Sprint(other, PRINT_LOW, " \n");

    // health touch sound
    sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);

    stuffcmd (other, "bf\n");

    self.model = string_null;
    self.solid = SOLID_NOT;

    self.nextthink = time + 20;
    self.think = SUB_regen;

    activator = other;
    SUB_UseTargets();       // fire all targets / killtargets
};


#define H_ROTTEN    1
#define H_MEGA      2

void() item_health =
{
    self.touch = health_touch;

    if (self.spawnflags & H_ROTTEN)
    {
        precache_model("progs/i_lifess.mdl");

        precache_sound("items/pickheal.wav");
        setmodel(self, "progs/i_lifess.mdl");
        self.noise = "items/pickheal.wav";
        self.healamount = 20;   // PM:  Quake = 15
        self.netname = "Life Essence";
        self.effects = self.effects | EF_RED;
        self.healtype = 1;
    }
    else if (self.spawnflags & H_MEGA)
    {
        precache_model("progs/lifeseed.mdl");
        precache_sound("items/pickheal.wav");
        setmodel(self, "progs/lifeseed.mdl");
        self.noise = "items/pickheal.wav";
        self.healamount = 100;
        self.netname = "Life Seed";
        self.healtype = 2;
    }
    else
    {
        precache_model("progs/i_medpch.mdl");
        precache_sound("items/pickheal.wav");
        setmodel(self, "progs/i_medpch.mdl");
        self.noise = "items/pickheal.wav";
        self.healamount = 50;
        self.netname = "Medicine Patch";
        self.healtype = 1;
    }
    setsize (self, '0 0 0', '32 32 56');
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

// PM:  Use Blood's three armor/damage system.
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
    {
        Sprint(other, PRINT_MEDIUM, "Tried to pickup illegal armor.\n");
    }

    other.armorvalue = value;
    if (bit)
        other.items = other.items - (other.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + bit;

    self.solid = SOLID_NOT;
    self.model = string_null;
    self.nextthink = time + 20;
    self.think = SUB_regen;

    Sprint(other, PRINT_LOW, "Picked up ");
    Sprint(other, PRINT_LOW, self.netname);
    Sprint(other, PRINT_LOW, "\n");
    sound(other, CHAN_ITEM, "items/pickarmr.wav", 1, ATTN_NORM);
    stuffcmd (other, "bf\n");

    activator = other;
    SUB_UseTargets();               // fire all targets / killtargets
};

// Basic Armor
void() item_armor0 =
    {
    self.touch = armor_touch;
    precache_model("progs/i_arm_bs.mdl");
    setmodel(self, "progs/i_arm_bs.mdl");
    self.netname = "Basic Armor";
    //setsize (self, '-7 -18 3', '10 18 38');
    setsize (self, '-7 -18 0', '10 18 38');
    StartItem ();
    };

// Spirit Armor
void() item_armor4 =
    {
    self.touch = armor_touch;
    precache_model("progs/i_arm_sp.mdl");
    setmodel(self, "progs/i_arm_sp.mdl");
    self.netname = "Spirit Armor";

    //setsize (self, '-2 -17 2', '4 19 37');
    setsize (self, '-2 -17 0', '4 19 37');
    StartItem ();
    };

/*QUAKED item_armor1 (0 .5 .8) (-1 -18 2) (6 19 45)
*/

void() item_armor1 =
{
    self.touch = armor_touch;
    precache_model ("progs/i_arm_bd.mdl");
    setmodel (self, "progs/i_arm_bd.mdl");
    self.netname = "Body Armor";

    setsize (self, '-1 -18 0', '6 19 45');
    StartItem ();
};

/*QUAKED item_armor2 (0 .5 .8) (-7 -12 8) (7 10 37)
*/

void() item_armor2 =
{
    self.touch = armor_touch;
    precache_model ("progs/i_arm_fr.mdl");
    setmodel (self, "progs/i_arm_fr.mdl");
    self.netname = "Fire Armor";

    setsize (self, '-7 -12 0', '7 10 37');
    StartItem ();
};

/*QUAKED item_armorInv (0 .5 .8) (-12 -17 2) (12 19 42)
*/

void() item_armorInv =
{
    self.touch = armor_touch;
    precache_model ("progs/i_arm_su.mdl");
    setmodel (self, "progs/i_arm_su.mdl");
    self.netname = "Super Armor";

    setsize (self, '-12 -17 0', '12 19 42');
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

    Sprint (other, PRINT_LOW, "Picked up ");
    Sprint (other, PRINT_LOW, self.netname);
    Sprint (other, PRINT_LOW, "\n");

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

    activator = other;
    SUB_UseTargets();               // fire all targets / killtargets
};


/*QUAKED weapon_flaregun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_flaregun =
{
    precache_model ("progs/v_shot.mdl");
    precache_model ("progs/g_flare.mdl");
    precache_model ("progs/v_aflare.mdl");  // akimbo model

    setmodel (self, "progs/g_flare.mdl");
    self.weapon = IT_FLAREGUN;
    self.netname = "Flare Gun";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // precache the necessary sounds
    PsychoCaleb_Precache ();
    precache_sound ("weapons/flaregun/flaref.wav");
    precache_sound ("weapons/napalm/explodfs.wav");  // For alt-flares

    StartItem ();
};

/*QUAKED weapon_supershotgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_supershotgun =
{
    precache_model ("progs/v_shot2.mdl");
    precache_model ("progs/g_shot.mdl");
    precache_model ("progs/shotshl.mdl");   // shotgun shell
    precache_model ("progs/v_ashot2.mdl");  // akimbo model

    setmodel (self, "progs/g_shot.mdl");
    self.weapon = IT_SAWED_OFF;
    self.netname = "Sawed-off";
    self.touch = weapon_touch;
    setsize (self, '-19 -4 0', '17 4 14');

    // Precache the necessary sounds
    precache_sound ("weapons/shotgun/shotcock.wav");  // shell ejection
    precache_sound ("weapons/shotgun/shotfir2.wav");  // shotgun alt-fire
    precache_sound ("weapons/shotgun/shotfire.wav");  // shotgun fired
    precache_sound ("weapons/shotgun/shotload.wav");  // reload sound
    precache_sound ("weapons/shtshl2.wav");  // shell hitting ground

    StartItem ();
};

/*QUAKED weapon_nailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_nailgun =
{
    precache_model ("progs/v_nail.mdl");
    precache_model ("progs/v_anail.mdl");  // akimbo model
    precache_model ("progs/g_nail.mdl");
    precache_model ("progs/tommyshl.mdl");  // tommy gun shell

    setmodel (self, "progs/g_nail.mdl");
    self.weapon = IT_TOMMYGUN;
    self.netname = "Tommy Gun";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // Precache the necessary sounds
    precache_sound ("weapons/tommygun/_tom.wav");     // Fire
    precache_sound ("weapons/tommygun/tomcock.wav");  // Out of bullet noise
    precache_sound ("weapons/shtshl.wav");            // shell hitting ground
    precache_sound ("weapons/shtshl3.wav");           // shell hitting ground (2nd)

    StartItem ();
};

/*QUAKED weapon_supernailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_supernailgun =
{
    precache_model ("progs/v_nail2.mdl");
    precache_model ("progs/g_nail2.mdl");
    precache_model ("progs/grd_aero.mdl");

    setmodel (self, "progs/g_nail2.mdl");
    self.weapon = IT_SPRAY_CAN;
    self.netname = "Spray Can";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // Precache the necessary sounds
//    precache_sound ("weapons/spraycan/burstflm.wav");
    precache_sound ("weapons/spraycan/spraycan.wav");  // lighted spray can
    precache_sound ("weapons/spraycan/sprayfir.wav");  // fire
    precache_sound ("weapons/tnt/lighter.wav");  // = zipopen.wav + ziplight.wav
    precache_sound ("weapons/tnt/zipclose.wav");

    precache_model ("progs/sprayfir.spr");

    StartItem ();
};

/*QUAKED weapon_grenadelauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_grenadelauncher =
{
    precache_model ("progs/v_rock.mdl");
    precache_model ("progs/g_rock.mdl");
    precache_model ("progs/grd_bund.mdl");

    setmodel (self, "progs/g_rock.mdl");
    self.weapon = IT_TNT;
    self.netname = "Dynamite";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // Precache the necessary sounds
    PsychoCaleb_Precache ();
    precache_sound ("weapons/tnt/lighter.wav");  // = zipopen.wav + ziplight.wav
    precache_sound ("weapons/tnt/tntfuse.wav");  // tnt lit
    precache_sound ("weapons/tnt/tnttoss.wav");  // throw sound
    precache_sound ("weapons/tnt/zipclose.wav");

    StartItem ();
};

// FIXME: weapon_grenadelauncher & item_tnt have a lot of
//        things in common. We should merge them in some way

//  TNT Bundle model
void() item_tnt =
{
    precache_model ("progs/v_rock.mdl");
    precache_model ("progs/i_tnt.mdl");
    precache_model ("progs/grd_bund.mdl");

    setmodel (self, "progs/i_tnt.mdl");
    self.weapon = IT_TNT;
    self.netname = "Dynamite";
    self.touch = weapon_touch;
    setsize (self, '0 0 0', '32 32 32');

    // Precache the necessary sounds
    PsychoCaleb_Precache ();
    precache_sound ("weapons/tnt/lighter.wav");  // = zipopen.wav + ziplight.wav
    precache_sound ("weapons/tnt/tntfuse.wav");  // tnt lit
    precache_sound ("weapons/tnt/tnttoss.wav");  // throw sound
    precache_sound ("weapons/tnt/zipclose.wav");

    StartItem ();
};


// Proximity grenade
void() weapon_proximity =
{
    precache_model ("progs/v_proxy.mdl");
    precache_model ("progs/g_proxy.mdl");
    precache_model ("progs/grd_prox.mdl");

    setmodel (self, "progs/g_proxy.mdl");
    self.weapon = IT_PROXIMITY_BOMB;
    self.netname = "Proximity Bomb";
    self.touch = weapon_touch;
    setsize (self, '0 0 0', '32 32 32');

    // Precache the necessary sounds
    PsychoCaleb_Precache ();
    precache_sound ("weapons/tnt/proxarm.wav");  // proximity bomb armed
    precache_sound ("weapons/tnt/proxdet.wav");  // proximity bomb triggered
    precache_sound ("weapons/tnt/tnttoss.wav");  // throw sound

    StartItem ();
};

// Remote Detonator model
void() weapon_remote =
{
    precache_model ("progs/v_remote.mdl");
    precache_model ("progs/g_remote.mdl");
    precache_model ("progs/grd_remo.mdl");

    setmodel (self, "progs/g_remote.mdl");
    self.weapon = IT_REMOTE_DETONATOR;
    self.netname = "Remote Detonator";
    self.touch = weapon_touch;
    setsize (self, '0 0 0', '32 32 32');

    // Precache the necessary sounds
    PsychoCaleb_Precache ();
    precache_sound ("weapons/tnt/remfire.wav");  // remote triggered
    precache_sound ("weapons/tnt/tnttoss.wav");  // throw sound

    StartItem ();
};

/*QUAKED weapon_rocketlauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_rocketlauncher =
{
    precache_model ("progs/v_rock2.mdl");
    precache_model ("progs/g_rock2.mdl");
    precache_model ("progs/v_arock2.mdl");

    setmodel (self, "progs/g_rock2.mdl");
    self.weapon = IT_NAPALM_LAUNCHER;
    self.netname = "Napalm Launcher";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    precache_model ("progs/missile.mdl");  // napalm regular fire
    precache_model ("progs/naltball.mdl"); // napalm alt fire model

    // Precache the necessary sounds
    PsychoCaleb_Precache ();
    precache_sound ("weapons/napalm/blaster.wav");  // Shot

    StartItem ();
};


/*QUAKED weapon_lightning (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_lightning =
{
    precache_model ("progs/v_light.mdl");
    precache_model ("progs/g_light.mdl");
    precache_model ("progs/v_alight.mdl");  // Akimbo model
    precache_model ("progs/bolt.mdl");
    precache_model ("progs/bolt2.mdl");

    setmodel (self, "progs/g_light.mdl");
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

    StartItem ();
};


/*QUAKED weapon_voodoodoll (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_voodoodoll =
{
    precache_model ("progs/v_voodoo.mdl");
    precache_model ("progs/g_voodoo.mdl");

    setmodel (self, "progs/g_voodoo.mdl");
    self.weapon = IT_VOODOO_DOLL;
    self.netname = "Voodoo Doll";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // Precache the necessary sounds
    precache_sound ("weapons/voodoodl/voolaugh.wav");
    precache_sound ("weapons/voodoodl/voostab.wav");
    precache_sound ("weapons/voodoodl/voochant.wav");

    StartItem ();
};

/*QUAKED weapon_lifeleech (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_lifeleech =
{
    precache_model ("progs/g_leech.mdl");
    precache_model ("progs/v_leech.mdl");
    precache_model ("progs/bolt.mdl");

    setmodel (self, "progs/g_leech.mdl");
    self.weapon = IT_LIFE_LEECH;
    self.netname = "Life Leech";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // precache the necessary sounds
    precache_sound ("weapons/lifelech/laltfr1.wav");
    precache_sound ("weapons/lifelech/llaltht.wav");    // LL sentry destroyed
    precache_sound ("weapons/napalm/explodfs.wav");     // altfire missile touch
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
    // leech life
    else if (self.weapon == 11)
    {
        if (other.ammo_leech >= MAX_LEECH)
            return;
        other.ammo_leech = other.ammo_leech + self.aflag;
    }

    bound_other_ammo ();

    Sprint (other, PRINT_LOW, "Picked up ");
    Sprint (other, PRINT_LOW, self.netname);
    Sprint (other, PRINT_LOW, "\n");

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

    activator = other;
    SUB_UseTargets();               // fire all targets / killtargets
};


#define AMMO_BIG 1

/*QUAKED item_shells (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_shells =
{
    self.touch = ammo_touch;

    if (self.spawnflags & AMMO_BIG)
    {
        precache_model ("progs/i_boxshl.mdl");
        setmodel (self, "progs/i_boxshl.mdl");
        self.netname = "box of shotgun shells";
        self.aflag = 15;
    }
    else
    {
        precache_model ("progs/i_fewshl.mdl");
        setmodel (self, "progs/i_fewshl.mdl");
        self.netname = "4 shotgun shells";
        self.aflag = 4;
    }
    self.weapon = 1;
    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
};

/*QUAKED item_flares (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_flares =
{
    self.touch = ammo_touch;

    precache_model ("progs/i_flares.mdl");
    setmodel (self, "progs/i_flares.mdl");

    self.netname = "box of flares";
    self.aflag = 8;
    self.weapon = 5;

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
};

/*QUAKED item_spikes (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_spikes =
{
    self.touch = ammo_touch;

    if (self.spawnflags & AMMO_BIG)
    {
        precache_model ("progs/i_drum.mdl");
        setmodel (self, "progs/i_drum.mdl");
        self.netname = "full drum of bullets";
        self.aflag = 100;
    }
    else
    {
        precache_model ("progs/i_fewblt.mdl");
        setmodel (self, "progs/i_fewblt.mdl");
        self.netname = "a few bullets";
        self.aflag = 15;
    }
    self.weapon = 2;
    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
};

/*QUAKED item_rockets (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_rockets =
{
    self.touch = ammo_touch;

    if (self.spawnflags & AMMO_BIG)
    {
        precache_model ("progs/i_gascan.mdl");
        setmodel (self, "progs/i_gascan.mdl");
        self.aflag = 6;
    }
    else
    {
        precache_model ("progs/i_gascan.mdl");
        setmodel (self, "progs/i_gascan.mdl");
        self.aflag = 6;
    }
    self.weapon = 3;
    self.netname = "gasoline cans";
    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
};


/*QUAKED item_cells (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_cells =
{
    self.touch = ammo_touch;

    if (self.spawnflags & AMMO_BIG)
    {
        precache_model ("progs/i_teschg.mdl");
        setmodel (self, "progs/i_teschg.mdl");
        self.aflag = 32;
    }
    else
    {
        precache_model ("progs/i_teschg.mdl");
        setmodel (self, "progs/i_teschg.mdl");
        self.aflag = 32;
    }
    self.weapon = 4;
    self.netname = "batteries";
    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
};


void() item_soul =
{
    self.touch = ammo_touch;

    precache_model ("progs/soul.mdl");
    setmodel (self, "progs/soul.mdl");

    self.netname = "trapped soul";
    self.aflag = 10;
    self.weapon = 11;

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
};

// Rewritten to use 'item_*' ammo boxes.
// Some levels such as dm5.bsp use this function.

/*QUAKED item_weapon (0 .5 .8) (0 0 0) (32 32 32) shotgun rocket spikes big
DO NOT USE THIS!!!! IT WILL BE REMOVED!
*/

//-------------------------------
// Spawnflags for 'item_weapon'.
//-------------------------------
#define WEAPON_SHOTGUN  1
#define WEAPON_ROCKET   2
#define WEAPON_SPIKES   4
#define WEAPON_BIG      8

void() item_weapon =
{
    local   float   osf;    // Short for original spawnflags.

    osf = self.spawnflags;

    // Change spawnflags for use with the other ammo items.
    if (self.spawnflags & WEAPON_BIG)
        self.spawnflags = AMMO_BIG;
    else
        self.spawnflags = 0;

    if (osf & WEAPON_SHOTGUN)
    {
        self.classname = "item_shells";
        item_shells ();
        return;
    }
    if (osf & WEAPON_ROCKET)
    {
        self.classname = "item_rockets";
        item_rockets ();
        return;
    }
    if (osf & WEAPON_SPIKES)
    {
        self.classname = "item_spikes";
        item_spikes ();
        return;
    }

    dprint ("Undefined ammo at: ");
    dprint (vtos(self.origin));
    dprint ("\n");
    remove (self);
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

    Sprint (other, PRINT_LOW, "Picked up ");
    Sprint (other, PRINT_LOW, self.netname);
    Sprint (other,PRINT_LOW, "\n");

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
the following keys need to exist in single player qBlood:
Skull, Eye, Fire, Dagger, Spider, Moon
*/
void() item_key =
{
    if ((self.spawnflags & 63) == 0)
    {
        // Convert to skull key.
        dprint ("No key type -- converted to skull type.\n");
        self.spawnflags = self.spawnflags | 1;
    }

    if (self.spawnflags & 32)
    {
        precache_model ("progs/b_g_key.mdl");
        setmodel (self, "progs/b_g_key.mdl");
        self.netname    = "moon key";
        self.items2     = IT2_KEY6;
    }
    else if (self.spawnflags & 16)
    {
        precache_model ("progs/b_s_key.mdl");
        setmodel (self, "progs/b_s_key.mdl");
        self.netname    = "spider key";
        self.items2     = IT2_KEY5;
    }
    else if (self.spawnflags & 8)
    {
        precache_model ("progs/m_g_key.mdl");
        setmodel (self, "progs/m_g_key.mdl");
        self.netname    = "dagger key";
        self.items2     = IT2_KEY4;
    }
    else if (self.spawnflags & 4)
    {
        precache_model ("progs/m_s_key.mdl");
        setmodel (self, "progs/m_s_key.mdl");
        self.netname    = "fire key";
        self.items2     = IT2_KEY3;
    }
    else if (self.spawnflags & 2)
    {
        precache_model ("progs/w_g_key.mdl");
        setmodel (self, "progs/w_g_key.mdl");
        self.netname    = "eye key";
        self.items2     = IT2_KEY2;
    }
    else if (self.spawnflags & 1)
    {
        precache_model ("progs/w_s_key.mdl");
        setmodel (self, "progs/w_s_key.mdl");
        self.netname    = "skull key";
        self.items2     = IT2_KEY1;
    }
    else
    {
        dprint ("No key type -- removed!\n");
        remove (self);
        return;
    }

    precache_sound ("items/pickkey.wav");
    self.noise  = "items/pickkey.wav";
    self.touch  = key_touch;
    setsize (self, '-16 -16 -24', '16 16 32');
    StartItem ();
};

/*QUAKED item_key1 (0 .5 .8) (-16 -16 -24) (16 16 32)
*/
void() item_key1 =
{
    self.spawnflags = 1;    // For compatibility with Quake maps.
    self.classname = "item_key";
    item_key ();
};
/*QUAKED item_key2 (0 .5 .8) (-16 -16 -24) (16 16 32)
*/
void() item_key2 =
{
    self.spawnflags = 2;    // For compatibility with Quake maps.
    self.classname = "item_key";
    item_key ();
};


/*
===============================================================================

END OF LEVEL RUNES

===============================================================================
*/

void() sigil_touch =
{
local entity    stemp;
local float     best;

    if (other.classname != "player")
        return;
    if (other.health <= 0)
        return;

    centerprint (other, "Picked up the rune!");

    sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
    stuffcmd (other, "bf\n");
    self.solid = SOLID_NOT;
    self.model = string_null;
    serverflags = serverflags | (self.spawnflags & 15);
    self.classname = "";        // so rune doors won't find it

    activator = other;
    SUB_UseTargets();               // fire all targets / killtargets
};


/*QUAKED item_sigil (0 .5 .8) (-16 -16 -24) (16 16 32) E1 E2 E3 E4
End of level sigil, pick up to end episode and return to jrstart.
*/

void() item_sigil =
{
    if (!self.spawnflags)
        objerror ("no spawnflags");

    precache_sound ("items/pickkey.wav");  // runekey
    self.noise = "items/pickkey.wav";

    if (self.spawnflags & 1)
    {
        precache_model ("progs/end1.mdl");
        setmodel (self, "progs/end1.mdl");
    }
    if (self.spawnflags & 2)
    {
        precache_model ("progs/end2.mdl");
        setmodel (self, "progs/end2.mdl");
    }
    if (self.spawnflags & 4)
    {
        precache_model ("progs/end3.mdl");
        setmodel (self, "progs/end3.mdl");
    }
    if (self.spawnflags & 8)
    {
        precache_model ("progs/end4.mdl");
        setmodel (self, "progs/end4.mdl");
    }

    self.touch = sigil_touch;
    setsize (self, '-16 -16 -24', '16 16 32');
    StartItem ();
};

/*
===============================================================================

POWERUPS

===============================================================================
*/


/*QUAKED item_artifact_invulnerability (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invulnerable for 30 seconds
*/
void() item_artifact_invulnerability =
{
    self.touch = powerup_touch;

    precache_model ("progs/invulner.mdl");
    precache_sound ("bludbath/powerup.wav");
    self.noise = "bludbath/powerup.wav";
    setmodel (self, "progs/invulner.mdl");
    self.netname = "Death mask";
    self.effects = self.effects | EF_RED;
    self.items = IT_INVULNERABILITY;
    setsize (self, '-4 -12 -0', '2 12 30');
    StartItem ();
};

/*QUAKED item_artifact_envirosuit (0 .5 .8) (-9 -13 -3) (8 13 74)
Player takes no damage from water or slime for 30 seconds
*/
void() item_artifact_envirosuit =
{
    self.touch = powerup_touch;

    precache_model ("progs/suit.mdl");

    precache_sound ("foley/swimuw.wav"); // diving suit engage sound
//    precache_sound ("foley/frbreath.wav");
//    precache_sound ("foley/uwbreath.wav");
    precache_sound ("items/pickup.wav");

    self.noise = "items/pickup.wav";
    setmodel (self, "progs/suit.mdl");
    self.netname = "Diving Suit";
// PM:  Diving suit/IT_SUIT controlled by inventory.
    setsize (self, '-9 -13 -3', '8 13 74');
    StartItem ();
};


/*QUAKED item_artifact_invisibility (0 .5 .8) (-3 -6 -2) (6 7 23)
Player is invisible for 30 seconds
*/
void() item_artifact_invisibility =
{
    self.touch = powerup_touch;

    precache_model ("progs/invisibl.mdl");
    precache_sound ("bludbath/powerup.wav");
    self.noise = "bludbath/powerup.wav";
    setmodel (self, "progs/invisibl.mdl");
    self.netname = "Cloak of Invisibility";
    self.items = IT_INVISIBILITY;
    setsize (self, '-3 -6 -2', '6 7 23');
    StartItem ();
};


/*QUAKED item_artifact_super_damage (0 .5 .8) (-16 -7 -2) (18 7 18)
The next attack from the player will do 4x damage
*/
void() item_artifact_super_damage =
{
    self.touch = powerup_touch;

    precache_model ("progs/quaddama.mdl");
    precache_sound ("bludbath/powerup.wav");
    self.noise = "bludbath/powerup.wav";
    setmodel (self, "progs/quaddama.mdl");

    self.netname = "Guns Akimbo";

    setsize (self, '-16 -7 -2', '18 7 18');
    StartItem ();
};
