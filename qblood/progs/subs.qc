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


void() SUB_CalcMoveDone;


float() crandom =
{
    return 2*(random() - 0.5);
};


void() SUB_Null = {};

void() SUB_Remove =
{
    remove (self);
};


/*
====================
bcenterprint

Send a centerprint to all players
====================
*/
void(string text) bcenterprint =
{
    local entity ent;

    ent = find (world, classname, "player");
    while (ent != world)
    {
        centerprint (ent, text);
        ent = find (ent, classname, "player");
    }
};


/*
====================
bcenterprint3

Send a centerprint3 to all players
====================
*/
void(string text1, string text2, string text3) bcenterprint3 =
{
    local entity ent;

    ent = find (world, classname, "player");
    while (ent != world)
    {
        centerprint3 (ent, text1, text2, text3);
        ent = find (ent, classname, "player");
    }
};


#ifdef NEW_MODELS
/*
====================
SUB_AutoAnimation

Function used to animate models that don't have animation groups
====================
*/
void() SUB_AutoAnimation =
{
    self.nextthink = time + 0.1;

    self.frame = self.frame + 1;
    if (self.frame >= self.anim_len)
        self.frame = 0;
};
#endif


/*
====================
SUB_SolidTouch

So you don't slip on corpses, Life Leeches, ...
====================
*/
void () SUB_SolidTouch =
{
    if ((!other.flags & FL_ONGROUND) && (other.health) && (other.flags & FL_CLIENT))
        other.flags = other.flags + FL_ONGROUND;
};


/*
QuakeEd only writes a single float for angles (bad idea), so up and down are
just constant angles.
*/
vector() SetMovedir =
{
    if (self.angles == '0 -1 0')
        self.movedir = '0 0 1';
    else if (self.angles == '0 -2 0')
        self.movedir = '0 0 -1';
    else
    {
        makevectors (self.angles);
        self.movedir = v_forward;
    }

    self.angles = '0 0 0';
};

/*
================
InitTrigger
================
*/
void() InitTrigger =
{
    // trigger angles are used for one-way touches.  An angle of 0 is assumed
    // to mean no restrictions, so use a yaw of 360 instead.
    if (self.angles != '0 0 0')
        SetMovedir ();
    self.solid = SOLID_TRIGGER;
    setmodel (self, self.model);    // set size and link into world
    self.movetype = MOVETYPE_NONE;
    self.modelindex = 0;
    self.model = string_null;
};

/*
=============
SUB_CalcMove

calculate self.velocity and self.nextthink to reach dest from
self.origin traveling at speed
===============
*/
void(vector tdest, float tspeed, void() func) SUB_CalcMove =
{
    local vector    vdestdelta;
    local float     len, traveltime;

    if (!tspeed)
        objerror("No speed is defined!");

    self.think1 = func;
    self.finaldest = tdest;
    self.think = SUB_CalcMoveDone;

    if (tdest == self.origin)
    {
        self.velocity = '0 0 0';
        self.nextthink = self.ltime + 0.1;
        return;
    }

    // set destdelta to the vector needed to move
    vdestdelta = tdest - self.origin;

    // calculate length of vector
    len = vlen (vdestdelta);

    // divide by speed to get time to reach dest
    traveltime = len / tspeed;

    if (traveltime < 0.03)
        traveltime = 0.03;

    // set nextthink to trigger a think when dest is reached
    self.nextthink = self.ltime + traveltime;

    // scale the destdelta vector by the time spent traveling to get velocity
    self.velocity = vdestdelta * (1/traveltime);    // qcc won't take vec/float
};

/*
============
After moving, set origin to exact final destination
============
*/
void()  SUB_CalcMoveDone =
{
    setorigin(self, self.finaldest);
    self.velocity = '0 0 0';
    self.nextthink = -1;
    if (self.think1)
        self.think1();
};


/*
============
After rotating, set angle to exact final angle
============
*/
void() SUB_CalcAngleMoveDone =
{
    self.angles = self.finalangle;
    self.avelocity = '0 0 0';
    self.nextthink = -1;
    if (self.think1)
        self.think1();
};

