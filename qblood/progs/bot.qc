/*  Copyright (C) 2001-2002  Mathieu Olivier

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


#ifndef NO_FRIKBOT

#include "common.qh"
#include "bot.qh"

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

// -------globals-----
float   active_clients;
float   max_clients, real_frametime;
float   bot_count;
float   waypoint_mode, dump_mode;
float   waypoints, direct_route;
float   sv_friction, sv_gravity;
float   sv_accelerate, sv_maxspeed, sv_stopspeed;
entity  fixer;
entity  route_table;
entity  b_temp1, b_temp2, b_temp3;
entity  player_head, player_tail, phys_head, way_head;
float   busy_waypoints;
float   saved_bots, current_bots;

// -------ProtoTypes------
// external
void()              ClientConnect;
void()              ClientDisconnect;
void()              SetNewParms;

// rankings
float(float clientno)       ClientBitFlag;
float()                     ClientNextAvailable;
void(float whichteam, float whatbot, float whatskill) BotConnect;
void(entity bot)            BotDisconnect;
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


// editor stuffs
void()              bot_way_edit;
void()              bot_menu_display;


// ----------Commands---------
void(entity e, float chan, string samp, float vol, float atten) frik_sound = #8;
void(entity client, string s)                           frik_stuffcmd = #21;
void(entity client, string s)                           frik_sprint = #24;
void(entity client, string s1, string s2)               frik_sprint2 = #24;
void(entity client, string s1, string s2, string s3)    frik_sprint3 = #24;
vector(entity e, float sped)                            frik_aim = #44;
void(float to, float f)                                 frik_WriteByte = #52;
void(float to, float f)                                 frik_WriteChar = #53;
void(float to, float f)                                 frik_WriteShort = #54;
void(float to, float f)                                 frik_WriteLong = #55;
void(float to, float f)                                 frik_WriteCoord = #56;
void(float to, float f)                                 frik_WriteAngle = #57;
void(float to, string s)                                frik_WriteString = #58;
void(float to, entity s)                                frik_WriteEntity = #59;
void(entity client, string s)                           frik_centerprint = #73;
void(entity client, string s1, string s2)               frik_centerprint2 = #73;
void(entity client, string s1, string s2, string s3)    frik_centerprint3 = #73;
void(entity client, string s1, string s2, string s3, string s4, string s5, string s6, string s7) frik_centerprint7 = #73;
void(entity e)                                          frik_setspawnparms = #78;


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
};

void(entity e) setspawnparms =
{
    if (e.ishuman == 1)
        frik_setspawnparms(e);
    else
    {
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
        SetNewParms();
    }
};

void(entity client, string s) sprint =
{
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
};

void(entity client, string s1, string s2) sprint2 =
{
    if (client.ishuman == 1)
        frik_sprint2 (client, s1, s2);
    b_temp1 = player_head;

    while(b_temp1)
    {
        if (b_temp1.classname == "botcam")
        {
            if ((b_temp1.enemy == client) && b_temp1.ishuman)
                frik_sprint2 (b_temp1, s1, s2);
        }
        b_temp1 = b_temp1._next;
    }
};

void(entity client, string s1, string s2, string s3) sprint3 =
{
    if (client.ishuman == 1)
        frik_sprint3 (client, s1, s2, s3);
    b_temp1 = player_head;

    while(b_temp1)
    {
        if (b_temp1.classname == "botcam")
        {
            if ((b_temp1.enemy == client) && b_temp1.ishuman)
                frik_sprint3 (b_temp1, s1, s2, s3);
        }
        b_temp1 = b_temp1._next;
    }
};

void(entity client, string s) centerprint =
{
    if (client.ishuman == 1)
        frik_centerprint(client, s);
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
};

void(entity client, string s1, string s2) centerprint2 =
{
    if (client.ishuman == 1)
        frik_centerprint2(client, s1, s2);
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
};

void(entity client, string s1, string s2, string s3) centerprint3 =
{
    if (client.ishuman == 1)
        frik_centerprint3(client, s1, s2, s3);
    b_temp1 = player_head;

    while(b_temp1)
    {
        if (b_temp1.classname == "botcam")
        {
            if ((b_temp1.enemy == client) && b_temp1.ishuman)
                frik_centerprint3(b_temp1, s1, s2, s3);
        }
        b_temp1 = b_temp1._next;
    }
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
    return (active_clients & ClientBitFlag (clientno)) != 0;
};


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

    self.impulse = IMP_NONE;
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
    sprint3 (self, "Now tracking ", self.enemy.netname, "\n");
};


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

void() Bot_ClientConnect =
{
    local float cno;

    cno = self.colormap - 1;

    // If it's a real new player
    if (self.ishuman == 0)
    {
        // If there's no free spot left for another player, we kick a bot
        if (ClientNextAvailable () == -1)
            if (bot_count)
                KickABot ();

        // Sanity check: make sure the new player hasn't taken the entity of an existing bot
        if (ClientIsActive (cno))
            error ("ClientInRankings: new human player entity was used by a bot");
    }

    if (player_head)
        player_head._last = self;

    self._next = player_head;
    self._last = world;
    player_head = self;
    if (!player_tail)
        player_tail = self;

    if (!self.phys_obj)
    {
        b_temp2 = phys_head;
        while (b_temp2 != world && b_temp2.owner != self)
            b_temp2 = b_temp2._next;
        self.phys_obj = b_temp2;
    }

    // If it's a bot
    if (self.ishuman == 2)
    {
        self.ishuman = FALSE;
        return;
    }
    active_clients = active_clients | ClientBitFlag (cno);

    self.b_clientno = cno;
    self.ishuman = TRUE;
    self.switch_wallhug = time + 1;
};


void() Bot_ClientDisconnect =
{
    if (player_head == self)
        player_head = self._next;
    if (player_tail == self)
        player_tail = self._last;
    if (self._next)
        self._next._last = self._last;
    if (self._last)
        self._last._next = self._next;

    active_clients = active_clients - (active_clients & ClientBitFlag (self.b_clientno));

    // If it's a real player, reset the client number
    if (self.ishuman)
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
        if (self.classname == "botcam")
            return TRUE;
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
    }
    DynamicWaypoint();
    return FALSE;
};
float () BotPostFrame =
{
    if (self.b_clientno == -1)
        return TRUE;
    if (self.ishuman)
    {
        if (waypoint_mode > WM_LOADED)
            bot_menu_display();

        if (botcam())
            return TRUE;
    }
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
    WriteByte(MSG_ALL, 1);
    WriteString(MSG_ALL, self.netname);
    WriteByte(MSG_ALL, 8);
    WriteByte(MSG_ALL, 2);
    WriteString(MSG_ALL, h);
};
void() BotSayInit =
{
    WriteByte(MSG_ALL, 8);
    WriteByte(MSG_ALL, 1);
    WriteString(MSG_ALL, self.netname);
};
void(string h) BotSay2 =
{
    WriteByte(MSG_ALL, 8);
    WriteByte(MSG_ALL, 2);
    WriteString(MSG_ALL, h);
};
void(string h) BotSayTeam =
{
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
};
/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BotInit

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/


void() Bot_Init =
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

    // We can't support more than 16 clients
    if (max_clients > 16)
        max_clients = 16;

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
    precache_model("progs/s_light.spr");
    precache_model("progs/s_bubble.spr");
    // the bots return!
    saved_bots = cvar ("scratch1");
    cvar_set ("saved4", "0");
    if (max_clients > 1)
    {
        localcmd("exec maps/");
        localcmd(mapname);
        localcmd(".way\n");
        waypoint_mode = WM_DYNAMIC;
    }
    else
        waypoint_mode = WM_LOADED;

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
    WriteByte (MSG_ALL, SVC_UPDATENAME);
    WriteByte (MSG_ALL, who.b_clientno);
    WriteString (MSG_ALL, who.netname);
    WriteByte (MSG_ALL, SVC_UPDATECOLORS);
    WriteByte (MSG_ALL, who.b_clientno);
    WriteByte (MSG_ALL, who.b_shirt * 16 + who.b_pants);
    WriteByte (MSG_ALL, SVC_UPDATEFRAGS);
    WriteByte (MSG_ALL, who.b_clientno);
    WriteShort (MSG_ALL, who.frags);
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
    local float found;

    found = -1;
    clientno = max_clients - 1;
    while (clientno >= 0)
    {
        if (!ClientIsActive (clientno))
        {
            // We make sure to leave one free spot for a real player
            if (found != -1)
                return found;
            found = clientno;
        }

        clientno = clientno - 1;
    }

    return -1;
};


void(entity e1, entity e2, float flag) DeveloperLightning =
{
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

    if (gametype == GT_SINGLE_PLAYER || gametype == GT_COOPERATIVE)
	    return;
	
	f = ClientNextAvailable();
    uself = self;
    if(f == -1)
    {
        bprint ("Unable to connect a bot (no more room)\n");
        return;
    }

    // chat thing
    active_clients = active_clients | ClientBitFlag (f);

    bot_count = bot_count + 1;
    self = GetClientEntity(f);

    if (!saved_bots)
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

    UpdateClient(self);
    SetNewParms();
    self.ishuman = 2;
    ClientConnect();
    PutClientInServer();

    // Select a team at spawn time
    self.impulse = whichteam + 1;

    // this is risky... could corrupt .way files if done wrong
    // If you're not the gambling type, comment this out

    f = ClientBitFlag(self.b_num - 1);
    current_bots = current_bots | f;

    h = ftos(current_bots);
    cvar_set("scratch1", h);

    self = uself;

};

void(entity bot) BotDisconnect =
{
    local string h;
    local entity uself;
    uself = self;
    self = bot;

    bot_count = bot_count - 1;
    current_bots = current_bots - (current_bots & ClientBitFlag(self.b_num - 1));
    h = ftos(current_bots);
    cvar_set("scratch1", h);

    ClientDisconnect();

    // We must remove The bot's client number entry in the rankings
    // Quake engine sets all fields to 0, can only do the most important here
    self.b_frags = self.frags = 0;
    self.netname = string_null;
    self.classname = string_null;
    self.health = 0;
    self.items = 0;
    self.armorvalue = 0;
    self.weaponmodel = string_null;
    self.b_pants = 0;
    self.b_shirt = 0;
    self.ammo_shells = self.ammo_nails = self.ammo_rockets = self.ammo_cells = 0;
    UpdateClient(self);
    active_clients = active_clients - (active_clients & ClientBitFlag (self.b_clientno));
    self.b_clientno = -1;

    self = uself;
};


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

void() Bot_Return =
{
    // Don't return bots if they've been disabled
    if (cvar ("sv_disable") & SV_DISABLE_BOTS)
    {
        saved_bots = 0;
        return;
    }

    if (time > 2)
    {
        if ((waypoint_mode == WM_DYNAMIC) || (waypoint_mode == WM_LOADED))
        {
            local float botskill;
            local float num, bit;

            botskill = cvar ("skill");
            num = 1;
            bit = 1;

            while (num <= 16)
            {
                if (saved_bots & bit)
                    BotConnect (num & 1, num, botskill);

                num = num + 1;
                bit = bit * 2;
            }

            saved_bots = 0;
        }
    }
};


void() WaypointWatch =
{
    // Waypoint Baywatch
    local float bigboobs;

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

void() Bot_Frame =
{
    if (intermission_running)
        return;

    local float num;

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
            }
        }
        self = nextent(self);
        num = num + 1;
    }

    WaypointWatch();

    if (saved_bots)
        // Don't respawn bots until at least 1 player has entered the game
        if (active_clients)
            Bot_Return();
};


#endif  // #ifndef NO_FRIKBOT
