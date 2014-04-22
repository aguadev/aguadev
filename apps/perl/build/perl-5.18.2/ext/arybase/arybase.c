/*
 * This file was generated automatically by ExtUtils::ParseXS version 3.18 from the
 * contents of arybase.xs. Do not edit this file, edit arybase.xs instead.
 *
 *    ANY CHANGES MADE HERE WILL BE LOST!
 *
 */

#line 1 "arybase.xs"
#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#define PERL_EXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "feature.h"

/* ... op => info map ................................................. */

typedef struct {
 OP *(*old_pp)(pTHX);
 IV base;
} ab_op_info;

#define PTABLE_NAME        ptable_map
#define PTABLE_VAL_FREE(V) PerlMemShared_free(V)
#include "ptable.h"
#define ptable_map_store(T, K, V) ptable_map_store(aPTBLMS_ (T), (K), (V))

STATIC ptable *ab_op_map = NULL;

#ifdef USE_ITHREADS
STATIC perl_mutex ab_op_map_mutex;
#endif

STATIC const ab_op_info *ab_map_fetch(const OP *o, ab_op_info *oi) {
 const ab_op_info *val;

#ifdef USE_ITHREADS
 MUTEX_LOCK(&ab_op_map_mutex);
#endif

 val = (ab_op_info *)ptable_fetch(ab_op_map, o);
 if (val) {
  *oi = *val;
  val = oi;
 }

#ifdef USE_ITHREADS
 MUTEX_UNLOCK(&ab_op_map_mutex);
#endif

 return val;
}

STATIC const ab_op_info *ab_map_store_locked(
 pPTBLMS_ const OP *o, OP *(*old_pp)(pTHX), IV base
) {
#define ab_map_store_locked(O, PP, B) \
  ab_map_store_locked(aPTBLMS_ (O), (PP), (B))
 ab_op_info *oi;

 if (!(oi = (ab_op_info *)ptable_fetch(ab_op_map, o))) {
  oi = (ab_op_info *)PerlMemShared_malloc(sizeof *oi);
  ptable_map_store(ab_op_map, o, oi);
 }

 oi->old_pp = old_pp;
 oi->base   = base;
 return oi;
}

STATIC void ab_map_store(
 pPTBLMS_ const OP *o, OP *(*old_pp)(pTHX), IV base)
{
#define ab_map_store(O, PP, B) ab_map_store(aPTBLMS_ (O),(PP),(B))

#ifdef USE_ITHREADS
 MUTEX_LOCK(&ab_op_map_mutex);
#endif

 ab_map_store_locked(o, old_pp, base);

#ifdef USE_ITHREADS
 MUTEX_UNLOCK(&ab_op_map_mutex);
#endif
}

STATIC void ab_map_delete(pTHX_ const OP *o) {
#define ab_map_delete(O) ab_map_delete(aTHX_ (O))
#ifdef USE_ITHREADS
 MUTEX_LOCK(&ab_op_map_mutex);
#endif

 ptable_map_store(ab_op_map, o, NULL);

#ifdef USE_ITHREADS
 MUTEX_UNLOCK(&ab_op_map_mutex);
#endif
}

/* ... $[ Implementation .............................................. */

#define hintkey     "$["
#define hintkey_len  (sizeof(hintkey)-1)

STATIC SV * ab_hint(pTHX_ const bool create) {
#define ab_hint(c) ab_hint(aTHX_ c)
 dVAR;
 SV **val
  = hv_fetch(GvHV(PL_hintgv), hintkey, hintkey_len, create);
 if (!val)
  return 0;
 return *val;
}

/* current base at compile time */
STATIC IV current_base(pTHX) {
#define current_base() current_base(aTHX)
 SV *hsv = ab_hint(0);
 assert(FEATURE_ARYBASE_IS_ENABLED);
 if (!hsv || !SvOK(hsv)) return 0;
 return SvIV(hsv);
}

STATIC void set_arybase_to(pTHX_ IV base) {
#define set_arybase_to(base) set_arybase_to(aTHX_ (base))
 dVAR;
 SV *hsv = ab_hint(1);
 sv_setiv_mg(hsv, base);
}

#define old_ck(opname) STATIC OP *(*ab_old_ck_##opname)(pTHX_ OP *) = 0
old_ck(sassign);
old_ck(aassign);
old_ck(aelem);
old_ck(aslice);
old_ck(lslice);
old_ck(av2arylen);
old_ck(splice);
old_ck(keys);
old_ck(each);
old_ck(substr);
old_ck(rindex);
old_ck(index);
old_ck(pos);

