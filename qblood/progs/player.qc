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
#include "player.qh"

void() CTF_PlayerDropFlag;


/*
==============================================================================
PLAYER
==============================================================================
*/

void() player_run;

void()  player_stand1 =[    $axstnd1,   player_stand1   ]
{
    if (self.player_state != PS_HOLD_FIRE && self.player_state != PS_MENU)
        self.weaponframe = 0;

    if (self.velocity_x || self.velocity_y)
    {
        self.walkframe=0;
        player_run();
        return;
    }

    if (self.weapon == IT_PITCHFORK)
    {
        if (self.walkframe >= 12)
            self.walkframe = 0;
        self.frame = $axstnd1 + self.walkframe;
    }
    else
    {
        if (self.walkframe >= 5)
            self.walkframe = 0;
        self.frame = $stand1 + self.walkframe;
    }
    self.walkframe = self.walkframe + 1;
};

void()  player_run =[   $rockrun1,  player_run  ]
{
    if (self.player_state != PS_HOLD_FIRE && self.player_state != PS_MENU)
    {
        self.weaponframe = 0;
        self.player_state = PS_IDLE;
    }

    if (!self.velocity_x && !self.velocity_y)
    {
        self.walkframe=0;
        player_stand1();
        return;
    }

    if (self.weapon == IT_PITCHFORK)
    {
        if (self.walkframe == 6)
            self.walkframe = 0;
        self.frame = $axrun1 + self.walkframe;
    }
    else
    {
        if (self.walkframe == 6)
            self.walkframe = 0;
        self.frame = self.frame + self.walkframe;
    }
    self.walkframe = self.walkframe + 1;
};

void() muzzleflash =
{
    #ifdef QUAKEWORLD
    WriteByte (MSG_MULTICAST, SVC_MUZZLEFLASH);
    WriteEntity (MSG_MULTICAST, self);
    multicast (self.origin, MULTICAST_PVS);
    #else
    self.effects = self.effects | EF_MUZZLEFLASH;
    #endif
};


//============================================================================

void() player_rocket1   =[$rockatt1, player_rocket2  ] {self.weaponframe=1;muzzleflash();};
void() player_rocket2   =[$rockatt2, player_rocket3  ] {self.weaponframe=2;};
void() player_rocket3   =[$rockatt3, player_rocket4  ] {self.weaponframe=3;};
void() player_rocket4   =[$rockatt4, player_rocket5  ] {self.weaponframe=4;};
void() player_rocket5   =[$rockatt5, player_rocket6  ] {self.weaponframe=5;};
void() player_rocket6   =[$rockatt6, player_run      ] {self.weaponframe=6;};


float() PainSound =
{
local float     rs;

    if (self.health < 0)
        return FALSE;

    if (self.pain_finished > time)
        return FALSE;

    self.pain_finished = time + 0.5;

    if (self.deathtype == "drowning")
    {
        if (random() > 0.5)
            sound (self, CHAN_VOICE, "ambience/bubrise.wav", 1, ATTN_NORM);
        else
            sound (self, CHAN_VOICE, "foley/undchoke.wav", 1, ATTN_NORM);
        return TRUE;
    }
    if (self.deathtype == "falling")
    {
        sound (self, CHAN_VOICE, "player/pain/play1105.wav", 1, ATTN_NORM);
        return TRUE;
    }
    if (self.deathtype == "fire")
    {
        // PM -- Player is on fire so scream.
        rs = ceil(random() * 3);
        if (rs == 3)
        {
            self.noise = "player/pain/play1120.wav";
            self.pain_finished = time + 1.9;
        }
        else if (rs == 2)
        {
            self.noise = "player/pain/play1119.wav";
            self.pain_finished = time + 2;
        }
        else
        {
            self.noise = "player/pain/play1118.wav";
            self.pain_finished = time + 2.6;
        }
        sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
        return TRUE;
    }

    // Normal pain sound.
    rs = ceil(random() * 3);
    if (rs == 0)
        self.noise = "player/pain/play1106.wav";
    else if (rs == 1)
        self.noise = "player/pain/play1107.wav";
    else
        self.noise = "player/pain/play1108.wav";

    sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
    return TRUE;
};

