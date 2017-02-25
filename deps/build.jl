using BinDeps

@BinDeps.setup

basedir = dirname(@__FILE__)
director_version = "0.1.0-29-g190fc82"

@static if is_linux()
    deps = [
        python = library_dependency("python", aliases=["libpython2.7.so", "libpython3.2.so", "libpython3.3.so", "libpython3.4.so", "libpython3.5.so", "libpython3.6.so", "libpython3.7.so"])
        python_vtk = library_dependency("vtkCommon", aliases=["libvtkCommon.so", "libvtkCommon.so.5.8", "libvtkCommon.so.5.10"], depends=[python],
            validate=(name, handle) -> begin
                isfile(replace(name, r"vtkCommon", "vtkCommonPythonD", 1))
            end)
        director = library_dependency("ddApp", aliases=["libddApp"], depends=[python_vtk, python])
    ]

    linux_distributor = strip(readstring(`lsb_release -i -s`))
    linux_version = VersionNumber(strip(readstring(`lsb_release -r -s`)))
    if linux_distributor == "Ubuntu" && linux_version >= v"16.04"
        director_variant = "ubuntu-16.04"
    elseif linux_distributor == "Ubuntu" && linux_version >= v"14.04"
        director_variant = "ubuntu-14.04"
    else
        error("Prebuilt binaries are only available for Ubuntu 14.04 and 16.04")
    end


    # The vtkPython libraries all have undeclared dependencies on libpython2.7,
    # so they cannot be dlopen()ed without missing symbol errors. As a result,
    # we can't use the regular library_dependency mechanism to look for vtk5
    # and python-vtk. Instead, we combined both dependencies into "python_vtk"
    # and make one build rule to apt-get install all the vtk-related packages.
    provides(SimpleBuild,
        () -> run(`sudo apt-get install libvtk5-qt4-dev python-vtk`),
        python_vtk)
    provides(AptGet, Dict("python2.7" => python))
    provides(BuildProcess, (@build_steps begin
        FileDownloader("http://people.csail.mit.edu/patmarion/software/director/releases/director-$(director_version)-$(director_variant).tar.gz",
                       joinpath(basedir, "downloads", "director.tar.gz"))
        CreateDirectory(joinpath(basedir, "usr"))
        (`tar xzf $(joinpath(basedir, "downloads", "director.tar.gz")) --directory=usr --strip-components=1`)
    end), director)
elseif is_apple()
    deps = [
        director = library_dependency("ddApp", aliases=["libddApp"])
    ]
    provides(BuildProcess, (@build_steps begin
        FileDownloader("http://people.csail.mit.edu/patmarion/software/director/releases/director-$(director_version)-mac.tar.gz",
                       joinpath(basedir, "downloads", "director.tar.gz"))
        CreateDirectory(joinpath(basedir, "usr"))
        (`tar xzf $(joinpath(basedir, "downloads", "director.tar.gz")) --directory=usr --strip-components=1`)
    end), director)

end

@BinDeps.install Dict(:ddApp => :libddApp)
