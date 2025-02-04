const std = @import("std");
const solana = @import("solana-program-sdk");

pub fn build(b: *std.Build) void {
    const optimize = .ReleaseSmall;
    const target = b.resolveTargetQuery(solana.sbf_target);
    const program = b.addSharedLibrary(.{
        .name = "counter",
        .root_source_file = b.path("src/root.zig"),
        .optimize = optimize,
        .target = target,
    });

    const caramello_dep = b.dependency("caramello", .{
        .target = target,
        .optimize = optimize,
    });
    const caramello_mod = caramello_dep.module("caramello");

    program.root_module.addImport("caramello", caramello_mod);

    // Adding required dependencies, link the program properly, and get a
    // prepared modules
    _ = solana.buildProgram(b, program, target, optimize);
    b.installArtifact(program);
    build_deps(b);
    // base58.generateProgramKeypair(b, program);
}

// temporary hack to get linting, haven't figured out another way
fn build_deps(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const program = b.addSharedLibrary(.{
        .name = "counter",
        .root_source_file = b.path("src/root.zig"),
        .optimize = optimize,
        .target = target,
    });

    const solana_dep = b.dependency("solana-program-sdk", .{
        .target = target,
        .optimize = optimize,
    });
    const solana_mod = solana_dep.module("solana-program-sdk");
    program.root_module.addImport("solana-program-sdk", solana_mod);

    const caramello_dep = b.dependency("caramello", .{
        .target = target,
        .optimize = optimize,
    });
    const caramello_mod = caramello_dep.module("caramello");
    program.root_module.addImport("caramello", caramello_mod);

    const build_dep = b.step("lint", "build for linter");
    build_dep.dependOn(&program.step);
}
