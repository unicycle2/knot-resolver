# Knot Resolver
project('knot-resolver', 'c',
	version : '1.3.0-dev',
	meson_version : '>0.28.0',
	license : 'GPL3+')

add_project_arguments('-std=c99', language : 'c')

# Project variables
libkres_version = '3.0.0'

# Dependencies
threads_dep     = dependency('threads')
libknot_dep     = dependency('libknot', version : '>= 2.3.1')
libdnssec_dep   = dependency('libdnssec', version : '>= 2.3.1')
libzscanner_dep = dependency('libzscanner', version : '>= 2.3.1')
libuv_dep       = dependency('libuv', version : '>= 1.0')
libsystemd_dep  = dependency('libsystemd', version : '>= 227', required : false)
gnutls_dep      = dependency('gnutls')
luajit_dep      = dependency('luajit')
lmdb_dep        = dependency('lmdb', required : false)

cmocka_dep      = dependency('cmocka', required : false)

sed = find_program('sed')

# Configuration Data
abs_sysconfdir = join_paths(get_option('prefix'), get_option('sysconfdir'))
abs_moduledir = join_paths(get_option('prefix'), get_option('libdir'), get_option('moduledir'))

conf_data = configuration_data()
conf_data.set('PACKAGE_VERSION', '"'+meson.project_version()+'"')
conf_data.set('abi_version', 3)
conf_data.set('MODULEDIR', '"' + abs_moduledir + '"')
conf_data.set('_GNU_SOURCE', 1)

if libknot_dep.version().version_compare('>= 2.4.0')
  conf_data.set('libknot_SONAME', '"libknot.so.5"')
  conf_data.set('libzscanner_SONAME', '"libzscanner.so.1"')
  conf_data.set('libdnssec_SONAME', '"libdnssec.so.2"')
else
  conf_data.set('libknot_SONAME', '"libknot.so.4"')
  conf_data.set('libzscanner_SONAME', '"libzscanner.so.1"')
  conf_data.set('libdnssec_SONAME', '"libdnssec.so.2"')
endif

if libsystemd_dep.found()
  conf_data.set('HAS_SYSTEMD', 1)
endif

# Attributes checks
compiler = meson.get_compiler('c')

attributes = ['cold', 'noreturn', 'pure', 'unused', 'nonnull', 'specialsnowflake']
foreach attr : attributes
  code = 'void func() __attribute__ (('+attr+'));'
  result = compiler.compiles(code, name : 'has __attribute__ (('+attr+'))')
  conf_data.set('HAVE_ATTRIBUTE_'+attr.toupper(), result)
endforeach

configure_file(input : 'config.h.in',
	       output : 'config.h',
	       configuration : conf_data)	     

# Include directories

incdir = include_directories('lib/generic',
			     'contrib')

# contrib convenience library

contrib_sources = ['contrib/ccan/asprintf/asprintf.c',
		   'contrib/ccan/ilog/ilog.c',
		   'contrib/ccan/isaac/isaac.c',
		   'contrib/ccan/json/json.c',
		   'contrib/ucw/mempool.c',
		   'contrib/murmurhash3/murmurhash3.c',
		   'contrib/base32hex.c',
		   'contrib/base64.c']

if not lmdb_dep.found()
  contrib_sources += ['contrib/lmdb/mdb.c',
                      'contrib/lmdb/midl.c']
  incdir += ['contrib/lmbd']
endif

contrib = static_library('contrib',
			 contrib_sources,
			 include_directories : incdir)

# libkres shared library

libkres_sources = ['lib/generic/lru.c',
		   'lib/generic/map.c',
		   'lib/layer/iterate.c',
		   'lib/layer/validate.c',
		   'lib/layer/rrcache.c',   
		   'lib/layer/pktcache.c',
		   'lib/dnssec/nsec.c',
		   'lib/dnssec/nsec3.c',
		   'lib/dnssec/signature.c',
		   'lib/dnssec/ta.c',
		   'lib/dnssec.c',
		   'lib/utils.c',
		   'lib/nsrep.c',
		   'lib/module.c',
		   'lib/resolve.c',
		   'lib/zonecut.c',
		   'lib/rplan.c',
		   'lib/cache.c',
		   'lib/cdb_lmdb.c']

libkres_deps = [threads_dep, libuv_dep, libknot_dep, libdnssec_dep, lmdb_dep]

libkres = library('kres',
		  libkres_sources,
		  link_with : contrib,
		  version : libkres_version,
		  dependencies : libkres_deps,
		  include_directories : incdir,
		  install : true)

# Modules

modules_cpp_args = ['-fvisibility=hidden', '-fPIC']

## hints module
shared_module('hints',
	      ['modules/hints/hints.c'],
	      include_directories : incdir,
	      link_with : [libkres, contrib],
	      name_prefix : '',
	      cpp_args : modules_cpp_args,
	      install_dir : abs_moduledir,
	      install : true)

## stats module
shared_module('stats',
	      ['modules/stats/stats.c'],
	      include_directories : incdir,
	      link_with : [libkres, contrib],
	      name_prefix : '',
	      cpp_args : modules_cpp_args,
	      install_dir : abs_moduledir,
	      install : true)

