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
entity() identify_player;


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
#ifdef QUAKEWORLD
void(vector org, float damage) QW_SpawnBlood =
{
    WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
    WriteByte (MSG_MULTICAST, TE_BLOOD);
    WriteByte (MSG_MULTICAST, 1);
    WriteCoord (MSG_MULTICAST, org_x);
    WriteCoord (MSG_MULTICAST, org_y);
    WriteCoord (MSG_MULTICAST, org_z);
    multicast (org, MULTICAST_PVS);
};
#else
void(vector org, vector vel, float damage) NQ_SpawnBlood =
{
    particle (org, vel*0.1, 73, damage*2);
};
#endif

/*
================
spawn_touchblood
================
*/
void(float damage) spawn_touchblood =
{
    local vector    vel;

    vel = wall_velocity () * 0.2;
    SpawnBlood (self.origin + vel*0.01, vel, damage);
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

    setmodel (missile, "progs/zom_gib.mdl");
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

#ifdef QUAKEWORLD
vector  blood_org;
float   blood_count;

vector  puff_org;
float   puff_count;
#endif

void() ClearMultiDamage =
{
    multi_ent = world;
    multi_damage = 0;
    #ifdef QUAKEWORLD
    blood_count = 0;
    puff_count = 0;
    #endif
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

#ifdef QUAKEWORLD
void() Multi_Finish =
{
    if (puff_count)
    {
        WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
        WriteByte (MSG_MULTICAST, TE_GUNSHOT);
        WriteByte (MSG_MULTICAST, puff_count);
        WriteCoord (MSG_MULTICAST, puff_org_x);
        WriteCoord (MSG_MULTICAST, puff_org_y);
        WriteCoord (MSG_MULTICAST, puff_org_z);
        multicast (puff_org, MULTICAST_PVS);
    }

    if (blood_count)
    {
        WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
        WriteByte (MSG_MULTICAST, TE_BLOOD);
        WriteByte (MSG_MULTICAST, blood_count);
        WriteCoord (MSG_MULTICAST, blood_org_x);
        WriteCoord (MSG_MULTICAST, blood_org_y);
        WriteCoord (MSG_MULTICAST, blood_org_z);
        multicast (puff_org, MULTICAST_PVS);
    }
};
#endif

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
        #ifdef QUAKEWORLD
        blood_count = blood_count + 1;
        blood_org = org;
        #else
        SpawnBlood (org, vel*0.2, damage);
        #endif
        SpawnBloodSpray (trace_ent, org);
    }
    else
    {
        #ifdef QUAKEWORLD
        puff_count = puff_count + 1;
        #else
        WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte (MSG_BROADCAST, TE_GUNSHOT);
        WriteCoord (MSG_BROADCAST, org_x);
        WriteCoord (MSG_BROADCAST, org_y);
        WriteCoord (MSG_BROADCAST, org_z);
        #endif
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

    #ifdef QUAKEWORLD
    traceline (src, src + dir*2048, FALSE, self);
    puff_org = trace_endpos - dir*4;
    #endif

    while (shotcount > 0)
    {
        direction = dir + crandom()*spread_x*v_right + crandom()*spread_y*v_up;

        traceline (src, src + direction*2048, FALSE, self);
        if (trace_fraction != 1.0)
            TraceAttack (damage, direction);

        shotcount = shotcount - 1;
    }
    ApplyMultiDamage ();

    #ifdef QUAKEWORLD
    Multi_Finish ();
    #endif
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
    shell.nextthink = time + 1.5;
    shell.think = SUB_Remove;
    shell.ltime = time - 1;
};


/*
==============================================================================

ROCKETS

==============================================================================
*/

void(entity client) ResetIdle =
{
    client.idle_done = FALSE;
    client.idle_time = time + 10 + random() * 10;  // 10-20 sec.
};

// This makes the player rave.
void(entity client) BoredCaleb =
{
    if (client.health <= 0)
        return;
    if (client.deadflag)
        return;
    if (client.classname != "player")
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

    sound (client, CHAN_VOICE, playit, 1, ATTN_NORM);
};

// This makes the player laugh or utter one of Caleb's signature one-liners.
void(entity client) PsychoCaleb =
{
    if (random() > 0.15)
        return;     // Only 15% chance per call.
    if (client.health <= 0)
        return;
    if (client.deadflag)
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

    sound (client, CHAN_BODY, playit, 1, ATTN_NORM);
};

// This creates a blank entity that inflicts burn damage for several
// frames.  Refers to code in 'fire.qc'

void() BlastDamageThink =
{
    BurnRadius (self, self.dmg, self.cnt, world);

    // Damage decreases each frame to a minimum of 5.
    if (self.dmg > 5)
    {
        if (self.dmg < 15)
            self.dmg = 5;
        else
            self.dmg = self.dmg - 10;
    }
    self.cnt = 5;   // Burn up to a half second per frame.

    self.delay = self.delay - 1;
    if (self.delay <= 0)
    {
        remove (self);
        return;
    }

    self.nextthink = time + 0.1;
};

void(entity inflictor, float radius, float damage, float burn) MakeBlastDamage =
{
    local   entity  blast;

    blast = spawn();

    setorigin (blast, inflictor.origin);
    setmodel (blast, string_null);
    setsize (blast, VEC_ORIGIN, VEC_ORIGIN);

    blast.solid     = SOLID_NOT;
    blast.movetype  = MOVETYPE_NONE;
    blast.velocity  = '0 0 0';
    blast.touch     = SUB_Null;

    blast.owner     = inflictor.owner;
    blast.height    = radius;
    blast.dmg       = damage;
    blast.cnt       = burn;
    blast.delay     = 7;    // Damage for seven frames.

    blast.nextthink = time + 0.1;
    blast.think     = BlastDamageThink;
};

#ifndef QUAKEWORLD
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
    s_explode1 ();
};
#endif


