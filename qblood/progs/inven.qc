/*  Copyright (C) 2001  Patrick Martin

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

//==========================================================================
//  inven.qc -- by Patrick Martin               Last updated:  10-1-2001
//--------------------------------------------------------------------------
//  This controls a player's inventory of items.
//
//  NOTE:  Each item can be carried for later use.  All unused items
//         start with 100 points.
//==========================================================================

#include "common.qh"

//--------------------//
//  NEW EDICT FIELDS  //
//--------------------//

// The new inven* fields are used to store inventory items.  Unlike
// '.item' and '.item2', each item uses seven bits per item since
// each item has a fuel gauge.
.float      inven1;
.float      inven2;

.float      it_select;      // Current item selected from inventory.
.float      it_on;          // If > time, inventory should be on screen.

// *_on are boolean fields.  If TRUE, item is on.
// *_time are float fields.  If <= time while item is on, fuel decreases.
//   While item is off, this holds the time left before fuel decrease.
.float      boots_on;
.float      boots_time;
.float      dive_on;
.float      dive_time;
.float      beast_on;
.float      beast_time;
.float      xray_on;
.float      xray_time;

//-----------------//
//  NEW CONSTANTS  //
//-----------------//

#define SEVEN_BITS          127

#define IT3_FIRST_AID       1
#define IT3_JUMP_BOOTS      128
#define IT3_DIVING_SUIT     16384

#define IT4_BEAST_VISION    1
#define IT4_CRYSTAL_BALL    128


//========================================================================
//  Item Power Settings

// This returns the amount of power left in an item.
float(float itype) InvenFuel =
{
    local   float   fuel;

    if (itype == S_FIRST_AID)
        return (self.inven1 & (SEVEN_BITS * IT3_FIRST_AID)) / IT3_FIRST_AID;
    if (itype == S_DIVING_SUIT)
        return (self.inven1 & (SEVEN_BITS * IT3_DIVING_SUIT)) / IT3_DIVING_SUIT;
    if (itype == S_CRYSTAL_BALL)
        return (self.inven2 & (SEVEN_BITS * IT4_CRYSTAL_BALL)) / IT4_CRYSTAL_BALL;
    if (itype == S_BEAST_VISION)
        return (self.inven2 & (SEVEN_BITS * IT4_BEAST_VISION)) / IT4_BEAST_VISION;
    if (itype == S_JUMP_BOOTS)
        return (self.inven1 & (SEVEN_BITS * IT3_JUMP_BOOTS)) / IT3_JUMP_BOOTS;

    return 0;
};

// This checks if item is maxed.  Returns TRUE if power >= 100.
float(entity who, float itype) InvenMax =
{
    local   entity  oself;
    local   float   fuel;

    oself = self;
    self = who;
    fuel = InvenFuel (itype);
    self = oself;

    return (fuel >= 100);
};

// This sets the power level of an item.
void(entity who, float itype, float fuel) InvenSet =
{
    local   float   noitems;

    noitems = FALSE;
    if (!who.inven1)
        if (!who.inven2)
            noitems = TRUE;

    // Make sure the power setting is legal.
    fuel = floor (fuel);
    if (fuel > 100)
        fuel = 100;
    else if (fuel < 0)
        fuel = 0;

    // Now reset the desired item.
    if (itype == S_FIRST_AID)
    {
        if (noitems)
            who.it_select = itype;
        who.inven1 = who.inven1 - (who.inven1 & (SEVEN_BITS * IT3_FIRST_AID));
        who.inven1 = who.inven1 + (fuel * IT3_FIRST_AID);
        return;
    }
    if (itype == S_DIVING_SUIT)
    {
        if (noitems)
            who.it_select = itype;
        who.inven1 = who.inven1 - (who.inven1 & (SEVEN_BITS * IT3_DIVING_SUIT));
        who.inven1 = who.inven1 + (fuel * IT3_DIVING_SUIT);
        who.dive_time = 0;
        return;
    }
    if (itype == S_CRYSTAL_BALL)
    {
        if (noitems)
            who.it_select = itype;
        who.inven2 = who.inven2 - (who.inven2 & (SEVEN_BITS * IT4_CRYSTAL_BALL));
        who.inven2 = who.inven2 + (fuel * IT4_CRYSTAL_BALL);
        who.xray_time = 0;
        return;
    }
    if (itype == S_BEAST_VISION)
    {
        if (noitems)
            who.it_select = itype;
        who.inven2 = who.inven2 - (who.inven2 & (SEVEN_BITS * IT4_BEAST_VISION));
        who.inven2 = who.inven2 + (fuel * IT4_BEAST_VISION);
        who.beast_time = 0;
        return;
    }
    if (itype == S_JUMP_BOOTS)
    {
        if (noitems)
            who.it_select = itype;
        who.inven1 = who.inven1 - (who.inven1 & (SEVEN_BITS * IT3_JUMP_BOOTS));
        who.inven1 = who.inven1 + (fuel * IT3_JUMP_BOOTS);
        who.boots_time = 0;
        return;
    }
};

// This recharges all items in inventory except first-aid back to 100.
// Should be used after level change.
void() InvenRecharge =
{
    if (InvenFuel (S_DIVING_SUIT))
        InvenSet (self, S_DIVING_SUIT, 100);
    if (InvenFuel (S_CRYSTAL_BALL))
        InvenSet (self, S_CRYSTAL_BALL, 100);
    if (InvenFuel (S_BEAST_VISION))
        InvenSet (self, S_BEAST_VISION, 100);
    if (InvenFuel (S_JUMP_BOOTS))
        InvenSet (self, S_JUMP_BOOTS, 100);
};


//========================================================================
//  Item Usage

void() Use_FirstAid =
{
    local   float   faid, need;

    faid = InvenFuel (S_FIRST_AID);
    if (faid == 0)
    {
        Sprint (self, PRINT_MEDIUM, "You don't have the Doctor's Bag\n");
        return;
    }
    if (self.health >= self.max_health)
    {
        Sprint (self, PRINT_MEDIUM, "You don't need the Doctor's Bag\n");
        return;
    }

    need = self.max_health - self.health;
    if (faid > need)
    {
        self.health = self.max_health;
        faid = faid - need;

        local   string  text;

        text = ftos(faid);
        Sprint (self, PRINT_MEDIUM, "Doctor's Bag health level is now at ");
        Sprint (self, PRINT_MEDIUM, text);
        Sprint (self, PRINT_MEDIUM, "%\n");
    }
    else
    {
        self.health = self.health + faid;
        faid = 0;
        Sprint (self, PRINT_MEDIUM, "Doctor's Bag is used up\n");
    }

    InvenSet (self, S_FIRST_AID, faid);
    sound (self, CHAN_ITEM, "items/pickheal.wav", 1, ATTN_NORM);
};

void() Use_DivingSuit =
{
    if (!InvenFuel (S_DIVING_SUIT))
    {
        // No more dive suit.
        self.items      = self.items - (self.items & IT_SUIT);
        self.dive_on    = 0;
        self.dive_time  = 0;
        self.it_select  = 0;    // Default to first-aid.
        return;
    }

    self.dive_on = !self.dive_on;
    if (self.dive_on)
    {
        if (self.waterlevel < 3)
        {
            // Not underwater, so turn it back off.
            self.dive_on = !self.dive_on;
            return;
        }

//        Sprint (self, PRINT_MEDIUM, "Diving Suit ON\n");
        self.items = self.items | IT_SUIT;
        self.dive_time = time + self.dive_time;
        sound (self, CHAN_ITEM, "foley/swimuw.wav", 1, ATTN_NORM);
    }
    else
    {
//        Sprint (self, PRINT_MEDIUM, "Diving Suit OFF\n");
        self.items = self.items - (self.items & IT_SUIT);
        self.dive_time = self.dive_time - time;
    }
};

void() Use_CrystalBall =
{
    if (!InvenFuel (S_CRYSTAL_BALL))
        return;

    Sprint (self, PRINT_MEDIUM, "FIXME:  Crystal ball\n");
    InvenSet (self, S_CRYSTAL_BALL, 0);     // Remove it from inventory.
    sound (self, CHAN_ITEM, "bludbath/powerup.wav", 1, ATTN_NORM);
};

void() Use_BeastVision =
{
    if (!InvenFuel (S_BEAST_VISION))
        return;

    Sprint (self, PRINT_MEDIUM, "FIXME:  Beast vision\n");
    InvenSet (self, S_BEAST_VISION, 0);     // Remove it from inventory.
    sound (self, CHAN_ITEM, "bludbath/powerup.wav", 1, ATTN_NORM);
};

void() Use_JumpBoots =
{
    if (!InvenFuel (S_JUMP_BOOTS))
    {
        // No more jump power.
        self.boots_on   = 0;
        self.boots_time = 0;
        self.it_select  = 0;    // Default to first-aid.
        return;
    }

    self.boots_on = !self.boots_on;
    if (self.boots_on)
    {
        Sprint (self, PRINT_MEDIUM, "Boots of Jumping ON\n");
        self.boots_time = time + self.boots_time;
        sound (self, CHAN_ITEM, "bludbath/powerup.wav", 1, ATTN_NORM);
    }
    else
    {
        Sprint (self, PRINT_MEDIUM, "Boots of Jumping OFF\n");
        self.boots_time = self.boots_time - time;
    }
};


//========================================================================
//  Inventory Commands

// This uses the currently selected item.
void() InvenUse =
{
    if (self.it_select == S_FIRST_AID)
        Use_FirstAid ();
    else if (self.it_select == S_DIVING_SUIT)
        Use_DivingSuit ();
    else if (self.it_select == S_CRYSTAL_BALL)
        Use_CrystalBall ();
    else if (self.it_select == S_BEAST_VISION)
        Use_BeastVision ();
    else if (self.it_select == S_JUMP_BOOTS)
        Use_JumpBoots ();
    else
        Sprint (self, PRINT_MEDIUM, "Tried to use unknown item\n");
};

// This displays the inventory.  Selected item is displayed in red.
void(float chosen) InvenList =
{
    local   float   fuel, i;
    local   string  text;

    i = 0;
    fuel = InvenFuel (S_FIRST_AID);
    if (fuel)
    {
        text = ftos(fuel);
        if (chosen == S_FIRST_AID)
            Sprint (self, PRINT_MEDIUM, "Äïãôïò§ó Âáçº ");
        else
            Sprint (self, PRINT_MEDIUM, "Doctor's Bag: ");
        Sprint (self, PRINT_MEDIUM, text);
        i = i + 1;
    }

    fuel = InvenFuel (S_DIVING_SUIT);
    if (fuel)
    {
        text = ftos(fuel);
        if (i)
            Sprint (self, PRINT_MEDIUM, " / ");
        if (chosen == S_DIVING_SUIT)
            Sprint (self, PRINT_MEDIUM, "Äéöéîç Óõéôº ");
        else
            Sprint (self, PRINT_MEDIUM, "Diving Suit: ");
        Sprint (self, PRINT_MEDIUM, text);
        i = i + 1;
    }

    fuel = InvenFuel (S_CRYSTAL_BALL);
    if (fuel)
    {
        text = ftos(fuel);
        if (i)
            Sprint (self, PRINT_MEDIUM, " / ");
        if (chosen == S_CRYSTAL_BALL)
            Sprint (self, PRINT_MEDIUM, "Ãòùóôáì Âáììº ");
        else
            Sprint (self, PRINT_MEDIUM, "Crystal Ball: ");
        Sprint (self, PRINT_MEDIUM, text);
        i = i + 1;
    }

    fuel = InvenFuel (S_BEAST_VISION);
    if (fuel)
    {
        text = ftos(fuel);
        if (i)
            Sprint (self, PRINT_MEDIUM, " / ");
        if (chosen == S_BEAST_VISION)
            Sprint (self, PRINT_MEDIUM, "Âåáóô Öéóéïîº ");
        else
            Sprint (self, PRINT_MEDIUM, "Beast Vision: ");
        Sprint (self, PRINT_MEDIUM, text);
        i = i + 1;
    }

    fuel = InvenFuel (S_JUMP_BOOTS);
    if (fuel)
    {
        text = ftos(fuel);
        if (i)
            Sprint (self, PRINT_MEDIUM, " / ");
        if (chosen == S_JUMP_BOOTS)
            Sprint (self, PRINT_MEDIUM, "Âïïôó ïæ Êõíðéîçº ");
        else
            Sprint (self, PRINT_MEDIUM, "Boots of Jumping: ");
        Sprint (self, PRINT_MEDIUM, text);
    }

//    if (!i)
//        Sprint (self, PRINT_MEDIUM, "You aren't carrying anything");

    Sprint (self, PRINT_MEDIUM, "\n");
};

// This lets a player select another item in the inventory.
void(float add) InvenSelect =
{
    if (!self.inven1)
        if (!self.inven2)
        {
            // No items.
            self.it_select = 0;
            Sprint (self, PRINT_MEDIUM, "You aren't carrying anything\n");
            return;
        }

    if (self.it_on > time)
    {
        // Change items while inventory is onscreen.
        local   float   fuel;
        local   float   old;

        old = self.it_select;   // Remember old item in case selection fails.
        if (add)
        {
            // Scroll to the right.
            do
            {
                self.it_select = self.it_select + 1;
                if (self.it_select > 4)
                {
                    // Failed -- select old item back and abort.
                    self.it_select = old;
                    fuel = -1;
                }
                else
                    fuel = InvenFuel (self.it_select);
            }
            while (!fuel);
        }
        else
        {
            // Scroll to the left.
            do
            {
                self.it_select = self.it_select - 1;
                if (self.it_select < 0)
                {
                    // Failed -- select old item back and abort.
                    self.it_select = old;
                    fuel = -1;
                }
                else
                    fuel = InvenFuel (self.it_select);
            }
            while (!fuel);
        }
    }

    // Display inventory.
    self.it_on = time + 5;
    InvenList (self.it_select);
};

// This gives the cheater all items.
void() InvenCheat =
{
    InvenSet (self, S_FIRST_AID, 100);
    InvenSet (self, S_DIVING_SUIT, 100);
    InvenSet (self, S_CRYSTAL_BALL, 100);
    InvenSet (self, S_BEAST_VISION, 100);
    InvenSet (self, S_JUMP_BOOTS, 100);
    Sprint (self, PRINT_MEDIUM, "satchel -- Your inventory is full.\n");
};


//========================================================================
//  Inventory Check

// NOTE:  100 points == 30 seconds.  1 point == 3 frames.

// This checks for activated items.  Should be called from 'CheckPowerups'.
void() InvenCheck =
{
    local   float   fuel;
    local   string  text;

// Diving Suit
    if (self.dive_on)
    {
        self.air_finished = time + 12;      // Don't drown!

        if (self.dive_time <= time)
        {
            fuel = InvenFuel (S_DIVING_SUIT);
            if (fuel > 0)
            {
                fuel = fuel - 1;
                InvenSet (self, S_DIVING_SUIT, fuel);
                self.dive_time = time + 0.3;

            // Debug message.
                fuel = fuel * 0.1;
                if (floor(fuel) == fuel)
                {
                    text = ftos(fuel * 10);
                    Sprint (self, PRINT_MEDIUM, "Dive Suit air remaining: ");
                    Sprint (self, PRINT_MEDIUM, text);
                    Sprint (self, PRINT_MEDIUM, "%\n");
                }
            }
            else
            {
                // All gone -- turn it off.
                self.it_select = 0;
                self.dive_time = 0;
                Use_DivingSuit ();
            }
        }
    }

// Jump Boots
    if (self.boots_on)
    {
        if (self.boots_time <= time)
        {
            fuel = InvenFuel (S_JUMP_BOOTS);
            if (fuel > 0)
            {
                fuel = fuel - 1;
                InvenSet (self, S_JUMP_BOOTS, fuel);
                self.boots_time = time + 0.3;

            // Debug message.
                fuel = fuel * 0.1;
                if (floor(fuel) == fuel)
                {
                    text = ftos(fuel * 10);
                    Sprint (self, PRINT_MEDIUM, "Boots of Jumping time remaining ");
                    Sprint (self, PRINT_MEDIUM, text);
                    Sprint (self, PRINT_MEDIUM, "%\n");
                }
            }
            else
            {
                // All gone -- turn it off.
                Use_JumpBoots ();
            }
        }
    }
};


//===========================/  END OF FILE  /===========================//
