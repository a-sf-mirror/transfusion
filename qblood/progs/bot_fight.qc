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

/*
 * Original version of this file taken from FrikBot X v0.10.1
 * Copyright (C) 2001  Ryan Smith
 * See the file COPYING.FrikBotX for the copyright notice.
 */


#include "common.qh"


.entity avoid;

float(entity e) bot_size_player =
{
    local float sz;

    sz = e.health + e.armorvalue * e.armortype;
    if (e.weapon == IT_NAPALM_LAUNCHER)
        sz = sz + 60;
    else if (e.weapon == IT_TESLA_CANNON)
        sz = sz + 60;
    else if (e.weapon == IT_LIFE_LEECH)
        sz = sz + 50;
    else if (e.weapon == IT_SPRAY_CAN)
        sz = sz + 50;
    else if (e.weapon == IT_TOMMYGUN)
        sz = sz + 40;
    else if (e.weapon == IT_SAWED_OFF)
        sz = sz + 40;
    else if (e.weapon == IT_VOODOO_DOLL)
        sz = sz + 40;
    else if (e.weapon == IT_TNT)
        sz = sz + 30;
    else if (e.weapon == IT_FLAREGUN)
        sz = sz + 10;
    else if (e.weapon == IT_PITCHFORK)
        sz = sz - 50;
    if (e.items & IT_GUNS_AKIMBO)
        sz = sz + 200;
    if (e.items & IT_INVULNERABILITY) // Invul
        sz = sz + 300;
    if (e.items & IT_INVISIBILITY) // Invis
        sz = sz + 250;
    return sz;
};

