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

void Blood_To_qBlood (const unsigned short i, FILE *f)
{
    // Don't waste cycles on BS
    if (sprite[i].picnum == 0 && sprite[i].lotag == 0)
        return;

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
		WriteFlaggedItem(i, "weapon_grenadelauncher", f, 1);
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

    case RANDOMWEAPON: //527
        WriteSimpleItem(i, "weapon_random", f);
		return;

    case ACTIVEPROXIMITY://3444
        WriteSimpleItem(i, "proximity_mine", f);
		return;

/* Ammo */
	case FLARES:		//816
		WriteSimpleItem(i, "item_flares", f);
		return;

	case SHOTGUNSHELLS_MORE://812
		WriteFlaggedItem(i, "item_shells", f, 1);
        return;

	case TOMMYCLIP:		//817
		WriteFlaggedItem(i, "item_spikes", f, 1);
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
            
        
    case TEAMPOLE:      // 753
        switch (sprite[i].lotag)
        {
        case 145: // Blue team base
            WriteSimpleItem(i, "info_player_team1", f);
            WriteSimpleItem(i, "item_flag_team1", f);
            return;

        case 146: // Red team base
            WriteSimpleItem(i, "info_player_team2", f);
            WriteSimpleItem(i, "item_flag_team2", f);
            return;
        }
        
	case AKIMBO:		//829   
		WriteSimpleItem(i, "item_artifact_super_damage", f);
		return;
	
	case DEATHMASK:		//825   
		WriteSimpleItem(i, "item_artifact_invulnerability", f);
		return;
		
	case PLAYERSTART1:	//2522
        
        if (sprite[i].pal == 0)
        WriteSimpleItem(i, "info_player_start", f); // It's a valid simple player start.
        
        else
        WriteSimpleItem(i, "info_player_deathmatch", f);
        WriteSimpleItem(i, "info_player_team1", f);
    	return;
    
    // TWEAKME: It seem there's a flag for DM with the player starts
	case PLAYERSTART2:	//2523  
	case PLAYERSTART3:	//2524  
	case PLAYERSTART4:	//2525  
	
    if (sprite[i].pal == 0)
        WriteSimpleItem(i, "info_player_coop", f); // It's a valid simple player start.
        
        else
		
        {
            WriteSimpleItem(i, "info_player_deathmatch", f); // It's a BB start!
            WriteSimpleItem(i, "info_player_team1", f);
        }
		return;
    
    case PLAYERSTART5:	//2526  
	case PLAYERSTART6:	//2527  
	case PLAYERSTART7:	//2528  
	case PLAYERSTART8:	//2529
        
        if (sprite[i].pal == 0)
        WriteSimpleItem(i, "info_player_coop", f); // It's a valid simple player start.
        
        else
		
        {
            WriteSimpleItem(i, "info_player_deathmatch", f); // It's a BB start!
            WriteSimpleItem(i, "info_player_team2", f);
        }
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
		WriteFlaggedItem(i, "item_health", f, 1);
        return;
		
	case DOCTORSBAG:	//519
		WriteSimpleItem(i, "item_artifact_bag", f);
		return;

	case LIFESEED:		//2433
		WriteFlaggedItem(i, "item_health", f, 2);
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
    case RAT:			   //1745
        WriteSimpleItem(i, "monster_rat", f);
        return;
    
    case BAT:			   //1948
        WriteSimpleItem(i, "monster_bat", f);
        return;
    
    case BONE_EEL:         //1870
        WriteSimpleItem(i, "monster_eel", f);
        return;
    
    case BLACKSPIDER:      //1920  The colors are taken from mapedit
        WriteSimpleItem(i, "monster_blackspider", f);
        return;
    
    case REDSPIDER:        //1925
        WriteSimpleItem(i, "monster_redspider", f);
        return;
    
    case BROWNSPIDER:      //1935
        WriteSimpleItem(i, "monster_brownspider", f);
        return;
    
    case CULTIST_ACTIVE:   //2820  2820 - 2909 CULTISTS pal defines what type
    case CULTIST_INACTIVE: //2825  brown = 0, black = 3, green = 11, red = 12, blue = 13   
    case CUTLIST_PRONE:    //3385
        switch (sprite[i].pal)
        {
        case 0:
            WriteSimpleItem(i, "monster_browncultist", f); // Shotgun & TNT
        return;
        
        case 3:
            WriteSimpleItem(i, "monster_blackcultist", f); // Tommy 
        return;
        
        case 11:
            WriteSimpleItem(i, "monster_greencultist", f); // TNT
        return;
        
        case 12:
            WriteSimpleItem(i, "monster_redcultist", f); // Double barrel, then beast
        return;
        
        case 13:
            WriteSimpleItem(i, "monster_bluecultist", f); // Tesla
        return;

        default:
            WriteSimpleItem(i, "monster_cultist_fixme", f); // I screwed up
        return;
        }

    
    case CHRYSALIDPOD:	   //1792  pal defines what type; 0 for green, 2 for fire
        if (sprite[i].pal == 0)
        WriteSimpleItem(i, "monster_chrysalid", f);

        else
        WriteSimpleItem(i, "monster_firechrysalid", f);
        return;
    
    case CHRYSALIDTENTACLE://1797
        
        if (sprite[i].pal == 0)
        WriteSimpleItem(i, "monster_tentacle", f);

        else
        WriteSimpleItem(i, "monster_firetentacle", f);
        return;
    
    case ZOMBIE:	       //1170
        WriteSimpleItem(i, "monster_earthzombie", f);
        return;
    
    case ZOMBIESLEEPING:   //1209
        WriteSimpleItem(i, "monster_sleepingzombie", f);
        return;

    case ZOMBIEEMERGING:   //3054
        WriteSimpleItem(i, "monster_emergingzombie", f);
        return;
    
    case INNOCENT:		   //3798
        WriteSimpleItem(i, "monster_innocent", f);
        return;
    
    case MIME:             //2400
        WriteSimpleItem(i, "monster_mime", f);
        return;
    
    case HELLHOUND:        //1270
        WriteSimpleItem(i, "monster_hellhound", f);
        return;
    
    case GILBEAST:         //1570
        WriteSimpleItem(i, "monster_gilbeast", f);
        return;
    
    case HAND:             //1980
        WriteSimpleItem(i, "monster_hand", f);
        return;
    
    case GARGOYLE_STATUE:  //1530 pal defines what type 0 for regular, 5 for grey 
        
        if (sprite[i].pal == 0)
        WriteSimpleItem(i, "monster_statuegargoyle", f);

        else
        WriteSimpleItem(i, "monster_statuegreygargoyle", f);

        return;
    
    case GARGOYLE:         //1470  
        if (sprite[i].pal == 0)
        WriteSimpleItem(i, "monster_gargoyle", f);

        else
        WriteSimpleItem(i, "monster_greygargoyle", f);

        return;
    
    case LILCALEB:         //3870
        WriteSimpleItem(i, "monster_lilcaleb", f);
        return;
    
    case BUTCHER:          //1370
        WriteSimpleItem(i, "monster_butcher", f);
        return;
    
    case PHANTASM:         //3060
        WriteSimpleItem(i, "monster_phantasm", f);
        return;
    
    case SHIAL:			   //1930
        WriteSimpleItem(i, "monster_shial", f);
        return;
    
    case CERBERUS:		   //2680
        WriteSimpleItem(i, "monster_cerberus", f);
        return;
    
    case TCHERNOBOG:	   //3140 
        WriteSimpleItem(i, "monster_tchernobog", f);
        return;
    
    case BEAST:            //2960
        WriteSimpleItem(i, "monster_beast", f);
        return;

/* Trees */
    case TREE1:				//540	 
    case TREE3:             //542
    case TREE4:				//543
    case TREE6:				//545
        WriteFlaggedItem(i, "obj_tree", f, 1);
		return;

    case TREE2:				//541
    case TREE10:            //797
        WriteFlaggedItem(i, "obj_tree2", f, 1);
		return;

    case TREE5:				//544
    case TREE8:				//547
        WriteFlaggedItem(i, "obj_hedge1", f, 1);
		return;
    	
    case TREE7:				//546 TREE9
    case TREE9:				//599 
        WriteFlaggedItem(i, "obj_bush1", f, 1);
		return;

/* Lights */
    case FLAME:				// 2101 - 2114 this should catch all the values
    case 2102:
    case 2103:
    case 2104:
    case 2105:
    case 2106:
    case 2107:
    case 2108:
    case 2109:
    case 2110:
    case 2111:
    case 2112:
    case 2113:
    case 2114:
        WriteLight(f, i, 100, "light_flame_small_yellow");
        return;

    case BIGFLAME:			// 3566 - 3579 this should catch all the values
    case 3567:
    case 3568:
    case 3569:
    case 3570:
    case 3571:
    case 3572:
    case 3573:
    case 3574:
    case 3575:
    case 3576:
    case 3577:
    case 3578:
    case 3579:
        WriteLight(f, i, 200, "light_flame_large_yellow");
        return;

    case WOODTORCH:         // 506 - 509
    case 507:
    case 508:
    case 509:
        WriteLight(f, i, 200, "obj_eflmtrch");
        return;

    case BRASSTORCH:		// 570
    case GOLDTORCH:			// 571
        WriteLight(f, i, 200, "obj_cflmtrch");
		return;

/* Atmospheric stuff (i.e. sets the blood "mood" */
    case CROSSTOMBSTONE:	//678
    case WOODCROSSTOMBSTONE://700 
        WriteFlaggedItem(i, "obj_tombstn1", f, 1);
		return;

    case OVALTOMBSTONE:		//701
        WriteFlaggedItem(i, "obj_tombstn2", f, 1);
		return;

    case RIPTOMBSTONE:		//704
        WriteFlaggedItem(i, "obj_tombstn3", f, 1);
		return;

    case SHOVEL:		    //1712
        WriteFlaggedItem(i, "obj_shovel", f, 1);
		return;

    case STATUE1:			//536
        WriteFlaggedItem(i, "obj_fountain", f, 1);
		return;
/*
    case CRUCIFIEDINNOCENT:	//648
        WriteFlaggedItem(i, "monster_zombie", f, 1); // 1 = crucified
		return;
*/
    case LIGHTNING:		//2090 
        WriteSimpleItem(i, "event_lightning", f);
		return;
    
    case SMALLVIAL:     //517
        WriteFlaggedItem(i, "obj_boost", f, 1);
		return;

    case BARREL1:		//907 - Which barrel is gibbable?
    case BARREL2:		//925
        WriteSimpleItem(i, "misc_explobox2", f);
		return;

    case FROZENCOW:     //1351
        WriteFlaggedItem(i, "obj_beefslab", f, 1);
		return;

    case STOOL:			//284
        WriteFlaggedItem(i, "obj_stool", f, 1);
		return;

    case CAULDRON1:     //550
    case CAULDRON2:     //551
        WriteFlaggedItem(i, "obj_cauldren", f, 1);
		return;

    case TILTEDCROSS: 	//703
        WriteFlaggedItem(i, "obj_cross", f, 1);
		return;

    case SMALLPLANT:    //1010
        WriteFlaggedItem(i, "obj_plantgen", f, 1);
		return;

    case POTTEDPLANT:	//1009
        WriteFlaggedItem(i, "obj_plantmez", f, 1);
		return;

    case VASEPLANT:     //1013
        WriteFlaggedItem(i, "obj_plantrom", f, 1);
		return;

    case LARGE2HANDEDJUG://642
        WriteFlaggedItem(i, "obj_pot1", f, 1);
		return;
    
    case LARGEVASE1:	//537
        WriteFlaggedItem(i, "obj_pot2", f, 1);
		return;
    
    case LARGEVASE2:	//739
        WriteFlaggedItem(i, "obj_pot3", f, 1);
		return;

    case SEAWEED1:      //664
    case SEAWEED2:      //665
    case SEAWEED3:      //666
    case SEAWEED4:      //667
        WriteFlaggedItem(i, "obj_seaweed", f, 1);
		return;
    
    case SKULLSTICK1:   //257
        WriteFlaggedItem(i, "obj_skllstk1", f, 1);
		return;

    case SKULLSTICK2:   //259
        WriteFlaggedItem(i, "obj_skllstk2", f, 1);
		return;

    case HALFSKULL:     //683 -- TWEAKME: There should be multiple skull types
    case SKULLSIDE:		//807
        WriteFlaggedItem(i, "obj_skull", f, 1);
		return;

    case CLOSEDBOOK:    //348
        WriteFlaggedItem(i, "obj_bookclos", f, 1);
		return;

    case OPENBOOK:      //349
        WriteFlaggedItem(i, "obj_bookopen", f, 1);
		return;
/*
    case WEB1:	    //1066
    case WEB2:      //1067
    case WEB3:      //1068
    case WEB4:		//1069
    case WEB5:		//1087
    case WEB6:		//1088
    case WEB7:		//1089
        WriteFlaggedItem(i, "obj_webs", f);
        return;
*/

    case SCROLL:    //833
        WriteFlaggedItem(i, "obj_h-book", f, 1);
		return;

    case FLAG:     //3558 - 3565
    case 3559:
    case 3560:
    case 3561:
    case 3562:
    case 3563:
    case 3564:
    case 3565:
        WriteFlaggedItem(i, "obj_flag", f, 1);
        return;

    case BONEPILE: //4075 - CP TEXTURE
        WriteFlaggedItem(i, "obj_bonepile", f, 1);
        return;

    case 0: // Off the wall stuff, no picture 
        switch(sprite[i].lotag) // Cycle through known lotags
        {
        case 0:   // NULL sprite?
            return;

        case 8:   // Teleport target
            WriteSimpleItem(i, "info_teleport_destination", f); // Should change to targetitem
            return;

        case 20:  // Toggle switch
        case 21:  // 1-way switch
        case 22:  // Combination switch
        case 416: // Gib object
        case 417: // Explode object
        case 700: // Trigger gen - E1M5, what is this?
            return;

        case 701: // Waterdrip Gen
        case 702: // Blooddrip Gen - both of these should actually have a visible drip
            WriteSimpleItem(i, "ambient_drip", f);
		    return;

        case 706: // Bubble Gen
        case 707: // Multi-Bubble Gen
            WriteSimpleItem(i, "air_bubbles", f);
		    return;

        default:
            WriteSimpleItem(i, "tell_tim_to_learn_me", f); // This "shouldn't" ever happen
            return;
        }

	default:
	return; // The next was for testing
    WriteSimpleItem(i, "fix_me", f);

	} // switch

} // Blood_To_qBlood