STATIC bool ab_op_is_dollar_bracket(pTHX_ OP *o) {
#define ab_op_is_dollar_bracket(o) ab_op_is_dollar_bracket(aTHX_ (o))
 OP *c;
 return o->op_type == OP_RV2SV && (o->op_flags & OPf_KIDS)
  && (c = cUNOPx(o)->op_first)
  && c->op_type == OP_GV
  && GvSTASH(cGVOPx_gv(c)) == PL_defstash
  && strEQ(GvNAME(cGVOPx_gv(c)), "[");
}

STATIC void ab_neuter_dollar_bracket(pTHX_ OP *o) {
#define ab_neuter_dollar_bracket(o) ab_neuter_dollar_bracket(aTHX_ (o))
 OP *oldc, *newc;
 /*
  * Must replace the core's $[ with something that can accept assignment
  * of non-zero value and can be local()ised.  Simplest thing is a
  * different global variable.
  */
 oldc = cUNOPx(o)->op_first;
 newc = newGVOP(OP_GV, 0,
   gv_fetchpvs("arybase::leftbrack", GV_ADDMULTI, SVt_PVGV));
 cUNOPx(o)->op_first = newc;
 op_free(oldc);
}

STATIC void ab_process_assignment(pTHX_ OP *left, OP *right) {
#define ab_process_assignment(l, r) \
    ab_process_assignment(aTHX_ (l), (r))
 if (ab_op_is_dollar_bracket(left) && right->op_type == OP_CONST) {
  set_arybase_to(SvIV(cSVOPx_sv(right)));
  ab_neuter_dollar_bracket(left);
  Perl_ck_warner_d(aTHX_
   packWARN(WARN_DEPRECATED), "Use of assignment to $[ is deprecated"
  );
 }
}

STATIC OP *ab_ck_sassign(pTHX_ OP *o) {
 o = (*ab_old_ck_sassign)(aTHX_ o);
 if (o->op_type == OP_SASSIGN && FEATURE_ARYBASE_IS_ENABLED) {
  OP *right = cBINOPx(o)->op_first;
  OP *left = right->op_sibling;
  if (left) ab_process_assignment(left, right);
 }
 return o;
}

STATIC OP *ab_ck_aassign(pTHX_ OP *o) {
 o = (*ab_old_ck_aassign)(aTHX_ o);
 if (o->op_type == OP_AASSIGN && FEATURE_ARYBASE_IS_ENABLED) {
  OP *right = cBINOPx(o)->op_first;
  OP *left = cBINOPx(right->op_sibling)->op_first->op_sibling;
  right = cBINOPx(right)->op_first->op_sibling;
  ab_process_assignment(left, right);
 }
 return o;
}

void
tie(pTHX_ SV * const sv, SV * const obj, HV *const stash)
{
    SV *rv = newSV_type(SVt_RV);

    SvRV_set(rv, obj ? SvREFCNT_inc_simple_NN(obj) : newSV(0));
    SvROK_on(rv);
    sv_bless(rv, stash);

    sv_unmagic((SV *)sv, PERL_MAGIC_tiedscalar);
    sv_magic((SV *)sv, rv, PERL_MAGIC_tiedscalar, NULL, 0);
    SvREFCNT_dec(rv); /* As sv_magic increased it by one.  */
}

/* This function converts from base-based to 0-based an index to be passed
   as an argument. */
static IV
adjust_index(IV index, IV base)
{
 if (index >= base || index > -1) return index-base;
 return index;
}
/* This function converts from 0-based to base-based an index to
   be returned. */
static IV
adjust_index_r(IV index, IV base)
{
 return index + base;
}

#define replace_sv(sv,base) \
 ((sv) = sv_2mortal(newSViv(adjust_index(SvIV(sv),base))))
#define replace_sv_r(sv,base) \
 ((sv) = sv_2mortal(newSViv(adjust_index_r(SvIV(sv),base))))

