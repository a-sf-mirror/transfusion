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

void () Taunt0;
void () Taunt1;
void () Taunt2;
void () Taunt3;
void () Taunt4;
void () Taunt5;
void () Taunt6;
void () Taunt7;
void () Taunt8;
void () Taunt9;

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BotName

Sets bot's name and colors

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
string(float r) BotName =
{
    self.b_num = r;
	self.b_pants = r;
    self.b_shirt = r;
	
    if (r == 1)
        return "Barker";

    else if (r == 2)
        return "Bloch";

    else if (r == 3)
        return "Bradbury";

    else if (r == 4)
        return "Campbell";

    else if (r == 5)
        return "DeSade";

    else if (r == 6)
        return "King";

    else if (r == 7)
        return "Koontz";

    else if (r == 8)
        return "Lee";

    else if (r == 9)
        return "Lovecraft";

    else if (r == 10)
        return "McCammon";

    else if (r == 11)
        return "Poe";

    else if (r == 12)
        return "Saul";

    else if (r == 13)
        return "Stine";

    else if (r == 14)
        return "Stoker";

    else if (r == 15)
        return "Straub";

    else if (r == 16)
    {
	    self.b_pants = 0;
        self.b_shirt = 0;
		return "Wells";
	}
	
	else
        return "FIX_ME_IN_BotName";
};
string () PickARandomName =
{
    if (bot_count > 16)
        return "player";

    local float y, test;
    local string h;
    local entity t;
    y = TRUE;
    while(y)
    {
        test = ceil(random() * 16);
        h = BotName(test);
        t = find(world, netname, h);
        if (t == world)
            y = FALSE;
    }
    return h;
};



// I didn't like the old code so this is very stripped down

entity b_originator;
float b_topic;
/* FBX Topics

b_originator == self
 1 - sign on
 2 - killed targ
 3 - team message "friendly eyes"
 4 - team message "on your back"
 5 - team message "need back up"
 6 - excuses
 ----
 7 - gameover
 ----
 8 - welcoming someone onto server
 9 - ridicule lost frag (killed self?)
 10 - ridicule lost frag (lava)
 11 - lag
b_originator == targ


*/
void(float tpic) bot_start_topic =
{
    if (random() <= 0.2)
    {
        b_topic = tpic;
        b_originator = self;
    }
    else
        b_topic = 0;
};