void()  player_pain1 =  [   $pain1, player_pain2    ] {};
void()  player_pain2 =  [   $pain2, player_pain3    ] {};
void()  player_pain3 =  [   $pain3, player_pain4    ] {};
void()  player_pain4 =  [   $pain4, player_pain5    ] {};
void()  player_pain5 =  [   $pain5, player_pain6    ] {};
void()  player_pain6 =  [   $pain6, player_run  ] {};

void()  player_axpain1 =    [   $axpain1,   player_axpain2  ] {};
void()  player_axpain2 =    [   $axpain2,   player_axpain3  ] {};
void()  player_axpain3 =    [   $axpain3,   player_axpain4  ] {};
void()  player_axpain4 =    [   $axpain4,   player_axpain5  ] {};
void()  player_axpain5 =    [   $axpain5,   player_axpain6  ] {};
void()  player_axpain6 =    [   $axpain6,   player_run  ] {};

void() player_pain =
{
    if (self.weaponframe)
        return;

    if (self.invisible_finished > time)
        return;     // eyes don't have pain frames

    // Changed so player only shows pain when player make noise.
    if (PainSound ())
    {
        self.weaponframe = 0;
        if (self.weapon == IT_PITCHFORK)
            player_axpain1 ();
        else
            player_pain1 ();
    }
};

void() player_diea1;
void() player_dieb1;
void() player_diec1;
void() player_died1;
void() player_diee1;
void() player_die_ax1;


void() DeathSound =
{
local float     rs;

    // water death sounds
    if (self.waterlevel == 3)
    {
        sound (self, CHAN_VOICE, "ambience/bubrise.wav", 1, ATTN_NONE);
        return;
    }

    rs = rint ((random() * 4) + 1);
    if (rs == 1)
        self.noise = "player/die1.wav";
    else if (rs == 2)
        self.noise = "player/die2.wav";
    else if (rs == 3)
        self.noise = "player/die3.wav";
    else if (rs == 4)
        self.noise = "butcher/fzomdie2.wav";
    else
        self.noise = "butcher/fzomdie3.wav";

    sound (self, CHAN_VOICE, self.noise, 1, ATTN_NONE);
    return;
};


void() PlayerDead =
{
    self.nextthink = -1;

    // allow respawn after a certain time
    self.deadflag = DEAD_DEAD;
    if (self.player_state != PS_MENU)
        self.player_state = PS_IDLE;  // so that he can enter the menu
};

vector(float dm) VelocityForDamage =
{
    local vector v;

    if (vlen(damage_inflictor.velocity)>0)
    {
        v = 0.5 * damage_inflictor.velocity;
        v = v + (25 * normalize(self.origin-damage_inflictor.origin));
        v_z = 100 + 240 * random();
        v_x = v_x + (200 * crandom());
        v_y = v_y + (200 * crandom());
        //dprint ("Velocity gib\n");
    }
    else
    {
        v_x = 100 * crandom();
        v_y = 100 * crandom();
        v_z = 200 + 100 * random();
    }

    if (dm > -50)
    {
//      dprint ("level 1\n");
        v = v * 0.7;
    }
    else if (dm > -200)
    {
//      dprint ("level 3\n");
        v = v * 2;
    }
    else
        v = v * 10;

    return v;
};


void(string gibname, float dm) ThrowGib =
{
    local   entity new;

    new = spawn();
    new.origin = self.origin;
    setmodel (new, gibname);
    setsize (new, '0 0 0', '0 0 0');
    new.velocity = VelocityForDamage (dm);
    new.movetype = MOVETYPE_BOUNCE;
    new.solid = SOLID_NOT;
    new.avelocity_x = random()*600;
    new.avelocity_y = random()*600;
    new.avelocity_z = random()*600;
    new.think = SUB_Remove;
    new.ltime = time;
    new.nextthink = time + 10 + random()*10;
    new.frame = 0;
    new.flags = 0;
};

/*
====================
HeadDie

Function called when a head "dies"
====================
*/
void() HeadDie =
{
    sound (self, CHAN_ITEM, "misc/gibsq.wav", 1, ATTN_NORM);
    ThrowGib ("progs/m_brain.mdl", self.health);
    remove (self);
};