/*
=============
SUB_CalcAngleMove

calculate self.avelocity and self.nextthink to reach destangle from
self.angles rotating

The calling function should make sure self.think is valid
===============
*/
void(vector destangle, float tspeed, void() func) SUB_CalcAngleMove =
{
    local vector    destdelta;
    local float     len, traveltime;

    if (!tspeed)
        objerror("No speed is defined!");

    // set destdelta to the vector needed to move
    destdelta = destangle - self.angles;

    // calculate length of vector
    len = vlen (destdelta);

    // divide by speed to get time to reach dest
    traveltime = len / tspeed;

    // set nextthink to trigger a think when dest is reached
    self.nextthink = self.ltime + traveltime;

    // scale the destdelta vector by the time spent traveling to get velocity
    self.avelocity = destdelta * (1 / traveltime);

    self.think1 = func;
    self.finalangle = destangle;
    self.think = SUB_CalcAngleMoveDone;
};


//=============================================================================

void() SUB_UseTargets;

void() DelayThink =
{
    activator = self.enemy;
    SUB_UseTargets ();
    remove(self);
};

/*
==============================
SUB_UseTargets

the global "activator" should be set to the entity that initiated the firing.

If self.delay is set, a DelayedUse entity will be created that will actually
do the SUB_UseTargets after that many seconds have passed.

Centerprints any self.message to the activator.

Removes all entities with a targetname that match self.killtarget,
and removes them, so some events can remove other triggers.

Search for (string)targetname in all entities that
match (string)self.target and call their .use function

==============================
*/
void() SUB_UseTargets =
{
    local entity t, stemp, otemp, act;

    // check for a delay
    if (self.delay)
    {
        // create a temp object to fire at a later time
        t = spawn();
        t.classname = "DelayedUse";
        t.nextthink = time + self.delay;
        t.think = DelayThink;
        t.enemy = activator;
        t.message = self.message;
        t.killtarget = self.killtarget;
        t.target = self.target;
        return;
    }

    // print the message
    if (activator.classname == "player" && self.message != string_null)
    {
        centerprint (activator, self.message);
        if (!self.noise)
            sound (activator, CHAN_VOICE, "bludbath/message.wav", 1, ATTN_NORM);
    }

    // kill the killtargets
    if (self.killtarget)
    {
        t = world;
        do
        {
            t = find (t, targetname, self.killtarget);
            if (t)
                remove (t);
        } while (t);
    }

    // fire targets
    if (self.target)
    {
        act = activator;
        t = world;
        do
        {
            t = find (t, targetname, self.target);
            if (!t)
                return;
            stemp = self;
            otemp = other;
            self = t;
            other = stemp;
            if (self.use)
                self.use ();
            self = stemp;
            other = otemp;
            activator = act;
        } while (TRUE);
    }


};


/*
=======================
SUB_GetPointedPlayer

Returns the player you are pointed towards

Copyright (C) 1997  Nat Friedman
By Suck (Nat Friedman); hacked by Zoid for CTF4
=======================
*/
entity(float closeness) SUB_GetPointedPlayer =
{
    // e is a temp entity; guy is our current best guess
    // as to at whom the player is pointing
    local entity e, guy;

    // Temp vars.
    local vector diff, point, start_point;
    local float currclose, length;
    local string s1, s2, s3;

    // Normalize self.angles so we can do a length-independent
    // consideration
    makevectors (self.v_angle);

    start_point = self.origin + self.view_ofs;

    // Walk the list of players...
    e = find(world, classname, "player");
    while (e != world)
    {
        // Get a vector pointing from the viewer to the current
        // player under consideration
        diff = e.origin - start_point;
        length = vlen (diff);

        // Normalize it since we only care where he's pointing,
        // not how far away the guy is.
        diff = normalize (diff);

        // Find the different between the current player's angle
        // and the viewer's vision angle
        diff = diff - v_forward;

        // The length is going to be our definition of closeness
        currclose = vlen (diff) * length / 500;
        traceline (start_point, e.origin, FALSE, self);
        if (trace_ent == e && (closeness == -1 || currclose < closeness)) {
            closeness = currclose;
            guy = e;
        }
        e = find (e, classname, "player");
    }

    return guy;
};


/*
=======================
identify_player

Identify the player you are pointed towards
=======================
*/
void() identify_player =
{
    local entity guy;

    guy = SUB_GetPointedPlayer (-1);

    if (guy == world)
        centerprint (self, "You're not looking at anyone!");
    else
        centerprint2 (self, "You are looking at ", guy.netname);
};