/*
===============================================================================

LIGHTNING

===============================================================================
*/

void(entity from, float damage) LightningHit =
{
    #ifdef QUAKEWORLD
    WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
    WriteByte (MSG_MULTICAST, TE_LIGHTNINGBLOOD);
    WriteCoord (MSG_MULTICAST, trace_endpos_x);
    WriteCoord (MSG_MULTICAST, trace_endpos_y);
    WriteCoord (MSG_MULTICAST, trace_endpos_z);
    multicast (trace_endpos, MULTICAST_PVS);

    #else
    particle (trace_endpos, '0 0 100', 225, damage*4);
    #endif

    T_Damage (trace_ent, from, from, damage, DF_FIRE, string_null);
};

/*
=================
LightningDamage
=================
*/
void(vector p1, vector p2, entity from, float damage) LightningDamage =
{
//  PM:  Function mostly rewritten.
//
//  What did the old code suppose to do?  Hit three different targets
//  in row ala railgun?  Make the beam wider?  Whatever it was supposed
//  to do, it didn't work.  Therefore, I simplified the code.
//  Also, the +400 up vector to 'other' code in player vs. player
//  Thunderbolt battles doesn't work either, so I removed it.

    traceline (p1, p2, FALSE, self);
    if (trace_ent.takedamage)
        LightningHit (from, damage);
};


//=============================================================================

void() spike_touch;
void() superspike_touch;


/*
===============
launch_spike

Used for both the player and the ogre
===============
*/
void(vector org, vector dir) launch_spike =
{
    newmis = spawn ();
    #ifdef QUAKEWORLD
    newmis.voided=0;
    #endif
    newmis.owner = self;
    newmis.movetype = MOVETYPE_FLYMISSILE;
    newmis.solid = SOLID_BBOX;

    newmis.angles = vectoangles(dir);

    newmis.touch = spike_touch;
    newmis.classname = "spike";
    newmis.think = SUB_Remove;
    newmis.nextthink = time + 6;
    setmodel (newmis, "progs/spike.mdl");
    setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
    setorigin (newmis, org);

    newmis.velocity = dir * 2000;
};

void() flame_touch =
{
    local float rand;

    if (other == self.owner)
        return;

    #ifdef QUAKEWORLD
    if (self.voided) {
        return;
    }
    self.voided = 1;
    #endif

    if (other.solid == SOLID_TRIGGER)
        return; // trigger field, do nothing

    if (pointcontents(self.origin) == CONTENT_SKY)
    {
        remove(self);
        return;
    }

    // hit something that bleeds
    if (other.takedamage)
        BurnDamage (other, self, 5, 30);

    remove(self);

};


void() spike_touch =
{
local float rand;
    if (other == self.owner)
        return;

    #ifdef QUAKEWORLD
    if (self.voided) {
        return;
    }
    self.voided = 1;
    #endif

    if (other.solid == SOLID_TRIGGER)
        return; // trigger field, do nothing

    if (pointcontents(self.origin) == CONTENT_SKY)
    {
        remove(self);
        return;
    }

// hit something that bleeds
    if (other.takedamage)
    {
        spawn_touchblood (9);
        other.deathtype = "nail";
        T_Damage (other, self, self.owner, 9, DF_BODY, string_null);
    }
    else
    {
        #ifdef QUAKEWORLD
        WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
        if (self.classname == "wizspike")
            WriteByte (MSG_MULTICAST, TE_WIZSPIKE);
        else if (self.classname == "knightspike")
            WriteByte (MSG_MULTICAST, TE_KNIGHTSPIKE);
        else
            WriteByte (MSG_MULTICAST, TE_SPIKE);
        WriteCoord (MSG_MULTICAST, self.origin_x);
        WriteCoord (MSG_MULTICAST, self.origin_y);
        WriteCoord (MSG_MULTICAST, self.origin_z);
        multicast (self.origin, MULTICAST_PHS);

        #else
        WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);

        if (self.classname == "wizspike")
            WriteByte (MSG_BROADCAST, TE_WIZSPIKE);
        else if (self.classname == "knightspike")
            WriteByte (MSG_BROADCAST, TE_KNIGHTSPIKE);
        else
            WriteByte (MSG_BROADCAST, TE_SPIKE);
        WriteCoord (MSG_BROADCAST, self.origin_x);
        WriteCoord (MSG_BROADCAST, self.origin_y);
        WriteCoord (MSG_BROADCAST, self.origin_z);
        #endif
    }

    remove(self);

};

