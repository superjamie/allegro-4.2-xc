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
 *      MacOS X system driver.
 *
 *      By Angelo Mottola.
 *
 *      See readme.txt for copyright information.
 */


#include "allegro.h"
#include "allegro/internal/aintern.h"
#include "allegro/platform/aintosx.h"

#ifndef ALLEGRO_MACOSX
   #error something is wrong with the makefile
#endif


static int osx_sys_init(void);
static void osx_sys_exit(void);
static void osx_sys_message(AL_CONST char *);
static void osx_sys_get_executable_name(char *, int);
static int osx_sys_find_resource(char *, AL_CONST char *, int);
static void osx_sys_set_window_title(AL_CONST char *);
static int osx_sys_set_close_button_callback(void (*proc)(void));
static int osx_sys_set_display_switch_mode(int mode);
static void osx_sys_get_gfx_safe_mode(int *driver, struct GFX_MODE *mode);
static void osx_sys_yield_timeslice(void);
static int osx_sys_desktop_color_depth(void);
static int osx_sys_get_desktop_resolution(int *width, int *height);


#define WINDOW_TITLE_SIZE     256
#define MESSAGE_STRING_SIZE   4096


/* Global variables */
int    __crt0_argc;
char **__crt0_argv;
pthread_mutex_t osx_event_mutex;
NSCursor *osx_cursor = NULL;
NSWindow *osx_window = NULL;
char osx_window_title[WINDOW_TITLE_SIZE];
void (*osx_window_close_hook)(void) = NULL;
int osx_gfx_mode = OSX_GFX_NONE;


static RETSIGTYPE (*old_sig_abrt)(int num);
static RETSIGTYPE (*old_sig_fpe)(int num);
static RETSIGTYPE (*old_sig_ill)(int num);
static RETSIGTYPE (*old_sig_segv)(int num);
static RETSIGTYPE (*old_sig_term)(int num);
static RETSIGTYPE (*old_sig_int)(int num);
static RETSIGTYPE (*old_sig_quit)(int num);

static NSBundle *app_bundle = NULL;
static unsigned char *cursor_data = NULL;
static NSBitmapImageRep *cursor_rep = NULL;
static NSImage *cursor_image = NULL;
static int old_x, old_y;
static int buttons;
static int skip_events_processing = FALSE;


SYSTEM_DRIVER system_macosx =
{
   SYSTEM_MACOSX,
   empty_string,
   empty_string,
   "MacOS X",
   osx_sys_init,
   osx_sys_exit,
   osx_sys_get_executable_name,
   osx_sys_find_resource,
   osx_sys_set_window_title,
   osx_sys_set_close_button_callback,
   osx_sys_message,
   NULL,  /* AL_METHOD(void, assert, (AL_CONST char *msg)); */
   NULL,  /* AL_METHOD(void, save_console_state, (void)); */
   NULL,  /* AL_METHOD(void, restore_console_state, (void)); */
   NULL,  /* AL_METHOD(struct BITMAP *, create_bitmap, (int color_depth, int width, int height)); */
   NULL,  /* AL_METHOD(void, created_bitmap, (struct BITMAP *bmp)); */
   NULL,  /* AL_METHOD(struct BITMAP *, create_sub_bitmap, (struct BITMAP *parent, int x, int y, int width, int height)); */
   NULL,  /* AL_METHOD(void, created_sub_bitmap, (struct BITMAP *bmp, struct BITMAP *parent)); */
   NULL,  /* AL_METHOD(int, destroy_bitmap, (struct BITMAP *bitmap)); */
   NULL,  /* AL_METHOD(void, read_hardware_palette, (void)); */
   NULL,  /* AL_METHOD(void, set_palette_range, (AL_CONST struct RGB *p, int from, int to, int retracesync)); */
   NULL,  /* AL_METHOD(struct GFX_VTABLE *, get_vtable, (int color_depth)); */
   osx_sys_set_display_switch_mode,
   NULL,  /* AL_METHOD(void, display_switch_lock, (int lock, int foreground)); */
   osx_sys_desktop_color_depth,
   osx_sys_get_desktop_resolution,
   osx_sys_get_gfx_safe_mode,
   osx_sys_yield_timeslice,
   _unix_create_mutex,
   _unix_destroy_mutex,
   _unix_lock_mutex,
   _unix_unlock_mutex,
   NULL,  /* AL_METHOD(_DRIVER_INFO *, gfx_drivers, (void)); */
   NULL,  /* AL_METHOD(_DRIVER_INFO *, digi_drivers, (void)); */
   NULL,  /* AL_METHOD(_DRIVER_INFO *, midi_drivers, (void)); */
   NULL,  /* AL_METHOD(_DRIVER_INFO *, keyboard_drivers, (void)); */
   NULL,  /* AL_METHOD(_DRIVER_INFO *, mouse_drivers, (void)); */
   NULL,  /* AL_METHOD(_DRIVER_INFO *, joystick_drivers, (void)); */
   NULL,  /* AL_METHOD(_DRIVER_INFO *, timer_drivers, (void)); */
};



