//==========================================================================
//  inven.qc -- by Patrick Martin               Last updated:  8-17-2001
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

// The new item* fields are used to store inventory items.  Unlike
// '.item' and '.item2', each item uses seven bits per item since
// each item has a fuel gauge.
.float      items3;
.float      items4;

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
        return (self.items3 & (SEVEN_BITS * IT3_FIRST_AID)) / IT3_FIRST_AID;
    if (itype == S_DIVING_SUIT)
        return (self.items3 & (SEVEN_BITS * IT3_DIVING_SUIT)) / IT3_DIVING_SUIT;
    if (itype == S_CRYSTAL_BALL)
        return (self.items4 & (SEVEN_BITS * IT4_CRYSTAL_BALL)) / IT4_CRYSTAL_BALL;
    if (itype == S_BEAST_VISION)
        return (self.items4 & (SEVEN_BITS * IT4_BEAST_VISION)) / IT4_BEAST_VISION;
    if (itype == S_JUMP_BOOTS)
        return (self.items3 & (SEVEN_BITS * IT3_JUMP_BOOTS)) / IT3_JUMP_BOOTS;

    return 0;
};

// This sets the power level of an item.
void(entity who, float itype, float fuel) InvenSet =
{
    local   float   noitems;

    noitems = FALSE;
    if (!who.items3)
        if (!who.items4)
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
        who.items3 = who.items3 - (who.items3 & (SEVEN_BITS * IT3_FIRST_AID));
        who.items3 = who.items3 + (fuel * IT3_FIRST_AID);
        return;
    }
    if (itype == S_DIVING_SUIT)
    {
        if (noitems)
            who.it_select = itype;
        who.items3 = who.items3 - (who.items3 & (SEVEN_BITS * IT3_DIVING_SUIT));
        who.items3 = who.items3 + (fuel * IT3_DIVING_SUIT);
        who.dive_time = 0;
        return;
    }
    if (itype == S_CRYSTAL_BALL)
    {
        if (noitems)
            who.it_select = itype;
        who.items4 = who.items4 - (who.items4 & (SEVEN_BITS * IT4_CRYSTAL_BALL));
        who.items4 = who.items4 + (fuel * IT4_CRYSTAL_BALL);
        who.xray_time = 0;
        return;
    }
    if (itype == S_BEAST_VISION)
    {
        if (noitems)
            who.it_select = itype;
        who.items4 = who.items4 - (who.items4 & (SEVEN_BITS * IT4_BEAST_VISION));
        who.items4 = who.items4 + (fuel * IT4_BEAST_VISION);
        who.beast_time = 0;
        return;
    }
    if (itype == S_JUMP_BOOTS)
    {
        if (noitems)
            who.it_select = itype;
        who.items3 = who.items3 - (who.items3 & (SEVEN_BITS * IT3_JUMP_BOOTS));
        who.items3 = who.items3 + (fuel * IT3_JUMP_BOOTS);
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
        Sprint (self, PRINT_MEDIUM, "No first-aid\n");
        return;
    }
    if (self.health >= self.max_health)
    {
        Sprint (self, PRINT_MEDIUM, "You don't need first-aid\n");
        return;
    }

    need = self.max_health - self.health;
    if (faid > need)
    {
        self.health = self.max_health;
        faid = faid - need;

        local   string  text;

        text = ftos(faid);
        Sprint (self, PRINT_MEDIUM, "First-aid is now at ");
        Sprint (self, PRINT_MEDIUM, text);
        Sprint (self, PRINT_MEDIUM, "%\n");
    }
    else
    {
        self.health = self.health + faid;
        faid = 0;
        Sprint (self, PRINT_MEDIUM, "First-aid used up\n");
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

//        Sprint (self, PRINT_MEDIUM, "Dive ON\n");
        self.items = self.items | IT_SUIT;
        self.dive_time = time + self.dive_time;
        sound (self, CHAN_ITEM, "bludbath/powerup.wav", 1, ATTN_NORM);
    }
    else
    {
//        Sprint (self, PRINT_MEDIUM, "Dive OFF\n");
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
        Sprint (self, PRINT_MEDIUM, "Boots ON\n");
        self.boots_time = time + self.boots_time;
        sound (self, CHAN_ITEM, "bludbath/powerup.wav", 1, ATTN_NORM);
    }
    else
    {
        Sprint (self, PRINT_MEDIUM, "Boots OFF\n");
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
            Sprint (self, PRINT_MEDIUM, "��� ");
        else
            Sprint (self, PRINT_MEDIUM, "Aid: ");
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
            Sprint (self, PRINT_MEDIUM, "����� ");
        else
            Sprint (self, PRINT_MEDIUM, "Suit: ");
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
            Sprint (self, PRINT_MEDIUM, "����� ");
        else
            Sprint (self, PRINT_MEDIUM, "Xray: ");
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
            Sprint (self, PRINT_MEDIUM, "������ ");
        else
            Sprint (self, PRINT_MEDIUM, "Beast: ");
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
            Sprint (self, PRINT_MEDIUM, "���� ");
        else
            Sprint (self, PRINT_MEDIUM, "Jump: ");
        Sprint (self, PRINT_MEDIUM, text);
    }

//    if (!i)
//        Sprint (self, PRINT_MEDIUM, "No inventory");

    Sprint (self, PRINT_MEDIUM, "\n");
};

// This lets a player select another item in the inventory.
void(float add) InvenSelect =
{
    if (!self.items3)
        if (!self.items4)
        {
            // No items.
            self.it_select = 0;
            Sprint (self, PRINT_MEDIUM, "No inventory\n");
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
                    Sprint (self, PRINT_MEDIUM, "Dive at ");
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
                    Sprint (self, PRINT_MEDIUM, "Jump at ");
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