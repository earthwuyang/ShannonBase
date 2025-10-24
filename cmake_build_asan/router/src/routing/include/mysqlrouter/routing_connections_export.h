
#ifndef ROUTING_CONNECTIONS_EXPORT_H
#define ROUTING_CONNECTIONS_EXPORT_H

#ifdef ROUTING_CONNECTIONS_STATIC_DEFINE
#  define ROUTING_CONNECTIONS_EXPORT
#  define ROUTING_CONNECTIONS_NO_EXPORT
#else
#  ifndef ROUTING_CONNECTIONS_EXPORT
#    ifdef routing_connections_EXPORTS
        /* We are building this library */
#      define ROUTING_CONNECTIONS_EXPORT __attribute__((visibility("default")))
#    else
        /* We are using this library */
#      define ROUTING_CONNECTIONS_EXPORT __attribute__((visibility("default")))
#    endif
#  endif

#  ifndef ROUTING_CONNECTIONS_NO_EXPORT
#    define ROUTING_CONNECTIONS_NO_EXPORT __attribute__((visibility("hidden")))
#  endif
#endif

#ifndef ROUTING_CONNECTIONS_DEPRECATED
#  define ROUTING_CONNECTIONS_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef ROUTING_CONNECTIONS_DEPRECATED_EXPORT
#  define ROUTING_CONNECTIONS_DEPRECATED_EXPORT ROUTING_CONNECTIONS_EXPORT ROUTING_CONNECTIONS_DEPRECATED
#endif

#ifndef ROUTING_CONNECTIONS_DEPRECATED_NO_EXPORT
#  define ROUTING_CONNECTIONS_DEPRECATED_NO_EXPORT ROUTING_CONNECTIONS_NO_EXPORT ROUTING_CONNECTIONS_DEPRECATED
#endif

/* NOLINTNEXTLINE(readability-avoid-unconditional-preprocessor-if) */
#if 0 /* DEFINE_NO_DEPRECATED */
#  ifndef ROUTING_CONNECTIONS_NO_DEPRECATED
#    define ROUTING_CONNECTIONS_NO_DEPRECATED
#  endif
#endif

#endif /* ROUTING_CONNECTIONS_EXPORT_H */
