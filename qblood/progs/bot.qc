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


void() bot_map_load =
{
    // place your qc loaded waypoints here

    /*
    if (mapname == "dm1")
        map_dm1();
    else if (mapname == "dm2")
        map_dm2();
    else if (mapname == "dm3")
        map_dm3();
    else if (mapname == "dm4")
        map_dm4();
    else if (mapname == "dm5")
        map_dm5();
    else if (mapname == "dm6")
        map_dm6();
    */
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Variables and shtuff

bot.qc has become pretty much a header file
for all variable in the bot...

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

// ----- entity fields ---
.float  wallhug, keys, oldkeys, ishuman;
.float  b_frags, b_clientno, b_shirt, b_pants;
.float  priority, ai_time, b_sound, missile_speed;
.float  portal_time, b_skill, switch_wallhug;
.float  b_aiflags, b_num, b_chattime;
#ifdef QUAKEWORLD
.float  b_entertime, b_userid; // QW stuff
#endif
.float  b_menu, b_menu_time, b_menu_value;
.float route_failed, dyn_flags, dyn_time;
.float dyn_plat;
.entity temp_way, last_way, phys_obj;
.entity target1, target2, target3, target4;
.entity _next, _last;
.entity current_way;
.vector b_angle, b_dest, mouse_emu, obs_dir;
.vector movevect, b_dir;
.vector dyn_dest;
#ifdef QUAKEWORLD
.vector punchangle; // HACK - Don't want to screw with bot_phys
#endif

// --------defines-----
float SVC_UPDATENAME    = 13;
float SVC_UPDATEFRAGS   = 14;
float SVC_UPDATECOLORS  = 17;

// used for the physics & movement AI
float KEY_MOVEUP        = 1;
float KEY_MOVEDOWN      = 2;
float KEY_MOVELEFT      = 4;
float KEY_MOVERIGHT     = 8;
float KEY_MOVEFORWARD   = 16;
float KEY_MOVEBACK      = 32;
float KEY_LOOKUP        = 64;
float KEY_LOOKDOWN      = 128;
float KEY_LOOKLEFT      = 256;
float KEY_LOOKRIGHT     = 512;

// these are aiflags for waypoints
// some overlap to the bot
float AI_TELELINK_1     = 1;       // link type
float AI_TELELINK_2     = 2;       // link type
float AI_TELELINK_3     = 4;       // link type
float AI_TELELINK_4     = 8;       // link type
float AI_DOORFLAG       = 16;      // read ahead
float AI_PRECISION      = 32;      // read ahead + point
float AI_SURFACE        = 64;      // point
float AI_BLIND          = 128;     // read ahead + point
float AI_JUMP           = 256;     // point + ignore
float AI_DIRECTIONAL    = 512;     // read ahead + ignore
float AI_PLAT_BOTTOM    = 1024;    // read ahead
float AI_RIDE_TRAIN     = 2048;    // read ahead
float AI_SUPER_JUMP     = 4096;    // point + ignore + route test
float AI_SNIPER         = 8192;    // point type
float AI_AMBUSH         = 16384;   // point type
float AI_DOOR_NO_OPEN   = 32768;   // read ahead
float AI_DIFFICULT      = 65536;   // route test
float AI_TRACE_TEST     = 131072;  // route test

// these are flags for bots/players (dynamic/editor flags)
float AI_OBSTRUCTED     = 1;
float AI_HOLD_SELECT    = 2;
float AI_ROUTE_FAILED   = 2;
float AI_WAIT           = 4;
float AI_DANGER         = 8;

// addition masks
float AI_POINT_TYPES        = 29152;
float AI_READAHEAD_TYPES    = 36528;
float AI_IGNORE_TYPES       = 4864;

float WM_UNINIT         = 0;
float WM_DYNAMIC        = 1;
float WM_LOADING        = 2;
float WM_LOADED         = 3;
// editor modes aren't available in QW, but we retain support of them
// since the editor is still built into the AI in places
float WM_EDITOR         = 4;
float WM_EDITOR_DYNAMIC = 5;
float WM_EDITOR_DYNLINK = 6;

#ifndef QUAKEWORLD
float OPT_SAVEBOTS  = 1;
#endif
float OPT_NOCHAT    = 2;

// -------globals-----
float   active_clients1, active_clients2;
float   max_clients, real_frametime;
float   bot_count, b_options;
#ifdef QUAKEWORLD
float   lasttime;
#endif
float   waypoint_mode, dump_mode;
float   waypoints, direct_route;
#ifdef QUAKEWORLD
float   userid;
#endif
float   sv_friction, sv_gravity;
float   sv_accelerate, sv_maxspeed, sv_stopspeed;
entity  fixer;
entity  route_table;
entity  b_temp1, b_temp2, b_temp3;
entity  player_head, phys_head, way_head;
float   busy_waypoints;
#ifndef QUAKEWORLD
float   saved_bots, saved_skills1, saved_skills2, current_bots;
#endif

// -------ProtoTypes------
// external
void()              ClientConnect;
void()              ClientDisconnect;
void()              SetNewParms;

// rankings
float(float clientno)       ClientBitFlag;
void(float whichteam, float whatbot, float whatskill) BotConnect;
void(entity bot)            BotDisconnect;
void(float clientno)        BotInvalidClientNo;
void(entity who)            UpdateClient;

// waypointing
void()              DynamicWaypoint;
entity(vector org)      make_waypoint;
void()              ClearAllWays;
void()              FixWaypoints;
float()             begin_route;
void(entity this, float direct)         bot_get_path;
void()              WaypointThink;
entity(entity start)                FindWayPoint;

// physics & movement
float(entity e)         bot_can_rj;
void()              bot_jump;
void()              frik_bot_roam;
float(vector weird)     frik_walkmove;
void()              frik_movetogoal;
void()              frik_obstacles;
float(float flag)           frik_recognize_plat;
float(vector sdir)      frik_KeysForDir;
void(vector whichway, float danger) frik_obstructed;
void()              SV_Physics_Client;
void()              SV_ClientThink;
void()              CL_KeyMove;

// ai & misc
string()                PickARandomName;
float(entity targ)      fov;
float(float y1, float y2)   angcomp;
float(entity targ1, entity targ2)       wisible;
float(entity targ)      sisible;
float(entity targ)      fisible;
vector(entity ent)      realorigin;
void(entity ent)            target_drop;
void(entity ent)            target_add;
void()              KickABot;
void(entity targ, float success) bot_lost;
string(float r)         BotName;
float(float v)          frik_anglemod;
void() bot_chat;
void(float tpic) bot_start_topic;


#ifndef QUAKEWORLD
// editor stuffs
void()              bot_way_edit;
void()              bot_menu_display;
#endif


// ----------Commands---------
void(entity e, float chan, string samp, float vol, float atten) frik_sound = #8;
void(entity client, string s)   frik_stuffcmd = #21;
#ifndef QUAKEWORLD
void(entity client, string s)   frik_sprint = #24;
#else
void(entity client, float level, string s)  frik_sprint = #24;
#endif
vector(entity e, float sped)              frik_aim = #44;
void(entity client, string s)             frik_centerprint = #73;
void(entity client, string s1, string s2) frik_centerprint2 = #73;
void(entity e)          frik_setspawnparms = #78;
void(float to, float f)     frik_WriteByte = #52;
void(float to, float f)     frik_WriteChar = #53;
void(float to, float f)     frik_WriteShort = #54;
void(float to, float f)     frik_WriteLong = #55;
void(float to, float f)     frik_WriteCoord = #56;
void(float to, float f)     frik_WriteAngle = #57;
void(float to, string s)    frik_WriteString    = #58;
void(float to, entity s)    frik_WriteEntity    = #59;

#ifndef QUAKEWORLD
void(entity client, string s1, string s2, string s3, string s4, string s5, string s6, string s7)
frik_big_centerprint = #73;
#endif

//----------------------------------------------------------------------------

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Function redeclarations. These allow function
designed to work for clients (sprint, so forth)
to mainly not complain when working with a bot

Although these shouldn't be needed anymore,
as the bots truly are clients now, if you don't
stop the SZ_ buffer from filling up by disabling
direct messages to the bots, it crashes quake :-(

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
void(entity client, string s) stuffcmd =
{
    if (client.ishuman == 1)
        frik_stuffcmd(client, s);
    #ifndef QUAKEWORLD
    b_temp1 = player_head;

    while(b_temp1)
    {
        if (b_temp1.classname == "botcam")
        {
            if ((b_temp1.enemy == client) && b_temp1.ishuman)
                frik_stuffcmd(b_temp1, s);
        }
        b_temp1 = b_temp1._next;
    }
    #endif
};

void(entity e) setspawnparms =
{
    if (e.ishuman == 1)
        frik_setspawnparms(e);
    else
    {
        #ifndef QUAKEWORLD
        b_temp1 = player_head;
        while(b_temp1)
        {
            if (b_temp1.ishuman)
            {
                frik_setspawnparms(b_temp1);
                return;
            }
            b_temp1 = b_temp1._next;
        }
        #endif
        SetNewParms();
    }
};

#ifndef QUAKEWORLD
void(entity client, string s) sprint =
#else
void(entity client, float level, string s) sprint =
#endif
{
    #ifndef QUAKEWORLD
    if (client.ishuman == 1)
        frik_sprint(client, s);
    b_temp1 = player_head;

    while(b_temp1)
    {
        if (b_temp1.classname == "botcam")
        {
            if ((b_temp1.enemy == client) && b_temp1.ishuman)
                frik_sprint(b_temp1, s);
        }
        b_temp1 = b_temp1._next;
    }
    #else
    if (client.ishuman)
        frik_sprint(client, level, s);
    #endif
};
void(entity client, string s) centerprint =
{
    if (client.ishuman == 1)
        frik_centerprint(client, s);
    #ifndef QUAKEWORLD
    b_temp1 = player_head;

    while(b_temp1)
    {
        if (b_temp1.classname == "botcam")
        {
            if ((b_temp1.enemy == client) && b_temp1.ishuman)
                frik_centerprint(b_temp1, s);
        }
        b_temp1 = b_temp1._next;
    }
    #endif
};
void(entity client, string s1, string s2) centerprint2 =
{
    if (client.ishuman == 1)
        frik_centerprint2(client, s1, s2);
    #ifndef QUAKEWORLD
    b_temp1 = player_head;

    while(b_temp1)
    {
        if (b_temp1.classname == "botcam")
        {
            if ((b_temp1.enemy == client) && b_temp1.ishuman)
                frik_centerprint2(b_temp1, s1, s2);
        }
        b_temp1 = b_temp1._next;
    }
    #endif
};

vector(entity e, float sped) aim =
{
    e.missile_speed = sped;
    return frik_aim(e, sped);
};

void(entity e, float chan, string samp, float vol, float atten) sound =
{
    frik_sound(e, chan, samp, vol, atten);
    if (samp == "items/inv3.wav")
        return;
    else if (e.classname == "player")
        e.b_sound = time + 1;
    else if (other.classname == "player")
        other.b_sound = time + 1;
};
void(float to, float f) WriteByte =
{
    if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
        return;
    frik_WriteByte(to, f);
};
void(float to, float f) WriteChar =
{
    if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
        return;
    frik_WriteChar(to, f);
};
void(float to, float f) WriteShort =
{
    if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
        return;
    frik_WriteShort(to, f);
};
void(float to, float f) WriteLong =
{
    if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
        return;
    frik_WriteLong(to, f);
};
void(float to, float f) WriteCoord =
{
    if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
        return;
    frik_WriteCoord(to, f);
};
void(float to, float f) WriteAngle =
{
    if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
        return;
    frik_WriteAngle(to, f);
};
void(float to, string s) WriteString =
{
    if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
        return;
    frik_WriteString(to, s);
};
void(float to, entity s) WriteEntity =
{
    if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
        return;
    frik_WriteEntity(to, s);
};

float(float clientno) ClientIsActive =
{
    if(clientno > 16)
        return (active_clients2 & ClientBitFlag (clientno - 16)) != 0;

    return (active_clients1 & ClientBitFlag (clientno)) != 0;
};


#ifndef QUAKEWORLD
/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Bot Cam, see what the bot sees (or any other player)

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

float() botcam =
{
    if (self.classname != "botcam")
        return FALSE;
    setorigin(self, self.enemy.origin);
    self.items = self.enemy.items;
    self.weapon = self.enemy.weapon;
    self.weaponmodel = self.enemy.weaponmodel;
    self.currentammo = self.enemy.currentammo;
    self.weaponframe = self.enemy.weaponframe;
    self.ammo_shells = self.enemy.ammo_shells;
    self.ammo_nails = self.enemy.ammo_nails;
    self.ammo_rockets= self.enemy.ammo_rockets;
    self.ammo_cells = self.enemy.ammo_cells;
    self.view_ofs = self.enemy.view_ofs;
    self.health = self.enemy.health;
    self.armorvalue = self.enemy.armorvalue;
    self.dmg_take = self.enemy.dmg_take;
    self.dmg_save = self.enemy.dmg_save;
    self.dmg_inflictor = self.enemy.dmg_inflictor;
    self.punchangle = self.enemy.punchangle;
    self.deadflag = self.enemy.deadflag;
    msg_entity = self;
    WriteByte (MSG_ONE,5);
    WriteEntity (MSG_ONE, self.enemy);
    WriteByte (MSG_ONE, 10);
        WriteAngle (MSG_ONE,self.enemy.v_angle_x);
        WriteAngle (MSG_ONE,self.enemy.v_angle_y);
        WriteAngle (MSG_ONE,self.enemy.v_angle_z);
    self.modelindex = 0;

    self.impulse = 0;
    return TRUE;

};

void() botcam_u =
{

    // sloppy cycling code
    if (self.classname != "botcam")
    {
        self.enemy = player_head;
    }
    else
    {
        do
            self.enemy = self.enemy._next;
        while (self.enemy.classname == "botcam");
    }
    if (self.enemy == self)
    {
        do
            self.enemy = self.enemy._next;
        while (self.enemy.classname == "botcam");
    }

    self.classname = "botcam";
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    self.takedamage = DAMAGE_NO;


    if (!self.enemy)
    {
        sprint(self, "No one left to track!\n");
        msg_entity = self;
        WriteByte (MSG_ONE,5);
        WriteEntity (MSG_ONE, self);
        PutClientInServer();
        return;
    }
    if (!self.enemy.ishuman)
    {
        self.enemy.dmg_take = 0;
        self.enemy.dmg_save = 0;
    }
    sprint(self, "Now tracking ");
    sprint(self, self.enemy.netname);
    sprint(self, "\n");
};
#endif


/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Stuff mentioned up top
it just links the bot into the mod

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void() ClientFixRankings =
{
    local float cno;
    if (self.switch_wallhug > time)
        return;
    self.switch_wallhug = 0;

    b_temp2 = nextent(world);
    cno = 0;

    while (cno < max_clients)
    {
        if ((!b_temp2.ishuman) && ClientIsActive(cno))
            UpdateClient(b_temp2);
        cno = cno + 1;
        b_temp2 = nextent(b_temp2);
    }
};

void() ClientInRankings =
{
    local float cno;
    if (player_head)
        player_head._last = self;

    self._next = player_head;
    self._last = world;
    player_head = self;
    #ifdef QUAKEWORLD
    userid = userid + 1;
    self.b_userid = userid;
    #endif

    if (!self.phys_obj)
    {
        b_temp2 = phys_head;
        while (b_temp2 != world && b_temp2.owner != self)
            b_temp2 = b_temp2._next;
        self.phys_obj = b_temp2;
    }

    if (self.ishuman == 2)
    {
        self.ishuman = FALSE;
        return;
    }
    cno = self.colormap - 1;
    BotInvalidClientNo (cno);
    if(cno > 16)
        active_clients2 = active_clients2 | ClientBitFlag(cno - 16);
    else
        active_clients1 = active_clients1 | ClientBitFlag(cno);

    self.b_clientno = cno;
    self.ishuman = TRUE;
    self.switch_wallhug = time + 1;
};


void() ClientDisconnected =
{
    if (player_head == self)
        player_head = self._next;
    if (self._next)
        self._next._last = self._last;
    if (self._last)
        self._last._next = self._next;

    if(self.b_clientno > 16)
        active_clients2 = active_clients2 - (active_clients2 & ClientBitFlag(self.b_clientno - 16));
    else
        active_clients1 = active_clients1 - (active_clients1 & ClientBitFlag(self.b_clientno));

    // If it's a real player, reset the client number
    if (self.ishuman = TRUE)
        self.b_clientno = -1;
};
/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BotPreFrame & BotPostFrame, used to make the
bot easier to install

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
float () BotPreFrame =
{
    if (self.b_clientno == -1)
        return TRUE;
    if (self.ishuman)
    {
        if (self.switch_wallhug)
            ClientFixRankings();
        #ifndef QUAKEWORLD
        if (self.classname == "botcam")
            return TRUE;
        #endif
    }
    if (self.b_frags != self.frags)
    {

        if (self.b_frags > self.frags)
        {
            if (pointcontents(self.origin) == CONTENT_LAVA)
                bot_start_topic(10);
            else
                bot_start_topic(9);
        }
        else
            bot_start_topic(2);
        self.b_frags = self.frags;
        #ifdef QUAKEWORLD
        if (!self.ishuman)
        {
            WriteByte(2, 14);
            WriteByte(2, self.b_clientno);
            WriteShort(2, self.frags);
        }
        #endif
    }
    DynamicWaypoint();
    return FALSE;
};
float () BotPostFrame =
{
    if (self.b_clientno == -1)
        return TRUE;
    #ifndef QUAKEWORLD
    if (self.ishuman)
    {
        if (waypoint_mode > WM_LOADED)
            bot_menu_display();

        if (botcam())
            return TRUE;
    }
    #endif
    return FALSE;
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Bot Chat code

The rest of this code is in bot_misc.qc

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
void(string h) BotSay = // simulate talking by composing a 'chat' message
{
    WriteByte(MSG_ALL, 8);
    #ifdef QUAKEWORLD
    WriteByte(MSG_ALL, 3);
    #endif
    WriteByte(MSG_ALL, 1);
    WriteString(MSG_ALL, self.netname);
    WriteByte(MSG_ALL, 8);
    #ifdef QUAKEWORLD
    WriteByte(MSG_ALL, 3);
    #endif
    WriteByte(MSG_ALL, 2);
    WriteString(MSG_ALL, h);
};
void() BotSayInit =
{
    WriteByte(MSG_ALL, 8);
    #ifdef QUAKEWORLD
    WriteByte(MSG_ALL, 3);
    #endif
    WriteByte(MSG_ALL, 1);
    WriteString(MSG_ALL, self.netname);
};
void(string h) BotSay2 =
{
    WriteByte(MSG_ALL, 8);
    #ifdef QUAKEWORLD
    WriteByte(MSG_ALL, 3);
    #endif
    WriteByte(MSG_ALL, 2);
    WriteString(MSG_ALL, h);
};
void(string h) BotSayTeam =
{
    // FBX QW doesn't support teamplay...yet
    #ifndef QUAKEWORLD
    local entity t;

    t = player_head;
    while(t)
    {
        if (t.team == self.team)
        {
            msg_entity = t;
            WriteByte(MSG_ONE, 8);
            WriteByte(MSG_ONE, 1);
            WriteByte(MSG_ONE, 40);
            WriteString(MSG_ONE, self.netname);
            WriteByte(MSG_ONE, 8);
            WriteByte(MSG_ONE, 2);
            WriteByte(MSG_ONE, 41);
            WriteString(MSG_ONE, h);
        }
        t = t._next;
    }
    #endif
};
/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BotInit

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/


void() BotInit =
{
    local entity ent, fisent;
    local float numents;

    // spawn entities for the physics
    ent = nextent(world);
    max_clients = 0;

    while(ent != world)
    {
        max_clients = max_clients + 1;
        ent = nextent(ent);
    }

    if (max_clients > 32)
        max_clients = 32;

    ent = nextent(world);
    fisent = world;
    while (numents < max_clients)
    {
        phys_head = spawn();
        if (fisent)
            fisent._next = phys_head;
        phys_head._last = fisent;
        fisent = phys_head;
        ent.phys_obj = phys_head;
        phys_head.classname = "phys_obj";
        phys_head.owner = ent;
        numents = numents + 1;
        ent = nextent(ent);
    }
    #ifndef QUAKEWORLD
    precache_model("progs/s_light.spr");
    precache_model("progs/s_bubble.spr");
    // the bots return!
    b_options = cvar("saved1");
    if (b_options & OPT_SAVEBOTS)
    {
        saved_bots = cvar("scratch1");
        saved_skills1 = cvar("scratch2");
        saved_skills2 = cvar("scratch3");
    }
    cvar_set ("saved4", "0");
    if (max_clients > 1)
    {
        localcmd("exec maps/");
        localcmd(mapname);
        localcmd(".way\n");
        waypoint_mode = WM_DYNAMIC;
        bot_map_load();
    }
    else
        waypoint_mode = WM_LOADED;
    #else
    waypoint_mode = WM_DYNAMIC;
    bot_map_load();
    #endif

};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Rankings 'utilities'. Written by Alan Kivlin,
this code just fools clients by sending precisely
the same network messages as when a real player
signs on to the server.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/


void(entity who) UpdateClient =
{
    #ifndef QUAKEWORLD
    WriteByte (MSG_ALL, SVC_UPDATENAME);
    WriteByte (MSG_ALL, who.b_clientno);
    WriteString (MSG_ALL, who.netname);
    WriteByte (MSG_ALL, SVC_UPDATECOLORS);
    WriteByte (MSG_ALL, who.b_clientno);
    WriteByte (MSG_ALL, who.b_shirt * 16 + who.b_pants);
    WriteByte (MSG_ALL, SVC_UPDATEFRAGS);
    WriteByte (MSG_ALL, who.b_clientno);
    WriteShort (MSG_ALL, who.frags);
    #else
    WriteByte(2, 14 );
    WriteByte(2, who.b_clientno);
    WriteShort(2, who.frags);
    WriteByte(2, 36);
    WriteByte(2, who.b_clientno);
    WriteShort(2, 100 * (3 - who.b_skill));
    WriteByte(2, 37);                // update entertime
    WriteByte(2, who.b_clientno);          // client number
    WriteLong(2, time - who.b_entertime);   // client entertime
    WriteByte(2, 40 );            // update userinfo
    WriteByte(2, who.b_clientno);      // client number
    WriteLong(2, who.b_userid);      // client userid
    WriteByte(2, 92); // \
    WriteByte(2, 98); // b
    WriteByte(2, 111); // o
    WriteByte(2, 116); // t
    WriteByte(2, 116); // t
    WriteByte(2, 111); // o
    WriteByte(2, 109); // m
    WriteByte(2, 99); // c
    WriteByte(2, 111); // o
    WriteByte(2, 108); // l
    WriteByte(2, 111); // o
    WriteByte(2, 114); // r
    WriteByte(2, 92); // \
    if(who.b_pants > 9)
    {
        WriteByte(2, 49);
        WriteByte(2, 38 + who.b_pants);
    }
    else
        WriteByte(2, 48 + who.b_pants);
    WriteByte(2, 92);  // \
    WriteByte(2, 116); // t
    WriteByte(2, 111); // o
    WriteByte(2, 112); // p
    WriteByte(2, 99);  // c
    WriteByte(2, 111); // o
    WriteByte(2, 108); // l
    WriteByte(2, 111); // o
    WriteByte(2, 114); // r
    WriteByte(2, 92);  // \
    if(who.b_shirt > 9)
    {
        WriteByte(2, 49);
        WriteByte(2, 38 + who.b_shirt);
    }
    else
        WriteByte(2, 48 + who.b_shirt);
    WriteByte(2, 92);  // \
    WriteByte(2, 116); // t
    WriteByte(2, 101); // e
    WriteByte(2, 97);  // a
    WriteByte(2, 109); // m
    WriteByte(2, 92);  // \
    WriteByte(2, 98);  // b
    WriteByte(2, 111); // o
    WriteByte(2, 116); // t
    // FIXME: do teams properly
    // note this has no effect on infokey
    WriteByte(2, 92 );  // \
    WriteByte(2, 115); // s
    WriteByte(2, 107); // k
    WriteByte(2, 105); // i
    WriteByte(2, 110); // n
    WriteByte(2, 92);  // \
    WriteByte(2, 98);  // b
    WriteByte(2, 97);  // a
    WriteByte(2, 115); // s
    WriteByte(2, 101); // e
    WriteByte(2, 92);  // \
    WriteByte(2, 110); // n
    WriteByte(2, 97);  // a
    WriteByte(2, 109); // m
    WriteByte(2, 101); // e
    WriteByte(2, 92);  // \
    WriteString( 2, who.netname);
    #endif
};

float(float clientno) ClientBitFlag =
{
    local float bitflag;
    bitflag = 1;
    while(clientno > 0)
    {
        bitflag = bitflag * 2;
        clientno = clientno - 1;
    }
    return bitflag;
};

float() ClientNextAvailable =
{
    local float clientno;

    // Note: FrikaC want to do this top down, but QW won't let him
    clientno = 0;
    while(clientno < max_clients)
    {
        if(!ClientIsActive(clientno))
            return clientno;

        clientno = clientno + 1;
    }

    return -1;
};


void(entity e1, entity e2, float flag) DeveloperLightning =
{
    #ifndef QUAKEWORLD
    // used to show waypoint links for debugging
    WriteByte (MSG_BROADCAST, 23);
    if (flag)
        WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
    else
        WriteByte (MSG_BROADCAST, TE_LIGHTNING3);
    WriteEntity (MSG_BROADCAST, e2);
    WriteCoord (MSG_BROADCAST, e1.origin_x);
    WriteCoord (MSG_BROADCAST, e1.origin_y);
    WriteCoord (MSG_BROADCAST, e1.origin_z);
    WriteCoord (MSG_BROADCAST, e2.origin_x);
    WriteCoord (MSG_BROADCAST, e2.origin_y);
    WriteCoord (MSG_BROADCAST, e2.origin_z);
    #endif
};


/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BotConnect and related functions.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
entity(float num) GetClientEntity =
{
    local entity upsy;
    upsy = world;
    num = num + 1;
    while (num > 0)
    {
        num = num - 1;
        upsy = nextent(upsy);
    }
    return upsy;
};

void(float whichteam, float whatbot, float whatskill) BotConnect =
{
    local float f;
    local string h;
    local entity uself;

    f = ClientNextAvailable();
    uself = self;
    if(f == -1)
    {
        Bprint (PRINT_HIGH, "Unable to connect a bot, server is full.\n");
        return;
    }

    // chat thing
    if(f > 16)
        active_clients2 = active_clients2 | ClientBitFlag(f - 16);
    else
        active_clients1 = active_clients1 | ClientBitFlag(f);

    bot_count = bot_count + 1;
    self = GetClientEntity(f);
    #ifndef QUAKEWORLD
    if (!saved_bots)
    #endif
        bot_start_topic(1);
    self.b_clientno = f;
    self.colormap = f + 1;
    if (whatbot)
        self.netname = BotName(whatbot);
    else
        self.netname = PickARandomName();

    // players can set skill all weird, so leave these checks in
    whatskill = rint(whatskill);
    if (whatskill > 3)
        whatskill = 3;
    else if (whatskill < 0)
        whatskill = 0;
    self.b_skill = whatskill;

    #ifdef QUAKEWORLD
    self.b_entertime = time;
    #endif

    UpdateClient(self);
    SetNewParms();
    self.ishuman = 2;
    ClientConnect();
    PutClientInServer();

    // Select a team at spawn time
    self.impulse = whichteam + 1;

    #ifndef QUAKEWORLD
    // this is risky... could corrupt .way files if done wrong
    // If you're not the gambling type, comment this out

    f = ClientBitFlag(self.b_num - 1);
    current_bots = current_bots | f;

    if (self.b_num <= 8)
        saved_skills1 = (saved_skills1 & (65536 - (3 * f)) | (self.b_skill * f));
    else
    {
        f = ClientBitFlag(self.b_num - 9);
        saved_skills2 = (saved_skills2 & (65536 - (3 * f)) | (self.b_skill * f));
    }

    h = ftos(current_bots);
    cvar_set("scratch1", h);
    h = ftos(saved_skills1);
    cvar_set("scratch2", h);
    h = ftos(saved_skills2);
    cvar_set("scratch3", h);
    #endif

    self = uself;

};

void(entity bot) BotDisconnect =
{
    local string h;
    local entity uself;
    uself = self;
    self = bot;

    bot_count = bot_count - 1;
    #ifndef QUAKEWORLD
    current_bots = current_bots - (current_bots & ClientBitFlag(self.b_num - 1));
    h = ftos(current_bots);
    cvar_set("scratch1", h);
    #endif

    ClientDisconnect();

    if (self.b_clientno != -1)
    {
        // the bot's client number is not in use by a real player so we
        // must remove it's entry in the rankings
        // Quake engine sets all fields to 0, can only do the most important here
        self.b_frags = self.frags = 0;
        self.netname = "";
        self.classname = "";
        self.health = 0;
        self.items = 0;
        self.armorvalue = 0;
        self.weaponmodel = "";
        self.b_pants = 0;
        self.b_shirt = 0;
        self.ammo_shells = self.ammo_nails = self.ammo_rockets = self.ammo_cells = 0;
        UpdateClient(self);
        if(self.b_clientno > 16)
            active_clients2 = active_clients2 - (active_clients2 & ClientBitFlag(self.b_clientno - 16));
        else
            active_clients1 = active_clients1 - (active_clients1 & ClientBitFlag(self.b_clientno));
        self.b_clientno = -1;
    }
    self = uself;
};
/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BotInvalidClientNo
kicks a bot if a player connects and takes the bot's space

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void(float clientno) BotInvalidClientNo =
{
    local entity bot;

    bot = GetClientEntity(clientno);
    if(bot.b_clientno > 0)
    {
        if (!bot.ishuman)
        {
            bot.b_clientno = -1;
            BotDisconnect(bot);
            if(self.b_clientno > 16)
                active_clients2 = active_clients2 | ClientBitFlag(self.b_clientno - 16);
            else
                active_clients1 = active_clients1 | ClientBitFlag(self.b_clientno);
            BotConnect(0, bot.b_num, bot.b_skill);
            return;
        }
    }
};

#ifndef QUAKEWORLD
/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Waypoint Loading from file

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
void() LoadWaypoint =
{
    local vector org;
    local entity tep;
    local float r;
    org_x = cvar("saved1");
    org_y = cvar("saved2");
    org_z = cvar("saved3");

    tep = make_waypoint(org);

    r = cvar("saved4");

    tep.b_aiflags = floor(r / 4);
    tep.b_pants = cvar("scratch1");
    tep.b_skill = cvar("scratch2");
    tep.b_shirt = cvar("scratch3");
    tep.b_frags = cvar("scratch4");
};

void() bot_return =
{
    if (time > 2)
    {
        if ((waypoint_mode == WM_DYNAMIC) || (waypoint_mode == WM_LOADED))
        {
            // minor precaution

            if (saved_bots & 1) BotConnect(0, 1, saved_skills1 & 3);
            if (saved_bots & 2) BotConnect(0, 2, (saved_skills1 & 12) / 4);
            if (saved_bots & 4) BotConnect(0, 3, (saved_skills1 & 48) / 16);
            if (saved_bots & 8) BotConnect(0, 4, (saved_skills1 & 192) / 64);
            if (saved_bots & 16) BotConnect(0, 5, (saved_skills1 & 768) / 256);
            if (saved_bots & 32) BotConnect(0, 6, (saved_skills1 & 3072) / 1024);
            if (saved_bots & 64) BotConnect(0, 7, (saved_skills1 & 12288) / 4096);
            if (saved_bots & 128) BotConnect(0, 8, (saved_skills1 & 49152) / 16384);
            if (saved_bots & 256) BotConnect(0, 9, saved_skills2 & 3);
            if (saved_bots & 512) BotConnect(0, 10, (saved_skills2 & 12) / 4);
            if (saved_bots & 1024) BotConnect(0, 11, (saved_skills2& 48) / 16);
            if (saved_bots & 2048) BotConnect(0, 12, (saved_skills2 & 192) / 64);
            if (saved_bots & 4096) BotConnect(0, 13, (saved_skills2 & 768) / 256);
            if (saved_bots & 8192) BotConnect(0, 14, (saved_skills2 & 3072) / 1024);
            if (saved_bots & 16384) BotConnect(0, 15, (saved_skills2 & 12288) / 4096);
            if (saved_bots & 32768) BotConnect(0, 16, (saved_skills2 & 49152) / 16384);
            saved_bots = 0;
        }
    }
};


void() WaypointWatch =
{
    // Waypoint Baywatch
    local float bigboobs;
    local string h;

    if (max_clients < 2)
        return;
    if (waypoint_mode != WM_UNINIT)
    {
        bigboobs = cvar("saved4");
        if (bigboobs != 0)
        {
            if ((bigboobs & 3) == 1)
                ClearAllWays();
            else if ((bigboobs & 3) == 3)
            {
                FixWaypoints();
                h = ftos(b_options);
                cvar_set("saved1", h);
                cvar_set("saved4", "0");
                cvar_set("scratch1", "0");
                waypoint_mode = WM_LOADED;
                return;
            }
            LoadWaypoint();
            waypoint_mode = WM_LOADING;
            cvar_set("saved4", "0");
        }
    }
};
#endif

void() BotFrame =
{
    local float num;
    #ifdef QUAKEWORLD
    local string h;

    h = infokey(world, "bot_options");
    b_options = stof(h);
    #endif

    // for the sake of speed
    sv_maxspeed = cvar("sv_maxspeed");
    sv_gravity = cvar("sv_gravity");
    sv_friction = cvar("sv_friction");
    sv_accelerate = cvar("sv_accelerate");
    sv_stopspeed = cvar("sv_stopspeed");
    real_frametime = frametime; // in NQ this is alright

    self = nextent(world);
    num = 0;
    while (num < max_clients)
    {
        if (self.ishuman == FALSE)
        {
            if (self.b_clientno > 0)
            {
                frik_obstacles();
                CL_KeyMove();
                SV_ClientThink();
                SV_Physics_Client();

                #ifdef QUAKEWORLD
                // this is sickening
                if (self.phys_obj)
                {
                    if (self.phys_obj.modelindex != self.modelindex)
                    {
                        setmodel(self.phys_obj, "progs/player.mdl");
                        self.phys_obj.modelindex = self.modelindex;
                    }
                    self.phys_obj.frame = self.frame;
                    self.phys_obj.angles = self.angles;
                    self.phys_obj.colormap = self.colormap;
                    self.phys_obj.effects = self.effects;
                }
                #endif
            }
        }
        self = nextent(self);
        num = num + 1;
    }

    #ifndef QUAKEWORLD
    WaypointWatch();

    if (saved_bots)
        bot_return();
    #endif
};
