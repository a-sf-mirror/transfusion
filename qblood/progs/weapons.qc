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


void () player_run;
void(entity bomb, entity attacker, float rad, entity ignore, string dtype) T_RadiusDamage;
void() identify_player;


//============================================================================

vector() wall_velocity =
{
    local vector    vel;

    vel = normalize (self.velocity);
    vel = normalize(vel + v_up*(random()- 0.5) + v_right*(random()- 0.5));
    vel = vel + 2*trace_plane_normal;
    vel = vel * 200;

    return vel;
};


/*
================
SpawnBlood
================
*/
void(vector org, vector vel, float damage) SpawnBlood =
{
    particle (org, vel*0.1, 73, damage*2);
};


/*
================
MeatSprayTouch

Bleeds when generic meat spray touches something
================
*/
void() MeatSprayTouch =
{
    SpawnBlood (self.origin, '0 0 500', 16);
};

/*
================
BloodMeatSpray

Modified to behave more like Blood's blood spray
================
*/
void(vector org, vector vel, entity ignore) BloodMeatSpray =
{
    local   entity  missile;
    local   vector  org;

    missile = spawn ();
    missile.owner       = ignore;
    missile.movetype    = MOVETYPE_TOSS;    // Was *_BOUNCE
    missile.solid       = SOLID_BBOX;       // Was *_NOT

    missile.velocity    = vel;
    missile.avelocity   = '3000 1000 2000';

    // set missile duration
    missile.nextthink   = time + 1;
    missile.think       = SUB_Remove;
    missile.touch       = MeatSprayTouch;

    setmodel (missile, "progs/bitogore.mdl");
    setsize (missile, '0 0 0', '0 0 0');
    setorigin (missile, org);
};


/*
================
SpawnBloodSpray
================
*/
void(entity targ, vector org) SpawnBloodSpray =
{
    if (random() < 0.25)    // 25% chance per call of spawning blood.
    {
        local   vector  vel;

        vel_x = crandom() * 300;
        vel_y = crandom() * 300;
        vel_z = random() * 300 + 200;
        BloodMeatSpray (org, vel, targ);
    }
};


float(entity targ) Reflected =
{
    if (!targ)
        return FALSE;

    return (targ.reflect_finished >= time);
};


/*
==============================================================================

MULTI-DAMAGE

Collects multiple small damages into a single damage

==============================================================================
*/

entity  multi_ent;
float   multi_damage;

void() ClearMultiDamage =
{
    multi_ent = world;
    multi_damage = 0;
};

void() ApplyMultiDamage =
{
    if (!multi_ent)
        return;
    T_Damage (multi_ent, self, self, multi_damage, DF_BODY, string_null);
};

void(entity hit, float damage) AddMultiDamage =
{
    if (!hit)
        return;

    if (hit != multi_ent)
    {
        ApplyMultiDamage ();
        multi_damage = damage;
        multi_ent = hit;
    }
    else
        multi_damage = multi_damage + damage;
};

/*
==============================================================================

BULLETS

==============================================================================
*/

/*
================
TraceAttack
================
*/
void(float damage, vector dir) TraceAttack =
{
    if (Reflected (trace_ent))
    {
        if (Reflected (self))
            return;     // Both have reflection, so negate attack.

        // Hit attacker instead.
        trace_ent = self;
        trace_endpos = self.origin;
        dir = '0 0 0' - dir;
    }

    local   vector  vel, org;

    vel = normalize(dir + v_up*crandom() + v_right*crandom());
    vel = vel + 2*trace_plane_normal;
    vel = vel * 200;

    org = trace_endpos - dir*4;

    if (trace_ent.takedamage)
        AddMultiDamage (trace_ent, damage);

    // Make players bleed
    if (trace_ent.takedamage && trace_ent.classname == "player")
    {
        SpawnBlood (org, vel*0.2, damage);
        SpawnBloodSpray (trace_ent, org);
    }
    else
    {
        WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte (MSG_BROADCAST, TE_GUNSHOT);
        WriteCoord (MSG_BROADCAST, org_x);
        WriteCoord (MSG_BROADCAST, org_y);
        WriteCoord (MSG_BROADCAST, org_z);
    }
};


