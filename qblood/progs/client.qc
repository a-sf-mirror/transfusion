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


// prototypes
void () W_WeaponFrame;
void() W_SetCurrentAmmo;
void() player_pain;
void() player_stand1;
void (vector org) spawn_tfog;
void (vector org, entity death_owner) spawn_tdeath;
void() CTF_PlayerDropFlag;
entity() CTF_Spawn;

float   modelindex_eyes, modelindex_player;

/*
=============================================================================

                LEVEL CHANGING / INTERMISSION

=============================================================================
*/

string nextmap;

float   intermission_running;
float   intermission_exittime;

/*QUAKED info_intermission (1 0.5 0.5) (-16 -16 -16) (16 16 16)
This is the camera point for the intermission.
Use mangle instead of angle, so you can set pitch or roll as well as yaw.  'pitch roll yaw'
*/
void() info_intermission =
{
    #ifdef QUAKEWORLD
    self.angles = self.mangle;      // so C can get at it
    #endif
};

void() SetChangeParms =
{
    if (self.health <= 0)
    {
        SetNewParms ();
        return;
    }

    // remove items
    self.items  = self.items  - (self.items  & (IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD));
    self.items2 = self.items2 - (self.items2 & (IT2_KEY1 | IT2_KEY2));

    // PM:  Recharge inventory, except for first-aid.
    InvenRecharge ();

// cap super health
    if (self.health > 200)
        self.health = 200;
    if (self.health < 1)
        self.health = 100;
    parm1 = self.items;
    parm2 = self.health;
    parm3 = self.ammo_shells;
    parm4 = self.ammo_nails;
    parm5 = self.ammo_rockets;
    parm6 = self.ammo_cells;
    parm7 = self.weapon;
    parm8 = self.armor_fire;
    parm9 = self.armor_body;
    parm10 = self.armor_mind;
    parm11 = self.inven1;
    parm12 = self.inven2;
    parm13 = self.it_select;
};

void() SetNewParms =
{
    parm1 = IT_AXE;
    parm2 = 100;
    parm3 = 0;
    parm4 = 0;
    parm5 = 0;
    parm6 = 0;
    parm7 = IT_AXE;
    parm8 = 0;
    parm9 = 0;
    parm10 = 0;
    parm11 = 0;
    parm12 = 0;
    parm13 = 0;
};

void() DecodeLevelParms =
{
    if (serverflags)
    {
        if (world.model == "maps/start.bsp")
            SetNewParms ();     // take away all stuff on starting new episode
    }

    self.items          = parm1;
    self.health         = parm2;
    self.ammo_shells    = parm3;
    self.ammo_nails     = parm4;
    self.ammo_rockets   = parm5;
    self.ammo_cells     = parm6;
    self.weapon         = parm7;
    self.armor_fire     = parm8;
    self.armor_body     = parm9;
    self.armor_mind     = parm10;
    self.inven1         = parm11;
    self.inven2         = parm12;
    self.it_select      = parm13;

    if (self.items & IT_ARMOR1)
        self.armorvalue = self.armor_body;
    else if (self.items & IT_ARMOR2)
        self.armorvalue = self.armor_fire;
    else if (self.items & IT_ARMOR3)
        self.armorvalue = self.armor_mind;
    else
        self.armorvalue = 0;
};

/*
============
FindIntermission

Returns the entity to view from
============
*/
entity() FindIntermission =
{
    local   entity spot;
    local   float cyc;

// look for info_intermission first
    spot = find (world, classname, "info_intermission");
    if (spot)
    {   // pick a random one
        cyc = random() * 4;
        while (cyc > 1)
        {
            spot = find (spot, classname, "info_intermission");
            if (!spot)
                spot = find (spot, classname, "info_intermission");
            cyc = cyc - 1;
        }
        return spot;
    }

// then look for the start position
    spot = find (world, classname, "info_player_start");
    if (spot)
        return spot;

    #ifndef QUAKEWORLD
    // testinfo_player_start is only found in regioned levels
    spot = find (world, classname, "testplayerstart");
    if (spot)
        return spot;
    #endif

    objerror ("FindIntermission: no spot");
};


void() GotoNextMap =
{
    #ifdef QUAKEWORLD
    local string newmap;

    //ZOID: 12-13-96, samelevel is overloaded, only 1 works for same level
    if (cvar("samelevel") == 1)     // if samelevel is set, stay on same level
        changelevel (mapname);
    else {
        // configurable map lists, see if the current map exists as a
        // serverinfo/localinfo var
        newmap = infokey(world, mapname);
        if (newmap != "")
            changelevel (newmap);
        else
            changelevel (nextmap);
    }

    #else
    if (cvar("samelevel"))  // if samelevel is set, stay on same level
        changelevel (mapname);
    else
        changelevel (nextmap);
    #endif
};