static OP *ab_pp_basearg(pTHX) {
 dVAR; dSP;
 SV **firstp = NULL;
 SV **svp;
 UV count = 1;
 ab_op_info oi;
 ab_map_fetch(PL_op, &oi);
 
 switch (PL_op->op_type) {
 case OP_AELEM:
  firstp = SP;
  break;
 case OP_ASLICE:
  firstp = PL_stack_base + TOPMARK + 1;
  count = SP-firstp;
  break;
 case OP_LSLICE:
  firstp = PL_stack_base + *(PL_markstack_ptr-1)+1;
  count = TOPMARK - *(PL_markstack_ptr-1);
  if (GIMME != G_ARRAY) {
   firstp += count-1;
   count = 1;
  }
  break;
 case OP_SPLICE:
  if (SP - PL_stack_base - TOPMARK >= 2)
   firstp = PL_stack_base + TOPMARK + 2;
  else count = 0;
  break;
 case OP_SUBSTR:
  firstp = SP-(PL_op->op_private & 7)+2;
  break;
 default:
  DIE(aTHX_
     "panic: invalid op type for arybase.xs:ab_pp_basearg: %d",
      PL_op->op_type);
 }
 svp = firstp;
 while (count--) replace_sv(*svp,oi.base), svp++;
 return (*oi.old_pp)(aTHX);
}

static OP *ab_pp_av2arylen(pTHX) {
 dSP; dVAR;
 SV *sv;
 ab_op_info oi;
 OP *ret;
 ab_map_fetch(PL_op, &oi);
 ret = (*oi.old_pp)(aTHX);
 if (PL_op->op_flags & OPf_MOD || LVRET) {
  sv = newSV(0);
  tie(aTHX_ sv, TOPs, gv_stashpv("arybase::mg",1));
  SETs(sv);
 }
 else {
  SvGETMAGIC(TOPs);
  if (SvOK(TOPs)) replace_sv_r(TOPs, oi.base);
 }
 return ret;
}

static OP *ab_pp_keys(pTHX) {
 dVAR; dSP;
 ab_op_info oi;
 OP *retval;
 const I32 offset = SP - PL_stack_base;
 SV **svp;
 ab_map_fetch(PL_op, &oi);
 retval = (*oi.old_pp)(aTHX);
 if (GIMME_V == G_SCALAR) return retval;
 SPAGAIN;
 svp = PL_stack_base + offset;
 while (svp <= SP) replace_sv_r(*svp,oi.base), ++svp;
 return retval; 
}

static OP *ab_pp_each(pTHX) {
 dVAR; dSP;
 ab_op_info oi;
 OP *retval;
 const I32 offset = SP - PL_stack_base;
 ab_map_fetch(PL_op, &oi);
 retval = (*oi.old_pp)(aTHX);
 SPAGAIN;
 if (GIMME_V == G_SCALAR) {
  if (SvOK(TOPs)) replace_sv_r(TOPs,oi.base);
 }
 else if (offset < SP - PL_stack_base) replace_sv_r(TOPm1s,oi.base);
 return retval; 
}

static OP *ab_pp_index(pTHX) {
 dVAR; dSP;
 ab_op_info oi;
 OP *retval;
 ab_map_fetch(PL_op, &oi);
 if (MAXARG == 3 && TOPs) replace_sv(TOPs,oi.base);
 retval = (*oi.old_pp)(aTHX);
 SPAGAIN;
 replace_sv_r(TOPs,oi.base);
 return retval; 
}

static OP *ab_ck_base(pTHX_ OP *o)
{
 OP * (*old_ck)(pTHX_ OP *o) = 0;
 OP * (*new_pp)(pTHX)        = ab_pp_basearg;
 switch (o->op_type) {
 case OP_AELEM    : old_ck = ab_old_ck_aelem    ; break;
 case OP_ASLICE   : old_ck = ab_old_ck_aslice   ; break;
 case OP_LSLICE   : old_ck = ab_old_ck_lslice   ; break;
 case OP_AV2ARYLEN: old_ck = ab_old_ck_av2arylen; break;
 case OP_SPLICE   : old_ck = ab_old_ck_splice   ; break;
 case OP_KEYS     : old_ck = ab_old_ck_keys     ; break;
 case OP_EACH     : old_ck = ab_old_ck_each     ; break;
 case OP_SUBSTR   : old_ck = ab_old_ck_substr   ; break;
 case OP_RINDEX   : old_ck = ab_old_ck_rindex   ; break;
 case OP_INDEX    : old_ck = ab_old_ck_index    ; break;
 case OP_POS      : old_ck = ab_old_ck_pos      ; break;
 default:
  DIE(aTHX_
     "panic: invalid op type for arybase.xs:ab_ck_base: %d",
      PL_op->op_type);
 }
 o = (*old_ck)(aTHX_ o);
 if (!FEATURE_ARYBASE_IS_ENABLED) return o;
 /* We need two switch blocks, as the type may have changed. */
 switch (o->op_type) {
 case OP_AELEM    :
 case OP_ASLICE   :
 case OP_LSLICE   :
 case OP_SPLICE   :
 case OP_SUBSTR   : break;
 case OP_POS      :
 case OP_AV2ARYLEN: new_pp = ab_pp_av2arylen    ; break;
 case OP_AKEYS    : new_pp = ab_pp_keys         ; break;
 case OP_AEACH    : new_pp = ab_pp_each         ; break;
 case OP_RINDEX   :
 case OP_INDEX    : new_pp = ab_pp_index        ; break;
 default: return o;
 }
 {
  IV const base = current_base();
  if (base) {
   ab_map_store(o, o->op_ppaddr, base);
   o->op_ppaddr = new_pp;
   /* Break the aelemfast optimisation */
   if (o->op_type == OP_AELEM &&
       cBINOPo->op_first->op_sibling->op_type == OP_CONST) {
     cBINOPo->op_first->op_sibling
      = newUNOP(OP_NULL,0,cBINOPo->op_first->op_sibling);
   }
  }
  else ab_map_delete(o);
 }
 return o;
}


