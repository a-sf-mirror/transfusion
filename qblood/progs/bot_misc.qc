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

void (float snd) Taunt;

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
	    chat_strings = 23;
    
	else if (b_topic == 9)
	    chat_strings = 15;
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
					Taunt(4);
                }
                else if (r == 2)
                {
                    BotSay(": Fool - You're already dead\n");                    
					Taunt(9);
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
				else if (r == 12)
                {
				    BotSay(": Run... Run...\n");
					localcmd("play player/quips/1083.wav\n");
				}
				else if (r == 13)
                {
                    BotSay(": Bring it on!\n");
                    localcmd("play blood2/spawn/1acaleb1.wav\n");
				}
				else if (r == 14)
                {
                    BotSay(": Everybody dies!\n");
                    localcmd("play blood2/spawn/C_1LINER_2.WAV\n");
				}
				else if (r == 15)
                {
                    BotSay(": Everybody dies\n");
                    localcmd("play blood2/spawn/C_1LINER_3.WAV\n");
				}
				else if (r == 16)
                {
                    BotSay(": I am death, who wants some?\n");
                    localcmd("play blood2/spawn/C_1LINER_6.WAV\n");
				}
				else if (r == 17)
                {
                    BotSay(": Hmmm, I'll take a BLT.  That's a lettuce, tomato and blood sandwich.  Hold the mayo\n");
                    localcmd("play blood2/spawn/E1M3_3_CAL.WAV\n");
				}
				else if (r == 18)
                {
                    BotSay(": Looks like there's killin to do\n");
                    localcmd("play blood2/spawn/E1M4_1_CAL.WAV\n");
				}
				else if (r == 19)
                {
                    BotSay(": Ah, this place is a hell hole.  I like it!\n");
                    localcmd("play blood2/spawn/E1M4_2_CAL.WAV\n");
				}
				else if (r == 20)
                {
                    BotSay(": All in all, I'd rather be killing stuff.\n");
                    localcmd("play blood2/spawn/E2M2_3_CAL.WAV\n");
				}
				else if (r == 21)
                {
                    BotSay(": It's howdy doody time kiddies - the bad man is here!\n");
                    localcmd("play blood2/spawn/E2M5_1_CAL.WAV\n");
				}
				else if (r == 22)
                {
                    BotSay(": I'm no mechanic, I just mostly hurt people.\n");
                    localcmd("play blood2/spawn/E3M3_3_CAL.WAV\n");
				}
				else if (r == 23)
                {
                    BotSay(": You know, this place almost seems unreal...\n");
                    localcmd("play blood2/spawn/E3M5_1_CAL.WAV\n");
				}
				else if (r == 24)
                {
                    BotSay(": Time to start piling up the bodies\n");
                    localcmd("play blood2/spawn/PWRUP1_CAL.WAV\n");
				}
				else if (r == 25)
                {
                    BotSay(": Dead man walking\n");
                    localcmd("play blood2/spawn/SPAWN3_CAL.WAV\n");
				}
				else if (r == 26)
                {
                    BotSay(": Be careful now, you'll shoot your eye out\n");
                    localcmd("play blood2/spawn/tnt12cal.wav\n");
				}
				else if (r == 27)
                {
                    BotSay(": Today is the last day of the rest of your life\n");
                    localcmd("play blood2/spawn/tnt13cal.wav\n");
				}
				else if (r == 28)
                {
                    BotSay(": I'll beat you like a bad stepchild\n");
                    localcmd("play blood2/spawn/tnt2_cal.wav\n");
				}
				else if (r == 29)
                {
                    BotSay(": I'm your best reason to be afraid\n");
                    localcmd("play blood2/spawn/tnt4_cal.wav\n");
				}
				else if (r == 30)
                {
                    BotSay(": They're going to need a bucket and a mop when I'm through with you\n");
                    localcmd("play blood2/spawn/tnt6_cal.wav\n");
				}
				else
                {
                    BotSay(": Are you feelin lucky?\n");
                    localcmd("play blood2/spawn/tnt8_cal.wav\n");
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
                    local float TempSound;

                    TempSound = ceil (random() * 3);

				    if (TempSound == 1)
					{
					    BotSay(": I love the smell of napalm in the morning\n");
						Taunt(0);
					}	
					else if (TempSound == 2)
					{
					    BotSay(": Hmmm... is that gasoline I smell?\n");
						Taunt(1);
					}
                    else
                    {
                        BotSay(": Now we're cooking with gas!\n");
                        localcmd("play blood2/murdered/E3M1_2_CAL.WAV\n");
    				}
				}
                else if (self.weapon == IT_FLAREGUN || self.weapon == IT_SPRAY_CAN)
                {
                    local float TempSound;

                    TempSound = ceil (random() * 5);

                    if (TempSound == 1)
					{
                        BotSay(": Now that's one hell of a foundeau! Hoo hoo hoo hoo!\n");
                        localcmd("play blood2/murdered/E1M1_9_CALA.WAV\n");
				    }
				    else if (TempSound == 2)
                    {
                        BotSay(": Now that's what I call a barbeque.  Mmm... lot's of sauce!\n");
                        localcmd("play blood2/murdered/E1M1_9_CALB.WAV\n");
	    			}
    				else if (TempSound == 3)
                    {
                        BotSay(": Ooh! Now that's what I call a barbeque.  Hehehe!\n");
                        localcmd("play blood2/murdered/E1M1_9_CALC.WAV\n");
    				}
				    else if (TempSound == 4)
                    {
                        BotSay(": Time for a barbeque\n");
                        localcmd("play blood2/murdered/msc7_cal.wav\n");
    				}
				    else
                    {
                        BotSay(": How do you like your flesh cooked?\n");
                        localcmd("play blood2/murdered/tnt7_cal.wav\n");
    				}
                }
				else if (random() <= 0.5 && self.weapon == IT_SAWED_OFF)
				{
				    if (random() <= 0.5)
					{
                        BotSay(": This is my boomstick!\n");
    					localcmd("play player/taunts/t1002.wav\n");
                    }
                    else
                    {
                        BotSay(": Now this is what I call a boom stick\n");
                        localcmd("play blood2/murdered/msc1_cal.wav\n");
    				}                    
				}					
                else if (r == 1)
				{
                    BotSay(": Tada!\n");
					Taunt(2);
				}
                else if (r == 2)
				{
                    BotSay(": Who wants some HUH? Who's next?\n");
					Taunt(3);
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
				else if (r == 8)
				{
				    BotSay(": What are you gonna do, bleed on me?\n");
					localcmd("play player/quips/1054.wav\n");
				}
				else if (r == 9)
                {
                    BotSay(": When you get to hell, tell them I sent you.  You'll get a discount\n");
                    localcmd("play blood2/murdered/11caleb2.wav\n");
				}
				else if (r == 10)
                {
                    BotSay(": Relax.  You're dead!\n");
                    localcmd("play blood2/murdered/16caleb1.wav\n");
				}
				else if (r == 11)
                {
                    BotSay(": Gimme some sugar baby!\n");
                    localcmd("play blood2/murdered/16caleb2.wav\n");
				}
				else if (r == 12)
                {
                    BotSay(": What are you going to do? SPANK me?\n");
                    localcmd("play blood2/murdered/20caleb2.wav\n");
				}
				else if (r == 13)
                {
                    BotSay(": And me, without a spoon\n");
                    localcmd("play blood2/murdered/BGGIB4_CAL.WAV\n");
				}
				else if (r == 14)
                {
                    BotSay(": You've looked better, but not by much\n");
                    localcmd("play blood2/murdered/C_1LINER_1.WAV\n");
				}
				else if (r == 15)
                {
                    BotSay(": That's right!  Who's laughing now?!?!\n");
                    localcmd("play blood2/murdered/C_1LINER_5.WAV\n");
				}				
				else if (r == 16)
                {
                    BotSay(": Resistance is futile!\n");
                    localcmd("play blood2/murdered/gen2_cal.wav\n");
				}
				else if (r == 17)
                {
                    BotSay(": Blood drops keep falling on my head...\n");
                    localcmd("play blood2/murdered/IDLE2_CAL.WAV\n");
				}
				else if (r == 18)
                {
                    BotSay(": If you think I'm sexy - and you want my body...\n");
                    localcmd("play blood2/murdered/IDLE3_CAL.WAV\n");
				}
				else if (r == 19)
                {
                    BotSay(": I never learned how to play nice\n");
                    localcmd("play blood2/murdered/KILL10CAL1.WAV\n");
				}
				else if (r == 20)
                {
                    BotSay(": What we have here is a failure to coagulate\n");
                    localcmd("play blood2/murdered/KILL10CAL2.WAV\n");
				}
				else if (r == 21)
                {
                    BotSay(": Aw, no one wants to play with me\n");
                    localcmd("play blood2/murdered/KILL11CAL.WAV\n");
				}
				else if (r == 22)
                {
                    BotSay(": That will teach ya\n");
                    localcmd("play blood2/murdered/KILL12CAL.WAV\n");
				}
				else if (r == 23)
                {
                    BotSay(": That will teach ya!\n");
                    localcmd("play blood2/murdered/KILL16CAL.WAV\n");
				}
				else if (r == 24)
                {
                    BotSay(": Aw, did I hurt your feelings?\n");
                    localcmd("play blood2/murdered/KILL2_CALA.WAV\n");
				}
				else if (r == 25)
                {
                    BotSay(": You must have blinked\n");
                    localcmd("play blood2/murdered/KILL2_CALB.WAV\n");
				}
				else if (r == 26)
                {
                    BotSay(": That's right!  Who's laughing now?\n");
                    localcmd("play blood2/murdered/KILL3_CAL.WAV\n");
				}
				else if (r == 27)
                {
                    BotSay(": Another day, another corpse\n");
                    localcmd("play blood2/murdered/KILL4_CAL.WAV\n");
				}
				else if (r == 28)
                {
                    BotSay(": Another day, another corpse, another reason for making whoopie\n");
                    localcmd("play blood2/murdered/KILL5_CAL.WAV\n");
				}
				else if (r == 29)
                {
                    BotSay(": Red is definitely your color\n");
                    localcmd("play blood2/murdered/KILL6_CAL.WAV\n");
				}
				else if (r == 30)
                {
                    BotSay(": Lucky you, killed by the best!\n");
                    localcmd("play blood2/murdered/KILL7_CAL.WAV\n");
				}
				else if (r == 31)
                {
                    BotSay(": Another notch on the barrel\n");
                    localcmd("play blood2/murdered/KILL9_CAL.WAV\n");
				}
				else if (r == 32)
                {
                    BotSay(": Hehe\n");
                    localcmd("play blood2/murdered/LAUGH1_CALA.WAV\n");
				}
				else if (r == 33)
                {
                    BotSay(": Haha\n");
                    localcmd("play blood2/murdered/LAUGH1_CALB.WAV\n");
				}
				else if (r == 34)
                {
                    BotSay(": I'd say I'm sorry, but you know it wouldn't be sincere\n");
                    localcmd("play blood2/murdered/msc11cal.wav\n");
				}
				else if (r == 35)
                {
                    BotSay(": What a mess, these conditions are hardly sanitary\n");
                    localcmd("play blood2/murdered/MSC16_CAL.WAV\n");
				}
				else if (r == 36)
                {
                    BotSay(": Hmm, point away from face and fire.  Sounds easy enough\n");
                    localcmd("play blood2/murdered/msc2_cal.wav\n");
				}
				else if (r == 37)
                {
                    BotSay(": There going to need a closed casket now!\n");
                    localcmd("play blood2/murdered/PWRUP2_CAL.WAV\n");
				}
				else if (r == 38)
                {
                    BotSay(": Your bad day just got worse\n");
                    localcmd("play blood2/murdered/tnt1_cal.wav\n");
				}
				else if (r == 39)
                {
                    BotSay(": When you get to hell, tell them I sent you.  You'll get a group discount\n");
                    localcmd("play blood2/murdered/tnt3_cal.wav\n");
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
					Taunt(7);                    
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
				else if (r == 7)
                {
				    BotSay(": Help help! I'm being repressed\n");
					localcmd("play player/quips/1051.wav\n");
				}
				else if (r == 8)
                {
				    BotSay(": Aw... you're gonna hurt my feelings\n");
				    localcmd("play blood2/died/17caleb2.wav\n");
				}
				else if (r == 9)
                {
				    BotSay(": Ooh... this could be bad!\n");
				    localcmd("play blood2/died/5caleb1.wav\n");
				}
				else if (r == 10)
                {
				    BotSay(": Ooh... you son of a ...!\n");
				    localcmd("play blood2/died/C_1LINER_4.WAV\n");
				}
				else if (r == 11)
                {
				    BotSay(": Mmm... this is going to get a lot worse before it get's better\n");
				    localcmd("play blood2/died/E1M5_3_CAL.WAV\n");
				}
				else if (r == 12)
                {
				    BotSay(": My momma said there'd be days like this.  I never liked her\n");
				    localcmd("play blood2/died/E2M3_2_CAL.WAV\n");
				}
				else if (r == 13)
                {
				    BotSay(": Ah... I feel like a piece of meat\n");
				    localcmd("play blood2/died/E2M5_4_CAL.WAV\n");
				}
				else if (r == 14)
                {
				    BotSay(": You know, I should have taken a job in construction\n");
				    localcmd("play blood2/died/E2M7_1_CAL.WAV\n");
				}
				else if (r == 15)
                {
				    BotSay(": This is unbelivably bad!\n");
				    localcmd("play blood2/died/E3M1_4_CAL.WAV\n");
				}
				else if (r == 16)
                {
				    BotSay(": I've just about had enough of you\n");
				    localcmd("play blood2/died/KILL14CAL.WAV\n");
				}
				else if (r == 17)
                {
				    BotSay(": Umm... That wasn't a bit nice\n");
				    localcmd("play blood2/died/MSC10CALA.WAV\n");
				}
				else if (r == 18)
                {
				    BotSay(": Make the hurting stop!\n");
				    localcmd("play blood2/died/pn2_cal.wav\n");
				}
				else if (r == 19)
                {
				    BotSay(": I wish you wouldn't do that\n");
				    localcmd("play blood2/died/pn8_cal1.wav\n");
				}
				else if (r == 20)
                {
				    BotSay(": Make the hurting stop\n");
				    localcmd("play blood2/died/pn8_cal2.wav\n");
				}
				else if (r == 21)
                {
				    BotSay(": Little thing like death never stopped me!\n");
				    localcmd("play blood2/died/SPAWN2_CAL.WAV\n");
				}
				else if (r == 22)
                {
				    BotSay(": You've got to be kidding me!\n");
				    localcmd("play blood2/died/SUBBCALEB1.WAV\n");
				}
				else
                {
				    BotSay(": I'm DEAD again!\n");
				    localcmd("play blood2/died/sui2_cal.wav\n");
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
					Taunt(8);					
				}
				else if (r == 2)
				{
                    BotSay(": Are you just gonna stand there and bleed?\n");
					Taunt(5);
				}
                else if (r == 3)
				{
                    BotSay(": That'll teach ya\n");
					Taunt(6);
				}
				else if (r == 4)
				{
				    BotSay(": Hmmm. Extraordinary use of color. The composition is a bit lacking\n");
					localcmd("play player/quips/1055.wav\n");
				}				
				else if (r == 5)
				{
					BotSay(": Lambs to the slaughter\n");
					localcmd("play player/quips/1027.wav\n");
				}
				else if (r == 6)
				{
                	BotSay(": Sure is dead around here\n");
                	localcmd("play blood2/suicide/E1M5_4_CAL.WAV\n");
				}
				else if (r == 7)
				{
                	BotSay(": Oh yum!  A personcicle\n");
                	localcmd("play blood2/suicide/E2M5_3_CAL.WAV\n");
				}
				else if (r == 8)
				{
                	BotSay(": Couldn't have done it better myself\n");
                	localcmd("play blood2/suicide/E2M7_3_CAL.WAV\n");
				}
				else if (r == 9)
				{
                	BotSay(": What a waste of good ammunition\n");
                	localcmd("play blood2/suicide/E3M2_1_CAL.WAV\n");
				}
				else if (r == 10)
				{
                	BotSay(": You know, it smells like somebody died in here\n");
                	localcmd("play blood2/suicide/E4M3_1_CAL.WAV\n");
				}
				else if (r == 11)
				{
                	BotSay(": Oooh - that's gotta hurt\n");
                	localcmd("play blood2/suicide/KILL15CAL.WAV\n");
				}
				else if (r == 12)
				{
                	BotSay(": That's a good way to get yourself killed\n");
                	localcmd("play blood2/suicide/KILL1_CAL.WAV\n");
				}
				else if (r == 13)
				{
                	BotSay(": Haha\n");
                	localcmd("play blood2/suicide/LAUGH2_CALA.WAV\n");
				}
				else if (r == 14)
				{
                	BotSay(": Hehe\n");
                	localcmd("play blood2/suicide/LAUGH2_CALB.WAV\n");
				}
				else
				{
                	BotSay(": Hey dummy - you got a deathwish or something?\n");
                	localcmd("play blood2/suicide/sui3_cal.wav\n");
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