#ifndef QUAKEWORLD
void() ExitIntermission =
{
// skip any text in deathmatch
    if (deathmatch)
    {
        GotoNextMap ();
        return;
    }

    intermission_exittime = time + 1;
    intermission_running = intermission_running + 1;

//
// run some text if at the end of an episode
//
    if (intermission_running == 2)
    {
        if (world.model == "maps/e1m7.bsp")
        {
            WriteByte (MSG_ALL, SVC_CDTRACK);
            WriteByte (MSG_ALL, 2);
            WriteByte (MSG_ALL, 3);
            if (!cvar("registered"))
            {
                WriteByte (MSG_ALL, SVC_FINALE);
                WriteString (MSG_ALL, "As the corpse of the monstrous entity\nChthon sinks back into the lava whence\nit rose, you grip the Rune of Earth\nMagic tightly. Now that you have\nconquered the Dimension of the Doomed,\nrealm of Earth Magic, you are ready to\ncomplete your task in the other three\nhaunted lands of Quake. Or are you? If\nyou don't register Quake, you'll never\nknow what awaits you in the Realm of\nBlack Magic, the Netherworld, and the\nElder World!");
            }
            else
            {
                WriteByte (MSG_ALL, SVC_FINALE);
                WriteString (MSG_ALL, "As the corpse of the monstrous entity\nChthon sinks back into the lava whence\nit rose, you grip the Rune of Earth\nMagic tightly. Now that you have\nconquered the Dimension of the Doomed,\nrealm of Earth Magic, you are ready to\ncomplete your task. A Rune of magic\npower lies at the end of each haunted\nland of Quake. Go forth, seek the\ntotality of the four Runes!");
            }
            return;
        }
        else if (world.model == "maps/e2m6.bsp")
        {
            WriteByte (MSG_ALL, SVC_CDTRACK);
            WriteByte (MSG_ALL, 2);
            WriteByte (MSG_ALL, 3);

            WriteByte (MSG_ALL, SVC_FINALE);
            WriteString (MSG_ALL, "The Rune of Black Magic throbs evilly in\nyour hand and whispers dark thoughts\ninto your brain. You learn the inmost\nlore of the Hell-Mother; Shub-Niggurath!\nYou now know that she is behind all the\nterrible plotting which has led to so\nmuch death and horror. But she is not\ninviolate! Armed with this Rune, you\nrealize that once all four Runes are\ncombined, the gate to Shub-Niggurath's\nPit will open, and you can face the\nWitch-Goddess herself in her frightful\notherworld cathedral.");
            return;
        }
        else if (world.model == "maps/e3m6.bsp")
        {
            WriteByte (MSG_ALL, SVC_CDTRACK);
            WriteByte (MSG_ALL, 2);
            WriteByte (MSG_ALL, 3);

            WriteByte (MSG_ALL, SVC_FINALE);
            WriteString (MSG_ALL, "The charred viscera of diabolic horrors\nbubble viscously as you seize the Rune\nof Hell Magic. Its heat scorches your\nhand, and its terrible secrets blight\nyour mind. Gathering the shreds of your\ncourage, you shake the devil's shackles\nfrom your soul, and become ever more\nhard and determined to destroy the\nhideous creatures whose mere existence\nthreatens the souls and psyches of all\nthe population of Earth.");
            return;
        }
        else if (world.model == "maps/e4m7.bsp")
        {
            WriteByte (MSG_ALL, SVC_CDTRACK);
            WriteByte (MSG_ALL, 2);
            WriteByte (MSG_ALL, 3);

            WriteByte (MSG_ALL, SVC_FINALE);
            WriteString (MSG_ALL, "Despite the awful might of the Elder\nWorld, you have achieved the Rune of\nElder Magic, capstone of all types of\narcane wisdom. Beyond good and evil,\nbeyond life and death, the Rune\npulsates, heavy with import. Patient and\npotent, the Elder Being Shub-Niggurath\nweaves her dire plans to clear off all\nlife from the Earth, and bring her own\nfoul offspring to our world! For all the\ndwellers in these nightmare dimensions\nare her descendants! Once all Runes of\nmagic power are united, the energy\nbehind them will blast open the Gateway\nto Shub-Niggurath, and you can travel\nthere to foil the Hell-Mother's plots\nin person.");
            return;
        }

        GotoNextMap();
    }

    if (intermission_running == 3)
    {
        if (!cvar("registered"))
        {   // shareware episode has been completed, go to sell screen
            WriteByte (MSG_ALL, SVC_SELLSCREEN);
            return;
        }

        if ( (serverflags&15) == 15)
        {
            WriteByte (MSG_ALL, SVC_FINALE);
            WriteString (MSG_ALL, "Now, you have all four Runes. You sense\ntremendous invisible forces moving to\nunseal ancient barriers. Shub-Niggurath\nhad hoped to use the Runes Herself to\nclear off the Earth, but now instead,\nyou will use them to enter her home and\nconfront her as an avatar of avenging\nEarth-life. If you defeat her, you will\nbe remembered forever as the savior of\nthe planet. If she conquers, it will be\nas if you had never been born.");
            return;
        }

    }

    GotoNextMap();
};
#endif

/*
============
IntermissionThink

When the player presses attack or jump, change to the next level
============
*/
void() IntermissionThink =
{
    if (time < intermission_exittime)
        return;

    if (!self.button0 && !self.button1 && !self.button2)
        return;

    #ifdef QUAKEWORLD
    GotoNextMap ();
    #else
    ExitIntermission ();
    #endif
};

/*
============
execute_changelevel

The global "nextmap" has been set previously.
Take the players to the intermission spot
============
*/
void() execute_changelevel =
{
    local entity    pos;

    intermission_running = 1;

// enforce a wait time before allowing changelevel
    #ifndef QUAKEWORLD
    if (! deathmatch)
        intermission_exittime = time + 2;
    else
    #endif
        intermission_exittime = time + 5;

    pos = FindIntermission ();

    WriteByte (MSG_ALL, SVC_CDTRACK);
    WriteByte (MSG_ALL, 3);

    #ifndef QUAKEWORLD
    WriteByte (MSG_ALL, 3);  // FIXME: molivier: Isn't it an error ? (we send '3' 2 times)

    #else
    WriteByte (MSG_ALL, SVC_INTERMISSION);
    WriteCoord (MSG_ALL, pos.origin_x);
    WriteCoord (MSG_ALL, pos.origin_y);
    WriteCoord (MSG_ALL, pos.origin_z);
    WriteAngle (MSG_ALL, pos.mangle_x);
    WriteAngle (MSG_ALL, pos.mangle_y);
    WriteAngle (MSG_ALL, pos.mangle_z);
    #endif

    other = find (world, classname, "player");
    while (other != world)
    {
        #ifndef QUAKEWORLD
        PM_KillBurner (other);
        other.view_ofs = '0 0 0';
        other.angles = other.v_angle = pos.mangle;
        other.fixangle = TRUE;      // turn this way immediately
        other.nextthink = time + 0.5;
        #endif

        other.takedamage = DAMAGE_NO;
        other.solid = SOLID_NOT;
        other.movetype = MOVETYPE_NONE;
        other.modelindex = 0;

        #ifndef QUAKEWORLD
        setorigin (other, pos.origin);
        #endif
        other = find (other, classname, "player");
    }

    #ifndef QUAKEWORLD
    WriteByte (MSG_ALL, SVC_INTERMISSION);
    #endif
};


void() changelevel_touch =
{
    local entity    pos;

    if (other.classname != "player")
        return;

    // if "noexit" is set, blow up the player trying to leave
    #ifdef QUAKEWORLD
    //ZOID, 12-13-96, noexit isn't supported in QW.  Overload samelevel
    if ((cvar("samelevel") == 2) || ((cvar("samelevel") == 3) && (mapname != "start")))
    #else
    if ((cvar("noexit") == 1) || ((cvar("noexit") == 2) && (mapname != "start")))
    #endif
    {
        T_Damage (other, self, self, 50000);
        return;
    }

    #ifndef QUAKEWORLD
    if (coop || deathmatch)
    {
    #endif
        Bprint (PRINT_HIGH, other.netname);
        Bprint (PRINT_HIGH," checked out for good\n");
    #ifndef QUAKEWORLD
    }
    #endif

    nextmap = self.map;

    SUB_UseTargets ();

    #ifndef QUAKEWORLD
    if ( (self.spawnflags & 1) && (deathmatch == 0) )
    {   // NO_INTERMISSION
        GotoNextMap();
        return;
    }
    #endif

    self.touch = SUB_Null;

// we can't move people right now, because touch functions are called
// in the middle of C movement code, so set a think time to do it
    self.think = execute_changelevel;
    self.nextthink = time + 0.1;
};