STATIC U32 ab_initialized = 0;

/* --- XS ------------------------------------------------------------- */

#line 404 "arybase.c"
#ifndef PERL_UNUSED_VAR
#  define PERL_UNUSED_VAR(var) if (0) var = var
#endif

#ifndef dVAR
#  define dVAR		dNOOP
#endif


/* This stuff is not part of the API! You have been warned. */
#ifndef PERL_VERSION_DECIMAL
#  define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#endif
#ifndef PERL_DECIMAL_VERSION
#  define PERL_DECIMAL_VERSION \
	  PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#endif
#ifndef PERL_VERSION_GE
#  define PERL_VERSION_GE(r,v,s) \
	  (PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))
#endif
#ifndef PERL_VERSION_LE
#  define PERL_VERSION_LE(r,v,s) \
	  (PERL_DECIMAL_VERSION <= PERL_VERSION_DECIMAL(r,v,s))
#endif

/* XS_INTERNAL is the explicit static-linkage variant of the default
 * XS macro.
 *
 * XS_EXTERNAL is the same as XS_INTERNAL except it does not include
 * "STATIC", ie. it exports XSUB symbols. You probably don't want that
 * for anything but the BOOT XSUB.
 *
 * See XSUB.h in core!
 */


/* TODO: This might be compatible further back than 5.10.0. */
#if PERL_VERSION_GE(5, 10, 0) && PERL_VERSION_LE(5, 15, 1)
#  undef XS_EXTERNAL
#  undef XS_INTERNAL
#  if defined(__CYGWIN__) && defined(USE_DYNAMIC_LOADING)
#    define XS_EXTERNAL(name) __declspec(dllexport) XSPROTO(name)
#    define XS_INTERNAL(name) STATIC XSPROTO(name)
#  endif
#  if defined(__SYMBIAN32__)
#    define XS_EXTERNAL(name) EXPORT_C XSPROTO(name)
#    define XS_INTERNAL(name) EXPORT_C STATIC XSPROTO(name)
#  endif
#  ifndef XS_EXTERNAL
#    if defined(HASATTRIBUTE_UNUSED) && !defined(__cplusplus)
#      define XS_EXTERNAL(name) void name(pTHX_ CV* cv __attribute__unused__)
#      define XS_INTERNAL(name) STATIC void name(pTHX_ CV* cv __attribute__unused__)
#    else
#      ifdef __cplusplus
#        define XS_EXTERNAL(name) extern "C" XSPROTO(name)
#        define XS_INTERNAL(name) static XSPROTO(name)
#      else
#        define XS_EXTERNAL(name) XSPROTO(name)
#        define XS_INTERNAL(name) STATIC XSPROTO(name)
#      endif
#    endif
#  endif
#endif

/* perl >= 5.10.0 && perl <= 5.15.1 */


/* The XS_EXTERNAL macro is used for functions that must not be static
 * like the boot XSUB of a module. If perl didn't have an XS_EXTERNAL
 * macro defined, the best we can do is assume XS is the same.
 * Dito for XS_INTERNAL.
 */
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL(name) XS(name)
#endif
#ifndef XS_INTERNAL
#  define XS_INTERNAL(name) XS(name)
#endif

