/*
Copyright (C) 2001-2002 Luke Ashdown <kazashi@planetblood.com>

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
#include "shadow.h" // for defines

void ShadowWarrior_To_qBlood (const unsigned short i, FILE *f)
{
    if (sprite[i].picnum == 0) // Don't even waste cycles...
        return;

	switch (sprite[i].picnum)
	{

/* Weapons */
	case SHURIKENS:	        //1793 Weapon # 2
		WriteSimpleItem(i, "weapon_flaregun", f);
        WriteSimpleItem(i, "item_flares", f);
		return;

	case RIOTGUN:		    //1794 Weapon # 3
		WriteSimpleItem(i, "weapon_supershotgun", f);
		return;

	case UZI:		        //1797 Weapon # 4
		WriteSimpleItem(i, "weapon_nailgun", f);
		return;

	case MISSILELAUNCHER:   //1818 Weapon # 5
		WriteSimpleItem(i, "weapon_rocketlauncher", f);
		return;

	case GRENADELAUNCHER:	//1817 Weapon # 6
		WriteFlaggedItem(i, "weapon_grenadelauncher", f, 1);
		return;

	case CALTROPS:		    //1829 Weapon # 6
		WriteSimpleItem(i, "weapon_remote", f);
		return;
		
	case GASBOMB:	        //1808 Weapon # 6
		WriteSimpleItem(i, "weapon_proximity", f);
		return;

	case STICKYBOMB:		//1842 Weapon # 7
		WriteSimpleItem(i, "weapon_supernailgun", f);
		return;

	case RAILGUN:	        //1811 Weapon # 8
		WriteSimpleItem(i, "weapon_lightning", f);
		return;

	case RIPPERHEART:	    //1824 Weapon # 9
		WriteSimpleItem(i, "weapon_voodoodoll", f);
		return;
    
    case GUARDIANHEAD:	    //1814 Weapon # 0
		WriteSimpleItem(i, "weapon_lifeleech", f);
		return;

/* Ammo */
    case UZIBULLETS:	//1799
		WriteSimpleItem(i, "item_spikes", f); 
		return;

	case MISSILES:		//1800
		WriteSimpleItem(i, "item_rockets", f);
		return;

	case RAILSLUGS:		//1812
		WriteSimpleItem(i, "item_cells", f);
		return;

	case RIOTGUNSHELLS:	//1822
		WriteSimpleItem(i, "item_shells", f);
		return;

    case GRENADES:	    //1831
		WriteSimpleItem(i, "item_soul", f);
		return;

/* Misc with an obvious acceptable conversion */
        
	case TOOLKIT:		//1813   
		WriteSimpleItem(i, "item_artifact_super_damage", f);
		return;
	
	case NUKE:		    //1809   
		WriteSimpleItem(i, "item_artifact_invulnerability", f);
		return;
		
	case PLAYERSTART:	//2307 hitag 42 lotag 0
        
        if (sprite[i].hitag == 42)
        {
            WriteSimpleItem(i, "info_player_deathmatch", f);

            if (sprite[i].lotag < 4)
                WriteSimpleItem(i, "info_player_team1", f); // For CTF
            else
                WriteSimpleItem(i, "info_player_team2", f);
        }

        else if (sprite[i].hitag == 48) // co-op
        {
        
        if (sprite[i].lotag == 0)
            WriteSimpleItem(i, "info_player_start", f);
        
        else // sprite[i].lotag > 0
            WriteSimpleItem(i, "info_player_coop", f);
        }

		return;

/* Armor */
	case ARMOR:	//3030 

        if (sprite[i].pal == 19) // Kevlar Armor, 100pts palette 19
            WriteSimpleItem(i, "item_armor1", f);
        
        else // Armor vest, 50pts palette 0
            WriteSimpleItem(i, "item_armorInv", f);
		return;

/* Powerups */
	case MEDPAK:	        //1802
		WriteFlaggedItem(i, "item_health", f, 1); //
        return;
		
	case MEDKIT:	        //1803
		WriteSimpleItem(i, "item_artifact_bag", f);
		return;

    case FORTUNECOOKIE:     //822
        WriteSimpleItem(i, "item_health", f);
		return;

    case HEATSEEKERCARD:	//1819
        WriteSimpleItem(i, "item_artifact_crystal", f);
		return;

    case NIGHTVISION:	    //3031
        WriteSimpleItem(i, "item_artifact_vision", f);
		return;

    case SMOKEBOMB:         //1804
        WriteSimpleItem(i, "item_artifact_invisibility", f);
        return;

    case FLASHBOMB:         //2428
        WriteSimpleItem(i, "item_artifact_reflect", f);
        return;


/* Keys */
    case KEYCARD_BLUE:	//1767
        WriteSimpleItem(i, "item_key1", f);
        return;
    
    case KEYCARD_GREEN:	//1775
        WriteSimpleItem(i, "item_key2", f);
        return;
    
    case KEYCARD_RED:	//1771
        WriteSimpleItem(i, "item_key3", f);
        return;
    
    case KEY_GOLD:		//1765
        WriteSimpleItem(i, "item_key4", f);
        return;
    
    case KEY_SILVER:	//1769
        WriteSimpleItem(i, "item_key5", f);
        return;
    
    case KEY_BRONZE:	//1773
        WriteSimpleItem(i, "item_key6", f);
        return;

    default:
        {
        char buffer[20];
        sprintf(buffer, "fix_me_picture_%d",i);
        WriteSimpleItem(i, buffer, f); // Indicating that the sprite number should be learned.
        }
        return;

	} // switch

} // ShadowWarrior_To_qBlood