# This Makefile is for the LWP extension to perl.
#
# It was generated automatically by MakeMaker version
# 6.94 (Revision: 69400) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#       ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: ()
#

#   MakeMaker Parameters:

#     ABSTRACT => q[The World-Wide Web library for Perl]
#     AUTHOR => [q[Gisle Aas <gisle@activestate.com>]]
#     BUILD_REQUIRES => {  }
#     CONFIGURE_REQUIRES => {  }
#     DISTNAME => q[libwww-perl]
#     EXE_FILES => [q[bin/lwp-request], q[bin/lwp-mirror], q[bin/lwp-download], q[bin/lwp-dump]]
#     LICENSE => q[perl]
#     META_MERGE => { recommends=>{ Authen::NTLM=>q[1.02], LWP::Protocol::https=>q[6.02], Data::Dump=>q[0] }, resources=>{ repository=>q[https://github.com/libwww-perl/libwww-perl], MailingList=>q[mailto:libwww@perl.org] } }
#     MIN_PERL_VERSION => q[5.008001]
#     NAME => q[LWP]
#     PREREQ_PM => { HTTP::Daemon=>q[6], URI::Escape=>q[0], Net::FTP=>q[2.58], URI=>q[1.10], LWP::MediaTypes=>q[6], Digest::MD5=>q[0], HTTP::Date=>q[6], WWW::RobotRules=>q[6], HTTP::Status=>q[6], MIME::Base64=>q[2.1], HTTP::Request=>q[6], HTTP::Response=>q[6], HTML::Entities=>q[0], HTTP::Negotiate=>q[6], HTTP::Request::Common=>q[6], File::Listing=>q[6], IO::Select=>q[0], HTTP::Cookies=>q[6], IO::Socket=>q[0], Net::HTTP=>q[6.04], Encode::Locale=>q[0], HTML::HeadParser=>q[0], Encode=>q[2.12] }
#     TEST_REQUIRES => {  }
#     VERSION_FROM => q[lib/LWP.pm]
#     clean => { FILES=>q[] }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /agua/apps/perl/5.18.2/lib/5.18.2/x86_64-linux/Config.pm).
# They may have been overridden via Makefile.PL or on the command line.
AR = ar
CC = cc
CCCDLFLAGS = -fPIC
CCDLFLAGS = -Wl,-E
DLEXT = so
DLSRC = dl_dlopen.xs
EXE_EXT = 
FULL_AR = /usr/bin/ar
LD = cc
LDDLFLAGS = -shared -O2 -L/usr/local/lib -fstack-protector
LDFLAGS =  -fstack-protector -L/usr/local/lib
LIBC = 
LIB_EXT = .a
OBJ_EXT = .o
OSNAME = linux
OSVERS = 3.8.0-35-generic
RANLIB = :
SITELIBEXP = /agua/apps/perl/5.18.2/lib/site_perl/5.18.2
SITEARCHEXP = /agua/apps/perl/5.18.2/lib/site_perl/5.18.2/x86_64-linux
SO = so
VENDORARCHEXP = 
VENDORLIBEXP = 


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
DIRFILESEP = /
DFSEP = $(DIRFILESEP)
NAME = LWP
NAME_SYM = LWP
VERSION = 6.05
VERSION_MACRO = VERSION
VERSION_SYM = 6_05
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION = 6.05
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"
INST_ARCHLIB = blib/arch
INST_SCRIPT = blib/script
INST_BIN = blib/bin
INST_LIB = blib/lib
INST_MAN1DIR = blib/man1
INST_MAN3DIR = blib/man3
MAN1EXT = 1
MAN3EXT = 3
INSTALLDIRS = site
DESTDIR = 
PREFIX = $(SITEPREFIX)
PERLPREFIX = /agua/apps/perl/5.18.2
SITEPREFIX = /agua/apps/perl/5.18.2
VENDORPREFIX = 
INSTALLPRIVLIB = /agua/apps/perl/5.18.2/lib/5.18.2
DESTINSTALLPRIVLIB = $(DESTDIR)$(INSTALLPRIVLIB)
INSTALLSITELIB = /agua/apps/perl/5.18.2/lib/site_perl/5.18.2
DESTINSTALLSITELIB = $(DESTDIR)$(INSTALLSITELIB)
INSTALLVENDORLIB = 
DESTINSTALLVENDORLIB = $(DESTDIR)$(INSTALLVENDORLIB)
INSTALLARCHLIB = /agua/apps/perl/5.18.2/lib/5.18.2/x86_64-linux
DESTINSTALLARCHLIB = $(DESTDIR)$(INSTALLARCHLIB)
INSTALLSITEARCH = /agua/apps/perl/5.18.2/lib/site_perl/5.18.2/x86_64-linux
DESTINSTALLSITEARCH = $(DESTDIR)$(INSTALLSITEARCH)
INSTALLVENDORARCH = 
DESTINSTALLVENDORARCH = $(DESTDIR)$(INSTALLVENDORARCH)
INSTALLBIN = /agua/apps/perl/5.18.2/bin
DESTINSTALLBIN = $(DESTDIR)$(INSTALLBIN)
INSTALLSITEBIN = /agua/apps/perl/5.18.2/bin
DESTINSTALLSITEBIN = $(DESTDIR)$(INSTALLSITEBIN)
INSTALLVENDORBIN = 
DESTINSTALLVENDORBIN = $(DESTDIR)$(INSTALLVENDORBIN)
INSTALLSCRIPT = /agua/apps/perl/5.18.2/bin
DESTINSTALLSCRIPT = $(DESTDIR)$(INSTALLSCRIPT)
INSTALLSITESCRIPT = /agua/apps/perl/5.18.2/bin
DESTINSTALLSITESCRIPT = $(DESTDIR)$(INSTALLSITESCRIPT)
INSTALLVENDORSCRIPT = 
DESTINSTALLVENDORSCRIPT = $(DESTDIR)$(INSTALLVENDORSCRIPT)
INSTALLMAN1DIR = /agua/apps/perl/5.18.2/man/man1
DESTINSTALLMAN1DIR = $(DESTDIR)$(INSTALLMAN1DIR)
INSTALLSITEMAN1DIR = /agua/apps/perl/5.18.2/man/man1
DESTINSTALLSITEMAN1DIR = $(DESTDIR)$(INSTALLSITEMAN1DIR)
INSTALLVENDORMAN1DIR = 
DESTINSTALLVENDORMAN1DIR = $(DESTDIR)$(INSTALLVENDORMAN1DIR)
INSTALLMAN3DIR = /agua/apps/perl/5.18.2/man/man3
DESTINSTALLMAN3DIR = $(DESTDIR)$(INSTALLMAN3DIR)
INSTALLSITEMAN3DIR = /agua/apps/perl/5.18.2/man/man3
DESTINSTALLSITEMAN3DIR = $(DESTDIR)$(INSTALLSITEMAN3DIR)
INSTALLVENDORMAN3DIR = 
DESTINSTALLVENDORMAN3DIR = $(DESTDIR)$(INSTALLVENDORMAN3DIR)
PERL_LIB = /agua/apps/perl/5.18.2/lib/5.18.2
PERL_ARCHLIB = /agua/apps/perl/5.18.2/lib/5.18.2/x86_64-linux
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKEFILE_OLD = Makefile.old
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = /agua/apps/perl/5.18.2/lib/5.18.2/x86_64-linux/CORE
PERL = /mnt/repos/private/syoung/aguadev/apps/perl/5.18.2/bin/perl
FULLPERL = /mnt/repos/private/syoung/aguadev/apps/perl/5.18.2/bin/perl
ABSPERL = $(PERL)
PERLRUN = $(PERL)
FULLPERLRUN = $(FULLPERL)
ABSPERLRUN = $(ABSPERL)
PERLRUNINST = $(PERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
FULLPERLRUNINST = $(FULLPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
ABSPERLRUNINST = $(ABSPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
PERL_CORE = 0
PERM_DIR = 755
PERM_RW = 644
PERM_RWX = 755

MAKEMAKER   = /agua/apps/perl/5.18.2/lib/site_perl/5.18.2/ExtUtils/MakeMaker.pm
MM_VERSION  = 6.94
MM_REVISION = 69400

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
MAKE = make
FULLEXT = LWP
BASEEXT = LWP
PARENT_NAME = 
DLBASE = $(BASEEXT)
VERSION_FROM = lib/LWP.pm
OBJECT = 
LDFROM = $(OBJECT)
LINKTYPE = dynamic
BOOTDEP = 

# Handy lists of source code files:
XS_FILES = 
C_FILES  = 
O_FILES  = 
H_FILES  = 
MAN1PODS = bin/lwp-download \
	bin/lwp-dump \
	bin/lwp-mirror \
	bin/lwp-request
MAN3PODS = lib/LWP.pm \
	lib/LWP/Authen/Ntlm.pm \
	lib/LWP/ConnCache.pm \
	lib/LWP/Debug.pm \
	lib/LWP/MemberMixin.pm \
	lib/LWP/Protocol.pm \
	lib/LWP/RobotUA.pm \
	lib/LWP/Simple.pm \
	lib/LWP/UserAgent.pm \
	lwpcook.pod \
	lwptut.pod

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIB)$(DFSEP)Config.pm $(PERL_INC)$(DFSEP)config.h

# Where to build things
INST_LIBDIR      = $(INST_LIB)
INST_ARCHLIBDIR  = $(INST_ARCHLIB)

INST_AUTODIR     = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC      = 
INST_DYNAMIC     = 
INST_BOOT        = 

# Extra linker info
EXPORT_LIST        = 
PERL_ARCHIVE       = 
PERL_ARCHIVE_AFTER = 


TO_INST_PM = lib/LWP.pm \
	lib/LWP/Authen/Basic.pm \
	lib/LWP/Authen/Digest.pm \
	lib/LWP/Authen/Ntlm.pm \
	lib/LWP/ConnCache.pm \
	lib/LWP/Debug.pm \
	lib/LWP/DebugFile.pm \
	lib/LWP/MemberMixin.pm \
	lib/LWP/Protocol.pm \
	lib/LWP/Protocol/GHTTP.pm \
	lib/LWP/Protocol/cpan.pm \
	lib/LWP/Protocol/data.pm \
	lib/LWP/Protocol/file.pm \
	lib/LWP/Protocol/ftp.pm \
	lib/LWP/Protocol/gopher.pm \
	lib/LWP/Protocol/http.pm \
	lib/LWP/Protocol/loopback.pm \
	lib/LWP/Protocol/mailto.pm \
	lib/LWP/Protocol/nntp.pm \
	lib/LWP/Protocol/nogo.pm \
	lib/LWP/RobotUA.pm \
	lib/LWP/Simple.pm \
	lib/LWP/UserAgent.pm \
	lwpcook.pod \
	lwptut.pod

PM_TO_BLIB = lib/LWP.pm \
	blib/lib/LWP.pm \
	lib/LWP/Authen/Basic.pm \
	blib/lib/LWP/Authen/Basic.pm \
	lib/LWP/Authen/Digest.pm \
	blib/lib/LWP/Authen/Digest.pm \
	lib/LWP/Authen/Ntlm.pm \
	blib/lib/LWP/Authen/Ntlm.pm \
	lib/LWP/ConnCache.pm \
	blib/lib/LWP/ConnCache.pm \
	lib/LWP/Debug.pm \
	blib/lib/LWP/Debug.pm \
	lib/LWP/DebugFile.pm \
	blib/lib/LWP/DebugFile.pm \
	lib/LWP/MemberMixin.pm \
	blib/lib/LWP/MemberMixin.pm \
	lib/LWP/Protocol.pm \
	blib/lib/LWP/Protocol.pm \
	lib/LWP/Protocol/GHTTP.pm \
	blib/lib/LWP/Protocol/GHTTP.pm \
	lib/LWP/Protocol/cpan.pm \
	blib/lib/LWP/Protocol/cpan.pm \
	lib/LWP/Protocol/data.pm \
	blib/lib/LWP/Protocol/data.pm \
	lib/LWP/Protocol/file.pm \
	blib/lib/LWP/Protocol/file.pm \
	lib/LWP/Protocol/ftp.pm \
	blib/lib/LWP/Protocol/ftp.pm \
	lib/LWP/Protocol/gopher.pm \
	blib/lib/LWP/Protocol/gopher.pm \
	lib/LWP/Protocol/http.pm \
	blib/lib/LWP/Protocol/http.pm \
	lib/LWP/Protocol/loopback.pm \
	blib/lib/LWP/Protocol/loopback.pm \
	lib/LWP/Protocol/mailto.pm \
	blib/lib/LWP/Protocol/mailto.pm \
	lib/LWP/Protocol/nntp.pm \
	blib/lib/LWP/Protocol/nntp.pm \
	lib/LWP/Protocol/nogo.pm \
	blib/lib/LWP/Protocol/nogo.pm \
	lib/LWP/RobotUA.pm \
	blib/lib/LWP/RobotUA.pm \
	lib/LWP/Simple.pm \
	blib/lib/LWP/Simple.pm \
	lib/LWP/UserAgent.pm \
	blib/lib/LWP/UserAgent.pm \
	lwpcook.pod \
	$(INST_LIB)/lwpcook.pod \
	lwptut.pod \
	$(INST_LIB)/lwptut.pod


# --- MakeMaker platform_constants section:
MM_Unix_VERSION = 6.94
PERL_MALLOC_DEF = -DPERL_EXTMALLOC_DEF -Dmalloc=Perl_malloc -Dfree=Perl_mfree -Drealloc=Perl_realloc -Dcalloc=Perl_calloc


# --- MakeMaker tool_autosplit section:
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(ABSPERLRUN)  -e 'use AutoSplit;  autosplit($$$$ARGV[0], $$$$ARGV[1], 0, 1, 1)' --



# --- MakeMaker tool_xsubpp section:


# --- MakeMaker tools_other section:
SHELL = /bin/sh
CHMOD = chmod
CP = cp
MV = mv
NOOP = $(TRUE)
NOECHO = @
RM_F = rm -f
RM_RF = rm -rf
TEST_F = test -f
TOUCH = touch
UMASK_NULL = umask 0
DEV_NULL = > /dev/null 2>&1
MKPATH = $(ABSPERLRUN) -MExtUtils::Command -e 'mkpath' --
EQUALIZE_TIMESTAMP = $(ABSPERLRUN) -MExtUtils::Command -e 'eqtime' --
FALSE = false
TRUE = true
ECHO = echo
ECHO_N = echo -n
UNINST = 0
VERBINST = 0
MOD_INSTALL = $(ABSPERLRUN) -MExtUtils::Install -e 'install([ from_to => {@ARGV}, verbose => '\''$(VERBINST)'\'', uninstall_shadows => '\''$(UNINST)'\'', dir_mode => '\''$(PERM_DIR)'\'' ]);' --
DOC_INSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'perllocal_install' --
UNINSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'uninstall' --
WARN_IF_OLD_PACKLIST = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'warn_if_old_packlist' --
MACROSTART = 
MACROEND = 
USEMAKEFILE = -f
FIXIN = $(ABSPERLRUN) -MExtUtils::MY -e 'MY->fixin(shift)' --
CP_NONEMPTY = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'cp_nonempty' --