/*QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player touches this, he gets sent to the map listed in the "map" variable.  Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
*/
void() trigger_changelevel =
{
    if (!self.map)
        objerror ("changelevel trigger doesn't have map");

    InitTrigger ();
    self.touch = changelevel_touch;
};


/*
=============================================================================

                PLAYER GAME EDGE FUNCTIONS

=============================================================================
*/

void() set_suicide_frame;

// called by ClientKill and DeadThink
void() respawn =
{
    #ifndef QUAKEWORLD
    if (coop)
    {
        // make a copy of the dead body for appearances sake
        CloneCorpse (self);
        // get the spawn parms as they were at level start
        setspawnparms (self);
        // respawn
        PutClientInServer ();
    }
    else if (deathmatch)
    {
    #endif
        // make a copy of the dead body for appearances sake
        CloneCorpse (self);
        // set default spawn parms
        SetNewParms ();
        // respawn
        PutClientInServer ();
    #ifndef QUAKEWORLD
    }
    else
    {   // restart the entire server
        localcmd ("restart\n");
    }
    #endif
};


/*
============
ClientKill

Player entered the suicide command
============
*/
void() ClientKill =
{
    // can't suicide when observer
    if (self.observer)
        return;

    Bprint (PRINT_MEDIUM, "Kevorkian approves!\n");
    sound (self, CHAN_AUTO, "thevoice/vo5.wav", 1, ATTN_NORM);
    CTF_PlayerDropFlag ();
    set_suicide_frame ();
    self.modelindex = modelindex_player;
    #ifdef QUAKEWORLD
    logfrag (self, self);
    #endif
    self.frags = self.frags - 2;    // extra penalty
    respawn ();
};

float(vector v) CheckSpawnPoint =
{
    return FALSE;
};

/*
============
SelectSpawnPoint

Returns the entity to spawn at
============
*/
entity() SelectSpawnPoint =
{
    // testinfo_player_start is only found in regioned levels
    lastspawn = find (world, classname, "testplayerstart");
    if (lastspawn)
        return lastspawn;

    // If we're in a deathmatch
    #ifndef QUAKEWORLD
    if (deathmatch)
    {
    #endif
        local float totalspots;

        // If it's a CTF game, try to spawn on one of the team's points
        if (deathmatch == 2)
        {
            lastspawn = CTF_Spawn ();
            if (lastspawn != world)
                return lastspawn;
        }

        // Get a list of all DM spots
        totalspots = 0;
        lastspawn = find (world, classname, "info_player_deathmatch");
        while (lastspawn)
        {
            totalspots = totalspots + 1;
            lastspawn = find (lastspawn, classname, "info_player_deathmatch");
        }

        // Choose one at random
        if (totalspots > 0)
        {
            totalspots = rint((random() * (totalspots - 1)));
            lastspawn = find (world, classname, "info_player_deathmatch");
            while (totalspots > 0) {
                totalspots = totalspots - 1;
                lastspawn = find (lastspawn, classname, "info_player_deathmatch");
            }
            return lastspawn;
        }
    #ifndef QUAKEWORLD
    }

    // If we're in a SP coop game
    else if (coop)
    {
        lastspawn = find (lastspawn, classname, "info_player_coop");
        if (lastspawn == world)
            lastspawn = find (world, classname, "info_player_coop");
        if (lastspawn != world)
            return lastspawn;
    }

    // If we have a least one rune in a SP game
    if (serverflags && !deathmatch)
    {
        lastspawn = find (world, classname, "info_player_start2");
        if (lastspawn)
            return lastspawn;
    }
    #endif

    // We haven't found a suitable spawn point, so we take the SP one
    lastspawn = find (world, classname, "info_player_start");
    if (! lastspawn)
        error ("PutClientInServer: no info_player_start on level");

    return lastspawn;
};


void() DecodeLevelParms;
void() PlayerDie;


#ifdef QUAKEWORLD
/*
===========
ValidateUser

FIXME: molivier: What is this function ? It seems to be unused ? It could be CTF stuff.
============
*
float(entity e) ValidateUser =
{
    local string    s;
    local string    userclan;
    local float     rank, rankmin, rankmax;

//
// if the server has set "clan1" and "clan2", then it
// is a clan match that will allow only those two clans in
//
    s = serverinfo("clan1");
    if (s)
    {
        userclan = masterinfo(e,"clan");
        if (s == userclan)
            return true;
        s = serverinfo("clan2");
        if (s == userclan)
            return true;
        return false;
    }

//
// if the server has set "rankmin" and/or "rankmax" then
// the users rank must be between those two values
//
    s = masterinfo (e, "rank");
    rank = stof (s);

    s = serverinfo("rankmin");
    if (s)
    {
        rankmin = stof (s);
        if (rank < rankmin)
            return false;
    }
    s = serverinfo("rankmax");
    if (s)
    {
        rankmax = stof (s);
        if (rankmax < rank)
            return false;
    }

    return true;
};
*/
#endif


/*
===========
PutClientInServer

called each time a player is spawned
============
*/
void() PutClientInServer =
{
    local   entity spot;

    spot = SelectSpawnPoint ();

    self.classname = "player";
    self.health = 100;
    self.takedamage = DAMAGE_AIM;
    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_WALK;
    self.show_hostile = 0;
    self.max_health = 100;
    self.flags = FL_CLIENT;
    self.air_finished = time + 12;
    self.dmg = 2;           // initial water damage
    self.super_damage_finished = 0;
    self.radsuit_finished = 0;
    self.invisible_finished = 0;
    self.invincible_finished = 0;
    self.effects = 0;
    self.invincible_time = 0;
    PM_KillBurner (other);
// fixme2
    self.reflect_finished = 0;
    self.remain_dmg = 0;
    self.remain_arm = 0;

    W_Uncharge ();
    PM_ResetIdle (self);

    DecodeLevelParms ();

    self.attack_finished = time;
    self.th_pain = player_pain;
    self.th_die = PlayerDie;

    self.deadflag = DEAD_NO;
// paustime is set by teleporters to keep the player from moving a while
    self.pausetime = 0;

    self.origin = spot.origin + '0 0 1';
    self.angles = spot.angles;
    self.fixangle = TRUE;       // turn this way immediately

// oh, this is a hack!
    setmodel (self, "progs/eyes.mdl");
    modelindex_eyes = self.modelindex;

    setmodel (self, "progs/player.mdl");
    modelindex_player = self.modelindex;

    setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);

    self.view_ofs = '0 0 22';

    // Mod - Xian (May.20.97)
    // Bug where player would have velocity from their last kill
    self.velocity = '0 0 0';

    player_stand1 ();

    if (self.do_observer)
    {
        BecomeObserver (self);
        return;
    }

    #ifndef QUAKEWORLD
    if (deathmatch || coop)
    {
    #endif
        makevectors(self.angles);
        spawn_tfog (self.origin + v_forward*20);
    #ifndef QUAKEWORLD
    }
    #endif

    spawn_tdeath (self.origin, self);

    #ifdef QUAKEWORLD
    // Set Rocket Jump Modifiers
    if (stof(infokey(world, "rj")) != 0)
    {
        rj = stof(infokey(world, "rj"));
    }
    #endif

    self.weapon = W_BestWeapon ();
    W_SetCurrentAmmo ();
};


