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


// This function is both needed (by the compiler and
// maybe by the game), and unused (because never called)
void() main =
{
};


/*
================
PrecacheSounds

Precache all necessary sounds
================
*/
void() PrecacheSounds =
{
    // DON'T TOUCH !! - The following sounds are used by the engine code
    precache_sound ("misc/h2ohit1.wav");     // object entering water
    precache_sound ("demon/dland2.wav");     // landing thud

    // --- A few weapon sounds. Most of them are in weapon spawn functions --- //

    // pitchfork
    precache_sound ("weapons/pitchfrk/pflesh.wav");
    //precache_sound ("weapons/pitchfrk/pmetal.wav");
    precache_sound ("weapons/pitchfrk/pstone.wav");  // Hit a stone
    //precache_sound ("weapons/pitchfrk/pwood.wav");

    // ----- Player pain sounds ----- //

    precache_sound ("player/pain/play1105.wav");
    precache_sound ("player/pain/play1106.wav");
    precache_sound ("player/pain/play1107.wav");
    precache_sound ("player/pain/play1108.wav");

    // It burns !!!
    precache_sound ("player/pain/play1118.wav");
    precache_sound ("player/pain/play1119.wav");
    precache_sound ("player/pain/play1120.wav");

    // ----- Player songs (when idle for too long) ----- //

    precache_sound ("player/songs/1093.wav");
    precache_sound ("player/songs/1094.wav");
    precache_sound ("player/songs/1095.wav");
    precache_sound ("player/songs/1097.wav");
    precache_sound ("player/songs/vo3011.wav");
    precache_sound ("player/songs/vo3024.wav");
    precache_sound ("player/songs/vo3026.wav");
    precache_sound ("player/songs/vo3030.wav");
    precache_sound ("player/songs/vo3033.wav");
    precache_sound ("player/songs/vo3034.wav");
    precache_sound ("player/songs/vo3035.wav");
    precache_sound ("player/songs/vo3039.wav");

    // ----- The Voice ----- //

    precache_sound ("thevoice/vo1.wav");  // Let the bloodbath begins !
    precache_sound ("thevoice/vo2.wav");
    precache_sound ("thevoice/vo5.wav");
    precache_sound ("thevoice/splatt.wav");

    // Obituary sounds
    precache_sound ("thevoice/boned.wav");
    precache_sound ("thevoice/castra.wav");
    precache_sound ("thevoice/creamed.wav");
    precache_sound ("thevoice/decimat.wav");
    precache_sound ("thevoice/destro.wav");
    precache_sound ("thevoice/diced.wav");
    precache_sound ("thevoice/disembo.wav");
    precache_sound ("thevoice/flatte.wav");
    precache_sound ("thevoice/justice.wav");
    precache_sound ("thevoice/killed.wav");
    precache_sound ("thevoice/madness.wav");
    precache_sound ("thevoice/massacr.wav");
    precache_sound ("thevoice/mincmeat.wav");
    precache_sound ("thevoice/mutila.wav");
    precache_sound ("thevoice/reamed.wav");
    precache_sound ("thevoice/ripped.wav");
    precache_sound ("thevoice/slaught.wav");
    precache_sound ("thevoice/sliced.wav");
    precache_sound ("thevoice/smashed.wav");
    precache_sound ("thevoice/sodomiz.wav");
    precache_sound ("thevoice/throttl.wav");
    precache_sound ("thevoice/wasted.wav");
    precache_sound ("thevoice/vo10.wav");
    precache_sound ("thevoice/vo12.wav");  // Population control
    precache_sound ("thevoice/vo13.wav");  // Unassisted death
    precache_sound ("thevoice/vo14.wav");
    precache_sound ("thevoice/vo15.wav");  // Finish him
    precache_sound ("thevoice/vo16.wav");  // Darwin Award
    precache_sound ("thevoice/vo19.wav");
    precache_sound ("thevoice/vo20.wav");
    precache_sound ("thevoice/vo21.wav");
    precache_sound ("thevoice/vo22.wav");
    precache_sound ("thevoice/vo23.wav");
    precache_sound ("thevoice/vo24.wav");
    precache_sound ("thevoice/vo25.wav");
    precache_sound ("thevoice/vo26.wav");
    precache_sound ("thevoice/vo27.wav");
    precache_sound ("thevoice/vo28.wav");
    precache_sound ("thevoice/vo29.wav");
    precache_sound ("thevoice/vo30.wav");
    precache_sound ("thevoice/vo31.wav");
    precache_sound ("thevoice/vo32.wav");
    precache_sound ("thevoice/vo33.wav");
    precache_sound ("thevoice/vo34.wav");
    precache_sound ("thevoice/vo35.wav");
    precache_sound ("thevoice/vo36.wav");
    precache_sound ("thevoice/vo38.wav");
    precache_sound ("thevoice/vo39.wav");
    precache_sound ("thevoice/vo40.wav");
    precache_sound ("thevoice/vo41.wav");
    precache_sound ("thevoice/vo42.wav");
    precache_sound ("thevoice/vo43.wav");
    precache_sound ("thevoice/vo44.wav");
    precache_sound ("thevoice/vo7.wav");
    precache_sound ("thevoice/vo8.wav");  // Hamburger
    precache_sound ("thevoice/vo9.wav");

    // ----- Various game sounds ----- //

    // Fire
    precache_sound ("weapons/napalm/burn.wav");  // burning on lava

    // Death and gib sounds
    precache_sound ("firepod/fpodcol2.wav");  // telefragged player
    precache_sound ("misc/gibsq.wav");        // used when gibbing a corpse/head
    precache_sound ("player/die1.wav");
    precache_sound ("player/die2.wav");
    precache_sound ("player/die3.wav");

    // Moving, swimming, jumping, ...
    precache_sound ("foley/emerge.wav");    // leaving water sound
    precache_sound ("foley/gasp.wav");      // gasping for air
    precache_sound ("foley/jump.wav");      // player jump
    precache_sound ("foley/land.wav");      // player landing
    precache_sound ("foley/lndwater.wav");  // player jumping into water
    precache_sound ("foley/punt.wav");      // used by kickable heads
    precache_sound ("foley/submerge.wav");  // swimming
    precache_sound ("foley/swim.wav");      // swimming
    precache_sound ("foley/undchoke.wav");  // drowning pain

    // Teleport sounds
    precache_sound ("misc/r_tele1.wav");
    precache_sound ("misc/r_tele2.wav");
    precache_sound ("misc/r_tele3.wav");
    precache_sound ("misc/r_tele4.wav");
    precache_sound ("misc/r_tele5.wav");

    // Miscellaneous sounds
    precache_sound ("ambience/bubrise.wav");       // bubble sound
    precache_sound ("ambience/sizzle.wav");        // smelt on slime
    precache_sound ("bludbath/reappear.wav");      // item respawn sound
    precache_sound ("bludbath/message.wav");       // Messages  (TODO: not always used...)
    precache_sound ("items/ammo.wav");             // ammo pick up
    precache_sound ("items/pickarmr.wav");         // armor pick up
    precache_sound ("items/weaponup.wav");         // weapon pick up
    precache_sound ("misc/moans.wav");             // intermission sound
    precache_sound ("misc/null.wav");              // null sound (used as a placeholder, and to stop sounds)
    precache_sound ("player/slimbrn2.wav");
    precache_sound ("player/taunts/t1010.wav");    // "I live ... again !"
};