/*
================
FireBullets

Used by shotgun, super shotgun, and enemy soldier firing
Go to the trouble of combining multiple pellets into a single damage call.
================
*/
void(vector orig, vector dir, float shotcount, float damage, vector spread) FireBullets =
{
    local vector direction;
    local vector src;

    makevectors(self.v_angle);

    src = orig + v_forward*10;
    src_z = self.absmin_z + self.size_z * 0.7;

    ClearMultiDamage ();

    while (shotcount > 0)
    {
        direction = dir + crandom()*spread_x*v_right + crandom()*spread_y*v_up;

        traceline (src, src + direction*2048, FALSE, self);
        if (trace_fraction != 1.0)
            TraceAttack (damage, direction);

        shotcount = shotcount - 1;
    }
    ApplyMultiDamage ();
};


/*
================
ShellHit

Plays hit sound when shell hits hard surface if not stuck inloop
================
*/
void() ShellHit =
{
    // prevent sound if last shellhit sound occured within last 2 frames
    if (self.ltime <= (time - 0.2))
        sound (self, CHAN_WEAPON, self.noise, 1,ATTN_NORM);

    self.ltime = time; // marks time of current touch triggeractivation
};


/*
================
DropShell

Displays shell and defines its dynamic manifestation
================
*/
void(entity shell) DropShell =
{
    shell.movetype = MOVETYPE_BOUNCE;
    shell.solid = SOLID_BBOX;
    setmodel (shell, shell.mdl);
    setsize (shell, VEC_ORIGIN, VEC_ORIGIN);
    makevectors (shell.owner.v_angle);

    shell.avelocity_x = crandom()*500;
    shell.avelocity_y = crandom()*500;
    shell.avelocity_z = crandom()*500;
    shell.touch = ShellHit;
    shell.nextthink = time + 1.2;
    shell.think = SUB_Remove;
    shell.reset = SUB_Remove;
    shell.ltime = time - 1;
    shell.effects = shell.effects | EF_LOWPRECISION;
};


/*
==============================================================================

ROCKETS

==============================================================================
*/

void(entity client) ResetIdle =
{
    client.idle_done = FALSE;
    client.idle_time = time + 5 + random() * 10;  // 5-15 sec.
};

// This makes the player rave.
void(entity client) BoredCaleb =
{
    // If we're already talking
    if (client.voice_finished >= time)
        return;

    if (client.health <= 0 || client.deadflag)
        return;
    if (client.classname != "player" || !client.takedamage)
        return;

    local   float   rs;
    local   string  playit;

    rs = floor (random() * 12);

    if (rs == 0)
        playit = "player/songs/1093.wav";   // "Strangers in the night..."
    else if (rs == 1)
        playit = "player/songs/1094.wav";   // "There's no business like..."
    else if (rs == 2)
        playit = "player/songs/1095.wav";   // "I did it... my way!"
    else if (rs == 3)
        playit = "player/songs/1097.wav";   // "...putting on the Ritz."
    else if (rs == 4)
        playit = "player/songs/vo3011.wav";   // "sun will come out . . ."
    else if (rs == 5)
        playit = "player/songs/vo3024.wav";   // "row row row your boat"
    else if (rs == 6)
        playit = "player/songs/vo3026.wav";   // "it's a long way ..."
    else if (rs == 7)
        playit = "player/songs/vo3030.wav";   // "somewhere over the rainbow."
    else if (rs == 8)
        playit = "player/songs/vo3033.wav";   // "sailing sailing ..."
    else if (rs == 9)
        playit = "player/songs/vo3034.wav";   // "on the good ship lollipop."
    else if (rs == 10)
        playit = "player/songs/vo3035.wav";   // "i get no kick from champagne...."
    else
        playit = "player/songs/vo3039.wav";   // "i've got you under my skin"

    client.voice_finished = time + 8;
    sound (client, CHAN_VOICE, playit, 1, ATTN_NORM);
};

