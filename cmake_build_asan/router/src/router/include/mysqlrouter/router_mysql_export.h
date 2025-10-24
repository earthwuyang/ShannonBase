
#ifndef ROUTER_MYSQL_EXPORT_H
#define ROUTER_MYSQL_EXPORT_H

#ifdef ROUTER_MYSQL_STATIC_DEFINE
#  define ROUTER_MYSQL_EXPORT
#  define ROUTER_MYSQL_NO_EXPORT
#else
#  ifndef ROUTER_MYSQL_EXPORT
#    ifdef router_mysql_EXPORTS
        /* We are building this library */
#      define ROUTER_MYSQL_EXPORT __attribute__((visibility("default")))
#    else
        /* We are using this library */
#      define ROUTER_MYSQL_EXPORT __attribute__((visibility("default")))
#    endif
#  endif

#  ifndef ROUTER_MYSQL_NO_EXPORT
#    define ROUTER_MYSQL_NO_EXPORT __attribute__((visibility("hidden")))
#  endif
#endif

#ifndef ROUTER_MYSQL_DEPRECATED
#  define ROUTER_MYSQL_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef ROUTER_MYSQL_DEPRECATED_EXPORT
#  define ROUTER_MYSQL_DEPRECATED_EXPORT ROUTER_MYSQL_EXPORT ROUTER_MYSQL_DEPRECATED
#endif

#ifndef ROUTER_MYSQL_DEPRECATED_NO_EXPORT
#  define ROUTER_MYSQL_DEPRECATED_NO_EXPORT ROUTER_MYSQL_NO_EXPORT ROUTER_MYSQL_DEPRECATED
#endif

/* NOLINTNEXTLINE(readability-avoid-unconditional-preprocessor-if) */
#if 0 /* DEFINE_NO_DEPRECATED */
#  ifndef ROUTER_MYSQL_NO_DEPRECATED
#    define ROUTER_MYSQL_NO_DEPRECATED
#  endif
#endif

#endif /* ROUTER_MYSQL_EXPORT_H */