/* osx_signal_handler:
 *  Used to trap various signals, to make sure things get shut down cleanly.
 */
static RETSIGTYPE osx_signal_handler(int num)
{
   pthread_mutex_unlock(&osx_event_mutex);
   pthread_mutex_destroy(&osx_event_mutex);
   pthread_mutex_unlock(&osx_window_mutex);
   pthread_mutex_destroy(&osx_window_mutex);
   
   allegro_exit();
   fprintf(stderr, "Shutting down Allegro due to signal #%d\n", num);
   raise(num);
}



/* osx_event_handler:
 *  Event handling function; gets repeatedly called inside a dedicated thread.
 */
void osx_event_handler()
{
   NSEvent *event;
   NSDate *distantPast = [NSDate distantPast];
   NSPoint point;
   NSRect frame, view;
   CGMouseDelta fdx, fdy;
   int x, y, dx = 0, dy = 0, dz = 0;
   
   while (1) {
      event = [NSApp nextEventMatchingMask: NSAnyEventMask
         untilDate: distantPast
         inMode: NSDefaultRunLoopMode
         dequeue: YES];
      if (event == nil)
         break;
      
      if ((skip_events_processing) || (osx_gfx_mode == OSX_GFX_NONE)) {
         [NSApp sendEvent: event];
	 continue;
      }

      if (osx_window) {
         point = [event locationInWindow];
         frame = [[osx_window contentView] frame];
         view = NSMakeRect(0, 0, gfx_driver->w, gfx_driver->h);
      }
      
      switch ([event type]) {
	 
         case NSKeyDown:
	    if (_keyboard_installed)
	       osx_keyboard_handler(TRUE, event);
	    break;
	
         case NSKeyUp:
	    if (_keyboard_installed)
	       osx_keyboard_handler(FALSE, event);
	    break;

         case NSFlagsChanged:
	    if (_keyboard_installed)
	       osx_keyboard_modifiers([event modifierFlags]);
	    break;
	 
         case NSLeftMouseDown:
         case NSOtherMouseDown:
         case NSRightMouseDown:
	    if (![NSApp isActive]) {
	       /* App is regaining focus */
	       if (_mouse_installed) {
	          if ((osx_window) && (NSPointInRect(point, view))) {
                     _mouse_x = old_x = point.x;
	             _mouse_y = old_y = frame.size.height - point.y;
		     _mouse_b = 0;
	             _handle_mouse_input();
                     _mouse_on = TRUE;
	          }
	       }
	       if (osx_window)
                  [osx_window invalidateCursorRectsForView: [osx_window contentView]];
	       if (_keyboard_installed)
	          osx_keyboard_focused(TRUE, 0);
	       _switch_in();
	       [NSApp sendEvent: event];
	       break;
	    }
	    /* fallthrough */
         case NSLeftMouseUp:
         case NSOtherMouseUp:
         case NSRightMouseUp:
	    if ((!osx_window) || (NSPointInRect(point, view))) {
	       /* Deliver mouse downs only if cursor is on the window */
	       buttons |= (([event type] == NSLeftMouseDown) ? 0x1 : 0);
	       buttons |= (([event type] == NSRightMouseDown) ? 0x2 : 0);
	       buttons |= (([event type] == NSOtherMouseDown) ? 0x4 : 0);
	    }
	    buttons &= ~(([event type] == NSLeftMouseUp) ? 0x1 : 0);
	    buttons &= ~(([event type] == NSRightMouseUp) ? 0x2 : 0);
	    buttons &= ~(([event type] == NSOtherMouseUp) ? 0x4 : 0);
	    if (_mouse_installed)
               osx_mouse_handler(0, 0, 0, buttons);
	    [NSApp sendEvent: event];
	    break;
	    
         case NSLeftMouseDragged:
         case NSRightMouseDragged:
         case NSOtherMouseDragged:
         case NSMouseMoved:
	    if (osx_window) {
               if (NSPointInRect(point, view)) {
	          x = point.x;
	          y = (frame.size.height - point.y);
	          dx += x - old_x;
	          dy += y - old_y;
	          old_x = x;
	          old_y = y;
	       }
	    }
	    else
	       CGGetLastMouseDelta(&dx, &dy);
	    [NSApp sendEvent: event];
	    break;
            
         case NSScrollWheel:
	    dz += [event deltaY];
            break;
	    
	 case NSMouseEntered:
	    if (([event trackingNumber] == osx_mouse_tracking_rect) && ([NSApp isActive])) {
	       if (_mouse_installed) {
                  _mouse_x = old_x = point.x;
	          _mouse_y = old_y = frame.size.height - point.y;
		  _mouse_b = 0;
	          _handle_mouse_input();
                  _mouse_on = TRUE;
	       }
	    }
	    else
	       [NSApp sendEvent: event];
	    break;
            
	 case NSMouseExited:
	    if ([event trackingNumber] == osx_mouse_tracking_rect) {
	       if (_mouse_installed) {
	          _mouse_on = FALSE;
                  _handle_mouse_input();
	       }
	    }
	    else
	       [NSApp sendEvent: event];
	    break;
            
	 case NSAppKitDefined:
            switch ([event subtype]) {
	       
               case NSApplicationActivatedEventType:
	          if (osx_window)
		     [osx_window invalidateCursorRectsForView: [osx_window contentView]];
		  if (_keyboard_installed)
	             osx_keyboard_focused(TRUE, 0);
		  _switch_in();
                  break;
		  
               case NSApplicationDeactivatedEventType:
		  if (_keyboard_installed)
		     osx_keyboard_focused(FALSE, 0);
		  _switch_out();
                  break;
	       
	       case NSWindowMovedEventType:
                  /* This is needed to ensure the shadow gets drawn when the window is
		   * created. It's weird, but sometimes it doesn't get drawn if we omit
		   * the next two lines... The same applies to the cursor rectangle,
		   * which doesn't seem to be set at window creation (it works once you
		   * move the mouse though)
		   */
	          if (osx_window) {
		     [osx_window invalidateShadow];
		     [osx_window invalidateCursorRectsForView: [osx_window contentView]];
		  }
		  break;
	    }
            [NSApp sendEvent: event];
            break;
	 
	 default:
	    [NSApp sendEvent: event];
	    break;
      }
   }
   if (_mouse_installed) {
      if (osx_mouse_warped) {
         old_x = _mouse_x;
         old_y = _mouse_y;
         dx = dy = 0;
         osx_mouse_warped = FALSE;
      }
      else if (dx || dy || dz)
         osx_mouse_handler(dx, dy, dz, buttons);
   }
}