## cookies module
shared_module('cookies',
	      ['modules/cookies/cookiectl.c',
	       'modules/cookies/cookiemonster.c',
	       'modules/cookies/cookies.c'],
	      include_directories : incdir,
	      link_with: [libkres, contrib],
	      name_prefix : '',
	      cpp_args : modules_cpp_args,
	      install_dir : abs_moduledir,
	      install : true)

## kmemcached module

libmemcached_dep = dependency('libmemcached')

if libmemcached_dep.found()
  shared_module('kmemcached',
		['modules/kmemcached/kmemcached.c',
		 'modules/kmemcached/cdb_memcached.c'],
		include_directories : incdir,
		link_with : [libkres],
		dependencies : libmemcached_dep,
		name_prefix : '',
		cpp_args : modules_cpp_args,
		install_dir : abs_moduledir,
		install : true)
endif

## redis module
hiredis_dep = dependency('hiredis')
if hiredis_dep.found()
  shared_module('redis',
		['modules/redis/redis.c',
		 'modules/redis/cdb_redis.c'],
		include_directories : incdir,
		link_with : [libkres],
		dependencies : [hiredis_dep, libuv_dep],
		name_prefix : '',
		cpp_args : modules_cpp_args,
		install_dir : abs_moduledir,
		install : true)
endif		

## dnstap module
libprotobuf_c_dep = dependency('libprotobuf-c', version : '>= 1', required : false)
libfstrm_dep      = dependency('libfstrm', version : '>= 0.2', required : false)
protoc_c_cmd      = find_program('protoc-c', required : false)

if libprotobuf_c_dep.found() and libfstrm_dep.found() and protoc_c_cmd.found()
  protoc_c_gen       = generator(protoc_c_cmd,
				 output : ['@BASENAME@.pb-c.c', '@BASENAME@.pb-c.h'],
				 arguments : ['@INPUT@',
					      '--proto_path=@SOURCE_DIR@/modules/dnstap/',
					      '--c_out=@BUILD_DIR@'])
  
  dnstap_pb = protoc_c_gen.process('modules/dnstap/dnstap.proto')

  shared_module('dnstap',
		['modules/dnstap/dnstap.c'],
		dnstap_pb,
		include_directories : incdir,
		link_with : [libkres],
		dependencies : [libprotobuf_c_dep, libfstrm_dep],
		name_prefix : '',
		cpp_args : modules_cpp_args,
		install_dir : abs_moduledir,
		install : true)
endif

## policy module
install_data(['modules/policy/policy.lua',
	      'modules/policy/aho-corasick.lua'],
	     install_dir : abs_moduledir,
	     install : true)

## ketcd module
install_data(['modules/ketcd/ketcd.lua'],
	     install_dir : abs_moduledir,
	     install : true)

## graphite module
install_data(['modules/graphite/graphite.lua'],
	     install_dir : abs_moduledir,
	     install : true)

## view module
install_data(['modules/view/view.lua'],
	     install_dir : abs_moduledir,
	     install : true)

## predict module
install_data(['modules/predict/predict.lua'],
	     install_dir : abs_moduledir,
	     install : true)

## dns64 module
install_data(['modules/dns64/dns64.lua'],
	     install_dir : abs_moduledir,
	     install : true)

## renumber module
install_data(['modules/renumber/renumber.lua'],
	     install_dir : abs_moduledir,
	     install : true)

## http module
install_data(['modules/http/http.lua',
	      'modules/http/prometheus.lua'],
	     install_dir : abs_moduledir,
	     install : true)

install_subdir('modules/http/http/',
	       install_dir : abs_moduledir,
	       install : true)

## daf module
install_data(['modules/daf/daf.lua'],
	     install_dir : abs_moduledir,
	     install : true)
install_data('modules/daf/daf.js',
	     install_dir : join_paths(abs_moduledir, 'daf'),
	     install : true)

## workarounds module
install_data(['modules/workarounds/workarounds.lua'],
	     install_dir : abs_moduledir,
	     install : true)

## version module
version_lua = custom_target('version.lua',
			    input : ['modules/version/version.lua.in'],
			    output : ['version.lua'],
			    capture : true,
		      	    command : [sed,
				       '-e', 's,@VERSION@,'+meson.project_version()+',g',
				       '@INPUT@'],
			    install_dir : abs_moduledir,
			    install : true)

# Embedded Lua files

xxd_lua = find_program('scripts/embed-lua.sh')

lua_gen = generator(xxd_lua,
		    output : '@BASENAME@.inc',
		    arguments : ['@INPUT@', '@OUTPUT@'])

lua_inc = lua_gen.process('daemon/lua/sandbox.lua', 'daemon/lua/config.lua')

if libknot_dep.version().version_compare('>= 2.4.0')
  libknot_rrset_txt_dump = 'true'
else
  libknot_rrset_txt_dump = 'false'
endif

