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

// This controls a player's inventory of items.
//
// NOTE:  Each item can be carried for later use.  All unused items
//        start with 100 points.

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

// *_on are boolean fields.  If TRUE, item is on.
// *_time are float fields.  If <= time while item is on, fuel decreases.
//   While item is off, this holds the time left before fuel decrease.
.float      boots_on;
.float      boots_time;
.float      dive_on;
.float      dive_time;
.float      beast_on;
.float      beast_time;
//.float      xray_on;
.float      xray_time;

//========================================================================
//  Item Power Settings

void(float add, float noprint) InvenSelect;

// Set the current item as the first available one
void() InvenSetOnFirst =
{
	self.it_select  = 0;    // Default to first-aid.
	InvenSelect(TRUE, TRUE);
};

// This returns the amount of power left in an item.
float(float itype) InvenFuel =
{
	if (itype == INV_FIRST_AID)
		return (self.inven1 & (SEVEN_BITS * IT3_FIRST_AID)) / IT3_FIRST_AID;
	if (itype == INV_DIVING_SUIT)
		return (self.inven1 & (SEVEN_BITS * IT3_DIVING_SUIT)) / IT3_DIVING_SUIT;
	if (itype == INV_CRYSTAL_BALL)
		return (self.inven2 & (SEVEN_BITS * IT4_CRYSTAL_BALL)) / IT4_CRYSTAL_BALL;
	if (itype == INV_BEAST_VISION)
		return (self.inven2 & (SEVEN_BITS * IT4_BEAST_VISION)) / IT4_BEAST_VISION;
	if (itype == INV_JUMP_BOOTS)
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
	fuel = InvenFuel(itype);
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
	fuel = floor(fuel);
	if (fuel > 100)
		fuel = 100;
	else if (fuel < 0)
		fuel = 0;

	if (noitems)
		who.it_select = itype;

	// Now reset the desired item.
	if (itype == INV_FIRST_AID)
	{        
		who.inven1 = who.inven1 - (who.inven1 & (SEVEN_BITS * IT3_FIRST_AID));
		who.inven1 = who.inven1 + (fuel * IT3_FIRST_AID);
		return;
	}
	else if (itype == INV_DIVING_SUIT)
	{
		who.inven1 = who.inven1 - (who.inven1 & (SEVEN_BITS * IT3_DIVING_SUIT));
		who.inven1 = who.inven1 + (fuel * IT3_DIVING_SUIT);
		who.dive_time = 0;
		return;
	}
	else if (itype == INV_CRYSTAL_BALL)
	{
		who.inven2 = who.inven2 - (who.inven2 & (SEVEN_BITS * IT4_CRYSTAL_BALL));
		who.inven2 = who.inven2 + (fuel * IT4_CRYSTAL_BALL);
		who.xray_time = 0;
		return;
	}
	else if (itype == INV_BEAST_VISION)
	{
		who.inven2 = who.inven2 - (who.inven2 & (SEVEN_BITS * IT4_BEAST_VISION));
		who.inven2 = who.inven2 + (fuel * IT4_BEAST_VISION);
		who.beast_time = 0;
		return;
	}
	else if (itype == INV_JUMP_BOOTS)
	{        
		who.inven1 = who.inven1 - (who.inven1 & (SEVEN_BITS * IT3_JUMP_BOOTS));
		who.inven1 = who.inven1 + (fuel * IT3_JUMP_BOOTS);
		who.boots_time = 0;
		return;
	}
	else
		bprint("The new inventory item needs to be coded in InvenSet()\n");
};

//========================================================================
//  Item Usage
void() Use_FirstAid =
{
	local   float   faid, need;

	faid = InvenFuel(INV_FIRST_AID);
	if (faid == 0)
	{
		sprint(self, "You don't have the Doctor's Bag\n");
		return;
	}
	if (self.health >= self.max_health)
	{
		sprint(self, "You don't need the Doctor's Bag\n");
		return;
	}

	need = self.max_health - self.health;
	if (faid > need)
	{
		self.health = self.max_health;
		faid = faid - need;

		local   string  text;

		text = ftos(faid);
		sprint3(self, "Doctor's Bag health level is now at ", text, "%\n");
	}
	else
	{
		self.health = self.health + faid;
		faid = 0;
		sprint(self, "Doctor's Bag is used up\n");
	}

	InvenSet(self, INV_FIRST_AID, faid);
	sound(self, CHAN_ITEM, "items/pickheal.wav", 1, ATTN_NORM);

	if (!faid)
		InvenSetOnFirst();
};