# --- MakeMaker makemakerdflt section:
makemakerdflt : all
	$(NOECHO) $(NOOP)


# --- MakeMaker dist section:
TAR = tar
TARFLAGS = cvf
ZIP = zip
ZIPFLAGS = -r
COMPRESS = gzip --best
SUFFIX = .gz
SHAR = shar
PREOP = $(NOECHO) $(NOOP)
POSTOP = $(NOECHO) $(NOOP)
TO_UNIX = $(NOECHO) $(NOOP)
CI = ci -u
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q
DIST_CP = best
DIST_DEFAULT = tardist
DISTNAME = libwww-perl
DISTVNAME = libwww-perl-6.05


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:


# --- MakeMaker const_loadlibs section:


# --- MakeMaker const_cccmd section:


# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:

PASTHRU = LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	PREFIX="$(PREFIX)"


# --- MakeMaker special_targets section:
.SUFFIXES : .xs .c .C .cpp .i .s .cxx .cc $(OBJ_EXT)

.PHONY: all config static dynamic test linkext manifest blibdirs clean realclean disttest distdir



# --- MakeMaker c_o section:


# --- MakeMaker xs_c section:


# --- MakeMaker xs_o section:


# --- MakeMaker top_targets section:
all :: pure_all manifypods
	$(NOECHO) $(NOOP)


