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
	about the Blood trademark and copyrights.<br />
	Transfusion is both a mod for Quake and a standalone game. You can use it as any
	Quake mod, or you can use the binaries provided with our releases to launch the
	game from a completely separate directory. You just don't need Quake to play
	Transfusion.<br /> In fact, a lot of versions of the Quake engine will allow you
	to run it like a Quake mod, even without the Quake data since we don't use any
	file from the original game. So if you don't like our customized engine, chances are
	that you can use your favorite one without any major problem. This is not the case of
	id Software official binaries though.<br />
</div>

<!-- The game code -->
<div class="section">
	<h2 id="gamecode-section" class="section">The game code</h2>
	Quake 1 uses either "progs.dat" for NQ or "qwprogs.dat" for QW as the
	bytecode for storing the game behaviour. Each of them can be created with
	BQCC and our source code, which can be found in the "progs" directory. It is
	composed of plain text files with a ".qc" or ".qh" suffix. The whole source is
	indented at 4 columns with spaces (no tabs) and quite well commented.<br />
	It incorporates code from <a href="http://www.inside3d.com/frikbot/">FrikBotX</a>.
	You can disable bot support at compile time with the NO_FRIKBOT preprocessor define
	(add "-d NO_FRIKBOT" at the BQCC command line). We provide this option because of
	stability problems we had previously with the bot code: the game code tended to crash
	easily when players entered the game after bots. This problem is now fixed, but if you
	want a bot-free game code for some reason, and probably also gain a few FPS in the
	process, you can build it very easily.<br />
</div>

<!-- BQCC -->
<div class="section">
	<h2 id="bqcc-section" class="section">BQCC (Bloody QuakeC Compiler)</h2>
	BQCC is our own QuakeC compiler. Its source code is based on MrElusive's
	QuakeC Compiler v1.4. We choosed MEQCC because of its C-style
	preprocessor which allows us to build both our NQ game code and our
	QW game code from the same source files. By default, BQCC compiles
	for NQ. Use the command line switch "-qw" to make it compile for QW.
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
	Since the qBlood Project has decided to switched to Quake 2 engine,
	Transfusion won't really have its own engine. We will provide a customized
	version of the NQ engine though, with a modified key binding menu,
	a updated map list, "bb" as the default game folder, and a few other features.<br />
	Initially, we planned to use the very promising
	<a href="http://twilight.sourceforge.net/">Project Twilight</a> engine as our
	code base. Unfortunately, this project is still under development and hasn't
	yet achieved the stable and mature state that is necessary for us to work
	with it. It is the reason why we finally deciced to set our choice on
	DarkPlaces. LordHavoc, its creator, offered us to merge the necessary changes
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
