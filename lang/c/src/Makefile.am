# -pedantic
AM_CPPFLAGS=-I$(top_srcdir)/jansson/src
AM_CFLAGS=-Wall
ACLOCAL_AMFLAGS=-I m4

include_HEADERS = avro.h

lib_LTLIBRARIES = libavro.la
libavro_la_SOURCES = st.c st.h schema.c schema.h schema_printf.c schema_equal.c datum.c datum.h \
io.c dump.c dump.h encoding_binary.c container_of.h queue.h encoding.h
libavro_la_LIBADD = $(top_builddir)/jansson/src/.libs/libjansson.a
libavro_la_LDFLAGS = \
        -version-info $(LIBAVRO_VERSION) \
        -release $(VERSION) \
        -export-dynamic