pure_all :: config pm_to_blib subdirs linkext
	$(NOECHO) $(NOOP)

subdirs :: $(MYEXTLIB)
	$(NOECHO) $(NOOP)

config :: $(FIRST_MAKEFILE) blibdirs
	$(NOECHO) $(NOOP)

help :
	perldoc ExtUtils::MakeMaker


# --- MakeMaker blibdirs section:
blibdirs : $(INST_LIBDIR)$(DFSEP).exists $(INST_ARCHLIB)$(DFSEP).exists $(INST_AUTODIR)$(DFSEP).exists $(INST_ARCHAUTODIR)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists $(INST_SCRIPT)$(DFSEP).exists $(INST_MAN1DIR)$(DFSEP).exists $(INST_MAN3DIR)$(DFSEP).exists
	$(NOECHO) $(NOOP)

# Backwards compat with 6.18 through 6.25
blibdirs.ts : blibdirs
	$(NOECHO) $(NOOP)

$(INST_LIBDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_LIBDIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_LIBDIR)
	$(NOECHO) $(TOUCH) $(INST_LIBDIR)$(DFSEP).exists

$(INST_ARCHLIB)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHLIB)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHLIB)
	$(NOECHO) $(TOUCH) $(INST_ARCHLIB)$(DFSEP).exists