// This makes the player laugh or utter one of Caleb's signature one-liners.
void(entity client) PsychoCaleb =
{
    // If we're already talking
    if (client.voice_finished >= time)
        return;

    if (random() > 0.15)
        return;     // Only 15% chance per call.
    if (client.health <= 0 || client.deadflag)
        return;
    if (client.classname != "player")
        return;

    local   float   rs;
    local   string  playit;

    rs = floor (random() * 3);

    if (rs == 0)
        playit = "player/quips/1039.wav";   // "Son of a bitch must pay!"
    else if (rs == 1)
        playit = "player/quips/1050.wav";   // "Tha, tha, that's all folks!"
    else if (rs == 2)
        playit = "player/quips/1057.wav";   // "Rest in pieces"
    else
    {
        // Laugh like a psycho.
        rs = floor (random() * 8);

        if (rs == 0)
            playit = "player/play1109.wav";
        else if (rs == 1)
            playit = "player/play1110.wav";
        else if (rs == 2)
            playit = "player/play1111.wav";
        else if (rs == 3)
            playit = "player/play1112.wav";
        else if (rs == 4)
            playit = "player/play1113.wav";
        else if (rs == 5)
            playit = "player/play1114.wav";
        else if (rs == 6)
            playit = "player/play1115.wav";
        else
            playit = "player/play1116.wav";
    }

    client.voice_finished = time + 5;
    sound (client, CHAN_VOICE, playit, 1, ATTN_NORM);
};


// 13 frames for Blood's explosion
void() s_explode1  = [0,  s_explode2]  {};
void() s_explode2  = [1,  s_explode3]  {};
void() s_explode3  = [2,  s_explode4]  {};
void() s_explode4  = [3,  s_explode5]  {};
void() s_explode5  = [4,  s_explode6]  {};
void() s_explode6  = [5,  s_explode7]  {};
void() s_explode7  = [6,  s_explode8]  {};
void() s_explode8  = [7,  s_explode9]  {};
void() s_explode9  = [8,  s_explode10] {};
void() s_explode10 = [9,  s_explode11] {};
void() s_explode11 = [10, s_explode12] {};
void() s_explode12 = [11, s_explode13] {};
void() s_explode13 = [12, SUB_Remove]  {};

void() BecomeExplosion =
{
    self.movetype = MOVETYPE_NONE;
    self.velocity = '0 0 0';
    self.touch = SUB_Null;
    setmodel (self, "progs/s_explod.spr");
    self.solid = SOLID_NOT;
    self.reset = SUB_Remove;
    s_explode1 ();
};


//=============================================================================

void() flame_touch =
{
    local float rand;

    if (other == self.owner)
        return;

    if (other.solid == SOLID_TRIGGER)
        return; // trigger field, do nothing

    if (pointcontents(self.origin) == CONTENT_SKY)
    {
        remove(self);
        return;
    }

    // hit something that bleeds
    if (other.takedamage)
        BurnDamage (other, self, 5, DF_FIRE, 10, 3);

    remove(self);

};


/*
===============================================================================

PLAYER WEAPON USE

===============================================================================
*/

// Functions defined later in weapon files (w_*.qc)
void() Fork_Attack;     void() Fork_Draw;   void() Fork_Holster;    void() Fork_UpdateView;
void() Flare_Attack;    void() Flare_Draw;  void() Flare_Holster;   void() Flare_UpdateView;
void() Shot_Attack;     void() Shot_Draw;   void() Shot_Holster;    void() Shot_UpdateView;
void() Tommy_Attack;    void() Tommy_Draw;  void() Tommy_Holster;   void() Tommy_UpdateView;
void() Spray_Attack;    void() Spray_Draw;  void() Spray_Holster;   void() Spray_UpdateView;
void() TNT_Attack;      void() TNT_Draw;    void() TNT_Holster;     void() TNT_UpdateView;
void() Proxy_Attack;    void() Proxy_Draw;  void() Proxy_Holster;   void() Proxy_UpdateView;
void() Remote_Attack;   void() Remote_Draw; void() Remote_Holster;  void() Remote_UpdateView;
void() Tesla_Attack;    void() Tesla_Draw;  void() Tesla_Holster;   void() Tesla_UpdateView;
void() Napalm_Attack;   void() Napalm_Draw; void() Napalm_Holster;  void() Napalm_UpdateView;
void() Voodoo_Attack;   void() Voodoo_Draw; void() Voodoo_Holster;  void() Voodoo_UpdateView;
void() Leech_Attack;    void() Leech_Draw;  void() Leech_Holster;   void() Leech_UpdateView;