/*
====================
HeadTouch

Function used for throwing heads when someone touchs them
====================
*/
void() HeadTouch =
{
    // only a player can kick it
    if (other.classname != "player")
        return;

    sound(other, CHAN_ITEM, "foley/punt.wav", 1, ATTN_NORM);

    // Destroy the head, kick after kick
    if (self.takedamage != DAMAGE_NO)
    {
        self.health = self.health - 10;
        if (self.health <= 0)
        {
            self.enemy = other;
            self.th_die ();
            return;
        }
    }

    // define velocity
    // you can play with these formulas to adjust trajectory
    self.velocity_x = other.velocity_x * 3 + 50 * random();
    self.velocity_y = other.velocity_y * 3 + 50 * random();
    self.velocity_z = 300 + 160 * random() + (other.velocity_y + other.velocity_x) * 0.30;
    self.avelocity = crandom() * '0 600 0';

    self.flags = self.flags - (self.flags & FL_ONGROUND);
};


void(string gibname, float dm) ThrowHead =
{
    setmodel (self, gibname);
    self.frame = 0;
    self.skin = 0;
    self.movetype = MOVETYPE_BOUNCE;

    // A player's head is invulnerable until this player respawns
    if (self.classname != "player")
    {
        self.takedamage = DAMAGE_AIM;
        self.health = 80;

        // Get rid of it in 2 minutes anyway (to avoid too many entities)
        self.nextthink = time + 120;
        self.think = SUB_Remove;
    }
    else
    {
        self.takedamage = DAMAGE_NO;
        self.nextthink = -1;
    }

    // Clean all
    // if a monsters death sets off a trigger then dont let the corpses death do the same
    self.use = SUB_Null;
    self.target = string_null;
    self.killtarget = string_null;
    self.targetname = string_null;
    self.th_pain = SUB_Null;
    self.flags = self.flags - (self.flags & (FL_MONSTER | FL_ONGROUND));

    self.th_die = HeadDie;
    self.touch = HeadTouch;

    self.classname = "head";
    self.solid = SOLID_BBOX;
    self.view_ofs = '0 0 8';
    setsize (self, '-16 -16 0', '16 16 56');
    self.velocity = VelocityForDamage (dm);
    self.origin_z = self.origin_z - 24;
    self.avelocity = crandom() * '0 600 0';
};


//  This produces a variety of semi-random gibs.  This should only be
//  used by gibbed players and humanoid monsters (e.g., zombies, cultists)
void() RandomHumanGibs =
{
//
// In Blood, you get 2 hands, ribcage, some meat, guts, eyeball, and a skull
//
// gib models...
//
// gib1 = bone (arm/leg) with flesh
// gib2 = rib cage
// gib3 = heart
// m_arm = upper arm
// m_brain = brain
// m_chest = torso
// m_farm = forearm with fist
// m_fist = hand/fist
// m_foot = looks like a bloody shoe?
// m_guts = intestines
// m_leg = femur with meat
//

    local   float   gibs, r;

    // Throw 4-5 gibs
    gibs = random() * 2;
    gibs = 4 + floor(gibs);

    // throw torso
    ThrowGib ("progs/m_chest.mdl", self.health);
    gibs = gibs - 1;

    // throw hands (either or both)
    r = random();
    if (r < 0.4)
    {
        ThrowGib ("progs/m_farm.mdl", self.health);
        gibs = gibs - 1;
    }
    else if (r < 0.8)
    {
        ThrowGib ("progs/m_fist.mdl", self.health);
        gibs = gibs - 1;
    }
    else
    {
        ThrowGib ("progs/m_farm.mdl", self.health);
        ThrowGib ("progs/m_fist.mdl", self.health);
        gibs = gibs - 2;
    }

    // throw misc. organs (either or both)
    r = random();
    if (r < 0.4)
    {
        ThrowGib ("progs/gib3.mdl", self.health);
        gibs = gibs - 1;
    }
    else if (r < 0.8)
    {
        ThrowGib ("progs/m_guts.mdl", self.health);
        gibs = gibs - 1;
    }
    else
    {
        ThrowGib ("progs/gib3.mdl", self.health);
        ThrowGib ("progs/m_guts.mdl", self.health);
        gibs = gibs - 2;
    }

    // throw arm/leg limbs until we run out of gibs
    while (gibs > 0)
    {
        r = random() * 3;
        r = ceil (r);

        if (r == 1)
            ThrowGib ("progs/m_arm.mdl", self.health);
        else if (r == 2)
            ThrowGib ("progs/m_foot.mdl", self.health);
        else //if (r == 3)
            ThrowGib ("progs/m_leg.mdl", self.health);

        gibs = gibs - 1;
    }
};


