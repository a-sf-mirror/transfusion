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
			<span class="title">February 24, 2004:</span> (by Elric)<br />
			I am finally out of the project for good. Many thanks to all the guys who contributed to
			Transfusion, or supported it one way or another. It has been a great experience to me.<p />
		</li>
		<li>
			<span class="title">January 22, 2004:</span> (by Elric)<br />
			Some code and binary snapshots have been uploaded. We try to cook a new release for ASAP.
			Stay tuned and pray: it may well be the last release this project will ever produce.<p />
		</li>
		<li>
			<span class="title">November 2, 2003:</span> (by Tim)<br/>
			Finally figuring out how to work some of the stuff on the site.<br/>
			It's good to be working with Mathieu again, albiet a little sad since he's inactive these days.<br/>
			My main desire for joining up (again) was to motivate the great 3D animators/artists that have been 
			with the project through it's great period of inactivity.  I seriously thought that the project
			would have ended if not for their persistance.  Thanks Luke and Chris!<br/>
			I like to do updates every week, so I figure I'll start things off today.<br/>
			<br/>
			<b>The good stuff for this week as follows:</b><br/>
			Blood splattering was lost for some reason. 
			Put it back, and made it do a nifty splattering confetti style effect.<br/>
			Initial screen shaking code is in place.  Now to implement it for beast's stomp, etc.<br/>
			Monsters can be disabled via nomonsters cvar now.  Works like nodudes.<br/>
			A lot of Single Player specific code tweaks added.
			I.E. keys not spawning in blood bath, all doors open, keys respawning in 15 seconds in coop games,
			life leech sentries attacking monsters in SP and coop, etc.<br/>
			Of course all the monster related code is SP specific.<br/>
			The most notable update this week is that monsters no longer stand around when being attacked.  
			They "wake up" and wake up nearby monsters that can see you.<br/>
			Stepping on monsters hurts them, and can slowly kill them.<br/>
			Lots of code cleaning and fat trimming. Many bug/behavior fixes for the monsters.<p/>
		</li>
		<li>
			<span class="title">October 13, 2003:</span> (by Elric)<br />
			I am officially resigning from my Lead Programmer position today. Timothy Hale, another co-founder
			of this project, will be taking up the chair in my place.<p />
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
