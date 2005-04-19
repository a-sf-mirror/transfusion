/*
Copyright (C) 2001-2002 Timothy Hale <timhale@planetblood.com>

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#include "global.h" // FILE
#include "blood.h"  // for defines

void Blood_To_qBlood (unsigned short i, FILE *f)
{
	switch (sprite[i].picnum)
	{

/* Weapons */
	case FLAREPISTOL:	//524 Weapon # 2
		WriteSimpleItem(i, "weapon_flaregun", f);
		return;

	case SHOTGUN:		//559 Weapon # 3
		WriteSimpleItem(i, "weapon_supershotgun", f);
		return;

	case TOMMYGUN:		//558 Weapon # 4
		WriteSimpleItem(i, "weapon_nailgun", f);
		return;

	case NAPALMLAUNCHER://526 Weapon # 5
		WriteSimpleItem(i, "weapon_rocketlauncher", f);
		return;

	case TNTSTICK:		//589 Weapon # 6
		WriteSimpleItem(i, "item_tnt", f); 
		return;

	case TNTBOX:		//809 Weapon # 6
		WriteSimpleItem(i, "weapon_grenadelauncher", f);
		return;

	case TNTREMOTE:		//810 Weapon # 6
		WriteSimpleItem(i, "weapon_remote", f);
		return;
		
	case TNTPROXIMITY:	//811 Weapon # 6
		WriteSimpleItem(i, "weapon_proximity", f);
		return;

	case SPRAYCAN:		//618 Weapon # 7
		WriteSimpleItem(i, "weapon_supernailgun", f);
		return;

	case TESLACANNON:	//539 Weapon # 8
		WriteSimpleItem(i, "weapon_lightning", f);
		return;

	case VOODOODOLL:	//525 Weapon # 9
		WriteSimpleItem(i, "weapon_voodoodoll", f);
		return;
    
    case LIFELEECH:	    //800 Weapon # 0
		WriteSimpleItem(i, "weapon_lifeleech", f);
		return;

/* Ammo */
	case FLARES:		//816
		WriteSimpleItem(i, "item_flares", f);
		return;

	case SHOTGUNSHELLS_MORE://812
		WriteFlaggedItem(i, "item_shells", f, 1); //*BIG*, GOOD
        return;

	case TOMMYCLIP:		//817
		WriteFlaggedItem(i, "item_spikes", f, 1); //*BIG*, GOOD
		return;

    case TOMMYSHELLS:	//813
		WriteSimpleItem(i, "item_spikes", f); 
		return;

	case GASOLINE:		//801
		WriteSimpleItem(i, "item_rockets", f);
		return;

	case TESLAAMMO:		//548
		WriteSimpleItem(i, "item_cells", f);
		return;

	case SHOTGUNSHELLS:	//619
		WriteSimpleItem(i, "item_shells", f);
		return;

    case TRAPPEDSOUL:	//820
		WriteSimpleItem(i, "item_soul", f);
		return;

/* Misc with an obvious acceptable conversion */
	case AKIMBO:		//829   
		WriteSimpleItem(i, "item_artifact_super_damage", f);
		return;
	
	case DEATHMASK:		//825   
		WriteSimpleItem(i, "item_artifact_invulnerability", f);
		return;
		
	case PLAYERSTART1:	//2522
        
        if (sprite[i].pal == 0)
        WriteSimpleItem(i, "info_player_start", f); // It's a valid simple player start.

        // Otherwise, DM only. But in both cases DM is good.
        WriteSimpleItem(i, "info_player_deathmatch", f);
    	return;
    
    // TWEAKME: It seem there's a flag for DM with the player starts
	case PLAYERSTART2:	//2523  
	case PLAYERSTART3:	//2524  
	case PLAYERSTART4:	//2525  
	case PLAYERSTART5:	//2526  
	case PLAYERSTART6:	//2527  
	case PLAYERSTART7:	//2528  
	case PLAYERSTART8:	//2529
        
        if (sprite[i].pal == 0)
        WriteSimpleItem(i, "info_player_coop", f); // It's a valid simple player start.
        
        else
		WriteSimpleItem(i, "info_player_deathmatch", f); // It's a BB start!

		return;