void() GibPlayer =
{
    ThrowHead ("progs/h_player.mdl", self.health);
    RandomHumanGibs ();

    self.deadflag = DEAD_DEAD;

    if (damage_attacker.classname == "teledeath"  ||
        damage_attacker.classname == "teledeath2" ||
        damage_attacker.classname == "teledeath3" )
    {
        sound (self, CHAN_VOICE, "firepod/fpodcol2.wav", 1, ATTN_NONE);
        return;
    }

    if (random() < 0.5)
        sound (self, CHAN_VOICE, "butcher/fzomdie2.wav", 1, ATTN_NONE);
    else
        sound (self, CHAN_VOICE, "butcher/fzomdie3.wav", 1, ATTN_NONE);
};

void() PlayerDie =
{
    local   float   i;
    local   string  s;

    // I may not die alone...
    W_ActivateRemoteBombs ();

    self.items = self.items - (self.items & IT_INVISIBILITY);

    if (self.akimbo_finished > 0)
    {
        DropQuad (self.akimbo_finished - time);
        Bprint (PRINT_LOW, self.netname);
        Bprint (PRINT_LOW, " lost a Guns Akimbo with ");
        s = ftos(rint(self.akimbo_finished - time));
        Bprint (PRINT_LOW, s);
        Bprint (PRINT_LOW, " seconds remaining\n");
    }

    if (self.invisible_finished > 0)
    {
        Bprint (PRINT_LOW, self.netname);
        Bprint (PRINT_LOW, " lost a cloak with ");
        s = ftos(rint(self.invisible_finished - time));
        Bprint (PRINT_LOW, s);
        Bprint (PRINT_LOW, " seconds remaining\n");
        DropRing (self.invisible_finished - time);
    }

    CTF_PlayerDropFlag ();

    self.invisible_finished = 0;    // don't die as eyes
    self.invincible_finished = 0;
    self.akimbo_finished = 0;
    self.radsuit_finished = 0;
    self.modelindex = modelindex_player;    // don't use eyes

    self.weaponmodel="";
    self.view_ofs = '0 0 -8';
    self.deadflag = DEAD_DYING;
    self.solid = SOLID_NOT;
    self.flags = self.flags - (self.flags & FL_ONGROUND);
    self.movetype = MOVETYPE_TOSS;
    if (self.velocity_z < 10)
        self.velocity_z = self.velocity_z + random()*300;

    if (self.health < -40)
    {
        GibPlayer ();
        return;
    }

    DeathSound();

    self.angles_x = 0;
    self.angles_z = 0;

    if (self.weapon == IT_PITCHFORK)
    {
        player_die_ax1 ();
        return;
    }

    i = 1 + floor(random()*6);
    if (i == 1)
        player_diea1();
    else if (i == 2)
        player_dieb1();
    else if (i == 3)
        player_diec1();
    else if (i == 4)
        player_died1();
    else
        player_diee1();

};

void() set_suicide_frame =
{   // used by kill command and disconnect command
    if (self.model != "progs/player.mdl")
        return; // allready gibbed
    self.frame = $deatha11;
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_TOSS;
    self.deadflag = DEAD_DEAD;
    self.nextthink = -1;
};


void()  player_diea1    =   [   $deatha1,   player_diea2    ] {};
void()  player_diea2    =   [   $deatha2,   player_diea3    ] {};
void()  player_diea3    =   [   $deatha3,   player_diea4    ] {};
void()  player_diea4    =   [   $deatha4,   player_diea5    ] {};
void()  player_diea5    =   [   $deatha5,   player_diea6    ] {};
void()  player_diea6    =   [   $deatha6,   player_diea7    ] {};
void()  player_diea7    =   [   $deatha7,   player_diea8    ] {};
void()  player_diea8    =   [   $deatha8,   player_diea9    ] {};
void()  player_diea9    =   [   $deatha9,   player_diea10   ] {};
void()  player_diea10   =   [   $deatha10,  player_diea11   ] {};
void()  player_diea11   =   [   $deatha11,  player_diea11 ] {PlayerDead();};

