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

#include "common.qh"
#include "player.qh"


void() Bomb_Fire;
void() Bomb_Uncharge;
void() ShowThrowMeter;


//============================================================================

// ----- TNT model ----- //

$modelname v_rock

// idle (animation; 3 frames)
$frame tnt_idle1 /* tnt_idle2 tnt_idle3 */

// fire
// the last 3 frames must be looped while holding the lighted TNT
$frame tnt_fire1 tnt_fire2 tnt_fire3 tnt_fire4 tnt_fire5
$frame tnt_fire6 tnt_fire7 tnt_fire8 tnt_fire9

// throw
// at tnt_throw6, it's a new TNT that we have in hands
$frame tnt_throw1  tnt_throw2 tnt_throw3 tnt_throw4 tnt_throw5
$frame tnt_throw6  tnt_throw7 tnt_throw8

// draw
$frame tnt_draw1 tnt_draw2 tnt_draw3 tnt_draw4 tnt_draw5
$frame tnt_draw6 tnt_draw7 tnt_draw8

// draw half
$frame tnt_drawhalf1 tnt_drawhalf2 tnt_drawhalf3 tnt_drawhalf4

// holster
$frame tnt_holster1 tnt_holster2 tnt_holster3 tnt_holster4

// holster half
$frame tnt_holsterhlf1 tnt_holsterhlf2 tnt_holsterhlf3 tnt_holsterhlf4


// ----- Proximity Bomb model ----- //

$modelname v_proxy

// idle
$frame proxy_idle1

// throw
$frame proxy_throw1  proxy_throw2 proxy_throw3 proxy_throw4 proxy_throw5
$frame proxy_throw6  proxy_throw7

// draw
$frame proxy_draw1 proxy_draw2 proxy_draw3 proxy_draw4

// holster
$frame proxy_holster1 proxy_holster2 proxy_holster3 proxy_holster4


// ----- Remote Detonator model ----- //

$modelname v_remote

// idle
$frame remote_idle1

// throw
$frame remote_throw1  remote_throw2 remote_throw3 remote_throw4 remote_throw5
$frame remote_throw6  remote_throw7

// fire
$frame remote_fire1 remote_fire2 remote_fire3

// draw
$frame remote_draw1 remote_draw2 remote_draw3 remote_draw4

// holster
$frame remote_holster1 remote_holster2 remote_holster3 remote_holster4


// ----- Player related code ----- //

// Throw a TNT
void() player_throwtnt1 = [$attack2, player_throwtnt2] { self.weaponframe = $tnt_throw1; };
void() player_throwtnt2 = [$attack2, player_throwtnt3] { self.weaponframe = $tnt_throw2; };
void() player_throwtnt3 = [$attack2, player_throwtnt4] { self.weaponframe = $tnt_throw3; };
void() player_throwtnt4 = [$attack2, player_throwtnt5] { self.weaponframe = $tnt_throw4; };
void() player_throwtnt5 = [$attack2, player_throwtnt6] { self.weaponframe = $tnt_throw5; };
void() player_throwtnt6 = [$attack1, player_throwtnt7]
{
    self.weaponframe = $tnt_throw6;
    Bomb_Fire ();
    Bomb_Uncharge ();
    ShowThrowMeter ();
    self.player_state = PS_IDLE;
};
void() player_throwtnt7 = [$attack1, player_throwtnt8] { self.weaponframe = $tnt_throw7; };
void() player_throwtnt8 = [$attack2, player_run      ] { self.weaponframe = $tnt_throw8; };

// Throw a proximity bomb
void() player_throwproxy1 = [$attack2, player_throwproxy2] { self.weaponframe = $proxy_throw1; };
void() player_throwproxy2 = [$attack2, player_throwproxy3] { self.weaponframe = $proxy_throw2; };
void() player_throwproxy3 = [$attack2, player_throwproxy4] { self.weaponframe = $proxy_throw3; };
void() player_throwproxy4 = [$attack2, player_throwproxy5] { self.weaponframe = $proxy_throw4; };
void() player_throwproxy5 = [$attack2, player_throwproxy6] { self.weaponframe = $proxy_throw5; };
void() player_throwproxy6 = [$attack1, player_throwproxy7]
{
    self.weaponframe = $proxy_throw6;
    Bomb_Fire ();
    Bomb_Uncharge ();
    ShowThrowMeter ();
    self.player_state = PS_IDLE;
};
void() player_throwproxy7 = [$attack1, player_run] { self.weaponframe = $proxy_throw7; };