$(INST_AUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_AUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_AUTODIR)
	$(NOECHO) $(TOUCH) $(INST_AUTODIR)$(DFSEP).exists

$(INST_ARCHAUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHAUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHAUTODIR)
	$(NOECHO) $(TOUCH) $(INST_ARCHAUTODIR)$(DFSEP).exists

$(INST_BIN)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_BIN)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_BIN)
	$(NOECHO) $(TOUCH) $(INST_BIN)$(DFSEP).exists

$(INST_SCRIPT)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_SCRIPT)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_SCRIPT)
	$(NOECHO) $(TOUCH) $(INST_SCRIPT)$(DFSEP).exists

$(INST_MAN1DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN1DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN1DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN1DIR)$(DFSEP).exists

$(INST_MAN3DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN3DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN3DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN3DIR)$(DFSEP).exists



# --- MakeMaker linkext section:

linkext :: $(LINKTYPE)
	$(NOECHO) $(NOOP)


# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic_bs section:

BOOTSTRAP =


# --- MakeMaker dynamic section:

dynamic :: $(FIRST_MAKEFILE) $(BOOTSTRAP) $(INST_DYNAMIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker dynamic_lib section:


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
static :: $(FIRST_MAKEFILE) $(INST_STATIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker static_lib section:


# --- MakeMaker manifypods section:

POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e pod2man "--"
POD2MAN = $(POD2MAN_EXE)


manifypods : pure_all  \
	bin/lwp-download \
	bin/lwp-dump \
	bin/lwp-mirror \
	bin/lwp-request \
	lib/LWP.pm \
	lib/LWP/Authen/Ntlm.pm \
	lib/LWP/ConnCache.pm \
	lib/LWP/Debug.pm \
	lib/LWP/MemberMixin.pm \
	lib/LWP/Protocol.pm \
	lib/LWP/RobotUA.pm \
	lib/LWP/Simple.pm \
	lib/LWP/UserAgent.pm \
	lwpcook.pod \
	lwptut.pod
	$(NOECHO) $(POD2MAN) --section=1 --perm_rw=$(PERM_RW) \
	  bin/lwp-download $(INST_MAN1DIR)/lwp-download.$(MAN1EXT) \
	  bin/lwp-dump $(INST_MAN1DIR)/lwp-dump.$(MAN1EXT) \
	  bin/lwp-mirror $(INST_MAN1DIR)/lwp-mirror.$(MAN1EXT) \
	  bin/lwp-request $(INST_MAN1DIR)/lwp-request.$(MAN1EXT) 
	$(NOECHO) $(POD2MAN) --section=3 --perm_rw=$(PERM_RW) \
	  lib/LWP.pm $(INST_MAN3DIR)/LWP.$(MAN3EXT) \
	  lib/LWP/Authen/Ntlm.pm $(INST_MAN3DIR)/LWP::Authen::Ntlm.$(MAN3EXT) \
	  lib/LWP/ConnCache.pm $(INST_MAN3DIR)/LWP::ConnCache.$(MAN3EXT) \
	  lib/LWP/Debug.pm $(INST_MAN3DIR)/LWP::Debug.$(MAN3EXT) \
	  lib/LWP/MemberMixin.pm $(INST_MAN3DIR)/LWP::MemberMixin.$(MAN3EXT) \
	  lib/LWP/Protocol.pm $(INST_MAN3DIR)/LWP::Protocol.$(MAN3EXT) \
	  lib/LWP/RobotUA.pm $(INST_MAN3DIR)/LWP::RobotUA.$(MAN3EXT) \
	  lib/LWP/Simple.pm $(INST_MAN3DIR)/LWP::Simple.$(MAN3EXT) \
	  lib/LWP/UserAgent.pm $(INST_MAN3DIR)/LWP::UserAgent.$(MAN3EXT) \
	  lwpcook.pod $(INST_MAN3DIR)/lwpcook.$(MAN3EXT) \
	  lwptut.pod $(INST_MAN3DIR)/lwptut.$(MAN3EXT) 




# --- MakeMaker processPL section:


# --- MakeMaker installbin section:

EXE_FILES = bin/lwp-request bin/lwp-mirror bin/lwp-download bin/lwp-dump

pure_all :: $(INST_SCRIPT)/lwp-download $(INST_SCRIPT)/lwp-dump $(INST_SCRIPT)/lwp-request $(INST_SCRIPT)/lwp-mirror
	$(NOECHO) $(NOOP)

realclean ::
	$(RM_F) \
	  $(INST_SCRIPT)/lwp-download $(INST_SCRIPT)/lwp-dump \
	  $(INST_SCRIPT)/lwp-request $(INST_SCRIPT)/lwp-mirror 

$(INST_SCRIPT)/lwp-download : bin/lwp-download $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/lwp-download
	$(CP) bin/lwp-download $(INST_SCRIPT)/lwp-download
	$(FIXIN) $(INST_SCRIPT)/lwp-download
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/lwp-download

$(INST_SCRIPT)/lwp-dump : bin/lwp-dump $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/lwp-dump
	$(CP) bin/lwp-dump $(INST_SCRIPT)/lwp-dump
	$(FIXIN) $(INST_SCRIPT)/lwp-dump
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/lwp-dump

$(INST_SCRIPT)/lwp-request : bin/lwp-request $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/lwp-request
	$(CP) bin/lwp-request $(INST_SCRIPT)/lwp-request
	$(FIXIN) $(INST_SCRIPT)/lwp-request
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/lwp-request

$(INST_SCRIPT)/lwp-mirror : bin/lwp-mirror $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/lwp-mirror
	$(CP) bin/lwp-mirror $(INST_SCRIPT)/lwp-mirror
	$(FIXIN) $(INST_SCRIPT)/lwp-mirror
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/lwp-mirror



# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean_subdirs section:
clean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean :: clean_subdirs
	- $(RM_F) \
	  $(BASEEXT).bso $(BASEEXT).def \
	  $(BASEEXT).exp $(BASEEXT).x \
	  $(BOOTSTRAP) $(INST_ARCHAUTODIR)/extralibs.all \
	  $(INST_ARCHAUTODIR)/extralibs.ld $(MAKE_APERL_FILE) \
	  *$(LIB_EXT) *$(OBJ_EXT) \
	  *perl.core MYMETA.json \
	  MYMETA.yml blibdirs.ts \
	  core core.*perl.*.? \
	  core.[0-9] core.[0-9][0-9] \
	  core.[0-9][0-9][0-9] core.[0-9][0-9][0-9][0-9] \
	  core.[0-9][0-9][0-9][0-9][0-9] lib$(BASEEXT).def \
	  mon.out perl \
	  perl$(EXE_EXT) perl.exe \
	  perlmain.c pm_to_blib \
	  pm_to_blib.ts so_locations \
	  tmon.out 
	- $(RM_RF) \
	  blib 
	  $(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	- $(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD) $(DEV_NULL)


# --- MakeMaker realclean_subdirs section:
realclean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker realclean section:
# Delete temporary files (via clean) and also delete dist files
realclean purge ::  clean realclean_subdirs
	- $(RM_F) \
	  $(MAKEFILE_OLD) $(FIRST_MAKEFILE) 
	- $(RM_RF) \
	  $(DISTVNAME) 


# --- MakeMaker metafile section:
metafile : create_distdir
	$(NOECHO) $(ECHO) Generating META.yml
	$(NOECHO) $(ECHO) '---' > META_new.yml
	$(NOECHO) $(ECHO) 'abstract: '\''The World-Wide Web library for Perl'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'author:' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Gisle Aas <gisle@activestate.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'build_requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  ExtUtils::MakeMaker: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'configure_requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  ExtUtils::MakeMaker: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'dynamic_config: 1' >> META_new.yml
	$(NOECHO) $(ECHO) 'generated_by: '\''ExtUtils::MakeMaker version 6.94, CPAN::Meta::Converter version 2.120921'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'license: perl' >> META_new.yml
	$(NOECHO) $(ECHO) 'meta-spec:' >> META_new.yml
	$(NOECHO) $(ECHO) '  url: http://module-build.sourceforge.net/META-spec-v1.4.html' >> META_new.yml
	$(NOECHO) $(ECHO) '  version: '\''1.4'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'name: libwww-perl' >> META_new.yml
	$(NOECHO) $(ECHO) 'no_index:' >> META_new.yml
	$(NOECHO) $(ECHO) '  directory:' >> META_new.yml
	$(NOECHO) $(ECHO) '    - t' >> META_new.yml
	$(NOECHO) $(ECHO) '    - inc' >> META_new.yml
	$(NOECHO) $(ECHO) 'recommends:' >> META_new.yml
	$(NOECHO) $(ECHO) '  Authen::NTLM: '\''1.02'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Data::Dump: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  LWP::Protocol::https: '\''6.02'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  Digest::MD5: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Encode: '\''2.12'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Encode::Locale: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::Listing: '\''6'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  HTML::Entities: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  HTML::HeadParser: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  HTTP::Cookies: '\''6'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  HTTP::Daemon: '\''6'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  HTTP::Date: '\''6'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  HTTP::Negotiate: '\''6'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  HTTP::Request: '\''6'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  HTTP::Request::Common: '\''6'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  HTTP::Response: '\''6'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  HTTP::Status: '\''6'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  IO::Select: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  IO::Socket: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  LWP::MediaTypes: '\''6'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  MIME::Base64: '\''2.1'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Net::FTP: '\''2.58'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Net::HTTP: '\''6.04'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  URI: '\''1.10'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  URI::Escape: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  WWW::RobotRules: '\''6'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  perl: '\''5.008001'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'resources:' >> META_new.yml
	$(NOECHO) $(ECHO) '  repository: https://github.com/libwww-perl/libwww-perl' >> META_new.yml
	$(NOECHO) $(ECHO) '  x_MailingList: mailto:libwww@perl.org' >> META_new.yml
	$(NOECHO) $(ECHO) 'version: '\''6.05'\''' >> META_new.yml
	-$(NOECHO) $(MV) META_new.yml $(DISTVNAME)/META.yml
	$(NOECHO) $(ECHO) Generating META.json
	$(NOECHO) $(ECHO) '{' > META_new.json
	$(NOECHO) $(ECHO) '   "abstract" : "The World-Wide Web library for Perl",' >> META_new.json
	$(NOECHO) $(ECHO) '   "author" : [' >> META_new.json
	$(NOECHO) $(ECHO) '      "Gisle Aas <gisle@activestate.com>"' >> META_new.json
	$(NOECHO) $(ECHO) '   ],' >> META_new.json
	$(NOECHO) $(ECHO) '   "dynamic_config" : 1,' >> META_new.json
	$(NOECHO) $(ECHO) '   "generated_by" : "ExtUtils::MakeMaker version 6.94, CPAN::Meta::Converter version 2.120921",' >> META_new.json
	$(NOECHO) $(ECHO) '   "license" : [' >> META_new.json
	$(NOECHO) $(ECHO) '      "perl_5"' >> META_new.json
	$(NOECHO) $(ECHO) '   ],' >> META_new.json
	$(NOECHO) $(ECHO) '   "meta-spec" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec",' >> META_new.json
	$(NOECHO) $(ECHO) '      "version" : "2"' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "name" : "libwww-perl",' >> META_new.json
	$(NOECHO) $(ECHO) '   "no_index" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "directory" : [' >> META_new.json
	$(NOECHO) $(ECHO) '         "t",' >> META_new.json
	$(NOECHO) $(ECHO) '         "inc"' >> META_new.json
	$(NOECHO) $(ECHO) '      ]' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "prereqs" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "build" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "ExtUtils::MakeMaker" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "configure" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "ExtUtils::MakeMaker" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "runtime" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "recommends" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "Authen::NTLM" : "1.02",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Data::Dump" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "LWP::Protocol::https" : "6.02"' >> META_new.json
	$(NOECHO) $(ECHO) '         },' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "Digest::MD5" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Encode" : "2.12",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Encode::Locale" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::Listing" : "6",' >> META_new.json
	$(NOECHO) $(ECHO) '            "HTML::Entities" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "HTML::HeadParser" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "HTTP::Cookies" : "6",' >> META_new.json
	$(NOECHO) $(ECHO) '            "HTTP::Daemon" : "6",' >> META_new.json
	$(NOECHO) $(ECHO) '            "HTTP::Date" : "6",' >> META_new.json
	$(NOECHO) $(ECHO) '            "HTTP::Negotiate" : "6",' >> META_new.json
	$(NOECHO) $(ECHO) '            "HTTP::Request" : "6",' >> META_new.json
	$(NOECHO) $(ECHO) '            "HTTP::Request::Common" : "6",' >> META_new.json
	$(NOECHO) $(ECHO) '            "HTTP::Response" : "6",' >> META_new.json
	$(NOECHO) $(ECHO) '            "HTTP::Status" : "6",' >> META_new.json
	$(NOECHO) $(ECHO) '            "IO::Select" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "IO::Socket" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "LWP::MediaTypes" : "6",' >> META_new.json
	$(NOECHO) $(ECHO) '            "MIME::Base64" : "2.1",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Net::FTP" : "2.58",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Net::HTTP" : "6.04",' >> META_new.json
	$(NOECHO) $(ECHO) '            "URI" : "1.10",' >> META_new.json
	$(NOECHO) $(ECHO) '            "URI::Escape" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "WWW::RobotRules" : "6",' >> META_new.json
	$(NOECHO) $(ECHO) '            "perl" : "5.008001"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      }' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "release_status" : "stable",' >> META_new.json
	$(NOECHO) $(ECHO) '   "resources" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "repository" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "url" : "https://github.com/libwww-perl/libwww-perl"' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "x_MailingList" : "mailto:libwww@perl.org"' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "version" : "6.05"' >> META_new.json
	$(NOECHO) $(ECHO) '}' >> META_new.json
	-$(NOECHO) $(MV) META_new.json $(DISTVNAME)/META.json


# --- MakeMaker signature section:
signature :
	cpansign -s


# --- MakeMaker dist_basics section:
distclean :: realclean distcheck
	$(NOECHO) $(NOOP)

distcheck :
	$(PERLRUN) "-MExtUtils::Manifest=fullcheck" -e fullcheck

skipcheck :
	$(PERLRUN) "-MExtUtils::Manifest=skipcheck" -e skipcheck

manifest :
	$(PERLRUN) "-MExtUtils::Manifest=mkmanifest" -e mkmanifest

veryclean : realclean
	$(RM_F) *~ */*~ *.orig */*.orig *.bak */*.bak *.old */*.old



# --- MakeMaker dist_core section:

dist : $(DIST_DEFAULT) $(FIRST_MAKEFILE)
	$(NOECHO) $(ABSPERLRUN) -l -e 'print '\''Warning: Makefile possibly out of date with $(VERSION_FROM)'\''' \
	  -e '    if -e '\''$(VERSION_FROM)'\'' and -M '\''$(VERSION_FROM)'\'' < -M '\''$(FIRST_MAKEFILE)'\'';' --

tardist : $(DISTVNAME).tar$(SUFFIX)
	$(NOECHO) $(NOOP)

uutardist : $(DISTVNAME).tar$(SUFFIX)
	uuencode $(DISTVNAME).tar$(SUFFIX) $(DISTVNAME).tar$(SUFFIX) > $(DISTVNAME).tar$(SUFFIX)_uu
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).tar$(SUFFIX)_uu'

$(DISTVNAME).tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).tar$(SUFFIX)'
	$(POSTOP)

zipdist : $(DISTVNAME).zip
	$(NOECHO) $(NOOP)

$(DISTVNAME).zip : distdir
	$(PREOP)
	$(ZIP) $(ZIPFLAGS) $(DISTVNAME).zip $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).zip'
	$(POSTOP)

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).shar'
	$(POSTOP)