/* osx_sys_init:
 *  Initalizes the MacOS X system driver.
 */
static int osx_sys_init(void)
{
   FSRef processRef;
   FSCatalogInfo processInfo;
   ProcessSerialNumber psn = {0, kCurrentProcess};
   char path[1024], *p;
   int i;
   
   /* This comes from the ADC tips & tricks section: how to detect if the app
    * lives inside a bundle
    */
   GetProcessBundleLocation (&psn, &processRef);
   FSGetCatalogInfo (&processRef, kFSCatInfoNodeFlags, &processInfo, NULL, NULL, NULL);
   if (processInfo.nodeFlags & kFSNodeIsDirectoryMask) {
      strncpy(path, __crt0_argv[0], sizeof(path));
      for (i = 0; i < 4; i++) {
         for (p = path + strlen(path); (p >= path) && (*p != '/'); p--);
         *p = '\0';
      }
      chdir(path);
      app_bundle = [NSBundle mainBundle];
   }
   
   /* Install emergency-exit signal handlers */
   old_sig_abrt = signal(SIGABRT, osx_signal_handler);
   old_sig_fpe  = signal(SIGFPE,  osx_signal_handler);
   old_sig_ill  = signal(SIGILL,  osx_signal_handler);
   old_sig_segv = signal(SIGSEGV, osx_signal_handler);
   old_sig_term = signal(SIGTERM, osx_signal_handler);
   old_sig_int  = signal(SIGINT,  osx_signal_handler);
   old_sig_quit = signal(SIGQUIT, osx_signal_handler);
   
   /* Setup a blank cursor */
   cursor_data = calloc(1, 16 * 16 * 4);
   cursor_rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: &cursor_data
      pixelsWide: 16
      pixelsHigh: 16
      bitsPerSample: 8
      samplesPerPixel: 4
      hasAlpha: YES
      isPlanar: NO
      colorSpaceName: NSDeviceRGBColorSpace
      bytesPerRow: 64
      bitsPerPixel: 32];
   cursor_image = [[NSImage alloc] initWithSize: NSMakeSize(16, 16)];
   [cursor_image addRepresentation: cursor_rep];
   osx_cursor = [[NSCursor alloc] initWithImage: cursor_image
      hotSpot: NSMakePoint(0, 0)];
   
   osx_gfx_mode = OSX_GFX_NONE;
   
   set_display_switch_mode(SWITCH_BACKGROUND);
   set_window_title([[[NSProcessInfo processInfo] processName] cString]);
   
   return 0;
}