/*
================
MandatoryExtension

Check the availability of a QuakeC extension we absolutely need
================
*/
void(string ext) MandatoryExtension =
{
    if (!checkextension (ext))
        error2 ("A mandatory QuakeC extension is missing: ", ext);
};


//=======================
/*QUAKED worldspawn (0 0 0) ?
Only used for the world entity.
Set message to the level name.
Set sounds to the cd track to play.

World Types:
0: medieval
1: metal
2: base
*/
//=======================
void() worldspawn =
{
    // Check for QC extensions
    if (!cvar ("pr_checkextension"))
        error ("QuakeC extensions are not supported by this engine");
    MandatoryExtension ("DP_EF_BLUE");
    MandatoryExtension ("DP_EF_RED");
    MandatoryExtension ("DP_INPUTBUTTONS");
    MandatoryExtension ("DP_QUAKE3_MODEL");
    MandatoryExtension ("DP_REGISTERCVAR");

    // Create our own cvars as soon as possible
    registercvar ("g_flashyEffects", "0");
    registercvar ("g_lockTeams", "0");
    registercvar ("g_warmup", "0");
    registercvar ("g_weaponStay", "0");
    registercvar ("sv_cheats", "0");
    registercvar ("sv_disable", "0");

    // Warmup initialization
    warmup_done = (! cvar ("g_warmup"));
    warmup_endtime = 0;
    warmup_counttime = 0;

    starttime = time;

    // Empty the lists of available weapons
    available_weapons = IT_PITCHFORK;

    // Save the map index before BotInit has a chance to overwrite it
    map_cycle = cvar ("saved1");

    #ifndef NO_FRIKBOT
    // FrikBot X initialization
    Bot_Init();
    #endif

    // Compute the game type
    teamplay = cvar("teamplay");
    deathmatch = cvar("deathmatch");

    // we don't care about SP cooperative play anyway
    cvar_set ("coop", "0");
    coop = 0;

    // Select the game type
    if (deathmatch == 2)
    {
        gametype = GT_CAPTURE_THE_FLAG;

        // Tell the engine that we're actually in a team play
        if (teamplay == 0)
        {
            teamplay = 1;
            cvar_set ("teamplay", "1");
        }
    }
    else
    {
        cvar_set ("deathmatch", "1");
        deathmatch = 1;

        if (! teamplay)
            gametype = GT_BLOODBATH;
        else
            gametype = GT_TEAM_BLOODBATH;
    }
    friendlyfire = (teamplay == 2);  // NOTE: should we allow friendlyfire changes during the game ?

    // Set gravity
    cvar_set ("sv_gravity", "800");

    // Some CTF variables need an initialization
    team1score = team2score = 0;

    // It's time to precache some sounds...
    PrecacheSounds ();

    precache_model ("progs/flame.spr");     // Used for people on fire
    precache_model ("progs/s_oldexp.spr");
    precache_model ("progs/player.mdl");    // Warning: this model is also referenced by the engine itself
    precache_model ("progs/eyes.mdl");

    // Gibs and other stuff
    precache_model ("progs/bitogore.mdl");
    precache_model ("progs/h_player.mdl");
    precache_model ("models/objects/gib1.md3");
    precache_model ("models/objects/gib2.md3");
    precache_model ("models/objects/gib3.md3");
    precache_model ("progs/m_arm.mdl");
    precache_model ("models/objects/m_brain.md3");
    precache_model ("progs/m_chest.mdl");
    precache_model ("progs/m_farm.mdl");
    precache_model ("progs/m_fist.mdl");
    precache_model ("models/objects/m_foot.md3");
    precache_model ("models/objects/m_guts.md3");
    precache_model ("models/objects/m_leg.md3");
    precache_model ("models/objects/m_eyeball.md3");
    precache_model ("models/objects/m_hand.md3");

    precache_model ("progs/s_explod.spr");  // napalm sprite explosion

    precache_model ("models/weapons/v_pitch.md3");


    //
    // Setup light animation tables. 'a' is total darkness, 'z' is maxbright.
    //

    // 0 normal
    lightstyle(0, "m");

    // 1 FLICKER (first variety)
    lightstyle(1, "mmnmmommommnonmmonqnmmo");

    // 2 SLOW STRONG PULSE
    lightstyle(2, "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba");

    // 3 CANDLE (first variety)
    lightstyle(3, "mmmmmaaaaammmmmaaaaaabcdefgabcdefg");

    // 4 FAST STROBE
    lightstyle(4, "mamamamamama");

    // 5 GENTLE PULSE 1
    lightstyle(5,"jklmnopqrstuvwxyzyxwvutsrqponmlkj");

    // 6 FLICKER (second variety)
    lightstyle(6, "nmonqnmomnmomomno");

    // 7 CANDLE (second variety)
    lightstyle(7, "mmmaaaabcdefgmmmmaaaammmaamm");

    // 8 CANDLE (third variety)
    lightstyle(8, "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");

    // 9 SLOW STROBE (fourth variety)
    lightstyle(9, "aaaaaaaazzzzzzzz");

    // 10 FLUORESCENT FLICKER
    lightstyle(10, "mmamammmmammamamaaamammma");

    // 11 SLOW PULSE NOT FADE TO BLACK
    lightstyle(11, "abcdefghijklmnopqrrqponmlkjihgfedcba");

    // styles 32-62 are assigned by the light program for switchable lights

    // 63 testing
    lightstyle(63, "a");
};

