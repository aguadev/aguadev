#!perl

# We are miniperl, building extensions
# Reset @INC completely, adding the directories we need, and removing the
# installed directories (which we don't need to read, and may confuse us)
@INC = (q /mnt/repos/private/syoung/aguadev/apps/perl/build/perl-5.18.2/cpan/AutoLoader/lib ,
        q /mnt/repos/private/syoung/aguadev/apps/perl/build/perl-5.18.2/dist/Carp/lib ,
        q /mnt/repos/private/syoung/aguadev/apps/perl/build/perl-5.18.2/dist/Cwd ,
        q /mnt/repos/private/syoung/aguadev/apps/perl/build/perl-5.18.2/dist/Cwd/lib ,
        q /mnt/repos/private/syoung/aguadev/apps/perl/build/perl-5.18.2/dist/ExtUtils-Command/lib ,
        q /mnt/repos/private/syoung/aguadev/apps/perl/build/perl-5.18.2/dist/ExtUtils-Install/lib ,
        q /mnt/repos/private/syoung/aguadev/apps/perl/build/perl-5.18.2/cpan/ExtUtils-MakeMaker/lib ,
        q /mnt/repos/private/syoung/aguadev/apps/perl/build/perl-5.18.2/dist/ExtUtils-Manifest/lib ,
        q /mnt/repos/private/syoung/aguadev/apps/perl/build/perl-5.18.2/cpan/File-Path/lib ,
        q /mnt/repos/private/syoung/aguadev/apps/perl/build/perl-5.18.2/ext/re ,
        q /mnt/repos/private/syoung/aguadev/apps/perl/build/perl-5.18.2/dist/Term-ReadLine/lib ,
        q /mnt/repos/private/syoung/aguadev/apps/perl/build/perl-5.18.2/lib ,
        q . );
