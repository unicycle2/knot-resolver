# Knot Resolver
project('knot-resolver', 'c',
	version : '1.3.0-dev',
	meson_version : '>0.37.0',
	license : 'GPL3+')

# Project variables
libkres_version = '3.0.0'

# Global compiler settings
compiler = meson.get_compiler('c')
add_project_arguments('-std=c99', language : 'c')
add_project_arguments(['-include', join_paths(meson.current_build_dir(), 'config.h')], language : 'c')
add_project_arguments('-D_GNU_SOURCE=1', language : 'c')

# Dependencies
threads_dep     = dependency('threads')
libknot_dep     = dependency('libknot', version : '>= 2.3.1')
libdnssec_dep   = dependency('libdnssec', version : '>= 2.3.1')
libzscanner_dep = dependency('libzscanner', version : '>= 2.3.1')
libuv_dep       = dependency('libuv', version : '>= 1.0')
libsystemd_dep  = dependency('libsystemd', version : '>= 227', required : false)
nettle_dep      = dependency('nettle')
gnutls_dep      = dependency('gnutls')
luajit_dep      = dependency('luajit')
lmdb_dep        = dependency('lmdb', required : false)

cmocka_dep      = dependency('cmocka', required : false)

cat = find_program('cat')
sed = find_program('sed')

# Configuration Data
abs_sysconfdir = join_paths(get_option('prefix'), get_option('sysconfdir'))
abs_moduledir = join_paths(get_option('prefix'), get_option('libdir'), get_option('moduledir'))

conf_data = configuration_data()
conf_data.set_quoted('PACKAGE_VERSION', meson.project_version())
conf_data.set_quoted('MODULEDIR', abs_moduledir)

pkg_config = find_program('pkg-config')

if host_machine.system() == 'darwin'
  so_tool = find_program('otool')
  so_ext = '.dylib'
else
  so_tool = find_program('scripts/objdump_soname')
  so_ext = '.so'
endif

knot_libraries = ['libknot', 'libdnssec', 'libzscanner']
foreach lib : knot_libraries
  lib_libdir = run_command(pkg_config, '--variable=libdir', lib).stdout().strip()
  lib_fullpath = join_paths(lib_libdir, lib+so_ext)
  lib_soname = run_command(so_tool, '-Dm', lib_fullpath).stdout().strip()
  message(lib+' SONAME is: '+lib_soname)
  if lib_soname == ''
    error(lib+' SONAME is empty, fix the build script.')
  endif
  conf_data.set_quoted(lib+'_SONAME', lib_soname)
endforeach

if libsystemd_dep.found()
  conf_data.set('HAS_SYSTEMD', 1)
endif

# Attributes checks
attributes = ['cold', 'noreturn', 'pure', 'unused', 'nonnull', 'const']
foreach attr : attributes
  code = 'void func(void *) __attribute__ (('+attr+'));'
  result = compiler.compiles(code, args : ['-Wattributes', '-Werror'], name : 'has __attribute__ (('+attr+'))')
  conf_data.set10('HAVE_ATTRIBUTE_'+attr.to_upper(), result)
endforeach

code = 'void func(void *) __attribute__ ((visibility("default")));'
result = compiler.compiles(code, args : ['-Wattributes', '-Werror'], name : 'has __attribute__ ((visibility("default")))')
conf_data.set10('HAVE_ATTRIBUTE_VISIBILITY', result)

configure_file(input : 'config.h.in',
	       output : 'config.h',
	       configuration : conf_data)	     

# Include directories

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
  incdir = include_directories('lib/generic',
			       'contrib',
			       'contrib/lmdb')
else
  incdir = include_directories('lib/generic',
			       'contrib')
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
		   'lib/cdb_lmdb.c',
		   'lib/cookies/alg_containers.c',
		   'lib/cookies/alg_sha.c',
		   'lib/cookies/helper.c',
		   'lib/cookies/lru_cache.c',
		   'lib/cookies/nonce.c']

