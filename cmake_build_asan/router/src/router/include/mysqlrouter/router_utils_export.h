
#ifndef ROUTER_UTILS_EXPORT_H
#define ROUTER_UTILS_EXPORT_H

#ifdef ROUTER_UTILS_STATIC_DEFINE
#  define ROUTER_UTILS_EXPORT
#  define ROUTER_UTILS_NO_EXPORT
#else
#  ifndef ROUTER_UTILS_EXPORT
#    ifdef router_utils_EXPORTS
        /* We are building this library */
#      define ROUTER_UTILS_EXPORT __attribute__((visibility("default")))
#    else
        /* We are using this library */
#      define ROUTER_UTILS_EXPORT __attribute__((visibility("default")))
#    endif
#  endif

#  ifndef ROUTER_UTILS_NO_EXPORT
#    define ROUTER_UTILS_NO_EXPORT __attribute__((visibility("hidden")))
#  endif
#endif

#ifndef ROUTER_UTILS_DEPRECATED
#  define ROUTER_UTILS_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef ROUTER_UTILS_DEPRECATED_EXPORT
#  define ROUTER_UTILS_DEPRECATED_EXPORT ROUTER_UTILS_EXPORT ROUTER_UTILS_DEPRECATED
#endif

#ifndef ROUTER_UTILS_DEPRECATED_NO_EXPORT
#  define ROUTER_UTILS_DEPRECATED_NO_EXPORT ROUTER_UTILS_NO_EXPORT ROUTER_UTILS_DEPRECATED
#endif

/* NOLINTNEXTLINE(readability-avoid-unconditional-preprocessor-if) */
#if 0 /* DEFINE_NO_DEPRECATED */
#  ifndef ROUTER_UTILS_NO_DEPRECATED
#    define ROUTER_UTILS_NO_DEPRECATED
#  endif
#endif

#endif /* ROUTER_UTILS_EXPORT_H */
