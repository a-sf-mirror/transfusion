<?php
	$page_title = "The ReBUILD Project";
	$page_topic = "The ReBUILD Project";
	$page_cvs = "rebuild";
	$page_links = array (
		"Introduction" => array ("Address" => "#introduction-section", "Text" => "Introduction"),
		"Downloads" => array ("Address" => "#downloads-section", "Text" => "Downloads"),
		"File formats" => array ("Address" => "#fileformats-section", "Text" => "File formats")
	);

	require ("header.php");
?>

<!-- Introduction -->
<div class="section">
	<h2 id="introduction-section" class="section">Introduction</h2>
	ReBUILD is a project founded in August 2000 by Timothy Hale and Mathieu Olivier,
	with the valuable help of Greg Enright of <a href="bloodsource.php">the BloodSource
	campaign</a>. Those 3 fans of <a href="http://blood.lith.com/">Monolith Productions'
	3D-shooter Blood</a> wanted to revitalize/modernize the editing tools for
	<a href="http://www.advsys.net/ken/build.htm">BUILD</a>, the engine on which Blood
	is based, and to gather <a href="#fileformats-section">technical
	informations</a> about Blood, so people would have a set of good tools to work with
	when the Blood source code would finally be released.<br />
	<br />
	At this time, Ken Silverman had just released the source code of his BUILD engine,
	and so many people thought the Blood source code release was a matter of weeks.
	Unfortunately, this release didn't happen. Timothy, Mathieu and Greg then decided to
	move on and founded qBlood (now known as
	<a href="http://transfusion.deathmask.net/">the Transfusion Project</a>) in March 2001.
	As a consequence, there isn't much activity on ReBUILD nowadays, although the project
	isn't officially dead. If you want to get support or information about the ReBUILD
	Project, contact Timothy Hale or Mathieu Olivier via the Transfusion Project.<br />
</div>

<!-- Downloads -->
<div class="section">
	<h2 id="downloads-section" class="section">Downloads</h2>
	The utilities marked with an empty dot are now maintained in the Transfusion project's
	CVS tree and are the only ones that are really supported. Their source codes and binaries
	can be found <a href="snapshots.php#rebuild-section">here</a>. Below is the complete list
	of the utilities the ReBUILD Project has created or modified:<br />
	<br />
	<span class="boldtitle">Tools released under the
	<a href="http://www.gnu.org/copyleft/gpl.html">GNU GPL</a></span> (source code and Win32
	binaries are in the ZIP files)<br />
	<ul>
		<li style="list-style-type: circle;">
			<a href="snapshots.php#rebuild-section">The ART tools</a> - 2 tools and their
			documentation to convert ART files into a series of TGA pictures, and the opposite
		</li>
		<li style="list-style-type: circle;">
			<a href="snapshots.php#rebuild-section">RFF</a> - Allows you to read RFF files
			and to extract their contents. Supports Version 2.0 and 3.1 RFF files
		</li>
		<li style="list-style-type: circle;">
			<a href="snapshots.php#rebuild-section">Sfx2Wav</a> - Convert a SFX/RAW pair into
			a WAV file
		</li>
		<li style="list-style-type: circle;">
			<a href="snapshots.php#rebuild-section">Blud2B</a> - This will take an encrypted
			Blood map, and convert it to a plain BUILD map
		</li>
		<li>
			<a href="files/loader.zip">Blood Loader</a> - Blood launcher with a nice GUI and
			many options
		</li>
		<li>
			<a href="files/wart2tga.zip">Windows art to tga converter</a> - Win32 GUI version
			of Art2Tga
		</li>
		<li>
			<a href="files/winbarf.zip">WinBarf</a> - Win32 GUI version of RFF
		</li>
		<li>
			<a href="files/xtract.zip">Xtract</a> - Art and map extraction utility for GRP
			packages. Closed source program "dukeconv" included (BUILD->Quake map converter)
		</li>
		<li>
			<a href="files/episodes.zip">Episodes</a> - INI file generator for Blood
		</li>
	</ul>
	<br />
	<span class="boldtitle">Tools released under the
	<a href="http://www.advsys.net/ken/build.htm">BUILD</a> license</span> (source code and Win32
	binaries are in the ZIP files)<br />
	<ul>
		<li>
			<a href="files/ktools.zip">KTools</a> - Kextract and Kgroup Win32 binaries.
			Handle BUILD group files (*.GRP)
		</li>
		<li>
			<a href="files/convmap.zip">BUILD map converters</a> - converts between
			map version 5, 6 and 7
		</li>
	</ul>
	<span class="boldtitle">Other goodies</span> (no source code here)<br />
	<ul>
		<li>
			<a href="files/palette.zip">palette.dat (zipped)</a> - Blood's palette file.
			Some BUILD or Blood utilities out there require it
		</li>
		<li>
			<a href="files/wtga2art.zip">Windows tga to art converter</a> - Win32 GUI version
			of Tga2Art. You need the animdata.ini file if you intend to use animations.
			Create your own art files!
		</li>
		<li>
			<a href="files/wsfx2wav.zip">Windows Sfx2Wav utility</a> - Win32 GUI version of
			Sfx2Wav. You need to have all your raw/sfx files in the same directory.
			Single file selection only with this release
		</li>
	</ul>