libkres_deps = [threads_dep, libuv_dep, libknot_dep, libdnssec_dep, lmdb_dep, nettle_dep]

libkres = library('kres',
		  libkres_sources,
		  link_with : contrib,
		  version : libkres_version,
		  dependencies : libkres_deps,
		  include_directories : incdir,
		  install : true)

libkres_pc_conf = configuration_data()
libkres_pc_conf.set('version', meson.project_version())
libkres_pc_conf.set('prefix', get_option('prefix'))
libkres_pc_conf.set('libdir', join_paths(get_option('prefix'), get_option('libdir')))
libkres_pc_conf.set('includedir', join_paths(get_option('prefix'), get_option('includedir')))

libkres_pc = configure_file(input : 'lib/libkres.pc.in',
			    output : 'libkres.pc',
			    configuration : libkres_pc_conf)

install_data(libkres_pc,
	      install_dir : join_paths(get_option('prefix'), get_option('libdir'), get_option('pkgconfigdir')),
	      install : true)

# Modules

modules_cpp_args = ['-fvisibility=hidden']

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

lua_modules = ['modules/policy/policy.lua',
	       'modules/policy/aho-corasick.lua',
	       'modules/ketcd/ketcd.lua',
	       'modules/graphite/graphite.lua',
	       'modules/view/view.lua',
	       'modules/predict/predict.lua',
	       'modules/dns64/dns64.lua',
	       'modules/renumber/renumber.lua',
	       'modules/http/http.lua',
	       'modules/http/prometheus.lua',
	       'modules/daf/daf.lua',
	       'modules/workarounds/workarounds.lua']

luajit_cmd = find_program('luajit', required : true)

foreach module : lua_modules
  lua_module = custom_target(module,
			     input : module,
			     output : module.split('/').get(-1),
			     command : [luajit_cmd, '-b', '@INPUT@', '@OUTPUT@'],
			     install_dir : abs_moduledir,
			     install : true,
			     build_by_default : true)
endforeach
  
## version module
version_inc = custom_target('version.inc',
			    input : ['modules/version/version.lua.in'],
			    output : ['version.lua.in'],
			    capture : true,
		      	    command : [sed,
				       '-e', 's,@VERSION@,'+meson.project_version()+',g',
				       '@INPUT@'],
			    install : false)

version_lua = custom_target('version.lua',
			    input : version_inc,
			    output : 'version.lua',
			    command : [luajit_cmd, '-b', '@INPUT@', '@OUTPUT@'],
			    install_dir : abs_moduledir,
			    install : true,
			    build_by_default : true)

## http module additional files
install_subdir('modules/http/http/',
	       install_dir : abs_moduledir,
	       install : true)