void() superspike_touch =
{
local float rand;
    if (other == self.owner)
        return;

    #ifdef QUAKEWORLD
    if (self.voided) {
        return;
    }
    self.voided = 1;
    #endif

    if (other.solid == SOLID_TRIGGER)
        return; // trigger field, do nothing

    if (pointcontents(self.origin) == CONTENT_SKY)
    {
        remove(self);
        return;
    }

// hit something that bleeds
    if (other.takedamage)
    {
        spawn_touchblood (18);
        other.deathtype = "supernail";
        T_Damage (other, self, self.owner, 18, DF_BODY, string_null);
    }
    else
    {
        #ifdef QUAKEWORLD
        WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
        WriteByte (MSG_MULTICAST, TE_SUPERSPIKE);
        WriteCoord (MSG_MULTICAST, self.origin_x);
        WriteCoord (MSG_MULTICAST, self.origin_y);
        WriteCoord (MSG_MULTICAST, self.origin_z);
        multicast (self.origin, MULTICAST_PHS);

        #else
        WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte (MSG_BROADCAST, TE_SUPERSPIKE);
        WriteCoord (MSG_BROADCAST, self.origin_x);
        WriteCoord (MSG_BROADCAST, self.origin_y);
        WriteCoord (MSG_BROADCAST, self.origin_z);
        #endif
    }

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
};


/*
====================
W_SwitchToWeapon

Switch to another player's weapon
====================
*/
void(float newWeapon) W_SwitchToWeapon =
{
    if (! (self.items & newWeapon))
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
        self.weaponmodel = "";
    }
};


float() W_BestWeapon =
{
    local   float   it;

    it = self.items;

    if(self.ammo_rockets >= 1 && (it & IT_NAPALM_LAUNCHER) )
        return IT_NAPALM_LAUNCHER;
    if (self.waterlevel <= 1 && self.ammo_cells >= 1 && (it & IT_TESLA_CANNON) )
        return IT_TESLA_CANNON;
    if(self.ammo_leech >= 1 && (it & IT_LIFE_LEECH) )
        return IT_LIFE_LEECH;
    if(self.ammo_spray >= 1 && (it & IT_SPRAY_CAN) )
        return IT_SPRAY_CAN;
    if(self.ammo_tnt_bundle >= 1 && (it & IT_TNT) )
        return IT_TNT;
    if(self.ammo_shells >= 1 && (it & IT_SAWED_OFF) )
        return IT_SAWED_OFF;
    if(self.ammo_nails >= 1 && (it & IT_TOMMYGUN) )
        return IT_TOMMYGUN;
    if(self.ammo_flares >= 1 && (it & IT_FLAREGUN) )
        return IT_FLAREGUN;
    if(self.ammo_voodoo >= 1 && (it & IT_VOODOO_DOLL) )
        return IT_VOODOO_DOLL;

    return IT_PITCHFORK;
};

float() W_AmmoAvailable =
{
    if (self.currentammo > 0 || self.weapon == IT_PITCHFORK)
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
    if (! W_AmmoAvailable ())
    {
        if (self.weapon == IT_TOMMYGUN)
            sound (self, CHAN_WEAPON, "weapons/tommygun/tomcock.wav", 1, ATTN_NORM);

        self.attack_finished = time + 0.5;
        self.impulse = 0;
        return;
    }

    makevectors (self.v_angle);    // calculate forward angle for velocity
    self.show_hostile = time + 1;  // wake monsters up

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
        new = IT_VOODOO_DOLL;
        if (self.ammo_voodoo < 1)
            am = 1;
    }
    else if (self.impulse == 17)
    {
        new = IT_LIFE_LEECH;
        if (self.ammo_leech < 1)
            am = 1;
    }

    self.impulse = 0;

    // don't have the weapon
    if (!(self.items & new))
    {
        Sprint (self, PRINT_MEDIUM, "You don't have that weapon.\n");
        return;
    }

    // don't have the ammo
    if (am)
    {
        Sprint (self, PRINT_MEDIUM, "You are out of ammo.\n");
        return;
    }

    // If the weapon has really changed
    if (new != old)
        W_SwitchToWeapon (new);
};


