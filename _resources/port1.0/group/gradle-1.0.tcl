# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:filetype=tcl:et:sw=4:ts=4:sts=4

# The gradle PortGroup aids in porting Java projects using the Gradle build
# system.  It attempts to circumvent the common ./gradlew idiom by instead
# depending on the appropriate gradle* port.
#
# Usage:
# PortGroup gradle 1.0

PortGroup                           java 1.0

options                             gradle.init_scripts \
                                    gradle.build_tasks \
                                    gradle.test_tasks \
                                    gradle.major \
                                    gradle.user_home

# The initialisation scripts to run for the configure phase (if any).  Paths are
# relative to ${configure.dir}.
default gradle.init_scripts         {}

# The tasks to run for the build phase.
default gradle.build_tasks          assemble

# The tasks to run for the test phase (if test.run is enabled).
default gradle.test_tasks           test

# The major version of Gradle to use.  Defaults to the latest version.
default gradle.major                {}

# The location of the Gradle User Home directory.
default gradle.user_home            {${workpath}/.home/.gradle}

# Useful defaults for standard keywords.
default configure.pre_args          {}
default test.run                    yes

namespace eval gradle {}

proc gradle::port {} {
    global                          gradle.major
    return gradle[join ${gradle.major}]
}

proc gradle::prog {} {
    global                          prefix
    return ${prefix}/bin/[gradle::port]
}

proc gradle::setup {} {
    global                          use_parallel_build \
                                    build.jobs \
                                    gradle.build_tasks \
                                    gradle.init_scripts \
                                    gradle.test_tasks \
                                    gradle.user_home

    lappend common_args             --no-daemon \
                                    --gradle-user-home=${gradle.user_home}

    if {${use_parallel_build}} {
        lappend common_args         --max-workers=${build.jobs} \
                                    --parallel
    } else {
        lappend common_args         --no-parallel
    }

    depends_build-append            port:[gradle::port]

    if {[llength ${gradle.init_scripts}]} {
        configure.cmd               [gradle::prog]
        configure.pre_args-append   {*}${common_args}
    } else {
        use_configure               no
    }

    foreach script ${gradle.init_scripts} {
        configure.pre_args-append   --init-script=${script}
    }

    build.cmd                       [gradle::prog]
    build.target                    {*}${gradle.build_tasks}
    build.pre_args-append           {*}${common_args}

    test.cmd                        [gradle::prog]
    test.target                     {*}${gradle.test_tasks}
    test.pre_args-append            {*}${common_args}

    if {"assemble" in ${gradle.build_tasks}} {
        build.pre_args-append       --exclude-task=javadocJar \
                                    --exclude-task=sourcesJar
    }

    foreach task ${gradle.test_tasks} {
        build.pre_args-append       --exclude-task=${task}
    }
}

port::register_callback gradle::setup