/*
====================
W_DrawWeapon

Draw a new weapon
====================
*/
void(float weap) W_DrawWeapon =
{
    if (! (self.items & weap))
        return;

    // Don't draw a fire based weapon under water
    if (self.waterlevel == 3)
    {
        if (self.weapon == IT_TNT || self.weapon == IT_SPRAY_CAN)
            weap = W_BestWeapon ();
    }

    self.player_state = PS_DRAW;

    if (weap == IT_PITCHFORK)
        Fork_Draw ();
    else if (weap == IT_FLAREGUN)
        Flare_Draw ();
    else if (weap == IT_SAWED_OFF)
        Shot_Draw ();
    else if (weap == IT_TOMMYGUN)
        Tommy_Draw ();
    else if (weap == IT_SPRAY_CAN)
        Spray_Draw ();
    else if (weap == IT_TNT)
        TNT_Draw ();
    else if (weap == IT_PROXIMITY_BOMB)
        Proxy_Draw ();
    else if (weap == IT_REMOTE_DETONATOR)
        Remote_Draw ();
    else if (weap == IT_NAPALM_LAUNCHER)
        Napalm_Draw ();
    else if (weap == IT_TESLA_CANNON)
        Tesla_Draw ();
    else if (weap == IT_VOODOO_DOLL)
        Voodoo_Draw ();
    else if (weap == IT_LIFE_LEECH)
        Leech_Draw ();

    self.newweapon = 0;
};


/*
====================
W_SwitchToWeapon

Switch to another player's weapon
====================
*/
void(float newWeapon) W_SwitchToWeapon =
{
    self.newweapon = 0;

    // If we don't have that weapon
    if (! (self.items & newWeapon))
        return;

    // If the new weapon is already the current one
    if (self.weapon == newWeapon)
        return;

    self.newweapon = newWeapon;
    self.player_state = PS_HOLSTER;

    if (self.weapon == IT_PITCHFORK)
        Fork_Holster ();
    else if (self.weapon == IT_FLAREGUN)
        Flare_Holster ();
    else if (self.weapon == IT_SAWED_OFF)
        Shot_Holster ();
    else if (self.weapon == IT_TOMMYGUN)
        Tommy_Holster ();
    else if (self.weapon == IT_SPRAY_CAN)
        Spray_Holster ();
    else if (self.weapon == IT_TNT)
        TNT_Holster ();
    else if (self.weapon == IT_PROXIMITY_BOMB)
        Proxy_Holster ();
    else if (self.weapon == IT_REMOTE_DETONATOR)
        Remote_Holster ();
    else if (self.weapon == IT_NAPALM_LAUNCHER)
        Napalm_Holster ();
    else if (self.weapon == IT_TESLA_CANNON)
        Tesla_Holster ();
    else if (self.weapon == IT_VOODOO_DOLL)
        Voodoo_Holster ();
    else if (self.weapon == IT_LIFE_LEECH)
        Leech_Holster ();
};


