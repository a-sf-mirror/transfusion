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
				
#include "common.qh"
#include "player.qh"

void() Leech_BallFire;
void() Leech_BallTouch;

//=======================================================================

// ------------ Life Leech model ---------- //

// Normal mode
$modelname v_leech

// fire
$frame leech_fire1 leech_fire2 leech_fire3 leech_fire4 leech_fire5
$frame leech_fire6 leech_fire7 leech_fire8 leech_fire9 leech_fire10

// draw
$frame leech_draw1 leech_draw2 leech_draw3 leech_draw4

//holster 
$frame leech_holster1 leech_holster2 leech_holster3 leech_holster4

// Akimbo model
$modelname v_aleech

// fire
$frame alech_fire1 alech_fire2 alech_fire3 alech_fire4 alech_fire5
$frame alech_fire6 alech_fire7 alech_fire8 alech_fire9 alech_fire10

// draw
$frame aleech_draw1 aleech_draw2 aleech_draw3 aleech_draw4

//holster 
$frame aleech_holster1 aleech_holster2 aleech_holster3 aleech_holster4

// ------------ Player related code ---------- //

// Normal fire
void() player_leech1 = [$rockatt1, player_leech2]
 { 
	self.player_state = PS_FIRE;
 	self.weaponframe = $leech_fire2; 
	sound (self, CHAN_WEAPON, "weapons/lifelech/laltfr1.wav", 1, ATTN_NORM);
        muzzleflash ();
	Leech_BallFire();	
	Leech_BallFire();	// two balls per frame, 14 shots total
 };
 
void() player_leech2 = [$rockatt2, player_leech3] { self.weaponframe = $leech_fire3; Leech_BallFire(); Leech_BallFire(); };
void() player_leech3 = [$rockatt3, player_leech4] { self.weaponframe = $leech_fire4; Leech_BallFire(); Leech_BallFire(); };
void() player_leech4 = [$rockatt4, player_leech5] { self.weaponframe = $leech_fire5; Leech_BallFire(); Leech_BallFire(); };
void() player_leech5 = [$rockatt5, player_leech6] { self.weaponframe = $leech_fire6; Leech_BallFire(); Leech_BallFire(); };
void() player_leech6 = [$rockatt1, player_leech7] { self.weaponframe = $leech_fire7; Leech_BallFire(); Leech_BallFire(); };
void() player_leech7 = [$rockatt1, player_leech8] { self.weaponframe = $leech_fire8; Leech_BallFire(); Leech_BallFire(); };
void() player_leech8 = [$rockatt1, player_leech9] { self.weaponframe = $leech_fire9; Leech_BallFire(); Leech_BallFire(); };
void() player_leech9 = [$rockatt1, player_leech10] { self.weaponframe = $leech_fire10; };
void() player_leech10 = [$rockatt1, player_run] { self.weaponframe = $leech_fire1; };

//Akimbo mode
void() player_akleech1 = [$rockatt1, player_akleech2] { self.weaponframe = $alech_fire2; muzzleflash (); };
void() player_akleech2 = [$rockatt2, player_akleech3] { self.weaponframe = $alech_fire3; };
void() player_akleech3 = [$rockatt1, player_akleech4] { self.weaponframe = $alech_fire4; Leech_BallFire(); };
void() player_akleech4 = [$rockatt2, player_akleech5] { self.weaponframe = $alech_fire5; };
void() player_akleech5 = [$rockatt3, player_akleech6] { self.weaponframe = $alech_fire6; };
void() player_akleech6 = [$rockatt4, player_akleech7] { self.weaponframe = $alech_fire7; };
void() player_akleech7 = [$rockatt5, player_akleech8] { self.weaponframe = $alech_fire8; };
void() player_akleech8 = [$rockatt1, player_akleech9] { self.weaponframe = $alech_fire9; };
void() player_akleech9 = [$rockatt1, player_akleech10] { self.weaponframe = $alech_fire10; };
void() player_akleech10 = [$rockatt1, player_run]

{ 
    // Check if we have enough ammo for another Akimbo Shot
    if ((self.items & IT_GUNS_AKIMBO) && self.currentammo < 14)  // if < 14, set a flag to drain from player health when ammo reaches 0
    {
	W_SetCurrentAmmo (FALSE, 0);
	self.weaponframe = $alech_fire1;
    }
    else
	self.weaponframe = $alech_fire10;
};

//=================================================================

/*
=========================
Leech_BallFire

Fire the Life Leech Shot
=========================
*/


void() Leech_BallFire =
{

    sound (self, CHAN_WEAPON, "weapons/lifelech/llsngfr3.wav", 1, ATTN_NORM);

};

/*
==================
Leech_BallTouch

Touch function for the Life Leech ball
==================
*/


void() Leech_BallTouch =
{

    sound (self, CHAN_WEAPON, "weapons/lifelech/laltht.wav", 1, ATTN_NORM);

};
				
/*
======================
Leech_Attack

Life Leech Attack Code
======================
*/

void() Leech_Attack = 

{
    // Normal fire or altfire?
    if (self.impulse == 12 || self.button1)
        self.player_state = PS_ALTFIRE;
    else
        self.player_state = PS_FIRE;
			    
    // If we have guns akimbo
    if (self.items & IT_GUNS_AKIMBO)
	{
	player_akleech1 ();
	self.attack_finished = time + 1.2;
	}
    else
	{
	player_leech1 ();
	self.attack_finished = time + 1.0;
	}
										
    Leech_BallFire ();
};
											    

