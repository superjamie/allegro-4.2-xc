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
 *      C++ wrapper for fixed point math type.
 *
 *      By Shawn Hargreaves.
 *
 *      See readme.txt for copyright information.
 */


#ifndef ALLEGRO_FIX_H
#define ALLEGRO_FIX_H

#ifdef __cplusplus

#include "fixed.h"
#include "fmaths.h"

class fix      /* C++ wrapper for the fixed point routines */
{
public:
   fixed v;

   fix()                                     { }
   fix(const fix &x)                         { v = x.v; }
   fix(const int x)                          { v = itofix(x); }
   fix(const long x)                         { v = itofix(x); }
   fix(const unsigned int x)                 { v = itofix(x); }
   fix(const unsigned long x)                { v = itofix(x); }
   fix(const float x)                        { v = ftofix(x); }
   fix(const double x)                       { v = ftofix(x); }

   operator int() const                      { return fixtoi(v); }
   operator long() const                     { return fixtoi(v); }
   operator unsigned int() const             { return fixtoi(v); }
   operator unsigned long() const            { return fixtoi(v); }
   operator float() const                    { return fixtof(v); }
   operator double() const                   { return fixtof(v); }

   fix& operator = (const fix &x)            { v = x.v;           return *this;
}
   fix& operator = (const int x)             { v = itofix(x);     return *this;
}
   fix& operator = (const long x)            { v = itofix(x);     return *this;
}
   fix& operator = (const unsigned int x)    { v = itofix(x);     return *this;
}
   fix& operator = (const unsigned long x)   { v = itofix(x);     return *this;
}
   fix& operator = (const float x)           { v = ftofix(x);     return *this;
}
   fix& operator = (const double x)          { v = ftofix(x);     return *this;
}

   fix& operator +=  (const fix x)           { v += x.v;          return *this;
}
   fix& operator +=  (const int x)           { v += itofix(x);    return *this;
}
   fix& operator +=  (const long x)          { v += itofix(x);    return *this;
}
   fix& operator +=  (const float x)         { v += ftofix(x);    return *this;
}
   fix& operator +=  (const double x)        { v += ftofix(x);    return *this;
}

   fix& operator -=  (const fix x)           { v -= x.v;          return *this;
}
   fix& operator -=  (const int x)           { v -= itofix(x);    return *this;
}
   fix& operator -=  (const long x)          { v -= itofix(x);    return *this;
}
   fix& operator -=  (const float x)         { v -= ftofix(x);    return *this;
}
   fix& operator -=  (const double x)        { v -= ftofix(x);    return *this;
}

   fix& operator *=  (const fix x)           { v = fmul(v, x.v);           return *this; }
   fix& operator *=  (const int x)           { v *= x;                     return *this; }
   fix& operator *=  (const long x)          { v *= x;                     return *this; }
   fix& operator *=  (const float x)         { v = ftofix(fixtof(v) * x);  return *this; }
   fix& operator *=  (const double x)        { v = ftofix(fixtof(v) * x);  return *this; }

   fix& operator /=  (const fix x)           { v = fdiv(v, x.v);           return *this; }
   fix& operator /=  (const int x)           { v /= x;                     return *this; }
   fix& operator /=  (const long x)          { v /= x;                     return *this; }
   fix& operator /=  (const float x)         { v = ftofix(fixtof(v) / x);  return *this; }
   fix& operator /=  (const double x)        { v = ftofix(fixtof(v) / x);  return *this; }

   fix& operator <<= (const int x)           { v <<= x;           return *this;
}
   fix& operator >>= (const int x)           { v >>= x;           return *this;
}

   fix& operator ++ ()                       { v += itofix(1);    return *this;
}
   fix& operator -- ()                       { v -= itofix(1);    return *this;
}

   fix operator ++ (int)                     { fix t;  t.v = v;   v += itofix(1);  return t; }
   fix operator -- (int)                     { fix t;  t.v = v;   v -= itofix(1);  return t; }

   fix operator - () const                   { fix t;  t.v = -v;  return t; }

   inline friend fix operator +  (const fix x, const fix y);
   inline friend fix operator +  (const fix x, const int y);
   inline friend fix operator +  (const int x, const fix y);
   inline friend fix operator +  (const fix x, const long y);
   inline friend fix operator +  (const long x, const fix y);
   inline friend fix operator +  (const fix x, const float y);
   inline friend fix operator +  (const float x, const fix y);
   inline friend fix operator +  (const fix x, const double y);
   inline friend fix operator +  (const double x, const fix y);

