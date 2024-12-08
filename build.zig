// FIXME: switch to zimgui.cpp/zimgui.h (those don't have a function name prefix)
// but this needs support in sokol_imgui.h (currently sokol_imgui.h expects the
// ig prefix when compiled in C mode)
const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_cimgui = b.addStaticLibrary(.{
        .name = "cimgui_clib",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib_cimgui.linkLibCpp();
    lib_cimgui.addCSourceFiles(.{
        .files = &.{
            "src/zimgui.cpp",
            "src/imgui_demo.cpp",
            "src/imgui_draw.cpp",
            "src/imgui_tables.cpp",
            "src/imgui_widgets.cpp",
            "src/imgui.cpp",
        },
    });

    // make cimgui available as artifact, this allows to inject
    // the Emscripten sysroot include path in another build.zig
    b.installArtifact(lib_cimgui);

    // translate-c the cimgui.h file
    // NOTE: running this step with the host target is intended to avoid
    // any Emscripten header search path shenanigans
    const translateC = b.addTranslateC(.{
        .root_source_file = b.path("src/zimgui.h"),
        .target = b.host,
        .optimize = optimize,
    });

    // build cimgui as module
    const mod_cimgui = b.addModule("cimgui", .{
        .root_source_file = translateC.getOutput(),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    mod_cimgui.linkLibrary(lib_cimgui);
}