/* osx_sys_exit:
 *  Shuts down the system driver.
 */
static void osx_sys_exit(void)
{
   signal(SIGABRT, old_sig_abrt);
   signal(SIGFPE,  old_sig_fpe);
   signal(SIGILL,  old_sig_ill);
   signal(SIGSEGV, old_sig_segv);
   signal(SIGTERM, old_sig_term);
   signal(SIGINT,  old_sig_int);
   signal(SIGQUIT, old_sig_quit);
   
   if (osx_cursor)
      [osx_cursor release];
   if (cursor_image)
      [cursor_image release];
   if (cursor_rep)
      [cursor_rep release];
   if (cursor_data)
      free(cursor_data);
   if (app_bundle)
      [app_bundle release];
   osx_cursor = NULL;
   cursor_image = NULL;
   cursor_rep = NULL;
   cursor_data = NULL;
   app_bundle = NULL;
}



/* osx_sys_get_executable_name:
 *  Returns the full path to the application executable name. Note that if the
 *  exe is inside a bundle, this returns the full path of the bundle.
 */
static void osx_sys_get_executable_name(char *output, int size)
{
   if (app_bundle)
      do_uconvert([[app_bundle bundlePath] cString], U_ASCII, output, U_CURRENT, size);
   else
      do_uconvert(__crt0_argv[0], U_ASCII, output, U_CURRENT, size);
}



/* osx_sys_find_resource:
 *  Searches the resource in the bundle resource path if the app is in a
 *  bundle, otherwise calls the unix resource finder routine.
 */