/*
=============================================================================

                QUAKED FUNCTIONS

=============================================================================
*/


/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24)
The normal starting point for a level.
*/
void() info_player_start =
{
};


/*QUAKED info_player_start2 (1 0 0) (-16 -16 -24) (16 16 24)
Only used on start map for the return point from an episode.
*/
void() info_player_start2 =
{
};

#ifndef QUAKEWORLD
/*
saved out by quaked in region mode
*/
void() testplayerstart =
{
};
#endif

/*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for deathmatch games
*/
void() info_player_deathmatch =
{
};

/*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for coop games
*/
void() info_player_coop =
{
};

/*
===============================================================================

RULES

===============================================================================
*/

/*
go to the next level for deathmatch
only called if a time or frag limit has expired
*/
void() NextLevel =
{
    local entity o;

    #ifdef QUAKEWORLD
    if (nextmap != "")
        return; // already done
    #endif

    if (mapname == "start")
    {
        if (!cvar("registered"))
        {
            mapname = "e1m1";
        }
        else if (!(serverflags & 1))
        {
            mapname = "e1m1";
            serverflags = serverflags | 1;
        }
        else if (!(serverflags & 2))
        {
            mapname = "e2m1";
            serverflags = serverflags | 2;
        }
        else if (!(serverflags & 4))
        {
            mapname = "e3m1";
            serverflags = serverflags | 4;
        }
        else if (!(serverflags & 8))
        {
            mapname = "e4m1";
            serverflags = serverflags - 7;
        }

        o = spawn();
        o.map = mapname;
    }
    else
    {
        // find a trigger changelevel
        o = find(world, classname, "trigger_changelevel");

        // go back to same map if no trigger_changelevel
        if (!o)
        {
            o = spawn();
            o.map = mapname;
        }
    }

    nextmap = o.map;
    #ifndef QUAKEWORLD
    gameover = TRUE;
    #endif

    if (o.nextthink < time)
    {
        o.think = execute_changelevel;
        o.nextthink = time + 0.1;
    }
};

/*
============
CheckRules

Exit deathmatch games upon conditions
============
*/
void() CheckRules =
{
    #ifndef QUAKEWORLD
    local   float       timelimit;
    local   float       fraglimit;

    if (gameover)   // someone else quit the game already
        return;

    timelimit = cvar("timelimit") * 60;
    fraglimit = cvar("fraglimit");
    #endif

    if (timelimit && time >= timelimit)
    {
        NextLevel ();
        return;
    }

    if (fraglimit && self.frags >= fraglimit)
    {
        NextLevel ();
        return;
    }
};

//============================================================================

void() PlayerDeathThink =
{
    local entity    old_self;
    local float     forward;

    if ((self.flags & FL_ONGROUND))
    {
        forward = vlen (self.velocity);
        forward = forward - 20;
        if (forward <= 0)
            self.velocity = '0 0 0';
        else
            self.velocity = forward * normalize(self.velocity);
    }

// wait for all buttons released
    if (self.deadflag == DEAD_DEAD)
    {
        if (self.button2 || self.button1 || self.button0)
            return;
        self.deadflag = DEAD_RESPAWNABLE;

        // Play the obituary sound
        if (self.noise1)
        {
            sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
            self.noise1 = string_null;
        }

        return;
    }

// wait for any button down
    if (!self.button2 && !self.button1 && !self.button0)
        return;

    self.button0 = 0;
    self.button1 = 0;
    self.button2 = 0;
    respawn();
};


void() PlayerJump =
{
    local vector start, end;

    if (self.flags & FL_WATERJUMP)
        return;

    if (self.waterlevel >= 2)
    {
        if (self.watertype == CONTENT_WATER)
            self.velocity_z = 100;
        else if (self.watertype == CONTENT_SLIME)
            self.velocity_z = 80;
        else
            self.velocity_z = 50;

// play swiming sound
        if (self.swim_flag < time)
        {
            self.swim_flag = time + 1;
            if (random() < 0.5)
                sound (self, CHAN_BODY, "foley/swim.wav", 1, ATTN_NORM);
            else
                sound (self, CHAN_BODY, "foley/submerge.wav", 1, ATTN_NORM);
        }

        return;
    }

    if (!(self.flags & FL_ONGROUND))
        return;

    if ( !(self.flags & FL_JUMPRELEASED) )
        return;     // don't pogo stick

    self.flags = self.flags - (self.flags & FL_JUMPRELEASED);

    self.button2 = 0;
// player jumping sound
    sound (self, CHAN_BODY, "foley/jump.wav", 1, ATTN_NORM);

    #ifndef QUAKEWORLD
    local   float   jump;

// Boots let player jump about 4x as high.
// NOTE:  max height = v0^2 / 2g.
    if (self.boots_on)
        jump = 740;     // Velocity is doubled.
    else
        jump = 370;     // quake = 270
    self.flags = self.flags - FL_ONGROUND;  // don't stairwalk
    self.velocity_z = self.velocity_z + jump;
    #endif
};


/*
===========
WaterMove

============
*/
.float  dmgtime;