</div>

<!-- File formats -->
<div class="section">
	<h2 id="fileformats-section" class="section">File formats</h2>
	One of the goals of the ReBUILD project is to gather technical information about the file formats
	used by Blood. Some of them are standard BUILD formats and are well known and documented, but for the
	most part, the file formats have to be guessed from reverse-engineering technics and experiments.
	The contact <a href="bloodsource.php">the BloodSource campaign</a> once maintained with
	<a href="http://www.saettler.com/">Matt Saettler</a>, one of the Blood developers, proved extremely
	valuable here since Matt provided us with several important information regarding several of those
	formats.<br />
	<br />

	<!-- ART files and PALETTE.DAT -->
	<span class="boldtitle">The ART files and PALETTE.DAT:</span><br />
	Blood uses the BUILD standard ART format for its picture packages. Blood's color palette, stored
	in PALETTE.DAT, is also in a standard BUILD format. The complete documentation of both formats
	is available in the source code release of the <a href="http://www.advsys.net/ken/build.htm">BUILD
	engine</a>, mostly in BUILDINF.TXT.<br />
	<br />

	<!-- DEM files -->
	<span class="boldtitle">The DEM files:</span><br />
	This is the documentation provided on the .dem format that Blood uses for it's demos. It came
	with 1.21 One Whole Unit.<br />
	<pre>
	Blood's .DEM file format (1.10 and above)
	Copyright 1997, Monolith Productions.  All Rights Reserved.

	08/20/97

	THIS IS ALL SUBJECT TO CHANGE.

	===============================================================================
	WARNING!  WARNING!  WARNING!  WARNING!  WARNING!  WARNING!  WARNING!  WARNING!
	===============================================================================

	The INPUT structure couuld change, causing the demos to be invalid.

	More often, however, AI or weapon changes cause the recorded actions to
	become 'not the intended action'.

	For example, 1.02 demos that use the Voo-Doo alt-fire were 'broken' in 1.10
	when the alt-fire VooDoo action was changed.  Monsters that were previously
	killed were now still alive.  This could cause the player to run into them
	instead of proceeding safely to the next area, etc.  All further actions
	would then be modified as the recorded re-actions of the player are now blindly
	responsding to events that don't happen.  The usual result is early death.

	===============================================================================

	File format:

	DEMOHEAHDER
	INPUT[nInputCount][nNetPlayers] // set of INPUT for each of the players.

	===============================================================================

	DEMOHEADER Structure definition

	struct DEMOHEADER
	{
	    DWORD           signature;          //'DEM\0x1a'
	    BLOODVERSION    nVersion;           // version of Blood that created the demo
	    long            nBuild;             // build of Blood that created the demo
	                                        // builds are:
	                                        // SW, SWCD:   2
	                                        // Registered: 3
	                                        // Plasma Pak: 4
	    long    nInputCount;                // number of INPUT structures recorded
	    int     nNetPlayers;                // number of players recorded
	    short   nMyConnectIndex;            // the ID of the player

	    short   nConnectHead;               // index into connectPoints of Player
	    short   connectPoints[MAXPLAYERS];  // IDs of players

	    GAMEOPTIONS gameOptions;            // game options used for level
	};


	===============================================================================

	GAMEOPTIONS Structure definition

	struct GAMEOPTIONS
	{
	    GAMETYPE        nGameType;
	    DIFFICULTY      nDifficulty;
	    int             nEpisode;

	    int             nLevel;
	    char            zLevelName[ _MAX_PATH ];
	    char            zLevelSong[ _MAX_PATH ];
	    int             nTrackNumber;
	    char            szSaveGameName[kMaxFileKeyLen];
	    char            szUserGameName[kMaxFileKeyLen];

	    short           nSaveGameSlot;
	    int             picEntry;
	    ulong           uMapCRC;
	    MONSTERSETTINGS nMonsterSettings;

	    ulong           uGameFlags;

	    // net game options/data only
	    ulong           uNetGameFlags;

	    WEAPONSETTINGS  nWeaponSettings;
	    ITEMSETTINGS    nItemSettings;
	    RESPAWNSETTINGS nRespawnSettings;
	    TEAMSETTINGS    nTeamSettings;  // team and cooperative

	    int             nMonsterRespawnTime;
	    int             nWeaponRespawnTime;
	    int             nItemRespawnTime;
	    int             nSpecialRespawnTime;
	};


	===============================================================================

	INPUT Structure definition

	/***********************************************************************
	 * BUTTONFLAGS
	 *
	 * This structure is packetized and sent to other players. These keys
	 * are used frequently during the game. The purpose for separating and
	 * keeping this structure small, is to limit the amount of transferred
	 * data.
	 *
	 **********************************************************************/
	union BUTTONFLAGS
	{
	    char    byte;
	    struct
	    {
	        unsigned jump       : 1;    // player is jumping (once!)
	        unsigned crouch     : 1;    // player is crouching

	        unsigned shoot      : 1;    // normal attack
	        unsigned shoot2     : 1;    // alternate attack
	        unsigned lookUp     : 1;    // > glance or aim up/down
	        unsigned lookDown   : 1;    // > if glancing then lookCenter is set
	    };
	};


	union KEYFLAGS
	{
	    short   word;
	    struct
	    {
	        unsigned action         : 1;    // open or activate

	        unsigned jab            : 1;    // quick attack
	        unsigned prevItem       : 1;    // next inventory item
	        unsigned nextItem       : 1;    // prev inventory item
	        unsigned useItem        : 1;    // use inventory item
	        unsigned prevWeapon     : 1;    // prev useable weapon
	        unsigned nextWeapon     : 1;    // next useable weapon

	        unsigned holsterWeapon  : 1;    // holster current weapon

	        unsigned lookCenter     : 1;    // used for lookUp/lookDown only
	        unsigned lookLeft       : 1;    // > glance or aim up/down
	        unsigned lookRight      : 1;    // > if glancing then lookCenter is set
	        unsigned spin180        : 1;    // spin 180 degrees

	        unsigned pause          : 1;    // pause the game
	        unsigned quit           : 1;    // quit the game
	        unsigned restart        : 1;    // restart the level
	    };
	};

	union USEFLAGS
	{
	    char    byte;
	    struct
	    {
	        unsigned useBeastVision : 1;
	        unsigned useCrystalBall : 1;

	        unsigned useJumpBoots   : 1;
	        unsigned useMedKit      : 1;
	    };
	};

	union SYNCFLAGS
	{
	    char    byte;

	    struct
	    {
	        unsigned buttonChange   : 1;
	        unsigned keyChange      : 1;
	        unsigned useChange      : 1;
	        unsigned weaponChange   : 1;

	        unsigned mlookChange    : 1;
	        unsigned run            : 1;    // player is running
	    };
	};

	struct INPUT
	{
	    SYNCFLAGS   syncFlags;  // always sent: indicates optional fields

	    schar       forward;    // always sent
	    sshort      turn;       // always sent
	    schar       strafe;     // always sent

	    // optional fields
	    BUTTONFLAGS buttonFlags;
	    KEYFLAGS    keyFlags;

	    USEFLAGS    useFlags;
	    uchar       newWeapon;  // sent as 0 every frame unless changed
	    schar       mlook;
	};</pre>
	<br />

	<!-- MAP files -->
	<span class="boldtitle">The MAP files:</span><br />
	We started to study this complicated format to do a Blood to BUILD map
	converter, and we stopped working on it as soon as we got what we want: a
	converter that works. In other words, we don't know the Blood MAP format well,
	we just know enough of it.<br />
	Our converter, BLUD2B, is more a series of hacks than a real tool. It's full
	of arbitrary constants and little tricks to do the job. For example, it does not
	know how to compute the encryption / decryption keys a map uses, but we found
	a way to guess them! (it's easily doable thanks to the simplicity of the
	encryption method and the fact that BUILD map data are mostly zeros).<br />
	If you're interested by this format, take a look at BLUD2B source code and the
	following email by Matt Saettler. None of them contain "The Truth" about the
	MAP format, but they should help you to figure it out.<br />
	<pre>
	Typical header with signature.

	Header has version. Version 6.03 is unencrypted. Version 7.0 is encrypted
	(same xor encryption algorithm used in RFF file format).

	After header comes (possible encrypted) Information structure. This contains
	global information like map revision count, 'start' x,y,z, number of walls,
	sectors, etc. This is the same for 6.03 and 7.0
	CryptKey: 0x7474614d

	Version 7.0 then has extra information. Info includes copyright. Not sure
	what else.
	CryptKey: numwalls

	Next comes skyofsetts (for moving skys)
	CryptKey: buffer size

	The Build info and the 'Extra' information. The Extra info is where the
	blood-specific information is stored. This info is kept in an array by
	type. The 'extra' member of the base build structure is the array offset
	into the extra array. If zero, then there is no extra information. see
	mapedit for access to what the info is; mapedit allows editing of all this
	structure).


	all valid sectors
	Sector
	CryptKey: map Rev * sizeof(SECTOR) (I was sneaky, using maprev.. So it
	changes each time you save it....)
	If extra:
	Xsector
	CryptKey: Unencrypted

	All valid walls
	wall
	CryptKey: map Rev * sizeof(SECTOR) | 0x7474614d
	if extra:
	xwall
	CryptKey: Unencrypted

	all valid sprites
	sprite
	CryptKey: map Rev * sizeof(SPRITE) | 0x7474614d
	if extra:
	xsprite
	CryptKey: UnEncrypted

	Last is a CRC of the entire file (to detect modifications)


	If you are converting to basic Build files, you can just read and ignore the
	'extra' information.</pre>
	<br />

	<!-- RFF files -->
	<span class="boldtitle">The RFF files:</span><br />
	The following mail from Matt Saettler is a good summary of what we know about RFF files.<br />
	<pre>
	The file format is a basic multi-file container. As such, it has a header
	for version #, etc, a list of files in a 'directory' and the actual file data.

	For the initial shareware release, the file data was just copied into the RFF
	file. After we noticed that there were readily available hacking programs
	available to extract file by type (by recognizing the signature bytes for
	that file format (for example, WAV files), I decided to encrypt the start of
	each file to prevent this from happening. Also, the dictionary is encrypted.

	There were two versions of BARF compiled from the same source. one for
	external release and one for internal only release. The internal release
	allowed the creation of encrypted files and marked the RFF as 'Monolith
	approved'. I believe that when a 'non-approved' map file was run, the
	monolith logo showed in the top right of the screen.

	The internal release also allows full extraction of all files. The external
	version only extracts files that we thought were likely to be modified by
	MOD makers.

	The first thing in the file is the header block. It consists of a signature
	block, version #, # of files and offset to the first 'directory' structure.
	There might be some other stuff in there. It is never encrypted.

	The directory block is an array of structures. I don't believe that
	sub-directories were allowed. The structure contains the information about
	each file. Info will be: Name, extension, flags, fileoffset, filesize, time
	(for update). There might be a few other things in the structure.

	Encryption. The older RFF file format did not use encryption. I believe that
	this was only in the shareware, but I'm not sure. It might have actually been
	used in the shipping Blood. Later version (and certainly all patches) used
	the encryption. The encryption is a simple XOR of each byte with a moving
	value starting at a given starting value. The starting value was variable
	based on file offset (I think). Getting this starting value will be the tough
	part.

	To reverse engineer the starting 'key', create a simple RFF file with a
	single file named AAAAAA.AAA. This sequence should be easy to find since
	there will be an increasing sequence of bytes in the file. You should be able
	to figure out the starting XOR from what the sequence is at.

	The first 256 (or maybe 255) bytes of files were also compressed (based on a
	flag in the directory struct). The key was probably constant to allow moving
	the file without having to re-crypt the data. Use the same trick to reverse
	engineer to find the starting key. Use a file with all zeros for easiest
	finding.

	Here is the crypt routine that I've often used. I'm pretty sure this is what
	I also used in Blood. (note this this is a two-way routine; it encrypts and
	decrypts; the beauty of XOR...)

	void crypt(unsigned char *buf, int len, long startpos)
	{
		long curpos=startpos;
		int i;
		for(i=0;i&lt;len;i++)
		{
			buf[i] ^= (unsigned char) ((unsigned short) curpos/2);
			curpos++;
		}
	}

	Barf is driven by a 'script'-like language that defines the files to be
	included and their file flags, etc. This file also allows the generation of
	an .H file (hmm.. the files also have an ID that is used in a #define, so the
	id is probably in the directory structure).

	Barf will generate a script file from an RFF file. But the external version
	will not extract the protected files...I don't remember which files we
	considered 'protected'.... It should be obvious by what doesn't get
	extracted.... :)</pre>

	From our experiments, Matt were partially wrong about encryption and compression.
	First, we have never found any clue of a compression scheme in any RFF file. Most files
	are indeed partially encrypted, except in the RFF 2.0 format (the version of RFF format
	used in shareware Blood). A flag in the file properties controls whether or not a
	particular file is encrypted. When it is the case, only the 256 first bytes are encrypted,
	using the 8 lowest bits of the file offset.<br />
	If you're a developer and are interested in having the exact structures of the RFF format,
	take a look at the source code of our RFF utility. The code is well commented and although
	some parts of the RFF format are still obscure to us, we know it enough to be able to extract
	any file from any RFF package.<br />
	<br />

	<!-- SFX and RAW files -->
	<span class="boldtitle">The SFX and RAW files:</span><br />
	In Blood, each sound is stored in 2 files: a SFX file, containing the sound properties (such as
	volume and format), and a RAW file that contains the actual sound data.<br />
	For an unknown reason, Blood's BARF utility dumps the SFX file format when you use the "-r"
	option ("Extract Script file"). Here is the contents of the file it dumps:<br />
	<pre>
	// Resource script file generated by BARF script extractor
	// Copyright 1997, Monolith Productions.  All Rights Reserved

	 // SFX data format
	 //    int    relVol;      volume, 0-255
	 //    int    pitch;       pitch change (fixed point)
	 //    int    pitchrange;  range of random pitch (fixed point)
	 //    int    format;      format of audio 1=11025 5=22050
	 //    int    loopStart;   loop position (-1 means no looping)
	 //    char   rawName[9];  name of RAW resource

	// end of generated file</pre>
	Note that "rawName" is 0-terminated and that if it is shorter than 8 bytes, the file will actually
	end right after it finished. It means a valid SFX file is always between 22 and 29 bytes long.<br />
	Although "format" is always 1 or 5 in Blood, Matt Saettler gave us the list of all possible
	formats. Here it is, copied from the course code of our Sfx2Wav utility:<br />
	<pre>
	typedef enum
	{
	    SND_FMT_DEFAULT,  // 0
	    SND_FMT_1M08,     // 1
	    SND_FMT_1S08,     // 2
	    SND_FMT_1M16,     // 3
	    SND_FMT_1S16,     // 4
	    SND_FMT_2M08,     // 5
	    SND_FMT_2S08,     // 6
	    SND_FMT_2M16,     // 7
	    SND_FMT_2S16,     // 8
	    SND_FMT_4M08,     // 9
	    SND_FMT_4S08,     // 10
	    SND_FMT_4M16,     // 11
	    SND_FMT_4S16      // 12
	} SoundFormat_t;</pre>
	As you can see, Blood sounds are all 8 bit mono sounds, either at 11025Hz (SND_FMT_1M08) or
	22050Hz (SND_FMT_2M08)<br />

</div>

<br />
<br />

<?php
	require ("footer.php");
?>