/* Armor */
	case FIREARMOR:		//2578 // REDISH
		WriteSimpleItem(i, "item_armor2", f);
		return;

	case BODYARMOR:		//2586 // BLUE'ISH
		WriteSimpleItem(i, "item_armor1", f);
		return;

	case SUPERARMOR:	//2594
		WriteSimpleItem(i, "item_armorInv", f);
		return;

	case SPIRITARMOR:	//2602 // UGLY SMILY
		WriteSimpleItem(i, "item_armor4", f);
		return;

	case BASICARMOR:	//2628 // FLAT GREY
		WriteSimpleItem(i, "item_armor0", f);
		return;

/* Powerups */
	case LIFEESSENCE:	//2169
		WriteFlaggedItem(i, "item_health", f, 1); // *ROTTEN*, GOOD
        return;
		
	case DOCTORSBAG:	//519
		WriteSimpleItem(i, "item_artifact_bag", f);
		return;

	case LIFESEED:		//2433
		WriteFlaggedItem(i, "item_health", f, 2); //TESTME: *MEGA*
        return;

    case MEDICINEPOUCH: //822
        WriteSimpleItem(i, "item_health", f);
		return;

    case CRYSTALBALL:	//760
        WriteSimpleItem(i, "item_artifact_crystal", f);
		return;

    case BEASTVISON:	//839
        WriteSimpleItem(i, "item_artifact_vision", f);
		return;

    case CLOAK_INVISIBLE://896
        WriteSimpleItem(i, "item_artifact_invisibility", f);
        return;
    
    case JUMPINGBOOTS:   //827 - TESTME
        WriteSimpleItem(i, "item_artifact_boots", f);
        return;

    case DIVINGSUIT:     //830 - TESTME
        WriteSimpleItem(i, "item_artifact_envirosuit", f);
        return;

    case REFLECTIVESHOT: //2428 - TESTME
        WriteSimpleItem(i, "item_artifact_reflect", f);
        return;
    
    case SHADOWCLOAK:    //768-771 - TESTME
        WriteSimpleItem(i, "item_artifact_shadow", f);
        return;

/* Keys */
    case SKULLKEY:		//2552
        WriteSimpleItem(i, "item_key1", f);
        return;
    
    case EYEKEY:		//2553
        WriteSimpleItem(i, "item_key2", f);
        return;
    
    case FLAMEKEY:		//2554
        WriteSimpleItem(i, "item_key3", f);
        return;
    
    case DAGGERKEY:		//2555
        WriteSimpleItem(i, "item_key4", f);
        return;
    
    case SPIDERKEY:		//2556
        WriteSimpleItem(i, "item_key5", f);
        return;
    
    case MOONKEY:		//2557
        WriteSimpleItem(i, "item_key6", f);
        return;

/* Enemies */
	case RAT:				//1745 actor_rat
        WriteSimpleItem(i, "actor_rat", f);
		return;
        
	case BAT:				//1948
	case CHRYSALIDPOD:		//1792  
	case CHRYSALIDTENTACLE:	//1797
		WriteSimpleItem(i, "monster_dog", f);
		return;
		
	case CULTIST_ACTIVE:	//2820 // 2820 - 2909 CULTISTS
	case CULTIST_INACTIVE:	//2825 // What flag makes it black/red/blue/brown???
		WriteSimpleItem(i, "monster_enforcer", f);
		return;
	
	case RUNNINGZOMBIE:		//1170
	case EMERGINGZOMBIE:	//3054
		WriteSimpleItem(i, "monster_zombie", f);
		return;

	case INNOCENT:			//3798
	case GARGOYLE_ACTIVE:	//1470
    case SHIAL:				//1930
    case CERBERUS:			//2680
    case TCHERNOBOG:		//3140
        return;