// Throw a remote detonator
void() player_throwremote1 = [$attack2, player_throwremote2] { self.weaponframe = $remote_throw1; };
void() player_throwremote2 = [$attack2, player_throwremote3] { self.weaponframe = $remote_throw2; };
void() player_throwremote3 = [$attack2, player_throwremote4] { self.weaponframe = $remote_throw3; };
void() player_throwremote4 = [$attack2, player_throwremote5] { self.weaponframe = $remote_throw4; };
void() player_throwremote5 = [$attack2, player_throwremote6] { self.weaponframe = $remote_throw5; };
void() player_throwremote6 = [$attack1, player_throwremote7]
{
    self.weaponframe = $remote_throw6;
    Bomb_Fire ();
    Bomb_Uncharge ();
    ShowThrowMeter ();
};
void() player_throwremote7 = [$attack1, player_throwremote8] { self.weaponframe = $remote_throw7; };
void() player_throwremote8 = [$attack2, player_run         ]
{
    // We switch to the 1st remote frame
    self.weaponframe = $remote_fire1;

    self.player_state = PS_HOLD_FIRE;
};

// TNT half draw
void() player_tnthalfdraw1 = [$attack2, player_tnthalfdraw2] { self.weaponframe = $tnt_drawhalf1; };
void() player_tnthalfdraw2 = [$attack2, player_tnthalfdraw3] { self.weaponframe = $tnt_drawhalf2; };
void() player_tnthalfdraw3 = [$attack2, player_tnthalfdraw4] { self.weaponframe = $tnt_drawhalf3; };
void() player_tnthalfdraw4 = [$attack2, player_run         ] { self.weaponframe = $tnt_drawhalf4; };

// TNT normal draw
void() player_tntdraw1 = [$attack2, player_tntdraw2] { self.weaponframe = $tnt_draw1; };
void() player_tntdraw2 = [$attack2, player_tntdraw3] { self.weaponframe = $tnt_draw2; };
void() player_tntdraw3 = [$attack2, player_tntdraw4] { self.weaponframe = $tnt_draw3; };
void() player_tntdraw4 = [$attack2, player_tntdraw5] { self.weaponframe = $tnt_draw4; };
void() player_tntdraw5 = [$attack2, player_tntdraw6] { self.weaponframe = $tnt_draw5; };
void() player_tntdraw6 = [$attack2, player_tntdraw7] { self.weaponframe = $tnt_draw6; };
void() player_tntdraw7 = [$attack2, player_tntdraw8] { self.weaponframe = $tnt_draw7; };
void() player_tntdraw8 = [$attack2, player_run     ] { self.weaponframe = $tnt_draw8; };

// TNT half holster
void() player_tnthalfholster1 = [$attack2, player_tnthalfholster2] { self.weaponframe = $tnt_holsterhlf1; };
void() player_tnthalfholster2 = [$attack2, player_tnthalfholster3] { self.weaponframe = $tnt_holsterhlf2; };
void() player_tnthalfholster3 = [$attack2, player_tnthalfholster4] { self.weaponframe = $tnt_holsterhlf3; };
void() player_tnthalfholster4 = [$attack2, player_tnthalfholster5] { self.weaponframe = $tnt_holsterhlf4; };
void() player_tnthalfholster5 = [$attack2, player_run            ] { W_DrawWeapon (self.newweapon); };

// TNT normal holster
void() player_tntholster1 = [$attack2, player_tntholster2] { self.weaponframe = $tnt_holster1; };
void() player_tntholster2 = [$attack2, player_tntholster3] { self.weaponframe = $tnt_holster2; };
void() player_tntholster3 = [$attack2, player_tntholster4] { self.weaponframe = $tnt_holster3; };
void() player_tntholster4 = [$attack2, player_tntholster5] { self.weaponframe = $tnt_holster4; };
void() player_tntholster5 = [$attack2, player_run        ] { W_DrawWeapon (self.newweapon); };

// Proximity bomb draw
void() player_proxydraw1 = [$attack2, player_proxydraw2] { self.weaponframe = $proxy_draw1; };
void() player_proxydraw2 = [$attack2, player_proxydraw3] { self.weaponframe = $proxy_draw2; };
void() player_proxydraw3 = [$attack2, player_proxydraw4] { self.weaponframe = $proxy_draw3; };
void() player_proxydraw4 = [$attack2, player_run       ] { self.weaponframe = $proxy_draw4; };