void() W_SetCurrentAmmo =
{
    if (self.weapon == IT_PITCHFORK)
    {
        self.currentammo = 0;
        Fork_UpdateView ();
    }
    else if (self.weapon == IT_FLAREGUN)
    {
        self.currentammo = self.ammo_flares;
        Flare_UpdateView ();
        //self.items = self.items | IT_SHELLS;
    }
    else if (self.weapon == IT_SAWED_OFF)
    {
        self.currentammo = self.ammo_shells;
        Shot_UpdateView ();
        self.items = self.items | IT_SHELLS;
    }
    else if (self.weapon == IT_TOMMYGUN)
    {
        self.currentammo = self.ammo_nails;
        Tommy_UpdateView ();
        self.items = self.items | IT_NAILS;
    }
    else if (self.weapon == IT_SPRAY_CAN)
    {
        self.currentammo = self.ammo_spray;
        Spray_UpdateView ();
        //self.items = self.items | IT_NAILS;
    }
    else if (self.weapon == IT_TNT)
    {
        self.currentammo = self.ammo_tnt_bundle;
        TNT_UpdateView ();
        //self.items = self.items | IT_ROCKETS;
    }
    else if (self.weapon == IT_PROXIMITY_BOMB)
    {
        self.currentammo = self.ammo_tnt_proxy;
        Proxy_UpdateView ();
        //self.items = self.items | IT_ROCKETS;
    }
    else if (self.weapon == IT_REMOTE_DETONATOR)
    {
        self.currentammo = self.ammo_tnt_remote;
        Remote_UpdateView ();
        //self.items = self.items | IT_ROCKETS;
    }
    else if (self.weapon == IT_NAPALM_LAUNCHER)
    {
        self.currentammo = self.ammo_rockets;
        Napalm_UpdateView ();
        self.items = self.items | IT_ROCKETS;
    }
    else if (self.weapon == IT_TESLA_CANNON)
    {
        self.currentammo = self.ammo_cells;
        Tesla_UpdateView ();
        self.items = self.items | IT_CELLS;
    }
    else if (self.weapon == IT_VOODOO_DOLL)
    {
        self.currentammo = self.ammo_voodoo;
        Voodoo_UpdateView ();
        //self.items = self.items | IT_CELLS;
    }
    else if (self.weapon == IT_LIFE_LEECH)
    {
        self.currentammo = self.ammo_leech;
        Leech_UpdateView ();
        //self.items = self.items | IT_CELLS;
    }
    else
    {
        self.currentammo = 0;
        self.weaponmodel = string_null;
    }
};


/*
====================
W_BestWeapon

Autoswitch weapon list

Note (Elric): This list comes from my experiments with Blood.
I don't really agree with the order, but hey ... it's Blood.
====================
*/
float() W_BestWeapon =
{
    local   float   it;

    it = self.items;

    // 1- Sawed Off
    if (self.ammo_shells >= 1 && (it & IT_SAWED_OFF))
        return IT_SAWED_OFF;

    // 2- Tommy Gun
    if (self.ammo_nails >= 1 && (it & IT_TOMMYGUN))
        return IT_TOMMYGUN;

    // 3- Flare Gun
    if (self.ammo_flares >= 1 && (it & IT_FLAREGUN))
        return IT_FLAREGUN;

    // 4- Tesla Cannon
    if (self.ammo_cells >= 1 && (it & IT_TESLA_CANNON))
        return IT_TESLA_CANNON;

    // 5- Voodoo Doll
    if (self.ammo_voodoo >= 1 && (it & IT_VOODOO_DOLL))
        return IT_VOODOO_DOLL;

    // 6- Spray Can
    if (self.ammo_spray >= 1 && (it & IT_SPRAY_CAN) && self.waterlevel < 3)
        return IT_SPRAY_CAN;

    // 7- Life Leech
    if (it & IT_LIFE_LEECH)
        return IT_LIFE_LEECH;

    // 8- Fork
    return IT_PITCHFORK;
};

float() W_AmmoAvailable =
{
    if (self.currentammo > 0)
        return TRUE;

    if (self.weapon == IT_PITCHFORK || self.weapon == IT_LIFE_LEECH)
        return TRUE;

    return FALSE;
};

