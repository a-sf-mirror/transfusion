<?php
	$page_title = "Transfusion II: Caleb's Awakening";
	$page_topic = "Transfusion II: Caleb's Awakening";
	$page_vcs = "awakening";
	$page_links = array (
		"Introduction" => array ("Address" => "#introduction-section", "Text" => "Introduction")
	);

	require ("header.php");
?>

<!-- Introduction -->
<div class="section">
	<h2 id="introduction-section" class="section">Introduction</h2>
	Transfusion II: Caleb's Awakening should have been our next project.
	Its development started in January 2003, after Transfusion first official
	release, but was quickly frozen (mainly because of a lack of coders).
	It has eventually been abandonned.<br />
	Unlike Transfusion, Caleb's Awakening was based on the Quake 2 engine.
	The main goal was to remake the single player part of Blood, although
	support for the same multiplayer modes than those available in Transfusion
	was also planned.<br />
	The team finally decided to bring the necessary changes to Transfusion
	for the single player support instead of restarting a complete development
	with another engine.<br />
	<br />
	The <?php ViewVcsUrl ("awakening", "awakening directory"); ?> of our SVN 
	repository contains an unfinished merged version of Quake 2 and Quake 2 CTF
	game codes, and an improved version of the pcx2wal tool.<br />
</div>

<br />
<br />

<?php
	require ("footer.php");
?>