// Proximity bomb holster
void() player_proxyholster1 = [$attack2, player_proxyholster2] { self.weaponframe = $proxy_holster1; };
void() player_proxyholster2 = [$attack2, player_proxyholster3] { self.weaponframe = $proxy_holster2; };
void() player_proxyholster3 = [$attack2, player_proxyholster4] { self.weaponframe = $proxy_holster3; };
void() player_proxyholster4 = [$attack2, player_proxyholster5] { self.weaponframe = $proxy_holster4; };
void() player_proxyholster5 = [$attack2, player_run          ] { W_DrawWeapon (self.newweapon); };

// Remote detonator draw
void() player_remotedraw1 = [$attack2, player_remotedraw2] { self.weaponframe = $remote_draw1; };
void() player_remotedraw2 = [$attack2, player_remotedraw3] { self.weaponframe = $remote_draw2; };
void() player_remotedraw3 = [$attack2, player_remotedraw4] { self.weaponframe = $remote_draw3; };
void() player_remotedraw4 = [$attack2, player_run        ] { self.weaponframe = $remote_draw4; };

// Remote detonator holster
void() player_remoteholster1 = [$attack2, player_remoteholster2] { self.weaponframe = $remote_holster1; };
void() player_remoteholster2 = [$attack2, player_remoteholster3] { self.weaponframe = $remote_holster2; };
void() player_remoteholster3 = [$attack2, player_remoteholster4] { self.weaponframe = $remote_holster3; };
void() player_remoteholster4 = [$attack2, player_remoteholster5] { self.weaponframe = $remote_holster4; };
void() player_remoteholster5 = [$attack2, player_run           ] { W_DrawWeapon (self.newweapon); };

// Light a TNT
void() player_lighttnt1 = [$attack2, player_lighttnt2] { self.weaponframe = $tnt_fire1; };
void() player_lighttnt2 = [$attack2, player_lighttnt3] { self.weaponframe = $tnt_fire2; };
void() player_lighttnt3 = [$attack2, player_lighttnt4] { self.weaponframe = $tnt_fire3; };
void() player_lighttnt4 = [$attack2, player_lighttnt5] { self.weaponframe = $tnt_fire4; };
void() player_lighttnt5 = [$attack2, player_lighttnt6] { self.weaponframe = $tnt_fire5; };
void() player_lighttnt6 = [$attack2, player_lighttnt7] { self.weaponframe = $tnt_fire6; };
void() player_lighttnt7 = [$attack2, player_lighttnt8] { self.weaponframe = $tnt_fire7; };
void() player_lighttnt8 = [$attack2, player_lighttnt9] { self.weaponframe = $tnt_fire8; };
void() player_lighttnt9 = [$attack2, player_lighttnt7] { self.weaponframe = $tnt_fire9; };

// Trigger the remote bombs
void() player_remotefire1 = [$attack2, player_remotefire2] { self.weaponframe = $remote_fire2; };
void() player_remotefire2 = [$attack2, player_remotefire3] { self.weaponframe = $remote_fire3; };
void() player_remotefire3 = [$attack2, player_run        ]
{
    self.weaponframe = 0;
    self.player_state = PS_IDLE;

    // If we have no more remote bombs, we "lose" this weapon
    if (self.currentammo == 0)
    {
        local float newWeapon;

        self.items = self.items - self.weapon;
        newWeapon = W_BestWeapon();
        W_DrawWeapon (newWeapon);
    }
    else
        Remote_UpdateView ();
};


//============================================================================

#define DMG_TNT              120
#define DMG_PROXIMITY_BOMB   150
#define DMG_REMOTE_DETONATOR 120
#define DMG_SPRAY_CAN        20

// The 2 types of TNT
#define TNT_TYPE_NORMAL  0
#define TNT_TYPE_ALTFIRE 1


void() ShowThrowMeter =
{
    local   string  text;

    if (self.charge == 20)
        text = "žžžžžžžžžžžžžžžžžžžž";
    else if (self.charge == 19)
        text = "žžžžžžžžžžžžžžžžžžž ";
    else if (self.charge == 18)
        text = "žžžžžžžžžžžžžžžžžž  ";
    else if (self.charge == 17)
        text = "žžžžžžžžžžžžžžžžž   ";
    else if (self.charge == 16)
        text = "žžžžžžžžžžžžžžžž    ";
    else if (self.charge == 15)
        text = "žžžžžžžžžžžžžžž     ";
    else if (self.charge == 14)
        text = "žžžžžžžžžžžžžž      ";
    else if (self.charge == 13)
        text = "žžžžžžžžžžžžž       ";
    else if (self.charge == 12)
        text = "žžžžžžžžžžžž        ";
    else if (self.charge == 11)
        text = "žžžžžžžžžžž         ";
    else if (self.charge == 10)
        text = "žžžžžžžžžž          ";
    else if (self.charge == 9)
        text = "žžžžžžžžž           ";
    else if (self.charge == 8)
        text = "žžžžžžžž            ";
    else if (self.charge == 7)
        text = "žžžžžžž             ";
    else if (self.charge == 6)
        text = "žžžžžž              ";
    else if (self.charge == 5)
        text = "žžžžž               ";
    else if (self.charge == 4)
        text = "žžžž                ";
    else if (self.charge == 3)
        text = "žžž                 ";
    else if (self.charge == 2)
        text = "žž                  ";
    else if (self.charge == 1)
        text = "ž                   ";
    else
        text = "";

    centerprint (self, text);
};

