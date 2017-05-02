doxygen = find_program('doxygen')
sphinx_build = find_program('sphinx-build')

if doxygen.found()
  custom_target('doc-doxygen',
		input : ['Doxygen'],
		output : ['blah.xml'],
		command : [doxygen, '@INPUT@'])
			
endif

if sphinx_build.found()
  run_target('doc-html',
	     command : [sphinx_build, '-b', 'html', '.', 'html'])
endif