void() bot_dodge_stuff =
{
    local entity foe;
    local float foedist, avdist, scandist, foesz, flen, tsz;
    local vector v;

    if (waypoint_mode > WM_LOADED)
        return;

    self.avoid = world;


    if (self.enemy)
    {
        v = self.origin - realorigin(self.enemy);
        foedist = vlen(v);
        foesz = bot_size_player(self.enemy);
    }
    else
    {
        foedist = 3000;
        foesz = 9999999;
    }
    avdist = 256;

    foe = find(world, classname, "grenade");
    while(foe)
    {
        flen = vlen(foe.origin - self.origin);
        if (flen < avdist)
        {
            avdist = flen;
            self.avoid = foe;
        }
        foe = find(foe, classname, "grenade");
    }
    if (!self.avoid)
    {
        foe = find(world, classname, "missile");
        while(foe)
        {
            if (foe.owner != self)
            {
                flen = vlen(foe.origin - self.origin);
                if (flen < avdist)
                {
                    avdist = flen;
                    self.avoid = foe;
                }
            }
            foe = find(foe, classname, "missile");
        }
        if (!self.avoid)
        {
            foe = find(world, classname, "spike");
            while(foe)
            {
                if (foe.owner != self)
                {
                    flen = vlen(foe.origin - self.origin);
                    if (flen < avdist)
                    {
                        avdist = flen;
                        self.avoid = foe;
                    }
                }
                foe = find(foe, classname, "spike");
            }
        }
    }
    foe = player_head;
    while(foe)
    {
        if(foe != self)
        {
            if (foe.modelindex != 0)
            {
                if (foe.health > 0)
                {
                    if (!(gametype >= GT_TEAM_BLOODBATH && self.team == foe.team))
                    {
                        flen = vlen(foe.origin - self.origin);
                        if (flen < foedist)
                        {
                            tsz = bot_size_player(foe);
                            if (tsz < foesz)
                            {
                                if (fov(foe) || foe.b_sound > time || self.b_skill == 3)
                                {
                                    if (fisible(foe))
                                    {
                                        self.enemy = foe;
                                        foedist = vlen(foe.origin - self.origin);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        foe = foe._next;
    }
};




/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

weapon_range

_x "sweet spot range" - try to maintain this range if possible
_y minimum range bot can be to be effective (rl/gl) (move away)
_z maximum range bot can be to be effective (lg/axe) (move in)
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

vector(float wep) weapon_range =
{
    if (wep == IT_PITCHFORK)
        return '48 0 64';
    else if (wep == IT_FLAREGUN)
        return '128 0 99999';
    else if (wep == IT_SAWED_OFF)
        return '48 0 3000';
    else if (wep == IT_TOMMYGUN)
        return '180 0 3000';
    else if (wep == IT_NAPALM_LAUNCHER)
        return '180 48 3000';
    else if (wep == IT_TNT)
        return '180 48 512';
    else if (wep == IT_PROXIMITY_BOMB)
        return '180 48 512';
    else if (wep == IT_REMOTE_DETONATOR)
        return '180 48 512';
    else if (wep == IT_SPRAY_CAN)
        return '128 0 512';
    else if (wep == IT_TESLA_CANNON)
        return '180 0 3000';
    else if (wep == IT_VOODOO_DOLL)
        return '256 0 3000';
    else if (wep == IT_LIFE_LEECH)
        return '180 0 3000';
};
/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

bot_weapon_switch

Pick a weapon based on range / ammo

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void(float brange) bot_weapon_switch =
{
    local   float   it, flag, pulse;
    local vector v;

    it = self.items & 127;

    while(it)
    {
        // Napalm Launcher
        if ((self.ammo_rockets >= 1) && (it & IT_NAPALM_LAUNCHER))
        {
            flag = IT_NAPALM_LAUNCHER;
            pulse = 5;
        }
        // Tesla Cannon
        else if (self.ammo_cells >= 1 && (it & IT_TESLA_CANNON))
        {
            flag = IT_TESLA_CANNON;
            pulse = 8;
        }
        // Life Leech
        else if(self.ammo_leech >= 1 && (it & IT_LIFE_LEECH))
        {
            flag = IT_LIFE_LEECH;
            pulse = 9;
        }
        // Spray Can
        else if(self.ammo_spray >= 1 && (it & IT_SPRAY_CAN))
        {
            flag = IT_SPRAY_CAN;
            pulse = 7;
        }
        // Sawed Off
        else if(self.ammo_shells >= 2 && (it & IT_SAWED_OFF))
        {
            flag = IT_SAWED_OFF;
            pulse = 3;
        }
        // Tommy Gun
        else if(self.ammo_nails >= 1 && (it & IT_TOMMYGUN))
        {
            flag = IT_TOMMYGUN;
            pulse = 4;
        }
        // Voodoo Doll
        else if(self.ammo_voodoo >= 1 && (it & IT_VOODOO_DOLL))
        {
            flag = IT_VOODOO_DOLL;
            pulse = 17;
        }
        // Flaregun
        else if(self.ammo_shells >= 1 && (it & IT_FLAREGUN))
        {
            flag = IT_FLAREGUN;
            pulse = 2;
        }
        // TNT
        else if ((self.ammo_tnt_bundle >= 1) && (it & IT_TNT))
        {
            flag = IT_TNT;
            pulse = 6;
        }
        else
        {
            if (pulse)
                self.impulse = pulse;
            return;
        }

        if (brange == -1)
        {
            if (pulse)
                self.impulse = pulse;
            return;
        }

        v = weapon_range(flag);
        if (brange < v_y || brange > v_z)
            it = it - flag;
        else
        {
            if (pulse)
                self.impulse = pulse;
            return;
        }
    }
};

void() bot_shoot =
{
    // quick little function to stop making him shoot the wrong way ! Argh
    local float g;
    g = angcomp(self.v_angle_x, self.b_angle_x);
    if (fabs(g) > 10 * (4 - self.b_skill))
        return; // argh, too far away
    g = angcomp(self.v_angle_y, self.b_angle_y);
    if (fabs(g) > 7 * (4 - self.b_skill))
        return; // not again!
    self.button0 = TRUE;
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Bot_fight_style

This is the core of the bot's thinking when
attacking an enemy.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void() bot_fight_style =
{
    local vector v, v1, v2, org;
    local float foedist, mysz, foesz;


    if (self.enemy.health <= 0)
    {
        self.enemy = world;
        return;
    }
    else if (!self.enemy.takedamage)
    {
        self.enemy = world;
        return;
    }
    else if (!fisible(self.enemy))
    {
        self.enemy = world;
        return;
    }

    org = realorigin(self.enemy);
    makevectors(self.v_angle);

    // decide if I should shoot

    foedist = vlen(org - self.origin);
    v = weapon_range(self.weapon);
    if (foedist > v_y && foedist < v_z)
    {
        traceline(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * v_z, FALSE, self);
        if (vlen(trace_endpos - (self.origin + self.view_ofs)) >= v_y)
        {
            // try to avoid shooting teammates
            if (trace_ent.classname == "player")
                if (trace_ent.team == self.team && gametype >= GT_TEAM_BLOODBATH)
                    return;
            bot_shoot();
        }
    }
    else
        bot_weapon_switch(foedist);

    if (!(self.b_aiflags & (AI_PRECISION | AI_BLIND | AI_OBSTRUCTED)))
    {
        foesz = bot_size_player(self.enemy);
        mysz = bot_size_player(self) + 5;

        if (foesz > mysz)
        {
            if (gametype >= GT_TEAM_BLOODBATH)
            {
                if (random() < 0.02)
                {
                    bot_start_topic(5);
                    self.b_chattime = 1;
                }
            }

            return;
        }
        else if (mysz < 140)
            return;
        else if (self.avoid)
        {
            if (self.avoid.velocity)
                v = self.avoid.velocity;
            else
                v = normalize(self.avoid.origin - self.origin);
            v1_x = v_y;
            v1_y = v_y * -1;
            v2_x = v_y;
            v2_y = v_y * -1;
            foedist = vlen(self.avoid.origin - (self.origin + v1));
            if (foedist < vlen(self.avoid.origin - (self.origin + v2)))
                frik_walkmove(v2);
            else
                frik_walkmove(v1);
        }
        else
        {
            if (foedist + 32 <  v_x)
                frik_walkmove(self.origin - org);
            else if (foedist - 32 >  v_x)
                frik_walkmove(org - self.origin);
            else if (self.wallhug)
                frik_walkmove(v_right);
            else
                frik_walkmove(v_right * -1);
        }
    }
    else
    {
        foesz = bot_size_player(self.enemy);
        mysz = bot_size_player(self) + 5;

        if (foesz > mysz)
            return;
        else if (mysz < 140)
            return;
        self.keys = self.keys & 960;
    }
};