void() Bomb_Uncharge =
{
    // Stop the fuse sound if any
    sound (self, CHAN_WEAPON, "misc/null.wav", 0, ATTN_NORM);

    self.charge     = 0;
    self.powertime  = 0;
    self.tnt_time   = 0;
};

#define FUSE_TIME   5.5

// This charges up and displays the throw meter
void() BuildThrowMeter =
{
    ResetIdle (self);  // Don't let Caleb rave

    self.player_state = PS_CHARGE;

    if (self.charge >= 20)
    {
        // Maxed out
        self.powertime = 0;
    }
    else if (self.powertime <= time)
    {
        self.powertime = time + 0.1;
        self.charge = self.charge + 1;
    }
    ShowThrowMeter ();
};


// This controls charging and firing of normal dynamite and spray can
void() player_lightcan1;
void() W_ChargeNormal =
{
    local   float   altfire;

    if ((self.impulse == 12) || self.button3)
    {
        altfire = TRUE;
        self.impulse = 0;
    }
    else
        altfire = FALSE;

    // Check if player is holding lit dynamite or spray can
    if (self.tnt_time)
    {
        // If the fuse is burned up, the TNT explodes in our hands...
        if (self.tnt_time && self.tnt_time <= time)
        {
            Sprint (self, PRINT_LOW, "Timed out . . .\n");

            // Indeed, we use a little trick: we drop the dynamite with a zero match time
            self.charge = 0;    // Make sure it's dropped, not thrown
            W_Attack ();
            return;
        }

        // Check for throwing
        // NOTE:  In Blood, normal-fire has priority over alt-fire
        if (self.button0)
        {
            BuildThrowMeter ();
        }
        else if (self.charge)
        {
            W_Attack ();
            return;
        }
        if (altfire)
        {
            if (self.weapon == IT_SPRAY_CAN)
                self.tnt_type = TNT_TYPE_ALTFIRE;

            self.charge = 0;    // Make sure it's dropped, not thrown
            W_Attack ();
            return;
        }

        // Play the fuse sound if needed
        if (self.t_width <= time)
        {
            // Fuse sound not playing, so play it again
            if (self.weapon == IT_SPRAY_CAN)
            {
                sound (self, CHAN_WEAPON, "weapons/spraycan/spraycan.wav", 0.5, ATTN_NORM);
                self.t_width = time + 2.6;
            }
            else
            {
                sound (self, CHAN_WEAPON, "weapons/tnt/tntfuse.wav", 0.5, ATTN_NORM);
                self.t_width = time + 3.2;
            }
        }

        return;
    }

    // Dynamite is not lit, so check for ignition.  If either button is
    // held, start the fuse
    if ((self.button0 && self.weapon == IT_TNT) || altfire)
    {
        if (self.button0)
        {
            BuildThrowMeter ();
            self.tnt_type = TNT_TYPE_NORMAL;
            player_lighttnt1 ();
        }
        else // if (altfire)
        {
            self.player_state = PS_HOLD_FIRE;

            if (self.weapon == IT_TNT)
            {
                self.tnt_type = TNT_TYPE_ALTFIRE;
                self.attack_finished = time + 0.7;
                player_lighttnt1 ();
            }
            else  // if (self.weapon == IT_SPRAY_CAN)
            {
                self.tnt_type = TNT_TYPE_NORMAL;
                self.attack_finished = time + 0.6;  // let the animation play
                player_lightcan1 ();
            }
        }

        self.tnt_time = time + FUSE_TIME;
        self.t_width = 0;  // So the fuse wav starts at the next frame
    }
};