void() Use_DivingSuit =
{
	if (!InvenFuel(INV_DIVING_SUIT))
	return;

	self.dive_on = !self.dive_on;
	if (self.dive_on)
	{
		if (self.waterlevel < 3)
		{
			// Not underwater, so turn it back off.
			self.dive_on = !self.dive_on;
			return;
		}

		sprint(self, "Diving Suit ON\n");
		self.items = self.items | IT_SUIT;
		self.dive_time = time + self.dive_time;
		sound(self, CHAN_ITEM, "foley/swimuw.wav", 1, ATTN_NORM);
	}
	else
	{
		sprint(self, "Diving Suit OFF\n");
		self.items = self.items - (self.items & IT_SUIT);
		self.dive_time = self.dive_time - time;
	}
};

void() Use_CrystalBall =
{
	if (!InvenFuel(INV_CRYSTAL_BALL))
		return;

	sprint(self, "FIXME:  Crystal ball\n");
	InvenSet(self, INV_CRYSTAL_BALL, 0);     // Remove it from inventory.
	sound(self, CHAN_ITEM, "bludbath/powerup.wav", 1, ATTN_NORM);
};

void(float OnOrOff) ToggleBeastVision =
{
	other = nextent(world);

	while (other != world)
	{
		if (other.classname == "player" || (other.flags & FL_MONSTER))
		{
			if (OnOrOff)
				other.effects = other.effects | EF_FULLBRIGHT;

			// Avoid turning on unwanted effects when you turn off your beast vision
			else if (other.effects & EF_FULLBRIGHT)				    
				other.effects = other.effects - (other.effects | EF_FULLBRIGHT);
		}

		other = nextent(other);
	}
};

void() Use_BeastVision =
{    
	if (!InvenFuel (INV_BEAST_VISION))
		return;

	self.beast_on = !self.beast_on;    
	if (self.beast_on)
	{
		sprint(self, "Beast vision ON\n");
		self.beast_time = time + self.beast_time;
		sound(self, CHAN_ITEM, "bludbath/powerup.wav", 1, ATTN_NORM);
		ToggleBeastVision(TRUE);
	}
	else
	{
		sprint(self, "Beast vision OFF\n");
		self.beast_time = self.beast_time - time;
		ToggleBeastVision(FALSE);
	}    
};

void() Use_JumpBoots =
{
	if (!InvenFuel(INV_JUMP_BOOTS))
	return;

	self.boots_on = !self.boots_on;
	if (self.boots_on)
	{
		sprint(self, "Boots of Jumping ON\n");
		self.boots_time = time + self.boots_time;
		sound(self, CHAN_ITEM, "bludbath/powerup.wav", 1, ATTN_NORM);
	}
	else
	{
		sprint(self, "Boots of Jumping OFF\n");
		self.boots_time = self.boots_time - time;
	}
};

//========================================================================
//  Inventory Commands

// This uses the currently selected item.
void() InvenUse =
{
	if (self.it_select == INV_FIRST_AID)
		Use_FirstAid();
	else if (self.it_select == INV_DIVING_SUIT)
		Use_DivingSuit();
	else if (self.it_select == INV_CRYSTAL_BALL)
		Use_CrystalBall();
	else if (self.it_select == INV_BEAST_VISION)
		Use_BeastVision();
	else if (self.it_select == INV_JUMP_BOOTS)
		Use_JumpBoots();
	else
		sprint(self, "Tried to use unknown item\n");
};

// This displays the inventory.  Selected item is displayed in red.
void(float chosen) InvenList =
{
	local   float   fuel, i;
	local   string  text;

	i = 0;
	fuel = InvenFuel(INV_FIRST_AID);
	if (fuel)
	{
		text = ftos(fuel);
		if (chosen == INV_FIRST_AID)
			sprint(self, "Äïãôïò§ó Âáçº ");
		else
			sprint(self, "Doctor's Bag: ");
		sprint(self, text);
		i = i + 1;
	}

	fuel = InvenFuel(INV_DIVING_SUIT);
	if (fuel)
	{
		text = ftos(fuel);
		if (i)
			sprint(self, " / ");
		if (chosen == INV_DIVING_SUIT)
			sprint(self, "Äéöéîç Óõéôº ");
		else
			sprint(self, "Diving Suit: ");
		sprint(self, text);
		i = i + 1;
	}

	fuel = InvenFuel(INV_CRYSTAL_BALL);
	if (fuel)
	{
		text = ftos(fuel);
		if (i)
			sprint(self, " / ");
		if (chosen == INV_CRYSTAL_BALL)
			sprint(self, "Ãòùóôáì Âáììº ");
		else
			sprint(self, "Crystal Ball: ");
		sprint(self, text);
		i = i + 1;
	}

	fuel = InvenFuel(INV_BEAST_VISION);
	if (fuel)
	{
		text = ftos(fuel);
		if (i)
			sprint(self, " / ");
		if (chosen == INV_BEAST_VISION)
			sprint(self, "Âåáóô Öéóéïîº ");
		else
			sprint(self, "Beast Vision: ");
		sprint(self, text);
		i = i + 1;
	}

	fuel = InvenFuel(INV_JUMP_BOOTS);
	if (fuel)
	{
		text = ftos(fuel);
		if (i)
			sprint(self, " / ");
		if (chosen == INV_JUMP_BOOTS)
			sprint(self, "Âïïôó ïæ Êõíðéîçº ");
		else
			sprint(self, "Boots of Jumping: ");
		sprint(self, text);
		i = i + 1;
	}

	if (!i)
		sprint(self, "You aren't carrying anything");

	sprint(self, "\n");
};

