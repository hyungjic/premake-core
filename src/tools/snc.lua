--
-- snc.lua
-- Provides Sony SNC-specific configuration strings.
-- Copyright (c) 2010 Jason Perkins and the Premake project
--

	
	premake.snc = { }
	

-- TODO: Will cfg.system == "windows" ever be true for SNC? If
-- not, remove the conditional blocks that use this test.

--
-- Set default tools
--

	premake.snc.cc     = "snc"
	premake.snc.cxx    = "g++"
	premake.snc.ar     = "ar"
	
	
--
-- Translation of Premake flags into SNC flags
--

	local cflags =
	{
		EnableSSE      = "-msse",
		EnableSSE2     = "-msse2",
		ExtraWarnings  = "-Wall",
		FatalWarnings  = "-Werror",
		FloatFast      = "-ffast-math",
		FloatStrict    = "-ffloat-store",
		NoFramePointer = "-fomit-frame-pointer",
		Optimize       = "-O2",
		OptimizeSize   = "-Os",
		OptimizeSpeed  = "-O3",
		Symbols        = "-g",
	}

	local cxxflags =
	{
		NoExceptions   = "", -- No exceptions is the default in the SNC compiler.
		NoRTTI         = "-Xc-=rtti",
	}
	
	
--
-- Map platforms to flags
--

	premake.snc.platforms = 
	{
		Native = { 
			cppflags = "-MMD -MP",
		},
		x32 = { 
			cppflags = "-MMD -MP",	
			flags    = "-m32",
			ldflags  = "-L/usr/lib32", 
		},
		x64 = { 
			cppflags = "-MMD -MP",
			flags    = "-m64",
			ldflags  = "-L/usr/lib64",
		},
		PS3 = {
			cc         = "ppu-lv2-g++",
			cxx        = "ppu-lv2-g++",
			ar         = "ppu-lv2-ar",
			cppflags   = "-MMD -MP",
		}
	}

	local platforms = premake.snc.platforms
	

--
-- Returns a list of compiler flags, based on the supplied configuration.
--

	function premake.snc.getcppflags(cfg)
		local result = { }
		table.insert(result, platforms[cfg.platform].cppflags)
		return result
	end

	function premake.snc.getcflags(cfg)
		local result = table.translate(cfg.flags, cflags)
		table.insert(result, platforms[cfg.platform].flags)
		if cfg.system ~= "windows" and cfg.kind == "SharedLib" then
			table.insert(result, "-fPIC")
		end
		
		return result		
	end
	
	function premake.snc.getcxxflags(cfg)
		local result = table.translate(cfg.flags, cxxflags)
		return result
	end
	


--
-- Returns a list of linker flags, based on the supplied configuration.
--

	function premake.snc.getldflags(cfg)
		local result = { }
		
		if not cfg.flags.Symbols then
			table.insert(result, "-s")
		end
	
		if cfg.kind == "SharedLib" then
			table.insert(result, "-shared")				
			if cfg.system == "windows" and not cfg.flags.NoImportLib then
				table.insert(result, '-Wl,--out-implib="' .. cfg.linktarget.fullpath .. '"')
			end
		end

		if cfg.kind == "WindowedApp" and cfg.system == "windows" then
			table.insert(result, "-mwindows")
		end
		
		local platform = platforms[cfg.platform]
		table.insert(result, platform.flags)
		table.insert(result, platform.ldflags)
		
		return result
	end
		

--
-- Return a list of library search paths. Technically part of LDFLAGS but need to
-- be separated because of the way Visual Studio calls SNC for the PS3. See bug 
-- #1729227 for background on why library paths must be split.
--

	function premake.snc.getlibdirflags(cfg)
		local result = { }
		for _, value in ipairs(premake.getlinks(cfg, "all", "directory")) do
			table.insert(result, '-L' .. _MAKE.esc(value))
		end
		return result
	end
	


--
-- Returns a list of linker flags for library search directories and library
-- names. See bug #1729227 for background on why the path must be split.
--

	function premake.snc.getlinkflags(cfg)
		local result = { }
		for _, value in ipairs(premake.getlinks(cfg, "all", "basename")) do
			if path.getextension(value) == ".framework" then
				table.insert(result, '-framework ' .. _MAKE.esc(path.getbasename(value)))
			else
				table.insert(result, '-l' .. _MAKE.esc(value))
			end
		end
		return result
	end
	
	

--
-- Decorate defines for the SNC command line.
--

	function premake.snc.getdefines(defines)
		local result = { }
		for _,def in ipairs(defines) do
			table.insert(result, '-D' .. def)
		end
		return result
	end


	
--
-- Decorate include file search paths for the SNC command line.
--

	function premake.snc.getincludedirs(includedirs)
		local result = { }
		for _,dir in ipairs(includedirs) do
			table.insert(result, "-I" .. _MAKE.esc(dir))
		end
		return result
	end