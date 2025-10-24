
#ifndef HTTP_CLIENT_EXPORT_H
#define HTTP_CLIENT_EXPORT_H

#ifdef HTTP_CLIENT_STATIC_DEFINE
#  define HTTP_CLIENT_EXPORT
#  define HTTP_CLIENT_NO_EXPORT
#else
#  ifndef HTTP_CLIENT_EXPORT
#    ifdef http_client_EXPORTS
        /* We are building this library */
#      define HTTP_CLIENT_EXPORT __attribute__((visibility("default")))
#    else
        /* We are using this library */
#      define HTTP_CLIENT_EXPORT __attribute__((visibility("default")))
#    endif
#  endif

#  ifndef HTTP_CLIENT_NO_EXPORT
#    define HTTP_CLIENT_NO_EXPORT __attribute__((visibility("hidden")))
#  endif
#endif

#ifndef HTTP_CLIENT_DEPRECATED
#  define HTTP_CLIENT_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef HTTP_CLIENT_DEPRECATED_EXPORT
#  define HTTP_CLIENT_DEPRECATED_EXPORT HTTP_CLIENT_EXPORT HTTP_CLIENT_DEPRECATED
#endif

#ifndef HTTP_CLIENT_DEPRECATED_NO_EXPORT
#  define HTTP_CLIENT_DEPRECATED_NO_EXPORT HTTP_CLIENT_NO_EXPORT HTTP_CLIENT_DEPRECATED
#endif

/* NOLINTNEXTLINE(readability-avoid-unconditional-preprocessor-if) */
#if 0 /* DEFINE_NO_DEPRECATED */
#  ifndef HTTP_CLIENT_NO_DEPRECATED
#    define HTTP_CLIENT_NO_DEPRECATED
#  endif
#endif

#endif /* HTTP_CLIENT_EXPORT_H */
