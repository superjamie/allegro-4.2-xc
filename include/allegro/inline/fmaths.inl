/*         ______   ___    ___
 *        /\  _  \ /\_ \  /\_ \
 *        \ \ \L\ \\//\ \ \//\ \      __     __   _ __   ___
 *         \ \  __ \ \ \ \  \ \ \   /'__`\ /'_ `\/\`'__\/ __`\
 *          \ \ \/\ \ \_\ \_ \_\ \_/\  __//\ \L\ \ \ \//\ \L\ \
 *           \ \_\ \_\/\____\/\____\ \____\ \____ \ \_\\ \____/
 *            \/_/\/_/\/____/\/____/\/____/\/___L\ \/_/ \/___/
 *                                           /\____/
 *                                           \_/__/
 *
 *      Fixed point math inline functions (generic C).
 *
 *      By Shawn Hargreaves.
 *
 *      See readme.txt for copyright information.
 */


#ifndef ALLEGRO_FMATHS_INL
#define ALLEGRO_FMATHS_INL

#ifdef __cplusplus
   extern "C" {
#endif

#include "mathasm.inl"

/* ftofix and fixtof are used in generic C versions of fmul and fdiv */
AL_INLINE(fixed, ftofix, (double x),
{
   if (x > 32767.0) {
      *allegro_errno = ERANGE;
      return 0x7FFFFFFF;
   }

   if (x < -32767.0) {
      *allegro_errno = ERANGE;
      return -0x7FFFFFFF;
   }

   return (long)(x * 65536.0 + (x < 0 ? -0.5 : 0.5));
})


AL_INLINE(double, fixtof, (fixed x),
{
   return (double)x / 65536.0;
})


#ifdef ALLEGRO_NO_ASM

   /* use generic C versions */

AL_INLINE(fixed, fadd, (fixed x, fixed y),
{
   fixed result = x + y;

   if (result >= 0) {
      if ((x < 0) && (y < 0)) {
         *allegro_errno = ERANGE;
         return -0x7FFFFFFF;
      }
      else
         return result;
   }
   else {
      if ((x > 0) && (y > 0)) {
         *allegro_errno = ERANGE;
         return 0x7FFFFFFF;
      }
      else
         return result;
   }
})


AL_INLINE(fixed, fsub, (fixed x, fixed y),
{
   fixed result = x - y;

   if (result >= 0) {
      if ((x < 0) && (y > 0)) {
         *allegro_errno = ERANGE;
         return -0x7FFFFFFF;
      }
      else
         return result;
   }
   else {
      if ((x > 0) && (y < 0)) {
         *allegro_errno = ERANGE;
         return 0x7FFFFFFF;
      }
      else
         return result;
   }
})


AL_INLINE(fixed, fmul, (fixed x, fixed y),
 {
   return ftofix(fixtof(x) * fixtof(y));
})


AL_INLINE(fixed, fdiv, (fixed x, fixed y),
{
   if (y == 0) {
      *allegro_errno = ERANGE;
      return (x < 0) ? -0x7FFFFFFF : 0x7FFFFFFF;
   }
   else
      return ftofix(fixtof(x) / fixtof(y));
})


AL_INLINE(int, fceil, (fixed x),
{
   x += 0xFFFF;
   if (x >= 0x80000000) {
      *allegro_errno = ERANGE;
      return 0x7FFF;
   }

   return (x >> 16);
})

#endif      /* C vs. inline asm */


AL_INLINE(fixed, itofix, (int x),
{
   return x << 16;
})


AL_INLINE(int, fixtoi, (fixed x),
{
   return (x >> 16) + ((x & 0x8000) >> 15);
})


AL_INLINE(fixed, fcos, (fixed x),
{
   return _cos_tbl[((x + 0x4000) >> 15) & 0x1FF];
})


AL_INLINE(fixed, fsin, (fixed x),
{
   return _cos_tbl[((x - 0x400000 + 0x4000) >> 15) & 0x1FF];
})


AL_INLINE(fixed, ftan, (fixed x),
{
   return _tan_tbl[((x + 0x4000) >> 15) & 0xFF];
})


AL_INLINE(fixed, facos, (fixed x),
{
   if ((x < -65536) || (x > 65536)) {
      *allegro_errno = EDOM;
      return 0;
   }

   return _acos_tbl[(x+65536+127)>>8];
})


AL_INLINE(fixed, fasin, (fixed x),
{
   if ((x < -65536) || (x > 65536)) {
      *allegro_errno = EDOM;
      return 0;
   }

   return 0x00400000 - _acos_tbl[(x+65536+127)>>8];
})

#ifdef __cplusplus
   }
#endif

#endif          /* ifndef ALLEGRO_FMATHS_INL */

