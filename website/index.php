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
	<a href="http://www.planetblood.com/qblood/">our main website</a> for
	general informations about the project.<br />
</div>

<!-- News -->
<div class="section">
	<h2 id="news-section" class="section">News</h2>
	<ul>
		<li>
			<span class="title">April 2, 2003:</span> (by Elric)<br />
			Because of a lack of coders, Awakening is set aside for some time. We now focus on improving
			Transfusion 1. We won't support QuakeWorld anymore, neither the standard Quake engine. We will
			use DarkPlaces exclusively, which should allow us to create a much better and polished game than
			before. And yes, single player campaigns are planned.<br />
			The website will be updated with fresh informations soon. Stay tuned.<p />
		</li>
		<li>
			<span class="title">February 11, 2003:</span> (by Elric)<br />
			I'm happy to announce you the official opening of the <?php ViewCvsURL ("awakening", "Awakening tree"); ?>
			on the CVS repository! I will also upload this website to the repository; so in case someone would
			be interested in getting the couple of PHP files I use, go visit the CVS module
			"<?php ViewCvsURL ("website", "website"); ?>".<p />
		</li>
		<li>
			<span class="title">January 21, 2003:</span> (by Elric)<br />
			The SDK for Transfusion 1.01 has finally been uploaded. It is available in 2 formats:
			a Win32 installer and a Linux ZIP archive. You can get it from the "Files" page, as usual.<p />
		</li>
		<li>
			<span class="title">January 13, 2003:</span> (by Elric)<br />
			The 1.01 patch for Transfusion is out! Follow the "Files" link above to get it.<p />
		</li>
	</ul>
</div>

<!-- Useful links -->
<div class="section">
	<h2 id="links-section" class="section">Useful links</h2>
	<ul>
		<li>
			Home page: <?php ExplicitURL ("http://www.planetblood.com/qblood/"); ?><p />
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
			<a href="mailto:iliveagain@planetblood.com">Joe "ILiveAgain" Volante</a>
			(Project Coordinator): any question not purely about art or programming
		</li>
		<li>
			<a href="mailto:kazashi@users.sourceforge.net">Luke "Kazashi" Ashdown</a>
			(Lead Artist): any art / design topic
		</li>
		<li>
			<a href="mailto:molivier@users.sourceforge.net">Mathieu "Elric" Olivier</a>
			(Lead Programmer): any programming topic and the websites
		</li>
	</ul>
	The Transfusion Project has also a mailing list:
	<a href="mailto:blood-devel@lists.sourceforge.net">blood-devel at lists dot
	sourceforge dot net</a>. It is quite programming oriented, but we don't
	mind other qBlood related topics. A part of its traffic is made of CVS
	update messages that are automatically send each time our code base is
	updated. All mails are archived, and the "Mailing lists" link at the
	beginning of this page allows you to browse them or to subscribe to the
	blood-devel list.<br />
	Finally, you can join <a href="irc://irc.gamesnet.net/qblood">our IRC
	channel</a> (#qblood on "irc.gamesnet.net") for some interactive
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