void() World_WarmupCountdown;
void() StartFrame =
{
    timelimit = cvar("timelimit") * 60;
    fraglimit = cvar("fraglimit");
    skill     = cvar("skill");

    World_WarmupCountdown ();

    #ifndef NO_FRIKBOT
    Bot_Frame ();
    #endif
};


/*
==============================================================================

WARMUP

==============================================================================
*/

/*
====================
World_EndWarmup

Ends the warmup and resets/respawns all entities.
====================
*/
void(float cloneCorpse) respawn;
void() World_EndWarmup =
{
    if (warmup_done)
        return;

    local entity ent, tempEnt;

    bcenterprint ("Resetting level...\n");
    warmup_done = TRUE;
    warmup_counttime = 0;

    starttime = time;

    tempEnt = self;

    // Reset all entities
    ent = nextent (world);
    while (ent != world)
    {
        // If the entity has a reset function, call it
        if (ent.reset)
        {
            // Players respawn after the whole world has been reset
            if (ent.classname != "player")
            {
                self = ent;
                self.reset ();
            }
        }
        ent = nextent (ent);
    }

    // Respawn all players
    ent = find (world, classname, "player");
    while (ent != world)
    {
        self = ent;
        self.reset ();
        ent = find (ent, classname, "player");
    }

    self = tempEnt;

    // Use this occasion to test if cheats are enabled (the players should know that)
    if (cvar ("sv_cheats"))
        bprint ("◊¡“Œ…Œ«∫ Cheats are enabled on this server!!\n");
};