/*
============
W_Attack

An attack impulse can be triggered now
============
*/
void() W_Attack =
{
    makevectors (self.v_angle);    // calculate forward angle for velocity

    if (self.weapon == IT_PITCHFORK)
        Fork_Attack ();
    else if (self.weapon == IT_FLAREGUN)
        Flare_Attack ();
    else if (self.weapon == IT_SAWED_OFF)
        Shot_Attack ();
    else if (self.weapon == IT_TOMMYGUN)
        Tommy_Attack ();
    else if (self.weapon == IT_SPRAY_CAN)
        Spray_Attack ();
    else if (self.weapon == IT_TNT)
        TNT_Attack ();
    else if (self.weapon == IT_PROXIMITY_BOMB)
        Proxy_Attack ();
    else if (self.weapon == IT_REMOTE_DETONATOR)
        Remote_Attack ();
    else if (self.weapon == IT_NAPALM_LAUNCHER)
        Napalm_Attack ();
    else if (self.weapon == IT_TESLA_CANNON)
        Tesla_Attack ();
    else if (self.weapon == IT_VOODOO_DOLL)
        Voodoo_Attack ();
    else if (self.weapon == IT_LIFE_LEECH)
        Leech_Attack ();

    self.impulse = 0;
};

/*
============
W_ChangeWeapon

============
*/
void() W_ChangeWeapon =
{
    local float old, am, new;

    // Don't let player change weapons while holding lit dynamite.
    if (self.tnt_time)
        return;

    old = self.weapon;
    am = 0;

    if (self.impulse == 1)
    {
        new = IT_PITCHFORK;
    }
    else if (self.impulse == 2)
    {
        new = IT_FLAREGUN;
        if (self.ammo_flares < 1)
            am = 1;
    }
    else if (self.impulse == 3)
    {
        new = IT_SAWED_OFF;
        if (self.ammo_shells < 1)
            am = 1;
    }
    else if (self.impulse == 4)
    {
        new = IT_TOMMYGUN;
        if (self.ammo_nails < 1)
            am = 1;
    }
    else if (self.impulse == 5)
    {
        new = IT_NAPALM_LAUNCHER;
        if (self.ammo_rockets < 1)
            am = 1;
    }
    else if (self.impulse == 6)
    {
        new = 0;

        // If we don't have any type of dynamite
        if (self.ammo_tnt_bundle < 1 &&
            self.ammo_tnt_proxy  < 1 &&
            !(self.items & IT_REMOTE_DETONATOR))  // select at least the remote if we have it
            am = 1;

        else
        {
            // If the TNT was already selected
            if (self.weapon == IT_TNT)
            {
                if (self.ammo_tnt_proxy > 0)
                    new = IT_PROXIMITY_BOMB;
                else if (self.items & IT_REMOTE_DETONATOR)
                    new = IT_REMOTE_DETONATOR;
                else
                    new = IT_TNT;
            }

            // Else, if the proximity bombs were already selected
            else if (self.weapon == IT_PROXIMITY_BOMB)
            {
                if (self.items & IT_REMOTE_DETONATOR)
                    new = IT_REMOTE_DETONATOR;
                else if (self.ammo_tnt_bundle > 0)
                    new = IT_TNT;
                else
                    new = IT_PROXIMITY_BOMB;
            }

            // Else (if the previous weapon was the remote detonators or a non-dynamite weapon)
            else
            {
                if (self.ammo_tnt_bundle > 0)
                    new = IT_TNT;
                else if (self.ammo_tnt_proxy > 0)
                    new = IT_PROXIMITY_BOMB;
                else
                    new = IT_REMOTE_DETONATOR;
            }
        }
    }
    else if (self.impulse == 7)
    {
        new = IT_SPRAY_CAN;
        if (self.ammo_spray < 1)
            am = 1;
    }
    else if (self.impulse == 8)
    {
        new = IT_TESLA_CANNON;
        if (self.ammo_cells < 1)
            am = 1;
    }
    else if (self.impulse == 9)
    {
        new = IT_LIFE_LEECH;
        // Life Leech doesn't need ammo
    }
    else if (self.impulse == 17)
    {
        new = IT_VOODOO_DOLL;
        if (self.ammo_voodoo < 1)
            am = 1;
    }

    self.impulse = 0;

    // don't have the weapon
    if (!(self.items & new))
    {
        sprint (self, "You don't have that weapon.\n");
        return;
    }

    // No TNT or spray can under water
    if (self.waterlevel == 3)
    {
        if (new == IT_TNT || new == IT_SPRAY_CAN)
        {
            sprint (self, "You can't select that weapon under water.\n");
            return;
        }
    }

    // don't have the ammo
    if (am)
    {
        sprint (self, "You are out of ammo.\n");
        return;
    }

    // If the weapon has really changed
    if (new != old)
        W_SwitchToWeapon (new);
};