/* Now, finally, after all this mess, we want an ExtUtils::ParseXS
 * internal macro that we're free to redefine for varying linkage due
 * to the EXPORT_XSUB_SYMBOLS XS keyword. This is internal, use
 * XS_EXTERNAL(name) or XS_INTERNAL(name) in your code if you need to!
 */

#undef XS_EUPXS
#if defined(PERL_EUPXS_ALWAYS_EXPORT)
#  define XS_EUPXS(name) XS_EXTERNAL(name)
#else
   /* default to internal */
#  define XS_EUPXS(name) XS_INTERNAL(name)
#endif

#ifndef PERL_ARGS_ASSERT_CROAK_XS_USAGE
#define PERL_ARGS_ASSERT_CROAK_XS_USAGE assert(cv); assert(params)

/* prototype to pass -Wmissing-prototypes */
STATIC void
S_croak_xs_usage(pTHX_ const CV *const cv, const char *const params);

STATIC void
S_croak_xs_usage(pTHX_ const CV *const cv, const char *const params)
{
    const GV *const gv = CvGV(cv);

    PERL_ARGS_ASSERT_CROAK_XS_USAGE;

    if (gv) {
        const char *const gvname = GvNAME(gv);
        const HV *const stash = GvSTASH(gv);
        const char *const hvname = stash ? HvNAME(stash) : NULL;

        if (hvname)
            Perl_croak(aTHX_ "Usage: %s::%s(%s)", hvname, gvname, params);
        else
            Perl_croak(aTHX_ "Usage: %s(%s)", gvname, params);
    } else {
        /* Pants. I don't think that it should be possible to get here. */
        Perl_croak(aTHX_ "Usage: CODE(0x%"UVxf")(%s)", PTR2UV(cv), params);
    }
}
#undef  PERL_ARGS_ASSERT_CROAK_XS_USAGE

#ifdef PERL_IMPLICIT_CONTEXT
#define croak_xs_usage(a,b)    S_croak_xs_usage(aTHX_ a,b)
#else
#define croak_xs_usage        S_croak_xs_usage
#endif

#endif

/* NOTE: the prototype of newXSproto() is different in versions of perls,
 * so we define a portable version of newXSproto()
 */
#ifdef newXS_flags
#define newXSproto_portable(name, c_impl, file, proto) newXS_flags(name, c_impl, file, proto, 0)
#else
#define newXSproto_portable(name, c_impl, file, proto) (PL_Sv=(SV*)newXS(name, c_impl, file), sv_setpv(PL_Sv, proto), (CV*)PL_Sv)
#endif /* !defined(newXS_flags) */

#line 546 "arybase.c"

XS_EUPXS(XS_arybase_FETCH); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_arybase_FETCH)
{
    dVAR; dXSARGS;
    PERL_UNUSED_VAR(cv); /* -W */
    PERL_UNUSED_VAR(ax); /* -Wall */
    SP -= items;
    {
#line 429 "arybase.xs"
	SV *ret = FEATURE_ARYBASE_IS_ENABLED
		   ? cop_hints_fetch_pvs(PL_curcop, "$[", 0)
		   : 0;
#line 560 "arybase.c"
#line 433 "arybase.xs"
	if (!ret || !SvOK(ret)) mXPUSHi(0);
	else XPUSHs(ret);
#line 564 "arybase.c"
	PUTBACK;
	return;
    }
}


XS_EUPXS(XS_arybase_STORE); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_arybase_STORE)
{
    dVAR; dXSARGS;
    if (items != 2)
       croak_xs_usage(cv,  "sv, newbase");
    {
	SV *	sv = ST(0)
;
	IV	newbase = (IV)SvIV(ST(1))
;
#line 439 "arybase.xs"
      if (FEATURE_ARYBASE_IS_ENABLED) {
	SV *base = cop_hints_fetch_pvs(PL_curcop, "$[", 0);
	if (SvOK(base) ? SvIV(base) == newbase : !newbase) XSRETURN_EMPTY;
	Perl_croak(aTHX_ "That use of $[ is unsupported");
      }
      else if (newbase)
	Perl_croak(aTHX_ "Assigning non-zero to $[ is no longer possible");
#line 590 "arybase.c"
    }
    XSRETURN_EMPTY;
}