/*
====================
World_WarmupCountdown

Handle the warmup countdown
====================
*/
void() World_WarmupCountdown =
{
    // If the warmup has already been done
    if (warmup_done)
        return;

    // If the game is already over, don't bother with a warmup
    if (gameover)
    {
        warmup_done = TRUE;
        warmup_counttime = 0;
        return;
    }

    // If the warmup hasn't begun, send regularly a message to all players
    // so they know they're not in the real game yet
    if (! warmup_endtime)
    {
        if (warmup_counttime <= time)
        {
            warmup_counttime = warmup_counttime + 10;
            bcenterprint ("ææ Waiting for opponents ºº\n");
        }
        return;
    }

    // If the warmup is over
    if (warmup_endtime <= time)
    {
        World_EndWarmup ();
        return;
    }

    // Send regularly the countdown to all clients
    if (warmup_counttime <= time)
    {
        local string remaining;

        if (warmup_endtime - time < 5)
            warmup_counttime = warmup_counttime + 1;
        else
            warmup_counttime = warmup_counttime + 5;

        remaining = ftos (rint (warmup_endtime - time));
        bcenterprint3 ("◊¡“Õ’–∫ ", remaining, " sec\n");  // "WARMUP: ... sec"
    }
};


/*
====================
World_StartWarmup

Start the warmup countdown
====================
*/
void() World_StartWarmup =
{
    local float duration;
    local string str;

    // If the warmup has already begun or has been done
    if (warmup_endtime || warmup_done)
        return;

    // If you must do a warmup, make it last at least 5 secondes
    duration = cvar ("g_warmup");
    if (duration < 5)
        duration = 5;

    warmup_endtime = time + duration;
    warmup_counttime = time + duration - (floor (duration / 5) * 5);

    str = ftos (duration);
    bprint3 ("ææ Warmup started (", str, " sec) ºº\n");
};