void() bot_chat =
{
    local float r;
	local float chat_strings;
	
	if (b_topic == 1)
	    chat_strings = 12;
	
	else if (b_topic == 2)
	    chat_strings = 8;

	else if (b_topic == 3 || b_topic == 4 || b_topic == 5)
	    chat_strings = 2;

	else if (b_topic == 6)
	    chat_strings = 7;
    
	else if (b_topic == 9)
	    chat_strings = 5;
	else
	    chat_strings = 6;

    r = ceil (random() * chat_strings);

    if (self.b_chattime > time)
    {
        if (self.b_skill < 2)
            self.keys = self.button0 = self.button2 = 0;
        return;
    }
    else if (self.b_chattime)
    {
        if (b_topic == 1)  // Spawning
        {
            if (b_originator == self)
            {
                if (r == 1)
                {
                    BotSay(": I have something for you...\n");
					Taunt4();
                }
                else if (r == 2)
                {
                    BotSay(": Fool - You're already dead\n");                    
					Taunt9();
                }                
				else if (r == 3)
				{
				    BotSay(": I live again!\n");
					localcmd("play player/taunts/t1010.wav\n");
				}
                else if (r == 4)
                {
				    BotSay(": All I want's a friend\n");
					localcmd("play player/taunts/t1005.wav\n");
				}
                else if (r == 5)
                {
				    BotSay(": Mmm fresh victims for the evergrowing army of the undead\n");
					localcmd("play player/quips/1001.wav\n");
				}
                else if (r == 6)
                {
				    BotSay(": They're all dead they just don't know it yet\n");
					localcmd("play player/quips/1014.wav\n");
				}                
				else if (r == 7)
                {
				    BotSay(": I got time to play with you\n");
					localcmd("play player/quips/1037.wav\n");
				}
				else if (r == 8)
                {
				    BotSay(": Come out come out wherever you are\n");
					localcmd("play player/quips/1038.wav\n");
				}
				else if (r == 9)
                {
				    BotSay(": I've got a present for ya!\n");
					localcmd("play player/quips/1017.wav\n");
				}
				else if (r == 10)
                {
				    BotSay(": Wow! This promises to be fun!\n");
					localcmd("play player/quips/1048.wav\n");
				}
				else if (r == 11)
                {
				    BotSay(": I'm going to have to put you down\n");
					localcmd("play player/quips/1053.wav\n");
				}
				else
                {
				    BotSay(": Run... Run...\n");
					localcmd("play player/quips/1083.wav\n");
				}
				bot_start_topic(0);
            }
        }
        else if (b_topic == 2) // Just killed someone
        {
            if (b_originator == self)
            {
			    if (self.items & IT_GUNS_AKIMBO)
				{
				    BotSay(": I've got two guns. That should be enough for all of you\n");
					localcmd("play player/quips/1018.wav\n");
				}					
				else if (self.weapon == IT_NAPALM_LAUNCHER)
				{
				    if (random() <= 0.5)
					{
					    BotSay(": I love the smell of napalm in the morning\n");
						Taunt0();
					}	
					else
					{
					    BotSay(": Hmmm... is that gasoline I smell?\n");
						Taunt1();
					}                
				}
				else if (random() <= 0.5 && self.weapon == IT_SAWED_OFF)
				{
				    BotSay(": This is my boomstick!\n");
					localcmd("play player/taunts/t1002.wav\n");
				}					
                else if (r == 1)
				{
                    BotSay(": Tada!\n");
					Taunt2();
				}
                else if (r == 2)
				{
                    BotSay(": Who wants some HUH? Who's next?\n");
					Taunt3();
				}                
                else if (r == 3)
                {
				    BotSay(": I want some more\n");
					localcmd("play player/quips/1012.wav\n");
				}				
				else if (r == 4)
				{
				    BotSay(": Rest in pieces!\n");
					localcmd("play player/quips/1057.wav\n");
				}				
				else if (r == 5)
				{
				    BotSay(": I did it my way\n");
					localcmd("play player/songs/1095.wav\n");
				}
				else if (r == 6)
				{
				    BotSay(": It's all in the reflexes\n");
					localcmd("play player/quips/1040.wav\n");
				}				
				else if (r == 7)
				{
					BotSay(": Pay attention son, this is for your own good\n");
					localcmd("play player/quips/1046.wav\n");
				}				
				else
				{
				    BotSay(": What are you gonna do, bleed on me?\n");
					localcmd("play player/quips/1054.wav\n");
				}
                bot_start_topic(0);
            }
        }
        else if (b_topic == 3)
        {
            if (b_originator == self)
            {
                if (r == 1)
                    BotSayTeam(": friendly eyes\n");
                else
                    BotSayTeam(": team eyes\n");
                bot_start_topic(0);
            }
        }
        else if (b_topic == 4)
        {
            if (b_originator == self)
            {
                if (r == 1)
                    BotSayTeam(": on your back\n");
                else
                    BotSayTeam(": I'm with you\n");
                bot_start_topic(0);
            }
        }
        else if (b_topic == 5)
        {
            if (b_originator == self)
            {
                if (r == 1)
                    BotSayTeam(": I need help\n");
                else
                    BotSayTeam(": need backup\n");
                bot_start_topic(0);
            }
        }
        else if (b_topic == 6) // Just died
        {
            if (b_originator == self)
            {
                if (r == 1)
                {
                    BotSay(": Oh, that wasn't a bit nice!\n");
					Taunt7();                    
                }
                else if (r == 2)
                {
				    BotSay(": Victims, aren't we all?\n");
					localcmd("play player/taunts/t1013.wav\n");
				}
                else if (r == 3)
                {
				    BotSay(": Mmm this looks extraordinarily bad\n");
					localcmd("play player/quips/1045.wav\n");
				}
                else if (r == 4)
                {
				    BotSay(": When does the hurting stop?\n");
					
					if (random() <= 0.5)
					    localcmd("play player/quips/1042.wav\n");
					else
					    localcmd("play player/quips/1044.wav\n");
				}
                else if (r == 5)
                {
				    BotSay(": Boo hoo when does the hurting stop?\n");
					localcmd("play player/quips/1043.wav\n");
				}
                else if (r == 6)
                {
				    BotSay(": I smell balm and puntane\n");
					localcmd("play player/quips/1041.wav\n");
				}
				else
                {
				    BotSay(": Help help! I'm being repressed\n");
					localcmd("play player/quips/1051.wav\n");
				}
				bot_start_topic(0);
            }
        }
        else if (b_topic == 7)
        {
		    BotSay(": Good game\n");
			bot_start_topic(0);
        }
        else if (b_topic == 8)
        {
            if (b_originator != self)
            {
                if (r == 1)
                {
                    BotSay(": heya\n");
                    bot_start_topic(0);
                }
                else if (r == 2)
                {
                    BotSay(": welcome\n");
                    bot_start_topic(0);
                }
                else if (r == 3)
                {
                    BotSayInit();
                    BotSay2(": hi ");
                    BotSay2(b_originator.netname);
                    BotSay2("\n");
                    bot_start_topic(0);
                }
                else if (r == 4)
                {
                    BotSayInit();
                    BotSay2(": hey ");
                    BotSay2(b_originator.netname);
                    BotSay2("\n");
                    bot_start_topic(0);
                }
                else if (r == 5)
                {
                    BotSay(": howdy\n");
                    bot_start_topic(0);
                }
                else
                {
                    BotSay(": lo\n");
                    bot_start_topic(0);
                }
            }
        }

        else if (b_topic == 9)
        {
            if (b_originator != self)
            {
                if (r == 1)
				{
                    BotSay(": Amateurs\n");
					Taunt8();					
				}
				else if (r == 2)
				{
                    BotSay(": Are you just gonna stand there and bleed?\n");
					Taunt5();
				}
                else if (r == 3)
				{
                    BotSay(": That'll teach ya\n");
					Taunt6();
				}
				else if (r == 4)
				{
				    BotSay(": Hmmm. Extraordinary use of color. The composition is a bit lacking\n");
					localcmd("play player/quips/1055.wav\n");
				}				
				else
				{
					BotSay(": Lambs to the slaughter\n");
					localcmd("play player/quips/1027.wav\n");
				}
				bot_start_topic(0);
            }
        }
        else if (b_topic == 10)
        {
            if (b_originator != self)
            {
                if (r == 1)
                    BotSay(": have a nice dip?\n");
                else if (r == 2)
                    BotSay(": bah I hate levels with lava\n");
                else if (r == 3)
                {
                    BotSayInit();
                    BotSay2(": good job ");
                    BotSay2(b_originator.netname);
                    BotSay2("\n");
                }
                else if (r == 4)
                {
                    BotSayInit();
                    BotSay2(": nice backflip ");
                    BotSay2(b_originator.netname);
                    BotSay2("\n");
                }
                else if (r == 5)
                    BotSay(": watch your step\n");
                else
                    BotSay(": hehe\n");
                b_topic = 6;
            }
        }

        else if (b_topic == 11)
        {
            if (b_originator != self)
            {
                BotSay(": Lag...\n");
                    bot_start_topic(0);
            }
        }
        self.b_chattime = 0;
    }
    else if (b_topic)
    {
        if (random() < 0.5)
        {
            if (self == b_originator)
            {
                if (b_topic <= 7)
                    self.b_chattime = time + 2;
            }
            else
            {
                if (b_topic >= 7)
                    self.b_chattime = time + 2;
            }
        }
    }
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Kick A Bot.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void() World_CheckWarmup;
void() KickABot =
{
    local entity ty;
    ty = find(world, classname, "player");
    while (ty != world)
    {
        if (!(ty.ishuman))
        {
            BotDisconnect(ty);
            ty.ishuman = TRUE;
            World_CheckWarmup ();
            return;
        }

        ty = find(ty, classname, "player");
    }
};


/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Simplified origin checking.

God, I wish I had inline

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

vector(entity ent) realorigin =
{
// even more simplified...
    return (ent.absmin + ent.absmax) * 0.5;
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

fisible

a version of visible that checks for corners
of the bounding boxes

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

float (entity targ) fisible =
{
    local vector    spot1, org;
    local float thruwater, pc1, pc2;

    org = realorigin(targ);
    spot1 = self.origin + self.view_ofs;

    if (targ.solid == SOLID_BSP)
    {
        traceline (spot1, org, TRUE, self);
        if (trace_ent == targ)
            return TRUE;
        else if (trace_fraction == 1)
            return TRUE;
        return FALSE;
    }
    else
    {
        pc1 = pointcontents(org);
        pc2 = pointcontents(spot1);
        if (targ.classname == "player")
            thruwater = FALSE;
        else if (pc1 == CONTENT_LAVA)
            return FALSE;
        else
            thruwater = TRUE;
    }

    if (pc1 < -1) // targ's origin is in water or other liquid
    {
        if (pc2 != pc1)
        {
            // look for their head
            traceline (spot1, org + targ.mins, TRUE, self);
            // cross the water check
            if (trace_inopen)
                if (trace_inwater)
                    if (!thruwater)
                        return FALSE;
            if (trace_ent == targ)
                return TRUE;
            else if (trace_fraction == 1)
                return TRUE;
            return FALSE;
        }
    }
    else
    {
        if (pc2 != pc1)
        {
            traceline (spot1, org + targ.maxs, TRUE, self);
            if (trace_inopen)
                if (trace_inwater)
                    if (!thruwater)
                        return FALSE;
            if (trace_ent == targ)
                return TRUE;
            else if (trace_fraction == 1)
                return TRUE;
            return FALSE;
        }
    }
    traceline (spot1, org, TRUE, self);
    if (trace_ent == targ)
        return TRUE;
    else if (trace_fraction == 1)
        return TRUE;
    traceline (spot1, org + targ.maxs, TRUE, self);
    if (trace_ent == targ)
        return TRUE;
    else if (trace_fraction == 1)
        return TRUE;
    traceline (spot1, org + targ.mins, TRUE, self);
    if (trace_ent == targ)
        return TRUE;
    else if (trace_fraction == 1)
        return TRUE;
    return FALSE;
};


/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Wisible

goes through movable brushes/entities, used
for waypoints

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

// this is used for waypoint stuff....
float (entity targ1, entity targ2) wisible =
{
    local vector    spot1, spot2;
    local entity ignore;

    spot1 = targ1.origin;
    spot2 = realorigin(targ2);

    ignore = self;
    do
    {
        traceline (spot1, spot2, TRUE, ignore);
        spot1 = realorigin(trace_ent);
                ignore = trace_ent;
    } while ((trace_ent != world) && (trace_fraction != 1));
    if (trace_endpos == spot2)
        return TRUE;
    else
        return FALSE;
};


/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

sisible

Now this is getting ridiculous. Simple visible,
used when we need just a simple traceline nothing else

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

float (entity targ) sisible =
{
    traceline (self.origin, targ.origin, TRUE, self);
    if (trace_ent == targ)
        return TRUE;
    else if (trace_fraction == 1)
        return TRUE;
};
/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

angcomp

subtracts one angle from another

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

float (float y1, float y2) angcomp =
{
    y1 = frik_anglemod(y1);
    y2 = frik_anglemod(y2);

    local float answer;
    answer = y1 - y2;
    if (answer > 180)
        answer = (360 - answer) * -1;
    else if (answer < -180)
        answer = answer + 360;
    return answer;
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

fov

is the entity in the bot's field of view

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
float (entity targ) fov =
{
    local vector yawn;
    local float g;
    yawn = realorigin(targ);
    yawn = (yawn + targ.view_ofs) - (self.origin + self.view_ofs);
    yawn = normalize(yawn);
    yawn = vectoangles(yawn);
    g = angcomp(self.v_angle_x, yawn_x);
    if (fabs(g) > 45)
        return FALSE;
    g = angcomp(self.v_angle_y, yawn_y);
    if (fabs(g) > 60)
        return FALSE;

    return TRUE;
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

frik_anglemod

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
float(float v) frik_anglemod =
{
    return v - floor(v/360) * 360;
};


#endif  // #ifndef NO_FRIKBOT