# --- MakeMaker distdir section:
create_distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"

distdir : create_distdir distmeta 
	$(NOECHO) $(NOOP)



# --- MakeMaker dist_test section:
disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL 
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)



# --- MakeMaker dist_ci section:

ci :
	$(PERLRUN) "-MExtUtils::Manifest=maniread" \
	  -e "@all = keys %{ maniread() };" \
	  -e "print(qq{Executing $(CI) @all\n}); system(qq{$(CI) @all});" \
	  -e "print(qq{Executing $(RCS_LABEL) ...\n}); system(qq{$(RCS_LABEL) @all});"


# --- MakeMaker distmeta section:
distmeta : create_distdir metafile
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -e q{META.yml};' \
	  -e 'eval { maniadd({q{META.yml} => q{Module YAML meta-data (added by MakeMaker)}}) }' \
	  -e '    or print "Could not add META.yml to MANIFEST: $$$${'\''@'\''}\n"' --
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -f q{META.json};' \
	  -e 'eval { maniadd({q{META.json} => q{Module JSON meta-data (added by MakeMaker)}}) }' \
	  -e '    or print "Could not add META.json to MANIFEST: $$$${'\''@'\''}\n"' --



# --- MakeMaker distsignature section:
distsignature : create_distdir
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }' \
	  -e '    or print "Could not add SIGNATURE to MANIFEST: $$$${'\''@'\''}\n"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s