## daf module additional files
install_data('modules/daf/daf.js',
	     install_dir : join_paths(abs_moduledir, 'daf'),
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

kres_inc = custom_target('kres.inc',
			 input : ['daemon/lua/kres.lua.in'],
			 output : ['kres.inc'],
			 capture : true,
			 command : [sed,
				    '-e', 's,@KNOT_RRSET_TXT_DUMP@,'+libknot_rrset_txt_dump+',g',
				    '@INPUT@'],
			 install : false)

kres_lua = custom_target('kres.lua',
			 input : kres_inc,
			 output : ['kres.lua'],
			 command : [luajit_cmd, '-b', '@INPUT@', '@OUTPUT@'],
			 install_dir : abs_moduledir,
			 install : true,
			 build_by_default : true)

trust_anchors_inc = custom_target('trust_anchors.inc',
				  input : 'daemon/lua/trust_anchors.lua.in',
				  output : 'trust_anchors.inc',
				  capture : true,
				  command : [sed,
					     '-e', 's,@ETCDIR@,'+abs_sysconfdir+',g',
					     '@INPUT@'],
				  install : false)

trust_anchors_lua = custom_target('trust_anchors.lua',
			    input : trust_anchors_inc,
			    output : 'trust_anchors.lua',
			    command : [luajit_cmd, '-b', '@INPUT@', '@OUTPUT@'],
			    install_dir : abs_moduledir,
			    install : true,
			    build_by_default : true)

if libzscanner_dep.version().version_compare('>= 2.4.2')
  libzscanner_comments = 'true'
else
  libzscanner_comments = 'false'
endif

zonefile_inc = custom_target('zonefile.inc',
			     input : ['daemon/lua/zonefile.lua.in'],
			     output : ['zonefile.inc'],
			     capture : true,
			     command : [sed,
					'-e', 's,@LIBZSCANNER_COMMENTS@,'+libzscanner_comments+',g',
					'@INPUT@'],
			     install : false)

zonefile_lua = custom_target('zonefile.lua',
			    input : zonefile_inc,
			    output : 'zonefile.lua',
			    command : [luajit_cmd, '-b', '@INPUT@', '@OUTPUT@'],
			    install_dir : abs_moduledir,
			    install : true,
			    build_by_default : true)

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

kres_gen_module = custom_target('kres_gen.lua',
				input : 'daemon/lua/kres-gen.lua',
				output : 'kres-gen.lua',
				command : [luajit_cmd, '-b', '@INPUT@', '@OUTPUT@'],
				install_dir : abs_moduledir,
				install : true,
				build_by_default : true)

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

  mock_cmodule = shared_module('tests/mock_cmodule',
			       ['tests/mock_cmodule.c'],
			       include_directories : incdir,
			       link_with : [contrib],
			       name_prefix : '',
			       cpp_args : ['-fPIC', '-fvisibility=hidden'],
			       install : false)
  
  test_cache = executable('test_cache',
			  'tests/test_cache.c',
			  link_with : [libkres, contrib],
			  include_directories : incdir,
			  link_args : '-ldl',
			  dependencies : [libknot_dep, cmocka_dep, lmdb_dep])
  test('test_cache', test_cache)
  
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

doxygen = find_program('doxygen', required : false)
sphinx = find_program('sphinx-build', required : false)

if doxygen.found() and sphinx.found()
  sphinx_sources = [
    'daemon/README.rst',
    'modules/dns64/README.rst',
    'modules/hints/README.rst',
    'modules/graphite/README.rst',
    'modules/ketcd/README.rst',
    'modules/version/README.rst',
    'modules/renumber/README.rst',
    'modules/http/README.rst',
    'modules/workarounds/README.rst',
    'modules/redis/README.rst',
    'modules/daf/README.rst',
    'modules/dnstap/README.rst',
    'modules/predict/README.rst',
    'modules/README.rst',
    'modules/stats/README.rst',
    'modules/policy/README.rst',
    'modules/cookies/README.rst',
    'modules/kmemcached/README.rst',
    'modules/view/README.rst',
    'tests/README.rst',
    'tests/deckard/SCENARIO_GUIDE.rst',
    'tests/deckard/SCENARIO_EXAMPLE.rst',
    'tests/deckard/README.rst',
    'lib/generic/README.rst',
    'lib/README.rst',
    'doc/modules.rst',
    'doc/build.rst',
    'doc/daemon.rst',
    'doc/index.rst',
    'doc/modules_api.rst',
    'doc/lib.rst',
  ]

  custom_target('docs',
		command: [sphinx, '-W', '-b', 'html', join_paths(meson.current_source_dir(), 'doc'), '@OUTPUT@'],
		input: sphinx_sources,
		output: 'html',
		build_by_default: false)
  install_subdir(join_paths(meson.current_build_dir(), 'html'), install_dir: 'share/doc/knot-resolver/')
endif

kresd_run = find_program('tests/deckard/kresd_run.sh', required : false)

if kresd_run.found()
  run_target('check-integration',
	     command: [kresd_run, meson.current_build_dir(), meson.current_source_dir()],
	     build_by_default: false)
endif
