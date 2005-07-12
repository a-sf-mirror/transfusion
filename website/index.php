<?php
	$page_title = "Development Page";
	$page_topic = "The Transfusion Project";
	$page_links = array (
		"About" => array ("Address" => "#about-section", "Text" => "About this page"),
		"News" => array ("Address" => "#news-section", "Text" => "News"),
		"Links" => array ("Address" => "#links-section", "Text" => "Useful links"),
		"Devel" => array ("Address" => "#devel-section", "Text" => "The development process"),
		"Contacts" => array ("Address" => "#contacts-section", "Text" => "Contacts")
	);

	require ("header.php");
?>

<!-- About -->
<div class="section">
	<h2 id="about-section" class="section">About this page</h2>
	This website is the home of the Transfusion Project development. Please, go to
	<a href="http://www.transfusion-game.com/">our main website</a> for
	general information about the project.<br />
</div>

<!-- News -->
<div class="section">
	<h2 id="news-section" class="section">News</h2>
	<ul>
		<li>
			<span class="title">July 12, 2005:</span> (by Elric)<br />
			GroupSPR has been updated to version 1.0, with support for DarkPlaces' SPR32 format.<p />
		</li>
		<li>
			<span class="title">April 24, 2005:</span> (by Elric)<br />
			The source code of Map2Map, our BUILD to Quake map converter has been added to the CVS repository, along
			with a new version of the GroupSPR tool. Both are <?php ViewCvsURL ("qblood/tools", "in the \"tools\" sub-directory"); ?>
			of our source tree.<br />
			The update of the BloodSource and ReBUILD pages I mentioned in the previous news have actually been completed
			months ago. I simply forgot to post the news.<p />
		</li>
		<li>
			<span class="title">September 9, 2004:</span> (by Elric)<br />
			In case you missed <a href="http://sourceforge.net/mailarchive/forum.php?thread_id=5531111&amp;forum_id=2317">the
			announcement</a>, Transfusion 1.1-beta3 is out. You can get it from
			<a href="http://sourceforge.net/project/showfiles.php?group_id=22136">the files page</a>.<br />
			I'm currently updating the <a href="bloodsource.php">BloodSource</a> and <a href="rebuild.php">ReBUILD</a>
			pages with additional information from my backup of the now defunct BloodSource home page.
			More to come very soon.<p />
		</li>
		<li>
			<span class="title">August 26, 2004:</span> (by Elric)<br />
			I just discovered today that <a href="http://www.planetblood.com/bloodsource/">the BloodSource website</a>
			seems to have been removed from PlanetBlood.com. Fortunately, I have a backup of the whole site, so I'll
			try to gather and summarize all information related to this project on a brand new
			<a href="bloodsource.php">BloodSource section</a>.<p />
		</li>
	</ul>
</div>

<!-- Useful links -->
<div class="section">
	<h2 id="links-section" class="section">Useful links</h2>
	<ul>
		<li>
			Home page: <?php ExplicitURL ("http://www.transfusion-game.com/"); ?><p />
		</li>
		<li>
			SourceForge page: <?php ExplicitURL ("http://sourceforge.net/projects/blood/"); ?><p />
		</li>
		<li>
			Mailing lists: <?php ExplicitURL ("http://sourceforge.net/mail/?group_id=22136"); ?><p />
		</li>
		<li>
			CVS repository: <?php ExplicitURL ("http://sourceforge.net/cvs/?group_id=22136"); ?><p />
		</li>
		<li>
			DarkPlaces home page: <?php ExplicitURL ("http://icculus.org/twilight/darkplaces/"); ?><p />
		</li>
	</ul>
</div>

<!-- The development process -->
<div class="section">
	<h2 id="devel-section" class="section">The development process</h2>
	The Transfusion Project has a very open development process. All our code is available
	on CVS and in code snapshots updated regularly. Our snapshots are named according
	to this scheme: "&lt;<i>CVS module name</i>&gt;-&lt;<i>type</i>&gt;-&lt;<i>date</i>&gt;.zip".
	The date is either a version number or a 6 digits number (year/month/day).
	For instance, "qblood-progs-020523.zip" contains the "progs" (the game code) from
	the CVS module "qblood" (Transfusion), made the "020523" (May 23, 2002). The
	type of the code snapshots is just "CVS".<br />
	Of course, contributors	are welcome. Feel free to contact us if you want to help.<br />
</div>

<!-- Contacts -->
<div class="section">
	<h2 id="contacts-section" class="section">Contacts</h2>
	You can find the list of all team members on our main website.<br />
	The Transfusion Project has also a mailing list:
	<a href="mailto:blood-devel (at) lists.sourceforge.net">blood-devel at lists dot
	sourceforge dot net</a>. It is quite programming oriented, but we don't
	mind other Transfusion related topics. A part of its traffic is made of CVS
	update messages that are automatically send each time our code base is
	updated. All mails are archived, and the "Mailing lists" link at the
	beginning of this page allows you to browse them or to subscribe to the
	blood-devel list.<br />
	Finally, you can join <a href="irc://irc.anynet.org/transfusion">our IRC
	channel</a> (#transfusion on "irc.anynet.org") for some interactive
	discussions.<br />
</div>

<br />
<br />

<?php
	require ("footer.php");
?>