static int osx_sys_find_resource(char *dest, AL_CONST char *resource, int size)
{
   const char *path;
   char buf[256], tmp[256];
   
   if (app_bundle) {
      path = [[app_bundle resourcePath] cString];
      append_filename(buf, uconvert_ascii(path, tmp), resource, sizeof(buf));
      if (exists(buf)) {
         ustrzcpy(dest, size, buf);
	 return 0;
      }
   }
   return _unix_find_resource(dest, resource, size);
}



/* osx_sys_message:
 *  Displays a message using an alert panel.
 */
static void osx_sys_message(AL_CONST char *msg)
{
   char utf8_msg[MESSAGE_STRING_SIZE];
   NSString *ns_title, *ns_msg;
   
   do_uconvert(msg, U_CURRENT, utf8_msg, U_UTF8, MESSAGE_STRING_SIZE);
   ns_title = [NSString stringWithUTF8String: osx_window_title];
   ns_msg = [NSString stringWithUTF8String: utf8_msg];
   
   pthread_mutex_lock(&osx_event_mutex);
   skip_events_processing = TRUE;
   pthread_mutex_unlock(&osx_event_mutex);
   
   NSRunAlertPanel(ns_title, ns_msg, nil, nil, nil);
   
   pthread_mutex_lock(&osx_event_mutex);
   skip_events_processing = FALSE;
   pthread_mutex_unlock(&osx_event_mutex);
}



/* osx_sys_set_window_title:
 *  Sets the title for both the application menu and the window if present.
 */
static void osx_sys_set_window_title(AL_CONST char *title)
{
   char tmp[WINDOW_TITLE_SIZE];
   
   strcpy(osx_window_title, title);
   do_uconvert(title, U_CURRENT, tmp, U_UTF8, WINDOW_TITLE_SIZE);

   NSString *ns_title = [NSString stringWithUTF8String: tmp];
   
   /* Fix: set menu items to reflect new app title */
   
   if (osx_window)
      [osx_window setTitle: ns_title];
}



/* osx_sys_set_close_button_callback:
 *  Sets the window close callback.
 */
static int osx_sys_set_close_button_callback(void (*proc)(void))
{
   osx_window_close_hook = proc;
   return 0;
}



/* osx_sys_set_display_switch_mode:
 *  Sets the current display switch mode.
 */
static int osx_sys_set_display_switch_mode(int mode)
{
   if (mode != SWITCH_BACKGROUND)
      return -1;   
   return 0;
}



/* osx_sys_get_gfx_safe_mode:
 *  Defines the safe graphics mode for this system.
 */
static void osx_sys_get_gfx_safe_mode(int *driver, struct GFX_MODE *mode)
{
   *driver = GFX_QUARTZ_WINDOW;
   mode->width = 320;
   mode->height = 200;
   mode->bpp = 8;
}



/* osx_sys_yield_timeslice:
 *  Used to play nice with multitasking.
 */
static void osx_sys_yield_timeslice(void)
{
   usleep(30000);
}



/* osx_sys_desktop_color_depth:
 *  Queries the desktop color depth.
 */
static int osx_sys_desktop_color_depth(void)
{
   CFDictionaryRef mode = NULL;
   int color_depth;
   
   mode = CGDisplayCurrentMode(kCGDirectMainDisplay);
   if (!mode)
      return -1;
   CFNumberGetValue(CFDictionaryGetValue(mode, kCGDisplayBitsPerPixel), kCFNumberSInt32Type, &color_depth);
   
   return color_depth == 32 ? color_depth : 15;
}


/* osx_sys_get_desktop_resolution:
 *  Queries the desktop resolution.
 */
static int osx_sys_get_desktop_resolution(int *width, int *height)
{
   CFDictionaryRef mode = NULL;
   
   mode = CGDisplayCurrentMode(kCGDirectMainDisplay);
   if (!mode)
      return -1;
   CFNumberGetValue(CFDictionaryGetValue(mode, kCGDisplayWidth), kCFNumberSInt32Type, width);
   CFNumberGetValue(CFDictionaryGetValue(mode, kCGDisplayHeight), kCFNumberSInt32Type, height);
   
   return 0;
}


