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
 *      Fixed point math routines.
 *
 *      By Shawn Hargreaves.
 *
 *      See readme.txt for copyright information.
 */


#ifndef ALLEGRO_FMATH_H
#define ALLEGRO_FMATH_H

#ifdef __cplusplus
   extern "C" {
#endif

#include "base.h"
#include "fixed.h"

AL_FUNC(fixed, fsqrt, (fixed x));
AL_FUNC(fixed, fhypot, (fixed x, fixed y));
AL_FUNC(fixed, fatan, (fixed x));
AL_FUNC(fixed, fatan2, (fixed y, fixed x));

AL_ARRAY(fixed, _cos_tbl);
AL_ARRAY(fixed, _tan_tbl);
AL_ARRAY(fixed, _acos_tbl);

#include "inline/fmaths.inl"

#ifdef __cplusplus
   }
#endif

#endif          /* ifndef ALLEGRO_FMATH_H */