/*
============
CheatCommand
============
*/
void() CheatCommand =
{
    self.ammo_flares     = MAX_FLARES;
    self.ammo_shells     = MAX_SHELLS;
    self.ammo_nails      = MAX_NAILS;
    self.ammo_rockets    = MAX_ROCKETS;
    self.ammo_tnt_bundle = MAX_TNT;
    self.ammo_tnt_proxy  = MAX_PROXY;
    self.ammo_tnt_remote = MAX_REMOTE;
    self.ammo_spray      = MAX_SPRAY;
    self.ammo_cells      = MAX_CELLS;
    self.ammo_voodoo     = MAX_VOODOO;
    self.ammo_leech      = MAX_LEECH;

    self.items = self.items |
        IT_PITCHFORK |
        IT_FLAREGUN |
        IT_SAWED_OFF |
        IT_TOMMYGUN |
        IT_SPRAY_CAN |
        IT_TNT |
        IT_PROXIMITY_BOMB |
        IT_REMOTE_DETONATOR |
        IT_NAPALM_LAUNCHER |
        IT_TESLA_CANNON |
        IT_VOODOO_DOLL |
        IT_LIFE_LEECH;
    self.items2 = self.items2 |
        IT2_KEY1 | IT2_KEY2;

    // FIXME: we should precache all the weapons sounds

    W_SwitchToWeapon (IT_NAPALM_LAUNCHER);
    self.impulse = 0;
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

        if (newWeapon == IT_LIFE_LEECH)
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
            if (self.ammo_spray < 1)
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
            newWeapon = IT_VOODOO_DOLL;
            if (self.ammo_voodoo < 1)
                am = 1;
        }
        else if (newWeapon == IT_VOODOO_DOLL)
        {
            newWeapon = IT_LIFE_LEECH;
            if (self.ammo_leech < 1)
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

        if (newWeapon == IT_LIFE_LEECH)
        {
            newWeapon = IT_VOODOO_DOLL;
            if (self.ammo_voodoo < 1)
                am = 1;
        }
        else if (newWeapon == IT_VOODOO_DOLL)
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
            newWeapon = IT_LIFE_LEECH;
            if (self.ammo_leech < 1)
                am = 1;
        }

        if ( (self.items & newWeapon) && am == 0)
        {
            W_SwitchToWeapon (newWeapon);
            return;
        }
    }

};


void() QuadCheat =
{
    self.akimbo_finished = time + 30;
    W_SetCurrentAmmo ();

    Sprint (self, PRINT_MEDIUM, "Tequila !\n");
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
ImpulseCommands

============
*/
void() ImpulseCommands =
{
    if ((self.impulse >= 1 && self.impulse <= 9) || self.impulse == 17)
        W_ChangeWeapon ();

    else if (self.impulse == 10)
        CycleWeaponCommand ();
    else if (self.impulse == 11)
        CycleWeaponReverseCommand ();

    // Altfire (will be treated later; just return)
    else if (self.impulse == 12)
        return;

    // Inventory selection/usage.
    else if (self.impulse == 13)
        InvenUse ();
    else if (self.impulse == 14)
        InvenSelect (FALSE);
    else if (self.impulse == 15)
        InvenSelect (TRUE);

    // Armor cycle.
    else if (self.impulse == 16)
        ArmorTest ();

    else if (self.impulse == 50)
        Menu_Start ();

    else if (self.impulse == 141)
        identify_player ();

    // Cheat codes are only allowed when the "sv_allowCheat" cvar is set
    else if (cvar ("sv_allowCheat"))
    {
        if (self.impulse == 250)
        {
            coredump ();
        }
        else if (self.impulse == 251)
        {
            Sprint (self, PRINT_MEDIUM, "griswold -- You have full armor.\n");
            self.armor_fire = self.armor_body = self.armor_mind = self.armorvalue = 200;
            self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR2;
        }
        else if (self.impulse == 252)
        {
            Sprint (self, PRINT_MEDIUM, "mcgee -- You're fired!\n");
            Ignite (self, self, 200);
        }
        else if (self.impulse == 253)
            InvenCheat ();
        else if (self.impulse == 254)
            CheatCommand ();
        else if (self.impulse == 255)
            QuadCheat ();
    }

    self.impulse = 0;
};

/*
============
W_WeaponFrame

Called every frame so impulse events can be handled as well as possible
============
*/
float() W_FireCharge;
void() W_WeaponFrame =
{
    if (time < self.attack_finished)
        return;

    ImpulseCommands ();

    if (W_FireCharge ())
        return;

    // Check for attack
    if (self.button0 || self.button1 || self.impulse == 12)
    {
        ResetIdle (self);
        W_Attack ();
    }
};