void() WaterMove =
{
//dprint (ftos(self.waterlevel));
    if (self.movetype == MOVETYPE_NOCLIP)
        return;
    if (self.health < 0)
        return;

    if (self.waterlevel != 3)
    {
        if (self.air_finished < time)
            sound (self, CHAN_VOICE, "foley/undchoke.wav", 1, ATTN_NORM);
        else if (self.air_finished < time + 9)
            sound (self, CHAN_VOICE, "foley/gasp.wav", 1, ATTN_NORM);
        self.air_finished = time + 12;
        self.dmg = 2;
        if (self.dive_on)
            Use_DivingSuit ();  // Turn of diving suit.
    }
    else if (self.air_finished < time)
    {   // drown!
        if (self.pain_finished < time)
        {
            self.dmg = self.dmg + 2;
            if (self.dmg > 15)
                self.dmg = 10;
            // PM:  Armor does not protect against drowning.
            T_NewDamage (self, world, world, self.dmg, 0, "drowning");
            self.pain_finished = time + 1;
        }
    }
    // Auto-use diving suit if underwater.
    if (self.waterlevel == 3)
        if (self.air_finished < time + 11)
            if (!self.dive_on)
                Use_DivingSuit ();

    if (!self.waterlevel)
    {
        if (self.flags & FL_INWATER)
        {
            // play leave water sound
            sound (self, CHAN_BODY, "foley/emerge.wav", 1, ATTN_NORM);
            self.flags = self.flags - FL_INWATER;
        }
        return;
    }

    if (self.watertype == CONTENT_LAVA)
    {   // do damage
        if (self.dmgtime < time)
        {
            if (self.dive_on)
                self.dmgtime = time + 1;
            else
                self.dmgtime = time + 0.2;

            // PM:  Fire-based damage.
            T_NewDamage (self, world, world, 10*self.waterlevel, DF_FIRE, "fire");
        }
    }
    else if (self.watertype == CONTENT_SLIME)
    {   // do damage
        if (self.dmgtime < time)
            if (!self.dive_on)
        {
            self.dmgtime = time + 1;
            T_NewDamage (self, world, world, 4*self.waterlevel, DF_BODY, "acid");
        }
    }

    if ( !(self.flags & FL_INWATER) )
    {

        // player enter water sound
        // FIXME: we should have different sounds for each type of liquid
        if (self.watertype == CONTENT_LAVA)
            sound (self, CHAN_BODY, "weapons/napalm/burn.wav", 1, ATTN_NORM);
        if (self.watertype == CONTENT_WATER)
            sound (self, CHAN_BODY, "foley/submerge.wav", 1, ATTN_NORM);
        if (self.watertype == CONTENT_SLIME)
            sound (self, CHAN_BODY, "ambience/sizzle.wav", 1, ATTN_NORM);  // FIXME: we shouldn't use an ambient sound here

        self.flags = self.flags + FL_INWATER;
        self.dmgtime = 0;
    }

    #ifndef QUAKEWORLD
    if (! (self.flags & FL_WATERJUMP) )
        self.velocity = self.velocity - 0.8*self.waterlevel*frametime*self.velocity;
    #endif
};

void() CheckWaterJump =
{
    local vector start, end;

// check for a jump-out-of-water
    makevectors (self.angles);
    start = self.origin;
    start_z = start_z + 8;
    v_forward_z = 0;
    normalize(v_forward);
    end = start + v_forward*24;
    traceline (start, end, TRUE, self);
    if (trace_fraction < 1)
    {   // solid at waist
        start_z = start_z + self.maxs_z - 8;
        end = start + v_forward*24;
        self.movedir = trace_plane_normal * -50;
        traceline (start, end, TRUE, self);
        if (trace_fraction == 1)
        {   // open at eye level
            self.flags = self.flags | FL_WATERJUMP;
            self.velocity_z = 225;
            self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
            self.teleport_time = time + 2;  // safety net
            return;
        }
    }
};


/*
================
PlayerPreThink

Called every frame before physics are run
================
*/
void() PlayerPreThink =
{
    local   float   mspeed, aspeed;
    local   float   r;

    if (intermission_running)
    {
        IntermissionThink ();   // otherwise a button could be missed between
        return;                 // the think tics
    }

    if (self.view_ofs == '0 0 0')
        return;     // intermission or finale

    makevectors (self.v_angle);     // is this still used

    self.deathtype = "";

    CheckRules ();
    WaterMove ();

    #ifndef QUAKEWORLD
    if (self.waterlevel == 2)
        CheckWaterJump ();
    #endif

    if (self.deadflag >= DEAD_DEAD)
    {
        PlayerDeathThink ();
        return;
    }

    //ZOID-Observer
    if (self.observer) {
        ObserverThink();
        return;
    }

    if (self.deadflag == DEAD_DYING)
        return; // dying, so do nothing

    if (self.button2)
    {
        PlayerJump ();
    }
    else
        self.flags = self.flags | FL_JUMPRELEASED;

// teleporters can force a non-moving pause time
    if (time < self.pausetime)
        self.velocity = '0 0 0';
};

/*
================
CheckPowerups

Check for turning off powerups
================
*/
void() CheckPowerups =
{
    if (self.health <= 0)
        return;

// invisibility
    if (self.invisible_finished)
    {
// sound and screen flash when items starts to run out
        if (self.invisible_sound < time)
        {
            sound (self, CHAN_AUTO, "bludbath/powerup.wav", 0.5, ATTN_IDLE);
            self.invisible_sound = time + ((random() * 3) + 1);
        }


        if (self.invisible_finished < time + 3)
        {
            if (self.invisible_time == 1)
            {
                Sprint (self, PRINT_HIGH, "Cloak of Invisibility is draining\n");
                stuffcmd (self, "bf\n");
                sound (self, CHAN_AUTO, "bludbath/powerup.wav", 1, ATTN_NORM);
                self.invisible_time = time + 1;
            }

            if (self.invisible_time < time)
            {
                self.invisible_time = time + 1;
                stuffcmd (self, "bf\n");
            }
        }

        if (self.invisible_finished < time)
        {   // just stopped
            self.items = self.items - IT_INVISIBILITY;
            self.invisible_finished = 0;
            self.invisible_time = 0;
        }

    // use the eyes
        self.frame = 0;
        self.modelindex = modelindex_eyes;
    }
    else
        self.modelindex = modelindex_player;    // don't use eyes

// invincibility
    if (self.invincible_finished)
    {
// sound and screen flash when items starts to run out
        if (self.invincible_finished < time + 3)
        {
            if (self.invincible_time == 1)
            {
                Sprint (self, PRINT_HIGH, "Death Mask is almost used up\n");
                stuffcmd (self, "bf\n");
                sound (self, CHAN_AUTO, "bludbath/powerup.wav", 1, ATTN_NORM);
                self.invincible_time = time + 1;
            }

            if (self.invincible_time < time)
            {
                self.invincible_time = time + 1;
                stuffcmd (self, "bf\n");
            }
        }

        if (self.invincible_finished < time)
        {   // just stopped
            self.items = self.items - IT_INVULNERABILITY;
            self.invincible_time = 0;
            self.invincible_finished = 0;
        }
        if (self.invincible_finished > time)
        {
            self.effects = self.effects | EF_DIMLIGHT;
            #ifdef QUAKEWORLD
            self.effects = self.effects | EF_RED;
            #endif
        }
        else
        {
            self.effects = self.effects - (self.effects & EF_DIMLIGHT);
            #ifdef QUAKEWORLD
            self.effects = self.effects - (self.effects & EF_RED);
            #endif
        }
    }

// super damage
    if (self.super_damage_finished)
    {

// sound and screen flash when items starts to run out

        if (self.super_damage_finished < time + 3)
        {
            if (self.super_time == 1)
            {
                Sprint (self, PRINT_HIGH, "Guns Akimbo is wearing off\n");
                stuffcmd (self, "bf\n");
                sound (self, CHAN_AUTO, "bludbath/powerup.wav", 1, ATTN_NORM);
                self.super_time = time + 1;
            }

            if (self.super_time < time)
            {
                self.super_time = time + 1;
                stuffcmd (self, "bf\n");
            }
        }

        if (self.super_damage_finished < time)
        {   // just stopped
// PM:  Guns akimbo don't use IT_QUAD.
            self.super_damage_finished = 0;
            self.super_time = 0;
        }
        if (self.super_damage_finished > time)
        {
            self.effects = self.effects | EF_DIMLIGHT;
            #ifdef QUAKEWORLD
            self.effects = self.effects | EF_BLUE;
            #endif
        }
        else
        {
            self.effects = self.effects - (self.effects & EF_DIMLIGHT);
            #ifdef QUAKEWORLD
            self.effects = self.effects - (self.effects & EF_BLUE);
            #endif
        }
    }

// Reflective shots
    if (self.reflect_finished)
    {
        // In Blood, there is no warning when it stops.

        if (self.reflect_finished < time)
        {   // just stopped
            self.items = self.items - IT_QUAD;
            self.reflect_finished = 0;

            self.effects = self.effects - (self.effects & EF_DIMLIGHT);
            #ifdef QUAKEWORLD
            self.effects = self.effects - (self.effects & EF_BLUE);
            #endif
        }
        else
        {
            self.effects = self.effects | EF_DIMLIGHT;
            #ifdef QUAKEWORLD
            self.effects = self.effects | EF_BLUE;
            #endif
        }
    }

// removed quake suit check.

    // PM:  Check inventory items.
    InvenCheck ();
};