/*
============
CycleWeaponCommand

Go to the next weapon with ammo
============
*/
void() CycleWeaponCommand =
{
    local   float   am, newWeapon;

    self.impulse = 0;
    newWeapon = self.weapon;

    // Don't let player change weapons while holding lit dynamite.
    if (self.tnt_time)
        return;
    while (1)
    {
        am = 0;

        if (newWeapon == IT_VOODOO_DOLL)
        {
            newWeapon = IT_PITCHFORK;
        }
        else if (newWeapon == IT_PITCHFORK)
        {
            newWeapon = IT_FLAREGUN;
            if (self.ammo_flares < 1)
                am = 1;
        }
        else if (newWeapon == IT_FLAREGUN)
        {
            newWeapon = IT_SAWED_OFF;
            if (self.ammo_shells < 1)
                am = 1;
        }
        else if (newWeapon == IT_SAWED_OFF)
        {
            newWeapon = IT_TOMMYGUN;
            if (self.ammo_nails < 1)
                am = 1;
        }
        else if (newWeapon == IT_TOMMYGUN)
        {
            newWeapon = IT_NAPALM_LAUNCHER;
            if (self.ammo_rockets < 1)
                am = 1;
        }
        else if (newWeapon == IT_NAPALM_LAUNCHER)
        {
            newWeapon = IT_TNT;
            // No TNT under water
            if (self.waterlevel == 3)
                am = 1;
            // No need to check the ammo (it's removed as soon as there's no more ammo)
        }
        else if (newWeapon == IT_TNT)
        {
            newWeapon = IT_PROXIMITY_BOMB;
            // No need to check the ammo (it's removed as soon as there's no more ammo)
        }
        else if (newWeapon == IT_PROXIMITY_BOMB)
        {
            newWeapon = IT_REMOTE_DETONATOR;
            // No need to check the ammo (it's removed as soon as there's
            // no more ammo and no remaining bombs to trigger)
        }
        else if (newWeapon == IT_REMOTE_DETONATOR)
        {
            newWeapon = IT_SPRAY_CAN;
            // No spray can under water
            if (self.ammo_spray < 1 || self.waterlevel == 3)
                am = 1;
        }
        else if (newWeapon == IT_SPRAY_CAN)
        {
            newWeapon = IT_TESLA_CANNON;
            if (self.ammo_cells < 1)
                am = 1;
        }
        else if (newWeapon == IT_TESLA_CANNON)
        {
            newWeapon = IT_LIFE_LEECH;
            // Life Leech doesn't need ammo
        }
        else if (newWeapon == IT_LIFE_LEECH)
        {
            newWeapon = IT_VOODOO_DOLL;
            if (self.ammo_voodoo < 1)
                am = 1;
        }

        if ( (self.items & newWeapon) && am == 0)
        {
            W_SwitchToWeapon (newWeapon);
            return;
        }
    }

};