/*
====================
World_StopWarmup

Stop the warmup countdown
====================
*/
void() World_StopWarmup =
{
    // If the warmup has not begun yet (or is finished)
    if (!warmup_endtime)
        return;

    warmup_endtime = 0;
    warmup_counttime = time + 5;  // "waiting for opponents" in 5 sec
    bprint ("ææ Warmup canceled ºº\n");
};


/*
====================
World_CheckWarmup

Check the warmup conditions, and start or stop the warmup when necessary
====================
*/
void() World_CheckWarmup =
{
    local entity ent;
    local float count1, count2;
    local float doWarmup;

    // If it's done
    if (warmup_done)
        return;

    count1 = count2 = 0;
    ent = find (world, classname, "player");
    while (ent != world)
    {
        if (ent.team != TEAM_COLOR2)
            count1 = count1 + 1;
        else
            count2 = count2 + 1;
        ent = find (ent, classname, "player");
    }

    // At least 2 players in BloodBath mode, and at least 1 player in each team for teamplay
    if (gametype == GT_BLOODBATH)
        doWarmup = (count1 >= 2);
    else
        doWarmup = (count1 >= 1 && count2 >= 1);

    if (doWarmup)
        World_StartWarmup ();
    else
        World_StopWarmup ();
};


/*
==============================================================================

CORPSE MANAGEMENT

==============================================================================
*/

// In player.qc
void() HeadDie;
void(string gibname, float dm) ThrowGib;


/*
====================
BecomeCorpse

Modify entity properties to change it to a destroyable corpse
====================
*/
void(float corpseHealth, void() corpseToGib) BecomeCorpse =
{
    // Corpse will turn into gibs if destroyed
    self.health = corpseHealth;
    self.th_die = corpseToGib;

    // Get rid of it in 30 sec anyway
    self.nextthink = time + 30;
    self.think = SUB_Remove;

    self.reset = SUB_Remove;

    // Allow some interactions (so the corpses can be destroyed by explosions)
    self.solid = SOLID_BBOX;
    self.takedamage = DAMAGE_AIM;
};


/*
====================
GibPlayerCorpse

Remove a player's corpse and throw gibs
====================
*/
void() RandomHumanGibs;
void() GibPlayerCorpse =
{
    RandomHumanGibs ();
    KillBurner (self);
    sound (self, CHAN_ITEM, "misc/gibsq.wav", 1, ATTN_NORM);

    remove (self);
};


/*
====================
CloneCorpse

Make a clone for the given ent so the ent can be respawned elsewhere
====================
*/
void(entity ent) CloneCorpse =
{
    local entity clone;
    local entity tempEnt;

    // Copy the entity characteristics
    clone = spawn ();
    clone.netname = ent.netname;
    clone.angles = ent.angles;
    clone.model = ent.model;
    clone.modelindex = ent.modelindex;
    clone.frame = ent.frame;
    clone.skin = ent.skin;
    clone.colormap = ent.colormap;
    clone.movetype = ent.movetype;
    clone.velocity = ent.velocity;
    setorigin (clone, ent.origin);
    setsize (clone, ent.mins, ent.maxs);

    tempEnt = self;
    self = clone;

    // If the entity is a head, we just need to call HeadDie when it's destroyed
    if (clone.model == "progs/h_player.mdl")
    {
        self.classname = "head";
        self.touch = HeadTouch;
        BecomeCorpse (80, HeadDie);
    }
    // Corpse will turn into gibs if destroyed
    else
    {
        local vector minBbox, maxBbox;

        self.classname = "corpse";

        minBbox = VEC_HULL_MIN;
        maxBbox = VEC_HULL_MAX;
        maxBbox_z = minBbox_z + 5;
        setsize (self, minBbox, maxBbox);
        self.touch = SUB_SolidTouch;

        BecomeCorpse (100, GibPlayerCorpse);
    }

    self = tempEnt;
};
