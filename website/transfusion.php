<?php
	$page_title = "Transfusion";
	$page_topic = "Transfusion";
	$page_cvs = "qblood";
	$page_links = array (
		"Introduction" => array ("Address" => "#introduction-section", "Text" => "Introduction"),
		"GameCode" => array ("Address" => "#gamecode-section", "Text" => "The game code"),
		"BQCC" => array ("Address" => "#bqcc-section", "Text" => "BQCC"),
		"Engine" => array ("Address" => "#engine-section", "Text" => "The engine")
	);

	require ("header.php");
?>

<!-- Introduction -->
<div class="section">
	<h2 id="introduction-section" class="section">Introduction</h2>
	Transfusion is our initial project, using the Quake 1 engine. Originally called
	just "qBlood", it has been renamed to "BloodBath" when we decided to switch to
	the Quake 2 engine in december 2001 and to make our Quake 1 game multiplayer-only.
	The game name has changed a second time to "Transfusion" after we talked with Infogrames
	(now Atari) about the Blood trademark and copyrights.<br />
	Transfusion is a standalone game, but it can also be played as a Quake 1 / QW mod
	until version 1.01 included. If you have one of these old versions and wants to do so,
	please take a look at the manual provided with each release for the detailed
	instructions.<br />
</div>

<!-- The game code -->
<div class="section">
	<h2 id="gamecode-section" class="section">The game code</h2>
	Quake 1 uses "progs.dat" as the	bytecode for storing the game behaviour. This file is
	created thanks to BQCC and our source code, which can be found in the "progs" directory.
	The code is composed of plain text files with a ".qc" or ".qh" suffix. The whole source
	is indented at 4 columns with spaces (no tabs) and quite well commented.<br />
	It incorporates code from <a href="http://www.inside3d.com/frikbot/">FrikBotX</a>.
	You can disable bot support at compile time with the NO_FRIKBOT preprocessor define
	(add "-d NO_FRIKBOT" at the BQCC command line). If you want a bot-free game code for
	some reason, and probably also gain a few FPS in the process, you can rebuild it very
	easily.<br />
</div>

<!-- BQCC -->
<div class="section">
	<h2 id="bqcc-section" class="section">BQCC (Bloody QuakeC Compiler)</h2>
	BQCC is our own QuakeC compiler. Its source code is based on MrElusive's
	QuakeC Compiler v1.4. We choosed MEQCC because of its C-style
	preprocessor which allowed us to build both our NQ game code and our
	QW game code from the same source files. Transfusion no longer supports
	QW, but this feature has survived. By default, BQCC compiles for NQ, but
	the command line switch "-qw" makes it compile for QW, using "qwprogs.src".
	For more details and the list of the other features, take a look at
	the files "readme.txt" and "meqcc.txt" in the bqcc directory.<br />
	There aren't many more things to say about it. It works fine for us,
	so we almost only work on it when there is a bug to fix. Sometimes, an
	additional feature makes it into the code, but it's unusal. As you can
	imagine, the BQCC code is not updated very often. This doesn't mean
	that BQCC code is perfect of course, and so if someone wants to take
	the time to work seriously on it, to do some optimizations or add some
	nice new features, let us know.<br />
	BQCC is known to compile and run on Win32, Linux and OpenBSD. In fact,
	it should work on most operating systems, either as-is or with very few
	changes.<br />
</div>

<!-- The engine -->
<div class="section">
	<h2 id="engine-section" class="section">The engine</h2>
	As mentioned above, Transfusion supported any Quake 1 / QuakeWorld compatible
	engine, up to version 1.01. We have now decided to focus on what a lot of
	people consider to be the best Quake1-based engine out there: DarkPlaces.<br />
	LordHavoc, its creator, offered us to merge the necessary changes
	for Transfusion into DarkPlaces main code, and we accepted. Its source code is
	maintained on the Project Twilight CVS repository at
	<a href="http://icculus.org/">icculus.org</a>, although DarkPlaces has its own
	home page at <a href="http://icculus.org/twilight/darkplaces/">this address</a>.
	Binaries of the Transfusion version can be found in the
	<a href="snapshots.php">snapshots directory</a> in "qblood-bin-*" ZIP files.
	Darkplaces compiles and runs on at least Win32 and Linux.<br />
	So far, we have absolutely no intention to get the DarkPlaces source code into
	our own CVS tree to maintain our own engine. We don't say it will never happen
	though, but it's very unlikely.<br />
</div>

<br />
<br />

<?php
	require ("footer.php");
?>