// This controls charging and firing of the dynamite variants
void() W_ChargeBomb =
{
    local   float   altfire;

    if ((self.impulse == 12) || self.button3)
    {
        altfire = TRUE;
        self.impulse = 0;
    }
    else
        altfire = FALSE;

    if (self.button0)
    {
        BuildThrowMeter ();
    }
    else if (self.charge)
    {
        W_Attack ();
        return;
    }

    // Altfire -> drop the bomb at the current position
    if (altfire)
    {
        Sprint (self, PRINT_LOW, "Bomb dropped\n");
        self.charge = 0;    // Make sure it's dropped, not thrown
        W_Attack ();
    }
};


void() GrenadeExplode =
{
    #ifdef QUAKEWORLD
    if (self.voided) {
        return;
    }
    self.voided = 1;
    #endif

    // Stop the fuse sound if any
    sound (self, CHAN_BODY, "misc/null.wav", 0, ATTN_NORM);

    // Don't let the remote find and detonate grenades that are already
    // exploding
    self.classname = "exploded";

    // Don't let grenade explode twice.
    self.takedamage = DAMAGE_NO;

    if (self.netname == "Napalm Ball")
    {
        ThrowEmbers (2);
        local   float   radius, damage, burn;
        radius = self.dmg + 40;
        damage = self.dmg / 6;
        burn   = self.dmg / 12;
        MakeBlastDamage (self, radius, damage, burn);
    }
    else if (self.netname == "Lit Spray Can")
        MakeBlastDamage (self, 250, 20, 15);

    PsychoCaleb (self.owner);

    T_RadiusDamage (self, self.owner, self.dmg, world, "grenade");

    #ifdef QUAKEWORLD
    WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
    WriteByte (MSG_MULTICAST, TE_EXPLOSION);
    WriteCoord (MSG_MULTICAST, self.origin_x);
    WriteCoord (MSG_MULTICAST, self.origin_y);
    WriteCoord (MSG_MULTICAST, self.origin_z);
    multicast (self.origin, MULTICAST_PHS);
    remove (self);

    #else
    WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
    WriteByte (MSG_BROADCAST, TE_EXPLOSION);
    WriteCoord (MSG_BROADCAST, self.origin_x);
    WriteCoord (MSG_BROADCAST, self.origin_y);
    WriteCoord (MSG_BROADCAST, self.origin_z);
    BecomeExplosion ();
    #endif
};


/*
================
W_ActivateRemoteBombs

Make all remote bombs owned by "self" explode
================
*/
void() W_ActivateRemoteBombs =
{
    local entity grenadeEnt;
    local entity tempEnt;

    grenadeEnt = find (world, classname, "grenade");
    while (grenadeEnt)
    {
        if (grenadeEnt.owner == self)
            if (grenadeEnt.netname == "Remote Detonator")
            {
                sound (grenadeEnt, CHAN_BODY, "weapons/tnt/remdet.wav", 1, ATTN_NORM);
                tempEnt = self;
                self = grenadeEnt;
                GrenadeExplode ();
                self = tempEnt;
            }
        grenadeEnt = find (grenadeEnt, classname, "grenade");
    }

    self.attack_finished = time + 0.6;
};


// This fires the remote if the player is hold it
float() W_CheckRemote =
{
    // Check if holding the remote
    if (self.weapon == IT_REMOTE_DETONATOR && self.player_state == PS_HOLD_FIRE &&
        (self.button0 || self.button3 || self.impulse == 12))
    {
        // If we trigger the bombs
        if (self.button0)
        {
            self.attack_finished = time + 0.2;
            player_remotefire1 ();
            sound (self, CHAN_WEAPON, "weapons/tnt/remfire.wav", 1, ATTN_NORM);
            W_ActivateRemoteBombs ();
        }
        // Else (altfire: if we take another bomb in our hands)
        else
        {
            if (self.currentammo != 0)
            {
                Remote_UpdateView ();
                self.attack_finished = time + 0.4;
                self.player_state = PS_IDLE;
            }
            else
                Sprint (self, PRINT_LOW, "You have no more remote bombs\n");
        }

        self.impulse = 0;
        return TRUE;
    }

    return FALSE;
};

// The checks if the player is using a charge weapon
float() W_FireCharge =
{
    // Check if we are using dynamite
    if (self.weapon == IT_TNT || (self.weapon == IT_SPRAY_CAN && self.ammo_spray >= 1))
    {
        W_ChargeNormal ();

        // If the spray can isn't lit
        if (self.weapon == IT_SPRAY_CAN && !self.tnt_time)
            return FALSE;

        return TRUE;
    }
    if (self.weapon == IT_PROXIMITY_BOMB)
    {
        W_ChargeBomb ();
        return TRUE;
    }
    if (self.weapon == IT_REMOTE_DETONATOR)
    {
        if (W_CheckRemote ())
            return TRUE;
        if (self.ammo_tnt_remote >= 1)
        {
            W_ChargeBomb ();
            return TRUE;
        }
    }

    // Player can rapid-fire the weapon
    //W_Uncharge ();
    return FALSE;
};


