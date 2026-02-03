const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const enable_fts5 = b.option(bool, "enable_fts5", "Whether to compile sqlite with FTS5") orelse false;
    const enable_carray = b.option(bool, "enable_carray", "Whether to compile sqlite with CARRAY extension") orelse false;

    const sqlite = b.addLibrary(.{
        .name = "sqlite",
        .root_module = b.addTranslateC(.{
            .root_source_file = b.path("sqlite/sqlite3.h"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }).createModule(),
    });

    sqlite.addCSourceFile(.{ .file = b.path("sqlite/sqlite3.c") });

    if (enable_fts5) {
        sqlite.root_module.addCMacro("SQLITE_ENABLE_FTS5", "1");
    }

    if (enable_carray) {
        sqlite.root_module.addCMacro("SQLITE_ENABLE_CARRAY", "1");
    }

    const lightql = b.addModule("lightql", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "sqlite", .module = sqlite.root_module },
        },
    });

    const liblightql = b.addLibrary(.{
        .name = "lightql",
        .linkage = .static,
        .root_module = lightql,
    });

    b.installArtifact(liblightql);

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "lightql", .module = lightql },
        },
    });
    const exe = b.addExecutable(.{
        .name = "main",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