void()  player_dieb1    =   [   $deathb1,   player_dieb2    ] {};
void()  player_dieb2    =   [   $deathb2,   player_dieb3    ] {};
void()  player_dieb3    =   [   $deathb3,   player_dieb4    ] {};
void()  player_dieb4    =   [   $deathb4,   player_dieb5    ] {};
void()  player_dieb5    =   [   $deathb5,   player_dieb6    ] {};
void()  player_dieb6    =   [   $deathb6,   player_dieb7    ] {};
void()  player_dieb7    =   [   $deathb7,   player_dieb8    ] {};
void()  player_dieb8    =   [   $deathb8,   player_dieb9    ] {};
void()  player_dieb9    =   [   $deathb9,   player_dieb9    ] {PlayerDead();};

void()  player_diec1    =   [   $deathc1,   player_diec2    ] {};
void()  player_diec2    =   [   $deathc2,   player_diec3    ] {};
void()  player_diec3    =   [   $deathc3,   player_diec4    ] {};
void()  player_diec4    =   [   $deathc4,   player_diec5    ] {};
void()  player_diec5    =   [   $deathc5,   player_diec6    ] {};
void()  player_diec6    =   [   $deathc6,   player_diec7    ] {};
void()  player_diec7    =   [   $deathc7,   player_diec8    ] {};
void()  player_diec8    =   [   $deathc8,   player_diec9    ] {};
void()  player_diec9    =   [   $deathc9,   player_diec10   ] {};
void()  player_diec10   =   [   $deathc10,  player_diec11   ] {};
void()  player_diec11   =   [   $deathc11,  player_diec12   ] {};
void()  player_diec12   =   [   $deathc12,  player_diec13   ] {};
void()  player_diec13   =   [   $deathc13,  player_diec14   ] {};
void()  player_diec14   =   [   $deathc14,  player_diec15   ] {};
void()  player_diec15   =   [   $deathc15,  player_diec15 ] {PlayerDead();};

void()  player_died1    =   [   $deathd1,   player_died2    ] {};
void()  player_died2    =   [   $deathd2,   player_died3    ] {};
void()  player_died3    =   [   $deathd3,   player_died4    ] {};
void()  player_died4    =   [   $deathd4,   player_died5    ] {};
void()  player_died5    =   [   $deathd5,   player_died6    ] {};
void()  player_died6    =   [   $deathd6,   player_died7    ] {};
void()  player_died7    =   [   $deathd7,   player_died8    ] {};
void()  player_died8    =   [   $deathd8,   player_died9    ] {};
void()  player_died9    =   [   $deathd9,   player_died9    ] {PlayerDead();};

void()  player_diee1    =   [   $deathe1,   player_diee2    ] {};
void()  player_diee2    =   [   $deathe2,   player_diee3    ] {};
void()  player_diee3    =   [   $deathe3,   player_diee4    ] {};
void()  player_diee4    =   [   $deathe4,   player_diee5    ] {};
void()  player_diee5    =   [   $deathe5,   player_diee6    ] {};
void()  player_diee6    =   [   $deathe6,   player_diee7    ] {};
void()  player_diee7    =   [   $deathe7,   player_diee8    ] {};
void()  player_diee8    =   [   $deathe8,   player_diee9    ] {};
void()  player_diee9    =   [   $deathe9,   player_diee9    ] {PlayerDead();};

void()  player_die_ax1  =   [   $axdeth1,   player_die_ax2  ] {};
void()  player_die_ax2  =   [   $axdeth2,   player_die_ax3  ] {};
void()  player_die_ax3  =   [   $axdeth3,   player_die_ax4  ] {};
void()  player_die_ax4  =   [   $axdeth4,   player_die_ax5  ] {};
void()  player_die_ax5  =   [   $axdeth5,   player_die_ax6  ] {};
void()  player_die_ax6  =   [   $axdeth6,   player_die_ax7  ] {};
void()  player_die_ax7  =   [   $axdeth7,   player_die_ax8  ] {};
void()  player_die_ax8  =   [   $axdeth8,   player_die_ax9  ] {};
void()  player_die_ax9  =   [   $axdeth9,   player_die_ax9  ] {PlayerDead();};