// This makes bomb take damage if in slime/lava.  Assumes 'self' == bomb
void() BombContents =
{
    // Dynamite will take damage then explode if in slime or lava.
    local float pc;

    pc = pointcontents (self.origin);
    if (pc == CONTENT_SLIME)
        T_Damage (self, world, world, 4, DF_BODY, "acid");
    else if (pc == CONTENT_LAVA)
        T_Damage (self, world, world, 10, DF_FIRE, "fire");
};

void() BombThink =
{
    self.nextthink  = time + 0.1;
    BombContents ();
};


/*
================
ProximBombCheck

The proximity bomb checks its neighborhood and explodes if a living being is nearby
================
*/
void() ProximBombCheck =
{
    local entity thing;

    // Try to find something interesting nearby
    // Note: in T_RadiusDamage, an explosion can damage someone up to a distance of its damage + 40
    thing = findradius (self.origin, self.dmg + 20);
    while (thing)
    {
        // If it's a player or a monster, explode in 400 msec
        if (thing.classname == "player")
        {
            sound (self, CHAN_WEAPON, "weapons/tnt/proxdet.wav", 1, ATTN_NORM);
            self.pausetime = time + 0.4;
            self.think1 = SUB_Null;
            return;
        }

        // Next one
        thing = thing.chain;
    }

    // Retry in a moment
    self.pausetime = time + 0.25;
};


/*
================
ProximBombArmed

The proximity bomb becomes armed, ready to explode as soon as someone is nearby
================
*/
void() ProximBombArmed =
{
    sound (self, CHAN_WEAPON, "weapons/tnt/proxarm.wav", 1, ATTN_NORM);

    self.pausetime = time;
    self.think1 = ProximBombCheck;
};


/*
================
ProximBombThink

The proximity bomb does a generic think, then is checked against the world
================
*/
void() ProximBombThink =
{
    if (self.pausetime <= time)
    {
        if (self.think1 == SUB_Null)
        {
            GrenadeExplode ();
            return;
        }
        self.think1 ();
    }

    // Do the standard bomb thinking
    BombThink ();
};


/*
================
GrenadeTouch

"Touch" function for grenades
================
*/
void() GrenadeTouch =
{
    if (self.velocity == '0 0 0')
        self.avelocity = '0 0 0';
};


// Dynamite stuff.
void() DynaTouch =
{
    // Normal grenades are the only ones which can explode on touch
    if (self.style == TNT_TYPE_NORMAL)
    {
        // Don't explode on owner
        if (other != self.owner)
        {
            // Rebound if it hits the ceiling.  Otherwise, explode.
            traceline (self.origin - self.dest*4, self.origin + self.dest*16, TRUE, self);
            if (trace_fraction == 1 || trace_plane_normal_z >= 0)
            {
                GrenadeExplode ();
                return;
            }
        }
    }

    if (self.velocity == '0 0 0')
        self.avelocity = '0 0 0';
};


void() DynaThink =
{
    if (self.pausetime <= time)
    {
        GrenadeExplode ();
        return;
    }

    if (self.t_width <= time)
    {
        self.t_width    = time + 3;
        sound (self, CHAN_BODY, "weapons/tnt/tntfuse.wav", 0.5, ATTN_NORM);
    }
    self.dest = normalize (self.velocity);

    BombThink ();
};


/*
====================
proximity_mine

Spawn function for proximity mines (BB6 map)
====================
*/
void() proximity_mine =
{
    precache_sound ("weapons/tnt/proxdet.wav");  // proximity bomb triggered

    self.owner      = world;
    #ifdef QUAKEWORLD
    self.voided     = 0;
    #endif
    self.solid      = SOLID_BBOX;
    self.takedamage = DAMAGE_AIM;
    self.health     = 1;
    self.th_die     = GrenadeExplode;
    self.nextthink  = 0.1;
    self.pausetime  = time;
    self.think1     = ProximBombCheck;
    self.think      = ProximBombThink;
    self.dmg        = DMG_PROXIMITY_BOMB;
    setsize (self, '-1 -1 -1', '1 1 1');
};


