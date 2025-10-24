
#ifndef HTTP_COMMON_EXPORT_H
#define HTTP_COMMON_EXPORT_H

#ifdef HTTP_COMMON_STATIC_DEFINE
#  define HTTP_COMMON_EXPORT
#  define HTTP_COMMON_NO_EXPORT
#else
#  ifndef HTTP_COMMON_EXPORT
#    ifdef http_common_EXPORTS
        /* We are building this library */
#      define HTTP_COMMON_EXPORT __attribute__((visibility("default")))
#    else
        /* We are using this library */
#      define HTTP_COMMON_EXPORT __attribute__((visibility("default")))
#    endif
#  endif

#  ifndef HTTP_COMMON_NO_EXPORT
#    define HTTP_COMMON_NO_EXPORT __attribute__((visibility("hidden")))
#  endif
#endif

#ifndef HTTP_COMMON_DEPRECATED
#  define HTTP_COMMON_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef HTTP_COMMON_DEPRECATED_EXPORT
#  define HTTP_COMMON_DEPRECATED_EXPORT HTTP_COMMON_EXPORT HTTP_COMMON_DEPRECATED
#endif

#ifndef HTTP_COMMON_DEPRECATED_NO_EXPORT
#  define HTTP_COMMON_DEPRECATED_NO_EXPORT HTTP_COMMON_NO_EXPORT HTTP_COMMON_DEPRECATED
#endif

/* NOLINTNEXTLINE(readability-avoid-unconditional-preprocessor-if) */
#if 0 /* DEFINE_NO_DEPRECATED */
#  ifndef HTTP_COMMON_NO_DEPRECATED
#    define HTTP_COMMON_NO_DEPRECATED
#  endif
#endif

#endif /* HTTP_COMMON_EXPORT_H */