/*
================
PlayerPostThink

Called every frame after physics are run
================
*/
void() PlayerPostThink =
{
    local   float   mspeed, aspeed;
    local   float   r;

    // if we're not allowed to act (in intermission, or dead, or observer)
    if (self.view_ofs == '0 0 0' || self.deadflag || self.observer)
        return;

    // check to see if player landed and play landing sound
    // no damage taken if not > 300 units high
    if ((self.jump_flag < -300) && (self.flags & FL_ONGROUND) && (self.health > 0))
    {
        if (self.watertype == CONTENT_WATER)
            sound (self, CHAN_BODY, "foley/lndwater.wav", 1, ATTN_NORM);

        // if higher than 300 units, do 5 damage, and set the falling death flag if player is killed
        else if (self.jump_flag < -750)     // was -650
        {
            // PM:  Armor does not protect against falling.
            // Quake falling damage = 5.
            aspeed = 0 - self.jump_flag;
            aspeed = (aspeed - 700) * 0.2;
            T_NewDamage (self, world, world, aspeed, 0, "falling");
        }
        else
            sound (self, CHAN_VOICE, "foley/land.wav", 1, ATTN_NORM);

        self.jump_flag = 0;
    }

    self.jump_flag = self.velocity_z;

    CheckPowerups ();

    W_WeaponFrame ();

// PM:  Check for boredom.
    if (self.velocity == '0 0 0')
    {
        if (self.idle_time <= time)
            if (!self.idle_done)
            {
                PM_BoredCaleb (self);
                self.idle_done = TRUE;
            }
    }
    else
    {
        PM_ResetIdle (self);
    }
};


/*
===========
ClientConnect

called when a player connects to a server
============
*/
void() ClientConnect =
{
    Bprint (PRINT_HIGH, self.netname);
    Bprint (PRINT_HIGH, " lives again!\n"); // entered the game

    sound (self, CHAN_AUTO, "thevoice/vo1.wav", 1, ATTN_NORM); //Let the Bloodbath Begin!

    #ifndef QUAKEWORLD
    if (deathmatch)
    #endif
        self.do_observer = 1;

    // a client connecting during an intermission can cause problems
    if (intermission_running)
        #ifdef QUAKEWORLD
        GotoNextMap ();
        #else
        ExitIntermission ();
        #endif
};


/*
===========
ClientDisconnect

called when a player disconnects from a server
============
*/
void() ClientDisconnect =
{
    #ifndef QUAKEWORLD
    if (gameover)
        return;
    // if the level end trigger has been activated, just return
    // since they aren't *really* leaving
    #endif

    // let everyone else know
    Bprint (PRINT_HIGH, self.netname);
    Bprint (PRINT_HIGH, " left this world for another with ");
    Bprint (PRINT_HIGH, ftos(self.frags));
    Bprint (PRINT_HIGH, " kills\n");
    sound (self, CHAN_BODY, "thevoice/vo2.wav", 1, ATTN_NONE);
    CTF_PlayerDropFlag ();
    set_suicide_frame ();
};