void GetNewTextureName(char* buffer, const unsigned short i)
{
    switch(wall[i].picnum)
    {
        case 77:
            strcpy(buffer, "+lites");
            return;

        case 161:
            strcpy(buffer, "+0xray");
            return;

        case 187:
            strcpy(buffer, "+0skulfd");
            return;

        case 243:
            strcpy(buffer, "*bldbods");
            return;

        case 528:
            strcpy(buffer, "*lava_1");
            return;

        case 530:
            strcpy(buffer, "+lava2");
            return;

        case 716:
            strcpy(buffer, "+0nunskl");
            return;

        case 720:
            strcpy(buffer, "+0gclock");
            return;

        case 854:
            strcpy(buffer, "+0hrtmon");
            return;

        case 997:
            strcpy(buffer, "+water1");
            return;

        case 1029:
            strcpy(buffer, "+water2");
            return;

        case 1046:
            strcpy(buffer, "+0swch_1");
            return;

        case 1048:
            strcpy(buffer, "+0swch_2");
            return;

        case 1070:
            strcpy(buffer, "+0swch_3");
            return;

        case 1072:
            strcpy(buffer, "+0swch_4");
            return;

        case 1074:
            strcpy(buffer, "+0swch_5");
            return;

        case 1076:
            strcpy(buffer, "+0swch_6");
            return;

        case 1078:
            strcpy(buffer, "+0swch_7");
            return;

        case 1100:
            strcpy(buffer, "+0shittk");
            return;

        case 1116:
            strcpy(buffer, "+slime1");
            return;

        case 1120:
            strcpy(buffer, "+slime2");
            return;

        case 1130:
            strcpy(buffer, "*sht_bld");
            return;

        case 1135:
            strcpy(buffer, "+0fluobk");
            return;

        case 1161:
            strcpy(buffer, "+0swch4x");
            return;

        case 2039:
            strcpy(buffer, "+0telprt");
            return;

        case 2178:
            strcpy(buffer, "+0gunpto");
            return;

        case 2183:
            strcpy(buffer, "+0gunptf");
            return;

        case 2288:
            strcpy(buffer, "+0fluo_2");
            return;

        case 2290:
            strcpy(buffer, "+0fluo_3");
            return;

        case 2307:
            strcpy(buffer, "+0gunptx");
            return;

        case 2546:
            strcpy(buffer, "+0jukebx");
            return;

        case 2012:
            strcpy(buffer, "+0congrat");
            return;

        case 2013:
            strcpy(buffer, "+1congrat");
            return;

        case 2915:
            strcpy(buffer, "+water3");
            return;

        default:
            sprintf(buffer,TEXTUREPREFIX "tile%.4d", wall[i].picnum);
            return;  // If it's not on the list, just give it the default name.
    }

}