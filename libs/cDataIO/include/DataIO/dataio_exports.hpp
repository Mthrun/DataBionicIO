// OUTPUT
// The MYLIB_API macro for the selected static or shared-library build.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.

#pragma once

// A MEX file contains the core code; it does not import a separate DataIO DLL.
#if defined(COMPILING_FROM_R) || defined(DATAIO_STATIC)
		#define MYLIB_API
#else
	#if defined(_WIN32) || defined(__CYGWIN__)
		#ifdef MYLIB_EXPORTS
			#define MYLIB_API __declspec(dllexport)
		#else
			#define MYLIB_API __declspec(dllimport)
		#endif
	#else
		#define MYLIB_API
	#endif
#endif