/*
===========
ClientObituary

called when a player dies (self is the victim)
============
*/
void(entity attacker) ClientObituary =
{
    local   float rnum;
    local   string deathstring, deathstring2;
    #ifdef QUAKEWORLD
    local   string  attackerteam, targteam;
    #endif

    rnum = random();

    #ifdef QUAKEWORLD
    //ZOID 12-13-96: self.team doesn't work in QW.  Use keys
    attackerteam = infokey(attacker, "team");
    targteam = infokey(self, "team");
    #endif

    if (self.classname != "player")
        return;  // Maybe we should print an error message

    if (attacker.classname == "teledeath")
    {
        Bprint (PRINT_MEDIUM,self.netname);
        Bprint (PRINT_MEDIUM,"'s personal space was invaded by ");
        Bprint (PRINT_MEDIUM,attacker.owner.netname);
        Bprint (PRINT_MEDIUM,"\n");
        self.noise1 = "thevoice/splatt.wav";
        #ifdef QUAKEWORLD
        logfrag (attacker.owner, self);
        #endif

        attacker.owner.frags = attacker.owner.frags + 1;
        return;
    }

    if (attacker.classname == "teledeath2")
    {
        Bprint (PRINT_MEDIUM,"Tchernobog's Death Mask deflects ");
        Bprint (PRINT_MEDIUM,self.netname);
        Bprint (PRINT_MEDIUM,"'s telefrag\n");
        self.noise1 = "thevoice/splatt.wav";
        #ifdef QUAKEWORLD
        logfrag (self, self);
        #endif

        self.frags = self.frags - 1;
        return;
    }

    // double 666 telefrag
    if (attacker.classname == "teledeath3")
    {
        Bprint (PRINT_MEDIUM,self.netname);
        Bprint (PRINT_MEDIUM," was overcome by  ");
        Bprint (PRINT_MEDIUM,attacker.owner.netname);
        Bprint (PRINT_MEDIUM, "'s Death Mask power\n");
        self.frags = self.frags - 1;
        self.noise1 = "thevoice/splatt.wav";
        #ifdef QUAKEWORLD
        logfrag (self, self);
        #endif
        return;
    }

    if (self.deathtype == "squish")
    {
        Bprint (PRINT_MEDIUM,self.netname);
        Bprint (PRINT_MEDIUM," was squashed\n");
        self.noise1 = "thevoice/squash.wav";
        self.frags = self.frags - 1;            // killed self
        #ifdef QUAKEWORLD
        logfrag (self, self);
        #endif
        return;
    }

    if (attacker.classname == "player")
    {
        if (self == attacker)
        {
            // killed self in a dumb fashion
            // dturner, 5/14/2001
            // eliminate quake obit logic, use bloods instead
            #ifdef QUAKEWORLD
            logfrag (attacker, attacker);
            #endif
            attacker.frags = attacker.frags - 1;
            Bprint (PRINT_MEDIUM,self.netname);

            if (rnum < 0.33)
            {
                deathstring = " receives the Darwin Award.\n";
                self.noise1 = "thevoice/vo16.wav";
            }
            else if (rnum < 0.66)
            {
                deathstring = " exercises Population control.\n";
                self.noise1 = "thevoice/vo12.wav";
            }
            else
            {
                deathstring = " gets an Unassisted death\n";
                self.noise1 = "thevoice/vo13.wav";
            }

            Bprint (PRINT_MEDIUM, deathstring);
            return;
        }
        #ifndef QUAKEWORLD
        else if ((teamplay == 2 && self.team > 0      && self.team == attacker.team) ||
        #else
        else if ((teamplay == 2 && attackerteam != "" && targteam == attackerteam) ||
        #endif
                 (deathmatch == 2 && self.team == attacker.team))
        {
            if (rnum < 0.25)
                deathstring = " mows down a teammate\n";
            else if (rnum < 0.50)
                deathstring = " checks his glasses\n";
            else if (rnum < 0.75)
                deathstring = " gets a frag for the other team\n";
            else
                deathstring = " loses another friend\n";
            Bprint (PRINT_MEDIUM, attacker.netname);
            Bprint (PRINT_MEDIUM, deathstring);

            attacker.frags = attacker.frags - 1;

            #ifdef QUAKEWORLD
            //ZOID 12-13-96:  killing a teammate logs as suicide
            logfrag (attacker, attacker);
            #endif
            return;
        }
        else
        {
            // all new obituary logic starts here
            // no weapon associations, just random message and Announcer voice
            // 5 14 2001 dturner
            #ifdef QUAKEWORLD
            logfrag (attacker, self);
            #endif
            attacker.frags = attacker.frags + 1;

            rnum = random()*54;

            // Messages with no names
            if (rnum <= 1)
            {
                Bprint (PRINT_MEDIUM, "Beaten like a Kirk.\n");
                self.noise1 = "thevoice/vo39.wav";
            }
            else if (rnum <= 2)
            {
                Bprint (PRINT_MEDIUM, "Bobbettized!\n");
                self.noise1 = "thevoice/vo31.wav";
            }
            else if (rnum <= 3)
            {
                Bprint (PRINT_MEDIUM, "Destroyed!\n");
                self.noise1 = "thevoice/vo24.wav";
            }
            else if (rnum <= 4)
            {
                Bprint (PRINT_MEDIUM, "Dog meat.\n");
                self.noise1 = "thevoice/vo36.wav";
            }
            else if (rnum <= 5)
            {
                Bprint (PRINT_MEDIUM, "Excellent!\n");
                self.noise1 = "thevoice/vo44.wav";
            }
            else if (rnum <= 6)
            {
                Bprint (PRINT_MEDIUM, "Fine work.\n");
                self.noise1 = "thevoice/vo22.wav";
            }
            else if (rnum <= 7)
            {
                Bprint (PRINT_MEDIUM, "Good one\n");
                self.noise1 = "thevoice/vo20.wav";
            }
            else if (rnum <= 8)
            {
                Bprint (PRINT_MEDIUM, "He shoots! He scores!\n");
                self.noise1 = "thevoice/vo33.wav";
            }
            else if (rnum <= 8)
            {
                Bprint (PRINT_MEDIUM, "Hosed!\n");
                self.noise1 = "thevoice/vo25.wav";
            }
            else if (rnum <= 10)
            {
                Bprint (PRINT_MEDIUM, "Humiliated!\n");
                self.noise1 = "thevoice/vo26.wav";
            }
            else if (rnum <= 11)
            {
                Bprint (PRINT_MEDIUM, "Lunch meat!\n");
                self.noise1 = "thevoice/vo21.wav";
            }
            else if (rnum <= 12)
            {
                Bprint (PRINT_MEDIUM, "Pass the chili!\n");
                self.noise1 = "thevoice/vo29.wav";
            }
            else if (rnum <= 13)
            {
                Bprint (PRINT_MEDIUM, "Punishment delivered\n");
                self.noise1 = "thevoice/vo30.wav";
            }
            else if (rnum <= 14)
            {
                Bprint (PRINT_MEDIUM, "Ripped 'em loose.\n");
                self.noise1 = "thevoice/vo38.wav";
            }
            else if (rnum <= 15)
            {
                Bprint (PRINT_MEDIUM, "Sent to HELL!\n");
                self.noise1 = "thevoice/vo28.wav";
            }
            else if (rnum <= 16)
            {
                Bprint (PRINT_MEDIUM, "Snuffed!\n");
                self.noise1 = "thevoice/vo41.wav";
            }
            else if (rnum <= 17)
            {
                Bprint (PRINT_MEDIUM, "Spillage!\n");
                self.noise1 = "thevoice/vo34.wav";
            }
            else if (rnum <= 18)
            {
                Bprint (PRINT_MEDIUM, "Sprayed!\n");
                self.noise1 = "thevoice/vo35.wav";
            }
            else if (rnum <= 19)
            {
                Bprint (PRINT_MEDIUM, "Stiffed!\n");
                self.noise1 = "thevoice/vo32.wav";
            }
            else if (rnum <= 20)
            {
                Bprint (PRINT_MEDIUM, "Talented!\n");
                self.noise1 = "thevoice/vo19.wav";
            }
            else if (rnum <= 21)
            {
                Bprint (PRINT_MEDIUM, "Toasted!\n");
                self.noise1 = "thevoice/vo27.wav";
            }
            else if (rnum <= 22)
            {
                Bprint (PRINT_MEDIUM, "Vaporized!\n");
                self.noise1 = "thevoice/vo43.wav";
            }
            else if (rnum <= 23)
            {
                Bprint (PRINT_MEDIUM, "Well done!\n");
                self.noise1 = "thevoice/vo23.wav";
            }
            else if (rnum <= 24)
            {
                Bprint (PRINT_MEDIUM, "Whipped and creamed!\n");
                self.noise1 = "thevoice/vo40.wav";
            }

            // Messages with the attacker name only
            else if (rnum <= 25)
            {
                Bprint (PRINT_MEDIUM, self.netname);
                Bprint (PRINT_MEDIUM, " suffered scrotum separation ");
                self.noise1 = "thevoice/vo9.wav";
            }
            else if (rnum <= 26)
            {
                Bprint (PRINT_MEDIUM, self.netname);
                Bprint (PRINT_MEDIUM, " is excrement\n ");
                self.noise1 = "thevoice/vo7.wav";
            }
            else if (rnum <= 27)
            {
                Bprint (PRINT_MEDIUM, self.netname);
                Bprint (PRINT_MEDIUM, " is hamburger\n ");
                self.noise1 = "thevoice/vo8.wav";
            }
            else if (rnum <= 28)
            {
                Bprint (PRINT_MEDIUM, self.netname);
                Bprint (PRINT_MEDIUM, " had his spleen vented\n");
                self.noise1 = "thevoice/vo42.wav";
            }

            // Messages with attacker name and target name
            else
            {
                deathstring2 = string_null;

                if (rnum <= 29)
                {
                    deathstring = " body bagged ";
                    self.noise1 = "thevoice/vo10.wav";
                }
                else if (rnum <= 30)
                {
                    deathstring = " boned ";
                    deathstring2 = " like a fish!\n";
                    self.noise1 = "thevoice/boned.wav";
                }
                else if (rnum <= 31)
                {
                    deathstring = " gave ";
                    deathstring2 = " Anal Justice!\n";
                    self.noise1 = "thevoice/justice.wav";
                }
                else if (rnum <= 32)
                {
                    deathstring = " hurt ";
                    deathstring2 = " real bad!\n";
                    self.noise1 = string_null;
                }
                else if (rnum <= 33)
                {
                    deathstring = " ripped ";
                    deathstring2 = " a new orifice!\n";
                    self.noise1 = "thevoice/ripped.wav";
                }
                else if (rnum <= 34)
                {
                    deathstring = " castrated ";
                    self.noise1 = "thevoice/castra.wav";
                }
                else if (rnum <= 35)
                {
                    deathstring = " creamed ";
                    self.noise1 = "thevoice/creamed.wav";
                }
                else if (rnum <= 36)
                {
                    deathstring = " decimated ";
                    self.noise1 = "thevoice/decimat.wav";
                }
                else if (rnum <= 37)
                {
                    deathstring = " destroyed ";
                    self.noise1 = "thevoice/destro.wav";
                }
                else if (rnum <= 38)
                {
                    deathstring = " diced ";
                    self.noise1 = "thevoice/diced.wav";
                }
                else if (rnum <= 39)
                {
                    deathstring = " disembowled ";
                    self.noise1 = "thevoice/disembo.wav";
                }
                else if (rnum <= 40)
                {
                    deathstring = " flattened ";
                    self.noise1 = "thevoice/flatte.wav";
                }
                else if (rnum <= 41)
                {
                    deathstring = " killed ";
                    self.noise1 = "thevoice/killed.wav";
                }
                else if (rnum <= 42)
                {
                    deathstring = " gave AnAl MaDnEsS to ";
                    self.noise1 = "thevoice/madness.wav";
                }
                else if (rnum <= 43)
                {
                    deathstring = " massacred ";
                    self.noise1 = "thevoice/massacr.wav";
                }
                else if (rnum <= 44)
                {
                    deathstring = " made mincemeat out of ";
                    self.noise1 = "thevoice/mincmeat.wav";
                }
                else if (rnum <= 45)
                {
                    deathstring = " mutilated ";
                    self.noise1 = "thevoice/mutila.wav";
                }
                else if (rnum <= 46)
                {
                    deathstring = " reamed ";
                    self.noise1 = "thevoice/reamed.wav";
                }
                else if (rnum <= 47)
                {
                    deathstring = " shat upon ";
                    self.noise1 = "thevoice/vo14.wav";
                }
                else if (rnum <= 48)
                {
                    deathstring = " slaughtered ";
                    self.noise1 = "thevoice/slaught.wav";
                }
                else if (rnum <= 49)
                {
                    deathstring = " sliced ";
                    self.noise1 = "thevoice/sliced.wav";
                }
                else if (rnum <= 50)
                {
                    deathstring = " smashed ";
                    self.noise1 = "thevoice/smashed.wav";
                }
                else if (rnum <= 51)
                {
                    deathstring = " sodomized ";
                    self.noise1 = "thevoice/sodomiz.wav";
                }
                else if (rnum <= 52)
                {
                    deathstring = " splattered ";
                    self.noise1 = "thevoice/splatt.wav";
                }
                else if (rnum <= 53)
                {
                    deathstring = " throttled ";
                    self.noise1 = "thevoice/throttl.wav";
                }
                else if (rnum <= 54)
                {
                    deathstring = " wasted ";
                    self.noise1 = "thevoice/wasted.wav";
                }

                Bprint (PRINT_MEDIUM, attacker.netname);
                Bprint (PRINT_MEDIUM, deathstring);
                Bprint (PRINT_MEDIUM, self.netname);
                if (deathstring2)
                    Bprint (PRINT_MEDIUM, deathstring2);
            }
        }
        return;
    }
    else
    {
        #ifdef QUAKEWORLD
        logfrag (self, self);
        #endif
        Bprint (PRINT_MEDIUM, self.netname);
        self.frags = self.frags - 1;

        #ifndef QUAKEWORLD
        // killed by a monster?
        if (attacker.flags & FL_MONSTER)
        {
            if (attacker.classname == "monster_army")
                bprint (" was shot by a Grunt\n");
            if (attacker.classname == "monster_demon1")
                bprint (" was eviscerated by a Fiend\n");
            if (attacker.classname == "monster_dog")
                bprint (" was mauled by a Rottweiler\n");
            if (attacker.classname == "monster_dragon")
                bprint (" was fried by a Dragon\n");
            if (attacker.classname == "monster_enforcer")
                bprint (" was blasted by an Enforcer\n");
            if (attacker.classname == "monster_fish")
                bprint (" was fed to the Rotfish\n");
            if (attacker.classname == "monster_hell_knight")
                bprint (" was slain by a Death Knight\n");
            if (attacker.classname == "monster_knight")
                bprint (" was slashed by a Knight\n");
            if (attacker.classname == "monster_ogre")
                bprint (" was destroyed by an Ogre\n");
            if (attacker.classname == "monster_oldone")
                bprint (" became one with Shub-Niggurath\n");
            if (attacker.classname == "monster_shalrath")
                bprint (" was exploded by a Vore\n");
            if (attacker.classname == "monster_shambler")
                bprint (" was smashed by a Shambler\n");
            if (attacker.classname == "monster_tarbaby")
                bprint (" was slimed by a Spawn\n");
            if (attacker.classname == "monster_vomit")
                bprint (" was vomited on by a Vomitus\n");
            if (attacker.classname == "monster_wizard")
                bprint (" was scragged by a Scrag\n");
            if (attacker.classname == "monster_zombie")
                bprint (" joins the Zombies\n");

            return;
        }
        #endif

        // hell if I know; he's just dead!!!
        Bprint (PRINT_MEDIUM," died\n");
    }
};