/*
============
CycleWeaponReverseCommand

Go to the prev weapon with ammo
============
*/
void() CycleWeaponReverseCommand =
{
    local   float   am, newWeapon;

    self.impulse = 0;
    newWeapon = self.weapon;

    // Don't let player change weapons while holding lit dynamite.
    if (self.tnt_time)
        return;
    while (1)
    {
        am = 0;

        if (newWeapon == IT_VOODOO_DOLL)
        {
            newWeapon = IT_LIFE_LEECH;
            // Life Leech doesn't need ammo
        }
        else if (newWeapon == IT_LIFE_LEECH)
        {
            newWeapon = IT_TESLA_CANNON;
            if (self.ammo_cells < 1)
                am = 1;
        }
        else if (newWeapon == IT_TESLA_CANNON)
        {
            newWeapon = IT_SPRAY_CAN;
            if (self.ammo_spray < 2)
                am = 1;
        }
        else if (newWeapon == IT_SPRAY_CAN)
        {
            newWeapon = IT_REMOTE_DETONATOR;
            // No need to check the ammo (it's removed as soon as there's
            // no more ammo and no remaining bombs to trigger)
        }
        else if (newWeapon == IT_REMOTE_DETONATOR)
        {
            newWeapon = IT_PROXIMITY_BOMB;
            // No need to check the ammo (it's removed as soon as there's no more ammo)
        }
        else if (newWeapon == IT_PROXIMITY_BOMB)
        {
            newWeapon = IT_TNT;
            // No need to check the ammo (it's removed as soon as there's no more ammo)
        }
        else if (newWeapon == IT_TNT)
        {
            newWeapon = IT_NAPALM_LAUNCHER;
            if (self.ammo_rockets < 1)
                am = 1;
        }
        else if (newWeapon == IT_NAPALM_LAUNCHER)
        {
            newWeapon = IT_TOMMYGUN;
            if (self.ammo_nails < 1)
                am = 1;
        }
        else if (newWeapon == IT_TOMMYGUN)
        {
            newWeapon = IT_SAWED_OFF;
            if (self.ammo_shells < 1)
                am = 1;
        }
        else if (newWeapon == IT_SAWED_OFF)
        {
            newWeapon = IT_FLAREGUN;
            if (self.ammo_flares < 1)
                am = 1;
        }
        else if (newWeapon == IT_FLAREGUN)
        {
            newWeapon = IT_PITCHFORK;
        }
        else if (newWeapon == IT_PITCHFORK)
        {
            newWeapon = IT_VOODOO_DOLL;
            if (self.ammo_voodoo < 1)
                am = 1;
        }

        if ( (self.items & newWeapon) && am == 0)
        {
            W_SwitchToWeapon (newWeapon);
            return;
        }
    }

};


void() Cheat_Akimbo =
{
    self.akimbo_finished = time + 30;
    W_SetCurrentAmmo ();

    sprint (self, "Tequila!\n");
    dprint ("Akimbo cheat\n");
};


// PM:  Let's player change the armor shown if he has more than one armor.
void() ArmorTest =
{
    if (self.items & IT_ARMOR2)
    {
        if (self.armor_body)
        {
            self.armorvalue = self.armor_body;
            self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR1;
        }
        else if (self.armor_mind)
        {
            self.armorvalue = self.armor_mind;
            self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR3;
        }
    }
    else if (self.items & IT_ARMOR1)
    {
        if (self.armor_mind)
        {
            self.armorvalue = self.armor_mind;
            self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR3;
        }
        else if (self.armor_fire)
        {
            self.armorvalue = self.armor_fire;
            self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR2;
        }
    }
    else if (self.items & IT_ARMOR3)
    {
        if (self.armor_fire)
        {
            self.armorvalue = self.armor_fire;
            self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR2;
        }
        else if (self.armor_body)
        {
            self.armorvalue = self.armor_body;
            self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR1;
        }
    }
};


/*
============
W_WeaponFrame

Called every frame so impulse events can be handled as well as possible
============
*/
void() Impulses_Player;
float() W_FireCharge;
void() W_WeaponFrame =
{
    if (time < self.attack_finished)
        return;

    if (! W_AmmoAvailable ())
        if (self.player_state != PS_HOLD_FIRE)
        {
            W_SwitchToWeapon (W_BestWeapon ());
            return;
        }

    Impulses_Player ();

    if (W_FireCharge ())
        return;

    // Check for attack
    if (self.button0 || self.button3)
    {
        ResetIdle (self);
        W_Attack ();
    }
};
