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
    other.items = other.items | IT_QUAD;
    self.model = string_null;

// do the apropriate action
    other.super_time = 1;
    other.super_damage_finished = self.cnt;

    s=ftos(rint(other.super_damage_finished - time));

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
    setsize (item, '-16 -16 -24', '16 16 32');
    item.cnt = time + timeleft;
    item.touch = q_touch;
    item.nextthink = time + timeleft;    // remove it with the time left on it
    item.think = SUB_Remove;
};

void() r_touch =
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
    setsize (item, '-16 -16 -24', '16 16 32');
    item.cnt = time + timeleft;
    item.touch = r_touch;
    item.nextthink = time + timeleft;    // remove after 30 seconds
    item.think = SUB_Remove;
};


/*
============
PlaceItem

plants the object on the floor
============
*/
void() PlaceItem =
{
    local float oldz;

    self.mdl = self.model;      // so it can be restored on respawn
    self.flags = FL_ITEM;       // make extra wide
    self.solid = SOLID_TRIGGER;
    self.movetype = MOVETYPE_TOSS;
    self.velocity = '0 0 0';
    self.origin_z = self.origin_z + 6;
    oldz = self.origin_z;
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

Sets the clipping size and plants the object on the floor
============
*/
void() StartItem =
{
    self.nextthink = time + 0.2;    // items start after other solids
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
    self.solid = SOLID_NOT;
    self.model = string_null;
    if (deathmatch)
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
// dturner 6/30/2001

// small tome or book, closed

void() obj_tome =
    {
    precache_model("progs/a_tome.mdl");
    precache_sound("items/pickup.wav");
    setmodel(self, "progs/a_tome.mdl");
    self.noise = "items/pickup.wav";

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// small potion vial

void() obj_boost =
    {
    precache_model("progs/a_boost.mdl");
    setmodel(self, "progs/a_boost.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// large potion goblet

void() obj_mboost =
    {
    precache_model("progs/a_mboost.mdl");
    setmodel(self, "progs/a_mboost.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };


// huge statue of praying angel

void() obj_anglstat =
    {
    precache_model("progs/anglstat.mdl");
    setmodel(self, "progs/anglstat.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// a slab of beef, found in restaraunt freezers

void() obj_beefslab =
    {
    precache_model("progs/beefslab.mdl");
    setmodel(self, "progs/beefslab.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// pile of bones

void() obj_bonepile =
    {
    precache_model("progs/bonepile.mdl");
    setmodel(self, "progs/bonepile.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// another book, closed

void() obj_bookclos =
    {
    precache_model("progs/bookclos.mdl");
    setmodel(self, "progs/bookclos.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// another book, open

void() obj_bookopen =
    {
    precache_model("progs/bookopen.mdl");
    setmodel(self, "progs/bookopen.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// small bush

void() obj_bush1 =
    {
    precache_model("progs/bush1.mdl");
    setmodel(self, "progs/bush1.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// large cauldren

void() obj_cauldren =
    {
    precache_model("progs/cauldren.mdl");
    setmodel(self, "progs/cauldren.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// chrome flaming torch

void() obj_cflmtrch =
    {
    precache_model("progs/cflmtrch.mdl");
    setmodel(self, "progs/cflmtrch.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// a locked chest, with 2 skins

void() obj_chest1 =
    {
    precache_model("progs/chest1.mdl");
    setmodel(self, "progs/chest1.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// a locked chest, round, with 3 skins

void() obj_chest2 =
    {
    precache_model("progs/chest2.mdl");
    setmodel(self, "progs/chest2.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// square chest

void() obj_chest3 =
    {
    precache_model("progs/chest3.mdl");
    setmodel(self, "progs/chest3.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// corpse lying on stomach, 4 skins

void() obj_corps1 =
    {
    precache_model("progs/corps1.mdl");
    setmodel(self, "progs/corps1.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// clue book

void() obj_clueb =
    {
    precache_model("progs/clueb.mdl");
    setmodel(self, "progs/clueb.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// a corpse lying face up with 5 skins
// skin4 is encased in webs
void() obj_corps2 =
    {
    precache_model("progs/corps2.mdl");
    setmodel(self, "progs/corps2.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };


// a rusty metal cross with a tilted cross beam

void() obj_cross =
    {
    precache_model("progs/cross.mdl");
    setmodel(self, "progs/cross.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// a chrome skeleton key

void() obj_cskey =
    {
    precache_model("progs/cskey.mdl");
    setmodel(self, "progs/cskey.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// an egyptian looking torch

void() obj_eflmtrch =
    {
    precache_model("progs/eflmtrch.mdl");
    setmodel(self, "progs/eflmtrch.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// egytpian torch, unlit

void() obj_egtorch =
    {
    precache_model("progs/egtorch.mdl");
    setmodel(self, "progs/egtorch.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// iron fence gateway

void() obj_fence =
    {
    precache_model("progs/fence.mdl");
    setmodel(self, "progs/fence.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// large 2 tier fountain

void() obj_fountain =
    {
    precache_model("progs/fountain.mdl");
    setmodel(self, "progs/fountain.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// head of a fallen angel

void() obj_hfangel =
    {
    precache_model("progs/h_fangel.mdl");
    setmodel(self, "progs/h_fangel.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// tall triangular hedge

void() obj_hedge1 =
    {
    precache_model("progs/hedge1.mdl");
    setmodel(self, "progs/hedge1.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// tall square hedge

void() obj_hedge2 =
    {
    precache_model("progs/hedge2.mdl");
    setmodel(self, "progs/hedge2.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// tall rounded hedge

void() obj_hedge3 =
    {
    precache_model("progs/hedge3.mdl");
    setmodel(self, "progs/hedge3.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// cross with fluer de lis

void() obj_holycrss =
    {
    precache_model("progs/holycrss.mdl");
    setmodel(self, "progs/holycrss.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// huge moving spider web

void() obj_megaweb =
    {
    precache_model("progs/megaweb.mdl");
    setmodel(self, "progs/megaweb.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// small plant

void() obj_plantgen =
    {
    precache_model("progs/plantgen.mdl");
    setmodel(self, "progs/plantgen.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// potted plant

void() obj_plantmez =
    {
    precache_model("progs/plantmez.mdl");
    setmodel(self, "progs/plantmez.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// plant in vase

void() obj_plantrom =
    {
    precache_model("progs/plantrom.mdl");
    setmodel(self, "progs/plantrom.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// large 2 handled jug, 4 skins

void() obj_pot1 =
    {
    precache_model("progs/pot1.mdl");
    setmodel(self, "progs/pot1.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// large vase, 4 skins

void() obj_pot2 =
    {
    precache_model("progs/pot2.mdl");
    setmodel(self, "progs/pot2.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// large vase, 4 skins

void() obj_pot3 =
    {
    precache_model("progs/pot3.mdl");
    setmodel(self, "progs/pot3.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// roman style flaming torch

void() obj_rflmtrch =
    {
    precache_model("progs/rflmtrch.mdl");
    setmodel(self, "progs/rflmtrch.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// seaweed

void() obj_seaweed =
    {
    precache_model("progs/seaweed.mdl");
    setmodel(self, "progs/seaweed.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// 1 skull on a stick

void() obj_skllstk1 =
    {
    precache_model("progs/skllstk1.mdl");
    setmodel(self, "progs/skllstk1.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// 2 skulls on a stick

void() obj_skllstk2 =
    {
    precache_model("progs/skllstk2.mdl");
    setmodel(self, "progs/skllstk2.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

//  cross tombstone

void() obj_tombstn1 =
    {
    precache_model("progs/tombstn1.mdl");
    setmodel(self, "progs/tombstn1.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// oval tombstone

void() obj_tombstn2 =
    {
    precache_model("progs/tombstn2.mdl");
    setmodel(self, "progs/tombstn2.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// dead tree

void() obj_tree =
    {
    precache_model("progs/tree.mdl");
    setmodel(self, "progs/tree.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// leafy tree

void() obj_tree2 =
    {
    precache_model("progs/tree2.mdl");
    setmodel(self, "progs/tree2.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// small spider webs

void() obj_webs =
    {
    precache_model("progs/webs.mdl");
    setmodel(self, "progs/webs.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };


/*
===================================

POWERUPS

===================================
*/

//various powerups that aren't in other sections already

// Proximity grenade model
// FIXME: move to weapons when code is complete

void() weapon_proximity =
{
    self.model = "progs/g_proxy.mdl";
    self.noise = "items/weaponup.wav";
    item_lure ();
};

// Remote Detonator model
// FIXME: move to weapons when code is complete

void() weapon_remote =
{
    self.model = "progs/g_remote.mdl";
    self.noise = "items/weaponup.wav";
    item_lure ();
};

// Life Leech model
//  FIXME: move to weapons when code is complete

void() weapon_lifeleech =
{
    self.model = "progs/g_leech.mdl";
    self.noise = "items/weaponup.wav";
    item_lure ();
};

//  TNT Bundle model
//  FIXME: move to weapons when code is complete
void() item_tnt =
{
    self.model = "progs/i_tnt.mdl";
    self.noise = "items/weaponup.wav";
    item_lure ();
};

// Doctor's Bag
void() item_artifact_bag =
{
    self.model = "progs/i_docbag.mdl";
    item_lure ();
};

// Boots of Jumping
void() item_artifact_boots =
{
    self.model = "progs/i_boots.mdl";
    item_lure ();
};

// Crystal Ball
void() item_artifact_crystal =
{
    self.model = "progs/i_crysbal.mdl";
    item_lure ();
};

// Reflective Shots
void() item_artifact_reflect =
{
    self.model = "progs/i_reflct.mdl";
    item_lure ();
};

// Beast Vision
void() item_artifact_vision =
{
    self.model = "progs/i_vision.mdl";
    item_lure ();
};

// Cloak of Shadows
void() item_artifact_shadow =
{
    self.model = "progs/i_shadow.mdl";
    item_lure ();
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
float (entity e, float healamount, float ignore) T_Heal =
{
    if (e.health <= 0)
        return 0;
    if ((!ignore) && (e.health >= other.max_health))
        return 0;
    healamount = ceil(healamount);

    e.health = e.health + healamount;
    if ((!ignore) && (e.health >= other.max_health))
        e.health = other.max_health;

    if (e.health > 250)
        e.health = 250;
    return 1;
};

/*QUAKED item_health (.3 .3 1) (0 0 0) (32 32 32) rotten megahealth
Health box. Normally gives 50 points.
Rotten box heals 20 points,
megahealth will add 100 health, then
rot you down to your maximum health limit,
one point per second.
*/

#define H_ROTTEN    1
#define H_MEGA      2
.float  healamount, healtype;
void() health_touch;
void() item_megahealth_rot;

void() item_health =
{
    self.touch = health_touch;

    if (self.spawnflags & H_ROTTEN)
    {
        precache_model("progs/i_lifess.mdl");

        precache_sound("items/pickheal.wav");
        setmodel(self, "progs/i_lifess.mdl");
        self.noise = "items/pickheal.wav";
        self.healamount = 15;
        self.netname = "Life Essence"
;
        self.healtype = 1;
    }
    else if (self.spawnflags & H_MEGA)
    {
        precache_model("progs/lifeseed.mdl");
        precache_sound("items/pickup.wav");
        setmodel(self, "progs/lifeseed.mdl");
        self.noise = "items/pickup.wav";
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


void() health_touch =
{
    local   float amount;
    local   string  s;

    if (other.classname != "player")
        return;

    if (self.healtype == 2) // Megahealth?  Ignore max_health...
    {
        if (other.health >= 250)
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

    // Megahealth = rot down the player's super health
    if (self.healtype == 2)
    {
        other.items = other.items | IT_SUPERHEALTH;
        self.nextthink = time + 5;
        self.think = item_megahealth_rot;
        self.owner = other;
    }
    else if (deathmatch)
    {
        self.nextthink = time + 20;
        self.think = SUB_regen;
    }

    activator = other;
    SUB_UseTargets();               // fire all targets / killtargets
};

void() item_megahealth_rot =
{
    other = self.owner;

    if (other.health > other.max_health)
    {
        other.health = other.health - 1;
        self.nextthink = time + 1;
        return;
    }

// it is possible for a player to die and respawn between rots, so don't
// just blindly subtract the flag off
    other.items = other.items - (other.items & IT_SUPERHEALTH);

    if (deathmatch)
    {
        self.nextthink = time + 20;
        self.think = SUB_regen;
    }
};

/*
===============================================================================

ARMOR

===============================================================================
*/

void() armor_touch;

void() armor_touch =
{
    local   float   type, value, bit;

    if (other.health <= 0)
        return;
    if (other.classname != "player")
        return;

    if (self.classname == "item_armor1")
    {
        type = 0.3;
        value = 100;
        bit = IT_ARMOR1;
    }
    if (self.classname == "item_armor2")
    {
        type = 0.6;
        value = 150;
        bit = IT_ARMOR2;
    }
    if (self.classname == "item_armorInv")
    {
        type = 0.8;
        value = 200;
        bit = IT_ARMOR3;
    }
    if (other.armortype*other.armorvalue >= type*value)
        return;

    other.armortype = type;
    other.armorvalue = value;
    other.items = other.items - (other.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + bit;

    self.solid = SOLID_NOT;
    self.model = string_null;
    if (deathmatch)
        self.nextthink = time + 20;
    self.think = SUB_regen;

    Sprint(other, PRINT_LOW, "Picked up basic armor\n"); // FIXME need also Body, Fire, Spirit, Super
    sound(other, CHAN_ITEM, "items/pickarmr.wav", 1, ATTN_NORM);
    stuffcmd (other, "bf\n");

    activator = other;
    SUB_UseTargets();               // fire all targets / killtargets
};

// Basic Armor
// FIXME: merge with real armor code when damage types are coded

void() item_armor0 =
    {
    precache_model("progs/i_arm_bs.mdl");
    setmodel(self, "progs/i_arm_bs.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

// Spirit Armor
// FIXME: merge with real armor code when damage types are coded

void() item_armor4 =
    {
    precache_model("progs/i_arm_sp.mdl");
    setmodel(self, "progs/i_arm_sp.mdl");

    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
    };

/*QUAKED item_armor1 (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() item_armor1 =
{
    self.touch = armor_touch;
    precache_model ("progs/i_arm_bd.mdl");
    setmodel (self, "progs/i_arm_bd.mdl");
    self.skin = 0;
    setsize (self, '-16 -16 0', '16 16 56');
    StartItem ();
};

/*QUAKED item_armor2 (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() item_armor2 =
{
    self.touch = armor_touch;
    precache_model ("progs/armor.mdl");
    setmodel (self, "progs/armor.mdl");
    self.skin = 1;
    setsize (self, '-16 -16 0', '16 16 56');
    StartItem ();
};

/*QUAKED item_armorInv (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() item_armorInv =
{
    self.touch = armor_touch;
    precache_model ("progs/armor.mdl");
    setmodel (self, "progs/armor.mdl");
    self.skin = 2;
    setsize (self, '-16 -16 0', '16 16 56');
    StartItem ();
};

/*
===============================================================================

WEAPONS

===============================================================================
*/

void() bound_other_ammo =
{
    if (other.ammo_shells > 100)
        other.ammo_shells = 100;
    if (other.ammo_nails > 200)
        other.ammo_nails = 200;
    if (other.ammo_rockets > 100)
        other.ammo_rockets = 100;
    if (other.ammo_cells > 100)
        other.ammo_cells = 100;
};


float(float w) RankForWeapon =
{
    if (w == IT_LIGHTNING)
        return 1;
    if (w == IT_ROCKET_LAUNCHER)
        return 2;
    if (w == IT_SUPER_NAILGUN)
        return 3;
    if (w == IT_GRENADE_LAUNCHER || w == IT_PROXIMITY_BOMB)
        return 4;
    if (w == IT_SUPER_SHOTGUN)
        return 5;
    if (w == IT_NAILGUN)
        return 6;
    if (w == IT_VOODOO_DOLL)
        return 7;
    return 8;
};

float (float w) WeaponCode =
{
    if (w == IT_SUPER_SHOTGUN)
        return 3;
    if (w == IT_NAILGUN)
        return 4;
    if (w == IT_SUPER_NAILGUN)
        return 5;
    if (w == IT_GRENADE_LAUNCHER || w == IT_PROXIMITY_BOMB)
        return 6;
    if (w == IT_ROCKET_LAUNCHER)
        return 7;
    if (w == IT_LIGHTNING)
        return 8;
    if (w == IT_VOODOO_DOLL)
        return 9;
    return 1;
};


/*
=============
Deathmatch_Weapon

Deathmatch weapon change rules for picking up a weapon

.float      ammo_shells, ammo_nails, ammo_rockets, ammo_cells;
=============
*/
void(float old, float new) Deathmatch_Weapon =
{
    local float or, nr;

// change self.weapon if desired
    or = RankForWeapon (self.weapon);
    nr = RankForWeapon (new);
    if ( nr < or )
        self.weapon = new;
};

float() W_BestWeapon;

/*
=============
weapon_touch
=============
*/
void() weapon_touch =
{
    local   float   new, old;
    local   float   leave;
    local   entity  stemp;

    #ifdef QUAKEWORLD
    // For client weapon_switch
    local   float   w_switch;
    #endif

    if (!(other.flags & FL_CLIENT))
        return;

    #ifdef QUAKEWORLD
    if ((stof(infokey(other,"w_switch"))) == 0)
        w_switch = 8;
    else
        w_switch = stof(infokey(other,"w_switch"));
    #endif

    if (cvar ("g_weaponStay")
    #ifndef QUAKEWORLD
        || (!deathmatch && coop)  // Always leave weapons on SP coop
    #endif
       )
        leave = 1;
    else
        leave = 0;

    if (self.classname == "weapon_flaregun")
    {
        if (leave && (other.items & IT_SHOTGUN) )
            return;
        new = IT_SHOTGUN;
        other.ammo_shells = other.ammo_shells + 8;
    }
    else if (self.classname == "weapon_nailgun")
    {
        if (leave && (other.items & IT_NAILGUN) )
            return;
        new = IT_NAILGUN;
        other.ammo_nails = other.ammo_nails + 30;
    }
    else if (self.classname == "weapon_supernailgun")
    {
        if (leave && (other.items & IT_SUPER_NAILGUN) )
            return;
        new = IT_SUPER_NAILGUN;
        other.ammo_nails = other.ammo_nails + 30;
    }
    else if (self.classname == "weapon_supershotgun")
    {
        if (leave && (other.items & IT_SUPER_SHOTGUN) )
            return;
        new = IT_SUPER_SHOTGUN;
        other.ammo_shells = other.ammo_shells + 5;
    }
    else if (self.classname == "weapon_rocketlauncher")
    {
        if (leave && (other.items & IT_ROCKET_LAUNCHER) )
            return;
        new = IT_ROCKET_LAUNCHER;
        other.ammo_rockets = other.ammo_rockets + 5;
    }
    else if (self.classname == "weapon_grenadelauncher")
    {
        if (leave && (other.items & IT_GRENADE_LAUNCHER) )
            return;
        new = IT_GRENADE_LAUNCHER;
        other.ammo_rockets = other.ammo_rockets + 5;
    }
    else if (self.classname == "weapon_lightning")
    {
        if (leave && (other.items & IT_LIGHTNING) )
            return;
        new = IT_LIGHTNING;
        other.ammo_cells = other.ammo_cells + 15;
    }
    else if (self.classname == "weapon_voodoodoll")
    {
        if (leave && (other.items & IT_VOODOO_DOLL) )
            return;
        new = IT_VOODOO_DOLL;
        other.ammo_cells = other.ammo_cells + 10;
    }
    else
        objerror ("weapon_touch: unknown classname");

    #ifndef QUAKEWORLD
    //ZOID--remove unnessary msgs
    if (!deathmatch) {
    #endif
        Sprint (other, PRINT_LOW, "Picked up ");
        Sprint (other, PRINT_LOW, self.netname);
        Sprint (other, PRINT_LOW, "\n");
    #ifndef QUAKEWORLD
    }
    #endif

// weapon touch sound
    sound (other, CHAN_ITEM, "items/weaponup.wav", 1, ATTN_NORM);
    stuffcmd (other, "bf\n");

    bound_other_ammo ();

// change to the weapon
    old = other.items;
    other.items = other.items | new;

    stemp = self;
    self = other;

    #ifdef QUAKEWORLD
    if ( WeaponCode(new) <= w_switch )
    {
        if (self.flags & FL_INWATER)
        {
            if (new != IT_LIGHTNING)
                Deathmatch_Weapon (old, new);
        }
        else
            Deathmatch_Weapon (old, new);
    }
    #else
    if (!deathmatch)
        self.weapon = new;
    else
        Deathmatch_Weapon (old, new);
    #endif

    W_SetCurrentAmmo();

    self = stemp;

    if (leave)
        return;

    // remove it in single player, or setup for respawning in deathmatch
    self.model = string_null;
    self.solid = SOLID_NOT;
    #ifndef QUAKEWORLD
    if (deathmatch)
    #endif
        self.nextthink = time + 30;
    self.think = SUB_regen;

    activator = other;
    SUB_UseTargets();               // fire all targets / killtargets
};


/*QUAKED weapon_flaregun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_flaregun =
{
    precache_model ("progs/g_flare.mdl");
    setmodel (self, "progs/g_flare.mdl");
    self.weapon = IT_SHOTGUN;
    self.netname = "Flare Gun";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // precache the necessary sounds
    precache_sound ("weapons/flaregun/flaref.wav");

    StartItem ();
};

/*QUAKED weapon_supershotgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_supershotgun =
{
    precache_model ("progs/g_shot.mdl");
    setmodel (self, "progs/g_shot.mdl");
    self.weapon = IT_SUPER_SHOTGUN;
    self.netname = "Sawed-off";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // Precache the necessary sounds
//    precache_sound ("weapons/shotgun/sawcock1.wav"); //same as shotcock.wav
    precache_sound ("weapons/shotgun/shotcock.wav");
    precache_sound ("weapons/shotgun/shotfir2.wav");  //shotgun alt-fire
    precache_sound ("weapons/shotgun/shotfire.wav");  // shotgun fired
//    precache_sound ("weapons/shotgun/shotload.wav");
    precache_sound ("weapons/shtshl2.wav");  // shell hitting ground
//    precache_sound ("weapons/shtshl4.wav");  // same as shtshl2.wav

    StartItem ();
};

/*QUAKED weapon_nailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_nailgun =
{
    precache_model ("progs/g_nail.mdl");
    setmodel (self, "progs/g_nail.mdl");
    self.weapon = IT_NAILGUN;
    self.netname = "Tommy Gun";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // Precache the necessary sounds
    precache_sound ("weapons/tommygun/_tom.wav");  // Fire
//    precache_sound ("weapons/tommygun/tomcock.wav");  // Out of bullet noise
    precache_sound ("weapons/shtshl.wav");   // shell hitting ground
    precache_sound ("weapons/shtshl3.wav");  // shell hitting ground (2nd)

    StartItem ();
};

/*QUAKED weapon_supernailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_supernailgun =
{
    precache_model ("progs/g_nail2.mdl");
    setmodel (self, "progs/g_nail2.mdl");
    self.weapon = IT_SUPER_NAILGUN;
    self.netname = "Spray Can";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // Precache the necessary sounds
//    precache_sound ("weapons/spraycan/burstflm.wav");
//    precache_sound ("weapons/spraycan/spraycan.wav");
    precache_sound ("weapons/spraycan/sprayfir.wav");  // fire

    StartItem ();
};

/*QUAKED weapon_grenadelauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_grenadelauncher =
{
    precache_model ("progs/g_rock.mdl");
    setmodel (self, "progs/g_rock.mdl");
    self.weapon = IT_GRENADE_LAUNCHER;
    self.netname = "Dynamite";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');
    StartItem ();
};

/*QUAKED weapon_rocketlauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_rocketlauncher =
{
    precache_model ("progs/g_rock2.mdl");
    setmodel (self, "progs/g_rock2.mdl");
    self.weapon = IT_ROCKET_LAUNCHER;
    self.netname = "Napalm Launcher";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    precache_model ("progs/naltball.mdl"); // napalm alt fire model

    // Precache the necessary sounds
    precache_sound ("weapons/napalm/blaster.wav");  // Napalm launcher
/*
    precache_sound ("weapons/napalm/explodcs.wav");
    precache_sound ("weapons/napalm/explodfl.wav");
    precache_sound ("weapons/napalm/burn.wav");
    precache_sound ("weapons/napalm/explodul.wav");
    precache_sound ("weapons/napalm/explodus.wav");
    precache_sound ("weapons/napalm/naplmex2.wav");
*/

    StartItem ();
};


/*QUAKED weapon_lightning (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_lightning =
{
    precache_model ("progs/g_light.mdl");
    setmodel (self, "progs/g_light.mdl");
    self.weapon = IT_LIGHTNING;
    self.netname = "Tesla Cannon";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // Precache the necessary sounds
/*
    precache_sound ("weapons/tesla/taltac3.wav");
    precache_sound ("weapons/tesla/tesaltf2.wav");
    precache_sound ("weapons/tesla/tesaltfr.wav");
    precache_sound ("weapons/tesla/tesaltht.wav");
    precache_sound ("weapons/tesla/tesla1.wav");
*/
    precache_sound ("weapons/tesla/teslaz~1.wav");
//    precache_sound ("weapons/tesla/teslaz~2.wav");
    precache_sound ("weapons/tesla/tessngfr.wav");
//    precache_sound ("weapons/tesla/tessnght.wav");  // Hit

    StartItem ();
};


/*QUAKED weapon_voodoodoll (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_voodoodoll =
{
    precache_model ("progs/g_voodoo.mdl");
    setmodel (self, "progs/g_voodoo.mdl");
    self.weapon = IT_VOODOO_DOLL;
    self.netname = "Voodoo Doll";
    self.touch = weapon_touch;
    setsize (self, '-16 -16 0', '16 16 56');

    // Precache the necessary sounds
    precache_sound ("weapons/voodoodl/voolaugh.wav");
    precache_sound ("weapons/voodoodl/voostab.wav");

    StartItem ();
};


/*
===============================================================================

AMMO

===============================================================================
*/

void() ammo_touch =
{
local entity    stemp;
local float     best;

    if (other.classname != "player")
        return;
    if (other.health <= 0)
        return;

// if the player was using his best weapon, change up to the new one if better
    stemp = self;
    self = other;
    best = W_BestWeapon();
    self = stemp;


// shotgun
    if (self.weapon == 1)
    {
        if (other.ammo_shells >= 100)
            return;
        other.ammo_shells = other.ammo_shells + self.aflag;
    }

// spikes
    if (self.weapon == 2)
    {
        if (other.ammo_nails >= 200)
            return;
        other.ammo_nails = other.ammo_nails + self.aflag;
    }

//  rockets
    if (self.weapon == 3)
    {
        if (other.ammo_rockets >= 100)
            return;
        other.ammo_rockets = other.ammo_rockets + self.aflag;
    }

//  cells
    if (self.weapon == 4)
    {
        if (other.ammo_cells >= 100)
            return;
        other.ammo_cells = other.ammo_cells + self.aflag;
    }

    bound_other_ammo ();

    Sprint (other, PRINT_LOW, "Picked up ");
    Sprint (other, PRINT_LOW, self.netname);
    Sprint (other, PRINT_LOW, "\n");
// ammo touch sound
    sound (other, CHAN_ITEM, "items/ammo.wav", 1, ATTN_NORM);
    stuffcmd (other, "bf\n");

// change to a better weapon if appropriate

    if ( other.weapon == best )
    {
        stemp = self;
        self = other;
        self.weapon = W_BestWeapon();
        W_SetCurrentAmmo ();
        self = stemp;
    }

// if changed current ammo, update it
    stemp = self;
    self = other;
    W_SetCurrentAmmo();
    self = stemp;

// remove it in single player, or setup for respawning in deathmatch
    self.model = string_null;
    self.solid = SOLID_NOT;
    if (deathmatch)
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
    if (self.spawnflags & AMMO_BIG)
    {
        self.netname = "box of flares";
        self.aflag = 8;
    }
    else
        self.aflag = 4;
    self.weapon = 1;
    self.netname = "a few flares";
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
    self.netname = "tesla charges";
    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
};


/*QUAKED item_weapon (0 .5 .8) (0 0 0) (32 32 32) shotgun rocket spikes big
DO NOT USE THIS!!!! IT WILL BE REMOVED!
*/

#define WEAPON_SHOTGUN  1
#define WEAPON_ROCKET   2
#define WEAPON_SPIKES   4
#define WEAPON_BIG      8
void() item_weapon =
{
    self.touch = ammo_touch;

    if (self.spawnflags & WEAPON_SHOTGUN)
    {
        if (self.spawnflags & WEAPON_BIG)
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
    }

    if (self.spawnflags & WEAPON_SPIKES)
    {
        if (self.spawnflags & WEAPON_BIG)
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

    }

    if (self.spawnflags & WEAPON_ROCKET)
    {
        if (self.spawnflags & WEAPON_BIG)
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
        self.netname = "gasoline can";
    }

    setsize (self, '0 0 0', '32 32 56');
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
    if (other.items & self.items)
        return;

    Sprint (other, PRINT_LOW, "Picked up ");
    Sprint (other, PRINT_LOW, self.netname);
    Sprint (other,PRINT_LOW, "\n");

    sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
    stuffcmd (other, "bf\n");
    other.items = other.items | self.items;

    #ifndef QUAKEWORLD
    if (!coop)
    {
    #endif
        self.solid = SOLID_NOT;
        self.model = string_null;
    #ifndef QUAKEWORLD
    }
    #endif

    activator = other;
    SUB_UseTargets();               // fire all targets / killtargets
};


void() key_setsounds =
{
    if (world.worldtype == 0)
    {
        precache_sound ("items/pickkey.wav");  // medkey
        self.noise = "items/pickkey.wav";
    }
    if (world.worldtype == 1)
    {
        precache_sound ("items/pickkey.wav");  // runekey
        self.noise = "items/pickkey.wav";
    }
    if (world.worldtype == 2)
    {
        precache_sound2 ("items/pickkey.wav");  // basekey
        self.noise = "items/pickkey.wav";
    }
};

/*QUAKED item_key1 (0 .5 .8) (-16 -16 -24) (16 16 32)
SILVER key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base

the following keys need to exist in single player qBlood:
Skull, Eye, Fire, Dagger, Spider, Moon

*/

void() item_key1 =
{
    if (world.worldtype == 0)
    {
        precache_model ("progs/w_s_key.mdl");
        setmodel (self, "progs/w_s_key.mdl");
        self.netname = "silver key";
    }
    else if (world.worldtype == 1)
    {
        precache_model ("progs/m_s_key.mdl");
        setmodel (self, "progs/m_s_key.mdl");
        self.netname = "silver runekey";
    }
    else if (world.worldtype == 2)
    {
        precache_model2 ("progs/b_s_key.mdl");
        setmodel (self, "progs/b_s_key.mdl");
        self.netname = "silver keycard";
    }
    key_setsounds();
    self.touch = key_touch;
    self.items2 = IT2_KEY1;
    setsize (self, '-16 -16 -24', '16 16 32');
    StartItem ();
};

/*QUAKED item_key2 (0 .5 .8) (-16 -16 -24) (16 16 32)
GOLD key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base
*/

void() item_key2 =
{
    if (world.worldtype == 0)
    {
        precache_model ("progs/w_g_key.mdl");
        setmodel (self, "progs/w_g_key.mdl");
        self.netname = "gold key";
    }
    if (world.worldtype == 1)
    {
        precache_model ("progs/m_g_key.mdl");
        setmodel (self, "progs/m_g_key.mdl");
        self.netname = "gold runekey";
    }
    if (world.worldtype == 2)
    {
        precache_model2 ("progs/b_g_key.mdl");
        setmodel (self, "progs/b_g_key.mdl");
        self.netname = "gold keycard";
    }
    key_setsounds();
    self.touch = key_touch;
    self.items2 = IT2_KEY2;
    setsize (self, '-16 -16 -24', '16 16 32');
    StartItem ();
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
        precache_model2 ("progs/end2.mdl");
        setmodel (self, "progs/end2.mdl");
    }
    if (self.spawnflags & 4)
    {
        precache_model2 ("progs/end3.mdl");
        setmodel (self, "progs/end3.mdl");
    }
    if (self.spawnflags & 8)
    {
        precache_model2 ("progs/end4.mdl");
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

void() powerup_touch =
{
local entity    stemp;
local float     best;

    if (other.classname != "player")
        return;
    if (other.health <= 0)
        return;

    Sprint (other, PRINT_LOW, "Picked up ");
    Sprint (other,PRINT_LOW,  self.netname);
    Sprint (other,PRINT_LOW, "\n");

    #ifndef QUAKEWORLD
    if (deathmatch)
    {
    #endif
        self.mdl = self.model;

        if ((self.classname == "item_artifact_invulnerability") ||
            (self.classname == "item_artifact_invisibility"))
            self.nextthink = time + 60*5;
        else
            self.nextthink = time + 60;

        self.think = SUB_regen;
    #ifndef QUAKEWORLD
    }
    #endif

    sound (other, CHAN_VOICE, self.noise, 1, ATTN_NORM);
    stuffcmd (other, "bf\n");
    self.solid = SOLID_NOT;
    other.items = other.items | self.items;
    self.model = string_null;

// do the apropriate action
    if (self.classname == "item_artifact_envirosuit")
    {
        other.rad_time = 1;
        other.radsuit_finished = time + 30;
    }

    if (self.classname == "item_artifact_invulnerability")
    {
        other.invincible_time = 1;
        other.invincible_finished = time + 30;
    }

    if (self.classname == "item_artifact_invisibility")
    {
        other.invisible_time = 1;
        other.invisible_finished = time + 30;
    }

    if (self.classname == "item_artifact_super_damage")
    {
        other.super_time = 1;
        other.super_damage_finished = time + 30;
    }

    activator = other;
    SUB_UseTargets();               // fire all targets / killtargets
};



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
    #ifdef QUAKEWORLD
    self.effects = self.effects | EF_RED;
    #endif
    self.items = IT_INVULNERABILITY;
    setsize (self, '-16 -16 -24', '16 16 32');
    StartItem ();
};

/*QUAKED item_artifact_envirosuit (0 .5 .8) (-16 -16 -24) (16 16 32)
Player takes no damage from water or slime for 30 seconds
*/
void() item_artifact_envirosuit =
{
    self.touch = powerup_touch;

    precache_model ("progs/suit.mdl");
    precache_sound ("foley/frbreath.wav");
    precache_sound ("foley/uwbreath.wav");
    self.noise = "foley/frbreath.wav";
    setmodel (self, "progs/suit.mdl");
    self.netname = "Diving Suit";
    self.items = IT_SUIT;
    setsize (self, '-16 -16 -24', '16 16 32');
    StartItem ();
};


/*QUAKED item_artifact_invisibility (0 .5 .8) (-16 -16 -24) (16 16 32)
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
    setsize (self, '-16 -16 -24', '16 16 32');
    StartItem ();
};


/*QUAKED item_artifact_super_damage (0 .5 .8) (-16 -16 -24) (16 16 32)
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
    self.items = IT_QUAD;
    #ifdef QUAKEWORLD
    self.effects = self.effects | EF_BLUE;
    #endif

    setsize (self, '-16 -16 -24', '16 16 32');
    StartItem ();
};



/*
===============================================================================

PLAYER BACKPACKS

===============================================================================
*/

void() BackpackTouch =
{
    local   string  s;
    local   float   best, old, new;
    local   entity  stemp;
    local   float   acount;
    #ifdef QUAKEWORLD
    local   float   b_switch;

    if ((stof(infokey(other,"b_switch"))) == 0)
        b_switch = 8;
    else
        b_switch = stof(infokey(other,"b_switch"));
    #endif

    if (other.classname != "player")
        return;
    if (other.health <= 0)
        return;

    acount = 0;
    Sprint (other, PRINT_LOW, "You get ");

    if (self.items)
        if ((other.items & self.items) == 0)
        {
            acount = 1;
            Sprint (other, PRINT_LOW, "the ");
            Sprint (other, PRINT_LOW, self.netname);
        }

// if the player was using his best weapon, change up to the new one if better
    stemp = self;
    self = other;
    best = W_BestWeapon();
    self = stemp;

// change weapons
    other.ammo_shells = other.ammo_shells + self.ammo_shells;
    other.ammo_nails = other.ammo_nails + self.ammo_nails;
    other.ammo_rockets = other.ammo_rockets + self.ammo_rockets;
    other.ammo_cells = other.ammo_cells + self.ammo_cells;

    new = self.items;
    if (!new)
        new = other.weapon;
    old = other.items;
    other.items = other.items | new;

    bound_other_ammo ();

    if (self.ammo_shells)
    {
        if (acount)
            Sprint(other, PRINT_LOW, ", ");
        acount = 1;
        s = ftos(self.ammo_shells);
        Sprint (other, PRINT_LOW, s);
        Sprint (other, PRINT_LOW, " shells");  // "Box of shotgun shells"
    }
    if (self.ammo_nails)
    {
        if (acount)
            Sprint(other, PRINT_LOW, ", ");
        acount = 1;
        s = ftos(self.ammo_nails);
        Sprint (other, PRINT_LOW, s);
        Sprint (other, PRINT_LOW, " nails");  // "Full drum of bullets"
    }
    if (self.ammo_rockets)
    {
        if (acount)
            Sprint(other, PRINT_LOW, ", ");
        acount = 1;
        s = ftos(self.ammo_rockets);
        Sprint (other, PRINT_LOW, s);
        Sprint (other, PRINT_LOW, " rockets");  // "Gasoline Can"
    }
    if (self.ammo_cells)
    {
        if (acount)
            Sprint(other, PRINT_LOW, ", ");
        acount = 1;
        s = ftos(self.ammo_cells);
        Sprint (other, PRINT_LOW, s);
        Sprint (other, PRINT_LOW, " cells");  // "Tesla Charge"
    }

/* dturner,4/10/2001
   still need Flares,
   Bundle of TNT, Case of Tnt,
   Voodoo Doll,
   Trapped Soul,
   Spray Can,
   Proximaty Detonator,
   Remote Detonator
   */

    Sprint(other, PRINT_LOW, "\n");

    // backpack touch sound
    sound (other, CHAN_ITEM, "items/ammo.wav", 1, ATTN_NORM);
    stuffcmd (other, "bf\n");

// remove the backpack, change self to the player
    remove(self);
    self = other;

// change to the weapon
    #ifdef QUAKEWORLD
    if ( WeaponCode(new) <= b_switch )
    {
        if (self.flags & FL_INWATER)
        {
            if (new != IT_LIGHTNING)
            {
                Deathmatch_Weapon (old, new);
            }
        }
        else
        {
            Deathmatch_Weapon (old, new);
        }
    }
    #else
    if (!deathmatch)
        self.weapon = new;
    else
        Deathmatch_Weapon (old, new);
    #endif

    W_SetCurrentAmmo ();
};

/*
===============
DropBackpack
===============
*/
void() DropBackpack =
{
    local entity    item;

    if (!(self.ammo_shells + self.ammo_nails + self.ammo_rockets + self.ammo_cells))
        return; // nothing in it

    item = spawn();
    item.origin = self.origin - '0 0 24';

    // If the proximity bombs were selected, switch to grenade launcher
    if (self.weapon == IT_PROXIMITY_BOMB)
        self.weapon = IT_GRENADE_LAUNCHER;

    item.items = self.weapon;
    if (item.items == IT_AXE)
        item.netname = "Pitchfork";
    else if (item.items == IT_SHOTGUN)
        item.netname = "Flare Gun";
    else if (item.items == IT_SUPER_SHOTGUN)
        item.netname = "Sawed-off";
    else if (item.items == IT_NAILGUN)
        item.netname = "Tommy Gun";
    else if (item.items == IT_SUPER_NAILGUN)
        item.netname = "Spray Can";
    else if (item.items == IT_GRENADE_LAUNCHER)
        item.netname = "Dynamite";
    else if (item.items == IT_ROCKET_LAUNCHER)
        item.netname = "Napalm Launcher";
    else if (item.items == IT_LIGHTNING)
        item.netname = "Tesla Cannon";
    else if (item.items == IT_VOODOO_DOLL)
        item.netname = "Voodoo Doll";
    else
        item.netname = "";
    // need voodoo doll, tnt variants, life leech

    item.ammo_shells = self.ammo_shells;
    item.ammo_nails = self.ammo_nails;
    item.ammo_rockets = self.ammo_rockets;
    item.ammo_cells = self.ammo_cells;

    item.velocity_z = 300;
    item.velocity_x = -100 + (random() * 200);
    item.velocity_y = -100 + (random() * 200);

    item.flags = FL_ITEM;
    item.solid = SOLID_TRIGGER;
    item.movetype = MOVETYPE_TOSS;
    setmodel (item, "progs/backpack.mdl");
    setsize (item, '-16 -16 0', '16 16 56');
    item.touch = BackpackTouch;

    item.nextthink = time + 120;    // remove after 2 minutes
    item.think = SUB_Remove;
};