# --- MakeMaker install section:

install :: pure_install doc_install
	$(NOECHO) $(NOOP)

install_perl :: pure_perl_install doc_perl_install
	$(NOECHO) $(NOOP)

install_site :: pure_site_install doc_site_install
	$(NOECHO) $(NOOP)

install_vendor :: pure_vendor_install doc_vendor_install
	$(NOECHO) $(NOOP)

pure_install :: pure_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

doc_install :: doc_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

pure__install : pure_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

doc__install : doc_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_perl_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLARCHLIB)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLPRIVLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLARCHLIB) \
		$(INST_BIN) $(DESTINSTALLBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		$(SITEARCHEXP)/auto/$(FULLEXT)


pure_site_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLSITEARCH)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLSITELIB) \
		$(INST_ARCHLIB) $(DESTINSTALLSITEARCH) \
		$(INST_BIN) $(DESTINSTALLSITEBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSITESCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLSITEMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLSITEMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		$(PERL_ARCHLIB)/auto/$(FULLEXT)

pure_vendor_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read $(VENDORARCHEXP)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLVENDORARCH)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLVENDORLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLVENDORARCH) \
		$(INST_BIN) $(DESTINSTALLVENDORBIN) \
		$(INST_SCRIPT) $(DESTINSTALLVENDORSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLVENDORMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLVENDORMAN3DIR)