kres_lua = custom_target('kres.lua',
			 input : ['daemon/lua/kres.lua.in'],
			 output : ['kres.lua'],
			 capture : true,
			 command : [sed,
				    '-e', 's,@KNOT_RRSET_TXT_DUMP@,'+libknot_rrset_txt_dump+',g',
				    '@INPUT@'],
			 install_dir : abs_moduledir,
			 install : true)

trust_anchors_lua = custom_target('trust_anchors.lua',
				  input : 'daemon/lua/trust_anchors.lua.in',
				  output : 'trust_anchors.lua',
				  capture : true,
				  command : [sed,
					     '-e', 's,@ETCDIR@,'+abs_sysconfdir+',g',
					     '@INPUT@'],
				  install_dir : abs_moduledir,
				  install : true)

if libzscanner_dep.version().version_compare('>= 2.4.2')
  libzscanner_comments = 'true'
else
  libzscanner_comments = 'false'
endif

zonefile_lua = custom_target('zonefile.lua',
			     input : ['daemon/lua/zonefile.lua.in'],
			     output : ['zonefile.lua'],
			     capture : true,
			     command : [sed,
					'-e', 's,@LIBZSCANNER_COMMENTS@,'+libzscanner_comments+',g',
					'@INPUT@'],
			     install_dir : abs_moduledir,
			     install : true)

# kresd daemon

daemon_sources = ['daemon/io.c',
		  'daemon/network.c',
		  'daemon/engine.c',
		  'daemon/worker.c',
		  'daemon/bindings.c',
		  'daemon/ffimodule.c',
		  'daemon/tls.c',
		  'daemon/tls_ephemeral_credentials.c',
		  'daemon/main.c']

executable('kresd',
	   daemon_sources,
	   lua_inc,
	   kres_lua, zonefile_lua,
	   link_with : libkres,
	   include_directories : incdir,
	   dependencies : [threads_dep,
			   libknot_dep,
			   libzscanner_dep,
			   luajit_dep,
			   libuv_dep,
			   gnutls_dep,
			   libsystemd_dep],
	   install_dir : get_option('sbindir'),
	   install : true)

# Various library mappings into Lua

## Run on 'regenerate' target

run_target('regenerate',
	   command : 'daemon/lua/kres-gen.sh')

install_data(['daemon/lua/kres-gen.lua'],
	     install_dir : abs_moduledir)

# kresc CLI
libedit_dep     = dependency('libedit', required : false)
if libedit_dep.found()
  executable('kresc',
	     ['daemon/kresc.c'],
	     link_with : [contrib, libkres],
	     dependencies : [libedit_dep],
	     include_directories : incdir,
	     install : true)
endif

# etc directory installation

install_data(['etc/icann-ca.pem',
	      'etc/config.cluster',
	      'etc/config.isp',
	      'etc/config.personal',
	      'etc/config.splitview'],
	      install_dir : get_option('sysconfdir'),
	      install : true)

# Tests

if cmocka_dep.found()

  test_set = executable('test_set',
			'tests/test_set.c',
			link_with : [libkres, contrib],
			include_directories : incdir,
			dependencies : [cmocka_dep, lmdb_dep])
  test('test_set', test_set)

  test_map = executable('test_map',
			'tests/test_map.c',
			link_with : [libkres, contrib],
			include_directories : incdir,
			dependencies : [cmocka_dep, lmdb_dep])
  test('test_map', test_map)

  test_array = executable('test_array',
			'tests/test_array.c',
			link_with : [libkres, contrib],
			include_directories : incdir,
			dependencies : [cmocka_dep, lmdb_dep])
  test('test_array', test_array)

  test_pack = executable('test_pack',
			'tests/test_pack.c',
			link_with : [libkres, contrib],
			include_directories : incdir,
			dependencies : [cmocka_dep, lmdb_dep])
  test('test_pack', test_pack)

  test_lru = executable('test_lru',
			'tests/test_lru.c',
			link_with : [libkres, contrib],
			include_directories : incdir,
			dependencies : [cmocka_dep, lmdb_dep])
  test('test_lru', test_lru)

  test_utils = executable('test_utils',
			'tests/test_utils.c',
			link_with : [libkres, contrib],
			include_directories : incdir,
			dependencies : [cmocka_dep, lmdb_dep])
  test('test_utils', test_utils)

  test_module = executable('test_module',
			'tests/test_module.c',
			link_with : [libkres, contrib],
			include_directories : incdir,
			dependencies : [cmocka_dep, lmdb_dep])
  test('test_module', test_module)

#  test_cache = executable('test_cache',
#			'tests/test_cache.c',
#			link_with : [libkres, contrib],
#			include_directories : incdir,
#			dependencies : [cmocka_dep, lmdb_dep])
#  test('test_cache', test_cache)

  test_zonecut = executable('test_zonecut',
			'tests/test_zonecut.c',
			link_with : [libkres, contrib],
			include_directories : incdir,
			dependencies : [cmocka_dep, lmdb_dep])
  test('test_zonecut', test_zonecut)

  test_rplan = executable('test_rplan',
			'tests/test_rplan.c',
			link_with : [libkres, contrib],
			include_directories : incdir,
			dependencies : [cmocka_dep, lmdb_dep])
  test('test_rplan', test_rplan)

endif