/* Trees */
    case TREE1:				//540	 
    case TREE3:             //542
    case TREE4:				//543
    case TREE6:				//545
        WriteSimpleItem(i, "obj_tree", f);
		return;

    case TREE2:				//541
        WriteSimpleItem(i, "obj_tree2", f);
		return;

    case TREE5:				//544
    case TREE8:				//547
        WriteSimpleItem(i, "obj_hedge1", f);
		return;
    	
    case TREE7:				//546 TREE9
    case TREE9:				//599 
        WriteSimpleItem(i, "obj_bush", f);
		return;

/* Atmospheric stuff (i.e. sets the blood "mood" */
    case CROSSTOMBSTONE:	//678
        WriteSimpleItem(i, "obj_tombstn1", f);
		return;

    case OVALTOMBSTONE:		//701
        WriteSimpleItem(i, "obj_tombstn2", f);
		return;

    case SHOVEL:		    //1712
        WriteSimpleItem(i, "obj_shovel", f);
		return;

    case STATUE1:			//536
        WriteSimpleItem(i, "obj_fountain", f);
		return;

    case CRUCIFIEDINNOCENT:	//648
        WriteFlaggedItem(i, "monster_zombie", f, 1); // 1 = crucified
		return;

    case LIGHTNING:		//2090 
        WriteSimpleItem(i, "event_lightning", f);
		return;
    
    case SMALLVIAL:     //517
        WriteSimpleItem(i, "obj_boost", f);
		return;

    case BARREL1:		//907 - Which barrel is gibbable?
    case BARREL2:		//925
        WriteSimpleItem(i, "barrel", f);
		return;

    case FROZENCOW:     //1351
        WriteSimpleItem(i, "obj_beefslab", f);
		return;

    case STOOL:			//284
        WriteSimpleItem(i, "obj_stool", f);
		return;

    case CAULDRON1:     //550
    case CAULDRON2:     //551
        WriteSimpleItem(i, "obj_cauldren", f);
		return;

    case TILTEDCROSS: 	//703
        WriteSimpleItem(i, "obj_cross", f);
		return;

    case FLAMINGTORCH1: //506
    case FLAMINGTORCH2: //507
    case FLAMINGTORCH3: //508
    case FLAMINGTORCH4: //509
        WriteSimpleItem(i, "obj_eflmtrch", f);
		return;

    case SMALLPLANT:    //1010
        WriteSimpleItem(i, "obj_plantgen", f);
		return;

    case POTTEDPLANT:	//1009
        WriteSimpleItem(i, "obj_planetmez", f);
		return;

    case VASEPLANT:     //1013
        WriteSimpleItem(i, "obj_planetrom", f);
		return;

    case LARGE2HANDEDJUG://642
        WriteSimpleItem(i, "obj_pot1", f);
		return;
    
    case LARGEVASE1:	//537
        WriteSimpleItem(i, "obj_pot2", f);
		return;
    
    case LARGEVASE2:	//739
        WriteSimpleItem(i, "obj_pot3l", f);
		return;

    case SEAWEED1:      //664
    case SEAWEED2:      //665
    case SEAWEED3:      //666
    case SEAWEED4:      //667
        WriteSimpleItem(i, "obj_seaweed", f);
		return;
    
    case SKULLSTICK1:   //257
        WriteSimpleItem(i, "obj_skllstk1", f);
		return;

    case SKULLSTICK2:   //259
        WriteSimpleItem(i, "obj_skllstk2", f);
		return;

    case HALFSKULL:     //683 -- TWEAKME: There should be multiple skull types
    case SKULLSIDE:		//807
        WriteSimpleItem(i, "obj_skull", f);
		return;

	default:
	return; // The next was for testing
    WriteSimpleItem(i, "fix_me", f);

	} // switch

} // Blood_To_qBlood