doc_perl_install :: all
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLPRIVLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)/perllocal.pod

doc_site_install :: all
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)/perllocal.pod

doc_vendor_install :: all
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLVENDORLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)/perllocal.pod


uninstall :: uninstall_from_$(INSTALLDIRS)dirs
	$(NOECHO) $(NOOP)

uninstall_from_perldirs ::
	$(NOECHO) $(UNINSTALL) $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist

uninstall_from_sitedirs ::
	$(NOECHO) $(UNINSTALL) $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist

uninstall_from_vendordirs ::
	$(NOECHO) $(UNINSTALL) $(VENDORARCHEXP)/auto/$(FULLEXT)/.packlist


# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE :
	$(NOECHO) $(NOOP)


# --- MakeMaker perldepend section:


# --- MakeMaker makefile section:
# We take a very conservative approach here, but it's worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
$(FIRST_MAKEFILE) : Makefile.PL $(CONFIGDEP)
	$(NOECHO) $(ECHO) "Makefile out-of-date with respect to $?"
	$(NOECHO) $(ECHO) "Cleaning current config before rebuilding Makefile..."
	-$(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	-$(NOECHO) $(MV)   $(FIRST_MAKEFILE) $(MAKEFILE_OLD)
	- $(MAKE) $(USEMAKEFILE) $(MAKEFILE_OLD) clean $(DEV_NULL)
	$(PERLRUN) Makefile.PL 
	$(NOECHO) $(ECHO) "==> Your Makefile has been rebuilt. <=="
	$(NOECHO) $(ECHO) "==> Please rerun the $(MAKE) command.  <=="
	$(FALSE)



# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = perl
FULLPERL      = /mnt/repos/private/syoung/aguadev/apps/perl/5.18.2/bin/perl

$(MAP_TARGET) :: static $(MAKE_APERL_FILE)
	$(MAKE) $(USEMAKEFILE) $(MAKE_APERL_FILE) $@

$(MAKE_APERL_FILE) : $(FIRST_MAKEFILE) pm_to_blib
	$(NOECHO) $(ECHO) Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	$(NOECHO) $(PERLRUNINST) \
		Makefile.PL DIR= \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS=


# --- MakeMaker test section:

TEST_VERBOSE=0

test : pure_all
	$(FULLPERL) t/TEST $(TEST_VERBOSE)

test_hudson : pure_all
	$(FULLPERL) t/TEST $(TEST_VERBOSE) --formatter=TAP::Formatter::JUnit



# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd :
	$(NOECHO) $(ECHO) '<SOFTPKG NAME="$(DISTNAME)" VERSION="$(VERSION)">' > $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <ABSTRACT>The World-Wide Web library for Perl</ABSTRACT>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <AUTHOR>Gisle Aas &lt;gisle@activestate.com&gt;</AUTHOR>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <IMPLEMENTATION>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <PERLCORE VERSION="5,008001,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Digest::MD5" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Encode::" VERSION="2.12" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Encode::Locale" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE VERSION="6" NAME="File::Listing" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="HTML::Entities" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="HTML::HeadParser" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE VERSION="6" NAME="HTTP::Cookies" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="HTTP::Daemon" VERSION="6" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="HTTP::Date" VERSION="6" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="HTTP::Negotiate" VERSION="6" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="HTTP::Request" VERSION="6" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE VERSION="6" NAME="HTTP::Request::Common" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="HTTP::Response" VERSION="6" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE VERSION="6" NAME="HTTP::Status" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="IO::Select" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="IO::Socket" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="LWP::MediaTypes" VERSION="6" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE VERSION="2.1" NAME="MIME::Base64" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE VERSION="2.58" NAME="Net::FTP" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE VERSION="6.04" NAME="Net::HTTP" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="URI::" VERSION="1.1" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="URI::Escape" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="WWW::RobotRules" VERSION="6" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <ARCHITECTURE NAME="x86_64-linux-5.18" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <CODEBASE HREF="" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    </IMPLEMENTATION>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '</SOFTPKG>' >> $(DISTNAME).ppd


# --- MakeMaker pm_to_blib section:

pm_to_blib : $(FIRST_MAKEFILE) $(TO_INST_PM)
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/LWP.pm blib/lib/LWP.pm \
	  lib/LWP/Authen/Basic.pm blib/lib/LWP/Authen/Basic.pm \
	  lib/LWP/Authen/Digest.pm blib/lib/LWP/Authen/Digest.pm \
	  lib/LWP/Authen/Ntlm.pm blib/lib/LWP/Authen/Ntlm.pm \
	  lib/LWP/ConnCache.pm blib/lib/LWP/ConnCache.pm \
	  lib/LWP/Debug.pm blib/lib/LWP/Debug.pm \
	  lib/LWP/DebugFile.pm blib/lib/LWP/DebugFile.pm \
	  lib/LWP/MemberMixin.pm blib/lib/LWP/MemberMixin.pm \
	  lib/LWP/Protocol.pm blib/lib/LWP/Protocol.pm \
	  lib/LWP/Protocol/GHTTP.pm blib/lib/LWP/Protocol/GHTTP.pm \
	  lib/LWP/Protocol/cpan.pm blib/lib/LWP/Protocol/cpan.pm \
	  lib/LWP/Protocol/data.pm blib/lib/LWP/Protocol/data.pm \
	  lib/LWP/Protocol/file.pm blib/lib/LWP/Protocol/file.pm \
	  lib/LWP/Protocol/ftp.pm blib/lib/LWP/Protocol/ftp.pm \
	  lib/LWP/Protocol/gopher.pm blib/lib/LWP/Protocol/gopher.pm \
	  lib/LWP/Protocol/http.pm blib/lib/LWP/Protocol/http.pm \
	  lib/LWP/Protocol/loopback.pm blib/lib/LWP/Protocol/loopback.pm \
	  lib/LWP/Protocol/mailto.pm blib/lib/LWP/Protocol/mailto.pm \
	  lib/LWP/Protocol/nntp.pm blib/lib/LWP/Protocol/nntp.pm \
	  lib/LWP/Protocol/nogo.pm blib/lib/LWP/Protocol/nogo.pm \
	  lib/LWP/RobotUA.pm blib/lib/LWP/RobotUA.pm \
	  lib/LWP/Simple.pm blib/lib/LWP/Simple.pm \
	  lib/LWP/UserAgent.pm blib/lib/LWP/UserAgent.pm \
	  lwpcook.pod $(INST_LIB)/lwpcook.pod \
	  lwptut.pod $(INST_LIB)/lwptut.pod 
	$(NOECHO) $(TOUCH) pm_to_blib


# --- MakeMaker selfdocument section:


# --- MakeMaker postamble section:


# End.