/*
====================
InventChange

Called when the player explicitely switches
its current inventory item using an impulse
====================
*/
void() InventChange =
{
	local float choice;

	choice = -1;
	if (self.impulse == IMP_FIRST_AID)
		choice = INV_FIRST_AID;
	else if (self.impulse == IMP_CRYSTAL_BALL)
		choice = INV_CRYSTAL_BALL;
	else if (self.impulse == IMP_BEAST_VISION)
		choice = INV_BEAST_VISION;
	else if (self.impulse == IMP_JUMP_BOOTS)
		choice = INV_JUMP_BOOTS;

	// If there's no item matching the impulse
	if (choice == -1)
		error("No inventory item is assigned to that impulse number\n");

	// If we don't have that item
	if (!InvenFuel (choice))
	{
		sprint(self, "You don't have that item.\n");
		return;
	}

	self.it_select = choice;
	InvenList(choice);
};

// This lets a player select another item in the inventory.
void(float add, float noprint) InvenSelect =
{
	if (!self.inven1)
	if (!self.inven2)
	{
		// No items.
		self.it_select = 0;
		if (!noprint)
			sprint(self, "You aren't carrying anything\n");
		return;
	}

	local float fuel;
	local float old;

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

	// Display inventory.
	if (!noprint)
		InvenList(self.it_select);
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
			fuel = InvenFuel(INV_DIVING_SUIT);
			if (fuel > 0)
			{
				fuel = fuel - 1;
				InvenSet(self, INV_DIVING_SUIT, fuel);
				self.dive_time = time + 0.3;

				// Debug message.
				fuel = fuel * 0.1;
				if (floor(fuel) == fuel)
				{
					text = ftos(fuel * 10);
					sprint3(self, "Dive Suit air remaining: ", text, "%\n");
				}
			}
			// All gone. Turn it off
			else
			{
				self.dive_time  = 0;
				self.items      = self.items - (self.items & IT_SUIT);
				self.dive_on    = 0;
				InvenSetOnFirst();
			}
		}
	}

	// Jump Boots
	if (self.boots_on)
	{
		if (self.boots_time <= time)
		{
			fuel = InvenFuel(INV_JUMP_BOOTS);
			if (fuel > 0)
			{
				fuel = fuel - 1;
				InvenSet(self, INV_JUMP_BOOTS, fuel);
				self.boots_time = time + 0.3;

				// Debug message.
				fuel = fuel * 0.1;
				if (floor(fuel) == fuel)
				{
					text = ftos(fuel * 10);
					sprint3(self, "Boots of Jumping time remaining ", text, "%\n");
				}
			}
			// All gone. Turn it off
			else
			{
				self.boots_on   = 0;
				self.boots_time = 0;
				InvenSetOnFirst();
			}
		}
	}

	// Beast vision
	if (self.beast_on)
	{
		if (self.beast_time <= time)
		{
			fuel = InvenFuel(INV_BEAST_VISION);
			if (fuel > 0)
			{
				fuel = fuel - 1;
				InvenSet(self, INV_BEAST_VISION, fuel);
				self.beast_time = time + 0.3;

				// Debug message.
				fuel = fuel * 0.1;
				if (floor(fuel) == fuel)
				{
					text = ftos(fuel * 10);
					sprint3(self, "Beast Vision time remaining ", text, "%\n");
				}
			}
			// All gone. Turn it off
			else
			{
				ToggleBeastVision(FALSE);
				self.beast_on   = 0;
				self.beast_time = 0;
				InvenSetOnFirst();
			}
		}
	}	

};