XS_EUPXS(XS_arybase__mg_FETCH); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_arybase__mg_FETCH)
{
    dVAR; dXSARGS;
    if (items != 1)
       croak_xs_usage(cv,  "sv");
    PERL_UNUSED_VAR(ax); /* -Wall */
    SP -= items;
    {
	SV *	sv = ST(0)
;
#line 454 "arybase.xs"
	if (!SvROK(sv) || SvTYPE(SvRV(sv)) >= SVt_PVAV)
	    Perl_croak(aTHX_ "Not a SCALAR reference");
	{
	    SV *base = FEATURE_ARYBASE_IS_ENABLED
			 ? cop_hints_fetch_pvs(PL_curcop, "$[", 0)
			 : 0;
	    SvGETMAGIC(SvRV(sv));
	    if (!SvOK(SvRV(sv))) XSRETURN_UNDEF;
	    mXPUSHi(adjust_index_r(
		SvIV_nomg(SvRV(sv)), base&&SvOK(base)?SvIV(base):0
	    ));
	}
#line 620 "arybase.c"
	PUTBACK;
	return;
    }
}


XS_EUPXS(XS_arybase__mg_STORE); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_arybase__mg_STORE)
{
    dVAR; dXSARGS;
    if (items != 2)
       croak_xs_usage(cv,  "sv, newbase");
    {
	SV *	sv = ST(0)
;
	SV *	newbase = ST(1)
;
#line 470 "arybase.xs"
	if (!SvROK(sv) || SvTYPE(SvRV(sv)) >= SVt_PVAV)
	    Perl_croak(aTHX_ "Not a SCALAR reference");
	{
	    SV *base = FEATURE_ARYBASE_IS_ENABLED
			? cop_hints_fetch_pvs(PL_curcop, "$[", 0)
			: 0;
	    SvGETMAGIC(newbase);
	    if (!SvOK(newbase)) SvSetMagicSV(SvRV(sv),&PL_sv_undef);
	    else 
		sv_setiv_mg(
		   SvRV(sv),
		   adjust_index(
		      SvIV_nomg(newbase), base&&SvOK(base)?SvIV(base):0
		   )
		);
	}
#line 655 "arybase.c"
    }
    XSRETURN_EMPTY;
}

#ifdef __cplusplus
extern "C"
#endif
XS_EXTERNAL(boot_arybase); /* prototype to pass -Wmissing-prototypes */
XS_EXTERNAL(boot_arybase)
{
    dVAR; dXSARGS;
#if (PERL_REVISION == 5 && PERL_VERSION < 9)
    char* file = __FILE__;
#else
    const char* file = __FILE__;
#endif

    PERL_UNUSED_VAR(cv); /* -W */
    PERL_UNUSED_VAR(items); /* -W */
#ifdef XS_APIVERSION_BOOTCHECK
    XS_APIVERSION_BOOTCHECK;
#endif
    XS_VERSION_BOOTCHECK;

        newXS("arybase::FETCH", XS_arybase_FETCH, file);
        newXS("arybase::STORE", XS_arybase_STORE, file);
        newXS("arybase::mg::FETCH", XS_arybase__mg_FETCH, file);
        newXS("arybase::mg::STORE", XS_arybase__mg_STORE, file);

    /* Initialisation Section */

#line 398 "arybase.xs"
{
    GV *const gv = gv_fetchpvn("[", 1, GV_ADDMULTI|GV_NOTQUAL, SVt_PV);
    sv_unmagic(GvSV(gv), PERL_MAGIC_sv); /* This is *our* scalar now! */
    tie(aTHX_ GvSV(gv), NULL, GvSTASH(CvGV(cv)));

    if (!ab_initialized++) {
	ab_op_map = ptable_new();
#ifdef USE_ITHREADS
	MUTEX_INIT(&ab_op_map_mutex);
#endif
#define check(uc,lc,ck) \
		wrap_op_checker(OP_##uc, ab_ck_##ck, &ab_old_ck_##lc)
	check(SASSIGN,  sassign,  sassign);
	check(AASSIGN,  aassign,  aassign);
	check(AELEM,    aelem,    base);
	check(ASLICE,   aslice,   base);
	check(LSLICE,   lslice,   base);
	check(AV2ARYLEN,av2arylen,base);
	check(SPLICE,   splice,   base);
	check(KEYS,     keys,     base);
	check(EACH,     each,     base);
	check(SUBSTR,   substr,   base);
	check(RINDEX,   rindex,   base);
	check(INDEX,    index,    base);
	check(POS,      pos,      base);
    }
}

#line 716 "arybase.c"

    /* End of Initialisation Section */

#if (PERL_REVISION == 5 && PERL_VERSION >= 9)
  if (PL_unitcheckav)
       call_list(PL_scopestack_ix, PL_unitcheckav);
#endif
    XSRETURN_YES;
}