/*
================
Bomb_Fire

Fire a bomb
================
*/
void() Bomb_Fire =
{
    if (self.weapon == IT_PROXIMITY_BOMB)
        self.currentammo = self.ammo_tnt_proxy = self.ammo_tnt_proxy - 1;
    else if (self.weapon == IT_REMOTE_DETONATOR)
        self.currentammo = self.ammo_tnt_remote = self.ammo_tnt_remote - 1;
    else if (self.weapon == IT_TNT)
        self.currentammo = self.ammo_tnt_bundle = self.ammo_tnt_bundle - 1;
    else  // if (self.weapon == IT_SPRAY_CAN)
    {
        // If we have at least one full spray can, we use it
        if (self.currentammo >= 48)
            self.ammo_spray = self.ammo_spray - 48;
        // Else, we burn our last one
        else
            self.ammo_spray = 0;

        self.currentammo = self.ammo_spray;
    }

    sound (self, CHAN_AUTO, "weapons/tnt/tnttoss.wav", 1, ATTN_NORM);

    newmis = spawn ();
    newmis.owner = self;
    newmis.movetype = MOVETYPE_BOUNCE;
    newmis.solid = SOLID_BBOX;
    newmis.classname = "grenade";
    #ifdef QUAKEWORLD
    newmis.voided=0;

    msg_entity = self;
    WriteByte (MSG_ONE, SVC_SMALLKICK);
    #else
    self.punchangle_x = -2;
    #endif

    // set newmis speed
    makevectors (self.v_angle);

    if (self.charge)
    {
        // TNT Charge/throw meter power.
        local   float   mspeed, mup;

        mspeed = 200 + (self.charge * 50);
        if (mspeed < 300)
            mspeed = 300;  // don't throw the grenade on our own feet !
        mup = mspeed / 1.75;

        if (self.v_angle_x)
            newmis.velocity = v_forward * mspeed + v_up * mup + crandom () * v_right * 10 + crandom () * v_up * 10;
        else
        {
            newmis.velocity = aim(self, 10000);
            newmis.velocity = newmis.velocity * mspeed;
            newmis.velocity_z = mup;
        }
    }
    else
        newmis.velocity = '0 0 0';

    newmis.touch = GrenadeTouch;

    // Explodes as soon as it takes 1 point of damage
    newmis.takedamage = DAMAGE_AIM;
    newmis.health = 1;
    newmis.th_die = GrenadeExplode;

    newmis.nextthink = 0.1;
    newmis.think     = BombThink;

    setorigin (newmis, self.origin);

    self.player_state = PS_FIRE;

    // If we fire a proximity bomb
    if (self.weapon == IT_PROXIMITY_BOMB)
    {
        newmis.pausetime = time + 2.5;
        newmis.think = ProximBombThink;
        newmis.think1 = ProximBombArmed;
        newmis.netname = "Proximity Bomb";
        newmis.dmg = DMG_PROXIMITY_BOMB;
        newmis.avelocity = '0 300 0';
        newmis.angles = '0 0 0';
        newmis.model = "progs/grd_prox.mdl";
    }
    // else if we fire a remote detonator
    else if (self.weapon == IT_REMOTE_DETONATOR)
    {
        newmis.netname = "Remote Detonator";
        newmis.dmg = DMG_REMOTE_DETONATOR;
        newmis.avelocity = '0 300 0';
        newmis.angles = '0 0 0';
        newmis.model = "progs/grd_remo.mdl";
    }
    // Else, it's TNT or a spray can!
    else
    {
        newmis.style     = self.tnt_type;
        newmis.pausetime = self.tnt_time;
        newmis.think     = DynaThink;
        newmis.touch     = DynaTouch;
        newmis.dest      = normalize (newmis.velocity);

        if (self.weapon == IT_SPRAY_CAN)
        {
            newmis.netname   = "Lit Spray Can";
            newmis.dmg       = DMG_SPRAY_CAN;
            newmis.model     = "progs/grd_aero.mdl";
            newmis.angles    = '0 -300 0';
            if (newmis.style == TNT_TYPE_NORMAL)
                newmis.avelocity = '150 150 150';
            else
                newmis.avelocity = '0 150 150';

            self.weaponframe = 0;  // reset the weapon view
        }
        else
        {
            newmis.netname   = "TNT";
            newmis.dmg       = DMG_TNT;
            newmis.model     = "progs/grd_bund.mdl";
            newmis.avelocity = '300 300 300';
            newmis.angles    = vectoangles(newmis.velocity);
        }
    }

    setmodel (newmis, newmis.model);
    setsize (newmis, '0 0 0', '0 0 0');

    // If we have no more dynamite, we "lose" the weapon
    // (expect for remote detonators: we always have the remote)
    if (self.currentammo == 0 && self.weapon != IT_REMOTE_DETONATOR)
    {
        local float newWeapon;

        self.items = self.items - self.weapon;
        newWeapon = W_BestWeapon();
        W_DrawWeapon (newWeapon);
    }
};