   inline friend fix operator -  (const fix x, const fix y);
   inline friend fix operator -  (const fix x, const int y);
   inline friend fix operator -  (const int x, const fix y);
   inline friend fix operator -  (const fix x, const long y);
   inline friend fix operator -  (const long x, const fix y);
   inline friend fix operator -  (const fix x, const float y);
   inline friend fix operator -  (const float x, const fix y);
   inline friend fix operator -  (const fix x, const double y);
   inline friend fix operator -  (const double x, const fix y);

   inline friend fix operator *  (const fix x, const fix y);
   inline friend fix operator *  (const fix x, const int y);
   inline friend fix operator *  (const int x, const fix y);
   inline friend fix operator *  (const fix x, const long y);
   inline friend fix operator *  (const long x, const fix y);
   inline friend fix operator *  (const fix x, const float y);
   inline friend fix operator *  (const float x, const fix y);
   inline friend fix operator *  (const fix x, const double y);
   inline friend fix operator *  (const double x, const fix y);

   inline friend fix operator /  (const fix x, const fix y);
   inline friend fix operator /  (const fix x, const int y);
   inline friend fix operator /  (const int x, const fix y);
   inline friend fix operator /  (const fix x, const long y);
   inline friend fix operator /  (const long x, const fix y);
   inline friend fix operator /  (const fix x, const float y);
   inline friend fix operator /  (const float x, const fix y);
   inline friend fix operator /  (const fix x, const double y);
   inline friend fix operator /  (const double x, const fix y);

   inline friend fix operator << (const fix x, const int y);
   inline friend fix operator >> (const fix x, const int y);

   inline friend int operator == (const fix x, const fix y);
   inline friend int operator == (const fix x, const int y);
   inline friend int operator == (const int x, const fix y);
   inline friend int operator == (const fix x, const long y);
   inline friend int operator == (const long x, const fix y);
   inline friend int operator == (const fix x, const float y);
   inline friend int operator == (const float x, const fix y);
   inline friend int operator == (const fix x, const double y);
   inline friend int operator == (const double x, const fix y);

   inline friend int operator != (const fix x, const fix y);
   inline friend int operator != (const fix x, const int y);
   inline friend int operator != (const int x, const fix y);
   inline friend int operator != (const fix x, const long y);
   inline friend int operator != (const long x, const fix y);
   inline friend int operator != (const fix x, const float y);
   inline friend int operator != (const float x, const fix y);
   inline friend int operator != (const fix x, const double y);
   inline friend int operator != (const double x, const fix y);

   inline friend int operator <  (const fix x, const fix y);
   inline friend int operator <  (const fix x, const int y);
   inline friend int operator <  (const int x, const fix y);
   inline friend int operator <  (const fix x, const long y);
   inline friend int operator <  (const long x, const fix y);
   inline friend int operator <  (const fix x, const float y);
   inline friend int operator <  (const float x, const fix y);
   inline friend int operator <  (const fix x, const double y);
   inline friend int operator <  (const double x, const fix y);

   inline friend int operator >  (const fix x, const fix y);
   inline friend int operator >  (const fix x, const int y);
   inline friend int operator >  (const int x, const fix y);
   inline friend int operator >  (const fix x, const long y);
   inline friend int operator >  (const long x, const fix y);
   inline friend int operator >  (const fix x, const float y);
   inline friend int operator >  (const float x, const fix y);
   inline friend int operator >  (const fix x, const double y);
   inline friend int operator >  (const double x, const fix y);

   inline friend int operator <= (const fix x, const fix y);
   inline friend int operator <= (const fix x, const int y);
   inline friend int operator <= (const int x, const fix y);
   inline friend int operator <= (const fix x, const long y);
   inline friend int operator <= (const long x, const fix y);
   inline friend int operator <= (const fix x, const float y);
   inline friend int operator <= (const float x, const fix y);
   inline friend int operator <= (const fix x, const double y);
   inline friend int operator <= (const double x, const fix y);

   inline friend int operator >= (const fix x, const fix y);
   inline friend int operator >= (const fix x, const int y);
   inline friend int operator >= (const int x, const fix y);
   inline friend int operator >= (const fix x, const long y);
   inline friend int operator >= (const long x, const fix y);
   inline friend int operator >= (const fix x, const float y);
   inline friend int operator >= (const float x, const fix y);
   inline friend int operator >= (const fix x, const double y);
   inline friend int operator >= (const double x, const fix y);

   inline friend fix sqrt(fix x);
   inline friend fix cos(fix x);
   inline friend fix sin(fix x);
   inline friend fix tan(fix x);
   inline friend fix acos(fix x);
   inline friend fix asin(fix x);
   inline friend fix atan(fix x);
   inline friend fix atan2(fix x, fix y);
};

#include "inline/fix.inl"

#endif          /* ifdef __cplusplus */

#endif          /* ifndef ALLEGRO_FIX_H */

