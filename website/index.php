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
	<a href="http://transfusion.deathmask.net/">our main website</a> for
	general informations about the project.<br />
</div>

<!-- News -->
<div class="section">
	<h2 id="news-section" class="section">News</h2>
	<ul>
		<li>
			<span class="title">August 26, 2004:</span> (by Elric)<br />
			I just discovered today that <a href="http://www.planetblood.com/bloodsource/">the BloodSource website</a>
			seems to have been removed from PlanetBlood.com. Fortunately, I have a backup of the whole site, so I'll
			try to gather and summarize all information related to this project on a brand new
			<a href="bloodsource.php">BloodSource section</a>.<p />
		</li>
		<li>
			<span class="title">August 12, 2004:</span> (by Elric)<br />
			The Transfusion official website has moved! Willis very kindly offered us a webspace on
			his <a href="http://www.deathmask.net/">deathmask</a>. New forums are online and I used that
			opportunity to rewrite the website layout from scratch, so you shouldn't see layout problems
			anymore (holes in borders for example). The new pages are written in PHP, which will allow
			me to make the website evolve quickly hopefully. Go breathe the smell of the napalm in the
			morning at <?php ExplicitURL ("http://transfusion.deathmask.net/"); ?>.<p />
		</li>
		<li>
			<span class="title">August 5, 2004:</span> (by Elric)<br />
			Since the PlanetBlood.com forums are down for the moment, Luke "Kazashi" Ashdown activated
			the SF.net forums so we have a place to talk until the problem is solved. You can access them
			at: <?php ExplicitURL ("http://sourceforge.net/forum/?group_id=22136"); ?><p />
		</li>
	</ul>
</div>

<!-- Useful links -->
<div class="section">
	<h2 id="links-section" class="section">Useful links</h2>
	<ul>
		<li>
			Home page: <?php ExplicitURL ("http://transfusion.deathmask.net/"); ?><p />
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
	We try to make a public release every 6 weeks, including new features,
	new models, and sometimes new maps and sounds. Also, we occasionally make available
	pre-release patches so that intrepid users can test the new features that will be in
	the next official release. Most of the time, these patches consist of a bunch of
	files to add to the last release to upgrade the game to the current development
	version. Pre-release patches are usually quite stable, though not as well tested as
	an official release.<br />
	The best way to follow the day to day development of Transfusion is
	probably to subscribe to our mailing list. Also, the project has a weekly meeting
	on our IRC channel, which starts around 11:00PM (USA East Coast time) every Sunday
	evening. For more details on these topics, see the <a href="#contacts-section">contacts
	section</a> below.<br />
	Of course, contributors	are welcome. Feel free to contact us if you want to help.<br />
</div>

<!-- Contacts -->
<div class="section">
	<h2 id="contacts-section" class="section">Contacts</h2>
	You can find the list of all team members on our main website. Depending on the
	topic, you may want to send a mail directly to one of the 3 project leaders:<br />
	<ul>
		<li>
			<a href="mailto:cruaich@yahoo.com">Christopher "Cruaich" Steele</a>
			(Project Coordinator): any question not purely about art or programming
		</li>
		<li>
			<a href="mailto:kazashi@users.sourceforge.net">Luke "Kazashi" Ashdown</a>
			(Lead Artist): any art / design topic
		</li>
		<li>
			<a href="mailto:timhale@planetblood.com">Timothy "protoplasmatic" Hale</a>
			(Lead Programmer): any programming topic
		</li>
	</ul>
	The Transfusion Project has also a mailing list:
	<a href="mailto:blood-devel@lists.sourceforge.net">blood-devel at lists dot
	sourceforge dot net</a>. It is quite programming oriented, but we don't
	mind other Transfusion related topics. A part of its traffic is made of CVS
	update messages that are automatically send each time our code base is
	updated. All mails are archived, and the "Mailing lists" link at the
	beginning of this page allows you to browse them or to subscribe to the
	blood-devel list.<br />
	Finally, you can join <a href="irc://irc.gamesurge.net/qblood">our IRC
	channel</a> (#qblood on "irc.gamesurge.net") for some interactive
	discussions.<br />
</div>

<br />
<br />

<!-- Disclaimer -->
<div class="section">
	<span id="disclaimer" class="footnotes-title">Disclaimer:</span><br />
	I'm a programmer. I'm not a webmaster or an artist. So this website is ugly.
	And also, I'm French, so this website probably contains several English
	mistakes. I know all that, so please be nice with me about it. I just try to
	make this page light, readable, and useful. That said, constructive feedback
	is always welcome.<br />
</div>

<?php
	require ("footer.php");
?>