/*
============
TNT_Attack

Attack code for the TNT
============
*/
void() TNT_Attack =
{
    player_throwtnt1 ();
    self.attack_finished = time + 1.0;
};


/*
============
TNT_Draw

Draw code for the TNT
============
*/
void() TNT_Draw =
{
    self.currentammo = self.ammo_tnt_bundle;
    self.items = (self.items - (self.items & (IT_NAILS | IT_SHELLS | IT_CELLS | IT_ROCKETS)));

    TNT_UpdateView ();

    // If we need to pop up the lighter
    if (self.weapon != IT_SPRAY_CAN)
    {
        sound (self, CHAN_WEAPON, "weapons/tnt/lighter.wav", 1, ATTN_NORM);
        player_tntdraw1 ();
        self.attack_finished = time + 0.9;
    }
    else
    {
        player_tnthalfdraw1 ();
        self.attack_finished = time + 0.5;
    }

    self.weapon = IT_TNT;
};


/*
============
TNT_Holster

Holster code for the TNT
============
*/
void() TNT_Holster =
{
    self.attack_finished = time + 0.5;

    // If we need to close the lighter
    if (self.newweapon != IT_SPRAY_CAN)
    {
        sound (self, CHAN_WEAPON, "weapons/tnt/zipclose.wav", 1, ATTN_NORM);
        player_tntholster1 ();
    }
    else
        player_tnthalfholster1 ();
};


/*
============
TNT_UpdateView

Choose the right TNT model to display
============
*/
void() TNT_UpdateView =
{
    self.weaponmodel = "progs/v_rock.mdl";
    self.items = self.items - (self.items & IT_GUNS_AKIMBO);
};


/*
============
Proxy_Attack

Attack code for the proximity bomb
============
*/
void() Proxy_Attack =
{
    player_throwproxy1 ();
    self.attack_finished = time + 0.8;
};


/*
============
Proxy_Draw

Draw code for the proximity bomb
============
*/
void() Proxy_Draw =
{
    self.weapon = IT_PROXIMITY_BOMB;
    self.currentammo = self.ammo_tnt_proxy;
    self.items = self.items - (self.items & (IT_SHELLS | IT_NAILS | IT_CELLS | IT_ROCKETS));

    Proxy_UpdateView ();

    self.attack_finished = time + 0.5;
    player_proxydraw1 ();
};


/*
============
Proxy_Holster

Holster code for the proximity bomb
============
*/
void() Proxy_Holster =
{
    self.attack_finished = time + 0.5;
    player_proxyholster1 ();
};


/*
============
Proxy_UpdateView

Choose the right proximity bomb model to display
============
*/
void() Proxy_UpdateView =
{
    self.weaponmodel = "progs/v_proxy.mdl";
    self.items = self.items - (self.items & IT_GUNS_AKIMBO);
};


/*
============
Remote_Attack

Attack code for the remote detonator
============
*/
void() Remote_Attack =
{
    player_throwremote1 ();
    self.attack_finished = time + 0.8;
};


/*
============
Remote_Draw

Draw code for the remote detonator
============
*/
void() Remote_Draw =
{
    self.weapon = IT_REMOTE_DETONATOR;
    self.currentammo = self.ammo_tnt_remote;
    self.items = self.items - (self.items & (IT_SHELLS | IT_NAILS | IT_CELLS | IT_ROCKETS));

    Remote_UpdateView ();

    self.attack_finished = time + 0.5;

    // If we have just the remote
    if (self.currentammo == 0)
    {
        // FIXME: we should have a "half-draw" animation for this
        self.weaponframe = $remote_fire1;
        self.player_state = PS_HOLD_FIRE;
    }
    else
        player_remotedraw1 ();
};


/*
============
Remote_Holster

Holster code for the remote detonator
============
*/
void() Remote_Holster =
{
    self.attack_finished = time + 0.5;
    player_remoteholster1 ();
};


/*
============
Remote_UpdateView

Choose the right remote detonator model to display
============
*/
void() Remote_UpdateView =
{
    self.weaponmodel = "progs/v_remote.mdl";
    self.items = self.items - (self.items & IT_GUNS_AKIMBO);
};
