Bloody QCC is a modified version of MeQCC (Mr Elusive's QuakeC Compiler) v1.4.
For other informations, take a look at "qcc.txt" and "meqcc.txt", included
into this package.

Changes since MeQCC v1.4:
  * v0.1.1
    - Some code tweaking to make it compile on OpenBSD. Other Unixes should
    work without changes too.
    - ...

  * v0.1.0
    - You can now use several frame lists (up to 4 for now) in a single source
    file if you name them with "$modelname". If you don't name the first
    model, it will be known as "<default>" be the compiler. Here's an example:

        // unnamed -> <default>
        $frame player1 player2
        $frame ...

        $modelname v_fork
        $frame fork_idle
        $frame fork_fire1 fork_fire2

        $modelname v_shot
        $frame shot_idle shot_fire1 shot_fire2
        $frame shot_alt1 shot_alt2

    - bug fix: added checks for the length of the frame names and model names.
    - removed some unused functionalities such as PAK file generation.
    - cleaned some dead code.

  * v0.0.1
    - bug fix: the whitespaces just before the name of a macro were discarded,
    causing errors during the compilation.

  * v0.0.0
    - bug fix: macro parameters can now include parenthesis
    - new command line option (-qw). BQCC then uses the "qwprogs.src" file
    instead of "progs.src", and automatically defines "QUAKEWORLD".


Mathieu Olivier  <elric@planetblood.com>


========== ORIGINAL README.TXT CONTENTS ==========

All additional source code files and modifications to the source code
of the original QuakeC compiler from id Software are licensed under
the terms of the GPL (gnu public license), see the gnu.txt.

The source code of the original QuakeC compiler from id Software
can be found at:
ftp://ftp.idsoftware.com/idstuff/source/qcc.tar.gz or
ftp://ftp.idsoftware.com/idstuff/source/q1tools_gpl.tgz


date: 2000 June 16th

MrE,
